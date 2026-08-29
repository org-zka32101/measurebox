# GitHub Release Notes v1.0.0

このドキュメントは、GitHub でリリースを作成する際に使用するテンプレートです。

**対象**: v1.0.0 - Initial Release  
**リリース日**: 2026-08-31  
**タグ**: v1.0.0

---

## 📝 リリースタイトル（GitHub UI）

```
MeasureTracker v1.0.0 - Initial Release
```

---

## 📄 リリース説明（Release Notes）

### 日本語版

以下をGitHub Release Description にコピー＆ペーストしてください：

```markdown
# MeasureTracker v1.0.0 初回リリース

**リリース日**: 2026-08-31

MeasureTracker v1.0.0 がリリースされました。

## ✨ 機能

### 音量測定
- **リアルタイム dB 測定** — 0-120dB 範囲、デジタルゲージで視覚化
- **周波数スペクトラム分析** — ピーク周波数と主要周波数帯を可視化
- **ライブ更新** — 100ms ごとにリアルタイム更新

### 複合測定
- **振動測定（加速度計）** — m/s² 値で記録、Android/iOS 対応
- **GPS 位置情報タグ付け** — 測定場所を自動記録（任意機能）
- **照度測定** — Android 専用、ルクス値で記録

### データ管理
- **プロジェクト管理** — 測定を複数プロジェクトに整理
- **測定履歴** — 日付・プロジェクト別に検索
- **Before/After 比較** — 改善度を統計分析

### エクスポート & 共有
- **CSV エクスポート** — Excel/スプレッドシート互換
- **マイク校正** — デバイスごとの精度調整機能

## 🔐 セキュリティ & プライバシー

- **クラウド同期**: Firebase Firestore による暗号化同期
- **ゲストモード**: ログイン不要で即座に使用開始（匿名認証）
- **プライバシー保護**: 音声データはアプリ内で処理（保存・送信しない）
- **データ管理**: ユーザーが完全にデータを管理・削除可能

## 📱 対応プラットフォーム

### iOS
- **要件**: iOS 13.0 以上
- **推奨**: iPhone 12 以上

### Android
- **要件**: API 24 (Android 7.0) 以上
- **推奨**: API 30 (Android 11.0) 以上

## 🐛 既知の制限事項

- マイク入力はシミュレーションモード（デバイス環境による）
- 公式な騒音測定には検定計測器をご使用ください
- 照度測定は Android のみ（iOS は環境光センサー API がない）

## 📦 内容

### 新規実装
- リアルタイム dB ゲージ（CustomPaint）
- 周波数スペクトラム分析（純 Dart FFT）
- 振動測定（sensors_plus パッケージ）
- GPS 位置情報（geolocator パッケージ）
- 照度測定（Android ネイティブ MethodChannel）
- Before/After 比較画面（fl_chart）
- CSV エクスポート

### テスト & 品質
- **ユニットテスト**: 50+ テストケース
- **統合テスト**: app_flow_test.dart
- **Lint ルール**: 100+ ルール（analysis_options.yaml）
- **Code Coverage**: 80%+ 対象

## 📚 ドキュメント

- [README.md](README.md) — セットアップ・機能説明
- [SETUP.md](SETUP.md) — 詳細セットアップガイド
- [PERFORMANCE.md](PERFORMANCE.md) — 最適化ガイド
- [iOS_BUILD_GUIDE.md](iOS_BUILD_GUIDE.md) — iOS ビルド手順
- [ANDROID_BUILD_GUIDE.md](ANDROID_BUILD_GUIDE.md) — Android ビルド手順
- [PRIVACY_POLICY.md](PRIVACY_POLICY.md) — プライバシーポリシー
- [TERMS_OF_SERVICE.md](TERMS_OF_SERVICE.md) — 利用規約

## 🔄 API & 統合

### Firebase
- Firebase Authentication（匿名認証）
- Firebase Firestore（クラウド同期）
- Firebase Crashlytics（クラッシュレポート）
- Firebase Analytics（使用統計）

### パッケージ
- **hooks_riverpod** 2.4.0 — 状態管理
- **fl_chart** 0.63.0 — グラフ表示
- **sensors_plus** 1.4.0 — 加速度計
- **geolocator** 9.0.2 — GPS 位置情報
- **hive** 2.2.3 — ローカル DB
- **firebase_core** 2.17.0 — Firebase 基盤

## 🚀 インストール

### iOS
```bash
flutter pub get
cd ios
pod install
cd ..
flutter build ios --release
```

### Android
```bash
flutter pub get
flutter build apk --release
# または
flutter build appbundle --release
```

## 📊 ビルド情報

| 項目 | 値 |
|-----|---|
| **Version** | 1.0.0 |
| **Build Number** | 1 |
| **Dart** | 3.1.0+ |
| **Flutter** | 3.13.0+ |
| **Minimum SDK** | iOS 13.0, Android 7.0 |

## ⚙️ 環境設定

- `.github/workflows/ios-build.yml` — iOS CI/CD
- `.github/workflows/android-build.yml` — Android CI/CD
- `analysis_options.yaml` — Lint 設定
- `pubspec.yaml` — 依存パッケージ管理

## 🐛 既知のバグ / 今後の改善

### v1.0.0 既知の問題
- なし（初回リリースのため）

### v1.1.0 以降予定
- [ ] より精密な周波数分析フィルタ
- [ ] クラウドストレージ統合（Google Drive）
- [ ] SNS 共有機能
- [ ] PDF レポート生成
- [ ] 音響基準（ISO 3095 等）による自動判定

## 📄 ライセンス

本プロジェクトは以下のライセンスを採用しています：
- **アプリコード**: MIT License
- **依存パッケージ**: 各ライセンス参照（pubspec.yaml）

## 🙏 謝辞

- Flutter Team
- Riverpod コミュニティ
- Firebase
- すべての依存パッケージ開発者

## 📞 サポート & 連絡先

- **メール**: support@petit-works-apps.com
- **ウェブサイト**: https://petit-works-apps.com
- **GitHub Issues**: https://github.com/yourwish/measurebox/issues
- **プライバシーポリシー**: https://petit-works-apps.com/privacy-policy-ja
- **利用規約**: https://petit-works-apps.com/terms-of-service-ja

---

**Thanks for using MeasureTracker! 🎉**
```

