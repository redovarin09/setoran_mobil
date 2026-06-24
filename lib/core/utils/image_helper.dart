import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ImageHelper {
  static const _folder = 'bukti_bayar';

  static Future<Directory> _getBuktiDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir  = Directory('${docs.path}/$_folder');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<String> getFullPath(String fileName) async {
    final dir = await _getBuktiDir();
    return '${dir.path}/$fileName';
  }

  static Future<String> saveFromPath(String sourcePath) async {
    final dir      = await _getBuktiDir();
    final ext      = sourcePath.split('.').last.toLowerCase();
    final fileName =
        'bukti_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final dest = '${dir.path}/$fileName';
    await File(sourcePath).copy(dest);
    return fileName;
  }

  static Future<void> delete(String fileName) async {
    if (fileName.isEmpty) return;
    final path = await getFullPath(fileName);
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  static Future<bool> exists(String fileName) async {
    if (fileName.isEmpty) return false;
    final path = await getFullPath(fileName);
    return File(path).exists();
  }
}
