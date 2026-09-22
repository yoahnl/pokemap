import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/trigger_editing_commands.dart';
import '../../shared/widgets/buttons/studio_tool.dart';

class MapTriggerInspector extends StatefulWidget {
  const MapTriggerInspector({
    super.key,
    required this.document,
    required this.project,
    required this.trigger,
    required this.onChanged,
    required this.onDeleted,
    this.onOpenInteraction,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapTrigger trigger;
  final VoidCallback onChanged;
  final VoidCallback onDeleted;
  final VoidCallback? onOpenInteraction;

  @override
  State<MapTriggerInspector> createState() => _MapTriggerInspectorState();
}

class _MapTriggerInspectorState extends State<MapTriggerInspector> {
  final _name = TextEditingController();
  String? _appliedTo;

  TriggerEditingCommands get _commands =>
      TriggerEditingCommands(widget.document, widget.project);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _change(VoidCallback action) {
    try {
      action();
    } catch (error) {
      widget.document.error = error is StateError
          ? error.message
          : error.toString();
    }
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final trigger = widget.trigger;
    if (_appliedTo != trigger.id) {
      _appliedTo = trigger.id;
      _name.text = trigger.name;
    }
    final blocked = _commands.deletionProblem(trigger.id);
    final area = trigger.area;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Zone d’histoire', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          '${area.size.width} × ${area.size.height} cases '
          'depuis ${area.pos.x}, ${area.pos.y}',
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('trigger-name'),
          controller: _name,
          decoration: const InputDecoration(labelText: 'Nom'),
          onSubmitted: (value) =>
              _change(() => _commands.rename(trigger.id, value)),
          onTapOutside: (_) {
            if (_name.text != trigger.name) {
              _change(() => _commands.rename(trigger.id, _name.text));
            }
            FocusManager.instance.primaryFocus?.unfocus();
          },
        ),
        const SizedBox(height: 12),
        Text(
          blocked ?? 'Aucune interaction n’est liée à cette zone.',
          key: const ValueKey('trigger-usage'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            if (widget.onOpenInteraction != null)
              StudioTool(
                label: 'Ouvrir son interaction',
                icon: Icons.open_in_new,
                onPressed: widget.onOpenInteraction,
              ),
            StudioTool(
              label: blocked == null
                  ? 'Supprimer la zone'
                  : 'Suppression bloquée par l’histoire',
              icon: Icons.delete_outline,
              onPressed: blocked != null
                  ? null
                  : () {
                      _change(() => _commands.delete(trigger.id));
                      widget.onDeleted();
                    },
            ),
          ],
        ),
      ],
    );
  }
}
