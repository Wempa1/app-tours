// lib/features/tours/data/tour_repo.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

/// Contrato de acceso a datos de Tours (capa BE).
abstract class TourRepo {
  /// Catálogo público (vista `tours_view_public`), ordenado por título.
  Future<List<Tour>> listCatalog({int limit = 50});

  /// Tours publicados (tabla `tours`), ordenado por título.
  Future<List<Tour>> listPublished({int limit = 50});

  /// Tours cercanos vía RPC `tours_nearby(p_lat, p_lon, p_limit)`.
  Future<List<Tour>> toursNearby({
    required double lat,
    required double lon,
    int limit = 12,
  });

  /// Paradas + i18n para un tour (ordenadas por `order_index` asc).
  Future<List<StopWithI18n>> listStopsWithI18n({
    required String tourId,
    required String lang, // 'es', 'en', ...
  });

  /// Firma y devuelve una URL temporal para un archivo de audio privado.
  Future<String?> signedAudioUrl(String? audioPath, {int expiresSeconds = 600});
}

/// Implementación Supabase del repositorio.
class SupabaseTourRepo implements TourRepo {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<List<Tour>> listCatalog({int limit = 50}) async {
    final rows = await _db
        .from('tours_view_public')
        .select()
        .order('title', ascending: true)
        .limit(limit);

    final list = List<Map<String, dynamic>>.from(rows as List? ?? const []);
    return list.map(Tour.fromJson).toList();
  }

  @override
  Future<List<Tour>> listPublished({int limit = 50}) async {
    final rows = await _db
        .from('tours')
        .select()
        .eq('published', true)
        // Si tu schema tiene 'priority', puedes volver a usarla.
        .order('title', ascending: true)
        .limit(limit);

    final list = List<Map<String, dynamic>>.from(rows as List? ?? const []);
    return list.map(Tour.fromJson).toList();
  }

  @override
  Future<List<Tour>> toursNearby({
    required double lat,
    required double lon,
    int limit = 12,
  }) async {
    final rows = await _db.rpc(
      'tours_nearby',
      params: {'p_lat': lat, 'p_lon': lon, 'p_limit': limit},
    );

    final list = List<Map<String, dynamic>>.from(rows as List? ?? const []);
    return list.map(Tour.fromJson).toList();
  }

  @override
  Future<List<StopWithI18n>> listStopsWithI18n({
    required String tourId,
    required String lang,
  }) async {
    // 1) Stops ordenados
    final stopsRows = await _db
        .from('stops')
        .select('id,tour_id,order_index,lat,lon')
        .eq('tour_id', tourId)
        .order('order_index', ascending: true);

    final stopsList =
        List<Map<String, dynamic>>.from(stopsRows as List? ?? const []);
    if (stopsList.isEmpty) return const [];

    final ids = stopsList.map((e) => (e['id']).toString()).toList();

    // 2) i18n de esos stops en el idioma solicitado
    final i18nRows = await _db
        .from('stop_i18n')
        .select()
        .eq('lang', lang)
        .inFilter('stop_id', ids);

    final i18nList =
        List<Map<String, dynamic>>.from(i18nRows as List? ?? const []);
    final i18nById = {
      for (final m in i18nList) (m['stop_id']).toString(): StopI18n.fromJson(m),
    };

    // 3) Merge
    return stopsList
        .map((m) => StopWithI18n(
              stop: Stop.fromJson(m),
              i18n: i18nById[(m['id']).toString()],
            ))
        .toList();
  }

  @override
  Future<String?> signedAudioUrl(
    String? audioPath, {
    int expiresSeconds = 600,
  }) async {
    if (audioPath == null || audioPath.isEmpty) return null;

    // Bucket privado para audio
    const bucket = 'avanti-audio';
    final url = await _db.storage
        .from(bucket)
        .createSignedUrl(audioPath, expiresSeconds);

    return url;
  }
}
