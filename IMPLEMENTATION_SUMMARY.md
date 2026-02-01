# Implementasi Kategorisasi Jenis Anomali - Ringkasan

**Tanggal:** 30 Januari 2026  
**Status:** ✅ Selesai dan teruji

---

## 📋 Ringkasan Perubahan

Sistem PLN Billing AMR sekarang memiliki **kategorisasi anomali yang lengkap dan terstruktur** dengan tampilan yang intuitif untuk membantu analyst mencegah dan menindaklanjuti masalah billing secara efektif.

---

## 🎯 Yang Diimplementasikan

### 1. **Utility Untuk Kategorisasi Anomali**

📄 File: `lib/shared/utils/anomaly_utils.dart`

```dart
class AnomalyUtils {
  static String getTypeName(AnomalyType type)           // Nama jenis dalam Bahasa Indonesia
  static String getSeverityName(AnomalySeverity sev)    // Nama level keparahan
  static Color getSeverityColor(AnomalySeverity sev)    // Warna visual per kategori
  static IconData getTypeIcon(AnomalyType type)         // Ikon untuk setiap jenis
}
```

**Jenis Anomali yang Dikategorikan:**

- 🔴 **Stand Mundur** (KRITIS) - Stand meter menurun dari periode sebelumnya
- 🟠 **Jam Nyala Berlebih** (SEDANG) - Jam operasi > 720 jam/bulan
- 🟠 **Lonjakan Konsumsi** (SEDANG) - Konsumsi > 30% dari rata-rata 12 bulan
- 🟠 **Konsumsi Nol** (SEDANG) - Tidak ada konsumsi dalam periode

### 2. **Layar Statistik Anomali**

📄 File: `lib/features/anomalies/anomaly_statistics_screen.dart`

**Fitur:**

- ✅ Ringkasan 4 kartu (Total, Kritis, Sedang, Rendah)
- ✅ Breakdown per jenis anomali dengan persentase
- ✅ Breakdown per kategori keparahan dengan persentase
- ✅ Daftar detail anomali dengan informasi lengkap

**Komponen:**

- `AnomalyStatisticsScreen` - Main screen
- `_AnomalySummaryCards` - Kartu ringkasan
- `_AnomaliesByTypeSection` - Statistik per jenis
- `_AnomaliesBySeveritySection` - Statistik per keparahan
- `_AnomaliesDetailedListSection` - Daftar detail

### 3. **Pembaruan Layar Daftar Anomali**

📄 File: `lib/features/billing_records/billing_records_screen.dart`

**Perubahan:**

- ✅ Pisah tampilan pelanggan dan anomali berdasarkan `showAnomaliesOnly` flag
- ✅ Tambah method `_buildAnomaliesView()` untuk tampilan anomali
- ✅ Implementasi `_AnomalyCard` widget untuk tampilan detail anomali

**Widget Baru:**

```dart
class _AnomalyCard {
  // Menampilkan:
  // - Icon dan jenis anomali
  // - Level keparahan dengan warna
  // - Info pelanggan (nama, ID)
  // - Periode billing
  // - Waktu terdeteksi
  // - Deskripsi detail
}
```

### 4. **Dialog Pilihan Tampilan Anomali**

📄 File: `lib/features/dashboard/dashboard_screen.dart`

**Perubahan:**

- ✅ Tombol "Anomali Terdeteksi" di dashboard menampilkan dialog pilihan
- ✅ Opsi: "Statistik" atau "Daftar"
- ✅ Navigasi ke layar yang sesuai

```
Dashboard
    ↓
[Anomali Terdeteksi] → Dialog Pilihan
    ├─ Statistik → AnomalyStatisticsScreen
    └─ Daftar → BillingRecordsScreen (showAnomaliesOnly: true)
```

---

## 📊 Struktur Kategori Anomali

### Jenis Anomali (AnomalyType)

```
stanMundur              → "Stand Mundur"
excessiveHours          → "Jam Nyala Berlebih"
consumptionSpike        → "Lonjakan Konsumsi"
zeroConsumption         → "Konsumsi Nol"
```

### Level Keparahan (AnomalySeverity)

```
critical  (Kritis)  → 🔴 Red (#D32F2F)     → Stand Mundur
medium    (Sedang)  → 🟠 Orange (#F57C00)  → Jam, Lonjakan, Nol
low       (Rendah)  → 🟡 Yellow (#FBC02D)  → Future use
```

### Visual Indicators

- **Ikon:** Trending Down, Schedule, Trending Up, Power Off
- **Warna:** Sesuai severity level
- **Label:** Indonesian language display names

---

## 🔄 User Flow

### Dari Dashboard:

```
1. Lihat badge "Anomali Terdeteksi: X" di dashboard
2. Klik badge → Dialog pilihan tampilan
3. Pilih "Statistik" → Lihat analisis ringkasan dan breakdown
4. Atau pilih "Daftar" → Lihat detail per anomali
```

### Di Statistik Screen:

```
- Ringkasan dengan 4 metrik
- Grafik breakdown per jenis (dengan %)
- Grafik breakdown per keparahan (dengan %)
- Daftar detail anomali scrollable
```

