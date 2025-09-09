import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_profile.dart';
import 'firestore_service.dart';

class BusinessProfileService {
  static const String _collection = 'businessProfile';
  static const String _defaultDocumentId = 'main';

  // Get business profile
  static Future<BusinessProfile?> getBusinessProfile() async {
    try {
      final doc = await FirestoreService.getDocument(
        collection: _collection,
        documentId: _defaultDocumentId,
      );

      if (doc.exists && doc.data() != null) {
        return BusinessProfile.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get business profile: ${e.toString()}');
    }
  }

  // Create or update business profile
  static Future<void> saveBusinessProfile(BusinessProfile profile) async {
    try {
      final data = profile.copyWith(updatedAt: DateTime.now()).toMap();
      
      await FirestoreService.addDocument(
        collection: _collection,
        documentId: _defaultDocumentId,
        data: data,
      );
    } catch (e) {
      throw Exception('Failed to save business profile: ${e.toString()}');
    }
  }

  // Update specific fields
  static Future<void> updateBusinessProfile(Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      
      await FirestoreService.updateDocument(
        collection: _collection,
        documentId: _defaultDocumentId,
        data: updates,
      );
    } catch (e) {
      throw Exception('Failed to update business profile: ${e.toString()}');
    }
  }

  // Initialize with default values if not exists
  static Future<BusinessProfile> initializeBusinessProfile() async {
    try {
      final existing = await getBusinessProfile();
      if (existing != null) {
        return existing;
      }

      final defaultProfile = BusinessProfile(
        id: _defaultDocumentId,
        businessName: 'Akhiro Cafe',
        address: '123 Coffee Street, Bean City',
        phone: '+1 (555) 123-4567',
        email: 'info@akhirocafe.com',
        website: 'www.akhirocafe.com',
        description: 'A cozy place for coffee lovers',
        currency: 'PHP',
        taxRate: 0.10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await saveBusinessProfile(defaultProfile);
      return defaultProfile;
    } catch (e) {
      throw Exception('Failed to initialize business profile: ${e.toString()}');
    }
  }

  // Stream business profile for real-time updates
  static Stream<BusinessProfile?> streamBusinessProfile() {
    try {
      return FirestoreService.streamDocument(
        collection: _collection,
        documentId: _defaultDocumentId,
      ).map((doc) {
        if (doc.exists && doc.data() != null) {
          return BusinessProfile.fromMap(doc.data()!, doc.id);
        }
        return null;
      });
    } catch (e) {
      throw Exception('Failed to stream business profile: ${e.toString()}');
    }
  }

  // Update operating hours
  static Future<void> updateOperatingHours(Map<String, String> operatingHours) async {
    try {
      await updateBusinessProfile({'operatingHours': operatingHours});
    } catch (e) {
      throw Exception('Failed to update operating hours: ${e.toString()}');
    }
  }

  // Update POS settings
  static Future<void> updatePOSSettings({
    bool? autoPrintReceipts,
    bool? lowStockAlerts,
    int? lowStockThreshold,
    double? taxRate,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (autoPrintReceipts != null) updates['autoPrintReceipts'] = autoPrintReceipts;
      if (lowStockAlerts != null) updates['lowStockAlerts'] = lowStockAlerts;
      if (lowStockThreshold != null) updates['lowStockThreshold'] = lowStockThreshold;
      if (taxRate != null) updates['taxRate'] = taxRate;

      if (updates.isNotEmpty) {
        await updateBusinessProfile(updates);
      }
    } catch (e) {
      throw Exception('Failed to update POS settings: ${e.toString()}');
    }
  }
}
