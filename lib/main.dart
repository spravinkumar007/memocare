import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
import 'widgets/voice_assistant_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.init();

  // Start reminder scheduler
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

        // Set scaffold background color to white
        scaffoldBackgroundColor: Colors.white,

        // Set card color to white
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

        // Text themes with proper colors
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
        '/activity-center': (context) => ActivityCenterScreen(
          onVoiceAssistantPressed: () {}, // This will be overridden in MainApp
        ),
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

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  Future<void> _initializeServices() async {
    // Update status messages during initialization
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _statusMessage = 'Loading notifications...');

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _statusMessage = 'Checking reminders...');

    // Reschedule any pending reminders
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
            colors: [
              Colors.blue[400]!,
              Colors.blue[600]!,
              Colors.blue[800]!,
            ],
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
                          child: const Icon(
                            Icons.health_and_safety,
                            size: 80,
                            color: Colors.blue,
                          ),
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
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 60),

                      // Animated loading indicator
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

                      // Dynamic status message
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Version info
                      Text(
                        'Version 2.0.0',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
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

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);
  final ReminderScheduler _scheduler = ReminderScheduler();
  bool _showBadge = false;

  // Voice Assistant
  late VoiceAssistantService _voiceService;
  bool _showVoiceAssistant = false;

  // Screens list
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initVoiceAssistant();
    _checkPendingReminders();
    _scheduler.startScheduler();

    // Initialize screens with callbacks - USING CONSTRUCTOR APPROACH
    _screens = [
      const DashboardScreen(),
      ActivityCenterScreen(
        onVoiceAssistantPressed: _showVoiceAssistantDialog,
      ),
      RemindersScreen(),
      MedicationScreen(
        onVoiceAssistantPressed: _showVoiceAssistantDialog,
      ),
      const EmergencyScreen(),
      const ActivityScreen(), // This is the Memory Diary screen
    ];
  }

  Future<void> _initVoiceAssistant() async {
    _voiceService = VoiceAssistantService(
      onRemindersRequest: () {
        _navigateToScreen(2); // Reminders index
      },
      onEmergencyRequest: () {
        _navigateToScreen(4); // Emergency index
      },
      onMedicationRequest: () {
        _navigateToScreen(3); // Medication index
      },
      onActivityRequest: () {
        _navigateToScreen(5); // Memory Diary index (was Activity)
      },
      onMemoryGameRequest: () {
        _navigateToScreen(1); // Games index
      },
      onDashboardRequest: () {
        _navigateToScreen(0); // Dashboard index
      },
      onSettingsRequest: () {
        _showSettingsFromVoice();
      },
      onCallContactRequest: (name) {
        _handleCallContact(name);
      },
      onCustomCommand: (command) {
        _handleCustomCommand(command);
      },
    );

    await _voiceService.initialize();
    await _voiceService.requestPermissions();
  }

  void _navigateToScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  void _showSettingsFromVoice() {
    _voiceService.speak("Opening settings from menu");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Open settings from the menu drawer'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleCallContact(String name) {
    _voiceService.speak("Calling $name");
    // Navigate to emergency screen where contacts are shown
    _navigateToScreen(4); // Go to emergency
  }

  void _handleCustomCommand(String command) {
    if (command.contains('help')) {
      _voiceService.speak(
          "You can say: open reminders, call emergency, show medications, "
              "open memory diary, play games, go to dashboard, or open settings"
      );
    } else if (command.contains('game') || command.contains('play')) {
      _navigateToScreen(1); // Navigate to games
    } else if (command.contains('diary') || command.contains('memory diary')) {
      _navigateToScreen(5); // Navigate to memory diary
    } else {
      _voiceService.speak("I didn't understand. Say 'help' for commands.");
    }
  }

  Future<void> _checkPendingReminders() async {
    // Check if there are any pending reminders
    const storage = FlutterSecureStorage();
    final remindersData = await storage.read(key: StorageKeys.patientReminders);
    if (remindersData != null) {
      // Parse and check for incomplete reminders
      // This is simplified - you'd want to actually parse and check
      setState(() {
        _showBadge = true;
      });
    }
  }

  Widget _buildBadge() {
    if (!_showBadge) return const SizedBox.shrink();

    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }

  // Updated navigation items with "Memory Diary" as the last option
  List<BottomNavigationBarItem> get _navItems {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.extension),
        activeIcon: Icon(Icons.extension),
        label: 'Games',
      ),
      BottomNavigationBarItem(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications),
            Positioned(
              right: -4,
              top: -4,
              child: _buildBadge(),
            ),
          ],
        ),
        activeIcon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications),
            Positioned(
              right: -2,
              top: -2,
              child: _buildBadge(),
            ),
          ],
        ),
        label: 'Reminders',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.medication),
        activeIcon: Icon(Icons.medication),
        label: 'Medication',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.emergency),
        activeIcon: Icon(Icons.emergency),
        label: 'Emergency',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.menu_book), // Changed from Icons.directions_run
        activeIcon: Icon(Icons.menu_book),
        label: 'Memory', // Changed from 'Activity'
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Hide badge when reminders screen is opened
      if (index == 2) {
        _showBadge = false;
      }
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showVoiceAssistantDialog() {
    setState(() {
      _showVoiceAssistant = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VoiceAssistantWidget(
        service: _voiceService,
        onClose: () {
          Navigator.pop(context);
          setState(() {
            _showVoiceAssistant = false;
          });
        },
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
            // Hide badge when reminders screen is opened
            if (index == 2) {
              _showBadge = false;
            }
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.blue[600],
          unselectedItemColor: Colors.grey[600],
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          backgroundColor: Colors.white,
          items: _navItems,
          iconSize: 22,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _showVoiceAssistant ? Colors.green : Colors.blue[600],
        onPressed: _showVoiceAssistantDialog,
        child: Icon(
          _showVoiceAssistant ? Icons.voice_chat : Icons.mic,
          color: Colors.white,
        ),
        mini: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scheduler.stopScheduler();
    _voiceService.dispose();
    super.dispose();
  }
}