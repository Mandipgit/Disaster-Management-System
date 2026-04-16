import 'package:flutter/material.dart';

/// Disaster360 Color Palette
/// All colors used throughout the app are defined here for consistency and easy theming
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ─────────────────────────────────────────────────────────────────────────
  // BACKGROUNDS
  // ─────────────────────────────────────────────────────────────────────────
  static const Color bgPrimary = Color(0xFF0D1117); // Main app background
  static const Color bgSurface = Color(0xFF141B27); // Card/container background
  static const Color bgDark = Color(0xFF1A2030); // Alternative dark background
  static const Color border = Color(0xFF1E2A3A); // Border/divider color

  // ─────────────────────────────────────────────────────────────────────────
  // BRAND & PRIMARY ACTION
  // ─────────────────────────────────────────────────────────────────────────
  static const Color orange = Color(
    0xFFFF6B2B,
  ); // Primary orange, active states
  static const Color orangeLight = Color(0xFFFF6B2B); // Orange with opacity

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS & SEMANTIC COLORS
  // ─────────────────────────────────────────────────────────────────────────
  /// Danger/Error status - high risk, cyclone/hurricane alerts
  static const Color danger = Color(0xFFFF3B3B);
  static const Color dangerLight = Color(0xFFFF3B3B);

  /// Warning/Caution status - medium risk, flood alerts, offline state
  static const Color warning = Color(0xFFFFB800);
  static const Color warningLight = Color(0xFFFFB800);

  /// Success/Safe status - resolved, tsunami/landslide controlled
  static const Color success = Color(0xFF00D4AA);
  static const Color successLight = Color(0xFF00D4AA);
  static const Color successGreen = Color(0xFF4CAF50); // Alternative green

  /// Info/Informational status - earthquake alerts, notifications
  static const Color info = Color(0xFF4D9EFF);
  static const Color infoLight = Color(0xFF4D9EFF);

  // ─────────────────────────────────────────────────────────────────────────
  // TEXT COLORS (add as needed)
  // ─────────────────────────────────────────────────────────────────────────
  static const Color textLight = Colors.white;
  static const Color textMuted = Colors.white38;
}
