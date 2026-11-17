import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Brand accent (matches the app icon).
const Color kAccent = Color(0xFFFF91C5);

const Color kLate = Color(0xFFE5484D);
const Color kOnTime = Color(0xFF30A46C);

/// Design tokens that the Material [ColorScheme] can't express.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color card;
  final Color elevated;
  final Color hairline;
  final Color label;
  final Color labelSecondary;
  final Color labelTertiary;
  final Color accent;
  final Color accentSoft; // predicted days
  final Color onAccent;
  final Color late;
  final Color onTime;

  const AppColors({
    required this.background,
    required this.card,
    required this.elevated,
    required this.hairline,
    required this.label,
    required this.labelSecondary,
    required this.labelTertiary,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.late,
    required this.onTime,
  });

  static const AppColors light = AppColors(
    background: Color(0xFFF5F3F1),
    card: Color(0xFFFFFFFF),
    elevated: Color(0xFFFFFFFF),
    hairline: Color(0xFFE4E0DC),
    label: Color(0xFF111111),
    labelSecondary: Color(0xFF6B6966),
    labelTertiary: Color(0xFFA3A09C),
    accent: kAccent,
    accentSoft: Color(0x2EFF91C5), // 18%
    onAccent: Color(0xFF111111),
    late: kLate,
    onTime: kOnTime,
  );

  static const AppColors dark = AppColors(
    background: Color(0xFF000000),
    card: Color(0xFF1C1C1E),
    elevated: Color(0xFF2C2C2E),
    hairline: Color(0xFF38383A),
    label: Color(0xFFFFFFFF),
    labelSecondary: Color(0xFF9C9CA1),
    labelTertiary: Color(0xFF636366),
    accent: kAccent,
    accentSoft: Color(0x38FF91C5), // 22% on black
    onAccent: Color(0xFF111111),
    late: Color(0xFFFF6369),
    onTime: Color(0xFF3DD68C),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? card,
    Color? elevated,
    Color? hairline,
    Color? label,
    Color? labelSecondary,
    Color? labelTertiary,
    Color? accent,
    Color? accentSoft,
    Color? onAccent,
    Color? late,
    Color? onTime,
  }) {
    return AppColors(
      background: background ?? this.background,
      card: card ?? this.card,
      elevated: elevated ?? this.elevated,
      hairline: hairline ?? this.hairline,
      label: label ?? this.label,
      labelSecondary: labelSecondary ?? this.labelSecondary,
      labelTertiary: labelTertiary ?? this.labelTertiary,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
      late: late ?? this.late,
      onTime: onTime ?? this.onTime,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      label: Color.lerp(label, other.label, t)!,
      labelSecondary: Color.lerp(labelSecondary, other.labelSecondary, t)!,
      labelTertiary: Color.lerp(labelTertiary, other.labelTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      late: Color.lerp(late, other.late, t)!,
      onTime: Color.lerp(onTime, other.onTime, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

/// Type scale. Tracking is size-specific: tight on large text, slightly open on small.
class AppText {
  static TextStyle _inter(double size, FontWeight weight, double tracking, double height, Color color) => TextStyle(
    fontFamily: 'Inter', // bundled, no network
    fontSize: size,
    fontWeight: weight,
    letterSpacing: tracking,
    height: height,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextTheme build(AppColors c) => TextTheme(
    displayLarge: _inter(64, FontWeight.w700, -1.6, 1.0, c.label), // hero numbers
    displayMedium: _inter(44, FontWeight.w700, -1.0, 1.05, c.label), // stat values
    headlineLarge: _inter(32, FontWeight.w700, -0.7, 1.12, c.label), // large title
    headlineMedium: _inter(28, FontWeight.w700, -0.6, 1.14, c.label),
    headlineSmall: _inter(24, FontWeight.w700, -0.5, 1.16, c.label),
    titleLarge: _inter(22, FontWeight.w600, -0.4, 1.2, c.label),
    titleMedium: _inter(17, FontWeight.w600, -0.25, 1.25, c.label),
    titleSmall: _inter(15, FontWeight.w600, -0.1, 1.3, c.label),
    bodyLarge: _inter(17, FontWeight.w400, -0.2, 1.35, c.label),
    bodyMedium: _inter(15, FontWeight.w400, -0.1, 1.4, c.label),
    bodySmall: _inter(13, FontWeight.w400, 0.05, 1.4, c.labelSecondary),
    labelLarge: _inter(16, FontWeight.w600, -0.2, 1.2, c.label),
    labelMedium: _inter(13, FontWeight.w500, 0.05, 1.3, c.labelSecondary),
    labelSmall: _inter(11, FontWeight.w600, 0.6, 1.3, c.labelSecondary), // tab labels, weekday letters
  );
}

ThemeData buildTheme(Brightness brightness) {
  final bool isDark = brightness == Brightness.dark;
  final AppColors c = isDark ? AppColors.dark : AppColors.light;

  final ColorScheme cs = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    primaryContainer: c.card,
    onPrimaryContainer: c.label,
    secondary: c.elevated,
    onSecondary: c.label,
    secondaryContainer: c.accentSoft,
    onSecondaryContainer: c.label,
    tertiary: c.labelSecondary,
    onTertiary: c.card,
    tertiaryContainer: c.hairline,
    onTertiaryContainer: c.label,
    error: c.late,
    onError: Colors.white,
    errorContainer: c.late.withValues(alpha: 0.15),
    onErrorContainer: c.late,
    surface: c.background,
    onSurface: c.label,
    surfaceContainerHighest: c.card,
    onSurfaceVariant: c.labelSecondary,
    outline: c.hairline,
    outlineVariant: c.hairline,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: c.label,
    onInverseSurface: c.background,
    inversePrimary: c.accent,
  );

  final TextTheme textTheme = AppText.build(c);
  const StadiumBorder stadium = StadiumBorder();

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: cs,
    textTheme: textTheme,
    scaffoldBackgroundColor: c.background,
    canvasColor: c.background,
    extensions: [c],
    splashFactory: NoSplash.splashFactory, // press feedback is handled by Pressable
    highlightColor: Colors.transparent,
    dividerTheme: DividerThemeData(color: c.hairline, thickness: 0.5, space: 0.5),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: PredictiveBackPageTransitionsBuilder(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder()},
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: c.label,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.titleMedium,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: c.labelSecondary),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: c.card,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.label,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: c.background),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.accent : (isDark ? const Color(0xFF39393D) : const Color(0xFFD9D5D1)),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.card,
      hintStyle: textTheme.bodyLarge?.copyWith(color: c.labelTertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.accent, width: 2),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: c.accent, selectionColor: c.accent.withValues(alpha: 0.35), selectionHandleColor: c.accent),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        elevation: 0,
        minimumSize: const Size(0, 52),
        shape: stadium,
        textStyle: textTheme.labelLarge,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        minimumSize: const Size(0, 52),
        shape: stadium,
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: c.label, shape: stadium, textStyle: textTheme.labelLarge),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: c.label)),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: const WidgetStatePropertyAll(BorderSide.none),
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.accent : c.card),
        foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.onAccent : c.labelSecondary),
        textStyle: WidgetStatePropertyAll(textTheme.titleSmall),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: c.card,
      hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      hourMinuteTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 34, fontWeight: FontWeight.w500), // the default is 57sp, far too big
      dialHandColor: c.accent,
      dialBackgroundColor: c.background,
      hourMinuteColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? c.accent : c.background),
      hourMinuteTextColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? c.onAccent : c.label),
      dayPeriodColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? c.accent : c.background),
      dayPeriodTextColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? c.onAccent : c.label),
      dialTextColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? c.onAccent : c.label),
      entryModeIconColor: c.labelSecondary,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: c.card,
      surfaceTintColor: Colors.transparent,
      todayForegroundColor: WidgetStatePropertyAll(c.label),
      todayBorder: BorderSide(color: c.labelTertiary),
      dayForegroundColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return c.labelTertiary.withValues(alpha: 0.55); // e.g. future days
        return s.contains(WidgetState.selected) ? c.onAccent : c.label;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.accent : null),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.elevated,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: textTheme.bodyMedium,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent, linearTrackColor: c.hairline),
  );
}

final ThemeData darkTheme = buildTheme(Brightness.dark);
final ThemeData lightTheme = buildTheme(Brightness.light);
