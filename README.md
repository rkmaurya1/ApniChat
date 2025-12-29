# ApniChat - Flutter Chat Application

A complete real-time chat application built with Flutter and Firebase.

## Features

### Basic Features
- ✅ User Login and Signup (Email)
- ✅ One-to-One Chat
- ✅ Real-time Messaging
- ✅ User Online/Offline Status
- ✅ Message Time and Date

### Advanced Features
- ✅ User Profile Photo
- ✅ Image Messages
- ✅ Last Seen Status
- ✅ Read Receipts (✔✔)
- 🔄 Voice Messages (Infrastructure ready)
- 🔄 Push Notifications (Infrastructure ready)
- 🔄 Group Chat (Can be added)

## Technology Stack

- **Frontend**: Flutter
- **Backend**: Firebase
  - Firebase Authentication (Login/Signup)
  - Cloud Firestore (Real-time Messages)
  - Firebase Storage (Image Sharing)
  - Firebase Cloud Messaging (Push Notifications - ready)

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   ├── message_model.dart
│   └── chat_model.dart
├── services/                 # Business logic
│   ├── auth_service.dart
│   ├── chat_service.dart
│   └── storage_service.dart
├── screens/                  # UI screens
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── home_screen.dart
│   ├── chat_screen.dart
│   ├── users_screen.dart
│   └── profile_screen.dart
└── utils/                    # Utilities
    ├── constants.dart
    └── helpers.dart
```

## Firebase Database Structure

### Users Collection
```
users/
 └── userId/
     ├── name
     ├── email
     ├── photoUrl
     ├── isOnline
     └── lastSeen
```

### Chats Collection
```
chats/
 └── chatId/
     ├── userId1
     ├── userId2
     ├── lastMessage
     ├── lastMessageTime
     ├── lastMessageSenderId
     └── messages/
         └── messageId/
             ├── senderId
             ├── receiverId
             ├── text
             ├── imageUrl
             ├── voiceUrl
             ├── type
             ├── time
             └── isRead
```

## Setup Instructions

### 1. Prerequisites
- Flutter SDK installed
- Firebase account
- Android Studio / Xcode (for mobile development)

### 2. Firebase Setup

**Important**: You need to replace the placeholder Firebase configuration files with your actual Firebase project files.

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Add Android app with package name: `com.example.apnichat`
4. Download `google-services.json` and replace `android/app/google-services.json`
5. Add iOS app (if needed) and replace `ios/Runner/GoogleService-Info.plist`
6. Enable the following services:
   - Authentication (Email/Password)
   - Firestore Database
   - Storage
   - Cloud Messaging (optional)

See `FIREBASE_SETUP.md` for detailed Firebase setup instructions including security rules.

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the App

```bash
flutter run
```

## Configuration Files

The following files need to be replaced with your Firebase project configuration:

- `android/app/google-services.json` - Android Firebase config
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase config

**Note**: These files are currently placeholders and must be replaced with your actual Firebase configuration files.

## Security Rules

Make sure to set up proper security rules in Firebase Console. See `FIREBASE_SETUP.md` for recommended security rules.

## Dependencies

- `firebase_core` - Firebase initialization
- `firebase_auth` - Authentication
- `cloud_firestore` - Real-time database
- `firebase_storage` - File storage
- `firebase_messaging` - Push notifications
- `image_picker` - Image selection
- `cached_network_image` - Image caching
- `intl` - Date/time formatting
- `uuid` - Unique ID generation

## Development

This app is built for job/interview purposes and demonstrates:
- Flutter UI/UX best practices
- Firebase integration
- Real-time data synchronization
- State management
- Clean architecture

## License

This project is for educational and portfolio purposes.
