# MeasureBox v1.0

騒音を測定して、対策の効果を「数字で見える化」する Before/After 改善ツール。

## 概要

MeasureBox は、スマートフォンのマイクを使って騒音レベル（dB）を測定し、対策前後の改善効果を視覚的に比較できるアプリです。

**主な機能**:
- 🎤 リアルタイム騒音計（dBA対応）
- 📊 Before/After グラフ化
- 💾 ログ管理＆CSV出力
- ⚙️ マイク感度校正

## インストール・セットアップ

### 前提条件
- Flutter 3.x 以上
- iOS 13.0+ / Android 8.0+
- Firebase プロジェクト

### ステップ 1: プロジェクト設定

```bash
cd measurebox
flutter pub get
```

### ステップ 2: Hive コード生成（必須）

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### ステップ 3: Firebase セットアップ

1. Firebase Console で新しいプロジェクトを作成
2. iOS/Android アプリを登録
3. google-services.json / GoogleService-Info.plist をダウンロード
4. lib/firebase_options.dart を実際の Firebase 認証情報で更新

### ステップ 4: アプリ実行

```bash
flutter run
```

## ユーザーフロー

```
ログイン/サインアップ
  ↓
ホーム（プロジェクト一覧）
  ├─ 新規プロジェクト作成
  └─ プロジェクト詳細
     ├─ 測定開始（リアルタイムゲージ）
     ├─ Before/After 比較（グラフ表示）
     └─ ログ（測定履歴・CSV出力）
```

## 技術スタック

- **言語**: Dart 3.x
- **フレームワーク**: Flutter 3.x
- **状態管理**: Riverpod 2.x
- **ローカルDB**: Hive 2.x
- **クラウドDB**: Firebase Firestore
- **認証**: Firebase Auth
- **グラフ**: fl_chart 0.65

## 開発ロードマップ

- **v1.0** (2026年11月) — MVP完成
- **v1.1** (2027年1月) — スコア化・自動ログ
- **v1.2** (2027年4月) — マップ・証拠化
- **v2.0** (2027年7月) — 完全プラットフォーム化

## トラブルシューティング

### Hive コード生成に失敗

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### マイク権限エラー

iOS: Info.plist に NSMicrophoneUsageDescription を追加  
Android: AndroidManifest.xml に RECORD_AUDIO パーミッション追加

### Firebase が初期化されない

firebase_options.dart に実際の Firebase 認証情報を設定してください

## ライセンス

MIT License

---

**Last Updated**: 2026-06-14  
**Version**: 1.0.0-dev  
**Status**: Phase 5 完成、Phase 6 テスト・最適化中
