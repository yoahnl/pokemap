import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';

class MapWarpDoorEditor extends StatefulWidget {
  const MapWarpDoorEditor({
    super.key,
    required this.map,
    required this.project,
    required this.warp,
    required this.onApply,
  });

  final MapData map;
  final ProjectManifest project;
  final MapWarp warp;
  final ValueChanged<MapWarpDoor?> onApply;

  @override
  State<MapWarpDoorEditor> createState() => _MapWarpDoorEditorState();
}

class _MapWarpDoorEditorState extends State<MapWarpDoorEditor> {
  MapWarpDoor? _draft;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(MapWarpDoorEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.warp.id != widget.warp.id ||
        oldWidget.map.id != widget.map.id ||
        oldWidget.warp.door != widget.warp.door) {
      _reset();
    }
  }

  void _reset() {
    _draft = widget.warp.door;
    _enabled = _draft != null;
  }

  ProjectModel3dEntry? _model(SpatialModelInstance instance) {
    final models = widget.project.models3d.where(
      (model) => model.id == instance.modelId,
    );
    return models.length == 1 ? models.single : null;
  }

  List<Model3dAnimation> _clips(ProjectModel3dEntry? model) {
    final clips = model?.inspection.animations ?? <Model3dAnimation>[];
    return clips
        .where(
          (clip) =>
              clip.durationSeconds.isFinite &&
              clip.durationSeconds > 0 &&
              clips.where((other) => other.index == clip.index).length == 1,
        )
        .toList();
  }

  Map<GridPos, String> _exits() {
    final position = widget.warp.pos;
    final candidates = {
      GridPos(x: position.x, y: position.y + 1): 'Sud',
      GridPos(x: position.x, y: position.y - 1): 'Nord',
      GridPos(x: position.x + 1, y: position.y): 'Est',
      GridPos(x: position.x - 1, y: position.y): 'Ouest',
    };
    return Map.fromEntries(
      candidates.entries.where((entry) {
        final position = entry.key;
        return position.x >= 0 &&
            position.y >= 0 &&
            position.x < widget.map.size.width &&
            position.y < widget.map.size.height &&
            !(widget.map.spatialScene?.navigation.blockedAreas.any(
                  (area) => area.contains(position.x + .5, position.y + .5),
                ) ??
                false);
      }),
    );
  }

  String _exitId(GridPos position) => '${position.x},${position.y}';

  MapWarpDoor _binding(SpatialModelInstance instance, GridPos exit) {
    final clips = _clips(_model(instance));
    return MapWarpDoor(
      instanceId: instance.id,
      openAnimationIndex: clips.first.index,
      closeAnimationIndex: clips.length > 1
          ? clips[1].index
          : clips.first.index,
      exitPos: exit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final instances =
        widget.map.spatialScene?.instances ?? <SpatialModelInstance>[];
    final candidates = instances
        .where(
          (instance) =>
              instance.clip == null &&
              instance.animationIndex == null &&
              instances.where((other) => other.id == instance.id).length == 1 &&
              _clips(_model(instance)).isNotEmpty,
        )
        .toList();
    final exits = _exits();
    final draft = _draft;
    final instance = candidates
        .where((item) => item.id == draft?.instanceId)
        .firstOrNull;
    final clips = _clips(instance == null ? null : _model(instance));
    final changed =
        _enabled != (widget.warp.door != null) ||
        (_enabled && draft != widget.warp.door);
    String? problem;
    if (_enabled) {
      if (draft == null) {
        problem = 'Choisissez un modèle animé et une case de dégagement.';
      } else {
        try {
          validateMapWarpDoor(
            widget.map,
            widget.warp.copyWith(door: draft),
            models: widget.project.models3d,
          );
        } on ValidationException catch (error) {
          problem = error.message;
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioToggleRow(
          label: 'Porte animée',
          description: 'Ouvre et ferme une porte placée sur cette carte lors du passage.',
          value: _enabled,
          onChanged: (value) => setState(() {
            _enabled = value;
            if (value &&
                _draft == null &&
                candidates.isNotEmpty &&
                exits.isNotEmpty) {
              _draft = _binding(candidates.first, exits.keys.first);
            }
          }),
        ),
        if (_enabled) ...[
          if (candidates.isEmpty) ...[
            const StudioNotice(
              'Placez un modèle avec une animation, sans lecture automatique, sur cette carte.',
            ),
            const SizedBox(height: 8),
          ],
          StudioSelect(
            label: 'Modèle de porte',
            value: draft?.instanceId,
            options: {
              for (final item in candidates)
                item.id:
                    '${_model(item)!.name} · ${item.position.x.toStringAsFixed(1)}, ${item.position.z.toStringAsFixed(1)}',
            },
            onChanged: exits.isEmpty
                ? null
                : (id) => setState(() {
                    _draft = _binding(
                      candidates.singleWhere((item) => item.id == id),
                      draft?.exitPos ?? exits.keys.first,
                    );
                  }),
          ),
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Animation d’ouverture',
            value: draft?.openAnimationIndex.toString(),
            options: {for (final clip in clips) '${clip.index}': clip.name},
            onChanged: draft == null
                ? null
                : (index) => setState(() {
                    _draft = draft.copyWith(
                      openAnimationIndex: int.parse(index),
                    );
                  }),
          ),
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Animation de fermeture',
            value: draft?.closeAnimationIndex.toString(),
            options: {for (final clip in clips) '${clip.index}': clip.name},
            onChanged: draft == null
                ? null
                : (index) => setState(() {
                    _draft = draft.copyWith(
                      closeAnimationIndex: int.parse(index),
                    );
                  }),
          ),
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Case de dégagement',
            value: draft == null ? null : _exitId(draft.exitPos),
            options: {
              for (final entry in exits.entries)
                _exitId(entry.key):
                    '${entry.value} · ${entry.key.x}, ${entry.key.y}',
            },
            onChanged: draft == null
                ? null
                : (id) => setState(() {
                    _draft = draft.copyWith(
                      exitPos: exits.keys.singleWhere(
                        (position) => _exitId(position) == id,
                      ),
                    );
                  }),
          ),
          const SizedBox(height: 8),
          const Text(
            'Au retour, le personnage quitte la porte vers cette case avant sa fermeture.',
          ),
          if (problem != null) ...[
            const SizedBox(height: 8),
            StudioNotice(problem, isError: true),
          ],
        ],
        if (changed) ...[
          const SizedBox(height: 8),
          StudioButton(
            label: 'Appliquer la porte',
            onPressed: problem == null
                ? () => widget.onApply(_enabled ? _draft : null)
                : null,
          ),
        ],
      ],
    );
  }
}
