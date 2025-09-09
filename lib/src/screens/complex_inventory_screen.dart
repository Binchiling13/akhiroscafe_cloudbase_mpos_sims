import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/ingredient_controller.dart';
import '../controllers/product_inventory_controller.dart';
import '../models/product_inventory.dart';
import '../services/product_inventory_service.dart';
import 'ingredient_form_screen.dart';
import 'product_form_screen.dart';
import 'production_screen.dart';

class ComplexInventoryScreen extends StatefulWidget {
  const ComplexInventoryScreen({super.key});

  @override
  State<ComplexInventoryScreen> createState() => _ComplexInventoryScreenState();
}

class _ComplexInventoryScreenState extends State<ComplexInventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2), text: 'Products'),
            Tab(icon: Icon(Icons.eco), text: 'Ingredients'),
            Tab(icon: Icon(Icons.precision_manufacturing), text: 'Production'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ProductInventoryTab(),
          IngredientInventoryTab(),
          ProductionTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 0: // Products tab
        return FloatingActionButton(
          onPressed: () => _navigateToAddProduct(),
          tooltip: 'Add Product',
          child: const Icon(Icons.add),
        );
      case 1: // Ingredients tab
        return FloatingActionButton(
          onPressed: () => _navigateToAddIngredient(),
          tooltip: 'Add Ingredient',
          child: const Icon(Icons.add),
        );
      case 2: // Production tab
        return FloatingActionButton(
          onPressed: () => _navigateToProduction(),
          tooltip: 'Production Center',
          child: const Icon(Icons.precision_manufacturing),
        );
      default:
        return FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        );
    }
  }

  void _navigateToAddIngredient() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IngredientFormScreen(),
      ),
    );
  }

  void _navigateToAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProductFormScreen(),
      ),
    );
  }

  void _navigateToProduction() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProductionScreen(),
      ),
    );
  }
}

// Ingredients Tab
class IngredientInventoryTab extends StatefulWidget {
  const IngredientInventoryTab({super.key});

  @override
  State<IngredientInventoryTab> createState() => _IngredientInventoryTabState();
}

