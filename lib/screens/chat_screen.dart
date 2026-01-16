import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

/// =========================== 
/// SISTEMA DE CORES REFINADO
/// ===========================
class AppColors {
  static const darkBg = Color(0xFF0A0E14);
  static const darkCard = Color(0xFF0F151C);
  static const neonCyan = Color(0xFF00E5D1);
  static const neonBlue = Color(0xFF00C9FF);
  static const neonPurple = Color(0xFF9D4EDD);
  static const accentGreen = Color(0xFF00FF87);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B8C1);
  static const divider = Color(0xFF1A2332);
}

class ChatScreen extends StatefulWidget {
  final String role;

  const ChatScreen({Key? key, required this.role}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  final String _apiKey = 'AIzaSyCmHithFgsSqDhUIXxgGdKp3A1S6et1va4';

  late final GenerativeModel _model;
  late final ChatSession _chat;
  late AnimationController _loadingController;

  List<int> diasSelecionados = [];
  int _nutriStep = 0;
  final Map<String, String> _userInfo = {};

  String get _collectionName =>
      widget.role == 'personal' ? 'chat_sessions_personal' : 'chat_sessions_nutricionista';

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    final systemInstruction = widget.role == 'personal'
        ? '''
Você é um personal trainer experiente. Sempre adapte o treino ao sexo do usuário:

- Se o usuário for masculino: foque em hipertrofia, força e exercícios compostos.
- Se o usuário for feminino: foque em tonificação, glúteos, core, resistência e equilíbrio.

IMPORTANTE: Use o percentual de gordura corporal (BF) para personalizar:
- BF < 10% (homens) ou < 18% (mulheres): Foco em manutenção e treino de força
- BF 10-18% (homens) ou 18-25% (mulheres): Ideal para hipertrofia
- BF > 18% (homens) ou > 25% (mulheres): Incluir mais cardio e circuitos

Monte treinos separados por dia (segunda a domingo, dependendo dos dias selecionados).  
Formato da resposta SEMPRE deve ser assim:

DIA: Segunda-feira
Grupo Muscular: Peito e Tríceps
Exercícios:
- Supino Reto com Barra – 3x10
- Supino Inclinado com Halteres – 3x10
- Crucifixo no Banco – 3x12
- Tríceps Corda – 3x12
- Tríceps Francês – 3x10

Nunca escreva texto fora desse formato. Sempre respeite o sexo e BF do usuário.
'''
        : '''
Você é um nutricionista experiente.

IMPORTANTE: Use o percentual de gordura corporal (BF) para ajustar calorias e macros:
- BF < 10% (homens) ou < 18% (mulheres): Dieta de manutenção ou leve superávit
- BF 10-18% (homens) ou 18-25% (mulheres): Foco em recomposição corporal
- BF > 18% (homens) ou > 25% (mulheres): Déficit calórico moderado

Ajuste também baseado no objetivo (ganho de massa, perda de gordura, manutenção).

Responda sempre com planos de dieta objetivos e organizados.
Sempre organizado e direto.
''';

    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
    _chat = _model.startChat(history: [Content.text(systemInstruction)]);

    _loadChatHistory();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection(_collectionName)
        .orderBy('timestamp')
        .get();

    setState(() {
      _messages.clear();
      if (snapshot.docs.isEmpty) {
        if (widget.role == 'personal') {
          _messages.add({
            'role': 'assistant',
            'content': 'Olá! 👋 Sou seu personal trainer virtual.\n\nAntes de montar seu treino, me conte:\n• Seu nível de experiência na academia (iniciante, intermediário ou avançado)\n• Possui alguma lesão ou limitação física? (Se não, digite "não")'
          });
        } else {
          _messages.add({
            'role': 'assistant',
            'content': 'Olá! 👋 Sou seu nutricionista virtual. Me diga se possui alguma alergia ou intolerância alimentar.'
          });
        }
      } else {
        for (var doc in snapshot.docs) {
          _messages.add({'role': doc['role'], 'content': doc['content']});
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    if (widget.role == 'personal' && diasSelecionados.isEmpty) {
      _showSnackBar('Selecione ao menos um dia de treino!');
      return;
    }

    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _isLoading = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginDialog();
      setState(() => _isLoading = false);
      return;
    }

    try {
      String mensagemFinal;

      if (widget.role == 'personal') {
        // Buscar dados do personal
        final personalSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('personal_data')
            .doc('user_info')
            .get();

        // Buscar dados nutricionais (para pegar o BF)
        final nutriSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('nutritional_data')
            .doc('user_info')
            .get();

        final Map<String, dynamic> cadastroPersonal =
            personalSnap.exists ? (personalSnap.data() as Map<String, dynamic>) : {};
        
        final Map<String, dynamic> cadastroNutri =
            nutriSnap.exists ? (nutriSnap.data() as Map<String, dynamic>) : {};

        final sexo = cadastroPersonal['sexo'] ?? cadastroNutri['sexo'] ?? 'masculino';
        final objetivo = cadastroPersonal['objetivo'] ?? cadastroNutri['objetivo'] ?? 'ganhar massa';
        final experiencia = cadastroPersonal['experience'] ?? 'iniciante';
        
        // 🔥 PEGAR O BF
        final dadosCorporais = cadastroNutri['dadosCorporais'] as Map<String, dynamic>?;
        final bf = dadosCorporais?['bf'] ?? 20.0;
        final origemBF = dadosCorporais?['origem'] ?? 'manual';
        
        final peso = cadastroNutri['peso'] ?? cadastroPersonal['peso'] ?? 70.0;
        final altura = cadastroNutri['altura'] ?? cadastroPersonal['altura'] ?? 170;
        final idade = cadastroNutri['idade'] ?? cadastroPersonal['idade'] ?? 25;

        final nomesDias = {
          1: 'Segunda-feira',
          2: 'Terça-feira',
          3: 'Quarta-feira',
          4: 'Quinta-feira',
          5: 'Sexta-feira',
          6: 'Sábado',
          7: 'Domingo',
        };
        String diasTexto = diasSelecionados.map((d) => nomesDias[d]!).join(', ');

        mensagemFinal = '''
Crie um treino completo considerando:
- Sexo: $sexo
- Objetivo: $objetivo
- Experiência: $experiencia
- Percentual de Gordura (BF): ${bf.toStringAsFixed(1)}% (detectado por $origemBF)
- Peso: $peso kg
- Altura: $altura cm
- Idade: $idade anos
- Dias de treino: $diasTexto

Use o BF para ajustar a intensidade e tipo de treino.
Formato da resposta deve respeitar o sexo do usuário e objetivo.

Informações adicionais: $message
''';
      } else {
        // NUTRICIONISTA
        List<String> perguntas = [
          'Possui alguma alergia ou intolerância alimentar? (Se não, digite "não")',
          'Qual sua preferência alimentar? (Ex: vegetariano, vegano, sem restrições)',
          'Qual seu horário de sono? (Ex: acorda às 7h, dorme às 23h)',
        ];

        final currentIndex = _nutriStep;
        if (currentIndex < perguntas.length) {
          _userInfo[perguntas[currentIndex]] = message;
          _nutriStep = currentIndex + 1;
        }

        if (_nutriStep < perguntas.length) {
          final nextQuestion = perguntas[_nutriStep];
          _addAssistantMessage(nextQuestion);
          setState(() => _isLoading = false);
          return;
        } else {
          final nutriSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('nutritional_data')
              .doc('user_info')
              .get();

          final Map<String, dynamic> cadastroNutricional =
              nutriSnap.exists ? (nutriSnap.data() as Map<String, dynamic>) : {};

          final peso = cadastroNutricional['peso'] ?? 70.0;
          final altura = cadastroNutricional['altura'] ?? 170;
          final idade = cadastroNutricional['idade'] ?? 25;
          final sexo = cadastroNutricional['sexo'] ?? 'Masculino';
          final objetivo = cadastroNutricional['objetivo'] ?? 'Manter peso';
          final atividade = cadastroNutricional['atividade'] ?? 'Moderadamente ativo';
          
          // 🔥 PEGAR O BF
          final dadosCorporais = cadastroNutricional['dadosCorporais'] as Map<String, dynamic>?;
          final bf = dadosCorporais?['bf'] ?? 20.0;
          final origemBF = dadosCorporais?['origem'] ?? 'manual';

          final extrasText = _userInfo.entries
              .map((e) => '${e.key}: ${e.value}')
              .join('; ');

          mensagemFinal = '''
Crie um plano de dieta detalhado baseado em:
- Peso: $peso kg
- Altura: $altura cm
- Idade: $idade anos
- Sexo: $sexo
- Objetivo: $objetivo
- Nível de atividade: $atividade
- Percentual de Gordura (BF): ${bf.toStringAsFixed(1)}% (detectado por $origemBF)

Informações adicionais: $extrasText

Use o BF para calcular calorias e macros ideais.
Seja objetivo, organize por refeições e ofereça variações por dia da semana.
''';
        }
      }

      final response = await _chat.sendMessage(Content.text(mensagemFinal));
      final geminiResponse = response.text;

      if (geminiResponse != null) {
        if (widget.role == 'personal') {
          await _saveWorkoutPlan(geminiResponse, diasSelecionados);
        } else {
          await _saveDietPlan(geminiResponse);
          _nutriStep = 0;
          _userInfo.clear();
          _addAssistantMessage('Se quiser ajustes (calorias, preferências, número de refeições), me diga.');
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection(_collectionName)
            .add({
          'role': 'assistant',
          'content': geminiResponse,
          'timestamp': Timestamp.now(),
        });

        _addAssistantMessage(geminiResponse);
      } else {
        _addAssistantMessage('⚠️ A IA não retornou resposta.');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      _addAssistantMessage('Erro: $e');
      setState(() => _isLoading = false);
    }
  }

  void _addAssistantMessage(String msg) {
    setState(() {
      if (widget.role == 'nutricionista') {
        String formatted = msg
            .replaceAll('*', '')
            .replaceAll('#', '');

        formatted = formatted.split('\n').map((line) {
          String l = line.trim();
          if (l.startsWith('-')) {
            l = '• ${l.substring(1).trim()}';
          }
          return l;
        }).join('\n');

        _messages.add({'role': 'assistant', 'content': formatted});
      } else {
        _messages.add({'role': 'assistant', 'content': msg});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.darkCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.darkCard.withOpacity(0.98),
                AppColors.darkBg.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.neonCyan.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 60, color: AppColors.neonCyan),
              const SizedBox(height: 16),
              const Text(
                'Login Necessário',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Você precisa estar logado para usar o chat.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonCyan,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Fazer Login', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, Map<String, dynamic>> _parseTreinoPorDia(String texto) {
    final blocos = texto.split('DIA:').where((b) => b.trim().isNotEmpty).toList();
    Map<String, Map<String, dynamic>> treinos = {};

    for (var bloco in blocos) {
      final linhas = bloco.trim().split('\n');
      String dia = linhas[0].trim();
      String grupo = '';
      List<String> exercicios = [];

      for (var linha in linhas.skip(1)) {
        if (linha.startsWith('Grupo Muscular:')) {
          grupo = linha.replaceFirst('Grupo Muscular:', '').trim();
        } else if (linha.startsWith('-')) {
          exercicios.add(linha.trim());
        }
      }

      treinos[dia] = {
        'grupo': grupo,
        'exercicios': exercicios,
        'origem': 'Gemini AI',
      };
    }

    return treinos;
  }

  Future<void> _saveWorkoutPlan(String content, List<int> diasSelecionados) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final treinosPorDia = _parseTreinoPorDia(content);
    final nomesDias = {1: 'Segunda-feira', 2: 'Terça-feira', 3: 'Quarta-feira', 4: 'Quinta-feira', 5: 'Sexta-feira', 6: 'Sábado', 7: 'Domingo'};
    final nomesDiasLower = {1: 'segunda', 2: 'terça', 3: 'quarta', 4: 'quinta', 5: 'sexta', 6: 'sábado', 7: 'domingo'};

    for (var dia in diasSelecionados) {
      final nomeDia = nomesDias[dia]!;
      final treino = treinosPorDia[nomeDia];
      if (treino == null) continue;

      DateTime hoje = DateTime.now();
      int diasParaAdicionar = (dia - hoje.weekday + 7) % 7;
      DateTime diaTreino = hoje.add(Duration(days: diasParaAdicionar));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workout_plans')
          .add({
        'nome': treino['grupo'],
        'exercicios': treino['exercicios'],
        'series_reps': 'N/A',
        'data': Timestamp.fromDate(diaTreino),
        'diaSemana': nomesDiasLower[dia],
        'origem': treino['origem'],
      });
    }
  }

  Future<void> _saveDietPlan(String plano) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('diet_plans')
        .add({
      'conteudo': plano,
      'timestamp': Timestamp.now(),
      'origem': 'Gemini AI',
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPersonal = widget.role == 'personal';
    final gradientColors = isPersonal 
        ? [AppColors.neonCyan, AppColors.neonBlue]
        : [AppColors.neonPurple, const Color(0xFFFF6EC7)];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(gradientColors),
          SafeArea(
            child: Column(
              children: [
                _buildPremiumAppBar(gradientColors),
                if (isPersonal) _buildDaySelectionChips(),
                Expanded(child: _buildMessageList()),
                if (_isLoading) _buildTypingIndicator(gradientColors),
                _buildMessageInput(gradientColors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(List<Color> gradientColors) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.darkBg, Color(0xFF0F1419), AppColors.darkCard],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [gradientColors[0].withOpacity(0.15), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [gradientColors[1].withOpacity(0.1), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumAppBar(List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.darkCard.withOpacity(0.9),
            AppColors.darkCard.withOpacity(0.7),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gradientColors[0].withOpacity(0.3)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              widget.role == 'personal' ? Icons.fitness_center_rounded : Icons.restaurant_menu_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.role == 'personal' ? 'Personal Trainer' : 'Nutricionista',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGreen.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Online • IA Avançada',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelectionChips() {
    final nomesDias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withOpacity(0.3)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(7, (index) {
            final dia = index + 1;
            final isSelected = diasSelecionados.contains(dia);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        diasSelecionados.remove(dia);
                      } else {
                        diasSelecionados.add(dia);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [AppColors.neonCyan, AppColors.neonBlue],
                            )
                          : null,
                      color: isSelected ? null : AppColors.darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.neonCyan.withOpacity(0.5)
                            : AppColors.divider,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.neonCyan.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      nomesDias[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      physics: const BouncingScrollPhysics(),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return PremiumChatBubble(
          message: msg['content'] ?? '',
          isUserMessage: isUser,
          role: widget.role,
        );
      },
    );
  }

  Widget _buildTypingIndicator(List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.darkCard.withOpacity(0.9),
                  AppColors.darkCard.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: gradientColors[0].withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(gradientColors[0]),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Digitando...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(List<Color> gradientColors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.darkCard.withOpacity(0.95),
            AppColors.darkCard.withOpacity(0.85),
          ],
        ),
        border: Border(
          top: BorderSide(color: AppColors.divider.withOpacity(0.5)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.darkBg.withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: gradientColors[0].withOpacity(0.2),
                ),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 15, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _sendMessage(value.trim());
                    _controller.clear();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading
                    ? null
                    : () {
                        final text = _controller.text.trim();
                        if (text.isNotEmpty) {
                          _sendMessage(text);
                          _controller.clear();
                        }
                      },
                borderRadius: BorderRadius.circular(26),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =========================== 
/// PREMIUM CHAT BUBBLE
/// ===========================
class PremiumChatBubble extends StatelessWidget {
  final String message;
  final bool isUserMessage;
  final String role;

  const PremiumChatBubble({
    Key? key,
    required this.message,
    required this.isUserMessage,
    required this.role,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradientColors = role == 'personal'
        ? [AppColors.neonCyan, AppColors.neonBlue]
        : [AppColors.neonPurple, const Color(0xFFFF6EC7)];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                role == 'personal' ? Icons.fitness_center_rounded : Icons.restaurant_menu_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isUserMessage
                    ? LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.darkCard.withOpacity(0.9),
                          AppColors.darkCard.withOpacity(0.7),
                        ],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUserMessage ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isUserMessage ? const Radius.circular(4) : const Radius.circular(20),
                ),
                border: Border.all(
                  color: isUserMessage
                      ? gradientColors[0].withOpacity(0.3)
                      : AppColors.divider.withOpacity(0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUserMessage
                        ? gradientColors[0].withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isUserMessage ? Colors.white : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          if (isUserMessage) ...[
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentGreen, Color(0xFF00FFD1)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGreen.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}