import 'package:flutter/material.dart';
import 'resource_management_dialog.dart';

class ResourceTerrainManagementDialog extends StatefulWidget {
  const ResourceTerrainManagementDialog({
    super.key,
    required this.title,
    required this.name,
    required this.description,
    required this.submit,
    required this.canApply,
    this.duplicate = false,
  });
  final String title, name, description;
  final bool duplicate;
  final Future<String?> Function(String name) submit;
  final bool Function() canApply;
  @override
  State<ResourceTerrainManagementDialog> createState() =>
      _ResourceTerrainManagementDialogState();
}

class _ResourceTerrainManagementDialogState
    extends State<ResourceTerrainManagementDialog> {
  late final _name = TextEditingController(text: widget.name);
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ResourceManagementDialog(
    title: widget.title,
    submitLabel: widget.duplicate ? 'Créer la préparation' : 'Enregistrer',
    dirty: () => _name.text != widget.name,
    valid: () => _name.text.trim().isNotEmpty && widget.canApply(),
    submit: () => widget.submit(_name.text),
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
          onChanged: (_) => refresh(),
        ),
      ],
    ),
  );
}
