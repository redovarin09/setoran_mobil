// Helper murni perbaikan — bisa di-test tanpa Flutter.
// Sumber: PRD FR-15 (filter), FR-16 (urutan tanggal ASC).

/// Contains case-insensitive pada jenis/bengkel/keterangan/tanggal.
/// Query kosong → semua cocok (list penuh).
bool cocokFilter({
  required String jenis,
  required String bengkel,
  required String keterangan,
  required String tanggal,
  required String query,
}) {
  final q = query.toLowerCase().trim();
  if (q.isEmpty) return true;
  return jenis.toLowerCase().contains(q) ||
      bengkel.toLowerCase().contains(q) ||
      keterangan.toLowerCase().contains(q) ||
      tanggal.contains(q);
}
