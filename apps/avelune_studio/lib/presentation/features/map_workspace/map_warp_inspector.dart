import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/warp_editing_commands.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'map_warp_door_editor.dart';
import 'map_warp_transition_editor.dart';
import 'map_warp_ladder_editor.dart';

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
  MapWarpTriggerMode? _pendingActiveMode;
  String? _pendingDestination;
  int? _pendingX;
  int? _pendingY;

  WarpEditingCommands get _commands =>
      WarpEditingCommands(widget.document, widget.project);

  void _clearPending() {
    _pendingActiveMode = null;
    _pendingDestination = null;
    _pendingX = null;
    _pendingY = null;
  }

  @override
  void didUpdateWidget(MapWarpInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.document, widget.document) ||
        oldWidget.warp.id != widget.warp.id ||
        oldWidget.warp.triggerMode != widget.warp.triggerMode) {
      _clearPending();
    }
  }

  void _selectMode(String raw) {
    final mode = MapWarpTriggerMode.values.byName(raw);
    if (widget.warp.triggerMode == MapWarpTriggerMode.sceneOnly &&
        mode != MapWarpTriggerMode.sceneOnly) {
      setState(() => _pendingActiveMode = mode);
      return;
    }
    setState(_clearPending);
    if (mode != widget.warp.triggerMode) {
      _change(() => _commands.retarget(widget.warp.id, triggerMode: mode));
    }
  }

  bool _commitTarget(String raw, {required bool horizontal}) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed < 0) {
      if (_pendingActiveMode != null) {
        setState(() {
          if (horizontal) {
            _pendingX = null;
          } else {
            _pendingY = null;
          }
        });
      }
      widget.document.error =
          'La case d’arrivée doit être exprimée en nombres positifs.';
      widget.onChanged();
      return false;
    }
    if (_pendingActiveMode != null) {
      setState(() {
        if (horizontal) {
          _pendingX = parsed;
        } else {
          _pendingY = parsed;
        }
      });
      return true;
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
    final pending = _pendingActiveMode != null;
    final mode = _pendingActiveMode ?? warp.triggerMode;
    final passive = mode == MapWarpTriggerMode.sceneOnly;
    final owner = '${widget.document.current.id}/${warp.id}';
    final destinations = _commands
        .destinations()
        .where(
          (entry) =>
              !pending ||
              widget.project.maps
                      .where((candidate) => candidate.id == entry.id)
                      .length ==
                  1,
        )
        .toList();
    final targetMapId = pending ? _pendingDestination : warp.targetMapId;
    final problem = pending ? null : _commands.destinationProblem(warp);
    final known = destinations.any((entry) => entry.id == targetMapId);
    final canApply = pending && known && _pendingX != null && _pendingY != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          passive ? 'Point d’arrivée' : 'Passage',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          '${passive ? 'Position' : 'Départ'} : ${widget.document.current.name} · ${warp.pos.x}, ${warp.pos.y}',
        ),
        if (!passive) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('warp-destination-${warp.id}-$pending'),
            initialValue: known ? targetMapId : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Carte d’arrivée'),
            items: [
              for (final entry in destinations)
                DropdownMenuItem(value: entry.id, child: Text(entry.name)),
            ],
            onChanged: (id) {
              if (id == null) return;
              if (pending) {
                setState(() {
                  _pendingDestination = id;
                  _pendingX = null;
                  _pendingY = null;
                });
              } else {
                _change(() => _commands.retarget(warp.id, targetMapId: id));
              }
            },
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
                  key: ValueKey('warp-target-x-$owner-$pending-$targetMapId'),
                  label: 'Case X',
                  value: pending ? '${_pendingX ?? ''}' : '${warp.targetPos.x}',
                  tryCommit: (raw) => _commitTarget(raw, horizontal: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StudioCommitField(
                  key: ValueKey('warp-target-y-$owner-$pending-$targetMapId'),
                  label: 'Case Y',
                  value: pending ? '${_pendingY ?? ''}' : '${warp.targetPos.y}',
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
        ],
        const SizedBox(height: 12),
        StudioSelect(
          key: ValueKey('warp-mode-${warp.id}-${mode.name}'),
          label: 'Utilisation',
          value: mode.name,
          options: const {
            'onEnter': 'À l’entrée',
            'onBump': 'Au contact',
            'sceneOnly': 'Point d’arrivée',
          },
          onChanged: _selectMode,
        ),
        if (pending) ...[
          const SizedBox(height: 8),
          const Text('Choisissez la carte et la case de sortie.'),
          const SizedBox(height: 8),
          StudioButton(
            label: 'Appliquer le passage',
            onPressed: canApply
                ? () {
                    _change(
                      () => _commands.retarget(
                        warp.id,
                        triggerMode: _pendingActiveMode,
                        targetMapId: _pendingDestination,
                        targetPos: GridPos(x: _pendingX!, y: _pendingY!),
                      ),
                    );
                  }
                : null,
          ),
        ],
        if (passive) ...[
          const SizedBox(height: 6),
          Text(
            'Utilisé par une scène',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (!passive && !pending) ...[
          const SizedBox(height: 12),
          MapWarpTransitionEditor(
            key: ValueKey('warp-transition-$owner'),
            warp: warp,
            onApply: (transition) =>
                _change(() => _commands.configureTransition(warp.id, transition)),
          ),
        ],
        if (!passive &&
            !pending &&
            widget.document.current.spatialScene != null) ...[
          const SizedBox(height: 12),
          MapWarpLadderEditor(
            warp: warp,
            onApply: (ladder) =>
                _change(() => _commands.configureLadder(warp.id, ladder)),
          ),
          const SizedBox(height: 12),
          MapWarpDoorEditor(
            map: widget.document.current,
            project: widget.project,
            warp: warp,
            onApply: (door) =>
                _change(() => _commands.configureDoor(warp.id, door)),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            if (!passive &&
                !pending &&
                widget.onOpenDestination != null &&
                known)
              StudioTool(
                label: 'Ouvrir la carte d’arrivée',
                icon: Icons.open_in_new,
                onPressed: () => widget.onOpenDestination!(warp.targetMapId),
              ),
            StudioTool(
              label: passive
                  ? 'Supprimer le point d’arrivée'
                  : 'Supprimer le passage',
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
