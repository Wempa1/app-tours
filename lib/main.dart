import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env');

  final url = dotenv.env['SUPABASE_URL'] ?? '';
  final anon = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (url.isEmpty || anon.isEmpty) {
    debugPrint('⚠️ Missing SUPABASE_URL or SUPABASE_ANON_KEY in assets/.env');
  }

  await Supabase.initialize(url: url, anonKey: anon);
  debugPrint('✅ Avanti main() boot');

  runApp(
    
    const ProviderScope( // ⬅️ Riverpod scope para providers globales
      child: ProviderScope( // ⬅️ Riverpod scope para providers globales
      child: AvantiApp(),
    ),
  ,
    ),
  );
}

class AvantiApp extends StatelessWidget {
  const AvantiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Avanti',
      theme: buildTheme(),           // tema claro
      darkTheme: buildDarkTheme(),   // tema oscuro
      themeMode: ThemeMode.system,   // respeta el modo del sistema
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
