// lib/features/map/presentation/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:avanti/core/services/location_service.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationServiceProvider);
    const fallback = LatLng(48.8546, 2.3477); // París (fallback)

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: FutureBuilder(
        future: location.currentPositionOrNull(),
        builder: (context, snap) {
          var center = fallback;
          Marker? userMarker;

          if (snap.connectionState == ConnectionState.done && snap.data != null) {
            final pos = snap.data!;
            center = LatLng(pos.latitude, pos.longitude);
            userMarker = Marker(
              point: center,
              width: 40,
              height: 40,
              child: const Icon(Icons.my_location, size: 32),
            );
          }

          return FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15,
            ),
            children: [
              // <- sin const (según versión de flutter_map, no es const)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.avanti',
              ),
              if (userMarker != null) MarkerLayer(markers: [userMarker]),
              // <- tampoco const aquí ni en los elementos de la lista
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
