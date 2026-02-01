# PLN Billing AMR (Automated Meter Reading)

Aplikasi Flutter standalone untuk pemeriksaan dan monitoring data stand meter pelanggan PLN.

## Fitur

- **Import Data Excel**: Import file Excel bulanan dengan format PLN (102 kolom)
- **Dashboard Ringkas**: Menampilkan jumlah pelanggan aktif dan total RPTAG bulan terbaru
- **Deteksi Anomali Otomatis**:
  - Stand mundur (meter reading menurun) - CRITICAL
  - Jam nyala > 720 jam/bulan - MEDIUM
  - Konsumsi meningkat > 30% dari rata-rata 12 bulan - MEDIUM
  - Konsumsi nol - MEDIUM
- **Riwayat 12 Bulan**: Menyimpan dan menampilkan data 12 bulan terakhir per pelanggan
- **Pencarian Pelanggan**: Cari berdasarkan ID Pelanggan atau Nama
- **Read-Only**: Aplikasi hanya untuk viewing, tidak ada fitur edit/koreksi

## Struktur Aplikasi

```
lib/
├── main.dart                          # Entry point aplikasi
├── features/                          # Feature modules
│   ├── dashboard/                     # Dashboard screen
│   │   └── dashboard_screen.dart
│   ├── billing_records/               # Billing records & customer detail
│   │   └── billing_records_screen.dart
│   └── import_excel/                  # Excel import & anomaly detection
│       ├── excel_import_service.dart
│       └── anomaly_detection_service.dart
├── shared/                            # Shared resources
│   ├── models/                        # Data models
│   │   ├── billing_record.dart
│   │   ├── customer.dart
│   │   ├── import_record.dart
│   │   └── anomaly_flag.dart
│   └── widgets/                       # Reusable widgets
└── core/                              # Core functionality
    ├── database/                      # Database layer
    │   └── database_helper.dart
    ├── providers/                     # Riverpod providers
    │   └── app_providers.dart
    └── constants/                     # App constants
```

## Teknologi

- **Framework**: Flutter 3.10+
- **State Management**: Riverpod 2.6+
- **Database**: SQLite (sqflite)
- **Excel Parsing**: excel package
- **File Picker**: file_picker
- **Formatting**: intl (Indonesian locale)

## Database Schema

### Tables

1. **customers**: Data pelanggan (customer_id, nama, alamat, tariff, power_capacity)
2. **billing_records**: Record billing bulanan (customer_id + billing_period UNIQUE)
3. **imports**: Log import Excel
4. **anomaly_flags**: Flags anomali terdeteksi

### Auto-Retention

Data lebih dari 12 bulan otomatis terhapus setiap kali import baru.

## Cara Penggunaan

### 1. Import Data Excel

1. Klik tombol **"Import Data Excel"** di Dashboard
2. Pilih file Excel dengan format PLN
3. Aplikasi akan parse, validasi, upsert, dan deteksi anomali
4. Dialog hasil import menampilkan status dan error log (jika ada)

### 2. Lihat Dashboard

Dashboard menampilkan ringkasan bulan terbaru:

- **Jumlah Pelanggan Aktif**: Total customer dengan data bulan terbaru
- **Total RPTAG**: Sum RPTAG semua pelanggan bulan terbaru
- **Anomali Terdeteksi**: Jumlah anomali yang belum direview

### 3. Lihat Data Pelanggan

1. Klik **"Lihat Semua Data Pelanggan"**
2. Gunakan search bar untuk cari pelanggan (by ID atau Nama)
3. Klik pelanggan untuk lihat riwayat 12 bulan billing

## Format Excel Import

### Kolom Essential

- **THBLREK**: Periode billing (YYYYMM, contoh: 202602)
- **IDPEL**: ID Pelanggan
- **NAMA, ALAMAT, TARIF, DAYA**: Data pelanggan
- **SAHLWBP, SLALWBP**: Stand LWBP (off-peak)
- **SAHWBP, SLAWBP**: Stand WBP (peak)
- **KWHLWBP, KWHWBP**: Konsumsi
- **JAMNYALA**: Jam operasi
- **RPTAG**: Total tagihan

### Upsert Logic

- Jika **IDPEL + THBLREK** sudah ada → **UPDATE**
- Jika belum ada → **INSERT**

## Deteksi Anomali

1. **Stand Mundur** (CRITICAL): SAHLWBP < SLALWBP atau SAHWBP < SLAWBP
2. **Jam Nyala Berlebih** (MEDIUM): JAMNYALA > 720
3. **Konsumsi Spike** (MEDIUM): > 30% dari rata-rata 12 bulan
4. **Konsumsi Nol** (MEDIUM): Total konsumsi = 0

## Development

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Build
flutter build apk --release  # Android
flutter build windows --release  # Windows
```
