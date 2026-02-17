import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../constants/storage_keys.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String _patientName = '';
  List<Map<String, dynamic>> _todayActivities = [];
  Map<String, int> _weeklyStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivityData();
  }

  Future<void> _loadActivityData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final patientName = await _secureStorage.read(key: 'patient_name') ?? 'Patient';

      final activitiesData = await _secureStorage.read(key: 'patient_activities');
      if (activitiesData != null) {
        final List<dynamic> decoded = jsonDecode(activitiesData);
        _todayActivities = decoded.cast<Map<String, dynamic>>();
      } else {
        _setDefaultActivities();
      }

      _calculateWeeklyStats();

      setState(() {
        _patientName = patientName;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading activity data: $e');
      _setDefaultActivities();
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setDefaultActivities() {
    _todayActivities = [
      {
        'id': '1',
        'title': 'Morning Walk',
        'duration': '20 minutes',
        'time': '7:30 AM',
        'type': 'Physical',
        'status': 'completed',
        'icon': 'walk',
        'color': 'green'
      },
      {
        'id': '2',
        'title': 'Memory Game',
        'duration': '15 minutes',
        'time': '10:00 AM',
        'type': 'Cognitive',
        'status': 'completed',
        'icon': 'brain',
        'color': 'purple'
      },
      {
        'id': '3',
        'title': 'Reading Time',
        'duration': '30 minutes',
        'time': '2:00 PM',
        'type': 'Mental',
        'status': 'pending',
        'icon': 'book',
        'color': 'blue'
      },
      {
        'id': '4',
        'title': 'Social Call',
        'duration': '15 minutes',
        'time': '4:00 PM',
        'type': 'Social',
        'status': 'pending',
        'icon': 'call',
        'color': 'orange'
      },
      {
        'id': '5',
        'title': 'Evening Exercise',
        'duration': '25 minutes',
        'time': '6:00 PM',
        'type': 'Physical',
        'status': 'pending',
        'icon': 'exercise',
        'color': 'green'
      },
    ];
    _saveActivities();
  }

  void _calculateWeeklyStats() {
    _weeklyStats = {
      'Physical': 5,
      'Cognitive': 7,
      'Social': 3,
      'Mental': 4,
    };
  }

  Future<void> _saveActivities() async {
    try {
      final encoded = jsonEncode(_todayActivities);
      await _secureStorage.write(key: 'patient_activities', value: encoded);
    } catch (e) {
      print('Error saving activities: $e');
    }
  }

  void _markActivityComplete(String id) {
    setState(() {
      final index = _todayActivities.indexWhere((activity) => activity['id'] == id);
      if (index != -1) {
        _todayActivities[index]['status'] =
        _todayActivities[index]['status'] == 'completed' ? 'pending' : 'completed';
      }
    });
    _saveActivities();
  }

  Color _getActivityColor(String colorName) {
    switch (colorName) {
      case 'green': return Colors.green;
      case 'purple': return Colors.purple;
      case 'blue': return Colors.blue;
      case 'orange': return Colors.orange;
      case 'red': return Colors.red;
      default: return Colors.blue;
    }
  }

  IconData _getActivityIcon(String iconName) {
    switch (iconName) {
      case 'walk': return Icons.directions_walk;
      case 'brain': return Icons.psychology;
      case 'book': return Icons.menu_book;
      case 'call': return Icons.phone;
      case 'exercise': return Icons.fitness_center;
      case 'music': return Icons.music_note;
      case 'paint': return Icons.brush;
      default: return Icons.local_activity;
    }
  }

  int get _completedCount => _todayActivities.where((a) => a['status'] == 'completed').length;
  double get _completionPercentage => _todayActivities.isEmpty ? 0 : _completedCount / _todayActivities.length;

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text('Logout'),
            ],
          ),
          content: const Text('Are you sure you want to logout from MemoCare?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _secureStorage.write(key: 'user_logged_in', value: 'false');
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/role-selection', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Daily Activities'),
          backgroundColor: Colors.teal[600],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.teal),
              SizedBox(height: 16),
              Text('Loading activities...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Daily Activities'),
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Today's Progress
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal[400]!, Colors.teal[600]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.directions_run,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Today's Activities",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Keep $_patientName active and engaged',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: Stack(
                            children: [
                              CircularProgressIndicator(
                                value: _completionPercentage,
                                strokeWidth: 4,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                              Center(
                                child: Text(
                                  '${(_completionPercentage * 100).round()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_completedCount of ${_todayActivities.length} activities completed',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Great progress today!',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Weekly Stats Cards
              Row(
                children: [
                  Expanded(child: _buildStatCard('Physical', _weeklyStats['Physical']!, Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Cognitive', _weeklyStats['Cognitive']!, Colors.purple)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Social', _weeklyStats['Social']!, Colors.orange)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Mental', _weeklyStats['Mental']!, Colors.blue)),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                "Today's Schedule",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              ..._todayActivities.map((activity) => _buildActivityCard(activity)).toList(),

              const SizedBox(height: 20),

              // Quick Activity Suggestions
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.lightbulb, color: Colors.amber[700], size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Activity Suggestions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSuggestionRow('🧩', 'Puzzle Games', 'Improve memory and problem-solving'),
                    _buildSuggestionRow('🎵', 'Music Therapy', 'Listen to favorite songs'),
                    _buildSuggestionRow('🌱', 'Gardening', 'Connect with nature'),
                    _buildSuggestionRow('🎨', 'Art & Crafts', 'Express creativity'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Health Tips
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.health_and_safety, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Daily Health Tips',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildHealthTip('💧', 'Stay hydrated - drink 8 glasses of water daily'),
                    _buildHealthTip('🚶', 'Take regular walks to maintain mobility'),
                    _buildHealthTip('🧠', 'Practice memory exercises daily'),
                    _buildHealthTip('😴', 'Maintain a regular sleep schedule'),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatIcon(title),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const Text(
            'This Week',
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatIcon(String type) {
    switch (type) {
      case 'Physical': return Icons.fitness_center;
      case 'Cognitive': return Icons.psychology;
      case 'Social': return Icons.people;
      case 'Mental': return Icons.menu_book;
      default: return Icons.local_activity;
    }
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final color = _getActivityColor(activity['color']);
    final isCompleted = activity['status'] == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? color : color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isCompleted ? Icons.check : _getActivityIcon(activity['icon']),
                color: isCompleted ? Colors.white : color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['title'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${activity['time']} • ${activity['duration']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activity['type'],
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _markActivityComplete(activity['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? Colors.grey : color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size(60, 28),
              ),
              child: Text(
                isCompleted ? 'Done' : 'Mark Done',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionRow(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTip(String emoji, String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[800],
              ),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}
