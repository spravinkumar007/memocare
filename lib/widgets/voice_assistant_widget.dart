import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/voice_assistant_service.dart';

class VoiceAssistantWidget extends StatefulWidget {
  final VoiceAssistantService service;
  final VoidCallback onClose;

  const VoiceAssistantWidget({
    super.key,
    required this.service,
    required this.onClose,
  });

  @override
  State<VoiceAssistantWidget> createState() => _VoiceAssistantWidgetState();
}

class _VoiceAssistantWidgetState extends State<VoiceAssistantWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  String _statusText = "Listening...";
  String _recognizedText = "";
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _startListening();
  }

  Future<void> _startListening() async {
    // Check permissions
    if (!await Permission.microphone.isGranted) {
      setState(() {
        _statusText = "Microphone permission required";
      });
      return;
    }

    setState(() {
      _statusText = "Listening...";
      _isProcessing = false;
    });

    widget.service.startSimpleListening(
      onResult: (command) {
        setState(() {
          _recognizedText = command;
          _statusText = "Processing...";
          _isProcessing = true;
        });

        // Process the command
        widget.service.processSimpleCommand(command).then((_) {
          // Close after a delay if not speaking
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && !widget.service.isSpeaking) {
              widget.onClose();
            }
          });
        });
      },
      onError: (error) {
        setState(() {
          _statusText = "Error: $error";
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) widget.onClose();
        });
      },
    );
  }

  @override
  void dispose() {
    widget.service.stopSimpleListening();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: screenWidth * 0.9,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Mic Icon
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isProcessing ? Colors.green : Colors.blue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isProcessing ? Colors.green : Colors.blue).withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isProcessing ? Icons.check : Icons.mic,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Status Text
                    Text(
                      _statusText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isProcessing ? Colors.green[800] : Colors.blue[900],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Recognized Text
                    if (_recognizedText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          '"$_recognizedText"',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Example Commands - UPDATED with Memory Diary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb, color: Colors.amber[800], size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Try saying:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildExampleChip('Reminders', Icons.notifications),
                              _buildExampleChip('Emergency', Icons.emergency),
                              _buildExampleChip('Medications', Icons.medication),
                              _buildExampleChip('Memory diary', Icons.menu_book), // Changed from Activity
                              _buildExampleChip('Games', Icons.extension), // Changed from Memory game
                              _buildExampleChip('Dashboard', Icons.dashboard),
                              _buildExampleChip('Settings', Icons.settings),
                              _buildExampleChip('Help', Icons.help),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Cancel Button - Fixed with proper padding
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: TextButton.icon(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close, color: Colors.red, size: 18),
                label: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(color: Colors.red[200]!),
                  ),
                  minimumSize: const Size(100, 36),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.blue[700]),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}