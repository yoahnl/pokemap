import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/trigger_editing_commands.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';

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
  TriggerEditingCommands get _commands =>
      TriggerEditingCommands(widget.document, widget.project);

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
    final owner = '${widget.document.current.id}/${trigger.id}';
    final blocked = _commands.deletionProblem(trigger.id);
    final area = trigger.area;
    final mapId = widget.document.current.id;
    final events = [
      for (final record
          in widget.project.eventRegistry?.records ?? <NarrativeEventRecord>[])
        if (_triggerSource(record, mapId, trigger.id) case final moment?)
          (
            name:
                record.definitionOrNull?.name ??
                record.draftOrNull?.name ??
                record.id,
            when: moment,
          ),
    ];
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
        StudioCommitField(
          key: ValueKey('trigger-name-$owner'),
          label: 'Nom',
          value: trigger.name,
          onCommit: (value) =>
              _change(() => _commands.rename(trigger.id, value)),
        ),
        const SizedBox(height: 12),
        Column(
          key: const ValueKey('trigger-events'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Événements déclenchés',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (events.isEmpty)
              const Text('Aucun événement ne se déclenche dans cette zone.')
            else
              for (final event in events)
                Text('« ${event.name} » · ${event.when}'),
          ],
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

String? _triggerSource(NarrativeEventRecord record, String mapId, String id) {
  final source = record.definitionOrNull?.source ?? record.draftOrNull?.source;
  return source?.when(
    entityAutorun: (_, _) => null,
    entityBump: (_, _) => null,
    entityInteract: (_, _) => null,
    modelInteract: (_, _) => null,
    triggerBump: (map, trigger) =>
        map == mapId && trigger == id ? 'en touchant la zone' : null,
    triggerEnter: (map, trigger) =>
        map == mapId && trigger == id ? 'en entrant dans la zone' : null,
    mapEnter: (_) => null,
    outcomeReceived: (_) => null,
  );
}
