import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/firestore_service.dart';
import '../models/app_user.dart';

class AuthController extends ChangeNotifier {
  User? _firebaseUser;
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get firebaseUser => _firebaseUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null && _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin && _currentUser?.isActive == true;
  bool get isCashier => _currentUser?.role == UserRole.cashier && _currentUser?.isActive == true;
  bool get isActiveUser => _currentUser?.isActive == true;

  AuthController() {
    // Listen to Firebase Auth state changes
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  // Handle Firebase Auth state changes
  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    
    if (user != null) {
      // User is logged in, load their profile
      await _loadUserProfile(user.uid);
    } else {
      // User is logged out, clear profile
      _currentUser = null;
    }
    
    notifyListeners();
  }

  // Load user profile from Firestore
  Future<void> _loadUserProfile(String userId) async {
    try {
      _currentUser = await UserService.getUserById(userId);
      
      // If user profile doesn't exist, create a default admin profile
      if (_currentUser == null && _firebaseUser != null) {
        print('No user profile found, creating default admin profile...');
        await _createDefaultUserProfile(_firebaseUser!);
      }
      
      _clearError();
    } catch (e) {
      print('Error loading user profile: ${e.toString()}');
      
      // If error loading profile, try to create default profile
      if (_firebaseUser != null) {
        try {
          await _createDefaultUserProfile(_firebaseUser!);
        } catch (createError) {
          _setError('Failed to load user profile: ${e.toString()}');
          _currentUser = null;
        }
      } else {
        _setError('Failed to load user profile: ${e.toString()}');
        _currentUser = null;
      }
    }
  }

  // Create default user profile when none exists
  Future<void> _createDefaultUserProfile(User firebaseUser) async {
    try {
      print('Creating default user profile for: ${firebaseUser.email}');
      
      // Create a default admin user profile
      final defaultUser = AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? 'Admin User',
        firstName: firebaseUser.displayName?.split(' ').first ?? 'Admin',
        lastName: firebaseUser.displayName?.split(' ').last ?? 'User',
        role: UserRole.admin, // Default to admin
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        phoneNumber: firebaseUser.phoneNumber,
      );

      // Save to Firestore using the existing service
      await FirestoreService.addDocument(
        collection: 'users',
        documentId: firebaseUser.uid,
        data: defaultUser.toMap(),
      );

      _currentUser = defaultUser;
      print('Default admin profile created successfully');
    } catch (e) {
      print('Error creating default user profile: ${e.toString()}');
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  // Sign in method
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      UserCredential? result = await AuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result != null) {
        // User profile will be loaded automatically by _onAuthStateChanged
        _setLoading(false);
        return true;
      }
      
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  // Register method
  Future<bool> register(String email, String password, String displayName) async {
    _setLoading(true);
    _clearError();

    try {
      UserCredential? result = await AuthService.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      
      if (result != null) {
        // User profile will be loaded automatically by _onAuthStateChanged
        _setLoading(false);
        return true;
      }
      
      _setLoading(false);
      return false;
    } catch (e) {
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  // Sign out method
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await AuthService.signOut();
      _firebaseUser = null;
      _currentUser = null;
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  // Reset password method
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Check if current user can access a specific screen
  bool canAccessScreen(String screenName) {
    if (_currentUser == null || !_currentUser!.isActive) {
      return false;
    }

    switch (screenName.toLowerCase()) {
      case 'pos':
        return true; // Both admin and cashier can access POS
      case 'dashboard':
      case 'orders':
      case 'inventory':
      case 'users':
      case 'settings':
        return _currentUser!.role == UserRole.admin;
      default:
        return false;
    }
  }

  // Get available screens for current user
  List<String> getAvailableScreens() {
    if (_currentUser == null || !_currentUser!.isActive) {
      return [];
    }

    if (_currentUser!.role == UserRole.admin) {
      return ['dashboard', 'pos', 'orders', 'inventory', 'users', 'settings'];
    } else if (_currentUser!.role == UserRole.cashier) {
      return ['pos'];
    }

    return [];
  }

  // Refresh current user profile
  Future<void> refreshUserProfile() async {
    if (_firebaseUser != null) {
      print('Refreshing user profile...');
      await _loadUserProfile(_firebaseUser!.uid);
    }
  }

  // Force reload user profile (useful after role changes)
  Future<void> forceRefreshUserProfile() async {
    if (_firebaseUser != null) {
      _setLoading(true);
      print('Force refreshing user profile...');
      await _loadUserProfile(_firebaseUser!.uid);
      _setLoading(false);
    }
  }

  // Debug method to make current user admin (for testing)
  Future<void> makeCurrentUserAdmin() async {
    if (_currentUser != null) {
      try {
        final updatedUser = _currentUser!.copyWith(
          role: UserRole.admin,
          updatedAt: DateTime.now(),
        );
        
        await FirestoreService.updateDocument(
          collection: 'users',
          documentId: _currentUser!.id,
          data: updatedUser.toMap(),
        );
        
        _currentUser = updatedUser;
        notifyListeners();
        print('User role updated to admin successfully');
      } catch (e) {
        print('Failed to update user role: ${e.toString()}');
      }
    }
  }

  // Debug method to check current user status
  void debugPrintUserStatus() {
    print('=== User Debug Info ===');
    print('Firebase User: ${_firebaseUser?.email}');
    print('App User: ${_currentUser?.email}');
    print('Role: ${_currentUser?.role}');
    print('Is Admin: $isAdmin');
    print('Is Cashier: $isCashier');
    print('Is Active: $isActiveUser');
    print('Is Authenticated: $isAuthenticated');
    print('======================');
  }
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  String _getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many login attempts. Please try again later.';
        default:
          return 'Login failed: ${error.message}';
      }
    }
    return error.toString();
  }
}
