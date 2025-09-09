import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';

class InventoryController extends ChangeNotifier {
  List<InventoryItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategory = 'All';
  String _sortBy = 'Name';
  String _searchQuery = '';

  // Getters
  List<InventoryItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  String get searchQuery => _searchQuery;

  // Get filtered and sorted items
  List<InventoryItem> get filteredItems {
    var filtered = List<InventoryItem>.from(_items);

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((item) => item.category == _selectedCategory).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) =>
        item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'Name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Category':
        filtered.sort((a, b) => a.category.compareTo(b.category));
        break;
      case 'Stock':
        filtered.sort((a, b) => a.currentStock.compareTo(b.currentStock));
        break;
      case 'Cost':
        filtered.sort((a, b) => a.costPerUnit.compareTo(b.costPerUnit));
        break;
      case 'Low Stock':
        filtered.sort((a, b) {
          if (a.isLowStock && !b.isLowStock) return -1;
          if (!a.isLowStock && b.isLowStock) return 1;
          return 0;
        });
        break;
    }

    return filtered;
  }

  // Get categories
  List<String> get categories {
    final categorySet = {'All'};
    categorySet.addAll(_items.map((item) => item.category));
    return categorySet.toList();
  }

  // Get low stock items
  List<InventoryItem> get lowStockItems {
    return _items.where((item) => item.isLowStock).toList();
  }

  // Get expiring items
  List<InventoryItem> get expiringItems {
    return _items.where((item) => item.isExpiringSoon || item.isExpired).toList();
  }

  // Get inventory statistics
  Map<String, dynamic> get inventoryStats {
    final totalItems = _items.length;
    final lowStockCount = lowStockItems.length;
    final expiringCount = expiringItems.length;
    final totalValue = _items.fold<double>(0, (sum, item) => sum + item.totalValue);

    return {
      'totalItems': totalItems,
      'lowStockItems': lowStockCount,
      'expiringItems': expiringCount,
      'totalValue': totalValue,
    };
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Load all inventory items
  Future<void> loadItems() async {
    _setLoading(true);
    _clearError();

    try {
      _items = await InventoryService.getActiveItems();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Create new inventory item
  Future<bool> createItem(InventoryItem item) async {
    _setLoading(true);
    _clearError();

    try {
      final itemId = await InventoryService.createInventoryItem(item);
      
      // Add the new item to the local list with the generated ID
      final newItem = item.copyWith(
        id: itemId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _items.insert(0, newItem);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update existing inventory item
  Future<bool> updateItem(String itemId, InventoryItem item) async {
    _setLoading(true);
    _clearError();

    try {
      await InventoryService.updateInventoryItem(itemId, item);
      
      // Update the item in the local list
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _items[index] = item.copyWith(
          id: itemId,
          updatedAt: DateTime.now(),
        );
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Delete inventory item
  Future<bool> deleteItem(String itemId) async {
    _setLoading(true);
    _clearError();

    try {
      await InventoryService.deleteInventoryItem(itemId);
      
      // Remove the item from the local list
      _items.removeWhere((item) => item.id == itemId);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update stock quantity
  Future<bool> updateStock(String itemId, double newStock, {String? reason}) async {
    _setLoading(true);
    _clearError();

    try {
      await InventoryService.updateStock(itemId, newStock, reason: reason);
      
      // Update the stock in the local list
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _items[index] = _items[index].copyWith(
          currentStock: newStock,
          lastRestocked: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Adjust stock (add or subtract)
  Future<bool> adjustStock(String itemId, double adjustment, {String? reason}) async {
    _setLoading(true);
    _clearError();

    try {
      await InventoryService.adjustStock(itemId, adjustment, reason: reason);
      
      // Update the stock in the local list
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        final newStock = _items[index].currentStock + adjustment;
        _items[index] = _items[index].copyWith(
          currentStock: newStock,
          lastRestocked: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Set filters and sorting
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Refresh data
  Future<void> refreshItems() async {
    await loadItems();
  }
}
