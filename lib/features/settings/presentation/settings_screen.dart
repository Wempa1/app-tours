import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avanti/di/providers.dart'; // currentUserEmailProvider, signOutProvider

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    // Evita use_build_context_synchronously capturando el messenger antes del await
    final messenger = ScaffoldMessenger.of(context);
    final doSignOut = ref.read(signOutProvider);
    await doSignOut();
    messenger.showSnackBar(const SnackBar(content: Text('Signed out')));
    // Si tienes pantalla de login, aquí podrías navegar:
    // context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(currentUserEmailProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.alternate_email),
              title: const Text('Email'),
              subtitle: Text(email ?? '-'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
              onPressed: () => _signOut(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
