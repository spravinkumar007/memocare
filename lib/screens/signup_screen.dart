import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart'; // import constants

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  int _currentPage = 0;
  bool _isLoading = false;

  // Account Info
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Patient Details
  final _patientNameController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _patientPhoneController = TextEditingController();
  final _patientAddressController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _allergiesController = TextEditingController();

  // Caretaker Details
  final _caretakerNameController = TextEditingController();
  final _caretakerPhoneController = TextEditingController();
  final _caretakerEmailController = TextEditingController();
  final _caretakerRelationController = TextEditingController();
  final _caretakerAddressController = TextEditingController();

  // Emergency Contacts
  final List<Map<String, TextEditingController>> _emergencyContacts = [
    {
      'name': TextEditingController(),
      'phone': TextEditingController(),
      'relation': TextEditingController(),
    },
    {
      'name': TextEditingController(),
      'phone': TextEditingController(),
      'relation': TextEditingController(),
    },
  ];

  String _selectedGender = 'Male';
  String _selectedCaretakerRelation = 'Spouse';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _relationOptions = [
    'Spouse', 'Child', 'Parent', 'Sibling',
    'Relative', 'Friend', 'Professional Caregiver', 'Other'
  ];

  Future<void> _nextPage() async {
    if (_currentPage < 3) {
      if (_validateCurrentPage()) {
        setState(() {
          _currentPage++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      await _completeRegistration();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _validateAccountInfo();
      case 1:
        return _validatePatientInfo();
      case 2:
        return _validateCaretakerInfo();
      case 3:
        return _validateEmergencyContacts();
      default:
        return false;
    }
  }

  bool _validateAccountInfo() {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showMessage('Please fill all required fields');
      return false;
    }
    if (!_emailController.text.contains('@') || !_emailController.text.contains('.')) {
      _showMessage('Please enter a valid email');
      return false;
    }
    if (_passwordController.text.length < 6) {
      _showMessage('Password must be at least 6 characters');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match');
      return false;
    }
    return true;
  }

  bool _validatePatientInfo() {
    if (_patientNameController.text.isEmpty ||
        _patientAgeController.text.isEmpty ||
        _patientPhoneController.text.isEmpty ||
        _patientAddressController.text.isEmpty) {
      _showMessage('Please fill all required patient information');
      return false;
    }
    return true;
  }

  bool _validateCaretakerInfo() {
    if (_caretakerNameController.text.isEmpty ||
        _caretakerPhoneController.text.isEmpty) {
      _showMessage('Please fill required caretaker information');
      return false;
    }
    return true;
  }

  bool _validateEmergencyContacts() {
    for (int i = 0; i < _emergencyContacts.length; i++) {
      if (_emergencyContacts[i]['name']!.text.isEmpty ||
          _emergencyContacts[i]['phone']!.text.isEmpty ||
          _emergencyContacts[i]['relation']!.text.isEmpty) {
        _showMessage('Please fill all emergency contact information');
        return false;
      }
    }
    return true;
  }

  Future<void> _completeRegistration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save all data to secure storage using constants
      await _saveUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Welcome to MemoCare!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to real face authentication
        Navigator.of(context).pushReplacementNamed('/real-face-auth');
      }
    } catch (e) {
      _showMessage('Registration failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserData() async {
    // Account info
    await _secureStorage.write(key: StorageKeys.userEmail, value: _emailController.text.trim());
    await _secureStorage.write(key: StorageKeys.userPassword, value: _passwordController.text);
    await _secureStorage.write(key: StorageKeys.userLoggedIn, value: 'true');

    // Patient details
    await _secureStorage.write(key: StorageKeys.patientName, value: _patientNameController.text);
    await _secureStorage.write(key: StorageKeys.patientAge, value: _patientAgeController.text);
    await _secureStorage.write(key: StorageKeys.patientGender, value: _selectedGender);
    await _secureStorage.write(key: StorageKeys.patientPhone, value: _patientPhoneController.text);
    await _secureStorage.write(key: StorageKeys.patientAddress, value: _patientAddressController.text);
    await _secureStorage.write(key: StorageKeys.medicalConditions, value: _medicalConditionsController.text);
    await _secureStorage.write(key: StorageKeys.medications, value: _medicationsController.text);
    await _secureStorage.write(key: StorageKeys.allergies, value: _allergiesController.text);

    // Caretaker details
    await _secureStorage.write(key: StorageKeys.caretakerName, value: _caretakerNameController.text);
    await _secureStorage.write(key: StorageKeys.caretakerPhone, value: _caretakerPhoneController.text);
    await _secureStorage.write(key: StorageKeys.caretakerEmail, value: _caretakerEmailController.text);
    await _secureStorage.write(key: StorageKeys.caretakerRelation, value: _selectedCaretakerRelation);
    await _secureStorage.write(key: StorageKeys.caretakerAddress, value: _caretakerAddressController.text);

    // Emergency contacts
    for (int i = 0; i < _emergencyContacts.length; i++) {
      final nameKey = StorageKeys.emergencyContactName.replaceFirst('{i}', i.toString());
      final phoneKey = StorageKeys.emergencyContactPhone.replaceFirst('{i}', i.toString());
      final relationKey = StorageKeys.emergencyContactRelation.replaceFirst('{i}', i.toString());

      await _secureStorage.write(key: nameKey, value: _emergencyContacts[i]['name']!.text);
      await _secureStorage.write(key: phoneKey, value: _emergencyContacts[i]['phone']!.text);
      await _secureStorage.write(key: relationKey, value: _emergencyContacts[i]['relation']!.text);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[300]!, Colors.blue[600]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_currentPage > 0) {
                          _previousPage();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Create Patient Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Progress indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index <= _currentPage
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48), // Balance
                  ],
                ),
              ),

              // Form Pages
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildAccountInfoPage(),
                        _buildPatientInfoPage(),
                        _buildCaretakerInfoPage(),
                        _buildEmergencyContactsPage(),
                      ],
                    ),
                  ),
                ),
              ),

              // Navigation Buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousPage,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Previous'),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue[600],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : Text(_currentPage == 3 ? 'Complete Registration' : 'Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountInfoPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your login credentials',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address *',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password *',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password *',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us about the patient',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _patientNameController,
            decoration: InputDecoration(
              labelText: 'Full Name *',
              prefixIcon: const Icon(Icons.person_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _patientAgeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Age *',
                    prefixIcon: const Icon(Icons.cake_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender *',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: _genderOptions.map((gender) {
                    return DropdownMenuItem(value: gender, child: Text(gender));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedGender = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _patientPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _patientAddressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Address *',
              prefixIcon: const Icon(Icons.home_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _medicalConditionsController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Medical Conditions',
              prefixIcon: const Icon(Icons.medical_services_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              hintText: 'e.g., Alzheimer\'s, Diabetes, Hypertension',
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _medicationsController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Current Medications',
              prefixIcon: const Icon(Icons.medication_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              hintText: 'List current medications',
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _allergiesController,
            decoration: InputDecoration(
              labelText: 'Allergies',
              prefixIcon: const Icon(Icons.warning_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              hintText: 'Food, drug, or other allergies',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaretakerInfoPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Caretaker Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Primary caretaker details',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          TextFormField(
            controller: _caretakerNameController,
            decoration: InputDecoration(
              labelText: 'Caretaker Name *',
              prefixIcon: const Icon(Icons.person_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _caretakerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _caretakerEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedCaretakerRelation,
            decoration: InputDecoration(
              labelText: 'Relationship to Patient *',
              prefixIcon: const Icon(Icons.family_restroom_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: _relationOptions.map((relation) {
              return DropdownMenuItem(value: relation, child: Text(relation));
            }).toList(),
            onChanged: (value) => setState(() => _selectedCaretakerRelation = value!),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _caretakerAddressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Address',
              prefixIcon: const Icon(Icons.home_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emergency Contacts',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add emergency contact information',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          ...List.generate(_emergencyContacts.length, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency Contact ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emergencyContacts[index]['name']!,
                    decoration: InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: const Icon(Icons.person_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _emergencyContacts[index]['phone']!,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number *',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _emergencyContacts[index]['relation']!,
                    decoration: InputDecoration(
                      labelText: 'Relationship *',
                      prefixIcon: const Icon(Icons.family_restroom_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'e.g., Doctor, Neighbor, Relative',
                    ),
                  ),
                ],
              ),
            );
          }),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Great! You\'re all set. Click "Complete Registration" to finish.',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _patientNameController.dispose();
    _patientAgeController.dispose();
    _patientPhoneController.dispose();
    _patientAddressController.dispose();
    _medicalConditionsController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    _caretakerNameController.dispose();
    _caretakerPhoneController.dispose();
    _caretakerEmailController.dispose();
    _caretakerRelationController.dispose();
    _caretakerAddressController.dispose();

    for (var contact in _emergencyContacts) {
      contact['name']!.dispose();
      contact['phone']!.dispose();
      contact['relation']!.dispose();
    }

    super.dispose();
  }
}