import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cadastro_nutricional_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _obscureTextSenha = true;
  bool _obscureTextConfirmarSenha = true;
  bool _isLoading = false;
  bool _hoveringButton = false;
  bool _nomeFocused = false;
  bool _emailFocused = false;
  bool _senhaFocused = false;
  bool _confirmarSenhaFocused = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late AnimationController _contentController;
  late Animation<double> _glowPulse;
  late Animation<double> _contentFadeIn;
  late Animation<Offset> _contentSlideIn;

  // REDUZIDO: 80 → 35 partículas (mais discreto)
  final List<_Particle> _particles = List.generate(35, (index) => _Particle());

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // Mais lento = mais suave
    )..repeat(reverse: true);

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _glowPulse = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _contentFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _contentSlideIn = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    for (var p in _particles) p.randomize();
    _contentController.forward();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _animationController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      await userCredential.user!.updateDisplayName(_nomeController.text.trim());

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': _nomeController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const CadastroNutricional(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'A senha fornecida é muito fraca.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Uma conta para este e-mail já existe.';
      } else if (e.code == 'invalid-email') {
        message = 'E-mail inválido.';
      } else {
        message = 'Ocorreu um erro no cadastro. Tente novamente.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Erro inesperado. Tente novamente.'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradiente mais suave
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xFF0A0E27),
                        const Color(0xFF151B35),
                        _animationController.value * 0.3, // Menos movimento
                      )!,
                      const Color(0xFF0F1624),
                      Color.lerp(
                        const Color(0xFF151B35),
                        const Color(0xFF0A0E27),
                        _animationController.value * 0.3,
                      )!,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),

          // Luz ambiente superior (REDUZIDA)
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF00F5C8).withOpacity(0.08 * _glowPulse.value),
                        Color(0xFF00F5C8).withOpacity(0.02 * _glowPulse.value),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // Luz ambiente inferior (REDUZIDA)
          Positioned(
            bottom: -150,
            left: -100,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF00E5FF).withOpacity(0.06 * _glowPulse.value),
                        Color(0xFF00E5FF).withOpacity(0.02 * _glowPulse.value),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // Partículas discretas (SEM magnetismo, SEM clique)
          CustomPaint(
            painter: _ParticlePainter(_particles, size),
            size: Size.infinite,
          ),

          // Botão voltar limpo
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Conteúdo principal
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 60,
              ),
              child: FadeTransition(
                opacity: _contentFadeIn,
                child: SlideTransition(
                  position: _contentSlideIn,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        // REDUZIDO: 24 → 14
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.09),
                                Colors.white.withOpacity(0.04),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              width: 1,
                              color: Colors.white.withOpacity(0.15),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo ESTÁTICA (SEM pulse)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Image.asset(
                                    'imagens/logo.png',
                                    height: 90,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Título com gradiente
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      const Color(0xFF00F5C8),
                                      const Color(0xFF00D4FF),
                                    ],
                                  ).createShader(bounds),
                                  child: const Text(
                                    "Crie sua conta",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 32,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Comece sua transformação hoje",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 15,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Campo Nome
                                Focus(
                                  onFocusChange: (focus) {
                                    setState(() => _nomeFocused = focus);
                                  },
                                  child: _buildCleanField(
                                    controller: _nomeController,
                                    label: "Nome",
                                    hint: "João Silva",
                                    icon: Icons.person_outline_rounded,
                                    isFocused: _nomeFocused,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Digite seu nome';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Campo E-mail
                                Focus(
                                  onFocusChange: (focus) {
                                    setState(() => _emailFocused = focus);
                                  },
                                  child: _buildCleanField(
                                    controller: _emailController,
                                    label: "E-mail",
                                    hint: "seu@email.com",
                                    icon: Icons.mail_outline_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    isFocused: _emailFocused,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Digite seu e-mail';
                                      }
                                      if (!v.contains('@') || !v.contains('.')) {
                                        return 'E-mail inválido';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Campo Senha
                                Focus(
                                  onFocusChange: (focus) {
                                    setState(() => _senhaFocused = focus);
                                  },
                                  child: _buildCleanField(
                                    controller: _senhaController,
                                    label: "Senha",
                                    hint: "••••••••",
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscureTextSenha,
                                    isFocused: _senhaFocused,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureTextSenha
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                          () => _obscureTextSenha = !_obscureTextSenha),
                                      splashRadius: 20,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Digite uma senha';
                                      }
                                      if (v.length < 6) {
                                        return 'Senha muito curta (mín. 6 caracteres)';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Campo Confirmar Senha
                                Focus(
                                  onFocusChange: (focus) {
                                    setState(() => _confirmarSenhaFocused = focus);
                                  },
                                  child: _buildCleanField(
                                    controller: _confirmarSenhaController,
                                    label: "Confirmar senha",
                                    hint: "••••••••",
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscureTextConfirmarSenha,
                                    isFocused: _confirmarSenhaFocused,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureTextConfirmarSenha
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscureTextConfirmarSenha =
                                              !_obscureTextConfirmarSenha),
                                      splashRadius: 20,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Confirme sua senha';
                                      }
                                      if (v != _senhaController.text) {
                                        return 'As senhas não coincidem';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Botão Criar Conta (GLOW REDUZIDO)
                                MouseRegion(
                                  onEnter: (_) => setState(() => _hoveringButton = true),
                                  onExit: (_) => setState(() => _hoveringButton = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: _hoveringButton
                                            ? [
                                                const Color(0xFF00F5C8),
                                                const Color(0xFF00D4FF),
                                              ]
                                            : [
                                                const Color(0xFF00E5D1),
                                                const Color(0xFF00C5B8),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFF00F5C8).withOpacity(
                                              _hoveringButton ? 0.3 : 0.2),
                                          blurRadius: _hoveringButton ? 20 : 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isLoading ? null : _createAccount,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Center(
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2.5,
                                                  ),
                                                )
                                              : const Text(
                                                  "Criar Conta",
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontFamily: 'Montserrat',
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Footer limpo
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "🚀",
                                        style: TextStyle(fontSize: 15),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          "Sua jornada fitness começa aqui",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.65),
                                            fontSize: 12,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isFocused,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Glow APENAS no foco, bem suave
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF00F5C8).withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: isFocused
                ? const Color(0xFF00F5C8)
                : Colors.white.withOpacity(0.4),
            size: 20,
          ),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: isFocused
                ? const Color(0xFF00F5C8)
                : Colors.white.withOpacity(0.5),
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF00F5C8),
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(isFocused ? 0.08 : 0.04),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF00F5C8),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: const Color(0xFFFF6B6B).withOpacity(0.6),
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFFF6B6B),
              width: 2,
            ),
          ),
          errorStyle: const TextStyle(
            color: Color(0xFFFF6B6B),
            fontSize: 11,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// Partículas MUITO mais discretas (SEM interação)
class _Particle {
  Offset position = Offset.zero;
  double radius = 1;
  double dx = 0;
  double dy = 0;
  Color color = Colors.white54;

  void randomize([Size? size]) {
    final random = Random();
    position = Offset(
      random.nextDouble() * (size?.width ?? 800),
      random.nextDouble() * (size?.height ?? 1200),
    );
    radius = random.nextDouble() * 1.8 + 0.5; // Menor
    dx = (random.nextDouble() - 0.5) * 0.3; // Mais lento
    dy = (random.nextDouble() - 0.5) * 0.3;
    color = Colors.white.withOpacity(random.nextDouble() * 0.2 + 0.05); // Mais discreto
  }

  void move() {
    position = position.translate(dx, dy);
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Size screenSize;

  _ParticlePainter(this.particles, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      paint.color = p.color;
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5); // Blur suave
      canvas.drawCircle(p.position, p.radius, paint);

      p.move();

      // Reposicionar suavemente
      if (p.position.dx > size.width + 20 ||
          p.position.dx < -20 ||
          p.position.dy > size.height + 20 ||
          p.position.dy < -20) {
        p.randomize(size);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}