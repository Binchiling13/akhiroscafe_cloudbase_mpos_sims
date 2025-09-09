import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../controllers/order_controller.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // Load orders when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderController>().loadOrders();
    });
  }

  List<String> get _statusOptions => ['All', 'Pending', 'Completed', 'Cancelled', 'Refunded'];

  double _getTotalRevenue(List<Order> orders) {
    return orders.fold(0, (sum, order) => sum + order.total);
  }

  int _getTotalItems(List<Order> orders) {
    return orders.fold(0, (sum, order) => sum + order.totalItems);
  }

  List<Order> _getFilteredOrders(List<Order> orders) {
    return orders.where((order) {
      final matchesSearch = _searchController.text.isEmpty ||
          order.id.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (order.customerName?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);
      
      final matchesDate = _selectedDateRange == null ||
          (order.dateTime.isAfter(_selectedDateRange!.start) &&
           order.dateTime.isBefore(_selectedDateRange!.end.add(const Duration(days: 1))));
      
      return matchesSearch && matchesDate;
    }).toList();
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: 600,
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order ${order.id}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Date: ${_formatDateTime(order.dateTime)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                // Order details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer info
                        if (order.customerName != null)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.person),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Customer: ${order.customerName}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Items
                        const Text(
                          'Order Items:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Expanded(
                          child: ListView.builder(
                            itemCount: order.items.length,
                            itemBuilder: (context, index) {
                              final item = order.items[index];
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(item.imageUrl),
                                    onBackgroundImageError: (_, __) {},
                                    child: const Icon(Icons.coffee),
                                  ),
                                  title: Text(item.productName),
                                  subtitle: Text('Unit Price: ₱${item.price.toStringAsFixed(2)}'),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Qty: ${item.quantity}'),
                                      Text(
                                        '₱${item.totalPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        const Divider(),
                        
                        // Order summary
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:'),
                                Text('₱${order.subtotal.toStringAsFixed(2)}'),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tax:'),
                                Text('₱${order.tax.toStringAsFixed(2)}'),
                              ],
                            ),
                            if (order.discount > 0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Discount:'),
                                  Text('-₱${order.discount.toStringAsFixed(2)}'),
                                ],
                              ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₱${order.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Store references before async operations
                          final navigator = Navigator.of(context);
                          final orderController = context.read<OrderController>();
                          
                          navigator.pop();
                          orderController.updateOrderStatus(order.id, 'Completed');
                        },
                        child: const Text('Mark Completed'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // Store references before async operations
                          final navigator = Navigator.of(context);
                          final orderController = context.read<OrderController>();
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          
                          navigator.pop();
                          
                          // Show confirmation dialog for cancellation
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Cancel Order'),
                              content: const Text(
                                'Are you sure you want to cancel this order?\n\n'
                                'This will restore the product stock and cannot be undone.'
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('No'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Yes, Cancel Order'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed == true) {
                            final success = await orderController.cancelOrder(order.id);
                            if (success && mounted) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Order cancelled successfully. Stock has been restored.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(orderController.errorMessage ?? 'Failed to cancel order'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Cancel Order'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderController>(
      builder: (context, orderController, child) {
        final filteredOrders = _getFilteredOrders(orderController.orders);
        final totalRevenue = _getTotalRevenue(filteredOrders);
        final totalItems = _getTotalItems(filteredOrders);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Orders'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => orderController.refreshOrders(),
                tooltip: 'Refresh Orders',
              ),
            ],
          ),
          body: Column(
            children: [
              // Filters
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Search field
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'Search orders...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Status filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: orderController.selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: _statusOptions.map((String status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              if (value != null) {
                                orderController.filterByStatus(value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Date range filter
                        ElevatedButton.icon(
                          onPressed: _selectDateRange,
                          icon: const Icon(Icons.date_range),
                          label: Text(_selectedDateRange == null
                              ? 'Select Date Range'
                              : '${_formatDateTime(_selectedDateRange!.start)} - ${_formatDateTime(_selectedDateRange!.end)}'),
                        ),
                        if (_selectedDateRange != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _clearDateFilter,
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear date filter',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Statistics cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Icon(Icons.receipt, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                'Total Orders',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                filteredOrders.length.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Icon(Icons.attach_money, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                'Total Revenue',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₱${totalRevenue.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Icon(Icons.shopping_cart, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                'Total Items',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                totalItems.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Icon(Icons.trending_up, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                'Avg Order Value',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                filteredOrders.isNotEmpty
                                    ? '₱${(totalRevenue / filteredOrders.length).toStringAsFixed(2)}'
                                    : '₱0.00',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Orders list
              Expanded(
                child: orderController.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : orderController.errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Error: ${orderController.errorMessage}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                                ElevatedButton(
                                  onPressed: () => orderController.refreshOrders(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : filteredOrders.isEmpty
                            ? const Center(
                                child: Text(
                                  'No orders found',
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                itemCount: filteredOrders.length,
                                itemBuilder: (context, index) {
                                  final order = filteredOrders[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: _getStatusColor(order.status),
                                        child: Text(
                                          '${order.totalItems}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        'Order ${order.id}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (order.customerName != null)
                                            Text('Customer: ${order.customerName}'),
                                          Text('Date: ${_formatDateTime(order.dateTime)}'),
                                          Text('Items: ${order.totalItems}'),
                                        ],
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(order.status),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              order.status,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₱${order.total.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _showOrderDetails(order),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      case 'Refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
