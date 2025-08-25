import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'widgets/av_tour_card.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _sb = Supabase.instance.client;
  final _heroCtrl = PageController(viewportFraction: 0.92);
  final _heroIndex = ValueNotifier(0);

  late Future<List<_TourVM>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load(); // <- devuelve Future<List<_TourVM>>
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _heroIndex.dispose();
    super.dispose();
  }

  Future<List<_TourVM>> _load() async {
    final rows = await _sb
        .from('tours_view_public')
        .select()
        .order('priority', ascending: true)
        .limit(12);

    final list = List<Map<String, dynamic>>.from(rows as List? ?? const []);
    return list
        .map((m) => _TourVM(
              id: (m['id'] ?? '') as String,
              title: (m['title'] ?? '') as String,
              cover: (m['cover_url'] ?? '') as String,
              stops: (m['stops_count'] as num?)?.toInt() ?? 0,
              durationMin: (m['duration_minutes'] as num?)?.toInt() ?? 0,
              lengthKm: (m['distance_km'] as num?)?.toDouble() ?? 0.0,
              rating: 4.8, // placeholder hasta tener reviews
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          automaticallyImplyLeading: false,
          toolbarHeight: 72,
          titleSpacing: 20,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary,
                child: const Icon(Icons.travel_explore, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome to Avanti',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: theme.colorScheme.primary)),
                    Text('Discover Paris at your pace',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search tours, neighborhoods, monuments…',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (q) {
                    // hook up later
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _chip(context, 'Popular', selected: true),
                      _chip(context, 'History'),
                      _chip(context, 'Art'),
                      _chip(context, 'Food'),
                      _chip(context, 'Romantic'),
                      _chip(context, 'Family'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),

        // HERO + indicador
        SliverToBoxAdapter(
          child: FutureBuilder<List<_TourVM>>(
            future: _future,
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

              final heroCount = tours.length.clamp(0, 5);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(
                      height: 210,
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
                    Row(
                      children: [
                        Text('All tours',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        TextButton(
                          onPressed: () => context.go('/catalog'),
                          child: const Text('See more'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // GRID
        FutureBuilder<List<_TourVM>>(
          future: _future,
          builder: (context, snap) {
            final tours = snap.data ?? <_TourVM>[];
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= tours.length) return const SizedBox.shrink();
                    final t = tours[index];
                    return AvTourCard(
                      title: t.title,
                      subtitle: t.subtitle,
                      imageUrl: t.cover,
                      rating: t.rating,
                      onTap: () => context.push('/tour/${t.id}'),
                    );
                  },
                  childCount: tours.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, String label, {bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {},
      ),
    );
  }

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.90),
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
    );
  }
}
