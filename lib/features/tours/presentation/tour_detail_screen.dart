import 'package:avanti/features/tours/data/models.dart';
import 'package:avanti/features/tours/data/progress_repo.dart';
import 'package:avanti/features/tours/data/tour_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

// Providers sencillos (puedes moverlos a un archivo común si prefieres)
final tourRepoProvider = Provider<TourRepo>((_) => SupabaseTourRepo());
final progressRepoProvider = Provider<ProgressRepo>(
  (_) => SupabaseProgressRepo(),
);

// Idioma activo (simple). Más adelante lo conectamos a settings del usuario.
final currentLangProvider = Provider<String>((_) => 'es');

class TourDetailScreen extends ConsumerStatefulWidget {
  final String tourId;
  const TourDetailScreen({super.key, required this.tourId});

  @override
  ConsumerState<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends ConsumerState<TourDetailScreen> {
  late final AudioPlayer _player;
  bool _loadingAudio = false;
  String? _currentStopId;

  late Future<List<StopWithI18n>> _stopsFuture;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    final lang = ref.read(currentLangProvider);
    _stopsFuture = ref
        .read(tourRepoProvider)
        .listStopsWithI18n(tourId: widget.tourId, lang: lang);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playStop(StopWithI18n s) async {
    final repo = ref.read(tourRepoProvider);
    final audioPath = s.i18n?.audioPath;
    if (audioPath == null || audioPath.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta parada aún no tiene audio.')),
        );
      }
      return;
    }
    setState(() {
      _loadingAudio = true;
      _currentStopId = s.stop.id;
    });
    try {
      final signed = await repo.signedAudioUrl(audioPath);
      if (signed == null || signed.isEmpty) {
        throw Exception('No se pudo firmar la URL del audio.');
      }
      await _player.setUrl(signed);
      await _player.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Audio error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loadingAudio = false);
      }
    }
  }

  Future<void> _markProgress({
    required List<StopWithI18n> stops,
    required StopWithI18n current,
  }) async {
    final repo = ref.read(progressRepoProvider);
    // El índice de la parada (1-based para completed_stops)
    final idx = stops.indexWhere((e) => e.stop.id == current.stop.id);
    final completed = (idx >= 0) ? idx + 1 : 1;

    try {
      await repo.setProgress(
        tourId: widget.tourId,
        lastStopId: current.stop.id,
        completedStops: completed,
      );

      // Si completó todas las paradas, registra la finalización del tour
      if (completed >= stops.length && stops.isNotEmpty) {
        await repo.recordCompletion(tourId: widget.tourId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('¡Tour completado!')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Progreso guardado: $completed/${stops.length}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de progreso: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tour')),
      body: FutureBuilder<List<StopWithI18n>>(
        future: _stopsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final stops = snap.data ?? const <StopWithI18n>[];
          if (stops.isEmpty) {
            return const Center(child: Text('Este tour no tiene paradas.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: stops.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final s = stops[i];
              final title = s.i18n?.title ?? 'Stop ${s.stop.orderIndex}';
              final desc = s.i18n?.description ?? '';
              final isCurrent = _currentStopId == s.stop.id;

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s.stop.orderIndex.toString(),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _loadingAudio && isCurrent
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  tooltip: 'Reproducir',
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  onPressed: () => _playStop(s),
                                ),
                        ],
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          desc,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Marcar como completada'),
                            onPressed: () =>
                                _markProgress(stops: stops, current: s),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            icon: const Icon(Icons.directions_walk),
                            label: const Text('Cómo llegar'),
                            onPressed: () {
                              // Aquí luego abriremos navegación hacia la siguiente parada
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Direcciones aún no implementadas.',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
