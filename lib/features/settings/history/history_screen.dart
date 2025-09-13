import 'package:avanti/di/providers.dart';
import 'package:avanti/features/history/data/history_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(tourHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Tours')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: 'No pudimos cargar tu historial.',
          onRetry: () => ref.refresh(tourHistoryProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _HistoryTile(entry: items[i]),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final TourHistoryEntry entry;
  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final tour = entry.tour;
    final cover = tour?.coverUrl;
    final subtitle = _buildSubtitle(entry);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: cover == null || cover.isEmpty
              ? Container(
                  color: Colors.black12,
                  child: const Icon(Icons.image_not_supported),
                )
              : Image.network(
                  cover,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.black12, child: const Icon(Icons.broken_image)),
                ),
        ),
      ),
      title: Text(
        tour?.title.isNotEmpty == true ? tour!.title : 'Tour ${entry.tourId}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Si quieres navegar al detalle del tour:
        // context.push('/tour/${entry.tourId}');
      },
    );
  }

  String _buildSubtitle(TourHistoryEntry e) {
    final d = e.completedAt;
    final formatted =
        '${_two(d.day)}/${_two(d.month)}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';
    final dur = e.durationMinutes;
    if (dur == null) return 'Completado: $formatted';
    return 'Completado: $formatted · $dur min';
  }

  String _two(int n) => n < 10 ? '0$n' : '$n';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 48, color: Colors.black45),
            const SizedBox(height: 12),
            Text(
              'Aún no tienes tours completados',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Cuando completes tus tours, aparecerán aquí.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