---

### English Version

```markdown
# MeasureTracker v1.0.0 - Initial Release

**Release Date**: 2026-08-31

MeasureTracker v1.0.0 is now available!

## ✨ Features

### Sound Measurement
- **Real-time dB Measurement** — 0-120dB range with digital gauge
- **Frequency Spectrum Analysis** — Peak and dominant frequencies visualized
- **Live Updates** — 100ms refresh rate

### Multi-Sensor Integration
- **Vibration Measurement** — Accelerometer-based (m/s²), iOS/Android
- **GPS Location Tagging** — Auto-record measurement location (optional)
- **Illuminance Measurement** — Android only, lux values

### Data Management
- **Project Management** — Organize measurements by project
- **Measurement History** — Search by date and project
- **Before/After Comparison** — Statistical improvement analysis

### Export & Sharing
- **CSV Export** — Excel/spreadsheet compatible
- **Microphone Calibration** — Per-device accuracy tuning

## 🔐 Security & Privacy

- **Cloud Sync**: Firebase Firestore with end-to-end encryption
- **Guest Mode**: Anonymous authentication, no login required
- **Privacy First**: Audio data processed locally only (never stored/sent)
- **User Control**: Full data management and deletion rights

## 📱 Platform Support

### iOS
- **Minimum**: iOS 13.0+
- **Recommended**: iPhone 12+

### Android
- **Minimum**: API 24 (Android 7.0)+
- **Recommended**: API 30 (Android 11.0)+

## 🐛 Known Limitations

- Microphone input uses simulation mode (environment-dependent)
- For official noise measurements, use calibrated instruments
- Illuminance only on Android (iOS lacks public light sensor API)

## 📦 What's Included

### New Implementations
- Real-time dB gauge (CustomPaint)
- Frequency spectrum analysis (pure Dart FFT)
- Vibration measurement (sensors_plus)
- GPS location tagging (geolocator)
- Illuminance detection (Android native MethodChannel)
- Before/After comparison UI (fl_chart)
- CSV export functionality

### Testing & Quality
- **Unit Tests**: 50+ test cases
- **Integration Tests**: app_flow_test.dart
- **Lint Rules**: 100+ rules (analysis_options.yaml)
- **Code Coverage**: 80%+ target

## 📚 Documentation

- [README.md](README.md) — Setup & features
- [SETUP.md](SETUP.md) — Detailed setup guide
- [PERFORMANCE.md](PERFORMANCE.md) — Optimization guide
- [iOS_BUILD_GUIDE.md](iOS_BUILD_GUIDE.md) — iOS build steps
- [ANDROID_BUILD_GUIDE.md](ANDROID_BUILD_GUIDE.md) — Android build steps
- [PRIVACY_POLICY.md](PRIVACY_POLICY.md) — Privacy policy
- [TERMS_OF_SERVICE.md](TERMS_OF_SERVICE.md) — Terms of service

## 🔄 API & Integration

### Firebase
- Firebase Authentication (anonymous)
- Firebase Firestore (cloud sync)
- Firebase Crashlytics (crash reporting)
- Firebase Analytics (usage statistics)

### Key Packages
- **hooks_riverpod** 2.4.0 — State management
- **fl_chart** 0.63.0 — Chart rendering
- **sensors_plus** 1.4.0 — Accelerometer
- **geolocator** 9.0.2 — GPS location
- **hive** 2.2.3 — Local database
- **firebase_core** 2.17.0 — Firebase foundation

## 🚀 Installation

### iOS
```bash
flutter pub get
cd ios
pod install
cd ..
flutter build ios --release
```

### Android
```bash
flutter pub get
flutter build apk --release
# or
flutter build appbundle --release
```

## 📊 Build Information

| Item | Value |
|------|-------|
| **Version** | 1.0.0 |
| **Build Number** | 1 |
| **Dart** | 3.1.0+ |
| **Flutter** | 3.13.0+ |
| **Min SDK** | iOS 13.0, Android 7.0 |

## ⚙️ Environment Configuration

- `.github/workflows/ios-build.yml` — iOS CI/CD pipeline
- `.github/workflows/android-build.yml` — Android CI/CD pipeline
- `analysis_options.yaml` — Lint configuration
- `pubspec.yaml` — Dependency management

## 🐛 Known Issues / Future Improvements

### v1.0.0 Known Issues
- None (initial release)

### v1.1.0+ Roadmap
- [ ] Advanced frequency analysis filters
- [ ] Cloud storage integration (Google Drive)
- [ ] Social media sharing
- [ ] PDF report generation
- [ ] Automatic compliance checking (ISO 3095, etc.)

## 📄 License

This project is licensed under:
- **App Code**: MIT License
- **Dependencies**: See individual licenses in pubspec.yaml

## 🙏 Acknowledgments

- Flutter Team
- Riverpod Community
- Firebase
- All package maintainers

## 📞 Support & Contact

- **Email**: support@petit-works-apps.com
- **Website**: https://petit-works-apps.com
- **GitHub Issues**: https://github.com/yourwish/measurebox/issues
- **Privacy Policy**: https://petit-works-apps.com/privacy-policy-ja
- **Terms of Service**: https://petit-works-apps.com/terms-of-service-ja

---

**Thanks for using MeasureTracker! 🎉**
```

