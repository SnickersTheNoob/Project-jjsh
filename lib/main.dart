import 'package:flutter/material.dart';
import 'splash.dart';
import 'valentine.dart';
import 'success.dart';
import 'abort.dart';
import 'tictactoe.dart';
import 'question_screen.dart';
import 'screens/name_input.dart';
import 'services/music_service.dart';
import 'services/stats_service.dart';
import 'memories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize global services used by several screens.
  await MusicService().init();
  await StatsService().init();
  runApp(const ValentineApp());
}

class ValentineApp extends StatelessWidget {
  const ValentineApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Damian’s Valentine 💖",
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'ComicNeue',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _fadeRoute(const SplashScreen(), settings);
          case '/form':
            return _fadeRoute(const ValentineScreen(), settings);
          case '/success':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return _fadeRoute(
              SuccessScreen(
                name: args['name'] ?? "Someone",
                image: args['image'],
              ),
              settings,
            );
          case '/abort':
            return _fadeRoute(const AbortScreen(), settings);
          case '/gallery':
            // Route to MemoriesScreen (show memories after prize)
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return _fadeRoute(
              MemoriesScreen(name: args['name'] ?? "Someone"),
              settings,
            );
          case '/maze':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return _fadeRoute(
              TicTacToeScreen(name: args['name'] ?? "Someone"),
              settings,
            );
          case '/questions':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return _fadeRoute(
              QuestionScreen(name: args['name'] ?? "Someone"),
              settings,
            );
          case '/name_input':
            return _fadeRoute(const NameInputScreen(), settings);
          default:
            return null;
        }
      },
    );
  }

  PageRouteBuilder _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }
}