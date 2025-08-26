// lib/ui/widgets/av_bottom_nav.dart
import 'package:flutter/material.dart';

// Páginas de cada pestaña
import '../../screen/home/home_screen.dart';
import '../../screen/catalog/catalog_screen.dart';
import '../../screen/map/map_screen.dart';
import '../../screen/menu/menu_screen.dart';

class AvBottomNav extends StatefulWidget {
  const AvBottomNav({super.key});

  @override
  State<AvBottomNav> createState() => _AvBottomNavState();
}

class _AvBottomNavState extends State<AvBottomNav> {
  int _index = 0;

  final _screens = const <Widget>[
    HomeScreen(),
    CatalogScreen(),
    MapScreen(),
    MenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: _screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Catalog',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu),
            selectedIcon: Icon(Icons.menu_open),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}
