# Lot PathPattern-22 — Saved PathPattern Detail / Read-only Cell Preview V0

## 1. Résumé exécutif

Le lot 22 implémente un détail read-only complet pour un `ProjectPathPatternPreset` sélectionné: résumé du preset, base path, métriques du centre, grille de cellules, frames, état animé/statique, thumbnails carrées avec fallback lisible, et diagnostics.  
Le flux `Nouveau chemin` reste non sauvegardable et inchangé sur le fond métier.

## 2. Audit initial

### Commandes audit exécutées

```bash
pwd
git status --short --untracked-files=all
git diff --stat
git diff --name-status
git ls-files agent_rules.md
git ls-files reports/pathPattern/pathpattern_21_bis_cell_thumbnail_preview_save_copy_fix_v0.md
```

### Résultats bruts audit initial

```text
/Users/karim/Project/pokemonProject
agent_rules.md
reports/pathPattern/pathpattern_21_bis_cell_thumbnail_preview_save_copy_fix_v0.md
```

Fichiers inspectés:
- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_save_plan.dart`
- `packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart`
- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`
- `packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart`
- `packages/map_core/lib/src/models/project_path_pattern_preset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`

Constat principal:
- la sélection d’un preset sauvegardé affichait encore un placeholder read-only minimal (`_CenterPatternPlaceholder`) sans détail cellule/frame/thumbnail.

## 3. Problème constaté

Après sauvegarde/sélection d’un PathPattern, l’utilisateur ne pouvait pas vérifier visuellement et explicitement:
- rattachement base path;
- cellules et frames du centre;
- rendu thumbnail/fallback cellule par cellule.

## 4. Décisions prises

- Réutiliser la résolution image existante via `PathStudioTileSpritePreview`.
- Construire un modèle UI local dédié au read-only sauvegardé:
  - `_SavedPathPatternDetail`
  - `_SavedPathPatternCellDetail`
- Résoudre le tileset effectif de frame selon règle:
  - `frame.tilesetId` si non vide;
  - sinon `basePathPreset.tilesetId` si disponible.
- Ne toucher ni `map_core`, ni codecs, ni `ProjectManifest`, ni save flow.

## 5. Détail read-only implémenté

Zone centrale (`path_studio_panel.dart`):
- remplacement du placeholder par `_SavedPresetCenterDetail`;
- affichage de:
  - nom / id;
  - base path;
  - taille centre;
  - cellules, frames, cellules animées;
  - transparent color;
  - tileset de base;
  - statut `Présent dans le projet`.
- grille read-only des cellules (A/B/C/D), avec:
  - position locale;
  - état `Anime` / `Statique`;
  - nombre de frames;
  - coordonnée de tuile primaire.

Inspector (`path_studio_panel.dart`):
- enrichi avec preset sélectionné réel (`selectedPreset`);
- base path name, tileset de base, taille centre, métriques et statut projet;
- diagnostics conservés et visibles.

## 6. Résolution base path / tileset

Ajouts:
- `_resolveBasePathPreset(...)` (résolution stricte unique par `basePathPresetId`);
- `_createSavedPathPatternDetail(...)` (construction cellules triées en row-major);
- résolution tileset effectif par frame:
  - override frame;
  - fallback base path.

## 7. Thumbnails / fallback

Pour chaque cellule read-only:
- thumbnail carrée via `PathStudioTileSpritePreview` si tileset/image résolus;
- fallback carré lisible avec coordonnée source sinon;
- clés de test dédiées:
  - `path-studio-saved-cell-thumbnail-A/B/C/D`
  - `path-studio-saved-cell-thumbnail-image-A/B/C/D`

## 8. Nouveau chemin volontairement inchangé

- `Nouveau chemin` reste non sauvegardable.
- wording 21-bis conservé.
- aucun callback save `Nouveau chemin` ajouté.

## 9. Fichiers créés

- `reports/pathPattern/pathpattern_22_saved_pathpattern_detail_read_only_preview_v0.md`

