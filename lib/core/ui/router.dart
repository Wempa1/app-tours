// lib/core/ui/router.dart
import 'dart:async';

import 'package:avanti/features/auth/presentation/login_screen.dart';
import 'package:avanti/features/shell/presentation/widgets/av_bottom_nav.dart';
import 'package:avanti/features/tours/presentation/tour_detail_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Notificador que hace que GoRouter se "refresque" cuando cambia el estado de auth.
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

String _stripTrailingSlash(String path) {
  if (path.length > 1 && path.endsWith('/')) {
    return path.substring(0, path.length - 1);
  }
  return path;
}

/// Router de la app con redirección según sesión:
/// - Si NO hay sesión  -> /auth
/// - Si hay sesión     -> /home
final appRouter = GoRouter(
  initialLocation: '/auth',
  refreshListenable: _authNotifier,
  redirect: (context, state) {
    // Normaliza trailing slash para evitar variantes como '/home/'
    final loc = _stripTrailingSlash(state.matchedLocation);
    if (loc != state.matchedLocation) return loc;

    final hasSession = Supabase.instance.client.auth.currentSession != null;
    final atAuth = loc == '/auth';

    // No autenticado: solo permitimos /auth
    if (!hasSession) {
      return atAuth ? null : '/auth';
    }

    // Autenticado: si está en /auth, lo enviamos a /home
    if (hasSession && atAuth) return '/home';

    // No redirigir en otros casos
    return null;
  },
  routes: [
    // -------- Auth (sin bottom bar)
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (_, __) => const LoginScreen(),
    ),

    // -------- Tabs con bottom bar (todas construyen AvBottomNav)
    // Alias raíz por si alguien navega a "/"
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

    // -------- Detalle (sin bottom bar)
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
