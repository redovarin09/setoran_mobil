import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/database/db_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/setoran_model.dart';
import '../../widgets/currency_input.dart';

class InputSetoranSheet extends StatefulWidget {
  final int mingguKe;
  final int bulan;
  final int tahun;
  final SetoranModel? existing;
  final VoidCallback onSaved;

  const InputSetoranSheet({
    super.key,
    required this.mingguKe,
    required this.bulan,
    required this.tahun,
    this.existing,
    required this.onSaved,
  });

  @override
  State<InputSetoranSheet> createState() => _InputSetoranSheetState();
}

class _InputSetoranSheetState extends State<InputSetoranSheet> {
  final _db = DbHelper();
  bool _loading = false;

  late int _setoran;
  late int _potongan;
  late int _dibayarkan;
  late String _catatan;
  late TextEditingController _catatanCtrl;
  late TextEditingController _tanggalCtrl;

  int get _total => _setoran - _potongan;
  int get _sisa  => (_total - _dibayarkan).clamp(0, 999999999);
  String get _keterangan =>
      (_total - _dibayarkan) <= 0 ? 'Lunas' : 'Kurang';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _setoran    = e?.setoran    ?? 700000;
    _potongan   = e?.potongan   ?? 0;
    _dibayarkan = e?.dibayarkan ?? 0;
    _catatan    = e?.catatan    ?? '';

    // Default tanggal minggu ke-N bulan ini
    final now = DateTime.now();
    final defaultDate = e?.tanggal ??
        '${(widget.mingguKe * 7 - 3).toString().padLeft(2, '0')}/'
        '${widget.bulan.toString().padLeft(2, '0')}/'
        '${widget.tahun}';

    _tanggalCtrl = TextEditingController(text: defaultDate);
    _catatanCtrl = TextEditingController(text: _catatan);
  }

  @override
  void dispose() {
    _tanggalCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_setoran == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal setoran tidak boleh 0'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final model = SetoranModel.hitung(
      id:         widget.existing?.id,
      mingguKe:   widget.mingguKe,
      bulan:      widget.bulan,
      tahun:      widget.tahun,
      tanggal:    _tanggalCtrl.text,
      setoran:    _setoran,
      potongan:   _potongan,
      dibayarkan: _dibayarkan,
      catatan:    _catatanCtrl.text,
    );

    if (widget.existing == null) {
      await _db.insertSetoran(model);
    } else {
      await _db.updateSetoran(model);
    }

    setState(() => _loading = false);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _hapus() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Data'),
        content: Text(
          'Hapus data setoran Minggu ${widget.mingguKe}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && widget.existing?.id != null) {
      await _db.deleteSetoran(widget.existing!.id!);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Setoran Minggu ${widget.mingguKe}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                if (widget.existing != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.danger),
                    onPressed: _hapus,
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20, 16, 20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                children: [
                  // Tanggal
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanggal',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _tanggalCtrl,
                        decoration: const InputDecoration(
                          hintText: 'DD/MM/YYYY',
                          prefixIcon: Icon(Icons.calendar_today,
                              size: 18, color: AppColors.primary),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                  // Nominal Setoran
                  CurrencyInput(
                    label: 'Nominal Setoran',
                    initialValue: _setoran,
                    isRequired: true,
                    onChanged: (v) => setState(() => _setoran = v),
                  ),

                  // Potongan
                  CurrencyInput(
                    label: 'Potongan',
                    initialValue: _potongan,
                    onChanged: (v) => setState(() => _potongan = v),
                  ),

                  // Dibayarkan
                  CurrencyInput(
                    label: 'Dibayarkan',
                    initialValue: _dibayarkan,
                    onChanged: (v) => setState(() => _dibayarkan = v),
                  ),

                  // Preview otomatis
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        _previewRow('Total Setoran',
                            CurrencyFormatter.format(_total)),
                        _previewRow('Dibayarkan',
                            CurrencyFormatter.format(_dibayarkan)),
                        const Divider(height: 16),
                        _previewRow(
                          'Sisa',
                          CurrencyFormatter.format(_sisa),
                          color: _sisa > 0
                              ? AppColors.danger
                              : AppColors.success,
                          bold: true,
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: _keterangan == 'Lunas'
                                  ? AppColors.successLight
                                  : AppColors.dangerLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _keterangan,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _keterangan == 'Lunas'
                                    ? AppColors.success
                                    : AppColors.danger,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Catatan
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catatan',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _catatanCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Opsional...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12,
                          ),
                        ),
                        onChanged: (v) => _catatan = v,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Tombol
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _simpan,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  '💾  Simpan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value,
      {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMedium)),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                color: color ?? AppColors.textDark,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
