import 'dart:convert';
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
    await File(sourcePath).copy('${dir.path}/$fileName');
    return fileName;
  }

  static Future<void> delete(String fileName) async {
    if (fileName.isEmpty) return;
    try {
      final path = await getFullPath(fileName);
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  static Future<void> deleteAll(List<String> fileNames) async {
    for (final name in fileNames) {
      await delete(name);
    }
  }

  static Future<bool> exists(String fileName) async {
    if (fileName.isEmpty) return false;
    final path = await getFullPath(fileName);
    return File(path).exists();
  }

  // ─── Konversi List <-> String untuk DB ─────────────

  /// List<String> → JSON string untuk disimpan di DB
  static String encodeList(List<String> list) {
    if (list.isEmpty) return '';
    return jsonEncode(list);
  }

  /// JSON string dari DB → List<String>
  /// Backward compatible: string biasa (1 foto lama) juga bisa
  static List<String> decodeList(String raw) {
    if (raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.cast<String>();
      }
      // Kalau bukan list (format lama), bungkus jadi list
      return [raw];
    } catch (_) {
      // Format lama: string biasa = 1 filename
      return [raw];
    }
  }
}
