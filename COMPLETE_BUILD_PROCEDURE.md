# 📚 MeasureTracker v1.0.0 完全ビルド・リリース手順書

**適用対象**: iOS・Android 両プラットフォーム  
**所要時間**: 3-5 日  
**最終目標**: App Store・Google Play への公開

---

## 📋 全体進捗マップ

```
┌─────────────────────────────────────────────────────────┐
│ Phase 7: リリース前最終確認                              │
├─────────────────────────────────────────────────────────┤
│ Phase 7.1 ✅ iOS・Android ビルド環境準備 (2026-08-06)   │
│  └─ iOS設定（Podfile、Info.plist権限）                  │
│  └─ Android設定（AndroidManifest権限）                  │
│  └─ ビルドスクリプト作成                                 │
│  └─ ドキュメント作成                                     │
├─────────────────────────────────────────────────────────┤
│ Phase 7.2 ⏳ Firebase設定・デバッグビルド・実機テスト    │
│  └─ Firebase設定ファイル取得 (Day 1)                     │
│  └─ iOS デバッグビルド実行 (Day 1)                       │
│  └─ Android デバッグビルド実行 (Day 1)                   │
│  └─ 実機テスト (Day 2-3)                                 │
│  └─ テスト結果レポート作成 (Day 3)                       │
├─────────────────────────────────────────────────────────┤
│ Phase 7.3 📋 iOS リリースビルド・App Store 申請         │
│  └─ iOS リリースビルド実行 (Day 4)                       │
│  └─ App Store Connect メタデータ入力 (Day 4-5)           │
│  └─ App Store に申請 (Day 5)                             │
├─────────────────────────────────────────────────────────┤
│ Phase 7.4 📋 Android リリースビルド・Google Play 申請   │
│  └─ Android リリースビルド実行 (Day 4)                   │
│  └─ Google Play Console メタデータ入力 (Day 4-5)         │
│  └─ Google Play に申請 (Day 5)                           │
├─────────────────────────────────────────────────────────┤
│ Phase 7.5 📋 リリース公開・監視                          │
│  └─ iOS App Store 公開 (2026-08-27)                     │
│  └─ Android Google Play 公開 (2026-08-29)               │
│  └─ Analytics & Crashlytics 監視開始                     │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 Day 1: Firebase 設定 & デバッグビルド

### Morning (09:00-12:00) - Firebase 設定ファイル取得

#### Task 1.1: Firebase Console へのアクセス

```bash
# ブラウザで Firebase Console を開く
https://console.firebase.google.com/project/petit-works-utility
```

**確認事項**:
- ✓ Google アカウントでログイン
- ✓ プロジェクト: petit-works-utility を選択

#### Task 1.2: iOS - GoogleService-Info.plist 取得

```bash
# Firebase Console 内の操作
1. プロジェクト概要 → アプリを追加
2. iOS を選択
3. 以下を入力:
   - Bundle ID: com.petitworksapps.measuretracker
   - App nickname: MeasureTracker
   - Team ID: (Apple Developer Account から取得)
4. ダウンロードボタン → GoogleService-Info.plist

# ローカル操作
mv ~/Downloads/GoogleService-Info.plist ios/Runner/

# 確認
ls -la ios/Runner/GoogleService-Info.plist
```

**所要時間**: 10-15 分

#### Task 1.3: Android - google-services.json 取得

```bash
# Firebase Console 内の操作
1. プロジェクト概要 → アプリを追加
2. Android を選択
3. 以下を入力:
   - Package name: com.petitworksapps.measuretracker
   - App nickname: MeasureTracker
   - SHA-1: (下記のコマンド出力から取得)

# SHA-1 フィンガープリント取得
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android | grep SHA1
# 出力例: SHA1: AB:CD:EF:... (これを Firebase に入力)

# Firebase Console で google-services.json をダウンロード
mv ~/Downloads/google-services.json android/app/

# 確認
ls -la android/app/google-services.json
```

**所要時間**: 15-20 分

### Afternoon (13:00-17:00) - デバッグビルド実行

#### Task 1.4: 環境チェック

```bash
flutter doctor -v
```

**期待される出力**:
```
✓ Flutter (version 3.XX.X)
✓ Android toolchain
✓ Xcode
✓ CocoaPods
✓ Chrome
```

**ブロッカー**: 環境が OK でない場合は、ここで対応が必要

**所要時間**: 5 分

#### Task 1.5: 依存関係インストール

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**所要時間**: 3-5 分

#### Task 1.6: iOS デバッグビルド

```bash
# CocoaPods セットアップ（初回のみ）
cd ios
pod install
cd ..

