import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../services/order_service.dart';
import '../services/product_inventory_service.dart';

class OrderController extends ChangeNotifier {
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  Order? _selectedOrder;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedStatus = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters
  List<Order> get orders => _filteredOrders;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedStatus => _selectedStatus;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  List<String> get statuses {
    final statusSet = {'All'};
    statusSet.addAll(_orders.map((order) => order.status));
    return statusSet.toList();
  }

  OrderController() {
    loadOrders();
  }

  // Load all orders
  Future<void> loadOrders() async {
    _setLoading(true);
    _clearError();

    try {
      _orders = await OrderService.getAllOrders();
      _applyFilters();
      _setLoading(false);
    } catch (e) {
      String errorMessage = e.toString();
      
      // Provide more specific error messages for common issues
      if (errorMessage.contains('timestamp') || errorMessage.contains('Timestamp')) {
        errorMessage = 'Failed to load orders: Date/time format error. Please check your data.';
      } else if (errorMessage.contains('permission-denied')) {
        errorMessage = 'Failed to load orders: Permission denied. Please check your Firestore rules.';
      } else if (errorMessage.contains('network')) {
        errorMessage = 'Failed to load orders: Network error. Please check your connection.';
      } else {
        errorMessage = 'Failed to load orders: $errorMessage';
      }
      
      _setError(errorMessage);
      _setLoading(false);
    }
  }

  // Create a new order
  Future<bool> createOrder(Order order) async {
    _setLoading(true);
    _clearError();

    try {
      // First validate stock availability
      final stockValidation = await ProductInventoryService.validateStockForOrder(order.items);
      
      if (!stockValidation['isValid']) {
        final errors = stockValidation['errors'] as List<String>;
        throw Exception('Stock validation failed:\n${errors.join('\n')}');
      }

      // Create the order
      final orderId = await OrderService.createOrder(order);
      
      // Process stock decrementing
      await ProductInventoryService.processOrderStock(
        order.items, 
        reason: 'Order #$orderId - ${order.customerName ?? 'Customer'}'
      );
      
      // Add the new order to the local list with the generated ID
      final newOrder = order.copyWith(
        id: orderId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _orders.insert(0, newOrder); // Insert at beginning for recent orders first
      _applyFilters();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update an existing order
  Future<bool> updateOrder(String orderId, Order order) async {
    _setLoading(true);
    _clearError();

    try {
      await OrderService.updateOrder(orderId, order);
      
      // Update the order in the local list
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = order.copyWith(updatedAt: DateTime.now());
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

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    _setLoading(true);
    _clearError();

    try {
      await OrderService.updateOrderStatus(orderId, status);
      
      // Update the status in the local list
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          status: status,
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

  // Cancel an order and restore stock
  Future<bool> cancelOrder(String orderId) async {
    _setLoading(true);
    _clearError();

    try {
      await OrderService.cancelOrder(orderId);
      
      // Update the status in the local list
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          status: 'Cancelled',
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

  // Delete an order
  Future<bool> deleteOrder(String orderId) async {
    _setLoading(true);
    _clearError();

    try {
      await OrderService.deleteOrder(orderId);
      
      // Remove the order from the local list
      _orders.removeWhere((order) => order.id == orderId);
      _applyFilters();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Add item to order
  Future<bool> addItemToOrder(String orderId, CartItem item) async {
    _setLoading(true);
    _clearError();

    try {
      await OrderService.addItemToOrder(orderId, item);
      
      // Update the order in the local list
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final currentOrder = _orders[index];
        final updatedItems = List<CartItem>.from(currentOrder.items);
        
        // Check if item already exists
        final existingItemIndex = updatedItems.indexWhere(
          (cartItem) => cartItem.productId == item.productId,
        );
        
        if (existingItemIndex != -1) {
          updatedItems[existingItemIndex] = updatedItems[existingItemIndex].copyWith(
            quantity: updatedItems[existingItemIndex].quantity + item.quantity,
          );
        } else {
          updatedItems.add(item);
        }
        
        // Recalculate subtotal
        final newSubtotal = updatedItems.fold<double>(
          0.0, (sum, cartItem) => sum + cartItem.totalPrice,
        );
        
        _orders[index] = currentOrder.copyWith(
          items: updatedItems,
          subtotal: newSubtotal,
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

  // Remove item from order
  Future<bool> removeItemFromOrder(String orderId, String productId) async {
    _setLoading(true);
    _clearError();

    try {
      await OrderService.removeItemFromOrder(orderId, productId);
      
      // Update the order in the local list
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final currentOrder = _orders[index];
        final updatedItems = currentOrder.items
            .where((item) => item.productId != productId)
            .toList();
        
        // Recalculate subtotal
        final newSubtotal = updatedItems.fold<double>(
          0.0, (sum, cartItem) => sum + cartItem.totalPrice,
        );
        
        _orders[index] = currentOrder.copyWith(
          items: updatedItems,
          subtotal: newSubtotal,
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

  // Get order by ID
  Future<Order?> getOrder(String orderId) async {
    _setLoading(true);
    _clearError();

    try {
      final order = await OrderService.getOrder(orderId);
      _selectedOrder = order;
      _setLoading(false);
      return order;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  // Get orders by customer
  Future<List<Order>> getOrdersByCustomer(String customerId) async {
    _setLoading(true);
    _clearError();

    try {
      final orders = await OrderService.getOrdersByCustomer(customerId);
      _setLoading(false);
      return orders;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return [];
    }
  }

  // Filter by status
  void filterByStatus(String status) {
    _selectedStatus = status;
    _applyFilters();
  }

  // Filter by date range
  void filterByDateRange(DateTime? startDate, DateTime? endDate) {
    _startDate = startDate;
    _endDate = endDate;
    _applyFilters();
  }

  // Clear filters
  void clearFilters() {
    _selectedStatus = 'All';
    _startDate = null;
    _endDate = null;
    _applyFilters();
  }

  // Apply filters
  void _applyFilters() {
    _filteredOrders = _orders.where((order) {
      // Filter by status
      final matchesStatus = _selectedStatus == 'All' ||
          order.status == _selectedStatus;

      // Filter by date range
      bool matchesDateRange = true;
      if (_startDate != null && _endDate != null) {
        final orderDate = order.dateTime;
        matchesDateRange = orderDate.isAfter(_startDate!) && 
                          orderDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }

      return matchesStatus && matchesDateRange;
    }).toList();

    notifyListeners();
  }

  // Select an order
  void selectOrder(Order? order) {
    _selectedOrder = order;
    notifyListeners();
  }

  // Get orders by status
  List<Order> getOrdersByStatus(String status) {
    return _orders.where((order) => order.status == status).toList();
  }

  // Get today's orders
  List<Order> getTodaysOrders() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _orders.where((order) =>
        order.dateTime.isAfter(startOfDay) && 
        order.dateTime.isBefore(endOfDay)
    ).toList();
  }

  // Get order statistics
  Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      return await OrderService.getOrderStatistics();
    } catch (e) {
      _setError(e.toString());
      return {};
    }
  }

  // Calculate total revenue
  double getTotalRevenue() {
    return _filteredOrders.fold<double>(
      0.0, (sum, order) => sum + order.total,
    );
  }

  // Calculate average order value
  double getAverageOrderValue() {
    if (_filteredOrders.isEmpty) return 0.0;
    return getTotalRevenue() / _filteredOrders.length;
  }

  // Refresh orders from server
  Future<void> refreshOrders() async {
    await loadOrders();
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
