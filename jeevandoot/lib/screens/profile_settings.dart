import 'package:flutter/material.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/app_top_bar.dart';
import 'package:jeevandoot/widgets/common.dart';

/// In-memory store for the user's profile, health and preference data.
/// Persists for the app session so edits survive screen navigation.
abstract final class UserData {
  static String name = 'Ramesh Kumar';
  static String phone = '+91 98765 43210';
  static String age = '42';
  static String gender = 'Male';
  static String bloodGroup = 'O+';
  static String email = 'ramesh.kumar@example.com';
  static String address = 'Shop 12, MG Road, Pune, Maharashtra';
  static String dob = '12 August 1983';
  static String idNumber = 'XXXX-XXXX-1234';

  static String allergies = 'Peanuts, Penicillin';
  static String chronicConditions = 'Mild hypertension';
  static String height = '168 cm';
  static String weight = '74 kg';
  static String medications = 'Amlodipine 5 mg (daily)';

  static bool smsAlerts = true;
  static bool appAlerts = true;
  static bool emailUpdates = false;
  static bool reminderAlerts = true;
  static bool appointmentAlerts = true;

  static bool dataSharing = false;
  static bool appLock = true;
  static bool biometricLock = false;
  static bool shareHealthReports = false;
  static bool marketingUpdates = false;
}

