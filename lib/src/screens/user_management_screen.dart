import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_management_controller.dart';
import '../models/app_user.dart';
import 'user_form_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  UserRole? _selectedRoleFilter;
  bool? _selectedStatusFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserManagementController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('User Management'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: controller.isLoading ? null : () => controller.refreshUsers(),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddUserDialog(context),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'All Users', icon: Icon(Icons.people)),
                Tab(text: 'Active', icon: Icon(Icons.person)),
                Tab(text: 'Inactive', icon: Icon(Icons.person_off)),
              ],
            ),
          ),
          body: Column(
            children: [
              // Search and Filter Section
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).cardColor,
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Filters
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<UserRole?>(
                            value: _selectedRoleFilter,
                            decoration: const InputDecoration(
                              labelText: 'Filter by Role',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem<UserRole?>(
                                value: null,
                                child: Text('All Roles'),
                              ),
                              ...UserRole.allRoles.map((role) => 
                                DropdownMenuItem<UserRole>(
                                  value: role,
                                  child: Row(
                                    children: [
                                      Icon(role.icon, size: 16, color: role.color),
                                      const SizedBox(width: 8),
                                      Text(role.displayName),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedRoleFilter = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<bool?>(
                            value: _selectedStatusFilter,
                            decoration: const InputDecoration(
                              labelText: 'Filter by Status',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem<bool?>(
                                value: null,
                                child: Text('All Status'),
                              ),
                              DropdownMenuItem<bool>(
                                value: true,
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, size: 16, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text('Active'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem<bool>(
                                value: false,
                                child: Row(
                                  children: [
                                    Icon(Icons.cancel, size: 16, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Inactive'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedStatusFilter = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Statistics Cards
              Container(
                padding: const EdgeInsets.all(16.0),
                child: _buildStatisticsCards(controller),
              ),

              // User List
              Expanded(
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildUserList(controller, controller.users),
                          _buildUserList(controller, controller.activeUsers),
                          _buildUserList(controller, controller.inactiveUsers),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCards(UserManagementController controller) {
    final stats = controller.getUserStatistics();
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Users',
            stats['total'].toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Active',
            stats['active'].toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Admins',
            stats['admins'].toString(),
            Icons.admin_panel_settings,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Cashiers',
            stats['cashiers'].toString(),
            Icons.point_of_sale,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(UserManagementController controller, List<AppUser> users) {
    // Apply search and filters
    var filteredUsers = users;
    
    if (_searchQuery.isNotEmpty) {
      filteredUsers = controller.searchUsers(_searchQuery);
    }
    
    if (_selectedRoleFilter != null) {
      filteredUsers = filteredUsers.where((user) => user.role == _selectedRoleFilter).toList();
    }
    
    if (_selectedStatusFilter != null) {
      filteredUsers = filteredUsers.where((user) => user.isActive == _selectedStatusFilter).toList();
    }

    if (filteredUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(user, controller);
      },
    );
  }

  Widget _buildUserCard(AppUser user, UserManagementController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.role.color,
          child: Icon(
            user.role.icon,
            color: Colors.white,
          ),
        ),
        title: Text(
          user.displayName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: user.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Row(
              children: [
                Chip(
                  label: Text(
                    user.role.displayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: user.role.color.withOpacity(0.1),
                  side: BorderSide(color: user.role.color),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    user.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: user.isActive 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  side: BorderSide(
                    color: user.isActive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(value, user, controller),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: user.isActive ? 'deactivate' : 'activate',
              child: Row(
                children: [
                  Icon(user.isActive ? Icons.person_off : Icons.person),
                  const SizedBox(width: 8),
                  Text(user.isActive ? 'Deactivate' : 'Activate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reset_password',
              child: Row(
                children: [
                  Icon(Icons.lock_reset),
                  SizedBox(width: 8),
                  Text('Reset Password'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showUserDetails(user),
      ),
    );
  }

  void _handleUserAction(String action, AppUser user, UserManagementController controller) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'activate':
        _activateUser(user, controller);
        break;
      case 'deactivate':
        _deactivateUser(user, controller);
        break;
      case 'reset_password':
        _resetPassword(user, controller);
        break;
      case 'delete':
        _deleteUser(user, controller);
        break;
    }
  }

  void _showAddUserDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UserFormScreen(),
      ),
    );
  }

  void _showEditUserDialog(AppUser user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserFormScreen(user: user),
      ),
    );
  }

  void _showUserDetails(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', user.email),
            _buildDetailRow('Role', user.role.displayName),
            _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive'),
            if (user.phoneNumber != null)
              _buildDetailRow('Phone', user.phoneNumber!),
            _buildDetailRow('Created', _formatDate(user.createdAt)),
            _buildDetailRow('Updated', _formatDate(user.updatedAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _activateUser(AppUser user, UserManagementController controller) async {
    final success = await controller.activateUser(user.id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.displayName} has been activated')),
      );
    }
  }

  void _deactivateUser(AppUser user, UserManagementController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text('Are you sure you want to deactivate ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await controller.deactivateUser(user.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.displayName} has been deactivated')),
        );
      }
    }
  }

  void _resetPassword(AppUser user, UserManagementController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send password reset email to ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await controller.resetUserPassword(user.email);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent to ${user.email}')),
        );
      }
    }
  }

  void _deleteUser(AppUser user, UserManagementController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to permanently delete ${user.displayName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await controller.deleteUser(user.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.displayName} has been deleted')),
        );
      }
    }
  }
}
