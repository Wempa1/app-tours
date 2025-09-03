// lib/core/services/file_cache_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Cache de archivos simple (solo móvil/desktop; no soporta Web).
/// - TTL configurable (default: 12h)
/// - Nombres de archivo seguros (hash SHA-1 base64-url)
/// - Escritura atómica (.tmp -> rename)
class FileCacheService {
  final Duration ttl;
  final String namespace;

  // ⬇️ OJO: constructor ya NO es const porque _cachedBaseDir no es final
  FileCacheService({
    this.ttl = const Duration(hours: 12),
    this.namespace = 'avanti_cache',
  });

  Directory? _cachedBaseDir;

  Future<Directory> _baseDir() async {
    if (_cachedBaseDir != null) return _cachedBaseDir!;
    final tmp = await getTemporaryDirectory();
    final dir = Directory(p.join(tmp.path, namespace));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cachedBaseDir = dir;
    return dir;
  }

  /// Convierte la key en un nombre de archivo seguro para el FS.
  String _safeName(String key) {
    final digest = sha1.convert(utf8.encode(key));
    final b64 = base64Url.encode(digest.bytes); // sin '/' ni '+'
    return '$b64.json';
  }

  Future<File> _fileFor(String key) async {
    final dir = await _baseDir();
    return File(p.join(dir.path, _safeName(key)));
  }

  Future<T?> read<T>(String key, T Function(dynamic json) decoder) async {
    try {
      final f = await _fileFor(key);
      if (!await f.exists()) return null;

      final stat = await f.stat();
      final isFresh = DateTime.now().difference(stat.modified) <= ttl;
      if (!isFresh) {
        // Limpieza proactiva de expirados
        try {
          await f.delete();
        } catch (_) {}
        return null;
      }

      final content = await f.readAsString();
      final json = jsonDecode(content);
      return decoder(json);
    } catch (_) {
      // tolerante a errores de lectura/parseo
      return null;
    }
  }

  Future<void> write(String key, Object data) async {
    final f = await _fileFor(key);
    final tmp = File('${f.path}.tmp');
    final content = jsonEncode(data);

    // Escritura atómica: escribir -> flush -> rename (reemplaza si existe)
    await tmp.writeAsString(content, flush: true);
    if (await f.exists()) {
      try {
        await f.delete();
      } catch (_) {}
    }
    await tmp.rename(f.path);
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
    try {
      final f = await _fileFor(key);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
  }

  /// Elimina todos los archivos expirados en el namespace.
  Future<void> pruneExpired() async {
    final dir = await _baseDir();
    try {
      final now = DateTime.now();
      await for (final ent in dir.list(followLinks: false)) {
        if (ent is File) {
          final stat = await ent.stat();
          final isFresh = now.difference(stat.modified) <= ttl;
          if (!isFresh) {
            try {
              await ent.delete();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  /// Elimina todo el namespace de caché.
  Future<void> invalidateAll() async {
    final dir = await _baseDir();
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
    // Reset para recrear en el siguiente uso
    _cachedBaseDir = null;
  }

  /// Útil para debug/logs.
  Future<String> debugPathForKey(String key) async {
    final f = await _fileFor(key);
    return f.path;
    }
}
