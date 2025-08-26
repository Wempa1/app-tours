import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// ===== Modelos ligeros (ajusta a tu fuente real/Supabase) ===================
class TourStop {
  final int order;
  final String title;
  final String? subtitle; // p.ej. "300 m · 4 min"
  final String? thumbUrl;
  const TourStop({
    required this.order,
    required this.title,
    this.subtitle,
    this.thumbUrl,
  });
}

class TourDetailModel {
  final String id;
  final String name;
  final String? logoUrl; // círculo superior (opcional)
  final String coverUrl;
  final int stopCount;
  final Duration duration;
  final double lengthKm;
  final List<TourStop> stops;
  final String description;

  const TourDetailModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.coverUrl,
    required this.stopCount,
    required this.duration,
    required this.lengthKm,
    required this.stops,
    required this.description,
  });
}

String _durationText(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h > 0 && m > 0) return '$h h $m min';
  if (h > 0) return '$h h';
  return '$m min';
}

/// ===== Pantalla =============================================================
class TourDetailScreen extends StatelessWidget {
  final TourDetailModel tour;
  const TourDetailScreen({super.key, required this.tour});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tour.name, overflow: TextOverflow.ellipsis),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Logo redondo (opcional) =====
                  if (tour.logoUrl != null && tour.logoUrl!.isNotEmpty) ...[
                    Center(
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.10),
                        backgroundImage:
                            CachedNetworkImageProvider(tour.logoUrl!),
                        child: const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ===== Nombre del tour =====
                  Text(
                    tour.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== Cover =====
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: tour.coverUrl,
                            fit: BoxFit.cover,
                            placeholder: (c, _) =>
                                Container(color: const Color(0xFFE2E8F0)),
                            errorWidget: (c, _, __) => Container(
                              color: const Color(0xFFE2E8F0),
                              child:
                                  const Icon(Icons.image_not_supported_outlined),
                            ),
                          ),
                          // Vignette sutil para legibilidad
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.center,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.35),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== Métricas: stops, duración, km =====
                  _StatsBar(
                    items: [
                      _StatItem(
                        icon: Icons.location_on_outlined,
                        label: 'Stops',
                        value: tour.stopCount.toString(),
                      ),
                      _StatItem(
                        icon: Icons.schedule_rounded,
                        label: 'Duration',
                        value: _durationText(tour.duration),
                      ),
                      _StatItem(
                        icon: Icons.route_rounded,
                        label: 'Length',
                        value: '${tour.lengthKm.toStringAsFixed(1)} km',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ===== Lista de paradas =====
                  _SectionCard(
                    title: 'Itinerary',
                    child: ListView.separated(
                      itemCount: tour.stops.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final s = tour.stops[i];
                        return _StopTile(stop: s);
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== Descripción =====
                  _SectionCard(
                    title: 'About this tour',
                    child: Text(
                      tour.description,
                      style:
                          theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
      // CTA inferior (opcional)
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {
              // NOTE: Navegar al mapa / guía paso a paso cuando exista la ruta
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Guide mode coming soon')),
              );
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start tour'),
          ),
        ),
      ),
    );
  }
}

/// ===== Widgets auxiliares ===================================================
class _StatsBar extends StatelessWidget {
  final List<_StatItem> items;
  const _StatsBar({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Construimos children manualmente para intercalar separadores sin romper Expanded
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      children.add(
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF0F172A)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF1F2937)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.value,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (i < items.length - 1) {
        children.add(const SizedBox(width: 10));
      }
    }

    return Row(children: children);
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  final TourStop stop;
  const _StopTile({required this.stop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '${stop.order}',
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      title: Text(
        stop.title,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: stop.subtitle != null ? Text(stop.subtitle!) : null,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        // NOTE: cuando exista StopDetailScreen, navega aquí
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stop ${stop.order}: coming soon')),
        );
      },
    );
  }
}

/// ===== Mock rápido para probar (elimina en prod) ============================
class DebugTourDetailPreview extends StatelessWidget {
  const DebugTourDetailPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final model = TourDetailModel(
      id: 'ile-cite',
      name: 'Île de la Cité – Paris Essential',
      logoUrl:
          'https://images.unsplash.com/photo-1520974735194-6c0aeb979c1d?w=256',
      coverUrl:
          'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=1600',
      stopCount: 9,
      duration: const Duration(hours: 2),
      lengthKm: 4.6,
      stops: const [
        TourStop(order: 1, title: 'Notre-Dame de Paris', subtitle: 'Start · 0 m'),
        TourStop(order: 2, title: 'Pont Neuf', subtitle: '450 m · 6 min'),
        TourStop(order: 3, title: 'Sainte-Chapelle', subtitle: '300 m · 4 min'),
        TourStop(order: 4, title: 'Conciergerie'),
        TourStop(order: 5, title: 'Bouquinistes of the Seine'),
        TourStop(order: 6, title: 'Place Dauphine'),
        TourStop(order: 7, title: 'Pont des Arts'),
        TourStop(order: 8, title: 'Quai de l’Horloge'),
        TourStop(order: 9, title: 'Finish – Île de la Cité'),
      ],
      description:
          'Explore the historic heart of Paris at your own pace. Includes audio guide, offline maps, and local tips for each stop.',
    );

    return TourDetailScreen(tour: model);
  }
}