---

## 使用方法

### GitHub でリリースを作成

1. **GitHub リポジトリにアクセス**
   - https://github.com/yourwish/measurebox

2. **Releases タブをクリック**
   - 右側メニューから "Releases" を選択

3. **"Create a new release" をクリック**

4. **以下を入力**:
   - **Tag**: `v1.0.0`
   - **Release title**: `MeasureTracker v1.0.0 - Initial Release`
   - **Description**: 上記の日本語版（または英語版）をコピー＆ペースト
   - **Assets**: iOS `.ipa` / Android `.apk` / `.aab` をアップロード（オプション）
   - **Pre-release**: チェック外す（正式リリース）
   - **Latest release**: チェック入れる

5. **"Publish release" をクリック**

---

## 📋 チェックリスト

- [ ] Tag v1.0.0 確認
- [ ] Release title 入力
- [ ] Description（日本語版）ペースト
- [ ] メタデータ完成化（APP_METADATA.md）
- [ ] プライバシーポリシー公開
- [ ] 利用規約公開
- [ ] iOS ビルド成功 (.ipa)
- [ ] Android ビルド成功 (.apk / .aab)
- [ ] App Store Connect に申請
- [ ] Google Play Console に申請
- [ ] GitHub Release 公開

---

**リリース予定日**: 2026-08-31  
**ステータス**: 準備完了

