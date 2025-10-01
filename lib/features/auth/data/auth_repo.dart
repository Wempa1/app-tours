import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepo {
  String? currentEmail();
  Future<void> signOut();
  Future<void> sendPasswordResetEmail({String? email});
}

class SupabaseAuthRepo implements AuthRepo {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  String? currentEmail() => _db.auth.currentUser?.email;

  @override
  Future<void> signOut() => _db.auth.signOut();

  @override
  Future<void> sendPasswordResetEmail({String? email}) async {
    final target = email ?? _db.auth.currentUser?.email;
    if (target == null || target.isEmpty) {
      throw StateError('No hay email para resetear contraseña.');
    }
    // Puedes configurar redirectTo si ya tienes un deep link:
    // await _db.auth.resetPasswordForEmail(target, redirectTo: 'io.supabase.flutter://reset-callback');
    await _db.auth.resetPasswordForEmail(target);
  }
}
