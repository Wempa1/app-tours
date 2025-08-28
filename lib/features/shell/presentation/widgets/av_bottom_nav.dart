import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/home_screen.dart';
import '../../../map/presentation/map_screen.dart';
import '../../../settings/presentation/settings_screen.dart';
import '../../../tours/presentation/catalog_screen.dart';

class AvBottomNav extends StatefulWidget {
  const AvBottomNav({super.key});
  @override
  State<AvBottomNav> createState() => _AvBottomNavState();
}

class _AvBottomNavState extends State<AvBottomNav> {
  int _index = 0;

  late final List<Widget> _screens = const [
    HomeScreen(),
    CatalogScreen(),
    MapScreen(),
    SettingsScreen(), // (menú/perfil)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Catálogo',
          ),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Mapa'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Menú',
          ),
        ],
      ),
    );
  }
}
