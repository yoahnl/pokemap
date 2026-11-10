import 'package:flutter/material.dart';

import '../../../features/resources/application/resource_border_lifecycle_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'resource_management_dialog.dart';

class ResourceBorderConfirmationDialog extends StatefulWidget {
  const ResourceBorderConfirmationDialog({
    super.key,
    required this.name,
    required this.title,
    required this.description,
    required this.controller,
  });
  final String name;
  final String title, description;
  final ResourceBorderLifecycleController controller;
  @override
  State<ResourceBorderConfirmationDialog> createState() =>
      _ResourceBorderConfirmationDialogState();
}

class _ResourceBorderConfirmationDialogState
    extends State<ResourceBorderConfirmationDialog> {
  ResourceBorderLifecycleController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    final pending = controller.prepare();
    setState(() {});
    await pending;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => ResourceManagementDialog(
    title: widget.title,
    submitLabel: widget.title,
    dirty: () => false,
    valid: () => controller.canApply,
    submit: controller.apply,
    fields: (refresh, busy) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Text(widget.description),
        if (controller.working) const LinearProgressIndicator(),
        if (controller.error != null) ...[
          const SizedBox(height: 12),
          Text(
            'Opération refusée : ${controller.error}',
            key: const ValueKey('resource-border-refusal'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (controller.preparation != null) ...[
          const SizedBox(height: 12),
          Text(
            '${controller.preparation!.changedPaths.length} document(s) concernés.',
          ),
          SelectableText(
            'Révision : ${controller.preparation!.snapshotRevision}',
          ),
        ],
        const SizedBox(height: 12),
        StudioButton(
          label: 'Réanalyser',
          secondary: true,
          onPressed: busy || controller.working ? null : _prepare,
        ),
        CheckboxListTile(
          key: const ValueKey('resource-border-confirm'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Je confirme cette opération sur la bordure.'),
          value: controller.confirmed,
          onChanged:
              busy || controller.working || controller.preparation == null
              ? null
              : (value) {
                  controller.confirm(value == true);
                  refresh();
                },
        ),
      ],
    ),
  );
}
