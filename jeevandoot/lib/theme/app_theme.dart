import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Design tokens extracted from the patient-side design system.
abstract final class AppSpacing {
  static const double unit = 8;
  static const double gutter = 16;
  static const double stackSm = 12;
  static const double stackMd = 24;
  static const double stackLg = 40;
  static const double containerMargin = 20;
  static const double touchTargetMin = 56;
}

/// Typography tokens (Public Sans based) from the design system.
abstract final class AppTextStyles {
  // display-hero-mobile: 28/36 w700
  static const TextStyle displayHeroMobile = TextStyle(
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  // headline-lg-mobile: 22/30 w700
  static const TextStyle headlineLgMobile = TextStyle(
    fontSize: 22,
    height: 30 / 22,
    fontWeight: FontWeight.w700,
  );

  // headline-lg: 24/32 w700
  static const TextStyle headlineLg = TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
  );

  // headline-md: 20/28 w600
  static const TextStyle headlineMd = TextStyle(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
  );

  // display-hero: 32/40 w700
  static const TextStyle displayHero = TextStyle(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  // body-lg: 18/28 w400
  static const TextStyle bodyLg = TextStyle(
    fontSize: 18,
    height: 28 / 18,
    fontWeight: FontWeight.w400,
  );

  // body-md: 16/24 w400
  static const TextStyle bodyMd = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );

  // label-lg: 16/20 ls0.5 w600
  static const TextStyle labelLg = TextStyle(
    fontSize: 16,
    height: 20 / 16,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle labelSm = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
  );
}

/// The JeevanDoot light color scheme, exactly matching the HTML tokens.
class AppColors {
  static const Color primary = Color(0xFF006B5E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF00A693);
  static const Color onPrimaryContainer = Color(0xFF00332C);
  static const Color primaryFixed = Color(0xFF7AF7E1);
  static const Color primaryFixedDim = Color(0xFF5BDAC6);
  static const Color onPrimaryFixed = Color(0xFF00201B);
  static const Color onPrimaryFixedVariant = Color(0xFF005046);

  static const Color secondary = Color(0xFF526069);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD3E2ED);
  static const Color onSecondaryContainer = Color(0xFF56656E);
  static const Color secondaryFixed = Color(0xFFD6E5EF);
  static const Color secondaryFixedDim = Color(0xFFBAC9D3);
  static const Color onSecondaryFixed = Color(0xFF0F1D25);
  static const Color onSecondaryFixedVariant = Color(0xFF3B4951);

  static const Color tertiary = Color(0xFF7E5700);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFC38800);
  static const Color onTertiaryContainer = Color(0xFF3D2800);
  static const Color tertiaryFixed = Color(0xFFFFDEAC);
  static const Color tertiaryFixedDim = Color(0xFFFFBA38);
  static const Color onTertiaryFixed = Color(0xFF281900);
  static const Color onTertiaryFixedVariant = Color(0xFF604100);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color background = Color(0xFFF3FAFF);
  static const Color onBackground = Color(0xFF071E27);
  static const Color surface = Color(0xFFF3FAFF);
  static const Color onSurface = Color(0xFF071E27);
  static const Color surfaceDim = Color(0xFFC7DDE9);
  static const Color surfaceBright = Color(0xFFF3FAFF);
  static const Color surfaceVariant = Color(0xFFCFE6F2);
  static const Color onSurfaceVariant = Color(0xFF3C4946);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFE6F6FF);
  static const Color surfaceContainer = Color(0xFFDBF1FE);
  static const Color surfaceContainerHigh = Color(0xFFD5ECF8);
  static const Color surfaceContainerHighest = Color(0xFFCFE6F2);

  static const Color outline = Color(0xFF6C7A76);
  static const Color outlineVariant = Color(0xFFBBCAC5);

  static const Color inverseSurface = Color(0xFF1E333C);
  static const Color onInverseSurface = Color(0xFFDFF4FF);
  static const Color inversePrimary = Color(0xFF5BDAC6);
  static const Color surfaceTint = Color(0xFF006B5E);

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    surfaceDim: surfaceDim,
    surfaceBright: surfaceBright,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    inverseSurface: inverseSurface,
    onInverseSurface: onInverseSurface,
    inversePrimary: inversePrimary,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: surfaceTint,
    primaryFixed: primaryFixed,
    primaryFixedDim: primaryFixedDim,
    onPrimaryFixed: onPrimaryFixed,
    onPrimaryFixedVariant: onPrimaryFixedVariant,
    secondaryFixed: secondaryFixed,
    secondaryFixedDim: secondaryFixedDim,
    onSecondaryFixed: onSecondaryFixed,
    onSecondaryFixedVariant: onSecondaryFixedVariant,
    tertiaryFixed: tertiaryFixed,
    tertiaryFixedDim: tertiaryFixedDim,
    onTertiaryFixed: onTertiaryFixed,
    onTertiaryFixedVariant: onTertiaryFixedVariant,
  );
}

/// Shared subtle page transition used across the app for a cohesive feel.
const PageTransitionsTheme kPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
    TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
    TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
    TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
    TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
  },
);

/// Scroll behavior that keeps Material scrolling on all platforms.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

