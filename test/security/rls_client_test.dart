// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

bool _isRlsDenied(String message) {
  final m = message.toLowerCase();
  return m.contains('row-level security') ||
         m.contains('permission') ||
         m.contains('forbidden') ||
         m.contains('unauthorized') ||
         m.contains('not allowed');
}

void main() {
  // Lee credenciales del entorno (local o CI)
  final url = Platform.environment['SUPABASE_URL'];
  final anon = Platform.environment['SUPABASE_ANON_KEY'];
  final hasEnv = (url != null && url.isNotEmpty && anon != null && anon.isNotEmpty);

  late SupabaseClient client;

  setUpAll(() {
    final u = Platform.environment['SUPABASE_URL'];
    final a = Platform.environment['SUPABASE_ANON_KEY'];
    if (u == null || a == null || u.isEmpty || a.isEmpty) return;
    client = SupabaseClient(u, a);
  });

  group('RLS (anon) —', () {
    test('setup env', () {
      if (!hasEnv) {
        print('⚠️ SUPABASE_URL / SUPABASE_ANON_KEY no están en el entorno. Saltando tests RLS.');
        return;
      }
      expect(hasEnv, isTrue);
    });

    test('read tours published OK', () async {
      if (!hasEnv) return;
      final rows = await client
          .from('tours')
          .select()
          .eq('published', true)
          .limit(1);
      expect(rows, isA<List>());
    });

    test('insert into tours should fail (RLS)', () async {
      if (!hasEnv) return;
      try {
        await client.from('tours').insert({
          'title': 'RLS Test',
          'slug': 'rls-test-${DateTime.now().millisecondsSinceEpoch}',
          'published': false,
        });
        fail('Se esperaba error por RLS al insertar en tours.');
      } on PostgrestException catch (e) {
        expect(_isRlsDenied(e.message), isTrue,
            reason: 'Mensaje recibido: "${e.message}"');
      }
    });

    test('insert into stops should fail (RLS)', () async {
      if (!hasEnv) return;
      try {
        await client.from('stops').insert({
          'tour_id': '00000000-0000-0000-0000-000000000000',
          'order_index': 1,
          'title': 'No debería insertarse',
        });
        fail('Se esperaba error por RLS al insertar en stops.');
      } on PostgrestException catch (e) {
        expect(_isRlsDenied(e.message), isTrue,
            reason: 'Mensaje recibido: "${e.message}"');
      }
    });

    test('rpc record_tour_completion should fail without auth', () async {
      if (!hasEnv) return;
      try {
        await client.rpc('record_tour_completion', params: {
          'p_tour_id': '00000000-0000-0000-0000-000000000000',
          'p_duration_minutes': 10,
        });
        fail('Se esperaba error por falta de auth en RPC.');
      } on PostgrestException {
        // ✅ Cualquier PostgrestException nos sirve; fallar sin auth es correcto
      }
    });

    test('storage: public read allowed, write blocked for anon', () async {
      if (!hasEnv) return;

      // Subida: debe fallar
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      try {
        await client.storage.from('avanti-public').uploadBinary(
              'tours/rls_test_${DateTime.now().millisecondsSinceEpoch}.bin',
              bytes,
              fileOptions: const FileOptions(contentType: 'application/octet-stream'),
            );
        fail('Se esperaba error por RLS en storage upload.');
      } on StorageException catch (e) {
        expect(_isRlsDenied(e.message), isTrue,
            reason: 'Mensaje recibido: "${e.message}"');
      }

      // Listado: debe funcionar (lectura pública)
      final files = await client.storage.from('avanti-public').list(
            path: 'tours',
            searchOptions: const SearchOptions(limit: 1),
          );
      expect(files, isA<List>());
    });
  });
}
