import 'package:flutter/material.dart';

class DataClearDialog extends StatefulWidget {
  final int productCount;
  final int historyCount;
  final int settingsCount;

  const DataClearDialog({
    Key? key,
    required this.productCount,
    required this.historyCount,
    required this.settingsCount,
  }) : super(key: key);

  @override
  State<DataClearDialog> createState() => _DataClearDialogState();
}

class _DataClearDialogState extends State<DataClearDialog> {
  String _selectedOption = 'all';
  bool _hasConfirmed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.red.shade300,
          width: 2,
        ),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: Colors.red.shade600,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(
            'データクリアの警告',
            style: TextStyle(
              color: Colors.red.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'この操作は取り消すことができません。',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // データの種類選択
            Text(
              '削除するデータを選択してください:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 8),

            _buildDataOption(
              value: 'all',
              title: 'すべてのデータを削除',
              description: '商品データ、履歴データ、設定データをすべて削除',
              count: widget.productCount + widget.historyCount + widget.settingsCount,
            ),
            _buildDataOption(
              value: 'products',
              title: '商品データのみ削除',
              description: '冷蔵庫内の商品データを削除',
              count: widget.productCount,
            ),
            _buildDataOption(
              value: 'history',
              title: '履歴データのみ削除',
              description: '過去の履歴データを削除',
              count: widget.historyCount,
            ),
            _buildDataOption(
              value: 'settings',
              title: '設定データのみ削除',
              description: 'アプリの設定データを削除',
              count: widget.settingsCount,
            ),

            const SizedBox(height: 16),

            // 最終確認チェックボックス
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _hasConfirmed,
                    onChanged: (value) {
                      setState(() {
                        _hasConfirmed = value ?? false;
                      });
                    },
                    activeColor: Colors.red.shade600,
                  ),
                  Expanded(
                    child: Text(
                      '上記の内容を理解し、データの削除を実行することを確認しました',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'キャンセル',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _hasConfirmed ? _confirmDelete : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade500,
          ),
          child: const Text(
            '削除実行',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildDataOption({
    required String value,
    required String title,
    required String description,
    required int count,
  }) {
    final isSelected = _selectedOption == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedOption = value;
            _hasConfirmed = false; // 選択変更時は確認をリセット
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.red.shade100 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.red.shade300 : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                groupValue: _selectedOption,
                onChanged: (newValue) {
                  setState(() {
                    _selectedOption = newValue!;
                    _hasConfirmed = false;
                  });
                },
                activeColor: Colors.red.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.red.shade800 : Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.red.shade600 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count件のデータ',
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? Colors.red.shade500 : Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    // 最終確認ダイアログを表示
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red.shade700,
              size: 32,
            ),
            const SizedBox(width: 8),
            Text(
              '最終確認',
              style: TextStyle(
                color: Colors.red.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Column(
                children: [
                  Text(
                    '本当にデータを削除しますか？',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getSelectedDataDescription(),
                    style: TextStyle(
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'この操作は完全に取り消すことができません。',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'キャンセル',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // 確認ダイアログを閉じる
              Navigator.of(context).pop(); // メインダイアログを閉じる
              _executeDataClear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              '完全に削除する',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _getSelectedDataDescription() {
    switch (_selectedOption) {
      case 'all':
        return 'すべてのデータ (${widget.productCount + widget.historyCount + widget.settingsCount}件)';
      case 'products':
        return '商品データ (${widget.productCount}件)';
      case 'history':
        return '履歴データ (${widget.historyCount}件)';
      case 'settings':
        return '設定データ (${widget.settingsCount}件)';
      default:
        return 'データ';
    }
  }

  void _executeDataClear() {
    // TODO: 実際のデータクリア処理を実装
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_getSelectedDataDescription()}を削除しました'),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
