import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jeevandoot/models/symptom_result.dart';
import 'package:jeevandoot/screens/symptom_result_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';

SymptomResult _sample({
  required String level,
  required int score,
}) =>
    SymptomResult(
      success: true,
      riskScore: score,
      riskLevel: level,
      summary: 'Summary for $level.',
      symptoms: const ['Headache', 'Dizziness'],
      duration: 'since morning',
      severity: 'mild',
      explanation: 'A plain-language explanation for the patient.',
      precautions: const ['Rest and drink fluids.', 'Monitor your symptoms.'],
      seekMedicalAttention: level != 'LOW',
      emergency: level == 'HIGH',
      warningSigns:
          level == 'LOW' ? const [] : const ['Worsening headache'],
      redFlags: level == 'HIGH' ? const ['Difficulty breathing'] : const [],
      disclaimer: 'This tool does not diagnose medical conditions.',
    );

void main() {
  test('SymptomResult.fromJson parses the backend payload', () {
    final result = SymptomResult.fromJson({
      'success': true,
      'risk_score': 85,
      'risk_level': 'HIGH',
      'summary': 'Urgent attention may be needed.',
      'symptoms': ['Breathing difficulty', 'Chest discomfort'],
      'duration': '',
      'severity': 'severe',
      'explanation': 'Serious warning signs present.',
      'precautions': <String>[],
      'seek_medical_attention': true,
      'emergency': true,
      'warning_signs': <String>[],
      'red_flags': ['Difficulty breathing'],
      'disclaimer': 'This tool does not diagnose medical conditions.',
    });
    expect(result.riskLevel, 'HIGH');
    expect(result.riskScore, 85);
    expect(result.emergency, isTrue);
    expect(result.symptoms, hasLength(2));
  });

  testWidgets('HIGH result shows the urgent-care banner and score',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: SymptomResultScreen(result: _sample(level: 'HIGH', score: 88)),
    ));

    expect(find.text('Your Symptom Check'), findsOneWidget);
    expect(find.text('Seek urgent medical attention'), findsOneWidget);
    expect(find.text('Risk Score: 88/100'), findsOneWidget);
    expect(find.text('Call Emergency Services'), findsOneWidget);
    expect(find.text('Find Nearest Hospital'), findsOneWidget);
    expect(find.text('What we detected'), findsOneWidget);
    expect(find.text('Why this risk level?'), findsOneWidget);
  });

  testWidgets('LOW result shows precautions and self-care actions',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildAppTheme(),
      home: SymptomResultScreen(result: _sample(level: 'LOW', score: 15)),
    ));

    expect(find.text('Risk Score: 15/100'), findsOneWidget);
    expect(find.text('What you can do'), findsOneWidget);
    expect(find.text('Rest and drink fluids.'), findsOneWidget);
    expect(find.text('Continue with Self-Care'), findsOneWidget);
    expect(find.text('Seek urgent medical attention'), findsNothing);
  });
}
