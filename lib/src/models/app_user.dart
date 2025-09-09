import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String firstName;
  final String lastName;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? phoneNumber;
  final String? profileImageUrl;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.phoneNumber,
    this.profileImageUrl,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      role: UserRole.fromString(map['role'] ?? 'cashier'),
      isActive: map['isActive'] ?? true,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'role': role.value,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? phoneNumber,
    String? profileImageUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  String get fullName => '$firstName $lastName';

  bool get canAccessAllScreens => role == UserRole.admin;
  bool get canAccessPOSOnly => role == UserRole.cashier;
  bool get canManageUsers => role == UserRole.admin;
  bool get canManageInventory => role == UserRole.admin;
  bool get canViewReports => role == UserRole.admin;
  bool get canManageSettings => role == UserRole.admin;

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, displayName: $displayName, role: ${role.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper method to parse different date formats from Firestore
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    } else if (value is DateTime) {
      return value;
    } else if (value is String) {
      return DateTime.parse(value);
    } else {
      // Handle Firestore Timestamp - convert to DateTime
      return DateTime.now();
    }
  }
}

enum UserRole {
  admin('admin', 'Administrator'),
  cashier('cashier', 'Cashier');

  const UserRole(this.value, this.displayName);

  final String value;
  final String displayName;

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'cashier':
        return UserRole.cashier;
      default:
        return UserRole.cashier; // Default to cashier for safety
    }
  }

  static List<UserRole> get allRoles => UserRole.values;

  Color get color {
    switch (this) {
      case UserRole.admin:
        return const Color(0xFF1976D2); // Blue
      case UserRole.cashier:
        return const Color(0xFF388E3C); // Green
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.cashier:
        return Icons.point_of_sale;
    }
  }
}