/// The JeevanDoot doctor-side color scheme, matching the doctor.html tokens.
class DoctorAppColors {
  static const Color primary = Color(0xFF00685F);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF008378);
  static const Color onPrimaryContainer = Color(0xFFF4FFFC);
  static const Color primaryFixed = Color(0xFF89F5E7);
  static const Color primaryFixedDim = Color(0xFF6BD8CB);
  static const Color onPrimaryFixed = Color(0xFF00201D);
  static const Color onPrimaryFixedVariant = Color(0xFF005049);

  static const Color secondary = Color(0xFF0051D5);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF316BF3);
  static const Color onSecondaryContainer = Color(0xFFFEFCFF);
  static const Color secondaryFixed = Color(0xFFDBE1FF);
  static const Color secondaryFixedDim = Color(0xFFB4C5FF);
  static const Color onSecondaryFixed = Color(0xFF00174B);
  static const Color onSecondaryFixedVariant = Color(0xFF003EA8);

  static const Color tertiary = Color(0xFF924628);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFB05E3D);
  static const Color onTertiaryContainer = Color(0xFFFFFBFF);
  static const Color tertiaryFixed = Color(0xFFFFDBCE);
  static const Color tertiaryFixedDim = Color(0xFFFFB59A);
  static const Color onTertiaryFixed = Color(0xFF370E00);
  static const Color onTertiaryFixedVariant = Color(0xFF773215);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color background = Color(0xFFF8F9FF);
  static const Color onBackground = Color(0xFF0B1C30);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color surfaceDim = Color(0xFFCBDBF5);
  static const Color surfaceBright = Color(0xFFF8F9FF);
  static const Color onSurfaceVariant = Color(0xFF3D4947);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);

  static const Color outline = Color(0xFF6D7A77);
  static const Color outlineVariant = Color(0xFFBCC9C6);

  static const Color inverseSurface = Color(0xFF213145);
  static const Color onInverseSurface = Color(0xFFEAF1FF);
  static const Color inversePrimary = Color(0xFF6BD8CB);
  static const Color surfaceTint = Color(0xFF006A61);

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    surfaceDim: surfaceDim,
    surfaceBright: surfaceBright,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    inverseSurface: inverseSurface,
    onInverseSurface: onInverseSurface,
    inversePrimary: inversePrimary,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: surfaceTint,
    primaryFixed: primaryFixed,
    primaryFixedDim: primaryFixedDim,
    onPrimaryFixed: onPrimaryFixed,
    onPrimaryFixedVariant: onPrimaryFixedVariant,
    secondaryFixed: secondaryFixed,
    secondaryFixedDim: secondaryFixedDim,
    onSecondaryFixed: onSecondaryFixed,
    onSecondaryFixedVariant: onSecondaryFixedVariant,
    tertiaryFixed: tertiaryFixed,
    tertiaryFixedDim: tertiaryFixedDim,
    onTertiaryFixed: onTertiaryFixed,
    onTertiaryFixedVariant: onTertiaryFixedVariant,
  );
}

ThemeData buildDoctorTheme() {
  final scheme = DoctorAppColors.lightScheme;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: DoctorAppColors.background,
    fontFamilyFallback: const ['Inter', 'Helvetica', 'Arial'],
    textTheme: ThemeData.light().textTheme.copyWith(
          displayLarge: AppTextStyles.displayHero,
          headlineLarge: AppTextStyles.headlineLg,
          headlineMedium: AppTextStyles.headlineMd,
          titleLarge: AppTextStyles.headlineLgMobile,
          bodyLarge: AppTextStyles.bodyLg,
          bodyMedium: AppTextStyles.bodyMd,
          labelLarge: AppTextStyles.labelLg,
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: DoctorAppColors.surface,
      elevation: 0,
      titleTextStyle: AppTextStyles.headlineLgMobile
          .copyWith(color: DoctorAppColors.primary, fontWeight: FontWeight.bold),
      iconTheme: const IconThemeData(color: DoctorAppColors.primary),
    ),
    pageTransitionsTheme: kPageTransitions,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: scheme.primary,
      selectionColor: scheme.primary.withValues(alpha: 0.25),
      selectionHandleColor: scheme.primary,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: AppTextStyles.bodyMd.copyWith(color: scheme.onInverseSurface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: AppColors.lightScheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamilyFallback: const ['Public Sans', 'Helvetica', 'Arial'],
  );

  final scheme = AppColors.lightScheme;

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge: AppTextStyles.displayHero,
      headlineLarge: AppTextStyles.headlineLg,
      headlineMedium: AppTextStyles.headlineMd,
      titleLarge: AppTextStyles.headlineLgMobile,
      bodyLarge: AppTextStyles.bodyLg,
      bodyMedium: AppTextStyles.bodyMd,
      labelLarge: AppTextStyles.labelLg,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface.withValues(alpha: 0.8),
      elevation: 0,
      titleTextStyle: AppTextStyles.headlineLgMobile
          .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
      iconTheme: const IconThemeData(color: AppColors.primary),
    ),
    pageTransitionsTheme: kPageTransitions,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.primary.withValues(alpha: 0.25),
      selectionHandleColor: AppColors.primary,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
        textStyle: AppTextStyles.labelLg,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.unit,
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.outlineVariant),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: AppTextStyles.bodyMd.copyWith(color: scheme.onInverseSurface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
