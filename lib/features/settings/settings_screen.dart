import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/providers/app_providers.dart';
import '../import_excel/anomaly_detection_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _dbSize;
  String? _dbPath;
  bool _isLoading = false;
  double _operatingHoursThreshold = 720;
  double _consumptionVarianceThreshold = 35;
  String _anomalyDetectionMode = 'kwh';
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _varianceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDatabaseInfo();
    _loadSettings();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _varianceController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final db = DatabaseHelper.instance;
      final threshold = await db.getOperatingHoursThreshold();
      final varianceThreshold = await db.getConsumptionVarianceThreshold();
      final detectionMode = await db.getAnomalyDetectionMode();
      setState(() {
        _operatingHoursThreshold = threshold;
        _hoursController.text = threshold.toStringAsFixed(0);
        _consumptionVarianceThreshold = varianceThreshold;
        _varianceController.text = varianceThreshold.toStringAsFixed(0);
        _anomalyDetectionMode = detectionMode;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
      }
    }
  }

  Future<void> _loadDatabaseInfo() async {
    try {
      final db = DatabaseHelper.instance;
      final dbPath = await db.getDatabasePath();
      final file = File(dbPath);

      if (await file.exists()) {
        final size = await file.length();
        setState(() {
          _dbPath = dbPath;
          _dbSize = _formatBytes(size);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading database info: $e')),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _exportDatabase() async {
    if (_dbPath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Database path not found')));
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Pick directory for export
      final outputPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Pilih folder untuk export database',
      );

      if (outputPath == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Create backup filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFileName = 'billing_amr_backup_$timestamp.db';
      final backupPath = path.join(outputPath, backupFileName);

      // Copy database file
      final sourceFile = File(_dbPath!);
      await sourceFile.copy(backupPath);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database berhasil di-export ke:\n$backupPath'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting database: $e')));
      }
    }
  }

  Future<void> _importDatabase() async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi Import'),
          content: const Text(
            'Import database akan mengganti semua data yang ada. '
            'Pastikan Anda sudah melakukan backup terlebih dahulu.\n\n'
            'Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() => _isLoading = true);

      // Pick database file
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Pilih file database untuk di-import',
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final pickedFile = result.files.first;
      if (pickedFile.path == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Close database connection
      await DatabaseHelper.instance.close();

      // Copy the imported file to database location
      final importFile = File(pickedFile.path!);
      await importFile.copy(_dbPath!);

      // Reinitialize database
      await DatabaseHelper.instance.database;

      setState(() => _isLoading = false);
      await _loadDatabaseInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database berhasil di-import!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing database: $e')));
      }
    }
  }

  Future<void> _resetDatabase() async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text('Reset Database'),
            ],
          ),
          content: const Text(
            'PERINGATAN: Tindakan ini akan menghapus SEMUA data billing, '
            'pelanggan, riwayat import, dan data anomali.\n\n'
            'Tindakan ini TIDAK DAPAT dibatalkan!\n\n'
            'Pastikan Anda sudah melakukan backup terlebih dahulu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reset Database'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Check if still mounted before showing second dialog
      if (!mounted) return;

      // Second confirmation
      final doubleConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi Akhir'),
          content: const Text(
            'Ketik "RESET" untuk mengkonfirmasi penghapusan semua data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Konfirmasi Reset'),
            ),
          ],
        ),
      );

      if (doubleConfirmed != true) return;

      setState(() => _isLoading = true);

      // Reset database
      final db = DatabaseHelper.instance;
      await db.resetDatabase();

      // Invalidate providers
      ref.invalidate(customersProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(importHistoryProvider);
      ref.invalidate(anomaliesProvider);

      setState(() => _isLoading = false);
      await _loadDatabaseInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database berhasil di-reset!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error resetting database: $e')));
      }
    }
  }

  Future<void> _saveOperatingHoursThreshold() async {
    final value = double.tryParse(_hoursController.text);

    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nilai yang valid (lebih dari 0)'),
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final db = DatabaseHelper.instance;
      await db.updateOperatingHoursThreshold(value);

      setState(() {
        _operatingHoursThreshold = value;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan berhasil disimpan!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    }
  }

  Future<void> _saveConsumptionVarianceThreshold() async {
    final value = double.tryParse(_varianceController.text);

    if (value == null || value <= 0 || value > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nilai persentase yang valid (1-100)'),
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final db = DatabaseHelper.instance;
      await db.updateConsumptionVarianceThreshold(value);

      setState(() {
        _consumptionVarianceThreshold = value;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan berhasil disimpan!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    }
  }

  Future<void> _redetectAnomalies() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deteksi Ulang Anomali'),
        content: const Text(
          'Ini akan menghapus semua data anomali yang ada dan mendeteksi ulang menggunakan threshold baru. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isLoading = true);

      // Import anomaly detection service
      final anomalyService = AnomalyDetectionService(); // Need to import this
      final count = await anomalyService.detectAnomalies();

      // Invalidate providers to refresh data
      ref.invalidate(anomaliesProvider);
      ref.invalidate(dashboardSummaryProvider);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deteksi selesai! Ditemukan $count anomali')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
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
                        maxWidth: isWide ? 900 : constraints.maxWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Gradient Header - Consistent with other screens
                          _buildGradientHeader(theme),
                          const SizedBox(height: 24),

                          // Anomaly Detection Settings Section
                          _buildSectionTitle(
                            context,
                            icon: Icons.tune_rounded,
                            title: 'Konfigurasi Deteksi Anomali',
                            color: Colors.indigo,
                          ),
                          const SizedBox(height: 12),

                          // Detection Mode Card
                          _buildDetectionModeCard(context),
                          const SizedBox(height: 12),

                          // Threshold Cards
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 600;
                              if (isNarrow) {
                                return Column(
                                  children: [
                                    _buildThresholdCard(
                                      context,
                                      icon: Icons.access_time_rounded,
                                      iconColor: Colors.purple,
                                      title: 'Jam Nyala Maksimal',
                                      description:
                                          'Batas jam operasi meter sebelum dianggap anomali',
                                      currentValue: _operatingHoursThreshold,
                                      unit: 'jam',
                                      defaultValue: '720',
                                      defaultDescription: '30 hari × 24 jam',
                                      controller: _hoursController,
                                      onSave: _saveOperatingHoursThreshold,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildThresholdCard(
                                      context,
                                      icon: Icons.trending_up_rounded,
                                      iconColor: Colors.orange,
                                      title: 'Batas Perubahan Konsumsi',
                                      description:
                                          'Persentase perubahan konsumsi vs rata-rata/bulan lalu',
                                      currentValue:
                                          _consumptionVarianceThreshold,
                                      unit: '%',
                                      defaultValue: '35',
                                      defaultDescription:
                                          'Lonjakan/penurunan signifikan',
                                      controller: _varianceController,
                                      onSave: _saveConsumptionVarianceThreshold,
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildThresholdCard(
                                      context,
                                      icon: Icons.access_time_rounded,
                                      iconColor: Colors.purple,
                                      title: 'Jam Nyala Maksimal',
                                      description:
                                          'Batas jam operasi meter sebelum dianggap anomali',
                                      currentValue: _operatingHoursThreshold,
                                      unit: 'jam',
                                      defaultValue: '720',
                                      defaultDescription: '30 hari × 24 jam',
                                      controller: _hoursController,
                                      onSave: _saveOperatingHoursThreshold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildThresholdCard(
                                      context,
                                      icon: Icons.trending_up_rounded,
                                      iconColor: Colors.orange,
                                      title: 'Batas Perubahan Konsumsi',
                                      description:
                                          'Persentase perubahan konsumsi vs rata-rata/bulan lalu',
                                      currentValue:
                                          _consumptionVarianceThreshold,
                                      unit: '%',
                                      defaultValue: '35',
                                      defaultDescription:
                                          'Lonjakan/penurunan signifikan',
                                      controller: _varianceController,
                                      onSave: _saveConsumptionVarianceThreshold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Re-detect Button Card
                          _buildRedetectCard(colorScheme),
                          const SizedBox(height: 32),

                          // Database Section
                          _buildSectionTitle(
                            context,
                            icon: Icons.storage_rounded,
                            title: 'Database',
                            color: Colors.teal,
                          ),
                          const SizedBox(height: 12),

                          // Database Info Card
                          _buildDatabaseInfoCard(context),
                          const SizedBox(height: 12),

                          // Backup & Restore Card
                          _buildBackupRestoreCard(context),
                          const SizedBox(height: 12),

                          // Reset Database Card
                          _buildResetDatabaseCard(context),
                          const SizedBox(height: 32),

                          // App Info Footer
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.bolt_rounded,
                                        size: 16,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Billing AMR v1.0.0',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildGradientHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade500, Colors.deepPurple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.shade200.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.settings_rounded,
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
                  'Pengaturan Aplikasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Konfigurasi deteksi anomali dan manajemen database',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDetectionModeCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basis Pengecekan Anomali',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pilih metrik untuk mendeteksi lonjakan/penurunan',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 400;
                if (isNarrow) {
                  return Column(
                    children: [
                      _buildDetectionModeOption(
                        context,
                        value: 'kwh',
                        label: 'kWh (Konsumsi)',
                        description: 'Lonjakan/penurunan pemakaian listrik',
                        icon: Icons.bolt_rounded,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildDetectionModeOption(
                        context,
                        value: 'rptag',
                        label: 'RPTAG (Rupiah)',
                        description: 'Lonjakan/penurunan tagihan rupiah',
                        icon: Icons.payments_rounded,
                        color: Colors.green,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _buildDetectionModeOption(
                        context,
                        value: 'kwh',
                        label: 'kWh (Konsumsi)',
                        description: 'Lonjakan/penurunan pemakaian listrik',
                        icon: Icons.bolt_rounded,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetectionModeOption(
                        context,
                        value: 'rptag',
                        label: 'RPTAG (Rupiah)',
                        description: 'Lonjakan/penurunan tagihan rupiah',
                        icon: Icons.payments_rounded,
                        color: Colors.green,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedetectCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.primary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.refresh_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deteksi Ulang Anomali',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jalankan setelah mengubah threshold untuk memperbarui data anomali',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _redetectAnomalies,
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text('Jalankan'),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    context,
                    icon: Icons.save_rounded,
                    label: 'Ukuran',
                    value: _dbSize ?? '-',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoChip(
                    context,
                    icon: Icons.folder_rounded,
                    label: 'Lokasi',
                    value: _dbPath != null ? path.basename(_dbPath!) : '-',
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            if (_dbPath != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _dbPath!,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackupRestoreCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.backup_rounded,
                    size: 18,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Backup & Restore',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 350;
                if (isNarrow) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: _buildActionButton(
                          context,
                          icon: Icons.cloud_upload_rounded,
                          label: 'Export',
                          description: 'Simpan backup',
                          color: Colors.green,
                          onTap: _exportDatabase,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: _buildActionButton(
                          context,
                          icon: Icons.cloud_download_rounded,
                          label: 'Import',
                          description: 'Restore backup',
                          color: Colors.blue,
                          onTap: _importDatabase,
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        icon: Icons.cloud_upload_rounded,
                        label: 'Export',
                        description: 'Simpan backup',
                        color: Colors.green,
                        onTap: _exportDatabase,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        icon: Icons.cloud_download_rounded,
                        label: 'Import',
                        description: 'Restore backup',
                        color: Colors.blue,
                        onTap: _importDatabase,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Import akan mengganti semua data yang ada',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade800,
                      ),
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

  Widget _buildResetDatabaseCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade50,
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reset Database',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Hapus semua data',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        size: 20,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Fitur ini akan menghapus SEMUA data termasuk data pelanggan, '
                          'billing records, riwayat import, dan data anomali. '
                          'Tindakan ini tidak dapat dibatalkan!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _resetDatabase,
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: const Text('Reset Database'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionModeOption(
    BuildContext context, {
    required String value,
    required String label,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _anomalyDetectionMode == value;
    return InkWell(
      onTap: () async {
        setState(() {
          _anomalyDetectionMode = value;
        });
        final db = DatabaseHelper.instance;
        await db.updateAnomalyDetectionMode(value);

        // Store context before async gap
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Mode deteksi diubah ke ${value == 'kwh' ? 'kWh (Konsumsi)' : 'RPTAG (Rupiah)'}. Jalankan "Deteksi Ulang" untuk menerapkan.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? color : Colors.grey.shade500,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected ? color : Colors.grey.shade700,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required double currentValue,
    required String unit,
    required String defaultValue,
    required String defaultDescription,
    required TextEditingController controller,
    required VoidCallback onSave,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Current value display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentValue.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 14,
                      color: iconColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Input field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      hintText: defaultValue,
                      suffixText: unit,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: iconColor, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: onSave,
                  icon: const Icon(Icons.check, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Default: $defaultValue $unit ($defaultDescription)',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: color.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
