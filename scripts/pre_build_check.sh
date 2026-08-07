#!/bin/bash

# MeasureTracker Pre-Build Verification Script
# Purpose: Verify all build prerequisites before building
# Usage: ./pre_build_check.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASS=0
WARN=0
FAIL=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}MeasureTracker Pre-Build Check${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check function
check_file() {
    local file=$1
    local description=$2

    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗${NC} $description - Not found: $file"
        ((FAIL++))
        return 1
    fi
}

check_dir() {
    local dir=$1
    local description=$2

    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $description"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗${NC} $description - Not found: $dir"
        ((FAIL++))
        return 1
    fi
}

check_content() {
    local file=$1
    local pattern=$2
    local description=$3

    if [ -f "$file" ] && grep -q "$pattern" "$file"; then
        echo -e "${GREEN}✓${NC} $description"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗${NC} $description"
        ((FAIL++))
        return 1
    fi
}

check_warning() {
    local file=$1
    local description=$2

    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}⚠${NC} $description - Needed for production: $file"
        ((WARN++))
        return 1
    fi
    return 0
}

# Section 1: Project Files
echo -e "${BLUE}[1/5] Project Structure${NC}"
check_file "pubspec.yaml" "pubspec.yaml exists"
check_file "CLAUDE.md" "CLAUDE.md exists"
check_file "pubspec.lock" "pubspec.lock exists"
check_dir "lib" "lib/ directory exists"
echo ""

# Section 2: iOS Configuration
echo -e "${BLUE}[2/5] iOS Configuration${NC}"
check_file "ios/Podfile" "ios/Podfile created"
check_file "ios/Runner/Info.plist" "ios/Runner/Info.plist exists"
check_content "ios/Runner/Info.plist" "NSMicrophoneUsageDescription" "Microphone permission in Info.plist"
check_warning "ios/Runner/GoogleService-Info.plist" "iOS Firebase configuration"
echo ""

# Section 3: Android Configuration
echo -e "${BLUE}[3/5] Android Configuration${NC}"
check_file "android/app/build.gradle" "android/app/build.gradle exists"
check_file "android/app/src/main/AndroidManifest.xml" "AndroidManifest.xml exists"
check_content "android/app/src/main/AndroidManifest.xml" "RECORD_AUDIO" "Microphone permission in AndroidManifest"
check_warning "android/app/google-services.json" "Android Firebase configuration"
echo ""

# Section 4: Build Scripts
echo -e "${BLUE}[4/5] Build Scripts${NC}"
check_file "scripts/build_ios.sh" "iOS build script exists"
check_file "scripts/build_android.sh" "Android build script exists"
if [ -x "scripts/build_ios.sh" ]; then
    echo -e "${GREEN}✓${NC} iOS build script is executable"
    ((PASS++))
else
    echo -e "${YELLOW}⚠${NC} iOS build script not executable - fixing..."
    chmod +x scripts/build_ios.sh 2>/dev/null && echo -e "${GREEN}  Fixed${NC}" && ((PASS++)) || ((WARN++))
fi
if [ -x "scripts/build_android.sh" ]; then
    echo -e "${GREEN}✓${NC} Android build script is executable"
    ((PASS++))
else
    echo -e "${YELLOW}⚠${NC} Android build script not executable - fixing..."
    chmod +x scripts/build_android.sh 2>/dev/null && echo -e "${GREEN}  Fixed${NC}" && ((PASS++)) || ((WARN++))
fi
echo ""

# Section 5: Documentation
echo -e "${BLUE}[5/5] Documentation${NC}"
check_file "iOS_BUILD_GUIDE.md" "iOS Build Guide exists"
check_file "ANDROID_BUILD_GUIDE.md" "Android Build Guide exists"
check_file "RELEASE_CHECKLIST.md" "Release Checklist exists"
check_file "FIREBASE_SETUP.md" "Firebase Setup Guide exists"
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Check Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Passed:  ${GREEN}$PASS${NC}"
echo -e "Warnings: ${YELLOW}$WARN${NC}"
echo -e "Failed:  ${RED}$FAIL${NC}"
echo ""

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}✗ Build prerequisites NOT met${NC}"
    echo ""
    echo "Required files for building:"
    echo "  iOS:     ios/Runner/GoogleService-Info.plist"
    echo "  Android: android/app/google-services.json"
    echo ""
    echo "Download from Firebase Console:"
    echo "  https://console.firebase.google.com/project/petit-works-utility"
    echo ""
    echo "See FIREBASE_SETUP.md for detailed instructions"
    exit 1
elif [ $WARN -gt 0 ]; then
    echo -e "${YELLOW}⚠ Build possible, but Firebase files missing${NC}"
    echo ""
    echo "To enable Firebase features, download:"
    echo "  iOS:     GoogleService-Info.plist → ios/Runner/"
    echo "  Android: google-services.json → android/app/"
    echo ""
    echo "See FIREBASE_SETUP.md for detailed instructions"
    echo ""
    if command -v flutter &> /dev/null; then
        echo "You can proceed with build (Firebase features disabled):"
        echo "  ./scripts/build_ios.sh debug"
        echo "  ./scripts/build_android.sh debug apk"
    fi
    exit 0
else
    echo -e "${GREEN}✓ All prerequisites met - Ready to build!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Verify Firebase files:"
    echo "     - ios/Runner/GoogleService-Info.plist"
    echo "     - android/app/google-services.json"
    echo ""
    echo "  2. Run build scripts:"
    echo "     ./scripts/build_ios.sh debug"
    echo "     ./scripts/build_android.sh debug apk"
    exit 0
fi
