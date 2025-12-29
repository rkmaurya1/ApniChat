# Firebase Project कैसे Create करें - Step by Step Guide

## 📋 Prerequisites (जरूरी चीजें)
- Google Account (Gmail)
- Internet Connection
- 10-15 minutes का समय

---

## 🚀 Step 1: Firebase Console में जाएं

1. Browser खोलें (Chrome/Firefox/Safari)
2. इस link पर जाएं: **https://console.firebase.google.com/**
3. अपने Google Account से **Sign In** करें

---

## 🆕 Step 2: नया Project Create करें

1. Firebase Console के homepage पर **"Add project"** या **"Create a project"** button पर click करें
2. **Project name** दें (जैसे: `apnichat` या `my-chat-app`)
3. **Continue** button click करें
4. **Google Analytics** enable करें या skip करें (optional है)
   - अगर enable करते हैं, तो Analytics account select करें या नया बनाएं
5. **Create project** button click करें
6. कुछ seconds wait करें - Firebase project create हो रहा है
7. **Continue** button click करें जब project ready हो जाए

---

## 📱 Step 3: Android App Add करें

1. Project dashboard पर **Android icon** (🤖) पर click करें
2. **Android package name** दें: `com.example.apnichat`
   - ⚠️ **Important**: यह exact वही होना चाहिए जो आपके `android/app/build.gradle.kts` में है
3. **App nickname** (optional): `ApniChat Android`
4. **Register app** button click करें
5. **google-services.json** file download करें
6. Download की गई file को अपने project में copy करें:
   ```
   android/app/google-services.json
   ```
   - पुरानी placeholder file को replace करें
7. **Next** → **Next** → **Continue to console** click करें

---

## 🍎 Step 4: iOS App Add करें (अगर iOS चाहिए)

1. Project dashboard पर **iOS icon** (🍎) पर click करें
2. **iOS bundle ID** दें: `com.example.apnichat`
   - ⚠️ **Important**: यह exact वही होना चाहिए जो आपके iOS project में है
3. **App nickname** (optional): `ApniChat iOS`
4. **Register app** button click करें
5. **GoogleService-Info.plist** file download करें
6. Download की गई file को अपने project में copy करें:
   ```
   ios/Runner/GoogleService-Info.plist
   ```
   - पुरानी placeholder file को replace करें
7. **Next** → **Next** → **Continue to console** click करें

---

## 🔐 Step 5: Authentication Enable करें

1. Left sidebar में **Authentication** पर click करें
2. **Get started** button click करें
3. **Sign-in method** tab पर जाएं
4. **Email/Password** provider पर click करें
5. **Enable** toggle ON करें
6. **Save** button click करें

---

## 💾 Step 6: Firestore Database Create करें

1. Left sidebar में **Firestore Database** पर click करें
2. **Create database** button click करें
3. **Start in test mode** select करें (development के लिए)
   - ⚠️ Production में security rules जरूर set करें
4. **Next** click करें
5. **Location** select करें (जैसे: `asia-south1` - Mumbai)
   - अपने location के nearest region choose करें
6. **Enable** button click करें
7. कुछ seconds wait करें - database create हो रहा है

### Security Rules Set करें:
1. Firestore Database page पर **Rules** tab पर जाएं
2. नीचे दिए गए rules को copy करके paste करें:
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
3. **Publish** button click करें

---

## 📦 Step 7: Storage Enable करें

1. Left sidebar में **Storage** पर click करें
2. **Get started** button click करें
3. **Start in test mode** select करें
4. **Next** click करें
5. **Location** select करें (Firestore के same location choose करें)
6. **Done** click करें

### Storage Rules Set करें:
1. Storage page पर **Rules** tab पर जाएं
2. नीचे दिए गए rules को copy करके paste करें:
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
3. **Publish** button click करें

---

## 🔔 Step 8: Cloud Messaging Setup (Optional - Push Notifications के लिए)

1. Left sidebar में **Cloud Messaging** पर click करें
2. अगर first time है, तो **Get started** click करें
3. Android के लिए:
   - Firebase Cloud Messaging API (V1) enable करें
   - Server key note करें (अगर चाहिए)
4. iOS के लिए:
   - APNs Authentication Key upload करें (अगर iOS app है)

---

## ✅ Step 9: Verification (जांच करें)

अपने project में ये files check करें:

### Android:
- ✅ `android/app/google-services.json` - actual file होनी चाहिए (placeholder नहीं)
- File में `YOUR_PROJECT_ID` या `YOUR_API_KEY` जैसे text नहीं होने चाहिए

### iOS:
- ✅ `ios/Runner/GoogleService-Info.plist` - actual file होनी चाहिए
- File में `YOUR_PROJECT_ID` या `YOUR_API_KEY` जैसे text नहीं होने चाहिए

---

## 🎯 Step 10: App Run करें

1. Terminal में project folder में जाएं:
   ```bash
   cd /Users/tryeno_team/apnichat
   ```

2. Dependencies install करें:
   ```bash
   flutter pub get
   ```

3. App run करें:
   ```bash
   flutter run
   ```

---

## ❌ Common Issues और Solutions

### Issue 1: "FirebaseApp not initialized"
**Solution**: 
- `google-services.json` file सही location में है या नहीं check करें
- `android/app/build.gradle.kts` में `google-services` plugin add है या नहीं check करें

### Issue 2: "Package name mismatch"
**Solution**:
- Firebase Console में दिया गया package name और `build.gradle.kts` में दिया गया package name same होना चाहिए

### Issue 3: "Permission denied" errors
**Solution**:
- Firestore और Storage के security rules check करें
- Rules में `request.auth != null` condition है या नहीं verify करें

### Issue 4: "Authentication not enabled"
**Solution**:
- Firebase Console → Authentication → Sign-in method में Email/Password enable है या नहीं check करें

---

## 📞 Help

अगर कोई problem आए:
1. Firebase Console में project settings check करें
2. Error message को carefully read करें
3. `FIREBASE_SETUP.md` file भी देखें

---

## 🎉 Success!

अगर सब कुछ सही है, तो:
- ✅ App successfully run होगी
- ✅ Sign up/Sign in काम करेगा
- ✅ Messages send/receive होंगे
- ✅ Images upload होंगी

**Happy Coding! 🚀**

