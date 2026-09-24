import '../core/utils/image_helper.dart';

// 1 baris = 1 cicilan/reversal. Append-only: tanpa UPDATE/DELETE dari UI.
// nominal > 0 cicilan, < 0 reversal; 0 ditolak (CHECK).
class PembayaranLogModel {
  final int? id;
  final int setoranId;
  final String waktuIso;
  final int nominal;
  final List<String> bukti;
  final String catatan;

  PembayaranLogModel({
    this.id,
    required this.setoranId,
    required this.waktuIso,
    required this.nominal,
    List<String>? bukti,
    this.catatan = '',
  }) : bukti = bukti ?? [];

  bool get isReversal => nominal < 0;

  Map<String, dynamic> toMap() => {
    'id':          id,
    'setoran_id':  setoranId,
    'waktu':       waktuIso,
    'nominal':     nominal,
    'bukti_bayar': ImageHelper.encodeList(bukti),
    'catatan':     catatan,
  };

  factory PembayaranLogModel.fromMap(Map<String, dynamic> m) =>
      PembayaranLogModel(
        id:        m['id'],
        setoranId: m['setoran_id'] ?? 0,
        waktuIso:  m['waktu'] ?? '',
        nominal:   m['nominal'] ?? 0,
        bukti: ImageHelper.decodeList(
            m['bukti_bayar'] ?? ''),
        catatan: m['catatan'] ?? '',
      );
}
