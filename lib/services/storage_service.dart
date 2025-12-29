import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      String fileName = '${_uuid.v4()}.jpg';
      Reference ref = _storage.ref().child('images/$userId/$fileName');

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String> uploadProfilePhoto(File imageFile, String userId) async {
    try {
      Reference ref = _storage.ref().child('profile_photos/$userId.jpg');

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
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

