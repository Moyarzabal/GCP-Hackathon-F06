import 'app_exception.dart';

/// 成功または失敗の結果を表す抽象クラス
abstract class Result<T> {
  const Result();

  /// 成功の場合のコンストラクタ
  factory Result.success(T data) = Success<T>;

  /// 失敗の場合のコンストラクタ
  factory Result.failure(AppException exception) = Failure<T>;

  /// 成功かどうかを判定
  bool get isSuccess => this is Success<T>;

  /// 失敗かどうかを判定
  bool get isFailure => this is Failure<T>;

  /// 成功の場合はデータを返し、失敗の場合はnullを返す
  T? get data => isSuccess ? (this as Success<T>).data : null;

  /// 失敗の場合は例外を返し、成功の場合はnullを返す
  AppException? get exception => isFailure ? (this as Failure<T>).exception : null;

  /// 成功の場合は変換関数を適用し、失敗の場合はそのまま返す
  Result<R> map<R>(R Function(T) mapper) {
    if (isSuccess) {
      try {
        return Success(mapper((this as Success<T>).data));
      } catch (e, stackTrace) {
        return Failure(
          ValidationException('Mapping failed: $e', details: e.toString(), stackTrace: stackTrace),
        );
      }
    }
    return Failure((this as Failure<T>).exception);
  }

  /// 非同期の変換関数を適用
  Future<Result<R>> mapAsync<R>(Future<R> Function(T) mapper) async {
    if (isSuccess) {
      try {
        final result = await mapper((this as Success<T>).data);
        return Success(result);
      } catch (e, stackTrace) {
        return Failure(
          ValidationException('Async mapping failed: $e', details: e.toString(), stackTrace: stackTrace),
        );
      }
    }
    return Failure((this as Failure<T>).exception);
  }

  /// 成功・失敗それぞれに対応する処理を実行
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException exception) failure,
  }) {
    if (isSuccess) {
      return success((this as Success<T>).data);
    } else {
      return failure((this as Failure<T>).exception);
    }
  }
}

/// 成功を表すクラス
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T> && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// 失敗を表すクラス
class Failure<T> extends Result<T> {
  final AppException exception;

  const Failure(this.exception);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure<T> && other.exception == exception;
  }

  @override
  int get hashCode => exception.hashCode;

  @override
  String toString() => 'Failure($exception)';
}

/// Resultを扱うためのヘルパー関数
extension ResultExtension<T> on Result<T> {
  /// データを取得（失敗の場合は例外をthrow）
  T get dataOrThrow {
    if (isSuccess) {
      return (this as Success<T>).data;
    } else {
      throw (this as Failure<T>).exception;
    }
  }

  /// データを取得（失敗の場合はデフォルト値を返す）
  T getOrDefault(T defaultValue) {
    return data ?? defaultValue;
  }
}