# ビルド実行
./scripts/build_ios.sh debug
# または
flutter build ios --debug
```

**期待される出力**:
```
✓ Built build/ios/Debug-iphoneos/
```

**所要時間**: 30-40 分（初回）

**トラブル対応**:
```bash
# CocoaPods エラーの場合
rm -rf ios/Pods ios/Podfile.lock
cd ios && pod repo update && pod install && cd ..
flutter build ios --debug
```

#### Task 1.7: Android デバッグビルド

```bash
./scripts/build_android.sh debug apk
# または
flutter build apk --debug
```

**期待される出力**:
```
✓ Built build/app/outputs/apk/debug/app-debug.apk
```

**所要時間**: 20-30 分（初回）

**トラブル対応**:
```bash
flutter clean
rm -rf android/.gradle
flutter pub get
flutter build apk --debug
```

---

## 🧪 Day 2-3: 実機テスト

### Morning (09:00-12:00) - iOS 実機テスト

#### Task 2.1: デバイス準備

```bash
# USB でデバイスを接続
# Xcode で信頼設定を確認（初回のみ）

# デバイス確認
flutter devices
```

**期待される出力**:
```
iPhone 12 (mobile)    • 0123456789ABCDEF • ios     • iOS 16.X.X
```

#### Task 2.2: アプリ実行

```bash
flutter run -d <device_id>
# 例: flutter run -d "iPhone 12"
```

**期待される出力**:
```
✓ Launching lib/main.dart on <device> in debug mode...
✓ App successfully started
```

#### Task 2.3: テスト実行

以下の項目をすべてチェック:

**起動テスト**
- [ ] アプリが起動する
- [ ] クラッシュが発生しない
- [ ] ホーム画面が表示される

**権限テスト**
- [ ] マイク権限ダイアログが表示される
- [ ] "許可"を選択すると測定可能
- [ ] "許可しない"を選択するとエラー処理が適切

**機能テスト**
- [ ] プロジェクト作成できる
- [ ] プロジェクト編集できる
- [ ] プロジェクト削除できる（確認ダイアログ表示）
- [ ] 測定画面に遷移できる
- [ ] 測定開始・停止ができる
- [ ] dB 値が表示される
- [ ] ログが保存される

**UI/UX テスト**
- [ ] レイアウト崩れがない
- [ ] テキストが読みやすい
- [ ] ボタン反応が良好
- [ ] スクロールがスムーズ

**所要時間**: 45-60 分

### Afternoon (13:00-17:00) - Android 実機テスト

#### Task 2.4: デバイス準備

```bash
# USB でデバイスを接続
# USB デバッグを有効化:
# 設定 → 開発者向けオプション → USB デバッグ ON

# デバイス確認
flutter devices
adb devices
```

#### Task 2.5: アプリ実行

```bash
flutter run -d <device_id>
# 例: flutter run -d "ZTE1234567890"
```

#### Task 2.6: テスト実行

iOS と同じテスト項目を実行

**所要時間**: 45-60 分

### Day 3: テスト結果報告

#### Task 2.7: テスト結果レポート作成

以下の内容でテスト結果レポートを作成:

```markdown
# MeasureTracker デバッグビルド & 実機テスト結果報告書

## テスト環境
- iOS: iPhone 12, 13, 14 (iOS 16.0+)
- Android: Pixel 5, 6 (Android 11+)

## テスト実行日
2026-08-08～2026-08-09

## 結果サマリー
| 項目 | iOS | Android | 判定 |
|------|-----|---------|------|
| 起動テスト | ✓ | ✓ | ✅ |
| 権限テスト | ✓ | ✓ | ✅ |
| 機能テスト | ✓ | ✓ | ✅ |
| UI/UX テスト | ✓ | ✓ | ✅ |
| クラッシュ | 0件 | 0件 | ✅ |

## 詳細結果
[各項目の詳細結果を記載]

## 問題報告
[発見された問題があれば記載]

## 承認者
Date: 2026-08-09
Tester: [テスト実施者名]
```

**所要時間**: 30 分

---

## 🚀 Day 4-5: リリースビルド & App Store・Google Play 申請

### Day 4 Morning: iOS リリースビルド

#### Task 3.1: iOS リリースビルド実行

```bash
./scripts/build_ios.sh release
# または
flutter build ios --release
```

**期待される出力**:
```
✓ Built build/ios/Release-iphoneos/
```

**所要時間**: 40-50 分

#### Task 3.2: Archive 生成

```bash
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  archive
cd ..
```

**所要時間**: 10-15 分

### Day 4 Afternoon: App Store Connect 登録

#### Task 3.3: App Store Connect にアプリ登録

```
URL: https://appstoreconnect.apple.com/
```

**手順**:
1. "My Apps" → "+" → "New App"
2. 以下を入力:
   - Platform: iOS
   - Name: MeasureTracker
   - Primary Language: Japanese
   - Bundle ID: com.petitworksapps.measuretracker
   - SKU: measuretracker-001

**所要時間**: 10 分

#### Task 3.4: メタデータ設定

**アプリ情報**:
- Name: MeasureTracker
- Subtitle: 正確な音量計測アプリ
- Description: [iOS_BUILD_GUIDE.md 参照]
- Category: ユーティリティ

**スクリーンショット** (5-8枚):
- ホーム画面
- 測定画面
- グラフ表示
- 比較画面
- ログ画面

**所要時間**: 60-90 分

#### Task 3.5: プライバシー & ポリシー設定

```
プライバシーポリシー: https://petit-works-apps.com/privacy-ja
Support URL: https://petit-works-apps.com/support
EULA: https://petit-works-apps.com/terms
```

**所要時間**: 15 分

### Day 4 Evening: Android リリースビルド

#### Task 3.6: Android リリースビルド実行

```bash
# リリース Keystore 生成（初回のみ）
keytool -genkey -v -keystore ~/measuretracker-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias measuretracker

