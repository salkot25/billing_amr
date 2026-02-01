# Panduan Fitur Pencarian dan Filter Data Anomali

## Gambaran Umum

Fitur pencarian dan filter memungkinkan pengguna untuk menemukan anomali spesifik dengan cepat dan mudah. Fitur ini tersedia di dua layar utama:

1. **Dashboard Anomali** - Pencarian dengan filter severity, type, dan date range
2. **Data Anomali** (di Billing Records) - Pencarian sederhana berdasarkan customer

---

## 1. Dashboard Anomali (Pencarian Lanjutan)

### Akses

Navigasi ke `Dashboard Anomali` dari menu utama aplikasi.

### Fitur Pencarian

#### a) **Search Bar**

- **Fungsi**: Cari anomali berdasarkan nama pelanggan, ID pelanggan, atau deskripsi masalah
- **Cara Menggunakan**:
  1. Ketik kata kunci di kolom pencarian
  2. Hasil akan difilter secara real-time
  3. Klik tombol ✕ untuk menghapus pencarian

**Contoh Pencarian**:

- "Pelanggan ABC" → Cari berdasarkan nama pelanggan
- "CUST001" → Cari berdasarkan ID pelanggan
- "Stand mundur" → Cari berdasarkan deskripsi masalah

---

### Fitur Filter

#### a) **Filter Keparahan (Severity)**

Filter anomali berdasarkan tingkat keparahan:

| Filter | Warna  | Keterangan                                          |
| ------ | ------ | --------------------------------------------------- |
| KRITIS | Merah  | Anomali yang memerlukan tindakan segera             |
| SEDANG | Oranye | Anomali yang perlu ditindaklanjuti dalam 3-5 hari   |
| RENDAH | Kuning | Anomali yang dapat ditindaklanjuti sesuai prioritas |

**Cara Menggunakan**:

1. Lihat chip filter di bawah kolom pencarian dengan label "Keparahan:"
2. Klik satu atau lebih chip untuk memilih severity
3. Data akan difilter sesuai pilihan
4. Klik lagi untuk membatalkan filter

#### b) **Filter Jenis Anomali (Type)**

Filter anomali berdasarkan jenisnya:

| Jenis              | Icon | Keterangan                                |
| ------------------ | ---- | ----------------------------------------- |
| Stand Mundur       | 📉   | Penurunan konsumsi yang abnormal          |
| Jam Nyala Berlebih | ⏱️   | Waktu operasi yang berlebihan             |
| Lonjakan Konsumsi  | 📈   | Peningkatan konsumsi yang tiba-tiba       |
| Konsumsi Nol       | ⏻️    | Tidak ada konsumsi dalam periode tertentu |

**Cara Menggunakan**:

1. Lihat chip filter di bawah "Keparahan:" dengan label "Jenis Anomali:"
2. Klik satu atau lebih chip untuk memilih jenis
3. Data akan difilter sesuai pilihan

#### c) **Filter Rentang Tanggal (Date Range)**

Filter anomali berdasarkan periode waktu terdeteksinya.

**Cara Menggunakan**:

1. Klik tombol "Pilih Rentang Tanggal"
2. Pilih tanggal awal dan akhir di kalender yang muncul
3. Klik "OK" untuk menerapkan filter
4. Klik ✕ untuk menghapus filter tanggal

---

### Kombinasi Filter

Anda dapat menggabungkan semua filter sekaligus:

**Contoh**:

- Search: "Pelanggan ABC"
- Severity: KRITIS
- Type: Lonjakan Konsumsi
- Date: 1 Jan 2026 - 30 Jan 2026

Hasil akan menampilkan hanya anomali yang memenuhi semua kriteria.

---

### Informasi Hasil Filter

Di bawah filter bar, Anda akan melihat:

```
Menampilkan 5 dari 20 anomali
```

Ini menunjukkan:

- **5** = Anomali yang memenuhi kriteria filter
- **20** = Total semua anomali

Jika tidak ada anomali yang cocok:

```
Tidak ada anomali yang sesuai dengan filter
```

---

## 2. Data Anomali (Pencarian Dasar)

### Akses

Navigasi ke `Data Anomali` melalui navigasi bawah atau dari customer detail page.

### Fitur Pencarian

#### **Search Bar**

Cari anomali dengan kriteria:

- Nama pelanggan
- ID pelanggan
- Deskripsi masalah

**Cara Menggunakan**:

1. Ketik kata kunci di kolom pencarian
2. Hasil akan difilter secara otomatis
3. Klik ✕ untuk menghapus pencarian

**Informasi Hasil**:

```
Ditemukan 3 dari 15 anomali
```

Jika tidak ada hasil:

```
Tidak ada anomali yang sesuai
```

---

## Tips dan Trik

### 1. **Pencarian Cepat**

- Gunakan ID pelanggan untuk hasil yang lebih spesifik
- Gunakan nama pelanggan untuk pencarian yang lebih luas

### 2. **Kombinasi Filter Efektif**

- **Untuk Audit**: Filter `KRITIS` + date range spesifik
- **Untuk Follow-up**: Filter `SEDANG` + `RENDAH` + date range 7 hari terakhir
- **Untuk Analisis**: Pilih satu jenis anomali + semua severity

### 3. **Reset Filter**

- Klik ✕ pada setiap filter untuk menghapusnya
- Atau clear search bar untuk reset pencarian
- Klik ✕ pada tombol date range untuk reset tanggal

### 4. **Performa**

Aplikasi akan otomatis menampilkan statistik berdasarkan hasil filter:

- Summary cards terbaru
- Grafik jenis anomali (filtered)
- Grafik keparahan (filtered)
- Daftar detail anomali (filtered)

---

## Skema Warna Filter

### Severity

- 🔴 **KRITIS** (#D32F2F) - Merah
- 🟠 **SEDANG** (#F57C00) - Oranye
- 🟡 **RENDAH** (#FBC02D) - Kuning

### Type

- Blue untuk semua jenis anomali

---

## Status Implementasi

✅ Fitur pencarian di Dashboard Anomali
✅ Fitur filter severity (KRITIS, SEDANG, RENDAH)
✅ Fitur filter type (Stand Mundur, Jam Nyala Berlebih, dll)
✅ Fitur filter date range
✅ Fitur pencarian di Data Anomali
✅ Tampilan statistik yang dinamis sesuai filter

---

## Troubleshooting

### Q: Tidak ada anomali yang ditampilkan?

**A**:

1. Pastikan kriteria filter tidak terlalu ketat
2. Coba hapus filter tanggal terlebih dahulu
3. Reset semua filter dengan mengklik ✕
4. Pastikan ada data anomali di sistem

### Q: Pencarian lambat?

**A**:

1. Pencarian adalah real-time, jadi hasil langsung muncul
2. Jika aplikasi terasa lambat, coba restart aplikasi
3. Pastikan tidak ada proses berat lain yang sedang berjalan

### Q: Bagaimana cara melihat semua anomali?

**A**:

1. Hapus semua kata kunci di search bar
2. Hapus semua filter dengan klik ✕
3. Jangan pilih rentang tanggal
4. Dashboard akan menampilkan semua anomali

---

## Versi

- **v1.0** - Release awal dengan fitur search, filter severity, type, dan date range
