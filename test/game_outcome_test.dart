import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nulldle/screens/game_screen.dart';

/// ------------------------------------------------------------
/// GAME OUTCOME TESTS
/// ------------------------------------------------------------
/// These widget tests verify end-game behaviour in Nulldle:
/// 1. The app correctly detects a WIN when the player guesses
///    the target word.
/// 2. The app correctly detects a LOSS after six incorrect guesses.
///
/// Using Flutter’s widget test framework lets us simulate user input and verify UI changes (dialogs, icons, or text output) without manually interacting with the app.
///
/// SharedPreferences is mocked so test results don’t interfere
/// with real user data.
/// ------------------------------------------------------------
void main() {
  // Required to initialise the Flutter testing environment.
  TestWidgetsFlutterBinding.ensureInitialized();

  /// ------------------------------------------------------------
  /// Test 1: Win Condition
  /// ------------------------------------------------------------
  /// Goal:
  ///  - Simulate a user correctly guessing the word.
  ///  - Expect the win dialog to appear with a smiley ":D".
  ///
  /// Method:
  ///  - Mock SharedPreferences to start with clean data.
  ///  - Load GameScreen with a forced target "about".
  ///  - Enter "ABOUT" and press submit.
  ///  - Wait for animations to complete, then check output.
  testWidgets('shows win dialog when correct word guessed', (tester) async {
    // Resets any saved stats for an isolated test environment.
    SharedPreferences.setMockInitialValues({});

    // Load GameScreen in a test MaterialApp wrapper.
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          testWords: ['about'],  // test dictionary
          forcedTarget: 'about', // preselected winning word
        ),
      ),
    );
    await tester.pumpAndSettle(); // wait for build and animations

    // Enter correct guess.
    await tester.enterText(find.byKey(const Key('guess_field')), 'ABOUT');
    await tester.tap(find.byKey(const Key('submit_button')));
    await tester.pumpAndSettle(); // allow UI updates to complete

    // Verify win outcome.
    expect(find.text(':D'), findsOneWidget); // Win dialog shown
  });

  /// ------------------------------------------------------------
  /// Test 2: Lose Condition
  /// ------------------------------------------------------------
  /// Goal:
  ///  - Ensure app shows a lose dialog after six valid incorrect guesses.
  ///  - This checks that the max guess limit and result logic are correct.
  ///
  /// Method:
  ///  - Provide a seed list of valid words (including target).
  ///  - Force the target to 'about'.
  ///  - Enter six unique incorrect guesses.
  ///  - Expect the ":(" lose icon to appear.
  testWidgets('shows lose dialog after 6 incorrect valid guesses', (tester) async {
    SharedPreferences.setMockInitialValues({});

    // Sample word set, includes both target and distractors.
    const seed = [
      'about', 'zesty', 'cigar', 'proud', 'couch', 'teary', 'fuzzy', 'knack'
    ];

    // Load the game with forced target and known dictionary.
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          testWords: seed,
          forcedTarget: 'about', // target word
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find the main input field and submit button using stable keys.
    final field = find.byKey(const Key('guess_field'));
    final submit = find.byKey(const Key('submit_button'));

    // Simulate six distinct incorrect guesses.
    // All words exist in dictionary to avoid "invalid word" errors.
    for (final g in ['zesty', 'cigar', 'proud', 'couch', 'teary', 'fuzzy']) {
      await tester.enterText(field, g.toUpperCase());
      await tester.tap(submit);
      await tester.pumpAndSettle();
    }

    // Verify lose outcome.
    expect(find.text(':('), findsOneWidget); // Lose dialog shown
  });
}
