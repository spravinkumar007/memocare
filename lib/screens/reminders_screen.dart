import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../constants/storage_keys.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;
  String _patientName = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadPatientInfo();
    await _loadReminders();
  }

  Future<void> _loadPatientInfo() async {
    try {
      final patientName = await _secureStorage.read(key: StorageKeys.patientName);
      if (patientName != null && patientName.isNotEmpty) {
        setState(() {
          _patientName = patientName;
        });
      } else {
        setState(() {
          _patientName = 'Patient';
        });
      }
    } catch (e) {
      print('Error loading patient info: $e');
      setState(() {
        _patientName = 'Patient';
      });
    }
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final remindersData = await _secureStorage.read(key: StorageKeys.patientReminders);

      if (remindersData != null && remindersData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(remindersData);
        if (decoded.isNotEmpty) {
          setState(() {
            _reminders = decoded.cast<Map<String, dynamic>>();
          });
        } else {
          _setDefaultReminders();
        }
      } else {
        _setDefaultReminders();
      }
    } catch (e) {
      print('Error loading reminders: $e');
      _setDefaultReminders();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setDefaultReminders() {
    _reminders = [
      {
        'id': '1',
        'title': 'Take Morning Medication',
        'description': 'Donepezil 10mg with breakfast',
        'time': '08:00 AM',
        'category': 'Medication',
        'color': 'green',
        'isCompleted': true,
        'icon': 'medication',
      },
      {
        'id': '2',
        'title': 'Doctor Appointment',
        'description': 'Neurologist checkup at City Hospital',
        'time': '02:30 PM',
        'category': 'Health',
        'color': 'red',
        'isCompleted': false,
        'icon': 'doctor',
      },
      {
        'id': '3',
        'title': 'Call Family',
        'description': 'Weekly call with daughter Emma',
        'time': '05:00 PM',
        'category': 'Social',
        'color': 'blue',
        'isCompleted': false,
        'icon': 'family',
      },
      {
        'id': '4',
        'title': 'Evening Walk',
        'description': '20-minute walk in the park',
        'time': '06:30 PM',
        'category': 'Exercise',
        'color': 'purple',
        'isCompleted': false,
        'icon': 'exercise',
      },
      {
        'id': '5',
        'title': 'Take Evening Medication',
        'description': 'Omega-3 and Vitamin D',
        'time': '08:00 PM',
        'category': 'Medication',
        'color': 'green',
        'isCompleted': false,
        'icon': 'medication',
      },
    ];
    _saveReminders();
  }

  Future<void> _saveReminders() async {
    try {
      final encoded = jsonEncode(_reminders);
      await _secureStorage.write(key: StorageKeys.patientReminders, value: encoded);
    } catch (e) {
      print('Error saving reminders: $e');
    }
  }

  void _toggleReminderCompletion(String id) {
    setState(() {
      final index = _reminders.indexWhere((reminder) => reminder['id'] == id);
      if (index != -1) {
        _reminders[index]['isCompleted'] = !(_reminders[index]['isCompleted'] ?? false);
      }
    });
    _saveReminders();
  }

  int get _completedCount {
    if (_reminders.isEmpty) return 0;
    return _reminders.where((r) => r['isCompleted'] == true).length;
  }

  double get _completionPercentage {
    if (_reminders.isEmpty) return 0;
    return _completedCount / _reminders.length;
  }

  Color _getCategoryColor(String? colorName) {
    switch (colorName ?? '') {
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName ?? '') {
      case 'medication':
        return Icons.medication;
      case 'doctor':
        return Icons.local_hospital;
      case 'family':
        return Icons.family_restroom;
      case 'exercise':
        return Icons.directions_walk;
      case 'food':
        return Icons.restaurant;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _showAddReminderDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => const AddReminderDialog(),
    );

    if (result != null) {
      setState(() {
        _reminders.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': result['title'] ?? '',
          'description': result['description'] ?? '',
          'time': result['time'] ?? '12:00 PM',
          'category': result['category'] ?? 'General',
          'color': result['color'] ?? 'blue',
          'isCompleted': false,
          'icon': result['icon'] ?? 'notifications',
        });
      });
      _saveReminders();
    }
  }

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
      await _secureStorage.write(key: StorageKeys.userLoggedIn, value: 'false');
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reminders'),
          backgroundColor: Colors.orange[600],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 16),
              Text('Loading reminders...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Daily Reminders'),
        backgroundColor: Colors.orange[600],
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header with Icon and Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.access_time,
                  size: 32,
                  color: Colors.orange[700],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Reminders',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Stay on track with your daily tasks',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Progress Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[400]!, Colors.orange[600]!],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Progress Circle
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: _completionPercentage,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      Center(
                        child: Text(
                          '${(_completionPercentage * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Progress",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_completedCount of ${_reminders.length} reminders completed',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_completionPercentage * 100).round()}% Complete',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Add New Reminder Button
          Container(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _showAddReminderDialog,
              icon: const Icon(Icons.add, size: 24),
              label: const Text(
                'Add New Reminder',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Today's Reminders Title
          const Text(
            "Today's Reminders",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          // Reminders List
          if (_reminders.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No reminders yet. Tap "Add New Reminder" to create one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            ..._reminders.map((reminder) => _buildReminderCard(reminder)).toList(),

          const SizedBox(height: 100), // Space for bottom navigation
        ],
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    // Safe extraction with null checks
    final String title = reminder['title'] ?? 'Reminder';
    final String description = reminder['description'] ?? '';
    final String time = reminder['time'] ?? '12:00 PM';
    final String category = reminder['category'] ?? 'General';
    final String colorName = reminder['color'] ?? 'blue';
    final String iconName = reminder['icon'] ?? 'notifications';
    final bool isCompleted = reminder['isCompleted'] ?? false;
    final String id = reminder['id'] ?? '';

    final color = _getCategoryColor(colorName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? color : color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted ? color : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCompleted ? Icons.check : _getCategoryIcon(iconName),
                color: isCompleted ? Colors.white : color,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Time and Done Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _toggleReminderCompletion(id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? Colors.grey : color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(60, 32),
                  ),
                  child: Text(
                    isCompleted ? 'Done' : 'Done',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddReminderDialog extends StatefulWidget {
  const AddReminderDialog({super.key});

  @override
  State<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedCategory = 'Medication';
  String _selectedColor = 'green';
  String _selectedIcon = 'medication';

  final Map<String, Map<String, String>> _categories = {
    'Medication': {'color': 'green', 'icon': 'medication'},
    'Health': {'color': 'red', 'icon': 'doctor'},
    'Social': {'color': 'blue', 'icon': 'family'},
    'Exercise': {'color': 'purple', 'icon': 'exercise'},
    'Food': {'color': 'orange', 'icon': 'food'},
  };

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Reminder'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Reminder Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectTime,
                    child: Text('Time: ${_formatTime(_selectedTime)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.keys.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                  _selectedColor = _categories[value]!['color']!;
                  _selectedIcon = _categories[value]!['icon']!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              Navigator.of(context).pop({
                'title': _titleController.text,
                'description': _descriptionController.text,
                'time': _formatTime(_selectedTime),
                'category': _selectedCategory,
                'color': _selectedColor,
                'icon': _selectedIcon,
              });
            }
          },
          child: const Text('Add Reminder'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}