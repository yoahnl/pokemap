# Surface Studio V2.4 — Coordinate System Closure, Mapper Preview Fix & Mistral Calibration

## 20.1 Verdict

V2.4 accepté côté implémentation automatisée.

Limite QA : QA interactive complète impossible dans cet environnement. L’application macOS a été lancée, buildée, puis arrêtée; aucune manipulation visuelle interactive de l’écran réel n’a été effectuée par l’agent.

## 20.2 Audit initial

### git status initial

```text
 M packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart
 M packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
 M packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
 M packages/map_gameplay/test/placed_elements_collision_test.dart
?? packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart
?? packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_mistral_prompt_test.dart
?? reports/surface/surface_studio_rebuild_v2_3_real_preview_mistral.md
```

### diff stat initial

```text
 .../atlas/surface_studio_atlas_grid_painter.dart   |  81 ++++++-----
 .../atlas/surface_studio_atlas_panel.dart          |  99 ++++++++++++--
 .../preview/surface_studio_preview_panel.dart      | 152 +++++++++------------
 ...e_studio_mapping_suggestion_prompt_builder.dart | 132 ++++++++++++++----
 .../surface_studio_mistral_mapping_suggester.dart  | 117 +++++++++++++++-
 .../surface_studio/surface_studio_screen.dart      |  61 ++++++++-
 .../surface_studio_mapping_suggestion_test.dart    | 112 +++++++++++++++
 .../test/placed_elements_collision_test.dart       |   1 +
 8 files changed, 591 insertions(+), 164 deletions(-)
```

### Commande audit obligatoire

```text
pwd
/Users/karim/Project/pokemonProject

ctx stats
zsh:1: command not found: ctx
```

### Context Mode MCP

```text
448.4K tokens saved  ·  82.5% reduction  ·  2h 35m
Without context-mode: 2.1 MB
With context-mode: 371.8 KB
1.7 MB kept out of your conversation. Never entered context.
79 calls
ctx_batch_execute: 19 calls, 927.6 KB saved
ctx_search: 15 calls, 435.3 KB saved
ctx_execute: 23 calls, 168.7 KB saved
ctx_execute_file: 15 calls, 161.6 KB saved
ctx_fetch_and_index: 3 calls, 46.2 KB saved
ctx_stats: 4 calls, 12.7 KB saved
v1.0.103
```

### Cause racine alignement atlas

Avant V2.4, le mapper utilisait une `Image.memory(... BoxFit.contain ...)` et un `CustomPaint` indépendant qui dessinait la grille sur toute la surface disponible. Les labels/taps de colonnes venaient d’une rangée de widgets `Expanded` séparée. Dès que l’image était letterboxée par `contain`, l’image, la grille, le hit-test et la sélection ne partageaient plus le même rectangle de destination.

### Cause racine preview recentrée

La preview V2.3 croppait déjà une tile, mais le système de coordonnées source n’était pas partagé avec le viewport atlas. L’utilisateur pouvait voir des colonnes sélectionnées dans un repère visuel et la preview pouvait croper depuis un autre repère logique. V2.4 extrait `surfaceStudioTileSourceRect` dans une primitive partagée et ajoute un debug source rect visible.

### Cause racine erreurs Mistral

V2.3 envoyait principalement l’image complète et une image annotée simple. Cette entrée était trop difficile à interpréter pour un atlas vertical long : colonnes compressées, numéros peu exploitables, absence de planche contact par colonne, absence de descripteurs locaux et pas de blocage local des colonnes `likelyEmpty`.

### État QA V2.3

Le rapport V2.3 reconnaissait une QA runtime non interactive. V2.4 ne prétend pas avoir corrigé cette limite par observation manuelle complète; elle compense par des tests de géométrie, de source rect, de widgets, de provider Mistral fake et de lancement runtime macOS.

## 20.3 Coordinate System

### fittedImageRect

`SurfaceStudioAtlasViewGeometry.fromContain` calcule un rectangle unique de type `BoxFit.contain` pour l’image atlas dans le viewport. Ce rectangle est conservé dans `fittedImageRect` et devient la seule source pour l’image, la grille, les labels, les overlays de tap et la sélection.

### image pixel size

Le viewport décode les bytes atlas une seule fois avec `ui.decodeImageFromList`. Si l’image est absente, il utilise la taille logique `columnCount * tileWidth` par `frameCount * tileHeight` pour garder une géométrie fallback cohérente.

### viewport size

Le `LayoutBuilder` du canvas fournit la taille réelle du viewport. Le hit-test ne calcule jamais `viewport.width / columnCount` directement; il utilise toujours `fittedImageRect.width / columnCount`.

### column hit test

`surfaceStudioColumnAtViewportOffset` retourne `null` hors `fittedImageRect`. Un tap dans le letterbox ne sélectionne aucune colonne.

### frame hit test

`surfaceStudioFrameAtViewportOffset` applique la même règle verticale pour les frames.

### source rect

`surfaceStudioTileSourceRect` documente et teste la conversion : colonnes UI 1-based, pixels source 0-based.

Exemple protégé par test : `uiColumn: 4`, `frameIndex: 1`, `tileWidth: 32`, `tileHeight: 32` donne `x = 96`, `y = 32`.

## 20.4 Preview Mapper

### Avant

La preview pouvait rester confuse : sélection visible ne voulait pas dire assignation, et il n’existait pas de preuve UI directe que le crop venait de la colonne réellement assignée.

### Après

La sélection reste distincte de l’assignation. Le bouton `Utiliser comme Plein(center)` assigne les colonnes sélectionnées à `SurfaceVariantRole.isolated`. La preview devient active seulement après assignation réelle. Le message “Assignez au moins le rôle Plein” disparaît seulement après cette assignation.

### sourceRect

Le panneau preview affiche maintenant :

```text
Colonnes assignées au Plein : 4–5
Source rect actuelle : x=24 y=0 w=8 h=8
Frame : 1 / 2
```

puis après frame suivante :

```text
Source rect actuelle : x=32 y=8 w=8 h=8
```

### crop réel

`SurfaceStudioSurfacePreviewPainter` dessine chaque cellule avec `canvas.drawImageRect` depuis le vrai `sourceRect` atlas. Il n’affiche pas l’image complète recentrée.

### frame

`frameIndex` change la ligne source `sourceY = frameIndex * tileHeight`.

### multi-colonnes center

Quand `isolated` contient plusieurs colonnes, la preview dessine un motif alterné sur la grille. Le frame index décale aussi le choix de variante, ce qui rend les colonnes multiples visibles au lieu de cacher la seconde colonne.

### fallbacks

Si l’image est absente, la preview affiche un message explicite. Si `isolated` n’est pas assigné, elle affiche l’état vide attendu.

## 20.5 Mistral Calibration

### vision pack

Nouveau service `SurfaceStudioMistralVisionPack` :

```text
- originalAtlasDataUrl
- annotatedAtlasDataUrl
- columnContactSheetDataUrl
- columnDescriptors
```

### images envoyées

Le provider Mistral envoie trois images en data URL : image originale, image annotée grille+colonnes, et planche contact colonnes. Il n’envoie pas de chemin local et n’ajoute jamais la clé API dans le body JSON.

### contact sheet

La planche contact extrait chaque colonne sous forme de cellule séparée avec numéro lisible et frames échantillonnées. C’est l’image prioritaire dans le prompt V4.

### descriptors

Les descripteurs locaux incluent : colonne, couleur moyenne, occupation des bords, transparence, `likelyEmpty`, candidats locaux.

### prompt V4 complet

```text
You are analyzing a Pokémon-like animated surface atlas for a no-code map editor.
Take your time internally.
Use high-effort visual reasoning.
Inspect the column contact sheet first.
Do not rush.
Do not guess.
Do not guess when uncertain.
Prefer abstaining over wrong mappings.
Only assign roles when visual evidence is strong.
Return JSON only.
Return valid JSON only. No markdown. No prose outside JSON. Do not expose chain-of-thought.

You receive three images:
1. Original atlas image.
2. Annotated atlas image with grid and readable 1-based column numbers.
3. Column contact sheet. The column contact sheet is the priority image for identification.

Inspect the atlas as a grid:
- columns are visual variants
- rows are animation frames
- Columns are 1-based in this UI
- tileWidth: <tileWidth>
- tileHeight: <tileHeight>
- columns: <columnCount>
- frames: <frameCount>
- every role must map to existing columns only

Your task:
Assign atlas columns to surface autotile roles.

Allowed technical roles, in canonical order:
isolated, endNorth, endEast, endSouth, endWest, horizontal, vertical, cornerNW, cornerNE, cornerSW, cornerSE, innerCornerNW, innerCornerNE, innerCornerSW, innerCornerSE, teeNorth, teeEast, teeSouth, teeWest, cross

French UI label to technical role mapping:
- Plein(center) = isolated
- Bord haut = endNorth
- Bord droit = endEast
- Bord bas = endSouth
- Bord gauche = endWest
- Horizontal = horizontal
- Vertical = vertical
- Coin haut gauche = cornerNW
- Coin haut droit = cornerNE
- Coin bas gauche = cornerSW
- Coin bas droit = cornerSE
- Coin int. haut gauche = innerCornerNW
- Coin int. haut droit = innerCornerNE
- Coin int. bas gauche = innerCornerSW
- Coin int. bas droit = innerCornerSE
- Té haut = teeNorth
- Té droit = teeEast
- Té bas = teeSouth
- Té gauche = teeWest
- Croix = cross

Visual guidance:
- A bright or pink guide column may be a border, not necessarily center.
- Repeated water-only columns are likely center/isolated.
- Shoreline strips indicate borders.
- L-shaped shorelines indicate external corners.
- Inner L-shaped cutouts indicate inner corners.
- T shapes indicate junctions.
- Cross shapes indicate cross junction.
- If uncertain, leave the role empty and add a warning.
- Prefer fewer high-confidence mappings over many guesses.
- If the atlas only contains center/water fill columns without clear borders, leave border/corner roles empty.
- Never map likelyEmpty columns.

Local column descriptors from deterministic analysis:
<JSON descriptors>

Validation rules:
- All column numbers must be between 1 and <columnCount>.
- isolated may contain multiple columns.
- All other roles must contain at most one column.
- Do not invent roles.
- Never map columns marked likelyEmpty by the local descriptors.
- confidence must be exactly high, medium, or low.
- reason must be a short string for each assignment.
- evidenceColumns must be inside the atlas bounds.
- rejectedColumns must be inside the atlas bounds.
- warnings must be strings and should explain ambiguity.

Before producing JSON, internally verify:
1. All column numbers are within range.
2. isolated/center may contain multiple columns.
3. All other roles contain at most one column.
4. No role is invented.
5. likelyEmpty columns are not mapped.
6. Warnings explain ambiguity.
7. Output is valid JSON only.

Expected JSON schema:
{
  "assignments": [
    {
      "role": "isolated",
      "columns": [4, 5],
      "confidence": "high",
      "evidenceColumns": [4, 5],
      "reason": "Columns 4 and 5 are full water tiles without shoreline and can repeat as center variants."
    }
  ],
  "rejectedColumns": [
    {
      "column": 3,
      "reason": "Likely empty or insufficient visual evidence."
    }
  ],
  "warnings": [
    "Inner corners are not confidently visible."
  ]
}
```

### schema V4

Le schema JSON demandé au provider exige `assignments`, `rejectedColumns`, `warnings`; chaque assignment exige `role`, `columns`, `confidence`, `evidenceColumns`, `reason`.

### reasoning_effort

Le body HTTP garde `reasoning_effort: high`.

### response_format

Le body HTTP garde `response_format: { type: json_schema, ... }`.

### temperature

Le body HTTP garde `temperature: 0.1`.

### validation JSON

Le parser local rejette : JSON invalide, rôle inconnu, colonne hors plage, multi-colonnes hors `isolated`, confiance inconnue, `evidenceColumns` absentes/hors plage, suggestion sur colonne `likelyEmpty`.

### progress UI

Pendant l’analyse IA : spinner visible, boutons IA désactivés, message `Mistral analyse l’atlas avec un niveau de réflexion élevé. Cela peut prendre quelques secondes.`, étape `Analyse visuelle approfondie…`.

### gestion erreurs

Timeout et exceptions provider deviennent warnings UI; aucune mutation de mapping n’est appliquée.

## 20.6 UI integration

### effet canvas greffé avant

L’effet venait principalement d’un viewport atlas traité comme une superposition de widgets désynchronisés et d’une preview sans explication de source rect. Visuellement, l’utilisateur voyait une image centrée avec des overlays qui ne prouvaient pas leur alignement.

### changements exacts

```text
- Image widget supprimée du mapper au profit d’un painter unique.
- Grille, labels, sélection, hit-test et image partagent fittedImageRect.
- Source rect preview exposé dans le panneau preview.
- Fallback image gardé explicite, mais non silencieux.
- Mistral affiche une vraie phase de travail avec spinner.
```

### limites restantes

QA interactive complète non effectuée dans cet environnement. Le ressenti “natif” doit encore être confirmé sur l’écran réel par manipulation humaine.

## 20.7 Fichiers créés/modifiés/supprimés

### Créés V2.4

```text
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_view_geometry.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_vision_pack.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_view_geometry_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_viewport_coordinate_test.dart
packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart
packages/map_editor/test/surface_studio/surface_studio_mistral_vision_pack_test.dart
```

### Modifiés V2.4

```text
packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart
packages/map_editor/test/surface_studio/surface_studio_mistral_prompt_test.dart
packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
```

### Supprimés V2.4

```text
Aucun fichier source supprimé.
```

### Changements préexistants non imputés au lot V2.4

```text
packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart
packages/map_gameplay/test/placed_elements_collision_test.dart
reports/surface/surface_studio_rebuild_v2_3_real_preview_mistral.md
```

Le fichier runtime DevTools généré par `flutter run -d macos` a été nettoyé sans commande git.

## 20.8 Contenu complet

Le rapport lui-même n’est pas inclus dans sa propre section contenu afin d’éviter une auto-inclusion infinie.


### packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_view_geometry.dart

```dart
import 'dart:ui';

final class SurfaceStudioAtlasViewGeometry {
  const SurfaceStudioAtlasViewGeometry({
    required this.viewportSize,
    required this.imagePixelSize,
    required this.fittedImageRect,
    required this.tileWidth,
    required this.tileHeight,
    required this.columnCount,
    required this.frameCount,
  });

  factory SurfaceStudioAtlasViewGeometry.fromContain({
    required Size viewportSize,
    required Size imagePixelSize,
    required int tileWidth,
    required int tileHeight,
    required int columnCount,
    required int frameCount,
  }) {
    return SurfaceStudioAtlasViewGeometry(
      viewportSize: viewportSize,
      imagePixelSize: imagePixelSize,
      fittedImageRect: computeSurfaceStudioContainedImageRect(
        viewportSize: viewportSize,
        imagePixelSize: imagePixelSize,
      ),
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      frameCount: frameCount,
    );
  }

  final Size viewportSize;
  final Size imagePixelSize;
  final Rect fittedImageRect;
  final int tileWidth;
  final int tileHeight;
  final int columnCount;
  final int frameCount;
}

Rect computeSurfaceStudioContainedImageRect({
  required Size viewportSize,
  required Size imagePixelSize,
}) {
  if (viewportSize.width <= 0 ||
      viewportSize.height <= 0 ||
      imagePixelSize.width <= 0 ||
      imagePixelSize.height <= 0) {
    return Offset.zero & Size.zero;
  }
  final scale = (viewportSize.width / imagePixelSize.width) <
          (viewportSize.height / imagePixelSize.height)
      ? viewportSize.width / imagePixelSize.width
      : viewportSize.height / imagePixelSize.height;
  final fittedSize = Size(
    imagePixelSize.width * scale,
    imagePixelSize.height * scale,
  );
  return Rect.fromLTWH(
    (viewportSize.width - fittedSize.width) / 2,
    (viewportSize.height - fittedSize.height) / 2,
    fittedSize.width,
    fittedSize.height,
  );
}

int? surfaceStudioColumnAtViewportOffset({
  required Offset localPosition,
  required SurfaceStudioAtlasViewGeometry geometry,
}) {
  final rect = geometry.fittedImageRect;
  if (!rect.contains(localPosition) || geometry.columnCount <= 0) {
    return null;
  }
  final localX = localPosition.dx - rect.left;
  final normalized = (localX / rect.width).clamp(0, 0.999999);
  return (normalized * geometry.columnCount).floor() + 1;
}

int? surfaceStudioFrameAtViewportOffset({
  required Offset localPosition,
  required SurfaceStudioAtlasViewGeometry geometry,
}) {
  final rect = geometry.fittedImageRect;
  if (!rect.contains(localPosition) || geometry.frameCount <= 0) {
    return null;
  }
  final localY = localPosition.dy - rect.top;
  final normalized = (localY / rect.height).clamp(0, 0.999999);
  return (normalized * geometry.frameCount).floor() + 1;
}

Rect surfaceStudioColumnViewportRect({
  required int uiColumn,
  required SurfaceStudioAtlasViewGeometry geometry,
}) {
  final safeColumnCount = geometry.columnCount < 1 ? 1 : geometry.columnCount;
  final column = uiColumn.clamp(1, safeColumnCount).toInt();
  final width = geometry.fittedImageRect.width / safeColumnCount;
  return Rect.fromLTWH(
    geometry.fittedImageRect.left + (column - 1) * width,
    geometry.fittedImageRect.top,
    width,
    geometry.fittedImageRect.height,
  );
}

Rect surfaceStudioTileSourceRect({
  required int uiColumn,
  required int frameIndex,
  required int tileWidth,
  required int tileHeight,
  required int columnCount,
  required int frameCount,
}) {
  final safeColumnCount = columnCount < 1 ? 1 : columnCount;
  final safeFrameCount = frameCount < 1 ? 1 : frameCount;
  final column = uiColumn.clamp(1, safeColumnCount).toInt();
  final frame = frameIndex.clamp(0, safeFrameCount - 1).toInt();
  return Rect.fromLTWH(
    (column - 1) * tileWidth.toDouble(),
    frame * tileHeight.toDouble(),
    tileWidth.toDouble(),
    tileHeight.toDouble(),
  );
}
```

### packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart

```dart
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType, Slider;
import 'package:flutter/services.dart';

import '../surface_studio_atlas_view_geometry.dart';
import '../surface_studio_column_selection.dart';
import '../surface_studio_design_tokens.dart';
import '../surface_studio_drag_payload.dart';

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
    required this.centerAssigned,
    required this.centerColumns,
    required this.onUseSelectionAsCenter,
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
  final bool centerAssigned;
  final List<int> centerColumns;
  final double zoomPercent;
  final ValueChanged<SurfaceStudioColumnSelection> onColumnSelectionChanged;
  final VoidCallback onUseSelectionAsCenter;
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
              centerAssigned: centerAssigned,
              centerColumns: centerColumns,
              zoomPercent: zoomPercent,
              onColumnSelectionChanged: onColumnSelectionChanged,
              onUseSelectionAsCenter: onUseSelectionAsCenter,
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
    required this.centerAssigned,
    required this.centerColumns,
    required this.zoomPercent,
    required this.onColumnSelectionChanged,
    required this.onUseSelectionAsCenter,
  });

  final int columnCount;
  final int frameCount;
  final int tileWidth;
  final int tileHeight;
  final Uint8List? atlasImageBytes;
  final String? atlasImageFallbackLabel;
  final SurfaceStudioColumnSelection selection;
  final bool centerAssigned;
  final List<int> centerColumns;
  final double zoomPercent;
  final ValueChanged<SurfaceStudioColumnSelection> onColumnSelectionChanged;
  final VoidCallback onUseSelectionAsCenter;

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
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: SurfaceStudioAtlasCanvas(
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
            constraints: const BoxConstraints(minHeight: 35),
            decoration: BoxDecoration(
              color: SurfaceStudioDesignTokens.backgroundPanel
                  .withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text(
                    selection.microcopy,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: SurfaceStudioDesignTokens.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    selection.isEmpty
                        ? 'Colonnes sélectionnées : aucune'
                        : 'Colonnes sélectionnées : ${_formatColumns(selection.columns)}',
                    style: const TextStyle(
                      color: SurfaceStudioDesignTokens.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    centerAssigned
                        ? 'Plein(center) : colonnes ${_formatColumns(centerColumns)}'
                        : 'Plein(center) : non assigné',
                    style: TextStyle(
                      color: centerAssigned
                          ? SurfaceStudioDesignTokens.accentTeal
                          : SurfaceStudioDesignTokens.accentGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (selection.isNotEmpty)
                    CupertinoButton(
                      key: const ValueKey(
                        'surfaceStudio.atlas.useSelectionAsCenter',
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      minimumSize: const Size(0, 0),
                      color: SurfaceStudioDesignTokens.accentGoldSoft,
                      onPressed: onUseSelectionAsCenter,
                      child: const Text(
                        'Utiliser comme Plein(center)',
                        style: TextStyle(
                          color: SurfaceStudioDesignTokens.accentGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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

class SurfaceStudioAtlasCanvas extends StatefulWidget {
  const SurfaceStudioAtlasCanvas({
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
  State<SurfaceStudioAtlasCanvas> createState() =>
      _SurfaceStudioAtlasCanvasState();
}

class _SurfaceStudioAtlasCanvasState extends State<SurfaceStudioAtlasCanvas> {
  ui.Image? _image;
  Object? _decodeToken;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(covariant SurfaceStudioAtlasCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.atlasImageBytes != widget.atlasImageBytes) {
      _image?.dispose();
      _image = null;
      _decodeImage();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  void _decodeImage() {
    final bytes = widget.atlasImageBytes;
    if (bytes == null || bytes.isEmpty) {
      _decodeToken = null;
      return;
    }
    final token = Object();
    _decodeToken = token;
    ui.decodeImageFromList(bytes, (image) {
      if (!mounted || _decodeToken != token) {
        image.dispose();
        return;
      }
      setState(() => _image = image);
    });
  }

  void _selectColumn(int column) {
    final shift = HardwareKeyboard.instance.logicalKeysPressed.any(
      (key) =>
          key == LogicalKeyboardKey.shiftLeft ||
          key == LogicalKeyboardKey.shiftRight,
    );
    final next = shift && widget.selection.isNotEmpty
        ? widget.selection.selectContiguousTo(column)
        : widget.selection.selectSingle(column);
    widget.onColumnSelectionChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 1,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 1,
        );
        final image = _image;
        final imagePixelSize = image == null
            ? Size(
                (widget.columnCount * widget.tileWidth).toDouble(),
                (widget.frameCount * widget.tileHeight).toDouble(),
              )
            : Size(image.width.toDouble(), image.height.toDouble());
        final geometry = SurfaceStudioAtlasViewGeometry.fromContain(
          viewportSize: viewportSize,
          imagePixelSize: imagePixelSize,
          tileWidth: widget.tileWidth,
          tileHeight: widget.tileHeight,
          columnCount: widget.columnCount,
          frameCount: widget.frameCount,
        );
        return GestureDetector(
          key: const ValueKey('surfaceStudio.atlas.canvas'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final column = surfaceStudioColumnAtViewportOffset(
              localPosition: details.localPosition,
              geometry: geometry,
            );
            if (column != null) {
              _selectColumn(column);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _SurfaceStudioAtlasCanvasPainter(
                  atlasImage: image,
                  geometry: geometry,
                  selectedColumns: widget.selection.columns,
                  zoomPercent: widget.zoomPercent,
                  fallbackLabel: widget.atlasImageFallbackLabel ??
                      'Image source indisponible — aperçu illustratif.',
                ),
                child: const SizedBox.expand(),
              ),
              if (image == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      widget.atlasImageFallbackLabel ??
                          'Image source indisponible — aperçu illustratif.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: SurfaceStudioDesignTokens.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              for (var column = 1; column <= widget.columnCount; column++)
                Positioned.fromRect(
                  rect: surfaceStudioColumnViewportRect(
                    uiColumn: column,
                    geometry: geometry,
                  ),
                  child: GestureDetector(
                    key: ValueKey('surfaceStudio.atlas.column.$column'),
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _selectColumn(column),
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SurfaceStudioAtlasCanvasPainter extends CustomPainter {
  const _SurfaceStudioAtlasCanvasPainter({
    required this.atlasImage,
    required this.geometry,
    required this.selectedColumns,
    required this.zoomPercent,
    required this.fallbackLabel,
  });

  final ui.Image? atlasImage;
  final SurfaceStudioAtlasViewGeometry geometry;
  final List<int> selectedColumns;
  final double zoomPercent;
  final String fallbackLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final viewportPaint = Paint()
      ..color = SurfaceStudioDesignTokens.backgroundDeep;
    canvas.drawRect(Offset.zero & size, viewportPaint);

    final imageRect = geometry.fittedImageRect;
    final image = atlasImage;
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        imageRect,
        Paint()..filterQuality = FilterQuality.none,
      );
    } else {
      _drawFallbackSurface(canvas, imageRect);
    }

    _drawGrid(canvas, imageRect);
    _drawColumnLabels(canvas);
    _drawSelection(canvas);
  }

  void _drawFallbackSurface(Canvas canvas, Rect imageRect) {
    final background = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF174A8B), Color(0xFF1A74D6), Color(0xFF123D3A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(imageRect);
    canvas.drawRect(imageRect, background);

    final safeColumnCount = geometry.columnCount.clamp(1, 9999).toInt();
    final safeFrameCount = geometry.frameCount.clamp(1, 9999).toInt();
    final tileW = imageRect.width / safeColumnCount;
    final tileH = imageRect.height / safeFrameCount;
    final wavePaint = Paint()
      ..color = SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var y = 0; y < geometry.frameCount; y += 2) {
      final centerY = imageRect.top + y * tileH + tileH / 2;
      for (var x = 0; x < geometry.columnCount; x += 2) {
        final left = imageRect.left + x * tileW + tileW * 0.18;
        final rect = Rect.fromLTWH(
            left, centerY - tileH * 0.22, tileW * 0.64, tileH * 0.44);
        canvas.drawArc(rect, 0, 3.14159, false, wavePaint);
      }
    }
  }

  void _drawGrid(Canvas canvas, Rect imageRect) {
    final columnCount = geometry.columnCount.clamp(1, 9999).toInt();
    final frameCount = geometry.frameCount.clamp(1, 9999).toInt();
    final columnWidth = imageRect.width / columnCount;
    final rowHeight = imageRect.height / frameCount;
    final linePaint = Paint()
      ..color = SurfaceStudioDesignTokens.textPrimary.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    final strongPaint = Paint()
      ..color = SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.24)
      ..strokeWidth = 1.1;

    canvas.save();
    canvas.clipRect(imageRect);
    for (var column = 0; column <= columnCount; column++) {
      final x = imageRect.left + column * columnWidth;
      canvas.drawLine(
        Offset(x, imageRect.top),
        Offset(x, imageRect.bottom),
        column.isEven ? strongPaint : linePaint,
      );
    }
    for (var row = 0; row <= frameCount; row++) {
      final y = imageRect.top + row * rowHeight;
      canvas.drawLine(
        Offset(imageRect.left, y),
        Offset(imageRect.right, y),
        row % 4 == 0 ? strongPaint : linePaint,
      );
    }
    canvas.restore();
  }

  void _drawColumnLabels(Canvas canvas) {
    for (var column = 1; column <= geometry.columnCount; column++) {
      final columnRect = surfaceStudioColumnViewportRect(
        uiColumn: column,
        geometry: geometry,
      );
      final isSelected = selectedColumns.contains(column);
      final labelText = TextPainter(
        text: TextSpan(
          text: '$column',
          style: TextStyle(
            color: isSelected
                ? SurfaceStudioDesignTokens.backgroundDeep
                : SurfaceStudioDesignTokens.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: columnRect.width);
      final desiredLabelWidth = labelText.width + 9;
      final labelWidth = columnRect.width < 18
          ? columnRect.width
          : desiredLabelWidth.clamp(18.0, columnRect.width).toDouble();
      final labelRect = Rect.fromLTWH(
        columnRect.center.dx - labelWidth / 2,
        geometry.fittedImageRect.top + 6,
        labelWidth,
        18,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(7)),
        Paint()
          ..color = isSelected
              ? SurfaceStudioDesignTokens.accentGold
              : SurfaceStudioDesignTokens.backgroundDeep.withValues(alpha: 0.7),
      );
      labelText.paint(
        canvas,
        Offset(
          labelRect.center.dx - labelText.width / 2,
          labelRect.center.dy - labelText.height / 2,
        ),
      );
    }
  }

  void _drawSelection(Canvas canvas) {
    if (selectedColumns.isEmpty) {
      return;
    }
    final fillPaint = Paint()
      ..color = SurfaceStudioDesignTokens.accentGold.withValues(alpha: 0.18);
    final strokePaint = Paint()
      ..color = SurfaceStudioDesignTokens.accentGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final column in selectedColumns) {
      final rect = surfaceStudioColumnViewportRect(
        uiColumn: column,
        geometry: geometry,
      ).deflate(1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        fillPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SurfaceStudioAtlasCanvasPainter oldDelegate) =>
      oldDelegate.atlasImage != atlasImage ||
      oldDelegate.geometry != geometry ||
      oldDelegate.selectedColumns != selectedColumns ||
      oldDelegate.zoomPercent != zoomPercent ||
      oldDelegate.fallbackLabel != fallbackLabel;
}

String _formatColumns(List<int> columns) {
  if (columns.isEmpty) {
    return 'aucune';
  }
  if (columns.length == 1) {
    return '${columns.first}';
  }
  return '${columns.first}–${columns.last}';
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
import 'surface_studio_surface_preview_renderer.dart';

class SurfaceStudioPreviewPanel extends StatelessWidget {
  const SurfaceStudioPreviewPanel({
    super.key,
    required this.frameCount,
    required this.frameIndex,
    required this.playing,
    required this.loop,
    required this.gridVisible,
    required this.previewSize,
    required this.tileWidth,
    required this.tileHeight,
    required this.columnCount,
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
  final int tileWidth;
  final int tileHeight;
  final int columnCount;
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
                      tileWidth: tileWidth,
                      tileHeight: tileHeight,
                      columnCount: columnCount,
                      atlasImageBytes: atlasImageBytes,
                      atlasFallbackMessage: atlasFallbackMessage,
                      assignmentDraft: assignmentDraft,
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
    required this.tileWidth,
    required this.tileHeight,
    required this.columnCount,
    this.atlasImageBytes,
    this.atlasFallbackMessage,
    required this.assignmentDraft,
  });

  final int previewSize;
  final bool gridVisible;
  final int frameIndex;
  final int frameCount;
  final int tileWidth;
  final int tileHeight;
  final int columnCount;
  final Uint8List? atlasImageBytes;
  final String? atlasFallbackMessage;
  final SurfaceStudioRoleAssignmentDraft assignmentDraft;

  @override
  Widget build(BuildContext context) {
    final hasCenter = assignmentDraft.isAssigned(SurfaceVariantRole.isolated);
    final centerColumns =
        assignmentDraft.columnsForRole(SurfaceVariantRole.isolated);
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
                  SurfaceStudioSurfacePreviewRenderer(
                    key: const ValueKey('surfaceStudio.preview.tileRenderer'),
                    atlasImageBytes: atlasImageBytes!,
                    assignmentDraft: assignmentDraft,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                    columnCount: columnCount,
                    frameCount: frameCount,
                    frameIndex: frameIndex,
                    previewSize: previewSize,
                    gridVisible: gridVisible,
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
                if (atlasImageBytes != null)
                  const Positioned(
                    left: 10,
                    top: 10,
                    child: _PartialPreviewBadge(),
                  ),
                if (atlasImageBytes != null && centerColumns.isNotEmpty)
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: _SourceRectDebug(
                      centerColumns: centerColumns,
                      frameIndex: frameIndex,
                      frameCount: frameCount,
                      tileWidth: tileWidth,
                      tileHeight: tileHeight,
                      columnCount: columnCount,
                    ),
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

class _SourceRectDebug extends StatelessWidget {
  const _SourceRectDebug({
    required this.centerColumns,
    required this.frameIndex,
    required this.frameCount,
    required this.tileWidth,
    required this.tileHeight,
    required this.columnCount,
  });

  final List<int> centerColumns;
  final int frameIndex;
  final int frameCount;
  final int tileWidth;
  final int tileHeight;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    final safeFrameCount = frameCount < 1 ? 1 : frameCount;
    final safeFrameIndex = frameIndex % safeFrameCount;
    final column = centerColumns[safeFrameIndex % centerColumns.length];
    final source = surfaceStudioTileSourceRect(
      uiColumn: column,
      frameIndex: safeFrameIndex,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      frameCount: safeFrameCount,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundDeep.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SurfaceStudioDesignTokens.borderStrong.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          'Colonnes assignées au Plein : ${_formatColumns(centerColumns)}  •  '
          'Source rect actuelle : x=${source.left.round()} y=${source.top.round()} '
          'w=${source.width.round()} h=${source.height.round()}  •  '
          'Frame : ${safeFrameIndex + 1} / $safeFrameCount',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: SurfaceStudioDesignTokens.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

String _formatColumns(List<int> columns) {
  if (columns.isEmpty) {
    return 'aucune';
  }
  if (columns.length == 1) {
    return '${columns.first}';
  }
  return '${columns.first}–${columns.last}';
}

class _PartialPreviewBadge extends StatelessWidget {
  const _PartialPreviewBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundDeep.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SurfaceStudioDesignTokens.accentTeal),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          'Preview partielle : Plein(center)',
          style: TextStyle(
            color: SurfaceStudioDesignTokens.accentTeal,
            fontSize: 11,
            fontWeight: FontWeight.w800,
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
```

### packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart

```dart
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

import '../surface_studio_design_tokens.dart';
import '../surface_studio_atlas_view_geometry.dart';
import '../surface_studio_role_assignment_draft.dart';

export '../surface_studio_atlas_view_geometry.dart'
    show surfaceStudioTileSourceRect;

class SurfaceStudioSurfacePreviewRenderer extends StatefulWidget {
  const SurfaceStudioSurfacePreviewRenderer({
    super.key,
    required this.atlasImageBytes,
    required this.assignmentDraft,
    required this.tileWidth,
    required this.tileHeight,
    required this.columnCount,
    required this.frameCount,
    required this.frameIndex,
    required this.previewSize,
    required this.gridVisible,
  });

  final Uint8List atlasImageBytes;
  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
  final int tileWidth;
  final int tileHeight;
  final int columnCount;
  final int frameCount;
  final int frameIndex;
  final int previewSize;
  final bool gridVisible;

  @override
  State<SurfaceStudioSurfacePreviewRenderer> createState() =>
      _SurfaceStudioSurfacePreviewRendererState();
}

class _SurfaceStudioSurfacePreviewRendererState
    extends State<SurfaceStudioSurfacePreviewRenderer> {
  ui.Image? _image;
  Object? _decodeToken;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(
      covariant SurfaceStudioSurfacePreviewRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.atlasImageBytes != widget.atlasImageBytes) {
      _image?.dispose();
      _image = null;
      _decode();
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  void _decode() {
    final token = Object();
    _decodeToken = token;
    ui.decodeImageFromList(widget.atlasImageBytes, (image) {
      if (!mounted || _decodeToken != token) {
        image.dispose();
        return;
      }
      setState(() => _image = image);
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return const Center(
        child: Text(
          'Préparation de la preview atlas...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SurfaceStudioDesignTokens.textMuted,
            fontSize: 12,
            height: 1.3,
          ),
        ),
      );
    }
    return CustomPaint(
      key: const ValueKey('surfaceStudio.preview.tileCanvas'),
      painter: SurfaceStudioSurfacePreviewPainter(
        atlasImage: image,
        assignmentDraft: widget.assignmentDraft,
        tileWidth: widget.tileWidth,
        tileHeight: widget.tileHeight,
        columnCount: widget.columnCount,
        frameCount: widget.frameCount,
        frameIndex: widget.frameIndex,
        previewSize: widget.previewSize,
        gridVisible: widget.gridVisible,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class SurfaceStudioSurfacePreviewPainter extends CustomPainter {
  const SurfaceStudioSurfacePreviewPainter({
    required this.atlasImage,
    required this.assignmentDraft,
    required this.tileWidth,
    required this.tileHeight,
    required this.columnCount,
    required this.frameCount,
    required this.frameIndex,
    required this.previewSize,
    required this.gridVisible,
  });

  final ui.Image atlasImage;
  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
  final int tileWidth;
  final int tileHeight;
  final int columnCount;
  final int frameCount;
  final int frameIndex;
  final int previewSize;
  final bool gridVisible;

  @override
  void paint(Canvas canvas, Size size) {
    final centerColumns =
        assignmentDraft.columnsForRole(SurfaceVariantRole.isolated);
    if (centerColumns.isEmpty) {
      return;
    }
    final safeFrameCount = frameCount < 1 ? 1 : frameCount;
    final safeFrameIndex = frameIndex % safeFrameCount;
    final cellWidth = size.width / previewSize;
    final cellHeight = size.height / previewSize;
    final paint = Paint()..filterQuality = FilterQuality.none;
    for (var y = 0; y < previewSize; y++) {
      for (var x = 0; x < previewSize; x++) {
        final tileColumn =
            centerColumns[(x + y + safeFrameIndex) % centerColumns.length];
        final source = surfaceStudioTileSourceRect(
          uiColumn: tileColumn,
          frameIndex: safeFrameIndex,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          columnCount: columnCount,
          frameCount: safeFrameCount,
        );
        canvas.drawImageRect(
          atlasImage,
          source,
          Rect.fromLTWH(x * cellWidth, y * cellHeight, cellWidth, cellHeight),
          paint,
        );
      }
    }
    if (!gridVisible) {
      return;
    }
    final gridPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (var i = 0; i <= previewSize; i++) {
      final x = i * cellWidth;
      final y = i * cellHeight;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(
          covariant SurfaceStudioSurfacePreviewPainter oldDelegate) =>
      oldDelegate.atlasImage != atlasImage ||
      oldDelegate.assignmentDraft != assignmentDraft ||
      oldDelegate.tileWidth != tileWidth ||
      oldDelegate.tileHeight != tileHeight ||
      oldDelegate.columnCount != columnCount ||
      oldDelegate.frameCount != frameCount ||
      oldDelegate.frameIndex != frameIndex ||
      oldDelegate.previewSize != previewSize ||
      oldDelegate.gridVisible != gridVisible;
}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart

```dart
import 'surface_studio_mistral_vision_pack.dart';

const surfaceStudioMistralAllowedRoleNames = <String>[
  'isolated',
  'endNorth',
  'endEast',
  'endSouth',
  'endWest',
  'horizontal',
  'vertical',
  'cornerNW',
  'cornerNE',
  'cornerSW',
  'cornerSE',
  'innerCornerNW',
  'innerCornerNE',
  'innerCornerSW',
  'innerCornerSE',
  'teeNorth',
  'teeEast',
  'teeSouth',
  'teeWest',
  'cross',
];

const surfaceStudioMistralRoleLabelMap = <String, String>{
  'Plein(center)': 'isolated',
  'Bord haut': 'endNorth',
  'Bord droit': 'endEast',
  'Bord bas': 'endSouth',
  'Bord gauche': 'endWest',
  'Horizontal': 'horizontal',
  'Vertical': 'vertical',
  'Coin haut gauche': 'cornerNW',
  'Coin haut droit': 'cornerNE',
  'Coin bas gauche': 'cornerSW',
  'Coin bas droit': 'cornerSE',
  'Coin int. haut gauche': 'innerCornerNW',
  'Coin int. haut droit': 'innerCornerNE',
  'Coin int. bas gauche': 'innerCornerSW',
  'Coin int. bas droit': 'innerCornerSE',
  'Té haut': 'teeNorth',
  'Té droit': 'teeEast',
  'Té bas': 'teeSouth',
  'Té gauche': 'teeWest',
  'Croix': 'cross',
};

String buildSurfaceStudioMappingSuggestionPrompt({
  required int tileWidth,
  required int tileHeight,
  required int columnCount,
  required int frameCount,
  List<SurfaceStudioColumnVisualDescriptor> columnDescriptors =
      const <SurfaceStudioColumnVisualDescriptor>[],
}) {
  final roles = surfaceStudioMistralAllowedRoleNames.join(', ');
  final roleLabels = surfaceStudioMistralRoleLabelMap.entries
      .map((entry) => '- ${entry.key} = ${entry.value}')
      .join('\n');
  final descriptors = columnDescriptors.isEmpty
      ? '[]'
      : surfaceStudioColumnDescriptorsJson(columnDescriptors);
  return '''
You are analyzing a Pokémon-like animated surface atlas for a no-code map editor.
Take your time internally.
Use high-effort visual reasoning.
Inspect the column contact sheet first.
Do not rush.
Do not guess.
Do not guess when uncertain.
Prefer abstaining over wrong mappings.
Only assign roles when visual evidence is strong.
Return JSON only.
Return valid JSON only. No markdown. No prose outside JSON. Do not expose chain-of-thought.

You receive three images:
1. Original atlas image.
2. Annotated atlas image with grid and readable 1-based column numbers.
3. Column contact sheet. The column contact sheet is the priority image for identification.

Inspect the atlas as a grid:
- columns are visual variants
- rows are animation frames
- Columns are 1-based in this UI
- tileWidth: $tileWidth
- tileHeight: $tileHeight
- columns: $columnCount
- frames: $frameCount
- every role must map to existing columns only

Your task:
Assign atlas columns to surface autotile roles.

Allowed technical roles, in canonical order:
$roles

French UI label to technical role mapping:
$roleLabels

Visual guidance:
- A bright or pink guide column may be a border, not necessarily center.
- Repeated water-only columns are likely center/isolated.
- Shoreline strips indicate borders.
- L-shaped shorelines indicate external corners.
- Inner L-shaped cutouts indicate inner corners.
- T shapes indicate junctions.
- Cross shapes indicate cross junction.
- If uncertain, leave the role empty and add a warning.
- Prefer fewer high-confidence mappings over many guesses.
- If the atlas only contains center/water fill columns without clear borders, leave border/corner roles empty.
- Never map likelyEmpty columns.

Local column descriptors from deterministic analysis:
$descriptors

Validation rules:
- All column numbers must be between 1 and $columnCount.
- isolated may contain multiple columns.
- All other roles must contain at most one column.
- Do not invent roles.
- Never map columns marked likelyEmpty by the local descriptors.
- confidence must be exactly high, medium, or low.
- reason must be a short string for each assignment.
- evidenceColumns must be inside the atlas bounds.
- rejectedColumns must be inside the atlas bounds.
- warnings must be strings and should explain ambiguity.

Before producing JSON, internally verify:
1. All column numbers are within range.
2. isolated/center may contain multiple columns.
3. All other roles contain at most one column.
4. No role is invented.
5. likelyEmpty columns are not mapped.
6. Warnings explain ambiguity.
7. Output is valid JSON only.

Expected JSON schema:
{
  "assignments": [
    {
      "role": "isolated",
      "columns": [4, 5],
      "confidence": "high",
      "evidenceColumns": [4, 5],
      "reason": "Columns 4 and 5 are full water tiles without shoreline and can repeat as center variants."
    }
  ],
  "rejectedColumns": [
    {
      "column": 3,
      "reason": "Likely empty or insufficient visual evidence."
    }
  ],
  "warnings": [
    "Inner corners are not confidently visible."
  ]
}
''';
}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:map_core/map_core.dart';

import 'surface_studio_ai_mapping_suggester.dart';
import 'surface_studio_mapping_suggestion_models.dart';
import 'surface_studio_mapping_suggestion_prompt_builder.dart';
import 'surface_studio_mistral_vision_pack.dart';

