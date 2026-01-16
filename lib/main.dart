import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'screens/main_menu_screen.dart';
import 'screens/perfil_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa datas pt_BR
  await initializeDateFormatting('pt_BR', null);

  // Mantém apenas retrato
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const FitPlannerApp());
}

class FitPlannerApp extends StatefulWidget {
  const FitPlannerApp({super.key});

  @override
  State<FitPlannerApp> createState() => _FitPlannerAppState();
}

class _FitPlannerAppState extends State<FitPlannerApp> {
  Locale appLocale = const Locale('pt', 'BR');
  bool _isLoadingPreferences = true;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  // CARREGA IDIOMA DO FIREBASE
  Future<void> _loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        if (data.containsKey('idioma')) {
          String idioma = data['idioma'];
          appLocale = idioma == "en_US"
              ? const Locale('en', 'US')
              : const Locale('pt', 'BR');
        }
      }
    }

    setState(() => _isLoadingPreferences = false);
  }

  // MUDAR IDIOMA
  void changeLanguage(String lang) {
    setState(() {
      appLocale = lang == "en_US"
          ? const Locale('en', 'US')
          : const Locale('pt', 'BR');
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    if (_isLoadingPreferences) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitPlanner',

      // SUPORTE DE IDIOMA
      locale: appLocale,
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // TEMA FIXO
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.grey[50],
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
        ).copyWith(secondary: Colors.tealAccent),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),

      home: MainMenuScreen(),
      routes: {
        "/perfil": (_) => PerfilScreen(
              toggleTheme: () {},
              changeLanguage: changeLanguage,
              isDarkMode: false,
              currentLanguage: appLocale.languageCode == "en"
                  ? "en_US"
                  : "pt_BR",
            ),
      },
    );
  }
}
