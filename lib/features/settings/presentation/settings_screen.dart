// lib/features/settings/presentation/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:avanti/di/providers.dart';
import 'package:avanti/features/settings/account/account_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Como es FutureProvider<String?>, obtenemos un AsyncValue<String?>
    final emailAsync = ref.watch(currentUserEmailProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cabecera: email del usuario (usa .when de AsyncValue)
          emailAsync.when(
            data: (email) => ListTile(
              leading: const Icon(Icons.alternate_email),
              title: const Text('Email'),
              subtitle: Text(email ?? '—'),
            ),
            loading: () => const ListTile(
              leading: Icon(Icons.alternate_email),
              title: Text('Email'),
              subtitle: Text('Cargando…'),
            ),
            error: (_, __) => const ListTile(
              leading: Icon(Icons.alternate_email),
              title: Text('Email'),
              subtitle: Text('—'),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),

          // Lista de opciones
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Opciones',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),

          // Cuenta
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Cuenta'),
            subtitle: const Text('Datos personales y seguridad'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            ),
          ),

          // Historial de Tours
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historial de Tours'),
            subtitle: const Text('Tours completados y progreso'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _HistoryScreen()),
              );
            },
          ),

          // Métodos de pago
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Métodos de Pago'),
            subtitle: const Text('Tarjetas y facturación'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _PaymentsScreen()),
              );
            },
          ),

          // Permisos
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Permisos'),
            subtitle: const Text('Reestablece permisos si fueron denegados'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _PermissionsScreen()),
              );
            },
          ),

          // Configuración
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configuración'),
            subtitle: const Text('Preferencias de la aplicación'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _PreferencesScreen()),
              );
            },
          ),

          const SizedBox(height: 24),

          // Botón de Cerrar sesión centrado
          Center(
            child: FilledButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  // Soporta ambas variantes: Provider<Future<void> Function()>
                  // o, si cambiara por error, FutureProvider<void>.
                  final dynamic signOutAny = ref.read(signOutProvider);
                  if (signOutAny is Future<void> Function()) {
                    await signOutAny();
                  } else if (signOutAny is Future<void>) {
                    await signOutAny;
                  } else {
                    // Fallback: usa el repo directamente
                    await ref.read(authRepoProvider).signOut();
                  }

                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Signed out')),
                  );
                } catch (_) {
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content:
                          Text('No pudimos cerrar sesión. Intenta de nuevo.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ----------------------------------------------
// Pantallas placeholder para cada sección
// ----------------------------------------------

class _HistoryScreen extends StatelessWidget {
  const _HistoryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Tours')),
      body: const Center(
        child: Text('Pantalla de Historial (pendiente de implementar)'),
      ),
    );
  }
}

class _PaymentsScreen extends StatelessWidget {
  const _PaymentsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Métodos de Pago')),
      body: const Center(
        child: Text('Pantalla de Pagos (pendiente de implementar)'),
      ),
    );
  }
}

class _PreferencesScreen extends StatelessWidget {
  const _PreferencesScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: const Center(
        child: Text('Pantalla de Configuración (pendiente de implementar)'),
      ),
    );
  }
}

class _PermissionsScreen extends StatelessWidget {
  const _PermissionsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permisos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Permisos de la aplicación'),
              subtitle: Text(
                'Si negaste un permiso, puedes habilitarlo desde los ajustes del dispositivo.',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await Geolocator.openAppSettings();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Abriendo ajustes…'
                                : 'No se pudo abrir ajustes',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Ajustes'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await Geolocator.openLocationSettings();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Abriendo ajustes de ubicación…'
                                : 'No se pudo abrir ajustes de ubicación',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('Ubicación'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
