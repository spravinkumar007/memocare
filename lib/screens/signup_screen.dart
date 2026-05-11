import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

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
      await _saveUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Registration successful! Welcome to MemoCare!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

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
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[400]!, Colors.blue[700]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (_currentPage > 0) {
                            _previousPage();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Create Patient Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Progress Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${_currentPage + 1}/4',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / 4,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              const SizedBox(height: 20),

              // Form Pages
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
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
                            side: const BorderSide(color: Colors.white, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Previous',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (_currentPage > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 3,
                          shadowColor: Colors.white.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                            : Text(
                          _currentPage == 3 ? 'Complete Registration' : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // Page Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create your login credentials',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Email Address *',
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              hintText: 'Enter your email',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(
                Icons.email_outlined,
                size: 22,
                color: Colors.blue,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Password *',
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              hintText: 'Create a password',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(
                Icons.lock_outlined,
                size: 22,
                color: Colors.blue,
              ),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 22,
                  color: Colors.grey[600],
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Confirm Password *',
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              hintText: 'Re-enter your password',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline,
                size: 22,
                color: Colors.blue,
              ),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  size: 22,
                  color: Colors.grey[600],
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Password Requirements
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Password must be at least 6 characters long',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPatientInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Patient Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tell us about the patient',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Full Name
          TextFormField(
            controller: _patientNameController,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Full Name *',
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              hintText: 'Enter patient\'s full name',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.person_outlined, size: 22, color: Colors.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Name is required';
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Age and Gender Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _patientAgeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Age *',
                    labelStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    hintText: 'Years',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Icon(Icons.cake_outlined, size: 22, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.green, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Gender Dropdown - FIXED VERSION
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!, width: 1.5),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedGender,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.green, size: 24),
                    iconSize: 24,
                    elevation: 8,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    dropdownColor: Colors.white,
                    menuMaxHeight: 200,
                    decoration: InputDecoration(
                      labelText: 'Gender *',
                      labelStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                      prefixIcon: const Icon(Icons.wc_outlined, size: 22, color: Colors.green),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    ),
                    items: _genderOptions.map((gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(
                          gender,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Phone
          TextFormField(
            controller: _patientPhoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              hintText: 'Enter contact number',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.phone_outlined, size: 22, color: Colors.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Phone number is required';
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Address
          TextFormField(
            controller: _patientAddressController,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Address *',
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              hintText: 'Enter full address',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.home_outlined, size: 22, color: Colors.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Address is required';
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Medical Conditions (Optional)
          TextFormField(
            controller: _medicalConditionsController,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Medical Conditions (Optional)',
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              hintText: 'e.g., Alzheimer\'s, Diabetes, Hypertension',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.medical_services_outlined, size: 22, color: Colors.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
          const SizedBox(height: 18),

          // Medications (Optional)
          TextFormField(
            controller: _medicationsController,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Current Medications (Optional)',
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              hintText: 'List current medications',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.medication_outlined, size: 22, color: Colors.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
          const SizedBox(height: 18),

          // Allergies (Optional)
          TextFormField(
            controller: _allergiesController,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Allergies (Optional)',
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              hintText: 'Food, drug, or other allergies',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.warning_outlined, size: 22, color: Colors.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCaretakerInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Caretaker Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Primary caretaker details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Caretaker Name
          TextFormField(
            controller: _caretakerNameController,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Caretaker Name *',
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              hintText: 'Enter caretaker\'s full name',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.person_outlined, size: 22, color: Colors.orange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Name is required';
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Caretaker Phone
          TextFormField(
            controller: _caretakerPhoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              hintText: 'Enter contact number',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.phone_outlined, size: 22, color: Colors.orange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Phone number is required';
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Caretaker Email (Optional)
          TextFormField(
            controller: _caretakerEmailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Email Address (Optional)',
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              hintText: 'Enter email address',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.email_outlined, size: 22, color: Colors.orange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),
          const SizedBox(height: 18),

          // Relationship Dropdown - FIXED VERSION
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 1.5),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedCaretakerRelation,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.orange, size: 24),
              iconSize: 24,
              elevation: 8,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              dropdownColor: Colors.white,
              menuMaxHeight: 300,
              decoration: InputDecoration(
                labelText: 'Relationship to Patient *',
                labelStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
                prefixIcon: const Icon(Icons.family_restroom_outlined, size: 22, color: Colors.orange),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
              items: _relationOptions.map((relation) {
                return DropdownMenuItem<String>(
                  value: relation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      relation,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCaretakerRelation = value!;
                });
              },
            ),
          ),
          const SizedBox(height: 18),

          // Caretaker Address (Optional)
          TextFormField(
            controller: _caretakerAddressController,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Address (Optional)',
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              hintText: 'Enter full address',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.home_outlined, size: 22, color: Colors.orange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add emergency contact information',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Emergency Contact 1
          _buildEmergencyContactCard(0, 'Emergency Contact 1'),

          const SizedBox(height: 24),

          // Emergency Contact 2
          _buildEmergencyContactCard(1, 'Emergency Contact 2'),

          const SizedBox(height: 24),

          // Success Message
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green[200]!, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green[700], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Almost Done!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review your information and tap Complete Registration',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard(int index, String title) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Name
          TextFormField(
            controller: _emergencyContacts[index]['name']!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Full Name *',
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              hintText: 'Enter full name',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.person_outlined, size: 22, color: Colors.red),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Name is required';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Phone
          TextFormField(
            controller: _emergencyContacts[index]['phone']!,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Phone Number *',
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              hintText: 'Enter phone number',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.phone_outlined, size: 22, color: Colors.red),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Phone number is required';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Relation
          TextFormField(
            controller: _emergencyContacts[index]['relation']!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'Relationship *',
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              hintText: 'e.g., Spouse, Child, Doctor',
              hintStyle: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(Icons.family_restroom_outlined, size: 22, color: Colors.red),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Relationship is required';
              return null;
            },
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

    _pageController.dispose();
    super.dispose();
  }
}