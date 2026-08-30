# APK/AAB ビルド手順書

**対象**: MeasureTracker v1.0.0 リリース  
**日付**: 2026-08-30  
**ビルド環境**: macOS (iOS) / Linux or Windows (Android)

---

## 📋 前提条件

### 必須ツール
- Flutter 3.13.0 以上
- Dart 3.1.0 以上
- Android Studio (Android ビルド用)
- Xcode 15.0 以上 (iOS ビルド用)
- CocoaPods (iOS 依存管理)

### 必須ファイル
- `firebase_options.dart`: Firebase プロジェクト設定
- `google-services.json`: Android Firebase 設定
- `GoogleService-Info.plist`: iOS Firebase 設定

---

## 🔧 Step 1: 環境準備

### 1.1 Flutter & Dart 確認
```bash
flutter --version
dart --version
```

**期待される出力:**
```
Flutter 3.13.0+
Dart 3.1.0+
```

### 1.2 Firebase 設定ファイル配置

**Android**:
```bash
# google-services.json を android/app/ に配置
# アクセス: Firebase Console → プロジェクト設定 → google-services.json ダウンロード
cp google-services.json android/app/
```

**iOS**:
```bash
# GoogleService-Info.plist を ios/Runner/ に配置
# アクセス: Firebase Console → プロジェクト設定 → GoogleService-Info.plist ダウンロード
cp GoogleService-Info.plist ios/Runner/
```

### 1.3 firebase_options.dart 更新
```bash
# Firebase CLI で自動生成（推奨）
flutterfire configure --project=petit-works-utility
```

または手動編集:
```dart
// lib/firebase_options.dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
  projectId: 'petit-works-utility',
  storageBucket: 'petit-works-utility.appspot.com',
);
```

---

## 📦 Step 2: 依存関係インストール

### 2.1 パッケージダウンロード
```bash
cd /path/to/measurebox
flutter pub get
```

### 2.2 コード生成 (Hive)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**期待される出力:**
```
Building for Dart
building asset_graph
...
Built cache dir /.dart_tool/build/generated/.../
```

---

## 🎨 Step 3: アイコン生成

### 3.1 flutter_launcher_icons 実行
```bash
flutter pub run flutter_launcher_icons
```

**確認内容:**
```
✓ ios/Runner/Assets.xcassets/AppIcon.appiconset/
  - Icon-App-1024x1024@1x.png (✅ 生成済み)
  - Contents.json (✅ 生成済み)

✓ android/app/src/main/res/mipmap-*/
  - ic_launcher.png (✅ mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
```

---

## 🚀 Step 4: APK ビルド (Android)

### 4.1 デバッグビルド（テスト用）
```bash
flutter build apk --debug
```

**出力ファイル:**
```
build/app/outputs/flutter-apk/app-debug.apk
```

**テスト**:
```bash
# Android デバイスにインストール
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### 4.2 リリースビルド (Google Play 用)

#### 4.2.1 Keystore 生成（初回のみ）
```bash
keytool -genkey -v -keystore ~/measurebox.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias measurebox
```

**入力情報**:
```
姓名: MeasureTracker
組織単位: Engineering
組織: petit-works-apps
市区町村: Tokyo
都道府県: Tokyo
国コード: JP
```

#### 4.2.2 Gradle 設定 (android/key.properties)
```properties
storeFile=/Users/username/measurebox.jks
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=measurebox
```

**注意**: このファイルを `.gitignore` に追加してください

#### 4.2.3 リリースビルド実行
```bash
flutter build apk --release
# または
flutter build appbundle --release  # Google Play 推奨
```

**出力ファイル:**
```
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

### 4.3 ビルドサイズ最適化

```bash
# サイズレポート確認
flutter build apk --release --analyze-size
```

**期待される結果**: < 60MB (AAB), < 80MB (APK)

---

## 📱 Step 5: iOS ビルド (macOS 環境のみ)

### 5.1 CocoaPods セットアップ
```bash
cd ios
pod install
cd ..
```

### 5.2 デバッグビルド（テスト用）
```bash
flutter build ios --debug
```

### 5.3 リリースビルド

#### 5.3.1 ビルド実行
```bash
flutter build ios --release
```

