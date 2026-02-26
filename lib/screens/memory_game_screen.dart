import 'package:flutter/material.dart';
import 'dart:math';

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  List<String> _cards = [];
  List<bool> _flipped = [];
  List<bool> _matched = [];
  int _flippedIndex = -1;
  int _score = 0;
  int _attempts = 0;
  bool _gameComplete = false;

  final List<String> _emojis = [
    '🐶', '🐱', '🐭', '🐹', '🐰', '🦊',
    '🐻', '🐼', '🐨', '🐯', '🦁', '🐮',
  ];

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    // Use 6 pairs for easy difficulty
    final selectedEmojis = _emojis.take(6).toList();
    _cards = [...selectedEmojis, ...selectedEmojis];
    _cards.shuffle(Random());

    _flipped = List.filled(_cards.length, false);
    _matched = List.filled(_cards.length, false);
    _flippedIndex = -1;
    _score = 0;
    _attempts = 0;
    _gameComplete = false;
  }

  void _onCardTap(int index) {
    if (_matched[index] || _flipped[index] || _gameComplete) return;

    setState(() {
      _flipped[index] = true;

      if (_flippedIndex == -1) {
        // First card flipped
        _flippedIndex = index;
      } else {
        // Second card flipped
        _attempts++;

        if (_cards[_flippedIndex] == _cards[index]) {
          // Match found
          _matched[_flippedIndex] = true;
          _matched[index] = true;
          _score += 10;

          // Check if game is complete
          if (_matched.every((m) => m)) {
            _gameComplete = true;
          }

          // Reset flip tracking
          _flipped[_flippedIndex] = true;
          _flipped[index] = true;
          _flippedIndex = -1;
        } else {
          // No match, schedule flip back
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              setState(() {
                _flipped[_flippedIndex] = false;
                _flipped[index] = false;
                _flippedIndex = -1;
              });
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Game'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _initializeGame()),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple[100]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Score Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildScoreItem('Score', '$_score', Icons.star),
                  _buildScoreItem('Attempts', '$_attempts', Icons.touch_app),
                  _buildScoreItem('Matches', '${_matched.where((m) => m).length ~/ 2}', Icons.check_circle),
                ],
              ),
            ),

            if (_gameComplete)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🎉 Congratulations! 🎉',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You completed the game in $_attempts attempts!',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _initializeGame()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Play Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

            // Game Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _onCardTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: _getCardColor(index),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _matched[index]
                              ? Colors.green
                              : Colors.purple[300]!,
                          width: 2,
                        ),
                        boxShadow: [
                          if (!_flipped[index] && !_matched[index])
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Center(
                        child: _flipped[index] || _matched[index]
                            ? Text(
                          _cards[index],
                          style: const TextStyle(fontSize: 30),
                        )
                            : const Icon(
                          Icons.help_outline,
                          size: 30,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Tap cards to find matching pairs',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.purple[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getCardColor(int index) {
    if (_matched[index]) return Colors.green[100]!;
    if (_flipped[index]) return Colors.white;
    return Colors.purple[50]!;
  }
}