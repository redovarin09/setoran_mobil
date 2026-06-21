class SetoranModel {
  final int? id;
  final int mingguKe;       // 1-4
  final int bulan;          // 1-12
  final int tahun;          // 2026
  final String tanggal;     // DD/MM/YYYY
  final int setoran;        // nominal setoran
  final int potongan;       // potongan
  final int totalSetoran;   // setoran - potongan
  final int dibayarkan;     // yang sudah dibayar
  final int sisa;           // totalSetoran - dibayarkan
  final String keterangan;  // Lunas / Kurang
  final String catatan;     // catatan bebas

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
  });

  // Hitung otomatis
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
  }) {
    final total = setoran - potongan;
    final sisa  = total - dibayarkan;
    final ket   = sisa <= 0 ? 'Lunas' : 'Kurang';
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
      keterangan: ket,
      catatan: catatan,
    );
  }

  Map<String, dynamic> toMap() => {
    'id':           id,
    'minggu_ke':    mingguKe,
    'bulan':        bulan,
    'tahun':        tahun,
    'tanggal':      tanggal,
    'setoran':      setoran,
    'potongan':     potongan,
    'total_setoran':totalSetoran,
    'dibayarkan':   dibayarkan,
    'sisa':         sisa,
    'keterangan':   keterangan,
    'catatan':      catatan,
  };

  factory SetoranModel.fromMap(Map<String, dynamic> map) => SetoranModel(
    id:           map['id'],
    mingguKe:     map['minggu_ke'],
    bulan:        map['bulan'],
    tahun:        map['tahun'],
    tanggal:      map['tanggal'] ?? '',
    setoran:      map['setoran'] ?? 0,
    potongan:     map['potongan'] ?? 0,
    totalSetoran: map['total_setoran'] ?? 0,
    dibayarkan:   map['dibayarkan'] ?? 0,
    sisa:         map['sisa'] ?? 0,
    keterangan:   map['keterangan'] ?? '',
    catatan:      map['catatan'] ?? '',
  );

  SetoranModel copyWith({
    int? id,
    int? mingguKe,
    int? bulan,
    int? tahun,
    String? tanggal,
    int? setoran,
    int? potongan,
    int? totalSetoran,
    int? dibayarkan,
    int? sisa,
    String? keterangan,
    String? catatan,
  }) =>
    SetoranModel(
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
    );

  bool get isLunas => keterangan == 'Lunas';
}
