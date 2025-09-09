import '../models/product_inventory.dart';
import 'firestore_service.dart';
import 'ingredient_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductInventoryService {
  static const String _collectionName = 'productInventory';

  // Get all active products
  static Future<List<ProductInventory>> getActiveProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .get();

      final products = snapshot.docs
          .map((doc) => ProductInventory.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort by name in the app to avoid index requirements
      products.sort((a, b) => a.name.compareTo(b.name));
      return products;
    } catch (e) {
      throw Exception('Failed to get active products: $e');
    }
  }

  // Get products by category
  static Future<List<ProductInventory>> getProductsByCategory(String category) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();

      final products = snapshot.docs
          .map((doc) => ProductInventory.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort by name in the app to avoid index requirements
      products.sort((a, b) => a.name.compareTo(b.name));
      return products;
    } catch (e) {
      throw Exception('Failed to get products by category: $e');
    }
  }

  // Get low stock products
  static Future<List<ProductInventory>> getLowStockProducts() async {
    try {
      final allProducts = await getActiveProducts();
      return allProducts.where((product) => product.isLowStock).toList();
    } catch (e) {
      throw Exception('Failed to get low stock products: $e');
    }
  }

  // Get expiring products
  static Future<List<ProductInventory>> getExpiringProducts() async {
    try {
      final allProducts = await getActiveProducts();
      return allProducts.where((product) => product.isExpiringSoon || product.isExpired).toList();
    } catch (e) {
      throw Exception('Failed to get expiring products: $e');
    }
  }

  // Get products that can be produced (based on ingredient availability)
  static Future<List<ProductInventory>> getProducibleProducts() async {
    try {
      final products = await getActiveProducts();
      final producibleProducts = <ProductInventory>[];

      for (final product in products) {
        if (await canProduceProduct(product.id, 1)) {
          producibleProducts.add(product);
        }
      }

      return producibleProducts;
    } catch (e) {
      throw Exception('Failed to get producible products: $e');
    }
  }

  // Check if a product can be produced
  static Future<bool> canProduceProduct(String productId, int quantity) async {
    try {
      final product = await getProduct(productId);
      if (product == null || product.recipe.isEmpty) return false;

      // Check ingredient availability
      for (final recipeIngredient in product.recipe) {
        final ingredient = await IngredientService.getIngredient(recipeIngredient.ingredientId);
        if (ingredient == null) return false;
        
        final requiredQuantity = recipeIngredient.quantity * quantity;
        if (ingredient.currentStock < requiredQuantity) return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get single product
  static Future<ProductInventory?> getProduct(String productId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(productId)
          .get();

      if (doc.exists && doc.data() != null) {
        return ProductInventory.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  // Create new product
  static Future<String> createProduct(ProductInventory product) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection(_collectionName)
          .add(product.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  // Update product
  static Future<void> updateProduct(String productId, ProductInventory product) async {
    try {
      await FirestoreService.updateDocument(
        collection: _collectionName,
        documentId: productId,
        data: product.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Update stock quantity
  static Future<void> updateStock(String productId, double newStock, {String? reason}) async {
    try {
      await FirestoreService.updateDocument(
        collection: _collectionName,
        documentId: productId,
        data: {
          'currentStock': newStock,
          'lastProduced': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // TODO: Log stock change for audit trail
      // await _logStockChange(productId, newStock, reason);
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  // Adjust stock (add or subtract)
  static Future<void> adjustStock(String productId, double adjustment, {String? reason}) async {
    try {
      final product = await getProduct(productId);
      if (product != null) {
        final newStock = product.currentStock + adjustment;
        await updateStock(productId, newStock.clamp(0, double.infinity), reason: reason);
      } else {
        throw Exception('Product not found');
      }
    } catch (e) {
      throw Exception('Failed to adjust stock: $e');
    }
  }

  // Produce product (consumes ingredients and adds to product stock)
  static Future<bool> produceProduct(String productId, int quantity, {String? reason}) async {
    try {
      final product = await getProduct(productId);
      if (product == null) return false;

      // Check if can produce
      if (!await canProduceProduct(productId, quantity)) return false;

      // Calculate ingredient consumption
      final ingredientConsumption = <String, double>{};
      for (final recipeIngredient in product.recipe) {
        ingredientConsumption[recipeIngredient.ingredientId] = 
            recipeIngredient.quantity * quantity;
      }

      // Consume ingredients
      final success = await IngredientService.consumeIngredients(ingredientConsumption);
      if (!success) return false;

      // Add to product stock
      await adjustStock(productId, quantity.toDouble(), reason: reason ?? 'Production');

      return true;
    } catch (e) {
      throw Exception('Failed to produce product: $e');
    }
  }

  // Sell product (reduces stock)
  static Future<bool> sellProduct(String productId, int quantity) async {
    try {
      final product = await getProduct(productId);
      if (product == null || product.currentStock < quantity) return false;

      await adjustStock(productId, -quantity.toDouble(), reason: 'Sale');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Search products by name
  static Future<List<ProductInventory>> searchProducts(String query) async {
    try {
      final allProducts = await getActiveProducts();
      return allProducts
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.description.toLowerCase().contains(query.toLowerCase()) ||
              product.category.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // Get product statistics
  static Future<Map<String, dynamic>> getProductStats() async {
    try {
      final products = await getActiveProducts();
      
      final totalProducts = products.length;
      final lowStockProducts = products.where((product) => product.isLowStock).length;
      final outOfStockProducts = products.where((product) => product.isOutOfStock).length;
      final expiredProducts = products.where((product) => product.isExpired).length;
      final expiringSoonProducts = products.where((product) => product.isExpiringSoon).length;
      final totalValue = products.fold<double>(0, (sum, product) => sum + product.totalValue);
      final totalProductionCost = products.fold<double>(0, (sum, product) => sum + (product.productionCost * product.currentStock));

      final categories = products.map((product) => product.category).toSet().toList();

      return {
        'totalProducts': totalProducts,
        'lowStockProducts': lowStockProducts,
        'outOfStockProducts': outOfStockProducts,
        'expiredProducts': expiredProducts,
        'expiringSoonProducts': expiringSoonProducts,
        'totalValue': totalValue,
        'totalProductionCost': totalProductionCost,
        'profitPotential': totalValue - totalProductionCost,
        'categories': categories,
      };
    } catch (e) {
      throw Exception('Failed to get product statistics: $e');
    }
  }

  // Delete product (soft delete)
  static Future<void> deleteProduct(String productId) async {
    try {
      await FirestoreService.updateDocument(
        collection: _collectionName,
        documentId: productId,
        data: {
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Get product categories
  static Future<List<String>> getProductCategories() async {
    try {
      final products = await getActiveProducts();
      return products.map((product) => product.category).toSet().toList()..sort();
    } catch (e) {
      throw Exception('Failed to get product categories: $e');
    }
  }

  // Calculate production cost for a product based on current ingredient prices
  static Future<double> calculateProductionCost(String productId) async {
    try {
      final product = await getProduct(productId);
      if (product == null) return 0.0;

      double totalCost = 0.0;
      for (final recipeIngredient in product.recipe) {
        final ingredient = await IngredientService.getIngredient(recipeIngredient.ingredientId);
        if (ingredient != null) {
          totalCost += ingredient.unitCost * recipeIngredient.quantity;
        }
      }

      return totalCost;
    } catch (e) {
      return 0.0;
    }
  }

  // Get production recommendations
  static Future<List<ProductInventory>> getProductionRecommendations() async {
    try {
      final products = await getActiveProducts();
      final recommendations = <ProductInventory>[];

      for (final product in products) {
        // Recommend production if:
        // 1. Product is low on stock
        // 2. Product can be produced
        // 3. Product is available for sale
        if (product.isLowStock && 
            product.isAvailable && 
            await canProduceProduct(product.id, 1)) {
          recommendations.add(product);
        }
      }

      // Sort by priority (lowest stock percentage first)
      recommendations.sort((a, b) => a.stockPercentage.compareTo(b.stockPercentage));
      return recommendations;
    } catch (e) {
      throw Exception('Failed to get production recommendations: $e');
    }
  }

  // Validate stock availability for cart items
  static Future<Map<String, dynamic>> validateStockForOrder(List<dynamic> cartItems) async {
    try {
      final Map<String, dynamic> result = {
        'isValid': true,
        'errors': <String>[],
        'unavailableItems': <Map<String, dynamic>>[],
      };

      for (final item in cartItems) {
        final productId = item.productId;
        final requestedQuantity = item.quantity;
        
        final product = await getProduct(productId);
        if (product == null) {
          result['isValid'] = false;
          result['errors'].add('Product "${item.productName}" not found');
          result['unavailableItems'].add({
            'productId': productId,
            'productName': item.productName,
            'requestedQuantity': requestedQuantity,
            'availableStock': 0,
            'error': 'Product not found'
          });
          continue;
        }

        if (!product.isActive || !product.isAvailable) {
          result['isValid'] = false;
          result['errors'].add('Product "${product.name}" is not available for sale');
          result['unavailableItems'].add({
            'productId': productId,
            'productName': product.name,
            'requestedQuantity': requestedQuantity,
            'availableStock': product.currentStock.toInt(),
            'error': 'Product not available'
          });
          continue;
        }

        if (product.currentStock < requestedQuantity) {
          result['isValid'] = false;
          result['errors'].add('Insufficient stock for "${product.name}". Available: ${product.currentStock.toInt()}, Requested: $requestedQuantity');
          result['unavailableItems'].add({
            'productId': productId,
            'productName': product.name,
            'requestedQuantity': requestedQuantity,
            'availableStock': product.currentStock.toInt(),
            'error': 'Insufficient stock'
          });
        }
      }

      return result;
    } catch (e) {
      throw Exception('Failed to validate stock for order: $e');
    }
  }

  // Process order and decrement stock
  static Future<bool> processOrderStock(List<dynamic> cartItems, {String? reason}) async {
    try {
      // First validate stock availability
      final validation = await validateStockForOrder(cartItems);
      if (!validation['isValid']) {
        throw Exception('Stock validation failed: ${validation['errors'].join(', ')}');
      }

      // Process each item and decrement stock
      for (final item in cartItems) {
        final productId = item.productId;
        final quantity = item.quantity;
        
        final product = await getProduct(productId);
        if (product != null) {
          final newStock = product.currentStock - quantity;
          await updateStock(
            productId, 
            newStock.clamp(0, double.infinity), 
            reason: reason ?? 'Order processed'
          );
        }
      }

      return true;
    } catch (e) {
      throw Exception('Failed to process order stock: $e');
    }
  }

  // Restore stock when order is cancelled
  static Future<bool> restoreOrderStock(List<dynamic> cartItems, {String? reason}) async {
    try {
      // Process each item and restore stock
      for (final item in cartItems) {
        final productId = item.productId;
        final quantity = item.quantity;
        
        final product = await getProduct(productId);
        if (product != null) {
          final newStock = product.currentStock + quantity;
          await updateStock(
            productId, 
            newStock, 
            reason: reason ?? 'Order cancelled - stock restored'
          );
        }
      }

      return true;
    } catch (e) {
      throw Exception('Failed to restore order stock: $e');
    }
  }

  // Check single product stock availability
  static Future<bool> checkStockAvailability(String productId, int quantity) async {
    try {
      final product = await getProduct(productId);
      if (product == null) return false;
      
      return product.isActive && 
             product.isAvailable && 
             product.currentStock >= quantity;
    } catch (e) {
      return false;
    }
  }
}
