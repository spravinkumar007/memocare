import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum CaregiverMood {
  cheerful,
  calm,
  encouraging,
  concerned,
  celebratory,
}

class VirtualCaregiverService {
  late SpeechToText _speech;
  bool _isListening = false;
  bool _isListeningContinuous = false;
  late FlutterTts _tts;
  bool _isSpeaking = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _caregiverName = "Ella";
  CaregiverMood _currentMood = CaregiverMood.cheerful;
  String _lastUserInput = "";
  DateTime _lastInteraction = DateTime.now();
  int _interactionCount = 0;
  Map<String, dynamic> _patientData = {};
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _emergencyContacts = [];

  final Function() onRemindersRequest;
  final Function() onEmergencyRequest;
  final Function() onMedicationRequest;
  final Function() onMemoryDiaryRequest;
  final Function() onGamesRequest;
  final Function() onDashboardRequest;
  final Function(String) onCallContactRequest;
  final Function(String) onSendMessageRequest;
  final Function() onMoodCheckRequest;
  final Function()? onEmergencyAlertSent;

  Function(String)? _onPartialResultCallback;
  Function(String)? _onFinalResultCallback;
  Function(String)? _onErrorCallback;
  Timer? _listeningTimer;

  VirtualCaregiverService({
    required this.onRemindersRequest,
    required this.onEmergencyRequest,
    required this.onMedicationRequest,
    required this.onMemoryDiaryRequest,
    required this.onGamesRequest,
    required this.onDashboardRequest,
    required this.onCallContactRequest,
    required this.onSendMessageRequest,
    required this.onMoodCheckRequest,
    this.onEmergencyAlertSent,
  });

