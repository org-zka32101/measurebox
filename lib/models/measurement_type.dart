enum MeasurementType {
  single,  // 単発測定
  before,  // 対策前
  after;   // 対策後

  String get label {
    switch (this) {
      case MeasurementType.single:
        return '単発';
      case MeasurementType.before:
        return '対策前';
      case MeasurementType.after:
        return '対策後';
    }
  }
}
