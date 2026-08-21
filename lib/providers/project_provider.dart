import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/project_model.dart';
import '../services/firebase_service.dart';
import '../services/guest_auth_service.dart';
import '../services/hive_service.dart';

final projectServiceProvider = Provider((ref) => FirebaseService());

final projectsStreamProvider = StreamProvider<List<ProjectModel>>((ref) {
  final firebaseService = ref.watch(projectServiceProvider);

  // ゲストモード：匿名認証のuidで直接アクセス（GuestAuthServiceの
  // ドキュメント参照）。起動時のサインインに失敗している場合は
  // （オフライン等）同期を諦め、空リストを返す。
  final guestUserId = GuestAuthService.currentUserId;
  if (guestUserId == null) return Stream.value(const []);
  return firebaseService.streamProjects(guestUserId);
});

class ProjectNotifier extends StateNotifier<AsyncValue<void>> {
  ProjectNotifier(this._firebaseService) : super(const AsyncValue.data(null));

  final FirebaseService _firebaseService;

  Future<ProjectModel> createProject({
    required String userId,
    required String name,
    String? description,
  }) async {
    state = const AsyncValue.loading();

    late final ProjectModel project;
    final result = await AsyncValue.guard(() async {
      final projectId = const Uuid().v4();
      final now = DateTime.now();

      project = ProjectModel(
        id: projectId,
        userId: userId,
        name: name,
        description: description,
        createdAt: now,
        updatedAt: now,
      );

      // Save to Firebase
      await _firebaseService.saveProject(project, userId);

      // Cache locally
      final projectsBox = HiveService.getProjectsBox();
      final projects = projectsBox.values.toList();
      projects.add(project);
      await projectsBox.clear();
      for (int i = 0; i < projects.length; i++) {
        await projectsBox.putAt(i, projects[i]);
      }
    });

    state = result.hasError
        ? AsyncValue.error(result.error!, result.stackTrace!)
        : const AsyncValue.data(null);

    if (result.hasError) {
      // ignore: only_throw_errors
      throw result.error!;
    }
    return project;
  }

  Future<void> deleteProject({
    required String userId,
    required String projectId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _firebaseService.deleteProject(userId, projectId);

      // Remove from local cache
      final projectsBox = HiveService.getProjectsBox();
      projectsBox.delete(projectId);
    }).then((_) => const AsyncValue.data(null));
  }

  Future<void> updateProject({
    required String userId,
    required ProjectModel project,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updated = project.copyWith(updatedAt: DateTime.now());
      await _firebaseService.saveProject(updated, userId);

      // Update local cache
      final projectsBox = HiveService.getProjectsBox();
      projectsBox.put(project.id, updated);
    }).then((_) => const AsyncValue.data(null));
  }
}

final projectProvider = StateNotifierProvider<ProjectNotifier, AsyncValue<void>>(
  (ref) => ProjectNotifier(
    ref.watch(projectServiceProvider),
  ),
);

// Provider for a single project (cached)
final projectByIdProvider =
    FutureProvider.family<ProjectModel?, String>((ref, projectId) async {
  final projects = await ref.watch(projectsStreamProvider.future);
  try {
    return projects.firstWhere((p) => p.id == projectId);
  } catch (e) {
    return null;
  }
});
