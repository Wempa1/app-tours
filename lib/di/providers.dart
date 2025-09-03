// Repos y providers compartidos para la UI (Riverpod)

import 'package:avanti/features/tours/data/caching_tour_repo.dart';
import 'package:avanti/features/tours/data/models.dart';
import 'package:avanti/features/tours/data/progress_repo.dart';
import 'package:avanti/features/tours/data/tour_repo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------- Repos (BE detrás de interfaces) ----------------

final tourRepoProvider = Provider<TourRepo>(
  (ref) => CachingTourRepo(remote: SupabaseTourRepo()),
);

final progressRepoProvider = Provider<ProgressRepo>(
  (ref) => SupabaseProgressRepo(),
);

// ---------------- Catálogo ----------------

final catalogProvider = FutureProvider.autoDispose<List<Tour>>((ref) async {
  final repo = ref.watch(tourRepoProvider);
  return repo.listCatalog();
});

// ---------------- Idioma actual (placeholder) ----------------
// Si quieres hacerlo dinámico luego, cambia a StateProvider<String>.
final currentLangProvider = Provider<String>((_) => 'es');

// ---------------- Paradas con i18n ----------------

typedef StopsI18nArgs = ({String tourId, String lang});

final stopsWithI18nProvider =
    FutureProvider.autoDispose.family<List<StopWithI18n>, StopsI18nArgs>(
  (ref, args) {
    final repo = ref.watch(tourRepoProvider);
    return repo.listStopsWithI18n(tourId: args.tourId, lang: args.lang);
  },
);

// ---------------- URL firmada de audio ----------------
// Acepta String? para no hacer fetch si el path viene vacío/nulo.
final signedAudioUrlProvider =
    FutureProvider.autoDispose.family<String?, String?>((ref, audioPath) async {
  if (audioPath == null || audioPath.isEmpty) return null;
  final repo = ref.watch(tourRepoProvider);
  return repo.signedAudioUrl(audioPath);
});

// ---------------- User Stats (view user_stats_v) ----------------
// Nota: Esto toca Supabase directamente.
// Para separación estricta FE/BE, podemos crear un UserStatsRepo.

typedef UserStats = ({
  int completedTours,
  int rewardStars0to9,
  double walkedKm,
});

final userStatsProvider = FutureProvider.autoDispose<UserStats>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) {
    return (completedTours: 0, rewardStars0to9: 0, walkedKm: 0.0);
    // Usuario no autenticado -> stats en cero
  }

  try {
    final row = await client
        .from('user_stats_v')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) {
      return (completedTours: 0, rewardStars0to9: 0, walkedKm: 0.0);
    }

    return (
      completedTours: (row['completed_tours'] as num?)?.toInt() ?? 0,
      rewardStars0to9: (row['reward_stars'] as num?)?.toInt() ?? 0,
      walkedKm: (row['walked_km'] as num?)?.toDouble() ?? 0.0,
    );
  } catch (_) {
    // Fallback seguro para no romper UI
    return (completedTours: 0, rewardStars0to9: 0, walkedKm: 0.0);
  }
});
// === Auth providers (frontera FE/BE) =========================


/// Email del usuario autenticado (o null)
final currentUserEmailProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.email;
});

/// Acción de sign out expuesta como función
final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await Supabase.instance.client.auth.signOut();
  };
});
