import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/warp_editing_commands.dart';
import '../../shared/widgets/buttons/studio_tool.dart';

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
  final _x = TextEditingController();
  final _y = TextEditingController();
  String? _appliedTo;

  WarpEditingCommands get _commands =>
      WarpEditingCommands(widget.document, widget.project);

  @override
  void dispose() {
    _x.dispose();
    _y.dispose();
    super.dispose();
  }

  void _syncFields() {
    final warp = widget.warp;
    final key = '${warp.id}:${warp.targetPos.x}:${warp.targetPos.y}';
    if (_appliedTo == key) return;
    _appliedTo = key;
    _x.text = '${warp.targetPos.x}';
    _y.text = '${warp.targetPos.y}';
  }

  void _change(VoidCallback action) {
    try {
      action();
    } catch (error) {
      widget.document.error = error.toString();
    }
    widget.onChanged();
  }

  void _applyTargetPos() {
    final x = int.tryParse(_x.text.trim());
    final y = int.tryParse(_y.text.trim());
    if (x == null || y == null || x < 0 || y < 0) {
      _appliedTo = null;
      setState(_syncFields);
      widget.document.error =
          'La case d’arrivée doit être exprimée en nombres positifs.';
      widget.onChanged();
      return;
    }
    if (x == widget.warp.targetPos.x && y == widget.warp.targetPos.y) return;
    _change(
      () => _commands.retarget(
        widget.warp.id,
        targetPos: GridPos(x: x, y: y),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _syncFields();
    final warp = widget.warp;
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
              child: TextField(
                key: const ValueKey('warp-target-x'),
                controller: _x,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Case X'),
                onSubmitted: (_) => _applyTargetPos(),
                onTapOutside: (_) {
                  _applyTargetPos();
                  FocusManager.instance.primaryFocus?.unfocus();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: const ValueKey('warp-target-y'),
                controller: _y,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Case Y'),
                onSubmitted: (_) => _applyTargetPos(),
                onTapOutside: (_) {
                  _applyTargetPos();
                  FocusManager.instance.primaryFocus?.unfocus();
                },
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
                onPressed: () =>
                    widget.onOpenDestination!(warp.targetMapId),
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
