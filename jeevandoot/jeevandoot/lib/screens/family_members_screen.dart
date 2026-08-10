import 'package:flutter/material.dart';
import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/api/patient_service.dart';
import 'package:jeevandoot/l10n/app_strings.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  final _service = PatientService(ApiClient.instance);
  late Future<List<FamilyMember>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listFamilyMembers();
  }

  Future<void> _reload() {
    setState(() {
      _future = _service.listFamilyMembers();
    });
    return _future;
  }

  Future<void> _addMember() async {
    final nameCtrl = TextEditingController();
    final relCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
builder: (ctx) => AlertDialog(
        title: Text(AppStrings.tr('Add Family Member')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: AppStrings.tr('Full name')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: relCtrl,
              decoration: InputDecoration(
                labelText: AppStrings.tr('Relationship (e.g. mother, son)'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.tr('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.tr('Add')),
          ),
        ],
      ),
    );
    if (saved != true || nameCtrl.text.trim().isEmpty) return;
    try {
      await _service.addFamilyMember({
        'name': nameCtrl.text.trim(),
        'relationship_type': relCtrl.text.trim(),
      });
      _reload();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        title: AppStrings.tr('Family Members'),
        onTrailing: () => openOfflineScreen(context),
      ),
      body: FutureBuilder<List<FamilyMember>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _errorState(scheme);
          }
          final members = snap.data ?? [];
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.containerMargin),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
Text(
                      AppStrings.tr('Your family'),
                      style: AppTextStyles.displayHeroMobile
                          .copyWith(color: scheme.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                if (members.isEmpty)
                  _emptyState(scheme)
                else
                  ...members.map((m) => _memberCard(scheme, m)),
                const SizedBox(height: AppSpacing.stackLg),
PillButton(
                  label: AppStrings.tr('Add Family Member'),
                  icon: Icons.person_add,
                  onPressed: _addMember,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _memberCard(ColorScheme scheme, FamilyMember member) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Icon(Icons.person, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: AppSpacing.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
                ),
                if (member.relationship != null)
                  Text(
                    member.relationship!,
                    style: AppTextStyles.bodyMd
                        .copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ColorScheme scheme) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.stackLg),
        child: Column(
          children: [
            Icon(Icons.family_restroom, size: 56, color: scheme.outline),
            const SizedBox(height: AppSpacing.stackSm),
Text(
              AppStrings.tr('No family members added yet.'),
              style: AppTextStyles.bodyLg.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );

  Widget _errorState(ColorScheme scheme) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.stackLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 56, color: scheme.outline),
              const SizedBox(height: AppSpacing.stackSm),
Text(AppStrings.tr('Could not load family members.')),
              const SizedBox(height: AppSpacing.stackMd),
              PillButton(label: AppStrings.tr('Retry'), onPressed: _reload),
            ],
          ),
        ),
      );
}
