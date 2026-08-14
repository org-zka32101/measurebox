# Android ビルド & リリース準備ガイド - Phase 7

## 🤖 GitHub Actions での自動ビルド（CI検証）

`main` への push / PR の度に、GitHub 提供の Ubuntu ランナー上で **デバッグ署名の
release APK** を自動ビルドするワークフローを追加しました: `.github/workflows/android-build.yml`

**実施内容**: `flutter pub get` → Firebase設定配置 → `flutter analyze` →
`flutter test` → `flutter build apk --release`。成功するとAPKを
Actions の Artifacts からダウンロードできます。

### できること / できないこと

| 項目 | 対応 |
|------|------|
| コンパイルが通るかの継続的検証 | ✅ 自動 |
| Google Play への提出物（署名済みAAB） | ❌（`android-release.yml` を使用、後述） |

### Firebase 設定（CI用）
`lib/firebase_options.dart` と `android/app/google-services.json` は
`.gitignore` 対象のため、CI では既定でリポジトリ内の `*.example` プレースホルダを
使用します（＝この状態でビルドされたアプリは Firebase に接続できません）。

実際の Firebase プロジェクトに接続した状態でCIビルドしたい場合は、リポジトリの
**Settings → Secrets and variables → Actions** に以下を追加してください:

```bash
base64 -w0 lib/firebase_options.dart
# → FIREBASE_OPTIONS_DART_BASE64 として登録

base64 -w0 android/app/google-services.json
# → GOOGLE_SERVICES_JSON_BASE64 として登録
```

### 署名済みAAB（Google Play提出用）✅ 実装済み
`.github/workflows/android-release.yml` で、署名済みAABの生成とGoogle Playへの
自動アップロードに対応しています。Keystore等のSecrets設定方法は
**ANDROID_RELEASE_SIGNING_SETUP.md** を参照してください。

---

## 📋 Android ビルド前チェックリスト（手動ビルド）

### 1. 環境準備
- [ ] Android Studio 2024.1+ がインストールされている
- [ ] Android SDK 33+ がインストールされている
- [ ] Java JDK 11+ がインストールされている
- [ ] Flutter が正しく設定されている
  ```bash
  flutter doctor
  ```

### 2. Firebase Android 設定

**重要**: Google Play Store 申請前に必須

#### 2.1 google-services.json ダウンロード
1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. プロジェクト: `petit-works-utility` を選択
3. Android アプリ登録:
   - Package Name: `com.yourwish.measuretrackers`
   - SHA-1: (後述)
4. google-services.json をダウンロード
5. `android/app/` に配置

#### 2.2 SHA-1 フィンガープリント取得
```bash
# デバッグキー
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# リリースキー（後で生成）
keytool -list -v -keystore path/to/keystore.jks -alias your_alias
```

### 3. Gradle 設定確認

#### 3.1 build.gradle チェック
```bash
cat android/app/build.gradle
```

以下を確認:
- minSdkVersion: 21 以上
- compileSdkVersion: 34 以上
- targetSdkVersion: 34 以上

#### 3.2 AndroidManifest.xml 権限確認
```bash
cat android/app/src/main/AndroidManifest.xml
```

✅ 必須権限:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### 4. リリース用 Keystore 生成

**初回のみ実行**

```bash
keytool -genkey -v -keystore ~/measuretracker-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias measuretracker

# パスワードは安全に保管する
```

#### Keystore 情報保管
```
ファイル: ~/measuretracker-release.jks
alias: measuretracker
keystore_password: (安全に管理)
key_password: (安全に管理)
```

### 5. key.properties 設定（リリース署名用）✅ 実装済み

`android/app/build.gradle.kts` は `android/key.properties` の有無を見て、
存在すればそれで署名し、無ければ従来通りデバッグ鍵にフォールバックします
（`flutter build apk --release` がCI検証ビルドで引き続き動く理由）。

ローカルでリリース署名する場合、`android/key.properties`（**リポジトリ直下ではなく
`android/` フォルダ直下**）を作成:

