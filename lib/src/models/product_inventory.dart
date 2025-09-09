import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeIngredient {
  final String ingredientId;
  final String ingredientName; // For display purposes
  final double quantity;
  final String unit; // Unit from the ingredient

  RecipeIngredient({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
  });

  factory RecipeIngredient.fromMap(Map<String, dynamic> data) {
    return RecipeIngredient(
      ingredientId: data['ingredientId'] ?? '',
      ingredientName: data['ingredientName'] ?? '',
      quantity: (data['quantity'] ?? 0.0).toDouble(),
      unit: data['unit'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ingredientId': ingredientId,
      'ingredientName': ingredientName,
      'quantity': quantity,
      'unit': unit,
    };
  }
}

class ProductInventory {
  final String id;
  final String name;
  final String description;
  final String category;
  final double currentStock;
  final double minimumStock;
  final double maximumStock;
  final double sellingPrice;
  final double productionCost;
  final List<RecipeIngredient> recipe; // Ingredients needed to make this product
  final String productionTime; // e.g., "5 minutes"
  final String? imageUrl;
  final DateTime? expiryDate;
  final DateTime? lastProduced;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isAvailable; // Can be sold

  ProductInventory({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.currentStock,
    required this.minimumStock,
    required this.maximumStock,
    required this.sellingPrice,
    required this.productionCost,
    required this.recipe,
    required this.productionTime,
    this.imageUrl,
    this.expiryDate,
    this.lastProduced,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.isAvailable = true,
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
    return daysUntilExpiry <= 3 && daysUntilExpiry > 0; // Products expire faster
  }

  double get totalValue => currentStock * sellingPrice;
  double get stockPercentage => maximumStock > 0 ? (currentStock / maximumStock) * 100 : 0;
  double get profitMargin => sellingPrice > 0 ? ((sellingPrice - productionCost) / sellingPrice) * 100 : 0;

  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    if (isOverStock) return 'Overstock';
    return 'In Stock';
  }

  // Check if can be produced based on ingredient availability
  bool get canBeProduce => recipe.isNotEmpty; // Will be checked against actual ingredient stock

  // Factory constructor from Firestore data
  factory ProductInventory.fromMap(Map<String, dynamic> data, String id) {
    return ProductInventory(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      currentStock: (data['currentStock'] ?? 0.0).toDouble(),
      minimumStock: (data['minimumStock'] ?? 0.0).toDouble(),
      maximumStock: (data['maximumStock'] ?? 0.0).toDouble(),
      sellingPrice: (data['sellingPrice'] ?? 0.0).toDouble(),
      productionCost: (data['productionCost'] ?? 0.0).toDouble(),
      recipe: (data['recipe'] as List<dynamic>?)
          ?.map((item) => RecipeIngredient.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      productionTime: data['productionTime'] ?? '',
      imageUrl: data['imageUrl'],
      expiryDate: _parseDateTime(data['expiryDate']),
      lastProduced: _parseDateTime(data['lastProduced']),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(data['updatedAt']) ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      isAvailable: data['isAvailable'] ?? true,
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
      'sellingPrice': sellingPrice,
      'productionCost': productionCost,
      'recipe': recipe.map((ingredient) => ingredient.toMap()).toList(),
      'productionTime': productionTime,
      'imageUrl': imageUrl,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'lastProduced': lastProduced != null ? Timestamp.fromDate(lastProduced!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'isAvailable': isAvailable,
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
  ProductInventory copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? currentStock,
    double? minimumStock,
    double? maximumStock,
    double? sellingPrice,
    double? productionCost,
    List<RecipeIngredient>? recipe,
    String? productionTime,
    String? imageUrl,
    DateTime? expiryDate,
    DateTime? lastProduced,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isAvailable,
  }) {
    return ProductInventory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      maximumStock: maximumStock ?? this.maximumStock,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      productionCost: productionCost ?? this.productionCost,
      recipe: recipe ?? this.recipe,
      productionTime: productionTime ?? this.productionTime,
      imageUrl: imageUrl ?? this.imageUrl,
      expiryDate: expiryDate ?? this.expiryDate,
      lastProduced: lastProduced ?? this.lastProduced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
