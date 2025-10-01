// lib/core/logging/app_logger.dart
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

typedef LogReporter = void Function(
  String level,
  String message, {
  Object? error,
  StackTrace? stackTrace,
});

class AppLogger {
  static LogReporter? _reporter;

  /// Llamar desde main() lo antes posible:
  /// AppLogger.init();
  static void init({LogReporter? reporter}) {
    _reporter = reporter;

    // Captura errores de framework Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      e(
        'FlutterError',
        details.exception,
        details.stack ?? StackTrace.current,
      );
    };

    // Captura errores no capturados a nivel de engine/plataforma
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      e('Uncaught error', error, stack);
      // true = error manejado (evita volcado adicional por el engine)
      return true;
    };
  }

  static void d(String msg, [Object? data]) {
    _log('DEBUG', msg, data: data);
  }

  static void i(String msg, [Object? data]) {
    _log('INFO', msg, data: data);
  }

  static void w(String msg, [Object? data, StackTrace? st]) {
    _log('WARN', msg, error: data, st: st);
  }

  static void e(String msg, [Object? err, StackTrace? st]) {
    _log('ERROR', msg, error: err, st: st);
  }

  static void _log(
    String level,
    String msg, {
    Object? data,
    Object? error,
    StackTrace? st,
  }) {
    final parts = <String>[
      '[$level] $msg',
      if (data != null) 'DATA: $data',
      if (error != null) 'ERROR: $error',
      if (st != null) 'STACK: $st',
    ];
    final full = parts.join('\n');

    if (kDebugMode) {
      // Consola amigable en debug (evita lint avoid_print)
      debugPrint(full);
    }

    // Traza para DevTools (visible en Timeline / Logging)
    dev.log(
      full,
      name: 'Avanti',
      error: error,
      stackTrace: st,
      level: _levelToInt(level),
    );

    // Reporter externo opcional (Sentry/Datadog/lo que sea)
    final r = _reporter;
    if (r != null) {
      try {
        r(level, msg, error: error, stackTrace: st);
      } catch (_) {
        // Nunca dejes que el reporter rompa la app
      }
    }
  }

  static int _levelToInt(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARN':
        return 900;
      case 'ERROR':
        return 1000;
      default:
        return 0;
    }
  }
}
