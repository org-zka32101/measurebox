import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../constants/strings.dart';
import '../../constants/colors.dart';
import '../../models/project_model.dart';
import '../../providers/project_provider.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/error_state_view.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectByIdProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロジェクト詳細'),
      ),
      body: projectAsync.when(
        data: (project) {
          if (project == null) {
            return const Center(
              child: Text('プロジェクトが見つかりません'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ヘッダーカード
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.folder_rounded,
                        color: Colors.white70, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      project.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.white),
                    ),
                    if (project.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        project.description!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 統計情報カード
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '作成日',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${project.createdAt.year}年${project.createdAt.month}月${project.createdAt.day}日',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _actionTile(
                context,
                icon: Icons.mic_rounded,
                color: primaryColor,
                title: AppStrings.startMeasure,
                subtitle: '騒音レベルを測定します',
                onTap: () => Navigator.of(context)
                    .pushNamed('/measure', arguments: project.id),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                icon: Icons.compare_arrows_rounded,
                color: safeColor,
                title: AppStrings.comparison,
                subtitle: '対策前後を比べます',
                onTap: () => Navigator.of(context).pushNamed(
                  '/comparison',
                  arguments: {'projectId': project.id},
                ),
              ),
              const SizedBox(height: 12),
              _actionTile(
                context,
                icon: Icons.history_rounded,
                color: warningColor,
                title: AppStrings.logs,
                subtitle: '測定履歴を確認します',
                onTap: () => Navigator.of(context)
                    .pushNamed('/logs', arguments: project.id),
              ),
              const SizedBox(height: 24),
              _actionTile(
                context,
                icon: Icons.delete_outline_rounded,
                color: dangerColor,
                title: 'プロジェクトを削除',
                subtitle: '関連データすべて削除されます',
                onTap: () => _handleDeleteProject(context, ref, project),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => ErrorStateView(
          error: error,
          onRetry: () => ref.invalidate(projectByIdProvider(projectId)),
        ),
      ),
    );
  }

  Future<void> _handleDeleteProject(
    BuildContext context,
    WidgetRef ref,
    ProjectModel project,
  ) async {
    final confirmed = await confirmDeleteProjectDialog(
      context,
      projectName: project.name,
    );
    if (!confirmed) return;

    // 削除完了を待ってから成否をフィードバックする。以前は確認ダイアログを
    // 閉じた瞬間に削除を投げっぱなしで即座にHomeへ戻っていたため、
    // 削除がFirestore側で失敗しても画面外で握りつぶされていた。
    await ref.read(projectProvider.notifier).deleteProject(
          userId: 'guest-user',
          projectId: project.id,
        );
    if (!context.mounted) return;

    final result = ref.read(projectProvider);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('削除に失敗しました。もう一度お試しください。'),
          backgroundColor: dangerColor,
        ),
      );
      return; // 失敗時は画面に留まり、再試行できるようにする
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('プロジェクトを削除しました')),
    );
    Navigator.of(context).pop();
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: greyLight, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
