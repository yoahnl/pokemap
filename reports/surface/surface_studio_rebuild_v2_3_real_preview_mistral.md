# Surface Studio V2.3 — Make It Actually Work / Real Preview, Real Mapping, Mistral Reasoning & Native Integration

## 16.1 Verdict
V2.3 accepté côté implémentation locale et vérifications automatisées. Limite honnête : la QA runtime a lancé l’application macOS et chargé le projet réel, mais l’environnement shell non interactif n’a pas permis de manipuler visuellement les étapes Mapper/Suggestion dans l’app ouverte.

## 16.2 Audit initial
Commandes initiales obligatoires lancées depuis `/Users/karim/Project/pokemonProject` :
```text
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "SurfaceStudioPreviewPanel|SurfaceStudioRoleAssignmentDraft|SurfaceVariantRole.isolated|Plein|center|isolated|assignmentDraft|columnsForRole|onDrop|Image.memory|BoxFit.cover|buildSurfaceStudioMappingSuggestionPrompt|reasoning_effort|response_format|json_schema|mistral" packages/map_editor/lib/src/features/surface_studio packages/map_editor/test/surface_studio
rg -n "surfaceStudio.preview|surfaceStudio.schema.role.center|surfaceStudio.atlas.realImage|surfaceStudio.preview.realImage|Assignez au moins|Image source indisponible" packages/map_editor/lib packages/map_editor/test
```
Status initial réel observé via shell :
```text
 M packages/map_gameplay/test/placed_elements_collision_test.dart
```
Diff stat initial réel observé via shell :
```text
packages/map_gameplay/test/placed_elements_collision_test.dart | 1 +
```
Changement préexistant hors lot, non touché :
```text
diff --git a/packages/map_gameplay/test/placed_elements_collision_test.dart b/packages/map_gameplay/test/placed_elements_collision_test.dart
index f753d7b8..11372765 100644
--- a/packages/map_gameplay/test/placed_elements_collision_test.dart
+++ b/packages/map_gameplay/test/placed_elements_collision_test.dart
@@ -136,6 +136,7 @@ void main() {
             ),
           ),
         ],
+        surfaceCatalog: ProjectSurfaceCatalog(),
       );
       final world = GameplayWorldState.initial(
         map: _baseMap(
```
Findings audit :
- Cause preview vide : `SurfaceStudioPreviewPanel` ne recevait pas les dimensions de tuile/colonnes et rendait soit le message vide, soit une image complète/preview procédurale au lieu de croper les tiles assignées.
- Cause confusion sélection/assignation : `_selectedColumns` démarrait à 4-5, mais `_assignmentDraft` restait vide. La sélection visuelle ne mutait pas `SurfaceStudioRoleAssignmentDraft` tant qu’il n’y avait pas drop ou suggestion appliquée.
- Drag/drop réel : `_acceptDrop` met bien à jour `SurfaceStudioRoleAssignmentDraft`, avec `SurfaceVariantRole.isolated` multi-colonnes et les autres rôles mono-colonne.
- Mismatch UI/modèle : `Plein(center)` correspond au modèle `SurfaceVariantRole.isolated`. La preview doit donc lire `isolated`, pas un rôle `center` inexistant.
- Atlas mapper : `SurfaceStudioAtlasPanel` utilisait `BoxFit.cover`, et le painter de grille dessinait un faux atlas opaque même quand les bytes réels existaient.
- Prompt Mistral actuel : prompt court, pas de rôle français/technique complet, pas de consigne explicite de prudence visuelle, pas de schema JSON strict.
- Payload Mistral actuel : `temperature: 0`, `response_format: json_object`, pas de `reasoning_effort`, une seule image data URL.
- Tests insuffisants identifiés : les tests V2.2 vérifiaient surtout présence de widgets et confirmation IA, pas le fait que la preview disparaisse de l’état vide après assignation réelle.

## 16.3 Preview réelle
Le nouveau renderer `SurfaceStudioSurfacePreviewRenderer` décode les bytes atlas, résout `SurfaceVariantRole.isolated`, calcule un `sourceRect` exact et dessine la tile dans une grille `previewSize × previewSize`. Preview V2.3 minimale : si seul Plein(center)/isolated est assigné, toute la grille est remplie avec cette tile réelle et une bannière “Preview partielle : Plein(center)” reste visible.
Conversion protégée par test : colonnes UI 1-based ; atlas pixels 0-based. `sourceX = (uiColumn - 1) * tileWidth`, `sourceY = frameIndex * tileHeight`. Exemple testé : colonne UI 4, frame 1, tuile 8 donne `Rect.fromLTWH(24, 8, 8, 8)`.
Frame handling : `frameIndex` est clampé et utilisé pour choisir la ligne source. Les colonnes multiples isolated alternent aussi par frame via `centerColumns[frameIndex % centerColumns.length]`, ce qui rend le changement frame visible/testable même avec une preview partielle.
Fallbacks restants : sans bytes atlas, la preview affiche explicitement “Image source indisponible — aperçu illustratif.” Sans isolated assigné, le message “Assignez au moins le rôle Plein” reste affiché.

