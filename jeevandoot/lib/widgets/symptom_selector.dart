import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Multi-select emoji grid of the 14 symptom categories.
class SymptomSelector extends StatelessWidget {
  const SymptomSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kSymptoms.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.unit,
        crossAxisSpacing: AppSpacing.unit,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final symptom = kSymptoms[index];
        final isSelected = selected.contains(symptom.id);
        return _chip(scheme, symptom, isSelected);
      },
    );
  }

  Widget _chip(ColorScheme scheme, Symptom symptom, bool isSelected) {
    return Material(
      color: isSelected ? scheme.primaryContainer : scheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          final next = Set<String>.of(selected);
          if (isSelected) {
            next.remove(symptom.id);
          } else {
            next.add(symptom.id);
          }
          onChanged(next);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? scheme.primaryContainer : scheme.outlineVariant,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                symptom.emoji,
                style: const TextStyle(fontSize: 30, height: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                symptom.label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelLg.copyWith(
                  color: isSelected ? scheme.onPrimaryContainer : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
