import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _sb = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await _sb
        .from('tours_view_public')
        .select()
        .order('title', ascending: true);
    // 'rows' ya es List<dynamic>; lo normalizamos de forma segura:
    return List<Map<String, dynamic>>.from(rows as List? ?? const []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catalog')),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final items = List<Map<String, dynamic>>.from(
            (snap.data as List?) ?? const [],
          );

          if (items.isEmpty) {
            return const Center(child: Text('No tours yet.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .78),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final m = items[i];
              final duration = (m['duration_minutes'] as num?)?.toInt() ?? 0;
              return _TourCard(
                title: (m['title'] ?? '') as String,
                city: (m['city'] ?? '') as String,
                duration: duration,
                cover: (m['cover_url'] ?? '') as String,
                onTap: () => context.push('/tour/${m['id']}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  final String title;
  final String city;
  final int duration;
  final String cover;
  final VoidCallback onTap;
  const _TourCard({required this.title, required this.city, required this.duration, required this.cover, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 16/10,
                child: cover.isNotEmpty
                  ? CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover, errorWidget: (_, __, ___) => _fallback(), placeholder: (_, __) => _loader())
                  : _fallback(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10,8,10,8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(city, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16),
                        const SizedBox(width: 4),
                        Text('$duration min', style: const TextStyle(fontSize: 12)),
                        const Spacer(),
                      ],
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

  Widget _fallback() => const ColoredBox(color: Color(0xFFEFEFEF), child: Center(child: Icon(Icons.image, size: 34)));
  Widget _loader() => const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)));
}
