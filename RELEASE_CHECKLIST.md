# MeasureTracker v1.0.0 リリース前最終チェックリスト

**Release Date Target**: 2026-08-31  
**Status**: Phase 7.1 準備中  
**App Version**: 1.0.0+1 (iOS/Android)  

---

## 📋 Phase 7: リリース前最終確認

### ✅ セクション 1: 環境・ビルド準備

#### 1.1 iOS ビルド環境
- [x] iOS_BUILD_GUIDE.md 作成
- [x] ios/Podfile 作成
- [x] scripts/build_ios.sh 作成
- [x] Info.plist にマイク権限追加
- [x] Info.plist に追跡権限追加
- [x] Info.plist に加速度センサー(振動測定)権限追加
- [ ] Firebase GoogleService-Info.plist ダウンロード
- [ ] Xcode 15.0+ インストール確認
- [ ] CocoaPods インストール確認

#### 1.2 Android ビルド環境
- [x] ANDROID_BUILD_GUIDE.md 作成
- [x] scripts/build_android.sh 作成
- [ ] Firebase google-services.json ダウンロード
- [ ] Android Studio インストール確認
- [ ] SDK API 34 インストール確認
- [ ] Release Keystore 生成

#### 1.3 Flutter & Dependencies
- [x] pubspec.yaml に全パッケージ追加済み
- [x] pubspec.lock ファイル確認
- [ ] `flutter pub get` 実行確認
- [ ] `flutter pub run build_runner build` 実行確認

---

### ✅ セクション 2: 機能・UI テスト

#### 2.1 iOS 実機テスト

##### インストール & 起動
- [ ] デバッグビルド成功: `flutter build ios --debug`
- [ ] iPhone 実機にインストール成功
- [ ] アプリ起動確認（クラッシュなし）
- [ ] ホーム画面表示確認

##### 権限リクエスト
- [ ] マイク権限ダイアログ表示
- [ ] ユーザーが "許可" 選択時の動作確認
- [ ] ユーザーが "許可しない" 選択時の動作確認

##### 認証機能
- [ ] ゲストモードで起動確認
- [ ] メール/パスワード入力フィールド表示（Firebase接続後）
- [ ] 登録ボタン動作確認

##### プロジェクト管理
- [ ] プロジェクト作成成功
- [ ] プロジェクト編集成功
- [ ] プロジェクト削除確認ダイアログ表示
- [ ] プロジェクト削除実行確認

##### 測定機能 ⭐ 重要
- [ ] 測定画面遷移成功
- [ ] マイク入力開始（"測定開始"ボタン）
- [ ] dB ゲージ表示（0-120dB 範囲）
- [ ] リアルタイム更新確認
- [ ] 測定停止（"停止"ボタン）
- [ ] 測定データ保存確認

##### グラフ・統計
- [ ] ログ画面でグラフ表示確認
- [ ] 棒グラフ（BarChart）表示
- [ ] 折れ線グラフ（LineChart）表示
- [ ] 統計情報（平均・最大・最小）表示

##### Before/After 比較
- [ ] 比較画面でドロップダウン表示
- [ ] Before 測定選択
- [ ] After 測定選択
- [ ] 比較結果グラフ表示
- [ ] 改善度 / 悪化度 表示

##### UI/UX
- [ ] Safe Area 対応（ノッチ表示なし）
- [ ] ダークモード表示確認
- [ ] 画面遷移がスムーズ
- [ ] ボタン押下反応が良好
- [ ] テキスト・アイコンサイズ適切

##### パフォーマンス
- [ ] 起動時間 < 3秒
- [ ] グラフ表示遅延なし（FPS 60+）
- [ ] メモリ使用量 < 200MB
- [ ] バッテリー消費が正常

#### 2.2 Android 実機テスト（同上）

**各項目を複数 API level でテスト**:
- [ ] API 24 (Android 7.0)
- [ ] API 30 (Android 11.0)
- [ ] API 34 (Android 14.0)

---

### ✅ セクション 3: データ・セキュリティ

#### 3.1 ローカル保存 (Hive)
- [ ] オフライン状態でデータ保存確認
- [ ] アプリ再起動後データ復元確認
- [ ] 複数プロジェクト保存・読み込み確認

#### 3.2 Cloud Sync (Firebase)
- [ ] Firebase 接続確認 (ゲストユーザー)
- [ ] Firestore にデータ同期確認
- [ ] オフライン→オンライン状態でのデータマージ確認

#### 3.3 セキュリティ
- [ ] Firebase Rules が正しく適用（ゲストアクセス許可）
- [ ] 他ユーザーのデータにアクセス不可確認
- [ ] HTTP → HTTPS の強制確認

#### 3.4 プライバシー
- [ ] マイクデータはローカルのみ保存確認
- [ ] クラウド同期時にマイク音声データは含まれない確認
- [ ] dB 値のみ保存確認

---

### ✅ セクション 4: App Store 申請準備（iOS）

