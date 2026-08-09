import 'package:flutter/material.dart';
import 'package:jeevandoot/constants.dart';
import 'package:jeevandoot/screens/language_selection_screen.dart';
import 'package:jeevandoot/screens/profile_settings.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Future<void> _open(BuildContext context, Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        avatarUrl: AppAssets.patientAvatar,
        title: 'JeevanDoot',
        onTrailing: () => openOfflineScreen(context),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.containerMargin,
          AppSpacing.stackMd,
          AppSpacing.containerMargin,
          AppSpacing.stackLg,
        ),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Profile',
                style: AppTextStyles.displayHeroMobile
                    .copyWith(color: scheme.onSurface),
              ),
              IconButton.filledTonal(
                onPressed: () => _open(context, const EditProfileScreen()),
                icon: const Icon(Icons.edit),
                style: IconButton.styleFrom(
                  backgroundColor: scheme.surfaceContainer,
                  foregroundColor: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _profileCard(scheme),
          const SizedBox(height: AppSpacing.stackLg),
          _settingsGrid(scheme),
          const SizedBox(height: AppSpacing.stackLg),
          _familySection(context, scheme),
        ],
      ),
    );
  }

  Widget _profileCard(ColorScheme scheme) {
    return SoftCard(
      child: Column(
        children: [
          ClipOval(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                border: Border.all(color: scheme.surface, width: 4),
                color: scheme.surfaceContainerHigh,
              ),
              child: Image.network(
                AppAssets.patientAvatar,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.person, size: 40),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            UserData.name,
            style: AppTextStyles.headlineLg.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.unit),
          Wrap(
            spacing: AppSpacing.gutter,
            runSpacing: AppSpacing.unit,
            alignment: WrapAlignment.center,
            children: [
              _infoChip(scheme, Icons.cake, '${UserData.age} yrs'),
              _infoChip(scheme, Icons.wc, UserData.gender),
              _infoChip(scheme, Icons.bloodtype, UserData.bloodGroup),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.call, size: 18, color: scheme.primary),
                const SizedBox(width: 4),
                Text(
                  UserData.phone,
                  style: AppTextStyles.labelLg.copyWith(color: scheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(ColorScheme scheme, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _settingsGrid(ColorScheme scheme) {
    final items = [
      (
        icon: Icons.person,
        title: 'Personal Info',
        subtitle: 'Address, DOB, ID details',
        page: const PersonalInfoScreen(),
      ),
      (
        icon: Icons.medical_information,
        title: 'Health Info',
        subtitle: 'Allergies, chronic conditions',
        page: const HealthInfoScreen(),
      ),
      (
        icon: Icons.translate,
        title: 'Language',
        subtitle: 'Hindi (हिन्दी)',
        page: const LanguageSelectionScreen(),
      ),
      (
        icon: Icons.notifications,
        title: 'Notifications',
        subtitle: 'SMS, App alerts',
        page: const NotificationsSettingsScreen(),
      ),
      (
        icon: Icons.security,
        title: 'Privacy & Security',
        subtitle: 'Data sharing, app lock',
        page: const PrivacySecurityScreen(),
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.gutter,
        crossAxisSpacing: AppSpacing.gutter,
        mainAxisExtent: 148,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _settingCard(
          scheme,
          icon: item.icon,
          title: item.title,
          subtitle: item.subtitle,
          onTap: () => _open(context, item.page),
        );
      },
    );
  }

  Widget _settingCard(
    ColorScheme scheme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: scheme.primary),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headlineMd.copyWith(
                  color: scheme.onSurface,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMd.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _familySection(BuildContext context, ColorScheme scheme) {
    final members = [
      (
        name: 'Sunita Devi',
        relation: 'Mother',
        image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC9Jn4VGYsKSJRBB-jB1jRE0jexDaoaxCuhqcaVcnrj1gZAiV10sefw1Og2fcLA4IQOywHrmuPYHUwmW-_7j87OvQkx7q0V1iTRBciYwhAKSXnlOwa5eVt8kyyn0aACco8x2Q3eMnPYyViFyzX2m-jZ9c03zrN8D7Q3tYd0aZMFUA7JmYwVSc_SrNrSNK6K9vwwPT6cGTVdHUudLYObSCBuK1Qa7jnthdTDg0M6fUywC5lwz9C4hmpZ'
      ),
      (
        name: 'Mohan Kumar',
        relation: 'Father',
        image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDcmTYMjf_OyOeL-lIs0Fz6PrMixIlvqwQqRb-NlGUis7nvkssN_TeyurAJp2afk_WbaIcjEuEfBnrNYb99zmenmmaHQicXSGs2nSLlR6dmkg2oXhAgDH_cuFmEnn1MVKo0Io4a5Q1h0ZnBZ1VFEY3lwpeeqfHup5tlotH0_s3YURrHyT5qsf6ZfigvumqOxuyzoQVHX6GwuBiYNRtUt0r9ms0DxYqqVMZKe0BgMIxhm7U11WlY52ta'
      ),
      (
        name: 'Rahul',
        relation: 'Child',
        image: 'https://lh3.googleusercontent.com/aida-public/AB6AXuD0W6LFRNtM1ZpjcPbRI_HHQhAGfNxnHp8ZncDpJC45DBXwGVnn9mTT3Suy9RY9FYRQwzx9plGlSSsVjHMqTiCnJI60LoEfphP59t5Jw0wQZ_fzsh7KRSJQSzwz4TozU9yJ69fv0e8tjpHjusVlOKtMtUpYDBtxm6x0lmsG_CALPoa6MeyulXQeAgdWp21ngc1BsF1knyVPCE7ImPakwpReanViC14xYkCG92kfc7BfKftYBFeEvJs2'
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Family Members',
              style: AppTextStyles.headlineLgMobile
                  .copyWith(color: scheme.onSurface),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'See all',
                style: AppTextStyles.labelLg.copyWith(color: scheme.primary),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: members.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.gutter),
            itemBuilder: (context, index) {
              final member = members[index];
              return Container(
                width: 256,
                padding: const EdgeInsets.all(AppSpacing.gutter),
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
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: Image.network(
                          member.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              ColoredBox(color: scheme.surfaceContainerHigh),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.unit),
                    Text(
                      member.name,
                      style: AppTextStyles.headlineMd
                          .copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        member.relation,
                        style: AppTextStyles.bodyMd
                            .copyWith(color: scheme.onSecondaryContainer),
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Switching to ${member.name}'s profile...",
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.primary,
                        side: BorderSide(color: scheme.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        textStyle: AppTextStyles.labelLg,
                      ),
                      child: const Text('Switch Profile'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        PillButton(
          label: 'Add Family Member',
          icon: Icons.add,
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          onPressed: () => _showAddFamilyDialog(context),
        ),
      ],
    );
  }

  void _showAddFamilyDialog(BuildContext context) {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Family Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(labelText: 'Relation'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${nameController.text} added to your family.',
                  ),
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
