// Test kontrak M4 — dijalankan oleh CI, bukan lokal.
// Sumber: PRD FR-10 (jadwal dinamis), FR-13 (log), OQ-7 (tanpa clamp).
import 'package:flutter_test/flutter_test.dart';
import 'package:setoran_mobil/core/utils/week_helper.dart';
import 'package:setoran_mobil/models/setoran_model.dart';

void main() {
  group('jadwal jatuh tempo dinamis (FR-10)', () {
    test('Minggu Februari 2026 = 4', () {
      expect(WeekHelper.jumlahJatuhTempo(0, 2, 2026), 4);
      expect(WeekHelper.jumlahMinggu(2, 2026), 4);
    });

    test('Senin Februari 2026 = 4, jatuh tempo ke-1 = 2 Feb', () {
      expect(WeekHelper.jumlahJatuhTempo(1, 2, 2026), 4);
      expect(
        WeekHelper.tanggalJatuhTempo(1, 1, 2, 2026),
        DateTime(2026, 2, 2),
      );
    });

    test('Minggu pertama Feb 2026 = 1 Feb', () {
      expect(
        WeekHelper.tanggalJatuhTempo(1, 0, 2, 2026),
        DateTime(2026, 2, 1),
      );
    });

    test('label 7 hari dari sumber tunggal', () {
      expect(WeekHelper.hariPendek.length, 7);
      expect(WeekHelper.hariPendek.first, 'Min');
    });
  });

  group('setoran tanpa clamp (OQ-7)', () {
    test('overpay → sisa minus + Lunas', () {
      final m = SetoranModel.hitung(
        mingguKe: 1,
        bulan: 2,
        tahun: 2026,
        tanggal: '01/02/2026',
        setoran: 700000,
        dibayarkan: 750000,
      );
      expect(m.sisa, -50000);
      expect(m.keterangan, 'Lunas');
    });

    test('dibayarkan = Σ log (cicil 3x + reversal)', () {
      const logs = [400000, 250000, -50000];
      final dibayarkan = logs.reduce((a, b) => a + b);
      final m = SetoranModel.hitung(
        mingguKe: 1,
        bulan: 2,
        tahun: 2026,
        tanggal: '01/02/2026',
        setoran: 700000,
        dibayarkan: dibayarkan,
      );
      expect(m.dibayarkan, 600000);
      expect(m.sisa, 100000);
      expect(m.keterangan, 'Kurang');
    });
  });
}
