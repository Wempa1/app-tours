import 'dart:math';

typedef AsyncFn<T> = Future<T> Function();

Future<T> withRetry<T>(
  AsyncFn<T> fn, {
  int maxAttempts = 3,
  Duration baseDelay = const Duration(milliseconds: 300),
  double jitterRatio = 0.25, // ±25%
  bool Function(Object error)? retryIf,
}) async {
  Object? lastErr;
  StackTrace? lastSt;

  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (e, st) {
      lastErr = e;
      lastSt = st;
      final allow = retryIf?.call(e) ?? true;
      final isLast = attempt == maxAttempts;
      if (!allow || isLast) break;

      // backoff exponencial con jitter
      final factor = pow(2, attempt - 1).toDouble();
      final base = baseDelay * factor;
      final jitterMs = (base.inMilliseconds * jitterRatio);
      final deltaMs = (Random().nextDouble() * jitterMs * 2) - jitterMs;
      final wait = base + Duration(milliseconds: deltaMs.round());
      await Future.delayed(wait);
    }
  }
  // re-lanza el último error si no hubo éxito
  assert(lastErr != null);
  // ignore: only_throw_errors
  throw lastErr!;
}