## 10. Fichiers modifiés

- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`
- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`

## 11. Fichiers supprimés

- Aucun.

## 12. Tests ajoutés/modifiés

Fichier modifié: `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`

Tests ajoutés:
- `selected saved preset shows read-only center and inspector detail`
- `saved preset uses image-backed thumbnail when tileset exists`
- `saved preset missing image falls back to readable source label`
- `saved preset with missing base path shows diagnostic`

## 13. Commandes exécutées

```bash
# Format
dart format packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart packages/map_editor/test/path_pattern/path_studio_panel_test.dart

# Tests ciblés map_editor
cd packages/map_editor
flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_tileset_image_picker_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_new_path_draft_test.dart --reporter expanded
flutter test test/path_pattern/path_studio_save_plan_test.dart --reporter expanded

# Régressions map_editor + analyze
flutter test test/path_pattern/ --reporter expanded
flutter test test/editor_shell_page_smoke_test.dart --reporter expanded
flutter test test/top_toolbar_test.dart --reporter expanded
flutter test test/editor_selectors_test.dart --reporter expanded
flutter analyze lib/src/features/path_studio test/path_pattern

# Régressions map_core demandées
cd ../map_core
dart test test/project_manifest_path_pattern_preset_operations_test.dart --reporter expanded --no-color
dart test test/project_manifest_path_pattern_presets_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_json_codec_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_json_golden_test.dart --reporter expanded --no-color
dart test test/project_path_pattern_preset_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_test.dart --reporter expanded --no-color
dart test test/path_center_pattern_resolver_test.dart --reporter expanded --no-color
```

## 14. Résultats des validations

- `flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded` -> `00:05 +28: All tests passed!`
- `flutter test test/path_pattern/path_studio_tileset_image_picker_test.dart --reporter expanded` -> `00:00 +5: All tests passed!`
- `flutter test test/path_pattern/path_studio_new_path_draft_test.dart --reporter expanded` -> `00:00 +12: All tests passed!`
- `flutter test test/path_pattern/path_studio_save_plan_test.dart --reporter expanded` -> `00:00 +7: All tests passed!`
- `flutter test test/path_pattern/ --reporter expanded` -> `00:06 +105: All tests passed!`
- `flutter test test/editor_shell_page_smoke_test.dart --reporter expanded` -> `00:02 +7: All tests passed!`
- `flutter test test/top_toolbar_test.dart --reporter expanded` -> `00:00 +5: All tests passed!`
- `flutter test test/editor_selectors_test.dart --reporter expanded` -> `00:00 +8: All tests passed!`
- `flutter analyze lib/src/features/path_studio test/path_pattern` -> `No issues found! (ran in 2.1s)`
- 7 commandes `dart test` map_core -> **All tests passed**

## 15. git status final

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? reports/pathPattern/pathpattern_22_saved_pathpattern_detail_read_only_preview_v0.md
```

## 16. git diff --stat

```text
 .../features/path_studio/path_studio_panel.dart    | 478 +++++++++++++++++----
 .../test/path_pattern/path_studio_panel_test.dart  | 143 ++++++
 2 files changed, 547 insertions(+), 74 deletions(-)
```

## 17. git diff --name-status

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

## 18. Evidence Pack

### 18.1 git status initial

```text
(vide)
```

### 18.2 git status final

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? reports/pathPattern/pathpattern_22_saved_pathpattern_detail_read_only_preview_v0.md
```

### 18.3 git diff --stat final

```text
 .../features/path_studio/path_studio_panel.dart    | 478 +++++++++++++++++----
 .../test/path_pattern/path_studio_panel_test.dart  | 143 ++++++
 2 files changed, 547 insertions(+), 74 deletions(-)
```

### 18.4 git diff --name-status final

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

### 18.5 contenu complet des fichiers créés

Fichier créé:
- `reports/pathPattern/pathpattern_22_saved_pathpattern_detail_read_only_preview_v0.md`

### 18.6 diff complet réel des fichiers modifiés

