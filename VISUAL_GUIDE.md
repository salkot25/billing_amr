# 📊 Panduan Visual - Kategorisasi Anomali

## 🎯 Jenis Anomali dan Tampilan

### 1️⃣ Stand Mundur (Stand Meter Menurun)

```
┌─────────────────────────────────────┐
│ 📉 Stand Mundur                     │
│ Kategori: KRITIS                    │
├─────────────────────────────────────┤
│ Pelanggan: PT MAJU JAYA (123456)    │
│ Periode: 202501                     │
│ Terdeteksi: 30 Jan 2026 14:35       │
├─────────────────────────────────────┤
│ ⚠️  Stand LWBP mundur:              │
│    5000.00 → 4950.00                │
└─────────────────────────────────────┘
```

**Aksi:** 🚨 SEGERA verifikasi & periksa meter fisik

---

### 2️⃣ Jam Nyala Berlebih (>720 jam/bulan)

```
┌─────────────────────────────────────┐
│ ⏱️  Jam Nyala Berlebih               │
│ Kategori: SEDANG                    │
├─────────────────────────────────────┤
│ Pelanggan: CV MAJU LAKSANA (654321) │
│ Periode: 202501                     │
│ Terdeteksi: 30 Jan 2026 09:15       │
├─────────────────────────────────────┤
│ 📊 Jam nyala melebihi 720 jam:      │
│    745.5 jam                        │
└─────────────────────────────────────┘
```

**Aksi:** Cek pembacaan, verifikasi data dengan pelanggan

---

### 3️⃣ Lonjakan Konsumsi (>30% dari rata-rata)

```
┌─────────────────────────────────────┐
│ 📈 Lonjakan Konsumsi                │
│ Kategori: SEDANG                    │
├─────────────────────────────────────┤
│ Pelanggan: TOKO ELEKTRONIK (789012)│
│ Periode: 202501                     │
│ Terdeteksi: 30 Jan 2026 11:45       │
├─────────────────────────────────────┤
│ 📊 Konsumsi meningkat 45.2%         │
│    dari rata-rata (1250 kWh)        │
└─────────────────────────────────────┘
```

**Aksi:** Konfirmasi ke pelanggan, verifikasi penambahan beban

---

### 4️⃣ Konsumsi Nol (Tidak Ada Konsumsi)

```
┌─────────────────────────────────────┐
│ 🔌 Konsumsi Nol                     │
│ Kategori: SEDANG                    │
├─────────────────────────────────────┤
│ Pelanggan: RUMAH KOSONG (345678)    │
│ Periode: 202501                     │
│ Terdeteksi: 30 Jan 2026 08:20       │
├─────────────────────────────────────┤
│ ⚠️  Konsumsi nol untuk periode ini  │
└─────────────────────────────────────┘
```

**Aksi:** Cek koneksi listrik, verifikasi meterisasi

---

## 🎨 Sistem Warna & Kategori

### Keparahan Anomali

```
┌──────────┬────────────┬──────────┬─────────────────┐
│ Level    │ Warna      │ Ikon     │ Jenis Anomali   │
├──────────┼────────────┼──────────┼─────────────────┤
│ KRITIS   │ 🔴 Merah   │ ⚠️       │ Stand Mundur     │
├──────────┼────────────┼──────────┼─────────────────┤
│ SEDANG   │ 🟠 Oranye  │ ⚠️       │ 3 jenis lainnya │
├──────────┼────────────┼──────────┼─────────────────┤
│ RENDAH   │ 🟡 Kuning  │ ℹ️       │ (Future)        │
└──────────┴────────────┴──────────┴─────────────────┘
```

---

## 📊 Statistik Anomali - Layout

```
┌─────────────────────────────────────────────────────┐
│               STATISTIK ANOMALI                      │
├─────────────────────────────────────────────────────┤
│                                                      │
│   ┌──────────────┐ ┌──────────────┐                │
│   │ 📊 Total: 15 │ │ 🔴 Kritis: 3 │                │
│   └──────────────┘ └──────────────┘                │
│                                                      │
│   ┌──────────────┐ ┌──────────────┐                │
│   │ 🟠 Sedang: 12│ │ 🟡 Rendah: 0 │                │
│   └──────────────┘ └──────────────┘                │
│                                                      │
├─────────────────────────────────────────────────────┤
│                 JENIS ANOMALI                       │
│                                                      │
│  📉 Stand Mundur              3 (20%)               │
│  ⏱️  Jam Nyala Berlebih        5 (33%)               │
│  📈 Lonjakan Konsumsi         4 (27%)               │
│  🔌 Konsumsi Nol              3 (20%)               │
│                                                      │
├─────────────────────────────────────────────────────┤
│              KATEGORI KEPARAHAN                     │
│                                                      │
│  🔴 KRITIS                    3 (20%)               │
│  🟠 SEDANG                   12 (80%)               │
│                                                      │
├─────────────────────────────────────────────────────┤
│              DAFTAR DETAIL ANOMALI                  │
│                                                      │
│  [Anomali 1] [Anomali 2] [Anomali 3]               │
│  [Anomali 4] [Anomali 5] [Anomali 6]               │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## 🔄 User Navigation Flow

```
                    DASHBOARD
                        |
                        | Klik "Anomali Terdeteksi"
                        ↓
                  ┌─────────────┐
                  │ DIALOG MENU │
                  ├─────────────┤
                  │ • Statistik │ ←─────┐
                  │ • Daftar    │       │
                  └─────────────┘       │
                        |               │
            ┌───────────┴───────────┐   │
            ↓                       ↓   │
     ┌─────────────┐         ┌──────────────┐
     │ STATISTIK   │ ◄────── │ DAFTAR ANOMALI
     │ ANOMALI     │         │ (showAnomaliesOnly: true)
     │             │         │
     │ • Summary   │         │ • Anomali Card 1
     │   Cards     │         │ • Anomali Card 2
     │ • By Type   │         │ • Anomali Card 3
     │ • By        │         │ • ... (scrollable)
     │   Severity  │         │
     │ • Detail    │         │
     │   List      │         │
     └─────────────┘         └──────────────┘
