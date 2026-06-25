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

  static Future<String> saveFromBytes(
      String fileName, List<int> bytes) async {
    final dir  = await _getBuktiDir();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
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

  // ─── Base64 untuk backup ────────────────────────────

  static Future<String?> toBase64(String fileName) async {
    try {
      if (fileName.isEmpty) return null;
      final path  = await getFullPath(fileName);
      final file  = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> fromBase64(
      String fileName, String b64) async {
    try {
      final bytes = base64Decode(b64);
      await saveFromBytes(fileName, bytes);
      return fileName;
    } catch (_) {
      return null;
    }
  }

  // ─── Encode/Decode List untuk DB ───────────────────

  static String encodeList(List<String> list) {
    if (list.isEmpty) return '';
    return jsonEncode(list);
  }

  static List<String> decodeList(String raw) {
    if (raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<String>();
      return [raw];
    } catch (_) {
      return raw.isEmpty ? [] : [raw];
    }
  }
}
