import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/customer.dart';
import '../../shared/models/billing_record.dart';
import '../../shared/models/import_record.dart';
import '../database/database_helper.dart';

// Database provider
final databaseProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

// Dashboard summary provider
final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
  final db = ref.watch(databaseProvider);

  final latestPeriod = await db.getLatestBillingPeriod();

  if (latestPeriod == null) {
    return DashboardSummary(
      activeCustomersCount: 0,
      totalRptag: 0.0,
      anomalyCount: 0,
      latestPeriod: null,
    );
  }

  final activeCustomersCount = await db.getActiveCustomersCount(latestPeriod);
  final totalRptag = await db.getTotalRptag(latestPeriod);
  final anomalyCount = await db.getAnomalyCount();
  final totalConsumption = await db.getTotalConsumption(latestPeriod);

  // Get previous period data
  final previousPeriod = await db.getPreviousBillingPeriod(latestPeriod);
  int previousCustomersCount = 0;
  double previousTotalRptag = 0.0;
  double previousTotalConsumption = 0.0;

  if (previousPeriod != null) {
    previousCustomersCount = await db.getActiveCustomersCount(previousPeriod);
    previousTotalRptag = await db.getTotalRptag(previousPeriod);
    previousTotalConsumption = await db.getTotalConsumption(previousPeriod);
  }

  return DashboardSummary(
    activeCustomersCount: activeCustomersCount,
    totalRptag: totalRptag,
    anomalyCount: anomalyCount,
    latestPeriod: latestPeriod,
    previousCustomersCount: previousCustomersCount,
    previousTotalRptag: previousTotalRptag,
    previousPeriod: previousPeriod,
    totalConsumption: totalConsumption,
    previousTotalConsumption: previousTotalConsumption,
  );
});

// Dashboard summary by period provider
final dashboardSummaryByPeriodProvider =
    FutureProvider.family<DashboardSummary, String>((ref, period) async {
      final db = ref.watch(databaseProvider);

      final activeCustomersCount = await db.getActiveCustomersCount(period);
      final totalRptag = await db.getTotalRptag(period);
      final anomalyCount = await db.getAnomalyCount();
      final totalConsumption = await db.getTotalConsumption(period);

      // Get previous period data
      final previousPeriod = await db.getPreviousBillingPeriod(period);
      int previousCustomersCount = 0;
      double previousTotalRptag = 0.0;
      double previousTotalConsumption = 0.0;

      if (previousPeriod != null) {
        previousCustomersCount = await db.getActiveCustomersCount(
          previousPeriod,
        );
        previousTotalRptag = await db.getTotalRptag(previousPeriod);
        previousTotalConsumption = await db.getTotalConsumption(previousPeriod);
      }

      return DashboardSummary(
        activeCustomersCount: activeCustomersCount,
        totalRptag: totalRptag,
        anomalyCount: anomalyCount,
        latestPeriod: period,
        previousCustomersCount: previousCustomersCount,
        previousTotalRptag: previousTotalRptag,
        previousPeriod: previousPeriod,
        totalConsumption: totalConsumption,
        previousTotalConsumption: previousTotalConsumption,
      );
    });

// All customers provider
final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.getAllCustomers();
});

// Customer search provider
final customerSearchProvider = FutureProvider.family<List<Customer>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) {
    return ref.watch(customersProvider).value ?? [];
  }
  final db = ref.watch(databaseProvider);
  return await db.searchCustomers(query);
});

// Customer by ID provider
final customerByIdProvider = FutureProvider.family<Customer?, String>((
  ref,
  customerId,
) async {
  final db = ref.watch(databaseProvider);
  return await db.getCustomerById(customerId);
});

// Customer active status provider
final customerActiveStatusProvider = FutureProvider.family<bool, String>((
  ref,
  customerId,
) async {
  final db = ref.watch(databaseProvider);
  return await db.isCustomerActive(customerId);
});

// Billing records for customer provider
final billingRecordsProvider =
    FutureProvider.family<List<BillingRecord>, String>((ref, customerId) async {
      final db = ref.watch(databaseProvider);
      return await db.getBillingRecordsByCustomer(customerId);
    });

// Anomalies provider
final anomaliesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final db = ref.watch(databaseProvider);
  return await db.getAnomaliesWithRecords();
});

// Import history provider
final importHistoryProvider = FutureProvider<List<ImportRecord>>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.getImportHistory();
});

// Consumption by tariff provider
final consumptionByTariffProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  final db = ref.watch(databaseProvider);
  final latestPeriod = await db.getLatestBillingPeriod();

  if (latestPeriod == null) {
    return {};
  }

  return await db.getConsumptionByTariff(latestPeriod);
});

// Operating hours threshold provider
final operatingHoursThresholdProvider = FutureProvider<double>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.getOperatingHoursThreshold();
});

// Dashboard summary model
class DashboardSummary {
  final int activeCustomersCount;
  final double totalRptag;
  final int anomalyCount;
  final String? latestPeriod;
  final int previousCustomersCount;
  final double previousTotalRptag;
  final String? previousPeriod;
  final double totalConsumption;
  final double previousTotalConsumption;

  DashboardSummary({
    required this.activeCustomersCount,
    required this.totalRptag,
    required this.anomalyCount,
    required this.latestPeriod,
    this.previousCustomersCount = 0,
    this.previousTotalRptag = 0.0,
    this.previousPeriod,
    this.totalConsumption = 0.0,
    this.previousTotalConsumption = 0.0,
  });

  // Calculate trends
  double get customerGrowthPercent {
    if (previousCustomersCount == 0) return 0.0;
    return ((activeCustomersCount - previousCustomersCount) /
            previousCustomersCount) *
        100;
  }

  double get rptagGrowthPercent {
    if (previousTotalRptag == 0) return 0.0;
    return ((totalRptag - previousTotalRptag) / previousTotalRptag) * 100;
  }

  double get consumptionGrowthPercent {
    if (previousTotalConsumption == 0) return 0.0;
    return ((totalConsumption - previousTotalConsumption) /
            previousTotalConsumption) *
        100;
  }
}