#### 5.3.2 Xcode でアーカイブ生成
```bash
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath ../build/ios/Release.xcarchive \
  archive
```

#### 5.3.3 IPA エクスポート
```bash
xcodebuild -exportArchive \
  -archivePath ../build/ios/Release.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ../build/ios/ipa
```

**ExportOptions.plist** (事前作成):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store</string>
  <key>teamID</key>
  <string>YOUR_TEAM_ID</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>thinning</key>
  <string>&lt;none&gt;</string>
</dict>
</plist>
```

---

## ✅ Step 6: ビルド検証

### 6.1 APK 検証 (Android)
```bash
# アプリがクラッシュなく起動するか確認
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell am start -n com.yourwish.measuretrackers/.MainActivity

# ログ確認
adb logcat
```

### 6.2 iOS 検証
```bash
# Xcode でシミュレータに展開
open -a Simulator
flutter run -d "iPhone 14 Pro"
```

### 6.3 機能テスト

**共通**:
- [ ] アプリ起動確認
- [ ] ホーム画面表示
- [ ] プロジェクト作成
- [ ] 測定開始/停止
- [ ] データ保存確認

**Android 特有**:
- [ ] マイク権限リクエスト
- [ ] 位置情報権限リクエスト
- [ ] センサー利用確認

**iOS 特有**:
- [ ] マイク権限リクエスト
- [ ] 位置情報権限リクエスト
- [ ] App Tracking 許可リクエスト

---

## 📤 Step 7: App Store/Play Store 提出

### 7.1 Google Play Console 提出 (Android)

```bash
# 1. Google Play Console にログイン
# https://play.google.com/console

# 2. MeasureTracker アプリを選択

# 3. リリース → テスト → 内部テスト
#    app-release.aab をアップロード

# 4. 各セクション確認:
#    - コンテンツレーティング ✅
#    - プライバシーポリシー ✅
#    - メタデータ (説明・キーワード) ✅
#    - 権限確認 (RECORD_AUDIO等) ✅

# 5. リリース作成 → 本番環境にロールアウト
#    段階的ロールアウト: 10% → 50% → 100%
```

### 7.2 App Store Connect 提出 (iOS)

```bash
# 1. App Store Connect にログイン
# https://appstoreconnect.apple.com

# 2. MeasureTracker を選択

# 3. ビルド → app-release.ipa をアップロード
#    (Xcode Organizer または Application Loader)

# 4. メタデータ確認:
#    - App Description ✅
#    - Keywords ✅
#    - Screenshot ✅
#    - Privacy Policy URL ✅

# 5. 審査に提出
```

---

## 🐛 トラブルシューティング

### エラー: "flutter: command not found"
```bash
# Flutter パスを PATH に追加
export PATH="$PATH:/path/to/flutter/bin"
```

### エラー: "android/app/google-services.json not found"
```bash
# Firebase Console から google-services.json をダウンロード
# android/app/ に配置
```

### エラー: "Pod install failed"
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
```

### ビルドサイズが大きすぎる
```bash
# 不要なパッケージを削除
flutter pub remove [package_name]

# または flutter_native_splash などの条件付き include を確認
```

---

## 📊 ビルド情報

| 項目 | 値 |
|-----|---|
| **App Name** | MeasureTracker |
| **Package Name (Android)** | com.yourwish.measuretrackers |
| **Bundle ID (iOS)** | com.yourwish.measuretrackers |
| **Version** | 1.0.0 |
| **Build Number** | 1 |
| **Min SDK (Android)** | API 24 (Android 7.0) |
| **Min iOS** | iOS 13.0 |

---

## 📝 リリースチェックリスト

- [ ] Firebase 設定ファイル配置
- [ ] flutter pub get 実行
- [ ] flutter pub run build_runner build 実行
- [ ] flutter pub run flutter_launcher_icons 実行
- [ ] APK デバッグビルド成功
- [ ] APK リリースビルド成功 (< 80MB)
- [ ] AAB リリースビルド成功 (< 60MB)
- [ ] iOS ビルド成功 (macOS環境)
- [ ] 実機テスト完了
- [ ] Google Play Console アップロード
- [ ] App Store Connect アップロード
- [ ] メタデータ最終確認
- [ ] 審査申請

---

**ビルド完了後、App Store/Play Store 審査に進めます。** 🚀
