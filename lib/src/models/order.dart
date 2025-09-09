import 'cart_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final DateTime dateTime;
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final String status;
  final String? customerName;
  final String? customerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Order({
    required this.id,
    required this.dateTime,
    required this.items,
    required this.subtotal,
    required this.tax,
    this.discount = 0.0,
    this.status = 'Pending',
    this.customerName,
    this.customerId,
    this.createdAt,
    this.updatedAt,
  });

  double get total => subtotal + tax - discount;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  // Convert Order to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': Timestamp.fromDate(dateTime),
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'status': status,
      'customerName': customerName,
      'customerId': customerId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create Order from Firestore document
  factory Order.fromMap(Map<String, dynamic> map, String documentId) {
    return Order(
      id: documentId,
      dateTime: _parseDateTime(map['dateTime']),
      items: (map['items'] as List<dynamic>? ?? [])
          .map((item) => CartItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      tax: (map['tax'] ?? 0.0).toDouble(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Pending',
      customerName: map['customerName'],
      customerId: map['customerId'],
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
  Order copyWith({
    String? id,
    DateTime? dateTime,
    List<CartItem>? items,
    double? subtotal,
    double? tax,
    double? discount,
    String? status,
    String? customerName,
    String? customerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      customerId: customerId ?? this.customerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Mock data for demonstration
  static List<Order> getMockOrders() {
    return [
      Order(
        id: 'ORD001',
        dateTime: DateTime.now().subtract(const Duration(hours: 1)),
        items: [
          CartItem(
            productId: '1',
            productName: 'Espresso',
            price: 2.50,
            quantity: 2,
            imageUrl: 'assets/images/flutter_logo.png',
          ),
          CartItem(
            productId: '5',
            productName: 'Croissant',
            price: 3.00,
            quantity: 1,
            imageUrl: 'assets/images/flutter_logo.png',
          ),
        ],
        subtotal: 8.00,
        tax: 0.80,
        customerName: 'John Doe',
      ),
      Order(
        id: 'ORD002',
        dateTime: DateTime.now().subtract(const Duration(hours: 2)),
        items: [
          CartItem(
            productId: '2',
            productName: 'Cappuccino',
            price: 4.50,
            quantity: 1,
            imageUrl: 'assets/images/flutter_logo.png',
          ),
        ],
        subtotal: 4.50,
        tax: 0.45,
        customerName: 'Jane Smith',
      ),
      Order(
        id: 'ORD003',
        dateTime: DateTime.now().subtract(const Duration(hours: 3)),
        items: [
          CartItem(
            productId: '4',
            productName: 'Latte',
            price: 4.75,
            quantity: 2,
            imageUrl: 'assets/images/flutter_logo.png',
          ),
          CartItem(
            productId: '6',
            productName: 'Chocolate Muffin',
            price: 2.75,
            quantity: 2,
            imageUrl: 'assets/images/flutter_logo.png',
          ),
        ],
        subtotal: 15.00,
        tax: 1.50,
        discount: 2.00,
        customerName: 'Mike Johnson',
      ),
    ];
  }
}
