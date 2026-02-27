import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class ActivityCenterScreen extends StatefulWidget {
  final Function? onVoiceAssistantPressed;

  const ActivityCenterScreen({super.key, this.onVoiceAssistantPressed});

  @override
  State<ActivityCenterScreen> createState() => _ActivityCenterScreenState();
}

class _ActivityCenterScreenState extends State<ActivityCenterScreen> with TickerProviderStateMixin {
  int _selectedGameIndex = 0;
  late PageController _pageController;

  // Game States
  bool _isGameActive = false;

  // Game 1: Memory Match
  List<String> _matchCards = [];
  List<bool> _matchFlipped = [];
  List<bool> _matchMatched = [];
  int _matchFlippedIndex = -1;
  int _matchScore = 0;
  int _matchAttempts = 0;
  bool _matchGameComplete = false;

  // Game 2: Sequence Memory
  List<Color> _sequenceButtons = [];
  List<int> _sequencePattern = [];
  int _sequenceCurrentStep = 0;
  bool _sequencePlayerTurn = false;
  int _sequenceScore = 0;
  Timer? _sequenceTimer;

  // Game 3: Word Recall
  List<String> _wordPairs = [];
  List<bool> _wordAnswers = [];
  int _wordCurrentIndex = 0;
  int _wordScore = 0;
  bool _wordShowAnswer = false;

  // Game 4: Number Matrix
  List<List<int>> _numberMatrix = [];
  int _numberTarget = 0;
  int _numberScore = 0;
  int _numberTimeLeft = 30;
  Timer? _numberTimer;

  final List<String> _gameTitles = [
    'Memory Match',
    'Sequence Memory',
    'Word Recall',
    'Number Matrix',
  ];

  final List<IconData> _gameIcons = [
    Icons.extension,
    Icons.timeline,
    Icons.menu_book,
    Icons.grid_3x3,
  ];

  final List<Color> _gameColors = [
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.orange,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeMatchGame();
    _initializeSequenceGame();
    _initializeWordGame();
    _initializeNumberGame();
  }

  // Game 1: Memory Match Initialization
  void _initializeMatchGame() {
    List<String> emojis = ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼'];
    List<String> selectedEmojis = emojis.take(4).toList();
    _matchCards = [...selectedEmojis, ...selectedEmojis];
    _matchCards.shuffle(Random());
    _matchFlipped = List.filled(_matchCards.length, false);
    _matchMatched = List.filled(_matchCards.length, false);
    _matchFlippedIndex = -1;
    _matchScore = 0;
    _matchAttempts = 0;
    _matchGameComplete = false;
  }

