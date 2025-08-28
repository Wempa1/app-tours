import 'package:avanti/core/services/retry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('withRetry reintenta cuando la función falla', () async {
    int attempts = 0;
    Future<int> failing() async {
      attempts++;
      if (attempts < 3) {
        throw Exception('fallo');
      }
      return 42;
    }

    final result = await withRetry<int>(
      failing,
      maxAttempts: 3,
      baseDelay: const Duration(milliseconds: 10),
    );
    expect(result, 42);
    expect(attempts, 3);
  });

  test('withRetry respeta retryIf=false y no reintenta', () async {
    int attempts = 0;
    Future<void> failing() async {
      attempts++;
      throw StateError('no reintentar');
    }

    try {
      await withRetry<void>(failing, maxAttempts: 5, retryIf: (e) => false);
      fail('Debió lanzar excepción');
    } catch (e) {
      expect(e, isA<StateError>());
      expect(attempts, 1);
    }
  });
}
