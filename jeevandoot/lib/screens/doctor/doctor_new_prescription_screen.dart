import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/screens/doctor/doctor_prescription_review_screen.dart';
import 'package:jeevandoot/services/api_client.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

enum _SaveState { idle, saving, saved, offline }

/// Built-in prescription writer. The server is the source of truth: drafts
/// autosave to the backend and locally; only an explicit doctor confirmation
/// can issue a prescription.
class DoctorNewPrescriptionScreen extends StatefulWidget {
  const DoctorNewPrescriptionScreen({super.key, required this.patient});

  final DoctorPatient patient;

  @override
  State<DoctorNewPrescriptionScreen> createState() =>
      _DoctorNewPrescriptionScreenState();
}

class _DoctorNewPrescriptionScreenState
    extends State<DoctorNewPrescriptionScreen> {
  static const List<String> _kFrequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Four times daily',
    'Every 4 hours',
    'Every 6 hours',
    'Every 8 hours',
    'Every 12 hours',
    'As directed',
    'Custom…',
  ];
  static const List<String> _kDurationUnits = [
    'days',
    'weeks',
    'months',
    'until finished',
    'as directed',
  ];
  static const List<String> _kTimings = [
    'Before food',
    'After food',
    'With food',
    'Empty stomach',
    'At bedtime',
    'Morning',
    'Evening',
    'Any time',
    'Custom',
  ];
  static const List<String> _kForms = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Drops',
    'Cream',
    'Injection',
    'Ointment',
    'Inhaler',
    'Solution',
    'Suspension',
  ];
  static const List<String> _kRoutes = [
    'Oral',
    'Topical',
    'Sublingual',
    'Inhaled',
    'Ophthalmic',
    'Otic',
    'Nasal',
    'Rectal',
    'Other',
  ];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Prescription? _draft;
  List<Medicine> _common = const [];
  List<Medicine> _searchResults = const [];
  List<Prescription> _history = const [];
  List<String> _allergies = const [];
  Prescription? _pendingDraft; // offered via the draft-recovery banner
  bool _loading = true;
  bool _searching = false;
  bool _showResults = false;
  _SaveState _saveState = _SaveState.idle;
  Timer? _debounce;
  Timer? _notesTimer;
  int _searchSeq = 0;
  final List<Map<String, dynamic>> _warnings = [];

  String get _patientId =>
      widget.patient.patientId.isNotEmpty ? widget.patient.patientId : widget.patient.id;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _notesTimer?.cancel();
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Patient's recorded allergies (surfaced prominently per the safety
    // rules) come from the pre-consultation case file.
    try {
      final file = await fetchCaseFile(_patientId);
      if (mounted) _allergies = file.history.allergies;
    } catch (_) {}

    try {
      final results = await Future.wait([
        fetchCommonMedicines(),
        fetchPrescriptionHistory(_patientId),
      ]);
      if (!mounted) return;
      _common = (results[0] as List<Medicine>).isEmpty
          ? const []
          : results[0] as List<Medicine>;
      _history = results[1] as List<Prescription>;
    } catch (_) {
      // Offline: quick select falls back to bundled demo medicines below.
      if (!mounted) return;
      _common = const [];
      _history = const [];
    }

    // Draft recovery: prefer the backend draft (server is source of truth),
    // then the locally-preserved draft for offline recovery.
    Prescription? backendDraft;
    try {
      backendDraft = await fetchPrescriptionDraft(_patientId);
    } catch (_) {
      backendDraft = null;
    }
    final localDraft = await loadLocalDraft(_patientId);
    final recovered = backendDraft ??
        (localDraft != null && localDraft.isDraft ? localDraft : null);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (recovered != null) {
        _pendingDraft = recovered;
      } else {
        _notesController.text = '';
      }
    });
  }

  // -------------------------------------------------------------------------
  // Draft lifecycle
  // -------------------------------------------------------------------------

  Future<Prescription> _ensureDraft() async {
    if (_draft != null) return _draft!;
    final draft = await createPrescriptionDraft(patientId: _patientId);
    return draft;
  }

  void _continueDraft(Prescription draft) {
    setState(() {
      _draft = draft;
      _pendingDraft = null;
      _notesController.text = draft.additionalInstructions;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Draft restored for ${widget.patient.name}.')),
    );
  }

  Future<void> _discardDraft() async {
    final draft = _pendingDraft;
    if (draft == null) {
      setState(() => _pendingDraft = null);
      return;
    }
    try {
      await _clearLocalDraft();
      if (draft.isDraft) {
        await _safeCancel(draft.id);
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _pendingDraft = null);
  }

  Future<void> _clearLocalDraft() => clearLocalDraft(_patientId);

  Future<void> _safeCancel(String prescriptionId) async {
    try {
      await ApiClient.instance.post(
        '/api/doctor/prescriptions/$prescriptionId/cancel',
        {'reason': 'Draft discarded by doctor.'},
      );
    } catch (_) {}
  }

  // -------------------------------------------------------------------------
  // Autosave
  // -------------------------------------------------------------------------

  Future<void> _autosaveNotes() async {
    final draft = _draft;
    if (draft == null) return;
    _notesTimer?.cancel();
    _notesTimer = Timer(const Duration(milliseconds: 700), () async {
      if (!mounted) return;
      setState(() => _saveState = _SaveState.saving);
      try {
        final updated = await savePrescriptionNotes(
          prescriptionId: draft.id,
          additionalInstructions: _notesController.text,
        );
        await saveLocalDraft(_patientId, _prescriptionToJson(updated));
        if (!mounted) return;
        setState(() {
          _draft = updated;
          _saveState = _SaveState.saved;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _saveState = _SaveState.offline);
      }
    });
  }

  Map<String, dynamic> _prescriptionToJson(Prescription rx) {
    return {
      'id': rx.id,
      'status': rx.status.apiValue,
      'additional_instructions': rx.additionalInstructions,
      'medicines': rx.medicines.map((m) => {
            'id': m.id,
            'medicine_id': m.medicineId,
            'name': m.name,
            'generic_name': m.genericName,
            'strength': m.strength,
            'dosage_form': m.dosageForm,
            'dose': m.dose,
            'frequency': m.frequency,
            'duration': m.duration,
            'duration_unit': m.durationUnit,
            'route': m.route,
            'timing': m.timing,
            'instructions': m.instructions,
          }).toList(),
    };
  }

  // -------------------------------------------------------------------------
  // Medicine search
  // -------------------------------------------------------------------------

  void _onSearchChanged(String value) {
    setState(() {
      _showResults = value.isNotEmpty;
      _searching = value.isNotEmpty;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _search);
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = const [];
        _searching = false;
      });
      return;
    }
    final seq = ++_searchSeq;
    try {
      final results = await medicineSearch(query);
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    } catch (_) {
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _searchResults = kMedicineSearchResults
            .where((m) => m.toLowerCase().contains(query.toLowerCase()))
            .map((m) => Medicine(
                  id: '',
                  name: m,
                  genericName: m,
                  brandName: '',
                  strength: '',
                  dosageForm: 'Tablet',
                  route: 'Oral',
                  category: '',
                  active: true,
                  quickSelect: false,
                ))
            .toList();
        _searching = false;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Medicine form (add / edit)
  // -------------------------------------------------------------------------

  Future<void> _openMedicineForm({Medicine? medicine, PrescriptionItem? edit}) async {
    final scheme = Theme.of(context).colorScheme;
    final initialMedicine = medicine;
    final edited = edit;

    // Wait for the draft so item mutations have an id.
    Prescription? draft = _draft;
    if (draft == null && initialMedicine != null) {
      try {
        draft = await _ensureDraft();
        await saveLocalDraft(_patientId, _prescriptionToJson(draft));
      } catch (_) {
        draft = null;
      }
      if (!mounted) return;
      if (draft == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to save prescription. Your draft is preserved locally. '
              'Retry when connection is restored.',
            ),
          ),
        );
        return;
      }
      setState(() => _draft = draft);
    }

    if (!mounted) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _MedicineFormSheet(
        medicine: initialMedicine,
        edit: edited,
        frequencies: _kFrequencies,
        durationUnits: _kDurationUnits,
        timings: _kTimings,
        forms: _kForms,
        routes: _kRoutes,
      ),
    );
    if (result == null || !mounted) return;
    await _applyMedicineResult(result, edited: edited);
  }

  Future<void> _applyMedicineResult(
    Map<String, dynamic> result, {
    PrescriptionItem? edited,
  }) async {
    var draft = _draft;
    if (draft == null) {
      // The add flow may have been entered without a draft (e.g. the header
      // "+" button). Create it so the item has somewhere to attach instead of
      // silently dropping the medicine.
      try {
        draft = await _ensureDraft();
        await saveLocalDraft(_patientId, _prescriptionToJson(draft));
      } catch (_) {
        if (!mounted) return;
        setState(() => _saveState = _SaveState.offline);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to save prescription. Your draft is preserved locally. '
              'Retry when connection is restored.',
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      setState(() => _draft = draft);
    }
    setState(() {
      _saveState = _SaveState.saving;
      _warnings.clear();
    });
    try {
      if (edited != null && edited.id != null) {
        final updated = await updatePrescriptionItem(
          prescriptionId: draft.id,
          itemId: edited.id!,
          fields: {
            'strength': result['strength'],
            'dosage_form': result['dosageForm'],
            'dose': result['dose'],
            'frequency': result['frequency'],
            'duration': result['duration'],
            'duration_unit': result['durationUnit'],
            'route': result['route'],
            'timing': result['timing'],
            'instructions': result['instructions'],
          },
        );
        await saveLocalDraft(_patientId, _prescriptionToJson(updated));
        if (!mounted) return;
        setState(() {
          _draft = updated;
          _saveState = _SaveState.saved;
        });
      } else {
        final medicineId = result['medicineId'] as String?;
        if (medicineId == null || medicineId.isEmpty) {
          if (!mounted) return;
          setState(() => _saveState = _SaveState.idle);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Search and select a medicine first.')),
          );
          return;
        }
        final res = await addPrescriptionItem(
          prescriptionId: draft.id,
          medicineId: medicineId,
          genericName: result['genericName'] as String?,
          strength: result['strength'] as String?,
          dosageForm: result['dosageForm'] as String?,
          dose: result['dose'] as String,
          frequency: result['frequency'] as String,
          duration: result['duration'] as String?,
          durationUnit: result['durationUnit'] as String? ?? 'days',
          route: result['route'] as String,
          timing: result['timing'] as String?,
          instructions: result['instructions'] as String?,
        );
        await saveLocalDraft(_patientId, _prescriptionToJson(res.prescription));
        if (!mounted) return;
        setState(() {
          _draft = res.prescription;
          _warnings.addAll(res.warnings.cast<Map<String, dynamic>>());
          _saveState = _SaveState.saved;
          _searchController.clear();
          _showResults = false;
          _searchResults = const [];
        });
        FocusScope.of(context).unfocus();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saveState = _SaveState.offline);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saveState = _SaveState.offline);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Connection lost — draft saved locally. Waiting for connection…',
          ),
        ),
      );
    }
  }

  Future<void> _editMedicine(PrescriptionItem item) async {
    await _openMedicineForm(edit: item);
  }

  Future<void> _removeMedicine(PrescriptionItem item) async {
    final draft = _draft;
    if (draft == null || item.id == null) return;
    setState(() => _saveState = _SaveState.saving);
    try {
      final updated = await removePrescriptionItem(
        prescriptionId: draft.id,
        itemId: item.id!,
      );
      await saveLocalDraft(_patientId, _prescriptionToJson(updated));
      if (!mounted) return;
      setState(() {
        _draft = updated;
        _saveState = _SaveState.saved;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saveState = _SaveState.offline);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection lost — changes will sync when restored.'),
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Review
  // -------------------------------------------------------------------------

  Future<void> _openReview() async {
    final draft = _draft;
    if (draft == null || draft.medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one medicine before reviewing.'),
        ),
      );
      return;
    }
    // Autosave notes before review so the review reflects the latest draft.
    try {
      final updated = await savePrescriptionNotes(
        prescriptionId: draft.id,
        additionalInstructions: _notesController.text,
      );
      if (mounted) setState(() => _draft = updated);
    } catch (_) {}
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DoctorPrescriptionReviewScreen(
          patient: widget.patient,
          prescription: _draft!,
          allergies: _allergies,
        ),
      ),
    );
    await _reloadHistory();
  }

  Future<void> _reloadHistory() async {
    try {
      final history = await fetchPrescriptionHistory(_patientId);
      if (!mounted) return;
      setState(() {
        _history = history;
        if (_draft != null && !_draft!.isDraft) {
          _draft = null;
          _notesController.clear();
          _clearLocalDraft();
        }
      });
    } catch (_) {}
  }

  // -------------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppTopBar(
        showBack: true,
        title: 'Prescription',
        hideTrailing: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final left = <Widget>[
                  _headerCard(scheme),
                  const SizedBox(height: AppSpacing.stackMd),
                  _saveStatusRow(scheme),
                  const SizedBox(height: AppSpacing.unit),
                  if (_pendingDraft != null)
                    _draftBanner(scheme),
                  const SizedBox(height: AppSpacing.gutter),
                  _quickSelectCard(scheme),
                  const SizedBox(height: AppSpacing.stackMd),
                  _searchCard(scheme),
                  const SizedBox(height: AppSpacing.unit),
                  if (_showResults) _searchResultsList(scheme),
                  const SizedBox(height: AppSpacing.stackMd),
                  _medicinesCard(scheme),
                  const SizedBox(height: AppSpacing.stackMd),
                  _instructionsCard(scheme),
                ];
                final right = <Widget>[
                  _historyCard(scheme),
                ];
                if (wide) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerMargin,
                      AppSpacing.unit,
                      AppSpacing.containerMargin,
                      AppSpacing.stackLg,
                    ),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: Column(children: left)),
                          const SizedBox(width: AppSpacing.gutter),
                          Expanded(flex: 2, child: Column(children: right)),
                        ],
                      ),
                    ],
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerMargin,
                    AppSpacing.unit,
                    AppSpacing.containerMargin,
                    AppSpacing.stackLg,
                  ),
                  children: [
                    ...left,
                    const SizedBox(height: AppSpacing.stackMd),
                    ...right,
                  ],
                );
              },
            ),
      bottomNavigationBar: _bottomBar(scheme),
    );
  }

  // -------------------------------------------------------------------------
  // Patient header
  // -------------------------------------------------------------------------

  Widget _headerCard(ColorScheme scheme) {
    final patient = widget.patient;
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
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, size: 24, color: scheme.primary),
              ),
              const SizedBox(width: AppSpacing.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: AppTextStyles.headlineMd
                          .copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$patient.age years • ${patient.gender} • $_patientId',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: scheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  patient.consultType,
                  style: AppTextStyles.labelSm
                      .copyWith(color: scheme.onSurfaceVariant, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _allergyBanner(scheme),
        ],
      ),
    );
  }

  Widget _allergyBanner(ColorScheme scheme) {
    final allergies = _allergies;
    if (allergies.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, size: 16, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No allergies on record.',
                style: AppTextStyles.labelSm.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: scheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Known Allergies',
                  style: AppTextStyles.labelSm.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  allergies.join(', '),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: scheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Autosave status
  // -------------------------------------------------------------------------

  Widget _saveStatusRow(ColorScheme scheme) {
    final (icon, text, color) = switch (_saveState) {
      _SaveState.saving => (Icons.cloud_upload_outlined, 'Saving…', scheme.onSurfaceVariant),
      _SaveState.saved => (Icons.cloud_done_outlined, 'Saved just now ✓', scheme.primary),
      _SaveState.offline => (
          Icons.cloud_off,
          'Connection lost — draft saved locally. Waiting for connection…',
          scheme.error,
        ),
      _SaveState.idle => (Icons.edit_note, 'Editing draft', scheme.onSurfaceVariant),
    };
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.labelSm.copyWith(color: color, fontSize: 11),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Draft recovery
  // -------------------------------------------------------------------------

  Widget _draftBanner(ColorScheme scheme) {
    final draft = _pendingDraft!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Draft Prescription',
                style: AppTextStyles.labelLg.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'You have an unfinished prescription for ${widget.patient.name} '
            '(${draft.medicines.length} medicine${draft.medicines.length == 1 ? '' : 's'}).',
            style: AppTextStyles.bodyMd
                .copyWith(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  label: 'Continue Draft',
                  icon: Icons.play_arrow,
                  height: 42,
                  onPressed: () => _continueDraft(draft),
                ),
              ),
              const SizedBox(width: AppSpacing.unit),
              Expanded(
                child: PillButton(
                  label: 'Discard',
                  height: 42,
                  backgroundColor: scheme.surfaceContainerLow,
                  foregroundColor: scheme.onSurface,
                  border: Border.all(color: scheme.outlineVariant),
                  onPressed: _discardDraft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Quick select
  // -------------------------------------------------------------------------

  Widget _quickSelectCard(ColorScheme scheme) {
    final meds = _common;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMMON MEDICINES',
          style: AppTextStyles.labelSm.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Quick select opens the medicine configuration — it never '
          'auto-prescribes.',
          style: AppTextStyles.labelSm.copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppSpacing.unit),
        if (meds.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Text(
              'Quick-select list unavailable offline. Use search to add '
              'medicines.',
              style: AppTextStyles.bodyMd
                  .copyWith(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in meds)
                _quickChip(scheme, m),
            ],
          ),
      ],
    );
  }

  Widget _quickChip(ColorScheme scheme, Medicine m) {
    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () => _openMedicineForm(medicine: m),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.medication, size: 13, color: scheme.primary),
              const SizedBox(width: 5),
              Text(
                m.strength.isNotEmpty ? '${m.name} ${m.strength}' : m.name,
                style: AppTextStyles.labelSm.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Search
  // -------------------------------------------------------------------------

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
          onChanged: _onSearchChanged,
          style: AppTextStyles.bodyMd.copyWith(
            color: scheme.onSurface,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Search generic name, brand, category or strength…',
            hintStyle: AppTextStyles.bodyMd
                .copyWith(color: scheme.onSurfaceVariant, fontSize: 13),
            prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: scheme.onSurfaceVariant),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _showResults = false;
                        _searchResults = const [];
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

  Widget _searchResultsList(ColorScheme scheme) {
    if (_searching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No medicines found.',
          style: AppTextStyles.bodyMd
              .copyWith(color: scheme.onSurfaceVariant, fontSize: 13),
        ),
      );
    }
    return Column(
      children: [
        for (final m in _searchResults)
          InkWell(
            onTap: () {
              _searchController.clear();
              setState(() {
                _showResults = false;
                _searchResults = const [];
              });
              _openMedicineForm(medicine: m);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.unit),
              padding: const EdgeInsets.all(AppSpacing.gutter),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.medication, size: 18, color: scheme.primary),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.display,
                          style: AppTextStyles.bodyMd
                              .copyWith(color: scheme.onSurface),
                        ),
                        if (m.genericName != m.name && m.genericName.isNotEmpty)
                          Text(
                            'Generic: ${m.genericName}'
                            '${m.category.isNotEmpty ? ' • ${m.category}' : ''}',
                            style: AppTextStyles.labelSm.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.add_circle_outline, size: 22, color: scheme.primary),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Medicines list
  // -------------------------------------------------------------------------

  Widget _medicinesCard(ColorScheme scheme) {
    final medicines = _draft?.medicines ?? const <PrescriptionItem>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'MEDICINES (${medicines.length})',
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Add Medicine',
              onPressed: () => _openMedicineForm(),
              icon: Icon(Icons.add_circle, color: scheme.primary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.unit),
        for (final w in _warnings)
          _safetyWarningBanner(scheme, w),
        if (_warnings.isNotEmpty) const SizedBox(height: AppSpacing.unit),
        if (medicines.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Icon(Icons.medication_outlined,
                    size: 36, color: scheme.onSurfaceVariant),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  'No medicines added yet',
                  style: AppTextStyles.bodyMd.copyWith(
                      color: scheme.onSurfaceVariant, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Use quick select or search to add a medicine.',
                  style: AppTextStyles.labelSm.copyWith(
                      color: scheme.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
          )
        else
          for (var i = 0; i < medicines.length; i++)
            _medicineCard(scheme, medicines[i], i + 1),
      ],
    );
  }

  Widget _safetyWarningBanner(ColorScheme scheme, Map<String, dynamic> warning) {
    final type = warning['type'] as String? ?? '';
    final color = type == 'ALLERGY_WARNING' ? scheme.error : const Color(0xFFB45309);
    final icon = type == 'ALLERGY_WARNING'
        ? Icons.warning_amber_rounded
        : Icons.content_copy;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.unit),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type == 'ALLERGY_WARNING'
                      ? 'ALLERGY WARNING'
                      : 'POSSIBLE DUPLICATE MEDICATION',
                  style: AppTextStyles.labelSm.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  warning['message'] as String? ?? '',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: scheme.onSurface, fontSize: 13),
                ),
                if (type == 'ALLERGY_WARNING')
                  Text(
                    'Please verify before prescribing. The system does not '
                    'claim a reaction will occur.',
                    style: AppTextStyles.labelSm.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _medicineCard(ColorScheme scheme, PrescriptionItem item, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.gutter),
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
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: AppTextStyles.labelLg.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.unit),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.labelLg.copyWith(
                          color: scheme.onSurface),
                    ),
                    if (item.genericName.isNotEmpty &&
                        item.genericName != item.name)
                      Text(
                        item.genericName,
                        style: AppTextStyles.labelSm.copyWith(
                            color: scheme.onSurfaceVariant, fontSize: 11),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: Icon(Icons.edit_outlined, size: 20, color: scheme.primary),
                onPressed: () => _editMedicine(item),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: Icon(Icons.delete_outline, size: 20, color: scheme.error),
                onPressed: () => _removeMedicine(item),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Wrap(
            spacing: AppSpacing.unit,
            runSpacing: AppSpacing.unit,
            children: [
              _medChip(scheme,
                  icon: Icons.straighten,
                  text: [item.strength, item.dosageForm]
                      .where((s) => s.isNotEmpty)
                      .join(' • ')),
              _medChip(scheme, icon: Icons.schedule, text: item.frequency),
              if (item.duration != null && item.duration!.isNotEmpty)
                _medChip(scheme,
                    icon: Icons.calendar_today,
                    text: '${item.duration} ${item.durationUnit}'),
              _medChip(scheme, icon: Icons.route_outlined, text: item.route),
              if (item.timing.isNotEmpty)
                _medChip(scheme, icon: Icons.restaurant, text: item.timing),
            ],
          ),
          if (item.dose.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.unit),
            Text(
              item.doseLine,
              style: AppTextStyles.bodyMd.copyWith(
                color: scheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (item.instructions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.instructions,
              style: AppTextStyles.bodyMd
                  .copyWith(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _medChip(ColorScheme scheme,
      {required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text.isEmpty ? '—' : text,
            style: AppTextStyles.labelSm.copyWith(
              color: scheme.onSurface,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Additional instructions
  // -------------------------------------------------------------------------

  Widget _instructionsCard(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADDITIONAL INSTRUCTIONS',
          style: AppTextStyles.labelSm.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.unit),
        TextField(
          controller: _notesController,
          maxLines: 3,
          onChanged: (_) => _autosaveNotes(),
          style: AppTextStyles.bodyMd.copyWith(
            color: scheme.onSurface,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Rest and maintain adequate hydration…',
            hintStyle: AppTextStyles.bodyMd
                .copyWith(color: scheme.onSurfaceVariant, fontSize: 13),
            filled: true,
            fillColor: scheme.surfaceContainerLowest,
            contentPadding: const EdgeInsets.all(AppSpacing.gutter),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // History
  // -------------------------------------------------------------------------

  Widget _historyCard(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRESCRIPTION HISTORY',
          style: AppTextStyles.labelSm.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.unit),
        if (_history.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Text(
              'No issued prescriptions yet for this patient.',
              style: AppTextStyles.bodyMd
                  .copyWith(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          )
        else
          for (final rx in _history)
            _historyRow(scheme, rx),
      ],
    );
  }

  Widget _historyRow(ColorScheme scheme, Prescription rx) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.unit),
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.description, size: 20),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rx.doctorName,
                  style: AppTextStyles.labelLg
                      .copyWith(color: scheme.onSurface, fontSize: 14),
                ),
                Text(
                  '${_shortDate(rx.issuedAt ?? rx.date)} • '
                  '${rx.medicines.length} medicine${rx.medicines.length == 1 ? '' : 's'}',
                  style: AppTextStyles.labelSm
                      .copyWith(color: scheme.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'ISSUED',
              style: AppTextStyles.labelSm.copyWith(
                color: const Color(0xFF15803D),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  // -------------------------------------------------------------------------
  // Bottom bar
  // -------------------------------------------------------------------------

  Widget _bottomBar(ColorScheme scheme) {
    final hasDraft = _draft != null && _draft!.medicines.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerMargin,
        AppSpacing.unit,
        AppSpacing.containerMargin,
        AppSpacing.containerMargin,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: PillButton(
              label: 'Save Draft',
              icon: Icons.save_outlined,
              height: 48,
              backgroundColor: scheme.surfaceContainerLow,
              foregroundColor: scheme.onSurface,
              border: Border.all(color: scheme.outlineVariant),
              onPressed: _saveState == _SaveState.offline
                  ? null
                  : () async {
                      if (_draft == null) return;
                      try {
                        await savePrescriptionNotes(
                          prescriptionId: _draft!.id,
                          additionalInstructions: _notesController.text,
                        );
                        if (!mounted) return;
                        setState(() => _saveState = _SaveState.saved);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Draft saved.')),
                        );
                      } catch (_) {}
                    },
            ),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            flex: 2,
            child:              PillButton(
                label: 'Review Prescription',
                icon: Icons.rate_review_outlined,
                height: 48,
                onPressed: hasDraft ? _openReview : null,
              ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Medicine configuration form
// ---------------------------------------------------------------------------

class _MedicineFormSheet extends StatefulWidget {
  const _MedicineFormSheet({
    required this.medicine,
    required this.edit,
    required this.frequencies,
    required this.durationUnits,
    required this.timings,
    required this.forms,
    required this.routes,
  });

  final Medicine? medicine;
  final PrescriptionItem? edit;
  final List<String> frequencies;
  final List<String> durationUnits;
  final List<String> timings;
  final List<String> forms;
  final List<String> routes;

  @override
  State<_MedicineFormSheet> createState() => _MedicineFormSheetState();
}

class _MedicineFormSheetState extends State<_MedicineFormSheet> {
  final _doseController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _strengthController = TextEditingController();
  String _frequency = 'Twice daily';
  String _durationUnit = 'days';
  String _route = 'Oral';
  String _timing = 'After food';
  String _form = 'Tablet';
  String _strength = '';
  bool _customFrequency = false;
  final _customFrequencyController = TextEditingController();

  Medicine? get _med => widget.medicine;

  @override
  void initState() {
    super.initState();
    final edit = widget.edit;
    if (edit != null) {
      _doseController.text = edit.dose;
      _durationController.text = edit.duration ?? '';
      _instructionsController.text = edit.instructions;
      _frequency = edit.frequency;
      _customFrequency = !widget.frequencies.contains(edit.frequency);
      if (_customFrequency) _customFrequencyController.text = edit.frequency;
      _durationUnit = edit.durationUnit;
      _route = edit.route;
      _timing = edit.timing;
      _form = edit.dosageForm;
      _strength = edit.strength;
      _strengthController.text = edit.strength;
    } else if (_med != null) {
      _strength = _med!.strength;
      _strengthController.text = _med!.strength;
      _form = _med!.dosageForm.isNotEmpty ? _med!.dosageForm : 'Tablet';
      _route = _med!.route.isNotEmpty ? _med!.route : 'Oral';
    }
  }

  @override
  void dispose() {
    _doseController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    _customFrequencyController.dispose();
    _strengthController.dispose();
    super.dispose();
  }

  String get _title =>
      widget.edit != null ? 'Edit Medicine' : 'Add ${_med?.name ?? 'Medicine'}';

  List<String> get _routesForForm {
    final routes = List<String>.from(widget.routes);
    final form = _form.toLowerCase();
    if (form.contains('cream') || form.contains('ointment')) {
      return ['Topical', ...routes.where((r) => r != 'Topical')];
    }
    if (form.contains('inhal')) return ['Inhaled', ...routes];
    return routes;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _title,
                style: AppTextStyles.headlineLgMobile
                    .copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                widget.edit != null
                    ? widget.edit!.name
                    : (_med != null
                        ? _med!.display
                        : 'Search and select a medicine first.'),
                style: AppTextStyles.bodyMd
                    .copyWith(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.gutter),
              _label(scheme, 'Strength'),
              TextField(
                controller: _strengthController,
                onChanged: (v) => setState(() => _strength = v.trim()),
                style: _inputStyle,
                decoration: _inputDecoration('e.g. 500 mg'),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              _label(scheme, 'Dosage Form'),
              _dropdown(scheme, _form, widget.forms,
                  onChanged: (v) => setState(() => _form = v!)),
              const SizedBox(height: AppSpacing.stackSm),
              _label(scheme, 'Dose'),
              TextField(
                controller: _doseController,
                style: _inputStyle,
                decoration: _inputDecoration('e.g. 1 tablet, 5 ml'),
              ),
              const SizedBox(height: AppSpacing.stackSm),
              _label(scheme, 'Frequency'),
              _dropdown(
                scheme,
                _customFrequency ? 'Custom…' : _frequency,
                widget.frequencies,
                onChanged: (v) => setState(() {
                  if (v == 'Custom…') {
                    _customFrequency = true;
                  } else {
                    _customFrequency = false;
                    _frequency = v!;
                  }
                }),
              ),
              if (_customFrequency) ...[
                const SizedBox(height: AppSpacing.unit),
                TextField(
                  controller: _customFrequencyController,
                  style: _inputStyle,
                  decoration: _inputDecoration('e.g. Every 3 hours'),
                ),
              ],
              const SizedBox(height: AppSpacing.stackSm),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(scheme, 'Duration'),
                        TextField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          style: _inputStyle,
                          decoration: _inputDecoration('e.g. 3'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.unit),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(scheme, 'Unit'),
                        _dropdown(scheme, _durationUnit, widget.durationUnits,
                            onChanged: (v) =>
                                setState(() => _durationUnit = v!)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.stackSm),
              _label(scheme, 'Route'),
              _dropdown(scheme, _route, _routesForForm,
                  onChanged: (v) => setState(() => _route = v!)),
              const SizedBox(height: AppSpacing.stackSm),
              _label(scheme, 'Timing'),
              _dropdown(scheme, _timing, widget.timings,
                  onChanged: (v) => setState(() => _timing = v!)),
              const SizedBox(height: AppSpacing.stackSm),
              _label(scheme, 'Additional Instructions (optional)'),
              TextField(
                controller: _instructionsController,
                maxLines: 2,
                style: _inputStyle,
                decoration: _inputDecoration('Take with water…'),
              ),
              const SizedBox(height: AppSpacing.gutter),
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: 'Cancel',
                      height: 48,
                      backgroundColor: scheme.surfaceContainerLow,
                      foregroundColor: scheme.onSurface,
                      border: Border.all(color: scheme.outlineVariant),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gutter),
                  Expanded(
                    child: PillButton(
                      label: widget.edit != null ? 'Update' : 'Add Medicine',
                      icon: Icons.check,
                      height: 48,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (widget.edit == null && _med == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search and select a medicine first.')),
      );
      return;
    }
    _strength = _strengthController.text.trim();
    final dose = _doseController.text.trim();
    final frequency = _customFrequency
        ? _customFrequencyController.text.trim()
        : _frequency;
    if (dose.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a dose.')),
      );
      return;
    }
    if (frequency.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a frequency.')),
      );
      return;
    }
    Navigator.of(context).pop({
      'medicineId': widget.edit?.medicineId ?? _med?.id,
      'genericName': widget.edit?.genericName ?? _med?.genericName,
      'strength': _strength,
      'dosageForm': _form,
      'dose': dose,
      'frequency': frequency,
      'duration': _durationController.text.trim(),
      'durationUnit': _durationUnit,
      'route': _route,
      'timing': _timing,
      'instructions': _instructionsController.text.trim(),
    });
  }

  Widget _label(ColorScheme scheme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppTextStyles.labelSm.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  TextStyle get _inputStyle => AppTextStyles.bodyMd.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 14,
      );

  InputDecoration _inputDecoration(String hint) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMd
          .copyWith(color: scheme.onSurfaceVariant, fontSize: 13),
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    );
  }

  Widget _dropdown(
    ColorScheme scheme,
    String value,
    List<String> options, {
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : null,
          isExpanded: true,
          hint: Text(value.isEmpty ? 'Select…' : value,
              style: AppTextStyles.bodyMd
                  .copyWith(color: scheme.onSurface, fontSize: 14)),
          items: [
            for (final o in options)
              DropdownMenuItem(value: o, child: Text(o)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
