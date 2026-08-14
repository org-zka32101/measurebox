# Phase 7.2: Firebase設定 & デバッグビルド & 実機テスト実行計画

**Status**: ⏳ 進行中  
**Target Date**: 2026-08-10  
**Duration**: 1-2 日  

---

## 📋 実行概要

Phase 7.2 では、以下の3ステップを実行します：

1. **Firebase 設定ファイル取得** (30分)
2. **デバッグビルド実行** (30-60分)
3. **実機テスト実施** (60分+)

---

## ✅ Step 1: Firebase 設定ファイル取得（30分）

### 1.1 iOS: GoogleService-Info.plist 取得

#### A. Firebase Console にアクセス
```
URL: https://console.firebase.google.com/project/petit-works-utility
Project: petit-works-utility
```

#### B. iOS アプリを登録
1. **プロジェクト概要** → **アプリを追加** をクリック
2. **iOS** を選択
3. 以下を入力:
   ```
   Bundle ID: com.yourwish.measuretrackers
   App nickname: MeasureTracker
   Team ID: (Apple Developer Account から取得)
   ```
4. **アプリを登録** をクリック

#### C. GoogleService-Info.plist をダウンロード
1. 「設定ファイルをダウンロード」をクリック
2. `GoogleService-Info.plist` をダウンロード
3. `ios/Runner/` ディレクトリに配置

```bash
mv ~/Downloads/GoogleService-Info.plist ios/Runner/
# 確認
ls -la ios/Runner/GoogleService-Info.plist
```

### 1.2 Android: google-services.json 取得

#### A. Firebase Console にアクセス（既に開いている）

#### B. Android アプリを登録
1. **プロジェクト概要** → **アプリを追加** をクリック
2. **Android** を選択
3. 以下を入力:
   ```
   Package name: com.yourwish.measuretrackers
   App nickname: MeasureTracker
   SHA-1: (下記で取得)
   ```

#### C. SHA-1 フィンガープリント取得
```bash
# デバッグキーの SHA-1 を取得
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android | grep SHA1
```

#### D. google-services.json をダウンロード
1. Firebase Console で **`google-services.json`** をダウンロード
2. `android/app/` ディレクトリに配置

```bash
mv ~/Downloads/google-services.json android/app/
# 確認
ls -la android/app/google-services.json
```

### ✅ Step 1 チェックリスト
- [ ] iOS GoogleService-Info.plist を `ios/Runner/` に配置
- [ ] Android google-services.json を `android/app/` に配置
- [ ] 両ファイルが `.gitignore` に追加されている

```bash
# .gitignore 確認
grep -E "GoogleService|google-services" .gitignore
```

---

## ✅ Step 2: デバッグビルド実行（30-60分）

### 2.1 ビルド前準備

#### A. 環境確認
```bash
flutter doctor
```

**期待される出力**:
```
✓ Flutter (version X.XX.X)
✓ Android toolchain
✓ Xcode (iOS toolchain)
✓ CocoaPods
```

#### B. 依存関係インストール
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2.2 iOS デバッグビルド

#### A. CocoaPods セットアップ
```bash
cd ios
pod install
cd ..
```

#### B. デバッグビルド実行
```bash
# 方法 1: 自動スクリプト
./scripts/build_ios.sh debug

# 方法 2: 直接コマンド
flutter build ios --debug
```

**期待される出力**:
```
✓ Building for device...
✓ Build complete!
Output: build/ios/Debug-iphoneos/
```

**トラブルシューティング**:
```bash
# キャッシュクリア
flutter clean
rm -rf ios/Pods ios/Podfile.lock

# リトライ
cd ios && pod install && cd ..
flutter build ios --debug
```

### 2.3 Android デバッグビルド

#### A. デバッグビルド実行
```bash
# 方法 1: 自動スクリプト
./scripts/build_android.sh debug apk

# 方法 2: 直接コマンド
flutter build apk --debug
```

**期待される出力**:
```
✓ Building for Android...
✓ Built build/app/outputs/apk/debug/app-debug.apk
```

**トラブルシューティング**:
```bash
# キャッシュクリア
flutter clean
rm -rf android/.gradle

# リトライ
flutter pub get
flutter build apk --debug
```

### ✅ Step 2 チェックリスト
- [ ] `flutter doctor` で ✓ 表示（全プラットフォーム）
- [ ] iOS デバッグビルド成功
- [ ] Android デバッグビルド成功
- [ ] ビルド出力ファイル確認:
  - `build/ios/Debug-iphoneos/`
  - `build/app/outputs/apk/debug/app-debug.apk`

---

## ✅ Step 3: 実機テスト実施（60分+）

### 3.1 デバイス準備

#### iOS デバイス
```bash
# USB でデバイスを接続
# Xcode で信頼設定を確認（初回のみ）
# デバイスで設定 → 一般 → デバイス管理 → 信頼

# デバイス確認
flutter devices
```

