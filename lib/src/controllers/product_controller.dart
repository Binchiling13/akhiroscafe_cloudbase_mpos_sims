import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductController extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Getters
  List<Product> get products => _filteredProducts;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  List<String> get categories {
    final categorySet = {'All'};
    categorySet.addAll(_products.map((product) => product.category));
    return categorySet.toList();
  }

  ProductController() {
    loadProducts();
  }

  // Load all products
  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();

    try {
      _products = await ProductService.getAllProducts();
      _applyFilters();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Create a new product
  Future<bool> createProduct(Product product) async {
    _setLoading(true);
    _clearError();

    try {
      final productId = await ProductService.createProduct(product);
      
      // Add the new product to the local list with the generated ID
      final newProduct = product.copyWith(
        id: productId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _products.add(newProduct);
      _applyFilters();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update an existing product
  Future<bool> updateProduct(String productId, Product product) async {
    _setLoading(true);
    _clearError();

    try {
      await ProductService.updateProduct(productId, product);
      
      // Update the product in the local list
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = product.copyWith(updatedAt: DateTime.now());
        _applyFilters();
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Delete a product
  Future<bool> deleteProduct(String productId) async {
    _setLoading(true);
    _clearError();

    try {
      await ProductService.deleteProduct(productId);
      
      // Remove the product from the local list
      _products.removeWhere((product) => product.id == productId);
      _applyFilters();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Deactivate a product (soft delete)
  Future<bool> deactivateProduct(String productId) async {
    _setLoading(true);
    _clearError();

    try {
      await ProductService.deactivateProduct(productId);
      
      // Update the product status in the local list
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(
          isActive: false,
          updatedAt: DateTime.now(),
        );
        _applyFilters();
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update product stock
  Future<bool> updateProductStock(String productId, int newStock) async {
    _setLoading(true);
    _clearError();

    try {
      await ProductService.updateProductStock(productId, newStock);
      
      // Update the stock in the local list
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(
          stockQuantity: newStock,
          updatedAt: DateTime.now(),
        );
        _applyFilters();
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Get product by ID
  Future<Product?> getProduct(String productId) async {
    _setLoading(true);
    _clearError();

    try {
      final product = await ProductService.getProduct(productId);
      _selectedProduct = product;
      _setLoading(false);
      return product;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  // Search products
  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Filter by category
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  // Clear search and filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _applyFilters();
  }

  // Apply search and category filters
  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      // Filter by search query
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.sku.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filter by category
      final matchesCategory = _selectedCategory == 'All' ||
          product.category == _selectedCategory;

      // Only show active products
      return product.isActive && matchesSearch && matchesCategory;
    }).toList();

    notifyListeners();
  }

  // Select a product
  void selectProduct(Product? product) {
    _selectedProduct = product;
    notifyListeners();
  }

  // Get products by category
  List<Product> getProductsByCategory(String category) {
    return _products
        .where((product) => product.category == category && product.isActive)
        .toList();
  }

  // Get low stock products
  List<Product> getLowStockProducts({int threshold = 10}) {
    return _products
        .where((product) => 
            product.isActive && product.stockQuantity <= threshold)
        .toList();
  }

  // Refresh products from server
  Future<void> refreshProducts() async {
    await loadProducts();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
