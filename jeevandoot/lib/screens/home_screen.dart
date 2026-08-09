import 'package:flutter/material.dart';
import 'package:jeevandoot/constants.dart';
import 'package:jeevandoot/models/models.dart';
import 'package:jeevandoot/screens/book_consultation_screen.dart';
import 'package:jeevandoot/screens/offline_screen.dart';
import 'package:jeevandoot/screens/profile_screen.dart';
import 'package:jeevandoot/screens/records_screen.dart';
import 'package:jeevandoot/screens/reminders_screen.dart';
import 'package:jeevandoot/screens/self_care_advice_screen.dart';
import 'package:jeevandoot/screens/symptom_checker_screen.dart';
import 'package:jeevandoot/screens/video_call_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/bottom_nav.dart';
import 'package:jeevandoot/widgets/common.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(onNavigateRecords: () => setState(() => _currentIndex = 3)),
          const _HealthTab(),
          const _ConsultTab(),
          const RecordsTab(),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.onNavigateRecords});

  final VoidCallback onNavigateRecords;

  static const String _avatarUrl = AppAssets.patientAvatar;
  static const String _doctorImageUrl = AppAssets.doctorImage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        avatarUrl: _avatarUrl,
        subtitle: 'Ramnagar, Maharashtra',
        onTrailing: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OfflineScreen()),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.unit,
          AppSpacing.containerMargin,
          AppSpacing.stackMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Namaste, ${AppState.patientName} 👋',
              style: AppTextStyles.displayHeroMobile
                  .copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            _voiceHero(context, scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _quickActions(context, scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _upcomingConsultation(context, scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _healthReminder(context, scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _syncStatus(scheme),
          ],
        ),
      ),
    );
  }

  Widget _voiceHero(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.stackMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'How are you feeling today?',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.stackLg),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SymptomCheckerScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic,
                size: 48,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            "Tell us what you're feeling",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLg.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.unit),
          Text(
            'You can speak in your preferred language.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.labelLg.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.gutter),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                context,
                scheme,
                icon: Icons.medical_services,
                bg: scheme.surfaceContainer,
                color: scheme.primary,
                label: 'Check Symptoms',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SymptomCheckerScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: _actionCard(
                context,
                scheme,
                icon: Icons.calendar_month,
                bg: scheme.tertiaryFixed,
                color: scheme.onTertiaryFixed,
                label: 'Book Consultation',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BookConsultationScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gutter),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                context,
                scheme,
                icon: Icons.content_paste,
                bg: scheme.secondaryContainer,
                color: scheme.onSecondaryContainer,
                label: 'My Records',
                onTap: onNavigateRecords,
              ),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: _actionCard(
                context,
                scheme,
                icon: Icons.medication,
                bg: scheme.surfaceContainerHighest,
                color: scheme.onSurfaceVariant,
                label: 'Medicines',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RemindersScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(
    BuildContext context,
    ColorScheme scheme, {
    required IconData icon,
    required Color bg,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 140,
          padding: const EdgeInsets.all(AppSpacing.gutter),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                label,
                style: AppTextStyles.bodyMd.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _upcomingConsultation(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Consultation',
          style: AppTextStyles.labelLg.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.gutter),
        Container(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Image.network(
                        _doctorImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: scheme.surfaceContainerHigh,
                          child: const Icon(Icons.person),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. Priya Sharma',
                          style: AppTextStyles.headlineMd
                              .copyWith(color: scheme.onSurface),
                        ),
                        Text(
                          'General Physician',
                          style: AppTextStyles.bodyMd
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 16, color: scheme.primaryContainer),
                            const SizedBox(width: 4),
                            Text(
                              'Today · 5:30 PM',
                              style: AppTextStyles.labelLg
                                  .copyWith(color: scheme.primaryContainer),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.gutter),
              PillButton(
                label: 'Join Consultation',
                icon: Icons.videocam,
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VideoCallScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _healthReminder(BuildContext context, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medication,
              color: scheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Take medicine',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Today · 8:00 PM',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          StatefulBuilder(
            builder: (context, setLocal) {
              final done = AppState.medicineReminderTaken;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setLocal(() => AppState.medicineReminderTaken = true);
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: done
                          ? scheme.primaryContainer
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.primary, width: 1.5),
                    ),
                    child: Icon(
                      done ? Icons.check : Icons.check_outlined,
                      color: done ? scheme.onPrimaryContainer : scheme.primary,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _syncStatus(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.unit),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sync,
            size: 16,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            'Your data is synced',
            style: AppTextStyles.labelSm.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthTab extends StatelessWidget {
  const _HealthTab();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        avatarUrl: AppAssets.patientAvatar,
        subtitle: 'Health',
        onTrailing: () => openOfflineScreen(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Health',
              style: AppTextStyles.displayHeroMobile
                  .copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            SoftCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RemindersScreen()),
              ),
              child: Row(
                children: [
                  _iconCircle(scheme, Icons.alarm, scheme.primary),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reminders',
                          style: AppTextStyles.headlineMd
                              .copyWith(color: scheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Medicines, hydration and follow-ups',
                          style: AppTextStyles.bodyMd
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.outline),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            SoftCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SelfCareAdviceScreen()),
              ),
              child: Row(
                children: [
                  _iconCircle(scheme, Icons.self_improvement, scheme.tertiary),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Self-Care Advice',
                          style: AppTextStyles.headlineMd
                              .copyWith(color: scheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Recovery tips for home',
                          style: AppTextStyles.bodyMd
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.outline),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            SoftCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SymptomCheckerScreen()),
              ),
              child: Row(
                children: [
                  _iconCircle(scheme, Icons.medical_services, scheme.primaryContainer),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check Symptoms',
                          style: AppTextStyles.headlineMd
                              .copyWith(color: scheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Voice-first triage assistant',
                          style: AppTextStyles.bodyMd
                              .copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.outline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconCircle(ColorScheme scheme, IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
      child: Icon(icon, color: color),
    );
  }
}

class _ConsultTab extends StatelessWidget {
  const _ConsultTab();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        title: 'Consult',
        onTrailing: () => openOfflineScreen(context),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.containerMargin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat,
                  size: 48,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Text(
                'No active consultations',
                style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.unit),
              Text(
                'Book a consultation with a doctor to start chatting.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.stackLg),
              PillButton(
                label: 'Book a Consultation',
                icon: Icons.calendar_month,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BookConsultationScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
