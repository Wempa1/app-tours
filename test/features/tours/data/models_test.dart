import 'package:avanti/features/tours/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Tour toJson/fromJson', () {
    final t = Tour(
      id: '1',
      slug: 'test-slug',
      title: 'Title',
      city: 'City',
      coverUrl: 'http://x',
      durationMinutes: 90,
      distanceKm: 3.4,
      published: true,
    );
    final j = t.toJson();
    final back = Tour.fromJson(j);
    expect(back.id, t.id);
    expect(back.slug, t.slug);
    expect(back.title, t.title);
    expect(back.city, t.city);
    expect(back.coverUrl, t.coverUrl);
    expect(back.durationMinutes, t.durationMinutes);
    expect(back.distanceKm, t.distanceKm);
    expect(back.published, t.published);
  });

  test('StopWithI18n toJson/fromJson', () {
    final s = Stop(id: 's1', tourId: 't1', orderIndex: 1, lat: 1.0, lon: 2.0);
    final i = StopI18n(
      stopId: 's1',
      lang: 'es',
      title: 'Hola',
      description: 'Desc',
      audioPath: 'a.mp3',
      imagePath: 'i.jpg',
    );
    final wrap = StopWithI18n(stop: s, i18n: i);
    final j = wrap.toJson();
    final back = StopWithI18n.fromJson(j);
    expect(back.stop.id, s.id);
    expect(back.i18n?.lang, i.lang);
    expect(back.i18n?.title, i.title);
  });
}
