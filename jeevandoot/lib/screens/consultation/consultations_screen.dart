import 'package:flutter/material.dart';
import 'package:jeevandoot/models/consultation_models.dart';
import 'package:jeevandoot/screens/book_consultation_screen.dart';
import 'package:jeevandoot/screens/consultation/appointment_detail_screen.dart';
import 'package:jeevandoot/screens/video_call_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/consultation_widgets.dart';
import 'package:jeevandoot/services/backend.dart';

/// Patient's appointment list: upcoming and history.
class ConsultationsScreen extends StatefulWidget {
  const ConsultationsScreen({super.key});

  @override
  State<ConsultationsScreen> createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends State<ConsultationsScreen> {
  bool _upcoming = true;
  List<ConsultationAppointment> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = _upcoming
          ? await fetchUpcomingConsultations()
          : await fetchConsultationHistory();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load consultation details.';
      });
    }
  }

  void _switchTab(bool upcoming) {
    if (_upcoming == upcoming) return;
    setState(() => _upcoming = upcoming);
    _load();
  }

  void _openDetail(ConsultationAppointment a) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: a)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        title: 'My Appointments',
        onTrailing: () => openOfflineScreen(context),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.containerMargin,
            AppSpacing.stackMd,
            AppSpacing.containerMargin,
            AppSpacing.stackLg,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(child: _tab(scheme, true, 'Upcoming')),
                  Expanded(child: _tab(scheme, false, 'History')),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            if (_loading)
              const ConsultationLoading()
            else if (_error != null)
              ConsultationError(title: _error!, onRetry: _load)
            else if (_items.isEmpty)
              _upcoming
                  ? ConsultationEmpty(
                      icon: Icons.event_available,
                      title: 'No upcoming consultations',
                      message:
                          'Book a consultation with a doctor to see it here.',
                      ctaLabel: 'Book a Consultation',
                      onCta: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BookConsultationScreen(),
                        ),
                      ),
                    )
                  : ConsultationEmpty(
                      icon: Icons.history,
                      title: 'No past consultations',
                      message: 'Your completed and cancelled consultations will appear here.',
                    )
            else
              for (var i = 0; i < _items.length; i++) ...[
                AppointmentCard(
                  appointment: _items[i],
                  onTap: () => _openDetail(_items[i]),
                  // Join is only offered for active appointments.
                  onJoin: _items[i].isActiveAppointment
                      ? () => _join(_items[i])
                      : null,
                ),
                if (i < _items.length - 1) const SizedBox(height: AppSpacing.gutter),
              ],
          ],
        ),
      ),
    );
  }

  Widget _tab(ColorScheme scheme, bool upcoming, String label) {
    final selected = _upcoming == upcoming;
    return InkWell(
      onTap: () => _switchTab(upcoming),
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? scheme.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: selected
              ? [BoxShadow(color: scheme.primary.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelLg.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
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
}
