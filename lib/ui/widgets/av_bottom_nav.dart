import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AvBottomNav extends StatelessWidget {
  final Widget child; // el contenido de la ruta activa
  const AvBottomNav({super.key, required this.child});

  static const _tabs = [
    ('/',        Icons.home_outlined,   Icons.home_rounded,   'Home'),
    ('/catalog', Icons.list_alt_outlined, Icons.list_alt,     'Catalog'),
    ('/map',     Icons.map_outlined,    Icons.map,            'Map'),
    ('/menu', Icons.menu_outlined,  Icons.menu_rounded,    'Menu'),
  ];

  int _indexForLocation(String loc) {
    for (var i = 0; i < _tabs.length; i++) {
      final base = _tabs[i].$1;
      if (loc == base || loc.startsWith('$base/')) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final current = _indexForLocation(loc);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.$2),
              selectedIcon: Icon(t.$3),
              label: t.$4,
            ),
        ],
      ),
    );
  }
}