/// Full profile editor reachable from the "My Profile" header button.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _age;
  late String _gender;
  late String _blood;

  static const List<String> _genders = ['Male', 'Female', 'Other'];
  static const List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: UserData.name);
    _phone = TextEditingController(text: UserData.phone);
    _age = TextEditingController(text: UserData.age);
    _gender = UserData.gender;
    _blood = UserData.bloodGroup;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _age.dispose();
    super.dispose();
  }

  void _save() {
    setState(() {
      if (_name.text.trim().isNotEmpty) UserData.name = _name.text.trim();
      if (_phone.text.trim().isNotEmpty) UserData.phone = _phone.text.trim();
      if (_age.text.trim().isNotEmpty) UserData.age = _age.text.trim();
      UserData.gender = _gender;
      UserData.bloodGroup = _blood;
    });
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        title: 'Edit Profile',
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
          _formField(
            controller: _name,
            label: 'Full name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: AppSpacing.gutter),
          _formField(
            controller: _phone,
            label: 'Phone number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.gutter),
          _formField(
            controller: _age,
            label: 'Age',
            icon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _chipField(
            scheme: scheme,
            label: 'Gender',
            options: _genders,
            selected: _gender,
            onChanged: (value) => setState(() => _gender = value),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          _chipField(
            scheme: scheme,
            label: 'Blood group',
            options: _bloodGroups,
            selected: _blood,
            onChanged: (value) => setState(() => _blood = value),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpacing.containerMargin),
        child: PillButton(
          label: 'Save Changes',
          icon: Icons.check,
          onPressed: _save,
        ),
      ),
    );
  }
}

/// Displays and edits personal / contact / ID details.
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  bool _editing = false;
  late final TextEditingController _name;
  late final TextEditingController _dob;
  late final TextEditingController _age;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _id;
  late String _gender;
  late String _blood;

  static const List<String> _genders = ['Male', 'Female', 'Other'];
  static const List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: UserData.name);
    _dob = TextEditingController(text: UserData.dob);
    _age = TextEditingController(text: UserData.age);
    _phone = TextEditingController(text: UserData.phone);
    _email = TextEditingController(text: UserData.email);
    _address = TextEditingController(text: UserData.address);
    _id = TextEditingController(text: UserData.idNumber);
    _gender = UserData.gender;
    _blood = UserData.bloodGroup;
  }

  @override
  void dispose() {
    _name.dispose();
    _dob.dispose();
    _age.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _id.dispose();
    super.dispose();
  }

  void _save() {
    setState(() {
      if (_name.text.trim().isNotEmpty) UserData.name = _name.text.trim();
      if (_dob.text.trim().isNotEmpty) UserData.dob = _dob.text.trim();
      if (_age.text.trim().isNotEmpty) UserData.age = _age.text.trim();
      if (_phone.text.trim().isNotEmpty) UserData.phone = _phone.text.trim();
      if (_email.text.trim().isNotEmpty) UserData.email = _email.text.trim();
      if (_address.text.trim().isNotEmpty) UserData.address = _address.text.trim();
      if (_id.text.trim().isNotEmpty) UserData.idNumber = _id.text.trim();
      UserData.gender = _gender;
      UserData.bloodGroup = _blood;
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Personal information updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        title: 'Personal Info',
        trailingIcon: _editing ? Icons.check : Icons.edit,
        onTrailing: _editing
            ? _save
            : () => setState(() => _editing = true),
      ),
      body: _editing ? _buildForm() : _buildDisplay(scheme),
    );
  }

  Widget _buildDisplay(ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerMargin,
        AppSpacing.stackMd,
        AppSpacing.containerMargin,
        AppSpacing.stackLg,
      ),
      children: [
        _sectionCard(
          scheme,
          title: 'Personal Details',
          children: [
            _infoTile(scheme, icon: Icons.person_outline, label: 'Full name', value: UserData.name),
            _infoTile(scheme, icon: Icons.cake_outlined, label: 'Date of birth', value: UserData.dob),
            _infoTile(scheme, icon: Icons.tag, label: 'Age', value: UserData.age),
            _infoTile(scheme, icon: Icons.wc, label: 'Gender', value: UserData.gender),
            _infoTile(scheme, icon: Icons.bloodtype, label: 'Blood group', value: UserData.bloodGroup),
          ],
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _sectionCard(
          scheme,
          title: 'Contact',
          children: [
            _infoTile(scheme, icon: Icons.phone_outlined, label: 'Phone', value: UserData.phone),
            _infoTile(scheme, icon: Icons.mail_outline, label: 'Email', value: UserData.email),
            _infoTile(scheme, icon: Icons.home_outlined, label: 'Address', value: UserData.address),
          ],
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _sectionCard(
          scheme,
          title: 'ID Details',
          children: [
            _infoTile(scheme, icon: Icons.credit_card, label: 'Govt. ID number', value: UserData.idNumber),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerMargin,
        AppSpacing.stackMd,
        AppSpacing.containerMargin,
        AppSpacing.stackLg,
      ),
      children: [
        _formField(controller: _name, label: 'Full name', icon: Icons.person_outline),
        const SizedBox(height: AppSpacing.gutter),
        _formField(controller: _dob, label: 'Date of birth', icon: Icons.cake_outlined),
        const SizedBox(height: AppSpacing.gutter),
        _formField(controller: _age, label: 'Age', icon: Icons.tag, keyboardType: TextInputType.number),
        const SizedBox(height: AppSpacing.gutter),
        _formField(controller: _phone, label: 'Phone number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: AppSpacing.gutter),
        _formField(controller: _email, label: 'Email', icon: Icons.mail_outline, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: AppSpacing.gutter),
        _formField(controller: _address, label: 'Address', icon: Icons.home_outlined, maxLines: 3),
        const SizedBox(height: AppSpacing.gutter),
        _formField(controller: _id, label: 'Govt. ID number', icon: Icons.credit_card),
        const SizedBox(height: AppSpacing.stackMd),
        _chipField(
          scheme: Theme.of(context).colorScheme,
          label: 'Gender',
          options: _genders,
          selected: _gender,
          onChanged: (value) => setState(() => _gender = value),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _chipField(
          scheme: Theme.of(context).colorScheme,
          label: 'Blood group',
          options: _bloodGroups,
          selected: _blood,
          onChanged: (value) => setState(() => _blood = value),
        ),
      ],
    );
  }
}

/// Displays and edits health details (allergies, conditions, vitals).
class HealthInfoScreen extends StatefulWidget {
  const HealthInfoScreen({super.key});

  @override
  State<HealthInfoScreen> createState() => _HealthInfoScreenState();
}

class _HealthInfoScreenState extends State<HealthInfoScreen> {
  bool _editing = false;
  late final TextEditingController _blood;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _allergies;
  late final TextEditingController _conditions;
  late final TextEditingController _medications;

  @override
  void initState() {
    super.initState();
    _blood = TextEditingController(text: UserData.bloodGroup);
    _height = TextEditingController(text: UserData.height);
    _weight = TextEditingController(text: UserData.weight);
    _allergies = TextEditingController(text: UserData.allergies);
    _conditions = TextEditingController(text: UserData.chronicConditions);
    _medications = TextEditingController(text: UserData.medications);
  }

  @override
  void dispose() {
    _blood.dispose();
    _height.dispose();
    _weight.dispose();
    _allergies.dispose();
    _conditions.dispose();
    _medications.dispose();
    super.dispose();
  }

  void _save() {
    setState(() {
      if (_blood.text.trim().isNotEmpty) UserData.bloodGroup = _blood.text.trim();
      if (_height.text.trim().isNotEmpty) UserData.height = _height.text.trim();
      if (_weight.text.trim().isNotEmpty) UserData.weight = _weight.text.trim();
      if (_allergies.text.trim().isNotEmpty) UserData.allergies = _allergies.text.trim();
      if (_conditions.text.trim().isNotEmpty) UserData.chronicConditions = _conditions.text.trim();
      if (_medications.text.trim().isNotEmpty) UserData.medications = _medications.text.trim();
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Health information updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        title: 'Health Info',
        trailingIcon: _editing ? Icons.check : Icons.edit,
        onTrailing: _editing
            ? _save
            : () => setState(() => _editing = true),
      ),
      body: _editing ? _buildForm() : _buildDisplay(scheme),
    );
  }

  Widget _buildDisplay(ColorScheme scheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerMargin,
        AppSpacing.stackMd,
        AppSpacing.containerMargin,
        AppSpacing.stackLg,
      ),
      children: [
        _sectionCard(
          scheme,
          title: 'Vitals',
          children: [
            _infoTile(scheme, icon: Icons.bloodtype, label: 'Blood group', value: UserData.bloodGroup),
            _infoTile(scheme, icon: Icons.height, label: 'Height', value: UserData.height),
            _infoTile(scheme, icon: Icons.monitor_weight_outlined, label: 'Weight', value: UserData.weight),
          ],
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _sectionCard(
          scheme,
          title: 'Conditions',
          children: [
            _infoTile(scheme, icon: Icons.medical_information_outlined, label: 'Allergies', value: UserData.allergies),
            _infoTile(scheme, icon: Icons.favorite_outline, label: 'Chronic conditions', value: UserData.chronicConditions),
            _infoTile(scheme, icon: Icons.medication_outlined, label: 'Current medications', value: UserData.medications),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerMargin,
        AppSpacing.stackMd,
        AppSpacing.containerMargin,
        AppSpacing.stackLg,
      ),
      children: [
        _formField(controller: _blood, label: 'Blood group', icon: Icons.bloodtype),
        const SizedBox(height: AppSpacing.gutter),
        _formField(controller: _height, label: 'Height', icon: Icons.height),
        const SizedBox(height: AppSpacing.gutter),
        _formField(controller: _weight, label: 'Weight', icon: Icons.monitor_weight_outlined),
        const SizedBox(height: AppSpacing.gutter),
        _formField(controller: _allergies, label: 'Allergies', icon: Icons.medical_information_outlined),
        const SizedBox(height: AppSpacing.gutter),
        _formField(controller: _conditions, label: 'Chronic conditions', icon: Icons.favorite_outline),
        const SizedBox(height: AppSpacing.gutter),
        _formField(controller: _medications, label: 'Current medications', icon: Icons.medication_outlined, maxLines: 3),
      ],
    );
  }
}

/// Notification preference toggles.
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        title: 'Notifications',
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
          _switchTile(
            scheme,
            icon: Icons.sms_outlined,
            title: 'SMS alerts',
            subtitle: 'Text messages for reports and payments',
            value: UserData.smsAlerts,
            onChanged: (v) => setState(() => UserData.smsAlerts = v),
          ),
          const SizedBox(height: AppSpacing.gutter),
          _switchTile(
            scheme,
            icon: Icons.notifications_outlined,
            title: 'App alerts',
            subtitle: 'In-app notifications for activity',
            value: UserData.appAlerts,
            onChanged: (v) => setState(() => UserData.appAlerts = v),
          ),
          const SizedBox(height: AppSpacing.gutter),
          _switchTile(
            scheme,
            icon: Icons.mail_outline,
            title: 'Email updates',
            subtitle: 'Weekly health summaries by email',
            value: UserData.emailUpdates,
            onChanged: (v) => setState(() => UserData.emailUpdates = v),
          ),
          const SizedBox(height: AppSpacing.gutter),
          _switchTile(
            scheme,
            icon: Icons.alarm_outlined,
            title: 'Reminder alerts',
            subtitle: 'Medicines and follow-up reminders',
            value: UserData.reminderAlerts,
            onChanged: (v) => setState(() => UserData.reminderAlerts = v),
          ),
          const SizedBox(height: AppSpacing.gutter),
          _switchTile(
            scheme,
            icon: Icons.event_available_outlined,
            title: 'Appointment alerts',
            subtitle: 'Booking and confirmation updates',
            value: UserData.appointmentAlerts,
            onChanged: (v) => setState(() => UserData.appointmentAlerts = v),
          ),
        ],
      ),
    );
  }
}

