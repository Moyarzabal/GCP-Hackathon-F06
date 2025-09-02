import '../errors/failures.dart';

/// Result type for error handling
sealed class Result<T> {
  const Result();

  /// Creates a successful result
  const factory Result.success(T data) = Success<T>;

  /// Creates a failure result
  const factory Result.failure(Failure failure) = Failed<T>;

  /// Returns true if the result is successful
  bool get isSuccess => this is Success<T>;

  /// Returns true if the result is a failure
  bool get isFailure => this is Failed<T>;

  /// Returns the data if successful, null otherwise
  T? get data => switch (this) {
        Success<T> success => success.data,
        Failed<T> _ => null,
      };

  /// Returns the data if successful, null otherwise
  T? getOrNull() => data;

  /// Returns the failure if failed, null otherwise
  Failure? get failure => switch (this) {
        Success<T> _ => null,
        Failed<T> failed => failed.failure,
      };

  /// Returns the error if failed, null otherwise
  Failure? getError() => failure;

  /// Transforms the data if successful
  Result<U> map<U>(U Function(T data) transform) {
    return switch (this) {
      Success<T> success => Result.success(transform(success.data)),
      Failed<T> failed => Result.failure(failed.failure),
    };
  }

  /// Chains another result-returning operation
  Result<U> flatMap<U>(Result<U> Function(T data) transform) {
    return switch (this) {
      Success<T> success => transform(success.data),
      Failed<T> failed => Result.failure(failed.failure),
    };
  }

  /// Folds the result into a single value
  U fold<U>(
    U Function(Failure failure) onFailure,
    U Function(T data) onSuccess,
  ) {
    return switch (this) {
      Success<T> success => onSuccess(success.data),
      Failed<T> failed => onFailure(failed.failure),
    };
  }
}

/// Successful result
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  String toString() => 'Success($data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success<T> && data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Failed result
final class Failed<T> extends Result<T> {
  final Failure failure;
  const Failed(this.failure);

  @override
  String toString() => 'Failed($failure)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Failed<T> && failure == other.failure;

  @override
  int get hashCode => failure.hashCode;
}