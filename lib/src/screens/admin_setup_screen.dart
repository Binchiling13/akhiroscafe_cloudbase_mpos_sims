import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';

class AdminSetupScreen extends StatelessWidget {
  const AdminSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Setup'),
      ),
      body: Consumer<AuthController>(
        builder: (context, authController, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'User Debug Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Firebase User: ${authController.firebaseUser?.email ?? 'None'}'),
                        Text('App User: ${authController.currentUser?.email ?? 'None'}'),
                        Text('Display Name: ${authController.currentUser?.displayName ?? 'None'}'),
                        Text('Role: ${authController.currentUser?.role.toString() ?? 'None'}'),
                        Text('Is Admin: ${authController.isAdmin}'),
                        Text('Is Cashier: ${authController.isCashier}'),
                        Text('Is Active: ${authController.isActiveUser}'),
                        Text('Is Authenticated: ${authController.isAuthenticated}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authController.currentUser != null 
                    ? () async {
                        await authController.makeCurrentUserAdmin();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User role updated to Admin'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    : null,
                  child: const Text('Make Current User Admin'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    await authController.forceRefreshUserProfile();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User profile refreshed'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  child: const Text('Refresh User Profile'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    authController.debugPrintUserStatus();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Debug info printed to console'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  child: const Text('Print Debug Info'),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('Back to App'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
