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
  String? _selectedPeriod; // null = Semua periode

  @override
  void dispose() {
    _customerIdController.dispose();
    super.dispose();
  }

  // Get unique billing periods from anomalies
  List<String> _getUniquePeriods(List<Map<String, dynamic>> anomalies) {
    final periods = anomalies
        .map((a) => a['billing_period'] as String?)
        .where((p) => p != null && p.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    periods.sort((a, b) => b.compareTo(a)); // Descending (newest first)
    return periods;
  }

  // Format period string for display (e.g., "202601" -> "Januari 2026")
  String _formatPeriod(String period) {
    if (period.length != 6) return period;
    try {
      final year = period.substring(0, 4);
      final month = int.parse(period.substring(4, 6));
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
      return '${monthNames[month - 1]} $year';
    } catch (e) {
      return period;
    }
  }

  void _addCustomerId() {
    final input = _customerIdController.text.trim();
    if (input.isEmpty) return;

    // Check if input contains multiple IDs (separated by comma, semicolon, newline, tab, space, or pipe)
    final List<String> newIds = input
        .split(RegExp(r'[,;\n\t\s|]+'))
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 16,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 1200 : constraints.maxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with Gradient
                    Container(
                      padding: EdgeInsets.all(isWide ? 24 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.cyan.shade600, Colors.teal.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.shade200.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.analytics_rounded,
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
                                      'Pengecekan DLPD',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _customerIds.isEmpty
                                          ? 'Masukkan ID pelanggan untuk memulai'
                                          : '${_customerIds.length} pelanggan ditambahkan',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_customerIds.isNotEmpty) ...[
                                // Period Dropdown
                                Consumer(
                                  builder: (context, ref, child) {
                                    final anomaliesAsync = ref.watch(
                                      anomaliesProvider,
                                    );
                                    return anomaliesAsync.maybeWhen(
                                      data: (anomalies) {
                                        // Filter anomalies for current customer IDs
                                        final relevantAnomalies = anomalies
                                            .where(
                                              (a) => _customerIds.contains(
                                                a['customer_id'],
                                              ),
                                            )
                                            .toList();
                                        final periods = _getUniquePeriods(
                                          relevantAnomalies,
                                        );
                                        if (periods.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.1,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String?>(
                                              value: _selectedPeriod,
                                              icon: Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                color: Colors.teal.shade600,
                                                size: 20,
                                              ),
                                              isDense: true,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.teal.shade700,
                                              ),
                                              items: [
                                                const DropdownMenuItem<String?>(
                                                  value: null,
                                                  child: Text('Semua Periode'),
                                                ),
                                                ...periods.map(
                                                  (period) =>
                                                      DropdownMenuItem<String>(
                                                        value: period,
                                                        child: Text(
                                                          _formatPeriod(period),
                                                        ),
                                                      ),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedPeriod = value;
                                                });
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                      orElse: () => const SizedBox.shrink(),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.people_rounded,
                                        color: Colors.teal.shade700,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_customerIds.length}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Input Field inside header
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _customerIdController,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Masukkan ID Pelanggan (pisahkan dengan koma, spasi, atau enter)',
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 14,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.person_search_rounded,
                                        color: Colors.teal.shade400,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                    ),
                                    onSubmitted: (_) => _addCustomerId(),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ElevatedButton(
                                    onPressed: _addCustomerId,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add, size: 18),
                                        SizedBox(width: 6),
                                        Text('Tambah'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Customer IDs chips inside header
                          if (_customerIds.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'ID Pelanggan yang akan dicek',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: _clearAll,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade400,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.clear_all,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Hapus Semua',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: 100,
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
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  id,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.teal.shade700,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                InkWell(
                                                  onTap: () =>
                                                      _removeCustomerId(id),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Icon(
                                                    Icons.close,
                                                    size: 14,
                                                    color: Colors.red.shade400,
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
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Results section
                    if (_customerIds.isEmpty)
                      _buildEmptyState()
                    else
                      ..._customerIds.map(
                        (customerId) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _CustomerDlpdCard(
                            customerId: customerId,
                            selectedPeriod: _selectedPeriod,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search_rounded,
                size: 48,
                color: Colors.teal.shade300,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum ada ID pelanggan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Masukkan ID pelanggan di atas untuk memulai\npengecekan DLPD (Daftar Langganan Pemakaian Daya)',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerDlpdCard extends ConsumerStatefulWidget {
  final String customerId;
  final String? selectedPeriod;

  const _CustomerDlpdCard({required this.customerId, this.selectedPeriod});

  @override
  ConsumerState<_CustomerDlpdCard> createState() => _CustomerDlpdCardState();
}

class _CustomerDlpdCardState extends ConsumerState<_CustomerDlpdCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerByIdProvider(widget.customerId));
    final anomaliesAsync = ref.watch(anomaliesProvider);

    return customerAsync.when(
      data: (customer) {
        if (customer == null) {
          return _buildNotFoundCard();
        }

        // Get anomalies for this customer (filtered by period if selected)
        final customerAnomalies = anomaliesAsync.maybeWhen(
          data: (anomalies) {
            var filtered = anomalies.where(
              (a) => a['customer_id'] == widget.customerId,
            );
            // Apply period filter if selected
            if (widget.selectedPeriod != null) {
              filtered = filtered.where(
                (a) => a['billing_period'] == widget.selectedPeriod,
              );
            }
            return filtered.toList();
          },
          orElse: () => <Map<String, dynamic>>[],
        );

        final hasAnomalies = customerAnomalies.isNotEmpty;
        final anomalyCount = customerAnomalies.length;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: hasAnomalies
                  ? Colors.orange.shade300
                  : Colors.grey.shade200,
              width: hasAnomalies ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Header - Clickable
              InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Avatar with tariff
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: hasAnomalies
                                ? [
                                    Colors.orange.shade400,
                                    Colors.orange.shade600,
                                  ]
                                : [Colors.teal.shade400, Colors.teal.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            customer.tariff.isNotEmpty
                                ? customer.tariff
                                : customer.nama.isNotEmpty
                                ? customer.nama.substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Customer ID + Name
                            Row(
                              children: [
                                Text(
                                  widget.customerId,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    customer.nama,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Tariff / Daya badges
                            Row(
                              children: [
                                if (customer.tariff.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      customer.tariff,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                if (customer.powerCapacity > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${NumberFormat('#,###', 'id_ID').format(customer.powerCapacity)} VA',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                // Anomaly badge
                                if (hasAnomalies) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          size: 10,
                                          color: Colors.orange.shade700,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$anomalyCount Anomali',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            // Show anomaly descriptions if any
                            if (hasAnomalies && !_isExpanded) ...[
                              const SizedBox(height: 6),
                              ...customerAnomalies.take(2).map((anomaly) {
                                final description =
                                    anomaly['description'] as String? ?? '';
                                final billingPeriod =
                                    anomaly['billing_period'] as String? ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month_outlined,
                                        size: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        billingPeriod,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          description,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              if (anomalyCount > 2)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '+${anomalyCount - 2} anomali lainnya',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey.shade400,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              // Content - Collapsible
              if (_isExpanded)
                _buildExpandedContent(customer, customerAnomalies),
            ],
          ),
        );
      },
      loading: () => _buildLoadingCard(),
      error: (error, stack) => _buildErrorCard(error),
    );
  }

  Widget _buildNotFoundCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.person_off_outlined,
                color: Colors.red.shade400,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.customerId,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pelanggan tidak ditemukan',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
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

  Widget _buildLoadingCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customerId,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Memuat data...',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(Object error) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade400,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.customerId,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Error: $error',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(
    Customer customer,
    List<Map<String, dynamic>> anomalies,
  ) {
    final recordsAsync = ref.watch(billingRecordsProvider(widget.customerId));

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Anomaly list if any
          if (anomalies.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Anomali Terdeteksi (${anomalies.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...anomalies.map((anomaly) {
                    final description = anomaly['description'] as String? ?? '';
                    final billingPeriod =
                        anomaly['billing_period'] as String? ?? '';
                    final type = anomaly['type'] as String? ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              billingPeriod,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // DLPD Analysis Content
          recordsAsync.when(
            data: (records) {
              if (records.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.timeline_outlined,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada data pemakaian',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return _DlpdAnalysisContent(records: records, customer: customer);
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error: $error',
                style: TextStyle(color: Colors.red.shade600, fontSize: 12),
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

    // Calculate kWh statistics
    String kwhMonthCompare = '-';
    String kwhThreeMonthAvg = '-';
    Color kwhMonthColor = Colors.grey;
    IconData kwhMonthIcon = Icons.remove;
    Color kwhAvgColor = Colors.blue.shade700;
    IconData kwhAvgIcon = Icons.analytics_outlined;

    // Calculate RPTAG statistics
    String rptagMonthCompare = '-';
    String rptagThreeMonthAvg = '-';
    Color rptagMonthColor = Colors.grey;
    IconData rptagMonthIcon = Icons.remove;
    Color rptagAvgColor = Colors.blue.shade700;
    IconData rptagAvgIcon = Icons.analytics_outlined;

    if (sortedRecords.length >= 2) {
      // kWh comparison
      final latestKwh =
          sortedRecords[0].offPeakConsumption +
          sortedRecords[0].peakConsumption;
      final previousKwh =
          sortedRecords[1].offPeakConsumption +
          sortedRecords[1].peakConsumption;

      if (previousKwh > 0) {
        final percentChange = ((latestKwh - previousKwh) / previousKwh) * 100;
        kwhMonthCompare =
            '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%';
        kwhMonthColor = percentChange >= 0
            ? Colors.red.shade600
            : Colors.green.shade600;
        kwhMonthIcon = percentChange >= 0
            ? Icons.trending_up
            : Icons.trending_down;
      }

      // RPTAG comparison
      final latestRptag = sortedRecords[0].rptag;
      final previousRptag = sortedRecords[1].rptag;

      if (previousRptag > 0) {
        final percentChange =
            ((latestRptag - previousRptag) / previousRptag) * 100;
        rptagMonthCompare =
            '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%';
        rptagMonthColor = percentChange >= 0
            ? Colors.red.shade600
            : Colors.green.shade600;
        rptagMonthIcon = percentChange >= 0
            ? Icons.trending_up
            : Icons.trending_down;
      }
    }

    if (sortedRecords.length >= 4) {
      // kWh 3-month average
      final latestKwh =
          sortedRecords[0].offPeakConsumption +
          sortedRecords[0].peakConsumption;
      final avg3MonthKwh =
          (sortedRecords[1].offPeakConsumption +
              sortedRecords[1].peakConsumption +
              sortedRecords[2].offPeakConsumption +
              sortedRecords[2].peakConsumption +
              sortedRecords[3].offPeakConsumption +
              sortedRecords[3].peakConsumption) /
          3;

      if (avg3MonthKwh > 0) {
        final percentChange = ((latestKwh - avg3MonthKwh) / avg3MonthKwh) * 100;
        kwhThreeMonthAvg =
            '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%';
        kwhAvgColor = percentChange >= 0
            ? Colors.red.shade600
            : Colors.green.shade600;
        kwhAvgIcon = percentChange >= 0
            ? Icons.trending_up
            : Icons.trending_down;
      }

      // RPTAG 3-month average
      final latestRptag = sortedRecords[0].rptag;
      final avg3MonthRptag =
          (sortedRecords[1].rptag +
              sortedRecords[2].rptag +
              sortedRecords[3].rptag) /
          3;

      if (avg3MonthRptag > 0) {
        final percentChange =
            ((latestRptag - avg3MonthRptag) / avg3MonthRptag) * 100;
        rptagThreeMonthAvg =
            '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%';
        rptagAvgColor = percentChange >= 0
            ? Colors.red.shade600
            : Colors.green.shade600;
        rptagAvgIcon = percentChange >= 0
            ? Icons.trending_up
            : Icons.trending_down;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;

          if (isNarrow) {
            // Portrait/Mobile: Stack vertically
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Detail Pelanggan Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DETAIL PELANGGAN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
                const SizedBox(height: 16),
                const Divider(thickness: 1, height: 1),
                const SizedBox(height: 16),
                // Statistics Section - kWh and RPTAG
                _buildStatisticsSection(
                  kwhMonthIcon: kwhMonthIcon,
                  kwhMonthColor: kwhMonthColor,
                  kwhMonthCompare: kwhMonthCompare,
                  rptagMonthIcon: rptagMonthIcon,
                  rptagMonthColor: rptagMonthColor,
                  rptagMonthCompare: rptagMonthCompare,
                  kwhAvgIcon: kwhAvgIcon,
                  kwhAvgColor: kwhAvgColor,
                  kwhThreeMonthAvg: kwhThreeMonthAvg,
                  rptagAvgIcon: rptagAvgIcon,
                  rptagAvgColor: rptagAvgColor,
                  rptagThreeMonthAvg: rptagThreeMonthAvg,
                ),
              ],
            );
          }

          // Landscape/Wide: Side by side
          return IntrinsicHeight(
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
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
                // Statistics Section - kWh and RPTAG
                Expanded(
                  flex: 2,
                  child: _buildStatisticsSection(
                    kwhMonthIcon: kwhMonthIcon,
                    kwhMonthColor: kwhMonthColor,
                    kwhMonthCompare: kwhMonthCompare,
                    rptagMonthIcon: rptagMonthIcon,
                    rptagMonthColor: rptagMonthColor,
                    rptagMonthCompare: rptagMonthCompare,
                    kwhAvgIcon: kwhAvgIcon,
                    kwhAvgColor: kwhAvgColor,
                    kwhThreeMonthAvg: kwhThreeMonthAvg,
                    rptagAvgIcon: rptagAvgIcon,
                    rptagAvgColor: rptagAvgColor,
                    rptagThreeMonthAvg: rptagThreeMonthAvg,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsSection({
    required IconData kwhMonthIcon,
    required Color kwhMonthColor,
    required String kwhMonthCompare,
    required IconData rptagMonthIcon,
    required Color rptagMonthColor,
    required String rptagMonthCompare,
    required IconData kwhAvgIcon,
    required Color kwhAvgColor,
    required String kwhThreeMonthAvg,
    required IconData rptagAvgIcon,
    required Color rptagAvgColor,
    required String rptagThreeMonthAvg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // vs Bulan Lalu - kWh and RPTAG
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
              const SizedBox(height: 8),
              Row(
                children: [
                  // kWh comparison
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'kWh',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  kwhMonthIcon,
                                  size: 14,
                                  color: kwhMonthColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  kwhMonthCompare,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: kwhMonthColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // RPTAG comparison
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RPTAG',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  rptagMonthIcon,
                                  size: 14,
                                  color: rptagMonthColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  rptagMonthCompare,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: rptagMonthColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // vs Avg 3 Bulan - kWh and RPTAG
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
                  Icon(Icons.show_chart, size: 13, color: Colors.grey.shade600),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  // kWh comparison
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'kWh',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(kwhAvgIcon, size: 14, color: kwhAvgColor),
                                const SizedBox(width: 3),
                                Text(
                                  kwhThreeMonthAvg,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: kwhAvgColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // RPTAG comparison
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RPTAG',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  rptagAvgIcon,
                                  size: 14,
                                  color: rptagAvgColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  rptagThreeMonthAvg,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: rptagAvgColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
