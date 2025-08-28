import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

class AppLogger {
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
    final full = [
      '[$level] $msg',
      if (data != null) 'DATA: $data',
      if (error != null) 'ERROR: $error',
      if (st != null) 'STACK: $st',
    ].join('\n');

    if (kDebugMode) {
      // Consola en debug
      // ignore: avoid_print
      print(full);
    }
    // Traza para herramientas (DevTools)
    dev.log(full, name: 'Avanti');
    // Futuro: enviar a Supabase/Sentry, si quieres.
  }
}
