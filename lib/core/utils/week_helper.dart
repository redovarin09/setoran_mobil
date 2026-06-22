class WeekHelper {
  /// Hitung jumlah hari MINGGU (Sunday) dalam satu bulan
  static int jumlahMinggu(int bulan, int tahun) {
    final lastDay = DateTime(tahun, bulan + 1, 0).day;
    int count = 0;
    for (int d = 1; d <= lastDay; d++) {
      if (DateTime(tahun, bulan, d).weekday == DateTime.sunday) {
        count++;
      }
    }
    return count;
  }

  /// Tanggal hari Minggu ke-N dalam bulan tersebut
  static DateTime tanggalMinggu(int mingguKe, int bulan, int tahun) {
    final lastDay = DateTime(tahun, bulan + 1, 0).day;
    int count = 0;
    for (int d = 1; d <= lastDay; d++) {
      final dt = DateTime(tahun, bulan, d);
      if (dt.weekday == DateTime.sunday) {
        count++;
        if (count == mingguKe) return dt;
      }
    }
    // Fallback: hari Minggu terakhir bulan
    return DateTime(tahun, bulan + 1, 0);
  }

  /// Semua tanggal hari Minggu dalam satu bulan
  static List<DateTime> semuaMinggu(int bulan, int tahun) {
    final lastDay = DateTime(tahun, bulan + 1, 0).day;
    final result  = <DateTime>[];
    for (int d = 1; d <= lastDay; d++) {
      final dt = DateTime(tahun, bulan, d);
      if (dt.weekday == DateTime.sunday) {
        result.add(dt);
      }
    }
    return result;
  }

  /// Cek apakah tanggal adalah hari Minggu
  static bool isSunday(DateTime dt) =>
      dt.weekday == DateTime.sunday;

  /// Format tanggal ke DD/MM/YYYY
  static String format(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';

  /// Parse DD/MM/YYYY ke DateTime
  static DateTime parse(String s) {
    final parts = s.split('/');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }
}
