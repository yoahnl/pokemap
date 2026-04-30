# Lot PathPattern-16 — Center Cell Tile Picker V0

## 1. Résumé exécutif

Verdict : OK, lot fonctionnel et validé.

Le lot ajoute la première vraie brique de composition du motif central dans Path Studio : après création d’un `Nouveau chemin` et sélection d’un tileset, l’utilisateur peut choisir une coordonnée de tuile dans un picker V0 et l’assigner à la cellule active du centre. Le centre 1×1 configure la cellule A ; le centre 2×2 configure A, B, C et D en ordre row-major.

Le modèle reste local à `map_editor`. Aucune sauvegarde, aucun `ProjectManifest`, aucun `map_core`, aucun runtime, aucun gameplay et aucun painter n’ont été modifiés.

Décision UI importante : le `PathStudioPanel` ne reçoit aujourd’hui qu’un `ProjectManifest`; il ne possède pas de chemin absolu de tileset ni de loader image. Le picker V0 affiche donc une grille logique de coordonnées de tuiles, branchée réellement au draft, sans lecture image et sans preview PNG. Ce n’est pas une maquette vide : les coordonnées sélectionnées deviennent des `PathStudioNewPathDraftTile` convertibles en `TilesetVisualFrame`.

## 2. Audit initial

Commandes exécutées avant modification :
```text
/Users/karim/Project/pokemonProject
```

`git status --short --untracked-files=all` initial :
```text
(no output)
```

`git diff --stat` initial :
```text
(no output)
```

`git diff --name-status` initial :
```text
(no output)
```

`find packages/map_editor -name AGENTS.md -print` initial :
```text
(no output)
```

Fichiers suivis audités :
```text
packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

Constats :

- Le worktree était propre au démarrage du lot.
- Aucun `AGENTS.md` plus profond n’a été trouvé sous `packages/map_editor`.
- `PathStudioNewPathDraft` portait déjà `tilesetId`, mais aucune assignation par cellule.
- `cellsNotConfigured` était toujours présent, même après sélection tileset.
- `path_studio_panel.dart` affichait une grille placeholder et un sélecteur tileset, mais aucun picker de tuile.
- `ProjectTilesetEntry` expose `id`, `name`, `relativePath`, `paletteEntries`, mais pas directement dimensions image; les dimensions image existent dans `TilesetEditorCanvas` via chargement d’image/notifier, hors périmètre de ce panneau.
- `TilesetSourceRect` et `TilesetVisualFrame` sont les contrats existants compatibles avec une tuile V0.

Context Mode : disponible et utilisé. Stats observées pendant le lot : `1.8M tokens saved`, `82.2% reduction`, `213 calls`, version `v1.0.103`.

## 3. État constaté avant travaux

Avant Lot 16, le flux principal permettait :

- créer un nouveau chemin local;
- choisir un tileset local;
- choisir la taille 1×1 / 2×2;
- sélectionner une cellule placeholder;
- voir `Tileset à choisir` disparaître après sélection tileset;
- voir `Cellules à configurer` rester présent.

Ce qui manquait :

- aucune cellule ne pouvait recevoir une tuile;
- aucune preview/configuration cellule;
- aucune disparition de `cellsNotConfigured` après configuration complète;
- aucun clear de cellule;
- aucune politique testée sur resize/changement tileset avec assignations.

## 4. Plan d’action

1. Écrire des tests rouges sur le draft local : assignation, remplacement, clear, 1×1, 2×2, resize et changement de tileset.
2. Étendre `PathStudioNewPathDraft` avec une tuile V0 par cellule, immuable et convertible en `TilesetVisualFrame`.
3. Brancher `PathStudioPanel` : cellule active, picker de tuiles logique, clear cellule, résumé et diagnostics.
4. Relancer tests ciblés, régressions éditeur, régressions map_core et analyze ciblé.
5. Produire le rapport final avec contenus complets et diff complet.

## 5. Décisions prises

- V0 = une seule tuile / une seule frame par cellule.
- Une tuile sélectionnée est représentée par `PathStudioNewPathDraftTile(tilesetId, sourceX, sourceY)`.
- `PathStudioNewPathDraftTile.toFrame()` produit un `TilesetVisualFrame` avec `TilesetSourceRect(x, y)`.
- Les assignations sont stockées dans un `Map<String, PathStudioNewPathDraftTile>` immuable, clé `x,y`.
- 1×1 -> 2×2 conserve A et crée B/C/D vides.
- 2×2 -> 1×1 conserve A si elle existe et retire B/C/D.
- Changement de tileset : les cellules configurées sont vidées, car les coordonnées ne sont valides que dans l’atlas courant.
- Sans tileset sélectionné : le picker affiche un empty state clair et ne permet pas d’assigner.
- Avec tileset sélectionné : le picker affiche une grille logique 8×4 de coordonnées V0. Cette limite est volontaire et documentée; elle évite la lecture image et le couplage à l’infrastructure canvas/notifier.
- `cellsNotConfigured` disparaît seulement quand toutes les cellules requises du centre courant ont une tuile.

## 6. Implémentation détaillée

### Modèle local

`PathStudioNewPathDraftTile` a été ajouté côté `map_editor`. Il contient `tilesetId`, `sourceX`, `sourceY`, un label de coordonnée et une conversion vers `TilesetVisualFrame`.

`PathStudioNewPathDraftCell` expose maintenant `tile` et `isConfigured`.

`PathStudioNewPathDraft` expose maintenant :

- `assignedTiles`;
- `configuredCellCount`;
- `allCenterCellsConfigured`;
- equality/hashCode tenant compte des assignations.

Helpers ajoutés :

- `assignPathStudioNewPathDraftCellTile(...)`;
- `clearPathStudioNewPathDraftCell(...)`;
- helpers privés de validation, trimming par taille et comparaison de map.

### UI

`PathStudioPanel` a reçu :

- callbacks `_assignNewPathDraftTile` et `_clearNewPathDraftCell`;
- cards cellule avec état vide/configuré;
- badge visuel de coordonnée configurée;
- détail de cellule sélectionnée avec bouton `Effacer la cellule`;
- `_NewPathTilePickerPanel`;
- `_NewPathTileButton`;
- résumé `Configurées x/y`;
- inspector `Cellules configurées` et `Tuile sélectionnée`;
- diagnostics affichant `Aucune erreur` quand toutes les issues locales disparaissent.

## 7. Fichiers modifiés / créés / supprimés

Modifiés :
- `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart`
- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`
- `packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart`
- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`

Créés :
- `reports/pathPattern/lot_16_center_cell_tile_picker_v0.md`

Supprimés : aucun.

## 8. Tests ajoutés / mis à jour

`path_studio_new_path_draft_test.dart` couvre maintenant :

- assignation 1×1;
- conversion `PathStudioNewPathDraftTile` -> `TilesetVisualFrame`;
- 2×2 partiel puis complet;
- remplacement sans multi-frame implicite;
- clear de cellule;
- resize 1×1 -> 2×2 avec conservation de A;
- resize 2×2 -> 1×1 avec conservation de A;
- changement de tileset qui vide les assignations.

`path_studio_panel_test.dart` couvre maintenant :

- empty state sans tileset;
- picker actif après tileset;
- assignation 1×1;
- assignation indépendante A/B/C/D en 2×2;
- remplacement;
- clear;
- changement de tileset;
- non-régression du flux legacy secondaire.

## 9. Commandes exécutées et résultats

### `flutter test test/path_pattern/path_studio_new_path_draft_test.dart --no-pub --reporter expanded`

CWD: `/Users/karim/Project/pokemonProject/packages/map_editor`

Exit code: `0`

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

### `flutter test test/path_pattern/path_pattern_draft_test.dart --no-pub --reporter expanded`

CWD: `/Users/karim/Project/pokemonProject/packages/map_editor`

Exit code: `0`

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

### `flutter test test/path_pattern/path_studio_panel_test.dart --no-pub --reporter expanded`

CWD: `/Users/karim/Project/pokemonProject/packages/map_editor`

Exit code: `0`

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
00:01 +8: PathStudioPanel assigns independent tiles to all 2x2 center cells
00:02 +9: PathStudioPanel replaces and clears the active cell tile
00:02 +10: PathStudioPanel changing tileset clears configured center cells
00:02 +11: PathStudioPanel resizes the new path draft to 2x2 and selects a cell
00:02 +12: PathStudioPanel edits new path draft name and keeps save disabled
00:02 +13: PathStudioPanel secondary legacy flow changes inherited structure locally
00:03 +14: PathStudioPanel empty new path name shows a local diagnostic
00:03 +15: PathStudioPanel secondary legacy flow reports missing existing paths
00:03 +16: All tests passed!
```

### `flutter test test/path_pattern/ --no-pub --reporter expanded`

CWD: `/Users/karim/Project/pokemonProject/packages/map_editor`

Exit code: `0`

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
00:00 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:00 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:00 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:00 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:01 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
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
00:01 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:01 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:01 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel creates a new path draft without legacy base presets
00:01 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel new path draft does not force existing legacy path choices
00:02 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel new path draft can select a project tileset
00:02 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel new path draft stays usable when the project has no tileset
00:02 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel assigns a tileset tile to the 1x1 active cell
00:02 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel assigns independent tiles to all 2x2 center cells
00:03 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel replaces and clears the active cell tile
00:03 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel changing tileset clears configured center cells
00:03 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel resizes the new path draft to 2x2 and selects a cell
00:03 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel edits new path draft name and keeps save disabled
00:03 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel secondary legacy flow changes inherited structure locally
00:03 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel empty new path name shows a local diagnostic
00:03 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel secondary legacy flow reports missing existing paths
00:03 +71: All tests passed!
```

### `flutter test test/editor_shell_page_smoke_test.dart --no-pub --reporter expanded`

CWD: `/Users/karim/Project/pokemonProject/packages/map_editor`

Exit code: `0`

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart
00:00 +0: EditorShellPage smoke renders map workspace chrome and toggles the right panel
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:01 +1: EditorShellPage smoke updates the workspace header for tileset mode
00:01 +2: EditorShellPage smoke renders the trainer studio workspace chrome
FileProjectRepository: Loading project from /tmp/editor_shell_trainer/project.json
00:01 +3: EditorShellPage smoke renders the Pokémon catalogs workspace shell
00:01 +4: EditorShellPage smoke renders the Items catalogs workspace shell
00:02 +5: EditorShellPage smoke opens Path Studio from the project explorer
00:02 +6: EditorShellPage smoke renders shell chrome with an error state already present
00:02 +7: All tests passed!
```

### `flutter test test/top_toolbar_test.dart --no-pub --reporter expanded`

CWD: `/Users/karim/Project/pokemonProject/packages/map_editor`

Exit code: `0`

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

### `flutter test test/editor_selectors_test.dart --no-pub --reporter expanded`

CWD: `/Users/karim/Project/pokemonProject/packages/map_editor`

Exit code: `0`

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

### `flutter analyze lib/src/features/path_studio test/path_pattern`

CWD: `/Users/karim/Project/pokemonProject/packages/map_editor`

Exit code: `0`

```text
Analyzing 2 items...                                            
No issues found! (ran in 2.1s)
```

### `dart test test/project_manifest_path_pattern_preset_operations_test.dart --reporter expanded --no-color && dart test test/project_manifest_path_pattern_presets_test.dart --reporter expanded --no-color && dart test test/project_path_pattern_preset_json_codec_test.dart --reporter expanded --no-color && dart test test/project_path_pattern_preset_json_golden_test.dart --reporter expanded --no-color && dart test test/project_path_pattern_preset_test.dart --reporter expanded --no-color && dart test test/path_center_pattern_test.dart --reporter expanded --no-color && dart test test/path_center_pattern_resolver_test.dart --reporter expanded --no-color`

CWD: `/Users/karim/Project/pokemonProject/packages/map_core`

Exit code: `0`

