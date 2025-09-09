import 'package:flutter/material.dart';
import '../models/product_inventory.dart';
import '../services/product_inventory_service.dart';

class ProductInventoryController extends ChangeNotifier {
  List<ProductInventory> _products = [];
  List<ProductInventory> _filteredProducts = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _statusFilter = 'All'; // All, Low Stock, Out of Stock, Expiring, Producible

  // Getters
  List<ProductInventory> get products => _products;
  List<ProductInventory> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get statusFilter => _statusFilter;

  // Get unique categories
  List<String> get categories {
    final cats = _products.map((product) => product.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  // Load all products
  Future<void> loadProducts() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    _isLoading = true;
    notifyListeners();

    try {
      _products = await ProductInventoryService.getActiveProducts();
      _applyFilters();
    } catch (e) {
      // Handle error
      debugPrint('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new product
  Future<bool> createProduct(ProductInventory product) async {
    try {
      await ProductInventoryService.createProduct(product);
      await loadProducts(); // Reload the list
      return true;
    } catch (e) {
      debugPrint('Error creating product: $e');
      return false;
    }
  }

  // Update product
  Future<bool> updateProduct(String productId, ProductInventory product) async {
    try {
      await ProductInventoryService.updateProduct(productId, product);
      await loadProducts(); // Reload the list
      return true;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
    }
  }

  // Update stock
  Future<bool> updateStock(String productId, double newStock, {String? reason}) async {
    try {
      await ProductInventoryService.updateStock(productId, newStock, reason: reason);
      await loadProducts(); // Reload the list
      return true;
    } catch (e) {
      debugPrint('Error updating stock: $e');
      return false;
    }
  }

  // Adjust stock
  Future<bool> adjustStock(String productId, double adjustment, {String? reason}) async {
    try {
      await ProductInventoryService.adjustStock(productId, adjustment, reason: reason);
      await loadProducts(); // Reload the list
      return true;
    } catch (e) {
      debugPrint('Error adjusting stock: $e');
      return false;
    }
  }

  // Produce product
  Future<bool> produceProduct(String productId, int quantity, {String? reason}) async {
    try {
      final success = await ProductInventoryService.produceProduct(productId, quantity, reason: reason);
      if (success) {
        await loadProducts(); // Reload the list
      }
      return success;
    } catch (e) {
      debugPrint('Error producing product: $e');
      return false;
    }
  }

  // Sell product
  Future<bool> sellProduct(String productId, int quantity) async {
    try {
      final success = await ProductInventoryService.sellProduct(productId, quantity);
      if (success) {
        await loadProducts(); // Reload the list
      }
      return success;
    } catch (e) {
      debugPrint('Error selling product: $e');
      return false;
    }
  }

  // Check if product can be produced
  Future<bool> canProduceProduct(String productId, int quantity) async {
    try {
      return await ProductInventoryService.canProduceProduct(productId, quantity);
    } catch (e) {
      debugPrint('Error checking production capability: $e');
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    try {
      await ProductInventoryService.deleteProduct(productId);
      await loadProducts(); // Reload the list
      return true;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  // Search products
  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter by category
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // Filter by status
  void filterByStatus(String status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  // Apply all filters
  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase());

      // Category filter
      final matchesCategory = _selectedCategory == 'All' || 
          product.category == _selectedCategory;

      // Status filter
      bool matchesStatus = true;
      switch (_statusFilter) {
        case 'Low Stock':
          matchesStatus = product.isLowStock;
          break;
        case 'Out of Stock':
          matchesStatus = product.isOutOfStock;
          break;
        case 'Expiring':
          matchesStatus = product.isExpiringSoon || product.isExpired;
          break;
        case 'Expired':
          matchesStatus = product.isExpired;
          break;
        case 'Available':
          matchesStatus = product.isAvailable;
          break;
        case 'All':
        default:
          matchesStatus = true;
          break;
      }

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();

    // Sort by name
    _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _statusFilter = 'All';
    _applyFilters();
    notifyListeners();
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      return await ProductInventoryService.getProductStats();
    } catch (e) {
      debugPrint('Error getting product statistics: $e');
      return {};
    }
  }

  // Get production recommendations
  Future<List<ProductInventory>> getProductionRecommendations() async {
    try {
      return await ProductInventoryService.getProductionRecommendations();
    } catch (e) {
      debugPrint('Error getting production recommendations: $e');
      return [];
    }
  }

  // Calculate production cost
  Future<double> calculateProductionCost(String productId) async {
    try {
      return await ProductInventoryService.calculateProductionCost(productId);
    } catch (e) {
      debugPrint('Error calculating production cost: $e');
      return 0.0;
    }
  }

  // Get low stock count
  int get lowStockCount => _products.where((product) => product.isLowStock).length;

  // Get out of stock count
  int get outOfStockCount => _products.where((product) => product.isOutOfStock).length;

  // Get expiring count
  int get expiringCount => _products.where((product) => product.isExpiringSoon || product.isExpired).length;

  // Get total value
  double get totalValue => _products.fold(0.0, (sum, product) => sum + product.totalValue);

  // Get total production cost
  double get totalProductionCost => _products.fold(0.0, (sum, product) => sum + (product.productionCost * product.currentStock));

  // Get profit potential
  double get profitPotential => totalValue - totalProductionCost;
}
