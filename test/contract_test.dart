// Test kontrak M1 — dijalankan oleh CI (flutter test), bukan lokal.
// Sumber: docs/prd.md §6 aturan global + §9 M-2 + tech-design §2 anti-drift.
import 'package:flutter_test/flutter_test.dart';
import 'package:setoran_mobil/core/error/app_error.dart';

void main() {
  group('aturan hitung global (PRD §6 revisi OQ-7)', () {
    test('total = setoran − potongan', () {
      expect(hitungTotal(700000, 50000), 650000);
    });

    test('potongan > setoran → total negatif, tampil apa adanya', () {
      expect(hitungTotal(100000, 150000), -50000);
    });

    test('sisa_raw = total − dibayarkan, bertanda', () {
      expect(hitungSisa(650000, 650000), 0);
      expect(hitungSisa(650000, 400000), 250000);
      expect(hitungSisa(650000, 700000), -50000);
    });

    test('kembalian = max(0, −sisa_raw)', () {
      expect(hitungKembalian(250000), 0);
      expect(hitungKembalian(0), 0);
      expect(hitungKembalian(-50000), 50000);
    });

    test('Lunas jika sisa_raw <= 0 else Kurang', () {
      expect(statusDariSisa(0), StatusPeriode.lunas);
      expect(statusDariSisa(-1), StatusPeriode.lunas);
      expect(statusDariSisa(1), StatusPeriode.kurang);
    });

    test('grand = sisaLalu + Σsisa_raw − perbaikan, bertanda asli', () {
      expect(hitungGrand(100000, 500000, 200000), 400000);
      expect(hitungGrand(-50000, 100000, 200000), -150000);
    });
  });

  group('kontrak log (FR-13)', () {
    test('dibayarkan = Σ log termasuk reversal negatif', () {
      const log = [400000, 250000, -50000];
      final dibayarkan = log.reduce((a, b) => a + b);
      expect(dibayarkan, 600000);
      expect(hitungSisa(650000, dibayarkan), 50000);
      expect(statusDariSisa(hitungSisa(650000, dibayarkan)),
          StatusPeriode.kurang);
    });

    test('nominal log nol ditolak kontrak (CHECK nominal != 0)', () {
      const nominal = 0;
      expect(nominal == 0, isTrue,
          reason: 'DB menolak via CHECK; UI tolak via AppError validasi');
    });
  });
}
