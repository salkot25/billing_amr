import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/models/import_record.dart';
import 'excel_import_service.dart';
import 'anomaly_detection_service.dart';

class ImportExcelScreen extends ConsumerStatefulWidget {
  const ImportExcelScreen({super.key});

  @override
  ConsumerState<ImportExcelScreen> createState() => _ImportExcelScreenState();
}

class _ImportExcelScreenState extends ConsumerState<ImportExcelScreen> {
  File? _selectedFile;
  bool _isImporting = false;
  double _importProgress = 0.0;
  String _importStatus = '';
  ImportRecord? _lastImportResult;

  void _onSelectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _importProgress = 0.0;
        _importStatus = '';
        _lastImportResult = null;
      });
    }
  }

  void _onImport() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih file terlebih dahulu')),
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _importProgress = 0.0;
      _importStatus = 'Memulai proses import...';
      _lastImportResult = null;
    });

    try {
      final importService = ExcelImportService();
      final importRecord = await importService.importExcelWithProgress(
        _selectedFile!,
        onProgress: (progress, status) {
          if (mounted) {
            setState(() {
              _importProgress = progress;
              _importStatus = status;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _importStatus = 'Mendeteksi anomali...';
          _importProgress = 0.9;
        });
      }

      // Run anomaly detection
      final anomalyService = AnomalyDetectionService();
      await anomalyService.detectAnomalies();

      if (mounted) {
        setState(() {
          _lastImportResult = importRecord;
          _importProgress = 1.0;
          _importStatus = 'Selesai!';
          _isImporting = false;
          _selectedFile = null;
        });

        // Refresh dashboard data
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(customersProvider);
        ref.invalidate(importHistoryProvider);

        // Show success/warning dialog
        _showImportResultDialog(importRecord);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _importStatus = 'Error: ${e.toString()}';
          _importProgress = 0.0;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error import: $e')));
      }
    }
  }

  void _showImportResultDialog(ImportRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          record.status == 'success'
              ? '✓ Import Berhasil'
              : record.status == 'partial'
              ? '⚠ Import Sebagian'
              : '✗ Import Gagal',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'File', value: record.filename),
              _InfoRow(
                label: 'Waktu',
                value: DateFormat(
                  'dd/MM/yyyy HH:mm:ss',
                  'id_ID',
                ).format(record.importDate),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'Berhasil',
                      value: record.recordCount.toString(),
                      isBold: true,
                    ),
                    if (record.errorCount > 0)
                      _InfoRow(
                        label: 'Error',
                        value: record.errorCount.toString(),
                        color: Colors.red,
                      ),
                  ],
                ),
              ),
              if (record.errorLog != null && record.errorLog!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Detail Error:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      record.errorLog!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final importHistoryAsync = ref.watch(importHistoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Data'),
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
                  maxWidth: isWide ? 1080 : constraints.maxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gradient Header - Consistent with Dashboard
                    _buildGradientHeader(theme),
                    const SizedBox(height: 24),

                    // Upload Area Card
                    _UploadArea(
                      selectedFile: _selectedFile,
                      isImporting: _isImporting,
                      onSelectFile: _onSelectFile,
                      onImport: _onImport,
                    ),
                    const SizedBox(height: 20),

                    // Progress Section
                    if (_isImporting || _lastImportResult != null)
                      _ProgressSection(
                        progress: _importProgress,
                        status: _importStatus,
                        isImporting: _isImporting,
                        lastResult: _lastImportResult,
                      ),
                    if (_isImporting || _lastImportResult != null)
                      const SizedBox(height: 20),

                    // History Section
                    _HistorySection(importHistoryAsync: importHistoryAsync),
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
          colors: [Colors.teal.shade500, Colors.teal.shade700],
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.cloud_upload_rounded,
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
                  'Import Data Billing',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload file Excel (.xlsx) untuk mengimpor data pelanggan dan tagihan',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadArea extends StatelessWidget {
  final File? selectedFile;
  final bool isImporting;
  final VoidCallback onSelectFile;
  final VoidCallback onImport;

  const _UploadArea({
    required this.selectedFile,
    required this.isImporting,
    required this.onSelectFile,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.file_upload_outlined,
                    size: 20,
                    color: Colors.teal.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Pilih File Excel',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Upload Zone
            InkWell(
              onTap: isImporting ? null : onSelectFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selectedFile != null
                        ? Colors.teal.shade400
                        : theme.colorScheme.outlineVariant,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: selectedFile != null
                      ? Colors.teal.shade50.withValues(alpha: 0.5)
                      : theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selectedFile != null
                            ? Colors.teal.shade100
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        selectedFile != null
                            ? Icons.description_outlined
                            : Icons.cloud_upload_outlined,
                        size: 36,
                        color: selectedFile != null
                            ? Colors.teal.shade600
                            : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (selectedFile != null)
                      Column(
                        children: [
                          Text(
                            selectedFile!.path
                                .split(Platform.pathSeparator)
                                .last,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '✓ File siap diimport',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.teal.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Text(
                            'Klik untuk memilih file',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Format: .xlsx (Excel 2007+)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              'File .xls? Buka di Excel → Save As → pilih .xlsx',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Import Button
            FilledButton.icon(
              onPressed: isImporting ? null : onImport,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: Icon(isImporting ? Icons.hourglass_top : Icons.upload_file),
              label: Text(
                isImporting ? 'Proses Import...' : 'Mulai Import',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final double progress;
  final String status;
  final bool isImporting;
  final ImportRecord? lastResult;

  const _ProgressSection({
    required this.progress,
    required this.status,
    required this.isImporting,
    required this.lastResult,
  });

  @override
  Widget build(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isImporting
                        ? Colors.blue.shade50
                        : lastResult?.status == 'success'
                        ? Colors.green.shade50
                        : lastResult?.status == 'partial'
                        ? Colors.orange.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isImporting
                        ? Icons.sync
                        : lastResult?.status == 'success'
                        ? Icons.check_circle_outline
                        : lastResult?.status == 'partial'
                        ? Icons.warning_amber_outlined
                        : Icons.error_outline,
                    size: 20,
                    color: isImporting
                        ? Colors.blue.shade600
                        : lastResult?.status == 'success'
                        ? Colors.green.shade600
                        : lastResult?.status == 'partial'
                        ? Colors.orange.shade600
                        : Colors.red.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isImporting ? 'Proses Import' : 'Hasil Import',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        status,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.teal.shade500,
                    ),
                  ),
                ),
              ],
            ),
            if (!isImporting && lastResult != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lastResult!.status == 'success'
                      ? Colors.green.shade50
                      : lastResult!.status == 'partial'
                      ? Colors.orange.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: lastResult!.status == 'success'
                        ? Colors.green.shade200
                        : lastResult!.status == 'partial'
                        ? Colors.orange.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      lastResult!.status == 'success'
                          ? Icons.check_circle
                          : lastResult!.status == 'partial'
                          ? Icons.warning_amber
                          : Icons.cancel,
                      color: lastResult!.status == 'success'
                          ? Colors.green.shade600
                          : lastResult!.status == 'partial'
                          ? Colors.orange.shade600
                          : Colors.red.shade600,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lastResult!.status == 'success'
                                ? 'Import Berhasil!'
                                : lastResult!.status == 'partial'
                                ? 'Import Sebagian Berhasil'
                                : 'Import Gagal',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: lastResult!.status == 'success'
                                  ? Colors.green.shade700
                                  : lastResult!.status == 'partial'
                                  ? Colors.orange.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${lastResult!.recordCount} record berhasil diimport${lastResult!.errorCount > 0 ? ', ${lastResult!.errorCount} error' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistorySection extends ConsumerStatefulWidget {
  final AsyncValue<List<ImportRecord>> importHistoryAsync;

  const _HistorySection({required this.importHistoryAsync});

  @override
  ConsumerState<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends ConsumerState<_HistorySection> {
  int _currentPage = 0;
  int _itemsPerPage = 10;

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade600,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Hapus Semua Riwayat?'),
          ],
        ),
        content: const Text(
          'Semua riwayat import akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final db = ref.read(databaseProvider);
              await db.clearAllImportHistory();
              ref.invalidate(importHistoryProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Semua riwayat import berhasil dihapus',
                    ),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ImportRecord record,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red.shade600, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Hapus Riwayat?')),
          ],
        ),
        content: Text(
          'Riwayat import "${record.filename}" akan dihapus secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final db = ref.read(databaseProvider);
              await db.deleteImportHistory(record.id!);
              ref.invalidate(importHistoryProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Riwayat "${record.filename}" berhasil dihapus',
                    ),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header - Consistent with Daftar Pelanggan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Riwayat Import',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                widget.importHistoryAsync.when(
                  data: (imports) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${imports.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                ),
                const Spacer(),
                // Clear All Button
                widget.importHistoryAsync.when(
                  data: (imports) => imports.isNotEmpty
                      ? TextButton.icon(
                          onPressed: () => _showClearAllDialog(context, ref),
                          icon: Icon(
                            Icons.delete_sweep_outlined,
                            size: 18,
                            color: Colors.red.shade600,
                          ),
                          label: Text(
                            'Hapus Semua',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(0),
            child: widget.importHistoryAsync.when(
              data: (imports) {
                if (imports.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada riwayat import',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Pagination logic
                final totalItems = imports.length;
                final totalPages = _itemsPerPage == -1
                    ? 1
                    : (totalItems / _itemsPerPage).ceil();
                final startIndex = _itemsPerPage == -1
                    ? 0
                    : _currentPage * _itemsPerPage;
                final endIndex = _itemsPerPage == -1
                    ? totalItems
                    : (startIndex + _itemsPerPage).clamp(0, totalItems);
                final paginatedImports = imports.sublist(startIndex, endIndex);

                return Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: paginatedImports.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final record = paginatedImports[index];
                        return _HistoryItem(
                          record: record,
                          onDelete: () =>
                              _showDeleteDialog(context, ref, record),
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
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Tampilkan:',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildPageSizeButton(5, theme),
                          const SizedBox(width: 4),
                          _buildPageSizeButton(10, theme),
                          const SizedBox(width: 4),
                          _buildPageSizeButton(100, theme),
                          const SizedBox(width: 4),
                          _buildPageSizeButton(-1, theme, label: 'Semua'),
                          const Spacer(),
                          // Page info and navigation
                          if (_itemsPerPage != -1 && totalPages > 1) ...[
                            Text(
                              '${startIndex + 1}-$endIndex dari $totalItems',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Previous button
                            _buildNavButton(
                              icon: Icons.chevron_left,
                              onPressed: _currentPage > 0
                                  ? () => setState(() => _currentPage--)
                                  : null,
                              theme: theme,
                            ),
                            const SizedBox(width: 4),
                            // Page indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(6),
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
                            // Next button
                            _buildNavButton(
                              icon: Icons.chevron_right,
                              onPressed: _currentPage < totalPages - 1
                                  ? () => setState(() => _currentPage++)
                                  : null,
                              theme: theme,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ),
        ],
      ),
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
}

class _HistoryItem extends StatelessWidget {
  final ImportRecord record;
  final VoidCallback onDelete;

  const _HistoryItem({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');
    final numberFormat = NumberFormat('#,##0', 'id_ID');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar/Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: record.status == 'success'
                    ? [Colors.green.shade400, Colors.green.shade600]
                    : record.status == 'partial'
                    ? [Colors.orange.shade400, Colors.orange.shade600]
                    : [Colors.red.shade400, Colors.red.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              record.status == 'success'
                  ? Icons.check_rounded
                  : record.status == 'partial'
                  ? Icons.warning_amber_rounded
                  : Icons.close_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.filename,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(record.importDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.folder_outlined,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      record.fileSizeFormatted,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.check_circle_outline,
                      size: 12,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${numberFormat.format(record.recordCount)} record',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (record.errorCount > 0) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.error_outline,
                        size: 12,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${record.errorCount} error',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: record.status == 'success'
                  ? Colors.green.shade50
                  : record.status == 'partial'
                  ? Colors.orange.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              record.status == 'success'
                  ? '✓ Berhasil'
                  : record.status == 'partial'
                  ? '⚠ Sebagian'
                  : '✗ Gagal',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: record.status == 'success'
                    ? Colors.green.shade700
                    : record.status == 'partial'
                    ? Colors.orange.shade700
                    : Colors.red.shade700,
              ),
            ),
          ),
          // Delete Button
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: Colors.red.shade400,
            ),
            tooltip: 'Hapus',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