class _IngredientInventoryTabState extends State<IngredientInventoryTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load data after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<IngredientController>().loadIngredients();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Consumer<IngredientController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Statistics Cards
            _buildIngredientStats(context, controller),

            // Filters
            _buildIngredientFilters(context, controller),

            // Ingredient List
            Expanded(
              child: controller.filteredIngredients.isEmpty
                  ? const Center(
                      child: Text(
                        'No ingredients found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: controller.filteredIngredients.length,
                      itemBuilder: (context, index) {
                        final ingredient =
                            controller.filteredIngredients[index];
                        return _buildIngredientCard(
                            context, ingredient, controller);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIngredientStats(
      BuildContext context, IngredientController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              controller.ingredients.length.toString(),
              Icons.eco,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Low Stock',
              controller.lowStockCount.toString(),
              Icons.warning,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Out of Stock',
              controller.outOfStockCount.toString(),
              Icons.error,
              Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Expiring',
              controller.expiringCount.toString(),
              Icons.schedule,
              Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientFilters(
      BuildContext context, IngredientController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search ingredients...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: controller.searchIngredients,
          ),
          const SizedBox(height: 8),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Category filter
                _buildFilterChip(
                  'Category: ${controller.selectedCategory}',
                  () => _showCategoryPicker(context, controller),
                ),
                const SizedBox(width: 8),

                // Supplier filter
                _buildFilterChip(
                  'Supplier: ${controller.selectedSupplier}',
                  () => _showSupplierPicker(context, controller),
                ),
                const SizedBox(width: 8),

                // Status filter
                _buildFilterChip(
                  'Status: ${controller.statusFilter}',
                  () => _showStatusPicker(context, controller),
                ),
                const SizedBox(width: 8),

                // Clear filters
                if (controller.searchQuery.isNotEmpty ||
                    controller.selectedCategory != 'All' ||
                    controller.selectedSupplier != 'All' ||
                    controller.statusFilter != 'All')
                  ElevatedButton(
                    onPressed: controller.clearFilters,
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientCard(
      BuildContext context, ingredient, IngredientController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getIngredientStatusColor(ingredient),
          child: Icon(
            Icons.eco,
            color: Colors.white,
          ),
        ),
        title: Text(
          ingredient.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${ingredient.currentStock} ${ingredient.unit.symbol}'),
            Text('${ingredient.category} • ${ingredient.supplier}'),
            if (ingredient.isLowStock)
              Text(
                'Low Stock!',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            if (ingredient.isExpiringSoon)
              Text(
                'Expiring Soon!',
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () =>
                  _showQuantityDialog(context, ingredient, false, controller),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green),
              onPressed: () =>
                  _showQuantityDialog(context, ingredient, true, controller),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editIngredient(context, ingredient),
            ),
          ],
        ),
      ),
    );
  }

  Color _getIngredientStatusColor(ingredient) {
    if (ingredient.isOutOfStock) return Colors.red;
    if (ingredient.isLowStock) return Colors.orange;
    if (ingredient.isExpiringSoon) return Colors.amber;
    return Colors.green;
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        backgroundColor: Colors.grey.shade200,
      ),
    );
  }

  void _showCategoryPicker(
      BuildContext context, IngredientController controller) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Category'),
        children: controller.categories.map((category) {
          return SimpleDialogOption(
            onPressed: () {
              controller.filterByCategory(category);
              Navigator.pop(context);
            },
            child: Text(category),
          );
        }).toList(),
      ),
    );
  }

  void _showSupplierPicker(
      BuildContext context, IngredientController controller) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Supplier'),
        children: controller.suppliers.map((supplier) {
          return SimpleDialogOption(
            onPressed: () {
              controller.filterBySupplier(supplier);
              Navigator.pop(context);
            },
            child: Text(supplier),
          );
        }).toList(),
      ),
    );
  }

  void _showStatusPicker(
      BuildContext context, IngredientController controller) {
    final statuses = [
      'All',
      'Low Stock',
      'Out of Stock',
      'Expiring',
      'Expired'
    ];
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Status'),
        children: statuses.map((status) {
          return SimpleDialogOption(
            onPressed: () {
              controller.filterByStatus(status);
              Navigator.pop(context);
            },
            child: Text(status),
          );
        }).toList(),
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, ingredient, bool isIncrement,
      IngredientController controller) {
    final TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isIncrement ? 'Add' : 'Remove'} ${ingredient.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Current Stock: ${ingredient.currentStock.toStringAsFixed(1)} ${ingredient.unit.displayName}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity to ${isIncrement ? 'add' : 'remove'}',
                hintText: 'Enter quantity',
                suffixText: ingredient.unit.displayName,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            if (!isIncrement)
              Text(
                'Maximum you can remove: ${ingredient.currentStock.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantityText = quantityController.text.trim();
              if (quantityText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a quantity')),
                );
                return;
              }

              final quantity = double.tryParse(quantityText);
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter a valid positive number')),
                );
                return;
              }

              if (!isIncrement && quantity > ingredient.currentStock) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Cannot remove more than current stock')),
                );
                return;
              }

              final adjustment = isIncrement ? quantity : -quantity;
              controller.adjustStock(ingredient.id, adjustment,
                  reason:
                      '${isIncrement ? 'Added' : 'Removed'} $quantity ${ingredient.unit.displayName} manually');

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${isIncrement ? 'Added' : 'Removed'} $quantity ${ingredient.unit.displayName} ${isIncrement ? 'to' : 'from'} ${ingredient.name}'),
                  backgroundColor: isIncrement ? Colors.green : Colors.orange,
                ),
              );
            },
            child: Text(isIncrement ? 'Add' : 'Remove'),
          ),
        ],
      ),
    );
  }

  void _adjustIngredientStock(BuildContext context, String ingredientId,
      double adjustment, IngredientController controller) {
    controller.adjustStock(ingredientId, adjustment,
        reason: 'Manual adjustment');
  }

  void _editIngredient(BuildContext context, ingredient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IngredientFormScreen(ingredient: ingredient),
      ),
    );
  }
}

// Products Tab (similar structure to ingredients)
class ProductInventoryTab extends StatefulWidget {
  const ProductInventoryTab({super.key});

  @override
  State<ProductInventoryTab> createState() => _ProductInventoryTabState();
}

