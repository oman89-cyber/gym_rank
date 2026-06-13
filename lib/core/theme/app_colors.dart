import 'package:flutter/material.dart';

class AppColors {
  // ── Base ──────────────────────────────────────────────────────────────────
  static const Color background    = Color(0xFF000000); // pure black
  static const Color surface       = Color(0xFF000000); // pure black
  static const Color card          = Color(0xFF060B14); // very deep navy for main cards
  static const Color cardElevated  = Color(0xFF0A1325); // slightly lighter navy
  static const Color cardButton    = Color(0xFF0D1B36); // distinct navy tone for actionable cards

  // ── Blue Accent ───────────────────────────────────────────────────────────
  static const Color blue          = Color(0xFF2563EB);
  static const Color blueDark      = Color(0xFF1A3FAA);
  static const Color blueLight     = Color(0xFF60A5FA);
  static const Color blueMuted     = Color(0xFF1A2D55);
  static const Color blueGlow      = Color(0xFF1D4ED8);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFECF0FF);
  static const Color textSecondary = Color(0xFF8898B8);
  static const Color textMuted     = Color(0xFF4A5674);

  // ── UI ────────────────────────────────────────────────────────────────────
  static const Color border        = Color(0xFF1A2540);
  static const Color gold          = Color(0xFFF59E0B);
  static const Color goldLight     = Color(0xFFFCD34D);
  static const Color orange        = Color(0xFFEA580C);
  static const Color green         = Color(0xFF10B981);
  static const Color red           = Color(0xFFEF4444);

  // ── Rank Colors ───────────────────────────────────────────────────────────
  static Color getRankColor(String rank) {
    final r = rank.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    switch (r) {
      case 'SS': return const Color(0xFFE11D48);
      case 'S':  return const Color(0xFFF59E0B);
      case 'A':  return const Color(0xFF10B981);
      case 'B':  return const Color(0xFF3B82F6);
      case 'C':  return const Color(0xFF8B5CF6);
      case 'D':  return const Color(0xFF6B7280);
      default:   return const Color(0xFF4B5563); // E, F
    }
  }
}
