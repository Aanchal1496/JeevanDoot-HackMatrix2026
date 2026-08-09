import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/doctor_models.dart';
import '../models/models.dart';
import '../screens/profile_settings.dart';
import 'api_client.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class AdviceItem {
  const AdviceItem({required this.title, required this.body});

  final String title;
  final String body;

  factory AdviceItem.fromJson(Map<String, dynamic> json) => AdviceItem(
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
      );
}

class SlotDate {
  const SlotDate({
    required this.id,
    required this.label,
    required this.day,
    required this.month,
    required this.full,
    required this.weekday,
  });

  final String id;
  final String label;
  final int day;
  final String month;
  final String full;
  final String weekday;

  factory SlotDate.fromJson(Map<String, dynamic> json) => SlotDate(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        day: json['day'] as int? ?? 0,
        month: json['month'] as String? ?? '',
        full: json['full'] as String? ?? '',
        weekday: json['weekday'] as String? ?? '',
      );
}

class SlotTime {
  const SlotTime({required this.id, required this.label});

  final String id;
  final String label;

  factory SlotTime.fromJson(Map<String, dynamic> json) => SlotTime(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );
}

class BookedAppointment {
  const BookedAppointment({
    required this.id,
    required this.name,
    required this.doctorName,
    required this.specialization,
    required this.time,
    required this.date,
    required this.weekday,
    required this.consultType,
  });

  final String id;
  final String name;
  final String doctorName;
  final String specialization;
  final String time;
  final String date;
  final String weekday;
  final String consultType;

  factory BookedAppointment.fromJson(Map<String, dynamic> json) =>
      BookedAppointment(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        doctorName: json['doctor_name'] as String? ?? 'Dr. Priya Sharma',
        specialization:
            json['specialization'] as String? ?? 'General Physician',
        time: json['time'] as String? ?? '5:30 PM',
        date: json['date'] as String? ?? 'August 10, 2026',
        weekday: json['weekday'] as String? ?? 'Monday',
        consultType:
            json['consult_type'] as String? ?? 'Video Consultation',
      );
}

class DoctorStats {
  const DoctorStats({
    required this.patients,
    required this.waiting,
    required this.urgent,
    required this.completed,
  });

  final String patients;
  final String waiting;
  final String urgent;
  final String completed;

  factory DoctorStats.fromJson(Map<String, dynamic> json) => DoctorStats(
        patients: json['patients']?.toString() ?? '0',
        waiting: json['waiting']?.toString() ?? '0',
        urgent: json['urgent']?.toString() ?? '0',
        completed: json['completed']?.toString() ?? '0',
      );
}

class PatientCase {
  const PatientCase({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.symptoms,
    required this.vitals,
    required this.history,
    required this.aiSummary,
  });

  final String id;
  final String name;
  final String age;
  final String gender;
  final List<String> symptoms;
  final Map<String, String> vitals;
  final Map<String, List<String>> history;
  final String aiSummary;

  factory PatientCase.fromJson(Map<String, dynamic> json) => PatientCase(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        age: (json['age'] ?? '').toString(),
        gender: json['gender'] as String? ?? '',
        symptoms: (json['symptoms'] as List?)?.cast<String>() ?? const [],
        vitals: (json['vitals'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
            ) ??
            const {},
        history: (json['history'] as Map?)?.map(
              (k, v) => MapEntry(
                k.toString(),
                (v as List?)?.cast<String>() ?? const [],
              ),
            ) ??
            const {},
        aiSummary: json['ai_summary'] as String? ?? '',
      );
}

class PrescriptionItem {
  const PrescriptionItem({
    required this.name,
    required this.category,
    required this.dosage,
    required this.unit,
    required this.morning,
    required this.afternoon,
    required this.night,
    required this.days,
    required this.instructions,
  });

  final String name;
  final String category;
  final String dosage;
  final String unit;
  final int morning;
  final int afternoon;
  final int night;
  final int days;
  final String instructions;

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) =>
      PrescriptionItem(
        name: json['name'] as String? ?? '',
        category: json['category'] as String? ?? 'Tablet',
        dosage: (json['dosage'] ?? '').toString(),
        unit: json['unit'] as String? ?? 'mg',
        morning: json['morning'] as int? ?? 0,
        afternoon: json['afternoon'] as int? ?? 0,
        night: json['night'] as int? ?? 0,
        days: json['days'] as int? ?? 5,
        instructions: json['instructions'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'dosage': dosage,
        'unit': unit,
        'morning': morning,
        'afternoon': afternoon,
        'night': night,
        'days': days,
        'instructions': instructions,
      };
}

class Prescription {
  const Prescription({
    required this.id,
    required this.doctorName,
    required this.date,
    required this.notes,
    required this.medicines,
  });

