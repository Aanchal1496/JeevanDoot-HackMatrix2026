import 'package:flutter/material.dart';
import 'package:jeevandoot/constants.dart';
import 'package:jeevandoot/models/consultation_models.dart';
import 'package:jeevandoot/models/models.dart';
import 'package:jeevandoot/screens/book_consultation_screen.dart';
import 'package:jeevandoot/screens/consultation/appointment_detail_screen.dart';
import 'package:jeevandoot/screens/consultation/consultations_screen.dart';
import 'package:jeevandoot/screens/offline_screen.dart';
import 'package:jeevandoot/screens/profile_screen.dart';
import 'package:jeevandoot/screens/records_screen.dart';
import 'package:jeevandoot/screens/reminders_screen.dart';
import 'package:jeevandoot/screens/self_care_advice_screen.dart';
import 'package:jeevandoot/screens/symptom_checker_screen.dart';
import 'package:jeevandoot/screens/video_call_screen.dart';
import 'package:jeevandoot/screens/consultation_hub_screen.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/bottom_nav.dart';
import 'package:jeevandoot/widgets/common.dart';
import 'package:jeevandoot/widgets/consultation_widgets.dart';

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

class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.onNavigateRecords});

  final VoidCallback onNavigateRecords;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  static const String _avatarUrl = AppAssets.patientAvatar;

  List<ConsultationAppointment> _upcoming = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await fetchUpcomingConsultations();
      if (!mounted) return;
      final sorted = [...list]..sort((a, b) {
          final aStart = a.start;
          final bStart = b.start;
          if (aStart == null && bStart == null) return 0;
          if (aStart == null) return 1;
          if (bStart == null) return -1;
          return aStart.compareTo(bStart);
        });
      setState(() {
        _upcoming = sorted;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load consultation details.';
      });
    }
  }

  Future<void> _openBooking() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BookConsultationScreen()),
    );
    if (mounted) _load();
  }

  Future<void> _openAppointments() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ConsultationsScreen()),
    );
    if (mounted) _load();
  }

  void _openDetail(ConsultationAppointment a) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: a)),
    );
  }

  void _join(ConsultationAppointment a) {
    if (!a.canJoinNow) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          doctorName: a.doctorName,
          specialization: a.specialization,
          photoUrl: a.photoUrl,
          meetingId: a.meetingId,
          isAudioOnly: a.consultType.contains('Audio'),
        ),
      ),
    );
  }

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
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerMargin,
            AppSpacing.unit,
            AppSpacing.containerMargin,
            AppSpacing.stackMd,
          ),
          children: [
            Text(
              'Namaste, ${AppState.patientName} 👋',
              style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            _voiceHero(context, scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _quickActions(context, scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _upcomingSection(scheme),
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
                MaterialPageRoute(builder: (_) => const SymptomCheckerScreen()),
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
              child: const Icon(Icons.mic, size: 48, color: AppColors.onPrimary),
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

  // -- Quick actions ---------------------------------------------------------

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
                  MaterialPageRoute(builder: (_) => const SymptomCheckerScreen()),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: _actionCard(
                context,
                scheme,
                icon: Icons.video_call,
                bg: scheme.primaryContainer.withValues(alpha: 0.35),
                color: scheme.primary,
                label: 'Book Consultation',
                onTap: _openBooking,
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
                icon: Icons.event_available,
                bg: scheme.tertiaryFixed,
                color: scheme.onTertiaryFixed,
                label: 'My Appointments',
                onTap: _openAppointments,
              ),
            ),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(
              child: _actionCard(
                context,
                scheme,
                icon: Icons.content_paste,
                bg: scheme.secondaryContainer,
                color: scheme.onSecondaryContainer,
                label: 'Health Records',
                onTap: widget.onNavigateRecords,
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
                icon: Icons.battery_saver,
                bg: scheme.surfaceContainer,
                color: scheme.onSurface,
                label: 'Low-Bandwidth Consult',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ConsultationHubScreen(role: 'patient'),
                  ),
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
              BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1)),
              BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 8)),
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

  // -- Upcoming consultations -------------------------------------------------

  Widget _upcomingSection(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Consultations',
              style: AppTextStyles.labelLg.copyWith(color: scheme.onSurfaceVariant),
            ),
            TextButton(
              onPressed: _openAppointments,
              style: TextButton.styleFrom(
                foregroundColor: scheme.primary,
                textStyle: AppTextStyles.labelLg,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gutter),
        if (_loading)
          const ConsultationLoading(count: 2)
        else if (_error != null)
          ConsultationError(title: _error!, onRetry: _load)
        else if (_upcoming.isEmpty)
          ConsultationEmpty(
            icon: Icons.event_available,
            title: 'No upcoming consultations',
            message: 'Consult a qualified doctor remotely — choose a specialty, pick a time and get a secure video consultation.',
            ctaLabel: 'Book a Consultation',
            onCta: _openBooking,
          )
        else ...[
          _nextConsultationCard(context, scheme, _upcoming.first),
          if (_upcoming.length > 1) ...[
            const SizedBox(height: AppSpacing.gutter),
            for (final a in _upcoming.skip(1).take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
                child: AppointmentCard(
                  appointment: a,
                  onTap: () => _openDetail(a),
                  onJoin: () => _join(a),
                ),
              ),
          ],
        ],
      ],
    );
  }

  Widget _nextConsultationCard(
    BuildContext context,
    ColorScheme scheme,
    ConsultationAppointment a,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR NEXT CONSULTATION',
            style: AppTextStyles.labelSm.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: a.photoUrl.isEmpty
                      ? ColoredBox(
                          color: scheme.surfaceContainerHigh,
                          child: const Icon(Icons.person),
                        )
                      : Image.network(
                          a.photoUrl,
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
                      a.doctorName,
                      style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                    ),
                    Text(
                      a.specialization,
                      style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: scheme.primaryContainer),
                        const SizedBox(width: 4),
                        Text(
                          '${a.relativeDayLabel} • ${a.time}',
                          style: AppTextStyles.labelLg.copyWith(color: scheme.primaryContainer),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.gutter),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openDetail(a),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    side: BorderSide(color: scheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: PillButton(
                  label: a.canJoinNow
                      ? 'Join Consultation'
                      : (a.joinHint.isEmpty ? 'Join Consultation' : a.joinHint),
                  icon: Icons.videocam,
                  height: AppSpacing.touchTargetMin,
                  backgroundColor: a.canJoinNow ? scheme.primary : scheme.surfaceContainerHighest,
                  foregroundColor: a.canJoinNow ? scheme.onPrimary : scheme.onSurfaceVariant,
                  onPressed: a.canJoinNow ? () => _join(a) : null,
                ),
              ),
            ],
          ),
        ],
      ),
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
            child: Icon(Icons.medication, color: scheme.onSecondaryContainer),
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
                      color: done ? scheme.primaryContainer : Colors.transparent,
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
              style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.onSurface),
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
                          style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Medicines, hydration and follow-ups',
                          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
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
                          style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Recovery tips for home',
                          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
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
                          style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Voice-first triage assistant',
                          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
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
                child: Icon(Icons.chat, size: 48, color: scheme.primary),
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
