import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../utils/error_messages.dart';

/// Shared error state for `AsyncValue.when(error: ...)` branches.
///
/// Shows a plain-language message (via [friendlyErrorMessage], never the
/// raw exception text) plus a retry action, instead of leaving the user on
/// a dead-end screen with `Text('エラー: $error')` and no way to recover
/// short of leaving and re-entering the screen.
class ErrorStateView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ErrorStateView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: dangerColor),
            const SizedBox(height: 16),
            Text(
              friendlyErrorMessage(error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }
}
