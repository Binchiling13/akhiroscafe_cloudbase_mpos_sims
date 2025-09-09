import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final int stockQuantity;
  final String sku;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.stockQuantity,
    required this.sku,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  // Convert Product to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'stockQuantity': stockQuantity,
      'sku': sku,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create Product from Firestore document
  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    return Product(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      stockQuantity: map['stockQuantity'] ?? 0,
      sku: map['sku'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null ? _parseDateTime(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? _parseDateTime(map['updatedAt']) : null,
    );
  }

  // Helper method to parse DateTime from various formats
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
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    int? stockQuantity,
    String? sku,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      sku: sku ?? this.sku,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Mock data for demonstration
  static List<Product> getMockProducts() {
    return [
      Product(
        id: '1',
        name: 'Espresso',
        description: 'Rich and bold espresso shot',
        price: 2.50,
        category: 'Coffee',
        imageUrl: 'assets/images/flutter_logo.png',
        stockQuantity: 100,
        sku: 'ESP001',
      ),
      Product(
        id: '2',
        name: 'Cappuccino',
        description: 'Creamy cappuccino with foam art',
        price: 4.50,
        category: 'Coffee',
        imageUrl: 'assets/images/flutter_logo.png',
        stockQuantity: 85,
        sku: 'CAP001',
      ),
      Product(
        id: '3',
        name: 'Americano',
        description: 'Smooth americano coffee',
        price: 3.25,
        category: 'Coffee',
        imageUrl: 'assets/images/flutter_logo.png',
        stockQuantity: 120,
        sku: 'AME001',
      ),
      Product(
        id: '4',
        name: 'Latte',
        description: 'Creamy latte with steamed milk',
        price: 4.75,
        category: 'Coffee',
        imageUrl: 'assets/images/flutter_logo.png',
        stockQuantity: 90,
        sku: 'LAT001',
      ),
      Product(
        id: '5',
        name: 'Croissant',
        description: 'Buttery and flaky croissant',
        price: 3.00,
        category: 'Pastry',
        imageUrl: 'assets/images/flutter_logo.png',
        stockQuantity: 45,
        sku: 'CRO001',
      ),
      Product(
        id: '6',
        name: 'Chocolate Muffin',
        description: 'Rich chocolate chip muffin',
        price: 2.75,
        category: 'Pastry',
        imageUrl: 'assets/images/flutter_logo.png',
        stockQuantity: 30,
        sku: 'MUF001',
      ),
      Product(
        id: '7',
        name: 'Green Tea',
        description: 'Premium green tea',
        price: 2.25,
        category: 'Tea',
        imageUrl: 'assets/images/flutter_logo.png',
        stockQuantity: 200,
        sku: 'TEA001',
      ),
      Product(
        id: '8',
        name: 'Sandwich',
        description: 'Fresh deli sandwich',
        price: 7.50,
        category: 'Food',
        imageUrl: 'assets/images/flutter_logo.png',
        stockQuantity: 25,
        sku: 'SAN001',
      ),
    ];
  }
}
