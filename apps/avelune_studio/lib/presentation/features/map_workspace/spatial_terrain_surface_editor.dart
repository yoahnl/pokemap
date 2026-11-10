import 'package:flutter/material.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/spatial_terrain_surface_editing_session.dart';
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
  late SpatialTerrainSurfaceEditingSession _editing;

  @override
  void initState() {
    super.initState();
    _editing = SpatialTerrainSurfaceEditingSession(
      widget.document,
      widget.view,
    );
  }

  @override
  void didUpdateWidget(SpatialTerrainSurfaceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.document, widget.document) ||
        !identical(oldWidget.view, widget.view)) {
      if (_editing.source?.id != widget.document.current.id) {
        widget.view.spatialSurfaceId = null;
      }
      _editing.dispose();
      _editing = SpatialTerrainSurfaceEditingSession(
        widget.document,
        widget.view,
      );
    } else if (!identical(_editing.source, widget.document.current) ||
        _editing.surface?.id != widget.view.spatialSurfaceId) {
      _editing.clearPreview(widget.view);
      _editing.load();
    }
  }

  @override
  void dispose() {
    _editing.dispose();
    super.dispose();
  }

  void _edit(VoidCallback change) {
    setState(() => _editing.edit(change));
    widget.onChanged();
  }

  void _preview() {
    setState(_editing.preview);
    widget.onChanged();
  }

  void _apply() {
    setState(_editing.apply);
    widget.onChanged();
  }

  void _delete() {
    setState(_editing.delete);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces =
        widget.document.current.spatialScene!.terrainSurfaces.surfaces;
    final enabled = !widget.document.saving && _editing.surface != null;
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
            value: _editing.surface?.id ?? '',
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
                    _editing.load();
                  }),
          ),
          const SizedBox(height: 12),
          if (_editing.surface == null)
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
                value: _editing.values[id]!,
                enabled: enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                onChanged: (value) => _edit(() => _editing.values[id] = value),
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
        if (_editing.error != null) ...[
          const SizedBox(height: 12),
          StudioNotice(_editing.error!, isError: true),
        ],
        if (_editing.notice != null) ...[
          const SizedBox(height: 12),
          StudioNotice(_editing.notice!),
        ],
      ],
    );
  }
}
