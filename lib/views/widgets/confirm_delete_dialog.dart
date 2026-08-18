import 'package:flutter/material.dart';
import '../../constants/colors.dart';

/// Shared "delete this project?" confirmation dialog.
///
/// Previously hand-duplicated (with subtly different post-confirm
/// behavior) in both [ProjectCard] and `ProjectDetailScreen`, so a future
/// copy or flow change had to be made in two places and could drift.
///
/// Returns `true` only if the user tapped 削除. This dialog only asks for
/// confirmation — callers are responsible for actually performing the
/// delete (awaiting it) and reporting success/failure themselves.
Future<bool> confirmDeleteProjectDialog(
  BuildContext context, {
  required String projectName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('プロジェクトを削除しますか？'),
      content: Text(
        '「$projectName」と関連するすべてのデータが削除されます。\nこの操作は取り消せません。',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: dangerColor),
          child: const Text('削除'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
