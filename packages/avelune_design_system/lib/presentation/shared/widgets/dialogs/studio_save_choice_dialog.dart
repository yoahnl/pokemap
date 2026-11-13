import 'package:flutter/material.dart';

import '../buttons/studio_button.dart';

enum StudioSaveChoice { save, discard, cancel }

Future<StudioSaveChoice> showStudioSaveChoiceDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String saveLabel,
  required String discardLabel,
  required String cancelLabel,
}) async =>
    await showDialog<StudioSaveChoice>(
      context: context,
      builder: (_) => StudioSaveChoiceDialog(
        title: title,
        message: message,
        saveLabel: saveLabel,
        discardLabel: discardLabel,
        cancelLabel: cancelLabel,
      ),
    ) ??
    StudioSaveChoice.cancel;

class StudioSaveChoiceDialog extends StatelessWidget {
  const StudioSaveChoiceDialog({
    super.key,
    required this.title,
    required this.message,
    required this.saveLabel,
    required this.discardLabel,
    required this.cancelLabel,
  });

  final String title;
  final String message;
  final String saveLabel;
  final String discardLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    void choose(StudioSaveChoice choice) => Navigator.of(context).pop(choice);
    return AlertDialog(
      key: const ValueKey('studio-save-choice'),
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Text(message),
      ),
      actions: [
        StudioButton(
          key: const ValueKey('studio-save-choice-discard'),
          label: discardLabel,
          variant: StudioButtonVariant.destructive,
          onPressed: () => choose(StudioSaveChoice.discard),
        ),
        StudioButton(
          key: const ValueKey('studio-save-choice-cancel'),
          label: cancelLabel,
          variant: StudioButtonVariant.secondary,
          onPressed: () => choose(StudioSaveChoice.cancel),
        ),
        StudioButton(
          key: const ValueKey('studio-save-choice-save'),
          label: saveLabel,
          variant: StudioButtonVariant.primary,
          onPressed: () => choose(StudioSaveChoice.save),
        ),
      ],
    );
  }
}
