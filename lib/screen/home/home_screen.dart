// lib/screen/home/home_screen.dart
// lib/screen/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/location_service.dart';
import '../../services/location_service.dart';

/// --------- ViewModels ---------
class _TourVM {
  final String id, title, cover;
  final int stops, durationMin;
  final double lengthKm, rating;
  _TourVM({
    required this.id,
    required this.title,
    required this.cover,
    required this.stops,
    required this.durationMin,
    required this.lengthKm,
    required this.rating,
  });
  String get subtitle => '$durationMin min · $stops stops';
}

class _StatsVM {
  final int completedTours;
  final int rewardStars0to9; // 0..9 (el 10º es gratis)
  final double walkedKm;
  const _StatsVM({
    required this.completedTours,
    required this.rewardStars0to9,
    required this.walkedKm,
  });
  factory _StatsVM.zero() =>
      const _StatsVM(completedTours: 0, rewardStars0to9: 0, walkedKm: 0.0);
}

/// --------- Screen ---------
class HomeScreen extends ConsumerConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _sb = Supabase.instance.client;
  final _heroCtrl = PageController(viewportFraction: 0.92);
  final _heroIndex = ValueNotifier(0);

  late Future<List<_TourVM>> _toursFuture;
  late Future<_StatsVM> _statsFuture;

  @override
  void initState() {
    super.initState();
    _toursFuture = _loadToursNearbyOrDefault();
    _statsFuture = _loadStats();
    _toursFuture = _loadToursNearbyOrDefault();
    _statsFuture = _loadStats();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _heroIndex.dispose();
    super.dispose();
  }

  // ---- Tours cercanos (RPC) con fallback a vista pública ----
  Future<List<_TourVM>> _loadToursNearbyOrDefault() async {
  // 1) Intentar ubicación del usuario
  final loc = ref.read(locationServiceProvider);
  final pos = await loc.currentPositionOrNull();

  // 2) Si hay ubicación → usar función tours_nearby(p_lat, p_lon, p_limit)
  if (pos != null) {
    final rows = await _sb.rpc('tours_nearby', params: {
      'p_lat': pos.latitude,
      'p_lon': pos.longitude,
      'p_limit': 12,
    });

    final list = List<Map<String, dynamic>>.from(rows as List? ?? const []);
    if (list.isNotEmpty) {
      return list.map((m) => _TourVM(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        cover: (m['cover_url'] ?? '').toString(),
        stops: (m['stops_count'] as num?)?.toInt() ?? 0,
        durationMin: (m['duration_minutes'] as num?)?.toInt() ?? 0,
        lengthKm: (m['distance_km'] as num?)?.toDouble()
                  ?? (m['distance_km'] as int?)?.toDouble() ?? 0.0,
        rating: 4.8, // placeholder
      )).toList();
    }
  }

  // 3) Fallback → vista pública (ordenar por un campo que exista)
  final rows = await _sb
      .from('tours_view_public')
      .select()
      .order('title', ascending: true)   // <- antes era 'priority'
      .limit(12);
  // ---- Tours cercanos (RPC) con fallback a vista pública ----
  Future<List<_TourVM>> _loadToursNearbyOrDefault() async {
  // 1) Intentar ubicación del usuario
  final loc = ref.read(locationServiceProvider);
  final pos = await loc.currentPositionOrNull();

  // 2) Si hay ubicación → usar función tours_nearby(p_lat, p_lon, p_limit)
  if (pos != null) {
    final rows = await _sb.rpc('tours_nearby', params: {
      'p_lat': pos.latitude,
      'p_lon': pos.longitude,
      'p_limit': 12,
    });

    final list = List<Map<String, dynamic>>.from(rows as List? ?? const []);
    if (list.isNotEmpty) {
      return list.map((m) => _TourVM(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        cover: (m['cover_url'] ?? '').toString(),
        stops: (m['stops_count'] as num?)?.toInt() ?? 0,
        durationMin: (m['duration_minutes'] as num?)?.toInt() ?? 0,
        lengthKm: (m['distance_km'] as num?)?.toDouble()
                  ?? (m['distance_km'] as int?)?.toDouble() ?? 0.0,
        rating: 4.8, // placeholder
      )).toList();
    }
  }

  // 3) Fallback → vista pública (ordenar por un campo que exista)
  final rows = await _sb
      .from('tours_view_public')
      .select()
      .order('title', ascending: true)   // <- antes era 'priority'
      .limit(12);

  final list = List<Map<String, dynamic>>.from(rows as List? ?? const []);
  return list.map((m) => _TourVM(
    id: (m['id'] ?? '').toString(),
    title: (m['title'] ?? '').toString(),
    cover: (m['cover_url'] ?? '').toString(),
    stops: (m['stops_count'] as num?)?.toInt() ?? 0,
    durationMin: (m['duration_minutes'] as num?)?.toInt() ?? 0,
    lengthKm: (m['distance_km'] as num?)?.toDouble() ?? 0.0,
    rating: 4.8,
  )).toList();
}
  final list = List<Map<String, dynamic>>.from(rows as List? ?? const []);
  return list.map((m) => _TourVM(
    id: (m['id'] ?? '').toString(),
    title: (m['title'] ?? '').toString(),
    cover: (m['cover_url'] ?? '').toString(),
    stops: (m['stops_count'] as num?)?.toInt() ?? 0,
    durationMin: (m['duration_minutes'] as num?)?.toInt() ?? 0,
    lengthKm: (m['distance_km'] as num?)?.toDouble() ?? 0.0,
    rating: 4.8,
  )).toList();
}

  // ---- Stats desde la vista user_stats_v ----
  // ---- Stats desde la vista user_stats_v ----
  Future<_StatsVM> _loadStats() async {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) return _StatsVM.zero();

    try {
      final row = await _sb
          .from('user_stats_v')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
          .maybeSingle();

      if (row == null) return _StatsVM.zero();

      return _StatsVM(
        completedTours: (row['completed_tours'] as num?)?.toInt() ?? 0,
        rewardStars0to9: (row['reward_stars'] as num?)?.toInt() ?? 0,
        walkedKm: (row['walked_km'] as num?)?.toDouble() ?? 0.0,
      );
    } on PostgrestException catch (e) {
      debugPrint('⚠️ user_stats_v query failed: ${e.message}');
      return _StatsVM.zero();
    } catch (e) {
      debugPrint('⚠️ unexpected stats error: $e');
      return _StatsVM.zero();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            floating: true,
            snap: true,
            automaticallyImplyLeading: false,
            pinned: false,
            pinned: false,
            toolbarHeight: 64,
            titleSpacing: 20,
            title: Text(
              'Recommended',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),

          // HERO: recomendado
          SliverToBoxAdapter(
            child: FutureBuilder<List<_TourVM>>(
              future: _toursFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Error: ${snap.error}'),
                  );
                }
                final tours = snap.data ?? <_TourVM>[];
                if (tours.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _emptyHero(context),
                  );
                }

                // Altura responsiva del slideshow
                final w = MediaQuery.of(context).size.width;
                final h = (w * 0.58).clamp(220.0, 360.0).toDouble();

                final int heroCount = tours.length.clamp(0, 5);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      SizedBox(
                        height: h,
                        child: PageView.builder(
                          controller: _heroCtrl,
                          itemCount: heroCount,
                          onPageChanged: (i) => _heroIndex.value = i,
                          itemBuilder: (_, i) => _heroCard(context, tours[i]),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ValueListenableBuilder<int>(
                        valueListenable: _heroIndex,
                        builder: (_, i, __) => SmoothPageIndicator(
                          controller: _heroCtrl,
                          count: heroCount,
                          effect: ExpandingDotsEffect(
                            dotHeight: 6,
                            dotWidth: 6,
                            spacing: 6,
                            activeDotColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
                  ),
                );
              },
            ),
          ),

          // MY STATS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'My Stats',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<_StatsVM>(
                    future: _statsFuture,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const SizedBox(
                          height: 160,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snap.hasError) {
                        return Text('Error loading stats: ${snap.error}');
                      }
                      final s = snap.data ?? _StatsVM.zero();
                      return _StatsGrid(stats: s);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- helpers visuales ----------
  Widget _emptyHero(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: const Center(child: Text('No tours yet')),
    );
  }

  Widget _heroCard(BuildContext context, _TourVM t) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        type: MaterialType.transparency, // asegura Material ancestro para InkWell
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            // GoRouter: detalle por id (ya tienes la ruta /tour/:id)
            // GoRouter: detalle por id (ya tienes la ruta /tour/:id)
            context.push('/tour/${t.id}');
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  t.cover,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFFE2E8F0)),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.65),
                        Colors.black.withValues(alpha: 0.10),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              
                              .withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              t.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.90),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// --------- Widgets de Stats ----------
