import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

final currentUserStreamProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final cachedUserProvider = Provider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final currentUser = authService.currentUser;

  if (currentUser == null) {
    return null;
  }

  return authService.getCachedUser(currentUser.uid);
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._authService) : super(const AsyncValue.data(null));

  final AuthService _authService;

  Future<void> signup({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.signup(
          email: email,
          password: password,
          displayName: displayName,
        )).then((_) => const AsyncValue.data(null));
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.login(
          email: email,
          password: password,
        )).then((_) => const AsyncValue.data(null));
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.logout())
        .then((_) => const AsyncValue.data(null));
  }

  Future<void> updateDisplayName(String displayName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.updateDisplayName(displayName))
        .then((_) => const AsyncValue.data(null));
  }

  Future<void> updateCalibration(double calibration) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.updateCalibration(calibration))
        .then((_) => const AsyncValue.data(null));
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (ref) => AuthNotifier(ref.watch(authServiceProvider)),
);
