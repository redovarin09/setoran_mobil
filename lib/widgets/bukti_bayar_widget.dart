import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/image_helper.dart';
import 'full_screen_image.dart';

class BuktiBayarWidget extends StatefulWidget {
  final String initialFileName;
  final ValueChanged<String> onChanged;

  const BuktiBayarWidget({
    super.key,
    required this.initialFileName,
    required this.onChanged,
  });

  @override
  State<BuktiBayarWidget> createState() => _BuktiBayarWidgetState();
}

class _BuktiBayarWidgetState extends State<BuktiBayarWidget> {
  final _picker = ImagePicker();
  String _fileName = '';
  String? _fullPath;
  bool _loadingPath = false;

  @override
  void initState() {
    super.initState();
    _fileName = widget.initialFileName;
    if (_fileName.isNotEmpty) _loadPath();
  }

  Future<void> _loadPath() async {
    setState(() => _loadingPath = true);
    _fullPath = await ImageHelper.getFullPath(_fileName);
    setState(() => _loadingPath = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (picked == null) return;

      // Hapus foto lama jika ada
      if (_fileName.isNotEmpty) {
        await ImageHelper.delete(_fileName);
      }

      final newName = await ImageHelper.saveFromPath(picked.path);
      final newPath = await ImageHelper.getFullPath(newName);

      setState(() {
        _fileName = newName;
        _fullPath = newPath;
      });
      widget.onChanged(newName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal ambil foto: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  Future<void> _showSourcePicker() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 12, horizontal: 16),
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
                  style: TextStyle(fontWeight: FontWeight.w600)),
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
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Buka galeri foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _hapusFoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Bukti Bayar'),
        content: const Text('Yakin ingin menghapus foto ini?'),
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

    await ImageHelper.delete(_fileName);
    setState(() {
      _fileName = '';
      _fullPath = null;
    });
    widget.onChanged('');
  }

  void _lihatFull() {
    if (_fullPath == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImage(
          imagePath: _fullPath!,
          title: 'Bukti Bayar',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.attach_file,
                    size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Bukti Bayar',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (_fileName.isNotEmpty)
              TextButton.icon(
                onPressed: _hapusFoto,
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: AppColors.danger),
                label: const Text('Hapus',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.danger)),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Area foto
        GestureDetector(
          onTap: _fileName.isEmpty ? _showSourcePicker : _lihatFull,
          child: Container(
            width: double.infinity,
            height: _fileName.isEmpty ? 100 : 160,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _fileName.isEmpty
                    ? AppColors.divider
                    : AppColors.primary.withValues(alpha: 0.3),
                width: _fileName.isEmpty ? 1.5 : 1,
                style: _fileName.isEmpty
                    ? BorderStyle.solid
                    : BorderStyle.solid,
              ),
            ),
            child: _loadingPath
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2))
                : _fileName.isEmpty
                    ? _buildEmpty()
                    : _buildPreview(),
          ),
        ),

        if (_fileName.isNotEmpty) ...[
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: _showSourcePicker,
              icon: const Icon(Icons.refresh,
                  size: 14, color: AppColors.primary),
              label: const Text('Ganti Foto',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.primary)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4)),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEmpty() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined,
            size: 32, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'Tap untuk tambah foto bukti bayar',
          style: TextStyle(
              fontSize: 12, color: Colors.grey[400]),
        ),
        const SizedBox(height: 4),
        Text(
          'Kamera atau Galeri',
          style: TextStyle(
              fontSize: 11, color: Colors.grey[300]),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    if (_fullPath == null) {
      return const Center(
          child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2));
    }

    final file = File(_fullPath!);
    if (!file.existsSync()) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined,
              size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text('File tidak ditemukan',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey[400])),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            file,
            fit: BoxFit.cover,
          ),
        ),
        // Overlay tap hint
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(10)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.zoom_in,
                    size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Tap untuk lihat penuh',
                  style: TextStyle(
                      fontSize: 11, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
