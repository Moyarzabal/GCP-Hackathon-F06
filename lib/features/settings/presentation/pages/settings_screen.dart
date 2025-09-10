import 'package:flutter/material.dart';
import '../../../../shared/widgets/adaptive/adaptive_button.dart';
import '../../../../shared/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/adaptive/adaptive_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: const AdaptiveAppBar(
        title: Text('設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: InkWell(
              onTap: () => _showNotificationSettings(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.blue),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '通知設定',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '賞味期限の通知を管理',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: InkWell(
              onTap: () => _showFamilySettings(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.family_restroom, color: Colors.green),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '家族共有',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '家族メンバーを管理',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: InkWell(
              onTap: () => _showCategorySettings(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.category, color: Colors.orange),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'カテゴリ管理',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '商品カテゴリをカスタマイズ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Card(
            child: InkWell(
              onTap: () => _showAboutDialog(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'アプリについて',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'バージョン 1.0.0',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                AdaptiveButton(
                  onPressed: () => _showDataExportDialog(context),
                  style: AdaptiveButtonStyle.primary,
                  child: const Text('データをエクスポート'),
                ),
                const SizedBox(height: 16),
                AdaptiveButton(
                  onPressed: () => _showDataClearDialog(context),
                  style: AdaptiveButtonStyle.outlined,
                  child: const Text('データをクリア'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showCustomAdaptiveDialog(
      context: context,
      title: '通知設定',
      content: '賞味期限の通知設定を変更します。',
      actions: [
        AdaptiveDialogAction(
          text: 'キャンセル',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AdaptiveDialogAction(
          text: '設定',
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  void _showFamilySettings(BuildContext context) {
    showCustomAdaptiveDialog(
      context: context,
      title: '家族共有',
      content: '家族メンバーの管理を行います。',
      actions: [
        AdaptiveDialogAction(
          text: 'キャンセル',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AdaptiveDialogAction(
          text: '管理',
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  void _showCategorySettings(BuildContext context) {
    showCustomAdaptiveDialog(
      context: context,
      title: 'カテゴリ管理',
      content: '商品カテゴリのカスタマイズを行います。',
      actions: [
        AdaptiveDialogAction(
          text: 'キャンセル',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AdaptiveDialogAction(
          text: '管理',
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showCustomAdaptiveDialog(
      context: context,
      title: 'アプリについて',
      content: '冷蔵庫管理AI v1.0.0\n\n食材の賞味期限を管理し、食品ロスを削減するアプリです。',
      actions: [
        AdaptiveDialogAction(
          text: 'OK',
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  void _showDataExportDialog(BuildContext context) {
    showCustomAdaptiveDialog(
      context: context,
      title: 'データエクスポート',
      content: 'すべてのデータをエクスポートしますか？',
      actions: [
        AdaptiveDialogAction(
          text: 'キャンセル',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AdaptiveDialogAction(
          text: 'エクスポート',
          isDefaultAction: true,
          onPressed: () {
            Navigator.of(context).pop();
            // エクスポート処理の実装
          },
        ),
      ],
    );
  }

  void _showDataClearDialog(BuildContext context) {
    showCustomAdaptiveDialog(
      context: context,
      title: 'データクリア',
      content: 'すべてのデータを削除しますか？この操作は取り消すことができません。',
      actions: [
        AdaptiveDialogAction(
          text: 'キャンセル',
          onPressed: () => Navigator.of(context).pop(),
        ),
        AdaptiveDialogAction(
          text: '削除',
          isDestructiveAction: true,
          onPressed: () {
            Navigator.of(context).pop();
            // データクリア処理の実装
          },
        ),
      ],
    );
  }
}