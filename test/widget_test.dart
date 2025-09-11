// Basic widget test placeholder - disabled for now
// Will be implemented after main UI components are ready

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barcode_scanner/app.dart';

void main() {
  testWidgets('Realistic fridge doors and drawers toggle', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // 冷蔵庫ビューへ切替
    await tester.tap(find.text('冷蔵庫'));
    await tester.pumpAndSettle();

    // ドア存在
    final leftDoor = find.bySemanticsLabel('左ドア');
    final rightDoor = find.bySemanticsLabel('右ドア');
    expect(leftDoor, findsOneWidget);
    expect(rightDoor, findsOneWidget);

    // タップでアニメする
    await tester.tap(leftDoor);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(rightDoor);
    await tester.pump(const Duration(milliseconds: 300));

    // 引き出し存在
    final vegetable = find.bySemanticsLabel('野菜室');
    final freezer = find.bySemanticsLabel('冷凍庫');
    expect(vegetable, findsOneWidget);
    expect(freezer, findsOneWidget);

    // 引き出しタップ
    await tester.tap(vegetable);
    await tester.pump(const Duration(milliseconds: 260));
    await tester.tap(freezer);
    await tester.pump(const Duration(milliseconds: 260));
  });
}