### Di Daftar Screen:

```
- List anomali dengan kartu detail
- Setiap kartu menampilkan:
  - Jenis & kategori keparahan
  - Info pelanggan
  - Periode & waktu terdeteksi
  - Deskripsi lengkap
```

---

## 📁 File yang Dibuat/Diubah

### File Baru:

```
lib/shared/utils/anomaly_utils.dart              [150 lines]
lib/features/anomalies/anomaly_statistics_screen.dart  [488 lines]
ANOMALY_CATEGORIZATION.md                        [Dokumentasi lengkap]
```

### File Diubah:

```
lib/features/billing_records/billing_records_screen.dart
  - Import anomaly_flag & anomaly_utils
  - Refactor build() → _buildCustomersView() & _buildAnomaliesView()
  - Tambah _AnomalyCard widget

lib/features/dashboard/dashboard_screen.dart
  - Import AnomalyStatisticsScreen
  - Update onTap anomaly card → Dialog pilihan

lib/shared/models/anomaly_flag.dart
  - Tetap sama (sudah ada AnomalyType & AnomalySeverity enums)
```

---

## ✅ Quality Assurance

### Testing:

- ✅ Flutter analyze: **No issues found**
- ✅ All imports resolved
- ✅ No unused variables
- ✅ Proper error handling in UI
- ✅ Responsive layout (tested with LayoutBuilder)

### Deprecated Fixes:

- ✅ Replaced `withOpacity(0.1)` with `withValues(alpha: 0.1)` (3 occurrences)

### Code Style:

- ✅ Consistent formatting
- ✅ Indonesian labels throughout
- ✅ Proper widget hierarchy
- ✅ Efficient state management with Riverpod

---

## 🚀 Cara Menggunakan

### 1. **Lihat Statistik Anomali:**

```
Dashboard → [Anomali Terdeteksi] → Dialog → Pilih "Statistik"
```

### 2. **Lihat Daftar Anomali:**

```
Dashboard → [Anomali Terdeteksi] → Dialog → Pilih "Daftar"
```

### 3. **Detail Anomali:**

- Setiap anomali menampilkan:
  - Jenis dan kategori keparahan
  - Pelanggan (nama & ID)
  - Periode billing
  - Deskripsi detail masalah

### 4. **Rekomendasi Tindakan:**

Lihat file `ANOMALY_CATEGORIZATION.md` untuk:

- Penjelasan lengkap setiap jenis anomali
- Timeline tindaklanjut yang disarankan
- Panduan verifikasi lapangan

---

## 📚 Dokumentasi

### File Referensi:

📄 **ANOMALY_CATEGORIZATION.md** (Dokumentasi lengkap)

- Penjelasan detail setiap jenis anomali
- Kategori keparahan dan warna
- Proses deteksi otomatis
- Struktur data model
- Rekomendasi tindakan

---

## 🔧 Maintenance Notes

### Adding New Anomaly Type:

1. Update `AnomalyType` enum di `anomaly_flag.dart`
2. Update `AnomalyUtils` di `anomaly_utils.dart`
3. Update `_checkRecordAnomalies()` di `anomaly_detection_service.dart`

### Customizing Colors:

```dart
// Edit di AnomalyUtils.getSeverityColor()
case AnomalySeverity.critical:
  return const Color(0xFFD32F2F); // Customize here
```

### Adding New Severity Level:

1. Update `AnomalySeverity` enum
2. Update `getSeverityName()` & `getSeverityColor()` di `AnomalyUtils`
3. Update UI conditionals yang menggunakan severity

---

## 📈 Future Enhancements

Fitur yang bisa ditambahkan di masa depan:

- [ ] Export anomali ke PDF/Excel
- [ ] Mark anomali as "reviewed"
- [ ] Filter anomali per jenis
- [ ] Sort anomali per tanggal/pelanggan
- [ ] Anomali history (trend analysis)
- [ ] Email notification untuk KRITIS
- [ ] SLA tracking untuk tindaklanjut

---

## 🎓 Technical Details

### Riverpod Integration:

```dart
final anomaliesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(databaseProvider);
  return await db.getAnomaliesWithRecords();
});
```

### Database Query:

```sql
SELECT af.*, br.customer_id, br.billing_period, c.nama
FROM anomaly_flags af
INNER JOIN billing_records br ON af.billing_record_id = br.id
INNER JOIN customers c ON br.customer_id = c.customer_id
WHERE af.reviewed = 0
ORDER BY af.severity DESC, af.flagged_at DESC
```

---

## ✨ Hasil Akhir

✅ **Sistem kategorisasi anomali lengkap dan functional**

- 4 jenis anomali dengan kategori jelas
- 2 level keparahan (Kritis, Sedang)
- Visual indicators yang intuitif
- 2 mode tampilan (Statistik & Daftar)
- Dokumentasi lengkap
- Code quality: No issues (flutter analyze)

---

**Status:** Siap untuk testing dengan data sebenarnya  
**Next Step:** Import data Excel untuk validasi deteksi anomali
