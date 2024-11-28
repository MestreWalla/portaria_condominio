import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/configuracoes_controller.dart';
import 'localizations/app_localizations.dart';
import 'routes/app_routes.dart';
import 'theme_provider.dart';
import 'views/splash/splash_screen.dart';
import 'services/notification_service.dart';
import 'utils/page_transitions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase
  await Firebase.initializeApp();

  // Inicializa o SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Inicializa o serviço de notificações
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(MyApp(
    prefs: prefs,
    notificationService: notificationService,
  ));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final NotificationService notificationService;

  const MyApp({
    super.key,
    required this.prefs,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ConfiguracoesController(prefs)),
      ],
      child: Consumer2<ThemeProvider, ConfiguracoesController>(
        builder: (context, themeProvider, configController, child) {
          return MaterialApp(
            navigatorKey: notificationService.navigatorKey,
            title: 'Gestão de Condomínio',
            theme: themeProvider.currentTheme.copyWith(
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: CustomPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
            ),
            locale: configController.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreen(),
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}