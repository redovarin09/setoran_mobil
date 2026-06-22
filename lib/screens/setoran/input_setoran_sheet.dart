import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/db_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/week_helper.dart';
import '../../models/setoran_model.dart';
import '../../widgets/currency_input.dart';
import '../../widgets/date_picker_field.dart';

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

  late DateTime _tanggal;
  late int _setoran;
  late int _potongan;
  late int _dibayarkan;
  late TextEditingController _catatanCtrl;

  int get _total => _setoran - _potongan;
  int get _sisa  => (_total - _dibayarkan).clamp(0, 999999999);
  String get _ket => (_total - _dibayarkan) <= 0 ? 'Lunas' : 'Kurang';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    // Tanggal default: Senin minggu ke-N bulan ini
    _tanggal = e != null
        ? WeekHelper.parse(e.tanggal)
        : WeekHelper.tanggalMinggu(
            widget.mingguKe, widget.bulan, widget.tahun);

    _setoran    = e?.setoran    ?? 700000;
    _potongan   = e?.potongan   ?? 0;
    _dibayarkan = e?.dibayarkan ?? 0;
    _catatanCtrl = TextEditingController(text: e?.catatan ?? '');
  }

  @override
  void dispose() {
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
      tanggal:    WeekHelper.format(_tanggal),
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
        content: Text('Hapus setoran Minggu ${widget.mingguKe}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.danger)),
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
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
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
                Row(
                  children: [
                    if (widget.existing != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.danger),
                        onPressed: _hapus,
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
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
                  // DatePicker — tidak bisa salah format lagi
                  DatePickerField(
                    label: 'Tanggal',
                    initialDate: _tanggal,
                    firstDate: DateTime(widget.tahun, widget.bulan, 1),
                    lastDate: DateTime(widget.tahun, widget.bulan + 1, 0),
                    onChanged: (dt) => setState(() => _tanggal = dt),
                  ),

                  CurrencyInput(
                    label: 'Nominal Setoran',
                    initialValue: _setoran,
                    isRequired: true,
                    onChanged: (v) => setState(() => _setoran = v),
                  ),

                  CurrencyInput(
                    label: 'Potongan',
                    initialValue: _potongan,
                    onChanged: (v) => setState(() => _potongan = v),
                  ),

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
                        _row('Total Setoran',
                            CurrencyFormatter.format(_total)),
                        _row('Dibayarkan',
                            CurrencyFormatter.format(_dibayarkan)),
                        const Divider(height: 16),
                        _row(
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
                              color: _ket == 'Lunas'
                                  ? AppColors.successLight
                                  : AppColors.dangerLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _ket,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _ket == 'Lunas'
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
                      const Text('Catatan',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _catatanCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Opsional...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            side: const BorderSide(
                                color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Batal',
                              style:
                                  TextStyle(color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _simpan,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Text('💾  Simpan',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
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

  Widget _row(String label, String value,
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
