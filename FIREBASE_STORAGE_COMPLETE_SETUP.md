# Firebase Storage Complete Setup Guide 🔥

## Error You're Seeing ❌

```
Failed to send image: Exception: Failed to upload image:
[firebase_storage/object-not-found]
No object exists at the desired reference.
```

**Meaning:** Firebase Storage is not enabled or not configured properly in your Firebase project.

---

## Step-by-Step Fix 🛠️

### Step 1: Enable Firebase Storage

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **apnichat**
3. Click on **Storage** in left menu (🗄️ icon)
4. Click **Get Started** button
5. Click **Next** → **Done**

**Important:** If you see "No default bucket", you need to create one:
- Click **Get Started**
- Select location (choose closest to your users)
- Click **Done**

---

### Step 2: Set Storage Rules

After enabling Storage:

1. Click on **Rules** tab
2. Replace existing rules with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Chat images - anyone can read, only uploader can write
    match /chat_images/{userId}/{imageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Profile photos - anyone can read, only owner can write
    match /profile_photos/{userId}.jpg {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Voice messages - anyone can read, only uploader can write
    match /voices/{userId}/{voiceId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

3. Click **Publish**

---

### Step 3: Verify Storage is Working

Run this test in your app:

1. Login to app
2. Open any chat
3. Click image button (📷)
4. Select an image
5. You should see:
   - ✅ "Uploading image..." message
   - ✅ Progress in console logs
   - ✅ "Image sent successfully!" message
   - ✅ Image appears in chat

---

## Alternative Setup (If Above Doesn't Work)

### Option A: Use Public Rules (FOR TESTING ONLY!)

**⚠️ WARNING: Only use this for testing, NOT for production!**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;  // Anyone can read/write
    }
  }
}
```

If images upload with these rules, it means your authentication is working but the restrictive rules were blocking uploads.

### Option B: Check Firebase Config

Verify your Firebase configuration in Android/iOS:

**Android (`android/app/google-services.json`):**
```json
{
  "project_info": {
    "project_id": "your-project-id",
    "storage_bucket": "your-project-id.appspot.com"  // ← Check this exists
  }
}
```

**iOS (`ios/Runner/GoogleService-Info.plist`):**
```xml
<key>STORAGE_BUCKET</key>
<string>your-project-id.appspot.com</string>  <!-- Check this exists -->
```

If `storage_bucket` is missing:
1. Go to Firebase Console
2. Project Settings → General
3. Download new `google-services.json` and `GoogleService-Info.plist`
4. Replace old files
5. Run: `flutter clean && flutter pub get`

---

## Testing After Setup ✅

### Test 1: Profile Photo Upload
1. Go to Profile screen
2. Tap on profile photo
3. Select image from gallery
4. Should upload successfully

### Test 2: Chat Image Upload
1. Open any chat
2. Tap image icon (📷)
3. Select image
4. Image should upload and appear in chat

### Test 3: Check Firebase Console
1. Go to Firebase Console → Storage
2. Click on **Files** tab
3. You should see folders:
   - `chat_images/`
   - `profile_photos/`

---

## Common Errors & Solutions 🔧

### Error: "object-not-found"
**Cause:** Storage not enabled or bucket doesn't exist
**Solution:** Follow Step 1 above

### Error: "unauthorized" or "permission-denied"
**Cause:** Storage rules are too restrictive
**Solution:** Follow Step 2 above

### Error: "network-request-failed"
**Cause:** No internet connection
**Solution:** Check your internet

### Error: "unauthenticated"
**Cause:** User not logged in
**Solution:** Make sure user is signed in with Google

---

## Code Changes Made ✅

Updated `lib/services/storage_service.dart`:

1. ✅ Better error handling with specific messages
2. ✅ File validation before upload
3. ✅ Progress monitoring (check logs)
4. ✅ Metadata for better file tracking
5. ✅ Changed path from `images/` to `chat_images/` for clarity

---

## Verify Setup Checklist ✓

Before testing, make sure:

- [ ] Firebase Storage is enabled in Console
- [ ] Storage rules are published
- [ ] `google-services.json` has `storage_bucket`
- [ ] App is rebuilt after config changes
- [ ] User is logged in
- [ ] Internet connection is working

---

## Quick Test Command

Run in terminal to check if Storage is accessible:

```bash
# Check if you can access Firebase Storage
flutter run

# In app, try uploading image
# Check logs for "Upload progress: XX%"
```

---

## Still Not Working? 🤔

### Debug Steps:

1. **Check Logs:**
   ```bash
   flutter logs
   # Look for "Upload progress" messages
   ```

2. **Verify Authentication:**
   - Make sure user is logged in
   - Check Firebase Console → Authentication
   - User should appear in users list

3. **Check Internet:**
   - Try opening browser
   - Test with simple website

4. **Reinstall App:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

5. **Check Firebase Project:**
   - Go to Firebase Console
   - Project Settings → General
   - Verify "Default GCS bucket" exists
   - Should be: `your-project-id.appspot.com`

---

## What Happens When Image Uploads Successfully ✨

```
User taps image icon
    ↓
[0ms] Image picker opens
    ↓
[500ms] User selects image
    ↓
[1s] File validation starts
    ↓
[1.2s] "Uploading image..." shows
    ↓
[1.5s] Upload starts to Firebase Storage
    ↓
[2s] Progress: 25%
    ↓
[2.5s] Progress: 50%
    ↓
[3s] Progress: 75%
    ↓
[3.5s] Progress: 100%
    ↓
[4s] Get download URL
    ↓
[4.2s] Save to Firestore
    ↓
[4.5s] "Image sent successfully!" 🎉
    ↓
[5s] Image appears in chat!
```

---

## Summary 📝

**Problem:** Firebase Storage not enabled/configured

**Solution:**
1. Enable Firebase Storage in Console
2. Set proper Storage rules
3. Verify config files have storage_bucket
4. Rebuild app
5. Test upload

**Expected Result:** Images upload successfully with progress indicator! 🚀

---

Need more help? Check Firebase Console logs or share the exact error message!
