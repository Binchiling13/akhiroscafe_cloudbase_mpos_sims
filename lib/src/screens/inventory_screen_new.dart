import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory_item.dart';
import '../controllers/inventory_controller.dart';
import 'inventory_form_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load inventory items when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryController>().loadItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _navigateToForm({InventoryItem? item}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => InventoryFormScreen(item: item),
      ),
    );

    if (result == true && mounted) {
      // Refresh the inventory list
      context.read<InventoryController>().refreshItems();
    }
  }

  void _showStockAdjustmentDialog(InventoryItem item) {
    final adjustmentController = TextEditingController();
    final reasonController = TextEditingController();
    bool isAddition = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Adjust Stock - ${item.name}'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Current Stock: ${item.currentStock} ${item.unit.name}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Add Stock'),
                            value: true,
                            groupValue: isAddition,
                            onChanged: (value) {
                              setState(() {
                                isAddition = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Remove Stock'),
                            value: false,
                            groupValue: isAddition,
                            onChanged: (value) {
                              setState(() {
                                isAddition = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: adjustmentController,
                      decoration: InputDecoration(
                        labelText: 'Amount to ${isAddition ? 'Add' : 'Remove'}',
                        border: const OutlineInputBorder(),
                        suffixText: item.unit.name,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final adjustmentText = adjustmentController.text.trim();
                    if (adjustmentText.isEmpty) return;

                    final adjustment = double.tryParse(adjustmentText);
                    if (adjustment == null || adjustment <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid amount')),
                      );
                      return;
                    }

                    final finalAdjustment = isAddition ? adjustment : -adjustment;
                    final reason = reasonController.text.trim().isEmpty 
                        ? (isAddition ? 'Stock addition' : 'Stock removal')
                        : reasonController.text.trim();

                    Navigator.of(context).pop();

                    final inventoryController = context.read<InventoryController>();
                    final success = await inventoryController.adjustStock(
                      item.id,
                      finalAdjustment,
                      reason: reason,
                    );

                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Stock adjusted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(inventoryController.errorMessage ?? 'Failed to adjust stock'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Adjust Stock'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteItem(InventoryItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: Text('Are you sure you want to delete "${item.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                final inventoryController = context.read<InventoryController>();
                final success = await inventoryController.deleteItem(item.id);

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Item deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(inventoryController.errorMessage ?? 'Failed to delete item'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryController>(
      builder: (context, inventoryController, child) {
        final filteredItems = inventoryController.filteredItems;
        final stats = inventoryController.inventoryStats;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Inventory Management'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => inventoryController.refreshItems(),
                tooltip: 'Refresh Inventory',
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _navigateToForm(),
                tooltip: 'Add New Item',
              ),
            ],
          ),
          body: Column(
            children: [
              // Statistics Cards
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Items',
                        stats['totalItems'].toString(),
                        Icons.inventory,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Low Stock',
                        stats['lowStockItems'].toString(),
                        Icons.warning,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Expiring',
                        stats['expiringItems'].toString(),
                        Icons.schedule,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        'Total Value',
                        '₱${stats['totalValue'].toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              // Filters and Search
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    // Search field
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search items...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          inventoryController.setSearchQuery(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Category filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: inventoryController.selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: inventoryController.categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            inventoryController.setCategory(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Sort dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: inventoryController.sortBy,
                        decoration: const InputDecoration(
                          labelText: 'Sort By',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Name', child: Text('Name')),
                          DropdownMenuItem(value: 'Category', child: Text('Category')),
                          DropdownMenuItem(value: 'Stock', child: Text('Stock')),
                          DropdownMenuItem(value: 'Cost', child: Text('Cost')),
                          DropdownMenuItem(value: 'Low Stock', child: Text('Low Stock First')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            inventoryController.setSortBy(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Inventory List
              Expanded(
                child: inventoryController.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : inventoryController.errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Error: ${inventoryController.errorMessage}',
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => inventoryController.refreshItems(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : filteredItems.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inventory, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'No inventory items found',
                                      style: TextStyle(fontSize: 18, color: Colors.grey),
                                    ),
                                    Text(
                                      'Add some items to get started',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                itemCount: filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  return _buildInventoryItemCard(item);
                                },
                              ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
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

  Widget _buildInventoryItemCard(InventoryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Status indicators
                          if (item.isLowStock)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'LOW STOCK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (item.isExpired)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'EXPIRED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (item.isExpiringSoon && !item.isExpired)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'EXPIRING SOON',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.category,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _navigateToForm(item: item);
                        break;
                      case 'adjust':
                        _showStockAdjustmentDialog(item);
                        break;
                      case 'delete':
                        _confirmDeleteItem(item);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'adjust',
                      child: Row(
                        children: [
                          Icon(Icons.tune),
                          SizedBox(width: 8),
                          Text('Adjust Stock'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stock information
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Current Stock',
                    '${item.currentStock} ${item.unit.name}',
                    item.isLowStock ? Colors.orange : Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Min Stock',
                    '${item.minimumStock} ${item.unit.name}',
                    Colors.grey,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Cost/Unit',
                    '₱${item.costPerUnit.toStringAsFixed(2)}',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Total Value',
                    '₱${item.totalValue.toStringAsFixed(2)}',
                    Colors.purple,
                  ),
                ),
              ],
            ),

            if (item.supplier.isNotEmpty || item.expiryDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (item.supplier.isNotEmpty)
                    Expanded(
                      child: _buildInfoItem(
                        'Supplier',
                        item.supplier,
                        Colors.indigo,
                      ),
                    ),
                  if (item.expiryDate != null)
                    Expanded(
                      child: _buildInfoItem(
                        'Expiry Date',
                        '${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}',
                        item.isExpired 
                            ? Colors.red 
                            : item.isExpiringSoon 
                                ? Colors.orange 
                                : Colors.green,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