class _ProductInventoryTabState extends State<ProductInventoryTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load data after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductInventoryController>().loadProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Consumer<ProductInventoryController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Statistics Cards
            _buildProductStats(context, controller),

            // Filters
            _buildProductFilters(context, controller),

            // Product List
            Expanded(
              child: controller.filteredProducts.isEmpty
                  ? const Center(
                      child: Text(
                        'No products found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: controller.filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = controller.filteredProducts[index];
                        return _buildProductCard(context, product, controller);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductStats(
      BuildContext context, ProductInventoryController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              controller.products.length.toString(),
              Icons.inventory_2,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Low Stock',
              controller.lowStockCount.toString(),
              Icons.warning,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Value',
              '₱${controller.totalValue.toStringAsFixed(0)}',
              Icons.attach_money,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductFilters(
      BuildContext context, ProductInventoryController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: controller.searchProducts,
          ),
          const SizedBox(height: 8),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Category filter
                _buildFilterChip(
                  'Category: ${controller.selectedCategory}',
                  () => _showCategoryPicker(context, controller),
                ),
                const SizedBox(width: 8),

                // Status filter
                _buildFilterChip(
                  'Status: ${controller.statusFilter}',
                  () => _showStatusPicker(context, controller),
                ),
                const SizedBox(width: 8),

                // Clear filters
                if (controller.searchQuery.isNotEmpty ||
                    controller.selectedCategory != 'All' ||
                    controller.statusFilter != 'All')
                  ElevatedButton(
                    onPressed: controller.clearFilters,
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, product, ProductInventoryController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getProductStatusColor(product),
          child: Icon(
            Icons.inventory_2,
            color: Colors.white,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock: ${product.currentStock.toInt()} units'),
            Text('Price: ₱${product.sellingPrice.toStringAsFixed(2)}'),
            Text('Recipe: ${product.recipe.length} ingredients'),
            if (product.isLowStock)
              Text(
                'Low Stock!',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editProduct(context, product),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProductStatusColor(product) {
    if (product.isOutOfStock) return Colors.red;
    if (product.isLowStock) return Colors.orange;
    if (product.isExpiringSoon) return Colors.amber;
    return Colors.green;
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        backgroundColor: Colors.grey.shade200,
      ),
    );
  }

  void _showCategoryPicker(
      BuildContext context, ProductInventoryController controller) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Category'),
        children: controller.categories.map((category) {
          return SimpleDialogOption(
            onPressed: () {
              controller.filterByCategory(category);
              Navigator.pop(context);
            },
            child: Text(category),
          );
        }).toList(),
      ),
    );
  }

  void _showStatusPicker(
      BuildContext context, ProductInventoryController controller) {
    final statuses = [
      'All',
      'Low Stock',
      'Out of Stock',
      'Expiring',
      'Available'
    ];
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Status'),
        children: statuses.map((status) {
          return SimpleDialogOption(
            onPressed: () {
              controller.filterByStatus(status);
              Navigator.pop(context);
            },
            child: Text(status),
          );
        }).toList(),
      ),
    );
  }

  void _editProduct(BuildContext context, product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: product),
      ),
    );
  }
}

// Production Tab
class ProductionTab extends StatefulWidget {
  const ProductionTab({super.key});

  @override
  State<ProductionTab> createState() => _ProductionTabState();
}

class _ProductionTabState extends State<ProductionTab>
    with AutomaticKeepAliveClientMixin {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

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
      final matchesCategory =
          _selectedCategory == 'All' || product.category == _selectedCategory;
      final matchesSearch = _searchController.text.isEmpty ||
          product.name
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _produceProduct(ProductInventory product) async {
    final TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Produce ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Current Stock: ${product.currentStock.toStringAsFixed(0)} units'),
            Text(
                'Production Cost: Php ${product.productionCost.toStringAsFixed(2)} per unit'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity to produce',
                hintText: 'Enter quantity',
                suffixText: 'units',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Recipe Requirements:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...product.recipe
                .map((ingredient) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Text(
                        '• ${ingredient.quantity} ${ingredient.unit} ${ingredient.ingredientName}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ))
                .toList(),
            if (product.recipe.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'No recipe defined',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantityText = quantityController.text.trim();
              if (quantityText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a quantity')),
                );
                return;
              }

              final quantity = int.tryParse(quantityText);
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter a valid positive number')),
                );
                return;
              }

              // Check if we can produce the requested quantity
              final canProduce =
                  await ProductInventoryService.canProduceProduct(
                      product.id, quantity);
              if (!canProduce) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Insufficient ingredients to produce the requested quantity'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Store navigator reference before closing dialog
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final productController =
                  context.read<ProductInventoryController>();
              final ingredientController = context.read<IngredientController>();

              navigator.pop();

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text('Producing...'),
                    ],
                  ),
                ),
              );

              try {
                final success = await ProductInventoryService.produceProduct(
                    product.id, quantity);

                // Dismiss loading dialog
                if (mounted) navigator.pop();

                if (success && mounted) {
                  final totalCost = product.productionCost * quantity;
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                          'Successfully produced $quantity units of ${product.name}\n'
                          'Total production cost: Php ${totalCost.toStringAsFixed(2)}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                  // Reload data to reflect changes
                  productController.loadProducts();
                  ingredientController.loadIngredients();
                } else if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Failed to produce product. Check ingredient availability.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                // Dismiss loading dialog
                if (mounted) navigator.pop();

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Production error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Produce'),
          ),
        ],
      ),
    );
  }

  Future<bool> _canProduceProduct(ProductInventory product) async {
    // Check if we can produce at least 1 unit
    return await ProductInventoryService.canProduceProduct(product.id, 1);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer2<ProductInventoryController, IngredientController>(
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
                            'Add products in the Products tab first',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: (product.imageUrl?.isNotEmpty ?? false)
                  ? ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(8)),
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
                    onPressed:
                        canProduce ? () => _produceProduct(product) : null,
                    icon: const Icon(Icons.add_circle, size: 16),
                    label:
                        const Text('Produce', style: TextStyle(fontSize: 12)),
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
