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
  List<Map<String, dynamic>> _todayEntries = [];
  Map<String, int> _weeklyStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiaryData();
  }

  Future<void> _loadDiaryData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final patientName = await _secureStorage.read(key: 'patient_name') ?? 'Patient';

      final diaryData = await _secureStorage.read(key: 'memory_diary_entries');
      if (diaryData != null) {
        final List<dynamic> decoded = jsonDecode(diaryData);
        _todayEntries = decoded.cast<Map<String, dynamic>>();
      } else {
        _setDefaultEntries();
      }

      _calculateWeeklyStats();

      setState(() {
        _patientName = patientName;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading diary data: $e');
      _setDefaultEntries();
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setDefaultEntries() {
    _todayEntries = [
      {
        'id': '1',
        'title': 'Morning Reflections',
        'description': 'Woke up feeling good. Remembered to take morning medication.',
        'time': '7:30 AM',
        'type': 'Personal',
        'mood': 'happy',
        'color': 'green'
      },
      {
        'id': '2',
        'title': 'Memory Practice',
        'description': 'Played memory matching game. Scored 80 points!',
        'time': '10:00 AM',
        'type': 'Cognitive',
        'mood': 'proud',
        'color': 'purple'
      },
      {
        'id': '3',
        'title': 'Phone Call with Daughter',
        'description': 'Spoke with Emma for 15 minutes. She\'s coming to visit on Sunday.',
        'time': '2:00 PM',
        'type': 'Social',
        'mood': 'happy',
        'color': 'blue'
      },
      {
        'id': '4',
        'title': 'Afternoon Walk',
        'description': 'Walked around the garden. Saw beautiful flowers.',
        'time': '4:00 PM',
        'type': 'Physical',
        'mood': 'calm',
        'color': 'orange'
      },
      {
        'id': '5',
        'title': 'Evening Relaxation',
        'description': 'Listened to favorite music. Felt peaceful.',
        'time': '6:00 PM',
        'type': 'Mental',
        'mood': 'relaxed',
        'color': 'teal'
      },
    ];
    _saveEntries();
  }

  void _calculateWeeklyStats() {
    _weeklyStats = {
      'Personal': 7,
      'Cognitive': 5,
      'Social': 3,
      'Physical': 4,
      'Mental': 6,
    };
  }

  Future<void> _saveEntries() async {
    try {
      final encoded = jsonEncode(_todayEntries);
      await _secureStorage.write(key: 'memory_diary_entries', value: encoded);
    } catch (e) {
      print('Error saving diary entries: $e');
    }
  }

  void _addNewEntry() {
    _showAddEntryDialog();
  }

  void _editEntry(String id) {
    final entry = _todayEntries.firstWhere((e) => e['id'] == id);
    _showAddEntryDialog(entry: entry);
  }

  void _deleteEntry(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this memory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _todayEntries.removeWhere((entry) => entry['id'] == id);
      });
      _saveEntries();
    }
  }

  void _showAddEntryDialog({Map<String, dynamic>? entry}) {
    final bool isEditing = entry != null;
    final _titleController = TextEditingController(text: entry?['title'] ?? '');
    final _descriptionController = TextEditingController(text: entry?['description'] ?? '');
    String _selectedMood = entry?['mood'] ?? 'happy';
    String _selectedType = entry?['type'] ?? 'Personal';

    final List<String> _moodOptions = ['happy', 'calm', 'proud', 'relaxed', 'thoughtful', 'peaceful'];
    final List<String> _typeOptions = ['Personal', 'Cognitive', 'Social', 'Physical', 'Mental', 'Family'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(isEditing ? Icons.edit : Icons.add, color: Colors.teal),
            const SizedBox(width: 8),
            Text(isEditing ? 'Edit Memory' : 'New Memory'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedMood,
                decoration: const InputDecoration(
                  labelText: 'Mood',
                  border: OutlineInputBorder(),
                ),
                items: _moodOptions.map((mood) {
                  return DropdownMenuItem(
                    value: mood,
                    child: Row(
                      children: [
                        Icon(_getMoodIcon(mood), size: 16, color: _getMoodColor(mood)),
                        const SizedBox(width: 8),
                        Text(mood[0].toUpperCase() + mood.substring(1)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => _selectedMood = value!,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _typeOptions.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) => _selectedType = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty) {
                if (isEditing) {
                  setState(() {
                    entry!['title'] = _titleController.text;
                    entry['description'] = _descriptionController.text;
                    entry['mood'] = _selectedMood;
                    entry['type'] = _selectedType;
                  });
                } else {
                  setState(() {
                    _todayEntries.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': _titleController.text,
                      'description': _descriptionController.text,
                      'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}',
                      'type': _selectedType,
                      'mood': _selectedMood,
                      'color': _getMoodColorName(_selectedMood),
                    });
                  });
                }
                _saveEntries();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  int get _completedCount => _todayEntries.length;
  int get _totalEntries => 10; // Daily goal

  double get _completionPercentage => _todayEntries.length / _totalEntries;

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'happy': return Colors.amber;
      case 'calm': return Colors.blue;
      case 'proud': return Colors.purple;
      case 'relaxed': return Colors.teal;
      case 'thoughtful': return Colors.indigo;
      case 'peaceful': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getMoodColorName(String mood) {
    switch (mood) {
      case 'happy': return 'amber';
      case 'calm': return 'blue';
      case 'proud': return 'purple';
      case 'relaxed': return 'teal';
      case 'thoughtful': return 'indigo';
      case 'peaceful': return 'green';
      default: return 'grey';
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'happy': return Icons.emoji_emotions;
      case 'calm': return Icons.spa;
      case 'proud': return Icons.emoji_events;
      case 'relaxed': return Icons.beach_access;
      case 'thoughtful': return Icons.psychology;
      case 'peaceful': return Icons.self_improvement;
      default: return Icons.edit;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Personal': return Icons.person;
      case 'Cognitive': return Icons.psychology;
      case 'Social': return Icons.people;
      case 'Physical': return Icons.directions_walk;
      case 'Mental': return Icons.self_improvement;
      case 'Family': return Icons.family_restroom;
      default: return Icons.menu_book;
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
      await _secureStorage.write(key: 'user_logged_in', value: 'false');
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
          title: const Text('Memory Diary'),
          backgroundColor: Colors.teal[600],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.teal),
              SizedBox(height: 16),
              Text('Loading memories...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Memory Diary'),
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: _addNewEntry,
            icon: const Icon(Icons.add),
            tooltip: 'Add Memory',
          ),
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
                            Icons.menu_book,
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
                                "Today's Memories",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Keep $_patientName engaged',
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
                                value: _completionPercentage > 1 ? 1 : _completionPercentage,
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
                                '$_completedCount memories recorded',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Keep adding your thoughts!',
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
              const Text(
                "Memory Categories",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildStatCard('Personal', _weeklyStats['Personal']!, Colors.amber)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Cognitive', _weeklyStats['Cognitive']!, Colors.purple)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Social', _weeklyStats['Social']!, Colors.blue)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Physical', _weeklyStats['Physical']!, Colors.green)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Mental', _weeklyStats['Mental']!, Colors.teal)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Family', 2, Colors.orange)),
                ],
              ),

              const SizedBox(height: 20),

              // Today's Entries
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Memories",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addNewEntry,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add New'),
                    style: TextButton.styleFrom(foregroundColor: Colors.teal),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              ..._todayEntries.map((entry) => _buildEntryCard(entry)).toList(),

              const SizedBox(height: 20),

              // Memory Tips
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.teal[700], size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Memory Tips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildTipRow('📝', 'Write down important events each day'),
                    _buildTipRow('📸', 'Add photos to trigger memories'),
                    _buildTipRow('🎵', 'Music can help recall memories'),
                    _buildTipRow('👨‍👩‍👧', 'Share memories with family'),
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
      case 'Personal': return Icons.person;
      case 'Cognitive': return Icons.psychology;
      case 'Social': return Icons.people;
      case 'Physical': return Icons.fitness_center;
      case 'Mental': return Icons.self_improvement;
      case 'Family': return Icons.family_restroom;
      default: return Icons.menu_book;
    }
  }

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    final moodColor = _getMoodColor(entry['mood'] ?? 'happy');
    final typeIcon = _getTypeIcon(entry['type'] ?? 'Personal');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: moodColor.withOpacity(0.3),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: moodColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getMoodIcon(entry['mood'] ?? 'happy'),
                    color: moodColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 2),
                          Text(
                            entry['time'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editEntry(entry['id']);
                    } else if (value == 'delete') {
                      _deleteEntry(entry['id']);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry['description'],
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: moodColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 10, color: moodColor),
                      const SizedBox(width: 4),
                      Text(
                        entry['type'],
                        style: TextStyle(
                          fontSize: 10,
                          color: moodColor,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildTipRow(String emoji, String tip) {
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
                color: Colors.teal[800],
              ),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}