// lib/core/ui/router.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:avanti/features/auth/presentation/login_screen.dart';
import 'package:avanti/features/shell/presentation/widgets/av_bottom_nav.dart';
import 'package:avanti/features/tours/presentation/tour_detail_screen.dart';

/// Notificador que hace que GoRouter se "refresque" cuando cambia el estado de auth.
/// Escucha onAuthStateChange y llama a notifyListeners().
class _AuthStateNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _AuthStateNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// Instancia única para toda la app.
final _authNotifier = _AuthStateNotifier();

/// Router de la app con redirección según sesión:
/// - Si NO hay sesión  -> /auth
/// - Si hay sesión     -> /home
final appRouter = GoRouter(
  initialLocation: '/auth',
  refreshListenable: _authNotifier,
  redirect: (context, state) {
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
    final loggingIn = state.matchedLocation == '/auth';

    // No autenticado: permite solo /auth
    if (!isLoggedIn) {
      return loggingIn ? null : '/auth';
    }

    // Autenticado: si está en /auth, envía a /home
    if (loggingIn) return '/home';

    // En cualquier otra ruta, no redirigir.
    return null;
  },
  routes: [
    // Auth
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (_, __) => const LoginScreen(),
    ),

    // Home (alias en "/" y en "/home" para evitar errores de rutas inexistentes)
    GoRoute(
      path: '/',
      name: 'root',
      builder: (_, __) => const AvBottomNav(initialIndex: 0),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (_, __) => const AvBottomNav(initialIndex: 0),
    ),

    // Tabs directas
    GoRoute(
      path: '/catalog',
      name: 'catalog',
      builder: (_, __) => const AvBottomNav(initialIndex: 1),
    ),
    GoRoute(
      path: '/map',
      name: 'map',
      builder: (_, __) => const AvBottomNav(initialIndex: 2),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (_, __) => const AvBottomNav(initialIndex: 3),
    ),

    // Detalle de tour (sin bottom bar)
    GoRoute(
      path: '/tour/:id',
      name: 'tourDetail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TourDetailScreen(tourId: id);
      },
    ),
  ],
);
