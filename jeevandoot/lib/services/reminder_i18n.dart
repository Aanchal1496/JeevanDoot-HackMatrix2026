import 'package:jeevandoot/services/prescription_i18n.dart';

/// Localized strings for the reminders feature.
///
/// Mirrors the existing [RxStrings] architecture used by the prescription
/// screen: every UI string is available in English, Hindi and Marathi, and the
/// active language follows [RxLanguage] / `AppState.selectedLanguage`.
class ReminderStrings {
  const ReminderStrings({
    required this.title,
    required this.subtitle,
    required this.medicines,
    required this.followUps,
    required this.upcoming,
    required this.history,
    required this.noMedicines,
    required this.noFollowUps,
    required this.noRemindersHint,
    required this.dosage,
    required this.take,
    required this.periodMorning,
    required this.periodAfternoon,
    required this.periodNight,
    required this.beforeFood,
    required this.afterFood,
    required this.anytime,
    required this.days,
    required this.dose,
    required this.todaysDoses,
    required this.tomorrow,
    required this.statusUpcoming,
    required this.statusDue,
    required this.statusTaken,
    required this.statusSkipped,
    required this.statusMissed,
    required this.markTaken,
    required this.skip,
    required this.remindLater,
    required this.nextDose,
    required this.voiceReminder,
    required this.voiceOn,
    required this.voiceOff,
    required this.testVoice,
    required this.addReminder,
    required this.editReminder,
    required this.removeReminder,
    required this.reminderOn,
    required this.reminderOff,
    required this.notificationTitle,
    required this.notificationBody,
    required this.notificationsDisabled,
    required this.voiceUnavailable,
    required this.errorLoading,
    required this.retry,
    required this.followUpDate,
    required this.followUpTime,
    required this.doctor,
    required this.reason,
    required this.enabled,
    required this.disabled,
    required this.reminderSaved,
    required this.reminderRemoved,
    required this.medicine,
    required this.mealInstruction,
  });

  final String title;
  final String subtitle;
  final String medicines;
  final String followUps;
  final String upcoming;
  final String history;
  final String noMedicines;
  final String noFollowUps;
  final String noRemindersHint;
  final String dosage;
  final String take;
  final String periodMorning;
  final String periodAfternoon;
  final String periodNight;
  final String beforeFood;
  final String afterFood;
  final String anytime;
  final String days;
  final String dose;
  final String todaysDoses;
  final String tomorrow;
  final String statusUpcoming;
  final String statusDue;
  final String statusTaken;
  final String statusSkipped;
  final String statusMissed;
  final String markTaken;
  final String skip;
  final String remindLater;
  final String nextDose;
  final String voiceReminder;
  final String voiceOn;
  final String voiceOff;
  final String testVoice;
  final String addReminder;
  final String editReminder;
  final String removeReminder;
  final String reminderOn;
  final String reminderOff;
  final String notificationTitle;
  final String notificationBody;
  final String notificationsDisabled;
  final String voiceUnavailable;
  final String errorLoading;
  final String retry;
  final String followUpDate;
  final String followUpTime;
  final String doctor;
  final String reason;
  final String enabled;
  final String disabled;
  final String reminderSaved;
  final String reminderRemoved;
  final String medicine;
  final String mealInstruction;