class _StatsGrid extends StatelessWidget {
  final _StatsVM stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      children: [
        _StatCard(
          title: 'Completed Tours',
          child: _BigValue('${stats.completedTours}'),
        ),
        _StatCard(
          title: 'Avanti Rewards',
          child: _StarsGrid(count: stats.rewardStars0to9),
        ),
        _StatCard(
          title: 'Walked Distance',
          child: _BigValue('${stats.walkedKm.toStringAsFixed(1)} km'),
        ),
        const _StatCard(title: 'Coming Soon', child: _BigValue('—')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _StatCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style:
               
                theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Expanded(child: Center(child: child)),
        ],
      ),
    );
  }
}

class _BigValue extends StatelessWidget {
  final String value;
  const _BigValue(this.value);

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: TextAlign.center,
      style: Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(fontWeight: FontWeight.w800),
      style: Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

// 5 estrellas arriba + 4 abajo, centradas
class _StarsGrid extends StatelessWidget {
  final int count; // 0..9
  const _StarsGrid({required this.count});

  @override
  Widget build(BuildContext context) {
    const int topTotal = 5;
    const int bottomTotal = 4;
    final int active = count.clamp(0, topTotal + bottomTotal);
    final int activeTop = active.clamp(0, topTotal);
    final int activeBottom = (active - topTotal).clamp(0, bottomTotal);

    Widget buildRow(int total, int active) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final filled = i < active;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 22,
              color: filled ? Colors.amber : Colors.grey.withValues(alpha: 0.5),
            ),
          );
        }),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildRow(topTotal, activeTop),
        const SizedBox(height: 6),
        buildRow(bottomTotal, activeBottom),
      ],
    );
  }
}
