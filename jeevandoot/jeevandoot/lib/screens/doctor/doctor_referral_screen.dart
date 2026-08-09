import 'package:flutter/material.dart';
import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/api/doctor_service.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class DoctorReferralScreen extends StatefulWidget {
  const DoctorReferralScreen({super.key, required this.patient});

  final DoctorPatient patient;

  @override
  State<DoctorReferralScreen> createState() => _DoctorReferralScreenState();
}

class _DoctorReferralScreenState extends State<DoctorReferralScreen> {
  final DoctorService _service = DoctorService(ApiClient.instance);
  String _urgency = 'Urgent';
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _facilityController = TextEditingController();
  String _selectedFacility = '';
  bool _submitting = false;

  static const _facilities = [
    'JeevanDoot General Hospital — Cardiology',
    'City Care Hospital — Neurology',
    'Apollo Heart Institute — Cardiac Surgery',
    'Sunrise Orthopedic Center',
  ];

  List<String> get _filteredFacilities => _selectedFacility.isEmpty
      ? []
      : _facilities
          .where((f) => f.toLowerCase().contains(_selectedFacility.toLowerCase()))
          .toList();

  String get _urgencyCode => switch (_urgency) {
        'Urgent' => 'URGENT',
        'Emergency' => 'EMERGENCY',
        _ => 'ROUTINE',
      };

  Future<void> _submit() async {
    final patientUserId = widget.patient.patientUserId;
    if (patientUserId == null || _submitting) return;
    setState(() => _submitting = true);
    final parts = _selectedFacility.split('—');
    try {
      await _service.createReferral(
        patientUserId: patientUserId,
        urgency: _urgencyCode,
        hospital: parts.isNotEmpty ? parts[0].trim() : _selectedFacility,
        specialist: parts.length > 1 ? parts[1].trim() : null,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral submitted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit referral: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _facilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        showBack: true,
        title: 'Referral Patient',
        hideTrailing: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _patientCard(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _urgencyCard(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _reasonCard(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _facilityCard(scheme),
            const SizedBox(height: AppSpacing.stackMd),
            _submitBar(scheme),
          ],
        ),
      ),
    );
  }

  Widget _patientCard(ColorScheme scheme) {
    final patient = widget.patient;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 24),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
                ),
                Text(
                  '${patient.age} yrs · ${patient.gender} · ${patient.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _urgencyCard(ColorScheme scheme) {
    final options = ['Urgent', 'Emergency', 'Routine'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'REFERRAL URGENCY',
          style: AppTextStyles.labelSm.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.unit),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              for (final option in options)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _urgency = option),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _urgency == option
                            ? scheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        option,
                        style: AppTextStyles.labelLg.copyWith(
                          color: _urgency == option
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reasonCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REASON FOR REFERRAL',
            style: AppTextStyles.labelSm.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.unit),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe the reason for referral...',
              hintStyle: AppTextStyles.bodyMd
                  .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
              filled: true,
              fillColor: scheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.all(AppSpacing.gutter),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _facilityCard(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECT FACILITY',
            style: AppTextStyles.labelSm.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.unit),
          TextField(
            controller: _facilityController,
            onChanged: (value) => setState(() => _selectedFacility = value),
            decoration: InputDecoration(
              hintText: 'Search hospital or department',
              hintStyle: AppTextStyles.bodyMd
                  .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant),
              filled: true,
              fillColor: scheme.surfaceContainerLow,
              contentPadding: const EdgeInsets.all(AppSpacing.gutter),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_filteredFacilities.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.stackSm),
            for (final facility in _filteredFacilities)
              InkWell(
                onTap: () {
                  _facilityController.text = facility;
                  _selectedFacility = facility;
                  setState(() {});
                  FocusScope.of(context).unfocus();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.unit),
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedFacility == facility
                          ? scheme.primary
                          : scheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_hospital,
                          size: 20, color: scheme.primary),
                      const SizedBox(width: AppSpacing.gutter),
                      Expanded(
                        child: Text(
                          facility,
                          style: AppTextStyles.bodyMd
                              .copyWith(color: scheme.onSurface, fontSize: 14),
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 20, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _submitBar(ColorScheme scheme) {
    return PillButton(
      label: _submitting ? 'Submitting…' : 'Submit Referral',
      icon: Icons.send,
      height: 48,
      onPressed: _submitting ? null : _submit,
    );
  }
}
