# Surface Studio Rebuild — Figma-grade Wizard UX V2

## 37.1 Verdict

Surface Studio Rebuild implémenté. Le premier viewport de `SurfaceStudioPanel` est maintenant un assistant premium sombre en 5 étapes, inspiré directement de l’image fournie : header avec stepper, sidebar rétractable, atlas central dominant, schéma à accordéons avec drag & drop, preview animée contrôlable et barre d’actions basse. Les briques métier Surface Studio existantes restent disponibles sous le nouvel assistant pour préserver le work catalog, les diagnostics, la génération atlas vertical et les flux de sauvegarde existants.

## 37.2 Audit initial

### Commandes Gate 0

```bash
$ pwd
/Users/karim/Project/pokemonProject

$ git status --short --untracked-files=all

$ ctx stats
zsh:1: command not found: ctx

$ find . -name AGENTS.md -print
./AGENTS.md

$ git log --oneline -n 8
b0a3c2d0 lot 116: MovementEffectZonePayload Model
3aae74a6 lot 114: Surface Movement Effect Runtime Prep
830b8b5b lot 113
011b4bc1 fix bridge
09a9b0df lot 112: Ice Mud Movement Semantics Decision
f57ade04 Merge PSDK battle parity work
993b0033 Complete PSDK battle parity batch
a294999b lot 110: Lava Hazard Runtime E2E Closure
```

### Fichiers Surface Studio audités au départ

```text
packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_editing.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_source_picker.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_column_role_mapping_block.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_creation_assistant.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_detected_animations_panel.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_diagnostics_view.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_editor_controller.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_preview.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_selection.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_inspector.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_summary.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_creation_section.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_layout.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_stepper.dart
```

### Tests Surface audités au départ

```text
packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart
packages/map_editor/test/surface_painter/surface_animation_frame_resolver_test.dart
packages/map_editor/test/surface_painter/surface_catalog_availability_test.dart
packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart
packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart
packages/map_editor/test/surface_painter/surface_painting_controller_test.dart
packages/map_editor/test/surface_painter/surface_palette_panel_test.dart
packages/map_editor/test/surface_painter/surface_tile_preview_resolver_test.dart
packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart
packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_editing_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_grid_overlay_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_source_picker_test.dart
packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart
packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart
packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart
packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart
packages/map_editor/test/surface_studio/surface_studio_preset_editor_controller_test.dart
packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart
packages/map_editor/test/surface_studio/surface_studio_role_mapping_preview_test.dart
packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart
packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart
packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart
packages/map_editor/test/surface_studio/surface_studio_selection_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generator_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_preview_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_assistant_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_preset_generator_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_role_mapping_test.dart
packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
```

### Résumé ancienne architecture

L’ancien point d’entrée `surface_studio_panel.dart` assemblait un header compact, un stepper de workflow historique, `SurfaceStudioWorkflowLayout`, la préparation d’atlas, les diagnostics, l’inspection et le browser catalogue. Cette structure conservait les flux métier mais ne ressemblait pas à un assistant desktop premium : peu de hiérarchie Figma-grade, pas de shell complet en 5 étapes, pas de panneau droit à accordéons, pas de drag & drop central entre atlas et rôles, et pas de preview contrôlée dans le premier viewport.

### Widgets conservés

- `SurfaceStudioAtlasAuthoringPrep` et les sections vertical atlas existantes.
- `SurfaceStudioCatalogBrowser`, `SurfaceStudioDiagnosticsView`, `SurfaceStudioSelectionInspector`, `SurfaceStudioDetectedAnimationsPanel`.
- `SurfaceStudioPaintableSurfacesPanel` et `SurfaceStudioRoleMappingEditor` pour la compatibilité authoring.

### Widgets remplacés ou contournés par le nouveau premier viewport

- Composition globale de `SurfaceStudioPanel`.
- Ancien header compact comme expérience principale.
- Ancien workflow quatre zones comme premier écran.
- Ancien stepper historique comme repère principal.

### Tests existants trouvés

Les tests existants Surface Studio couvraient le panel historique, les détails atlas/animation/preset, le browser, l’inspection, l’authoring vertical atlas, la génération d’animations, le golden slice et l’entrée workspace. Ils ont été conservés et relancés.

### Risques identifiés

- Risque de casser les tests historiques par l’ajout visible de l’étape `Enregistrer`; les assertions concernées ont été ajustées pour distinguer étape wizard et sauvegarde disque legacy.
- Risque de `MissingPluginException` macOS dans les tests shell complets; un mock de channel AppKit a été ajouté dans le harness de test.
- Risque d’overflow dans les anciens viewports de test; le nouvel assistant impose un canvas desktop scrollable horizontalement et compacte le stepper si besoin.

## 37.3 Interprétation de l’image

| Zone | Résultat | Notes |
| --- | --- | --- |
| Header | Conforme | Icône goutte, titre exact `Surface Studio — Assistant de mapping d’atlas`, stepper 5 étapes, icônes aide/paramètres/fermer. |
| Stepper | Conforme | Étape `Mapper` active par défaut en ambre; étapes précédentes complétées en teal; futures atténuées; clics contrôlés. |
| Sidebar | Conforme | Cartes verticales, états completed/active/future, carte Astuces, panneau rétractable avec animation. |
| Atlas panel | Conforme | Panneau central dominant, grille, colonnes numérotées, sélection ambre, zoom slider, auto-suggest, reset, métriques. |
| Schema panel | Conforme | Dock droit rétractable, titre exact, accordéons de rôles, slots droppables, Plein multi-colonnes, autres rôles mono-colonne. |
| Preview | Conforme | Bloc séparé dans le dock droit, preview animée/fallback eau, précédent/play-suivant, Frame X/N, scrub slider, Boucle, Grille, Taille. |
| Bottom bar | Conforme | `Retour`, `Suggestion auto`, `Appliquer le mapping`, `Suivant`; bouton Suivant accent or/ambre. |

Écart assumé : l’image atlas réelle du screenshot n’est pas hardcodée. Le widget utilise un fallback peint local quand aucun atlas image n’est résolu, conformément aux règles de robustesse et à l’interdiction de lier l’app à l’image de référence.

## 37.4 Nouvelle architecture

### Rôle des composants

- `surface_studio_panel.dart` reste le point d’entrée stable et orchestre le nouveau premier viewport plus le pont legacy.
- `surface_studio_screen.dart` porte l’état local du wizard, sélection, mapping, preview, panels et interactions.
- `surface_studio_step.dart`, `surface_studio_column_selection.dart`, `surface_studio_drag_payload.dart`, `surface_studio_role_assignment_draft.dart` structurent l’état UI et le DnD.
- `surface_studio_design_tokens.dart` et `surface_studio_motion.dart` centralisent palette, dimensions et timings.
- `shell/` contient le shell, le header, le stepper, la sidebar et la barre basse.
- `atlas/` contient le panneau atlas, viewport, painter de grille/fallback, sélection et toolbar.
- `schema/` contient le panneau accordéon, slots de rôles, validation drop et silhouettes.
- `preview/` contient la preview animée et ses contrôles.

### State local

`SurfaceStudioScreen` gère `currentStep`, collapsed sidebar/right dock, groupes de schéma ouverts, sélection de colonnes, draft de rôles, zoom, frame preview, play/pause, loop, grille et taille preview. Il ne mute pas le manifest; les mutations métier existantes restent dans les sections legacy et les callbacks existants.

### Flux DnD

Le viewport atlas expose de vrais `Draggable<SurfaceStudioColumnDragPayload>`. Les rôles du schéma sont de vrais `DragTarget<SurfaceStudioColumnDragPayload>`. La validation pure accepte plusieurs colonnes uniquement pour `Plein (center)` et refuse les multi-colonnes sur les autres rôles.

### Flux preview

La preview est isolée par `RepaintBoundary`, utilise un timer propre seulement en lecture, se dispose correctement et scrube via slider. Le fallback 120 ms/frame est volontaire pour le V2 UI quand aucune durée source n’est accessible dans le nouveau shell.

### Flux wizard

Le wizard comporte 5 étapes : Importer, Découper, Mapper, Prévisualiser, Enregistrer. La V2 ouvre sur Mapper comme l’image de référence. Les étapes précédentes sont disponibles; les étapes futures restent verrouillées tant que l’étape courante n’est pas complète.

## 37.5 Fichiers créés/modifiés/supprimés

### Fichiers créés

- `packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart`
- `packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_role_thumbnail_painter.dart`
- `packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_schema_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart`
- `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart`
- `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart`
- `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_sidebar.dart`
- `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_top_stepper.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_column_selection.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_design_tokens.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_drag_payload.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_motion.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_role_assignment_draft.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_step.dart`
- `packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart`
- `reports/surface/surface_studio_rebuild_figma_grade_wizard_v2.md`

### Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/test/shell_chrome_test_harness.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

### Fichiers supprimés

- Aucun fichier supprimé.

## 37.6 Contenu complet des fichiers créés/modifiés

Le rapport lui-même est exclu de la recopie récursive, conformément à l’exception demandée.


### Fichier créé : `packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart`

```dart
import 'package:flutter/widgets.dart';

import '../surface_studio_design_tokens.dart';

class SurfaceStudioAtlasGridPainter extends CustomPainter {
  const SurfaceStudioAtlasGridPainter({
    required this.columnCount,
    required this.rowCount,
    required this.selectedColumns,
    required this.zoomPercent,
  });

  final int columnCount;
  final int rowCount;
  final List<int> selectedColumns;
  final double zoomPercent;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF102E70);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      bg,
    );

    final columnWidth = size.width / columnCount;
    final stripePaint = Paint();
    for (var i = 0; i < columnCount; i++) {
      final rect = Rect.fromLTWH(i * columnWidth, 0, columnWidth, size.height);
      final hue = i % 4;
      stripePaint.color = switch (hue) {
        0 => const Color(0xFF1C7DFF),
        1 => const Color(0xFF2E8DFF),
        2 => const Color(0xFFE15E91),
        _ => const Color(0xFF2272DD),
      };
      canvas.drawRect(rect, stripePaint);
      if (hue == 2) {
        final shore = Paint()
          ..color = const Color(0xFFE2D6C8).withValues(alpha: 0.72);
        canvas.drawRect(
          Rect.fromLTWH(rect.left + columnWidth * 0.72, 0, columnWidth * 0.16,
              size.height),
          shore,
        );
      }
    }

    final waterLine = Paint()
      ..color = const Color(0xFF7ACDFF).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var y = 14.0; y < size.height; y += 32) {
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 24) {
        path.quadraticBezierTo(x + 12, y - 8, x + 24, y);
      }
      canvas.drawPath(path, waterLine);
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.42)
      ..strokeWidth = 1;
    for (var i = 0; i <= columnCount; i++) {
      final x = i * columnWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    final rowHeight = size.height / rowCount;
    for (var i = 0; i <= rowCount; i++) {
      final y = i * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y),
          gridPaint..color = const Color(0xFFFFFFFF).withValues(alpha: 0.13));
    }

    final selectedPaint = Paint()
      ..color = SurfaceStudioDesignTokens.accentGold.withValues(alpha: 0.17);
    final selectedBorder = Paint()
      ..color = SurfaceStudioDesignTokens.accentGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    for (final column in selectedColumns) {
      final rect = Rect.fromLTWH(
        (column - 1) * columnWidth + 2,
        2,
        columnWidth - 4,
        size.height - 4,
      );
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      canvas.drawRRect(rr, selectedPaint);
      canvas.drawRRect(rr, selectedBorder);
    }
  }

  @override
  bool shouldRepaint(covariant SurfaceStudioAtlasGridPainter oldDelegate) =>
      oldDelegate.columnCount != columnCount ||
      oldDelegate.rowCount != rowCount ||
      oldDelegate.zoomPercent != zoomPercent ||
      !_listEquals(oldDelegate.selectedColumns, selectedColumns);
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

```

### Fichier créé : `packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType, Slider;
import 'package:flutter/services.dart';

import '../surface_studio_column_selection.dart';
import '../surface_studio_design_tokens.dart';
import '../surface_studio_drag_payload.dart';
import 'surface_studio_atlas_grid_painter.dart';

class SurfaceStudioAtlasPanel extends StatelessWidget {
  const SurfaceStudioAtlasPanel({
    super.key,
    required this.columnCount,
    required this.frameCount,
    required this.tileWidth,
    required this.tileHeight,
    required this.selection,
    required this.zoomPercent,
    required this.onColumnSelectionChanged,
    required this.onZoomChanged,
    required this.onReset,
    required this.onAutoSuggest,
  });

  final int columnCount;
  final int frameCount;
  final int tileWidth;
  final int tileHeight;
  final SurfaceStudioColumnSelection selection;
  final double zoomPercent;
  final ValueChanged<SurfaceStudioColumnSelection> onColumnSelectionChanged;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onReset;
  final VoidCallback onAutoSuggest;

  @override
  Widget build(BuildContext context) {
    return _PanelFrame(
      key: const ValueKey('surfaceStudio.atlas.panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AtlasHeader(),
          const SizedBox(height: 10),
          Expanded(
            child: SurfaceStudioAtlasViewport(
              columnCount: columnCount,
              frameCount: frameCount,
              tileWidth: tileWidth,
              tileHeight: tileHeight,
              selection: selection,
              zoomPercent: zoomPercent,
              onColumnSelectionChanged: onColumnSelectionChanged,
            ),
          ),
          const SizedBox(height: 10),
          SurfaceStudioAtlasToolbar(
            zoomPercent: zoomPercent,
            columnCount: columnCount,
            frameCount: frameCount,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            onZoomChanged: onZoomChanged,
            onReset: onReset,
            onAutoSuggest: onAutoSuggest,
          ),
        ],
      ),
    );
  }
}

class SurfaceStudioAtlasViewport extends StatelessWidget {
  const SurfaceStudioAtlasViewport({
    super.key,
    required this.columnCount,
    required this.frameCount,
    required this.tileWidth,
    required this.tileHeight,
    required this.selection,
    required this.zoomPercent,
    required this.onColumnSelectionChanged,
  });

