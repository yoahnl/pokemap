import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/warp_editing_commands.dart';
import '../../../features/map_workspace/application/map_warp_target_session.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'map_arrival_picker.dart';
import 'map_destination_picker.dart';
import 'map_dive_zone_panel.dart';
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
    this.loadDestination,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWarp warp;
  final VoidCallback onChanged;
  final VoidCallback onDeleted;
  final ValueChanged<String>? onOpenDestination;
  final Future<MapData?> Function(String mapId)? loadDestination;

  @override
  State<MapWarpInspector> createState() => _MapWarpInspectorState();
}

class _MapWarpInspectorState extends State<MapWarpInspector> {
  late MapWarpTargetSession form;

  WarpEditingCommands get _commands =>
      WarpEditingCommands(widget.document, widget.project);

  @override
  void initState() {
    super.initState();
    form = MapWarpTargetSession(widget.document, widget.project, widget.warp);
  }

  @override
  void didUpdateWidget(MapWarpInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.document, widget.document)) {
      form.dispose();
      form = MapWarpTargetSession(widget.document, widget.project, widget.warp);
    } else {
      form.update(widget.project, widget.warp);
    }
  }

  @override
  void dispose() {
    form.dispose();
    super.dispose();
  }

  void _selectMode(String raw) {
    setState(() => form.selectMode(raw));
    widget.onChanged();
  }

  bool _commitTarget(String raw, {required bool horizontal}) {
    final result = form.commitTarget(raw, horizontal: horizontal);
    setState(() {});
    widget.onChanged();
    return result;
  }

  Future<MapData?> _destination(String mapId) async {
    final load = widget.loadDestination;
    if (load != null) return load(mapId);
    final controller = context
        .getInheritedWidgetOfExactType<DivePairPublishingScope>()
        ?.controller;
    if (controller == null) return null;
    return controller.documents[mapId]?.current ??
        await controller.previewMap(mapId);
  }

  Future<void> _pickArrival(String mapId) async {
    final entry = widget.project.maps.firstWhere((map) => map.id == mapId);
    await form.pickArrival(
      (current) => showMapArrivalPicker(
        context,
        destinationName: entry.name,
        fromMapId: widget.document.current.id,
        current: current,
        destination: _destination(mapId),
      ),
    );
    if (!mounted) return;
    setState(() {});
    widget.onChanged();
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
    final pending = form.pendingActiveMode != null;
    final mode = form.pendingActiveMode ?? warp.triggerMode;
    final passive = mode == MapWarpTriggerMode.sceneOnly;
    final owner = '${widget.document.current.id}/${warp.id}';
    final destinations = form.destinations;
    final targetMapId = form.targetMapId;
    final problem = pending ? null : _commands.destinationProblem(warp);
    final known = form.known;
    final canApply = form.canApply;
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
              setState(() => form.selectDestination(id));
              widget.onChanged();
            },
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: StudioButton(
              key: const ValueKey('warp-destination-search'),
              label: 'Rechercher une carte…',
              icon: Icons.search,
              secondary: true,
              onPressed: () async {
                final id = await showMapDestinationPicker(
                  context,
                  widget.project,
                  excludeMapId: widget.document.current.id,
                  selectedId: targetMapId,
                );
                if (id == null || !mounted) return;
                setState(() => form.selectDestination(id));
                widget.onChanged();
              },
            ),
          ),
          if (problem != null) ...[
            const SizedBox(height: 6),
            Text(
              '$problem Référence conservée : ${warp.targetMapId}. Choisissez une autre carte pour la remplacer.',
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
                  value: pending
                      ? '${form.pendingX ?? ''}'
                      : '${warp.targetPos.x}',
                  tryCommit: (raw) => _commitTarget(raw, horizontal: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StudioCommitField(
                  key: ValueKey('warp-target-y-$owner-$pending-$targetMapId'),
                  label: 'Case Y',
                  value: pending
                      ? '${form.pendingY ?? ''}'
                      : '${warp.targetPos.y}',
                  tryCommit: (raw) => _commitTarget(raw, horizontal: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: StudioButton(
              key: const ValueKey('warp-arrival-picker'),
              label: 'Choisir le point d’arrivée…',
              icon: Icons.place_outlined,
              secondary: true,
              onPressed: known && targetMapId != null
                  ? () => _pickArrival(targetMapId)
                  : null,
            ),
          ),
          if (known && !pending)
            Text(
              'Arrivée : ${destinations.firstWhere((entry) => entry.id == targetMapId).name} · case ${warp.targetPos.x}, ${warp.targetPos.y}',
              key: const ValueKey('warp-arrival-summary'),
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
                    form.apply();
                    widget.onChanged();
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
            onApply: (transition) => _change(
              () => _commands.configureTransition(warp.id, transition),
            ),
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
