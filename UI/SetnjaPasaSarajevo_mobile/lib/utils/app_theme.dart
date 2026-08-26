import 'package:flutter/material.dart';

/// Production-ready app theme constants
class AppTheme {
  // Primary Colors
  static const Color primaryGreen = Color(0xFF4E8D63);
  static const Color primaryGreenLight = Color(0xFFA8D5BA);
  static const Color primaryGreenDark = Color(0xFF2D5A3D);

  // Status Colors (with better contrast)
  static const Color statusConfirmed = Color(0xFF10B981); // Better green
  static const Color statusPending = Color(0xFFF59E0B); // Better orange
  static const Color statusCancelled = Color(0xFFEF4444); // Better red
  static const Color statusCompleted = Color(0xFF3B82F6); // Better blue

  // Background & Surface
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceWhite = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color borderLight = Color(0xFFE5E7EB);

  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing14 = 14.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;

  // Shadows
  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMedium = [
  BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 18,
    offset: const Offset(0, 8),
  ),
];


  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  /// Get status color based on status string
  static Color getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return statusConfirmed;
      case 'cancelled':
      case 'rejected':
        return statusCancelled;
      case 'completed':
        return statusCompleted;
      case 'pending':
      default:
        return statusPending;
    }
  }

  /// Get status display name
  static String getStatusDisplay(String? status) {
    return status ?? 'Pending';
  }
}
