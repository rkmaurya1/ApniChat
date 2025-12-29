# Firebase Setup Instructions

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Follow the setup wizard

## Step 2: Add Android App

1. In Firebase Console, click "Add app" and select Android
2. Package name: `com.example.apnichat`
3. Download `google-services.json`
4. Replace the file at `android/app/google-services.json` with your downloaded file

## Step 3: Add iOS App (if needed)

1. In Firebase Console, click "Add app" and select iOS
2. Bundle ID: `com.example.apnichat`
3. Download `GoogleService-Info.plist`
4. Replace the file at `ios/Runner/GoogleService-Info.plist` with your downloaded file

## Step 4: Enable Firebase Services

### Authentication
1. Go to Authentication > Sign-in method
2. Enable "Email/Password"

### Firestore Database
1. Go to Firestore Database
2. Click "Create database"
3. Start in **test mode** (for development)
4. Choose your preferred location

### Storage
1. Go to Storage
2. Click "Get started"
3. Start in **test mode** (for development)
4. Choose your preferred location

### Cloud Messaging (Optional - for push notifications)
1. Go to Cloud Messaging
2. Follow the setup instructions for your platform

## Step 5: Security Rules (Important!)

### Firestore Rules
Replace the default rules with:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /chats/{chatId} {
      allow read: if request.auth != null && 
        (resource.data.userId1 == request.auth.uid || 
         resource.data.userId2 == request.auth.uid);
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      
      match /messages/{messageId} {
        allow read: if request.auth != null && 
          (resource.data.senderId == request.auth.uid || 
           resource.data.receiverId == request.auth.uid);
        allow create: if request.auth != null && 
          request.resource.data.senderId == request.auth.uid;
        allow update: if request.auth != null && 
          resource.data.receiverId == request.auth.uid;
      }
    }
  }
}
```

### Storage Rules
Replace the default rules with:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /images/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /profile_photos/{userId}.jpg {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /voices/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 6: Run the App

1. Run `flutter pub get` to install dependencies
2. Make sure you've replaced the Firebase config files
3. Run `flutter run`

## Notes

- The placeholder Firebase config files are in the project but need to be replaced with your actual Firebase project files
- Make sure to update security rules before deploying to production
- Test mode is fine for development but should be changed for production

