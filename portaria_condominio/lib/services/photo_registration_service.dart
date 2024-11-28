import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class PhotoRegistrationService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadPhoto(String userType, String userId, File photoFile) async {
    try {
      // Create storage reference
      final storageRef = _storage.ref().child('${userType}_photos/$userId.jpg');
      
      // Upload file
      await storageRef.putFile(photoFile);
      
      // Get download URL
      String downloadURL = await storageRef.getDownloadURL();
      
      // Update user document with photo URL
      await _firestore.collection(userType == 'resident' ? 'residents' : 'providers')
          .doc(userId)
          .update({
        'photoURL': downloadURL,
        'photoRegisteredAt': FieldValue.serverTimestamp(),
      });
      
      return downloadURL;
    } catch (e) {
      throw Exception('Erro ao fazer upload da foto: $e');
    }
  }

  Future<bool> verifyPhotoRegistration(String userType, String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection(userType == 'resident' ? 'residents' : 'providers')
          .doc(userId)
          .get();
      
      if (!docSnapshot.exists) return false;
      
      final data = docSnapshot.data();
      return data != null && data['photoURL'] != null;
    } catch (e) {
      return false;
    }
  }
}
