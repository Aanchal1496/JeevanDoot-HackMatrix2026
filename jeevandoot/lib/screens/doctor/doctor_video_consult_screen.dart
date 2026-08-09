import 'package:flutter/material.dart';
import 'package:jeevandoot/constants.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/screens/doctor/doctor_ai_suggested_questions_screen.dart';
import 'package:jeevandoot/screens/doctor/doctor_consultation_info_panel_screen.dart';
import 'package:jeevandoot/screens/doctor/doctor_consultation_notes_screen.dart';
import 'package:jeevandoot/screens/doctor/doctor_symptom_timeline_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';

class DoctorVideoConsultScreen extends StatefulWidget {
  const DoctorVideoConsultScreen({super.key, required this.patient});

  final DoctorPatient patient;

  @override
  State<DoctorVideoConsultScreen> createState() =>
      _DoctorVideoConsultScreenState();
}

class _DoctorVideoConsultScreenState extends State<DoctorVideoConsultScreen> {
  bool _micOn = true;
  bool _cameraOn = true;
  bool _speakerOn = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final patient = widget.patient;
    return Scaffold(
      backgroundColor: scheme.inverseSurface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            AppAssets.patientCaseImage,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                ColoredBox(color: scheme.inverseSurface),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.inverseSurface.withValues(alpha: 0.6),
                  Colors.transparent,
                  scheme.inverseSurface.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          _topHeader(scheme, patient),
          _connectionAlert(scheme),
          _selfPreview(scheme),
          _controls(scheme, patient),
        ],
      ),
    );
  }

  Widget _topHeader(ColorScheme scheme, DoctorPatient patient) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter,
                    vertical: AppSpacing.unit,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person,
                                color: Colors.white,
                                size: 24),
                          ),
                          const SizedBox(width: AppSpacing.gutter),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelLg
                                      .copyWith(color: scheme.onSurface),
                                ),
                                Text(
                                  'ID: P-98234 • ${patient.age} Y',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelSm
                                      .copyWith(color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                        const SizedBox(height: AppSpacing.unit),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.errorContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning,
                                  size: 14, color: scheme.onErrorContainer),
                              const SizedBox(width: 4),
                              Text(
                                patient.risk.label.toUpperCase(),
                                style: AppTextStyles.labelSm.copyWith(
                                  color: scheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.unit,
                ),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.signal_cellular_alt,
                        size: 16, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Good Connection',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSm
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _connectionAlert(ColorScheme scheme) {
    return Positioned(
      top: 110,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.containerMargin),
          padding: const EdgeInsets.all(AppSpacing.gutter),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
            boxShadow: const [
              BoxShadow(color: Color(0x1A000000), blurRadius: 24),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x33FEF08A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off, color: Color(0xFFCA8A04)),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAB308),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Weak Connection',
                          style: AppTextStyles.labelLg
                              .copyWith(color: scheme.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Poor network detected. Switching to audio to preserve call quality...',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selfPreview(ColorScheme scheme) {
    return Positioned(
      right: AppSpacing.containerMargin,
      bottom: 140,
      child: Container(
        width: 112,
        height: 160,
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.surface, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 24),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_cameraOn)
              Image.network(
                AppAssets.doctorAvatar,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    ColoredBox(color: scheme.surfaceContainer),
              )
            else
              ColoredBox(
                color: scheme.surfaceContainer,
                child: const Icon(Icons.person, size: 40),
              ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: scheme.inverseSurface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  _micOn ? Icons.mic : Icons.mic_off,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls(ColorScheme scheme, DoctorPatient patient) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.containerMargin,
            right: AppSpacing.containerMargin,
            bottom: AppSpacing.containerMargin,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      _roundControl(scheme,
                          icon: _micOn ? Icons.mic : Icons.mic_off,
                          onTap: () => setState(() => _micOn = !_micOn)),
                      const SizedBox(width: 4),
                      _roundControl(scheme,
                          icon: _cameraOn ? Icons.videocam : Icons.videocam_off,
                          onTap: () => setState(() => _cameraOn = !_cameraOn)),
                      const SizedBox(width: 4),
                      _roundControl(scheme,
                          icon: _speakerOn ? Icons.volume_up : Icons.volume_off,
                          onTap: () => setState(() => _speakerOn = !_speakerOn)),
                      const SizedBox(width: 4),
                      _roundControl(scheme,
                          icon: Icons.edit_note,
                          showDot: true,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  DoctorConsultationNotesScreen(patient: patient),
                            ),
                          )),
                      const SizedBox(width: 4),
                      _roundControl(scheme,
                          icon: Icons.more_vert,
                          onTap: () {
                            showModalBottomSheet<void>(
                              context: context,
                              backgroundColor: scheme.surface,
                              builder: (_) => _CallMenuSheet(patient: patient),
                            );
                          }),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.stackSm),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Call ended.')),
                    );
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: scheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x4DBA1A1A), blurRadius: 12),
                      ],
                    ),
                    child: const Icon(Icons.call_end,
                        color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roundControl(
    ColorScheme scheme, {
    required IconData icon,
    required VoidCallback onTap,
    bool showDot = false,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 24, color: scheme.onSurface),
            if (showDot)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CallMenuSheet extends StatelessWidget {
  const _CallMenuSheet({required this.patient});

  final DoctorPatient patient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final options = [
      (
        icon: Icons.info_outline,
        label: 'Patient Information',
        screen: DoctorConsultationInfoPanelScreen(
            patient: patient, fromVideo: true),
      ),
      (
        icon: Icons.history,
        label: 'Symptom Timeline',
        screen: DoctorSymptomTimelineScreen(patient: patient),
      ),
      (
        icon: Icons.question_answer,
        label: 'Suggested Questions',
        screen: DoctorAISuggestedQuestionsScreen(patient: patient),
      ),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Call Options',
              style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.gutter),
            for (final option in options)
              ListTile(
                leading: Icon(option.icon, color: scheme.primary),
                title: Text(
                  option.label,
                  style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurface),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => option.screen),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
