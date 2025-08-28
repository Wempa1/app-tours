sealed class Result<T> {
  const Result();
  R when<R>({
    required R Function(T value) ok,
    required R Function(Object error, StackTrace? st) err,
  });
  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
  @override
  R when<R>({
    required R Function(T value) ok,
    required R Function(Object error, StackTrace? st) err,
  }) => ok(value);
}

class Err<T> extends Result<T> {
  final Object error;
  final StackTrace? stackTrace;
  const Err(this.error, [this.stackTrace]);
  @override
  R when<R>({
    required R Function(T value) ok,
    required R Function(Object error, StackTrace? st) err,
  }) => err(error, stackTrace);
}
