# iOS ビルド & リリース準備ガイド - Phase 7

## 🤖 GitHub Actions での自動ビルド（CI検証）

`main` への push / PR の度に、GitHub 提供の macOS ランナー上で **未署名の iOS ビルド** を
自動実行するワークフローを追加しました: `.github/workflows/ios-build.yml`

**実施内容**: `flutter pub get` → `flutter analyze` → `flutter test` →
`flutter build ios --release --no-codesign`。成功すると `Runner.app`（未署名）を
Actions の Artifacts からダウンロードできます。

### できること / できないこと

| 項目 | 対応 |
|------|------|
| コンパイルが通るかの継続的検証 | ✅ 自動 |
| 実機/シミュレータへのインストール検証 | ❌（未署名のため） |
| App Store への提出物（署名済みIPA） | ❌（Apple Developer証明書が必要、別途設定要） |

### Firebase 設定（CI用）
`lib/firebase_options.dart` と `ios/Runner/GoogleService-Info.plist` は
`.gitignore` 対象のため、CI では既定でリポジトリ内の `*.example` プレースホルダを
使用します（＝この状態でビルドされたアプリは Firebase に接続できません）。

実際の Firebase プロジェクトに接続した状態でCIビルドしたい場合は、リポジトリの
**Settings → Secrets and variables → Actions** に以下を追加してください:

```bash
# ローカルで実ファイルをbase64化してSecretsに貼り付け
base64 -i lib/firebase_options.dart | pbcopy
# → FIREBASE_OPTIONS_DART_BASE64 として登録

base64 -i ios/Runner/GoogleService-Info.plist | pbcopy
# → GOOGLE_SERVICE_INFO_PLIST_BASE64 として登録
```

### 署名済みIPA（App Store提出用）✅ 実装済み
`.github/workflows/ios-release.yml` で、署名済みIPAの生成とTestFlightへの
自動アップロードに対応しています。Apple Developer証明書等のSecrets設定方法は
**iOS_RELEASE_SIGNING_SETUP.md** を参照してください。

---

## 📋 iOS ビルド前チェックリスト（手動ビルド）

### 1. 環境準備
- [ ] Xcode 15.0 以上がインストールされている
- [ ] Xcode Command Line Tools が正しく設定されている
  ```bash
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
  xcode-select --print-path
  ```
- [ ] CocoaPods がインストールされている
  ```bash
  sudo gem install cocoapods
  pod repo update
  ```

### 2. Firebase iOS 設定

**重要**: Google Play/App Store 申請前に必須

#### 2.1 GoogleService-Info.plist ダウンロード
1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. プロジェクト: `petit-works-utility` を選択
3. iOS アプリ登録:
   - Bundle ID: `com.yourwish.measuretrackers`
   - App Store ID: (後で設定)
   - Team ID: (Apple Developer Account から取得)
4. GoogleService-Info.plist をダウンロード
5. `ios/Runner/` に配置

#### 2.2 Xcode プロジェクトに plist を追加
```bash
# ios/ ディレクトリで実行
open Runner.xcworkspace
```
- Xcode で `Runner` プロジェクトを開く
- `GoogleService-Info.plist` を `Runner` ターゲットにドラッグ&ドロップ
- "Copy items if needed" をチェック
- ターゲット `Runner` を選択

### 3. Podfile 依存関係の確認

```bash
cd ios
pod install
cd ..
```

### 4. Info.plist 権限確認

✅ 既に設定済み:
- `NSMicrophoneUsageDescription` - マイクアクセス
- `NSUserTrackingUsageDescription` - App Tracking Transparency

### 5. ビルド設定確認

#### 5.1 最小 iOS バージョン
```bash
# Xcode で Runner プロジェクト → Build Settings
# Minimum Deployment Target: iOS 13.0 以上（Runner.xcodeproj & ios/Podfile と一致させる）
```

#### 5.2 署名設定（実機テスト用）
```bash
# Xcode で Runner → Signing & Capabilities
# 1. Team を選択
# 2. Bundle Identifier 確認: com.yourwish.measuretrackers
# 3. Signing Certificate: "Automatic" 推奨
```

---

## 🔨 iOS ビルドコマンド

### デバッグビルド（実機テスト用）
```bash
flutter clean
flutter pub get
flutter build ios --debug
```

**出力**: `build/ios/Debug-iphoneos/`

### リリースビルド（App Store 申請用）
```bash
flutter clean
flutter pub get
flutter build ios --release
```

**出力**: `build/ios/Release-iphoneos/`

### Archive ビルド（App Store 提出用）
```bash
flutter build ios --release
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  archive
cd ..
```

---

## 📱 実機テスト手順（iOS デバイス）

### 1. デバイスの接続
```bash
# 接続済みデバイスを確認
flutter devices

# デバイスが表示されない場合
xcrun xdevice discover -v
```

### 2. アプリをデバイスに展開
```bash
# 特定デバイスでビルド & 実行
flutter run -d <device_id>

# またはデバッガ付き
flutter run -d <device_id> --debug

# リリースモード
flutter run -d <device_id> --release
```

### 3. テスト項目チェック

- [ ] **認証機能**
  - ゲストモードで起動確認
  - メール/パスワード認証（Firebase接続後）
  
- [ ] **プロジェクト管理**
  - プロジェクト作成・編集・削除
  - UI レスポンシブネス確認
  
- [ ] **測定機能** ⭐
  - マイク権限リクエスト表示
  - 音量測定開始・停止
  - dB 値表示
  - 統計グラフ表示
  
