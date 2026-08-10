import 'package:flutter/material.dart';
import 'package:jeevandoot/api/doctor_service.dart';

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
    this.patientUserId,
    this.consultationId,
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
  final int? patientUserId;
  final int? consultationId;

  /// Builds a queue card from a live `/doctors/queue` item. Fields not
  /// present in the queue response (age/gender/wait-time) render as "unknown".
  factory DoctorPatient.fromQueue(QueuePatient q) {
    final level = switch (q.riskLevel) {
      'HIGH' => DoctorRiskLevel.urgent,
      'MEDIUM' => DoctorRiskLevel.medium,
      _ => DoctorRiskLevel.low,
    };
    return DoctorPatient(
      name: q.patientName,
      id: 'TRI-${q.triageId}',
      age: 'Not recorded',
      gender: 'Unknown',
      risk: DoctorRisk(level, '${q.riskLevel} Risk'),
      symptoms: q.symptoms.isEmpty ? [] : [q.symptoms],
      waitTime: 'IN QUEUE',
      startTime: null,
      patientUserId: q.patientId,
    );
  }

  /// Builds a queue card from a `/consultations/queue` item (demo mode).
  factory DoctorPatient.fromConsultation(ConsultationQueueItem q) {
    final level = switch (q.riskLevel) {
      'HIGH' => DoctorRiskLevel.urgent,
      'MEDIUM' => DoctorRiskLevel.medium,
      _ => DoctorRiskLevel.low,
    };
    return DoctorPatient(
      name: q.patientName,
      id: 'CONS-${q.id}',
      age: q.age?.toString() ?? 'Not recorded',
      gender: q.gender ?? 'Unknown',
      risk: DoctorRisk(level, '${q.riskLevel} Risk'),
      symptoms: q.symptoms,
      waitTime: 'IN QUEUE',
      consultType: q.type ?? 'Video Consultation',
      patientUserId: q.patientId,
      consultationId: q.id,
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

  static String doctorName = 'Dr. Priya Sharma';
  static String specialization = 'General Physician';
  static String registrationId = 'MCI-78945612';
  static String clinic = 'JeevanDoot Clinic';
  static String workingHours = '9:00 AM – 5:00 PM';
  static String workingDays = 'Monday to Saturday';
  static bool isAvailable = true;
}
