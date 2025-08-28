import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/shell/presentation/widgets/av_bottom_nav.dart';
import '../screen/tour/tour_detail_route.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'root',
      builder: (_, __) => const AvBottomNav(),
      routes: [
        // /tour/:id
        GoRoute(
          path: 'tour/:id',
          name: 'tour-detail',
          builder: (context, state) {
            final tourId = state.pathParameters['id']!;
            return TourDetailRoute(tourId: tourId);
          },
        ),
      ],
    ),
  ],
  errorBuilder: (_, state) => Scaffold(
    appBar: AppBar(title: const Text('Route error')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text('Routing error: ${state.error ?? 'Unknown'}'),
    ),
  ),
);
