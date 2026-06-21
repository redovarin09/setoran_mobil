class PerbaikanModel {
  final int? id;
  final String tanggal;
  final int tahun;
  final String jenisPerbaikan;
  final String namaBengkel;
  final int biaya;
  final String km;
  final String keterangan;

  PerbaikanModel({
    this.id,
    required this.tanggal,
    required this.tahun,
    required this.jenisPerbaikan,
    required this.namaBengkel,
    required this.biaya,
    this.km = '',
    this.keterangan = '',
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
  };

  factory PerbaikanModel.fromMap(Map<String, dynamic> map) => PerbaikanModel(
    id:              map['id'],
    tanggal:         map['tanggal'] ?? '',
    tahun:           map['tahun'] ?? 2026,
    jenisPerbaikan:  map['jenis_perbaikan'] ?? '',
    namaBengkel:     map['nama_bengkel'] ?? '',
    biaya:           map['biaya'] ?? 0,
    km:              map['km'] ?? '',
    keterangan:      map['keterangan'] ?? '',
  );

  PerbaikanModel copyWith({
    int? id,
    String? tanggal,
    int? tahun,
    String? jenisPerbaikan,
    String? namaBengkel,
    int? biaya,
    String? km,
    String? keterangan,
  }) =>
    PerbaikanModel(
      id:             id             ?? this.id,
      tanggal:        tanggal        ?? this.tanggal,
      tahun:          tahun          ?? this.tahun,
      jenisPerbaikan: jenisPerbaikan ?? this.jenisPerbaikan,
      namaBengkel:    namaBengkel    ?? this.namaBengkel,
      biaya:          biaya          ?? this.biaya,
      km:             km             ?? this.km,
      keterangan:     keterangan     ?? this.keterangan,
    );
}
