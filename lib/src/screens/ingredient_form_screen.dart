import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ingredient.dart';
import '../controllers/ingredient_controller.dart';

class IngredientFormScreen extends StatefulWidget {
  final Ingredient? ingredient; // null for new ingredient, existing for edit

  const IngredientFormScreen({super.key, this.ingredient});

  @override
  State<IngredientFormScreen> createState() => _IngredientFormScreenState();
}

class _IngredientFormScreenState extends State<IngredientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _minimumStockController = TextEditingController();
  final _maximumStockController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _supplierController = TextEditingController();

  String _selectedCategory = 'Dairy';
  IngredientUnit _selectedUnit = IngredientUnit.gram;
  DateTime? _selectedExpiryDate;
  bool _isLoading = false;

  final List<String> _predefinedCategories = [
    'Dairy',
    'Meat',
    'Vegetables',
    'Fruits',
    'Spices',
    'Beverages',
    'Grains',
    'Oils',
    'Condiments',
    'Baking',
    'Cleaning',
    'Packaging',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.ingredient != null) {
      _populateFields(widget.ingredient!);
    }
  }

  void _populateFields(Ingredient ingredient) {
    _nameController.text = ingredient.name;
    _descriptionController.text = ingredient.description;
    _currentStockController.text = ingredient.currentStock.toString();
    _minimumStockController.text = ingredient.minimumStock.toString();
    _maximumStockController.text = ingredient.maximumStock.toString();
    _unitCostController.text = ingredient.unitCost.toString();
    _supplierController.text = ingredient.supplier;
    _selectedCategory = ingredient.category;
    _selectedUnit = ingredient.unit;
    _selectedExpiryDate = ingredient.expiryDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _currentStockController.dispose();
    _minimumStockController.dispose();
    _maximumStockController.dispose();
    _unitCostController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ingredient == null ? 'Add Ingredient' : 'Edit Ingredient'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.ingredient != null)
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
                    _buildSectionTitle('Basic Information'),
                    _buildNameField(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 16),
                    _buildCategoryField(),
                    const SizedBox(height: 16),
                    _buildSupplierField(),
                    const SizedBox(height: 24),

                    // Stock Information
                    _buildSectionTitle('Stock Information'),
                    _buildUnitField(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildCurrentStockField()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildUnitCostField()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildMinimumStockField()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMaximumStockField()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Expiry Information
                    _buildSectionTitle('Expiry Information'),
                    _buildExpiryDateField(),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveIngredient,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          widget.ingredient == null ? 'Add Ingredient' : 'Update Ingredient',
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
        labelText: 'Ingredient Name',
        prefixIcon: Icon(Icons.eco),
        border: OutlineInputBorder(),
        hintText: 'e.g., Fresh Milk, Ground Coffee',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter ingredient name';
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
        hintText: 'Brief description of the ingredient',
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

  Widget _buildSupplierField() {
    return TextFormField(
      controller: _supplierController,
      decoration: const InputDecoration(
        labelText: 'Supplier',
        prefixIcon: Icon(Icons.business),
        border: OutlineInputBorder(),
        hintText: 'e.g., ABC Dairy, Local Market',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter supplier name';
        }
        return null;
      },
    );
  }

  Widget _buildUnitField() {
    return DropdownButtonFormField<IngredientUnit>(
      value: _selectedUnit,
      decoration: const InputDecoration(
        labelText: 'Unit of Measurement',
        prefixIcon: Icon(Icons.straighten),
        border: OutlineInputBorder(),
      ),
      items: IngredientUnit.values.map((unit) {
        return DropdownMenuItem(
          value: unit,
          child: Text('${unit.name} (${unit.symbol})'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedUnit = value!;
        });
      },
    );
  }

  Widget _buildCurrentStockField() {
    return TextFormField(
      controller: _currentStockController,
      decoration: const InputDecoration(
        labelText: 'Current Stock',
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

  Widget _buildUnitCostField() {
    return TextFormField(
      controller: _unitCostController,
      decoration: const InputDecoration(
        labelText: 'Unit Cost (₱)',
        prefixIcon: Icon(Icons.attach_money),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter unit cost';
        }
        final cost = double.tryParse(value);
        if (cost == null || cost < 0) {
          return 'Please enter valid unit cost';
        }
        return null;
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
      initialDate: _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() {
        _selectedExpiryDate = date;
      });
    }
  }

  Future<void> _saveIngredient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final ingredient = Ingredient(
        id: widget.ingredient?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        currentStock: double.parse(_currentStockController.text),
        minimumStock: double.parse(_minimumStockController.text),
        maximumStock: double.parse(_maximumStockController.text),
        unit: _selectedUnit,
        unitCost: double.parse(_unitCostController.text),
        supplier: _supplierController.text.trim(),
        expiryDate: _selectedExpiryDate,
        lastRestocked: widget.ingredient?.lastRestocked,
        createdAt: widget.ingredient?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final controller = context.read<IngredientController>();
      bool success;

      if (widget.ingredient == null) {
        success = await controller.createIngredient(ingredient);
      } else {
        success = await controller.updateIngredient(widget.ingredient!.id, ingredient);
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ingredient == null
                  ? 'Ingredient added successfully'
                  : 'Ingredient updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save ingredient'),
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
        title: const Text('Delete Ingredient'),
        content: Text('Are you sure you want to delete ${widget.ingredient!.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _deleteIngredient,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteIngredient() async {
    Navigator.pop(context); // Close dialog

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = context.read<IngredientController>();
      final success = await controller.deleteIngredient(widget.ingredient!.id);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingredient deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete ingredient'),
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
