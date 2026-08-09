import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jeevandoot/screens/doctor/doctor_home_screen.dart';
import 'package:jeevandoot/screens/home_screen.dart';
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

  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());

  final _doctorIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  bool _otpVisible = false;
  int _secondsRemaining = 59;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _doctorIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 59);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) timer.cancel();
      });
    });
  }

  void _requestOtp() {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number.')),
      );
      return;
    }
    setState(() => _otpVisible = true);
    _startCountdown();
    // Autofocus the first OTP box once revealed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocusNodes.first.requestFocus();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP sent to your mobile number.')),
    );
  }

  void _verifyOtp() {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit OTP.')),
      );
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _doctorSignIn() {
    final id = _doctorIdController.text.trim();
    final password = _passwordController.text;
    if (id.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your Medical ID and password.'),
        ),
      );
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DoctorHomeScreen()),
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
                            _phoneField(scheme),
                            const SizedBox(height: AppSpacing.stackMd),
                            _getOtpButton(scheme),
                            if (_otpVisible) ...[
                              const SizedBox(height: AppSpacing.stackMd),
                              _divider(scheme),
                              const SizedBox(height: AppSpacing.stackMd),
                              _otpSection(scheme),
                              const SizedBox(height: AppSpacing.stackMd),
                              _verifyButton(scheme),
                              const SizedBox(height: AppSpacing.stackMd),
                              _resendRow(scheme),
                            ],
                          ] else ...[
                            _doctorForm(scheme),
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

  Widget _doctorForm(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
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
        const SizedBox(height: AppSpacing.unit),
        Text(
          'Sign in to manage your consultations and patients.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.stackLg),
        _fieldLabel(scheme, 'Medical ID / Email'),
        const SizedBox(height: AppSpacing.unit),
        _doctorField(
          scheme,
          controller: _doctorIdController,
          icon: Icons.badge_outlined,
          hint: 'Enter ID or Email',
        ),
        const SizedBox(height: AppSpacing.stackMd),
        _fieldLabel(scheme, 'Password'),
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
                const SnackBar(content: Text('Password reset link sent.')),
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
        const SizedBox(height: AppSpacing.stackMd),
        PillButton(
          label: 'Sign In',
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
              'SECURE DOCTOR ACCESS',
              style: AppTextStyles.labelSm.copyWith(
                color: scheme.primary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.unit),
        Text(
          'Verified medical professionals only',
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSm.copyWith(color: scheme.outline),
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
              'Enter your mobile number to continue.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }

  Widget _phoneField(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Mobile Number',
            style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
          ),
        ),
        const SizedBox(height: AppSpacing.unit),
        Container(
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
                  style: AppTextStyles.bodyLg.copyWith(color: scheme.onSurfaceVariant),
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
        ),
      ],
    );
  }

  Widget _getOtpButton(ColorScheme scheme) {
    return PillButton(
      label: 'Get OTP',
      icon: Icons.arrow_forward,
      backgroundColor: scheme.secondaryContainer,
      foregroundColor: scheme.onSecondaryContainer,
      onPressed: _otpVisible ? null : _requestOtp,
    );
  }

  Widget _divider(ColorScheme scheme) {
    return Opacity(
      opacity: 0.5,
      child: Row(
        children: [
          Expanded(child: Divider(color: scheme.outlineVariant)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.lock, size: 16, color: scheme.outlineVariant),
          ),
          Expanded(child: Divider(color: scheme.outlineVariant)),
        ],
      ),
    );
  }

  Widget _otpSection(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Enter 6-digit OTP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLg.copyWith(color: scheme.onSurface),
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _secondsRemaining > 0
                    ? '00:${_secondsRemaining.toString().padLeft(2, '0')}'
                    : 'Resend available',
                maxLines: 1,
                style: AppTextStyles.bodyMd.copyWith(color: scheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.unit),
        Row(
          children: [
            for (var i = 0; i < 6; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 5 ? 6 : 0),
                  child: _otpBox(scheme, i),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _otpBox(ColorScheme scheme, int index) {
    return SizedBox(
      height: 56,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        maxLength: 1,
        textAlign: TextAlign.center,
        style: AppTextStyles.headlineLg.copyWith(color: scheme.onSurface),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          setState(() {});
          if (value.isNotEmpty) {
            if (index < 5) {
              _otpFocusNodes[index + 1].requestFocus();
            } else {
              _otpFocusNodes[index].unfocus();
            }
          }
        },
        onTapOutside: (_) => _otpFocusNodes[index].unfocus(),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: _otpControllers[index].text.isNotEmpty
              ? scheme.primaryContainer.withValues(alpha: 0.1)
              : scheme.surfaceContainerLowest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: _otpControllers[index].text.isNotEmpty
                  ? scheme.primary
                  : scheme.outlineVariant,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: _otpControllers[index].text.isNotEmpty
                  ? scheme.primary
                  : scheme.outlineVariant,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _verifyButton(ColorScheme scheme) {
    return PillButton(
      label: 'Verify & Continue',
      icon: Icons.verified_user,
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      onPressed: _verifyOtp,
    );
  }

  Widget _resendRow(ColorScheme scheme) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Didn't receive the code?",
            style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
          ),
          TextButton(
            onPressed: _secondsRemaining > 0 ? null : _requestOtp,
            style: TextButton.styleFrom(
              foregroundColor: scheme.primary,
              textStyle: AppTextStyles.labelLg,
            ),
            child: const Text('Resend'),
          ),
        ],
      ),
    );
  }
}
