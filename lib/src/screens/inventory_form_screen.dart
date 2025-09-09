import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory_item.dart';
import '../controllers/inventory_controller.dart';

class InventoryFormScreen extends StatefulWidget {
  final InventoryItem? item; // null for new item, existing item for editing

  const InventoryFormScreen({
    super.key,
    this.item,
  });

  @override
  State<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _currentStockController;
  late final TextEditingController _minimumStockController;
  late final TextEditingController _maximumStockController;
  late final TextEditingController _costPerUnitController;
  late final TextEditingController _supplierController;

  IngredientUnit _selectedUnit = IngredientUnit.piece;
  DateTime? _expiryDate;
  bool _isActive = true;
  bool _isLoading = false;

  final List<String> _predefinedCategories = [
    'Coffee Beans',
    'Tea Leaves',
    'Dairy Products',
    'Syrups & Sauces',
    'Pastries & Baked Goods',
    'Packaging',
    'Cleaning Supplies',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data if editing
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
    _categoryController = TextEditingController(text: widget.item?.category ?? '');
    _currentStockController = TextEditingController(text: widget.item?.currentStock.toString() ?? '0');
    _minimumStockController = TextEditingController(text: widget.item?.minimumStock.toString() ?? '0');
    _maximumStockController = TextEditingController(text: widget.item?.maximumStock.toString() ?? '100');
    _costPerUnitController = TextEditingController(text: widget.item?.costPerUnit.toString() ?? '0');
    _supplierController = TextEditingController(text: widget.item?.supplier ?? '');

    if (widget.item != null) {
      _selectedUnit = widget.item!.unit;
      _expiryDate = widget.item!.expiryDate;
      _isActive = widget.item!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _currentStockController.dispose();
    _minimumStockController.dispose();
    _maximumStockController.dispose();
    _costPerUnitController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.item != null;

  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    
    if (date != null) {
      setState(() {
        _expiryDate = date;
      });
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final inventoryController = Provider.of<InventoryController>(context, listen: false);

      final item = InventoryItem(
        id: widget.item?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        currentStock: double.parse(_currentStockController.text),
        minimumStock: double.parse(_minimumStockController.text),
        maximumStock: double.parse(_maximumStockController.text),
        unit: _selectedUnit,
        costPerUnit: double.parse(_costPerUnitController.text),
        supplier: _supplierController.text.trim(),
        expiryDate: _expiryDate,
        isActive: _isActive,
        createdAt: widget.item?.createdAt,
        updatedAt: DateTime.now(),
      );

      bool success;
      if (isEditing) {
        success = await inventoryController.updateItem(widget.item!.id, item);
      } else {
        success = await inventoryController.createItem(item);
      }

      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Item updated successfully!' : 'Item created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(inventoryController.errorMessage ?? 'An error occurred'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Inventory Item' : 'Add Inventory Item'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveItem,
              child: Text(
                isEditing ? 'UPDATE' : 'SAVE',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),
              
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Item name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Category field with dropdown
              DropdownButtonFormField<String>(
                value: _predefinedCategories.contains(_categoryController.text) 
                    ? _categoryController.text 
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _predefinedCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _categoryController.text = value;
                  }
                },
                validator: (value) {
                  if (_categoryController.text.trim().isEmpty) {
                    return 'Category is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Custom category field
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Custom Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                  helperText: 'Or enter a custom category',
                ),
              ),
              const SizedBox(height: 24),

              // Stock Information Section
              _buildSectionHeader('Stock Information'),
              const SizedBox(height: 16),

              Row(
                children: [
                  // Current Stock
                  Expanded(
                    child: TextFormField(
                      controller: _currentStockController,
                      decoration: const InputDecoration(
                        labelText: 'Current Stock *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Current stock is required';
                        }
                        final stock = double.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'Invalid stock amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Unit dropdown
                  Expanded(
                    child: DropdownButtonFormField<IngredientUnit>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.straighten),
                      ),
                      items: IngredientUnit.values.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text('${unit.fullName} (${unit.name})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedUnit = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  // Minimum Stock
                  Expanded(
                    child: TextFormField(
                      controller: _minimumStockController,
                      decoration: const InputDecoration(
                        labelText: 'Minimum Stock *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.warning),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Minimum stock is required';
                        }
                        final stock = double.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'Invalid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Maximum Stock
                  Expanded(
                    child: TextFormField(
                      controller: _maximumStockController,
                      decoration: const InputDecoration(
                        labelText: 'Maximum Stock *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.trending_up),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Maximum stock is required';
                        }
                        final stock = double.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'Invalid amount';
                        }
                        final minStock = double.tryParse(_minimumStockController.text);
                        if (minStock != null && stock < minStock) {
                          return 'Must be greater than minimum';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Financial Information Section
              _buildSectionHeader('Financial Information'),
              const SizedBox(height: 16),

              Row(
                children: [
                  // Cost per unit
                  Expanded(
                    child: TextFormField(
                      controller: _costPerUnitController,
                      decoration: const InputDecoration(
                        labelText: 'Cost per Unit *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: '₱ ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Cost per unit is required';
                        }
                        final cost = double.tryParse(value);
                        if (cost == null || cost < 0) {
                          return 'Invalid cost amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Supplier
                  Expanded(
                    child: TextFormField(
                      controller: _supplierController,
                      decoration: const InputDecoration(
                        labelText: 'Supplier',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Additional Information Section
              _buildSectionHeader('Additional Information'),
              const SizedBox(height: 16),

              // Expiry Date
              InkWell(
                onTap: _selectExpiryDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixIcon: Icon(Icons.edit),
                  ),
                  child: Text(
                    _expiryDate != null
                        ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                        : 'No expiry date set',
                    style: TextStyle(
                      color: _expiryDate != null ? null : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Active status
              SwitchListTile(
                title: const Text('Active Item'),
                subtitle: const Text('Item is available for use'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveItem,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update Item' : 'Create Item'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}
