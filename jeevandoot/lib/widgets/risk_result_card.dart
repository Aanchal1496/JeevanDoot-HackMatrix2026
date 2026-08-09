import 'package:flutter/material.dart';

import '../models/symptom_result.dart';
import '../theme/app_theme.dart';

/// Color + label mapping for the three risk levels.
(Color, String) riskLevelStyle(String level, ColorScheme scheme) {
  switch (level) {
    case 'HIGH':
      return (scheme.error, 'High');
    case 'MEDIUM':
      return (scheme.tertiary, 'Medium');
    default:
      return (scheme.primary, 'Low');
  }
}

/// Big risk badge + score gauge shown at the top of the result screen.
class RiskResultCard extends StatelessWidget {
  const RiskResultCard({super.key, required this.result});

  final SymptomResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (color, label) = riskLevelStyle(result.riskLevel, scheme);
    final score = result.riskScore.clamp(0, 100).toDouble();

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
            ),
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 10,
                color: color,
                backgroundColor: scheme.surfaceContainerHighest,
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${result.riskScore}',
                  style: AppTextStyles.displayHero.copyWith(
                    color: color,
                    fontSize: 44,
                  ),
                ),
                Text(
                  '/ 100',
                  style: AppTextStyles.labelSm.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gutter),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.labelLg.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.unit),
        Text(
          'Risk Score: ${result.riskScore}/100',
          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
