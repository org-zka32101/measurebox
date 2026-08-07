# 🚀 クイックスタート: デバッグビルド実行

このガイドでは、**最短時間で** デバッグビルドと実機テストを開始する手順を説明します。

---

## ⚡ 高速実行（5ステップで完了）

### Step 1: Firebase 設定ファイル確認（5分）

```bash
# ファイルが配置されているか確認
test -f ios/Runner/GoogleService-Info.plist && \
  echo "✓ iOS Firebase 設定ファイル OK" || \
  echo "✗ iOS Firebase 設定ファイルなし"

test -f android/app/google-services.json && \
  echo "✓ Android Firebase 設定ファイル OK" || \
  echo "✗ Android Firebase 設定ファイルなし"
```

**ファイルがない場合**: 
→ [FIREBASE_SETUP.md](FIREBASE_SETUP.md) に従ってダウンロード

### Step 2: 環境チェック（2分）

```bash
flutter doctor -v
```

**チェック項目**:
- ✓ Flutter
- ✓ Android toolchain
- ✓ Xcode（iOS の場合）
- ✓ CocoaPods（iOS の場合）

### Step 3: 依存関係インストール（3分）

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 4: デバッグビルド実行（10-30分）

#### iOS
```bash
# CocoaPods セットアップ（初回のみ）
cd ios && pod install && cd ..

# ビルド実行
./scripts/build_ios.sh debug
# または
flutter build ios --debug
```

#### Android
```bash
# ビルド実行
./scripts/build_android.sh debug apk
# または
flutter build apk --debug
```

### Step 5: 実機で実行（5分）

```bash
# デバイス接続確認
flutter devices

# iOS
flutter run -d <device_id>

# Android
flutter run -d <device_id>
```

---

## 🎯 ビルド成功の目安

### ビルド完了メッセージ（iOS）
```
Built build/ios/Debug-iphoneos/Runner.app
```

### ビルド完了メッセージ（Android）
```
Built build/app/outputs/apk/debug/app-debug.apk
```

### アプリ起動後の確認
- ✓ アプリが起動する
- ✓ クラッシュしない
- ✓ ホーム画面が表示される
- ✓ プロジェクト一覧が表示される

---

## ❌ よくあるエラーと対処法

### エラー 1: Firebase 設定ファイルが見つからない
```
Error: Could not find GoogleService-Info.plist
```

**対処**:
```bash
# Step 1 を実行してファイルを配置
# または FIREBASE_SETUP.md に従ってダウンロード
```

### エラー 2: CocoaPods エラー（iOS）
```
[!] Specs not found for https://github.com/CocoaPods/Specs.git
```

**対処**:
```bash
cd ios
rm -rf Pods Podfile.lock
pod repo update
pod install
cd ..
```

### エラー 3: Gradle ビルドエラー（Android）
```
Build failed with an exception
```

**対処**:
```bash
flutter clean
rm -rf android/.gradle
flutter pub get
flutter build apk --debug
```

### エラー 4: メモリ不足
```
java.lang.OutOfMemoryError: Java heap space
```

**対処**:
```bash
# android/app/build.gradle に追加
android {
  dexOptions {
    javaMaxHeapSize "2048m"
  }
}
```

---

## 📊 ビルド時間の目安

| ステップ | 初回 | 2回目以降 |
|---------|------|---------|
| Firebase 設定ファイル取得 | 5分 | - |
| 環境チェック | 2分 | 2分 |
| 依存関係インストール | 3分 | 1分 |
| iOS デバッグビルド | 30分 | 5分 |
| Android デバッグビルド | 20分 | 3分 |
| 実機テスト | 5分+ | 5分+ |
| **合計** | **45-65分** | **16分** |

---

## 🔍 ビルド詳細情報の確認

### ビルド出力ディレクトリ

```bash
# iOS
ls -lh build/ios/Debug-iphoneos/

# Android
ls -lh build/app/outputs/apk/debug/
```

### ビルドサイズ確認

```bash
# iOS
du -sh build/ios/Debug-iphoneos/

# Android
ls -lh build/app/outputs/apk/debug/app-debug.apk
```

### ビルド詳細ログ確認

```bash
# iOS
flutter build ios --debug -v

# Android
flutter build apk --debug -v
```

---

## 🔗 参考リンク

- [Flutter ドキュメント](https://flutter.dev/docs)
- [Firebase ドキュメント](https://firebase.google.com/docs)
- [iOS ビルドガイド](iOS_BUILD_GUIDE.md)
- [Android ビルドガイド](ANDROID_BUILD_GUIDE.md)

---

## ✅ チェックリスト

- [ ] Firebase 設定ファイルが配置されている
- [ ] flutter doctor で環境 OK
- [ ] 依存関係がインストールされている
- [ ] iOS デバッグビルド成功
- [ ] Android デバッグビルド成功
- [ ] 実機でアプリが起動する
- [ ] ホーム画面が表示される
- [ ] クラッシュが発生していない

---

**Status**: Phase 7.2 - デバッグビルド & 実機テスト  
**Duration**: 45-65分（初回）  
**Next**: Phase 7.3 - iOS リリースビルド & App Store 申請
