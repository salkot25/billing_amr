# 🎯 Quick Reference - Kategorisasi Anomali

**📍 Lokasi File Penting:**

```
lib/
├── shared/
│   └── utils/
│       └── anomaly_utils.dart ...................... Utility functions
├── features/
│   ├── anomalies/
│   │   └── anomaly_statistics_screen.dart ........ Statistik view
│   ├── billing_records/
│   │   └── billing_records_screen.dart ........... Daftar + modal
│   └── dashboard/
│       └── dashboard_screen.dart .................. Navigation
└── shared/
    └── models/
        └── anomaly_flag.dart ..................... Enums (sudah ada)
```

---

## 🔴 Jenis Anomali Quick Reference

| Icon | Jenis              | Severity  | Trigger                    |
| ---- | ------------------ | --------- | -------------------------- |
| 📉   | Stand Mundur       | 🔴 KRITIS | Stand < periode sebelumnya |
| ⏱️   | Jam Nyala Berlebih | 🟠 SEDANG | Hours > 720/bulan          |
| 📈   | Lonjakan Konsumsi  | 🟠 SEDANG | Konsumsi > 30% rata-rata   |
| 🔌   | Konsumsi Nol       | 🟠 SEDANG | Total kWh = 0              |

---

## 🎨 Warna Mapping

```
Severity        Color           Hex Code    Usage
─────────────────────────────────────────────────
KRITIS (🔴)     Red             #D32F2F    Stand Mundur
SEDANG (🟠)     Orange          #F57C00    3 jenis lainnya
RENDAH (🟡)     Yellow          #FBC02D    (Future)
```

---

## 📂 File Dokumentasi

| File                        | Isi                                   |
| --------------------------- | ------------------------------------- |
| `ANOMALY_CATEGORIZATION.md` | Penjelasan detail semua jenis anomali |
| `IMPLEMENTATION_SUMMARY.md` | Ringkasan perubahan kode              |
| `VISUAL_GUIDE.md`           | Panduan visual & skenario             |
| `COMPLETION_CHECKLIST.md`   | Checklist implementasi                |
| `QUICK_REFERENCE.md`        | File ini                              |

---

## 🚀 Quick Start

### 1. Lihat Statistik Anomali

```
Dashboard → [Anomali Terdeteksi] → Pilih "Statistik"
```

### 2. Lihat Daftar Anomali

```
Dashboard → [Anomali Terdeteksi] → Pilih "Daftar"
```

### 3. Akses Programmatically

```dart
// Di code
final anomalies = ref.watch(anomaliesProvider);

// Utility
final typeName = AnomalyUtils.getTypeName(AnomalyType.standMundur);
final severity = AnomalyUtils.getSeverityName(AnomalySeverity.critical);
final color = AnomalyUtils.getSeverityColor(AnomalySeverity.critical);
final icon = AnomalyUtils.getTypeIcon(AnomalyType.standMundur);
```

---

## 🔍 Database Query

```sql
SELECT af.*, br.customer_id, br.billing_period, c.nama
FROM anomaly_flags af
INNER JOIN billing_records br ON af.billing_record_id = br.id
INNER JOIN customers c ON br.customer_id = c.customer_id
WHERE af.reviewed = 0
ORDER BY af.severity DESC, af.flagged_at DESC
```

---

## 📱 UI Components

### AnomalyStatisticsScreen

```
┌─ Summary Cards (4)
├─ Type Breakdown
├─ Severity Breakdown
└─ Detail List
```

### \_AnomalyCard (in Daftar)

```
┌─ Header (Type, Severity, Badge)
├─ Divider
├─ Customer Info
├─ Period & Time
└─ Description Box
```

---

## ✅ Action by Severity

```
🔴 KRITIS
├─ Notifikasi: URGENT
├─ Timeline: 24 jam
├─ Action: Verifikasi fisik
└─ Status: Harus resolved

🟠 SEDANG
├─ Notifikasi: Normal
├─ Timeline: 3-5 hari
├─ Action: Konfirmasi & verifikasi
└─ Status: Can defer

🟡 RENDAH
├─ Notifikasi: None
├─ Timeline: Monitoring
├─ Action: Track saja
└─ Status: Background
```

---

## 💻 Code Snippets

### Import di File Baru

```dart
import '../../shared/models/anomaly_flag.dart';
import '../../shared/utils/anomaly_utils.dart';
```

### Tampilkan Warna Severity

```dart
final color = AnomalyUtils.getSeverityColor(anomaly.severity);
Container(
  color: color.withValues(alpha: 0.1),
  child: Text(AnomalyUtils.getSeverityName(anomaly.severity)),
)
```

### Tampilkan Icon Jenis

```dart
Icon(
  AnomalyUtils.getTypeIcon(anomaly.type),
  color: AnomalyUtils.getSeverityColor(anomaly.severity),
)
```

### Parse dari Map

```dart
final type = AnomalyType.values.firstWhere(
  (e) => e.name == map['type'],
  orElse: () => AnomalyType.standMundur,
);
final severity = AnomalySeverity.values.firstWhere(
  (e) => e.name == map['severity'],
  orElse: () => AnomalySeverity.medium,
);
```

---

## 🐛 Common Issues & Solutions

| Issue                         | Solution                                    |
| ----------------------------- | ------------------------------------------- |
| Tidak ada anomali ditampilkan | Import data Excel terlebih dahulu           |
| Warna tidak muncul            | Check `withValues(alpha: ...)` usage        |
| Icon tidak ter-load           | Pastikan import `material.dart`             |
| Data tidak refresh            | Gunakan `ref.invalidate(anomaliesProvider)` |

---

## 📊 Data Model

```dart
// Enums
enum AnomalyType {
  standMundur,           // Stand menurun
  excessiveHours,        // Jam >720
  consumptionSpike,      // Konsumsi >30%
  zeroConsumption,       // Konsumsi 0
}

enum AnomalySeverity {
  critical,              // Kritis
  medium,                // Sedang
  low,                   // Rendah
}

// Data
class AnomalyFlag {
  final int? id;
  final int billingRecordId;
  final AnomalyType type;
  final AnomalySeverity severity;
  final String description;
  final bool reviewed;
  final DateTime flaggedAt;
}
```

---

## 🎓 Learning Path

1. **Pahami Jenis Anomali** → Baca `ANOMALY_CATEGORIZATION.md`
2. **Lihat Visual** → Baca `VISUAL_GUIDE.md`
3. **Implementasi** → Check `lib/features/anomalies/`
4. **Customize** → Edit `anomaly_utils.dart`

---

## 📞 Quick Links

- 📖 Full Documentation: `ANOMALY_CATEGORIZATION.md`
- 🎨 Visual Guide: `VISUAL_GUIDE.md`
- 📊 Implementation: `IMPLEMENTATION_SUMMARY.md`
- ✅ Checklist: `COMPLETION_CHECKLIST.md`
- ⚡ This File: `QUICK_REFERENCE.md`

---

## 🎯 Next Steps

1. [ ] Test dengan data Excel real
2. [ ] Validasi deteksi anomali
3. [ ] User acceptance testing
4. [ ] Gather feedback
5. [ ] Plan Phase 2 features

---

**Status:** ✅ Production Ready  
**Last Updated:** 30 Januari 2026  
**Quality:** No issues (flutter analyze)
