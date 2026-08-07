# ビルド検証レポート（実施済み）

**Date**: 2026-08-07
**実施内容**: Dart/Flutter SDK を実際にこの環境に導入し、`flutter analyze`/`flutter test`/`flutter build` を実行して検証

前回（周波数測定機能実装時点）は「この環境に Flutter SDK がなく検証できない」という
制約がありましたが、今回は **実際に Dart SDK 3.12.2 と Flutter SDK 3.44.9
（プロジェクトが要求する `sdk: ^3.12.0` を満たす組み合わせ）をダウンロード・導入し、
本物のツールチェーンで検証しました。**

---

## ✅ 検証結果サマリー

| コマンド | 結果 | 詳細 |
|---------|------|------|
| `flutter pub get` | ✅ 成功 | 全依存関係解決 |
| `flutter analyze` | ✅ **エラー0件** | 490件は全て info/warning（スタイルのみ、ビルド非阻害） |
| `flutter test` | ✅ **32/32 全合格** | 周波数分析10ケース含む |
| `flutter build web --debug` | ✅ **成功** | `build/web` 生成（53MB） |
| `flutter build web --release` | ✅ **成功** | Tree-shaking込みで成功 |
| `flutter build apk` | ⚠️ 未実施 | Android SDK取得が組織のエグレスポリシーでブロック（`dl.google.com` へのアクセス拒否、403）。回避はせず未実施のまま報告 |
| `flutter build ios` | ⚠️ 未実施 | iOS ビルドは macOS + Xcode が必須。この環境は Linux サンドボックスのため原理的に不可能 |

**結論**: Dart/Flutterコードベース自体（周波数測定機能を含む）は **完全にコンパイル可能** であることを実機のツールチェーンで確認しました。Android/iOS のネイティブパッケージング（APK/IPA生成）は、それぞれ Android SDK・Xcode が必要なため、開発者ご自身のマシンまたは CI で実行してください（手順は `iOS_BUILD_GUIDE.md` / `ANDROID_BUILD_GUIDE.md` 参照）。

---

## 🐛 検証中に発見・修正した実在のバグ

`flutter analyze` を初回実行した時点で、周波数測定機能とは無関係な **既存コードの実バグ** が複数見つかりました。すべて修正済みです。

### 1. `lib/views/screens/logs_screen.dart` — 構文エラー（コンパイル全体を阻害）
`children: [...]` リストと `Column(...)` の閉じ括弧 `],` `),` が2つ丸ごと欠落しており、
`flutter analyze`/`flutter build` が **ファイル全体、ひいてはアプリ全体** をパースできない状態でした。
括弧の対応をスタックで解析するスクリプトを書いて欠落箇所を特定し、修正しました。

### 2. `lib/firebase_options.dart` — ファイルが実在しなかった
`CLAUDE.md` には「作成済み（プレースホルダ）」と記載がありましたが、実際には
リポジトリに存在せず（`.gitignore` 対象のため）、`lib/main.dart` のコンパイルが
`Target of URI doesn't exist` で失敗していました。`flutterfire configure` 相当の
プレースホルダファイルを作成し、`lib/firebase_options.dart.example` として
テンプレートをコミット（実ファイルは引き続き `.gitignore` 対象のまま）。

### 3. `lib/models/comparison_model.dart` / `measurement_model.dart` — Firestore Timestamp 変換バグ
`fromFirestore()` が Firestore の `Timestamp`（`.toDate()` を持つ）のみを想定しており、
プレーンな `DateTime` を渡すと `NoSuchMethodError` でクラッシュしていました
（ユニットテストが実際にこれで落ちていました）。両方の型を受け付けるよう修正。

### 4. `test/services/csv_service_test.dart` — 文字列内の未エスケープ `$`
`'...!@#$%'` の `$` が Dart の文字列補間として解釈され構文エラー。raw string に変更。

### 5. `pubspec.yaml` — `integration_test` 依存関係の欠落
`integration_test/app_flow_test.dart` と `test_driver/integration_test.dart` が
`package:integration_test` を使用しているにもかかわらず `pubspec.yaml` に
宣言されておらず、解決エラーになっていました。`dev_dependencies` に追加。

### 6. `test/widget_test.dart` — `flutter create` のデフォルトテストが未更新のまま残存
このアプリには存在しない「カウンター」機能をテストする、`flutter create` 生成時の
ボイラープレートがそのまま残っていました。加えて `ProviderScope` でラップされておらず
`Bad state: No ProviderScope found` でクラッシュ。このアプリに即した
「ゲストモードで HomeScreen が起動する」スモークテストに書き換えました。

### 参考: 前回までに修正済みの `num.clamp()` 型バグ（5箇所）
`decibel_gauge.dart`, `audio_service.dart`, `measurement_model.dart` の計5箇所で
Dartの `num.clamp()` が `num` 型を返し `double`/`int` への暗黙代入がコンパイルエラーになる
既知の落とし穴を修正済み（前回コミットで対応、周波数測定機能実装時に発見）。

---

## 📋 検証方法の詳細

### 環境構築
```bash
# Dart SDK 3.12.2（単体、pure-Dartコードの検証用）
curl -sSL -o dart-sdk.zip \
  "https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64-release.zip"

# Flutter SDK 3.44.9（Dart 3.12.2 を内包、pubspec.yaml の sdk: ^3.12.0 要件を満たす）
curl -sSL -o flutter.tar.xz \
  "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.9-stable.tar.xz"
```

**注意**: 当初 Flutter 3.35.5 系（Dart 3.9.2 同梱）をダウンロードしたところ
`pubspec.yaml` の `sdk: ^3.12.0` 制約を満たせず `flutter pub get` が失敗しました。
Flutter の公開リリース一覧 API（`releases_linux.json`）から Dart 3.12.2 を
同梱する最新版（3.44.9）を特定し、そちらを使用しています。

### 純Dart FFTエンジンの二重検証
Flutter SDK 導入前は Python での独立検証（7/7合格）に加え、Dart SDK 単体でも
実際の Dart VM で `frequency_analysis_service.dart` を実行し、11/11 のアサーション
（既知周波数の検出精度、パフォーマンス計測含む）に合格しています。
FFT計算は8192サンプルあたり平均 **0.85ms**（JIT実行）で、150ms更新間隔に対し
十分高速であることも確認しました。

---

## 🚀 未実施項目（開発者環境で実施してください）

- [ ] `flutter build apk --debug` / `--release`（Android SDK が必要）
- [ ] `flutter build ios --debug` / `--release`（macOS + Xcode が必要）
- [ ] 実機テスト（iOS/Android）
- [ ] `flutterfire configure` で実際の Firebase 認証情報を生成

これらは `COMPLETE_BUILD_PROCEDURE.md` に記載の手順に従って進めてください。
Dart/Flutter コードベース自体は検証済みのため、あとはプラットフォーム固有の
ネイティブビルドとFirebase実認証情報の設定のみで、App Store/Google Play
提出物の生成に進めるはずです。

---

**Verified by**: Claude Code（このセッションで Dart 3.12.2 + Flutter 3.44.9 を導入し実行）
**Not a substitute for**: 実機テスト、Android/iOS ネイティブビルド、本番Firebase接続確認
