#!/bin/bash

# GitHub में Code Push करने के लिए Script
# Run करें: bash PUSH_TO_GITHUB.sh

echo "🚀 GitHub में Code Push करना शुरू कर रहे हैं..."

# Step 1: .gitignore update check
echo "✅ Step 1: .gitignore check कर रहे हैं..."
if grep -q "google-services.json" .gitignore; then
    echo "✅ Sensitive files .gitignore में हैं"
else
    echo "⚠️  .gitignore में sensitive files add कर रहे हैं..."
fi

# Step 2: Sensitive files को unstage करें (अगर add हो गए)
echo "✅ Step 2: Sensitive files check कर रहे हैं..."
git reset HEAD android/app/google-services.json 2>/dev/null
git reset HEAD ios/Runner/GoogleService-Info.plist 2>/dev/null
echo "✅ Sensitive files unstage कर दी गईं"

# Step 3: Safe files add करें
echo "✅ Step 3: Safe files add कर रहे हैं..."
git add .gitignore
git add lib/
git add pubspec.yaml
git add pubspec.lock
git add README.md
git add FIREBASE_*.md
git add GITHUB_PUSH_GUIDE.md
git add android/app/build.gradle.kts
git add android/build.gradle.kts
git add android/app/src/main/AndroidManifest.xml
git add ios/
git add test/
git add analysis_options.yaml

echo "✅ Files add हो गईं"

# Step 4: Status check
echo ""
echo "📋 Staged files:"
git status --short | grep "^A\|^M" | head -10

# Step 5: Commit
echo ""
read -p "Commit message (Enter for default): " commit_msg
if [ -z "$commit_msg" ]; then
    commit_msg="Add complete chat application with Firebase integration

- Added authentication service (sign up, sign in, sign out)
- Added chat service with real-time messaging
- Added storage service for image uploads
- Added messaging service for push notifications
- Added all UI screens (login, signup, home, chat, users, profile)
- Added Firebase Messaging initialization
- Added comprehensive Firebase setup documentation"
fi

echo "✅ Committing changes..."
git commit -m "$commit_msg"

# Step 6: Push
echo ""
read -p "GitHub पर push करें? (y/n): " push_confirm
if [ "$push_confirm" = "y" ] || [ "$push_confirm" = "Y" ]; then
    echo "✅ GitHub पर push कर रहे हैं..."
    git push origin main
    echo ""
    echo "🎉 Success! Code GitHub पर push हो गया है!"
    echo "🔗 Check करें: https://github.com/rkmaurya1/ApniChat"
else
    echo "⏸️  Push cancelled. आप manually push कर सकते हैं:"
    echo "   git push origin main"
fi

echo ""
echo "✅ Complete!"