  final String id;
  final String doctorName;
  final String date;
  final String notes;
  final List<PrescriptionItem> medicines;

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
        id: json['id'] as String? ?? '',
        doctorName: json['doctor_name'] as String? ?? '',
        date: json['date'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        medicines: (json['medicines'] as List?)
                ?.map((e) =>
                    PrescriptionItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class RecordEvent {
  const RecordEvent({
    required this.date,
    required this.type,
    required this.title,
    required this.detail,
  });

  final String date;
  final String type;
  final String title;
  final String detail;

  factory RecordEvent.fromJson(Map<String, dynamic> json) => RecordEvent(
        date: json['date'] as String? ?? '',
        type: json['type'] as String? ?? 'Consultation',
        title: json['title'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
      );
}

class ReminderItem {
  const ReminderItem({
    required this.id,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.active,
    required this.done,
  });

  final String id;
  final String time;
  final String title;
  final String subtitle;
  final String icon;
  final bool active;
  final bool done;

  factory ReminderItem.fromJson(Map<String, dynamic> json) => ReminderItem(
        id: json['id'] as String? ?? '',
        time: json['time'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        icon: json['icon'] as String? ?? 'medication',
        active: (json['active'] as int? ?? 0) == 1,
        done: (json['done'] as int? ?? 0) == 1,
      );
}

// ---------------------------------------------------------------------------
// Auth session
// ---------------------------------------------------------------------------

const _kPrefsToken = 'auth_token';
const _kPrefsRole = 'auth_role';
const _kPrefsUser = 'auth_user';

class SessionData {
  const SessionData({required this.token, required this.role, required this.user});

  final String token;
  final String role;
  final Map<String, dynamic> user;
}

/// Applies a patient payload to the in-memory [UserData] / [AppState] stores.
void applyPatientUser(Map<String, dynamic> user) {
  UserData.name = user['name'] ?? UserData.name;
  UserData.phone = user['phone'] ?? UserData.phone;
  UserData.age = (user['age'] ?? UserData.age).toString();
  UserData.gender = user['gender'] ?? UserData.gender;
  UserData.bloodGroup = user['blood_group'] ?? UserData.bloodGroup;
  UserData.email = user['email'] ?? UserData.email;
  UserData.address = user['address'] ?? UserData.address;
  UserData.dob = user['dob'] ?? UserData.dob;
  UserData.idNumber = user['id_number'] ?? UserData.idNumber;
  UserData.allergies = user['allergies'] ?? UserData.allergies;
  UserData.chronicConditions =
      user['chronic_conditions'] ?? UserData.chronicConditions;
  UserData.height = user['height'] ?? UserData.height;
  UserData.weight = user['weight'] ?? UserData.weight;
  UserData.medications = user['medications'] ?? UserData.medications;

  AppState.patientId = user['id'] ?? AppState.patientId;
  AppState.patientName = (user['name'] ?? AppState.patientName).toString().split(' ').first;
  AppState.phone = user['phone'] ?? AppState.phone;
}

/// Applies a doctor payload to the in-memory [DoctorState] store.
void applyDoctorUser(Map<String, dynamic> user) {
  DoctorState.doctorName = user['name'] ?? DoctorState.doctorName;
  DoctorState.specialization =
      user['specialization'] ?? DoctorState.specialization;
  DoctorState.registrationId =
      user['registration_id'] ?? DoctorState.registrationId;
  DoctorState.clinic = user['clinic'] ?? DoctorState.clinic;
  DoctorState.workingHours = user['working_hours'] ?? DoctorState.workingHours;
  DoctorState.workingDays = user['working_days'] ?? DoctorState.workingDays;
  DoctorState.isAvailable = user['is_available'] ?? DoctorState.isAvailable;
}

Future<SessionData> _storeSession(SessionData session) async {
  ApiClient.instance.token = session.token;
  AppState.token = session.token;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kPrefsToken, session.token);
  await prefs.setString(_kPrefsRole, session.role);
  await prefs.setString(_kPrefsUser, jsonEncode(session.user));
  return session;
}

Map<String, dynamic> _decodeUser(String? raw, Map<String, dynamic> fallback) {
  if (raw == null || raw.isEmpty) return fallback;
  try {
    final decoded = jsonDecode(raw);
    return (decoded as Map).cast<String, dynamic>();
  } catch (_) {
    return fallback;
  }
}

/// Restores a previously persisted session at app startup.
Future<void> restoreSession() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(_kPrefsToken);
  final role = prefs.getString(_kPrefsRole);
  final user = _decodeUser(prefs.getString(_kPrefsUser), {});
  if (token == null || role == null) return;
  ApiClient.instance.token = token;
  AppState.token = token;
  if (role == 'doctor') {
    applyDoctorUser(user);
  } else {
    applyPatientUser(user);
    // Refresh from the live backend when reachable.
    try {
      final res = await ApiClient.instance
          .get('/api/profile', query: {'patient_id': AppState.patientId});
      applyPatientUser((res as Map)['profile'] as Map<String, dynamic>);
    } catch (_) {}
  }
}

/// Returns the persisted role ('patient', 'doctor') or null if none.
Future<String?> sessionRole() async {
  final prefs = await SharedPreferences.getInstance();
  final role = prefs.getString(_kPrefsRole);
  final token = prefs.getString(_kPrefsToken);
  if (role == null || token == null || token.isEmpty) return null;
  return role;
}

// ---------------------------------------------------------------------------
// Local account auth (device-only, works without the backend)
// ---------------------------------------------------------------------------

// Demo note: accounts (including passwords) are stored in plaintext on the
// device only, so auth works fully offline. Swap in `package:crypto` hashing
// before shipping to real users.
const _kPrefsAccounts = 'local_accounts';

Future<List<Map<String, dynamic>>> _readAccounts() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefsAccounts);
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  } catch (_) {
    return [];
  }
}

Future<void> _writeAccounts(List<Map<String, dynamic>> accounts) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kPrefsAccounts, jsonEncode(accounts));
}

