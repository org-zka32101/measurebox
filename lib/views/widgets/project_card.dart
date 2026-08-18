import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/project_model.dart';
import 'confirm_delete_dialog.dart';

class ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onTap;
  final Future<void> Function()? onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: greyLight, width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  color: primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 17,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(project.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert_rounded, color: textSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () => _handleDelete(context),
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 20, color: dangerColor),
                          SizedBox(width: 8),
                          Text('削除', style: TextStyle(color: dangerColor)),
                        ],
                      ),
                    ),
                  ],
                )
              else
                const Icon(Icons.chevron_right_rounded, color: textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    if (onDelete == null) return;
    final confirmed = await confirmDeleteProjectDialog(
      context,
      projectName: project.name,
    );
    if (confirmed) {
      await onDelete!();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
