import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_keys.dart';
import 'core/config/supabase_client.dart';
import 'core/logging/app_logger.dart';
import 'core/router.dart';
import 'core/theme.dart';

Future<void> main() async {
  // Captura global de errores de Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    AppLogger.e('FlutterError', details.exception, details.stack);
  };

  // Zona protegida para errores asíncronos no capturados
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await AppSupabase.init();
      runApp(const ProviderScope(child: AvantiApp()));
    },
    (error, stack) {
      AppLogger.e('Uncaught zone error', error, stack);
    },
  );
}

class AvantiApp extends StatelessWidget {
  const AvantiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Avanti',
      theme: buildTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: AppKeys.scaffoldMessenger, // <— Snackbars globales
    );
  }
}
