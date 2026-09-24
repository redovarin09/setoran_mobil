// Test kontrak M5 — dijalankan oleh CI, bukan lokal.
// Sumber: PRD FR-15 (filter), FR-16 (urutan), FR-18 (tahun nota).
import 'package:flutter_test/flutter_test.dart';
import 'package:setoran_mobil/features/perbaikan/perbaikan_filter.dart';

void main() {
  group('filter perbaikan (FR-15)', () {
    test('kosong → semua cocok', () {
      expect(
        cocokFilter(
            jenis: 'Oli',
            bengkel: 'Shell',
            keterangan: '',
            tanggal: '01/02/2026',
            query: ''),
        isTrue,
      );
    });

    test('contains case-insensitive jenis/bengkel/keterangan', () {
      bool f(String q) => cocokFilter(
            jenis: 'Servis Rutin',
            bengkel: 'Bengkel Jaya',
            keterangan: 'ganti kampas',
            tanggal: '15/01/2026',
            query: q,
          );
      expect(f('servis'), isTrue);
      expect(f('JAYA'), isTrue);
      expect(f('kampas'), isTrue);
      expect(f('rem'), isFalse);
    });

    test('tanggal cocok substring apa adanya', () {
      expect(
        cocokFilter(
            jenis: 'Oli',
            bengkel: '',
            keterangan: '',
            tanggal: '15/01/2026',
            query: '15/01'),
        isTrue,
      );
    });
  });
}
