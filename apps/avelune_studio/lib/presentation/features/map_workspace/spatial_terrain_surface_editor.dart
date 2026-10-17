import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/spatial_terrain_surface_editing_commands.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'map_workspace_view_state.dart';

class SpatialTerrainSurfaceEditor extends StatefulWidget {
  const SpatialTerrainSurfaceEditor({
    super.key,
    required this.document,
    required this.view,
    required this.onChanged,
  });
  final EditableMapDocument document;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  @override
  State<SpatialTerrainSurfaceEditor> createState() =>
      _SpatialTerrainSurfaceEditorState();
}

class _SpatialTerrainSurfaceEditorState
    extends State<SpatialTerrainSurfaceEditor> {
  MapData? _source;
  SpatialTerrainSurface? _surface;
  SpatialTerrainSurfaceEditingPreview? _ownPreview;
  final _values = <String, String>{};
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SpatialTerrainSurfaceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(_source, widget.document.current) ||
        !identical(oldWidget.view, widget.view) ||
        _surface?.id != widget.view.spatialSurfaceId) {
      _clearPreview(oldWidget.view);
      _load();
    }
  }

  @override
  void dispose() {
    _clearPreview(widget.view);
    super.dispose();
  }

  void _clearPreview(MapWorkspaceViewState view) {
    if (identical(view.terrainSurfacePreview, _ownPreview)) {
      view.terrainSurfacePreview = null;
    }
    _ownPreview = null;
  }

  void _load() {
    final map = widget.document.current;
    final scene = map.spatialScene!;
    final sameMap = _source == null || _source!.id == map.id;
    final id = sameMap ? widget.view.spatialSurfaceId : null;
    _source = map;
    _surface = scene.terrainSurfaces.surfaces
        .where((surface) => surface.id == id)
        .firstOrNull;
    widget.view.spatialSurfaceId = _surface?.id;
    _error = null;
    _notice = null;
    final surface = _surface;
    if (surface == null) {
      _values.clear();
      return;
    }
    _values.addAll({
      'x': '${surface.x}',
      'z': '${surface.z}',
      'height': '${surface.height / scene.levelHeight}',
      'width': '${surface.bounds.right - surface.bounds.left}',
      'depth': '${surface.bounds.bottom - surface.bounds.top}',
      'rise-x': '${surface.gradientX / scene.levelHeight}',
      'rise-z': '${surface.gradientZ / scene.levelHeight}',
    });
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

  void _preview() {
    _clearPreview(widget.view);
    try {
      if (!identical(_source, widget.document.current)) {
        throw StateError('La carte a changé. Choisissez à nouveau la surface.');
      }
      final surface = _surface!;
      final width = terrainSurfaceNumber(_values['width']!, 'La largeur');
      final depth = terrainSurfaceNumber(_values['depth']!, 'La profondeur');
      if (width <= 0 || depth <= 0) {
        throw StateError('Les dimensions doivent être strictement positives.');
      }
      final scaleX = width / (surface.bounds.right - surface.bounds.left);
      final scaleZ = depth / (surface.bounds.bottom - surface.bounds.top);
      final step = widget.document.current.spatialScene!.levelHeight;
      final changed = surface.copyWith(
        x: terrainSurfaceNumber(_values['x']!, 'X'),
        z: terrainSurfaceNumber(_values['z']!, 'Y'),
        height: terrainSurfaceNumber(_values['height']!, 'La hauteur') * step,
        gradientX:
            terrainSurfaceNumber(
              _values['rise-x']!,
              'La montée vers la droite',
            ) *
            step,
        gradientZ:
            terrainSurfaceNumber(_values['rise-z']!, 'La montée vers le bas') *
            step,
        footprints: scaleX == 1 && scaleZ == 1
            ? surface.footprints
            : [
                for (final footprint in surface.footprints)
                  BorderGroundFootprint(
                    points: [
                      for (final point in footprint.points)
                        BorderGroundPoint(
                          x: point.x * scaleX,
                          z: point.z * scaleZ,
                        ),
                    ],
                  ),
              ],
      );
      _ownPreview = SpatialTerrainSurfaceEditingCommands(widget.document)
          .preview(
            changed,
            reanchorInstances: widget.view.spatialSurfaceReanchorInstances,
          );
      widget.view.terrainSurfacePreview = _ownPreview;
      _error = null;
    } on Object catch (failure) {
      _error = terrainSurfaceFailureMessage(failure);
    }
    setState(() {});
    widget.onChanged();
  }

  void _apply() {
    final preview = widget.view.terrainSurfacePreview;
    if (preview == null) return;
    try {
      SpatialTerrainSurfaceEditingCommands(widget.document).apply(preview);
      _clearPreview(widget.view);
      _load();
      _notice = 'Surface appliquée. Une seule annulation restaure la carte.';
    } on Object catch (failure) {
      _error = terrainSurfaceFailureMessage(failure);
    }
    setState(() {});
    widget.onChanged();
  }

  void _delete() {
    try {
      SpatialTerrainSurfaceEditingCommands(widget.document).delete(
        _surface!.id,
        reanchorInstances: widget.view.spatialSurfaceReanchorInstances,
      );
      _clearPreview(widget.view);
      _load();
      _notice = 'Surface supprimée. Annuler permet de la retrouver.';
    } on Object catch (failure) {
      _error = terrainSurfaceFailureMessage(failure);
    }
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces =
        widget.document.current.spatialScene!.terrainSurfaces.surfaces;
    final enabled = !widget.document.saving && _surface != null;
    final preview = widget.view.terrainSurfacePreview;
    final valid = preview?.validFor(widget.document.current) == true;
    return StudioPanel(
      compact: true,
      title: 'Modifier une surface',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StudioButton(
              label: 'Dessiner',
              secondary: widget.view.spatialSurfaceSelect,
              onPressed: widget.document.saving
                  ? null
                  : () => _edit(() => widget.view.spatialSurfaceSelect = false),
            ),
            StudioButton(
              label: 'Sélectionner',
              secondary: !widget.view.spatialSurfaceSelect,
              onPressed: widget.document.saving || surfaces.isEmpty
                  ? null
                  : () => _edit(() => widget.view.spatialSurfaceSelect = true),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (surfaces.isEmpty)
          const StudioNotice(
            'Dessinez une surface sur la carte. Vous pourrez ensuite ajuster sa position, ses dimensions et sa pente ici.',
          )
        else ...[
          StudioSelect(
            key: const ValueKey('terrain-surface-picker'),
            label: 'Surface de la carte',
            value: _surface?.id ?? '',
            options: {
              '': 'Choisissez une surface',
              for (var i = 0; i < surfaces.length; i++)
                surfaces[i].id:
                    'Surface ${i + 1} · X ${surfaces[i].x}, Y ${surfaces[i].z}',
            },
            onChanged: widget.document.saving
                ? null
                : (id) => _edit(() {
                    widget.view.spatialSurfaceId = id.isEmpty ? null : id;
                    widget.view.spatialSurfaceSelect = true;
                    _load();
                  }),
          ),
          const SizedBox(height: 12),
          if (_surface == null)
            const StudioNotice(
              'Choisissez une surface dans la liste ou cliquez sur la carte avec Sélectionner.',
            )
          else ...[
            for (final (id, label) in const [
              ('x', 'X'),
              ('z', 'Y'),
              ('width', 'Largeur'),
              ('depth', 'Profondeur'),
              ('height', 'Hauteur à l’origine'),
              ('rise-x', 'Montée vers la droite par case'),
              ('rise-z', 'Montée vers le bas par case'),
            ]) ...[
              StudioDraftField(
                key: ValueKey('terrain-surface-$id'),
                label: label,
                value: _values[id]!,
                enabled: enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                onChanged: (value) => _edit(() => _values[id] = value),
              ),
              const SizedBox(height: 12),
            ],
            const StudioNotice(
              'Positions et dimensions en cases. Les montées sont exprimées en blocs par case ; une valeur négative descend. Les décors conservent leur décalage au-dessus du terrain.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StudioButton(
                  key: const ValueKey('terrain-surface-preview'),
                  label: 'Aperçu',
                  secondary: true,
                  onPressed: enabled ? _preview : null,
                ),
                StudioButton(
                  key: const ValueKey('terrain-surface-apply'),
                  label: 'Appliquer',
                  onPressed: enabled && valid && preview!.hasChanges
                      ? _apply
                      : null,
                ),
                StudioButton(
                  key: const ValueKey('terrain-surface-cancel'),
                  label: 'Annuler l’aperçu',
                  variant: StudioButtonVariant.quiet,
                  onPressed: valid ? () => _edit(() {}) : null,
                ),
                StudioButton(
                  key: const ValueKey('terrain-surface-delete'),
                  label: 'Supprimer',
                  variant: StudioButtonVariant.quiet,
                  onPressed: enabled ? _delete : null,
                ),
              ],
            ),
          ],
        ],
        if (valid) ...[
          const SizedBox(height: 12),
          StudioNotice(
            preview!.hasChanges
                ? 'Aperçu sur la carte. Appliquez pour conserver ce changement.'
                : 'La surface correspond déjà à ces valeurs.',
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
    );
  }
}
