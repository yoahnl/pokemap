import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

const Color _accent = Color(0xFF2DD4BF);

/// Panneau final du workflow : les surfaces réellement peignables.
///
/// Les presets restent l’unité technique du catalogue, mais l’UI parle ici de
/// surfaces à peindre pour éviter que l’utilisateur confonde atlas, animations
/// et résultat final utilisable dans l’éditeur de map.
class SurfaceStudioPaintableSurfacesPanel extends StatelessWidget {
  const SurfaceStudioPaintableSurfacesPanel({
    super.key,
    required this.readModel,
    this.selectedPresetId,
    this.onCreateSurfacePressed,
    this.onSaveCatalogPressed,
    this.onPresetSelected,
    this.onEditMappingPressed,
    this.mappingEditor,
  });

  final SurfaceStudioReadModel readModel;
  final String? selectedPresetId;
  final VoidCallback? onCreateSurfacePressed;
  final VoidCallback? onSaveCatalogPressed;
  final ValueChanged<String>? onPresetSelected;
  final ValueChanged<String>? onEditMappingPressed;
  final Widget? mappingEditor;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final presets = readModel.presets;
    final hasAnimations = readModel.summary.animationCount > 0;
    final hasSurfaces = presets.isNotEmpty;

    return Container(
      key: const ValueKey('surface_studio_paintable_surfaces_panel'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Surfaces prêtes à peindre',
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ces surfaces seront disponibles dans l’éditeur de map pour peindre vos niveaux.',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          if (!hasSurfaces)
            _EmptyPaintableState(hasAnimations: hasAnimations)
          else
            for (var i = 0; i < presets.length; i++) ...[
              _PaintableSurfaceRow(
                row: presets[i],
                selected: presets[i].id == selectedPresetId,
                onSelect: onPresetSelected == null
                    ? null
                    : () => onPresetSelected!(presets[i].id),
                onEditMapping: onEditMappingPressed == null
                    ? null
                    : () => onEditMappingPressed!(presets[i].id),
              ),
              if (i != presets.length - 1) const SizedBox(height: 8),
            ],
          if (mappingEditor != null) ...[
            const SizedBox(height: 12),
            mappingEditor!,
          ],
          const SizedBox(height: 12),
          CupertinoButton(
            key: const ValueKey('surface_studio_guidance_create_surface'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            color: _accent.withValues(alpha: 0.72),
            disabledColor: EditorChrome.islandFillElevated(context)
                .withValues(alpha: 0.72),
            onPressed: onCreateSurfacePressed,
            child: const Text('Créer une surface'),
          ),
          if (onCreateSurfacePressed == null) ...[
            const SizedBox(height: 6),
            Text(
              hasAnimations
                  ? 'Utilisez le bloc “Créer une surface à peindre” après avoir généré les animations.'
                  : 'Générez d’abord les animations depuis l’atlas.',
              style: TextStyle(color: subtle, fontSize: 10.5, height: 1.35),
            ),
          ],
          if (onSaveCatalogPressed != null) ...[
            const SizedBox(height: 8),
            CupertinoButton(
              key: const ValueKey('surface_studio_guidance_save_catalog'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              onPressed: onSaveCatalogPressed,
              child: const Text('Sauvegarder le catalogue'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyPaintableState extends StatelessWidget {
  const _EmptyPaintableState({required this.hasAnimations});

  final bool hasAnimations;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasAnimations
                ? 'Animations détectées, mais aucune surface peignable.'
                : 'Aucune surface prête à peindre',
            style: TextStyle(
              color: label,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasAnimations
                ? 'Créez une surface à partir des animations générées.'
                : 'Générez des animations depuis un atlas, puis créez une surface peignable.',
            style: TextStyle(
              color: subtle.withValues(alpha: 0.95),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaintableSurfaceRow extends StatelessWidget {
  const _PaintableSurfaceRow({
    required this.row,
    required this.selected,
    this.onSelect,
    this.onEditMapping,
  });

  final SurfaceStudioPresetReadModel row;
  final bool selected;
  final VoidCallback? onSelect;
  final VoidCallback? onEditMapping;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final content = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected
            ? _accent.withValues(alpha: 0.12)
            : EditorChrome.islandFillElevated(context).withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? _accent.withValues(alpha: 0.68)
              : EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Peignable',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ID : ${row.id}',
            style: TextStyle(
              color: subtle.withValues(alpha: 0.92),
              fontSize: 10.5,
              height: 1.3,
            ),
          ),
          Text(
            '${row.referencedAnimationIds.length} animation(s) liée(s)',
            style: TextStyle(
              color: subtle.withValues(alpha: 0.92),
              fontSize: 10.5,
              height: 1.3,
            ),
          ),
          if (onEditMapping != null) ...[
            const SizedBox(height: 8),
            CupertinoButton(
              key: ValueKey('surface_paintable_edit_mapping_${row.id}'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              onPressed: onEditMapping,
              child: const Text('Modifier le mapping'),
            ),
          ],
        ],
      ),
    );
    if (onSelect == null) {
      return content;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      child: content,
    );
  }
}
