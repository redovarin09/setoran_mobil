import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/db_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/terbilang.dart';
import '../../core/utils/week_helper.dart';
import '../../models/pembayaran_log_model.dart';
import '../../models/setoran_model.dart';
import '../../widgets/bersama/currency_input.dart';
import '../../widgets/bersama/date_picker_field.dart';
import '../../widgets/bersama/bukti_bayar_widget.dart';

// Sheet input setoran + log cicilan (FR-11..FR-14, US-4/5/14).
// Aturan: tiap simpan cicilan = append pembayaran_log; koreksi via
// reversal (nominal negatif); larang timpa diam-diam (OQ-6).
// Foto BARU selalu menempel pada entri log cicilan (Q3 tech-design);
// foto lama (header) hanya kompatibilitas baca.
class InputSetoranSheet extends StatefulWidget {
  final int mingguKe;
  final int bulan;
  final int tahun;
  final int jadwalHari;
  final int defaultNominal;
  final SetoranModel? existing;
  final VoidCallback onSaved;

  const InputSetoranSheet({
    super.key,
    required this.mingguKe,
    required this.bulan,
    required this.tahun,
    required this.jadwalHari,
    required this.defaultNominal,
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
  int _cicilan = 0;
  bool _isKoreksi = false;
  late TextEditingController _catatanCtrl;
  late TextEditingController _cicilanCatatanCtrl;
  late List<String> _buktiBayar;
  late List<String> _buktiAwal;
  List<PembayaranLogModel> _logs = [];
  bool _logsLoading = true;

  int get _total => _setoran - _potongan;
  int get _dibayarkanLama => widget.existing?.dibayarkan ?? 0;
  int get _cicilanEfektif => _isKoreksi ? -_cicilan : _cicilan;
  int get _dibayarkanBaru => _dibayarkanLama + _cicilanEfektif;
  // Sisa mentah bertanda (OQ-7): minus tampil apa adanya.
  int get _sisaBaru => _total - _dibayarkanBaru;
  int get _kembalianBaru => _sisaBaru < 0 ? -_sisaBaru : 0;
  String get _ket => _sisaBaru <= 0 ? 'Lunas' : 'Kurang';

  /// Foto yang ditambah pada sesi ini → milik entri log, bukan header.
  List<String> get _buktiBaru => _buktiBayar
      .where((f) => !_buktiAwal.contains(f))
      .toList();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    _tanggal = e != null
        ? WeekHelper.parse(e.tanggal)
        : WeekHelper.tanggalJatuhTempo(
            widget.mingguKe,
            widget.jadwalHari,
            widget.bulan,
            widget.tahun);

    _setoran    = e?.setoran  ?? widget.defaultNominal;
    _potongan   = e?.potongan ?? 0;
    _catatanCtrl = TextEditingController(text: e?.catatan ?? '');
    _cicilanCatatanCtrl = TextEditingController();
    _buktiBayar = List.from(e?.buktiBayar ?? []);
    _buktiAwal  = List.from(e?.buktiBayar ?? []);
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final id = widget.existing?.id;
    if (id == null) {
      setState(() => _logsLoading = false);
      return;
    }
    final logs = await _db.getLogBySetoran(id);
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _logsLoading = false;
    });
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    _cicilanCatatanCtrl.dispose();
    super.dispose();
  }

  void _tolak(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  Future<void> _simpan() async {
    if (_setoran == 0) {
      _tolak('Nominal setoran tidak boleh 0');
      return;
    }
    if (_cicilanEfektif == 0 && _buktiBaru.isNotEmpty) {
      _tolak('Isi nominal cicilan untuk menyimpan foto baru');
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
      dibayarkan: _dibayarkanBaru,
      catatan:    _catatanCtrl.text,
      // Header: hanya foto lama yang dipertahankan (kompat baca).
      buktiBayar: _buktiBayar
          .where((f) =>
              _buktiAwal.contains(f) || !_buktiBaru.contains(f))
          .toList(),
    );

    PembayaranLogModel? cicilan;
    if (_cicilanEfektif != 0) {
      cicilan = PembayaranLogModel(
        setoranId:  widget.existing?.id ?? 0,
        waktuIso:   DateTime.now().toIso8601String(),
        nominal:    _cicilanEfektif,
        bukti:      _buktiBaru,
        catatan:    _cicilanCatatanCtrl.text.trim(),
      );
    }

    await _db.simpanSetoranLengkap(model, cicilan: cicilan);

    setState(() => _loading = false);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _hapus() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Data'),
        content:
            Text('Hapus setoran Periode ${widget.mingguKe}?'),
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
    final hariIni = WeekHelper.hariPendek[widget.jadwalHari];
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
                  'Periode ${widget.mingguKe} · $hariIni',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Row(
                  children: [
                    if (widget.existing != null)
                      Semantics(
                        hint: 'tindakan permanen, perlu konfirmasi',
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.danger),
                          onPressed: _hapus,
                        ),
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
                  DatePickerField(
                    label: 'Tanggal',
                    initialDate: _tanggal,
                    firstDate: DateTime(widget.tahun, widget.bulan, 1),
                    lastDate: DateTime(widget.tahun, widget.bulan + 1, 0),
                    onChanged: (dt) => setState(() => _tanggal = dt),
                  ),

                  CurrencyInput(
                    key: const ValueKey('setoranNominal'),
                    label: 'Nominal Setoran',
                    initialValue: _setoran,
                    isRequired: true,
                    onChanged: (v) => setState(() => _setoran = v),
                  ),

                  CurrencyInput(
                    key: const ValueKey('setoranPotongan'),
                    label: 'Potongan (manual)',
                    initialValue: _potongan,
                    onChanged: (v) => setState(() => _potongan = v),
                  ),

                  // Cicilan baru / koreksi
                  Row(
                    children: [
                      const Text('Cicilan baru',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w500,
                          )),
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _isKoreksi = !_isKoreksi),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isKoreksi
                                ? AppColors.danger
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.divider),
                          ),
                          child: Text(
                            _isKoreksi
                                ? 'Koreksi (−)'
                                : 'Koreksi?',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isKoreksi
                                  ? Colors.white
                                  : AppColors.textLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  CurrencyInput(
                    key: const ValueKey('setoranCicilan'),
                    label: _isKoreksi
                        ? 'Nominal koreksi'
                        : 'Nominal cicilan',
                    initialValue: 0,
                    onChanged: (v) => setState(() => _cicilan = v),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Catatan cicilan',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _cicilanCatatanCtrl,
                        maxLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'Opsional...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                  // Preview live bertanda asli
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
                            '${CurrencyFormatter.format(_dibayarkanLama)}'
                            ' → ${CurrencyFormatter.format(_dibayarkanBaru)}'),
                        const Divider(height: 16),
                        _row(
                          'Sisa',
                          CurrencyFormatter.format(_sisaBaru),
                          color: _sisaBaru > 0
                              ? AppColors.danger
                              : AppColors.success,
                          bold: true,
                          semantics:
                              'Sisa ${terbilangRp(_sisaBaru)}',
                        ),
                        if (_kembalianBaru > 0)
                          _row(
                            'Kembalian',
                            CurrencyFormatter.format(
                                _kembalianBaru),
                            color: AppColors.warning,
                            bold: true,
                          ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Semantics(
                            liveRegion: true,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: _ket == 'Lunas'
                                    ? AppColors.successLight
                                    : AppColors.dangerLight,
                                borderRadius:
                                    BorderRadius.circular(20),
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
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Riwayat cicilan
                  _buildLogTimeline(),

                  // Catatan periode
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

                  const Divider(height: 20),
		  BuktiBayarWidget(
		    initialFileNames: _buktiBayar,
		    onChanged: (list) => _buktiBayar = list,
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
                          key: const ValueKey('setoranSimpan'),
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

  Widget _buildLogTimeline() {
    if (_logsLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: LinearProgressIndicator(
            color: AppColors.primary),
      );
    }
    if (_logs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Riwayat cicilan',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMedium,
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(height: 6),
        ..._logs.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    l.isReversal
                        ? Icons.undo
                        : Icons.payments_outlined,
                    size: 14,
                    color: l.isReversal
                        ? AppColors.danger
                        : AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l.catatan.isEmpty
                          ? l.waktuIso.split('T').first
                          : '${l.waktuIso.split('T').first} · ${l.catatan}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (l.bukti.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.photo_camera,
                          size: 12, color: AppColors.textLight),
                    ),
                  Text(
                    '${l.isReversal ? '−' : '+'}'
                    '${CurrencyFormatter.format(l.nominal.abs())}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: l.isReversal
                          ? AppColors.danger
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            )),
        const Divider(height: 16),
      ],
    );
  }

  Widget _row(String label, String value,
      {Color? color, bool bold = false, String? semantics}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMedium)),
          semantics == null
              ? Text(value,
                  style: TextStyle(
                    fontSize: 13,
                    color: color ?? AppColors.textDark,
                    fontWeight:
                        bold ? FontWeight.bold : FontWeight.w500,
                  ))
              : Semantics(
                  label: semantics,
                  child: Text(value,
                      style: TextStyle(
                        fontSize: 13,
                        color: color ?? AppColors.textDark,
                        fontWeight: bold
                            ? FontWeight.bold
                            : FontWeight.w500,
                      )),
                ),
        ],
      ),
    );
  }
}
