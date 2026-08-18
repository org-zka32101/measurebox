import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../constants/strings.dart';
import '../../constants/colors.dart';
import '../../providers/project_provider.dart';
import '../widgets/project_card.dart';
import '../widgets/new_project_dialog.dart';
import '../widgets/error_state_view.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String guestUserId = 'guest-user';

  void _showNewProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NewProjectDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.projects),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: AppStrings.settings,
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: primaryGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        size: 52,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'はじめましょう',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '最初のプロジェクトを作成して\n騒音を測定しましょう',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textSecondary,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showNewProjectDialog(context),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(AppStrings.newProject),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: projects.length + 1,
            itemBuilder: (context, index) {
              // Header with project count
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'プロジェクト',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${projects.length}個',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: textSecondary,
                                ),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: () => _showNewProjectDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('新規'),
                      ),
                    ],
                  ),
                );
              }
              final project = projects[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProjectCard(
                  project: project,
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      '/project_detail',
                      arguments: project.id,
                    );
                  },
                  onDelete: () async {
                    await ref.read(projectProvider.notifier).deleteProject(
                          userId: guestUserId,
                          projectId: project.id,
                        );
                    if (!context.mounted) return;
                    final result = ref.read(projectProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.hasError
                            ? '削除に失敗しました。もう一度お試しください。'
                            : 'プロジェクトを削除しました'),
                        backgroundColor: result.hasError ? dangerColor : null,
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(projectsStreamProvider),
        ),
      ),
      floatingActionButton: projectsAsync.maybeWhen(
        data: (projects) => projects.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _showNewProjectDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(AppStrings.newProject),
              ),
        orElse: () => null,
      ),
    );
  }
}
