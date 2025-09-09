import '../models/ingredient.dart';
import 'firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IngredientService {
  static const String _collectionName = 'ingredients';

  // Get all active ingredients
  static Future<List<Ingredient>> getActiveIngredients() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .get();

      final ingredients = snapshot.docs
          .map((doc) => Ingredient.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort by name in the app to avoid index requirements
      ingredients.sort((a, b) => a.name.compareTo(b.name));
      return ingredients;
    } catch (e) {
      throw Exception('Failed to get active ingredients: $e');
    }
  }

  // Get ingredients by category
  static Future<List<Ingredient>> getIngredientsByCategory(String category) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();

      final ingredients = snapshot.docs
          .map((doc) => Ingredient.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort by name in the app to avoid index requirements
      ingredients.sort((a, b) => a.name.compareTo(b.name));
      return ingredients;
    } catch (e) {
      throw Exception('Failed to get ingredients by category: $e');
    }
  }

  // Get low stock ingredients
  static Future<List<Ingredient>> getLowStockIngredients() async {
    try {
      final allIngredients = await getActiveIngredients();
      return allIngredients.where((ingredient) => ingredient.isLowStock).toList();
    } catch (e) {
      throw Exception('Failed to get low stock ingredients: $e');
    }
  }

  // Get expiring ingredients
  static Future<List<Ingredient>> getExpiringIngredients() async {
    try {
      final allIngredients = await getActiveIngredients();
      return allIngredients.where((ingredient) => ingredient.isExpiringSoon || ingredient.isExpired).toList();
    } catch (e) {
      throw Exception('Failed to get expiring ingredients: $e');
    }
  }

  // Get single ingredient
  static Future<Ingredient?> getIngredient(String ingredientId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(ingredientId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Ingredient.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get ingredient: $e');
    }
  }

  // Create new ingredient
  static Future<String> createIngredient(Ingredient ingredient) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection(_collectionName)
          .add(ingredient.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create ingredient: $e');
    }
  }

  // Update ingredient
  static Future<void> updateIngredient(String ingredientId, Ingredient ingredient) async {
    try {
      await FirestoreService.updateDocument(
        collection: _collectionName,
        documentId: ingredientId,
        data: ingredient.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      throw Exception('Failed to update ingredient: $e');
    }
  }

  // Update stock quantity
  static Future<void> updateStock(String ingredientId, double newStock, {String? reason}) async {
    try {
      await FirestoreService.updateDocument(
        collection: _collectionName,
        documentId: ingredientId,
        data: {
          'currentStock': newStock,
          'lastRestocked': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // TODO: Log stock change for audit trail
      // await _logStockChange(ingredientId, newStock, reason);
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  // Adjust stock (add or subtract)
  static Future<void> adjustStock(String ingredientId, double adjustment, {String? reason}) async {
    try {
      final ingredient = await getIngredient(ingredientId);
      if (ingredient != null) {
        final newStock = ingredient.currentStock + adjustment;
        await updateStock(ingredientId, newStock.clamp(0, double.infinity), reason: reason);
      } else {
        throw Exception('Ingredient not found');
      }
    } catch (e) {
      throw Exception('Failed to adjust stock: $e');
    }
  }

  // Consume ingredients (used in production)
  static Future<bool> consumeIngredients(Map<String, double> ingredientConsumption) async {
    try {
      // Check if all ingredients have sufficient stock
      for (final entry in ingredientConsumption.entries) {
        final ingredient = await getIngredient(entry.key);
        if (ingredient == null || ingredient.currentStock < entry.value) {
          return false; // Insufficient stock
        }
      }

      // Consume the ingredients
      for (final entry in ingredientConsumption.entries) {
        await adjustStock(entry.key, -entry.value, reason: 'Production consumption');
      }

      return true;
    } catch (e) {
      throw Exception('Failed to consume ingredients: $e');
    }
  }

  // Search ingredients by name
  static Future<List<Ingredient>> searchIngredients(String query) async {
    try {
      final allIngredients = await getActiveIngredients();
      return allIngredients
          .where((ingredient) =>
              ingredient.name.toLowerCase().contains(query.toLowerCase()) ||
              ingredient.description.toLowerCase().contains(query.toLowerCase()) ||
              ingredient.category.toLowerCase().contains(query.toLowerCase()) ||
              ingredient.supplier.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search ingredients: $e');
    }
  }

  // Get ingredients statistics
  static Future<Map<String, dynamic>> getIngredientStats() async {
    try {
      final ingredients = await getActiveIngredients();
      
      final totalIngredients = ingredients.length;
      final lowStockIngredients = ingredients.where((ingredient) => ingredient.isLowStock).length;
      final outOfStockIngredients = ingredients.where((ingredient) => ingredient.isOutOfStock).length;
      final expiredIngredients = ingredients.where((ingredient) => ingredient.isExpired).length;
      final expiringSoonIngredients = ingredients.where((ingredient) => ingredient.isExpiringSoon).length;
      final totalValue = ingredients.fold<double>(0, (sum, ingredient) => sum + ingredient.totalValue);

      final categories = ingredients.map((ingredient) => ingredient.category).toSet().toList();
      final suppliers = ingredients.map((ingredient) => ingredient.supplier).toSet().toList();

      return {
        'totalIngredients': totalIngredients,
        'lowStockIngredients': lowStockIngredients,
        'outOfStockIngredients': outOfStockIngredients,
        'expiredIngredients': expiredIngredients,
        'expiringSoonIngredients': expiringSoonIngredients,
        'totalValue': totalValue,
        'categories': categories,
        'suppliers': suppliers,
      };
    } catch (e) {
      throw Exception('Failed to get ingredient statistics: $e');
    }
  }

  // Delete ingredient (soft delete)
  static Future<void> deleteIngredient(String ingredientId) async {
    try {
      await FirestoreService.updateDocument(
        collection: _collectionName,
        documentId: ingredientId,
        data: {
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      throw Exception('Failed to delete ingredient: $e');
    }
  }

  // Get ingredient categories
  static Future<List<String>> getIngredientCategories() async {
    try {
      final ingredients = await getActiveIngredients();
      return ingredients.map((ingredient) => ingredient.category).toSet().toList()..sort();
    } catch (e) {
      throw Exception('Failed to get ingredient categories: $e');
    }
  }

  // Get suppliers
  static Future<List<String>> getSuppliers() async {
    try {
      final ingredients = await getActiveIngredients();
      return ingredients.map((ingredient) => ingredient.supplier).toSet().toList()..sort();
    } catch (e) {
      throw Exception('Failed to get suppliers: $e');
    }
  }
}
