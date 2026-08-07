# 周波数測定機能 - 実装計画書（v1.0.0 統合版）

**Status**: ⏳ 実装開始待機  
**Target Release**: v1.0.0 (2026-08-31)  
**Duration**: 9-14 日  
**Scope**: 全周波数スペクトラム表示 + デジタル表示

---

## 📋 要件仕様

### 機能要件
- ✅ **周波数範囲**: 0-22050Hz（全周波数）
- ✅ **周波数分解能**: ±5Hz（中程度精度）
- ✅ **表示方式**: グラフ＋デジタル表示の両方
- ✅ **リアルタイム性**: 100ms 以下の遅延
- ✅ **プラットフォーム**: iOS・Android 両対応

### 非機能要件
- **CPU 使用率**: < 30%
- **メモリ使用量**: < 100MB
- **バッテリー消費**: 1.5-2倍（dB 測定比）
- **フレームレート**: 60fps 維持

---

## 🔧 技術実装方針

### 方案B（標準版）を採用
```
実マイク入力（PCM 16-bit, 44.1kHz）
    ↓
FFT 処理（4096サンプル / フレーム）
    ↓
周波数スペクトラム計算
    ↓
UI 表示（グラフ + デジタル）
```

### パッケージスタック

#### オーディオ入力
```yaml
dependencies:
  audio_waveforms: ^1.1.0        # ✅ マイク入力（リアルタイム）
  record: ^5.0.0                 # バックアップ（フォールバック）
```

#### FFT & 信号処理
```yaml
dependencies:
  fft: ^0.7.0                    # ✅ Dart ネイティブ FFT
  fast_fourier_transform: ^1.0.0 # 代替案
```

#### UI・グラフ表示
```yaml
dependencies:
  fl_chart: ^0.65.0              # ✅ 既存（拡張）
  charts_flutter: ^0.14.0        # 詳細グラフ用
```

#### ユーティリティ
```yaml
dependencies:
  vector_math: ^2.1.0            # 数値計算
```

---

## 📐 アーキテクチャ設計

### 層構成

```
┌──────────────────────────────────────────┐
│ Presentation Layer (UI)                  │
├──────────────────────────────────────────┤
│ • FrequencyMeasureScreen (新規)           │
│ • SpectrogramWidget (新規)               │
│ • FrequencyChartWidget (新規)            │
│ • FrequencyDetailsCard (新規)            │
└──────────────┬───────────────────────────┘
               ↓
┌──────────────────────────────────────────┐
│ State Management (Riverpod)              │
├──────────────────────────────────────────┤
│ • frequencyProvider (StreamProvider)     │
│ • spectrogramDataProvider                │
│ • frequencyStatsProvider                 │
└──────────────┬───────────────────────────┘
               ↓
┌──────────────────────────────────────────┐
│ Service Layer (Business Logic)           │
├──────────────────────────────────────────┤
│ • FrequencyAnalysisService (新規)        │
│ • FFT Processor                          │
│ • Spectrogram Buffer Manager             │
└──────────────┬───────────────────────────┘
               ↓
┌──────────────────────────────────────────┐
│ Audio Layer (Audio Processing)           │
├──────────────────────────────────────────┤
│ • AudioService (拡張)                    │
│ • PCM Buffer Management                  │
│ • Audio Format Handler                   │
└──────────────┬───────────────────────────┘
               ↓
┌──────────────────────────────────────────┐
│ Platform Layer (Native)                  │
├──────────────────────────────────────────┤
│ • AVAudioEngine (iOS)                    │
│ • AudioRecord (Android)                  │
└──────────────────────────────────────────┘
```

---

## 📅 実装タイムライン（9-14日）

### Phase 1: 基盤構築（Day 1-2）

#### Task 1.1: パッケージ追加 & 環境構築
```bash
# pubspec.yaml に依存パッケージを追加
flutter pub add audio_waveforms fft vector_math charts_flutter

# 動作確認
flutter pub get
flutter pub run build_runner build
```

**所要時間**: 2 時間  
**成果物**: 
- pubspec.yaml 更新
- platform 固有設定（iOS/Android）

#### Task 1.2: AudioService 拡張（実マイク対応）
```dart
// lib/services/audio_service.dart 拡張

class AudioService {
  // 既存
  Timer? _updateTimer;
  bool _isRecording = false;
  double _currentDb = 0.0;
  
  // 新規（周波数測定）
  late audio_waveforms.AudioWaveformController _waveformController;
  List<double> _frequencyData = []; // FFT 結果
  List<double> _pcmBuffer = [];     // PCM サンプルバッファ
  
  // リアルタイムマイク入力開始
  Future<void> startFrequencyMeasurement({
    required Function(List<double>, List<double>, double) onFrequencyChange,
  }) async { ... }
}
```