/// Privacy and security toggles.
class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppTopBar(
        showBack: true,
        title: 'Privacy & Security',
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
          _switchTile(
            scheme,
            icon: Icons.share_outlined,
            title: 'Share data with doctors',
            subtitle: 'Allow doctors to view your health records',
            value: UserData.dataSharing,
            onChanged: (v) => setState(() => UserData.dataSharing = v),
          ),
          const SizedBox(height: AppSpacing.gutter),
          _switchTile(
            scheme,
            icon: Icons.lock_outline,
            title: 'App lock',
            subtitle: 'Require a PIN to open JeevanDoot',
            value: UserData.appLock,
            onChanged: (v) => setState(() => UserData.appLock = v),
          ),
          const SizedBox(height: AppSpacing.gutter),
          _switchTile(
            scheme,
            icon: Icons.fingerprint,
            title: 'Biometric unlock',
            subtitle: 'Use fingerprint or face to unlock',
            value: UserData.biometricLock,
            onChanged: (v) => setState(() => UserData.biometricLock = v),
          ),
          const SizedBox(height: AppSpacing.gutter),
          _switchTile(
            scheme,
            icon: Icons.assignment_outlined,
            title: 'Share health reports',
            subtitle: 'Share reports with family members',
            value: UserData.shareHealthReports,
            onChanged: (v) => setState(() => UserData.shareHealthReports = v),
          ),
          const SizedBox(height: AppSpacing.gutter),
          _switchTile(
            scheme,
            icon: Icons.campaign_outlined,
            title: 'Marketing updates',
            subtitle: 'Health tips and promotional messages',
            value: UserData.marketingUpdates,
            onChanged: (v) => setState(() => UserData.marketingUpdates = v),
          ),
        ],
      ),
    );
  }
}

