import 'package:flutter/material.dart';

/// Centralized color constants used across the app.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color accent = Color(0xFFBB86FC);

  // Game-specific colors
  static const Color correct = Color(0xFF4CAF50);
  static const Color wrong = Color(0xFFEF5350);
  static const Color timerWarning = Color(0xFFFF9800);
  static const Color timerDanger = Color(0xFFEF5350);

  // Surface colors
  static const Color darkBg = Color(0xFF0D0D1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF252540);
  static const Color darkBorder = Color(0xFF3A3A5C);

  // Level difficulty
  static const Color easyLevel = Color(0xFF4CAF50);
  static const Color mediumLevel = Color(0xFFFF9800);
  static const Color hardLevel = Color(0xFFEF5350);
}
