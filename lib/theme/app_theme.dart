import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;

class AppTheme {
  // Light theme colors
  static const Color primaryColor = Color(0xFF2E86C1); // Blue
  static const Color secondaryColor = Color(0xFF28B463); // Green
  static const Color accentColor = Color(0xFFE67E22); // Orange
  static const Color errorColor = Color(0xFFE74C3C); // Red
  static const Color warningColor = Color(0xFFF39C12); // Yellow
  static const Color successColor = Color(0xFF27AE60); // Success Green

  static const double summaryBoxSized = 60;

  //headersOperations
  static const double operationsHeaderItemWidthNormal = 90;
  static const TextStyle headerStyle =
      TextStyle(fontWeight: FontWeight.w900, fontSize: 11.8);

  static const TextStyle headerStyleBig =
      TextStyle(fontWeight: FontWeight.w800, fontSize: 16);

  static const TextStyle valueStyleBig =
      TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: primaryColor);
  // Background colors
  static const Color backgroundColor =
      Color(0xFFFAFAFA); // Light gray background
  static const Color cardColor = Color(0xFFFFFFFF); // White cards
  static const Color surfaceColor = Color(0xFFF5F5F5); // Light surface

  // Text colors
  static const Color primaryTextColor = Color(0xFF2C3E50); // Dark blue-gray
  static const Color secondaryTextColor = Color(0xFF7F8C8D); // Medium gray
  static const Color lightTextColor = Color(0xFFBDC3C7); // Light gray

  // Border and divider colors
  static const Color borderColor = Color(0xFFE5E5E5); // Light border
  static const Color dividerColor = Color(0xFFECF0F1); // Very light gray

  // Status colors for weighing operations
  static const Color loadingOperationColor =
      Color(0xFF3498DB); // Blue for loading
  static const Color unloadingOperationColor =
      Color(0xFF2ECC71); // Green for unloading
  static const Color stableWeightColor = Color(0xFF27AE60); // Green for stable
  static const Color unstableWeightColor =
      Color(0xFFF39C12); // Orange for unstable

  static FluentThemeData get lightTheme {
    return FluentThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,

      // Define accent colors
      accentColor: AccentColor.swatch({
        'darkest': primaryColor.withOpacity(0.9),
        'darker': primaryColor.withOpacity(0.8),
        'dark': primaryColor.withOpacity(0.7),
        'normal': primaryColor,
        'light': primaryColor.withOpacity(0.6),
        'lighter': primaryColor.withOpacity(0.4),
        'lightest': primaryColor.withOpacity(0.2),
      }),

      // Typography - simplified for FluentUI compatibility
      typography: Typography.fromBrightness(
        brightness: Brightness.light,
        color: primaryTextColor,
      ),

      // Navigation theme
      navigationPaneTheme: NavigationPaneThemeData(
        backgroundColor: cardColor,
        overlayBackgroundColor: cardColor.withOpacity(0.95),
        highlightColor: primaryColor.withOpacity(0.1),
      ),
    );
  }

  // Utility methods
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'active':
        return successColor;
      case 'pending':
      case 'warning':
      case 'unstable':
        return warningColor;
      case 'error':
      case 'failed':
      case 'cancelled':
        return errorColor;
      case 'loading':
        return loadingOperationColor;
      case 'unloading':
        return unloadingOperationColor;
      default:
        return secondaryTextColor;
    }
  }

  static Color getOperationColor(String operationType) {
    switch (operationType.toLowerCase()) {
      case 'loading':
        return loadingOperationColor;
      case 'unloading':
        return unloadingOperationColor;
      default:
        return primaryColor;
    }
  }
}

class WeighingTheme {
  // Weight display styles
  static TextStyle get stableWeightStyle => const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: AppTheme.stableWeightColor,
      );

  static TextStyle get unstableWeightStyle => const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: AppTheme.unstableWeightColor,
      );

  static TextStyle get weightUnitStyle => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppTheme.secondaryTextColor,
      );

  // Operation type styles
  static BoxDecoration get loadingOperationDecoration => BoxDecoration(
        color: AppTheme.loadingOperationColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AppTheme.loadingOperationColor.withOpacity(0.3)),
      );

  static BoxDecoration get unloadingOperationDecoration => BoxDecoration(
        color: AppTheme.unloadingOperationColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppTheme.unloadingOperationColor.withOpacity(0.3)),
      );

  static TextStyle get operationTypeStyle => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryTextColor,
      );

  // Status indicators
  static BoxDecoration get successIndicator => BoxDecoration(
        color: AppTheme.successColor,
        borderRadius: BorderRadius.circular(12),
      );

  static BoxDecoration get warningIndicator => BoxDecoration(
        color: AppTheme.warningColor,
        borderRadius: BorderRadius.circular(12),
      );

  static BoxDecoration get errorIndicator => BoxDecoration(
        color: AppTheme.errorColor,
        borderRadius: BorderRadius.circular(12),
      );

  // Card shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // Tab styles
  static BoxDecoration get activeTabDecoration => BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.primaryColor),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      );

  static BoxDecoration get inactiveTabDecoration => BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      );

  // Form field styles for Material forms (when needed)
  static material.InputDecoration getFormFieldDecoration(String label,
      {IconData? icon}) {
    return material.InputDecoration(
      labelText: label,
      prefixIcon:
          icon != null ? Icon(icon, color: AppTheme.secondaryTextColor) : null,
      border: material.OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      focusedBorder: material.OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      enabledBorder: material.OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      filled: true,
      fillColor: AppTheme.cardColor,
      labelStyle: const TextStyle(color: AppTheme.secondaryTextColor),
    );
  }
}
