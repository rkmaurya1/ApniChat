import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
    // Sign out from both Google and Firebase to ensure account picker shows on next login
    await _googleSignIn.signOut();
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

  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Get FCM token
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        // Check if user already exists in Firestore
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (doc.exists) {
          // User exists, update their status
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({
            'isOnline': true,
            'lastSeen': DateTime.now().toIso8601String(),
            if (fcmToken != null) 'fcmToken': fcmToken,
          });
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        } else {
          // New user, create document
          UserModel user = UserModel(
            uid: userCredential.user!.uid,
            name: userCredential.user!.displayName ?? 'User',
            email: userCredential.user!.email ?? '',
            isOnline: true,
            lastSeen: DateTime.now(),
          );

          Map<String, dynamic> userData = user.toMap();
          if (fcmToken != null) {
            userData['fcmToken'] = fcmToken;
          }

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(userData);

          return user;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }
}