## 16.4 Mapping réel
Sélection et assignation sont maintenant exposées séparément dans l’atlas : `Colonnes sélectionnées : 4–5` et `Plein(center) : non assigné` avant mutation. Un bouton rapide `Utiliser comme Plein(center)` assigne la sélection à `SurfaceVariantRole.isolated` sans remplacer le drag/drop. Après assignation, le slot Plein affiche les chips 4/5 et la preview passe en état actif.
Suggestions IA/locales : une suggestion acceptée individuellement appelle maintenant `_applySingleSuggestion`, qui modifie le même `SurfaceStudioRoleAssignmentDraft` que le drag/drop et le bouton rapide. Les suggestions globales continuent de passer par `_applySuggestions`.
Propagation : `_columnRoleMappingDraft` lit toujours `_assignmentDraft`, donc Mapper, Prévisualiser et Enregistrer consomment le même mapping réel.

## 16.5 Mistral
Sources consultées : [Mistral API Specs](https://docs.mistral.ai/api), [Mistral Vision](https://docs.mistral.ai/capabilities/vision), [Mistral Chat Completions](https://docs.mistral.ai/studio-api/conversations/chat-completion).
Architecture : le lot garde `SurfaceStudioMistralMappingSuggester` derrière `SurfaceStudioAiMappingSuggester`, HTTP client injectable, sans appel réseau en tests. La clé vient toujours de `resolveEditorMistralApiKey(ProjectSettings?)` / `MISTRAL_API_KEY`, sans nouveau stockage.
Modèle par défaut : `mistral-small-latest`. Paramètres envoyés : `temperature: 0.1`, `reasoning_effort: high`, `response_format: json_schema` avec schéma strict. Si l’API refuse un champ selon modèle/endpoint, le chemin HTTP non-2xx retourne un warning sans mutation.
Images envoyées : une image atlas normalisée et une version annotée par grille, toutes deux en data URL base64. Le body ne contient ni clé ni chemin local projet.
Prompt final complet :
```dart
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
}) {
  final roles = surfaceStudioMistralAllowedRoleNames.join(', ');
  final roleLabels = surfaceStudioMistralRoleLabelMap.entries
      .map((entry) => '- ${entry.key} = ${entry.value}')
      .join('\n');
  return '''
You are analyzing a Pokémon-like animated surface atlas for a no-code map editor.
Take your time internally.
Use careful visual reasoning before answering.
Do not rush.
Do not guess when uncertain.
Return valid JSON only. No markdown. No prose outside JSON. Do not expose chain-of-thought.

Inspect the atlas as a grid:
- columns are visual variants
- rows are animation frames
- columns are 1-based in this UI
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

Validation rules:
- All column numbers must be between 1 and $columnCount.
- isolated may contain multiple columns.
- All other roles must contain at most one column.
- Do not invent roles.
- confidence must be exactly high, medium, or low.
- reason must be a short string for each assignment.
- warnings must be strings and should explain ambiguity.

Before producing JSON, internally verify:
1. All column numbers are within range.
2. isolated/center may contain multiple columns.
3. All other roles contain at most one column.
4. No role is invented.
5. Warnings explain ambiguity.
6. Output is valid JSON only.

Expected JSON schema:
{
  "assignments": [
    {
      "role": "isolated",
      "columns": [4, 5],
      "confidence": "high",
      "reason": "Columns 4 and 5 are full water tiles without shoreline and can repeat as center variants."
    }
  ],
  "warnings": [
    "Inner corners are not confidently visible."
  ]
}
''';
}

```
Validation JSON : rôles inconnus rejetés, colonnes hors bornes rejetées, multi-colonne hors `isolated` rejeté, confidence inconnue rejetée, JSON invalide converti en warning.
Confirmation utilisateur : l’UI conserve la confirmation “Confirmer l’analyse IA” avant tout appel provider et n’applique jamais automatiquement les suggestions.

## 16.6 Intégration UI
Changements concrets pour réduire l’effet canvas greffé :
- l’atlas réel est affiché en `BoxFit.contain`, plus en `cover`, pour éviter que les colonnes soient visuellement rognées ;
- le painter d’atlas ne dessine plus le faux atlas opaque quand une image réelle existe ; il devient grille/selection overlay ;
- la microcopy atlas devient une barre d’action utile avec état sélection/assignation et CTA direct ;
- la fausse preview eau procédurale a été retirée du panneau preview ;
- aucune croix de fermeture interne n’a été ajoutée ou restaurée ; le test existant continue de passer.
Le panneau global droit vide n’a pas été modifié dans ce lot parce que les tests V2.2/V2.3 confirment déjà que le right dock interne est absent hors Mapper. Aucun fichier shell global n’a été touché.

## 16.7 Fichiers créés/modifiés/supprimés
Fichiers créés :
- `packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart`
- `packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart`
- `packages/map_editor/test/surface_studio/surface_studio_mistral_prompt_test.dart`
Fichiers modifiés par V2.3 :
- `packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart`
- `packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart`
- `packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart`
- `packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart`
Fichiers supprimés : aucun.
Changement préexistant non touché : `packages/map_gameplay/test/placed_elements_collision_test.dart`.

## 16.8 Contenu complet des fichiers créés/modifiés
### packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart
```dart
import 'package:flutter/widgets.dart';

import '../surface_studio_design_tokens.dart';

class SurfaceStudioAtlasGridPainter extends CustomPainter {
  const SurfaceStudioAtlasGridPainter({
    required this.columnCount,
    required this.rowCount,
    required this.selectedColumns,
    required this.zoomPercent,
    this.drawFallbackSurface = true,
  });

  final int columnCount;
  final int rowCount;
  final List<int> selectedColumns;
  final double zoomPercent;
  final bool drawFallbackSurface;

  @override
  void paint(Canvas canvas, Size size) {
    if (drawFallbackSurface) {
      final bg = Paint()..color = const Color(0xFF102E70);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
        bg,
      );

      final columnWidth = size.width / columnCount;
      final stripePaint = Paint();
      for (var i = 0; i < columnCount; i++) {
        final rect =
            Rect.fromLTWH(i * columnWidth, 0, columnWidth, size.height);
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
            Rect.fromLTWH(
              rect.left + columnWidth * 0.72,
              0,
              columnWidth * 0.16,
              size.height,
            ),
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
    }

    final columnWidth = size.width / columnCount;
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
      oldDelegate.drawFallbackSurface != drawFallbackSurface ||
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
                          fit: BoxFit.contain,
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
                          drawFallbackSurface: atlasImageBytes == null,
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
import '../surface_studio_role_assignment_draft.dart';

ui.Rect surfaceStudioTileSourceRect({
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
  return ui.Rect.fromLTWH(
    (column - 1) * tileWidth.toDouble(),
    frame * tileHeight.toDouble(),
    tileWidth.toDouble(),
    tileHeight.toDouble(),
  );
}

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
    final tileColumn = centerColumns[frameIndex % centerColumns.length];
    final source = surfaceStudioTileSourceRect(
      uiColumn: tileColumn,
      frameIndex: frameIndex % safeFrameCount,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      frameCount: safeFrameCount,
    );
    final cellWidth = size.width / previewSize;
    final cellHeight = size.height / previewSize;
    final paint = Paint()..filterQuality = FilterQuality.none;
    for (var y = 0; y < previewSize; y++) {
      for (var x = 0; x < previewSize; x++) {
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
}) {
  final roles = surfaceStudioMistralAllowedRoleNames.join(', ');
  final roleLabels = surfaceStudioMistralRoleLabelMap.entries
      .map((entry) => '- ${entry.key} = ${entry.value}')
      .join('\n');
  return '''
You are analyzing a Pokémon-like animated surface atlas for a no-code map editor.
Take your time internally.
Use careful visual reasoning before answering.
Do not rush.
Do not guess when uncertain.
Return valid JSON only. No markdown. No prose outside JSON. Do not expose chain-of-thought.

Inspect the atlas as a grid:
- columns are visual variants
- rows are animation frames
- columns are 1-based in this UI
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

Validation rules:
- All column numbers must be between 1 and $columnCount.
- isolated may contain multiple columns.
- All other roles must contain at most one column.
- Do not invent roles.
- confidence must be exactly high, medium, or low.
- reason must be a short string for each assignment.
- warnings must be strings and should explain ambiguity.

Before producing JSON, internally verify:
1. All column numbers are within range.
2. isolated/center may contain multiple columns.
3. All other roles contain at most one column.
4. No role is invented.
5. Warnings explain ambiguity.
6. Output is valid JSON only.

Expected JSON schema:
{
  "assignments": [
    {
      "role": "isolated",
      "columns": [4, 5],
      "confidence": "high",
      "reason": "Columns 4 and 5 are full water tiles without shoreline and can repeat as center variants."
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

    final prompt = buildSurfaceStudioMappingSuggestionPrompt(
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      frameCount: frameCount,
    );
    final imageDataUrl = _imageDataUrl(imageBytes);
    final annotatedDataUrl = _annotatedImageDataUrl(
      imageBytes,
      columnCount: columnCount,
      frameCount: frameCount,
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
            {'type': 'image_url', 'image_url': imageDataUrl},
            {'type': 'image_url', 'image_url': annotatedDataUrl},
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

  String _annotatedImageDataUrl(
    Uint8List bytes, {
    required int columnCount,
    required int frameCount,
  }) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      decoded = null;
    }
    if (decoded == null) {
      return _imageDataUrl(bytes);
    }
    final longest =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    final annotated = longest > 1024
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? 1024 : null,
            height: decoded.height > decoded.width ? 1024 : null,
          )
        : img.Image.from(decoded);
    _drawGridOverlay(
      annotated,
      columns: columnCount,
      rows: frameCount,
      color: img.ColorRgba8(242, 200, 75, 210),
    );
    return 'data:image/png;base64,${base64Encode(img.encodePng(annotated))}';
  }

  void _drawGridOverlay(
    img.Image image, {
    required int columns,
    required int rows,
    required img.Color color,
  }) {
    final safeColumns = columns < 1 ? 1 : columns;
    final safeRows = rows < 1 ? 1 : rows;
    for (var column = 0; column <= safeColumns; column++) {
      final x = (column * image.width / safeColumns).round().clamp(
            0,
            image.width - 1,
          );
      for (var y = 0; y < image.height; y++) {
        image.setPixel(x, y, color);
      }
    }
    for (var row = 0; row <= safeRows; row++) {
      final y = (row * image.height / safeRows).round().clamp(
            0,
            image.height - 1,
          );
      for (var x = 0; x < image.width; x++) {
        image.setPixel(x, y, color);
      }
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
          'required': ['assignments', 'warnings'],
          'properties': {
            'assignments': {
              'type': 'array',
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': ['role', 'columns', 'confidence', 'reason'],
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
    await tester.tap(find.byKey(const Key('surfaceStudio.preview.next')));
    await tester.pumpAndSettle();
    expect(find.text('Frame 2 / 2'), findsOneWidget);
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
    expect(prompt, contains('Do not guess when uncertain'));
    expect(prompt, contains('columns are 1-based'));
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
    expect(jsonEncode(body), contains('Take your time internally'));
    expect(jsonEncode(body), contains('Do not guess when uncertain'));
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

## 16.9 Diffs complets
### packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart
```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart b/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart
index 521e0bd7..3913aa7b 100644
--- a/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart
@@ -8,56 +8,66 @@ class SurfaceStudioAtlasGridPainter extends CustomPainter {
     required this.rowCount,
     required this.selectedColumns,
     required this.zoomPercent,
+    this.drawFallbackSurface = true,
   });
 
   final int columnCount;
   final int rowCount;
   final List<int> selectedColumns;
   final double zoomPercent;