```

---

## 📋 Checklist Tindaklanjut Anomali

### KRITIS (Stand Mundur)

```
☐ Notifikasi tim lapangan
☐ Jadwalkan kunjungan ke lokasi
☐ Periksa kondisi meter fisik
☐ Cek integritas seal/segel
☐ Verifikasi pembacaan meter
☐ Buat laporan investigasi
☐ Update status di sistem
```

### SEDANG (Jam/Lonjakan/Nol)

```
☐ Buat ticket tindaklanjut
☐ Hubungi pelanggan untuk konfirmasi
☐ Minta data pendukung dari pelanggan
☐ Cross-check dengan data historis
☐ Tentukan apakah perlu kunjungan
☐ Update keterangan anomali
☐ Close ticket setelah verifikasi
```

---

## 💡 Tips Penggunaan

### 1. **Prioritas Penanganan:**

- 🔴 KRITIS → Tangani dalam 24 jam
- 🟠 SEDANG → Tangani dalam 3-5 hari
- 🟡 RENDAH → Monitoring saja

### 2. **Filter Cepat:**

- Lihat statistik dulu untuk overview
- Sorting otomatis: KRITIS → SEDANG → RENDAH
- Newest anomali tampil di atas

### 3. **Export Data (Future):**

- Dashboard anomali bisa di-export ke PDF
- Cocok untuk laporan mingguan/bulanan

### 4. **Tracking Progress:**

- Mark anomali sebagai "reviewed" setelah ditindaklanjuti
- Monitor trend anomali dari waktu ke waktu

---

## 🎓 Contoh Skenario Real-World

### Skenario 1: Deteksi Stand Mundur

```
Waktu: 01-30-2026 14:35
Customer: PT JAYA SENTOSA (ID: 12345)

1. Sistem deteksi: Stand LWBP 5000 → 4950
   ↓
2. Anomali created dengan type: standMundur, severity: CRITICAL
   ↓
3. Dashboard badge: "Anomali Terdeteksi: 1"
   ↓
4. Analyst klik → Dialog → Pilih "Daftar"
   ↓
5. Lihat detail anomali dengan indikasi KRITIS (merah)
   ↓
6. Hubungi supervisor → Tugas lapangan ke lokasi
   ↓
7. Teknisi verifikasi meter → Temukan seal rusak
   ↓
8. Update dalam sistem → Mark as reviewed
```

### Skenario 2: Deteksi Lonjakan Konsumsi

```
Waktu: 01-29-2026 11:15
Customer: TOKO ELEKTRONIK (ID: 67890)

1. Sistem deteksi: Konsumsi +45% dari rata-rata
   ↓
2. Anomali created dengan type: consumptionSpike, severity: MEDIUM
   ↓
3. Analyst klik → Dialog → Pilih "Statistik"
   ↓
4. Lihat breakdown: 27% adalah lonjakan konsumsi
   ↓
5. Analyst hubungi pelanggan
   ↓
6. Pelanggan konfirmasi: Baru pasang AC baru
   ↓
7. Catat keterangan di sistem
   ↓
8. Mark as reviewed (normal/tidak perlu tindakan)
```

---

## 🔍 Troubleshooting

### Tidak Ada Anomali yang Muncul

```
✓ Pastikan sudah import data Excel
✓ Cek apakah ada data yang problematic
✓ Refresh dashboard (swipe down)
```

### Anomali Tidak Sesuai

```
✓ Lihat deskripsi detail di kartu anomali
✓ Cek kembali data source (Excel)
✓ Lihat documentation untuk penjelasan kriteria
```

### Tampilan Tidak Jelas

```
✓ Refresh page (hot reload)
✓ Cek ukuran layar (responsive design)
✓ Lihat di device yang berbeda
```

---

## 📞 Support

Untuk pertanyaan atau masalah:

- 📖 Baca dokumentasi: `ANOMALY_CATEGORIZATION.md`
- 💻 Check source code: `lib/features/anomalies/`
- 🐛 Report issue dengan tangkapan layar & scenario

---

**Terakhir diupdate:** 30 Januari 2026  
**Versi:** 1.0  
**Status:** ✅ Production Ready
