import 'package:flutter/material.dart';
import '../models/anomaly_flag.dart';

/// Utility class for anomaly display formatting
class AnomalyUtils {
  /// Get display name for anomaly type in Indonesian
  static String getTypeName(AnomalyType type) {
    switch (type) {
      case AnomalyType.standMundur:
        return 'Stand Mundur';
      case AnomalyType.excessiveHours:
        return 'Jam Nyala Berlebih';
      case AnomalyType.consumptionSpike:
        return 'Lonjakan Konsumsi';
      case AnomalyType.consumptionDecrease:
        return 'Penurunan Pemakaian';
      case AnomalyType.zeroConsumption:
        return 'Konsumsi Nol';
    }
  }

  /// Get display name for anomaly severity in Indonesian
  static String getSeverityName(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.critical:
        return 'KRITIS';
      case AnomalySeverity.medium:
        return 'SEDANG';
      case AnomalySeverity.low:
        return 'RENDAH';
    }
  }

  /// Get color for severity level
  static Color getSeverityColor(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.critical:
        return const Color(0xFFD32F2F); // Red
      case AnomalySeverity.medium:
        return const Color(0xFFF57C00); // Orange
      case AnomalySeverity.low:
        return const Color(0xFFFBC02D); // Yellow
    }
  }

  /// Get icon for anomaly type
  static IconData getTypeIcon(AnomalyType type) {
    switch (type) {
      case AnomalyType.standMundur:
        return Icons.arrow_back;
      case AnomalyType.excessiveHours:
        return Icons.schedule;
      case AnomalyType.consumptionSpike:
        return Icons.trending_up;
      case AnomalyType.consumptionDecrease:
        return Icons.trending_down;
      case AnomalyType.zeroConsumption:
        return Icons.power_off;
    }
  }

  /// Get display label for enum values (for filter chips)
  static String getDisplayLabel(String value) {
    // Check if it's a type
    try {
      final type = AnomalyType.values.firstWhere((e) => e.name == value);
      return getTypeName(type);
    } catch (e) {
      // Continue
    }

    // Check if it's a severity
    try {
      final severity = AnomalySeverity.values.firstWhere(
        (e) => e.name == value,
      );
      return getSeverityName(severity);
    } catch (e) {
      // Continue
    }

    return value;
  }
}
