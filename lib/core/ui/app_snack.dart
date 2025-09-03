import 'package:avanti/core/config/app_keys.dart';
import 'package:flutter/material.dart';

class AppSnack {
  AppSnack._();

  /// Muestra un SnackBar genérico (info) con opciones.
  static void showInfo(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _show(
      message,
      duration: duration,
      action: action,
      // color por defecto = null → usa tema
      backgroundColor: null,
    );
  }

  /// Muestra un SnackBar de error con color del tema si hay contexto global.
  static void showError(
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final ctx = AppKeys.scaffoldMessenger.currentContext;
    final bg = (ctx != null) ? Theme.of(ctx).colorScheme.error : Colors.red;
    _show(
      message,
      duration: duration,
      action: action,
      backgroundColor: bg,
      contentColor: Colors.white,
    );
  }

  /// Implementación base: usa el GlobalKey del ScaffoldMessenger.
  static void _show(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
    Color? contentColor,
  }) {
    final messenger = AppKeys.scaffoldMessenger.currentState;
    if (messenger == null) {
      // Aún no hay árbol con ScaffoldMessengerKey montado.
      // Evitamos crashear silenciosamente.
      debugPrint('⚠️ AppSnack: scaffoldMessenger no disponible todavía.');
      return;
    }

    // Oculta el snackbar previo para no apilar.
    messenger.hideCurrentSnackBar();

    final snack = SnackBar(
      content: Text(
        message,
        style: (contentColor != null)
            ? TextStyle(color: contentColor, fontWeight: FontWeight.w600)
            : null,
      ),
      action: action,
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    messenger.showSnackBar(snack);
  }
}
