import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // 2026 Modern Luxury Hotel Palette
  static const Color primary = Color(0xFF0F766E); // Deep Emerald Teal
  static const Color primaryLight = Color(0xFF14B8A6); // Vibrant Mint Teal
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primarySurface = Color(0xFFF0FDFA);

  // Modern Accent & Brand Colors
  static const Color accentIndigo = Color(0xFF6366F1); // Modern Indigo
  static const Color accentIndigoLight = Color(0xFFEEF2FF);
  static const Color accentCyan = Color(0xFF0284C7); // Cerulean
  static const Color accentGold = Color(0xFFD97706); // Luxury Amber Gold
  static const Color accentGoldBg = Color(0xFFFEF3C7);

  // 2026 Status Colors
  static const Color statusAvailable = Color(0xFF10B981); // Emerald Green
  static const Color statusAvailableBg = Color(0xFFECFDF5);
  static const Color statusAvailableBorder = Color(0xFFA7F3D0);

  static const Color statusOccupied = Color(0xFF0284C7); // Ocean Blue
  static const Color statusOccupiedBg = Color(0xFFF0F9FF);
  static const Color statusOccupiedBorder = Color(0xFFBAE6FD);

  static const Color statusCleaning = Color(0xFFF59E0B); // Warm Amber
  static const Color statusCleaningBg = Color(0xFFFFFBEB);
  static const Color statusCleaningBorder = Color(0xFFFDE68A);

  static const Color statusMaintenance = Color(0xFFEF4444); // Crimson Red
  static const Color statusMaintenanceBg = Color(0xFFFEF2F2);
  static const Color statusMaintenanceBorder = Color(0xFFFECACA);

  static const Color statusDeparted = Color(0xFF64748B); // Slate Gray
  static const Color statusDepartedBg = Color(0xFFF8FAFC);
  static const Color statusDepartedBorder = Color(0xFFE2E8F0);

  static const Color statusGuests = Color(0xFF8B5CF6); // Modern Purple
  static const Color statusGuestsBg = Color(0xFFF5F3FF);
  static const Color statusGuestsBorder = Color(0xFFDDD6FE);

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC); // Clean Slate-50 background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);

  // Typography Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate-900
  static const Color textSecondary = Color(0xFF64748B); // Slate-500
  static const Color textMuted = Color(0xFF94A3B8); // Slate-400
  static const Color textWhite = Color(0xFFFFFFFF);

  // Compatibility Aliases for Green/Red/Blue
  static const Color accentGreen = statusAvailable;
  static const Color accentGreenLight = statusAvailableBg;
  static const Color accentGreenBorder = statusAvailableBorder;
  static const Color accentRed = statusMaintenance;
  static const Color accentBlue = statusOccupied;
  static const Color accentOrange = statusCleaning;
  static const Color accentPurple = statusGuests;

  // 2026 Neutral Palette
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  static const Color borderSubtle = Color(0xFFE2E8F0);

  // Semantic Status Tokens
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusSuccessSurface = Color(0xFFECFDF5);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusWarningSurface = Color(0xFFFFFBEB);
  static const Color statusError = Color(0xFFEF4444);
  static const Color statusErrorSurface = Color(0xFFFEF2F2);
  static const Color error = Color(0xFFEF4444);

  // Card & Elevation Shadows
  static const Color cardShadow = Color(0x0A0F172A);
  static const Color cardShadowElevated = Color(0x140F172A);
  static const Color cardBorder = Color(0xFFE2E8F0);
}
