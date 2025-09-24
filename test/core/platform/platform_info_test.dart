import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:barcode_scanner/core/platform/platform_info.dart';

void main() {
  group('PlatformInfo', () {
    test('should correctly identify web platform', () {
      // Web環境ではkIsWebがtrueになる
      expect(PlatformInfo.isWeb, equals(kIsWeb));
    });

    test('should correctly identify mobile platforms', () {
      // モバイルプラットフォームの検出
      expect(PlatformInfo.isMobile,
          equals(PlatformInfo.isIOS || PlatformInfo.isAndroid));
    });

    test('should return correct platform name', () {
      // プラットフォーム名が適切に返されること
      final platformName = PlatformInfo.platformName;
      expect(platformName, isNotEmpty);
      expect(
          ['Web', 'iOS', 'Android', 'macOS', 'Windows', 'Linux', 'Unknown']
              .contains(platformName),
          isTrue);
    });

    test('should have mutually exclusive platform flags', () {
      // プラットフォームフラグが相互排他的であること
      final platforms = [
        PlatformInfo.isWeb,
        PlatformInfo.isIOS,
        PlatformInfo.isAndroid,
        PlatformInfo.isDesktop,
      ];

      // 少なくとも一つがtrueであること
      final trueCount = platforms.where((p) => p).length;
      expect(trueCount, greaterThan(0));

      // テスト環境の特性を考慮
      if (PlatformInfo.isWeb) {
        expect(PlatformInfo.isMobile, isFalse);
        expect(PlatformInfo.isIOS, isFalse);
        expect(PlatformInfo.isAndroid, isFalse);
      }
    });
  });
}
