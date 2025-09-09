import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessProfile {
  final String id;
  final String businessName;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String description;
  final String logoUrl;
  final String currency;
  final double taxRate;
  final Map<String, String> operatingHours; // day -> "09:00-17:00"
  final bool autoPrintReceipts;
  final bool lowStockAlerts;
  final int lowStockThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessProfile({
    required this.id,
    required this.businessName,
    required this.address,
    required this.phone,
    required this.email,
    this.website = '',
    this.description = '',
    this.logoUrl = '',
    this.currency = 'PHP',
    this.taxRate = 0.10,
    Map<String, String>? operatingHours,
    this.autoPrintReceipts = true,
    this.lowStockAlerts = true,
    this.lowStockThreshold = 10,
    required this.createdAt,
    required this.updatedAt,
  }) : operatingHours = operatingHours ?? {
    'Monday': '08:00-18:00',
    'Tuesday': '08:00-18:00',
    'Wednesday': '08:00-18:00',
    'Thursday': '08:00-18:00',
    'Friday': '08:00-18:00',
    'Saturday': '08:00-20:00',
    'Sunday': '09:00-17:00',
  };

  // Create BusinessProfile from Firestore document
  factory BusinessProfile.fromMap(Map<String, dynamic> data, String id) {
    return BusinessProfile(
      id: id,
      businessName: data['businessName'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      website: data['website'] ?? '',
      description: data['description'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      currency: data['currency'] ?? 'PHP',
      taxRate: (data['taxRate'] ?? 0.10).toDouble(),
      operatingHours: Map<String, String>.from(data['operatingHours'] ?? {}),
      autoPrintReceipts: data['autoPrintReceipts'] ?? true,
      lowStockAlerts: data['lowStockAlerts'] ?? true,
      lowStockThreshold: data['lowStockThreshold'] ?? 10,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert BusinessProfile to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'description': description,
      'logoUrl': logoUrl,
      'currency': currency,
      'taxRate': taxRate,
      'operatingHours': operatingHours,
      'autoPrintReceipts': autoPrintReceipts,
      'lowStockAlerts': lowStockAlerts,
      'lowStockThreshold': lowStockThreshold,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create a copy with updated fields
  BusinessProfile copyWith({
    String? id,
    String? businessName,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? description,
    String? logoUrl,
    String? currency,
    double? taxRate,
    Map<String, String>? operatingHours,
    bool? autoPrintReceipts,
    bool? lowStockAlerts,
    int? lowStockThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      currency: currency ?? this.currency,
      taxRate: taxRate ?? this.taxRate,
      operatingHours: operatingHours ?? this.operatingHours,
      autoPrintReceipts: autoPrintReceipts ?? this.autoPrintReceipts,
      lowStockAlerts: lowStockAlerts ?? this.lowStockAlerts,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get formatted operating hours
  String getFormattedOperatingHours(String day) {
    return operatingHours[day] ?? 'Closed';
  }

  // Check if open on a specific day
  bool isOpenOn(String day) {
    final hours = operatingHours[day];
    return hours != null && hours.toLowerCase() != 'closed';
  }

  // Get tax rate as percentage
  String get taxRatePercentage => '${(taxRate * 100).toStringAsFixed(1)}%';
}
