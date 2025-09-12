// lib/di/providers.dart
// Repos y providers compartidos para la UI (Riverpod)

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Auth (repos separados FE/BE)
import 'package:avanti/features/auth/data/auth_repo.dart';

// Tours (repos y modelos)
import 'package:avanti/features/tours/data/caching_tour_repo.dart';
import 'package:avanti/features/tours/data/models.dart';
import 'package:avanti/features/tours/data/progress_repo.dart';
import 'package:avanti/features/tours/data/tour_repo.dart';

// Historial
import 'package:avanti/features/history/data/history_models.dart';
import 'package:avanti/features/history/data/history_repo.dart';

//Pagos
import 'package:avanti/features/payments/data/payment_models.dart';
import 'package:avanti/features/payments/data/payment_repo.dart';

// OJO: mantenemos Supabase aquí SOLO para userStatsProvider.
// Si luego quieres separación 100% FE/BE, movemos esto a un UserStatsRepo en features/user/data/.
import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------- Repos (BE detrás de interfaces) ----------------

final tourRepoProvider = Provider<TourRepo>(
  (ref) => CachingTourRepo(remote: SupabaseTourRepo()),
);

final progressRepoProvider = Provider<ProgressRepo>(
  (ref) => SupabaseProgressRepo(),
);

// Auth repo (frontera FE/BE)
final authRepoProvider = Provider<AuthRepo>(
  (ref) => SupabaseAuthRepo(),
);

// Historial repo
final historyRepoProvider = Provider<HistoryRepo>(
  (ref) => SupabaseHistoryRepo(),
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
// Para separación 100% FE/BE, crear un UserStatsRepo y mover la lógica allí.

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

// ---------------- Auth (expuesto a la UI vía repo) ----------------

/// Email del usuario autenticado (o null) como FutureProvider,
/// para que la UI pueda usar `.when(...)`.
final currentUserEmailProvider =
    FutureProvider.autoDispose<String?>((ref) async {
  final repo = ref.watch(authRepoProvider);
  return repo.currentEmail();
});

/// Acción de sign out como FutureProvider: en UI se usa `ref.read(signOutProvider.future)`.
final signOutProvider = FutureProvider.autoDispose<void>((ref) async {
  final repo = ref.watch(authRepoProvider);
  await repo.signOut();
});

/// Enviar correo de restablecimiento de contraseña.
/// Si pasas `null`, usa el email del usuario actual.
final passwordResetProvider =
    FutureProvider.autoDispose.family<void, String?>((ref, email) async {
  final repo = ref.watch(authRepoProvider);
  await repo.sendPasswordResetEmail(email: email);
});

// ================== Historial de Tours ========================

final tourHistoryProvider =
    FutureProvider.autoDispose<List<TourHistoryEntry>>((ref) async {
  final repo = ref.watch(historyRepoProvider);
  return repo.listUserHistory(limit: 200);
});

// ================== Payments ===============================
final paymentRepoProvider = Provider<PaymentRepo>(
  (ref) => SupabasePaymentRepo(),
);

final paymentMethodsProvider =
    FutureProvider.autoDispose<List<PaymentMethod>>((ref) async {
  final repo = ref.watch(paymentRepoProvider);
  return repo.list();
});


