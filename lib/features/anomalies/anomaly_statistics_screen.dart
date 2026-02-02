import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/models/anomaly_flag.dart';
import '../../shared/models/billing_record.dart';
import '../../shared/models/customer.dart';
import '../../shared/utils/anomaly_utils.dart';

class AnomalyStatisticsScreen extends ConsumerStatefulWidget {
  const AnomalyStatisticsScreen({super.key});

  @override
  ConsumerState<AnomalyStatisticsScreen> createState() =>
      _AnomalyStatisticsScreenState();
}

class _AnomalyStatisticsScreenState
    extends ConsumerState<AnomalyStatisticsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  AnomalyType? _selectedType;
  String? _selectedPeriod; // null = Semua periode

  @override
  void dispose() {
    _searchController.dispose();
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

  List<Map<String, dynamic>> _filterAnomalies(
    List<Map<String, dynamic>> anomalies,
  ) {
    return anomalies.where((anomaly) {
      // Period filter
      if (_selectedPeriod != null) {
        final billingPeriod = anomaly['billing_period'] as String? ?? '';
        if (billingPeriod != _selectedPeriod) {
          return false;
        }
      }

      // Search filter
      final customerName = anomaly['customer_name'] as String? ?? '';
      final customerId = anomaly['customer_id'] as String? ?? '';
      final description = anomaly['description'] as String? ?? '';

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!customerName.toLowerCase().contains(query) &&
            !customerId.toLowerCase().contains(query) &&
            !description.toLowerCase().contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return ref
              .watch(anomaliesProvider)
              .when(
                data: (anomalies) {
                  final filteredAnomalies = _filterAnomalies(anomalies);

                  if (anomalies.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle_outline,
                              size: 64,
                              color: Colors.green.shade400,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Tidak ada anomali terdeteksi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Semua data billing dalam kondisi normal',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

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
                            // Header with Gradient - Consistent with Data Pelanggan
                            Container(
                              padding: EdgeInsets.all(isWide ? 24 : 20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.shade600,
                                    Colors.orange.shade700,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.shade200.withValues(
                                      alpha: 0.5,
                                    ),
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
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Deteksi Anomali',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${anomalies.length} anomali terdeteksi',
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
                                      // Period Dropdown
                                      Builder(
                                        builder: (context) {
                                          final periods = _getUniquePeriods(
                                            anomalies,
                                          );
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.1),
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
                                                  color: Colors.orange.shade600,
                                                  size: 20,
                                                ),
                                                isDense: true,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.orange.shade700,
                                                ),
                                                items: [
                                                  const DropdownMenuItem<
                                                    String?
                                                  >(
                                                    value: null,
                                                    child: Text(
                                                      'Semua Periode',
                                                    ),
                                                  ),
                                                  ...periods.map(
                                                    (period) =>
                                                        DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: period,
                                                          child: Text(
                                                            _formatPeriod(
                                                              period,
                                                            ),
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
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  // Search Bar - Inside Header
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        hintText:
                                            'Cari pelanggan, ID, atau deskripsi anomali...',
                                        hintStyle: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 14,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search,
                                          color: Colors.orange.shade400,
                                        ),
                                        suffixIcon: _searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: Icon(
                                                  Icons.clear,
                                                  color: Colors.grey.shade500,
                                                ),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() {
                                                    _searchQuery = '';
                                                  });
                                                },
                                              )
                                            : null,
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _searchQuery = value;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Summary cards
                            if (filteredAnomalies.isNotEmpty) ...[
                              // Type count cards in grid
                              _AnomalyTypeCountCards(
                                anomalies: filteredAnomalies,
                                selectedType: _selectedType,
                                onTypeSelected: (type) {
                                  setState(() {
                                    _selectedType = type;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),

                              // Type-based detailed breakdown
                              if (_selectedType != null)
                                _AnomalyTypeBreakdownTabbed(
                                  anomalies: filteredAnomalies,
                                  selectedType: _selectedType!,
                                ),
                              const SizedBox(height: 24),
                            ] else
                              _buildEmptyFilterState(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              );
        },
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tidak ada anomali yang sesuai dengan filter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba ubah kata kunci pencarian',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnomalyTypeCountCards extends ConsumerWidget {
  final List<Map<String, dynamic>> anomalies;
  final AnomalyType? selectedType;
  final Function(AnomalyType) onTypeSelected;

  const _AnomalyTypeCountCards({
    required this.anomalies,
    required this.selectedType,
    required this.onTypeSelected,
  });

  // Helper to intersperse widgets with separator
  List<Widget> _intersperse(List<Widget> widgets, Widget separator) {
    if (widgets.isEmpty) return [];
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(separator);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Group by customer_id per type to count unique customers per anomaly type
    final typeCustomerMap = <String, Set<String>>{};
    for (final anomaly in anomalies) {
      final type = anomaly['type'] as String? ?? 'unknown';
      final customerId = anomaly['customer_id'] as String? ?? '';
      typeCustomerMap.putIfAbsent(type, () => <String>{});
      typeCustomerMap[type]!.add(customerId);
    }

    // Count unique customers per type
    final typeMap = <String, int>{};
    for (final entry in typeCustomerMap.entries) {
      typeMap[entry.key] = entry.value.length;
    }

    // Calculate total unique customers (not total anomalies)
    final allCustomers = <String>{};
    for (final anomaly in anomalies) {
      final customerId = anomaly['customer_id'] as String? ?? '';
      allCustomers.add(customerId);
    }
    final totalUniqueCustomers = allCustomers.length;

    // Get all types in custom order
    final allTypes = [
      AnomalyType.consumptionSpike,
      AnomalyType.consumptionDecrease,
      AnomalyType.excessiveHours,
      AnomalyType.standMundur,
      AnomalyType.zeroConsumption,
    ];

    // Get operating hours threshold
    final thresholdAsync = ref.watch(operatingHoursThresholdProvider);
    final threshold = thresholdAsync.maybeWhen(
      data: (value) => value,
      orElse: () => 720.0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        final cards = allTypes.map((type) {
          final count = typeMap[type.name] ?? 0;
          final percentage = totalUniqueCustomers == 0
              ? 0.0
              : (count / totalUniqueCustomers) * 100;

          return Expanded(
            child: _AnomalyTypeSimpleCard(
              type: type,
              count: count,
              percentage: percentage,
              isSelected: selectedType == type,
              onTap: () => onTypeSelected(type),
              threshold: type == AnomalyType.excessiveHours ? threshold : null,
            ),
          );
        }).toList();

        if (isWide) {
          // Wide screen: single row
          return Row(
            children: _intersperse(cards, const SizedBox(width: 12)).toList(),
          );
        } else {
          // Narrow screen: 2 rows
          final half = (cards.length / 2).ceil();
          return Column(
            children: [
              Row(
                children: _intersperse(
                  cards.take(half).toList(),
                  const SizedBox(width: 12),
                ).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: _intersperse(
                  cards.skip(half).toList(),
                  const SizedBox(width: 12),
                ).toList(),
              ),
            ],
          );
        }
      },
    );
  }
}

// Simple stat card similar to customer data design
class _AnomalyTypeSimpleCard extends StatelessWidget {
  final AnomalyType type;
  final int count;
  final double percentage;
  final bool isSelected;
  final VoidCallback onTap;
  final double? threshold;

  const _AnomalyTypeSimpleCard({
    required this.type,
    required this.count,
    required this.percentage,
    required this.isSelected,
    required this.onTap,
    this.threshold,
  });

  Color _getTypeColor() {
    switch (type) {
      case AnomalyType.standMundur:
        return Colors.teal;
      case AnomalyType.excessiveHours:
        return Colors.orange;
      case AnomalyType.consumptionSpike:
        return Colors.deepOrange; // Lonjakan konsumsi - bahaya tinggi
      case AnomalyType.consumptionDecrease:
        return Colors.blue; // Penurunan konsumsi - informasi
      case AnomalyType.zeroConsumption:
        return Colors.grey; // Konsumsi nol - netral
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = AnomalyUtils.getTypeIcon(type);
    final typeName = AnomalyUtils.getTypeName(type);
    final color = _getTypeColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const Spacer(),
                if (threshold != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Text(
                      '>${threshold!.toStringAsFixed(0)}j',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              typeName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnomalyTypeBreakdownTabbed extends StatefulWidget {
  final List<Map<String, dynamic>> anomalies;
  final AnomalyType selectedType;

  const _AnomalyTypeBreakdownTabbed({
    required this.anomalies,
    required this.selectedType,
  });

  @override
  State<_AnomalyTypeBreakdownTabbed> createState() =>
      _AnomalyTypeBreakdownTabbedState();
}

class _AnomalyTypeBreakdownTabbedState
    extends State<_AnomalyTypeBreakdownTabbed> {
  String _sortBy = 'customer'; // 'customer', 'period', 'value'
  bool _sortAscending = true;
  int _currentPage = 0;
  int _itemsPerPage = 5;

  @override
  void didUpdateWidget(covariant _AnomalyTypeBreakdownTabbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset page when type changes
    if (oldWidget.selectedType != widget.selectedType) {
      setState(() {
        _currentPage = 0;
      });
    }
  }

  // Extract numeric value from description
  double _extractValue(Map<String, dynamic> anomaly) {
    final description = anomaly['description'] as String? ?? '';
    // Extract first number from description (handles decimals)
    final match = RegExp(r'\d+\.?\d*').firstMatch(description);
    if (match != null) {
      return double.tryParse(match.group(0)!) ?? 0.0;
    }
    return 0.0;
  }

  // Build sort control widgets (reusable for both layouts)
  List<Widget> _buildSortControls() {
    return [
      Icon(Icons.sort, size: 14, color: Colors.grey.shade700),
      const SizedBox(width: 6),
      Text(
        'Urutkan:',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(width: 8),
      ChoiceChip(
        label: const Text('Pelanggan'),
        selected: _sortBy == 'customer',
        onSelected: (selected) {
          if (selected) {
            setState(() {
              if (_sortBy == 'customer') {
                _sortAscending = !_sortAscending;
              } else {
                _sortBy = 'customer';
                _sortAscending = true;
              }
            });
          }
        },
        selectedColor: Colors.blue.shade100,
        labelStyle: TextStyle(
          fontSize: 10,
          color: _sortBy == 'customer'
              ? Colors.blue.shade700
              : Colors.grey.shade600,
          fontWeight: _sortBy == 'customer'
              ? FontWeight.w600
              : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        visualDensity: VisualDensity.compact,
      ),
      const SizedBox(width: 6),
      ChoiceChip(
        label: const Text('Periode'),
        selected: _sortBy == 'period',
        onSelected: (selected) {
          if (selected) {
            setState(() {
              if (_sortBy == 'period') {
                _sortAscending = !_sortAscending;
              } else {
                _sortBy = 'period';
                _sortAscending = true;
              }
            });
          }
        },
        selectedColor: Colors.blue.shade100,
        labelStyle: TextStyle(
          fontSize: 10,
          color: _sortBy == 'period'
              ? Colors.blue.shade700
              : Colors.grey.shade600,
          fontWeight: _sortBy == 'period' ? FontWeight.w600 : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        visualDensity: VisualDensity.compact,
      ),
      const SizedBox(width: 6),
      ChoiceChip(
        label: const Text('Nilai'),
        selected: _sortBy == 'value',
        onSelected: (selected) {
          if (selected) {
            setState(() {
              if (_sortBy == 'value') {
                _sortAscending = !_sortAscending;
              } else {
                _sortBy = 'value';
                _sortAscending = false; // Default descending untuk nilai
              }
            });
          }
        },
        selectedColor: Colors.blue.shade100,
        labelStyle: TextStyle(
          fontSize: 10,
          color: _sortBy == 'value'
              ? Colors.blue.shade700
              : Colors.grey.shade600,
          fontWeight: _sortBy == 'value' ? FontWeight.w600 : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        visualDensity: VisualDensity.compact,
      ),
      const SizedBox(width: 6),
      IconButton(
        icon: Icon(
          _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
          size: 14,
        ),
        onPressed: () {
          setState(() {
            _sortAscending = !_sortAscending;
          });
        },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        tooltip: _sortAscending ? 'A-Z' : 'Z-A',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final typeMap = <AnomalyType, List<Map<String, dynamic>>>{};

    // Group anomalies by type
    for (final anomaly in widget.anomalies) {
      final typeStr = anomaly['type'] as String? ?? '';
      final type = AnomalyType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => AnomalyType.standMundur,
      );

      if (!typeMap.containsKey(type)) {
        typeMap[type] = [];
      }
      typeMap[type]!.add(anomaly);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Content for selected type
        Builder(
          builder: (context) {
            var items = typeMap[widget.selectedType] ?? [];

            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 56,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada anomali untuk jenis ini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Sort items
            items = List.from(items);

            // Group by customer_id and keep only the latest period per customer
            final customerMap = <String, Map<String, dynamic>>{};
            for (final item in items) {
              final customerId = item['customer_id'] as String? ?? '';
              final existingItem = customerMap[customerId];

              if (existingItem == null) {
                customerMap[customerId] = item;
              } else {
                // Keep the one with latest billing period
                final existingPeriod =
                    existingItem['billing_period'] as String? ?? '';
                final currentPeriod = item['billing_period'] as String? ?? '';
                if (currentPeriod.compareTo(existingPeriod) > 0) {
                  customerMap[customerId] = item;
                }
              }
            }
            items = customerMap.values.toList();

            if (_sortBy == 'customer') {
              items.sort((a, b) {
                final nameA = (a['nama'] as String? ?? '').toLowerCase();
                final nameB = (b['nama'] as String? ?? '').toLowerCase();
                return _sortAscending
                    ? nameA.compareTo(nameB)
                    : nameB.compareTo(nameA);
              });
            } else if (_sortBy == 'period') {
              items.sort((a, b) {
                final periodA = a['billing_period'] as String? ?? '';
                final periodB = b['billing_period'] as String? ?? '';
                return _sortAscending
                    ? periodA.compareTo(periodB)
                    : periodB.compareTo(periodA);
              });
            } else if (_sortBy == 'value') {
              items.sort((a, b) {
                final valueA = _extractValue(a);
                final valueB = _extractValue(b);
                return _sortAscending
                    ? valueA.compareTo(valueB)
                    : valueB.compareTo(valueA);
              });
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and sort controls
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Check if we have enough space for horizontal layout
                        final isWideScreen = constraints.maxWidth > 600;

                        if (isWideScreen) {
                          // Wide screen: single row layout
                          return Row(
                            children: [
                              // Left side: Detail Analisis
                              Icon(
                                Icons.analytics_outlined,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Detail Analisis',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              // Right side: Sort controls
                              ..._buildSortControls(),
                            ],
                          );
                        } else {
                          // Narrow screen: stacked layout
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title row
                              Row(
                                children: [
                                  Icon(
                                    Icons.analytics_outlined,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Detail Analisis',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Sort controls row
                              Row(children: _buildSortControls()),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                  // Detail list with pagination
                  Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      // Calculate pagination
                      final totalItems = items.length;
                      final totalPages = _itemsPerPage == -1
                          ? 1
                          : (totalItems / _itemsPerPage).ceil();
                      final startIndex = _itemsPerPage == -1
                          ? 0
                          : _currentPage * _itemsPerPage;
                      final endIndex = _itemsPerPage == -1
                          ? totalItems
                          : (startIndex + _itemsPerPage).clamp(0, totalItems);
                      final paginatedItems = items.sublist(
                        startIndex,
                        endIndex,
                      );

                      return Column(
                        children: [
                          // List
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: paginatedItems.length,
                            separatorBuilder: (context, index) =>
                                Divider(color: Colors.grey.shade200),
                            itemBuilder: (context, index) {
                              final anomaly = paginatedItems[index];
                              final customerName =
                                  anomaly['nama'] as String? ?? 'Unknown';
                              final customerId =
                                  anomaly['customer_id'] as String? ?? '';
                              final description =
                                  anomaly['description'] as String? ?? '';
                              final billingPeriod =
                                  anomaly['billing_period'] as String? ?? '';
                              final tariff = anomaly['tarif'] as String? ?? '';
                              final daya = anomaly['daya'] as int? ?? 0;

                              // Get type color
                              Color typeColor;
                              switch (widget.selectedType) {
                                case AnomalyType.standMundur:
                                  typeColor = Colors.teal;
                                case AnomalyType.excessiveHours:
                                  typeColor = Colors.orange;
                                case AnomalyType.consumptionSpike:
                                  typeColor = Colors.deepOrange;
                                case AnomalyType.consumptionDecrease:
                                  typeColor = Colors.blue;
                                case AnomalyType.zeroConsumption:
                                  typeColor = Colors.grey;
                              }

                              return InkWell(
                                onTap: () {
                                  _showCustomerHistoryDialog(
                                    context,
                                    customerId,
                                    customerName,
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      // Avatar with tariff
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              typeColor.withValues(alpha: 0.8),
                                              typeColor,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            tariff.isNotEmpty
                                                ? tariff
                                                : (customerName.isNotEmpty
                                                      ? customerName
                                                            .substring(0, 1)
                                                            .toUpperCase()
                                                      : '?'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Customer ID + Customer Name
                                            Row(
                                              children: [
                                                Text(
                                                  customerId,
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
                                                    customerName,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            // Tariff / Daya VA
                                            Row(
                                              children: [
                                                if (tariff.isNotEmpty) ...[
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.blue.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      tariff,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .blue
                                                            .shade700,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                ],
                                                if (daya > 0) ...[
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.green.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '${NumberFormat('#,###', 'id_ID').format(daya)} VA',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .green
                                                            .shade700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            // Period + Description
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_month_outlined,
                                                  size: 11,
                                                  color: Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  billingPeriod,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    description,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: typeColor,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Arrow icon
                                      Icon(
                                        Icons.chevron_right,
                                        size: 20,
                                        color: Colors.grey.shade400,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          // Pagination Footer
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              border: Border(
                                top: BorderSide(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(16),
                              ),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 500;

                                if (isNarrow) {
                                  // Stack vertically on narrow screens
                                  return SizedBox(
                                    width: double.infinity,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Items per page selector
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Tampilkan:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _buildPageSizeButton(5, theme),
                                            const SizedBox(width: 4),
                                            _buildPageSizeButton(10, theme),
                                            const SizedBox(width: 4),
                                            _buildPageSizeButton(100, theme),
                                            const SizedBox(width: 4),
                                            _buildPageSizeButton(
                                              -1,
                                              theme,
                                              label: 'Semua',
                                            ),
                                          ],
                                        ),
                                        // Page info and navigation
                                        if (_itemsPerPage != -1 &&
                                            totalPages > 1) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '${startIndex + 1}-$endIndex dari $totalItems',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              _buildNavButton(
                                                icon: Icons.chevron_left,
                                                onPressed: _currentPage > 0
                                                    ? () => setState(
                                                        () => _currentPage--,
                                                      )
                                                    : null,
                                                theme: theme,
                                              ),
                                              const SizedBox(width: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${_currentPage + 1} / $totalPages',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              _buildNavButton(
                                                icon: Icons.chevron_right,
                                                onPressed:
                                                    _currentPage <
                                                        totalPages - 1
                                                    ? () => setState(
                                                        () => _currentPage++,
                                                      )
                                                    : null,
                                                theme: theme,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }

                                // Wide screen: horizontal layout
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Tampilkan:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildPageSizeButton(5, theme),
                                        const SizedBox(width: 4),
                                        _buildPageSizeButton(10, theme),
                                        const SizedBox(width: 4),
                                        _buildPageSizeButton(100, theme),
                                        const SizedBox(width: 4),
                                        _buildPageSizeButton(
                                          -1,
                                          theme,
                                          label: 'Semua',
                                        ),
                                      ],
                                    ),
                                    // Page info and navigation
                                    if (_itemsPerPage != -1 && totalPages > 1)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${startIndex + 1}-$endIndex dari $totalItems',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          _buildNavButton(
                                            icon: Icons.chevron_left,
                                            onPressed: _currentPage > 0
                                                ? () => setState(
                                                    () => _currentPage--,
                                                  )
                                                : null,
                                            theme: theme,
                                          ),
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${_currentPage + 1} / $totalPages',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          _buildNavButton(
                                            icon: Icons.chevron_right,
                                            onPressed:
                                                _currentPage < totalPages - 1
                                                ? () => setState(
                                                    () => _currentPage++,
                                                  )
                                                : null,
                                            theme: theme,
                                          ),
                                        ],
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPageSizeButton(int size, ThemeData theme, {String? label}) {
    final isSelected = _itemsPerPage == size;
    return InkWell(
      onTap: () {
        setState(() {
          _itemsPerPage = size;
          _currentPage = 0;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label ?? '$size',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required ThemeData theme,
  }) {
    final isEnabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isEnabled
              ? theme.colorScheme.surfaceContainerHighest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isEnabled
                ? theme.colorScheme.outlineVariant
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isEnabled
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  void _showCustomerHistoryDialog(
    BuildContext context,
    String customerId,
    String customerName,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
          child: Column(
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                        Icons.analytics_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID Pelanggan: $customerId',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Tutup',
                      ),
                    ),
                  ],
                ),
              ),
              // Content with subtle background
              Expanded(
                child: Container(
                  color: Colors.grey.shade50,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final customerAsync = ref.watch(
                        customerByIdProvider(customerId),
                      );

                      return customerAsync.when(
                        data: (customer) {
                          if (customer == null) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_off_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Pelanggan tidak ditemukan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final recordsAsync = ref.watch(
                            billingRecordsProvider(customerId),
                          );

                          return recordsAsync.when(
                            data: (records) {
                              if (records.isEmpty) {
                                return Center(
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
                                          Icons.timeline_outlined,
                                          size: 64,
                                          color: Colors.blue.shade300,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Belum Ada Riwayat Pemakaian',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Data pemakaian akan muncul setelah import data',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return _CustomerHistoryChart(
                                records: records,
                                customer: customer,
                              );
                            },
                            loading: () => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.blue.shade600,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Memuat data...',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            error: (error, stack) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.red.shade300,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Terjadi Kesalahan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    error.toString(),
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
                        loading: () => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Memuat pelanggan...',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        error: (error, stack) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Gagal memuat data pelanggan',
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
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerHistoryChart extends StatefulWidget {
  final List<BillingRecord> records;
  final Customer customer;

  const _CustomerHistoryChart({required this.records, required this.customer});

  @override
  State<_CustomerHistoryChart> createState() => _CustomerHistoryChartState();
}

class _CustomerHistoryChartState extends State<_CustomerHistoryChart> {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer details
          _buildCustomerDetails(),
          const SizedBox(height: 16),

          // Toggle buttons
          _buildToggleButtons(),
          const SizedBox(height: 24),

          // Chart
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildChart(sortedRecords),
            ),
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

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                          fontSize: 20,
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
                  _buildAnomalyStatisticsSection(
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
                            fontSize: 20,
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
                    child: _buildAnomalyStatisticsSection(
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
      ),
    );
  }

  Widget _buildAnomalyStatisticsSection({
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
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 12)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
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
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('LWBP (Off-Peak)'),
              selected: showLWBP,
              onSelected: (value) => setState(() => showLWBP = value),
              backgroundColor: Colors.grey.shade200,
              selectedColor: Colors.blue.shade200,
            ),
            if (allowWbpKvarh)
              FilterChip(
                label: const Text('WBP (Peak)'),
                selected: showWBP,
                onSelected: (value) => setState(() => showWBP = value),
                backgroundColor: Colors.grey.shade200,
                selectedColor: Colors.green.shade200,
              ),
            if (allowWbpKvarh)
              FilterChip(
                label: const Text('KVARH (Reactive)'),
                selected: showKVARH,
                onSelected: (value) => setState(() => showKVARH = value),
                backgroundColor: Colors.grey.shade200,
                selectedColor: Colors.orange.shade200,
              ),
            FilterChip(
              label: const Text('RPTAG (Rupiah Tagihan)'),
              selected: showRPTAG,
              onSelected: (value) => setState(() => showRPTAG = value),
              backgroundColor: Colors.grey.shade200,
              selectedColor: Colors.teal.shade200,
            ),
          ],
        ),
        if (!allowWbpKvarh) ...[
          const SizedBox(height: 8),
          Text(
            'WBP dan KVARH hanya tampil untuk tarif I2/I3 atau daya > 200000 VA.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                      color = Colors.teal.shade300;
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
  }

  Widget _buildStandMeterTable(List<BillingRecord> records) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    final displayRecords = records.take(12).toList().reversed.toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tabel Stand kWh Meter (12 Bulan Terakhir)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.swipe, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Geser ke kanan untuk melihat semua data',
                  style: TextStyle(
                    fontSize: 11,
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
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 48,
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  columns: [
                    const DataColumn(
                      label: SizedBox(
                        width: 90,
                        child: Text(
                          'Series',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    // Create columns for each period
                    ...displayRecords.map(
                      (record) => DataColumn(
                        label: SizedBox(
                          width: 75,
                          child: Text(
                            record.billingPeriod,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
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
                        const DataCell(
                          Text(
                            'LWBP (kWh)',
                            style: TextStyle(
                              fontSize: 11,
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
                                fontSize: 11,
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
                    // Row for WBP
                    DataRow(
                      cells: [
                        const DataCell(
                          Text(
                            'WBP (kWh)',
                            style: TextStyle(
                              fontSize: 11,
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
                            final prevValue =
                                displayRecords[index + 1].peakStand;
                            isDecreased = currentValue < prevValue;
                          }

                          return DataCell(
                            Text(
                              formatter.format(currentValue.toInt()),
                              style: TextStyle(
                                fontSize: 11,
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
                    // Row for KVARH
                    DataRow(
                      cells: [
                        const DataCell(
                          Text(
                            'KVARH',
                            style: TextStyle(
                              fontSize: 11,
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
                                fontSize: 11,
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
                    // Row for RPTAG
                    DataRow(
                      cells: [
                        const DataCell(
                          Text(
                            'RPTAG (Rp)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ...displayRecords.map(
                          (record) => DataCell(
                            Text(
                              formatter.format(record.rptag.toInt()),
                              style: const TextStyle(fontSize: 11),
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
      ),
    );
  }
}

// ignore: unused_element
class _AnomalyTypeDetailedBreakdown extends StatelessWidget {
  final List<Map<String, dynamic>> anomalies;

  const _AnomalyTypeDetailedBreakdown({required this.anomalies});

  @override
  Widget build(BuildContext context) {
    final typeMap = <AnomalyType, List<Map<String, dynamic>>>{};

    // Group anomalies by type
    for (final anomaly in anomalies) {
      final typeStr = anomaly['type'] as String? ?? '';
      final type = AnomalyType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => AnomalyType.standMundur,
      );

      if (!typeMap.containsKey(type)) {
        typeMap[type] = [];
      }
      typeMap[type]!.add(anomaly);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail per Jenis Anomali',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          ...AnomalyType.values.map((type) {
            final items = typeMap[type] ?? [];
            final criticalCount = items
                .where((a) => (a['severity'] as String?) == 'critical')
                .length;
            final mediumCount = items
                .where((a) => (a['severity'] as String?) == 'medium')
                .length;
            final lowCount = items
                .where((a) => (a['severity'] as String?) == 'low')
                .length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with type name and icon
                      Row(
                        children: [
                          Icon(
                            AnomalyUtils.getTypeIcon(type),
                            size: 20,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AnomalyUtils.getTypeName(type),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${items.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Severity breakdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _TypeSeverityBadge(
                            label: 'Kritis',
                            count: criticalCount,
                            color: const Color(0xFFD32F2F),
                          ),
                          _TypeSeverityBadge(
                            label: 'Sedang',
                            count: mediumCount,
                            color: const Color(0xFFF57C00),
                          ),
                          _TypeSeverityBadge(
                            label: 'Rendah',
                            count: lowCount,
                            color: const Color(0xFFFBC02D),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TypeSeverityBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _TypeSeverityBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _AnomaliesByTypeSection extends StatelessWidget {
  final List<Map<String, dynamic>> anomalies;

  const _AnomaliesByTypeSection({required this.anomalies});

  @override
  Widget build(BuildContext context) {
    final typeMap = <String, int>{};

    for (final anomaly in anomalies) {
      final type = anomaly['type'] as String? ?? 'unknown';
      typeMap[type] = (typeMap[type] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jenis Anomali',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: typeMap.entries.map((entry) {
                  final type = AnomalyType.values.firstWhere(
                    (e) => e.name == entry.key,
                    orElse: () => AnomalyType.standMundur,
                  );
                  final count = entry.value;
                  final percentage = ((count / anomalies.length) * 100)
                      .toStringAsFixed(1);

                  return Column(
                    children: [
                      if (typeMap.entries.toList().indexOf(entry) > 0)
                        const Divider(height: 12),
                      Row(
                        children: [
                          Icon(
                            AnomalyUtils.getTypeIcon(type),
                            size: 20,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AnomalyUtils.getTypeName(type),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$count ($percentage%)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _AnomaliesBySeveritySection extends StatelessWidget {
  final List<Map<String, dynamic>> anomalies;

  const _AnomaliesBySeveritySection({required this.anomalies});

  @override
  Widget build(BuildContext context) {
    final severityMap = <String, int>{};

    for (final anomaly in anomalies) {
      final severity = anomaly['severity'] as String? ?? 'medium';
      severityMap[severity] = (severityMap[severity] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori Keparahan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: severityMap.entries.map((entry) {
                  final severity = AnomalySeverity.values.firstWhere(
                    (e) => e.name == entry.key,
                    orElse: () => AnomalySeverity.medium,
                  );
                  final count = entry.value;
                  final percentage = ((count / anomalies.length) * 100)
                      .toStringAsFixed(1);
                  final color = AnomalyUtils.getSeverityColor(severity);

                  return Column(
                    children: [
                      if (severityMap.entries.toList().indexOf(entry) > 0)
                        const Divider(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AnomalyUtils.getSeverityName(severity),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$count ($percentage%)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
