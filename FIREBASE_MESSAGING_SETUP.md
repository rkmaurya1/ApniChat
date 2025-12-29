# Firebase Messaging Setup - Complete Guide

## ✅ क्या Add किया गया है:

### 1. Messaging Service (`lib/services/messaging_service.dart`)
- ✅ FCM token get करने की functionality
- ✅ Notification permissions request करने की functionality
- ✅ Foreground messages handle करने की functionality
- ✅ Background messages handle करने की functionality
- ✅ Notification tap handle करने की functionality
- ✅ Token को Firestore में save करने की functionality
- ✅ Topic subscription/unsubscription

### 2. Main.dart Updates (`lib/main.dart`)
- ✅ Firebase Messaging initialization
- ✅ Background message handler setup
- ✅ MessagingService initialization

### 3. Auth Service Updates (`lib/services/auth_service.dart`)
- ✅ Sign up के समय FCM token save करना
- ✅ Sign in के समय FCM token update करना
- ✅ Sign out के समय FCM token delete करना

### 4. Android Configuration (`android/app/src/main/AndroidManifest.xml`)
- ✅ Internet permission
- ✅ Post notifications permission (Android 13+)
- ✅ Vibrate permission
- ✅ Boot completed permission
- ✅ Default notification channel

---

## 🚀 कैसे Use करें:

### 1. App Run करें
```bash
flutter pub get
flutter run
```

### 2. Permissions
- Android 13+ पर notification permission automatically request होगी
- iOS पर notification permission automatically request होगी

### 3. FCM Token
- User sign in करने पर automatically Firestore में save होगा
- Token `users/{userId}/fcmToken` field में store होगा

---

## 📱 Push Notification भेजने के लिए:

### Firebase Console से:
1. Firebase Console → Cloud Messaging → New notification
2. Notification title और message दें
3. Target select करें (specific user या topic)
4. Send करें

### Backend से (Cloud Functions या Server):
```javascript
// Example: Send notification to specific user
const admin = require('firebase-admin');

async function sendNotification(userId, title, body, data) {
  // Get user's FCM token from Firestore
  const userDoc = await admin.firestore()
    .collection('users')
    .doc(userId)
    .get();
  
  const fcmToken = userDoc.data()?.fcmToken;
  
  if (fcmToken) {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: data, // Optional: custom data
    });
  }
}
```

### Chat Message के लिए Notification:
```javascript
// When a new message is sent
async function onMessageCreated(snapshot, context) {
  const message = snapshot.data();
  const receiverId = message.receiverId;
  
  // Get receiver's FCM token
  const receiverDoc = await admin.firestore()
    .collection('users')
    .doc(receiverId)
    .get();
  
  const fcmToken = receiverDoc.data()?.fcmToken;
  
  if (fcmToken) {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: message.senderName || 'New Message',
        body: message.text || 'You have a new message',
      },
      data: {
        type: 'chat_message',
        chatId: context.params.chatId,
        senderId: message.senderId,
      },
    });
  }
}
```

---

## 🔧 Customization:

### Foreground Notifications Show करने के लिए:
अगर आप foreground में notifications show करना चाहते हैं, तो `flutter_local_notifications` package add करें:

```yaml
# pubspec.yaml
dependencies:
  flutter_local_notifications: ^17.0.0
```

फिर `messaging_service.dart` में `_handleForegroundMessage` method update करें।

### Notification Tap पर Navigate करने के लिए:
`_handleNotificationTap` method में navigation logic add करें:

```dart
void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;
  if (data['type'] == 'chat_message') {
    // Navigate to chat screen
    // Example: Navigator.pushNamed(context, '/chat', arguments: data['chatId']);
  }
}
```

---

## 📋 Firestore Structure:

### Users Collection:
```
users/
  └── {userId}/
      ├── uid
      ├── name
      ├── email
      ├── isOnline
      ├── lastSeen
      └── fcmToken  ← FCM token यहाँ store होगा
```

---

## ⚠️ Important Notes:

1. **Android 13+**: `POST_NOTIFICATIONS` permission automatically request होगी
2. **iOS**: Notification permission automatically request होगी
3. **Token Refresh**: Token automatically refresh होगा और Firestore में update होगा
4. **Background Messages**: Background messages handle करने के लिए top-level function use किया गया है
5. **Token Management**: Sign out पर token automatically delete हो जाएगा

---

## 🧪 Testing:

### 1. Test Token:
```dart
final messagingService = MessagingService();
String? token = await messagingService.getToken();
print('FCM Token: $token');
```

### 2. Test Notification:
Firebase Console → Cloud Messaging → Send test message
- FCM token paste करें
- Message send करें

### 3. Test Scenarios:
- ✅ App foreground में है - notification show होनी चाहिए
- ✅ App background में है - notification show होनी चाहिए
- ✅ App closed है - notification tap करने पर app open होनी चाहिए

---

## 🐛 Troubleshooting:

### Issue: Notifications नहीं आ रही
1. Check करें कि FCM token Firestore में save हो रहा है
2. Check करें कि permissions granted हैं
3. Check करें कि `google-services.json` सही है

### Issue: Background messages handle नहीं हो रहे
1. Check करें कि `firebaseMessagingBackgroundHandler` top-level function है
2. Check करें कि `FirebaseMessaging.onBackgroundMessage` properly setup है

### Issue: Token null आ रहा है
1. Check करें कि Firebase properly initialized है
2. Check करें कि permissions granted हैं
3. Device/emulator पर internet connection है या नहीं

---

## ✅ Setup Complete!

अब आपका Firebase Messaging setup complete है! 🎉

Push notifications भेजने और receive करने के लिए ready है।

