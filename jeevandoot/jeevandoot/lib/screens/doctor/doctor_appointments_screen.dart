import 'package:flutter/material.dart';
import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/api/doctor_service.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/screens/doctor/doctor_patient_case_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class DoctorAppointmentsTab extends StatefulWidget {
  const DoctorAppointmentsTab({super.key});

  @override
  State<DoctorAppointmentsTab> createState() => _DoctorAppointmentsTabState();
}

class _DoctorAppointmentsTabState extends State<DoctorAppointmentsTab> {
  final DoctorService _service = DoctorService(ApiClient.instance);
  String _tab = 'Upcoming';

  List<Consultation> _consultations = const [];
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
      final consultations = await _service.myConsultations();
      if (mounted) {
        setState(() {
          _consultations = consultations;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load your schedule.';
          _loading = false;
        });
      }
    }
  }

  List<Consultation> get _visible {
    final upcoming = _consultations.where((c) =>
        (c.status?.toLowerCase() ?? '') != 'completed' &&
        (c.status?.toLowerCase() ?? '') != 'cancelled').toList();
    final completed = _consultations.where((c) =>
        (c.status?.toLowerCase() ?? '') == 'completed').toList();
    return switch (_tab) {
      'Completed' => completed,
      'Today' => upcoming,
      _ => upcoming,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        title: 'Schedule',
        onTrailing: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No new notifications.')),
          );
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.containerMargin,
              AppSpacing.unit,
              AppSpacing.containerMargin,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointments',
                  style: AppTextStyles.displayHeroMobile
                      .copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                _tabs(scheme),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: AppTextStyles.bodyMd
                                .copyWith(color: scheme.onSurfaceVariant)),
                      )
                    : _visible.isEmpty
                        ? Center(
                            child: Text(
                              'No appointments here.',
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: scheme.onSurfaceVariant),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.containerMargin,
                                0,
                                AppSpacing.containerMargin,
                                AppSpacing.stackMd,
                              ),
                              itemCount: _visible.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.gutter),
                              itemBuilder: (context, index) => _appointmentCard(
                                  context, scheme, _visible[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _tabs(ColorScheme scheme) {
    final tabs = ['Upcoming', 'Completed'];
    return Row(
      children: [
        for (final tab in tabs)
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _tab = tab),
              child: Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _tab == tab ? scheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelLg.copyWith(
                    color:
                        _tab == tab ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  DoctorPatient _asPatient(Consultation c) => DoctorPatient(
        name: c.patientName ?? 'Patient',
        id: 'CON-${c.id}',
        age: 'Not recorded',
        gender: 'Unknown',
        risk: const DoctorRisk(DoctorRiskLevel.low, 'LOW Risk'),
        symptoms: const [],
        waitTime: 'WAITING',
        patientUserId: c.patientUserId,
        consultType: c.type ?? 'Consultation',
      );

  Widget _appointmentCard(
      BuildContext context, ColorScheme scheme, Consultation c) {
    final completed = _tab == 'Completed';
    return SoftCard(
      border: Border(
        left: BorderSide(
            color: completed ? scheme.surfaceContainerHighest : scheme.primary,
            width: 4),
      ),
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.patientName ?? 'Patient',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineMd
                          .copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: CON-${c.id} • ${c.status ?? 'upcoming'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSm.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.unit),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    c.scheduledAt?.isNotEmpty == true
                        ? _shortTime(c.scheduledAt!)
                        : '—',
                    style: AppTextStyles.headlineMd
                        .copyWith(color: scheme.primary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              Icon(Icons.videocam, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  c.type ?? 'Consultation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          if (!completed)
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    label: 'View Case',
                    backgroundColor: scheme.surfaceContainerLowest,
                    foregroundColor: scheme.secondary,
                    border: Border.all(color: scheme.secondary),
                    height: 48,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            DoctorPatientCaseScreen(patient: _asPatient(c)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.gutter),
                Expanded(
                  child: PillButton(
                    label: 'Start Consultation',
                    height: 48,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            DoctorPatientCaseScreen(patient: _asPatient(c)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _shortTime(String iso) {
    final t = DateTime.tryParse(iso);
    if (t == null) return iso;
    final l = t.toLocal();
    String h(int n) => n.toString().padLeft(2, '0');
    return '${h(l.hour)}:${h(l.minute)}';
  }
}