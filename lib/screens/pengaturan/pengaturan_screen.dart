import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/db_helper.dart';
import '../../core/utils/currency_formatter.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  final _db  = DbHelper();
  int _tahun = DateTime.now().year;
  bool _loading = false;

  // ─── EXPORT / BACKUP ───────────────────────────────

  Future<void> _exportBackup() async {
    setState(() => _loading = true);
    try {
      final json     = await _db.exportToJson(_tahun);
      final jsonStr  = const JsonEncoder.withIndent('  ').convert(json);
      final dir      = await getApplicationDocumentsDirectory();
      final fileName = 'backup_setoran_$_tahun.json';
      final file     = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Backup Setoran Mobil $_tahun',
        subject: fileName,
      );
    } catch (e) {
      _showError('Gagal export: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ─── RESTORE / IMPORT ──────────────────────────────

  Future<void> _restoreBackup() async {
    // Cari file backup di Documents
    final dir = await getApplicationDocumentsDirectory();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));

    if (files.isEmpty) {
      _showError(
          'Tidak ada file backup (.json) di penyimpanan.\n'
          'Lakukan Export/Backup terlebih dahulu, lalu simpan file-nya kembali ke folder Documents aplikasi.');
      return;
    }

    // Tampilkan daftar file backup
    if (!mounted) return;
    final picked = await showDialog<File>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Pilih File Backup'),
        children: files.map((f) {
          final name = f.path.split('/').last;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, f),
            child: Row(
              children: [
                const Icon(Icons.file_present,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name,
                      style: const TextStyle(fontSize: 13)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (picked == null) return;

    // Konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Restore'),
        content: Text(
          'Data tahun yang ada di backup akan menggantikan data saat ini.\n\n'
          'File: ${picked.path.split('/').last}',
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
    try {
      final content = await picked.readAsString();
      final json    = jsonDecode(content) as Map<String, dynamic>;
      await _db.importFromJson(json);
      _showSuccess('Restore berhasil!');
    } catch (e) {
      _showError('Gagal restore: $e');
    } finally {
      setState(() => _loading = false);
    }
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
          'Sisa tahun lalu diupdate: ${CurrencyFormatter.format(result)}');
    }
  }

  // ─── RESET DATA ────────────────────────────────────

  Future<void> _resetData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ Reset Semua Data'),
        content: const Text(
          'Tindakan ini akan menghapus SEMUA data setoran dan perbaikan.\n\n'
          'Pastikan sudah melakukan backup terlebih dahulu!\n\n'
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

    // Konfirmasi kedua
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
      duration: const Duration(seconds: 4),
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
                title: 'Export / Backup',
                subtitle: 'Simpan data ke file JSON & bagikan',
                trailing: TextButton(
                  onPressed: _pilihTahunLalu,
                  child: Text('$_tahun ▾',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold)),
                ),
                onTap: _exportBackup,
              ),

              _settingCard(
                icon: Icons.download_for_offline,
                iconColor: AppColors.success,
                title: 'Restore / Import',
                subtitle: 'Pulihkan data dari file backup JSON',
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

              const SizedBox(height: 16),

              // ── BAHAYA ───────────────────────────
              _sectionTitle('Zona Berbahaya'),
              const SizedBox(height: 8),

              _settingCard(
                icon: Icons.delete_forever,
                iconColor: AppColors.danger,
                title: 'Reset Semua Data',
                subtitle: 'Hapus seluruh data setoran & perbaikan',
                titleColor: AppColors.danger,
                onTap: _resetData,
              ),

              const SizedBox(height: 24),

              // Info versi
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.directions_car,
                        size: 40, color: AppColors.primary),
                    const SizedBox(height: 8),
                    const Text(
                      'Setoran Mobil',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
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
            color: iconColor.withOpacity(0.1),
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

  Future<void> _pilihTahunLalu() async {
    final picked = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Pilih Tahun Export'),
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
