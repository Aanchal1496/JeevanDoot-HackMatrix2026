import 'package:flutter/material.dart';

import '../screens/listening_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/common.dart';
import '../widgets/microphone_button.dart';
import '../widgets/symptom_selector.dart';

/// Step 1 of the symptom checker: choose a voice, icon or typed input.
class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final Set<String> _selected = {};

  void _goToListening({bool textMode = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListeningScreen(
          selectedSymptoms: _selected.toSet(),
          startInTextMode: textMode,
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
          140,
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
              "Describe your symptoms and we'll help you understand how urgent they may be.",
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
            SymptomSelector(
              selected: _selected,
              onChanged: (next) => setState(() => _selected..clear()..addAll(next)),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Center(
              child: TextButton.icon(
                onPressed: () => _goToListening(textMode: true),
                icon: const Icon(Icons.keyboard),
                label: const Text('Prefer to type? Enter symptoms manually'),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                ),
              ),
            ),
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
            label: _selected.isEmpty ? 'Continue' : 'Continue (${_selected.length})',
            onPressed: _continue,
          ),
        ),
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
        MicrophoneButton(
          listening: false,
          onPressed: () => _goToListening(),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        Text(
          'Tap the microphone and tell us how you\u2019re feeling.',
          textAlign: TextAlign.center,
          style: AppTextStyles.labelLg.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        PillButton(
          label: 'Start speaking',
          icon: Icons.mic,
          onPressed: () => _goToListening(),
        ),
      ],
    );
  }
}
