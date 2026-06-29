# MeasureTracker v2.0 - Flutter Project

## Phase 1-2: 基礎セットアップ＆認証 - 完成状況

### Phase 1 ✅ **完了**
- Flutter プロジェクト作成
- pubspec.yaml に全依存パッケージ追加
- Hive ローカルDB 初期化構造
- Firebase 基本設定
- 定数（colors, strings, config, theme, routes）作成
- データモデル作成
  - UserModel (Hive @HiveType 0)
  - ProjectModel (Hive @HiveType 1) 
  - MeasurementModel (Hive @HiveType 2)
  - ComparisonModel (Hive @HiveType 3)
  - MeasurementType enum
- HiveService (ローカルDB管理)
- main.dart (Firebase + Hive 初期化)
- firebase_options.dart (Firebase設定プレースホルダ)

### Phase 2 ✅ **完了**
- FirebaseService (Firestore CRUD)
- AuthService (Firebase Auth)
- AuthProvider (Riverpod)
- LoginScreen (メール/パスワード認証)
- SignupScreen (アカウント作成)
- HomeScreen (プロジェクト一覧・簡易版)
- main.dart にルーティング追加

### Phase 3 ✅ **完了**
- ProjectProvider (Riverpod StreamProvider)
- ProjectCard widget (プロジェクト表示)
- NewProjectDialog (プロジェクト作成)
- ProjectDetailScreen (プロジェクト詳細)
- HomeScreen 更新（プロジェクト一覧表示）
- main.dart にプロジェクト詳細ルート追加

### Phase 3.5 ✅ **完了** (Settings・Logs・CSV)
- SettingsScreen (ユーザープロフィール・マイク校正)
- LogsScreen (測定ログ一覧・統計表示)
- MeasurementProvider (Riverpod)
- CSVService (CSV生成・保存)
- main.dart にルーティング追加

### Phase 4 ✅ **完了** (測定機能)
- AudioService (マイク入力・dB計算・統計)
- DecibelGauge (CustomPaint・円形ゲージ・ステータス色分け)
- MeasureScreen (測定開始・停止・メモ・保存)
- main.dart に /measure ルート追加

### Phase 5 ✅ **完了** (Before/After 比較)
- ComparisonProvider (Riverpod)
- ComparisonScreen (測定選択・統計表示・グラフ)
- MeasurementChart widget (BarChart・LineChart)
- main.dart に /comparison ルート追加

### Phase 6 ✅ **完了** (テスト・最適化・ドキュメント)
- **ドキュメント**:
  - README.md （セットアップ・機能説明）
  - SETUP.md （詳細なセットアップガイド）
  - PERFORMANCE.md （最適化ガイド）
- **コード品質**:
  - コード品質チェック・修正（8問題修正）
  - analysis_options.yaml（100+ルール）
- **ユニットテスト**:
  - measurement_model_test.dart
  - comparison_model_test.dart
  - csv_service_test.dart
  - validators_test.dart
- **統合テスト**:
  - integration_test/app_flow_test.dart
  - test_driver/integration_test.dart
- **ユーティリティ**:
  - lib/utils/validators.dart（検証関数）

## Next Steps

### 短期（すぐやる）
1. **firebase_options.dart を更新** ⭐ 必須
   - 実際のFirebase プロジェクト設定に置き換え
   - GCP Console から google-services.json / GoogleService-Info.plist をダウンロード
   
2. **build_runner で Hive コード生成** ⭐ 必須
   ```bash
   flutter pub run build_runner build
   ```
   これで user_model.g.dart 等が生成される

3. **Phase 6 その他の機能**
   - Comparison 一覧表示
   - SNS 共有機能
   - PDF 証拠化（v1.2 以降）

### ディレクトリ構成（Phase 5 完了時点）
```
lib/
├── main.dart                          ✅ Firebase + Hive + ルーティング
├── firebase_options.dart              ✅ (プレースホルダ)
├── constants/
│   ├── colors.dart                    ✅
│   ├── strings.dart                   ✅
│   ├── config.dart                    ✅
│   ├── theme.dart                     ✅
│   └── routes.dart                    ✅
├── models/
│   ├── user_model.dart                ✅
│   ├── project_model.dart             ✅
│   ├── measurement_model.dart         ✅
│   ├── comparison_model.dart          ✅
│   └── measurement_type.dart          ✅
├── services/
│   ├── hive_service.dart              ✅
│   ├── firebase_service.dart          ✅
│   ├── auth_service.dart              ✅
│   ├── csv_service.dart               ✅
│   └── audio_service.dart             ✅
├── providers/
│   ├── auth_provider.dart             ✅
│   ├── project_provider.dart          ✅
│   ├── measurement_provider.dart      ✅
│   └── comparison_provider.dart       ✅
├── views/
│   ├── screens/
│   │   ├── splash_screen.dart         ✅
│   │   ├── login_screen.dart          ✅
│   │   ├── signup_screen.dart         ✅
│   │   ├── home_screen.dart           ✅
│   │   ├── project_detail_screen.dart ✅
│   │   ├── settings_screen.dart       ✅
│   │   ├── logs_screen.dart           ✅
│   │   ├── measure_screen.dart        ✅
│   │   └── comparison_screen.dart     ✅
│   └── widgets/
│       ├── project_card.dart          ✅
│       ├── new_project_dialog.dart    ✅
│       ├── decibel_gauge.dart         ✅
│       └── measurement_chart.dart     ✅
└── utils/
    └── (作成予定)
```

