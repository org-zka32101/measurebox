/// Maps a raised error/exception into a short, plain-language Japanese
/// message that's safe to show end users.
///
/// Screens across the app used to do `Text('エラー: $error')` /
/// `Text('エラー: $e')` directly, which dumps the raw Dart/Firebase
/// exception `toString()` on guest users — e.g.
/// `[cloud_firestore/permission-denied] Missing or insufficient
/// permissions.` — with no plain-language explanation or next step.
String friendlyErrorMessage(Object error) {
  final raw = error.toString();

  if (raw.contains('permission-denied')) {
    return 'アクセスが拒否されました。しばらくしてからもう一度お試しください。';
  }
  if (raw.contains('unavailable') ||
      raw.contains('network') ||
      raw.contains('SocketException') ||
      raw.contains('TimeoutException')) {
    return 'ネットワークに接続できません。通信環境をご確認のうえ、もう一度お試しください。';
  }
  if (raw.contains('not-found')) {
    return 'データが見つかりませんでした。';
  }

  return '問題が発生しました。もう一度お試しください。';
}
