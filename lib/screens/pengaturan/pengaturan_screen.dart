import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/db_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/excel_exporter.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  final _db  = DbHelper();
  int _tahun = DateTime.now().year;
  bool _loading = false;

  // ─── EXPORT / BACKUP JSON ──────────────────────────

  Future<void> _exportBackup() async {
    setState(() => _loading = true);
    try {
      final json    = await _db.exportToJson(_tahun);
      final jsonStr = const JsonEncoder.withIndent('  ').convert(json);
      final dir     = await getApplicationDocumentsDirectory();
      final nama    = await _db.getKendaraanNama();
      final fileName= 'backup_${nama}_$_tahun.json'
          .replaceAll(' ', '_');
      final file    = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Backup Setoran $_tahun',
        subject: fileName,
      );
    } catch (e) {
      _showError('Gagal export: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ─── EXPORT EXCEL ──────────────────────────────────

  Future<void> _exportExcel() async {
    setState(() => _loading = true);
    try {
      await ExcelExporter.exportTahun(_tahun);
    } catch (e) {
      _showError('Gagal export Excel: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ─── RESTORE — PILIH FILE DARI MANA SAJA ───────────

  Future<void> _restoreBackup() async {
    try {
      // Buka file picker — user bisa pilih dari Downloads,
      // Drive, WhatsApp, folder mana saja
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Pilih file backup (.json)',
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      final path   = picked.path;

      if (path == null) {
        _showError('Tidak bisa membaca file. Coba pindahkan '
            'file ke Downloads terlebih dahulu.');
        return;
      }

      // Preview isi file sebelum restore
      final content = await File(path).readAsString();
      Map<String, dynamic> json;
      try {
        json = jsonDecode(content) as Map<String, dynamic>;
      } catch (_) {
        _showError('File bukan format backup yang valid.');
        return;
      }

      // Tampilkan info backup
      final tahunBackup = json['tahun'] ?? '?';
      final sisaBackup  = json['sisa_tahun_lalu'] ?? 0;
      final jmlSetoran  =
          (json['setoran'] as List?)?.length ?? 0;
      final jmlPerbaikan =
          (json['perbaikan'] as List?)?.length ?? 0;
      final exportedAt  = json['exported_at'] ?? '-';

      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Konfirmasi Restore'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('File', picked.name),
              _infoRow('Tahun', '$tahunBackup'),
              _infoRow('Sisa Tahun Lalu',
                  CurrencyFormatter.format(sisaBackup as int)),
              _infoRow('Data Setoran', '$jmlSetoran entri'),
              _infoRow('Data Perbaikan',
                  '$jmlPerbaikan entri'),
              _infoRow('Dibuat', exportedAt
                  .toString()
                  .substring(0, 10)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⚠️ Data tahun $tahunBackup yang ada '
                  'saat ini akan digantikan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: const Text('Restore',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() => _loading = true);
      await _db.importFromJson(json);
      _showSuccess('✅ Restore berhasil!');
    } on Exception catch (e) {
      _showError('Gagal restore: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
        ],
      ),
    );
  }

  // ─── EDIT SISA TAHUN LALU ──────────────────────────

  Future<void> _editSisaTahunLalu() async {
    final current = await _db.getSisaTahunLalu();
    final ctrl    = TextEditingController(
        text: current.toString());

    if (!mounted) return;
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Sisa Tahun Lalu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saat ini: ${CurrencyFormatter.format(current)}',
              style: const TextStyle(
                  color: AppColors.textMedium, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                labelText: 'Nominal',
                isDense: true,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text) ?? 0;
              Navigator.pop(context, val);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Simpan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null) {
      await _db.setSisaTahunLalu(result);
      _showSuccess(
          'Sisa tahun lalu: ${CurrencyFormatter.format(result)}');
    }
  }

  // ─── CARRY OVER ────────────────────────────────────

  Future<void> _carryOver() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Carry Over'),
        content: Text(
          'Grand Total tahun $_tahun akan dijadikan '
          'Sisa Tahun Lalu untuk tahun ${_tahun + 1}.\n\n'
          'Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Ya, Carry Over',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    await _db.carryOverKeTahunDepan(_tahun);
    setState(() => _loading = false);
    _showSuccess(
        '✅ Carry over berhasil! Sisa ${_tahun + 1} sudah diupdate.');
  }

  // ─── RESET DATA ────────────────────────────────────

  Future<void> _resetData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ Reset Semua Data'),
        content: const Text(
          'Tindakan ini akan menghapus SEMUA data setoran '
          'dan perbaikan.\n\n'
          'Pastikan sudah backup terlebih dahulu!\n\n'
          'Tindakan ini TIDAK BISA dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            child: const Text('HAPUS SEMUA',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Terakhir'),
        content: const Text('Yakin ingin menghapus semua data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger),
            child: const Text('Ya, Hapus',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm2 != true) return;

    setState(() => _loading = true);
    await _db.resetSemuaData();
    setState(() => _loading = false);
    _showSuccess('Semua data berhasil dihapus');
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.danger,
      duration: const Duration(seconds: 5),
    ));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Pengaturan'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── BACKUP & RESTORE ─────────────────
              _sectionTitle('Backup & Restore'),
              const SizedBox(height: 8),

              _settingCard(
                icon: Icons.upload_file,
                iconColor: AppColors.primary,
                title: 'Export / Backup (JSON)',
                subtitle: 'Simpan data ke file JSON & bagikan',
                trailing: _tahunButton(),
                onTap: _exportBackup,
              ),

              _settingCard(
                icon: Icons.table_chart,
                iconColor: const Color(0xFF1B5E20),
                title: 'Export ke Excel (.xlsx)',
                subtitle: 'Laporan Excel lengkap 3 sheet',
                trailing: _tahunButton(),
                onTap: _exportExcel,
              ),

              _settingCard(
                icon: Icons.download_for_offline,
                iconColor: AppColors.success,
                title: 'Restore / Import',
                subtitle:
                    'Pilih file backup .json dari folder mana saja\n'
                    '(Downloads, Drive, WhatsApp, dll)',
                onTap: _restoreBackup,
              ),

              const SizedBox(height: 16),

              // ── KONFIGURASI ──────────────────────
              _sectionTitle('Konfigurasi'),
              const SizedBox(height: 8),

              _settingCard(
                icon: Icons.history,
                iconColor: AppColors.warning,
                title: 'Sisa Tahun Lalu',
                subtitle: 'Edit nominal sisa dari tahun sebelumnya',
                onTap: _editSisaTahunLalu,
              ),

              _settingCard(
                icon: Icons.arrow_forward,
                iconColor: AppColors.primary,
                title: 'Carry Over ke Tahun Depan',
                subtitle:
                    'Pindahkan Grand Total $_tahun ke sisa tahun depan',
                onTap: _carryOver,
              ),

              const SizedBox(height: 16),

              // ── ZONA BERBAHAYA ───────────────────
              _sectionTitle('Zona Berbahaya'),
              const SizedBox(height: 8),

              _settingCard(
                icon: Icons.delete_forever,
                iconColor: AppColors.danger,
                title: 'Reset Semua Data',
                subtitle:
                    'Hapus seluruh data setoran & perbaikan',
                titleColor: AppColors.danger,
                onTap: _resetData,
              ),

              const SizedBox(height: 24),

              Center(
                child: Column(
                  children: [
                    const Icon(Icons.directions_car,
                        size: 40, color: AppColors.primary),
                    const SizedBox(height: 8),
                    const Text('Setoran Mobil',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontSize: 16,
                        )),
                    const SizedBox(height: 4),
                    Text('v1.2.0',
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),

          // Loading overlay
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                            color: AppColors.primary),
                        SizedBox(height: 12),
                        Text('Memproses...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tahunButton() {
    return TextButton(
      onPressed: _pilihTahun,
      child: Text('$_tahun ▾',
          style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.textLight,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _settingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? titleColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: titleColor ?? AppColors.textDark,
            )),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textLight)),
        trailing: trailing ??
            const Icon(Icons.chevron_right,
                color: AppColors.textLight),
      ),
    );
  }

  Future<void> _pilihTahun() async {
    final picked = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Pilih Tahun'),
        children: [2024, 2025, 2026, 2027].map((y) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, y),
            child: Text('$y',
                style: TextStyle(
                  fontWeight: y == _tahun
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: y == _tahun
                      ? AppColors.primary
                      : AppColors.textDark,
                )),
          );
        }).toList(),
      ),
    );
    if (picked != null) setState(() => _tahun = picked);
  }
}
