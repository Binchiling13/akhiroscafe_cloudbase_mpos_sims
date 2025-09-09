import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../services/ingredient_service.dart';

class IngredientController extends ChangeNotifier {
  List<Ingredient> _ingredients = [];
  List<Ingredient> _filteredIngredients = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedSupplier = 'All';
  String _statusFilter = 'All'; // All, Low Stock, Out of Stock, Expiring

  // Getters
  List<Ingredient> get ingredients => _ingredients;
  List<Ingredient> get filteredIngredients => _filteredIngredients;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedSupplier => _selectedSupplier;
  String get statusFilter => _statusFilter;

  // Get unique categories
  List<String> get categories {
    final cats = _ingredients.map((ingredient) => ingredient.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  // Get unique suppliers
  List<String> get suppliers {
    final sups = _ingredients.map((ingredient) => ingredient.supplier).toSet().toList();
    sups.sort();
    return ['All', ...sups];
  }

  // Load all ingredients
  Future<void> loadIngredients() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    _isLoading = true;
    notifyListeners();

    try {
      _ingredients = await IngredientService.getActiveIngredients();
      _applyFilters();
    } catch (e) {
      // Handle error
      debugPrint('Error loading ingredients: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new ingredient
  Future<bool> createIngredient(Ingredient ingredient) async {
    try {
      await IngredientService.createIngredient(ingredient);
      await loadIngredients(); // Reload the list
      return true;
    } catch (e) {
      debugPrint('Error creating ingredient: $e');
      return false;
    }
  }

  // Update ingredient
  Future<bool> updateIngredient(String ingredientId, Ingredient ingredient) async {
    try {
      await IngredientService.updateIngredient(ingredientId, ingredient);
      await loadIngredients(); // Reload the list
      return true;
    } catch (e) {
      debugPrint('Error updating ingredient: $e');
      return false;
    }
  }

  // Update stock
  Future<bool> updateStock(String ingredientId, double newStock, {String? reason}) async {
    try {
      await IngredientService.updateStock(ingredientId, newStock, reason: reason);
      await loadIngredients(); // Reload the list
      return true;
    } catch (e) {
      debugPrint('Error updating stock: $e');
      return false;
    }
  }

  // Adjust stock
  Future<bool> adjustStock(String ingredientId, double adjustment, {String? reason}) async {
    try {
      await IngredientService.adjustStock(ingredientId, adjustment, reason: reason);
      await loadIngredients(); // Reload the list
      return true;
    } catch (e) {
      debugPrint('Error adjusting stock: $e');
      return false;
    }
  }

  // Delete ingredient
  Future<bool> deleteIngredient(String ingredientId) async {
    try {
      await IngredientService.deleteIngredient(ingredientId);
      await loadIngredients(); // Reload the list
      return true;
    } catch (e) {
      debugPrint('Error deleting ingredient: $e');
      return false;
    }
  }

  // Search ingredients
  void searchIngredients(String query) {
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

  // Filter by supplier
  void filterBySupplier(String supplier) {
    _selectedSupplier = supplier;
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
    _filteredIngredients = _ingredients.where((ingredient) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          ingredient.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ingredient.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ingredient.supplier.toLowerCase().contains(_searchQuery.toLowerCase());

      // Category filter
      final matchesCategory = _selectedCategory == 'All' || 
          ingredient.category == _selectedCategory;

      // Supplier filter
      final matchesSupplier = _selectedSupplier == 'All' || 
          ingredient.supplier == _selectedSupplier;

      // Status filter
      bool matchesStatus = true;
      switch (_statusFilter) {
        case 'Low Stock':
          matchesStatus = ingredient.isLowStock;
          break;
        case 'Out of Stock':
          matchesStatus = ingredient.isOutOfStock;
          break;
        case 'Expiring':
          matchesStatus = ingredient.isExpiringSoon || ingredient.isExpired;
          break;
        case 'Expired':
          matchesStatus = ingredient.isExpired;
          break;
        case 'All':
        default:
          matchesStatus = true;
          break;
      }

      return matchesSearch && matchesCategory && matchesSupplier && matchesStatus;
    }).toList();

    // Sort by name
    _filteredIngredients.sort((a, b) => a.name.compareTo(b.name));
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _selectedSupplier = 'All';
    _statusFilter = 'All';
    _applyFilters();
    notifyListeners();
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      return await IngredientService.getIngredientStats();
    } catch (e) {
      debugPrint('Error getting ingredient statistics: $e');
      return {};
    }
  }

  // Get low stock count
  int get lowStockCount => _ingredients.where((ingredient) => ingredient.isLowStock).length;

  // Get out of stock count
  int get outOfStockCount => _ingredients.where((ingredient) => ingredient.isOutOfStock).length;

  // Get expiring count
  int get expiringCount => _ingredients.where((ingredient) => ingredient.isExpiringSoon || ingredient.isExpired).length;

  // Get total value
  double get totalValue => _ingredients.fold(0.0, (sum, ingredient) => sum + ingredient.totalValue);
}
