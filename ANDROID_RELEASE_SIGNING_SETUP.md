# Android 署名付きリリースビルド（GitHub Actions）セットアップガイド

`.github/workflows/android-release.yml` は、署名済みの Google Play 提出可能な
AAB（Android App Bundle）を自動生成し、任意で Google Play に直接アップロードする
ワークフローです。

`.github/workflows/android-build.yml`（デバッグ署名・全push/PRで実行するCI検証用）
とは別物です。こちらは **手動実行** または **`android-v*` タグのpush** でのみ動き、
実際のリリース用Keystore + Firebase実認証情報が必須です。

---

## 🔑 必要な Repository Secrets

`Settings → Secrets and variables → Actions → New repository secret` で以下を登録してください。

| Secret名 | 内容 | 必須 |
|---------|------|------|
| `FIREBASE_OPTIONS_DART_BASE64` | 実際の `lib/firebase_options.dart` をbase64化したもの | ✅ 必須 |
| `GOOGLE_SERVICES_JSON_BASE64` | 実際の `google-services.json` をbase64化したもの | ✅ 必須 |
| `ANDROID_KEYSTORE_BASE64` | リリース用Keystore（.jks）をbase64化したもの | ✅ 必須 |
| `ANDROID_KEYSTORE_PASSWORD` | Keystoreのパスワード | ✅ 必須 |
| `ANDROID_KEY_ALIAS` | Keystore内の鍵のエイリアス名 | ✅ 必須 |
| `ANDROID_KEY_PASSWORD` | 鍵自体のパスワード | ✅ 必須 |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_BASE64` | Google Play Console APIのサービスアカウントJSONをbase64化したもの | Play Store自動アップロード時のみ |

**Google Playサービスアカウントが未設定の場合**、AAB生成までは行われ、Google Playへの
アップロードだけがスキップされます（生成されたAABはワークフローのArtifactから
手動ダウンロード可能）。

---

## 📝 各Secretの取得手順

### 1. Firebase設定（FIREBASE_SETUP.md と同じ）
```bash
base64 -w0 lib/firebase_options.dart
# → FIREBASE_OPTIONS_DART_BASE64 に貼り付け

base64 -w0 android/app/google-services.json
# → GOOGLE_SERVICES_JSON_BASE64 に貼り付け
```

### 2. リリース用 Keystore の作成（初回のみ）

```bash
keytool -genkey -v -keystore measuretracker-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias measuretracker

# 対話式でパスワード・組織情報等を入力
# ここで設定するKeystoreパスワードが ANDROID_KEYSTORE_PASSWORD、
# 鍵パスワードが ANDROID_KEY_PASSWORD、
# -alias に指定した値が ANDROID_KEY_ALIAS になります
```

**⚠️ 重要**: このKeystoreと入力したパスワードは**紛失すると再発行不可**です。
一度Google Playに公開したアプリは、以後同じKeystoreでしか更新できません。
安全な場所に必ずバックアップしてください（後述の `ios-certs-vault` のような
専用の秘密情報保管リポジトリの利用を推奨）。

```bash
base64 -w0 measuretracker-release.jks
# → ANDROID_KEYSTORE_BASE64 に貼り付け
```

### 3. Google Play Console サービスアカウント（自動アップロード用・任意）

1. [Google Play Console](https://play.google.com/console) → 設定 → API アクセス
2. 「新しいサービスアカウントを作成」→ 手順に従って
   [Google Cloud Console](https://console.cloud.google.com/) でサービスアカウントを作成
3. Google Cloud Console でそのサービスアカウントの鍵（JSON）を作成・ダウンロード
4. Google Play Console に戻り、作成したサービスアカウントを招待
   - 権限: 最低でも「製造版へのリリースの管理」（もしくは該当トラックへの権限）
5. base64化:
   ```bash
   base64 -w0 play-service-account.json
   # → GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_BASE64 に貼り付け
   ```

**注意**: Google Playへのアップロードには、**該当パッケージ名で最低1回、
Play Console上で手動アップロードした実績**が必要です（APIだけで新規アプリの
初回公開はできません）。初回は `android-build.yml`/`android-release.yml` で
生成したAPK/AABを手動でPlay Consoleにアップロードしてから、以後の自動化を
有効にしてください。

---

## 🚀 実行方法

### 手動実行
1. GitHubリポジトリ → Actions → "Android Release (Signed AAB)" → "Run workflow"
2. `upload_to_play_store` にチェックを入れると、ビルド後自動でGoogle Playにアップロード
3. `play_store_track` でトラック（internal/alpha/beta/production）を選択

### タグpushで自動実行
```bash
git tag android-v1.0.0
git push origin android-v1.0.0
```
`android-v*` 形式のタグをpushすると自動的にビルド＋Google Playアップロードまで実行されます。

---

## ⚠️ 重要な注意事項

- **すべての認証情報はジョブ内のファイルに展開され、ログに出力されず、
  ジョブ終了時に必ず削除されます**（`Clean up signing material` ステップ）
- Secretsが1つでも未設定の場合、該当ステップで **明確なエラーメッセージを出して即座に失敗** します
  （サイレントスキップはしません）
- Google Playサービスアカウントが未設定でも、署名済みAAB自体は生成されワークフローの
  Artifactから取得できます。Google Playアップロードだけが任意です
- **このワークフロー自体は、この環境（Claude Codeのサンドボックス）には実際の
  Android Keystore・Google Play認証情報が無いため、エンドツーエンドでの動作確認が
  できていません。** YAML構文・埋め込みシェルスクリプトの構文（`bash -n`）、
  および `android/app/build.gradle.kts` の署名設定ロジック（`key.properties` の
  有無によるフォールバック）は検証済みですが、実際にSecretsを設定した上での
  初回実行では、Keystoreのフォーマットや権限不足など、想定外のエラーが出る
  可能性があります。初回はまず `upload_to_play_store: false` で手動実行し、
  AAB生成まで成功することを確認してから Google Play アップロードを有効に
  することを推奨します。

---

## 🔄 トラブルシューティング

### "Keystore was tampered with, or password was incorrect"
- `ANDROID_KEYSTORE_PASSWORD` が実際のパスワードと一致しているか確認
- `ANDROID_KEYSTORE_BASE64` が正しくbase64化されているか確認
  （`base64 -w0` を使わずに改行入りでエンコードすると壊れることがあります）

### "No key with alias 'xxx' found in keystore"
- `ANDROID_KEY_ALIAS` がKeystore作成時に指定した `-alias` の値と完全一致しているか確認

### Google Playアップロードが失敗する
- サービスアカウントがPlay Consoleに招待され、必要な権限が付与されているか確認
- 対象パッケージ名（`com.yourwish.measuretrackers`）で、Play Console上に
  **最低1回の手動アップロード実績**があるか確認（初回公開はAPI経由不可）
- versionCode（`pubspec.yaml` の `version: x.x.x+N` の `N`）が既存リリースと
  重複していないか確認

---

**関連ドキュメント**: ANDROID_BUILD_GUIDE.md（デバッグ署名CI検証ビルド）, FIREBASE_SETUP.md, iOS_RELEASE_SIGNING_SETUP.md（同様のiOS向け仕組み）
