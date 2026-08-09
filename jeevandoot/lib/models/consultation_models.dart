import 'package:flutter/material.dart';

/// How the patient chooses to book a consultation.
enum BookingMode { self, asha }

/// Consultation medium: video or audio.
enum ConsultKind {
  video('video', 'Video Consultation', Icons.videocam),
  audio('audio', 'Audio Consultation', Icons.headphones);

  const ConsultKind(this.apiValue, this.label, this.icon);

  final String apiValue;
  final String label;
  final IconData icon;
}

/// A medical specialty shown on the doctor-selection step.
class ConsultationSpecialty {
  const ConsultationSpecialty({
    required this.id,
    required this.name,
    required this.doctorCount,
  });

  final String id;
  final String name;
  final int doctorCount;

  IconData get icon {
    switch (id) {
      case 'pediatrics':
        return Icons.child_care;
      case 'gynecology':
        return Icons.female;
      case 'dermatology':
        return Icons.face_retouching_natural;
      case 'cardiology':
        return Icons.monitor_heart;
      case 'mental-health':
        return Icons.psychology;
      case 'other':
        return Icons.more_horiz;
      default:
        return Icons.medical_services;
    }
  }

  factory ConsultationSpecialty.fromJson(Map<String, dynamic> json) =>
      ConsultationSpecialty(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Other',
        doctorCount: json['doctor_count'] as int? ?? 0,
      );
}

/// A doctor available for teleconsultation.
class DoctorInfo {
  const DoctorInfo({
    required this.id,
    required this.name,
    required this.qualification,
    required this.specialization,
    required this.experience,
    required this.languages,
    required this.photoUrl,
    required this.fee,
    required this.rating,
    required this.isActive,
    required this.availableToday,
  });

  final String id;
  final String name;
  final String qualification;
  final String specialization;
  final String experience;
  final List<String> languages;
  final String photoUrl;
  final double fee;
  final double rating;
  final bool isActive;
  final bool availableToday;

  String get feeLabel => fee <= 0 ? 'Free' : '₹${fee.round()}';

  factory DoctorInfo.fromJson(Map<String, dynamic> json) => DoctorInfo(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        qualification: json['qualification'] as String? ?? '',
        specialization: json['specialization'] as String? ?? '',
        experience: json['experience'] as String? ?? '',
        languages:
            (json['languages'] as List?)?.cast<String>() ?? const [],
        photoUrl: json['photo_url'] as String? ?? '',
        fee: (json['consultation_fee'] as num?)?.toDouble() ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        availableToday: json['available_today'] as bool? ?? false,
      );
}

/// Availability state of a single time slot.
enum SlotStatus { available, selected, booked, unavailable }

/// One appointment time slot for a doctor on a given date.
class ConsultationSlot {
  const ConsultationSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.label,
    required this.period,
    required this.status,
  });

  final String id;
  final String startTime;
  final String endTime;
  final String label;
  final String period; // morning | afternoon | evening
  final SlotStatus status;

  bool get isSelectable =>
      status == SlotStatus.available || status == SlotStatus.selected;

  ConsultationSlot copyWith({SlotStatus? status}) => ConsultationSlot(
        id: id,
        startTime: startTime,
        endTime: endTime,
        label: label,
        period: period,
        status: status ?? this.status,
      );

  factory ConsultationSlot.fromJson(Map<String, dynamic> json) {
    final raw = (json['status'] as String? ?? 'available').toLowerCase();
    final status = switch (raw) {
      'booked' => SlotStatus.booked,
      'unavailable' => SlotStatus.unavailable,
      _ => SlotStatus.available,
    };
    return ConsultationSlot(
      id: json['id'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      label: json['label'] as String? ?? '',
      period: json['period'] as String? ?? 'evening',
      status: status,
    );
  }
}

/// Response of GET /api/consultations/doctors/{id}/slots.
class DoctorSlots {
  const DoctorSlots({
    required this.date,
    required this.dateLabel,
    required this.slots,
  });

  final String date;
  final String dateLabel;
  final List<ConsultationSlot> slots;

