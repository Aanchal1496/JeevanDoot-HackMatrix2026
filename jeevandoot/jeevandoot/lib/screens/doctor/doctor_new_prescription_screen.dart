import 'package:flutter/material.dart';
import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/api/doctor_service.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class DoctorNewPrescriptionScreen extends StatefulWidget {
  const DoctorNewPrescriptionScreen({super.key, required this.patient});

  final DoctorPatient patient;

  @override
  State<DoctorNewPrescriptionScreen> createState() =>
      _DoctorNewPrescriptionScreenState();
}

class _DoctorNewPrescriptionScreenState
    extends State<DoctorNewPrescriptionScreen> {
  final DoctorService _service = DoctorService(ApiClient.instance);
  final TextEditingController _searchController = TextEditingController();
  final List<MedicineEntry> _medicines = [];
  String _searchQuery = '';
  bool _showResults = false;
  bool _submitting = false;

  List<String> get _results => _searchQuery.isEmpty
      ? []
      : kMedicineSearchResults
          .where((m) => m.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addMedicine(String name) {
    setState(() {
      _medicines.add(MedicineEntry(
        name: name,
        category: 'Tablet',
        dosage: '1',
        unit: 'mg',
        morning: 1,
        afternoon: 0,
        night: 1,
        days: 5,
        instructions: 'After food',
      ));
      _searchController.clear();
      _searchQuery = '';
      _showResults = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _updateDosage(MedicineEntry medicine, int index,
      {int? morning, int? afternoon, int? night}) {
    setState(() {
      medicine.morning = morning ?? medicine.morning;
      medicine.afternoon = afternoon ?? medicine.afternoon;
      medicine.night = night ?? medicine.night;
    });
  }

  void _updateDays(MedicineEntry medicine, int delta) {
    setState(() {
      medicine.days = (medicine.days + delta).clamp(1, 30);
    });
  }

  void _removeMedicine(int index) {
    setState(() => _medicines.removeAt(index));
  }

  Future<void> _save() async {
    final patientUserId = widget.patient.patientUserId;
    if (patientUserId == null || _medicines.isEmpty || _submitting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add at least one medicine to save the prescription.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final consultation = await _service.createConsultation(
        patientUserId: patientUserId,
        scheduledAt: DateTime.now().toIso8601String(),
      );
      final consultationId = consultation['id'] as int;
      await _service.createPrescription(
        consultationId: consultationId,
        patientUserId: patientUserId,
        diagnosis: 'Consultation diagnosis',
        instructions: '',
        medicines: [
          for (final m in _medicines)
            {
              'medicine_name': m.name,
              'dosage': '${m.dosage}${m.unit}',
              'frequency': 'M:${m.morning} A:${m.afternoon} N:${m.night}',
              'duration': '${m.days} days',
              'timing': 'Morning/Afternoon/Night',
              'before_after_food': m.instructions,
            },
        ],
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save prescription: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        showBack: true,
        title: 'New Prescription',
        hideTrailing: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.containerMargin),
              children: [
                _searchCard(scheme),
                const SizedBox(height: AppSpacing.stackMd),
                if (_showResults && _results.isNotEmpty) ...[
                  for (final medicine in _results)
                    InkWell(
                      onTap: () => _addMedicine(medicine),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.unit),
                        padding: const EdgeInsets.all(AppSpacing.gutter),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.medication,
                                size: 20, color: scheme.primary),
                            const SizedBox(width: AppSpacing.gutter),
                            Expanded(
                              child: Text(
                                medicine,
                                style: AppTextStyles.bodyMd
                                    .copyWith(color: scheme.onSurface),
                              ),
                            ),
                            Icon(Icons.add_circle_outline,
                                size: 22, color: scheme.primary),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.stackSm),
                ],
                Text(
                  'ADDED MEDICINES (${_medicines.length})',
                  style: AppTextStyles.labelSm.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppSpacing.unit),
                if (_medicines.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.gutter),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.medication_outlined,
                              size: 40, color: scheme.onSurfaceVariant),
                          const SizedBox(height: AppSpacing.unit),
                          Text(
                            'Search and add medicines above',
                            style: AppTextStyles.bodyMd
                                .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < _medicines.length; i++)
                    _medicineCard(scheme, _medicines[i], i),
              ],
            ),
          ),
          if (_medicines.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerMargin,
                AppSpacing.unit,
                AppSpacing.containerMargin,
                AppSpacing.containerMargin,
              ),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                  top: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: PillButton(
                label: _submitting ? 'Saving…' : 'Save Prescription',
                icon: Icons.check_circle_outline,
                height: 48,
                onPressed: _submitting ? null : _save,
              ),
            ),
        ],
      ),
    );
  }

  Widget _searchCard(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SEARCH MEDICINES',
          style: AppTextStyles.labelSm.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.unit),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() {
            _searchQuery = value;
            _showResults = value.isNotEmpty;
          }),
          decoration: InputDecoration(
            hintText: 'Search medicine name...',
            hintStyle: AppTextStyles.bodyMd
                .copyWith(color: scheme.onSurfaceVariant, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _showResults = false;
                      });
                    },
                  )
                : null,
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
    );
  }

  Widget _medicineCard(ColorScheme scheme, MedicineEntry medicine, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication, size: 20, color: scheme.primary),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.name,
                      style: AppTextStyles.labelLg
                          .copyWith(color: scheme.onSurface),
                    ),
                    Text(
                      '${medicine.category} · ${medicine.dosage}${medicine.unit}',
                      style: AppTextStyles.labelSm
                          .copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: scheme.error),
                onPressed: () => _removeMedicine(index),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              _timeStepper(scheme, 'Morning', medicine.morning, (v) =>
                  _updateDosage(medicine, index, morning: v)),
              const SizedBox(width: AppSpacing.unit),
              _timeStepper(scheme, 'Afternoon', medicine.afternoon, (v) =>
                  _updateDosage(medicine, index, afternoon: v)),
              const SizedBox(width: AppSpacing.unit),
              _timeStepper(scheme, 'Night', medicine.night, (v) =>
                  _updateDosage(medicine, index, night: v)),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Duration',
                style: AppTextStyles.bodyMd.copyWith(
                  color: scheme.onSurface,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _updateDays(medicine, -1),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Icon(Icons.remove, size: 18, color: scheme.onSurface),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                child: Text(
                  '${medicine.days} days',
                  style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
                ),
              ),
              InkWell(
                onTap: () => _updateDays(medicine, 1),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add,
                      size: 18, color: scheme.onPrimaryContainer),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeStepper(
    ColorScheme scheme,
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => onChanged((value - 1).clamp(0, 9)),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Icon(Icons.remove, size: 16, color: scheme.onSurface),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Center(
                    child: Text(
                      '$value',
                      style: AppTextStyles.labelLg
                          .copyWith(color: scheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => onChanged((value + 1).clamp(0, 9)),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add,
                        size: 16, color: scheme.onPrimaryContainer),
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
