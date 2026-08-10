import 'package:flutter/material.dart';
import 'package:jeevandoot/l10n/app_strings.dart';
import 'package:jeevandoot/screens/prescription_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/common.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key, this.type});

  /// Consultation kind: contains 'audio' for (voice-only) calls.
  final String? type;

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _micOn = true;
  bool _cameraOn = true;
  bool _speakerOn = true;

  static const String _doctorImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuArYswFEKWUqY6KXPcK8lNOQPAuiHgksqnGPPxSQ576fLmtElUQtFDiY5tgllEsL6FBt71O2wcpcApw58B-pH3u4Mjqzvbgv2LlOXcneQ5YfGLGJqYUCq9y16ag6EoVYJ6Gn756klumOMkCLcpIsq1npMbPJQBZn9b3pz_91pZMaazsndp79KXLcOrRXZ34duBvYZaBfiqxfr-FTv_5d-5Lf55SlWROK3T2JC0VkPPlbmRiTMmn-Unk';
  static const String _patientImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCU72s8GQlG85GiW4WATEhPVsz2LOvGlpA5IzQGGVfj2kcd5CH9g6yXEsVfqs21w9_YYo0Giit4zs51fw22FObFZJElmDGjGDImhaNSyzNDnLYeu9dw_TahWgsCL-LkX1h8GFpkPEKpIPFuzJKmidt8bTC_GhUxh_p7-d0rUuWVUd-fWxXRZQ59PA4wmaiL0jjzLJHhEVwPkw1_-PXKGNkKrBjOuo8ENsNdaYzmAhjuBA3tVcK0C3uO';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _header(scheme),
            Expanded(
              flex: 3,
              child: _videoArea(scheme),
            ),
            Expanded(
              flex: 2,
              child: _patientPanel(scheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.containerMargin),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 48,
              height: 48,
              child: Image.network(
                _doctorImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    ColoredBox(color: scheme.surfaceContainerHigh, child: const Icon(Icons.person)),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.tr('Dr. Priya Sharma'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                ),
                Text(
                  AppStrings.tr('General Physician'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLg.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.stackSm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.signal_cellular_alt,
                    size: 18, color: scheme.primary),
                const SizedBox(width: 4),
                Text(
                  AppStrings.tr('Good'),
                  style: AppTextStyles.labelLg.copyWith(color: scheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoArea(ColorScheme scheme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          _doctorImageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              ColoredBox(color: scheme.surfaceContainerHighest),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.onSurface.withValues(alpha: 0.6),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: scheme.tertiary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, size: 20, color: scheme.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      AppStrings.tr('Switching to audio to improve quality'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLg
                          .copyWith(color: scheme.onTertiaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: AppSpacing.containerMargin,
          child: Container(
            width: 96,
            height: 128,
            decoration: BoxDecoration(
              color: scheme.surfaceDim,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.surface, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 12),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _cameraOn
                ? Image.network(
                    _patientImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        ColoredBox(color: scheme.surfaceDim),
                  )
                : ColoredBox(
                    color: scheme.surfaceDim,
                    child: const Icon(Icons.person, size: 40),
                  ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.stackMd,
              vertical: AppSpacing.stackSm,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: scheme.surfaceContainerHighest),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _control(
                  scheme,
                  icon: _micOn ? Icons.mic : Icons.mic_off,
                  active: _micOn,
                  onTap: () => setState(() => _micOn = !_micOn),
                ),
                const SizedBox(width: 8),
                _control(
                  scheme,
                  icon: _cameraOn ? Icons.videocam : Icons.videocam_off,
                  active: _cameraOn,
                  onTap: () => setState(() => _cameraOn = !_cameraOn),
                ),
                const SizedBox(width: 8),
                _control(
                  scheme,
                  icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
                  active: _speakerOn,
                  onTap: () => setState(() => _speakerOn = !_speakerOn),
                ),
                Container(
                  width: 1,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: scheme.outlineVariant,
                ),
                _control(
                  scheme,
                  icon: Icons.call_end,
                  active: false,
                  color: scheme.error,
                  iconColor: scheme.onError,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _control(
    ColorScheme scheme, {
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
  }) {
    final bg = color ?? scheme.surfaceContainerHigh;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(
          icon,
          size: 24,
          color: iconColor ?? scheme.onSurface,
        ),
      ),
    );
  }

  Widget _patientPanel(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerMargin,
        AppSpacing.stackSm,
        AppSpacing.containerMargin,
        AppSpacing.gutter,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3))),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, -10),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.tr('Consultation Notes'),
                style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
              ),
              Icon(Icons.info, color: scheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Expanded(
            child: ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: scheme.error.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: scheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.priority_high,
                              size: 18,
                              color: scheme.onError,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.tr('Triage: Priority'),
                            style: AppTextStyles.labelLg
                                .copyWith(color: scheme.onErrorContainer),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'High fever reported for 3 days. Patient flagged for immediate general physician review.',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.medical_information, color: scheme.secondary),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.tr('Reported Symptoms'),
                            style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.stackSm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AppStrings.tr('Fever (102°F)'),
                          AppStrings.tr('Dry Cough'),
                          AppStrings.tr('Fatigue'),
                        ]
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.gutter,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: scheme.surfaceDim),
                                ),
                                child: Text(
                                  s,
                                  style: AppTextStyles.labelLg
                                      .copyWith(color: scheme.onSurface),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.stackSm),
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrescriptionScreen()),
                  ),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.folder_open,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.gutter),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.tr('Previous Records'),
                                style: AppTextStyles.labelLg
                                    .copyWith(color: scheme.onPrimaryContainer),
                              ),
                              Text(
                                AppStrings.tr('2 prescriptions, 1 lab report'),
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: scheme.onPrimaryFixedVariant,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward, color: scheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
