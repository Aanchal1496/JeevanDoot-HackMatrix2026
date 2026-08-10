import 'package:flutter/material.dart';
import 'package:jeevandoot/api/api_client.dart';
import 'package:jeevandoot/api/auth_service.dart';
import 'package:jeevandoot/l10n/app_strings.dart';
import 'package:jeevandoot/models/doctor_models.dart';
import 'package:jeevandoot/models/models.dart';
import 'package:jeevandoot/screens/asha/asha_home_screen.dart';
import 'package:jeevandoot/screens/doctor/doctor_home_screen.dart';
import 'package:jeevandoot/screens/home_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/common.dart';

enum LoginRole { patient, doctor, asha }

enum PatientAuthMode { signIn, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _headerImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAWW5HTyOUrphhsI3rHhGHEVEgnrcllB_Uuo3oSffCfJO6nrXrkQ4hV6QEV_v4nWdRffHQwtW6axEp_EJ6rxd0iiL27vsOIpiOHN9a5Sdl8Q5byNuTsE60Jx6oSBhXP28kz7uwNafxnBDqd-RayUVEttgRnQbDe8lOXF24u1Petdiag79JUAd2j_AbSkJtZpgMP9DvDEVIOwaRhIUX3Pkbf7-a_ltkVtw4ZyEveZRpVNyLgtfKsZ4j_';

  LoginRole _role = LoginRole.patient;
  PatientAuthMode _patientMode = PatientAuthMode.signIn;

  final _patientEmailController = TextEditingController();
  final _patientPasswordController = TextEditingController();
  final _patientNameController = TextEditingController();

  final _doctorIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  final _ashaEmailController = TextEditingController();
  final _ashaPasswordController = TextEditingController();
  bool _ashaObscurePassword = true;