**所要時間**: 4-6 時間  
**成果物**:
- AudioService.dart（マイク入力対応）
- PCM Buffer 管理クラス

### Phase 2: 周波数分析エンジン実装（Day 3-5）

#### Task 2.1: FFT Processor 実装
```dart
// lib/services/frequency_analysis_service.dart (新規)

class FrequencyAnalysisService {
  static const int sampleRate = 44100;
  static const int frameSize = 4096;
  
  // FFT 実行
  List<double> computeFFT(List<double> pcmSamples) {
    // Hanning Window を適用
    // FFT 計算
    // パワースペクトラム計算
    // dB 変換
    return frequencySpectrum;
  }
  
  // 周波数とパワーのマッピング
  Map<double, double> getFrequencyPowerMap(List<double> spectrum) {
    // 周波数 Hz → パワー dB のマップ
    return frequencyMap;
  }
  
  // ピーク周波数検出
  double getPeakFrequency(List<double> spectrum) {
    // 最大パワーの周波数を返す
    return peakFrequency;
  }
}
```

**所要時間**: 6-8 時間  
**成果物**:
- FrequencyAnalysisService.dart
- FFT 処理エンジン
- ユーティリティ関数

#### Task 2.2: Spectrogram Buffer 管理
```dart
// lib/services/spectrogram_buffer.dart (新規)

class SpectrogramBuffer {
  late List<List<double>> _buffer;  // 時系列スペクトラムデータ
  late int _maxLength;              // バッファサイズ
  
  // スペクトラムを追加
  void addSpectrum(List<double> spectrum) { ... }
  
  // 時系列データ取得
  List<List<double>> getTimeSeriesData() { ... }
  
  // リセット
  void clear() { ... }
}
```

**所要時間**: 3-4 時間  
**成果物**:
- SpectrogramBuffer.dart
- バッファ管理クラス

### Phase 3: Riverpod Provider 実装（Day 5-6）

#### Task 3.1: 周波数データ Provider
```dart
// lib/providers/frequency_provider.dart (新規)

final frequencyDataProvider = StreamProvider.autoDispose<FrequencyData>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  
  return Stream.periodic(
    Duration(milliseconds: 100),
    (count) {
      return FrequencyData(
        spectrum: audioService.getCurrentSpectrum(),
        peakFrequency: audioService.getPeakFrequency(),
        statistics: audioService.getFrequencyStats(),
      );
    },
  );
});

// モデル定義
class FrequencyData {
  final List<double> spectrum;      // 0-22050Hz スペクトラム
  final double peakFrequency;       // ピーク周波数
  final FrequencyStats statistics;  // 統計情報
}

class FrequencyStats {
  final double avgFrequency;
  final double maxPower;
  final double minPower;
  final List<double> topFrequencies; // トップ5周波数
}
```

**所要時間**: 3-4 時間  
**成果物**:
- frequency_provider.dart
- FrequencyData モデル
- FrequencyStats モデル

### Phase 4: UI コンポーネント実装（Day 7-10）

#### Task 4.1: Spectrogram グラフウィジェット
```dart
// lib/views/widgets/spectrogram_widget.dart (新規)

class SpectrogramWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frequencyData = ref.watch(frequencyDataProvider);
    
    return frequencyData.when(
      data: (data) => CustomPaint(
        painter: SpectrogramPainter(
          spectrum: data.spectrum,
          peakFrequency: data.peakFrequency,
        ),
        size: Size.infinite,
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

// カスタムペインター
class SpectrogramPainter extends CustomPainter {
  final List<double> spectrum;
  final double peakFrequency;
  
  @override
  void paint(Canvas canvas, Size size) {
    // 周波数スペクトラムを画面にペイント
    // 周波数軸（横）: 0-22050Hz
    // パワー軸（縦）: 0-120dB
    // カラーマップ: 青（低パワー）→ 赤（高パワー）
  }
}
```

**所要時間**: 4-5 時間  
**成果物**:
- SpectrogramWidget.dart
- SpectrogramPainter.dart

