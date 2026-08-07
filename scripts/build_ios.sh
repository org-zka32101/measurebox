#!/bin/bash

# MeasureTracker iOS Build Script
# Purpose: Automate iOS build process for testing and release
# Usage: ./build_ios.sh [debug|release]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
IOS_DIR="$PROJECT_DIR/ios"
BUILD_MODE="${1:-debug}"
BUILD_OUTPUT_DIR="$PROJECT_DIR/build"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}MeasureTracker iOS Build Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Pre-flight checks
echo -e "${YELLOW}[1/7] Pre-flight checks...${NC}"

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter not found in PATH${NC}"
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

if ! command -v pod &> /dev/null; then
    echo -e "${RED}✗ CocoaPods not found${NC}"
    echo "Please install: sudo gem install cocoapods"
    exit 1
fi

if [ ! -f "$PROJECT_DIR/pubspec.yaml" ]; then
    echo -e "${RED}✗ pubspec.yaml not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All tools available${NC}"
echo ""

# Step 2: Clean build artifacts
echo -e "${YELLOW}[2/7] Cleaning build artifacts...${NC}"
flutter clean
rm -rf "$IOS_DIR/Pods"
rm -f "$IOS_DIR/Podfile.lock"
echo -e "${GREEN}✓ Cleaned${NC}"
echo ""

# Step 3: Get dependencies
echo -e "${YELLOW}[3/7] Fetching dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies updated${NC}"
echo ""

# Step 4: Generate Hive models
echo -e "${YELLOW}[4/7] Generating Hive models...${NC}"
flutter pub run build_runner build --delete-conflicting-outputs
echo -e "${GREEN}✓ Code generation complete${NC}"
echo ""

# Step 5: Install CocoaPods
echo -e "${YELLOW}[5/7] Installing CocoaPods dependencies...${NC}"
cd "$IOS_DIR"
pod install --repo-update
cd "$PROJECT_DIR"
echo -e "${GREEN}✓ CocoaPods installed${NC}"
echo ""

# Step 6: Validate Firebase config
echo -e "${YELLOW}[6/7] Validating iOS configuration...${NC}"

if [ ! -f "$IOS_DIR/Runner/GoogleService-Info.plist" ]; then
    echo -e "${YELLOW}⚠ Warning: GoogleService-Info.plist not found${NC}"
    echo "Download from Firebase Console:"
    echo "https://console.firebase.google.com/project/petit-works-utility/settings/general/ios:com.petitworksapps.measuretracker"
    echo ""
fi

if ! grep -q "NSMicrophoneUsageDescription" "$IOS_DIR/Runner/Info.plist"; then
    echo -e "${RED}✗ Microphone permission not in Info.plist${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Configuration valid${NC}"
echo ""

# Step 7: Build iOS app
echo -e "${YELLOW}[7/7] Building iOS application (${BUILD_MODE})...${NC}"

if [ "$BUILD_MODE" = "debug" ]; then
    flutter build ios --debug
    BUILD_PATH="$BUILD_OUTPUT_DIR/ios/Debug-iphoneos"
elif [ "$BUILD_MODE" = "release" ]; then
    flutter build ios --release
    BUILD_PATH="$BUILD_OUTPUT_DIR/ios/Release-iphoneos"
else
    echo -e "${RED}✗ Invalid build mode: $BUILD_MODE${NC}"
    echo "Usage: $0 [debug|release]"
    exit 1
fi

echo -e "${GREEN}✓ Build complete${NC}"
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ iOS Build Successful!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Mode:        ${BLUE}${BUILD_MODE}${NC}"
echo -e "Output:      ${BLUE}${BUILD_PATH}${NC}"
echo -e "Timestamp:   ${BLUE}${TIMESTAMP}${NC}"
echo ""

if [ "$BUILD_MODE" = "debug" ]; then
    echo -e "${YELLOW}Next steps (Debug):${NC}"
    echo "1. Connect iOS device via USB"
    echo "2. Run: flutter run -d <device_id>"
    echo "3. Or open in Xcode:"
    echo "   open $IOS_DIR/Runner.xcworkspace"
elif [ "$BUILD_MODE" = "release" ]; then
    echo -e "${YELLOW}Next steps (Release):${NC}"
    echo "1. Archive for App Store:"
    echo "   cd $IOS_DIR"
    echo "   xcodebuild -workspace Runner.xcworkspace \\"
    echo "     -scheme Runner -configuration Release \\"
    echo "     -archivePath build/Runner.xcarchive archive"
    echo "2. Upload to App Store via Xcode > Organizer"
fi

echo ""
