import 'dart:math';

typedef AsyncFn<T> = Future<T> Function();

/// Ejecuta [fn] con backoff exponencial + jitter.
/// - [maxAttempts]: intentos totales (>=1)
/// - [baseDelay]: delay base para el primer reintento
/// - [jitterRatio]: 0..1 (±porcentaje de jitter sobre el delay calculado)
/// - [retryIf]: decide si reintentar para un error dado (por defecto: siempre)
Future<T> withRetry<T>(
  AsyncFn<T> fn, {
  int maxAttempts = 3,
  Duration baseDelay = const Duration(milliseconds: 300),
  double jitterRatio = 0.25, // ±25%
  bool Function(Object error)? retryIf,
}) async {
  assert(maxAttempts >= 1);
  final rand = Random();
  Object? lastErr;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (e) {
      lastErr = e;

      final allow = retryIf?.call(e) ?? true;
      final isLast = attempt == maxAttempts;
      if (!allow || isLast) break;

      // Backoff exponencial en ms: 1x, 2x, 4x, ...
      final factor = 1 << (attempt - 1); // 1,2,4,...
      final baseMs = baseDelay.inMilliseconds * factor;

      // Jitter acotado [-j, +j]
      final jr = jitterRatio.clamp(0.0, 1.0);
      final jitterSpan = (baseMs * jr).round();
      final jitter = rand.nextInt(jitterSpan * 2 + 1) - jitterSpan;

      final wait = Duration(milliseconds: baseMs + jitter);
      await Future.delayed(wait);
    }
  }

  // re-lanza el último error si no hubo éxito
  // ignore: only_throw_errors
  throw lastErr!;
}
