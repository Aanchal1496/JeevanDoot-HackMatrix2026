import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart';

/// Large animated microphone button.
///
/// Shows a pulsing ring while [listening], a subtle pulse in [idle] mode,
/// and a stop icon when active so the patient knows how to finish.
class MicrophoneButton extends StatelessWidget {
  const MicrophoneButton({
    super.key,
    required this.listening,
    required this.onPressed,
    this.enabled = true,
    this.size = 120,
  });

  final bool listening;
  final VoidCallback onPressed;
  final bool enabled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inner = Material(
      color: enabled
          ? (listening ? scheme.error : scheme.primary)
          : scheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      elevation: listening ? 8 : 4,
      shadowColor: scheme.primary.withValues(alpha: 0.35),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            listening ? Icons.stop_rounded : Icons.mic,
            size: size * 0.42,
            color: enabled ? (listening ? scheme.onError : AppColors.onPrimary) : scheme.outline,
          ),
        ),
      ),
    );
    return PulsingRing(
      color: enabled ? (listening ? scheme.error : scheme.primary) : scheme.outlineVariant,
      duration: listening
          ? const Duration(milliseconds: 1100)
          : const Duration(seconds: 2),
      child: inner,
    );
  }
}
