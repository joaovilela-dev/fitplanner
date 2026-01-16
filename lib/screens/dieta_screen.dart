import 'package:flutter/material.dart';
import 'agua_screen.dart';
import 'macronutrients_screen.dart';
import 'proteinas_screen.dart';
import 'carboidratos_screen.dart';
import 'gorduras_screen.dart';
import 'vitaminas_minerais_screen.dart';
import 'suplementos_screen.dart';
import 'whey_screen.dart';
import 'creatina_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dicas de Nutrição',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF0F1723),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      home: const DietaScreen(),
    );
  }
}

class DietaScreen extends StatefulWidget {
  const DietaScreen({super.key});

  @override
  State<DietaScreen> createState() => _DietaScreenState();
}

class _DietaScreenState extends State<DietaScreen> with TickerProviderStateMixin {
  late AnimationController _headerAnimController;
  late AnimationController _listAnimController;
  late Animation<double> _headerOpacity;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _listAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _headerAnimController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _headerAnimController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _listAnimController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _listAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'title': 'Água: A base de tudo',
        'icon': Icons.water_drop,
        'page': AguaScreen(),
        'gradient': [const Color(0xFF4FC3F7), const Color(0xFF29B6F6)],
      },
      {
        'title': 'Macronutrientes',
        'icon': Icons.restaurant_menu,
        'page': MacronutrientsScreen(),
        'gradient': [const Color(0xFFFF6B6B), const Color(0xFFEE5A6F)],
      },
      {
        'title': 'Proteínas',
        'icon': Icons.fitness_center,
        'page': ProteinasScreen(),
        'gradient': [const Color(0xFFFF6F00), const Color(0xFFFF8F00)],
      },
      {
        'title': 'Carboidratos',
        'icon': Icons.bakery_dining,
        'page': CarboidratosScreen(),
        'gradient': [const Color(0xFFFFA726), const Color(0xFFFB8C00)],
      },
      {
        'title': 'Gorduras',
        'icon': Icons.opacity,
        'page': GordurasScreen(),
        'gradient': [const Color(0xFFFFCA28), const Color(0xFFFFC107)],
      },
      {
        'title': 'Vitaminas e Minerais',
        'icon': Icons.local_florist,
        'page': VitaminasMineraisScreen(),
        'gradient': [const Color(0xFF66BB6A), const Color(0xFF4CAF50)],
      },
      {
        'title': 'Suplementos: Quando e por que usar',
        'icon': Icons.medication,
        'page': SuplementosScreen(),
        'gradient': [const Color(0xFF9C27B0), const Color(0xFF8E24AA)],
      },
      {
        'title': 'Whey Protein',
        'icon': Icons.sports_martial_arts,
        'page': WheyScreen(),
        'gradient': [const Color(0xFF00C9A7), const Color(0xFF92FE9D)],
      },
      {
        'title': 'Creatina',
        'icon': Icons.flash_on,
        'page': CreatinaScreen(),
        'gradient': [const Color(0xFF536DFE), const Color(0xFF3D5AFE)],
      },
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F1723), Color(0xFF06202A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header animado
              FadeTransition(
                opacity: _headerOpacity,
                child: SlideTransition(
                  position: _headerSlide,
                  child: _buildHeader(),
                ),
              ),

              // Lista de cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 400 + (index * 80)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildNutritionCard(
                            context,
                            title: item['title'] as String,
                            icon: item['icon'] as IconData,
                            gradient: item['gradient'] as List<Color>,
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 400),
                                  pageBuilder: (_, __, ___) => item['page'] as Widget,
                                  transitionsBuilder: (_, animation, __, child) {
                                    return FadeTransition(opacity: animation, child: child);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.03),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C9A7), Color(0xFF92FE9D)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Nutrição',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Guia Completo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Domine os fundamentos da nutrição esportiva',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Ícone com gradiente
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Título
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                
                // Seta
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.6),
                    size: 16,
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