String _localId(String prefix) {
  final suffix = DateTime.now().microsecondsSinceEpoch.toString();
  return '$prefix-${suffix.substring(suffix.length - 6)}';
}

Map<String, dynamic> _newLocalUser({
  required String role,
  required String name,
  required String phone,
}) {
  if (role == 'doctor') {
    return {
      'id': _localId('DR'),
      'name': name,
      'medical_id': phone,
      'specialization': 'General Physician',
      'registration_id': '',
      'clinic': 'JeevanDoot Clinic',
      'working_hours': '9:00 AM \u2013 5:00 PM',
      'working_days': 'Monday to Saturday',
      'is_available': true,
    };
  }
  return {
    'id': _localId('PT'),
    'name': name,
    'phone': phone,
    'age': '30',
    'gender': 'Male',
    'blood_group': 'O+',
    'email': '',
    'address': '',
    'dob': '',
    'id_number': '',
    'language': 'hi',
    'allergies': 'None',
    'chronic_conditions': 'None',
    'height': '',
    'weight': '',
    'medications': '',
  };
}

Future<String> _startLocalSession(String role, Map<String, dynamic> user) async {
  await _storeSession(SessionData(
    token: 'local-${DateTime.now().microsecondsSinceEpoch}',
    role: role,
    user: user,
  ));
  if (role == 'doctor') {
    applyDoctorUser(user);
  } else {
    applyPatientUser(user);
  }
  return role;
}

/// Creates a new device-local account and signs in. Returns the role.
Future<String> signUpLocal({
  required String role,
  required String name,
  required String phone,
  required String password,
}) async {
  final cleanName = name.trim();
  final cleanPhone = phone.trim();
  if (cleanName.isEmpty || cleanPhone.isEmpty || password.isEmpty) {
    throw ApiException('Please fill in all the fields.');
  }
  if (password.length < 4) {
    throw ApiException('Password must be at least 4 characters long.');
  }
  final accounts = await _readAccounts();
  final exists = accounts
      .any((a) => a['role'] == role && a['phone'] == cleanPhone);
  if (exists) {
    throw ApiException(
      role == 'doctor'
          ? 'An account with this Medical ID already exists. Please login.'
          : 'An account with this mobile number already exists. Please login.',
    );
  }
  final user = _newLocalUser(role: role, name: cleanName, phone: cleanPhone);
  accounts.add({
    'role': role,
    'name': cleanName,
    'phone': cleanPhone,
    'password': password,
    'user': user,
  });
  await _writeAccounts(accounts);
  return _startLocalSession(role, user);
}

