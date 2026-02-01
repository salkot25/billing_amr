import '../../shared/models/anomaly_flag.dart';
import '../../shared/models/billing_record.dart';
import '../../core/database/database_helper.dart';

class AnomalyDetectionService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Run anomaly detection after import
  Future<int> detectAnomalies() async {
    int anomalyCount = 0;

    // Get latest billing period
    final latestPeriod = await _db.getLatestBillingPeriod();
    if (latestPeriod == null) return 0;

    // Get operating hours threshold from settings
    final operatingHoursThreshold = await _db.getOperatingHoursThreshold();

    // Get all billing records for the latest period
    final db = await _db.database;
    final records = await db.query(
      'billing_records',
      where: 'billing_period = ?',
      whereArgs: [latestPeriod],
    );

    for (final recordMap in records) {
      final record = BillingRecord.fromMap(recordMap);

      // Check if customer is active
      final isActive = await _db.isCustomerActive(record.customerId);
      if (!isActive) continue; // Skip inactive customers

      // Delete existing anomaly flags for this record
      await _db.deleteAnomalyFlags(record.id!);

      // Check for anomalies
      final anomalies = await _checkRecordAnomalies(
        record,
        operatingHoursThreshold,
      );
      anomalyCount += anomalies.length;

      // Insert anomaly flags
      for (final anomaly in anomalies) {
        await _db.insertAnomalyFlag(anomaly);
      }
    }

    return anomalyCount;
  }

  /// Check a single record for anomalies
  Future<List<AnomalyFlag>> _checkRecordAnomalies(
    BillingRecord record,
    double operatingHoursThreshold,
  ) async {
    final List<AnomalyFlag> anomalies = [];
    final now = DateTime.now();

    // 1. Check for stand mundur (meter reading going backward) - CRITICAL
    if (record.prevOffPeakStand != null) {
      final prevOffPeak = double.tryParse(record.prevOffPeakStand!) ?? 0.0;
      if (record.offPeakStand < prevOffPeak) {
        anomalies.add(
          AnomalyFlag(
            billingRecordId: record.id!,
            type: AnomalyType.standMundur,
            severity: AnomalySeverity.critical,
            description:
                'Stand LWBP mundur: ${prevOffPeak.toStringAsFixed(2)} → ${record.offPeakStand.toStringAsFixed(2)}',
            flaggedAt: now,
          ),
        );
      }
    }

    if (record.prevPeakStand != null) {
      final prevPeak = double.tryParse(record.prevPeakStand!) ?? 0.0;
      if (record.peakStand < prevPeak) {
        anomalies.add(
          AnomalyFlag(
            billingRecordId: record.id!,
            type: AnomalyType.standMundur,
            severity: AnomalySeverity.critical,
            description:
                'Stand WBP mundur: ${prevPeak.toStringAsFixed(2)} → ${record.peakStand.toStringAsFixed(2)}',
            flaggedAt: now,
          ),
        );
      }
    }

    // 2. Check for excessive operating hours (configurable threshold) - MEDIUM
    if (record.operatingHours > operatingHoursThreshold) {
      anomalies.add(
        AnomalyFlag(
          billingRecordId: record.id!,
          type: AnomalyType.excessiveHours,
          severity: AnomalySeverity.medium,
          description:
              'Jam nyala melebihi ${operatingHoursThreshold.toStringAsFixed(0)} jam: ${record.operatingHours.toStringAsFixed(1)} jam',
          flaggedAt: now,
        ),
      );
    }

    // 3. Check for zero consumption - MEDIUM
    final totalConsumption = record.offPeakConsumption + record.peakConsumption;
    if (totalConsumption == 0) {
      anomalies.add(
        AnomalyFlag(
          billingRecordId: record.id!,
          type: AnomalyType.zeroConsumption,
          severity: AnomalySeverity.medium,
          description: 'Konsumsi nol untuk periode ini',
          flaggedAt: now,
        ),
      );
    }

    // 4. Check for consumption spike/decrease - compare with average AND previous month
    final consumptionThreshold = await _db.getConsumptionVarianceThreshold();
    final avgConsumption = await _db.getAverageConsumption(record.customerId);
    final prevMonthConsumption = await _db.getPreviousMonthConsumption(
      record.customerId,
      record.billingPeriod,
    );

    double? varianceFromAvg;
    double? varianceFromPrev;

    if (avgConsumption > 0) {
      varianceFromAvg =
          ((totalConsumption - avgConsumption) / avgConsumption) * 100;
    }

    if (prevMonthConsumption != null && prevMonthConsumption > 0) {
      varianceFromPrev =
          ((totalConsumption - prevMonthConsumption) / prevMonthConsumption) *
          100;
    }

    // Check if it's a spike (exceeds threshold)
    final isSpike =
        (varianceFromAvg != null && varianceFromAvg > consumptionThreshold) ||
        (varianceFromPrev != null && varianceFromPrev > consumptionThreshold);

    // Check if it's a decrease (exceeds negative threshold)
    final isDecrease =
        (varianceFromAvg != null && varianceFromAvg < -consumptionThreshold) ||
        (varianceFromPrev != null && varianceFromPrev < -consumptionThreshold);

    if (isSpike) {
      // Build description showing both comparisons
      final descParts = <String>[];
      if (varianceFromAvg != null && varianceFromAvg > consumptionThreshold) {
        descParts.add('+${varianceFromAvg.toStringAsFixed(0)}% vs Avg 12 bln');
      }
      if (varianceFromPrev != null && varianceFromPrev > consumptionThreshold) {
        descParts.add('+${varianceFromPrev.toStringAsFixed(0)}% vs Bln Lalu');
      }

      anomalies.add(
        AnomalyFlag(
          billingRecordId: record.id!,
          type: AnomalyType.consumptionSpike,
          severity: AnomalySeverity.medium,
          description: 'Konsumsi naik: ${descParts.join(', ')}',
          flaggedAt: now,
        ),
      );
    } else if (isDecrease) {
      // Build description showing both comparisons
      final descParts = <String>[];
      if (varianceFromAvg != null && varianceFromAvg < -consumptionThreshold) {
        descParts.add('${varianceFromAvg.toStringAsFixed(0)}% vs Avg 12 bln');
      }
      if (varianceFromPrev != null &&
          varianceFromPrev < -consumptionThreshold) {
        descParts.add('${varianceFromPrev.toStringAsFixed(0)}% vs Bln Lalu');
      }

      anomalies.add(
        AnomalyFlag(
          billingRecordId: record.id!,
          type: AnomalyType.consumptionDecrease,
          severity: AnomalySeverity.medium,
          description: 'Konsumsi turun: ${descParts.join(', ')}',
          flaggedAt: now,
        ),
      );
    }

    return anomalies;
  }

  /// Detect anomalies for a specific customer
  Future<int> detectAnomaliesForCustomer(String customerId) async {
    int anomalyCount = 0;

    // Check if customer is active
    final isActive = await _db.isCustomerActive(customerId);
    if (!isActive) return 0; // Skip inactive customers

    // Get operating hours threshold from settings
    final operatingHoursThreshold = await _db.getOperatingHoursThreshold();

    final records = await _db.getBillingRecordsByCustomer(customerId);

    for (final record in records) {
      if (record.id == null) continue;

      // Delete existing anomaly flags
      await _db.deleteAnomalyFlags(record.id!);

      // Check for anomalies
      final anomalies = await _checkRecordAnomalies(
        record,
        operatingHoursThreshold,
      );

      // Insert new anomaly flags
      for (final anomaly in anomalies) {
        await _db.insertAnomalyFlag(anomaly);
        anomalyCount++;
      }
    }

    return anomalyCount;
  }
}
