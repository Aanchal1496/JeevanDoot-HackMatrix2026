import 'package:flutter/material.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class DoctorAISuggestedQuestionsScreen extends StatefulWidget {
  const DoctorAISuggestedQuestionsScreen({super.key, required this.patient});

  final DoctorPatient patient;

  @override
  State<DoctorAISuggestedQuestionsScreen> createState() =>
      _DoctorAISuggestedQuestionsScreenState();
}

class _DoctorAISuggestedQuestionsScreenState
    extends State<DoctorAISuggestedQuestionsScreen> {
  final Set<int> _selected = {};

  static const _questions = [
    'How long have you been experiencing the fever?',
    'Have you taken any medication in the last 24 hours?',
    'Are you experiencing any breathing difficulty at rest?',
    'Is the pain sharp or dull? Does it radiate elsewhere?',
    'Have you travelled recently or been exposed to anyone unwell?',
    'Do you have any known allergies to medication?',
    'Have you noticed any change in appetite or weight?',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        showBack: true,
        title: 'AI Suggested Questions',
        hideTrailing: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.containerMargin),
              children: [
                _headerCard(scheme),
                const SizedBox(height: AppSpacing.stackMd),
                for (var i = 0; i < _questions.length; i++)
                  _questionCard(scheme, index: i, question: _questions[i]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.containerMargin),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(
                top: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            child: PillButton(
              label: 'Add Selected (${_selected.length})',
              height: 48,
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${_selected.length} questions added to consultation.',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 24, color: scheme.onPrimaryContainer),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Text(
              'AI has generated questions based on the patient\'s reported symptoms.',
              style: AppTextStyles.bodyMd.copyWith(
                color: scheme.onPrimaryContainer,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionCard(
    ColorScheme scheme, {
    required int index,
    required String question,
  }) {
    final selected = _selected.contains(index);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.unit),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() {
          selected ? _selected.remove(index) : _selected.add(index);
        }),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected ? scheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? scheme.primary : scheme.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check, size: 16, color: scheme.onPrimary)
                    : null,
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Text(
                  question,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: scheme.onSurface, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