```properties
storeFile=/Users/your_username/measuretracker-release.jks
storePassword=your_store_password
keyAlias=measuretracker
keyPassword=your_key_password
```

**セキュリティ注意**:
- `key.properties` と `*.jks`/`*.keystore` は `android/.gitignore` に既に
  登録されているため、誤ってコミットされることはありません
- GitHub Actions での自動署名は `android-release.yml` が
  Secretsから同等のファイルを動的生成します（`ANDROID_RELEASE_SIGNING_SETUP.md` 参照）

---

## 🔨 Android ビルドコマンド

### デバッグビルド（開発用 APK）
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

**出力**: `build/app/outputs/apk/debug/app-debug.apk`

### リリースビルド（Google Play 申請用 AAB）
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

**出力**: `build/app/outputs/bundle/release/app-release.aab`

### リリースビルド（APK）
```bash
flutter build apk --release --split-per-abi
```

**出力**: 
- `build/app/outputs/apk/release/app-arm64-v8a-release.apk`
- `build/app/outputs/apk/release/app-armeabi-v7a-release.apk`
- `build/app/outputs/apk/release/app-x86_64-release.apk`

---

## 📱 実機テスト手順（Android デバイス）

### 1. デバイス接続
```bash
# USB デバッグを有効化（デバイス設定）
# 開発者オプション → USB デバッグ ON

# 接続確認
flutter devices
adb devices
```

### 2. アプリをデバイスに展開
```bash
# デバッグビルド実行
flutter run -d <device_id> --debug

# またはリリースモード
flutter run -d <device_id> --release
```

### 3. テスト項目チェック

- [ ] **権限リクエスト**
  - マイク権限の確認ダイアログ表示
  
- [ ] **認証機能**
  - ゲストモードで起動確認
  - メール/パスワード認証（Firebase接続後）
  
- [ ] **プロジェクト管理**
  - プロジェクト作成・編集・削除
  - UI レスポンシブネス確認
  
- [ ] **測定機能** ⭐
  - マイク権限リクエスト表示
  - 音量測定開始・停止
  - dB 値表示（0-120dB 範囲）
  - 統計グラフ表示
  
- [ ] **ローカル保存** (Hive)
  - オフライン状態でデータ保存確認
  - Firebase 再接続時の同期
  
- [ ] **UI/UX**
  - Material Design 準拠
  - NotchやCutout対応
  - Dark Mode 対応確認
  - スクロール/ジェスチャー反応良好
  
- [ ] **パフォーマンス**
  - 起動時間 < 3秒
  - メモリ使用量 < 200MB
  - バッテリー消費正常

---

## 🚀 Google Play Store 申請準備

