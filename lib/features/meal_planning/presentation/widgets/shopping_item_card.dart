import 'package:flutter/material.dart';
import '../../../../shared/models/shopping_item.dart';

class ShoppingItemCard extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ShoppingItemCard({
    Key? key,
    required this.item,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: item.isCompleted
            ? BorderSide(color: Colors.green.withOpacity(0.3))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: item.isCompleted
                ? Colors.green.withOpacity(0.05)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              // チェックボックス
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.isCompleted ? Colors.green : Colors.grey,
                      width: 2,
                    ),
                    color: item.isCompleted ? Colors.green : Colors.transparent,
                  ),
                  child: item.isCompleted
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ),

              const SizedBox(width: 12),

              // アイテム情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // アイテム名と数量
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              decoration: item.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: item.isCompleted
                                  ? Colors.grey[600]
                                  : null,
                            ),
                          ),
                        ),
                        if (item.isCustom)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'カスタム',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // 数量とカテゴリ
                    Row(
                      children: [
                        Text(
                          item.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: item.categoryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.categoryIcon,
                                size: 12,
                                color: item.categoryColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                item.category,
                                style: TextStyle(
                                  color: item.categoryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // メモ
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.notes,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // 価格情報
                    if (item.estimatedPrice != null && item.estimatedPrice! > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '予想価格: ¥${item.estimatedPrice!.toInt()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // アクションボタン
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      iconSize: 20,
                      color: Colors.grey[600],
                      tooltip: '編集',
                    ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete),
                      iconSize: 20,
                      color: Colors.red[400],
                      tooltip: '削除',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

