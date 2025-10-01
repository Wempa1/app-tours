// lib/features/settings/presentation/settings_screen.dart

import 'package:avanti/di/providers.dart';
import 'package:avanti/features/settings/account/account_screen.dart';
import 'package:avanti/features/settings/history/history_screen.dart';
import 'package:avanti/features/settings/payments/payment_methods_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(signOutProvider.future);
      if (!context.mounted) return;
      // Redirige a la pantalla de autenticación
      context.go('/auth');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos cerrar sesión. Intenta de nuevo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailAsync = ref.watch(currentUserEmailProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cabecera: email del usuario
          emailAsync.when(
            data: (email) => ListTile(
              leading: const Icon(Icons.alternate_email),
              title: const Text('Email'),
              subtitle: Text(email ?? '-'),
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
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountScreen()),
              );
            },
          ),

          // Historial de Tours
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historial de Tours'),
            subtitle: const Text('Tours completados y progreso'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
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
                MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
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
              onPressed: () => _handleSignOut(context, ref),
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
// Pantallas placeholder para secciones aún no implementadas
// (Nota: Eliminado _PaymentMethodsScreen porque ya existe PaymentMethodsScreen real)
// ----------------------------------------------

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

  Future<void> _openAppSettings(BuildContext context) async {
    final ok = await Geolocator.openAppSettings();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Abriendo ajustes…' : 'No se pudo abrir ajustes')),
    );
  }

  Future<void> _openLocationSettings(BuildContext context) async {
    final ok = await Geolocator.openLocationSettings();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Abriendo ajustes de ubicación…' : 'No se pudo abrir ajustes de ubicación',
        ),
      ),
    );
  }

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
                    onPressed: () => _openAppSettings(context),
                    icon: const Icon(Icons.settings),
                    label: const Text('Abrir Ajustes'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openLocationSettings(context),
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
