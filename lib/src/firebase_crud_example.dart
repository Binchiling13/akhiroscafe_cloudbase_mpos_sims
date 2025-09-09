import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/product_controller.dart';
import 'controllers/order_controller.dart';
import 'controllers/customer_controller.dart';
import 'controllers/auth_controller.dart';
import 'models/product.dart';
import 'models/order.dart';
import 'models/cart_item.dart';

// Example widget showing how to use the Firebase CRUD operations
class FirebaseCrudExampleScreen extends StatefulWidget {
  const FirebaseCrudExampleScreen({super.key});

  @override
  State<FirebaseCrudExampleScreen> createState() => _FirebaseCrudExampleScreenState();
}

class _FirebaseCrudExampleScreenState extends State<FirebaseCrudExampleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase CRUD Examples'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductSection(),
            const Divider(height: 32),
            _buildOrderSection(),
            const Divider(height: 32),
            _buildCustomerSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSection() {
    return Consumer<ProductController>(
      builder: (context, productController, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Operations',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Create Product Button
            ElevatedButton(
              onPressed: () => _createSampleProduct(productController),
              child: const Text('Create Sample Product'),
            ),
            const SizedBox(height: 8),
            
            // Load Products Button
            ElevatedButton(
              onPressed: () => productController.loadProducts(),
              child: const Text('Load All Products'),
            ),
            const SizedBox(height: 8),
            
            // Search Products
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search Products',
                border: OutlineInputBorder(),
              ),
              onChanged: productController.searchProducts,
            ),
            const SizedBox(height: 16),
            
            // Products List
            if (productController.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (productController.errorMessage != null)
              Text(
                'Error: ${productController.errorMessage}',
                style: const TextStyle(color: Colors.red),
              )
            else
              ...productController.products.map((product) => Card(
                child: ListTile(
                  title: Text(product.name),
                  subtitle: Text('\$${product.price.toStringAsFixed(2)} - Stock: ${product.stockQuantity}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Update Stock'),
                        onTap: () => _updateProductStock(productController, product),
                      ),
                      PopupMenuItem(
                        child: const Text('Delete'),
                        onTap: () => productController.deleteProduct(product.id),
                      ),
                    ],
                  ),
                ),
              )).toList(),
          ],
        );
      },
    );
  }

  Widget _buildOrderSection() {
    return Consumer<OrderController>(
      builder: (context, orderController, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Operations',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Create Order Button
            ElevatedButton(
              onPressed: () => _createSampleOrder(orderController),
              child: const Text('Create Sample Order'),
            ),
            const SizedBox(height: 8),
            
            // Load Orders Button
            ElevatedButton(
              onPressed: () => orderController.loadOrders(),
              child: const Text('Load All Orders'),
            ),
            const SizedBox(height: 8),
            
            // Filter by Status
            DropdownButton<String>(
              value: orderController.selectedStatus,
              onChanged: (status) {
                if (status != null) {
                  orderController.filterByStatus(status);
                }
              },
              items: orderController.statuses.map((status) => 
                DropdownMenuItem(
                  value: status,
                  child: Text(status),
                ),
              ).toList(),
            ),
            const SizedBox(height: 16),
            
            // Orders List
            if (orderController.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (orderController.errorMessage != null)
              Text(
                'Error: ${orderController.errorMessage}',
                style: const TextStyle(color: Colors.red),
              )
            else
              ...orderController.orders.map((order) => Card(
                child: ListTile(
                  title: Text('Order ${order.id}'),
                  subtitle: Text('Total: \$${order.total.toStringAsFixed(2)} - Status: ${order.status}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Mark as Completed'),
                        onTap: () => orderController.updateOrderStatus(order.id, 'Completed'),
                      ),
                      PopupMenuItem(
                        child: const Text('Cancel Order'),
                        onTap: () => orderController.updateOrderStatus(order.id, 'Cancelled'),
                      ),
                      PopupMenuItem(
                        child: const Text('Delete'),
                        onTap: () => orderController.deleteOrder(order.id),
                      ),
                    ],
                  ),
                ),
              )).toList(),
          ],
        );
      },
    );
  }

  Widget _buildCustomerSection() {
    return Consumer<CustomerController>(
      builder: (context, customerController, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Operations',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Current Customer Info
            if (customerController.currentCustomer != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Customer: ${customerController.currentCustomer!.displayName}'),
                      Text('Email: ${customerController.currentCustomer!.email}'),
                      if (customerController.currentCustomer!.phoneNumber != null)
                        Text('Phone: ${customerController.currentCustomer!.phoneNumber}'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            
            // Update Profile Button
            ElevatedButton(
              onPressed: () => _updateCustomerProfile(customerController),
              child: const Text('Update Profile'),
            ),
            const SizedBox(height: 8),
            
            // Load All Customers Button (Admin)
            ElevatedButton(
              onPressed: () => customerController.loadAllCustomers(),
              child: const Text('Load All Customers (Admin)'),
            ),
            const SizedBox(height: 8),
            
            // Search Customers
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search Customers',
                border: OutlineInputBorder(),
              ),
              onChanged: customerController.searchCustomers,
            ),
            const SizedBox(height: 16),
            
            // Customers List
            if (customerController.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (customerController.errorMessage != null)
              Text(
                'Error: ${customerController.errorMessage}',
                style: const TextStyle(color: Colors.red),
              )
            else
              ...customerController.customers.map((customer) => Card(
                child: ListTile(
                  title: Text(customer.displayName),
                  subtitle: Text(customer.email),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Deactivate'),
                        onTap: () => customerController.deactivateCustomer(customer.id),
                      ),
                    ],
                  ),
                ),
              )).toList(),
          ],
        );
      },
    );
  }

  void _createSampleProduct(ProductController controller) {
    final product = Product(
      id: '', // Will be generated by Firestore
      name: 'Sample Coffee ${DateTime.now().millisecondsSinceEpoch}',
      description: 'A delicious sample coffee product',
      price: 4.99,
      category: 'Coffee',
      imageUrl: 'https://example.com/coffee.jpg',
      stockQuantity: 50,
      sku: 'SAM${DateTime.now().millisecondsSinceEpoch}',
    );
    
    controller.createProduct(product);
  }

  void _updateProductStock(ProductController controller, Product product) {
    // Update stock to a random number between 10 and 100
    final newStock = 10 + (DateTime.now().millisecondsSinceEpoch % 90);
    controller.updateProductStock(product.id, newStock);
  }

  void _createSampleOrder(OrderController controller) {
    final order = Order(
      id: '', // Will be generated by Firestore
      dateTime: DateTime.now(),
      items: [
        CartItem(
          productId: 'sample_product_1',
          productName: 'Sample Coffee',
          price: 4.99,
          quantity: 2,
          imageUrl: 'https://example.com/coffee.jpg',
        ),
        CartItem(
          productId: 'sample_product_2',
          productName: 'Sample Pastry',
          price: 2.99,
          quantity: 1,
          imageUrl: 'https://example.com/pastry.jpg',
        ),
      ],
      subtotal: 12.97,
      tax: 1.30,
      customerName: 'Sample Customer',
      customerId: 'sample_customer_id',
    );
    
    controller.createOrder(order);
  }

  void _updateCustomerProfile(CustomerController controller) {
    controller.updateCurrentCustomerProfile(
      displayName: 'Updated Name ${DateTime.now().millisecondsSinceEpoch}',
      phoneNumber: '+1234567890',
      address: '123 Sample Street, Sample City',
    );
  }
}

// How to integrate these controllers in your main app
class FirebaseCrudApp extends StatelessWidget {
  const FirebaseCrudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ProductController()),
        ChangeNotifierProvider(create: (_) => OrderController()),
        ChangeNotifierProvider(create: (_) => CustomerController()),
      ],
      child: MaterialApp(
        title: 'Akhiro Cafe - Firebase CRUD',
        theme: ThemeData(
          primarySwatch: Colors.brown,
        ),
        home: const FirebaseCrudExampleScreen(),
      ),
    );
  }
}
