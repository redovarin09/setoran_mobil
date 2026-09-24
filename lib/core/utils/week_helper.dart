class WeekHelper {
  /// Label pendek hari, index 0=Minggu..6=Sabtu (tech-design §1).
  static const List<String> hariPendek = [
    'Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab',
  ];

  /// 0=Minggu..6=Sabtu → DateTime.weekday (Senin=1..Minggu=7).
  static int _weekday(int jadwalHari) =>
      jadwalHari == 0 ? DateTime.sunday : jadwalHari;

  /// Jumlah hari jatuh tempo dalam satu bulan (generalisasi OQ-4:
  /// dulu selalu Minggu).
  static int jumlahJatuhTempo(
      int jadwalHari, int bulan, int tahun) {
    final lastDay = DateTime(tahun, bulan + 1, 0).day;
    final target  = _weekday(jadwalHari);
    int count = 0;
    for (int d = 1; d <= lastDay; d++) {
      if (DateTime(tahun, bulan, d).weekday == target) {
        count++;
      }
    }
    return count;
  }

  /// Tanggal jatuh tempo ke-N; fallback hari terakhir bulan.
  static DateTime tanggalJatuhTempo(
      int n, int jadwalHari, int bulan, int tahun) {
    final lastDay = DateTime(tahun, bulan + 1, 0).day;
    final target  = _weekday(jadwalHari);
    int count = 0;
    for (int d = 1; d <= lastDay; d++) {
      final dt = DateTime(tahun, bulan, d);
      if (dt.weekday == target) {
        count++;
        if (count == n) return dt;
      }
    }
    return DateTime(tahun, bulan + 1, 0);
  }

  /// Semua tanggal jatuh tempo dalam satu bulan.
  static List<DateTime> semuaJatuhTempo(
      int jadwalHari, int bulan, int tahun) {
    final lastDay = DateTime(tahun, bulan + 1, 0).day;
    final target  = _weekday(jadwalHari);
    final result  = <DateTime>[];
    for (int d = 1; d <= lastDay; d++) {
      final dt = DateTime(tahun, bulan, d);
      if (dt.weekday == target) {
        result.add(dt);
      }
    }
    return result;
  }

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
