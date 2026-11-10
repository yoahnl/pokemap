import '../../../features/resources/application/resource_terrain_lifecycle_controller.dart';

import 'package:flutter/material.dart';

import 'resource_management_dialog.dart';

class ResourceTerrainManagementDialog extends StatefulWidget {
  const ResourceTerrainManagementDialog({
    super.key,
    required this.title,
    required this.controller,
    required this.description,
  });
  final String title, description;
  final ResourceTerrainLifecycleController controller;
  @override
  State<ResourceTerrainManagementDialog> createState() =>
      _ResourceTerrainManagementDialogState();
}

class _ResourceTerrainManagementDialogState
    extends State<ResourceTerrainManagementDialog> {
  late final _name = TextEditingController(text: widget.controller.name);
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ResourceManagementDialog(
    title: widget.title,
    submitLabel: widget.controller.duplicate
        ? 'Créer la préparation'
        : 'Enregistrer',
    dirty: () => widget.controller.dirty,
    valid: () => widget.controller.canApply,
    submit: widget.controller.apply,
    fields: (refresh, busy) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.description),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('resource-terrain-name'),
          decoration: const InputDecoration(
            labelText: 'Nom du terrain ou chemin',
          ),
          controller: _name,
          enabled: !busy,
          onChanged: (value) {
            widget.controller.name = value;
            refresh();
          },
        ),
      ],
    ),
  );
}
