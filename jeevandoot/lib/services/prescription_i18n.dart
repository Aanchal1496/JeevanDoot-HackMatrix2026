import 'package:jeevandoot/services/backend.dart';

/// Supported interface languages for the prescription screen.
enum RxLanguage {
  en('en', 'English', 'EN', 'en-IN'),
  hi('hi', 'हिंदी', 'हिं', 'hi-IN'),
  mr('mr', 'मराठी', 'मरा', 'mr-IN');

  const RxLanguage(this.code, this.label, this.shortLabel, this.ttsCode);

  final String code;
  final String label;
  final String shortLabel;
  final String ttsCode;

  static RxLanguage fromCode(String code) => RxLanguage.values.firstWhere(
        (l) => l.code == code,
        orElse: () => RxLanguage.en,
      );
}

/// Localized strings for the icon-based prescription screen.
class RxStrings {
  const RxStrings({
    required this.myPrescription,
    required this.prescribedBy,
    required this.consultationDate,
    required this.patient,
    required this.active,
    required this.doctor,
    required this.listen,
    required this.speaking,
    required this.play,
    required this.pause,
    required this.replay,
    required this.dosage,
    required this.tablet,
    required this.syrup,
    required this.capsule,
    required this.injection,
    required this.drops,
    required this.morning,
    required this.afternoon,
    required this.night,
    required this.beforeFood,
    required this.afterFood,
    required this.anytime,
    required this.forDays,
    required this.until,
    required this.todaysMedicines,
    required this.markAsTaken,
    required this.taken,
    required this.setReminder,
    required this.reminderOn,
    required this.reminderOff,
    required this.reminderTime,
    required this.nextDose,
    required this.nextDoseTomorrow,
    required this.nextFollowUp,
    required this.addReminder,
    required this.followUpReminderAdded,
    required this.followUpReminderRemoved,
    required this.safetyNote,
    required this.noPrescriptions,
    required this.noPrescriptionsHint,
    required this.errorLoading,
    required this.retry,
    required this.voiceUnavailable,
    required this.medicine,
    required this.quantity,
    required this.time,
    required this.food,
    required this.duration,
    required this.chosePrescription,
    required this.and,
  });

  final String myPrescription;
  final String prescribedBy;
  final String consultationDate;
  final String patient;
  final String active;
  final String doctor;
  final String listen;
  final String speaking;
  final String play;
  final String pause;
  final String replay;
  final String dosage;
  final String tablet;
  final String syrup;
  final String capsule;
  final String injection;
  final String drops;
  final String morning;
  final String afternoon;
  final String night;
  final String beforeFood;
  final String afterFood;
  final String anytime;
  final String forDays;
  final String until;
  final String todaysMedicines;
  final String markAsTaken;
  final String taken;
  final String setReminder;
  final String reminderOn;
  final String reminderOff;
  final String reminderTime;
  final String nextDose;
  final String nextDoseTomorrow;
  final String nextFollowUp;
  final String addReminder;
  final String followUpReminderAdded;
  final String followUpReminderRemoved;
  final String safetyNote;
  final String noPrescriptions;
  final String noPrescriptionsHint;
  final String errorLoading;
  final String retry;
  final String voiceUnavailable;
  final String medicine;
  final String quantity;
  final String time;
  final String food;
  final String duration;
  final String chosePrescription;
  final String and;

  static const RxStrings en = RxStrings(
    myPrescription: 'My Prescription',
    prescribedBy: 'Prescribed by',
    consultationDate: 'Consultation date',
    patient: 'Patient',
    active: 'Active',
    doctor: 'Doctor',
    listen: 'Listen',
    speaking: 'Speaking…',
    play: 'Play',
    pause: 'Pause',
    replay: 'Replay',
    dosage: 'Dosage',
    tablet: 'Tablet',
    syrup: 'Syrup',
    capsule: 'Capsule',
    injection: 'Injection',
    drops: 'Drops',
    morning: 'Morning',
    afternoon: 'Afternoon',
    night: 'Night',
    beforeFood: 'Before Food',
    afterFood: 'After Food',
    anytime: 'Anytime',
    forDays: 'For {n} Days',
    until: 'Until {date}',
    todaysMedicines: "Today's Medicines",
    markAsTaken: 'Mark as Taken',
    taken: 'Taken',
    setReminder: 'Set Reminder',
    reminderOn: 'On',
    reminderOff: 'Off',
    reminderTime: 'Reminder time',
    nextDose: 'Next dose',
    nextDoseTomorrow: 'Tomorrow morning',
    nextFollowUp: 'Next Follow-up',
    addReminder: 'Add Reminder',
    followUpReminderAdded: 'Follow-up reminder added.',
    followUpReminderRemoved: 'Follow-up reminder removed.',
    safetyNote: 'Follow the dosage prescribed by your doctor.',
    noPrescriptions: 'No prescriptions yet',
    noPrescriptionsHint: 'Your doctor will share prescriptions here after a consultation.',
    errorLoading: 'Could not load your prescriptions.',
    retry: 'Retry',
    voiceUnavailable: 'Voice reading is not supported on this device.',
    medicine: 'Medicine',
    quantity: 'How many',
    time: 'When',
    food: 'With food',
    duration: 'For how long',
    chosePrescription: 'Prescription',
    and: 'and',
  );

