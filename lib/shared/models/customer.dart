class Customer {
  final int? id;
  final String customerId;
  final String nama;
  final String alamat;
  final String tariff;
  final int powerCapacity; // DAYA
  final String? meterCode; // KDDK
  final DateTime updatedAt;

  Customer({
    this.id,
    required this.customerId,
    required this.nama,
    required this.alamat,
    required this.tariff,
    required this.powerCapacity,
    this.meterCode,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'nama': nama,
      'alamat': alamat,
      'tariff': tariff,
      'power_capacity': powerCapacity,
      'meter_code': meterCode,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      customerId: map['customer_id'] as String,
      nama: map['nama'] as String,
      alamat: map['alamat'] as String,
      tariff: map['tariff'] as String,
      powerCapacity: map['power_capacity'] as int,
      meterCode: map['meter_code'] as String?,
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
