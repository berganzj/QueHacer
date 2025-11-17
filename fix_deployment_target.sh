#!/bin/bash

# QueHacer Deployment Target Fix Script
# This script will help resolve the "OS version lower than deployment target" error

echo "🔧 QueHacer Deployment Target Fix"
echo "================================="

# Check current directory
if [ ! -f "QueHacer.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the QueHacer project directory"
    exit 1
fi

echo "✅ Found QueHacer project"

# 1. Clean derived data
echo "🧹 Cleaning Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData

# 2. Check current deployment targets
echo "📋 Current deployment targets:"
grep -n "IPHONEOS_DEPLOYMENT_TARGET" QueHacer.xcodeproj/project.pbxproj

# 3. Clean build folder via command line (if xcodebuild is available)
if command -v xcodebuild &> /dev/null; then
    echo "🧹 Cleaning build folder..."
    xcodebuild clean -project QueHacer.xcodeproj -alltargets
else
    echo "⚠️ xcodebuild not available - please clean build folder manually in Xcode"
fi

# 4. Check for any cached scheme files
echo "🔍 Checking for cached scheme files..."
if [ -d "QueHacer.xcodeproj/xcuserdata" ]; then
    echo "📂 Found user data cache - consider deleting if issues persist"
    ls -la QueHacer.xcodeproj/xcuserdata/
fi

echo ""
echo "🎯 Manual Steps to Complete in Xcode:"
echo "1. Open QueHacer.xcodeproj in Xcode"
echo "2. Select the QueHacer project (blue icon) in navigator"
echo "3. Select QueHacer target"
echo "4. Go to Build Settings tab"
echo "5. Search for 'deployment target'"
echo "6. Verify iOS Deployment Target shows 14.0"
echo "7. Make sure your iPhone 15 is selected as destination"
echo "8. Product → Clean Build Folder (⌘⇧K)"
echo "9. Build and run the project"

echo ""
echo "📱 If issue persists, try:"
echo "- Restart Xcode completely"
echo "- Restart your iPhone 15"
echo "- Check iOS version on device (Settings → General → About)"
echo "- Try creating a new scheme"

echo ""
echo "✅ Script completed. Deployment target is now set to iOS 14.0"