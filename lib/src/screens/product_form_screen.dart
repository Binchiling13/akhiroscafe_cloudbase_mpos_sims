import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_inventory.dart';
import '../models/ingredient.dart';
import '../controllers/product_inventory_controller.dart';
import '../controllers/ingredient_controller.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductInventory? product; // null for new product, existing for edit

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _minimumStockController = TextEditingController();
  final _maximumStockController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _productionCostController = TextEditingController();
  final _productionTimeController = TextEditingController();

  String _selectedCategory = 'Beverages';
  DateTime? _selectedExpiryDate;
  bool _isAvailable = true;
  bool _isLoading = false;
  List<RecipeIngredient> _recipe = [];
  List<Ingredient> _availableIngredients = [];

  final List<String> _predefinedCategories = [
    'Beverages',
    'Coffee',
    'Tea',
    'Pastries',
    'Sandwiches',
    'Desserts',
    'Snacks',
    'Breakfast',
    'Lunch',
    'Dinner',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIngredients();
    });
    if (widget.product != null) {
      _populateFields(widget.product!);
    }
  }

  Future<void> _loadIngredients() async {
    final ingredientController = context.read<IngredientController>();
    await ingredientController.loadIngredients();
    if (mounted) {
      setState(() {
        _availableIngredients = ingredientController.ingredients;
      });
    }
  }

  void _populateFields(ProductInventory product) {
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _currentStockController.text = product.currentStock.toString();
    _minimumStockController.text = product.minimumStock.toString();
    _maximumStockController.text = product.maximumStock.toString();
    _sellingPriceController.text = product.sellingPrice.toString();
    _productionCostController.text = product.productionCost.toString();
    _productionTimeController.text = product.productionTime;
    _selectedCategory = product.category;
    _selectedExpiryDate = product.expiryDate;
    _isAvailable = product.isAvailable;
    _recipe = List.from(product.recipe);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _currentStockController.dispose();
    _minimumStockController.dispose();
    _maximumStockController.dispose();
    _sellingPriceController.dispose();
    _productionCostController.dispose();
    _productionTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.product != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _showDeleteDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information
                    _buildSectionTitle('Product Information'),
                    _buildNameField(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 16),
                    _buildCategoryField(),
                    const SizedBox(height: 16),
                    _buildProductionTimeField(),
                    const SizedBox(height: 24),

                    // Pricing Information
                    _buildSectionTitle('Pricing & Cost'),
                    Row(
                      children: [
                        Expanded(child: _buildSellingPriceField()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildProductionCostField()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stock Information
                    _buildSectionTitle('Stock Information'),
                    _buildCurrentStockField(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildMinimumStockField()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMaximumStockField()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recipe Information
                    _buildSectionTitle('Recipe'),
                    _buildRecipeSection(),
                    const SizedBox(height: 24),

                    // Settings
                    _buildSectionTitle('Settings'),
                    _buildAvailabilityField(),
                    const SizedBox(height: 16),
                    _buildExpiryDateField(),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProduct,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          widget.product == null ? 'Add Product' : 'Update Product',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Product Name',
        prefixIcon: Icon(Icons.inventory_2),
        border: OutlineInputBorder(),
        hintText: 'e.g., Cappuccino, Chocolate Cake',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter product name';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description',
        prefixIcon: Icon(Icons.description),
        border: OutlineInputBorder(),
        hintText: 'Brief description of the product',
      ),
      maxLines: 2,
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
      ),
      items: _predefinedCategories.map((category) {
        return DropdownMenuItem(value: category, child: Text(category));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
    );
  }

  Widget _buildProductionTimeField() {
    return TextFormField(
      controller: _productionTimeController,
      decoration: const InputDecoration(
        labelText: 'Production Time',
        prefixIcon: Icon(Icons.schedule),
        border: OutlineInputBorder(),
        hintText: 'e.g., 5 minutes, 30 minutes',
      ),
    );
  }

  Widget _buildSellingPriceField() {
    return TextFormField(
      controller: _sellingPriceController,
      decoration: const InputDecoration(
        labelText: 'Selling Price (₱)',
        prefixIcon: Icon(Icons.attach_money),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter selling price';
        }
        final price = double.tryParse(value);
        if (price == null || price < 0) {
          return 'Please enter valid price';
        }
        return null;
      },
    );
  }

  Widget _buildProductionCostField() {
    return TextFormField(
      controller: _productionCostController,
      decoration: const InputDecoration(
        labelText: 'Production Cost (₱)',
        prefixIcon: Icon(Icons.calculate),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter production cost';
        }
        final cost = double.tryParse(value);
        if (cost == null || cost < 0) {
          return 'Please enter valid cost';
        }
        return null;
      },
    );
  }

  Widget _buildCurrentStockField() {
    return TextFormField(
      controller: _currentStockController,
      decoration: const InputDecoration(
        labelText: 'Current Stock (units)',
        prefixIcon: Icon(Icons.inventory),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter current stock';
        }
        final stock = double.tryParse(value);
        if (stock == null || stock < 0) {
          return 'Please enter valid stock amount';
        }
        return null;
      },
    );
  }

  Widget _buildMinimumStockField() {
    return TextFormField(
      controller: _minimumStockController,
      decoration: const InputDecoration(
        labelText: 'Minimum Stock',
        prefixIcon: Icon(Icons.warning),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter minimum stock';
        }
        final stock = double.tryParse(value);
        if (stock == null || stock < 0) {
          return 'Please enter valid minimum stock';
        }
        return null;
      },
    );
  }

  Widget _buildMaximumStockField() {
    return TextFormField(
      controller: _maximumStockController,
      decoration: const InputDecoration(
        labelText: 'Maximum Stock',
        prefixIcon: Icon(Icons.trending_up),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter maximum stock';
        }
        final stock = double.tryParse(value);
        if (stock == null || stock < 0) {
          return 'Please enter valid maximum stock';
        }
        final minStock = double.tryParse(_minimumStockController.text);
        if (minStock != null && stock < minStock) {
          return 'Maximum stock must be greater than minimum stock';
        }
        return null;
      },
    );
  }

  Widget _buildRecipeSection() {
    return Column(
      children: [
        // Recipe ingredients list
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              ListTile(
                title: const Text('Recipe Ingredients'),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addRecipeIngredient,
                ),
              ),
              if (_recipe.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No ingredients added yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ..._recipe.asMap().entries.map((entry) {
                  final index = entry.key;
                  final ingredient = entry.value;
                  return ListTile(
                    title: Text(ingredient.ingredientName),
                    subtitle: Text('${ingredient.quantity} ${ingredient.unit}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeRecipeIngredient(index),
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityField() {
    return SwitchListTile(
      title: const Text('Available for Sale'),
      subtitle: const Text('Toggle product availability'),
      value: _isAvailable,
      onChanged: (value) {
        setState(() {
          _isAvailable = value;
        });
      },
    );
  }

  Widget _buildExpiryDateField() {
    return InkWell(
      onTap: _selectExpiryDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Expiry Date (Optional)',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        child: Text(
          _selectedExpiryDate == null
              ? 'No expiry date set'
              : '${_selectedExpiryDate!.day}/${_selectedExpiryDate!.month}/${_selectedExpiryDate!.year}',
        ),
      ),
    );
  }

  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedExpiryDate = date;
      });
    }
  }

  void _addRecipeIngredient() {
    if (_availableIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No ingredients available. Please add ingredients first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _RecipeIngredientDialog(
        availableIngredients: _availableIngredients,
        onAdd: (recipeIngredient) {
          setState(() {
            _recipe.add(recipeIngredient);
          });
        },
      ),
    );
  }

  void _removeRecipeIngredient(int index) {
    setState(() {
      _recipe.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final product = ProductInventory(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        currentStock: double.parse(_currentStockController.text),
        minimumStock: double.parse(_minimumStockController.text),
        maximumStock: double.parse(_maximumStockController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        productionCost: double.parse(_productionCostController.text),
        recipe: _recipe,
        productionTime: _productionTimeController.text.trim(),
        expiryDate: _selectedExpiryDate,
        lastProduced: widget.product?.lastProduced,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isAvailable: _isAvailable,
      );

      final controller = context.read<ProductInventoryController>();
      bool success;

      if (widget.product == null) {
        success = await controller.createProduct(product);
      } else {
        success = await controller.updateProduct(widget.product!.id, product);
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null
                  ? 'Product added successfully'
                  : 'Product updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save product'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${widget.product!.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _deleteProduct,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct() async {
    Navigator.pop(context); // Close dialog

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = context.read<ProductInventoryController>();
      final success = await controller.deleteProduct(widget.product!.id);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete product'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// Dialog for adding recipe ingredients
class _RecipeIngredientDialog extends StatefulWidget {
  final List<Ingredient> availableIngredients;
  final Function(RecipeIngredient) onAdd;

  const _RecipeIngredientDialog({
    required this.availableIngredients,
    required this.onAdd,
  });

  @override
  State<_RecipeIngredientDialog> createState() => _RecipeIngredientDialogState();
}

class _RecipeIngredientDialogState extends State<_RecipeIngredientDialog> {
  Ingredient? _selectedIngredient;
  final _quantityController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Recipe Ingredient'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<Ingredient>(
            value: _selectedIngredient,
            decoration: const InputDecoration(
              labelText: 'Select Ingredient',
              border: OutlineInputBorder(),
            ),
            items: widget.availableIngredients.map((ingredient) {
              return DropdownMenuItem(
                value: ingredient,
                child: Text('${ingredient.name} (${ingredient.unit.symbol})'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedIngredient = value;
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantityController,
            decoration: InputDecoration(
              labelText: 'Quantity',
              suffixText: _selectedIngredient?.unit.symbol ?? '',
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addIngredient,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _addIngredient() {
    if (_selectedIngredient == null || _quantityController.text.trim().isEmpty) {
      return;
    }

    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      return;
    }

    final recipeIngredient = RecipeIngredient(
      ingredientId: _selectedIngredient!.id,
      ingredientName: _selectedIngredient!.name,
      quantity: quantity,
      unit: _selectedIngredient!.unit.symbol,
    );

    widget.onAdd(recipeIngredient);
    Navigator.pop(context);
  }
}
