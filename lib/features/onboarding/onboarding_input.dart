// Helper murni onboarding — bisa di-test tanpa Flutter.
// Sumber: docs/prd.md FR-2 (NQ-2 bebas+plat, E-15 tanpa dropdown tahun).

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

/// Label 7 chip jadwal hari, index 0=Minggu..6=Sabtu (tech-design §1).
const List<String> labelJadwalHari = [
  'Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab',
];
