import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Get FCM token
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        
        UserModel user = UserModel(
          uid: credential.user!.uid,
          name: name,
          email: email,
          isOnline: true,
          lastSeen: DateTime.now(),
        );

        Map<String, dynamic> userData = user.toMap();
        if (fcmToken != null) {
          userData['fcmToken'] = fcmToken;
        }

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userData);

        return user;
      }
      return null;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Get FCM token
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .update({
          'isOnline': true,
          'lastSeen': DateTime.now().toIso8601String(),
          if (fcmToken != null) 'fcmToken': fcmToken,
        });

        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    if (currentUser != null) {
      // Delete FCM token on sign out
      try {
        await FirebaseMessaging.instance.deleteToken();
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'isOnline': false,
          'lastSeen': DateTime.now().toIso8601String(),
          'fcmToken': FieldValue.delete(), // Remove FCM token
        });
      } catch (e) {
        // If token deletion fails, still update user status
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'isOnline': false,
          'lastSeen': DateTime.now().toIso8601String(),
        });
      }
    }
    await _auth.signOut();
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  Stream<UserModel?> getUserDataStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists
            ? UserModel.fromMap(doc.data() as Map<String, dynamic>)
            : null);
  }
}

