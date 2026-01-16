import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_menu_screen.dart';
import 'cadastro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _hoveringButton = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  late AnimationController _animationController;
  late AnimationController _contentController;
  late Animation<double> _contentFadeIn;
  late Animation<Offset> _contentSlideIn;

  final List<_Particle> _particles = List.generate(30, (index) => _Particle());

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _contentFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _contentSlideIn = Tween<Offset>(
      begin: const Offset(0, 0.05),
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
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainMenuScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      if (e.code == 'user-not-found') {
        msg = 'Usuário não encontrado.';
      } else if (e.code == 'wrong-password') {
        msg = 'Senha incorreta.';
      } else if (e.code == 'invalid-email') {
        msg = 'E-mail inválido.';
      } else {
        msg = 'Erro ao entrar. Tente novamente.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(msg)),
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
          // Background gradiente sutil
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
                        const Color(0xFF141937),
                        _animationController.value * 0.3,
                      )!,
                      const Color(0xFF0F1624),
                      Color.lerp(
                        const Color(0xFF141937),
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

          // Luz ambiente superior - mais discreta
          Positioned(
            top: -150,
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
                        Color(0xFF00F5C8).withOpacity(0.08),
                        Color(0xFF00F5C8).withOpacity(0.03),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // Luz ambiente inferior - mais discreta
          Positioned(
            bottom: -200,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF00E5FF).withOpacity(0.06),
                    Color(0xFF00E5FF).withOpacity(0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          CustomPaint(
            painter: _ParticlePainter(_particles, size),
            size: Size.infinite,
          ),

          // Conteúdo principal
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: FadeTransition(
                opacity: _contentFadeIn,
                child: SlideTransition(
                  position: _contentSlideIn,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
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
                              width: 1.5,
                              color: Colors.white.withOpacity(0.15),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 50,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Logo estática e limpa
                                Image.asset(
                                  'imagens/logo.png',
                                  height: 100,
                                ),
                                const SizedBox(height: 36),

                                // Título com gradiente
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      const Color(0xFF00F5C8),
                                      const Color(0xFF00D4E8),
                                    ],
                                  ).createShader(bounds),
                                  child: const Text(
                                    "Bem-vindo de volta",
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
                                  "Continue sua jornada fitness",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 15,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 40),

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
                                const SizedBox(height: 18),

                                // Campo Senha
                                Focus(
                                  onFocusChange: (focus) {
                                    setState(() => _passwordFocused = focus);
                                  },
                                  child: _buildCleanField(
                                    controller: _passwordController,
                                    label: "Senha",
                                    hint: "••••••••",
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscurePassword,
                                    isFocused: _passwordFocused,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 21,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword,
                                      ),
                                      splashRadius: 20,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Digite sua senha';
                                      }
                                      if (v.length < 6) {
                                        return 'Senha muito curta (mín. 6 caracteres)';
                                              }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Esqueceu a senha
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () async {
                                      final email = _emailController.text.trim();
                                      if (email.isEmpty || !email.contains('@')) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'Digite um e-mail válido primeiro',
                                            ),
                                            backgroundColor: const Color(0xFFFF6B6B),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                        return;
                                      }
                                      try {
                                        await _auth.sendPasswordResetEmail(
                                          email: email,
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.check_circle_outline,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Expanded(
                                                    child: Text(
                                                      'E-mail enviado! Verifique sua caixa de entrada.',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              backgroundColor: const Color(0xFF00F5C8),
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              margin: const EdgeInsets.all(16),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Erro ao enviar e-mail. Tente novamente.',
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
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      foregroundColor: const Color(0xFF00F5C8),
                                    ),
                                    child: const Text(
                                      "Esqueceu a senha?",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Botão de Login refinado
                                MouseRegion(
                                  onEnter: (_) =>
                                      setState(() => _hoveringButton = true),
                                  onExit: (_) =>
                                      setState(() => _hoveringButton = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: _hoveringButton
                                            ? [
                                                const Color(0xFF00F5C8),
                                                const Color(0xFF00D4E8),
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
                                            _hoveringButton ? 0.35 : 0.2,
                                          ),
                                          blurRadius: _hoveringButton ? 20 : 16,
                                          offset: Offset(0, _hoveringButton ? 6 : 4),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isLoading ? null : _signIn,
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
                                                  "Entrar",
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

                                const SizedBox(height: 32),

                                // Divisor minimalista
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Colors.white.withOpacity(0.15),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        "OU",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.15),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),

                                // Link de cadastro limpo
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Não tem uma conta? ",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 15,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation,
                                                    secondaryAnimation) =>
                                                const CadastroScreen(),
                                            transitionsBuilder: (context, animation,
                                                secondaryAnimation, child) {
                                              return FadeTransition(
                                                opacity: animation,
                                                child: child,
                                              );
                                            },
                                            transitionDuration:
                                                const Duration(milliseconds: 400),
                                          ),
                                        );
                                      },
                                      child: ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [
                                            const Color(0xFF00F5C8),
                                            const Color(0xFF00D4E8),
                                          ],
                                        ).createShader(bounds),
                                        child: const Text(
                                          "Cadastre-se",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            fontFamily: 'Montserrat',
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Footer discreto
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00F5C8)
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Text(
                                          "💪",
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          "Transforme seu corpo, transforme sua vida",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.5),
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
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
                : Colors.white.withOpacity(0.45),
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
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
              width: 1.5,
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
              color: const Color(0xFFFF6B6B).withOpacity(0.5),
              width: 1.5,
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

// Partículas discretas e sutis
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
    radius = random.nextDouble() * 1.8 + 0.5;
    dx = (random.nextDouble() - 0.5) * 0.3;
    dy = (random.nextDouble() - 0.5) * 0.3;
    color = Colors.white.withOpacity(random.nextDouble() * 0.25 + 0.05);
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
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(p.position, p.radius, paint);

      p.move();

      // Reposicionar partículas suavemente
      if (p.position.dx > size.width + 30 ||
          p.position.dx < -30 ||
          p.position.dy > size.height + 30 ||
          p.position.dy < -30) {
        p.randomize(size);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}