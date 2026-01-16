import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AjudaScreen extends StatefulWidget {
  const AjudaScreen({super.key});

  @override
  State<AjudaScreen> createState() => _AjudaScreenState();
}

class _AjudaScreenState extends State<AjudaScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  final List<bool> _expandedFAQs = List.generate(8, (_) => false);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildHeader(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildQuickActions(),
                            const SizedBox(height: 32),
                            _buildSectionTitle('Perguntas Frequentes'),
                            const SizedBox(height: 16),
                            _buildFAQSection(),
                            const SizedBox(height: 32),
                            _buildSectionTitle('Tutoriais'),
                            const SizedBox(height: 16),
                            _buildTutorialsSection(),
                            const SizedBox(height: 32),
                            _buildSectionTitle('Suporte'),
                            const SizedBox(height: 16),
                            _buildSupportSection(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0A0E14),
                Color(0xFF0F1419),
                Color(0xFF0F151C),
              ],
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
                colors: [
                  const Color(0xFF00E5D1).withOpacity(0.15),
                  Colors.transparent,
                ],
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
                colors: [
                  const Color(0xFF9D4EDD).withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F151C).withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00E5D1).withOpacity(0.2),
            ),
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00E5D1).withOpacity(0.2),
                const Color(0xFF00C9FF).withOpacity(0.15),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5D1), Color(0xFF00C9FF)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5D1).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Central de Ajuda',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estamos aqui para ajudar você',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acesso Rápido',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Chat Suporte',
                gradient: [const Color(0xFF00E5D1), const Color(0xFF00C9FF)],
                onTap: () {
                  _showComingSoonDialog('Chat de Suporte');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.mail_outline_rounded,
                title: 'Email',
                gradient: [const Color(0xFF9D4EDD), const Color(0xFFFF6EC7)],
                onTap: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'suporte@fitplanner.com',
                    query: 'subject=Ajuda FitPlanner',
                  );
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.video_library_rounded,
                title: 'Tutoriais',
                gradient: [const Color(0xFF00FF87), const Color(0xFF00FFD1)],
                onTap: () {
                  _showComingSoonDialog('Vídeos Tutoriais');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.bug_report_rounded,
                title: 'Reportar Bug',
                gradient: [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)],
                onTap: () {
                  _showBugReportDialog();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradient[0].withOpacity(0.15),
                gradient[1].withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gradient[0].withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFAQSection() {
    final faqs = [
      {
        'question': 'Como criar um plano de treino?',
        'answer':
            'Para criar um plano de treino, acesse o menu "Planner Fitness", toque no botão "+", escolha os exercícios desejados e configure séries, repetições e descanso. Você pode salvar e editar seus treinos a qualquer momento.',
      },
      {
        'question': 'Como funciona o chat com Personal Trainer?',
        'answer':
            'O chat utiliza inteligência artificial para responder suas dúvidas sobre treinos, técnicas de exercícios e montagem de fichas. Basta fazer login e acessar "Personal Trainer" no menu principal.',
      },
      {
        'question': 'Posso usar o app offline?',
        'answer':
            'Algumas funcionalidades como visualização de treinos salvos e tabela de alimentos funcionam offline. Porém, os chats de IA e sincronização de dados requerem conexão com a internet.',
      },
      {
        'question': 'Como alterar minha foto de perfil?',
        'answer':
            'Acesse "Meu Perfil" no menu lateral, toque no botão "Alterar foto" ou no ícone de câmera flutuante, e selecione uma imagem da sua galeria.',
      },
      {
        'question': 'Os dados são salvos automaticamente?',
        'answer':
            'Sim! Todos os seus treinos, configurações e progresso são salvos automaticamente na nuvem quando você está conectado à internet.',
      },
      {
        'question': 'Como acessar a tabela nutricional?',
        'answer':
            'No menu principal, toque em "Alimentos" para acessar a tabela nutricional completa com informações sobre calorias, proteínas, carboidratos e gorduras de diversos alimentos.',
      },
      {
        'question': 'Posso compartilhar meus treinos?',
        'answer':
            'Em breve! Estamos desenvolvendo a funcionalidade de compartilhamento de treinos com amigos e treinadores. Fique atento às próximas atualizações.',
      },
      {
        'question': 'Como reportar um problema?',
        'answer':
            'Use o botão "Reportar Bug" na seção de Acesso Rápido acima, ou envie um email para suporte@fitplanner.com com detalhes do problema encontrado.',
      },
    ];

    return Column(
      children: List.generate(
        faqs.length,
        (index) => _buildFAQItem(
          question: faqs[index]['question']!,
          answer: faqs[index]['answer']!,
          index: index,
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
    required int index,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F151C).withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00E5D1).withOpacity(0.2),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _expandedFAQs[index] = !_expandedFAQs[index];
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E5D1), Color(0xFF00C9FF)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.question_mark_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              question,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Icon(
                            _expandedFAQs[index]
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: const Color(0xFF00E5D1),
                          ),
                        ],
                      ),
                      if (_expandedFAQs[index]) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            answer,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildTutorialsSection() {
    final tutorials = [
      {
        'icon': Icons.fitness_center_rounded,
        'title': 'Primeiros Passos',
        'description': 'Aprenda a usar o FitPlanner',
        'gradient': [const Color(0xFF00E5D1), const Color(0xFF00C9FF)],
      },
      {
        'icon': Icons.restaurant_menu_rounded,
        'title': 'Nutrição Básica',
        'description': 'Entenda sobre macronutrientes',
        'gradient': [const Color(0xFF9D4EDD), const Color(0xFFFF6EC7)],
      },
      {
        'icon': Icons.calendar_today_rounded,
        'title': 'Montando seu Treino',
        'description': 'Crie fichas personalizadas',
        'gradient': [const Color(0xFF00FF87), const Color(0xFF00FFD1)],
      },
    ];

    return Column(
      children: tutorials.map((tutorial) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTutorialCard(
            icon: tutorial['icon'] as IconData,
            title: tutorial['title'] as String,
            description: tutorial['description'] as String,
            gradient: tutorial['gradient'] as List<Color>,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTutorialCard({
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradient,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F151C).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gradient[0].withOpacity(0.2),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _showComingSoonDialog(title);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.play_circle_outline_rounded,
                      color: gradient[0],
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportSection() {
    return Column(
      children: [
        _buildSupportCard(
          icon: Icons.email_rounded,
          title: 'Email de Suporte',
          subtitle: 'suporte@fitplanner.com',
          gradient: [const Color(0xFF00E5D1), const Color(0xFF00C9FF)],
          onTap: () async {
            final Uri emailUri = Uri(
              scheme: 'mailto',
              path: 'suporte@fitplanner.com',
            );
            if (await canLaunchUrl(emailUri)) {
              await launchUrl(emailUri);
            }
          },
        ),
        const SizedBox(height: 12),
        _buildSupportCard(
          icon: Icons.phone_rounded,
          title: 'WhatsApp',
          subtitle: '+55 (11) 99999-9999',
          gradient: [const Color(0xFF00FF87), const Color(0xFF00FFD1)],
          onTap: () async {
            final Uri whatsappUri = Uri.parse('https://wa.me/5511999999999');
            if (await canLaunchUrl(whatsappUri)) {
              await launchUrl(whatsappUri);
            }
          },
        ),
        const SizedBox(height: 12),
        _buildSupportCard(
          icon: Icons.schedule_rounded,
          title: 'Horário de Atendimento',
          subtitle: 'Segunda a Sexta: 8h às 18h',
          gradient: [const Color(0xFF9D4EDD), const Color(0xFFFF6EC7)],
          onTap: null,
        ),
      ],
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    VoidCallback? onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F151C).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: gradient[0].withOpacity(0.2),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: gradient[0],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F151C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5D1), Color(0xFF00C9FF)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Em Breve',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '$feature estará disponível em breve! Estamos trabalhando para trazer esta funcionalidade para você.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5D1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Entendi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F151C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bug_report_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Reportar Bug',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descreva o problema encontrado:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Digite aqui...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Relatório enviado! Obrigado pelo feedback.'),
                  backgroundColor: Color(0xFF00E5D1),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Enviar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}