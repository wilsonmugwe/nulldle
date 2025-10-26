import 'dart:math' show max;
import 'package:flutter/foundation.dart'; // change: for kDebugMode (perf logs)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ------------------------------------------------------------
/// SharedPreferences keys (legacy totals shown in your UI)
/// I keep these for backward compatibility with the current screen.
/// ------------------------------------------------------------
const _kTotalGames = 'totalGames';
const _kTotalWins = 'totalWins';
const _kTotalLosses = 'totalLosses';
const _kTotalIncorrectAttempts = 'totalIncorrectAttempts';
const _kTotalGuessesOnWins = 'totalGuessesOnWins';

/// ------------------------------------------------------------
/// New keys (streak-style metrics expected by unit tests)
/// These do not drive the current UI yet. They are for tests.
/// ------------------------------------------------------------
const _kGamesPlayed = 'gamesPlayed';
const _kGamesWon = 'gamesWon';
const _kCurrentStreak = 'currentStreak';
const _kMaxStreak = 'maxStreak';

/// ------------------------------------------------------------
/// GameStats: immutable snapshot of statistics in memory.
/// All values are totals. I compute rates and averages on demand.
/// ------------------------------------------------------------
class GameStats {
  final int totalGames;
  final int totalWins;
  final int totalLosses;
  // Sum of incorrect attempts across finished games.
  final int totalIncorrectAttempts;
  // Sum of guesses used in all wins. Used for average.
  final int totalGuessesOnWins;

  const GameStats({
    required this.totalGames,
    required this.totalWins,
    required this.totalLosses,
    required this.totalIncorrectAttempts,
    required this.totalGuessesOnWins,
  });

  /// Win rate in percent. Zero if no games played.
  double get winRate => totalGames == 0 ? 0 : (totalWins / totalGames) * 100.0;

  /// Average guesses when the player wins. Zero if no wins.
  double get avgGuessesPerWin =>
      totalWins == 0 ? 0 : (totalGuessesOnWins / totalWins);

  /// Average incorrect attempts per game. Zero if no games.
  double get avgIncorrectPerGame =>
      totalGames == 0 ? 0 : (totalIncorrectAttempts / totalGames);

  /// Create a modified copy with only selected fields changed.
  GameStats copyWith({
    int? totalGames,
    int? totalWins,
    int? totalLosses,
    int? totalIncorrectAttempts,
    int? totalGuessesOnWins,
  }) {
    return GameStats(
      totalGames: totalGames ?? this.totalGames,
      totalWins: totalWins ?? this.totalWins,
      totalLosses: totalLosses ?? this.totalLosses,
      totalIncorrectAttempts:
          totalIncorrectAttempts ?? this.totalIncorrectAttempts,
      totalGuessesOnWins:
          totalGuessesOnWins ?? this.totalGuessesOnWins,
    );
  }

  /// Load legacy totals from SharedPreferences.
  static Future<GameStats> load(SharedPreferences p) async {
    return GameStats(
      totalGames: p.getInt(_kTotalGames) ?? 0,
      totalWins: p.getInt(_kTotalWins) ?? 0,
      totalLosses: p.getInt(_kTotalLosses) ?? 0,
      totalIncorrectAttempts: p.getInt(_kTotalIncorrectAttempts) ?? 0,
      totalGuessesOnWins: p.getInt(_kTotalGuessesOnWins) ?? 0,
    );
  }

  /// Save legacy totals to SharedPreferences.
  Future<void> save(SharedPreferences p) async {
    await p.setInt(_kTotalGames, totalGames);
    await p.setInt(_kTotalWins, totalWins);
    await p.setInt(_kTotalLosses, totalLosses);
    await p.setInt(_kTotalIncorrectAttempts, totalIncorrectAttempts);
    await p.setInt(_kTotalGuessesOnWins, totalGuessesOnWins);
  }
}

/// ------------------------------------------------------------
/// StatsRepository: small wrapper around SharedPreferences.
/// I keep init() idempotent. Methods call init() to be safe.
/// I also add light perf logs to support the Performance section.
/// ------------------------------------------------------------
class StatsRepository {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Returns a snapshot of legacy totals for the UI.
  Future<GameStats> getStats() async {
    await init();
    // change: light perf timing for load
    final t0 = DateTime.now();
    final s = await GameStats.load(_prefs!);
    final ms = DateTime.now().difference(t0).inMilliseconds;
    if (kDebugMode) debugPrint('PERF stats_load_ms=$ms'); // change
    return s;
  }

  /// Unit-test friendly loader for the new keys.
  Future<Map<String, int>> loadStats() async {
    await init();
    final p = _prefs!;
    return {
      _kGamesPlayed: p.getInt(_kGamesPlayed) ?? 0,
      _kGamesWon: p.getInt(_kGamesWon) ?? 0,
      _kCurrentStreak: p.getInt(_kCurrentStreak) ?? 0,
      _kMaxStreak: p.getInt(_kMaxStreak) ?? 0,
    };
  }

  // Note: helpers kept for future use and clarity.
  Future<void> _setInt(String key, int value) async {
    await init();
    await _prefs!.setInt(key, value);
  }

  int _getInt(String key) => _prefs!.getInt(key) ?? 0;

