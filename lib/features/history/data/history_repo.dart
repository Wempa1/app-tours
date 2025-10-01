import 'package:avanti/features/history/data/history_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class HistoryRepo {
  Future<List<TourHistoryEntry>> listUserHistory({int limit});
}

class SupabaseHistoryRepo implements HistoryRepo {
  SupabaseClient get _db => Supabase.instance.client;

  String _requireUser() {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Necesitas iniciar sesión para ver el historial.');
    }
    return uid;
  }

  @override
  Future<List<TourHistoryEntry>> listUserHistory({int limit = 200}) async {
    final uid = _requireUser();

    // Pide la tabla de completados + join anidado a tours para obtener título/cover.
    final rows = await _db
        .from('tour_completions')
        .select(
          'tour_id,completed_at,duration_minutes,'
          'tours(id,slug,title,city,cover_url,duration_minutes,distance_km,published)',
        )
        .eq('user_id', uid)
        .order('completed_at', ascending: false)
        .limit(limit);

    final list = List<Map<String, dynamic>>.from(rows as List? ?? const []);
    final mapped = list.map(TourHistoryEntry.fromRow).toList();

    // Asegura orden desc por fecha, por si acaso
    mapped.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return mapped;
  }
}
