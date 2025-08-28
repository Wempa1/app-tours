import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

abstract class TourRepo {
  Future<List<Tour>> listCatalog({int limit});
  Future<List<Tour>> listPublished({int limit});
  Future<List<Tour>> toursNearby({
    required double lat,
    required double lon,
    int limit,
  });
  Future<List<StopWithI18n>> listStopsWithI18n({
    required String tourId,
    required String lang, // 'es', 'en', ...
  });

  Future<String?> signedAudioUrl(String? audioPath, {int expiresSeconds});
}

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
        .order('priority', ascending: true)
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
    final stopsRows = await _db
        .from('stops')
        .select('id,tour_id,order_index,lat,lon')
        .eq('tour_id', tourId)
        .order('order_index', ascending: true);

    final stopsList = List<Map<String, dynamic>>.from(
      stopsRows as List? ?? const [],
    );
    final ids = stopsList.map((e) => e['id'] as String).toList();
    if (ids.isEmpty) return [];

    final i18nRows = await _db
        .from('stop_i18n')
        .select()
        .eq('lang', lang)
        .inFilter('stop_id', ids);

    final i18nList = List<Map<String, dynamic>>.from(
      i18nRows as List? ?? const [],
    );
    final i18nById = {
      for (final m in i18nList) m['stop_id'] as String: StopI18n.fromJson(m),
    };

    return stopsList
        .map(
          (m) => StopWithI18n(
            stop: Stop.fromJson(m),
            i18n: i18nById[m['id'] as String],
          ),
        )
        .toList();
  }

  @override
  Future<String?> signedAudioUrl(
    String? audioPath, {
    int expiresSeconds = 600,
  }) async {
    if (audioPath == null || audioPath.isEmpty) return null;
    final res = await _db.storage
        .from('avanti-audio')
        .createSignedUrl(audioPath, expiresSeconds);
    return res;
  }
}
