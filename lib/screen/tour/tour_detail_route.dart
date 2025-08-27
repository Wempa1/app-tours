import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'tour_detail_screen.dart';

class TourDetailRoute extends StatelessWidget {
  final String id;
  const TourDetailRoute({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TourDetailModel>(
      future: _loadTour(id),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load tour: ${snap.error}'),
            ),
          );
        }
        final tour = snap.data!;
        return TourDetailScreen(tour: tour);
      },
    );
  }
}

Future<TourDetailModel> _loadTour(String id) async {
  final sb = Supabase.instance.client;

  // Tour principal
  // Tour principal
  final row = await sb
      .from('tours_view_public')
      .select()
      .eq('id', id)
      .maybeSingle();

  if (row == null) {
    throw Exception('Tour not found: $id');
  }

  final name = (row['title'] ?? '') as String;
  final cover = (row['cover_url'] ?? '') as String;
  final stopCount = (row['stops_count'] as num?)?.toInt() ?? 0;
  final durationMin = (row['duration_minutes'] as num?)?.toInt() ?? 0;
  final lengthKm = (row['distance_km'] as num?)?.toDouble() ?? 0.0;
  final description =
      (row['description'] ?? row['short_description'] ?? '') as String;

  // Paradas (vista exacta)
  final stopsRows = await sb
      .from('tour_stops_view_public')
      .select('ord,title,distance_m,walk_min,thumb_url')
      .eq('tour_id', id)
      .order('ord', ascending: true);

  final stopsList = List<Map<String, dynamic>>.from(stopsRows as List? ?? const []);

  final stops = stopsList.map((m) {
    final ord = (m['ord'] as num?)?.toInt() ?? 0;
    final title = (m['title'] ?? '') as String;
    final distM = (m['distance_m'] as num?)?.toInt();
    final walkMin = (m['walk_min'] as num?)?.toInt();
    final subtitle =
        (distM != null && walkMin != null) ? '$distM m · $walkMin m' : null;
    return TourStop(
      order: ord == 0 ? 1 : ord,
      title: title.isEmpty ? 'Stop ${ord == 0 ? 1 : ord}' : title,
      subtitle: subtitle,
      thumbUrl: (m['thumb_url'] ?? '') as String?,
    );
  }).toList();
  // Paradas (vista exacta)
  final stopsRows = await sb
      .from('tour_stops_view_public')
      .select('ord,title,distance_m,walk_min,thumb_url')
      .eq('tour_id', id)
      .order('ord', ascending: true);

  final stopsList = List<Map<String, dynamic>>.from(stopsRows as List? ?? const []);

  final stops = stopsList.map((m) {
    final ord = (m['ord'] as num?)?.toInt() ?? 0;
    final title = (m['title'] ?? '') as String;
    final distM = (m['distance_m'] as num?)?.toInt();
    final walkMin = (m['walk_min'] as num?)?.toInt();
    final subtitle =
        (distM != null && walkMin != null) ? '$distM m · $walkMin m' : null;
    return TourStop(
      order: ord == 0 ? 1 : ord,
      title: title.isEmpty ? 'Stop ${ord == 0 ? 1 : ord}' : title,
      subtitle: subtitle,
      thumbUrl: (m['thumb_url'] ?? '') as String?,
    );
  }).toList();

  return TourDetailModel(
    id: id,
    name: name,
    logoUrl: null,
    coverUrl: cover,
    stopCount: stopCount,
    duration: Duration(minutes: durationMin),
    lengthKm: lengthKm,
    stops: stops,
    description: description,
  );
}