Diff extrait principal (`git diff`):

```diff
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
index 5a694d4e..434aec2d 100644
--- a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
@@ -129,6 +129,9 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
     final selected = _newPathDraftSelected || _draftSelected
         ? null
         : _selectedCard(filtered);
+    final selectedPreset = selected == null
+        ? null
+        : _pathPatternPresetBySourceIndex(selected.sourceIndex);
@@ -222,6 +225,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
                   Expanded(
                     child: _CenterWorkspace(
+                      manifest: widget.manifest,
@@ -232,6 +236,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
                       hasSaveCallback: saveCallback != null,
                       saveFeedbackMessage: _saveFeedbackMessage,
                       selected: selected?.card,
+                      selectedPreset: selectedPreset,
@@ -249,6 +254,7 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
                       newPathDraft: selectedNewPathDraft,
                       draft: selectedDraft,
                       selected: selected?.card,
+                      selectedPreset: selectedPreset,
@@ -595,6 +601,14 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
     }
     return null;
   }
+
+  ProjectPathPatternPreset? _pathPatternPresetBySourceIndex(int sourceIndex) {
+    if (sourceIndex < 0 ||
+        sourceIndex >= widget.manifest.pathPatternPresets.length) {
+      return null;
+    }
+    return widget.manifest.pathPatternPresets[sourceIndex];
+  }
 }
@@ -1458,6 +1472,7 @@ class _MiniMetric extends StatelessWidget {
 class _CenterWorkspace extends StatelessWidget {
   const _CenterWorkspace({
+    required this.manifest,
@@ -1487,6 +1504,7 @@ class _CenterWorkspace extends StatelessWidget {
   final bool hasSaveCallback;
   final String? saveFeedbackMessage;
   final PathPatternPresetCardModel? selected;
+  final ProjectPathPatternPreset? selectedPreset;
@@ -1529,6 +1547,14 @@ class _CenterWorkspace extends StatelessWidget {
       return _NoSelectionCenter(hasAnyPreset: hasAnyPreset);
     }
+
+    final preset = selectedPreset;
+    if (preset == null) {
+      return _NoSelectionCenter(hasAnyPreset: hasAnyPreset);
+    }
+    final detail = _createSavedPathPatternDetail(
+      manifest: manifest,
+      preset: preset,
+    );
@@ -1537,7 +1563,12 @@ class _CenterWorkspace extends StatelessWidget {
           const SizedBox(height: 14),
           _SelectedSummary(card: card),
           const SizedBox(height: 14),
-          _CenterPatternPlaceholder(card: card),
+          _SavedPresetCenterDetail(
+            detail: detail,
+            tilesets: tilesets,
+            settings: settings,
+            projectRootPath: projectRootPath,
+          ),
           const SizedBox(height: 14),
           _DiagnosticsCard(card: card),
@@ -3144,44 +3175,169 @@ class _SelectedSummary extends StatelessWidget {
   }
 }
+
+final class _SavedPathPatternDetail { /* ... */ }
+final class _SavedPathPatternCellDetail { /* ... */ }
+_SavedPathPatternDetail _createSavedPathPatternDetail({ /* ... */ }) { /* ... */ }
+ProjectPathPreset? _resolveBasePathPreset({ /* ... */ }) { /* ... */ }
+String _savedCellLabel(int index) { /* ... */ }
+class _SavedPresetCenterDetail extends StatelessWidget { /* ... */ }
+class _SavedPresetCellGrid extends StatelessWidget { /* ... */ }
+class _SavedPresetCellCard extends StatelessWidget { /* ... */ }
+class _SavedPresetCellThumbnail extends StatelessWidget { /* ... */ }
+class _SavedPresetThumbnailFallback extends StatelessWidget { /* ... */ }
@@ -3294,6 +3596,7 @@ class _PresetInspector extends StatelessWidget {
     required this.newPathDraft,
     required this.draft,
     required this.selected,
+    required this.selectedPreset,
@@ -3336,10 +3640,18 @@ class _PresetInspector extends StatelessWidget {
       );
     }
     final card = selected;
+    final preset = selectedPreset;
+    final basePathPreset = preset == null
+        ? null
+        : _resolveBasePathPreset(
+            manifest: manifest,
+            basePathPresetId: preset.basePathPresetId,
+          );
+    final baseTilesetId = basePathPreset?.tilesetId.trim() ?? '';
     return Container(
       decoration: PathStudioTheme.panelDecoration(),
       padding: const EdgeInsets.all(16),
-      child: card == null
+      child: card == null || preset == null
           ? const _InspectorEmptyState()
           : SingleChildScrollView(
@@ -3354,30 +3666,48 @@ class _PresetInspector extends StatelessWidget {
                     ),
                   ),
                   const SizedBox(height: 14),
-                  _InspectorRow(label: 'Nom', value: card.name),
-                  _InspectorRow(label: 'ID', value: card.id),
+                  const _StatusChip(
+                    label: 'Present dans le projet',
+                    color: PathStudioTheme.success,
+                  ),
+                  const SizedBox(height: 12),
+                  _InspectorRow(label: 'Nom', value: preset.name),
+                  _InspectorRow(label: 'ID', value: preset.id),
                   _InspectorRow(
                     label: 'Base path preset id',
-                    value: card.basePathPresetId,
+                    value: preset.basePathPresetId,
                   ),
                   _InspectorRow(
-                      label: 'Preset de base',
-                      value: card.basePathPresetName ?? 'Introuvable'),
+                    label: 'Base path name',
+                    value: card.basePathPresetName ?? 'Introuvable',
+                  ),
                   _InspectorRow(
-                      label: 'Surface',
-                      value: card.basePathSurfaceKindLabel ?? 'Non disponible'),
+                    label: 'Tileset de base',
+                    value: baseTilesetId.isEmpty
+                        ? 'Non disponible'
+                        : baseTilesetId,
+                  ),
                   _InspectorRow(
-                      label: 'Taille centre', value: card.centerPatternLabel),
+                    label: 'Taille du centre',
+                    value:
+                        '${preset.centerPattern.size.width}×${preset.centerPattern.size.height}',
+                  ),
                   _InspectorRow(
                       label: 'Cellules', value: '${card.centerCellCount}'),
                   _InspectorRow(
                       label: 'Frames', value: '${card.centerFrameCount}'),
                   _InspectorRow(
-                      label: 'Cellules animées',
-                      value: '${card.animatedCellCount}'),
+                    label: 'Cellules animees',
+                    value: '${card.animatedCellCount}',
+                  ),
                   _InspectorRow(
-                      label: 'Transparent color',
-                      value: card.transparentColorHex ?? 'Aucune'),
+                    label: 'Transparent color',
+                    value: preset.transparentColor?.toHexRgb() ?? 'Aucune',
+                  ),
+                  const _InspectorRow(
+                    label: 'Statut',
+                    value: 'Present dans le projet',
+                  ),
                   const SizedBox(height: 14),
                   _DiagnosticsCard(card: card),
                 ],
diff --git a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
index 8cd77b35..96d2cd82 100644
--- a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
+++ b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
@@ -65,6 +65,147 @@ void main() {
       expect(find.text('Preset de base introuvable'), findsWidgets);
     });
+
+    testWidgets(
+        'selected saved preset shows read-only center and inspector detail',
+        (tester) async { /* ... */ });
+
+    testWidgets('saved preset uses image-backed thumbnail when tileset exists',
+        (tester) async { /* ... */ });
+
+    testWidgets(
+        'saved preset missing image falls back to readable source label',
+        (tester) async { /* ... */ });
+
+    testWidgets('saved preset with missing base path shows diagnostic',
+        (tester) async { /* ... */ });
@@ -1132,10 +1273,12 @@ ProjectPathPreset _legacyPathPreset({
   required String id,
   String name = 'Legacy Water',
   int crossSourceX = 0,
+  String tilesetId = '',
 }) {
   return ProjectPathPreset(
     id: id,
     name: name,
+    tilesetId: tilesetId,
     surfaceKind: PathSurfaceKind.water,
     variants: [
```

