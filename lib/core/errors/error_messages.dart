/// エラーメッセージの日本語化とエラーコードの管理
class ErrorMessages {
  static const Map<String, String> _userFriendlyMessages = {
    'NetworkException': 'ネットワークエラー',
    'AuthException': '認証エラー',
    'DatabaseException': 'データエラー',
    'ValidationException': '入力エラー',
    'ScannerException': 'スキャナーエラー',
    'ApiException': 'サーバーエラー',
    'Exception': 'エラーが発生しました',
  };

  static const Map<String, String> _detailedMessages = {
    'NetworkException': 'インターネット接続を確認してください。',
    'AuthException': '認証に失敗しました。再度ログインしてください。',
    'DatabaseException': 'データの読み込みに失敗しました。アプリを再起動してください。',
    'ValidationException': '入力された情報に問題があります。内容を確認してください。',
    'ScannerException': 'カメラへのアクセスに失敗しました。権限を確認してください。',
    'ApiException': 'サーバーに接続できませんでした。しばらく時間をおいて再試行してください。',
    'Exception': '予期しないエラーが発生しました。問題が続く場合は、サポートにお問い合わせください。',
  };

  static const Map<String, String> _recoverySuggestions = {
    'NetworkException': 'ネットワーク接続を確認して、再試行してください。',
    'AuthException': '再度ログインしてください。',
    'ValidationException': '入力内容を確認して、修正してください。',
    'DatabaseException': 'アプリを再起動してください。問題が続く場合は、サポートにお問い合わせください。',
    'ScannerException': 'カメラの権限を確認して、再試行してください。',
    'ApiException': 'しばらく時間をおいて再試行してください。',
    'Exception': '問題が続く場合は、アプリを再起動してください。',
  };

  /// ユーザーフレンドリーなメッセージを取得
  static String getUserFriendlyMessage(Object error) {
    final type = error.runtimeType.toString();
    return _userFriendlyMessages[type] ?? _userFriendlyMessages['Exception']!;
  }

  /// 詳細なエラーメッセージを取得
  static String getDetailedMessage(Object error) {
    final type = error.runtimeType.toString();
    return _detailedMessages[type] ?? _detailedMessages['Exception']!;
  }

  /// エラー回復のための提案を取得
  static String getRecoverySuggestion(Object error) {
    final type = error.runtimeType.toString();
    return _recoverySuggestions[type] ?? _recoverySuggestions['Exception']!;
  }
}

/// エラーコードの体系化
class ErrorCodes {
  // ネットワーク関連 (1000-1999)
  static const int networkTimeout = 1001;
  static const int networkUnavailable = 1002;
  static const int networkSlowConnection = 1003;

  // 認証関連 (2000-2999)
  static const int authInvalidCredentials = 2001;
  static const int authTokenExpired = 2002;
  static const int authPermissionDenied = 2003;
  static const int authBiometricNotAvailable = 2004;

  // データベース関連 (3000-3999)
  static const int databaseConnectionFailed = 3001;
  static const int databaseQueryFailed = 3002;
  static const int databaseCorrupted = 3003;
  static const int databaseMigrationFailed = 3004;

  // バリデーション関連 (4000-4999)
  static const int validationRequiredField = 4001;
  static const int validationInvalidFormat = 4002;
  static const int validationOutOfRange = 4003;
  static const int validationDuplicateValue = 4004;

  // スキャナー関連 (5000-5999)
  static const int scannerPermissionDenied = 5001;
  static const int scannerCameraNotFound = 5002;
  static const int scannerBarcodeNotDetected = 5003;
  static const int scannerImageProcessingFailed = 5004;

  // API関連 (6000-6999)
  static const int apiServerError = 6001;
  static const int apiRateLimitExceeded = 6002;
  static const int apiInvalidResponse = 6003;
  static const int apiServiceUnavailable = 6004;

  /// エラーコードからメッセージを取得
  static String getMessageByCode(int errorCode) {
    switch (errorCode) {
      // ネットワーク関連
      case networkTimeout:
        return '接続がタイムアウトしました';
      case networkUnavailable:
        return 'ネットワークに接続できません';
      case networkSlowConnection:
        return 'ネットワーク接続が遅くなっています';

      // 認証関連
      case authInvalidCredentials:
        return 'ログイン情報が正しくありません';
      case authTokenExpired:
        return 'ログインの有効期限が切れました';
      case authPermissionDenied:
        return 'アクセス権限がありません';
      case authBiometricNotAvailable:
        return '生体認証が利用できません';

      // データベース関連
      case databaseConnectionFailed:
        return 'データベースに接続できません';
      case databaseQueryFailed:
        return 'データの取得に失敗しました';
      case databaseCorrupted:
        return 'データベースが破損しています';
      case databaseMigrationFailed:
        return 'データベースの更新に失敗しました';

      // バリデーション関連
      case validationRequiredField:
        return '必須項目が入力されていません';
      case validationInvalidFormat:
        return '入力形式が正しくありません';
      case validationOutOfRange:
        return '値が範囲外です';
      case validationDuplicateValue:
        return '重複する値が入力されています';

      // スキャナー関連
      case scannerPermissionDenied:
        return 'カメラの使用権限がありません';
      case scannerCameraNotFound:
        return 'カメラが見つかりません';
      case scannerBarcodeNotDetected:
        return 'バーコードが検出されませんでした';
      case scannerImageProcessingFailed:
        return '画像の処理に失敗しました';

      // API関連
      case apiServerError:
        return 'サーバーエラーが発生しました';
      case apiRateLimitExceeded:
        return 'リクエスト回数の上限に達しました';
      case apiInvalidResponse:
        return 'サーバーからの応答が無効です';
      case apiServiceUnavailable:
        return 'サービスが一時的に利用できません';

      default:
        return '未知のエラーが発生しました';
    }
  }

  /// エラーコードから重要度を取得
  static ErrorSeverity getSeverityByCode(int errorCode) {
    if (errorCode >= 3000 && errorCode < 4000) {
      return ErrorSeverity.critical; // データベース関連
    } else if (errorCode >= 2000 && errorCode < 3000) {
      return ErrorSeverity.error; // 認証関連
    } else if (errorCode >= 6000 && errorCode < 7000) {
      return ErrorSeverity.error; // API関連
    } else if (errorCode >= 1000 && errorCode < 2000) {
      return ErrorSeverity.warning; // ネットワーク関連
    } else if (errorCode >= 5000 && errorCode < 6000) {
      return ErrorSeverity.warning; // スキャナー関連
    } else {
      return ErrorSeverity.info; // その他
    }
  }
}

/// エラー重要度の定義
enum ErrorSeverity { info, warning, error, critical }
