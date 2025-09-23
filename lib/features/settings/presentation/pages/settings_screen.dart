import 'package:flutter/material.dart';
import '../../../../shared/widgets/adaptive/adaptive_button.dart';
import '../../../../shared/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/adaptive/adaptive_scaffold.dart';
import '../../../../shared/widgets/dangerous_action_card.dart';
import '../../../../shared/widgets/data_clear_dialog.dart';
import 'category_management_screen.dart';

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
          const SizedBox(height: 8),

          // データ管理セクション
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'データ管理',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AdaptiveButton(
                    onPressed: () => _showDataExportDialog(context),
                    style: AdaptiveButtonStyle.primary,
                    child: const Text('データをエクスポート'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 危険な操作セクション
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.shade200,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.red.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '⚠️ 危険な操作',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '以下の操作は取り消すことができません。実行前に十分注意してください。',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                DangerousActionCard(
                  title: 'データを完全に削除',
                  description: 'すべてのデータを永続的に削除します',
                  icon: Icons.delete_forever,
                  onTap: () => _showImprovedDataClearDialog(context),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryManagementScreen(),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showCustomAdaptiveDialog(
      context: context,
      title: 'アプリについて',
      content: 'Edibuddy v1.0.0\n\n食べ物の相棒として、食材の賞味期限を管理し、食品ロスを削減するアプリです。',
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

  void _showImprovedDataClearDialog(BuildContext context) {
    // 実際のデータ数を取得（ここでは仮の値を使用）
    const productCount = 25;
    const historyCount = 150;
    const settingsCount = 5;

    showDialog(
      context: context,
      builder: (context) => DataClearDialog(
        productCount: productCount,
        historyCount: historyCount,
        settingsCount: settingsCount,
      ),
    );
  }

}
