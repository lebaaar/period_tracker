import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// icon color: FF91C5
const ColorScheme darkColorScheme = ColorScheme.dark(
  brightness: Brightness.dark,

  primary: Color(0xFFFF91C5), // #ff91c5
  onPrimary: Colors.black,
  primaryContainer: Color(0xFF121212),
  onPrimaryContainer: Colors.white,

  // TBD - when creating calendar highlighting...
  secondary: Color.fromARGB(255, 66, 66, 66),
  onSecondary: Color(0xFF231532),
  secondaryContainer: Color(0xFF3A2C4A),
  onSecondaryContainer: Color(0xFFE5DFF2),

  // TBD - ?
  tertiary: Color.fromARGB(255, 198, 198, 198),
  onTertiary: Color(0xFF39182A),
  tertiaryContainer: Color.fromARGB(255, 124, 123, 123),
  onTertiaryContainer: Color(0xFFFFD9E7),

  // TBD - when displaying errors
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),

  surface: Colors.black,
  onSurface: Colors.white,
  surfaceContainerHighest: Color(0xFF121212),
  onSurfaceVariant: Color(0xFFCAC4D0),

  outline: Color(0xFF938F99),
  outlineVariant: Color(0xFF49454F),

  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),

  inverseSurface: Color(0xFFE6E1E5),
  onInverseSurface: Color(0xFF313033),
  inversePrimary: Color(0xFF98406F),
);

const ColorScheme lightColorScheme = ColorScheme.light(
  brightness: Brightness.light,

  primary: Color(0xFFFF91C5),
  onPrimary: Colors.black,
  primaryContainer: Color(0xFFF5F5F5),
  onPrimaryContainer: Colors.black,

  secondary: Color(0xFFE0E0E0),
  onSecondary: Color(0xFF231532),
  secondaryContainer: Color(0xFFEADDF7),
  onSecondaryContainer: Color(0xFF231532),

  tertiary: Color(0xFF6B6B6B),
  onTertiary: Colors.white,
  tertiaryContainer: Color(0xFFD0D0D0),
  onTertiaryContainer: Color(0xFF39182A),

  error: Color(0xFFBA1A1A),
  onError: Colors.white,
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF410002),

  surface: Colors.white,
  onSurface: Colors.black,
  surfaceContainerHighest: Color(0xFFF5F5F5),
  onSurfaceVariant: Color(0xFF49454F),

  outline: Color(0xFF79747E),
  outlineVariant: Color(0xFFCAC4D0),

  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),

  inverseSurface: Color(0xFF313033),
  onInverseSurface: Color(0xFFF4EFF4),
  inversePrimary: Color(0xFFFF91C5),
);

TextStyle _lexend(ColorScheme cs, double size, FontWeight weight) =>
    GoogleFonts.lexend(fontSize: size, color: cs.onSurface, fontWeight: weight, letterSpacing: 0);

ThemeData buildTheme(ColorScheme cs) {
  return ThemeData(
    colorScheme: cs,
    textTheme: TextTheme(
      bodyLarge: _lexend(cs, 16, FontWeight.w400),
      bodyMedium: _lexend(cs, 14, FontWeight.w400),
      bodySmall: _lexend(cs, 12, FontWeight.w400),
      titleLarge: _lexend(cs, 20, FontWeight.bold),
      titleMedium: _lexend(cs, 18, FontWeight.w600),
      titleSmall: _lexend(cs, 16, FontWeight.w500),
      labelLarge: _lexend(cs, 14, FontWeight.w500),
      labelMedium: _lexend(cs, 12, FontWeight.w400),
      labelSmall: _lexend(cs, 10, FontWeight.w400),
      headlineLarge: _lexend(cs, 32, FontWeight.bold),
      headlineMedium: _lexend(cs, 28, FontWeight.bold),
      headlineSmall: _lexend(cs, 24, FontWeight.bold),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onPrimary),
    ),
    scaffoldBackgroundColor: cs.surface,
  );
}

final ThemeData darkTheme = buildTheme(darkColorScheme);
final ThemeData lightTheme = buildTheme(lightColorScheme);
