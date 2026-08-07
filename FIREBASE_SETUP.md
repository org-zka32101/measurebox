# Firebase 設定ファイル取得ガイド

MeasureTracker をビルド・実行するには、Firebase 設定ファイルが必須です。

## 📋 必要なファイル

| プラットフォーム | ファイル | 配置先 |
|-----------------|---------|-------|
| iOS | `GoogleService-Info.plist` | `ios/Runner/` |
| Android | `google-services.json` | `android/app/` |

---

## 🔧 iOS - GoogleService-Info.plist 取得

### Step 1: Firebase Console にアクセス
1. [Firebase Console](https://console.firebase.google.com/) を開く
2. プロジェクト: **`petit-works-utility`** を選択

### Step 2: iOS アプリを登録
1. **プロジェクト概要** → **アプリを追加** を選択
2. **iOS** を選択
3. 以下を入力:
   ```
   Bundle ID: com.petitworksapps.measuretracker
   App nickname: MeasureTracker
   App Store ID: (後で設定可能)
   Team ID: (Apple Developer Account から取得)
   ```
4. **アプリを登録** をクリック

### Step 3: GoogleService-Info.plist をダウンロード
1. ダウンロード画面で **`GoogleService-Info.plist`** をダウンロード
2. `ios/Runner/` ディレクトリに配置

```bash
# コマンド例
mv ~/Downloads/GoogleService-Info.plist ios/Runner/
```

### Step 4: Xcode で plist を追加（実機テスト時に実施）
```bash
open ios/Runner.xcworkspace
```
- Xcode で `GoogleService-Info.plist` を `Runner` ターゲットにドラッグ&ドロップ
- "Copy items if needed" をチェック

---

## 🔧 Android - google-services.json 取得

### Step 1: Firebase Console にアクセス
1. [Firebase Console](https://console.firebase.google.com/) を開く
2. プロジェクト: **`petit-works-utility`** を選択

### Step 2: Android アプリを登録
1. **プロジェクト概要** → **アプリを追加** を選択
2. **Android** を選択
3. 以下を入力:
   ```
   Package name: com.petitworksapps.measuretracker
   App nickname: MeasureTracker
   SHA-1: (後述)
   ```

### Step 3: SHA-1 フィンガープリント取得（初回のみ）

#### デバッグキー
```bash
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

出力から **SHA1** をコピーして Firebase Console に入力

#### リリースキー（後で生成）
```bash
# リリース用 Keystore がまだない場合
keytool -genkey -v -keystore ~/measuretracker-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias measuretracker
```

### Step 4: google-services.json をダウンロード
1. Firebase Console で **`google-services.json`** をダウンロード
2. `android/app/` ディレクトリに配置

```bash
# コマンド例
mv ~/Downloads/google-services.json android/app/
```

---

## 📝 ファイル配置確認

```bash
# iOS
ls -la ios/Runner/GoogleService-Info.plist

# Android
ls -la android/app/google-services.json
```

両ファイルが表示されればOK

---

## 🚀 これで準備完了！

ファイル配置後、ビルドが可能になります：

```bash
# iOS デバッグビルド
./scripts/build_ios.sh debug

# Android デバッグビルド
./scripts/build_android.sh debug apk
```

---

## 🔒 セキュリティ上の注意

⚠️ **重要**: `google-services.json` と `GoogleService-Info.plist` には API キーが含まれています。

- `.gitignore` に追加されていることを確認
- GitHub に誤ってコミットしないこと
- 公開リポジトリには配置しないこと

```bash
# .gitignore の確認
cat .gitignore | grep -E "google-services|GoogleService"
```

---

## ❓ トラブルシューティング

### ファイルが見つからないエラー
```
Error: Could not find google-services.json (or GoogleService-Info.plist)
```

**対策**: ファイルが正しいディレクトリに配置されているか確認
```bash
# iOS
ls ios/Runner/GoogleService-Info.plist

# Android
ls android/app/google-services.json
```

### Firebase 認証エラー
```
Error: Firebase initialization failed
```

**対策**: 
1. Firebase Console でアプリが登録されているか確認
2. Bundle ID / Package Name が一致しているか確認
3. SHA-1 フィンガープリント（Android）が正しいか確認

### Xcode ビルドエラー（iOS）
```
error: 'GoogleService-Info.plist' not found
```

**対策**: 
1. Xcode を開き直す: `open ios/Runner.xcworkspace`
2. `GoogleService-Info.plist` を `Runner` ターゲットにドラッグ&ドロップ
3. "Copy items if needed" にチェック

---

**Last Updated**: 2026-08-06  
**Firebase Project**: petit-works-utility  
**Status**: 準備ガイド作成完了