# ビルド実行
./scripts/build_android.sh release aab
# または
flutter build appbundle --release
```

**期待される出力**:
```
✓ Built build/app/outputs/bundle/release/app-release.aab
```

**所要時間**: 30-40 分

### Day 5: Google Play 申請

#### Task 3.7: Google Play Console 登録

```
URL: https://play.google.com/console/
```

**手順**:
1. 新規アプリを作成
2. 以下を入力:
   - Name: MeasureTracker
   - Default Language: 日本語
   - Category: ツール
   - Package Name: com.petitworksapps.measuretracker

**所要時間**: 10 分

#### Task 3.8: メタデータ設定

**アプリ情報**:
- Name: MeasureTracker
- Short description: 正確な音量計測アプリ
- Full description: [ANDROID_BUILD_GUIDE.md 参照]
- Category: ツール

**スクリーンショット** (5-8枚, 1440x2560px):
- [iOS と同じ内容で調整]

**所要時間**: 60-90 分

#### Task 3.9: コンテンツレーティング & プライバシー設定

```
プライバシーポリシー: https://petit-works-apps.com/privacy-ja
Support URL: https://petit-works-apps.com/support
```

**所要時間**: 15 分

#### Task 3.10: ビルド版のアップロード

```
Production → Upload → app-release.aab を選択
```

**所要時間**: 5-10 分

---

## ✅ チェックリスト by Day

### Day 1 完了チェック
- [ ] Firebase GoogleService-Info.plist を ios/Runner/ に配置
- [ ] Firebase google-services.json を android/app/ に配置
- [ ] iOS デバッグビルド成功
- [ ] Android デバッグビルド成功

### Day 2-3 完了チェック
- [ ] iOS 実機テスト完了（複数デバイス）
- [ ] Android 実機テスト完了（複数デバイス）
- [ ] テスト結果レポート作成
- [ ] クラッシュ 0件
- [ ] 全機能が正常に動作

### Day 4-5 完了チェック
- [ ] iOS リリースビルド成功
- [ ] Android リリースビルド成功
- [ ] App Store Connect にメタデータ入力完了
- [ ] Google Play Console にメタデータ入力完了
- [ ] App Store に申請完了
- [ ] Google Play に申請完了

---

## 📊 タイムシート

| Day | 時間 | タスク | 予定 |
|-----|------|--------|------|
| Day 1 | 09:00-12:00 | Firebase設定 | 45分 |
| | 13:00-17:00 | デバッグビルド | 120分 |
| Day 2 | 09:00-12:00 | iOS 実機テスト | 60分 |
| | 13:00-17:00 | Android 実機テスト | 60分 |
| Day 3 | 09:00-12:00 | テスト結果レポート | 90分 |
| Day 4 | 09:00-12:00 | iOS リリースビルド | 50分 |
| | 13:00-17:00 | App Store メタデータ | 90分 |
| | 17:00-18:00 | Android リリースビルド | 40分 |
| Day 5 | 09:00-12:00 | Google Play メタデータ | 90分 |
| | 12:00-13:00 | App Store 申請 | 15分 |
| | 13:00-14:00 | Google Play 申請 | 15分 |

**Total**: 10.5 営業時間 (3-4 日)

---

## 🔗 参考ドキュメント

| ドキュメント | 用途 |
|-------------|------|
| QUICK_START_BUILD.md | 最短実行手順 |
| PHASE_7_2_EXECUTION_PLAN.md | 詳細実行計画 |
| FIREBASE_SETUP.md | Firebase設定 |
| iOS_BUILD_GUIDE.md | iOS ビルド詳細 |
| ANDROID_BUILD_GUIDE.md | Android ビルド詳細 |
| RELEASE_CHECKLIST.md | リリース最終確認 |

---

## ⚠️ 重要な注意

### Firebase 設定ファイル
- `.gitignore` に `GoogleService-Info.plist` と `google-services.json` が含まれていることを確認
- GitHub に誤ってコミットしないこと

### リリースキー
- Keystore ファイル（.jks）を安全に保管
- パスワードを記録（後で必要）

### メタデータ
- スクリーンショットは高品質（1440x2560px 以上）
- 説明文は正確で分かりやすく

### 審査期間
- App Store: 平均 1-2 日（最大 30 日）
- Google Play: 平均 2-4 時間（最大 7 日）

---

**Last Updated**: 2026-08-06  
**Total Duration**: 3-5 日  
**Status**: Phase 7.1-7.2 準備完成、Phase 7.3+ 待機中
