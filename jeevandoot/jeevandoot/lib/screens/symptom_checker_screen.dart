import 'package:flutter/material.dart';
import 'package:jeevandoot/models/models.dart';
import 'package:jeevandoot/screens/listening_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        onTrailing: () => openOfflineScreen(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.stackSm,
          AppSpacing.containerMargin,
          130,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _progressStepper(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              "Tell us what you're feeling",
              textAlign: TextAlign.center,
              style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.unit),
            Text(
              'Describe your symptoms in your own words.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            _voiceFirst(scheme),
            const SizedBox(height: AppSpacing.stackLg),
            Row(
              children: [
                Expanded(child: Divider(color: scheme.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                  child: Text(
                    'Or choose symptoms',
                    style: AppTextStyles.labelLg.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                Expanded(child: Divider(color: scheme.outlineVariant)),
              ],
            ),
            const SizedBox(height: AppSpacing.stackLg),
            _symptomGrid(scheme),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.unit,
          AppSpacing.containerMargin,
          16,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest.withValues(alpha: 0.95),
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.08),
              offset: const Offset(0, -4),
              blurRadius: 20,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: PillButton(
            label: 'Continue',
            onPressed: _continue,
          ),
        ),
      ),
    );
  }

  void _continue() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one symptom or use voice.'),
        ),
      );
      return;
    }
    _goToListening();
  }

  void _goToListening() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListeningScreen(selectedSymptoms: _selected.toSet()),
      ),
    );
  }

  Widget _progressStepper(ColorScheme scheme) {
    return Row(
      children: [
        Text(
          'Step 1 of 3',
          style: AppTextStyles.labelLg.copyWith(color: scheme.primary),
        ),
        const SizedBox(width: AppSpacing.gutter),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _voiceFirst(ColorScheme scheme) {
    return Column(
      children: [
        InkWell(
          onTap: () => _goToListening(),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.mic, size: 48, color: scheme.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'Tap to speak',
          style: AppTextStyles.labelLg.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackMd),
      ],
    );
  }

  Widget _symptomGrid(ColorScheme scheme) {
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
        final selected = _selected.contains(symptom.id);
        return _symptomChip(scheme, symptom, selected);
      },
    );
  }

  Widget _symptomChip(ColorScheme scheme, Symptom symptom, bool selected) {
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          setState(() {
            if (selected) {
              _selected.remove(symptom.id);
            } else {
              _selected.add(symptom.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? scheme.primaryContainer : scheme.outlineVariant,
            ),
            boxShadow: selected
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
              Icon(
                symptom.icon,
                size: 32,
                color: selected ? scheme.onPrimaryContainer : scheme.secondary,
              ),
              const SizedBox(height: 8),
              Text(
                symptom.label,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelLg.copyWith(
                  color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
