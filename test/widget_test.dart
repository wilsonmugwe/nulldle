import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nulldle/main.dart';
import 'package:nulldle/screens/game_screen.dart';

/// ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// TEST HELPERS
/// ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// These helper functions streamline repetitive setup steps across multiple widget tests.
///
/// Each test uses a clean mock SharedPreferences instance to prevent data persistence between runs. This ensures reproducible, isolated test behaviour.
/// ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/// Pumps the full Nulldle app at the HomeScreen state.
/// Sets a standard device resolution (1080×1920) to
/// stabilise UI rendering during widget tests.
Future<void> pumpHome(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(1080, 1920));
  await tester.pumpWidget(WordleApp());
  await tester.pumpAndSettle(); // Wait for all build frames to complete
}

/// Pumps a seeded GameScreen for deterministic testing.
/// By supplying testWords and a forcedTarget, asset
/// loading is bypassed, making tests faster and repeatable.
Future<void> pumpGame(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(const Size(1080, 1920));

  await tester.pumpWidget(
    const MaterialApp(
      home: GameScreen(
        testWords: ['about', 'zesty', 'cigar', 'proud', 'couch'],
        forcedTarget: 'zesty',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// ------------------------------------------------------------------------------------------------------
/// WIDGET TESTS
/// ------------------------------------------------------------------------------------------------------
/// These tests verify that:
/// 1. The HomeScreen displays its title and navigates
///    correctly to the GameScreen.
/// 2. The GameScreen processes guesses correctly,
///    updates the grid, and resets on "New Game".
/// ------------------------------------------------------------------------------------------------------
void main() {
  /// ------------------------------------------------------------------------------------------------------
  /// Test 1: HomeScreen → GameScreen Navigation
  /// ------------------------------------------------------------------------------------------------------
  /// Goal:
  ///   - Ensure the HomeScreen renders its core elements.
  ///   - Verify the "Play Game" button navigates to GameScreen.
  ///
  /// Method:
  ///   - Render the full app via pumpHome().
  ///   - Locate the title and play button.
  ///   - Tap the play button and expect the GameScreen widget.
  testWidgets('HomeScreen: renders and navigates to GameScreen', (tester) async {
    await pumpHome(tester);

    // Check that the app title renders.
    expect(find.text('Nulldle'), findsOneWidget);

    // Locate the Play Game button using its stable key.
    final playBtn = find.byKey(const Key('play_button'));
    expect(playBtn, findsOneWidget);

    // Simulate navigation to GameScreen.
    await tester.tap(playBtn);
    await tester.pumpAndSettle();

    // Verify that the GameScreen widget is now active.
    expect(find.byType(GameScreen), findsOneWidget);
  });

  /// ----------------------------------------------------------------------------------------------------
  /// Test 2: GameScreen Input and Reset
  /// ------------------------------------------------------------------------------------------------------
  /// Goal:
  ///   - Confirm the game accepts a valid guess,
  ///     displays it in the grid, and resets correctly.
  ///
  /// Method:
  ///   - Pump GameScreen with seeded test words.
  ///   - Enter a valid word, submit it, verify the grid updates.
  ///   - Tap "New Game" and confirm the grid clears.
  testWidgets('GameScreen: submit guess and New Game clears it', (tester) async {
    await pumpGame(tester);

    // Find UI elements by their assigned keys.
    final field   = find.byKey(const Key('guess_field'));
    final submit  = find.byKey(const Key('submit_button'));
    final newGame = find.byKey(const Key('new_game_button'));

    // Sanity check: all required controls are visible.
    expect(field, findsOneWidget);
    expect(submit, findsOneWidget);
    expect(newGame, findsOneWidget);

    // Step 1: Enter and submit a valid guess.
    await tester.enterText(field, 'ABOUT');
    await tester.tap(submit);
    await tester.pumpAndSettle();

    // Verify the grid shows the guess row (row 0 with text ABOUT).
    expect(find.byKey(const ValueKey('guess_row_0_ABOUT')), findsOneWidget);

    // Step 2: Tap "New Game" to reset.
    await tester.tap(newGame);
    await tester.pumpAndSettle();

    // Confirm the grid was cleared of the previous guess.
    expect(find.byKey(const ValueKey('guess_row_0_ABOUT')), findsNothing);

    // Confirm the game grid card remains visible.
    expect(find.byKey(const Key('grid_card')), findsOneWidget);
  });
}
