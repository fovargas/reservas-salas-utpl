import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color azulUtpl = Color(0xFF003B71);
  static const Color amarilloUtpl = Color(0xFFF2A900);
  static const Color fondo = Color(0xFFF5F7FA);

  static ThemeData claro() => _tema(Brightness.light);
  static ThemeData oscuro() => _tema(Brightness.dark);

  static ThemeData _tema(Brightness brillo) {
    final esquema = ColorScheme.fromSeed(
      seedColor: azulUtpl,
      primary: brillo == Brightness.light ? azulUtpl : null,
      secondary: amarilloUtpl,
      brightness: brillo,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: brillo == Brightness.light ? fondo : null,
      appBarTheme: const AppBarTheme(
        backgroundColor: azulUtpl,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        margin: const EdgeInsets.symmetric(
          horizontal: Espacio.lg,
          vertical: Espacio.xs,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    );
  }
}

class Espacio {
  Espacio._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}
