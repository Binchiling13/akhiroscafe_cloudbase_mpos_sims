import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import 'firestore_service.dart';

class UserService {
  static const String _collection = 'users';

  // Get all users
  static Future<List<AppUser>> getAllUsers() async {
    try {
      final snapshot = await FirestoreService.getCollection(collection: _collection);
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users: ${e.toString()}');
    }
  }

  // Get user by ID
  static Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await FirestoreService.getDocument(
        collection: _collection,
        documentId: userId,
      );

      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  // Get user by email
  static Future<AppUser?> getUserByEmail(String email) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return AppUser.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user by email: ${e.toString()}');
    }
  }

  // Create user
  static Future<AppUser> createUser(AppUser user) async {
    try {
      // Create Firebase Auth user first
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: user.email,
        password: 'password123', // You should generate or require a password
      );

      final userId = credential.user!.uid;

      // Update the user with the Firebase Auth UID
      final updatedUser = user.copyWith(
        id: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await FirestoreService.addDocument(
        collection: _collection,
        documentId: userId,
        data: updatedUser.toMap(),
      );

      // Update Firebase Auth profile
      await credential.user!.updateDisplayName(user.displayName);

      return updatedUser;
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  // Update user
  static Future<void> updateUser(AppUser user) async {
    try {
      await FirestoreService.updateDocument(
        collection: _collection,
        documentId: user.id,
        data: user.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  // Delete user
  static Future<void> deleteUser(String userId) async {
    try {
      // Note: This only deletes from Firestore
      // Deleting from Firebase Auth requires admin privileges
      await FirestoreService.deleteDocument(
        collection: _collection,
        documentId: userId,
      );
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  // Deactivate user (soft delete)
  static Future<void> deactivateUser(String userId) async {
    try {
      await FirestoreService.updateDocument(
        collection: _collection,
        documentId: userId,
        data: {
          'isActive': false,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to deactivate user: ${e.toString()}');
    }
  }

  // Activate user
  static Future<void> activateUser(String userId) async {
    try {
      await FirestoreService.updateDocument(
        collection: _collection,
        documentId: userId,
        data: {
          'isActive': true,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to activate user: ${e.toString()}');
    }
  }

  // Update user role
  static Future<void> updateUserRole(String userId, UserRole role) async {
    try {
      await FirestoreService.updateDocument(
        collection: _collection,
        documentId: userId,
        data: {
          'role': role.value,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to update user role: ${e.toString()}');
    }
  }

  // Get active users only
  static Future<List<AppUser>> getActiveUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active users: ${e.toString()}');
    }
  }

  // Get users by role
  static Future<List<AppUser>> getUsersByRole(UserRole role) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('role', isEqualTo: role.value)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users by role: ${e.toString()}');
    }
  }

  // Stream users for real-time updates
  static Stream<List<AppUser>> streamUsers() {
    try {
      return FirebaseFirestore.instance
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => AppUser.fromMap(doc.data(), doc.id))
              .toList());
    } catch (e) {
      throw Exception('Failed to stream users: ${e.toString()}');
    }
  }

  // Initialize default admin user
  static Future<AppUser> initializeDefaultAdmin() async {
    try {
      // Check if admin exists
      final adminUsers = await getUsersByRole(UserRole.admin);
      if (adminUsers.isNotEmpty) {
        return adminUsers.first;
      }

      // Create default admin
      final defaultAdmin = AppUser(
        id: '', // Will be set by createUser
        email: 'admin@akhirocafe.com',
        displayName: 'System Administrator',
        firstName: 'System',
        lastName: 'Administrator',
        role: UserRole.admin,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await createUser(defaultAdmin);
    } catch (e) {
      throw Exception('Failed to initialize default admin: ${e.toString()}');
    }
  }

  // Reset user password (admin only)
  static Future<void> resetUserPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  // Check if current user has permission for action
  static Future<bool> hasPermission(String action) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final user = await getUserById(currentUser.uid);
      if (user == null || !user.isActive) return false;

      switch (action) {
        case 'manage_users':
        case 'manage_inventory':
        case 'view_reports':
        case 'manage_settings':
          return user.role == UserRole.admin;
        case 'access_pos':
          return true; // Both roles can access POS
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }
}
