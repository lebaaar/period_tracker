import 'package:flutter/material.dart';

// icon color: FF91C5
final ColorScheme colorScheme = ColorScheme.dark(
  brightness: Brightness.dark,

  primary: Color(0xFFFF91C5),
  onPrimary: Colors.black,
  primaryContainer: Color(0xFF121212),
  onPrimaryContainer: Colors.white,

  // TBD - when creating calendar highlighting...
  secondary: Color.fromARGB(255, 89, 89, 89),
  onSecondary: Color(0xFF231532),
  secondaryContainer: Color(0xFF3A2C4A),
  onSecondaryContainer: Color(0xFFE5DFF2),

  // TBD - ?
  tertiary: Color(0xFFE5B7D0),
  onTertiary: Color(0xFF39182A),
  tertiaryContainer: Color(0xFF542E41),
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

final ColorScheme old = ColorScheme.dark(
  primary: const Color.fromRGBO(255, 145, 197, 1),
  onPrimary: Colors.black,
  secondary: Colors.white,
  onSecondary: Colors.black,
  surface: Colors.black,
  onSurface: Colors.white,
  error: Colors.redAccent,
  onError: Colors.black,
  tertiary: Colors.pinkAccent, // required for ColorScheme
  onTertiary: Colors.black, // required for ColorScheme
  outline: Colors.grey, // required for ColorScheme
  shadow: Colors.black, // required for ColorScheme
  inverseSurface: Colors.white,
  inversePrimary: Colors.white,
);

final textTheme = TextTheme(
  bodyLarge: TextStyle(fontSize: 16, color: colorScheme.onSurface),
  bodyMedium: TextStyle(fontSize: 14, color: colorScheme.onSurface),
  bodySmall: TextStyle(fontSize: 12, color: colorScheme.onSurface),
  titleLarge: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: colorScheme.onSurface,
  ),
  titleMedium: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: colorScheme.primary,
  ),
  titleSmall: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: colorScheme.onSurface,
  ),
  labelLarge: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: colorScheme.onSurface,
  ),
  labelMedium: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: colorScheme.primary,
  ),
  labelSmall: TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: colorScheme.onSurface,
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