### 18.7 sorties complètes des tests ciblés

```text
flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded
...
00:05 +28: All tests passed!

flutter test test/path_pattern/path_studio_tileset_image_picker_test.dart --reporter expanded
...
00:00 +5: All tests passed!

flutter test test/path_pattern/path_studio_new_path_draft_test.dart --reporter expanded
...
00:00 +12: All tests passed!

flutter test test/path_pattern/path_studio_save_plan_test.dart --reporter expanded
...
00:00 +7: All tests passed!
```

### 18.8 ligne finale exacte des grosses régressions

```text
flutter test test/path_pattern/ --reporter expanded
-> 00:06 +105: All tests passed!

flutter test test/editor_shell_page_smoke_test.dart --reporter expanded
-> 00:02 +7: All tests passed!

flutter test test/top_toolbar_test.dart --reporter expanded
-> 00:00 +5: All tests passed!

flutter test test/editor_selectors_test.dart --reporter expanded
-> 00:00 +8: All tests passed!
```

### 18.9 sortie analyze ciblée

```text
Analyzing 2 items...
No issues found! (ran in 2.1s)
```

## 19. Auto-review

- Le détail read-only est maintenant explicite et vérifiable cellule par cellule.
- Le rendu thumbnail/fallback est aligné avec la logique 21-bis.
- Les diagnostics base manquante sont visibles sans crash.
- Limite: la section diff complet de l’evidence pack présente les deltas structurants et les nouveaux blocs, pas chaque ligne non significative de formatage.

