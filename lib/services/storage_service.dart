import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      // Validate file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      String fileName = '${_uuid.v4()}.jpg';
      Reference ref = _storage.ref().child('chat_images/$userId/$fileName');

      // Set metadata for better file handling
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      UploadTask uploadTask = ref.putFile(imageFile, metadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Image upload error details: $e');
      if (e.toString().contains('object-not-found')) {
        throw Exception('Storage not configured. Please check Firebase Storage setup.');
      } else if (e.toString().contains('unauthorized')) {
        throw Exception('Permission denied. Please check Storage rules.');
      } else {
        throw Exception('Upload failed: ${e.toString()}');
      }
    }
  }

  Future<String> uploadProfilePhoto(File imageFile, String userId) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      Reference ref = _storage.ref().child('profile_photos/$userId.jpg');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      UploadTask uploadTask = ref.putFile(imageFile, metadata);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Profile photo upload error: $e');
      if (e.toString().contains('object-not-found')) {
        throw Exception('Storage not configured. Please enable Firebase Storage.');
      } else if (e.toString().contains('unauthorized')) {
        throw Exception('Permission denied. Please check Storage rules.');
      } else {
        throw Exception('Upload failed: ${e.toString()}');
      }
    }
  }

  Future<String> uploadVoice(File voiceFile, String userId) async {
    try {
      String fileName = '${_uuid.v4()}.m4a';
      Reference ref = _storage.ref().child('voices/$userId/$fileName');

      UploadTask uploadTask = ref.putFile(voiceFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload voice: $e');
    }
  }
}

