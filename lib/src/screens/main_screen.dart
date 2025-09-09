import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/pos_screen_firebase.dart';
import '../screens/complex_inventory_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/user_management_screen.dart';
import '../controllers/auth_controller.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static const routeName = '/main';

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        // Check if user is authenticated and has a profile loaded
        if (!authController.isAuthenticated ||
            authController.currentUser == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is active
        if (!authController.isActiveUser) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.block,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Account Disabled',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your account has been disabled. Please contact an administrator.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => authController.signOut(),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          );
        }

        final isAdmin = authController.isAdmin;
        final isCashier = authController.isCashier;

        // Setup screens and destinations based on user role
        List<Widget> screens = [];
        List<NavigationDestination> destinations = [];

        if (isAdmin) {
          screens = [
            const DashboardScreen(),
            const PosScreenFirebase(),
            const ComplexInventoryScreen(),
            const OrdersScreen(),
            const UserManagementScreen(),
          ];

          destinations = [
            const NavigationDestination(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            const NavigationDestination(
              icon: Icon(Icons.point_of_sale),
              label: 'POS',
            ),
            const NavigationDestination(
              icon: Icon(Icons.inventory),
              label: 'Inventory',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt),
              label: 'Orders',
            ),
            const NavigationDestination(
              icon: Icon(Icons.people),
              label: 'Users',
            ),
          ];
        } else if (isCashier) {
          // Cashier only gets POS
          screens = [
            const PosScreenFirebase(),
          ];

          destinations = [
            const NavigationDestination(
              icon: Icon(Icons.point_of_sale),
              label: 'POS',
            ),
          ];
        }

        // Ensure selected index is valid
        if (_selectedIndex >= screens.length) {
          _selectedIndex = 0;
        }

        return _buildMainScreen(
          context,
          authController,
          screens,
          destinations,
          isAdmin,
        );
      },
    );
  }

  Widget _buildMainScreen(
    BuildContext context,
    AuthController authController,
    List<Widget> screens,
    List<NavigationDestination> destinations,
    bool isAdmin,
  ) {
    if (screens.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Access',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You do not have access to any screens.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => authController.signOut(),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail for landscape mode
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              if (index < screens.length) {
                setState(() {
                  _selectedIndex = index;
                });
              }
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            leading: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/logoaki.png",
                    width: 45,
                    height: 45,
                  ),
                  Text(
                    'Akhiro\nCafe',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Role indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAdmin ? Colors.blue : Colors.green,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isAdmin ? 'Admin' : 'Cashier',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isAdmin ? Colors.blue : Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // User info
                  Text(
                    authController.currentUser?.displayName ?? 'User',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Debug admin setup button (temporary)
                  // TextButton(
                  //   onPressed: () => Navigator.pushNamed(context, '/admin-setup'),
                  //   style: TextButton.styleFrom(
                  //     padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  //   ),
                  //   child: const Text(
                  //     'Debug',
                  //     style: TextStyle(fontSize: 8),
                  //   ),
                  // ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAdmin) ...[
                        IconButton(
                          onPressed: () => _showSettingsScreen(authController),
                          icon: const Icon(Icons.settings),
                          tooltip: 'Settings',
                        ),
                        const SizedBox(height: 8),
                      ],
                      IconButton(
                        onPressed: () => _showLogoutDialog(authController),
                        icon: const Icon(Icons.logout),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            destinations: destinations.map((destination) {
              return NavigationRailDestination(
                icon: destination.icon,
                label: Text(destination.label),
              );
            }).toList(),
          ),

          // Divider
          const VerticalDivider(thickness: 1, width: 1),

          // Main content area
          Expanded(
            child: _selectedIndex < screens.length
                ? screens[_selectedIndex]
                : screens[0],
          ),
        ],
      ),
    );
  }

  void _showSettingsScreen(AuthController authController) {
    if (authController.canAccessScreen('settings')) {
      Navigator.pushNamed(context, '/settings');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission to access settings'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLogoutDialog(AuthController authController) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authController.signOut();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
