class BillingRecord {
  final int? id;
  final String customerId;
  final String billingPeriod; // YYYYMM format
  final double offPeakStand; // SAHLWBP
  final double peakStand; // SAHWBP
  final double offPeakConsumption; // KWHLWBP
  final double peakConsumption; // KWHWBP
  final double operatingHours; // JAMNYALA
  final double rptag;
  final double? kvarhConsumption; // KVARH consumption (reactive power)
  final String? prevOffPeakStand; // SLALWBP
  final String? prevPeakStand; // SLAWBP
  final DateTime createdAt;
  final DateTime updatedAt;

  BillingRecord({
    this.id,
    required this.customerId,
    required this.billingPeriod,
    required this.offPeakStand,
    required this.peakStand,
    required this.offPeakConsumption,
    required this.peakConsumption,
    required this.operatingHours,
    required this.rptag,
    this.kvarhConsumption,
    this.prevOffPeakStand,
    this.prevPeakStand,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'billing_period': billingPeriod,
      'off_peak_stand': offPeakStand,
      'peak_stand': peakStand,
      'off_peak_consumption': offPeakConsumption,
      'peak_consumption': peakConsumption,
      'operating_hours': operatingHours,
      'rptag': rptag,
      'kvarh_consumption': kvarhConsumption,
      'prev_off_peak_stand': prevOffPeakStand,
      'prev_peak_stand': prevPeakStand,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BillingRecord.fromMap(Map<String, dynamic> map) {
    return BillingRecord(
      id: map['id'] as int?,
      customerId: map['customer_id'] as String,
      billingPeriod: map['billing_period'] as String,
      offPeakStand: (map['off_peak_stand'] as num).toDouble(),
      peakStand: (map['peak_stand'] as num).toDouble(),
      offPeakConsumption: (map['off_peak_consumption'] as num).toDouble(),
      peakConsumption: (map['peak_consumption'] as num).toDouble(),
      operatingHours: (map['operating_hours'] as num).toDouble(),
      rptag: (map['rptag'] as num).toDouble(),
      kvarhConsumption: (map['kvarh_consumption'] as num?)?.toDouble(),
      prevOffPeakStand: map['prev_off_peak_stand'] as String?,
      prevPeakStand: map['prev_peak_stand'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  double get totalConsumption => offPeakConsumption + peakConsumption;
}
