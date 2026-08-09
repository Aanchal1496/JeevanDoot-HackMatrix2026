import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/case_file_models.dart';
import '../models/consultation_models.dart';
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
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    required this.symptoms,
    required this.symptomDuration,
    required this.symptomSeverity,
    required this.symptomOnset,
    required this.vitals,
    required this.history,
    required this.aiSummary,
    required this.status,
    required this.waitMinutes,
    required this.aiRiskScore,
    required this.aiTriageLevel,
    required this.aiTriageReason,
    required this.finalTriageLevel,
    required this.triageSource,
    required this.triageReason,
    required this.doctorOverrideReason,
    required this.safetyEscalated,
    required this.criticalSymptoms,
    required this.triageHistory,
  });

  final String id;
  final String patientId;
  final String name;
  final String age;
  final String gender;
  final String bloodGroup;
  final List<String> symptoms;
  final String symptomDuration;
  final String symptomSeverity;
  final String symptomOnset;
  final Map<String, String> vitals;
  final Map<String, List<String>> history;
  final String aiSummary;
  final QueueStatus status;
  final int waitMinutes;
  final int aiRiskScore;
  final TriageBand aiTriageLevel;
  final String? aiTriageReason;
  final TriageBand finalTriageLevel;
  final TriageSource triageSource;
  final String? triageReason;
  final String? doctorOverrideReason;
  final bool safetyEscalated;
  final List<String> criticalSymptoms;
  final List<TriageHistoryEntry> triageHistory;

  factory PatientCase.fromJson(Map<String, dynamic> json) => PatientCase(
        id: json['id'] as String? ?? '',
        patientId: json['patient_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        age: (json['age'] ?? '').toString(),
        gender: json['gender'] as String? ?? '',
        bloodGroup: json['blood_group'] as String? ?? '',
        symptoms: (json['symptoms'] as List?)?.cast<String>() ?? const [],
        symptomDuration: json['symptom_duration'] as String? ?? '',
        symptomSeverity: json['symptom_severity'] as String? ?? '',
        symptomOnset: json['symptom_onset'] as String? ?? '',
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
        status: QueueStatus.fromApi(json['status'] as String?),
        waitMinutes: (json['wait_minutes'] as num?)?.toInt() ?? 0,
        aiRiskScore: (json['ai_risk_score'] as num?)?.toInt() ?? 0,
        aiTriageLevel: TriageBand.fromApi(json['ai_triage_level'] as String?),
        aiTriageReason: json['ai_triage_reason'] as String?,
        finalTriageLevel:
            TriageBand.fromApi(json['final_triage_level'] as String?),
        triageSource: TriageSource.fromApi(json['triage_source'] as String?),
        triageReason: json['triage_reason'] as String?,
        doctorOverrideReason: json['doctor_override_reason'] as String?,
        safetyEscalated: json['safety_escalated'] == true ||
            json['safety_escalated'] == 1,
        criticalSymptoms:
            (json['critical_symptoms'] as List?)?.cast<String>() ?? const [],
        triageHistory: (json['triage_history'] as List? ?? const [])
            .map((e) => TriageHistoryEntry.fromJson(
                (e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// One medicine from the structured catalog (backend `medicines` table).
class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    required this.genericName,
    required this.brandName,
    required this.strength,
    required this.dosageForm,
    required this.route,
    required this.category,
    required this.active,
    required this.quickSelect,
  });

  final String id;
  final String name;
  final String genericName;
  final String brandName;
  final String strength;
  final String dosageForm;
  final String route;
  final String category;
  final bool active;
  final bool quickSelect;

  /// Display label, e.g. "Paracetamol 500 mg".
  String get display => strength.isNotEmpty ? '$name $strength' : name;

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        genericName: json['generic_name'] as String? ?? '',
        brandName: json['brand_name'] as String? ?? '',
        strength: json['strength'] as String? ?? '',
        dosageForm: json['dosage_form'] as String? ?? '',
        route: json['route'] as String? ?? '',
        category: json['category'] as String? ?? '',
        active: json['active'] == true || json['active'] == 1,
        quickSelect: json['quick_select'] == true || json['quick_select'] == 1,
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
    this.id,
    this.medicineId,
    this.genericName = '',
    this.strength = '',
    this.dosageForm = '',
    this.dose = '',
    this.frequency = '',
    this.duration,
    this.durationUnit = 'days',
    this.route = '',
    this.timing = '',
    this.displayOrder = 0,
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
  final int? id;
  final String? medicineId;
  final String genericName;
  final String strength;
  final String dosageForm;
  final String dose;
  final String frequency;
  final String? duration;
  final String durationUnit;
  final String route;
  final String timing;
  final int displayOrder;

  /// Plain-language dose line: "1 tablet twice daily after food for 3 days".
  String get doseLine {
    final parts = <String>[
      if (dose.isNotEmpty) dose,
      if (frequency.isNotEmpty) frequency.toLowerCase(),
      if (timing.isNotEmpty) timing.toLowerCase(),
      if (duration != null && duration!.isNotEmpty)
        'for $duration $durationUnit',
    ];
    return parts.join(' ');
  }

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) =>
      PrescriptionItem(
        id: int.tryParse(json['id']?.toString() ?? ''),
        medicineId: json['medicine_id']?.toString(),
        name: json['name'] as String? ?? '',
        genericName: json['generic_name'] as String? ?? '',
        strength: json['strength'] as String? ?? '',
        dosageForm: json['dosage_form'] as String? ?? '',
        dose: json['dose'] as String? ?? '',
        frequency: json['frequency'] as String? ?? '',
        duration: json['duration']?.toString(),
        durationUnit: json['duration_unit'] as String? ?? 'days',
        route: json['route'] as String? ?? '',
        timing: json['timing'] as String? ?? '',
        instructions: json['instructions'] as String? ?? '',
        displayOrder: int.tryParse(json['display_order']?.toString() ?? '') ?? 0,
        category: json['category'] as String? ?? 'Tablet',
        dosage: (json['dosage'] ?? '').toString(),
        unit: json['unit'] as String? ?? 'mg',
        morning: int.tryParse(json['morning']?.toString() ?? '') ?? 0,
        afternoon: int.tryParse(json['afternoon']?.toString() ?? '') ?? 0,
        night: int.tryParse(json['night']?.toString() ?? '') ?? 0,
        days: int.tryParse(json['days']?.toString() ?? '') ?? 0,
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

/// Prescription lifecycle status.
enum PrescriptionStatus {
  draft('DRAFT', 'Draft'),
  issued('ISSUED', 'Issued'),
  cancelled('CANCELLED', 'Cancelled');

  const PrescriptionStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PrescriptionStatus fromApi(String? value) => values.firstWhere(
        (s) => s.apiValue == (value ?? '').toUpperCase(),
        orElse: () => PrescriptionStatus.draft,
      );
}

class Prescription {
  const Prescription({
    required this.id,
    required this.doctorName,
    required this.date,
    required this.dateIso,
    required this.followUpDate,
    required this.followUpTime,
    required this.notes,
    required this.medicines,
    this.patientId = '',
    this.doctorId,
    this.consultationId,
    this.status = PrescriptionStatus.draft,
    this.issuedAt,
    this.createdAt,
    this.updatedAt,
    this.additionalInstructions = '',
  });

  final String id;
  final String doctorName;
  final String date;
  final String dateIso;
  final String followUpDate;
  final String followUpTime;
  final String notes;
  final List<PrescriptionItem> medicines;
  final String patientId;
  final String? doctorId;
  final String? consultationId;
  final PrescriptionStatus status;
  final String? issuedAt;
  final String? createdAt;
  final String? updatedAt;
  final String additionalInstructions;

  bool get isDraft => status == PrescriptionStatus.draft;
  bool get isIssued => status == PrescriptionStatus.issued;

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
        id: json['id']?.toString() ?? '',
        patientId: json['patient_id'] as String? ?? '',
        doctorId: json['doctor_id']?.toString(),
        doctorName: json['doctor_name'] as String? ?? '',
        consultationId: json['consultation_id']?.toString(),
        date: json['date'] as String? ?? '',
        dateIso: json['date_iso'] as String? ?? '',
        followUpDate: json['follow_up_date'] as String? ?? '',
        followUpTime: json['follow_up_time'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        status: PrescriptionStatus.fromApi(json['status'] as String?),
        issuedAt: json['issued_at']?.toString(),
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
        additionalInstructions:
            json['additional_instructions'] as String? ?? '',
        medicines: (json['medicines'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => PrescriptionItem.fromJson(e.cast<String, dynamic>()))
            .toList(),
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
// Medicine + follow-up reminder models
// ---------------------------------------------------------------------------

/// A single scheduled dose of a medicine reminder.
class MedicineDose {
  const MedicineDose({
    required this.id,
    required this.reminderId,
    required this.scheduledTime,
    required this.status,
    this.takenAt,
  });

  final String id;
  final String reminderId;
  final String scheduledTime;
  final String status; // upcoming | due | taken | skipped | missed
  final String? takenAt;

  factory MedicineDose.fromJson(Map<String, dynamic> json) => MedicineDose(
        id: json['id'] as String? ?? '',
        reminderId: json['reminder_id'] as String? ?? '',
        scheduledTime: json['scheduled_time'] as String? ?? '',
        status: json['status'] as String? ?? 'upcoming',
        takenAt: json['taken_at'] as String?,
      );
}

/// A medicine reminder created from a prescription item.
class MedicineReminderModel {
  const MedicineReminderModel({
    required this.id,
    required this.patientId,
    required this.medicineName,
    this.prescriptionId,
    this.medicineId,
    this.category = 'Tablet',
    this.dosage = '',
    this.unit = 'mg',
    this.quantity = 1,
    this.period = 'morning',
    this.mealInstruction = 'After food',
    this.time = '08:00',
    this.startDate,
    this.endDate,
    this.durationDays = 5,
    this.voiceEnabled = false,
    this.language = 'hi',
    this.status = 'active',
    this.doses = const [],
  });

  final String id;
  final String patientId;
  final String medicineName;
  final String? prescriptionId;
  final String? medicineId;
  final String category;
  final String dosage;
  final String unit;
  final int quantity;
  final String period;
  final String mealInstruction;
  final String time;
  final String? startDate;
  final String? endDate;
  final int durationDays;
  final bool voiceEnabled;
  final String language;
  final String status;
  final List<MedicineDose> doses;

  /// Returns the next dose yet to be taken (upcoming/due), if any.
  MedicineDose? get nextDose {
    for (final d in doses) {
      if (d.status == 'upcoming' || d.status == 'due') return d;
    }
    return null;
  }

  /// Whether any dose was taken today (used for the timeline "done" state).
  bool get anyTaken => doses.any((d) => d.status == 'taken');

  factory MedicineReminderModel.fromJson(Map<String, dynamic> json) =>
      MedicineReminderModel(
        id: json['id'] as String? ?? '',
        patientId: json['patient_id'] as String? ?? '',
        medicineName: json['medicine_name'] as String? ?? '',
        prescriptionId: json['prescription_id'] as String?,
        medicineId: json['medicine_id'] as String?,
        category: json['category'] as String? ?? 'Tablet',
        dosage: json['dosage'] as String? ?? '',
        unit: json['unit'] as String? ?? 'mg',
        quantity: json['quantity'] as int? ?? 1,
        period: json['period'] as String? ?? 'morning',
        mealInstruction: json['meal_instruction'] as String? ?? 'After food',
        time: json['time'] as String? ?? '08:00',
        startDate: json['start_date'] as String?,
        endDate: json['end_date'] as String?,
        durationDays: json['duration_days'] as int? ?? 5,
        voiceEnabled: (json['voice_enabled'] as int? ?? 0) == 1,
        language: json['language'] as String? ?? 'hi',
        status: json['status'] as String? ?? 'active',
        doses: (json['doses'] as List? ?? const [])
            .map((e) =>
                MedicineDose.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// A follow-up visit reminder.
class FollowUpReminderModel {
  const FollowUpReminderModel({
    required this.id,
    required this.patientId,
    required this.followupDate,
    this.prescriptionId,
    this.doctorName = 'Dr. Priya Sharma',
    this.followupTime = '10:00',
    this.reason = 'Follow-up consultation',
    this.voiceEnabled = false,
    this.language = 'hi',
    this.enabled = true,
  });

  final String id;
  final String patientId;
  final String? prescriptionId;
  final String doctorName;
  final String followupDate;
  final String followupTime;
  final String reason;
  final bool voiceEnabled;
  final String language;
  final bool enabled;

  factory FollowUpReminderModel.fromJson(Map<String, dynamic> json) =>
      FollowUpReminderModel(
        id: json['id'] as String? ?? '',
        patientId: json['patient_id'] as String? ?? '',
        prescriptionId: json['prescription_id'] as String?,
        doctorName: json['doctor_name'] as String? ?? 'Dr. Priya Sharma',
        followupDate: json['followup_date'] as String? ?? '',
        followupTime: json['followup_time'] as String? ?? '10:00',
        reason: json['reason'] as String? ?? 'Follow-up consultation',
        voiceEnabled: (json['voice_enabled'] as int? ?? 0) == 1,
        language: json['language'] as String? ?? 'hi',
        enabled: (json['enabled'] as int? ?? 1) == 1,
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

/// Fetches the backend risk-sorted queue (waiting + consulting + summary).
Future<QueueData> fetchDoctorQueue() async {
  final res = await ApiClient.instance.get('/api/doctor/queue') as Map;
  return QueueData.fromJson(res.cast<String, dynamic>());
}

/// Applies a doctor's triage override and returns the updated patient.
Future<DoctorPatient> overridePatientTriage({
  required String patientId,
  required TriageBand level,
  required String reason,
}) async {
  final res = await ApiClient.instance
      .post('/api/doctor/patients/$patientId/triage/override', {
    'triage_level': level.apiValue,
    'reason': reason,
    'changed_by': DoctorState.doctorName,
  }) as Map;
  return DoctorPatient.fromJson(
      (res['patient'] as Map).cast<String, dynamic>());
}

/// Moves a waiting patient into an active consultation.
Future<DoctorPatient> startPatientConsultation(String patientId) async {
  final res = await ApiClient.instance
      .post('/api/doctor/patients/$patientId/consultation/start', {}) as Map;
  return DoctorPatient.fromJson(
      (res['patient'] as Map).cast<String, dynamic>());
}

/// Marks an active consultation as completed.
Future<DoctorPatient> completePatientConsultation(String patientId) async {
  final res = await ApiClient.instance
      .post('/api/doctor/patients/$patientId/consultation/complete', {}) as Map;
  return DoctorPatient.fromJson(
      (res['patient'] as Map).cast<String, dynamic>());
}

Future<PatientCase> fetchPatientCase(String patientId) async {
  final res = await ApiClient.instance
      .get('/api/doctor/patients/$patientId') as Map;
  return PatientCase.fromJson((res['case'] as Map).cast<String, dynamic>());
}

/// Fetches the aggregated pre-consultation case file (single request).
Future<CaseFile> fetchCaseFile(String patientId) async {
  final res = await ApiClient.instance
      .get('/api/doctor/patients/$patientId/case-file') as Map;
  return CaseFile.fromJson(
      (res['case_file'] as Map).cast<String, dynamic>());
}

/// Regenerates the case file from the latest patient data.
Future<CaseFile> generateCaseFile(String patientId) async {
  final res = await ApiClient.instance
      .post('/api/doctor/patients/$patientId/case-file/generate', {}) as Map;
  return CaseFile.fromJson(
      (res['case_file'] as Map).cast<String, dynamic>());
}

/// Applies the doctor's edited summary; the original AI content is preserved
/// server-side and returned alongside.
Future<CaseFile> updateCaseFileSummary({
  required String patientId,
  required String doctorSummary,
}) async {
  final res = await ApiClient.instance.patch(
    '/api/doctor/patients/$patientId/case-file/summary',
    {'doctor_summary': doctorSummary},
  ) as Map;
  return CaseFile.fromJson(
      (res['case_file'] as Map).cast<String, dynamic>());
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

/// Structured medicine search (generic name, brand, category, strength).
Future<List<Medicine>> searchMedicines(String query) async {
  final res = await ApiClient.instance.get('/api/doctor/medicines',
      query: {'q': query}) as Map;
  return (res['medicines'] as List? ?? const [])
      .map((e) => Medicine.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

/// Configurable common-medicine quick-select set from the backend.
Future<List<Medicine>> fetchCommonMedicines() async {
  final res = await ApiClient.instance
      .get('/api/doctor/medicines/common') as Map;
  return (res['medicines'] as List? ?? const [])
      .map((e) => Medicine.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

/// Creates (or reopens) the patient's prescription draft.
Future<Prescription> createPrescriptionDraft({
  required String patientId,
  String? consultationId,
}) async {
  final res = await ApiClient.instance.post('/api/doctor/prescriptions', {
    'patient_id': patientId,
    'consultation_id': ?consultationId,
  }) as Map;
  return Prescription.fromJson(
      (res['prescription'] as Map).cast<String, dynamic>());
}

/// Recovers the patient's unfinished draft (draft recovery).
Future<Prescription?> fetchPrescriptionDraft(String patientId) async {
  try {
    final res = await ApiClient.instance.get('/api/doctor/prescriptions/drafts',
        query: {'patient_id': patientId}) as Map;
    return Prescription.fromJson(
        (res['prescription'] as Map).cast<String, dynamic>());
  } on ApiException catch (e) {
    if (e.statusCode == 404) return null;
    rethrow;
  }
}

/// Issued prescription history for a patient (doctor view).
Future<List<Prescription>> fetchPrescriptionHistory(String patientId) async {
  final res = await ApiClient.instance.get('/api/doctor/prescriptions/history',
      query: {'patient_id': patientId}) as Map;
  return (res['prescriptions'] as List? ?? const [])
      .map((e) => Prescription.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

/// Adds a configured medicine to the draft; returns the prescription and any
/// safety warnings (allergy / duplicate / interaction-unavailable).
Future<({Prescription prescription, List<dynamic> warnings})>
    addPrescriptionItem({
  required String prescriptionId,
  required String medicineId,
  required String dose,
  required String frequency,
  String? duration,
  String durationUnit = 'days',
  required String route,
  String? strength,
  String? dosageForm,
  String? timing,
  String? instructions,
  String? genericName,
}) async {
  final res = await ApiClient.instance
      .post('/api/doctor/prescriptions/$prescriptionId/items', {
    'medicine_id': medicineId,
    'dose': dose,
    'frequency': frequency,
    'duration': duration,
    'duration_unit': durationUnit,
    'route': route,
    'strength': strength,
    'dosage_form': dosageForm,
    'timing': timing,
    'instructions': instructions,
    'generic_name': genericName,
  }) as Map;
  return (
    prescription: Prescription.fromJson(
        (res['prescription'] as Map).cast<String, dynamic>()),
    warnings: res['safety']?['warnings'] as List? ?? const [],
  );
}

/// Updates an item on the draft.
Future<Prescription> updatePrescriptionItem({
  required String prescriptionId,
  required int itemId,
  Map<String, dynamic> fields = const {},
}) async {
  final res = await ApiClient.instance.patch(
    '/api/doctor/prescriptions/$prescriptionId/items/$itemId',
    fields,
  ) as Map;
  return Prescription.fromJson(
      (res['prescription'] as Map).cast<String, dynamic>());
}

/// Removes an item from the draft.
Future<Prescription> removePrescriptionItem({
  required String prescriptionId,
  required int itemId,
}) async {
  final res = await ApiClient.instance
      .delete('/api/doctor/prescriptions/$prescriptionId/items/$itemId') as Map;
  return Prescription.fromJson(
      (res['prescription'] as Map).cast<String, dynamic>());
}

/// Autosaves the additional instructions (never issues anything).
Future<Prescription> savePrescriptionNotes({
  required String prescriptionId,
  required String additionalInstructions,
}) async {
  final res = await ApiClient.instance.patch(
    '/api/doctor/prescriptions/$prescriptionId/notes',
    {'additional_instructions': additionalInstructions},
  ) as Map;
  return Prescription.fromJson(
      (res['prescription'] as Map).cast<String, dynamic>());
}

/// Issues the prescription (server revalidates everything).
Future<Prescription> issuePrescription(String prescriptionId) async {
  final res = await ApiClient.instance
      .post('/api/doctor/prescriptions/$prescriptionId/issue', {}) as Map;
  return Prescription.fromJson(
      (res['prescription'] as Map).cast<String, dynamic>());
}

/// Cancels a prescription (draft or issued) - the original record is
/// preserved and the action is audited server-side.
Future<Prescription> cancelPrescription(
  String prescriptionId, {
  required String reason,
}) async {
  final res = await ApiClient.instance.post(
    '/api/doctor/prescriptions/$prescriptionId/cancel',
    {'reason': reason},
  ) as Map;
  return Prescription.fromJson(
      (res['prescription'] as Map).cast<String, dynamic>());
}

/// Downloads the issued prescription PDF as bytes (authenticated).
Future<List<int>> downloadPrescriptionPdf(String prescriptionId) async {
  return ApiClient.instance
      .download('/api/doctor/prescriptions/$prescriptionId/pdf');
}

// ---------------------------------------------------------------------------
// Local draft persistence (offline recovery - never issues anything)
// ---------------------------------------------------------------------------

/// Local draft storage is scoped per doctor + patient so a shared clinic
/// device never exposes one doctor's draft to another user (spec: "Ensure
/// local draft recovery does not expose prescription data to other users of
/// the device"). The local copy is only an offline fallback - the server
/// remains the source of truth and only the server can ISSUE.
String _draftKey(String patientId) =>
    'rx_draft_${DoctorState.doctorName}_$patientId';

/// Stores the working draft JSON on this device only, keyed per patient.
Future<void> saveLocalDraft(String patientId, Map<String, dynamic> json) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_draftKey(patientId), jsonEncode(json));
}

/// Loads the locally-preserved draft, if any.
Future<Prescription?> loadLocalDraft(String patientId) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_draftKey(patientId));
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    return Prescription.fromJson((decoded as Map).cast<String, dynamic>());
  } catch (_) {
    return null;
  }
}

/// Clears the local draft once it has been issued or discarded.
Future<void> clearLocalDraft(String patientId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_draftKey(patientId));
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
// Teleconsultations API
// ---------------------------------------------------------------------------

Future<List<ConsultationSpecialty>> fetchConsultationSpecialties() async {
  final res = await ApiClient.instance.get('/api/consultations/specialties') as Map;
  return (res['specialties'] as List? ?? const [])
      .map((e) =>
          ConsultationSpecialty.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

Future<List<DoctorInfo>> fetchConsultationDoctors({
  String specialty = '',
  String query = '',
}) async {
  final res = await ApiClient.instance.get('/api/consultations/doctors',
      query: {
        if (specialty.isNotEmpty) 'specialty': specialty,
        if (query.trim().isNotEmpty) 'q': query.trim(),
      }) as Map;
  return (res['doctors'] as List? ?? const [])
      .map((e) => DoctorInfo.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

Future<List<SlotDateInfo>> fetchDoctorDates(String doctorId) async {
  final res = await ApiClient.instance
      .get('/api/consultations/doctors/$doctorId/dates') as Map;
  return (res['dates'] as List? ?? const [])
      .map((e) => SlotDateInfo.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

Future<DoctorSlots> fetchDoctorSlots(String doctorId, String date) async {
  final res = await ApiClient.instance
      .get('/api/consultations/doctors/$doctorId/slots', query: {'date': date}) as Map;
  return DoctorSlots.fromJson(res.cast<String, dynamic>());
}

Future<ConsultationAppointment> bookConsultation({
  required String doctorId,
  required String date,
  required String startTime,
  required ConsultKind consultKind,
  String reason = '',
  List<ConsultationAttachment> attachments = const [],
  String bookingSource = 'SELF',
  String? ashaRequestId,
  String? patientName,
  String? patientPhone,
}) async {
  final res = await ApiClient.instance.post('/api/consultations/book', {
    'patient_id': AppState.patientId,
    'doctor_id': doctorId,
    'date': date,
    'start_time': startTime,
    'consult_type': consultKind.apiValue,
    'reason': reason,
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'booking_source': bookingSource,
    'asha_request_id': ?ashaRequestId,
    'patient_name': ?patientName,
    'patient_phone': ?patientPhone,
  }) as Map;
  return ConsultationAppointment.fromJson(
    (res['appointment'] as Map).cast<String, dynamic>(),
  );
}

Future<List<ConsultationAppointment>> fetchUpcomingConsultations() async {
  final res = await ApiClient.instance.get('/api/consultations/upcoming',
      query: {'patient_id': AppState.patientId}) as Map;
  return (res['appointments'] as List? ?? const [])
      .map((e) =>
          ConsultationAppointment.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

Future<List<ConsultationAppointment>> fetchConsultationHistory() async {
  final res = await ApiClient.instance.get('/api/consultations/history',
      query: {'patient_id': AppState.patientId}) as Map;
  return (res['appointments'] as List? ?? const [])
      .map((e) =>
          ConsultationAppointment.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

Future<ConsultationAppointment> fetchConsultationAppointment(String id) async {
  final res = await ApiClient.instance.get('/api/consultations/$id',
      query: {'patient_id': AppState.patientId}) as Map;
  return ConsultationAppointment.fromJson(
    (res['appointment'] as Map).cast<String, dynamic>(),
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
// Medicine + follow-up reminder API
// ---------------------------------------------------------------------------

Map<String, String> _patientQuery([String? pid]) => {
      'patient_id': pid ?? AppState.patientId,
    };

/// Creates a medicine reminder (and its scheduled doses) from a prescription.
Future<MedicineReminderModel> createMedicineReminder({
  required String medicineName,
  String? prescriptionId,
  String? medicineId,
  String category = 'Tablet',
  String dosage = '',
  String unit = 'mg',
  int quantity = 1,
  String period = 'morning',
  String mealInstruction = 'After food',
  String time = '08:00',
  int durationDays = 5,
  bool voiceEnabled = false,
}) async {
  final res = await ApiClient.instance
      .post('/api/reminders/medicines', {
        'patient_id': AppState.patientId,
        'prescription_id': prescriptionId,
        'medicine_id': medicineId,
        'medicine_name': medicineName,
        'category': category,
        'dosage': dosage,
        'unit': unit,
        'quantity': quantity,
        'period': period,
        'meal_instruction': mealInstruction,
        'time': time,
        'duration_days': durationDays,
        'voice_enabled': voiceEnabled,
        'language': AppState.selectedLanguage,
      })
      as Map;
  return MedicineReminderModel.fromJson(
      (res['reminder'] as Map).cast<String, dynamic>());
}

Future<List<MedicineReminderModel>> fetchMedicineReminders() async {
  final res = await ApiClient.instance
      .get('/api/reminders/medicines', query: _patientQuery()) as Map;
  return (res['reminders'] as List? ?? const [])
      .map((e) =>
          MedicineReminderModel.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
}

Future<void> updateMedicineReminder(String reminderId,
    {bool? voiceEnabled, String? status, String? language}) async {
  await ApiClient.instance.put(
      '/api/reminders/medicines/$reminderId',
      {
        'patient_id': AppState.patientId,
        'voice_enabled': ?voiceEnabled,
        'status': ?status,
        'language': ?language,
      });
}

Future<void> deleteMedicineReminder(String reminderId) async {
  await ApiClient.instance.delete(
      '/api/reminders/medicines/$reminderId',
      query: _patientQuery());
}

Future<void> markDoseTaken(String reminderId, {String? takenAt}) async {
  await ApiClient.instance.post(
      '/api/reminders/medicines/$reminderId/taken',
      {
        'patient_id': AppState.patientId,
        'taken_at': ?takenAt,
      });
}

Future<void> markDoseSkipped(String reminderId) async {
  await ApiClient.instance.post(
      '/api/reminders/medicines/$reminderId/skip',
      _patientQuery());
}

Future<FollowUpReminderModel> createFollowUpReminder({
  required String followupDate,
  String? prescriptionId,
  String doctorName = 'Dr. Priya Sharma',
  String followupTime = '10:00',
  String reason = 'Follow-up consultation',
}) async {
  final res = await ApiClient.instance
      .post('/api/reminders/followups', {
        'patient_id': AppState.patientId,
        'prescription_id': prescriptionId,
        'doctor_name': doctorName,
        'followup_date': followupDate,
        'followup_time': followupTime,
        'reason': reason,
        'language': AppState.selectedLanguage,
      })
      as Map;
  return FollowUpReminderModel.fromJson(
      (res['followup'] as Map).cast<String, dynamic>());
}

Future<List<FollowUpReminderModel>> fetchFollowUpReminders() async {
  final res = await ApiClient.instance
      .get('/api/reminders/followups', query: _patientQuery()) as Map;
  return (res['followups'] as List? ?? const [])
      .map((e) => FollowUpReminderModel.fromJson(
          (e as Map).cast<String, dynamic>()))
      .toList();
}

Future<void> updateFollowUpReminder(String id,
    {bool? voiceEnabled, bool? enabled, String? language}) async {
  await ApiClient.instance.put(
      '/api/reminders/followups/$id',
      {
        'patient_id': AppState.patientId,
        'voice_enabled': ?voiceEnabled,
        'enabled': ?enabled,
        'language': ?language,
      });
}

Future<void> deleteFollowUpReminder(String id) async {
  await ApiClient.instance.delete(
      '/api/reminders/followups/$id',
      query: _patientQuery());
}

// ---------------------------------------------------------------------------
// Misc helpers
// ---------------------------------------------------------------------------

/// Medicine search used by the prescription writer (structured results).
Future<List<Medicine>> medicineSearch(String query) async {
  final q = query.trim();
  if (q.isEmpty) return const [];
  return searchMedicines(q);
}