```text
00:00 +0: loading test/project_manifest_path_pattern_preset_operations_test.dart
00:00 +0: ProjectManifest PathPattern preset operations read returns the manifest pathPatternPresets in order
00:00 +1: ProjectManifest PathPattern preset operations replace swaps the list, preserves other fields, and keeps order
00:00 +2: ProjectManifest PathPattern preset operations replace accepts an empty list and rejects duplicate exact ids
00:00 +3: ProjectManifest PathPattern preset operations replace treats ids with different whitespace as distinct ids
00:00 +4: ProjectManifest PathPattern preset operations upsert appends a new preset at the end
00:00 +5: ProjectManifest PathPattern preset operations upsert replaces an existing preset in place
00:00 +6: ProjectManifest PathPattern preset operations upsert rejects ambiguous existing duplicate ids
00:00 +7: ProjectManifest PathPattern preset operations remove deletes an existing id and preserves order
00:00 +8: ProjectManifest PathPattern preset operations remove missing id is a no-op with an equivalent new manifest
00:00 +9: ProjectManifest PathPattern preset operations remove rejects blank ids and duplicate matching ids
00:00 +10: ProjectManifest PathPattern preset operations clear removes all path pattern presets without mutating original
00:00 +11: ProjectManifest PathPattern preset operations lookup helpers find exact ids, report missing ids, and reject blanks
00:00 +12: ProjectManifest PathPattern preset operations lookup helpers reject duplicate exact ids
00:00 +13: ProjectManifest PathPattern preset operations operations keep pathPatternPresets JSON stable
00:00 +14: All tests passed!
00:00 +0: loading test/project_manifest_path_pattern_presets_test.dart
00:00 +0: ProjectManifest pathPatternPresets decodes old manifests without pathPatternPresets as empty
00:00 +1: ProjectManifest pathPatternPresets decodes pathPatternPresets null as empty
00:00 +2: ProjectManifest pathPatternPresets decodes and encodes empty pathPatternPresets stably
00:00 +3: ProjectManifest pathPatternPresets decodes the Lot 9 minimal golden through ProjectManifest
00:00 +4: ProjectManifest pathPatternPresets decodes the Lot 9 complete golden through ProjectManifest
00:00 +5: ProjectManifest pathPatternPresets roundtrips manifest pathPatternPresets without changing order
00:00 +6: ProjectManifest pathPatternPresets does not migrate legacy pathPresets into pathPatternPresets
00:00 +7: ProjectManifest pathPatternPresets rejects invalid pathPatternPresets payloads
00:00 +8: All tests passed!
00:00 +0: loading test/project_path_pattern_preset_json_codec_test.dart
00:00 +0: ProjectPathPatternPreset JSON codec encodes a minimal preset
00:00 +1: ProjectPathPatternPreset JSON codec decodes a minimal preset
00:00 +2: ProjectPathPatternPreset JSON codec roundtrips a minimal preset
00:00 +3: ProjectPathPatternPreset JSON codec encodes a complete 2x2 preset in row-major cell order
00:00 +4: ProjectPathPatternPreset JSON codec roundtrips a complete 2x2 preset
00:00 +5: ProjectPathPatternPreset JSON codec canonicalizes transparentColor after decode and encode
00:00 +6: ProjectPathPatternPreset JSON codec roundtrips frame tileset overrides
00:00 +7: ProjectPathPatternPreset JSON codec roundtrips null and non-null frame durations
00:00 +8: ProjectPathPatternPreset JSON codec rejects invalid JSON
00:00 +9: All tests passed!
00:00 +0: loading test/project_path_pattern_preset_json_golden_test.dart
00:00 +0: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden decodes to the expected preset
00:00 +1: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden matches encode output
00:00 +2: ProjectPathPatternPreset JSON golden samples complete 2x2 golden decodes to the expected preset
00:00 +3: ProjectPathPatternPreset JSON golden samples complete 2x2 golden matches encode output
00:00 +4: ProjectPathPatternPreset JSON golden samples goldens roundtrip through decode and encode
00:00 +5: ProjectPathPatternPreset JSON golden samples goldens use two-space canonical formatting with final newline
00:00 +6: All tests passed!
00:00 +0: loading test/project_path_pattern_preset_test.dart
00:00 +0: ProjectPathPatternPreset creates a minimal preset with defaults
00:00 +1: ProjectPathPatternPreset creates a complete preset with a 2x2 center pattern
00:00 +2: ProjectPathPatternPreset rejects blank identity fields
00:00 +3: ProjectPathPatternPreset validates with trim but stores original strings
00:00 +4: ProjectPathPatternPreset supports value equality and stable hashCode
00:00 +5: All tests passed!
00:00 +0: loading test/path_center_pattern_test.dart
00:00 +0: PathCenterPatternSize accepts 1x1 and 2x2 sizes
00:00 +1: PathCenterPatternSize rejects non-positive dimensions
00:00 +2: PathCenterPatternSize reports tile count and coordinate containment
00:00 +3: PathCenterPatternSize uses value equality and stable hashCode
00:00 +4: PathCenterPatternCell accepts non-negative local coordinates and frames
00:00 +5: PathCenterPatternCell rejects negative coordinates and empty frames
00:00 +6: PathCenterPatternCell defensively copies frames and exposes an immutable list
00:00 +7: PathCenterPatternCell uses value equality and stable hashCode
00:00 +8: PathCenterPattern 1x1 accepts a complete single-cell grid
00:00 +9: PathCenterPattern 2x2 accepts a complete grid and exposes cells in row-major order
00:00 +10: PathCenterPattern 2x2 defensively copies cells and exposes an immutable list
00:00 +11: PathCenterPattern 2x2 uses value equality and stable hashCode
00:00 +12: PathCenterPattern invalid grids rejects an empty cell list
00:00 +13: PathCenterPattern invalid grids rejects a missing cell
00:00 +14: PathCenterPattern invalid grids rejects a cell outside the grid
00:00 +15: PathCenterPattern invalid grids rejects duplicate coordinates
00:00 +16: PathCenterPattern invalid grids cellAt rejects coordinates outside the grid
00:00 +17: All tests passed!
00:00 +0: loading test/path_center_pattern_resolver_test.dart
00:00 +0: resolvePathCenterPatternCell 1x1 always resolves to the single local cell
00:00 +1: resolvePathCenterPatternCell 2x2 uses absolute map coordinates modulo pattern size
00:00 +2: resolvePathCenterPatternCell rectangular 3x2 does not assume square patterns
00:00 +3: resolvePathCenterPatternCell invalid coordinates rejects negative map coordinates
00:00 +4: PathCenterPatternCellResolution keeps map coordinates, local coordinates, and selected cell
00:00 +5: PathCenterPatternCellResolution uses value equality and stable hashCode
00:00 +6: All tests passed!
```

## 10. Résultats des validations

- `flutter test test/path_pattern/path_studio_new_path_draft_test.dart --no-pub --reporter expanded` dans `/Users/karim/Project/pokemonProject/packages/map_editor` : PASS — `00:00 +12: All tests passed!`
- `flutter test test/path_pattern/path_pattern_draft_test.dart --no-pub --reporter expanded` dans `/Users/karim/Project/pokemonProject/packages/map_editor` : PASS — `00:00 +6: All tests passed!`
- `flutter test test/path_pattern/path_studio_panel_test.dart --no-pub --reporter expanded` dans `/Users/karim/Project/pokemonProject/packages/map_editor` : PASS — `00:03 +16: All tests passed!`
- `flutter test test/path_pattern/ --no-pub --reporter expanded` dans `/Users/karim/Project/pokemonProject/packages/map_editor` : PASS — `00:03 +71: All tests passed!`
- `flutter test test/editor_shell_page_smoke_test.dart --no-pub --reporter expanded` dans `/Users/karim/Project/pokemonProject/packages/map_editor` : PASS — `00:02 +7: All tests passed!`
- `flutter test test/top_toolbar_test.dart --no-pub --reporter expanded` dans `/Users/karim/Project/pokemonProject/packages/map_editor` : PASS — `00:00 +5: All tests passed!`
- `flutter test test/editor_selectors_test.dart --no-pub --reporter expanded` dans `/Users/karim/Project/pokemonProject/packages/map_editor` : PASS — `00:00 +8: All tests passed!`
- `flutter analyze lib/src/features/path_studio test/path_pattern` dans `/Users/karim/Project/pokemonProject/packages/map_editor` : PASS — `No issues found! (ran in 2.1s)`
- `dart test test/project_manifest_path_pattern_preset_operations_test.dart --reporter expanded --no-color && dart test test/project_manifest_path_pattern_presets_test.dart --reporter expanded --no-color && dart test test/project_path_pattern_preset_json_codec_test.dart --reporter expanded --no-color && dart test test/project_path_pattern_preset_json_golden_test.dart --reporter expanded --no-color && dart test test/project_path_pattern_preset_test.dart --reporter expanded --no-color && dart test test/path_center_pattern_test.dart --reporter expanded --no-color && dart test test/path_center_pattern_resolver_test.dart --reporter expanded --no-color` dans `/Users/karim/Project/pokemonProject/packages/map_core` : PASS — `00:00 +6: All tests passed!`

Analyze ciblé : PASS — `No issues found! (ran in 2.8s)` lors de la passe capturée.

## 11. Limites connues / non-objectifs

- Le picker n’affiche pas l’image réelle du tileset; il affiche une grille logique de coordonnées. Raison : le panneau Path Studio ne reçoit pas d’accès filesystem/notifier/image loader dans ce lot.
- La grille V0 est fixe 8×4. Elle suffit aux tests et au flux V0, mais devra devenir dépendante des dimensions image lors d’un lot ultérieur.
- Pas de drag & drop.
- Pas de multi-frame ni timeline.
- Pas de preview PNG / animée.
- Pas de sauvegarde.
- Pas de mutation manifest.
- Pas de painter/canvas/runtime/gameplay/battle.
- Pas de map_core modifié.
- Pas de tall grass.
- Pas de Surface Studio, TSX/TMX, Mistral, PixelLab ou MCP produit.

## 12. Auto-review critique

- Audit initial réalisé : oui.
- Git write effectué : non.
- Périmètre du lot respecté : oui, uniquement draft local + UI + tests + rapport.
- Tile picker fonctionnel : oui, en grille logique V0.
- Assignation cellule fonctionnelle : oui.
- 1×1 couvert : oui.
- 2×2 couvert : oui.
- Clear cellule fonctionnel : oui.
- Readiness cohérente : oui, `cellsNotConfigured` dépend de toutes les cellules requises.
- UX lisible : oui, cellules vides/configurées/sélectionnées, picker et clear visibles.
- Tests ciblés ajoutés/mis à jour : oui.
- Régressions lancées : oui.
- Analyze ciblé lancé : oui.
- Rapport créé dans `reports/pathPattern/` : oui.
- Review séparée : tentée via sub-agent, mais le sub-agent n’a pas répondu avant timeout et a été arrêté. Review critique locale réalisée ensuite.

Points de vigilance :

- `path_studio_panel.dart` est désormais très long. Le lot respecte le périmètre, mais le prochain lot devrait extraire les sous-widgets Path Studio en fichiers ciblés avant d’ajouter beaucoup de complexité.
- La grille logique 8×4 est une solution V0 honnête, mais elle devra être remplacée par un navigateur fondé sur les dimensions réelles du tileset.
- La conversion vers `TilesetVisualFrame` est prête côté draft, mais aucune conversion persistante vers `ProjectPathPatternPreset` n’est encore branchée.

## 13. Critique du prompt

Ce qui était clair :

- le périmètre V0 une tuile / une frame par cellule;
- pas de save flow, pas de runtime, pas de painter;
- les cas fonctionnels obligatoires 1×1, 2×2, remplacement, clear, resize, changement tileset;
- l’exigence UX dark mode propre et non factice.

Ce qui était ambigu ou discutable :