### 1. Google Play Console 登録
1. [Google Play Console](https://play.google.com/console) にアクセス
2. 新規アプリを作成
3. 以下を入力:
   - Name: `MeasureTracker`
   - Default Language: 日本語
   - App Type: アプリ
   - Category: ツール
   - Content Rating: (設問に回答)

### 2. メタデータ設定

#### 2.1 アプリ情報
- **アプリ名**: MeasureTracker
- **簡潔な説明**: 正確な音量計測アプリ (50文字)
- **説明**: 
  ```
  MeasureTracker は、正確な音量測定が必要な専門家・研究者向けの Android アプリです。

  【機能】
  ✓ リアルタイム dB 測定
  ✓ 測定履歴管理
  ✓ Before/After 比較分析
  ✓ CSV エクスポート
  ✓ マイク校正機能

  【サポート】
  問題報告やご質問は support@petit-works-apps.com までお願いします。
  ```

#### 2.2 スクリーンショット（最大 8枚）
**仕様**: 1440 x 2560px 以上

推奨スクリーンショット:
1. ホーム画面（プロジェクト一覧）
2. 測定画面（dB ゲージ）
3. グラフ表示（統計）
4. 比較画面（Before/After）
5. ログ画面（測定履歴）
6. Settings（マイク校正）

#### 2.3 プレビュー画像
- 解像度: 1024 x 500px
- 内容: アプリの主要機能紹介

#### 2.4 プライバシーポリシー
- URL: `https://petit-works-apps.com/privacy-ja`
- 必須事項:
  - マイクデータの取り扱い
  - Firebase クラウド同期の説明
  - データ保持期間

### 3. アプリの申請

#### 3.1 リリース設定
- **リリースタイプ**: 本番環境
- **ロールアウト**: 段階的 (10% → 50% → 100%)
- **リリースノート**:
  ```
  MeasureTracker v1.0.0 初回リリース

  ✨ 新機能
  - リアルタイム音量測定（dB ゲージ）
  - Before/After 測定比較
  - CSV データエクスポート
  - マイク校正機能

  🔐 セキュリティ
  - Firebase クラウド同期
  - ゲストモード対応

  🐛 その他
  - UI/UX 改善
  - パフォーマンス最適化
  ```

#### 3.2 コンテンツレーティング
設問に回答（暴力・性的表現など）

#### 3.3 対象年齢
- 全年齢対象推奨

#### 3.4 ビルド版の選択
- プロダクション AAB ファイル指定

### 4. レビュー & 公開
- [ ] すべてのセクション完了
- [ ] ストアプレイスページ完成
- [ ] AAB ファイルアップロード
- [ ] 自動審査実行（通常 2-4時間）
- [ ] 承認後、ロールアウト開始

---

## 📊 Google Play Store 審査ポイント

### ✅ よくある却下理由と対策

| 理由 | 対策 |
|------|------|
| クラッシュが多い | Crashlytics 監視・修正 |
| 権限が多すぎる | 不要な権限を削除 |
| プライバシー違反 | プライバシーポリシー充実 |
| テスト不足 | 複数デバイスでテスト |
| ドキュメント不足 | Support URL 明記 |

### 📋 最終チェックリスト

- [ ] AndroidManifest.xml に全権限記載
- [ ] firebase google-services.json 配置済み
- [ ] リリース Keystore 作成済み
- [ ] gradle.properties に署名情報設定
- [ ] AAB ファイルビルド成功
- [ ] 実機テスト完了（複数 API level）
- [ ] クラッシュ 0件
- [ ] プライバシーポリシー公開
- [ ] Support URL 準備済み
- [ ] スクリーンショット 5枚以上

---

## 🔄 トラブルシューティング

### Google Play Services インストール
```bash
# AVD (エミュレータ) で GMS が必要な場合
flutter build apk --debug
flutter install  # インストール
```

### Keystore エラー
```bash
# Keystore パスワード忘れた場合
# → 新しい Keystore を生成して、Firebase Console で SHA-1 を更新
```

### ProGuard/R8 ビルドエラー
```gradle
// android/app/build.gradle
buildTypes {
  release {
    shrinkResources true
    minifyEnabled true
    proguardFiles getDefaultProguardFile('proguard-android-optimize.txt')
  }
}
```

---

## 📈 App Analytics 設定

### Google Analytics for Firebase
```dart
// lib/main.dart で既に FirebaseAnalytics を設定済み
```

### Crashlytics（エラー監視）
```yaml
# pubspec.yaml に firebase_crashlytics を追加（推奨）
```

---

## 📝 Version 管理

### pubspec.yaml の version 更新
```yaml
version: 1.0.0+1  # build-name+build-number
```

**マッピング**:
- `1.0.0` = Play Store バージョン
- `+1` = versionCode（整数、毎回インクリメント）

### 次バージョン例
```yaml
version: 1.0.1+2  # 小バグ修正
version: 1.1.0+3  # 機能追加
version: 2.0.0+4  # メジャー更新
```

---

## 📌 次のステップ

1. **iOS リリース** (並行実施)
   - App Store 申請

2. **クローズドベータテスト** (任意)
   - Google Play テストプログラム
   - 50 人までのテスター招待可能

3. **段階的ロールアウト**
   - 10% (1-2日) → 観察
   - 50% (1-2日) → 観察
   - 100% → 全公開

---

**Last Updated**: 2026-08-06  
**Status**: Phase 7.2 準備中  
**Android Minimum**: API 21  
**Target Bundle ID**: com.yourwish.measuretrackers
