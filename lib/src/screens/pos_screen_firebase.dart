import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_inventory.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../controllers/product_inventory_controller.dart';
import '../controllers/order_controller.dart';

class PosScreenFirebase extends StatefulWidget {
  const PosScreenFirebase({super.key});

  @override
  State<PosScreenFirebase> createState() => _PosScreenFirebaseState();
}

class _PosScreenFirebaseState extends State<PosScreenFirebase> {
  final List<CartItem> _cartItems = [];
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductInventoryController>(context, listen: false).loadProducts();
    });
  }

  List<String> _getCategories(List<ProductInventory> products) {
    final categories = products.map((p) => p.category).toSet().toList();
    categories.insert(0, 'All');
    return categories;
  }

  List<ProductInventory> _getFilteredProducts(List<ProductInventory> products) {
    return products.where((product) {
      final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
      final matchesSearch = _searchController.text.isEmpty ||
          product.name.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesCategory && matchesSearch && product.currentStock > 0; // Only show products in stock
    }).toList();
  }

  double get _subtotal {
    return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  double get _tax {
    return _subtotal * 0.1; // 10% tax
  }

  double get _total {
    return _subtotal + _tax;
  }

  int get _totalItemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  void _addToCart(ProductInventory product) async {
    // Check stock availability before adding to cart
    final availableStock = product.currentStock.toInt();
    final currentInCart = _cartItems
        .where((item) => item.productId == product.id)
        .fold(0, (sum, item) => sum + item.quantity);
    
    if (currentInCart >= availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot add more "${product.name}". Available stock: $availableStock'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!product.isActive || !product.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${product.name}" is not available for sale'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      final existingIndex = _cartItems.indexWhere((item) => item.productId == product.id);
      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(CartItem(
          productId: product.id,
          productName: product.name,
          price: product.sellingPrice,
          quantity: 1,
          imageUrl: product.imageUrl ?? '',
        ));
      }
    });

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeFromCart(int index) {
    setState(() {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity--;
      } else {
        _cartItems.removeAt(index);
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
  }

  void _checkout() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty!')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Processing order...'),
          ],
        ),
      ),
    );

    try {
      final orderController = Provider.of<OrderController>(context, listen: false);
      
      final order = Order(
        id: '', // Will be set by Firestore
        dateTime: DateTime.now(),
        items: _cartItems,
        subtotal: _subtotal,
        tax: _tax,
        status: 'Pending',
        customerName: 'Walk-in Customer', // Default for POS orders
        createdAt: DateTime.now(),
      );

      final success = await orderController.createOrder(order);
      
      // Dismiss loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (success) {
        // Store values before clearing cart for the success dialog
        final orderTotal = _total;
        final orderItemCount = _totalItemCount;
        
        _clearCart();
        
        if (mounted) {
          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Order Completed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order has been successfully processed!'),
                  const SizedBox(height: 10),
                  Text('Total: Php ${orderTotal.toStringAsFixed(2)}'),
                  Text('Items: $orderItemCount'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );

          // Refresh product data to show updated stock
          context.read<ProductInventoryController>().loadProducts();
        }
      } else {
        if (mounted) {
          // Show error from order controller
          final errorMessage = orderController.errorMessage ?? 'Unknown error occurred';
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Order Failed'),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Dismiss loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Order Error'),
            content: Text('Failed to process order: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductInventoryController>(
      builder: (context, productController, child) {
        final products = productController.products;
        final categories = _getCategories(products);
        final filteredProducts = _getFilteredProducts(products);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Point of Sale'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                onPressed: () {
                  productController.loadProducts();
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: productController.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    // Products section
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          // Search and filters
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: const InputDecoration(
                                      hintText: 'Search products...',
                                      prefixIcon: Icon(Icons.search),
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                DropdownButton<String>(
                                  value: _selectedCategory,
                                  hint: const Text('Category'),
                                  items: categories.map((category) {
                                    return DropdownMenuItem(
                                      value: category,
                                      child: Text(category),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Products grid
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16.0),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 16.0,
                                mainAxisSpacing: 16.0,
                                childAspectRatio: 0.8,
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                final isOutOfStock = product.currentStock <= 0;
                                final isLowStock = product.isLowStock && !isOutOfStock;
                                
                                return Card(
                                  elevation: 4,
                                  child: InkWell(
                                    onTap: isOutOfStock ? null : () => _addToCart(product),
                                    child: Stack(
                                      children: [
                                        Opacity(
                                          opacity: isOutOfStock ? 0.5 : 1.0,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius: const BorderRadius.vertical(
                                                      top: Radius.circular(8),
                                                    ),
                                                  ),
                                                  child: (product.imageUrl?.isNotEmpty ?? false)
                                                      ? ClipRRect(
                                                          borderRadius: const BorderRadius.vertical(
                                                            top: Radius.circular(8),
                                                          ),
                                                          child: Image.network(
                                                            product.imageUrl!,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (context, error, stackTrace) {
                                                              return const Icon(
                                                                Icons.image_not_supported,
                                                                size: 50,
                                                              );
                                                            },
                                                          ),
                                                        )
                                                      : const Icon(
                                                          Icons.fastfood,
                                                          size: 50,
                                                        ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      product.name,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          'Php ${product.sellingPrice.toStringAsFixed(2)}',
                                                          style: TextStyle(
                                                            color: Theme.of(context).primaryColor,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Stock: ${product.currentStock.toInt()}',
                                                          style: TextStyle(
                                                            color: isOutOfStock 
                                                                ? Colors.red 
                                                                : isLowStock 
                                                                    ? Colors.orange 
                                                                    : Colors.green,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Out of stock overlay
                                        if (isOutOfStock)
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.7),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'OUT OF\nSTOCK',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        // Low stock indicator
                                        if (isLowStock)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'LOW',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Cart section
                    Container(
                      width: 350,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border(
                          left: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.shopping_cart,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Cart ($_totalItemCount items)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (_cartItems.isNotEmpty)
                                  IconButton(
                                    onPressed: _clearCart,
                                    icon: const Icon(
                                      Icons.clear_all,
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Cart items
                          Expanded(
                            child: _cartItems.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.shopping_cart_outlined,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Cart is empty',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _cartItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _cartItems[index];
                                      return ListTile(
                                        title: Text(item.productName),
                                        subtitle: Text('Php ${item.price.toStringAsFixed(2)}'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              onPressed: () => _removeFromCart(index),
                                              icon: const Icon(Icons.remove),
                                            ),
                                            Text(
                                              '${item.quantity}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                // Find the product from the controller
                                                final productController = Provider.of<ProductInventoryController>(context, listen: false);
                                                final product = productController.products.firstWhere(
                                                  (p) => p.id == item.productId,
                                                  orElse: () => ProductInventory(
                                                    id: item.productId,
                                                    name: item.productName,
                                                    description: '',
                                                    category: 'Unknown',
                                                    currentStock: 1,
                                                    minimumStock: 0,
                                                    maximumStock: 100,
                                                    sellingPrice: item.price,
                                                    productionCost: 0,
                                                    recipe: [],
                                                    productionTime: '0',
                                                    createdAt: DateTime.now(),
                                                    updatedAt: DateTime.now(),
                                                  ),
                                                );
                                                _addToCart(product);
                                              },
                                              icon: const Icon(Icons.add),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          // Order summary and checkout
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Subtotal:'),
                                    Text('Php ${_subtotal.toStringAsFixed(2)}'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Tax (10%):'),
                                    Text('Php ${_tax.toStringAsFixed(2)}'),
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
                                      'Php ${_total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _cartItems.isEmpty ? null : _checkout,
                                    child: const Text(
                                      'Checkout',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
