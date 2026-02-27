import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class VoiceAssistantService {
  // Simple command recognition
  late SpeechToText _simpleSpeech;
  bool _isSimpleListening = false;

  // Text-to-speech
  late FlutterTts _tts;

  // Callbacks for navigation
  final Function() onRemindersRequest;
  final Function() onEmergencyRequest;
  final Function() onMedicationRequest;
  final Function() onActivityRequest;        // This should open Memory Diary
  final Function() onMemoryGameRequest;      // This should open Games
  final Function(String) onCallContactRequest;
  final Function() onDashboardRequest;
  final Function() onSettingsRequest;
  final Function(String) onCustomCommand;

  // State
  bool _isSpeaking = false;
  bool _isInitialized = false;

  VoiceAssistantService({
    required this.onRemindersRequest,
    required this.onEmergencyRequest,
    required this.onMedicationRequest,
    required this.onActivityRequest,
    required this.onMemoryGameRequest,
    required this.onCallContactRequest,
    required this.onDashboardRequest,
    required this.onSettingsRequest,
    required this.onCustomCommand,
  });

  // Initialize services
  Future<bool> initialize() async {
    try {
      // Initialize simple speech recognition
      _simpleSpeech = SpeechToText();
      _isInitialized = await _simpleSpeech.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) => print('Speech status: $status'),
      );

      // Initialize TTS
      _tts = FlutterTts();
      await _tts.setLanguage("en-US");
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);

      // Set voice (try to use female voice if available)
      var voices = await _tts.getVoices;
      if (voices.isNotEmpty) {
        var femaleVoice = voices.firstWhere(
              (v) => v.toString().contains('female') || v.toString().contains('en-US-x-sfg'),
          orElse: () => voices.first,
        );
        await _tts.setVoice({"name": femaleVoice, "locale": "en-US"});
      }

      // Set completion handler
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      return _isInitialized;
    } catch (e) {
      print('Voice assistant init error: $e');
      return false;
    }
  }

  // Request permissions
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.storage,
    ].request();

    return statuses[Permission.microphone]!.isGranted &&
        statuses[Permission.storage]!.isGranted;
  }

  // Simple command listening (lightweight)
  void startSimpleListening({
    required Function(String) onResult,
    required Function(String) onError,
  }) {
    if (!_isInitialized) {
      onError('Voice assistant not initialized');
      return;
    }

    if (_isSimpleListening) return;

    _isSimpleListening = true;

    _simpleSpeech.listen(
      onResult: (result) {
        String command = result.recognizedWords.toLowerCase();
        print('Recognized: $command');
        onResult(command);

        // Auto-stop after getting a result
        stopSimpleListening();
      },
      onSoundLevelChange: (level) => print('Sound level: $level'),
      cancelOnError: true,
      partialResults: false,
      listenMode: ListenMode.confirmation,
    );
  }

  void stopSimpleListening() {
    if (_isSimpleListening) {
      _simpleSpeech.stop();
      _isSimpleListening = false;
    }
  }

  // Process simple voice command
  Future<void> processSimpleCommand(String command) async {
    command = command.toLowerCase().trim();

    // Navigation commands
    if (command.contains('reminder') ||
        command.contains('remind me') ||
        command.contains('notification')) {
      await speak("Opening reminders");
      onRemindersRequest();
    }
    else if (command.contains('emergency') ||
        command.contains('help') ||
        command.contains('danger')) {
      await speak("Opening emergency contacts");
      onEmergencyRequest();
    }
    else if (command.contains('medication') ||
        command.contains('medicine') ||
        command.contains('pill')) {
      await speak("Opening medication tracker");
      onMedicationRequest();
    }
    // MEMORY DIARY COMMANDS - Now opens the correct screen
    else if (command.contains('memory diary') ||
        command.contains('diary') ||
        command.contains('memories') ||
        command.contains('memory book')) {
      await speak("Opening memory diary");
      onActivityRequest(); // This maps to Memory Diary screen (index 5)
    }
    // GAMES COMMANDS - Opens the Games screen
    else if (command.contains('game') ||
        command.contains('games') ||
        command.contains('play')) {
      await speak("Opening games");
      onMemoryGameRequest(); // This maps to Games screen (index 1)
    }
    else if (command.contains('dashboard') ||
        command.contains('home') ||
        command.contains('main')) {
      await speak("Going to dashboard");
      onDashboardRequest();
    }
    else if (command.contains('setting') ||
        command.contains('preference') ||
        command.contains('config')) {
      await speak("Opening settings");
      onSettingsRequest();
    }

    // Call contact commands
    else if (command.contains('call')) {
      // Extract name from "call [name]"
      RegExp callRegex = RegExp(r'call\s+(\w+)');
      var match = callRegex.firstMatch(command);
      if (match != null && match.groupCount >= 1) {
        String contactName = match.group(1)!;
        await speak("Calling $contactName");
        onCallContactRequest(contactName);
      } else {
        await speak("Who would you like to call?");
      }
    }

    // Help command
    else if (command.contains('help') || command.contains('what can')) {
      await speak(
          "You can say: open reminders, call emergency, show medications, "
              "open memory diary, play games, go to dashboard, or open settings"
      );
    }

    // Custom commands
    else if (command.isNotEmpty) {
      onCustomCommand(command);
    }
  }

  // Text-to-speech
  Future<void> speak(String text) async {
    try {
      _isSpeaking = true;
      await _tts.speak(text);
    } catch (e) {
      print('TTS error: $e');
      _isSpeaking = false;
    }
  }

  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
    }
  }

  bool get isListening => _isSimpleListening;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;

  // Dispose
  void dispose() {
    stopSimpleListening();
    stopSpeaking();
    _tts.stop();
  }
}