#### Task 4.2: 周波数チャートウィジェット
```dart
// lib/views/widgets/frequency_chart_widget.dart (新規)

class FrequencyChartWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frequencyData = ref.watch(frequencyDataProvider);
    
    return frequencyData.when(
      data: (data) => BarChart(
        BarChartData(
          barGroups: _buildBarGroups(data.spectrum),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // 周波数ラベル表示（100Hz単位）
                  final freq = (value * 22050 / 256).toInt();
                  return Text('${freq}Hz');
                },
              ),
            ),
          ),
        ),
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
  
  List<BarChartGroupData> _buildBarGroups(List<double> spectrum) {
    // スペクトラムデータをバーチャートに変換
    return spectrum
        .asMap()
        .entries
        .map((e) => BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(toY: e.value.clamp(0, 120)),
          ],
        ))
        .toList();
  }
}
```

**所要時間**: 4-5 時間  
**成果物**:
- FrequencyChartWidget.dart
- グラフ表示ロジック

#### Task 4.3: 周波数詳細表示カード
```dart
// lib/views/widgets/frequency_details_card.dart (新規)

class FrequencyDetailsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frequencyData = ref.watch(frequencyDataProvider);
    
    return frequencyData.when(
      data: (data) => Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ピーク周波数（デジタル表示）
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ピーク周波数:',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text('${data.peakFrequency.toStringAsFixed(1)} Hz',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              SizedBox(height: 12),
              
              // 統計情報
              _buildStatsRow(context, data.statistics),
            ],
          ),
        ),
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
  
  Widget _buildStatsRow(BuildContext context, FrequencyStats stats) {
    return Column(
      children: [
        _buildStatItem('平均周波数', '${stats.avgFrequency.toStringAsFixed(1)} Hz'),
        _buildStatItem('最大パワー', '${stats.maxPower.toStringAsFixed(1)} dB'),
        _buildStatItem('最小パワー', '${stats.minPower.toStringAsFixed(1)} dB'),
        
        // トップ5周波数
        Text('主要周波数:',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        ...stats.topFrequencies.map((freq) => 
          Text('  • ${freq.toStringAsFixed(1)} Hz')
        ).toList(),
      ],
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value),
      ],
    );
  }
}
```

**所要時間**: 3-4 時間  
**成果物**:
- FrequencyDetailsCard.dart
- デジタル表示コンポーネント

#### Task 4.4: 測定画面統合
```dart
// lib/views/screens/measure_screen.dart (拡張)

class MeasureScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,  // dB 測定 & 周波数測定
      child: Scaffold(
        appBar: AppBar(
          title: Text('測定'),
          bottom: TabBar(
            tabs: [
              Tab(text: '音量 (dB)'),
              Tab(text: '周波数'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: dB 測定（既存）
            _buildDBMeasurementTab(context, ref),
            
            // Tab 2: 周波数測定（新規）
            _buildFrequencyMeasurementTab(context, ref),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFrequencyMeasurementTab(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // スペクトラグラムグラフ
        Expanded(
          flex: 2,
          child: SpectrogramWidget(),
        ),
        
        // 周波数チャート
        Expanded(
          flex: 2,
          child: FrequencyChartWidget(),
        ),
        
        // 詳細情報
        Expanded(
          flex: 1,
          child: FrequencyDetailsCard(),
        ),
      ],
    );
  }
}
```

**所要時間**: 2-3 時間  
**成果物**:
- MeasureScreen.dart（拡張版）
- UI 統合

### Phase 5: テスト & 最適化（Day 11-14）

#### Task 5.1: ユニットテスト
```dart
// test/services/frequency_analysis_service_test.dart (新規)

void main() {
  group('FrequencyAnalysisService', () {
    late FrequencyAnalysisService service;
    
    setUp(() {
      service = FrequencyAnalysisService();
    });
    
    test('FFT 計算が正しい周波数スペクトラムを返す', () {
      // 1000Hz のサイン波を生成
      final pcmSamples = _generateSineWave(frequency: 1000, duration: 0.1);
      
      // FFT 計算
      final spectrum = service.computeFFT(pcmSamples);
      
      // ピーク周波数が 1000Hz ±5Hz 以内
      expect(spectrum.indexOf(spectrum.reduce(math.max)) * 44100 / 4096,
        closeTo(1000, 5));
    });
    
    test('ピーク周波数検出が正確', () { ... });
    test('周波数範囲が 0-22050Hz', () { ... });
  });
}
```

**所要時間**: 4-5 時間  
**成果物**:
- frequency_analysis_service_test.dart
- 10+ テストケース

