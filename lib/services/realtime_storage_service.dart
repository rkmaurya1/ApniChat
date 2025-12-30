import 'dart:io';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class RealtimeStorageService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final Uuid _uuid = const Uuid();

  /// Upload image as Base64 to Realtime Database
  /// Returns the image ID which can be used to retrieve the image
  Future<String> uploadImageToRealtimeDB(File imageFile, String userId) async {
    try {
      // Validate file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Read image as bytes
      final bytes = await imageFile.readAsBytes();

      // Convert to Base64
      String base64Image = base64Encode(bytes);

      // Generate unique image ID
      String imageId = _uuid.v4();

      // Create image data
      Map<String, dynamic> imageData = {
        'id': imageId,
        'uploadedBy': userId,
        'uploadedAt': ServerValue.timestamp,
        'base64': base64Image,
        'size': bytes.length,
      };

      // Save to Realtime Database
      await _database
          .ref()
          .child('chat_images')
          .child(userId)
          .child(imageId)
          .set(imageData);

      debugPrint('Image uploaded to Realtime DB: $imageId');

      return imageId;
    } catch (e) {
      debugPrint('Image upload error: $e');
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  /// Upload profile photo as Base64 to Realtime Database
  Future<String> uploadProfilePhotoToRealtimeDB(
      File imageFile, String userId) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final bytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(bytes);

      Map<String, dynamic> imageData = {
        'uploadedBy': userId,
        'uploadedAt': ServerValue.timestamp,
        'base64': base64Image,
        'size': bytes.length,
      };

      // Save to Realtime Database
      await _database
          .ref()
          .child('profile_photos')
          .child(userId)
          .set(imageData);

      debugPrint('Profile photo uploaded to Realtime DB for user: $userId');

      return userId; // Return userId as identifier
    } catch (e) {
      debugPrint('Profile photo upload error: $e');
      throw Exception('Failed to upload profile photo: ${e.toString()}');
    }
  }

  /// Get image Base64 from Realtime Database
  Future<String?> getImageBase64(String userId, String imageId) async {
    try {
      final snapshot = await _database
          .ref()
          .child('chat_images')
          .child(userId)
          .child(imageId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data['base64'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting image: $e');
      return null;
    }
  }

  /// Get profile photo Base64 from Realtime Database
  Future<String?> getProfilePhotoBase64(String userId) async {
    try {
      final snapshot =
          await _database.ref().child('profile_photos').child(userId).get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data['base64'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting profile photo: $e');
      return null;
    }
  }

  /// Stream to listen to profile photo changes
  Stream<String?> watchProfilePhoto(String userId) {
    return _database
        .ref()
        .child('profile_photos')
        .child(userId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        return data['base64'] as String?;
      }
      return null;
    });
  }
}