Widget _formField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType? keyboardType,
  int maxLines = 1,
}) {
  return TextField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
    ),
  );
}

Widget _chipField({
  required ColorScheme scheme,
  required String label,
  required List<String> options,
  required String selected,
  required ValueChanged<String> onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTextStyles.labelLg.copyWith(color: scheme.onSurfaceVariant),
      ),
      const SizedBox(height: AppSpacing.unit),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in options)
            ChoiceChip(
              label: Text(option),
              selected: selected == option,
              onSelected: (_) => onChanged(option),
              selectedColor: scheme.primaryContainer,
              labelStyle: AppTextStyles.labelLg.copyWith(
                color: selected == option
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              side: BorderSide(
                color: selected == option
                    ? scheme.primary
                    : scheme.outlineVariant,
              ),
            ),
        ],
      ),
    ],
  );
}

Widget _sectionCard(
  ColorScheme scheme, {
  required String title,
  required List<Widget> children,
}) {
  final tiles = <Widget>[];
  for (var i = 0; i < children.length; i++) {
    if (i > 0) tiles.add(const Divider(height: 1, indent: 56, endIndent: 16));
    tiles.add(children[i]);
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.unit),
        child: Text(
          title,
          style: AppTextStyles.headlineMd.copyWith(color: scheme.onSurface),
        ),
      ),
      SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: tiles,
        ),
      ),
    ],
  );
}

Widget _infoTile(
  ColorScheme scheme, {
  required IconData icon,
  required String label,
  required String value,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: scheme.primary),
        ),
        const SizedBox(width: AppSpacing.gutter),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMd.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _switchTile(
  ColorScheme scheme, {
  required IconData icon,
  required String title,
  required String subtitle,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  return Material(
    color: scheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(16),
    child: SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: scheme.primary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: 4,
      ),
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: scheme.primary),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMd.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodyMd.copyWith(
          color: scheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
