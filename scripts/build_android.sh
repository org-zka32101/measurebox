#!/bin/bash

# MeasureTracker Android Build Script
# Purpose: Automate Android build process for testing and release
# Usage: ./build_android.sh [debug|release] [apk|aab]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
BUILD_MODE="${1:-debug}"
BUILD_FORMAT="${2:-apk}"
BUILD_OUTPUT_DIR="$PROJECT_DIR/build"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}MeasureTracker Android Build Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Pre-flight checks
echo -e "${YELLOW}[1/6] Pre-flight checks...${NC}"

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter not found in PATH${NC}"
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

if [ ! -f "$PROJECT_DIR/pubspec.yaml" ]; then
    echo -e "${RED}✗ pubspec.yaml not found${NC}"
    exit 1
fi

if [ ! -f "$PROJECT_DIR/android/app/google-services.json" ]; then
    echo -e "${YELLOW}⚠ Warning: google-services.json not found${NC}"
    echo "Download from Firebase Console:"
    echo "https://console.firebase.google.com/project/petit-works-utility/settings/general/android:com.yourwish.measuretrackers"
    echo ""
fi

echo -e "${GREEN}✓ All tools available${NC}"
echo ""

# Step 2: Clean build artifacts
echo -e "${YELLOW}[2/6] Cleaning build artifacts...${NC}"
flutter clean
echo -e "${GREEN}✓ Cleaned${NC}"
echo ""

# Step 3: Get dependencies
echo -e "${YELLOW}[3/6] Fetching dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies updated${NC}"
echo ""

# Step 4: Generate Hive models
echo -e "${YELLOW}[4/6] Generating Hive models...${NC}"
flutter pub run build_runner build --delete-conflicting-outputs
echo -e "${GREEN}✓ Code generation complete${NC}"
echo ""

# Step 5: Validate Android configuration
echo -e "${YELLOW}[5/6] Validating Android configuration...${NC}"

if ! grep -q "RECORD_AUDIO" "$PROJECT_DIR/android/app/src/main/AndroidManifest.xml"; then
    echo -e "${RED}✗ RECORD_AUDIO permission not in AndroidManifest.xml${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Configuration valid${NC}"
echo ""

# Step 6: Build Android app
echo -e "${YELLOW}[6/6] Building Android application (${BUILD_MODE} ${BUILD_FORMAT})...${NC}"

case "$BUILD_FORMAT" in
  apk)
    if [ "$BUILD_MODE" = "debug" ]; then
      flutter build apk --debug
      BUILD_PATH="$BUILD_OUTPUT_DIR/app/outputs/apk/debug"
    elif [ "$BUILD_MODE" = "release" ]; then
      flutter build apk --release --split-per-abi
      BUILD_PATH="$BUILD_OUTPUT_DIR/app/outputs/apk/release"
    else
      echo -e "${RED}✗ Invalid build mode: $BUILD_MODE${NC}"
      exit 1
    fi
    ;;
  aab)
    if [ "$BUILD_MODE" != "release" ]; then
      echo -e "${RED}✗ AAB (App Bundle) only available for release builds${NC}"
      exit 1
    fi
    flutter build appbundle --release
    BUILD_PATH="$BUILD_OUTPUT_DIR/app/outputs/bundle/release"
    ;;
  *)
    echo -e "${RED}✗ Invalid format: $BUILD_FORMAT${NC}"
    echo "Usage: $0 [debug|release] [apk|aab]"
    exit 1
    ;;
esac

echo -e "${GREEN}✓ Build complete${NC}"
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Android Build Successful!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Mode:        ${BLUE}${BUILD_MODE}${NC}"
echo -e "Format:      ${BLUE}${BUILD_FORMAT}${NC}"
echo -e "Output:      ${BLUE}${BUILD_PATH}${NC}"
echo -e "Timestamp:   ${BLUE}${TIMESTAMP}${NC}"
echo ""

if [ "$BUILD_MODE" = "debug" ]; then
    echo -e "${YELLOW}Next steps (Debug):${NC}"
    echo "1. Connect Android device via USB"
    echo "2. Enable USB Debugging on device"
    echo "3. Run: flutter run -d <device_id>"
    echo "4. Or install APK directly:"
    echo "   adb install $BUILD_PATH/app-debug.apk"
elif [ "$BUILD_MODE" = "release" ] && [ "$BUILD_FORMAT" = "apk" ]; then
    echo -e "${YELLOW}Next steps (Release APK):${NC}"
    echo "1. Connect Android device via USB"
    echo "2. Install multiple APKs:"
    echo "   adb install-multiple \\"
    echo "     $BUILD_PATH/app-arm64-v8a-release.apk \\"
    echo "     $BUILD_PATH/app-armeabi-v7a-release.apk \\"
    echo "     $BUILD_PATH/app-x86_64-release.apk"
    echo "3. Or upload to Google Play Console"
elif [ "$BUILD_MODE" = "release" ] && [ "$BUILD_FORMAT" = "aab" ]; then
    echo -e "${YELLOW}Next steps (Release AAB):${NC}"
    echo "1. Upload to Google Play Console:"
    echo "   https://play.google.com/console"
    echo "2. Navigate to: Release → Production → Upload AAB"
    echo "3. AAB file: $BUILD_PATH/app-release.aab"
fi

echo ""
