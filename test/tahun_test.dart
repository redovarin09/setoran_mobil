// Test kontrak tahun dinamis — OQ-4 (PRD FR-4).
import 'package:flutter_test/flutter_test.dart';
import 'package:setoran_mobil/core/utils/tahun.dart';

void main() {
  test('rentang [berjalan−2 .. berjalan+5], 8 tahun', () {
    expect(daftarTahun(2026),
        [2024, 2025, 2026, 2027, 2028, 2029, 2030, 2031]);
    final t = DateTime.now().year;
    final list = daftarTahun(t);
    expect(list.length, 8);
    expect(list.first, t - 2);
    expect(list.last, t + 5);
    expect(list.contains(t), isTrue);
  });
}
