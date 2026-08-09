import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jeevandoot/screens/doctor/doctor_home_screen.dart';
import 'package:jeevandoot/screens/home_screen.dart';
import 'package:jeevandoot/services/api_client.dart';
import 'package:jeevandoot/services/backend.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/common.dart';

enum LoginRole { patient, doctor }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _headerImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAWW5HTyOUrphhsI3rHhGHEVEgnrcllB_Uuo3oSffCfJO6nrXrkQ4hV6QEV_v4nWdRffHQwtW6axEp_EJ6rxd0iiL27vsOIpiOHN9a5Sdl8Q5byNuTsE60Jx6oSBhXP28kz7uwNafxnBDqd-RayUVEttgRnQbDe8lOXF24u1Petdiag79JUAd2j_AbSkJtZpgMP9DvDEVIOwaRhIUX3Pkbf7-a_ltkVtw4ZyEveZRpVNyLgtfKsZ4j_';

  LoginRole _role = LoginRole.patient;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _doctorIdController = TextEditingController();
  bool _obscurePassword = true;

  bool _isSignUp = true;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _doctorIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isDoctor = _role == LoginRole.doctor;
    final identifier = isDoctor ? _doctorIdController.text : _phoneController.text;
    final name = _nameController.text;
    final password = _passwordController.text;
    if (_isSignUp && name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name.')),
      );
      return;
    }
    if (!isDoctor && identifier.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number.'),
        ),
      );
      return;
    }
    if (identifier.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isDoctor ? 'Please enter your Medical ID.' : 'Please enter your mobile number.'),
        ),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final roleKey = isDoctor ? 'doctor' : 'patient';
      final role = _isSignUp
          ? await signUpLocal(
              role: roleKey,
              name: name,
              phone: identifier,
              password: password,
            )
          : await loginLocal(
              role: roleKey,
              phone: identifier,
              password: password,
            );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => role == 'doctor'
              ? const DoctorHomeScreen()
              : const HomeScreen(),
        ),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    }
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
                          if (_isSignUp) ...[
                            _fieldLabel(scheme, 'Full Name'),
                            const SizedBox(height: AppSpacing.unit),
                            _authField(
                              scheme,
                              controller: _nameController,
                              icon: Icons.person_outline,
                              hint: 'Enter your name',
                            ),
                            const SizedBox(height: AppSpacing.stackMd),
                          ],
                          _fieldLabel(scheme, 'Mobile Number'),
                          const SizedBox(height: AppSpacing.unit),
                          _phoneField(scheme),
                          const SizedBox(height: AppSpacing.stackMd),
                          _fieldLabel(scheme, 'Password'),
                          const SizedBox(height: AppSpacing.unit),
                          _authField(
                            scheme,
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            hint: 'Minimum 4 characters',
                            obscure: true,
                            obscureToggle: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ] else ...[
                          _doctorHeader(scheme),
                          const SizedBox(height: AppSpacing.stackLg),
                          if (_isSignUp) ...[
                            _fieldLabel(scheme, 'Full Name'),
                            const SizedBox(height: AppSpacing.unit),
                            _authField(
                              scheme,
                              controller: _nameController,
                              icon: Icons.person_outline,
                              hint: 'Enter your name',
                            ),
                            const SizedBox(height: AppSpacing.stackMd),
                          ],
                          _fieldLabel(scheme, 'Medical ID / Email'),
                          const SizedBox(height: AppSpacing.unit),
                          _authField(
                            scheme,
                            controller: _doctorIdController,
                            icon: Icons.badge_outlined,
                            hint: 'Enter ID or Email',
                          ),
                          const SizedBox(height: AppSpacing.stackMd),
                          _fieldLabel(scheme, 'Password'),
                          const SizedBox(height: AppSpacing.unit),
                          _authField(
                            scheme,
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            hint: 'Minimum 4 characters',
                            obscure: true,
                            obscureToggle: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Password reset link sent.')),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: scheme.secondary,
                                textStyle: AppTextStyles.bodyMd,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.stackMd),
                        PillButton(
                          label: _busy
                              ? 'Please wait…'
                              : (_isSignUp ? 'Create Account' : 'Login'),
                          icon: _isSignUp ? Icons.person_add : Icons.login,
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          loading: _busy,
                          onPressed: _submit,
                        ),
                        const SizedBox(height: AppSpacing.stackSm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignUp
                                  ? 'Already have an account?'
                                  : 'New to JeevanDoot?',
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: scheme.onSurfaceVariant),
                            ),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(
                                      () => _isSignUp = !_isSignUp),
                              style: TextButton.styleFrom(
                                foregroundColor: scheme.primary,
                                textStyle: AppTextStyles.labelLg,
                              ),
                              child: Text(_isSignUp ? 'Login' : 'Create Account'),
                            ),
                          ],
                        ),
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
              label: 'Patient',
              icon: Icons.person_outline,
              selected: _role == LoginRole.patient,
              onTap: () => setState(() => _role = LoginRole.patient),
            ),
          ),
          Expanded(
            child: _roleTab(
              scheme,
              label: 'Doctor',
              icon: Icons.medical_services_outlined,
              selected: _role == LoginRole.doctor,
              onTap: () => setState(() => _role = LoginRole.doctor),
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

  Widget _fieldLabel(ColorScheme scheme, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
      ),
    );
  }

  Widget _authField(
    ColorScheme scheme, {
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
    VoidCallback? obscureToggle,
    TextInputType? keyboardType,
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
              keyboardType: keyboardType,
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

  Widget _phoneField(ColorScheme scheme) {
    return Container(
      height: AppSpacing.touchTargetMin,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              border: Border(
                right: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            child: Text(
              '+91',
              style:
                  AppTextStyles.bodyLg.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: AppTextStyles.bodyLg.copyWith(
                color: scheme.onSurface,
                letterSpacing: 1,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: 'XXXXX XXXXX',
                hintStyle: TextStyle(color: scheme.onSurfaceVariant),
              ),
              onChanged: (_) => setState(() {}),
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
                  text: 'Welcome to JeevanDoot ',
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
              'Create an account or login to continue.',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }

  Widget _doctorHeader(ColorScheme scheme) {
    return Column(
      children: [
        Transform.translate(
          offset: const Offset(0, -24),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Welcome, Doctor ',
                  style: AppTextStyles.displayHeroMobile
                      .copyWith(color: scheme.onSurface),
                ),
                const TextSpan(text: '🩺'),
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
              'Sign in to manage your consultations and patients.',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}
