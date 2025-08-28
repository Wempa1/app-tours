import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileCacheService {
  final Duration ttl;
  final String namespace;
  const FileCacheService({
    this.ttl = const Duration(hours: 12),
    this.namespace = 'avanti_cache',
  });

  Future<File> _fileFor(String key) async {
    final dir = await getTemporaryDirectory();
    final base = Directory(p.join(dir.path, namespace));
    if (!await base.exists()) {
      await base.create(recursive: true);
    }
    return File(p.join(base.path, '$key.json'));
  }

  Future<T?> read<T>(String key, T Function(dynamic json) decoder) async {
    try {
      final f = await _fileFor(key);
      if (!await f.exists()) return null;

      final stat = await f.stat();
      final isFresh = DateTime.now().difference(stat.modified) <= ttl;
      if (!isFresh) return null;

      final content = await f.readAsString();
      final json = jsonDecode(content);
      return decoder(json);
    } catch (_) {
      return null; // tolerante a errores de lectura/parseo
    }
  }

  Future<void> write(String key, Object data) async {
    final f = await _fileFor(key);
    final content = jsonEncode(data);
    await f.writeAsString(content, flush: true);
  }

  /// Devuelve el valor cacheado si fresco; si no, ejecuta [fetch],
  /// guarda el resultado y lo devuelve.
  Future<T> getOrFetch<T>({
    required String key,
    required Future<T> Function() fetch,
    required Object Function(T value) encoder,
    required T Function(dynamic json) decoder,
  }) async {
    final cached = await read<T>(key, decoder);
    if (cached != null) return cached;

    final fresh = await fetch();
    try {
      await write(key, encoder(fresh));
    } catch (_) {
      // ignoramos fallos de escritura de caché
    }
    return fresh;
  }

  Future<void> invalidate(String key) async {
    final f = await _fileFor(key);
    if (await f.exists()) {
      await f.delete();
    }
  }
}
