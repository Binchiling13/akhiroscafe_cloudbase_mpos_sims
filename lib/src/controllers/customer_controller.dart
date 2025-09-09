import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../services/auth_service.dart';

class CustomerController extends ChangeNotifier {
  Customer? _currentCustomer;
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Getters
  Customer? get currentCustomer => _currentCustomer;
  List<Customer> get customers => _filteredCustomers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  CustomerController() {
    _initializeCurrentCustomer();
  }

  // Initialize current customer from auth service
  Future<void> _initializeCurrentCustomer() async {
    final user = AuthService.currentUser;
    if (user != null) {
      await loadCurrentCustomer(user.uid);
    }
  }

  // Load current customer profile
  Future<void> loadCurrentCustomer(String customerId) async {
    _setLoading(true);
    _clearError();

    try {
      _currentCustomer = await CustomerService.getCustomer(customerId);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Create customer profile
  Future<bool> createCustomerProfile({
    required String id,
    required String email,
    required String displayName,
    String? phoneNumber,
    String? address,
    DateTime? dateOfBirth,
    String? profileImageUrl,
    Map<String, dynamic>? preferences,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final customer = Customer(
        id: id,
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        address: address,
        dateOfBirth: dateOfBirth,
        profileImageUrl: profileImageUrl,
        preferences: preferences,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await CustomerService.createCustomer(customer);
      _currentCustomer = customer;
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update current customer profile
  Future<bool> updateCurrentCustomerProfile({
    String? displayName,
    String? phoneNumber,
    String? address,
    DateTime? dateOfBirth,
    String? profileImageUrl,
    Map<String, dynamic>? preferences,
  }) async {
    if (_currentCustomer == null) {
      _setError('No customer profile found');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await CustomerService.updateCustomerProfile(
        customerId: _currentCustomer!.id,
        displayName: displayName,
        phoneNumber: phoneNumber,
        address: address,
        dateOfBirth: dateOfBirth,
        profileImageUrl: profileImageUrl,
        preferences: preferences,
      );

      // Update local customer data
      _currentCustomer = _currentCustomer!.copyWith(
        displayName: displayName ?? _currentCustomer!.displayName,
        phoneNumber: phoneNumber ?? _currentCustomer!.phoneNumber,
        address: address ?? _currentCustomer!.address,
        dateOfBirth: dateOfBirth ?? _currentCustomer!.dateOfBirth,
        profileImageUrl: profileImageUrl ?? _currentCustomer!.profileImageUrl,
        preferences: preferences ?? _currentCustomer!.preferences,
        updatedAt: DateTime.now(),
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update customer preferences
  Future<bool> updateCustomerPreferences(Map<String, dynamic> preferences) async {
    if (_currentCustomer == null) {
      _setError('No customer profile found');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await CustomerService.updateCustomerPreferences(
        _currentCustomer!.id,
        preferences,
      );

      _currentCustomer = _currentCustomer!.copyWith(
        preferences: preferences,
        updatedAt: DateTime.now(),
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Load all customers (for admin)
  Future<void> loadAllCustomers() async {
    _setLoading(true);
    _clearError();

    try {
      _customers = await CustomerService.getAllCustomers();
      _applyFilters();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Search customers
  void searchCustomers(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
  }

  // Apply search filters
  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredCustomers = List.from(_customers);
    } else {
      _filteredCustomers = _customers.where((customer) =>
          customer.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          customer.email.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    notifyListeners();
  }

  // Get customer by ID
  Future<Customer?> getCustomer(String customerId) async {
    _setLoading(true);
    _clearError();

    try {
      final customer = await CustomerService.getCustomer(customerId);
      _setLoading(false);
      return customer;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  // Get customer by email
  Future<Customer?> getCustomerByEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final customer = await CustomerService.getCustomerByEmail(email);
      _setLoading(false);
      return customer;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  // Deactivate customer (admin function)
  Future<bool> deactivateCustomer(String customerId) async {
    _setLoading(true);
    _clearError();

    try {
      await CustomerService.deactivateCustomer(customerId);
      
      // Remove from local list
      _customers.removeWhere((customer) => customer.id == customerId);
      _applyFilters();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Delete customer (admin function)
  Future<bool> deleteCustomer(String customerId) async {
    _setLoading(true);
    _clearError();

    try {
      await CustomerService.deleteCustomer(customerId);
      
      // Remove from local list
      _customers.removeWhere((customer) => customer.id == customerId);
      _applyFilters();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Get customer statistics
  Future<Map<String, dynamic>> getCustomerStatistics() async {
    try {
      return await CustomerService.getCustomerStatistics();
    } catch (e) {
      _setError(e.toString());
      return {};
    }
  }

  // Check if customer profile exists
  Future<bool> customerProfileExists(String customerId) async {
    try {
      final customer = await CustomerService.getCustomer(customerId);
      return customer != null;
    } catch (e) {
      return false;
    }
  }

  // Refresh current customer data
  Future<void> refreshCurrentCustomer() async {
    if (_currentCustomer != null) {
      await loadCurrentCustomer(_currentCustomer!.id);
    }
  }

  // Refresh all customers data
  Future<void> refreshAllCustomers() async {
    await loadAllCustomers();
  }

  // Clear current customer (for logout)
  void clearCurrentCustomer() {
    _currentCustomer = null;
    notifyListeners();
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
