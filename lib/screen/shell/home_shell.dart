import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../home/home_screen.dart';
import '../catalog/catalog_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';

class HomeShell extends StatefulWidget {
  final Widget child; // no lo usamos en este patrón, pero ShellRoute lo provee
  const HomeShell({super.key, required this.child});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indexFromPath(String path) {
    if (path.startsWith('/catalog')) return 1;
    if (path.startsWith('/map')) return 2;
    if (path.startsWith('/profile')) return 3;
    return 0; // home
  }

  void _go(int i) {
    switch (i) {
      case 0: context.go('/home'); break;
      case 1: context.go('/catalog'); break;
      case 2: context.go('/map'); break;
      case 3: context.go('/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final index = _indexFromPath(currentPath);

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: const [
            HomeScreen(),
            CatalogScreen(),
            MapScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _go,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Catalog'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
