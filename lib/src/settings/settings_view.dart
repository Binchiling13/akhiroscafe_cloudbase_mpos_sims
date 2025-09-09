import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_controller.dart';
import '../controllers/business_profile_controller.dart';
import '../screens/business_profile_edit_screen.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Consumer<BusinessProfileController>(
      builder: (context, businessProfileController, child) {
        final businessProfile = businessProfileController.businessProfile;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business Profile Section
                  _buildSectionHeader(context, 'Business Profile'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (businessProfile != null) ...[
                            ListTile(
                              leading: const Icon(Icons.business),
                              title: const Text('Business Name'),
                              subtitle: Text(businessProfile.businessName),
                              trailing: const Icon(Icons.edit),
                              onTap: () => _editBusinessProfile(context),
                            ),
                            ListTile(
                              leading: const Icon(Icons.location_on),
                              title: const Text('Address'),
                              subtitle: Text(businessProfile.address),
                              trailing: const Icon(Icons.edit),
                              onTap: () => _editBusinessProfile(context),
                            ),
                            ListTile(
                              leading: const Icon(Icons.phone),
                              title: const Text('Phone'),
                              subtitle: Text(businessProfile.phone),
                              trailing: const Icon(Icons.edit),
                              onTap: () => _editBusinessProfile(context),
                            ),
                            ListTile(
                              leading: const Icon(Icons.email),
                              title: const Text('Email'),
                              subtitle: Text(businessProfile.email),
                              trailing: const Icon(Icons.edit),
                              onTap: () => _editBusinessProfile(context),
                            ),
                            if (businessProfile.website.isNotEmpty)
                              ListTile(
                                leading: const Icon(Icons.web),
                                title: const Text('Website'),
                                subtitle: Text(businessProfile.website),
                                trailing: const Icon(Icons.edit),
                                onTap: () => _editBusinessProfile(context),
                              ),
                          ] else ...[
                            ListTile(
                              leading: const Icon(Icons.business),
                              title: const Text('Setup Business Profile'),
                              subtitle: const Text('Configure your business information'),
                              trailing: const Icon(Icons.add),
                              onTap: () => _editBusinessProfile(context),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // POS Settings Section
                  _buildSectionHeader(context, 'POS Settings'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          SwitchListTile(
                            secondary: const Icon(Icons.receipt),
                            title: const Text('Auto Print Receipts'),
                            subtitle: const Text('Automatically print receipts after checkout'),
                            value: businessProfile?.autoPrintReceipts ?? true,
                            onChanged: (value) => _toggleAutoPrintReceipts(context, businessProfileController, value),
                          ),
                          SwitchListTile(
                            secondary: const Icon(Icons.notifications),
                            title: const Text('Low Stock Alerts'),
                            subtitle: const Text('Get notified when items are running low'),
                            value: businessProfile?.lowStockAlerts ?? true,
                            onChanged: (value) => _toggleLowStockAlerts(context, businessProfileController, value),
                          ),
                          ListTile(
                            leading: const Icon(Icons.percent),
                            title: const Text('Tax Rate'),
                            subtitle: Text('${((businessProfile?.taxRate ?? 0.0) * 100).toStringAsFixed(1)}%'),
                            trailing: const Icon(Icons.edit),
                            onTap: () => _editBusinessProfile(context),
                          ),
                          ListTile(
                            leading: const Icon(Icons.attach_money),
                            title: const Text('Currency'),
                            subtitle: Text(businessProfile?.currency ?? 'PHP'),
                            trailing: const Icon(Icons.edit),
                            onTap: () => _editBusinessProfile(context),
                          ),
                          ListTile(
                            leading: const Icon(Icons.warning),
                            title: const Text('Low Stock Threshold'),
                            subtitle: Text('${businessProfile?.lowStockThreshold ?? 10} items'),
                            trailing: const Icon(Icons.edit),
                            onTap: () => _editBusinessProfile(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Operating Hours Section
                  _buildSectionHeader(context, 'Operating Hours'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.schedule),
                            title: const Text('Business Hours'),
                            subtitle: Text(businessProfile != null 
                                ? '${businessProfile.operatingHours.length} days configured'
                                : 'Not configured'),
                            trailing: const Icon(Icons.edit),
                            onTap: () => _editBusinessProfile(context),
                          ),
                          if (businessProfile != null && businessProfile.operatingHours.isNotEmpty) ...[
                            const Divider(),
                            ...businessProfile.operatingHours.entries.take(3).map((entry) => 
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    Text(entry.value, style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            ),
                            if (businessProfile.operatingHours.length > 3)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  '... and ${businessProfile.operatingHours.length - 3} more',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Theme Settings Section
                  _buildSectionHeader(context, 'Appearance'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.palette),
                            title: const Text('Theme Mode'),
                            subtitle: DropdownButton<ThemeMode>(
                              value: controller.themeMode,
                              onChanged: controller.updateThemeMode,
                              items: const [
                                DropdownMenuItem(
                                  value: ThemeMode.system,
                                  child: Text('System Theme'),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.light,
                                  child: Text('Light Theme'),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.dark,
                                  child: Text('Dark Theme'),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Data Management Section
                  _buildSectionHeader(context, 'Data Management'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.cloud_sync),
                            title: const Text('Sync Data'),
                            subtitle: const Text('Last synced: Never'),
                            trailing: const Icon(Icons.sync),
                            onTap: () {
                              // TODO: Sync data
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Data synced successfully!')),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.file_download),
                            title: const Text('Export Data'),
                            subtitle: const Text('Export sales and inventory data'),
                            trailing: const Icon(Icons.download),
                            onTap: () {
                              // TODO: Export data
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Data exported successfully!')),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.backup),
                            title: const Text('Backup Data'),
                            subtitle: const Text('Create a backup of your data'),
                            trailing: const Icon(Icons.backup),
                            onTap: () {
                              // TODO: Backup data
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Backup created successfully!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Account Section
                  _buildSectionHeader(context, 'Account'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text('Profile'),
                            subtitle: const Text('Manage your account settings'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              // TODO: Navigate to profile
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile settings functionality')),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.lock),
                            title: const Text('Change Password'),
                            subtitle: const Text('Update your password'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              // TODO: Change password
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Change password functionality')),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.logout, color: Colors.red),
                            title: const Text('Logout', style: TextStyle(color: Colors.red)),
                            subtitle: const Text('Sign out of your account'),
                            onTap: () {
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
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.pushReplacementNamed(context, '/login');
                                        },
                                        child: const Text('Logout'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // About Section
                  _buildSectionHeader(context, 'About'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.info),
                            title: const Text('Version'),
                            subtitle: const Text('1.0.0'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.help),
                            title: const Text('Help & Support'),
                            subtitle: const Text('Get help with using the app'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              // TODO: Show help
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Help & support functionality')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _editBusinessProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BusinessProfileEditScreen(),
      ),
    );
  }

  Future<void> _toggleAutoPrintReceipts(BuildContext context, BusinessProfileController controller, bool value) async {
    await controller.updateAutoPrintReceipts(value);
    if (controller.errorMessage != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleLowStockAlerts(BuildContext context, BusinessProfileController controller, bool value) async {
    await controller.updateLowStockAlerts(value);
    if (controller.errorMessage != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
