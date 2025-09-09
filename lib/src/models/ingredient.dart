import 'package:cloud_firestore/cloud_firestore.dart';

enum IngredientUnit {
  gram('g'),
  kilogram('kg'),
  pound('lb'),
  ounce('oz'),
  liter('L'),
  milliliter('mL'),
  cup('cup'),
  tablespoon('tbsp'),
  teaspoon('tsp'),
  piece('pcs'),
  bottle('bottle'),
  pack('pack'),
  bag('bag'),
  box('box');

  const IngredientUnit(this.symbol);
  final String symbol;

  String get displayName {
    switch (this) {
      case IngredientUnit.gram:
        return 'grams';
      case IngredientUnit.kilogram:
        return 'kilograms';
      case IngredientUnit.pound:
        return 'pounds';
      case IngredientUnit.ounce:
        return 'ounces';
      case IngredientUnit.liter:
        return 'liters';
      case IngredientUnit.milliliter:
        return 'milliliters';
      case IngredientUnit.cup:
        return 'cups';
      case IngredientUnit.tablespoon:
        return 'tablespoons';
      case IngredientUnit.teaspoon:
        return 'teaspoons';
      case IngredientUnit.piece:
        return 'pieces';
      case IngredientUnit.bottle:
        return 'bottles';
      case IngredientUnit.pack:
        return 'packs';
      case IngredientUnit.bag:
        return 'bags';
      case IngredientUnit.box:
        return 'boxes';
    }
  }

  @override
  String toString() => symbol;
}

class Ingredient {
  final String id;
  final String name;
  final String description;
  final String category;
  final double currentStock;
  final double minimumStock;
  final double maximumStock;
  final IngredientUnit unit;
  final double unitCost;
  final String supplier;
  final DateTime? expiryDate;
  final DateTime? lastRestocked;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Ingredient({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.currentStock,
    required this.minimumStock,
    required this.maximumStock,
    required this.unit,
    required this.unitCost,
    required this.supplier,
    this.expiryDate,
    this.lastRestocked,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Computed properties
  bool get isLowStock => currentStock <= minimumStock;
  bool get isOutOfStock => currentStock <= 0;
  bool get isOverStock => currentStock >= maximumStock;
  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate!.difference(now).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
  }

  double get totalValue => currentStock * unitCost;
  double get stockPercentage => maximumStock > 0 ? (currentStock / maximumStock) * 100 : 0;

  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    if (isOverStock) return 'Overstock';
    return 'In Stock';
  }

  // Factory constructor from Firestore data
  factory Ingredient.fromMap(Map<String, dynamic> data, String id) {
    return Ingredient(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      currentStock: (data['currentStock'] ?? 0.0).toDouble(),
      minimumStock: (data['minimumStock'] ?? 0.0).toDouble(),
      maximumStock: (data['maximumStock'] ?? 0.0).toDouble(),
      unit: IngredientUnit.values.firstWhere(
        (unit) => unit.name == data['unit'],
        orElse: () => IngredientUnit.gram,
      ),
      unitCost: (data['unitCost'] ?? 0.0).toDouble(),
      supplier: data['supplier'] ?? '',
      expiryDate: _parseDateTime(data['expiryDate']),
      lastRestocked: _parseDateTime(data['lastRestocked']),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']) ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'maximumStock': maximumStock,
      'unit': unit.name,
      'unitCost': unitCost,
      'supplier': supplier,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'lastRestocked': lastRestocked != null ? Timestamp.fromDate(lastRestocked!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  // Helper method to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  // Copy with method
  Ingredient copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? currentStock,
    double? minimumStock,
    double? maximumStock,
    IngredientUnit? unit,
    double? unitCost,
    String? supplier,
    DateTime? expiryDate,
    DateTime? lastRestocked,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      maximumStock: maximumStock ?? this.maximumStock,
      unit: unit ?? this.unit,
      unitCost: unitCost ?? this.unitCost,
      supplier: supplier ?? this.supplier,
      expiryDate: expiryDate ?? this.expiryDate,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