- [ ] **ローカル保存** (Hive)
  - オフライン状態でデータ保存確認
  - Firebase 再接続時の同期
  
- [ ] **UI/UX**
  - レイアウト崩れなし（各 iPhone サイズ）
  - 画面遷移スムーズ
  - ジェスチャー反応良好
  
- [ ] **パフォーマンス**
  - 起動時間 < 3秒
  - スクロール FPS 安定 (60fps)
  - メモリ使用量 < 200MB

---

## 🚀 App Store 申請準備

### 1. App Store Connect 登録
1. [App Store Connect](https://appstoreconnect.apple.com/) にアクセス
2. "My Apps" → "+" → "New App"
3. 以下を入力:
   - Platform: iOS
   - Name: `MeasureTracker`
   - Primary Language: Japanese
   - Bundle ID: `com.yourwish.measuretrackers`
   - SKU: 任意 (例: `measuretracker-001`)

### 2. メタデータ設定

#### 2.1 アプリ情報
- **アプリ名**: MeasureTracker
- **サブタイトル**: 正確な音量計測アプリ
- **プライマリカテゴリ**: ユーティリティ
- **セカンダリカテゴリ**: 仕事効率化

#### 2.2 説明文（日本語）
```
MeasureTracker は、正確な音量測定が必要な専門家・研究者向けの iOS アプリです。

【機能】
✓ リアルタイム dB 測定
✓ 測定履歴管理
✓ Before/After 比較分析
✓ CSV エクスポート
✓ マイク校正機能

【対応デバイス】
iPhone 12 以上推奨
```

#### 2.3 スクリーンショット（5枚）
1. ホーム画面
2. 測定画面
3. グラフ表示
4. 比較画面
5. ログ画面

**仕様**: 
- 解像度: 1242 x 2208px (iPhone 14)
- フォーマット: PNG または JPG
- 日本語テキスト推奨

#### 2.4 プライバシーポリシー
```
https://petit-works-apps.com/privacy-ja
```

#### 2.5 サポート URL
```
https://petit-works-apps.com/support
```

### 3. 版の情報（Builds）
- Version: 1.0.0
- Build: 1
- リリースノート:
  ```
  初回リリース

  - リアルタイム音量測定
  - Firebase クラウド同期
  - Before/After 比較機能
  - CSV エクスポート
  ```

### 4. リリース方式
- **自動リリース**: "Automatically release this version once it's approved"
- または **手動**: 承認後に "Release this version" ボタンで公開

---

## 📊 iOS App Store 審査重点項目

### ✅ 必ず確認

1. **プライバシー**
   - [ ] マイク権限の説明が明確
   - [ ] データ処理方針を明記
   - [ ] 利用規約・プライバシーポリシーを公開

2. **機能動作**
   - [ ] クラッシュなし
   - [ ] エラーハンドリング完備
   - [ ] オフライン対応

3. **UI/UX**
   - [ ] Apple Human Interface Guidelines 準拠
   - [ ] Safe Area 対応
   - [ ] ダークモード対応（推奨）

4. **セキュリティ**
   - [ ] HTTPS のみ使用
   - [ ] Firebase Rules が本番化
   - [ ] 認証トークン安全管理

---

## 🔄 トラブルシューティング

### CocoaPods エラー
```bash
# キャッシュをクリア
rm -rf ios/Pods ios/Podfile.lock
cd ios && pod install && cd ..
```

### Xcode ビルドエラー
```bash
# DerivedData をクリア
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Flutter キャッシュもクリア
flutter clean
flutter pub get
```

### Provisioning Profile エラー
```bash
# キーチェーンから削除
security delete-identity -c "iPhone Developer" ~/Library/Keychains/login.keychain

# Xcode で再作成
open ios/Runner.xcworkspace
# Runner → Signing & Capabilities → Restore Defaults
```

---

## 📝 Version 管理

### pubspec.yaml の version 更新
```yaml
version: 1.0.0+1  # build-name+build-number
```

**マッピング**:
- `1.0.0` = App Store バージョン
- `+1` = iOS CFBundleVersion（整数、毎回インクリメント）

### 次バージョン例
```yaml
version: 1.0.1+2  # 小バグ修正
version: 1.1.0+3  # 機能追加
version: 2.0.0+4  # メジャー更新
```

---

## ✅ 最終チェックリスト（App Store 申請前）

- [ ] Firebase GoogleService-Info.plist 設定済み
- [ ] マイク権限 Info.plist に記載
- [ ] iOS 最小バージョン確認（13.0+）
- [ ] 実機テスト合格（複数デバイス）
- [ ] クラッシュレート 0%
- [ ] プライバシーポリシー公開済み
- [ ] スクリーンショット準備完了
- [ ] メタデータ（説明・キーワード）完成
- [ ] Support URL 準備完了
- [ ] Version 番号を確認
- [ ] Build Archive 成功確認

---

## 📌 次のステップ（Phase 7.1+）

1. **Google Play リリース** (Android)
   - Google Play Console 設定
   - APK/AAB ビルド & 署名
   - 実機テスト & 審査

2. **継続開発** (v1.1+)
   - [ ] ダークモード完全対応
   - [ ] 多言語対応（英語・中国語）
   - [ ] クラウド同期改善
   - [ ] PDF エクスポート機能

---

**Last Updated**: 2026-08-06  
**Status**: Phase 7 準備中  
**iOS Minimum**: 13.0+  
**Target Bundle ID**: com.yourwish.measuretrackers
