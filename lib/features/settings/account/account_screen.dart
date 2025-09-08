import 'package:avanti/di/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailAsync = ref.watch(currentUserEmailProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cabecera
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Datos de la cuenta',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text('Información básica y seguridad'),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          // Email
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

          const SizedBox(height: 8),

          // Seguridad
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Seguridad', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Cambiar contraseña'),
            subtitle: const Text('Recibirás un enlace por correo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                // usa el email actual por defecto
                await ref.read(passwordResetProvider(null).future);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Te enviamos un correo para cambiar tu contraseña.')),
                );
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('No pudimos enviar el correo. Intenta de nuevo.')),
                );
              }
            },
          ),

          const SizedBox(height: 24),

          // (Opcional) Cerrar sesión también desde aquí, por comodidad
          Center(
            child: OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref.read(signOutProvider.future);
                  if (context.mounted) {
                    messenger.showSnackBar(const SnackBar(content: Text('Sesión cerrada')));
                    Navigator.of(context).pop(); // volver a Settings
                  }
                } catch (_) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('No pudimos cerrar sesión. Intenta de nuevo.')),
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
    );
  }
}
