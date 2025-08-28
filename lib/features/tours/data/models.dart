class Tour {
  final String id;
  final String slug;
  final String title;
  final String? city;
  final String? coverUrl;
  final int? durationMinutes;
  final double? distanceKm;
  final bool? published;

  Tour({
    required this.id,
    required this.slug,
    required this.title,
    this.city,
    this.coverUrl,
    this.durationMinutes,
    this.distanceKm,
    this.published,
  });

  factory Tour.fromJson(Map<String, dynamic> j) => Tour(
    id: j['id'] as String,
    slug: j['slug'] as String? ?? '',
    title: j['title'] as String? ?? '',
    city: j['city'] as String?,
    coverUrl: j['cover_url'] as String?,
    durationMinutes: (j['duration_minutes'] as num?)?.toInt(),
    distanceKm: (j['distance_km'] as num?)?.toDouble(),
    published: j['published'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'title': title,
    'city': city,
    'cover_url': coverUrl,
    'duration_minutes': durationMinutes,
    'distance_km': distanceKm,
    'published': published,
  };
}

class Stop {
  final String id;
  final String tourId;
  final int orderIndex;
  final double? lat;
  final double? lon;

  Stop({
    required this.id,
    required this.tourId,
    required this.orderIndex,
    this.lat,
    this.lon,
  });

  factory Stop.fromJson(Map<String, dynamic> j) => Stop(
    id: j['id'] as String,
    tourId: j['tour_id'] as String,
    orderIndex: (j['order_index'] as num).toInt(),
    lat: (j['lat'] as num?)?.toDouble(),
    lon: (j['lon'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tour_id': tourId,
    'order_index': orderIndex,
    'lat': lat,
    'lon': lon,
  };
}

class StopI18n {
  final String stopId;
  final String lang;
  final String title;
  final String? description;
  final String? audioPath;
  final String? imagePath;

  StopI18n({
    required this.stopId,
    required this.lang,
    required this.title,
    this.description,
    this.audioPath,
    this.imagePath,
  });

  factory StopI18n.fromJson(Map<String, dynamic> j) => StopI18n(
    stopId: j['stop_id'] as String,
    lang: j['lang'] as String,
    title: j['title'] as String? ?? '',
    description: j['description'] as String?,
    audioPath: j['audio_path'] as String?,
    imagePath: j['image_path'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'stop_id': stopId,
    'lang': lang,
    'title': title,
    'description': description,
    'audio_path': audioPath,
    'image_path': imagePath,
  };
}

class StopWithI18n {
  final Stop stop;
  final StopI18n? i18n;
  StopWithI18n({required this.stop, this.i18n});

  Map<String, dynamic> toJson() => {
    'stop': stop.toJson(),
    'i18n': i18n?.toJson(),
  };
  factory StopWithI18n.fromJson(Map<String, dynamic> j) => StopWithI18n(
    stop: Stop.fromJson(Map<String, dynamic>.from(j['stop'] as Map)),
    i18n: j['i18n'] == null
        ? null
        : StopI18n.fromJson(Map<String, dynamic>.from(j['i18n'] as Map)),
  );
}
