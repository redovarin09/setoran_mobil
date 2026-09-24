// Terbilang rupiah untuk Semantics (brief §10 a11y).
// Murni, bisa di-test tanpa Flutter. Mendukung negatif ("minus")
// dan 0 ("nol"); pecah per ribuan hingga triliun.

const _satuan = [
  '',
  'satu',
  'dua',
  'tiga',
  'empat',
  'lima',
  'enam',
  'tujuh',
  'delapan',
  'sembilan',
  'sepuluh',
  'sebelas',
];

String _belasan(int n) {
  if (n < 12) return _satuan[n];
  if (n < 20) return '${_satuan[n - 10]} belas';
  if (n < 100) {
    final p = n ~/ 10;
    final s = n % 10;
    return s == 0
        ? '${_satuan[p]} puluh'
        : '${_satuan[p]} puluh ${_satuan[s]}';
  }
  if (n < 200) {
    return n == 100 ? 'seratus' : 'seratus ${_belasan(n - 100)}';
  }
  if (n < 1000) {
    final r = n ~/ 100;
    final s = n % 100;
    final depan = r == 1 ? 'seratus' : '${_belasan(r)} ratus';
    return s == 0 ? depan : '$depan ${_belasan(s)}';
  }
  return '';
}

String _ratusan(int n) {
  if (n < 1000) return _belasan(n);
  if (n < 2000) {
    return n == 1000
        ? 'seribu'
        : 'seribu ${_ratusan(n - 1000)}';
  }
  if (n < 1000000) {
    final r = n ~/ 1000;
    final s = n % 1000;
    final depan = '${_belasan(r)} ribu';
    if (s == 0) return depan;
    final belakang = _ratusan(s);
    return belakang.isEmpty ? depan : '$depan $belakang';
  }
  if (n < 1000000000) {
    final r = n ~/ 1000000;
    final s = n % 1000000;
    final depan = '${_belasan(r)} juta';
    if (s == 0) return depan;
    final belakang = _ratusan(s);
    return belakang.isEmpty ? depan : '$depan $belakang';
  }
  final r = n ~/ 1000000000;
  final s = n % 1000000000;
  final depan = '${_belasan(r)} miliar';
  if (s == 0) return depan;
  final belakang = _ratusan(s);
  return belakang.isEmpty ? depan : '$depan $belakang';
}

/// 700000 → 'tujuh ratus ribu rupiah'; -50000 → 'minus lima puluh
/// ribu rupiah'; 0 → 'nol rupiah'.
String terbilangRp(int nominal) {
  if (nominal == 0) return 'nol rupiah';
  if (nominal < 0) return 'minus ${_ratusan(-nominal)} rupiah';
  return '${_ratusan(nominal)} rupiah';
}
