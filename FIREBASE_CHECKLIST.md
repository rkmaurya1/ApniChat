# Firebase Setup Checklist ✅

## 📝 Quick Checklist

### Phase 1: Firebase Console Setup
- [ ] Firebase project create किया
- [ ] Android app add किया (package: `com.example.apnichat`)
- [ ] `google-services.json` download किया
- [ ] iOS app add किया (अगर चाहिए)
- [ ] `GoogleService-Info.plist` download किया

### Phase 2: Services Enable
- [ ] Authentication → Email/Password enable किया
- [ ] Firestore Database create किया
- [ ] Firestore Security Rules set किए
- [ ] Storage enable किया
- [ ] Storage Security Rules set किए
- [ ] Cloud Messaging setup किया (optional)

### Phase 3: Files Replace
- [ ] `android/app/google-services.json` replace किया
- [ ] `ios/Runner/GoogleService-Info.plist` replace किया (अगर iOS चाहिए)

### Phase 4: Code Verification
- [ ] `flutter pub get` run किया
- [ ] App successfully run हो रही है
- [ ] Sign up/Sign in test किया
- [ ] Messages send/receive test किया

---

## 🔍 Quick Verification Commands

```bash
# Dependencies check
flutter pub get

# Check if config files exist
ls android/app/google-services.json
ls ios/Runner/GoogleService-Info.plist

# Run app
flutter run
```

---

## 📍 Important Locations

| File | Location |
|------|----------|
| Android Config | `android/app/google-services.json` |
| iOS Config | `ios/Runner/GoogleService-Info.plist` |
| Main App Code | `lib/main.dart` |
| Auth Service | `lib/services/auth_service.dart` |
| Chat Service | `lib/services/chat_service.dart` |

---

## ⚠️ Common Mistakes to Avoid

1. ❌ Placeholder files को replace नहीं किया
2. ❌ Package name mismatch (Firebase vs build.gradle.kts)
3. ❌ Security rules set नहीं किए
4. ❌ Authentication enable नहीं किया
5. ❌ `flutter pub get` run नहीं किया

---

**Status**: Use this checklist to track your Firebase setup progress!

