import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:avanti/core/logging/app_logger.dart';
import 'package:avanti/core/ui/app_snack.dart';
import 'package:avanti/di/providers.dart';
import 'package:avanti/features/tours/data/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class TourDetailScreen extends ConsumerStatefulWidget {
  final String tourId;
  const TourDetailScreen({super.key, required this.tourId});

  @override
  ConsumerState<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends ConsumerState<TourDetailScreen>
    with WidgetsBindingObserver {
  late final AudioPlayer _player;

  bool _loadingAudio = false;
  String? _currentStopId;

  String? _loadedAudioPath;
  String? _loadedSignedUrl;

  Duration _savedPosition = Duration.zero;

  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _becomingNoisySub;

  late Future<List<StopWithI18n>> _stopsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player = AudioPlayer();

    _configureAudioSession();

    final lang = ref.read(currentLangProvider);
    _stopsFuture = ref
        .read(stopsWithI18nProvider((tourId: widget.tourId, lang: lang)).future);
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    _becomingNoisySub = session.becomingNoisyEventStream.listen((_) async {
      AppLogger.i('Audio becoming noisy → pause');
      await _safePause();
    });
    _interruptionSub = session.interruptionEventStream.listen((event) async {
      if (event.begin) {
        await _safePause();
      }
    });
  }

  @override
  void dispose() {
    _interruptionSub?.cancel();
    _becomingNoisySub?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    _player.dispose();
    super.dispose();
  }

  Future<void> _safePause() async {
    try {
      _savedPosition = _player.position;
      await _player.pause();
      setState(() {});
    } catch (e, st) {
      AppLogger.w('Pause failed', e, st);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_player.playing) {
        AppLogger.i('Lifecycle: $state → pause player');
        _safePause();
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _playStop(StopWithI18n s) async {
    final audioPath = s.i18n?.audioPath;

    if (audioPath == null || audioPath.isEmpty) {
      AppSnack.showInfo('Esta parada aún no tiene audio.');
      return;
    }

    setState(() {
      _loadingAudio = true;
      _currentStopId = s.stop.id;
    });

    try {
      late final String signedUrl;

      if (_loadedAudioPath == audioPath && _loadedSignedUrl != null) {
        signedUrl = _loadedSignedUrl!;
      } else {
        final sUrl = await ref.read(signedAudioUrlProvider(audioPath).future);
        if (sUrl == null || sUrl.isEmpty) {
          throw Exception('No se pudo firmar la URL del audio.');
        }
        signedUrl = sUrl;
        _loadedAudioPath = audioPath;
        _loadedSignedUrl = signedUrl;
      }

      await _player.setUrl(signedUrl);

      if (_savedPosition > Duration.zero) {
        await _player.seek(_savedPosition);
        _savedPosition = Duration.zero;
      }

      await _player.play();
      setState(() {}); // refresca icono play/pause
    } catch (e, st) {
      AppLogger.e('Audio error', e, st);
      AppSnack.showError('No pudimos reproducir el audio. Intenta de nuevo.');
    } finally {
      if (mounted) {
        setState(() => _loadingAudio = false);
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_player.playing) {
      await _safePause();
    } else {
      try {
        await _player.play();
        setState(() {});
      } catch (e, st) {
        AppLogger.e('toggle play error', e, st);
        AppSnack.showError('No pudimos continuar la reproducción.');
      }
    }
  }

  Future<void> _markProgress({
    required List<StopWithI18n> stops,
    required StopWithI18n current,
  }) async {
    final repo = ref.read(progressRepoProvider);
    final idx = stops.indexWhere((e) => e.stop.id == current.stop.id);
    final completed = (idx >= 0) ? idx + 1 : 1;

    try {
      await repo.setProgress(
        tourId: widget.tourId,
        lastStopId: current.stop.id,
        completedStops: completed,
      );

      if (completed >= stops.length && stops.isNotEmpty) {
        await repo.recordCompletion(tourId: widget.tourId);
        AppSnack.showInfo('¡Tour completado!');
      } else {
        AppSnack.showInfo('Progreso guardado: $completed/${stops.length}');
      }
    } catch (e, st) {
      AppLogger.e('progress error', e, st);
      AppSnack.showError('No pudimos guardar tu progreso.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour'),
        actions: [
          IconButton(
            tooltip: _player.playing ? 'Pausar' : 'Reproducir',
            icon: Icon(
              _player.playing
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
            ),
            onPressed: (_loadedSignedUrl == null) ? null : _togglePlayPause,
          ),
        ],
      ),
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
                          if (_loadingAudio && isCurrent)
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            IconButton(
                              tooltip: isCurrent && _player.playing
                                  ? 'Pausar'
                                  : 'Reproducir',
                              icon: Icon(
                                isCurrent && _player.playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
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
                              AppSnack.showInfo(
                                'Direcciones aún no implementadas.',
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
