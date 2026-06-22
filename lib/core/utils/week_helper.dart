class WeekHelper {
  /// Hitung jumlah minggu aktif dalam satu bulan
  static int jumlahMinggu(int bulan, int tahun) {
    final firstDay = DateTime(tahun, bulan, 1);
    final lastDay  = DateTime(tahun, bulan + 1, 0);
    return ((lastDay.day + firstDay.weekday - 1) / 7).ceil();
  }

  /// Hitung tanggal default untuk minggu ke-N
  /// Mengambil hari Senin pertama bulan itu sebagai acuan
  static DateTime tanggalMinggu(int mingguKe, int bulan, int tahun) {
    final firstDay = DateTime(tahun, bulan, 1);

    // Cari Senin pertama di bulan ini
    // weekday: 1=Sen, 2=Sel, ..., 7=Ming
    final daysToMonday = firstDay.weekday == 1
        ? 0
        : (8 - firstDay.weekday) % 7;

    final firstMonday = firstDay.add(Duration(days: daysToMonday));

    // Minggu ke-N dimulai dari Senin ke-(N-1) setelah Senin pertama
    final weekDate = firstMonday.add(Duration(days: (mingguKe - 1) * 7));

    // Pastikan masih dalam bulan yang sama
    if (weekDate.month != bulan) {
      return DateTime(tahun, bulan + 1, 0); // hari terakhir bulan
    }
    return weekDate;
  }

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