  static const RxStrings hi = RxStrings(
    myPrescription: 'मेरा नुस्ख़ा',
    prescribedBy: 'द्वारा लिखा गया',
    consultationDate: 'परामर्श की तारीख',
    patient: 'मरीज़',
    active: 'सक्रिय',
    doctor: 'डॉक्टर',
    listen: 'सुनें',
    speaking: 'सुना जा रहा है…',
    play: 'चलाएँ',
    pause: 'रोकें',
    replay: 'फिर से सुनें',
    dosage: 'मात्रा',
    tablet: 'गोली',
    syrup: 'सिरप',
    capsule: 'कैप्सूल',
    injection: 'इंजेक्शन',
    drops: 'बूँदें',
    morning: 'सुबह',
    afternoon: 'दोपहर',
    night: 'रात',
    beforeFood: 'खाने से पहले',
    afterFood: 'खाने के बाद',
    anytime: 'कभी भी',
    forDays: '{n} दिन तक',
    until: '{date} तक',
    todaysMedicines: 'आज की दवाइयाँ',
    markAsTaken: 'लिया गया चिह्नित करें',
    taken: 'लिया गया',
    setReminder: 'रिमाइंडर सेट करें',
    reminderOn: 'चालू',
    reminderOff: 'बंद',
    reminderTime: 'रिमाइंडर समय',
    nextDose: 'अगली खुराक',
    nextDoseTomorrow: 'कल सुबह',
    nextFollowUp: 'अगली जांच',
    addReminder: 'रिमाइंडर जोड़ें',
    followUpReminderAdded: 'जांच का रिमाइंडर जुड़ गया।',
    followUpReminderRemoved: 'जांच का रिमाइंडर हटा दिया गया।',
    safetyNote: 'अपने डॉक्टर द्वारा निर्धारित मात्रा का ही पालन करें।',
    noPrescriptions: 'अभी कोई नुस्ख़ा नहीं है',
    noPrescriptionsHint: 'परामर्श के बाद आपका डॉक्टर यहाँ नुस्ख़ा साझा करेगा।',
    errorLoading: 'आपका नुस्ख़ा लोड नहीं हो सका।',
    retry: 'फिर कोशिश करें',
    voiceUnavailable: 'इस डिवाइस पर आवाज़ पढ़ना उपलब्ध नहीं है।',
    medicine: 'दवा',
    quantity: 'कितनी',
    time: 'कब',
    food: 'खाने के साथ',
    duration: 'कितने दिन',
    chosePrescription: 'नुस्ख़ा',
    and: 'और',
  );

