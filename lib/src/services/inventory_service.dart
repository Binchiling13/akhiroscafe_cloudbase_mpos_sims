import '../models/inventory_item.dart';
import 'firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryService {
  static const String _collectionName = 'inventory';

  // Get all active inventory items
  static Future<List<InventoryItem>> getActiveItems() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .get();

      final items = snapshot.docs
          .map((doc) => InventoryItem.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort by name in the app to avoid index requirements
      items.sort((a, b) => a.name.compareTo(b.name));
      return items;
    } catch (e) {
      throw Exception('Failed to get active inventory items: $e');
    }
  }

  // Get items by category
  static Future<List<InventoryItem>> getItemsByCategory(String category) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();

      final items = snapshot.docs
          .map((doc) => InventoryItem.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort by name in the app to avoid index requirements
      items.sort((a, b) => a.name.compareTo(b.name));
      return items;
    } catch (e) {
      throw Exception('Failed to get items by category: $e');
    }
  }

  // Get low stock items
  static Future<List<InventoryItem>> getLowStockItems() async {
    try {
      final allItems = await getActiveItems();
      return allItems.where((item) => item.isLowStock).toList();
    } catch (e) {
      throw Exception('Failed to get low stock items: $e');
    }
  }

  // Get expiring items
  static Future<List<InventoryItem>> getExpiringItems() async {
    try {
      final allItems = await getActiveItems();
      return allItems.where((item) => item.isExpiringSoon || item.isExpired).toList();
    } catch (e) {
      throw Exception('Failed to get expiring items: $e');
    }
  }

  // Get single inventory item
  static Future<InventoryItem?> getInventoryItem(String itemId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_collectionName)
          .doc(itemId)
          .get();

      if (doc.exists && doc.data() != null) {
        return InventoryItem.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get inventory item: $e');
    }
  }

  // Update stock quantity
  static Future<void> updateStock(String itemId, double newStock, {String? reason}) async {
    try {
      await FirestoreService.updateDocument(
        collection: _collectionName,
        documentId: itemId,
        data: {
          'currentStock': newStock,
          'lastRestocked': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // TODO: Log stock change for audit trail
      // await _logStockChange(itemId, newStock, reason);
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  // Adjust stock (add or subtract)
  static Future<void> adjustStock(String itemId, double adjustment, {String? reason}) async {
    try {
      final item = await getInventoryItem(itemId);
      if (item == null) {
        throw Exception('Item not found');
      }

      final newStock = item.currentStock + adjustment;
      if (newStock < 0) {
        throw Exception('Stock cannot be negative');
      }

      await updateStock(itemId, newStock, reason: reason);
    } catch (e) {
      throw Exception('Failed to adjust stock: $e');
    }
  }

  // Search items by name
  static Future<List<InventoryItem>> searchItems(String query) async {
    try {
      final allItems = await getActiveItems();
      return allItems
          .where((item) =>
              item.name.toLowerCase().contains(query.toLowerCase()) ||
              item.description.toLowerCase().contains(query.toLowerCase()) ||
              item.category.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search items: $e');
    }
  }

  // Get inventory statistics
  static Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      final items = await getActiveItems();
      
      final totalItems = items.length;
      final lowStockItems = items.where((item) => item.isLowStock).length;
      final expiredItems = items.where((item) => item.isExpired).length;
      final expiringSoonItems = items.where((item) => item.isExpiringSoon).length;
      final totalValue = items.fold<double>(0, (sum, item) => sum + item.totalValue);

      final categories = items.map((item) => item.category).toSet().toList();

      return {
        'totalItems': totalItems,
        'lowStockItems': lowStockItems,
        'expiredItems': expiredItems,
        'expiringSoonItems': expiringSoonItems,
        'totalValue': totalValue,
        'categories': categories,
      };
    } catch (e) {
      throw Exception('Failed to get inventory statistics: $e');
    }
  }

  // Create inventory item
  static Future<String> createInventoryItem(InventoryItem item) async {
    try {
      final itemWithTimestamp = item.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      return await FirestoreService.addDocument(
        collection: _collectionName,
        data: itemWithTimestamp.toMap(),
      );
    } catch (e) {
      throw Exception('Failed to create inventory item: $e');
    }
  }

  // Update inventory item
  static Future<void> updateInventoryItem(String itemId, InventoryItem item) async {
    try {
      final updatedItem = item.copyWith(
        updatedAt: DateTime.now(),
      );
      
      await FirestoreService.updateDocument(
        collection: _collectionName,
        documentId: itemId,
        data: updatedItem.toMap(),
      );
    } catch (e) {
      throw Exception('Failed to update inventory item: $e');
    }
  }

  // Delete inventory item (soft delete)
  static Future<void> deleteInventoryItem(String itemId) async {
    try {
      await FirestoreService.updateDocument(
        collection: _collectionName,
        documentId: itemId,
        data: {
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      throw Exception('Failed to delete inventory item: $e');
    }
  }
}