  factory DoctorSlots.fromJson(Map<String, dynamic> json) => DoctorSlots(
        date: json['date'] as String? ?? '',
        dateLabel: json['date_label'] as String? ?? '',
        slots: (json['slots'] as List? ?? const [])
            .map((e) => ConsultationSlot.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// A bookable day for a doctor (from the 14-day strip).
class SlotDateInfo {
  const SlotDateInfo({
    required this.id,
    required this.label,
    required this.day,
    required this.month,
    required this.weekday,
    required this.full,
    required this.available,
    required this.slotCount,
  });

  final String id; // YYYY-MM-DD
  final String label;
  final int day;
  final String month;
  final String weekday;
  final String full;
  final bool available;
  final int slotCount;

  factory SlotDateInfo.fromJson(Map<String, dynamic> json) => SlotDateInfo(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        day: json['day'] as int? ?? 0,
        month: json['month'] as String? ?? '',
        weekday: json['weekday'] as String? ?? '',
        full: json['full'] as String? ?? '',
        available: json['available'] as bool? ?? false,
        slotCount: json['slot_count'] as int? ?? 0,
      );
}

/// Metadata for an optional attachment (prescription / report / image).
class ConsultationAttachment {
  const ConsultationAttachment({
    required this.name,
    required this.size,
    required this.type,
  });

  final String name;
  final int size;
  final String type;

  String get sizeLabel {
    if (size >= 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / 1024).round()} KB';
  }

  Map<String, dynamic> toJson() => {'name': name, 'size': size, 'type': type};
}

/// Lifecycle of an appointment, as shown to the patient.
enum AppointmentStatus {
  pending,
  upcoming,
  confirmed,
  inProgress,
  completed,
  cancelled,
  noShow;

  static AppointmentStatus fromRaw(String raw) {
    switch (raw.toLowerCase()) {
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'no show':
      case 'noshow':
        return AppointmentStatus.noShow;
      case 'completed':
        return AppointmentStatus.completed;
      default:
        return AppointmentStatus.confirmed;
    }
  }

  String get label {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending';
      case AppointmentStatus.upcoming:
        return 'Upcoming';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.noShow:
        return 'No Show';
    }
  }
}

/// A booked teleconsultation appointment (patient-facing).
class ConsultationAppointment {
  const ConsultationAppointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
    required this.qualification,
    required this.photoUrl,
    required this.fee,
    required this.date,
    required this.dateLabel,
    required this.startTime,
    required this.endTime,
    required this.time,
    required this.consultType,
    required this.reason,
    required this.status,
    required this.bookingSource,
    required this.meetingId,
    required this.attachments,
    required this.start,
    required this.joinWindowMinutes,
    required this.canJoin,
  });

  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String specialization;
  final String qualification;
  final String photoUrl;
  final double fee;
  final String date; // YYYY-MM-DD
  final String dateLabel;
  final String startTime; // HH:MM
  final String endTime;
  final String time; // display label e.g. 10:30 AM
  final String consultType;
  final String reason;
  final String status; // raw backend status
  final String bookingSource; // SELF | ASHA
  final String meetingId;
  final List<ConsultationAttachment> attachments;
  final DateTime? start;
  final int joinWindowMinutes;
  final bool canJoin;

  bool get isAshaBooked => bookingSource == 'ASHA';

  bool get hasStarted => start != null && DateTime.now().isAfter(start!);

  /// True when the consultation is still ahead of us (not started / ongoing).
  bool get isActiveAppointment =>
      status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'upcoming';

  /// Status as shown to the patient, derived from the backend status and the
  /// appointment time (Upcoming → In Progress → Completed as time passes).
  AppointmentStatus get displayStatus {
    if (status.toLowerCase() == 'cancelled') return AppointmentStatus.cancelled;
    if (status.toLowerCase() == 'no show') return AppointmentStatus.noShow;
    if (status.toLowerCase() == 'completed') return AppointmentStatus.completed;
    final s = start;
    if (s != null) {
      final now = DateTime.now();
      if (now.isAfter(s.add(const Duration(hours: 1)))) {
        return AppointmentStatus.completed;
      }
      if (now.isAfter(s.subtract(Duration(minutes: joinWindowMinutes)))) {
        return AppointmentStatus.inProgress;
      }
      return AppointmentStatus.upcoming;
    }
    return AppointmentStatus.confirmed;
  }

  /// Whether the patient may join the call right now.
  bool get canJoinNow {
    if (!isActiveAppointment || start == null) return false;
    final now = DateTime.now();
    final windowStart = start!.subtract(Duration(minutes: joinWindowMinutes));
    return !now.isBefore(windowStart) && !now.isAfter(start!.add(const Duration(hours: 1)));
  }

  /// Human text describing when joining unlocks.
  String get joinHint {
    if (start == null || canJoinNow) return '';
    final windowStart = start!.subtract(Duration(minutes: joinWindowMinutes));
    final diff = windowStart.difference(DateTime.now());
    if (diff.isNegative) return 'Join now';
    final minutes = diff.inMinutes;
    if (minutes <= 0) return 'Join now';
    if (minutes < 60) return 'Join available in $minutes min';
    final hours = (minutes / 60).floor();
    final rem = minutes % 60;
    return rem == 0
        ? 'Join available in $hours hr'
        : 'Join available in $hours hr $rem min';
  }

  /// Short relative day label: Today / Tomorrow / weekday.
  String get relativeDayLabel {
    if (start == null) return dateLabel;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(start!.year, start!.month, start!.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return '${start!.day} ${_months[start!.month - 1]}';
  }

  /// Countdown text for the dashboard ("in 2 days", "Today at 10:30 AM").
  String get countdownLabel {
    if (start == null) return dateLabel;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(start!.year, start!.month, start!.day);
    final diff = day.difference(today).inDays;
    final base = switch (diff) {
      0 => 'Today',
      1 => 'Tomorrow',
      _ => '$relativeDayLabel ${start!.year}',
    };
    return '$base • $time';
  }

  bool get isCancelable =>
      isActiveAppointment && start != null && DateTime.now().isBefore(start!);

  bool get isReschedulable => isCancelable;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  factory ConsultationAppointment.fromJson(Map<String, dynamic> json) {
    final startIso = json['start_iso'] as String?;
    DateTime? start;
    if (startIso != null && startIso.isNotEmpty) {
      start = DateTime.tryParse(startIso);
    }
    return ConsultationAppointment(
      id: json['id'] as String? ?? '',
      patientId: json['patient_id'] as String? ?? '',
      doctorId: json['doctor_id'] as String? ?? '',
      doctorName: json['doctor_name'] as String? ?? '',
      specialization: json['specialization'] as String? ?? '',
      qualification: json['qualification'] as String? ?? '',
      photoUrl: json['photo_url'] as String? ?? '',
      fee: (json['consultation_fee'] as num?)?.toDouble() ?? 0,
      date: json['date'] as String? ?? '',
      dateLabel: json['date_label'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      time: json['time'] as String? ?? '',
      consultType: json['consult_type'] as String? ?? 'Video Consultation',
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'Confirmed',
      bookingSource: json['booking_source'] as String? ?? 'SELF',
      meetingId: json['meeting_id'] as String? ?? '',
      attachments: (json['attachments'] as List? ?? const [])
          .map((e) => ConsultationAttachment(
                name: (e as Map)['name'] as String? ?? '',
                size: (e['size'] as num?)?.toInt() ?? 0,
                type: (e['type'] as String? ?? ''),
              ))
          .toList(),
      start: start,
      joinWindowMinutes: json['join_window_minutes'] as int? ?? 10,
      canJoin: json['can_join'] as bool? ?? false,
    );
  }
}

/// An in-app notification for the patient.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime? createdAt;

  IconData get icon {
    switch (type) {
      case 'booking':
        return Icons.event_available;
      case 'cancellation':
        return Icons.event_busy;
      case 'reschedule':
        return Icons.update;
      case 'asha':
        return Icons.support_agent;
      case 'reminder':
      case 'upcoming':
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        type: json['type'] as String? ?? 'system',
        read: (json['read'] as int? ?? 0) == 1,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      );
}
