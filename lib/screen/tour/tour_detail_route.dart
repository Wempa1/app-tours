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

  // 1) Tour principal
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

  // 2) Paradas (con fallback de tablas/vistas)
  final stops = await _loadStopsWithFallback(id);

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

Future<List<TourStop>> _loadStopsWithFallback(String tourId) async {
  final sb = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> query(String table) async {
    final res = await sb
        .from(table)
        .select()
        .eq('tour_id', tourId)
        .order('ord', ascending: true);
    return List<Map<String, dynamic>>.from(res as List? ?? const []);
  }

  List<Map<String, dynamic>> list = const [];

  // Intento 1: tour_stops_view_public
  try {
    list = await query('tour_stops_view_public');
  } on PostgrestException {
    list = const [];
  }

  // Intento 2: tour_stops
  if (list.isEmpty) {
    try {
      list = await query('tour_stops');
    } on PostgrestException {
      list = const [];
    }
  }

  // Intento 3: stops_view_public
  if (list.isEmpty) {
    try {
      list = await query('stops_view_public');
    } on PostgrestException {
      list = const [];
    }
  }

  if (list.isEmpty) return const [];

  return list.map(_mapStop).toList();
}

TourStop _mapStop(Map<String, dynamic> m) {
  int asInt(dynamic v) => (v as num?)?.toInt() ?? 0;
  String asStr(dynamic v) => (v ?? '').toString();

  final ord = asInt(m['ord'] ?? m['order'] ?? m['position'] ?? m['index']);
  final title = asStr(m['title'] ?? m['name']);
  final distanceM = (m['distance_m'] as num?)?.toInt();
  final walkMin = (m['walk_min'] as num?)?.toInt();
  final subtitle = (distanceM != null && walkMin != null)
      ? '$distanceM m · $walkMin min'
      : (m['subtitle'] as String?);

  return TourStop(
    order: ord == 0 ? 1 : ord,
    title: title.isEmpty ? 'Stop $ord' : title,
    subtitle: subtitle,
    thumbUrl: (m['thumb_url'] ?? m['image_url']) as String?,
  );
}
