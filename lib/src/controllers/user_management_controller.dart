import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';

class UserManagementController extends ChangeNotifier {
  List<AppUser> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  AppUser? _selectedUser;

  // Getters
  List<AppUser> get users => _users;
  List<AppUser> get activeUsers => _users.where((user) => user.isActive).toList();
  List<AppUser> get inactiveUsers => _users.where((user) => !user.isActive).toList();
  List<AppUser> get adminUsers => _users.where((user) => user.role == UserRole.admin).toList();
  List<AppUser> get cashierUsers => _users.where((user) => user.role == UserRole.cashier).toList();
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppUser? get selectedUser => _selectedUser;

  UserManagementController() {
    loadUsers();
  }

  // Load all users
  Future<void> loadUsers() async {
    _setLoading(true);
    _clearError();

    try {
      _users = await UserService.getAllUsers();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Create new user
  Future<bool> createUser({
    required String email,
    required String firstName,
    required String lastName,
    required UserRole role,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final newUser = AppUser(
        id: '', // Will be set by the service
        email: email,
        displayName: '$firstName $lastName',
        firstName: firstName,
        lastName: lastName,
        role: role,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        phoneNumber: phoneNumber,
      );

      final createdUser = await UserService.createUser(newUser);
      _users.add(createdUser);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update user
  Future<bool> updateUser(AppUser user) async {
    _setLoading(true);
    _clearError();

    try {
      await UserService.updateUser(user);
      
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user;
        if (_selectedUser?.id == user.id) {
          _selectedUser = user;
        }
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      await UserService.deleteUser(userId);
      _users.removeWhere((user) => user.id == userId);
      
      if (_selectedUser?.id == userId) {
        _selectedUser = null;
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Deactivate user
  Future<bool> deactivateUser(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      await UserService.deactivateUser(userId);
      
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(
          isActive: false,
          updatedAt: DateTime.now(),
        );
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Activate user
  Future<bool> activateUser(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      await UserService.activateUser(userId);
      
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(
          isActive: true,
          updatedAt: DateTime.now(),
        );
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update user role
  Future<bool> updateUserRole(String userId, UserRole role) async {
    _setLoading(true);
    _clearError();

    try {
      await UserService.updateUserRole(userId, role);
      
      final index = _users.indexWhere((user) => user.id == userId);
      if (index != -1) {
        _users[index] = _users[index].copyWith(
          role: role,
          updatedAt: DateTime.now(),
        );
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Reset user password
  Future<bool> resetUserPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await UserService.resetUserPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Select user for editing
  void selectUser(AppUser? user) {
    _selectedUser = user;
    notifyListeners();
  }

  // Clear selection
  void clearSelection() {
    _selectedUser = null;
    notifyListeners();
  }

  // Search users
  List<AppUser> searchUsers(String query) {
    if (query.trim().isEmpty) {
      return _users;
    }

    final lowercaseQuery = query.toLowerCase();
    return _users.where((user) {
      return user.displayName.toLowerCase().contains(lowercaseQuery) ||
             user.email.toLowerCase().contains(lowercaseQuery) ||
             user.firstName.toLowerCase().contains(lowercaseQuery) ||
             user.lastName.toLowerCase().contains(lowercaseQuery) ||
             user.role.displayName.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Filter users by role
  List<AppUser> filterUsersByRole(UserRole? role) {
    if (role == null) {
      return _users;
    }
    return _users.where((user) => user.role == role).toList();
  }

  // Filter users by status
  List<AppUser> filterUsersByStatus(bool? isActive) {
    if (isActive == null) {
      return _users;
    }
    return _users.where((user) => user.isActive == isActive).toList();
  }

  // Get user statistics
  Map<String, int> getUserStatistics() {
    return {
      'total': _users.length,
      'active': activeUsers.length,
      'inactive': inactiveUsers.length,
      'admins': adminUsers.length,
      'cashiers': cashierUsers.length,
    };
  }

  // Check if email already exists
  bool isEmailExists(String email, {String? excludeUserId}) {
    return _users.any((user) => 
        user.email.toLowerCase() == email.toLowerCase() && 
        user.id != excludeUserId);
  }

  // Refresh users
  Future<void> refreshUsers() async {
    await loadUsers();
  }

  // Helper methods
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
}
