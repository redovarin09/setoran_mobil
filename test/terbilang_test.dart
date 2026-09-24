// Test kontrak M8 — dijalankan oleh CI, bukan lokal.
// Sumber: design-brief §10 (Semantics Amount).
import 'package:flutter_test/flutter_test.dart';
import 'package:setoran_mobil/core/utils/terbilang.dart';

void main() {
  group('terbilang rupiah (a11y)', () {
    test('nol', () {
      expect(terbilangRp(0), 'nol rupiah');
    });

    test('ratus ribu', () {
      expect(terbilangRp(700000), 'tujuh ratus ribu rupiah');
    });

    test('minus → awalan minus', () {
      expect(terbilangRp(-50000),
          'minus lima puluh ribu rupiah');
    });

    test('ribu dan juta', () {
      expect(terbilangRp(1500), 'seribu lima ratus rupiah');
      expect(terbilangRp(1000000), 'satu juta rupiah');
    });

    test('gabungan kompleks', () {
      expect(terbilangRp(2284584),
          'dua juta dua ratus delapan puluh empat ribu '
          'lima ratus delapan puluh empat rupiah');
    });
  });
}
