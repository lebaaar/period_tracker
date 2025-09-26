import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// icon color: FF91C5
final ColorScheme colorScheme = ColorScheme.dark(
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

final textTheme = TextTheme(
  bodyLarge: GoogleFonts.lexend(
    fontSize: 16,
    color: colorScheme.onSurface,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  ),
  bodyMedium: GoogleFonts.lexend(
    fontSize: 14,
    color: colorScheme.onSurface,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  ),
  bodySmall: GoogleFonts.lexend(
    fontSize: 12,
    color: colorScheme.onSurface,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  ),
  titleLarge: GoogleFonts.lexend(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: colorScheme.onSurface,
    letterSpacing: 0,
  ),
  titleMedium: GoogleFonts.lexend(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: colorScheme.onSurface,
    letterSpacing: 0,
  ),
  titleSmall: GoogleFonts.lexend(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: colorScheme.onSurface,
    letterSpacing: 0,
  ),
  labelLarge: GoogleFonts.lexend(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: colorScheme.onSurface,
    letterSpacing: 0,
  ),
  labelMedium: GoogleFonts.lexend(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: colorScheme.onSurface,
    letterSpacing: 0,
  ),
  labelSmall: GoogleFonts.lexend(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: colorScheme.onSurface,
    letterSpacing: 0,
  ),
  headlineLarge: GoogleFonts.lexend(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: colorScheme.onSurface,
    letterSpacing: 0,
  ),
  headlineMedium: GoogleFonts.lexend(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: colorScheme.onSurface,
    letterSpacing: 0,
  ),
  headlineSmall: GoogleFonts.lexend(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: colorScheme.onSurface,
    letterSpacing: 0,
  ),
);

final appBarTheme = AppBarTheme(
  backgroundColor: colorScheme.primary,
  foregroundColor: colorScheme.onPrimary,
  scrolledUnderElevation: 0,
  titleTextStyle: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: colorScheme.onPrimary,
  ),
);

final ThemeData appTheme = ThemeData(
  colorScheme: colorScheme,
  textTheme: textTheme,
  appBarTheme: appBarTheme,
  scaffoldBackgroundColor: colorScheme.surface,
);