## 重要な注意

### Windows で Symlink エラー
```
Creating symlink from C:\... to H:\... failed
```
→ Flutter プロジェクトを C:\ ドライブに移動すれば解決
　必要なら実行: `flutter doctor -v` で確認

### Firebase セットアップ
現在の firebase_options.dart はプレースホルダです。
実運用には以下が必須：
1. Firebase Console で プロジェクト作成
2. iOS/Android アプリ登録
3. google-services.json / GoogleService-Info.plist ダウンロード
4. firebase_options.dart に実値を設定

### Hive コード生成
Hive モデルを変更したら必ず実行：
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## API/Service 概要（実装予定）

### AuthService
- signup(email, password) → UserCredential
- login(email, password) → UserCredential
- logout()
- currentUser → Stream<User?>

### FirebaseService (Firestore)
- saveProject(Project) → void
- deleteProject(projectId) → void
- saveMeasurement(Measurement) → void
- streamMeasurements(projectId) → Stream<List<Measurement>>
- saveComparison(Comparison) → void

### AudioService (Phase 4)
- startMeasurement(onDBChange callback) → void
- stopMeasurement() → Measurement
- _calculateDB(audioData) → double (dB計算 + 校正)

### CSVService (Phase 6)
- generateCSV(measurements, projectId) → String

## リリースチェックリスト（参考）

Before App Store/Google Play:
- [ ] Firebase Rules 本番化
- [ ] iOS/Android 実機テスト（複数機種）
- [ ] オフライン動作確認
- [ ] クラッシュレート < 0.1%
- [ ] メタデータ完成（説明・スクリーンショット）
- [ ] プライバシーポリシー・利用規約公開

## 想定スケジュール

- **Week 1-2** (Phase 1): ✅ 完了 (6/14)
- **Week 3-4** (Phase 2): ✅ 完了 (6/14) - Firebase Auth + Login/Signup
- **Week 5-6** (Phase 3): ✅ 完了 (6/14) - Project CRUD + UI
- **Week 3.5** (Phase 3.5): ✅ 完了 (6/14) - Settings/Logs/CSV
- **Week 7-9** (Phase 4): ✅ 完了 (6/14) - AudioService + Gauge
- **Week 10-11** (Phase 5): ✅ 完了 (6/14) - Before/After 比較
- **Week 12** (Phase 6): テスト・最適化・リリース準備
- **Week 13-15** (Phase 7): リリース前最終確認

---

**Last Updated**: 2026-06-28  
**Status**: Phase 7 - 本番化完成 ✅  
**App Name**: MeasureTracker  
**Package Name**: com.petitworksapps.measuretracker  
**Firebase**: Configured (petit-works-utility project)  

### Phase 6 完成（元々）
  - ✅ ドキュメント（README/SETUP/PERFORMANCE）
  - ✅ コード品質チェック・修正（null safety等 8問題）
  - ✅ ユニットテスト（4テストスイート）
  - ✅ 統合テスト（app_flow_test）
  - ✅ Lint ルール設定（100+ルール）
  - ✅ Validators ユーティリティ実装

### Phase 6.5 - ゲストモード & UX改善追加実装 ✅
1. **ゲストモード実装**（ログイン機能無効化）
   - main.dart: 認証スキップ → HomeScreen直接
   - 全画面: guestUserId ('guest-user') 統一
   - Firebase Rules: ゲスト認可ルール（firestore.rules）

2. **削除確認ダイアログ**
   - ProjectCard（ホーム画面）
   - ProjectDetailScreen（詳細画面）
   - 削除予告メッセージ表示

3. **プロジェクト詳細画面改善**
   - プロジェクト情報カード（作成日付表示）

4. **新規プロジェクトダイアログ改善**
   - インライン入力検証（エラー表示）
   - 文字数カウンター（名前50/50、説明200/200）
   - SingleChildScrollView でスクロール対応

5. **Settings画面ゲストモード対応**
   - ユーザー認証情報削除（ユーザー名・メール・ログアウト・アカウント削除）
   - ゲストモードバッジ表示
   - マイク校正機能のみ表示

6. **Logs画面日付範囲フィルター**
   - AppBar フィルターボタン
   - 開始日・終了日 DatePicker
   - フィルター適用時のみ表示

7. **Comparison画面日付範囲フィルター**
   - Logs画面と同じ日付フィルター機能
   - Before/After測定選択時のみフィルター有効

### 成果物（APK版管理）
- v1.0-v1.2: 基本機能 + 削除ダイアログ
- v1.3-v1.5: 情報表示 + 入力検証
- v1.6: Settings対応
- v1.7-v1.8: 日付フィルター（Logs/Comparison）
- **最終版**: v1.8 (53.0MB) 全機能実装完成

**Next Phase**: Phase 7 リリース前最終確認
- [ ] Firestore Rules デプロイ手順
- [ ] 実機テスト（iOS/Android）
- [ ] Google Play申請準備
- [ ] GitHub Release タグ作成
