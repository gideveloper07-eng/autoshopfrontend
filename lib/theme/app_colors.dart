import 'package:flutter/material.dart';

class AppColors {
  // Brand colours (same in both themes)
  static const Color primary = Color(0xFF1F6AE2);
  static const Color secondary = Color(0xFF4DB7FF);
  static const Color secondaryLight = Color(0xFF8ED2FF);

  // Light theme
  static const Color background = Color(0xFFF5F9FF);
  static const Color backgroundDark = Color(0xFF0F1923);

  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF1A2535);

  static const Color textPrimary = Color(0xFF10253F);
  static const Color textPrimaryDark = Color(0xFFE8EDF5);

  static const Color textSecondary = Color(0xFF6A7B8F);
  static const Color textSecondaryDark = Color(0xFF8A9BB0);

  static const Color shadowPrimary = Color(0x220D3C74);

  static const LinearGradient vibrantGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F6AE2), Color(0xFF4DB7FF)],
  );

  static const LinearGradient vibrantGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A2A5C), Color(0xFF1A4A8C)],
  );

  static LinearGradient vibrantGradientAdaptive(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? vibrantGradientDark
        : vibrantGradient;
  }

  /// Returns the appropriate colour based on current brightness.
  static Color adaptive(BuildContext context, Color light, Color dark) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  static Color bg(BuildContext context) =>
      adaptive(context, background, backgroundDark);

  static Color card(BuildContext context) =>
      adaptive(context, surface, surfaceDark);

  static Color textHigh(BuildContext context) =>
      adaptive(context, textPrimary, textPrimaryDark);

  static Color textMed(BuildContext context) =>
      adaptive(context, textSecondary, textSecondaryDark);

  static Color divider(BuildContext context) =>
      adaptive(context, const Color(0xFFE0E0E0), const Color(0xFF2A3A4A));
}
