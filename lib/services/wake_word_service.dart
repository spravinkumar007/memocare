import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class WakeWordService {
  final SpeechToText _speech = SpeechToText();
  bool _listening = false;
  bool _shouldListen = false;
  final List<String> _wakeWords = ["memo", "emergency"];  // Accepts both
  Function(String)? _onWakeWordDetected;
  Timer? _restartTimer;
  Function(String)? onDebug;

  bool get isActive => _listening;

  Future<bool> initialize({Function(String)? onDebugLog}) async {
    onDebug = onDebugLog;
    _log("Initializing wake word engine...");
    bool available = await _speech.initialize(
      onError: (e) => _log("Error: $e"),
      onStatus: (status) {
        _log("Status: $status");
        if (status == "notListening" && _shouldListen && !_listening) {
          _log("Restarting listener...");
          _restartListening();
        }
      },
    );
    _log("Speech available: $available");
    return available;
  }

  Future<bool> requestPermissions() async {
    final status = await Permission.microphone.request();
    _log("Mic permission: ${status.isGranted}");
    return status.isGranted;
  }

  void startListening(Function(String) onDetected) {
    _log("startListening called");
    _onWakeWordDetected = onDetected;
    _shouldListen = true;
    if (!_listening) _start();
  }

  void stopListening() {
    _log("stopListening called");
    _shouldListen = false;
    _restartTimer?.cancel();
    _stop();
  }

  void _start() {
    if (!_shouldListen) return;
    if (_speech.isListening) return;

    _log("Listening for ${_wakeWords.join(' or ')}...");
    _speech.listen(
      onResult: (result) {
        if (!_shouldListen) return;
        String text = result.recognizedWords.toLowerCase();
        _log("Heard: '$text'");
        for (String word in _wakeWords) {
          if (text.contains(word)) {
            _log("✅ WAKE WORD DETECTED: '$word'");
            _onWakeWordDetected?.call(text);
            _stop();
            Future.delayed(const Duration(seconds: 2), () {
              if (_shouldListen && !_listening) _start();
            });
            break;
          }
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      onSoundLevelChange: (_) {},
      cancelOnError: false,
    );
    _listening = true;
  }

  void _stop() {
    if (_speech.isListening) _speech.stop();
    _listening = false;
  }

  void _restartListening() {
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 800), () {
      if (_shouldListen && !_listening) _start();
    });
  }

  void dispose() {
    _shouldListen = false;
    _restartTimer?.cancel();
    _stop();
    _speech.cancel();
  }

  void _log(String msg) {
    print("[WakeWord] $msg");
    onDebug?.call(msg);
  }
}