  Future<bool> initialize() async {
    try {
      _speech = SpeechToText();
      bool speechAvailable = await _speech.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) => print('Speech status: $status'),
      );
      _tts = FlutterTts();
      await _tts.setLanguage("en-US");
      await _tts.setPitch(1.1);
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      var voices = await _tts.getVoices;
      if (voices.isNotEmpty) {
        var femaleVoice = voices.firstWhere(
              (v) => v.toString().contains('female') || v.toString().contains('en-US-x-sfg'),
          orElse: () => voices.first,
        );
        await _tts.setVoice({"name": femaleVoice, "locale": "en-US"});
      }
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        if (_isListeningContinuous) _startContinuousListening();
      });
      await _loadPatientData();
      return speechAvailable;
    } catch (e) {
      print('Virtual caregiver init error: $e');
      return false;
    }
  }

  Future<void> _loadPatientData() async {
    try {
      _patientData['name'] = await _storage.read(key: 'patient_name') ?? 'Friend';

      final medsData = await _storage.read(key: 'medications_list');
      if (medsData != null) {
        _medications = List<Map<String, dynamic>>.from(jsonDecode(medsData));
      }

      final remindersData = await _storage.read(key: 'patient_reminders');
      if (remindersData != null) {
        _reminders = List<Map<String, dynamic>>.from(jsonDecode(remindersData));
      }

      _emergencyContacts = [];
      for (int i = 0; i < 2; i++) {
        final name = await _storage.read(key: 'emergency_contact_${i}_name');
        final phone = await _storage.read(key: 'emergency_contact_${i}_phone');
        final relation = await _storage.read(key: 'emergency_contact_${i}_relation');
        if (name != null && phone != null && name.isNotEmpty && phone.isNotEmpty) {
          _emergencyContacts.add({'name': name, 'phone': phone, 'relation': relation ?? ''});
          print("✅ Loaded emergency contact ${i+1}: $name, $phone");
        }
      }

      final caretakerName = await _storage.read(key: 'caretaker_name');
      final caretakerPhone = await _storage.read(key: 'caretaker_phone');
      if (caretakerName != null && caretakerPhone != null && caretakerName.isNotEmpty && caretakerPhone.isNotEmpty) {
        _patientData['caretaker'] = {
          'name': caretakerName,
          'phone': caretakerPhone,
          'relation': await _storage.read(key: 'caretaker_relation'),
        };
        print("✅ Loaded caregiver: $caretakerName, $caretakerPhone");
      }
    } catch (e) {
      print('Error loading patient data: $e');
    }
  }

  Future<bool> requestPermissions() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  void startContinuousListening({
    required Function(String) onResult,
    required Function(String) onError,
    Function(String)? onPartialResult,
  }) {
    _onFinalResultCallback = onResult;
    _onErrorCallback = onError;
    _onPartialResultCallback = onPartialResult;
    _isListeningContinuous = true;
    _startContinuousListening();
  }

  void _startContinuousListening() {
    if (_isListening || _isSpeaking || !_isListeningContinuous) return;
    _isListening = true;
    _speech.listen(
      onResult: (result) {
        String text = result.recognizedWords;
        if (_onPartialResultCallback != null && !result.finalResult) {
          _onPartialResultCallback!(text);
        }
        if (result.finalResult && text.isNotEmpty) {
          _lastUserInput = text;
          _interactionCount++;
          _lastInteraction = DateTime.now();
          _stopListening();
          if (_onFinalResultCallback != null) {
            _onFinalResultCallback!(text);
          }
        }
      },
      onSoundLevelChange: (_) {},
      cancelOnError: false,
      partialResults: true,
      listenMode: ListenMode.dictation,
      listenFor: const Duration(minutes: 5),
    );
  }

  void _stopListening() {
    if (_speech.isListening) {
      _speech.stop();
      _isListening = false;
    }
  }

  void stopListening() {
    _isListeningContinuous = false;
    _stopListening();
  }

  void pauseListening() { _stopListening(); }

  void resumeListening() {
    if (_isListeningContinuous && !_isSpeaking) _startContinuousListening();
  }

  Future<void> speak(String text, {CaregiverMood? mood}) async {
    try {
      pauseListening();
      _isSpeaking = true;
      _currentMood = mood ?? _currentMood;
      await _tts.speak(text);
    } catch (e) {
      print('TTS error: $e');
      _isSpeaking = false;
      resumeListening();
    }
  }

  // ============================================================
  // EMERGENCY ALERT – CORRECTED (fixes Position? error)
  // ============================================================
  Future<void> sendEmergencyAlert() async {
    print(">>> sendEmergencyAlert CALLED <<<");

    // Reload patient data
    await _loadPatientData();

    // 1. Check location services
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await speak("Location services are disabled. Please enable GPS in settings.");
      return;
    }

    // 2. Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        await speak("Location permission denied. Cannot send emergency alert.");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      await speak("Location permission permanently denied. Please enable in settings.");
      return;
    }

    // 3. Get current location with timeout and fallback
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      ).timeout(const Duration(seconds: 20));
    } catch (e) {
      print("Location error: $e");
      // Try last known location as fallback
      try {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition == null) throw Exception("No last known location");
        position = lastPosition;
        print("Using last known location: ${position.latitude}, ${position.longitude}");
      } catch (e2) {
        await speak("Unable to get your current location. Please check GPS settings.");
        return;
      }
    }

    // 4. Build emergency message
    String locationLink = "https://maps.google.com/?q=${position.latitude},${position.longitude}";
    String emergencyMessage = "🚨 EMERGENCY ALERT 🚨\n\nI need help.\nMy current location:\n$locationLink\n\nPlease reach out immediately.\n\n- Sent from MemoCare";

    // 5. Collect recipients
    List<String> recipients = [];
    if (_patientData.containsKey('caretaker') && _patientData['caretaker']['phone'] != null) {
      String phone = _patientData['caretaker']['phone'].toString();
      if (phone.isNotEmpty) recipients.add(phone);
    }
    if (_emergencyContacts.isNotEmpty && _emergencyContacts.first['phone'] != null) {
      String phone = _emergencyContacts.first['phone'].toString();
      if (phone.isNotEmpty) recipients.add(phone);
    }
    recipients = recipients.toSet().toList();
    print("Final recipients: $recipients");

    if (recipients.isEmpty) {
      await speak("No emergency contacts found. Please set up contacts first.");
      return;
    }

    // 6. Send SMS via compose screen
    bool smsSent = false;
    for (String phone in recipients) {
      String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.isEmpty) continue;
      final smsUri = Uri(scheme: 'sms', path: cleanPhone, queryParameters: {'body': emergencyMessage});
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        smsSent = true;
        print("SMS launched for $cleanPhone");
        break;
      } else {
        print("Could not launch SMS for $cleanPhone");
      }
    }

    // 7. WhatsApp fallback
    bool whatsappSent = false;
    if (!smsSent && recipients.isNotEmpty) {
      String cleanPhone = recipients.first.replaceAll(RegExp(r'[^0-9]'), '');
      String whatsappUrl = "https://api.whatsapp.com/send?phone=$cleanPhone&text=${Uri.encodeComponent(emergencyMessage)}";
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
        whatsappSent = true;
        print("WhatsApp launched");
      }
    }

    // 8. In-app notification
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Alerts',
      channelDescription: 'Notifications for emergency alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      0,
      '🚨 Emergency Alert Sent',
      'Your emergency contacts have been notified with your location.',
      notificationDetails,
    );

    // 9. Speak confirmation
    String confirmation = smsSent || whatsappSent
        ? "Emergency alert sent. Your contacts have been notified with your location."
        : "I'm sorry, I couldn't send the emergency alert. Please check your permissions.";
    await speak(confirmation, mood: CaregiverMood.concerned);

    onEmergencyAlertSent?.call();
  }

  // ============================================================
  // Rest of the methods (unchanged)
  // ============================================================
  Future<String> understandAndRespond(String userInput) async {
    return await processCommand(userInput);
  }

  Future<String> processCommand(String input) async {
    String cmd = input.toLowerCase().trim();
    if (_isGreeting(cmd)) return _getGreetingResponse();
    if (_isGratitude(cmd)) return _getGratitudeResponse();
    if (_isFarewell(cmd)) return _getFarewellResponse();
    if (_isMedicationRelated(cmd)) {
      onMedicationRequest();
      return _getMedicationResponse(cmd);
    }
    if (_isReminderRelated(cmd)) {
      onRemindersRequest();
      return _getReminderResponse(cmd);
    }
    if (_isEmergencyRelated(cmd)) {
      onEmergencyRequest();
      return _getEmergencyResponse();
    }
    if (_isMemoryDiaryRelated(cmd)) {
      onMemoryDiaryRequest();
      return _getMemoryDiaryResponse();
    }
    if (_isGamesRelated(cmd)) {
      onGamesRequest();
      return _getGamesResponse();
    }
    if (_isMoodRelated(cmd)) {
      onMoodCheckRequest();
      return _getMoodResponse(cmd);
    }
    String? contact = _extractContactName(cmd);
    if (contact != null) {
      onCallContactRequest(contact);
      return _getCallResponse(contact);
    }
    if (_isTimeRelated(cmd)) return _getTimeResponse();
    if (_isPersonalQuestion(cmd)) return _getPersonalResponse(cmd);
    if (_isHelpRequest(cmd)) return _getHelpResponse();
    return _getDefaultResponse(cmd);
  }

  bool _isGreeting(String s) => ['hello','hi','hey','good morning','good afternoon','good evening','howdy','namaste'].any((g) => s.contains(g));
  bool _isGratitude(String s) => ['thank','thanks','appreciate','grateful'].any((g) => s.contains(g));
  bool _isFarewell(String s) => ['bye','goodbye','see you','take care','later'].any((f) => s.contains(f));
  bool _isMedicationRelated(String s) => ['medicine','medication','pill','tablet','capsule','prescription','meds','dosage','refill'].any((k) => s.contains(k));
  bool _isReminderRelated(String s) => ['remind','reminder','task','todo','schedule','appointment','remember','forget','need to','have to'].any((k) => s.contains(k));
  bool _isEmergencyRelated(String s) => ['emergency','help','danger','sos','urgent','accident','fall','hurt','pain','bleeding','ambulance'].any((k) => s.contains(k));
  bool _isMemoryDiaryRelated(String s) => ['memory','diary','journal','remember','forgot','recall','past','yesterday','write down','note','thoughts'].any((k) => s.contains(k));
  bool _isGamesRelated(String s) => ['game','play','fun','activity','entertain','bored','puzzle','brain exercise'].any((k) => s.contains(k));
  bool _isMoodRelated(String s) => ['mood','feeling','feel','emotion','happy','sad','angry','tired','depressed','anxious','worried','stressed','calm','peaceful'].any((k) => s.contains(k));
  bool _isTimeRelated(String s) => ['time','date','day','today','tomorrow','yesterday','clock','what time','what day'].any((k) => s.contains(k));
  bool _isPersonalQuestion(String s) => ['your name','who are you','what are you','your age','can you','you help','you do'].any((k) => s.contains(k));
  bool _isHelpRequest(String s) => ['help','what can you do','how to use','instructions','guide','assist','support','capabilities','features'].any((k) => s.contains(k));

  String? _extractContactName(String s) {
    RegExp callRegex = RegExp(r'(?:call|phone|contact)\s+([a-zA-Z]+)');
    var match = callRegex.firstMatch(s);
    if (match != null) return match.group(1);
    for (var c in _emergencyContacts) {
      if (s.contains(c['name'].toLowerCase())) return c['name'];
    }
    if (_patientData.containsKey('caretaker') && s.contains(_patientData['caretaker']['name'].toLowerCase())) {
      return _patientData['caretaker']['name'];
    }
    return null;
  }

  String _getGreetingResponse() {
    int hour = DateTime.now().hour;
    String timeGreeting = hour < 12 ? "Good morning" : (hour < 17 ? "Good afternoon" : "Good evening");
    List<String> responses = [
      "$timeGreeting ${_patientData['name']}! How are you feeling today?",
      "$timeGreeting! It's wonderful to see you. How can I help you today?",
      "$timeGreeting ${_patientData['name']}! I'm here whenever you need me.",
    ];
    return responses[_interactionCount % responses.length];
  }

  String _getGratitudeResponse() => "You're very welcome! Is there anything else you need?";
  String _getFarewellResponse() => "Take care, ${_patientData['name']}! I'll be here when you need me.";

  String _getMedicationResponse(String input) {
    if (_medications.isEmpty) return "I don't see any medications in your list. Would you like me to help you add some?";
    if (input.contains('morning')) {
      var morning = _medications.where((m) => m['time'].toString().toLowerCase().contains('am')).toList();
      if (morning.isNotEmpty) return "Your morning medications are: ${morning.map((m) => "${m['name']} ${m['dosage']}").join(', ')}.";
    }
    if (input.contains('evening') || input.contains('night')) {
      var evening = _medications.where((m) => m['time'].toString().toLowerCase().contains('pm')).toList();
      if (evening.isNotEmpty) return "Your evening medications are: ${evening.map((m) => "${m['name']} ${m['dosage']}").join(', ')}.";
    }
    int pending = _medications.where((m) => !(m['taken'] ?? false)).length;
    if (pending > 0) return "You have $pending medications pending today. Would you like to see them all?";
    return "You've taken all your medications for today. Great job!";
  }

  String _getReminderResponse(String input) {
    if (_reminders.isEmpty) return "You don't have any reminders set. Would you like me to help you create one?";
    int pending = _reminders.where((r) => !(r['isCompleted'] ?? false)).length;
    if (pending > 0) return "You have $pending pending reminders. I can show them to you.";
    return "You've completed all your reminders for today! That's wonderful.";
  }

  String _getEmergencyResponse() => "I understand you need help. I'm showing you your emergency contacts. You can call them directly from there.";
  String _getMemoryDiaryResponse() => "Your memory diary is a great place to store your thoughts. Would you like to write a new entry or read past entries?";
  String _getGamesResponse() => "Playing games is great for your brain! We have memory match, sequence memory, word recall, and number matrix. Which one would you like?";

  String _getMoodResponse(String input) {
    if (input.contains('happy') || input.contains('good') || input.contains('great'))
      return "I'm so glad to hear that! What's making you feel happy today?";
    if (input.contains('sad') || input.contains('down') || input.contains('bad'))
      return "I'm sorry to hear that. Would you like to do something that might help, like playing a game or writing in your diary?";
    if (input.contains('tired'))
      return "Feeling tired is normal. Make sure you're getting enough rest.";
    if (input.contains('anxious') || input.contains('worried'))
      return "It's okay to feel anxious sometimes. Would you like to try a calming game?";
    return "It's important to acknowledge how you feel. Would you like to track your mood in your diary?";
  }

  String _getCallResponse(String name) {
    bool exists = _emergencyContacts.any((c) => c['name'].toLowerCase().contains(name.toLowerCase())) ||
        (_patientData.containsKey('caretaker') && _patientData['caretaker']['name'].toLowerCase().contains(name.toLowerCase()));
    return exists ? "Calling $name now." : "I don't see $name in your contacts. Would you like to add them?";
  }

  String _getTimeResponse() {
    DateTime now = DateTime.now();
    return "It's ${DateFormat('h:mm a').format(now)} on ${DateFormat('EEEE, MMMM d, yyyy').format(now)}.";
  }

  String _getPersonalResponse(String input) {
    if (input.contains('your name')) return "My name is $_caregiverName, your virtual caregiver. I'm here to help you with medications, reminders, and anything else you need!";
    if (input.contains('who are you')) return "I'm $_caregiverName, your personal caregiver companion.";
    return _getHelpResponse();
  }

  String _getHelpResponse() {
    return "I can help with:\n• Medications – ask about your pills\n• Reminders – check or add tasks\n• Emergency – call for help\n• Memory diary – write or read memories\n• Games – play brain games\n• Mood – talk about feelings\n• Contacts – call family\n• Time – ask what time it is\nJust tell me what you need!";
  }

  String _getDefaultResponse(String input) {
    if (input.length < 3) return "I'm sorry, I didn't catch that. Could you please repeat?";
    List<String> responses = [
      "I want to help, but I'm not sure I understood. Could you tell me more?",
      "I'm here to assist. Are you looking for help with medications, reminders, or something else?",
      "Let me try again. What would you like help with today?",
    ];
    return responses[_interactionCount % responses.length];
  }

  String getTimeBasedGreeting(String patientName) {
    int hour = DateTime.now().hour;
    if (hour < 12) return "Good morning $patientName! I hope you had a good night's rest. How can I help you?";
    if (hour < 17) return "Good afternoon $patientName! How is your day going?";
    return "Good evening $patientName! I hope you had a pleasant day. How can I help you?";
  }

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get caregiverName => _caregiverName;
  bool mounted = false;

  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
      resumeListening();
    }
  }

  void dispose() {
    mounted = false;
    _listeningTimer?.cancel();
    stopListening();
    stopSpeaking();
    _tts.stop();
  }
}