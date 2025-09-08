// lib/core/ui/router.dart
import 'package:go_router/go_router.dart';

import 'package:avanti/features/shell/presentation/widgets/av_bottom_nav.dart';
import 'package:avanti/features/tours/presentation/tour_detail_screen.dart';

/// Router de la app:
/// - '/'         -> AvBottomNav(tab Home)
/// - '/catalog'  -> AvBottomNav(tab Catálogo)
/// - '/map'      -> AvBottomNav(tab Mapa)
/// - '/settings' -> AvBottomNav(tab Menú/Perfil)
/// - '/tour/:id' -> Detalle de tour (sin bottom bar)
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
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
