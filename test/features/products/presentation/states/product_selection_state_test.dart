import 'package:flutter_test/flutter_test.dart';
import 'package:barcode_scanner/features/products/presentation/states/product_selection_state.dart';

void main() {
  group('ProductSelectionState', () {
    test('should initialize with default values', () {
      // Arrange & Act
      const state = ProductSelectionState();
      
      // Assert
      expect(state.isSelectionMode, false);
      expect(state.selectedProductIds, isEmpty);
      expect(state.isDeleting, false);
      expect(state.error, isNull);
    });

    test('should create copy with updated values', () {
      // Arrange
      const initialState = ProductSelectionState();
      
      // Act
      final updatedState = initialState.copyWith(
        isSelectionMode: true,
        selectedProductIds: {'product1', 'product2'},
        isDeleting: true,
        error: 'Test error',
      );
      
      // Assert
      expect(updatedState.isSelectionMode, true);
      expect(updatedState.selectedProductIds, {'product1', 'product2'});
      expect(updatedState.isDeleting, true);
      expect(updatedState.error, 'Test error');
    });

      test('should preserve original values when not specified in copyWith', () {
        // Arrange
        const initialState = ProductSelectionState(
          isSelectionMode: true,
          selectedProductIds: {'product1'},
          isDeleting: true,
          error: 'Original error',
        );
        
        // Act
        final updatedState = initialState.copyWith(
          isSelectionMode: false,
          // Other values not specified
        );
        
        // Assert
        expect(updatedState.isSelectionMode, false);
        expect(updatedState.selectedProductIds, {'product1'}); // Preserved
        expect(updatedState.isDeleting, true); // Preserved
        expect(updatedState.error, isNull); // Error is cleared when not specified
      });

    test('should check if product is selected', () {
      // Arrange
      const state = ProductSelectionState(
        selectedProductIds: {'product1', 'product2'},
      );
      
      // Act & Assert
      expect(state.isSelected('product1'), true);
      expect(state.isSelected('product2'), true);
      expect(state.isSelected('product3'), false);
    });

    test('should return selected count', () {
      // Arrange
      const state = ProductSelectionState(
        selectedProductIds: {'product1', 'product2', 'product3'},
      );
      
      // Act & Assert
      expect(state.selectedCount, 3);
    });

    test('should return 0 for selected count when no products selected', () {
      // Arrange
      const state = ProductSelectionState();
      
      // Act & Assert
      expect(state.selectedCount, 0);
    });

    test('should handle empty selected products set', () {
      // Arrange
      const state = ProductSelectionState(selectedProductIds: {});
      
      // Act & Assert
      expect(state.selectedProductIds, isEmpty);
      expect(state.selectedCount, 0);
      expect(state.isSelected('any_product'), false);
    });

    test('should handle null error', () {
      // Arrange
      const state = ProductSelectionState(error: null);
      
      // Act & Assert
      expect(state.error, isNull);
    });

    test('should handle non-null error', () {
      // Arrange
      const state = ProductSelectionState(error: 'Test error message');
      
      // Act & Assert
      expect(state.error, 'Test error message');
    });
  });
}
