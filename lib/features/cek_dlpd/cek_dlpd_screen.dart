import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/models/billing_record.dart';
import '../../shared/models/customer.dart';

class CekDlpdScreen extends ConsumerStatefulWidget {
  const CekDlpdScreen({super.key});

  @override
  ConsumerState<CekDlpdScreen> createState() => _CekDlpdScreenState();
}

class _CekDlpdScreenState extends ConsumerState<CekDlpdScreen> {
  final TextEditingController _customerIdController = TextEditingController();
  final List<String> _customerIds = [];

  @override
  void dispose() {
    _customerIdController.dispose();
    super.dispose();
  }

  void _addCustomerId() {
    final input = _customerIdController.text.trim();
    if (input.isEmpty) return;

    // Check if input contains multiple IDs (separated by comma, semicolon, or newline)
    final List<String> newIds = input
        .split(RegExp(r'[,;\n]+'))
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && !_customerIds.contains(id))
        .toList();

    if (newIds.isNotEmpty) {
      setState(() {
        _customerIds.addAll(newIds);
        _customerIdController.clear();
      });
    }
  }

  void _removeCustomerId(String id) {
    setState(() {
      _customerIds.remove(id);
    });
  }

  void _clearAll() {
    setState(() {
      _customerIds.clear();
      _customerIdController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cek DLPD'),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Input section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Masukkan ID Pelanggan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masukkan satu atau beberapa ID pelanggan (pisahkan dengan koma, titik koma, atau baris baru)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customerIdController,
                          decoration: InputDecoration(
                            hintText: 'Contoh: 123456789, 987654321',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.person_search_rounded,
                              color: Colors.blue.shade400,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          maxLines: 3,
                          minLines: 1,
                          onSubmitted: (_) => _addCustomerId(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _addCustomerId,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Tambah'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_customerIds.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ID Pelanggan yang akan dicek (${_customerIds.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _clearAll,
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text('Hapus Semua'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _customerIds.map((id) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.blue.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    id,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () => _removeCustomerId(id),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.red.shade400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Results section
            if (_customerIds.isEmpty)
              SizedBox(
                height: 400,
                child: Center(
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
                          Icons.search_off,
                          size: 64,
                          color: Colors.blue.shade300,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Belum ada ID pelanggan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masukkan ID pelanggan di atas untuk memulai pengecekan DLPD',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: List.generate(_customerIds.length, (index) {
                    final customerId = _customerIds[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _CustomerDlpdCard(customerId: customerId),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomerDlpdCard extends ConsumerStatefulWidget {
  final String customerId;

  const _CustomerDlpdCard({required this.customerId});

  @override
  ConsumerState<_CustomerDlpdCard> createState() => _CustomerDlpdCardState();
}

class _CustomerDlpdCardState extends ConsumerState<_CustomerDlpdCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerByIdProvider(widget.customerId));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header - Clickable
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: _isExpanded
                    ? LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade600, Colors.grey.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: _isExpanded
                      ? Radius.zero
                      : const Radius.circular(16),
                  bottomRight: _isExpanded
                      ? Radius.zero
                      : const Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: customerAsync.when(
                      data: (customer) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer?.nama ?? 'Pelanggan Tidak Ditemukan',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${widget.customerId}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      loading: () => const Text(
                        'Memuat...',
                        style: TextStyle(color: Colors.white),
                      ),
                      error: (_, stack) => Text(
                        'ID: ${widget.customerId}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),

          // Content - Collapsible
          if (_isExpanded)
            customerAsync.when(
              data: (customer) {
                if (customer == null) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Pelanggan tidak ditemukan',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final recordsAsync = ref.watch(
                  billingRecordsProvider(widget.customerId),
                );
                return recordsAsync.when(
                  data: (records) {
                    if (records.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.timeline_outlined,
                              size: 48,
                              color: Colors.blue.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada data pemakaian',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return _DlpdAnalysisContent(
                      records: records,
                      customer: customer,
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Error: $error',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Error: $error',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DlpdAnalysisContent extends StatefulWidget {
  final List<BillingRecord> records;
  final Customer customer;

  const _DlpdAnalysisContent({required this.records, required this.customer});

  @override
  State<_DlpdAnalysisContent> createState() => _DlpdAnalysisContentState();
}

class _DlpdAnalysisContentState extends State<_DlpdAnalysisContent> {
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
    // Sort records by period
    final sortedRecords = [...widget.records]
      ..sort((a, b) => a.billingPeriod.compareTo(b.billingPeriod));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer details
          _buildCustomerDetails(),
          const SizedBox(height: 16),

          // Toggle buttons
          _buildToggleButtons(),
          const SizedBox(height: 16),

          // Chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: _buildChart(sortedRecords),
          ),
          const SizedBox(height: 16),

          // Stand Meter Table
          _buildStandMeterTable(sortedRecords),
        ],
      ),
    );
  }

  Widget _buildCustomerDetails() {
    final customer = widget.customer;
    final sortedRecords = [...widget.records]
      ..sort((a, b) => b.billingPeriod.compareTo(a.billingPeriod));

    // Calculate statistics
    String monthCompare = '-';
    String threeMonthAvg = '-';
    Color monthColor = Colors.grey;
    IconData monthIcon = Icons.remove;

    if (sortedRecords.length >= 2) {
      final latest =
          sortedRecords[0].offPeakConsumption +
          sortedRecords[0].peakConsumption;
      final previous =
          sortedRecords[1].offPeakConsumption +
          sortedRecords[1].peakConsumption;

      if (previous > 0) {
        final percentChange = ((latest - previous) / previous) * 100;
        monthCompare =
            '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%';
        monthColor = percentChange >= 0
            ? Colors.red.shade600
            : Colors.green.shade600;
        monthIcon = percentChange >= 0
            ? Icons.trending_up
            : Icons.trending_down;
      }
    }

    if (sortedRecords.length >= 4) {
      final latest =
          sortedRecords[0].offPeakConsumption +
          sortedRecords[0].peakConsumption;
      final avg3Month =
          (sortedRecords[1].offPeakConsumption +
              sortedRecords[1].peakConsumption +
              sortedRecords[2].offPeakConsumption +
              sortedRecords[2].peakConsumption +
              sortedRecords[3].offPeakConsumption +
              sortedRecords[3].peakConsumption) /
          3;

      if (avg3Month > 0) {
        final percentChange = ((latest - avg3Month) / avg3Month) * 100;
        threeMonthAvg =
            '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Detail Pelanggan Section
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DETAIL PELANGGAN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  const Divider(thickness: 1, height: 1),
                  const SizedBox(height: 12),
                  _buildDetailRow('ID Pelanggan', customer.customerId),
                  const SizedBox(height: 8),
                  _buildDetailRow('Nama', customer.nama),
                  const SizedBox(height: 8),
                  _buildDetailRow('Alamat', customer.alamat),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Tarif / Daya',
                    '${customer.tariff} / ${customer.powerCapacity.toStringAsFixed(0)} VA',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Statistics Section
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 13,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'vs Bulan Lalu',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(monthIcon, size: 16, color: monthColor),
                            const SizedBox(width: 4),
                            Text(
                              monthCompare,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: monthColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.show_chart,
                              size: 13,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'vs Avg 3 Bulan',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 16,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              threeMonthAvg,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 11)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 11))),
      ],
    );
  }

  Widget _buildToggleButtons() {
    final allowWbpKvarh = _allowWbpKvarh;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Series untuk Ditampilkan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('LWBP'),
              selected: showLWBP,
              onSelected: (value) => setState(() => showLWBP = value),
              backgroundColor: Colors.grey.shade200,
              selectedColor: Colors.blue.shade200,
              labelStyle: const TextStyle(fontSize: 11),
            ),
            if (allowWbpKvarh)
              FilterChip(
                label: const Text('WBP'),
                selected: showWBP,
                onSelected: (value) => setState(() => showWBP = value),
                backgroundColor: Colors.grey.shade200,
                selectedColor: Colors.green.shade200,
                labelStyle: const TextStyle(fontSize: 11),
              ),
            if (allowWbpKvarh)
              FilterChip(
                label: const Text('KVARH'),
                selected: showKVARH,
                onSelected: (value) => setState(() => showKVARH = value),
                backgroundColor: Colors.grey.shade200,
                selectedColor: Colors.orange.shade200,
                labelStyle: const TextStyle(fontSize: 11),
              ),
            FilterChip(
              label: const Text('RPTAG'),
              selected: showRPTAG,
              onSelected: (value) => setState(() => showRPTAG = value),
              backgroundColor: Colors.grey.shade200,
              selectedColor: Colors.teal.shade200,
              labelStyle: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        if (!allowWbpKvarh) ...[
          const SizedBox(height: 8),
          Text(
            'WBP dan KVARH hanya tampil untuk tarif I2/I3 atau daya > 200000 VA.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  Widget _buildChart(List<BillingRecord> records) {
    final allowWbpKvarh = _allowWbpKvarh;
    final effectiveShowWBP = allowWbpKvarh && showWBP;
    final effectiveShowKVARH = allowWbpKvarh && showKVARH;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return SizedBox(
          height: 300,
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
                      String formattedPeriod = period;
                      try {
                        final parts = period.split('/');
                        if (parts.length == 2) {
                          final month = int.parse(parts[0]);
                          final year = parts[1].substring(2); // Last 2 digits
                          const monthNames = [
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
                          formattedPeriod = "${monthNames[month - 1]}'$year";
                        }
                      } catch (e) {
                        // Keep original format if parsing fails
                      }

                      if (isMobile) {
                        // Angled label for mobile/portrait
                        return Transform.translate(
                          offset: const Offset(0, 8),
                          child: Transform.rotate(
                            angle: -0.7854, // -45 degrees in radians
                            child: Text(
                              formattedPeriod,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      } else {
                        // Angled label for desktop/landscape
                        return Transform.translate(
                          offset: const Offset(0, 8),
                          child: Transform.rotate(
                            angle: -0.7854, // -45 degrees in radians
                            child: Text(
                              formattedPeriod,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    interval: safeHorizontalInterval.toDouble(),
                    getTitlesWidget: (value, meta) {
                      final formatter = NumberFormat('#,##0', 'id_ID');
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          formatter.format(value.toInt()),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
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

                      // Calculate the actual bar index based on which series are visible
                      int currentBarIndex = 0;

                      if (showLWBP) {
                        if (spot.barIndex == currentBarIndex) {
                          seriesName = 'LWBP';
                          unit = 'kWh';
                        }
                        currentBarIndex++;
                      }

                      if (effectiveShowWBP) {
                        if (spot.barIndex == currentBarIndex) {
                          seriesName = 'WBP';
                          unit = 'kWh';
                        }
                        currentBarIndex++;
                      }

                      if (effectiveShowKVARH) {
                        if (spot.barIndex == currentBarIndex) {
                          seriesName = 'KVARH';
                          unit = 'kVARh';
                        }
                        currentBarIndex++;
                      }

                      if (showRPTAG) {
                        if (spot.barIndex == currentBarIndex) {
                          seriesName = 'RPTAG';
                          unit = 'Rp';
                        }
                      }

                      final value = unit == 'Rp'
                          ? formatter.format(spot.y.toInt())
                          : formatter.format(spot.y.toInt());

                      rows.add({
                        'name': seriesName,
                        'value': value,
                        'unit': unit,
                      });
                    }

                    // Build table layout
                    final colWidth = 8;
                    String tableContent = 'Periode: ${record.billingPeriod}\n';
                    tableContent += '━━━━━━━━━━━━━━━━━━━━━━\n';

                    for (var row in rows) {
                      final name = (row['name'] as String).padRight(colWidth);
                      final unit = row['unit'] as String;
                      final value = unit == 'Rp'
                          ? 'Rp ${row['value']}'
                          : '${row['value']} $unit';
                      tableContent += '$name : $value\n';
                    }

                    return List.generate(
                      touchedSpots.length,
                      (index) => index == 0
                          ? LineTooltipItem(
                              tableContent.trim(),
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                                height: 1.5,
                                fontFamily: 'monospace',
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
                if (effectiveShowWBP)
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
                if (effectiveShowKVARH)
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
                    color: Colors.teal,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: records.length <= 12,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.teal,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.teal.withValues(alpha: 0.3),
                          Colors.teal.withValues(alpha: 0.05),
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
      },
    );
  }

  Widget _buildStandMeterTable(List<BillingRecord> records) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    final displayRecords = records.take(12).toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tabel Stand kWh Meter (12 Bulan Terakhir)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.swipe, size: 13, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'Geser ke kanan untuk melihat semua data',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                dataRowMinHeight: 32,
                dataRowMaxHeight: 40,
                columnSpacing: 10,
                horizontalMargin: 10,
                columns: [
                  const DataColumn(
                    label: SizedBox(
                      width: 80,
                      child: Text(
                        'Series',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  ...displayRecords.map(
                    (record) => DataColumn(
                      label: SizedBox(
                        width: 70,
                        child: Text(
                          record.billingPeriod,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      numeric: true,
                    ),
                  ),
                ],
                rows: [
                  DataRow(
                    cells: [
                      const DataCell(
                        Text(
                          'LWBP (kWh)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ...displayRecords.asMap().entries.map((entry) {
                        final index = entry.key;
                        final record = entry.value;
                        final currentValue = record.offPeakStand;

                        // Check if stand decreased from previous month (older data at higher index)
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
                              fontSize: 10,
                              color: isDecreased ? Colors.red : Colors.black,
                              fontWeight: isDecreased
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  DataRow(
                    cells: [
                      const DataCell(
                        Text(
                          'WBP (kWh)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ...displayRecords.asMap().entries.map((entry) {
                        final index = entry.key;
                        final record = entry.value;
                        final currentValue = record.peakStand;

                        // Check if stand decreased from previous month (older data at higher index)
                        bool isDecreased = false;
                        if (index < displayRecords.length - 1) {
                          final prevValue = displayRecords[index + 1].peakStand;
                          isDecreased = currentValue < prevValue;
                        }

                        return DataCell(
                          Text(
                            formatter.format(currentValue.toInt()),
                            style: TextStyle(
                              fontSize: 10,
                              color: isDecreased ? Colors.red : Colors.black,
                              fontWeight: isDecreased
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  DataRow(
                    cells: [
                      const DataCell(
                        Text(
                          'KVARH',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ...displayRecords.asMap().entries.map((entry) {
                        final index = entry.key;
                        final record = entry.value;
                        final currentValue = record.kvarhConsumption;

                        // Check if stand decreased from previous month (older data at higher index)
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
                              fontSize: 10,
                              color: isDecreased ? Colors.red : Colors.black,
                              fontWeight: isDecreased
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  DataRow(
                    cells: [
                      const DataCell(
                        Text(
                          'RPTAG (Rp)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ...displayRecords.map(
                        (record) => DataCell(
                          Text(
                            formatter.format(record.rptag.toInt()),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
