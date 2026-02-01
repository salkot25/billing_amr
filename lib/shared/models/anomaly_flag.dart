enum AnomalyType {
  standMundur, // Stand meter menurun
  excessiveHours, // Jam nyala > 720
  consumptionSpike, // Konsumsi meningkat >30%
  consumptionDecrease, // Konsumsi menurun >30%
  zeroConsumption, // Konsumsi nol
}

enum AnomalySeverity {
  critical, // Stand mundur, negative values
  medium, // Spikes, excessive hours
  low, // Minor issues
}

class AnomalyFlag {
  final int? id;
  final int billingRecordId;
  final AnomalyType type;
  final AnomalySeverity severity;
  final String description;
  final bool reviewed;
  final DateTime flaggedAt;

  AnomalyFlag({
    this.id,
    required this.billingRecordId,
    required this.type,
    required this.severity,
    required this.description,
    this.reviewed = false,
    required this.flaggedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billing_record_id': billingRecordId,
      'type': type.name,
      'severity': severity.name,
      'description': description,
      'reviewed': reviewed ? 1 : 0,
      'flagged_at': flaggedAt.toIso8601String(),
    };
  }

  factory AnomalyFlag.fromMap(Map<String, dynamic> map) {
    return AnomalyFlag(
      id: map['id'] as int?,
      billingRecordId: map['billing_record_id'] as int,
      type: AnomalyType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AnomalyType.standMundur,
      ),
      severity: AnomalySeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => AnomalySeverity.medium,
      ),
      description: map['description'] as String,
      reviewed: (map['reviewed'] as int) == 1,
      flaggedAt: DateTime.parse(map['flagged_at'] as String),
    );
  }
}
