import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/business_profile_controller.dart';

class BusinessProfileEditScreen extends StatefulWidget {
  const BusinessProfileEditScreen({super.key});

  @override
  State<BusinessProfileEditScreen> createState() => _BusinessProfileEditScreenState();
}

class _BusinessProfileEditScreenState extends State<BusinessProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _lowStockThresholdController = TextEditingController();
  
  bool _autoPrintReceipts = true;
  bool _lowStockAlerts = true;
  String _selectedCurrency = 'PHP';
  
  final List<String> _currencies = ['PHP', 'USD', 'EUR', 'JPY', 'GBP'];
  
  Map<String, String> _operatingHours = {};

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
  }

  void _loadBusinessProfile() {
    final controller = context.read<BusinessProfileController>();
    final profile = controller.businessProfile;
    
    if (profile != null) {
      _businessNameController.text = profile.businessName;
      _addressController.text = profile.address;
      _phoneController.text = profile.phone;
      _emailController.text = profile.email;
      _websiteController.text = profile.website;
      _descriptionController.text = profile.description;
      _taxRateController.text = (profile.taxRate * 100).toStringAsFixed(1);
      _lowStockThresholdController.text = profile.lowStockThreshold.toString();
      _autoPrintReceipts = profile.autoPrintReceipts;
      _lowStockAlerts = profile.lowStockAlerts;
      _selectedCurrency = profile.currency;
      _operatingHours = Map.from(profile.operatingHours);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = context.read<BusinessProfileController>();
    final currentProfile = controller.businessProfile;
    
    if (currentProfile == null) {
      _showErrorDialog('Business profile not loaded');
      return;
    }

    final updatedProfile = currentProfile.copyWith(
      businessName: _businessNameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      website: _websiteController.text.trim(),
      description: _descriptionController.text.trim(),
      currency: _selectedCurrency,
      taxRate: double.tryParse(_taxRateController.text) != null 
          ? double.parse(_taxRateController.text) / 100 
          : currentProfile.taxRate,
      operatingHours: _operatingHours,
      autoPrintReceipts: _autoPrintReceipts,
      lowStockAlerts: _lowStockAlerts,
      lowStockThreshold: int.tryParse(_lowStockThresholdController.text) ?? currentProfile.lowStockThreshold,
      updatedAt: DateTime.now(),
    );

    final success = await controller.updateBusinessProfile(updatedProfile);
    
    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      _showErrorDialog(controller.errorMessage ?? 'Failed to update profile');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editOperatingHours() {
    showDialog(
      context: context,
      builder: (context) => OperatingHoursDialog(
        initialHours: _operatingHours,
        onSaved: (hours) {
          setState(() {
            _operatingHours = hours;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BusinessProfileController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Business Profile'),
            actions: [
              TextButton(
                onPressed: controller.isLoading ? null : _saveProfile,
                child: controller.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Information Section
                          _buildSectionHeader('Basic Information'),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _businessNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Business Name',
                                      prefixIcon: Icon(Icons.business),
                                    ),
                                    validator: (value) {
                                      if (value?.trim().isEmpty ?? true) {
                                        return 'Business name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _addressController,
                                    decoration: const InputDecoration(
                                      labelText: 'Address',
                                      prefixIcon: Icon(Icons.location_on),
                                    ),
                                    maxLines: 3,
                                    validator: (value) {
                                      if (value?.trim().isEmpty ?? true) {
                                        return 'Address is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _phoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone',
                                      prefixIcon: Icon(Icons.phone),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value?.trim().isEmpty ?? true) {
                                        return 'Phone number is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value?.trim().isEmpty ?? true) {
                                        return 'Email is required';
                                      }
                                      if (!value!.contains('@')) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _websiteController,
                                    decoration: const InputDecoration(
                                      labelText: 'Website (optional)',
                                      prefixIcon: Icon(Icons.web),
                                    ),
                                    keyboardType: TextInputType.url,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _descriptionController,
                                    decoration: const InputDecoration(
                                      labelText: 'Description',
                                      prefixIcon: Icon(Icons.description),
                                    ),
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Financial Settings Section
                          _buildSectionHeader('Financial Settings'),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    value: _selectedCurrency,
                                    decoration: const InputDecoration(
                                      labelText: 'Currency',
                                      prefixIcon: Icon(Icons.attach_money),
                                    ),
                                    items: _currencies.map((currency) {
                                      return DropdownMenuItem(
                                        value: currency,
                                        child: Text(currency),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCurrency = value!;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _taxRateController,
                                    decoration: const InputDecoration(
                                      labelText: 'Tax Rate (%)',
                                      prefixIcon: Icon(Icons.percent),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.trim().isNotEmpty ?? false) {
                                        final rate = double.tryParse(value!);
                                        if (rate == null || rate < 0 || rate > 100) {
                                          return 'Please enter a valid tax rate (0-100)';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // POS Settings Section
                          _buildSectionHeader('POS Settings'),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    title: const Text('Auto Print Receipts'),
                                    subtitle: const Text('Automatically print receipts after checkout'),
                                    value: _autoPrintReceipts,
                                    onChanged: (value) {
                                      setState(() {
                                        _autoPrintReceipts = value;
                                      });
                                    },
                                  ),
                                  SwitchListTile(
                                    title: const Text('Low Stock Alerts'),
                                    subtitle: const Text('Get notified when items are running low'),
                                    value: _lowStockAlerts,
                                    onChanged: (value) {
                                      setState(() {
                                        _lowStockAlerts = value;
                                      });
                                    },
                                  ),
                                  TextFormField(
                                    controller: _lowStockThresholdController,
                                    decoration: const InputDecoration(
                                      labelText: 'Low Stock Threshold',
                                      prefixIcon: Icon(Icons.warning),
                                      helperText: 'Alert when stock falls below this number',
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.trim().isNotEmpty ?? false) {
                                        final threshold = int.tryParse(value!);
                                        if (threshold == null || threshold < 0) {
                                          return 'Please enter a valid threshold';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Operating Hours Section
                          _buildSectionHeader('Operating Hours'),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  ListTile(
                                    title: const Text('Business Hours'),
                                    subtitle: Text('${_operatingHours.length} days configured'),
                                    trailing: const Icon(Icons.edit),
                                    onTap: _editOperatingHours,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
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

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _taxRateController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }
}

class OperatingHoursDialog extends StatefulWidget {
  final Map<String, String> initialHours;
  final Function(Map<String, String>) onSaved;

  const OperatingHoursDialog({
    super.key,
    required this.initialHours,
    required this.onSaved,
  });

  @override
  State<OperatingHoursDialog> createState() => _OperatingHoursDialogState();
}

class _OperatingHoursDialogState extends State<OperatingHoursDialog> {
  late Map<String, String> _hours;
  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _hours = Map.from(widget.initialHours);
    
    // Initialize any missing days
    for (final day in _days) {
      if (!_hours.containsKey(day)) {
        _hours[day] = '09:00-17:00';
      }
    }
  }

  void _editDayHours(String day) async {
    final currentHours = _hours[day] ?? '09:00-17:00';
    final isClosed = currentHours.toLowerCase() == 'closed';
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => DayHoursDialog(
        day: day,
        currentHours: isClosed ? '09:00-17:00' : currentHours,
        isClosed: isClosed,
      ),
    );
    
    if (result != null) {
      setState(() {
        _hours[day] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Operating Hours'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _days.length,
          itemBuilder: (context, index) {
            final day = _days[index];
            final hours = _hours[day] ?? 'Closed';
            
            return ListTile(
              title: Text(day),
              subtitle: Text(hours),
              trailing: const Icon(Icons.edit),
              onTap: () => _editDayHours(day),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSaved(_hours);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class DayHoursDialog extends StatefulWidget {
  final String day;
  final String currentHours;
  final bool isClosed;

  const DayHoursDialog({
    super.key,
    required this.day,
    required this.currentHours,
    required this.isClosed,
  });

  @override
  State<DayHoursDialog> createState() => _DayHoursDialogState();
}

class _DayHoursDialogState extends State<DayHoursDialog> {
  late bool _isClosed;
  late String _openTime;
  late String _closeTime;

  @override
  void initState() {
    super.initState();
    _isClosed = widget.isClosed;
    
    if (widget.currentHours.contains('-')) {
      final parts = widget.currentHours.split('-');
      _openTime = parts[0];
      _closeTime = parts[1];
    } else {
      _openTime = '09:00';
      _closeTime = '17:00';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.day} Hours'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Closed'),
            value: _isClosed,
            onChanged: (value) {
              setState(() {
                _isClosed = value;
              });
            },
          ),
          if (!_isClosed) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Open'),
                    subtitle: Text(_openTime),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: int.parse(_openTime.split(':')[0]),
                          minute: int.parse(_openTime.split(':')[1]),
                        ),
                      );
                      if (time != null) {
                        setState(() {
                          _openTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Close'),
                    subtitle: Text(_closeTime),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: int.parse(_closeTime.split(':')[0]),
                          minute: int.parse(_closeTime.split(':')[1]),
                        ),
                      );
                      if (time != null) {
                        setState(() {
                          _closeTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final result = _isClosed ? 'Closed' : '$_openTime-$_closeTime';
            Navigator.of(context).pop(result);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
