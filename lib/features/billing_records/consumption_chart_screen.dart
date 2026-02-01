import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/models/customer.dart';
import '../../shared/models/billing_record.dart';
import '../../core/providers/app_providers.dart';

class ConsumptionChartScreen extends ConsumerWidget {
  final Customer customer;

  const ConsumptionChartScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grafik Pemakaian'),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 16,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 1200 : constraints.maxWidth,
                ),
                child: ConsumptionChartSection(customer: customer),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ConsumptionChartSection extends ConsumerStatefulWidget {
  final Customer customer;

  const ConsumptionChartSection({super.key, required this.customer});

  @override
  ConsumerState<ConsumptionChartSection> createState() =>
      _ConsumptionChartSectionState();
}

class _ConsumptionChartSectionState
    extends ConsumerState<ConsumptionChartSection> {
  bool showLWBP = true;
  bool showWBP = true;
  bool showKVARH = true;
  bool showRPTAG = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _allowWbpKvarh {
    final tariff = widget.customer.tariff.trim().toUpperCase();
    return tariff == 'I2' ||
        tariff == 'I3' ||
        widget.customer.powerCapacity > 200000;
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(
      billingRecordsProvider(widget.customer.customerId),
    );
    final theme = Theme.of(context);

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return _buildEmptyState(theme);
        }

        final allowWbpKvarh = _allowWbpKvarh;
        final effectiveShowWBP = allowWbpKvarh && showWBP;
        final effectiveShowKVARH = allowWbpKvarh && showKVARH;

        // Sort by period ascending for chart display
        records.sort((a, b) => a.billingPeriod.compareTo(b.billingPeriod));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient - Consistent with Billing Records (Indigo)
            _buildGradientHeader(theme),
            const SizedBox(height: 24),

            // Trend Statistics Cards
            _buildCustomerDetails(records, theme),
            const SizedBox(height: 20),

            // Chart with integrated legend and series toggle
            _buildChartCard(
              records,
              showWbp: effectiveShowWBP,
              showKvarh: effectiveShowKVARH,
              allowWbpKvarh: allowWbpKvarh,
              theme: theme,
            ),
            const SizedBox(height: 20),

            // Stand Meter Table
            _buildStandMeterTable(records, theme),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(64),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => _buildErrorState(error, theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data pemakaian',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade200),
      ),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Terjadi kesalahan: $error',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientHeader(ThemeData theme) {
    final customer = widget.customer;
    final formatter = NumberFormat('#,##0', 'id_ID');

    // Use Indigo to match Billing Records screen
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade500, Colors.indigo.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.shade200.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: ID + Name
          Row(
            children: [
              // Customer ID Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  customer.customerId,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Customer Name
              Expanded(
                child: Text(
                  customer.nama,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Tariff + Power Capacity
          Row(
            children: [
              Icon(Icons.bolt, size: 18, color: Colors.yellow.shade300),
              const SizedBox(width: 6),
              Text(
                '${customer.tariff} / ${formatter.format(customer.powerCapacity.toInt())} VA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(
    List<BillingRecord> records, {
    required bool showWbp,
    required bool showKvarh,
    required bool allowWbpKvarh,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Grafik Pemakaian',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${records.length} Periode',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Integrated Series Toggle
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildCompactFilterChip(
                      label: 'LWBP',
                      selected: showLWBP,
                      color: Colors.blue,
                      onSelected: (value) => setState(() => showLWBP = value),
                    ),
                    if (allowWbpKvarh)
                      _buildCompactFilterChip(
                        label: 'WBP',
                        selected: showWBP,
                        color: Colors.green,
                        onSelected: (value) => setState(() => showWBP = value),
                      ),
                    if (allowWbpKvarh)
                      _buildCompactFilterChip(
                        label: 'KVARH',
                        selected: showKVARH,
                        color: Colors.orange,
                        onSelected: (value) =>
                            setState(() => showKVARH = value),
                      ),
                    _buildCompactFilterChip(
                      label: 'RPTAG',
                      selected: showRPTAG,
                      color: Colors.purple,
                      onSelected: (value) => setState(() => showRPTAG = value),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Chart
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildChart(records, showWbp: showWbp, showKvarh: showKvarh),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFilterChip({
    required String label,
    required bool selected,
    required Color color,
    required ValueChanged<bool> onSelected,
  }) {
    return InkWell(
      onTap: () => onSelected(!selected),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.shade400,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: selected ? color : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(
    List<BillingRecord> records, {
    required bool showWbp,
    required bool showKvarh,
  }) {
    final allowWbpKvarh = _allowWbpKvarh;
    final effectiveShowWBP = allowWbpKvarh && showWbp;
    final effectiveShowKVARH = allowWbpKvarh && showKvarh;

    // Find max value for y-axis
    double maxY = 0;
    for (final record in records) {
      if (showLWBP && record.offPeakConsumption > maxY) {
        maxY = record.offPeakConsumption;
      }
      if (effectiveShowWBP && record.peakConsumption > maxY) {
        maxY = record.peakConsumption;
      }
      if (effectiveShowKVARH &&
          record.kvarhConsumption != null &&
          record.kvarhConsumption! > maxY) {
        maxY = record.kvarhConsumption!;
      }
      if (showRPTAG && record.rptag > maxY) {
        maxY = record.rptag;
      }
    }
    maxY = maxY * 1.1; // Add 10% padding
    if (maxY == 0) maxY = 100;

    final horizontalInterval = maxY / 5;
    final safeHorizontalInterval = horizontalInterval > 0
        ? horizontalInterval
        : 1.0;

    return SizedBox(
      height: 350,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: safeHorizontalInterval.toDouble(),
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: records.length > 12 ? 2 : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= records.length) {
                    return const Text('');
                  }
                  final period = records[index].billingPeriod;

                  // Format to Jan'25 style
                  String formattedPeriod = _formatPeriodShort(period);

                  return Transform.translate(
                    offset: const Offset(0, 8),
                    child: Transform.rotate(
                      angle: -0.7854, // -45 degrees in radians
                      child: Text(
                        formattedPeriod,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 70,
                interval: safeHorizontalInterval.toDouble(),
                getTitlesWidget: (value, meta) {
                  final formatter = NumberFormat('#,##0', 'id_ID');
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      formatter.format(value.toInt()),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: false,
              fitInsideVertically: true,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              tooltipMargin: 8,
              maxContentWidth: 250,
              getTooltipColor: (touchedSpot) => Colors.grey.shade800,
              getTooltipItems: (touchedSpots) {
                if (touchedSpots.isEmpty) return [];

                final index = touchedSpots.first.x.toInt();
                if (index < 0 || index >= records.length) return [];

                final record = records[index];
                final formatter = NumberFormat('#,##0', 'id_ID');

                // Build table rows for each series
                final List<Map<String, dynamic>> rows = [];

                for (var spot in touchedSpots) {
                  String seriesName = '';
                  String unit = '';
                  Color color = Colors.white;

                  // Calculate the actual bar index based on which series are visible
                  int currentBarIndex = 0;

                  if (showLWBP) {
                    if (spot.barIndex == currentBarIndex) {
                      seriesName = 'LWBP';
                      unit = 'kWh';
                      color = Colors.blue.shade300;
                    }
                    currentBarIndex++;
                  }

                  if (effectiveShowWBP) {
                    if (spot.barIndex == currentBarIndex) {
                      seriesName = 'WBP';
                      unit = 'kWh';
                      color = Colors.green.shade300;
                    }
                    currentBarIndex++;
                  }

                  if (effectiveShowKVARH) {
                    if (spot.barIndex == currentBarIndex) {
                      seriesName = 'KVARH';
                      unit = 'kVARh';
                      color = Colors.orange.shade300;
                    }
                    currentBarIndex++;
                  }

                  if (showRPTAG) {
                    if (spot.barIndex == currentBarIndex) {
                      seriesName = 'RPTAG';
                      unit = 'Rp';
                      color = Colors.purple.shade300;
                    }
                  }

                  final value = unit == 'Rp'
                      ? formatter.format(spot.y.toInt())
                      : formatter.format(spot.y.toInt());

                  rows.add({
                    'name': seriesName,
                    'value': value,
                    'unit': unit,
                    'color': color,
                  });
                }

                // Build table layout
                final colWidth = 8; // Width for series name column
                String tableContent = 'Periode: ${record.billingPeriod}\n';
                tableContent += 'ID: ${record.customerId}\n';
                tableContent += '━━━━━━━━━━━━━━━━━━━━━━\n';

                for (var row in rows) {
                  final name = (row['name'] as String).padRight(colWidth);
                  final unit = row['unit'] as String;
                  final value = unit == 'Rp'
                      ? 'Rp ${row['value']}'
                      : '${row['value']} $unit';
                  tableContent += '$name : $value\n';
                }

                // Return only one tooltip item with the full table
                // Use null for other spots to avoid extra spacing
                return List.generate(
                  touchedSpots.length,
                  (index) => index == 0
                      ? LineTooltipItem(
                          tableContent.trim(),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                            height: 1.5,
                            fontFamily: 'monospace',
                            overflow: TextOverflow.visible,
                          ),
                          textAlign: TextAlign.left,
                        )
                      : null,
                );
              },
            ),
            handleBuiltInTouches: true,
          ),
          lineBarsData: [
            if (showLWBP)
              LineChartBarData(
                spots: [
                  for (int i = 0; i < records.length; i++)
                    FlSpot(i.toDouble(), records[i].offPeakConsumption),
                ],
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: records.length <= 12,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.blue,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withValues(alpha: 0.3),
                      Colors.blue.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            if (showWbp)
              LineChartBarData(
                spots: [
                  for (int i = 0; i < records.length; i++)
                    FlSpot(i.toDouble(), records[i].peakConsumption),
                ],
                isCurved: true,
                color: Colors.green,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: records.length <= 12,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.green,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.3),
                      Colors.green.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            if (showKvarh)
              LineChartBarData(
                spots: [
                  for (int i = 0; i < records.length; i++)
                    if (records[i].kvarhConsumption != null)
                      FlSpot(i.toDouble(), records[i].kvarhConsumption!),
                ],
                isCurved: true,
                color: Colors.orange,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: records.length <= 12,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.orange,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withValues(alpha: 0.3),
                      Colors.orange.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            if (showRPTAG)
              LineChartBarData(
                spots: [
                  for (int i = 0; i < records.length; i++)
                    FlSpot(i.toDouble(), records[i].rptag),
                ],
                isCurved: true,
                color: Colors.purple,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: records.length <= 12,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.purple,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withValues(alpha: 0.3),
                      Colors.purple.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
          ],
          minX: 0,
          maxX: records.isNotEmpty ? (records.length - 1).toDouble() : 0,
          minY: 0,
          maxY: maxY,
        ),
      ),
    );
  }

  String _formatPeriodShort(String period) {
    if (period.length != 6) return period;
    final year = period.substring(2, 4);
    final month = period.substring(4, 6);
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final monthIndex = int.tryParse(month);
    if (monthIndex == null || monthIndex < 1 || monthIndex > 12) return period;
    return "${monthNames[monthIndex - 1]}'$year";
  }

  Widget _buildCustomerDetails(List<BillingRecord> records, ThemeData theme) {
    final sortedRecords = [...records]
      ..sort((a, b) => b.billingPeriod.compareTo(a.billingPeriod));
    final formatter = NumberFormat('#,##0', 'id_ID');

    // Data untuk trend card 1: vs Bulan Lalu (RPTAG)
    String monthCompare = '-';
    String latestPeriod = '-';
    String previousPeriod = '-';
    double latestRptag = 0;
    double previousRptag = 0;
    double diffRptag = 0;
    Color monthColor = Colors.grey;
    bool isPositiveMonth = false;

    if (sortedRecords.length >= 2) {
      latestRptag = sortedRecords[0].rptag;
      previousRptag = sortedRecords[1].rptag;
      latestPeriod = _formatPeriodShort(sortedRecords[0].billingPeriod);
      previousPeriod = _formatPeriodShort(sortedRecords[1].billingPeriod);
      diffRptag = latestRptag - previousRptag;

      if (previousRptag > 0) {
        final percentChange =
            ((latestRptag - previousRptag) / previousRptag) * 100;
        isPositiveMonth = percentChange >= 0;
        monthCompare = '${percentChange.abs().toStringAsFixed(1)}%';
        monthColor = percentChange >= 0
            ? Colors.red.shade600
            : Colors.green.shade600;
      }
    }

    // Data untuk trend card 2: vs Rata-rata 3 Bulan (RPTAG)
    String threeMonthAvg = '-';
    double avg3MonthRptag = 0;
    double diffAvg = 0;
    Color avg3Color = Colors.grey;
    bool isPositive3Month = false;

    if (sortedRecords.length >= 4) {
      avg3MonthRptag =
          (sortedRecords[1].rptag +
              sortedRecords[2].rptag +
              sortedRecords[3].rptag) /
          3;
      diffAvg = latestRptag - avg3MonthRptag;

      if (avg3MonthRptag > 0) {
        final percentChange =
            ((latestRptag - avg3MonthRptag) / avg3MonthRptag) * 100;
        isPositive3Month = percentChange >= 0;
        threeMonthAvg = '${percentChange.abs().toStringAsFixed(1)}%';
        avg3Color = percentChange >= 0
            ? Colors.red.shade600
            : Colors.green.shade600;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Perbandingan RPTAG Bulan Lalu
        Expanded(
          child: _buildDetailedTrendCard(
            title: 'RPTAG vs Bln Lalu',
            currentPeriod: latestPeriod,
            comparePeriod: previousPeriod,
            currentValue: latestRptag,
            compareValue: previousRptag,
            diffValue: diffRptag,
            percentChange: monthCompare,
            isPositive: isPositiveMonth,
            color: monthColor,
            theme: theme,
            formatter: formatter,
          ),
        ),
        const SizedBox(width: 16),
        // Card 2: Perbandingan RPTAG Rata-rata 3 Bulan
        Expanded(
          child: _buildDetailedTrendCard(
            title: 'RPTAG vs Avg 3 Bln',
            currentPeriod: latestPeriod,
            comparePeriod: 'Avg 3 bln',
            currentValue: latestRptag,
            compareValue: avg3MonthRptag,
            diffValue: diffAvg,
            percentChange: threeMonthAvg,
            isPositive: isPositive3Month,
            color: avg3Color,
            theme: theme,
            formatter: formatter,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedTrendCard({
    required String title,
    required String currentPeriod,
    required String comparePeriod,
    required double currentValue,
    required double compareValue,
    required double diffValue,
    required String percentChange,
    required bool isPositive,
    required Color color,
    required ThemeData theme,
    required NumberFormat formatter,
  }) {
    final hasData = currentValue > 0 || compareValue > 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and percentage badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                // Percentage Badge
                if (hasData)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${isPositive ? '↑' : '↓'} $percentChange',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
            if (hasData) ...[
              const SizedBox(height: 12),
              // Compact comparison: Current vs Compare in vertical layout
              Row(
                children: [
                  // Current Period Box
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentPeriod,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Rp ${formatter.format(currentValue.toInt())}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Compare Period Box
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comparePeriod,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Rp ${formatter.format(compareValue.toInt())}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Difference summary - compact
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? 'Naik' : 'Turun'} Rp ${formatter.format(diffValue.abs().toInt())}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Data tidak cukup untuk perbandingan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStandMeterTable(List<BillingRecord> records, ThemeData theme) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    final displayRecords = records.take(12).toList().reversed.toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.table_chart_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tabel Stand kWh Meter',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '12 Bulan Terakhir',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Hint
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.swipe, size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Geser ke kanan untuk melihat semua data',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
          ),
          // Table
          Padding(
            padding: const EdgeInsets.all(16),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.teal.shade50),
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 52,
                  columnSpacing: 16,
                  horizontalMargin: 16,
                  headingRowHeight: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  columns: [
                    DataColumn(
                      label: SizedBox(
                        width: 90,
                        child: Text(
                          'Series',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.teal.shade700,
                          ),
                        ),
                      ),
                    ),
                    ...displayRecords.map(
                      (record) => DataColumn(
                        label: SizedBox(
                          width: 75,
                          child: Text(
                            _formatPeriodShort(record.billingPeriod),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.teal.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        numeric: true,
                      ),
                    ),
                  ],
                  rows: [
                    // Row for LWBP
                    DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'LWBP',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...displayRecords.asMap().entries.map((entry) {
                          final index = entry.key;
                          final record = entry.value;
                          final currentValue = record.offPeakStand;

                          bool isDecreased = false;
                          if (index < displayRecords.length - 1) {
                            final prevValue =
                                displayRecords[index + 1].offPeakStand;
                            isDecreased = currentValue < prevValue;
                          }

                          return DataCell(
                            Text(
                              formatter.format(currentValue.toInt()),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDecreased
                                    ? Colors.red
                                    : Colors.grey.shade800,
                                fontWeight: isDecreased
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    // Row for WBP
                    DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'WBP',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...displayRecords.asMap().entries.map((entry) {
                          final index = entry.key;
                          final record = entry.value;
                          final currentValue = record.peakStand;

                          bool isDecreased = false;
                          if (index < displayRecords.length - 1) {
                            final prevValue =
                                displayRecords[index + 1].peakStand;
                            isDecreased = currentValue < prevValue;
                          }

                          return DataCell(
                            Text(
                              formatter.format(currentValue.toInt()),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDecreased
                                    ? Colors.red
                                    : Colors.grey.shade800,
                                fontWeight: isDecreased
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    // Row for KVARH
                    DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'KVARH',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...displayRecords.asMap().entries.map((entry) {
                          final index = entry.key;
                          final record = entry.value;
                          final currentValue = record.kvarhConsumption;

                          bool isDecreased = false;
                          if (index < displayRecords.length - 1 &&
                              currentValue != null) {
                            final prevValue =
                                displayRecords[index + 1].kvarhConsumption;
                            if (prevValue != null) {
                              isDecreased = currentValue < prevValue;
                            }
                          }

                          return DataCell(
                            Text(
                              currentValue != null
                                  ? formatter.format(currentValue.toInt())
                                  : '-',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDecreased
                                    ? Colors.red
                                    : Colors.grey.shade800,
                                fontWeight: isDecreased
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    // Row for RPTAG
                    DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'RPTAG',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...displayRecords.map(
                          (record) => DataCell(
                            Text(
                              formatter.format(record.rptag.toInt()),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
