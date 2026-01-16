import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dieta_screen.dart';
import 'login_screen.dart';
import 'cadastro_screen.dart';
import 'planner_fitness_screen.dart';
import 'chat_screen.dart';
import 'perfil_screen.dart';
import 'ajuda_screen.dart';

class AppColors {
  static const darkBg = Color(0xFF0A0E14);
  static const darkCard = Color(0xFF0F151C);
  static const surfaceLight = Color(0xFF1C2430);
  
  static const primary = Color(0xFF00D9FF);
  static const primaryDark = Color(0xFF00A8CC);
  static const primaryLight = Color(0xFF5CE1FF);
  
  static const accentGreen = Color(0xFF00FF87);
  static const accentGreenDark = Color(0xFF00CC6F);
  static const accentPurple = Color(0xFFB57BFF);
  static const accentOrange = Color(0xFFFF8A3D);
  
  static const success = Color(0xFF00E676);
  static const error = Color(0xFFFF5252);
  static const warning = Color(0xFFFFB74D);
  
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B8C1);
  static const textTertiary = Color(0xFF7A8290);
  
  static const divider = Color(0xFF1A2332);
}

class AppDimens {
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 24.0;
  
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 28.0;
}

class FeatureModel {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool requiresAuth;
  final Widget? widget;
  final List<Color> gradientColors;

  const FeatureModel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.requiresAuth,
    this.widget,
    required this.gradientColors,
  });
}

class AnimatedParticles extends StatefulWidget {
  const AnimatedParticles({super.key});

  @override
  State<AnimatedParticles> createState() => _AnimatedParticlesState();
}

class _AnimatedParticlesState extends State<AnimatedParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    for (int i = 0; i < 30; i++) {
      _particles.add(Particle());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particles, _controller.value),
          child: Container(),
        );
      },
    );
  }
}

