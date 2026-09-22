import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/warp_editing_commands.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';

class MapWarpInspector extends StatefulWidget {
  const MapWarpInspector({
    super.key,
    required this.document,
    required this.project,
    required this.warp,
    required this.onChanged,
    required this.onDeleted,
    this.onOpenDestination,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWarp warp;
  final VoidCallback onChanged;
  final VoidCallback onDeleted;
  final ValueChanged<String>? onOpenDestination;

  @override
  State<MapWarpInspector> createState() => _MapWarpInspectorState();
}

class _MapWarpInspectorState extends State<MapWarpInspector> {
  WarpEditingCommands get _commands =>
      WarpEditingCommands(widget.document, widget.project);

  bool _commitTarget(String raw, {required bool horizontal}) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed < 0) {
      widget.document.error =
          'La case d’arrivée doit être exprimée en nombres positifs.';
      widget.onChanged();
      return false;
    }
    final current = widget.warp.targetPos;
    if (horizontal ? parsed == current.x : parsed == current.y) return true;
    _change(
      () => _commands.retarget(
        widget.warp.id,
        targetPos: horizontal
            ? GridPos(x: parsed, y: current.y)
            : GridPos(x: current.x, y: parsed),
      ),
    );
    return true;
  }

  void _change(VoidCallback action) {
    try {
      action();
    } catch (error) {
      widget.document.error = error.toString();
    }
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final warp = widget.warp;
    final owner = '${widget.document.current.id}/${warp.id}';
    final destinations = _commands.destinations();
    final problem = _commands.destinationProblem(warp);
    final known = destinations.any((entry) => entry.id == warp.targetMapId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Passage', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'Départ : ${widget.document.current.name} · ${warp.pos.x}, ${warp.pos.y}',
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('warp-destination-${warp.id}'),
          initialValue: known ? warp.targetMapId : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Carte d’arrivée'),
          items: [
            for (final entry in destinations)
              DropdownMenuItem(value: entry.id, child: Text(entry.name)),
          ],
          onChanged: (id) => id == null
              ? null
              : _change(() => _commands.retarget(warp.id, targetMapId: id)),
        ),
        if (problem != null) ...[
          const SizedBox(height: 6),
          Text(
            problem,
            key: const ValueKey('warp-destination-problem'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StudioCommitField(
                key: ValueKey('warp-target-x-$owner'),
                label: 'Case X',
                value: '${warp.targetPos.x}',
                tryCommit: (raw) => _commitTarget(raw, horizontal: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StudioCommitField(
                key: ValueKey('warp-target-y-$owner'),
                label: 'Case Y',
                value: '${warp.targetPos.y}',
                tryCommit: (raw) => _commitTarget(raw, horizontal: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'La case d’arrivée est vérifiée à l’ouverture de la carte de destination.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<MapWarpTriggerMode>(
          key: ValueKey('warp-mode-${warp.id}-${warp.triggerMode.name}'),
          initialValue: warp.triggerMode,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Déclenchement'),
          items: const [
            DropdownMenuItem(
              value: MapWarpTriggerMode.onEnter,
              child: Text(
                'À l’entrée',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: MapWarpTriggerMode.onBump,
              child: Text(
                'Au contact',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          onChanged: (mode) => mode == null
              ? null
              : _change(() => _commands.retarget(warp.id, triggerMode: mode)),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            if (widget.onOpenDestination != null && known)
              StudioTool(
                label: 'Ouvrir la carte d’arrivée',
                icon: Icons.open_in_new,
                onPressed: () => widget.onOpenDestination!(warp.targetMapId),
              ),
            StudioTool(
              label: 'Supprimer le passage',
              icon: Icons.delete_outline,
              onPressed: () {
                _change(() => _commands.delete(warp.id));
                widget.onDeleted();
              },
            ),
          ],
        ),
      ],
    );
  }
}