  static const RxStrings mr = RxStrings(
    myPrescription: 'माझे प्रिस्क्रिप्शन',
    prescribedBy: 'यांनी दिलेले',
    consultationDate: 'भेटीची तारीख',
    patient: 'रुग्ण',
    active: 'सक्रिय',
    doctor: 'डॉक्टर',
    listen: 'ऐका',
    speaking: 'ऐकवले जात आहे…',
    play: 'चालवा',
    pause: 'थांबवा',
    replay: 'पुन्हा ऐका',
    dosage: 'मात्रा',
    tablet: 'गोळी',
    syrup: 'सिरप',
    capsule: 'कॅप्सूल',
    injection: 'इंजेक्शन',
    drops: 'थेंब',
    morning: 'सकाळ',
    afternoon: 'दुपार',
    night: 'रात्री',
    beforeFood: 'जेवणापूर्वी',
    afterFood: 'जेवणानंतर',
    anytime: 'कधीही',
    forDays: '{n} दिवस',
    until: '{date} पर्यंत',
    todaysMedicines: 'आजची औषधे',
    markAsTaken: 'घेतले म्हणून चिन्हांकित करा',
    taken: 'घेतले',
    setReminder: 'आठवण सेट करा',
    reminderOn: 'चालू',
    reminderOff: 'बंद',
    reminderTime: 'आठवणीची वेळ',
    nextDose: 'पुढील डोस',
    nextDoseTomorrow: 'उद्या सकाळी',
    nextFollowUp: 'पुढील तपासणी',
    addReminder: 'आठवण जोडा',
    followUpReminderAdded: 'तपासणीची आठवण जोडली.',
    followUpReminderRemoved: 'तपासणीची आठवण काढली.',
    safetyNote: 'तुमच्या डॉक्टरांनी दिलेल्या मात्रेचेच पालन करा.',
    noPrescriptions: 'अजून प्रिस्क्रिप्शन नाही',
    noPrescriptionsHint: 'भेटीनंतर तुमचे डॉक्टर येथे प्रिस्क्रिप्शन शेअर करतील.',
    errorLoading: 'तुमचे प्रिस्क्रिप्शन लोड होऊ शकले नाही.',
    retry: 'पुन्हा प्रयत्न करा',
    voiceUnavailable: 'या डिव्हाइसवर आवाजात वाचणे उपलब्ध नाही.',
    medicine: 'औषध',
    quantity: 'किती',
    time: 'केव्हा',
    food: 'जेवणासोबत',
    duration: 'किती दिवस',
    chosePrescription: 'प्रिस्क्रिप्शन',
    and: 'आणि',
  );

  static RxStrings of(RxLanguage lang) => switch (lang) {
        RxLanguage.hi => hi,
        RxLanguage.mr => mr,
        RxLanguage.en => en,
      };

  String unitWord(String category) {
    final c = category.toLowerCase();
    if (c.contains('syrup') || c.contains('liquid')) return syrup;
    if (c.contains('capsule')) return capsule;
    if (c.contains('injection') || c.contains('vaccine')) return injection;
    if (c.contains('drop')) return drops;
    return tablet;
  }
}

/// Number words used when reading the prescription aloud (1–5).
class RxNumberWords {
  const RxNumberWords(this.words);

  final List<String> words;

  String of(int n) => n >= 1 && n <= words.length ? words[n - 1] : '$n';

  static const en = RxNumberWords(['one', 'two', 'three', 'four', 'five']);
  static const hi = RxNumberWords(['एक', 'दो', 'तीन', 'चार', 'पाँच']);
  static const mr = RxNumberWords(['एक', 'दोन', 'तीन', 'चार', 'पाच']);

  static RxNumberWords forLang(RxLanguage lang) => switch (lang) {
        RxLanguage.hi => hi,
        RxLanguage.mr => mr,
        RxLanguage.en => en,
      };
}

/// Builds the sentence read aloud by the voice assistant in [lang].
///
/// Medicine names and numbers stay standardized; the connecting words are
/// translated. Example (EN):
/// "Paracetamol 500 mg. Take one tablet in the morning and one tablet at
/// night, after food, for 5 days."
String buildSpokenScript(Prescription p, RxLanguage lang) {
  final s = RxStrings.of(lang);
  final num = RxNumberWords.forLang(lang);

  final parts = <String>[];
  for (final m in p.medicines) {
    final unit = s.unitWord(m.category);
    final doseParts = <String>[];
    if (m.morning > 0) doseParts.add('${s.morning} ${num.of(m.morning)} $unit');
    if (m.afternoon > 0) doseParts.add('${s.afternoon} ${num.of(m.afternoon)} $unit');
    if (m.night > 0) doseParts.add('${s.night} ${num.of(m.night)} $unit');

    final food = switch (m.instructions.toLowerCase()) {
      'before food' => s.beforeFood,
      'after food' => s.afterFood,
      _ => s.anytime,
    };

    final duration = m.days > 0
        ? s.forDays.replaceAll('{n}', num.of(m.days))
        : '';

    final sentence = [
      '${m.name} ${m.dosage} ${m.unit}.',
      if (doseParts.isNotEmpty) '${s.dosage} ${doseParts.join(' ${s.and} ')}',
      if (food.isNotEmpty) food,
      if (duration.isNotEmpty) duration,
    ].where((e) => e.isNotEmpty).join(', ');
    parts.add(sentence);
  }
  return parts.join('. ');
}
