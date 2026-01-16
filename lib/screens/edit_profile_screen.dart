import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _alturaController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();

  String? _sexoSelecionado;
  String? _objetivoSelecionado;
  String? _atividadeSelecionado;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _pesoController.dispose();
    _alturaController.dispose();
    _idadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final userDoc = await docRef.get();
        if (userDoc.exists) {
          _nomeController.text = userDoc.data()?['name'] ?? '';
        }

        final nutriDocRef = docRef.collection('nutritional_data').doc('user_info');
        final nutriDoc = await nutriDocRef.get();
        if (nutriDoc.exists) {
          final data = nutriDoc.data()!;
          _pesoController.text = data['peso']?.toString() ?? '';
          _alturaController.text = data['altura']?.toString() ?? '';
          _idadeController.text = data['idade']?.toString() ?? '';
          _sexoSelecionado = data['sexo'];
          _objetivoSelecionado = data['objetivo'];
          _atividadeSelecionado = data['atividade'];
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e'), backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Salva dados no Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nomeController.text.trim(),
        }, SetOptions(merge: true));

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('nutritional_data')
            .doc('user_info')
            .set({
          'peso': double.tryParse(_pesoController.text),
          'altura': int.tryParse(_alturaController.text),
          'idade': int.tryParse(_idadeController.text),
          'sexo': _sexoSelecionado,
          'objetivo': _objetivoSelecionado,
          'atividade': _atividadeSelecionado,
          'dataUltimaAtualizacao': Timestamp.now(),
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Perfil atualizado com sucesso!'),
              backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar perfil: $e'), backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _sendPasswordReset() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link de redefinição enviado para seu e-mail.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar link: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? keyboardType, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, color: Colors.teal) : null,
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Campo obrigatório';
          if (keyboardType == TextInputType.number) {
            final number = double.tryParse(value);
            if (number == null || number <= 0) return 'Valor inválido';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
      );

  Widget _buildRadioGroup(
          List<String> options, String? groupValue, Function(String?) onChanged) =>
      Column(
        children: options
            .map((op) => RadioListTile<String>(
                  title: Text(op),
                  value: op,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: Colors.teal,
                  contentPadding: EdgeInsets.zero,
                ))
            .toList(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: AppBar(
          elevation: 4,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF26A69A), Color(0xFF004D40)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          centerTitle: true,
          title: const Text(
            'Editar Perfil',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Informações da Conta',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.teal)),
                      const SizedBox(height: 10),
                      _buildTextField("Nome", _nomeController, icon: Icons.person),

                      const SizedBox(height: 20),
                      const Divider(thickness: 1.2),

                      const SizedBox(height: 10),
                      const Text('Informações Nutricionais',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.teal)),

                      _buildTextField("Peso (kg)", _pesoController,
                          keyboardType: TextInputType.number,
                          icon: Icons.monitor_weight_outlined),
                      _buildTextField("Altura (cm)", _alturaController,
                          keyboardType: TextInputType.number, icon: Icons.height),
                      _buildTextField("Idade", _idadeController,
                          keyboardType: TextInputType.number, icon: Icons.cake_outlined),

                      const SizedBox(height: 20),
                      _buildSectionTitle("Sexo"),
                      _buildRadioGroup(['Masculino', 'Feminino'], _sexoSelecionado,
                          (v) => setState(() => _sexoSelecionado = v)),

                      _buildSectionTitle("Objetivo principal"),
                      _buildRadioGroup(
                          ['Perder peso', 'Manter peso', 'Ganhar massa muscular', 'Recomposição muscular'],
                          _objetivoSelecionado,
                          (v) => setState(() => _objetivoSelecionado = v)),

                      _buildSectionTitle("Nível de atividade física"),
                      _buildRadioGroup(
                          ['Sedentário', 'Levemente ativo', 'Moderadamente ativo', 'Muito ativo'],
                          _atividadeSelecionado,
                          (v) => setState(() => _atividadeSelecionado = v)),

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.teal[700],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 3,
                          ),
                          child: const Text(
                            'Salvar Perfil',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _sendPasswordReset,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.teal),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Redefinir Senha',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