/// Signs in with a device-local account. Returns the role.
Future<String> loginLocal({
  required String role,
  required String phone,
  required String password,
}) async {
  final cleanPhone = phone.trim();
  final accounts = await _readAccounts();
  final account = accounts
      .where((a) => a['role'] == role && a['phone'] == cleanPhone)
      .firstOrNull;
  if (account == null || account['password'] != password) {
    throw ApiException(
      role == 'doctor'
          ? 'Invalid Medical ID or password.'
          : 'Invalid phone number or password.',
    );
  }
  final user = (account['user'] as Map).cast<String, dynamic>();
  return _startLocalSession(role, user);
}

// ---------------------------------------------------------------------------
// Auth API
// ---------------------------------------------------------------------------

Future<void> requestOtp(String phone) async {
  await ApiClient.instance.post('/api/auth/request-otp', {'phone': phone});
}

Future<String> verifyOtp(String phone, String otp) async {
  final res = await ApiClient.instance
      .post('/api/auth/verify-otp', {'phone': phone, 'otp': otp}) as Map;
  final user = (res['user'] as Map).cast<String, dynamic>();
  applyPatientUser(user);
  await _storeSession(SessionData(
    token: res['token'] as String,
    role: res['role'] as String,
    user: user,
  ));
  return res['role'] as String;
}

Future<String> doctorLogin(String medicalId, String password) async {
  final res = await ApiClient.instance.post('/api/auth/doctor-login', {
    'medical_id': medicalId,
    'password': password,
  }) as Map;
  final user = (res['user'] as Map).cast<String, dynamic>();
  applyDoctorUser(user);
  await _storeSession(SessionData(
    token: res['token'] as String,
    role: res['role'] as String,
    user: user,
  ));
  return res['role'] as String;
}

Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kPrefsToken);
  await prefs.remove(_kPrefsRole);
  await prefs.remove(_kPrefsUser);
  ApiClient.instance.token = null;
  AppState.token = '';
  // Reset in-memory stores so the next account starts from clean defaults.
  UserData.name = 'Ramesh Kumar';
  UserData.phone = '+91 98765 43210';
  UserData.age = '42';
  UserData.gender = 'Male';
  UserData.bloodGroup = 'O+';
  UserData.email = 'ramesh.kumar@example.com';
  UserData.address = 'Shop 12, MG Road, Pune, Maharashtra';
  UserData.dob = '12 August 1983';
  UserData.idNumber = 'XXXX-XXXX-1234';
  UserData.allergies = 'Peanuts, Penicillin';
  UserData.chronicConditions = 'Mild hypertension';
  UserData.height = '168 cm';
  UserData.weight = '74 kg';
  UserData.medications = 'Amlodipine 5 mg (daily)';
  UserData.smsAlerts = true;
  UserData.appAlerts = true;
  UserData.emailUpdates = false;
  UserData.reminderAlerts = true;
  UserData.appointmentAlerts = true;
  UserData.dataSharing = false;
  UserData.appLock = true;
  UserData.biometricLock = false;
  UserData.shareHealthReports = false;
  UserData.marketingUpdates = false;
  DoctorState.doctorName = 'Dr. Priya Sharma';
  DoctorState.specialization = 'General Physician';
  DoctorState.registrationId = 'MCI-78945612';
  DoctorState.clinic = 'JeevanDoot Clinic';
  DoctorState.workingHours = '9:00 AM \u2013 5:00 PM';
  DoctorState.workingDays = 'Monday to Saturday';
  DoctorState.isAvailable = true;
  AppState.patientName = 'Ramesh';
  AppState.patientId = 'PT-RAMESH';
  AppState.phone = '+91 98765 43210';
  AppState.selectedLanguage = 'hi';
  AppState.medicineReminderTaken = false;
}

// ---------------------------------------------------------------------------
// Health / triage API
// ---------------------------------------------------------------------------