- Le prompt demande un tileset browser visuel, mais le `PathStudioPanel` actuel n’a pas accès à l’image ou au filesystem. Brancher un vrai atlas aurait nécessité d’élargir vers notifier/filesystem/image loading, donc j’ai retenu une grille logique V0.
- La demande “beaucoup de commentaires utiles” contredit certains lots précédents qui demandaient peu de commentaires; ici j’ai suivi la demande la plus récente, mais seulement sur les décisions non triviales.
- Le rapport demande le contenu complet des fichiers modifiés. Inclure aussi le contenu complet du rapport dans lui-même créerait une récursion non bornée; le rapport courant n’est donc pas recopié dans sa propre Evidence Pack.
- Le bonus drag & drop est explicitement optionnel; il aurait élargi le risque, donc je ne l’ai pas ajouté.

## 14. Checklist finale

- [x] audit initial réalisé.
- [x] aucun git write effectué.
- [x] périmètre du lot respecté.
- [x] tile picker fonctionnel.
- [x] assignation des cellules fonctionnelle.
- [x] 1×1 couvert.
- [x] 2×2 couvert.
- [x] clear cellule fonctionnel.
- [x] logique de readiness cohérente.
- [x] UX lisible et propre.
- [x] tests ciblés ajoutés / mis à jour.
- [x] régressions lancées.
- [x] analyze ciblé lancé.
- [x] rapport final créé dans reports/pathPattern/.
- [x] auto-review faite.
- [x] critique du prompt faite.

## 15. Evidence Pack

### Git status avant écriture du rapport

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

### git diff --stat

```text
 .../path_studio/path_studio_new_path_draft.dart    | 210 +++++++++-
 .../features/path_studio/path_studio_panel.dart    | 427 +++++++++++++++++++--
 .../path_studio_new_path_draft_test.dart           | 219 ++++++++++-
 .../test/path_pattern/path_studio_panel_test.dart  | 171 +++++++++
 4 files changed, 982 insertions(+), 45 deletions(-)
```

### git diff --name-status

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

### Diffs complets des fichiers modifiés

#### `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
index d287ca87..c52f510d 100644
--- a/packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
+++ b/packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
@@ -1,19 +1,64 @@
+import 'package:map_core/map_core.dart';
+
 enum PathStudioNewPathDraftIssueCode {
   nameRequired,
   tilesetNotConfigured,
   cellsNotConfigured,
 }
 
