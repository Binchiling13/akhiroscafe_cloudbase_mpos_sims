import 'package:flutter/material.dart';
import '../models/business_profile.dart';
import '../services/business_profile_service.dart';

class BusinessProfileController extends ChangeNotifier {
  BusinessProfile? _businessProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  BusinessProfile? get businessProfile => _businessProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  BusinessProfileController() {
    loadBusinessProfile();
  }

  // Load business profile
  Future<void> loadBusinessProfile() async {
    _setLoading(true);
    _clearError();

    try {
      _businessProfile = await BusinessProfileService.getBusinessProfile();
      
      // Initialize with default if not exists
      if (_businessProfile == null) {
        _businessProfile = await BusinessProfileService.initializeBusinessProfile();
      }
      
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Update business profile
  Future<bool> updateBusinessProfile(BusinessProfile profile) async {
    _setLoading(true);
    _clearError();

    try {
      await BusinessProfileService.saveBusinessProfile(profile);
      _businessProfile = profile;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update specific fields
  Future<bool> updateFields(Map<String, dynamic> updates) async {
    _setLoading(true);
    _clearError();

    try {
      await BusinessProfileService.updateBusinessProfile(updates);
      
      // Update local profile with new values
      if (_businessProfile != null) {
        _businessProfile = _businessProfile!.copyWith(
          businessName: updates['businessName'] ?? _businessProfile!.businessName,
          address: updates['address'] ?? _businessProfile!.address,
          phone: updates['phone'] ?? _businessProfile!.phone,
          email: updates['email'] ?? _businessProfile!.email,
          website: updates['website'] ?? _businessProfile!.website,
          description: updates['description'] ?? _businessProfile!.description,
          logoUrl: updates['logoUrl'] ?? _businessProfile!.logoUrl,
          currency: updates['currency'] ?? _businessProfile!.currency,
          taxRate: updates['taxRate'] ?? _businessProfile!.taxRate,
          operatingHours: updates['operatingHours'] ?? _businessProfile!.operatingHours,
          autoPrintReceipts: updates['autoPrintReceipts'] ?? _businessProfile!.autoPrintReceipts,
          lowStockAlerts: updates['lowStockAlerts'] ?? _businessProfile!.lowStockAlerts,
          lowStockThreshold: updates['lowStockThreshold'] ?? _businessProfile!.lowStockThreshold,
          updatedAt: DateTime.now(),
        );
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update operating hours
  Future<bool> updateOperatingHours(Map<String, String> operatingHours) async {
    _setLoading(true);
    _clearError();

    try {
      await BusinessProfileService.updateOperatingHours(operatingHours);
      
      if (_businessProfile != null) {
        _businessProfile = _businessProfile!.copyWith(
          operatingHours: operatingHours,
          updatedAt: DateTime.now(),
        );
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update POS settings
  Future<bool> updatePOSSettings({
    bool? autoPrintReceipts,
    bool? lowStockAlerts,
    int? lowStockThreshold,
    double? taxRate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await BusinessProfileService.updatePOSSettings(
        autoPrintReceipts: autoPrintReceipts,
        lowStockAlerts: lowStockAlerts,
        lowStockThreshold: lowStockThreshold,
        taxRate: taxRate,
      );
      
      if (_businessProfile != null) {
        _businessProfile = _businessProfile!.copyWith(
          autoPrintReceipts: autoPrintReceipts ?? _businessProfile!.autoPrintReceipts,
          lowStockAlerts: lowStockAlerts ?? _businessProfile!.lowStockAlerts,
          lowStockThreshold: lowStockThreshold ?? _businessProfile!.lowStockThreshold,
          taxRate: taxRate ?? _businessProfile!.taxRate,
          updatedAt: DateTime.now(),
        );
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Convenience methods for specific POS settings
  Future<bool> updateAutoPrintReceipts(bool autoPrintReceipts) async {
    return await updatePOSSettings(autoPrintReceipts: autoPrintReceipts);
  }

  Future<bool> updateLowStockAlerts(bool lowStockAlerts) async {
    return await updatePOSSettings(lowStockAlerts: lowStockAlerts);
  }

  Future<bool> updateLowStockThreshold(int threshold) async {
    return await updatePOSSettings(lowStockThreshold: threshold);
  }

  Future<bool> updateTaxRate(double taxRate) async {
    return await updatePOSSettings(taxRate: taxRate);
  }

  // Refresh from server
  Future<void> refreshBusinessProfile() async {
    await loadBusinessProfile();
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
