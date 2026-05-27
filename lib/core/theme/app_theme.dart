import 'package:flutter/material.dart';

class AppTheme {
  // Paletas principales
  static const Color vwBlue = Color(0xFF003087);        // Azul Corporativo VW
  static const Color warmYellow = Color(0xFFFFC72C);    // Amarillo cálido brillante
  static const Color creamVintage = Color(0xFFF5E1A4);  // Crema vintage / Amarillo suave
  static const Color detailRed = Color(0xFFC8102E);     // Rojo de detalles/acentos
  
  // Fondo de dueña (blanco fresco elegante)
  static const Color ownerBg = Color(0xFFF8FAFC);
  // Fondo de cliente (crema cálido vintage agradable)
  static const Color clientBg = Color(0xFFFCFBF8);

  // Tema Base con especificaciones comunes refinadas
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color scaffoldBg,
    required Color cardColor,
    required Color appBarColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: cardColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        tertiary: detailRed,
        surface: cardColor,
        brightness: brightness,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: brightness == Brightness.dark ? Colors.white : primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: brightness == Brightness.dark ? Colors.white : primary,
          fontSize: 19,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: primary),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0.5,
        shadowColor: primary.withValues(alpha: 0.08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: primary.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.12), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.1), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: detailRed, width: 1.2),
        ),
        labelStyle: TextStyle(color: primary.withValues(alpha: 0.6), fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 1,
          shadowColor: primary.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: secondary.withValues(alpha: 0.2),
        elevation: 8,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 24);
          }
          return IconThemeData(color: Colors.grey.shade500, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? primary : Colors.grey.shade600,
          );
        }),
      ),
    );
  }

  // Tema clásico/default
  static final light = _buildTheme(
    brightness: Brightness.light,
    primary: vwBlue,
    secondary: warmYellow,
    scaffoldBg: Colors.white,
    cardColor: Colors.white,
    appBarColor: Colors.white,
  );

  // Tema personalizado para la Dueña (Azul + Blanco limpio + Amarillo cálido vivo)
  static final ownerTheme = _buildTheme(
    brightness: Brightness.light,
    primary: vwBlue,
    secondary: warmYellow,
    scaffoldBg: ownerBg,
    cardColor: Colors.white,
    appBarColor: Colors.white,
  );

  // Tema personalizado para Clientes (Azul + Crema Vintage cálida + Blanco suave)
  static final clientTheme = _buildTheme(
    brightness: Brightness.light,
    primary: vwBlue,
    secondary: creamVintage,
    scaffoldBg: clientBg,
    cardColor: Colors.white,
    appBarColor: clientBg,
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: vwBlue,
      brightness: Brightness.dark,
    ),
  );
}