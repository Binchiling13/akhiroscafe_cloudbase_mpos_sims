import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_inventory_controller.dart';
import '../controllers/ingredient_controller.dart';
import '../models/product_inventory.dart';
import '../services/product_inventory_service.dart';

class ProductionPage extends StatefulWidget {
  const ProductionPage({super.key});

  @override
  State<ProductionPage> createState() => _ProductionPageState();
}

class _ProductionPageState extends State<ProductionPage> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductInventoryController>().loadProducts();
      context.read<IngredientController>().loadIngredients();
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
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _produceProduct(ProductInventory product) async {
    final TextEditingController quantityController = TextEditingController();
    int quantity = 1;

    // Show production dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Produce ${product.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Stock: ${product.currentStock}'),
                const SizedBox(height: 16),
                
                // Recipe display
                Text('Recipe Required:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (product.recipe.isNotEmpty)
                  ...product.recipe.map((recipeIngredient) =>
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('• ${recipeIngredient.ingredientId}: ${recipeIngredient.quantity * quantity}'),
                    )
                  )
                else
                  const Text('• No recipe defined'),
                
                const SizedBox(height: 16),
                
                // Quantity input
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity to Produce',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      quantity = int.tryParse(value) ?? 1;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Production cost
                Text('Production Cost: \$${(product.productionCost * quantity).toStringAsFixed(2)}'),
                
                const SizedBox(height: 8),
                
                // Ingredient availability check
                FutureBuilder<bool>(
                  future: ProductInventoryService.canProduceProduct(product.id, quantity),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final canProduce = snapshot.data!;
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: canProduce ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: canProduce ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              canProduce ? Icons.check_circle : Icons.error,
                              color: canProduce ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                canProduce 
                                  ? 'Ingredients available'
                                  : 'Insufficient ingredients',
                                style: TextStyle(
                                  color: canProduce ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FutureBuilder<bool>(
              future: ProductInventoryService.canProduceProduct(product.id, quantity),
              builder: (context, snapshot) {
                final canProduce = snapshot.data ?? false;
                return ElevatedButton(
                  onPressed: canProduce && quantity > 0
                    ? () => Navigator.of(context).pop(true)
                    : null,
                  child: const Text('Produce'),
                );
              },
            ),
          ],
        ),
      ),
    );

    if (result == true && quantity > 0) {
      try {
        final success = await ProductInventoryService.produceProduct(product.id, quantity);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully produced $quantity units of ${product.name}'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload data to reflect changes
          context.read<ProductInventoryController>().loadProducts();
          context.read<IngredientController>().loadIngredients();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to produce product. Check ingredient availability.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<bool> _canProduceProduct(ProductInventory product) async {
    return await ProductInventoryService.canProduceProduct(product.id, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Production Center'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              context.read<ProductInventoryController>().loadProducts();
              context.read<IngredientController>().loadIngredients();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Consumer2<ProductInventoryController, IngredientController>(
        builder: (context, productController, ingredientController, child) {
          if (productController.isLoading || ingredientController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = productController.products;
          final categories = _getCategories(products);
          final filteredProducts = _getFilteredProducts(products);

          return Column(
            children: [
              // Statistics row
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Products',
                        products.length.toString(),
                        Icons.inventory_2,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Low Stock',
                        products.where((p) => p.isLowStock).length.toString(),
                        Icons.warning,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Out of Stock',
                        products.where((p) => p.isOutOfStock).length.toString(),
                        Icons.error,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Ingredients',
                        ingredientController.ingredients.length.toString(),
                        Icons.breakfast_dining,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              // Search and filter row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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

              const SizedBox(height: 16),

              // Products grid
              Expanded(
                child: filteredProducts.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.production_quantity_limits,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add products in the Inventory section first',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _buildProductionCard(product);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductionCard(ProductInventory product) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: (product.imageUrl?.isNotEmpty ?? false)
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.fastfood, size: 50);
                        },
                      ),
                    )
                  : const Icon(Icons.fastfood, size: 50),
            ),
          ),

          // Product details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: ${product.currentStock.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: product.isLowStock ? Colors.red : Colors.green,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Price: Php ${product.sellingPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Cost: Php ${product.productionCost.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),

          // Production button
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              child: FutureBuilder<bool>(
                future: _canProduceProduct(product),
                builder: (context, snapshot) {
                  final canProduce = snapshot.data ?? false;
                  return ElevatedButton.icon(
                    onPressed: canProduce ? () => _produceProduct(product) : null,
                    icon: const Icon(Icons.add_circle, size: 16),
                    label: const Text('Produce', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canProduce ? Colors.green : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
