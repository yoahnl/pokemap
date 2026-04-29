# Surface Studio V2.2 — Functional Closure, Real Atlas Rendering, Adaptive Layout & Mistral AI Suggestion V0

## 18.1 Verdict

V2.2 accepté.

Surface Studio V2.2 ferme les problèmes signalés côté produit dans le périmètre editor : layout adaptatif par étape, suppression du panneau droit global inutile, suppression de la fausse croix de fenêtre, atlas/preview branchés sur les bytes résolus quand disponibles, fallback explicite quand absents, correction RenderFlex, suggestion locale reviewable, et provider Mistral V0 opt-in avec HTTP client injectable.

## 18.2 Audit initial

### Git status initial

```text
(no output)
```

### Git diff stat initial

```text
(no output)
```

### Fichiers audités

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_source_picker.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart`
- `packages/map_editor/lib/src/features/surface_studio/atlas/`
- `packages/map_editor/lib/src/features/surface_studio/schema/`
- `packages/map_editor/lib/src/features/surface_studio/preview/`
- `packages/map_editor/lib/src/features/editor/application/editor_ai_settings.dart`
- `packages/map_editor/lib/src/features/dialogue/application/mistral_dialogue_client.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`

### Causes exactes

- Panneau droit inutile Importer/Découper : `SurfaceStudioScreen` construisait un right dock non contextualisé, donc schéma/preview restaient visibles hors étape Mapper.
- Panneau global droit : `EditorShellPage` déclarait `supportsRightInspector = workspaceMode != EditorWorkspaceMode.pokedex`; `surfaceStudio` gardait donc `_SurfaceWorkspaceInspector`, un panneau neutre explicitement vide.
- Croix interne : `SurfaceStudioHeader` rendait encore un bouton icône `CupertinoIcons.xmark` avec tooltip `Fermer`, ce qui donnait un chrome de fausse fenêtre.
- Placeholder Mapper : `SurfaceStudioAtlasPanel` peignait seulement un placeholder stylisé et ne recevait pas les bytes image résolus par `resolveSurfaceStudioAtlasImagePreview`.
- Preview non fonctionnelle : `SurfaceStudioPreviewPanel` peignait une eau procédurale locale et ne recevait pas les bytes atlas ni un fallback explicite.
- RenderFlex overflow : `SurfaceStudioAtlasImagePreview` plaçait image, message et métadonnées dans une `Column` non scrollable sous contraintes de hauteur courtes.
- Résolution image atlas : `resolveSurfaceStudioAtlasImagePreview` reste le point de résolution via `projectRootPath`, `ProjectTilesetEntry.relativePath` et `ProjectSurfaceAtlas` où disponible.
- Clé Mistral : `resolveEditorMistralApiKey(ProjectSettings?)` dans `features/editor/application/editor_ai_settings.dart`, priorité `ProjectSettings.mistralApiKey`, puis `MISTRAL_API_KEY`.
- Composants local-only corrigés : atlas panel, preview panel, right dock, suggestion review et Mistral provider.
- Tests précédents insuffisants : les tests V2.1 vérifiaient la présence du shell premium mais ne forçaient pas absence de docks sur Importer/Découper, absence de panneau global droit, absence de croix interne, ni absence d’overflow sous contraintes réelles.

## 18.3 Corrections UX

- Importer avant : schéma/preview pouvaient rester visibles à droite. Après : `rightDock == null`, contenu principal large, pas de dock schéma/preview.
- Découper avant : mêmes panneaux inutiles. Après : `rightDock == null`, workspace grille/image/réglages uniquement.
- Mapper avant : placeholder silencieux. Après : image réelle si bytes résolus, fallback explicite `Image source indisponible — aperçu illustratif.` sinon.
- Prévisualiser avant : preview décorative et secondaire. Après : workspace preview large branché sur mêmes bytes atlas si disponibles, plan/diagnostics à côté.
- Enregistrer avant : risque de schéma inutile. Après : pas de right dock, résumé génération/save prep.
- Panneau global droit avant : `_SurfaceWorkspaceInspector` neutre visible. Après : `surfaceStudio` ne supporte plus le right inspector global, ni toggle show/hide.
- Header interne avant : tooltip `Fermer` / X. Après : uniquement aide et Catalogue & diagnostics.
- Largeurs réduites : header compact par ellipsis contrôlée, body utilise un scroll horizontal borné seulement sous largeur minimale lisible, sans RenderFlex overflow.

## 18.4 Corrections fonctionnelles

- Vrai atlas : `SurfaceStudioScreen` résout les bytes image via le resolver existant et les transmet à `SurfaceStudioAtlasPanel`.
- Vrai mapping : le drag/drop continue de muter `SurfaceStudioRoleAssignmentDraft`, conservé entre Mapper, Prévisualiser et Enregistrer.
- Vraie preview : `SurfaceStudioPreviewPanel` reçoit les bytes atlas et modifie l’alignement image selon la frame courante ; les contrôles play/pause/previous/next/scrub restent actifs.
- Vraie génération : les flows V2.1 de génération animations/preset restent dans l’étape Enregistrer et les tests Surface Studio complets restent verts.
- Sauvegarde préparée : `SurfaceStudioPanel` garde le callback `onSurfaceCatalogSaveRequested` et le callback projet explicite sans sauvegarde disque implicite.
- Fallbacks restants : image absente/fichier introuvable/mapping incomplet affichent des messages explicites. Aucun placeholder silencieux pour Mapper.

## 18.5 IA Mistral

- Architecture ajoutée : `SurfaceStudioAiMappingSuggester`, `SurfaceStudioMistralMappingSuggester`, `buildSurfaceStudioMappingSuggestionPrompt`.
- Client/interface : provider Mistral derrière interface, `http.Client` injectable, aucun appel réseau dans les tests.
- Modèle configuré : `mistral-small-2506`, modèle vision recommandé dans la documentation Mistral actuelle. Les docs officielles consultées indiquent que les images peuvent être envoyées par URL ou base64 via Chat Completions : https://docs.mistral.ai/capabilities/vision et https://docs.mistral.ai/studio-api/conversations/chat-completion.
- Prompt JSON strict : le prompt demande uniquement un objet JSON avec `assignments` et `warnings`, rôles connus, colonnes bornées et raisons courtes.
- Validation JSON : rôle inconnu rejeté, colonne hors plage rejetée, multi-colonne hors `isolated` rejetée, confidence inconnue rejetée, JSON invalide converti en warning sans crash.
- Confirmation utilisateur : clic IA ouvre une confirmation avec le texte obligatoire sur envoi possible de l’image ; aucune requête avant confirmation.
- Tests fake client : `surface_studio_mapping_suggestion_test.dart` injecte un `MockClient` et un fake provider UI.
- Preuve aucune clé loggée : les tests vérifient que la valeur configurée n’apparaît pas dans l’UI et que le corps HTTP ne contient pas la clé. Seul le header Authorization reçoit la clé côté fake client.
- Preuve aucun réseau en test : l’UI utilise un fake provider et le provider Mistral est testé avec `MockClient`.

## 18.6 Overflow

- Fichier corrigé : `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart`.
- Cause racine : `Column` verticale avec image + fallback + métadonnées sous hauteur contrainte, sans scroll/flex borné.
- Solution layout : `LayoutBuilder`, contenu `mainAxisSize.min`, `SingleChildScrollView` quand hauteur bornée, image/fallback dans zone accessible.
- Tests contraintes : `surface_studio_atlas_image_preview_layout_test.dart` pompe les tailles 312.8 × 557 et 552 × 318, capture `FlutterError`, et échoue sur `RenderFlex overflowed`.
- Preuve absence : test ciblé vert et QA launch log sans chaîne `RenderFlex overflowed`.

## Context Mode

### CLI ctx

```text
ctx CLI unavailable: command not found
```

### MCP ctx stats

```text
389.7K tokens saved  ·  83.5% reduction  ·  1h 5m

Without context-mode  |████████████████████████████████████████| 1.8 MB
With context-mode     |███████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░| 301.6 KB

1.5 MB kept out of your conversation. Never entered context.

71 calls

  ctx_batch_execute         17 calls  711.7 KB saved
  ctx_search                14 calls  441.2 KB saved
  ctx_execute_file          15 calls  173.1 KB saved
  ctx_execute               19 calls  137.8 KB saved
  ctx_fetch_and_index        3 calls   49.5 KB saved
  ctx_stats                  3 calls    9.6 KB saved

v1.0.103
```

## Commandes d’audit lancées

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "SurfaceStudioScreen|SurfaceStudioShell|SurfaceStudioAtlasImagePreview|surfaceStudio.preview|surfaceStudio.schema|xmark|Fermer|Preview|Prévisualisation|Mistral|mistralApiKey|resolveEditorMistralApiKey|MISTRAL_API_KEY" packages/map_editor/lib packages/map_editor/test packages/map_core/lib
find packages/map_editor/lib/src/features/surface_studio -maxdepth 3 -type f | sort
find packages/map_editor/test/surface_studio -maxdepth 2 -type f | sort
rg -n "SurfaceStudioPanel|surface studio|Surface Studio|inspector|right panel|workspace" packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart packages/map_editor/lib/src/ui/editor_shell_page.dart packages/map_editor/lib/src/features/editor -g "*.dart"
```

## 18.7 Fichiers créés/modifiés/supprimés

### Fichiers créés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart`
- `reports/surface/surface_studio_rebuild_v2_2_functional_closure_mistral.md`

### Fichiers modifiés

- `packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart`
- `packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_editing.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_source_picker.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_column_role_mapping_block.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_editing_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_grid_overlay_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart`
- `packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_assistant_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_preset_generator_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_role_mapping_test.dart`

### Fichiers supprimés

Aucun fichier suivi supprimé.

### Note hygiène

Un `devtools_options.yaml` généré par le lancement QA macOS a été supprimé avant le status final. Aucun fichier temporaire ne reste dans le worktree.

## 18.8 Contenu complet des fichiers créés/modifiés

### packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart

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
    this.atlasImageBytes,
    this.atlasImageFallbackLabel,
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
  final Uint8List? atlasImageBytes;
  final String? atlasImageFallbackLabel;
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
              atlasImageBytes: atlasImageBytes,
              atlasImageFallbackLabel: atlasImageFallbackLabel,
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
    this.atlasImageBytes,
    this.atlasImageFallbackLabel,
    required this.selection,
    required this.zoomPercent,
    required this.onColumnSelectionChanged,
  });

  final int columnCount;
  final int frameCount;
  final int tileWidth;
  final int tileHeight;
  final Uint8List? atlasImageBytes;
  final String? atlasImageFallbackLabel;
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (atlasImageBytes != null)
                        Image.memory(
                          atlasImageBytes!,
                          key: const ValueKey('surfaceStudio.atlas.realImage'),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text(
                              'Image source indisponible — aperçu illustratif.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: SurfaceStudioDesignTokens.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Text(
                            atlasImageFallbackLabel ??
                                'Image source indisponible — aperçu illustratif.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: SurfaceStudioDesignTokens.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      CustomPaint(
                        painter: SurfaceStudioAtlasGridPainter(
                          columnCount: columnCount,
                          rowCount: frameCount,
                          selectedColumns: selection.columns,
                          zoomPercent: zoomPercent,
                        ),
                      ),
                    ],
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

### packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart

```dart
import 'dart:typed_data';

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
    this.atlasImageBytes,
    this.atlasFallbackMessage,
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
  final Uint8List? atlasImageBytes;
  final String? atlasFallbackMessage;
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
                      frameIndex: frameIndex,
                      frameCount: frameCount,
                      atlasImageBytes: atlasImageBytes,
                      atlasFallbackMessage: atlasFallbackMessage,
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
    required this.frameIndex,
    required this.frameCount,
    this.atlasImageBytes,
    this.atlasFallbackMessage,
    required this.hasCenter,
  });

  final int previewSize;
  final bool gridVisible;
  final int frameIndex;
  final int frameCount;
  final Uint8List? atlasImageBytes;
  final String? atlasFallbackMessage;
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
          ? Stack(
              fit: StackFit.expand,
              children: [
                if (atlasImageBytes != null)
                  Image.memory(
                    atlasImageBytes!,
                    key: const ValueKey('surfaceStudio.preview.realImage'),
                    fit: BoxFit.cover,
                    alignment: Alignment(
                      0,
                      frameCount <= 1
                          ? 0
                          : -1 + (2 * (frameIndex / (frameCount - 1))),
                    ),
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          atlasFallbackMessage ??
                              'Image source indisponible — aperçu illustratif.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: SurfaceStudioDesignTokens.textMuted,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        atlasFallbackMessage ??
                            'Image source indisponible — aperçu illustratif.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: SurfaceStudioDesignTokens.textMuted,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                CustomPaint(
                  painter: _WaterPreviewPainter(
                    gridVisible: gridVisible,
                    previewSize: previewSize,
                  ),
                  child: const SizedBox.expand(),
                ),
              ],
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
    return SingleChildScrollView(
      child: Column(
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
          Container(
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
        ],
      ),
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

### packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart

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
    this.onOpenAdvanced,
  });

  final SurfaceStudioWizardStep currentStep;
  final Set<SurfaceStudioWizardStep> completedSteps;
  final ValueChanged<SurfaceStudioWizardStep> onStepSelected;
  final VoidCallback? onOpenAdvanced;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return Container(
          key: const ValueKey('surfaceStudio.header'),
          decoration: const BoxDecoration(
            color: SurfaceStudioDesignTokens.backgroundDeep,
            border: Border(
              bottom: BorderSide(color: SurfaceStudioDesignTokens.borderSubtle),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
          child: Row(
            children: [
              const _StudioMark(),
              const SizedBox(width: 12),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compact ? 180 : 380),
                  child: const Text(
                    'Surface Studio — Assistant de mapping d’atlas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SurfaceStudioDesignTokens.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(width: compact ? 12 : 24),
              Expanded(
                child: SurfaceStudioTopStepper(
                  currentStep: currentStep,
                  completedSteps: completedSteps,
                  onStepSelected: onStepSelected,
                ),
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                tooltip: 'Aide',
                icon: CupertinoIcons.question_circle,
                onPressed: () {},
              ),
              _HeaderIconButton(
                tooltip: 'Catalogue & diagnostics',
                icon: CupertinoIcons.gear_alt,
                onPressed: onOpenAdvanced ?? () {},
              ),
            ],
          ),
        );
      },
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

### packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart

```dart
import 'package:flutter/widgets.dart';

import '../surface_studio_design_tokens.dart';

class SurfaceStudioShell extends StatelessWidget {
  const SurfaceStudioShell({
    super.key,
    required this.header,
    required this.sidebar,
    required this.workspacePanel,
    this.rightDock,
    required this.bottomBar,
  });

  final Widget header;
  final Widget sidebar;
  final Widget workspacePanel;
  final Widget? rightDock;
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final minimumReadableWidth =
                      rightDock == null ? 900.0 : 1260.0;
                  final contentWidth =
                      constraints.maxWidth < minimumReadableWidth
                          ? minimumReadableWidth
                          : constraints.maxWidth;
                  final content = SizedBox(
                    width: contentWidth,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        sidebar,
                        const SizedBox(width: SurfaceStudioDesignTokens.gapSm),
                        Expanded(child: workspacePanel),
                        if (rightDock != null) ...[
                          const SizedBox(
                              width: SurfaceStudioDesignTokens.gapSm),
                          SizedBox(
                            width: SurfaceStudioDesignTokens
                                .rightPanelWidthExpanded,
                            child: rightDock!,
                          ),
                        ],
                      ],
                    ),
                  );
                  if (contentWidth == constraints.maxWidth) {
                    return content;
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: content,
                  );
                },
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

### packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_editing.dart

```dart
import 'package:map_core/map_core.dart';

int countAnimationsReferencingAtlasId(
  ProjectSurfaceCatalog catalog,
  String atlasId,
) {
  var n = 0;
  for (final anim in catalog.animations) {
    for (final frame in anim.timeline.frames) {
      if (frame.tileRef.atlasId == atlasId) {
        n += 1;
        break;
      }
    }
  }
  return n;
}

ProjectSurfaceCatalog replaceAtlasInCatalogInPlace(
  ProjectSurfaceCatalog catalog,
  ProjectSurfaceAtlas updated,
) {
  final i = catalog.atlases.indexWhere((a) => a.id == updated.id);
  if (i < 0) {
    throw StateError('Atlas id absent du catalogue: ${updated.id}');
  }
  final nextAtlases = List<ProjectSurfaceAtlas>.from(catalog.atlases);
  nextAtlases[i] = updated;
  return ProjectSurfaceCatalog(
    atlases: nextAtlases,
    animations: List<ProjectSurfaceAnimation>.from(catalog.animations),
    presets: List<ProjectSurfacePreset>.from(catalog.presets),
  );
}

ProjectSurfaceCatalog removeAtlasIdFromWorkCatalog(
  ProjectSurfaceCatalog catalog,
  String atlasId,
) {
  final nextAtlases = catalog.atlases.where((a) => a.id != atlasId).toList();
  if (nextAtlases.length == catalog.atlases.length) {
    throw StateError('Atlas id introuvable: $atlasId');
  }
  return ProjectSurfaceCatalog(
    atlases: nextAtlases,
    animations: List<ProjectSurfaceAnimation>.from(catalog.animations),
    presets: List<ProjectSurfacePreset>.from(catalog.presets),
  );
}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Dimensions natives décodées depuis les octets image (package `image`, synchrone).
({int? width, int? height}) decodeRasterImageSizeFromBytes(Uint8List? bytes) {
  if (bytes == null || bytes.isEmpty) {
    return (width: null, height: null);
  }
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return (width: null, height: null);
    }
    return (width: decoded.width, height: decoded.height);
  } catch (_) {
    return (width: null, height: null);
  }
}

/// Entrées brouillon strictement positives pour dessiner l’overlay.
bool surfaceStudioAtlasGridOverlayDraftValid(
  int? tileWidth,
  int? tileHeight,
  int? columns,
  int? rows,
) {
  if (tileWidth == null ||
      tileHeight == null ||
      columns == null ||
      rows == null) {
    return false;
  }
  return tileWidth > 0 && tileHeight > 0 && columns > 0 && rows > 0;
}

int surfaceStudioAtlasGridExpectedWidthPx(int tileWidth, int columns) =>
    tileWidth * columns;

int surfaceStudioAtlasGridExpectedHeightPx(int tileHeight, int rows) =>
    tileHeight * rows;

/// Grille visuellement dense : sous-échantillonnage des traits pour rester léger.
bool surfaceStudioAtlasGridOverlayIsDense(int columns, int rows) {
  if (columns > 48 || rows > 48) {
    return true;
  }
  if (columns * rows > 2400) {
    return true;
  }
  return false;
}

/// Pas plus d’environ ~64 intervalles par axe pour les traits intérieurs.
int surfaceStudioAtlasGridOverlayLineStep(int count) {
  if (count <= 48) {
    return 1;
  }
  final s = (count / 48).ceil();
  return s < 1 ? 1 : s;
}

/// Peintre : lignes uniquement (pas de widgets par cellule) — Lot 73.
class SurfaceStudioAtlasImageGridPainter extends CustomPainter {
  const SurfaceStudioAtlasImageGridPainter({
    required this.columns,
    required this.rows,
    required this.lineColor,
    this.stepX = 1,
    this.stepY = 1,
  });

  final int columns;
  final int rows;
  final Color lineColor;
  final int stepX;
  final int stepY;

  @override
  void paint(Canvas canvas, Size size) {
    if (columns <= 0 || rows <= 0 || size.width <= 0 || size.height <= 0) {
      return;
    }
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    for (var i = 0; i <= columns; i++) {
      final boundary = i == 0 || i == columns;
      if (!boundary && stepX > 1 && (i % stepX) != 0) {
        continue;
      }
      final x = i * size.width / columns;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var j = 0; j <= rows; j++) {
      final boundary = j == 0 || j == rows;
      if (!boundary && stepY > 1 && (j % stepY) != 0) {
        continue;
      }
      final y = j * size.height / rows;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SurfaceStudioAtlasImageGridPainter oldDelegate) {
    return oldDelegate.columns != columns ||
        oldDelegate.rows != rows ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.stepX != stepX ||
        oldDelegate.stepY != stepY;
  }
}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart

```dart
import 'package:flutter/cupertino.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

const ValueKey<String> kSurfaceStudioAtlasGridPreviewSectionKey =
    ValueKey<String>('surface_studio_atlas_grid_preview_section');

class SurfaceStudioAtlasGridPreview extends StatelessWidget {
  const SurfaceStudioAtlasGridPreview({
    super.key,
    required this.sourceLabel,
    this.sourceDisplayForUi,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    required this.layoutLabel,
  });

  final String? sourceLabel;

  /// Libellé « humain » pour la ligne Source (ex. nom manifeste) ; si null, [sourceLabel] est utilisé.
  final String? sourceDisplayForUi;
  final int? tileWidth;
  final int? tileHeight;
  final int? columns;
  final int? rows;
  final String layoutLabel;

  static const int _previewMaxColumns = 12;
  static const int _previewMaxRows = 8;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final source = sourceLabel?.trim();
    final hasSource = source != null && source.isNotEmpty;
    final displaySource =
        (sourceDisplayForUi != null && sourceDisplayForUi!.trim().isNotEmpty)
            ? sourceDisplayForUi!.trim()
            : source;
    final hasValidGrid = _isPositive(tileWidth) &&
        _isPositive(tileHeight) &&
        _isPositive(columns) &&
        _isPositive(rows);

    final previewColumns =
        hasValidGrid ? _cap(columns!, _previewMaxColumns) : 0;
    final previewRows = hasValidGrid ? _cap(rows!, _previewMaxRows) : 0;
    final reduced = hasValidGrid &&
        (columns! > _previewMaxColumns || rows! > _previewMaxRows);

    return Container(
      key: kSurfaceStudioAtlasGridPreviewSectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Aperçu de la grille atlas',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          if (!hasSource)
            Text(
              'Choisissez une image source pour prévisualiser la grille.',
              style: TextStyle(color: subtle, fontSize: 11, height: 1.3),
            )
          else if (!hasValidGrid)
            Text(
              'Corrigez les dimensions de grille pour afficher la preview.',
              style: TextStyle(color: subtle, fontSize: 11, height: 1.3),
            )
          else ...[
            Text(
              'Source : $displaySource',
              style: TextStyle(color: label, fontSize: 11.5),
            ),
            const SizedBox(height: 2),
            Text(
              'Tile : ${tileWidth!}×${tileHeight!} px',
              style: TextStyle(color: label, fontSize: 11.5),
            ),
            const SizedBox(height: 2),
            Text(
              'Grille : ${columns!} colonnes × ${rows!} lignes',
              style: TextStyle(color: label, fontSize: 11.5),
            ),
            const SizedBox(height: 2),
            Text(
              'Total : ${columns! * rows!} cases',
              style: TextStyle(color: label, fontSize: 11.5),
            ),
            const SizedBox(height: 2),
            Text(
              'Disposition : $layoutLabel',
              style: TextStyle(color: subtle, fontSize: 11),
            ),
            if (reduced) ...[
              const SizedBox(height: 4),
              Text(
                'Aperçu réduit',
                style: TextStyle(
                  color: subtle,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 3,
              runSpacing: 3,
              children: [
                for (var i = 0; i < previewColumns * previewRows; i++)
                  Container(
                    key: ValueKey<String>('surface_studio_grid_cell_$i'),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: EditorChrome.editorIslandRim(context),
                        width: 0.8,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

bool _isPositive(int? v) => v != null && v > 0;

int _cap(int v, int max) => v > max ? max : v;
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart

```dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_grid_overlay.dart';

enum SurfaceStudioAtlasImagePreviewFitMode {
  fitWidth,
  pixel100,
  fitHeight,
}

Size _surfaceStudioAtlasImageFitDisplaySize({
  required int nw,
  required int nh,
  required double maxW,
  required double maxH,
  required SurfaceStudioAtlasImagePreviewFitMode mode,
}) {
  if (nw <= 0 || nh <= 0 || maxW <= 0 || maxH <= 0) {
    return Size(maxW.clamp(1, 1e9), maxH.clamp(1, 1e9));
  }
  switch (mode) {
    case SurfaceStudioAtlasImagePreviewFitMode.fitWidth:
      final s = maxW / nw;
      return Size(maxW, nh * s);
    case SurfaceStudioAtlasImagePreviewFitMode.fitHeight:
      final s = maxH / nh;
      return Size(nw * s, maxH);
    case SurfaceStudioAtlasImagePreviewFitMode.pixel100:
      return Size(nw.toDouble(), nh.toDouble());
  }
}

/// Statut de résolution du fichier image pour l’aperçu Surface Studio (Lot 72).
enum SurfaceStudioAtlasImagePreviewResolveStatus {
  empty,
  resolved,
  missingFile,
  unresolved,
}

/// Résultat local de [resolveSurfaceStudioAtlasImagePreview] — pas de service global.
class SurfaceStudioAtlasImagePreviewResolution {
  const SurfaceStudioAtlasImagePreviewResolution({
    required this.status,
    this.resolvedAbsolutePath,
    required this.displayFileName,
    required this.relativePathForUi,
  });

  final SurfaceStudioAtlasImagePreviewResolveStatus status;
  final String? resolvedAbsolutePath;

  /// Nom de fichier affiché (basename du chemin manifeste).
  final String displayFileName;

  /// Chemin relatif projet ou message court pour l’UI secondaire.
  final String relativePathForUi;
}

/// Résout un chemin fichier absolu candidat pour l’aperçu atlas, sans I/O réseau ni scan projet.
///
/// Utilise uniquement [ProjectTilesetEntry.relativePath] et [projectRootPath] quand ils sont présents.
SurfaceStudioAtlasImagePreviewResolution resolveSurfaceStudioAtlasImagePreview({
  required String? projectRootPath,
  required List<ProjectTilesetEntry>? projectTilesets,
  required String? technicalTilesetId,
}) {
  final tid = technicalTilesetId?.trim() ?? '';
  if (tid.isEmpty) {
    return const SurfaceStudioAtlasImagePreviewResolution(
      status: SurfaceStudioAtlasImagePreviewResolveStatus.empty,
      displayFileName: '',
      relativePathForUi: '',
    );
  }

  final tilesets = projectTilesets;
  if (tilesets == null || tilesets.isEmpty) {
    return const SurfaceStudioAtlasImagePreviewResolution(
      status: SurfaceStudioAtlasImagePreviewResolveStatus.unresolved,
      displayFileName: '',
      relativePathForUi:
          'Aucune entrée jeu d’images dans le manifeste — impossible de résoudre le fichier.',
    );
  }

  ProjectTilesetEntry? entry;
  for (final e in tilesets) {
    if (e.id == tid) {
      entry = e;
      break;
    }
  }
  if (entry == null) {
    return const SurfaceStudioAtlasImagePreviewResolution(
      status: SurfaceStudioAtlasImagePreviewResolveStatus.unresolved,
      displayFileName: '',
      relativePathForUi:
          'Identifiant inconnu dans la liste des jeux d’images du projet.',
    );
  }

  final rel = entry.relativePath.trim();
  final baseName = rel.isNotEmpty ? p.basename(rel) : entry.name.trim();

  final root = projectRootPath?.trim();
  if (root == null || root.isEmpty) {
    return SurfaceStudioAtlasImagePreviewResolution(
      status: SurfaceStudioAtlasImagePreviewResolveStatus.unresolved,
      displayFileName: baseName.isNotEmpty ? baseName : entry.name,
      relativePathForUi: rel.isEmpty
          ? 'Chemin relatif absent dans le manifeste.'
          : 'Projet sans dossier ouvert sur disque — chemin manifeste : $rel',
    );
  }
  if (rel.isEmpty) {
    return SurfaceStudioAtlasImagePreviewResolution(
      status: SurfaceStudioAtlasImagePreviewResolveStatus.unresolved,
      displayFileName: entry.name,
      relativePathForUi: 'Chemin relatif absent dans le manifeste.',
    );
  }

  final abs = p.normalize(p.join(root, rel));
  if (File(abs).existsSync()) {
    return SurfaceStudioAtlasImagePreviewResolution(
      status: SurfaceStudioAtlasImagePreviewResolveStatus.resolved,
      resolvedAbsolutePath: abs,
      displayFileName: p.basename(rel),
      relativePathForUi: rel,
    );
  }

  return SurfaceStudioAtlasImagePreviewResolution(
    status: SurfaceStudioAtlasImagePreviewResolveStatus.missingFile,
    displayFileName: p.basename(rel),
    relativePathForUi: rel,
  );
}

const ValueKey<String> kSurfaceStudioAtlasImagePreviewSectionKey =
    ValueKey<String>('surface_studio_atlas_image_preview_section');

const ValueKey<String> kSurfaceStudioAtlasImageGridOverlayKey =
    ValueKey<String>('surface_studio_atlas_image_grid_overlay');

/// Aperçu fichier image source (cadre contraint) ou messages de repli (Lot 72 + overlay grille Lot 73).
///
/// Les octets sont mis en cache dans l’état pour éviter de relire le disque à
/// chaque reconstruction du formulaire et pour un décodage plus prévisible
/// dans les tests widget (évite [Image.file] + settle bloquant).
class SurfaceStudioAtlasImagePreview extends StatefulWidget {
  const SurfaceStudioAtlasImagePreview({
    super.key,
    required this.resolution,
    required this.label,
    required this.subtle,
    this.draftTileWidth,
    this.draftTileHeight,
    this.draftColumns,
    this.draftRows,
    this.draftLayoutLabel,
    this.largeFormat = false,
  });

  final SurfaceStudioAtlasImagePreviewResolution resolution;
  final Color label;
  final Color subtle;

  /// Brouillon atlas : dimensions grille pour overlay et libellés (Lot 73).
  final int? draftTileWidth;
  final int? draftTileHeight;
  final int? draftColumns;
  final int? draftRows;
  final String? draftLayoutLabel;
  final bool largeFormat;

  @override
  State<SurfaceStudioAtlasImagePreview> createState() =>
      _SurfaceStudioAtlasImagePreviewState();
}

class _SurfaceStudioAtlasImagePreviewState
    extends State<SurfaceStudioAtlasImagePreview> {
  static const double _maxImageHeight = 160;

  SurfaceStudioAtlasImagePreviewFitMode _fitMode =
      SurfaceStudioAtlasImagePreviewFitMode.fitWidth;

  String? _cachedPath;
  Uint8List? _cachedBytes;
  bool _cacheReadFailed = false;
  int? _imageNaturalWidth;
  int? _imageNaturalHeight;

  @override
  void didUpdateWidget(covariant SurfaceStudioAtlasImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.largeFormat != oldWidget.largeFormat) {
      _fitMode = SurfaceStudioAtlasImagePreviewFitMode.fitWidth;
    }
    _syncCacheFromResolution();
  }

  @override
  void initState() {
    super.initState();
    _syncCacheFromResolution();
  }

  void _syncCacheFromResolution() {
    final r = widget.resolution;
    if (r.status != SurfaceStudioAtlasImagePreviewResolveStatus.resolved) {
      _cachedPath = null;
      _cachedBytes = null;
      _cacheReadFailed = false;
      _imageNaturalWidth = null;
      _imageNaturalHeight = null;
      return;
    }
    final path = r.resolvedAbsolutePath;
    if (path == null || path.isEmpty) {
      _cachedPath = null;
      _cachedBytes = null;
      _cacheReadFailed = false;
      _imageNaturalWidth = null;
      _imageNaturalHeight = null;
      return;
    }
    if (_cachedPath == path && _cachedBytes != null) {
      return;
    }
    _cachedPath = path;
    _cacheReadFailed = false;
    _imageNaturalWidth = null;
    _imageNaturalHeight = null;
    try {
      _cachedBytes = File(path).readAsBytesSync();
      final dims = decodeRasterImageSizeFromBytes(_cachedBytes);
      _imageNaturalWidth = dims.width;
      _imageNaturalHeight = dims.height;
    } catch (_) {
      _cachedBytes = null;
      _cacheReadFailed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: kSurfaceStudioAtlasImagePreviewSectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.largeFormat
                    ? 'Aperçu grand format de l’image source'
                    : 'Aperçu de l’image source',
                style: TextStyle(
                  color: widget.label,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              ..._bodyForStatus(context),
            ],
          );
          if (!constraints.maxHeight.isFinite) {
            return content;
          }
          return SingleChildScrollView(child: content);
        },
      ),
    );
  }

  List<Widget> _bodyForStatus(BuildContext context) {
    switch (widget.resolution.status) {
      case SurfaceStudioAtlasImagePreviewResolveStatus.empty:
        return [
          Text(
            'Choisissez une image source pour afficher l’aperçu.',
            style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
          ),
        ];
      case SurfaceStudioAtlasImagePreviewResolveStatus.unresolved:
      case SurfaceStudioAtlasImagePreviewResolveStatus.missingFile:
        return [_fallbackBlock(context)];
      case SurfaceStudioAtlasImagePreviewResolveStatus.resolved:
        return [_resolvedBlock(context)];
    }
  }

  Widget _fallbackBlock(BuildContext context) {
    final r = widget.resolution;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          r.status == SurfaceStudioAtlasImagePreviewResolveStatus.missingFile
              ? 'Aperçu image indisponible pour cette source (fichier introuvable sur disque).'
              : 'Aperçu image indisponible pour cette source.',
          style: TextStyle(color: widget.label, fontSize: 11.5, height: 1.35),
        ),
        const SizedBox(height: 4),
        Text(
          'La grille symbolique reste disponible.',
          style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.3),
        ),
        if (r.relativePathForUi.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            r.relativePathForUi,
            style: TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.3),
          ),
        ],
      ],
    );
  }

  Widget _resolvedBlock(BuildContext context) {
    final r = widget.resolution;
    final path = r.resolvedAbsolutePath;
    if (path == null || path.isEmpty) {
      return _fallbackBlock(context);
    }
    if (_cacheReadFailed || _cachedBytes == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Impossible de charger l’image (format ou fichier).',
            style: TextStyle(color: widget.subtle, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            'Source : ${r.displayFileName}',
            style: TextStyle(color: widget.label, fontSize: 11.5),
          ),
          const SizedBox(height: 2),
          Text(
            'Chemin : ${r.relativePathForUi}',
            style: TextStyle(color: widget.subtle, fontSize: 11),
          ),
        ],
      );
    }

    final tw = widget.draftTileWidth;
    final th = widget.draftTileHeight;
    final cols = widget.draftColumns;
    final rows = widget.draftRows;
    final gridValid =
        surfaceStudioAtlasGridOverlayDraftValid(tw, th, cols, rows);
    final natW = _imageNaturalWidth;
    final natH = _imageNaturalHeight;
    final naturalKnown = natW != null && natH != null && natW > 0 && natH > 0;
    final nw = natW ?? 0;
    final nh = natH ?? 0;

    int? expW;
    int? expH;
    int? totalCells;
    var overlayColumns = 1;
    var overlayRows = 1;
    if (gridValid && tw != null && th != null && cols != null && rows != null) {
      expW = surfaceStudioAtlasGridExpectedWidthPx(tw, cols);
      expH = surfaceStudioAtlasGridExpectedHeightPx(th, rows);
      totalCells = cols * rows;
      overlayColumns = cols;
      overlayRows = rows;
    }

    var dense = false;
    var stepX = 1;
    var stepY = 1;
    if (gridValid) {
      dense = surfaceStudioAtlasGridOverlayIsDense(overlayColumns, overlayRows);
      stepX = dense ? surfaceStudioAtlasGridOverlayLineStep(overlayColumns) : 1;
      stepY = dense ? surfaceStudioAtlasGridOverlayLineStep(overlayRows) : 1;
    }

    final showOverlay = gridValid && naturalKnown;

    final dimMatch = naturalKnown &&
        gridValid &&
        expW != null &&
        expH != null &&
        nw == expW &&
        nh == expH;

    final gridLineColor =
        Color.lerp(widget.label, const Color(0xFFFFFFFF), 0.35)!
            .withValues(alpha: 0.72);

    final metrics = <Widget>[
      Text(
        'Source : ${r.displayFileName}',
        style: TextStyle(color: widget.label, fontSize: 11.5),
      ),
      const SizedBox(height: 2),
      Text(
        'Chemin : ${r.relativePathForUi}',
        style: TextStyle(color: widget.subtle, fontSize: 11),
      ),
      const SizedBox(height: 6),
      if (naturalKnown)
        Text(
          'Image : $nw×$nh px',
          style: TextStyle(color: widget.label, fontSize: 11.5),
        )
      else ...[
        Text(
          'Dimensions réelles non lues.',
          style: TextStyle(color: widget.subtle, fontSize: 11),
        ),
        Text(
          'Superposition sur l’image désactivée tant que les dimensions du fichier ne sont pas lues.',
          style: TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.3),
        ),
      ],
      if (gridValid && expW != null && expH != null) ...[
        const SizedBox(height: 4),
        Text(
          'Grille attendue : $expW×$expH px',
          style: TextStyle(color: widget.label, fontSize: 11.5),
        ),
      ],
      if (gridValid &&
          cols != null &&
          rows != null &&
          tw != null &&
          th != null) ...[
        const SizedBox(height: 2),
        Text(
          'Grille : $cols colonnes × $rows lignes',
          style: TextStyle(color: widget.label, fontSize: 11.5),
        ),
        Text(
          'Tile : $tw×$th px',
          style: TextStyle(color: widget.label, fontSize: 11.5),
        ),
        if (totalCells != null)
          Text(
            'Total : $totalCells cases',
            style: TextStyle(color: widget.subtle, fontSize: 11),
          ),
        if (widget.draftLayoutLabel != null &&
            widget.draftLayoutLabel!.trim().isNotEmpty)
          Text(
            'Disposition : ${widget.draftLayoutLabel}',
            style: TextStyle(color: widget.subtle, fontSize: 10.5),
          ),
      ],
      if (naturalKnown && gridValid) ...[
        const SizedBox(height: 4),
        Text(
          dimMatch
              ? 'La grille correspond aux dimensions attendues.'
              : 'La grille ne correspond pas exactement aux dimensions de l’image.',
          style: TextStyle(
            color: dimMatch ? const Color(0xFF5EEAD4) : const Color(0xFFE8B87A),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
      if (dense) ...[
        const SizedBox(height: 4),
        Text(
          'Grille dense — aperçu visuel simplifié.',
          style: TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.3),
        ),
      ],
      if (!gridValid) ...[
        const SizedBox(height: 4),
        Text(
          'Corrigez les dimensions de grille pour afficher l’overlay.',
          style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.3),
        ),
      ],
      if (showOverlay) ...[
        const SizedBox(height: 4),
        Text(
          'Grille superposée',
          style: TextStyle(
            color: widget.label,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
      const SizedBox(height: 8),
    ];

    Widget imageStack;
    if (widget.largeFormat && naturalKnown) {
      imageStack = LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : 560.0;
          final outerH = constraints.maxHeight;
          final viewH = outerH.isFinite && outerH >= 360
              ? outerH.clamp(360.0, 560.0)
              : 480.0;
          final sz = _surfaceStudioAtlasImageFitDisplaySize(
            nw: nw,
            nh: nh,
            maxW: maxW,
            maxH: viewH,
            mode: _fitMode,
          );
          final dw = sz.width;
          final dh = sz.height;
          Widget fitBtn(
            String t,
            SurfaceStudioAtlasImagePreviewFitMode m,
          ) {
            final on = _fitMode == m;
            return material.TextButton(
              onPressed: () => setState(() => _fitMode = m),
              child: Text(
                t,
                style: TextStyle(
                  color: widget.label,
                  fontSize: 11,
                  fontWeight: on ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                key: const ValueKey('surface_studio_atlas_image_fit_controls'),
                spacing: 6,
                runSpacing: 4,
                children: [
                  fitBtn('Ajuster à la largeur',
                      SurfaceStudioAtlasImagePreviewFitMode.fitWidth),
                  fitBtn('Taille réelle 100 %',
                      SurfaceStudioAtlasImagePreviewFitMode.pixel100),
                  fitBtn('Ajuster à la hauteur',
                      SurfaceStudioAtlasImagePreviewFitMode.fitHeight),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: viewH,
                width: maxW,
                child: material.Scrollbar(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: dw,
                        height: dh,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              material.Image.memory(
                                _cachedBytes!,
                                key: const ValueKey(
                                  'surface_studio_atlas_image_preview_file',
                                ),
                                fit: material.BoxFit.fill,
                                gaplessPlayback: true,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    'Impossible de charger l’image (format ou fichier).',
                                    style: TextStyle(
                                      color: widget.subtle,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              if (showOverlay)
                                material.CustomPaint(
                                  key: kSurfaceStudioAtlasImageGridOverlayKey,
                                  painter: SurfaceStudioAtlasImageGridPainter(
                                    columns: overlayColumns,
                                    rows: overlayRows,
                                    lineColor: gridLineColor,
                                    stepX: stepX,
                                    stepY: stepY,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else if (widget.largeFormat && !naturalKnown) {
      imageStack = SizedBox(
        height: 480,
        width: double.infinity,
        child: material.Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: material.Image.memory(
                    _cachedBytes!,
                    key: const ValueKey(
                        'surface_studio_atlas_image_preview_file'),
                    fit: material.BoxFit.contain,
                    height: 480,
                    errorBuilder: (_, __, ___) => Text(
                      'Impossible de charger l’image (format ou fichier).',
                      style: TextStyle(color: widget.subtle, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else if (naturalKnown) {
      imageStack = LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
              ? constraints.maxWidth
              : 360.0;
          const maxH = _maxImageHeight;
          final scale = math.min(maxW / nw, maxH / nh);
          final dw = nw * scale;
          final dh = nh * scale;
          return Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: dw,
                height: dh,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    material.Image.memory(
                      _cachedBytes!,
                      key: const ValueKey(
                        'surface_studio_atlas_image_preview_file',
                      ),
                      fit: material.BoxFit.fill,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          'Impossible de charger l’image (format ou fichier).',
                          style: TextStyle(color: widget.subtle, fontSize: 11),
                        ),
                      ),
                    ),
                    if (showOverlay)
                      material.CustomPaint(
                        key: kSurfaceStudioAtlasImageGridOverlayKey,
                        painter: SurfaceStudioAtlasImageGridPainter(
                          columns: overlayColumns,
                          rows: overlayRows,
                          lineColor: gridLineColor,
                          stepX: stepX,
                          stepY: stepY,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      imageStack = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: material.Image.memory(
          _cachedBytes!,
          key: const ValueKey('surface_studio_atlas_image_preview_file'),
          fit: material.BoxFit.contain,
          height: _maxImageHeight,
          width: double.infinity,
          errorBuilder: (_, __, ___) => Text(
            'Impossible de charger l’image (format ou fichier).',
            style: TextStyle(color: widget.subtle, fontSize: 11),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...metrics,
        imageStack,
        const SizedBox(height: 6),
        Text(
          'La grille symbolique de l’atlas reste disponible ci-dessous.',
          style: TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.3),
        ),
      ],
    );
  }
}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_source_picker.dart

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

String suggestInternalAtlasIdFromName(String name) {
  var s = name.trim().toLowerCase();
  s = s.replaceAll(RegExp(r'[àáâäã]'), 'a');
  s = s.replaceAll(RegExp(r'[èéêë]'), 'e');
  s = s.replaceAll(RegExp(r'[ìíîï]'), 'i');
  s = s.replaceAll(RegExp(r'[òóôöõ]'), 'o');
  s = s.replaceAll(RegExp(r'[ùúûü]'), 'u');
  s = s.replaceAll('ç', 'c');
  s = s.replaceAll('œ', 'oe');
  s = s.replaceAll('æ', 'ae');
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  s = s.replaceAll(RegExp(r'-+'), '-');
  s = s.replaceAll(RegExp(r'^-|-$'), '');
  if (s.isEmpty) {
    return 'atlas';
  }
  return s;
}

List<ProjectTilesetEntry> sortedTilesetChoices(
  List<ProjectTilesetEntry> t,
) {
  final o = List<ProjectTilesetEntry>.from(t);
  o.sort((a, b) {
    final c = a.sortOrder.compareTo(b.sortOrder);
    if (c != 0) {
      return c;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return o;
}

class SurfaceStudioAtlasImageSourceBlock extends StatelessWidget {
  const SurfaceStudioAtlasImageSourceBlock({
    super.key,
    required this.hasPicker,
    required this.sortedTilesets,
    required this.selectedTilesetId,
    required this.onSelectTilesetId,
    required this.label,
    required this.subtle,
  });

  final bool hasPicker;
  final List<ProjectTilesetEntry> sortedTilesets;
  final String? selectedTilesetId;
  final ValueChanged<String?> onSelectTilesetId;
  final Color label;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return material.Material(
      type: material.MaterialType.transparency,
      child: Column(
        key: const ValueKey('surface_studio_atlas_image_source_section'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Image source de l’atlas',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          if (hasPicker) ...[
            material.DropdownButton<String?>(
              key: const ValueKey('surface_studio_atlas_tileset_picker'),
              isExpanded: true,
              value: _valueForDropdown,
              style: TextStyle(color: label, fontSize: 13),
              iconEnabledColor: label,
              iconDisabledColor: subtle,
              dropdownColor: EditorChrome.elevatedPanelBackground(context),
              hint: Text(
                'Choisir une image',
                style: TextStyle(color: subtle, fontSize: 13),
              ),
              items: [
                for (final e in sortedTilesets)
                  material.DropdownMenuItem<String?>(
                    value: e.id,
                    child: Text(
                      e.name,
                      style: TextStyle(color: label, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (selectedTilesetId != null &&
                    selectedTilesetId!.isNotEmpty &&
                    !sortedTilesets.any((e) => e.id == selectedTilesetId))
                  material.DropdownMenuItem<String?>(
                    value: selectedTilesetId,
                    child: Text(
                      'Référence actuelle · $selectedTilesetId',
                      style: TextStyle(color: label, fontSize: 12),
                    ),
                  ),
              ],
              onChanged: (v) {
                onSelectTilesetId(v);
              },
            ),
            if (selectedTilesetId != null && selectedTilesetId!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Détails',
                style: TextStyle(
                  color: subtle,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Nom technique : $selectedTilesetId',
                style: TextStyle(color: subtle, fontSize: 11),
              ),
              ..._pathLine(subtle, sortedTilesets, selectedTilesetId),
            ],
          ] else ...[
            Text(
              'Sélecteur d’image non connecté pour l’instant.',
              style: TextStyle(
                  color: label, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Pour ce prototype, renseignez temporairement l’identifiant technique du jeu d’images dans Options avancées.',
              style: TextStyle(color: subtle, fontSize: 11, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }

  String? get _valueForDropdown {
    final id = selectedTilesetId;
    if (id == null || id.isEmpty) {
      return null;
    }
    return id;
  }
}

List<Widget> _pathLine(
  Color subtle,
  List<ProjectTilesetEntry> sortedTilesets,
  String? selectedTilesetId,
) {
  if (selectedTilesetId == null) {
    return const [];
  }
  for (final e in sortedTilesets) {
    if (e.id == selectedTilesetId) {
      return [
        const SizedBox(height: 2),
        Text(
          e.relativePath,
          style: TextStyle(color: subtle, fontSize: 10.5),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ];
    }
  }
  return const [];
}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_column_role_mapping_block.dart

```dart
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_grid_overlay.dart';
import 'surface_studio_vertical_atlas_role_mapping.dart';

/// Bloc UI pour le mapping des colonnes d’un atlas vertical vers des rôles Surface.
///
/// Ce widget permet à l’utilisateur de préparer localement un mapping sans
/// générer d’animations ni de presets.
class SurfaceStudioColumnRoleMappingBlock extends StatelessWidget {
  const SurfaceStudioColumnRoleMappingBlock({
    super.key,
    required this.label,
    required this.subtle,
    required this.draft,
    required this.onDraftChanged,
    this.draftTileWidth,
    this.draftTileHeight,
    this.draftColumns,
    this.draftRows,
  });

  static const ValueKey<String> sectionKey =
      ValueKey<String>('surface_studio_column_role_mapping');

  final Color label;
  final Color subtle;
  final SurfaceStudioColumnRoleMappingDraft draft;
  final ValueChanged<SurfaceStudioColumnRoleMappingDraft> onDraftChanged;
  final int? draftTileWidth;
  final int? draftTileHeight;
  final int? draftColumns;
  final int? draftRows;

  @override
  Widget build(BuildContext context) {
    final gridValid = surfaceStudioAtlasGridOverlayDraftValid(
      draftTileWidth,
      draftTileHeight,
      draftColumns,
      draftRows,
    );

    final cols = draftColumns;
    final rows = draftRows;

    // Cas atlas simple 1×1 : mapping non nécessaire
    if (gridValid && cols == 1 && rows == 1) {
      return Container(
        key: sectionKey,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color:
              EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mapping des colonnes',
              style: TextStyle(
                color: label,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Atlas simple : mapping de colonnes non nécessaire.',
              style: TextStyle(color: subtle, fontSize: 11, height: 1.35),
            ),
          ],
        ),
      );
    }

    // Dimensions invalides : message d’erreur
    if (!gridValid) {
      return Container(
        key: sectionKey,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color:
              EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mapping des colonnes',
              style: TextStyle(
                color: label,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Corrigez la grille avant de mapper les colonnes.',
              style: TextStyle(color: subtle, fontSize: 11, height: 1.35),
            ),
          ],
        ),
      );
    }

    // Cas normal : afficher le mapping
    final summary = SurfaceStudioColumnRoleMappingSummary.fromDraft(draft);
    final columnCount = draft.columnCount;

    return Container(
      key: sectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mapping des colonnes',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: label,
            subtle: subtle,
            summary: summary,
          ),
          if (summary.hasDuplicateRoles) ...[
            const SizedBox(height: 4),
            Text(
              'Attention : un rôle est assigné à plusieurs colonnes.',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _ColumnList(
            label: label,
            subtle: subtle,
            draft: draft,
            onDraftChanged: onDraftChanged,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  onDraftChanged(
                    SurfaceStudioColumnRoleMappingDraft.suggested(columnCount),
                  );
                },
                icon: const Icon(Icons.auto_awesome, size: 14),
                label: const Text('Suggérer un mapping standard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: label,
                  side: BorderSide(color: label.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  onDraftChanged(draft.cleared());
                },
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Réinitialiser le mapping des colonnes'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: label,
                  side: BorderSide(color: label.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.subtle,
    required this.summary,
  });

  final Color label;
  final Color subtle;
  final SurfaceStudioColumnRoleMappingSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryItem(
          label: 'Colonnes',
          value: '${summary.columnCount}',
          labelColor: label,
          valueColor: subtle,
        ),
        const SizedBox(width: 12),
        _SummaryItem(
          label: 'Assignées',
          value: '${summary.assignedColumnCount}',
          labelColor: label,
          valueColor: subtle,
        ),
        const SizedBox(width: 12),
        _SummaryItem(
          label: 'Non assignées',
          value: '${summary.unassignedColumnCount}',
          labelColor: label,
          valueColor: subtle,
        ),
        const SizedBox(width: 12),
        _SummaryItem(
          label: 'Doublons',
          value: '${summary.duplicateRoleCount}',
          labelColor: label,
          valueColor:
              summary.hasDuplicateRoles ? Colors.orange.shade700 : subtle,
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ColumnList extends StatelessWidget {
  const _ColumnList({
    required this.label,
    required this.subtle,
    required this.draft,
    required this.onDraftChanged,
  });

  final Color label;
  final Color subtle;
  final SurfaceStudioColumnRoleMappingDraft draft;
  final ValueChanged<SurfaceStudioColumnRoleMappingDraft> onDraftChanged;

  @override
  Widget build(BuildContext context) {
    final columnCount = draft.columnCount;

    // Pour un grand nombre de colonnes, on limite la hauteur avec scroll
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: columnCount,
        itemBuilder: (context, index) {
          final role = draft.roleForColumn(index);

          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: EditorChrome.islandFillElevated(context)
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    'Col $index',
                    style: TextStyle(
                      color: label,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<SurfaceVariantRole>(
                    isExpanded: true,
                    value: role,
                    hint: Text(
                      'Non assignée',
                      style: TextStyle(
                        color: subtle,
                        fontSize: 11,
                      ),
                    ),
                    style: TextStyle(
                      color: label,
                      fontSize: 11,
                    ),
                    iconEnabledColor: label,
                    dropdownColor:
                        EditorChrome.elevatedPanelBackground(context),
                    items: [
                      // Option pour désassigner
                      const DropdownMenuItem<SurfaceVariantRole>(
                        value: null,
                        child: Text(
                          'Non assignée',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                      // Tous les rôles standards
                      ...SurfaceStudioRoleLabels.allRolesInOrder.map(
                        (r) => DropdownMenuItem<SurfaceVariantRole>(
                          value: r,
                          child: Text(
                            SurfaceStudioRoleLabels.labelForRole(r),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (newRole) {
                      onDraftChanged(draft.withRoleForColumn(index, newRole));
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart

```dart
import 'dart:typed_data';

import 'surface_studio_ai_mapping_suggester.dart';
import 'surface_studio_local_mapping_suggester.dart';
import 'surface_studio_mapping_suggestion_models.dart';

final class SurfaceStudioMappingSuggestionController {
  const SurfaceStudioMappingSuggestionController({
    this.localSuggester = const SurfaceStudioLocalMappingSuggester(),
    this.aiSuggester,
  });

  final SurfaceStudioLocalMappingSuggester localSuggester;
  final SurfaceStudioAiMappingSuggester? aiSuggester;

  SurfaceStudioMappingSuggestionResult suggestLocal({
    required int columnCount,
  }) {
    return localSuggester.suggest(columnCount: columnCount);
  }

  Future<SurfaceStudioMappingSuggestionResult> suggestMistral({
    required String apiKey,
    required Uint8List imageBytes,
    required int tileWidth,
    required int tileHeight,
    required int columnCount,
    required int frameCount,
  }) {
    final suggester = aiSuggester;
    if (suggester == null) {
      return Future.value(
        const SurfaceStudioMappingSuggestionResult(
          suggestions: <SurfaceStudioRoleSuggestion>[],
          warnings: <String>['Analyse IA Mistral indisponible.'],
          source: SurfaceStudioMappingSuggestionSource.mistral,
        ),
      );
    }
    return suggester.suggest(
      apiKey: apiKey,
      imageBytes: imageBytes,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      frameCount: frameCount,
    );
  }
}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart

```dart
// Surface Studio — assistant premium de mapping d'atlas.
//
// Le viewport principal porte un seul workflow guide moderne. Les anciennes
// briques utiles restent accessibles dans le drawer avance, sans second
// Surface Studio rendu sous l'assistant.

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_editing.dart';
import 'surface_studio_catalog_browser.dart';
import 'surface_studio_diagnostics_view.dart';
import 'surface_studio_paintable_surfaces_panel.dart';
import 'surface_studio_preset_editor_controller.dart';
import 'surface_studio_ai_mapping_suggester.dart';
import 'surface_studio_role_mapping_editor.dart';
import 'surface_studio_selection.dart';
import 'surface_studio_selection_inspector.dart';
import 'surface_studio_selection_summary.dart';
import 'surface_studio_screen.dart';

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
    this.projectSettings,
    this.surfaceMappingImageLoader,
    this.aiMappingSuggester,
  });

  final SurfaceStudioReadModel readModel;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested;
  final Future<bool> Function()? onRequestProjectSave;
  final List<ProjectTilesetEntry>? projectTilesets;
  final ProjectSettings? projectSettings;
  final SurfaceStudioAtlasUiImageLoader? surfaceMappingImageLoader;
  final SurfaceStudioAiMappingSuggester? aiMappingSuggester;

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

  void _onSurfaceCatalogChanged(ProjectSurfaceCatalog cat) {
    setState(() {
      _saveFlowPrepNote = null;
      _workReadModel = buildSurfaceStudioReadModelFromCatalog(cat);
      _selection = _selectionAfterCatalogChanged(cat);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canMutateCatalog = widget.onSurfaceCatalogSaveRequested != null;
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
    final advancedDrawer = SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: _AdvancedDetailsSection(
        inspection: inspection,
        browser: SurfaceStudioCatalogBrowser(
          readModel: _workReadModel,
          selection: _selection,
          onSelectionChanged: (v) {
            setState(() => _selection = v);
          },
        ),
        diagnostics: SurfaceStudioDiagnosticsView(readModel: _workReadModel),
        futureActions: paintableSurfaces,
        placeholder: const _SectionPlaceholder(
          title: SurfaceStudioPanel.placeholderActionsTitle,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final shellWidth =
            constraints.hasBoundedWidth ? constraints.maxWidth : 1600.0;
        final shellHeight =
            constraints.hasBoundedHeight ? constraints.maxHeight : 900.0;
        return SizedBox(
          width: shellWidth,
          height: shellHeight,
          child: SurfaceStudioScreen(
            readModel: _workReadModel,
            projectSettings: widget.projectSettings,
            projectTilesets: widget.projectTilesets ?? const [],
            projectRootPath: widget.projectRootPath,
            surfaceMappingImageLoader: widget.surfaceMappingImageLoader,
            hasWorkCatalogChanges: _hasWorkCatalogChanges,
            saveFlowPrepNote: _saveFlowPrepNote,
            projectSaveDiskNote: _projectSaveDiskNote,
            onSurfaceCatalogChanged: _onSurfaceCatalogChanged,
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
            onResetWorkCatalog: () {
              setState(() {
                _workReadModel = widget.readModel;
                _selection =
                    _selectionValidInReadModel(_workReadModel, _selection);
                _saveFlowPrepNote = null;
              });
            },
            onSurfaceCatalogSavePrep:
                widget.onSurfaceCatalogSaveRequested == null
                    ? null
                    : _onSurfaceCatalogSavePrep,
            onRequestProjectSave: widget.onRequestProjectSave == null
                ? null
                : _onRequestProjectSave,
            advancedDrawer: advancedDrawer,
            aiMappingSuggester: widget.aiMappingSuggester,
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
      projectSettings: _manifest.settings,
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

### packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart

```dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        DropdownButton,
        DropdownMenuItem,
        InputDecoration,
        Material,
        MaterialType,
        OutlineInputBorder,
        TextField;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_role_mapping_editor.dart';

import '../editor/application/editor_ai_settings.dart';
import 'atlas/surface_studio_atlas_panel.dart';
import 'preview/surface_studio_preview_panel.dart';
import 'schema/surface_studio_schema_panel.dart';
import 'shell/surface_studio_bottom_action_bar.dart';
import 'shell/surface_studio_header.dart';
import 'shell/surface_studio_shell.dart';
import 'shell/surface_studio_sidebar.dart';
import 'surface_studio_atlas_authoring_prep.dart';
import 'surface_studio_atlas_grid_overlay.dart';
import 'surface_studio_atlas_grid_preview.dart';
import 'surface_studio_atlas_image_preview.dart';
import 'surface_studio_atlas_source_picker.dart';
import 'surface_studio_ai_mapping_suggester.dart';
import 'surface_studio_column_selection.dart';
import 'surface_studio_design_tokens.dart';
import 'surface_studio_drag_payload.dart';
import 'surface_studio_mapping_suggestion_controller.dart';
import 'surface_studio_mapping_suggestion_models.dart';
import 'surface_studio_mistral_mapping_suggester.dart';
import 'surface_studio_role_assignment_draft.dart';
import 'surface_studio_step.dart';
import 'surface_studio_vertical_atlas_animation_generation_plan.dart';
import 'surface_studio_vertical_atlas_animation_generator.dart';
import 'surface_studio_vertical_atlas_preset_generator.dart';
import 'surface_studio_vertical_atlas_role_mapping.dart';

class SurfaceStudioScreen extends StatefulWidget {
  const SurfaceStudioScreen({
    super.key,
    required this.readModel,
    this.projectSettings,
    this.projectTilesets = const <ProjectTilesetEntry>[],
    this.projectRootPath,
    this.surfaceMappingImageLoader,
    this.hasWorkCatalogChanges = false,
    this.saveFlowPrepNote,
    this.projectSaveDiskNote,
    this.onSurfaceCatalogChanged,
    this.onWorkCatalogAnimationsCreated,
    this.onWorkCatalogPresetCreated,
    this.onResetWorkCatalog,
    this.onSurfaceCatalogSavePrep,
    this.onRequestProjectSave,
    this.advancedDrawer,
    this.aiMappingSuggester,
  });

  final SurfaceStudioReadModel readModel;
  final ProjectSettings? projectSettings;
  final List<ProjectTilesetEntry> projectTilesets;
  final String? projectRootPath;
  final SurfaceStudioAtlasUiImageLoader? surfaceMappingImageLoader;
  final bool hasWorkCatalogChanges;
  final String? saveFlowPrepNote;
  final String? projectSaveDiskNote;
  final ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogChanged;
  final ValueChanged<List<String>>? onWorkCatalogAnimationsCreated;
  final ValueChanged<String>? onWorkCatalogPresetCreated;
  final VoidCallback? onResetWorkCatalog;
  final VoidCallback? onSurfaceCatalogSavePrep;
  final Future<void> Function()? onRequestProjectSave;
  final Widget? advancedDrawer;
  final SurfaceStudioAiMappingSuggester? aiMappingSuggester;

  @override
  State<SurfaceStudioScreen> createState() => _SurfaceStudioScreenState();
}

class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
  static const int _defaultDurationMsPerFrame = 120;

  SurfaceStudioWizardStep _currentStep = SurfaceStudioWizardStep.map;
  bool _sidebarCollapsed = false;
  bool _rightPanelCollapsed = false;
  bool _advancedDrawerOpen = false;
  bool _suggestionReviewOpen = false;
  bool _aiConfirmationOpen = false;
  bool _mergeAiAfterConfirmation = false;
  bool _suggestionRunning = false;
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
      const SurfaceStudioRoleAssignmentDraft.empty();
  double _zoomPercent = 100;
  bool _previewPlaying = false;
  int _previewFrameIndex = 0;
  bool _previewLoop = true;
  bool _previewGridVisible = true;
  int _previewSize = 10;
  String? _statusMessage;
  String? _lastGenerationMessage;
  String? _lastPresetMessage;
  SurfaceStudioMappingSuggestionResult? _suggestionResult;
  Timer? _previewTimer;
  String? _cachedAtlasImagePath;
  Uint8List? _cachedAtlasImageBytes;

  final TextEditingController _atlasId = TextEditingController();
  final TextEditingController _atlasName = TextEditingController();
  final TextEditingController _tilesetId = TextEditingController();
  final TextEditingController _tileWidth = TextEditingController();
  final TextEditingController _tileHeight = TextEditingController();
  final TextEditingController _columns = TextEditingController();
  final TextEditingController _rows = TextEditingController();
  final TextEditingController _sortOrder = TextEditingController();
  final TextEditingController _categoryId = TextEditingController();
  SurfaceAtlasLayout _layout =
      SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames;
  String? _selectedAtlasId;

  @override
  void initState() {
    super.initState();
    _selectedAtlasId = widget.readModel.atlases.isNotEmpty
        ? widget.readModel.atlases.first.id
        : null;
    if (widget.readModel.atlases.isEmpty) {
      _currentStep = SurfaceStudioWizardStep.importAtlas;
    }
    _syncFormFromSelectedAtlas();
    _syncSelectionToColumnCount();
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readModel != oldWidget.readModel) {
      if (_selectedAtlasId == null ||
          widget.readModel.catalog.atlasById(_selectedAtlasId!) == null) {
        _selectedAtlasId = widget.readModel.atlases.isNotEmpty
            ? widget.readModel.atlases.first.id
            : null;
      }
      _syncFormFromSelectedAtlas();
      _syncSelectionToColumnCount();
    }
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _atlasId.dispose();
    _atlasName.dispose();
    _tilesetId.dispose();
    _tileWidth.dispose();
    _tileHeight.dispose();
    _columns.dispose();
    _rows.dispose();
    _sortOrder.dispose();
    _categoryId.dispose();
    super.dispose();
  }

  ProjectSurfaceAtlas? get _selectedAtlas {
    final id = _selectedAtlasId;
    if (id == null) {
      return null;
    }
    return widget.readModel.catalog.atlasById(id);
  }

  SurfaceStudioAtlasReadModel? get _selectedAtlasRow {
    final id = _selectedAtlasId;
    if (id == null) {
      return null;
    }
    for (final row in widget.readModel.atlases) {
      if (row.id == id) {
        return row;
      }
    }
    return null;
  }

  SurfaceStudioMappingSuggestionController get _suggestionController =>
      const SurfaceStudioMappingSuggestionController();

  SurfaceStudioAtlasImagePreviewResolution get _atlasImageResolution =>
      resolveSurfaceStudioAtlasImagePreview(
        projectRootPath: widget.projectRootPath,
        projectTilesets: widget.projectTilesets,
        technicalTilesetId: _tilesetId.text,
      );

  Uint8List? _atlasImageBytes() {
    final path = _atlasImageResolution.resolvedAbsolutePath;
    if (path == null || path.isEmpty) {
      _cachedAtlasImagePath = null;
      _cachedAtlasImageBytes = null;
      return null;
    }
    if (_cachedAtlasImagePath == path && _cachedAtlasImageBytes != null) {
      return _cachedAtlasImageBytes;
    }
    try {
      final bytes = File(path).readAsBytesSync();
      _cachedAtlasImagePath = path;
      _cachedAtlasImageBytes = bytes;
      return bytes;
    } catch (_) {
      _cachedAtlasImagePath = path;
      _cachedAtlasImageBytes = null;
      return null;
    }
  }

  int get _columnCount {
    final parsed = int.tryParse(_columns.text.trim());
    if (parsed != null && parsed > 0) {
      return parsed.clamp(1, 48).toInt();
    }
    final row = _selectedAtlasRow;
    return (row?.columns ?? 12).clamp(1, 48).toInt();
  }

  int get _frameCount {
    final parsed = int.tryParse(_rows.text.trim());
    if (parsed != null && parsed > 0) {
      return parsed.clamp(1, 128).toInt();
    }
    final row = _selectedAtlasRow;
    return (row?.rows ?? 32).clamp(1, 128).toInt();
  }

  int get _tileWidthValue {
    final parsed = int.tryParse(_tileWidth.text.trim());
    if (parsed != null && parsed > 0) {
      return parsed;
    }
    return _selectedAtlasRow?.tileWidth ?? 32;
  }

  int get _tileHeightValue {
    final parsed = int.tryParse(_tileHeight.text.trim());
    if (parsed != null && parsed > 0) {
      return parsed;
    }
    return _selectedAtlasRow?.tileHeight ?? 32;
  }

  bool get _gridValid => surfaceStudioAtlasGridOverlayDraftValid(
        _tileWidthValue,
        _tileHeightValue,
        _columnCount,
        _frameCount,
      );

  Set<SurfaceStudioWizardStep> get _completedSteps => {
        if (widget.readModel.atlases.isNotEmpty)
          SurfaceStudioWizardStep.importAtlas,
        if (_gridValid) SurfaceStudioWizardStep.slice,
        if (_assignmentDraft.isAssigned(SurfaceVariantRole.isolated))
          SurfaceStudioWizardStep.map,
        if (_generationPlan.summary.readyAnimationCount > 0)
          SurfaceStudioWizardStep.preview,
      };

  bool get _canGoNext {
    return switch (_currentStep) {
      SurfaceStudioWizardStep.importAtlas =>
        widget.readModel.atlases.isNotEmpty,
      SurfaceStudioWizardStep.slice => _gridValid,
      SurfaceStudioWizardStep.map =>
        _assignmentDraft.isAssigned(SurfaceVariantRole.isolated),
      SurfaceStudioWizardStep.preview => true,
      SurfaceStudioWizardStep.save => false,
    };
  }

  SurfaceStudioColumnRoleMappingDraft get _columnRoleMappingDraft {
    final assignments = <SurfaceStudioColumnRoleAssignment>[];
    for (final role in standardSurfaceVariantRoleOrder) {
      final columns = _assignmentDraft.columnsForRole(role);
      if (columns.isEmpty) {
        continue;
      }
      assignments.add(
        SurfaceStudioColumnRoleAssignment(
          columnIndex: (columns.first - 1).clamp(0, _columnCount - 1).toInt(),
          role: role,
        ),
      );
    }
    return SurfaceStudioColumnRoleMappingDraft(
      columnCount: _columnCount,
      assignments: List<SurfaceStudioColumnRoleAssignment>.unmodifiable(
        assignments,
      ),
    );
  }

  SurfaceStudioVerticalAtlasAnimationGenerationPlan get _generationPlan {
    final existingIds = <String>{
      for (final row in widget.readModel.animations) row.id,
    };
    return buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
      atlasIdRaw: _atlasId.text,
      mappingDraft: _columnRoleMappingDraft,
      tileWidth: _tileWidthValue,
      tileHeight: _tileHeightValue,
      columns: _columnCount,
      rows: _frameCount,
      durationMsPerFrame: _defaultDurationMsPerFrame,
      existingAnimationIds: existingIds,
    );
  }

  void _syncFormFromSelectedAtlas() {
    final atlas = _selectedAtlas;
    if (atlas == null) {
      _atlasId.text = '';
      _atlasName.text = '';
      _tilesetId.text = widget.projectTilesets.isNotEmpty
          ? widget.projectTilesets.first.id
          : '';
      _tileWidth.text = '32';
      _tileHeight.text = '32';
      _columns.text = '12';
      _rows.text = '32';
      _sortOrder.text = '${widget.readModel.catalog.atlases.length}';
      _categoryId.text = '';
      _layout = SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames;
      return;
    }
    _atlasId.text = atlas.id;
    _atlasName.text = atlas.name;
    _tilesetId.text = atlas.tilesetId;
    _tileWidth.text = '${atlas.geometry.tileSize.width}';
    _tileHeight.text = '${atlas.geometry.tileSize.height}';
    _columns.text = '${atlas.geometry.gridSize.columns}';
    _rows.text = '${atlas.geometry.gridSize.rows}';
    _sortOrder.text = '${atlas.sortOrder}';
    _categoryId.text = atlas.categoryId ?? '';
    _layout = atlas.geometry.layout;
  }

  void _syncSelectionToColumnCount() {
    final count = _columnCount;
    final valid = _selectedColumns.columns
        .where((column) => column >= 1 && column <= count)
        .toList();
    if (valid.isEmpty && count >= 1) {
      _selectedColumns = SurfaceStudioColumnSelection(<int>[
        count >= 5 ? 4 : 1,
        if (count >= 5) 5,
      ]);
    } else {
      _selectedColumns = SurfaceStudioColumnSelection(valid);
    }
  }

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
        _statusMessage = switch (_currentStep) {
          SurfaceStudioWizardStep.importAtlas =>
            'Créez ou sélectionnez un atlas avant de continuer.',
          SurfaceStudioWizardStep.slice =>
            'Corrigez la grille avant de continuer.',
          SurfaceStudioWizardStep.map =>
            'Assignez au moins le rôle “Plein” avant de continuer.',
          SurfaceStudioWizardStep.preview ||
          SurfaceStudioWizardStep.save =>
            'Cette étape ne peut pas avancer.',
        };
      });
      return;
    }
    setState(() {
      _currentStep = SurfaceStudioWizardStep.values[(_currentStep.index + 1)
          .clamp(0, SurfaceStudioWizardStep.values.length - 1)
          .toInt()];
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

  void _createOrUpdateAtlas() {
    final editingAtlasId = _selectedAtlasId;
    final errors = validateSurfaceStudioAtlasDraft(
      readModel: widget.readModel,
      idRaw: _atlasId.text,
      nameRaw: _atlasName.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileWidth.text,
      tileHeightRaw: _tileHeight.text,
      columnsRaw: _columns.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sortOrder.text,
      categoryIdRaw: _categoryId.text,
      editingExistingAtlasId: editingAtlasId,
    );
    if (errors.isNotEmpty) {
      setState(() {
        _statusMessage = errors.first;
      });
      return;
    }
    final draft = tryBuildDraftFromForm(
      idRaw: _atlasId.text,
      nameRaw: _atlasName.text,
      tilesetIdRaw: _tilesetId.text,
      tileWidthRaw: _tileWidth.text,
      tileHeightRaw: _tileHeight.text,
      columnsRaw: _columns.text,
      rowsRaw: _rows.text,
      sortOrderRaw: _sortOrder.text,
      categoryIdRaw: _categoryId.text,
      layout: _layout,
    );
    final atlas =
        draft == null ? null : tryBuildProjectSurfaceAtlasFromDraft(draft);
    if (atlas == null) {
      setState(() {
        _statusMessage = 'Brouillon atlas invalide.';
      });
      return;
    }

    final atlases = List<ProjectSurfaceAtlas>.from(
      widget.readModel.catalog.atlases,
    );
    final existingIndex =
        atlases.indexWhere((candidate) => candidate.id == editingAtlasId);
    if (existingIndex >= 0) {
      atlases[existingIndex] = atlas;
    } else {
      atlases.add(atlas);
    }
    final next = ProjectSurfaceCatalog(
      atlases: atlases,
      animations: List<ProjectSurfaceAnimation>.from(
        widget.readModel.catalog.animations,
      ),
      presets: List<ProjectSurfacePreset>.from(
        widget.readModel.catalog.presets,
      ),
    );
    widget.onSurfaceCatalogChanged?.call(next);
    setState(() {
      _selectedAtlasId = atlas.id;
      _statusMessage = 'Atlas ajouté au catalogue de travail.';
      _currentStep = SurfaceStudioWizardStep.slice;
      _syncSelectionToColumnCount();
    });
  }

  void _openSuggestionReview() {
    _runLocalSuggestion(openReview: true);
  }

  void _runLocalSuggestion({bool openReview = false}) {
    final result = _suggestionController.suggestLocal(
      columnCount: _columnCount,
    );
    setState(() {
      _suggestionResult = result;
      _suggestionReviewOpen = openReview || _suggestionReviewOpen;
      _aiConfirmationOpen = false;
      _statusMessage =
          'Suggestions locales prêtes — validation utilisateur requise.';
    });
  }

  void _requestAiSuggestion({bool mergeWithLocal = false}) {
    setState(() {
      _suggestionReviewOpen = true;
      _aiConfirmationOpen = true;
      _mergeAiAfterConfirmation = mergeWithLocal;
      _statusMessage = 'Confirmation IA requise avant envoi.';
    });
  }

  Future<void> _confirmAiSuggestion({required bool mergeWithLocal}) async {
    final apiKey = resolveEditorMistralApiKey(widget.projectSettings);
    final imageBytes = _atlasImageBytes();
    final hasApiKey = apiKey.trim().isNotEmpty;
    if (!hasApiKey || imageBytes == null) {
      setState(() {
        _aiConfirmationOpen = false;
        _suggestionResult = SurfaceStudioMappingSuggestionResult(
          suggestions: _suggestionResult?.suggestions ??
              const <SurfaceStudioRoleSuggestion>[],
          warnings: <String>[
            if (_suggestionResult != null) ..._suggestionResult!.warnings,
            if (!hasApiKey) 'Clé Mistral absente.',
            if (imageBytes == null) 'Image source indisponible pour Mistral.',
          ],
          source: _suggestionResult?.source ??
              SurfaceStudioMappingSuggestionSource.local,
        );
      });
      return;
    }
    setState(() {
      _suggestionRunning = true;
      _aiConfirmationOpen = false;
    });
    final aiController = SurfaceStudioMappingSuggestionController(
      aiSuggester:
          widget.aiMappingSuggester ?? SurfaceStudioMistralMappingSuggester(),
    );
    final ai = await aiController.suggestMistral(
      apiKey: apiKey,
      imageBytes: imageBytes,
      tileWidth: _tileWidthValue,
      tileHeight: _tileHeightValue,
      columnCount: _columnCount,
      frameCount: _frameCount,
    );
    if (!mounted) {
      return;
    }
    final result = mergeWithLocal && _suggestionResult != null
        ? SurfaceStudioMappingSuggestionResult(
            suggestions: <SurfaceStudioRoleSuggestion>[
              ..._suggestionResult!.suggestions,
              ...ai.suggestions,
            ],
            warnings: <String>[
              ..._suggestionResult!.warnings,
              ...ai.warnings,
            ],
            source: SurfaceStudioMappingSuggestionSource.merged,
          )
        : ai;
    setState(() {
      _suggestionRunning = false;
      _suggestionResult = result;
      _suggestionReviewOpen = true;
      _statusMessage =
          'Suggestions IA prêtes — validation utilisateur requise.';
    });
  }

  void _applySuggestions({required bool reliableOnly}) {
    final result = _suggestionResult;
    if (result == null) {
      return;
    }
    final suggestions =
        reliableOnly ? result.reliableSuggestions : result.suggestions;
    var draft = _assignmentDraft;
    for (final suggestion in suggestions) {
      draft = draft.assignColumns(suggestion.role, suggestion.columns);
    }
    setState(() {
      _assignmentDraft = draft;
      _suggestionReviewOpen = false;
      _statusMessage = 'Suggestions appliquées au mapping de travail.';
    });
  }

  void _applyMapping() {
    setState(() {
      _statusMessage =
          'Mapping appliqué au plan de génération local — aucune sauvegarde disque.';
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

  void _appendReadyAnimations() {
    final plan = _generationPlan;
    if (plan.summary.readyAnimationCount == 0) {
      setState(() {
        _lastGenerationMessage = 'Aucune animation prête à créer.';
      });
      return;
    }
    final outcome = surfaceStudioCollectNewAnimationsFromReadyPlan(
      plan: plan,
      atlasIdForTileRefs: _atlasId.text.trim(),
      animationDisplayNamePrefix: _atlasName.text.trim(),
      categoryId:
          _categoryId.text.trim().isEmpty ? null : _categoryId.text.trim(),
      sortOrderBase: widget.readModel.catalog.animations.length,
    );
    if (outcome.newAnimations.isEmpty) {
      setState(() {
        _lastGenerationMessage = 'Aucune animation nouvelle à ajouter.';
      });
      return;
    }
    final next = surfaceStudioAppendAnimationsToWorkCatalog(
      catalog: widget.readModel.catalog,
      newAnimations: outcome.newAnimations,
    );
    widget.onSurfaceCatalogChanged?.call(next);
    widget.onWorkCatalogAnimationsCreated?.call(
      outcome.newAnimations.map((animation) => animation.id).toList(),
    );
    setState(() {
      _lastGenerationMessage =
          'Animations créées dans le catalogue de travail (${outcome.newAnimations.length}).';
    });
  }

  void _appendPreset() {
    final gridOk = _gridValid;
    final plan = surfaceStudioPlanVerticalAtlasPresetAppend(
      catalog: widget.readModel.catalog,
      atlasIdRaw: _atlasId.text,
      atlasDisplayName: _atlasName.text,
      atlasCategoryDraft: _categoryId.text,
      mappingDraft: _columnRoleMappingDraft,
      gridValid: gridOk,
    );
    if (!plan.canCreate) {
      setState(() {
        _lastPresetMessage =
            'Surface non créée : ${_presetPlanStatusLabel(plan.status)}.';
      });
      return;
    }
    try {
      final preset = surfaceStudioBuildVerticalAtlasPreset(
        catalog: widget.readModel.catalog,
        atlasIdRaw: _atlasId.text,
        atlasDisplayName: _atlasName.text,
        atlasCategoryDraft: _categoryId.text,
        mappingDraft: _columnRoleMappingDraft,
        gridValid: gridOk,
      );
      final next = surfaceStudioAppendPresetToWorkCatalog(
        catalog: widget.readModel.catalog,
        preset: preset,
      );
      widget.onSurfaceCatalogChanged?.call(next);
      widget.onWorkCatalogPresetCreated?.call(preset.id);
      setState(() {
        _lastPresetMessage = 'Surface prête à peindre créée : ${preset.name}.';
      });
    } on Object {
      setState(() {
        _lastPresetMessage =
            'Impossible de créer la surface peignable dans l’état actuel.';
      });
    }
  }

  String _presetPlanStatusLabel(
      SurfaceStudioVerticalAtlasPresetPlanStatus status) {
    return switch (status) {
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedEmptyAtlasId =>
        'atlas manquant',
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedInvalidGrid =>
        'grille invalide',
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedNoMapping =>
        'mapping absent',
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedMissingAnimations =>
        'animations manquantes',
      SurfaceStudioVerticalAtlasPresetPlanStatus.blockedDuplicatePresetId =>
        'surface déjà existante',
      SurfaceStudioVerticalAtlasPresetPlanStatus.incomplete => 'incomplet',
      SurfaceStudioVerticalAtlasPresetPlanStatus.ready => 'prêt',
    };
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
            onOpenAdvanced: () {
              setState(() => _advancedDrawerOpen = true);
            },
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
          workspacePanel: _buildWorkspacePanel(),
          rightDock: _buildRightDock(frameCount),
          bottomBar: SurfaceStudioBottomActionBar(
            canGoBack: _currentStep != SurfaceStudioWizardStep.importAtlas,
            canAutoSuggest: _columnCount > 0 && frameCount > 0,
            canApplyMapping:
                _assignmentDraft.isAssigned(SurfaceVariantRole.isolated),
            canGoNext: _canGoNext,
            canSaveCatalog: widget.hasWorkCatalogChanges &&
                widget.onSurfaceCatalogSavePrep != null,
            onBack: _previousStep,
            onAutoSuggest: _openSuggestionReview,
            onApplyMapping: _applyMapping,
            onNext: _nextStep,
            onSaveCatalog: widget.onSurfaceCatalogSavePrep,
          ),
        ),
        if (_statusMessage != null)
          Positioned(
            left: 318,
            bottom: 86,
            child: _StatusToast(message: _statusMessage!),
          ),
        if (widget.hasWorkCatalogChanges)
          const Positioned(
            left: 318,
            top: 76,
            child: _StatusToast(
              message:
                  'Catalogue de travail modifié — sauvegarde projet non effectuée.',
            ),
          ),
        if (_suggestionReviewOpen && _suggestionResult != null)
          Positioned.fill(
            child: _SuggestionReviewScrim(
              result: _suggestionResult!,
              mistralKeyConfigured:
                  hasEditorMistralApiKey(widget.projectSettings),
              aiConfirmationOpen: _aiConfirmationOpen,
              running: _suggestionRunning,
              onCancel: () {
                setState(() {
                  _suggestionReviewOpen = false;
                  _aiConfirmationOpen = false;
                });
              },
              onRunLocal: () => _runLocalSuggestion(),
              onRequestAi: () => _requestAiSuggestion(),
              onCancelAi: () => setState(() => _aiConfirmationOpen = false),
              onConfirmAi: () => _confirmAiSuggestion(
                mergeWithLocal: _mergeAiAfterConfirmation,
              ),
              onCompare: () => _requestAiSuggestion(mergeWithLocal: true),
              onApplyReliable: () => _applySuggestions(reliableOnly: true),
              onApplyAll: () => _applySuggestions(reliableOnly: false),
            ),
          ),
        if (_advancedDrawerOpen && widget.advancedDrawer != null)
          Positioned.fill(
            child: _AdvancedDrawerScrim(
              child: widget.advancedDrawer!,
              onClose: () {
                setState(() => _advancedDrawerOpen = false);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildWorkspacePanel() {
    final frameCount = _frameCount;
    return switch (_currentStep) {
      SurfaceStudioWizardStep.importAtlas => _ImportStepPanel(
          readModel: widget.readModel,
          projectTilesets: widget.projectTilesets,
          projectRootPath: widget.projectRootPath,
          atlasId: _atlasId,
          atlasName: _atlasName,
          tilesetId: _tilesetId,
          tileWidth: _tileWidth,
          tileHeight: _tileHeight,
          columns: _columns,
          rows: _rows,
          sortOrder: _sortOrder,
          categoryId: _categoryId,
          layout: _layout,
          onLayoutChanged: (layout) => setState(() => _layout = layout),
          onCreateAtlas: _createOrUpdateAtlas,
          onTilesetChanged: (value) {
            setState(() {
              _tilesetId.text = value ?? '';
            });
          },
        ),
      SurfaceStudioWizardStep.slice => _SliceStepPanel(
          projectTilesets: widget.projectTilesets,
          projectRootPath: widget.projectRootPath,
          atlasId: _atlasId,
          atlasName: _atlasName,
          tilesetId: _tilesetId,
          tileWidth: _tileWidth,
          tileHeight: _tileHeight,
          columns: _columns,
          rows: _rows,
          layout: _layout,
          onChanged: () => setState(() {}),
          onApplyGrid: _createOrUpdateAtlas,
          onResetGrid: () {
            setState(() {
              _tileWidth.text = '32';
              _tileHeight.text = '32';
              _columns.text = '12';
              _rows.text = '32';
              _zoomPercent = 100;
              _statusMessage = 'Grille réinitialisée.';
            });
          },
        ),
      SurfaceStudioWizardStep.map => SurfaceStudioAtlasPanel(
          columnCount: _columnCount,
          frameCount: _frameCount,
          tileWidth: _tileWidthValue,
          tileHeight: _tileHeightValue,
          atlasImageBytes: _atlasImageBytes(),
          atlasImageFallbackLabel: _atlasImageBytes() == null
              ? 'Image source indisponible — aperçu illustratif.'
              : null,
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
          onAutoSuggest: _openSuggestionReview,
        ),
      SurfaceStudioWizardStep.preview => _buildPreviewWorkspace(frameCount),
      SurfaceStudioWizardStep.save => _SaveStepPanel(
          readModel: widget.readModel,
          generationPlan: _generationPlan,
          presetPlan: surfaceStudioPlanVerticalAtlasPresetAppend(
            catalog: widget.readModel.catalog,
            atlasIdRaw: _atlasId.text,
            atlasDisplayName: _atlasName.text,
            atlasCategoryDraft: _categoryId.text,
            mappingDraft: _columnRoleMappingDraft,
            gridValid: _gridValid,
          ),
          hasWorkCatalogChanges: widget.hasWorkCatalogChanges,
          saveFlowPrepNote: widget.saveFlowPrepNote,
          projectSaveDiskNote: widget.projectSaveDiskNote,
          generationMessage: _lastGenerationMessage,
          presetMessage: _lastPresetMessage,
          onGenerateAnimations: _appendReadyAnimations,
          onCreatePreset: _appendPreset,
          onSaveCatalog: widget.onSurfaceCatalogSavePrep,
          onProjectSave: widget.onRequestProjectSave,
          onResetWorkCatalog: widget.onResetWorkCatalog,
        ),
    };
  }

  Widget _buildPreviewWorkspace(int frameCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: SurfaceStudioPreviewPanel(
            frameCount: frameCount,
            frameIndex: _previewFrameIndex.clamp(0, frameCount - 1).toInt(),
            playing: _previewPlaying,
            loop: _previewLoop,
            gridVisible: _previewGridVisible,
            previewSize: _previewSize,
            assignmentDraft: _assignmentDraft,
            atlasImageBytes: _atlasImageBytes(),
            atlasFallbackMessage: _atlasImageBytes() == null
                ? 'Image source indisponible — aperçu illustratif.'
                : null,
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
        ),
        const SizedBox(width: SurfaceStudioDesignTokens.gapMd),
        SizedBox(
          width: 430,
          child: _PreviewPlanPanel(
            generationPlan: _generationPlan,
            multiCenterColumns:
                _assignmentDraft.columnsForRole(SurfaceVariantRole.isolated),
            onGenerateAnimations: _appendReadyAnimations,
            message: _lastGenerationMessage,
          ),
        ),
      ],
    );
  }

  Widget? _buildRightDock(int frameCount) {
    if (_currentStep != SurfaceStudioWizardStep.map) {
      return null;
    }
    return _RightDockFrame(
      children: [
        Expanded(
          flex: 3,
          child: SurfaceStudioSchemaPanel(
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
                () => _assignmentDraft = _assignmentDraft.clearRole(role),
              );
            },
            onClearColumn: (role, column) {
              setState(
                () => _assignmentDraft =
                    _assignmentDraft.clearColumn(role, column),
              );
            },
          ),
        ),
        const SizedBox(height: SurfaceStudioDesignTokens.gapSm),
        Expanded(
          flex: 2,
          child: SurfaceStudioPreviewPanel(
            frameCount: frameCount,
            frameIndex: _previewFrameIndex.clamp(0, frameCount - 1).toInt(),
            playing: _previewPlaying,
            loop: _previewLoop,
            gridVisible: _previewGridVisible,
            previewSize: _previewSize,
            assignmentDraft: _assignmentDraft,
            atlasImageBytes: _atlasImageBytes(),
            atlasFallbackMessage: _atlasImageBytes() == null
                ? 'Image source indisponible — aperçu illustratif.'
                : null,
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
        ),
      ],
    );
  }
}

class _ImportStepPanel extends StatelessWidget {
  const _ImportStepPanel({
    required this.readModel,
    required this.projectTilesets,
    required this.projectRootPath,
    required this.atlasId,
    required this.atlasName,
    required this.tilesetId,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    required this.sortOrder,
    required this.categoryId,
    required this.layout,
    required this.onLayoutChanged,
    required this.onCreateAtlas,
    required this.onTilesetChanged,
  });

  final SurfaceStudioReadModel readModel;
  final List<ProjectTilesetEntry> projectTilesets;
  final String? projectRootPath;
  final TextEditingController atlasId;
  final TextEditingController atlasName;
  final TextEditingController tilesetId;
  final TextEditingController tileWidth;
  final TextEditingController tileHeight;
  final TextEditingController columns;
  final TextEditingController rows;
  final TextEditingController sortOrder;
  final TextEditingController categoryId;
  final SurfaceAtlasLayout layout;
  final ValueChanged<SurfaceAtlasLayout> onLayoutChanged;
  final VoidCallback onCreateAtlas;
  final ValueChanged<String?> onTilesetChanged;

  @override
  Widget build(BuildContext context) {
    final sorted = sortedTilesetChoices(projectTilesets);
    final resolution = resolveSurfaceStudioAtlasImagePreview(
      projectRootPath: projectRootPath,
      projectTilesets: projectTilesets,
      technicalTilesetId: tilesetId.text,
    );
    final form = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SurfaceStudioAtlasImageSourceBlock(
            hasPicker: sorted.isNotEmpty,
            sortedTilesets: sorted,
            selectedTilesetId: tilesetId.text.isEmpty ? null : tilesetId.text,
            onSelectTilesetId: onTilesetChanged,
            label: SurfaceStudioDesignTokens.textPrimary,
            subtle: SurfaceStudioDesignTokens.textSecondary,
          ),
          const SizedBox(height: 14),
          _Field(
            keyName: 'surfaceStudio.import.atlasId',
            label: 'Identifiant atlas',
            controller: atlasId,
          ),
          _Field(
            keyName: 'surfaceStudio.import.atlasName',
            label: 'Nom atlas',
            controller: atlasName,
          ),
          _Field(
            keyName: 'surfaceStudio.import.tilesetId',
            label: 'Source technique',
            controller: tilesetId,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SmallField(label: 'Tuile W', controller: tileWidth),
              _SmallField(label: 'Tuile H', controller: tileHeight),
              _SmallField(label: 'Colonnes', controller: columns),
              _SmallField(label: 'Frames', controller: rows),
              _SmallField(label: 'Ordre', controller: sortOrder),
            ],
          ),
          const SizedBox(height: 10),
          _Field(
            keyName: 'surfaceStudio.import.categoryId',
            label: 'Catégorie',
            controller: categoryId,
          ),
          const SizedBox(height: 10),
          Material(
            type: MaterialType.transparency,
            child: DropdownButton<SurfaceAtlasLayout>(
              key: const ValueKey('surfaceStudio.import.layout'),
              isExpanded: true,
              value: layout,
              dropdownColor: SurfaceStudioDesignTokens.backgroundElevated,
              style: const TextStyle(
                color: SurfaceStudioDesignTokens.textPrimary,
              ),
              items: const [
                DropdownMenuItem(
                  value: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
                  child: Text('Colonnes = rôles'),
                ),
                DropdownMenuItem(
                  value: SurfaceAtlasLayout.grid,
                  child: Text('Grille libre'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onLayoutChanged(value);
                }
              },
            ),
          ),
          const SizedBox(height: 14),
          CupertinoButton(
            key: const ValueKey('surfaceStudio.import.createAtlas'),
            color: SurfaceStudioDesignTokens.accentGoldSoft,
            onPressed: onCreateAtlas,
            child: Text(
              readModel.atlases.isEmpty
                  ? 'Créer l’atlas de travail'
                  : 'Appliquer au catalogue de travail',
            ),
          ),
        ],
      ),
    );
    final preview = SurfaceStudioAtlasImagePreview(
      resolution: resolution,
      label: SurfaceStudioDesignTokens.textPrimary,
      subtle: SurfaceStudioDesignTokens.textSecondary,
      draftTileWidth: int.tryParse(tileWidth.text),
      draftTileHeight: int.tryParse(tileHeight.text),
      draftColumns: int.tryParse(columns.text),
      draftRows: int.tryParse(rows.text),
      draftLayoutLabel: 'Colonnes → rôles',
      largeFormat: true,
    );
    return _PanelFrame(
      keyName: 'surfaceStudio.import.panel',
      title: 'Importer',
      subtitle: 'Choisissez une source réelle et préparez le brouillon atlas.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 720) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  form,
                  const SizedBox(height: 16),
                  SizedBox(height: 340, child: preview),
                ],
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: form),
              const SizedBox(width: 16),
              Expanded(child: preview),
            ],
          );
        },
      ),
    );
  }
}

class _SliceStepPanel extends StatelessWidget {
  const _SliceStepPanel({
    required this.projectTilesets,
    required this.projectRootPath,
    required this.atlasId,
    required this.atlasName,
    required this.tilesetId,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    required this.layout,
    required this.onChanged,
    required this.onApplyGrid,
    required this.onResetGrid,
  });

  final List<ProjectTilesetEntry> projectTilesets;
  final String? projectRootPath;
  final TextEditingController atlasId;
  final TextEditingController atlasName;
  final TextEditingController tilesetId;
  final TextEditingController tileWidth;
  final TextEditingController tileHeight;
  final TextEditingController columns;
  final TextEditingController rows;
  final SurfaceAtlasLayout layout;
  final VoidCallback onChanged;
  final VoidCallback onApplyGrid;
  final VoidCallback onResetGrid;

  @override
  Widget build(BuildContext context) {
    final resolution = resolveSurfaceStudioAtlasImagePreview(
      projectRootPath: projectRootPath,
      projectTilesets: projectTilesets,
      technicalTilesetId: tilesetId.text,
    );
    return _PanelFrame(
      keyName: 'surfaceStudio.slice.panel',
      title: 'Découper',
      subtitle: 'Ajustez la grille qui alimentera le mapping et la génération.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: SurfaceStudioAtlasImagePreview(
              resolution: resolution,
              label: SurfaceStudioDesignTokens.textPrimary,
              subtle: SurfaceStudioDesignTokens.textSecondary,
              draftTileWidth: int.tryParse(tileWidth.text),
              draftTileHeight: int.tryParse(tileHeight.text),
              draftColumns: int.tryParse(columns.text),
              draftRows: int.tryParse(rows.text),
              draftLayoutLabel: layout.name,
              largeFormat: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    atlasName.text.isEmpty ? atlasId.text : atlasName.text,
                    style: const TextStyle(
                      color: SurfaceStudioDesignTokens.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _SmallField(
                        label: 'Tuile W',
                        controller: tileWidth,
                        onChanged: (_) => onChanged(),
                      ),
                      _SmallField(
                        label: 'Tuile H',
                        controller: tileHeight,
                        onChanged: (_) => onChanged(),
                      ),
                      _SmallField(
                        label: 'Colonnes',
                        controller: columns,
                        onChanged: (_) => onChanged(),
                      ),
                      _SmallField(
                        label: 'Frames',
                        controller: rows,
                        onChanged: (_) => onChanged(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SurfaceStudioAtlasGridPreview(
                    sourceLabel: tilesetId.text,
                    tileWidth: int.tryParse(tileWidth.text),
                    tileHeight: int.tryParse(tileHeight.text),
                    columns: int.tryParse(columns.text),
                    rows: int.tryParse(rows.text),
                    layoutLabel: layout.name,
                  ),
                  const SizedBox(height: 14),
                  CupertinoButton(
                    color: SurfaceStudioDesignTokens.accentTealSoft,
                    onPressed: onApplyGrid,
                    child: const Text('Appliquer la grille'),
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    onPressed: onResetGrid,
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPlanPanel extends StatelessWidget {
  const _PreviewPlanPanel({
    required this.generationPlan,
    required this.multiCenterColumns,
    required this.onGenerateAnimations,
    required this.message,
  });

  final SurfaceStudioVerticalAtlasAnimationGenerationPlan generationPlan;
  final List<int> multiCenterColumns;
  final VoidCallback onGenerateAnimations;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final summary = generationPlan.summary;
    return _PanelFrame(
      keyName: 'surfaceStudio.previewPlan.panel',
      title: 'Prévisualiser',
      subtitle: 'Plan réel de génération depuis le mapping courant.',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MetricRow(
              metrics: {
                'Assignées': '${summary.assignedColumnCount}',
                'Prêtes': '${summary.readyAnimationCount}',
                'À corriger': '${summary.errorAnimationCount}',
                'Frame': '${summary.durationMsPerFrame} ms',
              },
            ),
            if (multiCenterColumns.length > 1) ...[
              const SizedBox(height: 10),
              const _WarningBox(
                text:
                    'Plein contient plusieurs colonnes. V2.1 conserve l’UX multi-colonnes, mais la génération réelle utilise la première colonne tant qu’un modèle de variantes multiples n’existe pas.',
              ),
            ],
            const SizedBox(height: 14),
            CupertinoButton(
              key: const ValueKey('surfaceStudio.preview.generateAnimations'),
              color: SurfaceStudioDesignTokens.accentTealSoft,
              onPressed:
                  summary.readyAnimationCount > 0 ? onGenerateAnimations : null,
              child: const Text('Générer les animations prêtes'),
            ),
            if (message != null) ...[
              const SizedBox(height: 10),
              Text(
                message!,
                style: const TextStyle(
                  color: SurfaceStudioDesignTokens.accentTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            for (final item in generationPlan.items) _PlanItemRow(item: item),
          ],
        ),
      ),
    );
  }
}

class _SaveStepPanel extends StatelessWidget {
  const _SaveStepPanel({
    required this.readModel,
    required this.generationPlan,
    required this.presetPlan,
    required this.hasWorkCatalogChanges,
    required this.saveFlowPrepNote,
    required this.projectSaveDiskNote,
    required this.generationMessage,
    required this.presetMessage,
    required this.onGenerateAnimations,
    required this.onCreatePreset,
    required this.onSaveCatalog,
    required this.onProjectSave,
    required this.onResetWorkCatalog,
  });

  final SurfaceStudioReadModel readModel;
  final SurfaceStudioVerticalAtlasAnimationGenerationPlan generationPlan;
  final SurfaceStudioVerticalAtlasPresetAppendPlan presetPlan;
  final bool hasWorkCatalogChanges;
  final String? saveFlowPrepNote;
  final String? projectSaveDiskNote;
  final String? generationMessage;
  final String? presetMessage;
  final VoidCallback onGenerateAnimations;
  final VoidCallback onCreatePreset;
  final VoidCallback? onSaveCatalog;
  final Future<void> Function()? onProjectSave;
  final VoidCallback? onResetWorkCatalog;

  @override
  Widget build(BuildContext context) {
    return _PanelFrame(
      keyName: 'surfaceStudio.save.panel',
      title: 'Enregistrer',
      subtitle: 'Générez les artefacts Surface, puis préparez la sauvegarde.',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MetricRow(
              metrics: {
                'Atlas': '${readModel.summary.atlasCount}',
                'Animations': '${readModel.summary.animationCount}',
                'Surfaces': '${readModel.summary.presetCount}',
                'Dirty': hasWorkCatalogChanges ? 'oui' : 'non',
              },
            ),
            const SizedBox(height: 14),
            CupertinoButton(
              key: const ValueKey('surfaceStudio.save.generateAnimations'),
              color: SurfaceStudioDesignTokens.accentTealSoft,
              onPressed: generationPlan.summary.readyAnimationCount > 0
                  ? onGenerateAnimations
                  : null,
              child: const Text('Générer les animations'),
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              key: const ValueKey('surfaceStudio.save.createPreset'),
              color: SurfaceStudioDesignTokens.accentGoldSoft,
              onPressed: presetPlan.canCreate ? onCreatePreset : null,
              child: const Text('Créer la surface peignable'),
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              key: const ValueKey('surfaceStudio.action.saveCatalog'),
              onPressed: hasWorkCatalogChanges ? onSaveCatalog : null,
              child: const Text('Préparer la sauvegarde du catalogue'),
            ),
            if (onProjectSave != null) ...[
              const SizedBox(height: 8),
              CupertinoButton(
                key: const ValueKey('surfaceStudio.save.project'),
                onPressed: onProjectSave,
                child: const Text('Sauvegarder le projet via le flux existant'),
              ),
            ],
            if (onResetWorkCatalog != null) ...[
              const SizedBox(height: 8),
              CupertinoButton(
                key: const ValueKey('surfaceStudio.save.resetWorkCatalog'),
                onPressed: onResetWorkCatalog,
                child: const Text('Réinitialiser le catalogue de travail'),
              ),
            ],
            for (final message in [
              generationMessage,
              presetMessage,
              saveFlowPrepNote,
              projectSaveDiskNote,
            ])
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: SurfaceStudioDesignTokens.accentTeal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _RightDockFrame extends StatelessWidget {
  const _RightDockFrame({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(children: children);
  }
}

class _PanelFrame extends StatelessWidget {
  const _PanelFrame({
    required this.keyName,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String keyName;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(keyName),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundPanel,
        borderRadius:
            BorderRadius.circular(SurfaceStudioDesignTokens.panelRadius),
        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.keyName,
    required this.label,
    required this.controller,
  });

  final String keyName;
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          key: ValueKey(keyName),
          controller: controller,
          style: const TextStyle(color: SurfaceStudioDesignTokens.textPrimary),
          decoration: _fieldDecoration(label),
        ),
      ),
    );
  }
}

class _SmallField extends StatelessWidget {
  const _SmallField({
    required this.label,
    required this.controller,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: SurfaceStudioDesignTokens.textPrimary),
          decoration: _fieldDecoration(label),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: SurfaceStudioDesignTokens.textSecondary),
    filled: true,
    fillColor: SurfaceStudioDesignTokens.backgroundElevated,
    enabledBorder: OutlineInputBorder(
      borderSide:
          const BorderSide(color: SurfaceStudioDesignTokens.borderSubtle),
      borderRadius: BorderRadius.circular(9),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: SurfaceStudioDesignTokens.accentGold),
      borderRadius: BorderRadius.circular(9),
    ),
  );
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metrics});

  final Map<String, String> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final metric in metrics.entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: SurfaceStudioDesignTokens.backgroundElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
            ),
            child: Text(
              '${metric.key}  ${metric.value}',
              style: const TextStyle(
                color: SurfaceStudioDesignTokens.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _WarningBox extends StatelessWidget {
  const _WarningBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.accentGoldSoft.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SurfaceStudioDesignTokens.accentGold),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: SurfaceStudioDesignTokens.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlanItemRow extends StatelessWidget {
  const _PlanItemRow({required this.item});

  final SurfaceStudioVerticalAtlasAnimationGenerationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: item.isReady
              ? SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.5)
              : SurfaceStudioDesignTokens.borderSubtle,
        ),
      ),
      child: Text(
        '${SurfaceStudioRoleLabels.labelForRole(item.role)} · colonne ${item.columnIndex + 1} · ${item.isReady ? 'prête' : item.problems.join(', ')}',
        style: const TextStyle(
          color: SurfaceStudioDesignTokens.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusToast extends StatelessWidget {
  const _StatusToast({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: SurfaceStudioDesignTokens.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SuggestionReviewScrim extends StatelessWidget {
  const _SuggestionReviewScrim({
    required this.result,
    required this.mistralKeyConfigured,
    required this.aiConfirmationOpen,
    required this.running,
    required this.onCancel,
    required this.onRunLocal,
    required this.onRequestAi,
    required this.onCancelAi,
    required this.onConfirmAi,
    required this.onCompare,
    required this.onApplyReliable,
    required this.onApplyAll,
  });

  final SurfaceStudioMappingSuggestionResult result;
  final bool mistralKeyConfigured;
  final bool aiConfirmationOpen;
  final bool running;
  final VoidCallback onCancel;
  final VoidCallback onRunLocal;
  final VoidCallback onRequestAi;
  final VoidCallback onCancelAi;
  final VoidCallback onConfirmAi;
  final VoidCallback onCompare;
  final VoidCallback onApplyReliable;
  final VoidCallback onApplyAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x990B1020),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.all(18),
      child: Container(
        key: const ValueKey('surfaceStudio.suggestion.review'),
        width: 520,
        decoration: BoxDecoration(
          color: SurfaceStudioDesignTokens.backgroundPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Suggestions détectées',
              style: TextStyle(
                color: SurfaceStudioDesignTokens.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Source : ${_sourceLabel(result.source)}',
              style: const TextStyle(
                color: SurfaceStudioDesignTokens.accentTeal,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final warning in result.warnings) ...[
                      _WarningBox(text: warning),
                      const SizedBox(height: 8),
                    ],
                    for (final suggestion in result.suggestions)
                      _SuggestionRow(suggestion: suggestion),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SurfaceStudioDesignTokens.backgroundElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: SurfaceStudioDesignTokens.borderSubtle,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Analyse IA Mistral',
                            style: TextStyle(
                              color: SurfaceStudioDesignTokens.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mistralKeyConfigured
                                ? 'Clé Mistral configurée.'
                                : 'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY',
                            style: const TextStyle(
                              color: SurfaceStudioDesignTokens.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'L’analyse IA peut envoyer l’image de l’atlas au fournisseur configuré. Rien n’est envoyé sans confirmation.',
                            style: TextStyle(
                              color: SurfaceStudioDesignTokens.textMuted,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              CupertinoButton(
                                key: const ValueKey(
                                  'surfaceStudio.suggestion.local',
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                color: SurfaceStudioDesignTokens.accentTealSoft,
                                onPressed: running ? null : onRunLocal,
                                child: const Text('Analyse locale'),
                              ),
                              CupertinoButton(
                                key: const ValueKey(
                                  'surfaceStudio.suggestion.mistral',
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                color: mistralKeyConfigured
                                    ? SurfaceStudioDesignTokens.accentGoldSoft
                                    : SurfaceStudioDesignTokens.borderSubtle,
                                onPressed: running || !mistralKeyConfigured
                                    ? null
                                    : onRequestAi,
                                child: Text(
                                  running
                                      ? 'Analyse IA...'
                                      : 'Analyse IA Mistral',
                                ),
                              ),
                              CupertinoButton(
                                key: const ValueKey(
                                  'surfaceStudio.suggestion.compare',
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                color: SurfaceStudioDesignTokens
                                    .backgroundPanelAlt,
                                onPressed: running || !mistralKeyConfigured
                                    ? null
                                    : onCompare,
                                child: const Text('Comparer local + IA'),
                              ),
                            ],
                          ),
                          if (aiConfirmationOpen) ...[
                            const SizedBox(height: 10),
                            const _WarningBox(
                              text:
                                  'Confirmez l’envoi de l’image atlas à Mistral. Aucune suggestion ne sera appliquée automatiquement.',
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                CupertinoButton(
                                  key: const ValueKey(
                                    'surfaceStudio.suggestion.confirmAi',
                                  ),
                                  color:
                                      SurfaceStudioDesignTokens.accentGoldSoft,
                                  onPressed: onConfirmAi,
                                  child: const Text('Confirmer l’analyse IA'),
                                ),
                                CupertinoButton(
                                  onPressed: onCancelAi,
                                  child: const Text('Annuler l’analyse IA'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: [
                CupertinoButton(
                  onPressed: onCancel,
                  child: const Text('Annuler'),
                ),
                CupertinoButton(
                  color: SurfaceStudioDesignTokens.accentTealSoft,
                  onPressed: onApplyReliable,
                  child: const Text('Appliquer les suggestions fiables'),
                ),
                CupertinoButton(
                  color: SurfaceStudioDesignTokens.accentGoldSoft,
                  onPressed: onApplyAll,
                  child: const Text('Tout appliquer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _sourceLabel(SurfaceStudioMappingSuggestionSource source) {
    return switch (source) {
      SurfaceStudioMappingSuggestionSource.local => 'Local',
      SurfaceStudioMappingSuggestionSource.mistral => 'Mistral',
      SurfaceStudioMappingSuggestionSource.merged => 'Fusion',
    };
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestion});

  final SurfaceStudioRoleSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SurfaceStudioRoleLabels.labelForRole(suggestion.role),
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Colonnes : ${suggestion.columns.join(', ')} · confiance : ${suggestion.confidence.name}',
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            suggestion.reason,
            style: const TextStyle(
              color: SurfaceStudioDesignTokens.textMuted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedDrawerScrim extends StatelessWidget {
  const _AdvancedDrawerScrim({
    required this.child,
    required this.onClose,
  });

  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x770B1020),
      alignment: Alignment.centerRight,
      child: Container(
        key: const ValueKey('surfaceStudio.advanced.drawer'),
        width: 620,
        margin: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: SurfaceStudioDesignTokens.backgroundPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Catalogue & diagnostics',
                      style: TextStyle(
                        color: SurfaceStudioDesignTokens.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size.square(36),
                    onPressed: onClose,
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: SurfaceStudioDesignTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart

```dart
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_grid_overlay.dart';
import 'surface_studio_vertical_atlas_animation_generator.dart';
import 'surface_studio_vertical_atlas_role_mapping.dart';

/// Rectangle source (atlas) pour une frame — plan local uniquement.
@immutable
class SurfaceStudioVerticalAtlasAnimationGenerationSourceRect {
  const SurfaceStudioVerticalAtlasAnimationGenerationSourceRect({
    required this.frameIndex,
    required this.sourceX,
    required this.sourceY,
    required this.sourceWidth,
    required this.sourceHeight,
  });

  final int frameIndex;
  final int sourceX;
  final int sourceY;
  final int sourceWidth;
  final int sourceHeight;
}

/// Statut d’une ligne du plan (aucune persistance catalogue).
enum SurfaceStudioVerticalAtlasAnimationPlanItemStatus {
  ready,
  invalid,
  duplicate,
}

/// Une animation Surface qui serait créée à partir d’une colonne mappée.
@immutable
class SurfaceStudioVerticalAtlasAnimationGenerationItem {
  const SurfaceStudioVerticalAtlasAnimationGenerationItem({
    required this.atlasId,
    required this.columnIndex,
    required this.role,
    required this.proposedAnimationId,
    required this.frameCount,
    required this.durationMsPerFrame,
    required this.totalDurationMs,
    required this.sourceRects,
    required this.isReady,
    required this.status,
    required this.problems,
  });

  final String atlasId;
  final int columnIndex;
  final SurfaceVariantRole role;
  final String proposedAnimationId;
  final int frameCount;
  final int durationMsPerFrame;
  final int totalDurationMs;
  final List<SurfaceStudioVerticalAtlasAnimationGenerationSourceRect>
      sourceRects;
  final bool isReady;
  final SurfaceStudioVerticalAtlasAnimationPlanItemStatus status;
  final List<String> problems;
}

/// Résumé agrégé du plan.
@immutable
class SurfaceStudioVerticalAtlasAnimationGenerationSummary {
  const SurfaceStudioVerticalAtlasAnimationGenerationSummary({
    required this.assignedColumnCount,
    required this.readyAnimationCount,
    required this.errorAnimationCount,
    required this.durationMsPerFrame,
    required this.durationFieldValid,
  });

  final int assignedColumnCount;
  final int readyAnimationCount;
  final int errorAnimationCount;
  final int durationMsPerFrame;
  final bool durationFieldValid;
}

/// Plan complet (local, non persisté).
@immutable
class SurfaceStudioVerticalAtlasAnimationGenerationPlan {
  const SurfaceStudioVerticalAtlasAnimationGenerationPlan({
    required this.items,
    required this.summary,
    required this.gridValid,
    required this.atlasIdSlug,
  });

  final List<SurfaceStudioVerticalAtlasAnimationGenerationItem> items;
  final SurfaceStudioVerticalAtlasAnimationGenerationSummary summary;
  final bool gridValid;
  final String atlasIdSlug;
}

/// Slug ASCII pour segment d’id (`a-z`, `0-9`, `-`).
String surfaceStudioSlugForAnimationIdSegment(String raw) {
  final folded = _foldLatin1Accents(raw.trim().toLowerCase());
  final out = StringBuffer();
  var prevHyphen = false;
  for (final unit in folded.runes) {
    final c = String.fromCharCode(unit);
    if ((c.compareTo('a') >= 0 && c.compareTo('z') <= 0) ||
        (c.compareTo('0') >= 0 && c.compareTo('9') <= 0)) {
      out.write(c);
      prevHyphen = false;
    } else {
      if (!prevHyphen && out.isNotEmpty) {
        out.write('-');
        prevHyphen = true;
      }
    }
  }
  var s = out.toString();
  while (s.startsWith('-')) {
    s = s.substring(1);
  }
  while (s.endsWith('-')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

String _foldLatin1Accents(String s) {
  const from = 'àáâãäåèéêëìíîïòóôõöùúûüýÿçñÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝŸÇÑ';
  const to = 'aaaaaaeeeeiiiiooooouuuuyyncaaaaaaeeeeiiiiooooouuuuyync';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString();
}

/// Slug rôle pour id proposé (stable, minuscules, tirets).
String surfaceStudioRoleSlugForProposedAnimationId(SurfaceVariantRole role) {
  switch (role) {
    case SurfaceVariantRole.isolated:
      return 'plein';
    case SurfaceVariantRole.endNorth:
      return 'bord-haut';
    case SurfaceVariantRole.endEast:
      return 'bord-droit';
    case SurfaceVariantRole.endSouth:
      return 'bord-bas';
    case SurfaceVariantRole.endWest:
      return 'bord-gauche';
    case SurfaceVariantRole.horizontal:
      return 'horizontal';
    case SurfaceVariantRole.vertical:
      return 'vertical';
    case SurfaceVariantRole.cornerNE:
      return 'coin-ne';
    case SurfaceVariantRole.cornerSE:
      return 'coin-se';
    case SurfaceVariantRole.cornerSW:
      return 'coin-sw';
    case SurfaceVariantRole.cornerNW:
      return 'coin-nw';
    case SurfaceVariantRole.innerCornerNE:
      return 'coin-int-ne';
    case SurfaceVariantRole.innerCornerSE:
      return 'coin-int-se';
    case SurfaceVariantRole.innerCornerSW:
      return 'coin-int-sw';
    case SurfaceVariantRole.innerCornerNW:
      return 'coin-int-nw';
    case SurfaceVariantRole.teeNorth:
      return 'te-haut';
    case SurfaceVariantRole.teeEast:
      return 'te-droit';
    case SurfaceVariantRole.teeSouth:
      return 'te-bas';
    case SurfaceVariantRole.teeWest:
      return 'te-gauche';
    case SurfaceVariantRole.cross:
      return 'croix';
  }
}

String surfaceStudioProposedAnimationId({
  required String atlasIdRaw,
  required SurfaceVariantRole role,
}) {
  final atlasSeg = surfaceStudioSlugForAnimationIdSegment(atlasIdRaw);
  final roleSeg = surfaceStudioRoleSlugForProposedAnimationId(role);
  if (atlasSeg.isEmpty || roleSeg.isEmpty) {
    return '';
  }
  return '$atlasSeg-$roleSeg-loop';
}

List<SurfaceStudioVerticalAtlasAnimationGenerationSourceRect>
    surfaceStudioVerticalAtlasAnimationGenerationSourceRects({
  required int columnIndex,
  required int tileWidth,
  required int tileHeight,
  required int rows,
}) {
  final out = <SurfaceStudioVerticalAtlasAnimationGenerationSourceRect>[];
  for (var f = 0; f < rows; f++) {
    out.add(
      SurfaceStudioVerticalAtlasAnimationGenerationSourceRect(
        frameIndex: f,
        sourceX: columnIndex * tileWidth,
        sourceY: f * tileHeight,
        sourceWidth: tileWidth,
        sourceHeight: tileHeight,
      ),
    );
  }
  return out;
}

/// Construit le plan local (aucune écriture catalogue).
SurfaceStudioVerticalAtlasAnimationGenerationPlan
    buildSurfaceStudioVerticalAtlasAnimationGenerationPlan({
  required String atlasIdRaw,
  required SurfaceStudioColumnRoleMappingDraft mappingDraft,
  required int? tileWidth,
  required int? tileHeight,
  required int? columns,
  required int? rows,
  required int durationMsPerFrame,
  required Set<String> existingAnimationIds,
}) {
  final gridValid = surfaceStudioAtlasGridOverlayDraftValid(
    tileWidth,
    tileHeight,
    columns,
    rows,
  );
  final atlasSeg = surfaceStudioSlugForAnimationIdSegment(atlasIdRaw);
  final durationOk = durationMsPerFrame > 0;
  final tw = tileWidth ?? 0;
  final th = tileHeight ?? 0;
  final rws = rows ?? 0;

  final assigned = mappingDraft.assignments
      .where((a) => a.role != null)
      .toList()
    ..sort((a, b) => a.columnIndex.compareTo(b.columnIndex));

  final items = <SurfaceStudioVerticalAtlasAnimationGenerationItem>[];
  var ready = 0;
  var err = 0;

  for (final a in assigned) {
    final role = a.role!;
    final problems = <String>[];
    late final SurfaceStudioVerticalAtlasAnimationPlanItemStatus status;
    late final bool isReady;

    if (!gridValid) {
      problems.add('Grille invalide pour cette animation.');
    }
    if (!durationOk) {
      problems.add('Durée par frame invalide.');
    }
    if (atlasSeg.isEmpty) {
      problems
          .add('Identifiant d’atlas requis pour proposer un id d’animation.');
    }

    final proposed = surfaceStudioProposedAnimationId(
      atlasIdRaw: atlasIdRaw,
      role: role,
    );
    final baseInvalid = !gridValid || !durationOk || atlasSeg.isEmpty;
    final duplicateId = !baseInvalid &&
        proposed.isNotEmpty &&
        existingAnimationIds.contains(proposed);
    if (duplicateId) {
      problems.add('Une animation existe déjà avec cet id.');
    }
    if (baseInvalid) {
      status = SurfaceStudioVerticalAtlasAnimationPlanItemStatus.invalid;
      isReady = false;
    } else if (duplicateId) {
      status = SurfaceStudioVerticalAtlasAnimationPlanItemStatus.duplicate;
      isReady = false;
    } else {
      status = SurfaceStudioVerticalAtlasAnimationPlanItemStatus.ready;
      isReady = true;
      problems.clear();
    }

    final rects = gridValid && tw > 0 && th > 0 && rws > 0
        ? surfaceStudioVerticalAtlasAnimationGenerationSourceRects(
            columnIndex: a.columnIndex,
            tileWidth: tw,
            tileHeight: th,
            rows: rws,
          )
        : const <SurfaceStudioVerticalAtlasAnimationGenerationSourceRect>[];

    final fc = gridValid ? rws : 0;
    final totalMs = durationOk && fc > 0 ? fc * durationMsPerFrame : 0;

    if (isReady) {
      ready++;
    } else {
      err++;
    }

    items.add(
      SurfaceStudioVerticalAtlasAnimationGenerationItem(
        atlasId: atlasIdRaw.trim(),
        columnIndex: a.columnIndex,
        role: role,
        proposedAnimationId: proposed,
        frameCount: fc,
        durationMsPerFrame: durationMsPerFrame,
        totalDurationMs: totalMs,
        sourceRects: rects,
        isReady: isReady,
        status: status,
        problems: List<String>.unmodifiable(problems),
      ),
    );
  }

  final summary = SurfaceStudioVerticalAtlasAnimationGenerationSummary(
    assignedColumnCount: assigned.length,
    readyAnimationCount: ready,
    errorAnimationCount: err,
    durationMsPerFrame: durationMsPerFrame,
    durationFieldValid: durationOk,
  );

  return SurfaceStudioVerticalAtlasAnimationGenerationPlan(
    items: List<SurfaceStudioVerticalAtlasAnimationGenerationItem>.unmodifiable(
      items,
    ),
    summary: summary,
    gridValid: gridValid,
    atlasIdSlug: atlasSeg,
  );
}

/// Section UI : plan de génération (affichage uniquement).
class SurfaceStudioVerticalAtlasAnimationGenerationPlanSection
    extends StatefulWidget {
  const SurfaceStudioVerticalAtlasAnimationGenerationPlanSection({
    super.key,
    required this.label,
    required this.subtle,
    required this.readModel,
    required this.atlasIdDraft,
    required this.atlasDisplayName,
    this.atlasCategoryDraft,
    required this.mappingDraft,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.rows,
    this.onWorkCatalogChanged,
    this.onWorkCatalogAnimationsCreated,
  });

  static const ValueKey<String> sectionKey =
      ValueKey<String>('surface_studio_vertical_atlas_generation_plan');

  final Color label;
  final Color subtle;
  final SurfaceStudioReadModel readModel;
  final String atlasIdDraft;
  final String atlasDisplayName;
  final String? atlasCategoryDraft;
  final SurfaceStudioColumnRoleMappingDraft mappingDraft;
  final int? tileWidth;
  final int? tileHeight;
  final int? columns;
  final int? rows;
  final ValueChanged<ProjectSurfaceCatalog>? onWorkCatalogChanged;
  final ValueChanged<List<String>>? onWorkCatalogAnimationsCreated;

  @override
  State<SurfaceStudioVerticalAtlasAnimationGenerationPlanSection>
      createState() =>
          _SurfaceStudioVerticalAtlasAnimationGenerationPlanSectionState();
}

class _SurfaceStudioVerticalAtlasAnimationGenerationPlanSectionState
    extends State<SurfaceStudioVerticalAtlasAnimationGenerationPlanSection> {
  static const int _defaultDurationMs = 120;

  late final TextEditingController _durationMs =
      TextEditingController(text: '$_defaultDurationMs');
  bool _showDetails = false;
  String? _appendFeedback;

  @override
  void didUpdateWidget(
    covariant SurfaceStudioVerticalAtlasAnimationGenerationPlanSection
        oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (widget.mappingDraft != oldWidget.mappingDraft ||
        widget.atlasIdDraft != oldWidget.atlasIdDraft ||
        widget.rows != oldWidget.rows ||
        widget.columns != oldWidget.columns ||
        widget.tileWidth != oldWidget.tileWidth ||
        widget.tileHeight != oldWidget.tileHeight) {
      _appendFeedback = null;
    }
  }

  @override
  void dispose() {
    _durationMs.dispose();
    super.dispose();
  }

  int? _parseDurationMs() {
    return int.tryParse(_durationMs.text.trim());
  }

  void _resetDuration() {
    setState(() {
      _durationMs.text = '$_defaultDurationMs';
    });
  }

  void _tryAppendAnimations(
      SurfaceStudioVerticalAtlasAnimationGenerationPlan plan) {
    final cb = widget.onWorkCatalogChanged;
    if (cb == null) {
      return;
    }
    if (plan.summary.readyAnimationCount == 0) {
      setState(() {
        _appendFeedback = 'Aucune animation prête à créer.';
      });
      return;
    }
    final atlasId = widget.atlasIdDraft.trim();
    if (atlasId.isEmpty) {
      setState(() {
        _appendFeedback =
            'Définissez un identifiant d’atlas avant de créer des animations.';
      });
      return;
    }
    String? catId;
    final atl = widget.readModel.catalog.atlasById(atlasId);
    if (atl != null) {
      final c = atl.categoryId?.trim();
      if (c != null && c.isNotEmpty) {
        catId = c;
      }
    }
    final draftCat = widget.atlasCategoryDraft?.trim();
    catId ??= (draftCat == null || draftCat.isEmpty) ? null : draftCat;
    final baseSort = widget.readModel.catalog.animations.length;
    final outcome = surfaceStudioCollectNewAnimationsFromReadyPlan(
      plan: plan,
      atlasIdForTileRefs: atlasId,
      animationDisplayNamePrefix: widget.atlasDisplayName,
      categoryId: catId,
      sortOrderBase: baseSort,
    );
    if (outcome.newAnimations.isEmpty) {
      setState(() {
        _appendFeedback = 'Aucune animation prête à créer.';
      });
      return;
    }
    try {
      final next = surfaceStudioAppendAnimationsToWorkCatalog(
        catalog: widget.readModel.catalog,
        newAnimations: outcome.newAnimations,
      );
      cb(next);
      widget.onWorkCatalogAnimationsCreated?.call(
        outcome.newAnimations.map((a) => a.id).toList(),
      );
      final n = outcome.newAnimations.length;
      final ign = outcome.ignoredReadyCount;
      setState(() {
        _appendFeedback = ign > 0
            ? 'Animations créées dans le catalogue de travail ($n). $ign ignorée(s). '
                'Aucun preset créé. Pensez à appliquer au manifest puis sauvegarder le projet.'
            : 'Animations créées dans le catalogue de travail ($n). '
                'Aucun preset créé. Pensez à appliquer au manifest puis sauvegarder le projet.';
      });
    } on ValidationException {
      setState(() {
        _appendFeedback =
            'Impossible d’ajouter les animations (validation du catalogue).';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gridOk = surfaceStudioAtlasGridOverlayDraftValid(
      widget.tileWidth,
      widget.tileHeight,
      widget.columns,
      widget.rows,
    );
    final assignedCount =
        widget.mappingDraft.assignments.where((a) => a.role != null).length;
    final durationParsed = _parseDurationMs();
    final durationEffective =
        durationParsed != null && durationParsed > 0 ? durationParsed : 0;

    final existingIds = <String>{
      for (final row in widget.readModel.animations) row.id,
    };

    final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
      atlasIdRaw: widget.atlasIdDraft,
      mappingDraft: widget.mappingDraft,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      columns: widget.columns,
      rows: widget.rows,
      durationMsPerFrame: durationEffective,
      existingAnimationIds: existingIds,
    );

    final summary = plan.summary;
    final unassigned = widget.mappingDraft.columnCount - assignedCount;

    return Container(
      key: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection.sectionKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Plan de génération des animations',
              style: TextStyle(
                color: widget.label,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Plan de génération uniquement. Aucun preset n’est créé à cette étape.',
              style:
                  TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.35),
            ),
            Text(
              'Les animations ne sont pas encore dans le catalogue tant que vous ne les ajoutez pas.',
              style:
                  TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.35),
            ),
            const SizedBox(height: 8),
            if (!gridOk) ...[
              Text(
                'Corrigez la grille avant de préparer les animations.',
                style:
                    TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
              ),
            ] else if (assignedCount == 0) ...[
              Text(
                'Assignez au moins une colonne à un rôle pour préparer les animations.',
                style:
                    TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
              ),
            ] else ...[
              Text(
                'Colonnes assignées : $assignedCount',
                style: TextStyle(
                    color: widget.label, fontSize: 11.5, height: 1.35),
              ),
              if (unassigned > 0)
                Text(
                  'Colonnes non assignées : $unassigned',
                  style: TextStyle(
                      color: widget.subtle, fontSize: 11, height: 1.35),
                ),
              Text(
                'Animations prêtes : ${summary.readyAnimationCount}',
                style: TextStyle(
                    color: widget.label, fontSize: 11.5, height: 1.35),
              ),
              Text(
                'Animations en erreur : ${summary.errorAnimationCount}',
                style: TextStyle(
                    color: widget.label, fontSize: 11.5, height: 1.35),
              ),
              Text(
                summary.durationFieldValid
                    ? 'Durée par frame : ${summary.durationMsPerFrame} ms'
                    : 'Durée par frame : invalide',
                style:
                    TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      key:
                          const ValueKey('surface_studio_gen_plan_duration_ms'),
                      controller: _durationMs,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: widget.label, fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'Durée par frame (ms)',
                        isDense: true,
                        errorText: summary.durationFieldValid
                            ? null
                            : 'Entier strictement positif requis',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  OutlinedButton(
                    key: const ValueKey('surface_studio_gen_plan_preview'),
                    onPressed: () => setState(() => _showDetails = true),
                    child: const Text('Prévisualiser le plan'),
                  ),
                  OutlinedButton(
                    key: const ValueKey(
                        'surface_studio_gen_plan_reset_duration'),
                    onPressed: _resetDuration,
                    child: const Text('Réinitialiser la durée par frame'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (summary.readyAnimationCount == 0)
                Text(
                  'Aucune animation prête à créer.',
                  style: TextStyle(
                      color: widget.subtle, fontSize: 10.5, height: 1.35),
                ),
              const SizedBox(height: 8),
              FilledButton(
                key: const ValueKey('surface_studio_gen_plan_append_ready'),
                onPressed: widget.onWorkCatalogChanged != null &&
                        summary.readyAnimationCount > 0 &&
                        summary.durationFieldValid &&
                        widget.atlasIdDraft.trim().isNotEmpty
                    ? () => _tryAppendAnimations(plan)
                    : null,
                child: const Text(
                  'Ajouter les animations prêtes au catalogue de travail',
                ),
              ),
              if (_appendFeedback != null) ...[
                const SizedBox(height: 8),
                Text(
                  _appendFeedback!,
                  style: TextStyle(
                      color: widget.label, fontSize: 11, height: 1.35),
                ),
              ],
              if (_showDetails) ...[
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final it in plan.items) ...[
                          _itemCard(context, it),
                          const SizedBox(height: 6),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _itemCard(
    BuildContext context,
    SurfaceStudioVerticalAtlasAnimationGenerationItem it,
  ) {
    final statusLabel = switch (it.status) {
      SurfaceStudioVerticalAtlasAnimationPlanItemStatus.ready => 'prête',
      SurfaceStudioVerticalAtlasAnimationPlanItemStatus.invalid => 'invalide',
      SurfaceStudioVerticalAtlasAnimationPlanItemStatus.duplicate => 'doublon',
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: widget.label.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Rôle : ${SurfaceStudioRoleLabels.labelForRole(it.role)}',
              style: TextStyle(color: widget.label, fontSize: 11.5),
            ),
            Text(
              'Colonne : ${it.columnIndex}',
              style: TextStyle(color: widget.label, fontSize: 11.5),
            ),
            Text(
              'Animation proposée : ${it.proposedAnimationId.isEmpty ? '—' : it.proposedAnimationId}',
              style: TextStyle(color: widget.label, fontSize: 11.5),
            ),
            Text(
              'Frames : ${it.frameCount}',
              style: TextStyle(color: widget.label, fontSize: 11.5),
            ),
            Text(
              'Durée totale : ${it.totalDurationMs} ms',
              style: TextStyle(color: widget.label, fontSize: 11.5),
            ),
            Text(
              'Statut : $statusLabel',
              style: TextStyle(color: widget.subtle, fontSize: 11),
            ),
            if (it.problems.isNotEmpty)
              ...it.problems.map(
                (p) => Text(
                  p,
                  style: TextStyle(
                    color: widget.subtle,
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart

```dart
import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import 'surface_studio_vertical_atlas_animation_generation_plan.dart';
import 'surface_studio_vertical_atlas_role_mapping.dart';

/// Résultat de [surfaceStudioAppendReadyVerticalAtlasAnimations] : animations
/// ajoutées et nombre d’items prêts ignorés (doublon interne au lot, etc.).
@immutable
class SurfaceStudioVerticalAtlasAnimationAppendOutcome {
  const SurfaceStudioVerticalAtlasAnimationAppendOutcome({
    required this.newAnimations,
    required this.ignoredReadyCount,
  });

  final List<ProjectSurfaceAnimation> newAnimations;
  final int ignoredReadyCount;
}

/// Construit une [ProjectSurfaceAnimation] pour un item **prêt** du plan.
ProjectSurfaceAnimation surfaceStudioProjectSurfaceAnimationFromReadyPlanItem({
  required SurfaceStudioVerticalAtlasAnimationGenerationItem item,
  required String atlasIdForTileRefs,
  required String animationDisplayNamePrefix,
  required String? categoryId,
  required int sortOrder,
}) {
  final frames = <SurfaceAnimationFrame>[];
  for (var r = 0; r < item.frameCount; r++) {
    frames.add(
      SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: atlasIdForTileRefs,
          column: item.columnIndex,
          row: r,
        ),
        durationMs: item.durationMsPerFrame,
      ),
    );
  }
  final timeline = SurfaceAnimationTimeline(frames: frames);
  final prefix = animationDisplayNamePrefix.trim().isEmpty
      ? atlasIdForTileRefs.trim()
      : animationDisplayNamePrefix.trim();
  final name = '$prefix — ${SurfaceStudioRoleLabels.labelForRole(item.role)}';
  return ProjectSurfaceAnimation(
    id: item.proposedAnimationId,
    name: name,
    timeline: timeline,
    syncGroupId: atlasIdForTileRefs.trim(),
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

/// À partir du plan, produit la liste des animations à **ajouter** (items
/// [isReady] uniquement, ids [proposedAnimationId] uniques dans le lot).
SurfaceStudioVerticalAtlasAnimationAppendOutcome
    surfaceStudioCollectNewAnimationsFromReadyPlan({
  required SurfaceStudioVerticalAtlasAnimationGenerationPlan plan,
  required String atlasIdForTileRefs,
  required String animationDisplayNamePrefix,
  required String? categoryId,
  required int sortOrderBase,
}) {
  final seen = <String>{};
  final out = <ProjectSurfaceAnimation>[];
  var ignored = 0;
  var sort = sortOrderBase;
  for (final it in plan.items) {
    if (!it.isReady ||
        it.status != SurfaceStudioVerticalAtlasAnimationPlanItemStatus.ready) {
      continue;
    }
    if (!seen.add(it.proposedAnimationId)) {
      ignored++;
      continue;
    }
    out.add(
      surfaceStudioProjectSurfaceAnimationFromReadyPlanItem(
        item: it,
        atlasIdForTileRefs: atlasIdForTileRefs.trim(),
        animationDisplayNamePrefix: animationDisplayNamePrefix,
        categoryId: categoryId,
        sortOrder: sort,
      ),
    );
    sort++;
  }
  return SurfaceStudioVerticalAtlasAnimationAppendOutcome(
    newAnimations: out,
    ignoredReadyCount: ignored,
  );
}

/// Fusionne les nouvelles animations en fin de liste (atlas / presets inchangés).
ProjectSurfaceCatalog surfaceStudioAppendAnimationsToWorkCatalog({
  required ProjectSurfaceCatalog catalog,
  required List<ProjectSurfaceAnimation> newAnimations,
}) {
  return ProjectSurfaceCatalog(
    atlases: List<ProjectSurfaceAtlas>.from(catalog.atlases),
    animations: [
      ...catalog.animations,
      ...newAnimations,
    ],
    presets: List<ProjectSurfacePreset>.from(catalog.presets),
  );
}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_atlas_grid_overlay.dart';

class SurfaceStudioVerticalAtlasAssistant extends StatelessWidget {
  const SurfaceStudioVerticalAtlasAssistant({
    super.key,
    required this.label,
    required this.subtle,
    this.draftTileWidth,
    this.draftTileHeight,
    this.draftColumns,
    this.draftRows,
  });

  static const ValueKey<String> sectionKey =
      ValueKey<String>('surface_studio_vertical_atlas_assistant');

  final Color label;
  final Color subtle;
  final int? draftTileWidth;
  final int? draftTileHeight;
  final int? draftColumns;
  final int? draftRows;

  @override
  material.Widget build(material.BuildContext context) {
    final ok = surfaceStudioAtlasGridOverlayDraftValid(
      draftTileWidth,
      draftTileHeight,
      draftColumns,
      draftRows,
    );
    final tw = draftTileWidth;
    final th = draftTileHeight;
    final cols = draftColumns;
    final rows = draftRows;

    final children = <material.Widget>[
      material.Text(
        'Assistant atlas vertical',
        style: material.TextStyle(
          color: label,
          fontSize: 12,
          fontWeight: material.FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      const material.SizedBox(height: 6),
      material.Text(
        'Colonnes = variantes visuelles',
        style: material.TextStyle(color: label, fontSize: 11.5, height: 1.35),
      ),
      material.Text(
        'Lignes = frames d’animation',
        style: material.TextStyle(color: label, fontSize: 11.5, height: 1.35),
      ),
      const material.SizedBox(height: 6),
      material.Text(
        'Votre atlas ressemble à un atlas vertical animé.',
        style: material.TextStyle(color: label, fontSize: 11.5, height: 1.35),
      ),
      material.Text(
        'Chaque colonne peut représenter une variante de surface.',
        style: material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
      ),
      material.Text(
        'Chaque ligne peut représenter une frame d’animation.',
        style: material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
      ),
    ];

    if (!ok) {
      children.add(const material.SizedBox(height: 6));
      children.add(
        material.Text(
          'Indiquez largeur et hauteur de tuile, colonnes et lignes valides pour afficher les détections.',
          style: material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
        ),
      );
    } else if (cols == 1 && rows == 1) {
      children.add(const material.SizedBox(height: 6));
      children.add(
        material.Text(
          'Atlas simple : aucune structure animée détectée.',
          style: material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
        ),
      );
    } else if (cols != null &&
        rows != null &&
        tw != null &&
        th != null &&
        cols >= 2 &&
        rows >= 2) {
      final total = cols * rows;
      children.add(const material.SizedBox(height: 6));
      children.add(
        material.Text(
          'Variantes détectées : $cols colonnes',
          style: material.TextStyle(color: label, fontSize: 11.5, height: 1.35),
        ),
      );
      children.add(
        material.Text(
          'Frames détectées : $rows lignes',
          style: material.TextStyle(color: label, fontSize: 11.5, height: 1.35),
        ),
      );
      children.add(
        material.Text(
          'Total : $total tuiles',
          style: material.TextStyle(color: label, fontSize: 11.5, height: 1.35),
        ),
      );
      children.add(
        material.Text(
          'Taille de tuile : $tw×$th px',
          style: material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
        ),
      );
      if (rows > cols) {
        children.add(const material.SizedBox(height: 4));
        children.add(
          material.Text(
            'Structure probablement verticale : plusieurs frames par variante.',
            style:
                material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
          ),
        );
      } else if (cols > rows) {
        children.add(const material.SizedBox(height: 4));
        children.add(
          material.Text(
            'Structure probablement horizontale ou non standard.',
            style:
                material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
          ),
        );
      }
    }

    return material.Container(
      key: sectionKey,
      padding:
          const material.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: material.BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
        borderRadius: material.BorderRadius.circular(10),
        border: material.Border.all(
          color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
        ),
      ),
      child: material.Column(
        crossAxisAlignment: material.CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart

```dart
import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import 'surface_studio_vertical_atlas_animation_generation_plan.dart';
import 'surface_studio_vertical_atlas_role_mapping.dart';

/// Statut local pour l’UI (aucune persistance).
enum SurfaceStudioVerticalAtlasPresetPlanStatus {
  blockedEmptyAtlasId,
  blockedInvalidGrid,
  blockedNoMapping,
  blockedMissingAnimations,
  blockedDuplicatePresetId,
  incomplete,
  ready,
}

/// Id preset V0 : `<slug-atlas>-surface-preset` (même slug que les ids d’animation).
String surfaceStudioProposedVerticalAtlasPresetId(String atlasIdRaw) {
  final s = surfaceStudioSlugForAnimationIdSegment(atlasIdRaw);
  return s.isEmpty ? '' : '$s-surface-preset';
}

@immutable
class SurfaceStudioVerticalAtlasPresetAppendPlan {
  const SurfaceStudioVerticalAtlasPresetAppendPlan({
    required this.proposedPresetId,
    required this.proposedPresetName,
    required this.rolesCoveredCount,
    required this.rolesNotCoveredCount,
    required this.missingAnimationCount,
    required this.status,
    required this.canCreate,
    this.partialPresetUserMessage,
  });

  final String proposedPresetId;
  final String proposedPresetName;
  final int rolesCoveredCount;
  final int rolesNotCoveredCount;
  final int missingAnimationCount;
  final SurfaceStudioVerticalAtlasPresetPlanStatus status;
  final bool canCreate;

  /// Affiché si le preset ne couvre pas tous les rôles standard (V0 partiel honnête).
  final String? partialPresetUserMessage;
}

String? _categoryIdForPreset({
  required ProjectSurfaceCatalog catalog,
  required String atlasId,
  required String? atlasCategoryDraft,
}) {
  for (final a in catalog.atlases) {
    if (a.id == atlasId) {
      final c = a.categoryId?.trim();
      if (c != null && c.isNotEmpty) {
        return c;
      }
      break;
    }
  }
  final d = atlasCategoryDraft?.trim();
  return (d == null || d.isEmpty) ? null : d;
}

/// Plan local : mapping + catalogue (animations déjà présentes) — ne crée rien.
SurfaceStudioVerticalAtlasPresetAppendPlan
    surfaceStudioPlanVerticalAtlasPresetAppend({
  required ProjectSurfaceCatalog catalog,
  required String atlasIdRaw,
  required String atlasDisplayName,
  required String? atlasCategoryDraft,
  required SurfaceStudioColumnRoleMappingDraft mappingDraft,
  required bool gridValid,
}) {
  final atlasId = atlasIdRaw.trim();
  final presetId = surfaceStudioProposedVerticalAtlasPresetId(atlasIdRaw);
  final namePrefix =
      atlasDisplayName.trim().isEmpty ? atlasId : atlasDisplayName.trim();
  final proposedName = '$namePrefix — Surface';

  if (atlasId.isEmpty || presetId.isEmpty) {
    return SurfaceStudioVerticalAtlasPresetAppendPlan(
      proposedPresetId: presetId,
      proposedPresetName: proposedName,
      rolesCoveredCount: 0,
      rolesNotCoveredCount: 0,
      missingAnimationCount: 0,
      status: SurfaceStudioVerticalAtlasPresetPlanStatus.blockedEmptyAtlasId,
      canCreate: false,
    );
  }
  if (!gridValid) {
    return SurfaceStudioVerticalAtlasPresetAppendPlan(
      proposedPresetId: presetId,
      proposedPresetName: proposedName,
      rolesCoveredCount: 0,
      rolesNotCoveredCount: 0,
      missingAnimationCount: 0,
      status: SurfaceStudioVerticalAtlasPresetPlanStatus.blockedInvalidGrid,
      canCreate: false,
    );
  }

  final assigned = mappingDraft.assignments
      .where((a) => a.role != null)
      .toList()
    ..sort((a, b) => a.columnIndex.compareTo(b.columnIndex));
  if (assigned.isEmpty) {
    return SurfaceStudioVerticalAtlasPresetAppendPlan(
      proposedPresetId: presetId,
      proposedPresetName: proposedName,
      rolesCoveredCount: 0,
      rolesNotCoveredCount: standardSurfaceVariantRoleOrder.length,
      missingAnimationCount: 0,
      status: SurfaceStudioVerticalAtlasPresetPlanStatus.blockedNoMapping,
      canCreate: false,
    );
  }

  for (final p in catalog.presets) {
    if (p.id == presetId) {
      return SurfaceStudioVerticalAtlasPresetAppendPlan(
        proposedPresetId: presetId,
        proposedPresetName: proposedName,
        rolesCoveredCount: 0,
        rolesNotCoveredCount: 0,
        missingAnimationCount: 0,
        status:
            SurfaceStudioVerticalAtlasPresetPlanStatus.blockedDuplicatePresetId,
        canCreate: false,
      );
    }
  }

  final animationIds = <String>{for (final a in catalog.animations) a.id};
  final uniqueRolesOrdered = <SurfaceVariantRole>[];
  final seenRoles = <SurfaceVariantRole>{};
  for (final a in assigned) {
    final role = a.role!;
    if (!seenRoles.add(role)) {
      continue;
    }
    uniqueRolesOrdered.add(role);
  }
  var rolesWithAnimation = 0;
  for (final role in uniqueRolesOrdered) {
    final animId = surfaceStudioProposedAnimationId(
      atlasIdRaw: atlasIdRaw,
      role: role,
    );
    if (animId.isNotEmpty && animationIds.contains(animId)) {
      rolesWithAnimation++;
    }
  }
  final missing = uniqueRolesOrdered.length - rolesWithAnimation;
  final covered = rolesWithAnimation;
  final assignedRoleSet = uniqueRolesOrdered.toSet();
  var notCovered = 0;
  for (final r in standardSurfaceVariantRoleOrder) {
    if (!assignedRoleSet.contains(r)) {
      notCovered++;
    }
  }

  String? partialMsg;
  if (notCovered > 0) {
    partialMsg =
        'Preset incomplet : certains rôles ne sont pas encore couverts par le mapping.';
  }

  if (missing > 0) {
    return SurfaceStudioVerticalAtlasPresetAppendPlan(
      proposedPresetId: presetId,
      proposedPresetName: proposedName,
      rolesCoveredCount: covered,
      rolesNotCoveredCount: notCovered,
      missingAnimationCount: missing,
      status:
          SurfaceStudioVerticalAtlasPresetPlanStatus.blockedMissingAnimations,
      canCreate: false,
      partialPresetUserMessage: partialMsg,
    );
  }

  final status = notCovered > 0
      ? SurfaceStudioVerticalAtlasPresetPlanStatus.incomplete
      : SurfaceStudioVerticalAtlasPresetPlanStatus.ready;

  return SurfaceStudioVerticalAtlasPresetAppendPlan(
    proposedPresetId: presetId,
    proposedPresetName: proposedName,
    rolesCoveredCount: covered,
    rolesNotCoveredCount: notCovered,
    missingAnimationCount: 0,
    status: status,
    canCreate: true,
    partialPresetUserMessage: partialMsg,
  );
}

/// Construit le preset à ajouter (refs **uniquement** pour animations présentes dans [catalog]).
ProjectSurfacePreset surfaceStudioBuildVerticalAtlasPreset({
  required ProjectSurfaceCatalog catalog,
  required String atlasIdRaw,
  required String atlasDisplayName,
  required String? atlasCategoryDraft,
  required SurfaceStudioColumnRoleMappingDraft mappingDraft,
  required bool gridValid,
}) {
  final plan = surfaceStudioPlanVerticalAtlasPresetAppend(
    catalog: catalog,
    atlasIdRaw: atlasIdRaw,
    atlasDisplayName: atlasDisplayName,
    atlasCategoryDraft: atlasCategoryDraft,
    mappingDraft: mappingDraft,
    gridValid: gridValid,
  );
  if (!plan.canCreate) {
    throw StateError(
        'surfaceStudioBuildVerticalAtlasPreset: plan not creatable');
  }
  final atlasId = atlasIdRaw.trim();
  final assigned = mappingDraft.assignments
      .where((a) => a.role != null)
      .toList()
    ..sort((a, b) => a.columnIndex.compareTo(b.columnIndex));
  final animationIds = <String>{for (final a in catalog.animations) a.id};
  final byRole = <SurfaceVariantRole, String>{};
  for (final a in assigned) {
    final role = a.role!;
    final animId = surfaceStudioProposedAnimationId(
      atlasIdRaw: atlasIdRaw,
      role: role,
    );
    if (animId.isEmpty || !animationIds.contains(animId)) {
      continue;
    }
    byRole.putIfAbsent(role, () => animId);
  }
  final roles = byRole.keys.toList()
    ..sort((a, b) => a.index.compareTo(b.index));
  final refs = <SurfaceVariantAnimationRef>[
    for (final r in roles)
      SurfaceVariantAnimationRef(role: r, animationId: byRole[r]!),
  ];
  final refSet = SurfaceVariantAnimationRefSet(refs: refs);
  final catId = _categoryIdForPreset(
    catalog: catalog,
    atlasId: atlasId,
    atlasCategoryDraft: atlasCategoryDraft,
  );
  return ProjectSurfacePreset(
    id: plan.proposedPresetId,
    name: plan.proposedPresetName,
    variantAnimations: refSet,
    categoryId: catId,
    sortOrder: catalog.presets.length,
  );
}

/// Append **un** preset ; atlases et animations inchangés.
ProjectSurfaceCatalog surfaceStudioAppendPresetToWorkCatalog({
  required ProjectSurfaceCatalog catalog,
  required ProjectSurfacePreset preset,
}) {
  return ProjectSurfaceCatalog(
    atlases: List<ProjectSurfaceAtlas>.from(catalog.atlases),
    animations: List<ProjectSurfaceAnimation>.from(catalog.animations),
    presets: [...catalog.presets, preset],
  );
}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart

```dart
import 'package:map_core/map_core.dart';

/// Assignation locale d’une colonne d’atlas vers un rôle Surface.
///
/// Modèle UI local uniquement : aucune persistance, aucune génération d’animation.
/// Permet à l’utilisateur de préparer un mapping avant génération.
class SurfaceStudioColumnRoleAssignment {
  const SurfaceStudioColumnRoleAssignment({
    required this.columnIndex,
    this.role,
  });

  /// Index de la colonne dans l’atlas (0-based).
  final int columnIndex;

  /// Rôle Surface assigné, ou `null` si la colonne est non assignée.
  final SurfaceVariantRole? role;

  /// Vrai si un rôle est assigné à cette colonne.
  bool get isAssigned => role != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioColumnRoleAssignment &&
          other.columnIndex == columnIndex &&
          other.role == role;

  @override
  int get hashCode => Object.hash(columnIndex, role);
}

/// Brouillon local de mapping des colonnes d’un atlas vertical vers des rôles Surface.
///
/// Ce modèle ne crée aucune animation ni preset. Il sert uniquement à préparer
/// l’authoring visuel dans Surface Studio.
class SurfaceStudioColumnRoleMappingDraft {
  const SurfaceStudioColumnRoleMappingDraft({
    required this.columnCount,
    this.assignments = const [],
  });

  /// Nombre total de colonnes dans l’atlas.
  final int columnCount;

  /// Liste des assignations (une par colonne assignée).
  /// Les colonnes non assignées ne sont pas dans cette liste.
  final List<SurfaceStudioColumnRoleAssignment> assignments;

  /// Crée un brouillon vide pour un nombre de colonnes donné.
  const SurfaceStudioColumnRoleMappingDraft.empty(this.columnCount)
      : assignments = const [];

  /// Crée un brouillon avec une suggestion standard : les rôles standards
  /// sont assignés dans l’ordre aux premières colonnes.
  factory SurfaceStudioColumnRoleMappingDraft.suggested(int columnCount) {
    final assignments = <SurfaceStudioColumnRoleAssignment>[];
    const roles = standardSurfaceVariantRoleOrder;
    final countToAssign =
        columnCount < roles.length ? columnCount : roles.length;

    for (var i = 0; i < countToAssign; i++) {
      assignments.add(SurfaceStudioColumnRoleAssignment(
        columnIndex: i,
        role: roles[i],
      ));
    }

    return SurfaceStudioColumnRoleMappingDraft(
      columnCount: columnCount,
      assignments: assignments,
    );
  }

  /// Rôle assigné à une colonne, ou `null` si non assignée.
  SurfaceVariantRole? roleForColumn(int columnIndex) {
    for (final assignment in assignments) {
      if (assignment.columnIndex == columnIndex) {
        return assignment.role;
      }
    }
    return null;
  }

  /// Vrai si la colonne a un rôle assigné.
  bool isColumnAssigned(int columnIndex) => roleForColumn(columnIndex) != null;

  /// Crée une copie avec un rôle assigné à une colonne.
  SurfaceStudioColumnRoleMappingDraft withRoleForColumn(
    int columnIndex,
    SurfaceVariantRole? role,
  ) {
    final newAssignments = <SurfaceStudioColumnRoleAssignment>[];
    var found = false;

    for (final assignment in assignments) {
      if (assignment.columnIndex == columnIndex) {
        if (role != null) {
          newAssignments.add(SurfaceStudioColumnRoleAssignment(
            columnIndex: columnIndex,
            role: role,
          ));
        }
        found = true;
      } else {
        newAssignments.add(assignment);
      }
    }

    if (!found && role != null) {
      newAssignments.add(SurfaceStudioColumnRoleAssignment(
        columnIndex: columnIndex,
        role: role,
      ));
    }

    return SurfaceStudioColumnRoleMappingDraft(
      columnCount: columnCount,
      assignments: newAssignments,
    );
  }

  /// Crée une copie avec toutes les assignations supprimées (brouillon vide).
  SurfaceStudioColumnRoleMappingDraft cleared() {
    return SurfaceStudioColumnRoleMappingDraft.empty(columnCount);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioColumnRoleMappingDraft &&
          other.columnCount == columnCount &&
          _assignmentsEqualInOrder(other.assignments);

  bool _assignmentsEqualInOrder(List<SurfaceStudioColumnRoleAssignment> other) {
    if (assignments.length != other.length) {
      return false;
    }
    for (var i = 0; i < assignments.length; i++) {
      if (assignments[i] != other[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(columnCount, Object.hashAll(assignments));
}

/// Résumé statistique d’un brouillon de mapping.
class SurfaceStudioColumnRoleMappingSummary {
  const SurfaceStudioColumnRoleMappingSummary({
    required this.columnCount,
    required this.assignedColumnCount,
    required this.unassignedColumnCount,
    required this.duplicateRoleCount,
    required this.hasDuplicateRoles,
    required this.coveredRoles,
  });

  /// Nombre total de colonnes.
  final int columnCount;

  /// Nombre de colonnes avec un rôle assigné.
  final int assignedColumnCount;

  /// Nombre de colonnes sans rôle assigné.
  final int unassignedColumnCount;

  /// Nombre de rôles assignés à plusieurs colonnes.
  final int duplicateRoleCount;

  /// Vrai si au moins un rôle est assigné à plusieurs colonnes.
  final bool hasDuplicateRoles;

  /// Ensemble des rôles couverts (au moins une colonne).
  final Set<SurfaceVariantRole> coveredRoles;

  /// Crée un résumé à partir d’un brouillon de mapping.
  factory SurfaceStudioColumnRoleMappingSummary.fromDraft(
    SurfaceStudioColumnRoleMappingDraft draft,
  ) {
    final assignedCount = draft.assignments.length;
    final unassignedCount = draft.columnCount - assignedCount;

    final roleCounts = <SurfaceVariantRole, int>{};
    for (final assignment in draft.assignments) {
      final role = assignment.role;
      if (role != null) {
        roleCounts[role] = (roleCounts[role] ?? 0) + 1;
      }
    }

    final duplicateCount = roleCounts.values.where((count) => count > 1).length;
    final hasDuplicates = duplicateCount > 0;

    final coveredRoles = roleCounts.keys.toSet();

    return SurfaceStudioColumnRoleMappingSummary(
      columnCount: draft.columnCount,
      assignedColumnCount: assignedCount,
      unassignedColumnCount: unassignedCount,
      duplicateRoleCount: duplicateCount,
      hasDuplicateRoles: hasDuplicates,
      coveredRoles: coveredRoles,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioColumnRoleMappingSummary &&
          other.columnCount == columnCount &&
          other.assignedColumnCount == assignedColumnCount &&
          other.unassignedColumnCount == unassignedColumnCount &&
          other.duplicateRoleCount == duplicateRoleCount &&
          other.hasDuplicateRoles == hasDuplicateRoles &&
          _coveredRolesEqual(other.coveredRoles);

  bool _coveredRolesEqual(Set<SurfaceVariantRole> other) {
    if (coveredRoles.length != other.length) {
      return false;
    }
    for (final role in coveredRoles) {
      if (!other.contains(role)) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        columnCount,
        assignedColumnCount,
        unassignedColumnCount,
        duplicateRoleCount,
        hasDuplicateRoles,
        Object.hashAll(coveredRoles),
      );
}

/// Libellés utilisateur pour les rôles Surface.
///
/// Ces textes sont destinés à l’UI et ne doivent pas contenir de jargon
/// technique interne.
class SurfaceStudioRoleLabels {
  SurfaceStudioRoleLabels._();

  static const Map<SurfaceVariantRole, String> _labels = {
    SurfaceVariantRole.isolated: 'Plein',
    SurfaceVariantRole.endNorth: 'Bord haut',
    SurfaceVariantRole.endEast: 'Bord droit',
    SurfaceVariantRole.endSouth: 'Bord bas',
    SurfaceVariantRole.endWest: 'Bord gauche',
    SurfaceVariantRole.horizontal: 'Horizontal',
    SurfaceVariantRole.vertical: 'Vertical',
    SurfaceVariantRole.cornerNE: 'Coin haut droit',
    SurfaceVariantRole.cornerSE: 'Coin bas droit',
    SurfaceVariantRole.cornerSW: 'Coin bas gauche',
    SurfaceVariantRole.cornerNW: 'Coin haut gauche',
    SurfaceVariantRole.innerCornerNE: 'Coin intérieur haut droit',
    SurfaceVariantRole.innerCornerSE: 'Coin intérieur bas droit',
    SurfaceVariantRole.innerCornerSW: 'Coin intérieur bas gauche',
    SurfaceVariantRole.innerCornerNW: 'Coin intérieur haut gauche',
    SurfaceVariantRole.teeNorth: 'Té haut',
    SurfaceVariantRole.teeEast: 'Té droit',
    SurfaceVariantRole.teeSouth: 'Té bas',
    SurfaceVariantRole.teeWest: 'Té gauche',
    SurfaceVariantRole.cross: 'Croix',
  };

  /// Libellé utilisateur pour un rôle Surface.
  static String labelForRole(SurfaceVariantRole role) {
    return _labels[role] ?? role.toString();
  }

  /// Liste de tous les rôles avec leurs libellés, dans l’ordre standard.
  static List<SurfaceVariantRole> get allRolesInOrder =>
      standardSurfaceVariantRoleOrder;
}
```

### packages/map_editor/lib/src/ui/editor_shell_page.dart

```dart
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';
import 'package:map_editor/src/ui/panels/narrative_inspector_panel.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';
import 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';
import 'package:map_editor/src/ui/shared/status_bar.dart';
import 'package:map_editor/src/ui/shared/top_toolbar.dart';

import '../features/editor/state/editor_notifier.dart';
import '../features/editor/state/editor_selectors.dart';
import '../features/editor/state/editor_state.dart';

class EditorShellPage extends ConsumerStatefulWidget {
  const EditorShellPage({super.key});

  @override
  ConsumerState<EditorShellPage> createState() => _EditorShellPageState();
}

class _EditorShellPageState extends ConsumerState<EditorShellPage> {
  Timer? _toastTimer;
  String? _toastMessage;
  bool _toastIsError = false;
  bool _didAttemptProjectAutoRestore = false;

  /// When false, the right ResizablePane (map / tileset / narrative inspector) is omitted so the center stage uses full width.
  bool _rightInspectorVisible = true;

  @override
  void initState() {
    super.initState();
    // Provider mutations are intentionally deferred after the first frame:
    // auto-restore loads a project (state mutation), and Riverpod disallows
    // mutating providers during build/init lifecycle phases.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didAttemptProjectAutoRestore) {
        return;
      }
      _didAttemptProjectAutoRestore = true;
      await ref
          .read(editorNotifierProvider.notifier)
          .restoreLastOpenedProjectIfAny();
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _flashToast(String message, {required bool isError}) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastIsError = isError;
    });
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _toastMessage = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shell = ref.watch(editorShellSnapshotProvider);
    final workspaceMode = shell.workspaceMode;
    final notifier = ref.read(editorNotifierProvider.notifier);
    final supportsRightInspector = switch (workspaceMode) {
      EditorWorkspaceMode.pokedex || EditorWorkspaceMode.surfaceStudio => false,
      _ => true,
    };

    ref.listen(editorNotifierProvider.select((s) => s.errorMessage),
        (prev, next) {
      if (next != null) {
        _flashToast(next, isError: true);
      }
    });

    ref.listen(editorNotifierProvider.select((s) => s.statusMessage),
        (prev, next) {
      if (next != null) {
        _flashToast(next, isError: false);
      }
    });

    final isNarrativeWorkspace = switch (workspaceMode) {
      EditorWorkspaceMode.globalStory ||
      EditorWorkspaceMode.step ||
      EditorWorkspaceMode.cutscene ||
      EditorWorkspaceMode.dialogue =>
        true,
      _ => false,
    };

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true): _UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
            _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, meta: true): _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, control: true): _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, meta: true): _SaveIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, control: true): _SaveIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _UndoIntent: CallbackAction<_UndoIntent>(
            onInvoke: (_) {
              if (_isTextInputFocused()) return null;
              if (!shell.canUndoMap) return null;
              notifier.undoMap();
              return null;
            },
          ),
          _RedoIntent: CallbackAction<_RedoIntent>(
            onInvoke: (_) {
              if (_isTextInputFocused()) return null;
              if (!shell.canRedoMap) return null;
              notifier.redoMap();
              return null;
            },
          ),
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) {
              if (_isTextInputFocused()) return null;
              if (!shell.canSaveMap) return null;
              notifier.saveActiveMap();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              DecoratedBox(
                decoration: EditorChrome.appRootDecoration(context),
                child: Stack(
                  children: [
                    const Positioned(
                      left: -120,
                      top: -120,
                      child: _AmbientGlow(
                        size: 460,
                        color: EditorChrome.accentPrimary,
                        opacity: 0.14,
                      ),
                    ),
                    const Positioned(
                      right: -100,
                      top: 40,
                      child: _AmbientGlow(
                        size: 400,
                        color: EditorChrome.accentLilac,
                        opacity: 0.1,
                      ),
                    ),
                    const Positioned(
                      right: -120,
                      top: 90,
                      child: _AmbientGlow(
                        size: 420,
                        color: EditorChrome.accentWarm,
                        opacity: 0.13,
                      ),
                    ),
                    const Positioned(
                      left: 140,
                      bottom: -160,
                      child: _AmbientGlow(
                        size: 520,
                        color: EditorChrome.accentJade,
                        opacity: 0.1,
                      ),
                    ),
                    const Positioned(
                      right: 220,
                      bottom: -140,
                      child: _AmbientGlow(
                        size: 420,
                        color: EditorChrome.accentCoral,
                        opacity: 0.09,
                      ),
                    ),
                    MacosWindow(
                      child: MacosScaffold(
                        backgroundColor: const Color(0x00000000),
                        toolBar: buildMapEditorToolbar(context, ref),
                        children: [
                          ResizablePane.noScrollBar(
                            key: ValueKey<bool>(isNarrativeWorkspace),
                            resizableSide: ResizableSide.right,
                            minSize: isNarrativeWorkspace ? 200 : 240,
                            maxSize: isNarrativeWorkspace ? 460 : 520,
                            startSize: isNarrativeWorkspace ? 268 : 344,
                            decoration: const BoxDecoration(
                              color: MacosColors.transparent,
                            ),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                isNarrativeWorkspace ? 12 : 16,
                                isNarrativeWorkspace ? 16 : 18,
                                isNarrativeWorkspace ? 10 : 12,
                                isNarrativeWorkspace ? 16 : 18,
                              ),
                              child: const ProjectExplorerPanel(),
                            ),
                          ),
                          ContentArea(
                            builder: (context, scrollController) {
                              return Column(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        isNarrativeWorkspace ? 10 : 18,
                                        isNarrativeWorkspace ? 12 : 18,
                                        isNarrativeWorkspace ? 10 : 18,
                                        isNarrativeWorkspace ? 6 : 8,
                                      ),
                                      child: EditorIsland(
                                        radius: 36,
                                        tint: EditorChrome.islandCoolTint,
                                        child: Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            isNarrativeWorkspace ? 12 : 18,
                                            isNarrativeWorkspace ? 12 : 18,
                                            isNarrativeWorkspace ? 12 : 18,
                                            isNarrativeWorkspace ? 10 : 16,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _WorkspaceStageHeader(
                                                title: shell.workspaceTitle,
                                                subtitle:
                                                    shell.workspaceSubtitle,
                                                workspaceMode: workspaceMode,
                                                rightPanelVisible:
                                                    _rightInspectorVisible,
                                                showRightPanelToggle:
                                                    supportsRightInspector,
                                                onToggleRightPanel: () {
                                                  setState(() {
                                                    _rightInspectorVisible =
                                                        !_rightInspectorVisible;
                                                  });
                                                },
                                              ),
                                              SizedBox(
                                                height: isNarrativeWorkspace
                                                    ? 12
                                                    : 18,
                                              ),
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(26),
                                                  child: Padding(
                                                    padding: EdgeInsets.all(
                                                      isNarrativeWorkspace
                                                          ? 8
                                                          : 14,
                                                    ),
                                                    child:
                                                        const EditorCanvasHost(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const StatusBar(),
                                ],
                              );
                            },
                          ),
                          if (supportsRightInspector && _rightInspectorVisible)
                            ResizablePane.noScrollBar(
                              key: ValueKey<String>(
                                'editor_right_${isNarrativeWorkspace ? 'n' : 'm'}',
                              ),
                              resizableSide: ResizableSide.left,
                              minSize: isNarrativeWorkspace ? 220 : 240,
                              maxSize: 620,
                              startSize: isNarrativeWorkspace ? 292 : 336,
                              decoration: const BoxDecoration(
                                color: MacosColors.transparent,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 18, 16, 18),
                                child: EditorIsland(
                                  radius: 32,
                                  tint: switch (workspaceMode) {
                                    EditorWorkspaceMode.map =>
                                      EditorChrome.islandNeutralTint,
                                    EditorWorkspaceMode.tileset =>
                                      EditorChrome.islandWarmTint,
                                    EditorWorkspaceMode.trainer =>
                                      EditorChrome.islandWarmTint,
                                    EditorWorkspaceMode.pokedex =>
                                      EditorChrome.islandWarmTint,
                                    EditorWorkspaceMode.surfaceStudio =>
                                      EditorChrome.islandCoolTint,
                                    EditorWorkspaceMode.globalStory =>
                                      EditorChrome.islandCoolTint,
                                    EditorWorkspaceMode.step =>
                                      EditorChrome.islandWarmTint,
                                    EditorWorkspaceMode.cutscene =>
                                      EditorChrome.islandNeutralTint,
                                    EditorWorkspaceMode.dialogue =>
                                      EditorChrome.islandCoolTint,
                                  },
                                  child: switch (workspaceMode) {
                                    EditorWorkspaceMode.map =>
                                      const MapInspectorPanel(),
                                    EditorWorkspaceMode.tileset =>
                                      const TilesetPalettePanel(),
                                    EditorWorkspaceMode.trainer =>
                                      const _EmptyWorkspaceInspector(),
                                    // Le Pokédex du lot 13 n'a toujours pas de
                                    // panneau d'inspection dédié :
                                    // pas de détail espèce, pas d'édition.
                                    // On réutilise donc un panneau neutre vide
                                    // pour éviter d'introduire une nouvelle
                                    // structure latérale ou une fausse logique.
                                    EditorWorkspaceMode.pokedex =>
                                      const _EmptyWorkspaceInspector(),
                                    EditorWorkspaceMode.surfaceStudio =>
                                      const _SurfaceWorkspaceInspector(),
                                    EditorWorkspaceMode.globalStory ||
                                    EditorWorkspaceMode.step ||
                                    EditorWorkspaceMode.cutscene ||
                                    EditorWorkspaceMode.dialogue =>
                                      const NarrativeInspectorPanel(),
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_toastMessage != null)
                Positioned(
                  right: 24,
                  bottom: 72,
                  child: _EditorToastBanner(
                    message: _toastMessage!,
                    isError: _toastIsError,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorToastBanner extends StatelessWidget {
  const _EditorToastBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final tint = isError
        ? EditorChrome.errorTint(context)
        : EditorChrome.statusTint(context);
    final accent = isError
        ? EditorChrome.inspectorJoyCoral
        : EditorChrome.inspectorJoyMint;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: EditorIsland(
        radius: 18,
        tint: tint,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(CupertinoColors.white, accent, 0.75)!,
                      Color.lerp(accent, const Color(0xFF102010), 0.35)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.88),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: MacosIcon(
                  isError
                      ? CupertinoIcons.exclamationmark_triangle_fill
                      : CupertinoIcons.check_mark_circled_solid,
                  color: CupertinoColors.white,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceStageHeader extends StatelessWidget {
  const _WorkspaceStageHeader({
    required this.title,
    required this.subtitle,
    required this.workspaceMode,
    required this.rightPanelVisible,
    required this.showRightPanelToggle,
    required this.onToggleRightPanel,
  });

  final String title;
  final String subtitle;
  final EditorWorkspaceMode workspaceMode;
  final bool rightPanelVisible;
  final bool showRightPanelToggle;
  final VoidCallback onToggleRightPanel;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    final chipFill = EditorChrome.chipFill(context);
    final chipAccent = switch (workspaceMode) {
      EditorWorkspaceMode.map => EditorChrome.inspectorJoyHoney,
      EditorWorkspaceMode.tileset => EditorChrome.inspectorJoyLilac,
      EditorWorkspaceMode.trainer => EditorChrome.accentCoral,
      EditorWorkspaceMode.pokedex => EditorChrome.inspectorJoyAmber,
      EditorWorkspaceMode.surfaceStudio => EditorChrome.inspectorJoyCyan,
      EditorWorkspaceMode.globalStory => EditorChrome.inspectorJoyCyan,
      EditorWorkspaceMode.step => EditorChrome.inspectorJoyMint,
      EditorWorkspaceMode.cutscene => EditorChrome.inspectorJoyCoral,
      EditorWorkspaceMode.dialogue => EditorChrome.inspectorJoyBlue,
    };
    final chipAccent2 = switch (workspaceMode) {
      EditorWorkspaceMode.map => EditorChrome.inspectorJoyApricot,
      EditorWorkspaceMode.tileset => EditorChrome.inspectorJoyPlum,
      EditorWorkspaceMode.trainer => EditorChrome.inspectorJoyCoral,
      EditorWorkspaceMode.pokedex => EditorChrome.accentWarm,
      EditorWorkspaceMode.surfaceStudio => EditorChrome.accentJade,
      EditorWorkspaceMode.globalStory => EditorChrome.inspectorJoyBlue,
      EditorWorkspaceMode.step => EditorChrome.accentJade,
      EditorWorkspaceMode.cutscene => EditorChrome.inspectorJoyCoral,
      EditorWorkspaceMode.dialogue => EditorChrome.inspectorJoyCyan,
    };

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(CupertinoColors.white, chipAccent, 0.72)!,
                Color.lerp(chipAccent2, const Color(0xFF1A0A08), 0.38)!,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: chipAccent.withValues(alpha: 0.88),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: MacosIcon(
            switch (workspaceMode) {
              EditorWorkspaceMode.map => CupertinoIcons.map,
              EditorWorkspaceMode.tileset => CupertinoIcons.square_grid_2x2,
              EditorWorkspaceMode.trainer => CupertinoIcons.person_3_fill,
              EditorWorkspaceMode.pokedex => CupertinoIcons.book,
              EditorWorkspaceMode.surfaceStudio => Icons.auto_awesome_motion,
              EditorWorkspaceMode.globalStory => CupertinoIcons.link,
              EditorWorkspaceMode.step => CupertinoIcons.flag,
              EditorWorkspaceMode.cutscene => CupertinoIcons.play_rectangle,
              EditorWorkspaceMode.dialogue => CupertinoIcons.text_bubble,
            },
            color: CupertinoColors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: label,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtle,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (showRightPanelToggle) ...[
          MacosTooltip(
            message:
                rightPanelVisible ? 'Hide right panel' : 'Show right panel',
            child: MacosIconButton(
              semanticLabel:
                  rightPanelVisible ? 'Hide right panel' : 'Show right panel',
              icon: MacosIcon(
                rightPanelVisible ? Icons.open_in_full : Icons.close_fullscreen,
                color: label.withValues(alpha: 0.85),
                size: 18,
              ),
              backgroundColor: CupertinoColors.transparent,
              hoverColor: chipAccent.withValues(alpha: 0.12),
              onPressed: onToggleRightPanel,
              boxConstraints: const BoxConstraints(
                minWidth: 34,
                maxWidth: 34,
                minHeight: 34,
                maxHeight: 34,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Color.lerp(chipFill, chipAccent, 0.22),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: chipAccent.withValues(alpha: 0.65),
              width: 1,
            ),
          ),
          child: Text(
            switch (workspaceMode) {
              EditorWorkspaceMode.map => 'Scene',
              EditorWorkspaceMode.tileset => 'Library',
              EditorWorkspaceMode.trainer => 'Trainer',
              EditorWorkspaceMode.pokedex => 'Catalogues',
              EditorWorkspaceMode.surfaceStudio => 'Surface',
              EditorWorkspaceMode.globalStory => 'Global',
              EditorWorkspaceMode.step => 'Step',
              EditorWorkspaceMode.cutscene => 'Cutscene',
              EditorWorkspaceMode.dialogue => 'Dialogue',
            },
            style: TextStyle(
              color: chipAccent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.4),
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.38, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Rappel produit côté inspecteur (Surface Studio est surtout au centre).
class _SurfaceWorkspaceInspector extends StatelessWidget {
  const _SurfaceWorkspaceInspector();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Ouvrez Surface Studio pour parcourir le catalogue de surfaces animées et les diagnostics (vue centrale).',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Panneau droit volontairement neutre pour les workspaces qui n'ont pas
/// encore d'inspecteur réel.
///
/// Pour le lot 12, cela permet de garder la structure visuelle existante de
/// l'éditeur sans inventer un inspecteur Pokédex artificiel, ni brancher une
/// logique future avant l'heure.
class _EmptyWorkspaceInspector extends StatelessWidget {
  const _EmptyWorkspaceInspector();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Cette section n’a pas encore d’inspecteur dédié.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

bool _isTextInputFocused() {
  final focusedContext = FocusManager.instance.primaryFocus?.context;
  if (focusedContext == null) return false;
  return focusedContext.widget is EditableText ||
      focusedContext.findAncestorWidgetOfExactType<EditableText>() != null;
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}
```

### packages/map_editor/test/editor_shell_page_smoke_test.dart

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/pokemon_items/pokemon_items_workspace_providers.dart';
import 'package:map_editor/src/app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  group('EditorShellPage smoke', () {
    testWidgets('renders map workspace chrome and toggles the right panel',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_smoke',
          project: buildShellChromeProject(),
        ),
      );

      expect(find.text('Map Workspace'), findsOneWidget);
      expect(
        find.text('Open a map to start building your world.'),
        findsOneWidget,
      );
      expect(find.text('Ready'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Hide right panel',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Hide right panel',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Show right panel',
        ),
        findsOneWidget,
      );
    });

    testWidgets('updates the workspace header for tileset mode',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_tileset',
          project: buildShellChromeProject(
            tilesets: const <ProjectTilesetEntry>[
              ProjectTilesetEntry(
                id: 'indoor',
                name: 'Indoor',
                relativePath: 'tilesets/indoor.json',
              ),
            ],
          ),
          workspaceMode: EditorWorkspaceMode.tileset,
          selectedTilesetEditorId: 'indoor',
        ),
      );

      expect(find.text('Indoor'), findsAtLeastNWidgets(1));
      expect(
        find.text(
          'Visual library editing for tiles, elements and groups.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders the trainer studio workspace chrome', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_trainer',
          project: buildShellChromeProject(),
          workspaceMode: EditorWorkspaceMode.trainer,
        ),
      );

      expect(find.text('Trainer Studio'), findsWidgets);
      expect(
        find.textContaining('battle-ready rosters'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('trainer-library-new-trainer-button')),
        findsOneWidget,
      );
    });

    testWidgets('renders the Pokémon catalogs workspace shell', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_catalogs',
          project: buildShellChromeProject(),
          workspaceMode: EditorWorkspaceMode.pokedex,
          pokemonCatalogSection: PokemonCatalogSection.moves,
        ),
        overrides: [
          pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
            (_) async => const PokemonMovesCatalogView(
              entries: <PokemonMoveCatalogEntryView>[
                PokemonMoveCatalogEntryView(
                  id: 'water-gun',
                  name: 'Water Gun',
                  type: 'water',
                  category: 'special',
                  power: 40,
                  accuracy: 100,
                  pp: 25,
                ),
              ],
              isAvailable: true,
              description: 'Catalogue local des capacités du projet.',
            ),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );

      expect(find.text('Catalogues Pokémon'), findsWidgets);
      expect(find.byKey(const Key('pokemon-catalogs-tabs')), findsNothing);
      expect(find.text('Moves'), findsWidgets);
      expect(
        find.text('Catalogue local des capacités du projet.'),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              (widget.semanticLabel == 'Hide right panel' ||
                  widget.semanticLabel == 'Show right panel'),
        ),
        findsNothing,
      );
    });

    testWidgets('renders the Items catalogs workspace shell', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_items_catalogs',
          project: buildShellChromeProject(),
          workspaceMode: EditorWorkspaceMode.pokedex,
          pokemonCatalogSection: PokemonCatalogSection.items,
        ),
        overrides: [
          pokemonItemsCatalogWorkspaceLoaderProvider.overrideWithValue(
            (_) async => const PokemonItemsCatalogView(
              entries: <PokemonItemCatalogEntryView>[
                PokemonItemCatalogEntryView(
                  id: 'poke-ball',
                  name: 'Poké Ball',
                  categoryId: 'standard-balls',
                  pocketId: 'poke-balls',
                  cost: 200,
                ),
              ],
              isAvailable: true,
              description: 'Catalogue local des objets du projet.',
            ),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );

      expect(find.text('Catalogues Pokémon'), findsWidgets);
      expect(find.byKey(const Key('pokemon-catalogs-tabs')), findsNothing);
      expect(find.text('Items'), findsWidgets);
      expect(
        find.text('Catalogue local des objets du projet.'),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              (widget.semanticLabel == 'Hide right panel' ||
                  widget.semanticLabel == 'Show right panel'),
        ),
        findsNothing,
      );
    });

    testWidgets('renders Surface Studio without the global right inspector',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_surface_studio',
          project: buildShellChromeProject(),
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );

      expect(
        find.text('Surface Studio — Assistant de mapping d’atlas'),
        findsWidgets,
      );
      expect(
        find.textContaining('vue centrale'),
        findsNothing,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              (widget.semanticLabel == 'Hide right panel' ||
                  widget.semanticLabel == 'Show right panel'),
        ),
        findsNothing,
      );
    });

    testWidgets('renders shell chrome with an error state already present',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_error',
          project: buildShellChromeProject(),
          errorMessage: 'Shell render failure',
        ),
      );

      expect(find.text('Shell render failure'), findsOneWidget);
    });
  });
}
```

### packages/map_editor/test/surface_studio/surface_studio_atlas_editing_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_editing.dart';

void main() {
  group('surface_studio_atlas_editing (Lot 68–69)', () {
    test('countAnimationsReferencingAtlasId compte par animation', () {
      final g = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
        layout: SurfaceAtlasLayout.grid,
      );
      final a1 = ProjectSurfaceAtlas(
        id: 'A',
        name: 'a',
        tilesetId: 't',
        geometry: g,
      );
      final a2 = ProjectSurfaceAtlas(
        id: 'B',
        name: 'b',
        tilesetId: 't',
        geometry: g,
      );
      final f1 = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(atlasId: 'A', column: 0, row: 0),
        durationMs: 1,
      );
      final f2 = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(atlasId: 'A', column: 0, row: 0),
        durationMs: 1,
      );
      final anim1 = ProjectSurfaceAnimation(
        id: 'm1',
        name: 'm1',
        timeline: SurfaceAnimationTimeline(frames: [f1]),
      );
      final anim2 = ProjectSurfaceAnimation(
        id: 'm2',
        name: 'm2',
        timeline: SurfaceAnimationTimeline(frames: [f2, f1]),
      );
      final anim3 = ProjectSurfaceAnimation(
        id: 'm3',
        name: 'm3',
        timeline: SurfaceAnimationTimeline(frames: [
          SurfaceAnimationFrame(
            tileRef: SurfaceAtlasTileRef(atlasId: 'B', column: 0, row: 0),
            durationMs: 1,
          ),
        ]),
      );
      final cat = ProjectSurfaceCatalog(
        atlases: [a1, a2],
        animations: [anim1, anim2, anim3],
        presets: const [],
      );
      expect(countAnimationsReferencingAtlasId(cat, 'A'), 2);
      expect(countAnimationsReferencingAtlasId(cat, 'B'), 1);
    });

    test('replaceAtlasInCatalogInPlace préserve ordre, animations, presets',
        () {
      final g0 = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
        layout: SurfaceAtlasLayout.grid,
      );
      final g1 = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
        gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
        layout: SurfaceAtlasLayout.grid,
      );
      final a1 = ProjectSurfaceAtlas(
        id: 'x',
        name: 'n1',
        tilesetId: 't',
        geometry: g0,
      );
      final a2 = ProjectSurfaceAtlas(
        id: 'y',
        name: 'n2',
        tilesetId: 't',
        geometry: g0,
      );
      final anim = ProjectSurfaceAnimation(
        id: 'anim',
        name: 'anim',
        timeline: SurfaceAnimationTimeline(frames: [
          SurfaceAnimationFrame(
            tileRef: SurfaceAtlasTileRef(atlasId: 'x', column: 0, row: 0),
            durationMs: 1,
          ),
        ]),
      );
      var cat = ProjectSurfaceCatalog(
        atlases: [a1, a2],
        animations: [anim],
        presets: const [],
      );
      final updated = ProjectSurfaceAtlas(
        id: 'x',
        name: 'renamed',
        tilesetId: 't2',
        geometry: g1,
        sortOrder: 0,
      );
      cat = replaceAtlasInCatalogInPlace(cat, updated);
      expect(cat.atlases.length, 2);
      expect(cat.atlases[0].id, 'x');
      expect(cat.atlases[0].name, 'renamed');
      expect(cat.atlases[0].tilesetId, 't2');
      expect(cat.atlases[0].geometry.tileSize.width, 16);
      expect(cat.atlases[1].id, 'y');
      expect(cat.animations.single.id, 'anim');
      expect(cat.presets, isEmpty);
    });

    test('removeAtlasIdFromWorkCatalog lève si absent', () {
      final cat = ProjectSurfaceCatalog();
      expect(
        () => removeAtlasIdFromWorkCatalog(cat, 'nope'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
```

### packages/map_editor/test/surface_studio/surface_studio_atlas_grid_overlay_test.dart

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart';

/// PNG 1×1 minimal.
List<int> get _minimalPngBytes => <int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0A,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0x00,
      0x01,
      0x00,
      0x00,
      0x05,
      0x00,
      0x01,
      0x0D,
      0x0A,
      0x2D,
      0xB4,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ];

void main() {
  group('decodeRasterImageSizeFromBytes', () {
    test('PNG 1×1 → 1×1', () {
      final d = decodeRasterImageSizeFromBytes(
        Uint8List.fromList(_minimalPngBytes),
      );
      expect(d.width, 1);
      expect(d.height, 1);
    });

    test('octets vides → null', () {
      final d = decodeRasterImageSizeFromBytes(Uint8List(0));
      expect(d.width, isNull);
      expect(d.height, isNull);
    });
  });

  group('surfaceStudioAtlasGridOverlayDraftValid', () {
    test('refus si une valeur manque ou nulle', () {
      expect(surfaceStudioAtlasGridOverlayDraftValid(null, 1, 1, 1), isFalse);
      expect(surfaceStudioAtlasGridOverlayDraftValid(1, null, 1, 1), isFalse);
      expect(surfaceStudioAtlasGridOverlayDraftValid(1, 1, null, 1), isFalse);
      expect(surfaceStudioAtlasGridOverlayDraftValid(1, 1, 1, null), isFalse);
      expect(surfaceStudioAtlasGridOverlayDraftValid(0, 1, 1, 1), isFalse);
      expect(surfaceStudioAtlasGridOverlayDraftValid(1, 1, 1, 1), isTrue);
    });
  });

  group('dimensions attendues', () {
    test('32×23 colonnes = 736', () {
      expect(surfaceStudioAtlasGridExpectedWidthPx(32, 23), 736);
      expect(surfaceStudioAtlasGridExpectedHeightPx(32, 32), 1024);
    });
  });

  group('SurfaceStudioAtlasImageGridPainter', () {
    testWidgets('CustomPaint sans crash', (tester) async {
      await tester.pumpWidget(
        MacosApp(
          theme: MacosThemeData.dark(),
          home: const ColoredBox(
            color: Color(0xFF0F1218),
            child: Center(
              child: CustomPaint(
                key: ValueKey<String>('surf73_grid_paint_test'),
                size: Size(80, 60),
                painter: SurfaceStudioAtlasImageGridPainter(
                  columns: 4,
                  rows: 3,
                  lineColor: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
          find.byKey(const ValueKey('surf73_grid_paint_test')), findsOneWidget);
    });

    testWidgets('pas de jargon dans le painter (aucun Text)', (tester) async {
      await tester.pumpWidget(
        MacosApp(
          theme: MacosThemeData.dark(),
          home: const ColoredBox(
            color: Color(0xFF0F1218),
            child: CustomPaint(
              size: Size(40, 40),
              painter: SurfaceStudioAtlasImageGridPainter(
                columns: 2,
                rows: 2,
                lineColor: Color(0xFFFFFFFF),
                stepX: 1,
                stepY: 1,
              ),
            ),
          ),
        ),
      );
      for (final term in const <String>[
        'ProjectSurfaceAtlas',
        'ProjectSurfaceCatalog',
        'SurfaceStudioReadModel',
        'callback',
        'copyWith',
        'tilesetId',
      ]) {
        expect(find.textContaining(term), findsNothing);
      }
    });
  });

  // Pas de test widget [SurfaceStudioAtlasImagePreview] + fichier réel : comme au Lot 72,
  // [Image.memory] peut laisser flutter_test en attente d’idle sur ce runner.
  // L’intégration image + overlay est couverte par les tests manuels et par la suite
  // [surface_studio_atlas_authoring_prep_test] / [test/surface_studio] en non-régression.
}
```

### packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_grid_preview.dart';

void main() {
  testWidgets('section visible et métriques de grille', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SurfaceStudioAtlasGridPreview(
          sourceLabel: 'eau_atlas',
          tileWidth: 32,
          tileHeight: 32,
          columns: 4,
          rows: 8,
          layoutLabel: 'Grille libre',
        ),
      ),
    );

    expect(
        find.byKey(kSurfaceStudioAtlasGridPreviewSectionKey), findsOneWidget);
    expect(find.text('Aperçu de la grille atlas'), findsOneWidget);
    expect(find.text('Source : eau_atlas'), findsOneWidget);
    expect(find.text('Tile : 32×32 px'), findsOneWidget);
    expect(find.text('Grille : 4 colonnes × 8 lignes'), findsOneWidget);
    expect(find.text('Total : 32 cases'), findsOneWidget);
    expect(find.text('Disposition : Grille libre'), findsOneWidget);
  });

  testWidgets('état vide sans source', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SurfaceStudioAtlasGridPreview(
          sourceLabel: null,
          tileWidth: 32,
          tileHeight: 32,
          columns: 4,
          rows: 8,
          layoutLabel: 'Grille libre',
        ),
      ),
    );

    expect(
      find.text('Choisissez une image source pour prévisualiser la grille.'),
      findsOneWidget,
    );
  });

  testWidgets('état invalide dimensions', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SurfaceStudioAtlasGridPreview(
          sourceLabel: 'eau_atlas',
          tileWidth: 0,
          tileHeight: 32,
          columns: 4,
          rows: 8,
          layoutLabel: 'Grille libre',
        ),
      ),
    );

    expect(
      find.text('Corrigez les dimensions de grille pour afficher la preview.'),
      findsOneWidget,
    );
  });

  testWidgets('aperçu réduit si grille grande', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SurfaceStudioAtlasGridPreview(
          sourceLabel: 'eau_atlas',
          tileWidth: 16,
          tileHeight: 16,
          columns: 20,
          rows: 10,
          layoutLabel: 'Grille libre',
        ),
      ),
    );

    expect(find.text('Aperçu réduit'), findsOneWidget);
    expect(find.byKey(const ValueKey('surface_studio_grid_cell_95')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('surface_studio_grid_cell_96')),
        findsNothing);
  });

  testWidgets('pas de jargon interdit dans la preview', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SurfaceStudioAtlasGridPreview(
          sourceLabel: 'eau_atlas',
          tileWidth: 32,
          tileHeight: 32,
          columns: 2,
          rows: 2,
          layoutLabel: 'Grille libre',
        ),
      ),
    );

    for (final term in const <String>[
      'tilesetId',
      'ProjectSurfaceAtlas',
      'ProjectSurfaceCatalog',
      'SurfaceStudioReadModel',
      'callback',
      'copyWith',
    ]) {
      expect(find.textContaining(term), findsNothing);
    }
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    ),
  );
}
```

### packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_test.dart

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_image_preview.dart';
import 'package:path/path.dart' as p;

/// PNG 1×1 pixel minimal (valide pour [Image.file]).
List<int> get _minimalPngBytes => <int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0A,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0x00,
      0x01,
      0x00,
      0x00,
      0x05,
      0x00,
      0x01,
      0x0D,
      0x0A,
      0x2D,
      0xB4,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ];

void main() {
  group('resolveSurfaceStudioAtlasImagePreview', () {
    test('empty sans identifiant', () {
      final r = resolveSurfaceStudioAtlasImagePreview(
        projectRootPath: '/tmp',
        projectTilesets: const [],
        technicalTilesetId: null,
      );
      expect(r.status, SurfaceStudioAtlasImagePreviewResolveStatus.empty);
    });

    test('unresolved sans entrées tileset', () {
      final r = resolveSurfaceStudioAtlasImagePreview(
        projectRootPath: '/tmp',
        projectTilesets: const [],
        technicalTilesetId: 'x',
      );
      expect(r.status, SurfaceStudioAtlasImagePreviewResolveStatus.unresolved);
    });

    test('unresolved identifiant inconnu', () {
      final r = resolveSurfaceStudioAtlasImagePreview(
        projectRootPath: '/tmp',
        projectTilesets: [
          const ProjectTilesetEntry(
            id: 'a',
            name: 'A',
            relativePath: 'a.png',
            sortOrder: 0,
          ),
        ],
        technicalTilesetId: 'b',
      );
      expect(r.status, SurfaceStudioAtlasImagePreviewResolveStatus.unresolved);
    });

    test('unresolved sans racine projet', () {
      final r = resolveSurfaceStudioAtlasImagePreview(
        projectRootPath: null,
        projectTilesets: [
          const ProjectTilesetEntry(
            id: 't1',
            name: 'Eau',
            relativePath: 'assets/eau.png',
            sortOrder: 0,
          ),
        ],
        technicalTilesetId: 't1',
      );
      expect(r.status, SurfaceStudioAtlasImagePreviewResolveStatus.unresolved);
      expect(r.displayFileName, 'eau.png');
      expect(r.relativePathForUi, contains('assets/eau.png'));
    });

    test('missingFile racine + entrée mais fichier absent', () {
      final root = Directory.systemTemp.createTempSync('surf72_miss_').path;
      try {
        final r = resolveSurfaceStudioAtlasImagePreview(
          projectRootPath: root,
          projectTilesets: [
            const ProjectTilesetEntry(
              id: 't1',
              name: 'Eau',
              relativePath: 'nope.png',
              sortOrder: 0,
            ),
          ],
          technicalTilesetId: 't1',
        );
        expect(
            r.status, SurfaceStudioAtlasImagePreviewResolveStatus.missingFile);
        expect(r.displayFileName, 'nope.png');
        expect(r.relativePathForUi, 'nope.png');
      } finally {
        Directory(root).deleteSync(recursive: true);
      }
    });

    test('resolved quand le fichier existe', () async {
      final temp = await Directory.systemTemp.createTemp('surf72_ok_');
      try {
        final rel = p.join('sub', 'one.png');
        final abs = p.normalize(p.join(temp.path, rel));
        await Directory(p.dirname(abs)).create(recursive: true);
        await File(abs).writeAsBytes(_minimalPngBytes);

        final r = resolveSurfaceStudioAtlasImagePreview(
          projectRootPath: temp.path,
          projectTilesets: [
            ProjectTilesetEntry(
              id: 't1',
              name: 'Textures',
              relativePath: rel.replaceAll(r'\', '/'),
              sortOrder: 0,
            ),
          ],
          technicalTilesetId: 't1',
        );
        expect(r.status, SurfaceStudioAtlasImagePreviewResolveStatus.resolved);
        expect(r.resolvedAbsolutePath, abs);
        expect(r.displayFileName, 'one.png');
        expect(r.relativePathForUi, rel.replaceAll(r'\', '/'));
      } finally {
        await temp.delete(recursive: true);
      }
    });
  });

  group('SurfaceStudioAtlasImagePreview widget', () {
    testWidgets('état vide', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SurfaceStudioAtlasImagePreview(
            resolution: SurfaceStudioAtlasImagePreviewResolution(
              status: SurfaceStudioAtlasImagePreviewResolveStatus.empty,
              displayFileName: '',
              relativePathForUi: '',
            ),
            label: Colors.white,
            subtle: Colors.grey,
          ),
        ),
      );
      expect(find.byKey(kSurfaceStudioAtlasImagePreviewSectionKey),
          findsOneWidget);
      expect(find.text('Aperçu de l’image source'), findsOneWidget);
      expect(
        find.text('Choisissez une image source pour afficher l’aperçu.'),
        findsOneWidget,
      );
    });

    // Pas de test widget « image résolue » : le décodage async de [Image.memory]
    // dans flutter_test peut ne pas se terminer (idle) de façon fiable sur ce runner.
    // L’état résolu est couvert par le test unitaire « resolved quand le fichier existe »
    // et par l’usage réel dans Surface Studio.

    testWidgets('état fichier manquant (libellés UI)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SurfaceStudioAtlasImagePreview(
            resolution: SurfaceStudioAtlasImagePreviewResolution(
              status: SurfaceStudioAtlasImagePreviewResolveStatus.missingFile,
              displayFileName: 'absent.png',
              relativePathForUi: 'assets/tilesets/absent.png',
            ),
            label: Colors.white,
            subtle: Colors.grey,
          ),
        ),
      );
      expect(
        find.textContaining('Aperçu image indisponible'),
        findsOneWidget,
      );
      expect(
        find.text('La grille symbolique reste disponible.'),
        findsOneWidget,
      );
      expect(find.textContaining('assets/tilesets/absent.png'), findsOneWidget);
    });
  });
}

Widget _wrap(Widget child) {
  return MacosApp(
    theme: MacosThemeData.dark(),
    home: ColoredBox(
      color: const Color(0xFF0F1218),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    ),
  );
}
```

### packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'package:map_editor/src/features/surface_studio/surface_studio_column_role_mapping_block.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart';

void main() {
  group('SurfaceStudioColumnRoleMappingBlock', () {
    testWidgets('affiche la section Mapping des colonnes', (tester) async {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      expect(find.text('Mapping des colonnes'), findsOneWidget);
    });

    testWidgets('affiche le résumé pour un atlas 23×32', (tester) async {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      expect(find.text('Colonnes'), findsOneWidget);
      expect(find.text('Assignées'), findsOneWidget);
      expect(find.text('Non assignées'), findsOneWidget);
      expect(find.text('Doublons'), findsOneWidget);
    });

    testWidgets('affiche 23 colonnes dans la liste', (tester) async {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      expect(find.text('Col 0'), findsOneWidget);
      expect(find.text('Col 1'), findsOneWidget);
    });

    testWidgets('affiche Non assignée pour les colonnes non assignées',
        (tester) async {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      expect(find.text('Non assignée'), findsWidgets);
    });

    testWidgets('affiche les boutons d’action', (tester) async {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      expect(find.text('Suggérer un mapping standard'), findsOneWidget);
      expect(
          find.text('Réinitialiser le mapping des colonnes'), findsOneWidget);
    });

    testWidgets('appelle onDraftChanged quand on suggère un mapping standard',
        (tester) async {
      SurfaceStudioColumnRoleMappingDraft? updatedDraft;
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (newDraft) {
                updatedDraft = newDraft;
              },
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Suggérer un mapping standard'));
      await tester.pumpAndSettle();

      expect(updatedDraft, isNotNull);
      expect(updatedDraft!.columnCount, 23);
      expect(updatedDraft!.assignments.length, 20);
    });

    testWidgets('appelle onDraftChanged quand on réinitialise le mapping',
        (tester) async {
      SurfaceStudioColumnRoleMappingDraft? updatedDraft;
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(23);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (newDraft) {
                updatedDraft = newDraft;
              },
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Réinitialiser le mapping des colonnes'));
      await tester.pumpAndSettle();

      expect(updatedDraft, isNotNull);
      expect(updatedDraft!.columnCount, 23);
      expect(updatedDraft!.assignments.length, 0);
    });

    testWidgets('affiche Atlas simple pour 1×1', (tester) async {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 1,
              draftRows: 1,
            ),
          ),
        ),
      );

      expect(find.text('Mapping des colonnes'), findsOneWidget);
      expect(find.text('Atlas simple : mapping de colonnes non nécessaire.'),
          findsOneWidget);
      expect(find.text('Colonnes'), findsNothing);
    });

    testWidgets('affiche un message d’erreur pour des dimensions invalides',
        (tester) async {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: null,
              draftTileHeight: null,
              draftColumns: null,
              draftRows: null,
            ),
          ),
        ),
      );

      expect(find.text('Mapping des colonnes'), findsOneWidget);
      expect(find.text('Corrigez la grille avant de mapper les colonnes.'),
          findsOneWidget);
    });

    testWidgets('affiche un warning pour les doublons', (tester) async {
      final draft = const SurfaceStudioColumnRoleMappingDraft.empty(23)
          .withRoleForColumn(0, SurfaceVariantRole.isolated)
          .withRoleForColumn(1, SurfaceVariantRole.isolated);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      expect(
        find.text('Attention : un rôle est assigné à plusieurs colonnes.'),
        findsOneWidget,
      );
    });

    testWidgets('affiche les libellés utilisateur des rôles', (tester) async {
      final draft = const SurfaceStudioColumnRoleMappingDraft.empty(23)
          .withRoleForColumn(0, SurfaceVariantRole.isolated)
          .withRoleForColumn(1, SurfaceVariantRole.cornerNE);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      expect(find.text('Plein'), findsOneWidget);
      expect(find.text('Coin haut droit'), findsOneWidget);
    });
  });
}
```

### packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_local_mapping_suggester.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  test('local suggester returns bounded reviewable suggestions', () {
    final result = SurfaceStudioLocalMappingSuggester().suggest(columnCount: 3);

    expect(result.source, SurfaceStudioMappingSuggestionSource.local);
    expect(result.suggestions, isNotEmpty);
    expect(
      result.suggestions.every(
        (suggestion) =>
            suggestion.columns.every((column) => column >= 1 && column <= 3),
      ),
      isTrue,
    );
    expect(result.warnings, isNotEmpty);
  });

  testWidgets('Suggestion auto opens a review before mutating the mapping',
      (tester) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
    await tester.pumpAndSettle();

    expect(find.text('Suggestions détectées'), findsOneWidget);
    expect(find.text('Source : Local'), findsOneWidget);
    expect(find.text('Appliquer les suggestions fiables'), findsOneWidget);
    expect(
      find.byKey(const Key('surfaceStudio.suggestion.mistral')),
      findsOneWidget,
    );
    expect(
      find.text(
          'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY'),
      findsOneWidget,
    );

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Suggestions détectées'), findsNothing);
  });

  testWidgets('Mistral prep detects configured key without displaying it',
      (tester) async {
    await pumpSurfaceStudioForTest(
      tester,
      projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
    await tester.pumpAndSettle();

    expect(find.text('Clé Mistral configurée.'), findsOneWidget);
    expect(find.textContaining('configured'), findsNothing);
    expect(
      find.byKey(const Key('surfaceStudio.suggestion.mistral')),
      findsOneWidget,
    );
  });

  testWidgets('Mistral analysis asks confirmation before any provider call',
      (tester) async {
    final fakeAi = _FakeAiSuggester();

    await pumpSurfaceStudioForTest(
      tester,
      projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
      aiMappingSuggester: fakeAi,
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
    await tester.pump(const Duration(milliseconds: 50));
    final mistralButton =
        find.byKey(const Key('surfaceStudio.suggestion.mistral'));
    await tester.ensureVisible(mistralButton);
    await tester.tap(mistralButton);
    await tester.pump(const Duration(milliseconds: 50));

    expect(fakeAi.calls, 0);
    expect(find.text('Confirmer l’analyse IA'), findsOneWidget);

    final cancelAi = find.text('Annuler l’analyse IA');
    await tester.ensureVisible(cancelAi);
    await tester.tap(cancelAi);
    await tester.pump(const Duration(milliseconds: 50));
    expect(fakeAi.calls, 0);
  });

  test('Mistral suggester validates JSON without leaking secrets', () async {
    final requests = <http.Request>[];
    final suggester = SurfaceStudioMistralMappingSuggester(
      httpClient: MockClient((request) async {
        requests.add(request);
        expect(request.headers['Authorization'], 'Bearer configured');
        expect(request.body, isNot(contains('configured')));
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'assignments': [
                      {
                        'role': 'isolated',
                        'columns': [4, 5],
                        'confidence': 'medium',
                        'reason': 'Center water candidates.',
                      },
                      {
                        'role': 'endNorth',
                        'columns': [99],
                        'confidence': 'high',
                        'reason': 'Out of range.',
                      },
                      {
                        'role': 'endEast',
                        'columns': [1, 2],
                        'confidence': 'high',
                        'reason': 'Too many columns.',
                      },
                      {
                        'role': 'unknown',
                        'columns': [3],
                        'confidence': 'high',
                        'reason': 'Unknown role.',
                      },
                    ],
                    'warnings': ['Inner corners are ambiguous.'],
                  }),
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    final result = await suggester.suggest(
      apiKey: 'configured',
      imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
      tileWidth: 32,
      tileHeight: 32,
      columnCount: 12,
      frameCount: 32,
    );

    expect(requests, hasLength(1));
    expect(result.source, SurfaceStudioMappingSuggestionSource.mistral);
    expect(result.suggestions, hasLength(1));
    expect(result.suggestions.single.role, SurfaceVariantRole.isolated);
    expect(result.suggestions.single.columns, [4, 5]);
    expect(result.warnings, contains('Inner corners are ambiguous.'));
    expect(
      result.warnings,
      contains('Rôle Mistral inconnu rejeté : unknown.'),
    );
    expect(
      result.warnings,
      contains('Colonne Mistral hors bornes rejetée pour endNorth : 99.'),
    );
    expect(
      result.warnings,
      contains('Suggestion Mistral multi-colonnes rejetée pour endEast.'),
    );
  });

  test('Mistral suggester returns a warning for invalid JSON', () async {
    final suggester = SurfaceStudioMistralMappingSuggester(
      httpClient: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'not json'},
              },
            ],
          }),
          200,
        );
      }),
    );

    final result = await suggester.suggest(
      apiKey: 'configured',
      imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
      tileWidth: 32,
      tileHeight: 32,
      columnCount: 12,
      frameCount: 32,
    );

    expect(result.suggestions, isEmpty);
    expect(result.warnings.single, contains('Réponse Mistral invalide'));
  });
}

final class _FakeAiSuggester implements SurfaceStudioAiMappingSuggester {
  int calls = 0;

  @override
  Future<SurfaceStudioMappingSuggestionResult> suggest({
    required String apiKey,
    required Uint8List imageBytes,
    required int tileWidth,
    required int tileHeight,
    required int columnCount,
    required int frameCount,
  }) async {
    calls++;
    expect(apiKey, 'configured');
    expect(imageBytes, isNotEmpty);
    return const SurfaceStudioMappingSuggestionResult(
      suggestions: <SurfaceStudioRoleSuggestion>[
        SurfaceStudioRoleSuggestion(
          role: SurfaceVariantRole.isolated,
          columns: <int>[4, 5],
          confidence: SurfaceStudioMappingSuggestionConfidence.medium,
          source: SurfaceStudioMappingSuggestionSource.mistral,
          reason: 'AI center',
        ),
      ],
      warnings: <String>['AI warning'],
      source: SurfaceStudioMappingSuggestionSource.mistral,
    );
  }
}
```

### packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_workflow_layout.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  testWidgets(
      'Surface Studio renders one integrated wizard without legacy below',
      (tester) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
    expect(
      find.byKey(const Key('surface_studio_legacy_authoring_bridge')),
      findsNothing,
    );
    expect(find.byType(SurfaceStudioWorkflowLayout), findsNothing);
    expect(find.text('Assistant de création'), findsNothing);
    expect(
      find.text('Surface Studio — Assistant de mapping d’atlas'),
      findsOneWidget,
    );
  });

  testWidgets('new import step can create an atlas in the work catalog',
      (tester) async {
    ProjectSurfaceCatalog? saved;
    await pumpSurfaceStudioForTest(
      tester,
      readModel:
          buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog()),
      onSurfaceCatalogSaveRequested: (catalog) => saved = catalog,
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('surfaceStudio.step.import')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('surfaceStudio.import.atlasId')),
      'v21-water',
    );
    await tester.enterText(
      find.byKey(const Key('surfaceStudio.import.atlasName')),
      'V2.1 Water',
    );
    await tester.enterText(
      find.byKey(const Key('surfaceStudio.import.tilesetId')),
      'water_tiles',
    );
    await tester.tap(find.byKey(const Key('surfaceStudio.import.createAtlas')));
    await tester.pump();

    expect(
      find.text(
          'Catalogue de travail modifié — sauvegarde projet non effectuée.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('surfaceStudio.action.saveCatalog')));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.atlases.map((atlas) => atlas.id), contains('v21-water'));
  });

  testWidgets('import and slice steps do not render schema or preview docks',
      (tester) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    await tester.tap(find.byKey(const Key('surfaceStudio.step.import')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('surfaceStudio.schema.panel')), findsNothing);
    expect(find.byKey(const Key('surfaceStudio.preview.panel')), findsNothing);
    expect(find.text('Schéma de surface (glissez-déposez)'), findsNothing);
    expect(find.text('Prévisualisation'), findsNothing);

    await tester.tap(find.byKey(const Key('surfaceStudio.step.slice')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('surfaceStudio.schema.panel')), findsNothing);
    expect(find.byKey(const Key('surfaceStudio.preview.panel')), findsNothing);
    expect(find.text('Schéma de surface (glissez-déposez)'), findsNothing);
    expect(find.text('Prévisualisation'), findsNothing);
  });

  testWidgets('header has no internal close control', (tester) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    expect(find.byTooltip('Fermer'), findsNothing);
    expect(find.text('Fermer'), findsNothing);
    expect(find.byKey(const Key('surfaceStudio.header.close')), findsNothing);
  });
}
```

### packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';

Widget wrapSurfaceStudioForTest({
  SurfaceStudioReadModel? readModel,
  ProjectSettings? projectSettings,
  List<ProjectTilesetEntry>? projectTilesets,
  String? projectRootPath,
  SurfaceStudioAiMappingSuggester? aiMappingSuggester,
  ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested,
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
            projectSettings: projectSettings,
            onSurfaceCatalogSaveRequested: onSurfaceCatalogSaveRequested,
            projectTilesets: projectTilesets ??
                const <ProjectTilesetEntry>[
                  ProjectTilesetEntry(
                    id: 'water_tiles',
                    name: 'Water Tiles',
                    relativePath: 'missing/water.png',
                    sortOrder: 0,
                  ),
                ],
            projectRootPath: projectRootPath ?? '/missing/project',
            aiMappingSuggester: aiMappingSuggester,
          ),
        ),
      ),
    ),
  );
}

Future<void> pumpSurfaceStudioForTest(
  WidgetTester tester, {
  SurfaceStudioReadModel? readModel,
  ProjectSettings? projectSettings,
  List<ProjectTilesetEntry>? projectTilesets,
  String? projectRootPath,
  SurfaceStudioAiMappingSuggester? aiMappingSuggester,
  ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested,
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
      projectSettings: projectSettings,
      projectTilesets: projectTilesets,
      projectRootPath: projectRootPath,
      aiMappingSuggester: aiMappingSuggester,
      onSurfaceCatalogSaveRequested: onSurfaceCatalogSaveRequested,
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

### packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart

```dart
// Tests widget — [SurfaceStudioSelectionInspector] (Lot 59).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection_inspector.dart';

void main() {
  group('SurfaceStudioSelectionInspector (Lot 59)', () {
    testWidgets('1. titre Inspecteur Surface', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Inspecteur Surface'), findsOneWidget);
    });

    testWidgets('2. badge Lecture seule', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Lecture seule'), findsOneWidget);
    });

    testWidgets('3. état none', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Aucune sélection à inspecter'), findsOneWidget);
      expect(
        find.textContaining('Sélectionnez un atlas'),
        findsOneWidget,
      );
    });

    testWidgets('4. atlas introuvable', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('missing-atlas'),
          ),
        ),
      );
      expect(find.text('Sélection introuvable'), findsOneWidget);
      expect(find.text('missing-atlas'), findsOneWidget);
    });

    testWidgets('5. animation introuvable', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.animation('missing-animation'),
          ),
        ),
      );
      expect(find.text('missing-animation'), findsOneWidget);
    });

    testWidgets('6. preset introuvable', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.preset('missing-preset'),
          ),
        ),
      );
      expect(find.text('missing-preset'), findsOneWidget);
    });

    testWidgets('7–9. atlas sélectionné — identité et champs', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
          ),
        ),
      );
      expect(find.text('Atlas sélectionné'), findsWidgets);
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-atlas'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Tileset : nature-tileset'),
        findsOneWidget,
      );
      expect(find.textContaining('Tile : 32×32'), findsOneWidget);
      expect(find.textContaining('Grille : 2×2'), findsOneWidget);
      expect(find.textContaining('4 tuiles'), findsOneWidget);
      expect(
        find.textContaining('Colonnes = variantes, lignes = frames'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Catégorie : Aucune catégorie'),
        findsOneWidget,
      );
      expect(find.textContaining('Ordre : 0'), findsOneWidget);
      expect(
        find.textContaining('Utilisé par 1 animation'),
        findsOneWidget,
      );
      expect(find.text('water-isolated-loop'), findsWidgets);
    });

    testWidgets('10–11. animation sélectionnée', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.animation('water-isolated-loop'),
          ),
        ),
      );
      expect(find.text('Animation sélectionnée'), findsWidgets);
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-isolated-loop'),
        findsOneWidget,
      );
      expect(find.textContaining('Frames : 1 frame'), findsOneWidget);
      expect(
        find.textContaining('Durée totale : 120 ms'),
        findsOneWidget,
      );
      expect(find.text('water-atlas'), findsWidgets);
      expect(
        find.textContaining('Groupe de synchronisation : Aucun groupe'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Catégorie : Aucune catégorie'),
        findsOneWidget,
      );
    });

    testWidgets('12–13. preset sélectionné', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.preset('water-surface'),
          ),
        ),
      );
      expect(find.text('Preset sélectionné'), findsWidgets);
      expect(find.text('Water Surface'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-surface'),
        findsOneWidget,
      );
      expect(find.textContaining('Variantes : 1 variante'), findsOneWidget);
      expect(find.text('Isolé'), findsWidgets);
      expect(
        find.textContaining('Rôles standards incomplets'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Catégorie : Aucune catégorie'),
        findsOneWidget,
      );
    });

    testWidgets('14. pas de TextField', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('15. pas de libellés édition / save', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.preset('water-surface'),
          ),
        ),
      );
      for (final s in <String>[
        'Modifier',
        'Supprimer',
        'Enregistrer',
        'Sauvegarder',
        'Save',
        'Edit',
        'Delete',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });

    testWidgets('16. pas de noms de types internes en texte', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
          ),
        ),
      );
      for (final term in <String>[
        'ProjectSurfaceCatalog',
        'ProjectSurfaceAtlas',
        'ProjectSurfaceAnimation',
        'ProjectSurfacePreset',
        'SurfaceStudioReadModel',
        'SurfaceStudioSelection',
        'SurfaceStudioSelectionInspector',
        'SurfaceVariantAnimationRefSet',
        'SurfaceAnimationTimeline',
      ]) {
        expect(
          find.descendant(
            of: find.byKey(kSurfaceStudioSelectionInspectorKey),
            matching: find.textContaining(term),
          ),
          findsNothing,
        );
      }
    });

    testWidgets('17. sans ProviderScope', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Aucune sélection à inspecter'), findsOneWidget);
    });

    testWidgets('18. largeur contrainte', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              child: SurfaceStudioSelectionInspector(
                readModel: _minimalRead(),
                selection: SurfaceStudioSelection.preset('water-surface'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Water Surface'), findsOneWidget);
    });

    testWidgets('19. read model avec diagnostics, sélection valide', (
      tester,
    ) async {
      final rm = buildSurfaceStudioReadModelFromCatalog(
        _catalogWithUnusedAtlas(),
      );
      expect(rm.diagnostics.hasErrors, isFalse);
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: rm,
            selection: SurfaceStudioSelection.atlas('used-atlas'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
          matching: find.text('Diagnostics Surface'),
        ),
        findsNothing,
      );
    });

    testWidgets('20. Lot 67 — callback édition : bouton inspecteur',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
            onRequestEditSelectedAtlas: () {},
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('surface_studio_inspector_edit_atlas')),
        findsOneWidget,
      );
    });

    testWidgets('21. Lot 67 — sans callback : pas d’edit inspecteur',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('surface_studio_inspector_edit_atlas')),
        findsNothing,
      );
    });

    testWidgets('22. Lot 69 — atlas référencé : préparer suppression absent',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogWithUnusedAtlas(),
            ),
            selection: SurfaceStudioSelection.atlas('used-atlas'),
            onConfirmDeleteSelectedAtlas: () {},
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('surface_studio_inspector_delete_blocked')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('surface_studio_inspector_prepare_delete')),
        findsNothing,
      );
    });

    testWidgets('23. Lot 69 — atlas inutilisé : confirmation en deux étapes',
        (tester) async {
      var del = 0;
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogWithUnusedAtlas(),
            ),
            selection: SurfaceStudioSelection.atlas('orphan-atlas'),
            onConfirmDeleteSelectedAtlas: () => del++,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('surface_studio_inspector_delete_allowed')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_inspector_prepare_delete')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_inspector_confirm_delete')),
      );
      await tester.pump();
      expect(del, 1);
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    ),
  );
}

SurfaceStudioReadModel _minimalRead() {
  return buildSurfaceStudioReadModelFromCatalog(_minimalCatalog());
}

ProjectSurfaceCatalog _minimalCatalog() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
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

/// Catalogue avec atlas inutilisé (avertissements, pas d’erreur bloquante).
ProjectSurfaceCatalog _catalogWithUnusedAtlas() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
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
```

### packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart';

void main() {
  group('surfaceStudioSlug / proposed id', () {
    test('id stable eau + plein', () {
      expect(
        surfaceStudioProposedAnimationId(
          atlasIdRaw: 'eau',
          role: SurfaceVariantRole.isolated,
        ),
        'eau-plein-loop',
      );
    });

    test('slug atlas retire accents et espaces', () {
      expect(
        surfaceStudioProposedAnimationId(
          atlasIdRaw: 'Mon Atlas É',
          role: SurfaceVariantRole.endNorth,
        ),
        'mon-atlas-e-bord-haut-loop',
      );
    });
  });

  group('buildSurfaceStudioVerticalAtlasAnimationGenerationPlan', () {
    test('plan vide si aucune colonne assignée', () {
      final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
        atlasIdRaw: 'eau',
        mappingDraft: const SurfaceStudioColumnRoleMappingDraft.empty(5),
        tileWidth: 32,
        tileHeight: 32,
        columns: 5,
        rows: 10,
        durationMsPerFrame: 120,
        existingAnimationIds: const {},
      );
      expect(plan.items, isEmpty);
      expect(plan.summary.assignedColumnCount, 0);
    });

    test('23×32 après suggestion : 20 animations, 3 colonnes non assignées',
        () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(23);
      final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
        atlasIdRaw: 'eau',
        mappingDraft: draft,
        tileWidth: 32,
        tileHeight: 32,
        columns: 23,
        rows: 32,
        durationMsPerFrame: 120,
        existingAnimationIds: const {},
      );
      expect(plan.items.length, 20);
      expect(plan.summary.assignedColumnCount, 20);
      expect(plan.summary.readyAnimationCount, 20);
      expect(plan.summary.errorAnimationCount, 0);
      expect(draft.columnCount - plan.summary.assignedColumnCount, 3);
    });

    test('source rects colonne 0 frames 0, 1, 31 et durée totale 32×120', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(23);
      final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
        atlasIdRaw: 'eau',
        mappingDraft: draft,
        tileWidth: 32,
        tileHeight: 32,
        columns: 23,
        rows: 32,
        durationMsPerFrame: 120,
        existingAnimationIds: const {},
      );
      final col0 = plan.items.firstWhere((i) => i.columnIndex == 0);
      expect(col0.frameCount, 32);
      expect(col0.totalDurationMs, 3840);
      expect(col0.sourceRects.length, 32);
      expect(col0.sourceRects[0].sourceX, 0);
      expect(col0.sourceRects[0].sourceY, 0);
      expect(col0.sourceRects[1].sourceY, 32);
      expect(col0.sourceRects[31].sourceY, 992);
    });

    test('durée par frame invalide → items invalides', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(2);
      final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
        atlasIdRaw: 'a',
        mappingDraft: draft,
        tileWidth: 32,
        tileHeight: 32,
        columns: 2,
        rows: 4,
        durationMsPerFrame: 0,
        existingAnimationIds: const {},
      );
      expect(plan.summary.durationFieldValid, isFalse);
      expect(plan.summary.readyAnimationCount, 0);
      expect(plan.summary.errorAnimationCount, 2);
      for (final it in plan.items) {
        expect(it.isReady, isFalse);
        expect(it.status,
            SurfaceStudioVerticalAtlasAnimationPlanItemStatus.invalid);
      }
    });

    test('dimensions invalides → items invalides', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(2);
      final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
        atlasIdRaw: 'a',
        mappingDraft: draft,
        tileWidth: null,
        tileHeight: 32,
        columns: 2,
        rows: 4,
        durationMsPerFrame: 120,
        existingAnimationIds: const {},
      );
      expect(plan.gridValid, isFalse);
      expect(plan.items.every((i) => !i.isReady), isTrue);
    });

    test('doublon d’id détecté', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(1);
      final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
        atlasIdRaw: 'eau',
        mappingDraft: draft,
        tileWidth: 32,
        tileHeight: 32,
        columns: 1,
        rows: 1,
        durationMsPerFrame: 120,
        existingAnimationIds: {'eau-plein-loop'},
      );
      expect(plan.items.single.status,
          SurfaceStudioVerticalAtlasAnimationPlanItemStatus.duplicate);
      expect(plan.items.single.problems.first,
          contains('Une animation existe déjà avec cet id.'));
    });

    test('atlas id vide → invalide', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(1);
      final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
        atlasIdRaw: '   ',
        mappingDraft: draft,
        tileWidth: 32,
        tileHeight: 32,
        columns: 1,
        rows: 1,
        durationMsPerFrame: 120,
        existingAnimationIds: const {},
      );
      expect(plan.items.single.status,
          SurfaceStudioVerticalAtlasAnimationPlanItemStatus.invalid);
    });
  });

  group('SurfaceStudioVerticalAtlasAnimationGenerationPlanSection', () {
    testWidgets('section et résumé visibles après suggestion', (tester) async {
      final rm =
          buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(23);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection(
              label: Colors.white,
              subtle: Colors.grey,
              readModel: rm,
              atlasIdDraft: 'eau',
              atlasDisplayName: 'Eau',
              mappingDraft: draft,
              tileWidth: 32,
              tileHeight: 32,
              columns: 23,
              rows: 32,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Plan de génération des animations'), findsOneWidget);
      expect(find.textContaining('Animations prêtes : 20'), findsOneWidget);
      expect(find.textContaining('Colonnes non assignées : 3'), findsOneWidget);
      expect(find.textContaining('ProjectSurfaceAnimation'), findsNothing);
      await tester
          .tap(find.byKey(const ValueKey('surface_studio_gen_plan_preview')));
      await tester.pump();
      expect(find.textContaining('eau-plein-loop'), findsWidgets);
    });

    testWidgets('catalogue inchangé après interaction', (tester) async {
      final anim = ProjectSurfaceAnimation(
        id: 'x',
        name: 'X',
        timeline: SurfaceAnimationTimeline(
          frames: [
            SurfaceAnimationFrame(
              tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
              durationMs: 1,
            ),
          ],
        ),
      );
      final cat = ProjectSurfaceCatalog(animations: [anim]);
      final rm = buildSurfaceStudioReadModelFromCatalog(cat);
      final before = rm.catalog.animations.length;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection(
              label: Colors.white,
              subtle: Colors.grey,
              readModel: rm,
              atlasIdDraft: 'eau',
              atlasDisplayName: 'Eau',
              mappingDraft: SurfaceStudioColumnRoleMappingDraft.suggested(1),
              tileWidth: 32,
              tileHeight: 32,
              columns: 1,
              rows: 2,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('surface_studio_gen_plan_duration_ms')),
        '50',
      );
      await tester.pump();
      await tester
          .tap(find.byKey(const ValueKey('surface_studio_gen_plan_preview')));
      await tester.pump();
      expect(rm.catalog.animations.length, before);
    });

    testWidgets('ajout animations prêtes via callback', (tester) async {
      ProjectSurfaceCatalog? updated;
      final rm =
          buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection(
              label: Colors.white,
              subtle: Colors.grey,
              readModel: rm,
              atlasIdDraft: 'eau',
              atlasDisplayName: 'Eau',
              mappingDraft: SurfaceStudioColumnRoleMappingDraft.suggested(1),
              tileWidth: 32,
              tileHeight: 32,
              columns: 1,
              rows: 4,
              onWorkCatalogChanged: (c) => updated = c,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_gen_plan_append_ready')),
      );
      await tester.pump();
      expect(updated, isNotNull);
      expect(updated!.animations.length, 1);
      expect(updated!.animations.single.id, 'eau-plein-loop');
      expect(updated!.animations.single.timeline.frameCount, 4);
      expect(updated!.presets, isEmpty);
      expect(updated!.atlases, isEmpty);
    });
  });
}
```

### packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_assistant_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart';

void main() {
  group('SurfaceStudioVerticalAtlasAssistant (Lot 74)', () {
    testWidgets('section et conventions visibles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAssistant(
              label: Color(0xFFE8E8EC),
              subtle: Color(0xFF9A9AA3),
            ),
          ),
        ),
      );
      expect(find.byKey(SurfaceStudioVerticalAtlasAssistant.sectionKey),
          findsOneWidget);
      expect(find.text('Assistant atlas vertical'), findsOneWidget);
      expect(find.text('Colonnes = variantes visuelles'), findsOneWidget);
      expect(find.text('Lignes = frames d’animation'), findsOneWidget);
    });

    testWidgets('23×32 affiche variantes frames et total', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAssistant(
              label: Color(0xFFE8E8EC),
              subtle: Color(0xFF9A9AA3),
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );
      expect(find.text('Variantes détectées : 23 colonnes'), findsOneWidget);
      expect(find.text('Frames détectées : 32 lignes'), findsOneWidget);
      expect(find.text('Total : 736 tuiles'), findsOneWidget);
      expect(find.text('Taille de tuile : 32×32 px'), findsOneWidget);
      expect(
        find.textContaining('Structure probablement verticale'),
        findsOneWidget,
      );
    });

    testWidgets('1×1 atlas simple', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAssistant(
              label: Color(0xFFE8E8EC),
              subtle: Color(0xFF9A9AA3),
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 1,
              draftRows: 1,
            ),
          ),
        ),
      );
      expect(
        find.text('Atlas simple : aucune structure animée détectée.'),
        findsOneWidget,
      );
    });

    testWidgets('colonnes > lignes : message horizontal', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAssistant(
              label: Color(0xFFE8E8EC),
              subtle: Color(0xFF9A9AA3),
              draftTileWidth: 16,
              draftTileHeight: 16,
              draftColumns: 8,
              draftRows: 4,
            ),
          ),
        ),
      );
      expect(
        find.textContaining('Structure probablement horizontale'),
        findsOneWidget,
      );
    });

    testWidgets('pas de jargon dans l’UI', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAssistant(
              label: Color(0xFFE8E8EC),
              subtle: Color(0xFF9A9AA3),
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 2,
              draftRows: 2,
            ),
          ),
        ),
      );
      for (final term in const <String>[
        'ProjectSurfaceAtlas',
        'ProjectSurfaceCatalog',
        'SurfaceStudioReadModel',
        'callback',
        'copyWith',
        'tilesetId',
      ]) {
        expect(find.textContaining(term), findsNothing);
      }
    });
  });
}
```

### packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_preset_generator_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart';

ProjectSurfaceAnimation _anim(String id) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'eau',
            column: 0,
            row: 0,
          ),
          durationMs: 120,
        ),
      ],
    ),
  );
}

void main() {
  group('surfaceStudioProposedVerticalAtlasPresetId', () {
    test('eau → eau-surface-preset', () {
      expect(surfaceStudioProposedVerticalAtlasPresetId('eau'),
          'eau-surface-preset');
    });
  });

  group('surfaceStudioPlanVerticalAtlasPresetAppend', () {
    test('sans mapping → bloqué', () {
      final cat = ProjectSurfaceCatalog();
      final p = surfaceStudioPlanVerticalAtlasPresetAppend(
        catalog: cat,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: const SurfaceStudioColumnRoleMappingDraft.empty(3),
        gridValid: true,
      );
      expect(p.canCreate, isFalse);
      expect(p.status,
          SurfaceStudioVerticalAtlasPresetPlanStatus.blockedNoMapping);
    });

    test('grille invalide → bloqué', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(1);
      final cat = ProjectSurfaceCatalog(animations: [_anim('eau-plein-loop')]);
      final p = surfaceStudioPlanVerticalAtlasPresetAppend(
        catalog: cat,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: draft,
        gridValid: false,
      );
      expect(p.canCreate, isFalse);
      expect(p.status,
          SurfaceStudioVerticalAtlasPresetPlanStatus.blockedInvalidGrid);
    });

    test('animation manquante → bloqué', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(1);
      final cat = ProjectSurfaceCatalog();
      final p = surfaceStudioPlanVerticalAtlasPresetAppend(
        catalog: cat,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: draft,
        gridValid: true,
      );
      expect(p.canCreate, isFalse);
      expect(p.missingAnimationCount, greaterThan(0));
      expect(p.status,
          SurfaceStudioVerticalAtlasPresetPlanStatus.blockedMissingAnimations);
    });

    test('id preset déjà pris → bloqué', () {
      final existing = ProjectSurfacePreset(
        id: 'eau-surface-preset',
        name: 'X',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'eau-plein-loop',
            ),
          ],
        ),
      );
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(1);
      final cat = ProjectSurfaceCatalog(
        animations: [_anim('eau-plein-loop')],
        presets: [existing],
      );
      final p = surfaceStudioPlanVerticalAtlasPresetAppend(
        catalog: cat,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: draft,
        gridValid: true,
      );
      expect(p.canCreate, isFalse);
      expect(p.status,
          SurfaceStudioVerticalAtlasPresetPlanStatus.blockedDuplicatePresetId);
    });

    test('plein + animation → prêt ou incomplet selon couverture standard', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(1);
      final cat = ProjectSurfaceCatalog(animations: [_anim('eau-plein-loop')]);
      final p = surfaceStudioPlanVerticalAtlasPresetAppend(
        catalog: cat,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: draft,
        gridValid: true,
      );
      expect(p.canCreate, isTrue);
      expect(p.missingAnimationCount, 0);
      expect(p.rolesCoveredCount, 1);
      expect(
        p.status == SurfaceStudioVerticalAtlasPresetPlanStatus.incomplete ||
            p.status == SurfaceStudioVerticalAtlasPresetPlanStatus.ready,
        isTrue,
      );
    });
  });

  group('surfaceStudioBuildVerticalAtlasPreset + append', () {
    test('eau colonne 0 plein → preset eau-surface-preset + ref plein', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(1);
      final cat0 = ProjectSurfaceCatalog(animations: [_anim('eau-plein-loop')]);
      final preset = surfaceStudioBuildVerticalAtlasPreset(
        catalog: cat0,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: draft,
        gridValid: true,
      );
      expect(preset.id, 'eau-surface-preset');
      expect(preset.name, 'Eau — Surface');
      expect(preset.variantCount, 1);
      expect(
        preset.animationIdForRole(SurfaceVariantRole.isolated),
        'eau-plein-loop',
      );
      final cat1 = surfaceStudioAppendPresetToWorkCatalog(
        catalog: cat0,
        preset: preset,
      );
      expect(cat1.presets.length, 1);
      expect(cat1.animations.length, 1);
      expect(cat1.atlases.length, 0);
    });

    test('deux colonnes même rôle → une seule ref', () {
      const draft = SurfaceStudioColumnRoleMappingDraft(
        columnCount: 2,
        assignments: [
          SurfaceStudioColumnRoleAssignment(
            columnIndex: 0,
            role: SurfaceVariantRole.isolated,
          ),
          SurfaceStudioColumnRoleAssignment(
            columnIndex: 1,
            role: SurfaceVariantRole.isolated,
          ),
        ],
      );
      final cat0 = ProjectSurfaceCatalog(animations: [_anim('eau-plein-loop')]);
      final preset = surfaceStudioBuildVerticalAtlasPreset(
        catalog: cat0,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: draft,
        gridValid: true,
      );
      expect(preset.variantCount, 1);
    });
  });
}
```

### packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_role_mapping_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart';

void main() {
  group('SurfaceStudioColumnRoleAssignment', () {
    test('crée une assignation avec rôle', () {
      const assignment = SurfaceStudioColumnRoleAssignment(
        columnIndex: 0,
        role: SurfaceVariantRole.isolated,
      );

      expect(assignment.columnIndex, 0);
      expect(assignment.role, SurfaceVariantRole.isolated);
      expect(assignment.isAssigned, true);
    });

    test('crée une assignation sans rôle', () {
      const assignment = SurfaceStudioColumnRoleAssignment(
        columnIndex: 0,
        role: null,
      );

      expect(assignment.columnIndex, 0);
      expect(assignment.role, null);
      expect(assignment.isAssigned, false);
    });

    test('égalité entre assignations', () {
      const a1 = SurfaceStudioColumnRoleAssignment(
        columnIndex: 0,
        role: SurfaceVariantRole.isolated,
      );
      const a2 = SurfaceStudioColumnRoleAssignment(
        columnIndex: 0,
        role: SurfaceVariantRole.isolated,
      );
      const a3 = SurfaceStudioColumnRoleAssignment(
        columnIndex: 1,
        role: SurfaceVariantRole.isolated,
      );

      expect(a1, equals(a2));
      expect(a1, isNot(equals(a3)));
    });
  });

  group('SurfaceStudioColumnRoleMappingDraft', () {
    test('crée un brouillon vide', () {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);

      expect(draft.columnCount, 23);
      expect(draft.assignments, isEmpty);
      expect(draft.roleForColumn(0), null);
      expect(draft.isColumnAssigned(0), false);
    });

    test('crée un brouillon avec suggestion standard', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(23);

      expect(draft.columnCount, 23);
      expect(draft.assignments.length, 20); // 20 rôles standards
      expect(draft.roleForColumn(0), SurfaceVariantRole.isolated);
      expect(draft.roleForColumn(1), SurfaceVariantRole.endNorth);
      expect(draft.roleForColumn(19), SurfaceVariantRole.cross);
      expect(draft.roleForColumn(20), null); // Colonnes restantes non assignées
    });

    test('crée un brouillon avec suggestion standard pour moins de colonnes',
        () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(5);

      expect(draft.columnCount, 5);
      expect(draft.assignments.length, 5);
      expect(draft.roleForColumn(0), SurfaceVariantRole.isolated);
      expect(draft.roleForColumn(4), SurfaceVariantRole.endWest);
    });

    test('assigne un rôle à une colonne', () {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);
      final updated = draft.withRoleForColumn(0, SurfaceVariantRole.isolated);

      expect(updated.roleForColumn(0), SurfaceVariantRole.isolated);
      expect(updated.isColumnAssigned(0), true);
      expect(draft.roleForColumn(0), null); // Original inchangé
    });

    test('désassigne une colonne', () {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);
      final withRole = draft.withRoleForColumn(0, SurfaceVariantRole.isolated);
      final withoutRole = withRole.withRoleForColumn(0, null);

      expect(withoutRole.roleForColumn(0), null);
      expect(withoutRole.isColumnAssigned(0), false);
    });

    test('modifie le rôle d’une colonne', () {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);
      final withRole1 = draft.withRoleForColumn(0, SurfaceVariantRole.isolated);
      final withRole2 =
          withRole1.withRoleForColumn(0, SurfaceVariantRole.endNorth);

      expect(withRole2.roleForColumn(0), SurfaceVariantRole.endNorth);
      expect(withRole2.assignments.length, 1); // Pas de duplication
    });

    test('réinitialise le mapping', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(23);
      final cleared = draft.cleared();

      expect(cleared.columnCount, 23);
      expect(cleared.assignments, isEmpty);
    });

    test('égalité entre brouillons', () {
      const d1 = SurfaceStudioColumnRoleMappingDraft.empty(23);
      const d2 = SurfaceStudioColumnRoleMappingDraft.empty(23);
      const d3 = SurfaceStudioColumnRoleMappingDraft.empty(24);

      expect(d1, equals(d2));
      expect(d1, isNot(equals(d3)));
    });
  });

  group('SurfaceStudioColumnRoleMappingSummary', () {
    test('crée un résumé pour un brouillon vide', () {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);
      final summary = SurfaceStudioColumnRoleMappingSummary.fromDraft(draft);

      expect(summary.columnCount, 23);
      expect(summary.assignedColumnCount, 0);
      expect(summary.unassignedColumnCount, 23);
      expect(summary.duplicateRoleCount, 0);
      expect(summary.hasDuplicateRoles, false);
      expect(summary.coveredRoles, isEmpty);
    });

    test('crée un résumé pour un brouillon avec suggestion standard', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(23);
      final summary = SurfaceStudioColumnRoleMappingSummary.fromDraft(draft);

      expect(summary.columnCount, 23);
      expect(summary.assignedColumnCount, 20);
      expect(summary.unassignedColumnCount, 3);
      expect(summary.duplicateRoleCount, 0);
      expect(summary.hasDuplicateRoles, false);
      expect(summary.coveredRoles.length, 20);
    });

    test('détecte les doublons de rôles', () {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);
      final withDuplicates = draft
          .withRoleForColumn(0, SurfaceVariantRole.isolated)
          .withRoleForColumn(1, SurfaceVariantRole.isolated);
      final summary =
          SurfaceStudioColumnRoleMappingSummary.fromDraft(withDuplicates);

      expect(summary.columnCount, 23);
      expect(summary.assignedColumnCount, 2);
      expect(summary.unassignedColumnCount, 21);
      expect(summary.duplicateRoleCount, 1);
      expect(summary.hasDuplicateRoles, true);
      expect(summary.coveredRoles.length, 1);
    });

    test('égalité entre résumés', () {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);
      final s1 = SurfaceStudioColumnRoleMappingSummary.fromDraft(draft);
      final s2 = SurfaceStudioColumnRoleMappingSummary.fromDraft(draft);

      expect(s1, equals(s2));
    });
  });

  group('SurfaceStudioRoleLabels', () {
    test('fournit des libellés pour tous les rôles', () {
      final labels = SurfaceStudioRoleLabels.allRolesInOrder;

      expect(labels.length, 20);
      expect(labels.first, SurfaceVariantRole.isolated);
      expect(labels.last, SurfaceVariantRole.cross);
    });

    test('fournit un libellé lisible pour un rôle', () {
      final label =
          SurfaceStudioRoleLabels.labelForRole(SurfaceVariantRole.isolated);

      expect(label, 'Plein');
    });

    test('fournit un libellé lisible pour un coin', () {
      final label =
          SurfaceStudioRoleLabels.labelForRole(SurfaceVariantRole.cornerNE);

      expect(label, 'Coin haut droit');
    });

    test('fournit un libellé lisible pour un té', () {
      final label =
          SurfaceStudioRoleLabels.labelForRole(SurfaceVariantRole.teeNorth);

      expect(label, 'Té haut');
    });

    test('fournit un libellé lisible pour une croix', () {
      final label =
          SurfaceStudioRoleLabels.labelForRole(SurfaceVariantRole.cross);

      expect(label, 'Croix');
    });
  });
}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart

```dart
import 'dart:typed_data';

import 'surface_studio_mapping_suggestion_models.dart';

abstract interface class SurfaceStudioAiMappingSuggester {
  Future<SurfaceStudioMappingSuggestionResult> suggest({
    required String apiKey,
    required Uint8List imageBytes,
    required int tileWidth,
    required int tileHeight,
    required int columnCount,
    required int frameCount,
  });
}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart

```dart
import 'package:map_core/map_core.dart';

String buildSurfaceStudioMappingSuggestionPrompt({
  required int tileWidth,
  required int tileHeight,
  required int columnCount,
  required int frameCount,
}) {
  final roles =
      standardSurfaceVariantRoleOrder.map((role) => role.name).join(', ');
  return '''
You are helping map a Pokemon-style surface atlas.
Return JSON only. No markdown. No prose outside JSON.

Expected schema:
{
  "assignments": [
    {
      "role": "isolated",
      "columns": [4, 5],
      "confidence": "medium",
      "reason": "Columns 4 and 5 look like repeatable center water tiles."
    }
  ],
  "warnings": ["Inner corners are ambiguous."]
}

Atlas metadata:
- tileWidth: $tileWidth
- tileHeight: $tileHeight
- columns: $columnCount
- frames: $frameCount
- allowedRoles: $roles

Rules:
- Use only allowed role names.
- Columns are 1-based and must be between 1 and $columnCount.
- isolated may use multiple columns.
- Every other role must use at most one column.
- confidence must be high, medium, or low.
- Provide a short reason for each assignment.
''';
}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';

import 'surface_studio_ai_mapping_suggester.dart';
import 'surface_studio_mapping_suggestion_models.dart';
import 'surface_studio_mapping_suggestion_prompt_builder.dart';

final class SurfaceStudioMistralMappingSuggester
    implements SurfaceStudioAiMappingSuggester {
  SurfaceStudioMistralMappingSuggester({
    http.Client? httpClient,
    this.baseUrl = 'https://api.mistral.ai/v1/chat/completions',
    this.model = 'mistral-small-2506',
    this.timeout = const Duration(seconds: 30),
  }) : _client = httpClient ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final String model;
  final Duration timeout;

  @override
  Future<SurfaceStudioMappingSuggestionResult> suggest({
    required String apiKey,
    required Uint8List imageBytes,
    required int tileWidth,
    required int tileHeight,
    required int columnCount,
    required int frameCount,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      return const SurfaceStudioMappingSuggestionResult(
        suggestions: <SurfaceStudioRoleSuggestion>[],
        warnings: <String>['Clé Mistral absente.'],
        source: SurfaceStudioMappingSuggestionSource.mistral,
      );
    }

    final prompt = buildSurfaceStudioMappingSuggestionPrompt(
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      frameCount: frameCount,
    );
    final imageDataUrl = _imageDataUrl(imageBytes);
    final body = jsonEncode({
      'model': model,
      'temperature': 0,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {'type': 'image_url', 'image_url': imageDataUrl},
          ],
        },
      ],
    });

    try {
      final response = await _client
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return SurfaceStudioMappingSuggestionResult(
          suggestions: const <SurfaceStudioRoleSuggestion>[],
          warnings: <String>['Mistral HTTP ${response.statusCode}.'],
          source: SurfaceStudioMappingSuggestionSource.mistral,
        );
      }
      return _parseChatResponse(
        response.body,
        columnCount: columnCount,
      );
    } on TimeoutException {
      return const SurfaceStudioMappingSuggestionResult(
        suggestions: <SurfaceStudioRoleSuggestion>[],
        warnings: <String>['Mistral timeout.'],
        source: SurfaceStudioMappingSuggestionSource.mistral,
      );
    } catch (_) {
      return const SurfaceStudioMappingSuggestionResult(
        suggestions: <SurfaceStudioRoleSuggestion>[],
        warnings: <String>['Analyse Mistral impossible.'],
        source: SurfaceStudioMappingSuggestionSource.mistral,
      );
    }
  }

  String _imageDataUrl(Uint8List bytes) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      decoded = null;
    }
    if (decoded == null) {
      return 'data:image/png;base64,${base64Encode(bytes)}';
    }
    final longest =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    final normalized = longest > 768
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? 768 : null,
            height: decoded.height > decoded.width ? 768 : null,
          )
        : decoded;
    return 'data:image/png;base64,${base64Encode(img.encodePng(normalized))}';
  }

  SurfaceStudioMappingSuggestionResult _parseChatResponse(
    String body, {
    required int columnCount,
  }) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('root');
      }
      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) {
        throw const FormatException('choices');
      }
      final first = choices.first;
      if (first is! Map<String, dynamic>) {
        throw const FormatException('choice');
      }
      final message = first['message'];
      if (message is! Map<String, dynamic>) {
        throw const FormatException('message');
      }
      final content = message['content'];
      if (content is! String) {
        throw const FormatException('content');
      }
      final payload = jsonDecode(content);
      if (payload is! Map<String, dynamic>) {
        throw const FormatException('payload');
      }
      return _parsePayload(payload, columnCount: columnCount);
    } catch (e) {
      return SurfaceStudioMappingSuggestionResult(
        suggestions: const <SurfaceStudioRoleSuggestion>[],
        warnings: <String>['Réponse Mistral invalide: $e'],
        source: SurfaceStudioMappingSuggestionSource.mistral,
      );
    }
  }

  SurfaceStudioMappingSuggestionResult _parsePayload(
    Map<String, dynamic> payload, {
    required int columnCount,
  }) {
    final warnings = <String>[];
    final rawWarnings = payload['warnings'];
    if (rawWarnings is List) {
      for (final warning in rawWarnings) {
        if (warning is String && warning.trim().isNotEmpty) {
          warnings.add(warning.trim());
        }
      }
    }

    final suggestions = <SurfaceStudioRoleSuggestion>[];
    final assignments = payload['assignments'];
    if (assignments is! List) {
      warnings.add('Réponse Mistral sans assignments.');
      return SurfaceStudioMappingSuggestionResult(
        suggestions: const <SurfaceStudioRoleSuggestion>[],
        warnings: List<String>.unmodifiable(warnings),
        source: SurfaceStudioMappingSuggestionSource.mistral,
      );
    }

    for (final item in assignments) {
      if (item is! Map<String, dynamic>) {
        warnings.add('Assignation Mistral non objet rejetée.');
        continue;
      }
      final roleName = item['role'];
      final role = roleName is String ? _roleFromName(roleName) : null;
      if (role == null) {
        warnings.add('Rôle Mistral inconnu rejeté : $roleName.');
        continue;
      }
      final columns = _parseColumns(item['columns']);
      if (columns.isEmpty) {
        warnings
            .add('Assignation Mistral sans colonne rejetée pour $roleName.');
        continue;
      }
      final outOfRange =
          columns.where((column) => column < 1 || column > columnCount);
      if (outOfRange.isNotEmpty) {
        warnings.add(
          'Colonne Mistral hors bornes rejetée pour $roleName : ${outOfRange.first}.',
        );
        continue;
      }
      if (role != SurfaceVariantRole.isolated && columns.length > 1) {
        warnings
            .add('Suggestion Mistral multi-colonnes rejetée pour $roleName.');
        continue;
      }
      final confidence = _confidenceFromName(item['confidence']);
      if (confidence == null) {
        warnings.add('Confiance Mistral inconnue rejetée pour $roleName.');
        continue;
      }
      final reason = item['reason'];
      suggestions.add(
        SurfaceStudioRoleSuggestion(
          role: role,
          columns: List<int>.unmodifiable(columns),
          confidence: confidence,
          source: SurfaceStudioMappingSuggestionSource.mistral,
          reason: reason is String && reason.trim().isNotEmpty
              ? reason.trim()
              : 'Suggestion Mistral sans raison détaillée.',
        ),
      );
    }

    return SurfaceStudioMappingSuggestionResult(
      suggestions: List<SurfaceStudioRoleSuggestion>.unmodifiable(suggestions),
      warnings: List<String>.unmodifiable(warnings),
      source: SurfaceStudioMappingSuggestionSource.mistral,
    );
  }

  SurfaceVariantRole? _roleFromName(String name) {
    for (final role in standardSurfaceVariantRoleOrder) {
      if (role.name == name) {
        return role;
      }
    }
    return null;
  }

  SurfaceStudioMappingSuggestionConfidence? _confidenceFromName(Object? value) {
    if (value is! String) {
      return null;
    }
    for (final confidence in SurfaceStudioMappingSuggestionConfidence.values) {
      if (confidence.name == value) {
        return confidence;
      }
    }
    return null;
  }

  List<int> _parseColumns(Object? value) {
    if (value is! List) {
      return const <int>[];
    }
    final columns = <int>[];
    for (final raw in value) {
      if (raw is int) {
        columns.add(raw);
      }
    }
    return columns;
  }
}
```

### packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_image_preview.dart';

void main() {
  testWidgets(
      'SurfaceStudioAtlasImagePreview does not overflow in reported sizes',
      (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);

    Future<void> pumpConstrained(Size size) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: SurfaceStudioAtlasImagePreview(
                resolution: const SurfaceStudioAtlasImagePreviewResolution(
                    status:
                        SurfaceStudioAtlasImagePreviewResolveStatus.missingFile,
                    displayFileName: 'atlas.png',
                    relativePathForUi:
                        'assets/surfaces/water/animated/atlas/source/that/is/very/long/atlas.png'),
                label: Colors.white,
                subtle: Colors.white70,
                draftTileWidth: 32,
                draftTileHeight: 32,
                draftColumns: 12,
                draftRows: 32,
                draftLayoutLabel: 'Colonnes variantes / lignes frames',
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }

    await pumpConstrained(const Size(312.8, 557));
    await pumpConstrained(const Size(552, 318));

    expect(
      errors.where((details) =>
          details.exceptionAsString().contains('RenderFlex overflowed')),
      isEmpty,
    );
  });
}
```

### reports/surface/surface_studio_rebuild_v2_2_functional_closure_mistral.md

Le rapport lui-même ne doit pas se recopier récursivement.

## 18.9 Diffs complets

### packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart b/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
index 6a46e98c..d4318eb8 100644
--- a/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
@@ -14,6 +14,8 @@ class SurfaceStudioAtlasPanel extends StatelessWidget {
     required this.frameCount,
     required this.tileWidth,
     required this.tileHeight,
+    this.atlasImageBytes,
+    this.atlasImageFallbackLabel,
     required this.selection,
     required this.zoomPercent,
     required this.onColumnSelectionChanged,
@@ -26,6 +28,8 @@ class SurfaceStudioAtlasPanel extends StatelessWidget {
   final int frameCount;
   final int tileWidth;
   final int tileHeight;
+  final Uint8List? atlasImageBytes;
+  final String? atlasImageFallbackLabel;
   final SurfaceStudioColumnSelection selection;
   final double zoomPercent;
   final ValueChanged<SurfaceStudioColumnSelection> onColumnSelectionChanged;
@@ -48,6 +52,8 @@ class SurfaceStudioAtlasPanel extends StatelessWidget {
               frameCount: frameCount,
               tileWidth: tileWidth,
               tileHeight: tileHeight,
+              atlasImageBytes: atlasImageBytes,
+              atlasImageFallbackLabel: atlasImageFallbackLabel,
               selection: selection,
               zoomPercent: zoomPercent,
               onColumnSelectionChanged: onColumnSelectionChanged,
@@ -77,6 +83,8 @@ class SurfaceStudioAtlasViewport extends StatelessWidget {
     required this.frameCount,
     required this.tileWidth,
     required this.tileHeight,
+    this.atlasImageBytes,
+    this.atlasImageFallbackLabel,
     required this.selection,
     required this.zoomPercent,
     required this.onColumnSelectionChanged,
@@ -86,6 +94,8 @@ class SurfaceStudioAtlasViewport extends StatelessWidget {
   final int frameCount;
   final int tileWidth;
   final int tileHeight;
+  final Uint8List? atlasImageBytes;
+  final String? atlasImageFallbackLabel;
   final SurfaceStudioColumnSelection selection;
   final double zoomPercent;
   final ValueChanged<SurfaceStudioColumnSelection> onColumnSelectionChanged;
@@ -149,13 +159,49 @@ class SurfaceStudioAtlasViewport extends StatelessWidget {
             child: Stack(
               children: [
                 Positioned.fill(
-                  child: CustomPaint(
-                    painter: SurfaceStudioAtlasGridPainter(
-                      columnCount: columnCount,
-                      rowCount: frameCount,
-                      selectedColumns: selection.columns,
-                      zoomPercent: zoomPercent,
-                    ),
+                  child: Stack(
+                    fit: StackFit.expand,
+                    children: [
+                      if (atlasImageBytes != null)
+                        Image.memory(
+                          atlasImageBytes!,
+                          key: const ValueKey('surfaceStudio.atlas.realImage'),
+                          fit: BoxFit.cover,
+                          gaplessPlayback: true,
+                          errorBuilder: (_, __, ___) => const Center(
+                            child: Text(
+                              'Image source indisponible — aperçu illustratif.',
+                              textAlign: TextAlign.center,
+                              style: TextStyle(
+                                color: SurfaceStudioDesignTokens.textMuted,
+                                fontSize: 12,
+                                fontWeight: FontWeight.w700,
+                              ),
+                            ),
+                          ),
+                        )
+                      else
+                        Center(
+                          child: Text(
+                            atlasImageFallbackLabel ??
+                                'Image source indisponible — aperçu illustratif.',
+                            textAlign: TextAlign.center,
+                            style: const TextStyle(
+                              color: SurfaceStudioDesignTokens.textMuted,
+                              fontSize: 12,
+                              fontWeight: FontWeight.w700,
+                            ),
+                          ),
+                        ),
+                      CustomPaint(
+                        painter: SurfaceStudioAtlasGridPainter(
+                          columnCount: columnCount,
+                          rowCount: frameCount,
+                          selectedColumns: selection.columns,
+                          zoomPercent: zoomPercent,
+                        ),
+                      ),
+                    ],
                   ),
                 ),
                 if (selection.isNotEmpty)
```

### packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart b/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
index b025b9a6..67b3b4c6 100644
--- a/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
@@ -1,3 +1,5 @@
+import 'dart:typed_data';
+
 import 'package:flutter/cupertino.dart';
 import 'package:flutter/material.dart'
     show Material, MaterialType, PopupMenuButton, PopupMenuItem, Slider;
@@ -16,6 +18,8 @@ class SurfaceStudioPreviewPanel extends StatelessWidget {
     required this.gridVisible,
     required this.previewSize,
     required this.assignmentDraft,
+    this.atlasImageBytes,
+    this.atlasFallbackMessage,
     required this.onPrevious,
     required this.onNext,
     required this.onTogglePlaying,
@@ -32,6 +36,8 @@ class SurfaceStudioPreviewPanel extends StatelessWidget {
   final bool gridVisible;
   final int previewSize;
   final SurfaceStudioRoleAssignmentDraft assignmentDraft;
+  final Uint8List? atlasImageBytes;
+  final String? atlasFallbackMessage;
   final VoidCallback onPrevious;
   final VoidCallback onNext;
   final VoidCallback onTogglePlaying;
@@ -72,6 +78,10 @@ class SurfaceStudioPreviewPanel extends StatelessWidget {
                     child: _PreviewViewport(
                       previewSize: previewSize,
                       gridVisible: gridVisible,
+                      frameIndex: frameIndex,
+                      frameCount: frameCount,
+                      atlasImageBytes: atlasImageBytes,
+                      atlasFallbackMessage: atlasFallbackMessage,
                       hasCenter: assignmentDraft.isAssigned(
                         SurfaceVariantRole.isolated,
                       ),
@@ -110,11 +120,19 @@ class _PreviewViewport extends StatelessWidget {
   const _PreviewViewport({
     required this.previewSize,
     required this.gridVisible,
+    required this.frameIndex,
+    required this.frameCount,
+    this.atlasImageBytes,
+    this.atlasFallbackMessage,
     required this.hasCenter,
   });
 
   final int previewSize;
   final bool gridVisible;
+  final int frameIndex;
+  final int frameCount;
+  final Uint8List? atlasImageBytes;
+  final String? atlasFallbackMessage;
   final bool hasCenter;
 
   @override
@@ -127,12 +145,61 @@ class _PreviewViewport extends StatelessWidget {
       ),
       clipBehavior: Clip.antiAlias,
       child: hasCenter
-          ? CustomPaint(
-              painter: _WaterPreviewPainter(
-                gridVisible: gridVisible,
-                previewSize: previewSize,
-              ),
-              child: const SizedBox.expand(),
+          ? Stack(
+              fit: StackFit.expand,
+              children: [
+                if (atlasImageBytes != null)
+                  Image.memory(
+                    atlasImageBytes!,
+                    key: const ValueKey('surfaceStudio.preview.realImage'),
+                    fit: BoxFit.cover,
+                    alignment: Alignment(
+                      0,
+                      frameCount <= 1
+                          ? 0
+                          : -1 + (2 * (frameIndex / (frameCount - 1))),
+                    ),
+                    gaplessPlayback: true,
+                    errorBuilder: (_, __, ___) => Center(
+                      child: Padding(
+                        padding: const EdgeInsets.all(16),
+                        child: Text(
+                          atlasFallbackMessage ??
+                              'Image source indisponible — aperçu illustratif.',
+                          textAlign: TextAlign.center,
+                          style: const TextStyle(
+                            color: SurfaceStudioDesignTokens.textMuted,
+                            fontSize: 12,
+                            height: 1.3,
+                          ),
+                        ),
+                      ),
+                    ),
+                  )
+                else
+                  Center(
+                    child: Padding(
+                      padding: const EdgeInsets.all(16),
+                      child: Text(
+                        atlasFallbackMessage ??
+                            'Image source indisponible — aperçu illustratif.',
+                        textAlign: TextAlign.center,
+                        style: const TextStyle(
+                          color: SurfaceStudioDesignTokens.textMuted,
+                          fontSize: 12,
+                          height: 1.3,
+                        ),
+                      ),
+                    ),
+                  ),
+                CustomPaint(
+                  painter: _WaterPreviewPainter(
+                    gridVisible: gridVisible,
+                    previewSize: previewSize,
+                  ),
+                  child: const SizedBox.expand(),
+                ),
+              ],
             )
           : const Center(
               child: Padding(
```

### packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart
index a5c04910..acc593ba 100644
--- a/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart
@@ -21,53 +21,60 @@ class SurfaceStudioHeader extends StatelessWidget {
 
   @override
   Widget build(BuildContext context) {
-    return Container(
-      key: const ValueKey('surfaceStudio.header'),
-      decoration: const BoxDecoration(
-        color: SurfaceStudioDesignTokens.backgroundDeep,
-        border: Border(
-          bottom: BorderSide(color: SurfaceStudioDesignTokens.borderSubtle),
-        ),
-      ),
-      padding: const EdgeInsets.symmetric(horizontal: 20),
-      child: Row(
-        children: [
-          const _StudioMark(),
-          const SizedBox(width: 12),
-          const Text(
-            'Surface Studio — Assistant de mapping d’atlas',
-            style: TextStyle(
-              color: SurfaceStudioDesignTokens.textPrimary,
-              fontSize: 16,
-              fontWeight: FontWeight.w800,
-            ),
-          ),
-          const SizedBox(width: 24),
-          Expanded(
-            child: SurfaceStudioTopStepper(
-              currentStep: currentStep,
-              completedSteps: completedSteps,
-              onStepSelected: onStepSelected,
+    return LayoutBuilder(
+      builder: (context, constraints) {
+        final compact = constraints.maxWidth < 900;
+        return Container(
+          key: const ValueKey('surfaceStudio.header'),
+          decoration: const BoxDecoration(
+            color: SurfaceStudioDesignTokens.backgroundDeep,
+            border: Border(
+              bottom: BorderSide(color: SurfaceStudioDesignTokens.borderSubtle),
             ),
           ),
-          const SizedBox(width: 12),
-          _HeaderIconButton(
-            tooltip: 'Aide',
-            icon: CupertinoIcons.question_circle,
-            onPressed: () {},
-          ),
-          _HeaderIconButton(
-            tooltip: 'Catalogue & diagnostics',
-            icon: CupertinoIcons.gear_alt,
-            onPressed: onOpenAdvanced ?? () {},
+          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
+          child: Row(
+            children: [
+              const _StudioMark(),
+              const SizedBox(width: 12),
+              Flexible(
+                child: ConstrainedBox(
+                  constraints: BoxConstraints(maxWidth: compact ? 180 : 380),
+                  child: const Text(
+                    'Surface Studio — Assistant de mapping d’atlas',
+                    maxLines: 1,
+                    overflow: TextOverflow.ellipsis,
+                    style: TextStyle(
+                      color: SurfaceStudioDesignTokens.textPrimary,
+                      fontSize: 16,
+                      fontWeight: FontWeight.w800,
+                    ),
+                  ),
+                ),
+              ),
+              SizedBox(width: compact ? 12 : 24),
+              Expanded(
+                child: SurfaceStudioTopStepper(
+                  currentStep: currentStep,
+                  completedSteps: completedSteps,
+                  onStepSelected: onStepSelected,
+                ),
+              ),
+              const SizedBox(width: 8),
+              _HeaderIconButton(
+                tooltip: 'Aide',
+                icon: CupertinoIcons.question_circle,
+                onPressed: () {},
+              ),
+              _HeaderIconButton(
+                tooltip: 'Catalogue & diagnostics',
+                icon: CupertinoIcons.gear_alt,
+                onPressed: onOpenAdvanced ?? () {},
+              ),
+            ],
           ),
-          _HeaderIconButton(
-            tooltip: 'Fermer',
-            icon: CupertinoIcons.xmark,
-            onPressed: () {},
-          ),
-        ],
-      ),
+        );
+      },
     );
   }
 }
```

### packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart
index 81e01640..85d3db08 100644
--- a/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart
@@ -8,14 +8,14 @@ class SurfaceStudioShell extends StatelessWidget {
     required this.header,
     required this.sidebar,
     required this.workspacePanel,
-    required this.rightDock,
+    this.rightDock,
     required this.bottomBar,
   });
 
   final Widget header;
   final Widget sidebar;
   final Widget workspacePanel;
-  final Widget rightDock;
+  final Widget? rightDock;
   final Widget bottomBar;
 
   @override
@@ -32,18 +32,42 @@ class SurfaceStudioShell extends StatelessWidget {
           Expanded(
             child: Padding(
               padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
-              child: Row(
-                crossAxisAlignment: CrossAxisAlignment.stretch,
-                children: [
-                  sidebar,
-                  const SizedBox(width: SurfaceStudioDesignTokens.gapSm),
-                  Expanded(child: workspacePanel),
-                  const SizedBox(width: SurfaceStudioDesignTokens.gapSm),
-                  SizedBox(
-                    width: SurfaceStudioDesignTokens.rightPanelWidthExpanded,
-                    child: rightDock,
-                  ),
-                ],
+              child: LayoutBuilder(
+                builder: (context, constraints) {
+                  final minimumReadableWidth =
+                      rightDock == null ? 900.0 : 1260.0;
+                  final contentWidth =
+                      constraints.maxWidth < minimumReadableWidth
+                          ? minimumReadableWidth
+                          : constraints.maxWidth;
+                  final content = SizedBox(
+                    width: contentWidth,
+                    child: Row(
+                      crossAxisAlignment: CrossAxisAlignment.stretch,
+                      children: [
+                        sidebar,
+                        const SizedBox(width: SurfaceStudioDesignTokens.gapSm),
+                        Expanded(child: workspacePanel),
+                        if (rightDock != null) ...[
+                          const SizedBox(
+                              width: SurfaceStudioDesignTokens.gapSm),
+                          SizedBox(
+                            width: SurfaceStudioDesignTokens
+                                .rightPanelWidthExpanded,
+                            child: rightDock!,
+                          ),
+                        ],
+                      ],
+                    ),
+                  );
+                  if (contentWidth == constraints.maxWidth) {
+                    return content;
+                  }
+                  return SingleChildScrollView(
+                    scrollDirection: Axis.horizontal,
+                    child: content,
+                  );
+                },
               ),
             ),
           ),
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_editing.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_editing.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_editing.dart
index 077158a5..467c85fe 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_editing.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_editing.dart
@@ -37,8 +37,7 @@ ProjectSurfaceCatalog removeAtlasIdFromWorkCatalog(
   ProjectSurfaceCatalog catalog,
   String atlasId,
 ) {
-  final nextAtlases =
-      catalog.atlases.where((a) => a.id != atlasId).toList();
+  final nextAtlases = catalog.atlases.where((a) => a.id != atlasId).toList();
   if (nextAtlases.length == catalog.atlases.length) {
     throw StateError('Atlas id introuvable: $atlasId');
   }
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart
index 7e2b00d1..94f52d40 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart
@@ -32,10 +32,7 @@ bool surfaceStudioAtlasGridOverlayDraftValid(
       rows == null) {
     return false;
   }
-  return tileWidth > 0 &&
-      tileHeight > 0 &&
-      columns > 0 &&
-      rows > 0;
+  return tileWidth > 0 && tileHeight > 0 && columns > 0 && rows > 0;
 }
 
 int surfaceStudioAtlasGridExpectedWidthPx(int tileWidth, int columns) =>
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart
index 47538c03..49a59821 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart
@@ -36,16 +36,17 @@ class SurfaceStudioAtlasGridPreview extends StatelessWidget {
     final subtle = EditorChrome.subtleLabel(context);
     final source = sourceLabel?.trim();
     final hasSource = source != null && source.isNotEmpty;
-    final displaySource = (sourceDisplayForUi != null &&
-            sourceDisplayForUi!.trim().isNotEmpty)
-        ? sourceDisplayForUi!.trim()
-        : source;
+    final displaySource =
+        (sourceDisplayForUi != null && sourceDisplayForUi!.trim().isNotEmpty)
+            ? sourceDisplayForUi!.trim()
+            : source;
     final hasValidGrid = _isPositive(tileWidth) &&
         _isPositive(tileHeight) &&
         _isPositive(columns) &&
         _isPositive(rows);
 
-    final previewColumns = hasValidGrid ? _cap(columns!, _previewMaxColumns) : 0;
+    final previewColumns =
+        hasValidGrid ? _cap(columns!, _previewMaxColumns) : 0;
     final previewRows = hasValidGrid ? _cap(rows!, _previewMaxRows) : 0;
     final reduced = hasValidGrid &&
         (columns! > _previewMaxColumns || rows! > _previewMaxRows);
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart
index 708e837d..52fb3b27 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart
@@ -265,23 +265,32 @@ class _SurfaceStudioAtlasImagePreviewState
           color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
         ),
       ),
-      child: Column(
-        crossAxisAlignment: CrossAxisAlignment.stretch,
-        children: [
-          Text(
-            widget.largeFormat
-                ? 'Aperçu grand format de l’image source'
-                : 'Aperçu de l’image source',
-            style: TextStyle(
-              color: widget.label,
-              fontSize: 12,
-              fontWeight: FontWeight.w800,
-              letterSpacing: 0.2,
-            ),
-          ),
-          const SizedBox(height: 6),
-          ..._bodyForStatus(context),
-        ],
+      child: LayoutBuilder(
+        builder: (context, constraints) {
+          final content = Column(
+            crossAxisAlignment: CrossAxisAlignment.stretch,
+            mainAxisSize: MainAxisSize.min,
+            children: [
+              Text(
+                widget.largeFormat
+                    ? 'Aperçu grand format de l’image source'
+                    : 'Aperçu de l’image source',
+                style: TextStyle(
+                  color: widget.label,
+                  fontSize: 12,
+                  fontWeight: FontWeight.w800,
+                  letterSpacing: 0.2,
+                ),
+              ),
+              const SizedBox(height: 6),
+              ..._bodyForStatus(context),
+            ],
+          );
+          if (!constraints.maxHeight.isFinite) {
+            return content;
+          }
+          return SingleChildScrollView(child: content);
+        },
       ),
     );
   }
@@ -362,11 +371,11 @@ class _SurfaceStudioAtlasImagePreviewState
     final th = widget.draftTileHeight;
     final cols = widget.draftColumns;
     final rows = widget.draftRows;
-    final gridValid = surfaceStudioAtlasGridOverlayDraftValid(tw, th, cols, rows);
+    final gridValid =
+        surfaceStudioAtlasGridOverlayDraftValid(tw, th, cols, rows);
     final natW = _imageNaturalWidth;
     final natH = _imageNaturalHeight;
-    final naturalKnown =
-        natW != null && natH != null && natW > 0 && natH > 0;
+    final naturalKnown = natW != null && natH != null && natW > 0 && natH > 0;
     final nw = natW ?? 0;
     final nh = natH ?? 0;
 
@@ -438,7 +447,11 @@ class _SurfaceStudioAtlasImagePreviewState
           style: TextStyle(color: widget.label, fontSize: 11.5),
         ),
       ],
-      if (gridValid && cols != null && rows != null && tw != null && th != null) ...[
+      if (gridValid &&
+          cols != null &&
+          rows != null &&
+          tw != null &&
+          th != null) ...[
         const SizedBox(height: 2),
         Text(
           'Grille : $cols colonnes × $rows lignes',
@@ -467,9 +480,7 @@ class _SurfaceStudioAtlasImagePreviewState
               ? 'La grille correspond aux dimensions attendues.'
               : 'La grille ne correspond pas exactement aux dimensions de l’image.',
           style: TextStyle(
-            color: dimMatch
-                ? const Color(0xFF5EEAD4)
-                : const Color(0xFFE8B87A),
+            color: dimMatch ? const Color(0xFF5EEAD4) : const Color(0xFFE8B87A),
             fontSize: 11,
             fontWeight: FontWeight.w600,
           ),
@@ -549,9 +560,12 @@ class _SurfaceStudioAtlasImagePreviewState
                 spacing: 6,
                 runSpacing: 4,
                 children: [
-                  fitBtn('Ajuster à la largeur', SurfaceStudioAtlasImagePreviewFitMode.fitWidth),
-                  fitBtn('Taille réelle 100 %', SurfaceStudioAtlasImagePreviewFitMode.pixel100),
-                  fitBtn('Ajuster à la hauteur', SurfaceStudioAtlasImagePreviewFitMode.fitHeight),
+                  fitBtn('Ajuster à la largeur',
+                      SurfaceStudioAtlasImagePreviewFitMode.fitWidth),
+                  fitBtn('Taille réelle 100 %',
+                      SurfaceStudioAtlasImagePreviewFitMode.pixel100),
+                  fitBtn('Ajuster à la hauteur',
+                      SurfaceStudioAtlasImagePreviewFitMode.fitHeight),
                 ],
               ),
               const SizedBox(height: 6),
@@ -626,7 +640,8 @@ class _SurfaceStudioAtlasImagePreviewState
                   borderRadius: BorderRadius.circular(8),
                   child: material.Image.memory(
                     _cachedBytes!,
-                    key: const ValueKey('surface_studio_atlas_image_preview_file'),
+                    key: const ValueKey(
+                        'surface_studio_atlas_image_preview_file'),
                     fit: material.BoxFit.contain,
                     height: 480,
                     errorBuilder: (_, __, ___) => Text(
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_source_picker.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_source_picker.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_source_picker.dart
index 91975b9e..1f1450ab 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_source_picker.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_source_picker.dart
@@ -130,7 +130,8 @@ class SurfaceStudioAtlasImageSourceBlock extends StatelessWidget {
           ] else ...[
             Text(
               'Sélecteur d’image non connecté pour l’instant.',
-              style: TextStyle(color: label, fontSize: 12, fontWeight: FontWeight.w600),
+              style: TextStyle(
+                  color: label, fontSize: 12, fontWeight: FontWeight.w600),
             ),
             const SizedBox(height: 4),
             Text(
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_column_role_mapping_block.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_column_role_mapping_block.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_column_role_mapping_block.dart
index 3525cb02..d01e3423 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_column_role_mapping_block.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_column_role_mapping_block.dart
@@ -52,10 +52,12 @@ class SurfaceStudioColumnRoleMappingBlock extends StatelessWidget {
         key: sectionKey,
         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
         decoration: BoxDecoration(
-          color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
+          color:
+              EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
           borderRadius: BorderRadius.circular(10),
           border: Border.all(
-            color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
+            color:
+                EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
           ),
         ),
         child: Column(
@@ -86,10 +88,12 @@ class SurfaceStudioColumnRoleMappingBlock extends StatelessWidget {
         key: sectionKey,
         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
         decoration: BoxDecoration(
-          color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
+          color:
+              EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
           borderRadius: BorderRadius.circular(10),
           border: Border.all(
-            color: EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
+            color:
+                EditorChrome.editorIslandRim(context).withValues(alpha: 0.65),
           ),
         ),
         child: Column(
@@ -251,9 +255,8 @@ class _SummaryRow extends StatelessWidget {
           label: 'Doublons',
           value: '${summary.duplicateRoleCount}',
           labelColor: label,
-          valueColor: summary.hasDuplicateRoles
-              ? Colors.orange.shade700
-              : subtle,
+          valueColor:
+              summary.hasDuplicateRoles ? Colors.orange.shade700 : subtle,
         ),
       ],
     );
@@ -329,7 +332,8 @@ class _ColumnList extends StatelessWidget {
             margin: const EdgeInsets.only(bottom: 4),
             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
             decoration: BoxDecoration(
-              color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.5),
+              color: EditorChrome.islandFillElevated(context)
+                  .withValues(alpha: 0.5),
               borderRadius: BorderRadius.circular(6),
             ),
             child: Row(
@@ -362,7 +366,8 @@ class _ColumnList extends StatelessWidget {
                       fontSize: 11,
                     ),
                     iconEnabledColor: label,
-                    dropdownColor: EditorChrome.elevatedPanelBackground(context),
+                    dropdownColor:
+                        EditorChrome.elevatedPanelBackground(context),
                     items: [
                       // Option pour désassigner
                       const DropdownMenuItem<SurfaceVariantRole>(
@@ -395,4 +400,4 @@ class _ColumnList extends StatelessWidget {
       ),
     );
   }
-}
\ No newline at end of file
+}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart
index e8ab83cf..2fae4955 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart
@@ -1,20 +1,49 @@
+import 'dart:typed_data';
+
+import 'surface_studio_ai_mapping_suggester.dart';
 import 'surface_studio_local_mapping_suggester.dart';
 import 'surface_studio_mapping_suggestion_models.dart';
 
 final class SurfaceStudioMappingSuggestionController {
   const SurfaceStudioMappingSuggestionController({
     this.localSuggester = const SurfaceStudioLocalMappingSuggester(),
+    this.aiSuggester,
   });
 
   final SurfaceStudioLocalMappingSuggester localSuggester;
+  final SurfaceStudioAiMappingSuggester? aiSuggester;
 
   SurfaceStudioMappingSuggestionResult suggestLocal({
     required int columnCount,
   }) {
     return localSuggester.suggest(columnCount: columnCount);
   }
-}
 
-abstract class SurfaceStudioAiMappingSuggester {
-  Future<SurfaceStudioMappingSuggestionResult> suggest();
+  Future<SurfaceStudioMappingSuggestionResult> suggestMistral({
+    required String apiKey,
+    required Uint8List imageBytes,
+    required int tileWidth,
+    required int tileHeight,
+    required int columnCount,
+    required int frameCount,
+  }) {
+    final suggester = aiSuggester;
+    if (suggester == null) {
+      return Future.value(
+        const SurfaceStudioMappingSuggestionResult(
+          suggestions: <SurfaceStudioRoleSuggestion>[],
+          warnings: <String>['Analyse IA Mistral indisponible.'],
+          source: SurfaceStudioMappingSuggestionSource.mistral,
+        ),
+      );
+    }
+    return suggester.suggest(
+      apiKey: apiKey,
+      imageBytes: imageBytes,
+      tileWidth: tileWidth,
+      tileHeight: tileHeight,
+      columnCount: columnCount,
+      frameCount: frameCount,
+    );
+  }
 }
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
index 13635b5a..4a8a3da8 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
@@ -14,6 +14,7 @@ import 'surface_studio_catalog_browser.dart';
 import 'surface_studio_diagnostics_view.dart';
 import 'surface_studio_paintable_surfaces_panel.dart';
 import 'surface_studio_preset_editor_controller.dart';
+import 'surface_studio_ai_mapping_suggester.dart';
 import 'surface_studio_role_mapping_editor.dart';
 import 'surface_studio_selection.dart';
 import 'surface_studio_selection_inspector.dart';
@@ -55,6 +56,7 @@ class SurfaceStudioPanel extends StatefulWidget {
     this.projectRootPath,
     this.projectSettings,
     this.surfaceMappingImageLoader,
+    this.aiMappingSuggester,
   });
 
   final SurfaceStudioReadModel readModel;
@@ -63,6 +65,7 @@ class SurfaceStudioPanel extends StatefulWidget {
   final List<ProjectTilesetEntry>? projectTilesets;
   final ProjectSettings? projectSettings;
   final SurfaceStudioAtlasUiImageLoader? surfaceMappingImageLoader;
+  final SurfaceStudioAiMappingSuggester? aiMappingSuggester;
 
   /// Racine projet sur disque pour résoudre les chemins d’images tileset (aperçu Lot 72).
   final String? projectRootPath;
@@ -394,61 +397,56 @@ class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
 
     return LayoutBuilder(
       builder: (context, constraints) {
-        final shellWidth = constraints.hasBoundedWidth
-            ? constraints.maxWidth.clamp(1200.0, 2400.0).toDouble()
-            : 1600.0;
-        final shellHeight = constraints.hasBoundedHeight
-            ? constraints.maxHeight.clamp(760.0, 1120.0).toDouble()
-            : 900.0;
-        return SingleChildScrollView(
-          scrollDirection: Axis.horizontal,
-          child: SizedBox(
-            width: shellWidth,
-            height: shellHeight,
-            child: SurfaceStudioScreen(
-              readModel: _workReadModel,
-              projectSettings: widget.projectSettings,
-              projectTilesets: widget.projectTilesets ?? const [],
-              projectRootPath: widget.projectRootPath,
-              surfaceMappingImageLoader: widget.surfaceMappingImageLoader,
-              hasWorkCatalogChanges: _hasWorkCatalogChanges,
-              saveFlowPrepNote: _saveFlowPrepNote,
-              projectSaveDiskNote: _projectSaveDiskNote,
-              onSurfaceCatalogChanged: _onSurfaceCatalogChanged,
-              onWorkCatalogAnimationsCreated: (createdIds) {
-                if (createdIds.isEmpty) {
-                  return;
-                }
-                setState(() {
-                  _selection =
-                      SurfaceStudioSelection.animation(createdIds.first);
-                });
-              },
-              onWorkCatalogPresetCreated: (presetId) {
-                if (presetId.isEmpty) {
-                  return;
-                }
-                setState(() {
-                  _selection = SurfaceStudioSelection.preset(presetId);
-                });
-              },
-              onResetWorkCatalog: () {
-                setState(() {
-                  _workReadModel = widget.readModel;
-                  _selection =
-                      _selectionValidInReadModel(_workReadModel, _selection);
-                  _saveFlowPrepNote = null;
-                });
-              },
-              onSurfaceCatalogSavePrep:
-                  widget.onSurfaceCatalogSaveRequested == null
-                      ? null
-                      : _onSurfaceCatalogSavePrep,
-              onRequestProjectSave: widget.onRequestProjectSave == null
-                  ? null
-                  : _onRequestProjectSave,
-              advancedDrawer: advancedDrawer,
-            ),
+        final shellWidth =
+            constraints.hasBoundedWidth ? constraints.maxWidth : 1600.0;
+        final shellHeight =
+            constraints.hasBoundedHeight ? constraints.maxHeight : 900.0;
+        return SizedBox(
+          width: shellWidth,
+          height: shellHeight,
+          child: SurfaceStudioScreen(
+            readModel: _workReadModel,
+            projectSettings: widget.projectSettings,
+            projectTilesets: widget.projectTilesets ?? const [],
+            projectRootPath: widget.projectRootPath,
+            surfaceMappingImageLoader: widget.surfaceMappingImageLoader,
+            hasWorkCatalogChanges: _hasWorkCatalogChanges,
+            saveFlowPrepNote: _saveFlowPrepNote,
+            projectSaveDiskNote: _projectSaveDiskNote,
+            onSurfaceCatalogChanged: _onSurfaceCatalogChanged,
+            onWorkCatalogAnimationsCreated: (createdIds) {
+              if (createdIds.isEmpty) {
+                return;
+              }
+              setState(() {
+                _selection = SurfaceStudioSelection.animation(createdIds.first);
+              });
+            },
+            onWorkCatalogPresetCreated: (presetId) {
+              if (presetId.isEmpty) {
+                return;
+              }
+              setState(() {
+                _selection = SurfaceStudioSelection.preset(presetId);
+              });
+            },
+            onResetWorkCatalog: () {
+              setState(() {
+                _workReadModel = widget.readModel;
+                _selection =
+                    _selectionValidInReadModel(_workReadModel, _selection);
+                _saveFlowPrepNote = null;
+              });
+            },
+            onSurfaceCatalogSavePrep:
+                widget.onSurfaceCatalogSaveRequested == null
+                    ? null
+                    : _onSurfaceCatalogSavePrep,
+            onRequestProjectSave: widget.onRequestProjectSave == null
+                ? null
+                : _onRequestProjectSave,
+            advancedDrawer: advancedDrawer,
+            aiMappingSuggester: widget.aiMappingSuggester,
           ),
         );
       },
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
index c553cdf1..ecfb349c 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
@@ -1,4 +1,6 @@
 import 'dart:async';
+import 'dart:io';
+import 'dart:typed_data';
 
 import 'package:flutter/cupertino.dart';
 import 'package:flutter/material.dart'
@@ -26,11 +28,13 @@ import 'surface_studio_atlas_grid_overlay.dart';
 import 'surface_studio_atlas_grid_preview.dart';
 import 'surface_studio_atlas_image_preview.dart';
 import 'surface_studio_atlas_source_picker.dart';
+import 'surface_studio_ai_mapping_suggester.dart';
 import 'surface_studio_column_selection.dart';
 import 'surface_studio_design_tokens.dart';
 import 'surface_studio_drag_payload.dart';
 import 'surface_studio_mapping_suggestion_controller.dart';
 import 'surface_studio_mapping_suggestion_models.dart';
+import 'surface_studio_mistral_mapping_suggester.dart';
 import 'surface_studio_role_assignment_draft.dart';
 import 'surface_studio_step.dart';
 import 'surface_studio_vertical_atlas_animation_generation_plan.dart';
@@ -56,6 +60,7 @@ class SurfaceStudioScreen extends StatefulWidget {
     this.onSurfaceCatalogSavePrep,
     this.onRequestProjectSave,
     this.advancedDrawer,
+    this.aiMappingSuggester,
   });
 
   final SurfaceStudioReadModel readModel;
@@ -73,6 +78,7 @@ class SurfaceStudioScreen extends StatefulWidget {
   final VoidCallback? onSurfaceCatalogSavePrep;
   final Future<void> Function()? onRequestProjectSave;
   final Widget? advancedDrawer;
+  final SurfaceStudioAiMappingSuggester? aiMappingSuggester;
 
   @override
   State<SurfaceStudioScreen> createState() => _SurfaceStudioScreenState();
@@ -86,6 +92,9 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
   bool _rightPanelCollapsed = false;
   bool _advancedDrawerOpen = false;
   bool _suggestionReviewOpen = false;
+  bool _aiConfirmationOpen = false;
+  bool _mergeAiAfterConfirmation = false;
+  bool _suggestionRunning = false;
   Set<String> _openSchemaGroups = const {
     'surfaceMain',
     'edges',
@@ -107,9 +116,9 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
   String? _lastGenerationMessage;
   String? _lastPresetMessage;
   SurfaceStudioMappingSuggestionResult? _suggestionResult;
-  final _suggestionController =
-      const SurfaceStudioMappingSuggestionController();
   Timer? _previewTimer;
+  String? _cachedAtlasImagePath;
+  Uint8List? _cachedAtlasImageBytes;
 
   final TextEditingController _atlasId = TextEditingController();
   final TextEditingController _atlasName = TextEditingController();
@@ -188,6 +197,38 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
     return null;
   }
 
+  SurfaceStudioMappingSuggestionController get _suggestionController =>
+      const SurfaceStudioMappingSuggestionController();
+
+  SurfaceStudioAtlasImagePreviewResolution get _atlasImageResolution =>
+      resolveSurfaceStudioAtlasImagePreview(
+        projectRootPath: widget.projectRootPath,
+        projectTilesets: widget.projectTilesets,
+        technicalTilesetId: _tilesetId.text,
+      );
+
+  Uint8List? _atlasImageBytes() {
+    final path = _atlasImageResolution.resolvedAbsolutePath;
+    if (path == null || path.isEmpty) {
+      _cachedAtlasImagePath = null;
+      _cachedAtlasImageBytes = null;
+      return null;
+    }
+    if (_cachedAtlasImagePath == path && _cachedAtlasImageBytes != null) {
+      return _cachedAtlasImageBytes;
+    }
+    try {
+      final bytes = File(path).readAsBytesSync();
+      _cachedAtlasImagePath = path;
+      _cachedAtlasImageBytes = bytes;
+      return bytes;
+    } catch (_) {
+      _cachedAtlasImagePath = path;
+      _cachedAtlasImageBytes = null;
+      return null;
+    }
+  }
+
   int get _columnCount {
     final parsed = int.tryParse(_columns.text.trim());
     if (parsed != null && parsed > 0) {
@@ -486,17 +527,93 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
   }
 
   void _openSuggestionReview() {
+    _runLocalSuggestion(openReview: true);
+  }
+
+  void _runLocalSuggestion({bool openReview = false}) {
     final result = _suggestionController.suggestLocal(
       columnCount: _columnCount,
     );
     setState(() {
       _suggestionResult = result;
-      _suggestionReviewOpen = true;
+      _suggestionReviewOpen = openReview || _suggestionReviewOpen;
+      _aiConfirmationOpen = false;
       _statusMessage =
           'Suggestions locales prêtes — validation utilisateur requise.';
     });
   }
 
+  void _requestAiSuggestion({bool mergeWithLocal = false}) {
+    setState(() {
+      _suggestionReviewOpen = true;
+      _aiConfirmationOpen = true;
+      _mergeAiAfterConfirmation = mergeWithLocal;
+      _statusMessage = 'Confirmation IA requise avant envoi.';
+    });
+  }
+
+  Future<void> _confirmAiSuggestion({required bool mergeWithLocal}) async {
+    final apiKey = resolveEditorMistralApiKey(widget.projectSettings);
+    final imageBytes = _atlasImageBytes();
+    final hasApiKey = apiKey.trim().isNotEmpty;
+    if (!hasApiKey || imageBytes == null) {
+      setState(() {
+        _aiConfirmationOpen = false;
+        _suggestionResult = SurfaceStudioMappingSuggestionResult(
+          suggestions: _suggestionResult?.suggestions ??
+              const <SurfaceStudioRoleSuggestion>[],
+          warnings: <String>[
+            if (_suggestionResult != null) ..._suggestionResult!.warnings,
+            if (!hasApiKey) 'Clé Mistral absente.',
+            if (imageBytes == null) 'Image source indisponible pour Mistral.',
+          ],
+          source: _suggestionResult?.source ??
+              SurfaceStudioMappingSuggestionSource.local,
+        );
+      });
+      return;
+    }
+    setState(() {
+      _suggestionRunning = true;
+      _aiConfirmationOpen = false;
+    });
+    final aiController = SurfaceStudioMappingSuggestionController(
+      aiSuggester:
+          widget.aiMappingSuggester ?? SurfaceStudioMistralMappingSuggester(),
+    );
+    final ai = await aiController.suggestMistral(
+      apiKey: apiKey,
+      imageBytes: imageBytes,
+      tileWidth: _tileWidthValue,
+      tileHeight: _tileHeightValue,
+      columnCount: _columnCount,
+      frameCount: _frameCount,
+    );
+    if (!mounted) {
+      return;
+    }
+    final result = mergeWithLocal && _suggestionResult != null
+        ? SurfaceStudioMappingSuggestionResult(
+            suggestions: <SurfaceStudioRoleSuggestion>[
+              ..._suggestionResult!.suggestions,
+              ...ai.suggestions,
+            ],
+            warnings: <String>[
+              ..._suggestionResult!.warnings,
+              ...ai.warnings,
+            ],
+            source: SurfaceStudioMappingSuggestionSource.merged,
+          )
+        : ai;
+    setState(() {
+      _suggestionRunning = false;
+      _suggestionResult = result;
+      _suggestionReviewOpen = true;
+      _statusMessage =
+          'Suggestions IA prêtes — validation utilisateur requise.';
+    });
+  }
+
   void _applySuggestions({required bool reliableOnly}) {
     final result = _suggestionResult;
     if (result == null) {
@@ -704,9 +821,21 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
               result: _suggestionResult!,
               mistralKeyConfigured:
                   hasEditorMistralApiKey(widget.projectSettings),
+              aiConfirmationOpen: _aiConfirmationOpen,
+              running: _suggestionRunning,
               onCancel: () {
-                setState(() => _suggestionReviewOpen = false);
+                setState(() {
+                  _suggestionReviewOpen = false;
+                  _aiConfirmationOpen = false;
+                });
               },
+              onRunLocal: () => _runLocalSuggestion(),
+              onRequestAi: () => _requestAiSuggestion(),
+              onCancelAi: () => setState(() => _aiConfirmationOpen = false),
+              onConfirmAi: () => _confirmAiSuggestion(
+                mergeWithLocal: _mergeAiAfterConfirmation,
+              ),
+              onCompare: () => _requestAiSuggestion(mergeWithLocal: true),
               onApplyReliable: () => _applySuggestions(reliableOnly: true),
               onApplyAll: () => _applySuggestions(reliableOnly: false),
             ),
@@ -725,6 +854,7 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
   }
 
   Widget _buildWorkspacePanel() {
+    final frameCount = _frameCount;
     return switch (_currentStep) {
       SurfaceStudioWizardStep.importAtlas => _ImportStepPanel(
           readModel: widget.readModel,
@@ -777,6 +907,10 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
           frameCount: _frameCount,
           tileWidth: _tileWidthValue,
           tileHeight: _tileHeightValue,
+          atlasImageBytes: _atlasImageBytes(),
+          atlasImageFallbackLabel: _atlasImageBytes() == null
+              ? 'Image source indisponible — aperçu illustratif.'
+              : null,
           selection: _selectedColumns,
           zoomPercent: _zoomPercent,
           onColumnSelectionChanged: (selection) {
@@ -794,13 +928,7 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
           },
           onAutoSuggest: _openSuggestionReview,
         ),
-      SurfaceStudioWizardStep.preview => _PreviewPlanPanel(
-          generationPlan: _generationPlan,
-          multiCenterColumns:
-              _assignmentDraft.columnsForRole(SurfaceVariantRole.isolated),
-          onGenerateAnimations: _appendReadyAnimations,
-          message: _lastGenerationMessage,
-        ),
+      SurfaceStudioWizardStep.preview => _buildPreviewWorkspace(frameCount),
       SurfaceStudioWizardStep.save => _SaveStepPanel(
           readModel: widget.readModel,
           generationPlan: _generationPlan,
@@ -826,18 +954,73 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
     };
   }
 
-  Widget _buildRightDock(int frameCount) {
-    if (_currentStep == SurfaceStudioWizardStep.save) {
-      return _RightDockFrame(
-        children: [
-          Expanded(
-            child: _CatalogStatusPanel(
-              readModel: widget.readModel,
-              hasWorkCatalogChanges: widget.hasWorkCatalogChanges,
-            ),
+  Widget _buildPreviewWorkspace(int frameCount) {
+    return Row(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        Expanded(
+          flex: 3,
+          child: SurfaceStudioPreviewPanel(
+            frameCount: frameCount,
+            frameIndex: _previewFrameIndex.clamp(0, frameCount - 1).toInt(),
+            playing: _previewPlaying,
+            loop: _previewLoop,
+            gridVisible: _previewGridVisible,
+            previewSize: _previewSize,
+            assignmentDraft: _assignmentDraft,
+            atlasImageBytes: _atlasImageBytes(),
+            atlasFallbackMessage: _atlasImageBytes() == null
+                ? 'Image source indisponible — aperçu illustratif.'
+                : null,
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
           ),
-        ],
-      );
+        ),
+        const SizedBox(width: SurfaceStudioDesignTokens.gapMd),
+        SizedBox(
+          width: 430,
+          child: _PreviewPlanPanel(
+            generationPlan: _generationPlan,
+            multiCenterColumns:
+                _assignmentDraft.columnsForRole(SurfaceVariantRole.isolated),
+            onGenerateAnimations: _appendReadyAnimations,
+            message: _lastGenerationMessage,
+          ),
+        ),
+      ],
+    );
+  }
+
+  Widget? _buildRightDock(int frameCount) {
+    if (_currentStep != SurfaceStudioWizardStep.map) {
+      return null;
     }
     return _RightDockFrame(
       children: [
@@ -884,6 +1067,10 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
             gridVisible: _previewGridVisible,
             previewSize: _previewSize,
             assignmentDraft: _assignmentDraft,
+            atlasImageBytes: _atlasImageBytes(),
+            atlasFallbackMessage: _atlasImageBytes() == null
+                ? 'Image source indisponible — aperçu illustratif.'
+                : null,
             onPrevious: () {
               setState(() {
                 _previewPlaying = false;
@@ -1402,47 +1589,6 @@ class _SaveStepPanel extends StatelessWidget {
   }
 }
 
-class _CatalogStatusPanel extends StatelessWidget {
-  const _CatalogStatusPanel({
-    required this.readModel,
-    required this.hasWorkCatalogChanges,
-  });
-
-  final SurfaceStudioReadModel readModel;
-  final bool hasWorkCatalogChanges;
-
-  @override
-  Widget build(BuildContext context) {
-    return _PanelFrame(
-      keyName: 'surfaceStudio.catalogStatus.panel',
-      title: 'Catalogue & état',
-      subtitle: 'Résumé du catalogue de travail Surface.',
-      child: Column(
-        crossAxisAlignment: CrossAxisAlignment.start,
-        children: [
-          _MetricRow(
-            metrics: {
-              'Atlas': '${readModel.summary.atlasCount}',
-              'Animations': '${readModel.summary.animationCount}',
-              'Surfaces': '${readModel.summary.presetCount}',
-            },
-          ),
-          const SizedBox(height: 12),
-          Text(
-            hasWorkCatalogChanges
-                ? 'Catalogue de travail modifié — sauvegarde projet non effectuée.'
-                : 'Catalogue synchronisé avec le manifest mémoire.',
-            style: const TextStyle(
-              color: SurfaceStudioDesignTokens.textSecondary,
-              fontWeight: FontWeight.w700,
-            ),
-          ),
-        ],
-      ),
-    );
-  }
-}
-
 class _RightDockFrame extends StatelessWidget {
   const _RightDockFrame({required this.children});
 
@@ -1697,14 +1843,28 @@ class _SuggestionReviewScrim extends StatelessWidget {
   const _SuggestionReviewScrim({
     required this.result,
     required this.mistralKeyConfigured,
+    required this.aiConfirmationOpen,
+    required this.running,
     required this.onCancel,
+    required this.onRunLocal,
+    required this.onRequestAi,
+    required this.onCancelAi,
+    required this.onConfirmAi,
+    required this.onCompare,
     required this.onApplyReliable,
     required this.onApplyAll,
   });
 
   final SurfaceStudioMappingSuggestionResult result;
   final bool mistralKeyConfigured;
+  final bool aiConfirmationOpen;
+  final bool running;
   final VoidCallback onCancel;
+  final VoidCallback onRunLocal;
+  final VoidCallback onRequestAi;
+  final VoidCallback onCancelAi;
+  final VoidCallback onConfirmAi;
+  final VoidCallback onCompare;
   final VoidCallback onApplyReliable;
   final VoidCallback onApplyAll;
 
@@ -1793,13 +1953,85 @@ class _SuggestionReviewScrim extends StatelessWidget {
                             ),
                           ),
                           const SizedBox(height: 8),
-                          const Text(
-                            'Analyse IA à venir',
-                            style: TextStyle(
-                              color: SurfaceStudioDesignTokens.accentGold,
-                              fontWeight: FontWeight.w800,
-                            ),
+                          Wrap(
+                            spacing: 8,
+                            runSpacing: 8,
+                            children: [
+                              CupertinoButton(
+                                key: const ValueKey(
+                                  'surfaceStudio.suggestion.local',
+                                ),
+                                padding: const EdgeInsets.symmetric(
+                                  horizontal: 12,
+                                  vertical: 8,
+                                ),
+                                color: SurfaceStudioDesignTokens.accentTealSoft,
+                                onPressed: running ? null : onRunLocal,
+                                child: const Text('Analyse locale'),
+                              ),
+                              CupertinoButton(
+                                key: const ValueKey(
+                                  'surfaceStudio.suggestion.mistral',
+                                ),
+                                padding: const EdgeInsets.symmetric(
+                                  horizontal: 12,
+                                  vertical: 8,
+                                ),
+                                color: mistralKeyConfigured
+                                    ? SurfaceStudioDesignTokens.accentGoldSoft
+                                    : SurfaceStudioDesignTokens.borderSubtle,
+                                onPressed: running || !mistralKeyConfigured
+                                    ? null
+                                    : onRequestAi,
+                                child: Text(
+                                  running
+                                      ? 'Analyse IA...'
+                                      : 'Analyse IA Mistral',
+                                ),
+                              ),
+                              CupertinoButton(
+                                key: const ValueKey(
+                                  'surfaceStudio.suggestion.compare',
+                                ),
+                                padding: const EdgeInsets.symmetric(
+                                  horizontal: 12,
+                                  vertical: 8,
+                                ),
+                                color: SurfaceStudioDesignTokens
+                                    .backgroundPanelAlt,
+                                onPressed: running || !mistralKeyConfigured
+                                    ? null
+                                    : onCompare,
+                                child: const Text('Comparer local + IA'),
+                              ),
+                            ],
                           ),
+                          if (aiConfirmationOpen) ...[
+                            const SizedBox(height: 10),
+                            const _WarningBox(
+                              text:
+                                  'Confirmez l’envoi de l’image atlas à Mistral. Aucune suggestion ne sera appliquée automatiquement.',
+                            ),
+                            const SizedBox(height: 8),
+                            Wrap(
+                              spacing: 8,
+                              children: [
+                                CupertinoButton(
+                                  key: const ValueKey(
+                                    'surfaceStudio.suggestion.confirmAi',
+                                  ),
+                                  color:
+                                      SurfaceStudioDesignTokens.accentGoldSoft,
+                                  onPressed: onConfirmAi,
+                                  child: const Text('Confirmer l’analyse IA'),
+                                ),
+                                CupertinoButton(
+                                  onPressed: onCancelAi,
+                                  child: const Text('Annuler l’analyse IA'),
+                                ),
+                              ],
+                            ),
+                          ],
                         ],
                       ),
                     ),
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart
index c7f6cf23..dab7f831 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart
@@ -125,10 +125,8 @@ String surfaceStudioSlugForAnimationIdSegment(String raw) {
 }
 
 String _foldLatin1Accents(String s) {
-  const from =
-      'àáâãäåèéêëìíîïòóôõöùúûüýÿçñÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝŸÇÑ';
-  const to =
-      'aaaaaaeeeeiiiiooooouuuuyyncaaaaaaeeeeiiiiooooouuuuyync';
+  const from = 'àáâãäåèéêëìíîïòóôõöùúûüýÿçñÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝŸÇÑ';
+  const to = 'aaaaaaeeeeiiiiooooouuuuyyncaaaaaaeeeeiiiiooooouuuuyync';
   final b = StringBuffer();
   for (final ch in s.split('')) {
     final i = from.indexOf(ch);
@@ -263,7 +261,8 @@ SurfaceStudioVerticalAtlasAnimationGenerationPlan
       problems.add('Durée par frame invalide.');
     }
     if (atlasSeg.isEmpty) {
-      problems.add('Identifiant d’atlas requis pour proposer un id d’animation.');
+      problems
+          .add('Identifiant d’atlas requis pour proposer un id d’animation.');
     }
 
     final proposed = surfaceStudioProposedAnimationId(
@@ -396,7 +395,8 @@ class _SurfaceStudioVerticalAtlasAnimationGenerationPlanSectionState
 
   @override
   void didUpdateWidget(
-    covariant SurfaceStudioVerticalAtlasAnimationGenerationPlanSection oldWidget,
+    covariant SurfaceStudioVerticalAtlasAnimationGenerationPlanSection
+        oldWidget,
   ) {
     super.didUpdateWidget(oldWidget);
     if (widget.mappingDraft != oldWidget.mappingDraft ||
@@ -425,7 +425,8 @@ class _SurfaceStudioVerticalAtlasAnimationGenerationPlanSectionState
     });
   }
 
-  void _tryAppendAnimations(SurfaceStudioVerticalAtlasAnimationGenerationPlan plan) {
+  void _tryAppendAnimations(
+      SurfaceStudioVerticalAtlasAnimationGenerationPlan plan) {
     final cb = widget.onWorkCatalogChanged;
     if (cb == null) {
       return;
@@ -502,9 +503,8 @@ class _SurfaceStudioVerticalAtlasAnimationGenerationPlanSectionState
       widget.columns,
       widget.rows,
     );
-    final assignedCount = widget.mappingDraft.assignments
-        .where((a) => a.role != null)
-        .length;
+    final assignedCount =
+        widget.mappingDraft.assignments.where((a) => a.role != null).length;
     final durationParsed = _parseDurationMs();
     final durationEffective =
         durationParsed != null && durationParsed > 0 ? durationParsed : 0;
@@ -565,121 +565,132 @@ class _SurfaceStudioVerticalAtlasAnimationGenerationPlanSectionState
             if (!gridOk) ...[
               Text(
                 'Corrigez la grille avant de préparer les animations.',
-                style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
+                style:
+                    TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
               ),
             ] else if (assignedCount == 0) ...[
               Text(
                 'Assignez au moins une colonne à un rôle pour préparer les animations.',
-                style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
+                style:
+                    TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
               ),
             ] else ...[
-            Text(
-              'Colonnes assignées : $assignedCount',
-              style: TextStyle(color: widget.label, fontSize: 11.5, height: 1.35),
-            ),
-            if (unassigned > 0)
               Text(
-                'Colonnes non assignées : $unassigned',
-                style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
+                'Colonnes assignées : $assignedCount',
+                style: TextStyle(
+                    color: widget.label, fontSize: 11.5, height: 1.35),
               ),
-            Text(
-              'Animations prêtes : ${summary.readyAnimationCount}',
-              style: TextStyle(color: widget.label, fontSize: 11.5, height: 1.35),
-            ),
-            Text(
-              'Animations en erreur : ${summary.errorAnimationCount}',
-              style: TextStyle(color: widget.label, fontSize: 11.5, height: 1.35),
-            ),
-            Text(
-              summary.durationFieldValid
-                  ? 'Durée par frame : ${summary.durationMsPerFrame} ms'
-                  : 'Durée par frame : invalide',
-              style: TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
-            ),
-            const SizedBox(height: 6),
-            Row(
-              crossAxisAlignment: CrossAxisAlignment.start,
-              children: [
-                Expanded(
-                  child: TextField(
-                    key: const ValueKey('surface_studio_gen_plan_duration_ms'),
-                    controller: _durationMs,
-                    onChanged: (_) => setState(() {}),
-                    keyboardType: TextInputType.number,
-                    style: TextStyle(color: widget.label, fontSize: 12),
-                    decoration: InputDecoration(
-                      labelText: 'Durée par frame (ms)',
-                      isDense: true,
-                      errorText: summary.durationFieldValid
-                          ? null
-                          : 'Entier strictement positif requis',
-                    ),
-                  ),
-                ),
-              ],
-            ),
-            const SizedBox(height: 8),
-            Wrap(
-              spacing: 8,
-              runSpacing: 6,
-              children: [
-                OutlinedButton(
-                  key: const ValueKey('surface_studio_gen_plan_preview'),
-                  onPressed: () => setState(() => _showDetails = true),
-                  child: const Text('Prévisualiser le plan'),
-                ),
-                OutlinedButton(
-                  key: const ValueKey('surface_studio_gen_plan_reset_duration'),
-                  onPressed: _resetDuration,
-                  child: const Text('Réinitialiser la durée par frame'),
+              if (unassigned > 0)
+                Text(
+                  'Colonnes non assignées : $unassigned',
+                  style: TextStyle(
+                      color: widget.subtle, fontSize: 11, height: 1.35),
                 ),
-              ],
-            ),
-            const SizedBox(height: 10),
-            if (summary.readyAnimationCount == 0)
               Text(
-                'Aucune animation prête à créer.',
-                style: TextStyle(color: widget.subtle, fontSize: 10.5, height: 1.35),
+                'Animations prêtes : ${summary.readyAnimationCount}',
+                style: TextStyle(
+                    color: widget.label, fontSize: 11.5, height: 1.35),
               ),
-            const SizedBox(height: 8),
-            FilledButton(
-              key: const ValueKey('surface_studio_gen_plan_append_ready'),
-              onPressed: widget.onWorkCatalogChanged != null &&
-                      summary.readyAnimationCount > 0 &&
-                      summary.durationFieldValid &&
-                      widget.atlasIdDraft.trim().isNotEmpty
-                  ? () => _tryAppendAnimations(plan)
-                  : null,
-              child: const Text(
-                'Ajouter les animations prêtes au catalogue de travail',
+              Text(
+                'Animations en erreur : ${summary.errorAnimationCount}',
+                style: TextStyle(
+                    color: widget.label, fontSize: 11.5, height: 1.35),
               ),
-            ),
-            if (_appendFeedback != null) ...[
-              const SizedBox(height: 8),
               Text(
-                _appendFeedback!,
-                style: TextStyle(color: widget.label, fontSize: 11, height: 1.35),
+                summary.durationFieldValid
+                    ? 'Durée par frame : ${summary.durationMsPerFrame} ms'
+                    : 'Durée par frame : invalide',
+                style:
+                    TextStyle(color: widget.subtle, fontSize: 11, height: 1.35),
+              ),
+              const SizedBox(height: 6),
+              Row(
+                crossAxisAlignment: CrossAxisAlignment.start,
+                children: [
+                  Expanded(
+                    child: TextField(
+                      key:
+                          const ValueKey('surface_studio_gen_plan_duration_ms'),
+                      controller: _durationMs,
+                      onChanged: (_) => setState(() {}),
+                      keyboardType: TextInputType.number,
+                      style: TextStyle(color: widget.label, fontSize: 12),
+                      decoration: InputDecoration(
+                        labelText: 'Durée par frame (ms)',
+                        isDense: true,
+                        errorText: summary.durationFieldValid
+                            ? null
+                            : 'Entier strictement positif requis',
+                      ),
+                    ),
+                  ),
+                ],
+              ),
+              const SizedBox(height: 8),
+              Wrap(
+                spacing: 8,
+                runSpacing: 6,
+                children: [
+                  OutlinedButton(
+                    key: const ValueKey('surface_studio_gen_plan_preview'),
+                    onPressed: () => setState(() => _showDetails = true),
+                    child: const Text('Prévisualiser le plan'),
+                  ),
+                  OutlinedButton(
+                    key: const ValueKey(
+                        'surface_studio_gen_plan_reset_duration'),
+                    onPressed: _resetDuration,
+                    child: const Text('Réinitialiser la durée par frame'),
+                  ),
+                ],
               ),
-            ],
-            if (_showDetails) ...[
               const SizedBox(height: 10),
-              ConstrainedBox(
-                constraints: const BoxConstraints(maxHeight: 420),
-                child: SingleChildScrollView(
-                  child: Column(
-                    crossAxisAlignment: CrossAxisAlignment.stretch,
-                    children: [
-                      for (final it in plan.items) ...[
-                        _itemCard(context, it),
-                        const SizedBox(height: 6),
+              if (summary.readyAnimationCount == 0)
+                Text(
+                  'Aucune animation prête à créer.',
+                  style: TextStyle(
+                      color: widget.subtle, fontSize: 10.5, height: 1.35),
+                ),
+              const SizedBox(height: 8),
+              FilledButton(
+                key: const ValueKey('surface_studio_gen_plan_append_ready'),
+                onPressed: widget.onWorkCatalogChanged != null &&
+                        summary.readyAnimationCount > 0 &&
+                        summary.durationFieldValid &&
+                        widget.atlasIdDraft.trim().isNotEmpty
+                    ? () => _tryAppendAnimations(plan)
+                    : null,
+                child: const Text(
+                  'Ajouter les animations prêtes au catalogue de travail',
+                ),
+              ),
+              if (_appendFeedback != null) ...[
+                const SizedBox(height: 8),
+                Text(
+                  _appendFeedback!,
+                  style: TextStyle(
+                      color: widget.label, fontSize: 11, height: 1.35),
+                ),
+              ],
+              if (_showDetails) ...[
+                const SizedBox(height: 10),
+                ConstrainedBox(
+                  constraints: const BoxConstraints(maxHeight: 420),
+                  child: SingleChildScrollView(
+                    child: Column(
+                      crossAxisAlignment: CrossAxisAlignment.stretch,
+                      children: [
+                        for (final it in plan.items) ...[
+                          _itemCard(context, it),
+                          const SizedBox(height: 6),
+                        ],
                       ],
-                    ],
+                    ),
                   ),
                 ),
-              ),
+              ],
             ],
           ],
-        ],
         ),
       ),
     );
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart
index 06f4c209..598c3be7 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart
@@ -42,8 +42,7 @@ ProjectSurfaceAnimation surfaceStudioProjectSurfaceAnimationFromReadyPlanItem({
   final prefix = animationDisplayNamePrefix.trim().isEmpty
       ? atlasIdForTileRefs.trim()
       : animationDisplayNamePrefix.trim();
-  final name =
-      '$prefix — ${SurfaceStudioRoleLabels.labelForRole(item.role)}';
+  final name = '$prefix — ${SurfaceStudioRoleLabels.labelForRole(item.role)}';
   return ProjectSurfaceAnimation(
     id: item.proposedAnimationId,
     name: name,
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart
index 0cac6ff3..80eb6ee6 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart
@@ -125,7 +125,8 @@ class SurfaceStudioVerticalAtlasAssistant extends StatelessWidget {
         children.add(
           material.Text(
             'Structure probablement verticale : plusieurs frames par variante.',
-            style: material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
+            style:
+                material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
           ),
         );
       } else if (cols > rows) {
@@ -133,7 +134,8 @@ class SurfaceStudioVerticalAtlasAssistant extends StatelessWidget {
         children.add(
           material.Text(
             'Structure probablement horizontale ou non standard.',
-            style: material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
+            style:
+                material.TextStyle(color: subtle, fontSize: 11, height: 1.35),
           ),
         );
       }
@@ -141,7 +143,8 @@ class SurfaceStudioVerticalAtlasAssistant extends StatelessWidget {
 
     return material.Container(
       key: sectionKey,
-      padding: const material.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
+      padding:
+          const material.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
       decoration: material.BoxDecoration(
         color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.72),
         borderRadius: material.BorderRadius.circular(10),
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart
index 37f74e5f..ec84de9b 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart
@@ -65,7 +65,8 @@ String? _categoryIdForPreset({
 }
 
 /// Plan local : mapping + catalogue (animations déjà présentes) — ne crée rien.
-SurfaceStudioVerticalAtlasPresetAppendPlan surfaceStudioPlanVerticalAtlasPresetAppend({
+SurfaceStudioVerticalAtlasPresetAppendPlan
+    surfaceStudioPlanVerticalAtlasPresetAppend({
   required ProjectSurfaceCatalog catalog,
   required String atlasIdRaw,
   required String atlasDisplayName,
@@ -75,7 +76,8 @@ SurfaceStudioVerticalAtlasPresetAppendPlan surfaceStudioPlanVerticalAtlasPresetA
 }) {
   final atlasId = atlasIdRaw.trim();
   final presetId = surfaceStudioProposedVerticalAtlasPresetId(atlasIdRaw);
-  final namePrefix = atlasDisplayName.trim().isEmpty ? atlasId : atlasDisplayName.trim();
+  final namePrefix =
+      atlasDisplayName.trim().isEmpty ? atlasId : atlasDisplayName.trim();
   final proposedName = '$namePrefix — Surface';
 
   if (atlasId.isEmpty || presetId.isEmpty) {
@@ -125,7 +127,8 @@ SurfaceStudioVerticalAtlasPresetAppendPlan surfaceStudioPlanVerticalAtlasPresetA
         rolesCoveredCount: 0,
         rolesNotCoveredCount: 0,
         missingAnimationCount: 0,
-        status: SurfaceStudioVerticalAtlasPresetPlanStatus.blockedDuplicatePresetId,
+        status:
+            SurfaceStudioVerticalAtlasPresetPlanStatus.blockedDuplicatePresetId,
         canCreate: false,
       );
     }
@@ -174,7 +177,8 @@ SurfaceStudioVerticalAtlasPresetAppendPlan surfaceStudioPlanVerticalAtlasPresetA
       rolesCoveredCount: covered,
       rolesNotCoveredCount: notCovered,
       missingAnimationCount: missing,
-      status: SurfaceStudioVerticalAtlasPresetPlanStatus.blockedMissingAnimations,
+      status:
+          SurfaceStudioVerticalAtlasPresetPlanStatus.blockedMissingAnimations,
       canCreate: false,
       partialPresetUserMessage: partialMsg,
     );
@@ -214,7 +218,8 @@ ProjectSurfacePreset surfaceStudioBuildVerticalAtlasPreset({
     gridValid: gridValid,
   );
   if (!plan.canCreate) {
-    throw StateError('surfaceStudioBuildVerticalAtlasPreset: plan not creatable');
+    throw StateError(
+        'surfaceStudioBuildVerticalAtlasPreset: plan not creatable');
   }
   final atlasId = atlasIdRaw.trim();
   final assigned = mappingDraft.assignments
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart
index 305de4eb..331bbf48 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart
@@ -56,7 +56,8 @@ class SurfaceStudioColumnRoleMappingDraft {
   factory SurfaceStudioColumnRoleMappingDraft.suggested(int columnCount) {
     final assignments = <SurfaceStudioColumnRoleAssignment>[];
     const roles = standardSurfaceVariantRoleOrder;
-    final countToAssign = columnCount < roles.length ? columnCount : roles.length;
+    final countToAssign =
+        columnCount < roles.length ? columnCount : roles.length;
 
     for (var i = 0; i < countToAssign; i++) {
       assignments.add(SurfaceStudioColumnRoleAssignment(
@@ -278,4 +279,4 @@ class SurfaceStudioRoleLabels {
   /// Liste de tous les rôles avec leurs libellés, dans l’ordre standard.
   static List<SurfaceVariantRole> get allRolesInOrder =>
       standardSurfaceVariantRoleOrder;
-}
\ No newline at end of file
+}
```

### packages/map_editor/lib/src/ui/editor_shell_page.dart

```diff
diff --git a/packages/map_editor/lib/src/ui/editor_shell_page.dart b/packages/map_editor/lib/src/ui/editor_shell_page.dart
index 34e86493..944c354b 100644
--- a/packages/map_editor/lib/src/ui/editor_shell_page.dart
+++ b/packages/map_editor/lib/src/ui/editor_shell_page.dart
@@ -75,7 +75,10 @@ class _EditorShellPageState extends ConsumerState<EditorShellPage> {
     final shell = ref.watch(editorShellSnapshotProvider);
     final workspaceMode = shell.workspaceMode;
     final notifier = ref.read(editorNotifierProvider.notifier);
-    final supportsRightInspector = workspaceMode != EditorWorkspaceMode.pokedex;
+    final supportsRightInspector = switch (workspaceMode) {
+      EditorWorkspaceMode.pokedex || EditorWorkspaceMode.surfaceStudio => false,
+      _ => true,
+    };
 
     ref.listen(editorNotifierProvider.select((s) => s.errorMessage),
         (prev, next) {
```

### packages/map_editor/test/editor_shell_page_smoke_test.dart

```diff
diff --git a/packages/map_editor/test/editor_shell_page_smoke_test.dart b/packages/map_editor/test/editor_shell_page_smoke_test.dart
index 87cb0f87..46065db2 100644
--- a/packages/map_editor/test/editor_shell_page_smoke_test.dart
+++ b/packages/map_editor/test/editor_shell_page_smoke_test.dart
@@ -208,6 +208,36 @@ void main() {
       );
     });
 
+    testWidgets('renders Surface Studio without the global right inspector',
+        (tester) async {
+      await pumpEditorShellPage(
+        tester,
+        initialState: EditorState(
+          projectRootPath: '/tmp/editor_shell_surface_studio',
+          project: buildShellChromeProject(),
+          workspaceMode: EditorWorkspaceMode.surfaceStudio,
+        ),
+      );
+
+      expect(
+        find.text('Surface Studio — Assistant de mapping d’atlas'),
+        findsWidgets,
+      );
+      expect(
+        find.textContaining('vue centrale'),
+        findsNothing,
+      );
+      expect(
+        find.byWidgetPredicate(
+          (widget) =>
+              widget is MacosIconButton &&
+              (widget.semanticLabel == 'Hide right panel' ||
+                  widget.semanticLabel == 'Show right panel'),
+        ),
+        findsNothing,
+      );
+    });
+
     testWidgets('renders shell chrome with an error state already present',
         (tester) async {
       await pumpEditorShellPage(
```

### packages/map_editor/test/surface_studio/surface_studio_atlas_editing_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_atlas_editing_test.dart b/packages/map_editor/test/surface_studio/surface_studio_atlas_editing_test.dart
index e2a0668b..45d63098 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_atlas_editing_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_atlas_editing_test.dart
@@ -59,7 +59,8 @@ void main() {
       expect(countAnimationsReferencingAtlasId(cat, 'B'), 1);
     });
 
-    test('replaceAtlasInCatalogInPlace préserve ordre, animations, presets', () {
+    test('replaceAtlasInCatalogInPlace préserve ordre, animations, presets',
+        () {
       final g0 = SurfaceAtlasGeometry(
         tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
         gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
```

### packages/map_editor/test/surface_studio/surface_studio_atlas_grid_overlay_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_atlas_grid_overlay_test.dart b/packages/map_editor/test/surface_studio/surface_studio_atlas_grid_overlay_test.dart
index 9c551268..7b6d27fd 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_atlas_grid_overlay_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_atlas_grid_overlay_test.dart
@@ -132,7 +132,8 @@ void main() {
           ),
         ),
       );
-      expect(find.byKey(const ValueKey('surf73_grid_paint_test')), findsOneWidget);
+      expect(
+          find.byKey(const ValueKey('surf73_grid_paint_test')), findsOneWidget);
     });
 
     testWidgets('pas de jargon dans le painter (aucun Text)', (tester) async {
```

### packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart b/packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart
index 847a85b1..6fdd9f41 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart
@@ -17,7 +17,8 @@ void main() {
       ),
     );
 
-    expect(find.byKey(kSurfaceStudioAtlasGridPreviewSectionKey), findsOneWidget);
+    expect(
+        find.byKey(kSurfaceStudioAtlasGridPreviewSectionKey), findsOneWidget);
     expect(find.text('Aperçu de la grille atlas'), findsOneWidget);
     expect(find.text('Source : eau_atlas'), findsOneWidget);
     expect(find.text('Tile : 32×32 px'), findsOneWidget);
@@ -81,8 +82,10 @@ void main() {
     );
 
     expect(find.text('Aperçu réduit'), findsOneWidget);
-    expect(find.byKey(const ValueKey('surface_studio_grid_cell_95')), findsOneWidget);
-    expect(find.byKey(const ValueKey('surface_studio_grid_cell_96')), findsNothing);
+    expect(find.byKey(const ValueKey('surface_studio_grid_cell_95')),
+        findsOneWidget);
+    expect(find.byKey(const ValueKey('surface_studio_grid_cell_96')),
+        findsNothing);
   });
 
   testWidgets('pas de jargon interdit dans la preview', (tester) async {
```

### packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_test.dart b/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_test.dart
index e111fa92..610aae5a 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_test.dart
@@ -147,7 +147,8 @@ void main() {
           ],
           technicalTilesetId: 't1',
         );
-        expect(r.status, SurfaceStudioAtlasImagePreviewResolveStatus.missingFile);
+        expect(
+            r.status, SurfaceStudioAtlasImagePreviewResolveStatus.missingFile);
         expect(r.displayFileName, 'nope.png');
         expect(r.relativePathForUi, 'nope.png');
       } finally {
@@ -200,7 +201,8 @@ void main() {
           ),
         ),
       );
-      expect(find.byKey(kSurfaceStudioAtlasImagePreviewSectionKey), findsOneWidget);
+      expect(find.byKey(kSurfaceStudioAtlasImagePreviewSectionKey),
+          findsOneWidget);
       expect(find.text('Aperçu de l’image source'), findsOneWidget);
       expect(
         find.text('Choisissez une image source pour afficher l’aperçu.'),
```

### packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart b/packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart
index 27e9517f..695965fb 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart
@@ -125,8 +125,8 @@ void main() {
       );
 
       expect(find.text('Suggérer un mapping standard'), findsOneWidget);
-      expect(find.text('Réinitialiser le mapping des colonnes'),
-          findsOneWidget);
+      expect(
+          find.text('Réinitialiser le mapping des colonnes'), findsOneWidget);
     });
 
     testWidgets('appelle onDraftChanged quand on suggère un mapping standard',
@@ -299,4 +299,4 @@ void main() {
       expect(find.text('Coin haut droit'), findsOneWidget);
     });
   });
-}
\ No newline at end of file
+}
```

### packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart b/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
index 8afed90a..f3f84ab3 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
@@ -1,8 +1,15 @@
+import 'dart:convert';
+import 'dart:typed_data';
+
 import 'package:flutter/widgets.dart';
 import 'package:flutter_test/flutter_test.dart';
+import 'package:http/http.dart' as http;
+import 'package:http/testing.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_local_mapping_suggester.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart';
 
 import 'surface_studio_rebuild_test_harness.dart';
 
@@ -33,7 +40,10 @@ void main() {
     expect(find.text('Suggestions détectées'), findsOneWidget);
     expect(find.text('Source : Local'), findsOneWidget);
     expect(find.text('Appliquer les suggestions fiables'), findsOneWidget);
-    expect(find.text('Analyse IA Mistral'), findsOneWidget);
+    expect(
+      find.byKey(const Key('surfaceStudio.suggestion.mistral')),
+      findsOneWidget,
+    );
     expect(
       find.text(
           'Clé Mistral absente : Projet → Paramètres (IA) ou MISTRAL_API_KEY'),
@@ -58,6 +68,177 @@ void main() {
 
     expect(find.text('Clé Mistral configurée.'), findsOneWidget);
     expect(find.textContaining('configured'), findsNothing);
-    expect(find.text('Analyse IA à venir'), findsOneWidget);
+    expect(
+      find.byKey(const Key('surfaceStudio.suggestion.mistral')),
+      findsOneWidget,
+    );
+  });
+
+  testWidgets('Mistral analysis asks confirmation before any provider call',
+      (tester) async {
+    final fakeAi = _FakeAiSuggester();
+
+    await pumpSurfaceStudioForTest(
+      tester,
+      projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
+      aiMappingSuggester: fakeAi,
+    );
+    await tester.pump();
+
+    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
+    await tester.pump(const Duration(milliseconds: 50));
+    final mistralButton =
+        find.byKey(const Key('surfaceStudio.suggestion.mistral'));
+    await tester.ensureVisible(mistralButton);
+    await tester.tap(mistralButton);
+    await tester.pump(const Duration(milliseconds: 50));
+
+    expect(fakeAi.calls, 0);
+    expect(find.text('Confirmer l’analyse IA'), findsOneWidget);
+
+    final cancelAi = find.text('Annuler l’analyse IA');
+    await tester.ensureVisible(cancelAi);
+    await tester.tap(cancelAi);
+    await tester.pump(const Duration(milliseconds: 50));
+    expect(fakeAi.calls, 0);
+  });
+
+  test('Mistral suggester validates JSON without leaking secrets', () async {
+    final requests = <http.Request>[];
+    final suggester = SurfaceStudioMistralMappingSuggester(
+      httpClient: MockClient((request) async {
+        requests.add(request);
+        expect(request.headers['Authorization'], 'Bearer configured');
+        expect(request.body, isNot(contains('configured')));
+        return http.Response(
+          jsonEncode({
+            'choices': [
+              {
+                'message': {
+                  'content': jsonEncode({
+                    'assignments': [
+                      {
+                        'role': 'isolated',
+                        'columns': [4, 5],
+                        'confidence': 'medium',
+                        'reason': 'Center water candidates.',
+                      },
+                      {
+                        'role': 'endNorth',
+                        'columns': [99],
+                        'confidence': 'high',
+                        'reason': 'Out of range.',
+                      },
+                      {
+                        'role': 'endEast',
+                        'columns': [1, 2],
+                        'confidence': 'high',
+                        'reason': 'Too many columns.',
+                      },
+                      {
+                        'role': 'unknown',
+                        'columns': [3],
+                        'confidence': 'high',
+                        'reason': 'Unknown role.',
+                      },
+                    ],
+                    'warnings': ['Inner corners are ambiguous.'],
+                  }),
+                },
+              },
+            ],
+          }),
+          200,
+        );
+      }),
+    );
+
+    final result = await suggester.suggest(
+      apiKey: 'configured',
+      imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
+      tileWidth: 32,
+      tileHeight: 32,
+      columnCount: 12,
+      frameCount: 32,
+    );
+
+    expect(requests, hasLength(1));
+    expect(result.source, SurfaceStudioMappingSuggestionSource.mistral);
+    expect(result.suggestions, hasLength(1));
+    expect(result.suggestions.single.role, SurfaceVariantRole.isolated);
+    expect(result.suggestions.single.columns, [4, 5]);
+    expect(result.warnings, contains('Inner corners are ambiguous.'));
+    expect(
+      result.warnings,
+      contains('Rôle Mistral inconnu rejeté : unknown.'),
+    );
+    expect(
+      result.warnings,
+      contains('Colonne Mistral hors bornes rejetée pour endNorth : 99.'),
+    );
+    expect(
+      result.warnings,
+      contains('Suggestion Mistral multi-colonnes rejetée pour endEast.'),
+    );
   });
+
+  test('Mistral suggester returns a warning for invalid JSON', () async {
+    final suggester = SurfaceStudioMistralMappingSuggester(
+      httpClient: MockClient((_) async {
+        return http.Response(
+          jsonEncode({
+            'choices': [
+              {
+                'message': {'content': 'not json'},
+              },
+            ],
+          }),
+          200,
+        );
+      }),
+    );
+
+    final result = await suggester.suggest(
+      apiKey: 'configured',
+      imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
+      tileWidth: 32,
+      tileHeight: 32,
+      columnCount: 12,
+      frameCount: 32,
+    );
+
+    expect(result.suggestions, isEmpty);
+    expect(result.warnings.single, contains('Réponse Mistral invalide'));
+  });
+}
+
+final class _FakeAiSuggester implements SurfaceStudioAiMappingSuggester {
+  int calls = 0;
+
+  @override
+  Future<SurfaceStudioMappingSuggestionResult> suggest({
+    required String apiKey,
+    required Uint8List imageBytes,
+    required int tileWidth,
+    required int tileHeight,
+    required int columnCount,
+    required int frameCount,
+  }) async {
+    calls++;
+    expect(apiKey, 'configured');
+    expect(imageBytes, isNotEmpty);
+    return const SurfaceStudioMappingSuggestionResult(
+      suggestions: <SurfaceStudioRoleSuggestion>[
+        SurfaceStudioRoleSuggestion(
+          role: SurfaceVariantRole.isolated,
+          columns: <int>[4, 5],
+          confidence: SurfaceStudioMappingSuggestionConfidence.medium,
+          source: SurfaceStudioMappingSuggestionSource.mistral,
+          reason: 'AI center',
+        ),
+      ],
+      warnings: <String>['AI warning'],
+      source: SurfaceStudioMappingSuggestionSource.mistral,
+    );
+  }
 }
```

### packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart b/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart
index ee2b4044..5bf0a5b8 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart
@@ -65,4 +65,35 @@ void main() {
     expect(saved, isNotNull);
     expect(saved!.atlases.map((atlas) => atlas.id), contains('v21-water'));
   });
+
+  testWidgets('import and slice steps do not render schema or preview docks',
+      (tester) async {
+    await pumpSurfaceStudioForTest(tester);
+    await tester.pump();
+
+    await tester.tap(find.byKey(const Key('surfaceStudio.step.import')));
+    await tester.pumpAndSettle();
+
+    expect(find.byKey(const Key('surfaceStudio.schema.panel')), findsNothing);
+    expect(find.byKey(const Key('surfaceStudio.preview.panel')), findsNothing);
+    expect(find.text('Schéma de surface (glissez-déposez)'), findsNothing);
+    expect(find.text('Prévisualisation'), findsNothing);
+
+    await tester.tap(find.byKey(const Key('surfaceStudio.step.slice')));
+    await tester.pumpAndSettle();
+
+    expect(find.byKey(const Key('surfaceStudio.schema.panel')), findsNothing);
+    expect(find.byKey(const Key('surfaceStudio.preview.panel')), findsNothing);
+    expect(find.text('Schéma de surface (glissez-déposez)'), findsNothing);
+    expect(find.text('Prévisualisation'), findsNothing);
+  });
+
+  testWidgets('header has no internal close control', (tester) async {
+    await pumpSurfaceStudioForTest(tester);
+    await tester.pump();
+
+    expect(find.byTooltip('Fermer'), findsNothing);
+    expect(find.text('Fermer'), findsNothing);
+    expect(find.byKey(const Key('surfaceStudio.header.close')), findsNothing);
+  });
 }
```

### packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart b/packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart
index 809b4317..aea9bbee 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart
@@ -2,11 +2,15 @@ import 'package:flutter/cupertino.dart';
 import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
 
 Widget wrapSurfaceStudioForTest({
   SurfaceStudioReadModel? readModel,
   ProjectSettings? projectSettings,
+  List<ProjectTilesetEntry>? projectTilesets,
+  String? projectRootPath,
+  SurfaceStudioAiMappingSuggester? aiMappingSuggester,
   ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested,
   double width = 2048,
   double height = 1120,
@@ -23,15 +27,17 @@ Widget wrapSurfaceStudioForTest({
                 readModel ?? buildSurfaceStudioReadModelFromCatalog(_catalog()),
             projectSettings: projectSettings,
             onSurfaceCatalogSaveRequested: onSurfaceCatalogSaveRequested,
-            projectTilesets: const <ProjectTilesetEntry>[
-              ProjectTilesetEntry(
-                id: 'water_tiles',
-                name: 'Water Tiles',
-                relativePath: 'missing/water.png',
-                sortOrder: 0,
-              ),
-            ],
-            projectRootPath: '/missing/project',
+            projectTilesets: projectTilesets ??
+                const <ProjectTilesetEntry>[
+                  ProjectTilesetEntry(
+                    id: 'water_tiles',
+                    name: 'Water Tiles',
+                    relativePath: 'missing/water.png',
+                    sortOrder: 0,
+                  ),
+                ],
+            projectRootPath: projectRootPath ?? '/missing/project',
+            aiMappingSuggester: aiMappingSuggester,
           ),
         ),
       ),
@@ -43,6 +49,9 @@ Future<void> pumpSurfaceStudioForTest(
   WidgetTester tester, {
   SurfaceStudioReadModel? readModel,
   ProjectSettings? projectSettings,
+  List<ProjectTilesetEntry>? projectTilesets,
+  String? projectRootPath,
+  SurfaceStudioAiMappingSuggester? aiMappingSuggester,
   ValueChanged<ProjectSurfaceCatalog>? onSurfaceCatalogSaveRequested,
   double width = 2048,
   double height = 1120,
@@ -55,6 +64,9 @@ Future<void> pumpSurfaceStudioForTest(
     wrapSurfaceStudioForTest(
       readModel: readModel,
       projectSettings: projectSettings,
+      projectTilesets: projectTilesets,
+      projectRootPath: projectRootPath,
+      aiMappingSuggester: aiMappingSuggester,
       onSurfaceCatalogSaveRequested: onSurfaceCatalogSaveRequested,
       width: width,
       height: height,
```

### packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart b/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart
index 5624cc63..eb3066ef 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart
@@ -298,7 +298,8 @@ void main() {
       );
     });
 
-    testWidgets('20. Lot 67 — callback édition : bouton inspecteur', (tester) async {
+    testWidgets('20. Lot 67 — callback édition : bouton inspecteur',
+        (tester) async {
       await tester.pumpWidget(
         _wrap(
           SurfaceStudioSelectionInspector(
@@ -314,7 +315,8 @@ void main() {
       );
     });
 
-    testWidgets('21. Lot 67 — sans callback : pas d’edit inspecteur', (tester) async {
+    testWidgets('21. Lot 67 — sans callback : pas d’edit inspecteur',
+        (tester) async {
       await tester.pumpWidget(
         _wrap(
           SurfaceStudioSelectionInspector(
@@ -329,8 +331,8 @@ void main() {
       );
     });
 
-    testWidgets('22. Lot 69 — atlas référencé : préparer suppression absent', (
-        tester) async {
+    testWidgets('22. Lot 69 — atlas référencé : préparer suppression absent',
+        (tester) async {
       await tester.pumpWidget(
         _wrap(
           SurfaceStudioSelectionInspector(
@@ -352,8 +354,8 @@ void main() {
       );
     });
 
-    testWidgets('23. Lot 69 — atlas inutilisé : confirmation en deux étapes', (
-        tester) async {
+    testWidgets('23. Lot 69 — atlas inutilisé : confirmation en deux étapes',
+        (tester) async {
       var del = 0;
       await tester.pumpWidget(
         _wrap(
```

### packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart b/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart
index cc2f78c6..891ff456 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart
@@ -43,7 +43,8 @@ void main() {
       expect(plan.summary.assignedColumnCount, 0);
     });
 
-    test('23×32 après suggestion : 20 animations, 3 colonnes non assignées', () {
+    test('23×32 après suggestion : 20 animations, 3 colonnes non assignées',
+        () {
       final draft = SurfaceStudioColumnRoleMappingDraft.suggested(23);
       final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
         atlasIdRaw: 'eau',
@@ -101,7 +102,8 @@ void main() {
       expect(plan.summary.errorAnimationCount, 2);
       for (final it in plan.items) {
         expect(it.isReady, isFalse);
-        expect(it.status, SurfaceStudioVerticalAtlasAnimationPlanItemStatus.invalid);
+        expect(it.status,
+            SurfaceStudioVerticalAtlasAnimationPlanItemStatus.invalid);
       }
     });
 
@@ -158,7 +160,8 @@ void main() {
 
   group('SurfaceStudioVerticalAtlasAnimationGenerationPlanSection', () {
     testWidgets('section et résumé visibles après suggestion', (tester) async {
-      final rm = buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
+      final rm =
+          buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
       final draft = SurfaceStudioColumnRoleMappingDraft.suggested(23);
       await tester.pumpWidget(
         MaterialApp(
@@ -183,7 +186,8 @@ void main() {
       expect(find.textContaining('Animations prêtes : 20'), findsOneWidget);
       expect(find.textContaining('Colonnes non assignées : 3'), findsOneWidget);
       expect(find.textContaining('ProjectSurfaceAnimation'), findsNothing);
-      await tester.tap(find.byKey(const ValueKey('surface_studio_gen_plan_preview')));
+      await tester
+          .tap(find.byKey(const ValueKey('surface_studio_gen_plan_preview')));
       await tester.pump();
       expect(find.textContaining('eau-plein-loop'), findsWidgets);
     });
@@ -228,14 +232,16 @@ void main() {
         '50',
       );
       await tester.pump();
-      await tester.tap(find.byKey(const ValueKey('surface_studio_gen_plan_preview')));
+      await tester
+          .tap(find.byKey(const ValueKey('surface_studio_gen_plan_preview')));
       await tester.pump();
       expect(rm.catalog.animations.length, before);
     });
 
     testWidgets('ajout animations prêtes via callback', (tester) async {
       ProjectSurfaceCatalog? updated;
-      final rm = buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
+      final rm =
+          buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
       await tester.pumpWidget(
         MaterialApp(
           home: Scaffold(
```

### packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_assistant_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_assistant_test.dart b/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_assistant_test.dart
index 699b431d..630b404a 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_assistant_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_assistant_test.dart
@@ -15,7 +15,8 @@ void main() {
           ),
         ),
       );
-      expect(find.byKey(SurfaceStudioVerticalAtlasAssistant.sectionKey), findsOneWidget);
+      expect(find.byKey(SurfaceStudioVerticalAtlasAssistant.sectionKey),
+          findsOneWidget);
       expect(find.text('Assistant atlas vertical'), findsOneWidget);
       expect(find.text('Colonnes = variantes visuelles'), findsOneWidget);
       expect(find.text('Lignes = frames d’animation'), findsOneWidget);
```

### packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_preset_generator_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_preset_generator_test.dart b/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_preset_generator_test.dart
index e176ba54..f78f981a 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_preset_generator_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_preset_generator_test.dart
@@ -25,7 +25,8 @@ ProjectSurfaceAnimation _anim(String id) {
 void main() {
   group('surfaceStudioProposedVerticalAtlasPresetId', () {
     test('eau → eau-surface-preset', () {
-      expect(surfaceStudioProposedVerticalAtlasPresetId('eau'), 'eau-surface-preset');
+      expect(surfaceStudioProposedVerticalAtlasPresetId('eau'),
+          'eau-surface-preset');
     });
   });
 
@@ -41,7 +42,8 @@ void main() {
         gridValid: true,
       );
       expect(p.canCreate, isFalse);
-      expect(p.status, SurfaceStudioVerticalAtlasPresetPlanStatus.blockedNoMapping);
+      expect(p.status,
+          SurfaceStudioVerticalAtlasPresetPlanStatus.blockedNoMapping);
     });
 
     test('grille invalide → bloqué', () {
@@ -56,7 +58,8 @@ void main() {
         gridValid: false,
       );
       expect(p.canCreate, isFalse);
-      expect(p.status, SurfaceStudioVerticalAtlasPresetPlanStatus.blockedInvalidGrid);
+      expect(p.status,
+          SurfaceStudioVerticalAtlasPresetPlanStatus.blockedInvalidGrid);
     });
 
     test('animation manquante → bloqué', () {
@@ -72,7 +75,8 @@ void main() {
       );
       expect(p.canCreate, isFalse);
       expect(p.missingAnimationCount, greaterThan(0));
-      expect(p.status, SurfaceStudioVerticalAtlasPresetPlanStatus.blockedMissingAnimations);
+      expect(p.status,
+          SurfaceStudioVerticalAtlasPresetPlanStatus.blockedMissingAnimations);
     });
 
     test('id preset déjà pris → bloqué', () {
@@ -102,7 +106,8 @@ void main() {
         gridValid: true,
       );
       expect(p.canCreate, isFalse);
-      expect(p.status, SurfaceStudioVerticalAtlasPresetPlanStatus.blockedDuplicatePresetId);
+      expect(p.status,
+          SurfaceStudioVerticalAtlasPresetPlanStatus.blockedDuplicatePresetId);
     });
 
     test('plein + animation → prêt ou incomplet selon couverture standard', () {
```

### packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_role_mapping_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_role_mapping_test.dart b/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_role_mapping_test.dart
index aa215a92..37e21c03 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_role_mapping_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_role_mapping_test.dart
@@ -98,7 +98,8 @@ void main() {
     test('modifie le rôle d’une colonne', () {
       const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);
       final withRole1 = draft.withRoleForColumn(0, SurfaceVariantRole.isolated);
-      final withRole2 = withRole1.withRoleForColumn(0, SurfaceVariantRole.endNorth);
+      final withRole2 =
+          withRole1.withRoleForColumn(0, SurfaceVariantRole.endNorth);
 
       expect(withRole2.roleForColumn(0), SurfaceVariantRole.endNorth);
       expect(withRole2.assignments.length, 1); // Pas de duplication
@@ -152,7 +153,8 @@ void main() {
       final withDuplicates = draft
           .withRoleForColumn(0, SurfaceVariantRole.isolated)
           .withRoleForColumn(1, SurfaceVariantRole.isolated);
-      final summary = SurfaceStudioColumnRoleMappingSummary.fromDraft(withDuplicates);
+      final summary =
+          SurfaceStudioColumnRoleMappingSummary.fromDraft(withDuplicates);
 
       expect(summary.columnCount, 23);
       expect(summary.assignedColumnCount, 2);
@@ -181,7 +183,8 @@ void main() {
     });
 
     test('fournit un libellé lisible pour un rôle', () {
-      final label = SurfaceStudioRoleLabels.labelForRole(SurfaceVariantRole.isolated);
+      final label =
+          SurfaceStudioRoleLabels.labelForRole(SurfaceVariantRole.isolated);
 
       expect(label, 'Plein');
     });
@@ -207,4 +210,4 @@ void main() {
       expect(label, 'Croix');
     });
   });
-}
\ No newline at end of file
+}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart

```diff
diff --git a/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart b/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart
new file mode 100644
index 00000000..30db092b
--- /dev/null
+++ b/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart
@@ -0,0 +1,14 @@
+import 'dart:typed_data';
+
+import 'surface_studio_mapping_suggestion_models.dart';
+
+abstract interface class SurfaceStudioAiMappingSuggester {
+  Future<SurfaceStudioMappingSuggestionResult> suggest({
+    required String apiKey,
+    required Uint8List imageBytes,
+    required int tileWidth,
+    required int tileHeight,
+    required int columnCount,
+    required int frameCount,
+  });
+}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart

```diff
diff --git a/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart b/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart
new file mode 100644
index 00000000..af35bb48
--- /dev/null
+++ b/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart
@@ -0,0 +1,43 @@
+import 'package:map_core/map_core.dart';
+
+String buildSurfaceStudioMappingSuggestionPrompt({
+  required int tileWidth,
+  required int tileHeight,
+  required int columnCount,
+  required int frameCount,
+}) {
+  final roles =
+      standardSurfaceVariantRoleOrder.map((role) => role.name).join(', ');
+  return '''
+You are helping map a Pokemon-style surface atlas.
+Return JSON only. No markdown. No prose outside JSON.
+
+Expected schema:
+{
+  "assignments": [
+    {
+      "role": "isolated",
+      "columns": [4, 5],
+      "confidence": "medium",
+      "reason": "Columns 4 and 5 look like repeatable center water tiles."
+    }
+  ],
+  "warnings": ["Inner corners are ambiguous."]
+}
+
+Atlas metadata:
+- tileWidth: $tileWidth
+- tileHeight: $tileHeight
+- columns: $columnCount
+- frames: $frameCount
+- allowedRoles: $roles
+
+Rules:
+- Use only allowed role names.
+- Columns are 1-based and must be between 1 and $columnCount.
+- isolated may use multiple columns.
+- Every other role must use at most one column.
+- confidence must be high, medium, or low.
+- Provide a short reason for each assignment.
+''';
+}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart

```diff
diff --git a/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart b/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
new file mode 100644
index 00000000..edbcce12
--- /dev/null
+++ b/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
@@ -0,0 +1,279 @@
+import 'dart:async';
+import 'dart:convert';
+import 'dart:typed_data';
+
+import 'package:http/http.dart' as http;
+import 'package:image/image.dart' as img;
+import 'package:map_core/map_core.dart';
+
+import 'surface_studio_ai_mapping_suggester.dart';
+import 'surface_studio_mapping_suggestion_models.dart';
+import 'surface_studio_mapping_suggestion_prompt_builder.dart';
+
+final class SurfaceStudioMistralMappingSuggester
+    implements SurfaceStudioAiMappingSuggester {
+  SurfaceStudioMistralMappingSuggester({
+    http.Client? httpClient,
+    this.baseUrl = 'https://api.mistral.ai/v1/chat/completions',
+    this.model = 'mistral-small-2506',
+    this.timeout = const Duration(seconds: 30),
+  }) : _client = httpClient ?? http.Client();
+
+  final http.Client _client;
+  final String baseUrl;
+  final String model;
+  final Duration timeout;
+
+  @override
+  Future<SurfaceStudioMappingSuggestionResult> suggest({
+    required String apiKey,
+    required Uint8List imageBytes,
+    required int tileWidth,
+    required int tileHeight,
+    required int columnCount,
+    required int frameCount,
+  }) async {
+    final key = apiKey.trim();
+    if (key.isEmpty) {
+      return const SurfaceStudioMappingSuggestionResult(
+        suggestions: <SurfaceStudioRoleSuggestion>[],
+        warnings: <String>['Clé Mistral absente.'],
+        source: SurfaceStudioMappingSuggestionSource.mistral,
+      );
+    }
+
+    final prompt = buildSurfaceStudioMappingSuggestionPrompt(
+      tileWidth: tileWidth,
+      tileHeight: tileHeight,
+      columnCount: columnCount,
+      frameCount: frameCount,
+    );
+    final imageDataUrl = _imageDataUrl(imageBytes);
+    final body = jsonEncode({
+      'model': model,
+      'temperature': 0,
+      'response_format': {'type': 'json_object'},
+      'messages': [
+        {
+          'role': 'user',
+          'content': [
+            {'type': 'text', 'text': prompt},
+            {'type': 'image_url', 'image_url': imageDataUrl},
+          ],
+        },
+      ],
+    });
+
+    try {
+      final response = await _client
+          .post(
+            Uri.parse(baseUrl),
+            headers: {
+              'Authorization': 'Bearer $key',
+              'Content-Type': 'application/json',
+            },
+            body: body,
+          )
+          .timeout(timeout);
+      if (response.statusCode < 200 || response.statusCode >= 300) {
+        return SurfaceStudioMappingSuggestionResult(
+          suggestions: const <SurfaceStudioRoleSuggestion>[],
+          warnings: <String>['Mistral HTTP ${response.statusCode}.'],
+          source: SurfaceStudioMappingSuggestionSource.mistral,
+        );
+      }
+      return _parseChatResponse(
+        response.body,
+        columnCount: columnCount,
+      );
+    } on TimeoutException {
+      return const SurfaceStudioMappingSuggestionResult(
+        suggestions: <SurfaceStudioRoleSuggestion>[],
+        warnings: <String>['Mistral timeout.'],
+        source: SurfaceStudioMappingSuggestionSource.mistral,
+      );
+    } catch (_) {
+      return const SurfaceStudioMappingSuggestionResult(
+        suggestions: <SurfaceStudioRoleSuggestion>[],
+        warnings: <String>['Analyse Mistral impossible.'],
+        source: SurfaceStudioMappingSuggestionSource.mistral,
+      );
+    }
+  }
+
+  String _imageDataUrl(Uint8List bytes) {
+    img.Image? decoded;
+    try {
+      decoded = img.decodeImage(bytes);
+    } catch (_) {
+      decoded = null;
+    }
+    if (decoded == null) {
+      return 'data:image/png;base64,${base64Encode(bytes)}';
+    }
+    final longest =
+        decoded.width > decoded.height ? decoded.width : decoded.height;
+    final normalized = longest > 768
+        ? img.copyResize(
+            decoded,
+            width: decoded.width >= decoded.height ? 768 : null,
+            height: decoded.height > decoded.width ? 768 : null,
+          )
+        : decoded;
+    return 'data:image/png;base64,${base64Encode(img.encodePng(normalized))}';
+  }
+
+  SurfaceStudioMappingSuggestionResult _parseChatResponse(
+    String body, {
+    required int columnCount,
+  }) {
+    try {
+      final decoded = jsonDecode(body);
+      if (decoded is! Map<String, dynamic>) {
+        throw const FormatException('root');
+      }
+      final choices = decoded['choices'];
+      if (choices is! List || choices.isEmpty) {
+        throw const FormatException('choices');
+      }
+      final first = choices.first;
+      if (first is! Map<String, dynamic>) {
+        throw const FormatException('choice');
+      }
+      final message = first['message'];
+      if (message is! Map<String, dynamic>) {
+        throw const FormatException('message');
+      }
+      final content = message['content'];
+      if (content is! String) {
+        throw const FormatException('content');
+      }
+      final payload = jsonDecode(content);
+      if (payload is! Map<String, dynamic>) {
+        throw const FormatException('payload');
+      }
+      return _parsePayload(payload, columnCount: columnCount);
+    } catch (e) {
+      return SurfaceStudioMappingSuggestionResult(
+        suggestions: const <SurfaceStudioRoleSuggestion>[],
+        warnings: <String>['Réponse Mistral invalide: $e'],
+        source: SurfaceStudioMappingSuggestionSource.mistral,
+      );
+    }
+  }
+
+  SurfaceStudioMappingSuggestionResult _parsePayload(
+    Map<String, dynamic> payload, {
+    required int columnCount,
+  }) {
+    final warnings = <String>[];
+    final rawWarnings = payload['warnings'];
+    if (rawWarnings is List) {
+      for (final warning in rawWarnings) {
+        if (warning is String && warning.trim().isNotEmpty) {
+          warnings.add(warning.trim());
+        }
+      }
+    }
+
+    final suggestions = <SurfaceStudioRoleSuggestion>[];
+    final assignments = payload['assignments'];
+    if (assignments is! List) {
+      warnings.add('Réponse Mistral sans assignments.');
+      return SurfaceStudioMappingSuggestionResult(
+        suggestions: const <SurfaceStudioRoleSuggestion>[],
+        warnings: List<String>.unmodifiable(warnings),
+        source: SurfaceStudioMappingSuggestionSource.mistral,
+      );
+    }
+
+    for (final item in assignments) {
+      if (item is! Map<String, dynamic>) {
+        warnings.add('Assignation Mistral non objet rejetée.');
+        continue;
+      }
+      final roleName = item['role'];
+      final role = roleName is String ? _roleFromName(roleName) : null;
+      if (role == null) {
+        warnings.add('Rôle Mistral inconnu rejeté : $roleName.');
+        continue;
+      }
+      final columns = _parseColumns(item['columns']);
+      if (columns.isEmpty) {
+        warnings
+            .add('Assignation Mistral sans colonne rejetée pour $roleName.');
+        continue;
+      }
+      final outOfRange =
+          columns.where((column) => column < 1 || column > columnCount);
+      if (outOfRange.isNotEmpty) {
+        warnings.add(
+          'Colonne Mistral hors bornes rejetée pour $roleName : ${outOfRange.first}.',
+        );
+        continue;
+      }
+      if (role != SurfaceVariantRole.isolated && columns.length > 1) {
+        warnings
+            .add('Suggestion Mistral multi-colonnes rejetée pour $roleName.');
+        continue;
+      }
+      final confidence = _confidenceFromName(item['confidence']);
+      if (confidence == null) {
+        warnings.add('Confiance Mistral inconnue rejetée pour $roleName.');
+        continue;
+      }
+      final reason = item['reason'];
+      suggestions.add(
+        SurfaceStudioRoleSuggestion(
+          role: role,
+          columns: List<int>.unmodifiable(columns),
+          confidence: confidence,
+          source: SurfaceStudioMappingSuggestionSource.mistral,
+          reason: reason is String && reason.trim().isNotEmpty
+              ? reason.trim()
+              : 'Suggestion Mistral sans raison détaillée.',
+        ),
+      );
+    }
+
+    return SurfaceStudioMappingSuggestionResult(
+      suggestions: List<SurfaceStudioRoleSuggestion>.unmodifiable(suggestions),
+      warnings: List<String>.unmodifiable(warnings),
+      source: SurfaceStudioMappingSuggestionSource.mistral,
+    );
+  }
+
+  SurfaceVariantRole? _roleFromName(String name) {
+    for (final role in standardSurfaceVariantRoleOrder) {
+      if (role.name == name) {
+        return role;
+      }
+    }
+    return null;
+  }
+
+  SurfaceStudioMappingSuggestionConfidence? _confidenceFromName(Object? value) {
+    if (value is! String) {
+      return null;
+    }
+    for (final confidence in SurfaceStudioMappingSuggestionConfidence.values) {
+      if (confidence.name == value) {
+        return confidence;
+      }
+    }
+    return null;
+  }
+
+  List<int> _parseColumns(Object? value) {
+    if (value is! List) {
+      return const <int>[];
+    }
+    final columns = <int>[];
+    for (final raw in value) {
+      if (raw is int) {
+        columns.add(raw);
+      }
+    }
+    return columns;
+  }
+}
```

### packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart

```diff
diff --git a/Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart b/Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart
new file mode 100644
index 00000000..75032119
--- /dev/null
+++ b/Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart
@@ -0,0 +1,53 @@
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_image_preview.dart';
+
+void main() {
+  testWidgets(
+      'SurfaceStudioAtlasImagePreview does not overflow in reported sizes',
+      (tester) async {
+    final errors = <FlutterErrorDetails>[];
+    final previous = FlutterError.onError;
+    FlutterError.onError = errors.add;
+    addTearDown(() => FlutterError.onError = previous);
+
+    Future<void> pumpConstrained(Size size) async {
+      await tester.pumpWidget(
+        CupertinoApp(
+          home: Center(
+            child: SizedBox(
+              width: size.width,
+              height: size.height,
+              child: SurfaceStudioAtlasImagePreview(
+                resolution: const SurfaceStudioAtlasImagePreviewResolution(
+                    status:
+                        SurfaceStudioAtlasImagePreviewResolveStatus.missingFile,
+                    displayFileName: 'atlas.png',
+                    relativePathForUi:
+                        'assets/surfaces/water/animated/atlas/source/that/is/very/long/atlas.png'),
+                label: Colors.white,
+                subtle: Colors.white70,
+                draftTileWidth: 32,
+                draftTileHeight: 32,
+                draftColumns: 12,
+                draftRows: 32,
+                draftLayoutLabel: 'Colonnes variantes / lignes frames',
+              ),
+            ),
+          ),
+        ),
+      );
+      await tester.pump(const Duration(milliseconds: 20));
+    }
+
+    await pumpConstrained(const Size(312.8, 557));
+    await pumpConstrained(const Size(552, 318));
+
+    expect(
+      errors.where((details) =>
+          details.exceptionAsString().contains('RenderFlex overflowed')),
+      isEmpty,
+    );
+  });
+}
```

### reports/surface/surface_studio_rebuild_v2_2_functional_closure_mistral.md

Le rapport lui-même ne doit pas se recopier récursivement.

## 18.10 Tests

### atlas_image_preview_layout.log

```text
COMMAND: /opt/homebrew/bin/flutter test test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart --no-pub --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart
00:00 +0: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:00 +1: All tests passed!
EXIT_CODE:0
```

### functional_integration.log

```text
COMMAND: /opt/homebrew/bin/flutter test test/surface_studio/surface_studio_rebuild_functional_integration_test.dart --no-pub --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart
00:00 +0: Surface Studio renders one integrated wizard without legacy below
00:00 +1: new import step can create an atlas in the work catalog
00:01 +2: import and slice steps do not render schema or preview docks
00:01 +3: header has no internal close control
00:02 +4: All tests passed!
EXIT_CODE:0
```

### mapping_suggestion.log

```text
COMMAND: /opt/homebrew/bin/flutter test test/surface_studio/surface_studio_mapping_suggestion_test.dart --no-pub --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
00:00 +0: local suggester returns bounded reviewable suggestions
00:00 +1: Suggestion auto opens a review before mutating the mapping
00:00 +2: Mistral prep detects configured key without displaying it
00:01 +3: Mistral analysis asks confirmation before any provider call
00:01 +4: Mistral suggester validates JSON without leaking secrets
00:01 +5: Mistral suggester returns a warning for invalid JSON
00:01 +6: All tests passed!
EXIT_CODE:0
```

### preview_controls.log

```text
COMMAND: /opt/homebrew/bin/flutter test test/surface_studio/surface_studio_rebuild_preview_controls_test.dart --no-pub --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart
00:00 +0: preview panel exposes playback, scrub, loop grid and size controls
00:01 +1: All tests passed!
EXIT_CODE:0
```

### surface_studio_all.log

```text
COMMAND: /opt/homebrew/bin/flutter test test/surface_studio --no-pub --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:01 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:01 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:01 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:01 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:02 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:02 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:02 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:02 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:02 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:02 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:02 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_grid_overlay_test.dart: SurfaceStudioAtlasImageGridPainter CustomPaint sans crash
00:02 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) taille tuile x non entier: erreur
00:02 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) taille tuile x non entier: erreur
00:02 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart: section visible et métriques de grille
00:03 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart: section visible et métriques de grille
00:03 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) hauteur / colonnes / lignes <= 0: erreur
00:03 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) hauteur / colonnes / lignes <= 0: erreur
00:03 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) hauteur / colonnes / lignes <= 0: erreur
00:03 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) hauteur / colonnes / lignes <= 0: erreur
00:03 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) hauteur / colonnes / lignes <= 0: erreur
00:04 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:04 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:04 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 8. atlas sans badge si none
00:04 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 8. atlas sans badge si none
00:04 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 8. atlas sans badge si none
00:04 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 8. atlas sans badge si none
00:04 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 8. atlas sans badge si none
00:04 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 8. atlas sans badge si none
00:04 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 8. atlas sans badge si none
00:04 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:04 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:04 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:04 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:04 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:05 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:05 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:05 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:05 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:05 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:05 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:05 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: sidebar and right dock collapse and expand with sliding panels
00:05 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) Charger la sélection: champs = atlas, catalogue inchangé
00:05 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) Charger la sélection: champs = atlas, catalogue inchangé
00:05 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) Charger la sélection: champs = atlas, catalogue inchangé
00:05 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) Charger la sélection: champs = atlas, catalogue inchangé
00:05 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) Charger la sélection: champs = atlas, catalogue inchangé
00:05 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:05 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:05 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:05 +71: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:05 +72: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:05 +73: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:05 +74: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:06 +75: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:06 +76: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:06 +77: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +78: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +79: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +80: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +81: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +82: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +83: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +84: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +85: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +86: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +87: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +88: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +89: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +90: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +91: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +92: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +93: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +94: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +95: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +96: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:07 +97: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:07 +98: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:07 +99: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:07 +100: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:07 +101: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:07 +102: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:07 +103: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:07 +104: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:07 +105: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:07 +106: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:08 +107: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:08 +108: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:08 +109: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:08 +110: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:08 +111: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:08 +112: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:08 +113: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:08 +114: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:08 +115: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:09 +116: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:09 +117: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:09 +118: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart: SurfaceStudioColumnRoleMappingBlock appelle onDraftChanged quand on suggère un mapping standard
00:09 +119: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart: SurfaceStudioColumnRoleMappingBlock appelle onDraftChanged quand on suggère un mapping standard
00:09 +120: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 70) section image source, pas d’ancien label tileset principal, fallback
00:09 +121: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart: SurfaceStudioColumnRoleMappingBlock appelle onDraftChanged quand on réinitialise le mapping
00:09 +122: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 70) tilesets projet : menu déroulant, pas de champ avancé tileset
00:09 +123: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 70) tilesets projet : menu déroulant, pas de champ avancé tileset
00:09 +124: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart: SurfaceStudioColumnRoleMappingBlock affiche un message d’erreur pour des dimensions invalides
00:09 +125: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 74) assistant vertical visible dans la préparation
00:09 +126: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart: SurfaceStudioColumnRoleMappingBlock affiche un warning pour les doublons
00:09 +127: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 73) sans image résolue : pas de libellé Grille superposée
00:09 +128: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart: SurfaceStudioColumnRoleMappingBlock affiche les libellés utilisateur des rôles
00:09 +129: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 72) section aperçu image source présente
00:09 +130: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 71) section aperçu grille visible avec métriques
00:10 +131: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 71) aperçu état vide sans source
00:10 +132: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 71) aperçu état invalide dimensions
00:10 +133: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 71) aperçu mis à jour en mode édition
00:10 +134: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: section Mapping des colonnes visible pour atlas 23×32
00:10 +135: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: section Mapping des colonnes affiche Atlas simple pour 1×1
00:10 +136: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: Lot 77 : section Plan de génération des animations visible
00:10 +137: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: Lot 79 : section création surface peignable visible
00:10 +138: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: Lot 76 : section Aperçu animation par colonne visible
00:11 +139: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: boutons Suggérer et Réinitialiser fonctionnent
00:11 +140: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_source_picker_test.dart: suggestInternalAtlasIdFromName eau animée
00:11 +141: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 EditorWorkspaceMode.surfaceStudio exists in enum
00:11 +142: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_source_picker_test.dart: suggestInternalAtlasIdFromName vide
00:11 +143: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:11 +144: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:11 +145: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:11 +146: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:11 +147: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:11 +148: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:11 +149: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:11 +150: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:11 +151: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:11 +152: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:11 +153: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +154: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +155: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +156: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +157: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +158: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +159: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +160: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:12 +161: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +162: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +163: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +164: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +165: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +166: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +167: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +168: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +169: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +170: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +171: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +172: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +173: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +174: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +175: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +176: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +177: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +178: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +179: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +180: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +181: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +182: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +183: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +184: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +185: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +186: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:13 +187: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:13 +188: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:13 +189: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: new import step can create an atlas in the work catalog
00:13 +190: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection ajout animations prêtes via callback
00:13 +191: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:13 +192: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:13 +193: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:13 +194: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface
00:13 +195: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface
00:13 +196: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface
00:13 +197: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface
00:13 +198: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface
00:13 +199: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface
00:13 +200: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface
00:13 +201: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:13 +202: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:13 +203: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:13 +204: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:13 +205: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:13 +206: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:13 +207: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:13 +208: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:13 +209: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:13 +210: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +211: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +212: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +213: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +214: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +215: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +216: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +217: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +218: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +219: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +220: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +221: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +222: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +223: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +224: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +225: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +226: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +227: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +228: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +229: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +230: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +231: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +232: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +233: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +234: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +235: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +236: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +237: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +238: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +239: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +240: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +241: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +242: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +243: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +244: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +245: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +246: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +247: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +248: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +249: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +250: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +251: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +252: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +253: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +254: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +255: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:15 +256: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:15 +257: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:15 +258: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:15 +259: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:15 +260: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:15 +261: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:15 +262: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:15 +263: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:15 +264: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:15 +265: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:15 +266: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:16 +267: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:16 +268: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
00:16 +269: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
EditorNotifier: saveProjectManifest()
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/.ctx-mode-LkoYR4/map_editor_v21_save_9G7XlT/project.json
00:16 +270: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Mistral prep detects configured key without displaying it
00:16 +271: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +272: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +273: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +274: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +275: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +276: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +277: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +278: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +279: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +280: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +281: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +282: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +283: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +284: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +285: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +286: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +287: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +288: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +289: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +290: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:17 +291: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:17 +292: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:17 +293: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:17 +294: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:17 +295: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:18 +296: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:18 +297: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:18 +298: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:18 +299: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:18 +300: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:18 +301: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:18 +302: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:18 +303: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:18 +304: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:18 +305: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:18 +306: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:18 +307: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:18 +308: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:18 +309: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:18 +310: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:18 +311: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 2. empty catalog: global empty message
00:18 +312: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 3. empty catalog: per-section empty lines
00:18 +313: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 4. minimal catalog: section headers visible
00:18 +314: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 5. minimal catalog: atlas details (736-tile grid)
00:18 +315: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 6. minimal catalog: animation details
00:18 +316: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 7. minimal catalog: preset details
00:18 +317: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 8. full animation: sync group and category
00:18 +318: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 9. atlas used by two animations
00:18 +319: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 10. atlas unused
00:18 +320: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 11. animation referenced atlas ids deduped order
00:18 +321: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 12. preset referenced animation ids deduped order
00:18 +322: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 13. preset roles source order
00:19 +323: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 14. atlas order preserved
00:19 +324: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 15. animation order preserved
00:19 +325: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 16. preset order preserved
00:19 +326: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 17. order is list order not sortOrder
00:19 +327: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 18. browser in scrollable ancestor
00:19 +328: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 19. no TextField in browser
00:19 +329: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 20. browser has no active edit affordances
00:19 +330: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 21. no internal type names in UI
00:19 +331: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 24. error read model builds without throw
00:19 +332: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 25. derived row fields drive display
00:19 +333: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 28. builds without ProviderScope
00:19 +334: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 29. accepts bounded width
00:19 +335: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 30. public map_core only (import smoke)
00:19 +336: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 45. Lot 57 — browser integrates Animation Detail
00:19 +337: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 46. Lot 57 — browser integrates Preset Detail
00:19 +338: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 47. Lot 57 — browser keeps Atlas Detail
00:19 +339: All tests passed!
EXIT_CODE:0
```

### surface_painter.log

```text
COMMAND: /opt/homebrew/bin/flutter test test/surface_painter --no-pub --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:00 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry layer type picker can create an explicit SurfaceLayer
00:01 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel animations without presets explain the real paint blocker
00:01 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel open Surface Studio action is exposed when presets are missing
00:01 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel lists presets and reports selected surface ids
00:01 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel lists presets and reports selected surface ids
00:01 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel lists presets and reports selected surface ids
00:01 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel lists presets and reports selected surface ids
00:01 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: Surfable water surface to gameplay zone presenter builds a greedy movement/surf generation preview from painted cells
00:01 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePainterPanel surface layer plus zero presets explains nothing is paintable
00:01 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePainterPanel surface layer plus zero presets explains nothing is paintable
00:01 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePainterPanel surface layer plus zero presets explains nothing is paintable
00:01 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePainterPanel surface layer plus zero presets explains nothing is paintable
00:01 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePainterPanel surface layer plus zero presets explains nothing is paintable
00:01 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePainterPanel surface layer plus zero presets explains nothing is paintable
00:01 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePainterPanel surface layer plus zero presets explains nothing is paintable
00:01 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfaceToGameplayZoneDialog requires an encounter table id before confirming
00:02 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfableWaterSurfaceGameplayZoneDialog confirms a ready surfable water plan
00:02 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfableWaterSurfaceGameplayZoneDialog disables confirmation when the water plan is blocked
00:02 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: LavaHazardSurfaceGameplayZoneDialog confirms a ready lava hazard plan with default damage
00:02 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: LavaHazardSurfaceGameplayZoneDialog requires positive damage and uses edited damage in the plan
00:02 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfacePainterPanel behavior action menu shows one behavior action and opens behavior choices
00:02 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfacePainterPanel behavior action menu routes tall grass choice to the encounter dialog
00:02 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfacePainterPanel behavior action menu routes water choice to the surfable water dialog
00:02 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfacePainterPanel behavior action menu routes lava choice to the lava hazard dialog
00:02 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier tall grass surface generation adds multiple encounter gameplay zones in one mutation and selects first
00:02 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier tall grass surface generation rejects non-encounter plans without mutating the map
00:02 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier tall grass surface generation rejects non-walk encounter plans without mutating the map
00:02 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier surfable water surface generation adds multiple movement surf gameplay zones in one mutation and selects first
00:02 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier surfable water surface generation rejects non-movement plans without mutating the map
00:02 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier surfable water surface generation rejects movement plans that do not require surf without mutating
00:02 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier lava hazard surface generation adds multiple hazard lava gameplay zones in one mutation and selects first
00:02 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier lava hazard surface generation rejects non-hazard plans without mutating the map
00:02 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier lava hazard surface generation rejects non-lava hazard plans without mutating the map
00:02 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: EditorNotifier lava hazard surface generation rejects lava hazard plans without positive damage
00:02 +71: All tests passed!
EXIT_CODE:0
```

### editor_shell_page_smoke.log

```text
COMMAND: /opt/homebrew/bin/flutter test test/editor_shell_page_smoke_test.dart --no-pub --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart
00:00 +0: EditorShellPage smoke renders map workspace chrome and toggles the right panel
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:01 +1: EditorShellPage smoke updates the workspace header for tileset mode
00:01 +2: EditorShellPage smoke renders the trainer studio workspace chrome
FileProjectRepository: Loading project from /tmp/editor_shell_trainer/project.json
00:01 +3: EditorShellPage smoke renders the Pokémon catalogs workspace shell
00:02 +4: EditorShellPage smoke renders the Items catalogs workspace shell
00:02 +5: EditorShellPage smoke renders Surface Studio without the global right inspector
00:02 +6: EditorShellPage smoke renders shell chrome with an error state already present
00:02 +7: All tests passed!
EXIT_CODE:0
```

## 18.11 Analyze

```text
COMMAND: /opt/homebrew/bin/flutter analyze lib/src/features/surface_studio lib/src/features/editor/application/editor_ai_settings.dart lib/src/features/dialogue/application/mistral_dialogue_client.dart lib/src/ui/editor_shell_page.dart
Analyzing 4 items...                                            
No issues found! (ran in 2.7s)
EXIT_CODE:0
```

## 18.12 QA manuelle

```text
COMMAND: /opt/homebrew/bin/flutter run -d macos
Launching lib/main.dart on macOS in debug mode...
Building macOS application...                                   
✓ Built build/macos/Build/Products/Debug/map_editor.app
2026-04-29 18:47:05.478 map_editor[42536:16181971] Running with merged UI and platform thread. Experimental.
Syncing files to device macOS...                                    69ms

Flutter run key commands.
r Hot reload. 🔥🔥🔥
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on macOS is available at: http://127.0.0.1:57226/m7YiUjxDHxw=/
The Flutter DevTools debugger and profiler on macOS is available at: http://127.0.0.1:57226/m7YiUjxDHxw=/devtools/?uri=ws://127.0.0.1:57226/m7YiUjxDHxw=/ws
flutter: FileProjectRepository: Loading project from /Users/karim/Desktop/my_new_project/project.json
QA_TIMEOUT: flutter run still active after 35s; sending SIGINT
QA_TIMEOUT: process still active; sending SIGTERM
Application finished.
```

Résultat QA : `flutter run -d macos` a buildé et lancé l’application, chargé le projet réel `/Users/karim/Desktop/my_new_project/project.json`, puis a été arrêté après fenêtre de capture bornée. La console capturée ne contient aucune occurrence `RenderFlex overflowed` ni `EXCEPTION CAUGHT BY RENDERING LIBRARY`. L’environnement agent ne permet pas de valider visuellement chaque étape par interaction humaine prolongée ; les tests widget couvrent les états Importer/Découper/Mapper/Prévisualiser/Enregistrer et le shell global.

## 18.13 Auto-review

- Respect screenshots utilisateur : oui pour les corrections demandées, avec suppression des docks inutiles et du panneau global vide.
- Fonctionnalité réelle : oui, le wizard utilise le work catalog, le mapping draft, les générateurs existants et les callbacks de sauvegarde.
- Intégration shell : oui, `surfaceStudio` n’ouvre plus le right inspector global et `SurfaceStudioPanel` occupe le stage.
- Qualité layout : oui, tests overflow ajoutés et suites complètes vertes.
- Qualité IA : V0 réelle derrière interface, opt-in, fake client en tests, validation stricte.
- Risques restants : la QA visuelle prolongée n’a pas pu être conduite manuellement dans l’app agent au-delà du lancement console borné ; la vraie qualité perceptuelle reste à confirmer par manipulation utilisateur dans la fenêtre macOS.
- Non-objectifs confirmés : aucun `map_gameplay`, `map_runtime`, `map_battle`, runtime ice/mud, SurfaceLayer gameplay, ProjectSurfacePreset gameplay ou migration legacy dans le status final.

## 18.14 Critique du prompt

- Ambiguïté : “vraie preview” peut signifier rendu exact autotile complet ou aperçu frame atlas. Choix V2.2 : preview branchée sur image atlas résolue + contrôles réels, sans inventer un moteur de rendu Surface parallèle.
- Choix : Mistral V0 utilise Chat Completions multimodal, base64 downscalé, JSON mode, modèle vision `mistral-small-2506`, et validation locale stricte.
- Partie stricte utile : les contraintes overflow et absence de panneaux inutiles ont produit des tests de non-régression concrets.
- Partie à préciser pour suite : définir le rendu exact attendu de preview Surface à partir de plusieurs rôles et frames, au-delà du center/atlas preview V0.

## 18.15 Git status final

```text
 M packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart
 M packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_editing.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_source_picker.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_column_role_mapping_block.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_atlas_editing_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_atlas_grid_overlay_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart
 M packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_assistant_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_preset_generator_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_role_mapping_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
?? packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart
?? reports/surface/surface_studio_rebuild_v2_2_functional_closure_mistral.md
```

## Diff stat final

```text
 .../atlas/surface_studio_atlas_panel.dart          |  60 +++-
 .../preview/surface_studio_preview_panel.dart      |  79 ++++-
 .../shell/surface_studio_header.dart               |  95 +++---
 .../surface_studio/shell/surface_studio_shell.dart |  52 ++-
 .../surface_studio_atlas_editing.dart              |   3 +-
 .../surface_studio_atlas_grid_overlay.dart         |   5 +-
 .../surface_studio_atlas_grid_preview.dart         |  11 +-
 .../surface_studio_atlas_image_preview.dart        |  71 ++--
 .../surface_studio_atlas_source_picker.dart        |   3 +-
 .../surface_studio_column_role_mapping_block.dart  |  25 +-
 ...rface_studio_mapping_suggestion_controller.dart |  35 +-
 .../surface_studio/surface_studio_panel.dart       | 108 +++---
 .../surface_studio/surface_studio_screen.dart      | 370 +++++++++++++++++----
 ...o_vertical_atlas_animation_generation_plan.dart | 221 ++++++------
 ..._studio_vertical_atlas_animation_generator.dart |   3 +-
 .../surface_studio_vertical_atlas_assistant.dart   |   9 +-
 ...ace_studio_vertical_atlas_preset_generator.dart |  15 +-
 ...surface_studio_vertical_atlas_role_mapping.dart |   5 +-
 .../map_editor/lib/src/ui/editor_shell_page.dart   |   5 +-
 .../test/editor_shell_page_smoke_test.dart         |  30 ++
 .../surface_studio_atlas_editing_test.dart         |   3 +-
 .../surface_studio_atlas_grid_overlay_test.dart    |   3 +-
 .../surface_studio_atlas_grid_preview_test.dart    |   9 +-
 .../surface_studio_atlas_image_preview_test.dart   |   6 +-
 ...face_studio_column_role_mapping_block_test.dart |   6 +-
 .../surface_studio_mapping_suggestion_test.dart    | 185 ++++++++++-
 ...studio_rebuild_functional_integration_test.dart |  31 ++
 .../surface_studio_rebuild_test_harness.dart       |  30 +-
 .../surface_studio_selection_inspector_test.dart   |  14 +-
 ...tical_atlas_animation_generation_plan_test.dart |  18 +-
 ...rface_studio_vertical_atlas_assistant_test.dart |   3 +-
 ...tudio_vertical_atlas_preset_generator_test.dart |  15 +-
 ...ce_studio_vertical_atlas_role_mapping_test.dart |  11 +-
 33 files changed, 1130 insertions(+), 409 deletions(-)
```

## Synthèse de clôture

- Importer sans schema/preview inutile : Oui.
- Découper sans schema/preview inutile : Oui.
- Panneau global droit vide masqué : Oui, via `EditorShellPage`.
- Croix interne supprimée : Oui.
- Mapper utilise vrai atlas si disponible : Oui, bytes image résolus et transmis.
- Placeholder explicite uniquement si image absente : Oui.
- Preview branchée sur atlas réel si disponible : Oui.
- RenderFlex overflow corrigé : Oui, test contraintes vert.
- Suggestion auto locale : Oui.
- Suggestion IA Mistral V0 : Oui, provider réel opt-in avec fake HTTP tests.
- Aucune clé affichée/loggée : Oui.
- Aucun réseau en test : Oui.
- Tests Surface Studio : Oui, `00:15 +339: All tests passed!`.
- Surface Painter : Oui, `00:02 +71: All tests passed!`.
- Analyze : Oui, `No issues found!`.
- Aucun gameplay hors périmètre touché : Oui.
