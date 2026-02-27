import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class MedicationScreen extends StatefulWidget {
  final Function? onVoiceAssistantPressed;

  const MedicationScreen({super.key, this.onVoiceAssistantPressed});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    try {
      final medsData = await _storage.read(key: 'medications_list');
      if (medsData != null) {
        _medications = List<Map<String, dynamic>>.from(jsonDecode(medsData));
      } else {
        _setDefaultMedications();
      }
    } catch (e) {
      debugPrint('Error loading medications: $e');
      _setDefaultMedications();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setDefaultMedications() {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final nextMonth = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 30)));

    _medications = [
      {
        'id': '1',
        'name': 'Donepezil',
        'dosage': '10mg',
        'frequency': 'Once daily',
        'time': '08:00 AM',
        'instructions': 'Take with food',
        'refillDate': nextMonth,
        'remaining': 30,
        'taken': false,
        'startDate': today,
      },
      {
        'id': '2',
        'name': 'Memantine',
        'dosage': '5mg',
        'frequency': 'Twice daily',
        'time': '08:00 AM, 08:00 PM',
        'instructions': 'Can be taken with or without food',
        'refillDate': DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 45))),
        'remaining': 60,
        'taken': false,
        'startDate': today,
      },
    ];
    _saveMedications();
  }

  Future<void> _saveMedications() async {
    await _storage.write(key: 'medications_list', value: jsonEncode(_medications));
  }

  void _markAsTaken(String id) {
    setState(() {
      final index = _medications.indexWhere((m) => m['id'] == id);
      if (index != -1) {
        _medications[index]['taken'] = !(_medications[index]['taken'] ?? false);
      }
    });
    _saveMedications();
  }

  void _deleteMedication(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Delete Medication',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        content: const Text(
          'Are you sure you want to delete this medication?',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _medications.removeWhere((m) => m['id'] == id);
      });
      _saveMedications();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication deleted successfully', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _editMedication(Map<String, dynamic> medication) {
    _showAddEditMedicationDialog(medication: medication);
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text('Logout', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout from MemoCare?',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _storage.write(key: 'user_logged_in', value: 'false');
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
      }
    }
  }

  void _showAddEditMedicationDialog({Map<String, dynamic>? medication}) {
    final bool isEditing = medication != null;
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: medication?['name'] ?? '');
    final _dosageController = TextEditingController(text: medication?['dosage'] ?? '');
    final _timeController = TextEditingController(text: medication?['time'] ?? '');
    final _instructionsController = TextEditingController(text: medication?['instructions'] ?? '');
    final _refillDateController = TextEditingController(text: medication?['refillDate'] ?? '');
    final _remainingController = TextEditingController(text: medication?['remaining']?.toString() ?? '');

    String _selectedFrequency = medication?['frequency'] ?? 'Once daily';
    final List<String> _frequencies = [
      'Once daily',
      'Twice daily',
      'Three times daily',
      'Four times daily',
      'As needed',
      'Weekly',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(isEditing ? Icons.edit : Icons.medication, color: Colors.teal[700]),
            ),
            const SizedBox(width: 12),
            Text(
              isEditing ? 'Edit Medication' : 'Add Medication',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Medication Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Medication Name',
                    labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(Icons.medication_outlined, size: 20, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  style: const TextStyle(color: Colors.black87),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter medication name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Dosage
                TextFormField(
                  controller: _dosageController,
                  decoration: InputDecoration(
                    labelText: 'Dosage (e.g., 10mg)',
                    labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(Icons.science_outlined, size: 20, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  style: const TextStyle(color: Colors.black87),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter dosage';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Frequency Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedFrequency,
                  decoration: InputDecoration(
                    labelText: 'Frequency',
                    labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(Icons.access_time, size: 20, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black87),
                  items: _frequencies.map((String frequency) {
                    return DropdownMenuItem<String>(
                      value: frequency,
                      child: Text(frequency, style: const TextStyle(color: Colors.black87)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    _selectedFrequency = newValue!;
                  },
                ),
                const SizedBox(height: 12),

                // Time
                TextFormField(
                  controller: _timeController,
                  decoration: InputDecoration(
                    labelText: 'Time (e.g., 08:00 AM)',
                    labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(Icons.schedule, size: 20, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  style: const TextStyle(color: Colors.black87),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter time';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Instructions
                TextFormField(
                  controller: _instructionsController,
                  decoration: InputDecoration(
                    labelText: 'Instructions',
                    labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(Icons.info_outline, size: 20, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  style: const TextStyle(color: Colors.black87),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // Refill Date
                TextFormField(
                  controller: _refillDateController,
                  decoration: InputDecoration(
                    labelText: 'Refill Date (YYYY-MM-DD)',
                    labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(Icons.calendar_today, size: 20, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  style: const TextStyle(color: Colors.black87),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter refill date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Remaining pills
                TextFormField(
                  controller: _remainingController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Remaining pills',
                    labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(Icons.numbers, size: 20, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  style: const TextStyle(color: Colors.black87),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter remaining pills';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (isEditing) {
                  _updateMedication(
                    id: medication!['id'],
                    name: _nameController.text,
                    dosage: _dosageController.text,
                    frequency: _selectedFrequency,
                    time: _timeController.text,
                    instructions: _instructionsController.text,
                    refillDate: _refillDateController.text,
                    remaining: int.parse(_remainingController.text),
                    taken: medication['taken'] ?? false,
                  );
                } else {
                  _addMedication(
                    name: _nameController.text,
                    dosage: _dosageController.text,
                    frequency: _selectedFrequency,
                    time: _timeController.text,
                    instructions: _instructionsController.text,
                    refillDate: _refillDateController.text,
                    remaining: int.parse(_remainingController.text),
                  );
                }
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: Text(
              isEditing ? 'Update' : 'Add Medication',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _addMedication({
    required String name,
    required String dosage,
    required String frequency,
    required String time,
    required String instructions,
    required String refillDate,
    required int remaining,
  }) {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    final newMedication = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'time': time,
      'instructions': instructions.isEmpty ? 'No specific instructions' : instructions,
      'refillDate': refillDate,
      'remaining': remaining,
      'taken': false,
      'startDate': today,
    };

    setState(() {
      _medications.add(newMedication);
    });
    _saveMedications();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name added successfully!', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _updateMedication({
    required String id,
    required String name,
    required String dosage,
    required String frequency,
    required String time,
    required String instructions,
    required String refillDate,
    required int remaining,
    required bool taken,
  }) {
    setState(() {
      final index = _medications.indexWhere((m) => m['id'] == id);
      if (index != -1) {
        _medications[index] = {
          'id': id,
          'name': name,
          'dosage': dosage,
          'frequency': frequency,
          'time': time,
          'instructions': instructions.isEmpty ? 'No specific instructions' : instructions,
          'refillDate': refillDate,
          'remaining': remaining,
          'taken': taken,
          'startDate': _medications[index]['startDate'],
        };
      }
    });
    _saveMedications();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name updated successfully!', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRefillReminder() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notification_important, color: Colors.teal),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Refill Reminders',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey),
            if (_medications.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No medications added yet', style: TextStyle(color: Colors.black87)),
              )
            else
              ..._medications.map((med) {
                final refill = DateTime.tryParse(med['refillDate'] ?? '');
                if (refill == null) return const SizedBox.shrink();

                final daysLeft = refill.difference(DateTime.now()).inDays;
                final color = daysLeft <= 3 ? Colors.red : (daysLeft <= 7 ? Colors.orange : Colors.green);

                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      daysLeft <= 3 ? Icons.warning : Icons.event,
                      color: color,
                    ),
                  ),
                  title: Text(med['name'], style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  subtitle: Text('Refill by: ${med['refillDate']}', style: const TextStyle(color: Colors.black54)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      daysLeft < 0 ? 'Overdue' : '$daysLeft days',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Medication Tracker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: Colors.teal[700],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.teal),
              SizedBox(height: 16),
              Text('Loading medications...', style: TextStyle(color: Colors.black87)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Medication Tracker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Refill Reminder Bell Button
          IconButton(
            onPressed: _showRefillReminder,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 24),
                // Add badge if there are medications needing refill soon
                if (_medications.any((m) {
                  final refill = DateTime.tryParse(m['refillDate'] ?? '');
                  return refill != null && refill.difference(DateTime.now()).inDays <= 3;
                }))
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Refill Reminders',
          ),
          // Voice Assistant Button
          if (widget.onVoiceAssistantPressed != null)
            IconButton(
              onPressed: () => widget.onVoiceAssistantPressed!(),
              icon: const Icon(Icons.mic, color: Colors.white),
              tooltip: 'Voice Assistant',
            ),
          // Logout Button
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Card (3D)
          _build3DSummaryCard(),

          const SizedBox(height: 24),

          // Today's Medications Title with Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Medications",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal[400]!, Colors.teal[600]!],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: MaterialButton(
                  onPressed: () => _showAddEditMedicationDialog(),
                  height: 40,
                  minWidth: 40,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Medications List
          if (_medications.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.medication_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No medications added yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the Add button to add your first medication',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ..._medications.map((med) => _build3DMedicationCard(med)).toList(),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _build3DSummaryCard() {
    final int totalMeds = _medications.length;
    final int takenMeds = _medications.where((m) => m['taken'] == true).length;
    final int refillNeeded = _medications.where((m) {
      final refill = DateTime.tryParse(m['refillDate'] ?? '');
      return refill != null && refill.difference(DateTime.now()).inDays <= 7;
    }).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal[400]!, Colors.teal[700]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Medication Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total', totalMeds.toString(), Icons.medication, Colors.white),
              _buildSummaryItem('Taken', takenMeds.toString(), Icons.check_circle, Colors.green[300]!),
              _buildSummaryItem('Refill', refillNeeded.toString(), Icons.warning, Colors.orange[300]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _build3DMedicationCard(Map<String, dynamic> medication) {
    final bool taken = medication['taken'] ?? false;
    final Color cardColor = taken ? Colors.green : Colors.teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: taken ? 3 : 2,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 10,
            offset: const Offset(-2, -2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cardColor.withOpacity(0.1),
                        cardColor.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: cardColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    taken ? Icons.check_circle : Icons.medication,
                    color: cardColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          decoration: taken ? TextDecoration.lineThrough : null,
                          shadows: [
                            Shadow(
                              color: cardColor.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: cardColor.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          medication['dosage'],
                          style: TextStyle(
                            fontSize: 12,
                            color: cardColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit and Delete buttons
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _editMedication(medication),
                      icon: Icon(Icons.edit_outlined, color: Colors.blue[600], size: 20),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: () => _deleteMedication(medication['id']),
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.access_time, 'Frequency', medication['frequency'], cardColor),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.schedule, 'Time', medication['time'], cardColor),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.info_outline, 'Instructions', medication['instructions'], cardColor),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today,
              'Refill',
              '${medication['refillDate']} (${medication['remaining']} left)',
              cardColor,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsTaken(medication['id']),
                    icon: Icon(taken ? Icons.undo : Icons.check, color: Colors.white),
                    label: Text(
                      taken ? 'Mark as Pending' : 'Mark as Taken',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: taken ? Colors.grey : cardColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                      shadowColor: cardColor.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}