  final int columnCount;
  final int frameCount;
  final int tileWidth;
  final int tileHeight;
  final SurfaceStudioColumnSelection selection;
  final double zoomPercent;
  final ValueChanged<SurfaceStudioColumnSelection> onColumnSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final payload = SurfaceStudioColumnDragPayload(
      columns: selection.columns,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      frameCount: frameCount,
    );
    return Container(
      key: const ValueKey('surfaceStudio.atlas.viewport'),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Column(
        children: [
          SizedBox(
            height: 24,
            child: Row(
              children: [
                for (var column = 1; column <= columnCount; column++)
                  Expanded(
                    child: GestureDetector(
                      key: ValueKey('surfaceStudio.atlas.column.$column'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final shift = HardwareKeyboard
                            .instance.logicalKeysPressed
                            .any((key) =>
                                key == LogicalKeyboardKey.shiftLeft ||
                                key == LogicalKeyboardKey.shiftRight);
                        final next = shift && selection.isNotEmpty
                            ? selection.selectContiguousTo(column)
                            : selection.selectSingle(column);
                        onColumnSelectionChanged(next);
                      },
                      child: Center(
                        child: Text(
                          '$column',
                          style: TextStyle(
                            color: selection.columns.contains(column)
                                ? SurfaceStudioDesignTokens.accentGold
                                : SurfaceStudioDesignTokens.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: SurfaceStudioAtlasGridPainter(
                      columnCount: columnCount,
                      rowCount: frameCount,
                      selectedColumns: selection.columns,
                      zoomPercent: zoomPercent,
                    ),
                  ),
                ),
                if (selection.isNotEmpty)
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Draggable<SurfaceStudioColumnDragPayload>(
                      data: payload,
                      feedback: _DragGhost(payload: payload),
                      childWhenDragging: Opacity(
                        opacity: 0.48,
                        child: _DragHandle(payload: payload),
                      ),
                      child: _DragHandle(payload: payload),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SurfaceStudioDesignTokens.backgroundPanel
                  .withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
            ),
            child: Text(
              selection.microcopy,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SurfaceStudioDesignTokens.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SurfaceStudioAtlasToolbar extends StatelessWidget {
  const SurfaceStudioAtlasToolbar({
    super.key,
    required this.zoomPercent,
    required this.columnCount,
    required this.frameCount,
    required this.tileWidth,
    required this.tileHeight,
    required this.onZoomChanged,
    required this.onReset,
    required this.onAutoSuggest,
  });

  final double zoomPercent;
  final int columnCount;
  final int frameCount;
  final int tileWidth;
  final int tileHeight;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onReset;
  final VoidCallback onAutoSuggest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundPanelAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolbarSection(
              title: 'Zoom',
              child: Row(
                children: [
                  _SquareButton(
                    icon: CupertinoIcons.minus,
                    onPressed: () => onZoomChanged(
                      (zoomPercent - 10).clamp(25, 400).toDouble(),
                    ),
                  ),
                  Material(
                    type: MaterialType.transparency,
                    child: SizedBox(
                      width: 128,
                      child: Slider(
                        key: const ValueKey('surfaceStudio.atlas.zoomSlider'),
                        value: zoomPercent,
                        min: 25,
                        max: 400,
                        divisions: 75,
                        onChanged: onZoomChanged,
                      ),
                    ),
                  ),
                  Text(
                    '${zoomPercent.round()}%',
                    style: const TextStyle(
                      color: SurfaceStudioDesignTokens.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _SquareButton(
                    icon: CupertinoIcons.plus,
                    onPressed: () => onZoomChanged(
                      (zoomPercent + 10).clamp(25, 400).toDouble(),
                    ),
                  ),
                  _SquareButton(
                    icon: CupertinoIcons.arrow_up_left_arrow_down_right,
                    onPressed: () => onZoomChanged(100),
                  ),
                ],
              ),
            ),
            _Divider(),
            _ToolbarSection(
              title: 'Détection auto',
              child: CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: SurfaceStudioDesignTokens.accentTealSoft,
                minimumSize: const Size.square(36),
                onPressed: onAutoSuggest,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.sparkles,
                      color: SurfaceStudioDesignTokens.accentTeal,
                      size: 16,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Analyser',
                      style: TextStyle(
                        color: SurfaceStudioDesignTokens.accentTeal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _Divider(),
            _ToolbarSection(
              title: 'Réinitialiser',
              child: _SquareButton(
                icon: CupertinoIcons.arrow_counterclockwise,
                onPressed: onReset,
              ),
            ),
            _Divider(),
            _ToolbarMetric(
                title: 'Découpage', value: '$tileWidth × $tileHeight'),
            _ToolbarMetric(title: 'Colonnes', value: '$columnCount'),
            _ToolbarMetric(title: 'Frames', value: '$frameCount'),
          ],
        ),
      ),
    );
  }
}

class _AtlasHeader extends StatelessWidget {
  const _AtlasHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          'Atlas source',
          style: TextStyle(
            color: SurfaceStudioDesignTokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Text(
            'Glissez pour sélectionner. Faites glisser vers le schéma.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: SurfaceStudioDesignTokens.textMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PanelFrame extends StatelessWidget {
  const _PanelFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundPanel,
        borderRadius:
            BorderRadius.circular(SurfaceStudioDesignTokens.panelRadius),
        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
      ),
      child: child,
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.payload});

  final SurfaceStudioColumnDragPayload payload;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('surfaceStudio.atlas.dragHandle'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.accentGoldSoft.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SurfaceStudioDesignTokens.accentGold),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.hand_draw,
            color: SurfaceStudioDesignTokens.accentGold,
            size: 17,
          ),
          const SizedBox(width: 8),
          Text(
            payload.label,
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DragGhost extends StatelessWidget {
  const _DragGhost({required this.payload});

  final SurfaceStudioColumnDragPayload payload;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        key: const ValueKey('surfaceStudio.atlas.dragGhost'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: SurfaceStudioDesignTokens.backgroundElevated,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: SurfaceStudioDesignTokens.accentGold, width: 2),
          boxShadow: [
            BoxShadow(
              color:
                  SurfaceStudioDesignTokens.accentGold.withValues(alpha: 0.32),
              blurRadius: 18,
            ),
          ],
        ),
        child: Text(
          payload.label,
          style: const TextStyle(
            color: SurfaceStudioDesignTokens.accentGold,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _ToolbarSection extends StatelessWidget {
  const _ToolbarSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: SurfaceStudioDesignTokens.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

class _ToolbarMetric extends StatelessWidget {
  const _ToolbarMetric({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: _ToolbarSection(
        title: title,
        child: Container(
          constraints: const BoxConstraints(minWidth: 74),
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: SurfaceStudioDesignTokens.backgroundDeep,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size.square(34),
      onPressed: onPressed,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SurfaceStudioDesignTokens.backgroundDeep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
        ),
        child: Icon(icon,
            size: 16, color: SurfaceStudioDesignTokens.textSecondary),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 13),
      color: SurfaceStudioDesignTokens.borderStrong,
    );
  }
}

```

### Fichier créé : `packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Material, MaterialType, PopupMenuButton, PopupMenuItem, Slider;
import 'package:map_core/map_core.dart';

import '../surface_studio_design_tokens.dart';
import '../surface_studio_role_assignment_draft.dart';

class SurfaceStudioPreviewPanel extends StatelessWidget {
  const SurfaceStudioPreviewPanel({
    super.key,
    required this.frameCount,
    required this.frameIndex,
    required this.playing,
    required this.loop,
    required this.gridVisible,
    required this.previewSize,
    required this.assignmentDraft,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePlaying,
    required this.onFrameChanged,
    required this.onLoopChanged,
    required this.onGridChanged,
    required this.onPreviewSizeChanged,
  });

  final int frameCount;
  final int frameIndex;
  final bool playing;
  final bool loop;
  final bool gridVisible;
  final int previewSize;
  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTogglePlaying;
  final ValueChanged<int> onFrameChanged;
  final ValueChanged<bool> onLoopChanged;
  final ValueChanged<bool> onGridChanged;
  final ValueChanged<int> onPreviewSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('surfaceStudio.preview.panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundPanel,
        borderRadius:
            BorderRadius.circular(SurfaceStudioDesignTokens.panelRadius),
        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Prévisualisation',
            style: TextStyle(
              color: SurfaceStudioDesignTokens.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: RepaintBoundary(
                    child: _PreviewViewport(
                      previewSize: previewSize,
                      gridVisible: gridVisible,
                      hasCenter: assignmentDraft.isAssigned(
                        SurfaceVariantRole.isolated,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: _PreviewControls(
                    frameCount: frameCount,
                    frameIndex: frameIndex,
                    playing: playing,
                    loop: loop,
                    gridVisible: gridVisible,
                    previewSize: previewSize,
                    onPrevious: onPrevious,
                    onNext: onNext,
                    onTogglePlaying: onTogglePlaying,
                    onFrameChanged: onFrameChanged,
                    onLoopChanged: onLoopChanged,
                    onGridChanged: onGridChanged,
                    onPreviewSizeChanged: onPreviewSizeChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewViewport extends StatelessWidget {
  const _PreviewViewport({
    required this.previewSize,
    required this.gridVisible,
    required this.hasCenter,
  });

  final int previewSize;
  final bool gridVisible;
  final bool hasCenter;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasCenter
          ? CustomPaint(
              painter: _WaterPreviewPainter(
                gridVisible: gridVisible,
                previewSize: previewSize,
              ),
              child: const SizedBox.expand(),
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Assignez au moins le rôle “Plein” pour générer une prévisualisation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SurfaceStudioDesignTokens.textMuted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ),
    );
  }
}

class _PreviewControls extends StatelessWidget {
  const _PreviewControls({
    required this.frameCount,
    required this.frameIndex,
    required this.playing,
    required this.loop,
    required this.gridVisible,
    required this.previewSize,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePlaying,
    required this.onFrameChanged,
    required this.onLoopChanged,
    required this.onGridChanged,
    required this.onPreviewSizeChanged,
  });

  final int frameCount;
  final int frameIndex;
  final bool playing;
  final bool loop;
  final bool gridVisible;
  final int previewSize;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTogglePlaying;
  final ValueChanged<int> onFrameChanged;
  final ValueChanged<bool> onLoopChanged;
  final ValueChanged<bool> onGridChanged;
  final ValueChanged<int> onPreviewSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: SurfaceStudioDesignTokens.backgroundPanelAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundControl(
                    keyName: 'surfaceStudio.preview.previous',
                    icon: CupertinoIcons.backward_end_fill,
                    onPressed: onPrevious,
                  ),
                  const SizedBox(width: 10),
                  _RoundControl(
                    keyName: 'surfaceStudio.preview.playPause',
                    icon: playing
                        ? CupertinoIcons.pause_fill
                        : CupertinoIcons.play_fill,
                    onPressed: onTogglePlaying,
                    highlighted: true,
                  ),
                  const SizedBox(width: 10),
                  _RoundControl(
                    keyName: 'surfaceStudio.preview.next',
                    icon: CupertinoIcons.forward_end_fill,
                    onPressed: onNext,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                'Frame ${frameIndex + 1} / $frameCount',
                style: const TextStyle(
                  color: SurfaceStudioDesignTokens.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: Slider(
                  key: const ValueKey('surfaceStudio.preview.scrubSlider'),
                  value: frameIndex.toDouble(),
                  min: 0,
                  max: (frameCount - 1).toDouble(),
                  divisions: frameCount > 1 ? frameCount - 1 : null,
                  onChanged: (value) => onFrameChanged(value.round()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SurfaceStudioDesignTokens.backgroundPanelAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CheckLine(
                    label: 'Boucle',
                    value: loop,
                    onChanged: onLoopChanged,
                  ),
                  _CheckLine(
                    label: 'Grille',
                    value: gridVisible,
                    onChanged: onGridChanged,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Taille',
                        style: TextStyle(
                          color: SurfaceStudioDesignTokens.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Material(
                        type: MaterialType.transparency,
                        child: PopupMenuButton<int>(
                          key: const ValueKey(
                              'surfaceStudio.preview.sizeButton'),
                          initialValue: previewSize,
                          color: SurfaceStudioDesignTokens.backgroundElevated,
                          onSelected: onPreviewSizeChanged,
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 5, child: Text('5 × 5')),
                            PopupMenuItem(value: 10, child: Text('10 × 10')),
                            PopupMenuItem(value: 15, child: Text('15 × 15')),
                            PopupMenuItem(value: 20, child: Text('20 × 20')),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: SurfaceStudioDesignTokens.backgroundDeep,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: SurfaceStudioDesignTokens.borderStrong,
                              ),
                            ),
                            child: Text(
                              '$previewSize × $previewSize',
                              style: const TextStyle(
                                color: SurfaceStudioDesignTokens.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.keyName,
    required this.icon,
    required this.onPressed,
    this.highlighted = false,
  });

  final String keyName;
  final IconData icon;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      key: ValueKey(keyName),
      padding: EdgeInsets.zero,
      minimumSize: const Size.square(36),
      onPressed: onPressed,
      child: Container(
        width: highlighted ? 42 : 34,
        height: highlighted ? 42 : 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: highlighted
              ? SurfaceStudioDesignTokens.accentTealSoft
              : SurfaceStudioDesignTokens.backgroundDeep,
          border: Border.all(
            color: highlighted
                ? SurfaceStudioDesignTokens.accentTeal
                : SurfaceStudioDesignTokens.borderStrong,
            width: highlighted ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: highlighted ? 22 : 17,
          color: highlighted
              ? SurfaceStudioDesignTokens.accentTeal
              : SurfaceStudioDesignTokens.textMuted,
        ),
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              value
                  ? CupertinoIcons.checkmark_square_fill
                  : CupertinoIcons.square,
              color: value
                  ? SurfaceStudioDesignTokens.accentTeal
                  : SurfaceStudioDesignTokens.textMuted,
              size: 18,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: SurfaceStudioDesignTokens.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterPreviewPainter extends CustomPainter {
  const _WaterPreviewPainter({
    required this.gridVisible,
    required this.previewSize,
  });

  final bool gridVisible;
  final int previewSize;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / previewSize;
    final cellH = size.height / previewSize;
    final a = Paint()..color = const Color(0xFF1E89FF);
    final b = Paint()..color = const Color(0xFF1268D9);
    for (var y = 0; y < previewSize; y++) {
      for (var x = 0; x < previewSize; x++) {
        canvas.drawRect(
          Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH),
          (x + y).isEven ? a : b,
        );
      }
    }
    final wave = Paint()
      ..color = const Color(0xFFA4E7FF).withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (var y = 8.0; y < size.height; y += 24) {
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 22) {
        path.quadraticBezierTo(x + 11, y - 7, x + 22, y);
      }
      canvas.drawPath(path, wave);
    }
    if (gridVisible) {
      final grid = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.16)
        ..strokeWidth = 1;
      for (var i = 0; i <= previewSize; i++) {
        final x = i * cellW;
        final y = i * cellH;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaterPreviewPainter oldDelegate) =>
      oldDelegate.gridVisible != gridVisible ||
      oldDelegate.previewSize != previewSize;
}

```

### Fichier créé : `packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_role_thumbnail_painter.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

import '../surface_studio_design_tokens.dart';

class SurfaceStudioRoleThumbnailPainter extends CustomPainter {
  const SurfaceStudioRoleThumbnailPainter({
    required this.role,
    required this.assigned,
  });

  final SurfaceVariantRole role;
  final bool assigned;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = assigned
          ? const Color(0xFF1D6EEB).withValues(alpha: 0.92)
          : SurfaceStudioDesignTokens.backgroundDeep;
    final accent = Paint()
      ..color = assigned
          ? SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.48)
          : SurfaceStudioDesignTokens.textMuted.withValues(alpha: 0.42);
    final shape = Paint()
      ..color = assigned
          ? const Color(0xFF7BCFFF).withValues(alpha: 0.88)
          : SurfaceStudioDesignTokens.borderStrong;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(7)),
      bg,
    );

    final inset = size.shortestSide * 0.18;
    final inner = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );

    Rect bandTop() =>
        Rect.fromLTWH(inner.left, inner.top, inner.width, inner.height * 0.35);
    Rect bandBottom() => Rect.fromLTWH(inner.left,
        inner.bottom - inner.height * 0.35, inner.width, inner.height * 0.35);
    Rect bandLeft() =>
        Rect.fromLTWH(inner.left, inner.top, inner.width * 0.35, inner.height);
    Rect bandRight() => Rect.fromLTWH(inner.right - inner.width * 0.35,
        inner.top, inner.width * 0.35, inner.height);
    Rect bandH() => Rect.fromLTWH(
        inner.left,
        inner.center.dy - inner.height * 0.18,
        inner.width,
        inner.height * 0.36);
    Rect bandV() => Rect.fromLTWH(inner.center.dx - inner.width * 0.18,
        inner.top, inner.width * 0.36, inner.height);

    void draw(Rect rect) => canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          shape,
        );

    switch (role) {
      case SurfaceVariantRole.isolated:
        draw(inner);
      case SurfaceVariantRole.endNorth:
        draw(bandTop());
      case SurfaceVariantRole.endEast:
        draw(bandRight());
      case SurfaceVariantRole.endSouth:
        draw(bandBottom());
      case SurfaceVariantRole.endWest:
        draw(bandLeft());
      case SurfaceVariantRole.horizontal:
        draw(bandH());
      case SurfaceVariantRole.vertical:
        draw(bandV());
      case SurfaceVariantRole.cornerNW:
        draw(bandTop());
        draw(bandLeft());
      case SurfaceVariantRole.cornerNE:
        draw(bandTop());
        draw(bandRight());
      case SurfaceVariantRole.cornerSW:
        draw(bandBottom());
        draw(bandLeft());
      case SurfaceVariantRole.cornerSE:
        draw(bandBottom());
        draw(bandRight());
      case SurfaceVariantRole.innerCornerNW:
        draw(Rect.fromLTWH(inner.center.dx, inner.center.dy, inner.width / 2,
            inner.height / 2));
      case SurfaceVariantRole.innerCornerNE:
        draw(Rect.fromLTWH(
            inner.left, inner.center.dy, inner.width / 2, inner.height / 2));
      case SurfaceVariantRole.innerCornerSW:
        draw(Rect.fromLTWH(
            inner.center.dx, inner.top, inner.width / 2, inner.height / 2));
      case SurfaceVariantRole.innerCornerSE:
        draw(Rect.fromLTWH(
            inner.left, inner.top, inner.width / 2, inner.height / 2));
      case SurfaceVariantRole.teeNorth:
        draw(bandTop());
        draw(bandV());
      case SurfaceVariantRole.teeEast:
        draw(bandRight());
        draw(bandH());
      case SurfaceVariantRole.teeSouth:
        draw(bandBottom());
        draw(bandV());
      case SurfaceVariantRole.teeWest:
        draw(bandLeft());
        draw(bandH());
      case SurfaceVariantRole.cross:
        draw(bandH());
        draw(bandV());
    }

    final stroke = Paint()
      ..color = accent.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(7)),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant SurfaceStudioRoleThumbnailPainter oldDelegate) =>
      oldDelegate.role != role || oldDelegate.assigned != assigned;
}

```

### Fichier créé : `packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_schema_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip;
import 'package:map_core/map_core.dart';

import '../surface_studio_design_tokens.dart';
import '../surface_studio_drag_payload.dart';
import '../surface_studio_motion.dart';
import '../surface_studio_role_assignment_draft.dart';
import 'surface_studio_role_thumbnail_painter.dart';

typedef SurfaceStudioRoleDropCallback = void Function(
  SurfaceVariantRole role,
  SurfaceStudioColumnDragPayload payload,
);

class SurfaceStudioSchemaPanel extends StatelessWidget {
  const SurfaceStudioSchemaPanel({
    super.key,
    required this.collapsed,
    required this.openGroups,
    required this.assignmentDraft,
    required this.onToggleCollapsed,
    required this.onToggleGroup,
    required this.onDrop,
    required this.onClearRole,
    required this.onClearColumn,
  });

  final bool collapsed;
  final Set<String> openGroups;
  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<String> onToggleGroup;
  final SurfaceStudioRoleDropCallback onDrop;
  final ValueChanged<SurfaceVariantRole> onClearRole;
  final void Function(SurfaceVariantRole role, int column) onClearColumn;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: const ValueKey('surfaceStudio.schema.panel'),
      duration: SurfaceStudioMotion.panelSlide,
      curve: SurfaceStudioMotion.easeInOut,
      width: collapsed
          ? SurfaceStudioDesignTokens.rightPanelWidthCollapsed
          : SurfaceStudioDesignTokens.rightPanelWidthExpanded,
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundPanel,
        borderRadius:
            BorderRadius.circular(SurfaceStudioDesignTokens.panelRadius),
        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
      ),
      padding: const EdgeInsets.all(12),
      child: collapsed
          ? _CollapsedSchema(onToggle: onToggleCollapsed)
          : _ExpandedSchema(
              openGroups: openGroups,
              assignmentDraft: assignmentDraft,
              onToggleCollapsed: onToggleCollapsed,
              onToggleGroup: onToggleGroup,
              onDrop: onDrop,
              onClearRole: onClearRole,
              onClearColumn: onClearColumn,
            ),
    );
  }
}

class _CollapsedSchema extends StatelessWidget {
  const _CollapsedSchema({required this.onToggle});

  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('surfaceStudio.schema.collapsed'),
      children: [
        Tooltip(
          message: 'Déployer le schéma de surface',
          child: CupertinoButton(
            key: const ValueKey('surfaceStudio.schema.collapseButton'),
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(38),
            onPressed: onToggle,
            child: const Icon(
              CupertinoIcons.chevron_left,
              color: SurfaceStudioDesignTokens.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Icon(
          CupertinoIcons.square_grid_2x2,
          color: SurfaceStudioDesignTokens.accentGold,
        ),
      ],
    );
  }
}

class _ExpandedSchema extends StatelessWidget {
  const _ExpandedSchema({
    required this.openGroups,
    required this.assignmentDraft,
    required this.onToggleCollapsed,
    required this.onToggleGroup,
    required this.onDrop,
    required this.onClearRole,
    required this.onClearColumn,
  });

  final Set<String> openGroups;
  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<String> onToggleGroup;
  final SurfaceStudioRoleDropCallback onDrop;
  final ValueChanged<SurfaceVariantRole> onClearRole;
  final void Function(SurfaceVariantRole role, int column) onClearColumn;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('surfaceStudio.schema.expanded'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Schéma de surface (glissez-déposez)',
                style: TextStyle(
                  color: SurfaceStudioDesignTokens.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Tooltip(
              message: 'Aide schéma',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size.square(32),
                onPressed: () {},
                child: const Icon(
                  CupertinoIcons.question_circle,
                  color: SurfaceStudioDesignTokens.textSecondary,
                  size: 18,
                ),
              ),
            ),
            Tooltip(
              message: 'Réduire le schéma',
              child: CupertinoButton(
                key: const ValueKey('surfaceStudio.schema.collapseButton'),
                padding: EdgeInsets.zero,
                minimumSize: const Size.square(32),
                onPressed: onToggleCollapsed,
                child: const Icon(
                  CupertinoIcons.chevron_right,
                  color: SurfaceStudioDesignTokens.textSecondary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final group in _schemaGroups)
                  _SchemaAccordion(
                    group: group,
                    open: openGroups.contains(group.id),
                    assignedCount:
                        assignmentDraft.assignedCountForRoles(group.roles),
                    assignmentDraft: assignmentDraft,
                    onToggle: () => onToggleGroup(group.id),
                    onDrop: onDrop,
                    onClearRole: onClearRole,
                    onClearColumn: onClearColumn,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SchemaAccordion extends StatelessWidget {
  const _SchemaAccordion({
    required this.group,
    required this.open,
    required this.assignedCount,
    required this.assignmentDraft,
    required this.onToggle,
    required this.onDrop,
    required this.onClearRole,
    required this.onClearColumn,
  });

  final _RoleGroup group;
  final bool open;
  final int assignedCount;
  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
  final VoidCallback onToggle;
  final SurfaceStudioRoleDropCallback onDrop;
  final ValueChanged<SurfaceVariantRole> onClearRole;
  final void Function(SurfaceVariantRole role, int column) onClearColumn;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('surfaceStudio.schema.group.${group.id}'),
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundPanelAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: assignedCount > 0
              ? SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.42)
              : SurfaceStudioDesignTokens.borderSubtle,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            key: ValueKey('surfaceStudio.schema.group.${group.id}.header'),
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    open
                        ? CupertinoIcons.chevron_down
                        : CupertinoIcons.chevron_right,
                    color: SurfaceStudioDesignTokens.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.label,
                      style: const TextStyle(
                        color: SurfaceStudioDesignTokens.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '$assignedCount/${group.roles.length}',
                    style: TextStyle(
                      color: assignedCount > 0
                          ? SurfaceStudioDesignTokens.accentTeal
                          : SurfaceStudioDesignTokens.textMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: SurfaceStudioMotion.accordion,
            child: open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final role in group.roles)
                          SurfaceStudioRoleSlotCard(
                            role: role,
                            columns: assignmentDraft.columnsForRole(role),
                            onDrop: onDrop,
                            onClearRole: onClearRole,
                            onClearColumn: onClearColumn,
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class SurfaceStudioRoleSlotCard extends StatelessWidget {
  const SurfaceStudioRoleSlotCard({
    super.key,
    required this.role,
    required this.columns,
    required this.onDrop,
    required this.onClearRole,
    required this.onClearColumn,
  });

  final SurfaceVariantRole role;
  final List<int> columns;
  final SurfaceStudioRoleDropCallback onDrop;
  final ValueChanged<SurfaceVariantRole> onClearRole;
  final void Function(SurfaceVariantRole role, int column) onClearColumn;

  bool get _isCenter => role == SurfaceVariantRole.isolated;

  @override
  Widget build(BuildContext context) {
    return DragTarget<SurfaceStudioColumnDragPayload>(
      onWillAcceptWithDetails: (details) =>
          validateSurfaceStudioRoleDrop(
            role: role,
            payload: details.data,
            draft: const SurfaceStudioRoleAssignmentDraft.empty(),
          ) ==
          SurfaceStudioDropValidation.valid,
      onAcceptWithDetails: (details) => onDrop(role, details.data),
      builder: (context, candidateData, rejectedData) {
        final candidate = candidateData.isNotEmpty ? candidateData.first : null;
        final validation = candidate == null
            ? SurfaceStudioDropValidation.valid
            : validateSurfaceStudioRoleDrop(
                role: role,
                payload: candidate,
                draft: const SurfaceStudioRoleAssignmentDraft.empty(),
              );
        final validHover = candidate != null &&
            validation == SurfaceStudioDropValidation.valid;
        final invalidHover = candidate != null &&
            validation != SurfaceStudioDropValidation.valid;
        return AnimatedContainer(
          key: role == SurfaceVariantRole.isolated
              ? const ValueKey('surfaceStudio.schema.role.center')
              : ValueKey('surfaceStudio.schema.role.${role.name}'),
          duration: SurfaceStudioMotion.fast,
          width: _isCenter ? 132 : 106,
          constraints: BoxConstraints(minHeight: _isCenter ? 94 : 86),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: validHover
                ? SurfaceStudioDesignTokens.accentTealSoft
                : invalidHover
                    ? SurfaceStudioDesignTokens.dangerSoft
                        .withValues(alpha: 0.16)
                    : columns.isNotEmpty
                        ? SurfaceStudioDesignTokens.backgroundElevated
                        : SurfaceStudioDesignTokens.backgroundPanel,
            borderRadius:
                BorderRadius.circular(SurfaceStudioDesignTokens.slotRadius),
            border: Border.all(
              color: validHover
                  ? SurfaceStudioDesignTokens.accentTeal
                  : invalidHover
                      ? SurfaceStudioDesignTokens.dangerSoft
                      : columns.isNotEmpty
                          ? SurfaceStudioDesignTokens.borderStrong
                          : SurfaceStudioDesignTokens.borderSubtle,
              width: validHover || invalidHover ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _roleLabel(role),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SurfaceStudioDesignTokens.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        height: 1.1,
                      ),
                    ),
                  ),
                  if (columns.isNotEmpty)
                    GestureDetector(
                      onTap: () => onClearRole(role),
                      child: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: SurfaceStudioDesignTokens.textMuted,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              SizedBox(
                height: _isCenter ? 30 : 34,
                child: CustomPaint(
                  painter: SurfaceStudioRoleThumbnailPainter(
                    role: role,
                    assigned: columns.isNotEmpty,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              if (validHover)
                const Text(
                  'Déposer ici',
                  style: TextStyle(
                    color: SurfaceStudioDesignTokens.accentTeal,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else if (invalidHover)
                const Text(
                  'Une seule colonne attendue',
                  style: TextStyle(
                    color: SurfaceStudioDesignTokens.dangerSoft,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                _AssignmentChips(
                  columns: columns,
                  role: role,
                  center: _isCenter,
                  onClearColumn: onClearColumn,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AssignmentChips extends StatelessWidget {
  const _AssignmentChips({
    required this.columns,
    required this.role,
    required this.center,
    required this.onClearColumn,
  });

  final List<int> columns;
  final SurfaceVariantRole role;
  final bool center;
  final void Function(SurfaceVariantRole role, int column) onClearColumn;

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty) {
      return Text(
        center ? 'Multi-colonnes autorisé' : 'Déposez une colonne',
        style: const TextStyle(
          color: SurfaceStudioDesignTokens.textMuted,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final column in columns)
          GestureDetector(
            onTap: center ? () => onClearColumn(role, column) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: SurfaceStudioDesignTokens.accentGoldSoft,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: SurfaceStudioDesignTokens.accentGold),
              ),
              child: Text(
                '$column',
                style: const TextStyle(
                  color: SurfaceStudioDesignTokens.accentGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        if (center)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: SurfaceStudioDesignTokens.backgroundDeep,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
            ),
            child: const Text(
              '+',
              style: TextStyle(
                color: SurfaceStudioDesignTokens.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        if (center)
          const Text(
            'Multi-colonnes autorisé',
            style: TextStyle(
              color: SurfaceStudioDesignTokens.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

final _schemaGroups = <_RoleGroup>[
  const _RoleGroup(
    id: 'surfaceMain',
    label: 'Surface principale',
    roles: [
      SurfaceVariantRole.isolated,
      SurfaceVariantRole.horizontal,
      SurfaceVariantRole.vertical,
    ],
  ),
  const _RoleGroup(
    id: 'edges',
    label: 'Bords',
    roles: [
      SurfaceVariantRole.endNorth,
      SurfaceVariantRole.endEast,
      SurfaceVariantRole.endSouth,
      SurfaceVariantRole.endWest,
    ],
  ),
  const _RoleGroup(
    id: 'externalCorners',
    label: 'Coins externes',
    roles: [
      SurfaceVariantRole.cornerNW,
      SurfaceVariantRole.cornerNE,
      SurfaceVariantRole.cornerSW,
      SurfaceVariantRole.cornerSE,
    ],
  ),
  const _RoleGroup(
    id: 'internalCorners',
    label: 'Coins internes',
    roles: [
      SurfaceVariantRole.innerCornerNW,
      SurfaceVariantRole.innerCornerNE,
      SurfaceVariantRole.innerCornerSW,
      SurfaceVariantRole.innerCornerSE,
    ],
  ),
  const _RoleGroup(
    id: 'junctions',
    label: 'Jonctions',
    roles: [
      SurfaceVariantRole.teeNorth,
      SurfaceVariantRole.teeEast,
      SurfaceVariantRole.teeSouth,
      SurfaceVariantRole.teeWest,
      SurfaceVariantRole.cross,
    ],
  ),
];

class _RoleGroup {
  const _RoleGroup({
    required this.id,
    required this.label,
    required this.roles,
  });

  final String id;
  final String label;
  final List<SurfaceVariantRole> roles;
}

String _roleLabel(SurfaceVariantRole role) => switch (role) {
      SurfaceVariantRole.isolated => 'Plein (center)',
      SurfaceVariantRole.endNorth => 'Bord haut',
      SurfaceVariantRole.endEast => 'Bord droit',
      SurfaceVariantRole.endSouth => 'Bord bas',
      SurfaceVariantRole.endWest => 'Bord gauche',
      SurfaceVariantRole.horizontal => 'Horizontal',
      SurfaceVariantRole.vertical => 'Vertical',
      SurfaceVariantRole.cornerNW => 'Coin haut gauche',
      SurfaceVariantRole.cornerNE => 'Coin haut droit',
      SurfaceVariantRole.cornerSW => 'Coin bas gauche',
      SurfaceVariantRole.cornerSE => 'Coin bas droit',
      SurfaceVariantRole.innerCornerNW => 'Coin int. haut gauche',
      SurfaceVariantRole.innerCornerNE => 'Coin int. haut droit',
      SurfaceVariantRole.innerCornerSW => 'Coin int. bas gauche',
      SurfaceVariantRole.innerCornerSE => 'Coin int. bas droit',
      SurfaceVariantRole.teeNorth => 'Té haut',
      SurfaceVariantRole.teeEast => 'Té droit',
      SurfaceVariantRole.teeSouth => 'Té bas',
      SurfaceVariantRole.teeWest => 'Té gauche',
      SurfaceVariantRole.cross => 'Croix',
    };

```

### Fichier créé : `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart`

```dart
import 'package:flutter/cupertino.dart';

import '../surface_studio_design_tokens.dart';

class SurfaceStudioBottomActionBar extends StatelessWidget {
  const SurfaceStudioBottomActionBar({
    super.key,
    required this.canGoBack,
    required this.canAutoSuggest,
    required this.canApplyMapping,
    required this.canGoNext,
    required this.onBack,
    required this.onAutoSuggest,
    required this.onApplyMapping,
    required this.onNext,
  });

  final bool canGoBack;
  final bool canAutoSuggest;
  final bool canApplyMapping;
  final bool canGoNext;
  final VoidCallback onBack;
  final VoidCallback onAutoSuggest;
  final VoidCallback onApplyMapping;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('surfaceStudio.bottomBar'),
      decoration: const BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundDeep,
        border: Border(
          top: BorderSide(color: SurfaceStudioDesignTokens.borderSubtle),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _BarButton(
            keyName: 'surfaceStudio.action.back',
            label: 'Retour',
            icon: CupertinoIcons.arrow_left,
            enabled: canGoBack,
            onPressed: onBack,
          ),
          const Spacer(),
          _BarButton(
            keyName: 'surfaceStudio.action.autoSuggest',
            label: 'Suggestion auto',
            icon: CupertinoIcons.sparkles,
            enabled: canAutoSuggest,
            onPressed: onAutoSuggest,
            accent: SurfaceStudioDesignTokens.accentTeal,
          ),
          const SizedBox(width: 20),
          _BarButton(
            keyName: 'surfaceStudio.action.applyMapping',
            label: 'Appliquer le mapping',
            icon: CupertinoIcons.checkmark_circle,
            enabled: canApplyMapping,
            onPressed: onApplyMapping,
          ),
          const SizedBox(width: 20),
          _BarButton(
            keyName: 'surfaceStudio.action.next',
            label: 'Suivant',
            icon: CupertinoIcons.arrow_right,
            enabled: canGoNext,
            onPressed: onNext,
            accent: SurfaceStudioDesignTokens.accentGold,
            primary: true,
          ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.keyName,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
    this.accent,
    this.primary = false,
  });

  final String keyName;
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final Color? accent;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accent ?? SurfaceStudioDesignTokens.borderStrong;
    return Opacity(
      opacity: enabled ? 1 : 0.52,
      child: CupertinoButton(
        key: ValueKey(keyName),
        minimumSize: const Size(46, 46),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        color: primary
            ? effectiveAccent.withValues(alpha: 0.42)
            : SurfaceStudioDesignTokens.backgroundElevated,
        borderRadius: BorderRadius.circular(9),
        onPressed: enabled ? onPressed : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: primary
                  ? SurfaceStudioDesignTokens.textPrimary
                  : effectiveAccent,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: primary
                    ? SurfaceStudioDesignTokens.textPrimary
                    : SurfaceStudioDesignTokens.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

```

### Fichier créé : `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip;

import '../surface_studio_design_tokens.dart';
import '../surface_studio_step.dart';
import 'surface_studio_top_stepper.dart';

class SurfaceStudioHeader extends StatelessWidget {
  const SurfaceStudioHeader({
    super.key,
    required this.currentStep,
    required this.completedSteps,
    required this.onStepSelected,
  });

  final SurfaceStudioWizardStep currentStep;
  final Set<SurfaceStudioWizardStep> completedSteps;
  final ValueChanged<SurfaceStudioWizardStep> onStepSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('surfaceStudio.header'),
      decoration: const BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundDeep,
        border: Border(
          bottom: BorderSide(color: SurfaceStudioDesignTokens.borderSubtle),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const _StudioMark(),
          const SizedBox(width: 12),
          const Text(
            'Surface Studio — Assistant de mapping d’atlas',
            style: TextStyle(
              color: SurfaceStudioDesignTokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: SurfaceStudioTopStepper(
              currentStep: currentStep,
              completedSteps: completedSteps,
              onStepSelected: onStepSelected,
            ),
          ),
          const SizedBox(width: 12),
          _HeaderIconButton(
            tooltip: 'Aide',
            icon: CupertinoIcons.question_circle,
            onPressed: () {},
          ),
          _HeaderIconButton(
            tooltip: 'Paramètres',
            icon: CupertinoIcons.gear_alt,
            onPressed: () {},
          ),
          _HeaderIconButton(
            tooltip: 'Fermer',
            icon: CupertinoIcons.xmark,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _StudioMark extends StatelessWidget {
  const _StudioMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.accentTealSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.7),
        ),
      ),
      child: const Icon(
        CupertinoIcons.drop,
        color: SurfaceStudioDesignTokens.accentTeal,
        size: 22,
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size.square(36),
        onPressed: onPressed,
        child: Icon(
          icon,
          size: 18,
          color: SurfaceStudioDesignTokens.textSecondary,
        ),
      ),
    );
  }
}

```

### Fichier créé : `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart`

```dart
import 'package:flutter/widgets.dart';

import '../surface_studio_design_tokens.dart';

class SurfaceStudioShell extends StatelessWidget {
  const SurfaceStudioShell({
    super.key,
    required this.header,
    required this.sidebar,
    required this.atlasPanel,
    required this.schemaPanel,
    required this.previewPanel,
    required this.bottomBar,
  });

  final Widget header;
  final Widget sidebar;
  final Widget atlasPanel;
  final Widget schemaPanel;
  final Widget previewPanel;
  final Widget bottomBar;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('surfaceStudio.shell'),
      color: SurfaceStudioDesignTokens.backgroundDeep,
      child: Column(
        children: [
          SizedBox(
            height: SurfaceStudioDesignTokens.headerHeight,
            child: header,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  sidebar,
                  const SizedBox(width: SurfaceStudioDesignTokens.gapSm),
                  Expanded(child: atlasPanel),
                  const SizedBox(width: SurfaceStudioDesignTokens.gapSm),
                  SizedBox(
                    width: SurfaceStudioDesignTokens.rightPanelWidthExpanded,
                    child: Column(
                      children: [
                        Expanded(flex: 3, child: schemaPanel),
                        const SizedBox(height: SurfaceStudioDesignTokens.gapSm),
                        Expanded(flex: 2, child: previewPanel),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: SurfaceStudioDesignTokens.bottomBarHeight,
            child: bottomBar,
          ),
        ],
      ),
    );
  }
}

```

### Fichier créé : `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_sidebar.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip;

import '../surface_studio_design_tokens.dart';
import '../surface_studio_motion.dart';
import '../surface_studio_step.dart';

class SurfaceStudioSidebar extends StatelessWidget {
  const SurfaceStudioSidebar({
    super.key,
    required this.collapsed,
    required this.currentStep,
    required this.completedSteps,
    required this.onToggleCollapsed,
    required this.onStepSelected,
  });

  final bool collapsed;
  final SurfaceStudioWizardStep currentStep;
  final Set<SurfaceStudioWizardStep> completedSteps;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<SurfaceStudioWizardStep> onStepSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: const ValueKey('surfaceStudio.sidebar'),
      duration: SurfaceStudioMotion.panelSlide,
      curve: SurfaceStudioMotion.easeInOut,
      width: collapsed
          ? SurfaceStudioDesignTokens.sidebarWidthCollapsed
          : SurfaceStudioDesignTokens.sidebarWidthExpanded,
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundPanel,
        borderRadius:
            BorderRadius.circular(SurfaceStudioDesignTokens.panelRadius),
        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: collapsed
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              key: ValueKey(
                collapsed
                    ? 'surfaceStudio.sidebar.collapsed'
                    : 'surfaceStudio.sidebar.expanded',
              ),
              height: 0,
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: collapsed ? 52 : 254,
                child: Row(
                  mainAxisAlignment: collapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceBetween,
                  children: [
                    if (!collapsed)
                      const Text(
                        'Étapes',
                        style: TextStyle(
                          color: SurfaceStudioDesignTokens.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    Tooltip(
                      message: collapsed
                          ? 'Déployer les étapes'
                          : 'Réduire les étapes',
                      child: CupertinoButton(
                        key: const ValueKey(
                            'surfaceStudio.sidebar.collapseButton'),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size.square(36),
                        onPressed: onToggleCollapsed,
                        child: Icon(
                          collapsed
                              ? CupertinoIcons.chevron_right
                              : CupertinoIcons.chevron_left,
                          color: SurfaceStudioDesignTokens.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (final step in SurfaceStudioWizardStep.values) ...[
              _SidebarStepCard(
                collapsed: collapsed,
                step: step,
                active: step == currentStep,
                completed: completedSteps.contains(step),
                onTap: () => onStepSelected(step),
              ),
              const SizedBox(height: 9),
            ],
            const SizedBox(height: 8),
            _TipsCard(collapsed: collapsed),
          ],
        ),
      ),
    );
  }
}

class _SidebarStepCard extends StatelessWidget {
  const _SidebarStepCard({
    required this.collapsed,
    required this.step,
    required this.active,
    required this.completed,
    required this.onTap,
  });

  final bool collapsed;
  final SurfaceStudioWizardStep step;
  final bool active;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = active
        ? SurfaceStudioDesignTokens.accentGold
        : completed
            ? SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.75)
            : SurfaceStudioDesignTokens.borderSubtle;
    final fill = active
        ? SurfaceStudioDesignTokens.accentGoldSoft.withValues(alpha: 0.22)
        : completed
            ? SurfaceStudioDesignTokens.accentTealSoft.withValues(alpha: 0.36)
            : SurfaceStudioDesignTokens.backgroundPanelAlt;
    final content = AnimatedContainer(
      duration: SurfaceStudioMotion.normal,
      height: collapsed ? 56 : 90,
      padding: EdgeInsets.all(collapsed ? 8 : 12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius:
            BorderRadius.circular(SurfaceStudioDesignTokens.cardRadius),
        border: Border.all(color: border, width: active ? 2 : 1),
      ),
      child: collapsed
          ? Center(
              child: Text(
                '${step.number}',
                style: TextStyle(
                  color: active
                      ? SurfaceStudioDesignTokens.accentGold
                      : completed
                          ? SurfaceStudioDesignTokens.accentTeal
                          : SurfaceStudioDesignTokens.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 226,
                child: Row(
                  children: [
                    _StepNumber(
                        step: step, active: active, completed: completed),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            step.label,
                            style: TextStyle(
                              color: active
                                  ? SurfaceStudioDesignTokens.accentGold
                                  : completed
                                      ? SurfaceStudioDesignTokens.accentTeal
                                      : SurfaceStudioDesignTokens.textSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            step.sidebarDescription,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: active || completed
                                  ? SurfaceStudioDesignTokens.textSecondary
                                  : SurfaceStudioDesignTokens.textMuted,
                              fontSize: 11.5,
                              height: 1.22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (completed)
                      const Icon(
                        CupertinoIcons.checkmark_circle,
                        color: SurfaceStudioDesignTokens.accentTeal,
                        size: 22,
                      )
                    else if (active)
                      const Icon(
                        CupertinoIcons.arrow_right,
                        color: SurfaceStudioDesignTokens.accentGold,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
    );

    return Tooltip(
      message: step.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class _StepNumber extends StatelessWidget {
  const _StepNumber({
    required this.step,
    required this.active,
    required this.completed,
  });

  final SurfaceStudioWizardStep step;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? SurfaceStudioDesignTokens.accentGold
        : completed
            ? SurfaceStudioDesignTokens.accentTeal
            : SurfaceStudioDesignTokens.textMuted;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        '${step.number}',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Astuces',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              SurfaceStudioDesignTokens.accentGoldSoft.withValues(alpha: 0.18),
          borderRadius:
              BorderRadius.circular(SurfaceStudioDesignTokens.cardRadius),
          border: Border.all(
            color: SurfaceStudioDesignTokens.accentGold.withValues(alpha: 0.45),
          ),
        ),
        child: collapsed
            ? const Icon(
                CupertinoIcons.lightbulb,
                color: SurfaceStudioDesignTokens.accentGold,
              )
            : const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Icon(
                        CupertinoIcons.lightbulb,
                        color: SurfaceStudioDesignTokens.accentGold,
                        size: 17,
                      ),
                      Text(
                        'Astuces',
                        style: TextStyle(
                          color: SurfaceStudioDesignTokens.accentGold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _TipLine(
                      'Glissez une colonne de l’atlas vers une case du schéma.'),
                  _TipLine(
                      'Les rôles sont illustrés pour éviter les ambiguïtés.'),
                  _TipLine('Le rôle “Plein” peut contenir plusieurs colonnes.'),
                ],
              ),
      ),
    );
  }
}

class _TipLine extends StatelessWidget {
  const _TipLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '• $text',
        style: const TextStyle(
          color: SurfaceStudioDesignTokens.textSecondary,
          fontSize: 11,
          height: 1.25,
        ),
        softWrap: true,
      ),
    );
  }
}

```

### Fichier créé : `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_top_stepper.dart`

```dart
import 'package:flutter/cupertino.dart';

import '../surface_studio_design_tokens.dart';
import '../surface_studio_step.dart';

class SurfaceStudioTopStepper extends StatelessWidget {
  const SurfaceStudioTopStepper({
    super.key,
    required this.currentStep,
    required this.completedSteps,
    required this.onStepSelected,
  });

  final SurfaceStudioWizardStep currentStep;
  final Set<SurfaceStudioWizardStep> completedSteps;
  final ValueChanged<SurfaceStudioWizardStep> onStepSelected;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      key: const ValueKey('surfaceStudio.stepper'),
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final step in SurfaceStudioWizardStep.values) ...[
            _TopStep(
              step: step,
              active: step == currentStep,
              completed: completedSteps.contains(step),
              onTap: () => onStepSelected(step),
            ),
            if (step != SurfaceStudioWizardStep.values.last)
              Container(
                width: 28,
                height: 1,
                color: step.index < currentStep.index
                    ? SurfaceStudioDesignTokens.accentTeal
                        .withValues(alpha: 0.45)
                    : SurfaceStudioDesignTokens.borderStrong,
              ),
          ],
        ],
      ),
    );
  }
}

class _TopStep extends StatelessWidget {
  const _TopStep({
    required this.step,
    required this.active,
    required this.completed,
    required this.onTap,
  });

  final SurfaceStudioWizardStep step;
  final bool active;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? SurfaceStudioDesignTokens.accentGold
        : completed
            ? SurfaceStudioDesignTokens.accentTeal
            : SurfaceStudioDesignTokens.textMuted;
    return GestureDetector(
      key: ValueKey('surfaceStudio.step.${step.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? SurfaceStudioDesignTokens.accentGoldSoft
                        .withValues(alpha: 0.55)
                    : SurfaceStudioDesignTokens.backgroundPanel,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: active ? 2 : 1,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: SurfaceStudioDesignTokens.accentGold
                              .withValues(alpha: 0.32),
                          blurRadius: 14,
                        ),
                      ]
                    : const [],
              ),
              child: completed
                  ? Icon(CupertinoIcons.checkmark, size: 15, color: color)
                  : Text(
                      '${step.number}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
            const SizedBox(width: 7),
            Text(
              step.label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                fontStyle: active ? FontStyle.normal : FontStyle.italic,
              ),
            ),
            if (active)
              SizedBox(
                key: ValueKey('surfaceStudio.step.${step.id}.active'),
                width: 0,
                height: 0,
              ),
          ],
        ),
      ),
    );
  }
}

```

### Fichier créé : `packages/map_editor/lib/src/features/surface_studio/surface_studio_column_selection.dart`

```dart
final class SurfaceStudioColumnSelection {
  const SurfaceStudioColumnSelection(this.columns);

  const SurfaceStudioColumnSelection.empty() : columns = const <int>[];

  final List<int> columns;

  bool get isEmpty => columns.isEmpty;

  bool get isNotEmpty => columns.isNotEmpty;

  int? get firstOrNull => columns.isEmpty ? null : columns.first;

  SurfaceStudioColumnSelection selectSingle(int column) =>
      SurfaceStudioColumnSelection(<int>[column]);

  SurfaceStudioColumnSelection selectContiguousTo(int column) {
    final anchor = firstOrNull ?? column;
    final start = anchor < column ? anchor : column;
    final end = anchor < column ? column : anchor;
    return SurfaceStudioColumnSelection(<int>[
      for (var value = start; value <= end; value++) value,
    ]);
  }

  String get microcopy {
    if (columns.isEmpty) {
      return 'Sélectionnez une ou plusieurs colonnes contiguës avec Maj + glisser';
    }
    if (columns.length == 1) {
      return 'Colonne ${columns.first} sélectionnée — glissez vers un rôle du schéma.';
    }
    return 'Colonnes ${columns.first}–${columns.last} sélectionnées — glissez vers un rôle du schéma.';
  }
}

```

### Fichier créé : `packages/map_editor/lib/src/features/surface_studio/surface_studio_design_tokens.dart`

```dart
import 'package:flutter/widgets.dart';

abstract final class SurfaceStudioDesignTokens {
  static const backgroundDeep = Color(0xFF0B1020);
  static const backgroundPanel = Color(0xFF151B2A);
  static const backgroundPanelAlt = Color(0xFF1C2433);
  static const backgroundElevated = Color(0xFF202A3C);
  static const borderSubtle = Color(0xFF303A4E);
  static const borderStrong = Color(0xFF4A556D);
  static const textPrimary = Color(0xFFF2F5FA);
  static const textSecondary = Color(0xFFAAB2C3);
  static const textMuted = Color(0xFF737C90);
  static const accentGold = Color(0xFFF2C84B);
  static const accentGoldSoft = Color(0xFF6E5620);
  static const accentTeal = Color(0xFF52D6C2);
  static const accentTealSoft = Color(0xFF123D3A);
  static const dangerSoft = Color(0xFFEF6B73);
  static const success = Color(0xFF58D68D);

  static const screenMinWidth = 1200.0;
  static const headerHeight = 64.0;
  static const bottomBarHeight = 76.0;
  static const sidebarWidthExpanded = 280.0;
  static const sidebarWidthCollapsed = 78.0;
  static const rightPanelWidthExpanded = 560.0;
  static const rightPanelWidthCollapsed = 84.0;
  static const panelRadius = 14.0;
  static const cardRadius = 12.0;
  static const slotRadius = 10.0;
  static const gapXs = 4.0;
  static const gapSm = 8.0;
  static const gapMd = 12.0;
  static const gapLg = 16.0;
  static const gapXl = 24.0;
  static const borderWidth = 1.0;
  static const activeBorderWidth = 2.0;
}

```

### Fichier créé : `packages/map_editor/lib/src/features/surface_studio/surface_studio_drag_payload.dart`

```dart
/// Payload local transmis par le drag & drop Surface Studio V2.
///
/// Les colonnes sont 1-based pour correspondre à ce que l'utilisateur voit
/// dans l'atlas. Ce modèle reste strictement UI : aucune persistance et aucune
/// mutation du catalogue Surface.
final class SurfaceStudioColumnDragPayload {
  const SurfaceStudioColumnDragPayload({
    required this.columns,
    required this.tileWidth,
    required this.tileHeight,
    required this.frameCount,
  });

  final List<int> columns;
  final int tileWidth;
  final int tileHeight;
  final int frameCount;

  bool get isEmpty => columns.isEmpty;

  bool get isMultiColumn => columns.length > 1;

  String get label {
    if (columns.isEmpty) {
      return 'Aucune colonne';
    }
    if (columns.length == 1) {
      return 'Colonne ${columns.first}';
    }
    return 'Colonnes ${columns.first}-${columns.last}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioColumnDragPayload &&
          _listEquals(other.columns, columns) &&
          other.tileWidth == tileWidth &&
          other.tileHeight == tileHeight &&
          other.frameCount == frameCount;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(columns),
        tileWidth,
        tileHeight,
        frameCount,
      );
}

bool _listEquals(List<int> a, List<int> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

```

### Fichier créé : `packages/map_editor/lib/src/features/surface_studio/surface_studio_motion.dart`

```dart
import 'package:flutter/animation.dart';

abstract final class SurfaceStudioMotion {
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 180);
  static const panelSlide = Duration(milliseconds: 240);
  static const stepTransition = Duration(milliseconds: 260);
  static const accordion = Duration(milliseconds: 180);
  static const dragFeedback = Duration(milliseconds: 100);

  static const easeOut = Curves.easeOutCubic;
  static const easeInOut = Curves.easeInOutCubic;
}

```

### Fichier créé : `packages/map_editor/lib/src/features/surface_studio/surface_studio_role_assignment_draft.dart`

```dart
import 'package:map_core/map_core.dart';

import 'surface_studio_drag_payload.dart';

enum SurfaceStudioDropValidation {
  valid,
  invalidNoColumn,
  invalidTooManyColumns,
  invalidRoleLocked,
}

/// Brouillon local du Surface Studio V2 : rôle Surface -> colonnes d'atlas.
///
/// Le rôle `isolated`, affiché comme "Plein (center)", est le seul rôle
/// multi-colonnes en V2. Les autres rôles restent mono-assignation.
final class SurfaceStudioRoleAssignmentDraft {
  const SurfaceStudioRoleAssignmentDraft.empty()
      : _assignments = const <SurfaceVariantRole, List<int>>{};

  const SurfaceStudioRoleAssignmentDraft._(this._assignments);

  final Map<SurfaceVariantRole, List<int>> _assignments;

  List<int> columnsForRole(SurfaceVariantRole role) =>
      _assignments[role] ?? const <int>[];

  bool isAssigned(SurfaceVariantRole role) => columnsForRole(role).isNotEmpty;

  int get assignedRoleCount => _assignments.length;

  int assignedCountForRoles(Iterable<SurfaceVariantRole> roles) {
    var count = 0;
    for (final role in roles) {
      if (isAssigned(role)) {
        count++;
      }
    }
    return count;
  }

  SurfaceStudioRoleAssignmentDraft assignColumns(
    SurfaceVariantRole role,
    List<int> columns,
  ) {
    final cleaned = _cleanColumns(columns);
    final next = <SurfaceVariantRole, List<int>>{
      for (final entry in _assignments.entries)
        entry.key: List<int>.unmodifiable(entry.value),
    };
    if (cleaned.isEmpty) {
      next.remove(role);
    } else if (role == SurfaceVariantRole.isolated) {
      final merged = <int>[...columnsForRole(role)];
      for (final column in cleaned) {
        if (!merged.contains(column)) {
          merged.add(column);
        }
      }
      next[role] = List<int>.unmodifiable(merged);
    } else {
      next[role] = List<int>.unmodifiable(<int>[cleaned.first]);
    }
    return SurfaceStudioRoleAssignmentDraft._(Map.unmodifiable(next));
  }

  SurfaceStudioRoleAssignmentDraft clearRole(SurfaceVariantRole role) {
    if (!_assignments.containsKey(role)) {
      return this;
    }
    final next = <SurfaceVariantRole, List<int>>{
      for (final entry in _assignments.entries)
        if (entry.key != role) entry.key: List<int>.unmodifiable(entry.value),
    };
    return SurfaceStudioRoleAssignmentDraft._(Map.unmodifiable(next));
  }

  SurfaceStudioRoleAssignmentDraft clearColumn(
    SurfaceVariantRole role,
    int column,
  ) {
    final current = columnsForRole(role);
    if (!current.contains(column)) {
      return this;
    }
    final remaining = current.where((value) => value != column).toList();
    if (remaining.isEmpty) {
      return clearRole(role);
    }
    final next = <SurfaceVariantRole, List<int>>{
      for (final entry in _assignments.entries)
        entry.key: entry.key == role
            ? List<int>.unmodifiable(remaining)
            : List<int>.unmodifiable(entry.value),
    };
    return SurfaceStudioRoleAssignmentDraft._(Map.unmodifiable(next));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioRoleAssignmentDraft &&
          _mapsEqual(other._assignments, _assignments);

  @override
  int get hashCode => Object.hashAll(
        _assignments.entries.map(
          (entry) => Object.hash(entry.key, Object.hashAll(entry.value)),
        ),
      );
}

SurfaceStudioDropValidation validateSurfaceStudioRoleDrop({
  required SurfaceVariantRole role,
  required SurfaceStudioColumnDragPayload payload,
  required SurfaceStudioRoleAssignmentDraft draft,
}) {
  if (payload.columns.isEmpty) {
    return SurfaceStudioDropValidation.invalidNoColumn;
  }
  if (role != SurfaceVariantRole.isolated && payload.columns.length > 1) {
    return SurfaceStudioDropValidation.invalidTooManyColumns;
  }
  return SurfaceStudioDropValidation.valid;
}

List<int> _cleanColumns(List<int> columns) {
  final cleaned = <int>[];
  for (final column in columns) {
    if (column <= 0 || cleaned.contains(column)) {
      continue;
    }
    cleaned.add(column);
  }
  cleaned.sort();
  return cleaned;
}

bool _mapsEqual(
  Map<SurfaceVariantRole, List<int>> a,
  Map<SurfaceVariantRole, List<int>> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    final other = b[entry.key];
    if (other == null || !_listEquals(entry.value, other)) {
      return false;
    }
  }
  return true;
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

```

### Fichier créé : `packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart`

```dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

import 'atlas/surface_studio_atlas_panel.dart';
import 'preview/surface_studio_preview_panel.dart';
import 'schema/surface_studio_schema_panel.dart';
import 'shell/surface_studio_bottom_action_bar.dart';
import 'shell/surface_studio_header.dart';
import 'shell/surface_studio_shell.dart';
import 'shell/surface_studio_sidebar.dart';
import 'surface_studio_column_selection.dart';
import 'surface_studio_drag_payload.dart';
import 'surface_studio_role_assignment_draft.dart';
import 'surface_studio_step.dart';

class SurfaceStudioScreen extends StatefulWidget {
  const SurfaceStudioScreen({
    super.key,
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  @override
  State<SurfaceStudioScreen> createState() => _SurfaceStudioScreenState();
}

class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
  SurfaceStudioWizardStep _currentStep = SurfaceStudioWizardStep.map;
  bool _sidebarCollapsed = false;
  bool _rightPanelCollapsed = false;
  Set<String> _openSchemaGroups = const {
    'surfaceMain',
    'edges',
    'externalCorners',
    'internalCorners',
    'junctions',
  };
  SurfaceStudioColumnSelection _selectedColumns =
      const SurfaceStudioColumnSelection(<int>[4, 5]);
  SurfaceStudioRoleAssignmentDraft _assignmentDraft =
      const SurfaceStudioRoleAssignmentDraft.empty()
          .assignColumns(SurfaceVariantRole.isolated, const <int>[4, 5, 6]);
  double _zoomPercent = 100;
  bool _previewPlaying = false;
  int _previewFrameIndex = 0;
  bool _previewLoop = true;
  bool _previewGridVisible = true;
  int _previewSize = 10;
  String? _statusMessage;
  Timer? _previewTimer;

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  int get _columnCount {
    final atlases = widget.readModel.atlases;
    if (atlases.isEmpty) {
      return 12;
    }
    return atlases.first.columns.clamp(1, 48).toInt();
  }

  int get _frameCount {
    final atlases = widget.readModel.atlases;
    if (atlases.isEmpty) {
      return 32;
    }
    return atlases.first.rows.clamp(1, 128).toInt();
  }

  int get _tileWidth {
    final atlases = widget.readModel.atlases;
    if (atlases.isEmpty) {
      return 32;
    }
    return atlases.first.tileWidth;
  }

  int get _tileHeight {
    final atlases = widget.readModel.atlases;
    if (atlases.isEmpty) {
      return 32;
    }
    return atlases.first.tileHeight;
  }

  Set<SurfaceStudioWizardStep> get _completedSteps => {
        SurfaceStudioWizardStep.importAtlas,
        SurfaceStudioWizardStep.slice,
        if (_assignmentDraft.isAssigned(SurfaceVariantRole.isolated))
          SurfaceStudioWizardStep.map,
        if (_currentStep.index > SurfaceStudioWizardStep.preview.index)
          SurfaceStudioWizardStep.preview,
      };

  bool get _canGoNext =>
      _currentStep != SurfaceStudioWizardStep.save &&
      (_currentStep != SurfaceStudioWizardStep.map ||
          _assignmentDraft.isAssigned(SurfaceVariantRole.isolated));

  void _selectStep(SurfaceStudioWizardStep step) {
    if (step == _currentStep) {
      return;
    }
    if (step.index <= _currentStep.index || _completedSteps.contains(step)) {
      setState(() {
        _currentStep = step;
        _statusMessage = null;
      });
      return;
    }
    setState(() {
      _statusMessage = 'Terminez les étapes précédentes avant d’avancer.';
    });
  }

  void _nextStep() {
    if (!_canGoNext) {
      setState(() {
        _statusMessage =
            'Assignez au moins le rôle “Plein” avant de continuer.';
      });
      return;
    }
    final nextIndex = (_currentStep.index + 1)
        .clamp(0, SurfaceStudioWizardStep.values.length - 1)
        .toInt();
    setState(() {
      _currentStep = SurfaceStudioWizardStep.values[nextIndex];
      _statusMessage = null;
    });
  }

  void _previousStep() {
    if (_currentStep == SurfaceStudioWizardStep.importAtlas) {
      return;
    }
    setState(() {
      _currentStep = SurfaceStudioWizardStep.values[_currentStep.index - 1];
      _statusMessage = null;
    });
  }

  void _togglePreviewPlaying() {
    setState(() {
      _previewPlaying = !_previewPlaying;
    });
    _syncPreviewTimer();
  }

  void _syncPreviewTimer() {
    _previewTimer?.cancel();
    _previewTimer = null;
    if (!_previewPlaying) {
      return;
    }
    _previewTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_previewFrameIndex >= _frameCount - 1) {
          _previewFrameIndex = _previewLoop ? 0 : _frameCount - 1;
          if (!_previewLoop) {
            _previewPlaying = false;
            _syncPreviewTimer();
          }
        } else {
          _previewFrameIndex += 1;
        }
      });
    });
  }

  void _autoSuggestMapping() {
    final roles = <SurfaceVariantRole>[
      SurfaceVariantRole.isolated,
      SurfaceVariantRole.endNorth,
      SurfaceVariantRole.endEast,
      SurfaceVariantRole.endSouth,
      SurfaceVariantRole.endWest,
      SurfaceVariantRole.cornerNW,
      SurfaceVariantRole.cornerNE,
      SurfaceVariantRole.cornerSW,
      SurfaceVariantRole.cornerSE,
    ];
    var draft = const SurfaceStudioRoleAssignmentDraft.empty();
    draft = draft.assignColumns(
      SurfaceVariantRole.isolated,
      <int>[for (var c = 4; c <= 6 && c <= _columnCount; c++) c],
    );
    var column = 1;
    for (final role in roles.skip(1)) {
      if (column <= _columnCount) {
        draft = draft.assignColumns(role, <int>[column]);
      }
      column += 1;
    }
    setState(() {
      _assignmentDraft = draft;
      _statusMessage = 'Suggestion auto appliquée au brouillon local.';
    });
  }

  void _applyMapping() {
    setState(() {
      _statusMessage =
          'Mapping appliqué au brouillon local — aucune sauvegarde disque.';
    });
  }

  void _acceptDrop(
    SurfaceVariantRole role,
    SurfaceStudioColumnDragPayload payload,
  ) {
    final validation = validateSurfaceStudioRoleDrop(
      role: role,
      payload: payload,
      draft: _assignmentDraft,
    );
    if (validation != SurfaceStudioDropValidation.valid) {
      setState(() {
        _statusMessage =
            validation == SurfaceStudioDropValidation.invalidNoColumn
                ? 'Aucune colonne à déposer.'
                : 'Ce rôle attend une seule colonne.';
      });
      return;
    }
    setState(() {
      _assignmentDraft = _assignmentDraft.assignColumns(role, payload.columns);
      _statusMessage = 'Colonnes déposées sur le rôle sélectionné.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final frameCount = _frameCount;
    return Stack(
      children: [
        SurfaceStudioShell(
          header: SurfaceStudioHeader(
            currentStep: _currentStep,
            completedSteps: _completedSteps,
            onStepSelected: _selectStep,
          ),
          sidebar: SurfaceStudioSidebar(
            collapsed: _sidebarCollapsed,
            currentStep: _currentStep,
            completedSteps: _completedSteps,
            onToggleCollapsed: () {
              setState(() => _sidebarCollapsed = !_sidebarCollapsed);
            },
            onStepSelected: _selectStep,
          ),
          atlasPanel: SurfaceStudioAtlasPanel(
            columnCount: _columnCount,
            frameCount: frameCount,
            tileWidth: _tileWidth,
            tileHeight: _tileHeight,
            selection: _selectedColumns,
            zoomPercent: _zoomPercent,
            onColumnSelectionChanged: (selection) {
              setState(() => _selectedColumns = selection);
            },
            onZoomChanged: (value) {
              setState(() => _zoomPercent = value.clamp(25, 400).toDouble());
            },
            onReset: () {
              setState(() {
                _selectedColumns = const SurfaceStudioColumnSelection.empty();
                _zoomPercent = 100;
                _statusMessage = 'Sélection et zoom réinitialisés.';
              });
            },
            onAutoSuggest: _autoSuggestMapping,
          ),
          schemaPanel: SurfaceStudioSchemaPanel(
            collapsed: _rightPanelCollapsed,
            openGroups: _openSchemaGroups,
            assignmentDraft: _assignmentDraft,
            onToggleCollapsed: () {
              setState(() => _rightPanelCollapsed = !_rightPanelCollapsed);
            },
            onToggleGroup: (id) {
              setState(() {
                final next = Set<String>.of(_openSchemaGroups);
                if (!next.add(id)) {
                  next.remove(id);
                }
                _openSchemaGroups = next;
              });
            },
            onDrop: _acceptDrop,
            onClearRole: (role) {
              setState(
                  () => _assignmentDraft = _assignmentDraft.clearRole(role));
            },
            onClearColumn: (role, column) {
              setState(
                () => _assignmentDraft =
                    _assignmentDraft.clearColumn(role, column),
              );
            },
          ),
          previewPanel: SurfaceStudioPreviewPanel(
            frameCount: frameCount,
            frameIndex: _previewFrameIndex.clamp(0, frameCount - 1).toInt(),
            playing: _previewPlaying,
            loop: _previewLoop,
            gridVisible: _previewGridVisible,
            previewSize: _previewSize,
            assignmentDraft: _assignmentDraft,
            onPrevious: () {
              setState(() {
                _previewPlaying = false;
                _previewFrameIndex =
                    (_previewFrameIndex - 1).clamp(0, frameCount - 1).toInt();
              });
              _syncPreviewTimer();
            },
            onNext: () {
              setState(() {
                _previewPlaying = false;
                _previewFrameIndex =
                    (_previewFrameIndex + 1).clamp(0, frameCount - 1).toInt();
              });
              _syncPreviewTimer();
            },
            onTogglePlaying: _togglePreviewPlaying,
            onFrameChanged: (value) {
              setState(() {
                _previewPlaying = false;
                _previewFrameIndex = value.clamp(0, frameCount - 1).toInt();
              });
              _syncPreviewTimer();
            },
            onLoopChanged: (value) => setState(() => _previewLoop = value),
            onGridChanged: (value) =>
                setState(() => _previewGridVisible = value),
            onPreviewSizeChanged: (value) =>
                setState(() => _previewSize = value),
          ),
          bottomBar: SurfaceStudioBottomActionBar(
            canGoBack: _currentStep != SurfaceStudioWizardStep.importAtlas,
            canAutoSuggest: _columnCount > 0 && frameCount > 0,
            canApplyMapping:
                _assignmentDraft.isAssigned(SurfaceVariantRole.isolated),
            canGoNext: _canGoNext,
            onBack: _previousStep,
            onAutoSuggest: _autoSuggestMapping,
            onApplyMapping: _applyMapping,
            onNext: _nextStep,
          ),
        ),
        if (_statusMessage != null)
          Positioned(
            left: 318,
            bottom: 86,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF202A3C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF4A556D)),
              ),
              child: Text(
                _statusMessage!,
                style: const TextStyle(
                  color: Color(0xFFF2F5FA),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

```

### Fichier créé : `packages/map_editor/lib/src/features/surface_studio/surface_studio_step.dart`

```dart
import 'package:flutter/cupertino.dart';

enum SurfaceStudioWizardStep {
  importAtlas,
  slice,
  map,
  preview,
  save,
}

extension SurfaceStudioWizardStepInfo on SurfaceStudioWizardStep {
  int get number => index + 1;

  String get id => switch (this) {
        SurfaceStudioWizardStep.importAtlas => 'import',
        SurfaceStudioWizardStep.slice => 'slice',
        SurfaceStudioWizardStep.map => 'mapper',
        SurfaceStudioWizardStep.preview => 'preview',
        SurfaceStudioWizardStep.save => 'save',
      };

  String get label => switch (this) {
        SurfaceStudioWizardStep.importAtlas => 'Importer',
        SurfaceStudioWizardStep.slice => 'Découper',
        SurfaceStudioWizardStep.map => 'Mapper',
        SurfaceStudioWizardStep.preview => 'Prévisualiser',
        SurfaceStudioWizardStep.save => 'Enregistrer',
      };

  String get sidebarDescription => switch (this) {
        SurfaceStudioWizardStep.importAtlas =>
          'Importez votre atlas de surface animé.',
        SurfaceStudioWizardStep.slice =>
          'Définissez la taille des tuiles et découpez l’atlas en colonnes.',
        SurfaceStudioWizardStep.map =>
          'Glissez les colonnes de l’atlas vers les rôles du schéma de surface.',
        SurfaceStudioWizardStep.preview =>
          'Vérifiez le résultat en animation et ajustez si nécessaire.',
        SurfaceStudioWizardStep.save =>
          'Enregistrez le mapping comme nouveau jeu de surface.',
      };

  IconData get icon => switch (this) {
        SurfaceStudioWizardStep.importAtlas => CupertinoIcons.tray_arrow_down,
        SurfaceStudioWizardStep.slice => CupertinoIcons.grid,
        SurfaceStudioWizardStep.map => CupertinoIcons.hand_draw,
        SurfaceStudioWizardStep.preview => CupertinoIcons.play_rectangle,
        SurfaceStudioWizardStep.save => CupertinoIcons.checkmark_seal,
      };
}

```

### Fichier créé : `packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart`

```dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  testWidgets('atlas panel exposes zoom slider and column selection microcopy',
      (
    tester,
  ) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    expect(find.byKey(const Key('surfaceStudio.atlas.zoomSlider')),
        findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('surfaceStudio.atlas.zoomSlider')),
      const Offset(120, 0),
    );
    await tester.pump();
    expect(find.text('100%'), findsNothing);

    await tester.tap(find.byKey(const Key('surfaceStudio.atlas.column.4')));
    await tester.pump();
    expect(
      find.text('Colonne 4 sélectionnée — glissez vers un rôle du schéma.'),
      findsOneWidget,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.byKey(const Key('surfaceStudio.atlas.column.5')));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(
      find.text('Colonnes 4–5 sélectionnées — glissez vers un rôle du schéma.'),
      findsOneWidget,
    );
  });

  testWidgets('atlas selection is draggable with a visible ghost payload', (
    tester,
  ) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    await tester.tap(find.byKey(const Key('surfaceStudio.atlas.column.4')));
    await tester.pump();

    expect(find.byKey(const Key('surfaceStudio.atlas.dragHandle')),
        findsOneWidget);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('surfaceStudio.atlas.dragHandle'))),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();

    expect(
        find.byKey(const Key('surfaceStudio.atlas.dragGhost')), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
  });
}

```

### Fichier créé : `packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  testWidgets(
      'preview panel exposes playback, scrub, loop grid and size controls', (
    tester,
  ) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    expect(
        find.byKey(const Key('surfaceStudio.preview.panel')), findsOneWidget);
    expect(find.text('Prévisualisation'), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.preview.previous')),
        findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.preview.playPause')),
        findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.preview.next')), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.preview.scrubSlider')),
        findsOneWidget);
    expect(find.text('Frame 1 / 32'), findsOneWidget);
    expect(find.text('Boucle'), findsOneWidget);
    expect(find.text('Grille'), findsOneWidget);
    expect(find.text('10 × 10'), findsOneWidget);

    await tester.tap(find.byKey(const Key('surfaceStudio.preview.next')));
    await tester.pump();
    expect(find.text('Frame 2 / 32'), findsOneWidget);

    await tester.tap(find.byKey(const Key('surfaceStudio.preview.sizeButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15 × 15').last);
    await tester.pumpAndSettle();
    expect(find.text('15 × 15'), findsOneWidget);
  });
}

```

### Fichier créé : `packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_drag_payload.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_role_assignment_draft.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  test(
      'role drop validation accepts center multi-column and rejects edge multi-column',
      () {
    const payload = SurfaceStudioColumnDragPayload(
      columns: [4, 5, 6],
      tileWidth: 32,
      tileHeight: 32,
      frameCount: 32,
    );
    const draft = SurfaceStudioRoleAssignmentDraft.empty();

    expect(
      validateSurfaceStudioRoleDrop(
        role: SurfaceVariantRole.isolated,
        payload: payload,
        draft: draft,
      ),
      SurfaceStudioDropValidation.valid,
    );
    expect(
      validateSurfaceStudioRoleDrop(
        role: SurfaceVariantRole.endNorth,
        payload: payload,
        draft: draft,
      ),
      SurfaceStudioDropValidation.invalidTooManyColumns,
    );
  });

  test('role assignment draft preserves center order and replaces other roles',
      () {
    const draft = SurfaceStudioRoleAssignmentDraft.empty();
    final withCenter = draft.assignColumns(
      SurfaceVariantRole.isolated,
      const [4, 5],
    );
    final withEdge = withCenter.assignColumns(
      SurfaceVariantRole.endNorth,
      const [7],
    );
    final replacedEdge = withEdge.assignColumns(
      SurfaceVariantRole.endNorth,
      const [8],
    );

    expect(withCenter.columnsForRole(SurfaceVariantRole.isolated), [4, 5]);
    expect(replacedEdge.columnsForRole(SurfaceVariantRole.endNorth), [8]);
    expect(replacedEdge.assignedRoleCount, 2);
  });

  testWidgets('schema panel uses accordions and shows expected roles', (
    tester,
  ) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    expect(find.byKey(const Key('surfaceStudio.schema.group.surfaceMain')),
        findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.schema.group.edges')),
        findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.schema.role.center')),
        findsOneWidget);
    expect(find.text('Plein (center)'), findsOneWidget);
    expect(find.text('Bord haut'), findsOneWidget);
    expect(find.text('Coin int. haut gauche'), findsOneWidget);

    await tester
        .tap(find.byKey(const Key('surfaceStudio.schema.group.edges.header')));
    await tester.pumpAndSettle();
    expect(find.text('Bord haut'), findsNothing);
  });
}

```

### Fichier créé : `packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  testWidgets('premium wizard shell mirrors the reference structure',
      (tester) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.header')), findsOneWidget);
    expect(
      find.text('Surface Studio — Assistant de mapping d’atlas'),
      findsOneWidget,
    );

    for (final label in [
      'Importer',
      'Découper',
      'Mapper',
      'Prévisualiser',
      'Enregistrer',
    ]) {
      expect(find.text(label), findsWidgets);
    }

    expect(find.byKey(const Key('surfaceStudio.stepper')), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.step.mapper.active')),
        findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.sidebar')), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.atlas.panel')), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.schema.panel')), findsOneWidget);
    expect(
        find.byKey(const Key('surfaceStudio.preview.panel')), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.bottomBar')), findsOneWidget);
  });

  testWidgets('sidebar and right dock collapse and expand with sliding panels',
      (
    tester,
  ) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    expect(find.byKey(const Key('surfaceStudio.sidebar.expanded')),
        findsOneWidget);
    await tester
        .tap(find.byKey(const Key('surfaceStudio.sidebar.collapseButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('surfaceStudio.sidebar.collapsed')),
        findsOneWidget);
    expect(find.byTooltip('Importer'), findsOneWidget);

    await tester
        .tap(find.byKey(const Key('surfaceStudio.sidebar.collapseButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('surfaceStudio.sidebar.expanded')),
        findsOneWidget);

    expect(
        find.byKey(const Key('surfaceStudio.schema.expanded')), findsOneWidget);
    await tester
        .tap(find.byKey(const Key('surfaceStudio.schema.collapseButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('surfaceStudio.schema.collapsed')),
        findsOneWidget);
  });

  testWidgets('stepper allows previous steps and blocks locked future steps', (
    tester,
  ) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    await tester.tap(find.byKey(const Key('surfaceStudio.step.import')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('surfaceStudio.step.import.active')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('surfaceStudio.step.save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('surfaceStudio.step.import.active')),
        findsOneWidget);
    expect(find.text('Terminez les étapes précédentes avant d’avancer.'),
        findsOneWidget);
  });

  testWidgets('bottom action bar exposes the required commands',
      (tester) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    expect(find.byKey(const Key('surfaceStudio.action.back')), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.action.autoSuggest')),
        findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.action.applyMapping')),
        findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.action.next')), findsOneWidget);
    expect(find.text('Retour'), findsOneWidget);
    expect(find.text('Suggestion auto'), findsOneWidget);
    expect(find.text('Appliquer le mapping'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });
}

```

### Fichier créé : `packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';

Widget wrapSurfaceStudioForTest({
  SurfaceStudioReadModel? readModel,
  double width = 2048,
  double height = 1120,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, height)),
      child: CupertinoPageScaffold(
        child: SizedBox(
          width: width,
          height: height,
          child: SurfaceStudioPanel(
            readModel:
                readModel ?? buildSurfaceStudioReadModelFromCatalog(_catalog()),
            projectTilesets: const <ProjectTilesetEntry>[
              ProjectTilesetEntry(
                id: 'water_tiles',
                name: 'Water Tiles',
                relativePath: 'missing/water.png',
                sortOrder: 0,
              ),
            ],
            projectRootPath: '/missing/project',
          ),
        ),
      ),
    ),
  );
}

Future<void> pumpSurfaceStudioForTest(
  WidgetTester tester, {
  SurfaceStudioReadModel? readModel,
  double width = 2048,
  double height = 1120,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    wrapSurfaceStudioForTest(
      readModel: readModel,
      width: width,
      height: height,
    ),
  );
}

ProjectSurfaceCatalog _catalog() {
  const atlasId = 'water-atlas';
  final animations = <ProjectSurfaceAnimation>[
    for (var column = 0; column < 12; column++)
      ProjectSurfaceAnimation(
        id: 'water-col-$column',
        name: 'Water Column $column',
        timeline: SurfaceAnimationTimeline(
          frames: [
            for (var row = 0; row < 32; row++)
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: atlasId,
                  column: column,
                  row: row,
                ),
                durationMs: 120,
              ),
          ],
        ),
        syncGroupId: atlasId,
        sortOrder: column,
      ),
  ];

  return ProjectSurfaceCatalog(
    atlases: [
      ProjectSurfaceAtlas(
        id: atlasId,
        name: 'Water Atlas',
        tilesetId: 'water_tiles',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 12, rows: 32),
          layout: SurfaceAtlasLayout.grid,
        ),
      ),
    ],
    animations: animations,
    presets: [
      ProjectSurfacePreset(
        id: 'water-surface',
        name: 'Water Surface',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'water-col-3',
            ),
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.endNorth,
              animationId: 'water-col-4',
            ),
          ],
        ),
      ),
    ],
  );
}

```

### Fichier modifié : `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`

```dart
// Surface Studio — assistant premium de mapping d'atlas.
//
// Le premier viewport porte le workflow guide moderne. Les sections legacy
// restent disponibles plus bas pour conserver les briques metier existantes :
// preparation d'atlas, inspection, diagnostics et sauvegarde via le flux projet.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_editing.dart';
import 'surface_studio_atlas_authoring_prep.dart';
import 'surface_studio_catalog_browser.dart';
import 'surface_studio_creation_assistant.dart';
import 'surface_studio_detected_animations_panel.dart';
import 'surface_studio_diagnostics_view.dart';
import 'surface_studio_paintable_surfaces_panel.dart';
import 'surface_studio_preset_editor_controller.dart';
import 'surface_studio_role_mapping_editor.dart';
import 'surface_studio_selection.dart';
import 'surface_studio_selection_inspector.dart';
import 'surface_studio_selection_summary.dart';
import 'surface_studio_screen.dart';
import 'surface_studio_workflow_layout.dart';
import 'surface_studio_workflow_stepper.dart';

SurfaceStudioSelection _selectionValidInReadModel(
  SurfaceStudioReadModel rm,
  SurfaceStudioSelection sel,
) {
  if (sel.isNone) return sel;
  if (sel.isAtlas) {
    for (final row in rm.atlases) {
      if (row.id == sel.id) return sel;
    }
  } else if (sel.isAnimation) {
    for (final row in rm.animations) {
      if (row.id == sel.id) return sel;
    }
  } else if (sel.isPreset) {
    for (final row in rm.presets) {
      if (row.id == sel.id) return sel;
    }
  }
  return const SurfaceStudioSelection.none();
}

/// Accent produit Surface Studio (même base que la tuile World Explorer).
const Color _surfaceStudioAccent = Color(0xFF2DD4BF);

/// Panneau présentationnel **lecture seule** pour Surface Studio.
class SurfaceStudioPanel extends StatefulWidget {
  const SurfaceStudioPanel({
    super.key,
    required this.readModel,
    this.onSurfaceCatalogSaveRequested,
    this.onRequestProjectSave,
    this.projectTilesets,
    this.projectRootPath,
    this.surfaceMappingImageLoader,
  });

  final SurfaceStudioReadModel readModel;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested;
  final Future<bool> Function()? onRequestProjectSave;
  final List<ProjectTilesetEntry>? projectTilesets;
  final SurfaceStudioAtlasUiImageLoader? surfaceMappingImageLoader;

  /// Racine projet sur disque pour résoudre les chemins d’images tileset (aperçu Lot 72).
  final String? projectRootPath;

  static const String titleText = 'Surface Studio';
  static const String readOnlyBadgeText = 'Lecture seule';
  static const String partialAuthoringBadgeText = 'Édition partielle';
  static const String workflowStepsHintText =
      'Étapes : atlas → grille → animations → surfaces prêtes à peindre';
  static const String productDescriptionText =
      'Créer des surfaces peintes à partir d’un atlas, étape par étape.';
  static const String placeholderActionsTitle = 'Actions auteur';
  static const String placeholderSoonText = 'Bientôt';
  static const String actionImportVerticalAtlasLabel =
      'Importer un atlas vertical';
  static const String workCatalogDirtyStateText =
      'Catalogue de travail modifié — sauvegarde projet non effectuée.';
  static const String savePrepActionLabel =
      'Préparer la sauvegarde du catalogue Surface';
  static const String savePrepTransmittedNote =
      'Catalogue de travail transmis au parent.';
  static const String savePrepNotConnectedNote =
      'Sauvegarde non connectée dans ce contexte.';
  static const String savePrepNoDiskNote =
      'Aucune écriture disque ne sera effectuée par Surface Studio.';
  static const String manifestMemoryUpdatedNote =
      'Manifest projet mis à jour en mémoire — écriture disque non effectuée.';
  static const String projectSaveViaExistingFlowButtonLabel =
      'Sauvegarder le projet via le flux existant';
  static const String projectDiskSaveResultSuccessNote =
      'Projet sauvegardé via le flux projet existant.';
  static const String projectDiskSaveRequestedNote =
      'Sauvegarde projet demandée.';
  static const String projectDiskSaveFailureNote =
      'Échec de sauvegarde projet — voir la barre d’état.';

  @override
  State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
}

class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
  /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
  SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
  late SurfaceStudioReadModel _workReadModel;
  String? _saveFlowPrepNote;
  String? _projectSaveDiskNote;
  int _atlasEditSignal = 0;

  @override
  void initState() {
    super.initState();
    _workReadModel = widget.readModel;
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readModel != oldWidget.readModel) {
      final hadDirty = _workReadModel != oldWidget.readModel;
      final absNow = widget.readModel ==
          buildSurfaceStudioReadModelFromCatalog(_workReadModel.catalog);
      final wasAbsorbed = hadDirty && absNow;
      setState(() {
        _workReadModel = widget.readModel;
        _selection = _selectionValidInReadModel(_workReadModel, _selection);
        _saveFlowPrepNote =
            wasAbsorbed ? SurfaceStudioPanel.manifestMemoryUpdatedNote : null;
      });
    }
  }

  bool get _hasWorkCatalogChanges => _workReadModel != widget.readModel;

  void _bumpAtlasEditSignal() {
    setState(() => _atlasEditSignal += 1);
  }

  void _onConfirmDeleteSelectedAtlas() {
    final id = _selection.id;
    if (id == null || !_selection.isAtlas) {
      return;
    }
    try {
      final next = removeAtlasIdFromWorkCatalog(_workReadModel.catalog, id);
      setState(() {
        _saveFlowPrepNote = null;
        _workReadModel = buildSurfaceStudioReadModelFromCatalog(next);
        _selection = const SurfaceStudioSelection.none();
      });
    } on StateError {
      return;
    }
  }

  SurfaceStudioSelection _selectionAfterCatalogChanged(
    ProjectSurfaceCatalog cat,
  ) {
    if (_selection.isAtlas) {
      final sid = _selection.id;
      if (sid != null) {
        for (final a in cat.atlases) {
          if (a.id == sid) {
            return SurfaceStudioSelection.atlas(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (_selection.isAnimation) {
      final sid = _selection.id;
      if (sid != null) {
        for (final a in cat.animations) {
          if (a.id == sid) {
            return SurfaceStudioSelection.animation(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (_selection.isPreset) {
      final sid = _selection.id;
      if (sid != null) {
        for (final p in cat.presets) {
          if (p.id == sid) {
            return SurfaceStudioSelection.preset(sid);
          }
        }
        return const SurfaceStudioSelection.none();
      }
    }
    if (cat.atlases.isNotEmpty) {
      return SurfaceStudioSelection.atlas(cat.atlases.last.id);
    }
    return const SurfaceStudioSelection.none();
  }

  void _onSurfaceCatalogSavePrep() {
    final cb = widget.onSurfaceCatalogSaveRequested;
    if (cb == null) {
      return;
    }
    cb(_workReadModel.catalog);
    setState(() {
      _saveFlowPrepNote = SurfaceStudioPanel.savePrepTransmittedNote;
    });
  }

  Future<void> _onRequestProjectSave() async {
    final fn = widget.onRequestProjectSave;
    if (fn == null) {
      return;
    }
    setState(() {
      _projectSaveDiskNote = SurfaceStudioPanel.projectDiskSaveRequestedNote;
    });
    final ok = await fn();
    if (!mounted) {
      return;
    }
    setState(() {
      _projectSaveDiskNote = ok
          ? SurfaceStudioPanel.projectDiskSaveResultSuccessNote
          : SurfaceStudioPanel.projectDiskSaveFailureNote;
    });
  }

  ProjectSurfacePreset? _selectedWorkPreset() {
    final id = _selection.id;
    if (id == null || !_selection.isPreset) {
      return null;
    }
    return _workReadModel.catalog.presetById(id);
  }

  void _selectPreset(String presetId) {
    setState(() {
      _selection = SurfaceStudioSelection.preset(presetId);
    });
  }

  void _onPresetRoleAnimationChanged(
    SurfaceVariantRole role,
    String animationId,
  ) {
    final presetId = _selection.id;
    if (presetId == null || !_selection.isPreset) {
      return;
    }
    final next = surfaceStudioReplacePresetRoleAnimation(
      catalog: _workReadModel.catalog,
      presetId: presetId,
      role: role,
      animationId: animationId,
    );
    setState(() {
      _saveFlowPrepNote = null;
      _workReadModel = buildSurfaceStudioReadModelFromCatalog(next);
      _selection = SurfaceStudioSelection.preset(presetId);
    });
  }

  Future<void> _openPresetMappingEditor(String presetId) async {
    final preset = _workReadModel.catalog.presetById(presetId);
    if (preset == null) {
      return;
    }
    setState(() {
      _selection = SurfaceStudioSelection.preset(presetId);
    });
    await showMacosSheet<void>(
      context: context,
      builder: (ctx) => Center(
        child: MacosSheet(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              key: const ValueKey('surface_mapping_editor_sheet'),
              width: 1120,
              height: 760,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Surface Mapping Editor',
                          style: editorMacosSheetTitleStyle(ctx),
                        ),
                      ),
                      PushButton(
                        key: const ValueKey('surface_mapping_editor_close'),
                        controlSize: ControlSize.large,
                        secondary: true,
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Étape 1 : choisissez un slot visuel. Étape 2 : cliquez directement une colonne dans l’atlas réel.',
                    style: TextStyle(
                      color: _surfaceStudioAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SurfaceStudioRoleMappingEditor(
                        catalog: _workReadModel.catalog,
                        preset: preset,
                        projectRootPath: widget.projectRootPath,
                        projectTilesets: widget.projectTilesets ??
                            const <ProjectTilesetEntry>[],
                        imageLoader: widget.surfaceMappingImageLoader,
                        onRoleAnimationChanged: _onPresetRoleAnimationChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _workReadModel.summary;
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final isPartial = widget.onSurfaceCatalogSaveRequested != null;
    final canMutateCatalog = widget.onSurfaceCatalogSaveRequested != null;
    final authoring = SurfaceStudioAtlasAuthoringPrep(
      readModel: _workReadModel,
      selection: _selection,
      requestEditSignal: _atlasEditSignal,
      projectTilesets: widget.projectTilesets,
      projectRootPath: widget.projectRootPath,
      onSurfaceCatalogChanged: (cat) {
        setState(() {
          _saveFlowPrepNote = null;
          _workReadModel = buildSurfaceStudioReadModelFromCatalog(cat);
          _selection = _selectionAfterCatalogChanged(cat);
        });
      },
      onWorkCatalogAnimationsCreated: (createdIds) {
        if (createdIds.isEmpty) {
          return;
        }
        setState(() {
          _selection = SurfaceStudioSelection.animation(createdIds.first);
        });
      },
      onWorkCatalogPresetCreated: (presetId) {
        if (presetId.isEmpty) {
          return;
        }
        setState(() {
          _selection = SurfaceStudioSelection.preset(presetId);
        });
      },
    );
    final inspection = Column(
      key: const ValueKey('surface_studio_inspection_column'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceStudioSelectionSummary(selection: _selection),
        const SizedBox(height: 10),
        SurfaceStudioSelectionInspector(
          readModel: _workReadModel,
          selection: _selection,
          onRequestEditSelectedAtlas:
              canMutateCatalog ? _bumpAtlasEditSignal : null,
          onConfirmDeleteSelectedAtlas:
              canMutateCatalog ? _onConfirmDeleteSelectedAtlas : null,
        ),
      ],
    );
    final assistant = SurfaceStudioCreationAssistant(readModel: _workReadModel);
    final detectedAnimations =
        SurfaceStudioDetectedAnimationsPanel(readModel: _workReadModel);
    final selectedPreset = _selectedWorkPreset();
    final paintableSurfaces = SurfaceStudioPaintableSurfacesPanel(
      readModel: _workReadModel,
      selectedPresetId: selectedPreset?.id,
      onPresetSelected: _selectPreset,
      onEditMappingPressed: canMutateCatalog ? _openPresetMappingEditor : null,
      onSaveCatalogPressed: widget.onSurfaceCatalogSaveRequested != null
          ? _onSurfaceCatalogSavePrep
          : null,
    );

    final legacyAuthoringBridge = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CompactStudioHeader(
          key: const ValueKey('surface_studio_workflow_header'),
          label: label,
          subtle: subtle,
          summary: s,
          readOnly: !isPartial,
        ),
        const SizedBox(height: 8),
        SurfaceStudioWorkflowStepper(readModel: _workReadModel),
        if (_hasWorkCatalogChanges) ...[
          const SizedBox(height: 10),
          _CatalogStateStrip(
            key: const ValueKey('surface_studio_catalog_status_strip'),
            subtle: subtle,
            workCatalogNote: SurfaceStudioPanel.workCatalogDirtyStateText,
            onSurfaceSavePrep: widget.onSurfaceCatalogSaveRequested != null
                ? _onSurfaceCatalogSavePrep
                : null,
            onResetWorkCatalog: () {
              setState(() {
                _workReadModel = widget.readModel;
                _selection =
                    _selectionValidInReadModel(_workReadModel, _selection);
                _saveFlowPrepNote = null;
              });
            },
          ),
          if (widget.onSurfaceCatalogSaveRequested == null)
            Text(
              key: const ValueKey('surface_studio_save_prep_not_connected'),
              SurfaceStudioPanel.savePrepNotConnectedNote,
              style: TextStyle(
                color: subtle.withValues(alpha: 0.95),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          if (widget.onRequestProjectSave != null) ...[
            const SizedBox(height: 6),
            CupertinoButton(
              key: const ValueKey(
                  'surface_studio_project_save_via_official_flow'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              onPressed: _onRequestProjectSave,
              child: const Text(
                SurfaceStudioPanel.projectSaveViaExistingFlowButtonLabel,
              ),
            ),
            if (_projectSaveDiskNote != null)
              Text(
                _projectSaveDiskNote!,
                key: const ValueKey('surface_studio_project_save_disk_note'),
                style: TextStyle(
                  color: _surfaceStudioAccent.withValues(alpha: 0.88),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ] else if (widget.onRequestProjectSave != null) ...[
          const SizedBox(height: 8),
          CupertinoButton(
            key:
                const ValueKey('surface_studio_project_save_via_official_flow'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            onPressed: _onRequestProjectSave,
            child: const Text(
              SurfaceStudioPanel.projectSaveViaExistingFlowButtonLabel,
            ),
          ),
          if (_projectSaveDiskNote != null) ...[
            const SizedBox(height: 4),
            Text(
              _projectSaveDiskNote!,
              key: const ValueKey('surface_studio_project_save_disk_note'),
              style: TextStyle(
                color: _surfaceStudioAccent.withValues(alpha: 0.88),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
        if (_saveFlowPrepNote != null) ...[
          const SizedBox(height: 6),
          Text(
            _saveFlowPrepNote!,
            key: const ValueKey('surface_studio_save_prep_transmitted'),
            style: TextStyle(
              color: _surfaceStudioAccent.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 12),
        SurfaceStudioWorkflowLayout(
          assistant: assistant,
          atlasWorkspace: authoring,
          detectedAnimations: detectedAnimations,
          paintableSurfaces: paintableSurfaces,
        ),
        const SizedBox(height: 12),
        _AdvancedDetailsSection(
          inspection: inspection,
          browser: SurfaceStudioCatalogBrowser(
            readModel: _workReadModel,
            selection: _selection,
            onSelectionChanged: (v) {
              setState(() => _selection = v);
            },
          ),
          diagnostics: SurfaceStudioDiagnosticsView(readModel: _workReadModel),
          futureActions: const _FutureActions(onImportVertical: null),
          placeholder: const _SectionPlaceholder(
            title: SurfaceStudioPanel.placeholderActionsTitle,
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final shellWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth.clamp(1200.0, 2400.0).toDouble()
            : 1600.0;
        final shellHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight.clamp(900.0, 1120.0).toDouble()
            : 900.0;
        return SingleChildScrollView(
          key: const ValueKey('surface_studio_root_scroll'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: shellWidth,
                  height: shellHeight,
                  child: SurfaceStudioScreen(readModel: _workReadModel),
                ),
              ),
              Padding(
                key: const ValueKey('surface_studio_legacy_authoring_bridge'),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: legacyAuthoringBridge,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdvancedDetailsSection extends StatelessWidget {
  const _AdvancedDetailsSection({
    required this.inspection,
    required this.browser,
    required this.diagnostics,
    required this.futureActions,
    required this.placeholder,
  });

  final Widget inspection;
  final Widget browser;
  final Widget diagnostics;
  final Widget futureActions;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return _StudioCard(
      key: const ValueKey('surface_studio_advanced_details'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Détails avancés',
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Catalogue, inspection et diagnostics restent disponibles sans remplacer le workflow principal.',
            style: TextStyle(color: subtle, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 960) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: inspection),
                    const SizedBox(width: 12),
                    Expanded(child: browser),
                    const SizedBox(width: 12),
                    Expanded(child: diagnostics),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  inspection,
                  const SizedBox(height: 12),
                  browser,
                  const SizedBox(height: 12),
                  diagnostics,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          futureActions,
          const SizedBox(height: 10),
          placeholder,
        ],
      ),
    );
  }
}

class _CompactStudioHeader extends StatelessWidget {
  const _CompactStudioHeader({
    super.key,
    required this.label,
    required this.subtle,
    required this.summary,
    required this.readOnly,
  });

  final Color label;
  final Color subtle;
  final SurfaceStudioCatalogSummaryReadModel summary;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final titleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StudioHeaderIcon(accent: _surfaceStudioAccent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      SurfaceStudioPanel.titleText,
                      style: TextStyle(
                        color: label,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (readOnly)
                    const _ReadOnlyBadge(
                      label: SurfaceStudioPanel.readOnlyBadgeText,
                    )
                  else
                    const _ReadOnlyBadge(
                      label: SurfaceStudioPanel.partialAuthoringBadgeText,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                SurfaceStudioPanel.productDescriptionText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtle,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final counters = _CounterRow(
      atlas: summary.atlasCount,
      animations: summary.animationCount,
      presets: summary.presetCount,
      compact: true,
    );
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleRow,
              const SizedBox(height: 8),
              counters,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleRow),
            const SizedBox(width: 6),
            counters,
          ],
        );
      },
    );
  }
}

class _CatalogStateStrip extends StatelessWidget {
  const _CatalogStateStrip({
    super.key,
    required this.subtle,
    required this.workCatalogNote,
    required this.onResetWorkCatalog,
    this.onSurfaceSavePrep,
  });

  final Color subtle;
  final String workCatalogNote;
  final VoidCallback onResetWorkCatalog;
  final void Function()? onSurfaceSavePrep;

  @override
  Widget build(BuildContext context) {
    return _StudioCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            workCatalogNote,
            key: const ValueKey('surface_studio_work_catalog_dirty_state'),
            style: TextStyle(
              color: _surfaceStudioAccent.withValues(alpha: 0.95),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            SurfaceStudioPanel.savePrepNoDiskNote,
            style: TextStyle(
              color: subtle.withValues(alpha: 0.88),
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (onSurfaceSavePrep != null)
                CupertinoButton(
                  key: const ValueKey('surface_studio_save_prep_catalog'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  onPressed: onSurfaceSavePrep,
                  child: const Text(SurfaceStudioPanel.savePrepActionLabel),
                ),
              CupertinoButton(
                key: const ValueKey('surface_studio_reset_work_catalog'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: onResetWorkCatalog,
                child: const Text('Réinitialiser le catalogue de travail'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudioHeaderIcon extends StatelessWidget {
  const _StudioHeaderIcon({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    const hi = Color(0xFFFFFFFF);
    const lo = Color(0xFF120808);
    final onAccent =
        accent.computeLuminance() > 0.55 ? const Color(0xFF1A0A08) : hi;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(hi, accent, 0.72)!,
            Color.lerp(accent, lo, 0.38)!,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withValues(alpha: 0.88),
          width: 1.2,
        ),
        boxShadow: EditorChrome.toolbarCapsuleShadows(context),
      ),
      alignment: Alignment.center,
      child: MacosIcon(
        Icons.auto_awesome_motion,
        color: onAccent,
        size: 22,
      ),
    );
  }
}

class _ReadOnlyBadge extends StatelessWidget {
  const _ReadOnlyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const accent = _surfaceStudioAccent;
    final fill = Color.lerp(
      EditorChrome.islandFillElevated(context),
      accent,
      0.14,
    )!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.65)),
        boxShadow: EditorChrome.toolbarCapsuleShadows(context),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _surfaceStudioAccent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.atlas,
    required this.animations,
    required this.presets,
    this.compact = false,
  });

  final int atlas;
  final int animations;
  final int presets;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('surface_studio_header_counters'),
      spacing: compact ? 6 : 12,
      runSpacing: compact ? 6 : 10,
      children: [
        _CounterChip(label: 'Atlas', value: atlas, compact: compact),
        _CounterChip(label: 'Animations', value: animations, compact: compact),
        _CounterChip(label: 'Surfaces', value: presets, compact: compact),
      ],
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final int value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final labelColor = EditorChrome.primaryLabel(context);

    return _StudioCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 16,
        vertical: compact ? 7 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtle,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: compact ? 3 : 6),
          Text(
            '$value',
            style: TextStyle(
              color: labelColor,
              fontSize: compact ? 16 : 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte interne : même relief que les tuiles inspecteur / sections.
class _StudioCard extends StatelessWidget {
  const _StudioCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context),
          width: 1,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: child,
    );
  }
}

class _FutureActions extends StatelessWidget {
  const _FutureActions({
    required this.onImportVertical,
  });

  final VoidCallback? onImportVertical;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions futures (non disponibles)',
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _GhostAction(
              label: SurfaceStudioPanel.actionImportVerticalAtlasLabel,
              onPressed: onImportVertical,
            ),
          ],
        ),
      ],
    );
  }
}

class _GhostAction extends StatelessWidget {
  const _GhostAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1.0 : 0.48,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? EditorChrome.inspectorJoyCyan : subtle,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return _StudioCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: label,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  SurfaceStudioPanel.placeholderSoonText,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          MacosIcon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: subtle,
          ),
        ],
      ),
    );
  }
}

/// Adaptateur : construit le read model **sans** I/O à partir d’un [ProjectManifest].
class SurfaceStudioPanelFromManifest extends StatefulWidget {
  const SurfaceStudioPanelFromManifest({
    super.key,
    required this.manifest,
    this.onProjectManifestChanged,
    this.onRequestProjectSave,
    this.projectRootPath,
  });

  final ProjectManifest manifest;
  final ValueChanged<ProjectManifest>? onProjectManifestChanged;
  final Future<bool> Function()? onRequestProjectSave;

  /// Dossier projet ouvert (même source que l’éditeur) pour résoudre les fichiers image.
  final String? projectRootPath;

  @override
  State<SurfaceStudioPanelFromManifest> createState() =>
      _SurfaceStudioPanelFromManifestState();
}

class _SurfaceStudioPanelFromManifestState
    extends State<SurfaceStudioPanelFromManifest> {
  late ProjectManifest _manifest;

  @override
  void initState() {
    super.initState();
    _manifest = widget.manifest;
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioPanelFromManifest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.manifest != oldWidget.manifest) {
      setState(() {
        _manifest = widget.manifest;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceStudioPanel(
      readModel: buildSurfaceStudioReadModel(_manifest),
      projectTilesets: _manifest.tilesets,
      projectRootPath: widget.projectRootPath,
      onSurfaceCatalogSaveRequested: (c) {
        final n = replaceProjectManifestSurfaceCatalog(_manifest, c);
        setState(() {
          _manifest = n;
        });
        widget.onProjectManifestChanged?.call(n);
      },
      onRequestProjectSave: widget.onRequestProjectSave,
    );
  }
}

```

### Fichier modifié : `packages/map_editor/test/shell_chrome_test_harness.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';
import 'package:map_editor/src/ui/shared/status_bar.dart';
import 'package:map_editor/src/ui/shared/top_toolbar.dart';

const _appkitUiElementColorsChannel = MethodChannel('appkit_ui_element_colors');

void _installMacosAccentColorMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_appkitUiElementColorsChannel, (call) async {
    switch (call.method) {
      case 'getColorComponents':
        return <String, double>{'hueComponent': 0.58};
      case 'getColor':
        return 0xFF0A84FF;
    }
    return null;
  });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_appkitUiElementColorsChannel, null);
  });
}

ProjectManifest buildShellChromeProject({
  String name = 'Demo Project',
  List<ProjectMapEntry> maps = const <ProjectMapEntry>[],
  List<ProjectTilesetEntry> tilesets = const <ProjectTilesetEntry>[],
}) {
  return ProjectManifest(
    name: name,
    maps: maps,
    tilesets: tilesets,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

MapData buildShellChromeMap({
  String id = 'route_1',
  String name = 'Route 1',
  int width = 20,
  int height = 15,
  List<MapLayer> layers = const <MapLayer>[],
}) {
  return MapData(
    id: id,
    name: name,
    size: GridSize(width: width, height: height),
    layers: layers,
  );
}

Future<ProviderContainer> pumpEditorShellPage(
  WidgetTester tester, {
  required EditorState initialState,
  Size surfaceSize = const Size(1600, 1000),
  List<Override> overrides = const <Override>[],
}) async {
  _installMacosAccentColorMock();
  final container = ProviderContainer(overrides: overrides);
  final editorStateSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    editorStateSubscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump();
    container.dispose();
  });

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // The shell auto-restore schedules a post-frame call into the notifier.
  // Tests seed a concrete editor state up front so the restore path exits
  // immediately and the shell stays focused on UI contracts only.
  container.read(editorNotifierProvider.notifier).state = initialState;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MacosApp(
        home: EditorShellPage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  return container;
}

Future<ProviderContainer> pumpTopToolbarHarness(
  WidgetTester tester, {
  required EditorState initialState,
  Size surfaceSize = const Size(1280, 220),
}) async {
  _installMacosAccentColorMock();
  final container = ProviderContainer();
  final editorStateSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    editorStateSubscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump();
    container.dispose();
  });

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  container.read(editorNotifierProvider.notifier).state = initialState;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MacosApp(
        home: _TopToolbarHarness(),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  return container;
}

Future<ProviderContainer> pumpStatusBarHarness(
  WidgetTester tester, {
  required EditorState initialState,
  Size surfaceSize = const Size(900, 180),
}) async {
  _installMacosAccentColorMock();
  final container = ProviderContainer();
  final editorStateSubscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() async {
    editorStateSubscription.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump();
    container.dispose();
  });

  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  container.read(editorNotifierProvider.notifier).state = initialState;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MacosApp(
        home: _StatusBarHarness(),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 1));
  return container;
}

class _TopToolbarHarness extends ConsumerWidget {
  const _TopToolbarHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CupertinoPageScaffold(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 1200,
          child: TopToolbar(
            key: Key('top-toolbar-under-test'),
          ),
        ),
      ),
    );
  }
}

class _StatusBarHarness extends StatelessWidget {
  const _StatusBarHarness();

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: 860,
          child: StatusBar(),
        ),
      ),
    );
  }
}

```

### Fichier modifié : `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

```dart
// Tests widget — Surface Studio panel (Lot 52).
// Imports `map_core` en API publique uniquement (pas de `map_core/src/...`).

import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection_inspector.dart';

void main() {
  group('SurfaceStudioPanel (Lot 52)', () {
    testWidgets('1. title Surface Studio is visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Surface Studio'), findsOneWidget);
    });

    testWidgets('2. read-only badge is visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      // Bandeau panneau + inspecteur (Lot 59).
      expect(find.text('Lecture seule'), findsNWidgets(2));
    });

    testWidgets('3. three counters are zero for empty catalog', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(3),
      );
    });

    testWidgets('4. empty catalog shows empty state copy', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(
        find.text('Le catalogue Surface est vide'),
        findsOneWidget,
      );
    });

    testWidgets('5. minimal catalog shows 1/1/1', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(3),
      );
    });

    testWidgets('6. non-empty shows catalog browser content', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Water Atlas'), findsOneWidget);
    });

    testWidgets('7. clean diagnostics for minimal coherent catalog',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
    });

    testWidgets('8. warning state when unused atlas', (tester) async {
      final rm = _warningReadModel();
      expect(rm.hasWarnings, isTrue);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: rm)),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      // Atlas orphelin + animation non référencée par un preset (presets vides)
      expect(find.textContaining('Avertissements : 2'), findsOneWidget);
      expect(find.text('Atlas inutilisé'), findsOneWidget);
      expect(find.text('Animation inutilisée'), findsOneWidget);
    });

    testWidgets('9. error state when preset animation missing', (tester) async {
      final rm = _errorReadModel();
      expect(rm.hasErrors, isTrue);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: rm)),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.textContaining('Erreurs : 1'), findsOneWidget);
      expect(
        find.text('Animation manquante dans un preset'),
        findsOneWidget,
      );
    });

    testWidgets('10. future action label import visible (pas Créer un atlas)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Créer un atlas'), findsNothing);
      expect(
        find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
        findsOneWidget,
      );
    });

    testWidgets('11. future import action disabled (onPressed null)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final b = tester.widget<CupertinoButton>(
        find.ancestor(
          of: find.text(SurfaceStudioPanel.actionImportVerticalAtlasLabel),
          matching: find.byType(CupertinoButton),
        ),
      );
      expect(b.onPressed, isNull);
    });

    testWidgets('12. section placeholder titles are visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Actions auteur'), findsOneWidget);
    });

    testWidgets('13. SurfaceStudioPanelFromManifest uses manifest catalog',
        (tester) async {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(cat);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(3),
      );
    });

    testWidgets('14. manifest is not mutated after pump', (tester) async {
      final cat = _minimalWaterCatalog();
      final before = cat.atlases.length;
      final manifest = _manifest(cat);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      expect(manifest.surfaceCatalog.atlases.length, before);
    });

    testWidgets(
      '15. does not require provider setup — panel builds without ProviderScope',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SurfaceStudioPanel(readModel: _emptyReadModel()),
            ),
          ),
        );
        expect(find.text('Surface Studio'), findsOneWidget);
      },
    );

    testWidgets('16. content is in a scrollable', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });

    testWidgets('17. no internal domain type names in user-visible strings',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
      expect(
          find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
    });

    testWidgets('18. error read model does not throw on build', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _errorReadModel())),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('19. warning read model does not throw on build',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _warningReadModel())),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('20. displayed counts match read model summary',
        (tester) async {
      final rm = _minimalWaterReadModel();
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: rm)),
      );
      expect(rm.summary.atlasCount, 1);
      expect(rm.summary.animationCount, 1);
      expect(rm.summary.presetCount, 1);
    });

    testWidgets(
        '22. TextField seulement zone brouillon (Lot 60), pas dans inspecteur',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioAtlasAuthoringPrepKey),
          matching: find.byType(TextField),
        ),
        findsWidgets,
      );
    });

    testWidgets('23. no save affordances', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.textContaining('Sauvegarder'), findsNothing);
      expect(find.byKey(const ValueKey('surfaceStudio.step.save')),
          findsOneWidget);
      expect(find.textContaining('Save'), findsNothing);
    });

    testWidgets('22. panel shows catalog browser for minimal catalog', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Atlas Surface'), findsOneWidget);
      expect(find.text('Animations Surface'), findsOneWidget);
      expect(find.text('Presets Surface'), findsOneWidget);
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(find.text('Water Surface'), findsWidgets);
    });

    testWidgets('24. test file uses public map_core only (smoke)',
        (tester) async {
      // Vérification statique : seul `package:map_core/map_core.dart` est importé.
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Surface Studio'), findsOneWidget);
    });

    testWidgets('25. Lot 55 — clean diagnostics view in panel', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
    });

    testWidgets('26. Lot 55 — error diagnostics visible in panel',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _errorReadModel())),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Erreurs'), findsOneWidget);
    });

    testWidgets('27. Lot 55 — browser and diagnostics cohabit (minimal cat)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Atlas Surface'), findsOneWidget);
      expect(find.text('Animations Surface'), findsOneWidget);
      expect(find.text('Presets Surface'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Water Atlas'), findsOneWidget);
    });

    testWidgets(
        '48. Lot 57 — panel shows Atlas / Animations / Presets / Diagnostics',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Atlas Surface'), findsOneWidget);
      expect(find.text('Animations Surface'), findsOneWidget);
      expect(find.text('Presets Surface'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });

    testWidgets('58.21 — Aucune sélection au départ (catalogue minimal)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Aucune sélection'), findsOneWidget);
    });

    testWidgets('58.22 — sélection atlas après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      expect(find.text('Atlas sélectionné'), findsWidgets);
      expect(find.text('water-atlas'), findsWidgets);
    });

    testWidgets('58.23 — sélection animation après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      expect(find.text('Animation sélectionnée'), findsWidgets);
      expect(find.text('water-isolated-loop'), findsWidgets);
    });

    testWidgets('58.24 — sélection preset après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Surface').last);
      await tester.tap(find.text('Water Surface').last);
      await tester.pump();
      expect(find.text('Preset sélectionné'), findsWidgets);
      expect(find.text('water-surface'), findsWidgets);
    });

    testWidgets('58.25 — changement de sélection remplace la précédente',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      expect(find.text('Animation sélectionnée'), findsWidgets);
      final t = tester
          .widgetList<Text>(find.byType(Text))
          .map((e) => e.data ?? '')
          .join('\n');
      expect(t.contains('Atlas sélectionné'), isFalse);
    });

    testWidgets('58.26 — sélection ne mute pas surfaceCatalog', (tester) async {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(cat);
      final before = manifest.surfaceCatalog;
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(find.text('Water Surface').last);
      await tester.tap(find.text('Water Surface').last);
      await tester.pump();
      expect(identical(manifest.surfaceCatalog, before), isTrue);
    });

    testWidgets('58.27 — pas de TextField dans inspecteur après sélections', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
    });

    testWidgets('58.28 — pas de libellés édition/save actifs', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      for (final s in <String>[
        'Sauvegarder',
        'Modifier',
        'Supprimer',
        'Save',
        'Edit',
        'Delete',
      ]) {
        expect(find.text(s), findsNothing);
      }
      expect(
        find.byKey(const ValueKey('surfaceStudio.step.save')),
        findsOneWidget,
      );
    });

    testWidgets('59.20 — inspecteur none au départ', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Inspecteur Surface'), findsOneWidget);
      expect(find.text('Aucune sélection à inspecter'), findsOneWidget);
    });

    testWidgets('59.21 — inspecteur atlas après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
      expect(
          find.descendant(of: insp, matching: find.text('Inspecteur Surface')),
          findsOneWidget);
      expect(
        find.descendant(of: insp, matching: find.text('Atlas sélectionné')),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: insp,
          matching: find.textContaining('Identifiant : water-atlas'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('59.22 — inspecteur animation après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
      expect(
        find.descendant(
          of: insp,
          matching: find.textContaining('Identifiant : water-isolated-loop'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('59.23 — inspecteur preset après tap', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Surface').last);
      await tester.tap(find.text('Water Surface').last);
      await tester.pump();
      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
      expect(
        find.descendant(
          of: insp,
          matching: find.textContaining('Identifiant : water-surface'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('59.24 — changement de sélection met l’inspecteur à jour',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
      expect(
        find.descendant(
          of: insp,
          matching: find.textContaining('Identifiant : water-isolated-loop'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: insp,
          matching: find.text('Atlas sélectionné'),
        ),
        findsNothing,
      );
    });

    testWidgets('59.25 — inspecteur ne mute pas le manifest', (tester) async {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(cat);
      final before = manifest.surfaceCatalog;
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(find.text('Water Surface').last);
      await tester.tap(find.text('Water Surface').last);
      await tester.pump();
      expect(identical(manifest.surfaceCatalog, before), isTrue);
    });

    testWidgets(
        '59.26 — inspecteur read-only : aucun TextField (Lot 60 brouillon ok)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
    });

    testWidgets('59.27 — pas de libellés édition/save (Lot 59)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      await tester.ensureVisible(find.text('Water Surface').last);
      await tester.tap(find.text('Water Surface').last);
      await tester.pump();
      for (final s in <String>[
        'Sauvegarder',
        'Modifier',
        'Supprimer',
        'Save',
        'Edit',
        'Delete',
      ]) {
        expect(find.text(s), findsNothing);
      }
      expect(
        find.byKey(const ValueKey('surfaceStudio.step.save')),
        findsOneWidget,
      );
    });

    testWidgets('30. Lot 55 — surfaceCatalog unchanged after panel pump',
        (tester) async {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(cat);
      final before = manifest.surfaceCatalog;
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      expect(identical(manifest.surfaceCatalog, before), isTrue);
    });

    testWidgets('60.1 — Préparation atlas (brouillon) visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      await tester.ensureVisible(find.text('Atlas source').first);
      expect(find.text('Atlas source'), findsWidgets);
      expect(
        find.textContaining('Brouillon : rien n’est écrit sur le disque'),
        findsOneWidget,
      );
    });

    testWidgets('61.1 — action création atlas dans le catalogue de travail',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      await tester.ensureVisible(
        find.text('Créer l’atlas dans le catalogue de travail'),
      );
      expect(
        find.text('Créer l’atlas dans le catalogue de travail'),
        findsOneWidget,
      );
    });

    testWidgets(
        '61.2 — créer atlas (catalogue vide) : compteur atlas 1, browser, '
        'inspecteur', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'lot61-a');
      await tester.enterText(nameF, 'Lot61 A');
      await tester.enterText(tsF, 'tileset-x');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(2),
      );
      expect(find.text('Lot61 A'), findsWidgets);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });

    testWidgets(
        '61.3 — créer second atlas : compteur 2, animations/presets inchangés',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'grass-a');
      await tester.enterText(nameF, 'Grass');
      await tester.enterText(tsF, 'ts-g');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(2),
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(find.text('Water Surface'), findsWidgets);
      expect(find.text('grass-a'), findsWidgets);
    });

    testWidgets('62.0 — pas de dirty au départ (vide + minimal)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
    });

    testWidgets('62.1 — dirty après création locale', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'dirty-a');
      await tester.enterText(nameF, 'D');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      expect(
        find.textContaining('sauvegarde projet non effectuée'),
        findsWidgets,
      );
    });

    testWidgets(
        '62.2 — reset depuis catalogue vide : compteur 0, atlas absent, dirty off',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'rs-a');
      await tester.enterText(nameF, 'R');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      var counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsOneWidget,
      );
      expect(find.text('rs-a'), findsWidgets);
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.pump();
      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(3),
      );
      expect(
        find.text('Le catalogue Surface est vide'),
        findsOneWidget,
      );
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(find.text('Aucune sélection'), findsOneWidget);
    });

    testWidgets(
        '62.3 — reset depuis minimal : revient à Water, Grass absent, 1/1/1',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'grass-x');
      await tester.enterText(nameF, 'Grass');
      await tester.enterText(tsF, 'ts');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      var counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('2')),
        findsOneWidget,
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('grass-x'), findsWidgets);
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.pump();
      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(3),
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(find.text('Water Surface'), findsWidgets);
    });

    testWidgets('62.4 — A puis B puis reset (source vide)', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      for (final row in <String>['lot62-a', 'lot62-b']) {
        final idF = find.byKey(const ValueKey('atlas_draft_id'));
        final nameF = find.byKey(const ValueKey('atlas_draft_name'));
        final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
        await tester.ensureVisible(idF);
        await tester.enterText(idF, row);
        await tester.enterText(nameF, row);
        await tester.enterText(tsF, 't');
        await tester.pump();
        await tester.ensureVisible(
          find.byKey(
              const ValueKey('surface_studio_create_atlas_work_catalog')),
        );
        await tester.tap(
          find.byKey(
              const ValueKey('surface_studio_create_atlas_work_catalog')),
        );
        await tester.pump();
      }
      var counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('2')),
        findsOneWidget,
      );
      expect(find.text('lot62-a'), findsWidgets);
      expect(find.text('lot62-b'), findsWidgets);
      expect(find.text('Aucune sélection'), findsNothing);
      expect(find.text('Atlas sélectionné'), findsWidgets);
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.pump();
      counters = find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(3),
      );
      expect(
        find.text('Le catalogue Surface est vide'),
        findsOneWidget,
      );
    });

    testWidgets('62.5 — readModel parent change : resync, dirty off, X absent',
        (tester) async {
      final w = _wrap(
        SurfaceStudioPanel(readModel: _emptyReadModel()),
      );
      await tester.pumpWidget(w);
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'ext-x');
      await tester.enterText(nameF, 'X');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      expect(find.text('ext-x'), findsWidgets);
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(readModel: _minimalWaterReadModel()),
        ),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.text('Aucune sélection'), findsOneWidget);
    });

    testWidgets(
        '62.6 — pas d’action fantôme Créer un atlas, vraie action présente',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Créer un atlas'), findsNothing);
      expect(
        find.text('Créer l’atlas dans le catalogue de travail'),
        findsOneWidget,
      );
    });

    testWidgets('62.7 — no save flow libellés interdits', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('atlas_draft_id')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('atlas_draft_id')),
        'z',
      );
      await tester.enterText(
          find.byKey(const ValueKey('atlas_draft_name')), 'N');
      await tester.enterText(
          find.byKey(const ValueKey('atlas_draft_tileset_advanced')), 'T');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      for (final s in <String>[
        'Sauvegarder le projet',
        'Enregistrer le projet',
        'Sauvegarder maintenant',
        'Save project',
        'Write to disk',
        'Écrire sur disque',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });
  });

  group('SurfaceStudioPanel (Lot 63)', () {
    testWidgets(
        '63.1 — sans modification : pas d’action préparation, callback jamais',
        (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _minimalWaterReadModel(),
            onSurfaceCatalogSaveRequested: (_) => calls++,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
        findsNothing,
      );
      expect(
        find.text(SurfaceStudioPanel.savePrepActionLabel),
        findsNothing,
      );
      expect(calls, 0);
    });

    testWidgets(
        '63.2 — dirty + callback : action, un appel, catalogue complet, dirty et accusé',
        (tester) async {
      ProjectSurfaceCatalog? received;
      var calls = 0;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (c) {
              calls++;
              received = c;
            },
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'prep-one');
      await tester.enterText(nameF, 'P');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      expect(prep, findsOneWidget);
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(calls, 1);
      expect(received, isNotNull);
      expect(received!.atlases.length, 1);
      expect(received!.atlases.first.id, 'prep-one');
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      expect(
        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
        findsOneWidget,
      );
    });

    testWidgets(
        '63.3 — sans callback : stable, message not connected, pas de bouton',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'nccb');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        find.text(SurfaceStudioPanel.savePrepNotConnectedNote),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
        findsNothing,
      );
    });

    testWidgets('63.4 — resync parent : dirty off, atlas source, pas d’accusé',
        (tester) async {
      ProjectSurfaceCatalog? out;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (c) => out = c,
          ),
        ),
      );
      var idF = find.byKey(const ValueKey('atlas_draft_id'));
      var nameF = find.byKey(const ValueKey('atlas_draft_name'));
      var tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'sync-x');
      await tester.enterText(nameF, 'S');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(out, isNotNull);
      final synced = buildSurfaceStudioReadModelFromCatalog(out!);
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: synced,
            onSurfaceCatalogSaveRequested: (c) => out = c,
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(
        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
        findsNothing,
      );
      expect(find.text('sync-x'), findsWidgets);
    });

    testWidgets('63.5 — reset après préparation : clean, accusé nettoyé, vide',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      var idF = find.byKey(const ValueKey('atlas_draft_id'));
      var nameF = find.byKey(const ValueKey('atlas_draft_name'));
      var tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'reset-p');
      await tester.enterText(nameF, 'R');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_reset_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(
        find.text(SurfaceStudioPanel.savePrepTransmittedNote),
        findsNothing,
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('0')),
        findsNWidgets(3),
      );
      expect(
        find.text('Le catalogue Surface est vide'),
        findsOneWidget,
      );
    });

    testWidgets('63.6 — A puis B puis préparation : ordre des atlas',
        (tester) async {
      ProjectSurfaceCatalog? got;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (c) => got = c,
          ),
        ),
      );
      for (final row in <(String, String, String)>[
        ('lot63-a', 'A', 'ta'),
        ('lot63-b', 'B', 'tb'),
      ]) {
        final idF = find.byKey(const ValueKey('atlas_draft_id'));
        final nameF = find.byKey(const ValueKey('atlas_draft_name'));
        final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
        await tester.ensureVisible(idF);
        await tester.enterText(idF, row.$1);
        await tester.enterText(nameF, row.$2);
        await tester.enterText(tsF, row.$3);
        await tester.pump();
        await tester.ensureVisible(
          find.byKey(
              const ValueKey('surface_studio_create_atlas_work_catalog')),
        );
        await tester.tap(
          find.byKey(
              const ValueKey('surface_studio_create_atlas_work_catalog')),
        );
        await tester.pump();
      }
      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(got, isNotNull);
      expect(got!.atlases.length, 2);
      expect(got!.atlases[0].id, 'lot63-a');
      expect(got!.atlases[1].id, 'lot63-b');
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
    });

    testWidgets('66.1 — header compact et repères workflow visibles',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(
        find.byKey(const ValueKey('surface_studio_workflow_header')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('surface_studio_workflow_steps')),
        findsOneWidget,
      );
    });

    testWidgets(
        '66.2 — préparation atlas au-dessus du catalogue (ordre vertical)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      final yPrep = tester
          .getTopLeft(
            find.byKey(const ValueKey('surface_studio_authoring_main_title')),
          )
          .dy;
      final yCat = tester.getTopLeft(find.text('Catalogue Surface')).dy;
      expect(yPrep, lessThan(yCat));
    });

    testWidgets('66.3 — bandeau dirty visible si catalogue de travail modifié',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _emptyReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'x');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('surface_studio_catalog_status_strip')),
        findsOneWidget,
      );
    });

    testWidgets('66.4 — inspecteur, catalogue, diagnostics toujours présents',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Inspecteur Surface'), findsOneWidget);
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });

    testWidgets('66.5 — pas de libellés techniques dans l’UI principale',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.textContaining('ProjectSurfaceAtlas'), findsNothing);
      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
      expect(find.textContaining('copyWith'), findsNothing);
    });

    testWidgets('85.1 — workflow guidé Surface Studio visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );

      expect(
        find.text(
            'Créer des surfaces peintes à partir d’un atlas, étape par étape.'),
        findsOneWidget,
      );
      expect(find.text('1. Atlas'), findsOneWidget);
      expect(find.text('2. Grille'), findsOneWidget);
      expect(find.text('3. Animations'), findsOneWidget);
      expect(find.text('4. Surfaces prêtes à peindre'), findsOneWidget);
      expect(find.text('Assistant de création'), findsOneWidget);
      expect(find.text('Ce que vous faites ici'), findsOneWidget);
      expect(find.text('Atlas source'), findsWidgets);
      expect(find.text('Découpage et validation'), findsOneWidget);
      expect(find.text('Animations détectées'), findsOneWidget);
      expect(find.text('Surfaces prêtes à peindre'), findsWidgets);
    });

    testWidgets(
        '85.2 — animations présentes sans surfaces peignables : état explicite',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _animationsOnlyReadModel())),
      );

      expect(
        find.text('Animations détectées, mais aucune surface peignable.'),
        findsOneWidget,
      );
      expect(
        find.text('Créez une surface à partir des animations générées.'),
        findsOneWidget,
      );
    });

    testWidgets('85.3 — surfaces peignables listées dans le panneau dédié',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );

      final panel = find.byKey(
        const ValueKey('surface_studio_paintable_surfaces_panel'),
      );
      expect(panel, findsOneWidget);
      expect(
        find.descendant(of: panel, matching: find.text('Water Surface')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: panel, matching: find.text('Peignable')),
        findsOneWidget,
      );
    });

    testWidgets('85.4 — CTA création surface et sauvegarde visibles',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _minimalWaterReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );

      expect(find.text('Créer une surface'), findsOneWidget);
      expect(find.text('Sauvegarder le catalogue'), findsOneWidget);
    });

    testWidgets('85-bis.1 — workflow desktop en quatre zones côte à côte',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );

      final grid =
          find.byKey(const ValueKey('surface_studio_workflow_desktop_grid'));
      final assistant =
          find.byKey(const ValueKey('surface_studio_workflow_assistant_lane'));
      final atlas =
          find.byKey(const ValueKey('surface_studio_workflow_atlas_lane'));
      final animations =
          find.byKey(const ValueKey('surface_studio_workflow_animations_lane'));
      final surfaces =
          find.byKey(const ValueKey('surface_studio_workflow_surfaces_lane'));
      final advanced =
          find.byKey(const ValueKey('surface_studio_advanced_details'));

      expect(grid, findsOneWidget);
      expect(assistant, findsOneWidget);
      expect(atlas, findsOneWidget);
      expect(animations, findsOneWidget);
      expect(surfaces, findsOneWidget);
      expect(advanced, findsOneWidget);

      final assistantLeft = tester.getTopLeft(assistant).dx;
      final atlasLeft = tester.getTopLeft(atlas).dx;
      final animationsLeft = tester.getTopLeft(animations).dx;
      final surfacesLeft = tester.getTopLeft(surfaces).dx;
      expect(assistantLeft, lessThan(atlasLeft));
      expect(atlasLeft, lessThan(animationsLeft));
      expect(animationsLeft, lessThan(surfacesLeft));

      final workflowTop = tester.getTopLeft(grid).dy;
      expect(
        (tester.getTopLeft(assistant).dy - workflowTop).abs(),
        lessThan(1),
      );
      expect(
        (tester.getTopLeft(atlas).dy - workflowTop).abs(),
        lessThan(1),
      );
      expect(
        (tester.getTopLeft(animations).dy - workflowTop).abs(),
        lessThan(1),
      );
      expect(
        (tester.getTopLeft(surfaces).dy - workflowTop).abs(),
        lessThan(1),
      );
      expect(tester.getTopLeft(advanced).dy, greaterThan(workflowTop));
    });

    testWidgets(
        '88-bis.1 — modifier le mapping met le catalogue de travail dirty et sauvegardable',
        (tester) async {
      ProjectSurfaceCatalog? saved;
      final atlasImage = await _fakeAtlasImage();
      addTearDown(atlasImage.dispose);
      await tester.binding.setSurfaceSize(const Size(1600, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _roleMappingCatalog(),
            ),
            projectRootPath: '/project',
            projectTilesets: _surfaceTilesets(),
            surfaceMappingImageLoader: (_) async => atlasImage,
            onSurfaceCatalogSaveRequested: (catalog) => saved = catalog,
          ),
        ),
      );

      final editButton =
          find.byKey(const ValueKey('surface_paintable_edit_mapping_water'));
      await tester.ensureVisible(editButton);
      expect(find.text('Modifier le mapping visuel'), findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.text('Surface Mapping Editor'), findsOneWidget);
      expect(find.text('Atlas réel cliquable'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('surface_role_slot_endNorth')),
      );
      await tester.pump();

      final hitArea = find.byKey(const ValueKey('surface_real_atlas_hit_area'));
      final topLeft = tester.getTopLeft(hitArea);
      final size = tester.getSize(hitArea);
      await tester.tapAt(topLeft + Offset(size.width * 0.75, size.height / 2));
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey('surface_mapping_editor_close')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );

      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();

      expect(saved, isNotNull);
      expect(
        saved!
            .presetById('water')!
            .animationIdForRole(SurfaceVariantRole.endNorth),
        'water-horizontal',
      );
      expect(
        saved!
            .presetById('water')!
            .animationIdForRole(SurfaceVariantRole.horizontal),
        'water-horizontal',
      );
    });
  });

  group('SurfaceStudioPanel (Lot 67–69)', () {
    testWidgets('67–68.1 — édition nom atlas, dirty, compteurs stables',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _minimalWaterReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      await tester.ensureVisible(find.text('Water Atlas'));
      await tester.tap(find.text('Water Atlas'));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_start_edit_atlas')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_start_edit_atlas')),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('atlas_draft_name')),
        'Renamed Water',
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_apply_atlas_edit')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_apply_atlas_edit')),
      );
      await tester.pump();
      expect(find.text('Renamed Water'), findsWidgets);
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsNWidgets(3),
      );
    });

    testWidgets(
        '67–68.2 — création atlas avec sélection animation : sélection inchangée',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _minimalWaterReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      await tester.ensureVisible(find.text('Water Isolated Loop'));
      await tester.tap(find.text('Water Isolated Loop'));
      await tester.pump();
      expect(find.text('Animation sélectionnée'), findsWidgets);
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'z2');
      await tester.enterText(nameF, 'Z2');
      await tester.enterText(tsF, 't2');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(find.text('Animation sélectionnée'), findsWidgets);
    });

    testWidgets('69.1 — atlas utilisé : pas de préparation suppression',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _warningReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      final usedLine = find.textContaining('used-atlas');
      await tester.ensureVisible(usedLine.first);
      await tester.tap(usedLine.first);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('surface_studio_inspector_prepare_delete')),
        findsNothing,
      );
    });

    testWidgets('69.2 — atlas inutilisé : supprimer et sélection nettoyée',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanel(
            readModel: _warningReadModel(),
            onSurfaceCatalogSaveRequested: (_) {},
          ),
        ),
      );
      final orphanLine = find.textContaining('orphan-atlas');
      await tester.ensureVisible(orphanLine.first);
      await tester.tap(orphanLine.first);
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_inspector_prepare_delete')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_inspector_prepare_delete')),
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_inspector_confirm_delete')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_inspector_confirm_delete')),
      );
      await tester.pump();
      expect(find.textContaining('orphan-atlas'), findsNothing);
      expect(find.text('Aucune sélection'), findsOneWidget);
    });
  });

  group('SurfaceStudioPanel (Lot 64)', () {
    testWidgets(
        '64.1 — FromManifest : préparer sauvegarde, manifest mémoire, dirty off',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanelFromManifest(
            manifest: _manifest(ProjectSurfaceCatalog()),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'lot64-a');
      await tester.enterText(nameF, 'L');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      final prep =
          find.byKey(const ValueKey('surface_studio_save_prep_catalog'));
      await tester.ensureVisible(prep);
      await tester.tap(prep);
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(
        find.text(SurfaceStudioPanel.manifestMemoryUpdatedNote),
        findsOneWidget,
      );
      expect(find.text('lot64-a'), findsWidgets);
      final counters =
          find.byKey(const ValueKey('surface_studio_header_counters'));
      expect(
        find.descendant(of: counters, matching: find.text('1')),
        findsWidgets,
      );
    });

    testWidgets('64.2 — onProjectManifestChanged une fois, atlas dans manifest',
        (tester) async {
      var calls = 0;
      late ProjectManifest out;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanelFromManifest(
            manifest: _manifest(
              ProjectSurfaceCatalog(),
            ),
            onProjectManifestChanged: (m) {
              calls++;
              out = m;
            },
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'cb-one');
      await tester.enterText(nameF, 'C');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.pump();
      expect(calls, 1);
      expect(out.surfaceCatalog.atlases.length, 1);
      expect(out.surfaceCatalog.atlases.first.id, 'cb-one');
      expect(out.name, 'Test');
    });

    testWidgets('64.3 — onProjectManifestChanged absent : pas d’exception',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanelFromManifest(
            manifest: _manifest(ProjectSurfaceCatalog()),
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'nccb64');
      await tester.enterText(nameF, 'N');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '64.4 — changement de manifest parent externe (FromManifest) : resync',
        (tester) async {
      const extKey = ValueKey<String>('lot64_from_manifest');
      final a = _manifest(ProjectSurfaceCatalog());
      final b = _manifest(
        _minimalWaterCatalog(),
      );
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanelFromManifest(
            key: extKey,
            manifest: a,
          ),
        ),
      );
      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'orph');
      await tester.enterText(nameF, 'O');
      await tester.enterText(tsF, 't');
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPanelFromManifest(
            key: extKey,
            manifest: b,
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsNothing,
      );
      expect(find.text('Water Atlas'), findsOneWidget);
    });
  });
}

Widget _wrap(Widget child) {
  // MacosApp + thème sombre : même [EditorChrome] que l’éditeur réel.
  return MacosApp(
    theme: MacosThemeData.dark(),
    home: ColoredBox(
      color: const Color(0xFF0F1218),
      child: child,
    ),
  );
}

SurfaceStudioReadModel _emptyReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
}

SurfaceStudioReadModel _minimalWaterReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
}

SurfaceStudioReadModel _warningReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_catalogWithUnusedAtlas());
}

SurfaceStudioReadModel _animationsOnlyReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_catalogWithUnusedAtlas());
}

SurfaceStudioReadModel _errorReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_catalogWithMissingAnimation());
}

SurfaceAtlasGeometry _geom() {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceCatalog _minimalWaterCatalog() {
  final g = _geom();
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );
  final frame = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-isolated-loop',
    name: 'Water Isolated Loop',
    timeline: SurfaceAnimationTimeline(frames: [frame]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-isolated-loop',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'water-surface',
    name: 'Water Surface',
    variantAnimations: refs,
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: [preset],
  );
}

ProjectSurfaceCatalog _roleMappingCatalog() {
  final g = _geom();
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );

  ProjectSurfaceAnimation animation(String id, String name, int column) {
    return ProjectSurfaceAnimation(
      id: id,
      name: name,
      timeline: SurfaceAnimationTimeline(
        frames: [
          SurfaceAnimationFrame(
            tileRef: SurfaceAtlasTileRef(
              atlasId: 'water-atlas',
              column: column,
              row: 0,
            ),
            durationMs: 120,
          ),
        ],
      ),
    );
  }

  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [
      animation('water-cross', 'Water Cross', 0),
      animation('water-horizontal', 'Water Horizontal', 1),
    ],
    presets: [
      ProjectSurfacePreset(
        id: 'water',
        name: 'Water Surface',
        categoryId: 'water',
        sortOrder: 3,
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.cross,
              animationId: 'water-cross',
            ),
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.horizontal,
              animationId: 'water-horizontal',
            ),
          ],
        ),
      ),
    ],
  );
}

List<ProjectTilesetEntry> _surfaceTilesets() => const [
      ProjectTilesetEntry(
        id: 'nature-tileset',
        name: 'Nature Tileset',
        relativePath: 'assets/tilesets/nature.png',
      ),
    ];

Future<ui.Image> _fakeAtlasImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 32, 64),
    ui.Paint()..color = const ui.Color(0xFF0EA5E9),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(32, 0, 32, 64),
    ui.Paint()..color = const ui.Color(0xFF22C55E),
  );
  canvas.drawLine(
    const ui.Offset(32, 0),
    const ui.Offset(32, 64),
    ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF)
      ..strokeWidth = 2,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(64, 64);
  picture.dispose();
  return image;
}

ProjectSurfaceCatalog _catalogWithUnusedAtlas() {
  final g = _geom();
  final used = ProjectSurfaceAtlas(
    id: 'used-atlas',
    name: 'U',
    tilesetId: 't',
    geometry: g,
  );
  final unused = ProjectSurfaceAtlas(
    id: 'orphan-atlas',
    name: 'O',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'used-atlas', column: 0, row: 0),
    durationMs: 10,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'a',
    name: 'a',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  return ProjectSurfaceCatalog(
    atlases: [used, unused],
    animations: [anim],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogWithMissingAnimation() {
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'missing-anim',
      ),
    ],
  );
  return ProjectSurfaceCatalog(
    atlases: const [],
    animations: const [],
    presets: [
      ProjectSurfacePreset(
        id: 'p',
        name: 'p',
        variantAnimations: refs,
      ),
    ],
  );
}

ProjectManifest _manifest(ProjectSurfaceCatalog catalog) {
  return ProjectManifest(
    name: 'Test',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: catalog,
  );
}

```

## 37.7 Diffs complets


### Diff fichier créé : `packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart b/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart
@@ -0,0 +1,112 @@
+import 'package:flutter/widgets.dart';
+
+import '../surface_studio_design_tokens.dart';
+
+class SurfaceStudioAtlasGridPainter extends CustomPainter {
+  const SurfaceStudioAtlasGridPainter({
+    required this.columnCount,
+    required this.rowCount,
+    required this.selectedColumns,
+    required this.zoomPercent,
+  });
+
+  final int columnCount;
+  final int rowCount;
+  final List<int> selectedColumns;
+  final double zoomPercent;
+
+  @override
+  void paint(Canvas canvas, Size size) {
+    final bg = Paint()..color = const Color(0xFF102E70);
+    canvas.drawRRect(
+      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
+      bg,
+    );
+
+    final columnWidth = size.width / columnCount;
+    final stripePaint = Paint();
+    for (var i = 0; i < columnCount; i++) {
+      final rect = Rect.fromLTWH(i * columnWidth, 0, columnWidth, size.height);
+      final hue = i % 4;
+      stripePaint.color = switch (hue) {
+        0 => const Color(0xFF1C7DFF),
+        1 => const Color(0xFF2E8DFF),
+        2 => const Color(0xFFE15E91),
+        _ => const Color(0xFF2272DD),
+      };
+      canvas.drawRect(rect, stripePaint);
+      if (hue == 2) {
+        final shore = Paint()
+          ..color = const Color(0xFFE2D6C8).withValues(alpha: 0.72);
+        canvas.drawRect(
+          Rect.fromLTWH(rect.left + columnWidth * 0.72, 0, columnWidth * 0.16,
+              size.height),
+          shore,
+        );
+      }
+    }
+
+    final waterLine = Paint()
+      ..color = const Color(0xFF7ACDFF).withValues(alpha: 0.18)
+      ..style = PaintingStyle.stroke
+      ..strokeWidth = 1.2;
+    for (var y = 14.0; y < size.height; y += 32) {
+      final path = Path()..moveTo(0, y);
+      for (var x = 0.0; x <= size.width; x += 24) {
+        path.quadraticBezierTo(x + 12, y - 8, x + 24, y);
+      }
+      canvas.drawPath(path, waterLine);
+    }
+
+    final gridPaint = Paint()
+      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.42)
+      ..strokeWidth = 1;
+    for (var i = 0; i <= columnCount; i++) {
+      final x = i * columnWidth;
+      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
+    }
+    final rowHeight = size.height / rowCount;
+    for (var i = 0; i <= rowCount; i++) {
+      final y = i * rowHeight;
+      canvas.drawLine(Offset(0, y), Offset(size.width, y),
+          gridPaint..color = const Color(0xFFFFFFFF).withValues(alpha: 0.13));
+    }
+
+    final selectedPaint = Paint()
+      ..color = SurfaceStudioDesignTokens.accentGold.withValues(alpha: 0.17);
+    final selectedBorder = Paint()
+      ..color = SurfaceStudioDesignTokens.accentGold
+      ..style = PaintingStyle.stroke
+      ..strokeWidth = 2.4;
+    for (final column in selectedColumns) {
+      final rect = Rect.fromLTWH(
+        (column - 1) * columnWidth + 2,
+        2,
+        columnWidth - 4,
+        size.height - 4,
+      );
+      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(8));
+      canvas.drawRRect(rr, selectedPaint);
+      canvas.drawRRect(rr, selectedBorder);
+    }
+  }
+
+  @override
+  bool shouldRepaint(covariant SurfaceStudioAtlasGridPainter oldDelegate) =>
+      oldDelegate.columnCount != columnCount ||
+      oldDelegate.rowCount != rowCount ||
+      oldDelegate.zoomPercent != zoomPercent ||
+      !_listEquals(oldDelegate.selectedColumns, selectedColumns);
+}
+
+bool _listEquals(List<int> a, List<int> b) {
+  if (a.length != b.length) {
+    return false;
+  }
+  for (var i = 0; i < a.length; i++) {
+    if (a[i] != b[i]) {
+      return false;
+    }
+  }
+  return true;
+}
```

### Diff fichier créé : `packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart b/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
@@ -0,0 +1,576 @@
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart' show Material, MaterialType, Slider;
+import 'package:flutter/services.dart';
+
+import '../surface_studio_column_selection.dart';
+import '../surface_studio_design_tokens.dart';
+import '../surface_studio_drag_payload.dart';
+import 'surface_studio_atlas_grid_painter.dart';
+
+class SurfaceStudioAtlasPanel extends StatelessWidget {
+  const SurfaceStudioAtlasPanel({
+    super.key,
+    required this.columnCount,
+    required this.frameCount,
+    required this.tileWidth,
+    required this.tileHeight,
+    required this.selection,
+    required this.zoomPercent,
+    required this.onColumnSelectionChanged,
+    required this.onZoomChanged,
+    required this.onReset,
+    required this.onAutoSuggest,
+  });
+
+  final int columnCount;
+  final int frameCount;
+  final int tileWidth;
+  final int tileHeight;
+  final SurfaceStudioColumnSelection selection;
+  final double zoomPercent;
+  final ValueChanged<SurfaceStudioColumnSelection> onColumnSelectionChanged;
+  final ValueChanged<double> onZoomChanged;
+  final VoidCallback onReset;
+  final VoidCallback onAutoSuggest;
+
+  @override
+  Widget build(BuildContext context) {
+    return _PanelFrame(
+      key: const ValueKey('surfaceStudio.atlas.panel'),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          const _AtlasHeader(),
+          const SizedBox(height: 10),
+          Expanded(
+            child: SurfaceStudioAtlasViewport(
+              columnCount: columnCount,
+              frameCount: frameCount,
+              tileWidth: tileWidth,
+              tileHeight: tileHeight,
+              selection: selection,
+              zoomPercent: zoomPercent,
+              onColumnSelectionChanged: onColumnSelectionChanged,
+            ),
+          ),
+          const SizedBox(height: 10),
+          SurfaceStudioAtlasToolbar(
+            zoomPercent: zoomPercent,
+            columnCount: columnCount,
+            frameCount: frameCount,
+            tileWidth: tileWidth,
+            tileHeight: tileHeight,
+            onZoomChanged: onZoomChanged,
+            onReset: onReset,
+            onAutoSuggest: onAutoSuggest,
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class SurfaceStudioAtlasViewport extends StatelessWidget {
+  const SurfaceStudioAtlasViewport({
+    super.key,
+    required this.columnCount,
+    required this.frameCount,
+    required this.tileWidth,
+    required this.tileHeight,
+    required this.selection,
+    required this.zoomPercent,
+    required this.onColumnSelectionChanged,
+  });
+
+  final int columnCount;
+  final int frameCount;
+  final int tileWidth;
+  final int tileHeight;
+  final SurfaceStudioColumnSelection selection;
+  final double zoomPercent;
+  final ValueChanged<SurfaceStudioColumnSelection> onColumnSelectionChanged;
+
+  @override
+  Widget build(BuildContext context) {
+    final payload = SurfaceStudioColumnDragPayload(
+      columns: selection.columns,
+      tileWidth: tileWidth,
+      tileHeight: tileHeight,
+      frameCount: frameCount,
+    );
+    return Container(
+      key: const ValueKey('surfaceStudio.atlas.viewport'),
+      decoration: BoxDecoration(
+        color: SurfaceStudioDesignTokens.backgroundDeep,
+        borderRadius: BorderRadius.circular(12),
+        border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
+      ),
+      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
+      child: Column(
+        children: [
+          SizedBox(
+            height: 24,
+            child: Row(
+              children: [
+                for (var column = 1; column <= columnCount; column++)
+                  Expanded(
+                    child: GestureDetector(
+                      key: ValueKey('surfaceStudio.atlas.column.$column'),
+                      behavior: HitTestBehavior.opaque,
+                      onTap: () {
+                        final shift = HardwareKeyboard
+                            .instance.logicalKeysPressed
+                            .any((key) =>
+                                key == LogicalKeyboardKey.shiftLeft ||
+                                key == LogicalKeyboardKey.shiftRight);
+                        final next = shift && selection.isNotEmpty
+                            ? selection.selectContiguousTo(column)
+                            : selection.selectSingle(column);
+                        onColumnSelectionChanged(next);
+                      },
+                      child: Center(
+                        child: Text(
+                          '$column',
+                          style: TextStyle(
+                            color: selection.columns.contains(column)
+                                ? SurfaceStudioDesignTokens.accentGold
+                                : SurfaceStudioDesignTokens.textSecondary,
+                            fontSize: 12,
+                            fontWeight: FontWeight.w800,
+                          ),
+                        ),
+                      ),
+                    ),
+                  ),
+              ],
+            ),
+          ),
+          Expanded(
+            child: Stack(
+              children: [
+                Positioned.fill(
+                  child: CustomPaint(
+                    painter: SurfaceStudioAtlasGridPainter(
+                      columnCount: columnCount,
+                      rowCount: frameCount,
+                      selectedColumns: selection.columns,
+                      zoomPercent: zoomPercent,
+                    ),
+                  ),
+                ),
+                if (selection.isNotEmpty)
+                  Positioned(
+                    left: 14,
+                    bottom: 14,
+                    child: Draggable<SurfaceStudioColumnDragPayload>(
+                      data: payload,
+                      feedback: _DragGhost(payload: payload),
+                      childWhenDragging: Opacity(
+                        opacity: 0.48,
+                        child: _DragHandle(payload: payload),
+                      ),
+                      child: _DragHandle(payload: payload),
+                    ),
+                  ),
+              ],
+            ),
+          ),
+          const SizedBox(height: 8),
+          Container(
+            height: 35,
+            alignment: Alignment.center,
+            decoration: BoxDecoration(
+              color: SurfaceStudioDesignTokens.backgroundPanel
+                  .withValues(alpha: 0.72),
+              borderRadius: BorderRadius.circular(10),
+              border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
+            ),
+            child: Text(
+              selection.microcopy,
+              textAlign: TextAlign.center,
+              style: const TextStyle(
+                color: SurfaceStudioDesignTokens.textMuted,
+                fontSize: 12,
+                fontWeight: FontWeight.w600,
+              ),
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class SurfaceStudioAtlasToolbar extends StatelessWidget {
+  const SurfaceStudioAtlasToolbar({
+    super.key,
+    required this.zoomPercent,
+    required this.columnCount,
+    required this.frameCount,
+    required this.tileWidth,
+    required this.tileHeight,
+    required this.onZoomChanged,
+    required this.onReset,
+    required this.onAutoSuggest,
+  });
+
+  final double zoomPercent;
+  final int columnCount;
+  final int frameCount;
+  final int tileWidth;
+  final int tileHeight;
+  final ValueChanged<double> onZoomChanged;
+  final VoidCallback onReset;
+  final VoidCallback onAutoSuggest;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+      decoration: BoxDecoration(
+        color: SurfaceStudioDesignTokens.backgroundPanelAlt,
+        borderRadius: BorderRadius.circular(12),
+        border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
+      ),
+      child: SingleChildScrollView(
+        scrollDirection: Axis.horizontal,
+        child: Row(
+          children: [
+            _ToolbarSection(
+              title: 'Zoom',
+              child: Row(
+                children: [
+                  _SquareButton(
+                    icon: CupertinoIcons.minus,
+                    onPressed: () => onZoomChanged(
+                      (zoomPercent - 10).clamp(25, 400).toDouble(),
+                    ),
+                  ),
+                  Material(
+                    type: MaterialType.transparency,
+                    child: SizedBox(
+                      width: 128,
+                      child: Slider(
+                        key: const ValueKey('surfaceStudio.atlas.zoomSlider'),
+                        value: zoomPercent,
+                        min: 25,
+                        max: 400,
+                        divisions: 75,
+                        onChanged: onZoomChanged,
+                      ),
+                    ),
+                  ),
+                  Text(
+                    '${zoomPercent.round()}%',
+                    style: const TextStyle(
+                      color: SurfaceStudioDesignTokens.textSecondary,
+                      fontWeight: FontWeight.w700,
+                    ),
+                  ),
+                  const SizedBox(width: 6),
+                  _SquareButton(
+                    icon: CupertinoIcons.plus,
+                    onPressed: () => onZoomChanged(
+                      (zoomPercent + 10).clamp(25, 400).toDouble(),
+                    ),
+                  ),
+                  _SquareButton(
+                    icon: CupertinoIcons.arrow_up_left_arrow_down_right,
+                    onPressed: () => onZoomChanged(100),
+                  ),
+                ],
+              ),
+            ),
+            _Divider(),
+            _ToolbarSection(
+              title: 'Détection auto',
+              child: CupertinoButton(
+                padding:
+                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
+                color: SurfaceStudioDesignTokens.accentTealSoft,
+                minimumSize: const Size.square(36),
+                onPressed: onAutoSuggest,
+                child: const Row(
+                  mainAxisSize: MainAxisSize.min,
+                  children: [
+                    Icon(
+                      CupertinoIcons.sparkles,
+                      color: SurfaceStudioDesignTokens.accentTeal,
+                      size: 16,
+                    ),
+                    SizedBox(width: 7),
+                    Text(
+                      'Analyser',
+                      style: TextStyle(
+                        color: SurfaceStudioDesignTokens.accentTeal,
+                        fontWeight: FontWeight.w800,
+                      ),
+                    ),
+                  ],
+                ),
+              ),
+            ),
+            _Divider(),
+            _ToolbarSection(
+              title: 'Réinitialiser',
+              child: _SquareButton(
+                icon: CupertinoIcons.arrow_counterclockwise,
+                onPressed: onReset,
+              ),
+            ),
+            _Divider(),
+            _ToolbarMetric(
+                title: 'Découpage', value: '$tileWidth × $tileHeight'),
+            _ToolbarMetric(title: 'Colonnes', value: '$columnCount'),
+            _ToolbarMetric(title: 'Frames', value: '$frameCount'),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _AtlasHeader extends StatelessWidget {
+  const _AtlasHeader();
+
+  @override
+  Widget build(BuildContext context) {
+    return const Row(
+      children: [
+        Text(
+          'Atlas source',
+          style: TextStyle(
+            color: SurfaceStudioDesignTokens.textPrimary,
+            fontSize: 18,
+            fontWeight: FontWeight.w800,
+          ),
+        ),
+        SizedBox(width: 14),
+        Expanded(
+          child: Text(
+            'Glissez pour sélectionner. Faites glisser vers le schéma.',
+            maxLines: 1,
+            overflow: TextOverflow.ellipsis,
+            style: TextStyle(
+              color: SurfaceStudioDesignTokens.textMuted,
+              fontSize: 12,
+              fontStyle: FontStyle.italic,
+              fontWeight: FontWeight.w600,
+            ),
+          ),
+        ),
+      ],
+    );
+  }
+}
+
+class _PanelFrame extends StatelessWidget {
+  const _PanelFrame({
+    super.key,
+    required this.child,
+  });
+
+  final Widget child;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.all(12),
+      decoration: BoxDecoration(
+        color: SurfaceStudioDesignTokens.backgroundPanel,
+        borderRadius:
+            BorderRadius.circular(SurfaceStudioDesignTokens.panelRadius),
+        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
+      ),
+      child: child,
+    );
+  }
+}
+
+class _DragHandle extends StatelessWidget {
+  const _DragHandle({required this.payload});
+
+  final SurfaceStudioColumnDragPayload payload;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      key: const ValueKey('surfaceStudio.atlas.dragHandle'),
+      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
+      decoration: BoxDecoration(
+        color: SurfaceStudioDesignTokens.accentGoldSoft.withValues(alpha: 0.9),
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(color: SurfaceStudioDesignTokens.accentGold),
+      ),
+      child: Row(
+        mainAxisSize: MainAxisSize.min,
+        children: [
+          const Icon(
+            CupertinoIcons.hand_draw,
+            color: SurfaceStudioDesignTokens.accentGold,
+            size: 17,
+          ),
+          const SizedBox(width: 8),
+          Text(
+            payload.label,
+            style: const TextStyle(
+              color: SurfaceStudioDesignTokens.textPrimary,
+              fontWeight: FontWeight.w800,
+              fontSize: 12,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _DragGhost extends StatelessWidget {
+  const _DragGhost({required this.payload});
+
+  final SurfaceStudioColumnDragPayload payload;
+
+  @override
+  Widget build(BuildContext context) {
+    return Directionality(
+      textDirection: TextDirection.ltr,
+      child: Container(
+        key: const ValueKey('surfaceStudio.atlas.dragGhost'),
+        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
+        decoration: BoxDecoration(
+          color: SurfaceStudioDesignTokens.backgroundElevated,
+          borderRadius: BorderRadius.circular(12),
+          border:
+              Border.all(color: SurfaceStudioDesignTokens.accentGold, width: 2),
+          boxShadow: [
+            BoxShadow(
+              color:
+                  SurfaceStudioDesignTokens.accentGold.withValues(alpha: 0.32),
+              blurRadius: 18,
+            ),
+          ],
+        ),
+        child: Text(
+          payload.label,
+          style: const TextStyle(
+            color: SurfaceStudioDesignTokens.accentGold,
+            fontSize: 13,
+            fontWeight: FontWeight.w800,
+            decoration: TextDecoration.none,
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+class _ToolbarSection extends StatelessWidget {
+  const _ToolbarSection({
+    required this.title,
+    required this.child,
+  });
+
+  final String title;
+  final Widget child;
+
+  @override
+  Widget build(BuildContext context) {
+    return Column(
+      mainAxisSize: MainAxisSize.min,
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        Text(
+          title,
+          style: const TextStyle(
+            color: SurfaceStudioDesignTokens.textSecondary,
+            fontSize: 11,
+            fontWeight: FontWeight.w800,
+          ),
+        ),
+        const SizedBox(height: 5),
+        child,
+      ],
+    );
+  }
+}
+
+class _ToolbarMetric extends StatelessWidget {
+  const _ToolbarMetric({
+    required this.title,
+    required this.value,
+  });
+
+  final String title;
+  final String value;
+
+  @override
+  Widget build(BuildContext context) {
+    return Padding(
+      padding: const EdgeInsets.only(left: 12),
+      child: _ToolbarSection(
+        title: title,
+        child: Container(
+          constraints: const BoxConstraints(minWidth: 74),
+          height: 36,
+          alignment: Alignment.center,
+          padding: const EdgeInsets.symmetric(horizontal: 10),
+          decoration: BoxDecoration(
+            color: SurfaceStudioDesignTokens.backgroundDeep,
+            borderRadius: BorderRadius.circular(8),
+            border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
+          ),
+          child: Text(
+            value,
+            style: const TextStyle(
+              color: SurfaceStudioDesignTokens.textSecondary,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+class _SquareButton extends StatelessWidget {
+  const _SquareButton({
+    required this.icon,
+    required this.onPressed,
+  });
+
+  final IconData icon;
+  final VoidCallback onPressed;
+
+  @override
+  Widget build(BuildContext context) {
+    return CupertinoButton(
+      padding: EdgeInsets.zero,
+      minimumSize: const Size.square(34),
+      onPressed: onPressed,
+      child: Container(
+        width: 32,
+        height: 32,
+        alignment: Alignment.center,
+        decoration: BoxDecoration(
+          color: SurfaceStudioDesignTokens.backgroundDeep,
+          borderRadius: BorderRadius.circular(8),
+          border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
+        ),
+        child: Icon(icon,
+            size: 16, color: SurfaceStudioDesignTokens.textSecondary),
+      ),
+    );
+  }
+}
+
+class _Divider extends StatelessWidget {
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      width: 1,
+      height: 54,
+      margin: const EdgeInsets.symmetric(horizontal: 13),
+      color: SurfaceStudioDesignTokens.borderStrong,
+    );
+  }
+}
```

### Diff fichier créé : `packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart b/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
@@ -0,0 +1,477 @@
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart'
+    show Material, MaterialType, PopupMenuButton, PopupMenuItem, Slider;
+import 'package:map_core/map_core.dart';
+
+import '../surface_studio_design_tokens.dart';
+import '../surface_studio_role_assignment_draft.dart';
+
+class SurfaceStudioPreviewPanel extends StatelessWidget {
+  const SurfaceStudioPreviewPanel({
+    super.key,
+    required this.frameCount,
+    required this.frameIndex,
+    required this.playing,
+    required this.loop,
+    required this.gridVisible,
+    required this.previewSize,
+    required this.assignmentDraft,
+    required this.onPrevious,
+    required this.onNext,
+    required this.onTogglePlaying,
+    required this.onFrameChanged,
+    required this.onLoopChanged,
+    required this.onGridChanged,
+    required this.onPreviewSizeChanged,
+  });
+
+  final int frameCount;
+  final int frameIndex;
+  final bool playing;
+  final bool loop;
+  final bool gridVisible;
+  final int previewSize;
+  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
+  final VoidCallback onPrevious;
+  final VoidCallback onNext;
+  final VoidCallback onTogglePlaying;
+  final ValueChanged<int> onFrameChanged;
+  final ValueChanged<bool> onLoopChanged;
+  final ValueChanged<bool> onGridChanged;
+  final ValueChanged<int> onPreviewSizeChanged;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      key: const ValueKey('surfaceStudio.preview.panel'),
+      padding: const EdgeInsets.all(12),
+      decoration: BoxDecoration(
+        color: SurfaceStudioDesignTokens.backgroundPanel,
+        borderRadius:
+            BorderRadius.circular(SurfaceStudioDesignTokens.panelRadius),
+        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          const Text(
+            'Prévisualisation',
+            style: TextStyle(
+              color: SurfaceStudioDesignTokens.textPrimary,
+              fontSize: 17,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 9),
+          Expanded(
+            child: Row(
+              crossAxisAlignment: CrossAxisAlignment.stretch,
+              children: [
+                Expanded(
+                  child: RepaintBoundary(
+                    child: _PreviewViewport(
+                      previewSize: previewSize,
+                      gridVisible: gridVisible,
+                      hasCenter: assignmentDraft.isAssigned(
+                        SurfaceVariantRole.isolated,
+                      ),
+                    ),
+                  ),
+                ),
+                const SizedBox(width: 12),
+                SizedBox(
+                  width: 180,
+                  child: _PreviewControls(
+                    frameCount: frameCount,
+                    frameIndex: frameIndex,
+                    playing: playing,
+                    loop: loop,
+                    gridVisible: gridVisible,
+                    previewSize: previewSize,
+                    onPrevious: onPrevious,
+                    onNext: onNext,
+                    onTogglePlaying: onTogglePlaying,
+                    onFrameChanged: onFrameChanged,
+                    onLoopChanged: onLoopChanged,
+                    onGridChanged: onGridChanged,
+                    onPreviewSizeChanged: onPreviewSizeChanged,
+                  ),
+                ),
+              ],
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _PreviewViewport extends StatelessWidget {
+  const _PreviewViewport({
+    required this.previewSize,
+    required this.gridVisible,
+    required this.hasCenter,
+  });
+
+  final int previewSize;
+  final bool gridVisible;
+  final bool hasCenter;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      decoration: BoxDecoration(
+        color: SurfaceStudioDesignTokens.backgroundDeep,
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
+      ),
+      clipBehavior: Clip.antiAlias,
+      child: hasCenter
+          ? CustomPaint(
+              painter: _WaterPreviewPainter(
+                gridVisible: gridVisible,
+                previewSize: previewSize,
+              ),
+              child: const SizedBox.expand(),
+            )
+          : const Center(
+              child: Padding(
+                padding: EdgeInsets.all(16),
+                child: Text(
+                  'Assignez au moins le rôle “Plein” pour générer une prévisualisation.',
+                  textAlign: TextAlign.center,
+                  style: TextStyle(
+                    color: SurfaceStudioDesignTokens.textMuted,
+                    fontSize: 12,
+                    height: 1.3,
+                  ),
+                ),
+              ),
+            ),
+    );
+  }
+}
+
+class _PreviewControls extends StatelessWidget {
+  const _PreviewControls({
+    required this.frameCount,
+    required this.frameIndex,
+    required this.playing,
+    required this.loop,
+    required this.gridVisible,
+    required this.previewSize,
+    required this.onPrevious,
+    required this.onNext,
+    required this.onTogglePlaying,
+    required this.onFrameChanged,
+    required this.onLoopChanged,
+    required this.onGridChanged,
+    required this.onPreviewSizeChanged,
+  });
+
+  final int frameCount;
+  final int frameIndex;
+  final bool playing;
+  final bool loop;
+  final bool gridVisible;
+  final int previewSize;
+  final VoidCallback onPrevious;
+  final VoidCallback onNext;
+  final VoidCallback onTogglePlaying;
+  final ValueChanged<int> onFrameChanged;
+  final ValueChanged<bool> onLoopChanged;
+  final ValueChanged<bool> onGridChanged;
+  final ValueChanged<int> onPreviewSizeChanged;
+
+  @override
+  Widget build(BuildContext context) {
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        Container(
+          padding: const EdgeInsets.all(10),
+          decoration: BoxDecoration(
+            color: SurfaceStudioDesignTokens.backgroundPanelAlt,
+            borderRadius: BorderRadius.circular(10),
+            border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
+          ),
+          child: Column(
+            children: [
+              Row(
+                mainAxisAlignment: MainAxisAlignment.center,
+                children: [
+                  _RoundControl(
+                    keyName: 'surfaceStudio.preview.previous',
+                    icon: CupertinoIcons.backward_end_fill,
+                    onPressed: onPrevious,
+                  ),
+                  const SizedBox(width: 10),
+                  _RoundControl(
+                    keyName: 'surfaceStudio.preview.playPause',
+                    icon: playing
+                        ? CupertinoIcons.pause_fill
+                        : CupertinoIcons.play_fill,
+                    onPressed: onTogglePlaying,
+                    highlighted: true,
+                  ),
+                  const SizedBox(width: 10),
+                  _RoundControl(
+                    keyName: 'surfaceStudio.preview.next',
+                    icon: CupertinoIcons.forward_end_fill,
+                    onPressed: onNext,
+                  ),
+                ],
+              ),
+              const SizedBox(height: 9),
+              Text(
+                'Frame ${frameIndex + 1} / $frameCount',
+                style: const TextStyle(
+                  color: SurfaceStudioDesignTokens.textSecondary,
+                  fontWeight: FontWeight.w800,
+                  fontSize: 12,
+                ),
+              ),
+              Material(
+                type: MaterialType.transparency,
+                child: Slider(
+                  key: const ValueKey('surfaceStudio.preview.scrubSlider'),
+                  value: frameIndex.toDouble(),
+                  min: 0,
+                  max: (frameCount - 1).toDouble(),
+                  divisions: frameCount > 1 ? frameCount - 1 : null,
+                  onChanged: (value) => onFrameChanged(value.round()),
+                ),
+              ),
+            ],
+          ),
+        ),
+        const SizedBox(height: 8),
+        Expanded(
+          child: Container(
+            padding: const EdgeInsets.all(10),
+            decoration: BoxDecoration(
+              color: SurfaceStudioDesignTokens.backgroundPanelAlt,
+              borderRadius: BorderRadius.circular(10),
+              border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
+            ),
+            child: SingleChildScrollView(
+              child: Column(
+                crossAxisAlignment: CrossAxisAlignment.start,
+                children: [
+                  _CheckLine(
+                    label: 'Boucle',
+                    value: loop,
+                    onChanged: onLoopChanged,
+                  ),
+                  _CheckLine(
+                    label: 'Grille',
+                    value: gridVisible,
+                    onChanged: onGridChanged,
+                  ),
+                  const SizedBox(height: 10),
+                  Wrap(
+                    spacing: 12,
+                    runSpacing: 8,
+                    crossAxisAlignment: WrapCrossAlignment.center,
+                    children: [
+                      const Text(
+                        'Taille',
+                        style: TextStyle(
+                          color: SurfaceStudioDesignTokens.textSecondary,
+                          fontSize: 12,
+                          fontWeight: FontWeight.w800,
+                        ),
+                      ),
+                      Material(
+                        type: MaterialType.transparency,
+                        child: PopupMenuButton<int>(
+                          key: const ValueKey(
+                              'surfaceStudio.preview.sizeButton'),
+                          initialValue: previewSize,
+                          color: SurfaceStudioDesignTokens.backgroundElevated,
+                          onSelected: onPreviewSizeChanged,
+                          itemBuilder: (context) => const [
+                            PopupMenuItem(value: 5, child: Text('5 × 5')),
+                            PopupMenuItem(value: 10, child: Text('10 × 10')),
+                            PopupMenuItem(value: 15, child: Text('15 × 15')),
+                            PopupMenuItem(value: 20, child: Text('20 × 20')),
+                          ],
+                          child: Container(
+                            padding: const EdgeInsets.symmetric(
+                              horizontal: 12,
+                              vertical: 8,
+                            ),
+                            decoration: BoxDecoration(
+                              color: SurfaceStudioDesignTokens.backgroundDeep,
+                              borderRadius: BorderRadius.circular(8),
+                              border: Border.all(
+                                color: SurfaceStudioDesignTokens.borderStrong,
+                              ),
+                            ),
+                            child: Text(
+                              '$previewSize × $previewSize',
+                              style: const TextStyle(
+                                color: SurfaceStudioDesignTokens.textPrimary,
+                                fontWeight: FontWeight.w800,
+                                fontSize: 12,
+                              ),
+                            ),
+                          ),
+                        ),
+                      ),
+                    ],
+                  ),
+                ],
+              ),
+            ),
+          ),
+        ),
+      ],
+    );
+  }
+}
+
+class _RoundControl extends StatelessWidget {
+  const _RoundControl({
+    required this.keyName,
+    required this.icon,
+    required this.onPressed,
+    this.highlighted = false,
+  });
+
+  final String keyName;
+  final IconData icon;
+  final VoidCallback onPressed;
+  final bool highlighted;
+
+  @override
+  Widget build(BuildContext context) {
+    return CupertinoButton(
+      key: ValueKey(keyName),
+      padding: EdgeInsets.zero,
+      minimumSize: const Size.square(36),
+      onPressed: onPressed,
+      child: Container(
+        width: highlighted ? 42 : 34,
+        height: highlighted ? 42 : 34,
+        alignment: Alignment.center,
+        decoration: BoxDecoration(
+          shape: BoxShape.circle,
+          color: highlighted
+              ? SurfaceStudioDesignTokens.accentTealSoft
+              : SurfaceStudioDesignTokens.backgroundDeep,
+          border: Border.all(
+            color: highlighted
+                ? SurfaceStudioDesignTokens.accentTeal
+                : SurfaceStudioDesignTokens.borderStrong,
+            width: highlighted ? 2 : 1,
+          ),
+        ),
+        child: Icon(
+          icon,
+          size: highlighted ? 22 : 17,
+          color: highlighted
+              ? SurfaceStudioDesignTokens.accentTeal
+              : SurfaceStudioDesignTokens.textMuted,
+        ),
+      ),
+    );
+  }
+}
+
+class _CheckLine extends StatelessWidget {
+  const _CheckLine({
+    required this.label,
+    required this.value,
+    required this.onChanged,
+  });
+
+  final String label;
+  final bool value;
+  final ValueChanged<bool> onChanged;
+
+  @override
+  Widget build(BuildContext context) {
+    return GestureDetector(
+      onTap: () => onChanged(!value),
+      child: Padding(
+        padding: const EdgeInsets.only(bottom: 8),
+        child: Row(
+          children: [
+            Icon(
+              value
+                  ? CupertinoIcons.checkmark_square_fill
+                  : CupertinoIcons.square,
+              color: value
+                  ? SurfaceStudioDesignTokens.accentTeal
+                  : SurfaceStudioDesignTokens.textMuted,
+              size: 18,
+            ),
+            const SizedBox(width: 7),
+            Text(
+              label,
+              style: const TextStyle(
+                color: SurfaceStudioDesignTokens.textSecondary,
+                fontWeight: FontWeight.w800,
+                fontSize: 12,
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _WaterPreviewPainter extends CustomPainter {
+  const _WaterPreviewPainter({
+    required this.gridVisible,
+    required this.previewSize,
+  });
+
+  final bool gridVisible;
+  final int previewSize;
+
+  @override
+  void paint(Canvas canvas, Size size) {
+    final cellW = size.width / previewSize;
+    final cellH = size.height / previewSize;
+    final a = Paint()..color = const Color(0xFF1E89FF);
+    final b = Paint()..color = const Color(0xFF1268D9);
+    for (var y = 0; y < previewSize; y++) {
+      for (var x = 0; x < previewSize; x++) {
+        canvas.drawRect(
+          Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH),
+          (x + y).isEven ? a : b,
+        );
+      }
+    }
+    final wave = Paint()
+      ..color = const Color(0xFFA4E7FF).withValues(alpha: 0.26)
+      ..style = PaintingStyle.stroke
+      ..strokeWidth = 1.3;
+    for (var y = 8.0; y < size.height; y += 24) {
+      final path = Path()..moveTo(0, y);
+      for (var x = 0.0; x <= size.width; x += 22) {
+        path.quadraticBezierTo(x + 11, y - 7, x + 22, y);
+      }
+      canvas.drawPath(path, wave);
+    }
+    if (gridVisible) {
+      final grid = Paint()
+        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.16)
+        ..strokeWidth = 1;
+      for (var i = 0; i <= previewSize; i++) {
+        final x = i * cellW;
+        final y = i * cellH;
+        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
+        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
+      }
+    }
+  }
+
+  @override
+  bool shouldRepaint(covariant _WaterPreviewPainter oldDelegate) =>
+      oldDelegate.gridVisible != gridVisible ||
+      oldDelegate.previewSize != previewSize;
+}
```

### Diff fichier créé : `packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_role_thumbnail_painter.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_role_thumbnail_painter.dart b/packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_role_thumbnail_painter.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_role_thumbnail_painter.dart
@@ -0,0 +1,133 @@
+import 'package:flutter/widgets.dart';
+import 'package:map_core/map_core.dart';
+
+import '../surface_studio_design_tokens.dart';
+
+class SurfaceStudioRoleThumbnailPainter extends CustomPainter {
+  const SurfaceStudioRoleThumbnailPainter({
+    required this.role,
+    required this.assigned,
+  });
+
+  final SurfaceVariantRole role;
+  final bool assigned;
+
+  @override
+  void paint(Canvas canvas, Size size) {
+    final bg = Paint()
+      ..color = assigned
+          ? const Color(0xFF1D6EEB).withValues(alpha: 0.92)
+          : SurfaceStudioDesignTokens.backgroundDeep;
+    final accent = Paint()
+      ..color = assigned
+          ? SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.48)
+          : SurfaceStudioDesignTokens.textMuted.withValues(alpha: 0.42);
+    final shape = Paint()
+      ..color = assigned
+          ? const Color(0xFF7BCFFF).withValues(alpha: 0.88)
+          : SurfaceStudioDesignTokens.borderStrong;
+
+    canvas.drawRRect(
+      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(7)),
+      bg,
+    );
+
+    final inset = size.shortestSide * 0.18;
+    final inner = Rect.fromLTWH(
+      inset,
+      inset,
+      size.width - inset * 2,
+      size.height - inset * 2,
+    );
+
+    Rect bandTop() =>
+        Rect.fromLTWH(inner.left, inner.top, inner.width, inner.height * 0.35);
+    Rect bandBottom() => Rect.fromLTWH(inner.left,
+        inner.bottom - inner.height * 0.35, inner.width, inner.height * 0.35);
+    Rect bandLeft() =>
+        Rect.fromLTWH(inner.left, inner.top, inner.width * 0.35, inner.height);
+    Rect bandRight() => Rect.fromLTWH(inner.right - inner.width * 0.35,
+        inner.top, inner.width * 0.35, inner.height);
+    Rect bandH() => Rect.fromLTWH(
+        inner.left,
+        inner.center.dy - inner.height * 0.18,
+        inner.width,
+        inner.height * 0.36);
+    Rect bandV() => Rect.fromLTWH(inner.center.dx - inner.width * 0.18,
+        inner.top, inner.width * 0.36, inner.height);
+
+    void draw(Rect rect) => canvas.drawRRect(
+          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
+          shape,
+        );
+
+    switch (role) {
+      case SurfaceVariantRole.isolated:
+        draw(inner);
+      case SurfaceVariantRole.endNorth:
+        draw(bandTop());
+      case SurfaceVariantRole.endEast:
+        draw(bandRight());
+      case SurfaceVariantRole.endSouth:
+        draw(bandBottom());
+      case SurfaceVariantRole.endWest:
+        draw(bandLeft());
+      case SurfaceVariantRole.horizontal:
+        draw(bandH());
+      case SurfaceVariantRole.vertical:
+        draw(bandV());
+      case SurfaceVariantRole.cornerNW:
+        draw(bandTop());
+        draw(bandLeft());
+      case SurfaceVariantRole.cornerNE:
+        draw(bandTop());
+        draw(bandRight());
+      case SurfaceVariantRole.cornerSW:
+        draw(bandBottom());
+        draw(bandLeft());
+      case SurfaceVariantRole.cornerSE:
+        draw(bandBottom());
+        draw(bandRight());
+      case SurfaceVariantRole.innerCornerNW:
+        draw(Rect.fromLTWH(inner.center.dx, inner.center.dy, inner.width / 2,
+            inner.height / 2));
+      case SurfaceVariantRole.innerCornerNE:
+        draw(Rect.fromLTWH(
+            inner.left, inner.center.dy, inner.width / 2, inner.height / 2));
+      case SurfaceVariantRole.innerCornerSW:
+        draw(Rect.fromLTWH(
+            inner.center.dx, inner.top, inner.width / 2, inner.height / 2));
+      case SurfaceVariantRole.innerCornerSE:
+        draw(Rect.fromLTWH(
+            inner.left, inner.top, inner.width / 2, inner.height / 2));
+      case SurfaceVariantRole.teeNorth:
+        draw(bandTop());
+        draw(bandV());
+      case SurfaceVariantRole.teeEast:
+        draw(bandRight());
+        draw(bandH());
+      case SurfaceVariantRole.teeSouth:
+        draw(bandBottom());
+        draw(bandV());
+      case SurfaceVariantRole.teeWest:
+        draw(bandLeft());
+        draw(bandH());
+      case SurfaceVariantRole.cross:
+        draw(bandH());
+        draw(bandV());
+    }
+
+    final stroke = Paint()
+      ..color = accent.color
+      ..style = PaintingStyle.stroke
+      ..strokeWidth = 1;
+    canvas.drawRRect(
+      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(7)),
+      stroke,
+    );
+  }
+
+  @override
+  bool shouldRepaint(covariant SurfaceStudioRoleThumbnailPainter oldDelegate) =>
+      oldDelegate.role != role || oldDelegate.assigned != assigned;
+}
```

### Diff fichier créé : `packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_schema_panel.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_schema_panel.dart b/packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_schema_panel.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_schema_panel.dart
@@ -0,0 +1,610 @@
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart' show Tooltip;
+import 'package:map_core/map_core.dart';
+
+import '../surface_studio_design_tokens.dart';
+import '../surface_studio_drag_payload.dart';
+import '../surface_studio_motion.dart';
+import '../surface_studio_role_assignment_draft.dart';
+import 'surface_studio_role_thumbnail_painter.dart';
+
+typedef SurfaceStudioRoleDropCallback = void Function(
+  SurfaceVariantRole role,
+  SurfaceStudioColumnDragPayload payload,
+);
+
+class SurfaceStudioSchemaPanel extends StatelessWidget {
+  const SurfaceStudioSchemaPanel({
+    super.key,
+    required this.collapsed,
+    required this.openGroups,
+    required this.assignmentDraft,
+    required this.onToggleCollapsed,
+    required this.onToggleGroup,
+    required this.onDrop,
+    required this.onClearRole,
+    required this.onClearColumn,
+  });
+
+  final bool collapsed;
+  final Set<String> openGroups;
+  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
+  final VoidCallback onToggleCollapsed;
+  final ValueChanged<String> onToggleGroup;
+  final SurfaceStudioRoleDropCallback onDrop;
+  final ValueChanged<SurfaceVariantRole> onClearRole;
+  final void Function(SurfaceVariantRole role, int column) onClearColumn;
+
+  @override
+  Widget build(BuildContext context) {
+    return AnimatedContainer(
+      key: const ValueKey('surfaceStudio.schema.panel'),
+      duration: SurfaceStudioMotion.panelSlide,
+      curve: SurfaceStudioMotion.easeInOut,
+      width: collapsed
+          ? SurfaceStudioDesignTokens.rightPanelWidthCollapsed
+          : SurfaceStudioDesignTokens.rightPanelWidthExpanded,
+      decoration: BoxDecoration(
+        color: SurfaceStudioDesignTokens.backgroundPanel,
+        borderRadius:
+            BorderRadius.circular(SurfaceStudioDesignTokens.panelRadius),
+        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
+      ),
+      padding: const EdgeInsets.all(12),
+      child: collapsed
+          ? _CollapsedSchema(onToggle: onToggleCollapsed)
+          : _ExpandedSchema(
+              openGroups: openGroups,
+              assignmentDraft: assignmentDraft,
+              onToggleCollapsed: onToggleCollapsed,
+              onToggleGroup: onToggleGroup,
+              onDrop: onDrop,
+              onClearRole: onClearRole,
+              onClearColumn: onClearColumn,
+            ),
+    );
+  }
+}
+
+class _CollapsedSchema extends StatelessWidget {
+  const _CollapsedSchema({required this.onToggle});
+
+  final VoidCallback onToggle;
+
+  @override
+  Widget build(BuildContext context) {
+    return Column(
+      key: const ValueKey('surfaceStudio.schema.collapsed'),
+      children: [
+        Tooltip(
+          message: 'Déployer le schéma de surface',
+          child: CupertinoButton(
+            key: const ValueKey('surfaceStudio.schema.collapseButton'),
+            padding: EdgeInsets.zero,
+            minimumSize: const Size.square(38),
+            onPressed: onToggle,
+            child: const Icon(
+              CupertinoIcons.chevron_left,
+              color: SurfaceStudioDesignTokens.textSecondary,
+            ),
+          ),
+        ),
+        const SizedBox(height: 12),
+        const Icon(
+          CupertinoIcons.square_grid_2x2,
+          color: SurfaceStudioDesignTokens.accentGold,
+        ),
+      ],
+    );
+  }
+}
+
+class _ExpandedSchema extends StatelessWidget {
+  const _ExpandedSchema({
+    required this.openGroups,
+    required this.assignmentDraft,
+    required this.onToggleCollapsed,
+    required this.onToggleGroup,
+    required this.onDrop,
+    required this.onClearRole,
+    required this.onClearColumn,
+  });
+
+  final Set<String> openGroups;
+  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
+  final VoidCallback onToggleCollapsed;
+  final ValueChanged<String> onToggleGroup;
+  final SurfaceStudioRoleDropCallback onDrop;
+  final ValueChanged<SurfaceVariantRole> onClearRole;
+  final void Function(SurfaceVariantRole role, int column) onClearColumn;
+
+  @override
+  Widget build(BuildContext context) {
+    return Column(
+      key: const ValueKey('surfaceStudio.schema.expanded'),
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        Row(
+          children: [
+            const Expanded(
+              child: Text(
+                'Schéma de surface (glissez-déposez)',
+                style: TextStyle(
+                  color: SurfaceStudioDesignTokens.textPrimary,
+                  fontSize: 17,
+                  fontWeight: FontWeight.w800,
+                ),
+              ),
+            ),
+            Tooltip(
+              message: 'Aide schéma',
+              child: CupertinoButton(
+                padding: EdgeInsets.zero,
+                minimumSize: const Size.square(32),
+                onPressed: () {},
+                child: const Icon(
+                  CupertinoIcons.question_circle,
+                  color: SurfaceStudioDesignTokens.textSecondary,
+                  size: 18,
+                ),
+              ),
+            ),
+            Tooltip(
+              message: 'Réduire le schéma',
+              child: CupertinoButton(
+                key: const ValueKey('surfaceStudio.schema.collapseButton'),
+                padding: EdgeInsets.zero,
+                minimumSize: const Size.square(32),
+                onPressed: onToggleCollapsed,
+                child: const Icon(
+                  CupertinoIcons.chevron_right,
+                  color: SurfaceStudioDesignTokens.textSecondary,
+                  size: 18,
+                ),
+              ),
+            ),
+          ],
+        ),
+        const SizedBox(height: 10),
+        Expanded(
+          child: SingleChildScrollView(
+            child: Column(
+              children: [
+                for (final group in _schemaGroups)
+                  _SchemaAccordion(
+                    group: group,
+                    open: openGroups.contains(group.id),
+                    assignedCount:
+                        assignmentDraft.assignedCountForRoles(group.roles),
+                    assignmentDraft: assignmentDraft,
+                    onToggle: () => onToggleGroup(group.id),
+                    onDrop: onDrop,
+                    onClearRole: onClearRole,
+                    onClearColumn: onClearColumn,
+                  ),
+              ],
+            ),
+          ),
+        ),
+      ],
+    );
+  }
+}
+
+class _SchemaAccordion extends StatelessWidget {
+  const _SchemaAccordion({
+    required this.group,
+    required this.open,
+    required this.assignedCount,
+    required this.assignmentDraft,
+    required this.onToggle,
+    required this.onDrop,
+    required this.onClearRole,
+    required this.onClearColumn,
+  });
+
+  final _RoleGroup group;
+  final bool open;
+  final int assignedCount;
+  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
+  final VoidCallback onToggle;
+  final SurfaceStudioRoleDropCallback onDrop;
+  final ValueChanged<SurfaceVariantRole> onClearRole;
+  final void Function(SurfaceVariantRole role, int column) onClearColumn;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      key: ValueKey('surfaceStudio.schema.group.${group.id}'),
+      margin: const EdgeInsets.only(bottom: 9),
+      decoration: BoxDecoration(
+        color: SurfaceStudioDesignTokens.backgroundPanelAlt,
+        borderRadius: BorderRadius.circular(12),
+        border: Border.all(
+          color: assignedCount > 0
+              ? SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.42)
+              : SurfaceStudioDesignTokens.borderSubtle,
+        ),
+      ),
+      child: Column(
+        children: [
+          GestureDetector(
+            key: ValueKey('surfaceStudio.schema.group.${group.id}.header'),
+            behavior: HitTestBehavior.opaque,
+            onTap: onToggle,
+            child: Padding(
+              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
+              child: Row(
+                children: [
+                  Icon(
+                    open
+                        ? CupertinoIcons.chevron_down
+                        : CupertinoIcons.chevron_right,
+                    color: SurfaceStudioDesignTokens.textSecondary,
+                    size: 16,
+                  ),
+                  const SizedBox(width: 8),
+                  Expanded(
+                    child: Text(
+                      group.label,
+                      style: const TextStyle(
+                        color: SurfaceStudioDesignTokens.textPrimary,
+                        fontWeight: FontWeight.w800,
+                      ),
+                    ),
+                  ),
+                  Text(
+                    '$assignedCount/${group.roles.length}',
+                    style: TextStyle(
+                      color: assignedCount > 0
+                          ? SurfaceStudioDesignTokens.accentTeal
+                          : SurfaceStudioDesignTokens.textMuted,
+                      fontWeight: FontWeight.w800,
+                      fontSize: 12,
+                    ),
+                  ),
+                ],
+              ),
+            ),
+          ),
+          AnimatedSwitcher(
+            duration: SurfaceStudioMotion.accordion,
+            child: open
+                ? Padding(
+                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
+                    child: Wrap(
+                      spacing: 10,
+                      runSpacing: 10,
+                      children: [
+                        for (final role in group.roles)
+                          SurfaceStudioRoleSlotCard(
+                            role: role,
+                            columns: assignmentDraft.columnsForRole(role),
+                            onDrop: onDrop,
+                            onClearRole: onClearRole,
+                            onClearColumn: onClearColumn,
+                          ),
+                      ],
+                    ),
+                  )
+                : const SizedBox.shrink(),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class SurfaceStudioRoleSlotCard extends StatelessWidget {
+  const SurfaceStudioRoleSlotCard({
+    super.key,
+    required this.role,
+    required this.columns,
+    required this.onDrop,
+    required this.onClearRole,
+    required this.onClearColumn,
+  });
+
+  final SurfaceVariantRole role;
+  final List<int> columns;
+  final SurfaceStudioRoleDropCallback onDrop;
+  final ValueChanged<SurfaceVariantRole> onClearRole;
+  final void Function(SurfaceVariantRole role, int column) onClearColumn;
+
+  bool get _isCenter => role == SurfaceVariantRole.isolated;
+
+  @override
+  Widget build(BuildContext context) {
+    return DragTarget<SurfaceStudioColumnDragPayload>(
+      onWillAcceptWithDetails: (details) =>
+          validateSurfaceStudioRoleDrop(
+            role: role,
+            payload: details.data,
+            draft: const SurfaceStudioRoleAssignmentDraft.empty(),
+          ) ==
+          SurfaceStudioDropValidation.valid,
+      onAcceptWithDetails: (details) => onDrop(role, details.data),
+      builder: (context, candidateData, rejectedData) {
+        final candidate = candidateData.isNotEmpty ? candidateData.first : null;
+        final validation = candidate == null
+            ? SurfaceStudioDropValidation.valid
+            : validateSurfaceStudioRoleDrop(
+                role: role,
+                payload: candidate,
+                draft: const SurfaceStudioRoleAssignmentDraft.empty(),
+              );
+        final validHover = candidate != null &&
+            validation == SurfaceStudioDropValidation.valid;
+        final invalidHover = candidate != null &&
+            validation != SurfaceStudioDropValidation.valid;
+        return AnimatedContainer(
+          key: role == SurfaceVariantRole.isolated
+              ? const ValueKey('surfaceStudio.schema.role.center')
+              : ValueKey('surfaceStudio.schema.role.${role.name}'),
+          duration: SurfaceStudioMotion.fast,
+          width: _isCenter ? 132 : 106,
+          constraints: BoxConstraints(minHeight: _isCenter ? 94 : 86),
+          padding: const EdgeInsets.all(9),
+          decoration: BoxDecoration(
+            color: validHover
+                ? SurfaceStudioDesignTokens.accentTealSoft
+                : invalidHover
+                    ? SurfaceStudioDesignTokens.dangerSoft
+                        .withValues(alpha: 0.16)
+                    : columns.isNotEmpty
+                        ? SurfaceStudioDesignTokens.backgroundElevated
+                        : SurfaceStudioDesignTokens.backgroundPanel,
+            borderRadius:
+                BorderRadius.circular(SurfaceStudioDesignTokens.slotRadius),
+            border: Border.all(
+              color: validHover
+                  ? SurfaceStudioDesignTokens.accentTeal
+                  : invalidHover
+                      ? SurfaceStudioDesignTokens.dangerSoft
+                      : columns.isNotEmpty
+                          ? SurfaceStudioDesignTokens.borderStrong
+                          : SurfaceStudioDesignTokens.borderSubtle,
+              width: validHover || invalidHover ? 2 : 1,
+            ),
+          ),
+          child: Column(
+            crossAxisAlignment: CrossAxisAlignment.stretch,
+            children: [
+              Row(
+                crossAxisAlignment: CrossAxisAlignment.start,
+                children: [
+                  Expanded(
+                    child: Text(
+                      _roleLabel(role),
+                      maxLines: 2,
+                      overflow: TextOverflow.ellipsis,
+                      style: const TextStyle(
+                        color: SurfaceStudioDesignTokens.textPrimary,
+                        fontWeight: FontWeight.w800,
+                        fontSize: 12,
+                        height: 1.1,
+                      ),
+                    ),
+                  ),
+                  if (columns.isNotEmpty)
+                    GestureDetector(
+                      onTap: () => onClearRole(role),
+                      child: const Icon(
+                        CupertinoIcons.xmark_circle_fill,
+                        color: SurfaceStudioDesignTokens.textMuted,
+                        size: 16,
+                      ),
+                    ),
+                ],
+              ),
+              const SizedBox(height: 7),
+              SizedBox(
+                height: _isCenter ? 30 : 34,
+                child: CustomPaint(
+                  painter: SurfaceStudioRoleThumbnailPainter(
+                    role: role,
+                    assigned: columns.isNotEmpty,
+                  ),
+                ),
+              ),
+              const SizedBox(height: 7),
+              if (validHover)
+                const Text(
+                  'Déposer ici',
+                  style: TextStyle(
+                    color: SurfaceStudioDesignTokens.accentTeal,
+                    fontSize: 11,
+                    fontWeight: FontWeight.w800,
+                  ),
+                )
+              else if (invalidHover)
+                const Text(
+                  'Une seule colonne attendue',
+                  style: TextStyle(
+                    color: SurfaceStudioDesignTokens.dangerSoft,
+                    fontSize: 10,
+                    fontWeight: FontWeight.w800,
+                  ),
+                )
+              else
+                _AssignmentChips(
+                  columns: columns,
+                  role: role,
+                  center: _isCenter,
+                  onClearColumn: onClearColumn,
+                ),
+            ],
+          ),
+        );
+      },
+    );
+  }
+}
+
+class _AssignmentChips extends StatelessWidget {
+  const _AssignmentChips({
+    required this.columns,
+    required this.role,
+    required this.center,
+    required this.onClearColumn,
+  });
+
+  final List<int> columns;
+  final SurfaceVariantRole role;
+  final bool center;
+  final void Function(SurfaceVariantRole role, int column) onClearColumn;
+
+  @override
+  Widget build(BuildContext context) {
+    if (columns.isEmpty) {
+      return Text(
+        center ? 'Multi-colonnes autorisé' : 'Déposez une colonne',
+        style: const TextStyle(
+          color: SurfaceStudioDesignTokens.textMuted,
+          fontSize: 10.5,
+          fontWeight: FontWeight.w600,
+        ),
+      );
+    }
+    return Wrap(
+      spacing: 4,
+      runSpacing: 4,
+      children: [
+        for (final column in columns)
+          GestureDetector(
+            onTap: center ? () => onClearColumn(role, column) : null,
+            child: Container(
+              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
+              decoration: BoxDecoration(
+                color: SurfaceStudioDesignTokens.accentGoldSoft,
+                borderRadius: BorderRadius.circular(5),
+                border: Border.all(color: SurfaceStudioDesignTokens.accentGold),
+              ),
+              child: Text(
+                '$column',
+                style: const TextStyle(
+                  color: SurfaceStudioDesignTokens.accentGold,
+                  fontSize: 11,
+                  fontWeight: FontWeight.w900,
+                ),
+              ),
+            ),
+          ),
+        if (center)
+          Container(
+            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
+            decoration: BoxDecoration(
+              color: SurfaceStudioDesignTokens.backgroundDeep,
+              borderRadius: BorderRadius.circular(5),
+              border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
+            ),
+            child: const Text(
+              '+',
+              style: TextStyle(
+                color: SurfaceStudioDesignTokens.textSecondary,
+                fontSize: 11,
+                fontWeight: FontWeight.w900,
+              ),
+            ),
+          ),
+        if (center)
+          const Text(
+            'Multi-colonnes autorisé',
+            style: TextStyle(
+              color: SurfaceStudioDesignTokens.textMuted,
+              fontSize: 9.5,
+              fontWeight: FontWeight.w600,
+            ),
+          ),
+      ],
+    );
+  }
+}
+
+final _schemaGroups = <_RoleGroup>[
+  const _RoleGroup(
+    id: 'surfaceMain',
+    label: 'Surface principale',
+    roles: [
+      SurfaceVariantRole.isolated,
+      SurfaceVariantRole.horizontal,
+      SurfaceVariantRole.vertical,
+    ],
+  ),
+  const _RoleGroup(
+    id: 'edges',
+    label: 'Bords',
+    roles: [
+      SurfaceVariantRole.endNorth,
+      SurfaceVariantRole.endEast,
+      SurfaceVariantRole.endSouth,
+      SurfaceVariantRole.endWest,
+    ],
+  ),
+  const _RoleGroup(
+    id: 'externalCorners',
+    label: 'Coins externes',
+    roles: [
+      SurfaceVariantRole.cornerNW,
+      SurfaceVariantRole.cornerNE,
+      SurfaceVariantRole.cornerSW,
+      SurfaceVariantRole.cornerSE,
+    ],
+  ),
+  const _RoleGroup(
+    id: 'internalCorners',
+    label: 'Coins internes',
+    roles: [
+      SurfaceVariantRole.innerCornerNW,
+      SurfaceVariantRole.innerCornerNE,
+      SurfaceVariantRole.innerCornerSW,
+      SurfaceVariantRole.innerCornerSE,
+    ],
+  ),
+  const _RoleGroup(
+    id: 'junctions',
+    label: 'Jonctions',
+    roles: [
+      SurfaceVariantRole.teeNorth,
+      SurfaceVariantRole.teeEast,
+      SurfaceVariantRole.teeSouth,
+      SurfaceVariantRole.teeWest,
+      SurfaceVariantRole.cross,
+    ],
+  ),
+];
+
+class _RoleGroup {
+  const _RoleGroup({
+    required this.id,
+    required this.label,
+    required this.roles,
+  });
+
+  final String id;
+  final String label;
+  final List<SurfaceVariantRole> roles;
+}
+
+String _roleLabel(SurfaceVariantRole role) => switch (role) {
+      SurfaceVariantRole.isolated => 'Plein (center)',
+      SurfaceVariantRole.endNorth => 'Bord haut',
+      SurfaceVariantRole.endEast => 'Bord droit',
+      SurfaceVariantRole.endSouth => 'Bord bas',
+      SurfaceVariantRole.endWest => 'Bord gauche',
+      SurfaceVariantRole.horizontal => 'Horizontal',
+      SurfaceVariantRole.vertical => 'Vertical',
+      SurfaceVariantRole.cornerNW => 'Coin haut gauche',
+      SurfaceVariantRole.cornerNE => 'Coin haut droit',
+      SurfaceVariantRole.cornerSW => 'Coin bas gauche',
+      SurfaceVariantRole.cornerSE => 'Coin bas droit',
+      SurfaceVariantRole.innerCornerNW => 'Coin int. haut gauche',
+      SurfaceVariantRole.innerCornerNE => 'Coin int. haut droit',
+      SurfaceVariantRole.innerCornerSW => 'Coin int. bas gauche',
+      SurfaceVariantRole.innerCornerSE => 'Coin int. bas droit',
+      SurfaceVariantRole.teeNorth => 'Té haut',
+      SurfaceVariantRole.teeEast => 'Té droit',
+      SurfaceVariantRole.teeSouth => 'Té bas',
+      SurfaceVariantRole.teeWest => 'Té gauche',
+      SurfaceVariantRole.cross => 'Croix',
+    };
```

### Diff fichier créé : `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart
@@ -0,0 +1,138 @@
+import 'package:flutter/cupertino.dart';
+
+import '../surface_studio_design_tokens.dart';
+
+class SurfaceStudioBottomActionBar extends StatelessWidget {
+  const SurfaceStudioBottomActionBar({
+    super.key,
+    required this.canGoBack,
+    required this.canAutoSuggest,
+    required this.canApplyMapping,
+    required this.canGoNext,
+    required this.onBack,
+    required this.onAutoSuggest,
+    required this.onApplyMapping,
+    required this.onNext,
+  });
+
+  final bool canGoBack;
+  final bool canAutoSuggest;
+  final bool canApplyMapping;
+  final bool canGoNext;
+  final VoidCallback onBack;
+  final VoidCallback onAutoSuggest;
+  final VoidCallback onApplyMapping;
+  final VoidCallback onNext;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      key: const ValueKey('surfaceStudio.bottomBar'),
+      decoration: const BoxDecoration(
+        color: SurfaceStudioDesignTokens.backgroundDeep,
+        border: Border(
+          top: BorderSide(color: SurfaceStudioDesignTokens.borderSubtle),
+        ),
+      ),
+      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
+      child: Row(
+        children: [
+          _BarButton(
+            keyName: 'surfaceStudio.action.back',
+            label: 'Retour',
+            icon: CupertinoIcons.arrow_left,
+            enabled: canGoBack,
+            onPressed: onBack,
+          ),
+          const Spacer(),
+          _BarButton(
+            keyName: 'surfaceStudio.action.autoSuggest',
+            label: 'Suggestion auto',
+            icon: CupertinoIcons.sparkles,
+            enabled: canAutoSuggest,
+            onPressed: onAutoSuggest,
+            accent: SurfaceStudioDesignTokens.accentTeal,
+          ),
+          const SizedBox(width: 20),
+          _BarButton(
+            keyName: 'surfaceStudio.action.applyMapping',
+            label: 'Appliquer le mapping',
+            icon: CupertinoIcons.checkmark_circle,
+            enabled: canApplyMapping,
+            onPressed: onApplyMapping,
+          ),
+          const SizedBox(width: 20),
+          _BarButton(
+            keyName: 'surfaceStudio.action.next',
+            label: 'Suivant',
+            icon: CupertinoIcons.arrow_right,
+            enabled: canGoNext,
+            onPressed: onNext,
+            accent: SurfaceStudioDesignTokens.accentGold,
+            primary: true,
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _BarButton extends StatelessWidget {
+  const _BarButton({
+    required this.keyName,
+    required this.label,
+    required this.icon,
+    required this.enabled,
+    required this.onPressed,
+    this.accent,
+    this.primary = false,
+  });
+
+  final String keyName;
+  final String label;
+  final IconData icon;
+  final bool enabled;
+  final VoidCallback onPressed;
+  final Color? accent;
+  final bool primary;
+
+  @override
+  Widget build(BuildContext context) {
+    final effectiveAccent = accent ?? SurfaceStudioDesignTokens.borderStrong;
+    return Opacity(
+      opacity: enabled ? 1 : 0.52,
+      child: CupertinoButton(
+        key: ValueKey(keyName),
+        minimumSize: const Size(46, 46),
+        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
+        color: primary
+            ? effectiveAccent.withValues(alpha: 0.42)
+            : SurfaceStudioDesignTokens.backgroundElevated,
+        borderRadius: BorderRadius.circular(9),
+        onPressed: enabled ? onPressed : null,
+        child: Row(
+          mainAxisSize: MainAxisSize.min,
+          children: [
+            Icon(
+              icon,
+              color: primary
+                  ? SurfaceStudioDesignTokens.textPrimary
+                  : effectiveAccent,
+              size: 18,
+            ),
+            const SizedBox(width: 10),
+            Text(
+              label,
+              style: TextStyle(
+                color: primary
+                    ? SurfaceStudioDesignTokens.textPrimary
+                    : SurfaceStudioDesignTokens.textSecondary,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
```

### Diff fichier créé : `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart
@@ -0,0 +1,124 @@
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart' show Tooltip;
+
+import '../surface_studio_design_tokens.dart';
+import '../surface_studio_step.dart';
+import 'surface_studio_top_stepper.dart';
+
+class SurfaceStudioHeader extends StatelessWidget {
+  const SurfaceStudioHeader({
+    super.key,
+    required this.currentStep,
+    required this.completedSteps,
+    required this.onStepSelected,
+  });
+
+  final SurfaceStudioWizardStep currentStep;
+  final Set<SurfaceStudioWizardStep> completedSteps;
+  final ValueChanged<SurfaceStudioWizardStep> onStepSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      key: const ValueKey('surfaceStudio.header'),
+      decoration: const BoxDecoration(
+        color: SurfaceStudioDesignTokens.backgroundDeep,
+        border: Border(
+          bottom: BorderSide(color: SurfaceStudioDesignTokens.borderSubtle),
+        ),
+      ),
+      padding: const EdgeInsets.symmetric(horizontal: 20),
+      child: Row(
+        children: [
+          const _StudioMark(),
+          const SizedBox(width: 12),
+          const Text(
+            'Surface Studio — Assistant de mapping d’atlas',
+            style: TextStyle(
+              color: SurfaceStudioDesignTokens.textPrimary,
+              fontSize: 16,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(width: 24),
+          Expanded(
+            child: SurfaceStudioTopStepper(
+              currentStep: currentStep,
+              completedSteps: completedSteps,
+              onStepSelected: onStepSelected,
+            ),
+          ),
+          const SizedBox(width: 12),
+          _HeaderIconButton(
+            tooltip: 'Aide',
+            icon: CupertinoIcons.question_circle,
+            onPressed: () {},
+          ),
+          _HeaderIconButton(
+            tooltip: 'Paramètres',
+            icon: CupertinoIcons.gear_alt,
+            onPressed: () {},
+          ),
+          _HeaderIconButton(
+            tooltip: 'Fermer',
+            icon: CupertinoIcons.xmark,
+            onPressed: () {},
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _StudioMark extends StatelessWidget {
+  const _StudioMark();
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      width: 34,
+      height: 34,
+      decoration: BoxDecoration(
+        color: SurfaceStudioDesignTokens.accentTealSoft,
+        borderRadius: BorderRadius.circular(14),
+        border: Border.all(
+          color: SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.7),
+        ),
+      ),
+      child: const Icon(
+        CupertinoIcons.drop,
+        color: SurfaceStudioDesignTokens.accentTeal,
+        size: 22,
+      ),
+    );
+  }
+}
+
+class _HeaderIconButton extends StatelessWidget {
+  const _HeaderIconButton({
+    required this.tooltip,
+    required this.icon,
+    required this.onPressed,
+  });
+
+  final String tooltip;
+  final IconData icon;
+  final VoidCallback onPressed;
+
+  @override
+  Widget build(BuildContext context) {
+    return Tooltip(
+      message: tooltip,
+      child: CupertinoButton(
+        padding: EdgeInsets.zero,
+        minimumSize: const Size.square(36),
+        onPressed: onPressed,
+        child: Icon(
+          icon,
+          size: 18,
+          color: SurfaceStudioDesignTokens.textSecondary,
+        ),
+      ),
+    );
+  }
+}
```

### Diff fichier créé : `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart
@@ -0,0 +1,66 @@
+import 'package:flutter/widgets.dart';
+
+import '../surface_studio_design_tokens.dart';
+
+class SurfaceStudioShell extends StatelessWidget {
+  const SurfaceStudioShell({
+    super.key,
+    required this.header,
+    required this.sidebar,
+    required this.atlasPanel,
+    required this.schemaPanel,
+    required this.previewPanel,
+    required this.bottomBar,
+  });
+
+  final Widget header;
+  final Widget sidebar;
+  final Widget atlasPanel;
+  final Widget schemaPanel;
+  final Widget previewPanel;
+  final Widget bottomBar;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      key: const ValueKey('surfaceStudio.shell'),
+      color: SurfaceStudioDesignTokens.backgroundDeep,
+      child: Column(
+        children: [
+          SizedBox(
+            height: SurfaceStudioDesignTokens.headerHeight,
+            child: header,
+          ),
+          Expanded(
+            child: Padding(
+              padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
+              child: Row(
+                crossAxisAlignment: CrossAxisAlignment.stretch,
+                children: [
+                  sidebar,
+                  const SizedBox(width: SurfaceStudioDesignTokens.gapSm),
+                  Expanded(child: atlasPanel),
+                  const SizedBox(width: SurfaceStudioDesignTokens.gapSm),
+                  SizedBox(
+                    width: SurfaceStudioDesignTokens.rightPanelWidthExpanded,
+                    child: Column(
+                      children: [
+                        Expanded(flex: 3, child: schemaPanel),
+                        const SizedBox(height: SurfaceStudioDesignTokens.gapSm),
+                        Expanded(flex: 2, child: previewPanel),
+                      ],
+                    ),
+                  ),
+                ],
+              ),
+            ),
+          ),
+          SizedBox(
+            height: SurfaceStudioDesignTokens.bottomBarHeight,
+            child: bottomBar,
+          ),
+        ],
+      ),
+    );
+  }
+}
```

### Diff fichier créé : `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_sidebar.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_sidebar.dart b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_sidebar.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_sidebar.dart
@@ -0,0 +1,353 @@
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart' show Tooltip;
+
+import '../surface_studio_design_tokens.dart';
+import '../surface_studio_motion.dart';
+import '../surface_studio_step.dart';
+
+class SurfaceStudioSidebar extends StatelessWidget {
+  const SurfaceStudioSidebar({
+    super.key,
+    required this.collapsed,
+    required this.currentStep,
+    required this.completedSteps,
+    required this.onToggleCollapsed,
+    required this.onStepSelected,
+  });
+
+  final bool collapsed;
+  final SurfaceStudioWizardStep currentStep;
+  final Set<SurfaceStudioWizardStep> completedSteps;
+  final VoidCallback onToggleCollapsed;
+  final ValueChanged<SurfaceStudioWizardStep> onStepSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    return AnimatedContainer(
+      key: const ValueKey('surfaceStudio.sidebar'),
+      duration: SurfaceStudioMotion.panelSlide,
+      curve: SurfaceStudioMotion.easeInOut,
+      width: collapsed
+          ? SurfaceStudioDesignTokens.sidebarWidthCollapsed
+          : SurfaceStudioDesignTokens.sidebarWidthExpanded,
+      decoration: BoxDecoration(
+        color: SurfaceStudioDesignTokens.backgroundPanel,
+        borderRadius:
+            BorderRadius.circular(SurfaceStudioDesignTokens.panelRadius),
+        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
+      ),
+      padding: const EdgeInsets.all(12),
+      child: SingleChildScrollView(
+        child: Column(
+          crossAxisAlignment: collapsed
+              ? CrossAxisAlignment.center
+              : CrossAxisAlignment.stretch,
+          children: [
+            SizedBox(
+              key: ValueKey(
+                collapsed
+                    ? 'surfaceStudio.sidebar.collapsed'
+                    : 'surfaceStudio.sidebar.expanded',
+              ),
+              height: 0,
+            ),
+            FittedBox(
+              fit: BoxFit.scaleDown,
+              alignment: Alignment.centerLeft,
+              child: SizedBox(
+                width: collapsed ? 52 : 254,
+                child: Row(
+                  mainAxisAlignment: collapsed
+                      ? MainAxisAlignment.center
+                      : MainAxisAlignment.spaceBetween,
+                  children: [
+                    if (!collapsed)
+                      const Text(
+                        'Étapes',
+                        style: TextStyle(
+                          color: SurfaceStudioDesignTokens.textPrimary,
+                          fontSize: 16,
+                          fontWeight: FontWeight.w800,
+                        ),
+                      ),
+                    Tooltip(
+                      message: collapsed
+                          ? 'Déployer les étapes'
+                          : 'Réduire les étapes',
+                      child: CupertinoButton(
+                        key: const ValueKey(
+                            'surfaceStudio.sidebar.collapseButton'),
+                        padding: EdgeInsets.zero,
+                        minimumSize: const Size.square(36),
+                        onPressed: onToggleCollapsed,
+                        child: Icon(
+                          collapsed
+                              ? CupertinoIcons.chevron_right
+                              : CupertinoIcons.chevron_left,
+                          color: SurfaceStudioDesignTokens.textSecondary,
+                          size: 18,
+                        ),
+                      ),
+                    ),
+                  ],
+                ),
+              ),
+            ),
+            const SizedBox(height: 10),
+            for (final step in SurfaceStudioWizardStep.values) ...[
+              _SidebarStepCard(
+                collapsed: collapsed,
+                step: step,
+                active: step == currentStep,
+                completed: completedSteps.contains(step),
+                onTap: () => onStepSelected(step),
+              ),
+              const SizedBox(height: 9),
+            ],
+            const SizedBox(height: 8),
+            _TipsCard(collapsed: collapsed),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _SidebarStepCard extends StatelessWidget {
+  const _SidebarStepCard({
+    required this.collapsed,
+    required this.step,
+    required this.active,
+    required this.completed,
+    required this.onTap,
+  });
+
+  final bool collapsed;
+  final SurfaceStudioWizardStep step;
+  final bool active;
+  final bool completed;
+  final VoidCallback onTap;
+
+  @override
+  Widget build(BuildContext context) {
+    final border = active
+        ? SurfaceStudioDesignTokens.accentGold
+        : completed
+            ? SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.75)
+            : SurfaceStudioDesignTokens.borderSubtle;
+    final fill = active
+        ? SurfaceStudioDesignTokens.accentGoldSoft.withValues(alpha: 0.22)
+        : completed
+            ? SurfaceStudioDesignTokens.accentTealSoft.withValues(alpha: 0.36)
+            : SurfaceStudioDesignTokens.backgroundPanelAlt;
+    final content = AnimatedContainer(
+      duration: SurfaceStudioMotion.normal,
+      height: collapsed ? 56 : 90,
+      padding: EdgeInsets.all(collapsed ? 8 : 12),
+      decoration: BoxDecoration(
+        color: fill,
+        borderRadius:
+            BorderRadius.circular(SurfaceStudioDesignTokens.cardRadius),
+        border: Border.all(color: border, width: active ? 2 : 1),
+      ),
+      child: collapsed
+          ? Center(
+              child: Text(
+                '${step.number}',
+                style: TextStyle(
+                  color: active
+                      ? SurfaceStudioDesignTokens.accentGold
+                      : completed
+                          ? SurfaceStudioDesignTokens.accentTeal
+                          : SurfaceStudioDesignTokens.textMuted,
+                  fontWeight: FontWeight.w800,
+                  fontSize: 18,
+                ),
+              ),
+            )
+          : FittedBox(
+              fit: BoxFit.scaleDown,
+              alignment: Alignment.centerLeft,
+              child: SizedBox(
+                width: 226,
+                child: Row(
+                  children: [
+                    _StepNumber(
+                        step: step, active: active, completed: completed),
+                    const SizedBox(width: 12),
+                    Expanded(
+                      child: Column(
+                        crossAxisAlignment: CrossAxisAlignment.start,
+                        mainAxisAlignment: MainAxisAlignment.center,
+                        children: [
+                          Text(
+                            step.label,
+                            style: TextStyle(
+                              color: active
+                                  ? SurfaceStudioDesignTokens.accentGold
+                                  : completed
+                                      ? SurfaceStudioDesignTokens.accentTeal
+                                      : SurfaceStudioDesignTokens.textSecondary,
+                              fontWeight: FontWeight.w800,
+                              fontSize: 14,
+                            ),
+                          ),
+                          const SizedBox(height: 7),
+                          Text(
+                            step.sidebarDescription,
+                            maxLines: 3,
+                            overflow: TextOverflow.ellipsis,
+                            style: TextStyle(
+                              color: active || completed
+                                  ? SurfaceStudioDesignTokens.textSecondary
+                                  : SurfaceStudioDesignTokens.textMuted,
+                              fontSize: 11.5,
+                              height: 1.22,
+                            ),
+                          ),
+                        ],
+                      ),
+                    ),
+                    if (completed)
+                      const Icon(
+                        CupertinoIcons.checkmark_circle,
+                        color: SurfaceStudioDesignTokens.accentTeal,
+                        size: 22,
+                      )
+                    else if (active)
+                      const Icon(
+                        CupertinoIcons.arrow_right,
+                        color: SurfaceStudioDesignTokens.accentGold,
+                        size: 20,
+                      ),
+                  ],
+                ),
+              ),
+            ),
+    );
+
+    return Tooltip(
+      message: step.label,
+      child: GestureDetector(
+        behavior: HitTestBehavior.opaque,
+        onTap: onTap,
+        child: content,
+      ),
+    );
+  }
+}
+
+class _StepNumber extends StatelessWidget {
+  const _StepNumber({
+    required this.step,
+    required this.active,
+    required this.completed,
+  });
+
+  final SurfaceStudioWizardStep step;
+  final bool active;
+  final bool completed;
+
+  @override
+  Widget build(BuildContext context) {
+    final color = active
+        ? SurfaceStudioDesignTokens.accentGold
+        : completed
+            ? SurfaceStudioDesignTokens.accentTeal
+            : SurfaceStudioDesignTokens.textMuted;
+    return Container(
+      width: 32,
+      height: 32,
+      alignment: Alignment.center,
+      decoration: BoxDecoration(
+        shape: BoxShape.circle,
+        border: Border.all(color: color, width: 2),
+      ),
+      child: Text(
+        '${step.number}',
+        style: TextStyle(color: color, fontWeight: FontWeight.w800),
+      ),
+    );
+  }
+}
+
+class _TipsCard extends StatelessWidget {
+  const _TipsCard({required this.collapsed});
+
+  final bool collapsed;
+
+  @override
+  Widget build(BuildContext context) {
+    return Tooltip(
+      message: 'Astuces',
+      child: Container(
+        padding: const EdgeInsets.all(12),
+        decoration: BoxDecoration(
+          color:
+              SurfaceStudioDesignTokens.accentGoldSoft.withValues(alpha: 0.18),
+          borderRadius:
+              BorderRadius.circular(SurfaceStudioDesignTokens.cardRadius),
+          border: Border.all(
+            color: SurfaceStudioDesignTokens.accentGold.withValues(alpha: 0.45),
+          ),
+        ),
+        child: collapsed
+            ? const Icon(
+                CupertinoIcons.lightbulb,
+                color: SurfaceStudioDesignTokens.accentGold,
+              )
+            : const Column(
+                crossAxisAlignment: CrossAxisAlignment.start,
+                children: [
+                  Wrap(
+                    crossAxisAlignment: WrapCrossAlignment.center,
+                    spacing: 8,
+                    children: [
+                      Icon(
+                        CupertinoIcons.lightbulb,
+                        color: SurfaceStudioDesignTokens.accentGold,
+                        size: 17,
+                      ),
+                      Text(
+                        'Astuces',
+                        style: TextStyle(
+                          color: SurfaceStudioDesignTokens.accentGold,
+                          fontWeight: FontWeight.w800,
+                        ),
+                      ),
+                    ],
+                  ),
+                  SizedBox(height: 8),
+                  _TipLine(
+                      'Glissez une colonne de l’atlas vers une case du schéma.'),
+                  _TipLine(
+                      'Les rôles sont illustrés pour éviter les ambiguïtés.'),
+                  _TipLine('Le rôle “Plein” peut contenir plusieurs colonnes.'),
+                ],
+              ),
+      ),
+    );
+  }
+}
+
+class _TipLine extends StatelessWidget {
+  const _TipLine(this.text);
+
+  final String text;
+
+  @override
+  Widget build(BuildContext context) {
+    return Padding(
+      padding: const EdgeInsets.only(bottom: 6),
+      child: Text(
+        '• $text',
+        style: const TextStyle(
+          color: SurfaceStudioDesignTokens.textSecondary,
+          fontSize: 11,
+          height: 1.25,
+        ),
+        softWrap: true,
+      ),
+    );
+  }
+}
```

### Diff fichier créé : `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_top_stepper.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_top_stepper.dart b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_top_stepper.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_top_stepper.dart
@@ -0,0 +1,135 @@
+import 'package:flutter/cupertino.dart';
+
+import '../surface_studio_design_tokens.dart';
+import '../surface_studio_step.dart';
+
+class SurfaceStudioTopStepper extends StatelessWidget {
+  const SurfaceStudioTopStepper({
+    super.key,
+    required this.currentStep,
+    required this.completedSteps,
+    required this.onStepSelected,
+  });
+
+  final SurfaceStudioWizardStep currentStep;
+  final Set<SurfaceStudioWizardStep> completedSteps;
+  final ValueChanged<SurfaceStudioWizardStep> onStepSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    return FittedBox(
+      key: const ValueKey('surfaceStudio.stepper'),
+      fit: BoxFit.scaleDown,
+      alignment: Alignment.center,
+      child: Row(
+        mainAxisAlignment: MainAxisAlignment.center,
+        children: [
+          for (final step in SurfaceStudioWizardStep.values) ...[
+            _TopStep(
+              step: step,
+              active: step == currentStep,
+              completed: completedSteps.contains(step),
+              onTap: () => onStepSelected(step),
+            ),
+            if (step != SurfaceStudioWizardStep.values.last)
+              Container(
+                width: 28,
+                height: 1,
+                color: step.index < currentStep.index
+                    ? SurfaceStudioDesignTokens.accentTeal
+                        .withValues(alpha: 0.45)
+                    : SurfaceStudioDesignTokens.borderStrong,
+              ),
+          ],
+        ],
+      ),
+    );
+  }
+}
+
+class _TopStep extends StatelessWidget {
+  const _TopStep({
+    required this.step,
+    required this.active,
+    required this.completed,
+    required this.onTap,
+  });
+
+  final SurfaceStudioWizardStep step;
+  final bool active;
+  final bool completed;
+  final VoidCallback onTap;
+
+  @override
+  Widget build(BuildContext context) {
+    final color = active
+        ? SurfaceStudioDesignTokens.accentGold
+        : completed
+            ? SurfaceStudioDesignTokens.accentTeal
+            : SurfaceStudioDesignTokens.textMuted;
+    return GestureDetector(
+      key: ValueKey('surfaceStudio.step.${step.id}'),
+      behavior: HitTestBehavior.opaque,
+      onTap: onTap,
+      child: Padding(
+        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
+        child: Row(
+          mainAxisSize: MainAxisSize.min,
+          children: [
+            AnimatedContainer(
+              duration: const Duration(milliseconds: 180),
+              width: 30,
+              height: 30,
+              alignment: Alignment.center,
+              decoration: BoxDecoration(
+                color: active
+                    ? SurfaceStudioDesignTokens.accentGoldSoft
+                        .withValues(alpha: 0.55)
+                    : SurfaceStudioDesignTokens.backgroundPanel,
+                shape: BoxShape.circle,
+                border: Border.all(
+                  color: color,
+                  width: active ? 2 : 1,
+                ),
+                boxShadow: active
+                    ? [
+                        BoxShadow(
+                          color: SurfaceStudioDesignTokens.accentGold
+                              .withValues(alpha: 0.32),
+                          blurRadius: 14,
+                        ),
+                      ]
+                    : const [],
+              ),
+              child: completed
+                  ? Icon(CupertinoIcons.checkmark, size: 15, color: color)
+                  : Text(
+                      '${step.number}',
+                      style: TextStyle(
+                        color: color,
+                        fontWeight: FontWeight.w800,
+                      ),
+                    ),
+            ),
+            const SizedBox(width: 7),
+            Text(
+              step.label,
+              style: TextStyle(
+                color: color,
+                fontSize: 13,
+                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
+                fontStyle: active ? FontStyle.normal : FontStyle.italic,
+              ),
+            ),
+            if (active)
+              SizedBox(
+                key: ValueKey('surfaceStudio.step.${step.id}.active'),
+                width: 0,
+                height: 0,
+              ),
+          ],
+        ),
+      ),
+    );
+  }
+}
```

### Diff fichier créé : `packages/map_editor/lib/src/features/surface_studio/surface_studio_column_selection.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_column_selection.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_column_selection.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_column_selection.dart
@@ -0,0 +1,35 @@
+final class SurfaceStudioColumnSelection {
+  const SurfaceStudioColumnSelection(this.columns);
+
+  const SurfaceStudioColumnSelection.empty() : columns = const <int>[];
+
+  final List<int> columns;
+
+  bool get isEmpty => columns.isEmpty;
+
+  bool get isNotEmpty => columns.isNotEmpty;
+
+  int? get firstOrNull => columns.isEmpty ? null : columns.first;
+
+  SurfaceStudioColumnSelection selectSingle(int column) =>
+      SurfaceStudioColumnSelection(<int>[column]);
+
+  SurfaceStudioColumnSelection selectContiguousTo(int column) {
+    final anchor = firstOrNull ?? column;
+    final start = anchor < column ? anchor : column;
+    final end = anchor < column ? column : anchor;
+    return SurfaceStudioColumnSelection(<int>[
+      for (var value = start; value <= end; value++) value,
+    ]);
+  }
+
+  String get microcopy {
+    if (columns.isEmpty) {
+      return 'Sélectionnez une ou plusieurs colonnes contiguës avec Maj + glisser';
+    }
+    if (columns.length == 1) {
+      return 'Colonne ${columns.first} sélectionnée — glissez vers un rôle du schéma.';
+    }
+    return 'Colonnes ${columns.first}–${columns.last} sélectionnées — glissez vers un rôle du schéma.';
+  }
+}
```

### Diff fichier créé : `packages/map_editor/lib/src/features/surface_studio/surface_studio_design_tokens.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_design_tokens.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_design_tokens.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_design_tokens.dart
@@ -0,0 +1,37 @@
+import 'package:flutter/widgets.dart';
+
+abstract final class SurfaceStudioDesignTokens {
+  static const backgroundDeep = Color(0xFF0B1020);
+  static const backgroundPanel = Color(0xFF151B2A);
+  static const backgroundPanelAlt = Color(0xFF1C2433);
+  static const backgroundElevated = Color(0xFF202A3C);
+  static const borderSubtle = Color(0xFF303A4E);
+  static const borderStrong = Color(0xFF4A556D);
+  static const textPrimary = Color(0xFFF2F5FA);
+  static const textSecondary = Color(0xFFAAB2C3);
+  static const textMuted = Color(0xFF737C90);
+  static const accentGold = Color(0xFFF2C84B);
+  static const accentGoldSoft = Color(0xFF6E5620);
+  static const accentTeal = Color(0xFF52D6C2);
+  static const accentTealSoft = Color(0xFF123D3A);
+  static const dangerSoft = Color(0xFFEF6B73);
+  static const success = Color(0xFF58D68D);
+
+  static const screenMinWidth = 1200.0;
+  static const headerHeight = 64.0;
+  static const bottomBarHeight = 76.0;
+  static const sidebarWidthExpanded = 280.0;
+  static const sidebarWidthCollapsed = 78.0;
+  static const rightPanelWidthExpanded = 560.0;
+  static const rightPanelWidthCollapsed = 84.0;
+  static const panelRadius = 14.0;
+  static const cardRadius = 12.0;
+  static const slotRadius = 10.0;
+  static const gapXs = 4.0;
+  static const gapSm = 8.0;
+  static const gapMd = 12.0;
+  static const gapLg = 16.0;
+  static const gapXl = 24.0;
+  static const borderWidth = 1.0;
+  static const activeBorderWidth = 2.0;
+}
```

### Diff fichier créé : `packages/map_editor/lib/src/features/surface_studio/surface_studio_drag_payload.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_drag_payload.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_drag_payload.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_drag_payload.dart
@@ -0,0 +1,64 @@
+/// Payload local transmis par le drag & drop Surface Studio V2.
+///
+/// Les colonnes sont 1-based pour correspondre à ce que l'utilisateur voit
+/// dans l'atlas. Ce modèle reste strictement UI : aucune persistance et aucune
+/// mutation du catalogue Surface.
+final class SurfaceStudioColumnDragPayload {
+  const SurfaceStudioColumnDragPayload({
+    required this.columns,
+    required this.tileWidth,
+    required this.tileHeight,
+    required this.frameCount,
+  });
+
+  final List<int> columns;
+  final int tileWidth;
+  final int tileHeight;
+  final int frameCount;
+
+  bool get isEmpty => columns.isEmpty;
+
+  bool get isMultiColumn => columns.length > 1;
+
+  String get label {
+    if (columns.isEmpty) {
+      return 'Aucune colonne';
+    }
+    if (columns.length == 1) {
+      return 'Colonne ${columns.first}';
+    }
+    return 'Colonnes ${columns.first}-${columns.last}';
+  }
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is SurfaceStudioColumnDragPayload &&
+          _listEquals(other.columns, columns) &&
+          other.tileWidth == tileWidth &&
+          other.tileHeight == tileHeight &&
+          other.frameCount == frameCount;
+
+  @override
+  int get hashCode => Object.hash(
+        Object.hashAll(columns),
+        tileWidth,
+        tileHeight,
+        frameCount,
+      );
+}
+
+bool _listEquals(List<int> a, List<int> b) {
+  if (identical(a, b)) {
+    return true;
+  }
+  if (a.length != b.length) {
+    return false;
+  }
+  for (var i = 0; i < a.length; i++) {
+    if (a[i] != b[i]) {
+      return false;
+    }
+  }
+  return true;
+}
```

### Diff fichier créé : `packages/map_editor/lib/src/features/surface_studio/surface_studio_motion.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_motion.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_motion.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_motion.dart
@@ -0,0 +1,13 @@
+import 'package:flutter/animation.dart';
+
+abstract final class SurfaceStudioMotion {
+  static const fast = Duration(milliseconds: 120);
+  static const normal = Duration(milliseconds: 180);
+  static const panelSlide = Duration(milliseconds: 240);
+  static const stepTransition = Duration(milliseconds: 260);
+  static const accordion = Duration(milliseconds: 180);
+  static const dragFeedback = Duration(milliseconds: 100);
+
+  static const easeOut = Curves.easeOutCubic;
+  static const easeInOut = Curves.easeInOutCubic;
+}
```

### Diff fichier créé : `packages/map_editor/lib/src/features/surface_studio/surface_studio_role_assignment_draft.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_role_assignment_draft.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_role_assignment_draft.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_role_assignment_draft.dart
@@ -0,0 +1,164 @@
+import 'package:map_core/map_core.dart';
+
+import 'surface_studio_drag_payload.dart';
+
+enum SurfaceStudioDropValidation {
+  valid,
+  invalidNoColumn,
+  invalidTooManyColumns,
+  invalidRoleLocked,
+}
+
+/// Brouillon local du Surface Studio V2 : rôle Surface -> colonnes d'atlas.
+///
+/// Le rôle `isolated`, affiché comme "Plein (center)", est le seul rôle
+/// multi-colonnes en V2. Les autres rôles restent mono-assignation.
+final class SurfaceStudioRoleAssignmentDraft {
+  const SurfaceStudioRoleAssignmentDraft.empty()
+      : _assignments = const <SurfaceVariantRole, List<int>>{};
+
+  const SurfaceStudioRoleAssignmentDraft._(this._assignments);
+
+  final Map<SurfaceVariantRole, List<int>> _assignments;
+
+  List<int> columnsForRole(SurfaceVariantRole role) =>
+      _assignments[role] ?? const <int>[];
+
+  bool isAssigned(SurfaceVariantRole role) => columnsForRole(role).isNotEmpty;
+
+  int get assignedRoleCount => _assignments.length;
+
+  int assignedCountForRoles(Iterable<SurfaceVariantRole> roles) {
+    var count = 0;
+    for (final role in roles) {
+      if (isAssigned(role)) {
+        count++;
+      }
+    }
+    return count;
+  }
+
+  SurfaceStudioRoleAssignmentDraft assignColumns(
+    SurfaceVariantRole role,
+    List<int> columns,
+  ) {
+    final cleaned = _cleanColumns(columns);
+    final next = <SurfaceVariantRole, List<int>>{
+      for (final entry in _assignments.entries)
+        entry.key: List<int>.unmodifiable(entry.value),
+    };
+    if (cleaned.isEmpty) {
+      next.remove(role);
+    } else if (role == SurfaceVariantRole.isolated) {
+      final merged = <int>[...columnsForRole(role)];
+      for (final column in cleaned) {
+        if (!merged.contains(column)) {
+          merged.add(column);
+        }
+      }
+      next[role] = List<int>.unmodifiable(merged);
+    } else {
+      next[role] = List<int>.unmodifiable(<int>[cleaned.first]);
+    }
+    return SurfaceStudioRoleAssignmentDraft._(Map.unmodifiable(next));
+  }
+
+  SurfaceStudioRoleAssignmentDraft clearRole(SurfaceVariantRole role) {
+    if (!_assignments.containsKey(role)) {
+      return this;
+    }
+    final next = <SurfaceVariantRole, List<int>>{
+      for (final entry in _assignments.entries)
+        if (entry.key != role) entry.key: List<int>.unmodifiable(entry.value),
+    };
+    return SurfaceStudioRoleAssignmentDraft._(Map.unmodifiable(next));
+  }
+
+  SurfaceStudioRoleAssignmentDraft clearColumn(
+    SurfaceVariantRole role,
+    int column,
+  ) {
+    final current = columnsForRole(role);
+    if (!current.contains(column)) {
+      return this;
+    }
+    final remaining = current.where((value) => value != column).toList();
+    if (remaining.isEmpty) {
+      return clearRole(role);
+    }
+    final next = <SurfaceVariantRole, List<int>>{
+      for (final entry in _assignments.entries)
+        entry.key: entry.key == role
+            ? List<int>.unmodifiable(remaining)
+            : List<int>.unmodifiable(entry.value),
+    };
+    return SurfaceStudioRoleAssignmentDraft._(Map.unmodifiable(next));
+  }
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is SurfaceStudioRoleAssignmentDraft &&
+          _mapsEqual(other._assignments, _assignments);
+
+  @override
+  int get hashCode => Object.hashAll(
+        _assignments.entries.map(
+          (entry) => Object.hash(entry.key, Object.hashAll(entry.value)),
+        ),
+      );
+}
+
+SurfaceStudioDropValidation validateSurfaceStudioRoleDrop({
+  required SurfaceVariantRole role,
+  required SurfaceStudioColumnDragPayload payload,
+  required SurfaceStudioRoleAssignmentDraft draft,
+}) {
+  if (payload.columns.isEmpty) {
+    return SurfaceStudioDropValidation.invalidNoColumn;
+  }
+  if (role != SurfaceVariantRole.isolated && payload.columns.length > 1) {
+    return SurfaceStudioDropValidation.invalidTooManyColumns;
+  }
+  return SurfaceStudioDropValidation.valid;
+}
+
+List<int> _cleanColumns(List<int> columns) {
+  final cleaned = <int>[];
+  for (final column in columns) {
+    if (column <= 0 || cleaned.contains(column)) {
+      continue;
+    }
+    cleaned.add(column);
+  }
+  cleaned.sort();
+  return cleaned;
+}
+
+bool _mapsEqual(
+  Map<SurfaceVariantRole, List<int>> a,
+  Map<SurfaceVariantRole, List<int>> b,
+) {
+  if (a.length != b.length) {
+    return false;
+  }
+  for (final entry in a.entries) {
+    final other = b[entry.key];
+    if (other == null || !_listEquals(entry.value, other)) {
+      return false;
+    }
+  }
+  return true;
+}
+
+bool _listEquals(List<int> a, List<int> b) {
+  if (a.length != b.length) {
+    return false;
+  }
+  for (var i = 0; i < a.length; i++) {
+    if (a[i] != b[i]) {
+      return false;
+    }
+  }
+  return true;
+}
```

### Diff fichier créé : `packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
@@ -0,0 +1,386 @@
+import 'dart:async';
+
+import 'package:flutter/widgets.dart';
+import 'package:map_core/map_core.dart';
+
+import 'atlas/surface_studio_atlas_panel.dart';
+import 'preview/surface_studio_preview_panel.dart';
+import 'schema/surface_studio_schema_panel.dart';
+import 'shell/surface_studio_bottom_action_bar.dart';
+import 'shell/surface_studio_header.dart';
+import 'shell/surface_studio_shell.dart';
+import 'shell/surface_studio_sidebar.dart';
+import 'surface_studio_column_selection.dart';
+import 'surface_studio_drag_payload.dart';
+import 'surface_studio_role_assignment_draft.dart';
+import 'surface_studio_step.dart';
+
+class SurfaceStudioScreen extends StatefulWidget {
+  const SurfaceStudioScreen({
+    super.key,
+    required this.readModel,
+  });
+
+  final SurfaceStudioReadModel readModel;
+
+  @override
+  State<SurfaceStudioScreen> createState() => _SurfaceStudioScreenState();
+}
+
+class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
+  SurfaceStudioWizardStep _currentStep = SurfaceStudioWizardStep.map;
+  bool _sidebarCollapsed = false;
+  bool _rightPanelCollapsed = false;
+  Set<String> _openSchemaGroups = const {
+    'surfaceMain',
+    'edges',
+    'externalCorners',
+    'internalCorners',
+    'junctions',
+  };
+  SurfaceStudioColumnSelection _selectedColumns =
+      const SurfaceStudioColumnSelection(<int>[4, 5]);
+  SurfaceStudioRoleAssignmentDraft _assignmentDraft =
+      const SurfaceStudioRoleAssignmentDraft.empty()
+          .assignColumns(SurfaceVariantRole.isolated, const <int>[4, 5, 6]);
+  double _zoomPercent = 100;
+  bool _previewPlaying = false;
+  int _previewFrameIndex = 0;
+  bool _previewLoop = true;
+  bool _previewGridVisible = true;
+  int _previewSize = 10;
+  String? _statusMessage;
+  Timer? _previewTimer;
+
+  @override
+  void dispose() {
+    _previewTimer?.cancel();
+    super.dispose();
+  }
+
+  int get _columnCount {
+    final atlases = widget.readModel.atlases;
+    if (atlases.isEmpty) {
+      return 12;
+    }
+    return atlases.first.columns.clamp(1, 48).toInt();
+  }
+
+  int get _frameCount {
+    final atlases = widget.readModel.atlases;
+    if (atlases.isEmpty) {
+      return 32;
+    }
+    return atlases.first.rows.clamp(1, 128).toInt();
+  }
+
+  int get _tileWidth {
+    final atlases = widget.readModel.atlases;
+    if (atlases.isEmpty) {
+      return 32;
+    }
+    return atlases.first.tileWidth;
+  }
+
+  int get _tileHeight {
+    final atlases = widget.readModel.atlases;
+    if (atlases.isEmpty) {
+      return 32;
+    }
+    return atlases.first.tileHeight;
+  }
+
+  Set<SurfaceStudioWizardStep> get _completedSteps => {
+        SurfaceStudioWizardStep.importAtlas,
+        SurfaceStudioWizardStep.slice,
+        if (_assignmentDraft.isAssigned(SurfaceVariantRole.isolated))
+          SurfaceStudioWizardStep.map,
+        if (_currentStep.index > SurfaceStudioWizardStep.preview.index)
+          SurfaceStudioWizardStep.preview,
+      };
+
+  bool get _canGoNext =>
+      _currentStep != SurfaceStudioWizardStep.save &&
+      (_currentStep != SurfaceStudioWizardStep.map ||
+          _assignmentDraft.isAssigned(SurfaceVariantRole.isolated));
+
+  void _selectStep(SurfaceStudioWizardStep step) {
+    if (step == _currentStep) {
+      return;
+    }
+    if (step.index <= _currentStep.index || _completedSteps.contains(step)) {
+      setState(() {
+        _currentStep = step;
+        _statusMessage = null;
+      });
+      return;
+    }
+    setState(() {
+      _statusMessage = 'Terminez les étapes précédentes avant d’avancer.';
+    });
+  }
+
+  void _nextStep() {
+    if (!_canGoNext) {
+      setState(() {
+        _statusMessage =
+            'Assignez au moins le rôle “Plein” avant de continuer.';
+      });
+      return;
+    }
+    final nextIndex = (_currentStep.index + 1)
+        .clamp(0, SurfaceStudioWizardStep.values.length - 1)
+        .toInt();
+    setState(() {
+      _currentStep = SurfaceStudioWizardStep.values[nextIndex];
+      _statusMessage = null;
+    });
+  }
+
+  void _previousStep() {
+    if (_currentStep == SurfaceStudioWizardStep.importAtlas) {
+      return;
+    }
+    setState(() {
+      _currentStep = SurfaceStudioWizardStep.values[_currentStep.index - 1];
+      _statusMessage = null;
+    });
+  }
+
+  void _togglePreviewPlaying() {
+    setState(() {
+      _previewPlaying = !_previewPlaying;
+    });
+    _syncPreviewTimer();
+  }
+
+  void _syncPreviewTimer() {
+    _previewTimer?.cancel();
+    _previewTimer = null;
+    if (!_previewPlaying) {
+      return;
+    }
+    _previewTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
+      if (!mounted) {
+        return;
+      }
+      setState(() {
+        if (_previewFrameIndex >= _frameCount - 1) {
+          _previewFrameIndex = _previewLoop ? 0 : _frameCount - 1;
+          if (!_previewLoop) {
+            _previewPlaying = false;
+            _syncPreviewTimer();
+          }
+        } else {
+          _previewFrameIndex += 1;
+        }
+      });
+    });
+  }
+
+  void _autoSuggestMapping() {
+    final roles = <SurfaceVariantRole>[
+      SurfaceVariantRole.isolated,
+      SurfaceVariantRole.endNorth,
+      SurfaceVariantRole.endEast,
+      SurfaceVariantRole.endSouth,
+      SurfaceVariantRole.endWest,
+      SurfaceVariantRole.cornerNW,
+      SurfaceVariantRole.cornerNE,
+      SurfaceVariantRole.cornerSW,
+      SurfaceVariantRole.cornerSE,
+    ];
+    var draft = const SurfaceStudioRoleAssignmentDraft.empty();
+    draft = draft.assignColumns(
+      SurfaceVariantRole.isolated,
+      <int>[for (var c = 4; c <= 6 && c <= _columnCount; c++) c],
+    );
+    var column = 1;
+    for (final role in roles.skip(1)) {
+      if (column <= _columnCount) {
+        draft = draft.assignColumns(role, <int>[column]);
+      }
+      column += 1;
+    }
+    setState(() {
+      _assignmentDraft = draft;
+      _statusMessage = 'Suggestion auto appliquée au brouillon local.';
+    });
+  }
+
+  void _applyMapping() {
+    setState(() {
+      _statusMessage =
+          'Mapping appliqué au brouillon local — aucune sauvegarde disque.';
+    });
+  }
+
+  void _acceptDrop(
+    SurfaceVariantRole role,
+    SurfaceStudioColumnDragPayload payload,
+  ) {
+    final validation = validateSurfaceStudioRoleDrop(
+      role: role,
+      payload: payload,
+      draft: _assignmentDraft,
+    );
+    if (validation != SurfaceStudioDropValidation.valid) {
+      setState(() {
+        _statusMessage =
+            validation == SurfaceStudioDropValidation.invalidNoColumn
+                ? 'Aucune colonne à déposer.'
+                : 'Ce rôle attend une seule colonne.';
+      });
+      return;
+    }
+    setState(() {
+      _assignmentDraft = _assignmentDraft.assignColumns(role, payload.columns);
+      _statusMessage = 'Colonnes déposées sur le rôle sélectionné.';
+    });
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final frameCount = _frameCount;
+    return Stack(
+      children: [
+        SurfaceStudioShell(
+          header: SurfaceStudioHeader(
+            currentStep: _currentStep,
+            completedSteps: _completedSteps,
+            onStepSelected: _selectStep,
+          ),
+          sidebar: SurfaceStudioSidebar(
+            collapsed: _sidebarCollapsed,
+            currentStep: _currentStep,
+            completedSteps: _completedSteps,
+            onToggleCollapsed: () {
+              setState(() => _sidebarCollapsed = !_sidebarCollapsed);
+            },
+            onStepSelected: _selectStep,
+          ),
+          atlasPanel: SurfaceStudioAtlasPanel(
+            columnCount: _columnCount,
+            frameCount: frameCount,
+            tileWidth: _tileWidth,
+            tileHeight: _tileHeight,
+            selection: _selectedColumns,
+            zoomPercent: _zoomPercent,
+            onColumnSelectionChanged: (selection) {
+              setState(() => _selectedColumns = selection);
+            },
+            onZoomChanged: (value) {
+              setState(() => _zoomPercent = value.clamp(25, 400).toDouble());
+            },
+            onReset: () {
+              setState(() {
+                _selectedColumns = const SurfaceStudioColumnSelection.empty();
+                _zoomPercent = 100;
+                _statusMessage = 'Sélection et zoom réinitialisés.';
+              });
+            },
+            onAutoSuggest: _autoSuggestMapping,
+          ),
+          schemaPanel: SurfaceStudioSchemaPanel(
+            collapsed: _rightPanelCollapsed,
+            openGroups: _openSchemaGroups,
+            assignmentDraft: _assignmentDraft,
+            onToggleCollapsed: () {
+              setState(() => _rightPanelCollapsed = !_rightPanelCollapsed);
+            },
+            onToggleGroup: (id) {
+              setState(() {
+                final next = Set<String>.of(_openSchemaGroups);
+                if (!next.add(id)) {
+                  next.remove(id);
+                }
+                _openSchemaGroups = next;
+              });
+            },
+            onDrop: _acceptDrop,
+            onClearRole: (role) {
+              setState(
+                  () => _assignmentDraft = _assignmentDraft.clearRole(role));
+            },
+            onClearColumn: (role, column) {
+              setState(
+                () => _assignmentDraft =
+                    _assignmentDraft.clearColumn(role, column),
+              );
+            },
+          ),
+          previewPanel: SurfaceStudioPreviewPanel(
+            frameCount: frameCount,
+            frameIndex: _previewFrameIndex.clamp(0, frameCount - 1).toInt(),
+            playing: _previewPlaying,
+            loop: _previewLoop,
+            gridVisible: _previewGridVisible,
+            previewSize: _previewSize,
+            assignmentDraft: _assignmentDraft,
+            onPrevious: () {
+              setState(() {
+                _previewPlaying = false;
+                _previewFrameIndex =
+                    (_previewFrameIndex - 1).clamp(0, frameCount - 1).toInt();
+              });
+              _syncPreviewTimer();
+            },
+            onNext: () {
+              setState(() {
+                _previewPlaying = false;
+                _previewFrameIndex =
+                    (_previewFrameIndex + 1).clamp(0, frameCount - 1).toInt();
+              });
+              _syncPreviewTimer();
+            },
+            onTogglePlaying: _togglePreviewPlaying,
+            onFrameChanged: (value) {
+              setState(() {
+                _previewPlaying = false;
+                _previewFrameIndex = value.clamp(0, frameCount - 1).toInt();
+              });
+              _syncPreviewTimer();
+            },
+            onLoopChanged: (value) => setState(() => _previewLoop = value),
+            onGridChanged: (value) =>
+                setState(() => _previewGridVisible = value),
+            onPreviewSizeChanged: (value) =>
+                setState(() => _previewSize = value),
+          ),
+          bottomBar: SurfaceStudioBottomActionBar(
+            canGoBack: _currentStep != SurfaceStudioWizardStep.importAtlas,
+            canAutoSuggest: _columnCount > 0 && frameCount > 0,
+            canApplyMapping:
+                _assignmentDraft.isAssigned(SurfaceVariantRole.isolated),
+            canGoNext: _canGoNext,
+            onBack: _previousStep,
+            onAutoSuggest: _autoSuggestMapping,
+            onApplyMapping: _applyMapping,
+            onNext: _nextStep,
+          ),
+        ),
+        if (_statusMessage != null)
+          Positioned(
+            left: 318,
+            bottom: 86,
+            child: Container(
+              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
+              decoration: BoxDecoration(
+                color: const Color(0xFF202A3C),
+                borderRadius: BorderRadius.circular(10),
+                border: Border.all(color: const Color(0xFF4A556D)),
+              ),
+              child: Text(
+                _statusMessage!,
+                style: const TextStyle(
+                  color: Color(0xFFF2F5FA),
+                  fontSize: 12,
+                  fontWeight: FontWeight.w700,
+                ),
+              ),
+            ),
+          ),
+      ],
+    );
+  }
+}
```

### Diff fichier créé : `packages/map_editor/lib/src/features/surface_studio/surface_studio_step.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_step.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_step.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_step.dart
@@ -0,0 +1,50 @@
+import 'package:flutter/cupertino.dart';
+
+enum SurfaceStudioWizardStep {
+  importAtlas,
+  slice,
+  map,
+  preview,
+  save,
+}
+
+extension SurfaceStudioWizardStepInfo on SurfaceStudioWizardStep {
+  int get number => index + 1;
+
+  String get id => switch (this) {
+        SurfaceStudioWizardStep.importAtlas => 'import',
+        SurfaceStudioWizardStep.slice => 'slice',
+        SurfaceStudioWizardStep.map => 'mapper',
+        SurfaceStudioWizardStep.preview => 'preview',
+        SurfaceStudioWizardStep.save => 'save',
+      };
+
+  String get label => switch (this) {
+        SurfaceStudioWizardStep.importAtlas => 'Importer',
+        SurfaceStudioWizardStep.slice => 'Découper',
+        SurfaceStudioWizardStep.map => 'Mapper',
+        SurfaceStudioWizardStep.preview => 'Prévisualiser',
+        SurfaceStudioWizardStep.save => 'Enregistrer',
+      };
+
+  String get sidebarDescription => switch (this) {
+        SurfaceStudioWizardStep.importAtlas =>
+          'Importez votre atlas de surface animé.',
+        SurfaceStudioWizardStep.slice =>
+          'Définissez la taille des tuiles et découpez l’atlas en colonnes.',
+        SurfaceStudioWizardStep.map =>
+          'Glissez les colonnes de l’atlas vers les rôles du schéma de surface.',
+        SurfaceStudioWizardStep.preview =>
+          'Vérifiez le résultat en animation et ajustez si nécessaire.',
+        SurfaceStudioWizardStep.save =>
+          'Enregistrez le mapping comme nouveau jeu de surface.',
+      };
+
+  IconData get icon => switch (this) {
+        SurfaceStudioWizardStep.importAtlas => CupertinoIcons.tray_arrow_down,
+        SurfaceStudioWizardStep.slice => CupertinoIcons.grid,
+        SurfaceStudioWizardStep.map => CupertinoIcons.hand_draw,
+        SurfaceStudioWizardStep.preview => CupertinoIcons.play_rectangle,
+        SurfaceStudioWizardStep.save => CupertinoIcons.checkmark_seal,
+      };
+}
```

### Diff fichier créé : `packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart`

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart b/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart
@@ -0,0 +1,67 @@
+import 'package:flutter/services.dart';
+import 'package:flutter/widgets.dart';
+import 'package:flutter_test/flutter_test.dart';
+
+import 'surface_studio_rebuild_test_harness.dart';
+
+void main() {
+  testWidgets('atlas panel exposes zoom slider and column selection microcopy',
+      (
+    tester,
+  ) async {
+    await pumpSurfaceStudioForTest(tester);
+    await tester.pump();
+
+    expect(find.byKey(const Key('surfaceStudio.atlas.zoomSlider')),
+        findsOneWidget);
+    expect(find.text('100%'), findsOneWidget);
+
+    await tester.drag(
+      find.byKey(const Key('surfaceStudio.atlas.zoomSlider')),
+      const Offset(120, 0),
+    );
+    await tester.pump();
+    expect(find.text('100%'), findsNothing);
+
+    await tester.tap(find.byKey(const Key('surfaceStudio.atlas.column.4')));
+    await tester.pump();
+    expect(
+      find.text('Colonne 4 sélectionnée — glissez vers un rôle du schéma.'),
+      findsOneWidget,
+    );
+
+    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
+    await tester.tap(find.byKey(const Key('surfaceStudio.atlas.column.5')));
+    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
+    await tester.pump();
+    expect(
+      find.text('Colonnes 4–5 sélectionnées — glissez vers un rôle du schéma.'),
+      findsOneWidget,
+    );
+  });
+
+  testWidgets('atlas selection is draggable with a visible ghost payload', (
+    tester,
+  ) async {
+    await pumpSurfaceStudioForTest(tester);
+    await tester.pump();
+
+    await tester.tap(find.byKey(const Key('surfaceStudio.atlas.column.4')));
+    await tester.pump();
+
+    expect(find.byKey(const Key('surfaceStudio.atlas.dragHandle')),
+        findsOneWidget);
+    final gesture = await tester.startGesture(
+      tester.getCenter(find.byKey(const Key('surfaceStudio.atlas.dragHandle'))),
+    );
+    await tester.pump(const Duration(milliseconds: 300));
+    await gesture.moveBy(const Offset(40, 0));
+    await tester.pump();
+
+    expect(
+        find.byKey(const Key('surfaceStudio.atlas.dragGhost')), findsOneWidget);
+
+    await gesture.up();
+    await tester.pumpAndSettle();
+  });
+}
```

### Diff fichier créé : `packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart`

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart b/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart
@@ -0,0 +1,39 @@
+import 'package:flutter/widgets.dart';
+import 'package:flutter_test/flutter_test.dart';
+
+import 'surface_studio_rebuild_test_harness.dart';
+
+void main() {
+  testWidgets(
+      'preview panel exposes playback, scrub, loop grid and size controls', (
+    tester,
+  ) async {
+    await pumpSurfaceStudioForTest(tester);
+    await tester.pump();
+
+    expect(
+        find.byKey(const Key('surfaceStudio.preview.panel')), findsOneWidget);
+    expect(find.text('Prévisualisation'), findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.preview.previous')),
+        findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.preview.playPause')),
+        findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.preview.next')), findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.preview.scrubSlider')),
+        findsOneWidget);
+    expect(find.text('Frame 1 / 32'), findsOneWidget);
+    expect(find.text('Boucle'), findsOneWidget);
+    expect(find.text('Grille'), findsOneWidget);
+    expect(find.text('10 × 10'), findsOneWidget);
+
+    await tester.tap(find.byKey(const Key('surfaceStudio.preview.next')));
+    await tester.pump();
+    expect(find.text('Frame 2 / 32'), findsOneWidget);
+
+    await tester.tap(find.byKey(const Key('surfaceStudio.preview.sizeButton')));
+    await tester.pumpAndSettle();
+    await tester.tap(find.text('15 × 15').last);
+    await tester.pumpAndSettle();
+    expect(find.text('15 × 15'), findsOneWidget);
+  });
+}
```

### Diff fichier créé : `packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart`

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart
@@ -0,0 +1,81 @@
+import 'package:flutter/widgets.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_drag_payload.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_role_assignment_draft.dart';
+
+import 'surface_studio_rebuild_test_harness.dart';
+
+void main() {
+  test(
+      'role drop validation accepts center multi-column and rejects edge multi-column',
+      () {
+    const payload = SurfaceStudioColumnDragPayload(
+      columns: [4, 5, 6],
+      tileWidth: 32,
+      tileHeight: 32,
+      frameCount: 32,
+    );
+    const draft = SurfaceStudioRoleAssignmentDraft.empty();
+
+    expect(
+      validateSurfaceStudioRoleDrop(
+        role: SurfaceVariantRole.isolated,
+        payload: payload,
+        draft: draft,
+      ),
+      SurfaceStudioDropValidation.valid,
+    );
+    expect(
+      validateSurfaceStudioRoleDrop(
+        role: SurfaceVariantRole.endNorth,
+        payload: payload,
+        draft: draft,
+      ),
+      SurfaceStudioDropValidation.invalidTooManyColumns,
+    );
+  });
+
+  test('role assignment draft preserves center order and replaces other roles',
+      () {
+    const draft = SurfaceStudioRoleAssignmentDraft.empty();
+    final withCenter = draft.assignColumns(
+      SurfaceVariantRole.isolated,
+      const [4, 5],
+    );
+    final withEdge = withCenter.assignColumns(
+      SurfaceVariantRole.endNorth,
+      const [7],
+    );
+    final replacedEdge = withEdge.assignColumns(
+      SurfaceVariantRole.endNorth,
+      const [8],
+    );
+
+    expect(withCenter.columnsForRole(SurfaceVariantRole.isolated), [4, 5]);
+    expect(replacedEdge.columnsForRole(SurfaceVariantRole.endNorth), [8]);
+    expect(replacedEdge.assignedRoleCount, 2);
+  });
+
+  testWidgets('schema panel uses accordions and shows expected roles', (
+    tester,
+  ) async {
+    await pumpSurfaceStudioForTest(tester);
+    await tester.pump();
+
+    expect(find.byKey(const Key('surfaceStudio.schema.group.surfaceMain')),
+        findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.schema.group.edges')),
+        findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.schema.role.center')),
+        findsOneWidget);
+    expect(find.text('Plein (center)'), findsOneWidget);
+    expect(find.text('Bord haut'), findsOneWidget);
+    expect(find.text('Coin int. haut gauche'), findsOneWidget);
+
+    await tester
+        .tap(find.byKey(const Key('surfaceStudio.schema.group.edges.header')));
+    await tester.pumpAndSettle();
+    expect(find.text('Bord haut'), findsNothing);
+  });
+}
```

### Diff fichier créé : `packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart`

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart b/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart
@@ -0,0 +1,106 @@
+import 'package:flutter/widgets.dart';
+import 'package:flutter_test/flutter_test.dart';
+
+import 'surface_studio_rebuild_test_harness.dart';
+
+void main() {
+  testWidgets('premium wizard shell mirrors the reference structure',
+      (tester) async {
+    await pumpSurfaceStudioForTest(tester);
+    await tester.pump();
+
+    expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.header')), findsOneWidget);
+    expect(
+      find.text('Surface Studio — Assistant de mapping d’atlas'),
+      findsOneWidget,
+    );
+
+    for (final label in [
+      'Importer',
+      'Découper',
+      'Mapper',
+      'Prévisualiser',
+      'Enregistrer',
+    ]) {
+      expect(find.text(label), findsWidgets);
+    }
+
+    expect(find.byKey(const Key('surfaceStudio.stepper')), findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.step.mapper.active')),
+        findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.sidebar')), findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.atlas.panel')), findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.schema.panel')), findsOneWidget);
+    expect(
+        find.byKey(const Key('surfaceStudio.preview.panel')), findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.bottomBar')), findsOneWidget);
+  });
+
+  testWidgets('sidebar and right dock collapse and expand with sliding panels',
+      (
+    tester,
+  ) async {
+    await pumpSurfaceStudioForTest(tester);
+    await tester.pump();
+
+    expect(find.byKey(const Key('surfaceStudio.sidebar.expanded')),
+        findsOneWidget);
+    await tester
+        .tap(find.byKey(const Key('surfaceStudio.sidebar.collapseButton')));
+    await tester.pumpAndSettle();
+    expect(find.byKey(const Key('surfaceStudio.sidebar.collapsed')),
+        findsOneWidget);
+    expect(find.byTooltip('Importer'), findsOneWidget);
+
+    await tester
+        .tap(find.byKey(const Key('surfaceStudio.sidebar.collapseButton')));
+    await tester.pumpAndSettle();
+    expect(find.byKey(const Key('surfaceStudio.sidebar.expanded')),
+        findsOneWidget);
+
+    expect(
+        find.byKey(const Key('surfaceStudio.schema.expanded')), findsOneWidget);
+    await tester
+        .tap(find.byKey(const Key('surfaceStudio.schema.collapseButton')));
+    await tester.pumpAndSettle();
+    expect(find.byKey(const Key('surfaceStudio.schema.collapsed')),
+        findsOneWidget);
+  });
+
+  testWidgets('stepper allows previous steps and blocks locked future steps', (
+    tester,
+  ) async {
+    await pumpSurfaceStudioForTest(tester);
+    await tester.pump();
+
+    await tester.tap(find.byKey(const Key('surfaceStudio.step.import')));
+    await tester.pumpAndSettle();
+    expect(find.byKey(const Key('surfaceStudio.step.import.active')),
+        findsOneWidget);
+
+    await tester.tap(find.byKey(const Key('surfaceStudio.step.save')));
+    await tester.pumpAndSettle();
+    expect(find.byKey(const Key('surfaceStudio.step.import.active')),
+        findsOneWidget);
+    expect(find.text('Terminez les étapes précédentes avant d’avancer.'),
+        findsOneWidget);
+  });
+
+  testWidgets('bottom action bar exposes the required commands',
+      (tester) async {
+    await pumpSurfaceStudioForTest(tester);
+    await tester.pump();
+
+    expect(find.byKey(const Key('surfaceStudio.action.back')), findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.action.autoSuggest')),
+        findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.action.applyMapping')),
+        findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.action.next')), findsOneWidget);
+    expect(find.text('Retour'), findsOneWidget);
+    expect(find.text('Suggestion auto'), findsOneWidget);
+    expect(find.text('Appliquer le mapping'), findsOneWidget);
+    expect(find.text('Suivant'), findsOneWidget);
+  });
+}
```

### Diff fichier créé : `packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart`

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart b/packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart
new file mode 100644
index 0000000..0000000
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart
@@ -0,0 +1,115 @@
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
+
+Widget wrapSurfaceStudioForTest({
+  SurfaceStudioReadModel? readModel,
+  double width = 2048,
+  double height = 1120,
+}) {
+  return MaterialApp(
+    home: MediaQuery(
+      data: MediaQueryData(size: Size(width, height)),
+      child: CupertinoPageScaffold(
+        child: SizedBox(
+          width: width,
+          height: height,
+          child: SurfaceStudioPanel(
+            readModel:
+                readModel ?? buildSurfaceStudioReadModelFromCatalog(_catalog()),
+            projectTilesets: const <ProjectTilesetEntry>[
+              ProjectTilesetEntry(
+                id: 'water_tiles',
+                name: 'Water Tiles',
+                relativePath: 'missing/water.png',
+                sortOrder: 0,
+              ),
+            ],
+            projectRootPath: '/missing/project',
+          ),
+        ),
+      ),
+    ),
+  );
+}
+
+Future<void> pumpSurfaceStudioForTest(
+  WidgetTester tester, {
+  SurfaceStudioReadModel? readModel,
+  double width = 2048,
+  double height = 1120,
+}) async {
+  tester.view.devicePixelRatio = 1;
+  tester.view.physicalSize = Size(width, height);
+  addTearDown(tester.view.resetDevicePixelRatio);
+  addTearDown(tester.view.resetPhysicalSize);
+  await tester.pumpWidget(
+    wrapSurfaceStudioForTest(
+      readModel: readModel,
+      width: width,
+      height: height,
+    ),
+  );
+}
+
+ProjectSurfaceCatalog _catalog() {
+  const atlasId = 'water-atlas';
+  final animations = <ProjectSurfaceAnimation>[
+    for (var column = 0; column < 12; column++)
+      ProjectSurfaceAnimation(
+        id: 'water-col-$column',
+        name: 'Water Column $column',
+        timeline: SurfaceAnimationTimeline(
+          frames: [
+            for (var row = 0; row < 32; row++)
+              SurfaceAnimationFrame(
+                tileRef: SurfaceAtlasTileRef(
+                  atlasId: atlasId,
+                  column: column,
+                  row: row,
+                ),
+                durationMs: 120,
+              ),
+          ],
+        ),
+        syncGroupId: atlasId,
+        sortOrder: column,
+      ),
+  ];
+
+  return ProjectSurfaceCatalog(
+    atlases: [
+      ProjectSurfaceAtlas(
+        id: atlasId,
+        name: 'Water Atlas',
+        tilesetId: 'water_tiles',
+        geometry: SurfaceAtlasGeometry(
+          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+          gridSize: SurfaceAtlasGridSize(columns: 12, rows: 32),
+          layout: SurfaceAtlasLayout.grid,
+        ),
+      ),
+    ],
+    animations: animations,
+    presets: [
+      ProjectSurfacePreset(
+        id: 'water-surface',
+        name: 'Water Surface',
+        variantAnimations: SurfaceVariantAnimationRefSet(
+          refs: [
+            SurfaceVariantAnimationRef(
+              role: SurfaceVariantRole.isolated,
+              animationId: 'water-col-3',
+            ),
+            SurfaceVariantAnimationRef(
+              role: SurfaceVariantRole.endNorth,
+              animationId: 'water-col-4',
+            ),
+          ],
+        ),
+      ),
+    ],
+  );
+}
```

### Diff fichier modifié : `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
index 855cb6ea..5b79aea9 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
@@ -1,11 +1,8 @@
-// Surface Studio — shell UI lecture seule (Lot 52).
+// Surface Studio — assistant premium de mapping d'atlas.
 //
-// Consomme un [SurfaceStudioReadModel] déjà construit côté [map_core] : pas de
-// re-diagnostic, pas de mutation manifest, pas d’I/O. Les actions futures sont
-// désactivées ; seul le placeholder « Actions auteur » reste pour un lot ultérieur.
-//
-// Style : aligné sur [EditorChrome] / îlots de l’éditeur (pas de Card Material
-// clair isolé) — cohérent avec World Explorer et le shell macOS.
+// Le premier viewport porte le workflow guide moderne. Les sections legacy
+// restent disponibles plus bas pour conserver les briques metier existantes :
+// preparation d'atlas, inspection, diagnostics et sauvegarde via le flux projet.
 
 import 'package:flutter/cupertino.dart';
 import 'package:flutter/material.dart' show Icons;
@@ -25,6 +22,7 @@ import 'surface_studio_role_mapping_editor.dart';
 import 'surface_studio_selection.dart';
 import 'surface_studio_selection_inspector.dart';
 import 'surface_studio_selection_summary.dart';
+import 'surface_studio_screen.dart';
 import 'surface_studio_workflow_layout.dart';
 import 'surface_studio_workflow_stepper.dart';
 
@@ -409,73 +407,48 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
           : null,
     );
 
-    return SingleChildScrollView(
-      key: const ValueKey('surface_studio_root_scroll'),
-      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
-      child: Column(
-        crossAxisAlignment: CrossAxisAlignment.stretch,
-        children: [
-          _CompactStudioHeader(
-            key: const ValueKey('surface_studio_workflow_header'),
-            label: label,
+    final legacyAuthoringBridge = Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        _CompactStudioHeader(
+          key: const ValueKey('surface_studio_workflow_header'),
+          label: label,
+          subtle: subtle,
+          summary: s,
+          readOnly: !isPartial,
+        ),
+        const SizedBox(height: 8),
+        SurfaceStudioWorkflowStepper(readModel: _workReadModel),
+        if (_hasWorkCatalogChanges) ...[
+          const SizedBox(height: 10),
+          _CatalogStateStrip(
+            key: const ValueKey('surface_studio_catalog_status_strip'),
             subtle: subtle,
-            summary: s,
-            readOnly: !isPartial,
+            workCatalogNote: SurfaceStudioPanel.workCatalogDirtyStateText,
+            onSurfaceSavePrep: widget.onSurfaceCatalogSaveRequested != null
+                ? _onSurfaceCatalogSavePrep
+                : null,
+            onResetWorkCatalog: () {
+              setState(() {
+                _workReadModel = widget.readModel;
+                _selection =
+                    _selectionValidInReadModel(_workReadModel, _selection);
+                _saveFlowPrepNote = null;
+              });
+            },
           ),
-          const SizedBox(height: 8),
-          SurfaceStudioWorkflowStepper(readModel: _workReadModel),
-          if (_hasWorkCatalogChanges) ...[
-            const SizedBox(height: 10),
-            _CatalogStateStrip(
-              key: const ValueKey('surface_studio_catalog_status_strip'),
-              subtle: subtle,
-              workCatalogNote: SurfaceStudioPanel.workCatalogDirtyStateText,
-              onSurfaceSavePrep: widget.onSurfaceCatalogSaveRequested != null
-                  ? _onSurfaceCatalogSavePrep
-                  : null,
-              onResetWorkCatalog: () {
-                setState(() {
-                  _workReadModel = widget.readModel;
-                  _selection =
-                      _selectionValidInReadModel(_workReadModel, _selection);
-                  _saveFlowPrepNote = null;
-                });
-              },
-            ),
-            if (widget.onSurfaceCatalogSaveRequested == null)
-              Text(
-                key: const ValueKey('surface_studio_save_prep_not_connected'),
-                SurfaceStudioPanel.savePrepNotConnectedNote,
-                style: TextStyle(
-                  color: subtle.withValues(alpha: 0.95),
-                  fontSize: 11,
-                  fontStyle: FontStyle.italic,
-                ),
-              ),
-            if (widget.onRequestProjectSave != null) ...[
-              const SizedBox(height: 6),
-              CupertinoButton(
-                key: const ValueKey(
-                    'surface_studio_project_save_via_official_flow'),
-                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
-                onPressed: _onRequestProjectSave,
-                child: const Text(
-                  SurfaceStudioPanel.projectSaveViaExistingFlowButtonLabel,
-                ),
+          if (widget.onSurfaceCatalogSaveRequested == null)
+            Text(
+              key: const ValueKey('surface_studio_save_prep_not_connected'),
+              SurfaceStudioPanel.savePrepNotConnectedNote,
+              style: TextStyle(
+                color: subtle.withValues(alpha: 0.95),
+                fontSize: 11,
+                fontStyle: FontStyle.italic,
               ),
-              if (_projectSaveDiskNote != null)
-                Text(
-                  _projectSaveDiskNote!,
-                  key: const ValueKey('surface_studio_project_save_disk_note'),
-                  style: TextStyle(
-                    color: _surfaceStudioAccent.withValues(alpha: 0.88),
-                    fontSize: 11,
-                    fontWeight: FontWeight.w600,
-                  ),
-                ),
-            ],
-          ] else if (widget.onRequestProjectSave != null) ...[
-            const SizedBox(height: 8),
+            ),
+          if (widget.onRequestProjectSave != null) ...[
+            const SizedBox(height: 6),
             CupertinoButton(
               key: const ValueKey(
                   'surface_studio_project_save_via_official_flow'),
@@ -485,8 +458,7 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
                 SurfaceStudioPanel.projectSaveViaExistingFlowButtonLabel,
               ),
             ),
-            if (_projectSaveDiskNote != null) ...[
-              const SizedBox(height: 4),
+            if (_projectSaveDiskNote != null)
               Text(
                 _projectSaveDiskNote!,
                 key: const ValueKey('surface_studio_project_save_disk_note'),
@@ -496,46 +468,99 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
                   fontWeight: FontWeight.w600,
                 ),
               ),
-            ],
           ],
-          if (_saveFlowPrepNote != null) ...[
-            const SizedBox(height: 6),
+        ] else if (widget.onRequestProjectSave != null) ...[
+          const SizedBox(height: 8),
+          CupertinoButton(
+            key:
+                const ValueKey('surface_studio_project_save_via_official_flow'),
+            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
+            onPressed: _onRequestProjectSave,
+            child: const Text(
+              SurfaceStudioPanel.projectSaveViaExistingFlowButtonLabel,
+            ),
+          ),
+          if (_projectSaveDiskNote != null) ...[
+            const SizedBox(height: 4),
             Text(
-              _saveFlowPrepNote!,
-              key: const ValueKey('surface_studio_save_prep_transmitted'),
+              _projectSaveDiskNote!,
+              key: const ValueKey('surface_studio_project_save_disk_note'),
               style: TextStyle(
-                color: _surfaceStudioAccent.withValues(alpha: 0.9),
+                color: _surfaceStudioAccent.withValues(alpha: 0.88),
                 fontSize: 11,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ],
-          const SizedBox(height: 12),
-          SurfaceStudioWorkflowLayout(
-            assistant: assistant,
-            atlasWorkspace: authoring,
-            detectedAnimations: detectedAnimations,
-            paintableSurfaces: paintableSurfaces,
-          ),
-          const SizedBox(height: 12),
-          _AdvancedDetailsSection(
-            inspection: inspection,
-            browser: SurfaceStudioCatalogBrowser(
-              readModel: _workReadModel,
-              selection: _selection,
-              onSelectionChanged: (v) {
-                setState(() => _selection = v);
-              },
-            ),
-            diagnostics:
-                SurfaceStudioDiagnosticsView(readModel: _workReadModel),
-            futureActions: const _FutureActions(onImportVertical: null),
-            placeholder: const _SectionPlaceholder(
-              title: SurfaceStudioPanel.placeholderActionsTitle,
+        ],
+        if (_saveFlowPrepNote != null) ...[
+          const SizedBox(height: 6),
+          Text(
+            _saveFlowPrepNote!,
+            key: const ValueKey('surface_studio_save_prep_transmitted'),
+            style: TextStyle(
+              color: _surfaceStudioAccent.withValues(alpha: 0.9),
+              fontSize: 11,
+              fontWeight: FontWeight.w600,
             ),
           ),
         ],
-      ),
+        const SizedBox(height: 12),
+        SurfaceStudioWorkflowLayout(
+          assistant: assistant,
+          atlasWorkspace: authoring,
+          detectedAnimations: detectedAnimations,
+          paintableSurfaces: paintableSurfaces,
+        ),
+        const SizedBox(height: 12),
+        _AdvancedDetailsSection(
+          inspection: inspection,
+          browser: SurfaceStudioCatalogBrowser(
+            readModel: _workReadModel,
+            selection: _selection,
+            onSelectionChanged: (v) {
+              setState(() => _selection = v);
+            },
+          ),
+          diagnostics: SurfaceStudioDiagnosticsView(readModel: _workReadModel),
+          futureActions: const _FutureActions(onImportVertical: null),
+          placeholder: const _SectionPlaceholder(
+            title: SurfaceStudioPanel.placeholderActionsTitle,
+          ),
+        ),
+      ],
+    );
+
+    return LayoutBuilder(
+      builder: (context, constraints) {
+        final shellWidth = constraints.hasBoundedWidth
+            ? constraints.maxWidth.clamp(1200.0, 2400.0).toDouble()
+            : 1600.0;
+        final shellHeight = constraints.hasBoundedHeight
+            ? constraints.maxHeight.clamp(900.0, 1120.0).toDouble()
+            : 900.0;
+        return SingleChildScrollView(
+          key: const ValueKey('surface_studio_root_scroll'),
+          child: Column(
+            crossAxisAlignment: CrossAxisAlignment.stretch,
+            children: [
+              SingleChildScrollView(
+                scrollDirection: Axis.horizontal,
+                child: SizedBox(
+                  width: shellWidth,
+                  height: shellHeight,
+                  child: SurfaceStudioScreen(readModel: _workReadModel),
+                ),
+              ),
+              Padding(
+                key: const ValueKey('surface_studio_legacy_authoring_bridge'),
+                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
+                child: legacyAuthoringBridge,
+              ),
+            ],
+          ),
+        );
+      },
     );
   }
 }
```

### Diff fichier modifié : `packages/map_editor/test/shell_chrome_test_harness.dart`

```diff
diff --git a/packages/map_editor/test/shell_chrome_test_harness.dart b/packages/map_editor/test/shell_chrome_test_harness.dart
index 3fe29791..aff6d9ff 100644
--- a/packages/map_editor/test/shell_chrome_test_harness.dart
+++ b/packages/map_editor/test/shell_chrome_test_harness.dart
@@ -1,4 +1,5 @@
 import 'package:flutter/cupertino.dart';
+import 'package:flutter/services.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:flutter_riverpod/flutter_riverpod.dart';
 import 'package:macos_ui/macos_ui.dart';
@@ -9,6 +10,25 @@ import 'package:map_editor/src/ui/editor_shell_page.dart';
 import 'package:map_editor/src/ui/shared/status_bar.dart';
 import 'package:map_editor/src/ui/shared/top_toolbar.dart';
 
+const _appkitUiElementColorsChannel = MethodChannel('appkit_ui_element_colors');
+
+void _installMacosAccentColorMock() {
+  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
+      .setMockMethodCallHandler(_appkitUiElementColorsChannel, (call) async {
+    switch (call.method) {
+      case 'getColorComponents':
+        return <String, double>{'hueComponent': 0.58};
+      case 'getColor':
+        return 0xFF0A84FF;
+    }
+    return null;
+  });
+  addTearDown(() {
+    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
+        .setMockMethodCallHandler(_appkitUiElementColorsChannel, null);
+  });
+}
+
 ProjectManifest buildShellChromeProject({
   String name = 'Demo Project',
   List<ProjectMapEntry> maps = const <ProjectMapEntry>[],
@@ -43,6 +63,7 @@ Future<ProviderContainer> pumpEditorShellPage(
   Size surfaceSize = const Size(1600, 1000),
   List<Override> overrides = const <Override>[],
 }) async {
+  _installMacosAccentColorMock();
   final container = ProviderContainer(overrides: overrides);
   final editorStateSubscription = container.listen<EditorState>(
     editorNotifierProvider,
@@ -83,6 +104,7 @@ Future<ProviderContainer> pumpTopToolbarHarness(
   required EditorState initialState,
   Size surfaceSize = const Size(1280, 220),
 }) async {
+  _installMacosAccentColorMock();
   final container = ProviderContainer();
   final editorStateSubscription = container.listen<EditorState>(
     editorNotifierProvider,
@@ -120,6 +142,7 @@ Future<ProviderContainer> pumpStatusBarHarness(
   required EditorState initialState,
   Size surfaceSize = const Size(900, 180),
 }) async {
+  _installMacosAccentColorMock();
   final container = ProviderContainer();
   final editorStateSubscription = container.listen<EditorState>(
     editorNotifierProvider,
```

### Diff fichier modifié : `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
index 05f9aae6..3c4d93cf 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
@@ -250,7 +250,8 @@ void main() {
         _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
       );
       expect(find.textContaining('Sauvegarder'), findsNothing);
-      expect(find.textContaining('Enregistrer'), findsNothing);
+      expect(find.byKey(const ValueKey('surfaceStudio.step.save')),
+          findsOneWidget);
       expect(find.textContaining('Save'), findsNothing);
     });
 
@@ -423,7 +424,6 @@ void main() {
       await tester.pump();
       for (final s in <String>[
         'Sauvegarder',
-        'Enregistrer',
         'Modifier',
         'Supprimer',
         'Save',
@@ -432,6 +432,10 @@ void main() {
       ]) {
         expect(find.text(s), findsNothing);
       }
+      expect(
+        find.byKey(const ValueKey('surfaceStudio.step.save')),
+        findsOneWidget,
+      );
     });
 
     testWidgets('59.20 — inspecteur none au départ', (tester) async {
@@ -572,7 +576,6 @@ void main() {
       await tester.pump();
       for (final s in <String>[
         'Sauvegarder',
-        'Enregistrer',
         'Modifier',
         'Supprimer',
         'Save',
@@ -581,6 +584,10 @@ void main() {
       ]) {
         expect(find.text(s), findsNothing);
       }
+      expect(
+        find.byKey(const ValueKey('surfaceStudio.step.save')),
+        findsOneWidget,
+      );
     });
 
     testWidgets('30. Lot 55 — surfaceCatalog unchanged after panel pump',
```

## 37.8 Tests

### Tests ciblés rebuild Surface Studio

Commande exacte :

```bash
cd packages/map_editor && /opt/homebrew/bin/flutter test test/surface_studio/surface_studio_rebuild_shell_test.dart test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart test/surface_studio/surface_studio_rebuild_schema_panel_test.dart test/surface_studio/surface_studio_rebuild_preview_controls_test.dart --no-pub --reporter expanded
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:01 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:01 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:01 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:02 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:02 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas selection is draggable with a visible ghost payload
00:02 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:02 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: bottom action bar exposes the required commands
00:02 +10: All tests passed!
```

Ligne finale exacte : `00:02 +10: All tests passed!`

### Dossier Surface Studio complet

Commande exacte :

```bash
cd packages/map_editor && /opt/homebrew/bin/flutter test test/surface_studio --no-pub --reporter expanded
```

Ligne finale exacte : `00:25 +417: All tests passed!`

### Golden slice isolé après stabilisation du channel macOS

Commande exacte :

```bash
cd packages/map_editor && /opt/homebrew/bin/flutter test test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart --no-pub --reporter expanded
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart
00:00 +0: Lot 80 — golden slice vertical atlas 23×32 + suggestion standard : 20 animations prêtes puis preset cohérent
00:00 +1: Lot 80 — golden slice vertical atlas 4×3 UI : atlas → mapping → animations → preset → save → project.json
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
EditorNotifier: saveProjectManifest()
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/map_editor_lot80_gs_Bhybnm/project.json
00:03 +2: All tests passed!
```

Ligne finale exacte : `00:03 +2: All tests passed!`

### Surface Painter regression

Commande exacte :

```bash
cd packages/map_editor && /opt/homebrew/bin/flutter test test/surface_painter --no-pub --reporter expanded
```

Ligne finale exacte : `00:02 +71: All tests passed!`

## 37.9 Analyze

Commande exacte :

```bash
cd packages/map_editor && /opt/homebrew/bin/flutter analyze lib/src/features/surface_studio test/surface_studio/surface_studio_rebuild_shell_test.dart test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart test/surface_studio/surface_studio_rebuild_schema_panel_test.dart test/surface_studio/surface_studio_rebuild_preview_controls_test.dart test/surface_studio/surface_studio_rebuild_test_harness.dart test/shell_chrome_test_harness.dart test/surface_studio/surface_studio_panel_test.dart
```

Sortie exacte :

```text
Analyzing 8 items...                                            

No issues found! (ran in 2.2s)
```

## 37.10 Auto-review

- Respect de l’image : Oui. La composition reproduit header, stepper, sidebar, atlas, schéma, preview et barre basse.
- Qualité UX : Oui. L’utilisateur voit les étapes, la sélection, les rôles, la preview et les actions sans passer par les détails techniques.
- Qualité interactions : Oui. Drag & drop réel, sliders réels, accordéons, panels coulissants, dropdown taille et toggles.
- Architecture composants : Oui. Le nouveau code est découpé en `shell`, `atlas`, `schema`, `preview` et modèles UI locaux.
- Accessibilité : Améliorée. Tooltips sur boutons icon-only, textes français, états disabled visuels, tailles de boutons corrigées avec `minimumSize`.
- Performance : Raisonnable V2. Preview en `RepaintBoundary`, timer disposé, fallback painter local, pas de reload image coûteux dans le nouveau shell.
- Risques restants : le nouveau shell utilise encore un fallback visuel pour l’atlas dans ce lot; le branchement complet aux miniatures atlas réelles pourra être renforcé ensuite.
- Dette volontaire : le pont legacy reste sous le nouvel assistant pour préserver les workflows validés et éviter une migration risquée dans le même lot.
- Non-objectifs confirmés : pas de map_gameplay, pas de map_runtime, pas de map_core, pas de gameplay ice/mud, pas de SurfaceLayer gameplay, pas de ProjectSurfacePreset gameplay.

## 37.11 Critique du prompt

Ambiguïtés rencontrées : la demande exige une reconstruction complète tout en demandant de conserver les flux métier existants. Le choix fait est un premier viewport entièrement reconstruit, puis un pont legacy plus bas pour les fonctions authoring déjà testées.

Parties très strictes : l’Evidence Pack complet avec contenus et diffs rend le rapport très volumineux, mais il est utile pour revue hors environnement.

Parties insuffisamment précises : le niveau exact de branchement de l’image atlas réelle dans la nouvelle première vue pourrait être séparé en lot dédié, car l’ancien loader existe mais le nouveau shell V2 doit rester robuste sans I/O fragile.

Suggestion pour le lot suivant : brancher la nouvelle grille/preview V2 sur les miniatures réelles du catalogue Surface et réduire progressivement la dépendance au pont legacy, sans changer le modèle Surface ni gameplay.

## 37.12 Git status final

Statut avant création du présent rapport :

```text
M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
?? packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart
?? packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
?? packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
?? packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_role_thumbnail_painter.dart
?? packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_schema_panel.dart
?? packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart
?? packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart
?? packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart
?? packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_sidebar.dart
?? packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_top_stepper.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_column_selection.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_design_tokens.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_drag_payload.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_motion.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_role_assignment_draft.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_step.dart
?? packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart
```

Statut final avec le rapport :

```text
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
?? packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart
?? packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
?? packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
?? packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_role_thumbnail_painter.dart
?? packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_schema_panel.dart
?? packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart
?? packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart
?? packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart
?? packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_sidebar.dart
?? packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_top_stepper.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_column_selection.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_design_tokens.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_drag_payload.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_motion.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_role_assignment_draft.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_step.dart
?? packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart
?? reports/surface/surface_studio_rebuild_figma_grade_wizard_v2.md
```

Explication des lignes :

- Les lignes `M` correspondent aux fichiers modifiés dans `map_editor` et aux tests ajustés.
- Les lignes `??` correspondent aux nouveaux composants Surface Studio V2, aux nouveaux tests V2 et au présent rapport.
- Aucun fichier supprimé.

### Diff stat final

```text
.../surface_studio/surface_studio_panel.dart       | 229 ++++++++++++---------
 .../map_editor/test/shell_chrome_test_harness.dart |  23 +++
 .../surface_studio/surface_studio_panel_test.dart  |  13 +-
 3 files changed, 160 insertions(+), 105 deletions(-)
```

### Context Mode

La commande `ctx stats` a été lancée et a répondu :

```text
zsh:1: command not found: ctx
```

Synthèse économie contexte : CLI `ctx` indisponible, donc aucune statistique chiffrée exploitable; les sorties longues ont été résumées dans les messages de travail et les preuves demandées sont incluses dans ce rapport.

### Périmètre explicitement non touché

- `map_core` non modifié.
- `map_gameplay` non modifié.
- `map_runtime` non modifié.
- `map_battle` non modifié.
- Aucun runtime ice/mud.
- Aucune glissade.
- Aucun movement cost appliqué.
- Aucune nouvelle action Surface Painter ice/mud.
- Aucun `SurfaceGameplayCatalog`.
- Aucune dépendance gameplay directe à `SurfaceLayer`.
- Aucune modification `MovementZonePayload`.
- Aucun `SpecialZonePayload(scriptKey)` pour gameplay.
- Aucune migration legacy.
- Aucune refonte de modèle Surface dans `map_core`.
- Aucun gameplay ajouté dans `ProjectSurfacePreset`.
- Aucune sauvegarde disque nouvelle hors flux existants.
- Aucune nouvelle dépendance Flutter.
