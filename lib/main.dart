import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'firebase_options.dart';
import 'constants/theme.dart';
import 'constants/strings.dart';
import 'services/hive_service.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/signup_screen.dart';
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
          final projectId = settings.arguments as String;
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
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Auth state is handled by MyApp's Consumer widget
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.appSubtitle,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