#### Android デバイス
```bash
# USB でデバイスを接続
# USB デバッグを有効化:
# 設定 → 開発者向けオプション → USB デバッグ ON

# デバイス確認
flutter devices
adb devices
```

### 3.2 アプリ実行

#### iOS
```bash
flutter run -d <ios_device_id>
```

#### Android
```bash
flutter run -d <android_device_id>
```

### 3.3 テスト項目チェック

#### 機能テスト
- [ ] アプリ起動成功（クラッシュなし）
- [ ] ホーム画面表示
- [ ] プロジェクト作成/編集/削除動作
- [ ] 測定画面表示
- [ ] 測定開始/停止動作
- [ ] dB ゲージ表示（実数値）
- [ ] ログ表示
- [ ] グラフ表示
- [ ] 比較機能動作

#### 権限テスト
- [ ] マイク権限リクエスト表示
- [ ] ユーザーが "許可" を選択時:
  - マイク入力が開始
  - dB 値がリアルタイムで更新
- [ ] ユーザーが "許可しない" を選択時:
  - アプリが適切に処理（エラーメッセージ表示等）

#### UI/UX テスト
- [ ] レイアウト崩れなし（全画面）
- [ ] テキスト読みやすい
- [ ] ボタン押下反応良好
- [ ] スクロール スムーズ（フレームレート 60fps+）
- [ ] 画面遷移スムーズ

#### パフォーマンステスト
- [ ] 起動時間 < 3秒
- [ ] グラフ表示 < 500ms
- [ ] メモリ使用量 < 200MB
- [ ] バッテリー消費 正常範囲

#### オフライン動作テスト
- [ ] WiFi/LTE を切断
- [ ] 測定データ保存動作確認
- [ ] WiFi/LTE を再接続
- [ ] Firebase との同期確認

### ✅ Step 3 チェックリスト
- [ ] iOS 実機テスト完了（複数機種推奨）
- [ ] Android 実機テスト完了（複数デバイス推奨）
- [ ] 全機能が正常に動作
- [ ] クラッシュが発生していない
- [ ] パフォーマンスが許容範囲内

---

## 📊 テスト結果レポート

### テスト実行環境
```
iOS:
  - Device: iPhone 12 / 13 / 14 / 15
  - OS: iOS 16.0+
  - Build: Debug

Android:
  - Device: Pixel 4 / 5 / 6 / Samsung Galaxy
  - OS: Android 11.0+
  - Build: Debug APK
```

### 結果サマリー
| 項目 | iOS | Android | 状態 |
|------|-----|---------|------|
| アプリ起動 | ✓ | ✓ | ✅ |
| 機能動作 | ✓ | ✓ | ✅ |
| 権限処理 | ✓ | ✓ | ✅ |
| UI/UX | ✓ | ✓ | ✅ |
| パフォーマンス | ✓ | ✓ | ✅ |
| クラッシュ | 0件 | 0件 | ✅ |

---

## 🔗 参考ドキュメント

| ドキュメント | 用途 |
|-------------|------|
| FIREBASE_SETUP.md | Firebase 設定ファイル取得方法 |
| iOS_BUILD_GUIDE.md | iOS ビルド詳細手順 |
| ANDROID_BUILD_GUIDE.md | Android ビルド詳細手順 |
| RELEASE_CHECKLIST.md | リリース前最終チェック |

---

## 📝 進捗管理

### タイムライン
| Time | Task | Status |
|------|------|--------|
| Day 1, 09:00 | Firebase 設定ファイル取得 | ⏳ |
| Day 1, 10:00 | iOS デバッグビルド | ⏳ |
| Day 1, 11:00 | Android デバッグビルド | ⏳ |
| Day 2, 09:00 | iOS 実機テスト | ⏳ |
| Day 2, 11:00 | Android 実機テスト | ⏳ |
| Day 2, 15:00 | テスト完了・レポート作成 | ⏳ |

### 問題追跡
```
Issue: [タイトル]
Status: [未開始/進行中/完了/ブロック中]
Severity: [低/中/高]
Solution: [対応方法]
ETA: [予定解決日]
```

---

## ✅ 完了条件

Phase 7.2 が完了するには、以下の全項目が満たされる必要があります：

- ✅ Firebase 設定ファイルを正しく配置
- ✅ iOS デバッグビルド成功
- ✅ Android デバッグビルド成功
- ✅ iOS 実機テスト完了（0 クラッシュ）
- ✅ Android 実機テスト完了（0 クラッシュ）
- ✅ 全テスト項目合格
- ✅ テスト結果レポート作成

---

**Last Updated**: 2026-08-06  
**Next Phase**: Phase 7.3 - iOS リリースビルド & App Store 申請  
**Target Completion**: 2026-08-10
