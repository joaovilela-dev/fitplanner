import 'dart:typed_data';
import 'dart:convert';
import 'dart:io' show File;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'main_menu_screen.dart';

class PerfilScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final Function(String) changeLanguage;
  final bool isDarkMode;
  final String currentLanguage;
  final Function(String)? onPhotoUpdated;

  const PerfilScreen({
    super.key,
    required this.toggleTheme,
    required this.changeLanguage,
    required this.isDarkMode,
    required this.currentLanguage,
    this.onPhotoUpdated,
  });

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isUploading = false;
  File? _pickedImageFile;
  Uint8List? _pickedImageBytes;
  String? _photoBase64;
  bool _photoChanged = false;

  Map<String, dynamic>? _nutritionalData;
  bool _isLoadingNutritional = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
    _loadUserData();
    _loadNutritionalData();
  }

  @override
  void dispose() {
    _animController.dispose();
    if (_photoChanged && _photoBase64 != null) {
      _saveBase64ToFirestore();
    }
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection("usuarios").doc(user.uid).get();
      if (mounted) {
        setState(() {
          _photoBase64 = doc.data()?["photoBase64"];
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
    }
  }

  Future<void> _loadNutritionalData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() => _isLoadingNutritional = true);
    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('nutritional_data')
          .doc('user_info')
          .get();
      if (mounted) {
        setState(() {
          _nutritionalData = doc.data();
          _isLoadingNutritional = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar dados nutricionais: $e");
      if (mounted) setState(() => _isLoadingNutritional = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    Uint8List bytes = await file.readAsBytes();
    setState(() {
      _pickedImageBytes = bytes;
      _photoBase64 = base64Encode(bytes);
      _photoChanged = true;
    });
  }

  Future<void> _saveBase64ToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() => _isUploading = true);
    try {
      await _firestore.collection("usuarios").doc(user.uid).set(
        {"photoBase64": _photoBase64},
        SetOptions(merge: true),
      );
      if (widget.onPhotoUpdated != null && _photoBase64 != null) {
        widget.onPhotoUpdated!(_photoBase64!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text("Foto atualizada com sucesso!"),
              ],
            ),
            backgroundColor: const Color(0xFF00C9A7),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erro ao salvar Base64: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  ImageProvider? _avatarImage() {
    if (_pickedImageBytes != null) return MemoryImage(_pickedImageBytes!);
    if (_photoBase64 != null) {
      try {
        return MemoryImage(base64Decode(_photoBase64!));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void _showFullScreenImage() {
    final avatar = _avatarImage();
    if (avatar == null) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: 'profile_photo',
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image(image: avatar, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNutritionalDialog() {
    if (_nutritionalData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum dado nutricional cadastrado ainda.")),
      );
      return;
    }

    final pesoController = TextEditingController(text: _nutritionalData!['peso']?.toString() ?? '');
    final alturaController = TextEditingController(text: _nutritionalData!['altura']?.toString() ?? '');
    final idadeController = TextEditingController(text: _nutritionalData!['idade']?.toString() ?? '');
    
    String sexo = _nutritionalData!['sexo'] ?? 'Masculino';
    String objetivo = _nutritionalData!['objetivo'] ?? 'Ganhar massa muscular';
    String atividade = _nutritionalData!['atividade'] ?? 'Moderadamente ativo';
    double bf = (_nutritionalData!['dadosCorporais']?['bf'] ?? 18.0).toDouble();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
                padding: const EdgeInsets.all(24),
                decoration: _modernGlassDecoration(radius: 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(gradient: _mainGradient(), shape: BoxShape.circle),
                            child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Editar Dados Nutricionais",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildEditField("Peso (kg)", pesoController, Icons.monitor_weight_rounded),
                      const SizedBox(height: 12),
                      _buildEditField("Altura (cm)", alturaController, Icons.height_rounded),
                      const SizedBox(height: 12),
                      _buildEditField("Idade", idadeController, Icons.cake_rounded),
                      const SizedBox(height: 20),
                      Text("Sexo", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Masculino', 'Feminino'].map((s) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildRadioOption(s, sexo == s, s == 'Masculino' ? Icons.male : Icons.female, () => setDialogState(() => sexo = s)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text("Objetivo", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...['Perder peso', 'Manter peso', 'Ganhar massa muscular', 'Recomposição muscular'].map((obj) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildRadioOption(obj, objetivo == obj, _getObjetivoIcon(obj), () => setDialogState(() => objetivo = obj)),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                      Text("Nível de Atividade", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...['Sedentário', 'Levemente ativo', 'Moderadamente ativo', 'Muito ativo'].map((atv) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildRadioOption(atv, atividade == atv, _getAtividadeIcon(atv), () => setDialogState(() => atividade = atv)),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                      Text("Percentual de Gordura: ${bf.toStringAsFixed(1)}%", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Slider(
                        value: bf,
                        min: 5,
                        max: 60,
                        divisions: 55,
                        activeColor: const Color(0xFF00F5C8),
                        inactiveColor: Colors.white.withOpacity(0.2),
                        onChanged: (v) => setDialogState(() => bf = v),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                ),
                              ),
                              child: const Text("Cancelar", style: TextStyle(color: Colors.white, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(gradient: _mainGradient(), borderRadius: BorderRadius.circular(12)),
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (pesoController.text.isEmpty || alturaController.text.isEmpty || idadeController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha todos os campos")));
                                    return;
                                  }
                                  final user = _auth.currentUser;
                                  if (user == null) return;
                                  try {
                                    final updatedData = {
                                      'peso': double.parse(pesoController.text),
                                      'altura': int.parse(alturaController.text),
                                      'idade': int.parse(idadeController.text),
                                      'sexo': sexo,
                                      'objetivo': objetivo,
                                      'atividade': atividade,
                                      'dadosCorporais': {
                                        'bf': bf,
                                        'origem': _nutritionalData!['dadosCorporais']?['origem'] ?? 'manual',
                                      },
                                      'dataAtualizacao': Timestamp.now(),
                                    };
                                    await _firestore.collection('users').doc(user.uid).collection('nutritional_data').doc('user_info').set(updatedData, SetOptions(merge: true));
                                    await _loadNutritionalData();
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.white),
                                            SizedBox(width: 12),
                                            Text("Dados atualizados com sucesso!"),
                                          ],
                                        ),
                                        backgroundColor: const Color(0xFF00C9A7),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao salvar: $e")));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text("Salvar", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getObjetivoIcon(String obj) {
    switch (obj) {
      case 'Perder peso': return Icons.trending_down_rounded;
      case 'Manter peso': return Icons.balance_rounded;
      case 'Ganhar massa muscular': return Icons.fitness_center_rounded;
      case 'Recomposição muscular': return Icons.transform_rounded;
      default: return Icons.fitness_center_rounded;
    }
  }

  IconData _getAtividadeIcon(String atv) {
    switch (atv) {
      case 'Sedentário': return Icons.weekend_rounded;
      case 'Levemente ativo': return Icons.directions_walk_rounded;
      case 'Moderadamente ativo': return Icons.directions_run_rounded;
      case 'Muito ativo': return Icons.sports_gymnastics_rounded;
      default: return Icons.directions_run_rounded;
    }
  }

  Widget _buildEditField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF00F5C8), size: 20),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00F5C8), width: 2)),
      ),
    );
  }

  Widget _buildRadioOption(String label, bool selected, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? LinearGradient(colors: [const Color(0xFF00F5C8).withOpacity(0.2), const Color(0xFF00E5FF).withOpacity(0.1)]) : null,
          color: selected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF00F5C8) : Colors.white.withOpacity(0.1), width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? const Color(0xFF00F5C8) : Colors.white.withOpacity(0.6), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Color(0xFF00F5C8), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
          ],
        ),
      ),
    );
  }

  LinearGradient _mainGradient() {
    return const LinearGradient(colors: [Color(0xFF00D9FF), Color(0xFF00FFA3)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  }

  LinearGradient _cardGradient() {
    return LinearGradient(colors: [const Color(0xFF1A2332).withOpacity(0.6), const Color(0xFF0F1923).withOpacity(0.4)], begin: Alignment.topLeft, end: Alignment.bottomRight);
  }

  BoxDecoration _modernGlassDecoration({double radius = 20}) {
    return BoxDecoration(
      gradient: _cardGradient(),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10)),
        BoxShadow(color: const Color(0xFF00D9FF).withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5)),
      ],
    );
  }

  Widget _modernGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: _modernGlassDecoration(radius: 20),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return WillPopScope(
      onWillPop: () async {
        if (_photoChanged && _photoBase64 != null) await _saveBase64ToFirestore();
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0A0E1A), Color(0xFF1A1F2E), Color(0xFF0F1620)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    _buildCustomAppBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _modernAvatarWithRing(user),
                            const SizedBox(height: 20),
                            Text(
                              user?.email?.split('@')[0] ?? "Usuário",
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(gradient: _mainGradient(), borderRadius: BorderRadius.circular(20)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text("Conta Verificada", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildStatsCards(user),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _modernSectionTitle("Dados Nutricionais"),
                                if (_nutritionalData != null)
                                  IconButton(
                                    onPressed: _showEditNutritionalDialog,
                                    icon: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(gradient: _mainGradient(), borderRadius: BorderRadius.circular(10)),
                                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _isLoadingNutritional
                                ? const Center(child: CircularProgressIndicator())
                                : _nutritionalData == null
                                    ? _modernGlassCard(
                                        child: Column(
                                          children: [
                                            Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.5), size: 48),
                                            const SizedBox(height: 12),
                                            Text("Nenhum dado nutricional cadastrado", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15)),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        children: [
                                          _buildNutritionalInfoCard(
                                            icon: Icons.monitor_weight_rounded,
                                            label: "Peso",
                                            value: "${_nutritionalData!['peso']} kg",
                                            gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildNutritionalInfoCard(
                                                  icon: Icons.height_rounded,
                                                  label: "Altura",
                                                  value: "${_nutritionalData!['altura']} cm",
                                                  gradient: const LinearGradient(colors: [Color(0xFFF093FB), Color(0xFFF5576C)]),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _buildNutritionalInfoCard(
                                                  icon: Icons.cake_rounded,
                                                  label: "Idade",
                                                  value: "${_nutritionalData!['idade']} anos",
                                                  gradient: const LinearGradient(colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)]),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          _buildNutritionalInfoCard(
                                            icon: _nutritionalData!['sexo'] == 'Masculino' ? Icons.male_rounded : Icons.female_rounded,
                                            label: "Sexo",
                                            value: _nutritionalData!['sexo'],
                                            gradient: const LinearGradient(colors: [Color(0xFFFA709A), Color(0xFFFEE140)]),
                                          ),
                                          const SizedBox(height: 12),
                                          _buildNutritionalInfoCard(
                                            icon: Icons.track_changes_rounded,
                                            label: "Percentual de Gordura",
                                            value: "${(_nutritionalData!['dadosCorporais']?['bf'] ?? 0).toStringAsFixed(1)}%",
                                            gradient: _mainGradient(),
                                          ),
                                          const SizedBox(height: 12),
                                          _buildNutritionalInfoCard(
                                            icon: Icons.flag_rounded,
                                            label: "Objetivo",
                                            value: _nutritionalData!['objetivo'],
                                            gradient: const LinearGradient(colors: [Color(0xFF30CFD0), Color(0xFF330867)]),
                                          ),
                                          const SizedBox(height: 12),
                                          _buildNutritionalInfoCard(
                                            icon: Icons.directions_run_rounded,
                                            label: "Nível de Atividade",
                                            value: _nutritionalData!['atividade'],
                                            gradient: const LinearGradient(colors: [Color(0xFFA8EDEA), Color(0xFFFED6E3)]),
                                          ),
                                        ],
                                      ),
                            const SizedBox(height: 32),
                            _modernSectionTitle("Informações da Conta"),
                            const SizedBox(height: 16),
                            _buildModernSettingCard(
                              icon: Icons.email_rounded,
                              title: "Email",
                              subtitle: user?.email ?? "Não encontrado",
                              gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                            ),
                            const SizedBox(height: 32),
                            _modernSectionTitle("Ações"),
                            const SizedBox(height: 16),
                            _buildModernSettingCard(
                              icon: Icons.logout_rounded,
                              title: "Sair da Conta",
                              subtitle: "Encerrar sessão atual",
                              gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)]),
                              onTap: () async {
                                final confirm = await showDialog<bool>(context: context, builder: (context) => _buildLogoutDialog());
                                if (confirm == true) {
                                  if (_photoChanged && _photoBase64 != null) await _saveBase64ToFirestore();
                                  await FirebaseAuth.instance.signOut();
                                  if (!mounted) return;
                                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainMenuScreen()), (route) => false);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: _buildModernFAB(),
      ),
    );
  }

  Widget _buildNutritionalInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Gradient gradient,
  }) {
    return _modernGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
            onPressed: () async {
              if (_photoChanged && _photoBase64 != null) await _saveBase64ToFirestore();
              if (mounted) Navigator.pop(context);
            },
          ),
          const Expanded(
            child: Text(
              "Meu Perfil",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildLogoutDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: _modernGlassDecoration(radius: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)]), shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 20),
                const Text("Sair da Conta?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                Text("Tem certeza que deseja encerrar sua sessão?", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.2))),
                        ),
                        child: const Text("Cancelar", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)]), borderRadius: BorderRadius.circular(12)),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Sair", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modernAvatarWithRing(User? user) {
    final avatar = _avatarImage();
    return GestureDetector(
      onLongPress: avatar != null ? _showFullScreenImage : null,
      child: Hero(
        tag: 'profile_photo',
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                gradient: _mainGradient(),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00D9FF).withOpacity(0.4), blurRadius: 30, spreadRadius: 5),
                  BoxShadow(color: const Color(0xFF00FFA3).withOpacity(0.3), blurRadius: 20, spreadRadius: -5),
                ],
              ),
            ),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(color: const Color(0xFF1A2332), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.1), width: 2)),
              child: CircleAvatar(
                radius: 68,
                backgroundColor: Colors.grey.shade800,
                backgroundImage: avatar,
                child: avatar == null
                    ? Text(user?.email?.substring(0, 1).toUpperCase() ?? "?", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white))
                    : null,
              ),
            ),
            if (_isUploading)
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
              ),
            if (avatar != null && !_isUploading)
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: _mainGradient(),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1A2332), width: 3),
                    boxShadow: [BoxShadow(color: const Color(0xFF00D9FF).withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
                  ),
                  child: const Icon(Icons.touch_app, color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(User? user) {
    return Row(
      children: [
        Expanded(
          child: _modernGlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(gradient: _mainGradient(), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_camera, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 14),
                Text(_photoBase64 != null ? "Com Foto" : "Sem Foto", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text("Status", style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _modernGlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]), shape: BoxShape.circle),
                  child: const Icon(Icons.verified_user, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 14),
                const Text("Ativo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text("Conta", style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: _modernGlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Icon(icon, size: 26, color: Colors.white),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (onTap != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.white.withOpacity(0.5)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _modernSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(gradient: _mainGradient(), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: _mainGradient(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00D9FF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: const Color(0xFF00FFA3).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}