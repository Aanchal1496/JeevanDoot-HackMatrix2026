import 'package:flutter_tts/flutter_tts.dart';

import 'prescription_i18n.dart';
import 'reminder_i18n.dart';

/// Spoken (Text-to-Speech) medicine reminder.
///
/// The spoken sentence is built in the patient's selected language (via
/// [ReminderStrings] / [RxNumberWords]) and read aloud with `flutter_tts`.
class VoiceReminderService {
  VoiceReminderService._();
  static final VoiceReminderService instance = VoiceReminderService._();

  FlutterTts? _tts;
  bool _available = true;

  Future<void> _ensureTts() async {
    if (_tts != null) return;
    try {
      final tts = FlutterTts();
      await tts.awaitSpeakCompletion(false);
      _tts = tts;
    } catch (_) {
      _available = false;
      _tts = null;
    }
  }

  bool get isAvailable => _available;

  String _periodLabel(RxLanguage lang, String period) {
    final s = ReminderStrings.of(lang);
    switch (period) {
      case 'morning':
        return s.periodMorning;
      case 'afternoon':
        return s.periodAfternoon;
      default:
        return s.periodNight;
    }
  }

  String _mealLabel(RxLanguage lang, String instruction) {
    final s = ReminderStrings.of(lang);
    final i = instruction.toLowerCase();
    if (i.contains('before')) return 'before food';
    if (i.contains('after')) return 'after food';
    return s.anytime;
  }

  /// Builds the spoken reminder sentence for the given medicine dose.
  String buildScript({
    required RxLanguage lang,
    required String medicineName,
    String dosage = '',
    String unit = '',
    int quantity = 1,
    String period = 'morning',
    String mealInstruction = 'After food',
  }) {
    final periodLabel = _periodLabel(lang, period);
    final mealLabel = _mealLabel(lang, mealInstruction);
    final word = RxNumberWords.forLang(lang).of(quantity);
    final unitWord =
        unit.isNotEmpty ? unit : (dosage.isNotEmpty ? dosage : '');

    return switch (lang) {
      RxLanguage.hi =>
        'दवाई लेने का समय हो गया है। $periodLabel $medicineName ${dosage.isNotEmpty ? dosage : ''} ${unit.isNotEmpty ? unit : ''} की $word गोली $mealLabel लें।',
      RxLanguage.mr =>
        'औषध घेण्याची वेळ झाली आहे. $periodLabel $medicineName ${dosage.isNotEmpty ? dosage : ''} ${unit.isNotEmpty ? unit : ''} ची $word गोळी $mealLabel घ्या.',
      RxLanguage.en =>
        'Medicine reminder. Take $word $unitWord of $medicineName, '
        '$periodLabel, $mealLabel.',
    };
  }

  Future<void> speak({
    required RxLanguage lang,
    required String medicineName,
    String dosage = '',
    String unit = '',
    int quantity = 1,
    String period = 'morning',
    String mealInstruction = 'After food',
  }) async {
    await _ensureTts();
    final tts = _tts;
    if (tts == null) {
      _available = false;
      return;
    }
    try {
      await tts.stop();
      await tts.setLanguage(lang.ttsCode);
      await tts.setSpeechRate(0.48);
      final script = buildScript(
        lang: lang,
        medicineName: medicineName,
        dosage: dosage,
        unit: unit,
        quantity: quantity,
        period: period,
        mealInstruction: mealInstruction,
      );
      await tts.speak(script);
    } catch (_) {
      _available = false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}