import 'package:flutter/material.dart';

enum DoctorRiskLevel { low, medium, high, urgent }

class DoctorRisk {
  const DoctorRisk(this.level, this.label);

  final DoctorRiskLevel level;
  final String label;

  Color get color {
    switch (level) {
      case DoctorRiskLevel.low:
        return const Color(0xFF10B981);
      case DoctorRiskLevel.medium:
        return const Color(0xFFF59E0B);
      case DoctorRiskLevel.high:
      case DoctorRiskLevel.urgent:
        return const Color(0xFFEF4444);
    }
  }
}

/// A patient in the doctor's queue / case view.
class DoctorPatient {
  const DoctorPatient({
    required this.name,
    required this.id,
    required this.age,
    required this.gender,
    required this.risk,
    required this.symptoms,
    required this.waitTime,
    this.startTime,
    this.consultType = 'Video Consultation',
  });

  final String name;
  final String id;
  final String age;
  final String gender;
  final DoctorRisk risk;
  final List<String> symptoms;
  final String waitTime;
  final String? startTime;
  final String consultType;

  factory DoctorPatient.fromJson(Map<String, dynamic> json) {
    return DoctorPatient(
      name: json['name'] as String? ?? 'Patient',
      id: json['id'] as String? ?? 'PT-0000',
      age: (json['age'] ?? '').toString(),
      gender: json['gender'] as String? ?? 'Male',
      risk: DoctorRisk(
        DoctorRiskLevel.values.firstWhere(
          (l) => l.name == json['risk'],
          orElse: () => DoctorRiskLevel.medium,
        ),
        json['risk_label'] as String? ??
            (json['risk'] as String? ?? 'Medium'),
      ),
      symptoms: (json['symptoms'] as List?)?.cast<String>() ??
          <String>[],
      waitTime: json['wait_time'] as String? ?? '00 MIN WAIT',
      startTime: json['start_time'] as String?,
      consultType:
          json['consult_type'] as String? ?? 'Video Consultation',
    );
  }
}

const List<DoctorPatient> kDoctorPatients = [
  DoctorPatient(
    name: 'Rahul Kumar',
    id: 'PT-9942',
    age: '54',
    gender: 'Male',
    risk: DoctorRisk(DoctorRiskLevel.high, 'High Risk'),
    symptoms: ['Fever', 'Breathing difficulty', 'Chest discomfort'],
    waitTime: '04 MIN WAIT',
  ),
  DoctorPatient(
    name: 'Priya Sharma',
    id: 'PT-88231',
    age: '45',
    gender: 'Male',
    risk: DoctorRisk(DoctorRiskLevel.high, 'High Risk'),
    symptoms: ['Severe abdominal pain'],
    waitTime: '12 MIN WAIT',
  ),
  DoctorPatient(
    name: 'Amit Patel',
    id: 'PT-7731',
    age: '45',
    gender: 'Male',
    risk: DoctorRisk(DoctorRiskLevel.medium, 'Medium'),
    symptoms: ['Persistent cough', 'fatigue'],
    waitTime: '25 MIN WAIT',
  ),
  DoctorPatient(
    name: 'Sunita Rao',
    id: 'PT-8492',
    age: '28',
    gender: 'Female',
    risk: DoctorRisk(DoctorRiskLevel.low, 'Low'),
    symptoms: ['Routine checkup', 'mild rash'],
    waitTime: '45 MIN WAIT',
  ),
];

/// Appointments for the doctor's schedule screen.
class DoctorAppointment {
  const DoctorAppointment({
    required this.name,
    required this.id,
    required this.time,
    required this.status,
    required this.risk,
    required this.consultType,
    this.startTime,
  });

  final String name;
  final String id;
  final String time;
  final String status;
  final DoctorRisk risk;
  final String consultType;
  final String? startTime;

  factory DoctorAppointment.fromJson(Map<String, dynamic> json) {
    return DoctorAppointment(
      name: json['name'] as String? ?? 'Patient',
      id: json['id'] as String? ?? 'APT-0000',
      time: json['time'] as String? ?? '--:--',
      status: json['status'] as String? ?? 'Upcoming',
      risk: DoctorRisk(
        DoctorRiskLevel.values.firstWhere(
          (l) => l.name == json['risk'],
          orElse: () => DoctorRiskLevel.medium,
        ),
        json['risk_label'] as String? ??
            (json['risk'] as String? ?? 'Medium'),
      ),
      consultType:
          json['consult_type'] as String? ?? 'Video Consultation',
      startTime: json['start_time'] as String?,
    );
  }
}

const List<DoctorAppointment> kDoctorAppointments = [
  DoctorAppointment(
    name: 'Sunita Devi',
    id: 'JD-8492',
    time: '5:30 PM',
    status: 'Upcoming',
    risk: DoctorRisk(DoctorRiskLevel.medium, 'Medium Risk'),
    consultType: 'Video Consultation',
  ),
  DoctorAppointment(
    name: 'Ramesh Kumar',
    id: 'JD-7731',
    time: '4:00 PM',
    status: 'Completed',
    risk: DoctorRisk(DoctorRiskLevel.low, 'Low Risk'),
    consultType: 'In-Person Visit',
  ),
];

/// Medicine entry in the prescription builder.
class MedicineEntry {
  MedicineEntry({
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
  int morning;
  int afternoon;
  int night;
  int days;
  final String instructions;
}

const List<String> kMedicineSearchResults = [
  'Paracetamol',
  'Amoxicillin',
  'Azithromycin',
  'Cetirizine',
  'Metformin',
  'Lisinopril',
  'Ibuprofen',
  'Cough Syrup',
];

/// Persistent doctor context.
class DoctorState {
  DoctorState._();

  static String doctorId = 'DR-PRIYA';
  static String doctorName = 'Dr. Priya Sharma';
  static String specialization = 'General Physician';
  static String registrationId = 'MCI-78945612';
  static String clinic = 'JeevanDoot Clinic';
  static String workingHours = '9:00 AM – 5:00 PM';
  static String workingDays = 'Monday to Saturday';
  static bool isAvailable = true;
}