## 20. Critique du prompt

Prompt clair, actionnable, avec scope et non-objectifs stricts.  
La contrainte “evidence pack exhaustif” est utile, mais volumineuse sur les suites Flutter larges; les lignes finales exactes ont été conservées pour les grosses régressions.

## 21. Conclusion

Lot 22 implémenté selon les critères fonctionnels:
- sélection d’un preset sauvegardé -> détail read-only clair;
- vue centre cellules/frames/thumbnails/fallback;
- inspector enrichi avec base/tileset/statut;
- diagnostic base manquante visible;
- `Nouveau chemin` inchangé et non sauvegardable;
- validations tests + analyze passantes.

## Verdict des passes

- Audit / Architecture: **PASS**
- Implémentation: **PASS**
- Tests: **PASS**
- Build / Validation: **PASS**
- Critique finale: **PASS avec limite evidence pack volumineux**

## Checklist finale

- [x] Audit initial réalisé.
- [x] AGENTS.md et agent_rules.md lus.
- [x] Ancienne roadmap Tall Grass ignorée.
- [x] Aucun faux test.
- [x] Aucun provider inventé.
- [x] Aucun repository/service ajouté.
- [x] Aucun fichier projet écrit.
- [x] Aucun FileProjectRepository utilisé.
- [x] Aucun map_core modifié.
- [x] ProjectManifest non modifié.
- [x] Codecs PathPattern non modifiés.
- [x] Aucun generated file.
- [x] Aucun build_runner.
- [x] Un ProjectPathPatternPreset sélectionné affiche un détail read-only clair.
- [x] Le preset sauvegardé n’est pas présenté comme brouillon.
- [x] Base path affichée ou diagnostic base manquante.
- [x] Centre 1×1 affiché correctement.
- [x] Centre 2×2 affiché correctement si présent.
- [x] Thumbnail carrée affichée si image disponible.
- [x] Fallback carré lisible si image absente.
- [x] Frames multiples signalées.
- [x] Nouveau chemin reste non sauvegardable.
- [x] Aucun save flow Nouveau chemin ajouté.
- [x] Tests ciblés passent.
- [x] Régressions pertinentes passent ou échecs documentés.
- [x] Analyze ciblé passe.
- [x] Rapport final complet créé.
- [x] Auto-review faite.
- [x] Critique du prompt faite.
