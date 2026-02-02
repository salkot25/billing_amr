import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/database/database_helper.dart';
import '../../core/providers/app_providers.dart';
import '../import_excel/import_excel_screen.dart';
import '../billing_records/billing_records_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? selectedPeriod;

  @override
  Widget build(BuildContext context) {
    final periodsAsync = ref.watch(availablePeriodsProvider);

    return periodsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
      data: (availablePeriods) {
        // Tidak ada data sama sekali
        if (availablePeriods.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Dashboard'),
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
            body: _buildEmptyDataState(context),
          );
        }

        // Set default period jika belum ada atau period tidak valid
        if (selectedPeriod == null ||
            !availablePeriods.contains(selectedPeriod)) {
          selectedPeriod = availablePeriods.first;
        }

        final dashboardAsync = ref.watch(
          dashboardSummaryByPeriodProvider(selectedPeriod!),
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(availablePeriodsProvider);
                  ref.invalidate(
                    dashboardSummaryByPeriodProvider(selectedPeriod!),
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 16,
                    vertical: 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWide ? 1080 : constraints.maxWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Dashboard Summary Cards
                          dashboardAsync.when(
                            data: (summary) => _buildSummaryCards(
                              context,
                              summary,
                              ref,
                              selectedPeriod!,
                              availablePeriods,
                              (period) {
                                setState(() {
                                  selectedPeriod = period;
                                });
                              },
                            ),
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (error, stack) =>
                                Center(child: Text('Error: $error')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyDataState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 64,
                color: Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan import data billing terlebih dahulu\nuntuk melihat dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImportExcelScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Import Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    DashboardSummary summary,
    WidgetRef ref,
    String selectedPeriod,
    List<String> availablePeriods,
    ValueChanged<String> onPeriodChanged,
  ) {
    final numberFormat = NumberFormat('#,##0', 'id_ID');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Unified Header with Period Info and Controls
            if (summary.latestPeriod != null)
              Container(
                padding: EdgeInsets.all(isWide ? 24 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade500, Colors.blue.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left: Icon & Title
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.dashboard_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dashboard Billing AMR',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PLN ULP Salatiga Kota',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Right: Period Dropdown & Import Button
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedPeriod,
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.blue.shade600,
                                size: 20,
                              ),
                              isDense: true,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                              items: availablePeriods.map((period) {
                                return DropdownMenuItem<String>(
                                  value: period,
                                  child: Text(_formatPeriod(period)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  onPeriodChanged(value);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () => _showImportDialog(context, ref),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                Icons.upload_file_rounded,
                                color: Colors.blue.shade700,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Main KPI Cards with comparison - 3 columns
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: isWide
                      ? (constraints.maxWidth - 32) / 3
                      : constraints.maxWidth,
                  child: _ComparisonCard(
                    title: 'Jumlah Pelanggan',
                    currentValue: summary.activeCustomersCount,
                    previousValue: summary.previousCustomersCount,
                    icon: Icons.people_alt_rounded,
                    accentColor: Theme.of(context).colorScheme.primary,
                    numberFormat: numberFormat,
                    isPercentage: false,
                    onTap: () => _navigateToBillingRecords(context),
                    sparklineDataFuture: ref
                        .read(databaseProvider)
                        .getCustomerCountHistory(),
                  ),
                ),
                SizedBox(
                  width: isWide
                      ? (constraints.maxWidth - 32) / 3
                      : constraints.maxWidth,
                  child: _ComparisonCard(
                    title: 'Total Konsumsi (kWh)',
                    currentValue: summary.totalConsumption,
                    previousValue: summary.previousTotalConsumption,
                    icon: Icons.bolt_rounded,
                    accentColor: Theme.of(context).colorScheme.primary,
                    numberFormat: numberFormat,
                    isPercentage: false,
                    suffix: ' kWh',
                    onTap: () => _showConsumptionHistoryDialog(context, ref),
                    sparklineDataFuture: ref
                        .read(databaseProvider)
                        .getConsumptionSparklineHistory(),
                  ),
                ),
                SizedBox(
                  width: isWide
                      ? (constraints.maxWidth - 32) / 3
                      : constraints.maxWidth,
                  child: _ComparisonCard(
                    title: 'Total Tagihan (RPTAG)',
                    currentValue: summary.totalRptag,
                    previousValue: summary.previousTotalRptag,
                    icon: Icons.attach_money_rounded,
                    accentColor: Theme.of(context).colorScheme.primary,
                    numberFormat: numberFormat,
                    currencyFormat: currencyFormat,
                    isPercentage: false,
                    onTap: () => _showRptagHistoryDialog(context, ref),
                    sparklineDataFuture: ref
                        .read(databaseProvider)
                        .getRptagSparklineHistory(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Chart konsumsi per tarif
            _TariffConsumptionChart(
              isWide: isWide,
              selectedPeriod: selectedPeriod,
            ),
          ],
        );
      },
    );
  }

  String _formatPeriod(String period) {
    if (period.length != 6) return period;
    final year = period.substring(0, 4);
    final month = period.substring(4, 6);
    final monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final monthIndex = int.tryParse(month);
    if (monthIndex == null || monthIndex < 1 || monthIndex > 12) return period;
    return '${monthNames[monthIndex - 1]} $year';
  }

  Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: const ImportExcelScreen(),
        ),
      ),
    );
  }

  Future<void> _showConsumptionHistoryDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
          child: _ConsumptionHistoryChart(),
        ),
      ),
    );
  }

  Future<void> _showRptagHistoryDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
          child: _RptagHistoryChart(),
        ),
      ),
    );
  }

  void _navigateToBillingRecords(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BillingRecordsScreen()),
    );
  }
}

