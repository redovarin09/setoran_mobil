// Model untuk ringkasan per bulan & grand total
class RekapBulanModel {
  final int bulan;
  final int tahun;
  final int totalSisa;

  RekapBulanModel({
    required this.bulan,
    required this.tahun,
    required this.totalSisa,
  });
}

class GrandTotalModel {
  final int sisaTahunLalu;
  final Map<int, int> sisaPerBulan; // bulan -> sisa
  final int totalPerbaikan;

  GrandTotalModel({
    required this.sisaTahunLalu,
    required this.sisaPerBulan,
    required this.totalPerbaikan,
  });

  int get totalSetoran =>
      sisaPerBulan.values.fold(0, (a, b) => a + b);

  int get totalKotor => sisaTahunLalu + totalSetoran;

  int get grandTotal => totalKotor - totalPerbaikan;
}
