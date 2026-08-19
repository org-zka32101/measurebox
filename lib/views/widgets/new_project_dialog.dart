import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../constants/strings.dart';
import '../../providers/project_provider.dart';

class NewProjectDialog extends ConsumerStatefulWidget {
  const NewProjectDialog({super.key});

  @override
  ConsumerState<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends ConsumerState<NewProjectDialog> {
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 200;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;
  bool _showNameError = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _nameController.addListener(() {
      if (_showNameError && _nameController.text.isNotEmpty) {
        setState(() => _showNameError = false);
      }
      setState(() {});
    });
    _descriptionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleCreate(WidgetRef ref) async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      setState(() => _showNameError = true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      const guestUserId = 'guest-user';

      final project = await ref.read(projectProvider.notifier).createProject(
            userId: guestUserId,
            name: name,
            description: description.isEmpty ? null : description,
          );

      if (mounted) {
        Navigator.of(context).pop(project);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.newProject),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              enabled: !_isLoading,
              maxLength: maxNameLength,
              decoration: InputDecoration(
                hintText: AppStrings.projectName,
                labelText: AppStrings.projectName,
                errorText: _showNameError ? 'プロジェクト名を入力してください' : null,
                counterText: '${_nameController.text.length}/$maxNameLength',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              enabled: !_isLoading,
              maxLines: 3,
              maxLength: maxDescriptionLength,
              decoration: InputDecoration(
                hintText: AppStrings.projectDescription,
                labelText: AppStrings.projectDescription,
                counterText: '${_descriptionController.text.length}/$maxDescriptionLength',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _handleCreate(ref),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppStrings.save),
        ),
      ],
    );
  }
}