+  final bool drawFallbackSurface;
 
   @override
   void paint(Canvas canvas, Size size) {
-    final bg = Paint()..color = const Color(0xFF102E70);
-    canvas.drawRRect(
-      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
-      bg,
-    );
+    if (drawFallbackSurface) {
+      final bg = Paint()..color = const Color(0xFF102E70);
+      canvas.drawRRect(
+        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
+        bg,
+      );
 
-    final columnWidth = size.width / columnCount;
-    final stripePaint = Paint();
-    for (var i = 0; i < columnCount; i++) {
-      final rect = Rect.fromLTWH(i * columnWidth, 0, columnWidth, size.height);
-      final hue = i % 4;
-      stripePaint.color = switch (hue) {
-        0 => const Color(0xFF1C7DFF),
-        1 => const Color(0xFF2E8DFF),
-        2 => const Color(0xFFE15E91),
-        _ => const Color(0xFF2272DD),
-      };
-      canvas.drawRect(rect, stripePaint);
-      if (hue == 2) {
-        final shore = Paint()
-          ..color = const Color(0xFFE2D6C8).withValues(alpha: 0.72);
-        canvas.drawRect(
-          Rect.fromLTWH(rect.left + columnWidth * 0.72, 0, columnWidth * 0.16,
-              size.height),
-          shore,
-        );
+      final columnWidth = size.width / columnCount;
+      final stripePaint = Paint();
+      for (var i = 0; i < columnCount; i++) {
+        final rect =
+            Rect.fromLTWH(i * columnWidth, 0, columnWidth, size.height);
+        final hue = i % 4;
+        stripePaint.color = switch (hue) {
+          0 => const Color(0xFF1C7DFF),
+          1 => const Color(0xFF2E8DFF),
+          2 => const Color(0xFFE15E91),
+          _ => const Color(0xFF2272DD),
+        };
+        canvas.drawRect(rect, stripePaint);
+        if (hue == 2) {
+          final shore = Paint()
+            ..color = const Color(0xFFE2D6C8).withValues(alpha: 0.72);
+          canvas.drawRect(
+            Rect.fromLTWH(
+              rect.left + columnWidth * 0.72,
+              0,
+              columnWidth * 0.16,
+              size.height,
+            ),
+            shore,
+          );
+        }
       }
-    }
 
-    final waterLine = Paint()
-      ..color = const Color(0xFF7ACDFF).withValues(alpha: 0.18)
-      ..style = PaintingStyle.stroke
-      ..strokeWidth = 1.2;
-    for (var y = 14.0; y < size.height; y += 32) {
-      final path = Path()..moveTo(0, y);
-      for (var x = 0.0; x <= size.width; x += 24) {
-        path.quadraticBezierTo(x + 12, y - 8, x + 24, y);
+      final waterLine = Paint()
+        ..color = const Color(0xFF7ACDFF).withValues(alpha: 0.18)
+        ..style = PaintingStyle.stroke
+        ..strokeWidth = 1.2;
+      for (var y = 14.0; y < size.height; y += 32) {
+        final path = Path()..moveTo(0, y);
+        for (var x = 0.0; x <= size.width; x += 24) {
+          path.quadraticBezierTo(x + 12, y - 8, x + 24, y);
+        }
+        canvas.drawPath(path, waterLine);
       }
-      canvas.drawPath(path, waterLine);
     }
 
+    final columnWidth = size.width / columnCount;
     final gridPaint = Paint()
       ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.42)
       ..strokeWidth = 1;
@@ -96,6 +106,7 @@ class SurfaceStudioAtlasGridPainter extends CustomPainter {
       oldDelegate.columnCount != columnCount ||
       oldDelegate.rowCount != rowCount ||
       oldDelegate.zoomPercent != zoomPercent ||
+      oldDelegate.drawFallbackSurface != drawFallbackSurface ||
       !_listEquals(oldDelegate.selectedColumns, selectedColumns);
 }
 
```
### packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart b/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
index d4318eb8..323a9622 100644
--- a/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
@@ -19,6 +19,9 @@ class SurfaceStudioAtlasPanel extends StatelessWidget {
     required this.selection,
     required this.zoomPercent,
     required this.onColumnSelectionChanged,
+    required this.centerAssigned,
+    required this.centerColumns,
+    required this.onUseSelectionAsCenter,
     required this.onZoomChanged,
     required this.onReset,
     required this.onAutoSuggest,
@@ -31,8 +34,11 @@ class SurfaceStudioAtlasPanel extends StatelessWidget {
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
@@ -55,8 +61,11 @@ class SurfaceStudioAtlasPanel extends StatelessWidget {
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
@@ -86,8 +95,11 @@ class SurfaceStudioAtlasViewport extends StatelessWidget {
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
@@ -97,8 +109,11 @@ class SurfaceStudioAtlasViewport extends StatelessWidget {
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
@@ -166,7 +181,7 @@ class SurfaceStudioAtlasViewport extends StatelessWidget {
                         Image.memory(
                           atlasImageBytes!,
                           key: const ValueKey('surfaceStudio.atlas.realImage'),
-                          fit: BoxFit.cover,
+                          fit: BoxFit.contain,
                           gaplessPlayback: true,
                           errorBuilder: (_, __, ___) => const Center(
                             child: Text(
@@ -199,6 +214,7 @@ class SurfaceStudioAtlasViewport extends StatelessWidget {
                           rowCount: frameCount,
                           selectedColumns: selection.columns,
                           zoomPercent: zoomPercent,
+                          drawFallbackSurface: atlasImageBytes == null,
                         ),
                       ),
                     ],
@@ -223,21 +239,74 @@ class SurfaceStudioAtlasViewport extends StatelessWidget {
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
@@ -247,6 +316,16 @@ class SurfaceStudioAtlasViewport extends StatelessWidget {
   }
 }
 
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
index 67b3b4c6..ee8782fc 100644
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
@@ -122,21 +130,28 @@ class _PreviewViewport extends StatelessWidget {
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
     return Container(
       decoration: BoxDecoration(
         color: SurfaceStudioDesignTokens.backgroundDeep,
@@ -149,32 +164,17 @@ class _PreviewViewport extends StatelessWidget {
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
@@ -192,13 +192,12 @@ class _PreviewViewport extends StatelessWidget {
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
                   ),
-                  child: const SizedBox.expand(),
-                ),
               ],
             )
           : const Center(
@@ -219,6 +218,32 @@ class _PreviewViewport extends StatelessWidget {
   }
 }
 
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
@@ -489,56 +514,3 @@ class _CheckLine extends StatelessWidget {
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
### packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart
```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart b/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart
new file mode 100644
index 00000000..00000000
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart
@@ -0,0 +1,212 @@
+import 'dart:typed_data';
+import 'dart:ui' as ui;
+
+import 'package:flutter/widgets.dart';
+import 'package:map_core/map_core.dart';
+
+import '../surface_studio_design_tokens.dart';
+import '../surface_studio_role_assignment_draft.dart';
+
+ui.Rect surfaceStudioTileSourceRect({
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
+  return ui.Rect.fromLTWH(
+    (column - 1) * tileWidth.toDouble(),
+    frame * tileHeight.toDouble(),
+    tileWidth.toDouble(),
+    tileHeight.toDouble(),
+  );
+}
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
+    final tileColumn = centerColumns[frameIndex % centerColumns.length];
+    final source = surfaceStudioTileSourceRect(
+      uiColumn: tileColumn,
+      frameIndex: frameIndex % safeFrameCount,
+      tileWidth: tileWidth,
+      tileHeight: tileHeight,
+      columnCount: columnCount,
+      frameCount: safeFrameCount,
+    );
+    final cellWidth = size.width / previewSize;
+    final cellHeight = size.height / previewSize;
+    final paint = Paint()..filterQuality = FilterQuality.none;
+    for (var y = 0; y < previewSize; y++) {
+      for (var x = 0; x < previewSize; x++) {
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
### packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart
```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart
index af35bb48..6b904e5c 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart
@@ -1,4 +1,48 @@
-import 'package:map_core/map_core.dart';
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
@@ -6,38 +50,78 @@ String buildSurfaceStudioMappingSuggestionPrompt({
   required int columnCount,
   required int frameCount,
 }) {
-  final roles =
-      standardSurfaceVariantRoleOrder.map((role) => role.name).join(', ');
+  final roles = surfaceStudioMistralAllowedRoleNames.join(', ');
+  final roleLabels = surfaceStudioMistralRoleLabelMap.entries
+      .map((entry) => '- ${entry.key} = ${entry.value}')
+      .join('\n');
   return '''
-You are helping map a Pokemon-style surface atlas.
-Return JSON only. No markdown. No prose outside JSON.
+You are analyzing a Pokémon-like animated surface atlas for a no-code map editor.
+Take your time internally.
+Use careful visual reasoning before answering.
+Do not rush.
+Do not guess when uncertain.
+Return valid JSON only. No markdown. No prose outside JSON. Do not expose chain-of-thought.
+
+Inspect the atlas as a grid:
+- columns are visual variants
+- rows are animation frames
+- columns are 1-based in this UI
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
 
-Expected schema:
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
+
+Validation rules:
+- All column numbers must be between 1 and $columnCount.
+- isolated may contain multiple columns.
+- All other roles must contain at most one column.
+- Do not invent roles.
+- confidence must be exactly high, medium, or low.
+- reason must be a short string for each assignment.
+- warnings must be strings and should explain ambiguity.
+
+Before producing JSON, internally verify:
+1. All column numbers are within range.
+2. isolated/center may contain multiple columns.
+3. All other roles contain at most one column.
+4. No role is invented.
+5. Warnings explain ambiguity.
+6. Output is valid JSON only.
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
+      "reason": "Columns 4 and 5 are full water tiles without shoreline and can repeat as center variants."
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
index edbcce12..6344e66f 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
@@ -15,7 +15,7 @@ final class SurfaceStudioMistralMappingSuggester
   SurfaceStudioMistralMappingSuggester({
     http.Client? httpClient,
     this.baseUrl = 'https://api.mistral.ai/v1/chat/completions',
-    this.model = 'mistral-small-2506',
+    this.model = 'mistral-small-latest',
     this.timeout = const Duration(seconds: 30),
   }) : _client = httpClient ?? http.Client();
 
@@ -49,16 +49,23 @@ final class SurfaceStudioMistralMappingSuggester
       frameCount: frameCount,
     );
     final imageDataUrl = _imageDataUrl(imageBytes);
+    final annotatedDataUrl = _annotatedImageDataUrl(
+      imageBytes,
+      columnCount: columnCount,
+      frameCount: frameCount,
+    );
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
             {'type': 'image_url', 'image_url': imageDataUrl},
+            {'type': 'image_url', 'image_url': annotatedDataUrl},
           ],
         },
       ],
@@ -123,6 +130,110 @@ final class SurfaceStudioMistralMappingSuggester
     return 'data:image/png;base64,${base64Encode(img.encodePng(normalized))}';
   }
 
+  String _annotatedImageDataUrl(
+    Uint8List bytes, {
+    required int columnCount,
+    required int frameCount,
+  }) {
+    img.Image? decoded;
+    try {
+      decoded = img.decodeImage(bytes);
+    } catch (_) {
+      decoded = null;
+    }
+    if (decoded == null) {
+      return _imageDataUrl(bytes);
+    }
+    final longest =
+        decoded.width > decoded.height ? decoded.width : decoded.height;
+    final annotated = longest > 1024
+        ? img.copyResize(
+            decoded,
+            width: decoded.width >= decoded.height ? 1024 : null,
+            height: decoded.height > decoded.width ? 1024 : null,
+          )
+        : img.Image.from(decoded);
+    _drawGridOverlay(
+      annotated,
+      columns: columnCount,
+      rows: frameCount,
+      color: img.ColorRgba8(242, 200, 75, 210),
+    );
+    return 'data:image/png;base64,${base64Encode(img.encodePng(annotated))}';
+  }
+
+  void _drawGridOverlay(
+    img.Image image, {
+    required int columns,
+    required int rows,
+    required img.Color color,
+  }) {
+    final safeColumns = columns < 1 ? 1 : columns;
+    final safeRows = rows < 1 ? 1 : rows;
+    for (var column = 0; column <= safeColumns; column++) {
+      final x = (column * image.width / safeColumns).round().clamp(
+            0,
+            image.width - 1,
+          );
+      for (var y = 0; y < image.height; y++) {
+        image.setPixel(x, y, color);
+      }
+    }
+    for (var row = 0; row <= safeRows; row++) {
+      final y = (row * image.height / safeRows).round().clamp(
+            0,
+            image.height - 1,
+          );
+      for (var x = 0; x < image.width; x++) {
+        image.setPixel(x, y, color);
+      }
+    }
+  }
+
+  Map<String, Object?> _jsonSchemaResponseFormat() {
+    return {
+      'type': 'json_schema',
+      'json_schema': {
+        'name': 'surface_studio_mapping_suggestion',
+        'strict': true,
+        'schema': {
+          'type': 'object',
+          'additionalProperties': false,
+          'required': ['assignments', 'warnings'],
+          'properties': {
+            'assignments': {
+              'type': 'array',
+              'items': {
+                'type': 'object',
+                'additionalProperties': false,
+                'required': ['role', 'columns', 'confidence', 'reason'],
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
+  }
+
   SurfaceStudioMappingSuggestionResult _parseChatResponse(
     String body, {
     required int columnCount,
```
### packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
index ecfb349c..9470c0a1 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
@@ -632,6 +632,29 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
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
@@ -836,6 +859,7 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
                 mergeWithLocal: _mergeAiAfterConfirmation,
               ),
               onCompare: () => _requestAiSuggestion(mergeWithLocal: true),
+              onApplySuggestion: _applySingleSuggestion,
               onApplyReliable: () => _applySuggestions(reliableOnly: true),
               onApplyAll: () => _applySuggestions(reliableOnly: false),
             ),
@@ -912,10 +936,15 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
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
@@ -967,6 +996,9 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
             loop: _previewLoop,
             gridVisible: _previewGridVisible,
             previewSize: _previewSize,
+            tileWidth: _tileWidthValue,
+            tileHeight: _tileHeightValue,
+            columnCount: _columnCount,
             assignmentDraft: _assignmentDraft,
             atlasImageBytes: _atlasImageBytes(),
             atlasFallbackMessage: _atlasImageBytes() == null
@@ -1066,6 +1098,9 @@ class _SurfaceStudioScreenState extends State<SurfaceStudioScreen> {
             loop: _previewLoop,
             gridVisible: _previewGridVisible,
             previewSize: _previewSize,
+            tileWidth: _tileWidthValue,
+            tileHeight: _tileHeightValue,
+            columnCount: _columnCount,
             assignmentDraft: _assignmentDraft,
             atlasImageBytes: _atlasImageBytes(),
             atlasFallbackMessage: _atlasImageBytes() == null
@@ -1851,6 +1886,7 @@ class _SuggestionReviewScrim extends StatelessWidget {
     required this.onCancelAi,
     required this.onConfirmAi,
     required this.onCompare,
+    required this.onApplySuggestion,
     required this.onApplyReliable,
     required this.onApplyAll,
   });
@@ -1865,6 +1901,7 @@ class _SuggestionReviewScrim extends StatelessWidget {
   final VoidCallback onCancelAi;
   final VoidCallback onConfirmAi;
   final VoidCallback onCompare;
+  final ValueChanged<SurfaceStudioRoleSuggestion> onApplySuggestion;
   final VoidCallback onApplyReliable;
   final VoidCallback onApplyAll;
 
@@ -1913,7 +1950,10 @@ class _SuggestionReviewScrim extends StatelessWidget {
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
@@ -2077,9 +2117,13 @@ class _SuggestionReviewScrim extends StatelessWidget {
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
@@ -2117,6 +2161,19 @@ class _SuggestionRow extends StatelessWidget {
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
### packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart
```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart b/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart
new file mode 100644
index 00000000..00000000
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart
@@ -0,0 +1,157 @@
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
+    await tester.tap(find.byKey(const Key('surfaceStudio.preview.next')));
+    await tester.pumpAndSettle();
+    expect(find.text('Frame 2 / 2'), findsOneWidget);
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
### packages/map_editor/test/surface_studio/surface_studio_mistral_prompt_test.dart
```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_mistral_prompt_test.dart b/packages/map_editor/test/surface_studio/surface_studio_mistral_prompt_test.dart
new file mode 100644
index 00000000..00000000
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_mistral_prompt_test.dart
@@ -0,0 +1,84 @@
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
+    expect(prompt, contains('Do not guess when uncertain'));
+    expect(prompt, contains('columns are 1-based'));
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
+    expect(jsonEncode(body), contains('Take your time internally'));
+    expect(jsonEncode(body), contains('Do not guess when uncertain'));
+  });
+}
```
### packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart b/packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
index f3f84ab3..e8c6ac42 100644
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
@@ -242,3 +312,45 @@ final class _FakeAiSuggester implements SurfaceStudioAiMappingSuggester {
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
```

## 16.10 Tests
### cd packages/map_editor && flutter test test/surface_studio/surface_studio_mapper_preview_test.dart --no-pub --reporter expanded
```text
00:00 +0: tile source rect uses 1-based UI columns and 0-based atlas pixels
00:00 +1: selection alone is not mapping, quick center assignment activates preview
00:00 +2: preview frame controls change the rendered frame state
00:01 +3: All tests passed!
```
Résultat : PASS.
### cd packages/map_editor && flutter test test/surface_studio/surface_studio_mistral_prompt_test.dart --no-pub --reporter expanded
```text
00:00 +0: prompt asks for careful visual reasoning and documents roles exactly
00:00 +1: Mistral request uses high reasoning, schema output and no secret body
00:00 +2: All tests passed!
```
Résultat : PASS.
### cd packages/map_editor && flutter test test/surface_studio/surface_studio_mapping_suggestion_test.dart --no-pub --reporter expanded
```text
00:00 +0: local suggester returns bounded reviewable suggestions
00:00 +1: Suggestion auto opens a review before mutating the mapping
00:00 +2: Mistral prep detects configured key without displaying it
00:01 +3: Mistral analysis asks confirmation before any provider call
00:01 +4: accepted Mistral suggestion updates mapping and live preview
00:01 +5: Mistral suggester validates JSON without leaking secrets
00:01 +6: Mistral suggester returns a warning for invalid JSON
00:01 +7: All tests passed!
```
Résultat : PASS.
### cd packages/map_editor && flutter test test/surface_studio/surface_studio_rebuild_functional_integration_test.dart --no-pub --reporter expanded
```text
00:00 +0: Surface Studio renders one integrated wizard without legacy below
00:00 +1: new import step can create an atlas in the work catalog
00:01 +2: import and slice steps do not render schema or preview docks
00:01 +3: header has no internal close control
00:01 +4: All tests passed!
```
Résultat : PASS.
### cd packages/map_editor && flutter test test/surface_studio/surface_studio_rebuild_preview_controls_test.dart --no-pub --reporter expanded
```text
00:00 +0: preview panel exposes playback, scrub, loop grid and size controls
00:01 +1: All tests passed!
```
Résultat : PASS.
### cd packages/map_editor && flutter test test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart --no-pub --reporter expanded
```text
00:00 +0: SurfaceStudioAtlasImagePreview does not overflow in reported sizes
00:00 +1: All tests passed!
```
Résultat : PASS.
### cd packages/map_editor && flutter test test/surface_studio --no-pub --reporter expanded
```text
00:20 +345: All tests passed!
```
Résultat : PASS.
### cd packages/map_editor && flutter test test/surface_painter --no-pub --reporter expanded
```text
00:03 +71: All tests passed!
```
Résultat : PASS.
### cd packages/map_editor && flutter analyze lib/src/features/surface_studio lib/src/features/editor/application/editor_ai_settings.dart lib/src/features/dialogue/application/mistral_dialogue_client.dart
```text
Analyzing 3 items...
No issues found! (ran in 2.0s)
```
Résultat : PASS.

## 16.11 Analyze
Commande exacte :
```text
cd packages/map_editor && flutter analyze lib/src/features/surface_studio lib/src/features/editor/application/editor_ai_settings.dart lib/src/features/dialogue/application/mistral_dialogue_client.dart
```
Sortie exacte :
```text
Analyzing 3 items...
No issues found! (ran in 2.0s)
```
Résultat : PASS.

## 16.12 QA runtime
Commande lancée :
```text
cd packages/map_editor && flutter run -d macos
```
Console pertinente :
```text
Launching lib/main.dart on macOS in debug mode...
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
2026-04-29 19:35:35.975 map_editor[12072:16355039] Running with merged UI and platform thread. Experimental.
Syncing files to device macOS...                                   134ms

Flutter run key commands.
r Hot reload.
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on macOS is available at: http://127.0.0.1:62250/AUmgEu0VDQs=/
The Flutter DevTools debugger and profiler on macOS is available at: http://127.0.0.1:62250/AUmgEu0VDQs=/devtools/?uri=ws://127.0.0.1:62250/AUmgEu0VDQs=/ws
flutter: FileProjectRepository: Loading project from /Users/karim/Desktop/my_new_project/project.json
Lost connection to device.
```
Observations : l’app macOS a buildé, s’est connectée au device macOS et a chargé `/Users/karim/Desktop/my_new_project/project.json`. Aucune ligne `RenderFlex overflowed` n’est apparue dans la console capturée. La session shell n’était pas interactive, donc la QA visuelle complète Mapper/drag/suggestion n’a pas pu être pilotée dans cet environnement. Le process a été arrêté ensuite avec `pkill`, puis la session a rendu `Lost connection to device`.

## Context Mode / ctx
Context Mode MCP a été utilisé pendant l’audit initial avant reprise, selon le journal de session. La CLI locale `ctx` demandée en fin de lot est indisponible :
```text
zsh:1: command not found: ctx
```
Stats MCP disponibles dans ce rapport : non exposées par une CLI locale. Économie qualitative : recherches larges et audit initial ont été résumés hors conversation brute.

## 16.13 Auto-review
- Fonctionnalité réelle : oui pour le chemin critique Mapper `selection -> assignation isolated -> preview réelle`.
- Preview réelle : oui, via crop atlas `drawImageRect`, plus de preview eau procédurale quand bytes atlas existent.
- Mapping réel : oui, le bouton rapide, le drag/drop existant et les suggestions mutent `SurfaceStudioRoleAssignmentDraft`.
- Qualité Mistral : améliorée avec prompt prudent, rôles exacts, JSON schema, reasoning high et tests fake HTTP.
- Qualité UI : améliorée sur atlas/preview, mais la QA visuelle interactive complète reste à faire côté app ouverte.
- Risques restants : `response_format: json_schema` et `reasoning_effort: high` sont envoyés comme demandé ; si le modèle/endpoint Mistral choisi les refuse, le provider renverra un warning HTTP sans mutation. Une future passe peut ajouter fallback automatique `json_object` sur erreur 400.
- Non-objectifs confirmés : aucun fichier `map_gameplay` V2.3 touché, aucun `map_runtime`, aucun `map_battle`, aucun runtime ice/mud, aucune migration legacy, aucun gameplay ajouté.

## 16.14 Critique du prompt
Ambiguïté principale : “utiliser reasoning_effort high si supporté” dépend du modèle/endpoint Mistral courant. Le choix V2.3 envoie explicitement le champ et garde une validation locale stricte, sans exposer de raisonnement ni secret. Le prompt demande une version annotée avec numéros si possible ; V2.3 ajoute une grille annotée mais pas de numéros textuels, afin d’éviter une dépendance police/texte fragile. Le prochain lot pourrait ajouter une génération d’image annotée plus riche et un fallback automatique de payload Mistral si `json_schema` n’est pas accepté.

## 16.15 Git status final
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
Diff stat final :
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
Explication : toutes les lignes `packages/map_editor/...` et le rapport `reports/surface/surface_studio_rebuild_v2_3_real_preview_mistral.md` appartiennent à V2.3. La ligne `packages/map_gameplay/test/placed_elements_collision_test.dart` était préexistante et n’a pas été modifiée par ce lot.

## Périmètre explicitement non touché
- `map_gameplay` production non modifié.
- `map_runtime` non modifié.
- `map_battle` non modifié.
- `map_core` non modifié.
- Aucun runtime ice/mud, aucune glissade, aucun movement cost appliqué.
- Aucun `SurfaceLayer` gameplay, aucun `ProjectSurfacePreset` gameplay.
- Aucun appel réseau IA en tests ; faux client HTTP uniquement.
