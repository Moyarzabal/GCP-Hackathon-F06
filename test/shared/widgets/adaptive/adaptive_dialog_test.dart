import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:barcode_scanner/shared/widgets/adaptive/adaptive_dialog.dart';

void main() {
  group('AdaptiveDialog', () {
    const testTitle = 'テストダイアログ';
    const testContent = 'これはテスト用のダイアログです。';

    testWidgets('should display dialog with title and content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showCustomAdaptiveDialog(
                    context: context,
                    title: testTitle,
                    content: testContent,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // ダイアログが表示されることを確認
      expect(find.text(testTitle), findsOneWidget);
      expect(find.text(testContent), findsOneWidget);
    });

    testWidgets('should display dialog with custom actions',
        (WidgetTester tester) async {
      bool confirmPressed = false;
      bool cancelPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showCustomAdaptiveDialog(
                    context: context,
                    title: testTitle,
                    content: testContent,
                    actions: [
                      AdaptiveDialogAction(
                        text: 'キャンセル',
                        onPressed: () {
                          cancelPressed = true;
                          Navigator.of(context).pop();
                        },
                      ),
                      AdaptiveDialogAction(
                        text: '確認',
                        isDefaultAction: true,
                        onPressed: () {
                          confirmPressed = true;
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // ダイアログが表示されることを確認
      expect(find.text(testTitle), findsOneWidget);
      expect(find.text(testContent), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('確認'), findsOneWidget);

      // 確認ボタンをタップ
      await tester.tap(find.text('確認'));
      await tester.pumpAndSettle();

      expect(confirmPressed, isTrue);
      expect(cancelPressed, isFalse);
    });

    testWidgets('should display dialog with destructive action',
        (WidgetTester tester) async {
      bool deletePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showCustomAdaptiveDialog(
                    context: context,
                    title: '削除確認',
                    content: 'この項目を削除しますか？',
                    actions: [
                      AdaptiveDialogAction(
                        text: 'キャンセル',
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      AdaptiveDialogAction(
                        text: '削除',
                        isDestructiveAction: true,
                        onPressed: () {
                          deletePressed = true;
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // ダイアログが表示されることを確認
      expect(find.text('削除確認'), findsOneWidget);
      expect(find.text('この項目を削除しますか？'), findsOneWidget);
      expect(find.text('削除'), findsOneWidget);

      // 削除ボタンをタップ
      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      expect(deletePressed, isTrue);
    });

    testWidgets('should display simple dialog without actions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showCustomAdaptiveDialog(
                    context: context,
                    title: testTitle,
                    content: testContent,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // ダイアログが表示されることを確認
      expect(find.text(testTitle), findsOneWidget);
      expect(find.text(testContent), findsOneWidget);
    });

    testWidgets('should handle dialog dismissal', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showCustomAdaptiveDialog(
                    context: context,
                    title: testTitle,
                    content: testContent,
                    actions: [
                      AdaptiveDialogAction(
                        text: 'OK',
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // ダイアログを表示
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // ダイアログが表示されることを確認
      expect(find.text(testTitle), findsOneWidget);

      // OKボタンをタップしてダイアログを閉じる
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // ダイアログが閉じられたことを確認
      expect(find.text(testTitle), findsNothing);
    });
  });
}
