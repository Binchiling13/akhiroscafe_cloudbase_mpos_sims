import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_inventory_controller.dart';
import '../controllers/ingredient_controller.dart';
import '../models/product_inventory.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductInventoryController>().loadProducts();
      context.read<IngredientController>().loadIngredients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Production Center'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.trending_up), text: 'Recommendations'),
                Tab(icon: Icon(Icons.precision_manufacturing), text: 'Production'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildRecommendationsTab(),
                  _buildProductionTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    return Consumer<ProductInventoryController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final lowStockProducts = controller.products
            .where((product) => product.isLowStock)
            .toList();

        return Column(
          children: [
            // Statistics
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Low Stock Items',
                      lowStockProducts.length.toString(),
                      Icons.warning,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Products',
                      controller.products.length.toString(),
                      Icons.inventory_2,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            // Recommendations list
            Expanded(
              child: lowStockProducts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 64,
                            color: Colors.green,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'All products are well stocked!',
                            style: TextStyle(fontSize: 18, color: Colors.green),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: lowStockProducts.length,
                      itemBuilder: (context, index) {
                        final product = lowStockProducts[index];
                        return _buildRecommendationCard(product, controller);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductionTab() {
    return Consumer<ProductInventoryController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.products.length,
          itemBuilder: (context, index) {
            final product = controller.products[index];
            return _buildProductionCard(product, controller);
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(ProductInventory product, ProductInventoryController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: const Icon(Icons.warning, color: Colors.white),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Stock: ${product.currentStock.toInt()} units'),
            Text('Minimum Stock: ${product.minimumStock.toInt()} units'),
            Text('Recipe: ${product.recipe.length} ingredients'),
            Text('Production Time: ${product.productionTime}'),
          ],
        ),
        trailing: ElevatedButton.icon(
          onPressed: () => _showProductionDialog(product, controller),
          icon: const Icon(Icons.precision_manufacturing),
          label: const Text('Produce'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProductionCard(ProductInventory product, ProductInventoryController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getProductStatusColor(product),
          child: const Icon(Icons.inventory_2, color: Colors.white),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Stock: ${product.currentStock.toInt()} units'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${product.category}'),
                Text('Selling Price: ₱${product.sellingPrice.toStringAsFixed(2)}'),
                Text('Production Cost: ₱${product.productionCost.toStringAsFixed(2)}'),
                Text('Production Time: ${product.productionTime}'),
                const SizedBox(height: 8),
                
                if (product.recipe.isNotEmpty) ...[
                  const Text(
                    'Recipe:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...product.recipe.map((ingredient) => 
                    Text('• ${ingredient.ingredientName}: ${ingredient.quantity} ${ingredient.unit}')
                  ).toList(),
                ],
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showProductionDialog(product, controller),
                        icon: const Icon(Icons.precision_manufacturing),
                        label: const Text('Produce'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showIngredientRequirements(product),
                        icon: const Icon(Icons.list),
                        label: const Text('Ingredients'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getProductStatusColor(ProductInventory product) {
    if (product.isOutOfStock) return Colors.red;
    if (product.isLowStock) return Colors.orange;
    return Colors.green;
  }

  void _showProductionDialog(ProductInventory product, ProductInventoryController controller) {
    final quantityController = TextEditingController(text: '1');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Produce ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How many units would you like to produce?'),
            const SizedBox(height: 16),
            TextFormField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
                suffixText: 'units',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text(
              'This will consume ingredients according to the recipe.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _produceProduct(
              product, 
              int.tryParse(quantityController.text) ?? 1, 
              controller,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Produce'),
          ),
        ],
      ),
    );
  }

  void _showIngredientRequirements(ProductInventory product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${product.name} - Ingredients Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: product.recipe.isEmpty
              ? [const Text('No recipe defined for this product.')]
              : product.recipe.map((ingredient) => 
                  ListTile(
                    leading: const Icon(Icons.eco),
                    title: Text(ingredient.ingredientName),
                    subtitle: Text('${ingredient.quantity} ${ingredient.unit}'),
                  )
                ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _produceProduct(ProductInventory product, int quantity, ProductInventoryController controller) async {
    Navigator.pop(context); // Close dialog

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Producing...'),
          ],
        ),
      ),
    );

    try {
      final success = await controller.produceProduct(
        product.id, 
        quantity, 
        reason: 'Manual production',
      );

      Navigator.pop(context); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully produced $quantity units of ${product.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Production failed. Check ingredient availability.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
