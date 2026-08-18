/// What physical quantity a [MeasurementModel] represents.
///
/// This is orthogonal to [MeasurementType] (single/before/after): category
/// answers "what did we measure" (sound level, vibration, ...), while type
/// answers "why was it recorded" (a one-off reading vs. a before/after
/// mitigation comparison).
///
/// [sound] is index 0 so that measurements recorded before this field
/// existed (no `category` key in Firestore) decode as sound — matching
/// what every measurement in this app actually was until vibration
/// measurement was added.
enum MeasurementCategory {
  sound, // 騒音（dB）
  vibration; // 振動

  String get label {
    switch (this) {
      case MeasurementCategory.sound:
        return '騒音';
      case MeasurementCategory.vibration:
        return '振動';
    }
  }
}
