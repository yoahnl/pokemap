import 'package:flutter/material.dart';

import '../buttons/studio_button.dart';

class StudioReviewDialog extends StatelessWidget {
  const StudioReviewDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.onConfirmed,
    required this.onCancelled,
  });

  final String title;
  final Widget content;
  final String confirmLabel;
  final VoidCallback? onConfirmed;
  final VoidCallback onCancelled;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: SizedBox(width: 600, child: SingleChildScrollView(child: content)),
    actions: [
      StudioButton(label: 'Annuler', secondary: true, onPressed: onCancelled),
      StudioButton(
        key: const ValueKey('confirm-reviewed-plan'),
        label: confirmLabel,
        onPressed: onConfirmed,
      ),
    ],
  );
}
