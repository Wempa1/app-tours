import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:avanti/features/home/presentation/widgets/home_screen.dart';
import 'package:avanti/features/tours/presentation/catalog_screen.dart';
import 'package:avanti/features/tours/presentation/tour_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/catalog',
      name: 'catalog',
      builder: (context, state) => const CatalogScreen(),
    ),
    GoRoute(
      path: '/tour/:id',
      name: 'tourDetail',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        if (id == null || id.isEmpty) {
          return const _RouteErrorScreen(
            message: 'Falta el parámetro de tour (id).',
          );
        }
        return TourDetailScreen(tourId: id);
      },
    ),
  ],
  errorBuilder: (context, state) => _RouteErrorScreen(
    message: state.error?.toString() ?? 'Ruta no encontrada',
  ),
);

class _RouteErrorScreen extends StatelessWidget {
  final String message;
  const _RouteErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navegación')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
