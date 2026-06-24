import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/image_helper.dart';
import 'full_screen_image.dart';

class BuktiBayarWidget extends StatefulWidget {
  final List<String> initialFileNames;
  final ValueChanged<List<String>> onChanged;
  final int maxFoto;

  const BuktiBayarWidget({
    super.key,
    required this.initialFileNames,
    required this.onChanged,
    this.maxFoto = 5,
  });

  @override
  State<BuktiBayarWidget> createState() => _BuktiBayarWidgetState();
}

class _BuktiBayarWidgetState extends State<BuktiBayarWidget> {
  final _picker = ImagePicker();
  late List<String> _fileNames;
  final Map<String, String> _pathCache = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fileNames = List.from(widget.initialFileNames);
    _loadAllPaths();
  }

  Future<void> _loadAllPaths() async {
    for (final name in _fileNames) {
      if (!_pathCache.containsKey(name)) {
        _pathCache[name] = await ImageHelper.getFullPath(name);
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_fileNames.length >= widget.maxFoto) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Maksimal ${widget.maxFoto} foto bukti bayar'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    try {
      setState(() => _loading = true);

      if (source == ImageSource.gallery) {
        // Multi-pick dari galeri
        final remaining = widget.maxFoto - _fileNames.length;
        final List<XFile> picked =
            await _picker.pickMultiImage(
          imageQuality: 75,
          limit: remaining,
        );
        for (final xfile in picked) {
          final name = await ImageHelper.saveFromPath(xfile.path);
          final path = await ImageHelper.getFullPath(name);
          _fileNames.add(name);
          _pathCache[name] = path;
        }
      } else {
        // Kamera: 1 per 1
        final XFile? picked = await _picker.pickImage(
          source: source,
          imageQuality: 75,
          maxWidth: 1280,
          maxHeight: 1280,
        );
        if (picked != null) {
          final name = await ImageHelper.saveFromPath(picked.path);
          final path = await ImageHelper.getFullPath(name);
          _fileNames.add(name);
          _pathCache[name] = path;
        }
      }

      widget.onChanged(List.from(_fileNames));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal ambil foto: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _hapusFoto(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Foto'),
        content: Text(
            'Hapus foto ${index + 1} dari ${_fileNames.length}?'),
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
    if (confirm != true) return;

    final name = _fileNames[index];
    await ImageHelper.delete(name);
    setState(() {
      _fileNames.removeAt(index);
      _pathCache.remove(name);
    });
    widget.onChanged(List.from(_fileNames));
  }

  void _lihatFull(int index) {
    final name = _fileNames[index];
    final path = _pathCache[name];
    if (path == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageGallery(
          imagePaths:   _fileNames
              .map((n) => _pathCache[n] ?? '')
              .where((p) => p.isNotEmpty)
              .toList(),
          initialIndex: index,
          title: 'Bukti Bayar',
        ),
      ),
    );
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Tambah Foto Bukti'
              ' (${_fileNames.length}/${widget.maxFoto})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt,
                    color: AppColors.primary),
              ),
              title: const Text('Ambil Foto',
                  style:
                      TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Buka kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library,
                    color: AppColors.success),
              ),
              title: const Text('Pilih dari Galeri',
                  style:
                      TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                  'Bisa pilih beberapa sekaligus '
                  '(max ${widget.maxFoto - _fileNames.length} lagi)'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text('Bukti Bayar',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _fileNames.length >= widget.maxFoto
                        ? AppColors.danger.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_fileNames.length}/${widget.maxFoto}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          _fileNames.length >= widget.maxFoto
                              ? AppColors.danger
                              : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            if (_loading)
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Grid foto horizontal
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _fileNames.length +
                (_fileNames.length < widget.maxFoto ? 1 : 0),
            itemBuilder: (_, i) {
              // Tile tambah foto
              if (i == _fileNames.length) {
                return _buildAddTile();
              }
              return _buildFotoTile(i);
            },
          ),
        ),

        // Hint
        if (_fileNames.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Belum ada foto. Tap + untuk menambahkan.',
            style: TextStyle(
                fontSize: 11, color: Colors.grey[400]),
          ),
        ] else ...[
          const SizedBox(height: 6),
          Text(
            'Tap foto untuk lihat penuh • '
            'Tahan untuk hapus',
            style: TextStyle(
                fontSize: 11, color: Colors.grey[400]),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildAddTile() {
    return GestureDetector(
      onTap: _showSourcePicker,
      child: Container(
        width: 90, height: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 28,
                color: AppColors.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 6),
            Text(
              'Tambah\nFoto',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoTile(int index) {
    final name = _fileNames[index];
    final path = _pathCache[name];

    return GestureDetector(
      onTap: () => _lihatFull(index),
      onLongPress: () => _hapusFoto(index),
      child: Container(
        width: 90, height: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.divider, width: 1),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Foto
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: path != null && File(path).existsSync()
                  ? Image.file(File(path), fit: BoxFit.cover)
                  : Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.grey[400], size: 28)),
            ),

            // Nomor foto
            Positioned(
              top: 4, left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Tombol hapus (X)
            Positioned(
              top: 2, right: 2,
              child: GestureDetector(
                onTap: () => _hapusFoto(index),
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
