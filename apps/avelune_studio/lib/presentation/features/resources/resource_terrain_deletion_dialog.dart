import 'package:flutter/material.dart';

import '../../../features/resources/application/resource_terrain_lifecycle_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'resource_management_dialog.dart';

class ResourceTerrainDeletionDialog extends StatefulWidget {
  const ResourceTerrainDeletionDialog({
    super.key,
    required this.name,
    required this.draft,
    required this.controller,
  });
  final String name;
  final bool draft;
  final ResourceTerrainLifecycleController controller;
  @override
  State<ResourceTerrainDeletionDialog> createState() =>
      _ResourceTerrainDeletionDialogState();
}

class _ResourceTerrainDeletionDialogState
    extends State<ResourceTerrainDeletionDialog> {
  ResourceTerrainLifecycleController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final preparing = _controller.prepareRemoval();
    setState(() {});
    await preparing;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => ResourceManagementDialog(
    title: widget.draft ? 'Supprimer le brouillon' : 'Supprimer le terrain',
    submitLabel: widget.draft
        ? 'Supprimer le brouillon'
        : 'Supprimer le terrain',
    dirty: () => false,
    valid: () => _controller.canApply,
    submit: _controller.apply,
    fields: (refresh, busy) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Text(
          widget.draft
              ? 'Cette préparation sera retirée ; sa publication reste disponible si elle existe. Les sources partagées sont conservées.'
              : 'Seul ce terrain est retiré. Les cartes, cases et sources partagées ne sont jamais supprimées pour libérer ses usages.',
        ),
        if (_controller.working) const LinearProgressIndicator(),
        if (_controller.error != null) ...[
          const SizedBox(height: 12),
          Text(
            'Retrait refusé : ${_controller.error}',
            key: const ValueKey('resource-terrain-refusal'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (_controller.preparation != null) ...[
          const SizedBox(height: 12),
          Text(
            '${_controller.preparation!.changedPaths.length} document(s) concernés.',
          ),
          SelectableText(
            'Révision : ${_controller.preparation!.snapshotRevision}',
          ),
        ],
        const SizedBox(height: 12),
        StudioButton(
          label: 'Réanalyser',
          secondary: true,
          onPressed: busy || _controller.working ? null : _prepare,
        ),
        CheckboxListTile(
          key: const ValueKey('resource-terrain-confirm'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Je confirme le retrait de cet objet.'),
          value: _controller.confirmed,
          onChanged: busy || _controller.working || !_controller.ready
              ? null
              : (value) {
                  _controller.confirm(value == true);
                  refresh();
                },
        ),
      ],
    ),
  );
}
