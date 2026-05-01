# Lot PathPattern-17 — Image-backed Tileset Picker V0

## 1. Résumé exécutif

Lot 17 implémente un picker de tileset visuel dans Path Studio. Le flux `Nouveau chemin` conserve le brouillon local du Lot 16, mais si le `tilesetId` du draft pointe vers une image résoluble, Path Studio affiche maintenant la vraie image du tileset, superpose une grille calculée depuis `ProjectSettings.tileWidth/tileHeight`, et transforme un clic visuel en coordonnées de tuiles `sourceX/sourceY`. Les cellules A/B/C/D affichent une preview image quand possible. Si l’image est absente, illisible, ou si la racine projet manque, l’ancien picker logique reste disponible et fonctionne.

Le lot reste local à `map_editor`. Aucun fichier `map_core`, aucun `ProjectManifest`, aucun codec, aucune sauvegarde, aucun painter/runtime/gameplay/battle n’a été modifié.


## 2. Audit initial


- `Context Mode` : disponible et utilisé pour l’audit de fichiers et commandes volumineuses.

- État Git initial effectif avant modification Lot 17 : `git status --short --untracked-files=all` ne listait aucun fichier.

- `PathStudioPanel` recevait seulement `ProjectManifest`; il ne recevait pas encore `projectRootPath`.

- `PathStudioWorkspace` pouvait lire la racine projet via `editorProjectRootPathProvider`.

- `ProjectTilesetEntry` expose `id`, `name`, `relativePath`, mais pas `tileWidth/tileHeight`.

- Les dimensions de tuiles existent dans `ProjectSettings.tileWidth` et `ProjectSettings.tileHeight`.

- Le Lot 16 avait déjà `PathStudioNewPathDraftTile` avec `tilesetId`, `sourceX`, `sourceY`, et le fallback logique 8×4 dans `path_studio_panel.dart`.

- L’éditeur a déjà des usages de `editorProjectRootPathProvider` et de résolution de chemin tileset ailleurs, mais pas de composant Path Studio local directement réutilisable sans couplage à notifier/canvas.


## 3. État constaté avant travaux


- Le picker Lot 16 assignait bien des coordonnées logiques.

- Aucune image de tileset n’était affichée dans Path Studio.

- Aucune preview visuelle de tuile assignée n’était affichée dans les cellules du nouveau chemin.

- Le fallback logique existant devait être conservé pour CI, fichiers absents et projets incomplets.


## 4. Décisions prises


- Résolution image locale dans `map_editor`, sans service global et sans repository.

- `projectRootPath` est propagé de `PathStudioWorkspace` vers `PathStudioPanel` comme paramètre optionnel minimal.

- Source image = `projectRootPath + ProjectTilesetEntry.relativePath`.

- Dimensions grille = `ProjectSettings.tileWidth/tileHeight`; aucun hardcode 32×32.

- Décodage des dimensions via le package `image` déjà présent dans `map_editor`, puis rendu par `Image.memory`. Ce choix évite un blocage de `ui.decodeImageFromList` dans les tests widget fake-async et garde le V0 simple.

- `sourceX/sourceY` restent des coordonnées de tuiles, jamais des pixels.

- Si l’image échoue, le picker logique Lot 16 reste affiché avec message de fallback.

- Changer de tileset continue à vider les cellules configurées via la politique Lot 16 existante.


## 5. Implémentation détaillée


### Résolution image tileset


Nouveau fichier `path_studio_tileset_image_picker.dart` :


- `loadPathStudioTilesetImage(...)` valide la racine projet, le fichier image, les dimensions de tuile, décode les dimensions image, calcule `columns` et `rows`, puis retourne un résultat typé.

- `PathStudioTilesetImageStatus` distingue `missingProjectRoot`, `missingFile`, `invalidTileSize`, `invalidGrid`, `invalidImage`, `loaded`.

- `pathStudioTileSourceFromLocalPosition(...)` convertit un clic local dans le widget en `TilesetSourceRect(x, y)` en coordonnées de tuiles.


### Grille visuelle


- `PathStudioImageBackedTilesetPicker` affiche `Image.memory`, une grille superposée en `CustomPainter`, et un highlight de la tuile active si la cellule active a déjà une tuile assignée pour le tileset courant.

- Le clic sur l’image appelle le callback existant d’assignation de tuile, avec `source.x/source.y`.


### Preview cellule


- `_TilePreviewBadge` utilise maintenant `PathStudioTileSpritePreview` quand l’image est disponible.

- Si l’image ou le tileset ne peut pas être résolu, la cellule conserve le badge coordonnée texte du Lot 16.

- La preview recharge aussi si le même `tilesetId` change de `relativePath` ou de `name`, suite à la review séparée.


### Fallback logique


- L’ancienne grille logique 8×4 est extraite dans `_LogicalNewPathTileGrid`.

- Le fallback reste testable et assignable quand l’image est introuvable ou quand la racine projet manque.


## 6. Fichiers créés


- `packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart` : resolver image, widget image-backed picker, preview cellule.

- `packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart` : tests de résolution image, fallback fichier absent, conversion clic local -> coordonnée de tuile.

- `reports/pathPattern/pathpattern_17_image_backed_tileset_picker_v0.md` : présent rapport.


## 7. Fichiers modifiés


- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart` : propagation de `projectRootPath`, intégration du picker image, preview cellule image, fallback logique.

- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart` : tests widget image-backed picker, fallback image manquante, 2×2 complet, clear cellule, helper image temporaire.


## 8. Fichiers supprimés

Aucun fichier supprimé.


## 9. Tests ajoutés / modifiés


- Nouveau test pur `path_studio_tileset_image_picker_test.dart`.

- Tests widget ajoutés dans `path_studio_panel_test.dart` : image manquante -> fallback logique, image disponible -> picker visuel, assignation 1×1, remplissage 2×2, clear cellule.

- Les tests existants Lot 16 sur assignation logique, remplacement, clear, resize et changement de tileset restent présents.


## 10. Commandes exécutées


- `pwd`
- `git status --short --untracked-files=all`
- `git diff --stat`
- `git diff --name-status`
- `find packages/map_editor -name AGENTS.md -print`
- `rg/sed audits on Path Studio, ProjectManifest, editor selectors, tileset image usages`
- `dart format lib/src/features/path_studio/path_studio_panel.dart lib/src/features/path_studio/path_studio_tileset_image_picker.dart test/path_pattern/path_studio_panel_test.dart test/path_pattern/path_studio_tileset_image_picker_test.dart`
- `flutter test test/path_pattern/path_studio_tileset_image_picker_test.dart --reporter expanded`
- `flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded`
- `flutter test test/path_pattern/path_studio_new_path_draft_test.dart --reporter expanded`
- `flutter test test/path_pattern/path_pattern_draft_test.dart --reporter expanded`
- `flutter test test/path_pattern/ --reporter expanded`
- `flutter test test/editor_shell_page_smoke_test.dart --reporter expanded`
- `flutter test test/top_toolbar_test.dart --reporter expanded`
- `flutter test test/editor_selectors_test.dart --reporter expanded`
- `flutter analyze lib/src/features/path_studio test/path_pattern`
- `dart test test/project_manifest_path_pattern_preset_operations_test.dart --reporter expanded`
- `dart test test/project_manifest_path_pattern_presets_test.dart --reporter expanded`
- `dart test test/project_path_pattern_preset_json_codec_test.dart --reporter expanded`
- `dart test test/project_path_pattern_preset_json_golden_test.dart --reporter expanded`
- `dart test test/project_path_pattern_preset_test.dart --reporter expanded`
- `dart test test/path_center_pattern_test.dart --reporter expanded`
- `dart test test/path_center_pattern_resolver_test.dart --reporter expanded`
- `git status --short --untracked-files=all`
- `git diff --stat`
- `git diff --name-status`


## 11. Résultats des validations


- `flutter test test/path_pattern/path_studio_tileset_image_picker_test.dart --reporter expanded` : `+3`, All tests passed.

- `flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded` : `+19`, All tests passed.

- `flutter test test/path_pattern/path_studio_new_path_draft_test.dart --reporter expanded` : `+12`, All tests passed.

- `flutter test test/path_pattern/path_pattern_draft_test.dart --reporter expanded` : `+6`, All tests passed.

- `flutter test test/path_pattern/ --reporter expanded` : `+77`, All tests passed.

- `flutter test test/editor_shell_page_smoke_test.dart --reporter expanded` : `+7`, All tests passed.

- `flutter test test/top_toolbar_test.dart --reporter expanded` : `+5`, All tests passed.

- `flutter test test/editor_selectors_test.dart --reporter expanded` : `+8`, All tests passed.

- `flutter analyze lib/src/features/path_studio test/path_pattern` : No issues found.

- Régressions `map_core` PathPattern listées en Evidence Pack : toutes passées.


## 12. Limites connues / non-objectifs


- Pas de multi-frame, pas de timeline, pas de drag & drop, pas de zoom avancé.

- La preview cellule est un crop simple affiché par widget, pas un moteur de preview PNG.

- Le fallback logique reste une grille 8×4 de Lot 16 quand l’image est indisponible.

- Pas de sauvegarde : les assignations restent dans le draft local.

- Pas d’édition des bords, coins, jonctions ou autotile complet.


## 13. Review séparée


Reviewer sub-agent `Heisenberg` lancé en lecture seule. Résultat :


- Finding réel : `PathStudioTileSpritePreview` devait recharger si le même `tilesetId` changeait de `relativePath`. Correction appliquée via `_tilesetFingerprint(...)`, puis tests et analyze relancés.

- Finding écarté : le rapport Lot 17 non suivi était signalé comme hors scope par le reviewer, mais le prompt exige explicitement ce rapport dans `reports/pathPattern/`; il est donc intentionnel.

- Aucun finding bloquant sur `map_core`, save flow, mutation manifest, coordonnées de tuiles, fallback logique ou intention des tests.


## 14. Auto-review critique


- [x] Audit initial réalisé.
- [x] Git utilisé uniquement en lecture.
- [x] Aucun commit / push / reset / restore / stash / checkout.
- [x] map_core non modifié.
- [x] ProjectManifest non modifié.
- [x] Codecs PathPattern non modifiés.
- [x] Aucun generated file / build_runner.
- [x] Aucun save flow / mutation manifest.
- [x] Aucun painter / canvas editor render / runtime / gameplay / battle.
- [x] Aucun tall grass / Surface Studio / TSX / TMX.
- [x] Image tileset affichée si résoluble.
- [x] Grille visuelle affichée.
- [x] Clic sur image assigne une tuile.
- [x] sourceX/sourceY restent en coordonnées de tuiles.
- [x] Preview cellule affichée si image résoluble.
- [x] Fallback logique conservé.
- [x] 1×1 testé.
- [x] 2×2 testé.
- [x] Clear cellule testé.
- [x] Changement de tileset testé via régression Lot 16 conservée.
- [x] Tests ciblés passent.
- [x] Régressions pertinentes passent.
- [x] Analyze ciblé passe.
- [x] Rapport final créé dans reports/pathPattern/.


## 15. Critique du prompt


- Clair : le périmètre fonctionnel était bien borné autour d’un picker image, grille visuelle, assignation cellule active et fallback.

- Ambigu : “afficher via Image.memory” était formulé comme approche simple, mais pas comme obligation stricte; le choix final utilise effectivement `Image.memory`.

- Discutable : demander le contenu complet de tous les fichiers modifiés rend le rapport très long, surtout pour `path_studio_panel.dart` qui existait déjà avec plus de 3600 lignes. Le diff complet est plus utile pour review, mais le contenu complet est inclus pour respecter la consigne.

- À mieux borner : préciser si les tests widget doivent éviter `pumpAndSettle` avec images aiderait à gagner du temps. La stabilisation a nécessité un helper de pump fixe et du `tester.runAsync` pour les fichiers temporaires.

- Non optimal mais acceptable : le Lot 17 garde une partie de l’orchestration dans `path_studio_panel.dart`; une extraction plus large serait utile plus tard, mais aurait dépassé le lot.


## 16. Prochaine étape recommandée

Lot 18 pourrait transformer les tuiles assignées du draft en modèle prêt à sauvegarder, ou préparer une sauvegarde locale contrôlée vers `ProjectPathPreset` + `ProjectPathPatternPreset`, sans encore brancher painter/runtime.


## 17. Evidence Pack


### État Git final réel


### git status --short --untracked-files=all

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart
?? packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart
?? reports/pathPattern/pathpattern_17_image_backed_tileset_picker_v0.md
```


### git diff --stat

```text
 .../features/path_studio/path_studio_panel.dart    | 185 +++++++++++---
 .../test/path_pattern/path_studio_panel_test.dart  | 283 ++++++++++++++++++++-
 2 files changed, 425 insertions(+), 43 deletions(-)
```


### git diff --name-status

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```


### SHA-256 fichiers touchés

```text
513d5ce06e0e01ce8b9064d39574964919c56b0835916555a82a0763a97c9788  packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
25275da0115c2552b90ae5402a5490b685feee79c23cbde794a84f0efda940fc  packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart
565d05a7d63071a0c87afb2864969583e4c1fc995f024e22b97a12b23a00e67b  packages/map_editor/test/path_pattern/path_studio_panel_test.dart
f825da07f231c65bdb0b3a1c480dd9373bc622ba4a3a640d30037f79c12dc415  packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart
```


### Line counts fichiers touchés

```text
    3668 packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
     642 packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart
     923 packages/map_editor/test/path_pattern/path_studio_panel_test.dart
      89 packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart
    5322 total
```


### Sorties complètes tests ciblés et régressions


### flutter test test/path_pattern/path_studio_tileset_image_picker_test.dart --reporter expanded

```text
Waiting for another flutter command to release the startup lock...
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart
00:00 +0: PathStudioTilesetImagePicker image support resolves an image from project root and tileset relativePath
00:00 +1: PathStudioTilesetImagePicker image support returns a fallback status when the image file is absent
00:00 +2: PathStudioTilesetImagePicker image support converts a local click position to tile coordinates
00:00 +3: All tests passed!
```


### flutter test test/path_pattern/path_studio_panel_test.dart --reporter expanded

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:00 +0: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:00 +1: PathStudioPanel lists presets and updates summary and inspector selection
00:00 +2: PathStudioPanel filters presets locally and clears selection on no result
00:01 +3: PathStudioPanel creates a new path draft without legacy base presets
00:01 +4: PathStudioPanel new path draft does not force existing legacy path choices
00:01 +5: PathStudioPanel new path draft can select a project tileset
00:01 +6: PathStudioPanel new path draft stays usable when the project has no tileset
00:01 +7: PathStudioPanel assigns a tileset tile to the 1x1 active cell
00:01 +8: PathStudioPanel missing tileset image keeps the logical picker fallback
00:02 +9: PathStudioPanel image-backed tileset picker assigns the active cell
00:02 +10: PathStudioPanel image-backed picker fills all 2x2 cells and supports clear
00:02 +11: PathStudioPanel assigns independent tiles to all 2x2 center cells
00:03 +12: PathStudioPanel replaces and clears the active cell tile
00:03 +13: PathStudioPanel changing tileset clears configured center cells
00:03 +14: PathStudioPanel resizes the new path draft to 2x2 and selects a cell
00:03 +15: PathStudioPanel edits new path draft name and keeps save disabled
00:04 +16: PathStudioPanel secondary legacy flow changes inherited structure locally
00:04 +17: PathStudioPanel empty new path name shows a local diagnostic
00:04 +18: PathStudioPanel secondary legacy flow reports missing existing paths
00:04 +19: All tests passed!
```


### flutter test test/path_pattern/path_studio_new_path_draft_test.dart --reporter expanded

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
00:00 +0: PathStudioNewPathDraft creates an initial draft without a legacy ProjectPathPreset
00:00 +1: PathStudioNewPathDraft selects a tileset while preserving center size and selection
00:00 +2: PathStudioNewPathDraft assigns one V0 tile to the 1x1 cell and clears cell issue
00:00 +3: PathStudioNewPathDraft keeps cells issue until every 2x2 cell has one tile
00:00 +4: PathStudioNewPathDraft replaces a configured cell instead of adding a second frame
00:00 +5: PathStudioNewPathDraft clears a configured required cell and restores cell issue
00:00 +6: PathStudioNewPathDraft resizes a 1x1 draft to 2x2 while preserving cell A only
00:00 +7: PathStudioNewPathDraft resizes a 2x2 draft back to 1x1 and keeps only cell A
00:00 +8: PathStudioNewPathDraft selecting another tileset clears cell assignments deterministically
00:00 +9: PathStudioNewPathDraft renames the draft locally
00:00 +10: PathStudioNewPathDraft empty name after tileset selection exposes only remaining issues
00:00 +11: PathStudioNewPathDraft selects a placeholder cell by exact local coordinates
00:00 +12: All tests passed!
```


### flutter test test/path_pattern/path_pattern_draft_test.dart --reporter expanded

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_draft_test.dart
00:00 +0: PathPatternDraft creates an initial draft from the legacy cross center
00:00 +1: PathPatternDraft returns null when a manifest has no legacy base path preset
00:00 +2: PathPatternDraft resizes a 1x1 draft to a 2x2 center with copied cross frames
00:00 +3: PathPatternDraft resizes a 2x2 draft back to a valid 1x1 center
00:00 +4: PathPatternDraft changes base while preserving name and current size
00:00 +5: PathPatternDraft empty draft name exposes a local nameRequired issue
00:00 +6: All tests passed!
```


### flutter test test/path_pattern/ --reporter expanded

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel empty manifest exposes an empty summary and no cards
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel ready 1x1 preset exposes list card details
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel ready 2x2 transparent animated preset exposes counts
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel missing basePathPresetId blocks the card
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel duplicate PathPattern ids block every affected card
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel duplicate legacy base path preset ids block referencing cards
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel preserves manifest pathPatternPresets order
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel matches basePathPresetId exactly without trimming
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel ids that differ only by spaces are distinct exact ids
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel summary counts ready, blocked, duplicates, and multi-cell presets
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel read model and card lists are immutable defensive copies
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel read model, summary, and card use value equality
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: renderPathCenterPatternStaticPreviewPng renders a 1x1 preview from the first frame source tile
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: renderPathCenterPatternStaticPreviewPng renders a 2x2 preview in local cell positions
00:00 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: renderPathCenterPatternStaticPreviewPng applies optional transparentColor before composing preview
00:00 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: renderPathCenterPatternStaticPreviewPng keeps transparent-color-looking pixels opaque when color is null
00:00 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: renderPathCenterPatternStaticPreviewPng rejects source rects outside the tileset image
00:00 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: renderPathCenterPatternStaticPreviewPng rejects non-1x1 source rects in V0
00:00 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: renderPathCenterPatternStaticPreviewPng rejects invalid PNG bytes
00:00 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: renderPathCenterPatternStaticPreviewPng rejects non-positive tile dimensions
00:00 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart: PathStudioTilesetImagePicker image support resolves an image from project root and tileset relativePath
00:00 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart: PathStudioTilesetImagePicker image support returns a fallback status when the image file is absent
00:00 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart: PathStudioTilesetImagePicker image support converts a local click position to tile coordinates
00:00 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/tileset_transparent_color_processor_test.dart: applyTilesetTransparentColorToPngBytes returns the same bytes instance when transparentColor is null
00:00 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/tileset_transparent_color_processor_test.dart: applyTilesetTransparentColorToPngBytes turns matching RGB pixels transparent and preserves others
00:01 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_draft_test.dart: PathPatternDraft creates an initial draft from the legacy cross center
00:01 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_draft_test.dart: PathPatternDraft creates an initial draft from the legacy cross center
00:01 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_draft_test.dart: PathPatternDraft creates an initial draft from the legacy cross center
00:01 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_draft_test.dart: PathPatternDraft creates an initial draft from the legacy cross center
00:01 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_draft_test.dart: PathPatternDraft creates an initial draft from the legacy cross center
00:01 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:02 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:02 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel creates a new path draft without legacy base presets
00:02 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel new path draft does not force existing legacy path choices
00:02 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel new path draft can select a project tileset
00:02 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel new path draft stays usable when the project has no tileset
00:02 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel assigns a tileset tile to the 1x1 active cell
00:03 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel missing tileset image keeps the logical picker fallback
00:03 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel image-backed tileset picker assigns the active cell
00:03 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel image-backed picker fills all 2x2 cells and supports clear
00:04 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel assigns independent tiles to all 2x2 center cells
00:04 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel replaces and clears the active cell tile
00:04 +71: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel changing tileset clears configured center cells
00:05 +72: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel resizes the new path draft to 2x2 and selects a cell
00:05 +73: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel edits new path draft name and keeps save disabled
00:05 +74: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel secondary legacy flow changes inherited structure locally
00:05 +75: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel empty new path name shows a local diagnostic
00:05 +76: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel secondary legacy flow reports missing existing paths
00:05 +77: All tests passed!
```


### flutter test test/editor_shell_page_smoke_test.dart --reporter expanded

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart
00:00 +0: EditorShellPage smoke renders map workspace chrome and toggles the right panel
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +1: EditorShellPage smoke updates the workspace header for tileset mode
00:01 +2: EditorShellPage smoke renders the trainer studio workspace chrome
FileProjectRepository: Loading project from /tmp/editor_shell_trainer/project.json
00:01 +3: EditorShellPage smoke renders the Pokémon catalogs workspace shell
00:01 +4: EditorShellPage smoke renders the Items catalogs workspace shell
00:01 +5: EditorShellPage smoke opens Path Studio from the project explorer
00:02 +6: EditorShellPage smoke renders shell chrome with an error state already present
00:02 +7: All tests passed!
```


### flutter test test/top_toolbar_test.dart --reporter expanded

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart
00:00 +0: TopToolbar shows the app brand and project workspace label
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +1: TopToolbar falls back to the workspace label when no project is loaded
00:00 +2: TopToolbar shows the toolbar status chip when a status is present
00:00 +3: TopToolbar shows the trainer studio label for the trainer workspace
00:00 +4: TopToolbar disables map save and history actions in Path Studio
00:00 +5: All tests passed!
```


