// lib/features/shell/presentation/widgets/av_bottom_nav.dart
import 'package:avanti/features/home/presentation/widgets/home_screen.dart';
import 'package:avanti/features/map/presentation/map_screen.dart';
import 'package:avanti/features/settings/presentation/settings_screen.dart';
import 'package:avanti/features/tours/presentation/catalog_screen.dart';
import 'package:flutter/material.dart';

class AvBottomNav extends StatefulWidget {
  /// Permite abrir el shell directamente en una pestaña concreta
  /// (0=Home, 1=Catálogo, 2=Mapa, 3=Menú).
  final int initialIndex;
  const AvBottomNav({super.key, this.initialIndex = 0});

  @override
  State<AvBottomNav> createState() => _AvBottomNavState();
}

class _AvBottomNavState extends State<AvBottomNav> {
  late int _index = widget.initialIndex.clamp(0, 3);

  // Mantiene estado con IndexedStack (listas, scroll, etc).
  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    CatalogScreen(),
    MapScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // IndexedStack conserva el estado de cada tab
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
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Menú',
          ),
        ],
      ),
    );
  }
}
