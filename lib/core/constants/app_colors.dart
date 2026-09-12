import 'package:flutter/material.dart';

/// Paleta oficial de ControlaTodo.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color backgroundLight = Color(0xFFF8FAFC);

  static const Color success = secondary;
  static const Color overdue = error;
  static const Color dueSoon = warning;
  static const Color dueLater = secondary;

  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  static const Color divider = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF334155);
}
