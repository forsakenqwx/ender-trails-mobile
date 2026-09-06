import 'package:fpdart/fpdart.dart';

import 'failure.dart';

/// Результат любой операции, которая может провалиться.
///
/// Успех — [Right], провал — [Left] с [Failure].
typedef Result<T> = Either<Failure, T>;

/// Успех без значения.
typedef ResultUnit = Result<Unit>;

/// Быстрые конструкторы, чтобы не импортировать fpdart в каждый файл.
Result<T> ok<T>(T value) => Either<Failure, T>.right(value);

ResultUnit get okUnit => Either<Failure, Unit>.right(unit);

Result<T> fail<T>(Failure failure) => Either<Failure, T>.left(failure);

extension ResultX<T> on Result<T> {
  T? get valueOrNull => fold((_) => null, (v) => v);

  Failure? get failureOrNull => fold((f) => f, (_) => null);

  bool get isOk => isRight();
}
