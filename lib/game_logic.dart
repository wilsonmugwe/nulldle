// lib/game_logic.dart

/// ------------------------------------------------------------
/// Enum: LetterFeedback
/// Represents the three possible outcomes for each letter guess:
/// - correct: right letter, right position
/// - present: letter exists but wrong position
/// - absent: letter not in the target word at all
/// ------------------------------------------------------------
enum LetterFeedback { correct, present, absent }

/// ------------------------------------------------------------
/// Function: evaluateGuess
/// Compares a guess to the target word letter by letter.
/// It returns a list of feedback results, one for each letter.
/// Handles duplicate letters properly, so feedback is accurate.
/// ------------------------------------------------------------
List<LetterFeedback> evaluateGuess(String target, String guess) {
  // I use an assert here to catch logic errors early.
  // Both words must have the same length for a fair comparison.
  assert(target.length == guess.length, 'Words must have same length');

  // I normalise both words to uppercase.
  // This makes the comparison case-insensitive.
  final t = target.toUpperCase();
  final g = guess.toUpperCase();

  // This list holds feedback results for each letter position.
  final fb = List<LetterFeedback>.filled(g.length, LetterFeedback.absent);

  // I keep a map of how many unmatched letters remain in the target.
  // This helps handle cases like "apple" vs "plate" correctly.
  final remaining = <String, int>{};

  // First pass: mark letters that are correct and count leftovers.
  for (var i = 0; i < g.length; i++) {
    if (g[i] == t[i]) {
      // Letter is in the right position.
      fb[i] = LetterFeedback.correct;
    } else {
      // Count this target letter as still available to match later.
      remaining[t[i]] = (remaining[t[i]] ?? 0) + 1;
    }
  }

  // Second pass: mark letters that are present but misplaced.
  for (var i = 0; i < g.length; i++) {
    if (fb[i] == LetterFeedback.correct) continue; // skip already matched

    final c = g[i];
    // If this guessed letter exists elsewhere in the target (unused count > 0)
    if ((remaining[c] ?? 0) > 0) {
      fb[i] = LetterFeedback.present;
      remaining[c] = remaining[c]! - 1; // reduce available count
    }
  }

  
  // debugPrint('PERF evaluated guess: $guess vs $target -> $fb');

  return fb;
}
