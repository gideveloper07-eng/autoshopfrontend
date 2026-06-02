import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1F6AE2);
  static const Color secondary = Color(0xFF4DB7FF);
  static const Color secondaryLight = Color(0xFF8ED2FF);
  static const Color background = Color(0xFFF5F9FF);
  static const Color textPrimary = Color(0xFF10253F);
  static const Color textSecondary = Color(0xFF6A7B8F);
  static const Color shadowPrimary = Color(0x220D3C74);

  static const LinearGradient vibrantGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1F6AE2), Color(0xFF4DB7FF)],
  );
}
