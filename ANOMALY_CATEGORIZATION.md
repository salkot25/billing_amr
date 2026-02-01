# Sistem Kategorisasi Anomali

## Ringkasan

Sistem ini mengidentifikasi dan mengkategorikan 4 jenis anomali pada data meter listrik PLN dengan dua tingkat keparahan (Kritis dan Sedang).

---

## Jenis Anomali (Anomaly Type)

### 1. Stand Mundur (Stand Meter Menurun)

**Ikon:** 📉 Trending Down  
**Keparahan:** KRITIS  
**Deskripsi:** Pembacaan meter menurun dibanding periode sebelumnya

**Detail:**

- Terjadi ketika stand LWBP (off-peak) atau WBP (peak) lebih rendah dari periode sebelumnya
- Indikasi kemungkinan adanya manipulasi meter atau reset meter
- Memerlukan pengecekan fisik segera ke lokasi pelanggan
- Dideteksi untuk kedua jenis tarif (LWBP dan WBP)

**Contoh:**

```
Stand LWBP mundur: 5000.00 → 4950.00
Stand WBP mundur: 3000.00 → 2980.00
```

---

### 2. Jam Nyala Berlebih (Excessive Operating Hours)

**Ikon:** ⏱️ Schedule  
**Keparahan:** SEDANG  
**Deskripsi:** Jam operasi melampaui 720 jam per bulan

**Detail:**

- Maksimal jam nyala normal adalah 720 jam/bulan (24 jam × 30 hari)
- Nilai lebih dari 720 jam mengindikasikan anomali
- Bisa disebabkan oleh:
  - Kesalahan pembacaan meter
  - Gangguan pada perangkat pencatat jam
  - Penggunaan yang tidak sesuai

---

### 3. Lonjakan Konsumsi (Consumption Spike)

**Ikon:** 📈 Trending Up  
**Keparahan:** SEDANG  
**Deskripsi:** Konsumsi meningkat >30% dari rata-rata 12 bulan

**Detail:**

- Dibandingkan rata-rata konsumsi 12 bulan sebelumnya
- Peningkatan >30% dianggap abnormal
- Kemungkinan penyebab:
  - Penambahan beban listrik
  - Kesalahan pembacaan meter
  - Perubahan pola penggunaan musiman

**Formula:**

```
Persentase = ((Konsumsi Bulan Ini - Rata-rata 12 Bulan) / Rata-rata 12 Bulan) × 100
Anomali jika: Persentase > 30%
```

---

### 4. Konsumsi Nol (Zero Consumption)

**Ikon:** 🔌 Power Off  
**Keparahan:** SEDANG  
**Deskripsi:** Tidak ada konsumsi listrik dalam periode billing

**Detail:**

- Total konsumsi (LWBP + WBP) = 0 kWh
- Indikasi:
  - Meter tidak berfungsi
  - Koneksi listrik terputus
  - Stand meter tidak berubah sama sekali
  - Perlu verifikasi lapangan

---

## Kategori Keparahan (Severity)

### 🔴 KRITIS (Critical)

