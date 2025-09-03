import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Provider global para inyectar el servicio (Riverpod)
final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

class LocationService {
  final GeolocatorPlatform _geo = GeolocatorPlatform.instance;

  /// Devuelve la posición actual o `null` si no se puede obtener.
  /// - Usa LocationSettings (API moderna) en vez de 'desiredAccuracy' (deprecated).
  Future<Position?> currentPositionOrNull({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeLimit = const Duration(seconds: 8),
    Duration overallTimeout = const Duration(seconds: 10),
  }) async {
    try {
      // 1) Servicio activado
      final serviceEnabled = await _geo.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // 2) Permisos
      var permission = await _geo.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _geo.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // 3) Posición (con timeouts)
      final settings = LocationSettings(
        accuracy: accuracy,
        timeLimit: timeLimit,
      );

      // Nota: getCurrentPosition devuelve Future<Position> (no-nullable).
      // Nosotros lo envolvemos en try/catch y devolvemos Position? (nullable).
      final position = await _geo
          .getCurrentPosition(locationSettings: settings)
          .timeout(overallTimeout);

      return position;
    } on TimeoutException {
      debugPrint('⏱️ Location timeout');
      return null;
    } catch (e, st) {
      debugPrint('⚠️ Location error: $e\n$st');
      return null;
    }
  }

  /// Última posición conocida o `null` si no existe/fracasa.
  Future<Position?> lastKnownPositionOrNull() async {
    try {
      return await _geo.getLastKnownPosition();
    } catch (e) {
      debugPrint('⚠️ lastKnownPosition error: $e');
      return null;
    }
  }
}