final class SurfaceStudioMistralMappingSuggester
    implements SurfaceStudioAiMappingSuggester {
  SurfaceStudioMistralMappingSuggester({
    http.Client? httpClient,
    this.baseUrl = 'https://api.mistral.ai/v1/chat/completions',
    this.model = 'mistral-small-latest',
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

    final visionPack = buildSurfaceStudioMistralVisionPack(
      imageBytes: imageBytes,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      frameCount: frameCount,
    );
    final prompt = buildSurfaceStudioMappingSuggestionPrompt(
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      frameCount: frameCount,
      columnDescriptors: visionPack.columnDescriptors,
    );
    final body = jsonEncode({
      'model': model,
      'temperature': 0.1,
      'reasoning_effort': 'high',
      'response_format': _jsonSchemaResponseFormat(),
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': visionPack.originalAtlasDataUrl,
            },
            {
              'type': 'image_url',
              'image_url': visionPack.annotatedAtlasDataUrl,
            },
            {
              'type': 'image_url',
              'image_url': visionPack.columnContactSheetDataUrl,
            },
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
        columnDescriptors: visionPack.columnDescriptors,
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

  Map<String, Object?> _jsonSchemaResponseFormat() {
    return {
      'type': 'json_schema',
      'json_schema': {
        'name': 'surface_studio_mapping_suggestion',
        'strict': true,
        'schema': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['assignments', 'rejectedColumns', 'warnings'],
          'properties': {
            'assignments': {
              'type': 'array',
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': [
                  'role',
                  'columns',
                  'confidence',
                  'evidenceColumns',
                  'reason',
                ],
                'properties': {
                  'role': {
                    'type': 'string',
                    'enum': surfaceStudioMistralAllowedRoleNames,
                  },
                  'columns': {
                    'type': 'array',
                    'items': {'type': 'integer'},
                  },
                  'confidence': {
                    'type': 'string',
                    'enum': ['high', 'medium', 'low'],
                  },
                  'evidenceColumns': {
                    'type': 'array',
                    'items': {'type': 'integer'},
                  },
                  'reason': {'type': 'string'},
                },
              },
            },
            'rejectedColumns': {
              'type': 'array',
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': ['column', 'reason'],
                'properties': {
                  'column': {'type': 'integer'},
                  'reason': {'type': 'string'},
                },
              },
            },
            'warnings': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
        },
      },
    };
  }

  SurfaceStudioMappingSuggestionResult _parseChatResponse(
    String body, {
    required int columnCount,
    required List<SurfaceStudioColumnVisualDescriptor> columnDescriptors,
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
      return _parsePayload(
        payload,
        columnCount: columnCount,
        columnDescriptors: columnDescriptors,
      );
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
    required List<SurfaceStudioColumnVisualDescriptor> columnDescriptors,
  }) {
    final warnings = <String>[];
    final descriptorsByColumn = <int, SurfaceStudioColumnVisualDescriptor>{
      for (final descriptor in columnDescriptors) descriptor.column: descriptor,
    };
    final likelyEmptyColumns = descriptorsByColumn.values
        .where((descriptor) => descriptor.likelyEmpty)
        .map((descriptor) => descriptor.column)
        .toSet();
    final rawWarnings = payload['warnings'];
    if (rawWarnings is List) {
      for (final warning in rawWarnings) {
        if (warning is String && warning.trim().isNotEmpty) {
          warnings.add(warning.trim());
        }
      }
    }
    final rejectedColumns = payload['rejectedColumns'];
    if (rejectedColumns is List) {
      for (final rejected in rejectedColumns) {
        if (rejected is! Map<String, dynamic>) {
          warnings.add('Colonne rejetée Mistral non objet ignorée.');
          continue;
        }
        final column = rejected['column'];
        final reason = rejected['reason'];
        if (column is! int || column < 1 || column > columnCount) {
          warnings.add('Colonne rejetée Mistral hors bornes ignorée.');
          continue;
        }
        if (reason is String && reason.trim().isNotEmpty) {
          warnings
              .add('Mistral a rejeté la colonne $column : ${reason.trim()}');
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
      int? emptyColumn;
      for (final column in columns) {
        if (likelyEmptyColumns.contains(column)) {
          emptyColumn = column;
          break;
        }
      }
      if (emptyColumn != null) {
        warnings.add(
          'Suggestion Mistral sur colonne likelyEmpty rejetée pour $roleName : $emptyColumn.',
        );
        continue;
      }
      if (role != SurfaceVariantRole.isolated && columns.length > 1) {
        warnings
            .add('Suggestion Mistral multi-colonnes rejetée pour $roleName.');
        continue;
      }
      final evidenceColumns = _parseColumns(item['evidenceColumns']);
      if (evidenceColumns.isEmpty) {
        warnings.add(
            'Suggestion Mistral sans evidenceColumns rejetée pour $roleName.');
        continue;
      }
      final evidenceOutOfRange = evidenceColumns.where(
        (column) => column < 1 || column > columnCount,
      );
      if (evidenceOutOfRange.isNotEmpty) {
        warnings.add(
          'Evidence Mistral hors bornes rejetée pour $roleName : ${evidenceOutOfRange.first}.',
        );
        continue;
      }
      final confidence = _confidenceFromName(item['confidence']);
      if (confidence == null) {
        warnings.add('Confiance Mistral inconnue rejetée pour $roleName.');
        continue;
      }
      final reason = item['reason'];
      for (final column in columns) {
        final descriptor = descriptorsByColumn[column];
        if (descriptor == null) {
          continue;
        }
        if (!descriptor.localCandidateRoles.contains(role.name)) {
          warnings.add(
            'Mistral contredit l’analyse locale pour ${role.name} colonne $column.',
          );
        }
      }
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

### packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_vision_pack.dart

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

final class SurfaceStudioMistralVisionPack {
  const SurfaceStudioMistralVisionPack({
    required this.originalAtlasDataUrl,
    required this.annotatedAtlasDataUrl,
    required this.columnContactSheetDataUrl,
    required this.columnDescriptors,
  });

  final String originalAtlasDataUrl;
  final String annotatedAtlasDataUrl;
  final String columnContactSheetDataUrl;
  final List<SurfaceStudioColumnVisualDescriptor> columnDescriptors;
}

final class SurfaceStudioColumnVisualDescriptor {
  const SurfaceStudioColumnVisualDescriptor({
    required this.column,
    required this.averageColorHex,
    required this.edgeOccupancy,
    required this.hasTransparentPixels,
    required this.likelyEmpty,
    required this.localCandidateRoles,
  });

  final int column;
  final String averageColorHex;
  final SurfaceStudioColumnEdgeOccupancy edgeOccupancy;
  final bool hasTransparentPixels;
  final bool likelyEmpty;
  final List<String> localCandidateRoles;

  Map<String, Object?> toJson() => {
        'column': column,
        'averageColorHex': averageColorHex,
        'edgeOccupancy': edgeOccupancy.toJson(),
        'hasTransparentPixels': hasTransparentPixels,
        'likelyEmpty': likelyEmpty,
        'localCandidateRoles': localCandidateRoles,
      };
}

final class SurfaceStudioColumnEdgeOccupancy {
  const SurfaceStudioColumnEdgeOccupancy({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  final double top;
  final double right;
  final double bottom;
  final double left;

  Map<String, Object?> toJson() => {
        'top': _round(top),
        'right': _round(right),
        'bottom': _round(bottom),
        'left': _round(left),
      };
}

SurfaceStudioMistralVisionPack buildSurfaceStudioMistralVisionPack({
  required Uint8List imageBytes,
  required int tileWidth,
  required int tileHeight,
  required int columnCount,
  required int frameCount,
  int originalMaxLongSide = 1400,
  int annotatedMaxLongSide = 1600,
}) {
  final decoded = _tryDecodeImage(imageBytes);
  if (decoded == null) {
    final fallback = _dataUrl(imageBytes);
    return SurfaceStudioMistralVisionPack(
      originalAtlasDataUrl: fallback,
      annotatedAtlasDataUrl: fallback,
      columnContactSheetDataUrl: fallback,
      columnDescriptors: const <SurfaceStudioColumnVisualDescriptor>[],
    );
  }

  final original = _resizeForAnalysis(decoded, originalMaxLongSide);
  final annotated = _buildAnnotatedAtlas(
    decoded,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    columnCount: columnCount,
    frameCount: frameCount,
    maxLongSide: annotatedMaxLongSide,
  );
  final contactSheet = _buildColumnContactSheet(
    decoded,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    columnCount: columnCount,
    frameCount: frameCount,
  );
  final descriptors = <SurfaceStudioColumnVisualDescriptor>[
    for (var column = 1; column <= columnCount; column++)
      _describeColumn(
        decoded,
        uiColumn: column,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        frameCount: frameCount,
      ),
  ];

  return SurfaceStudioMistralVisionPack(
    originalAtlasDataUrl: _pngDataUrl(original),
    annotatedAtlasDataUrl: _pngDataUrl(annotated),
    columnContactSheetDataUrl: _pngDataUrl(contactSheet),
    columnDescriptors: List<SurfaceStudioColumnVisualDescriptor>.unmodifiable(
      descriptors,
    ),
  );
}

String surfaceStudioColumnDescriptorsJson(
  List<SurfaceStudioColumnVisualDescriptor> descriptors,
) =>
    const JsonEncoder.withIndent('  ').convert(
      descriptors.map((descriptor) => descriptor.toJson()).toList(),
    );

img.Image _resizeForAnalysis(img.Image source, int maxLongSide) {
  final longest = source.width > source.height ? source.width : source.height;
  if (longest <= maxLongSide) {
    return img.Image.from(source);
  }
  return img.copyResize(
    source,
    width: source.width >= source.height ? maxLongSide : null,
    height: source.height > source.width ? maxLongSide : null,
    interpolation: img.Interpolation.average,
  );
}

img.Image _buildAnnotatedAtlas(
  img.Image source, {
  required int tileWidth,
  required int tileHeight,
  required int columnCount,
  required int frameCount,
  required int maxLongSide,
}) {
  final annotated = _resizeForAnalysis(source, maxLongSide);
  final safeColumns = columnCount < 1 ? 1 : columnCount;
  final safeFrames = frameCount < 1 ? 1 : frameCount;
  final columnWidth = annotated.width / safeColumns;
  final rowHeight = annotated.height / safeFrames;
  final gridColor = img.ColorRgba8(242, 200, 75, 220);
  final labelFill = img.ColorRgba8(11, 16, 32, 230);
  final labelText = img.ColorRgb8(242, 200, 75);

  for (var column = 0; column <= safeColumns; column++) {
    final x = (column * columnWidth).round().clamp(0, annotated.width - 1);
    img.drawLine(
      annotated,
      x1: x,
      y1: 0,
      x2: x,
      y2: annotated.height - 1,
      color: gridColor,
    );
  }
  for (var frame = 0; frame <= safeFrames; frame++) {
    final y = (frame * rowHeight).round().clamp(0, annotated.height - 1);
    img.drawLine(
      annotated,
      x1: 0,
      y1: y,
      x2: annotated.width - 1,
      y2: y,
      color: frame % 4 == 0 ? gridColor : img.ColorRgba8(255, 255, 255, 120),
    );
  }

  for (var column = 1; column <= safeColumns; column++) {
    final label = '$column';
    final left = ((column - 1) * columnWidth).round();
    final centerX = (left + columnWidth / 2).round();
    final desiredLabelWidth = label.length * 10 + 12;
    final maxLabelWidth = columnWidth.round();
    final labelWidth = maxLabelWidth < 24
        ? maxLabelWidth
        : desiredLabelWidth.clamp(24, maxLabelWidth).toInt();
    final labelLeft = (centerX - labelWidth ~/ 2).clamp(0, annotated.width - 1);
    img.fillRect(
      annotated,
      x1: labelLeft,
      y1: 4,
      x2: (labelLeft + labelWidth).clamp(0, annotated.width - 1),
      y2: 24,
      color: labelFill,
    );
    img.drawString(
      annotated,
      label,
      font: img.arial14,
      x: labelLeft + 5,
      y: 7,
      color: labelText,
    );
  }
  return annotated;
}

img.Image _buildColumnContactSheet(
  img.Image source, {
  required int tileWidth,
  required int tileHeight,
  required int columnCount,
  required int frameCount,
}) {
  final safeColumns = columnCount < 1 ? 1 : columnCount;
  final safeFrames = frameCount < 1 ? 1 : frameCount;
  final thumbWidth = tileWidth.clamp(32, 80).toInt();
  final thumbHeight = tileHeight.clamp(32, 80).toInt();
  const labelHeight = 24;
  const gap = 8;
  final samples = <int>{0, safeFrames ~/ 2, safeFrames - 1}.toList()..sort();
  final cellWidth = thumbWidth + 12;
  final cellHeight = labelHeight + samples.length * thumbHeight + 12;
  final sheet = img.Image(
    width: gap + safeColumns * (cellWidth + gap),
    height: cellHeight + gap * 2,
  );
  img.fill(sheet, color: img.ColorRgb8(11, 16, 32));

  for (var column = 1; column <= safeColumns; column++) {
    final cellLeft = gap + (column - 1) * (cellWidth + gap);
    img.fillRect(
      sheet,
      x1: cellLeft,
      y1: gap,
      x2: cellLeft + cellWidth,
      y2: gap + cellHeight,
      color: img.ColorRgb8(28, 36, 51),
    );
    img.drawString(
      sheet,
      '$column',
      font: img.arial14,
      x: cellLeft + 6,
      y: gap + 5,
      color: img.ColorRgb8(242, 200, 75),
    );
    for (var sampleIndex = 0; sampleIndex < samples.length; sampleIndex++) {
      final frame = samples[sampleIndex].clamp(0, safeFrames - 1);
      final tile = img.copyCrop(
        source,
        x: (column - 1) * tileWidth,
        y: frame * tileHeight,
        width: tileWidth,
        height: tileHeight,
      );
      final thumb = img.copyResize(
        tile,
        width: thumbWidth,
        height: thumbHeight,
        interpolation: img.Interpolation.nearest,
      );
      img.compositeImage(
        sheet,
        thumb,
        dstX: cellLeft + 6,
        dstY: gap + labelHeight + sampleIndex * thumbHeight,
      );
    }
  }
  return sheet;
}

SurfaceStudioColumnVisualDescriptor _describeColumn(
  img.Image source, {
  required int uiColumn,
  required int tileWidth,
  required int tileHeight,
  required int frameCount,
}) {
  final safeFrameCount = frameCount < 1 ? 1 : frameCount;
  var totalR = 0;
  var totalG = 0;
  var totalB = 0;
  var visibleCount = 0;
  var transparentCount = 0;
  var darkVisibleCount = 0;

  final xStart = (uiColumn - 1) * tileWidth;
  final frameSamples = <int>{0, safeFrameCount ~/ 2, safeFrameCount - 1};
  for (final frame in frameSamples) {
    final yStart = frame * tileHeight;
    for (var y = yStart; y < yStart + tileHeight; y++) {
      if (y < 0 || y >= source.height) {
        continue;
      }
      for (var x = xStart; x < xStart + tileWidth; x++) {
        if (x < 0 || x >= source.width) {
          continue;
        }
        final pixel = source.getPixel(x, y);
        final alpha = pixel.a.toInt();
        if (alpha < 20) {
          transparentCount++;
          continue;
        }
        final red = pixel.r.toInt();
        final green = pixel.g.toInt();
        final blue = pixel.b.toInt();
        totalR += red;
        totalG += green;
        totalB += blue;
        visibleCount++;
        if ((red + green + blue) / 3 < 10) {
          darkVisibleCount++;
        }
      }
    }
  }

  final averageColorHex = visibleCount == 0
      ? '#000000'
      : _hexColor(
          totalR ~/ visibleCount,
          totalG ~/ visibleCount,
          totalB ~/ visibleCount,
        );
  final sampledPixels = visibleCount + transparentCount;
  final transparentRatio =
      sampledPixels == 0 ? 1.0 : transparentCount / sampledPixels;
  final darkRatio = visibleCount == 0 ? 1.0 : darkVisibleCount / visibleCount;
  final likelyEmpty = transparentRatio > 0.9 || darkRatio > 0.95;
  final edgeOccupancy = _edgeOccupancy(
    source,
    xStart: xStart,
    yStart: 0,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
  );

  return SurfaceStudioColumnVisualDescriptor(
    column: uiColumn,
    averageColorHex: averageColorHex,
    edgeOccupancy: edgeOccupancy,
    hasTransparentPixels: transparentCount > 0,
    likelyEmpty: likelyEmpty,
    localCandidateRoles: likelyEmpty
        ? const <String>[]
        : _candidateRolesFromEdges(edgeOccupancy),
  );
}

SurfaceStudioColumnEdgeOccupancy _edgeOccupancy(
  img.Image source, {
  required int xStart,
  required int yStart,
  required int tileWidth,
  required int tileHeight,
}) {
  double occupied(int x, int y) {
    if (x < 0 || x >= source.width || y < 0 || y >= source.height) {
      return 0;
    }
    final pixel = source.getPixel(x, y);
    final alpha = pixel.a.toInt();
    final brightness = (pixel.r + pixel.g + pixel.b) / 3;
    return alpha > 20 && brightness > 10 ? 1 : 0;
  }

  var top = 0.0;
  var bottom = 0.0;
  for (var x = xStart; x < xStart + tileWidth; x++) {
    top += occupied(x, yStart);
    bottom += occupied(x, yStart + tileHeight - 1);
  }
  var left = 0.0;
  var right = 0.0;
  for (var y = yStart; y < yStart + tileHeight; y++) {
    left += occupied(xStart, y);
    right += occupied(xStart + tileWidth - 1, y);
  }
  return SurfaceStudioColumnEdgeOccupancy(
    top: top / tileWidth,
    right: right / tileHeight,
    bottom: bottom / tileWidth,
    left: left / tileHeight,
  );
}

List<String> _candidateRolesFromEdges(
  SurfaceStudioColumnEdgeOccupancy occupancy,
) {
  final candidates = <String>['isolated'];
  if (occupancy.top > 0.55) {
    candidates.add('endNorth');
  }
  if (occupancy.right > 0.55) {
    candidates.add('endEast');
  }
  if (occupancy.bottom > 0.55) {
    candidates.add('endSouth');
  }
  if (occupancy.left > 0.55) {
    candidates.add('endWest');
  }
  return List<String>.unmodifiable(candidates);
}

String _pngDataUrl(img.Image image) =>
    'data:image/png;base64,${base64Encode(img.encodePng(image))}';

String _dataUrl(Uint8List bytes) =>
    'data:image/png;base64,${base64Encode(bytes)}';

String _hexColor(int red, int green, int blue) =>
    '#${_hex(red)}${_hex(green)}${_hex(blue)}';

String _hex(int value) => value.clamp(0, 255).toRadixString(16).padLeft(2, '0');

double _round(double value) => double.parse(value.toStringAsFixed(3));

img.Image? _tryDecodeImage(Uint8List imageBytes) {
  try {
    return img.decodeImage(imageBytes);
  } catch (_) {
    return null;
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
  String? _mistralProgressMessage;
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
      _mistralProgressMessage = null;
      _statusMessage =
          'Suggestions locales prêtes — validation utilisateur requise.';
    });
  }

  void _requestAiSuggestion({bool mergeWithLocal = false}) {
    setState(() {
      _suggestionReviewOpen = true;
      _aiConfirmationOpen = true;
      _mergeAiAfterConfirmation = mergeWithLocal;
      _mistralProgressMessage = null;
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
        _mistralProgressMessage = null;
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
      _mistralProgressMessage = 'Analyse visuelle approfondie…';
    });
    final aiController = SurfaceStudioMappingSuggestionController(
      aiSuggester:
          widget.aiMappingSuggester ?? SurfaceStudioMistralMappingSuggester(),
    );
    late final SurfaceStudioMappingSuggestionResult ai;
    try {
      ai = await aiController.suggestMistral(
        apiKey: apiKey,
        imageBytes: imageBytes,
        tileWidth: _tileWidthValue,
        tileHeight: _tileHeightValue,
        columnCount: _columnCount,
        frameCount: _frameCount,
      );
    } on TimeoutException {
      ai = const SurfaceStudioMappingSuggestionResult(
        suggestions: <SurfaceStudioRoleSuggestion>[],
        warnings: <String>[
          'Mistral n’a pas répondu à temps. Aucune modification n’a été appliquée.',
        ],
        source: SurfaceStudioMappingSuggestionSource.mistral,
      );
    } catch (_) {
      ai = const SurfaceStudioMappingSuggestionResult(
        suggestions: <SurfaceStudioRoleSuggestion>[],
        warnings: <String>[
          'Analyse Mistral impossible. Aucune modification n’a été appliquée.',
        ],
        source: SurfaceStudioMappingSuggestionSource.mistral,
      );
    }
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
      _mistralProgressMessage = null;
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

  void _applySingleSuggestion(SurfaceStudioRoleSuggestion suggestion) {
    setState(() {
      _assignmentDraft =
          _assignmentDraft.assignColumns(suggestion.role, suggestion.columns);
      _statusMessage = 'Suggestion appliquée au mapping de travail.';
    });
  }

  void _useSelectionAsCenter() {
    final columns = _selectedColumns.columns;
    if (columns.isEmpty) {
      setState(() {
        _statusMessage = 'Sélectionnez au moins une colonne à assigner.';
      });
      return;
    }
    setState(() {
      _assignmentDraft =
          _assignmentDraft.assignColumns(SurfaceVariantRole.isolated, columns);
      _statusMessage = 'Colonnes sélectionnées assignées à Plein(center).';
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
              progressMessage: _mistralProgressMessage,
              onCancel: () {
                setState(() {
                  _suggestionReviewOpen = false;
                  _aiConfirmationOpen = false;
                  _mistralProgressMessage = null;
                });
              },
              onRunLocal: () => _runLocalSuggestion(),
              onRequestAi: () => _requestAiSuggestion(),
              onCancelAi: () => setState(() => _aiConfirmationOpen = false),
              onConfirmAi: () => _confirmAiSuggestion(
                mergeWithLocal: _mergeAiAfterConfirmation,
              ),
              onCompare: () => _requestAiSuggestion(mergeWithLocal: true),
              onApplySuggestion: _applySingleSuggestion,
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
          centerAssigned:
              _assignmentDraft.isAssigned(SurfaceVariantRole.isolated),
          centerColumns:
              _assignmentDraft.columnsForRole(SurfaceVariantRole.isolated),
          zoomPercent: _zoomPercent,
          onColumnSelectionChanged: (selection) {
            setState(() => _selectedColumns = selection);
          },
          onUseSelectionAsCenter: _useSelectionAsCenter,
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
            tileWidth: _tileWidthValue,
            tileHeight: _tileHeightValue,
            columnCount: _columnCount,
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
            tileWidth: _tileWidthValue,
            tileHeight: _tileHeightValue,
            columnCount: _columnCount,
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
    required this.progressMessage,
    required this.onCancel,
    required this.onRunLocal,
    required this.onRequestAi,
    required this.onCancelAi,
    required this.onConfirmAi,
    required this.onCompare,
    required this.onApplySuggestion,
    required this.onApplyReliable,
    required this.onApplyAll,
  });

  final SurfaceStudioMappingSuggestionResult result;
  final bool mistralKeyConfigured;
  final bool aiConfirmationOpen;
  final bool running;
  final String? progressMessage;
  final VoidCallback onCancel;
  final VoidCallback onRunLocal;
  final VoidCallback onRequestAi;
  final VoidCallback onCancelAi;
  final VoidCallback onConfirmAi;
  final VoidCallback onCompare;
  final ValueChanged<SurfaceStudioRoleSuggestion> onApplySuggestion;
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
                      _SuggestionRow(
                        suggestion: suggestion,
                        onApply: () => onApplySuggestion(suggestion),
                      ),
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
                          if (running) ...[
                            const SizedBox(height: 10),
                            Container(
                              key: const ValueKey(
                                'surfaceStudio.suggestion.mistralProgress',
                              ),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: SurfaceStudioDesignTokens.backgroundDeep,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      SurfaceStudioDesignTokens.accentGoldSoft,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const CupertinoActivityIndicator(radius: 10),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Mistral analyse l’atlas avec un niveau de réflexion élevé. Cela peut prendre quelques secondes.',
                                          style: TextStyle(
                                            color: SurfaceStudioDesignTokens
                                                .textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          progressMessage ??
                                              'Analyse visuelle approfondie…',
                                          style: const TextStyle(
                                            color: SurfaceStudioDesignTokens
                                                .accentGold,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
  const _SuggestionRow({
    required this.suggestion,
    required this.onApply,
  });

  final SurfaceStudioRoleSuggestion suggestion;
  final VoidCallback onApply;

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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton(
              key: ValueKey(
                'surfaceStudio.suggestion.accept.${suggestion.role.name}',
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: SurfaceStudioDesignTokens.accentTealSoft,
              onPressed: onApply,
              child: const Text('Accepter'),
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

### packages/map_editor/test/surface_studio/surface_studio_atlas_view_geometry_test.dart

```dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_view_geometry.dart';

void main() {
  test('computeContainedImageRect preserves ratio and exposes letterbox', () {
    final rect = computeSurfaceStudioContainedImageRect(
      viewportSize: const Size(600, 400),
      imagePixelSize: const Size(736, 1024),
    );

    expect(rect.left, closeTo(156.25, 0.001));
    expect(rect.top, closeTo(0, 0.001));
    expect(rect.width, closeTo(287.5, 0.001));
    expect(rect.height, closeTo(400, 0.001));
  });

  test('hit testing ignores letterbox and maps fitted rect columns', () {
    final geometry = SurfaceStudioAtlasViewGeometry.fromContain(
      viewportSize: const Size(600, 400),
      imagePixelSize: const Size(736, 1024),
      tileWidth: 32,
      tileHeight: 32,
      columnCount: 23,
      frameCount: 32,
    );

    expect(
      surfaceStudioColumnAtViewportOffset(
        localPosition: const Offset(120, 200),
        geometry: geometry,
      ),
      isNull,
    );
    expect(
      surfaceStudioColumnAtViewportOffset(
        localPosition: const Offset(200, 200),
        geometry: geometry,
      ),
      4,
    );
    expect(
      surfaceStudioFrameAtViewportOffset(
        localPosition: const Offset(200, 7),
        geometry: geometry,
      ),
      1,
    );
  });

  test('column viewport rect and tile source rect share 1-based column rules',
      () {
    final geometry = SurfaceStudioAtlasViewGeometry.fromContain(
      viewportSize: const Size(600, 400),
      imagePixelSize: const Size(736, 1024),
      tileWidth: 32,
      tileHeight: 32,
      columnCount: 23,
      frameCount: 32,
    );

    final column4 = surfaceStudioColumnViewportRect(
      uiColumn: 4,
      geometry: geometry,
    );
    expect(column4.left, closeTo(193.75, 0.001));
    expect(column4.width, closeTo(12.5, 0.001));
    expect(geometry.fittedImageRect.contains(column4.center), isTrue);

    final source = surfaceStudioTileSourceRect(
      uiColumn: 4,
      frameIndex: 1,
      tileWidth: 32,
      tileHeight: 32,
      columnCount: 23,
      frameCount: 32,
    );
    expect(source, const Rect.fromLTWH(96, 32, 32, 32));
  });
}
```

### packages/map_editor/test/surface_studio/surface_studio_atlas_viewport_coordinate_test.dart

```dart
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_editor/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_column_selection.dart';

void main() {
  testWidgets(
      'atlas viewport hit testing uses fitted image rect, not viewport width',
      (tester) async {
    var selection = const SurfaceStudioColumnSelection.empty();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 600,
            height: 460,
            child: SurfaceStudioAtlasViewport(
              columnCount: 23,
              frameCount: 32,
              tileWidth: 32,
              tileHeight: 32,
              atlasImageBytes: _atlasBytes(),
              selection: selection,
              centerAssigned: false,
              centerColumns: const <int>[],
              zoomPercent: 100,
              onColumnSelectionChanged: (next) => selection = next,
              onUseSelectionAsCenter: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final canvas = find.byKey(const ValueKey('surfaceStudio.atlas.canvas'));
    expect(canvas, findsOneWidget);
    expect(find.byKey(const ValueKey('surfaceStudio.atlas.realImage')),
        findsNothing);

    final canvasTopLeft = tester.getTopLeft(canvas);
    await tester.tapAt(canvasTopLeft + const Offset(120, 210));
    await tester.pump();
    expect(selection.columns, isEmpty);

    await tester.tapAt(canvasTopLeft + const Offset(200, 210));
    await tester.pump();
    expect(selection.columns, <int>[4]);
  });
}

Uint8List _atlasBytes() {
  const tile = 32;
  const columns = 23;
  const frames = 32;
  final image = img.Image(width: columns * tile, height: frames * tile);
  for (var frame = 0; frame < frames; frame++) {
    for (var column = 0; column < columns; column++) {
      img.fillRect(
        image,
        x1: column * tile,
        y1: frame * tile,
        x2: column * tile + tile - 1,
        y2: frame * tile + tile - 1,
        color: img.ColorRgb8(20 + column * 5, 50 + frame, 160),
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
```

### packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  test('tile source rect uses 1-based UI columns and 0-based atlas pixels', () {
    final rect = surfaceStudioTileSourceRect(
      uiColumn: 4,
      frameIndex: 1,
      tileWidth: 8,
      tileHeight: 8,
      columnCount: 5,
      frameCount: 2,
    );

    expect(rect, const ui.Rect.fromLTWH(24, 8, 8, 8));
  });

  test('tile source rect points to the expected fixture colors', () {
    final atlas = img.decodePng(_atlasBytes())!;

    final column4Frame0 = surfaceStudioTileSourceRect(
      uiColumn: 4,
      frameIndex: 0,
      tileWidth: 8,
      tileHeight: 8,
      columnCount: 5,
      frameCount: 2,
    );
    final column5Frame1 = surfaceStudioTileSourceRect(
      uiColumn: 5,
      frameIndex: 1,
      tileWidth: 8,
      tileHeight: 8,
      columnCount: 5,
      frameCount: 2,
    );

    final green = atlas.getPixel(
      column4Frame0.left.toInt() + 1,
      column4Frame0.top.toInt() + 1,
    );
    final darkBlue = atlas.getPixel(
      column5Frame1.left.toInt() + 1,
      column5Frame1.top.toInt() + 1,
    );

    expect(green.r, 20);
    expect(green.g, 220);
    expect(green.b, 60);
    expect(darkBlue.r, 8);
    expect(darkBlue.g, 42);
    expect(darkBlue.b, 96);
  });

  testWidgets(
      'selection alone is not mapping, quick center assignment activates preview',
      (tester) async {
    final temp = Directory.systemTemp.createTempSync('surface_mapper_preview_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final image = File('${temp.path}/tiles/water.png');
    image.parent.createSync(recursive: true);
    image.writeAsBytesSync(_atlasBytes());

    await pumpSurfaceStudioForTest(
      tester,
      readModel: _readModel(),
      projectTilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'water_tiles',
          name: 'Water Tiles',
          relativePath: 'tiles/water.png',
          sortOrder: 0,
        ),
      ],
      projectRootPath: temp.path,
    );
    await tester.pumpAndSettle();

    expect(find.text('Colonnes sélectionnées : 4–5'), findsOneWidget);
    expect(find.text('Plein(center) : non assigné'), findsOneWidget);
    expect(find.textContaining('Assignez au moins le rôle'), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
        findsNothing);

    await tester.tap(
      find.byKey(const Key('surfaceStudio.atlas.useSelectionAsCenter')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plein(center) : colonnes 4–5'), findsOneWidget);
    expect(find.textContaining('Assignez au moins le rôle'), findsNothing);
    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
        findsOneWidget);
    expect(find.textContaining('Preview partielle'), findsOneWidget);
    expect(
      find.textContaining('Source rect actuelle : x=24 y=0 w=8 h=8'),
      findsOneWidget,
    );

    final centerSlot =
        find.byKey(const Key('surfaceStudio.schema.role.center'));
    expect(find.descendant(of: centerSlot, matching: find.text('4')),
        findsOneWidget);
    expect(find.descendant(of: centerSlot, matching: find.text('5')),
        findsOneWidget);
  });

  testWidgets('preview frame controls change the rendered frame state',
      (tester) async {
    final temp = Directory.systemTemp.createTempSync('surface_frame_preview_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final image = File('${temp.path}/tiles/water.png');
    image.parent.createSync(recursive: true);
    image.writeAsBytesSync(_atlasBytes());

    await pumpSurfaceStudioForTest(
      tester,
      readModel: _readModel(),
      projectTilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'water_tiles',
          name: 'Water Tiles',
          relativePath: 'tiles/water.png',
          sortOrder: 0,
        ),
      ],
      projectRootPath: temp.path,
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('surfaceStudio.atlas.useSelectionAsCenter')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Frame 1 / 2'), findsOneWidget);
    expect(
      find.textContaining('Source rect actuelle : x=24 y=0 w=8 h=8'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('surfaceStudio.preview.next')));
    await tester.pumpAndSettle();
    expect(find.text('Frame 2 / 2'), findsOneWidget);
    expect(
      find.textContaining('Source rect actuelle : x=32 y=8 w=8 h=8'),
      findsOneWidget,
    );
  });
}

SurfaceStudioReadModel _readModel() {
  const atlasId = 'water-atlas';
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[
        ProjectSurfaceAtlas(
          id: atlasId,
          name: 'Water Atlas',
          tilesetId: 'water_tiles',
          geometry: SurfaceAtlasGeometry(
            tileSize: SurfaceAtlasTileSize(width: 8, height: 8),
            gridSize: SurfaceAtlasGridSize(columns: 5, rows: 2),
            layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
          ),
        ),
      ],
      animations: const <ProjectSurfaceAnimation>[],
      presets: const <ProjectSurfacePreset>[],
    ),
  );
}

Uint8List _atlasBytes() {
  const tile = 8;
  const columns = 5;
  const frames = 2;
  final image = img.Image(width: columns * tile, height: frames * tile);
  for (var frame = 0; frame < frames; frame++) {
    for (var column = 0; column < columns; column++) {
      final color = switch (column) {
        3 => frame == 0 ? img.ColorRgb8(20, 220, 60) : img.ColorRgb8(6, 90, 24),
        4 =>
          frame == 0 ? img.ColorRgb8(30, 120, 240) : img.ColorRgb8(8, 42, 96),
        _ => img.ColorRgb8(140 + column * 10, 20, 60 + frame * 30),
      };
      img.fillRect(
        image,
        x1: column * tile,
        y1: frame * tile,
        x2: column * tile + tile - 1,
        y2: frame * tile + tile - 1,
        color: color,
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
```

### packages/map_editor/test/surface_studio/surface_studio_mistral_vision_pack_test.dart

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_editor/src/features/surface_studio/surface_studio_mistral_vision_pack.dart';

void main() {
  test('vision pack builds original, annotated and contact sheet data urls',
      () {
    final pack = buildSurfaceStudioMistralVisionPack(
      imageBytes: _atlasBytesWithEmptyColumn(),
      tileWidth: 8,
      tileHeight: 8,
      columnCount: 4,
      frameCount: 2,
    );

    expect(pack.originalAtlasDataUrl, startsWith('data:image/png;base64,'));
    expect(pack.annotatedAtlasDataUrl, startsWith('data:image/png;base64,'));
    expect(
      pack.columnContactSheetDataUrl,
      startsWith('data:image/png;base64,'),
    );
    expect(pack.columnDescriptors, hasLength(4));
    expect(pack.columnDescriptors[2].column, 3);
    expect(pack.columnDescriptors[2].likelyEmpty, isTrue);
    expect(pack.columnDescriptors[0].averageColorHex, startsWith('#'));

    final contactSheet = img.decodePng(_decodeDataUrl(
      pack.columnContactSheetDataUrl,
    ));
    expect(contactSheet, isNotNull);
    expect(contactSheet!.width, greaterThan(contactSheet.height));

    final descriptorJson = surfaceStudioColumnDescriptorsJson(
      pack.columnDescriptors,
    );
    expect(descriptorJson, contains('"likelyEmpty": true'));
    expect(descriptorJson, isNot(contains('/Users/')));
    expect(descriptorJson, isNot(contains('configured-secret')));
  });
}

Uint8List _atlasBytesWithEmptyColumn() {
  const tile = 8;
  const columns = 4;
  const frames = 2;
  final image = img.Image(width: columns * tile, height: frames * tile);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
  for (var frame = 0; frame < frames; frame++) {
    for (var column = 0; column < columns; column++) {
      if (column == 2) {
        continue;
      }
      img.fillRect(
        image,
        x1: column * tile,
        y1: frame * tile,
        x2: column * tile + tile - 1,
        y2: frame * tile + tile - 1,
        color: img.ColorRgba8(30 + column * 40, 120, 210, 255),
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _decodeDataUrl(String dataUrl) {
  final encoded = dataUrl.substring(dataUrl.indexOf(',') + 1);
  return Uint8List.fromList(base64Decode(encoded));
}
```

### packages/map_editor/test/surface_studio/surface_studio_mistral_prompt_test.dart

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart';

void main() {
  test('prompt asks for careful visual reasoning and documents roles exactly',
      () {
    final prompt = buildSurfaceStudioMappingSuggestionPrompt(
      tileWidth: 8,
      tileHeight: 8,
      columnCount: 5,
      frameCount: 2,
    );

    expect(prompt, contains('Take your time internally'));
    expect(prompt, contains('Use high-effort visual reasoning'));
    expect(prompt, contains('Inspect the column contact sheet first'));
    expect(prompt, contains('Do not guess'));
    expect(prompt, contains('Prefer abstaining over wrong mappings'));
    expect(prompt, contains('Do not guess when uncertain'));
    expect(prompt, contains('Columns are 1-based'));
    expect(prompt, contains('Never map likelyEmpty columns'));
    expect(prompt, contains('tileWidth: 8'));
    expect(prompt, contains('tileHeight: 8'));
    expect(prompt, contains('columns: 5'));
    expect(prompt, contains('frames: 2'));
    expect(prompt, contains('isolated may contain multiple columns'));
    expect(prompt, contains('All other roles must contain at most one column'));
    expect(
      prompt,
      contains(
        'isolated, endNorth, endEast, endSouth, endWest, horizontal, vertical, cornerNW, cornerNE, cornerSW, cornerSE, innerCornerNW, innerCornerNE, innerCornerSW, innerCornerSE, teeNorth, teeEast, teeSouth, teeWest, cross',
      ),
    );
    expect(prompt, contains('Plein(center) = isolated'));
    expect(prompt, contains('Bord haut = endNorth'));
  });

  test('Mistral request uses high reasoning, schema output and no secret body',
      () async {
    Map<String, dynamic>? requestBody;
    final suggester = SurfaceStudioMistralMappingSuggester(
      httpClient: MockClient((request) async {
        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        expect(request.headers['Authorization'], 'Bearer configured-secret');
        expect(request.body, isNot(contains('configured-secret')));
        expect(request.body, isNot(contains('/Users/')));
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'assignments': const [],
                    'rejectedColumns': const [],
                    'warnings': const ['No confident mapping.'],
                  }),
                },
              },
            ],
          }),
          200,
        );
      }),
    );

    await suggester.suggest(
      apiKey: 'configured-secret',
      imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
      tileWidth: 8,
      tileHeight: 8,
      columnCount: 5,
      frameCount: 2,
    );

    final body = requestBody!;
    expect(body['reasoning_effort'], 'high');
    expect(body['temperature'], lessThanOrEqualTo(0.2));
    final responseFormat = body['response_format'] as Map<String, dynamic>;
    expect(responseFormat['type'], 'json_schema');
    expect(responseFormat['json_schema'], isA<Map<String, dynamic>>());
    expect(jsonEncode(responseFormat), contains('evidenceColumns'));
    expect(jsonEncode(responseFormat), contains('rejectedColumns'));
    expect(jsonEncode(body), contains('Take your time internally'));
    expect(
        jsonEncode(body), contains('Inspect the column contact sheet first'));
    final content = ((body['messages'] as List).single
        as Map<String, dynamic>)['content'] as List<dynamic>;
    expect(
      content
          .whereType<Map<String, dynamic>>()
          .where((part) => part['type'] == 'image_url'),
      hasLength(3),
    );
  });
}
```

### packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
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

  testWidgets('accepted Mistral suggestion updates mapping and live preview',
      (tester) async {
    final temp =
        Directory.systemTemp.createTempSync('surface_mistral_preview_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final image = File('${temp.path}/tiles/water.png');
    image.parent.createSync(recursive: true);
    image.writeAsBytesSync(_atlasBytes());
    final fakeAi = _FakeAiSuggester();

    await pumpSurfaceStudioForTest(
      tester,
      readModel: _readModel(),
      projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
      projectTilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'water_tiles',
          name: 'Water Tiles',
          relativePath: 'tiles/water.png',
          sortOrder: 0,
        ),
      ],
      projectRootPath: temp.path,
      aiMappingSuggester: fakeAi,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Assignez au moins le rôle'), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
        findsNothing);

    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
    await tester.pumpAndSettle();
    final mistralButton =
        find.byKey(const Key('surfaceStudio.suggestion.mistral'));
    await tester.ensureVisible(mistralButton);
    await tester.tap(mistralButton);
    await tester.pumpAndSettle();
    expect(find.text('Confirmer l’analyse IA'), findsOneWidget);
    expect(fakeAi.calls, 0);

    final confirmButton =
        find.byKey(const Key('surfaceStudio.suggestion.confirmAi'));
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
    expect(fakeAi.calls, 1);
    expect(find.text('AI center'), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
        findsNothing);

    final acceptButton =
        find.byKey(const Key('surfaceStudio.suggestion.accept.isolated'));
    await tester.ensureVisible(acceptButton);
    await tester.tap(acceptButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Assignez au moins le rôle'), findsNothing);
    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
        findsOneWidget);
    final centerSlot =
        find.byKey(const Key('surfaceStudio.schema.role.center'));
    expect(find.descendant(of: centerSlot, matching: find.text('4')),
        findsOneWidget);
    expect(find.descendant(of: centerSlot, matching: find.text('5')),
        findsOneWidget);
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
                        'evidenceColumns': [4, 5],
                        'reason': 'Center water candidates.',
                      },
                      {
                        'role': 'endNorth',
                        'columns': [99],
                        'confidence': 'high',
                        'evidenceColumns': [99],
                        'reason': 'Out of range.',
                      },
                      {
                        'role': 'endEast',
                        'columns': [1, 2],
                        'confidence': 'high',
                        'evidenceColumns': [1, 2],
                        'reason': 'Too many columns.',
                      },
                      {
                        'role': 'unknown',
                        'columns': [3],
                        'confidence': 'high',
                        'evidenceColumns': [3],
                        'reason': 'Unknown role.',
                      },
                    ],
                    'rejectedColumns': const [],
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

  test('Mistral suggester rejects locally likelyEmpty columns', () async {
    final suggester = SurfaceStudioMistralMappingSuggester(
      httpClient: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'assignments': [
                      {
                        'role': 'isolated',
                        'columns': [3],
                        'confidence': 'high',
                        'evidenceColumns': [3],
                        'reason': 'Looks empty but claimed as center.',
                      },
                    ],
                    'rejectedColumns': const [],
                    'warnings': const [],
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
      imageBytes: _atlasBytesWithEmptyColumn(),
      tileWidth: 8,
      tileHeight: 8,
      columnCount: 4,
      frameCount: 2,
    );

    expect(result.suggestions, isEmpty);
    expect(
      result.warnings,
      contains(
        'Suggestion Mistral sur colonne likelyEmpty rejetée pour isolated : 3.',
      ),
    );
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

SurfaceStudioReadModel _readModel() {
  const atlasId = 'water-atlas';
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[
        ProjectSurfaceAtlas(
          id: atlasId,
          name: 'Water Atlas',
          tilesetId: 'water_tiles',
          geometry: SurfaceAtlasGeometry(
            tileSize: SurfaceAtlasTileSize(width: 8, height: 8),
            gridSize: SurfaceAtlasGridSize(columns: 5, rows: 2),
            layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
          ),
        ),
      ],
      animations: const <ProjectSurfaceAnimation>[],
      presets: const <ProjectSurfacePreset>[],
    ),
  );
}

Uint8List _atlasBytes() {
  const tile = 8;
  const columns = 5;
  const frames = 2;
  final image = img.Image(width: columns * tile, height: frames * tile);
  for (var frame = 0; frame < frames; frame++) {
    for (var column = 0; column < columns; column++) {
      img.fillRect(
        image,
        x1: column * tile,
        y1: frame * tile,
        x2: column * tile + tile - 1,
        y2: frame * tile + tile - 1,
        color: img.ColorRgb8(40 + column * 32, 80 + frame * 70, 180),
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _atlasBytesWithEmptyColumn() {
  const tile = 8;
  const columns = 4;
  const frames = 2;
  final image = img.Image(width: columns * tile, height: frames * tile);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
  for (var frame = 0; frame < frames; frame++) {
    for (var column = 0; column < columns; column++) {
      if (column == 2) {
        continue;
      }
      img.fillRect(
        image,
        x1: column * tile,
        y1: frame * tile,
        x2: column * tile + tile - 1,
        y2: frame * tile + tile - 1,
        color: img.ColorRgba8(40 + column * 30, 100, 180, 255),
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
```

### packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart

```dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  testWidgets('Mistral progress stays visible while AI future is pending',
      (tester) async {
    final temp = Directory.systemTemp.createTempSync('surface_mistral_wait_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final image = File('${temp.path}/tiles/water.png');
    image.parent.createSync(recursive: true);
    image.writeAsBytesSync(_atlasBytes());
    final fakeAi = _PendingAiSuggester();

    await pumpSurfaceStudioForTest(
      tester,
      readModel: _readModel(),
      projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
      projectTilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'water_tiles',
          name: 'Water Tiles',
          relativePath: 'tiles/water.png',
          sortOrder: 0,
        ),
      ],
      projectRootPath: temp.path,
      aiMappingSuggester: fakeAi,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
    await tester.pumpAndSettle();
    final mistralButton =
        find.byKey(const Key('surfaceStudio.suggestion.mistral'));
    await tester.ensureVisible(mistralButton);
    await tester.tap(mistralButton);
    await tester.pumpAndSettle();
    final confirmButton =
        find.byKey(const Key('surfaceStudio.suggestion.confirmAi'));
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pump();

    expect(fakeAi.calls, 1);
    expect(
      find.byKey(const Key('surfaceStudio.suggestion.mistralProgress')),
      findsOneWidget,
    );
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(find.textContaining('Analyse visuelle approfondie'), findsOneWidget);
    expect(
      find.textContaining('Mistral analyse l’atlas avec un niveau'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('surfaceStudio.suggestion.mistral')),
          )
          .onPressed,
      isNull,
    );
    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
        findsNothing);

    fakeAi.complete();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('surfaceStudio.suggestion.mistralProgress')),
      findsNothing,
    );
    expect(find.text('AI center'), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
        findsNothing);
  });

  testWidgets('Mistral timeout is shown without mutating mapping',
      (tester) async {
    final temp =
        Directory.systemTemp.createTempSync('surface_mistral_timeout_');
    addTearDown(() => temp.deleteSync(recursive: true));
    final image = File('${temp.path}/tiles/water.png');
    image.parent.createSync(recursive: true);
    image.writeAsBytesSync(_atlasBytes());

    await pumpSurfaceStudioForTest(
      tester,
      readModel: _readModel(),
      projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
      projectTilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'water_tiles',
          name: 'Water Tiles',
          relativePath: 'tiles/water.png',
          sortOrder: 0,
        ),
      ],
      projectRootPath: temp.path,
      aiMappingSuggester: const _TimeoutAiSuggester(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
    await tester.pumpAndSettle();
    final mistralButton =
        find.byKey(const Key('surfaceStudio.suggestion.mistral'));
    await tester.ensureVisible(mistralButton);
    await tester.tap(mistralButton);
    await tester.pumpAndSettle();
    final confirmButton =
        find.byKey(const Key('surfaceStudio.suggestion.confirmAi'));
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Mistral n’a pas répondu à temps'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
        findsNothing);
  });
}

final class _PendingAiSuggester implements SurfaceStudioAiMappingSuggester {
  final Completer<SurfaceStudioMappingSuggestionResult> completer =
      Completer<SurfaceStudioMappingSuggestionResult>();
  int calls = 0;

  @override
  Future<SurfaceStudioMappingSuggestionResult> suggest({
    required String apiKey,
    required Uint8List imageBytes,
    required int tileWidth,
    required int tileHeight,
    required int columnCount,
    required int frameCount,
  }) {
    calls++;
    return completer.future;
  }

  void complete() {
    completer.complete(
      const SurfaceStudioMappingSuggestionResult(
        suggestions: <SurfaceStudioRoleSuggestion>[
          SurfaceStudioRoleSuggestion(
            role: SurfaceVariantRole.isolated,
            columns: <int>[4, 5],
            confidence: SurfaceStudioMappingSuggestionConfidence.high,
            source: SurfaceStudioMappingSuggestionSource.mistral,
            reason: 'AI center',
          ),
        ],
        warnings: <String>[],
        source: SurfaceStudioMappingSuggestionSource.mistral,
      ),
    );
  }
}

final class _TimeoutAiSuggester implements SurfaceStudioAiMappingSuggester {
  const _TimeoutAiSuggester();

  @override
  Future<SurfaceStudioMappingSuggestionResult> suggest({
    required String apiKey,
    required Uint8List imageBytes,
    required int tileWidth,
    required int tileHeight,
    required int columnCount,
    required int frameCount,
  }) {
    throw TimeoutException('fake timeout');
  }
}

SurfaceStudioReadModel _readModel() {
  const atlasId = 'water-atlas';
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[
        ProjectSurfaceAtlas(
          id: atlasId,
          name: 'Water Atlas',
          tilesetId: 'water_tiles',
          geometry: SurfaceAtlasGeometry(
            tileSize: SurfaceAtlasTileSize(width: 8, height: 8),
            gridSize: SurfaceAtlasGridSize(columns: 5, rows: 2),
            layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
          ),
        ),
      ],
      animations: const <ProjectSurfaceAnimation>[],
      presets: const <ProjectSurfacePreset>[],
    ),
  );
}

Uint8List _atlasBytes() {
  const tile = 8;
  const columns = 5;
  const frames = 2;
  final image = img.Image(width: columns * tile, height: frames * tile);
  for (var frame = 0; frame < frames; frame++) {
    for (var column = 0; column < columns; column++) {
      img.fillRect(
        image,
        x1: column * tile,
        y1: frame * tile,
        x2: column * tile + tile - 1,
        y2: frame * tile + tile - 1,
        color: img.ColorRgb8(40 + column * 32, 80 + frame * 70, 180),
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
```

## 20.9 Diffs complets


### packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart b/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
index d4318eb8..f51e4502 100644
--- a/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
@@ -1,11 +1,13 @@
+import 'dart:ui' as ui;
+
 import 'package:flutter/cupertino.dart';
 import 'package:flutter/material.dart' show Material, MaterialType, Slider;
 import 'package:flutter/services.dart';
 
+import '../surface_studio_atlas_view_geometry.dart';
 import '../surface_studio_column_selection.dart';
 import '../surface_studio_design_tokens.dart';
 import '../surface_studio_drag_payload.dart';
-import 'surface_studio_atlas_grid_painter.dart';
 
 class SurfaceStudioAtlasPanel extends StatelessWidget {
   const SurfaceStudioAtlasPanel({
@@ -19,6 +21,9 @@ class SurfaceStudioAtlasPanel extends StatelessWidget {
     required this.selection,
     required this.zoomPercent,
     required this.onColumnSelectionChanged,
+    required this.centerAssigned,
+    required this.centerColumns,
+    required this.onUseSelectionAsCenter,
     required this.onZoomChanged,
     required this.onReset,
     required this.onAutoSuggest,
@@ -31,8 +36,11 @@ class SurfaceStudioAtlasPanel extends StatelessWidget {
   final Uint8List? atlasImageBytes;
   final String? atlasImageFallbackLabel;
   final SurfaceStudioColumnSelection selection;
+  final bool centerAssigned;
+  final List<int> centerColumns;
   final double zoomPercent;
   final ValueChanged<SurfaceStudioColumnSelection> onColumnSelectionChanged;
+  final VoidCallback onUseSelectionAsCenter;
   final ValueChanged<double> onZoomChanged;
   final VoidCallback onReset;
   final VoidCallback onAutoSuggest;
@@ -55,8 +63,11 @@ class SurfaceStudioAtlasPanel extends StatelessWidget {
               atlasImageBytes: atlasImageBytes,
               atlasImageFallbackLabel: atlasImageFallbackLabel,
               selection: selection,
+              centerAssigned: centerAssigned,
+              centerColumns: centerColumns,
               zoomPercent: zoomPercent,
               onColumnSelectionChanged: onColumnSelectionChanged,
+              onUseSelectionAsCenter: onUseSelectionAsCenter,
             ),
           ),
           const SizedBox(height: 10),
@@ -86,8 +97,11 @@ class SurfaceStudioAtlasViewport extends StatelessWidget {
     this.atlasImageBytes,
     this.atlasImageFallbackLabel,
     required this.selection,
+    required this.centerAssigned,
+    required this.centerColumns,
     required this.zoomPercent,
     required this.onColumnSelectionChanged,
+    required this.onUseSelectionAsCenter,
   });
 
   final int columnCount;
@@ -97,8 +111,11 @@ class SurfaceStudioAtlasViewport extends StatelessWidget {
   final Uint8List? atlasImageBytes;
   final String? atlasImageFallbackLabel;
   final SurfaceStudioColumnSelection selection;
+  final bool centerAssigned;
+  final List<int> centerColumns;
   final double zoomPercent;
   final ValueChanged<SurfaceStudioColumnSelection> onColumnSelectionChanged;
+  final VoidCallback onUseSelectionAsCenter;
 
   @override
   Widget build(BuildContext context) {
@@ -118,90 +135,20 @@ class SurfaceStudioAtlasViewport extends StatelessWidget {
       padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
       child: Column(
         children: [
-          SizedBox(
-            height: 24,
-            child: Row(
-              children: [
-                for (var column = 1; column <= columnCount; column++)
-                  Expanded(
-                    child: GestureDetector(
-                      key: ValueKey('surfaceStudio.atlas.column.$column'),
-                      behavior: HitTestBehavior.opaque,
-                      onTap: () {
-                        final shift = HardwareKeyboard
-                            .instance.logicalKeysPressed
-                            .any((key) =>
-                                key == LogicalKeyboardKey.shiftLeft ||
-                                key == LogicalKeyboardKey.shiftRight);
-                        final next = shift && selection.isNotEmpty
-                            ? selection.selectContiguousTo(column)
-                            : selection.selectSingle(column);
-                        onColumnSelectionChanged(next);
-                      },
-                      child: Center(
-                        child: Text(
-                          '$column',
-                          style: TextStyle(
-                            color: selection.columns.contains(column)
-                                ? SurfaceStudioDesignTokens.accentGold
-                                : SurfaceStudioDesignTokens.textSecondary,
-                            fontSize: 12,
-                            fontWeight: FontWeight.w800,
-                          ),
-                        ),
-                      ),
-                    ),
-                  ),
-              ],
-            ),
-          ),
           Expanded(
             child: Stack(
               children: [
                 Positioned.fill(
-                  child: Stack(
-                    fit: StackFit.expand,
-                    children: [
-                      if (atlasImageBytes != null)
-                        Image.memory(
-                          atlasImageBytes!,
-                          key: const ValueKey('surfaceStudio.atlas.realImage'),
-                          fit: BoxFit.cover,
-                          gaplessPlayback: true,
-                          errorBuilder: (_, __, ___) => const Center(
-                            child: Text(
-                              'Image source indisponible — aperçu illustratif.',
-                              textAlign: TextAlign.center,
-                              style: TextStyle(
-                                color: SurfaceStudioDesignTokens.textMuted,
-                                fontSize: 12,
-                                fontWeight: FontWeight.w700,
-                              ),
-                            ),
-                          ),
-                        )
-                      else
-                        Center(
-                          child: Text(
-                            atlasImageFallbackLabel ??
-                                'Image source indisponible — aperçu illustratif.',
-                            textAlign: TextAlign.center,
-                            style: const TextStyle(
-                              color: SurfaceStudioDesignTokens.textMuted,
-                              fontSize: 12,
-                              fontWeight: FontWeight.w700,
-                            ),
-                          ),
-                        ),
-                      CustomPaint(
-                        painter: SurfaceStudioAtlasGridPainter(
-                          columnCount: columnCount,
-                          rowCount: frameCount,
-                          selectedColumns: selection.columns,
-                          zoomPercent: zoomPercent,
-                        ),
-                      ),
-                    ],
+                  child: SurfaceStudioAtlasCanvas(
+                    columnCount: columnCount,
+                    frameCount: frameCount,
+                    tileWidth: tileWidth,
+                    tileHeight: tileHeight,
+                    atlasImageBytes: atlasImageBytes,
+                    atlasImageFallbackLabel: atlasImageFallbackLabel,
+                    selection: selection,
+                    zoomPercent: zoomPercent,
+                    onColumnSelectionChanged: onColumnSelectionChanged,
                   ),
                 ),
                 if (selection.isNotEmpty)
@@ -223,21 +170,74 @@ class SurfaceStudioAtlasViewport extends StatelessWidget {
           ),
           const SizedBox(height: 8),
           Container(
-            height: 35,
-            alignment: Alignment.center,
+            constraints: const BoxConstraints(minHeight: 35),
             decoration: BoxDecoration(
               color: SurfaceStudioDesignTokens.backgroundPanel
                   .withValues(alpha: 0.72),
               borderRadius: BorderRadius.circular(10),
               border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
             ),
-            child: Text(
-              selection.microcopy,
-              textAlign: TextAlign.center,
-              style: const TextStyle(
-                color: SurfaceStudioDesignTokens.textMuted,
-                fontSize: 12,
-                fontWeight: FontWeight.w600,
+            child: Padding(
+              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
+              child: Wrap(
+                alignment: WrapAlignment.center,
+                crossAxisAlignment: WrapCrossAlignment.center,
+                spacing: 12,
+                runSpacing: 6,
+                children: [
+                  Text(
+                    selection.microcopy,
+                    textAlign: TextAlign.center,
+                    style: const TextStyle(
+                      color: SurfaceStudioDesignTokens.textMuted,
+                      fontSize: 12,
+                      fontWeight: FontWeight.w600,
+                    ),
+                  ),
+                  Text(
+                    selection.isEmpty
+                        ? 'Colonnes sélectionnées : aucune'
+                        : 'Colonnes sélectionnées : ${_formatColumns(selection.columns)}',
+                    style: const TextStyle(
+                      color: SurfaceStudioDesignTokens.textSecondary,
+                      fontSize: 12,
+                      fontWeight: FontWeight.w800,
+                    ),
+                  ),
+                  Text(
+                    centerAssigned
+                        ? 'Plein(center) : colonnes ${_formatColumns(centerColumns)}'
+                        : 'Plein(center) : non assigné',
+                    style: TextStyle(
+                      color: centerAssigned
+                          ? SurfaceStudioDesignTokens.accentTeal
+                          : SurfaceStudioDesignTokens.accentGold,
+                      fontSize: 12,
+                      fontWeight: FontWeight.w800,
+                    ),
+                  ),
+                  if (selection.isNotEmpty)
+                    CupertinoButton(
+                      key: const ValueKey(
+                        'surfaceStudio.atlas.useSelectionAsCenter',
+                      ),
+                      padding: const EdgeInsets.symmetric(
+                        horizontal: 10,
+                        vertical: 5,
+                      ),
+                      minimumSize: const Size(0, 0),
+                      color: SurfaceStudioDesignTokens.accentGoldSoft,
+                      onPressed: onUseSelectionAsCenter,
+                      child: const Text(
+                        'Utiliser comme Plein(center)',
+                        style: TextStyle(
+                          color: SurfaceStudioDesignTokens.accentGold,
+                          fontSize: 12,
+                          fontWeight: FontWeight.w900,
+                        ),
+                      ),
+                    ),
+                ],
               ),
             ),
           ),
@@ -247,6 +247,368 @@ class SurfaceStudioAtlasViewport extends StatelessWidget {
   }
 }
 
+class SurfaceStudioAtlasCanvas extends StatefulWidget {
+  const SurfaceStudioAtlasCanvas({
+    super.key,
+    required this.columnCount,
+    required this.frameCount,
+    required this.tileWidth,
+    required this.tileHeight,
+    this.atlasImageBytes,
+    this.atlasImageFallbackLabel,
+    required this.selection,
+    required this.zoomPercent,
+    required this.onColumnSelectionChanged,
+  });
+
+  final int columnCount;
+  final int frameCount;
+  final int tileWidth;
+  final int tileHeight;
+  final Uint8List? atlasImageBytes;
+  final String? atlasImageFallbackLabel;
+  final SurfaceStudioColumnSelection selection;
+  final double zoomPercent;
+  final ValueChanged<SurfaceStudioColumnSelection> onColumnSelectionChanged;
+
+  @override
+  State<SurfaceStudioAtlasCanvas> createState() =>
+      _SurfaceStudioAtlasCanvasState();
+}
+
+class _SurfaceStudioAtlasCanvasState extends State<SurfaceStudioAtlasCanvas> {
+  ui.Image? _image;
+  Object? _decodeToken;
+
+  @override
+  void initState() {
+    super.initState();
+    _decodeImage();
+  }
+
+  @override
+  void didUpdateWidget(covariant SurfaceStudioAtlasCanvas oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (oldWidget.atlasImageBytes != widget.atlasImageBytes) {
+      _image?.dispose();
+      _image = null;
+      _decodeImage();
+    }
+  }
+
+  @override
+  void dispose() {
+    _image?.dispose();
+    super.dispose();
+  }
+
+  void _decodeImage() {
+    final bytes = widget.atlasImageBytes;
+    if (bytes == null || bytes.isEmpty) {
+      _decodeToken = null;
+      return;
+    }
+    final token = Object();
+    _decodeToken = token;
+    ui.decodeImageFromList(bytes, (image) {
+      if (!mounted || _decodeToken != token) {
+        image.dispose();
+        return;
+      }
+      setState(() => _image = image);
+    });
+  }
+
+  void _selectColumn(int column) {
+    final shift = HardwareKeyboard.instance.logicalKeysPressed.any(
+      (key) =>
+          key == LogicalKeyboardKey.shiftLeft ||
+          key == LogicalKeyboardKey.shiftRight,
+    );
+    final next = shift && widget.selection.isNotEmpty
+        ? widget.selection.selectContiguousTo(column)
+        : widget.selection.selectSingle(column);
+    widget.onColumnSelectionChanged(next);
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    return LayoutBuilder(
+      builder: (context, constraints) {
+        final viewportSize = Size(
+          constraints.maxWidth.isFinite ? constraints.maxWidth : 1,
+          constraints.maxHeight.isFinite ? constraints.maxHeight : 1,
+        );
+        final image = _image;
+        final imagePixelSize = image == null
+            ? Size(
+                (widget.columnCount * widget.tileWidth).toDouble(),
+                (widget.frameCount * widget.tileHeight).toDouble(),
+              )
+            : Size(image.width.toDouble(), image.height.toDouble());
+        final geometry = SurfaceStudioAtlasViewGeometry.fromContain(
+          viewportSize: viewportSize,
+          imagePixelSize: imagePixelSize,
+          tileWidth: widget.tileWidth,
+          tileHeight: widget.tileHeight,
+          columnCount: widget.columnCount,
+          frameCount: widget.frameCount,
+        );
+        return GestureDetector(
+          key: const ValueKey('surfaceStudio.atlas.canvas'),
+          behavior: HitTestBehavior.opaque,
+          onTapDown: (details) {
+            final column = surfaceStudioColumnAtViewportOffset(
+              localPosition: details.localPosition,
+              geometry: geometry,
+            );
+            if (column != null) {
+              _selectColumn(column);
+            }
+          },
+          child: Stack(
+            fit: StackFit.expand,
+            children: [
+              CustomPaint(
+                painter: _SurfaceStudioAtlasCanvasPainter(
+                  atlasImage: image,
+                  geometry: geometry,
+                  selectedColumns: widget.selection.columns,
+                  zoomPercent: widget.zoomPercent,
+                  fallbackLabel: widget.atlasImageFallbackLabel ??
+                      'Image source indisponible — aperçu illustratif.',
+                ),
+                child: const SizedBox.expand(),
+              ),
+              if (image == null)
+                Center(
+                  child: Padding(
+                    padding: const EdgeInsets.all(16),
+                    child: Text(
+                      widget.atlasImageFallbackLabel ??
+                          'Image source indisponible — aperçu illustratif.',
+                      textAlign: TextAlign.center,
+                      style: const TextStyle(
+                        color: SurfaceStudioDesignTokens.textMuted,
+                        fontSize: 12,
+                        fontWeight: FontWeight.w700,
+                      ),
+                    ),
+                  ),
+                ),
+              for (var column = 1; column <= widget.columnCount; column++)
+                Positioned.fromRect(
+                  rect: surfaceStudioColumnViewportRect(
+                    uiColumn: column,
+                    geometry: geometry,
+                  ),
+                  child: GestureDetector(
+                    key: ValueKey('surfaceStudio.atlas.column.$column'),
+                    behavior: HitTestBehavior.translucent,
+                    onTap: () => _selectColumn(column),
+                    child: const SizedBox.expand(),
+                  ),
+                ),
+            ],
+          ),
+        );
+      },
+    );
+  }
+}
+
+class _SurfaceStudioAtlasCanvasPainter extends CustomPainter {
+  const _SurfaceStudioAtlasCanvasPainter({
+    required this.atlasImage,
+    required this.geometry,
+    required this.selectedColumns,
+    required this.zoomPercent,
+    required this.fallbackLabel,
+  });
+
+  final ui.Image? atlasImage;
+  final SurfaceStudioAtlasViewGeometry geometry;
+  final List<int> selectedColumns;
+  final double zoomPercent;
+  final String fallbackLabel;
+
+  @override
+  void paint(Canvas canvas, Size size) {
+    final viewportPaint = Paint()
+      ..color = SurfaceStudioDesignTokens.backgroundDeep;
+    canvas.drawRect(Offset.zero & size, viewportPaint);
+
+    final imageRect = geometry.fittedImageRect;
+    final image = atlasImage;
+    if (image != null) {
+      canvas.drawImageRect(
+        image,
+        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
+        imageRect,
+        Paint()..filterQuality = FilterQuality.none,
+      );
+    } else {
+      _drawFallbackSurface(canvas, imageRect);
+    }
+
+    _drawGrid(canvas, imageRect);
+    _drawColumnLabels(canvas);
+    _drawSelection(canvas);
+  }
+
+  void _drawFallbackSurface(Canvas canvas, Rect imageRect) {
+    final background = Paint()
+      ..shader = const LinearGradient(
+        colors: [Color(0xFF174A8B), Color(0xFF1A74D6), Color(0xFF123D3A)],
+        begin: Alignment.topLeft,
+        end: Alignment.bottomRight,
+      ).createShader(imageRect);
+    canvas.drawRect(imageRect, background);
+
+    final safeColumnCount = geometry.columnCount.clamp(1, 9999).toInt();
+    final safeFrameCount = geometry.frameCount.clamp(1, 9999).toInt();
+    final tileW = imageRect.width / safeColumnCount;
+    final tileH = imageRect.height / safeFrameCount;
+    final wavePaint = Paint()
+      ..color = SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.22)
+      ..style = PaintingStyle.stroke
+      ..strokeWidth = 1.2;
+    for (var y = 0; y < geometry.frameCount; y += 2) {
+      final centerY = imageRect.top + y * tileH + tileH / 2;
+      for (var x = 0; x < geometry.columnCount; x += 2) {
+        final left = imageRect.left + x * tileW + tileW * 0.18;
+        final rect = Rect.fromLTWH(
+            left, centerY - tileH * 0.22, tileW * 0.64, tileH * 0.44);
+        canvas.drawArc(rect, 0, 3.14159, false, wavePaint);
+      }
+    }
+  }
+
+  void _drawGrid(Canvas canvas, Rect imageRect) {
+    final columnCount = geometry.columnCount.clamp(1, 9999).toInt();
+    final frameCount = geometry.frameCount.clamp(1, 9999).toInt();
+    final columnWidth = imageRect.width / columnCount;
+    final rowHeight = imageRect.height / frameCount;
+    final linePaint = Paint()
+      ..color = SurfaceStudioDesignTokens.textPrimary.withValues(alpha: 0.22)
+      ..strokeWidth = 1;
+    final strongPaint = Paint()
+      ..color = SurfaceStudioDesignTokens.accentTeal.withValues(alpha: 0.24)
+      ..strokeWidth = 1.1;
+
+    canvas.save();
+    canvas.clipRect(imageRect);
+    for (var column = 0; column <= columnCount; column++) {
+      final x = imageRect.left + column * columnWidth;
+      canvas.drawLine(
+        Offset(x, imageRect.top),
+        Offset(x, imageRect.bottom),
+        column.isEven ? strongPaint : linePaint,
+      );
+    }
+    for (var row = 0; row <= frameCount; row++) {
+      final y = imageRect.top + row * rowHeight;
+      canvas.drawLine(
+        Offset(imageRect.left, y),
+        Offset(imageRect.right, y),
+        row % 4 == 0 ? strongPaint : linePaint,
+      );
+    }
+    canvas.restore();
+  }
+
+  void _drawColumnLabels(Canvas canvas) {
+    for (var column = 1; column <= geometry.columnCount; column++) {
+      final columnRect = surfaceStudioColumnViewportRect(
+        uiColumn: column,
+        geometry: geometry,
+      );
+      final isSelected = selectedColumns.contains(column);
+      final labelText = TextPainter(
+        text: TextSpan(
+          text: '$column',
+          style: TextStyle(
+            color: isSelected
+                ? SurfaceStudioDesignTokens.backgroundDeep
+                : SurfaceStudioDesignTokens.textSecondary,
+            fontSize: 11,
+            fontWeight: FontWeight.w900,
+          ),
+        ),
+        textDirection: TextDirection.ltr,
+      )..layout(maxWidth: columnRect.width);
+      final desiredLabelWidth = labelText.width + 9;
+      final labelWidth = columnRect.width < 18
+          ? columnRect.width
+          : desiredLabelWidth.clamp(18.0, columnRect.width).toDouble();
+      final labelRect = Rect.fromLTWH(
+        columnRect.center.dx - labelWidth / 2,
+        geometry.fittedImageRect.top + 6,
+        labelWidth,
+        18,
+      );
+      canvas.drawRRect(
+        RRect.fromRectAndRadius(labelRect, const Radius.circular(7)),
+        Paint()
+          ..color = isSelected
+              ? SurfaceStudioDesignTokens.accentGold
+              : SurfaceStudioDesignTokens.backgroundDeep.withValues(alpha: 0.7),
+      );
+      labelText.paint(
+        canvas,
+        Offset(
+          labelRect.center.dx - labelText.width / 2,
+          labelRect.center.dy - labelText.height / 2,
+        ),
+      );
+    }
+  }
+
+  void _drawSelection(Canvas canvas) {
+    if (selectedColumns.isEmpty) {
+      return;
+    }
+    final fillPaint = Paint()
+      ..color = SurfaceStudioDesignTokens.accentGold.withValues(alpha: 0.18);
+    final strokePaint = Paint()
+      ..color = SurfaceStudioDesignTokens.accentGold
+      ..style = PaintingStyle.stroke
+      ..strokeWidth = 2;
+    for (final column in selectedColumns) {
+      final rect = surfaceStudioColumnViewportRect(
+        uiColumn: column,
+        geometry: geometry,
+      ).deflate(1);
+      canvas.drawRRect(
+        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
+        fillPaint,
+      );
+      canvas.drawRRect(
+        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
+        strokePaint,
+      );
+    }
+  }
+
+  @override
+  bool shouldRepaint(covariant _SurfaceStudioAtlasCanvasPainter oldDelegate) =>
+      oldDelegate.atlasImage != atlasImage ||
+      oldDelegate.geometry != geometry ||
+      oldDelegate.selectedColumns != selectedColumns ||
+      oldDelegate.zoomPercent != zoomPercent ||
+      oldDelegate.fallbackLabel != fallbackLabel;
+}
+
+String _formatColumns(List<int> columns) {
+  if (columns.isEmpty) {
+    return 'aucune';
+  }
+  if (columns.length == 1) {
+    return '${columns.first}';
+  }
+  return '${columns.first}–${columns.last}';
+}
+
 class SurfaceStudioAtlasToolbar extends StatelessWidget {
   const SurfaceStudioAtlasToolbar({
     super.key,
```

### packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart b/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
index 67b3b4c6..dd843f98 100644
--- a/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
@@ -7,6 +7,7 @@ import 'package:map_core/map_core.dart';
 
 import '../surface_studio_design_tokens.dart';
 import '../surface_studio_role_assignment_draft.dart';
+import 'surface_studio_surface_preview_renderer.dart';
 
 class SurfaceStudioPreviewPanel extends StatelessWidget {
   const SurfaceStudioPreviewPanel({
@@ -17,6 +18,9 @@ class SurfaceStudioPreviewPanel extends StatelessWidget {
     required this.loop,
     required this.gridVisible,
     required this.previewSize,
+    required this.tileWidth,
+    required this.tileHeight,
+    required this.columnCount,
     required this.assignmentDraft,
     this.atlasImageBytes,
     this.atlasFallbackMessage,
@@ -35,6 +39,9 @@ class SurfaceStudioPreviewPanel extends StatelessWidget {
   final bool loop;
   final bool gridVisible;
   final int previewSize;
+  final int tileWidth;
+  final int tileHeight;
+  final int columnCount;
   final SurfaceStudioRoleAssignmentDraft assignmentDraft;
   final Uint8List? atlasImageBytes;
   final String? atlasFallbackMessage;
@@ -80,11 +87,12 @@ class SurfaceStudioPreviewPanel extends StatelessWidget {
                       gridVisible: gridVisible,
                       frameIndex: frameIndex,
                       frameCount: frameCount,
+                      tileWidth: tileWidth,
+                      tileHeight: tileHeight,
+                      columnCount: columnCount,
                       atlasImageBytes: atlasImageBytes,
                       atlasFallbackMessage: atlasFallbackMessage,
-                      hasCenter: assignmentDraft.isAssigned(
-                        SurfaceVariantRole.isolated,
-                      ),
+                      assignmentDraft: assignmentDraft,
                     ),
                   ),
                 ),
@@ -122,21 +130,30 @@ class _PreviewViewport extends StatelessWidget {
     required this.gridVisible,
     required this.frameIndex,
     required this.frameCount,
+    required this.tileWidth,
+    required this.tileHeight,
+    required this.columnCount,
     this.atlasImageBytes,
     this.atlasFallbackMessage,
-    required this.hasCenter,
+    required this.assignmentDraft,
   });
 
   final int previewSize;
   final bool gridVisible;
   final int frameIndex;
   final int frameCount;
+  final int tileWidth;
+  final int tileHeight;
+  final int columnCount;
   final Uint8List? atlasImageBytes;
   final String? atlasFallbackMessage;
-  final bool hasCenter;
+  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
 
   @override
   Widget build(BuildContext context) {
+    final hasCenter = assignmentDraft.isAssigned(SurfaceVariantRole.isolated);
+    final centerColumns =
+        assignmentDraft.columnsForRole(SurfaceVariantRole.isolated);
     return Container(
       decoration: BoxDecoration(
         color: SurfaceStudioDesignTokens.backgroundDeep,
@@ -149,32 +166,17 @@ class _PreviewViewport extends StatelessWidget {
               fit: StackFit.expand,
               children: [
                 if (atlasImageBytes != null)
-                  Image.memory(
-                    atlasImageBytes!,
-                    key: const ValueKey('surfaceStudio.preview.realImage'),
-                    fit: BoxFit.cover,
-                    alignment: Alignment(
-                      0,
-                      frameCount <= 1
-                          ? 0
-                          : -1 + (2 * (frameIndex / (frameCount - 1))),
-                    ),
-                    gaplessPlayback: true,
-                    errorBuilder: (_, __, ___) => Center(
-                      child: Padding(
-                        padding: const EdgeInsets.all(16),
-                        child: Text(
-                          atlasFallbackMessage ??
-                              'Image source indisponible — aperçu illustratif.',
-                          textAlign: TextAlign.center,
-                          style: const TextStyle(
-                            color: SurfaceStudioDesignTokens.textMuted,
-                            fontSize: 12,
-                            height: 1.3,
-                          ),
-                        ),
-                      ),
-                    ),
+                  SurfaceStudioSurfacePreviewRenderer(
+                    key: const ValueKey('surfaceStudio.preview.tileRenderer'),
+                    atlasImageBytes: atlasImageBytes!,
+                    assignmentDraft: assignmentDraft,
+                    tileWidth: tileWidth,
+                    tileHeight: tileHeight,
+                    columnCount: columnCount,
+                    frameCount: frameCount,
+                    frameIndex: frameIndex,
+                    previewSize: previewSize,
+                    gridVisible: gridVisible,
                   )
                 else
                   Center(
@@ -192,13 +194,26 @@ class _PreviewViewport extends StatelessWidget {
                       ),
                     ),
                   ),
-                CustomPaint(
-                  painter: _WaterPreviewPainter(
-                    gridVisible: gridVisible,
-                    previewSize: previewSize,
+                if (atlasImageBytes != null)
+                  const Positioned(
+                    left: 10,
+                    top: 10,
+                    child: _PartialPreviewBadge(),
+                  ),
+                if (atlasImageBytes != null && centerColumns.isNotEmpty)
+                  Positioned(
+                    left: 10,
+                    right: 10,
+                    bottom: 10,
+                    child: _SourceRectDebug(
+                      centerColumns: centerColumns,
+                      frameIndex: frameIndex,
+                      frameCount: frameCount,
+                      tileWidth: tileWidth,
+                      tileHeight: tileHeight,
+                      columnCount: columnCount,
+                    ),
                   ),
-                  child: const SizedBox.expand(),
-                ),
               ],
             )
           : const Center(
@@ -219,6 +234,101 @@ class _PreviewViewport extends StatelessWidget {
   }
 }
 
+class _SourceRectDebug extends StatelessWidget {
+  const _SourceRectDebug({
+    required this.centerColumns,
+    required this.frameIndex,
+    required this.frameCount,
+    required this.tileWidth,
+    required this.tileHeight,
+    required this.columnCount,
+  });
+
+  final List<int> centerColumns;
+  final int frameIndex;
+  final int frameCount;
+  final int tileWidth;
+  final int tileHeight;
+  final int columnCount;
+
+  @override
+  Widget build(BuildContext context) {
+    final safeFrameCount = frameCount < 1 ? 1 : frameCount;
+    final safeFrameIndex = frameIndex % safeFrameCount;
+    final column = centerColumns[safeFrameIndex % centerColumns.length];
+    final source = surfaceStudioTileSourceRect(
+      uiColumn: column,
+      frameIndex: safeFrameIndex,
+      tileWidth: tileWidth,
+      tileHeight: tileHeight,
+      columnCount: columnCount,
+      frameCount: safeFrameCount,
+    );
+    return DecoratedBox(
+      decoration: BoxDecoration(
+        color: SurfaceStudioDesignTokens.backgroundDeep.withValues(alpha: 0.82),
+        borderRadius: BorderRadius.circular(10),
+        border: Border.all(
+          color: SurfaceStudioDesignTokens.borderStrong.withValues(alpha: 0.72),
+        ),
+      ),
+      child: Padding(
+        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
+        child: Text(
+          'Colonnes assignées au Plein : ${_formatColumns(centerColumns)}  •  '
+          'Source rect actuelle : x=${source.left.round()} y=${source.top.round()} '
+          'w=${source.width.round()} h=${source.height.round()}  •  '
+          'Frame : ${safeFrameIndex + 1} / $safeFrameCount',
+          maxLines: 2,
+          overflow: TextOverflow.ellipsis,
+          style: const TextStyle(
+            color: SurfaceStudioDesignTokens.textSecondary,
+            fontSize: 11,
+            fontWeight: FontWeight.w800,
+            height: 1.25,
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+String _formatColumns(List<int> columns) {
+  if (columns.isEmpty) {
+    return 'aucune';
+  }
+  if (columns.length == 1) {
+    return '${columns.first}';
+  }
+  return '${columns.first}–${columns.last}';
+}
+
+class _PartialPreviewBadge extends StatelessWidget {
+  const _PartialPreviewBadge();
+
+  @override
+  Widget build(BuildContext context) {
+    return DecoratedBox(
+      decoration: BoxDecoration(
+        color: SurfaceStudioDesignTokens.backgroundDeep.withValues(alpha: 0.82),
+        borderRadius: BorderRadius.circular(999),
+        border: Border.all(color: SurfaceStudioDesignTokens.accentTeal),
+      ),
+      child: const Padding(
+        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+        child: Text(
+          'Preview partielle : Plein(center)',
+          style: TextStyle(
+            color: SurfaceStudioDesignTokens.accentTeal,
+            fontSize: 11,
+            fontWeight: FontWeight.w800,
+          ),
+        ),
+      ),
+    );
+  }
+}
+
 class _PreviewControls extends StatelessWidget {
   const _PreviewControls({
     required this.frameCount,
@@ -489,56 +599,3 @@ class _CheckLine extends StatelessWidget {
     );
   }
 }
-
-class _WaterPreviewPainter extends CustomPainter {
-  const _WaterPreviewPainter({
-    required this.gridVisible,
-    required this.previewSize,
-  });
-
-  final bool gridVisible;
-  final int previewSize;
-
-  @override
-  void paint(Canvas canvas, Size size) {
-    final cellW = size.width / previewSize;
-    final cellH = size.height / previewSize;
-    final a = Paint()..color = const Color(0xFF1E89FF);
-    final b = Paint()..color = const Color(0xFF1268D9);
-    for (var y = 0; y < previewSize; y++) {
-      for (var x = 0; x < previewSize; x++) {
-        canvas.drawRect(
-          Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH),
-          (x + y).isEven ? a : b,
-        );
-      }
-    }
-    final wave = Paint()
-      ..color = const Color(0xFFA4E7FF).withValues(alpha: 0.26)
-      ..style = PaintingStyle.stroke
-      ..strokeWidth = 1.3;
-    for (var y = 8.0; y < size.height; y += 24) {
-      final path = Path()..moveTo(0, y);
-      for (var x = 0.0; x <= size.width; x += 22) {
-        path.quadraticBezierTo(x + 11, y - 7, x + 22, y);
-      }
-      canvas.drawPath(path, wave);
-    }
-    if (gridVisible) {
-      final grid = Paint()
-        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.16)
-        ..strokeWidth = 1;
-      for (var i = 0; i <= previewSize; i++) {
-        final x = i * cellW;
-        final y = i * cellH;
-        canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
-        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
-      }
-    }
-  }
-
-  @override
-  bool shouldRepaint(covariant _WaterPreviewPainter oldDelegate) =>
-      oldDelegate.gridVisible != gridVisible ||
-      oldDelegate.previewSize != previewSize;
-}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart
index af35bb48..18dbd36f 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart
@@ -1,43 +1,160 @@
-import 'package:map_core/map_core.dart';
+import 'surface_studio_mistral_vision_pack.dart';
+
+const surfaceStudioMistralAllowedRoleNames = <String>[
+  'isolated',
+  'endNorth',
+  'endEast',
+  'endSouth',
+  'endWest',
+  'horizontal',
+  'vertical',
+  'cornerNW',
+  'cornerNE',
+  'cornerSW',
+  'cornerSE',
+  'innerCornerNW',
+  'innerCornerNE',
+  'innerCornerSW',
+  'innerCornerSE',
+  'teeNorth',
+  'teeEast',
+  'teeSouth',
+  'teeWest',
+  'cross',
+];
+
+const surfaceStudioMistralRoleLabelMap = <String, String>{
+  'Plein(center)': 'isolated',
+  'Bord haut': 'endNorth',
+  'Bord droit': 'endEast',
+  'Bord bas': 'endSouth',
+  'Bord gauche': 'endWest',
+  'Horizontal': 'horizontal',
+  'Vertical': 'vertical',
+  'Coin haut gauche': 'cornerNW',
+  'Coin haut droit': 'cornerNE',
+  'Coin bas gauche': 'cornerSW',
+  'Coin bas droit': 'cornerSE',
+  'Coin int. haut gauche': 'innerCornerNW',
+  'Coin int. haut droit': 'innerCornerNE',
+  'Coin int. bas gauche': 'innerCornerSW',
+  'Coin int. bas droit': 'innerCornerSE',
+  'Té haut': 'teeNorth',
+  'Té droit': 'teeEast',
+  'Té bas': 'teeSouth',
+  'Té gauche': 'teeWest',
+  'Croix': 'cross',
+};
 
 String buildSurfaceStudioMappingSuggestionPrompt({
   required int tileWidth,
   required int tileHeight,
   required int columnCount,
   required int frameCount,
+  List<SurfaceStudioColumnVisualDescriptor> columnDescriptors =
+      const <SurfaceStudioColumnVisualDescriptor>[],
 }) {
-  final roles =
-      standardSurfaceVariantRoleOrder.map((role) => role.name).join(', ');
+  final roles = surfaceStudioMistralAllowedRoleNames.join(', ');
+  final roleLabels = surfaceStudioMistralRoleLabelMap.entries
+      .map((entry) => '- ${entry.key} = ${entry.value}')
+      .join('\n');
+  final descriptors = columnDescriptors.isEmpty
+      ? '[]'
+      : surfaceStudioColumnDescriptorsJson(columnDescriptors);
   return '''
-You are helping map a Pokemon-style surface atlas.
-Return JSON only. No markdown. No prose outside JSON.
+You are analyzing a Pokémon-like animated surface atlas for a no-code map editor.
+Take your time internally.
+Use high-effort visual reasoning.
+Inspect the column contact sheet first.
+Do not rush.
+Do not guess.
+Do not guess when uncertain.
+Prefer abstaining over wrong mappings.
+Only assign roles when visual evidence is strong.
+Return JSON only.
+Return valid JSON only. No markdown. No prose outside JSON. Do not expose chain-of-thought.
+
+You receive three images:
+1. Original atlas image.
+2. Annotated atlas image with grid and readable 1-based column numbers.
+3. Column contact sheet. The column contact sheet is the priority image for identification.
+
+Inspect the atlas as a grid:
+- columns are visual variants
+- rows are animation frames
+- Columns are 1-based in this UI
+- tileWidth: $tileWidth
+- tileHeight: $tileHeight
+- columns: $columnCount
+- frames: $frameCount
+- every role must map to existing columns only
+
+Your task:
+Assign atlas columns to surface autotile roles.
+
+Allowed technical roles, in canonical order:
+$roles
+
+French UI label to technical role mapping:
+$roleLabels
+
+Visual guidance:
+- A bright or pink guide column may be a border, not necessarily center.
+- Repeated water-only columns are likely center/isolated.
+- Shoreline strips indicate borders.
+- L-shaped shorelines indicate external corners.
+- Inner L-shaped cutouts indicate inner corners.
+- T shapes indicate junctions.
+- Cross shapes indicate cross junction.
+- If uncertain, leave the role empty and add a warning.
+- Prefer fewer high-confidence mappings over many guesses.
+- If the atlas only contains center/water fill columns without clear borders, leave border/corner roles empty.
+- Never map likelyEmpty columns.
 
-Expected schema:
+Local column descriptors from deterministic analysis:
+$descriptors
+
+Validation rules:
+- All column numbers must be between 1 and $columnCount.
+- isolated may contain multiple columns.
+- All other roles must contain at most one column.
+- Do not invent roles.
+- Never map columns marked likelyEmpty by the local descriptors.
+- confidence must be exactly high, medium, or low.
+- reason must be a short string for each assignment.
+- evidenceColumns must be inside the atlas bounds.
+- rejectedColumns must be inside the atlas bounds.
+- warnings must be strings and should explain ambiguity.
+
+Before producing JSON, internally verify:
+1. All column numbers are within range.
+2. isolated/center may contain multiple columns.
+3. All other roles contain at most one column.
+4. No role is invented.
+5. likelyEmpty columns are not mapped.
+6. Warnings explain ambiguity.
+7. Output is valid JSON only.
+
+Expected JSON schema:
 {
   "assignments": [
     {
       "role": "isolated",
       "columns": [4, 5],
-      "confidence": "medium",
-      "reason": "Columns 4 and 5 look like repeatable center water tiles."
+      "confidence": "high",
+      "evidenceColumns": [4, 5],
+      "reason": "Columns 4 and 5 are full water tiles without shoreline and can repeat as center variants."
+    }
+  ],
+  "rejectedColumns": [
+    {
+      "column": 3,
+      "reason": "Likely empty or insufficient visual evidence."
     }
   ],
-  "warnings": ["Inner corners are ambiguous."]
+  "warnings": [
+    "Inner corners are not confidently visible."
+  ]
 }
-
-Atlas metadata:
-- tileWidth: $tileWidth
-- tileHeight: $tileHeight
-- columns: $columnCount
-- frames: $frameCount
-- allowedRoles: $roles
-
-Rules:
-- Use only allowed role names.
-- Columns are 1-based and must be between 1 and $columnCount.
-- isolated may use multiple columns.
-- Every other role must use at most one column.
-- confidence must be high, medium, or low.
-- Provide a short reason for each assignment.
 ''';
 }
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
index edbcce12..8c53cc31 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
@@ -3,19 +3,19 @@ import 'dart:convert';
 import 'dart:typed_data';
 
 import 'package:http/http.dart' as http;
-import 'package:image/image.dart' as img;
 import 'package:map_core/map_core.dart';
 
 import 'surface_studio_ai_mapping_suggester.dart';
 import 'surface_studio_mapping_suggestion_models.dart';
 import 'surface_studio_mapping_suggestion_prompt_builder.dart';
+import 'surface_studio_mistral_vision_pack.dart';
 
 final class SurfaceStudioMistralMappingSuggester
     implements SurfaceStudioAiMappingSuggester {
   SurfaceStudioMistralMappingSuggester({
     http.Client? httpClient,
     this.baseUrl = 'https://api.mistral.ai/v1/chat/completions',
-    this.model = 'mistral-small-2506',
+    this.model = 'mistral-small-latest',
     this.timeout = const Duration(seconds: 30),
   }) : _client = httpClient ?? http.Client();
 
@@ -42,23 +42,42 @@ final class SurfaceStudioMistralMappingSuggester
       );
     }
 
+    final visionPack = buildSurfaceStudioMistralVisionPack(
+      imageBytes: imageBytes,
+      tileWidth: tileWidth,
+      tileHeight: tileHeight,
+      columnCount: columnCount,
+      frameCount: frameCount,
+    );
     final prompt = buildSurfaceStudioMappingSuggestionPrompt(
       tileWidth: tileWidth,
       tileHeight: tileHeight,
       columnCount: columnCount,
       frameCount: frameCount,
+      columnDescriptors: visionPack.columnDescriptors,
     );
-    final imageDataUrl = _imageDataUrl(imageBytes);
     final body = jsonEncode({
       'model': model,
-      'temperature': 0,
-      'response_format': {'type': 'json_object'},
+      'temperature': 0.1,
+      'reasoning_effort': 'high',
+      'response_format': _jsonSchemaResponseFormat(),
       'messages': [
         {
           'role': 'user',
           'content': [
             {'type': 'text', 'text': prompt},
-            {'type': 'image_url', 'image_url': imageDataUrl},
+            {
+              'type': 'image_url',
+              'image_url': visionPack.originalAtlasDataUrl,
+            },
+            {
+              'type': 'image_url',
+              'image_url': visionPack.annotatedAtlasDataUrl,
+            },
+            {
+              'type': 'image_url',
+              'image_url': visionPack.columnContactSheetDataUrl,
+            },
           ],
         },
       ],
@@ -85,6 +104,7 @@ final class SurfaceStudioMistralMappingSuggester
       return _parseChatResponse(
         response.body,
         columnCount: columnCount,
+        columnDescriptors: visionPack.columnDescriptors,
       );
     } on TimeoutException {
       return const SurfaceStudioMappingSuggestionResult(
@@ -101,31 +121,76 @@ final class SurfaceStudioMistralMappingSuggester
     }
   }
 
-  String _imageDataUrl(Uint8List bytes) {
-    img.Image? decoded;
-    try {
-      decoded = img.decodeImage(bytes);
-    } catch (_) {
-      decoded = null;
-    }
-    if (decoded == null) {
-      return 'data:image/png;base64,${base64Encode(bytes)}';
-    }
-    final longest =
-        decoded.width > decoded.height ? decoded.width : decoded.height;
-    final normalized = longest > 768
-        ? img.copyResize(
-            decoded,
-            width: decoded.width >= decoded.height ? 768 : null,
-            height: decoded.height > decoded.width ? 768 : null,
-          )
-        : decoded;
-    return 'data:image/png;base64,${base64Encode(img.encodePng(normalized))}';
+  Map<String, Object?> _jsonSchemaResponseFormat() {
+    return {
+      'type': 'json_schema',
+      'json_schema': {
+        'name': 'surface_studio_mapping_suggestion',
+        'strict': true,
+        'schema': {
+          'type': 'object',
+          'additionalProperties': false,
+          'required': ['assignments', 'rejectedColumns', 'warnings'],
+          'properties': {
+            'assignments': {
+              'type': 'array',
+              'items': {
+                'type': 'object',
+                'additionalProperties': false,
+                'required': [
+                  'role',
+                  'columns',
+                  'confidence',
+                  'evidenceColumns',
+                  'reason',
+                ],
+                'properties': {
+                  'role': {
+                    'type': 'string',
+                    'enum': surfaceStudioMistralAllowedRoleNames,
+                  },
+                  'columns': {
+                    'type': 'array',
+                    'items': {'type': 'integer'},
+                  },
+                  'confidence': {
+                    'type': 'string',
+                    'enum': ['high', 'medium', 'low'],
+                  },
+                  'evidenceColumns': {
+                    'type': 'array',
+                    'items': {'type': 'integer'},
+                  },
+                  'reason': {'type': 'string'},
+                },
+              },
+            },
+            'rejectedColumns': {
+              'type': 'array',
+              'items': {
+                'type': 'object',
+                'additionalProperties': false,
+                'required': ['column', 'reason'],
+                'properties': {
+                  'column': {'type': 'integer'},
+                  'reason': {'type': 'string'},
+                },
+              },
+            },
+            'warnings': {
+              'type': 'array',
+              'items': {'type': 'string'},
+            },
+          },
+        },
+      },
+    };
   }
 
   SurfaceStudioMappingSuggestionResult _parseChatResponse(
     String body, {
     required int columnCount,
+    required List<SurfaceStudioColumnVisualDescriptor> columnDescriptors,
   }) {
     try {
       final decoded = jsonDecode(body);
@@ -152,7 +217,11 @@ final class SurfaceStudioMistralMappingSuggester
       if (payload is! Map<String, dynamic>) {
         throw const FormatException('payload');
       }
-      return _parsePayload(payload, columnCount: columnCount);
+      return _parsePayload(
+        payload,
+        columnCount: columnCount,
+        columnDescriptors: columnDescriptors,
+      );
     } catch (e) {
       return SurfaceStudioMappingSuggestionResult(
         suggestions: const <SurfaceStudioRoleSuggestion>[],
@@ -165,8 +234,16 @@ final class SurfaceStudioMistralMappingSuggester
   SurfaceStudioMappingSuggestionResult _parsePayload(
     Map<String, dynamic> payload, {
     required int columnCount,
+    required List<SurfaceStudioColumnVisualDescriptor> columnDescriptors,
   }) {
     final warnings = <String>[];
+    final descriptorsByColumn = <int, SurfaceStudioColumnVisualDescriptor>{
+      for (final descriptor in columnDescriptors) descriptor.column: descriptor,
+    };
+    final likelyEmptyColumns = descriptorsByColumn.values
+        .where((descriptor) => descriptor.likelyEmpty)
+        .map((descriptor) => descriptor.column)
+        .toSet();
     final rawWarnings = payload['warnings'];
     if (rawWarnings is List) {
       for (final warning in rawWarnings) {
@@ -175,6 +252,25 @@ final class SurfaceStudioMistralMappingSuggester
         }
       }
     }
+    final rejectedColumns = payload['rejectedColumns'];
+    if (rejectedColumns is List) {
+      for (final rejected in rejectedColumns) {
+        if (rejected is! Map<String, dynamic>) {
+          warnings.add('Colonne rejetée Mistral non objet ignorée.');
+          continue;
+        }
+        final column = rejected['column'];
+        final reason = rejected['reason'];
+        if (column is! int || column < 1 || column > columnCount) {
+          warnings.add('Colonne rejetée Mistral hors bornes ignorée.');
+          continue;
+        }
+        if (reason is String && reason.trim().isNotEmpty) {
+          warnings
+              .add('Mistral a rejeté la colonne $column : ${reason.trim()}');
+        }
+      }
+    }
 
     final suggestions = <SurfaceStudioRoleSuggestion>[];
     final assignments = payload['assignments'];
@@ -212,17 +308,56 @@ final class SurfaceStudioMistralMappingSuggester
         );
         continue;
       }
+      int? emptyColumn;
+      for (final column in columns) {
+        if (likelyEmptyColumns.contains(column)) {
+          emptyColumn = column;
+          break;
+        }
+      }
+      if (emptyColumn != null) {
+        warnings.add(
+          'Suggestion Mistral sur colonne likelyEmpty rejetée pour $roleName : $emptyColumn.',
+        );
+        continue;
+      }
       if (role != SurfaceVariantRole.isolated && columns.length > 1) {
         warnings
             .add('Suggestion Mistral multi-colonnes rejetée pour $roleName.');
         continue;
       }
+      final evidenceColumns = _parseColumns(item['evidenceColumns']);
+      if (evidenceColumns.isEmpty) {
+        warnings.add(
+            'Suggestion Mistral sans evidenceColumns rejetée pour $roleName.');
+        continue;
+      }
+      final evidenceOutOfRange = evidenceColumns.where(
+        (column) => column < 1 || column > columnCount,
+      );
+      if (evidenceOutOfRange.isNotEmpty) {
+        warnings.add(
+          'Evidence Mistral hors bornes rejetée pour $roleName : ${evidenceOutOfRange.first}.',
+        );
+        continue;
+      }
       final confidence = _confidenceFromName(item['confidence']);
       if (confidence == null) {
         warnings.add('Confiance Mistral inconnue rejetée pour $roleName.');
         continue;
       }
       final reason = item['reason'];
+      for (final column in columns) {
+        final descriptor = descriptorsByColumn[column];
+        if (descriptor == null) {
+          continue;
+        }
+        if (!descriptor.localCandidateRoles.contains(role.name)) {
+          warnings.add(
+            'Mistral contredit l’analyse locale pour ${role.name} colonne $column.',
+          );
+        }
+      }
       suggestions.add(
         SurfaceStudioRoleSuggestion(
           role: role,
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
index ecfb349c..5a524122 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
@@ -95,6 +95,7 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
   bool _aiConfirmationOpen = false;
   bool _mergeAiAfterConfirmation = false;
   bool _suggestionRunning = false;
+  String? _mistralProgressMessage;
   Set<String> _openSchemaGroups = const {
     'surfaceMain',
     'edges',
@@ -538,6 +539,7 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
       _suggestionResult = result;
       _suggestionReviewOpen = openReview || _suggestionReviewOpen;
       _aiConfirmationOpen = false;
+      _mistralProgressMessage = null;
       _statusMessage =
           'Suggestions locales prêtes — validation utilisateur requise.';
     });
@@ -548,6 +550,7 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
       _suggestionReviewOpen = true;
       _aiConfirmationOpen = true;
       _mergeAiAfterConfirmation = mergeWithLocal;
+      _mistralProgressMessage = null;
       _statusMessage = 'Confirmation IA requise avant envoi.';
     });
   }
@@ -559,6 +562,7 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
     if (!hasApiKey || imageBytes == null) {
       setState(() {
         _aiConfirmationOpen = false;
+        _mistralProgressMessage = null;
         _suggestionResult = SurfaceStudioMappingSuggestionResult(
           suggestions: _suggestionResult?.suggestions ??
               const <SurfaceStudioRoleSuggestion>[],
@@ -576,19 +580,39 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
     setState(() {
       _suggestionRunning = true;
       _aiConfirmationOpen = false;
+      _mistralProgressMessage = 'Analyse visuelle approfondie…';
     });
     final aiController = SurfaceStudioMappingSuggestionController(
       aiSuggester:
           widget.aiMappingSuggester ?? SurfaceStudioMistralMappingSuggester(),
     );
-    final ai = await aiController.suggestMistral(
-      apiKey: apiKey,
-      imageBytes: imageBytes,
-      tileWidth: _tileWidthValue,
-      tileHeight: _tileHeightValue,
-      columnCount: _columnCount,
-      frameCount: _frameCount,
-    );
+    late final SurfaceStudioMappingSuggestionResult ai;
+    try {
+      ai = await aiController.suggestMistral(
+        apiKey: apiKey,
+        imageBytes: imageBytes,
+        tileWidth: _tileWidthValue,
+        tileHeight: _tileHeightValue,
+        columnCount: _columnCount,
+        frameCount: _frameCount,
+      );
+    } on TimeoutException {
+      ai = const SurfaceStudioMappingSuggestionResult(
+        suggestions: <SurfaceStudioRoleSuggestion>[],
+        warnings: <String>[
+          'Mistral n’a pas répondu à temps. Aucune modification n’a été appliquée.',
+        ],
+        source: SurfaceStudioMappingSuggestionSource.mistral,
+      );
+    } catch (_) {
+      ai = const SurfaceStudioMappingSuggestionResult(
+        suggestions: <SurfaceStudioRoleSuggestion>[],
+        warnings: <String>[
+          'Analyse Mistral impossible. Aucune modification n’a été appliquée.',
+        ],
+        source: SurfaceStudioMappingSuggestionSource.mistral,
+      );
+    }
     if (!mounted) {
       return;
     }
@@ -607,6 +631,7 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
         : ai;
     setState(() {
       _suggestionRunning = false;
+      _mistralProgressMessage = null;
       _suggestionResult = result;
       _suggestionReviewOpen = true;
       _statusMessage =
@@ -632,6 +657,29 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
     });
   }
 
+  void _applySingleSuggestion(SurfaceStudioRoleSuggestion suggestion) {
+    setState(() {
+      _assignmentDraft =
+          _assignmentDraft.assignColumns(suggestion.role, suggestion.columns);
+      _statusMessage = 'Suggestion appliquée au mapping de travail.';
+    });
+  }
+
+  void _useSelectionAsCenter() {
+    final columns = _selectedColumns.columns;
+    if (columns.isEmpty) {
+      setState(() {
+        _statusMessage = 'Sélectionnez au moins une colonne à assigner.';
+      });
+      return;
+    }
+    setState(() {
+      _assignmentDraft =
+          _assignmentDraft.assignColumns(SurfaceVariantRole.isolated, columns);
+      _statusMessage = 'Colonnes sélectionnées assignées à Plein(center).';
+    });
+  }
+
   void _applyMapping() {
     setState(() {
       _statusMessage =
@@ -823,10 +871,12 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
                   hasEditorMistralApiKey(widget.projectSettings),
               aiConfirmationOpen: _aiConfirmationOpen,
               running: _suggestionRunning,
+              progressMessage: _mistralProgressMessage,
               onCancel: () {
                 setState(() {
                   _suggestionReviewOpen = false;
                   _aiConfirmationOpen = false;
+                  _mistralProgressMessage = null;
                 });
               },
               onRunLocal: () => _runLocalSuggestion(),
@@ -836,6 +886,7 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
                 mergeWithLocal: _mergeAiAfterConfirmation,
               ),
               onCompare: () => _requestAiSuggestion(mergeWithLocal: true),
+              onApplySuggestion: _applySingleSuggestion,
               onApplyReliable: () => _applySuggestions(reliableOnly: true),
               onApplyAll: () => _applySuggestions(reliableOnly: false),
             ),
@@ -912,10 +963,15 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
               ? 'Image source indisponible — aperçu illustratif.'
               : null,
           selection: _selectedColumns,
+          centerAssigned:
+              _assignmentDraft.isAssigned(SurfaceVariantRole.isolated),
+          centerColumns:
+              _assignmentDraft.columnsForRole(SurfaceVariantRole.isolated),
           zoomPercent: _zoomPercent,
           onColumnSelectionChanged: (selection) {
             setState(() => _selectedColumns = selection);
           },
+          onUseSelectionAsCenter: _useSelectionAsCenter,
           onZoomChanged: (value) {
             setState(() => _zoomPercent = value.clamp(25, 400).toDouble());
           },
@@ -967,6 +1023,9 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
             loop: _previewLoop,
             gridVisible: _previewGridVisible,
             previewSize: _previewSize,
+            tileWidth: _tileWidthValue,
+            tileHeight: _tileHeightValue,
+            columnCount: _columnCount,
             assignmentDraft: _assignmentDraft,
             atlasImageBytes: _atlasImageBytes(),
             atlasFallbackMessage: _atlasImageBytes() == null
@@ -1066,6 +1125,9 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
             loop: _previewLoop,
             gridVisible: _previewGridVisible,
             previewSize: _previewSize,
+            tileWidth: _tileWidthValue,
+            tileHeight: _tileHeightValue,
+            columnCount: _columnCount,
             assignmentDraft: _assignmentDraft,
             atlasImageBytes: _atlasImageBytes(),
             atlasFallbackMessage: _atlasImageBytes() == null
@@ -1845,12 +1907,14 @@ class _SuggestionReviewScrim extends StatelessWidget {
     required this.mistralKeyConfigured,
     required this.aiConfirmationOpen,
     required this.running,
+    required this.progressMessage,
     required this.onCancel,
     required this.onRunLocal,
     required this.onRequestAi,
     required this.onCancelAi,
     required this.onConfirmAi,
     required this.onCompare,
+    required this.onApplySuggestion,
     required this.onApplyReliable,
     required this.onApplyAll,
   });
@@ -1859,12 +1923,14 @@ class _SuggestionReviewScrim extends StatelessWidget {
   final bool mistralKeyConfigured;
   final bool aiConfirmationOpen;
   final bool running;
+  final String? progressMessage;
   final VoidCallback onCancel;
   final VoidCallback onRunLocal;
   final VoidCallback onRequestAi;
   final VoidCallback onCancelAi;
   final VoidCallback onConfirmAi;
   final VoidCallback onCompare;
+  final ValueChanged<SurfaceStudioRoleSuggestion> onApplySuggestion;
   final VoidCallback onApplyReliable;
   final VoidCallback onApplyAll;
 
@@ -1913,7 +1979,10 @@ class _SuggestionReviewScrim extends StatelessWidget {
                       const SizedBox(height: 8),
                     ],
                     for (final suggestion in result.suggestions)
-                      _SuggestionRow(suggestion: suggestion),
+                      _SuggestionRow(
+                        suggestion: suggestion,
+                        onApply: () => onApplySuggestion(suggestion),
+                      ),
                     const SizedBox(height: 12),
                     Container(
                       padding: const EdgeInsets.all(12),
@@ -1952,6 +2021,59 @@ class _SuggestionReviewScrim extends StatelessWidget {
                               height: 1.3,
                             ),
                           ),
+                          if (running) ...[
+                            const SizedBox(height: 10),
+                            Container(
+                              key: const ValueKey(
+                                'surfaceStudio.suggestion.mistralProgress',
+                              ),
+                              padding: const EdgeInsets.all(10),
+                              decoration: BoxDecoration(
+                                color: SurfaceStudioDesignTokens.backgroundDeep,
+                                borderRadius: BorderRadius.circular(10),
+                                border: Border.all(
+                                  color:
+                                      SurfaceStudioDesignTokens.accentGoldSoft,
+                                ),
+                              ),
+                              child: Row(
+                                crossAxisAlignment: CrossAxisAlignment.start,
+                                children: [
+                                  const CupertinoActivityIndicator(radius: 10),
+                                  const SizedBox(width: 10),
+                                  Expanded(
+                                    child: Column(
+                                      crossAxisAlignment:
+                                          CrossAxisAlignment.start,
+                                      children: [
+                                        const Text(
+                                          'Mistral analyse l’atlas avec un niveau de réflexion élevé. Cela peut prendre quelques secondes.',
+                                          style: TextStyle(
+                                            color: SurfaceStudioDesignTokens
+                                                .textSecondary,
+                                            fontSize: 12,
+                                            fontWeight: FontWeight.w800,
+                                            height: 1.3,
+                                          ),
+                                        ),
+                                        const SizedBox(height: 4),
+                                        Text(
+                                          progressMessage ??
+                                              'Analyse visuelle approfondie…',
+                                          style: const TextStyle(
+                                            color: SurfaceStudioDesignTokens
+                                                .accentGold,
+                                            fontSize: 12,
+                                            fontWeight: FontWeight.w900,
+                                          ),
+                                        ),
+                                      ],
+                                    ),
+                                  ),
+                                ],
+                              ),
+                            ),
+                          ],
                           const SizedBox(height: 8),
                           Wrap(
                             spacing: 8,
@@ -2077,9 +2199,13 @@ class _SuggestionReviewScrim extends StatelessWidget {
 }
 
 class _SuggestionRow extends StatelessWidget {
-  const _SuggestionRow({required this.suggestion});
+  const _SuggestionRow({
+    required this.suggestion,
+    required this.onApply,
+  });
 
   final SurfaceStudioRoleSuggestion suggestion;
+  final VoidCallback onApply;
 
   @override
   Widget build(BuildContext context) {
@@ -2117,6 +2243,19 @@ class _SuggestionRow extends StatelessWidget {
               height: 1.3,
             ),
           ),
+          const SizedBox(height: 8),
+          Align(
+            alignment: Alignment.centerRight,
+            child: CupertinoButton(
+              key: ValueKey(
+                'surfaceStudio.suggestion.accept.${suggestion.role.name}',
+              ),
+              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
+              color: SurfaceStudioDesignTokens.accentTealSoft,
+              onPressed: onApply,
+              child: const Text('Accepter'),
+            ),
+          ),
         ],
       ),
     );
```

### packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart b/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
index f3f84ab3..ee1029e1 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
@@ -1,10 +1,12 @@
 import 'dart:convert';
+import 'dart:io';
 import 'dart:typed_data';
 
 import 'package:flutter/widgets.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:http/http.dart' as http;
 import 'package:http/testing.dart';
+import 'package:image/image.dart' as img;
 import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_local_mapping_suggester.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart';
@@ -103,6 +105,74 @@ void main() {
     expect(fakeAi.calls, 0);
   });
 
+  testWidgets('accepted Mistral suggestion updates mapping and live preview',
+      (tester) async {
+    final temp =
+        Directory.systemTemp.createTempSync('surface_mistral_preview_');
+    addTearDown(() => temp.deleteSync(recursive: true));
+    final image = File('${temp.path}/tiles/water.png');
+    image.parent.createSync(recursive: true);
+    image.writeAsBytesSync(_atlasBytes());
+    final fakeAi = _FakeAiSuggester();
+
+    await pumpSurfaceStudioForTest(
+      tester,
+      readModel: _readModel(),
+      projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
+      projectTilesets: const <ProjectTilesetEntry>[
+        ProjectTilesetEntry(
+          id: 'water_tiles',
+          name: 'Water Tiles',
+          relativePath: 'tiles/water.png',
+          sortOrder: 0,
+        ),
+      ],
+      projectRootPath: temp.path,
+      aiMappingSuggester: fakeAi,
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.textContaining('Assignez au moins le rôle'), findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
+        findsNothing);
+
+    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
+    await tester.pumpAndSettle();
+    final mistralButton =
+        find.byKey(const Key('surfaceStudio.suggestion.mistral'));
+    await tester.ensureVisible(mistralButton);
+    await tester.tap(mistralButton);
+    await tester.pumpAndSettle();
+    expect(find.text('Confirmer l’analyse IA'), findsOneWidget);
+    expect(fakeAi.calls, 0);
+
+    final confirmButton =
+        find.byKey(const Key('surfaceStudio.suggestion.confirmAi'));
+    await tester.ensureVisible(confirmButton);
+    await tester.tap(confirmButton);
+    await tester.pumpAndSettle();
+    expect(fakeAi.calls, 1);
+    expect(find.text('AI center'), findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
+        findsNothing);
+
+    final acceptButton =
+        find.byKey(const Key('surfaceStudio.suggestion.accept.isolated'));
+    await tester.ensureVisible(acceptButton);
+    await tester.tap(acceptButton);
+    await tester.pumpAndSettle();
+
+    expect(find.textContaining('Assignez au moins le rôle'), findsNothing);
+    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
+        findsOneWidget);
+    final centerSlot =
+        find.byKey(const Key('surfaceStudio.schema.role.center'));
+    expect(find.descendant(of: centerSlot, matching: find.text('4')),
+        findsOneWidget);
+    expect(find.descendant(of: centerSlot, matching: find.text('5')),
+        findsOneWidget);
+  });
+
   test('Mistral suggester validates JSON without leaking secrets', () async {
     final requests = <http.Request>[];
     final suggester = SurfaceStudioMistralMappingSuggester(
@@ -121,27 +191,32 @@ void main() {
                         'role': 'isolated',
                         'columns': [4, 5],
                         'confidence': 'medium',
+                        'evidenceColumns': [4, 5],
                         'reason': 'Center water candidates.',
                       },
                       {
                         'role': 'endNorth',
                         'columns': [99],
                         'confidence': 'high',
+                        'evidenceColumns': [99],
                         'reason': 'Out of range.',
                       },
                       {
                         'role': 'endEast',
                         'columns': [1, 2],
                         'confidence': 'high',
+                        'evidenceColumns': [1, 2],
                         'reason': 'Too many columns.',
                       },
                       {
                         'role': 'unknown',
                         'columns': [3],
                         'confidence': 'high',
+                        'evidenceColumns': [3],
                         'reason': 'Unknown role.',
                       },
                     ],
+                    'rejectedColumns': const [],
                     'warnings': ['Inner corners are ambiguous.'],
                   }),
                 },
@@ -210,6 +285,54 @@ void main() {
     expect(result.suggestions, isEmpty);
     expect(result.warnings.single, contains('Réponse Mistral invalide'));
   });
+
+  test('Mistral suggester rejects locally likelyEmpty columns', () async {
+    final suggester = SurfaceStudioMistralMappingSuggester(
+      httpClient: MockClient((_) async {
+        return http.Response(
+          jsonEncode({
+            'choices': [
+              {
+                'message': {
+                  'content': jsonEncode({
+                    'assignments': [
+                      {
+                        'role': 'isolated',
+                        'columns': [3],
+                        'confidence': 'high',
+                        'evidenceColumns': [3],
+                        'reason': 'Looks empty but claimed as center.',
+                      },
+                    ],
+                    'rejectedColumns': const [],
+                    'warnings': const [],
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
+      imageBytes: _atlasBytesWithEmptyColumn(),
+      tileWidth: 8,
+      tileHeight: 8,
+      columnCount: 4,
+      frameCount: 2,
+    );
+
+    expect(result.suggestions, isEmpty);
+    expect(
+      result.warnings,
+      contains(
+        'Suggestion Mistral sur colonne likelyEmpty rejetée pour isolated : 3.',
+      ),
+    );
+  });
 }
 
 final class _FakeAiSuggester implements SurfaceStudioAiMappingSuggester {
@@ -242,3 +365,69 @@ final class _FakeAiSuggester implements SurfaceStudioAiMappingSuggester {
     );
   }
 }
+
+SurfaceStudioReadModel _readModel() {
+  const atlasId = 'water-atlas';
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[
+        ProjectSurfaceAtlas(
+          id: atlasId,
+          name: 'Water Atlas',
+          tilesetId: 'water_tiles',
+          geometry: SurfaceAtlasGeometry(
+            tileSize: SurfaceAtlasTileSize(width: 8, height: 8),
+            gridSize: SurfaceAtlasGridSize(columns: 5, rows: 2),
+            layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+          ),
+        ),
+      ],
+      animations: const <ProjectSurfaceAnimation>[],
+      presets: const <ProjectSurfacePreset>[],
+    ),
+  );
+}
+
+Uint8List _atlasBytes() {
+  const tile = 8;
+  const columns = 5;
+  const frames = 2;
+  final image = img.Image(width: columns * tile, height: frames * tile);
+  for (var frame = 0; frame < frames; frame++) {
+    for (var column = 0; column < columns; column++) {
+      img.fillRect(
+        image,
+        x1: column * tile,
+        y1: frame * tile,
+        x2: column * tile + tile - 1,
+        y2: frame * tile + tile - 1,
+        color: img.ColorRgb8(40 + column * 32, 80 + frame * 70, 180),
+      );
+    }
+  }
+  return Uint8List.fromList(img.encodePng(image));
+}
+
+Uint8List _atlasBytesWithEmptyColumn() {
+  const tile = 8;
+  const columns = 4;
+  const frames = 2;
+  final image = img.Image(width: columns * tile, height: frames * tile);
+  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
+  for (var frame = 0; frame < frames; frame++) {
+    for (var column = 0; column < columns; column++) {
+      if (column == 2) {
+        continue;
+      }
+      img.fillRect(
+        image,
+        x1: column * tile,
+        y1: frame * tile,
+        x2: column * tile + tile - 1,
+        y2: frame * tile + tile - 1,
+        color: img.ColorRgba8(40 + column * 30, 100, 180, 255),
+      );
+    }
+  }
+  return Uint8List.fromList(img.encodePng(image));
+}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_view_geometry.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_view_geometry.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_view_geometry.dart
new file mode 100644
index 00000000..fa681171
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_view_geometry.dart
@@ -0,0 +1,130 @@
+import 'dart:ui';
+
+final class SurfaceStudioAtlasViewGeometry {
+  const SurfaceStudioAtlasViewGeometry({
+    required this.viewportSize,
+    required this.imagePixelSize,
+    required this.fittedImageRect,
+    required this.tileWidth,
+    required this.tileHeight,
+    required this.columnCount,
+    required this.frameCount,
+  });
+
+  factory SurfaceStudioAtlasViewGeometry.fromContain({
+    required Size viewportSize,
+    required Size imagePixelSize,
+    required int tileWidth,
+    required int tileHeight,
+    required int columnCount,
+    required int frameCount,
+  }) {
+    return SurfaceStudioAtlasViewGeometry(
+      viewportSize: viewportSize,
+      imagePixelSize: imagePixelSize,
+      fittedImageRect: computeSurfaceStudioContainedImageRect(
+        viewportSize: viewportSize,
+        imagePixelSize: imagePixelSize,
+      ),
+      tileWidth: tileWidth,
+      tileHeight: tileHeight,
+      columnCount: columnCount,
+      frameCount: frameCount,
+    );
+  }
+
+  final Size viewportSize;
+  final Size imagePixelSize;
+  final Rect fittedImageRect;
+  final int tileWidth;
+  final int tileHeight;
+  final int columnCount;
+  final int frameCount;
+}
+
+Rect computeSurfaceStudioContainedImageRect({
+  required Size viewportSize,
+  required Size imagePixelSize,
+}) {
+  if (viewportSize.width <= 0 ||
+      viewportSize.height <= 0 ||
+      imagePixelSize.width <= 0 ||
+      imagePixelSize.height <= 0) {
+    return Offset.zero & Size.zero;
+  }
+  final scale = (viewportSize.width / imagePixelSize.width) <
+          (viewportSize.height / imagePixelSize.height)
+      ? viewportSize.width / imagePixelSize.width
+      : viewportSize.height / imagePixelSize.height;
+  final fittedSize = Size(
+    imagePixelSize.width * scale,
+    imagePixelSize.height * scale,
+  );
+  return Rect.fromLTWH(
+    (viewportSize.width - fittedSize.width) / 2,
+    (viewportSize.height - fittedSize.height) / 2,
+    fittedSize.width,
+    fittedSize.height,
+  );
+}
+
+int? surfaceStudioColumnAtViewportOffset({
+  required Offset localPosition,
+  required SurfaceStudioAtlasViewGeometry geometry,
+}) {
+  final rect = geometry.fittedImageRect;
+  if (!rect.contains(localPosition) || geometry.columnCount <= 0) {
+    return null;
+  }
+  final localX = localPosition.dx - rect.left;
+  final normalized = (localX / rect.width).clamp(0, 0.999999);
+  return (normalized * geometry.columnCount).floor() + 1;
+}
+
+int? surfaceStudioFrameAtViewportOffset({
+  required Offset localPosition,
+  required SurfaceStudioAtlasViewGeometry geometry,
+}) {
+  final rect = geometry.fittedImageRect;
+  if (!rect.contains(localPosition) || geometry.frameCount <= 0) {
+    return null;
+  }
+  final localY = localPosition.dy - rect.top;
+  final normalized = (localY / rect.height).clamp(0, 0.999999);
+  return (normalized * geometry.frameCount).floor() + 1;
+}
+
+Rect surfaceStudioColumnViewportRect({
+  required int uiColumn,
+  required SurfaceStudioAtlasViewGeometry geometry,
+}) {
+  final safeColumnCount = geometry.columnCount < 1 ? 1 : geometry.columnCount;
+  final column = uiColumn.clamp(1, safeColumnCount).toInt();
+  final width = geometry.fittedImageRect.width / safeColumnCount;
+  return Rect.fromLTWH(
+    geometry.fittedImageRect.left + (column - 1) * width,
+    geometry.fittedImageRect.top,
+    width,
+    geometry.fittedImageRect.height,
+  );
+}
+
+Rect surfaceStudioTileSourceRect({
+  required int uiColumn,
+  required int frameIndex,
+  required int tileWidth,
+  required int tileHeight,
+  required int columnCount,
+  required int frameCount,
+}) {
+  final safeColumnCount = columnCount < 1 ? 1 : columnCount;
+  final safeFrameCount = frameCount < 1 ? 1 : frameCount;
+  final column = uiColumn.clamp(1, safeColumnCount).toInt();
+  final frame = frameIndex.clamp(0, safeFrameCount - 1).toInt();
+  return Rect.fromLTWH(
+    (column - 1) * tileWidth.toDouble(),
+    frame * tileHeight.toDouble(),
+    tileWidth.toDouble(),
+    tileHeight.toDouble(),
+  );
+}
```

### packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart b/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart
new file mode 100644
index 00000000..a5b1a5e5
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart
@@ -0,0 +1,198 @@
+import 'dart:typed_data';
+import 'dart:ui' as ui;
+
+import 'package:flutter/widgets.dart';
+import 'package:map_core/map_core.dart';
+
+import '../surface_studio_design_tokens.dart';
+import '../surface_studio_atlas_view_geometry.dart';
+import '../surface_studio_role_assignment_draft.dart';
+
+export '../surface_studio_atlas_view_geometry.dart'
+    show surfaceStudioTileSourceRect;
+
+class SurfaceStudioSurfacePreviewRenderer extends StatefulWidget {
+  const SurfaceStudioSurfacePreviewRenderer({
+    super.key,
+    required this.atlasImageBytes,
+    required this.assignmentDraft,
+    required this.tileWidth,
+    required this.tileHeight,
+    required this.columnCount,
+    required this.frameCount,
+    required this.frameIndex,
+    required this.previewSize,
+    required this.gridVisible,
+  });
+
+  final Uint8List atlasImageBytes;
+  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
+  final int tileWidth;
+  final int tileHeight;
+  final int columnCount;
+  final int frameCount;
+  final int frameIndex;
+  final int previewSize;
+  final bool gridVisible;
+
+  @override
+  State<SurfaceStudioSurfacePreviewRenderer> createState() =>
+      _SurfaceStudioSurfacePreviewRendererState();
+}
+
+class _SurfaceStudioSurfacePreviewRendererState
+    extends State<SurfaceStudioSurfacePreviewRenderer> {
+  ui.Image? _image;
+  Object? _decodeToken;
+
+  @override
+  void initState() {
+    super.initState();
+    _decode();
+  }
+
+  @override
+  void didUpdateWidget(
+      covariant SurfaceStudioSurfacePreviewRenderer oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (oldWidget.atlasImageBytes != widget.atlasImageBytes) {
+      _image?.dispose();
+      _image = null;
+      _decode();
+    }
+  }
+
+  @override
+  void dispose() {
+    _image?.dispose();
+    super.dispose();
+  }
+
+  void _decode() {
+    final token = Object();
+    _decodeToken = token;
+    ui.decodeImageFromList(widget.atlasImageBytes, (image) {
+      if (!mounted || _decodeToken != token) {
+        image.dispose();
+        return;
+      }
+      setState(() => _image = image);
+    });
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final image = _image;
+    if (image == null) {
+      return const Center(
+        child: Text(
+          'Préparation de la preview atlas...',
+          textAlign: TextAlign.center,
+          style: TextStyle(
+            color: SurfaceStudioDesignTokens.textMuted,
+            fontSize: 12,
+            height: 1.3,
+          ),
+        ),
+      );
+    }
+    return CustomPaint(
+      key: const ValueKey('surfaceStudio.preview.tileCanvas'),
+      painter: SurfaceStudioSurfacePreviewPainter(
+        atlasImage: image,
+        assignmentDraft: widget.assignmentDraft,
+        tileWidth: widget.tileWidth,
+        tileHeight: widget.tileHeight,
+        columnCount: widget.columnCount,
+        frameCount: widget.frameCount,
+        frameIndex: widget.frameIndex,
+        previewSize: widget.previewSize,
+        gridVisible: widget.gridVisible,
+      ),
+      child: const SizedBox.expand(),
+    );
+  }
+}
+
+class SurfaceStudioSurfacePreviewPainter extends CustomPainter {
+  const SurfaceStudioSurfacePreviewPainter({
+    required this.atlasImage,
+    required this.assignmentDraft,
+    required this.tileWidth,
+    required this.tileHeight,
+    required this.columnCount,
+    required this.frameCount,
+    required this.frameIndex,
+    required this.previewSize,
+    required this.gridVisible,
+  });
+
+  final ui.Image atlasImage;
+  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
+  final int tileWidth;
+  final int tileHeight;
+  final int columnCount;
+  final int frameCount;
+  final int frameIndex;
+  final int previewSize;
+  final bool gridVisible;
+
+  @override
+  void paint(Canvas canvas, Size size) {
+    final centerColumns =
+        assignmentDraft.columnsForRole(SurfaceVariantRole.isolated);
+    if (centerColumns.isEmpty) {
+      return;
+    }
+    final safeFrameCount = frameCount < 1 ? 1 : frameCount;
+    final safeFrameIndex = frameIndex % safeFrameCount;
+    final cellWidth = size.width / previewSize;
+    final cellHeight = size.height / previewSize;
+    final paint = Paint()..filterQuality = FilterQuality.none;
+    for (var y = 0; y < previewSize; y++) {
+      for (var x = 0; x < previewSize; x++) {
+        final tileColumn =
+            centerColumns[(x + y + safeFrameIndex) % centerColumns.length];
+        final source = surfaceStudioTileSourceRect(
+          uiColumn: tileColumn,
+          frameIndex: safeFrameIndex,
+          tileWidth: tileWidth,
+          tileHeight: tileHeight,
+          columnCount: columnCount,
+          frameCount: safeFrameCount,
+        );
+        canvas.drawImageRect(
+          atlasImage,
+          source,
+          Rect.fromLTWH(x * cellWidth, y * cellHeight, cellWidth, cellHeight),
+          paint,
+        );
+      }
+    }
+    if (!gridVisible) {
+      return;
+    }
+    final gridPaint = Paint()
+      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.18)
+      ..strokeWidth = 1;
+    for (var i = 0; i <= previewSize; i++) {
+      final x = i * cellWidth;
+      final y = i * cellHeight;
+      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
+      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
+    }
+  }
+
+  @override
+  bool shouldRepaint(
+          covariant SurfaceStudioSurfacePreviewPainter oldDelegate) =>
+      oldDelegate.atlasImage != atlasImage ||
+      oldDelegate.assignmentDraft != assignmentDraft ||
+      oldDelegate.tileWidth != tileWidth ||
+      oldDelegate.tileHeight != tileHeight ||
+      oldDelegate.columnCount != columnCount ||
+      oldDelegate.frameCount != frameCount ||
+      oldDelegate.frameIndex != frameIndex ||
+      oldDelegate.previewSize != previewSize ||
+      oldDelegate.gridVisible != gridVisible;
+}
```

### packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_vision_pack.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_vision_pack.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_vision_pack.dart
new file mode 100644
index 00000000..478dbb3e
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_vision_pack.dart
@@ -0,0 +1,435 @@
+import 'dart:convert';
+import 'dart:typed_data';
+
+import 'package:image/image.dart' as img;
+
+final class SurfaceStudioMistralVisionPack {
+  const SurfaceStudioMistralVisionPack({
+    required this.originalAtlasDataUrl,
+    required this.annotatedAtlasDataUrl,
+    required this.columnContactSheetDataUrl,
+    required this.columnDescriptors,
+  });
+
+  final String originalAtlasDataUrl;
+  final String annotatedAtlasDataUrl;
+  final String columnContactSheetDataUrl;
+  final List<SurfaceStudioColumnVisualDescriptor> columnDescriptors;
+}
+
+final class SurfaceStudioColumnVisualDescriptor {
+  const SurfaceStudioColumnVisualDescriptor({
+    required this.column,
+    required this.averageColorHex,
+    required this.edgeOccupancy,
+    required this.hasTransparentPixels,
+    required this.likelyEmpty,
+    required this.localCandidateRoles,
+  });
+
+  final int column;
+  final String averageColorHex;
+  final SurfaceStudioColumnEdgeOccupancy edgeOccupancy;
+  final bool hasTransparentPixels;
+  final bool likelyEmpty;
+  final List<String> localCandidateRoles;
+
+  Map<String, Object?> toJson() => {
+        'column': column,
+        'averageColorHex': averageColorHex,
+        'edgeOccupancy': edgeOccupancy.toJson(),
+        'hasTransparentPixels': hasTransparentPixels,
+        'likelyEmpty': likelyEmpty,
+        'localCandidateRoles': localCandidateRoles,
+      };
+}
+
+final class SurfaceStudioColumnEdgeOccupancy {
+  const SurfaceStudioColumnEdgeOccupancy({
+    required this.top,
+    required this.right,
+    required this.bottom,
+    required this.left,
+  });
+
+  final double top;
+  final double right;
+  final double bottom;
+  final double left;
+
+  Map<String, Object?> toJson() => {
+        'top': _round(top),
+        'right': _round(right),
+        'bottom': _round(bottom),
+        'left': _round(left),
+      };
+}
+
+SurfaceStudioMistralVisionPack buildSurfaceStudioMistralVisionPack({
+  required Uint8List imageBytes,
+  required int tileWidth,
+  required int tileHeight,
+  required int columnCount,
+  required int frameCount,
+  int originalMaxLongSide = 1400,
+  int annotatedMaxLongSide = 1600,
+}) {
+  final decoded = _tryDecodeImage(imageBytes);
+  if (decoded == null) {
+    final fallback = _dataUrl(imageBytes);
+    return SurfaceStudioMistralVisionPack(
+      originalAtlasDataUrl: fallback,
+      annotatedAtlasDataUrl: fallback,
+      columnContactSheetDataUrl: fallback,
+      columnDescriptors: const <SurfaceStudioColumnVisualDescriptor>[],
+    );
+  }
+
+  final original = _resizeForAnalysis(decoded, originalMaxLongSide);
+  final annotated = _buildAnnotatedAtlas(
+    decoded,
+    tileWidth: tileWidth,
+    tileHeight: tileHeight,
+    columnCount: columnCount,
+    frameCount: frameCount,
+    maxLongSide: annotatedMaxLongSide,
+  );
+  final contactSheet = _buildColumnContactSheet(
+    decoded,
+    tileWidth: tileWidth,
+    tileHeight: tileHeight,
+    columnCount: columnCount,
+    frameCount: frameCount,
+  );
+  final descriptors = <SurfaceStudioColumnVisualDescriptor>[
+    for (var column = 1; column <= columnCount; column++)
+      _describeColumn(
+        decoded,
+        uiColumn: column,
+        tileWidth: tileWidth,
+        tileHeight: tileHeight,
+        frameCount: frameCount,
+      ),
+  ];
+
+  return SurfaceStudioMistralVisionPack(
+    originalAtlasDataUrl: _pngDataUrl(original),
+    annotatedAtlasDataUrl: _pngDataUrl(annotated),
+    columnContactSheetDataUrl: _pngDataUrl(contactSheet),
+    columnDescriptors: List<SurfaceStudioColumnVisualDescriptor>.unmodifiable(
+      descriptors,
+    ),
+  );
+}
+
+String surfaceStudioColumnDescriptorsJson(
+  List<SurfaceStudioColumnVisualDescriptor> descriptors,
+) =>
+    const JsonEncoder.withIndent('  ').convert(
+      descriptors.map((descriptor) => descriptor.toJson()).toList(),
+    );
+
+img.Image _resizeForAnalysis(img.Image source, int maxLongSide) {
+  final longest = source.width > source.height ? source.width : source.height;
+  if (longest <= maxLongSide) {
+    return img.Image.from(source);
+  }
+  return img.copyResize(
+    source,
+    width: source.width >= source.height ? maxLongSide : null,
+    height: source.height > source.width ? maxLongSide : null,
+    interpolation: img.Interpolation.average,
+  );
+}
+
+img.Image _buildAnnotatedAtlas(
+  img.Image source, {
+  required int tileWidth,
+  required int tileHeight,
+  required int columnCount,
+  required int frameCount,
+  required int maxLongSide,
+}) {
+  final annotated = _resizeForAnalysis(source, maxLongSide);
+  final safeColumns = columnCount < 1 ? 1 : columnCount;
+  final safeFrames = frameCount < 1 ? 1 : frameCount;
+  final columnWidth = annotated.width / safeColumns;
+  final rowHeight = annotated.height / safeFrames;
+  final gridColor = img.ColorRgba8(242, 200, 75, 220);
+  final labelFill = img.ColorRgba8(11, 16, 32, 230);
+  final labelText = img.ColorRgb8(242, 200, 75);
+
+  for (var column = 0; column <= safeColumns; column++) {
+    final x = (column * columnWidth).round().clamp(0, annotated.width - 1);
+    img.drawLine(
+      annotated,
+      x1: x,
+      y1: 0,
+      x2: x,
+      y2: annotated.height - 1,
+      color: gridColor,
+    );
+  }
+  for (var frame = 0; frame <= safeFrames; frame++) {
+    final y = (frame * rowHeight).round().clamp(0, annotated.height - 1);
+    img.drawLine(
+      annotated,
+      x1: 0,
+      y1: y,
+      x2: annotated.width - 1,
+      y2: y,
+      color: frame % 4 == 0 ? gridColor : img.ColorRgba8(255, 255, 255, 120),
+    );
+  }
+
+  for (var column = 1; column <= safeColumns; column++) {
+    final label = '$column';
+    final left = ((column - 1) * columnWidth).round();
+    final centerX = (left + columnWidth / 2).round();
+    final desiredLabelWidth = label.length * 10 + 12;
+    final maxLabelWidth = columnWidth.round();
+    final labelWidth = maxLabelWidth < 24
+        ? maxLabelWidth
+        : desiredLabelWidth.clamp(24, maxLabelWidth).toInt();
+    final labelLeft = (centerX - labelWidth ~/ 2).clamp(0, annotated.width - 1);
+    img.fillRect(
+      annotated,
+      x1: labelLeft,
+      y1: 4,
+      x2: (labelLeft + labelWidth).clamp(0, annotated.width - 1),
+      y2: 24,
+      color: labelFill,
+    );
+    img.drawString(
+      annotated,
+      label,
+      font: img.arial14,
+      x: labelLeft + 5,
+      y: 7,
+      color: labelText,
+    );
+  }
+  return annotated;
+}
+
+img.Image _buildColumnContactSheet(
+  img.Image source, {
+  required int tileWidth,
+  required int tileHeight,
+  required int columnCount,
+  required int frameCount,
+}) {
+  final safeColumns = columnCount < 1 ? 1 : columnCount;
+  final safeFrames = frameCount < 1 ? 1 : frameCount;
+  final thumbWidth = tileWidth.clamp(32, 80).toInt();
+  final thumbHeight = tileHeight.clamp(32, 80).toInt();
+  const labelHeight = 24;
+  const gap = 8;
+  final samples = <int>{0, safeFrames ~/ 2, safeFrames - 1}.toList()..sort();
+  final cellWidth = thumbWidth + 12;
+  final cellHeight = labelHeight + samples.length * thumbHeight + 12;
+  final sheet = img.Image(
+    width: gap + safeColumns * (cellWidth + gap),
+    height: cellHeight + gap * 2,
+  );
+  img.fill(sheet, color: img.ColorRgb8(11, 16, 32));
+
+  for (var column = 1; column <= safeColumns; column++) {
+    final cellLeft = gap + (column - 1) * (cellWidth + gap);
+    img.fillRect(
+      sheet,
+      x1: cellLeft,
+      y1: gap,
+      x2: cellLeft + cellWidth,
+      y2: gap + cellHeight,
+      color: img.ColorRgb8(28, 36, 51),
+    );
+    img.drawString(
+      sheet,
+      '$column',
+      font: img.arial14,
+      x: cellLeft + 6,
+      y: gap + 5,
+      color: img.ColorRgb8(242, 200, 75),
+    );
+    for (var sampleIndex = 0; sampleIndex < samples.length; sampleIndex++) {
+      final frame = samples[sampleIndex].clamp(0, safeFrames - 1);
+      final tile = img.copyCrop(
+        source,
+        x: (column - 1) * tileWidth,
+        y: frame * tileHeight,
+        width: tileWidth,
+        height: tileHeight,
+      );
+      final thumb = img.copyResize(
+        tile,
+        width: thumbWidth,
+        height: thumbHeight,
+        interpolation: img.Interpolation.nearest,
+      );
+      img.compositeImage(
+        sheet,
+        thumb,
+        dstX: cellLeft + 6,
+        dstY: gap + labelHeight + sampleIndex * thumbHeight,
+      );
+    }
+  }
+  return sheet;
+}
+
+SurfaceStudioColumnVisualDescriptor _describeColumn(
+  img.Image source, {
+  required int uiColumn,
+  required int tileWidth,
+  required int tileHeight,
+  required int frameCount,
+}) {
+  final safeFrameCount = frameCount < 1 ? 1 : frameCount;
+  var totalR = 0;
+  var totalG = 0;
+  var totalB = 0;
+  var visibleCount = 0;
+  var transparentCount = 0;
+  var darkVisibleCount = 0;
+
+  final xStart = (uiColumn - 1) * tileWidth;
+  final frameSamples = <int>{0, safeFrameCount ~/ 2, safeFrameCount - 1};
+  for (final frame in frameSamples) {
+    final yStart = frame * tileHeight;
+    for (var y = yStart; y < yStart + tileHeight; y++) {
+      if (y < 0 || y >= source.height) {
+        continue;
+      }
+      for (var x = xStart; x < xStart + tileWidth; x++) {
+        if (x < 0 || x >= source.width) {
+          continue;
+        }
+        final pixel = source.getPixel(x, y);
+        final alpha = pixel.a.toInt();
+        if (alpha < 20) {
+          transparentCount++;
+          continue;
+        }
+        final red = pixel.r.toInt();
+        final green = pixel.g.toInt();
+        final blue = pixel.b.toInt();
+        totalR += red;
+        totalG += green;
+        totalB += blue;
+        visibleCount++;
+        if ((red + green + blue) / 3 < 10) {
+          darkVisibleCount++;
+        }
+      }
+    }
+  }
+
+  final averageColorHex = visibleCount == 0
+      ? '#000000'
+      : _hexColor(
+          totalR ~/ visibleCount,
+          totalG ~/ visibleCount,
+          totalB ~/ visibleCount,
+        );
+  final sampledPixels = visibleCount + transparentCount;
+  final transparentRatio =
+      sampledPixels == 0 ? 1.0 : transparentCount / sampledPixels;
+  final darkRatio = visibleCount == 0 ? 1.0 : darkVisibleCount / visibleCount;
+  final likelyEmpty = transparentRatio > 0.9 || darkRatio > 0.95;
+  final edgeOccupancy = _edgeOccupancy(
+    source,
+    xStart: xStart,
+    yStart: 0,
+    tileWidth: tileWidth,
+    tileHeight: tileHeight,
+  );
+
+  return SurfaceStudioColumnVisualDescriptor(
+    column: uiColumn,
+    averageColorHex: averageColorHex,
+    edgeOccupancy: edgeOccupancy,
+    hasTransparentPixels: transparentCount > 0,
+    likelyEmpty: likelyEmpty,
+    localCandidateRoles: likelyEmpty
+        ? const <String>[]
+        : _candidateRolesFromEdges(edgeOccupancy),
+  );
+}
+
+SurfaceStudioColumnEdgeOccupancy _edgeOccupancy(
+  img.Image source, {
+  required int xStart,
+  required int yStart,
+  required int tileWidth,
+  required int tileHeight,
+}) {
+  double occupied(int x, int y) {
+    if (x < 0 || x >= source.width || y < 0 || y >= source.height) {
+      return 0;
+    }
+    final pixel = source.getPixel(x, y);
+    final alpha = pixel.a.toInt();
+    final brightness = (pixel.r + pixel.g + pixel.b) / 3;
+    return alpha > 20 && brightness > 10 ? 1 : 0;
+  }
+
+  var top = 0.0;
+  var bottom = 0.0;
+  for (var x = xStart; x < xStart + tileWidth; x++) {
+    top += occupied(x, yStart);
+    bottom += occupied(x, yStart + tileHeight - 1);
+  }
+  var left = 0.0;
+  var right = 0.0;
+  for (var y = yStart; y < yStart + tileHeight; y++) {
+    left += occupied(xStart, y);
+    right += occupied(xStart + tileWidth - 1, y);
+  }
+  return SurfaceStudioColumnEdgeOccupancy(
+    top: top / tileWidth,
+    right: right / tileHeight,
+    bottom: bottom / tileWidth,
+    left: left / tileHeight,
+  );
+}
+
+List<String> _candidateRolesFromEdges(
+  SurfaceStudioColumnEdgeOccupancy occupancy,
+) {
+  final candidates = <String>['isolated'];
+  if (occupancy.top > 0.55) {
+    candidates.add('endNorth');
+  }
+  if (occupancy.right > 0.55) {
+    candidates.add('endEast');
+  }
+  if (occupancy.bottom > 0.55) {
+    candidates.add('endSouth');
+  }
+  if (occupancy.left > 0.55) {
+    candidates.add('endWest');
+  }
+  return List<String>.unmodifiable(candidates);
+}
+
+String _pngDataUrl(img.Image image) =>
+    'data:image/png;base64,${base64Encode(img.encodePng(image))}';
+
+String _dataUrl(Uint8List bytes) =>
+    'data:image/png;base64,${base64Encode(bytes)}';
+
+String _hexColor(int red, int green, int blue) =>
+    '#${_hex(red)}${_hex(green)}${_hex(blue)}';
+
+String _hex(int value) => value.clamp(0, 255).toRadixString(16).padLeft(2, '0');
+
+double _round(double value) => double.parse(value.toStringAsFixed(3));
+
+img.Image? _tryDecodeImage(Uint8List imageBytes) {
+  try {
+    return img.decodeImage(imageBytes);
+  } catch (_) {
+    return null;
+  }
+}
```

### packages/map_editor/test/surface_studio/surface_studio_atlas_view_geometry_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_atlas_view_geometry_test.dart b/packages/map_editor/test/surface_studio/surface_studio_atlas_view_geometry_test.dart
new file mode 100644
index 00000000..a578b732
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_atlas_view_geometry_test.dart
@@ -0,0 +1,81 @@
+import 'dart:ui';
+
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_view_geometry.dart';
+
+void main() {
+  test('computeContainedImageRect preserves ratio and exposes letterbox', () {
+    final rect = computeSurfaceStudioContainedImageRect(
+      viewportSize: const Size(600, 400),
+      imagePixelSize: const Size(736, 1024),
+    );
+
+    expect(rect.left, closeTo(156.25, 0.001));
+    expect(rect.top, closeTo(0, 0.001));
+    expect(rect.width, closeTo(287.5, 0.001));
+    expect(rect.height, closeTo(400, 0.001));
+  });
+
+  test('hit testing ignores letterbox and maps fitted rect columns', () {
+    final geometry = SurfaceStudioAtlasViewGeometry.fromContain(
+      viewportSize: const Size(600, 400),
+      imagePixelSize: const Size(736, 1024),
+      tileWidth: 32,
+      tileHeight: 32,
+      columnCount: 23,
+      frameCount: 32,
+    );
+
+    expect(
+      surfaceStudioColumnAtViewportOffset(
+        localPosition: const Offset(120, 200),
+        geometry: geometry,
+      ),
+      isNull,
+    );
+    expect(
+      surfaceStudioColumnAtViewportOffset(
+        localPosition: const Offset(200, 200),
+        geometry: geometry,
+      ),
+      4,
+    );
+    expect(
+      surfaceStudioFrameAtViewportOffset(
+        localPosition: const Offset(200, 7),
+        geometry: geometry,
+      ),
+      1,
+    );
+  });
+
+  test('column viewport rect and tile source rect share 1-based column rules',
+      () {
+    final geometry = SurfaceStudioAtlasViewGeometry.fromContain(
+      viewportSize: const Size(600, 400),
+      imagePixelSize: const Size(736, 1024),
+      tileWidth: 32,
+      tileHeight: 32,
+      columnCount: 23,
+      frameCount: 32,
+    );
+
+    final column4 = surfaceStudioColumnViewportRect(
+      uiColumn: 4,
+      geometry: geometry,
+    );
+    expect(column4.left, closeTo(193.75, 0.001));
+    expect(column4.width, closeTo(12.5, 0.001));
+    expect(geometry.fittedImageRect.contains(column4.center), isTrue);
+
+    final source = surfaceStudioTileSourceRect(
+      uiColumn: 4,
+      frameIndex: 1,
+      tileWidth: 32,
+      tileHeight: 32,
+      columnCount: 23,
+      frameCount: 32,
+    );
+    expect(source, const Rect.fromLTWH(96, 32, 32, 32));
+  });
+}
```

### packages/map_editor/test/surface_studio/surface_studio_atlas_viewport_coordinate_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_atlas_viewport_coordinate_test.dart b/packages/map_editor/test/surface_studio/surface_studio_atlas_viewport_coordinate_test.dart
new file mode 100644
index 00000000..2c21bf17
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_atlas_viewport_coordinate_test.dart
@@ -0,0 +1,75 @@
+import 'dart:typed_data';
+
+import 'package:flutter/widgets.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:image/image.dart' as img;
+import 'package:map_editor/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_column_selection.dart';
+
+void main() {
+  testWidgets(
+      'atlas viewport hit testing uses fitted image rect, not viewport width',
+      (tester) async {
+    var selection = const SurfaceStudioColumnSelection.empty();
+
+    await tester.pumpWidget(
+      Directionality(
+        textDirection: TextDirection.ltr,
+        child: Center(
+          child: SizedBox(
+            width: 600,
+            height: 460,
+            child: SurfaceStudioAtlasViewport(
+              columnCount: 23,
+              frameCount: 32,
+              tileWidth: 32,
+              tileHeight: 32,
+              atlasImageBytes: _atlasBytes(),
+              selection: selection,
+              centerAssigned: false,
+              centerColumns: const <int>[],
+              zoomPercent: 100,
+              onColumnSelectionChanged: (next) => selection = next,
+              onUseSelectionAsCenter: () {},
+            ),
+          ),
+        ),
+      ),
+    );
+    await tester.pumpAndSettle();
+
+    final canvas = find.byKey(const ValueKey('surfaceStudio.atlas.canvas'));
+    expect(canvas, findsOneWidget);
+    expect(find.byKey(const ValueKey('surfaceStudio.atlas.realImage')),
+        findsNothing);
+
+    final canvasTopLeft = tester.getTopLeft(canvas);
+    await tester.tapAt(canvasTopLeft + const Offset(120, 210));
+    await tester.pump();
+    expect(selection.columns, isEmpty);
+
+    await tester.tapAt(canvasTopLeft + const Offset(200, 210));
+    await tester.pump();
+    expect(selection.columns, <int>[4]);
+  });
+}
+
+Uint8List _atlasBytes() {
+  const tile = 32;
+  const columns = 23;
+  const frames = 32;
+  final image = img.Image(width: columns * tile, height: frames * tile);
+  for (var frame = 0; frame < frames; frame++) {
+    for (var column = 0; column < columns; column++) {
+      img.fillRect(
+        image,
+        x1: column * tile,
+        y1: frame * tile,
+        x2: column * tile + tile - 1,
+        y2: frame * tile + tile - 1,
+        color: img.ColorRgb8(20 + column * 5, 50 + frame, 160),
+      );
+    }
+  }
+  return Uint8List.fromList(img.encodePng(image));
+}
```

### packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart b/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart
new file mode 100644
index 00000000..402ad232
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart
@@ -0,0 +1,206 @@
+import 'dart:io';
+import 'dart:typed_data';
+import 'dart:ui' as ui;
+
+import 'package:flutter/widgets.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:image/image.dart' as img;
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart';
+
+import 'surface_studio_rebuild_test_harness.dart';
+
+void main() {
+  test('tile source rect uses 1-based UI columns and 0-based atlas pixels', () {
+    final rect = surfaceStudioTileSourceRect(
+      uiColumn: 4,
+      frameIndex: 1,
+      tileWidth: 8,
+      tileHeight: 8,
+      columnCount: 5,
+      frameCount: 2,
+    );
+
+    expect(rect, const ui.Rect.fromLTWH(24, 8, 8, 8));
+  });
+
+  test('tile source rect points to the expected fixture colors', () {
+    final atlas = img.decodePng(_atlasBytes())!;
+
+    final column4Frame0 = surfaceStudioTileSourceRect(
+      uiColumn: 4,
+      frameIndex: 0,
+      tileWidth: 8,
+      tileHeight: 8,
+      columnCount: 5,
+      frameCount: 2,
+    );
+    final column5Frame1 = surfaceStudioTileSourceRect(
+      uiColumn: 5,
+      frameIndex: 1,
+      tileWidth: 8,
+      tileHeight: 8,
+      columnCount: 5,
+      frameCount: 2,
+    );
+
+    final green = atlas.getPixel(
+      column4Frame0.left.toInt() + 1,
+      column4Frame0.top.toInt() + 1,
+    );
+    final darkBlue = atlas.getPixel(
+      column5Frame1.left.toInt() + 1,
+      column5Frame1.top.toInt() + 1,
+    );
+
+    expect(green.r, 20);
+    expect(green.g, 220);
+    expect(green.b, 60);
+    expect(darkBlue.r, 8);
+    expect(darkBlue.g, 42);
+    expect(darkBlue.b, 96);
+  });
+
+  testWidgets(
+      'selection alone is not mapping, quick center assignment activates preview',
+      (tester) async {
+    final temp = Directory.systemTemp.createTempSync('surface_mapper_preview_');
+    addTearDown(() => temp.deleteSync(recursive: true));
+    final image = File('${temp.path}/tiles/water.png');
+    image.parent.createSync(recursive: true);
+    image.writeAsBytesSync(_atlasBytes());
+
+    await pumpSurfaceStudioForTest(
+      tester,
+      readModel: _readModel(),
+      projectTilesets: const <ProjectTilesetEntry>[
+        ProjectTilesetEntry(
+          id: 'water_tiles',
+          name: 'Water Tiles',
+          relativePath: 'tiles/water.png',
+          sortOrder: 0,
+        ),
+      ],
+      projectRootPath: temp.path,
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.text('Colonnes sélectionnées : 4–5'), findsOneWidget);
+    expect(find.text('Plein(center) : non assigné'), findsOneWidget);
+    expect(find.textContaining('Assignez au moins le rôle'), findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
+        findsNothing);
+
+    await tester.tap(
+      find.byKey(const Key('surfaceStudio.atlas.useSelectionAsCenter')),
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.text('Plein(center) : colonnes 4–5'), findsOneWidget);
+    expect(find.textContaining('Assignez au moins le rôle'), findsNothing);
+    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
+        findsOneWidget);
+    expect(find.textContaining('Preview partielle'), findsOneWidget);
+    expect(
+      find.textContaining('Source rect actuelle : x=24 y=0 w=8 h=8'),
+      findsOneWidget,
+    );
+
+    final centerSlot =
+        find.byKey(const Key('surfaceStudio.schema.role.center'));
+    expect(find.descendant(of: centerSlot, matching: find.text('4')),
+        findsOneWidget);
+    expect(find.descendant(of: centerSlot, matching: find.text('5')),
+        findsOneWidget);
+  });
+
+  testWidgets('preview frame controls change the rendered frame state',
+      (tester) async {
+    final temp = Directory.systemTemp.createTempSync('surface_frame_preview_');
+    addTearDown(() => temp.deleteSync(recursive: true));
+    final image = File('${temp.path}/tiles/water.png');
+    image.parent.createSync(recursive: true);
+    image.writeAsBytesSync(_atlasBytes());
+
+    await pumpSurfaceStudioForTest(
+      tester,
+      readModel: _readModel(),
+      projectTilesets: const <ProjectTilesetEntry>[
+        ProjectTilesetEntry(
+          id: 'water_tiles',
+          name: 'Water Tiles',
+          relativePath: 'tiles/water.png',
+          sortOrder: 0,
+        ),
+      ],
+      projectRootPath: temp.path,
+    );
+    await tester.pumpAndSettle();
+
+    await tester.tap(
+      find.byKey(const Key('surfaceStudio.atlas.useSelectionAsCenter')),
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.text('Frame 1 / 2'), findsOneWidget);
+    expect(
+      find.textContaining('Source rect actuelle : x=24 y=0 w=8 h=8'),
+      findsOneWidget,
+    );
+    await tester.tap(find.byKey(const Key('surfaceStudio.preview.next')));
+    await tester.pumpAndSettle();
+    expect(find.text('Frame 2 / 2'), findsOneWidget);
+    expect(
+      find.textContaining('Source rect actuelle : x=32 y=8 w=8 h=8'),
+      findsOneWidget,
+    );
+  });
+}
+
+SurfaceStudioReadModel _readModel() {
+  const atlasId = 'water-atlas';
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[
+        ProjectSurfaceAtlas(
+          id: atlasId,
+          name: 'Water Atlas',
+          tilesetId: 'water_tiles',
+          geometry: SurfaceAtlasGeometry(
+            tileSize: SurfaceAtlasTileSize(width: 8, height: 8),
+            gridSize: SurfaceAtlasGridSize(columns: 5, rows: 2),
+            layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+          ),
+        ),
+      ],
+      animations: const <ProjectSurfaceAnimation>[],
+      presets: const <ProjectSurfacePreset>[],
+    ),
+  );
+}
+
+Uint8List _atlasBytes() {
+  const tile = 8;
+  const columns = 5;
+  const frames = 2;
+  final image = img.Image(width: columns * tile, height: frames * tile);
+  for (var frame = 0; frame < frames; frame++) {
+    for (var column = 0; column < columns; column++) {
+      final color = switch (column) {
+        3 => frame == 0 ? img.ColorRgb8(20, 220, 60) : img.ColorRgb8(6, 90, 24),
+        4 =>
+          frame == 0 ? img.ColorRgb8(30, 120, 240) : img.ColorRgb8(8, 42, 96),
+        _ => img.ColorRgb8(140 + column * 10, 20, 60 + frame * 30),
+      };
+      img.fillRect(
+        image,
+        x1: column * tile,
+        y1: frame * tile,
+        x2: column * tile + tile - 1,
+        y2: frame * tile + tile - 1,
+        color: color,
+      );
+    }
+  }
+  return Uint8List.fromList(img.encodePng(image));
+}
```

### packages/map_editor/test/surface_studio/surface_studio_mistral_vision_pack_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_mistral_vision_pack_test.dart b/packages/map_editor/test/surface_studio/surface_studio_mistral_vision_pack_test.dart
new file mode 100644
index 00000000..d9fd7692
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_mistral_vision_pack_test.dart
@@ -0,0 +1,72 @@
+import 'dart:convert';
+import 'dart:typed_data';
+
+import 'package:flutter_test/flutter_test.dart';
+import 'package:image/image.dart' as img;
+import 'package:map_editor/src/features/surface_studio/surface_studio_mistral_vision_pack.dart';
+
+void main() {
+  test('vision pack builds original, annotated and contact sheet data urls',
+      () {
+    final pack = buildSurfaceStudioMistralVisionPack(
+      imageBytes: _atlasBytesWithEmptyColumn(),
+      tileWidth: 8,
+      tileHeight: 8,
+      columnCount: 4,
+      frameCount: 2,
+    );
+
+    expect(pack.originalAtlasDataUrl, startsWith('data:image/png;base64,'));
+    expect(pack.annotatedAtlasDataUrl, startsWith('data:image/png;base64,'));
+    expect(
+      pack.columnContactSheetDataUrl,
+      startsWith('data:image/png;base64,'),
+    );
+    expect(pack.columnDescriptors, hasLength(4));
+    expect(pack.columnDescriptors[2].column, 3);
+    expect(pack.columnDescriptors[2].likelyEmpty, isTrue);
+    expect(pack.columnDescriptors[0].averageColorHex, startsWith('#'));
+
+    final contactSheet = img.decodePng(_decodeDataUrl(
+      pack.columnContactSheetDataUrl,
+    ));
+    expect(contactSheet, isNotNull);
+    expect(contactSheet!.width, greaterThan(contactSheet.height));
+
+    final descriptorJson = surfaceStudioColumnDescriptorsJson(
+      pack.columnDescriptors,
+    );
+    expect(descriptorJson, contains('"likelyEmpty": true'));
+    expect(descriptorJson, isNot(contains('/Users/')));
+    expect(descriptorJson, isNot(contains('configured-secret')));
+  });
+}
+
+Uint8List _atlasBytesWithEmptyColumn() {
+  const tile = 8;
+  const columns = 4;
+  const frames = 2;
+  final image = img.Image(width: columns * tile, height: frames * tile);
+  img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
+  for (var frame = 0; frame < frames; frame++) {
+    for (var column = 0; column < columns; column++) {
+      if (column == 2) {
+        continue;
+      }
+      img.fillRect(
+        image,
+        x1: column * tile,
+        y1: frame * tile,
+        x2: column * tile + tile - 1,
+        y2: frame * tile + tile - 1,
+        color: img.ColorRgba8(30 + column * 40, 120, 210, 255),
+      );
+    }
+  }
+  return Uint8List.fromList(img.encodePng(image));
+}
+
+Uint8List _decodeDataUrl(String dataUrl) {
+  final encoded = dataUrl.substring(dataUrl.indexOf(',') + 1);
+  return Uint8List.fromList(base64Decode(encoded));
+}
```

### packages/map_editor/test/surface_studio/surface_studio_mistral_prompt_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_mistral_prompt_test.dart b/packages/map_editor/test/surface_studio/surface_studio_mistral_prompt_test.dart
new file mode 100644
index 00000000..ff130ed7
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_mistral_prompt_test.dart
@@ -0,0 +1,101 @@
+import 'dart:convert';
+import 'dart:typed_data';
+
+import 'package:flutter_test/flutter_test.dart';
+import 'package:http/http.dart' as http;
+import 'package:http/testing.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart';
+
+void main() {
+  test('prompt asks for careful visual reasoning and documents roles exactly',
+      () {
+    final prompt = buildSurfaceStudioMappingSuggestionPrompt(
+      tileWidth: 8,
+      tileHeight: 8,
+      columnCount: 5,
+      frameCount: 2,
+    );
+
+    expect(prompt, contains('Take your time internally'));
+    expect(prompt, contains('Use high-effort visual reasoning'));
+    expect(prompt, contains('Inspect the column contact sheet first'));
+    expect(prompt, contains('Do not guess'));
+    expect(prompt, contains('Prefer abstaining over wrong mappings'));
+    expect(prompt, contains('Do not guess when uncertain'));
+    expect(prompt, contains('Columns are 1-based'));
+    expect(prompt, contains('Never map likelyEmpty columns'));
+    expect(prompt, contains('tileWidth: 8'));
+    expect(prompt, contains('tileHeight: 8'));
+    expect(prompt, contains('columns: 5'));
+    expect(prompt, contains('frames: 2'));
+    expect(prompt, contains('isolated may contain multiple columns'));
+    expect(prompt, contains('All other roles must contain at most one column'));
+    expect(
+      prompt,
+      contains(
+        'isolated, endNorth, endEast, endSouth, endWest, horizontal, vertical, cornerNW, cornerNE, cornerSW, cornerSE, innerCornerNW, innerCornerNE, innerCornerSW, innerCornerSE, teeNorth, teeEast, teeSouth, teeWest, cross',
+      ),
+    );
+    expect(prompt, contains('Plein(center) = isolated'));
+    expect(prompt, contains('Bord haut = endNorth'));
+  });
+
+  test('Mistral request uses high reasoning, schema output and no secret body',
+      () async {
+    Map<String, dynamic>? requestBody;
+    final suggester = SurfaceStudioMistralMappingSuggester(
+      httpClient: MockClient((request) async {
+        requestBody = jsonDecode(request.body) as Map<String, dynamic>;
+        expect(request.headers['Authorization'], 'Bearer configured-secret');
+        expect(request.body, isNot(contains('configured-secret')));
+        expect(request.body, isNot(contains('/Users/')));
+        return http.Response(
+          jsonEncode({
+            'choices': [
+              {
+                'message': {
+                  'content': jsonEncode({
+                    'assignments': const [],
+                    'rejectedColumns': const [],
+                    'warnings': const ['No confident mapping.'],
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
+    await suggester.suggest(
+      apiKey: 'configured-secret',
+      imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
+      tileWidth: 8,
+      tileHeight: 8,
+      columnCount: 5,
+      frameCount: 2,
+    );
+
+    final body = requestBody!;
+    expect(body['reasoning_effort'], 'high');
+    expect(body['temperature'], lessThanOrEqualTo(0.2));
+    final responseFormat = body['response_format'] as Map<String, dynamic>;
+    expect(responseFormat['type'], 'json_schema');
+    expect(responseFormat['json_schema'], isA<Map<String, dynamic>>());
+    expect(jsonEncode(responseFormat), contains('evidenceColumns'));
+    expect(jsonEncode(responseFormat), contains('rejectedColumns'));
+    expect(jsonEncode(body), contains('Take your time internally'));
+    expect(
+        jsonEncode(body), contains('Inspect the column contact sheet first'));
+    final content = ((body['messages'] as List).single
+        as Map<String, dynamic>)['content'] as List<dynamic>;
+    expect(
+      content
+          .whereType<Map<String, dynamic>>()
+          .where((part) => part['type'] == 'image_url'),
+      hasLength(3),
+    );
+  });
+}
```

### packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart b/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart
new file mode 100644
index 00000000..3a4f418d
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart
@@ -0,0 +1,230 @@
+import 'dart:async';
+import 'dart:io';
+import 'dart:typed_data';
+
+import 'package:flutter/cupertino.dart';
+import 'package:flutter/widgets.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:image/image.dart' as img;
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart';
+
+import 'surface_studio_rebuild_test_harness.dart';
+
+void main() {
+  testWidgets('Mistral progress stays visible while AI future is pending',
+      (tester) async {
+    final temp = Directory.systemTemp.createTempSync('surface_mistral_wait_');
+    addTearDown(() => temp.deleteSync(recursive: true));
+    final image = File('${temp.path}/tiles/water.png');
+    image.parent.createSync(recursive: true);
+    image.writeAsBytesSync(_atlasBytes());
+    final fakeAi = _PendingAiSuggester();
+
+    await pumpSurfaceStudioForTest(
+      tester,
+      readModel: _readModel(),
+      projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
+      projectTilesets: const <ProjectTilesetEntry>[
+        ProjectTilesetEntry(
+          id: 'water_tiles',
+          name: 'Water Tiles',
+          relativePath: 'tiles/water.png',
+          sortOrder: 0,
+        ),
+      ],
+      projectRootPath: temp.path,
+      aiMappingSuggester: fakeAi,
+    );
+    await tester.pumpAndSettle();
+
+    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
+    await tester.pumpAndSettle();
+    final mistralButton =
+        find.byKey(const Key('surfaceStudio.suggestion.mistral'));
+    await tester.ensureVisible(mistralButton);
+    await tester.tap(mistralButton);
+    await tester.pumpAndSettle();
+    final confirmButton =
+        find.byKey(const Key('surfaceStudio.suggestion.confirmAi'));
+    await tester.ensureVisible(confirmButton);
+    await tester.tap(confirmButton);
+    await tester.pump();
+
+    expect(fakeAi.calls, 1);
+    expect(
+      find.byKey(const Key('surfaceStudio.suggestion.mistralProgress')),
+      findsOneWidget,
+    );
+    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
+    expect(find.textContaining('Analyse visuelle approfondie'), findsOneWidget);
+    expect(
+      find.textContaining('Mistral analyse l’atlas avec un niveau'),
+      findsOneWidget,
+    );
+    expect(
+      tester
+          .widget<CupertinoButton>(
+            find.byKey(const Key('surfaceStudio.suggestion.mistral')),
+          )
+          .onPressed,
+      isNull,
+    );
+    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
+        findsNothing);
+
+    fakeAi.complete();
+    await tester.pumpAndSettle();
+
+    expect(
+      find.byKey(const Key('surfaceStudio.suggestion.mistralProgress')),
+      findsNothing,
+    );
+    expect(find.text('AI center'), findsOneWidget);
+    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
+        findsNothing);
+  });
+
+  testWidgets('Mistral timeout is shown without mutating mapping',
+      (tester) async {
+    final temp =
+        Directory.systemTemp.createTempSync('surface_mistral_timeout_');
+    addTearDown(() => temp.deleteSync(recursive: true));
+    final image = File('${temp.path}/tiles/water.png');
+    image.parent.createSync(recursive: true);
+    image.writeAsBytesSync(_atlasBytes());
+
+    await pumpSurfaceStudioForTest(
+      tester,
+      readModel: _readModel(),
+      projectSettings: const ProjectSettings(mistralApiKey: 'configured'),
+      projectTilesets: const <ProjectTilesetEntry>[
+        ProjectTilesetEntry(
+          id: 'water_tiles',
+          name: 'Water Tiles',
+          relativePath: 'tiles/water.png',
+          sortOrder: 0,
+        ),
+      ],
+      projectRootPath: temp.path,
+      aiMappingSuggester: const _TimeoutAiSuggester(),
+    );
+    await tester.pumpAndSettle();
+
+    await tester.tap(find.byKey(const Key('surfaceStudio.action.autoSuggest')));
+    await tester.pumpAndSettle();
+    final mistralButton =
+        find.byKey(const Key('surfaceStudio.suggestion.mistral'));
+    await tester.ensureVisible(mistralButton);
+    await tester.tap(mistralButton);
+    await tester.pumpAndSettle();
+    final confirmButton =
+        find.byKey(const Key('surfaceStudio.suggestion.confirmAi'));
+    await tester.ensureVisible(confirmButton);
+    await tester.tap(confirmButton);
+    await tester.pumpAndSettle();
+
+    expect(
+      find.textContaining('Mistral n’a pas répondu à temps'),
+      findsOneWidget,
+    );
+    expect(find.byKey(const Key('surfaceStudio.preview.tileRenderer')),
+        findsNothing);
+  });
+}
+
+final class _PendingAiSuggester implements SurfaceStudioAiMappingSuggester {
+  final Completer<SurfaceStudioMappingSuggestionResult> completer =
+      Completer<SurfaceStudioMappingSuggestionResult>();
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
+  }) {
+    calls++;
+    return completer.future;
+  }
+
+  void complete() {
+    completer.complete(
+      const SurfaceStudioMappingSuggestionResult(
+        suggestions: <SurfaceStudioRoleSuggestion>[
+          SurfaceStudioRoleSuggestion(
+            role: SurfaceVariantRole.isolated,
+            columns: <int>[4, 5],
+            confidence: SurfaceStudioMappingSuggestionConfidence.high,
+            source: SurfaceStudioMappingSuggestionSource.mistral,
+            reason: 'AI center',
+          ),
+        ],
+        warnings: <String>[],
+        source: SurfaceStudioMappingSuggestionSource.mistral,
+      ),
+    );
+  }
+}
+
+final class _TimeoutAiSuggester implements SurfaceStudioAiMappingSuggester {
+  const _TimeoutAiSuggester();
+
+  @override
+  Future<SurfaceStudioMappingSuggestionResult> suggest({
+    required String apiKey,
+    required Uint8List imageBytes,
+    required int tileWidth,
+    required int tileHeight,
+    required int columnCount,
+    required int frameCount,
+  }) {
+    throw TimeoutException('fake timeout');
+  }
+}
+
+SurfaceStudioReadModel _readModel() {
+  const atlasId = 'water-atlas';
+  return buildSurfaceStudioReadModelFromCatalog(
+    ProjectSurfaceCatalog(
+      atlases: <ProjectSurfaceAtlas>[
+        ProjectSurfaceAtlas(
+          id: atlasId,
+          name: 'Water Atlas',
+          tilesetId: 'water_tiles',
+          geometry: SurfaceAtlasGeometry(
+            tileSize: SurfaceAtlasTileSize(width: 8, height: 8),
+            gridSize: SurfaceAtlasGridSize(columns: 5, rows: 2),
+            layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+          ),
+        ),
+      ],
+      animations: const <ProjectSurfaceAnimation>[],
+      presets: const <ProjectSurfacePreset>[],
+    ),
+  );
+}
+
+Uint8List _atlasBytes() {
+  const tile = 8;
+  const columns = 5;
+  const frames = 2;
+  final image = img.Image(width: columns * tile, height: frames * tile);
+  for (var frame = 0; frame < frames; frame++) {
+    for (var column = 0; column < columns; column++) {
+      img.fillRect(
+        image,
+        x1: column * tile,
+        y1: frame * tile,
+        x2: column * tile + tile - 1,
+        y2: frame * tile + tile - 1,
+        color: img.ColorRgb8(40 + column * 32, 80 + frame * 70, 180),
+      );
+    }
+  }
+  return Uint8List.fromList(img.encodePng(image));
+}
```

## 20.10 Tests — atlas view geometry

```text
commande exacte: bash -lc cd packages/map_editor && flutter test test/surface_studio/surface_studio_atlas_view_geometry_test.dart --no-pub --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_view_geometry_test.dart
00:00 +0: computeContainedImageRect preserves ratio and exposes letterbox
00:00 +1: hit testing ignores letterbox and maps fitted rect columns
00:00 +2: column viewport rect and tile source rect share 1-based column rules
00:00 +3: All tests passed!
exit code: 0
```

## 20.10 Tests — atlas viewport coordinate

```text
commande exacte: bash -lc cd packages/map_editor && flutter test test/surface_studio/surface_studio_atlas_viewport_coordinate_test.dart --no-pub --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_viewport_coordinate_test.dart
00:00 +0: atlas viewport hit testing uses fitted image rect, not viewport width
00:00 +1: All tests passed!
exit code: 0
```

## 20.10 Tests — mapper preview

```text
commande exacte: bash -lc cd packages/map_editor && flutter test test/surface_studio/surface_studio_mapper_preview_test.dart --no-pub --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart
00:00 +0: tile source rect uses 1-based UI columns and 0-based atlas pixels
00:00 +1: tile source rect points to the expected fixture colors
00:00 +2: selection alone is not mapping, quick center assignment activates preview
00:00 +3: preview frame controls change the rendered frame state
00:01 +4: All tests passed!
exit code: 0
```

## 20.10 Tests — Mistral vision pack

```text
commande exacte: bash -lc cd packages/map_editor && flutter test test/surface_studio/surface_studio_mistral_vision_pack_test.dart --no-pub --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_vision_pack_test.dart
00:00 +0: vision pack builds original, annotated and contact sheet data urls
00:00 +1: All tests passed!
exit code: 0
```

## 20.10 Tests — Mistral prompt

```text
commande exacte: bash -lc cd packages/map_editor && flutter test test/surface_studio/surface_studio_mistral_prompt_test.dart --no-pub --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_prompt_test.dart
00:00 +0: prompt asks for careful visual reasoning and documents roles exactly
00:00 +1: Mistral request uses high reasoning, schema output and no secret body
00:00 +2: All tests passed!
exit code: 0
```

## 20.10 Tests — mapping suggestion

```text
commande exacte: bash -lc cd packages/map_editor && flutter test test/surface_studio/surface_studio_mapping_suggestion_test.dart --no-pub --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
00:00 +0: local suggester returns bounded reviewable suggestions
00:00 +1: Suggestion auto opens a review before mutating the mapping
00:00 +2: Mistral prep detects configured key without displaying it
00:01 +3: Mistral analysis asks confirmation before any provider call
00:01 +4: accepted Mistral suggestion updates mapping and live preview
00:01 +5: Mistral suggester validates JSON without leaking secrets
00:01 +6: Mistral suggester returns a warning for invalid JSON
00:01 +7: Mistral suggester rejects locally likelyEmpty columns
00:01 +8: All tests passed!
exit code: 0
```

## 20.10 Tests — Mistral progress

```text
commande exacte: bash -lc cd packages/map_editor && flutter test test/surface_studio/surface_studio_mistral_progress_test.dart --no-pub --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart
00:00 +0: Mistral progress stays visible while AI future is pending
00:01 +1: Mistral timeout is shown without mutating mapping
00:01 +2: All tests passed!
exit code: 0
```

## 20.10 Tests — tous Surface Studio

```text
commande exacte: bash -lc cd packages/map_editor && flutter test test/surface_studio --no-pub --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé atlas + id
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: role drop validation accepts center multi-column and rejects edge multi-column
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: role assignment draft preserves center order and replaces other roles
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
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
00:01 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart: schema panel uses accordions and shows expected roles
00:01 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart: Mistral progress stays visible while AI future is pending
00:01 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart: Mistral progress stays visible while AI future is pending
00:01 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart: Mistral progress stays visible while AI future is pending
00:01 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart: selection alone is not mapping, quick center assignment activates preview
00:02 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart: selection alone is not mapping, quick center assignment activates preview
00:02 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart: preview frame controls change the rendered frame state
00:02 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:02 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:02 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:02 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:02 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:02 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:03 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:03 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:03 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:03 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:03 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:03 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) titre, brouillon local, défauts 32/1/1
00:03 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 renders one wizard and no legacy workflow underneath
00:03 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:03 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:03 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:03 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:03 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:03 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: premium wizard shell mirrors the reference structure
00:03 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) taille tuile x non entier: erreur
00:03 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:04 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:04 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:04 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:04 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:04 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:04 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:04 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:04 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel V2.1 SurfaceStudioPanelFromManifest saves the work catalog by action
00:04 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) hauteur / colonnes / lignes <= 0: erreur
00:04 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) hauteur / colonnes / lignes <= 0: erreur
00:04 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) hauteur / colonnes / lignes <= 0: erreur
00:04 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) hauteur / colonnes / lignes <= 0: erreur
00:04 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:04 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:04 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:04 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:04 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:04 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:04 +71: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:04 +72: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:04 +73: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:04 +74: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:04 +75: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: stepper allows previous steps and blocks locked future steps
00:04 +76: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) sortOrder négatif: erreur
00:04 +77: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: SurfaceStudioCatalogBrowser sélection (Lot 58) 20. browser remonte tap preset
00:04 +78: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart: bottom action bar exposes the required commands
00:04 +79: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) id dupliqué dans le catalogue: erreur
00:04 +80: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 60) Charger la sélection: champs = atlas, catalogue inchangé
00:05 +81: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:05 +82: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:05 +83: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:05 +84: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface
00:05 +85: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +86: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +87: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +88: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +89: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +90: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +91: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +92: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +93: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +94: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +95: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +96: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +97: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +98: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +99: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +100: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +101: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +102: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +103: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +104: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +105: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +106: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +107: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +108: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +109: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:05 +110: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +111: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +112: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +113: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +114: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +115: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +116: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +117: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +118: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +119: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +120: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +121: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +122: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:06 +123: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:07 +124: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:07 +125: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:07 +126: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:07 +127: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:07 +128: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:07 +129: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart: Lot 80 — golden slice vertical atlas V2.1 UI : atlas → suggestion review → animations → preset → save prep
00:07 +130: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:07 +131: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:07 +132: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart: preview panel exposes playback, scrub, loop grid and size controls
00:07 +133: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart: SurfaceStudioColumnRoleMappingBlock affiche les libellés utilisateur des rôles
00:07 +134: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 67–68) édition : renommer et appliquer, ordre et animations
00:07 +135: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 67–68) annuler l’édition : sortie mode édition
00:07 +136: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 67–68) pas d’action Renommer id / Changer l’id
00:08 +137: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 70) section image source, pas d’ancien label tileset principal, fallback
00:08 +138: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 70) tilesets projet : menu déroulant, pas de champ avancé tileset
00:08 +139: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 74) assistant vertical visible dans la préparation
00:08 +140: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 73) sans image résolue : pas de libellé Grille superposée
00:08 +141: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 72) section aperçu image source présente
00:08 +142: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 71) section aperçu grille visible avec métriques
00:08 +143: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 71) aperçu état vide sans source
00:08 +144: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 71) aperçu état invalide dimensions
00:08 +145: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: SurfaceStudioAtlasAuthoringPrep (Lot 71) aperçu mis à jour en mode édition
00:09 +146: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: section Mapping des colonnes visible pour atlas 23×32
00:09 +147: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: section Mapping des colonnes affiche Atlas simple pour 1×1
00:09 +148: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: Lot 77 : section Plan de génération des animations visible
00:09 +149: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: Lot 79 : section création surface peignable visible
00:09 +150: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: Lot 76 : section Aperçu animation par colonne visible
00:09 +151: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: boutons Suggérer et Réinitialiser fonctionnent
00:10 +152: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_source_picker_test.dart: suggestInternalAtlasIdFromName eau animée
00:10 +153: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_source_picker_test.dart: suggestInternalAtlasIdFromName vide
00:10 +154: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_source_picker_test.dart: sortedTilesetChoices ordre sortOrder puis nom
00:10 +155: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface
00:10 +156: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface
00:10 +157: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface
00:10 +158: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface
00:10 +159: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface
00:10 +160: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface
00:10 +161: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface
00:10 +162: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface
00:10 +163: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface
00:10 +164: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface
00:10 +165: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface
00:11 +166: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +167: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +168: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +169: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +170: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +171: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +172: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +173: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +174: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +175: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +176: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +177: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +178: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +179: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +180: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +181: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +182: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +183: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +184: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +185: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +186: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: Surface Studio renders one integrated wizard without legacy below
00:11 +187: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:11 +188: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:11 +189: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:11 +190: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:11 +191: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:11 +192: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:11 +193: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:11 +194: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:11 +195: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +196: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +197: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +198: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +199: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +200: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +201: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +202: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 entry remains visible in the explorer
00:12 +203: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: import and slice steps do not render schema or preview docks
00:12 +204: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: import and slice steps do not render schema or preview docks
00:12 +205: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: import and slice steps do not render schema or preview docks
00:12 +206: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: import and slice steps do not render schema or preview docks
00:12 +207: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: import and slice steps do not render schema or preview docks
00:12 +208: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: import and slice steps do not render schema or preview docks
00:12 +209: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart: import and slice steps do not render schema or preview docks
00:12 +210: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:12 +211: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:13 +212: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:13 +213: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:13 +214: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:13 +215: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:13 +216: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:13 +217: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 surface workspace renders one integrated assistant
00:13 +218: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +219: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +220: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +221: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +222: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +223: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +224: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +225: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +226: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +227: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +228: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +229: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +230: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +231: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +232: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +233: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +234: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +235: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +236: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +237: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +238: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +239: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +240: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +241: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +242: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart: editor lists roles, current animation and missing roles
00:13 +243: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +244: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +245: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +246: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +247: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +248: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +249: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +250: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +251: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +252: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +253: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +254: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +255: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +256: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +257: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +258: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +259: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +260: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +261: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +262: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +263: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +264: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +265: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +266: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep updates manifest memory without disk write
00:14 +267: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +268: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +269: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +270: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +271: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +272: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +273: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +274: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +275: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +276: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +277: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +278: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +279: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +280: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Suggestion auto opens a review before mutating the mapping
00:14 +281: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry V2.1 new wizard save prep then saveProjectManifest writes disk
EditorNotifier: saveProjectManifest()
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/map_editor_v21_save_dgTRs4/project.json
00:15 +282: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_viewport_coordinate_test.dart: atlas viewport hit testing uses fitted image rect, not viewport width
00:15 +283: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_viewport_coordinate_test.dart: atlas viewport hit testing uses fitted image rect, not viewport width
00:15 +284: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart: Mistral analysis asks confirmation before any provider call
00:15 +285: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:15 +286: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:15 +287: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:15 +288: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +289: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +290: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +291: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +292: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +293: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +294: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +295: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +296: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +297: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +298: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +299: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +300: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +301: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +302: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +303: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +304: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +305: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +306: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +307: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +308: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +309: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas panel exposes zoom slider and column selection microcopy
00:16 +310: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 10. sync group water
00:16 +311: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas selection is draggable with a visible ghost payload
00:16 +312: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas selection is draggable with a visible ghost payload
00:16 +313: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas selection is draggable with a visible ghost payload
00:16 +314: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas selection is draggable with a visible ghost payload
00:16 +315: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas selection is draggable with a visible ghost payload
00:16 +316: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas selection is draggable with a visible ghost payload
00:17 +317: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas selection is draggable with a visible ghost payload
00:17 +318: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas selection is draggable with a visible ghost payload
00:17 +319: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas selection is draggable with a visible ghost payload
00:17 +320: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart: atlas selection is draggable with a visible ghost payload
00:17 +321: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:17 +322: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:17 +323: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:17 +324: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:17 +325: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 1. browser shows title Catalogue Surface
00:17 +326: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 2. empty catalog: global empty message
00:17 +327: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 3. empty catalog: per-section empty lines
00:17 +328: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 4. minimal catalog: section headers visible
00:17 +329: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 5. minimal catalog: atlas details (736-tile grid)
00:17 +330: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 6. minimal catalog: animation details
00:17 +331: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 7. minimal catalog: preset details
00:17 +332: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 8. full animation: sync group and category
00:17 +333: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 9. atlas used by two animations
00:17 +334: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 10. atlas unused
00:17 +335: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 11. animation referenced atlas ids deduped order
00:17 +336: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 12. preset referenced animation ids deduped order
00:17 +337: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 13. preset roles source order
00:17 +338: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 14. atlas order preserved
00:17 +339: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 15. animation order preserved
00:17 +340: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 16. preset order preserved
00:18 +341: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 17. order is list order not sortOrder
00:18 +342: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 18. browser in scrollable ancestor
00:18 +343: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 19. no TextField in browser
00:18 +344: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 20. browser has no active edit affordances
00:18 +345: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 21. no internal type names in UI
00:18 +346: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 24. error read model builds without throw
00:18 +347: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 25. derived row fields drive display
00:18 +348: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 28. builds without ProviderScope
00:18 +349: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 29. accepts bounded width
00:18 +350: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 30. public map_core only (import smoke)
00:18 +351: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 45. Lot 57 — browser integrates Animation Detail
00:18 +352: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 46. Lot 57 — browser integrates Preset Detail
00:18 +353: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 47. Lot 57 — browser keeps Atlas Detail
00:18 +354: All tests passed!
exit code: 0
```

## 20.10 Tests — Surface Painter

```text
commande exacte: bash -lc cd packages/map_editor && flutter test test/surface_painter --no-pub --reporter expanded
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_animation_frame_resolver_test.dart: resolveSurfaceAnimationFrameAtElapsedMs selects the first frame at elapsed zero
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
00:01 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart: Surface layer creation entry explicit surface layer ids and default names stay unique
00:01 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_catalog_availability_test.dart: SurfaceCatalogAvailability empty catalog explains the full Surface Studio sequence
00:01 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_catalog_availability_test.dart: SurfaceCatalogAvailability atlas without animation explains the next authoring step
00:01 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_catalog_availability_test.dart: SurfaceCatalogAvailability animations without preset explains the observed 84-ter blocker
00:01 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_catalog_availability_test.dart: SurfaceCatalogAvailability presets make the Surface Painter available
00:01 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_palette_panel_test.dart: SurfacePalettePanel empty palette shows catalog counts and next actions
00:01 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfaceToGameplayZoneDialog requires an encounter table id before confirming
00:01 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfaceToGameplayZoneDialog requires an encounter table id before confirming
00:01 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfaceToGameplayZoneDialog requires an encounter table id before confirming
00:01 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart: SurfaceToGameplayZoneDialog requires an encounter table id before confirming
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
exit code: 0
```

## 20.11 Analyze

```text
commande exacte: bash -lc cd packages/map_editor && flutter analyze lib/src/features/surface_studio lib/src/features/editor/application/editor_ai_settings.dart
Analyzing 2 items...                                            
No issues found! (ran in 2.0s)
exit code: 0
```

## 20.12 QA runtime

### commande

```text
cd packages/map_editor && flutter run -d macos
```

### console pertinente

```text
Launching lib/main.dart on macOS in debug mode...
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
2026-04-29 20:16:41.808 map_editor[88283:16550799] Running with merged UI and platform thread. Experimental.
Syncing files to device macOS...                                   332ms

