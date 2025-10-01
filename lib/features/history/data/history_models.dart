import 'package:avanti/features/tours/data/models.dart';

class TourHistoryEntry {
  final String tourId;
  final DateTime completedAt;
  final int? durationMinutes;
  final Tour? tour; // detalles del tour, si vienen anidados

  const TourHistoryEntry({
    required this.tourId,
    required this.completedAt,
    this.durationMinutes,
    this.tour,
  });

  /// Row típico de Supabase:
  /// {
  ///   "tour_id": "...",
  ///   "completed_at": "2024-06-01T12:34:56Z",
  ///   "duration_minutes": 42,
  ///   "tours": { ... } // anidado si se pidió en el select
  /// }
  factory TourHistoryEntry.fromRow(Map<String, dynamic> row) {
    final dynamic tourMap = row['tours'] ?? row['tour'];
    Tour? tour;
    if (tourMap is Map) {
      tour = Tour.fromJson(Map<String, dynamic>.from(tourMap));
    }

    final completedRaw = row['completed_at'];
    DateTime completedAt;
    if (completedRaw is String) {
      completedAt = DateTime.tryParse(completedRaw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else if (completedRaw is DateTime) {
      completedAt = completedRaw;
    } else {
      completedAt = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return TourHistoryEntry(
      tourId: row['tour_id'] as String,
      completedAt: completedAt,
      durationMinutes: (row['duration_minutes'] as num?)?.toInt(),
      tour: tour,
    );
  }
}
