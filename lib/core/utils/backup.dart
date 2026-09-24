// Helper murni backup/restore — bisa di-test tanpa Flutter.
// Sumber: PRD E-20 (sanitasi penuh), E-23 (versi: 2, tolak lain).
import '../error/app_error.dart';

/// Selain [A-Za-z0-9-_] → `_`; collapse `_` ganda; trim tepi.
/// Kosong → 'Kendaraan_Saya'. Untuk nama file xlsx/json.
String sanitasiNamaFile(String v) {
  final ganti = v.replaceAll(RegExp(r'[^A-Za-z0-9\-_]'), '_');
  final rapat = ganti.replaceAll(RegExp(r'_+'), '_');
  final rapi = rapat.replaceAll(RegExp(r'^_+|_+$'), '');
  return rapi.isEmpty ? 'Kendaraan_Saya' : rapi;
}

/// Backup hanya versi 2; versi lain ditolak dengan pesan (E-23).
void cekVersiBackup(Map<String, dynamic> json) {
  if (json['versi'] != 2) {
    throw AppError(
      AppErrorCode.takDiproses,
      'Versi backup tak dikenal (diterima: versi 2)',
    );
  }
}