  static const ReminderStrings en = ReminderStrings(
    title: 'Reminders',
    subtitle: 'Stay on track with your medicines and follow-ups.',
    medicines: 'Medicines',
    followUps: 'Follow-ups',
    upcoming: 'Upcoming',
    history: 'History',
    noMedicines: 'No medicine reminders yet',
    noFollowUps: 'No follow-up reminders yet',
    noRemindersHint: 'Set a reminder from your prescription to get started.',
    dosage: 'Dosage',
    take: 'Take',
    periodMorning: 'Morning',
    periodAfternoon: 'Afternoon',
    periodNight: 'Night',
    beforeFood: 'Before food',
    afterFood: 'After food',
    anytime: 'Anytime',
    days: 'days',
    dose: 'dose',
    todaysDoses: "Today's doses",
    tomorrow: 'Tomorrow',
    statusUpcoming: 'Upcoming',
    statusDue: 'Due now',
    statusTaken: 'Taken',
    statusSkipped: 'Skipped',
    statusMissed: 'Missed',
    markTaken: 'Mark as Taken',
    skip: 'Skip',
    remindLater: 'Remind Later',
    nextDose: 'Next dose',
    voiceReminder: 'Voice reminder',
    voiceOn: 'On',
    voiceOff: 'Off',
    testVoice: 'Test voice',
    addReminder: 'Add reminder',
    editReminder: 'Edit',
    removeReminder: 'Remove',
    reminderOn: 'Enabled',
    reminderOff: 'Disabled',
    notificationTitle: 'Medicine Reminder',
    notificationBody: 'Take {n} {unit} of {medicine} {period}, {meal}.',
    notificationsDisabled: 'Notifications are disabled. Please enable notifications in your phone settings to receive medicine reminders.',
    voiceUnavailable: 'Voice reading is not supported on this device.',
    errorLoading: 'Could not load your reminders.',
    retry: 'Retry',
    followUpDate: 'Follow-up date',
    followUpTime: 'Time',
    doctor: 'Doctor',
    reason: 'Reason',
    enabled: 'Enabled',
    disabled: 'Disabled',
    reminderSaved: 'Reminder saved.',
    reminderRemoved: 'Reminder removed.',
    medicine: 'Medicine',
    mealInstruction: 'Food',
  );

  static const ReminderStrings hi = ReminderStrings(
    title: 'रिमाइंडर',
    subtitle: 'दवाइयों और जांच के रिमाइंडर याद रखें।',
    medicines: 'दवाइयाँ',
    followUps: 'जांच',
    upcoming: 'आगामी',
    history: 'इतिहास',
    noMedicines: 'अभी कोई दवा रिमाइंडर नहीं है',
    noFollowUps: 'अभी कोई जांच रिमाइंडर नहीं है',
    noRemindersHint: 'शुरू करने के लिए अपने नुस्ख़े से रिमाइंडर सेट करें।',
    dosage: 'मात्रा',
    take: 'लें',
    periodMorning: 'सुबह',
    periodAfternoon: 'दोपहर',
    periodNight: 'रात',
    beforeFood: 'खाने से पहले',
    afterFood: 'खाने के बाद',
    anytime: 'कभी भी',
    days: 'दिन',
    dose: 'खुराक',
    todaysDoses: 'आज की खुराक',
    tomorrow: 'कल',
    statusUpcoming: 'आगामी',
    statusDue: 'अभी लेना है',
    statusTaken: 'लिया गया',
    statusSkipped: 'छोड़ा गया',
    statusMissed: 'छूट गया',
    markTaken: 'लिया गया चिह्नित करें',
    skip: 'छोड़ें',
    remindLater: 'बाद में याद दिलाएँ',
    nextDose: 'अगली खुराक',
    voiceReminder: 'आवाज़ रिमाइंडर',
    voiceOn: 'चालू',
    voiceOff: 'बंद',
    testVoice: 'आवाज़ जाँचें',
    addReminder: 'रिमाइंडर जोड़ें',
    editReminder: 'बदलें',
    removeReminder: 'हटाएँ',
    reminderOn: 'सक्षम',
    reminderOff: 'अक्षम',
    notificationTitle: 'दवा रिमाइंडर',
    notificationBody: '{medicine} की {n} {unit} {period} {meal} लें।',
    notificationsDisabled: 'सूचनाएँ बंद हैं। दवा रिमाइंडर पाने के लिए अपने फ़ोन की सेटिंग्स में सूचनाएँ चालू करें।',
    voiceUnavailable: 'इस डिवाइस पर आवाज़ पढ़ना उपलब्ध नहीं है।',
    errorLoading: 'आपके रिमाइंडर लोड नहीं हो सके।',
    retry: 'फिर कोशिश करें',
    followUpDate: 'जांच की तारीख',
    followUpTime: 'समय',
    doctor: 'डॉक्टर',
    reason: 'कारण',
    enabled: 'सक्षम',
    disabled: 'अक्षम',
    reminderSaved: 'रिमाइंडर सेव हो गया।',
    reminderRemoved: 'रिमाइंडर हटा दिया गया।',
    medicine: 'दवा',
    mealInstruction: 'खाने के साथ',
  );