class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final Color color;

  Particle()
      : x = math.Random().nextDouble(),
        y = math.Random().nextDouble(),
        size = math.Random().nextDouble() * 3 + 1,
        speed = math.Random().nextDouble() * 0.5 + 0.2,
        color = [
          AppColors.primary,
          AppColors.accentGreen,
          AppColors.accentPurple,
        ][math.Random().nextInt(3)].withOpacity(0.3);
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final yOffset = ((animationValue * particle.speed) % 1.0) * size.height;
      final y = (particle.y * size.height + yOffset) % size.height;

      canvas.drawCircle(
        Offset(particle.x * size.width, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Premium3DButton extends StatefulWidget {
  final FeatureModel feature;
  final VoidCallback onTap;

  const Premium3DButton({
    super.key,
    required this.feature,
    required this.onTap,
  });

  @override
  State<Premium3DButton> createState() => _Premium3DButtonState();
}

class _Premium3DButtonState extends State<Premium3DButton>
    with TickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  late final AnimationController _controller;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: Listenable.merge([_controller, _pulseController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spacingXSmall,
                  vertical: AppDimens.spacingSmall,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(0, 8),
                      blurRadius: 24,
                      spreadRadius: -4,
                    ),
                    BoxShadow(
                      color: widget.feature.gradientColors[0]
                          .withOpacity(_glowAnimation.value * (0.3 + _pulseAnimation.value * 0.2)),
                      offset: const Offset(0, 4),
                      blurRadius: _isHovered ? 32 : 20,
                      spreadRadius: _isHovered ? 2 : 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isPressed
                              ? [
                                  AppColors.darkCard.withOpacity(0.95),
                                  AppColors.darkCard.withOpacity(0.85)
                                ]
                              : [
                                  AppColors.surfaceLight.withOpacity(0.85),
                                  AppColors.darkCard.withOpacity(0.65)
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: _isHovered
                              ? widget.feature.gradientColors[0].withOpacity(0.5)
                              : widget.feature.gradientColors[0].withOpacity(0.25),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildIconContainer(),
                          const SizedBox(width: AppDimens.spacingMedium),
                          Expanded(child: _buildTextContent()),
                          _buildArrowIcon(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.feature.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: widget.feature.gradientColors[0].withOpacity(0.6),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              widget.feature.icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.feature.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.feature.subtitle,
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.4,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildArrowIcon() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.translationValues(_isHovered ? 6 : 0, 0, 0),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.feature.gradientColors[0].withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.arrow_forward_rounded,
          size: 20,
          color: widget.feature.gradientColors[0],
        ),
      ),
    );
  }
}

class AnimatedLogoHeader extends StatelessWidget {
  const AnimatedLogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: 'app_logo',
          child: Container(
            height: 140,
            padding: const EdgeInsets.all(AppDimens.spacingMedium),
            child: Image.asset(
              'imagens/logo.png',
              height: 140,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.spacingLarge),
        _buildAppTitle(),
        const SizedBox(height: AppDimens.spacingMedium),
        _buildTagline(),
      ],
    );
  }

  Widget _buildAppTitle() {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: const Text(
        'FITPLANNER',
        style: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          color: Colors.white,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.primaryLight.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Organize • Evolua • Conquiste',
            style: TextStyle(
              color: AppColors.primary.withOpacity(0.95),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// ========== TELA PRINCIPAL ==========
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late final AnimationController _staggerController;
  late final AnimationController _backgroundController;
  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];

  Uint8List? _userPhotoBytes;
  final _auth = FirebaseAuth.instance;

  late final List<FeatureModel> _features;

  @override
  void initState() {
    super.initState();
    _initializeFeatures();
    _setupAnimations();
    _loadUserPhoto();
  }

  void _initializeFeatures() {
    _features = [
      FeatureModel(
        title: 'Planner Fitness',
        subtitle: 'Organize seus treinos semanais',
        icon: Icons.calendar_today_outlined,
        requiresAuth: true,
        widget: const PlannerFitnessScreen(),
        gradientColors: const [AppColors.primary, AppColors.primaryDark],
      ),
      FeatureModel(
        title: 'Alimentos',
        subtitle: 'Tabela nutricional completa',
        icon: Icons.restaurant_menu_rounded,
        requiresAuth: false,
        widget: const DietaScreen(),
        gradientColors: const [AppColors.accentGreen, AppColors.accentGreenDark],
      ),
      FeatureModel(
        title: 'Personal Trainer',
        subtitle: 'Chat com IA personalizada',
        icon: Icons.person_outline_rounded,
        requiresAuth: true,
        widget: const ChatScreen(role: 'personal'),
        gradientColors: const [AppColors.accentPurple, Color(0xFF8E54E9)],
      ),
      FeatureModel(
        title: 'Nutricionista',
        subtitle: 'Orientação nutricional inteligente',
        icon: Icons.local_hospital_outlined,
        requiresAuth: true,
        widget: const ChatScreen(role: 'nutricionista'),
        gradientColors: const [AppColors.accentOrange, Color(0xFFFF6B35)],
      ),
    ];
  }

  void _setupAnimations() {
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    for (int i = 0; i < _features.length; i++) {
      final start = i * 0.1;
      final end = start + 0.6;

      _slideAnimations.add(
        Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );

      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
    }

    _staggerController.forward();
  }

  Future<void> _loadUserPhoto() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      final photoData = snapshot.data()?['photoBase64'];
      if (photoData != null && photoData is String && photoData.isNotEmpty) {
        setState(() {
          _userPhotoBytes = base64Decode(photoData);
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar foto do usuário: $e');
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          const AnimatedParticles(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                _buildHeader(),
                _buildFeaturesList(),
              ],
            ),
          ),
        ],
      ),
      endDrawer: _buildDrawer(),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.darkBg,
                    Color(0xFF0D1117),
                    AppColors.darkCard,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: -150 + math.sin(_backgroundController.value * 2 * math.pi) * 30,
              right: -150 + math.cos(_backgroundController.value * 2 * math.pi) * 30,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100 + math.cos(_backgroundController.value * 2 * math.pi) * 20,
              left: -100 + math.sin(_backgroundController.value * 2 * math.pi) * 20,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentGreen.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 200 + math.sin(_backgroundController.value * 3 * math.pi) * 40,
              right: 100,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentPurple.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [_buildMenuButton()],
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    return Builder(
      builder: (context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.surfaceLight.withOpacity(0.7),
                  AppColors.darkCard.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.menu_rounded,
                color: AppColors.textPrimary.withOpacity(0.95),
                size: 28,
              ),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimens.spacingLarge),
        child: AnimatedLogoHeader(),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return SlideTransition(
              position: _slideAnimations[index],
              child: FadeTransition(
                opacity: _fadeAnimations[index],
                child: Premium3DButton(
                  feature: _features[index],
                  onTap: () => _handleFeatureTap(_features[index]),
                ),
              ),
            );
          },
          childCount: _features.length,
        ),
      ),
    );
  }

  void _handleFeatureTap(FeatureModel feature) {
    final user = _auth.currentUser;

    if (feature.requiresAuth && user == null) {
      _showLoginDialog(feature.title);
      return;
    }

    if (feature.widget != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => feature.widget!,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  void _showLoginDialog(String featureName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusXLarge),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.surfaceLight.withOpacity(0.98),
                    AppColors.darkBg.withOpacity(0.96),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimens.radiusXLarge),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 50,
                    spreadRadius: 15,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogIcon(),
                  const SizedBox(height: AppDimens.spacingLarge),
                  const Text(
                    'Login Necessário',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimens.spacingMedium),
                  Text(
                    'Você precisa estar autenticado para acessar:\n$featureName',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary.withOpacity(0.9),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimens.spacingXLarge),
                  _buildDialogActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogIcon() {return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.5),
            blurRadius: 32,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(
              Icons.lock_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                side: BorderSide(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary.withOpacity(0.9),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                ),
              ),
              child: const Text(
                'Entrar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Drawer _buildDrawer() {
    final user = _auth.currentUser;
    return user == null ? _buildGuestDrawer() : _buildAuthenticatedDrawer(user);
  }

  Drawer _buildGuestDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.surfaceLight.withOpacity(0.98),
                  AppColors.darkBg.withOpacity(0.98),
                ],
              ),
              border: Border(
                left: BorderSide(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildGuestHeader(),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildAuthButton(
                          title: 'Entrar',
                          icon: Icons.login_rounded,
                          gradient: const [AppColors.primary, AppColors.primaryDark],
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LoginScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildAuthButton(
                          title: 'Cadastrar',
                          icon: Icons.person_add_rounded,
                          gradient: const [AppColors.accentGreen, AppColors.accentGreenDark],
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CadastroScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _buildDrawerFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.6),
                  blurRadius: 50,
                  spreadRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 28),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
            ).createShader(bounds),
            child: const Text(
              'FITPLANNER',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Organize • Evolua • Conquiste',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradient[0].withOpacity(0.2),
                gradient[1].withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
            border: Border.all(
              color: gradient[0].withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: AppDimens.spacingMedium),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: gradient[0].withOpacity(0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Drawer _buildAuthenticatedDrawer(User user) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.surfaceLight.withOpacity(0.98),
                  AppColors.darkBg.withOpacity(0.98),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                left: BorderSide(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildDrawerHeader(user),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(AppDimens.spacingMedium),
                      children: [
                        _buildDrawerMenuItem(
                          icon: Icons.person_rounded,
                          title: 'Meu Perfil',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PerfilScreen(
                                  toggleTheme: () {},
                                  changeLanguage: (_) {},
                                  isDarkMode: true,
                                  currentLanguage: 'pt_BR',
                                ),
                              ),
                            );
                          },
                        ),
                        _buildDrawerMenuItem(
                          icon: Icons.help_outline_rounded,
                          title: 'Ajuda',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AjudaScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppDimens.spacingMedium),
                        _buildLogoutButton(),
                      ],
                    ),
                  ),
                  _buildDrawerFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(User user) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingXLarge),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withOpacity(0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.5),
                  blurRadius: 32,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: CircleAvatar(
                backgroundColor: AppColors.darkCard,
                backgroundImage: _userPhotoBytes != null
                    ? MemoryImage(_userPhotoBytes!)
                    : const AssetImage('imagens/logo.png') as ImageProvider,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.spacingMedium),
          Text(
            user.displayName ?? 'Usuário',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.4),
              ),
            ),
            child: Text(
              user.email ?? '',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withOpacity(0.95),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.spacingSmall),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.04),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: AppDimens.spacingMedium),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.primary.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleLogout(),
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.error.withOpacity(0.15),
                AppColors.error.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            border: Border.all(
              color: AppColors.error.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.4),
                  ),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimens.spacingMedium),
              Expanded(
                child: Text(
                  'Sair da Conta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error.withOpacity(0.95),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.error.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusXLarge),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.surfaceLight.withOpacity(0.98),
                    AppColors.darkBg.withOpacity(0.96),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppDimens.radiusXLarge),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      size: 40,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppDimens.spacingLarge),
                  const Text(
                    'Sair da Conta',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: AppDimens.spacingSmall),
                  Text(
                    'Tem certeza que deseja sair?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: AppDimens.spacingXLarge),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.white.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                              side: BorderSide(
                                color: AppColors.textSecondary.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                            ),
                            shadowColor: AppColors.error.withOpacity(0.5),
                            elevation: 8,
                          ),
                          child: const Text(
                            'Sair',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
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
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      
      Navigator.of(context).pop();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingLarge),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.divider.withOpacity(0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppDimens.spacingSmall),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ).createShader(bounds),
                child: const Text(
                  'FITPLANNER',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingSmall),
          Text(
            'Versão 1.0.0 • 2025',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}