#### 4.1 App Store Connect 登録
- [x] Apple Developer Account にログイン
- [x] 新規アプリ登録完了（⚠️ 旧 Bundle ID `com.petitworksapps.measuretracker` で登録済み。
      Bundle ID をコード側で `com.yourwish.measuretrackers` に変更したため、
      App Store Connect 側で Bundle ID の再登録／新規アプリ作成が必要。
      Bundle ID は App Store Connect 上で後から変更不可）
- [ ] Bundle ID: com.yourwish.measuretrackers で App Store Connect に再登録
- [ ] Initial Release Date: 2026-08-31

#### 4.2 メタデータ
- [ ] アプリ名: MeasureTracker
- [ ] サブタイトル: 正確な音量計測アプリ
- [ ] アプリケーション説明：
  ```
  MeasureTracker は、正確な音量測定が必要な専門家・研究者向けの iOS アプリです。

  【機能】
  ✓ リアルタイム dB 測定（0-120dB）
  ✓ 周波数スペクトラム分析（ピーク周波数・主要周波数帯を可視化）
  ✓ 測定履歴管理
  ✓ Before/After 比較分析
  ✓ CSV エクスポート
  ✓ マイク校正機能

  【対応デバイス】
  iPhone 12 以上推奨

  【サポート】
  問題報告やご質問は support@petit-works-apps.com までお願いします。
  ```

#### 4.3 スクリーンショット & 画像
- [ ] ホーム画面スクリーンショット (1242 x 2208px)
- [ ] 測定画面スクリーンショット
- [ ] グラフ表示スクリーンショット
- [ ] 比較画面スクリーンショット
- [ ] ログ画面スクリーンショット
- [ ] プレビュー画像 (1024 x 500px)

