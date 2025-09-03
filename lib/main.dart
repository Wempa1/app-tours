import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Deben existir en lib/core/ui/
import 'core/ui/router.dart'; // exporta: final GoRouter appRouter = ...
import 'core/ui/theme.dart';  // exporta: ThemeData buildTheme()/buildDarkTheme()

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Intentamos con --dart-define
  var url = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  var key = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  // 2) Si no vienen, cargamos desde assets/.env
  if (url.isEmpty || key.isEmpty) {
    await dotenv.load(fileName: 'assets/.env');
    url = dotenv.env['SUPABASE_URL'] ?? '';
    key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  // 3) Validación en runtime (evita "No host specified in URI")
  final isValid = url.startsWith('http') && key.isNotEmpty;
  if (!isValid) {
    runApp(const _ConfigErrorApp());
    return;
  }

  await Supabase.initialize(url: url, anonKey: key);

  runApp(const ProviderScope(child: AvantiApp()));
}

class AvantiApp extends StatelessWidget {
  const AvantiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Avanti',
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      routerConfig: appRouter,
    );
  }
}

/// Pantalla de error de configuración (si faltan credenciales)
class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Faltan credenciales de Supabase.\n\n'
                'Configura SUPABASE_URL y SUPABASE_ANON_KEY via --dart-define,\n'
                'o crea assets/.env con:\n'
                'SUPABASE_URL=...\nSUPABASE_ANON_KEY=...',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
