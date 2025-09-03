// lib/features/tours/data/models.dart

/// Modelo de Tour (capa de dominio/datos)
class Tour {
  final String id;
  final String slug;
  final String title;
  final String? city;
  final String? coverUrl;
  final int? durationMinutes;
  final double? distanceKm;
  final bool? published;

  const Tour({
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
        id: (j['id'])?.toString() ?? '',
        slug: (j['slug'])?.toString() ?? '',
        title: (j['title'])?.toString() ?? '',
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

  Tour copyWith({
    String? id,
    String? slug,
    String? title,
    String? city,
    String? coverUrl,
    int? durationMinutes,
    double? distanceKm,
    bool? published,
  }) {
    return Tour(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      city: city ?? this.city,
      coverUrl: coverUrl ?? this.coverUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      published: published ?? this.published,
    );
  }

  @override
  String toString() => 'Tour(id: $id, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tour &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          slug == other.slug &&
          title == other.title &&
          city == other.city &&
          coverUrl == other.coverUrl &&
          durationMinutes == other.durationMinutes &&
          distanceKm == other.distanceKm &&
          published == other.published;

  @override
  int get hashCode =>
      id.hashCode ^
      slug.hashCode ^
      title.hashCode ^
      city.hashCode ^
      (coverUrl?.hashCode ?? 0) ^
      (durationMinutes?.hashCode ?? 0) ^
      (distanceKm?.hashCode ?? 0) ^
      (published?.hashCode ?? 0);
}

/// Parada del tour
class Stop {
  final String id;
  final String tourId;
  /// Orden 1-based (DB lo garantiza con CHECK > 0)
  final int orderIndex;
  final double? lat;
  final double? lon;

  const Stop({
    required this.id,
    required this.tourId,
    required this.orderIndex,
    this.lat,
    this.lon,
  });

  factory Stop.fromJson(Map<String, dynamic> j) => Stop(
        id: (j['id'])?.toString() ?? '',
        tourId: (j['tour_id'])?.toString() ?? '',
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

  Stop copyWith({
    String? id,
    String? tourId,
    int? orderIndex,
    double? lat,
    double? lon,
  }) {
    return Stop(
      id: id ?? this.id,
      tourId: tourId ?? this.tourId,
      orderIndex: orderIndex ?? this.orderIndex,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }

  @override
  String toString() => 'Stop(id: $id, orderIndex: $orderIndex)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stop &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tourId == other.tourId &&
          orderIndex == other.orderIndex &&
          lat == other.lat &&
          lon == other.lon;

  @override
  int get hashCode =>
      id.hashCode ^
      tourId.hashCode ^
      orderIndex.hashCode ^
      (lat?.hashCode ?? 0) ^
      (lon?.hashCode ?? 0);
}

/// i18n de la parada
class StopI18n {
  final String stopId;
  final String lang;
  final String title;
  final String? description;
  final String? audioPath;
  final String? imagePath;

  const StopI18n({
    required this.stopId,
    required this.lang,
    required this.title,
    this.description,
    this.audioPath,
    this.imagePath,
  });

  factory StopI18n.fromJson(Map<String, dynamic> j) => StopI18n(
        stopId: (j['stop_id'])?.toString() ?? '',
        lang: (j['lang'])?.toString() ?? '',
        title: (j['title'])?.toString() ?? '',
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

  StopI18n copyWith({
    String? stopId,
    String? lang,
    String? title,
    String? description,
    String? audioPath,
    String? imagePath,
  }) {
    return StopI18n(
      stopId: stopId ?? this.stopId,
      lang: lang ?? this.lang,
      title: title ?? this.title,
      description: description ?? this.description,
      audioPath: audioPath ?? this.audioPath,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  String toString() => 'StopI18n(stopId: $stopId, lang: $lang)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StopI18n &&
          runtimeType == other.runtimeType &&
          stopId == other.stopId &&
          lang == other.lang &&
          title == other.title &&
          description == other.description &&
          audioPath == other.audioPath &&
          imagePath == other.imagePath;

  @override
  int get hashCode =>
      stopId.hashCode ^
      lang.hashCode ^
      title.hashCode ^
      (description?.hashCode ?? 0) ^
      (audioPath?.hashCode ?? 0) ^
      (imagePath?.hashCode ?? 0);
}

/// Wrapper: parada + su i18n (si existe)
class StopWithI18n {
  final Stop stop;
  final StopI18n? i18n;

  const StopWithI18n({required this.stop, this.i18n});

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

  StopWithI18n copyWith({Stop? stop, StopI18n? i18n}) =>
      StopWithI18n(stop: stop ?? this.stop, i18n: i18n ?? this.i18n);

  @override
  String toString() => 'StopWithI18n(stop: $stop, i18n: $i18n)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StopWithI18n &&
          runtimeType == other.runtimeType &&
          stop == other.stop &&
          i18n == other.i18n;

  @override
  int get hashCode => stop.hashCode ^ (i18n?.hashCode ?? 0);
}
