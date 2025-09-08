// lib/features/auth/data/auth_repo.dart
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepo {
  String? currentEmail();
  Future<void> signOut();
}

class SupabaseAuthRepo implements AuthRepo {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  String? currentEmail() => _db.auth.currentUser?.email;

  @override
  Future<void> signOut() => _db.auth.signOut();
}
