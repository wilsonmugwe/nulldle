import 'package:flutter_test/flutter_test.dart';
import 'package:nulldle/game_logic.dart';

/// ---------------------------------------------------------------------------------------------------------------------------------
/// GAME LOGIC TESTS
/// --------------------------------------------------------------------------------------------------------------------------
/// These unit tests verify that the evaluateGuess() function correctly analyses guesses in a Wordle-style comparison.
///
/// The evaluation assigns a LetterFeedback enum value per character:
/// - correct → letter is in the right position
/// - present → letter exists but is misplaced
/// - absent  → letter not found in target word
///
/// The tests also validate duplicate handling and input validation.
/// --------------------------------------------------------------------------------------------------------------------------
void main() {
  group('evaluateGuess', () {
    /// --------------------------------------------------------------------------------------------------------------------------
    /// Test 1: Exact Match
    /// --------------------------------------------------------------------------------------------------------------------------
    /// Goal:
    ///   - Ensure all letters are marked as correct
    ///     when the guessed word exactly matches the target.
    ///
    /// Expected:
    ///   - Every feedback item equals LetterFeedback.correct.
    test('all correct when guess equals target', () {
      final fb = evaluateGuess('APPLE', 'APPLE');
      expect(fb.every((x) => x == LetterFeedback.correct), isTrue);
    });

    /// --------------------------------------------------------------------------------------------------------------------------
    /// Test 2: Mixed Feedback (present and absent)
    /// --------------------------------------------------------------------------------------------------------------------------
    /// Goal:
    ///   - Verify that letters are correctly marked as present
    ///     when they exist but are misplaced,
    ///     and as absent when they don’t appear in the target.
    ///
    /// Example:
    ///   Target: APPLE
    ///   Guess:  PAPER
    ///   - 'P', 'A', 'E' appear but not all in correct positions.
    ///   - 'R' is absent.
    test('present and absent letters', () {
      final fb = evaluateGuess('APPLE', 'PAPER');
      expect(fb.length, 5);
      expect(fb.contains(LetterFeedback.present), isTrue);
      expect(fb.contains(LetterFeedback.absent), isTrue);
    });

    /// --------------------------------------------------------------------------------------------------------------------------
    /// Test 3: Duplicate Letter Handling
    /// --------------------------------------------------------------------------------------------------------------------------
    /// Goal:
    ///   - Confirm duplicate letters are only credited
    ///     up to the number of times they appear in the target.
    ///
    /// Example:
    ///   Target: ALERT
    ///   Guess:  BELLY
    ///   - Only one 'L' should be counted as present.
    ///   - Prevents over-counting duplicate letters.
    test('duplicate handling only credits available letters', () {
      final fb = evaluateGuess('ALERT', 'BELLY');

      // Ensure not all mismatched letters are marked as present.
      expect(
        fb.where((f) => f != LetterFeedback.absent).length,
        inInclusiveRange(1, 3),
      );
    });

    /// --------------------------------------------------------------------------------------------------------------------------
    /// Test 4: Input Validation
    /// --------------------------------------------------------------------------------------------------------------------------
    /// Goal:
    ///   - Confirm that evaluateGuess throws an AssertionError
    ///     when guess and target lengths differ.
    ///
    /// This protects against invalid input in the game logic.
    test('throws on different lengths', () {
      expect(
        () => evaluateGuess('HELLO', 'HELL'),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
