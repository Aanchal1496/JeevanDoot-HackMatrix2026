import 'package:flutter/material.dart';
import 'package:jeevandoot/screens/login_screen.dart';
import 'package:jeevandoot/theme/app_theme.dart';
import 'package:jeevandoot/widgets/common.dart';

class Language {
  const Language(this.code, this.native, this.name, this.flag, this.isFullWidth);

  final String code;
  final String native;
  final String name;
  final String flag;
  final bool isFullWidth;
}

const List<Language> _languages = [
  Language('hi', 'हिंदी', 'Hindi', '🇮🇳', true),
  Language('en', 'English', 'English', '🌐', false),
  Language('mr', 'मराठी', 'Marathi', '🌿', false),
  Language('gu', 'ગુજરાતી', 'Gujarati', '🦁', false),
  Language('ta', 'தமிழ்', 'Tamil', '🐘', false),
];

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selected = 'hi';

  static const String _heroImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDck7NSk2ZNbT558fOQG3LPKj4nTvt1qb9kvj-KPwIWnvnHnuTm042PJxiieGNvHzKYNJZFJzO2_WmR46txPySHLxq8Tvwb4Rl62dYmYKZkkHKPb6qOMqRB-PYPWqeU7cKmCf-ns1FuNXwf4ex9uUUu3nrznmwQ9Am6rh7zItmahVgrJDdq2Nk5mOymN7Ga8su4XXLD9-jOLjeHo3Ksx0T2nnwJtcO75t8uuMo45tF3UFwgXL9BeUrO';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.containerMargin,
                AppSpacing.stackMd,
                AppSpacing.containerMargin,
                AppSpacing.gutter,
              ),
              child: Text(
                'JeevanDoot',
                style: AppTextStyles.headlineLgMobile.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin,
                  0,
                  AppSpacing.containerMargin,
                  AppSpacing.stackLg,
                ),
                child: Column(
                  children: [
                    _hero(scheme),
                    const SizedBox(height: AppSpacing.stackMd),
                    _welcomeText(scheme),
                    const SizedBox(height: AppSpacing.stackLg),
                    _languageGrid(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.containerMargin),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surfaceBright.withValues(alpha: 0),
              AppColors.surfaceBright,
              AppColors.surfaceBright,
            ],
            stops: const [0, 0.4, 1],
          ),
        ),
        child: PillButton(
          label: 'Continue',
          icon: Icons.arrow_forward,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
      ),
    );
  }

  Widget _hero(ColorScheme scheme) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 200),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          _heroImageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _heroFallback(scheme),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _heroFallback(scheme);
          },
        ),
      ),
    );
  }

  Widget _heroFallback(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.medical_services,
          size: 56,
          color: scheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _welcomeText(ColorScheme scheme) {
    return Column(
      children: [
        Text(
          'Your health, closer to home.',
          textAlign: TextAlign.center,
          style: AppTextStyles.displayHeroMobile.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.unit),
        Text(
          'Get trusted healthcare support in your language.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _languageGrid() {
    return Column(
      children: [
        _languageCard(_languages[0], fullWidth: true),
        const SizedBox(height: AppSpacing.gutter),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _languageCard(_languages[1], fullWidth: false)),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(child: _languageCard(_languages[2], fullWidth: false)),
          ],
        ),
        const SizedBox(height: AppSpacing.gutter),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _languageCard(_languages[3], fullWidth: false)),
            const SizedBox(width: AppSpacing.gutter),
            Expanded(child: _languageCard(_languages[4], fullWidth: false)),
          ],
        ),
      ],
    );
  }

  Widget _languageCard(Language lang, {required bool fullWidth}) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selected == lang.code;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      transform: Matrix4.diagonal3Values(selected ? 1.02 : 1.0, selected ? 1.02 : 1.0, 1),
      child: Material(
        color: selected ? scheme.surfaceContainer : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => setState(() => _selected = lang.code),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.gutter),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                width: 2,
                color: selected ? scheme.primary : scheme.surfaceContainerHighest,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: fullWidth
                ? Row(
                    children: [
                      _flagCircle(scheme, lang.flag),
                      const SizedBox(width: AppSpacing.gutter),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.native,
                              style: AppTextStyles.headlineMd
                                  .copyWith(color: scheme.onSurface),
                            ),
                            Text(
                              lang.name,
                              style: AppTextStyles.bodyMd
                                  .copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      _checkIcon(scheme, selected),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang.native,
                            style: AppTextStyles.headlineMd
                                .copyWith(color: scheme.onSurface),
                          ),
                          _checkIcon(scheme, selected),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lang.name,
                        style: AppTextStyles.bodyMd
                            .copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _flagCircle(ColorScheme scheme, String flag) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(flag, style: const TextStyle(fontSize: 20)),
    );
  }

  Widget _checkIcon(ColorScheme scheme, bool selected) {
    return Icon(
      selected ? Icons.check_circle : Icons.radio_button_unchecked,
      color: selected ? scheme.primary : scheme.outlineVariant,
      size: 24,
    );
  }

}
