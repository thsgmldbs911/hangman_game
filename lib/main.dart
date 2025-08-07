
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hangman Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CategorySelectionPage(), // Start with category selection
    );
  }
}

class CategorySelectionPage extends StatefulWidget {
  const CategorySelectionPage({super.key});

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  Map<String, List<String>> _wordCategories = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWordCategories();
  }

  Future<void> _loadWordCategories() async {
    final String response = await DefaultAssetBundle.of(context).loadString('assets/words.json');
    final data = json.decode(response);
    setState(() {
      _wordCategories = Map<String, List<String>>.from(data.map((key, value) => MapEntry(key, List<String>.from(value))));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Category'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two columns for categories
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3, // Make buttons wider
                ),
                itemCount: _wordCategories.keys.length,
                itemBuilder: (context, index) {
                  final category = _wordCategories.keys.elementAt(index);
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GamePage(category: category, words: _wordCategories[category]!),
                        ),
                      );
                    },
                    child: Text(category),
                  );
                },
              ),
            ),
    );
  }
}

class GamePage extends StatefulWidget {
  final String category;
  final List<String> words;

  const GamePage({super.key, required this.category, required this.words});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late String word;
  List<String> guessedLetters = [];
  int incorrectGuesses = 0;

  @override
  void initState() {
    super.initState();
    _selectRandomWord();
  }

  void _selectRandomWord() {
    word = widget.words[Random().nextInt(widget.words.length)];
  }

  String get maskedWord {
    return word.split('').map((letter) {
      return guessedLetters.contains(letter) ? letter : '_';
    }).join(' ');
  }

  void guessLetter(String letter) {
    setState(() {
      if (!guessedLetters.contains(letter)) {
        guessedLetters.add(letter);
        if (!word.contains(letter)) {
          incorrectGuesses++;
        }
      }
      checkGameEnd();
    });
  }

  void checkGameEnd() {
    bool won = !maskedWord.contains('_');
    bool lost = incorrectGuesses >= 9;

    if (won || lost) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(won ? 'You Won!' : 'You Lost!'),
            content: Text('The word was: $word'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  resetGame();
                },
                child: const Text('Play Again'),
              ),
            ],
          );
        },
      );
    }
  }

  void resetGame() {
    setState(() {
      guessedLetters = [];
      incorrectGuesses = 0;
      _selectRandomWord();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hangman - ${widget.category}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: resetGame,
            tooltip: 'New Game',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hangman Figure
            Expanded(
              flex: 3,
              child: Center(
                child: HangmanFigure(incorrectGuesses: incorrectGuesses),
              ),
            ),
            // Masked Word
            Expanded(
              flex: 1,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    maskedWord,
                    style: const TextStyle(fontSize: 40, letterSpacing: 8),
                  ),
                ),
              ),
            ),
            // Alphabet Keyboard
            Expanded(
              flex: 3,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final spacing = screenWidth * 0.02; // 2% of screen width for spacing
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: 1.0, // Ensure buttons are square
                    ),
                    itemCount: 26,
                    itemBuilder: (context, index) {
                      final letter = String.fromCharCode('A'.codeUnitAt(0) + index);
                      final isGuessed = guessedLetters.contains(letter);
                      final isCorrect = word.contains(letter);
                      
                      return ElevatedButton(
                        onPressed: isGuessed ? null : () => guessLetter(letter),
                        style: ButtonStyle(
                          padding: MaterialStateProperty.all(EdgeInsets.zero),
                          backgroundColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                            if (isGuessed) {
                              return isCorrect ? Colors.green : Colors.red;
                            }
                            return Colors.grey; // Default color for unguessed letters
                          }),
                        ),
                        child: Text(letter),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HangmanFigure extends StatelessWidget {
  final int incorrectGuesses;

  const HangmanFigure({super.key, required this.incorrectGuesses});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final figureSize = Size.square(size.shortestSide * 0.8); // Use 80% of the shortest side
        return CustomPaint(
          size: figureSize,
          painter: HangmanPainter(incorrectGuesses),
        );
      },
    );
  }
}

class HangmanPainter extends CustomPainter {
  final int incorrectGuesses;

  HangmanPainter(this.incorrectGuesses);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Base
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);

    // Pole
    if (incorrectGuesses >= 1) {
      canvas.drawLine(Offset(size.width * 0.2, size.height), Offset(size.width * 0.2, size.height * 0.1), paint);
    }

    // Top bar
    if (incorrectGuesses >= 2) {
      canvas.drawLine(Offset(size.width * 0.2, size.height * 0.1), Offset(size.width * 0.7, size.height * 0.1), paint);
    }

    // Rope
    if (incorrectGuesses >= 3) {
      canvas.drawLine(Offset(size.width * 0.7, size.height * 0.1), Offset(size.width * 0.7, size.height * 0.2), paint);
    }

    // Head
    if (incorrectGuesses >= 4) {
      canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.25), size.width * 0.05, paint);
    }

    // Body
    if (incorrectGuesses >= 5) {
      canvas.drawLine(Offset(size.width * 0.7, size.height * 0.3), Offset(size.width * 0.7, size.height * 0.5), paint);
    }

    // Left Arm
    if (incorrectGuesses >= 6) {
      canvas.drawLine(Offset(size.width * 0.7, size.height * 0.35), Offset(size.width * 0.6, size.height * 0.45), paint);
    }

    // Right Arm
    if (incorrectGuesses >= 7) {
      canvas.drawLine(Offset(size.width * 0.7, size.height * 0.35), Offset(size.width * 0.8, size.height * 0.45), paint);
    }

    // Left Leg
    if (incorrectGuesses >= 8) {
      canvas.drawLine(Offset(size.width * 0.7, size.height * 0.5), Offset(size.width * 0.6, size.height * 0.6), paint);
    }

    // Right Leg
    if (incorrectGuesses >= 9) {
      canvas.drawLine(Offset(size.width * 0.7, size.height * 0.5), Offset(size.width * 0.8, size.height * 0.6), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate as HangmanPainter).incorrectGuesses != incorrectGuesses;
  }
}
