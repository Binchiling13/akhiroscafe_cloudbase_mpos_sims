import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';

class RoleBasedAccessService {
  static AppUser? _currentAppUser;
  
  // Get current app user with role information
  static Future<AppUser?> getCurrentAppUser() async {
    if (_currentAppUser != null) {
      return _currentAppUser;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    try {
      _currentAppUser = await UserService.getUserById(firebaseUser.uid);
      return _currentAppUser;
    } catch (e) {
      return null;
    }
  }

  // Check if current user has permission for specific action
  static Future<bool> hasPermission(String permission) async {
    final user = await getCurrentAppUser();
    if (user == null || !user.isActive) {
      return false;
    }

    switch (permission) {
      case 'access_pos':
        return true; // Both admin and cashier can access POS
      
      case 'manage_users':
      case 'manage_inventory':
      case 'manage_products':
      case 'view_reports':
      case 'manage_settings':
      case 'manage_business_profile':
      case 'cancel_orders':
      case 'view_financial_data':
        return user.role == UserRole.admin;
      
      case 'process_orders':
      case 'view_products':
      case 'view_customers':
        return true; // Both roles can do these
      
      default:
        return false;
    }
  }

  // Check if current user is admin
  static Future<bool> isAdmin() async {
    final user = await getCurrentAppUser();
    return user?.role == UserRole.admin && user?.isActive == true;
  }

  // Check if current user is cashier
  static Future<bool> isCashier() async {
    final user = await getCurrentAppUser();
    return user?.role == UserRole.cashier && user?.isActive == true;
  }

  // Check if current user is active
  static Future<bool> isActiveUser() async {
    final user = await getCurrentAppUser();
    return user?.isActive == true;
  }

  // Get allowed screens for current user
  static Future<List<String>> getAllowedScreens() async {
    final user = await getCurrentAppUser();
    if (user == null || !user.isActive) {
      return [];
    }

    if (user.role == UserRole.admin) {
      return [
        'pos',
        'inventory',
        'products',
        'orders',
        'customers',
        'reports',
        'settings',
        'users',
        'business_profile',
      ];
    } else if (user.role == UserRole.cashier) {
      return [
        'pos',
      ];
    }

    return [];
  }

  // Get navigation items for current user
  static Future<List<NavigationItem>> getNavigationItems() async {
    final allowedScreens = await getAllowedScreens();
    final allItems = [
      NavigationItem(
        id: 'pos',
        title: 'POS',
        icon: 'point_of_sale',
        route: '/pos',
      ),
      NavigationItem(
        id: 'inventory',
        title: 'Inventory',
        icon: 'inventory',
        route: '/inventory',
      ),
      NavigationItem(
        id: 'products',
        title: 'Products',
        icon: 'shopping_bag',
        route: '/products',
      ),
      NavigationItem(
        id: 'orders',
        title: 'Orders',
        icon: 'receipt',
        route: '/orders',
      ),
      NavigationItem(
        id: 'customers',
        title: 'Customers',
        icon: 'people',
        route: '/customers',
      ),
      NavigationItem(
        id: 'reports',
        title: 'Reports',
        icon: 'analytics',
        route: '/reports',
      ),
      NavigationItem(
        id: 'users',
        title: 'Users',
        icon: 'admin_panel_settings',
        route: '/users',
      ),
      NavigationItem(
        id: 'settings',
        title: 'Settings',
        icon: 'settings',
        route: '/settings',
      ),
    ];

    return allItems.where((item) => allowedScreens.contains(item.id)).toList();
  }

  // Clear cached user data (call on logout)
  static void clearCache() {
    _currentAppUser = null;
  }

  // Refresh current user data
  static Future<void> refreshCurrentUser() async {
    _currentAppUser = null;
    await getCurrentAppUser();
  }

  // Check if user can access specific route
  static Future<bool> canAccessRoute(String route) async {
    final allowedScreens = await getAllowedScreens();
    
    // Map routes to screen IDs
    final routeMapping = {
      '/pos': 'pos',
      '/inventory': 'inventory',
      '/products': 'products',
      '/orders': 'orders',
      '/customers': 'customers',
      '/reports': 'reports',
      '/users': 'users',
      '/settings': 'settings',
      '/business_profile': 'business_profile',
    };

    final screenId = routeMapping[route];
    return screenId != null && allowedScreens.contains(screenId);
  }

  // Get default route for user role
  static Future<String> getDefaultRoute() async {
    final user = await getCurrentAppUser();
    if (user == null || !user.isActive) {
      return '/login';
    }

    // Admin can access main screen with all options
    // Cashier goes directly to POS
    return user.role == UserRole.admin ? '/main' : '/pos';
  }
}

class NavigationItem {
  final String id;
  final String title;
  final String icon;
  final String route;

  const NavigationItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.route,
  });
}
