import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/real_face_auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/activity_center_screen.dart';
import 'screens/medication_screen.dart';
import 'screens/settings_screen.dart';
import 'constants/storage_keys.dart';
import 'services/notification_service.dart';
import 'services/reminder_scheduler.dart';
import 'services/voice_assistant_service.dart';
import 'services/virtual_caregiver_service.dart';
import 'services/wake_word_service.dart';
import 'widgets/voice_assistant_widget.dart';
import 'widgets/virtual_caregiver_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.init();

  final scheduler = ReminderScheduler();
  scheduler.startScheduler();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MemoCare',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[600]!),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(color: Colors.black87),
          titleMedium: TextStyle(color: Colors.black87),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue[700],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        cardColor: Colors.grey[850],
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[700]!),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/real-face-auth': (context) => const RealFaceAuthScreen(),
        '/dashboard': (context) => const MainApp(),
        '/emergency': (context) => const EmergencyScreen(),
        '/activity-center': (context) => ActivityCenterScreen(onVoiceAssistantPressed: () {}),
        '/medications': (context) => const MedicationScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late AnimationController _loadingAnimationController;
  String _statusMessage = 'Welcome to MemoCare...';
  final ReminderScheduler _scheduler = ReminderScheduler();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthAndNavigate();
    _initializeServices();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  Future<void> _initializeServices() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _statusMessage = 'Loading notifications...');
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _statusMessage = 'Checking reminders...');
    await _scheduler.rescheduleAllReminders();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _statusMessage = 'Almost ready...');
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    const storage = FlutterSecureStorage();
    final isLoggedIn = await storage.read(key: StorageKeys.userLoggedIn) == 'true';
    final faceRegistered = await storage.read(key: StorageKeys.faceRegistered) == 'true';
    if (mounted) {
      if (isLoggedIn && faceRegistered) {
        Navigator.of(context).pushReplacementNamed('/real-face-auth');
      } else {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[400]!, Colors.blue[600]!, Colors.blue[800]!],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(35),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.health_and_safety, size: 80, color: Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'MemoCare',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your Personal Memory Companion',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w300),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 60),
                      RotationTransition(
                        turns: _loadingAnimationController,
                        child: const SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Version 2.0.0',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);
  final ReminderScheduler _scheduler = ReminderScheduler();
  bool _showBadge = false;

  late VoiceAssistantService _voiceService;
  bool _showVoiceAssistant = false;

  late VirtualCaregiverService _caregiverService;
  late WakeWordService _wakeWordService;
  String _patientName = '';
  bool _isCaregiverActive = false;
  Timer? _healthCheckTimer;

  late final List<Widget> _screens = [
    const DashboardScreen(),
    ActivityCenterScreen(onVoiceAssistantPressed: _showVoiceAssistantDialog),
    RemindersScreen(),
    MedicationScreen(onVoiceAssistantPressed: _showVoiceAssistantDialog),
    const EmergencyScreen(),
    const ActivityScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPatientName();
    _initVoiceAssistant();
    _initVirtualCaregiver();
    _initWakeWordService();
    _requestEmergencyPermissions();
    _checkPendingReminders();
    _scheduler.startScheduler();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_wakeWordService.isActive) {
        _wakeWordService.startListening(_onWakeWordTriggered);
      }
    } else if (state == AppLifecycleState.paused) {
      _wakeWordService.stopListening();
    }
  }

  Future<void> _loadPatientName() async {
    const storage = FlutterSecureStorage();
    final name = await storage.read(key: StorageKeys.patientName);
    setState(() => _patientName = name ?? 'Friend');
  }

  Future<void> _requestEmergencyPermissions() async {
    await Permission.location.request();
    await Permission.locationAlways.request();
    await Permission.sms.request();
  }

  Future<void> _initVoiceAssistant() async {
    _voiceService = VoiceAssistantService(
      onRemindersRequest: () => _navigateToScreen(2),
      onEmergencyRequest: () => _navigateToScreen(4),
      onMedicationRequest: () => _navigateToScreen(3),
      onActivityRequest: () => _navigateToScreen(5),
      onMemoryGameRequest: () => _navigateToScreen(1),
      onDashboardRequest: () => _navigateToScreen(0),
      onSettingsRequest: _showSettingsFromVoice,
      onCallContactRequest: _handleCallContact,
      onCustomCommand: _handleCustomCommand,
    );
    await _voiceService.initialize();
    await _voiceService.requestPermissions();
  }

  Future<void> _initVirtualCaregiver() async {
    _caregiverService = VirtualCaregiverService(
      onRemindersRequest: () => _navigateToScreen(2),
      onEmergencyRequest: () => _navigateToScreen(4),
      onMedicationRequest: () => _navigateToScreen(3),
      onMemoryDiaryRequest: () => _navigateToScreen(5),
      onGamesRequest: () => _navigateToScreen(1),
      onDashboardRequest: () => _navigateToScreen(0),
      onCallContactRequest: _handleCallContact,
      onSendMessageRequest: _handleSendMessage,
      onMoodCheckRequest: _showMoodCheck,
      onEmergencyAlertSent: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Emergency alert sent"), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
          );
        }
      },
    );
    await _caregiverService.initialize();
    await _caregiverService.requestPermissions();
  }

  Future<void> _initWakeWordService() async {
    _wakeWordService = WakeWordService();
    bool available = await _wakeWordService.initialize();
    if (!available) return;
    bool hasPermission = await _wakeWordService.requestPermissions();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone permission needed")),
      );
      return;
    }
    _wakeWordService.startListening(_onWakeWordTriggered);
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_wakeWordService.isActive && !_isCaregiverActive && mounted) {
        _wakeWordService.startListening(_onWakeWordTriggered);
      }
    });
  }

  void _onWakeWordTriggered(String command) {
    print(">>> WAKE WORD DETECTED: $command");
    if (command.contains("emergency") ||
        command.contains("help me") ||
        command.contains("danger") ||
        command.contains("sos") ||
        command.contains("need help")) {
      print(">>> CALLING sendEmergencyAlert");
      _caregiverService.sendEmergencyAlert();
    }
    else if (!_isCaregiverActive && mounted)
    {
      _showVirtualCaregiverManually(command);
    }
  }

  void _navigateToScreen(int index) {
    setState(() => _selectedIndex = index);
    _pageController.jumpToPage(index);
  }

  void _showSettingsFromVoice() {
    _voiceService.speak("Opening settings from menu");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open settings from menu drawer')),
    );
  }

  void _handleCallContact(String name) {
    _voiceService.speak("Calling $name");
    _navigateToScreen(4);
  }

  void _handleSendMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Message sent: $message'), backgroundColor: Colors.green),
    );
  }

  void _handleCustomCommand(String command) {
    if (command.contains('help')) {
      _voiceService.speak("You can say: open reminders, call emergency, show medications, open memory diary, play games, go to dashboard, or open settings");
    } else if (command.contains('game') || command.contains('play')) {
      _navigateToScreen(1);
    } else if (command.contains('diary') || command.contains('memory diary')) {
      _navigateToScreen(5);
    } else {
      _voiceService.speak("I didn't understand. Say 'help' for commands.");
    }
  }

  void _showMoodCheck() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("How are you feeling?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMoodOption("Happy", Icons.emoji_emotions, Colors.amber),
            _buildMoodOption("Calm", Icons.spa, Colors.blue),
            _buildMoodOption("Sad", Icons.sentiment_dissatisfied, Colors.grey),
            _buildMoodOption("Anxious", Icons.mood_bad, Colors.orange),
            _buildMoodOption("Tired", Icons.bedtime, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodOption(String mood, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(mood),
      onTap: () {
        Navigator.pop(context);
        _caregiverService.speak("I hope you feel better soon. Would you like to do something to improve your mood?");
        if (mood == "Sad" || mood == "Anxious") _showSoothingActivitySuggestion();
      },
    );
  }

  void _showSoothingActivitySuggestion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Feeling better?"),
        content: const Text("Would you like to play a relaxing memory game or write in your diary?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Maybe later")),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _navigateToScreen(1); },
            child: const Text("Play a game"),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPendingReminders() async {
    const storage = FlutterSecureStorage();
    final remindersData = await storage.read(key: StorageKeys.patientReminders);
    if (remindersData != null) setState(() => _showBadge = true);
  }

  Widget _buildBadge() => _showBadge
      ? Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))
      : const SizedBox.shrink();

  List<BottomNavigationBarItem> get _navItems => [
    const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    const BottomNavigationBarItem(icon: Icon(Icons.extension), label: 'Games'),
    BottomNavigationBarItem(
      icon: Stack(
        children: [const Icon(Icons.notifications), Positioned(right: -4, top: -4, child: _buildBadge())],
      ),
      label: 'Reminders',
    ),
    const BottomNavigationBarItem(icon: Icon(Icons.medication), label: 'Medication'),
    const BottomNavigationBarItem(icon: Icon(Icons.emergency), label: 'Emergency'),
    const BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Memory'),
  ];

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; if (index == 2) _showBadge = false; });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,  // ✅ curve is now provided
    );
  }

  void _showVoiceAssistantDialog() {
    setState(() => _showVoiceAssistant = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VoiceAssistantWidget(
        service: _voiceService,
        onClose: () {
          Navigator.pop(context);
          setState(() => _showVoiceAssistant = false);
        },
      ),
    );
  }

  void _showVirtualCaregiverManually([String? initialCommand]) {
    if (_isCaregiverActive) return;
    setState(() => _isCaregiverActive = true);
    _wakeWordService.stopListening();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          setState(() => _isCaregiverActive = false);
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_wakeWordService.isActive) _wakeWordService.startListening(_onWakeWordTriggered);
          });
          return true;
        },
        child: VirtualCaregiverWidget(
          service: _caregiverService,
          onClose: () {
            setState(() => _isCaregiverActive = false);
            Navigator.pop(context);
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && !_wakeWordService.isActive) _wakeWordService.startListening(_onWakeWordTriggered);
            });
          },
          patientName: _patientName,
          autoGreet: true,
          initialCommand: initialCommand,  // ✅ now the widget accepts this
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 2) _showBadge = false;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: _navItems,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "caregiver",
            backgroundColor: _isCaregiverActive ? Colors.green : Colors.purple,
            onPressed: () => _showVirtualCaregiverManually(),
            child: Icon(_isCaregiverActive ? Icons.chat : Icons.support_agent),
            mini: true,
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "assistant",
            backgroundColor: _showVoiceAssistant ? Colors.green : Colors.blue[600],
            onPressed: _showVoiceAssistantDialog,
            child: Icon(_showVoiceAssistant ? Icons.voice_chat : Icons.mic),
            mini: true,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _scheduler.stopScheduler();
    _wakeWordService.dispose();
    _voiceService.dispose();
    _caregiverService.dispose();
    super.dispose();
  }
}