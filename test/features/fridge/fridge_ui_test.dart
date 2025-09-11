import 'package:barcode_scanner/features/home/presentation/pages/home_screen.dart';
import 'package:barcode_scanner/shared/models/product.dart';
import 'package:barcode_scanner/shared/providers/app_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('リスト⇄冷蔵庫の切替ができ、セクションタップで遷移する', (tester) async {
    final products = [
      Product(id: '1', name: '牛乳', category: '乳製品', expiryDate: DateTime.now().add(const Duration(days: 3))),
      Product(id: '2', name: 'にんじん', category: '野菜', expiryDate: DateTime.now().add(const Duration(days: 5))),
    ];

    final container = ProviderContainer(overrides: [
      appStateProvider.overrideWith((ref) => AppStateNotifier()..state = AppState(products: products)),
    ]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    // 初期はリスト
    expect(find.byKey(const ValueKey('listView')), findsOneWidget);

    // 冷蔵庫に切替
    await tester.tap(find.text('冷蔵庫'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('fridgeView')), findsOneWidget);

    // セクションタップ（冷蔵室 棚0）
    await tester.tap(find.textContaining('冷蔵室 棚0').first);
    await tester.pumpAndSettle();

    // セクションビュー（戻るボタンと件数表示あり）
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.textContaining('件'), findsOneWidget);
  });
}