class _ConsumptionHistoryChart extends ConsumerWidget {
  const _ConsumptionHistoryChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final db = ref.watch(databaseProvider);

    return FutureBuilder<Map<String, double>>(
      future: db.getYearlyConsumptionHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada data histori konsumsi',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada data untuk ditampilkan',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final numberFormat = NumberFormat('#,##0', 'id_ID');
        final values = data.values.toList();
        final maxValue = values.reduce((a, b) => a > b ? a : b);
        final minValue = values.reduce((a, b) => a < b ? a : b);
        final totalValue = values.reduce((a, b) => a + b);
        final avgValue = totalValue / values.length;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;
            final barWidth = isCompact ? 14.0 : 22.0;

            return Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(isCompact ? 16 : 24),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.analytics_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Histori Konsumsi kWh',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Data konsumsi listrik 12 bulan terakhir',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            color: Colors.orange.shade700,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Summary Statistics
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          alignment: WrapAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Total',
                              '${numberFormat.format(totalValue)} kWh',
                              Icons.functions,
                              Colors.orange.shade700,
                              isCompact,
                            ),
                            _buildStatItem(
                              'Rata-rata',
                              '${numberFormat.format(avgValue.round())} kWh',
                              Icons.trending_flat,
                              Colors.blue.shade600,
                              isCompact,
                            ),
                            _buildStatItem(
                              'Tertinggi',
                              '${numberFormat.format(maxValue)} kWh',
                              Icons.arrow_upward,
                              Colors.green.shade600,
                              isCompact,
                            ),
                            _buildStatItem(
                              'Terendah',
                              '${numberFormat.format(minValue)} kWh',
                              Icons.arrow_downward,
                              Colors.red.shade600,
                              isCompact,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Chart
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isCompact ? 16 : 24),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxValue * 1.2,
                        minY: 0,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) =>
                                Colors.orange.shade700.withValues(alpha: 0.9),
                            tooltipPadding: const EdgeInsets.all(8),
                            tooltipMargin: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final period = data.keys.elementAt(groupIndex);
                              final diff = rod.toY - avgValue;
                              final diffPercent = (diff / avgValue * 100)
                                  .abs()
                                  .toStringAsFixed(1);
                              final isPositive = diff >= 0;
                              final diffText = isPositive
                                  ? '↑ +$diffPercent%'
                                  : '↓ −$diffPercent%';
                              return BarTooltipItem(
                                '${_formatPeriodShort(period)}\n',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        '${numberFormat.format(rod.toY)} kWh\n',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '$diffText vs rata-rata',
                                    style: TextStyle(
                                      color: isPositive
                                          ? Colors.greenAccent.shade100
                                          : Colors.yellow.shade200,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < data.length) {
                                  final period = data.keys.elementAt(
                                    value.toInt(),
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Transform.rotate(
                                      angle: -0.5, // -30 degrees in radians
                                      child: Text(
                                        _formatPeriodShort(period),
                                        style: TextStyle(
                                          fontSize: isCompact ? 9 : 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: isCompact ? 50 : 60,
                              getTitlesWidget: (value, meta) {
                                if (value >= 1000000) {
                                  return Text(
                                    '${(value / 1000000).toStringAsFixed(1)}jt',
                                    style: TextStyle(
                                      fontSize: isCompact ? 9 : 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                }
                                return Text(
                                  numberFormat.format(value),
                                  style: TextStyle(
                                    fontSize: isCompact ? 9 : 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxValue / 5,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            left: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: avgValue,
                              color: Colors.blue.shade400,
                              strokeWidth: 2,
                              dashArray: [8, 4],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.topRight,
                                padding: const EdgeInsets.only(
                                  right: 8,
                                  bottom: 4,
                                ),
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                labelResolver: (line) => 'Rata-rata',
                              ),
                            ),
                          ],
                        ),
                        barGroups: data.entries.map((entry) {
                          final index = data.keys.toList().indexOf(entry.key);
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value,
                                color: entry.value >= avgValue
                                    ? Colors.orange.shade700
                                    : Colors.orange.shade400,
                                width: barWidth,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: maxValue * 1.2,
                                  color: Colors.orange.shade50,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isCompact,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isCompact ? 16 : 18, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatPeriodShort(String period) {
    if (period.length != 6) return period;
    final month = period.substring(4, 6);
    final year = period.substring(2, 4);
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final monthIndex = int.tryParse(month);
    if (monthIndex == null || monthIndex < 1 || monthIndex > 12) return period;
    return '${monthNames[monthIndex - 1]} \'$year';
  }
}

class _RptagHistoryChart extends ConsumerWidget {
  const _RptagHistoryChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final db = ref.watch(databaseProvider);

    return FutureBuilder<Map<String, double>>(
      future: db.getYearlyRptagHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.attach_money_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada data histori tagihan',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada data untuk ditampilkan',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final currencyFormat = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );
        final compactCurrencyFormat = NumberFormat.compactCurrency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 1,
        );
        final values = data.values.toList();
        final maxValue = values.reduce((a, b) => a > b ? a : b);
        final minValue = values.reduce((a, b) => a < b ? a : b);
        final totalValue = values.reduce((a, b) => a + b);
        final avgValue = totalValue / values.length;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;
            final barWidth = isCompact ? 14.0 : 22.0;

            return Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(isCompact ? 16 : 24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.analytics_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Histori Total Tagihan',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Data total tagihan (RPTAG) 12 bulan terakhir',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            color: Colors.green.shade700,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Summary Statistics
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          alignment: WrapAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Total',
                              compactCurrencyFormat.format(totalValue),
                              Icons.functions,
                              Colors.green.shade700,
                              isCompact,
                            ),
                            _buildStatItem(
                              'Rata-rata',
                              compactCurrencyFormat.format(avgValue),
                              Icons.trending_flat,
                              Colors.blue.shade600,
                              isCompact,
                            ),
                            _buildStatItem(
                              'Tertinggi',
                              compactCurrencyFormat.format(maxValue),
                              Icons.arrow_upward,
                              Colors.teal.shade600,
                              isCompact,
                            ),
                            _buildStatItem(
                              'Terendah',
                              compactCurrencyFormat.format(minValue),
                              Icons.arrow_downward,
                              Colors.red.shade600,
                              isCompact,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Chart
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isCompact ? 16 : 24),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxValue * 1.2,
                        minY: 0,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) =>
                                Colors.green.shade700.withValues(alpha: 0.9),
                            tooltipPadding: const EdgeInsets.all(8),
                            tooltipMargin: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final period = data.keys.elementAt(groupIndex);
                              final diff = rod.toY - avgValue;
                              final diffPercent = (diff / avgValue * 100)
                                  .abs()
                                  .toStringAsFixed(1);
                              final isPositive = diff >= 0;
                              final diffText = isPositive
                                  ? '↑ +$diffPercent%'
                                  : '↓ −$diffPercent%';
                              return BarTooltipItem(
                                '${_formatPeriodShort(period)}\n',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${currencyFormat.format(rod.toY)}\n',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '$diffText vs rata-rata',
                                    style: TextStyle(
                                      color: isPositive
                                          ? Colors.greenAccent.shade100
                                          : Colors.yellow.shade200,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < data.length) {
                                  final period = data.keys.elementAt(
                                    value.toInt(),
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Transform.rotate(
                                      angle: -0.5, // -30 degrees in radians
                                      child: Text(
                                        _formatPeriodShort(period),
                                        style: TextStyle(
                                          fontSize: isCompact ? 9 : 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: isCompact ? 65 : 80,
                              getTitlesWidget: (value, meta) {
                                if (value >= 1000000000) {
                                  return Text(
                                    '${(value / 1000000000).toStringAsFixed(1)}M',
                                    style: TextStyle(
                                      fontSize: isCompact ? 9 : 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                } else if (value >= 1000000) {
                                  return Text(
                                    '${(value / 1000000).toStringAsFixed(1)}jt',
                                    style: TextStyle(
                                      fontSize: isCompact ? 9 : 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                }
                                return Text(
                                  '${(value / 1000).toStringAsFixed(0)}rb',
                                  style: TextStyle(
                                    fontSize: isCompact ? 9 : 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxValue / 5,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.shade300,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            left: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: avgValue,
                              color: Colors.blue.shade400,
                              strokeWidth: 2,
                              dashArray: [8, 4],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.topRight,
                                padding: const EdgeInsets.only(
                                  right: 8,
                                  bottom: 4,
                                ),
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                labelResolver: (line) => 'Rata-rata',
                              ),
                            ),
                          ],
                        ),
                        barGroups: data.entries.map((entry) {
                          final index = data.keys.toList().indexOf(entry.key);
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value,
                                color: entry.value >= avgValue
                                    ? Colors.green.shade700
                                    : Colors.green.shade400,
                                width: barWidth,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: maxValue * 1.2,
                                  color: Colors.green.shade50,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isCompact,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isCompact ? 16 : 18, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatPeriodShort(String period) {
    if (period.length != 6) return period;
    final month = period.substring(4, 6);
    final year = period.substring(2, 4);
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final monthIndex = int.tryParse(month);
    if (monthIndex == null || monthIndex < 1 || monthIndex > 12) return period;
    return '${monthNames[monthIndex - 1]} \'$year';
  }
}

class _ComparisonCard extends StatelessWidget {
  final String title;
  final dynamic currentValue;
  final dynamic previousValue;
  final IconData icon;
  final Color accentColor;
  final NumberFormat numberFormat;
  final NumberFormat? currencyFormat;
  final bool isPercentage;
  final String? suffix;
  final VoidCallback? onTap;
  final Future<List<double>>? sparklineDataFuture;

  const _ComparisonCard({
    required this.title,
    required this.currentValue,
    required this.previousValue,
    required this.icon,
    required this.accentColor,
    required this.numberFormat,
    this.currencyFormat,
    required this.isPercentage,
    this.suffix,
    this.onTap,
    this.sparklineDataFuture,
  });

  String _formatValue(dynamic value) {
    if (currencyFormat != null) {
      return currencyFormat!.format(value);
    }
    final formatted = numberFormat.format(value);
    return suffix != null ? formatted + suffix! : formatted;
  }

  double _getPercentageChange() {
    if (previousValue == 0) return 0.0;
    return ((currentValue - previousValue) / previousValue) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentChange = _getPercentageChange();
    final isPositive = percentChange >= 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current value
              Text(
                _formatValue(currentValue),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 12),

              // Sparkline + Comparison
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Sparkline
                  if (sparklineDataFuture != null)
                    Expanded(
                      child: FutureBuilder<List<double>>(
                        future: sparklineDataFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const SizedBox(height: 40);
                          }
                          return SizedBox(
                            height: 40,
                            child: _buildSparkline(snapshot.data!, isPositive),
                          );
                        },
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 12),
                  // Trend indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 16,
                          color: isPositive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${percentChange.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPositive
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Previous period label
              Row(
                children: [
                  Text(
                    'Periode Lalu',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatValue(previousValue),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSparkline(List<double> data, bool isPositive) {
    if (data.isEmpty) return const SizedBox();

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    return CustomPaint(
      painter: _SparklinePainter(
        data: data,
        lineColor: isPositive ? Colors.green.shade400 : Colors.red.shade400,
        fillColor: isPositive
            ? Colors.green.shade400.withValues(alpha: 0.1)
            : Colors.red.shade400.withValues(alpha: 0.1),
        minValue: range > 0 ? minValue - (range * 0.1) : minValue * 0.9,
        maxValue: range > 0 ? maxValue + (range * 0.1) : maxValue * 1.1,
      ),
      size: const Size(double.infinity, 40),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Color fillColor;
  final double minValue;
  final double maxValue;

  _SparklinePainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
    required this.minValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final range = maxValue - minValue;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw endpoint dot
    if (data.isNotEmpty) {
      final lastX = size.width;
      final lastNormalized = range > 0 ? (data.last - minValue) / range : 0.5;
      final lastY = size.height - (lastNormalized * size.height);

      canvas.drawCircle(Offset(lastX, lastY), 3, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return data != oldDelegate.data;
  }
}

class _TariffConsumptionChart extends ConsumerStatefulWidget {
  final bool isWide;
  final String selectedPeriod;

  const _TariffConsumptionChart({
    required this.isWide,
    required this.selectedPeriod,
  });

  @override
  ConsumerState<_TariffConsumptionChart> createState() =>
      _TariffConsumptionChartState();
}

class _TariffConsumptionChartState
    extends ConsumerState<_TariffConsumptionChart> {
  int touchedIndex = -1;
  String selectedMetric = 'kwh'; // 'kwh', 'customer', 'rptag'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db = ref.watch(databaseProvider);

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchAllData(db, widget.selectedPeriod),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final data = snapshot.data!;
        final consumptionData = data['consumption'] as Map<String, double>;
        final customerData = data['customer'] as Map<String, int>;
        final rptagData = data['rptag'] as Map<String, double>;

        if (consumptionData.isEmpty) {
          return const SizedBox.shrink();
        }

        // Group by first letter of tariff
        final groupedConsumption = <String, double>{};
        final groupedCustomer = <String, int>{};
        final groupedRptag = <String, double>{};

        for (var entry in consumptionData.entries) {
          final firstLetter = entry.key.isNotEmpty ? entry.key[0] : entry.key;
          groupedConsumption[firstLetter] =
              (groupedConsumption[firstLetter] ?? 0.0) + entry.value;
        }

        for (var entry in customerData.entries) {
          final firstLetter = entry.key.isNotEmpty ? entry.key[0] : entry.key;
          groupedCustomer[firstLetter] =
              (groupedCustomer[firstLetter] ?? 0) + entry.value;
        }

        for (var entry in rptagData.entries) {
          final firstLetter = entry.key.isNotEmpty ? entry.key[0] : entry.key;
          groupedRptag[firstLetter] =
              (groupedRptag[firstLetter] ?? 0.0) + entry.value;
        }

        final currentData = selectedMetric == 'kwh'
            ? groupedConsumption
            : selectedMetric == 'customer'
            ? groupedCustomer.map((k, v) => MapEntry(k, v.toDouble()))
            : groupedRptag;

        final total = currentData.values.reduce((a, b) => a + b);
        final numberFormat = NumberFormat('#,##0', 'id_ID');
        final currencyFormat = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final hasSpaceForInlineToggle = constraints.maxWidth >= 800;

                    if (hasSpaceForInlineToggle) {
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.pie_chart_rounded,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Distribusi per Tarif',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedMetric == 'kwh'
                                      ? 'Persentase pemakaian kWh berdasarkan golongan tarif'
                                      : selectedMetric == 'customer'
                                      ? 'Persentase jumlah pelanggan berdasarkan golongan tarif'
                                      : 'Persentase total tagihan berdasarkan golongan tarif',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'customer',
                                label: Text('Pelanggan'),
                                icon: Icon(Icons.people_alt_rounded, size: 18),
                              ),
                              ButtonSegment(
                                value: 'kwh',
                                label: Text('kWh'),
                                icon: Icon(Icons.bolt_rounded, size: 18),
                              ),
                              ButtonSegment(
                                value: 'rptag',
                                label: Text('Tagihan'),
                                icon: Icon(
                                  Icons.attach_money_rounded,
                                  size: 18,
                                ),
                              ),
                            ],
                            selected: {selectedMetric},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                selectedMetric = newSelection.first;
                                touchedIndex = -1;
                              });
                            },
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.pie_chart_rounded,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Distribusi per Tarif',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedMetric == 'kwh'
                                          ? 'Persentase pemakaian kWh berdasarkan golongan tarif'
                                          : selectedMetric == 'customer'
                                          ? 'Persentase jumlah pelanggan berdasarkan golongan tarif'
                                          : 'Persentase total tagihan berdasarkan golongan tarif',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'customer',
                                  label: Text('Pelanggan'),
                                  icon: Icon(
                                    Icons.people_alt_rounded,
                                    size: 18,
                                  ),
                                ),
                                ButtonSegment(
                                  value: 'kwh',
                                  label: Text('kWh'),
                                  icon: Icon(Icons.bolt_rounded, size: 18),
                                ),
                                ButtonSegment(
                                  value: 'rptag',
                                  label: Text('Tagihan'),
                                  icon: Icon(
                                    Icons.attach_money_rounded,
                                    size: 18,
                                  ),
                                ),
                              ],
                              selected: {selectedMetric},
                              onSelectionChanged: (Set<String> newSelection) {
                                setState(() {
                                  selectedMetric = newSelection.first;
                                  touchedIndex = -1;
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return widget.isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: SizedBox(
                                    width: 350,
                                    height: 350,
                                    child: _buildPieChart(currentData, total),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 1,
                                child: SizedBox(
                                  height: 350,
                                  child: _buildLegend(
                                    currentData,
                                    total,
                                    theme,
                                    numberFormat,
                                    currencyFormat,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              SizedBox(
                                height: 350,
                                child: _buildPieChart(currentData, total),
                              ),
                              const SizedBox(height: 24),
                              _buildLegend(
                                currentData,
                                total,
                                theme,
                                numberFormat,
                                currencyFormat,
                              ),
                            ],
                          );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _fetchAllData(
    DatabaseHelper db,
    String period,
  ) async {
    final consumption = await db.getConsumptionByTariff(period);
    final customer = await db.getCustomerCountByTariff(period);
    final rptag = await db.getRptagByTariff(period);

    return {'consumption': consumption, 'customer': customer, 'rptag': rptag};
  }

  Widget _buildPieChart(Map<String, double> data, double total) {
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
      const Color(0xFFFFEB3B),
      const Color(0xFF795548),
    ];

    int index = 0;
    final sections = data.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = colors[index % colors.length];
      final isTouched = index == touchedIndex;
      final radius = isTouched ? 120.0 : 110.0;

      // Dynamic font size and visibility based on percentage
      final showTitle = percentage >= 3; // Only show title if >= 3%
      final fontSize = isTouched ? 14.0 : (percentage >= 10 ? 13.0 : 11.0);

      index++;

      return PieChartSectionData(
        value: entry.value,
        title: showTitle ? '${percentage.toStringAsFixed(1)}%' : '',
        color: color,
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black38, blurRadius: 2)],
        ),
        titlePositionPercentageOffset: percentage < 8 ? 0.7 : 0.55,
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 55,
        borderData: FlBorderData(show: false),
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
      ),
    );
  }

  String _getTariffName(String code) {
    final tariffNames = {
      'I': 'Industri',
      'B': 'Bisnis',
      'S': 'Sosial',
      'P': 'Pemerintah',
      'C': 'Curah',
      'R': 'Rumah Tangga',
      'L': 'Layanan Khusus',
    };
    return tariffNames[code] ?? code;
  }

  Widget _buildLegend(
    Map<String, double> data,
    double total,
    ThemeData theme,
    NumberFormat numberFormat,
    NumberFormat currencyFormat,
  ) {
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
      const Color(0xFFFFEB3B),
      const Color(0xFF795548),
    ];

    int index = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        final percentage = (entry.value / total) * 100;
        final color = colors[index % colors.length];
        index++;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tarif ${entry.key} (${_getTariffName(entry.key)})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedMetric == 'kwh'
                          ? '${numberFormat.format(entry.value)} kWh'
                          : selectedMetric == 'customer'
                          ? '${numberFormat.format(entry.value)} pelanggan'
                          : currencyFormat.format(entry.value),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
