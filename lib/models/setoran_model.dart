class SetoranModel {
  final int? id;
  final int mingguKe;
  final int bulan;
  final int tahun;
  final String tanggal;
  final int setoran;
  final int potongan;
  final int totalSetoran;
  final int dibayarkan;
  final int sisa;
  final String keterangan;
  final String catatan;
  final String buktiBayar; // ← nama file foto

  SetoranModel({
    this.id,
    required this.mingguKe,
    required this.bulan,
    required this.tahun,
    required this.tanggal,
    required this.setoran,
    this.potongan = 0,
    required this.totalSetoran,
    required this.dibayarkan,
    required this.sisa,
    required this.keterangan,
    this.catatan = '',
    this.buktiBayar = '',
  });

  factory SetoranModel.hitung({
    int? id,
    required int mingguKe,
    required int bulan,
    required int tahun,
    required String tanggal,
    required int setoran,
    int potongan = 0,
    required int dibayarkan,
    String catatan = '',
    String buktiBayar = '',
  }) {
    final total = setoran - potongan;
    final sisa  = total - dibayarkan;
    return SetoranModel(
      id: id,
      mingguKe: mingguKe,
      bulan: bulan,
      tahun: tahun,
      tanggal: tanggal,
      setoran: setoran,
      potongan: potongan,
      totalSetoran: total,
      dibayarkan: dibayarkan,
      sisa: sisa < 0 ? 0 : sisa,
      keterangan: sisa <= 0 ? 'Lunas' : 'Kurang',
      catatan: catatan,
      buktiBayar: buktiBayar,
    );
  }

  Map<String, dynamic> toMap() => {
    'id':            id,
    'minggu_ke':     mingguKe,
    'bulan':         bulan,
    'tahun':         tahun,
    'tanggal':       tanggal,
    'setoran':       setoran,
    'potongan':      potongan,
    'total_setoran': totalSetoran,
    'dibayarkan':    dibayarkan,
    'sisa':          sisa,
    'keterangan':    keterangan,
    'catatan':       catatan,
    'bukti_bayar':   buktiBayar,
  };

  factory SetoranModel.fromMap(Map<String, dynamic> m) =>
      SetoranModel(
        id:           m['id'],
        mingguKe:     m['minggu_ke'],
        bulan:        m['bulan'],
        tahun:        m['tahun'],
        tanggal:      m['tanggal'] ?? '',
        setoran:      m['setoran'] ?? 0,
        potongan:     m['potongan'] ?? 0,
        totalSetoran: m['total_setoran'] ?? 0,
        dibayarkan:   m['dibayarkan'] ?? 0,
        sisa:         m['sisa'] ?? 0,
        keterangan:   m['keterangan'] ?? '',
        catatan:      m['catatan'] ?? '',
        buktiBayar:   m['bukti_bayar'] ?? '',
      );

  SetoranModel copyWith({
    int? id, int? mingguKe, int? bulan, int? tahun,
    String? tanggal, int? setoran, int? potongan,
    int? totalSetoran, int? dibayarkan, int? sisa,
    String? keterangan, String? catatan, String? buktiBayar,
  }) => SetoranModel(
    id:           id           ?? this.id,
    mingguKe:     mingguKe     ?? this.mingguKe,
    bulan:        bulan        ?? this.bulan,
    tahun:        tahun        ?? this.tahun,
    tanggal:      tanggal      ?? this.tanggal,
    setoran:      setoran      ?? this.setoran,
    potongan:     potongan     ?? this.potongan,
    totalSetoran: totalSetoran ?? this.totalSetoran,
    dibayarkan:   dibayarkan   ?? this.dibayarkan,
    sisa:         sisa         ?? this.sisa,
    keterangan:   keterangan   ?? this.keterangan,
    catatan:      catatan      ?? this.catatan,
    buktiBayar:   buktiBayar   ?? this.buktiBayar,
  );

  bool get isLunas => keterangan == 'Lunas';
  bool get hasBukti => buktiBayar.isNotEmpty;
}
