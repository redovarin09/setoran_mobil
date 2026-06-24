class PerbaikanModel {
  final int? id;
  final String tanggal;
  final int tahun;
  final String jenisPerbaikan;
  final String namaBengkel;
  final int biaya;
  final String km;
  final String keterangan;
  final String buktiBayar; // ← nama file foto

  PerbaikanModel({
    this.id,
    required this.tanggal,
    required this.tahun,
    required this.jenisPerbaikan,
    required this.namaBengkel,
    required this.biaya,
    this.km = '',
    this.keterangan = '',
    this.buktiBayar = '',
  });

  Map<String, dynamic> toMap() => {
    'id':              id,
    'tanggal':         tanggal,
    'tahun':           tahun,
    'jenis_perbaikan': jenisPerbaikan,
    'nama_bengkel':    namaBengkel,
    'biaya':           biaya,
    'km':              km,
    'keterangan':      keterangan,
    'bukti_bayar':     buktiBayar,
  };

  factory PerbaikanModel.fromMap(Map<String, dynamic> m) =>
      PerbaikanModel(
        id:             m['id'],
        tanggal:        m['tanggal'] ?? '',
        tahun:          m['tahun'] ?? 2026,
        jenisPerbaikan: m['jenis_perbaikan'] ?? '',
        namaBengkel:    m['nama_bengkel'] ?? '',
        biaya:          m['biaya'] ?? 0,
        km:             m['km'] ?? '',
        keterangan:     m['keterangan'] ?? '',
        buktiBayar:     m['bukti_bayar'] ?? '',
      );

  PerbaikanModel copyWith({
    int? id, String? tanggal, int? tahun,
    String? jenisPerbaikan, String? namaBengkel,
    int? biaya, String? km, String? keterangan,
    String? buktiBayar,
  }) => PerbaikanModel(
    id:             id             ?? this.id,
    tanggal:        tanggal        ?? this.tanggal,
    tahun:          tahun          ?? this.tahun,
    jenisPerbaikan: jenisPerbaikan ?? this.jenisPerbaikan,
    namaBengkel:    namaBengkel    ?? this.namaBengkel,
    biaya:          biaya          ?? this.biaya,
    km:             km             ?? this.km,
    keterangan:     keterangan     ?? this.keterangan,
    buktiBayar:     buktiBayar     ?? this.buktiBayar,
  );

  bool get hasBukti => buktiBayar.isNotEmpty;
}
