// lib/features/tours/data/caching_tour_repo.dart
import 'package:avanti/core/services/file_cache_service.dart';
import 'package:avanti/core/services/retry.dart';
import 'package:avanti/features/tours/data/models.dart';
import 'package:avanti/features/tours/data/tour_repo.dart';

class CachingTourRepo implements TourRepo {
  final TourRepo remote;
  final FileCacheService cache;

  CachingTourRepo({required this.remote, FileCacheService? cache})
      : cache = cache ?? FileCacheService(); // <- sin `const`

  @override
  Future<List<Tour>> listCatalog({int limit = 50}) {
    final key = 'catalog_v1_limit_$limit';
    return cache.getOrFetch<List<Tour>>(
      key: key,
      fetch: () =>
          withRetry(() => remote.listCatalog(limit: limit), maxAttempts: 3),
      encoder: (value) => value.map((t) => t.toJson()).toList(),
      decoder: (json) => (json as List)
          .map((e) => Tour.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  @override
  Future<List<Tour>> listPublished({int limit = 50}) {
    final key = 'published_v1_limit_$limit';
    return cache.getOrFetch<List<Tour>>(
      key: key,
      fetch: () =>
          withRetry(() => remote.listPublished(limit: limit), maxAttempts: 3),
      encoder: (value) => value.map((t) => t.toJson()).toList(),
      decoder: (json) => (json as List)
          .map((e) => Tour.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  @override
  Future<List<Tour>> toursNearby({
    required double lat,
    required double lon,
    int limit = 12,
  }) {
    final key =
        'nearby_v1_${lat.toStringAsFixed(3)}_${lon.toStringAsFixed(3)}_$limit';
    return cache.getOrFetch<List<Tour>>(
      key: key,
      fetch: () => withRetry(
        () => remote.toursNearby(lat: lat, lon: lon, limit: limit),
        maxAttempts: 2, // ubicaciones cambian a menudo: caché corta
        baseDelay: const Duration(milliseconds: 400),
      ),
      encoder: (value) => value.map((t) => t.toJson()).toList(),
      decoder: (json) => (json as List)
          .map((e) => Tour.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  @override
  Future<List<StopWithI18n>> listStopsWithI18n({
    required String tourId,
    required String lang,
  }) {
    final key = 'stops_v1_${tourId}_$lang';
    return cache.getOrFetch<List<StopWithI18n>>(
      key: key,
      fetch: () => withRetry(
        () => remote.listStopsWithI18n(tourId: tourId, lang: lang),
        maxAttempts: 3,
      ),
      encoder: (value) => value.map((s) => s.toJson()).toList(),
      decoder: (json) => (json as List)
          .map((e) => StopWithI18n.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  @override
  Future<String?> signedAudioUrl(
    String? audioPath, {
    int expiresSeconds = 600,
  }) {
    // No cacheamos URLs firmadas (caducan).
    return withRetry(
      () => remote.signedAudioUrl(audioPath, expiresSeconds: expiresSeconds),
      maxAttempts: 2,
      baseDelay: const Duration(milliseconds: 500),
    );
  }
}
