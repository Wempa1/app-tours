import 'package:avanti/core/config/app_keys.dart';
import 'package:flutter/material.dart';

class AppSnack {
  static void showError(String message) {
    final ctx = AppKeys.scaffoldMessenger.currentContext;
    AppKeys.scaffoldMessenger.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: (ctx != null) ? Theme.of(ctx).colorScheme.error : null,
      ),
    );
  }

  static void showInfo(String message) {
    AppKeys.scaffoldMessenger.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