+/// Tuile V0 assignée à une cellule du centre.
+///
+/// Le Path Studio ne gère pas encore les animations ni les frames multiples.
+/// Cette valeur locale représente donc exactement une frame statique : un
+/// tileset projet et une coordonnée de tuile dans cet atlas.
+final class PathStudioNewPathDraftTile {
+  const PathStudioNewPathDraftTile({
+    required this.tilesetId,
+    required this.sourceX,
+    required this.sourceY,
+  })  : assert(sourceX >= 0),
+        assert(sourceY >= 0);
+
+  final String tilesetId;
+  final int sourceX;
+  final int sourceY;
+
+  String get coordinateLabel => '$sourceX,$sourceY';
+
+  TilesetVisualFrame toFrame() {
+    return TilesetVisualFrame(
+      tilesetId: tilesetId,
+      source: TilesetSourceRect(x: sourceX, y: sourceY),
+    );
+  }
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is PathStudioNewPathDraftTile &&
+            tilesetId == other.tilesetId &&
+            sourceX == other.sourceX &&
+            sourceY == other.sourceY;
+  }
+
+  @override
+  int get hashCode => Object.hash(tilesetId, sourceX, sourceY);
+}
+
 final class PathStudioNewPathDraftCell {
   const PathStudioNewPathDraftCell({
     required this.localX,
     required this.localY,
     required this.label,
+    this.tile,
   });
 
   final int localX;
   final int localY;
   final String label;
+  final PathStudioNewPathDraftTile? tile;
+
+  bool get isConfigured => tile != null;
 
   @override
   bool operator ==(Object other) {
@@ -21,11 +66,12 @@ final class PathStudioNewPathDraftCell {
         other is PathStudioNewPathDraftCell &&
             localX == other.localX &&
             localY == other.localY &&
-            label == other.label;
+            label == other.label &&
+            tile == other.tile;
   }
 
   @override
-  int get hashCode => Object.hash(localX, localY, label);
+  int get hashCode => Object.hash(localX, localY, label, tile);
 }
 
 final class PathStudioNewPathDraft {
@@ -38,10 +84,14 @@ final class PathStudioNewPathDraft {
     required this.selectedCellX,
     required this.selectedCellY,
     required this.isDirty,
+    Map<String, PathStudioNewPathDraftTile> assignedTiles = const {},
   })  : assert(centerWidth > 0),
         assert(centerHeight > 0),
         assert(selectedCellX >= 0 && selectedCellX < centerWidth),
-        assert(selectedCellY >= 0 && selectedCellY < centerHeight);
+        assert(selectedCellY >= 0 && selectedCellY < centerHeight),
+        assignedTiles = Map<String, PathStudioNewPathDraftTile>.unmodifiable(
+          assignedTiles,
+        );
 
   final String id;
   final String name;
@@ -52,10 +102,22 @@ final class PathStudioNewPathDraft {
   final int selectedCellY;
   final bool isDirty;
 
+  /// Assignations locales des cellules du centre, indexées par `x,y`.
+  ///
+  /// Le map est immuable pour éviter qu'un widget ou test modifie le brouillon
+  /// en place. Les helpers de ce fichier retournent toujours une nouvelle
+  /// instance de [PathStudioNewPathDraft].
+  final Map<String, PathStudioNewPathDraftTile> assignedTiles;
+
   String get centerPatternLabel => '$centerWidth×$centerHeight';
 
   int get centerCellCount => centerWidth * centerHeight;
 
+  int get configuredCellCount =>
+      cells.where((cell) => cell.isConfigured).length;
+
+  bool get allCenterCellsConfigured => configuredCellCount == centerCellCount;
+
   List<PathStudioNewPathDraftCell> get cells {
     final result = <PathStudioNewPathDraftCell>[];
     var labelCode = 'A'.codeUnitAt(0);
@@ -66,6 +128,7 @@ final class PathStudioNewPathDraft {
             localX: x,
             localY: y,
             label: String.fromCharCode(labelCode),
+            tile: assignedTiles[_cellKey(x, y)],
           ),
         );
         labelCode += 1;
@@ -88,7 +151,9 @@ final class PathStudioNewPathDraft {
     if (tilesetId == null || tilesetId!.isEmpty) {
       result.add(PathStudioNewPathDraftIssueCode.tilesetNotConfigured);
     }
-    result.add(PathStudioNewPathDraftIssueCode.cellsNotConfigured);
+    if (!allCenterCellsConfigured) {
+      result.add(PathStudioNewPathDraftIssueCode.cellsNotConfigured);
+    }
     return List<PathStudioNewPathDraftIssueCode>.unmodifiable(result);
   }
 
@@ -101,6 +166,7 @@ final class PathStudioNewPathDraft {
     int? selectedCellX,
     int? selectedCellY,
     bool? isDirty,
+    Map<String, PathStudioNewPathDraftTile>? assignedTiles,
   }) {
     return PathStudioNewPathDraft(
       id: id ?? this.id,
@@ -113,6 +179,7 @@ final class PathStudioNewPathDraft {
       selectedCellX: selectedCellX ?? this.selectedCellX,
       selectedCellY: selectedCellY ?? this.selectedCellY,
       isDirty: isDirty ?? this.isDirty,
+      assignedTiles: assignedTiles ?? this.assignedTiles,
     );
   }
 
@@ -127,7 +194,8 @@ final class PathStudioNewPathDraft {
             centerHeight == other.centerHeight &&
             selectedCellX == other.selectedCellX &&
             selectedCellY == other.selectedCellY &&
-            isDirty == other.isDirty;
+            isDirty == other.isDirty &&
+            _assignedTileMapsEqual(assignedTiles, other.assignedTiles);
   }
 
   @override
@@ -140,6 +208,7 @@ final class PathStudioNewPathDraft {
         selectedCellX,
         selectedCellY,
         isDirty,
+        _assignedTileMapHash(assignedTiles),
       );
 }
 
@@ -162,12 +231,20 @@ PathStudioNewPathDraft resizePathStudioNewPathDraftCenter({
   required int width,
   required int height,
 }) {
+  if (width <= 0 || height <= 0) {
+    throw ArgumentError.value('$width×$height', 'size', 'must be positive');
+  }
   return draft.copyWith(
     centerWidth: width,
     centerHeight: height,
     selectedCellX: draft.selectedCellX.clamp(0, width - 1).toInt(),
     selectedCellY: draft.selectedCellY.clamp(0, height - 1).toInt(),
     isDirty: true,
+    assignedTiles: _trimAssignedTilesForSize(
+      draft.assignedTiles,
+      width: width,
+      height: height,
+    ),
   );
 }
 
@@ -182,22 +259,131 @@ PathStudioNewPathDraft selectPathStudioNewPathDraftTileset(
   PathStudioNewPathDraft draft,
   String tilesetId,
 ) {
-  return draft.copyWith(tilesetId: tilesetId, isDirty: true);
+  // Une coordonnée `2,3` n'a de sens que dans l'atlas courant. Changer de
+  // tileset vide donc les cellules plutôt que de garder une assignation qui
+  // aurait l'air valide tout en pointant vers une autre image.
+  return draft.copyWith(
+    tilesetId: tilesetId.isEmpty ? null : tilesetId,
+    assignedTiles: const {},
+    isDirty: true,
+  );
 }
 
-PathStudioNewPathDraft selectPathStudioNewPathDraftCell({
+PathStudioNewPathDraft assignPathStudioNewPathDraftCellTile({
   required PathStudioNewPathDraft draft,
   required int localX,
   required int localY,
+  required int sourceX,
+  required int sourceY,
 }) {
-  if (localX < 0 ||
-      localY < 0 ||
-      localX >= draft.centerWidth ||
-      localY >= draft.centerHeight) {
-    throw RangeError.range(localX, 0, draft.centerWidth - 1, 'localX');
+  final tilesetId = draft.tilesetId;
+  if (tilesetId == null || tilesetId.isEmpty) {
+    throw StateError('A tileset must be selected before assigning a tile.');
+  }
+  if (sourceX < 0) {
+    throw ArgumentError.value(sourceX, 'sourceX', 'must be non-negative');
   }
+  if (sourceY < 0) {
+    throw ArgumentError.value(sourceY, 'sourceY', 'must be non-negative');
+  }
+  _validateCellCoordinates(draft: draft, localX: localX, localY: localY);
+
+  final nextTiles = Map<String, PathStudioNewPathDraftTile>.from(
+    draft.assignedTiles,
+  );
+  nextTiles[_cellKey(localX, localY)] = PathStudioNewPathDraftTile(
+    tilesetId: tilesetId,
+    sourceX: sourceX,
+    sourceY: sourceY,
+  );
+  return draft.copyWith(assignedTiles: nextTiles, isDirty: true);
+}
+
+PathStudioNewPathDraft clearPathStudioNewPathDraftCell({
+  required PathStudioNewPathDraft draft,
+  required int localX,
+  required int localY,
+}) {
+  _validateCellCoordinates(draft: draft, localX: localX, localY: localY);
+
+  final nextTiles = Map<String, PathStudioNewPathDraftTile>.from(
+    draft.assignedTiles,
+  )..remove(_cellKey(localX, localY));
+  return draft.copyWith(assignedTiles: nextTiles, isDirty: true);
+}
+
+PathStudioNewPathDraft selectPathStudioNewPathDraftCell({
+  required PathStudioNewPathDraft draft,
+  required int localX,
+  required int localY,
+}) {
+  _validateCellCoordinates(draft: draft, localX: localX, localY: localY);
   return draft.copyWith(
     selectedCellX: localX,
     selectedCellY: localY,
   );
 }
+
+String _cellKey(int localX, int localY) => '$localX,$localY';
+
+void _validateCellCoordinates({
+  required PathStudioNewPathDraft draft,
+  required int localX,
+  required int localY,
+}) {
+  if (localX < 0 || localX >= draft.centerWidth) {
+    throw RangeError.range(localX, 0, draft.centerWidth - 1, 'localX');
+  }
+  if (localY < 0 || localY >= draft.centerHeight) {
+    throw RangeError.range(localY, 0, draft.centerHeight - 1, 'localY');
+  }
+}
+
+Map<String, PathStudioNewPathDraftTile> _trimAssignedTilesForSize(
+  Map<String, PathStudioNewPathDraftTile> assignedTiles, {
+  required int width,
+  required int height,
+}) {
+  final kept = <String, PathStudioNewPathDraftTile>{};
+  for (final entry in assignedTiles.entries) {
+    final parts = entry.key.split(',');
+    if (parts.length != 2) {
+      continue;
+    }
+    final localX = int.tryParse(parts[0]);
+    final localY = int.tryParse(parts[1]);
+    if (localX == null || localY == null) {
+      continue;
+    }
+    if (localX >= 0 && localX < width && localY >= 0 && localY < height) {
+      kept[entry.key] = entry.value;
+    }
+  }
+  return kept;
+}
+
+bool _assignedTileMapsEqual(
+  Map<String, PathStudioNewPathDraftTile> left,
+  Map<String, PathStudioNewPathDraftTile> right,
+) {
+  if (identical(left, right)) {
+    return true;
+  }
+  if (left.length != right.length) {
+    return false;
+  }
+  for (final entry in left.entries) {
+    if (right[entry.key] != entry.value) {
+      return false;
+    }
+  }
+  return true;
+}
+
+int _assignedTileMapHash(Map<String, PathStudioNewPathDraftTile> tiles) {
+  final entries = tiles.entries.toList()
+    ..sort((left, right) => left.key.compareTo(right.key));
+  return Object.hashAll(
+    entries.map((entry) => Object.hash(entry.key, entry.value)),
+  );
+}
```

#### `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
index 71fa2897..bad7b526 100644
--- a/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
@@ -156,6 +156,8 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
                       hasAnyPreset: readModel.presets.isNotEmpty,
                       onNewPathSizeChanged: _resizeNewPathDraft,
                       onNewPathCellSelected: _selectNewPathDraftCell,
+                      onNewPathTileSelected: _assignNewPathDraftTile,
+                      onNewPathCellCleared: _clearNewPathDraftCell,
                       onDraftSizeChanged: _resizeDraft,
                       onDraftCellSelected: _selectDraftCell,
                     ),
@@ -336,6 +338,36 @@ class _PathStudioPanelState extends State<PathStudioPanel> {
     });
   }
 
+  void _assignNewPathDraftTile(int sourceX, int sourceY) {
+    final draft = _newPathDraft;
+    if (draft == null) {
+      return;
+    }
+    setState(() {
+      _newPathDraft = assignPathStudioNewPathDraftCellTile(
+        draft: draft,
+        localX: draft.selectedCellX,
+        localY: draft.selectedCellY,
+        sourceX: sourceX,
+        sourceY: sourceY,
+      );
+    });
+  }
+
+  void _clearNewPathDraftCell(int localX, int localY) {
+    final draft = _newPathDraft;
+    if (draft == null) {
+      return;
+    }
+    setState(() {
+      _newPathDraft = clearPathStudioNewPathDraftCell(
+        draft: draft,
+        localX: localX,
+        localY: localY,
+      );
+    });
+  }
+
   void _renameDraft(String name) {
     final draft = _draft;
     if (draft == null) {
@@ -1229,6 +1261,8 @@ class _CenterWorkspace extends StatelessWidget {
     required this.hasAnyPreset,
     required this.onNewPathSizeChanged,
     required this.onNewPathCellSelected,
+    required this.onNewPathTileSelected,
+    required this.onNewPathCellCleared,
     required this.onDraftSizeChanged,
     required this.onDraftCellSelected,
   });
@@ -1240,6 +1274,8 @@ class _CenterWorkspace extends StatelessWidget {
   final bool hasAnyPreset;
   final void Function(int width, int height) onNewPathSizeChanged;
   final void Function(int localX, int localY) onNewPathCellSelected;
+  final void Function(int sourceX, int sourceY) onNewPathTileSelected;
+  final void Function(int localX, int localY) onNewPathCellCleared;
   final void Function(int width, int height) onDraftSizeChanged;
   final void Function(int localX, int localY) onDraftCellSelected;
 
@@ -1252,6 +1288,8 @@ class _CenterWorkspace extends StatelessWidget {
         draft: newPathDraft,
         onSizeChanged: onNewPathSizeChanged,
         onCellSelected: onNewPathCellSelected,
+        onTileSelected: onNewPathTileSelected,
+        onCellCleared: onNewPathCellCleared,
       );
     }
     final draft = this.draft;
@@ -1290,12 +1328,16 @@ class _NewPathCenterWorkspace extends StatelessWidget {
     required this.draft,
     required this.onSizeChanged,
     required this.onCellSelected,
+    required this.onTileSelected,
+    required this.onCellCleared,
   });
 
   final List<ProjectTilesetEntry> tilesets;
   final PathStudioNewPathDraft draft;
   final void Function(int width, int height) onSizeChanged;
   final void Function(int localX, int localY) onCellSelected;
+  final void Function(int sourceX, int sourceY) onTileSelected;
+  final void Function(int localX, int localY) onCellCleared;
 
   @override
   Widget build(BuildContext context) {
@@ -1310,9 +1352,12 @@ class _NewPathCenterWorkspace extends StatelessWidget {
           _NewPathSummary(tilesets: tilesets, draft: draft),
           const SizedBox(height: 14),
           _NewPathCenterPatternEditor(
+            tilesets: tilesets,
             draft: draft,
             onSizeChanged: onSizeChanged,
             onCellSelected: onCellSelected,
+            onTileSelected: onTileSelected,
+            onCellCleared: onCellCleared,
           ),
           const SizedBox(height: 14),
           _NewPathDiagnosticsCard(draft: draft),
@@ -1401,7 +1446,10 @@ class _NewPathSummary extends StatelessWidget {
           _InfoTile(label: 'Tileset', value: tilesetLabel),
           _InfoTile(label: 'Centre', value: draft.centerPatternLabel),
           _InfoTile(label: 'Cellules', value: '${draft.centerCellCount}'),
-          const _InfoTile(label: 'Contenu', value: 'À configurer'),
+          _InfoTile(
+            label: 'Configurées',
+            value: '${draft.configuredCellCount}/${draft.centerCellCount}',
+          ),
           const _InfoTile(label: 'État', value: 'Brouillon non sauvegardé'),
         ],
       ),
@@ -1411,14 +1459,20 @@ class _NewPathSummary extends StatelessWidget {
 
 class _NewPathCenterPatternEditor extends StatelessWidget {
   const _NewPathCenterPatternEditor({
+    required this.tilesets,
     required this.draft,
     required this.onSizeChanged,
     required this.onCellSelected,
+    required this.onTileSelected,
+    required this.onCellCleared,
   });
 
+  final List<ProjectTilesetEntry> tilesets;
   final PathStudioNewPathDraft draft;
   final void Function(int width, int height) onSizeChanged;
   final void Function(int localX, int localY) onCellSelected;
+  final void Function(int sourceX, int sourceY) onTileSelected;
+  final void Function(int localX, int localY) onCellCleared;
 
   @override
   Widget build(BuildContext context) {
@@ -1466,7 +1520,16 @@ class _NewPathCenterPatternEditor extends StatelessWidget {
             onCellSelected: onCellSelected,
           ),
           const SizedBox(height: 14),
-          _NewPathSelectedCellDetails(draft: draft),
+          _NewPathSelectedCellDetails(
+            draft: draft,
+            onCellCleared: onCellCleared,
+          ),
+          const SizedBox(height: 14),
+          _NewPathTilePickerPanel(
+            tilesets: tilesets,
+            draft: draft,
+            onTileSelected: onTileSelected,
+          ),
         ],
       ),
     );
@@ -1527,11 +1590,12 @@ class _NewPathPatternCell extends StatelessWidget {
 
   @override
   Widget build(BuildContext context) {
+    final tile = cell.tile;
     return GestureDetector(
       onTap: onTap,
       child: Container(
         width: 112,
-        height: 92,
+        height: 118,
         margin: const EdgeInsets.all(6),
         padding: const EdgeInsets.all(10),
         decoration: BoxDecoration(
@@ -1560,17 +1624,24 @@ class _NewPathPatternCell extends StatelessWidget {
               ),
             ),
             const Spacer(),
-            const Text(
-              'À configurer',
+            if (tile != null)
+              _TilePreviewBadge(tile: tile)
+            else
+              const _EmptyTileBadge(),
+            const SizedBox(height: 6),
+            Text(
+              tile == null ? 'À configurer' : 'Configurée',
               style: TextStyle(
-                color: PathStudioTheme.textSecondary,
+                color: tile == null
+                    ? PathStudioTheme.textSecondary
+                    : PathStudioTheme.success,
                 fontSize: 11,
                 fontWeight: FontWeight.w800,
               ),
             ),
-            const Text(
-              'Aucune tuile',
-              style: TextStyle(
+            Text(
+              tile == null ? 'Aucune tuile' : 'Tuile ${tile.coordinateLabel}',
+              style: const TextStyle(
                 color: PathStudioTheme.textMuted,
                 fontSize: 10,
                 fontWeight: FontWeight.w700,
@@ -1584,13 +1655,18 @@ class _NewPathPatternCell extends StatelessWidget {
 }
 
 class _NewPathSelectedCellDetails extends StatelessWidget {
-  const _NewPathSelectedCellDetails({required this.draft});
+  const _NewPathSelectedCellDetails({
+    required this.draft,
+    required this.onCellCleared,
+  });
 
   final PathStudioNewPathDraft draft;
+  final void Function(int localX, int localY) onCellCleared;
 
   @override
   Widget build(BuildContext context) {
     final cell = draft.selectedCell;
+    final tile = cell.tile;
     return Container(
       padding: const EdgeInsets.all(12),
       decoration: PathStudioTheme.subtleDecoration(),
@@ -1614,11 +1690,224 @@ class _NewPathSelectedCellDetails extends StatelessWidget {
               fontWeight: FontWeight.w700,
             ),
           ),
+          const SizedBox(height: 6),
+          Text(
+            tile == null
+                ? 'Aucune tuile configurée pour cette cellule.'
+                : 'Tuile ${tile.coordinateLabel} assignée depuis ${tile.tilesetId}.',
+            style: const TextStyle(
+              color: PathStudioTheme.textMuted,
+              fontSize: 11,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+          if (tile != null) ...[
+            const SizedBox(height: 10),
+            Align(
+              alignment: Alignment.centerLeft,
+              child: CupertinoButton(
+                key: const Key('path-studio-new-path-clear-selected-cell'),
+                padding: const EdgeInsets.symmetric(
+                  horizontal: 12,
+                  vertical: 7,
+                ),
+                minimumSize: Size.zero,
+                color: PathStudioTheme.error.withValues(alpha: 0.16),
+                onPressed: () => onCellCleared(cell.localX, cell.localY),
+                child: const Text(
+                  'Effacer la cellule',
+                  style: TextStyle(
+                    color: PathStudioTheme.error,
+                    fontSize: 11,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+              ),
+            ),
+          ],
+        ],
+      ),
+    );
+  }
+}
+
+class _TilePreviewBadge extends StatelessWidget {
+  const _TilePreviewBadge({required this.tile});
+
+  final PathStudioNewPathDraftTile tile;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      width: 46,
+      height: 28,
+      decoration: BoxDecoration(
+        color: PathStudioTheme.success.withValues(alpha: 0.16),
+        borderRadius: BorderRadius.circular(8),
+        border:
+            Border.all(color: PathStudioTheme.success.withValues(alpha: 0.5)),
+      ),
+      alignment: Alignment.center,
+      child: Text(
+        tile.coordinateLabel,
+        style: const TextStyle(
+          color: PathStudioTheme.textPrimary,
+          fontSize: 10,
+          fontWeight: FontWeight.w900,
+        ),
+      ),
+    );
+  }
+}
+
+class _EmptyTileBadge extends StatelessWidget {
+  const _EmptyTileBadge();
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      width: 46,
+      height: 28,
+      decoration: BoxDecoration(
+        color: PathStudioTheme.backgroundAlt,
+        borderRadius: BorderRadius.circular(8),
+        border: Border.all(
+          color: PathStudioTheme.borderStrong.withValues(alpha: 0.65),
+        ),
+      ),
+      alignment: Alignment.center,
+      child: const MacosIcon(
+        CupertinoIcons.square,
+        color: PathStudioTheme.textMuted,
+        size: 14,
+      ),
+    );
+  }
+}
+
+class _NewPathTilePickerPanel extends StatelessWidget {
+  const _NewPathTilePickerPanel({
+    required this.tilesets,
+    required this.draft,
+    required this.onTileSelected,
+  });
+
+  final List<ProjectTilesetEntry> tilesets;
+  final PathStudioNewPathDraft draft;
+  final void Function(int sourceX, int sourceY) onTileSelected;
+
+  @override
+  Widget build(BuildContext context) {
+    final tilesetLabel =
+        _selectedTilesetLabel(tilesets: tilesets, tilesetId: draft.tilesetId);
+    if (tilesetLabel == null) {
+      return Container(
+        padding: const EdgeInsets.all(14),
+        decoration: PathStudioTheme.subtleDecoration(
+          color: PathStudioTheme.backgroundAlt,
+        ),
+        child: const Row(
+          crossAxisAlignment: CrossAxisAlignment.start,
+          children: [
+            MacosIcon(
+              CupertinoIcons.square_grid_2x2,
+              color: PathStudioTheme.textMuted,
+              size: 18,
+            ),
+            SizedBox(width: 10),
+            Expanded(
+              child: Column(
+                crossAxisAlignment: CrossAxisAlignment.start,
+                children: [
+                  Text(
+                    'Sélectionnez d’abord un tileset',
+                    style: TextStyle(
+                      color: PathStudioTheme.textPrimary,
+                      fontSize: 13,
+                      fontWeight: FontWeight.w800,
+                    ),
+                  ),
+                  SizedBox(height: 4),
+                  Text(
+                    'Le picker de tuiles s’activera ensuite pour la cellule sélectionnée.',
+                    style: TextStyle(
+                      color: PathStudioTheme.textSecondary,
+                      fontSize: 11.5,
+                      height: 1.3,
+                    ),
+                  ),
+                ],
+              ),
+            ),
+          ],
+        ),
+      );
+    }
+
+    final selectedCell = draft.selectedCell;
+    return Container(
+      padding: const EdgeInsets.all(14),
+      decoration: PathStudioTheme.subtleDecoration(
+        color: PathStudioTheme.backgroundAlt,
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Row(
+            children: [
+              const MacosIcon(
+                CupertinoIcons.square_grid_3x2,
+                color: PathStudioTheme.accentCyan,
+                size: 18,
+              ),
+              const SizedBox(width: 9),
+              Expanded(
+                child: Text(
+                  'Tileset: $tilesetLabel',
+                  overflow: TextOverflow.ellipsis,
+                  style: const TextStyle(
+                    color: PathStudioTheme.textPrimary,
+                    fontSize: 13,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+              ),
+            ],
+          ),
+          const SizedBox(height: 6),
+          Text(
+            'Sélectionnez une tuile pour la cellule ${selectedCell.label}',
+            style: const TextStyle(
+              color: PathStudioTheme.textSecondary,
+              fontSize: 12,
+              height: 1.35,
+            ),
+          ),
+          const SizedBox(height: 12),
+          Wrap(
+            spacing: 8,
+            runSpacing: 8,
+            children: [
+              for (var y = 0; y < 4; y += 1)
+                for (var x = 0; x < 8; x += 1)
+                  _NewPathTileButton(
+                    key: Key('path-studio-new-path-tile-$x-$y'),
+                    sourceX: x,
+                    sourceY: y,
+                    selected: selectedCell.tile?.sourceX == x &&
+                        selectedCell.tile?.sourceY == y &&
+                        selectedCell.tile?.tilesetId == draft.tilesetId,
+                    onTap: () => onTileSelected(x, y),
+                  ),
+            ],
+          ),
+          const SizedBox(height: 10),
           const Text(
-            'Aucune tuile configurée pour cette cellule.',
+            'Grille logique V0 : les coordonnées sont enregistrées dans le brouillon, sans lecture de l’image tileset ni preview PNG.',
             style: TextStyle(
               color: PathStudioTheme.textMuted,
-              fontSize: 11,
+              fontSize: 10.5,
+              height: 1.35,
               fontWeight: FontWeight.w700,
             ),
           ),
@@ -1628,6 +1917,67 @@ class _NewPathSelectedCellDetails extends StatelessWidget {
   }
 }
 
+class _NewPathTileButton extends StatelessWidget {
+  const _NewPathTileButton({
+    super.key,
+    required this.sourceX,
+    required this.sourceY,
+    required this.selected,
+    required this.onTap,
+  });
+
+  final int sourceX;
+  final int sourceY;
+  final bool selected;
+  final VoidCallback onTap;
+
+  @override
+  Widget build(BuildContext context) {
+    final color =
+        selected ? PathStudioTheme.accentHover : PathStudioTheme.border;
+    return CupertinoButton(
+      padding: EdgeInsets.zero,
+      minimumSize: Size.zero,
+      onPressed: onTap,
+      child: Container(
+        width: 46,
+        height: 46,
+        decoration: BoxDecoration(
+          gradient: LinearGradient(
+            begin: Alignment.topLeft,
+            end: Alignment.bottomRight,
+            colors: [
+              Color.lerp(
+                PathStudioTheme.surfaceStrong,
+                PathStudioTheme.accentCyan,
+                selected ? 0.3 : 0.12,
+              )!,
+              Color.lerp(
+                PathStudioTheme.backgroundAlt,
+                PathStudioTheme.accent,
+                selected ? 0.26 : 0.08,
+              )!,
+            ],
+          ),
+          borderRadius: BorderRadius.circular(10),
+          border: Border.all(color: color, width: selected ? 2 : 1),
+        ),
+        alignment: Alignment.center,
+        child: Text(
+          '$sourceX,$sourceY',
+          style: TextStyle(
+            color: selected
+                ? PathStudioTheme.textPrimary
+                : PathStudioTheme.textSecondary,
+            fontSize: 10.5,
+            fontWeight: FontWeight.w900,
+          ),
+        ),
+      ),
+    );
+  }
+}
+
 class _NewPathDiagnosticsCard extends StatelessWidget {
   const _NewPathDiagnosticsCard({required this.draft});
 
@@ -1635,27 +1985,36 @@ class _NewPathDiagnosticsCard extends StatelessWidget {
 
   @override
   Widget build(BuildContext context) {
+    final issues = draft.issues;
     return _SectionCard(
       title: 'Diagnostics locaux',
       icon: CupertinoIcons.check_mark_circled,
-      child: Column(
-        crossAxisAlignment: CrossAxisAlignment.stretch,
-        children: draft.issues
-            .map(
-              (issue) => Padding(
-                padding: const EdgeInsets.only(bottom: 8),
-                child: _DiagnosticRow(
-                  icon: CupertinoIcons.info_circle_fill,
-                  color: issue == PathStudioNewPathDraftIssueCode.nameRequired
-                      ? PathStudioTheme.warning
-                      : PathStudioTheme.accentCyan,
-                  title: _newPathDraftIssueLabel(issue),
-                  message: _newPathDraftIssueDescription(issue),
-                ),
-              ),
+      child: issues.isEmpty
+          ? const _DiagnosticRow(
+              icon: CupertinoIcons.check_mark_circled_solid,
+              color: PathStudioTheme.success,
+              title: 'Aucune erreur',
+              message: 'Toutes les cellules requises ont une tuile V0.',
             )
-            .toList(growable: false),
-      ),
+          : Column(
+              crossAxisAlignment: CrossAxisAlignment.stretch,
+              children: issues
+                  .map(
+                    (issue) => Padding(
+                      padding: const EdgeInsets.only(bottom: 8),
+                      child: _DiagnosticRow(
+                        icon: CupertinoIcons.info_circle_fill,
+                        color: issue ==
+                                PathStudioNewPathDraftIssueCode.nameRequired
+                            ? PathStudioTheme.warning
+                            : PathStudioTheme.accentCyan,
+                        title: _newPathDraftIssueLabel(issue),
+                        message: _newPathDraftIssueDescription(issue),
+                      ),
+                    ),
+                  )
+                  .toList(growable: false),
+            ),
     );
   }
 }
@@ -2569,10 +2928,20 @@ class _NewPathInspector extends StatelessWidget {
             _InspectorRow(label: 'ID temporaire', value: draft.id),
             _InspectorRow(label: 'Tileset', value: tilesetLabel),
             _InspectorRow(label: 'Cellules', value: '${draft.centerCellCount}'),
+            _InspectorRow(
+              label: 'Cellules configurées',
+              value: '${draft.configuredCellCount}/${draft.centerCellCount}',
+            ),
             _InspectorRow(
               label: 'Cellule sélectionnée',
               value: 'Cellule ${draft.selectedCell.label}',
             ),
+            _InspectorRow(
+              label: 'Tuile sélectionnée',
+              value: draft.selectedCell.tile == null
+                  ? 'Aucune tuile'
+                  : 'Tuile ${draft.selectedCell.tile!.coordinateLabel}',
+            ),
             const _InspectorRow(
               label: 'État',
               value: 'Brouillon non sauvegardé',
```

#### `packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart`

```diff
diff --git a/packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart b/packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
index 4a155d94..0af6f38c 100644
--- a/packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
+++ b/packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
@@ -1,4 +1,5 @@
 import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/features/path_studio/path_studio_new_path_draft.dart';
 
 void main() {
@@ -41,12 +42,161 @@ void main() {
       expect(selected.isDirty, isTrue);
     });
 
-    test('resizes a 1x1 draft to 2x2 placeholder cells', () {
+    test('assigns one V0 tile to the 1x1 cell and clears cell issue', () {
       final draft = selectPathStudioNewPathDraftTileset(
         createInitialPathStudioNewPathDraft(),
         'tileset-main',
       );
 
+      final assigned = assignPathStudioNewPathDraftCellTile(
+        draft: draft,
+        localX: 0,
+        localY: 0,
+        sourceX: 2,
+        sourceY: 3,
+      );
+
+      expect(assigned.configuredCellCount, 1);
+      expect(assigned.issues, isEmpty);
+      expect(
+        assigned.selectedCell.tile,
+        const PathStudioNewPathDraftTile(
+          tilesetId: 'tileset-main',
+          sourceX: 2,
+          sourceY: 3,
+        ),
+      );
+      expect(
+        assigned.selectedCell.tile!.toFrame(),
+        const TilesetVisualFrame(
+          tilesetId: 'tileset-main',
+          source: TilesetSourceRect(x: 2, y: 3),
+        ),
+      );
+    });
+
+    test('keeps cells issue until every 2x2 cell has one tile', () {
+      var draft = resizePathStudioNewPathDraftCenter(
+        draft: selectPathStudioNewPathDraftTileset(
+          createInitialPathStudioNewPathDraft(),
+          'tileset-main',
+        ),
+        width: 2,
+        height: 2,
+      );
+
+      draft = assignPathStudioNewPathDraftCellTile(
+        draft: draft,
+        localX: 0,
+        localY: 0,
+        sourceX: 0,
+        sourceY: 0,
+      );
+      expect(draft.configuredCellCount, 1);
+      expect(
+        draft.issues,
+        contains(PathStudioNewPathDraftIssueCode.cellsNotConfigured),
+      );
+
+      draft = assignPathStudioNewPathDraftCellTile(
+        draft: draft,
+        localX: 1,
+        localY: 0,
+        sourceX: 1,
+        sourceY: 0,
+      );
+      draft = assignPathStudioNewPathDraftCellTile(
+        draft: draft,
+        localX: 0,
+        localY: 1,
+        sourceX: 0,
+        sourceY: 1,
+      );
+      draft = assignPathStudioNewPathDraftCellTile(
+        draft: draft,
+        localX: 1,
+        localY: 1,
+        sourceX: 1,
+        sourceY: 1,
+      );
+
+      expect(draft.configuredCellCount, 4);
+      expect(
+        draft.issues,
+        isNot(contains(PathStudioNewPathDraftIssueCode.cellsNotConfigured)),
+      );
+    });
+
+    test('replaces a configured cell instead of adding a second frame', () {
+      final draft = selectPathStudioNewPathDraftTileset(
+        createInitialPathStudioNewPathDraft(),
+        'tileset-main',
+      );
+      final first = assignPathStudioNewPathDraftCellTile(
+        draft: draft,
+        localX: 0,
+        localY: 0,
+        sourceX: 0,
+        sourceY: 0,
+      );
+
+      final replaced = assignPathStudioNewPathDraftCellTile(
+        draft: first,
+        localX: 0,
+        localY: 0,
+        sourceX: 4,
+        sourceY: 2,
+      );
+
+      expect(replaced.configuredCellCount, 1);
+      expect(
+        replaced.selectedCell.tile,
+        const PathStudioNewPathDraftTile(
+          tilesetId: 'tileset-main',
+          sourceX: 4,
+          sourceY: 2,
+        ),
+      );
+    });
+
+    test('clears a configured required cell and restores cell issue', () {
+      final assigned = assignPathStudioNewPathDraftCellTile(
+        draft: selectPathStudioNewPathDraftTileset(
+          createInitialPathStudioNewPathDraft(),
+          'tileset-main',
+        ),
+        localX: 0,
+        localY: 0,
+        sourceX: 2,
+        sourceY: 3,
+      );
+
+      final cleared = clearPathStudioNewPathDraftCell(
+        draft: assigned,
+        localX: 0,
+        localY: 0,
+      );
+
+      expect(cleared.configuredCellCount, 0);
+      expect(cleared.selectedCell.tile, isNull);
+      expect(
+        cleared.issues,
+        contains(PathStudioNewPathDraftIssueCode.cellsNotConfigured),
+      );
+    });
+
+    test('resizes a 1x1 draft to 2x2 while preserving cell A only', () {
+      final draft = assignPathStudioNewPathDraftCellTile(
+        draft: selectPathStudioNewPathDraftTileset(
+          createInitialPathStudioNewPathDraft(),
+          'tileset-main',
+        ),
+        localX: 0,
+        localY: 0,
+        sourceX: 2,
+        sourceY: 3,
+      );
+
       final resized = resizePathStudioNewPathDraftCenter(
         draft: draft,
         width: 2,
@@ -65,16 +215,42 @@ void main() {
           (1, 1, 'D'),
         ],
       );
+      expect(
+        resized.cells.first.tile,
+        const PathStudioNewPathDraftTile(
+          tilesetId: 'tileset-main',
+          sourceX: 2,
+          sourceY: 3,
+        ),
+      );
+      expect(resized.cells.skip(1).every((cell) => cell.tile == null), isTrue);
       expect(resized.selectedCellX, 0);
       expect(resized.selectedCellY, 0);
     });
 
-    test('resizes a 2x2 draft back to 1x1 and clamps selection', () {
-      final twoByTwo = resizePathStudioNewPathDraftCenter(
-        draft: createInitialPathStudioNewPathDraft(),
+    test('resizes a 2x2 draft back to 1x1 and keeps only cell A', () {
+      var twoByTwo = resizePathStudioNewPathDraftCenter(
+        draft: selectPathStudioNewPathDraftTileset(
+          createInitialPathStudioNewPathDraft(),
+          'tileset-main',
+        ),
         width: 2,
         height: 2,
       );
+      twoByTwo = assignPathStudioNewPathDraftCellTile(
+        draft: twoByTwo,
+        localX: 0,
+        localY: 0,
+        sourceX: 0,
+        sourceY: 0,
+      );
+      twoByTwo = assignPathStudioNewPathDraftCellTile(
+        draft: twoByTwo,
+        localX: 1,
+        localY: 1,
+        sourceX: 4,
+        sourceY: 4,
+      );
       final selected = selectPathStudioNewPathDraftCell(
         draft: twoByTwo,
         localX: 1,
@@ -92,6 +268,41 @@ void main() {
       expect(resized.centerCellCount, 1);
       expect(resized.selectedCellX, 0);
       expect(resized.selectedCellY, 0);
+      expect(
+        resized.selectedCell.tile,
+        const PathStudioNewPathDraftTile(
+          tilesetId: 'tileset-main',
+          sourceX: 0,
+          sourceY: 0,
+        ),
+      );
+      expect(resized.configuredCellCount, 1);
+    });
+
+    test('selecting another tileset clears cell assignments deterministically',
+        () {
+      final assigned = assignPathStudioNewPathDraftCellTile(
+        draft: selectPathStudioNewPathDraftTileset(
+          createInitialPathStudioNewPathDraft(),
+          'tileset-main',
+        ),
+        localX: 0,
+        localY: 0,
+        sourceX: 2,
+        sourceY: 3,
+      );
+
+      final changed = selectPathStudioNewPathDraftTileset(
+        assigned,
+        'tileset-extra',
+      );
+
+      expect(changed.tilesetId, 'tileset-extra');
+      expect(changed.configuredCellCount, 0);
+      expect(changed.selectedCell.tile, isNull);
+      expect(changed.issues, [
+        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
+      ]);
     });
 
     test('renames the draft locally', () {
```

#### `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`

```diff
diff --git a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
index 42f14d04..3511aa41 100644
--- a/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
+++ b/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
@@ -187,6 +187,8 @@ void main() {
       expect(find.text('Cellules à configurer'), findsWidgets);
       expect(find.text('À configurer'), findsWidgets);
       expect(find.text('Aucune tuile'), findsWidgets);
+      expect(
+          find.text('Sélectionnez une tuile pour la cellule A'), findsWidgets);
     });
 
     testWidgets('new path draft stays usable when the project has no tileset',
@@ -202,9 +204,151 @@ void main() {
       expect(find.text('Brouillon nouveau chemin'), findsWidgets);
       expect(
           find.text('Aucun tileset disponible dans le projet'), findsWidgets);
+      expect(find.text('Sélectionnez d’abord un tileset'), findsWidgets);
       expect(find.text('Tileset à choisir'), findsWidgets);
     });
 
+    testWidgets('assigns a tileset tile to the 1x1 active cell',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
+        ),
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await tester.pumpAndSettle();
+      tester
+          .widget<MacosPopupButton<String>>(
+            find.byKey(const Key('path-studio-new-path-tileset-popup')),
+          )
+          .onChanged
+          ?.call('tileset-main');
+      await tester.pumpAndSettle();
+
+      final tile = find.byKey(const Key('path-studio-new-path-tile-2-1'));
+      await tester.ensureVisible(tile);
+      await tester.pumpAndSettle();
+      await tester.tap(tile);
+      await tester.pumpAndSettle();
+
+      expect(find.text('Configurée'), findsWidgets);
+      expect(find.text('Tuile 2,1'), findsWidgets);
+      expect(find.text('Cellules à configurer'), findsNothing);
+      expect(find.text('Tileset à choisir'), findsNothing);
+    });
+
+    testWidgets('assigns independent tiles to all 2x2 center cells',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
+        ),
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await tester.pumpAndSettle();
+      tester
+          .widget<MacosPopupButton<String>>(
+            find.byKey(const Key('path-studio-new-path-tileset-popup')),
+          )
+          .onChanged
+          ?.call('tileset-main');
+      await tester.pumpAndSettle();
+      await tester.tap(
+        find.byKey(const Key('path-studio-new-path-size-2x2')),
+      );
+      await tester.pumpAndSettle();
+
+      await _assignNewPathTile(tester, cellX: 0, cellY: 0, tileX: 0, tileY: 0);
+      await _assignNewPathTile(tester, cellX: 1, cellY: 0, tileX: 1, tileY: 0);
+      await _assignNewPathTile(tester, cellX: 0, cellY: 1, tileX: 0, tileY: 1);
+
+      expect(find.text('Cellules à configurer'), findsWidgets);
+
+      await _assignNewPathTile(tester, cellX: 1, cellY: 1, tileX: 1, tileY: 1);
+
+      expect(find.text('Tuile 0,0'), findsWidgets);
+      expect(find.text('Tuile 1,0'), findsWidgets);
+      expect(find.text('Tuile 0,1'), findsWidgets);
+      expect(find.text('Tuile 1,1'), findsWidgets);
+      expect(find.text('Cellules à configurer'), findsNothing);
+    });
+
+    testWidgets('replaces and clears the active cell tile', (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          tilesets: [_tileset(id: 'tileset-main', name: 'Chemins principaux')],
+        ),
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await tester.pumpAndSettle();
+      tester
+          .widget<MacosPopupButton<String>>(
+            find.byKey(const Key('path-studio-new-path-tileset-popup')),
+          )
+          .onChanged
+          ?.call('tileset-main');
+      await tester.pumpAndSettle();
+
+      await _tapNewPathTile(tester, tileX: 0, tileY: 0);
+      await _tapNewPathTile(tester, tileX: 1, tileY: 0);
+
+      expect(find.text('Tuile 1,0'), findsWidgets);
+      expect(find.text('Tuile 0,0'), findsNothing);
+
+      final clearButton =
+          find.byKey(const Key('path-studio-new-path-clear-selected-cell'));
+      await tester.ensureVisible(clearButton);
+      await tester.pumpAndSettle();
+      await tester.tap(clearButton);
+      await tester.pumpAndSettle();
+
+      expect(find.text('Tuile 1,0'), findsNothing);
+      expect(find.text('Aucune tuile configurée pour cette cellule.'),
+          findsWidgets);
+      expect(find.text('Cellules à configurer'), findsWidgets);
+    });
+
+    testWidgets('changing tileset clears configured center cells',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          tilesets: [
+            _tileset(id: 'tileset-main', name: 'Chemins principaux'),
+            _tileset(id: 'tileset-extra', name: 'Décor extra'),
+          ],
+        ),
+      );
+
+      await tester.tap(find.widgetWithText(CupertinoButton, 'Nouveau chemin'));
+      await tester.pumpAndSettle();
+      final popupFinder =
+          find.byKey(const Key('path-studio-new-path-tileset-popup'));
+      tester.widget<MacosPopupButton<String>>(popupFinder).onChanged?.call(
+            'tileset-main',
+          );
+      await tester.pumpAndSettle();
+      await _tapNewPathTile(tester, tileX: 2, tileY: 1);
+
+      expect(find.text('Tuile 2,1'), findsWidgets);
+      expect(find.text('Cellules à configurer'), findsNothing);
+
+      tester.widget<MacosPopupButton<String>>(popupFinder).onChanged?.call(
+            'tileset-extra',
+          );
+      await tester.pumpAndSettle();
+
+      expect(find.text('Décor extra (tileset-extra)'), findsWidgets);
+      expect(find.text('Tuile 2,1'), findsNothing);
+      expect(find.text('Cellules à configurer'), findsWidgets);
+    });
+
     testWidgets('resizes the new path draft to 2x2 and selects a cell',
         (tester) async {
       await _pumpPathStudio(
@@ -397,6 +541,33 @@ Future<void> _pumpPathStudio(
   await tester.pumpAndSettle();
 }
 
+Future<void> _assignNewPathTile(
+  WidgetTester tester, {
+  required int cellX,
+  required int cellY,
+  required int tileX,
+  required int tileY,
+}) async {
+  final cell = find.byKey(Key('path-studio-new-path-cell-$cellX-$cellY'));
+  await tester.ensureVisible(cell);
+  await tester.pumpAndSettle();
+  await tester.tap(cell);
+  await tester.pumpAndSettle();
+  await _tapNewPathTile(tester, tileX: tileX, tileY: tileY);
+}
+
+Future<void> _tapNewPathTile(
+  WidgetTester tester, {
+  required int tileX,
+  required int tileY,
+}) async {
+  final tile = find.byKey(Key('path-studio-new-path-tile-$tileX-$tileY'));
+  await tester.ensureVisible(tile);
+  await tester.pumpAndSettle();
+  await tester.tap(tile);
+  await tester.pumpAndSettle();
+}
+
 ProjectManifest _manifest({
   List<ProjectPathPreset> pathPresets = const [],
   List<ProjectPathPatternPreset> pathPatternPresets = const [],
```

### Contenu complet des fichiers modifiés

#### `packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart`

```dart
import 'package:map_core/map_core.dart';

enum PathStudioNewPathDraftIssueCode {
  nameRequired,
  tilesetNotConfigured,
  cellsNotConfigured,
}

/// Tuile V0 assignée à une cellule du centre.
///
/// Le Path Studio ne gère pas encore les animations ni les frames multiples.
/// Cette valeur locale représente donc exactement une frame statique : un
/// tileset projet et une coordonnée de tuile dans cet atlas.
final class PathStudioNewPathDraftTile {
  const PathStudioNewPathDraftTile({
    required this.tilesetId,
    required this.sourceX,
    required this.sourceY,
  })  : assert(sourceX >= 0),
        assert(sourceY >= 0);

  final String tilesetId;
  final int sourceX;
  final int sourceY;

  String get coordinateLabel => '$sourceX,$sourceY';

  TilesetVisualFrame toFrame() {
    return TilesetVisualFrame(
      tilesetId: tilesetId,
      source: TilesetSourceRect(x: sourceX, y: sourceY),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathStudioNewPathDraftTile &&
            tilesetId == other.tilesetId &&
            sourceX == other.sourceX &&
            sourceY == other.sourceY;
  }

  @override
  int get hashCode => Object.hash(tilesetId, sourceX, sourceY);
}

final class PathStudioNewPathDraftCell {
  const PathStudioNewPathDraftCell({
    required this.localX,
    required this.localY,
    required this.label,
    this.tile,
  });

  final int localX;
  final int localY;
  final String label;
  final PathStudioNewPathDraftTile? tile;

  bool get isConfigured => tile != null;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathStudioNewPathDraftCell &&
            localX == other.localX &&
            localY == other.localY &&
            label == other.label &&
            tile == other.tile;
  }

  @override
  int get hashCode => Object.hash(localX, localY, label, tile);
}

final class PathStudioNewPathDraft {
  PathStudioNewPathDraft({
    required this.id,
    required this.name,
    this.tilesetId,
    required this.centerWidth,
    required this.centerHeight,
    required this.selectedCellX,
    required this.selectedCellY,
    required this.isDirty,
    Map<String, PathStudioNewPathDraftTile> assignedTiles = const {},
  })  : assert(centerWidth > 0),
        assert(centerHeight > 0),
        assert(selectedCellX >= 0 && selectedCellX < centerWidth),
        assert(selectedCellY >= 0 && selectedCellY < centerHeight),
        assignedTiles = Map<String, PathStudioNewPathDraftTile>.unmodifiable(
          assignedTiles,
        );

  final String id;
  final String name;
  final String? tilesetId;
  final int centerWidth;
  final int centerHeight;
  final int selectedCellX;
  final int selectedCellY;
  final bool isDirty;

  /// Assignations locales des cellules du centre, indexées par `x,y`.
  ///
  /// Le map est immuable pour éviter qu'un widget ou test modifie le brouillon
  /// en place. Les helpers de ce fichier retournent toujours une nouvelle
  /// instance de [PathStudioNewPathDraft].
  final Map<String, PathStudioNewPathDraftTile> assignedTiles;

  String get centerPatternLabel => '$centerWidth×$centerHeight';

  int get centerCellCount => centerWidth * centerHeight;

  int get configuredCellCount =>
      cells.where((cell) => cell.isConfigured).length;

  bool get allCenterCellsConfigured => configuredCellCount == centerCellCount;

  List<PathStudioNewPathDraftCell> get cells {
    final result = <PathStudioNewPathDraftCell>[];
    var labelCode = 'A'.codeUnitAt(0);
    for (var y = 0; y < centerHeight; y += 1) {
      for (var x = 0; x < centerWidth; x += 1) {
        result.add(
          PathStudioNewPathDraftCell(
            localX: x,
            localY: y,
            label: String.fromCharCode(labelCode),
            tile: assignedTiles[_cellKey(x, y)],
          ),
        );
        labelCode += 1;
      }
    }
    return List<PathStudioNewPathDraftCell>.unmodifiable(result);
  }

  PathStudioNewPathDraftCell get selectedCell {
    return cells.firstWhere(
      (cell) => cell.localX == selectedCellX && cell.localY == selectedCellY,
    );
  }

  List<PathStudioNewPathDraftIssueCode> get issues {
    final result = <PathStudioNewPathDraftIssueCode>[];
    if (name.trim().isEmpty) {
      result.add(PathStudioNewPathDraftIssueCode.nameRequired);
    }
    if (tilesetId == null || tilesetId!.isEmpty) {
      result.add(PathStudioNewPathDraftIssueCode.tilesetNotConfigured);
    }
    if (!allCenterCellsConfigured) {
      result.add(PathStudioNewPathDraftIssueCode.cellsNotConfigured);
    }
    return List<PathStudioNewPathDraftIssueCode>.unmodifiable(result);
  }

  PathStudioNewPathDraft copyWith({
    String? id,
    String? name,
    Object? tilesetId = _sentinel,
    int? centerWidth,
    int? centerHeight,
    int? selectedCellX,
    int? selectedCellY,
    bool? isDirty,
    Map<String, PathStudioNewPathDraftTile>? assignedTiles,
  }) {
    return PathStudioNewPathDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      tilesetId: identical(tilesetId, _sentinel)
          ? this.tilesetId
          : tilesetId as String?,
      centerWidth: centerWidth ?? this.centerWidth,
      centerHeight: centerHeight ?? this.centerHeight,
      selectedCellX: selectedCellX ?? this.selectedCellX,
      selectedCellY: selectedCellY ?? this.selectedCellY,
      isDirty: isDirty ?? this.isDirty,
      assignedTiles: assignedTiles ?? this.assignedTiles,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PathStudioNewPathDraft &&
            id == other.id &&
            name == other.name &&
            tilesetId == other.tilesetId &&
            centerWidth == other.centerWidth &&
            centerHeight == other.centerHeight &&
            selectedCellX == other.selectedCellX &&
            selectedCellY == other.selectedCellY &&
            isDirty == other.isDirty &&
            _assignedTileMapsEqual(assignedTiles, other.assignedTiles);
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        tilesetId,
        centerWidth,
        centerHeight,
        selectedCellX,
        selectedCellY,
        isDirty,
        _assignedTileMapHash(assignedTiles),
      );
}

const _sentinel = Object();

PathStudioNewPathDraft createInitialPathStudioNewPathDraft() {
  return PathStudioNewPathDraft(
    id: 'draft-new-path',
    name: 'Nouveau chemin',
    centerWidth: 1,
    centerHeight: 1,
    selectedCellX: 0,
    selectedCellY: 0,
    isDirty: true,
  );
}

PathStudioNewPathDraft resizePathStudioNewPathDraftCenter({
  required PathStudioNewPathDraft draft,
  required int width,
  required int height,
}) {
  if (width <= 0 || height <= 0) {
    throw ArgumentError.value('$width×$height', 'size', 'must be positive');
  }
  return draft.copyWith(
    centerWidth: width,
    centerHeight: height,
    selectedCellX: draft.selectedCellX.clamp(0, width - 1).toInt(),
    selectedCellY: draft.selectedCellY.clamp(0, height - 1).toInt(),
    isDirty: true,
    assignedTiles: _trimAssignedTilesForSize(
      draft.assignedTiles,
      width: width,
      height: height,
    ),
  );
}

PathStudioNewPathDraft renamePathStudioNewPathDraft(
  PathStudioNewPathDraft draft,
  String name,
) {
  return draft.copyWith(name: name, isDirty: true);
}

PathStudioNewPathDraft selectPathStudioNewPathDraftTileset(
  PathStudioNewPathDraft draft,
  String tilesetId,
) {
  // Une coordonnée `2,3` n'a de sens que dans l'atlas courant. Changer de
  // tileset vide donc les cellules plutôt que de garder une assignation qui
  // aurait l'air valide tout en pointant vers une autre image.
  return draft.copyWith(
    tilesetId: tilesetId.isEmpty ? null : tilesetId,
    assignedTiles: const {},
    isDirty: true,
  );
}

PathStudioNewPathDraft assignPathStudioNewPathDraftCellTile({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
  required int sourceX,
  required int sourceY,
}) {
  final tilesetId = draft.tilesetId;
  if (tilesetId == null || tilesetId.isEmpty) {
    throw StateError('A tileset must be selected before assigning a tile.');
  }
  if (sourceX < 0) {
    throw ArgumentError.value(sourceX, 'sourceX', 'must be non-negative');
  }
  if (sourceY < 0) {
    throw ArgumentError.value(sourceY, 'sourceY', 'must be non-negative');
  }
  _validateCellCoordinates(draft: draft, localX: localX, localY: localY);

  final nextTiles = Map<String, PathStudioNewPathDraftTile>.from(
    draft.assignedTiles,
  );
  nextTiles[_cellKey(localX, localY)] = PathStudioNewPathDraftTile(
    tilesetId: tilesetId,
    sourceX: sourceX,
    sourceY: sourceY,
  );
  return draft.copyWith(assignedTiles: nextTiles, isDirty: true);
}

PathStudioNewPathDraft clearPathStudioNewPathDraftCell({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
}) {
  _validateCellCoordinates(draft: draft, localX: localX, localY: localY);

  final nextTiles = Map<String, PathStudioNewPathDraftTile>.from(
    draft.assignedTiles,
  )..remove(_cellKey(localX, localY));
  return draft.copyWith(assignedTiles: nextTiles, isDirty: true);
}

PathStudioNewPathDraft selectPathStudioNewPathDraftCell({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
}) {
  _validateCellCoordinates(draft: draft, localX: localX, localY: localY);
  return draft.copyWith(
    selectedCellX: localX,
    selectedCellY: localY,
  );
}

String _cellKey(int localX, int localY) => '$localX,$localY';

void _validateCellCoordinates({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
}) {
  if (localX < 0 || localX >= draft.centerWidth) {
    throw RangeError.range(localX, 0, draft.centerWidth - 1, 'localX');
  }
  if (localY < 0 || localY >= draft.centerHeight) {
    throw RangeError.range(localY, 0, draft.centerHeight - 1, 'localY');
  }
}

Map<String, PathStudioNewPathDraftTile> _trimAssignedTilesForSize(
  Map<String, PathStudioNewPathDraftTile> assignedTiles, {
  required int width,
  required int height,
}) {
  final kept = <String, PathStudioNewPathDraftTile>{};
  for (final entry in assignedTiles.entries) {
    final parts = entry.key.split(',');
    if (parts.length != 2) {
      continue;
    }
    final localX = int.tryParse(parts[0]);
    final localY = int.tryParse(parts[1]);
    if (localX == null || localY == null) {
      continue;
    }
    if (localX >= 0 && localX < width && localY >= 0 && localY < height) {
      kept[entry.key] = entry.value;
    }
  }
  return kept;
}

bool _assignedTileMapsEqual(
  Map<String, PathStudioNewPathDraftTile> left,
  Map<String, PathStudioNewPathDraftTile> right,
) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _assignedTileMapHash(Map<String, PathStudioNewPathDraftTile> tiles) {
  final entries = tiles.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return Object.hashAll(
    entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}
```

#### `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`

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
    if (manifest == null) {
      return const _PathStudioProjectMissingState();
    }
    return PathStudioPanel(manifest: manifest);
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
  });

  final ProjectManifest manifest;

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
    required this.draft,
    required this.onSizeChanged,
    required this.onCellSelected,
    required this.onTileSelected,
    required this.onCellCleared,
  });

  final List<ProjectTilesetEntry> tilesets;
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
    required this.draft,
    required this.onSizeChanged,
    required this.onCellSelected,
    required this.onTileSelected,
    required this.onCellCleared,
  });

  final List<ProjectTilesetEntry> tilesets;
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
    required this.draft,
    required this.onCellSelected,
  });

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
    required this.cell,
    required this.selected,
    required this.onTap,
  });

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
              _TilePreviewBadge(tile: tile)
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
  const _TilePreviewBadge({required this.tile});

  final PathStudioNewPathDraftTile tile;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    required this.draft,
    required this.onTileSelected,
  });

  final List<ProjectTilesetEntry> tilesets;
  final PathStudioNewPathDraft draft;
  final void Function(int sourceX, int sourceY) onTileSelected;

  @override
  Widget build(BuildContext context) {
    final tilesetLabel =
        _selectedTilesetLabel(tilesets: tilesets, tilesetId: draft.tilesetId);
    if (tilesetLabel == null) {
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
            'Grille logique V0 : les coordonnées sont enregistrées dans le brouillon, sans lecture de l’image tileset ni preview PNG.',
            style: TextStyle(
              color: PathStudioTheme.textMuted,
              fontSize: 10.5,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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

#### `packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_studio_new_path_draft.dart';

void main() {
  group('PathStudioNewPathDraft', () {
    test('creates an initial draft without a legacy ProjectPathPreset', () {
      final draft = createInitialPathStudioNewPathDraft();

      expect(draft.id, 'draft-new-path');
      expect(draft.name, 'Nouveau chemin');
      expect(draft.centerWidth, 1);
      expect(draft.centerHeight, 1);
      expect(draft.centerPatternLabel, '1×1');
      expect(draft.centerCellCount, 1);
      expect(draft.tilesetId, isNull);
      expect(draft.selectedCellX, 0);
      expect(draft.selectedCellY, 0);
      expect(draft.isDirty, isTrue);
      expect(draft.cells.map((cell) => cell.label), ['A']);
      expect(draft.issues, [
        PathStudioNewPathDraftIssueCode.tilesetNotConfigured,
        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
      ]);
    });

    test('selects a tileset while preserving center size and selection', () {
      final draft = createInitialPathStudioNewPathDraft();

      final selected = selectPathStudioNewPathDraftTileset(
        draft,
        'tileset-main',
      );

      expect(selected.tilesetId, 'tileset-main');
      expect(selected.issues, [
        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
      ]);
      expect(selected.centerPatternLabel, '1×1');
      expect(selected.selectedCellX, 0);
      expect(selected.selectedCellY, 0);
      expect(selected.isDirty, isTrue);
    });

    test('assigns one V0 tile to the 1x1 cell and clears cell issue', () {
      final draft = selectPathStudioNewPathDraftTileset(
        createInitialPathStudioNewPathDraft(),
        'tileset-main',
      );

      final assigned = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 0,
        localY: 0,
        sourceX: 2,
        sourceY: 3,
      );

      expect(assigned.configuredCellCount, 1);
      expect(assigned.issues, isEmpty);
      expect(
        assigned.selectedCell.tile,
        const PathStudioNewPathDraftTile(
          tilesetId: 'tileset-main',
          sourceX: 2,
          sourceY: 3,
        ),
      );
      expect(
        assigned.selectedCell.tile!.toFrame(),
        const TilesetVisualFrame(
          tilesetId: 'tileset-main',
          source: TilesetSourceRect(x: 2, y: 3),
        ),
      );
    });

    test('keeps cells issue until every 2x2 cell has one tile', () {
      var draft = resizePathStudioNewPathDraftCenter(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        width: 2,
        height: 2,
      );

      draft = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 0,
        localY: 0,
        sourceX: 0,
        sourceY: 0,
      );
      expect(draft.configuredCellCount, 1);
      expect(
        draft.issues,
        contains(PathStudioNewPathDraftIssueCode.cellsNotConfigured),
      );

      draft = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 1,
        localY: 0,
        sourceX: 1,
        sourceY: 0,
      );
      draft = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 0,
        localY: 1,
        sourceX: 0,
        sourceY: 1,
      );
      draft = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 1,
        localY: 1,
        sourceX: 1,
        sourceY: 1,
      );

      expect(draft.configuredCellCount, 4);
      expect(
        draft.issues,
        isNot(contains(PathStudioNewPathDraftIssueCode.cellsNotConfigured)),
      );
    });

    test('replaces a configured cell instead of adding a second frame', () {
      final draft = selectPathStudioNewPathDraftTileset(
        createInitialPathStudioNewPathDraft(),
        'tileset-main',
      );
      final first = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 0,
        localY: 0,
        sourceX: 0,
        sourceY: 0,
      );

      final replaced = assignPathStudioNewPathDraftCellTile(
        draft: first,
        localX: 0,
        localY: 0,
        sourceX: 4,
        sourceY: 2,
      );

      expect(replaced.configuredCellCount, 1);
      expect(
        replaced.selectedCell.tile,
        const PathStudioNewPathDraftTile(
          tilesetId: 'tileset-main',
          sourceX: 4,
          sourceY: 2,
        ),
      );
    });

    test('clears a configured required cell and restores cell issue', () {
      final assigned = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 2,
        sourceY: 3,
      );

      final cleared = clearPathStudioNewPathDraftCell(
        draft: assigned,
        localX: 0,
        localY: 0,
      );

      expect(cleared.configuredCellCount, 0);
      expect(cleared.selectedCell.tile, isNull);
      expect(
        cleared.issues,
        contains(PathStudioNewPathDraftIssueCode.cellsNotConfigured),
      );
    });

    test('resizes a 1x1 draft to 2x2 while preserving cell A only', () {
      final draft = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 2,
        sourceY: 3,
      );

      final resized = resizePathStudioNewPathDraftCenter(
        draft: draft,
        width: 2,
        height: 2,
      );

      expect(resized.tilesetId, 'tileset-main');
      expect(resized.centerPatternLabel, '2×2');
      expect(resized.centerCellCount, 4);
      expect(
        resized.cells.map((cell) => (cell.localX, cell.localY, cell.label)),
        [
          (0, 0, 'A'),
          (1, 0, 'B'),
          (0, 1, 'C'),
          (1, 1, 'D'),
        ],
      );
      expect(
        resized.cells.first.tile,
        const PathStudioNewPathDraftTile(
          tilesetId: 'tileset-main',
          sourceX: 2,
          sourceY: 3,
        ),
      );
      expect(resized.cells.skip(1).every((cell) => cell.tile == null), isTrue);
      expect(resized.selectedCellX, 0);
      expect(resized.selectedCellY, 0);
    });

    test('resizes a 2x2 draft back to 1x1 and keeps only cell A', () {
      var twoByTwo = resizePathStudioNewPathDraftCenter(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        width: 2,
        height: 2,
      );
      twoByTwo = assignPathStudioNewPathDraftCellTile(
        draft: twoByTwo,
        localX: 0,
        localY: 0,
        sourceX: 0,
        sourceY: 0,
      );
      twoByTwo = assignPathStudioNewPathDraftCellTile(
        draft: twoByTwo,
        localX: 1,
        localY: 1,
        sourceX: 4,
        sourceY: 4,
      );
      final selected = selectPathStudioNewPathDraftCell(
        draft: twoByTwo,
        localX: 1,
        localY: 1,
      );

      final resized = resizePathStudioNewPathDraftCenter(
        draft: selected,
        width: 1,
        height: 1,
      );

      expect(resized.centerWidth, 1);
      expect(resized.centerHeight, 1);
      expect(resized.centerCellCount, 1);
      expect(resized.selectedCellX, 0);
      expect(resized.selectedCellY, 0);
      expect(
        resized.selectedCell.tile,
        const PathStudioNewPathDraftTile(
          tilesetId: 'tileset-main',
          sourceX: 0,
          sourceY: 0,
        ),
      );
      expect(resized.configuredCellCount, 1);
    });

    test('selecting another tileset clears cell assignments deterministically',
        () {
      final assigned = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 2,
        sourceY: 3,
      );

      final changed = selectPathStudioNewPathDraftTileset(
        assigned,
        'tileset-extra',
      );

      expect(changed.tilesetId, 'tileset-extra');
      expect(changed.configuredCellCount, 0);
      expect(changed.selectedCell.tile, isNull);
      expect(changed.issues, [
        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
      ]);
    });

    test('renames the draft locally', () {
      final draft = renamePathStudioNewPathDraft(
        selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        'Route claire',
      );

      expect(draft.name, 'Route claire');
      expect(draft.tilesetId, 'tileset-main');
      expect(draft.isDirty, isTrue);
    });

    test('empty name after tileset selection exposes only remaining issues',
        () {
      final draft = renamePathStudioNewPathDraft(
        selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        '   ',
      );

      expect(draft.issues, [
        PathStudioNewPathDraftIssueCode.nameRequired,
        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
      ]);
    });

    test('selects a placeholder cell by exact local coordinates', () {
      final draft = resizePathStudioNewPathDraftCenter(
        draft: createInitialPathStudioNewPathDraft(),
        width: 2,
        height: 2,
      );

      final selected = selectPathStudioNewPathDraftCell(
        draft: draft,
        localX: 1,
        localY: 0,
      );

      expect(selected.selectedCellX, 1);
      expect(selected.selectedCellY, 0);
      expect(selected.selectedCell.label, 'B');
    });
  });
}
```

#### `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_studio_panel.dart';

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();
      tester
          .widget<MacosPopupButton<String>>(
            find.byKey(const Key('path-studio-new-path-tileset-popup')),
          )
          .onChanged
          ?.call('tileset-main');
      await tester.pumpAndSettle();

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
              return PathStudioPanel(manifest: manifest);
            },
          ),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
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
  await tester.pumpAndSettle();
  await tester.tap(cell);
  await tester.pumpAndSettle();
  await _tapNewPathTile(tester, tileX: tileX, tileY: tileY);
}

Future<void> _tapNewPathTile(
  WidgetTester tester, {
  required int tileX,
  required int tileY,
}) async {
  final tile = find.byKey(Key('path-studio-new-path-tile-$tileX-$tileY'));
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

ProjectManifest _manifest({
  List<ProjectPathPreset> pathPresets = const [],
  List<ProjectPathPatternPreset> pathPatternPresets = const [],
  List<ProjectTilesetEntry> tilesets = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: tilesets,
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
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

### Fichier créé

- `reports/pathPattern/lot_16_center_cell_tile_picker_v0.md` : présent rapport. Son contenu complet n’est pas recopié dans lui-même pour éviter une récursion infinie.

## 16. Statut final Git

Sorties finales capturées après écriture du présent rapport.

### git status --short --untracked-files=all final

```text
 M packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
 M packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
 M packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
 M packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? reports/pathPattern/lot_16_center_cell_tile_picker_v0.md
```

### git diff --stat final

```text
 .../path_studio/path_studio_new_path_draft.dart    | 210 +++++++++-
 .../features/path_studio/path_studio_panel.dart    | 427 +++++++++++++++++++--
 .../path_studio_new_path_draft_test.dart           | 219 ++++++++++-
 .../test/path_pattern/path_studio_panel_test.dart  | 171 +++++++++
 4 files changed, 982 insertions(+), 45 deletions(-)
```

### git diff --name-status final

```text
M	packages/map_editor/lib/src/features/path_studio/path_studio_new_path_draft.dart
M	packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
M	packages/map_editor/test/path_pattern/path_studio_new_path_draft_test.dart
M	packages/map_editor/test/path_pattern/path_studio_panel_test.dart
```

## 17. Conclusion

Lot 16 fermable : oui.
