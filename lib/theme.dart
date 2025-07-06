import 'package:flutter/material.dart';

final ColorScheme colorScheme = ColorScheme.dark(
  primary: const Color(0xFFED3D7D),
  onPrimary: Colors.black,
  secondary: Colors.white,
  onSecondary: Colors.black,
  surface: const Color(0xFF1A1A1A),
  onSurface: Colors.white,
  error: Colors.redAccent,
  onError: Colors.black,
  tertiary: Colors.pinkAccent, // required for ColorScheme
  onTertiary: Colors.black, // required for ColorScheme
  outline: Colors.grey, // required for ColorScheme
  shadow: Colors.black, // required for ColorScheme
  inverseSurface: Colors.white, // can be used for contrast backgrounds
  inversePrimary: Colors.white, // can be used for contrast primary
);

final textTheme = TextTheme(
  bodyLarge: TextStyle(fontSize: 16, color: colorScheme.onSurface),
  bodyMedium: TextStyle(fontSize: 14, color: colorScheme.onSurface),
  bodySmall: TextStyle(fontSize: 12, color: colorScheme.onSurface),
);

final appBarTheme = AppBarTheme(
  backgroundColor: colorScheme.primary,
  foregroundColor: colorScheme.onPrimary,
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