**Warna:** Merah (#D32F2F)  
**Anomali:** Stand Mundur  
**Tindakan:**

- Perlu segera ditindaklanjuti
- Verifikasi fisik ke lokasi pelanggan
- Kemungkinan ada manipulasi atau kerusakan meter

### 🟠 SEDANG (Medium)

**Warna:** Oranye (#F57C00)  
**Anomali:**

- Jam Nyala Berlebih
- Lonjakan Konsumsi
- Konsumsi Nol

**Tindakan:**

- Perlu pengecekan dan klarifikasi
- Dapat ditindaklanjuti sesuai prioritas
- Dimungkinkan ada penjelasan valid dari pelanggan

### 🟡 RENDAH (Low)

**Warna:** Kuning (#FBC02D)  
**Tindakan:** Monitoring saja

---

## Tampilan Anomali

### 1. Statistik Anomali (Anomaly Statistics Screen)

**Lokasi:** Dashboard → Anomali Terdeteksi → Statistik

**Menampilkan:**

- **Ringkasan Kartu** - Total, Kritis, Sedang, Rendah
- **Jenis Anomali** - Breakdown per jenis dengan jumlah dan persentase
- **Kategori Keparahan** - Breakdown per level keparahan
- **Daftar Detail** - Semua anomali dengan informasi lengkap

**Fitur:**

- Visual dengan ikon dan warna sesuai kategori
- Statistik persentase
- Filter dan sorting otomatis berdasarkan keparahan

### 2. Daftar Anomali (Anomaly List Screen)

**Lokasi:** Dashboard → Anomali Terdeteksi → Daftar

**Menampilkan:**

- **Kartu per Anomali** dengan:
  - Jenis anomali (tipe & deskripsi)
  - Level keparahan
  - Nama pelanggan & ID
  - Periode billing
  - Waktu terdeteksi
  - Deskripsi detail

**Fitur:**

- Warna-kode berdasarkan keparahan
- Ikon visual untuk setiap jenis anomali
- Informasi lengkap dalam satu kartu

---

## Proses Deteksi Otomatis

### Saat Import Excel:

1. File Excel diparse dan data di-upsert ke database
2. Sistem otomatis menjalankan deteksi anomali
3. Anomali flags disimpan dengan type, severity, dan deskripsi

### Data yang Digunakan:

- `billing_period` - Periode billing (YYYYMM)
- `customer_id` - ID pelanggan
- `off_peak_stand` / `peak_stand` - Stand meter
- `off_peak_consumption` / `peak_consumption` - Konsumsi
- `operating_hours` - Jam nyala
- Previous stands - Stand periode sebelumnya

---

## Struktur Data

### Model AnomalyFlag:

```dart
class AnomalyFlag {
  final int? id;
  final int billingRecordId;
  final AnomalyType type;           // standMundur, excessiveHours, consumptionSpike, zeroConsumption
  final AnomalySeverity severity;   // critical, medium, low
  final String description;          // Deskripsi detail
  final bool reviewed;              // Status review
  final DateTime flaggedAt;         // Waktu deteksi
}
```

### Enum:

```dart
enum AnomalyType {
  standMundur,
  excessiveHours,
  consumptionSpike,
  zeroConsumption,
}

enum AnomalySeverity {
  critical,
  medium,
  low,
}
```

---

## Utility Functions

### AnomalyUtils Class

Tersedia di: `lib/shared/utils/anomaly_utils.dart`

**Fungsi:**

- `getTypeName(AnomalyType)` - Nama jenis dalam Bahasa Indonesia
- `getSeverityName(AnomalySeverity)` - Nama level keparahan
- `getSeverityColor(AnomalySeverity)` - Warna untuk tampilan
- `getTypeIcon(AnomalyType)` - Icon untuk setiap jenis

**Contoh:**

```dart
final typeName = AnomalyUtils.getTypeName(AnomalyType.standMundur);  // "Stand Mundur"
final severity = AnomalyUtils.getSeverityName(AnomalySeverity.critical);  // "KRITIS"
final color = AnomalyUtils.getSeverityColor(AnomalySeverity.critical);  // Red
final icon = AnomalyUtils.getTypeIcon(AnomalyType.standMundur);  // Icons.trending_down
```

---

## Flow Pengguna

### Skenario Umum:

1. **Dashboard** - Lihat total anomali terdeteksi
2. **Klik Anomali** - Pilih tampilan (Statistik atau Daftar)
3. **Statistik View** - Analisis ringkasan dan breakdown
4. **Daftar View** - Lihat detail per anomali
5. **Tindak Lanjut** - Verifikasi lapangan atau klarifikasi pelanggan

---

## Rekomendasi Tindakan

| Jenis Anomali  | Keparahan | Tindakan                               | Timeline |
| -------------- | --------- | -------------------------------------- | -------- |
| Stand Mundur   | KRITIS    | Verifikasi fisik segera, periksa meter | 24 jam   |
| Jam Nyala >720 | SEDANG    | Cek pembacaan, verifikasi data         | 3-5 hari |
| Lonjakan >30%  | SEDANG    | Konfirmasi ke pelanggan, verifikasi    | 5-7 hari |
| Konsumsi Nol   | SEDANG    | Cek koneksi, verifikasi meter          | 2-3 hari |

---

## Notes

- Semua anomali disimpan dalam database dengan review flag
- Dapat ditandai sebagai "reviewed" setelah ditindaklanjuti
- Data retention sesuai 12-month rolling window
- Deteksi otomatis setiap kali import file Excel
