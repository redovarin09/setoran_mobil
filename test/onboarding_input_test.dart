// Test kontrak M2 — dijalankan oleh CI, bukan lokal.
// Sumber: docs/prd.md FR-2 (NQ-2, E-15).
import 'package:flutter_test/flutter_test.dart';
import 'package:setoran_mobil/features/onboarding/onboarding_input.dart';

void main() {
  group('onboarding input (FR-2)', () {
    test('kosong jenis → Kendaraan Saya', () {
      expect(normalisasiJenis(''), 'Kendaraan Saya');
      expect(normalisasiJenis('   '), 'Kendaraan Saya');
      expect(normalisasiJenis('  Avanza '), 'Avanza');
    });

    test('kosong nominal → 0; digit-only', () {
      expect(parseNominal(''), 0);
      expect(parseNominal('700000'), 700000);
      expect(parseNominal('Rp 1.500.000'), 1500000);
      expect(parseNominal('abc'), 0);
    });

    test('label jadwal 7 hari, index 0=Minggu', () {
      expect(labelJadwalHari.length, 7);
      expect(labelJadwalHari.first, 'Min');
      expect(labelJadwalHari[4], 'Kam');
    });
  });
}
