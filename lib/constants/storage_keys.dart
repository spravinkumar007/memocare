class StorageKeys {
  static const String userLoggedIn = 'user_logged_in';
  static const String faceRegistered = 'face_registered';
  static const String userEmail = 'user_email';
  static const String userPassword = 'user_password';

  // Patient
  static const String patientName = 'patient_name';
  static const String patientAge = 'patient_age';
  static const String patientGender = 'patient_gender';
  static const String patientPhone = 'patient_phone';
  static const String patientAddress = 'patient_address';
  static const String medicalConditions = 'medical_conditions';
  static const String medications = 'medications';
  static const String allergies = 'allergies';

  // Caretaker
  static const String caretakerName = 'caretaker_name';
  static const String caretakerPhone = 'caretaker_phone';
  static const String caretakerEmail = 'caretaker_email';
  static const String caretakerRelation = 'caretaker_relation';
  static const String caretakerAddress = 'caretaker_address';

  // Emergency contacts (use with index)
  static const String emergencyContactName = 'emergency_contact_{i}_name';
  static const String emergencyContactPhone = 'emergency_contact_{i}_phone';
  static const String emergencyContactRelation = 'emergency_contact_{i}_relation';

  //Reminder
  static const String patientReminders = 'patient_reminders';
  static const String reminders = 'reminders';

  //Activity
  static const String activities = 'activities';
}