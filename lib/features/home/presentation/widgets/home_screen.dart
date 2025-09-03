import 'package:avanti/core/logging/app_logger.dart';
import 'package:avanti/core/services/location_service.dart';
import 'package:avanti/core/ui/app_snack.dart';
import 'package:avanti/core/widgets/error_retry.dart';
import 'package:avanti/di/providers.dart';
import 'package:avanti/features/tours/data/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _heroCtrl = PageController(viewportFraction: 0.92);
  final _heroIndex = ValueNotifier(0);

  late Future<List<Tour>> _toursFuture;
  late Future<_StatsVM> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    _toursFuture = _loadToursNearbyOrDefault();
    _statsFuture = ref.read(userStatsProvider.future).then((s) => _StatsVM(
          completedTours: s.completedTours,
          rewardStars0to9: s.rewardStars0to9,
          walkedKm: s.walkedKm,
        ));
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _heroIndex.dispose();
    super.dispose();
  }

  Future<List<Tour>> _loadToursNearbyOrDefault() async {
    final repo = ref.read(tourRepoProvider);
    try {
      final loc = ref.read(locationServiceProvider);
      final pos = await loc.currentPositionOrNull();
      if (pos != null) {
        final nearby =
            await repo.toursNearby(lat: pos.latitude, lon: pos.longitude, limit: 12);
        if (nearby.isNotEmpty) {
          AppLogger.i('Nearby tours: ${nearby.length}');
          return nearby;
        }
      }
    } catch (e, st) {
      AppLogger.w('Nearby tours failed, fallback to catalog', e, st);
      AppSnack.showInfo('Usando recomendados por defecto.');
    }
    final cat = await repo.listCatalog(limit: 12);
    AppLogger.i('Catalog (fallback): ${cat.length}');
    return cat;
  }

  Future<void> _onRefresh() async {
    setState(_loadAll);
    await Future.wait([
      _toursFuture.catchError((_) => <Tour>[]),
      _statsFuture.catchError((_) => _StatsVM.zero()),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          primary: true,
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              automaticallyImplyLeading: false, // <- nombre correcto
              toolbarHeight: 64,
              titleSpacing: 20,
              title: Text(
                'Recommended',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            // HERO
            SliverToBoxAdapter(
              child: FutureBuilder<List<Tour>>(
                future: _toursFuture,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    AppLogger.e('Home tours error', snap.error);
                    return ErrorRetry(
                      message: 'No pudimos cargar tours.',
                      onRetry: () => setState(() {
                        _toursFuture = _loadToursNearbyOrDefault();
                      }),
                    );
                  }
                  final tours = snap.data ?? <Tour>[];
                  if (tours.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _emptyHero(context),
                    );
                  }

                  final w = MediaQuery.of(context).size.width;
                  final h = (w * 0.58).clamp(220.0, 360.0).toDouble();
                  final heroCount = tours.length.clamp(0, 5);

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
                          builder: (_, i, __) => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(heroCount, (idx) {
                              final active = idx == i;
                              return Container(
                                width: active ? 10 : 8,
                                height: active ? 10 : 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: active
                                      ? theme.colorScheme.primary
                                      : theme.disabledColor.withOpacity(0.4),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 22),
                      ],
                    ),
                  );
                },
              ),
            ),

            // STATS
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'My Stats',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
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
                          AppLogger.e('Stats error', snap.error);
                          return ErrorRetry(
                            message: 'No pudimos cargar tus estadísticas.',
                            onRetry: () => setState(_loadAll),
                          );
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
      ),
    );
  }

  Widget _emptyHero(BuildContext context) => Container(
        height: 220,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: const Center(child: Text('No tours yet')),
      );

  Widget _heroCard(BuildContext context, Tour t) {
    final theme = Theme.of(context);
    final rating = 4.8; // placeholder
    final subtitle =
        '${t.durationMinutes ?? 0} min · ${(t.distanceKm ?? 0).toStringAsFixed(1)} km';

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/tour/${t.id}'),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  t.coverUrl ?? '',
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
                        Colors.black.withOpacity(0.65),
                        Colors.black.withOpacity(0.10),
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
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.90),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
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
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.90),
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

class _StatsVM {
  final int completedTours;
  final int rewardStars0to9; // 0..9
  final double walkedKm;
  const _StatsVM({
    required this.completedTours,
    required this.rewardStars0to9,
    required this.walkedKm,
  });
  factory _StatsVM.zero() =>
      const _StatsVM(completedTours: 0, rewardStars0to9: 0, walkedKm: 0.0);
}

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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
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
    );
  }
}

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
              color: filled ? Colors.amber : Colors.grey.withOpacity(0.5),
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
