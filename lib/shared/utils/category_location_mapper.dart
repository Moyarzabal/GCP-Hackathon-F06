import '../models/product.dart';

/// カテゴリに基づいて商品の配置場所を決定するユーティリティクラス
class CategoryLocationMapper {
  /// カテゴリから適切な冷蔵庫の区画を決定する
  static FridgeCompartment getCompartmentForCategory(String category) {
    switch (category.toLowerCase()) {
      case '野菜':
        return FridgeCompartment.vegetableDrawer;
      case '冷凍食品':
        return FridgeCompartment.freezer;
      case '飲料':
      case '食品':
      case '調味料':
      case 'その他':
      default:
        return FridgeCompartment.refrigerator;
    }
  }

  /// カテゴリに基づいてデフォルトのProductLocationを生成する
  static ProductLocation getDefaultLocationForCategory(String category) {
    final compartment = getCompartmentForCategory(category);

    // 冷蔵庫の場合は3段あるので、バランス良く配置するために段を決める
    // ここでは一旦すべて0段（最上段）にして、後でUI側で3段に分散表示する
    int level = 0;

    // 冷凍庫や野菜室は基本的に1段なので0のまま

    return ProductLocation(
      compartment: compartment,
      level: level,
    );
  }

  /// 区画の日本語名を取得する
  static String getCompartmentDisplayName(FridgeCompartment compartment) {
    switch (compartment) {
      case FridgeCompartment.refrigerator:
        return '冷蔵室';
      case FridgeCompartment.vegetableDrawer:
        return '野菜室';
      case FridgeCompartment.freezer:
        return '冷凍室';
      case FridgeCompartment.doorLeft:
        return '左ドア';
      case FridgeCompartment.doorRight:
        return '右ドア';
    }
  }

  /// 各区画に適したカテゴリのリストを取得する
  static List<String> getCategoriesForCompartment(FridgeCompartment compartment) {
    switch (compartment) {
      case FridgeCompartment.refrigerator:
        return ['飲料', '食品', '調味料', 'その他'];
      case FridgeCompartment.vegetableDrawer:
        return ['野菜'];
      case FridgeCompartment.freezer:
        return ['冷凍食品'];
      case FridgeCompartment.doorLeft:
      case FridgeCompartment.doorRight:
        return ['調味料', 'その他']; // ドアは調味料やその他の小物用
    }
  }
}