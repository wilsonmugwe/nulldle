import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'statistics.dart';

/// ------------------------------------------------------------
/// NulldleText
/// A simple reusable text widget that gives the app a consistent
/// visual identity (pink, bold, monospaced).
/// I use this widget instead of repeatedly styling Text widgets.
/// ------------------------------------------------------------
class NulldleText extends StatelessWidget {
  final String text;
  final double size;

  const NulldleText(this.text, {super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Courier', // consistent retro style across app
        color: Colors.pink, // brand colour
        fontWeight: FontWeight.bold,
        fontSize: size,
      ),
    );
  }
}

/// ------------------------------------------------------------
/// HomeScreen
/// Acts as the main landing page for the app.
/// Shows the title, artwork, short description, and navigation buttons.
/// ------------------------------------------------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Displays a modal dialog explaining gameplay.
  /// This replaces the need for a separate page.
  /// Using AlertDialog keeps instructions lightweight and accessible.
  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('How to Play'),
        content: Text(
          'Guess the hidden five-letter word in six tries.\n\n'
          'After each guess:\n'
          '• Green  = correct letter in the correct spot\n'
          '• Yellow = letter is in the word but wrong spot\n'
          '• Grey   = letter not in the word\n\n'
          'Tip: Use the keyboard colors to guide your next guess!',
        ),
      ),
    );
  }

  /// ------------------------------------------------------------
  /// UI structure
  /// Uses a gradient background and a scrollable column to support
  /// both mobile and desktop screen sizes.
  /// The layout is responsive due to SafeArea + SingleChildScrollView.
  /// ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Full-screen background container with gradient fill.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF0F5), Color(0xFFFDF7FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        // SafeArea prevents overlap with notches and status bars.
        child: SafeArea(
          child: Center(
            // Allows scroll on smaller devices to avoid overflow.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              // ConstrainedBox ensures the layout doesn't stretch on wide screens.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    // ------------------------------------------------------------
                    // Title and image section
                    // ------------------------------------------------------------
                    const NulldleText('Nulldle', size: 48),
                    const SizedBox(height: 12),

                    // App logo or banner image for branding.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset('assets/title.png', width: 220),
                    ),
                    const SizedBox(height: 24),

                    // Introductory text explaining the app goal.
                    const NulldleText(
                      'Can you guess the hidden word in six tries?\n'
                      'Each color tells you how close you are!',
                      size: 16,
                    ),
                    const SizedBox(height: 24),

                    // ------------------------------------------------------------
                    // Navigation buttons: Play, How to Play, View Stats
                    // Each button uses semantic icons and consistent sizing.
                    // ------------------------------------------------------------
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        // Play Game: navigates to GameScreen
                        ElevatedButton.icon(
                          key: const Key('play_button'),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text(
                            'Play Game',
                            style: TextStyle(fontFamily: 'Courier'),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 24,
                            ),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GameScreen()),
                          ),
                        ),

                        // How to Play: opens dialog with rules
                        OutlinedButton.icon(
                          key: const Key('howto_button'),
                          icon: const Icon(Icons.help_outline),
                          label: const Text(
                            'How to Play',
                            style: TextStyle(fontFamily: 'Courier'),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 24,
                            ),
                          ),
                          onPressed: () => _showHowToPlay(context),
                        ),

                        // View Stats: navigates to StatisticsScreen
                        OutlinedButton.icon(
                          key: const Key('stats_button'),
                          icon: const Icon(Icons.insights),
                          label: const Text(
                            'View Stats',
                            style: TextStyle(fontFamily: 'Courier'),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 24,
                            ),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StatisticsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ------------------------------------------------------------
                    // Footer / motivational line
                    // Reinforces engagement and encourages replay.
                    // ------------------------------------------------------------
                    Text(
                      'Track your progress, beat your streak, and have fun!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                      textAlign: TextAlign.center,
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
}
