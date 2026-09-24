// Rentang tahun dinamis — OQ-4 TERJAWAB (PRD FR-4).
// Berlaku sama untuk dashboard/setoran/perbaikan/pengaturan.

/// [tahunBerjalan−2 .. tahunBerjalan+5], 8 tahun.
List<int> daftarTahun(int tahunBerjalan) =>
    List.generate(8, (i) => tahunBerjalan - 2 + i);
