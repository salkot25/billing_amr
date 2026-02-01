import 'dart:io';
import 'package:excel/excel.dart';
import '../../shared/models/billing_record.dart';
import '../../shared/models/customer.dart';
import '../../shared/models/import_record.dart';
import '../../core/database/database_helper.dart';

class ExcelImportService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<ImportRecord> importExcel(File file) async {
    return importExcelWithProgress(file, onProgress: (progress, status) {});
  }

  Future<ImportRecord> importExcelWithProgress(
    File file, {
    required Function(double progress, String status) onProgress,
  }) async {
    final List<String> errors = [];
    int recordCount = 0;
    int updatedCount = 0;
    int errorCount = 0;

    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      onProgress(0.1, 'Membaca file...');

      int totalRows = 0;
      int processedRows = 0;
      int currentRow = 0;

      // Count total rows first
      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet != null) {
          totalRows += sheet.rows.length - 1; // Exclude header
        }
      }

      for (var table in excel.tables.keys) {
        final sheet = excel.tables[table];
        if (sheet == null) continue;

        // Get header row to map column indices
        final headerRow = sheet.rows.first;
        final columnMap = _mapColumns(headerRow);

        // Skip header and process data rows
        for (var i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          currentRow++;

          // Update progress
          final progressValue = 0.1 + (processedRows / totalRows * 0.7);
          onProgress(
            progressValue,
            'Memproses baris $currentRow dari $totalRows...',
          );

          try {
            final record = _parseRow(row, columnMap);
            if (record != null) {
              // Upsert billing record
              await _db.upsertBillingRecord(record.billingRecord);

              // Upsert customer info
              await _db.upsertCustomer(record.customer);

              recordCount++;
            }
          } catch (e) {
            errorCount++;
            errors.add('Row ${i + 1}: ${e.toString()}');
          }

          processedRows++;
        }
      }

      onProgress(0.85, 'Menghapus data lama...');
      // Delete old records (older than 12 months)
      await _db.deleteOldRecords();

      onProgress(0.95, 'Menyimpan riwayat...');
      final status = errorCount == 0
          ? 'success'
          : errorCount < recordCount
          ? 'partial'
          : 'failed';

      final importRecord = ImportRecord(
        filename: file.path.split(Platform.pathSeparator).last,
        importDate: DateTime.now(),
        recordCount: recordCount,
        updatedCount: updatedCount,
        errorCount: errorCount,
        status: status,
        errorLog: errors.isNotEmpty ? errors.join('\n') : null,
        fileSize: file.lengthSync(),
      );

      await _db.insertImportRecord(importRecord);
      onProgress(1.0, 'Selesai!');
      return importRecord;
    } catch (e) {
      onProgress(0.0, 'Error');
      return ImportRecord(
        filename: file.path.split(Platform.pathSeparator).last,
        importDate: DateTime.now(),
        recordCount: 0,
        errorCount: 1,
        status: 'failed',
        errorLog: 'Failed to read Excel file: ${e.toString()}',
        fileSize: file.existsSync() ? file.lengthSync() : null,
      );
    }
  }

  Map<String, int> _mapColumns(List<Data?> headerRow) {
    final Map<String, int> columnMap = {};

    for (var i = 0; i < headerRow.length; i++) {
      final cellValue = headerRow[i]?.value?.toString() ?? '';
      columnMap[cellValue] = i;
    }

    return columnMap;
  }

  _ParsedRecord? _parseRow(List<Data?> row, Map<String, int> columnMap) {
    // Extract required columns
    final thblrek = _getCellValue(row, columnMap, 'THBLREK');
    final idpel = _getCellValue(row, columnMap, 'IDPEL');
    final nama = _getCellValue(row, columnMap, 'NAMA');
    final alamat = _getCellValue(row, columnMap, 'ALAMAT');
    final tarif = _getCellValue(row, columnMap, 'TARIF');
    final daya = _getCellValue(row, columnMap, 'DAYA');

    // Meter readings
    final sahlwbp = _getCellValue(row, columnMap, 'SAHLWBP');
    final slalwbp = _getCellValue(row, columnMap, 'SLALWBP');
    final sahwbp = _getCellValue(row, columnMap, 'SAHWBP');
    final slawbp = _getCellValue(row, columnMap, 'SLAWBP');

    // Consumption
    final kwhlwbp = _getCellValue(row, columnMap, 'KWHLWBP');
    final kwhwbp = _getCellValue(row, columnMap, 'KWHWBP');

    // KVARH - menggunakan SAHKVARH (kolom BF) - SLAKVARH (kolom BC)
    final sahkvarh = _getCellValue(row, columnMap, 'SAHKVARH');
    final slakvarh = _getCellValue(row, columnMap, 'SLAKVARH');

    // Operating hours and charges
    final jamnyala = _getCellValue(row, columnMap, 'JAMNYALA');
    final rptag = _getCellValue(row, columnMap, 'RPTAG');

    // Validate required fields
    if (idpel.isEmpty || thblrek.isEmpty) {
      return null;
    }

    // Parse numeric values
    final offPeakStand = double.tryParse(sahlwbp) ?? 0.0;
    final peakStand = double.tryParse(sahwbp) ?? 0.0;
    final offPeakConsumption = double.tryParse(kwhlwbp) ?? 0.0;
    final peakConsumption = double.tryParse(kwhwbp) ?? 0.0;
    final operatingHours = double.tryParse(jamnyala) ?? 0.0;
    final rptagValue = double.tryParse(rptag) ?? 0.0;
    final powerCapacity = int.tryParse(daya) ?? 0;

    // Hitung KVARH consumption dari SAHKVARH - SLAKVARH
    double? kvarhValue;
    final sahKvarhNum = double.tryParse(sahkvarh);
    final slaKvarhNum = double.tryParse(slakvarh);
    if (sahKvarhNum != null && slaKvarhNum != null) {
      kvarhValue = sahKvarhNum - slaKvarhNum;
    }

    final now = DateTime.now();

    final customer = Customer(
      customerId: idpel,
      nama: nama.isNotEmpty ? nama : 'Unknown',
      alamat: alamat.isNotEmpty ? alamat : 'Unknown',
      tariff: tarif.isNotEmpty ? tarif : 'Unknown',
      powerCapacity: powerCapacity,
      updatedAt: now,
    );

    final billingRecord = BillingRecord(
      customerId: idpel,
      billingPeriod: thblrek,
      offPeakStand: offPeakStand,
      peakStand: peakStand,
      offPeakConsumption: offPeakConsumption,
      peakConsumption: peakConsumption,
      operatingHours: operatingHours,
      rptag: rptagValue,
      kvarhConsumption: kvarhValue,
      prevOffPeakStand: slalwbp.isNotEmpty ? slalwbp : null,
      prevPeakStand: slawbp.isNotEmpty ? slawbp : null,
      createdAt: now,
      updatedAt: now,
    );

    return _ParsedRecord(customer: customer, billingRecord: billingRecord);
  }

  String _getCellValue(
    List<Data?> row,
    Map<String, int> columnMap,
    String columnName,
  ) {
    final index = columnMap[columnName];
    if (index == null || index >= row.length) return '';

    final cell = row[index];
    if (cell == null || cell.value == null) return '';

    return cell.value.toString().trim();
  }
}

class _ParsedRecord {
  final Customer customer;
  final BillingRecord billingRecord;

  _ParsedRecord({required this.customer, required this.billingRecord});
}
