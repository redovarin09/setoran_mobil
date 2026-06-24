import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class FullScreenImage extends StatefulWidget {
  final String imagePath;
  final String title;

  const FullScreenImage({
    super.key,
    required this.imagePath,
    required this.title,
  });

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  final _transformCtrl = TransformationController();
  bool _isZoomed = false;

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    await Share.shareXFiles(
      [XFile(widget.imagePath)],
      text: widget.title,
    );
  }

  void _resetZoom() {
    _transformCtrl.value = Matrix4.identity();
    setState(() => _isZoomed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          if (_isZoomed)
            IconButton(
              icon: const Icon(Icons.zoom_out, color: Colors.white),
              onPressed: _resetZoom,
              tooltip: 'Reset zoom',
            ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _share,
            tooltip: 'Bagikan',
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          transformationController: _transformCtrl,
          minScale: 0.5,
          maxScale: 5.0,
          onInteractionEnd: (details) {
            setState(() {
              _isZoomed =
                  _transformCtrl.value != Matrix4.identity();
            });
          },
          child: Image.file(
            File(widget.imagePath),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_outlined,
                    size: 64, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'Foto tidak dapat ditampilkan',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
