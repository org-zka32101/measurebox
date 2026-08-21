import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'firebase_options.dart';
import 'constants/theme.dart';
import 'constants/strings.dart';
import 'services/guest_auth_service.dart';
import 'services/hive_service.dart';
import 'views/screens/home_screen.dart';
import 'views/screens/project_detail_screen.dart';
import 'views/screens/settings_screen.dart';
import 'views/screens/logs_screen.dart';
import 'views/screens/measure_screen.dart';
import 'views/screens/comparison_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive first
    await HiveService.initBoxes();
  } catch (e) {
    print('Hive initialization error: $e');
  }

  try {
    // Initialize Firebase (blocking)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // ゲストモード用の匿名認証（GuestAuthServiceのドキュメント参照）。
    // Firestoreのセキュリティルールでユーザーごとにデータを分離するため、
    // ログイン画面を追加せずここで一度だけサインインする。
    final uid = await GuestAuthService.ensureSignedIn();
    print('匿名認証 完了: uid=$uid');
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ゲストモード：ログイン画面をスキップしてホーム画面へ直接遷移
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == '/project_detail') {
          final projectId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(projectId: projectId),
          );
        }
        if (settings.name == '/logs') {
          final projectId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => LogsScreen(projectId: projectId),
          );
        }
        if (settings.name == '/measure') {
          // 引数なし（ホーム画面から直接）の場合はプロジェクト未指定のまま
          // 測定を開始し、保存時にプロジェクトを選択/新規作成してもらう。
          final projectId = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (_) => MeasureScreen(projectId: projectId),
          );
        }
        if (settings.name == '/comparison') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ComparisonScreen(
              projectId: args['projectId'] as String,
              initialBeforeMeasurementId: args['beforeId'] as String?,
            ),
          );
        }
        return null;
      },
      routes: {
        '/home': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