Flutter run key commands.
r Hot reload.
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on macOS is available at: http://127.0.0.1:51752/2PJ9Wc61dKE=/
The Flutter DevTools debugger and profiler on macOS is available at: http://127.0.0.1:51752/2PJ9Wc61dKE=/devtools/?uri=ws://127.0.0.1:51752/2PJ9Wc61dKE=/ws
flutter: FileProjectRepository: Loading project from /Users/karim/Desktop/my_new_project/project.json
Application finished.
```

### observations

```text
preview active: non vérifié interactivement
alignement atlas: protégé par tests de fittedImageRect et hit-test, non vérifié manuellement
Mistral spinner: protégé par test widget fake pending, non vérifié manuellement
overflow console: aucun RenderFlex overflow dans la console capturée
limite: QA interactive complète impossible dans cet environnement
```

## 20.13 Auto-review

### fonctionnalité réelle

Le mapper utilise un système de coordonnées partagé. La sélection seule ne suffit pas; l’assignation center active réellement la preview.

### qualité coordonnées

La primitive pure protège contain rect, letterbox, hit-test colonne, hit-test frame, column viewport rect et source rect.

### qualité preview

La preview croppe des tiles réelles avec `drawImageRect`, alterne les colonnes center multiples et expose le source rect courant.

### qualité Mistral

Le provider envoie un vision pack calibré, un prompt V4, `reasoning_effort: high`, `json_schema`, `temperature: 0.1`, et valide strictement localement.

### qualité UI

Le mapper supprime la superposition Image widget + CustomPaint désynchronisée. La progress UI Mistral rend l’attente visible et bloque les doubles clics.

### risques restants

```text
- QA interactive réelle encore nécessaire sur la machine utilisateur.
- Les descripteurs locaux restent volontairement simples.
- Le contact sheet améliore l’entrée Mistral mais ne garantit pas une classification parfaite.
- Le ressenti “canvas greffé” doit encore être évalué visuellement sur l’app réelle.
```

### non-objectifs confirmés

```text
- aucun runtime ice/mud
- aucune glissade
- aucun movement cost
- aucune modification map_gameplay volontaire
- aucune modification map_runtime conservée
- aucune modification map_battle
- aucune dépendance gameplay à SurfaceLayer
- aucun SurfaceGameplayCatalog
```

## 20.14 Critique du prompt

```text
Ambiguïté : le prompt exige une QA interactive complète, mais l’environnement agent ne permet pas de manipuler visuellement l’app macOS lancée.
Décision : renforcer les tests de géométrie/pixels/widgets et documenter honnêtement la limite QA.
Ambiguïté : “effet canvas greffé” est qualitatif. Décision : corriger les causes techniques mesurables, surtout superposition désynchronisée et debug source rect manquant.
Ambiguïté : Mistral “se trompe systématiquement” peut venir du modèle ou de l’entrée visuelle. Décision : calibrer l’entrée avec contact sheet + descriptors + abstention stricte.
Suggestion lot suivant : faire une session QA humaine guidée avec capture écran ou test Playwright/macOS si l’éditeur expose une cible pilotable.
```

## 20.15 Git status final

```text
 M packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart
 M packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
 M packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
 M packages/map_gameplay/test/placed_elements_collision_test.dart
?? packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_view_geometry.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_vision_pack.dart
?? packages/map_editor/test/surface_studio/surface_studio_atlas_view_geometry_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_atlas_viewport_coordinate_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_mistral_prompt_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_mistral_vision_pack_test.dart
?? reports/surface/surface_studio_rebuild_v2_3_real_preview_mistral.md
?? reports/surface/surface_studio_rebuild_v2_4_coordinate_system_mistral_calibration.md
```

### explication du status final

```text
Les modifications map_editor Surface Studio listées correspondent aux lots V2.3/V2.4 non committés.
packages/map_gameplay/test/placed_elements_collision_test.dart était déjà modifié avant ce lot et n’a pas été touché par V2.4.
reports/surface/surface_studio_rebuild_v2_3_real_preview_mistral.md était déjà non suivi avant ce lot.
Le présent rapport V2.4 apparaît comme nouveau fichier non suivi.
```
