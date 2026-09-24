// Helper murni onboarding — bisa di-test tanpa Flutter.
// Sumber: docs/prd.md FR-2 (NQ-2 bebas+plat, E-15 tanpa dropdown tahun).
import '../../core/utils/week_helper.dart';

/// Kosong → 'Kendaraan Saya', selain itu trim.
String normalisasiJenis(String v) {
  final t = v.trim();
  return t.isEmpty ? 'Kendaraan Saya' : t;
}

/// digits-only; kosong/rusak → 0.
int parseNominal(String v) {
  final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
}

/// Label 7 chip jadwal hari — sumber tunggal di WeekHelper (core).
const List<String> labelJadwalHari = WeekHelper.hariPendek;
