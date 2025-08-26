// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/widgets/av_bottom_nav.dart';
import '../screen/tour/tour_detail_route.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Raíz: barra inferior con pestañas (sin ShellRoute)
    GoRoute(
      path: '/',
      name: 'root',
      builder: (context, state) => const AvBottomNav(),
    ),

    // Detalle de tour: se navega con context.push('/tour/<id>')
    GoRoute(
      path: '/tour/:id',
      name: 'tour',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        if (id == null || id.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Missing tour id')),
          );
        }
        return TourDetailRoute(id: id);
      },
    ),
  ],

  // Si algo falla en el enrutado, muestra un Scaffold en lugar de “pantalla negra”.
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Route error')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('Routing error: ${state.error ?? 'Unknown'}'),
    ),
  ),
);
