import 'package:cloud_firestore/cloud_firestore.dart';

enum IngredientUnit {
  gram,
  kilogram,
  piece,
  liter,
  milliliter,
  cup,
  tablespoon,
  teaspoon,
}

extension IngredientUnitExtension on IngredientUnit {
  String get name {
    switch (this) {
      case IngredientUnit.gram:
        return 'g';
      case IngredientUnit.kilogram:
        return 'kg';
      case IngredientUnit.piece:
        return 'pcs';
      case IngredientUnit.liter:
        return 'L';
      case IngredientUnit.milliliter:
        return 'mL';
      case IngredientUnit.cup:
        return 'cup';
      case IngredientUnit.tablespoon:
        return 'tbsp';
      case IngredientUnit.teaspoon:
        return 'tsp';
    }
  }

  String get fullName {
    switch (this) {
      case IngredientUnit.gram:
        return 'Grams';
      case IngredientUnit.kilogram:
        return 'Kilograms';
      case IngredientUnit.piece:
        return 'Pieces';
      case IngredientUnit.liter:
        return 'Liters';
      case IngredientUnit.milliliter:
        return 'Milliliters';
      case IngredientUnit.cup:
        return 'Cups';
      case IngredientUnit.tablespoon:
        return 'Tablespoons';
      case IngredientUnit.teaspoon:
        return 'Teaspoons';
    }
  }
}

class InventoryItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final double currentStock;
  final double minimumStock;
  final double maximumStock;
  final IngredientUnit unit;
  final double costPerUnit;
  final String supplier;
  final DateTime? expiryDate;
  final DateTime? lastRestocked;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InventoryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.currentStock,
    required this.minimumStock,
    required this.maximumStock,
    required this.unit,
    required this.costPerUnit,
    this.supplier = '',
    this.expiryDate,
    this.lastRestocked,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  bool get isLowStock => currentStock <= minimumStock;
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final daysDifference = expiryDate!.difference(now).inDays;
    return daysDifference <= 7 && daysDifference >= 0;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  double get totalValue => currentStock * costPerUnit;

  // Convert InventoryItem to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'maximumStock': maximumStock,
      'unit': unit.name,
      'costPerUnit': costPerUnit,
      'supplier': supplier,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'lastRestocked': lastRestocked != null ? Timestamp.fromDate(lastRestocked!) : null,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create InventoryItem from Firestore document
  factory InventoryItem.fromMap(Map<String, dynamic> map, String documentId) {
    return InventoryItem(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      currentStock: (map['currentStock'] ?? 0.0).toDouble(),
      minimumStock: (map['minimumStock'] ?? 0.0).toDouble(),
      maximumStock: (map['maximumStock'] ?? 0.0).toDouble(),
      unit: _parseUnit(map['unit']),
      costPerUnit: (map['costPerUnit'] ?? 0.0).toDouble(),
      supplier: map['supplier'] ?? '',
      expiryDate: map['expiryDate'] != null ? _parseDateTime(map['expiryDate']) : null,
      lastRestocked: map['lastRestocked'] != null ? _parseDateTime(map['lastRestocked']) : null,
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null ? _parseDateTime(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? _parseDateTime(map['updatedAt']) : null,
    );
  }

  static IngredientUnit _parseUnit(dynamic value) {
    if (value is String) {
      for (var unit in IngredientUnit.values) {
        if (unit.name == value) return unit;
      }
    }
    return IngredientUnit.piece; // Default fallback
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is DateTime) {
      return value;
    } else {
      return DateTime.now();
    }
  }

  // Create a copy with updated fields
  InventoryItem copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? currentStock,
    double? minimumStock,
    double? maximumStock,
    IngredientUnit? unit,
    double? costPerUnit,
    String? supplier,
    DateTime? expiryDate,
    DateTime? lastRestocked,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      maximumStock: maximumStock ?? this.maximumStock,
      unit: unit ?? this.unit,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      supplier: supplier ?? this.supplier,
      expiryDate: expiryDate ?? this.expiryDate,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