  @override
  void dispose() {
    _patientEmailController.dispose();
    _patientPasswordController.dispose();
    _patientNameController.dispose();
    _doctorIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _patientSignIn() async {
    final email = _patientEmailController.text.trim();
    final password = _patientPasswordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.tr('Please enter your email and password.')),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final user = await AuthService(ApiClient.instance).signIn(
        email: email,
        password: password,
      );
      AppState.patientName = user.name;
      if (!mounted) return;
      _openHome();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.tr('Could not reach the server. Please try again.')),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _patientSignUp() async {
    final name = _patientNameController.text.trim();
    final email = _patientEmailController.text.trim();
    final password = _patientPasswordController.text;
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.tr('Please fill in all the required fields.')),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final user = await AuthService(ApiClient.instance).signUp(
        name: name,
        email: email,
        password: password,
      );
      AppState.patientName = user.name;
      if (!mounted) return;
      _openHome();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.tr('Could not reach the server. Please try again.')),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _doctorSignIn() async {
    final email = _doctorIdController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.tr('Please enter your Medical ID and password.')),
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final user = await AuthService(ApiClient.instance).signIn(
        email: email,
        password: password,
      );
      DoctorState.doctorName = user.name;
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DoctorHomeScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.tr('Could not reach the server. Please try again.')),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _ashaSignIn() {
    final email = _ashaEmailController.text.trim();
    final password = _ashaPasswordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.tr('Please enter your credentials.'))),
      );
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AshaHomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.containerMargin),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 480),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _headerImage(scheme),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.stackMd,
                      0,
                      AppSpacing.stackMd,
                      AppSpacing.stackMd,
                    ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _roleTabs(scheme),
                          const SizedBox(height: AppSpacing.stackMd),
                          if (_role == LoginRole.patient) ...[
                            _welcomeHeader(scheme),
                            const SizedBox(height: AppSpacing.stackLg),
                            if (_patientMode == PatientAuthMode.signIn) ...[
                              _patientSignInForm(scheme),
                            ] else ...[
                              _patientSignUpForm(scheme),
                            ],
                          ] else if (_role == LoginRole.doctor) ...[
                            _doctorForm(scheme),
                          ] else ...[
                            _ashaForm(scheme),
                          ],
                        ],
                      ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleTabs(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _roleTab(
              scheme,
              label: AppStrings.tr('Patient'),
              icon: Icons.person_outline,
              selected: _role == LoginRole.patient,
              onTap: () => setState(() => _role = LoginRole.patient),
            ),
          ),
          Expanded(
            child: _roleTab(
              scheme,
              label: AppStrings.tr('Doctor'),
              icon: Icons.medical_services_outlined,
              selected: _role == LoginRole.doctor,
              onTap: () => setState(() => _role = LoginRole.doctor),
            ),
          ),
          Expanded(
            child: _roleTab(
              scheme,
              label: AppStrings.tr('ASHA'),
              icon: Icons.health_and_safety_outlined,
              selected: _role == LoginRole.asha,
              onTap: () => setState(() => _role = LoginRole.asha),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleTab(
    ColorScheme scheme, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? scheme.surfaceContainerLowest : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelLg.copyWith(
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _doctorForm(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: AppStrings.tr('Welcome, Doctor '),
                style: AppTextStyles.displayHeroMobile
                    .copyWith(color: scheme.onSurface),
              ),
              const TextSpan(text: '🩺'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.unit),
        Text(
          AppStrings.tr('Sign in to manage your consultations and patients.'),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        _fieldLabel(scheme, AppStrings.tr('Medical ID / Email')),
        const SizedBox(height: AppSpacing.unit),
        _doctorField(
          scheme,
          controller: _doctorIdController,
          icon: Icons.badge_outlined,
          hint: AppStrings.tr('Enter ID or Email'),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _fieldLabel(scheme, AppStrings.tr('Password')),
        const SizedBox(height: AppSpacing.unit),
        _doctorField(
          scheme,
          controller: _passwordController,
          icon: Icons.lock_outline,
          hint: '••••••••',
          obscure: true,
          obscureToggle: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppStrings.tr('Password reset link sent.'))),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: scheme.secondary,
              textStyle: AppTextStyles.bodyMd,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: Text(AppStrings.tr('Forgot Password?')),
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        PillButton(
          label: AppStrings.tr('Sign In'),
          icon: Icons.login,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          onPressed: _doctorSignIn,
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, size: 18, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              AppStrings.tr('SECURE DOCTOR ACCESS'),
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.primary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.unit),
        Text(
          AppStrings.tr('Verified medical professionals only'),
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSm.copyWith(color: scheme.outline),
        ),
      ],
    );
  }

  Widget _ashaForm(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: AppStrings.tr('Welcome, ASHA '),
                style: AppTextStyles.displayHeroMobile
                    .copyWith(color: scheme.onSurface),
              ),
              const TextSpan(text: '🩺'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.unit),
        Text(
          AppStrings.tr('Sign in to manage your assigned families.'),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        _fieldLabel(scheme, AppStrings.tr('Email')),
        const SizedBox(height: AppSpacing.unit),
        _doctorField(
          scheme,
          controller: _ashaEmailController,
          icon: Icons.badge_outlined,
          hint: AppStrings.tr('Enter Email'),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _fieldLabel(scheme, AppStrings.tr('Password')),
        const SizedBox(height: AppSpacing.unit),
        _doctorField(
          scheme,
          controller: _ashaPasswordController,
          icon: Icons.lock_outline,
          hint: '••••••••',
          obscure: true,
          obscureToggle: () =>
              setState(() => _ashaObscurePassword = !_ashaObscurePassword),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        PillButton(
          label: AppStrings.tr('Sign In'),
          icon: Icons.login,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          onPressed: _ashaSignIn,
        ),
      ],
    );
  }

  Widget _fieldLabel(ColorScheme scheme, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
      ),
    );
  }

  Widget _doctorField(
    ColorScheme scheme, {
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
    VoidCallback? obscureToggle,
  }) {
    return Container(
      height: AppSpacing.touchTargetMin,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Icon(icon, color: scheme.onSurfaceVariant),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              onChanged: (_) => setState(() {}),
              style: AppTextStyles.bodyLg.copyWith(color: scheme.onSurface),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                suffixIcon: obscureToggle != null
                    ? IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: scheme.onSurfaceVariant,
                        ),
                        onPressed: obscureToggle,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerImage(ColorScheme scheme) {
    return SizedBox(
      height: 160,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _headerImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                ColoredBox(color: scheme.surfaceContainerLow),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.surfaceContainerLowest.withValues(alpha: 0),
                  AppColors.surfaceContainerLowest,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcomeHeader(ColorScheme scheme) {
    return Column(
      children: [
        Transform.translate(
          offset: const Offset(0, -24),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: AppStrings.tr('Welcome to JeevanDoot '),
                  style: AppTextStyles.displayHeroMobile
                      .copyWith(color: scheme.onSurface),
                ),
                const TextSpan(text: '👋'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Text(
              _patientMode == PatientAuthMode.signIn
                  ? AppStrings.tr('Sign in to your account to continue.')
                  : AppStrings.tr('Create your account to get started.'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }

  Widget _patientSignInForm(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(scheme, AppStrings.tr('Email')),
        const SizedBox(height: AppSpacing.unit),
        _doctorField(
          scheme,
          controller: _patientEmailController,
          icon: Icons.mail_outline,
          hint: AppStrings.tr('Enter your email'),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _fieldLabel(scheme, AppStrings.tr('Password')),
        const SizedBox(height: AppSpacing.unit),
        _patientPasswordField(scheme),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.tr('Password reset link sent to your email.')),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: scheme.secondary,
              textStyle: AppTextStyles.bodyMd,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: Text(AppStrings.tr('Forgot Password?')),
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        PillButton(
          label: AppStrings.tr('Sign In'),
          icon: Icons.login,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          onPressed: _submitting ? null : _patientSignIn,
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _authSwitchRow(scheme, isSignUp: false),
      ],
    );
  }

  Widget _patientSignUpForm(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(scheme, AppStrings.tr('Full Name')),
        const SizedBox(height: AppSpacing.unit),
        _doctorField(
          scheme,
          controller: _patientNameController,
          icon: Icons.person_outline,
          hint: AppStrings.tr('Enter your full name'),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _fieldLabel(scheme, AppStrings.tr('Email')),
        const SizedBox(height: AppSpacing.unit),
        _doctorField(
          scheme,
          controller: _patientEmailController,
          icon: Icons.mail_outline,
          hint: AppStrings.tr('Enter your email'),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _fieldLabel(scheme, AppStrings.tr('Password')),
        const SizedBox(height: AppSpacing.unit),
        _patientPasswordField(scheme),
        const SizedBox(height: AppSpacing.stackMd),
        PillButton(
          label: AppStrings.tr('Create Account'),
          icon: Icons.person_add_alt_1,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          onPressed: _submitting ? null : _patientSignUp,
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _authSwitchRow(scheme, isSignUp: true),
      ],
    );
  }

  Widget _patientPasswordField(ColorScheme scheme) {
    return _doctorField(
      scheme,
      controller: _patientPasswordController,
      icon: Icons.lock_outline,
      hint: AppStrings.tr('Enter your password'),
      obscure: true,
      obscureToggle: () => setState(() => _obscurePassword = !_obscurePassword),
    );
  }

  Widget _authSwitchRow(ColorScheme scheme, {required bool isSignUp}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isSignUp ? AppStrings.tr('Already have an account? ') : AppStrings.tr('New to JeevanDoot? '),
          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
        ),
        TextButton(
          onPressed: () => setState(() {
            _patientMode = isSignUp
                ? PatientAuthMode.signIn
                : PatientAuthMode.signUp;
          }),
          style: TextButton.styleFrom(
            foregroundColor: scheme.primary,
            textStyle: AppTextStyles.labelLg,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: Text(isSignUp ? AppStrings.tr('Sign In') : AppStrings.tr('Sign Up')),
        ),
      ],
    );
  }
}
