# MeasureBox - セットアップガイド

MeasureBox v1.0 を開発環境で実行するための詳細なセットアップ手順です。

## 前提条件

- **Flutter**: 3.x 以上
- **Dart**: 3.x 以上
- **Android**: API 26 以上
- **iOS**: 13.0 以上

## ステップ 1: 環境確認

```bash
flutter doctor
```

すべての項目が ✓ になっていることを確認してください。

## ステップ 2: 依存パッケージをインストール

```bash
cd measurebox
flutter pub get
```

## ステップ 3: Hive コード生成（重要）

このステップが必須です。Hive モデルの TypeAdapter を生成します。

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

以下ファイルが生成されます:
- `lib/models/user_model.g.dart`
- `lib/models/project_model.g.dart`
- `lib/models/measurement_model.g.dart`
- `lib/models/comparison_model.g.dart`

**トラブルシューティング**:
```bash
# キャッシュをクリアして再実行
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## ステップ 4: Firebase プロジェクトセットアップ

### 4.1: Firebase Console でプロジェクト作成

1. https://console.firebase.google.com にアクセス
2. 「プロジェクトを作成」をクリック
3. プロジェクト名: `MeasureBox` を入力
4. 「続行」をクリック

### 4.2: Google アナリティクス（オプション）

- Google アナリティクスは無効化でも構いません

### 4.3: Android アプリを登録

1. Firebase Console から「Android アプリを追加」
2. パッケージ名: `com.yourwish.measuretrackers`
3. アプリニックネーム: `MeasureBox` (オプション)
4. SHA-1 フィンガープリント:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   （SHA-1 値をコピーして入力）
5. `google-services.json` をダウンロード
6. `android/app/` に配置

### 4.4: iOS アプリを登録

1. Firebase Console から「iOS アプリを追加」
2. Bundle ID: `com.yourwish.measuretrackers`
3. アプリニックネーム: `MeasureBox` (オプション)
4. `GoogleService-Info.plist` をダウンロード
5. Xcode で `ios/Runner.xcworkspace` を開く
6. Runner プロジェクトに `GoogleService-Info.plist` をドラッグ&ドロップ

### 4.5: Firebase Firestore セットアップ

1. Firebase Console から「Firestore Database」を選択
2. 「データベースを作成」
3. セキュリティルール: 「テストモード」を選択（開発用）
4. ロケーション: `asia-northeast1` (日本)

### 4.6: Firebase Authentication セットアップ

1. Firebase Console から「Authentication」を選択
2. 「Sign-in method」タブをクリック
3. 「メール/パスワード」を有効化

## ステップ 5: Firebase 認証情報を設定

`lib/firebase_options.dart` を開いて、Firebase コンソールから取得した情報を入力します：

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyD_YOUR_API_KEY',
  appId: '1:YOUR_APP_ID:android:YOUR_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'measurebox-YOUR_ID',
  databaseURL: 'https://measurebox-YOUR_ID.firebaseio.com',
  storageBucket: 'measurebox-YOUR_ID.appspot.com',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'AIzaSyD_YOUR_API_KEY',
  appId: '1:YOUR_APP_ID:ios:YOUR_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'measurebox-YOUR_ID',
  databaseURL: 'https://measurebox-YOUR_ID.firebaseio.com',
  storageBucket: 'measurebox-YOUR_ID.appspot.com',
  iosBundleId: 'com.yourwish.measuretrackers',
);
```

## ステップ 6: アプリを実行

### Android

```bash
flutter run -d emulator-5554
# または実機の場合
flutter run -d <device_id>
```

### iOS

```bash
flutter run -d iphone
```

## ステップ 7: Firestore セキュリティルール設定（本番前に必須）

Firebase Console から Firestore の「Rules」タブを開き、以下を設定：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
      
      match /projects/{projectId} {
        allow read, write: if request.auth.uid == uid;
        
        match /measurements/{measurementId} {
          allow read, write: if request.auth.uid == uid;
        }
        
        match /comparisons/{comparisonId} {
          allow read, write: if request.auth.uid == uid;
        }
      }
    }
  }
}
```

「公開」をクリックして設定を保存します。

## ステップ 8: マイク権限設定

### Android (android/app/src/main/AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### iOS (ios/Runner/Info.plist)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>騒音を測定するためにマイクを使用します</string>
```

## テスト

```bash
# ユニットテスト
flutter test

# 統合テスト
flutter test integration_test/
```

## ビルド

### Android APK

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

## トラブルシューティング

### Firebase 初期化エラー

```
Error: Failed to initialize Firebase
```

→ Firebase Console で正しい JSON/plist をダウンロードしているか確認  
→ firebase_options.dart が正しく更新されているか確認

### Hive ボックスが見つからない

```
Error: Box not found: user
```

→ `flutter pub run build_runner build` を実行  
→ 生成されたファイル（*.g.dart）が存在するか確認

### マイク権限エラー

```
Permission denied
```

→ アプリの設定からマイク権限を許可する  
→ Info.plist / AndroidManifest.xml を確認

### Windows Symlink エラー

H:\ ドライブでビルドすると symlink エラーが発生する場合は、プロジェクトを C:\ に移動してください。

## 開発のヒント

### ホットリロード

コード変更時に `r` キーを押すと、アプリを再起動せずに変更を反映できます。

```bash
r     - ホットリロード
R     - ホットリスタート
q     - 終了
```

### デバッグ出力

```dart
import 'dart:developer' as developer;

developer.log('Debug message', name: 'measurebox');
```

### Riverpod DevTools

Riverpod の状態変更をリアルタイムで監視できます。

```bash
flutter pub add dev:riverpod_generator
```

## リソース

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase for Flutter](https://firebase.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Hive Database](https://hivedb.dev/)

---

**Last Updated**: 2026-06-14
