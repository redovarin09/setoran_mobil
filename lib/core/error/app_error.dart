// Sumber kontrak: docs/technical-design.md §2 (tech-design dikunci untuk Q1–Q5).
// Aturan: total = setoran − potongan; sisa = total − dibayarkan;
// kembalian = max(0, −sisa); Lunas jika sisa <= 0 else Kurang.

enum StatusPeriode { lunas, kurang }

enum AppErrorCode { validasi, tidakKetemu, konflik, takDiproses, io, db }

class FieldError {
  final String field;
  final String pesan;
  const FieldError(this.field, this.pesan);
}

class AppError implements Exception {
  final AppErrorCode kode;
  final String pesan;
  final List<FieldError> detail;
  const AppError(this.kode, this.pesan, [this.detail = const []]);

  @override
  String toString() => 'AppError(${kode.name}): $pesan';
}

/// Hitung murni — bisa di-test tanpa Flutter.
int hitungTotal(int setoran, int potongan) => setoran - potongan;

int hitungSisa(int total, int dibayarkan) => total - dibayarkan;

int hitungKembalian(int sisaRaw) => sisaRaw < 0 ? -sisaRaw : 0;

StatusPeriode statusDariSisa(int sisaRaw) =>
    sisaRaw <= 0 ? StatusPeriode.lunas : StatusPeriode.kurang;

int hitungGrand(int sisaLalu, int totalSisa, int totalPerbaikan) =>
    sisaLalu + totalSisa - totalPerbaikan;
