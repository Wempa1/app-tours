import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screen/auth/login_screen.dart';
import '../screen/shell/home_shell.dart';
import '../screen/tour/tour_detail_screen.dart';

final _supabase = Supabase.instance.client;

final appRouter = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final session = _supabase.auth.currentSession;
    final path = state.uri.path; // v16: usar uri.path en lugar de subloc
    final isLogin = path == '/login';
    if (session == null) {
      return isLogin ? null : '/login';
    } else {
      return isLogin ? '/home' : null;
    }
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    // Shell con bottom tabs
    ShellRoute(
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (c, s) => const SizedBox.shrink()),
        GoRoute(path: '/catalog', builder: (c, s) => const SizedBox.shrink()),
        GoRoute(path: '/map', builder: (c, s) => const SizedBox.shrink()),
        GoRoute(path: '/profile', builder: (c, s) => const SizedBox.shrink()),
      ],
    ),
    GoRoute(
      path: '/tour/:id',
      builder: (context, state) => TourDetailScreen(tourId: state.pathParameters['id']!),
    ),
  ],
);
