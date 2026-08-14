# iOS 署名付きリリースビルド（GitHub Actions）セットアップガイド

`.github/workflows/ios-release.yml` は、署名済みの App Store 提出可能な IPA を
自動生成し、任意で TestFlight に直接アップロードするワークフローです。

`.github/workflows/ios-build.yml`（未署名・全push/PRで実行するCI検証用）とは
別物です。こちらは **手動実行** または **`ios-v*` タグのpush** でのみ動き、
Apple Developer の実認証情報が必須です。

---

## 🔑 必要な Repository Secrets

`Settings → Secrets and variables → Actions → New repository secret` で以下を登録してください。

| Secret名 | 内容 | 必須 |
|---------|------|------|
| `FIREBASE_OPTIONS_DART_BASE64` | 実際の `lib/firebase_options.dart` をbase64化したもの | ✅ 必須 |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | 実際の `GoogleService-Info.plist` をbase64化したもの | ✅ 必須 |
| `APPLE_CERTIFICATE_BASE64` | 配布用証明書（.p12）をbase64化したもの | ✅ 必須 |
| `APPLE_CERTIFICATE_PASSWORD` | 上記.p12のエクスポート時パスワード | ✅ 必須 |
| `APPLE_PROVISIONING_PROFILE_BASE64` | App Store配布用Provisioning Profile（.mobileprovision）をbase64化したもの | ✅ 必須 |
| `APPLE_KEYCHAIN_PASSWORD` | CI内で使い捨てキーチェーンを作る際のパスワード（任意のランダム文字列でOK、実在のパスワードではない） | ✅ 必須 |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API キーのID | TestFlight自動アップロード時のみ |
| `APP_STORE_CONNECT_API_ISSUER_ID` | App Store Connect API の Issuer ID | TestFlight自動アップロード時のみ |
| `APP_STORE_CONNECT_API_KEY_BASE64` | API キー（.p8ファイル）をbase64化したもの | TestFlight自動アップロード時のみ |

**App Store Connect API キー3点が未設定の場合**、IPA生成までは行われ、TestFlightへの
アップロードだけがスキップされます（生成されたIPAはワークフローのArtifactから
手動ダウンロード可能）。

---

## 📝 各Secretの取得手順

### 1. Firebase設定（FIREBASE_SETUP.md と同じ）
```bash
flutterfire configure --project=petit-works-utility
base64 -i lib/firebase_options.dart | pbcopy
# → FIREBASE_OPTIONS_DART_BASE64 に貼り付け

base64 -i ios/Runner/GoogleService-Info.plist | pbcopy
# → GOOGLE_SERVICE_INFO_PLIST_BASE64 に貼り付け
```

### 2. Apple 配布証明書（.p12）の作成

1. [Apple Developer Portal](https://developer.apple.com/account/resources/certificates/list) にログイン
2. Certificates → "+" → **Apple Distribution** を選択
3. ローカルMacで CSR (Certificate Signing Request) を作成:
   - キーチェーンアクセス → 証明書アシスタント → 認証局に証明書を要求
4. CSRをアップロードして証明書をダウンロード（.cer）
5. ダウンロードした.cerをダブルクリックしてキーチェーンにインストール
6. キーチェーンアクセスで証明書を右クリック → 書き出す → **.p12形式**を選択
   - この時設定するパスワードが `APPLE_CERTIFICATE_PASSWORD` になります
7. base64化:
   ```bash
   base64 -i distribution.p12 | pbcopy
   # → APPLE_CERTIFICATE_BASE64 に貼り付け
   ```

### 3. Provisioning Profile の作成

1. [Apple Developer Portal](https://developer.apple.com/account/resources/profiles/list) → Profiles → "+"
2. **App Store** を選択（配布用）
3. App ID: `com.yourwish.measuretrackers` を選択
4. 手順2で作成した Distribution証明書を選択
5. Profile名を入力してダウンロード（.mobileprovision）
6. base64化:
   ```bash
   base64 -i MeasureTracker_AppStore.mobileprovision | pbcopy
   # → APPLE_PROVISIONING_PROFILE_BASE64 に貼り付け
   ```

### 4. キーチェーンパスワード
```bash
# 任意のランダム文字列を生成するだけ。CI内の使い捨てキーチェーン専用で、
# Apple IDやその他の実パスワードとは無関係。
openssl rand -base64 24
# → APPLE_KEYCHAIN_PASSWORD に貼り付け
```

### 5. App Store Connect API キー（TestFlight自動アップロード用・任意）

1. [App Store Connect](https://appstoreconnect.apple.com/access/api) → ユーザーとアクセス → キー
2. "+" で新規キー作成（ロール: **App Manager** 推奨）
3. Key ID と Issuer ID をメモ
4. .p8ファイルをダウンロード（**一度しかダウンロードできないので注意**）
5. base64化:
   ```bash
   base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
   # → APP_STORE_CONNECT_API_KEY_BASE64 に貼り付け
   ```
6. `APP_STORE_CONNECT_API_KEY_ID` に Key ID、`APP_STORE_CONNECT_API_ISSUER_ID` に Issuer ID を設定

---

## 🚀 実行方法

### 手動実行
1. GitHubリポジトリ → Actions → "iOS Release (Signed IPA)" → "Run workflow"
2. `upload_to_testflight` にチェックを入れると、ビルド後自動でTestFlightにアップロード

### タグpushで自動実行
```bash
git tag ios-v1.0.0
git push origin ios-v1.0.0
```
`ios-v*` 形式のタグをpushすると自動的にビルド＋TestFlightアップロードまで実行されます。

---

## ⚠️ 重要な注意事項

- **すべての認証情報はジョブ内の使い捨てキーチェーン/ファイルに展開され、ログに出力されず、
  ジョブ終了時に破棄されます**（`Clean up ephemeral keychain` ステップで明示的に削除）
- Secretsが1つでも未設定の場合、該当ステップで **明確なエラーメッセージを出して即座に失敗** します
  （サイレントスキップはしません）
- App Store Connect API キーが未設定でも、署名済みIPA自体は生成されワークフローの
  Artifactから取得できます。TestFlightアップロードだけが任意です
- **このワークフロー自体は、この環境（Claude Codeのサンドボックス）には実際の
  Apple Developer認証情報が無いため、エンドツーエンドでの動作確認ができていません。**
  YAML構文・埋め込みシェルスクリプトの構文（`bash -n`）は検証済みですが、実際に
  Secretsを設定した上での初回実行では、証明書のフォーマットやProvisioning Profileの
  Bundle ID不一致など、想定外のエラーが出る可能性があります。初回はまず
  `upload_to_testflight: false` で手動実行し、IPA生成まで成功することを確認してから
  TestFlightアップロードを有効にすることを推奨します。

---

## 🔄 トラブルシューティング

### "No signing certificate" エラー
- `.p12` のパスワードが `APPLE_CERTIFICATE_PASSWORD` と一致しているか確認
- 証明書の種類が **Apple Distribution**（Apple Developmentではない）か確認

### "No profiles for 'com.yourwish.measuretrackers' were found"
- Provisioning ProfileのApp IDが `com.yourwish.measuretrackers` と完全一致しているか確認
- Provisioning Profileが期限切れでないか確認

### TestFlightアップロードが失敗する
- App Store Connect API キーのロールが最低でも **App Manager** であるか確認
- バンドルのVersion/Build番号が既存のTestFlightビルドと重複していないか確認
  （`pubspec.yaml` の `version: x.x.x+N` の `N` を上げる）

---

**関連ドキュメント**: iOS_BUILD_GUIDE.md（未署名CI検証ビルド）, FIREBASE_SETUP.md