Future<List<AdviceItem>> fetchSelfCare() async {
  final res = await ApiClient.instance.get('/api/self-care') as Map;
  final list = res['advice'] as List? ?? const [];
  return list
      .map((e) => AdviceItem.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

// ---------------------------------------------------------------------------
// Appointments API
// ---------------------------------------------------------------------------

Future<List<SlotDate>> fetchSlotDates() async {
  final res = await ApiClient.instance.get('/api/appointments/slots') as Map;
  return (res['dates'] as List? ?? const [])
      .map((e) => SlotDate.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

Future<List<SlotTime>> fetchSlotTimes() async {
  final res = await ApiClient.instance.get('/api/appointments/slots') as Map;
  return (res['slots'] as List? ?? const [])
      .map((e) => SlotTime.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

Future<BookedAppointment> bookAppointment({
  required String consultType,
  required String dateId,
  required String time,
}) async {
  final res = await ApiClient.instance.post('/api/appointments', {
    'patient_id': AppState.patientId,
    'consult_type': consultType,
    'date_id': dateId,
    'time': time,
  }) as Map;
  return BookedAppointment.fromJson(
    (res['appointment'] as Map).cast<String, dynamic>(),
  );
}

// ---------------------------------------------------------------------------
// Doctor API
// ---------------------------------------------------------------------------

Future<List<DoctorPatient>> fetchDoctorPatients() async {
  final res = await ApiClient.instance.get('/api/doctor/patients') as Map;
  return (res['patients'] as List? ?? const [])
      .map((e) => DoctorPatient.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

Future<PatientCase> fetchPatientCase(String patientId) async {
  final res = await ApiClient.instance
      .get('/api/doctor/patients/$patientId') as Map;
  return PatientCase.fromJson((res['case'] as Map).cast<String, dynamic>());
}

Future<List<DoctorAppointment>> fetchDoctorAppointments() async {
  final res = await ApiClient.instance.get('/api/doctor/appointments') as Map;
  return (res['appointments'] as List? ?? const [])
      .map((e) =>
          DoctorAppointment.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

Future<DoctorStats> fetchDoctorStats() async {
  final res = await ApiClient.instance.get('/api/doctor/stats') as Map;
  return DoctorStats.fromJson((res['stats'] as Map).cast<String, dynamic>());
}

Future<DoctorPatient?> fetchUrgentCase() async {
  final res = await ApiClient.instance.get('/api/doctor/stats') as Map;
  final raw = res['urgent_case'];
  if (raw == null) return null;
  return DoctorPatient.fromJson((raw as Map).cast<String, dynamic>());
}

Future<List<String>> searchMedicines(String query) async {
  final res = await ApiClient.instance.get('/api/doctor/medicines',
      query: {'q': query}) as Map;
  return (res['medicines'] as List? ?? const []).cast<String>();
}

// ---------------------------------------------------------------------------
// Prescriptions API
// ---------------------------------------------------------------------------

Future<List<Prescription>> fetchPrescriptions() async {
  final res = await ApiClient.instance.get('/api/prescriptions',
      query: {'patient_id': AppState.patientId}) as Map;
  return (res['prescriptions'] as List? ?? const [])
      .map((e) => Prescription.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

Future<Prescription> createPrescription({
  required String patientId,
  required List<PrescriptionItem> medicines,
  String notes = '',
}) async {
  final res = await ApiClient.instance.post('/api/prescriptions', {
    'patient_id': patientId,
    'doctor_name': DoctorState.doctorName,
    'notes': notes,
    'medicines': medicines.map((m) => m.toJson()).toList(),
  }) as Map;
  return Prescription.fromJson(
    (res['prescription'] as Map).cast<String, dynamic>(),
  );
}

// ---------------------------------------------------------------------------
// Profile / records / reminders API
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> fetchProfile() async {
  final res = await ApiClient.instance
      .get('/api/profile', query: {'patient_id': AppState.patientId}) as Map;
  final profile = (res['profile'] as Map).cast<String, dynamic>();
  applyPatientUser(profile);
  return profile;
}

Future<void> updateProfile(Map<String, dynamic> updates) async {
  await ApiClient.instance.put('/api/profile',
      {'patient_id': AppState.patientId, ...updates});
}

Future<List<RecordEvent>> fetchRecords() async {
  final res = await ApiClient.instance
      .get('/api/records', query: {'patient_id': AppState.patientId}) as Map;
  return (res['records'] as List? ?? const [])
      .map((e) => RecordEvent.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

Future<List<ReminderItem>> fetchReminders() async {
  final res = await ApiClient.instance
      .get('/api/reminders', query: {'patient_id': AppState.patientId}) as Map;
  return (res['reminders'] as List? ?? const [])
      .map((e) => ReminderItem.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

Future<void> markReminderDone(String reminderId, {bool done = true}) async {
  await ApiClient.instance
      .post('/api/reminders/$reminderId/done', {'done': done});
}

// ---------------------------------------------------------------------------
// Misc helpers
// ---------------------------------------------------------------------------

/// Debounced medicine search used by the prescription builder.
Future<List<String>> medicineSearch(String query) async {
  final q = query.trim();
  if (q.isEmpty) return const [];
  return searchMedicines(q);
}
