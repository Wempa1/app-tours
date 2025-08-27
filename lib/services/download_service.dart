import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  final Dio _dio = Dio();

  /// Guarda en: {appSupport}/media/{type}/{tourId}/filename
  Future<File> downloadToPrivateDir({
    required Uri url,
    required String tourId,
    required String filename, // e.g. 'stop_1.mp3'
    String type = 'audio',    // 'audio' | 'images'
    String? expectedSha256,   // opcional
  }) async {
    final base = await getApplicationSupportDirectory(); // privado
    final dir = Directory('${base.path}/media/$type/$tourId');
    if (!await dir.exists()) await dir.create(recursive: true);

    final file = File('${dir.path}/$filename');
    await _dio.download(url.toString(), file.path);

    if (expectedSha256 != null) {
      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString();
      if (hash.toLowerCase() != expectedSha256.toLowerCase()) {
        await file.delete();
        throw Exception('Checksum mismatch for $filename');
      }
    }
    return file;
  }
}