#### Task 5.2: 実機テスト
```bash
# iOS
flutter run -d iPhone

# Android  
flutter run -d Android

# テスト項目
- [ ] マイク入力が正しく受け取られる
- [ ] FFT が正しく計算される
- [ ] グラフが正常に表示される
- [ ] デジタル表示が正確（±5Hz）
- [ ] CPU 使用率 < 30%
- [ ] メモリ < 100MB
- [ ] リアルタイム性（遅延 < 100ms）
```

**所要時間**: 6-8 時間  
**成果物**:
- テスト結果レポート
- パフォーマンス測定結果

#### Task 5.3: パフォーマンス最適化
```dart
// 最適化項目
- [ ] FFT 計算の高速化（ネイティブバインディング検討）
- [ ] バッファサイズの最適化
- [ ] メモリ使用量の削減
- [ ] フレームレート維持（60fps）
```

**所要時間**: 4-6 時間  
**成果物**:
- PERFORMANCE.md（周波数測定の最適化ガイド）

---

## 📊 実装タイムシート（詳細版）

| Day | Phase | Task | 時間 | 成果物 |
|-----|-------|------|------|--------|
| 1 | 1 | パッケージ追加 | 2h | pubspec.yaml |
| 1 | 1 | AudioService 拡張 | 4h | audio_service.dart |
| 2 | 2 | FFT Processor | 7h | frequency_analysis_service.dart |
| 3 | 2 | Spectrogram Buffer | 3h | spectrogram_buffer.dart |
| 4 | 3 | Provider 実装 | 4h | frequency_provider.dart |
| 5 | 4 | Spectrogram ウィジェット | 5h | spectrogram_widget.dart |
| 6 | 4 | チャートウィジェット | 5h | frequency_chart_widget.dart |
| 7 | 4 | 詳細カード & 画面統合 | 5h | frequency_details_card.dart |
| 8 | 5 | ユニットテスト | 5h | *_test.dart |
| 9-10 | 5 | 実機テスト & バグ修正 | 8h | テスト結果 |
| 11-14 | 5 | 最適化 & ドキュメント | 6h | PERFORMANCE.md |
| **合計** | | | **54h** | **12ファイル** |

**実装期間**: 9-14 営業日（並行作業可能）

---

## ✅ デリバリーチェックリスト

### コード
- [ ] AudioService.dart（マイク入力対応）
- [ ] FrequencyAnalysisService.dart（FFT 処理）
- [ ] SpectrogramBuffer.dart（バッファ管理）
- [ ] frequency_provider.dart（Riverpod）
- [ ] SpectrogramWidget.dart（グラフ表示）
- [ ] FrequencyChartWidget.dart（チャート表示）
- [ ] FrequencyDetailsCard.dart（デジタル表示）
- [ ] MeasureScreen.dart（画面統合）

### テスト
- [ ] ユニットテスト（FFT 精度）
- [ ] 実機テスト（iOS・Android）
- [ ] パフォーマンステスト

### ドキュメント
- [ ] 周波数測定ユーザーガイド
- [ ] PERFORMANCE.md 更新

### リリース準備
- [ ] v1.0.0 README 更新
- [ ] リリースノート作成
- [ ] スクリーンショット更新（周波数測定画面）

---

## 🚀 実装開始前のチェック

- [ ] パッケージの互換性確認（iOS・Android）
- [ ] マイク入力の許可設定確認（Info.plist/AndroidManifest）
- [ ] FFT ライブラリのベンチマーク実行
- [ ] UI/UX デザイン確認

---

## 📝 リスク管理

### High Risk
| リスク | 対策 |
|--------|------|
| FFT 計算が遅い | ネイティブバインディング検討 |
| メモリ不足 | バッファサイズ削減 |
| マイク入力が取得できない | フォールバック実装 |

### Medium Risk
| リスク | 対策 |
|--------|------|
| UI レスポンス低下 | 計算を別スレッド実行 |
| 周波数精度不足 | ウィンドウ関数改善 |

---

## 📞 承認事項

実装開始前に以下を確認してください：

- ✅ 周波数範囲: 全周波数（0-22050Hz）
- ✅ 精度: 中程度（±5Hz）
- ✅ 表示: グラフ＋デジタル表示の両方
- ✅ 実装時期: すぐ実装（v1.0.0）

---

**Status**: 実装計画完成  
**Next Step**: 実装開始  
**Estimated Completion**: 2026-08-20  

