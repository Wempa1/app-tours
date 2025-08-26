import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screen/home/home_screen.dart';
import '../screen/catalog/catalog_screen.dart';
import '../screen/map/map_screen.dart';
import '../screen/menu/menu_screen.dart';
import '../screen/tour/tour_detail_route.dart';   // loader que hicimos
import '../ui/widgets/av_bottom_nav.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Shell con bottom nav persistente
    ShellRoute(
      builder: (context, state, child) => AvBottomNav(child: child),
      routes: [
        GoRoute(path: '/',        name: 'home',    builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/catalog', name: 'catalog', builder: (_, __) => const CatalogScreen()),
        GoRoute(path: '/map',     name: 'map',     builder: (_, __) => const MapScreen()),
        GoRoute(path: '/menu', name: 'menu', builder: (_, __) => const MenuScreen()),
      ],
    ),
    // Detalle de tour (sin bottom nav)
    GoRoute(
      path: '/tour/:id',
      name: 'tour',
      builder: (_, state) => TourDetailRoute(id: state.pathParameters['id']!),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(child: Text('Route error: ${state.error}')),
  ),
);
