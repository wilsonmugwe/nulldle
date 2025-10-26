import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/statistics.dart';

/// -----------------------------------------------------------------------------------------
/// Perf helper
/// I keep this tiny logger here so I can turn perf prints on/off.
/// The prefix "PERF" makes it easy to filter in the console.
/// ----------------------------------------------------------------------------------------------
class Perf {
  static const enabled = true; // toggle to false to silence logs later
  static void log(String message) {
    if (enabled) debugPrint('PERF $message');
  }
}

/// --------------------------------------------------------------------------------------------
/// Entry point
/// I measure "time to first frame" here. This is a fair proxy for perceived startup time. I use a post-frame callback because
/// logging right after runApp() fires too early to be useful.
/// ----------------------------------------------------------------------------------------

void main() {
  // I mark the start time as soon as possible.
  final appStart = DateTime.now();

  // I make sure the binding exists before I add frame callbacks.
  WidgetsFlutterBinding.ensureInitialized();

  // When the first frame is drawn, I record elapsed time.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final firstFrameMs = DateTime.now().difference(appStart).inMilliseconds;
    Perf.log('startup_first_frame_ms=$firstFrameMs');
  
  });

  // I launch the app. UI build starts here.
  runApp(const WordleApp());
}

/// ------------------------------------------------------------------------------------------------
/// Root widget
/// I keep the theme setup here. I avoid heavy work in build().
/// The theme uses Material 3 and a pink seed to match the design.
/// -----------------------------------------------------------------------------------------------------
class WordleApp extends StatelessWidget {
  const WordleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // I keep the overlay off by default. If I need a quick visual
      // read on frame performance, I can flip this to true temporarily.
      // (It draws two debug graphs in the top-right corner.)
      showPerformanceOverlay: false,

      debugShowCheckedModeBanner: false,
      title: 'Nulldle',

      // App-wide theme: light, friendly, and consistent.
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),

        // I set a soft background to keep contrast comfortable.
        scaffoldBackgroundColor: const Color(0xFFFDF7FA),

        // Buttons: rounded and touch-friendly.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.pink,
            side: const BorderSide(color: Colors.pink),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shadowColor: Colors.pink.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // I keep routes simple and explicit. This makes testing navigation easy.
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),   // Landing screen
        '/game': (_) => const GameScreen(), // Main gameplay
        '/stats': (_) => const StatisticsScreen(), // Player stats
      },
    );
  }
}

