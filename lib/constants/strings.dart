class AppStrings {
  // App name
  static const String appName = 'MeasureTracker';
  static const String appSubtitle = '騒音を測定・改善する';

  // Common
  static const String ok = 'OK';
  static const String cancel = 'キャンセル';
  static const String save = '保存';
  static const String delete = '削除';
  static const String close = '閉じる';
  static const String back = '戻る';
  static const String next = '次へ';
  static const String skip = 'スキップ';

  // Auth
  static const String login = 'ログイン';
  static const String signup = 'サインアップ';
  static const String logout = 'ログアウト';
  static const String email = 'メールアドレス';
  static const String password = 'パスワード';
  static const String passwordConfirm = 'パスワード（確認）';
  static const String forgotPassword = 'パスワードをお忘れですか？';
  static const String noAccount = 'アカウントをお持ちではありませんか？';
  static const String haveAccount = 'すでにアカウントをお持ちですか？';
  static const String signupHere = 'こちらからサインアップ';
  static const String loginHere = 'こちらからログイン';

  // Home
  static const String projects = 'プロジェクト';
  static const String newProject = '新規プロジェクト';
  static const String projectName = 'プロジェクト名';
  static const String projectDescription = '説明（オプション）';
  static const String noProjects = 'プロジェクトがありません';

  // Measure
  static const String measure = '測定';
  static const String measuring = '測定中...';
  static const String startMeasure = '測定開始';
  static const String stopMeasure = '測定停止';
  static const String decibel = 'dB';
  static const String min = '最小';
  static const String avg = '平均';
  static const String max = '最大';
  static const String duration = '測定時間';

  // Before/After
  static const String before = '対策前';
  static const String after = '対策後';
  static const String comparison = 'Before/After比較';
  static const String improvement = '改善';
  static const String improvementRate = '改善率';
  static const String retakeMeasure = '再測定';
  static const String newMeasure = '新規測定';
  static const String saveComparison = '比較を保存';
  static const String shareComparison = 'SNSで共有';

  // Logs
  static const String logs = 'ログ';
  static const String noLogs = 'ログがありません';
  static const String exportCSV = 'CSV出力';
  static const String memo = 'メモ';

  // Settings
  static const String settings = '設定';
  static const String account = 'アカウント';
  static const String data = 'データ';
  static const String calibration = 'マイク校正';
  static const String deleteAccount = 'アカウント削除';
  static const String aboutApp = 'このアプリについて';
  static const String privacyPolicy = 'プライバシーポリシー';
  static const String termsOfService = '利用規約';

  // Permissions
  static const String micPermissionRequired = 'マイク権限が必要です';
  static const String micPermissionDescription = '騒音を測定するためにマイクを使用します';
  static const String storagePermissionRequired = 'ストレージ権限が必要です';
  static const String permissionDenied = '権限がありません。設定から許可してください。';

  // Status
  static const String safe = '安全';
  static const String warning = '注意';
  static const String danger = '危険';

  // Help / 説明
  static const String measureHint = 'スマホのマイクを音源に向けて「測定開始」を押してください';
  static const String measureGuideTitle = '騒音レベルの目安';
  static const String guideSafe = '40〜60dB：会話・静かなオフィス';
  static const String guideWarning = '70〜85dB：交通量の多い道路・掃除機';
  static const String guideDanger = '85dB以上：長時間は要注意・耳に負担';
  static const String comparisonHint = '対策前と対策後の測定を選ぶと、改善量が自動で表示されます';
  static const String logsHint = '測定するとここに履歴が記録されます';
  static const String howToTitle = '使い方';
  static const String tapToStart = 'タップして測定開始';

  // Errors
  static const String errorTitle = 'エラー';
  static const String errorGeneric = 'エラーが発生しました';
  static const String errorNetwork = 'ネットワークエラー';
  static const String errorAuth = '認証エラー';
  static const String tryAgain = 'もう一度試す';

  // Loading
  static const String loading = '読み込み中...';
  static const String saving = '保存中...';
}
