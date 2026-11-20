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
    this.cancelLabel = 'Annuler',
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.contentWidth = 600,
    this.confirmVariant = StudioButtonVariant.primary,
  });

  final String title;
  final Widget content;
  final String confirmLabel;
  final VoidCallback? onConfirmed;
  final VoidCallback onCancelled;
  final String cancelLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final double contentWidth;
  final StudioButtonVariant confirmVariant;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: SizedBox(
      width: contentWidth,
      child: SingleChildScrollView(child: content),
    ),
    actions: [
      StudioButton(label: cancelLabel, secondary: true, onPressed: onCancelled),
      if (secondaryActionLabel case final label?)
        StudioButton(
          label: label,
          secondary: true,
          onPressed: onSecondaryAction,
        ),
      StudioButton(
        key: const ValueKey('confirm-reviewed-plan'),
        label: confirmLabel,
        variant: confirmVariant,
        onPressed: onConfirmed,
      ),
    ],
  );
}