  void _onMatchCardTap(int index) {
    if (!_isGameActive || _matchMatched[index] || _matchFlipped[index] || _matchGameComplete) return;

    setState(() {
      _matchFlipped[index] = true;

      if (_matchFlippedIndex == -1) {
        _matchFlippedIndex = index;
      } else {
        _matchAttempts++;

        if (_matchCards[_matchFlippedIndex] == _matchCards[index]) {
          _matchMatched[_matchFlippedIndex] = true;
          _matchMatched[index] = true;
          _matchScore += 10;

          if (_matchMatched.every((m) => m)) {
            _matchGameComplete = true;
          }

          _matchFlipped[_matchFlippedIndex] = true;
          _matchFlipped[index] = true;
          _matchFlippedIndex = -1;
        } else {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              setState(() {
                _matchFlipped[_matchFlippedIndex] = false;
                _matchFlipped[index] = false;
                _matchFlippedIndex = -1;
              });
            }
          });
        }
      }
    });
  }

  // Game 2: Sequence Memory
  void _initializeSequenceGame() {
    _sequenceButtons = List.generate(9, (index) => Colors.blue[300]!);
    _sequencePattern = [];
    _sequenceCurrentStep = 0;
    _sequencePlayerTurn = false;
    _sequenceScore = 0;
  }

  void _startSequenceGame() {
    setState(() {
      _isGameActive = true;
      _sequencePattern = [];
      _sequenceScore = 0;
      _nextSequenceRound();
    });
  }

  void _nextSequenceRound() {
    _sequencePlayerTurn = false;
    _sequencePattern.add(Random().nextInt(9));

    int step = 0;
    _sequenceTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (step < _sequencePattern.length) {
        setState(() {
          _sequenceButtons[_sequencePattern[step]] = Colors.white;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          setState(() {
            _sequenceButtons[_sequencePattern[step]] = Colors.blue[300]!;
          });
        });
        step++;
      } else {
        timer.cancel();
        setState(() {
          _sequencePlayerTurn = true;
          _sequenceCurrentStep = 0;
        });
      }
    });
  }

  void _onSequenceButtonTap(int index) {
    if (!_isGameActive || !_sequencePlayerTurn) return;

    if (index == _sequencePattern[_sequenceCurrentStep]) {
      setState(() {
        _sequenceButtons[index] = Colors.green;
        _sequenceCurrentStep++;
      });

      Future.delayed(const Duration(milliseconds: 200), () {
        setState(() {
          _sequenceButtons[index] = Colors.blue[300]!;
        });
      });

      if (_sequenceCurrentStep >= _sequencePattern.length) {
        setState(() {
          _sequenceScore += 10;
          _sequencePlayerTurn = false;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          _nextSequenceRound();
        });
      }
    } else {
      setState(() {
        _sequenceButtons[index] = Colors.red;
        _isGameActive = false;
      });

      Future.delayed(const Duration(milliseconds: 200), () {
        setState(() {
          _sequenceButtons[index] = Colors.blue[300]!;
        });
      });
    }
  }

  // Game 3: Word Recall
  void _initializeWordGame() {
    _wordPairs = [
      'Apple-Fruit',
      'Car-Vehicle',
      'Dog-Animal',
      'Rose-Flower',
      'Table-Furniture',
      'Monday-Day',
      'Winter-Season',
      'Doctor-Profession',
    ];
    _wordPairs.shuffle();
    _wordAnswers = List.filled(_wordPairs.length, false);
    _wordCurrentIndex = 0;
    _wordScore = 0;
    _wordShowAnswer = false;
  }

  void _checkWordAnswer(bool userAnswer) {
    if (!_isGameActive) return;

    String correctAnswer = _wordPairs[_wordCurrentIndex].split('-')[1];
    String word = _wordPairs[_wordCurrentIndex].split('-')[0];
    bool isCorrect = (userAnswer && correctAnswer == word) || (!userAnswer && correctAnswer != word);

    setState(() {
      if (isCorrect) {
        _wordScore += 10;
        _wordAnswers[_wordCurrentIndex] = true;
      }

      if (_wordCurrentIndex < _wordPairs.length - 1) {
        _wordCurrentIndex++;
      } else {
        _isGameActive = false;
      }
    });
  }

  // Game 4: Number Matrix
  void _initializeNumberGame() {
    _generateNewMatrix();
    _numberScore = 0;
    _numberTimeLeft = 30;
  }

  void _generateNewMatrix() {
    _numberMatrix = List.generate(4, (i) => List.generate(4, (j) => Random().nextInt(20) + 1));
    _numberTarget = _numberMatrix[Random().nextInt(4)][Random().nextInt(4)];
  }

  void _startNumberGame() {
    setState(() {
      _isGameActive = true;
      _numberScore = 0;
      _numberTimeLeft = 30;
      _generateNewMatrix();
    });

    _numberTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_numberTimeLeft > 0) {
          _numberTimeLeft--;
        } else {
          timer.cancel();
          setState(() {
            _isGameActive = false;
          });
        }
      });
    });
  }

  void _onNumberTap(int row, int col) {
    if (!_isGameActive) return;

    if (_numberMatrix[row][col] == _numberTarget) {
      setState(() {
        _numberScore += 10;
        _generateNewMatrix();
      });
    }
  }

  void _logout() {
    // Implement logout functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _sequenceTimer?.cancel();
    _numberTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Activity Center', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.onVoiceAssistantPressed != null)
            IconButton(
              onPressed: () => widget.onVoiceAssistantPressed!(),
              icon: const Icon(Icons.mic, color: Colors.white),
              tooltip: 'Voice Assistant',
            ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _gameTitles.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGameIndex = index;
                      _isGameActive = false;
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    });
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: _selectedGameIndex == index
                          ? _gameColors[index].withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedGameIndex == index
                            ? _gameColors[index]
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _gameIcons[index],
                          color: _selectedGameIndex == index
                              ? _gameColors[index]
                              : Colors.grey,
                          size: 30,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _gameTitles[index],
                          style: TextStyle(
                            color: _selectedGameIndex == index
                                ? _gameColors[index]
                                : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedGameIndex = index;
            _isGameActive = false;
          });
        },
        children: [
          // Game 1: Memory Match
          _buildMemoryMatchGame(),

          // Game 2: Sequence Memory
          _buildSequenceMemoryGame(),

          // Game 3: Word Recall
          _buildWordRecallGame(),

          // Game 4: Number Matrix
          _buildNumberMatrixGame(),
        ],
      ),
    );
  }

  Widget _buildMemoryMatchGame() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Game Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Score', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text('$_matchScore', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Attempts', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text('$_matchAttempts', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _initializeMatchGame();
                      _isGameActive = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('New Game'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Game Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _matchCards.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _onMatchCardTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: _matchMatched[index]
                          ? Colors.green[100]
                          : (_matchFlipped[index] ? Colors.white : Colors.purple[100]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _matchMatched[index]
                            ? Colors.green
                            : (_matchFlipped[index] ? Colors.purple : Colors.purple[300]!),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _matchFlipped[index] || _matchMatched[index]
                          ? Text(
                        _matchCards[index],
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

          if (_matchGameComplete)
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
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You completed the game in $_matchAttempts attempts!\nScore: $_matchScore',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSequenceMemoryGame() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Game Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Score', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text('$_sequenceScore', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Level', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text('${_sequencePattern.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                ElevatedButton(
                  onPressed: _startSequenceGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start Game'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Game Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _onSequenceButtonTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _sequenceButtons[index],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          Text(
            _sequencePlayerTurn ? 'Your Turn!' : 'Watch the pattern...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _sequencePlayerTurn ? Colors.green : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordRecallGame() {
    if (_wordPairs.isEmpty) _initializeWordGame();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Game Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Score', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text('$_wordScore', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Progress', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text('${_wordCurrentIndex + 1}/${_wordPairs.length}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _initializeWordGame();
                      _isGameActive = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('New Game'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          if (_wordCurrentIndex < _wordPairs.length)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _wordPairs[_wordCurrentIndex].split('-')[0],
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Is this a:',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _wordPairs[_wordCurrentIndex].split('-')[1],
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _checkWordAnswer(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Yes', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _checkWordAnswer(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('No', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                children: [
                  const Icon(Icons.celebration, size: 60, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    'Game Complete!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your Score: $_wordScore',
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNumberMatrixGame() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Game Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Score', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text('$_numberScore', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Time', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text('$_numberTimeLeft', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
                ElevatedButton(
                  onPressed: _startNumberGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start Game'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Target Number
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              shape: BoxShape.circle,
            ),
            child: Text(
              '$_numberTarget',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ),

          const SizedBox(height: 20),

          // Number Matrix
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 16,
              itemBuilder: (context, index) {
                int row = index ~/ 4;
                int col = index % 4;
                return GestureDetector(
                  onTap: () => _onNumberTap(row, col),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _numberMatrix.isNotEmpty && row < _numberMatrix.length && col < _numberMatrix[row].length
                          ? (_numberMatrix[row][col] == _numberTarget
                          ? Colors.orange[100]
                          : Colors.white)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _numberMatrix.isNotEmpty && row < _numberMatrix.length && col < _numberMatrix[row].length
                            ? (_numberMatrix[row][col] == _numberTarget
                            ? Colors.orange
                            : Colors.grey[300]!)
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _numberMatrix.isNotEmpty && row < _numberMatrix.length && col < _numberMatrix[row].length
                            ? '${_numberMatrix[row][col]}'
                            : '',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _numberMatrix.isNotEmpty && row < _numberMatrix.length && col < _numberMatrix[row].length
                              ? (_numberMatrix[row][col] == _numberTarget
                              ? Colors.orange[800]
                              : Colors.grey[800])
                              : Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Find the number shown above!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}