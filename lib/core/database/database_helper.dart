import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../shared/models/billing_record.dart';
import '../../shared/models/customer.dart';
import '../../shared/models/import_record.dart';
import '../../shared/models/anomaly_flag.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('billing_amr.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'billing_amr.db');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> resetDatabase() async {
    // Close the existing connection
    await close();

    // Get the database path and delete the file
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'billing_amr.db');

    await deleteDatabase(path);

    // Reinitialize the database
    _database = await _initDB('billing_amr.db');
  }

  Future<void> _createDB(Database db, int version) async {
    // Customers table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id TEXT UNIQUE NOT NULL,
        nama TEXT NOT NULL,
        alamat TEXT NOT NULL,
        tariff TEXT NOT NULL,
        power_capacity INTEGER NOT NULL,
        meter_code TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    // Billing records table
    await db.execute('''
      CREATE TABLE billing_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id TEXT NOT NULL,
        billing_period TEXT NOT NULL,
        off_peak_stand REAL NOT NULL,
        peak_stand REAL NOT NULL,
        off_peak_consumption REAL NOT NULL,
        peak_consumption REAL NOT NULL,
        operating_hours REAL NOT NULL,
        rptag REAL NOT NULL,
        kvarh_consumption REAL,
        prev_off_peak_stand TEXT,
        prev_peak_stand TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(customer_id, billing_period)
      )
    ''');

    // Imports table
    await db.execute('''
      CREATE TABLE imports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filename TEXT NOT NULL,
        import_date TEXT NOT NULL,
        record_count INTEGER NOT NULL,
        updated_count INTEGER DEFAULT 0,
        error_count INTEGER DEFAULT 0,
        status TEXT NOT NULL,
        error_log TEXT,
        file_size INTEGER
      )
    ''');

    // Anomaly flags table
    await db.execute('''
      CREATE TABLE anomaly_flags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        billing_record_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        severity TEXT NOT NULL,
        description TEXT NOT NULL,
        reviewed INTEGER DEFAULT 0,
        flagged_at TEXT NOT NULL,
        FOREIGN KEY (billing_record_id) REFERENCES billing_records (id)
      )
    ''');

    // Create indexes
    await db.execute(
      'CREATE INDEX idx_billing_period ON billing_records(billing_period DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_customer_period ON billing_records(customer_id, billing_period DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_anomaly_severity ON anomaly_flags(severity, reviewed)',
    );

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Insert default settings
    await db.insert('settings', {
      'key': 'operating_hours_threshold',
      'value': '720',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add settings table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Insert default settings if not exists
      final existing = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: ['operating_hours_threshold'],
      );

      if (existing.isEmpty) {
        await db.insert('settings', {
          'key': 'operating_hours_threshold',
          'value': '720',
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    }

    if (oldVersion < 3) {
      // Add kvarh_consumption column to billing_records if it doesn't exist
      try {
        await db.execute(
          'ALTER TABLE billing_records ADD COLUMN kvarh_consumption REAL',
        );
      } catch (e) {
        // Column might already exist, ignore error
      }
    }

    if (oldVersion < 4) {
      // Add file_size column to imports table
      try {
        await db.execute('ALTER TABLE imports ADD COLUMN file_size INTEGER');
      } catch (e) {
        // Column might already exist, ignore error
      }
    }
  }

  // UPSERT billing record
  Future<int> upsertBillingRecord(BillingRecord record) async {
    final db = await database;
    return await db.insert(
      'billing_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // UPSERT customer
  Future<int> upsertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert import record
  Future<int> insertImportRecord(ImportRecord importRecord) async {
    final db = await database;
    return await db.insert('imports', importRecord.toMap());
  }

  // Insert anomaly flag
  Future<int> insertAnomalyFlag(AnomalyFlag flag) async {
    final db = await database;
    return await db.insert('anomaly_flags', flag.toMap());
  }

  // Delete anomaly flags for a billing record
  Future<void> deleteAnomalyFlags(int billingRecordId) async {
    final db = await database;
    await db.delete(
      'anomaly_flags',
      where: 'billing_record_id = ?',
      whereArgs: [billingRecordId],
    );
  }

  // Get all billing periods
  Future<List<String>> getAllBillingPeriods() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT billing_period
      FROM billing_records
      ORDER BY billing_period DESC
    ''');
    return result.map((row) => row['billing_period'] as String).toList();
  }

  // Get latest billing period
  Future<String?> getLatestBillingPeriod() async {
    final db = await database;
    final result = await db.query(
      'billing_records',
      columns: ['billing_period'],
      orderBy: 'billing_period DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first['billing_period'] as String : null;
  }

  // Get previous billing period
  Future<String?> getPreviousBillingPeriod(String latestPeriod) async {
    final db = await database;
    final result = await db.query(
      'billing_records',
      columns: ['billing_period'],
      where: 'billing_period < ?',
      whereArgs: [latestPeriod],
      orderBy: 'billing_period DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first['billing_period'] as String : null;
  }

  // Get active customers count for latest period
  Future<int> getActiveCustomersCount(String billingPeriod) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT customer_id) as count
      FROM billing_records
      WHERE billing_period = ?
    ''',
      [billingPeriod],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get total RPTAG for latest period
  Future<double> getTotalRptag(String billingPeriod) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(rptag) as total
      FROM billing_records
      WHERE billing_period = ?
    ''',
      [billingPeriod],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get total consumption (kWh) for a period
  Future<double> getTotalConsumption(String billingPeriod) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(off_peak_consumption + peak_consumption) as total
      FROM billing_records
      WHERE billing_period = ?
    ''',
      [billingPeriod],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Get consumption by tariff for a period
  Future<Map<String, double>> getConsumptionByTariff(
    String billingPeriod,
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT c.tariff, 
             SUM(br.off_peak_consumption + br.peak_consumption) as total
      FROM billing_records br
      JOIN customers c ON br.customer_id = c.customer_id
      WHERE br.billing_period = ?
      GROUP BY c.tariff
      ORDER BY total DESC
    ''',
      [billingPeriod],
    );

    final Map<String, double> consumption = {};
    for (var row in result) {
      final tariff = row['tariff'] as String?;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      if (tariff != null && total > 0) {
        consumption[tariff] = total;
      }
    }
    return consumption;
  }

  // Get customer count by tariff for a period
  Future<Map<String, int>> getCustomerCountByTariff(
    String billingPeriod,
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT c.tariff, 
             COUNT(DISTINCT br.customer_id) as count
      FROM billing_records br
      JOIN customers c ON br.customer_id = c.customer_id
      WHERE br.billing_period = ?
      GROUP BY c.tariff
      ORDER BY count DESC
    ''',
      [billingPeriod],
    );

    final Map<String, int> counts = {};
    for (var row in result) {
      final tariff = row['tariff'] as String?;
      final count = (row['count'] as num?)?.toInt() ?? 0;
      if (tariff != null && count > 0) {
        counts[tariff] = count;
      }
    }
    return counts;
  }

  // Get total RPTAG by tariff for a period
  Future<Map<String, double>> getRptagByTariff(String billingPeriod) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT c.tariff, 
             SUM(br.rptag) as total
      FROM billing_records br
      JOIN customers c ON br.customer_id = c.customer_id
      WHERE br.billing_period = ?
      GROUP BY c.tariff
      ORDER BY total DESC
    ''',
      [billingPeriod],
    );

    final Map<String, double> rptag = {};
    for (var row in result) {
      final tariff = row['tariff'] as String?;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      if (tariff != null && total > 0) {
        rptag[tariff] = total;
      }
    }
    return rptag;
  }

  // Get anomaly count
  Future<int> getAnomalyCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM anomaly_flags
      WHERE reviewed = 0
    ''');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Get billing records for a customer
  Future<List<BillingRecord>> getBillingRecordsByCustomer(
    String customerId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'billing_records',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'billing_period DESC',
      limit: 12,
    );
    return maps.map((map) => BillingRecord.fromMap(map)).toList();
  }

  // Get all customers
  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final maps = await db.query('customers', orderBy: 'nama ASC');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  // Search customers by ID or name
  Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'customer_id LIKE ? OR nama LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'nama ASC',
    );
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  // Get customer by ID
  Future<Customer?> getCustomerById(String customerId) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  // Check if customer is active in latest billing period
  Future<bool> isCustomerActive(String customerId) async {
    final db = await database;
    final latestPeriod = await getLatestBillingPeriod();

    if (latestPeriod == null) return false;

    final result = await db.query(
      'billing_records',
      where: 'customer_id = ? AND billing_period = ?',
      whereArgs: [customerId, latestPeriod],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // Get anomaly flags with billing record info
  Future<List<Map<String, dynamic>>> getAnomaliesWithRecords() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        af.*,
        br.customer_id,
        br.billing_period,
        br.off_peak_stand,
        br.peak_stand,
        br.operating_hours,
        c.nama,
        c.alamat,
        c.tariff as tarif,
        c.power_capacity as daya
      FROM anomaly_flags af
      INNER JOIN billing_records br ON af.billing_record_id = br.id
      INNER JOIN customers c ON br.customer_id = c.customer_id
      WHERE af.reviewed = 0
      ORDER BY af.severity DESC, af.flagged_at DESC
    ''');
  }

  // Delete old records (older than 12 months)
  Future<int> deleteOldRecords() async {
    final db = await database;
    final latestPeriod = await getLatestBillingPeriod();
    if (latestPeriod == null) return 0;

    // Calculate 12 months ago
    final year = int.parse(latestPeriod.substring(0, 4));
    final month = int.parse(latestPeriod.substring(4, 6));
    final cutoffDate = DateTime(
      year,
      month,
    ).subtract(const Duration(days: 365));
    final cutoffPeriod =
        '${cutoffDate.year}${cutoffDate.month.toString().padLeft(2, '0')}';

    return await db.delete(
      'billing_records',
      where: 'billing_period < ?',
      whereArgs: [cutoffPeriod],
    );
  }

  // Get 12-month average consumption for a customer
  Future<double> getAverageConsumption(String customerId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT AVG(off_peak_consumption + peak_consumption) as avg_consumption
      FROM (
        SELECT off_peak_consumption, peak_consumption
        FROM billing_records
        WHERE customer_id = ?
        ORDER BY billing_period DESC
        LIMIT 12
      )
    ''',
      [customerId],
    );
    return (result.first['avg_consumption'] as num?)?.toDouble() ?? 0.0;
  }

  // Get previous month consumption for a customer
  Future<double?> getPreviousMonthConsumption(
    String customerId,
    String currentPeriod,
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT (off_peak_consumption + peak_consumption) as total_consumption
      FROM billing_records
      WHERE customer_id = ? AND billing_period < ?
      ORDER BY billing_period DESC
      LIMIT 1
    ''',
      [customerId, currentPeriod],
    );
    if (result.isEmpty) return null;
    return (result.first['total_consumption'] as num?)?.toDouble();
  }

  // Get import history
  Future<List<ImportRecord>> getImportHistory() async {
    final db = await database;
    final maps = await db.query(
      'imports',
      orderBy: 'import_date DESC',
      limit: 50,
    );
    return maps.map((map) => ImportRecord.fromMap(map)).toList();
  }

  // Delete import history record
  Future<void> deleteImportHistory(int id) async {
    final db = await database;
    await db.delete('imports', where: 'id = ?', whereArgs: [id]);
  }

  // Clear all import history
  Future<void> clearAllImportHistory() async {
    final db = await database;
    await db.delete('imports');
  }

  // Ensure settings table exists
  Future<void> _ensureSettingsTable() async {
    final db = await database;

    // Check if settings table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='settings'",
    );

    if (tables.isEmpty) {
      // Create settings table
      await db.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Insert default settings
      await db.insert('settings', {
        'key': 'operating_hours_threshold',
        'value': '720',
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Get setting value
  Future<String?> getSetting(String key) async {
    await _ensureSettingsTable();
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  // Update setting value
  Future<void> updateSetting(String key, String value) async {
    await _ensureSettingsTable();
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get operating hours threshold
  Future<double> getOperatingHoursThreshold() async {
    final value = await getSetting('operating_hours_threshold');
    return double.tryParse(value ?? '720') ?? 720.0;
  }

  // Update operating hours threshold
  Future<void> updateOperatingHoursThreshold(double threshold) async {
    await updateSetting('operating_hours_threshold', threshold.toString());
  }

  // Get consumption variance threshold (percentage for spike/decrease detection)
  Future<double> getConsumptionVarianceThreshold() async {
    final value = await getSetting('consumption_variance_threshold');
    return double.tryParse(value ?? '35') ?? 35.0;
  }

  // Update consumption variance threshold
  Future<void> updateConsumptionVarianceThreshold(double threshold) async {
    await updateSetting('consumption_variance_threshold', threshold.toString());
  }

  // Get anomaly detection mode ('kwh' or 'rptag')
  Future<String> getAnomalyDetectionMode() async {
    final value = await getSetting('anomaly_detection_mode');
    return value ?? 'kwh'; // Default to kWh-based detection
  }

  // Update anomaly detection mode
  Future<void> updateAnomalyDetectionMode(String mode) async {
    await updateSetting('anomaly_detection_mode', mode);
  }

  // Get average RPTAG for a customer (last 12 months)
  Future<double> getAverageRptag(String customerId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT AVG(rptag) as avg_rptag
      FROM (
        SELECT rptag
        FROM billing_records
        WHERE customer_id = ?
        ORDER BY billing_period DESC
        LIMIT 12
      )
    ''',
      [customerId],
    );
    return (result.first['avg_rptag'] as num?)?.toDouble() ?? 0.0;
  }

  // Get previous month RPTAG for a customer
  Future<double?> getPreviousMonthRptag(
    String customerId,
    String currentPeriod,
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT rptag
      FROM billing_records
      WHERE customer_id = ? AND billing_period < ?
      ORDER BY billing_period DESC
      LIMIT 1
    ''',
      [customerId, currentPeriod],
    );
    if (result.isEmpty) return null;
    return (result.first['rptag'] as num?)?.toDouble();
  }

  // Get yearly consumption history (last 12 months from latest period)
  Future<Map<String, double>> getYearlyConsumptionHistory() async {
    final db = await database;

    // Get all available periods and take last 12
    final periodsResult = await db.rawQuery('''
      SELECT DISTINCT billing_period 
      FROM billing_records 
      ORDER BY billing_period DESC 
      LIMIT 12
    ''');

    final periods = periodsResult
        .map((row) => row['billing_period'] as String)
        .toList()
        .reversed
        .toList(); // Reverse to get chronological order

    final Map<String, double> history = {};

    for (var period in periods) {
      final result = await db.rawQuery(
        '''
        SELECT SUM(off_peak_consumption + peak_consumption) as total
        FROM billing_records
        WHERE billing_period = ?
      ''',
        [period],
      );

      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      history[period] = total;
    }

    return history;
  }

  // Get yearly RPTAG history (last 12 months from latest period)
  Future<Map<String, double>> getYearlyRptagHistory() async {
    final db = await database;

    // Get all available periods and take last 12
    final periodsResult = await db.rawQuery('''
      SELECT DISTINCT billing_period 
      FROM billing_records 
      ORDER BY billing_period DESC 
      LIMIT 12
    ''');

    final periods = periodsResult
        .map((row) => row['billing_period'] as String)
        .toList()
        .reversed
        .toList(); // Reverse to get chronological order

    final Map<String, double> history = {};

    for (var period in periods) {
      final result = await db.rawQuery(
        '''
        SELECT SUM(rptag) as total
        FROM billing_records
        WHERE billing_period = ?
      ''',
        [period],
      );

      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      history[period] = total;
    }

    return history;
  }

  // Get yearly customer count history (last 6 months)
  Future<List<double>> getCustomerCountHistory() async {
    final db = await database;

    final periodsResult = await db.rawQuery('''
      SELECT DISTINCT billing_period 
      FROM billing_records 
      ORDER BY billing_period DESC 
      LIMIT 6
    ''');

    final periods = periodsResult
        .map((row) => row['billing_period'] as String)
        .toList()
        .reversed
        .toList();

    final List<double> history = [];

    for (var period in periods) {
      final result = await db.rawQuery(
        '''
        SELECT COUNT(DISTINCT customer_id) as count
        FROM billing_records
        WHERE billing_period = ?
      ''',
        [period],
      );

      final count = (result.first['count'] as int?)?.toDouble() ?? 0.0;
      history.add(count);
    }

    return history;
  }

  // Get consumption history for sparkline (last 6 months)
  Future<List<double>> getConsumptionSparklineHistory() async {
    final db = await database;

    final periodsResult = await db.rawQuery('''
      SELECT DISTINCT billing_period 
      FROM billing_records 
      ORDER BY billing_period DESC 
      LIMIT 6
    ''');

    final periods = periodsResult
        .map((row) => row['billing_period'] as String)
        .toList()
        .reversed
        .toList();

    final List<double> history = [];

    for (var period in periods) {
      final result = await db.rawQuery(
        '''
        SELECT SUM(off_peak_consumption + peak_consumption) as total
        FROM billing_records
        WHERE billing_period = ?
      ''',
        [period],
      );

      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      history.add(total);
    }

    return history;
  }

  // Get RPTAG history for sparkline (last 6 months)
  Future<List<double>> getRptagSparklineHistory() async {
    final db = await database;

    final periodsResult = await db.rawQuery('''
      SELECT DISTINCT billing_period 
      FROM billing_records 
      ORDER BY billing_period DESC 
      LIMIT 6
    ''');

    final periods = periodsResult
        .map((row) => row['billing_period'] as String)
        .toList()
        .reversed
        .toList();

    final List<double> history = [];

    for (var period in periods) {
      final result = await db.rawQuery(
        '''
        SELECT SUM(rptag) as total
        FROM billing_records
        WHERE billing_period = ?
      ''',
        [period],
      );

      final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
      history.add(total);
    }

    return history;
  }
}
