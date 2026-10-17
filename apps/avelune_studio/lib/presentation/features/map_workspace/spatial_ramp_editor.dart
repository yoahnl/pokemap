import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/spatial_ramp_editing_commands.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'map_workspace_view_state.dart';

class SpatialRampEditor extends StatefulWidget {
  const SpatialRampEditor({
    super.key,
    required this.document,
    required this.view,
    required this.onChanged,
    this.project,
  });

  final EditableMapDocument document;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final ProjectManifest? project;

  @override
  State<SpatialRampEditor> createState() => _SpatialRampEditorState();
}

class _SpatialRampEditorState extends State<SpatialRampEditor> {
  MapData? _source;
  SpatialRamp? _ramp;
  SpatialRampEditingPreview? _ownPreview;
  String _x = '', _y = '', _width = '', _depth = '';
  int _lowLevel = 0, _highLevel = 1;
  SpatialRampDirection _direction = SpatialRampDirection.north;
  String? _surfaceInstanceId;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _load(widget.document.current);
  }

  @override
  void didUpdateWidget(SpatialRampEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(_source, widget.document.current) ||
        !identical(oldWidget.view, widget.view)) {
      _clearPreview(oldWidget.view);
      _load(widget.document.current);
      _notice = 'La carte a changé. Les valeurs affichées ont été actualisées.';
    }
  }

  @override
  void dispose() {
    _clearPreview(widget.view);
    super.dispose();
  }

  void _clearPreview(MapWorkspaceViewState view) {
    if (identical(view.rampPreview, _ownPreview)) view.rampPreview = null;
    _ownPreview = null;
  }

  void _load(MapData map, {String? rampId}) {
    final sameMap = _source?.id == map.id;
    final selectedId = rampId ?? (sameMap ? _ramp?.id : null);
    final ramps = map.spatialScene?.navigation.ramps ?? const <SpatialRamp>[];
    _source = map;
    _ramp =
        ramps.where((ramp) => ramp.id == selectedId).firstOrNull ??
        ramps.firstOrNull;
    final ramp = _ramp;
    if (ramp != null) {
      _x = '${ramp.x}';
      _y = '${ramp.z}';
      _width = '${ramp.width}';
      _depth = '${ramp.depth}';
      _lowLevel = ramp.lowLevel;
      _highLevel = ramp.highLevel;
      _direction = ramp.direction;
      _surfaceInstanceId = ramp.surfaceInstanceId;
    }
    _error = null;
    _notice = null;
  }

  void _edit(VoidCallback change) {
    setState(() {
      _clearPreview(widget.view);
      _error = null;
      _notice = null;
      change();
    });
    widget.onChanged();
  }

  double _number(String value, String label) {
    final number = double.tryParse(value.trim().replaceAll(',', '.'));
    if (number == null || !number.isFinite) {
      throw StateError('$label doit être un nombre fini, par exemple 1,25.');
    }
    return number;
  }

  void _preview() {
    _clearPreview(widget.view);
    try {
      if (!identical(_source, widget.document.current)) {
        throw StateError('La carte a changé. Choisissez à nouveau la pente.');
      }
      final ramp = _ramp!;
      final preview =
          SpatialRampEditingCommands(
            widget.document,
            project: widget.project,
          ).preview(
            ramp.copyWith(
              x: _number(_x, 'X'),
              z: _number(_y, 'Y'),
              width: _number(_width, 'La largeur'),
              depth: _number(_depth, 'La profondeur'),
              lowLevel: _lowLevel,
              highLevel: _highLevel,
              direction: _direction,
              surfaceInstanceId: _surfaceInstanceId,
            ),
          );
      _ownPreview = preview;
      widget.view.rampPreview = preview;
      _error = null;
      _notice = null;
    } on Object catch (failure) {
      _error = spatialRampEditingFailureMessage(failure);
    }
    setState(() {});
    widget.onChanged();
  }

  void _apply() {
    final preview = widget.view.rampPreview;
    if (preview == null) return;
    try {
      SpatialRampEditingCommands(
        widget.document,
        project: widget.project,
      ).apply(preview);
      _clearPreview(widget.view);
      _load(widget.document.current);
      _notice = 'Pente appliquée. Une seule annulation restaure la carte.';
    } on Object catch (failure) {
      _clearPreview(widget.view);
      _error = spatialRampEditingFailureMessage(failure);
    }
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.document.current;
    final scene = map.spatialScene;
    final ramps = scene?.navigation.ramps ?? const <SpatialRamp>[];
    final ownedInstances = <String>{};
    for (final layer in map.layers) {
      if (layer is EnvironmentLayer) {
        for (final area in layer.content.areas) {
          ownedInstances.addAll(area.generatedPlacementIds);
        }
      } else if (layer is BorderLayer) {
        for (final feature in layer.content.features) {
          ownedInstances.addAll(feature.generatedPlacementIds);
        }
      }
    }
    final surfaces = (scene?.instances ?? const <SpatialModelInstance>[])
        .where(
          (instance) =>
              !instance.blocksMovement &&
              !instance.id.startsWith('smt_') &&
              !ownedInstances.contains(instance.id),
        )
        .toList();
    final modelNames = {
      for (final model
          in widget.project?.models3d ?? const <ProjectModel3dEntry>[])
        model.id: model.name,
    };
    final enabled = !widget.document.saving && _ramp != null;
    final preview = widget.view.rampPreview;
    final validPreview = preview != null && preview.validFor(map);
    final picker = StudioSelect(
      key: const ValueKey('spatial-ramp-picker'),
      label: 'Pente de la carte',
      value: _ramp?.id,
      options: {
        for (var index = 0; index < ramps.length; index++)
          ramps[index].id:
              'Pente ${index + 1} · X ${ramps[index].x}, Y ${ramps[index].z}',
      },
      onChanged: enabled
          ? (value) => _edit(() => _load(map, rampId: value))
          : null,
    );
    final attachedInstance = scene?.instances
        .where((instance) => instance.id == _ramp?.surfaceInstanceId)
        .firstOrNull;
    final automatic =
        widget.project?.models3d.any(
          (model) =>
              model.id == attachedInstance?.modelId &&
              model.rampProfile != null,
        ) ??
        false;
    if (automatic) {
      return StudioPanel(
        compact: true,
        title: 'Pente liée à un escalier',
        children: [
          picker,
          const SizedBox(height: 12),
          const StudioNotice(
            'Cette pente suit automatiquement son escalier. Déplacez ou tournez le décor ; réglez ses dimensions dans Ressources pour changer le modèle.',
          ),
        ],
      );
    }
    return StudioPanel(
      compact: true,
      title: 'Ajuster une pente',
      children: [
        if (ramps.isEmpty)
          const StudioNotice(
            'Dessinez une pente sur la carte pour pouvoir ajuster ici sa position et ses dimensions.',
          )
        else ...[
          picker,
          const SizedBox(height: 12),
          for (final field in <(String, String, ValueChanged<String>)>[
            ('X', _x, (value) => _x = value),
            ('Y', _y, (value) => _y = value),
            ('Largeur', _width, (value) => _width = value),
            ('Profondeur', _depth, (value) => _depth = value),
          ]) ...[
            StudioDraftField(
              key: ValueKey('spatial-ramp-${field.$1}'),
              label: field.$1,
              value: field.$2,
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) => _edit(() => field.$3(value)),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            'Position et dimensions en cases. Un niveau représente ${scene!.levelHeight} case de hauteur.',
          ),
          const SizedBox(height: 12),
          StudioSelect(
            key: const ValueKey('spatial-ramp-low-level'),
            label: 'Niveau bas',
            value: '$_lowLevel',
            options: {
              for (
                var level = 0;
                level <= MapSpatialScene.maximumTerrainLevel;
                level++
              )
                '$level': '$level',
            },
            onChanged: enabled
                ? (value) => _edit(() => _lowLevel = int.parse(value))
                : null,
          ),
          const SizedBox(height: 12),
          StudioSelect(
            key: const ValueKey('spatial-ramp-high-level'),
            label: 'Niveau haut',
            value: '$_highLevel',
            options: {
              for (
                var level = 1;
                level <= MapSpatialScene.maximumTerrainLevel;
                level++
              )
                '$level': '$level',
            },
            onChanged: enabled
                ? (value) => _edit(() => _highLevel = int.parse(value))
                : null,
          ),
          const SizedBox(height: 12),
          StudioSelect(
            key: const ValueKey('spatial-ramp-direction'),
            label: 'Montée vers',
            value: _direction.name,
            options: const {
              'north': 'Le haut de la carte',
              'south': 'Le bas de la carte',
              'east': 'La droite de la carte',
              'west': 'La gauche de la carte',
            },
            onChanged: enabled
                ? (value) => _edit(
                    () =>
                        _direction = SpatialRampDirection.values.byName(value),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          StudioSelect(
            key: const ValueKey('spatial-ramp-surface'),
            label: 'Apparence de la pente',
            value: _surfaceInstanceId ?? '',
            options: {
              '': 'Terrain peint',
              for (var index = 0; index < surfaces.length; index++)
                surfaces[index].id:
                    '${modelNames[surfaces[index].modelId] ?? 'Décor ${index + 1}'} · X ${surfaces[index].position.x}, Y ${surfaces[index].position.z}',
            },
            onChanged: enabled
                ? (value) => _edit(
                    () => _surfaceInstanceId = value.isEmpty ? null : value,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          const StudioNotice(
            'Choisissez un escalier déjà placé pour afficher ses marches à la place du terrain. Son emprise doit couvrir la pente ; il doit laisser passer le personnage.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StudioButton(
                key: const ValueKey('spatial-ramp-preview'),
                label: 'Aperçu',
                secondary: true,
                onPressed: enabled ? _preview : null,
              ),
              StudioButton(
                key: const ValueKey('spatial-ramp-apply'),
                label: 'Appliquer',
                onPressed: enabled && validPreview && preview.hasChanges
                    ? _apply
                    : null,
              ),
              StudioButton(
                key: const ValueKey('spatial-ramp-cancel'),
                label: 'Annuler l’aperçu',
                variant: StudioButtonVariant.quiet,
                onPressed: validPreview ? () => _edit(() {}) : null,
              ),
            ],
          ),
          if (validPreview) ...[
            const SizedBox(height: 12),
            StudioNotice(
              preview.hasChanges
                  ? 'Aperçu sur la carte. Les décors suivent leur sol et conservent leur décalage de hauteur. Appliquez pour modifier la carte.'
                  : 'La pente correspond déjà à ces valeurs.',
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            StudioNotice(_error!, isError: true),
          ],
          if (_notice != null) ...[
            const SizedBox(height: 12),
            StudioNotice(_notice!),
          ],
        ],
      ],
    );
  }
}
