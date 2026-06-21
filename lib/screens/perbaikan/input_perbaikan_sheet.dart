import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/db_helper.dart';
import '../../models/perbaikan_model.dart';
import '../../widgets/currency_input.dart';

class InputPerbaikanSheet extends StatefulWidget {
  final int tahun;
  final PerbaikanModel? existing;
  final VoidCallback onSaved;

  const InputPerbaikanSheet({
    super.key,
    required this.tahun,
    this.existing,
    required this.onSaved,
  });

  @override
  State<InputPerbaikanSheet> createState() => _InputPerbaikanSheetState();
}

class _InputPerbaikanSheetState extends State<InputPerbaikanSheet> {
  final _db = DbHelper();
  bool _loading = false;

  late TextEditingController _tanggalCtrl;
  late TextEditingController _jenisCtrl;
  late TextEditingController _bengkelCtrl;
  late TextEditingController _kmCtrl;
  late TextEditingController _keteranganCtrl;
  late int _biaya;

  // Saran jenis perbaikan
  final List<String> _jenisSaran = [
    'Servis Rutin', 'Oli', 'Kaki-Kaki', 'Rem',
    'AC', 'Ban', 'Aki', 'Mesin', 'Spooring',
    'Transmisi', 'Kelistrikan', 'Body', 'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final now = DateTime.now();
    final defaultTgl =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';

    _tanggalCtrl    = TextEditingController(text: e?.tanggal ?? defaultTgl);
    _jenisCtrl      = TextEditingController(text: e?.jenisPerbaikan ?? '');
    _bengkelCtrl    = TextEditingController(text: e?.namaBengkel ?? '');
    _kmCtrl         = TextEditingController(text: e?.km ?? '');
    _keteranganCtrl = TextEditingController(text: e?.keterangan ?? '');
    _biaya          = e?.biaya ?? 0;
  }

  @override
  void dispose() {
    _tanggalCtrl.dispose();
    _jenisCtrl.dispose();
    _bengkelCtrl.dispose();
    _kmCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_jenisCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jenis perbaikan tidak boleh kosong'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (_biaya == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biaya tidak boleh 0'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final model = PerbaikanModel(
      id:             widget.existing?.id,
      tanggal:        _tanggalCtrl.text,
      tahun:          widget.tahun,
      jenisPerbaikan: _jenisCtrl.text.trim(),
      namaBengkel:    _bengkelCtrl.text.trim(),
      biaya:          _biaya,
      km:             _kmCtrl.text.trim(),
      keterangan:     _keteranganCtrl.text.trim(),
    );

    if (widget.existing == null) {
      await _db.insertPerbaikan(model);
    } else {
      await _db.updatePerbaikan(model);
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
          'Hapus data perbaikan "${_jenisCtrl.text}"?',
        ),
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
      await _db.deletePerbaikan(widget.existing!.id!);
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
                  widget.existing == null
                      ? 'Tambah Perbaikan'
                      : 'Edit Perbaikan',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tanggal
                  _label('Tanggal'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _tanggalCtrl,
                    decoration: const InputDecoration(
                      hintText: 'DD/MM/YYYY',
                      prefixIcon: Icon(Icons.calendar_today,
                          size: 18, color: AppColors.primary),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Jenis Perbaikan + chip saran
                  _label('Jenis Perbaikan *'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _jenisCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Servis Rutin, Oli, Rem...',
                      prefixIcon: Icon(Icons.build_outlined,
                          size: 18, color: AppColors.primary),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Chip saran
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _jenisSaran.map((j) {
                      return GestureDetector(
                        onTap: () {
                          final cur = _jenisCtrl.text;
                          _jenisCtrl.text = cur.isEmpty ? j : '$cur + $j';
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Text(j,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Nama Bengkel
                  _label('Nama Bengkel'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _bengkelCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Shell Jatiasih',
                      prefixIcon: Icon(Icons.store_outlined,
                          size: 18, color: AppColors.primary),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Biaya
                  CurrencyInput(
                    label: 'Biaya Perbaikan',
                    initialValue: _biaya,
                    isRequired: true,
                    onChanged: (v) => setState(() => _biaya = v),
                  ),

                  // KM
                  _label('KM Kendaraan'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _kmCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: 200000',
                      prefixIcon: Icon(Icons.speed_outlined,
                          size: 18, color: AppColors.primary),
                      suffixText: 'km',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Keterangan
                  _label('Keterangan'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _keteranganCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Detail perbaikan (opsional)...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
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
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
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

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textMedium,
          fontWeight: FontWeight.w500,
        ),
      );
}
