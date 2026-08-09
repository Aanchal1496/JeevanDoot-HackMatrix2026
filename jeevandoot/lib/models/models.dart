// Patient-side shared models.

/// A selectable symptom category shown in the icon-based selector.
class Symptom {
  const Symptom(this.id, this.label, this.emoji);

  final String id;
  final String label;
  final String emoji;
}

/// The 14 icon-based symptom categories available in the symptom checker.
/// [id] values match the canonical ids used by the backend symptom extractor.
const List<Symptom> kSymptoms = [
  Symptom('fever', 'Fever', '\u{1F912}'),
  Symptom('headache', 'Headache', '\u{1F915}'),
  Symptom('cough', 'Cough', '\u{1F637}'),
  Symptom('breathing', 'Breathing difficulty', '\u{1FAC1}'),
  Symptom('chest', 'Chest discomfort', '\u2764\uFE0F'),
  Symptom('nausea', 'Nausea', '\u{1F922}'),
  Symptom('vomiting', 'Vomiting', '\u{1F92E}'),
  Symptom('diarrhea', 'Diarrhea', '\u{1F4A9}'),
  Symptom('dizziness', 'Dizziness', '\u{1F635}'),
  Symptom('fatigue', 'Fatigue', '\u{1F634}'),
  Symptom('cold', 'Cold', '\u{1F927}'),
  Symptom('sore_throat', 'Sore throat', '\u{1F5E3}\uFE0F'),
  Symptom('pain', 'Pain', '\u{1FA79}'),
  Symptom('other', 'Other', '\u{1FA7A}'),
];

/// Display label for a symptom id (fallback: readable id).
String symptomLabel(String id) {
  for (final s in kSymptoms) {
    if (s.id == id) return s.label;
  }
  return id.replaceAll('_', ' ');
}

/// Persistent patient context shared across screens.
class AppState {
  AppState._();

  static String selectedLanguage = 'hi';
  static String patientName = 'Ramesh';
  static String phone = '+91 98765 43210';
  static String patientId = 'PT-RAMESH';
  static String token = '';
  static bool medicineReminderTaken = false;

  /// Most recent symptom-checker summary. Shown to the doctor at booking as
  /// an AI-generated pre-consultation summary (for clinician review only).
  static String lastTriageSummary = '';
}
