import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/platform/platform_info.dart';

/// デバイス警告バナーの状態管理
final deviceWarningProvider = StateProvider<bool>((ref) => true);

/// PCアクセス時の警告メッセージ（画面中央に大きく表示）
class DeviceWarningBanner extends ConsumerWidget {
  const DeviceWarningBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShow = PlatformInfo.shouldShowWarning(context);
    final isVisible = ref.watch(deviceWarningProvider);

    if (!shouldShow || !isVisible) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // 半透明の背景オーバーレイ
        Container(
          color: Colors.black.withOpacity(0.3),
        ),
        // 中央の警告メッセージ
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // スマートフォンアイコン
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.smartphone,
                    color: Colors.orange.shade700,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                // メッセージテキスト
                Text(
                  '本サービスはスマートフォン端末で\n最適に表示されます',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '快適にご利用いただくため、\nスマートフォンからアクセスしてください',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                // 閉じるボタン
                ElevatedButton(
                  onPressed: () {
                    ref.read(deviceWarningProvider.notifier).state = false;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '了解しました',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// デバイス警告バナーを表示するラッパーウィジェット
class DeviceWarningWrapper extends ConsumerWidget {
  final Widget child;

  const DeviceWarningWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        child,
        const DeviceWarningBanner(),
      ],
    );
  }
}
