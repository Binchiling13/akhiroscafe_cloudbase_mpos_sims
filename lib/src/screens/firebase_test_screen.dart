import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../controllers/product_controller.dart';
import '../controllers/order_controller.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductController>().loadProducts();
      context.read<OrderController>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase CRUD Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createTestProduct(context),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () => _createTestOrder(context),
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _testTimestampHandling(context),
            tooltip: 'Test Timestamp Handling',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductSection(),
            const SizedBox(height: 24),
            _buildOrderSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSection() {
    return Consumer<ProductController>(
      builder: (context, productController, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (productController.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (productController.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.red[100],
                    child: Text(
                      'Error: ${productController.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else
                  productController.products.isEmpty
                      ? const Text('No products found. Create some test products!')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: productController.products.length,
                          itemBuilder: (context, index) {
                            final product = productController.products[index];
                            return ListTile(
                              title: Text(product.name),
                              subtitle: Text('₱${product.price.toStringAsFixed(2)} - ${product.category}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => productController.deleteProduct(product.id),
                              ),
                            );
                          },
                        ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderSection() {
    return Consumer<OrderController>(
      builder: (context, orderController, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Orders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (orderController.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (orderController.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.red[100],
                    child: Text(
                      'Error: ${orderController.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else
                  orderController.orders.isEmpty
                      ? const Text('No orders found. Create some test orders!')
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: orderController.orders.length,
                          itemBuilder: (context, index) {
                            final order = orderController.orders[index];
                            return ListTile(
                              title: Text('Order ${order.id}'),
                              subtitle: Text(
                                '₱${order.total.toStringAsFixed(2)} - ${order.status}\n'
                                'Date: ${order.dateTime.toString().substring(0, 19)}',
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => orderController.deleteOrder(order.id),
                              ),
                            );
                          },
                        ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _createTestProduct(BuildContext context) {
    final productController = context.read<ProductController>();
    
    final product = Product(
      id: '',
      name: 'Test Coffee ${DateTime.now().millisecondsSinceEpoch}',
      description: 'A delicious test coffee blend',
      price: 4.99,
      category: 'Coffee',
      imageUrl: 'https://via.placeholder.com/150',
      stockQuantity: 100,
      sku: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    
    productController.createProduct(product);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test product created!')),
    );
  }

  void _createTestOrder(BuildContext context) {
    final orderController = context.read<OrderController>();
    
    final order = Order(
      id: '',
      dateTime: DateTime.now(),
      items: [
        CartItem(
          productId: 'test_product_1',
          productName: 'Test Americano',
          price: 3.99,
          quantity: 2,
          imageUrl: 'https://via.placeholder.com/150',
        ),
        CartItem(
          productId: 'test_product_2',
          productName: 'Test Latte',
          price: 4.99,
          quantity: 1,
          imageUrl: 'https://via.placeholder.com/150',
        ),
      ],
      subtotal: 12.97,
      tax: 1.30,
      customerName: 'Test Customer',
      customerId: 'test_customer_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    
    orderController.createOrder(order);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test order created!')),
    );
  }

  void _testTimestampHandling(BuildContext context) async {
    final orderController = Provider.of<OrderController>(context, listen: false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Testing timestamp handling...')),
    );
    
    try {
      // Test creating an order with current timestamp
      final testOrder = Order(
        id: '',
        dateTime: DateTime.now(),
        items: [
          CartItem(
            productId: 'timestamp_test',
            productName: 'Timestamp Test Item',
            price: 5.99,
            quantity: 1,
            imageUrl: '',
          ),
        ],
        subtotal: 5.99,
        tax: 0.60,
        customerName: 'Timestamp Test Customer',
        createdAt: DateTime.now(),
      );
      
      final success = await orderController.createOrder(testOrder);
      
      if (success) {
        // Now try to reload orders to test timestamp parsing
        await orderController.loadOrders();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Timestamp test passed! Orders loaded successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to create test order');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Timestamp test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
