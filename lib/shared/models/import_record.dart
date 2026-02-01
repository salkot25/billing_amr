class ImportRecord {
  final int? id;
  final String filename;
  final DateTime importDate;
  final int recordCount;
  final int updatedCount;
  final int errorCount;
  final String status; // 'success', 'partial', 'failed'
  final String? errorLog;
  final int? fileSize; // File size in bytes

  ImportRecord({
    this.id,
    required this.filename,
    required this.importDate,
    required this.recordCount,
    this.updatedCount = 0,
    this.errorCount = 0,
    required this.status,
    this.errorLog,
    this.fileSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filename': filename,
      'import_date': importDate.toIso8601String(),
      'record_count': recordCount,
      'updated_count': updatedCount,
      'error_count': errorCount,
      'status': status,
      'error_log': errorLog,
      'file_size': fileSize,
    };
  }

  factory ImportRecord.fromMap(Map<String, dynamic> map) {
    return ImportRecord(
      id: map['id'] as int?,
      filename: map['filename'] as String,
      importDate: DateTime.parse(map['import_date'] as String),
      recordCount: map['record_count'] as int,
      updatedCount: map['updated_count'] as int? ?? 0,
      errorCount: map['error_count'] as int? ?? 0,
      status: map['status'] as String,
      errorLog: map['error_log'] as String?,
      fileSize: map['file_size'] as int?,
    );
  }

  /// Format file size to human readable string
  String get fileSizeFormatted {
    if (fileSize == null) return '-';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024)
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