#### 4.4 ビルド & Version
- [ ] Version: 1.0.0
- [ ] Build Number: 1
- [ ] リリースノート:
  ```
  MeasureTracker v1.0.0 初回リリース

  ✨ 機能
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

#### 4.5 コンテンツレーティング
- [ ] IARC 申請完了
- [ ] 年齢制限: 全年齢向け

#### 4.6 プライバシー & ポリシー
- [ ] プライバシーポリシー公開済み
  ```
  https://petit-works-apps.com/privacy-ja
  ```
- [ ] Support URL 設定
  ```
  https://petit-works-apps.com/support
  ```
- [ ] EULA (利用規約) 公開済み

#### 4.7 審査提出
- [ ] リリースビルド成功: `flutter build ios --release`
- [ ] Archive 生成成功
- [ ] App Store に Upload 成功
- [ ] すべてのセクション完了
- [ ] 審査タイプ: "自動リリース" または "手動リリース"

---

### ✅ セクション 5: Google Play 申請準備（Android）

#### 5.1 Google Play Console 登録
- [ ] Google Play Console にログイン
- [ ] 新規アプリ登録完了
- [ ] Package Name: com.yourwish.measuretrackers
- [ ] Category: ツール/ユーティリティ

#### 5.2 メタデータ
- [ ] アプリ名: MeasureTracker
- [ ] 簡潔な説明 (80文字以下):
  ```
  リアルタイムdB測定・周波数分析・Before/After比較ができる高精度騒音計アプリ
  ```
  （44文字）
- [ ] 詳細説明 (4000文字以下):
  ```
  MeasureTracker は、正確な音量測定が必要な専門家・研究者向けの騒音計アプリです。

  【機能】
  ✓ リアルタイム dB 測定（0-120dB）
  ✓ 周波数スペクトラム分析（ピーク周波数・主要周波数帯を可視化）
  ✓ 測定履歴管理
  ✓ Before/After 比較分析
  ✓ CSV エクスポート
  ✓ マイク校正機能

  【対応デバイス】
  Android 7.0 (API 24) 以上

  【サポート】
  問題報告やご質問は support@petit-works-apps.com までお願いします。
  ```
- [ ] Feature Graphic (1024 x 500px)

#### 5.3 スクリーンショット & 画像
- [ ] スクリーンショット 5枚以上 (1440 x 2560px)
- [ ] プレビュー画像
- [ ] アプリアイコン (512 x 512px)

#### 5.4 ビルド & Version
- [ ] AAB (App Bundle) ビルド成功: `flutter build appbundle --release`
- [ ] Version: 1.0.0
- [ ] Version Code: 1
- [ ] リリースノート: (iOS と同じ)

#### 5.5 コンテンツレーティング
- [ ] IARC アンケート完了
- [ ] 年齢制限: 全年齢向け

#### 5.6 プライバシー & ポリシー
- [ ] プライバシーポリシー URL 設定
- [ ] Support URL 設定
- [ ] Firebase & Crashlytics データ収集説明

#### 5.7 権限確認
- [ ] RECORD_AUDIO (マイク)
- [ ] INTERNET (通信)
- [ ] ACCESS_NETWORK_STATE (ネットワーク状態)
- [ ] 不要な権限が含まれていないか確認

#### 5.8 審査提出
- [ ] AAB ファイル Upload 成功
- [ ] すべてのセクション完了
- [ ] リリースタイプ: "Production"
- [ ] ロールアウト戦略: "段階的" (10% → 50% → 100%)

---

### ✅ セクション 6: ドキュメント & リリースノート

#### 6.1 ドキュメント確認
- [x] README.md - セットアップガイド
- [x] SETUP.md - 詳細セットアップ
- [x] PERFORMANCE.md - 最適化ガイド
- [x] iOS_BUILD_GUIDE.md - iOS ビルド手順
- [x] ANDROID_BUILD_GUIDE.md - Android ビルド手順
- [x] RELEASE_CHECKLIST.md (このファイル)

#### 6.2 GitHub Release ノート
- [ ] GitHub で Release を作成
- [ ] Tag: v1.0.0
- [ ] Title: MeasureTracker v1.0.0 - Initial Release
- [ ] Release Notes:
  ```markdown
  # MeasureTracker v1.0.0 Initial Release

  ## ✨ Features
  - Real-time dB measurement (0-120dB range)
  - Project management
  - Before/After comparison analysis
  - CSV data export
  - Microphone calibration

  ## 🔐 Security & Privacy
  - Firebase cloud synchronization
  - Guest mode support
  - End-to-end encrypted communication
  - Privacy policy compliant

  ## 📱 Platforms
  - iOS 13.0+
  - Android API 21+

  ## 🐛 Bug Fixes & Improvements
  - Initial release
  - Full feature implementation
  - Performance optimization

  ## 📝 Changelog
  See [CHANGELOG.md](CHANGELOG.md) for detailed version history.
  ```

---

### ✅ セクション 7: 最終品質保証

#### 7.1 Code Quality
- [x] analysis_options.yaml で 100+ Lint ルール適用
- [ ] `flutter analyze` 実行 → Warning 0件
- [ ] `flutter test` 実行 → 全テスト PASS
- [ ] Code coverage > 80%

#### 7.2 パフォーマンス
- [ ] Dart DevTools でメモリプロファイル確認
- [ ] フレームレート 60fps 確認
- [ ] CPU 使用率が正常範囲
- [ ] バッテリー消費が最小化

#### 7.3 アクセシビリティ
- [ ] Semantic Widgets 使用確認
- [ ] テキスト対比度 (WCAG AA 以上)
- [ ] タッチターゲットサイズ (最小 48 x 48dp)
- [ ] Screen Reader 対応確認

#### 7.4 Crash レート
- [ ] Firebase Crashlytics 監視
- [ ] 既知の Crash: 0件
- [ ] ANR (応答なし): 0件

---

### ✅ セクション 8: リリース後の監視

#### 8.1 Analytics
- [ ] Firebase Analytics 監視設定
- [ ] 主要イベント:
  - `app_open`
  - `start_measurement`
  - `save_measurement`
  - `view_comparison`
- [ ] Conversion Funnel 定義

#### 8.2 Monitoring
- [ ] Crashlytics リアルタイムモニタリング
- [ ] Performance Monitoring 設定
- [ ] Alerts 設定:
  - Crash rate > 1%
  - ANR > 0件
  - HTTP error > 5%

#### 8.3 Support & Feedback
- [ ] Support Email 設定: support@petit-works-apps.com
- [ ] Support URL 公開: https://petit-works-apps.com/support
- [ ] Issue Tracker 設定

---

## 📊 最終マイルストーン

### v1.0.0 Release Targets

| Phase | Task | Status | ETA |
|-------|------|--------|-----|
| 7.1 | iOS ビルド環境構築 | ✅ 完了 | 2026-08-06 |
| 7.2 | iOS Debug Build & Test | ⏳ 進行中 | 2026-08-10 |
| 7.3 | Android Debug Build & Test | ⏳ 予定 | 2026-08-13 |
| 7.4 | App Store 申請 | ⏳ 予定 | 2026-08-20 |
| 7.5 | Google Play 申請 | ⏳ 予定 | 2026-08-22 |
| 7.6 | App Store 審査期間 | ⏳ 予定 | 2026-08-24 |
| 7.7 | Google Play 審査期間 | ⏳ 予定 | 2026-08-24 |
| 7.8 | iOS 公開 | ⏳ 予定 | 2026-08-27 |
| 7.9 | Android 公開 | ⏳ 予定 | 2026-08-29 |
| 7.10 | Post-Release Monitoring | ⏳ 予定 | 2026-08-31+ |

---

## 📝 署名欄

- **Prepared by**: Claude Code
- **Date**: 2026-08-06
- **Version**: 1.0.0+1
- **Status**: Phase 7.1 準備完了

---

## 🔗 参考リンク

### Apple
- [App Store Connect](https://appstoreconnect.apple.com/)
- [Apple Developer](https://developer.apple.com/)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios)

### Google
- [Google Play Console](https://play.google.com/console)
- [Android Developer](https://developer.android.com/)
- [Material Design](https://material.io/design)

### Firebase
- [Firebase Console](https://console.firebase.google.com/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

### Flutter
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Flutter Packages](https://pub.dev/)

---

**Last Updated**: 2026-08-06  
**Next Review**: 2026-08-13  
**Release Target**: 2026-08-31