  static const ReminderStrings mr = ReminderStrings(
    title: 'आठवणी',
    subtitle: 'औषधे आणि तपासण्यांच्या आठवणी लक्षात ठेवा.',
    medicines: 'औषधे',
    followUps: 'तपासण्या',
    upcoming: 'आगामी',
    history: 'इतिहास',
    noMedicines: 'अजून औषध आठवण नाही',
    noFollowUps: 'अजून तपासणी आठवण नाही',
    noRemindersHint: 'सुरुवात करण्यासाठी तुमच्या प्रिस्क्रिप्शनमधून आठवण सेट करा.',
    dosage: 'मात्रा',
    take: 'घ्या',
    periodMorning: 'सकाळ',
    periodAfternoon: 'दुपार',
    periodNight: 'रात्री',
    beforeFood: 'जेवणापूर्वी',
    afterFood: 'जेवणानंतर',
    anytime: 'कधीही',
    days: 'दिवस',
    dose: 'डोस',
    todaysDoses: 'आजचे डोस',
    tomorrow: 'उद्या',
    statusUpcoming: 'आगामी',
    statusDue: 'आता घ्या',
    statusTaken: 'घेतले',
    statusSkipped: 'वगळले',
    statusMissed: 'चुकले',
    markTaken: 'घेतले म्हणून चिन्हांकित करा',
    skip: 'वगळा',
    remindLater: 'नंतर आठवण',
    nextDose: 'पुढील डोस',
    voiceReminder: 'आवाज आठवण',
    voiceOn: 'चालू',
    voiceOff: 'बंद',
    testVoice: 'आवाज तपासा',
    addReminder: 'आठवण जोडा',
    editReminder: 'बदला',
    removeReminder: 'काढा',
    reminderOn: 'सक्षम',
    reminderOff: 'अक्षम',
    notificationTitle: 'औषध आठवण',
    notificationBody: '{medicine} ची {n} {unit} {period} {meal} घ्या.',
    notificationsDisabled: 'सूचना बंद आहेत. औषध आठवण मिळवण्यासाठी तुमच्या फोनच्या सेटिंगमध्ये सूचना चालू करा.',
    voiceUnavailable: 'या डिव्हाइसवर आवाजात वाचणे उपलब्ध नाही.',
    errorLoading: 'तुमच्या आठवणी लोड होऊ शकल्या नाहीत.',
    retry: 'पुन्हा प्रयत्न करा',
    followUpDate: 'तपासणीची तारीख',
    followUpTime: 'वेळ',
    doctor: 'डॉक्टर',
    reason: 'कारण',
    enabled: 'सक्षम',
    disabled: 'अक्षम',
    reminderSaved: 'आठवण जतन झाली.',
    reminderRemoved: 'आठवण काढली.',
    medicine: 'औषध',
    mealInstruction: 'जेवणासोबत',
  );

  static ReminderStrings of(RxLanguage lang) => switch (lang) {
        RxLanguage.hi => hi,
        RxLanguage.mr => mr,
        RxLanguage.en => en,
      };

  /// The vernacular word for a medicine unit, mirroring `RxStrings.unitWord`.
  String unitFor(String category) {
    final c = category.toLowerCase();
    if (c.contains('syrup') || c.contains('liquid')) return medicine;
    if (c.contains('capsule')) return medicine;
    if (c.contains('injection') || c.contains('vaccine')) return medicine;
    if (c.contains('drop')) return medicine;
    return medicine;
  }
}