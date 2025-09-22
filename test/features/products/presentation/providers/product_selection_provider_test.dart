import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barcode_scanner/features/products/presentation/providers/product_selection_provider.dart';

void main() {
  group('ProductSelectionNotifier', () {
    late ProviderContainer container;
    late ProductSelectionNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(productSelectionProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with default state', () {
      // Act
      final state = container.read(productSelectionProvider);
      
      // Assert
      expect(state.isSelectionMode, false);
      expect(state.selectedProductIds, isEmpty);
      expect(state.isDeleting, false);
      expect(state.error, isNull);
    });

    group('toggleSelectionMode', () {
      test('should enter selection mode when currently not in selection mode', () {
        // Arrange
        expect(notifier.state.isSelectionMode, false);
        
        // Act
        notifier.toggleSelectionMode();
        
        // Assert
        expect(notifier.state.isSelectionMode, true);
        expect(notifier.state.selectedProductIds, isEmpty);
      });

      test('should exit selection mode when currently in selection mode', () {
        // Arrange
        notifier.toggleSelectionMode();
        expect(notifier.state.isSelectionMode, true);
        
        // Act
        notifier.toggleSelectionMode();
        
        // Assert
        expect(notifier.state.isSelectionMode, false);
        expect(notifier.state.selectedProductIds, isEmpty);
      });

      test('should clear selection when exiting selection mode', () {
        // Arrange
        notifier.toggleSelectionMode();
        notifier.toggleProductSelection('product1');
        notifier.toggleProductSelection('product2');
        expect(notifier.state.selectedProductIds, {'product1', 'product2'});
        
        // Act
        notifier.toggleSelectionMode();
        
        // Assert
        expect(notifier.state.isSelectionMode, false);
        expect(notifier.state.selectedProductIds, isEmpty);
      });
    });

    group('toggleProductSelection', () {
      test('should add product to selection when not selected', () {
        // Arrange
        notifier.toggleSelectionMode();
        expect(notifier.state.selectedProductIds, isEmpty);
        
        // Act
        notifier.toggleProductSelection('product1');
        
        // Assert
        expect(notifier.state.selectedProductIds, {'product1'});
      });

      test('should remove product from selection when already selected', () {
        // Arrange
        notifier.toggleSelectionMode();
        notifier.toggleProductSelection('product1');
        expect(notifier.state.selectedProductIds, {'product1'});
        
        // Act
        notifier.toggleProductSelection('product1');
        
        // Assert
        expect(notifier.state.selectedProductIds, isEmpty);
      });

      test('should handle multiple products', () {
        // Arrange
        notifier.toggleSelectionMode();
        
        // Act
        notifier.toggleProductSelection('product1');
        notifier.toggleProductSelection('product2');
        notifier.toggleProductSelection('product3');
        
        // Assert
        expect(notifier.state.selectedProductIds, {'product1', 'product2', 'product3'});
      });

      test('should not add product when not in selection mode', () {
        // Arrange
        expect(notifier.state.isSelectionMode, false);
        
        // Act
        notifier.toggleProductSelection('product1');
        
        // Assert
        expect(notifier.state.selectedProductIds, isEmpty);
      });
    });

    group('selectAll', () {
      test('should select all products when in selection mode', () {
        // Arrange
        notifier.toggleSelectionMode();
        const productIds = ['product1', 'product2', 'product3'];
        
        // Act
        notifier.selectAll(productIds);
        
        // Assert
        expect(notifier.state.selectedProductIds, productIds.toSet());
      });

      test('should not select products when not in selection mode', () {
        // Arrange
        expect(notifier.state.isSelectionMode, false);
        const productIds = ['product1', 'product2', 'product3'];
        
        // Act
        notifier.selectAll(productIds);
        
        // Assert
        expect(notifier.state.selectedProductIds, isEmpty);
      });

      test('should handle empty product list', () {
        // Arrange
        notifier.toggleSelectionMode();
        
        // Act
        notifier.selectAll([]);
        
        // Assert
        expect(notifier.state.selectedProductIds, isEmpty);
      });
    });

    group('clearSelection', () {
      test('should clear all selected products', () {
        // Arrange
        notifier.toggleSelectionMode();
        notifier.toggleProductSelection('product1');
        notifier.toggleProductSelection('product2');
        expect(notifier.state.selectedProductIds, {'product1', 'product2'});
        
        // Act
        notifier.clearSelection();
        
        // Assert
        expect(notifier.state.selectedProductIds, isEmpty);
      });

      test('should clear selection even when not in selection mode', () {
        // Arrange
        notifier.toggleSelectionMode();
        notifier.toggleProductSelection('product1');
        notifier.toggleSelectionMode(); // Exit selection mode
        expect(notifier.state.isSelectionMode, false);
        expect(notifier.state.selectedProductIds, isEmpty);
        
        // Act
        notifier.clearSelection();
        
        // Assert
        expect(notifier.state.selectedProductIds, isEmpty);
      });
    });

    group('clearError', () {
      test('should clear error message', () {
        // Arrange
        notifier.setError('Test error');
        expect(notifier.state.error, 'Test error');
        
        // Act
        notifier.clearError();
        
        // Assert
        expect(notifier.state.error, isNull);
      });

      test('should not affect other state properties', () {
        // Arrange
        notifier.toggleSelectionMode();
        notifier.toggleProductSelection('product1');
        notifier.setDeleting(true);
        notifier.setError('Test error');
        
        // Act
        notifier.clearError();
        
        // Assert
        expect(notifier.state.error, isNull);
        expect(notifier.state.isSelectionMode, true);
        expect(notifier.state.selectedProductIds, {'product1'});
        expect(notifier.state.isDeleting, true);
      });
    });

    group('setDeleting', () {
      test('should set deleting state to true', () {
        // Arrange
        expect(notifier.state.isDeleting, false);
        
        // Act
        notifier.setDeleting(true);
        
        // Assert
        expect(notifier.state.isDeleting, true);
      });

      test('should set deleting state to false', () {
        // Arrange
        notifier.setDeleting(true);
        expect(notifier.state.isDeleting, true);
        
        // Act
        notifier.setDeleting(false);
        
        // Assert
        expect(notifier.state.isDeleting, false);
      });
    });

    group('setError', () {
      test('should set error message', () {
        // Arrange
        expect(notifier.state.error, isNull);
        
        // Act
        notifier.setError('Test error message');
        
        // Assert
        expect(notifier.state.error, 'Test error message');
      });

      test('should overwrite existing error message', () {
        // Arrange
        notifier.setError('First error');
        expect(notifier.state.error, 'First error');
        
        // Act
        notifier.setError('Second error');
        
        // Assert
        expect(notifier.state.error, 'Second error');
      });
    });
  });
}
