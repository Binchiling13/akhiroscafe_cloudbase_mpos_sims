import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get Firestore instance
  static FirebaseFirestore get instance => _firestore;
  
  // Generic method to add a document
  static Future<String> addDocument({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      DocumentReference docRef;
      if (documentId != null) {
        docRef = _firestore.collection(collection).doc(documentId);
        await docRef.set(data);
      } else {
        docRef = await _firestore.collection(collection).add(data);
      }
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add document: ${e.toString()}');
    }
  }
  
  // Generic method to get a document by ID
  static Future<DocumentSnapshot<Map<String, dynamic>>> getDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      return await _firestore.collection(collection).doc(documentId).get();
    } catch (e) {
      throw Exception('Failed to get document: ${e.toString()}');
    }
  }
  
  // Generic method to get all documents from a collection
  static Future<QuerySnapshot<Map<String, dynamic>>> getCollection({
    required String collection,
    Query<Map<String, dynamic>>? query,
  }) async {
    try {
      if (query != null) {
        return await query.get();
      }
      return await _firestore.collection(collection).get();
    } catch (e) {
      throw Exception('Failed to get collection: ${e.toString()}');
    }
  }
  
  // Generic method to update a document
  static Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      throw Exception('Failed to update document: ${e.toString()}');
    }
  }
  
  // Generic method to delete a document
  static Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to delete document: ${e.toString()}');
    }
  }
  
  // Stream for real-time updates of a collection
  static Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection({
    required String collection,
    Query<Map<String, dynamic>>? query,
  }) {
    try {
      if (query != null) {
        return query.snapshots();
      }
      return _firestore.collection(collection).snapshots();
    } catch (e) {
      throw Exception('Failed to stream collection: ${e.toString()}');
    }
  }
  
  // Stream for real-time updates of a document
  static Stream<DocumentSnapshot<Map<String, dynamic>>> streamDocument({
    required String collection,
    required String documentId,
  }) {
    try {
      return _firestore.collection(collection).doc(documentId).snapshots();
    } catch (e) {
      throw Exception('Failed to stream document: ${e.toString()}');
    }
  }
  
  // Batch operations
  static WriteBatch getBatch() {
    return _firestore.batch();
  }
  
  // Transaction operations
  static Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) updateFunction,
  ) async {
    try {
      return await _firestore.runTransaction(updateFunction);
    } catch (e) {
      throw Exception('Failed to run transaction: ${e.toString()}');
    }
  }
}
