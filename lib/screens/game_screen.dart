import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'statistics.dart';

/// Stable keys for widget tests.
/// These make it easy to locate widgets during automated tests.
class GameKeys {
  static const guessField   = Key('guess_field');
  static const submitButton = Key('submit_button');
  static const newGameBtn   = Key('new_game_button');
  static const gridCard     = Key('grid_card');
}

/// ------------------------------------------------------------
/// GameScreen: main gameplay page
/// Handles input, feedback, stats, and screen layout.
/// Optional [testWords] and [forcedTarget] make widget tests reproducible.
/// ------------------------------------------------------------
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.testWords,
    this.forcedTarget,
  });

  final List<String>? testWords;   // used only for tests
  final String? forcedTarget;      // used only for tests

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _controller = TextEditingController();

  late List<String> _dictionary;        // loaded word list
  String _targetWord = '';              // current answer
  final List<String> _guesses = [];     // previous guesses
  final int _maxGuesses = 6;            // total allowed tries

  bool _loading = true;                 // blocks input while loading dictionary
  final StatsRepository _statsRepo = StatsRepository(); // shared prefs handler

  /// Keyboard colour map. Each letter starts grey and updates as the game runs.
  Map<String, Color> _keyboardColors = {
    for (var c in 'QWERTYUIOPASDFGHJKLZXCVBNM'.split(''))
      c: Colors.grey.shade300,
  };

  @override
  void initState() {
    super.initState();
    _initData();         // load dictionary or test data
    _statsRepo.init();   // prepare stats storage
  }

  /// Load dictionary file or injected test list.
  Future<void> _initData() async {
    if (widget.testWords != null && widget.testWords!.isNotEmpty) {
      // Test mode path: skip asset load for speed and control.
      _dictionary = widget.testWords!
          .map((w) => w.trim().toLowerCase())
          .where((w) => w.length == 5)
          .toList();
      _targetWord = (widget.forcedTarget ?? _dictionary.first).toLowerCase();
      setState(() => _loading = false);
      return;
    }
    await _loadDictionary(); // normal gameplay path
  }

  @override
  void dispose() {
    // Clean up the text controller to avoid leaks.
    _controller.dispose();
    super.dispose();
  }

  /// Reads the dictionary text asset and picks a random target word.
  Future<void> _loadDictionary() async {
    final dict = await rootBundle.loadString('assets/english_dict.txt');
    setState(() {
      _dictionary = dict
          .split('\n')
          .map((w) => w.trim().toLowerCase())
          .where((w) => w.length == 5)
          .toList();
      _targetWord = _dictionary[Random().nextInt(_dictionary.length)];
      _loading = false; // unlock UI
    });
  }

  /// Decides tile background colour for each letter in a guess.
  /// Green: correct, Yellow: present elsewhere, Grey: absent.
  Color _tileColor(String guess, int index) {
    if (_targetWord[index] == guess[index]) {
      return Colors.green;
    } else if (_targetWord.contains(guess[index])) {
      return Colors.yellow;
    } else {
      return Colors.grey;
    }
  }

  /// Updates the on-screen keyboard colours after each guess.
  /// It never downgrades an already correct (green) key.
  void _updateKeyboard(String guess) {
    for (int i = 0; i < guess.length; i++) {
      final letter = guess[i].toUpperCase();
      final newColor = _tileColor(guess, i);
      final current = _keyboardColors[letter];

      if (current == Colors.green) continue; // never override correct
      if (current == Colors.yellow && newColor == Colors.grey) continue; // keep yellow
      _keyboardColors[letter] = newColor;
    }
  }

  /// Resets all round data while keeping the dictionary.
  void _resetGameState() {
    setState(() {
      _guesses.clear();
      _controller.clear();

      if (widget.testWords != null && widget.testWords!.isNotEmpty) {
        _targetWord = (widget.forcedTarget ??
            widget.testWords![Random().nextInt(widget.testWords!.length)]).toLowerCase();
      } else {
        _targetWord = _dictionary[Random().nextInt(_dictionary.length)];
      }

      _keyboardColors = {
        for (var c in 'QWERTYUIOPASDFGHJKLZXCVBNM'.split(''))
          c: Colors.grey.shade300,
      };
    });
  }

  /// Displays the "You Win" dialog.
  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(":D",
                  style: TextStyle(fontSize: 64, color: Colors.green, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGameState();
              },
              child: const Text("Close",
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 24,
                      color: Colors.pink,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// Displays the "You Lose" dialog.
  void _showLoseAndResetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(":(",
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 64,
                      color: Colors.pink,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGameState();
              },
              child: const Text("Close",
                  style: TextStyle(
                      fontFamily: 'Courier',
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                      fontSize: 24)),
            ),
          ],
        );
      },
    );
  }

  /// Main game logic executed when player submits a word.
  void _submitGuess() {
    if (_loading) return; // still loading dictionary; ignore tap

    final guess = _controller.text.toLowerCase();
    _controller.clear();

    // Validation for input correctness and repetition.
    if (!_dictionary.contains(guess)) {
      _showSnackBar("Not a valid word!");
      return;
    }
    if (_guesses.contains(guess)) {
      _showSnackBar("You already tried that word!");
      return;
    }

    // change: lightweight timing capture for performance testing
    final t0 = DateTime.now();

    setState(() {
      _guesses.add(guess);
      _updateKeyboard(guess);
    });

    // change: log elapsed time for this submission (optional, off in release)
    final elapsed = DateTime.now().difference(t0).inMilliseconds;
    if (kDebugMode) debugPrint('PERF submit_ms=$elapsed');

    // Win condition
    if (guess == _targetWord) {
      _showWinDialog();
      _showSnackBar("You win!");
      _statsRepo.recordWin(
        totalGuessesUsed: _guesses.length,
        incorrectAttempts: (_guesses.length - 1).clamp(0, _maxGuesses),
      );
    }
    // Lose condition
    else if (_guesses.length >= _maxGuesses) {
      _showLoseAndResetDialog();
      _showSnackBar("Out of guesses! Word was $_targetWord");
      _statsRepo.recordLoss(incorrectAttempts: _maxGuesses);
    }
  }

  /// Small wrapper for displaying snack messages.
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // -----------------------------------------------------------------
  // Layout helpers
  // These compute tile/key sizes so all elements fit tightly regardless
  // of screen size.
  // -----------------------------------------------------------------

  double _tileSizeFromWidth(double availableWidth) {
    final double maxTileWidth = (availableWidth - (6 * 8)) / 5;
    return max(30.0, min(maxTileWidth, 56.0));
  }

  Widget _buildKeyboard({
    required double rowWidthAvailable,
    required double keyHeight,
    required double fontSize,
  }) {
    final double keyWidthMaxFromWidth = (rowWidthAvailable - 88.0) / 10.0;
    final double keyWidth = max(22.0, min(keyWidthMaxFromWidth, keyHeight * 0.95));

    const rows = ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.split('').map((letter) {
            final bg = _keyboardColors[letter]!;
            final fg = (bg.computeLuminance() > 0.5) ? Colors.black : Colors.white;
            return Container(
              margin: const EdgeInsets.all(4.0),
              width: keyWidth,
              height: keyHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))
                ],
                border: Border.all(color: Colors.black12),
              ),
              child: Text(letter,
                  style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: fg)),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  /// ------------------------------------------------------------
  /// Build method: constructs the full page layout dynamically.
  /// Responsive layout adjusts tile and keyboard sizes automatically.
  /// ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const double outerPad = 16.0;
    const double gridCardHPad = 16.0;
    const double gridCardVPad = 16.0;
    const double sectionGap = 10.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nulldle'),
        actions: [
          IconButton(
            tooltip: 'New Game',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _resetGameState,
          ),
          IconButton(
            tooltip: 'View Stats',
            icon: const Icon(Icons.insights),
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const StatisticsScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Pre-compute sizes and ensure nothing overflows vertically.
            final double contentWidth = constraints.maxWidth - 2 * outerPad;
            final double gridMaxWidth = min(420.0, contentWidth);
            final double tileSize = _tileSizeFromWidth(gridMaxWidth);

            final double gridHeight = gridCardVPad * 2 + (6 * tileSize) + (7 * 8);
            const double controlsVPad = 12.0;
            final double controlsHeight = controlsVPad * 2 + 48 + 10 + 44;

            final double totalVerticalChrome = (2 * outerPad) + sectionGap + sectionGap;
            final double remainingForKeyboard =
                constraints.maxHeight - gridHeight - controlsHeight - totalVerticalChrome;

            final double keyHeight = max(22.0, (remainingForKeyboard - (4 * 8)) / 3.0);
            final double keyFont = max(10.0, keyHeight * 0.48);

            double finalTileSize = tileSize;
            if (keyHeight <= 22.0) {
              final double targetKeyHeight = 24.0;
              final double needed = (targetKeyHeight * 3.0 + 4 * 8) - remainingForKeyboard;
              final double shrink = max(0.0, needed / 6.0);
              finalTileSize = max(30.0, tileSize - shrink);
            }

            final double finalGridHeight = gridCardVPad * 2 + (6 * finalTileSize) + (7 * 8);
            final double finalRemaining =
                constraints.maxHeight - finalGridHeight - controlsHeight - totalVerticalChrome;
            final double finalKeyHeight = max(22.0, (finalRemaining - (4 * 8)) / 3.0);
            final double finalKeyFont = max(10.0, finalKeyHeight * 0.48);

            return Padding(
              padding: const EdgeInsets.all(outerPad),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 2 * outerPad,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ----- GRID SECTION -----
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: gridMaxWidth),
                          child: Card(
                            key: GameKeys.gridCard,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: gridCardHPad,
                                vertical: gridCardVPad,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(6, (row) {
                                  final String? guess =
                                      row < _guesses.length ? _guesses[row] : null;
                                  return Row(
                                    key: ValueKey(
                                        'guess_row_${row}_${guess?.toUpperCase() ?? ""}'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(5, (col) {
                                      String letter = '';
                                      Color bgColor = Colors.grey.shade300;
                                      if (guess != null && col < guess.length) {
                                        letter = guess[col].toUpperCase();
                                        bgColor = _tileColor(guess, col);
                                      }
                                      return Container(
                                        margin: const EdgeInsets.all(4.0),
                                        width: finalTileSize,
                                        height: finalTileSize,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.black12),
                                          boxShadow: const [
                                            BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 2,
                                                offset: Offset(0, 1))
                                          ],
                                        ),
                                        child: Text(
                                          letter,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    }),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: sectionGap),

                      // ----- INPUT & BUTTONS SECTION -----
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                key: GameKeys.guessField,
                                controller: _controller,
                                enabled: !_loading,
                                maxLines: 1,
                                maxLength: 5,
                                textInputAction: TextInputAction.done,
                                style: const TextStyle(
                                    letterSpacing: 2, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  hintText: "Enter 5-letter word",
                                  counterText: "",
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: Color(0xFFE0E0E0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: Colors.pink, width: 2),
                                  ),
                                ),
                                onSubmitted: (_) => _submitGuess(),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton(
                                    key: GameKeys.submitButton,
                                    onPressed: _loading ? null : _submitGuess,
                                    child: const Text("Submit",
                                        style: TextStyle(
                                            fontFamily: 'Courier',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0)),
                                  ),
                                  ElevatedButton(
                                    key: GameKeys.newGameBtn,
                                    onPressed: _loading ? null : _resetGameState,
                                    child: const Text("New Game",
                                        style: TextStyle(
                                            fontFamily: 'Courier',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0)),
                                  ),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(context).push(MaterialPageRoute(
                                          builder: (_) => const StatisticsScreen()));
                                    },
                                    child: const Text("View Stats",
                                        style: TextStyle(
                                            fontFamily: 'Courier',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: sectionGap),

                      // ----- KEYBOARD SECTION -----
                      Center(
                        child: _buildKeyboard(
                          rowWidthAvailable: gridMaxWidth,
                          keyHeight: finalKeyHeight,
                          fontSize: finalKeyFont,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