### flutter test test/editor_selectors_test.dart --reporter expanded

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_selectors_test.dart
00:00 +0: editor selectors editorShellSnapshotProvider derives map title and save affordance
00:00 +1: editor selectors editorToolbarSnapshotProvider resolves selected tileset from layer
00:00 +2: editor selectors Path Studio snapshots hide map save and history actions
00:00 +3: editor selectors editorProjectExplorerSnapshotProvider exposes active map selection
00:00 +4: editor selectors editorShellSnapshotProvider exposes trainer studio labels
00:00 +5: editor selectors editorShellSnapshotProvider exposes Pokémon catalogs labels
00:00 +6: editor selectors editorTerrainLibrarySnapshotProvider exposes preset selection inputs
00:00 +7: editor selectors editorTilesetPaletteSnapshotProvider exposes palette panel state
00:00 +8: All tests passed!
```


### flutter analyze lib/src/features/path_studio test/path_pattern

```text
Analyzing 2 items...                                            
No issues found! (ran in 2.1s)
```


### dart test test/project_manifest_path_pattern_preset_operations_test.dart --reporter expanded

```text
00:00 [32m+0[0m: [1m[90mloading test/project_manifest_path_pattern_preset_operations_test.dart[0m[0m
00:00 [32m+0[0m: ProjectManifest PathPattern preset operations read returns the manifest pathPatternPresets in order[0m
00:00 [32m+1[0m: ProjectManifest PathPattern preset operations replace swaps the list, preserves other fields, and keeps order[0m
00:00 [32m+2[0m: ProjectManifest PathPattern preset operations replace accepts an empty list and rejects duplicate exact ids[0m
00:00 [32m+3[0m: ProjectManifest PathPattern preset operations replace treats ids with different whitespace as distinct ids[0m
00:00 [32m+4[0m: ProjectManifest PathPattern preset operations upsert appends a new preset at the end[0m
00:00 [32m+5[0m: ProjectManifest PathPattern preset operations upsert replaces an existing preset in place[0m
00:00 [32m+6[0m: ProjectManifest PathPattern preset operations upsert rejects ambiguous existing duplicate ids[0m
00:00 [32m+7[0m: ProjectManifest PathPattern preset operations remove deletes an existing id and preserves order[0m
00:00 [32m+8[0m: ProjectManifest PathPattern preset operations remove missing id is a no-op with an equivalent new manifest[0m
00:00 [32m+9[0m: ProjectManifest PathPattern preset operations remove rejects blank ids and duplicate matching ids[0m
00:00 [32m+10[0m: ProjectManifest PathPattern preset operations clear removes all path pattern presets without mutating original[0m
00:00 [32m+11[0m: ProjectManifest PathPattern preset operations lookup helpers find exact ids, report missing ids, and reject blanks[0m
00:00 [32m+12[0m: ProjectManifest PathPattern preset operations lookup helpers reject duplicate exact ids[0m
00:00 [32m+13[0m: ProjectManifest PathPattern preset operations operations keep pathPatternPresets JSON stable[0m
00:00 [32m+14[0m: All tests passed![0m
```


### dart test test/project_manifest_path_pattern_presets_test.dart --reporter expanded

```text
00:00 [32m+0[0m: [1m[90mloading test/project_manifest_path_pattern_presets_test.dart[0m[0m
00:00 [32m+0[0m: ProjectManifest pathPatternPresets decodes old manifests without pathPatternPresets as empty[0m
00:00 [32m+1[0m: ProjectManifest pathPatternPresets decodes pathPatternPresets null as empty[0m
00:00 [32m+2[0m: ProjectManifest pathPatternPresets decodes and encodes empty pathPatternPresets stably[0m
00:00 [32m+3[0m: ProjectManifest pathPatternPresets decodes the Lot 9 minimal golden through ProjectManifest[0m
00:00 [32m+4[0m: ProjectManifest pathPatternPresets decodes the Lot 9 complete golden through ProjectManifest[0m
00:00 [32m+5[0m: ProjectManifest pathPatternPresets roundtrips manifest pathPatternPresets without changing order[0m
00:00 [32m+6[0m: ProjectManifest pathPatternPresets does not migrate legacy pathPresets into pathPatternPresets[0m
00:00 [32m+7[0m: ProjectManifest pathPatternPresets rejects invalid pathPatternPresets payloads[0m
00:00 [32m+8[0m: All tests passed![0m
```


### dart test test/project_path_pattern_preset_json_codec_test.dart --reporter expanded

```text
00:00 [32m+0[0m: [1m[90mloading test/project_path_pattern_preset_json_codec_test.dart[0m[0m
00:00 [32m+0[0m: ProjectPathPatternPreset JSON codec encodes a minimal preset[0m
00:00 [32m+1[0m: ProjectPathPatternPreset JSON codec decodes a minimal preset[0m
00:00 [32m+2[0m: ProjectPathPatternPreset JSON codec roundtrips a minimal preset[0m
00:00 [32m+3[0m: ProjectPathPatternPreset JSON codec encodes a complete 2x2 preset in row-major cell order[0m
00:00 [32m+4[0m: ProjectPathPatternPreset JSON codec roundtrips a complete 2x2 preset[0m
00:00 [32m+5[0m: ProjectPathPatternPreset JSON codec canonicalizes transparentColor after decode and encode[0m
00:00 [32m+6[0m: ProjectPathPatternPreset JSON codec roundtrips frame tileset overrides[0m
00:00 [32m+7[0m: ProjectPathPatternPreset JSON codec roundtrips null and non-null frame durations[0m
00:00 [32m+8[0m: ProjectPathPatternPreset JSON codec rejects invalid JSON[0m
00:00 [32m+9[0m: All tests passed![0m
```


### dart test test/project_path_pattern_preset_json_golden_test.dart --reporter expanded

```text
00:00 [32m+0[0m: [1m[90mloading test/project_path_pattern_preset_json_golden_test.dart[0m[0m
00:00 [32m+0[0m: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden decodes to the expected preset[0m
00:00 [32m+1[0m: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden matches encode output[0m
00:00 [32m+2[0m: ProjectPathPatternPreset JSON golden samples complete 2x2 golden decodes to the expected preset[0m
00:00 [32m+3[0m: ProjectPathPatternPreset JSON golden samples complete 2x2 golden matches encode output[0m
00:00 [32m+4[0m: ProjectPathPatternPreset JSON golden samples goldens roundtrip through decode and encode[0m
00:00 [32m+5[0m: ProjectPathPatternPreset JSON golden samples goldens use two-space canonical formatting with final newline[0m
00:00 [32m+6[0m: All tests passed![0m
```


### dart test test/project_path_pattern_preset_test.dart --reporter expanded

```text
00:00 [32m+0[0m: [1m[90mloading test/project_path_pattern_preset_test.dart[0m[0m
00:00 [32m+0[0m: ProjectPathPatternPreset creates a minimal preset with defaults[0m
00:00 [32m+1[0m: ProjectPathPatternPreset creates a complete preset with a 2x2 center pattern[0m
00:00 [32m+2[0m: ProjectPathPatternPreset rejects blank identity fields[0m
00:00 [32m+3[0m: ProjectPathPatternPreset validates with trim but stores original strings[0m
00:00 [32m+4[0m: ProjectPathPatternPreset supports value equality and stable hashCode[0m
00:00 [32m+5[0m: All tests passed![0m
```


### dart test test/path_center_pattern_test.dart --reporter expanded

```text
00:00 [32m+0[0m: [1m[90mloading test/path_center_pattern_test.dart[0m[0m
00:00 [32m+0[0m: PathCenterPatternSize accepts 1x1 and 2x2 sizes[0m
00:00 [32m+1[0m: PathCenterPatternSize rejects non-positive dimensions[0m
00:00 [32m+2[0m: PathCenterPatternSize reports tile count and coordinate containment[0m
00:00 [32m+3[0m: PathCenterPatternSize uses value equality and stable hashCode[0m
00:00 [32m+4[0m: PathCenterPatternCell accepts non-negative local coordinates and frames[0m
00:00 [32m+5[0m: PathCenterPatternCell rejects negative coordinates and empty frames[0m
00:00 [32m+6[0m: PathCenterPatternCell defensively copies frames and exposes an immutable list[0m
00:00 [32m+7[0m: PathCenterPatternCell uses value equality and stable hashCode[0m
00:00 [32m+8[0m: PathCenterPattern 1x1 accepts a complete single-cell grid[0m
00:00 [32m+9[0m: PathCenterPattern 2x2 accepts a complete grid and exposes cells in row-major order[0m
00:00 [32m+10[0m: PathCenterPattern 2x2 defensively copies cells and exposes an immutable list[0m
00:00 [32m+11[0m: PathCenterPattern 2x2 uses value equality and stable hashCode[0m
00:00 [32m+12[0m: PathCenterPattern invalid grids rejects an empty cell list[0m
00:00 [32m+13[0m: PathCenterPattern invalid grids rejects a missing cell[0m
00:00 [32m+14[0m: PathCenterPattern invalid grids rejects a cell outside the grid[0m
00:00 [32m+15[0m: PathCenterPattern invalid grids rejects duplicate coordinates[0m
00:00 [32m+16[0m: PathCenterPattern invalid grids cellAt rejects coordinates outside the grid[0m
00:00 [32m+17[0m: All tests passed![0m
```


### dart test test/path_center_pattern_resolver_test.dart --reporter expanded

```text
00:00 [32m+0[0m: [1m[90mloading test/path_center_pattern_resolver_test.dart[0m[0m
00:00 [32m+0[0m: resolvePathCenterPatternCell 1x1 always resolves to the single local cell[0m
00:00 [32m+1[0m: resolvePathCenterPatternCell 2x2 uses absolute map coordinates modulo pattern size[0m
00:00 [32m+2[0m: resolvePathCenterPatternCell rectangular 3x2 does not assume square patterns[0m
00:00 [32m+3[0m: resolvePathCenterPatternCell invalid coordinates rejects negative map coordinates[0m
00:00 [32m+4[0m: PathCenterPatternCellResolution keeps map coordinates, local coordinates, and selected cell[0m
00:00 [32m+5[0m: PathCenterPatternCellResolution uses value equality and stable hashCode[0m
00:00 [32m+6[0m: All tests passed![0m
```


### Diff complet réel des fichiers modifiés


### git diff -- packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart packages/map_editor/test/path_pattern/path_studio_panel_test.dart

```diff
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
index bad7b526..b783aa2d 100644
--- a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
@@ -8,6 +8,7 @@ import 'path_pattern_draft.dart';
 import 'path_pattern_editor_read_model.dart';
 import 'path_studio_new_path_draft.dart';
 import 'path_studio_theme.dart';
+import 'path_studio_tileset_image_picker.dart';
 
 /// Workspace branché au shell global de l'éditeur.
 ///
@@ -20,10 +21,14 @@ class PathStudioWorkspace extends ConsumerWidget {
   @override
   Widget build(BuildContext context, WidgetRef ref) {
     final manifest = ref.watch(editorProjectManifestProvider);
+    final projectRootPath = ref.watch(editorProjectRootPathProvider);
     if (manifest == null) {
       return const _PathStudioProjectMissingState();
     }
-    return PathStudioPanel(manifest: manifest);
+    return PathStudioPanel(
+      manifest: manifest,
+      projectRootPath: projectRootPath,
+    );
   }
 }
 
@@ -37,9 +42,11 @@ class PathStudioPanel extends StatefulWidget {
   const PathStudioPanel({
     super.key,
     required this.manifest,
+    this.projectRootPath,
   });
 
   final ProjectManifest manifest;
+  final String? projectRootPath;
 
   @override
   State<PathStudioPanel> createState() => _PathStudioPanelState();
@@ -150,6 +157,8 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
                   Expanded(
                     child: _CenterWorkspace(
                       tilesets: widget.manifest.tilesets,
+                      settings: widget.manifest.settings,
+                      projectRootPath: widget.projectRootPath,
                       newPathDraft: selectedNewPathDraft,
                       draft: selectedDraft,
                       selected: selected?.card,
@@ -1255,6 +1264,8 @@ class _MiniMetric extends StatelessWidget {
 class _CenterWorkspace extends StatelessWidget {
   const _CenterWorkspace({
     required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.newPathDraft,
     required this.draft,
     required this.selected,
@@ -1268,6 +1279,8 @@ class _CenterWorkspace extends StatelessWidget {
   });
 
   final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraft? newPathDraft;
   final PathPatternDraft? draft;
   final PathPatternPresetCardModel? selected;
@@ -1285,6 +1298,8 @@ class _CenterWorkspace extends StatelessWidget {
     if (newPathDraft != null) {
       return _NewPathCenterWorkspace(
         tilesets: tilesets,
+        settings: settings,
+        projectRootPath: projectRootPath,
         draft: newPathDraft,
         onSizeChanged: onNewPathSizeChanged,
         onCellSelected: onNewPathCellSelected,
@@ -1325,6 +1340,8 @@ class _CenterWorkspace extends StatelessWidget {
 class _NewPathCenterWorkspace extends StatelessWidget {
   const _NewPathCenterWorkspace({
     required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.draft,
     required this.onSizeChanged,
     required this.onCellSelected,
@@ -1333,6 +1350,8 @@ class _NewPathCenterWorkspace extends StatelessWidget {
   });
 
   final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraft draft;
   final void Function(int width, int height) onSizeChanged;
   final void Function(int localX, int localY) onCellSelected;
@@ -1353,6 +1372,8 @@ class _NewPathCenterWorkspace extends StatelessWidget {
           const SizedBox(height: 14),
           _NewPathCenterPatternEditor(
             tilesets: tilesets,
+            settings: settings,
+            projectRootPath: projectRootPath,
             draft: draft,
             onSizeChanged: onSizeChanged,
             onCellSelected: onCellSelected,
@@ -1460,6 +1481,8 @@ class _NewPathSummary extends StatelessWidget {
 class _NewPathCenterPatternEditor extends StatelessWidget {
   const _NewPathCenterPatternEditor({
     required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.draft,
     required this.onSizeChanged,
     required this.onCellSelected,
@@ -1468,6 +1491,8 @@ class _NewPathCenterPatternEditor extends StatelessWidget {
   });
 
   final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraft draft;
   final void Function(int width, int height) onSizeChanged;
   final void Function(int localX, int localY) onCellSelected;
@@ -1516,6 +1541,9 @@ class _NewPathCenterPatternEditor extends StatelessWidget {
           ),
           const SizedBox(height: 18),
           _NewPathPatternGrid(
+            tilesets: tilesets,
+            settings: settings,
+            projectRootPath: projectRootPath,
             draft: draft,
             onCellSelected: onCellSelected,
           ),
@@ -1527,6 +1555,8 @@ class _NewPathCenterPatternEditor extends StatelessWidget {
           const SizedBox(height: 14),
           _NewPathTilePickerPanel(
             tilesets: tilesets,
+            settings: settings,
+            projectRootPath: projectRootPath,
             draft: draft,
             onTileSelected: onTileSelected,
           ),
@@ -1538,10 +1568,16 @@ class _NewPathCenterPatternEditor extends StatelessWidget {
 
 class _NewPathPatternGrid extends StatelessWidget {
   const _NewPathPatternGrid({
+    required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.draft,
     required this.onCellSelected,
   });
 
+  final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraft draft;
   final void Function(int localX, int localY) onCellSelected;
 
@@ -1557,6 +1593,9 @@ class _NewPathPatternGrid extends StatelessWidget {
         cells.add(
           _NewPathPatternCell(
             key: Key('path-studio-new-path-cell-$x-$y'),
+            tilesets: tilesets,
+            settings: settings,
+            projectRootPath: projectRootPath,
             cell: cell,
             selected: draft.selectedCellX == x && draft.selectedCellY == y,
             onTap: () => onCellSelected(x, y),
@@ -1579,11 +1618,17 @@ class _NewPathPatternGrid extends StatelessWidget {
 class _NewPathPatternCell extends StatelessWidget {
   const _NewPathPatternCell({
     super.key,
+    required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.cell,
     required this.selected,
     required this.onTap,
   });
 
+  final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraftCell cell;
   final bool selected;
   final VoidCallback onTap;
@@ -1625,7 +1670,12 @@ class _NewPathPatternCell extends StatelessWidget {
             ),
             const Spacer(),
             if (tile != null)
-              _TilePreviewBadge(tile: tile)
+              _TilePreviewBadge(
+                tilesets: tilesets,
+                settings: settings,
+                projectRootPath: projectRootPath,
+                tile: tile,
+              )
             else
               const _EmptyTileBadge(),
             const SizedBox(height: 6),
@@ -1732,13 +1782,21 @@ class _NewPathSelectedCellDetails extends StatelessWidget {
 }
 
 class _TilePreviewBadge extends StatelessWidget {
-  const _TilePreviewBadge({required this.tile});
+  const _TilePreviewBadge({
+    required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
+    required this.tile,
+  });
 
+  final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraftTile tile;
 
   @override
   Widget build(BuildContext context) {
-    return Container(
+    final fallback = Container(
       width: 46,
       height: 28,
       decoration: BoxDecoration(
@@ -1757,6 +1815,13 @@ class _TilePreviewBadge extends StatelessWidget {
         ),
       ),
     );
+    return PathStudioTileSpritePreview(
+      projectRootPath: projectRootPath,
+      tilesets: tilesets,
+      settings: settings,
+      tile: tile,
+      fallback: fallback,
+    );
   }
 }
 
@@ -1788,19 +1853,27 @@ class _EmptyTileBadge extends StatelessWidget {
 class _NewPathTilePickerPanel extends StatelessWidget {
   const _NewPathTilePickerPanel({
     required this.tilesets,
+    required this.settings,
+    required this.projectRootPath,
     required this.draft,
     required this.onTileSelected,
   });
 
   final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final String? projectRootPath;
   final PathStudioNewPathDraft draft;
   final void Function(int sourceX, int sourceY) onTileSelected;
 
   @override
   Widget build(BuildContext context) {
+    final selectedTileset = _selectedTileset(
+      tilesets: tilesets,
+      tilesetId: draft.tilesetId,
+    );
     final tilesetLabel =
         _selectedTilesetLabel(tilesets: tilesets, tilesetId: draft.tilesetId);
-    if (tilesetLabel == null) {
+    if (tilesetLabel == null || selectedTileset == null) {
       return Container(
         padding: const EdgeInsets.all(14),
         decoration: PathStudioTheme.subtleDecoration(
@@ -1884,32 +1957,19 @@ class _NewPathTilePickerPanel extends StatelessWidget {
             ),
           ),
           const SizedBox(height: 12),
-          Wrap(
-            spacing: 8,
-            runSpacing: 8,
-            children: [
-              for (var y = 0; y < 4; y += 1)
-                for (var x = 0; x < 8; x += 1)
-                  _NewPathTileButton(
-                    key: Key('path-studio-new-path-tile-$x-$y'),
-                    sourceX: x,
-                    sourceY: y,
-                    selected: selectedCell.tile?.sourceX == x &&
-                        selectedCell.tile?.sourceY == y &&
-                        selectedCell.tile?.tilesetId == draft.tilesetId,
-                    onTap: () => onTileSelected(x, y),
-                  ),
-            ],
-          ),
-          const SizedBox(height: 10),
-          const Text(
-            'Grille logique V0 : les coordonnées sont enregistrées dans le brouillon, sans lecture de l’image tileset ni preview PNG.',
-            style: TextStyle(
-              color: PathStudioTheme.textMuted,
-              fontSize: 10.5,
-              height: 1.35,
-              fontWeight: FontWeight.w700,
-            ),
+          PathStudioImageBackedTilesetPicker(
+            projectRootPath: projectRootPath,
+            tileset: selectedTileset,
+            settings: settings,
+            activeCell: selectedCell,
+            onTileSelected: (source) => onTileSelected(source.x, source.y),
+            fallbackBuilder: (context, result) {
+              return _LogicalNewPathTileGrid(
+                draft: draft,
+                selectedCell: selectedCell,
+                onTileSelected: onTileSelected,
+              );
+            },
           ),
         ],
       ),
@@ -1917,6 +1977,54 @@ class _NewPathTilePickerPanel extends StatelessWidget {
   }
 }
 
+class _LogicalNewPathTileGrid extends StatelessWidget {
+  const _LogicalNewPathTileGrid({
+    required this.draft,
+    required this.selectedCell,
+    required this.onTileSelected,
+  });
+
+  final PathStudioNewPathDraft draft;
+  final PathStudioNewPathDraftCell selectedCell;
+  final void Function(int sourceX, int sourceY) onTileSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        Wrap(
+          spacing: 8,
+          runSpacing: 8,
+          children: [
+            for (var y = 0; y < 4; y += 1)
+              for (var x = 0; x < 8; x += 1)
+                _NewPathTileButton(
+                  key: Key('path-studio-new-path-tile-$x-$y'),
+                  sourceX: x,
+                  sourceY: y,
+                  selected: selectedCell.tile?.sourceX == x &&
+                      selectedCell.tile?.sourceY == y &&
+                      selectedCell.tile?.tilesetId == draft.tilesetId,
+                  onTap: () => onTileSelected(x, y),
+                ),
+          ],
+        ),
+        const SizedBox(height: 10),
+        const Text(
+          'Fallback V0 : les coordonnées sont enregistrées dans le brouillon quand l’image tileset ne peut pas être chargée.',
+          style: TextStyle(
+            color: PathStudioTheme.textMuted,
+            fontSize: 10.5,
+            height: 1.35,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+      ],
+    );
+  }
+}
+
 class _NewPathTileButton extends StatelessWidget {
   const _NewPathTileButton({
     super.key,
@@ -3524,6 +3632,21 @@ String? _selectedTilesetLabel({
   return tilesetId;
 }
 
+ProjectTilesetEntry? _selectedTileset({
+  required List<ProjectTilesetEntry> tilesets,
+  required String? tilesetId,
+}) {
+  if (tilesetId == null || tilesetId.isEmpty) {
+    return null;
+  }
+  for (final tileset in tilesets) {
+    if (tileset.id == tilesetId) {
+      return tileset;
+    }
+  }
+  return null;
+}
+
 String _newPathDraftIssueLabel(PathStudioNewPathDraftIssueCode issue) {
   return switch (issue) {
     PathStudioNewPathDraftIssueCode.nameRequired => 'Nom requis',
diff --git a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
index 3511aa41..96441e5e 100644
--- a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
+++ b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
@@ -1,8 +1,13 @@
+import 'dart:io';
+import 'dart:typed_data';
+import 'dart:ui' as ui;
+
 import 'package:flutter/cupertino.dart';
 import 'package:flutter_test/flutter_test.dart';
 import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/features/path_studio/path_studio_panel.dart';
+import 'package:path/path.dart' as p;
 
 void main() {
   group('PathStudioPanel', () {
@@ -118,7 +123,7 @@ void main() {
       expect(find.text('lot futur'), findsWidgets);
 
       await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
 
       expect(find.text('Brouillon nouveau chemin'), findsWidgets);
       expect(find.text('Brouillon non sauvegardé'), findsWidgets);
@@ -147,7 +152,7 @@ void main() {
       );
 
       await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
 
       expect(find.text('Propriétés du nouveau chemin'), findsOneWidget);
       expect(find.text('mountain rock'), findsNothing);
@@ -170,7 +175,7 @@ void main() {
       );
 
       await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
 
       expect(find.text('Tileset'), findsWidgets);
       expect(find.text('À choisir'), findsWidgets);
@@ -199,7 +204,7 @@ void main() {
       );
 
       await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
 
       expect(find.text('Brouillon nouveau chemin'), findsWidgets);
       expect(
@@ -218,14 +223,14 @@ void main() {
       );
 
       await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
       tester
           .widget<MacosPopupButton<String>>(
             find.byKey(const Key('path-studio-new-path-tileset-popup')),
           )
           .onChanged
           ?.call('tileset-main');
-      await tester.pumpAndSettle();
+      await _pumpPathStudioAsync(tester);
 
       final tile = find.byKey(const Key('path-studio-new-path-tile-2-1'));
       await tester.ensureVisible(tile);
@@ -239,6 +244,173 @@ void main() {
       expect(find.text('Tileset à choisir'), findsNothing);
     });
 
+    testWidgets('missing tileset image keeps the logical picker fallback',
+        (tester) async {
+      final temp = (await tester.runAsync(
+        () => Directory.systemTemp.createTemp('path_studio_missing_'),
+      ))!;
+      addTearDown(() => temp.delete(recursive: true));
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
+        ),
+        projectRootPath: temp.path,
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await _pumpPathStudioAsync(tester);
+      tester
+          .widget<MacosPopupButton<String>>(
+            find.byKey(const Key('path-studio-new-path-tileset-popup')),
+          )
+          .onChanged
+          ?.call('tileset-main');
+      await _pumpPathStudioAsync(tester);
+
+      expect(find.text('Image du tileset introuvable'), findsWidgets);
+      expect(find.byKey(const Key('path-studio-new-path-tile-2-1')),
+          findsOneWidget);
+
+      await _tapNewPathTile(tester, tileX: 2, tileY: 1);
+
+      expect(find.text('Tuile 2,1'), findsWidgets);
+      expect(find.text('Cellules à configurer'), findsNothing);
+    });
+
+    testWidgets('image-backed tileset picker assigns the active cell',
+        (tester) async {
+      final temp = (await tester.runAsync(
+        () => Directory.systemTemp.createTemp('path_studio_image_'),
+      ))!;
+      addTearDown(() => temp.delete(recursive: true));
+      final imageFile = File(p.join(temp.path, 'tilesets/tileset-main.png'));
+      await tester.runAsync(() async {
+        await imageFile.parent.create(recursive: true);
+        await imageFile.writeAsBytes(await _pngBytes(width: 64, height: 32));
+      });
+
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
+          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
+        ),
+        projectRootPath: temp.path,
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await _pumpPathStudioAsync(tester);
+      tester
+          .widget<MacosPopupButton<String>>(
+            find.byKey(const Key('path-studio-new-path-tileset-popup')),
+          )
+          .onChanged
+          ?.call('tileset-main');
+      await _pumpPathStudioAsync(tester);
+
+      expect(find.byKey(const Key('path-studio-image-backed-tileset-picker')),
+          findsOneWidget);
+      expect(find.text('Image du tileset chargée'), findsWidgets);
+      expect(find.text('Grille 4×2'), findsWidgets);
+
+      await _tapImageBackedTile(tester,
+          tileX: 2, tileY: 1, columns: 4, rows: 2);
+
+      expect(find.text('Tuile 2,1'), findsWidgets);
+      expect(find.text('Cellules à configurer'), findsNothing);
+    });
+
+    testWidgets('image-backed picker fills all 2x2 cells and supports clear',
+        (tester) async {
+      final temp = (await tester.runAsync(
+        () => Directory.systemTemp.createTemp('path_studio_2x2_'),
+      ))!;
+      addTearDown(() => temp.delete(recursive: true));
+      final imageFile = File(p.join(temp.path, 'tilesets/tileset-main.png'));
+      await tester.runAsync(() async {
+        await imageFile.parent.create(recursive: true);
+        await imageFile.writeAsBytes(await _pngBytes(width: 64, height: 32));
+      });
+
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
+          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
+        ),
+        projectRootPath: temp.path,
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await _pumpPathStudioAsync(tester);
+      tester
+          .widget<MacosPopupButton<String>>(
+            find.byKey(const Key('path-studio-new-path-tileset-popup')),
+          )
+          .onChanged
+          ?.call('tileset-main');
+      await _pumpPathStudioAsync(tester);
+      await tester.tap(
+        find.byKey(const Key('path-studio-new-path-size-2x2')),
+      );
+      await tester.pumpAndSettle();
+
+      await _assignImageBackedTile(
+        tester,
+        cellX: 0,
+        cellY: 0,
+        tileX: 0,
+        tileY: 0,
+        columns: 4,
+        rows: 2,
+      );
+      await _assignImageBackedTile(
+        tester,
+        cellX: 1,
+        cellY: 0,
+        tileX: 1,
+        tileY: 0,
+        columns: 4,
+        rows: 2,
+      );
+      await _assignImageBackedTile(
+        tester,
+        cellX: 0,
+        cellY: 1,
+        tileX: 2,
+        tileY: 0,
+        columns: 4,
+        rows: 2,
+      );
+
+      expect(find.text('Cellules à configurer'), findsWidgets);
+
+      await _assignImageBackedTile(
+        tester,
+        cellX: 1,
+        cellY: 1,
+        tileX: 3,
+        tileY: 0,
+        columns: 4,
+        rows: 2,
+      );
+
+      expect(find.text('Cellules à configurer'), findsNothing);
+      expect(find.text('Tuile 3,0'), findsWidgets);
+
+      final clearButton =
+          find.byKey(const Key('path-studio-new-path-clear-selected-cell'));
+      await tester.ensureVisible(clearButton);
+      await tester.pumpAndSettle();
+      await tester.tap(clearButton);
+      await tester.pumpAndSettle();
+
+      expect(find.text('Cellules à configurer'), findsWidgets);
+      expect(find.text('Aucune tuile configurée pour cette cellule.'),
+          findsWidgets);
+    });
+
     testWidgets('assigns independent tiles to all 2x2 center cells',
         (tester) async {
       await _pumpPathStudio(
@@ -520,6 +692,7 @@ void main() {
 Future<void> _pumpPathStudio(
   WidgetTester tester, {
   required ProjectManifest manifest,
+  String? projectRootPath,
 }) async {
   await tester.binding.setSurfaceSize(const Size(1440, 920));
   addTearDown(() => tester.binding.setSurfaceSize(null));
@@ -531,14 +704,69 @@ Future<void> _pumpPathStudio(
         children: [
           ContentArea(
             builder: (context, scrollController) {
-              return PathStudioPanel(manifest: manifest);
+              return PathStudioPanel(
+                manifest: manifest,
+                projectRootPath: projectRootPath,
+              );
             },
           ),
         ],
       ),
     ),
   );
-  await tester.pumpAndSettle();
+  await _pumpPathStudioAsync(tester);
+}
+
+Future<void> _pumpPathStudioAsync(WidgetTester tester) async {
+  await tester.pump();
+  await tester.pump(const Duration(milliseconds: 250));
+  await tester.pump(const Duration(milliseconds: 250));
+}
+
+Future<void> _assignImageBackedTile(
+  WidgetTester tester, {
+  required int cellX,
+  required int cellY,
+  required int tileX,
+  required int tileY,
+  required int columns,
+  required int rows,
+}) async {
+  final cell = find.byKey(Key('path-studio-new-path-cell-$cellX-$cellY'));
+  await tester.ensureVisible(cell);
+  await _pumpPathStudioAsync(tester);
+  await tester.tap(cell);
+  await _pumpPathStudioAsync(tester);
+  await _tapImageBackedTile(
+    tester,
+    tileX: tileX,
+    tileY: tileY,
+    columns: columns,
+    rows: rows,
+  );
+}
+
+Future<void> _tapImageBackedTile(
+  WidgetTester tester, {
+  required int tileX,
+  required int tileY,
+  required int columns,
+  required int rows,
+}) async {
+  final picker =
+      find.byKey(const Key('path-studio-image-backed-tileset-canvas'));
+  await tester.ensureVisible(picker);
+  await _pumpPathStudioAsync(tester);
+  final topLeft = tester.getTopLeft(picker);
+  final size = tester.getSize(picker);
+  await tester.tapAt(
+    topLeft +
+        Offset(
+          (tileX + 0.5) * size.width / columns,
+          (tileY + 0.5) * size.height / rows,
+        ),
+  );
+  await _pumpPathStudioAsync(tester);
 }
 
 Future<void> _assignNewPathTile(
@@ -550,9 +778,9 @@ Future<void> _assignNewPathTile(
 }) async {
   final cell = find.byKey(Key('path-studio-new-path-cell-$cellX-$cellY'));
   await tester.ensureVisible(cell);
-  await tester.pumpAndSettle();
+  await _pumpPathStudioAsync(tester);
   await tester.tap(cell);
-  await tester.pumpAndSettle();
+  await _pumpPathStudioAsync(tester);
   await _tapNewPathTile(tester, tileX: tileX, tileY: tileY);
 }
 
@@ -563,18 +791,20 @@ Future<void> _tapNewPathTile(
 }) async {
   final tile = find.byKey(Key('path-studio-new-path-tile-$tileX-$tileY'));
   await tester.ensureVisible(tile);
-  await tester.pumpAndSettle();
+  await _pumpPathStudioAsync(tester);
   await tester.tap(tile);
-  await tester.pumpAndSettle();
+  await _pumpPathStudioAsync(tester);
 }
 
 ProjectManifest _manifest({
   List<ProjectPathPreset> pathPresets = const [],
   List<ProjectPathPatternPreset> pathPatternPresets = const [],
   List<ProjectTilesetEntry> tilesets = const [],
+  ProjectSettings settings = const ProjectSettings(),
 }) {
   return ProjectManifest(
     name: 'Project',
+    settings: settings,
     maps: const [],
     tilesets: tilesets,
     pathPresets: pathPresets,
@@ -583,6 +813,35 @@ ProjectManifest _manifest({
   );
 }
 
+Future<Uint8List> _pngBytes({
+  required int width,
+  required int height,
+}) async {
+  final recorder = ui.PictureRecorder();
+  final canvas = ui.Canvas(recorder);
+  final colors = [
+    const ui.Color(0xFFEBCB8B),
+    const ui.Color(0xFFA3BE8C),
+    const ui.Color(0xFF88C0D0),
+    const ui.Color(0xFFB48EAD),
+  ];
+  var colorIndex = 0;
+  for (var y = 0; y < height; y += 16) {
+    for (var x = 0; x < width; x += 16) {
+      final paint = ui.Paint()..color = colors[colorIndex % colors.length];
+      canvas.drawRect(
+        ui.Rect.fromLTWH(x.toDouble(), y.toDouble(), 16, 16),
+        paint,
+      );
+      colorIndex += 1;
+    }
+  }
+  final picture = recorder.endRecording();
+  final image = await picture.toImage(width, height);
+  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
+  return byteData!.buffer.asUint8List();
+}
+
 ProjectTilesetEntry _tileset({
   required String id,
   required String name,
```


### Diff /dev/null des fichiers créés


### diff -u /dev/null packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart

```diff
--- /dev/null	2026-05-01 01:12:52
+++ packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart	2026-05-01 01:11:21
@@ -0,0 +1,642 @@
+import 'dart:io';
+import 'dart:math' as math;
+import 'dart:typed_data';
+import 'dart:ui' as ui;
+
+import 'package:flutter/cupertino.dart';
+import 'package:image/image.dart' as img;
+import 'package:macos_ui/macos_ui.dart';
+import 'package:map_core/map_core.dart';
+import 'package:path/path.dart' as p;
+
+import 'path_studio_new_path_draft.dart';
+import 'path_studio_theme.dart';
+
+enum PathStudioTilesetImageStatus {
+  missingProjectRoot,
+  missingFile,
+  invalidTileSize,
+  invalidGrid,
+  invalidImage,
+  loaded,
+}
+
+final class PathStudioResolvedTilesetImage {
+  const PathStudioResolvedTilesetImage({
+    required this.absolutePath,
+    required this.bytes,
+    required this.imageWidthPx,
+    required this.imageHeightPx,
+    required this.tileWidthPx,
+    required this.tileHeightPx,
+    required this.columns,
+    required this.rows,
+  });
+
+  final String absolutePath;
+  final Uint8List bytes;
+  final int imageWidthPx;
+  final int imageHeightPx;
+  final int tileWidthPx;
+  final int tileHeightPx;
+  final int columns;
+  final int rows;
+}
+
+final class PathStudioTilesetImageLoadResult {
+  const PathStudioTilesetImageLoadResult({
+    required this.status,
+    required this.message,
+    this.image,
+  });
+
+  final PathStudioTilesetImageStatus status;
+  final String message;
+  final PathStudioResolvedTilesetImage? image;
+
+  bool get hasImage =>
+      status == PathStudioTilesetImageStatus.loaded && image != null;
+}
+
+Future<PathStudioTilesetImageLoadResult> loadPathStudioTilesetImage({
+  required String? projectRootPath,
+  required ProjectTilesetEntry tileset,
+  required ProjectSettings settings,
+}) async {
+  final root = projectRootPath?.trim();
+  if (root == null || root.isEmpty) {
+    return const PathStudioTilesetImageLoadResult(
+      status: PathStudioTilesetImageStatus.missingProjectRoot,
+      message: 'Racine projet indisponible',
+    );
+  }
+
+  final tileWidth = settings.tileWidth;
+  final tileHeight = settings.tileHeight;
+  if (tileWidth <= 0 || tileHeight <= 0) {
+    return const PathStudioTilesetImageLoadResult(
+      status: PathStudioTilesetImageStatus.invalidTileSize,
+      message: 'Dimensions de tuile invalides',
+    );
+  }
+
+  final absolutePath = p.normalize(p.join(root, tileset.relativePath));
+  final file = File(absolutePath);
+  if (!file.existsSync()) {
+    return const PathStudioTilesetImageLoadResult(
+      status: PathStudioTilesetImageStatus.missingFile,
+      message: 'Image du tileset introuvable',
+    );
+  }
+
+  try {
+    final bytes = file.readAsBytesSync();
+    final decoded = img.decodeImage(bytes);
+    if (decoded == null) {
+      return const PathStudioTilesetImageLoadResult(
+        status: PathStudioTilesetImageStatus.invalidImage,
+        message: 'Image du tileset illisible',
+      );
+    }
+    final columns = decoded.width ~/ tileWidth;
+    final rows = decoded.height ~/ tileHeight;
+    if (columns <= 0 || rows <= 0) {
+      return const PathStudioTilesetImageLoadResult(
+        status: PathStudioTilesetImageStatus.invalidGrid,
+        message: 'Impossible de découper ce tileset',
+      );
+    }
+    return PathStudioTilesetImageLoadResult(
+      status: PathStudioTilesetImageStatus.loaded,
+      message: 'Image du tileset chargée',
+      image: PathStudioResolvedTilesetImage(
+        absolutePath: absolutePath,
+        bytes: bytes,
+        imageWidthPx: decoded.width,
+        imageHeightPx: decoded.height,
+        tileWidthPx: tileWidth,
+        tileHeightPx: tileHeight,
+        columns: columns,
+        rows: rows,
+      ),
+    );
+  } catch (_) {
+    return const PathStudioTilesetImageLoadResult(
+      status: PathStudioTilesetImageStatus.invalidImage,
+      message: 'Image du tileset illisible',
+    );
+  }
+}
+
+TilesetSourceRect pathStudioTileSourceFromLocalPosition({
+  required ui.Offset localPosition,
+  required ui.Size displaySize,
+  required int columns,
+  required int rows,
+}) {
+  if (displaySize.width <= 0 || displaySize.height <= 0) {
+    return const TilesetSourceRect(x: 0, y: 0);
+  }
+  final rawX = (localPosition.dx / displaySize.width * columns).floor();
+  final rawY = (localPosition.dy / displaySize.height * rows).floor();
+  return TilesetSourceRect(
+    x: rawX.clamp(0, columns - 1).toInt(),
+    y: rawY.clamp(0, rows - 1).toInt(),
+  );
+}
+
+typedef PathStudioTilesetFallbackBuilder = Widget Function(
+  BuildContext context,
+  PathStudioTilesetImageLoadResult result,
+);
+
+class PathStudioImageBackedTilesetPicker extends StatefulWidget {
+  const PathStudioImageBackedTilesetPicker({
+    super.key,
+    required this.projectRootPath,
+    required this.tileset,
+    required this.settings,
+    required this.activeCell,
+    required this.onTileSelected,
+    required this.fallbackBuilder,
+  });
+
+  final String? projectRootPath;
+  final ProjectTilesetEntry tileset;
+  final ProjectSettings settings;
+  final PathStudioNewPathDraftCell activeCell;
+  final ValueChanged<TilesetSourceRect> onTileSelected;
+  final PathStudioTilesetFallbackBuilder fallbackBuilder;
+
+  @override
+  State<PathStudioImageBackedTilesetPicker> createState() =>
+      _PathStudioImageBackedTilesetPickerState();
+}
+
+class _PathStudioImageBackedTilesetPickerState
+    extends State<PathStudioImageBackedTilesetPicker> {
+  late Future<PathStudioTilesetImageLoadResult> _loadFuture;
+
+  @override
+  void initState() {
+    super.initState();
+    _loadFuture = _load();
+  }
+
+  @override
+  void didUpdateWidget(covariant PathStudioImageBackedTilesetPicker oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (oldWidget.projectRootPath != widget.projectRootPath ||
+        oldWidget.tileset.id != widget.tileset.id ||
+        oldWidget.tileset.relativePath != widget.tileset.relativePath ||
+        oldWidget.settings.tileWidth != widget.settings.tileWidth ||
+        oldWidget.settings.tileHeight != widget.settings.tileHeight) {
+      _loadFuture = _load();
+    }
+  }
+
+  Future<PathStudioTilesetImageLoadResult> _load() {
+    return loadPathStudioTilesetImage(
+      projectRootPath: widget.projectRootPath,
+      tileset: widget.tileset,
+      settings: widget.settings,
+    );
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    return FutureBuilder<PathStudioTilesetImageLoadResult>(
+      future: _loadFuture,
+      builder: (context, snapshot) {
+        if (!snapshot.hasData) {
+          return const _TilesetImageLoadingState();
+        }
+        final result = snapshot.requireData;
+        final image = result.image;
+        if (!result.hasImage || image == null) {
+          return Column(
+            crossAxisAlignment: CrossAxisAlignment.start,
+            children: [
+              _TilesetImageFallbackNotice(message: result.message),
+              const SizedBox(height: 12),
+              widget.fallbackBuilder(context, result),
+            ],
+          );
+        }
+        return _LoadedTilesetImagePicker(
+          image: image,
+          activeCell: widget.activeCell,
+          onTileSelected: widget.onTileSelected,
+        );
+      },
+    );
+  }
+}
+
+class PathStudioTileSpritePreview extends StatefulWidget {
+  const PathStudioTileSpritePreview({
+    super.key,
+    required this.projectRootPath,
+    required this.tilesets,
+    required this.settings,
+    required this.tile,
+    required this.fallback,
+  });
+
+  final String? projectRootPath;
+  final List<ProjectTilesetEntry> tilesets;
+  final ProjectSettings settings;
+  final PathStudioNewPathDraftTile tile;
+  final Widget fallback;
+
+  @override
+  State<PathStudioTileSpritePreview> createState() =>
+      _PathStudioTileSpritePreviewState();
+}
+
+class _PathStudioTileSpritePreviewState
+    extends State<PathStudioTileSpritePreview> {
+  late Future<PathStudioTilesetImageLoadResult>? _loadFuture;
+
+  @override
+  void initState() {
+    super.initState();
+    _loadFuture = _load();
+  }
+
+  @override
+  void didUpdateWidget(covariant PathStudioTileSpritePreview oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (oldWidget.projectRootPath != widget.projectRootPath ||
+        oldWidget.tile.tilesetId != widget.tile.tilesetId ||
+        _tilesetFingerprint(oldWidget.tilesets, oldWidget.tile.tilesetId) !=
+            _tilesetFingerprint(widget.tilesets, widget.tile.tilesetId) ||
+        oldWidget.settings.tileWidth != widget.settings.tileWidth ||
+        oldWidget.settings.tileHeight != widget.settings.tileHeight) {
+      _loadFuture = _load();
+    }
+  }
+
+  Future<PathStudioTilesetImageLoadResult>? _load() {
+    final tileset = _tilesetById(widget.tilesets, widget.tile.tilesetId);
+    if (tileset == null) {
+      return null;
+    }
+    return loadPathStudioTilesetImage(
+      projectRootPath: widget.projectRootPath,
+      tileset: tileset,
+      settings: widget.settings,
+    );
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final loadFuture = _loadFuture;
+    if (loadFuture == null) {
+      return widget.fallback;
+    }
+    return FutureBuilder<PathStudioTilesetImageLoadResult>(
+      future: loadFuture,
+      builder: (context, snapshot) {
+        final image = snapshot.data?.image;
+        if (image == null) {
+          return widget.fallback;
+        }
+        if (widget.tile.sourceX >= image.columns ||
+            widget.tile.sourceY >= image.rows) {
+          return widget.fallback;
+        }
+        return _TileSpritePreview(
+          key: const Key('path-studio-tile-preview-image'),
+          image: image,
+          tile: widget.tile,
+        );
+      },
+    );
+  }
+}
+
+class _TileSpritePreview extends StatelessWidget {
+  const _TileSpritePreview({
+    super.key,
+    required this.image,
+    required this.tile,
+  });
+
+  final PathStudioResolvedTilesetImage image;
+  final PathStudioNewPathDraftTile tile;
+
+  @override
+  Widget build(BuildContext context) {
+    const previewWidth = 46.0;
+    const previewHeight = 28.0;
+    return Container(
+      width: previewWidth,
+      height: previewHeight,
+      decoration: BoxDecoration(
+        color: PathStudioTheme.backgroundAlt,
+        borderRadius: BorderRadius.circular(8),
+        border: Border.all(
+          color: PathStudioTheme.success.withValues(alpha: 0.7),
+        ),
+      ),
+      clipBehavior: Clip.antiAlias,
+      child: ClipRect(
+        child: Transform.translate(
+          offset: Offset(
+            -tile.sourceX * previewWidth,
+            -tile.sourceY * previewHeight,
+          ),
+          child: Image.memory(
+            image.bytes,
+            width: image.columns * previewWidth,
+            height: image.rows * previewHeight,
+            fit: BoxFit.fill,
+            filterQuality: FilterQuality.none,
+            gaplessPlayback: true,
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+class _LoadedTilesetImagePicker extends StatelessWidget {
+  const _LoadedTilesetImagePicker({
+    required this.image,
+    required this.activeCell,
+    required this.onTileSelected,
+  });
+
+  final PathStudioResolvedTilesetImage image;
+  final PathStudioNewPathDraftCell activeCell;
+  final ValueChanged<TilesetSourceRect> onTileSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    final selectedTile = activeCell.tile;
+    return Container(
+      key: const Key('path-studio-image-backed-tileset-picker'),
+      padding: const EdgeInsets.all(12),
+      decoration: PathStudioTheme.subtleDecoration(
+        color: PathStudioTheme.surfaceStrong,
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Row(
+            children: [
+              const MacosIcon(
+                CupertinoIcons.photo,
+                color: PathStudioTheme.accentCyan,
+                size: 16,
+              ),
+              const SizedBox(width: 8),
+              const Text(
+                'Image du tileset chargée',
+                style: TextStyle(
+                  color: PathStudioTheme.textPrimary,
+                  fontSize: 12.5,
+                  fontWeight: FontWeight.w800,
+                ),
+              ),
+              const Spacer(),
+              Text(
+                'Grille ${image.columns}×${image.rows}',
+                style: const TextStyle(
+                  color: PathStudioTheme.textMuted,
+                  fontSize: 10.5,
+                  fontWeight: FontWeight.w800,
+                ),
+              ),
+            ],
+          ),
+          const SizedBox(height: 10),
+          LayoutBuilder(
+            builder: (context, constraints) {
+              final naturalWidth = image.imageWidthPx.toDouble();
+              final naturalHeight = image.imageHeightPx.toDouble();
+              final maxWidth = constraints.maxWidth.isFinite
+                  ? constraints.maxWidth
+                  : naturalWidth;
+              final displayWidth = math.min(
+                maxWidth,
+                math.max(naturalWidth, naturalWidth * 2),
+              );
+              final displayHeight = displayWidth * naturalHeight / naturalWidth;
+              final displaySize = ui.Size(displayWidth, displayHeight);
+              return SingleChildScrollView(
+                scrollDirection: Axis.horizontal,
+                child: GestureDetector(
+                  onTapDown: (details) {
+                    onTileSelected(
+                      pathStudioTileSourceFromLocalPosition(
+                        localPosition: details.localPosition,
+                        displaySize: displaySize,
+                        columns: image.columns,
+                        rows: image.rows,
+                      ),
+                    );
+                  },
+                  child: SizedBox(
+                    key: const Key('path-studio-image-backed-tileset-canvas'),
+                    width: displayWidth,
+                    height: displayHeight,
+                    child: Stack(
+                      fit: StackFit.expand,
+                      children: [
+                        ClipRRect(
+                          borderRadius: BorderRadius.circular(14),
+                          child: Image.memory(
+                            image.bytes,
+                            width: displayWidth,
+                            height: displayHeight,
+                            fit: BoxFit.fill,
+                            filterQuality: FilterQuality.none,
+                            gaplessPlayback: true,
+                          ),
+                        ),
+                        CustomPaint(
+                          painter: _TilesetImageGridPainter(
+                            image: image,
+                            selectedSource: selectedTile?.tilesetId == null
+                                ? null
+                                : TilesetSourceRect(
+                                    x: selectedTile!.sourceX,
+                                    y: selectedTile.sourceY,
+                                  ),
+                          ),
+                        ),
+                      ],
+                    ),
+                  ),
+                ),
+              );
+            },
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _TilesetImageLoadingState extends StatelessWidget {
+  const _TilesetImageLoadingState();
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.all(12),
+      decoration: PathStudioTheme.subtleDecoration(),
+      child: const Text(
+        'Chargement du tileset…',
+        style: TextStyle(
+          color: PathStudioTheme.textSecondary,
+          fontSize: 11.5,
+          fontWeight: FontWeight.w700,
+        ),
+      ),
+    );
+  }
+}
+
+class _TilesetImageFallbackNotice extends StatelessWidget {
+  const _TilesetImageFallbackNotice({required this.message});
+
+  final String message;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.all(12),
+      decoration: PathStudioTheme.subtleDecoration(
+        color: PathStudioTheme.warning.withValues(alpha: 0.1),
+      ),
+      child: Row(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          const MacosIcon(
+            CupertinoIcons.exclamationmark_triangle,
+            color: PathStudioTheme.warning,
+            size: 16,
+          ),
+          const SizedBox(width: 8),
+          Expanded(
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Text(
+                  message,
+                  style: const TextStyle(
+                    color: PathStudioTheme.textPrimary,
+                    fontSize: 12,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+                const SizedBox(height: 4),
+                const Text(
+                  'Utilisation du picker logique',
+                  style: TextStyle(
+                    color: PathStudioTheme.textSecondary,
+                    fontSize: 11,
+                    fontWeight: FontWeight.w700,
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
+class _TilesetImageGridPainter extends CustomPainter {
+  const _TilesetImageGridPainter({
+    required this.image,
+    required this.selectedSource,
+  });
+
+  final PathStudioResolvedTilesetImage image;
+  final TilesetSourceRect? selectedSource;
+
+  @override
+  void paint(ui.Canvas canvas, ui.Size size) {
+    final target = ui.Offset.zero & size;
+    canvas.save();
+    canvas.clipRRect(
+      ui.RRect.fromRectAndRadius(target, const ui.Radius.circular(14)),
+    );
+    final cellWidth = size.width / image.columns;
+    final cellHeight = size.height / image.rows;
+    final gridPaint = ui.Paint()
+      ..color = CupertinoColors.black.withValues(alpha: 0.45)
+      ..strokeWidth = 1;
+    for (var x = 1; x < image.columns; x += 1) {
+      final dx = x * cellWidth;
+      canvas.drawLine(ui.Offset(dx, 0), ui.Offset(dx, size.height), gridPaint);
+    }
+    for (var y = 1; y < image.rows; y += 1) {
+      final dy = y * cellHeight;
+      canvas.drawLine(ui.Offset(0, dy), ui.Offset(size.width, dy), gridPaint);
+    }
+
+    final selected = selectedSource;
+    if (selected != null &&
+        selected.x >= 0 &&
+        selected.y >= 0 &&
+        selected.x < image.columns &&
+        selected.y < image.rows) {
+      final rect = ui.Rect.fromLTWH(
+        selected.x * cellWidth,
+        selected.y * cellHeight,
+        cellWidth,
+        cellHeight,
+      );
+      canvas.drawRect(
+        rect.deflate(1),
+        ui.Paint()
+          ..style = ui.PaintingStyle.stroke
+          ..strokeWidth = 3
+          ..color = PathStudioTheme.accentHover,
+      );
+      canvas.drawRect(
+        rect.deflate(3),
+        ui.Paint()
+          ..style = ui.PaintingStyle.stroke
+          ..strokeWidth = 1.5
+          ..color = PathStudioTheme.accentCyan,
+      );
+    }
+    canvas.restore();
+  }
+
+  @override
+  bool shouldRepaint(covariant _TilesetImageGridPainter oldDelegate) {
+    return oldDelegate.image != image ||
+        oldDelegate.selectedSource != selectedSource;
+  }
+}
+
+ProjectTilesetEntry? _tilesetById(
+  List<ProjectTilesetEntry> tilesets,
+  String tilesetId,
+) {
+  for (final tileset in tilesets) {
+    if (tileset.id == tilesetId) {
+      return tileset;
+    }
+  }
+  return null;
+}
+
+String? _tilesetFingerprint(
+  List<ProjectTilesetEntry> tilesets,
+  String tilesetId,
+) {
+  final tileset = _tilesetById(tilesets, tilesetId);
+  if (tileset == null) {
+    return null;
+  }
+  return '${tileset.id}|${tileset.relativePath}|${tileset.name}';
+}
```


### diff -u /dev/null packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart

```diff
--- /dev/null	2026-05-01 01:12:52
+++ packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart	2026-05-01 00:45:08
@@ -0,0 +1,89 @@
+import 'dart:io';
+import 'dart:typed_data';
+import 'dart:ui' as ui;
+
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/path_studio/path_studio_tileset_image_picker.dart';
+import 'package:path/path.dart' as p;
+
+void main() {
+  group('PathStudioTilesetImagePicker image support', () {
+    test('resolves an image from project root and tileset relativePath',
+        () async {
+      final temp = await Directory.systemTemp.createTemp('path_studio_image_');
+      addTearDown(() => temp.delete(recursive: true));
+      final imageFile = File(p.join(temp.path, 'tilesets/main.png'));
+      await imageFile.parent.create(recursive: true);
+      await imageFile.writeAsBytes(await _pngBytes(width: 64, height: 32));
+
+      final result = await loadPathStudioTilesetImage(
+        projectRootPath: temp.path,
+        tileset: const ProjectTilesetEntry(
+          id: 'main',
+          name: 'Main',
+          relativePath: 'tilesets/main.png',
+        ),
+        settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
+      );
+
+      expect(result.status, PathStudioTilesetImageStatus.loaded);
+      expect(result.image!.absolutePath, imageFile.path);
+      expect(result.image!.imageWidthPx, 64);
+      expect(result.image!.imageHeightPx, 32);
+      expect(result.image!.columns, 4);
+      expect(result.image!.rows, 2);
+    });
+
+    test('returns a fallback status when the image file is absent', () async {
+      final temp =
+          await Directory.systemTemp.createTemp('path_studio_missing_');
+      addTearDown(() => temp.delete(recursive: true));
+
+      final result = await loadPathStudioTilesetImage(
+        projectRootPath: temp.path,
+        tileset: const ProjectTilesetEntry(
+          id: 'missing',
+          name: 'Missing',
+          relativePath: 'tilesets/missing.png',
+        ),
+        settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
+      );
+
+      expect(result.status, PathStudioTilesetImageStatus.missingFile);
+      expect(result.image, isNull);
+      expect(result.message, contains('introuvable'));
+    });
+
+    test('converts a local click position to tile coordinates', () {
+      final source = pathStudioTileSourceFromLocalPosition(
+        localPosition: const ui.Offset(35, 17),
+        displaySize: const ui.Size(128, 64),
+        columns: 4,
+        rows: 2,
+      );
+
+      expect(source.x, 1);
+      expect(source.y, 0);
+      expect(source.width, 1);
+      expect(source.height, 1);
+    });
+  });
+}
+
+Future<Uint8List> _pngBytes({
+  required int width,
+  required int height,
+}) async {
+  final recorder = ui.PictureRecorder();
+  final canvas = ui.Canvas(recorder);
+  final paint = ui.Paint()..color = const ui.Color(0xFFFF00FF);
+  canvas.drawRect(
+    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
+    paint,
+  );
+  final picture = recorder.endRecording();
+  final image = await picture.toImage(width, height);
+  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
+  return byteData!.buffer.asUint8List();
+}
```


## 18. Contenu complet des fichiers créés / modifiés


### packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../editor/state/editor_selectors.dart';
import 'path_pattern_draft.dart';
import 'path_pattern_editor_read_model.dart';
import 'path_studio_new_path_draft.dart';
import 'path_studio_theme.dart';
import 'path_studio_tileset_image_picker.dart';

/// Workspace branché au shell global de l'éditeur.
///
/// Ce wrapper Riverpod reste volontairement fin : il lit seulement le manifest
/// courant et délègue tout le rendu read-only à [PathStudioPanel]. Le lot 13 ne
/// crée ni repository, ni provider dédié, ni contrôleur de sauvegarde.
class PathStudioWorkspace extends ConsumerWidget {
  const PathStudioWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manifest = ref.watch(editorProjectManifestProvider);
    final projectRootPath = ref.watch(editorProjectRootPathProvider);
    if (manifest == null) {
      return const _PathStudioProjectMissingState();
    }
    return PathStudioPanel(
      manifest: manifest,
      projectRootPath: projectRootPath,
    );
  }
}

/// Shell visuel read-only du Path Studio.
///
/// Le widget reçoit un [ProjectManifest] explicite pour rester testable sans
/// dépendance à l'infrastructure éditeur. Toute l'information métier affichée
/// passe par le read model du lot 12 : aucune logique de diagnostic PathPattern
/// n'est recalculée ici.
class PathStudioPanel extends StatefulWidget {
  const PathStudioPanel({
    super.key,
    required this.manifest,
    this.projectRootPath,
  });

  final ProjectManifest manifest;
  final String? projectRootPath;

  @override
  State<PathStudioPanel> createState() => _PathStudioPanelState();
}

class _PathStudioPanelState extends State<PathStudioPanel> {
  String _searchQuery = '';
  PathStudioNewPathDraft? _newPathDraft;
  bool _newPathDraftSelected = false;
  PathPatternDraft? _draft;
  bool _draftSelected = false;
  String? _draftMessage;

  /// Index dans `readModel.presets`, pas id métier.
  ///
  /// Les ids dupliqués sont précisément un diagnostic V0 ; sélectionner par id
  /// rendrait une card ambiguë. L'index source garde donc une sélection stable
  /// même quand deux presets portent le même identifiant.
  int? _selectedSourceIndex;

  @override
  void didUpdateWidget(covariant PathStudioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.manifest != widget.manifest) {
      _selectedSourceIndex = null;
      _newPathDraft = null;
      _newPathDraftSelected = false;
      _draft = null;
      _draftSelected = false;
      _draftMessage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final readModel = createPathPatternEditorReadModel(
      manifest: widget.manifest,
    );
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _filteredCards(readModel, query);
    final selected = _newPathDraftSelected || _draftSelected
        ? null
        : _selectedCard(filtered);
    final selectedNewPathDraft = _newPathDraftSelected ? _newPathDraft : null;
    final selectedDraft = _draftSelected ? _draft : null;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: PathStudioTheme.backgroundGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PathStudioHeader(
              summary: readModel.summary,
              onCreateNewPathDraft: _createNewPathDraft,
              onCreateLegacyDraft: _createLegacyDraft,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 292,
                    child: _PresetSidebar(
                      readModel: readModel,
                      filteredCards: filtered,
                      newPathDraft: _newPathDraft,
                      newPathDraftSelected: _newPathDraftSelected,
                      newPathDraftMatchesQuery: _newPathDraft == null ||
                          query.isEmpty ||
                          _matchesNewPathDraftQuery(_newPathDraft!, query),
                      draft: _draft,
                      draftSelected: _draftSelected,
                      draftMatchesQuery: _draft == null ||
                          query.isEmpty ||
                          _matchesDraftQuery(_draft!, query),
                      draftMessage: _draftMessage,
                      selectedSourceIndex: selected?.sourceIndex,
                      onQueryChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      onSelectNewPathDraft: () {
                        setState(() {
                          _newPathDraftSelected = true;
                          _draftSelected = false;
                        });
                      },
                      onSelectDraft: () {
                        setState(() {
                          _newPathDraftSelected = false;
                          _draftSelected = true;
                        });
                      },
                      onSelect: (sourceIndex) {
                        setState(() {
                          _newPathDraftSelected = false;
                          _draftSelected = false;
                          _selectedSourceIndex = sourceIndex;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _CenterWorkspace(
                      tilesets: widget.manifest.tilesets,
                      settings: widget.manifest.settings,
                      projectRootPath: widget.projectRootPath,
                      newPathDraft: selectedNewPathDraft,
                      draft: selectedDraft,
                      selected: selected?.card,
                      hasAnyPreset: readModel.presets.isNotEmpty,
                      onNewPathSizeChanged: _resizeNewPathDraft,
                      onNewPathCellSelected: _selectNewPathDraftCell,
                      onNewPathTileSelected: _assignNewPathDraftTile,
                      onNewPathCellCleared: _clearNewPathDraftCell,
                      onDraftSizeChanged: _resizeDraft,
                      onDraftCellSelected: _selectDraftCell,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 326,
                    child: _PresetInspector(
                      manifest: widget.manifest,
                      newPathDraft: selectedNewPathDraft,
                      draft: selectedDraft,
                      selected: selected?.card,
                      onNewPathNameChanged: _renameNewPathDraft,
                      onNewPathTilesetChanged: _selectNewPathDraftTileset,
                      onNewPathSizeChanged: _resizeNewPathDraft,
                      onDraftNameChanged: _renameDraft,
                      onDraftBaseChanged: _changeDraftBase,
                      onDraftSizeChanged: _resizeDraft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_IndexedPresetCard> _filteredCards(
    PathPatternEditorReadModel readModel,
    String query,
  ) {
    final indexed = <_IndexedPresetCard>[];
    for (var index = 0; index < readModel.presets.length; index += 1) {
      final card = readModel.presets[index];
      if (query.isEmpty || _matchesQuery(card, query)) {
        indexed.add(_IndexedPresetCard(index, card));
      }
    }
    return indexed;
  }

  bool _matchesQuery(PathPatternPresetCardModel card, String query) {
    final fields = [
      card.name,
      card.id,
      card.basePathPresetId,
      card.basePathPresetName,
      card.basePathSurfaceKindLabel,
      card.centerPatternLabel,
    ];
    return fields
        .whereType<String>()
        .any((field) => field.toLowerCase().contains(query));
  }

  bool _matchesDraftQuery(PathPatternDraft draft, String query) {
    final fields = [
      draft.name,
      draft.id,
      draft.basePathPresetId,
      draft.centerPatternLabel,
    ];
    return fields.any((field) => field.toLowerCase().contains(query));
  }

  bool _matchesNewPathDraftQuery(
    PathStudioNewPathDraft draft,
    String query,
  ) {
    final fields = [
      draft.name,
      draft.id,
      draft.centerPatternLabel,
      'nouveau chemin',
    ];
    return fields.any((field) => field.toLowerCase().contains(query));
  }

  _IndexedPresetCard? _selectedCard(List<_IndexedPresetCard> filtered) {
    if (filtered.isEmpty) {
      return null;
    }
    for (final entry in filtered) {
      if (entry.sourceIndex == _selectedSourceIndex) {
        return entry;
      }
    }
    return filtered.first;
  }

  void _createNewPathDraft() {
    setState(() {
      _newPathDraft = createInitialPathStudioNewPathDraft();
      _newPathDraftSelected = true;
      _draftSelected = false;
      _draftMessage = null;
    });
  }

  void _createLegacyDraft() {
    if (widget.manifest.pathPresets.isEmpty) {
      setState(() {
        _draftMessage = 'Aucun path existant disponible';
        _newPathDraftSelected = false;
        _draftSelected = false;
      });
      return;
    }
    try {
      final draft = createInitialPathPatternDraftFromManifest(
        manifest: widget.manifest,
      );
      setState(() {
        _draft = draft;
        _newPathDraftSelected = false;
        _draftSelected = draft != null;
        _draftMessage = draft == null
            ? 'Aucun path existant disponible'
            : 'Brouillon non sauvegardé';
      });
    } on ArgumentError {
      setState(() {
        _draftMessage =
            'Le preset Path de base ne contient pas de centre cross';
        _newPathDraftSelected = false;
        _draftSelected = false;
      });
    }
  }

  void _renameNewPathDraft(String name) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = renamePathStudioNewPathDraft(draft, name);
    });
  }

  void _resizeNewPathDraft(int width, int height) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = resizePathStudioNewPathDraftCenter(
        draft: draft,
        width: width,
        height: height,
      );
    });
  }

  void _selectNewPathDraftTileset(String tilesetId) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = selectPathStudioNewPathDraftTileset(draft, tilesetId);
    });
  }

  void _selectNewPathDraftCell(int localX, int localY) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = selectPathStudioNewPathDraftCell(
        draft: draft,
        localX: localX,
        localY: localY,
      );
    });
  }

  void _assignNewPathDraftTile(int sourceX, int sourceY) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: draft.selectedCellX,
        localY: draft.selectedCellY,
        sourceX: sourceX,
        sourceY: sourceY,
      );
    });
  }

  void _clearNewPathDraftCell(int localX, int localY) {
    final draft = _newPathDraft;
    if (draft == null) {
      return;
    }
    setState(() {
      _newPathDraft = clearPathStudioNewPathDraftCell(
        draft: draft,
        localX: localX,
        localY: localY,
      );
    });
  }

  void _renameDraft(String name) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    setState(() => _draft = renamePathPatternDraft(draft, name));
  }

  void _resizeDraft(int width, int height) {
    final draft = _draft;
    final base = _basePathPresetForDraft(draft);
    if (draft == null || base == null) {
      return;
    }
    setState(() {
      _draft = resizePathPatternDraftCenter(
        draft: draft,
        basePathPreset: base,
        width: width,
        height: height,
      );
    });
  }

  void _changeDraftBase(String basePathPresetId) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    final base = _basePathPresetById(basePathPresetId);
    if (base == null) {
      return;
    }
    setState(() {
      _draft = changePathPatternDraftBase(
        draft: draft,
        basePathPreset: base,
      );
    });
  }

  void _selectDraftCell(int localX, int localY) {
    final draft = _draft;
    if (draft == null) {
      return;
    }
    setState(() {
      _draft = selectPathPatternDraftCell(
        draft: draft,
        localX: localX,
        localY: localY,
      );
    });
  }

  ProjectPathPreset? _basePathPresetForDraft(PathPatternDraft? draft) {
    if (draft == null) {
      return null;
    }
    return _basePathPresetById(draft.basePathPresetId);
  }

  ProjectPathPreset? _basePathPresetById(String id) {
    for (final preset in widget.manifest.pathPresets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }
}

class _IndexedPresetCard {
  const _IndexedPresetCard(this.sourceIndex, this.card);

  final int sourceIndex;
  final PathPatternPresetCardModel card;
}

class _PathStudioProjectMissingState extends StatelessWidget {
  const _PathStudioProjectMissingState();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: PathStudioTheme.background,
      child: Center(
        child: Text(
          'Charger un projet pour ouvrir Path Studio.',
          style: TextStyle(
            color: PathStudioTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PathStudioHeader extends StatelessWidget {
  const _PathStudioHeader({
    required this.summary,
    required this.onCreateNewPathDraft,
    required this.onCreateLegacyDraft,
  });

  final PathPatternEditorSummary summary;
  final VoidCallback onCreateNewPathDraft;
  final VoidCallback onCreateLegacyDraft;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(
        color: PathStudioTheme.surface,
        radius: 24,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  PathStudioTheme.accentHover,
                  PathStudioTheme.accent,
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: PathStudioTheme.accentHover.withValues(alpha: 0.8),
              ),
            ),
            child: const MacosIcon(
              CupertinoIcons.arrow_branch,
              color: CupertinoColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Path Studio',
                  style: TextStyle(
                    color: PathStudioTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Créer des motifs de chemin',
                  style: TextStyle(
                    color: PathStudioTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 2,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryPill(label: 'Presets', value: '${summary.totalCount}'),
                _SummaryPill(label: 'Prêts', value: '${summary.readyCount}'),
                _ShellActionButton(
                  icon: CupertinoIcons.plus,
                  label: 'Nouveau chemin',
                  hint: 'nouveau brouillon',
                  onPressed: onCreateNewPathDraft,
                ),
                _ShellActionButton(
                  icon: CupertinoIcons.arrow_down_doc,
                  label: 'Depuis un path existant',
                  hint: 'flux avancé',
                  onPressed: onCreateLegacyDraft,
                ),
                const _ShellActionButton(
                  icon: CupertinoIcons.square_on_square,
                  label: 'Dupliquer',
                  hint: 'lot futur',
                ),
                const _ShellActionButton(
                  icon: CupertinoIcons.floppy_disk,
                  label: 'Enregistrer',
                  hint: 'lot futur',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: PathStudioTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PathStudioTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellActionButton extends StatelessWidget {
  const _ShellActionButton({
    required this.icon,
    required this.label,
    this.hint = 'lot futur',
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      minimumSize: Size.zero,
      onPressed: onPressed,
      disabledColor: PathStudioTheme.surfaceRaised.withValues(alpha: 0.72),
      color: PathStudioTheme.accent,
      borderRadius: BorderRadius.circular(13),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MacosIcon(
            icon,
            color: onPressed == null
                ? PathStudioTheme.textMuted.withValues(alpha: 0.72)
                : CupertinoColors.white,
            size: 15,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: onPressed == null
                      ? PathStudioTheme.textSecondary.withValues(alpha: 0.7)
                      : CupertinoColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                hint,
                style: TextStyle(
                  color: onPressed == null
                      ? PathStudioTheme.textMuted
                      : CupertinoColors.white.withValues(alpha: 0.72),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetSidebar extends StatelessWidget {
  const _PresetSidebar({
    required this.readModel,
    required this.filteredCards,
    required this.newPathDraft,
    required this.newPathDraftSelected,
    required this.newPathDraftMatchesQuery,
    required this.draft,
    required this.draftSelected,
    required this.draftMatchesQuery,
    required this.draftMessage,
    required this.selectedSourceIndex,
    required this.onQueryChanged,
    required this.onSelectNewPathDraft,
    required this.onSelectDraft,
    required this.onSelect,
  });

  final PathPatternEditorReadModel readModel;
  final List<_IndexedPresetCard> filteredCards;
  final PathStudioNewPathDraft? newPathDraft;
  final bool newPathDraftSelected;
  final bool newPathDraftMatchesQuery;
  final PathPatternDraft? draft;
  final bool draftSelected;
  final bool draftMatchesQuery;
  final String? draftMessage;
  final int? selectedSourceIndex;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSelectNewPathDraft;
  final VoidCallback onSelectDraft;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Presets',
                  style: TextStyle(
                    color: PathStudioTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _SidebarCounter(value: readModel.summary.totalCount),
            ],
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            key: const Key('path-studio-search-field'),
            onChanged: onQueryChanged,
            placeholder: 'Rechercher un preset...',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 10),
              child: MacosIcon(
                CupertinoIcons.search,
                size: 15,
                color: PathStudioTheme.textMuted,
              ),
            ),
            style: const TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
            ),
            placeholderStyle: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 13,
            ),
            decoration: BoxDecoration(
              color: PathStudioTheme.surfaceStrong,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: PathStudioTheme.border),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _buildPresetList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetList() {
    final newPathDraftCard = newPathDraft;
    final draftCard = draft;
    if (readModel.presets.isEmpty &&
        newPathDraftCard == null &&
        draftCard == null) {
      return _SidebarNotice(
        title: 'Aucun motif PathPattern',
        message: draftMessage ??
            'Cliquez sur Nouveau chemin pour créer un brouillon local.',
      );
    }
    final newPathVisible = newPathDraftCard != null && newPathDraftMatchesQuery;
    final legacyDraftVisible = draftCard != null && draftMatchesQuery;
    if (filteredCards.isEmpty && !newPathVisible && !legacyDraftVisible) {
      return const _SidebarNotice(
        title: 'Aucun preset trouvé',
        message: 'Essayez un autre nom, id ou preset de base.',
      );
    }
    final draftCount = (newPathVisible ? 1 : 0) + (legacyDraftVisible ? 1 : 0);
    return ListView.separated(
      itemCount: filteredCards.length + draftCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (newPathDraftCard != null && newPathVisible && index == 0) {
          return _NewPathDraftListCard(
            draft: newPathDraftCard,
            selected: newPathDraftSelected,
            onTap: onSelectNewPathDraft,
          );
        }
        final legacyIndex = newPathVisible ? 1 : 0;
        if (draftCard != null && legacyDraftVisible && index == legacyIndex) {
          return _DraftListCard(
            draft: draftCard,
            selected: draftSelected,
            onTap: onSelectDraft,
          );
        }
        final presetIndex = index - draftCount;
        final entry = filteredCards[presetIndex];
        return _PresetListCard(
          key: Key('path-studio-preset-card-${entry.sourceIndex}'),
          card: entry.card,
          selected: entry.sourceIndex == selectedSourceIndex,
          onTap: () => onSelect(entry.sourceIndex),
        );
      },
    );
  }
}

class _NewPathDraftListCard extends StatelessWidget {
  const _NewPathDraftListCard({
    required this.draft,
    required this.selected,
    required this.onTap,
  });

  final PathStudioNewPathDraft draft;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: const Key('path-studio-new-path-draft-card'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? Color.lerp(
                  PathStudioTheme.surfaceStrong,
                  PathStudioTheme.accentCyan,
                  0.22,
                )
              : PathStudioTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? PathStudioTheme.accentCyan
                : PathStudioTheme.accentCyan.withValues(alpha: 0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    draft.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PathStudioTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const _StatusChip(
                  label: 'Nouveau chemin',
                  color: PathStudioTheme.accentCyan,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Brouillon chemin • Non sauvegardé',
              style: TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MiniMetric(
                  icon: CupertinoIcons.square_grid_2x2,
                  label: draft.centerPatternLabel,
                ),
                const SizedBox(width: 8),
                const _MiniMetric(
                  icon: CupertinoIcons.wand_stars,
                  label: 'à configurer',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftListCard extends StatelessWidget {
  const _DraftListCard({
    required this.draft,
    required this.selected,
    required this.onTap,
  });

  final PathPatternDraft draft;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: const Key('path-studio-draft-card'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? Color.lerp(
                  PathStudioTheme.surfaceStrong,
                  PathStudioTheme.accentCyan,
                  0.22,
                )
              : PathStudioTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? PathStudioTheme.accentCyan
                : PathStudioTheme.accentCyan.withValues(alpha: 0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    draft.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PathStudioTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const _StatusChip(
                  label: 'Depuis path existant',
                  color: PathStudioTheme.accentCyan,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Structure héritée • Non sauvegardé',
              style: TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MiniMetric(
                  icon: CupertinoIcons.square_grid_2x2,
                  label: draft.centerPatternLabel,
                ),
                const SizedBox(width: 8),
                _MiniMetric(
                  icon: draft.animatedCellCount > 0
                      ? CupertinoIcons.play_circle
                      : CupertinoIcons.circle,
                  label: draft.animatedCellCount > 0 ? 'animé' : 'statique',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarCounter extends StatelessWidget {
  const _SidebarCounter({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: PathStudioTheme.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: PathStudioTheme.accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$value',
        style: const TextStyle(
          color: PathStudioTheme.accentHover,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SidebarNotice extends StatelessWidget {
  const _SidebarNotice({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: PathStudioTheme.subtleDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MacosIcon(
              CupertinoIcons.tray,
              color: PathStudioTheme.textMuted,
              size: 26,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetListCard extends StatefulWidget {
  const _PresetListCard({
    super.key,
    required this.card,
    required this.selected,
    required this.onTap,
  });

  final PathPatternPresetCardModel card;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PresetListCard> createState() => _PresetListCardState();
}

class _PresetListCardState extends State<_PresetListCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final status = _statusPresentation(widget.card.status);
    final borderColor = widget.selected
        ? PathStudioTheme.accentHover
        : widget.card.status == PathPatternPresetReadinessStatus.blocked
            ? PathStudioTheme.error.withValues(alpha: 0.45)
            : PathStudioTheme.border;
    final fill = widget.selected
        ? Color.lerp(
            PathStudioTheme.surfaceStrong, PathStudioTheme.accent, 0.2)!
        : _hovered
            ? Color.lerp(
                PathStudioTheme.surfaceRaised,
                PathStudioTheme.accent,
                0.08,
              )!
            : PathStudioTheme.surfaceRaised;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: borderColor, width: widget.selected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PathStudioTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusChip(label: status.label, color: status.color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.card.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PathStudioTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _MiniMetric(
                    icon: CupertinoIcons.square_grid_2x2,
                    label: widget.card.centerPatternLabel,
                  ),
                  const SizedBox(width: 8),
                  _MiniMetric(
                    icon: widget.card.animatedCellCount > 0
                        ? CupertinoIcons.play_circle
                        : CupertinoIcons.circle,
                    label: widget.card.animatedCellCount > 0
                        ? 'animé'
                        : 'statique',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.48)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MacosIcon(icon, size: 12, color: PathStudioTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: PathStudioTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CenterWorkspace extends StatelessWidget {
  const _CenterWorkspace({
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.newPathDraft,
    required this.draft,
    required this.selected,
    required this.hasAnyPreset,
    required this.onNewPathSizeChanged,
    required this.onNewPathCellSelected,
    required this.onNewPathTileSelected,
    required this.onNewPathCellCleared,
    required this.onDraftSizeChanged,
    required this.onDraftCellSelected,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraft? newPathDraft;
  final PathPatternDraft? draft;
  final PathPatternPresetCardModel? selected;
  final bool hasAnyPreset;
  final void Function(int width, int height) onNewPathSizeChanged;
  final void Function(int localX, int localY) onNewPathCellSelected;
  final void Function(int sourceX, int sourceY) onNewPathTileSelected;
  final void Function(int localX, int localY) onNewPathCellCleared;
  final void Function(int width, int height) onDraftSizeChanged;
  final void Function(int localX, int localY) onDraftCellSelected;

  @override
  Widget build(BuildContext context) {
    final newPathDraft = this.newPathDraft;
    if (newPathDraft != null) {
      return _NewPathCenterWorkspace(
        tilesets: tilesets,
        settings: settings,
        projectRootPath: projectRootPath,
        draft: newPathDraft,
        onSizeChanged: onNewPathSizeChanged,
        onCellSelected: onNewPathCellSelected,
        onTileSelected: onNewPathTileSelected,
        onCellCleared: onNewPathCellCleared,
      );
    }
    final draft = this.draft;
    if (draft != null) {
      return _DraftCenterWorkspace(
        draft: draft,
        onSizeChanged: onDraftSizeChanged,
        onCellSelected: onDraftCellSelected,
      );
    }
    final card = selected;
    if (card == null) {
      return _NoSelectionCenter(hasAnyPreset: hasAnyPreset);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WorkflowSteps(status: card.status),
          const SizedBox(height: 14),
          _SelectedSummary(card: card),
          const SizedBox(height: 14),
          _CenterPatternPlaceholder(card: card),
          const SizedBox(height: 14),
          _DiagnosticsCard(card: card),
        ],
      ),
    );
  }
}

class _NewPathCenterWorkspace extends StatelessWidget {
  const _NewPathCenterWorkspace({
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.draft,
    required this.onSizeChanged,
    required this.onCellSelected,
    required this.onTileSelected,
    required this.onCellCleared,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraft draft;
  final void Function(int width, int height) onSizeChanged;
  final void Function(int localX, int localY) onCellSelected;
  final void Function(int sourceX, int sourceY) onTileSelected;
  final void Function(int localX, int localY) onCellCleared;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _NewPathBanner(),
          const SizedBox(height: 14),
          _NewPathWorkflowSteps(hasTileset: _hasSelectedTileset(draft)),
          const SizedBox(height: 14),
          _NewPathSummary(tilesets: tilesets, draft: draft),
          const SizedBox(height: 14),
          _NewPathCenterPatternEditor(
            tilesets: tilesets,
            settings: settings,
            projectRootPath: projectRootPath,
            draft: draft,
            onSizeChanged: onSizeChanged,
            onCellSelected: onCellSelected,
            onTileSelected: onTileSelected,
            onCellCleared: onCellCleared,
          ),
          const SizedBox(height: 14),
          _NewPathDiagnosticsCard(draft: draft),
        ],
      ),
    );
  }
}

class _NewPathBanner extends StatelessWidget {
  const _NewPathBanner();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Brouillon nouveau chemin',
      icon: CupertinoIcons.pencil_outline,
      trailing: _StatusChip(
        label: 'Non sauvegardé',
        color: PathStudioTheme.warning,
      ),
      child: Text(
        'Ce brouillon représente un nouveau chemin complet. La sélection du tileset et la configuration des bords arriveront dans un lot futur.',
        style: TextStyle(
          color: PathStudioTheme.textSecondary,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}

class _NewPathWorkflowSteps extends StatelessWidget {
  const _NewPathWorkflowSteps({required this.hasTileset});

  final bool hasTileset;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Création guidée',
      icon: CupertinoIcons.list_bullet,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          const _StepPill(index: 1, label: 'Nouveau chemin', active: true),
          const _StepArrow(),
          const _StepPill(index: 2, label: 'Motif du centre', active: true),
          const _StepArrow(),
          _StepPill(
            index: 3,
            label: 'Tileset',
            active: false,
            complete: hasTileset,
          ),
        ],
      ),
    );
  }
}

class _NewPathSummary extends StatelessWidget {
  const _NewPathSummary({
    required this.tilesets,
    required this.draft,
  });

  final List<ProjectTilesetEntry> tilesets;
  final PathStudioNewPathDraft draft;

  @override
  Widget build(BuildContext context) {
    final tilesetLabel =
        _selectedTilesetLabel(tilesets: tilesets, tilesetId: draft.tilesetId) ??
            'À choisir';
    return _SectionCard(
      title: 'Résumé du nouveau chemin',
      icon: CupertinoIcons.doc_text,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _InfoTile(label: 'Nom', value: draft.name),
          _InfoTile(label: 'Tileset', value: tilesetLabel),
          _InfoTile(label: 'Centre', value: draft.centerPatternLabel),
          _InfoTile(label: 'Cellules', value: '${draft.centerCellCount}'),
          _InfoTile(
            label: 'Configurées',
            value: '${draft.configuredCellCount}/${draft.centerCellCount}',
          ),
          const _InfoTile(label: 'État', value: 'Brouillon non sauvegardé'),
        ],
      ),
    );
  }
}

class _NewPathCenterPatternEditor extends StatelessWidget {
  const _NewPathCenterPatternEditor({
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.draft,
    required this.onSizeChanged,
    required this.onCellSelected,
    required this.onTileSelected,
    required this.onCellCleared,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraft draft;
  final void Function(int width, int height) onSizeChanged;
  final void Function(int localX, int localY) onCellSelected;
  final void Function(int sourceX, int sourceY) onTileSelected;
  final void Function(int localX, int localY) onCellCleared;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Motif du centre',
      icon: CupertinoIcons.square_grid_2x2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chaque cellule existe déjà dans le futur motif, mais son contenu visuel n’est pas encore choisi.',
            style: TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          CupertinoSlidingSegmentedControl<String>(
            key: const Key('path-studio-new-path-size-control'),
            groupValue: draft.centerPatternLabel,
            onValueChanged: (value) {
              if (value == '1×1') {
                onSizeChanged(1, 1);
              } else if (value == '2×2') {
                onSizeChanged(2, 2);
              }
            },
            children: const {
              '1×1': Padding(
                key: Key('path-studio-new-path-size-1x1'),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Text('1×1'),
              ),
              '2×2': Padding(
                key: Key('path-studio-new-path-size-2x2'),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Text('2×2'),
              ),
            },
          ),
          const SizedBox(height: 18),
          _NewPathPatternGrid(
            tilesets: tilesets,
            settings: settings,
            projectRootPath: projectRootPath,
            draft: draft,
            onCellSelected: onCellSelected,
          ),
          const SizedBox(height: 14),
          _NewPathSelectedCellDetails(
            draft: draft,
            onCellCleared: onCellCleared,
          ),
          const SizedBox(height: 14),
          _NewPathTilePickerPanel(
            tilesets: tilesets,
            settings: settings,
            projectRootPath: projectRootPath,
            draft: draft,
            onTileSelected: onTileSelected,
          ),
        ],
      ),
    );
  }
}

class _NewPathPatternGrid extends StatelessWidget {
  const _NewPathPatternGrid({
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.draft,
    required this.onCellSelected,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraft draft;
  final void Function(int localX, int localY) onCellSelected;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var y = 0; y < draft.centerHeight; y += 1) {
      final cells = <Widget>[];
      for (var x = 0; x < draft.centerWidth; x += 1) {
        final cell = draft.cells.firstWhere(
          (candidate) => candidate.localX == x && candidate.localY == y,
        );
        cells.add(
          _NewPathPatternCell(
            key: Key('path-studio-new-path-cell-$x-$y'),
            tilesets: tilesets,
            settings: settings,
            projectRootPath: projectRootPath,
            cell: cell,
            selected: draft.selectedCellX == x && draft.selectedCellY == y,
            onTap: () => onCellSelected(x, y),
          ),
        );
      }
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.backgroundAlt,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

class _NewPathPatternCell extends StatelessWidget {
  const _NewPathPatternCell({
    super.key,
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.cell,
    required this.selected,
    required this.onTap,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraftCell cell;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tile = cell.tile;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 112,
        height: 118,
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color.lerp(
            PathStudioTheme.surfaceStrong,
            selected ? PathStudioTheme.accent : PathStudioTheme.accentCyan,
            selected ? 0.32 : 0.16,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? PathStudioTheme.accentHover
                : PathStudioTheme.accentCyan.withValues(alpha: 0.45),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cell.label,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            if (tile != null)
              _TilePreviewBadge(
                tilesets: tilesets,
                settings: settings,
                projectRootPath: projectRootPath,
                tile: tile,
              )
            else
              const _EmptyTileBadge(),
            const SizedBox(height: 6),
            Text(
              tile == null ? 'À configurer' : 'Configurée',
              style: TextStyle(
                color: tile == null
                    ? PathStudioTheme.textSecondary
                    : PathStudioTheme.success,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              tile == null ? 'Aucune tuile' : 'Tuile ${tile.coordinateLabel}',
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewPathSelectedCellDetails extends StatelessWidget {
  const _NewPathSelectedCellDetails({
    required this.draft,
    required this.onCellCleared,
  });

  final PathStudioNewPathDraft draft;
  final void Function(int localX, int localY) onCellCleared;

  @override
  Widget build(BuildContext context) {
    final cell = draft.selectedCell;
    final tile = cell.tile;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cellule ${cell.label}',
            style: const TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Position ${cell.localX},${cell.localY}',
            style: const TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tile == null
                ? 'Aucune tuile configurée pour cette cellule.'
                : 'Tuile ${tile.coordinateLabel} assignée depuis ${tile.tilesetId}.',
            style: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (tile != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: CupertinoButton(
                key: const Key('path-studio-new-path-clear-selected-cell'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                minimumSize: Size.zero,
                color: PathStudioTheme.error.withValues(alpha: 0.16),
                onPressed: () => onCellCleared(cell.localX, cell.localY),
                child: const Text(
                  'Effacer la cellule',
                  style: TextStyle(
                    color: PathStudioTheme.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TilePreviewBadge extends StatelessWidget {
  const _TilePreviewBadge({
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.tile,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraftTile tile;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 46,
      height: 28,
      decoration: BoxDecoration(
        color: PathStudioTheme.success.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: PathStudioTheme.success.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        tile.coordinateLabel,
        style: const TextStyle(
          color: PathStudioTheme.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    return PathStudioTileSpritePreview(
      projectRootPath: projectRootPath,
      tilesets: tilesets,
      settings: settings,
      tile: tile,
      fallback: fallback,
    );
  }
}

class _EmptyTileBadge extends StatelessWidget {
  const _EmptyTileBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 28,
      decoration: BoxDecoration(
        color: PathStudioTheme.backgroundAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PathStudioTheme.borderStrong.withValues(alpha: 0.65),
        ),
      ),
      alignment: Alignment.center,
      child: const MacosIcon(
        CupertinoIcons.square,
        color: PathStudioTheme.textMuted,
        size: 14,
      ),
    );
  }
}

class _NewPathTilePickerPanel extends StatelessWidget {
  const _NewPathTilePickerPanel({
    required this.tilesets,
    required this.settings,
    required this.projectRootPath,
    required this.draft,
    required this.onTileSelected,
  });

  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final String? projectRootPath;
  final PathStudioNewPathDraft draft;
  final void Function(int sourceX, int sourceY) onTileSelected;

  @override
  Widget build(BuildContext context) {
    final selectedTileset = _selectedTileset(
      tilesets: tilesets,
      tilesetId: draft.tilesetId,
    );
    final tilesetLabel =
        _selectedTilesetLabel(tilesets: tilesets, tilesetId: draft.tilesetId);
    if (tilesetLabel == null || selectedTileset == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: PathStudioTheme.subtleDecoration(
          color: PathStudioTheme.backgroundAlt,
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MacosIcon(
              CupertinoIcons.square_grid_2x2,
              color: PathStudioTheme.textMuted,
              size: 18,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sélectionnez d’abord un tileset',
                    style: TextStyle(
                      color: PathStudioTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Le picker de tuiles s’activera ensuite pour la cellule sélectionnée.',
                    style: TextStyle(
                      color: PathStudioTheme.textSecondary,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final selectedCell = draft.selectedCell;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.backgroundAlt,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MacosIcon(
                CupertinoIcons.square_grid_3x2,
                color: PathStudioTheme.accentCyan,
                size: 18,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Tileset: $tilesetLabel',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PathStudioTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Sélectionnez une tuile pour la cellule ${selectedCell.label}',
            style: const TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          PathStudioImageBackedTilesetPicker(
            projectRootPath: projectRootPath,
            tileset: selectedTileset,
            settings: settings,
            activeCell: selectedCell,
            onTileSelected: (source) => onTileSelected(source.x, source.y),
            fallbackBuilder: (context, result) {
              return _LogicalNewPathTileGrid(
                draft: draft,
                selectedCell: selectedCell,
                onTileSelected: onTileSelected,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LogicalNewPathTileGrid extends StatelessWidget {
  const _LogicalNewPathTileGrid({
    required this.draft,
    required this.selectedCell,
    required this.onTileSelected,
  });

  final PathStudioNewPathDraft draft;
  final PathStudioNewPathDraftCell selectedCell;
  final void Function(int sourceX, int sourceY) onTileSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var y = 0; y < 4; y += 1)
              for (var x = 0; x < 8; x += 1)
                _NewPathTileButton(
                  key: Key('path-studio-new-path-tile-$x-$y'),
                  sourceX: x,
                  sourceY: y,
                  selected: selectedCell.tile?.sourceX == x &&
                      selectedCell.tile?.sourceY == y &&
                      selectedCell.tile?.tilesetId == draft.tilesetId,
                  onTap: () => onTileSelected(x, y),
                ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Fallback V0 : les coordonnées sont enregistrées dans le brouillon quand l’image tileset ne peut pas être chargée.',
          style: TextStyle(
            color: PathStudioTheme.textMuted,
            fontSize: 10.5,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NewPathTileButton extends StatelessWidget {
  const _NewPathTileButton({
    super.key,
    required this.sourceX,
    required this.sourceY,
    required this.selected,
    required this.onTap,
  });

  final int sourceX;
  final int sourceY;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? PathStudioTheme.accentHover : PathStudioTheme.border;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(
                PathStudioTheme.surfaceStrong,
                PathStudioTheme.accentCyan,
                selected ? 0.3 : 0.12,
              )!,
              Color.lerp(
                PathStudioTheme.backgroundAlt,
                PathStudioTheme.accent,
                selected ? 0.26 : 0.08,
              )!,
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: selected ? 2 : 1),
        ),
        alignment: Alignment.center,
        child: Text(
          '$sourceX,$sourceY',
          style: TextStyle(
            color: selected
                ? PathStudioTheme.textPrimary
                : PathStudioTheme.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _NewPathDiagnosticsCard extends StatelessWidget {
  const _NewPathDiagnosticsCard({required this.draft});

  final PathStudioNewPathDraft draft;

  @override
  Widget build(BuildContext context) {
    final issues = draft.issues;
    return _SectionCard(
      title: 'Diagnostics locaux',
      icon: CupertinoIcons.check_mark_circled,
      child: issues.isEmpty
          ? const _DiagnosticRow(
              icon: CupertinoIcons.check_mark_circled_solid,
              color: PathStudioTheme.success,
              title: 'Aucune erreur',
              message: 'Toutes les cellules requises ont une tuile V0.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: issues
                  .map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DiagnosticRow(
                        icon: CupertinoIcons.info_circle_fill,
                        color: issue ==
                                PathStudioNewPathDraftIssueCode.nameRequired
                            ? PathStudioTheme.warning
                            : PathStudioTheme.accentCyan,
                        title: _newPathDraftIssueLabel(issue),
                        message: _newPathDraftIssueDescription(issue),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _DraftCenterWorkspace extends StatelessWidget {
  const _DraftCenterWorkspace({
    required this.draft,
    required this.onSizeChanged,
    required this.onCellSelected,
  });

  final PathPatternDraft draft;
  final void Function(int width, int height) onSizeChanged;
  final void Function(int localX, int localY) onCellSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DraftBanner(),
          const SizedBox(height: 14),
          const _WorkflowSteps(
            status: PathPatternPresetReadinessStatus.needsReview,
          ),
          const SizedBox(height: 14),
          _DraftSummary(draft: draft),
          const SizedBox(height: 14),
          _DraftCenterPatternEditor(
            draft: draft,
            onSizeChanged: onSizeChanged,
            onCellSelected: onCellSelected,
          ),
          const SizedBox(height: 14),
          _DraftDiagnosticsCard(draft: draft),
        ],
      ),
    );
  }
}

class _DraftBanner extends StatelessWidget {
  const _DraftBanner();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Motif depuis path existant',
      icon: CupertinoIcons.pencil_outline,
      trailing: _StatusChip(
        label: 'Non sauvegardé',
        color: PathStudioTheme.warning,
      ),
      child: Text(
        'Ce brouillon réutilise temporairement une structure héritée. Il reste local et non sauvegardé.',
        style: TextStyle(
          color: PathStudioTheme.textSecondary,
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}

class _DraftSummary extends StatelessWidget {
  const _DraftSummary({required this.draft});

  final PathPatternDraft draft;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Résumé du brouillon',
      icon: CupertinoIcons.doc_text,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _InfoTile(label: 'Nom', value: draft.name),
          _InfoTile(label: 'Structure héritée', value: draft.basePathPresetId),
          _InfoTile(label: 'Centre', value: draft.centerPatternLabel),
          _InfoTile(label: 'Cellules', value: '${draft.centerCellCount}'),
          _InfoTile(label: 'Frames', value: '${draft.centerFrameCount}'),
          _InfoTile(
            label: 'Animation',
            value: '${draft.animatedCellCount} cellules',
          ),
          const _InfoTile(label: 'État', value: 'Brouillon non sauvegardé'),
        ],
      ),
    );
  }
}

class _DraftCenterPatternEditor extends StatelessWidget {
  const _DraftCenterPatternEditor({
    required this.draft,
    required this.onSizeChanged,
    required this.onCellSelected,
  });

  final PathPatternDraft draft;
  final void Function(int width, int height) onSizeChanged;
  final void Function(int localX, int localY) onCellSelected;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Motif du centre',
      icon: CupertinoIcons.square_grid_2x2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Le motif du centre sera répété dans les grandes zones pleines.',
            style: TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          CupertinoSlidingSegmentedControl<String>(
            key: const Key('path-studio-draft-size-control'),
            groupValue: draft.centerPatternLabel,
            onValueChanged: (value) {
              if (value == '1×1') {
                onSizeChanged(1, 1);
              } else if (value == '2×2') {
                onSizeChanged(2, 2);
              }
            },
            children: const {
              '1×1': Padding(
                key: Key('path-studio-draft-size-1x1'),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Text('1×1'),
              ),
              '2×2': Padding(
                key: Key('path-studio-draft-size-2x2'),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Text('2×2'),
              ),
            },
          ),
          const SizedBox(height: 18),
          _DraftPatternGrid(
            draft: draft,
            onCellSelected: onCellSelected,
          ),
          const SizedBox(height: 14),
          _DraftSelectedCellDetails(draft: draft),
        ],
      ),
    );
  }
}

class _DraftPatternGrid extends StatelessWidget {
  const _DraftPatternGrid({
    required this.draft,
    required this.onCellSelected,
  });

  final PathPatternDraft draft;
  final void Function(int localX, int localY) onCellSelected;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    var labelCode = 'A'.codeUnitAt(0);
    for (var y = 0; y < draft.centerPattern.size.height; y += 1) {
      final cells = <Widget>[];
      for (var x = 0; x < draft.centerPattern.size.width; x += 1) {
        final cell = draft.centerPattern.cellAt(x, y);
        cells.add(
          _DraftPatternCell(
            key: Key('path-studio-draft-cell-$x-$y'),
            label: String.fromCharCode(labelCode),
            cell: cell,
            selected: draft.selectedCellX == x && draft.selectedCellY == y,
            onTap: () => onCellSelected(x, y),
          ),
        );
        labelCode += 1;
      }
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.backgroundAlt,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

class _DraftPatternCell extends StatelessWidget {
  const _DraftPatternCell({
    super.key,
    required this.label,
    required this.cell,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final PathCenterPatternCell cell;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final source = cell.frames.first.source;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 112,
        height: 92,
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color.lerp(
            PathStudioTheme.surfaceStrong,
            selected ? PathStudioTheme.accent : PathStudioTheme.accentCyan,
            selected ? 0.32 : 0.16,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? PathStudioTheme.accentHover
                : PathStudioTheme.accentCyan.withValues(alpha: 0.45),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              '${cell.frames.length} frame${cell.frames.length > 1 ? 's' : ''}',
              style: const TextStyle(
                color: PathStudioTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              cell.frames.length > 1 ? 'animé' : 'statique',
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'source ${source.x},${source.y}',
              style: const TextStyle(
                color: PathStudioTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftSelectedCellDetails extends StatelessWidget {
  const _DraftSelectedCellDetails({required this.draft});

  final PathPatternDraft draft;

  @override
  Widget build(BuildContext context) {
    final cell = draft.selectedCell;
    final source = cell.frames.first.source;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cellule sélectionnée',
            style: TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Position ${cell.localX},${cell.localY}',
            style: const TextStyle(
              color: PathStudioTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${cell.frames.length} frame${cell.frames.length > 1 ? 's' : ''} • source ${source.x},${source.y}',
            style: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftDiagnosticsCard extends StatelessWidget {
  const _DraftDiagnosticsCard({required this.draft});

  final PathPatternDraft draft;

  @override
  Widget build(BuildContext context) {
    final issues = draft.issues;
    return _SectionCard(
      title: 'Diagnostics locaux',
      icon: CupertinoIcons.check_mark_circled,
      child: issues.isEmpty
          ? const _DiagnosticRow(
              icon: CupertinoIcons.check_mark_circled_solid,
              color: PathStudioTheme.success,
              title: 'Aucune erreur locale',
              message: 'Le brouillon est éditable en mémoire.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: issues
                  .map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DiagnosticRow(
                        icon: CupertinoIcons.exclamationmark_triangle_fill,
                        color: PathStudioTheme.warning,
                        title: _draftIssueLabel(issue),
                        message: _draftIssueDescription(issue),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _NoSelectionCenter extends StatelessWidget {
  const _NoSelectionCenter({required this.hasAnyPreset});

  final bool hasAnyPreset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(
        color: PathStudioTheme.surface,
      ),
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MacosIcon(
              CupertinoIcons.square_grid_2x2,
              color: PathStudioTheme.accentCyan,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              hasAnyPreset
                  ? 'Aucun preset sélectionné'
                  : 'Aucun motif PathPattern',
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasAnyPreset
                  ? 'Sélectionnez un preset dans la liste pour inspecter sa structure.'
                  : 'Les futurs lots permettront de créer un premier motif de centre.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PathStudioTheme.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkflowSteps extends StatelessWidget {
  const _WorkflowSteps({required this.status});

  final PathPatternPresetReadinessStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(
        color: PathStudioTheme.surface,
        radius: 18,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                const _StepPill(
                  index: 1,
                  label: 'Base',
                  active: false,
                  complete: true,
                ),
                const _StepArrow(),
                const _StepPill(
                  index: 2,
                  label: 'Motif du centre',
                  active: true,
                ),
                const _StepArrow(),
                _StepPill(
                  index: 3,
                  label: 'Aperçu',
                  active: false,
                  complete: status == PathPatternPresetReadinessStatus.ready,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({
    required this.index,
    required this.label,
    required this.active,
    this.complete = false,
  });

  final int index;
  final String label;
  final bool active;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? PathStudioTheme.accentHover
        : complete
            ? PathStudioTheme.success
            : PathStudioTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.2 : 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              complete ? '✓' : '$index',
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: active ? PathStudioTheme.textPrimary : color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepArrow extends StatelessWidget {
  const _StepArrow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 10),
      child: MacosIcon(
        CupertinoIcons.chevron_right,
        size: 13,
        color: PathStudioTheme.textMuted,
      ),
    );
  }
}

class _SelectedSummary extends StatelessWidget {
  const _SelectedSummary({required this.card});

  final PathPatternPresetCardModel card;

  @override
  Widget build(BuildContext context) {
    final status = _statusPresentation(card.status);
    return _SectionCard(
      title: 'Résumé du preset',
      icon: CupertinoIcons.doc_text,
      trailing: _StatusChip(label: status.label, color: status.color),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _InfoTile(label: 'Nom', value: card.name),
          _InfoTile(
              label: 'Base', value: card.basePathPresetName ?? 'Introuvable'),
          _InfoTile(label: 'Centre', value: card.centerPatternLabel),
          _InfoTile(label: 'Cellules', value: '${card.centerCellCount}'),
          _InfoTile(label: 'Frames', value: '${card.centerFrameCount}'),
          _InfoTile(
              label: 'Animation', value: '${card.animatedCellCount} cellules'),
          _InfoTile(
            label: 'Transparent',
            value: card.transparentColorHex ?? 'Absent',
          ),
        ],
      ),
    );
  }
}

class _CenterPatternPlaceholder extends StatelessWidget {
  const _CenterPatternPlaceholder({required this.card});

  final PathPatternPresetCardModel card;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Motif du centre',
      icon: CupertinoIcons.square_grid_2x2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniPatternGrid(card: card),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Éditeur read-only',
                  style: TextStyle(
                    color: PathStudioTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'L’édition 1×1 / 2×2 arrivera au lot 14. Cette zone pose seulement la structure du futur espace de travail, sans drag & drop ni génération PNG.',
                  style: TextStyle(
                    color: PathStudioTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
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

class _MiniPatternGrid extends StatelessWidget {
  const _MiniPatternGrid({required this.card});

  final PathPatternPresetCardModel card;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    var labelCode = 'A'.codeUnitAt(0);
    for (var y = 0; y < card.centerHeight; y += 1) {
      final cells = <Widget>[];
      for (var x = 0; x < card.centerWidth; x += 1) {
        cells.add(_PatternCell(label: String.fromCharCode(labelCode)));
        labelCode += 1;
      }
      rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.backgroundAlt,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

class _PatternCell extends StatelessWidget {
  const _PatternCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color.lerp(
          PathStudioTheme.surfaceStrong,
          PathStudioTheme.accentCyan,
          0.18,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: PathStudioTheme.accentCyan.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: PathStudioTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({required this.card});

  final PathPatternPresetCardModel card;

  @override
  Widget build(BuildContext context) {
    final issues = card.issues;
    return _SectionCard(
      title: 'Diagnostics',
      icon: CupertinoIcons.check_mark_circled,
      child: issues.isEmpty
          ? const _DiagnosticRow(
              icon: CupertinoIcons.check_mark_circled_solid,
              color: PathStudioTheme.success,
              title: 'Aucune erreur',
              message: 'Le preset est valide pour le shell V0.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: issues
                  .map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DiagnosticRow(
                        icon: CupertinoIcons.exclamationmark_triangle_fill,
                        color: PathStudioTheme.error,
                        title: _issueLabel(issue),
                        message: _issueDescription(issue),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _PresetInspector extends StatelessWidget {
  const _PresetInspector({
    required this.manifest,
    required this.newPathDraft,
    required this.draft,
    required this.selected,
    required this.onNewPathNameChanged,
    required this.onNewPathTilesetChanged,
    required this.onNewPathSizeChanged,
    required this.onDraftNameChanged,
    required this.onDraftBaseChanged,
    required this.onDraftSizeChanged,
  });

  final ProjectManifest manifest;
  final PathStudioNewPathDraft? newPathDraft;
  final PathPatternDraft? draft;
  final PathPatternPresetCardModel? selected;
  final ValueChanged<String> onNewPathNameChanged;
  final ValueChanged<String> onNewPathTilesetChanged;
  final void Function(int width, int height) onNewPathSizeChanged;
  final ValueChanged<String> onDraftNameChanged;
  final ValueChanged<String> onDraftBaseChanged;
  final void Function(int width, int height) onDraftSizeChanged;

  @override
  Widget build(BuildContext context) {
    final newPathDraft = this.newPathDraft;
    if (newPathDraft != null) {
      return _NewPathInspector(
        tilesets: manifest.tilesets,
        draft: newPathDraft,
        onNameChanged: onNewPathNameChanged,
        onTilesetChanged: onNewPathTilesetChanged,
        onSizeChanged: onNewPathSizeChanged,
      );
    }
    final draft = this.draft;
    if (draft != null) {
      return _LegacyDraftInspector(
        manifest: manifest,
        draft: draft,
        onNameChanged: onDraftNameChanged,
        onBaseChanged: onDraftBaseChanged,
        onSizeChanged: onDraftSizeChanged,
      );
    }
    final card = selected;
    return Container(
      decoration: PathStudioTheme.panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: card == null
          ? const _InspectorEmptyState()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Propriétés du preset',
                    style: TextStyle(
                      color: PathStudioTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InspectorRow(label: 'Nom', value: card.name),
                  _InspectorRow(label: 'ID', value: card.id),
                  _InspectorRow(
                    label: 'Base path preset id',
                    value: card.basePathPresetId,
                  ),
                  _InspectorRow(
                      label: 'Preset de base',
                      value: card.basePathPresetName ?? 'Introuvable'),
                  _InspectorRow(
                      label: 'Surface',
                      value: card.basePathSurfaceKindLabel ?? 'Non disponible'),
                  _InspectorRow(
                      label: 'Taille centre', value: card.centerPatternLabel),
                  _InspectorRow(
                      label: 'Cellules', value: '${card.centerCellCount}'),
                  _InspectorRow(
                      label: 'Frames', value: '${card.centerFrameCount}'),
                  _InspectorRow(
                      label: 'Cellules animées',
                      value: '${card.animatedCellCount}'),
                  _InspectorRow(
                      label: 'Transparent color',
                      value: card.transparentColorHex ?? 'Aucune'),
                  const SizedBox(height: 14),
                  _DiagnosticsCard(card: card),
                ],
              ),
            ),
    );
  }
}

class _NewPathInspector extends StatelessWidget {
  const _NewPathInspector({
    required this.tilesets,
    required this.draft,
    required this.onNameChanged,
    required this.onTilesetChanged,
    required this.onSizeChanged,
  });

  final List<ProjectTilesetEntry> tilesets;
  final PathStudioNewPathDraft draft;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onTilesetChanged;
  final void Function(int width, int height) onSizeChanged;

  @override
  Widget build(BuildContext context) {
    final tilesetLabel =
        _selectedTilesetLabel(tilesets: tilesets, tilesetId: draft.tilesetId) ??
            'À choisir';
    return Container(
      decoration: PathStudioTheme.panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Propriétés du nouveau chemin',
              style: TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const _StatusChip(
              label: 'Brouillon non sauvegardé',
              color: PathStudioTheme.warning,
            ),
            const SizedBox(height: 14),
            const _InspectorLabel('Nom'),
            CupertinoTextField(
              key: const Key('path-studio-new-path-name-field'),
              placeholder: draft.name,
              onChanged: onNameChanged,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              placeholderStyle: const TextStyle(
                color: PathStudioTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              decoration: BoxDecoration(
                color: PathStudioTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PathStudioTheme.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            ),
            const SizedBox(height: 12),
            const _InspectorLabel('Tileset'),
            _NewPathTilesetSelector(
              tilesets: tilesets,
              draft: draft,
              onTilesetChanged: onTilesetChanged,
            ),
            const SizedBox(height: 12),
            const _InspectorLabel('Taille du centre'),
            CupertinoSlidingSegmentedControl<String>(
              groupValue: draft.centerPatternLabel,
              onValueChanged: (value) {
                if (value == '1×1') {
                  onSizeChanged(1, 1);
                } else if (value == '2×2') {
                  onSizeChanged(2, 2);
                }
              },
              children: const {
                '1×1': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('1×1'),
                ),
                '2×2': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('2×2'),
                ),
              },
            ),
            const SizedBox(height: 14),
            _InspectorRow(label: 'ID temporaire', value: draft.id),
            _InspectorRow(label: 'Tileset', value: tilesetLabel),
            _InspectorRow(label: 'Cellules', value: '${draft.centerCellCount}'),
            _InspectorRow(
              label: 'Cellules configurées',
              value: '${draft.configuredCellCount}/${draft.centerCellCount}',
            ),
            _InspectorRow(
              label: 'Cellule sélectionnée',
              value: 'Cellule ${draft.selectedCell.label}',
            ),
            _InspectorRow(
              label: 'Tuile sélectionnée',
              value: draft.selectedCell.tile == null
                  ? 'Aucune tuile'
                  : 'Tuile ${draft.selectedCell.tile!.coordinateLabel}',
            ),
            const _InspectorRow(
              label: 'État',
              value: 'Brouillon non sauvegardé',
            ),
            const _InspectorRow(
              label: 'Sauvegarde',
              value: 'Non disponible dans ce lot',
            ),
            const _InspectorRow(
              label: 'Prochaine étape',
              value: 'Choisir un tileset et définir les tuiles',
            ),
            const SizedBox(height: 14),
            _NewPathDiagnosticsCard(draft: draft),
          ],
        ),
      ),
    );
  }
}

class _LegacyDraftInspector extends StatelessWidget {
  const _LegacyDraftInspector({
    required this.manifest,
    required this.draft,
    required this.onNameChanged,
    required this.onBaseChanged,
    required this.onSizeChanged,
  });

  final ProjectManifest manifest;
  final PathPatternDraft draft;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onBaseChanged;
  final void Function(int width, int height) onSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Propriétés du motif depuis path existant',
              style: TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const _StatusChip(
              label: 'Brouillon non sauvegardé',
              color: PathStudioTheme.warning,
            ),
            const SizedBox(height: 14),
            const _InspectorLabel('Nom'),
            CupertinoTextField(
              key: const Key('path-studio-draft-name-field'),
              placeholder: draft.name,
              onChanged: onNameChanged,
              style: const TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              placeholderStyle: const TextStyle(
                color: PathStudioTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              decoration: BoxDecoration(
                color: PathStudioTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: PathStudioTheme.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            ),
            const SizedBox(height: 12),
            const _InspectorLabel('Structure héritée'),
            _DraftBasePopup(
              manifest: manifest,
              draft: draft,
              onBaseChanged: onBaseChanged,
            ),
            const SizedBox(height: 12),
            const _InspectorLabel('Taille du centre'),
            CupertinoSlidingSegmentedControl<String>(
              groupValue: draft.centerPatternLabel,
              onValueChanged: (value) {
                if (value == '1×1') {
                  onSizeChanged(1, 1);
                } else if (value == '2×2') {
                  onSizeChanged(2, 2);
                }
              },
              children: const {
                '1×1': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('1×1'),
                ),
                '2×2': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text('2×2'),
                ),
              },
            ),
            const SizedBox(height: 14),
            _InspectorRow(label: 'ID temporaire', value: draft.id),
            _InspectorRow(
              label: 'Path existant réutilisé',
              value: draft.basePathPresetId,
            ),
            _InspectorRow(label: 'Cellules', value: '${draft.centerCellCount}'),
            _InspectorRow(label: 'Frames', value: '${draft.centerFrameCount}'),
            _InspectorRow(
              label: 'Cellules animées',
              value: '${draft.animatedCellCount}',
            ),
            _InspectorRow(
              label: 'Transparent color',
              value: draft.transparentColor?.toHexRgb() ?? 'Aucune',
            ),
            const _InspectorRow(
              label: 'État',
              value: 'Brouillon non sauvegardé',
            ),
            const SizedBox(height: 14),
            _DraftDiagnosticsCard(draft: draft),
          ],
        ),
      ),
    );
  }
}

class _DraftBasePopup extends StatelessWidget {
  const _DraftBasePopup({
    required this.manifest,
    required this.draft,
    required this.onBaseChanged,
  });

  final ProjectManifest manifest;
  final PathPatternDraft draft;
  final ValueChanged<String> onBaseChanged;

  @override
  Widget build(BuildContext context) {
    return MacosPopupButton<String>(
      key: const Key('path-studio-draft-base-popup'),
      value: draft.basePathPresetId,
      onChanged: (value) {
        if (value != null) {
          onBaseChanged(value);
        }
      },
      items: [
        for (final preset in manifest.pathPresets)
          MacosPopupMenuItem<String>(
            value: preset.id,
            child: SizedBox(
              width: 220,
              child: Text(
                '${preset.name} (${preset.id})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}

class _NewPathTilesetSelector extends StatelessWidget {
  const _NewPathTilesetSelector({
    required this.tilesets,
    required this.draft,
    required this.onTilesetChanged,
  });

  final List<ProjectTilesetEntry> tilesets;
  final PathStudioNewPathDraft draft;
  final ValueChanged<String> onTilesetChanged;

  @override
  Widget build(BuildContext context) {
    if (tilesets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PathStudioTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PathStudioTheme.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'À choisir',
              style: TextStyle(
                color: PathStudioTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Aucun tileset disponible dans le projet',
              style: TextStyle(
                color: PathStudioTheme.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    final selectedId = tilesets.any((tileset) => tileset.id == draft.tilesetId)
        ? draft.tilesetId!
        : '';
    return MacosPopupButton<String>(
      key: const Key('path-studio-new-path-tileset-popup'),
      value: selectedId,
      onChanged: (value) {
        if (value != null) {
          onTilesetChanged(value);
        }
      },
      items: [
        const MacosPopupMenuItem<String>(
          value: '',
          child: Text('À choisir'),
        ),
        for (final tileset in tilesets)
          MacosPopupMenuItem<String>(
            value: tileset.id,
            child: SizedBox(
              width: 220,
              child: Text(
                _tilesetLabel(tileset),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}

class _InspectorLabel extends StatelessWidget {
  const _InspectorLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: PathStudioTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InspectorEmptyState extends StatelessWidget {
  const _InspectorEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Propriétés du preset',
          style: TextStyle(
            color: PathStudioTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 18),
        _SidebarNotice(
          title: 'Aucun preset sélectionné',
          message: 'Les détails s’afficheront ici après sélection.',
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PathStudioTheme.panelDecoration(
        color: PathStudioTheme.surface,
        radius: 20,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MacosIcon(icon, color: PathStudioTheme.accentCyan, size: 18),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: PathStudioTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorRow extends StatelessWidget {
  const _InspectorRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.surfaceRaised,
        radius: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: PathStudioTheme.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MacosIcon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: PathStudioTheme.textSecondary,
                    fontSize: 11.5,
                    height: 1.3,
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

_StatusPresentation _statusPresentation(
  PathPatternPresetReadinessStatus status,
) {
  return switch (status) {
    PathPatternPresetReadinessStatus.ready => const _StatusPresentation(
        label: 'Prêt',
        color: PathStudioTheme.success,
      ),
    PathPatternPresetReadinessStatus.needsReview => const _StatusPresentation(
        label: 'À vérifier',
        color: PathStudioTheme.warning,
      ),
    PathPatternPresetReadinessStatus.blocked => const _StatusPresentation(
        label: 'Bloqué',
        color: PathStudioTheme.error,
      ),
  };
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;
}

String _issueLabel(PathPatternPresetIssueCode issue) {
  return switch (issue) {
    PathPatternPresetIssueCode.missingBasePathPreset =>
      'Preset de base introuvable',
    PathPatternPresetIssueCode.duplicatePathPatternId =>
      'ID PathPattern dupliqué',
    PathPatternPresetIssueCode.duplicateBasePathPresetId =>
      'Preset de base dupliqué',
  };
}

String _issueDescription(PathPatternPresetIssueCode issue) {
  return switch (issue) {
    PathPatternPresetIssueCode.missingBasePathPreset =>
      'Le preset référence un basePathPresetId absent du manifest.',
    PathPatternPresetIssueCode.duplicatePathPatternId =>
      'Plusieurs PathPattern partagent exactement le même id.',
    PathPatternPresetIssueCode.duplicateBasePathPresetId =>
      'Plusieurs ProjectPathPreset legacy correspondent à la même base.',
  };
}

String _draftIssueLabel(PathPatternDraftIssueCode issue) {
  return switch (issue) {
    PathPatternDraftIssueCode.nameRequired => 'Nom requis',
  };
}

String _draftIssueDescription(PathPatternDraftIssueCode issue) {
  return switch (issue) {
    PathPatternDraftIssueCode.nameRequired =>
      'Le brouillon peut rester éditable, mais son nom devra être renseigné avant une future sauvegarde.',
  };
}

bool _hasSelectedTileset(PathStudioNewPathDraft draft) {
  return draft.tilesetId != null && draft.tilesetId!.isNotEmpty;
}

String _tilesetLabel(ProjectTilesetEntry tileset) {
  return '${tileset.name} (${tileset.id})';
}

String? _selectedTilesetLabel({
  required List<ProjectTilesetEntry> tilesets,
  required String? tilesetId,
}) {
  if (tilesetId == null || tilesetId.isEmpty) {
    return null;
  }
  for (final tileset in tilesets) {
    if (tileset.id == tilesetId) {
      return _tilesetLabel(tileset);
    }
  }
  return tilesetId;
}

ProjectTilesetEntry? _selectedTileset({
  required List<ProjectTilesetEntry> tilesets,
  required String? tilesetId,
}) {
  if (tilesetId == null || tilesetId.isEmpty) {
    return null;
  }
  for (final tileset in tilesets) {
    if (tileset.id == tilesetId) {
      return tileset;
    }
  }
  return null;
}

String _newPathDraftIssueLabel(PathStudioNewPathDraftIssueCode issue) {
  return switch (issue) {
    PathStudioNewPathDraftIssueCode.nameRequired => 'Nom requis',
    PathStudioNewPathDraftIssueCode.tilesetNotConfigured => 'Tileset à choisir',
    PathStudioNewPathDraftIssueCode.cellsNotConfigured =>
      'Cellules à configurer',
  };
}

String _newPathDraftIssueDescription(PathStudioNewPathDraftIssueCode issue) {
  return switch (issue) {
    PathStudioNewPathDraftIssueCode.nameRequired =>
      'Le brouillon peut rester éditable, mais son nom devra être renseigné avant une future sauvegarde.',
    PathStudioNewPathDraftIssueCode.tilesetNotConfigured =>
      'Sélectionnez un tileset du projet pour continuer le brouillon.',
    PathStudioNewPathDraftIssueCode.cellsNotConfigured =>
      'Les cellules existent déjà mais aucune tuile n’est encore choisie.',
  };
}
```


### packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart

```dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:image/image.dart' as img;
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'path_studio_new_path_draft.dart';
import 'path_studio_theme.dart';

enum PathStudioTilesetImageStatus {
  missingProjectRoot,
  missingFile,
  invalidTileSize,
  invalidGrid,
  invalidImage,
  loaded,
}

final class PathStudioResolvedTilesetImage {
  const PathStudioResolvedTilesetImage({
    required this.absolutePath,
    required this.bytes,
    required this.imageWidthPx,
    required this.imageHeightPx,
    required this.tileWidthPx,
    required this.tileHeightPx,
    required this.columns,
    required this.rows,
  });

  final String absolutePath;
  final Uint8List bytes;
  final int imageWidthPx;
  final int imageHeightPx;
  final int tileWidthPx;
  final int tileHeightPx;
  final int columns;
  final int rows;
}

final class PathStudioTilesetImageLoadResult {
  const PathStudioTilesetImageLoadResult({
    required this.status,
    required this.message,
    this.image,
  });

  final PathStudioTilesetImageStatus status;
  final String message;
  final PathStudioResolvedTilesetImage? image;

  bool get hasImage =>
      status == PathStudioTilesetImageStatus.loaded && image != null;
}

Future<PathStudioTilesetImageLoadResult> loadPathStudioTilesetImage({
  required String? projectRootPath,
  required ProjectTilesetEntry tileset,
  required ProjectSettings settings,
}) async {
  final root = projectRootPath?.trim();
  if (root == null || root.isEmpty) {
    return const PathStudioTilesetImageLoadResult(
      status: PathStudioTilesetImageStatus.missingProjectRoot,
      message: 'Racine projet indisponible',
    );
  }

  final tileWidth = settings.tileWidth;
  final tileHeight = settings.tileHeight;
  if (tileWidth <= 0 || tileHeight <= 0) {
    return const PathStudioTilesetImageLoadResult(
      status: PathStudioTilesetImageStatus.invalidTileSize,
      message: 'Dimensions de tuile invalides',
    );
  }

  final absolutePath = p.normalize(p.join(root, tileset.relativePath));
  final file = File(absolutePath);
  if (!file.existsSync()) {
    return const PathStudioTilesetImageLoadResult(
      status: PathStudioTilesetImageStatus.missingFile,
      message: 'Image du tileset introuvable',
    );
  }

  try {
    final bytes = file.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return const PathStudioTilesetImageLoadResult(
        status: PathStudioTilesetImageStatus.invalidImage,
        message: 'Image du tileset illisible',
      );
    }
    final columns = decoded.width ~/ tileWidth;
    final rows = decoded.height ~/ tileHeight;
    if (columns <= 0 || rows <= 0) {
      return const PathStudioTilesetImageLoadResult(
        status: PathStudioTilesetImageStatus.invalidGrid,
        message: 'Impossible de découper ce tileset',
      );
    }
    return PathStudioTilesetImageLoadResult(
      status: PathStudioTilesetImageStatus.loaded,
      message: 'Image du tileset chargée',
      image: PathStudioResolvedTilesetImage(
        absolutePath: absolutePath,
        bytes: bytes,
        imageWidthPx: decoded.width,
        imageHeightPx: decoded.height,
        tileWidthPx: tileWidth,
        tileHeightPx: tileHeight,
        columns: columns,
        rows: rows,
      ),
    );
  } catch (_) {
    return const PathStudioTilesetImageLoadResult(
      status: PathStudioTilesetImageStatus.invalidImage,
      message: 'Image du tileset illisible',
    );
  }
}

TilesetSourceRect pathStudioTileSourceFromLocalPosition({
  required ui.Offset localPosition,
  required ui.Size displaySize,
  required int columns,
  required int rows,
}) {
  if (displaySize.width <= 0 || displaySize.height <= 0) {
    return const TilesetSourceRect(x: 0, y: 0);
  }
  final rawX = (localPosition.dx / displaySize.width * columns).floor();
  final rawY = (localPosition.dy / displaySize.height * rows).floor();
  return TilesetSourceRect(
    x: rawX.clamp(0, columns - 1).toInt(),
    y: rawY.clamp(0, rows - 1).toInt(),
  );
}

typedef PathStudioTilesetFallbackBuilder = Widget Function(
  BuildContext context,
  PathStudioTilesetImageLoadResult result,
);

class PathStudioImageBackedTilesetPicker extends StatefulWidget {
  const PathStudioImageBackedTilesetPicker({
    super.key,
    required this.projectRootPath,
    required this.tileset,
    required this.settings,
    required this.activeCell,
    required this.onTileSelected,
    required this.fallbackBuilder,
  });

  final String? projectRootPath;
  final ProjectTilesetEntry tileset;
  final ProjectSettings settings;
  final PathStudioNewPathDraftCell activeCell;
  final ValueChanged<TilesetSourceRect> onTileSelected;
  final PathStudioTilesetFallbackBuilder fallbackBuilder;

  @override
  State<PathStudioImageBackedTilesetPicker> createState() =>
      _PathStudioImageBackedTilesetPickerState();
}

class _PathStudioImageBackedTilesetPickerState
    extends State<PathStudioImageBackedTilesetPicker> {
  late Future<PathStudioTilesetImageLoadResult> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  @override
  void didUpdateWidget(covariant PathStudioImageBackedTilesetPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectRootPath != widget.projectRootPath ||
        oldWidget.tileset.id != widget.tileset.id ||
        oldWidget.tileset.relativePath != widget.tileset.relativePath ||
        oldWidget.settings.tileWidth != widget.settings.tileWidth ||
        oldWidget.settings.tileHeight != widget.settings.tileHeight) {
      _loadFuture = _load();
    }
  }

  Future<PathStudioTilesetImageLoadResult> _load() {
    return loadPathStudioTilesetImage(
      projectRootPath: widget.projectRootPath,
      tileset: widget.tileset,
      settings: widget.settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PathStudioTilesetImageLoadResult>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _TilesetImageLoadingState();
        }
        final result = snapshot.requireData;
        final image = result.image;
        if (!result.hasImage || image == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TilesetImageFallbackNotice(message: result.message),
              const SizedBox(height: 12),
              widget.fallbackBuilder(context, result),
            ],
          );
        }
        return _LoadedTilesetImagePicker(
          image: image,
          activeCell: widget.activeCell,
          onTileSelected: widget.onTileSelected,
        );
      },
    );
  }
}

class PathStudioTileSpritePreview extends StatefulWidget {
  const PathStudioTileSpritePreview({
    super.key,
    required this.projectRootPath,
    required this.tilesets,
    required this.settings,
    required this.tile,
    required this.fallback,
  });

  final String? projectRootPath;
  final List<ProjectTilesetEntry> tilesets;
  final ProjectSettings settings;
  final PathStudioNewPathDraftTile tile;
  final Widget fallback;

  @override
  State<PathStudioTileSpritePreview> createState() =>
      _PathStudioTileSpritePreviewState();
}

class _PathStudioTileSpritePreviewState
    extends State<PathStudioTileSpritePreview> {
  late Future<PathStudioTilesetImageLoadResult>? _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  @override
  void didUpdateWidget(covariant PathStudioTileSpritePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectRootPath != widget.projectRootPath ||
        oldWidget.tile.tilesetId != widget.tile.tilesetId ||
        _tilesetFingerprint(oldWidget.tilesets, oldWidget.tile.tilesetId) !=
            _tilesetFingerprint(widget.tilesets, widget.tile.tilesetId) ||
        oldWidget.settings.tileWidth != widget.settings.tileWidth ||
        oldWidget.settings.tileHeight != widget.settings.tileHeight) {
      _loadFuture = _load();
    }
  }

  Future<PathStudioTilesetImageLoadResult>? _load() {
    final tileset = _tilesetById(widget.tilesets, widget.tile.tilesetId);
    if (tileset == null) {
      return null;
    }
    return loadPathStudioTilesetImage(
      projectRootPath: widget.projectRootPath,
      tileset: tileset,
      settings: widget.settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadFuture = _loadFuture;
    if (loadFuture == null) {
      return widget.fallback;
    }
    return FutureBuilder<PathStudioTilesetImageLoadResult>(
      future: loadFuture,
      builder: (context, snapshot) {
        final image = snapshot.data?.image;
        if (image == null) {
          return widget.fallback;
        }
        if (widget.tile.sourceX >= image.columns ||
            widget.tile.sourceY >= image.rows) {
          return widget.fallback;
        }
        return _TileSpritePreview(
          key: const Key('path-studio-tile-preview-image'),
          image: image,
          tile: widget.tile,
        );
      },
    );
  }
}

class _TileSpritePreview extends StatelessWidget {
  const _TileSpritePreview({
    super.key,
    required this.image,
    required this.tile,
  });

  final PathStudioResolvedTilesetImage image;
  final PathStudioNewPathDraftTile tile;

  @override
  Widget build(BuildContext context) {
    const previewWidth = 46.0;
    const previewHeight = 28.0;
    return Container(
      width: previewWidth,
      height: previewHeight,
      decoration: BoxDecoration(
        color: PathStudioTheme.backgroundAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PathStudioTheme.success.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRect(
        child: Transform.translate(
          offset: Offset(
            -tile.sourceX * previewWidth,
            -tile.sourceY * previewHeight,
          ),
          child: Image.memory(
            image.bytes,
            width: image.columns * previewWidth,
            height: image.rows * previewHeight,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}

class _LoadedTilesetImagePicker extends StatelessWidget {
  const _LoadedTilesetImagePicker({
    required this.image,
    required this.activeCell,
    required this.onTileSelected,
  });

  final PathStudioResolvedTilesetImage image;
  final PathStudioNewPathDraftCell activeCell;
  final ValueChanged<TilesetSourceRect> onTileSelected;

  @override
  Widget build(BuildContext context) {
    final selectedTile = activeCell.tile;
    return Container(
      key: const Key('path-studio-image-backed-tileset-picker'),
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.surfaceStrong,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MacosIcon(
                CupertinoIcons.photo,
                color: PathStudioTheme.accentCyan,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                'Image du tileset chargée',
                style: TextStyle(
                  color: PathStudioTheme.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                'Grille ${image.columns}×${image.rows}',
                style: const TextStyle(
                  color: PathStudioTheme.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final naturalWidth = image.imageWidthPx.toDouble();
              final naturalHeight = image.imageHeightPx.toDouble();
              final maxWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : naturalWidth;
              final displayWidth = math.min(
                maxWidth,
                math.max(naturalWidth, naturalWidth * 2),
              );
              final displayHeight = displayWidth * naturalHeight / naturalWidth;
              final displaySize = ui.Size(displayWidth, displayHeight);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: GestureDetector(
                  onTapDown: (details) {
                    onTileSelected(
                      pathStudioTileSourceFromLocalPosition(
                        localPosition: details.localPosition,
                        displaySize: displaySize,
                        columns: image.columns,
                        rows: image.rows,
                      ),
                    );
                  },
                  child: SizedBox(
                    key: const Key('path-studio-image-backed-tileset-canvas'),
                    width: displayWidth,
                    height: displayHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(
                            image.bytes,
                            width: displayWidth,
                            height: displayHeight,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.none,
                            gaplessPlayback: true,
                          ),
                        ),
                        CustomPaint(
                          painter: _TilesetImageGridPainter(
                            image: image,
                            selectedSource: selectedTile?.tilesetId == null
                                ? null
                                : TilesetSourceRect(
                                    x: selectedTile!.sourceX,
                                    y: selectedTile.sourceY,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TilesetImageLoadingState extends StatelessWidget {
  const _TilesetImageLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(),
      child: const Text(
        'Chargement du tileset…',
        style: TextStyle(
          color: PathStudioTheme.textSecondary,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TilesetImageFallbackNotice extends StatelessWidget {
  const _TilesetImageFallbackNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: PathStudioTheme.subtleDecoration(
        color: PathStudioTheme.warning.withValues(alpha: 0.1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MacosIcon(
            CupertinoIcons.exclamationmark_triangle,
            color: PathStudioTheme.warning,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: PathStudioTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Utilisation du picker logique',
                  style: TextStyle(
                    color: PathStudioTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class _TilesetImageGridPainter extends CustomPainter {
  const _TilesetImageGridPainter({
    required this.image,
    required this.selectedSource,
  });

  final PathStudioResolvedTilesetImage image;
  final TilesetSourceRect? selectedSource;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final target = ui.Offset.zero & size;
    canvas.save();
    canvas.clipRRect(
      ui.RRect.fromRectAndRadius(target, const ui.Radius.circular(14)),
    );
    final cellWidth = size.width / image.columns;
    final cellHeight = size.height / image.rows;
    final gridPaint = ui.Paint()
      ..color = CupertinoColors.black.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var x = 1; x < image.columns; x += 1) {
      final dx = x * cellWidth;
      canvas.drawLine(ui.Offset(dx, 0), ui.Offset(dx, size.height), gridPaint);
    }
    for (var y = 1; y < image.rows; y += 1) {
      final dy = y * cellHeight;
      canvas.drawLine(ui.Offset(0, dy), ui.Offset(size.width, dy), gridPaint);
    }

    final selected = selectedSource;
    if (selected != null &&
        selected.x >= 0 &&
        selected.y >= 0 &&
        selected.x < image.columns &&
        selected.y < image.rows) {
      final rect = ui.Rect.fromLTWH(
        selected.x * cellWidth,
        selected.y * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(
        rect.deflate(1),
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = PathStudioTheme.accentHover,
      );
      canvas.drawRect(
        rect.deflate(3),
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = PathStudioTheme.accentCyan,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TilesetImageGridPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.selectedSource != selectedSource;
  }
}

ProjectTilesetEntry? _tilesetById(
  List<ProjectTilesetEntry> tilesets,
  String tilesetId,
) {
  for (final tileset in tilesets) {
    if (tileset.id == tilesetId) {
      return tileset;
    }
  }
  return null;
}

String? _tilesetFingerprint(
  List<ProjectTilesetEntry> tilesets,
  String tilesetId,
) {
  final tileset = _tilesetById(tilesets, tilesetId);
  if (tileset == null) {
    return null;
  }
  return '${tileset.id}|${tileset.relativePath}|${tileset.name}';
}
```


### packages/map_editor/test/path_pattern/path_studio_panel_test.dart

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_studio_panel.dart';
import 'package:path/path.dart' as p;

void main() {
  group('PathStudioPanel', () {
    testWidgets('renders a dark empty state when no PathPattern preset exists',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(),
      );

      expect(find.text('Path Studio'), findsOneWidget);
      expect(find.text('Créer des motifs de chemin'), findsOneWidget);
      expect(find.text('Aucun motif PathPattern'), findsWidgets);
      expect(find.text('Aucun preset sélectionné'), findsOneWidget);
      expect(find.text('Propriétés du preset'), findsOneWidget);
    });

    testWidgets('lists presets and updates summary and inspector selection',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(id: 'legacy-water', name: 'Base eau'),
          ],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'water-sea-2x2',
              name: 'Mer 2x2',
              pattern: _twoByTwoPattern(animatedTopLeft: true),
              transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
            ),
            _pathPatternPreset(
              id: 'sand-broken',
              name: 'Sable cassé',
              basePathPresetId: 'missing-base',
            ),
          ],
        ),
      );

      expect(find.text('Mer 2x2'), findsWidgets);
      expect(find.text('Sable cassé'), findsOneWidget);
      expect(find.text('Prêt'), findsWidgets);
      expect(find.text('2×2'), findsWidgets);
      expect(find.text('water-sea-2x2'), findsWidgets);
      expect(find.text('f05ba1'), findsWidgets);

      await tester.tap(find.text('Sable cassé'));
      await tester.pumpAndSettle();

      expect(find.text('missing-base'), findsWidgets);
      expect(find.text('Bloqué'), findsWidgets);
      expect(find.text('Preset de base introuvable'), findsWidgets);
    });

    testWidgets('filters presets locally and clears selection on no result',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(id: 'legacy-water'),
          ],
          pathPatternPresets: [
            _pathPatternPreset(id: 'water-sea', name: 'Mer profonde'),
            _pathPatternPreset(id: 'stone-road', name: 'Route pavée'),
          ],
        ),
      );

      await tester.enterText(
        find.byKey(const Key('path-studio-search-field')),
        'pavée',
      );
      await tester.pumpAndSettle();

      expect(find.text('Route pavée'), findsWidgets);
      expect(find.text('Mer profonde'), findsNothing);
      expect(find.text('stone-road'), findsWidgets);

      await tester.enterText(
        find.byKey(const Key('path-studio-search-field')),
        'zzz',
      );
      await tester.pumpAndSettle();

      expect(find.text('Aucun preset trouvé'), findsOneWidget);
      expect(find.text('Aucun preset sélectionné'), findsWidgets);
    });

    testWidgets('creates a new path draft without legacy base presets',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(),
      );

      final newPathButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Nouveau chemin'),
      );
      final duplicateButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Dupliquer'),
      );
      final saveButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Enregistrer'),
      );

      expect(find.text('Nouveau preset'), findsNothing);
      expect(newPathButton.onPressed, isNotNull);
      expect(duplicateButton.onPressed, isNull);
      expect(saveButton.onPressed, isNull);
      expect(find.text('lot futur'), findsWidgets);

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);

      expect(find.text('Brouillon nouveau chemin'), findsWidgets);
      expect(find.text('Brouillon non sauvegardé'), findsWidgets);
      expect(find.text('Propriétés du nouveau chemin'), findsOneWidget);
      expect(find.text('Nouveau chemin'), findsWidgets);
      expect(find.text('1×1'), findsWidgets);
      expect(find.text('Aucun preset Path de base disponible'), findsNothing);
      expect(find.text('Preset de base'), findsNothing);
      expect(find.text('Base path preset id'), findsNothing);
      expect(
        find.byKey(const Key('path-studio-new-path-cell-0-0')),
        findsOneWidget,
      );
    });

    testWidgets('new path draft does not force existing legacy path choices',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(id: 'mountain-rock', name: 'mountain rock'),
            _legacyPathPreset(id: 'tall_grass', name: 'tall_grass'),
          ],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);

      expect(find.text('Propriétés du nouveau chemin'), findsOneWidget);
      expect(find.text('mountain rock'), findsNothing);
      expect(find.text('tall_grass'), findsNothing);
      expect(
        find.byKey(const Key('path-studio-draft-base-popup')),
        findsNothing,
      );
    });

    testWidgets('new path draft can select a project tileset', (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [
            _tileset(id: 'tileset-main', name: 'Chemins principaux'),
            _tileset(id: 'tileset-extra', name: 'Décor extra'),
          ],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);

      expect(find.text('Tileset'), findsWidgets);
      expect(find.text('À choisir'), findsWidgets);
      expect(find.text('Tileset à choisir'), findsWidgets);

      final popup = tester.widget<MacosPopupButton<String>>(
        find.byKey(const Key('path-studio-new-path-tileset-popup')),
      );
      popup.onChanged?.call('tileset-main');
      await tester.pumpAndSettle();

      expect(find.text('Chemins principaux (tileset-main)'), findsWidgets);
      expect(find.text('Tileset à choisir'), findsNothing);
      expect(find.text('Cellules à configurer'), findsWidgets);
      expect(find.text('À configurer'), findsWidgets);
      expect(find.text('Aucune tuile'), findsWidgets);
      expect(
          find.text('Sélectionnez une tuile pour la cellule A'), findsWidgets);
    });

    testWidgets('new path draft stays usable when the project has no tileset',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);

      expect(find.text('Brouillon nouveau chemin'), findsWidgets);
      expect(
          find.text('Aucun tileset disponible dans le projet'), findsWidgets);
      expect(find.text('Sélectionnez d’abord un tileset'), findsWidgets);
      expect(find.text('Tileset à choisir'), findsWidgets);
    });

    testWidgets('assigns a tileset tile to the 1x1 active cell',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await _pumpPathStudioAsync(tester);

      final tile = find.byKey(const Key('path-studio-new-path-tile-2-1'));
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(find.text('Configurée'), findsWidgets);
      expect(find.text('Tuile 2,1'), findsWidgets);
      expect(find.text('Cellules à configurer'), findsNothing);
      expect(find.text('Tileset à choisir'), findsNothing);
    });

    testWidgets('missing tileset image keeps the logical picker fallback',
        (tester) async {
      final temp = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('path_studio_missing_'),
      ))!;
      addTearDown(() => temp.delete(recursive: true));
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
        projectRootPath: temp.path,
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await _pumpPathStudioAsync(tester);

      expect(find.text('Image du tileset introuvable'), findsWidgets);
      expect(find.byKey(const Key('path-studio-new-path-tile-2-1')),
          findsOneWidget);

      await _tapNewPathTile(tester, tileX: 2, tileY: 1);

      expect(find.text('Tuile 2,1'), findsWidgets);
      expect(find.text('Cellules à configurer'), findsNothing);
    });

    testWidgets('image-backed tileset picker assigns the active cell',
        (tester) async {
      final temp = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('path_studio_image_'),
      ))!;
      addTearDown(() => temp.delete(recursive: true));
      final imageFile = File(p.join(temp.path, 'tilesets/tileset-main.png'));
      await tester.runAsync(() async {
        await imageFile.parent.create(recursive: true);
        await imageFile.writeAsBytes(await _pngBytes(width: 64, height: 32));
      });

      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
        projectRootPath: temp.path,
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await _pumpPathStudioAsync(tester);

      expect(find.byKey(const Key('path-studio-image-backed-tileset-picker')),
          findsOneWidget);
      expect(find.text('Image du tileset chargée'), findsWidgets);
      expect(find.text('Grille 4×2'), findsWidgets);

      await _tapImageBackedTile(tester,
          tileX: 2, tileY: 1, columns: 4, rows: 2);

      expect(find.text('Tuile 2,1'), findsWidgets);
      expect(find.text('Cellules à configurer'), findsNothing);
    });

    testWidgets('image-backed picker fills all 2x2 cells and supports clear',
        (tester) async {
      final temp = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('path_studio_2x2_'),
      ))!;
      addTearDown(() => temp.delete(recursive: true));
      final imageFile = File(p.join(temp.path, 'tilesets/tileset-main.png'));
      await tester.runAsync(() async {
        await imageFile.parent.create(recursive: true);
        await imageFile.writeAsBytes(await _pngBytes(width: 64, height: 32));
      });

      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
        projectRootPath: temp.path,
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await _pumpPathStudioAsync(tester);
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await _pumpPathStudioAsync(tester);
      await tester.tap(
        find.byKey(const Key('path-studio-new-path-size-2x2')),
      );
      await tester.pumpAndSettle();

      await _assignImageBackedTile(
        tester,
        cellX: 0,
        cellY: 0,
        tileX: 0,
        tileY: 0,
        columns: 4,
        rows: 2,
      );
      await _assignImageBackedTile(
        tester,
        cellX: 1,
        cellY: 0,
        tileX: 1,
        tileY: 0,
        columns: 4,
        rows: 2,
      );
      await _assignImageBackedTile(
        tester,
        cellX: 0,
        cellY: 1,
        tileX: 2,
        tileY: 0,
        columns: 4,
        rows: 2,
      );

      expect(find.text('Cellules à configurer'), findsWidgets);

      await _assignImageBackedTile(
        tester,
        cellX: 1,
        cellY: 1,
        tileX: 3,
        tileY: 0,
        columns: 4,
        rows: 2,
      );

      expect(find.text('Cellules à configurer'), findsNothing);
      expect(find.text('Tuile 3,0'), findsWidgets);

      final clearButton =
          find.byKey(const Key('path-studio-new-path-clear-selected-cell'));
      await tester.ensureVisible(clearButton);
      await tester.pumpAndSettle();
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('Cellules à configurer'), findsWidgets);
      expect(find.text('Aucune tuile configurée pour cette cellule.'),
          findsWidgets);
    });

    testWidgets('assigns independent tiles to all 2x2 center cells',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('path-studio-new-path-size-2x2')),
      );
      await tester.pumpAndSettle();

      await _assignNewPathTile(tester, cellX: 0, cellY: 0, tileX: 0, tileY: 0);
      await _assignNewPathTile(tester, cellX: 1, cellY: 0, tileX: 1, tileY: 0);
      await _assignNewPathTile(tester, cellX: 0, cellY: 1, tileX: 0, tileY: 1);

      expect(find.text('Cellules à configurer'), findsWidgets);

      await _assignNewPathTile(tester, cellX: 1, cellY: 1, tileX: 1, tileY: 1);

      expect(find.text('Tuile 0,0'), findsWidgets);
      expect(find.text('Tuile 1,0'), findsWidgets);
      expect(find.text('Tuile 0,1'), findsWidgets);
      expect(find.text('Tuile 1,1'), findsWidgets);
      expect(find.text('Cellules à configurer'), findsNothing);
    });

    testWidgets('replaces and clears the active cell tile', (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await tester.pumpAndSettle();

      await _tapNewPathTile(tester, tileX: 0, tileY: 0);
      await _tapNewPathTile(tester, tileX: 1, tileY: 0);

      expect(find.text('Tuile 1,0'), findsWidgets);
      expect(find.text('Tuile 0,0'), findsNothing);

      final clearButton =
          find.byKey(const Key('path-studio-new-path-clear-selected-cell'));
      await tester.ensureVisible(clearButton);
      await tester.pumpAndSettle();
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('Tuile 1,0'), findsNothing);
      expect(find.text('Aucune tuile configurée pour cette cellule.'),
          findsWidgets);
      expect(find.text('Cellules à configurer'), findsWidgets);
    });

    testWidgets('changing tileset clears configured center cells',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          tilesets: [
            _tileset(id: 'tileset-main', name: 'Chemins principaux'),
            _tileset(id: 'tileset-extra', name: 'Décor extra'),
          ],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();
      final popupFinder =
          find.byKey(const Key('path-studio-new-path-tileset-popup'));
      tester.widget<MacosPopupButton<String>>(popupFinder).onChanged?.call(
            'tileset-main',
          );
      await tester.pumpAndSettle();
      await _tapNewPathTile(tester, tileX: 2, tileY: 1);

      expect(find.text('Tuile 2,1'), findsWidgets);
      expect(find.text('Cellules à configurer'), findsNothing);

      tester.widget<MacosPopupButton<String>>(popupFinder).onChanged?.call(
            'tileset-extra',
          );
      await tester.pumpAndSettle();

      expect(find.text('Décor extra (tileset-extra)'), findsWidgets);
      expect(find.text('Tuile 2,1'), findsNothing);
      expect(find.text('Cellules à configurer'), findsWidgets);
    });

    testWidgets('resizes the new path draft to 2x2 and selects a cell',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('path-studio-new-path-size-2x2')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('path-studio-new-path-cell-0-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('path-studio-new-path-cell-1-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('path-studio-new-path-cell-0-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('path-studio-new-path-cell-1-1')),
        findsOneWidget,
      );
      expect(find.text('A'), findsWidgets);
      expect(find.text('B'), findsWidgets);
      expect(find.text('C'), findsWidgets);
      expect(find.text('D'), findsWidgets);
      expect(find.text('À configurer'), findsWidgets);
      expect(find.text('Aucune tuile'), findsWidgets);
      expect(find.text('Chemins principaux (tileset-main)'), findsWidgets);
      expect(find.textContaining('source '), findsNothing);

      final bottomRightCell =
          find.byKey(const Key('path-studio-new-path-cell-1-1'));
      await tester.ensureVisible(bottomRightCell);
      await tester.pumpAndSettle();
      await tester.tap(bottomRightCell);
      await tester.pumpAndSettle();

      expect(find.text('Cellule sélectionnée'), findsWidgets);
      expect(find.text('Position 1,1'), findsWidgets);
      expect(find.text('Cellule D'), findsWidgets);
    });

    testWidgets('edits new path draft name and keeps save disabled',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('path-studio-new-path-name-field')),
        'Route brouillon',
      );
      await tester.pumpAndSettle();

      expect(find.text('Route brouillon'), findsWidgets);
      final saveButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Enregistrer'),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('secondary legacy flow changes inherited structure locally',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [
            _legacyPathPreset(id: 'legacy-water', name: 'Base eau'),
            _legacyPathPreset(
              id: 'legacy-sand',
              name: 'Base sable',
              crossSourceX: 5,
            ),
          ],
        ),
      );

      await tester.tap(
        find.widgetWithText(CupertinoButton, 'Depuis un path existant'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('path-studio-draft-name-field')),
        'Mer brouillon',
      );
      await tester.pumpAndSettle();

      final popup = tester.widget<MacosPopupButton<String>>(
        find.byKey(const Key('path-studio-draft-base-popup')),
      );
      popup.onChanged?.call('legacy-sand');
      await tester.pumpAndSettle();

      expect(find.text('Propriétés du motif depuis path existant'),
          findsOneWidget);
      expect(find.text('Structure héritée'), findsWidgets);
      expect(find.text('Mer brouillon'), findsWidgets);
      expect(find.text('legacy-sand'), findsWidgets);
      expect(find.text('source 5,0'), findsWidgets);
      expect(find.text('Brouillon non sauvegardé'), findsWidgets);
    });

    testWidgets('empty new path name shows a local diagnostic', (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
        ),
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('path-studio-new-path-name-field')),
        '   ',
      );
      await tester.pumpAndSettle();

      expect(find.text('Nom requis'), findsWidgets);
    });

    testWidgets('secondary legacy flow reports missing existing paths',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(),
      );

      await tester.tap(
        find.widgetWithText(CupertinoButton, 'Depuis un path existant'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aucun path existant disponible'), findsWidgets);

      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
      await tester.pumpAndSettle();

      expect(find.text('Brouillon nouveau chemin'), findsWidgets);
      expect(find.text('Aucun path existant disponible'), findsNothing);
    });
  });
}

Future<void> _pumpPathStudio(
  WidgetTester tester, {
  required ProjectManifest manifest,
  String? projectRootPath,
}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 920));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MacosApp(
      theme: MacosThemeData.dark(),
      home: MacosScaffold(
        children: [
          ContentArea(
            builder: (context, scrollController) {
              return PathStudioPanel(
                manifest: manifest,
                projectRootPath: projectRootPath,
              );
            },
          ),
        ],
      ),
    ),
  );
  await _pumpPathStudioAsync(tester);
}

Future<void> _pumpPathStudioAsync(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> _assignImageBackedTile(
  WidgetTester tester, {
  required int cellX,
  required int cellY,
  required int tileX,
  required int tileY,
  required int columns,
  required int rows,
}) async {
  final cell = find.byKey(Key('path-studio-new-path-cell-$cellX-$cellY'));
  await tester.ensureVisible(cell);
  await _pumpPathStudioAsync(tester);
  await tester.tap(cell);
  await _pumpPathStudioAsync(tester);
  await _tapImageBackedTile(
    tester,
    tileX: tileX,
    tileY: tileY,
    columns: columns,
    rows: rows,
  );
}

Future<void> _tapImageBackedTile(
  WidgetTester tester, {
  required int tileX,
  required int tileY,
  required int columns,
  required int rows,
}) async {
  final picker =
      find.byKey(const Key('path-studio-image-backed-tileset-canvas'));
  await tester.ensureVisible(picker);
  await _pumpPathStudioAsync(tester);
  final topLeft = tester.getTopLeft(picker);
  final size = tester.getSize(picker);
  await tester.tapAt(
    topLeft +
        Offset(
          (tileX + 0.5) * size.width / columns,
          (tileY + 0.5) * size.height / rows,
        ),
  );
  await _pumpPathStudioAsync(tester);
}

Future<void> _assignNewPathTile(
  WidgetTester tester, {
  required int cellX,
  required int cellY,
  required int tileX,
  required int tileY,
}) async {
  final cell = find.byKey(Key('path-studio-new-path-cell-$cellX-$cellY'));
  await tester.ensureVisible(cell);
  await _pumpPathStudioAsync(tester);
  await tester.tap(cell);
  await _pumpPathStudioAsync(tester);
  await _tapNewPathTile(tester, tileX: tileX, tileY: tileY);
}

Future<void> _tapNewPathTile(
  WidgetTester tester, {
  required int tileX,
  required int tileY,
}) async {
  final tile = find.byKey(Key('path-studio-new-path-tile-$tileX-$tileY'));
  await tester.ensureVisible(tile);
  await _pumpPathStudioAsync(tester);
  await tester.tap(tile);
  await _pumpPathStudioAsync(tester);
}

ProjectManifest _manifest({
  List<ProjectPathPreset> pathPresets = const [],
  List<ProjectPathPatternPreset> pathPatternPresets = const [],
  List<ProjectTilesetEntry> tilesets = const [],
  ProjectSettings settings = const ProjectSettings(),
}) {
  return ProjectManifest(
    name: 'Project',
    settings: settings,
    maps: const [],
    tilesets: tilesets,
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

Future<Uint8List> _pngBytes({
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final colors = [
    const ui.Color(0xFFEBCB8B),
    const ui.Color(0xFFA3BE8C),
    const ui.Color(0xFF88C0D0),
    const ui.Color(0xFFB48EAD),
  ];
  var colorIndex = 0;
  for (var y = 0; y < height; y += 16) {
    for (var x = 0; x < width; x += 16) {
      final paint = ui.Paint()..color = colors[colorIndex % colors.length];
      canvas.drawRect(
        ui.Rect.fromLTWH(x.toDouble(), y.toDouble(), 16, 16),
        paint,
      );
      colorIndex += 1;
    }
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

ProjectTilesetEntry _tileset({
  required String id,
  required String name,
}) {
  return ProjectTilesetEntry(
    id: id,
    name: name,
    relativePath: 'tilesets/$id.png',
  );
}

ProjectPathPreset _legacyPathPreset({
  required String id,
  String name = 'Legacy Water',
  int crossSourceX = 0,
}) {
  return ProjectPathPreset(
    id: id,
    name: name,
    surfaceKind: PathSurfaceKind.water,
    variants: [
      PathPresetVariantMapping(
        variant: TerrainPathVariant.cross,
        frames: [_frame(crossSourceX)],
      ),
    ],
  );
}

ProjectPathPatternPreset _pathPatternPreset({
  required String id,
  String? name,
  String basePathPresetId = 'legacy-water',
  PathCenterPattern? pattern,
  TilesetTransparentColor? transparentColor,
}) {
  return ProjectPathPatternPreset(
    id: id,
    name: name ?? id,
    basePathPresetId: basePathPresetId,
    centerPattern: pattern ?? _singleCellPattern(),
    transparentColor: transparentColor,
  );
}

PathCenterPattern _singleCellPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 1, height: 1),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: [_frame(0)],
      ),
    ],
  );
}

PathCenterPattern _twoByTwoPattern({bool animatedTopLeft = false}) {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 2, height: 2),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: animatedTopLeft ? [_frame(0), _frame(1)] : [_frame(0)],
      ),
      PathCenterPatternCell(localX: 1, localY: 0, frames: [_frame(2)]),
      PathCenterPatternCell(localX: 0, localY: 1, frames: [_frame(3)]),
      PathCenterPatternCell(localX: 1, localY: 1, frames: [_frame(4)]),
    ],
  );
}

TilesetVisualFrame _frame(int sourceX) {
  return TilesetVisualFrame(
    source: TilesetSourceRect(x: sourceX, y: 0),
  );
}
```


### packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_studio_tileset_image_picker.dart';
import 'package:path/path.dart' as p;

void main() {
  group('PathStudioTilesetImagePicker image support', () {
    test('resolves an image from project root and tileset relativePath',
        () async {
      final temp = await Directory.systemTemp.createTemp('path_studio_image_');
      addTearDown(() => temp.delete(recursive: true));
      final imageFile = File(p.join(temp.path, 'tilesets/main.png'));
      await imageFile.parent.create(recursive: true);
      await imageFile.writeAsBytes(await _pngBytes(width: 64, height: 32));

      final result = await loadPathStudioTilesetImage(
        projectRootPath: temp.path,
        tileset: const ProjectTilesetEntry(
          id: 'main',
          name: 'Main',
          relativePath: 'tilesets/main.png',
        ),
        settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
      );

      expect(result.status, PathStudioTilesetImageStatus.loaded);
      expect(result.image!.absolutePath, imageFile.path);
      expect(result.image!.imageWidthPx, 64);
      expect(result.image!.imageHeightPx, 32);
      expect(result.image!.columns, 4);
      expect(result.image!.rows, 2);
    });

    test('returns a fallback status when the image file is absent', () async {
      final temp =
          await Directory.systemTemp.createTemp('path_studio_missing_');
      addTearDown(() => temp.delete(recursive: true));

      final result = await loadPathStudioTilesetImage(
        projectRootPath: temp.path,
        tileset: const ProjectTilesetEntry(
          id: 'missing',
          name: 'Missing',
          relativePath: 'tilesets/missing.png',
        ),
        settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
      );

      expect(result.status, PathStudioTilesetImageStatus.missingFile);
      expect(result.image, isNull);
      expect(result.message, contains('introuvable'));
    });

    test('converts a local click position to tile coordinates', () {
      final source = pathStudioTileSourceFromLocalPosition(
        localPosition: const ui.Offset(35, 17),
        displaySize: const ui.Size(128, 64),
        columns: 4,
        rows: 2,
      );

      expect(source.x, 1);
      expect(source.y, 0);
      expect(source.width, 1);
      expect(source.height, 1);
    });
  });
}

Future<Uint8List> _pngBytes({
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint()..color = const ui.Color(0xFFFF00FF);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    paint,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
```


## 19. Note sur le contenu du rapport

Ce fichier est lui-même le rapport créé pour le lot. Son contenu complet est le document courant; il n’est pas recopié une deuxième fois pour éviter une récursion documentaire infinie.
