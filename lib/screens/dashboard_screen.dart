import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Patient Data
  String _patientName = 'Patient';
  String _patientAge = '';
  String _patientGender = '';
  String _patientPhone = '';
  String _patientAddress = '';
  String _medicalConditions = '';
  String _medications = '';
  String _allergies = '';

  // Caregiver Data
  String _caretakerName = '';
  String _caretakerPhone = '';
  String _caretakerEmail = '';
  String _caretakerRelation = '';
  String _caretakerAddress = '';

  // Emergency Contacts
  List<Map<String, String>> _emergencyContacts = [];

  String _userEmail = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllUserData();
  }

  Future<void> _loadAllUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load Patient Data
      final patientName = await _secureStorage.read(key: 'patient_name') ?? 'Patient';
      final patientAge = await _secureStorage.read(key: 'patient_age') ?? '';
      final patientGender = await _secureStorage.read(key: 'patient_gender') ?? '';
      final patientPhone = await _secureStorage.read(key: 'patient_phone') ?? '';
      final patientAddress = await _secureStorage.read(key: 'patient_address') ?? '';
      final medicalConditions = await _secureStorage.read(key: 'medical_conditions') ?? '';
      final medications = await _secureStorage.read(key: 'medications') ?? '';
      final allergies = await _secureStorage.read(key: 'allergies') ?? '';

      // Load Caregiver Data
      final caretakerName = await _secureStorage.read(key: 'caretaker_name') ?? '';
      final caretakerPhone = await _secureStorage.read(key: 'caretaker_phone') ?? '';
      final caretakerEmail = await _secureStorage.read(key: 'caretaker_email') ?? '';
      final caretakerRelation = await _secureStorage.read(key: 'caretaker_relation') ?? '';
      final caretakerAddress = await _secureStorage.read(key: 'caretaker_address') ?? '';

      // Load Emergency Contacts
      final emergencyContacts = <Map<String, String>>[];
      for (int i = 0; i < 2; i++) {
        final name = await _secureStorage.read(key: 'emergency_contact_${i}_name') ?? '';
        final phone = await _secureStorage.read(key: 'emergency_contact_${i}_phone') ?? '';
        final relation = await _secureStorage.read(key: 'emergency_contact_${i}_relation') ?? '';

        if (name.isNotEmpty) {
          emergencyContacts.add({
            'name': name,
            'phone': phone,
            'relation': relation,
          });
        }
      }

      final userEmail = await _secureStorage.read(key: 'user_email') ?? '';

      setState(() {
        _patientName = patientName;
        _patientAge = patientAge;
        _patientGender = patientGender;
        _patientPhone = patientPhone;
        _patientAddress = patientAddress;
        _medicalConditions = medicalConditions;
        _medications = medications;
        _allergies = allergies;

        _caretakerName = caretakerName;
        _caretakerPhone = caretakerPhone;
        _caretakerEmail = caretakerEmail;
        _caretakerRelation = caretakerRelation;
        _caretakerAddress = caretakerAddress;

        _emergencyContacts = emergencyContacts;
        _userEmail = userEmail;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][now.weekday - 1];
    final month = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][now.month - 1];
    return '$weekday, $month ${now.day}, ${now.year}';
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue[100]!, Colors.white],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.blue[600]),
                const SizedBox(height: 16),
                const Text(
                  'Loading your profile...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header with User Info and Logout Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with greeting and logout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getGreeting()},',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _patientName,
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Logout Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: _logout,
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.white,
                            size: 24,
                          ),
                          tooltip: 'Logout',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Date and Weather
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.wb_sunny,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getCurrentDate(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _getCurrentTime(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Weather',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '72°F Clear',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Face Authentication Status
            Card(
              color: Colors.green[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.green.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          "Face Authentication",
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Successfully authenticated!",
                      style: TextStyle(color: Colors.green.shade600, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "Welcome to MemoCare!",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Patient Details Section
            _buildSectionCard(
              'Patient Information',
              Icons.person,
              Colors.blue,
              [
                _buildDetailRow('Name', _patientName, Icons.person_outline),
                if (_patientAge.isNotEmpty)
                  _buildDetailRow('Age', '$_patientAge years', Icons.cake_outlined),
                if (_patientGender.isNotEmpty)
                  _buildDetailRow('Gender', _patientGender, Icons.wc_outlined),
                if (_patientPhone.isNotEmpty)
                  _buildDetailRow('Phone', _patientPhone, Icons.phone_outlined),
                if (_patientAddress.isNotEmpty)
                  _buildDetailRow('Address', _patientAddress, Icons.home_outlined),
                if (_medicalConditions.isNotEmpty)
                  _buildDetailRow('Medical Conditions', _medicalConditions, Icons.medical_services_outlined),
                if (_medications.isNotEmpty)
                  _buildDetailRow('Medications', _medications, Icons.medication_outlined),
                if (_allergies.isNotEmpty)
                  _buildDetailRow('Allergies', _allergies, Icons.warning_outlined),
              ],
            ),

            const SizedBox(height: 20),

            // Caregiver Details Section
            if (_caretakerName.isNotEmpty)
              _buildSectionCard(
                'Primary Caregiver',
                Icons.family_restroom,
                Colors.purple,
                [
                  _buildDetailRow('Name', _caretakerName, Icons.person_outline),
                  if (_caretakerRelation.isNotEmpty)
                    _buildDetailRow('Relationship', _caretakerRelation, Icons.family_restroom_outlined),
                  if (_caretakerPhone.isNotEmpty)
                    _buildDetailRow('Phone', _caretakerPhone, Icons.phone_outlined),
                  if (_caretakerEmail.isNotEmpty)
                    _buildDetailRow('Email', _caretakerEmail, Icons.email_outlined),
                  if (_caretakerAddress.isNotEmpty)
                    _buildDetailRow('Address', _caretakerAddress, Icons.home_outlined),
                ],
              ),

            const SizedBox(height: 20),

            // Emergency Contacts Section
            if (_emergencyContacts.isNotEmpty)
              _buildSectionCard(
                'Emergency Contacts',
                Icons.emergency,
                Colors.red,
                _emergencyContacts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final contact = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (index > 0) const Divider(height: 20),
                      Text(
                        'Emergency Contact ${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Name', contact['name']!, Icons.person_outline),
                      _buildDetailRow('Phone', contact['phone']!, Icons.phone_outlined),
                      _buildDetailRow('Relationship', contact['relation']!, Icons.group_outlined),
                    ],
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),

            // Account Information
            _buildSectionCard(
              'Account Information',
              Icons.account_circle,
              Colors.teal,
              [
                if (_userEmail.isNotEmpty)
                  _buildDetailRow('Email', _userEmail, Icons.email_outlined),
                _buildDetailRow('Registration Date', _getCurrentDate(), Icons.calendar_today_outlined),
                _buildDetailRow('Account Status', 'Active', Icons.verified_outlined),
              ],
            ),

            const SizedBox(height: 100), // Space for bottom navigation
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[600],
        onPressed: () {
          // Voice action
        },
        child: const Icon(Icons.mic, color: Colors.white, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
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
