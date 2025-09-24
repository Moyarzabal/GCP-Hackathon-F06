import 'package:flutter_test/flutter_test.dart';
import '../../../lib/shared/utils/category_location_mapper.dart';
import '../../../lib/shared/models/product.dart';

void main() {
  group('CategoryLocationMapper', () {
    test('should map vegetable category to vegetable drawer', () {
      expect(
        CategoryLocationMapper.getCompartmentForCategory('野菜'),
        FridgeCompartment.vegetableDrawer,
      );
    });

    test('should map frozen food category to freezer', () {
      expect(
        CategoryLocationMapper.getCompartmentForCategory('冷凍食品'),
        FridgeCompartment.freezer,
      );
    });

    test('should map other categories to refrigerator', () {
      expect(
        CategoryLocationMapper.getCompartmentForCategory('飲料'),
        FridgeCompartment.refrigerator,
      );
      expect(
        CategoryLocationMapper.getCompartmentForCategory('食品'),
        FridgeCompartment.refrigerator,
      );
      expect(
        CategoryLocationMapper.getCompartmentForCategory('調味料'),
        FridgeCompartment.refrigerator,
      );
      expect(
        CategoryLocationMapper.getCompartmentForCategory('その他'),
        FridgeCompartment.refrigerator,
      );
    });

    test('should create default location for vegetable category', () {
      final location =
          CategoryLocationMapper.getDefaultLocationForCategory('野菜');
      expect(location.compartment, FridgeCompartment.vegetableDrawer);
      expect(location.level, 0);
    });

    test('should create default location for frozen food category', () {
      final location =
          CategoryLocationMapper.getDefaultLocationForCategory('冷凍食品');
      expect(location.compartment, FridgeCompartment.freezer);
      expect(location.level, 0);
    });

    test('should create default location for refrigerator categories', () {
      final location =
          CategoryLocationMapper.getDefaultLocationForCategory('飲料');
      expect(location.compartment, FridgeCompartment.refrigerator);
      expect(location.level, 0);
    });

    test('should get compartment display names in Japanese', () {
      expect(
        CategoryLocationMapper.getCompartmentDisplayName(
            FridgeCompartment.refrigerator),
        '冷蔵室',
      );
      expect(
        CategoryLocationMapper.getCompartmentDisplayName(
            FridgeCompartment.vegetableDrawer),
        '野菜室',
      );
      expect(
        CategoryLocationMapper.getCompartmentDisplayName(
            FridgeCompartment.freezer),
        '冷凍室',
      );
    });

    test('should return correct categories for each compartment', () {
      expect(
        CategoryLocationMapper.getCategoriesForCompartment(
            FridgeCompartment.vegetableDrawer),
        ['野菜'],
      );
      expect(
        CategoryLocationMapper.getCategoriesForCompartment(
            FridgeCompartment.freezer),
        ['冷凍食品'],
      );
      expect(
        CategoryLocationMapper.getCategoriesForCompartment(
            FridgeCompartment.refrigerator),
        ['飲料', '食品', '調味料', 'その他'],
      );
    });
  });
}
