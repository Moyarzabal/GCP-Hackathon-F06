import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/models/product.dart'
    show ProductLocation, FridgeCompartment;
import '../../../../shared/providers/app_state_provider.dart';

/// 冷蔵庫内の選択セクション
class SelectedFridgeSection {
  final FridgeCompartment compartment;
  final int level; // 0 = 最上段

  const SelectedFridgeSection({
    required this.compartment,
    required this.level,
  });
}

class FridgeViewState {
  final SelectedFridgeSection? selectedSection;

  const FridgeViewState({
    this.selectedSection,
  });
}

class FridgeViewNotifier extends StateNotifier<FridgeViewState> {
  final Ref _ref;
  FridgeViewNotifier(this._ref) : super(const FridgeViewState());

  void selectSection(SelectedFridgeSection section) {
    state = FridgeViewState(selectedSection: section);
  }

  void clearSelection() {
    state = const FridgeViewState();
  }

  /// 選択中セクションの商品一覧を返す（Phase1: メモリ内）
  List<Product> getProductsForSelectedSection() {
    final all = _ref.read(productsProvider);
    final section = state.selectedSection;
    if (section == null) return all;
    return all.where((p) {
      final loc = p.location;
      if (loc == null) {
        // 位置未設定のプロダクトは冷蔵室 level 0 とみなす（初期互換）
        return section.compartment == FridgeCompartment.refrigerator &&
            section.level == 0;
      }
      return loc.compartment == section.compartment &&
          loc.level == section.level;
    }).toList();
  }
}

final fridgeViewProvider =
    StateNotifierProvider<FridgeViewNotifier, FridgeViewState>((ref) {
  return FridgeViewNotifier(ref);
});

/// セクション別の件数を計算する派生プロバイダ
final sectionCountsProvider = Provider<Map<String, int>>((ref) {
  final all = ref.watch(productsProvider);
  final Map<String, int> counts = {};
  void inc(FridgeCompartment c, int level) {
    final key = '${c.name}:$level';
    counts[key] = (counts[key] ?? 0) + 1;
  }

  for (final p in all) {
    final loc = p.location;
    if (loc == null) {
      inc(FridgeCompartment.refrigerator, 0);
    } else {
      inc(loc.compartment, loc.level);
    }
  }
  return counts;
});
