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
import 'screens/memory_game_screen.dart';
import 'screens/medication_screen.dart';
import 'screens/settings_screen.dart';
import 'constants/storage_keys.dart';
import 'services/notification_service.dart';
import 'services/reminder_scheduler.dart';

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
        '/memory-game': (context) => const MemoryGameScreen(),
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

  // Updated screens list - removed Settings
  final List<Widget> _screens = [
    const DashboardScreen(),
    const MemoryGameScreen(),
    RemindersScreen(),
    const MedicationScreen(),
    const EmergencyScreen(),
    const ActivityScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkPendingReminders();
    _scheduler.startScheduler();
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

  // Updated navigation items - removed Settings
  List<BottomNavigationBarItem> get _navItems {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.psychology),
        activeIcon: Icon(Icons.psychology),
        label: 'Memory',
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
        icon: Icon(Icons.directions_run),
        activeIcon: Icon(Icons.directions_run),
        label: 'Activity',
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
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
        backgroundColor: Colors.blue[600],
        onPressed: _showVoiceCommandDialog,
        child: const Icon(Icons.mic, color: Colors.white),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showVoiceCommandDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.mic, color: Colors.blue),
            SizedBox(width: 8),
            Text('Voice Command'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_voice,
                size: 40,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Listening for commands...',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try saying: "Show reminders" or "Call emergency"',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    // Simulate voice recognition after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context); // Close voice dialog
        _showVoiceCommandResult();
      }
    });
  }

  void _showVoiceCommandResult() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Command Recognized'),
        content: const Text('Opening Reminders...'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _onItemTapped(2); // Navigate to reminders
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scheduler.stopScheduler();
    super.dispose();
  }
}