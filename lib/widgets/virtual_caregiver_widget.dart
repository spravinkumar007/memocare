import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/virtual_caregiver_service.dart';

class VirtualCaregiverWidget extends StatefulWidget {
  final VirtualCaregiverService service;
  final VoidCallback onClose;
  final String patientName;
  final bool autoGreet;
  final String? initialCommand;  // optional command to process immediately

  const VirtualCaregiverWidget({
    super.key,
    required this.service,
    required this.onClose,
    required this.patientName,
    this.autoGreet = false,
    this.initialCommand,
  });

  @override
  State<VirtualCaregiverWidget> createState() => _VirtualCaregiverWidgetState();
}

class _VirtualCaregiverWidgetState extends State<VirtualCaregiverWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  String _statusText = "Initializing...";
  String _partialText = "";
  List<Map<String, dynamic>> _conversationHistory = [];
  bool _isSpeaking = false;
  bool _isProcessing = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    widget.service.mounted = true;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.autoGreet) {
      _autoGreet();
    } else {
      _startListening();
      // If there is an initial command, process it after a short delay
      if (widget.initialCommand != null && widget.initialCommand!.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _processCommand(widget.initialCommand!);
        });
      }
    }
  }

  Future<void> _autoGreet() async {
    String greeting = widget.service.getTimeBasedGreeting(widget.patientName);
    _addToHistory("assistant", greeting);
    setState(() {
      _isSpeaking = true;
      _statusText = "Speaking...";
    });
    await widget.service.speak(greeting, mood: CaregiverMood.cheerful);
    setState(() {
      _isSpeaking = false;
      _statusText = "Listening...";
    });
    _startListening();

    // After greeting, if there is an initial command, process it
    if (widget.initialCommand != null && widget.initialCommand!.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 800), () {
        _processCommand(widget.initialCommand!);
      });
    }
  }

  void _startListening() {
    if (_isListening) return;
    setState(() {
      _isListening = true;
      _statusText = "Listening...";
    });

    widget.service.startContinuousListening(
      onResult: (command) async {
        setState(() {
          _isListening = false;
          _isProcessing = true;
          _statusText = "Processing...";
        });
        _addToHistory("user", command);
        String response = await widget.service.understandAndRespond(command);
        _addToHistory("assistant", response);
        setState(() {
          _isProcessing = false;
          _isSpeaking = true;
          _statusText = "Speaking...";
        });
        await widget.service.speak(response);
        setState(() {
          _isSpeaking = false;
          _statusText = "Listening...";
        });
        _startListening();
      },
      onError: (error) {
        setState(() {
          _statusText = "Error: $error";
          _isListening = false;
        });
        _addToHistory("system", "Error: $error");
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _startListening();
        });
      },
      onPartialResult: (partial) {
        setState(() {
          _partialText = partial;
        });
      },
    );
  }

  Future<void> _processCommand(String command) async {
    // Simulate as if the user spoke it
    setState(() {
      _isListening = false;
      _isProcessing = true;
      _statusText = "Processing...";
    });
    _addToHistory("user", command);
    String response = await widget.service.understandAndRespond(command);
    _addToHistory("assistant", response);
    setState(() {
      _isProcessing = false;
      _isSpeaking = true;
      _statusText = "Speaking...";
    });
    await widget.service.speak(response);
    setState(() {
      _isSpeaking = false;
      _statusText = "Listening...";
    });
    _startListening();
  }

  void _addToHistory(String role, String text) {
    setState(() {
      _conversationHistory.add({
        'role': role,
        'text': text,
        'time': DateTime.now(),
      });
    });
  }

  @override
  void dispose() {
    widget.service.mounted = false;
    widget.service.stopListening();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: screenWidth * 0.92,
        constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple[50]!, Colors.white],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.purple, Colors.purpleAccent]),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.service.caregiverName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isListening ? Colors.green : (_isSpeaking ? Colors.orange : Colors.grey),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _statusText,
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close, color: Colors.white),
                      iconSize: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Conversation history
            Expanded(
              child: _conversationHistory.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.purple[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.mic, size: 50, color: Colors.purple[700]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _statusText,
                      style: TextStyle(fontSize: 18, color: Colors.purple[800], fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    if (_partialText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.purple[200]!),
                        ),
                        child: Text(
                          '"$_partialText"',
                          style: TextStyle(fontSize: 14, color: Colors.purple[800], fontStyle: FontStyle.italic),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      "I'm listening. Say something or tap a quick action.",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _conversationHistory.length,
                itemBuilder: (context, index) {
                  final message = _conversationHistory[index];
                  final isUser = message['role'] == 'user';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
                            child: const Icon(Icons.support_agent, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.blue[100] : Colors.purple[50],
                              borderRadius: BorderRadius.circular(16).copyWith(
                                bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                                bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                              ),
                              border: Border.all(color: isUser ? Colors.blue[200]! : Colors.purple[200]!),
                            ),
                            child: Text(
                              message['text'],
                              style: TextStyle(
                                fontSize: 14,
                                color: isUser ? Colors.blue[900] : Colors.purple[900],
                              ),
                            ),
                          ),
                        ),
                        if (isUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                            child: const Icon(Icons.person, color: Colors.white, size: 18),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Live transcription bar (while listening)
            if (_isListening && _partialText.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.purple[50],
                child: Row(
                  children: [
                    const Icon(Icons.graphic_eq, color: Colors.purple, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _partialText,
                        style: const TextStyle(color: Colors.purple, fontStyle: FontStyle.italic),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Quick action buttons
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!))),
              child: Column(
                children: [
                  const Text("Quick Actions", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickAction(Icons.medication, "Medication", Colors.green, () {
                          widget.service.pauseListening();
                          widget.service.speak("Opening your medications");
                          widget.service.onMedicationRequest();
                        }),
                        _buildQuickAction(Icons.notifications, "Reminders", Colors.orange, () {
                          widget.service.pauseListening();
                          widget.service.speak("Checking your reminders");
                          widget.service.onRemindersRequest();
                        }),
                        _buildQuickAction(Icons.emergency, "Emergency", Colors.red, () {
                          widget.service.pauseListening();
                          widget.service.speak("Opening emergency contacts");
                          widget.service.onEmergencyRequest();
                        }),
                        _buildQuickAction(Icons.menu_book, "Memory", Colors.teal, () {
                          widget.service.pauseListening();
                          widget.service.speak("Opening your memory diary");
                          widget.service.onMemoryDiaryRequest();
                        }),
                        _buildQuickAction(Icons.extension, "Games", Colors.purple, () {
                          widget.service.pauseListening();
                          widget.service.speak("Let's play some games");
                          widget.service.onGamesRequest();
                        }),
                        _buildQuickAction(Icons.emoji_emotions, "Mood", Colors.amber, () {
                          widget.service.pauseListening();
                          widget.service.speak("How are you feeling today?");
                          widget.service.onMoodCheckRequest();
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}