// Test kontrak M7 — dijalankan oleh CI, bukan lokal.
// Sumber: PRD E-20 (sanitasi), E-23 (versi 2).
import 'package:flutter_test/flutter_test.dart';
import 'package:setoran_mobil/core/error/app_error.dart';
import 'package:setoran_mobil/core/utils/backup.dart';

void main() {
  group('sanitasi nama file (E-20)', () {
    test('spasi & simbol → underscore, collapse, trim', () {
      expect(sanitasiNamaFile('Avanza Putih'), 'Avanza_Putih');
      expect(sanitasiNamaFile('Avanza/Putih:B 1234!'), 'Avanza_Putih_B_1234');
      expect(sanitasiNamaFile('a__b'), 'a_b');
      expect(sanitasiNamaFile('_a_'), 'a');
    });

    test('kosong → Kendaraan_Saya; alnum+dash dipertahankan', () {
      expect(sanitasiNamaFile(''), 'Kendaraan_Saya');
      expect(sanitasiNamaFile('///'), 'Kendaraan_Saya');
      expect(sanitasiNamaFile('Avanza-2024_X'), 'Avanza-2024_X');
    });
  });

  group('cek versi backup (E-23)', () {
    test('versi 2 lolos', () {
      expect(() => cekVersiBackup({'versi': 2}), returnsNormally);
    });

    test('versi lain ditolak takDiproses', () {
      for (final v in [1, 3, null, '2']) {
        try {
          cekVersiBackup({'versi': v});
          fail('versi $v harus ditolak');
        } on AppError catch (e) {
          expect(e.kode, AppErrorCode.takDiproses);
        }
      }
    });
  });
}
