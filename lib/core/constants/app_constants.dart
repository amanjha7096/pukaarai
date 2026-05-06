import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppConstants {
  static const String appName = 'VitalTrack';
}

class AppColors {
  // ── Accent colors — constant in both themes ───────────────────────────────
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5C55E8);
  static const Color primaryLight = Color(0xFF7B74FF);
  static const Color waterBlue = Color(0xFF5BC8F5);
  static const Color calorieOrange = Color(0xFFFF6B35);
  static const Color heartPink = Color(0xFFFF6B8A);
  static const Color sleepIndigo = Color(0xFFA78BFA);
  static const Color accentDot = Color(0xFFFF4757);

  // ── Dark-mode palette ─────────────────────────────────────────────────────
  static const Color _bgDark = Color(0xFF0E0E1A);
  static const Color _cardDark = Color(0xFF1C1C2E);
  static const Color _textPrimaryDark = Color(0xFFE8E8F8);
  static const Color _textSecondaryDark = Color(0xFF8080A0);

  // ── Theme-sensitive — read by build() after GetMaterialApp is live ────────
  static Color get background =>
      Get.isDarkMode ? _bgDark : const Color(0xFFF8F9FE);
  static Color get cardWhite =>
      Get.isDarkMode ? _cardDark : Colors.white;
  static Color get textPrimary =>
      Get.isDarkMode ? _textPrimaryDark : const Color(0xFF1A1A2E);
  static Color get textSecondary =>
      Get.isDarkMode ? _textSecondaryDark : const Color(0xFF9E9EC0);

  // ── Derived semantic colors ───────────────────────────────────────────────
  static Color get errorSurface =>
      Get.isDarkMode ? const Color(0xFF3A1010) : const Color(0xFFFFF0F0);
  static Color get deleteSurface =>
      Get.isDarkMode ? const Color(0xFF3A1010) : const Color(0xFFFFEEEE);
  static Color get dividerColor =>
      Get.isDarkMode ? const Color(0xFF2A2A40) : const Color(0xFFF0F0F8);
}

class AppGoals {
  static const double steps = 10000;
  static const double water = 3000;
  static const double calories = 2000;
  static const double sleep = 8;
}
