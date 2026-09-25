import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/db_helper.dart';
import '../../core/utils/backup.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/excel_exporter.dart';
import '../../core/utils/tahun.dart';
import '../../core/utils/week_helper.dart';
import '../onboarding/onboarding_screen.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  final _db  = DbHelper();
  int _tahun = DateTime.now().year;
  bool _loading = false;
  String _jenis = '';
  String _plat = '';
  int _jumlah = 0;
  int _jadwal = 0;

  @override
  void initState() {
    super.initState();
    _muatInfo();
  }

  Future<void> _muatInfo() async {
    final results = await Future.wait([
      _db.getJenisKendaraan(),
      _db.getPlatNomor(),
      _db.getJumlahMingguan(),
      _db.getJadwalHari(),
    ]);
    if (!mounted) return;
    setState(() {
      _jenis   = results[0] as String;
      _plat    = results[1] as String;
      _jumlah  = results[2] as int;
      _jadwal  = results[3] as int;
    });
  }

  // ─── EXPORT JSON ───────────────────────────────────

  Future<void> _exportBackup() async {
    setState(() => _loading = true);
    try {
      final json    = await _db.exportToJson(_tahun);
      final jsonStr = const JsonEncoder.withIndent('  ').convert(json);
      final dir     = await getApplicationDocumentsDirectory();
      final jenis   = await _db.getJenisKendaraan();
      final fileName=
          'backup_${sanitasiNamaFile(jenis)}_$_tahun.json';
      final file    = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Backup Setoran $_tahun — simpan file ini!',
          subject: fileName,
        ),
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

  // ─── RESTORE — SCAN FILE ───────────────────────────

  Future<void> _restoreBackup() async {
    // Tampilkan pilihan cara restore
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Cara Restore',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih file backup yang sudah disimpan sebelumnya',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textLight),
            ),
            const SizedBox(height: 16),

            // Opsi 1: Scan Downloads
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _restoreFromDownloads();
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder_open,
                    color: AppColors.primary),
              ),
              title: const Text('Scan Folder Downloads',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Cari file .json di /storage/Download'),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textLight),
            ),

            const Divider(height: 8),

            // Opsi 2: Pilih file (SAF — tanpa izin khusus,
            // jalan di semua Android termasuk 13+)
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _restoreFromPicker();
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.file_open,
                    color: AppColors.warning),
              ),
              title: const Text('Pilih File Backup…',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Cari file .json lewat pemilih file sistem'),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textLight),
            ),

            const Divider(height: 8),

            // Opsi 3: Paste JSON
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _restoreFromPaste();
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.paste,
                    color: AppColors.success),
              ),
              title: const Text('Tempel (Paste) JSON',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Buka file backup → Salin semua teks → Tempel di sini'),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textLight),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── RESTORE: SCAN DOWNLOADS ───────────────────────

  Future<void> _restoreFromDownloads() async {
    setState(() => _loading = true);

    // Cari file JSON di semua kemungkinan path
    final searchPaths = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/sdcard/Download',
      '/sdcard/Downloads',
    ];

    // Juga cari di internal app docs
    try {
      final appDir = await getApplicationDocumentsDirectory();
      searchPaths.add(appDir.path);
    } catch (_) {}

    final List<File> found = [];
    for (final path in searchPaths) {
      try {
        final dir = Directory(path);
        if (await dir.exists()) {
          final files = dir
              .listSync()
              .whereType<File>()
              .where((f) =>
                  f.path.endsWith('.json') &&
                  f.path.contains('backup'))
              .toList()
            ..sort((a, b) =>
                b.statSync().modified
                    .compareTo(a.statSync().modified));
          found.addAll(files);
        }
      } catch (_) {}
    }

    setState(() => _loading = false);

    if (found.isEmpty) {
      if (!mounted) return;
      _showTidakDitemukan();
      return;
    }

    // Tampilkan daftar file
    if (!mounted) return;
    final picked = await showDialog<File>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pilih File Backup'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: found.length,
            itemBuilder: (_, i) {
              final f    = found[i];
              final name = f.path.split('/').last;
              final mod  = f.statSync().modified;
              final tgl  =
                  '${mod.day}/${mod.month}/${mod.year}';
              return ListTile(
                leading: const Icon(Icons.file_present,
                    color: AppColors.primary),
                title: Text(name,
                    style: const TextStyle(fontSize: 13)),
                subtitle: Text('Diubah: $tgl',
                    style: const TextStyle(fontSize: 11)),
                onTap: () => Navigator.pop(context, f),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );

    if (picked != null) await _prosesRestore(picked);
  }

  void _showTidakDitemukan() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('File Tidak Ditemukan'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tidak ada file backup (.json) di folder Downloads.',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              'Cara mendapatkan file backup:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 6),
            Text(
              '1. Buka WhatsApp/Drive tempat file disimpan\n'
              '2. Download file backup .json\n'
              '3. Coba Restore lagi',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 12),
            Text(
              'Atau gunakan cara "Tempel JSON" jika file\n'
              'sudah bisa dibuka di HP.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restoreFromPaste();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success),
            child: const Text('Tempel JSON',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── RESTORE: PEMILIH FILE SISTEM (SAF) ──────────

  Future<void> _restoreFromPicker() async {
    setState(() => _loading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      final path = result?.files.single.path;
      if (path == null) return;
      await _prosesRestore(File(path));
    } catch (e) {
      _showError('Gagal memilih file: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ─── RESTORE: PASTE JSON ───────────────────────────

  Future<void> _restoreFromPaste() async {
    final ctrl = TextEditingController();

    // Coba auto-paste dari clipboard
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.contains('"setoran"')) {
        ctrl.text = data.text!;
      }
    } catch (_) {}

    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tempel JSON Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Buka file backup → pilih semua teks → salin → '
              'kembali ke sini → tempel di kotak bawah.',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textLight),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '{ "versi": 2, "tahun": 2026, ... }',
                hintStyle: TextStyle(fontSize: 11),
                isDense: true,
                contentPadding: EdgeInsets.all(10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final data =
                  await Clipboard.getData(Clipboard.kTextPlain);
              if (data?.text != null) ctrl.text = data!.text!;
            },
            child: const Text('📋 Paste'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Restore',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    try {
      jsonDecode(result.trim()); // validasi format
    } catch (_) {
      _showError(
          'Teks bukan format JSON yang valid. '
          'Pastikan menyalin seluruh isi file backup.');
      return;
    }

    // Buat file sementara lalu proses
    try {
      final dir  = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/restore_temp_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(result);
      await _prosesRestore(file);
      await file.delete();
    } catch (e) {
      _showError('Gagal restore: $e');
    }
  }

  // ─── PROSES RESTORE INTI ───────────────────────────

  Future<void> _prosesRestore(File file) async {
    String content;
    try {
      content = await file.readAsString();
    } catch (_) {
      _showError(
          'Tidak bisa membaca file. '
          'Gunakan cara "Tempel JSON" sebagai alternatif.');
      return;
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      _showError('File bukan format backup yang valid.');
      return;
    }

    final tahunBackup   = json['tahun'] ?? '?';
    final versiBackup   = json['versi']?.toString() ?? '?';
    final sisaBackup    = (json['sisa_tahun_lalu'] ?? 0) as int;
    final jmlSetoran    = (json['setoran'] as List?)?.length ?? 0;
    final jmlLog        =
        (json['pembayaran_log'] as List?)?.length ?? 0;
    final jmlPerbaikan  =
        (json['perbaikan'] as List?)?.length ?? 0;
    final exportedAt    =
        json['exported_at']?.toString().substring(0, 10) ?? '-';
    final jmlFoto 	= (json['images'] as Map?)?.length ?? 0;

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Restore'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Tahun', '$tahunBackup'),
            _infoRow('Versi', '$versiBackup'),
            _infoRow('Sisa Tahun Lalu',
                CurrencyFormatter.format(sisaBackup)),
            _infoRow('Data Setoran', '$jmlSetoran entri'),
            _infoRow('Cicilan', '$jmlLog entri'),
            _infoRow('Data Perbaikan', '$jmlPerbaikan entri'),
            _infoRow('Dibuat', exportedAt),
	    _infoRow('Foto Bukti', '$jmlFoto file'),

            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚠️ Data tahun $tahunBackup yang ada '
                'saat ini akan digantikan.',
                style: const TextStyle(
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
    try {
      await _db.importFromJson(json);
      _showSuccess('✅ Restore berhasil!');
    } catch (e) {
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
                  fontSize: 12, color: AppColors.textMedium)),
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
          'Sisa: ${CurrencyFormatter.format(result)}');
    }
  }

  // ─── EDIT KENDARAAN (FR-24) ──────────────────────────

  Future<void> _editKendaraan() async {
    final jenisCtrl = TextEditingController(text: _jenis);
    final platCtrl  = TextEditingController(text: _plat);
    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Jenis Kendaraan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: jenisCtrl,
              decoration: const InputDecoration(
                labelText: 'Jenis (kosong → Kendaraan Saya)',
                isDense: true,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: platCtrl,
              decoration: const InputDecoration(
                labelText: 'Plat nomor (opsional)',
                isDense: true,
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
            child: const Text('Simpan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result == true) {
      final jenis = jenisCtrl.text.trim().isEmpty
          ? 'Kendaraan Saya'
          : jenisCtrl.text.trim();
      await _db.setJenisKendaraan(jenis);
      await _db.setPlatNomor(platCtrl.text.trim());
      await _muatInfo();
      _showSuccess('Kendaraan: $jenis');
    }
  }

  // ─── EDIT TARGET MINGGUAN (FR-24) ────────────────────

  Future<void> _editTarget() async {
    final jumlahCtrl = TextEditingController(
        text: _jumlah.toString());
    int jadwal = _jadwal;
    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDag) => AlertDialog(
          title: const Text('Target Mingguan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: jumlahCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  labelText: 'Setoran per minggu',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Jadwal hari:',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(7, (i) {
                  final on = i == jadwal;
                  return GestureDetector(
                    onTap: () => setDag(() => jadwal = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: on
                            ? AppColors.primary
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        WeekHelper.hariPendek[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: on
                              ? Colors.white
                              : AppColors.textDark,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: const Text('Simpan',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      final jumlah =
          int.tryParse(jumlahCtrl.text) ?? 0;
      await _db.setJumlahMingguan(jumlah);
      await _db.setJadwalHari(jadwal);
      await _muatInfo();
      _showSuccess('Target mingguan disimpan');
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
        '✅ Sisa ${_tahun + 1} sudah diupdate!');
  }

  // ─── RESET ─────────────────────────────────────────

  Future<void> _resetData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('⚠️ Reset Semua Data'),
        content: const Text(
          'Akan menghapus SEMUA data: setoran, cicilan, '
          'perbaikan, foto, dan pengaturan — kembali ke awal.\n\n'
          'Backup terlebih dahulu!\n\n'
          'Tidak bisa dibatalkan.',
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
    if (!mounted) return;
    // FR-26: kembali ke onboarding setelah reset total.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
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
              _sectionTitle('Backup & Restore'),
              const SizedBox(height: 8),
              _settingCard(
                icon: Icons.upload_file,
                iconColor: AppColors.primary,
                title: 'Export / Backup (JSON)',
                subtitle: 'Simpan & bagikan data ke file JSON',
                trailing: _tahunBtn(),
                onTap: _exportBackup,
              ),
              _settingCard(
                icon: Icons.table_chart,
                iconColor: const Color(0xFF1B5E20),
                title: 'Export ke Excel (.xlsx)',
                subtitle: 'Laporan Excel 3 sheet',
                trailing: _tahunBtn(),
                onTap: _exportExcel,
              ),
              _settingCard(
                icon: Icons.download_for_offline,
                iconColor: AppColors.success,
                title: 'Restore / Import',
                subtitle:
                    'Scan Downloads atau tempel teks JSON',
                onTap: _restoreBackup,
              ),
              const SizedBox(height: 16),
              _sectionTitle('Kendaraan & Target'),
              const SizedBox(height: 8),
              _settingCard(
                icon: Icons.directions_car,
                iconColor: AppColors.primary,
                title: 'Jenis Kendaraan',
                subtitle: _jenis.isEmpty
                    ? 'Belum diatur'
                    : (_plat.isEmpty
                        ? _jenis
                        : '$_jenis · $_plat'),
                onTap: _editKendaraan,
              ),
              _settingCard(
                icon: Icons.event_repeat,
                iconColor: AppColors.success,
                title: 'Target Mingguan',
                subtitle:
                    '${CurrencyFormatter.format(_jumlah)} · '
                    '${WeekHelper.hariPendek[_jadwal]}',
                onTap: _editTarget,
              ),
              const SizedBox(height: 16),
              _sectionTitle('Konfigurasi'),
              const SizedBox(height: 8),
              _settingCard(
                icon: Icons.history,
                iconColor: AppColors.warning,
                title: 'Sisa Tahun Lalu',
                subtitle: 'Edit nominal sisa tahun sebelumnya',
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
              _sectionTitle('Zona Berbahaya'),
              const SizedBox(height: 8),
              _settingCard(
                icon: Icons.delete_forever,
                iconColor: AppColors.danger,
                title: 'Reset Semua Data',
                subtitle:
                    'Hapus total & kembali ke awal (onboarding)',
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
                    Text('v1.1.0',
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
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

  Widget _tahunBtn() => TextButton(
        onPressed: _pilihTahun,
        child: Text('$_tahun ▾',
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold)),
      );

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
          letterSpacing: 0.8,
        ),
      );

  Widget _settingCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? titleColor,
  }) =>
      Card(
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

  Future<void> _pilihTahun() async {
    final picked = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Pilih Tahun'),
        children: daftarTahun(DateTime.now().year).map((y) {
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
