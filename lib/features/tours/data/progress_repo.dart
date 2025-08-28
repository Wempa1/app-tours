import 'package:supabase_flutter/supabase_flutter.dart';

class TourProgress {
  final String userId;
  final String tourId;
  final int completedStops;
  final String? lastStopId;

  const TourProgress({
    required this.userId,
    required this.tourId,
    required this.completedStops,
    this.lastStopId,
  });

  factory TourProgress.fromJson(Map<String, dynamic> j) => TourProgress(
    userId: j['user_id'] as String,
    tourId: j['tour_id'] as String,
    completedStops: (j['completed_stops'] as num?)?.toInt() ?? 0,
    lastStopId: j['last_stop_id'] as String?,
  );
}

abstract class ProgressRepo {
  Future<TourProgress?> getProgress(String tourId);
  Future<TourProgress> setProgress({
    required String tourId,
    String? lastStopId,
    required int completedStops,
  });
  Future<void> recordCompletion({required String tourId, int? durationMinutes});
}

class SupabaseProgressRepo implements ProgressRepo {
  SupabaseClient get _db => Supabase.instance.client;

  String _requireUser() {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Necesitas iniciar sesión para guardar progreso.');
    }
    return uid;
  }

  @override
  Future<TourProgress?> getProgress(String tourId) async {
    _requireUser();
    final row = await _db
        .from('progress')
        .select()
        .eq('tour_id', tourId)
        .maybeSingle();
    if (row == null) return null;
    return TourProgress.fromJson(Map<String, dynamic>.from(row));
  }

  @override
  Future<TourProgress> setProgress({
    required String tourId,
    String? lastStopId,
    required int completedStops,
  }) async {
    final uid = _requireUser();
    final data = {
      'user_id': uid,
      'tour_id': tourId,
      'last_stop_id': lastStopId,
      'completed_stops': completedStops,
    };
    final rows = await _db.from('progress').upsert(data).select().maybeSingle();
    if (rows == null) {
      // si el upsert no devuelve fila, pedimos el estado actual
      return (await getProgress(tourId)) ??
          TourProgress(
            userId: uid,
            tourId: tourId,
            completedStops: completedStops,
          );
    }
    return TourProgress.fromJson(Map<String, dynamic>.from(rows));
  }

  @override
  Future<void> recordCompletion({
    required String tourId,
    int? durationMinutes,
  }) async {
    _requireUser();
    // Usa tu función SQL SECURITY DEFINER: record_tour_completion(p_tour_id, p_duration_minutes)
    await _db.rpc(
      'record_tour_completion',
      params: {'p_tour_id': tourId, 'p_duration_minutes': durationMinutes},
    );
  }
}
