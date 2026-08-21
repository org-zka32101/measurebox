import 'package:firebase_auth/firebase_auth.dart';

/// ゲストモード用の匿名認証ラッパー。
///
/// このアプリはログイン画面を持たず、全ユーザーが「ゲストモード」で
/// 使う。かつては 'guest-user' という固定文字列をFirestoreの
/// ユーザーIDとして全インストール共通で使っていたが、これだと
/// Firestoreのセキュリティルールで正当な持ち主を判別できず、
/// 実質的に「認証なしの共有パス」を公開してしまう
/// （Firebase設定さえ知っていれば誰でも全ユーザーのデータを
/// 読み書きできてしまう）。
///
/// そこで起動時に一度だけFirebase匿名認証でサインインし、実際の
/// Firebase Auth uid をユーザーIDとして使う。これによりインストール
/// ごとに一意なuidが払い出され、firestore.rules 側で
/// `request.auth.uid == userId` を要求するだけで、ログイン画面を
/// 追加することなくユーザーごとのデータ分離を実現できる。
class GuestAuthService {
  GuestAuthService._();

  static String? _cachedUid;

  /// アプリ起動時（main()）に一度だけ呼び出す。
  /// 既にサインイン済みならそれを再利用し、未サインインなら匿名認証で
  /// サインインする。オフライン等で失敗しても致命的にはせず、
  /// currentUserId は null のままになる（Firestore同期は失敗するが、
  /// Hiveのローカルキャッシュでの閲覧は引き続き可能）。
  static Future<String?> ensureSignedIn() async {
    try {
      final auth = FirebaseAuth.instance;
      var user = auth.currentUser;
      user ??= (await auth.signInAnonymously()).user;
      _cachedUid = user?.uid;
    } catch (e) {
      _cachedUid = null;
    }
    return _cachedUid;
  }

  /// サインイン済みFirebase Auth uid。ensureSignedIn() が成功していれば
  /// 非null。失敗している場合やensureSignedIn()未実行の場合はnull。
  static String? get currentUserId =>
      _cachedUid ?? FirebaseAuth.instance.currentUser?.uid;
}
