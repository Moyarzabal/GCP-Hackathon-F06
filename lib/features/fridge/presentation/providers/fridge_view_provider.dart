import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product.dart' show FridgeCompartment;
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
  FridgeViewNotifier() : super(const FridgeViewState());

  void selectSection(SelectedFridgeSection section) {
    state = FridgeViewState(selectedSection: section);
  }

  void clearSelection() {
    state = const FridgeViewState();
  }
}

final fridgeViewProvider =
    StateNotifierProvider<FridgeViewNotifier, FridgeViewState>((ref) {
  return FridgeViewNotifier();
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
