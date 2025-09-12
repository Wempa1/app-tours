import 'package:supabase_flutter/supabase_flutter.dart';
import 'payment_models.dart';

abstract class PaymentRepo {
  Future<List<PaymentMethod>> list();
  Future<PaymentMethod> addTestMethod({
    required String brand,
    required String last4,
    required int expMonth,
    required int expYear,
    String? label,
  });
  Future<void> delete(String id);
  Future<void> setDefault(String id);
}

class SupabasePaymentRepo implements PaymentRepo {
  SupabaseClient get _db => Supabase.instance.client;

  String _requireUser() {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Necesitas iniciar sesión.');
    }
    return uid;
  }

  @override
  Future<List<PaymentMethod>> list() async {
    final uid = _requireUser();
    final rows = await _db
        .from('payment_methods')
        .select()
        .eq('user_id', uid)
        .order('is_default', ascending: false)
        .order('created_at', ascending: false);

    final list = List<Map<String, dynamic>>.from(rows as List? ?? const []);
    return list.map(PaymentMethod.fromJson).toList();
  }

  @override
  Future<PaymentMethod> addTestMethod({
    required String brand,
    required String last4,
    required int expMonth,
    required int expYear,
    String? label,
  }) async {
    final uid = _requireUser();

    final inserted = await _db
        .from('payment_methods')
        .insert({
          'user_id': uid,
          'brand': brand,
          'last4': last4,
          'exp_month': expMonth,
          'exp_year': expYear,
          'label': label,
          // is_default: lo decide el usuario; puedes forzar true si es el primero
        })
        .select()
        .single();

    return PaymentMethod.fromJson(Map<String, dynamic>.from(inserted));
  }

  @override
  Future<void> delete(String id) async {
    final uid = _requireUser();
    await _db.from('payment_methods').delete().eq('id', id).eq('user_id', uid);
  }

  @override
  Future<void> setDefault(String id) async {
    final uid = _requireUser();
    // Quita el default de todas las tarjetas del usuario
    await _db
        .from('payment_methods')
        .update({'is_default': false})
        .eq('user_id', uid);

    // Setea default en la elegida
    await _db
        .from('payment_methods')
        .update({'is_default': true})
        .eq('id', id)
        .eq('user_id', uid);
  }
}
