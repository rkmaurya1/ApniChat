import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Get FCM token
  Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  // Request notification permissions
  Future<bool> requestPermission() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('Permission status: ${settings.authorizationStatus}');
      }

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting permission: $e');
      }
      return false;
    }
  }

  // Initialize messaging service
  Future<void> initialize() async {
    try {
      // Request permission
      await requestPermission();

      // Get token
      await getToken();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');
          if (message.notification != null) {
            print('Message notification: ${message.notification?.title}');
            print('Message notification: ${message.notification?.body}');
          }
        }
        // You can show a local notification here
        _handleForegroundMessage(message);
      });

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('A new onMessageOpenedApp event was published!');
          print('Message data: ${message.data}');
        }
        _handleNotificationTap(message);
      });

      // Check if app was opened from terminated state
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          print('App opened from terminated state');
          print('Message data: ${initialMessage.data}');
        }
        _handleNotificationTap(initialMessage);
      }

      // Token refresh listener
      _messaging.onTokenRefresh.listen((String newToken) {
        if (kDebugMode) {
          print('FCM Token refreshed: $newToken');
        }
        // Save new token to Firestore
        _saveTokenToFirestore(newToken);
      });

      // Save initial token to Firestore if user is logged in
      String? token = await getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing messaging: $e');
      }
    }
  }

  // Handle foreground messages (show local notification)
  void _handleForegroundMessage(RemoteMessage message) {
    // You can use flutter_local_notifications package here
    // to show notifications when app is in foreground
    if (kDebugMode) {
      print('Foreground message received: ${message.notification?.title}');
    }
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    // Navigate to specific screen based on message data
    if (kDebugMode) {
      print('Notification tapped: ${message.data}');
    }
    // Example: Navigate to chat screen
    // You can use GetX, Navigator, or any navigation solution here
  }

  // Save token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'fcmToken': token});
        if (kDebugMode) {
          print('Token saved to Firestore for user: ${currentUser.uid}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving token: $e');
      }
    }
  }

  // Save token to Firestore (public method)
  Future<void> saveTokenToFirestore(String? token) async {
    if (token != null) {
      await _saveTokenToFirestore(token);
    }
  }

  // Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to topic: $e');
      }
    }
  }

  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from topic: $e');
      }
    }
  }

  // Delete token (for logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      if (kDebugMode) {
        print('FCM Token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting token: $e');
      }
    }
  }
}