  /// Record a finished win.
  /// Updates both legacy totals and new streak keys.
  Future<void> recordWin({
    required int totalGuessesUsed,
    required int incorrectAttempts,
  }) async {
    await init();
    final p = _prefs!;

    // change: perf timing around a full write path
    final t0 = DateTime.now();

    // ---- Legacy totals (drive the visible UI) ----
    final legacy = await GameStats.load(p);
    final updatedLegacy = legacy.copyWith(
      totalGames: legacy.totalGames + 1,
      totalWins: legacy.totalWins + 1,
      totalGuessesOnWins: legacy.totalGuessesOnWins + totalGuessesUsed,
      totalIncorrectAttempts: legacy.totalIncorrectAttempts + incorrectAttempts,
    );
    await updatedLegacy.save(p);

    // ---- New streak keys (used by tests) ----
    final gamesPlayed = (p.getInt(_kGamesPlayed) ?? 0) + 1;
    final gamesWon = (p.getInt(_kGamesWon) ?? 0) + 1;
    final currentStreak = (p.getInt(_kCurrentStreak) ?? 0) + 1;
    final maxStreak = max(currentStreak, p.getInt(_kMaxStreak) ?? 0);

    await p.setInt(_kGamesPlayed, gamesPlayed);
    await p.setInt(_kGamesWon, gamesWon);
    await p.setInt(_kCurrentStreak, currentStreak);
    await p.setInt(_kMaxStreak, maxStreak);

    final ms = DateTime.now().difference(t0).inMilliseconds;
    if (kDebugMode) debugPrint('PERF stats_record_win_ms=$ms'); // change
  }

  /// Record a finished loss.
  /// Updates both legacy totals and new streak keys.
  Future<void> recordLoss({required int incorrectAttempts}) async {
    await init();
    final p = _prefs!;

    // change: perf timing around a full write path
    final t0 = DateTime.now();

    // ---- Legacy totals (drive the visible UI) ----
    final legacy = await GameStats.load(p);
    final updatedLegacy = legacy.copyWith(
      totalGames: legacy.totalGames + 1,
      totalLosses: legacy.totalLosses + 1,
      totalIncorrectAttempts: legacy.totalIncorrectAttempts + incorrectAttempts,
    );
    await updatedLegacy.save(p);

    // ---- New streak keys (used by tests) ----
    final gamesPlayed = (p.getInt(_kGamesPlayed) ?? 0) + 1;
    await p.setInt(_kGamesPlayed, gamesPlayed);

    // Loss breaks the streak.
    await p.setInt(_kCurrentStreak, 0);
    // _kGamesWon stays the same. _kMaxStreak stays the same.

    final ms = DateTime.now().difference(t0).inMilliseconds;
    if (kDebugMode) debugPrint('PERF stats_record_loss_ms=$ms'); // change
  }

  /// Reset all stored statistics to zero.
  Future<void> resetAll() async {
    await init();

    // change: perf timing for reset path
    final t0 = DateTime.now();

    // Clear legacy totals.
    const zero = GameStats(
      totalGames: 0,
      totalWins: 0,
      totalLosses: 0,
      totalIncorrectAttempts: 0,
      totalGuessesOnWins: 0,
    );
    await zero.save(_prefs!);

    // Clear new streak-based keys.
    await _prefs!.setInt(_kGamesPlayed, 0);
    await _prefs!.setInt(_kGamesWon, 0);
    await _prefs!.setInt(_kCurrentStreak, 0);
    await _prefs!.setInt(_kMaxStreak, 0);

    final ms = DateTime.now().difference(t0).inMilliseconds;
    if (kDebugMode) debugPrint('PERF stats_reset_ms=$ms'); // change
  }
}

/// ------------------------------------------------------------
/// StatisticsScreen
/// Shows totals and derived metrics. Allows a reset.
/// I keep the layout simple and readable.
/// ------------------------------------------------------------
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatsRepository _repo = StatsRepository();
  GameStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Load stats, then refresh the screen.
  Future<void> _load() async {
    final s = await _repo.getStats();
    if (!mounted) return;
    setState(() {
      _stats = s;
      _loading = false;
    });
  }

  /// Ask for confirmation, then reset and reload.
  Future<void> _confirmAndReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Statistics?'),
        content: const Text(
          'This will clear all stored stats. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repo.resetAll();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _stats == null) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final s = _stats!;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _statCard(context,
                icon: Icons.sports_esports,
                label: 'Games Played',
                value: s.totalGames.toString()),
            _statCard(context,
                icon: Icons.emoji_events,
                label: 'Wins',
                value: s.totalWins.toString()),
            _statCard(context,
                icon: Icons.cancel,
                label: 'Losses',
                value: s.totalLosses.toString()),

            // Win rate with a simple progress bar.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Win Rate',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (s.winRate / 100).clamp(0, 1).toDouble(),
                      minHeight: 10,
                      backgroundColor: Colors.black12,
                      color: Colors.pink,
                    ),
                    const SizedBox(height: 8),
                    Text('${s.winRate.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ),

            _statCard(context,
                icon: Icons.tag,
                label: 'Avg Guesses (Wins)',
                value: s.avgGuessesPerWin.toStringAsFixed(2)),
            _statCard(context,
                icon: Icons.report,
                label: 'Avg Incorrect / Game',
                value: s.avgIncorrectPerGame.toStringAsFixed(2)),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _confirmAndReset,
              child: const Text('Reset Statistics'),
            ),
          ],
        ),
      ),
    );
  }

  /// Small card helper for list items.
  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.pink.withOpacity(0.12),
          child: Icon(icon, color: Colors.pink),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
