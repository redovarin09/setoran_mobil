import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class FullScreenImage extends StatelessWidget {
  final String imagePath;
  final String title;

  const FullScreenImage({
    super.key,
    required this.imagePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return FullScreenImageGallery(
      imagePaths:   [imagePath],
      initialIndex: 0,
      title: title,
    );
  }
}

class FullScreenImageGallery extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final String title;

  const FullScreenImageGallery({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<FullScreenImageGallery> createState() =>
      _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState
    extends State<FullScreenImageGallery> {
  late PageController _pageCtrl;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    final path = widget.imagePaths[_currentIndex];
    await Share.shareXFiles(
      [XFile(path)],
      text: '${widget.title} (${_currentIndex + 1}'
          '/${widget.imagePaths.length})',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${widget.title}  ${_currentIndex + 1}'
          '/${widget.imagePaths.length}',
          style: const TextStyle(
              color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _share,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Swipe antar foto
          PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.imagePaths.length,
            onPageChanged: (i) =>
                setState(() => _currentIndex = i),
            itemBuilder: (_, i) {
              final path = widget.imagePaths[i];
              final file = File(path);
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Center(
                  child: file.existsSync()
                      ? Image.file(file, fit: BoxFit.contain)
                      : Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined,
                                size: 64,
                                color: Colors.grey[600]),
                            const SizedBox(height: 12),
                            Text('Foto tidak ditemukan',
                                style: TextStyle(
                                    color: Colors.grey[400])),
                          ],
                        ),
                ),
              );
            },
          ),

          // Dot indicator bawah
          if (widget.imagePaths.length > 1)
            Positioned(
              bottom: 24,
              left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imagePaths.length,
                  (i) => AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 3),
                    width: i == _currentIndex ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentIndex
                          ? Colors.white
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

          // Arrow navigasi
          if (widget.imagePaths.length > 1) ...[
            if (_currentIndex > 0)
              Positioned(
                left: 8, top: 0, bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _pageCtrl.previousPage(
                      duration: const Duration(
                          milliseconds: 250),
                      curve: Curves.easeInOut,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            if (_currentIndex <
                widget.imagePaths.length - 1)
              Positioned(
                right: 8, top: 0, bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _pageCtrl.nextPage(
                      duration: const Duration(
                          milliseconds: 250),
                      curve: Curves.easeInOut,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
