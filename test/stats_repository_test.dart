// test/stats_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nulldle/screens/statistics.dart';

/// ------------------------------------------------------------
/// STATS REPOSITORY TESTS
/// ------------------------------------------------------------
/// These tests verify that the StatsRepository class correctly
/// saves and retrieves game data in SharedPreferences.
///
/// The repository handles two main operations:
/// 1. Recording a WIN (updating total wins, streaks, etc.)
/// 2. Recording a LOSS (updating total games and resetting streak)
///
/// SharedPreferences is mocked to simulate local storage.
/// This ensures each test runs in isolation with no real data saved.
/// ------------------------------------------------------------
void main() {
  // Required setup for Flutter’s test environment.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StatsRepository', () {
    late StatsRepository repo;

    /// Called before each test:
    /// - Reset SharedPreferences using an empty mock map.
    /// - Create a fresh instance of StatsRepository.
    /// - Ensure it’s initialised before use.
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = StatsRepository();
      await repo.init();
    });

    /// Test: Record Win
    /// Goal: verify a win updates the expected fields.
    test('records and retrieves a win', () async {
      await repo.recordWin(totalGuessesUsed: 3, incorrectAttempts: 2);
      final stats = await repo.loadStats();
      expect(stats['gamesPlayed'], 1);
      expect(stats['gamesWon'], 1);
      expect((stats['currentStreak'] ?? 0) >= 1, isTrue);
      expect((stats['maxStreak'] ?? 0) >= 1, isTrue);
    });

    /// Test: Record Loss
    /// Goal: verify a loss increments gamesPlayed and keeps gamesWon at 0.
    test('records and retrieves a loss', () async {
      await repo.recordLoss(incorrectAttempts: 6);
      final stats = await repo.loadStats();
      expect(stats['gamesPlayed'], 1);
      expect(stats['gamesWon'], 0);
    });
  });
}
