# Lot PathPattern-13 — Path Studio Shell V0

Date: 2026-04-30

Verdict: implémenté et vérifié. Le lot ajoute une première UI visible Path Studio en dark mode, branchée à la navigation éditeur et alimentée par le read model PathPattern du Lot 12. Aucun `map_core`, `ProjectManifest`, codec, runtime, painter, canvas ou save flow PathPattern n’a été modifié.

## 1. Audit initial

Context Mode: disponible et utilisé via `ctx_batch_execute` pendant l’audit initial pour limiter le bruit des sorties de recherche. Les commandes principales et constats sont reproduits ici.

Etat initial exact:

```text
$ pwd
/Users/karim/Project/pokemonProject
$ git status --short
 M packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/editor_selectors_test.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
 M packages/map_editor/test/top_toolbar_test.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_theme.dart
?? packages/map_editor/test/path_pattern/path_studio_panel_test.dart
$ git diff --stat
 .../application/editor_workspace_controller.dart   |  4 ++
 .../src/features/editor/state/editor_notifier.dart |  8 +++
 .../features/editor/state/editor_selectors.dart    | 18 +++++--
 .../editor/state/models/editor_workspace_mode.dart |  7 +++
 .../lib/src/ui/canvas/editor_canvas_host.dart      |  2 +
 .../map_editor/lib/src/ui/editor_shell_page.dart   |  9 ++++
 .../lib/src/ui/panels/project_explorer_panel.dart  | 39 ++++++++++++--
 .../map_editor/lib/src/ui/shared/top_toolbar.dart  | 13 +++--
 .../map_editor/test/editor_selectors_test.dart     | 28 ++++++++++
 .../test/editor_shell_page_smoke_test.dart         | 62 ++++++++++++++++++++++
 .../map_editor/test/shell_chrome_test_harness.dart |  5 ++
 packages/map_editor/test/top_toolbar_test.dart     | 30 +++++++++++
 12 files changed, 214 insertions(+), 11 deletions(-)
$ git diff --name-status
M	packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
M	packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
M	packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
M	packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
M	packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
M	packages/map_editor/lib/src/ui/editor_shell_page.dart
M	packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
M	packages/map_editor/lib/src/ui/shared/top_toolbar.dart
M	packages/map_editor/test/editor_selectors_test.dart
M	packages/map_editor/test/editor_shell_page_smoke_test.dart
M	packages/map_editor/test/shell_chrome_test_harness.dart
M	packages/map_editor/test/top_toolbar_test.dart
```

Fichiers et patterns inspectés:

- `packages/map_editor/lib/src/features/path_studio/path_pattern_editor_read_model.dart`: read model Lot 12 existant, API `createPathPatternEditorReadModel` disponible.

- `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart`: enum workspace central existant.

- `packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart`: transitions workspace existantes.

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`: façade Riverpod existante pour sélectionner les workspaces.

- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`: snapshots shell / toolbar / explorer.

- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`: switch central des workspaces.

- `packages/map_editor/lib/src/ui/editor_shell_page.dart`: shell global et colonne inspecteur.

- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`: entrée visible côté Project Explorer.

- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`: accès workspace par toolbar.

- `packages/map_editor/test/shell_chrome_test_harness.dart`: harness de tests shell.

## 2. Stratégie retenue

J’ai retenu une intégration minimale et locale: `EditorWorkspaceMode.pathStudio` comme workspace central, une entrée Project Explorer, un bouton toolbar, et une surface `PathStudioWorkspace` qui lit le `ProjectManifest` depuis les selectors existants. Le panneau ne duplique pas les diagnostics: il consomme `createPathPatternEditorReadModel(manifest: ...)`.

Le dark mode est local au feature folder via `path_studio_theme.dart`; il ne refond pas le thème global `map_editor`. La sélection et la recherche restent en état local du widget: un `String` pour la recherche et un index source pour la sélection. L’index source est volontaire, car les ids dupliqués sont un état diagnostiqué et sélectionner par id serait ambigu.

Après revue séparée, les actions globales map Save/Undo/Redo sont explicitement masquées/désactivées hors workspace map, y compris en Path Studio quand une map active existe.

## 3. Fichiers créés / modifiés / supprimés

Fichiers créés:

- `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`

- `packages/map_editor/lib/src/features/path_studio/path_studio_theme.dart`

- `packages/map_editor/test/path_pattern/path_studio_panel_test.dart`

Fichiers modifiés:

- `packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart`

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`

- `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart`

- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`

- `packages/map_editor/lib/src/ui/editor_shell_page.dart`

- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`

- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`

- `packages/map_editor/test/editor_selectors_test.dart`

- `packages/map_editor/test/editor_shell_page_smoke_test.dart`

- `packages/map_editor/test/shell_chrome_test_harness.dart`

- `packages/map_editor/test/top_toolbar_test.dart`

Fichiers supprimés: aucun.

Fichiers volontairement non modifiés: `packages/map_core/**`, `ProjectManifest`, codecs PathPattern, generated files, runtime/gameplay/battle, painter/canvas.

## 4. Changements fichier par fichier

- `path_studio_theme.dart`: tokens dark mode locaux Path Studio, couleurs, décorations de panneaux, cards et champs.

- `path_studio_panel.dart`: UI shell complète read-only: header, boutons placeholder désactivés, sidebar presets, recherche, sélection, centre workflow/résumé/placeholder/diagnostics, inspector droit.

- `editor_workspace_mode.dart`: ajout du mode `pathStudio`.

- `editor_workspace_controller.dart`: transition `selectPathStudioWorkspace`.

- `editor_notifier.dart`: méthode publique `selectPathStudioWorkspace`, navigation uniquement.

- `editor_selectors.dart`: titres/sous-titres Path Studio, gating des actions map hors workspace map, champ `canSaveMap` dans le snapshot toolbar.

- `editor_canvas_host.dart`: routage du workspace vers `PathStudioWorkspace`.

- `editor_shell_page.dart`: Path Studio a son inspector interne; ajout icône/label/chip/tint workspace.

- `project_explorer_panel.dart`: carte Path Studio dans la section Path Library, visible et ouvrable.

- `top_toolbar.dart`: bouton workspace Path Studio; save utilise désormais `toolbar.canSaveMap`.

- Tests: widget tests Path Studio, smoke test explorer, tests selectors et toolbar pour verrouiller le périmètre read-only.

## 5. API/UI livrée

- `PathStudioWorkspace`: widget branché au manifest éditeur via selector existant.

- `PathStudioPanel`: widget testable qui accepte un `ProjectManifest`.

- Entrée visible Project Explorer: key `project-explorer-path-studio-entry`.

- Recherche locale: key `path-studio-search-field`.

- Boutons shell: `Nouveau preset`, `Dupliquer`, `Enregistrer`, désactivés et annotés `lot futur`.

- Diagnostics: `Prêt`, `À vérifier`, `Bloqué`, plus labels lisibles des issue codes V0.

## 6. UX dark mode

Le shell utilise un fond indigo très sombre, surfaces `#211F31` / `#26233A`, bordures `#3A3654`, texte clair, accents bleus/cyan et états vert/ambre/rouge. La disposition est stable: sidebar 292 px, zone centrale flexible, inspector 300 px. Les placeholders sont honnêtes: ils annoncent les lots futurs sans simuler l’édition réelle.

## 7. Validation

Commandes exécutées et résultats exacts:

### 7.1 Test ciblé Lot 13

Commande:

```text
cd packages/map_editor && flutter test test/path_pattern/path_studio_panel_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:02 +0: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:02 +1: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:02 +1: PathStudioPanel lists presets and updates summary and inspector selection
00:02 +2: PathStudioPanel lists presets and updates summary and inspector selection
00:02 +2: PathStudioPanel filters presets locally and clears selection on no result
00:03 +2: PathStudioPanel filters presets locally and clears selection on no result
00:03 +3: PathStudioPanel filters presets locally and clears selection on no result
00:03 +3: PathStudioPanel shows shell actions as visibly disabled placeholders
00:03 +4: PathStudioPanel shows shell actions as visibly disabled placeholders
00:03 +4: All tests passed!
```

### 7.2 Smoke / selectors / toolbar

Commande:

```text
cd packages/map_editor && flutter test test/path_pattern/path_studio_panel_test.dart test/editor_shell_page_smoke_test.dart test/editor_selectors_test.dart test/top_toolbar_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:02 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:02 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:02 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:02 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:02 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:02 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:02 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:02 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:02 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:02 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:02 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:02 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke renders map workspace chrome and toggles the right panel
00:03 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke renders map workspace chrome and toggles the right panel
00:03 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke renders map workspace chrome and toggles the right panel
00:03 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke renders map workspace chrome and toggles the right panel
00:03 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the app brand and project workspace label
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:03 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke renders map workspace chrome and toggles the right panel
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:03 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke renders map workspace chrome and toggles the right panel
00:03 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke renders map workspace chrome and toggles the right panel
00:03 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke renders map workspace chrome and toggles the right panel
00:03 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/top_toolbar_test.dart: TopToolbar shows the trainer studio label for the trainer workspace
00:03 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke updates the workspace header for tileset mode
00:03 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke updates the workspace header for tileset mode
00:03 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke updates the workspace header for tileset mode
00:03 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke renders the trainer studio workspace chrome
00:03 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke renders the trainer studio workspace chrome
FileProjectRepository: Loading project from /tmp/editor_shell_trainer/project.json
00:04 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke renders the trainer studio workspace chrome
00:04 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke renders the Pokémon catalogs workspace shell
00:04 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke renders the Pokémon catalogs workspace shell
00:04 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke renders the Items catalogs workspace shell
00:04 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke renders the Items catalogs workspace shell
00:04 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke opens Path Studio from the project explorer
00:04 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke opens Path Studio from the project explorer
00:04 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke renders shell chrome with an error state already present
00:04 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart: EditorShellPage smoke renders shell chrome with an error state already present
00:04 +24: All tests passed!
```

### 7.3 Régressions PathPattern editor

Commande:

```text
cd packages/map_editor && flutter test test/path_pattern/
```

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart
00:02 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... empty manifest exposes an empty summary and no cards
00:02 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... empty manifest exposes an empty summary and no cards
00:02 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... ready 1x1 preset exposes list card details
00:02 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... ready 1x1 preset exposes list card details
00:02 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... ready 2x2 transparent animated preset exposes counts
00:02 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... ready 2x2 transparent animated preset exposes counts
00:02 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel missing basePathPresetId blocks the card
00:02 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: createPathPatternEditorReadModel missing basePathPresetId blocks the card
00:02 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... duplicate PathPattern ids block every affected card
00:02 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... duplicate PathPattern ids block every affected card
00:02 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... duplicate legacy base path preset ids block referencing cards
00:02 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... duplicate legacy base path preset ids block referencing cards
00:02 +6: ... createPathPatternEditorReadModel preserves manifest pathPatternPresets order
00:02 +7: ... createPathPatternEditorReadModel preserves manifest pathPatternPresets order
00:02 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... matches basePathPresetId exactly without trimming
00:02 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... matches basePathPresetId exactly without trimming
00:02 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... ids that differ only by spaces are distinct exact ids
00:02 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... ids that differ only by spaces are distinct exact ids
00:02 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... summary counts ready, blocked, duplicates, and multi-cell presets
00:02 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... summary counts ready, blocked, duplicates, and multi-cell presets
00:02 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... read model and card lists are immutable defensive copies
00:02 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... read model and card lists are immutable defensive copies
00:02 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... read model, summary, and card use value equality
00:02 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_pattern_editor_read_model_test.dart: ... read model, summary, and card use value equality
00:02 +12: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart
00:02 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: ... renders a 1x1 preview from the first frame source tile
00:02 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: ... renders a 1x1 preview from the first frame source tile
00:02 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: ... renders a 2x2 preview in local cell positions
00:02 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: ... renders a 2x2 preview in local cell positions
00:02 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: ... optional transparentColor before composing preview
00:02 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: ... optional transparentColor before composing preview
00:02 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: ... pixels opaque when color is null
00:02 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: ... pixels opaque when color is null
00:02 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: ... rejects source rects outside the tileset image
00:02 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: ... rejects source rects outside the tileset image
00:02 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: ... rejects non-1x1 source rects in V0
00:02 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_static_preview_renderer_test.dart: ... rejects non-1x1 source rects in V0
00:02 +18: ... renderPathCenterPatternStaticPreviewPng rejects invalid PNG bytes
00:02 +19: ... renderPathCenterPatternStaticPreviewPng rejects invalid PNG bytes
00:02 +19: ... renderPathCenterPatternStaticPreviewPng rejects non-positive tile dimensions
00:02 +20: ... renderPathCenterPatternStaticPreviewPng rejects non-positive tile dimensions
00:02 +20: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart
00:02 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel renders a dark empty state when no PathPattern preset exists
00:03 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:03 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel lists presets and updates summary and inspector selection
00:03 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:04 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:04 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel filters presets locally and clears selection on no result
00:04 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel shows shell actions as visibly disabled placeholders
00:04 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_studio_panel_test.dart: PathStudioPanel shows shell actions as visibly disabled placeholders
00:04 +41: All tests passed!
```

Commande complémentaire, lancée explicitement car le dossier contient aussi le test animé:

```text
cd packages/map_editor && ls test/path_pattern && flutter test test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart
```

```text
path_center_pattern_animated_preview_renderer_test.dart
path_center_pattern_static_preview_renderer_test.dart
path_pattern_editor_read_model_test.dart
path_studio_panel_test.dart
tileset_transparent_color_processor_test.dart
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/path_pattern/path_center_pattern_animated_preview_renderer_test.dart
00:01 +0: renderPathCenterPatternAnimatedPreviewPng keeps a single-frame 1x1 pattern stable across elapsed time
00:01 +1: renderPathCenterPatternAnimatedPreviewPng keeps a single-frame 1x1 pattern stable across elapsed time
00:01 +1: renderPathCenterPatternAnimatedPreviewPng loops two explicit-duration frames for a 1x1 pattern
00:01 +2: renderPathCenterPatternAnimatedPreviewPng loops two explicit-duration frames for a 1x1 pattern
00:01 +2: renderPathCenterPatternAnimatedPreviewPng resolves independent 2x2 cell timelines
00:01 +3: renderPathCenterPatternAnimatedPreviewPng resolves independent 2x2 cell timelines
00:01 +3: renderPathCenterPatternAnimatedPreviewPng uses map_core default duration for null frame durations
00:01 +4: renderPathCenterPatternAnimatedPreviewPng uses map_core default duration for null frame durations
00:01 +4: renderPathCenterPatternAnimatedPreviewPng rejects non-positive frame durations
00:01 +5: renderPathCenterPatternAnimatedPreviewPng rejects non-positive frame durations
00:01 +5: renderPathCenterPatternAnimatedPreviewPng applies optional transparentColor before composing preview
00:01 +6: renderPathCenterPatternAnimatedPreviewPng applies optional transparentColor before composing preview
00:01 +6: renderPathCenterPatternAnimatedPreviewPng keeps transparent-color-looking pixels opaque when color is null
00:01 +7: renderPathCenterPatternAnimatedPreviewPng keeps transparent-color-looking pixels opaque when color is null
00:01 +7: renderPathCenterPatternAnimatedPreviewPng rejects source rects outside the tileset image
00:01 +8: renderPathCenterPatternAnimatedPreviewPng rejects source rects outside the tileset image
00:01 +8: renderPathCenterPatternAnimatedPreviewPng rejects non-1x1 source rects in V0
00:01 +9: renderPathCenterPatternAnimatedPreviewPng rejects non-1x1 source rects in V0
00:01 +9: renderPathCenterPatternAnimatedPreviewPng rejects invalid PNG bytes
00:01 +10: renderPathCenterPatternAnimatedPreviewPng rejects invalid PNG bytes
00:01 +10: renderPathCenterPatternAnimatedPreviewPng rejects negative elapsedMs and non-positive tile dimensions
00:01 +11: renderPathCenterPatternAnimatedPreviewPng rejects negative elapsedMs and non-positive tile dimensions
00:01 +11: All tests passed!
```

### 7.4 Régressions PathPattern map_core

Commande:

```text
cd packages/map_core && dart test test/project_manifest_path_pattern_preset_operations_test.dart test/project_manifest_path_pattern_presets_test.dart test/project_path_pattern_preset_json_codec_test.dart test/project_path_pattern_preset_json_golden_test.dart test/project_path_pattern_preset_test.dart test/path_center_pattern_test.dart test/path_center_pattern_resolver_test.dart
```

```text
00:00 +0: loading test/project_manifest_path_pattern_preset_operations_test.dart
00:00 +0: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations read returns the manifest pathPatternPresets in order
00:00 +1: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations read returns the manifest pathPatternPresets in order
00:00 +1: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations replace swaps the list, preserves other fields, and keeps order
00:00 +2: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations replace swaps the list, preserves other fields, and keeps order
00:00 +2: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations replace accepts an empty list and rejects duplicate exact ids
00:00 +3: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets decodes old manifests without pathPatternPresets as empty
00:00 +4: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets decodes old manifests without pathPatternPresets as empty
00:00 +5: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets decodes old manifests without pathPatternPresets as empty
00:00 +6: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets decodes old manifests without pathPatternPresets as empty
00:00 +7: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets decodes old manifests without pathPatternPresets as empty
00:00 +8: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets decodes old manifests without pathPatternPresets as empty
00:00 +9: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets decodes old manifests without pathPatternPresets as empty
00:00 +10: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets decodes old manifests without pathPatternPresets as empty
00:00 +11: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets decodes old manifests without pathPatternPresets as empty
00:00 +12: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets decodes old manifests without pathPatternPresets as empty
00:00 +13: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets decodes old manifests without pathPatternPresets as empty
00:00 +14: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations operations keep pathPatternPresets JSON stable
00:00 +15: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations operations keep pathPatternPresets JSON stable
00:00 +16: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec encodes a minimal preset
00:00 +17: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec encodes a minimal preset
00:00 +18: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets decodes the Lot 9 minimal golden through ProjectManifest
00:00 +19: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets decodes the Lot 9 minimal golden through ProjectManifest
00:00 +20: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets decodes the Lot 9 minimal golden through ProjectManifest
00:00 +21: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets decodes the Lot 9 minimal golden through ProjectManifest
00:00 +22: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden decodes to the expected preset
00:00 +23: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden decodes to the expected preset
00:00 +24: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden decodes to the expected preset
00:00 +25: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden decodes to the expected preset
00:00 +26: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden decodes to the expected preset
00:00 +27: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden decodes to the expected preset
00:00 +28: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden decodes to the expected preset
00:00 +29: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden decodes to the expected preset
00:00 +30: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset creates a minimal preset with defaults
00:00 +31: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset creates a minimal preset with defaults
00:00 +32: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset creates a minimal preset with defaults
00:00 +33: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset creates a minimal preset with defaults
00:00 +34: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset creates a minimal preset with defaults
00:00 +35: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples complete 2x2 golden matches encode output
00:00 +36: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples complete 2x2 golden matches encode output
00:00 +36: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset creates a complete preset with a 2x2 center pattern
00:00 +37: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples goldens roundtrip through decode and encode
00:00 +38: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples goldens roundtrip through decode and encode
00:00 +38: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset rejects blank identity fields
00:00 +39: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples goldens use two-space canonical formatting with final newline
00:00 +40: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples goldens use two-space canonical formatting with final newline
00:00 +41: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset supports value equality and stable hashCode
00:00 +42: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset supports value equality and stable hashCode
00:00 +42: loading test/path_center_pattern_test.dart
00:00 +42: test/path_center_pattern_test.dart: PathCenterPatternSize accepts 1x1 and 2x2 sizes
00:00 +43: test/path_center_pattern_test.dart: PathCenterPatternSize accepts 1x1 and 2x2 sizes
00:00 +43: test/path_center_pattern_test.dart: PathCenterPatternSize rejects non-positive dimensions
00:00 +44: test/path_center_pattern_test.dart: PathCenterPatternSize rejects non-positive dimensions
00:00 +44: test/path_center_pattern_test.dart: PathCenterPatternSize reports tile count and coordinate containment
00:00 +45: test/path_center_pattern_test.dart: PathCenterPatternSize reports tile count and coordinate containment
00:00 +45: test/path_center_pattern_test.dart: PathCenterPatternSize uses value equality and stable hashCode
00:00 +46: test/path_center_pattern_test.dart: PathCenterPatternSize uses value equality and stable hashCode
00:00 +46: test/path_center_pattern_test.dart: PathCenterPatternCell accepts non-negative local coordinates and frames
00:00 +47: test/path_center_pattern_test.dart: PathCenterPatternCell accepts non-negative local coordinates and frames
00:00 +47: test/path_center_pattern_test.dart: PathCenterPatternCell rejects negative coordinates and empty frames
00:00 +48: test/path_center_pattern_test.dart: PathCenterPatternCell rejects negative coordinates and empty frames
00:00 +48: test/path_center_pattern_test.dart: PathCenterPatternCell defensively copies frames and exposes an immutable list
00:00 +49: test/path_center_pattern_test.dart: PathCenterPatternCell defensively copies frames and exposes an immutable list
00:00 +49: test/path_center_pattern_test.dart: PathCenterPatternCell uses value equality and stable hashCode
00:00 +50: test/path_center_pattern_test.dart: PathCenterPatternCell uses value equality and stable hashCode
00:00 +50: test/path_center_pattern_test.dart: PathCenterPattern 1x1 accepts a complete single-cell grid
00:00 +51: test/path_center_pattern_test.dart: PathCenterPattern 1x1 accepts a complete single-cell grid
00:00 +51: test/path_center_pattern_test.dart: PathCenterPattern 2x2 accepts a complete grid and exposes cells in row-major order
00:00 +52: test/path_center_pattern_test.dart: PathCenterPattern 2x2 accepts a complete grid and exposes cells in row-major order
00:00 +52: test/path_center_pattern_test.dart: PathCenterPattern 2x2 defensively copies cells and exposes an immutable list
00:00 +53: test/path_center_pattern_test.dart: PathCenterPattern 2x2 defensively copies cells and exposes an immutable list
00:00 +53: test/path_center_pattern_test.dart: PathCenterPattern 2x2 uses value equality and stable hashCode
00:00 +54: test/path_center_pattern_test.dart: PathCenterPattern 2x2 uses value equality and stable hashCode
00:00 +54: test/path_center_pattern_test.dart: PathCenterPattern invalid grids rejects an empty cell list
00:00 +55: test/path_center_pattern_test.dart: PathCenterPattern invalid grids rejects an empty cell list
00:00 +55: test/path_center_pattern_test.dart: PathCenterPattern invalid grids rejects a missing cell
00:00 +56: test/path_center_pattern_test.dart: PathCenterPattern invalid grids rejects a missing cell
00:00 +56: loading test/path_center_pattern_resolver_test.dart
00:00 +56: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 1x1 always resolves to the single local cell
00:00 +57: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 1x1 always resolves to the single local cell
00:00 +58: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 1x1 always resolves to the single local cell
00:00 +59: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 1x1 always resolves to the single local cell
00:00 +60: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 1x1 always resolves to the single local cell
00:00 +60: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 2x2 uses absolute map coordinates modulo pattern size
00:00 +61: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 2x2 uses absolute map coordinates modulo pattern size
00:00 +61: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell rectangular 3x2 does not assume square patterns
00:00 +62: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell rectangular 3x2 does not assume square patterns
00:00 +62: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell invalid coordinates rejects negative map coordinates
00:00 +63: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell invalid coordinates rejects negative map coordinates
00:00 +63: test/path_center_pattern_resolver_test.dart: PathCenterPatternCellResolution keeps map coordinates, local coordinates, and selected cell
00:00 +64: test/path_center_pattern_resolver_test.dart: PathCenterPatternCellResolution keeps map coordinates, local coordinates, and selected cell
00:00 +64: test/path_center_pattern_resolver_test.dart: PathCenterPatternCellResolution uses value equality and stable hashCode
00:00 +65: test/path_center_pattern_resolver_test.dart: PathCenterPatternCellResolution uses value equality and stable hashCode
00:00 +65: All tests passed!
```

### 7.5 Analyze ciblé

Commande:

```text
cd packages/map_editor && flutter analyze lib/src/features/path_studio/path_studio_panel.dart lib/src/features/path_studio/path_studio_theme.dart lib/src/features/editor/state/models/editor_workspace_mode.dart lib/src/features/editor/application/editor_workspace_controller.dart lib/src/features/editor/state/editor_notifier.dart lib/src/features/editor/state/editor_selectors.dart lib/src/ui/canvas/editor_canvas_host.dart lib/src/ui/editor_shell_page.dart lib/src/ui/panels/project_explorer_panel.dart lib/src/ui/shared/top_toolbar.dart test/path_pattern/path_studio_panel_test.dart test/editor_shell_page_smoke_test.dart test/editor_selectors_test.dart test/top_toolbar_test.dart test/shell_chrome_test_harness.dart
```

```text
Analyzing 15 items...
No issues found! (ran in 2.2s)
```

## 8. Reviewer séparé

Un sub-agent reviewer séparé a été utilisé. Il a signalé un risque réel: Save/Undo/Redo restaient accessibles en Path Studio si une map active existait. J’ai vérifié le code, corrigé `editor_selectors.dart` et `top_toolbar.dart`, puis ajouté les tests `Path Studio snapshots hide map save and history actions` et `disables map save and history actions in Path Studio`.

```text
Findings:
[P1] Path Studio still exposes map save/undo flows in editor_selectors.dart: shell snapshot and toolbar snapshot initially allowed active-map save/history outside map workspace.
[P1] Toolbar save/undo/redo are not gated out for Path Studio in top_toolbar.dart.
Resolution:
- Verified the issue against editor selectors and toolbar code.
- Added Path Studio gating so map save/undo/redo actions are exposed only in EditorWorkspaceMode.map.
- Added selector and toolbar tests with activeMap + dirty + canUndo/canRedo while workspaceMode is pathStudio.
Other reviewer checks:
- Scope otherwise contained to packages/map_editor.
- No map_core, runtime renderer, PNG generation, or persistent save model changes found.
- Navigation wiring coherent: explorer entry, toolbar button, notifier/controller, and EditorCanvasHost route to PathStudioWorkspace.
- Panel uses Lot 12 createPathPatternEditorReadModel(...).
```

## 9. Evidence Pack

### 9.1 Etat Git avant rapport

```text
$ git status --short
 M packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/editor_selectors_test.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
 M packages/map_editor/test/top_toolbar_test.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_theme.dart
?? packages/map_editor/test/path_pattern/path_studio_panel_test.dart
$ git diff --stat
 .../application/editor_workspace_controller.dart   |  4 ++
 .../src/features/editor/state/editor_notifier.dart |  8 +++
 .../features/editor/state/editor_selectors.dart    | 18 +++++--
 .../editor/state/models/editor_workspace_mode.dart |  7 +++
 .../lib/src/ui/canvas/editor_canvas_host.dart      |  2 +
 .../map_editor/lib/src/ui/editor_shell_page.dart   |  9 ++++
 .../lib/src/ui/panels/project_explorer_panel.dart  | 39 ++++++++++++--
 .../map_editor/lib/src/ui/shared/top_toolbar.dart  | 13 +++--
 .../map_editor/test/editor_selectors_test.dart     | 28 ++++++++++
 .../test/editor_shell_page_smoke_test.dart         | 62 ++++++++++++++++++++++
 .../map_editor/test/shell_chrome_test_harness.dart |  5 ++
 packages/map_editor/test/top_toolbar_test.dart     | 30 +++++++++++
 12 files changed, 214 insertions(+), 11 deletions(-)
$ git diff --name-status
M	packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
M	packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
M	packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
M	packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
M	packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
M	packages/map_editor/lib/src/ui/editor_shell_page.dart
M	packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
M	packages/map_editor/lib/src/ui/shared/top_toolbar.dart
M	packages/map_editor/test/editor_selectors_test.dart
M	packages/map_editor/test/editor_shell_page_smoke_test.dart
M	packages/map_editor/test/shell_chrome_test_harness.dart
M	packages/map_editor/test/top_toolbar_test.dart
```

### 9.2 Diff complet réel des fichiers suivis

```text
diff --git a/packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart b/packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
index 643c6cdd..a3b8eff4 100644
--- a/packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
+++ b/packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
@@ -58,6 +58,10 @@ class EditorWorkspaceController {
     return _openWorkspace(current, EditorWorkspaceMode.dialogue);
   }
 
+  EditorState selectPathStudioWorkspace(EditorState current) {
+    return _openWorkspace(current, EditorWorkspaceMode.pathStudio);
+  }
+
   /// Normalise les transitions de workspace :
   /// - on conserve tout l'état métier courant ;
   /// - on bascule seulement la surface centrale active ;
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
index 1a8fa05b..80ed98b0 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
@@ -1448,6 +1448,14 @@ class EditorNotifier extends _$EditorNotifier {
     state = _editorWorkspaceController.selectDialogueWorkspace(state);
   }
 
+  /// Bascule vers Path Studio.
+  ///
+  /// Navigation pure de shell : aucune mutation de manifest, aucune génération
+  /// de preview et aucun save flow ne sont déclenchés par ce point d'entrée.
+  void selectPathStudioWorkspace() {
+    state = _editorWorkspaceController.selectPathStudioWorkspace(state);
+  }
+
   /// Écrit uniquement le fichier `.yarn` (le manifest projet reste inchangé).
   Future<void> saveProjectDialogueYarnBody({
     required String dialogueId,
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart b/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
index 07628178..91e0c96e 100644
--- a/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
+++ b/packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
@@ -38,6 +38,7 @@ typedef EditorToolbarSnapshot = ({
   CollisionBrushSizeMode collisionBrushSizeMode,
   bool isSaving,
   bool isDirty,
+  bool canSaveMap,
   bool canUndoMap,
   bool canRedoMap,
   String? statusMessage,
@@ -149,6 +150,7 @@ final editorShellSnapshotProvider = Provider<EditorShellSnapshot>((ref) {
     EditorWorkspaceMode.step => 'Step Studio',
     EditorWorkspaceMode.cutscene => 'Cutscene Studio',
     EditorWorkspaceMode.dialogue => 'Dialogue Studio',
+    EditorWorkspaceMode.pathStudio => 'Path Studio',
   };
 
   final workspaceSubtitle = switch (workspaceMode) {
@@ -170,16 +172,20 @@ final editorShellSnapshotProvider = Provider<EditorShellSnapshot>((ref) {
       'Scene execution workspace: dialogue, movement, waits, local branching.',
     EditorWorkspaceMode.dialogue =>
       'Conversation authoring: visual blocks, preview, Yarn export — not a raw script IDE.',
+    EditorWorkspaceMode.pathStudio =>
+      'Créer des motifs de chemin à partir des presets PathPattern du projet.',
   };
 
+  final exposesMapActions = workspaceMode == EditorWorkspaceMode.map;
+
   return (
     workspaceMode: workspaceMode,
     workspaceTitle: workspaceTitle,
     workspaceSubtitle: workspaceSubtitle,
-    canUndoMap: canUndoMap,
-    canRedoMap: canRedoMap,
+    canUndoMap: exposesMapActions && canUndoMap,
+    canRedoMap: exposesMapActions && canRedoMap,
     isSaving: isSaving,
-    canSaveMap: activeMap != null && !isSaving,
+    canSaveMap: exposesMapActions && activeMap != null && !isSaving,
   );
 });
 
@@ -187,6 +193,7 @@ final editorToolbarSnapshotProvider = Provider<EditorToolbarSnapshot>((ref) {
   return ref.watch(
     editorNotifierProvider.select((state) {
       final project = state.project;
+      final exposesMapActions = state.workspaceMode == EditorWorkspaceMode.map;
       return (
         project: project,
         projectRootPath: state.projectRootPath,
@@ -202,8 +209,9 @@ final editorToolbarSnapshotProvider = Provider<EditorToolbarSnapshot>((ref) {
         collisionBrushSizeMode: state.collisionBrushSizeMode,
         isSaving: state.isSaving,
         isDirty: state.isDirty,
-        canUndoMap: state.canUndoMap,
-        canRedoMap: state.canRedoMap,
+        canSaveMap: exposesMapActions && state.activeMap != null,
+        canUndoMap: exposesMapActions && state.canUndoMap,
+        canRedoMap: exposesMapActions && state.canRedoMap,
         statusMessage: state.statusMessage,
       );
     }),
diff --git a/packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart b/packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
index cfd25854..98a959ae 100644
--- a/packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
+++ b/packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
@@ -36,4 +36,11 @@ enum EditorWorkspaceMode {
 
   /// Studio de conversation (dialogues `.yarn` en blocs visuels).
   dialogue,
+
+  /// Shell Path Studio V0.
+  ///
+  /// Ce mode expose une surface read-only pour les `ProjectPathPatternPreset` :
+  /// liste, recherche, sélection, diagnostics et inspecteur. Il ne branche ni
+  /// painter, ni save flow, ni éditeur réel du motif.
+  pathStudio,
 }
diff --git a/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart b/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
index a4994e83..893ba022 100644
--- a/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
+++ b/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
@@ -3,6 +3,7 @@ import 'package:flutter_riverpod/flutter_riverpod.dart';
 
 import '../../features/editor/state/editor_selectors.dart';
 import '../../features/editor/state/editor_state.dart';
+import '../../features/path_studio/path_studio_panel.dart';
 import 'map_canvas.dart';
 import 'narrative_workspace_canvas.dart';
 import 'pokemon_catalogs_workspace.dart';
@@ -26,6 +27,7 @@ class EditorCanvasHost extends ConsumerWidget {
       EditorWorkspaceMode.cutscene ||
       EditorWorkspaceMode.dialogue =>
         const NarrativeWorkspaceCanvas(),
+      EditorWorkspaceMode.pathStudio => const PathStudioWorkspace(),
     };
   }
 }
diff --git a/packages/map_editor/lib/src/ui/editor_shell_page.dart b/packages/map_editor/lib/src/ui/editor_shell_page.dart
index 710bfaec..2fd28ff6 100644
--- a/packages/map_editor/lib/src/ui/editor_shell_page.dart
+++ b/packages/map_editor/lib/src/ui/editor_shell_page.dart
@@ -77,6 +77,7 @@ class _EditorShellPageState extends ConsumerState<EditorShellPage> {
     final notifier = ref.read(editorNotifierProvider.notifier);
     final supportsRightInspector = switch (workspaceMode) {
       EditorWorkspaceMode.pokedex => false,
+      EditorWorkspaceMode.pathStudio => false,
       _ => true,
     };
 
@@ -329,6 +330,8 @@ class _EditorShellPageState extends ConsumerState<EditorShellPage> {
                                       EditorChrome.islandNeutralTint,
                                     EditorWorkspaceMode.dialogue =>
                                       EditorChrome.islandCoolTint,
+                                    EditorWorkspaceMode.pathStudio =>
+                                      EditorChrome.islandCoolTint,
                                   },
                                   child: switch (workspaceMode) {
                                     EditorWorkspaceMode.map =>
@@ -345,6 +348,8 @@ class _EditorShellPageState extends ConsumerState<EditorShellPage> {
                                     // structure latérale ou une fausse logique.
                                     EditorWorkspaceMode.pokedex =>
                                       const _EmptyWorkspaceInspector(),
+                                    EditorWorkspaceMode.pathStudio =>
+                                      const _EmptyWorkspaceInspector(),
                                     EditorWorkspaceMode.globalStory ||
                                     EditorWorkspaceMode.step ||
                                     EditorWorkspaceMode.cutscene ||
@@ -481,6 +486,7 @@ class _WorkspaceStageHeader extends StatelessWidget {
       EditorWorkspaceMode.step => EditorChrome.inspectorJoyMint,
       EditorWorkspaceMode.cutscene => EditorChrome.inspectorJoyCoral,
       EditorWorkspaceMode.dialogue => EditorChrome.inspectorJoyBlue,
+      EditorWorkspaceMode.pathStudio => EditorChrome.accentPrimary,
     };
     final chipAccent2 = switch (workspaceMode) {
       EditorWorkspaceMode.map => EditorChrome.inspectorJoyApricot,
@@ -491,6 +497,7 @@ class _WorkspaceStageHeader extends StatelessWidget {
       EditorWorkspaceMode.step => EditorChrome.accentJade,
       EditorWorkspaceMode.cutscene => EditorChrome.inspectorJoyCoral,
       EditorWorkspaceMode.dialogue => EditorChrome.inspectorJoyCyan,
+      EditorWorkspaceMode.pathStudio => EditorChrome.inspectorJoyCyan,
     };
 
     return Row(
@@ -524,6 +531,7 @@ class _WorkspaceStageHeader extends StatelessWidget {
               EditorWorkspaceMode.step => CupertinoIcons.flag,
               EditorWorkspaceMode.cutscene => CupertinoIcons.play_rectangle,
               EditorWorkspaceMode.dialogue => CupertinoIcons.text_bubble,
+              EditorWorkspaceMode.pathStudio => CupertinoIcons.arrow_branch,
             },
             color: CupertinoColors.white,
             size: 22,
@@ -605,6 +613,7 @@ class _WorkspaceStageHeader extends StatelessWidget {
               EditorWorkspaceMode.step => 'Step',
               EditorWorkspaceMode.cutscene => 'Cutscene',
               EditorWorkspaceMode.dialogue => 'Dialogue',
+              EditorWorkspaceMode.pathStudio => 'Path',
             },
             style: TextStyle(
               color: chipAccent,
diff --git a/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart b/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
index 8774dcd3..28a1ef3e 100644
--- a/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
+++ b/packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
@@ -334,14 +334,15 @@ class _ProjectExplorerPanelState extends ConsumerState<ProjectExplorerPanel> {
         InspectorSectionCard(
           borderRadius: explorerTileRadius,
           title: 'Path Library',
-          subtitle: 'Surface overlays: roads, water, tall grass...',
+          subtitle: 'Legacy paths and Path Studio shell',
           icon: CupertinoIcons.arrow_branch,
           accentColor: EditorChrome.accentWarm,
-          badgeText: '${project.pathPresets.length}',
+          badgeText:
+              '${project.pathPresets.length}/${project.pathPatternPresets.length}',
           expanded: _expandPaths,
           onToggle: () => setState(() => _expandPaths = !_expandPaths),
           expandedHeight: hPaths,
-          child: const PathLibraryPanel(embedded: true),
+          child: _buildPathLibraryCard(context, project, snapshot, notifier),
         ),
         InspectorSectionCard(
           borderRadius: explorerTileRadius,
@@ -449,6 +450,38 @@ class _ProjectExplorerPanelState extends ConsumerState<ProjectExplorerPanel> {
     );
   }
 
+  Widget _buildPathLibraryCard(
+    BuildContext context,
+    ProjectManifest project,
+    EditorProjectExplorerSnapshot snapshot,
+    EditorNotifier notifier,
+  ) {
+    final isPathStudio =
+        snapshot.workspaceMode == EditorWorkspaceMode.pathStudio;
+
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        EditorSidebarListRow(
+          key: const Key('project-explorer-path-studio-entry'),
+          selected: isPathStudio,
+          onTap: notifier.selectPathStudioWorkspace,
+          leading: const MacosIcon(CupertinoIcons.arrow_branch),
+          title: const Text('Path Studio'),
+          subtitle: Text(
+            '${project.pathPatternPresets.length} motifs PathPattern — shell read-only',
+            maxLines: 1,
+            overflow: TextOverflow.ellipsis,
+          ),
+        ),
+        const SizedBox(height: 8),
+        const Expanded(
+          child: PathLibraryPanel(embedded: true),
+        ),
+      ],
+    );
+  }
+
   Widget _buildWorldIslandBody(
     BuildContext context,
     List<Widget> worldChildren,
diff --git a/packages/map_editor/lib/src/ui/shared/top_toolbar.dart b/packages/map_editor/lib/src/ui/shared/top_toolbar.dart
index b104cb5e..67a1ddf7 100644
--- a/packages/map_editor/lib/src/ui/shared/top_toolbar.dart
+++ b/packages/map_editor/lib/src/ui/shared/top_toolbar.dart
@@ -169,9 +169,7 @@ class TopToolbar extends ConsumerWidget {
               icon: CupertinoIcons.floppy_disk,
               tooltip: 'Save Map',
               selected: toolbar.isDirty,
-              onPressed: toolbar.activeMap != null
-                  ? () => notifier.saveActiveMap()
-                  : null,
+              onPressed: toolbar.canSaveMap ? notifier.saveActiveMap : null,
             ),
           ToolbarCapsuleButton(
             icon: CupertinoIcons.arrow_uturn_left,
@@ -245,6 +243,14 @@ class TopToolbar extends ConsumerWidget {
             selected: toolbar.workspaceMode == EditorWorkspaceMode.dialogue,
             onPressed: notifier.selectDialogueWorkspace,
           ),
+          ToolbarCapsuleButton(
+            icon: CupertinoIcons.arrow_branch,
+            tooltip: 'Switch to Path Studio',
+            selected: toolbar.workspaceMode == EditorWorkspaceMode.pathStudio,
+            onPressed: toolbar.project != null
+                ? notifier.selectPathStudioWorkspace
+                : null,
+          ),
         ],
       ),
       if (showWorldTools)
@@ -448,6 +454,7 @@ class TopToolbar extends ConsumerWidget {
           EditorWorkspaceMode.step => 'Step Studio',
           EditorWorkspaceMode.cutscene => 'Cutscene Studio',
           EditorWorkspaceMode.dialogue => 'Dialogue Studio',
+          EditorWorkspaceMode.pathStudio => 'Path Studio',
         },
       ),
       titleWidth: 236,
diff --git a/packages/map_editor/test/editor_selectors_test.dart b/packages/map_editor/test/editor_selectors_test.dart
index b2bea1ef..3cc6daa8 100644
--- a/packages/map_editor/test/editor_selectors_test.dart
+++ b/packages/map_editor/test/editor_selectors_test.dart
@@ -76,6 +76,34 @@ void main() {
       expect(toolbar.activeLayer, isA<TileLayer>());
     });
 
+    test('Path Studio snapshots hide map save and history actions', () {
+      final container = ProviderContainer();
+      addTearDown(container.dispose);
+
+      container.read(editorNotifierProvider.notifier).state = const EditorState(
+        workspaceMode: EditorWorkspaceMode.pathStudio,
+        activeMap: MapData(
+          id: 'town',
+          name: 'Starter Town',
+          size: GridSize(width: 8, height: 8),
+          layers: [],
+        ),
+        canUndoMap: true,
+        canRedoMap: true,
+        isDirty: true,
+      );
+
+      final shell = container.read(editorShellSnapshotProvider);
+      final toolbar = container.read(editorToolbarSnapshotProvider);
+
+      expect(shell.canSaveMap, isFalse);
+      expect(shell.canUndoMap, isFalse);
+      expect(shell.canRedoMap, isFalse);
+      expect(toolbar.canSaveMap, isFalse);
+      expect(toolbar.canUndoMap, isFalse);
+      expect(toolbar.canRedoMap, isFalse);
+    });
+
     test('editorProjectExplorerSnapshotProvider exposes active map selection',
         () {
       final container = ProviderContainer();
diff --git a/packages/map_editor/test/editor_shell_page_smoke_test.dart b/packages/map_editor/test/editor_shell_page_smoke_test.dart
index 87cb0f87..74b8c975 100644
--- a/packages/map_editor/test/editor_shell_page_smoke_test.dart
+++ b/packages/map_editor/test/editor_shell_page_smoke_test.dart
@@ -8,6 +8,7 @@ import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
 import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';
 import 'package:map_editor/src/application/models/pokemon_database_index.dart';
 import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
+import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
 import 'package:map_editor/src/features/editor/state/editor_state.dart';
 
 import 'shell_chrome_test_harness.dart';
@@ -208,6 +209,67 @@ void main() {
       );
     });
 
+    testWidgets('opens Path Studio from the project explorer', (tester) async {
+      final container = await pumpEditorShellPage(
+        tester,
+        initialState: EditorState(
+          projectRootPath: '/tmp/editor_shell_path_studio',
+          project: buildShellChromeProject(
+            pathPresets: const <ProjectPathPreset>[
+              ProjectPathPreset(
+                id: 'legacy-water',
+                name: 'Legacy Water',
+                surfaceKind: PathSurfaceKind.water,
+              ),
+            ],
+            pathPatternPresets: [
+              ProjectPathPatternPreset(
+                id: 'water-1x1',
+                name: 'Water 1x1',
+                basePathPresetId: 'legacy-water',
+                centerPattern: PathCenterPattern(
+                  size: PathCenterPatternSize(width: 1, height: 1),
+                  cells: [
+                    PathCenterPatternCell(
+                      localX: 0,
+                      localY: 0,
+                      frames: [
+                        const TilesetVisualFrame(
+                          source: TilesetSourceRect(x: 0, y: 0),
+                        ),
+                      ],
+                    ),
+                  ],
+                ),
+              ),
+            ],
+          ),
+        ),
+      );
+
+      expect(
+        find.byKey(const Key('project-explorer-path-studio-entry')),
+        findsOneWidget,
+      );
+
+      await tester.ensureVisible(
+        find.byKey(const Key('project-explorer-path-studio-entry')),
+      );
+      await tester.pumpAndSettle();
+      await tester.tap(
+        find.byKey(const Key('project-explorer-path-studio-entry')),
+      );
+      await tester.pumpAndSettle();
+
+      expect(
+        container.read(editorNotifierProvider).workspaceMode,
+        EditorWorkspaceMode.pathStudio,
+      );
+      expect(find.text('Path Studio'), findsWidgets);
+      expect(find.text('Créer des motifs de chemin'), findsWidgets);
+      expect(find.text('Water 1x1'), findsWidgets);
+    });
+
     testWidgets('renders shell chrome with an error state already present',
         (tester) async {
       await pumpEditorShellPage(
diff --git a/packages/map_editor/test/shell_chrome_test_harness.dart b/packages/map_editor/test/shell_chrome_test_harness.dart
index aff6d9ff..57ba2b54 100644
--- a/packages/map_editor/test/shell_chrome_test_harness.dart
+++ b/packages/map_editor/test/shell_chrome_test_harness.dart
@@ -33,11 +33,16 @@ ProjectManifest buildShellChromeProject({
   String name = 'Demo Project',
   List<ProjectMapEntry> maps = const <ProjectMapEntry>[],
   List<ProjectTilesetEntry> tilesets = const <ProjectTilesetEntry>[],
+  List<ProjectPathPreset> pathPresets = const <ProjectPathPreset>[],
+  List<ProjectPathPatternPreset> pathPatternPresets =
+      const <ProjectPathPatternPreset>[],
 }) {
   return ProjectManifest(
     name: name,
     maps: maps,
     tilesets: tilesets,
+    pathPresets: pathPresets,
+    pathPatternPresets: pathPatternPresets,
     surfaceCatalog: ProjectSurfaceCatalog(),
   );
 }
diff --git a/packages/map_editor/test/top_toolbar_test.dart b/packages/map_editor/test/top_toolbar_test.dart
index 1a838504..9ea36ac6 100644
--- a/packages/map_editor/test/top_toolbar_test.dart
+++ b/packages/map_editor/test/top_toolbar_test.dart
@@ -1,5 +1,6 @@
 import 'package:flutter_test/flutter_test.dart';
 import 'package:map_editor/src/features/editor/state/editor_state.dart';
+import 'package:map_editor/src/ui/shared/top_toolbar/widgets/toolbar_capsules.dart';
 
 import 'shell_chrome_test_harness.dart';
 
@@ -58,5 +59,34 @@ void main() {
 
       expect(find.text('Pokemon Map  •  Trainer Studio'), findsOneWidget);
     });
+
+    testWidgets('disables map save and history actions in Path Studio',
+        (tester) async {
+      await pumpTopToolbarHarness(
+        tester,
+        initialState: EditorState(
+          projectRootPath: '/tmp/top_toolbar_path_studio',
+          project: buildShellChromeProject(name: 'Pokemon Map'),
+          workspaceMode: EditorWorkspaceMode.pathStudio,
+          activeMap: buildShellChromeMap(),
+          isDirty: true,
+          canUndoMap: true,
+          canRedoMap: true,
+        ),
+      );
+
+      ToolbarCapsuleButton buttonWithTooltip(String tooltip) {
+        return tester.widget<ToolbarCapsuleButton>(
+          find.byWidgetPredicate(
+            (widget) =>
+                widget is ToolbarCapsuleButton && widget.tooltip == tooltip,
+          ),
+        );
+      }
+
+      expect(buttonWithTooltip('Save Map').onPressed, isNull);
+      expect(buttonWithTooltip('Undo').onPressed, isNull);
+      expect(buttonWithTooltip('Redo').onPressed, isNull);
+    });
   });
 }
```

### 9.3 Diff /dev/null complet des fichiers créés

#### packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart

```text
--- /dev/null	2026-04-30 19:55:25
+++ packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart	2026-04-30 19:46:55
@@ -0,0 +1,1441 @@
+import 'package:flutter/cupertino.dart';
+import 'package:flutter_riverpod/flutter_riverpod.dart';
+import 'package:macos_ui/macos_ui.dart';
+import 'package:map_core/map_core.dart';
+
+import '../editor/state/editor_selectors.dart';
+import 'path_pattern_editor_read_model.dart';
+import 'path_studio_theme.dart';
+
+/// Workspace branché au shell global de l'éditeur.
+///
+/// Ce wrapper Riverpod reste volontairement fin : il lit seulement le manifest
+/// courant et délègue tout le rendu read-only à [PathStudioPanel]. Le lot 13 ne
+/// crée ni repository, ni provider dédié, ni contrôleur de sauvegarde.
+class PathStudioWorkspace extends ConsumerWidget {
+  const PathStudioWorkspace({super.key});
+
+  @override
+  Widget build(BuildContext context, WidgetRef ref) {
+    final manifest = ref.watch(editorProjectManifestProvider);
+    if (manifest == null) {
+      return const _PathStudioProjectMissingState();
+    }
+    return PathStudioPanel(manifest: manifest);
+  }
+}
+
+/// Shell visuel read-only du Path Studio.
+///
+/// Le widget reçoit un [ProjectManifest] explicite pour rester testable sans
+/// dépendance à l'infrastructure éditeur. Toute l'information métier affichée
+/// passe par le read model du lot 12 : aucune logique de diagnostic PathPattern
+/// n'est recalculée ici.
+class PathStudioPanel extends StatefulWidget {
+  const PathStudioPanel({
+    super.key,
+    required this.manifest,
+  });
+
+  final ProjectManifest manifest;
+
+  @override
+  State<PathStudioPanel> createState() => _PathStudioPanelState();
+}
+
+class _PathStudioPanelState extends State<PathStudioPanel> {
+  String _searchQuery = '';
+
+  /// Index dans `readModel.presets`, pas id métier.
+  ///
+  /// Les ids dupliqués sont précisément un diagnostic V0 ; sélectionner par id
+  /// rendrait une card ambiguë. L'index source garde donc une sélection stable
+  /// même quand deux presets portent le même identifiant.
+  int? _selectedSourceIndex;
+
+  @override
+  void didUpdateWidget(covariant PathStudioPanel oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (oldWidget.manifest != widget.manifest) {
+      _selectedSourceIndex = null;
+    }
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final readModel = createPathPatternEditorReadModel(
+      manifest: widget.manifest,
+    );
+    final query = _searchQuery.trim().toLowerCase();
+    final filtered = _filteredCards(readModel, query);
+    final selected = _selectedCard(filtered);
+
+    return DecoratedBox(
+      decoration: const BoxDecoration(
+        gradient: PathStudioTheme.backgroundGradient,
+      ),
+      child: Padding(
+        padding: const EdgeInsets.all(18),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.stretch,
+          children: [
+            _PathStudioHeader(
+              summary: readModel.summary,
+            ),
+            const SizedBox(height: 16),
+            Expanded(
+              child: Row(
+                crossAxisAlignment: CrossAxisAlignment.stretch,
+                children: [
+                  SizedBox(
+                    width: 292,
+                    child: _PresetSidebar(
+                      readModel: readModel,
+                      filteredCards: filtered,
+                      selectedSourceIndex: selected?.sourceIndex,
+                      onQueryChanged: (value) {
+                        setState(() => _searchQuery = value);
+                      },
+                      onSelect: (sourceIndex) {
+                        setState(() => _selectedSourceIndex = sourceIndex);
+                      },
+                    ),
+                  ),
+                  const SizedBox(width: 16),
+                  Expanded(
+                    child: _CenterWorkspace(
+                      selected: selected?.card,
+                      hasAnyPreset: readModel.presets.isNotEmpty,
+                    ),
+                  ),
+                  const SizedBox(width: 16),
+                  SizedBox(
+                    width: 326,
+                    child: _PresetInspector(selected: selected?.card),
+                  ),
+                ],
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+
+  List<_IndexedPresetCard> _filteredCards(
+    PathPatternEditorReadModel readModel,
+    String query,
+  ) {
+    final indexed = <_IndexedPresetCard>[];
+    for (var index = 0; index < readModel.presets.length; index += 1) {
+      final card = readModel.presets[index];
+      if (query.isEmpty || _matchesQuery(card, query)) {
+        indexed.add(_IndexedPresetCard(index, card));
+      }
+    }
+    return indexed;
+  }
+
+  bool _matchesQuery(PathPatternPresetCardModel card, String query) {
+    final fields = [
+      card.name,
+      card.id,
+      card.basePathPresetId,
+      card.basePathPresetName,
+      card.basePathSurfaceKindLabel,
+      card.centerPatternLabel,
+    ];
+    return fields
+        .whereType<String>()
+        .any((field) => field.toLowerCase().contains(query));
+  }
+
+  _IndexedPresetCard? _selectedCard(List<_IndexedPresetCard> filtered) {
+    if (filtered.isEmpty) {
+      return null;
+    }
+    for (final entry in filtered) {
+      if (entry.sourceIndex == _selectedSourceIndex) {
+        return entry;
+      }
+    }
+    return filtered.first;
+  }
+}
+
+class _IndexedPresetCard {
+  const _IndexedPresetCard(this.sourceIndex, this.card);
+
+  final int sourceIndex;
+  final PathPatternPresetCardModel card;
+}
+
+class _PathStudioProjectMissingState extends StatelessWidget {
+  const _PathStudioProjectMissingState();
+
+  @override
+  Widget build(BuildContext context) {
+    return const ColoredBox(
+      color: PathStudioTheme.background,
+      child: Center(
+        child: Text(
+          'Charger un projet pour ouvrir Path Studio.',
+          style: TextStyle(
+            color: PathStudioTheme.textSecondary,
+            fontSize: 14,
+            fontWeight: FontWeight.w600,
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+class _PathStudioHeader extends StatelessWidget {
+  const _PathStudioHeader({
+    required this.summary,
+  });
+
+  final PathPatternEditorSummary summary;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      decoration: PathStudioTheme.panelDecoration(
+        color: PathStudioTheme.surface,
+        radius: 24,
+      ),
+      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
+      child: Row(
+        children: [
+          Container(
+            width: 46,
+            height: 46,
+            decoration: BoxDecoration(
+              gradient: const LinearGradient(
+                begin: Alignment.topLeft,
+                end: Alignment.bottomRight,
+                colors: [
+                  PathStudioTheme.accentHover,
+                  PathStudioTheme.accent,
+                ],
+              ),
+              borderRadius: BorderRadius.circular(15),
+              border: Border.all(
+                color: PathStudioTheme.accentHover.withValues(alpha: 0.8),
+              ),
+            ),
+            child: const MacosIcon(
+              CupertinoIcons.arrow_branch,
+              color: CupertinoColors.white,
+              size: 24,
+            ),
+          ),
+          const SizedBox(width: 14),
+          const Expanded(
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Text(
+                  'Path Studio',
+                  style: TextStyle(
+                    color: PathStudioTheme.textPrimary,
+                    fontSize: 22,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+                SizedBox(height: 3),
+                Text(
+                  'Créer des motifs de chemin',
+                  style: TextStyle(
+                    color: PathStudioTheme.textSecondary,
+                    fontSize: 13,
+                    fontWeight: FontWeight.w600,
+                  ),
+                ),
+              ],
+            ),
+          ),
+          _SummaryPill(label: 'Presets', value: '${summary.totalCount}'),
+          const SizedBox(width: 8),
+          _SummaryPill(label: 'Prêts', value: '${summary.readyCount}'),
+          const SizedBox(width: 12),
+          const _ShellActionButton(
+            icon: CupertinoIcons.plus,
+            label: 'Nouveau preset',
+          ),
+          const SizedBox(width: 8),
+          const _ShellActionButton(
+            icon: CupertinoIcons.square_on_square,
+            label: 'Dupliquer',
+          ),
+          const SizedBox(width: 8),
+          const _ShellActionButton(
+            icon: CupertinoIcons.floppy_disk,
+            label: 'Enregistrer',
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _SummaryPill extends StatelessWidget {
+  const _SummaryPill({
+    required this.label,
+    required this.value,
+  });
+
+  final String label;
+  final String value;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
+      decoration: BoxDecoration(
+        color: PathStudioTheme.surfaceRaised,
+        borderRadius: BorderRadius.circular(999),
+        border: Border.all(color: PathStudioTheme.border),
+      ),
+      child: Row(
+        mainAxisSize: MainAxisSize.min,
+        children: [
+          Text(
+            value,
+            style: const TextStyle(
+              color: PathStudioTheme.textPrimary,
+              fontSize: 13,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(width: 5),
+          Text(
+            label,
+            style: const TextStyle(
+              color: PathStudioTheme.textMuted,
+              fontSize: 11,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _ShellActionButton extends StatelessWidget {
+  const _ShellActionButton({
+    required this.icon,
+    required this.label,
+  });
+
+  final IconData icon;
+  final String label;
+
+  @override
+  Widget build(BuildContext context) {
+    return CupertinoButton(
+      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
+      minimumSize: Size.zero,
+      onPressed: null,
+      disabledColor: PathStudioTheme.surfaceRaised.withValues(alpha: 0.72),
+      color: PathStudioTheme.accent,
+      borderRadius: BorderRadius.circular(13),
+      child: Row(
+        mainAxisSize: MainAxisSize.min,
+        children: [
+          MacosIcon(
+            icon,
+            color: PathStudioTheme.textMuted.withValues(alpha: 0.72),
+            size: 15,
+          ),
+          const SizedBox(width: 8),
+          Column(
+            crossAxisAlignment: CrossAxisAlignment.start,
+            children: [
+              Text(
+                label,
+                style: TextStyle(
+                  color: PathStudioTheme.textSecondary.withValues(alpha: 0.7),
+                  fontSize: 12,
+                  fontWeight: FontWeight.w800,
+                ),
+              ),
+              const Text(
+                'lot futur',
+                style: TextStyle(
+                  color: PathStudioTheme.textMuted,
+                  fontSize: 9,
+                  fontWeight: FontWeight.w700,
+                ),
+              ),
+            ],
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _PresetSidebar extends StatelessWidget {
+  const _PresetSidebar({
+    required this.readModel,
+    required this.filteredCards,
+    required this.selectedSourceIndex,
+    required this.onQueryChanged,
+    required this.onSelect,
+  });
+
+  final PathPatternEditorReadModel readModel;
+  final List<_IndexedPresetCard> filteredCards;
+  final int? selectedSourceIndex;
+  final ValueChanged<String> onQueryChanged;
+  final ValueChanged<int> onSelect;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      decoration: PathStudioTheme.panelDecoration(),
+      padding: const EdgeInsets.all(14),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Row(
+            children: [
+              const Expanded(
+                child: Text(
+                  'Presets',
+                  style: TextStyle(
+                    color: PathStudioTheme.textPrimary,
+                    fontSize: 16,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+              ),
+              _SidebarCounter(value: readModel.summary.totalCount),
+            ],
+          ),
+          const SizedBox(height: 12),
+          CupertinoTextField(
+            key: const Key('path-studio-search-field'),
+            onChanged: onQueryChanged,
+            placeholder: 'Rechercher un preset...',
+            prefix: const Padding(
+              padding: EdgeInsets.only(left: 10),
+              child: MacosIcon(
+                CupertinoIcons.search,
+                size: 15,
+                color: PathStudioTheme.textMuted,
+              ),
+            ),
+            style: const TextStyle(
+              color: PathStudioTheme.textPrimary,
+              fontSize: 13,
+            ),
+            placeholderStyle: const TextStyle(
+              color: PathStudioTheme.textMuted,
+              fontSize: 13,
+            ),
+            decoration: BoxDecoration(
+              color: PathStudioTheme.surfaceStrong,
+              borderRadius: BorderRadius.circular(13),
+              border: Border.all(color: PathStudioTheme.border),
+            ),
+          ),
+          const SizedBox(height: 12),
+          Expanded(
+            child: _buildPresetList(),
+          ),
+        ],
+      ),
+    );
+  }
+
+  Widget _buildPresetList() {
+    if (readModel.presets.isEmpty) {
+      return const _SidebarNotice(
+        title: 'Aucun motif PathPattern',
+        message: 'Les presets apparaîtront ici après le lot création.',
+      );
+    }
+    if (filteredCards.isEmpty) {
+      return const _SidebarNotice(
+        title: 'Aucun preset trouvé',
+        message: 'Essayez un autre nom, id ou preset de base.',
+      );
+    }
+    return ListView.separated(
+      itemCount: filteredCards.length,
+      separatorBuilder: (_, __) => const SizedBox(height: 10),
+      itemBuilder: (context, index) {
+        final entry = filteredCards[index];
+        return _PresetListCard(
+          key: Key('path-studio-preset-card-${entry.sourceIndex}'),
+          card: entry.card,
+          selected: entry.sourceIndex == selectedSourceIndex,
+          onTap: () => onSelect(entry.sourceIndex),
+        );
+      },
+    );
+  }
+}
+
+class _SidebarCounter extends StatelessWidget {
+  const _SidebarCounter({required this.value});
+
+  final int value;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
+      decoration: BoxDecoration(
+        color: PathStudioTheme.accent.withValues(alpha: 0.15),
+        borderRadius: BorderRadius.circular(999),
+        border:
+            Border.all(color: PathStudioTheme.accent.withValues(alpha: 0.4)),
+      ),
+      child: Text(
+        '$value',
+        style: const TextStyle(
+          color: PathStudioTheme.accentHover,
+          fontSize: 12,
+          fontWeight: FontWeight.w800,
+        ),
+      ),
+    );
+  }
+}
+
+class _SidebarNotice extends StatelessWidget {
+  const _SidebarNotice({
+    required this.title,
+    required this.message,
+  });
+
+  final String title;
+  final String message;
+
+  @override
+  Widget build(BuildContext context) {
+    return Center(
+      child: Container(
+        padding: const EdgeInsets.all(16),
+        decoration: PathStudioTheme.subtleDecoration(),
+        child: Column(
+          mainAxisSize: MainAxisSize.min,
+          children: [
+            const MacosIcon(
+              CupertinoIcons.tray,
+              color: PathStudioTheme.textMuted,
+              size: 26,
+            ),
+            const SizedBox(height: 10),
+            Text(
+              title,
+              textAlign: TextAlign.center,
+              style: const TextStyle(
+                color: PathStudioTheme.textPrimary,
+                fontSize: 13,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+            const SizedBox(height: 5),
+            Text(
+              message,
+              textAlign: TextAlign.center,
+              style: const TextStyle(
+                color: PathStudioTheme.textMuted,
+                fontSize: 11,
+                height: 1.3,
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _PresetListCard extends StatefulWidget {
+  const _PresetListCard({
+    super.key,
+    required this.card,
+    required this.selected,
+    required this.onTap,
+  });
+
+  final PathPatternPresetCardModel card;
+  final bool selected;
+  final VoidCallback onTap;
+
+  @override
+  State<_PresetListCard> createState() => _PresetListCardState();
+}
+
+class _PresetListCardState extends State<_PresetListCard> {
+  bool _hovered = false;
+
+  @override
+  Widget build(BuildContext context) {
+    final status = _statusPresentation(widget.card.status);
+    final borderColor = widget.selected
+        ? PathStudioTheme.accentHover
+        : widget.card.status == PathPatternPresetReadinessStatus.blocked
+            ? PathStudioTheme.error.withValues(alpha: 0.45)
+            : PathStudioTheme.border;
+    final fill = widget.selected
+        ? Color.lerp(
+            PathStudioTheme.surfaceStrong, PathStudioTheme.accent, 0.2)!
+        : _hovered
+            ? Color.lerp(
+                PathStudioTheme.surfaceRaised,
+                PathStudioTheme.accent,
+                0.08,
+              )!
+            : PathStudioTheme.surfaceRaised;
+
+    return MouseRegion(
+      onEnter: (_) => setState(() => _hovered = true),
+      onExit: (_) => setState(() => _hovered = false),
+      child: GestureDetector(
+        onTap: widget.onTap,
+        child: AnimatedContainer(
+          duration: const Duration(milliseconds: 120),
+          padding: const EdgeInsets.all(12),
+          decoration: BoxDecoration(
+            color: fill,
+            borderRadius: BorderRadius.circular(16),
+            border:
+                Border.all(color: borderColor, width: widget.selected ? 2 : 1),
+          ),
+          child: Column(
+            crossAxisAlignment: CrossAxisAlignment.start,
+            children: [
+              Row(
+                children: [
+                  Expanded(
+                    child: Text(
+                      widget.card.name,
+                      maxLines: 1,
+                      overflow: TextOverflow.ellipsis,
+                      style: const TextStyle(
+                        color: PathStudioTheme.textPrimary,
+                        fontSize: 13,
+                        fontWeight: FontWeight.w800,
+                      ),
+                    ),
+                  ),
+                  _StatusChip(label: status.label, color: status.color),
+                ],
+              ),
+              const SizedBox(height: 8),
+              Text(
+                widget.card.id,
+                maxLines: 1,
+                overflow: TextOverflow.ellipsis,
+                style: const TextStyle(
+                  color: PathStudioTheme.textMuted,
+                  fontSize: 11,
+                  fontWeight: FontWeight.w600,
+                ),
+              ),
+              const SizedBox(height: 10),
+              Row(
+                children: [
+                  _MiniMetric(
+                    icon: CupertinoIcons.square_grid_2x2,
+                    label: widget.card.centerPatternLabel,
+                  ),
+                  const SizedBox(width: 8),
+                  _MiniMetric(
+                    icon: widget.card.animatedCellCount > 0
+                        ? CupertinoIcons.play_circle
+                        : CupertinoIcons.circle,
+                    label: widget.card.animatedCellCount > 0
+                        ? 'animé'
+                        : 'statique',
+                  ),
+                ],
+              ),
+            ],
+          ),
+        ),
+      ),
+    );
+  }
+}
+
+class _StatusChip extends StatelessWidget {
+  const _StatusChip({
+    required this.label,
+    required this.color,
+  });
+
+  final String label;
+  final Color color;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
+      decoration: BoxDecoration(
+        color: color.withValues(alpha: 0.15),
+        borderRadius: BorderRadius.circular(999),
+        border: Border.all(color: color.withValues(alpha: 0.48)),
+      ),
+      child: Text(
+        label,
+        style: TextStyle(
+          color: color,
+          fontSize: 10,
+          fontWeight: FontWeight.w800,
+        ),
+      ),
+    );
+  }
+}
+
+class _MiniMetric extends StatelessWidget {
+  const _MiniMetric({
+    required this.icon,
+    required this.label,
+  });
+
+  final IconData icon;
+  final String label;
+
+  @override
+  Widget build(BuildContext context) {
+    return Row(
+      mainAxisSize: MainAxisSize.min,
+      children: [
+        MacosIcon(icon, size: 12, color: PathStudioTheme.textMuted),
+        const SizedBox(width: 4),
+        Text(
+          label,
+          style: const TextStyle(
+            color: PathStudioTheme.textSecondary,
+            fontSize: 11,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+      ],
+    );
+  }
+}
+
+class _CenterWorkspace extends StatelessWidget {
+  const _CenterWorkspace({
+    required this.selected,
+    required this.hasAnyPreset,
+  });
+
+  final PathPatternPresetCardModel? selected;
+  final bool hasAnyPreset;
+
+  @override
+  Widget build(BuildContext context) {
+    final card = selected;
+    if (card == null) {
+      return _NoSelectionCenter(hasAnyPreset: hasAnyPreset);
+    }
+
+    return SingleChildScrollView(
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          _WorkflowSteps(status: card.status),
+          const SizedBox(height: 14),
+          _SelectedSummary(card: card),
+          const SizedBox(height: 14),
+          _CenterPatternPlaceholder(card: card),
+          const SizedBox(height: 14),
+          _DiagnosticsCard(card: card),
+        ],
+      ),
+    );
+  }
+}
+
+class _NoSelectionCenter extends StatelessWidget {
+  const _NoSelectionCenter({required this.hasAnyPreset});
+
+  final bool hasAnyPreset;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      decoration: PathStudioTheme.panelDecoration(
+        color: PathStudioTheme.surface,
+      ),
+      padding: const EdgeInsets.all(28),
+      child: Center(
+        child: Column(
+          mainAxisSize: MainAxisSize.min,
+          children: [
+            const MacosIcon(
+              CupertinoIcons.square_grid_2x2,
+              color: PathStudioTheme.accentCyan,
+              size: 44,
+            ),
+            const SizedBox(height: 16),
+            Text(
+              hasAnyPreset
+                  ? 'Aucun preset sélectionné'
+                  : 'Aucun motif PathPattern',
+              style: const TextStyle(
+                color: PathStudioTheme.textPrimary,
+                fontSize: 20,
+                fontWeight: FontWeight.w800,
+              ),
+            ),
+            const SizedBox(height: 8),
+            Text(
+              hasAnyPreset
+                  ? 'Sélectionnez un preset dans la liste pour inspecter sa structure.'
+                  : 'Les futurs lots permettront de créer un premier motif de centre.',
+              textAlign: TextAlign.center,
+              style: const TextStyle(
+                color: PathStudioTheme.textSecondary,
+                fontSize: 13,
+                height: 1.35,
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _WorkflowSteps extends StatelessWidget {
+  const _WorkflowSteps({required this.status});
+
+  final PathPatternPresetReadinessStatus status;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      decoration: PathStudioTheme.panelDecoration(
+        color: PathStudioTheme.surface,
+        radius: 18,
+      ),
+      padding: const EdgeInsets.all(14),
+      child: Row(
+        children: [
+          Expanded(
+            child: Wrap(
+              spacing: 10,
+              runSpacing: 10,
+              children: [
+                const _StepPill(
+                  index: 1,
+                  label: 'Base',
+                  active: false,
+                  complete: true,
+                ),
+                const _StepArrow(),
+                const _StepPill(
+                  index: 2,
+                  label: 'Motif du centre',
+                  active: true,
+                ),
+                const _StepArrow(),
+                _StepPill(
+                  index: 3,
+                  label: 'Aperçu',
+                  active: false,
+                  complete: status == PathPatternPresetReadinessStatus.ready,
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
+class _StepPill extends StatelessWidget {
+  const _StepPill({
+    required this.index,
+    required this.label,
+    required this.active,
+    this.complete = false,
+  });
+
+  final int index;
+  final String label;
+  final bool active;
+  final bool complete;
+
+  @override
+  Widget build(BuildContext context) {
+    final color = active
+        ? PathStudioTheme.accentHover
+        : complete
+            ? PathStudioTheme.success
+            : PathStudioTheme.textMuted;
+    return Container(
+      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
+      decoration: BoxDecoration(
+        color: color.withValues(alpha: active ? 0.2 : 0.11),
+        borderRadius: BorderRadius.circular(999),
+        border: Border.all(color: color.withValues(alpha: 0.45)),
+      ),
+      child: Row(
+        mainAxisSize: MainAxisSize.min,
+        children: [
+          Container(
+            width: 22,
+            height: 22,
+            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
+            alignment: Alignment.center,
+            child: Text(
+              complete ? '✓' : '$index',
+              style: const TextStyle(
+                color: CupertinoColors.white,
+                fontSize: 11,
+                fontWeight: FontWeight.w900,
+              ),
+            ),
+          ),
+          const SizedBox(width: 8),
+          Text(
+            label,
+            style: TextStyle(
+              color: active ? PathStudioTheme.textPrimary : color,
+              fontSize: 12,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _StepArrow extends StatelessWidget {
+  const _StepArrow();
+
+  @override
+  Widget build(BuildContext context) {
+    return const Padding(
+      padding: EdgeInsets.only(top: 10),
+      child: MacosIcon(
+        CupertinoIcons.chevron_right,
+        size: 13,
+        color: PathStudioTheme.textMuted,
+      ),
+    );
+  }
+}
+
+class _SelectedSummary extends StatelessWidget {
+  const _SelectedSummary({required this.card});
+
+  final PathPatternPresetCardModel card;
+
+  @override
+  Widget build(BuildContext context) {
+    final status = _statusPresentation(card.status);
+    return _SectionCard(
+      title: 'Résumé du preset',
+      icon: CupertinoIcons.doc_text,
+      trailing: _StatusChip(label: status.label, color: status.color),
+      child: Wrap(
+        spacing: 10,
+        runSpacing: 10,
+        children: [
+          _InfoTile(label: 'Nom', value: card.name),
+          _InfoTile(
+              label: 'Base', value: card.basePathPresetName ?? 'Introuvable'),
+          _InfoTile(label: 'Centre', value: card.centerPatternLabel),
+          _InfoTile(label: 'Cellules', value: '${card.centerCellCount}'),
+          _InfoTile(label: 'Frames', value: '${card.centerFrameCount}'),
+          _InfoTile(
+              label: 'Animation', value: '${card.animatedCellCount} cellules'),
+          _InfoTile(
+            label: 'Transparent',
+            value: card.transparentColorHex ?? 'Absent',
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _CenterPatternPlaceholder extends StatelessWidget {
+  const _CenterPatternPlaceholder({required this.card});
+
+  final PathPatternPresetCardModel card;
+
+  @override
+  Widget build(BuildContext context) {
+    return _SectionCard(
+      title: 'Motif du centre',
+      icon: CupertinoIcons.square_grid_2x2,
+      child: Row(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          _MiniPatternGrid(card: card),
+          const SizedBox(width: 18),
+          const Expanded(
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Text(
+                  'Éditeur read-only',
+                  style: TextStyle(
+                    color: PathStudioTheme.textPrimary,
+                    fontSize: 15,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+                SizedBox(height: 8),
+                Text(
+                  'L’édition 1×1 / 2×2 arrivera au lot 14. Cette zone pose seulement la structure du futur espace de travail, sans drag & drop ni génération PNG.',
+                  style: TextStyle(
+                    color: PathStudioTheme.textSecondary,
+                    fontSize: 13,
+                    height: 1.4,
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
+class _MiniPatternGrid extends StatelessWidget {
+  const _MiniPatternGrid({required this.card});
+
+  final PathPatternPresetCardModel card;
+
+  @override
+  Widget build(BuildContext context) {
+    final rows = <Widget>[];
+    var labelCode = 'A'.codeUnitAt(0);
+    for (var y = 0; y < card.centerHeight; y += 1) {
+      final cells = <Widget>[];
+      for (var x = 0; x < card.centerWidth; x += 1) {
+        cells.add(_PatternCell(label: String.fromCharCode(labelCode)));
+        labelCode += 1;
+      }
+      rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
+    }
+    return Container(
+      padding: const EdgeInsets.all(10),
+      decoration: PathStudioTheme.subtleDecoration(
+        color: PathStudioTheme.backgroundAlt,
+      ),
+      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
+    );
+  }
+}
+
+class _PatternCell extends StatelessWidget {
+  const _PatternCell({required this.label});
+
+  final String label;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      width: 54,
+      height: 54,
+      margin: const EdgeInsets.all(4),
+      decoration: BoxDecoration(
+        color: Color.lerp(
+          PathStudioTheme.surfaceStrong,
+          PathStudioTheme.accentCyan,
+          0.18,
+        ),
+        borderRadius: BorderRadius.circular(12),
+        border: Border.all(
+            color: PathStudioTheme.accentCyan.withValues(alpha: 0.5)),
+      ),
+      alignment: Alignment.center,
+      child: Text(
+        label,
+        style: const TextStyle(
+          color: PathStudioTheme.textPrimary,
+          fontSize: 16,
+          fontWeight: FontWeight.w900,
+        ),
+      ),
+    );
+  }
+}
+
+class _DiagnosticsCard extends StatelessWidget {
+  const _DiagnosticsCard({required this.card});
+
+  final PathPatternPresetCardModel card;
+
+  @override
+  Widget build(BuildContext context) {
+    final issues = card.issues;
+    return _SectionCard(
+      title: 'Diagnostics',
+      icon: CupertinoIcons.check_mark_circled,
+      child: issues.isEmpty
+          ? const _DiagnosticRow(
+              icon: CupertinoIcons.check_mark_circled_solid,
+              color: PathStudioTheme.success,
+              title: 'Aucune erreur',
+              message: 'Le preset est valide pour le shell V0.',
+            )
+          : Column(
+              crossAxisAlignment: CrossAxisAlignment.stretch,
+              children: issues
+                  .map(
+                    (issue) => Padding(
+                      padding: const EdgeInsets.only(bottom: 8),
+                      child: _DiagnosticRow(
+                        icon: CupertinoIcons.exclamationmark_triangle_fill,
+                        color: PathStudioTheme.error,
+                        title: _issueLabel(issue),
+                        message: _issueDescription(issue),
+                      ),
+                    ),
+                  )
+                  .toList(growable: false),
+            ),
+    );
+  }
+}
+
+class _PresetInspector extends StatelessWidget {
+  const _PresetInspector({required this.selected});
+
+  final PathPatternPresetCardModel? selected;
+
+  @override
+  Widget build(BuildContext context) {
+    final card = selected;
+    return Container(
+      decoration: PathStudioTheme.panelDecoration(),
+      padding: const EdgeInsets.all(16),
+      child: card == null
+          ? const _InspectorEmptyState()
+          : SingleChildScrollView(
+              child: Column(
+                crossAxisAlignment: CrossAxisAlignment.stretch,
+                children: [
+                  const Text(
+                    'Propriétés du preset',
+                    style: TextStyle(
+                      color: PathStudioTheme.textPrimary,
+                      fontSize: 16,
+                      fontWeight: FontWeight.w800,
+                    ),
+                  ),
+                  const SizedBox(height: 14),
+                  _InspectorRow(label: 'Nom', value: card.name),
+                  _InspectorRow(label: 'ID', value: card.id),
+                  _InspectorRow(
+                    label: 'Base path preset id',
+                    value: card.basePathPresetId,
+                  ),
+                  _InspectorRow(
+                      label: 'Preset de base',
+                      value: card.basePathPresetName ?? 'Introuvable'),
+                  _InspectorRow(
+                      label: 'Surface',
+                      value: card.basePathSurfaceKindLabel ?? 'Non disponible'),
+                  _InspectorRow(
+                      label: 'Taille centre', value: card.centerPatternLabel),
+                  _InspectorRow(
+                      label: 'Cellules', value: '${card.centerCellCount}'),
+                  _InspectorRow(
+                      label: 'Frames', value: '${card.centerFrameCount}'),
+                  _InspectorRow(
+                      label: 'Cellules animées',
+                      value: '${card.animatedCellCount}'),
+                  _InspectorRow(
+                      label: 'Transparent color',
+                      value: card.transparentColorHex ?? 'Aucune'),
+                  const SizedBox(height: 14),
+                  _DiagnosticsCard(card: card),
+                ],
+              ),
+            ),
+    );
+  }
+}
+
+class _InspectorEmptyState extends StatelessWidget {
+  const _InspectorEmptyState();
+
+  @override
+  Widget build(BuildContext context) {
+    return const Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        Text(
+          'Propriétés du preset',
+          style: TextStyle(
+            color: PathStudioTheme.textPrimary,
+            fontSize: 16,
+            fontWeight: FontWeight.w800,
+          ),
+        ),
+        SizedBox(height: 18),
+        _SidebarNotice(
+          title: 'Aucun preset sélectionné',
+          message: 'Les détails s’afficheront ici après sélection.',
+        ),
+      ],
+    );
+  }
+}
+
+class _SectionCard extends StatelessWidget {
+  const _SectionCard({
+    required this.title,
+    required this.icon,
+    required this.child,
+    this.trailing,
+  });
+
+  final String title;
+  final IconData icon;
+  final Widget child;
+  final Widget? trailing;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      decoration: PathStudioTheme.panelDecoration(
+        color: PathStudioTheme.surface,
+        radius: 20,
+      ),
+      padding: const EdgeInsets.all(16),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Row(
+            children: [
+              MacosIcon(icon, color: PathStudioTheme.accentCyan, size: 18),
+              const SizedBox(width: 9),
+              Expanded(
+                child: Text(
+                  title,
+                  style: const TextStyle(
+                    color: PathStudioTheme.textPrimary,
+                    fontSize: 15,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+              ),
+              if (trailing != null) trailing!,
+            ],
+          ),
+          const SizedBox(height: 14),
+          child,
+        ],
+      ),
+    );
+  }
+}
+
+class _InfoTile extends StatelessWidget {
+  const _InfoTile({
+    required this.label,
+    required this.value,
+  });
+
+  final String label;
+  final String value;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      width: 138,
+      padding: const EdgeInsets.all(12),
+      decoration: PathStudioTheme.subtleDecoration(),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Text(
+            label,
+            style: const TextStyle(
+              color: PathStudioTheme.textMuted,
+              fontSize: 10,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 5),
+          Text(
+            value,
+            maxLines: 1,
+            overflow: TextOverflow.ellipsis,
+            style: const TextStyle(
+              color: PathStudioTheme.textPrimary,
+              fontSize: 13,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _InspectorRow extends StatelessWidget {
+  const _InspectorRow({
+    required this.label,
+    required this.value,
+  });
+
+  final String label;
+  final String value;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      margin: const EdgeInsets.only(bottom: 10),
+      padding: const EdgeInsets.all(12),
+      decoration: PathStudioTheme.subtleDecoration(
+        color: PathStudioTheme.surfaceRaised,
+        radius: 14,
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Text(
+            label,
+            style: const TextStyle(
+              color: PathStudioTheme.textMuted,
+              fontSize: 10,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 6),
+          Text(
+            value,
+            style: const TextStyle(
+              color: PathStudioTheme.textPrimary,
+              fontSize: 12.5,
+              fontWeight: FontWeight.w700,
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _DiagnosticRow extends StatelessWidget {
+  const _DiagnosticRow({
+    required this.icon,
+    required this.color,
+    required this.title,
+    required this.message,
+  });
+
+  final IconData icon;
+  final Color color;
+  final String title;
+  final String message;
+
+  @override
+  Widget build(BuildContext context) {
+    return Container(
+      padding: const EdgeInsets.all(12),
+      decoration: BoxDecoration(
+        color: color.withValues(alpha: 0.1),
+        borderRadius: BorderRadius.circular(14),
+        border: Border.all(color: color.withValues(alpha: 0.35)),
+      ),
+      child: Row(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          MacosIcon(icon, color: color, size: 18),
+          const SizedBox(width: 10),
+          Expanded(
+            child: Column(
+              crossAxisAlignment: CrossAxisAlignment.start,
+              children: [
+                Text(
+                  title,
+                  style: TextStyle(
+                    color: color,
+                    fontSize: 12.5,
+                    fontWeight: FontWeight.w800,
+                  ),
+                ),
+                const SizedBox(height: 3),
+                Text(
+                  message,
+                  style: const TextStyle(
+                    color: PathStudioTheme.textSecondary,
+                    fontSize: 11.5,
+                    height: 1.3,
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
+_StatusPresentation _statusPresentation(
+  PathPatternPresetReadinessStatus status,
+) {
+  return switch (status) {
+    PathPatternPresetReadinessStatus.ready => const _StatusPresentation(
+        label: 'Prêt',
+        color: PathStudioTheme.success,
+      ),
+    PathPatternPresetReadinessStatus.needsReview => const _StatusPresentation(
+        label: 'À vérifier',
+        color: PathStudioTheme.warning,
+      ),
+    PathPatternPresetReadinessStatus.blocked => const _StatusPresentation(
+        label: 'Bloqué',
+        color: PathStudioTheme.error,
+      ),
+  };
+}
+
+class _StatusPresentation {
+  const _StatusPresentation({
+    required this.label,
+    required this.color,
+  });
+
+  final String label;
+  final Color color;
+}
+
+String _issueLabel(PathPatternPresetIssueCode issue) {
+  return switch (issue) {
+    PathPatternPresetIssueCode.missingBasePathPreset =>
+      'Preset de base introuvable',
+    PathPatternPresetIssueCode.duplicatePathPatternId =>
+      'ID PathPattern dupliqué',
+    PathPatternPresetIssueCode.duplicateBasePathPresetId =>
+      'Preset de base dupliqué',
+  };
+}
+
+String _issueDescription(PathPatternPresetIssueCode issue) {
+  return switch (issue) {
+    PathPatternPresetIssueCode.missingBasePathPreset =>
+      'Le preset référence un basePathPresetId absent du manifest.',
+    PathPatternPresetIssueCode.duplicatePathPatternId =>
+      'Plusieurs PathPattern partagent exactement le même id.',
+    PathPatternPresetIssueCode.duplicateBasePathPresetId =>
+      'Plusieurs ProjectPathPreset legacy correspondent à la même base.',
+  };
+}
```

#### packages/map_editor/lib/src/features/path_studio/path_studio_theme.dart

```text
--- /dev/null	2026-04-30 19:55:25
+++ packages/map_editor/lib/src/features/path_studio/path_studio_theme.dart	2026-04-30 19:29:37
@@ -0,0 +1,78 @@
+import 'package:flutter/cupertino.dart';
+
+/// Tokens visuels locaux au Path Studio.
+///
+/// Le lot 13 pose une direction dark mode identifiable sans transformer le
+/// thème global de `map_editor`. Ces couleurs restent donc volontairement
+/// privées à la feature Path Studio : les futurs lots pourront les promouvoir
+/// si plusieurs studios finissent par partager exactement cette DA.
+abstract final class PathStudioTheme {
+  static const Color background = Color(0xFF171523);
+  static const Color backgroundAlt = Color(0xFF191726);
+  static const Color surface = Color(0xFF211F31);
+  static const Color surfaceRaised = Color(0xFF26233A);
+  static const Color surfaceStrong = Color(0xFF2B2840);
+  static const Color border = Color(0xFF3A3654);
+  static const Color borderStrong = Color(0xFF514B70);
+  static const Color textPrimary = Color(0xFFF4F2FF);
+  static const Color textSecondary = Color(0xFFB8B3D3);
+  static const Color textMuted = Color(0xFF8F89AE);
+  static const Color accent = Color(0xFF4E8CFF);
+  static const Color accentHover = Color(0xFF6BA4FF);
+  static const Color accentCyan = Color(0xFF3ECFCD);
+  static const Color success = Color(0xFF4CC38A);
+  static const Color warning = Color(0xFFF2B84B);
+  static const Color error = Color(0xFFF06A6A);
+
+  static const LinearGradient backgroundGradient = LinearGradient(
+    begin: Alignment.topLeft,
+    end: Alignment.bottomRight,
+    colors: [
+      background,
+      backgroundAlt,
+      Color(0xFF141221),
+    ],
+  );
+
+  /// Ombre courte et sobre : le shell doit avoir du relief, mais rester un
+  /// outil de travail dense plutôt qu'une landing page décorative.
+  static List<BoxShadow> panelShadow() {
+    return const [
+      BoxShadow(
+        color: Color(0x73000000),
+        blurRadius: 0,
+        offset: Offset(0, 2),
+      ),
+      BoxShadow(
+        color: Color(0x33000000),
+        blurRadius: 10,
+        offset: Offset(0, 8),
+      ),
+    ];
+  }
+
+  static BoxDecoration panelDecoration({
+    Color color = surface,
+    Color borderColor = border,
+    double radius = 22,
+  }) {
+    return BoxDecoration(
+      color: color,
+      borderRadius: BorderRadius.circular(radius),
+      border: Border.all(color: borderColor),
+      boxShadow: panelShadow(),
+    );
+  }
+
+  static BoxDecoration subtleDecoration({
+    Color color = surfaceRaised,
+    Color borderColor = border,
+    double radius = 16,
+  }) {
+    return BoxDecoration(
+      color: color,
+      borderRadius: BorderRadius.circular(radius),
+      border: Border.all(color: borderColor.withValues(alpha: 0.84)),
+    );
+  }
+}
```

#### packages/map_editor/test/path_pattern/path_studio_panel_test.dart

```text
--- /dev/null	2026-04-30 19:55:25
+++ packages/map_editor/test/path_pattern/path_studio_panel_test.dart	2026-04-30 19:36:10
@@ -0,0 +1,223 @@
+import 'package:flutter/cupertino.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:macos_ui/macos_ui.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/path_studio/path_studio_panel.dart';
+
+void main() {
+  group('PathStudioPanel', () {
+    testWidgets('renders a dark empty state when no PathPattern preset exists',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(),
+      );
+
+      expect(find.text('Path Studio'), findsOneWidget);
+      expect(find.text('Créer des motifs de chemin'), findsOneWidget);
+      expect(find.text('Aucun motif PathPattern'), findsWidgets);
+      expect(find.text('Aucun preset sélectionné'), findsOneWidget);
+      expect(find.text('Propriétés du preset'), findsOneWidget);
+    });
+
+    testWidgets('lists presets and updates summary and inspector selection',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          pathPresets: [
+            _legacyPathPreset(id: 'legacy-water', name: 'Base eau'),
+          ],
+          pathPatternPresets: [
+            _pathPatternPreset(
+              id: 'water-sea-2x2',
+              name: 'Mer 2x2',
+              pattern: _twoByTwoPattern(animatedTopLeft: true),
+              transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
+            ),
+            _pathPatternPreset(
+              id: 'sand-broken',
+              name: 'Sable cassé',
+              basePathPresetId: 'missing-base',
+            ),
+          ],
+        ),
+      );
+
+      expect(find.text('Mer 2x2'), findsWidgets);
+      expect(find.text('Sable cassé'), findsOneWidget);
+      expect(find.text('Prêt'), findsWidgets);
+      expect(find.text('2×2'), findsWidgets);
+      expect(find.text('water-sea-2x2'), findsWidgets);
+      expect(find.text('f05ba1'), findsWidgets);
+
+      await tester.tap(find.text('Sable cassé'));
+      await tester.pumpAndSettle();
+
+      expect(find.text('missing-base'), findsWidgets);
+      expect(find.text('Bloqué'), findsWidgets);
+      expect(find.text('Preset de base introuvable'), findsWidgets);
+    });
+
+    testWidgets('filters presets locally and clears selection on no result',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          pathPresets: [
+            _legacyPathPreset(id: 'legacy-water'),
+          ],
+          pathPatternPresets: [
+            _pathPatternPreset(id: 'water-sea', name: 'Mer profonde'),
+            _pathPatternPreset(id: 'stone-road', name: 'Route pavée'),
+          ],
+        ),
+      );
+
+      await tester.enterText(
+        find.byKey(const Key('path-studio-search-field')),
+        'pavée',
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.text('Route pavée'), findsWidgets);
+      expect(find.text('Mer profonde'), findsNothing);
+      expect(find.text('stone-road'), findsWidgets);
+
+      await tester.enterText(
+        find.byKey(const Key('path-studio-search-field')),
+        'zzz',
+      );
+      await tester.pumpAndSettle();
+
+      expect(find.text('Aucun preset trouvé'), findsOneWidget);
+      expect(find.text('Aucun preset sélectionné'), findsWidgets);
+    });
+
+    testWidgets('shows shell actions as visibly disabled placeholders',
+        (tester) async {
+      await _pumpPathStudio(
+        tester,
+        manifest: _manifest(
+          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
+          pathPatternPresets: [_pathPatternPreset(id: 'water')],
+        ),
+      );
+
+      final newPresetButton = tester.widget<CupertinoButton>(
+        find.widgetWithText(CupertinoButton, 'Nouveau preset'),
+      );
+      final duplicateButton = tester.widget<CupertinoButton>(
+        find.widgetWithText(CupertinoButton, 'Dupliquer'),
+      );
+      final saveButton = tester.widget<CupertinoButton>(
+        find.widgetWithText(CupertinoButton, 'Enregistrer'),
+      );
+
+      expect(newPresetButton.onPressed, isNull);
+      expect(duplicateButton.onPressed, isNull);
+      expect(saveButton.onPressed, isNull);
+      expect(find.text('lot futur'), findsWidgets);
+    });
+  });
+}
+
+Future<void> _pumpPathStudio(
+  WidgetTester tester, {
+  required ProjectManifest manifest,
+}) async {
+  await tester.binding.setSurfaceSize(const Size(1440, 920));
+  addTearDown(() => tester.binding.setSurfaceSize(null));
+
+  await tester.pumpWidget(
+    MacosApp(
+      theme: MacosThemeData.dark(),
+      home: MacosScaffold(
+        children: [
+          ContentArea(
+            builder: (context, scrollController) {
+              return PathStudioPanel(manifest: manifest);
+            },
+          ),
+        ],
+      ),
+    ),
+  );
+  await tester.pumpAndSettle();
+}
+
+ProjectManifest _manifest({
+  List<ProjectPathPreset> pathPresets = const [],
+  List<ProjectPathPatternPreset> pathPatternPresets = const [],
+}) {
+  return ProjectManifest(
+    name: 'Project',
+    maps: const [],
+    tilesets: const [],
+    pathPresets: pathPresets,
+    pathPatternPresets: pathPatternPresets,
+    surfaceCatalog: ProjectSurfaceCatalog(),
+  );
+}
+
+ProjectPathPreset _legacyPathPreset({
+  required String id,
+  String name = 'Legacy Water',
+}) {
+  return ProjectPathPreset(
+    id: id,
+    name: name,
+    surfaceKind: PathSurfaceKind.water,
+  );
+}
+
+ProjectPathPatternPreset _pathPatternPreset({
+  required String id,
+  String? name,
+  String basePathPresetId = 'legacy-water',
+  PathCenterPattern? pattern,
+  TilesetTransparentColor? transparentColor,
+}) {
+  return ProjectPathPatternPreset(
+    id: id,
+    name: name ?? id,
+    basePathPresetId: basePathPresetId,
+    centerPattern: pattern ?? _singleCellPattern(),
+    transparentColor: transparentColor,
+  );
+}
+
+PathCenterPattern _singleCellPattern() {
+  return PathCenterPattern(
+    size: PathCenterPatternSize(width: 1, height: 1),
+    cells: [
+      PathCenterPatternCell(
+        localX: 0,
+        localY: 0,
+        frames: [_frame(0)],
+      ),
+    ],
+  );
+}
+
+PathCenterPattern _twoByTwoPattern({bool animatedTopLeft = false}) {
+  return PathCenterPattern(
+    size: PathCenterPatternSize(width: 2, height: 2),
+    cells: [
+      PathCenterPatternCell(
+        localX: 0,
+        localY: 0,
+        frames: animatedTopLeft ? [_frame(0), _frame(1)] : [_frame(0)],
+      ),
+      PathCenterPatternCell(localX: 1, localY: 0, frames: [_frame(2)]),
+      PathCenterPatternCell(localX: 0, localY: 1, frames: [_frame(3)]),
+      PathCenterPatternCell(localX: 1, localY: 1, frames: [_frame(4)]),
+    ],
+  );
+}
+
+TilesetVisualFrame _frame(int sourceX) {
+  return TilesetVisualFrame(
+    source: TilesetSourceRect(x: sourceX, y: 0),
+  );
+}
```

### 9.4 Contenu complet des fichiers créés

#### packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../editor/state/editor_selectors.dart';
import 'path_pattern_editor_read_model.dart';
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final readModel = createPathPatternEditorReadModel(
      manifest: widget.manifest,
    );
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _filteredCards(readModel, query);
    final selected = _selectedCard(filtered);

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
                      selectedSourceIndex: selected?.sourceIndex,
                      onQueryChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      onSelect: (sourceIndex) {
                        setState(() => _selectedSourceIndex = sourceIndex);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _CenterWorkspace(
                      selected: selected?.card,
                      hasAnyPreset: readModel.presets.isNotEmpty,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 326,
                    child: _PresetInspector(selected: selected?.card),
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
  });

  final PathPatternEditorSummary summary;

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
          _SummaryPill(label: 'Presets', value: '${summary.totalCount}'),
          const SizedBox(width: 8),
          _SummaryPill(label: 'Prêts', value: '${summary.readyCount}'),
          const SizedBox(width: 12),
          const _ShellActionButton(
            icon: CupertinoIcons.plus,
            label: 'Nouveau preset',
          ),
          const SizedBox(width: 8),
          const _ShellActionButton(
            icon: CupertinoIcons.square_on_square,
            label: 'Dupliquer',
          ),
          const SizedBox(width: 8),
          const _ShellActionButton(
            icon: CupertinoIcons.floppy_disk,
            label: 'Enregistrer',
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
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      minimumSize: Size.zero,
      onPressed: null,
      disabledColor: PathStudioTheme.surfaceRaised.withValues(alpha: 0.72),
      color: PathStudioTheme.accent,
      borderRadius: BorderRadius.circular(13),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MacosIcon(
            icon,
            color: PathStudioTheme.textMuted.withValues(alpha: 0.72),
            size: 15,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: PathStudioTheme.textSecondary.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'lot futur',
                style: TextStyle(
                  color: PathStudioTheme.textMuted,
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
    required this.selectedSourceIndex,
    required this.onQueryChanged,
    required this.onSelect,
  });

  final PathPatternEditorReadModel readModel;
  final List<_IndexedPresetCard> filteredCards;
  final int? selectedSourceIndex;
  final ValueChanged<String> onQueryChanged;
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
    if (readModel.presets.isEmpty) {
      return const _SidebarNotice(
        title: 'Aucun motif PathPattern',
        message: 'Les presets apparaîtront ici après le lot création.',
      );
    }
    if (filteredCards.isEmpty) {
      return const _SidebarNotice(
        title: 'Aucun preset trouvé',
        message: 'Essayez un autre nom, id ou preset de base.',
      );
    }
    return ListView.separated(
      itemCount: filteredCards.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = filteredCards[index];
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
    required this.selected,
    required this.hasAnyPreset,
  });

  final PathPatternPresetCardModel? selected;
  final bool hasAnyPreset;

  @override
  Widget build(BuildContext context) {
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
  const _PresetInspector({required this.selected});

  final PathPatternPresetCardModel? selected;

  @override
  Widget build(BuildContext context) {
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
```

#### packages/map_editor/lib/src/features/path_studio/path_studio_theme.dart

```dart
import 'package:flutter/cupertino.dart';

/// Tokens visuels locaux au Path Studio.
///
/// Le lot 13 pose une direction dark mode identifiable sans transformer le
/// thème global de `map_editor`. Ces couleurs restent donc volontairement
/// privées à la feature Path Studio : les futurs lots pourront les promouvoir
/// si plusieurs studios finissent par partager exactement cette DA.
abstract final class PathStudioTheme {
  static const Color background = Color(0xFF171523);
  static const Color backgroundAlt = Color(0xFF191726);
  static const Color surface = Color(0xFF211F31);
  static const Color surfaceRaised = Color(0xFF26233A);
  static const Color surfaceStrong = Color(0xFF2B2840);
  static const Color border = Color(0xFF3A3654);
  static const Color borderStrong = Color(0xFF514B70);
  static const Color textPrimary = Color(0xFFF4F2FF);
  static const Color textSecondary = Color(0xFFB8B3D3);
  static const Color textMuted = Color(0xFF8F89AE);
  static const Color accent = Color(0xFF4E8CFF);
  static const Color accentHover = Color(0xFF6BA4FF);
  static const Color accentCyan = Color(0xFF3ECFCD);
  static const Color success = Color(0xFF4CC38A);
  static const Color warning = Color(0xFFF2B84B);
  static const Color error = Color(0xFFF06A6A);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      background,
      backgroundAlt,
      Color(0xFF141221),
    ],
  );

  /// Ombre courte et sobre : le shell doit avoir du relief, mais rester un
  /// outil de travail dense plutôt qu'une landing page décorative.
  static List<BoxShadow> panelShadow() {
    return const [
      BoxShadow(
        color: Color(0x73000000),
        blurRadius: 0,
        offset: Offset(0, 2),
      ),
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 10,
        offset: Offset(0, 8),
      ),
    ];
  }

  static BoxDecoration panelDecoration({
    Color color = surface,
    Color borderColor = border,
    double radius = 22,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: panelShadow(),
    );
  }

  static BoxDecoration subtleDecoration({
    Color color = surfaceRaised,
    Color borderColor = border,
    double radius = 16,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor.withValues(alpha: 0.84)),
    );
  }
}
```

#### packages/map_editor/test/path_pattern/path_studio_panel_test.dart

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

    testWidgets('shows shell actions as visibly disabled placeholders',
        (tester) async {
      await _pumpPathStudio(
        tester,
        manifest: _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [_pathPatternPreset(id: 'water')],
        ),
      );

      final newPresetButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Nouveau preset'),
      );
      final duplicateButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Dupliquer'),
      );
      final saveButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Enregistrer'),
      );

      expect(newPresetButton.onPressed, isNull);
      expect(duplicateButton.onPressed, isNull);
      expect(saveButton.onPressed, isNull);
      expect(find.text('lot futur'), findsWidgets);
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

ProjectManifest _manifest({
  List<ProjectPathPreset> pathPresets = const [],
  List<ProjectPathPatternPreset> pathPatternPresets = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectPathPreset _legacyPathPreset({
  required String id,
  String name = 'Legacy Water',
}) {
  return ProjectPathPreset(
    id: id,
    name: name,
    surfaceKind: PathSurfaceKind.water,
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

### 9.5 Contenu complet des fichiers modifiés

#### packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart

```dart
import '../state/editor_state.dart';

/// Routeur pur des workspaces centraux de l'éditeur.
///
/// Pourquoi cette classe existe :
/// - `EditorNotifier` n'a pas besoin de porter lui-même tous les changements
///   de mode "simples" ;
/// - ces transitions ne lisent ni le disque ni Riverpod ;
/// - cela prépare un notifier plus fin, sans recréer un second store.
///
/// Frontière volontaire :
/// - on ne gère ici que les bascules de workspace triviales ;
/// - `selectTilesetWorkspace` reste dans le notifier, car il valide un id et
///   réinitialise un contexte spécifique tileset.
class EditorWorkspaceController {
  const EditorWorkspaceController();

  EditorState selectMapWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.map);
  }

  EditorState selectPokedexWorkspace(EditorState current) {
    return _openWorkspace(
      current.copyWith(
        pokemonCatalogSection: PokemonCatalogSection.pokedex,
      ),
      EditorWorkspaceMode.pokedex,
    );
  }

  EditorState selectPokemonCatalogSection(
    EditorState current,
    PokemonCatalogSection section,
  ) {
    return _openWorkspace(
      current.copyWith(pokemonCatalogSection: section),
      EditorWorkspaceMode.pokedex,
    );
  }

  EditorState selectTrainerWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.trainer);
  }

  EditorState selectGlobalStoryWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.globalStory);
  }

  EditorState selectStepWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.step);
  }

  EditorState selectCutsceneWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.cutscene);
  }

  EditorState selectDialogueWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.dialogue);
  }

  EditorState selectPathStudioWorkspace(EditorState current) {
    return _openWorkspace(current, EditorWorkspaceMode.pathStudio);
  }

  /// Normalise les transitions de workspace :
  /// - on conserve tout l'état métier courant ;
  /// - on bascule seulement la surface centrale active ;
  /// - on efface l'erreur courante pour éviter de laisser un message obsolète
  ///   d'un autre workflow polluer le nouvel espace.
  EditorState _openWorkspace(
    EditorState current,
    EditorWorkspaceMode workspaceMode,
  ) {
    return current
        .copyWithProjectSession(
          current.projectSession.copyWith(workspaceMode: workspaceMode),
        )
        .copyWithDocumentStatus(
          current.documentStatus.copyWith(errorMessage: null),
        );
  }
}
```

#### packages/map_editor/lib/src/features/editor/state/editor_notifier.dart

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/content_studio_providers.dart';
import '../../../app/providers/core_providers.dart';
import '../../../app/providers/editor_workspace_providers.dart';
import '../../../app/providers/use_case_providers.dart';
import '../../../application/errors/application_errors.dart';
import '../../../application/models/trainer_field_update.dart';
import '../../../application/models/map_tool_preview.dart';
import '../../../application/models/path_autotile_set.dart';
import '../../../application/ports/project_workspace.dart';
import '../../../application/services/editor_map_session_coordinator.dart';
import '../../../application/services/editor_map_mutation_coordinator.dart';
import '../../../application/services/element_collision_profile_generator.dart';
import '../../../application/services/entity_editing_service.dart';
import '../../../application/services/gameplay_zone_editing_service.dart';
import '../../../application/services/map_connection_editing_service.dart';
import '../../../application/services/path_autotile_resolver.dart';
import '../../../application/services/path_layer_editing_coordinator.dart';
import '../../../application/services/placed_element_instance_indexer.dart';
import '../../../application/services/terrain_painting_coordinator.dart';
import '../../../application/services/terrain_preset_resolver.dart';
import '../../../application/services/terrain_preset_selection_coordinator.dart';
import '../../../application/services/trigger_editing_service.dart';
import '../../../application/services/warp_editing_service.dart';
import '../application/editor_workspace_controller.dart';
import '../application/map_editing_controller.dart';
import '../application/map_selection_controller.dart';
import '../application/project_content_controller.dart';
import '../application/project_session_controller.dart';
import '../application/project_session_models.dart';
import '../tools/editor_tool.dart';
import 'editor_state.dart';
import '../../surface_painter/surface_painting_controller.dart';

part 'editor_notifier.g.dart';

/// Valeur sentinelle pour les paramètres optionnels nullable dans [EditorNotifier].
const Object _trainerUnset = Object();
const String _lastOpenedProjectManifestKey = 'lastOpenedProjectManifestPath';
const String _editorSessionFileName = 'editor_session_state.json';
const MethodChannel _macOsFileAccessChannel =
    MethodChannel('map_editor/file_access');

@riverpod
class EditorNotifier extends _$EditorNotifier {
  EditorWorkspaceController get _editorWorkspaceController =>
      ref.read(editorWorkspaceControllerProvider);
  MapEditingController get _mapEditingController => MapEditingController(
        mutationCoordinator: _editorMapMutationCoordinator,
      );
  MapSelectionController get _mapSelectionController => MapSelectionController(
        terrainPresetSelectionCoordinator: _terrainPresetSelectionCoordinator,
      );
  ProjectContentController get _projectContentController =>
      ref.read(projectContentControllerProvider);
  ProjectSessionController get _projectSessionController =>
      const ProjectSessionController();
  TerrainPresetResolver get _terrainPresetResolver =>
      ref.read(terrainPresetResolverProvider);
  TerrainPresetSelectionCoordinator get _terrainPresetSelectionCoordinator =>
      ref.read(terrainPresetSelectionCoordinatorProvider);
  PathAutotileResolver get _pathAutotileResolver =>
      ref.read(pathAutotileResolverProvider);
  EditorMapSessionCoordinator get _editorMapSessionCoordinator =>
      ref.read(editorMapSessionCoordinatorProvider);
  EditorMapMutationCoordinator get _editorMapMutationCoordinator =>
      ref.read(editorMapMutationCoordinatorProvider);
  ProjectWorkspaceFactory get _projectWorkspaceFactory =>
      ref.read(projectWorkspaceFactoryProvider);
  ProjectWorkspace? get _projectWorkspace {
    final projectRootPath = state.projectSession.projectRootPath;
    if (projectRootPath == null || projectRootPath.trim().isEmpty) {
      return null;
    }
    return _projectWorkspaceFactory.create(projectRootPath);
  }

  WarpEditingService get _warpEditingService =>
      ref.read(warpEditingServiceProvider);
  EntityEditingService get _entityEditingService =>
      ref.read(entityEditingServiceProvider);
  TriggerEditingService get _triggerEditingService =>
      ref.read(triggerEditingServiceProvider);
  GameplayZoneEditingService get _gameplayZoneEditingService =>
      ref.read(gameplayZoneEditingServiceProvider);
  MapConnectionEditingService get _mapConnectionEditingService =>
      ref.read(mapConnectionEditingServiceProvider);
  TerrainPaintingCoordinator get _terrainPaintingCoordinator =>
      ref.read(terrainPaintingCoordinatorProvider);
  PathLayerEditingCoordinator get _pathLayerEditingCoordinator =>
      ref.read(pathLayerEditingCoordinatorProvider);
  SurfacePaintingController get _surfacePaintingController =>
      const SurfacePaintingController();
  ElementCollisionProfileGenerator get _elementCollisionProfileGenerator =>
      ref.read(elementCollisionProfileGeneratorProvider);
  PlacedElementInstanceIndexer get _placedElementInstanceIndexer =>
      ref.read(placedElementInstanceIndexerProvider);

  TerrainPresetSelection _currentTerrainPresetSelection() {
    final selection = state.selection;
    return TerrainPresetSelection(
      selectionMode: selection.terrainSelectionMode,
      selectedTerrainType: selection.selectedTerrainType,
      selectedTerrainPresetId: selection.selectedTerrainPresetId,
      selectedPathPresetId: selection.selectedPathPresetId,
      selectedTerrainPresetByType: selection.selectedTerrainPresetByType,
    );
  }

  EditorState _copyStateWithTerrainPresetSelection(
    EditorState source,
    TerrainPresetSelection selection, {
    String? statusMessage,
    String? errorMessage,
    EditorToolType? activeTool,
  }) {
    return source.copyWith(
      terrainSelectionMode: selection.selectionMode,
      selectedTerrainType: selection.selectedTerrainType,
      selectedTerrainPresetId: selection.selectedTerrainPresetId,
      selectedPathPresetId: selection.selectedPathPresetId,
      selectedTerrainPresetByType: selection.selectedTerrainPresetByType,
      activeTool: activeTool ?? source.activeTool,
      statusMessage: statusMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  EditorState build() {
    return const EditorState();
  }

  /// Returns the persisted manifest path of the most recently opened project.
  ///
  /// This is intentionally tiny and file-based (single JSON file in app support)
  /// to keep startup deterministic and avoid introducing extra dependencies.
  Future<String?> getLastOpenedProjectManifestPath() async {
    try {
      final file = await _sessionStateFile();
      if (!await file.exists()) {
        return null;
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final value = decoded[_lastOpenedProjectManifestKey];
      if (value is! String) {
        return null;
      }
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      // Startup memory should never crash the editor. Any corrupted or
      // unreadable state is treated as "no remembered project".
      return null;
    }
  }

  /// Attempts to load the last opened project (if any).
  ///
  /// Returns true only when a project was actually restored.
  Future<bool> restoreLastOpenedProjectIfAny() async {
    // Do not override an already loaded project.
    if (state.project != null) {
      return false;
    }
    // On macOS sandbox, a plain path is not enough after restart.
    // We first ask native code to resolve a security-scoped bookmark if any.
    final manifestPath = await _resolveLastProjectManifestFromMacOsBookmark() ??
        await getLastOpenedProjectManifestPath();
    if (manifestPath == null) {
      return false;
    }
    if (!await File(manifestPath).exists()) {
      // Clear stale memory so the app won't re-check a dead path forever.
      await _clearLastOpenedProjectMemory();
      return false;
    }
    if (!await _isManifestReadable(manifestPath)) {
      // macOS can report that the path exists but still deny read access
      // (Desktop/Documents permission not granted to the app process).
      //
      // In that case we do NOT call `loadProject`, otherwise we'd surface a
      // noisy PathAccessException on every launch.
      await _clearLastOpenedProjectMemory();
      state = state.copyWith(
        errorMessage: null,
        statusMessage:
            'Dernier projet détecté, mais accès refusé par macOS. Ouvrez-le manuellement pour réautoriser l’accès.',
      );
      return false;
    }
    // Auto-restore must be resilient:
    // - no noisy startup error toast if macOS denies access to remembered path
    //   (common when the path is on Desktop/Documents and the app lost grant).
    // - no endless retry loop on next launch if access is denied.
    await loadProject(
      manifestPath,
      silentOnError: true,
      rememberAsRecent: false,
    );
    final restored = state.project != null;
    if (!restored) {
      // Important anti-loop guard:
      // if we failed to restore (permissions / deleted file / parse error),
      // drop the remembered path so startup stays clean next launch.
      await _clearLastOpenedProjectMemory();
    }
    return restored;
  }

  Future<void> createProject(String name, String directory) async {
    debugPrint('EditorNotifier: createProject($name, $directory)');
    try {
      final useCase = ref.read(createProjectUseCaseProvider);
      final manifest = await useCase.execute(name, directory);
      state = _projectSessionController.openProjectSession(
        current: state,
        session: ProjectSessionLoadResult(
          projectRootPath: directory,
          project: manifest,
          presetSelection: _terrainPresetSelectionCoordinator.initial(manifest),
        ),
        statusMessage: 'Project "$name" created successfully',
      );
      await _rememberLastOpenedProjectManifest(
        p.join(directory, 'project.json'),
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating project: $e');
      state = state.copyWith(errorMessage: 'Failed to create project: $e');
    }
  }

  Future<void> loadProject(
    String manifestPath, {
    bool silentOnError = false,
    bool rememberAsRecent = true,
  }) async {
    // Keep this trace for explicit user actions, but avoid noisy startup logs
    // when running a silent auto-restore attempt.
    if (!silentOnError) {
      debugPrint('EditorNotifier: loadProject($manifestPath)');
    }
    try {
      final useCase = ref.read(loadProjectUseCaseProvider);
      final manifest = await useCase.execute(manifestPath);
      final projectDir = p.dirname(manifestPath);
      state = _projectSessionController.openProjectSession(
        current: state,
        session: ProjectSessionLoadResult(
          projectRootPath: projectDir,
          project: manifest,
          presetSelection: _terrainPresetSelectionCoordinator.initial(manifest),
        ),
        statusMessage: 'Project "${manifest.name}" loaded',
      );
      if (rememberAsRecent) {
        await _rememberLastOpenedProjectManifest(manifestPath);
      }
    } catch (e) {
      if (!silentOnError) {
        debugPrint('EditorNotifier: Error loading project: $e');
      }
      if (silentOnError) {
        // Silent mode is used by startup auto-restore.
        // We intentionally avoid surfacing an intrusive error toast at launch.
        state = state.copyWith(
          errorMessage: null,
          statusMessage:
              'Impossible de rouvrir automatiquement le dernier projet. Ouvrez-le manuellement une fois pour réautoriser l’accès.',
        );
      } else {
        state = state.copyWith(errorMessage: 'Failed to load project: $e');
      }
    }
  }

  Future<bool> _isManifestReadable(String manifestPath) async {
    final file = File(manifestPath);
    try {
      // A tiny read is enough to validate real OS-level authorization.
      // We do not rely only on `exists()` because TCC can still block reads.
      await file.openRead(0, 1).first;
      return true;
    } on FileSystemException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<File> _sessionStateFile() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final editorDir = Directory(
      p.join(appSupportDir.path, 'rpg_map_editor'),
    );
    if (!await editorDir.exists()) {
      await editorDir.create(recursive: true);
    }
    return File(p.join(editorDir.path, _editorSessionFileName));
  }

  Future<void> _rememberLastOpenedProjectManifest(String manifestPath) async {
    try {
      final file = await _sessionStateFile();
      final payload = <String, dynamic>{
        _lastOpenedProjectManifestKey: manifestPath,
      };
      await file.writeAsString(jsonEncode(payload));
      // Also remember a security-scoped bookmark when running on macOS.
      // This is the durable way to re-open a user-selected folder under sandbox.
      await _rememberMacOsProjectBookmark(manifestPath);
    } catch (_) {
      // Non-critical: failing to persist recent project must not block editing.
    }
  }

  Future<void> _clearLastOpenedProjectMemory() async {
    try {
      final file = await _sessionStateFile();
      if (await file.exists()) {
        await file.delete();
      }
      await _clearMacOsProjectBookmark();
    } catch (_) {
      // Best effort cleanup only.
    }
  }

  Future<void> _rememberMacOsProjectBookmark(String manifestPath) async {
    if (!Platform.isMacOS) {
      return;
    }
    try {
      await _macOsFileAccessChannel.invokeMethod<void>(
        'rememberProjectPath',
        <String, dynamic>{'manifestPath': manifestPath},
      );
    } catch (_) {
      // Best effort only: path JSON persistence remains as fallback.
    }
  }

  Future<String?> _resolveLastProjectManifestFromMacOsBookmark() async {
    if (!Platform.isMacOS) {
      return null;
    }
    try {
      final path = await _macOsFileAccessChannel
          .invokeMethod<String>('resolveLastProjectManifestPath');
      if (path == null) {
        return null;
      }
      final trimmed = path.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearMacOsProjectBookmark() async {
    if (!Platform.isMacOS) {
      return;
    }
    try {
      await _macOsFileAccessChannel
          .invokeMethod<void>('clearRememberedProjectPath');
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  Future<void> updateProjectSettings({
    required String name,
    required ProjectSettings settings,
  }) async {
    debugPrint('EditorNotifier: updateProjectSettings()');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(updateProjectSettingsUseCaseProvider);
      final updated =
          await useCase.execute(fs, project, name: name, settings: settings);
      state = state.copyWith(
        project: updated,
        statusMessage: 'Project settings saved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating project settings: $e');
      state = state.copyWith(
        errorMessage: 'Failed to update project settings: $e',
      );
    }
  }

  void applyInMemoryProjectManifest(ProjectManifest manifest) {
    state = state.copyWith(project: manifest);
  }

  Future<bool> saveProjectManifest() async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) {
      state = state.copyWith(
        errorMessage: 'No project open to save.',
      );
      return false;
    }
    debugPrint('EditorNotifier: saveProjectManifest()');
    try {
      await ref.read(projectRepositoryProvider).saveProject(
            project,
            fs.projectManifestPath,
          );
      state = state.copyWith(
        statusMessage: 'Projet sauvegardé via le flux projet existant.',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      debugPrint('EditorNotifier: Error saving project manifest: $e');
      state = state.copyWith(
        errorMessage: 'Failed to save project: $e',
      );
      return false;
    }
  }

  Future<void> saveActiveMap() async {
    endMapStroke();
    final map = state.activeMap;
    final path = state.activeMapPath;
    if (map == null || path == null) return;

    debugPrint('EditorNotifier: saveActiveMap()');
    state = _projectSessionController.markMapSaving(state);

    try {
      final useCase = ref.read(saveMapUseCaseProvider);
      await useCase.execute(
        map,
        path,
        projectDialogueContext: state.project,
      );

      state = _projectSessionController.markMapSaved(
        current: state,
        map: map,
        statusMessage: 'Map "${map.id}" saved',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error saving map: $e');
      state = _projectSessionController.markMapSaveFailed(
        current: state,
        errorMessage: 'Failed to save map: $e',
      );
    }
  }

  Future<void> createMap(String id, int width, int height,
      {String? groupId, MapRole role = MapRole.exterior}) async {
    debugPrint(
        'EditorNotifier: createMap($id, $width, $height) in group $groupId');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(createMapUseCaseProvider);
      final map = await useCase.execute(fs, project, id, width, height,
          groupId: groupId, role: role);
      final presetSelection = _terrainPresetSelectionCoordinator.normalize(
        project: project,
        current: _currentTerrainPresetSelection(),
      );
      final updatedProject = project.copyWith(maps: [
        ...project.maps,
        ProjectMapEntry(
          id: id,
          name: id,
          relativePath: fs.getMapRelativePath(id),
          groupId: groupId,
          role: role,
        )
      ]);
      state = _projectSessionController.openMapDocument(
        current: state.copyWith(project: updatedProject),
        document: MapDocumentLoadResult(
          map: map,
          activeMapPath: fs.getMapPath(id),
          presetSelection: presetSelection,
          selectedTilesetEditorId:
              _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
            map,
          ),
        ),
        statusMessage: 'Map "$id" created successfully',
      );
      _coerceActiveToolIfIncompatibleWithLayer();
    } catch (e) {
      debugPrint('EditorNotifier: Error creating map: $e');
      state = state.copyWith(errorMessage: 'Failed to create map: $e');
    }
  }

  Future<void> loadMap(String relativePath) async {
    debugPrint('EditorNotifier: loadMap($relativePath)');
    final fs = _projectWorkspace;
    if (fs == null) return;

    try {
      final useCase = ref.read(loadMapUseCaseProvider);
      final project = state.project;
      final loadedMap = await useCase.execute(fs, relativePath);
      final map = project == null
          ? loadedMap
          : _placedElementInstanceIndexer.syncAllTileLayers(
              map: loadedMap,
              project: project,
            );
      final presetSelection = project == null
          ? _currentTerrainPresetSelection()
          : _terrainPresetSelectionCoordinator.normalize(
              project: project,
              current: _currentTerrainPresetSelection(),
            );
      final preservedSelectedTilesetEditorId = state.selectedTilesetEditorId;
      final nextSelectedTilesetEditorId =
          preservedSelectedTilesetEditorId != null &&
                  preservedSelectedTilesetEditorId.isNotEmpty &&
                  project != null &&
                  project.tilesets.any(
                    (tileset) => tileset.id == preservedSelectedTilesetEditorId,
                  )
              ? preservedSelectedTilesetEditorId
              : _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
                  map,
                );
      state = _projectSessionController.openMapDocument(
        current: state,
        document: MapDocumentLoadResult(
          map: map,
          activeMapPath: fs.resolveMapPath(relativePath),
          presetSelection: presetSelection,
          selectedTilesetEditorId: nextSelectedTilesetEditorId,
        ),
        statusMessage: 'Map "${map.id}" loaded',
      );
      _coerceActiveToolIfIncompatibleWithLayer();
    } catch (e) {
      debugPrint('EditorNotifier: Error loading map: $e');
      state = state.copyWith(errorMessage: 'Failed to load map: $e');
    }
  }

  /// Charge une "snapshot" de map par id SANS changer la map active.
  ///
  /// Pourquoi cette API existe:
  /// - certains workspaces (ex: Cutscene Studio) doivent proposer des
  ///   dropdowns guidés (PNJ/triggers) pour n'importe quelle map du projet;
  /// - on ne veut pas forcer un changement de contexte utilisateur vers cette
  ///   map juste pour lire ses entités;
  /// - on garde donc une lecture non destructive (read-only) côté éditeur.
  ///
  /// Contrat:
  /// - retourne la `activeMap` si c'est déjà la bonne map (inclut les edits
  ///   non sauvegardés en cours, utile pour une UX cohérente);
  /// - sinon lit le fichier map depuis le disque;
  /// - retourne `null` si le contexte projet est incomplet ou en cas d'erreur.
  Future<MapData?> loadMapSnapshotById(String mapId) async {
    final normalizedMapId = mapId.trim();
    if (normalizedMapId.isEmpty) {
      return null;
    }
    final project = state.project;
    final workspace = _projectWorkspace;
    if (project == null || workspace == null) {
      return null;
    }

    final activeMap = state.activeMap;
    if (activeMap != null && activeMap.id == normalizedMapId) {
      return activeMap;
    }

    ProjectMapEntry? entry;
    for (final mapEntry in project.maps) {
      if (mapEntry.id == normalizedMapId) {
        entry = mapEntry;
        break;
      }
    }
    if (entry == null) {
      return null;
    }

    try {
      final mapPath = workspace.resolveMapPath(entry.relativePath);
      final repo = ref.read(mapRepositoryProvider);
      return await repo.loadMap(mapPath);
    } catch (error) {
      debugPrint(
        'EditorNotifier: loadMapSnapshotById($normalizedMapId) failed: $error',
      );
      return null;
    }
  }

  Future<void> resizeActiveMap(int width, int height) async {
    final map = state.activeMap;
    if (map == null) return;

    debugPrint('EditorNotifier: resizeActiveMap(${width}x$height)');
    try {
      final useCase = ref.read(resizeMapUseCaseProvider);
      final resized = useCase.execute(map, width, height);
      final project = state.project;
      final committed = project == null
          ? resized
          : _placedElementInstanceIndexer.syncAllTileLayers(
              map: resized,
              project: project,
            );

      if (committed == map) {
        state = state.copyWith(
          statusMessage: 'Map "${map.id}" is already ${width}x$height',
          errorMessage: null,
        );
        return;
      }

      final hovered = state.hoveredTile;
      final nextHovered = (hovered != null &&
              (hovered.x < 0 ||
                  hovered.y < 0 ||
                  hovered.x >= width ||
                  hovered.y >= height))
          ? null
          : hovered;
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: state.activeLayerId,
        hoveredTile: nextHovered,
        updateHoveredTile: true,
        statusMessage: 'Map "${map.id}" resized to ${width}x$height',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error resizing map: $e');
      state = state.copyWith(errorMessage: 'Failed to resize map: $e');
    }
  }

  void updateMapMetadata(MapMetadata metadata) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(updateMapMetadataUseCaseProvider);
      final updated = useCase.execute(
        map,
        metadata,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: state.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Carte : propriétés enregistrées',
      );
    } catch (e) {
      debugPrint('EditorNotifier: updateMapMetadata failed: $e');
      state = state.copyWith(
        errorMessage: 'Échec des propriétés de carte : $e',
      );
    }
  }

  Future<void> renameMap(String oldId, String newId) async {
    debugPrint('EditorNotifier: renameMap($oldId -> $newId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(renameMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, oldId, newId);
      state = _projectSessionController.afterMapRenamed(
        current: state,
        updatedProject: updatedProject,
        oldId: oldId,
        newId: newId,
        newPath: fs.getMapPath(newId),
        statusMessage: 'Map renamed to "$newId"',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming map: $e');
      state = state.copyWith(errorMessage: 'Failed to rename map: $e');
    }
  }

  Future<void> deleteMap(String mapId) async {
    debugPrint('EditorNotifier: deleteMap($mapId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, mapId);
      state = _projectSessionController.afterMapDeleted(
        current: state,
        updatedProject: updatedProject,
        deletedMapId: mapId,
        statusMessage: 'Map "$mapId" deleted',
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting map: $e');
      state = state.copyWith(errorMessage: 'Failed to delete map: $e');
    }
  }

  Future<void> duplicateMap(String sourceId) async {
    debugPrint('EditorNotifier: duplicateMap($sourceId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(duplicateMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, sourceId);

      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Map "$sourceId" duplicated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error duplicating map: $e');
      state = state.copyWith(errorMessage: 'Failed to duplicate map: $e');
    }
  }

  Future<void> createGroup(String name, MapGroupType type,
      {String? parentId}) async {
    debugPrint('EditorNotifier: createGroup($name, $type, parent: $parentId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(createGroupUseCaseProvider);
      final updatedProject =
          await useCase.execute(fs, project, name, type, parentId: parentId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group "$name" created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating group: $e');
      state = state.copyWith(errorMessage: 'Failed to create group: $e');
    }
  }

  Future<void> deleteGroup(String groupId) async {
    debugPrint('EditorNotifier: deleteGroup($groupId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteGroupUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, groupId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting group: $e');
      state = state.copyWith(errorMessage: 'Failed to delete group: $e');
    }
  }

  Future<void> renameGroup(String groupId, String newName) async {
    debugPrint('EditorNotifier: renameGroup($groupId -> $newName)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(renameGroupUseCaseProvider);
      final updatedProject =
          await useCase.execute(fs, project, groupId, newName);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group renamed',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming group: $e');
      state = state.copyWith(errorMessage: 'Failed to rename group: $e');
    }
  }

  Future<void> moveMapToGroup(String mapId, String? groupId) async {
    debugPrint('EditorNotifier: moveMapToGroup($mapId -> $groupId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(moveMapToGroupUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, mapId, groupId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Map moved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving map: $e');
      state = state.copyWith(errorMessage: 'Failed to move map: $e');
    }
  }

  List<ProjectTilesetEntry> getAssignableTilesetsForActiveMap() {
    final project = state.project;
    final activeMap = state.activeMap;
    if (project == null || activeMap == null) return const [];
    try {
      final useCase = ref.read(resolveAssignableTilesetsForMapUseCaseProvider);
      return useCase.execute(project, activeMap.id);
    } catch (_) {
      return const [];
    }
  }

  Future<void> importProjectTileset({
    required String sourcePath,
    required String name,
    required TilesetScope scope,
    String? groupId,
    bool isWorldTileset = false,
    String? libraryFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(importProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        sourcePath: sourcePath,
        name: name,
        scope: scope,
        groupId: groupId,
        isWorldTileset: isWorldTileset,
        folderId: libraryFolderId,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId:
            updated.tilesets.isNotEmpty ? updated.tilesets.last.id : null,
        selectedTilesetElementGroupId: null,
        statusMessage: 'Tileset "$name" imported',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error importing tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to import tileset: $e');
    }
  }

  Future<void> updateProjectTileset({
    required String tilesetId,
    String? name,
    TilesetScope? scope,
    String? groupId,
    bool? isWorldTileset,
    int? sortOrder,
    String? libraryFolderId,
    bool clearLibraryFolder = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(updateProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        name: name,
        scope: scope,
        groupId: groupId,
        isWorldTileset: isWorldTileset,
        sortOrder: sortOrder,
        folderId: libraryFolderId,
        clearLibraryFolder: clearLibraryFolder,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset updated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to update tileset: $e');
    }
  }

  Future<void> reorderProjectTileset(String tilesetId, int direction) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(reorderProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        direction: direction,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset reordered',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error reordering tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to reorder tileset: $e');
    }
  }

  Future<void> createTilesetLibraryFolder({
    required String name,
    String? parentFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        parentFolderId: parentFolderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to create tileset folder: $e',
      );
    }
  }

  Future<void> renameTilesetLibraryFolder({
    required String folderId,
    required String name,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder renamed',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to rename tileset folder: $e',
      );
    }
  }

  Future<void> moveTilesetLibraryFolder({
    required String folderId,
    String? newParentFolderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(moveTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
        newParentFolderId: newParentFolderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder moved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset folder: $e',
      );
    }
  }

  Future<void> deleteTilesetLibraryFolder(String folderId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteTilesetLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        folderId: folderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset folder deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to delete tileset folder: $e',
      );
    }
  }

  Future<void> assignTilesetToLibraryFolder({
    required String tilesetId,
    required String folderId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(assignTilesetToLibraryFolderUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        folderId: folderId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset moved to folder',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error assigning tileset folder: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset to folder: $e',
      );
    }
  }

  Future<void> moveTilesetToLibraryRoot(String tilesetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(moveTilesetToLibraryRootUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Tileset moved to library root',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving tileset to library root: $e');
      state = state.copyWith(
        errorMessage: 'Failed to move tileset to library root: $e',
      );
    }
  }

  Future<void> deleteProjectTileset(String tilesetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteProjectTilesetUseCaseProvider);
      final updated = await useCase.execute(fs, project, tilesetId);
      final presetSelection = _terrainPresetSelectionCoordinator.normalize(
        project: updated,
        current: _currentTerrainPresetSelection(),
      );
      String? selectedTilesetEditorId = state.selectedTilesetEditorId;
      var workspaceMode = state.workspaceMode;
      var activeBrush =
          _clearBrushIfTilesetRemoved(state.activeBrush, tilesetId);
      if (selectedTilesetEditorId == tilesetId) {
        selectedTilesetEditorId =
            _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(
          state.activeMap,
          preferredLayerId: state.activeLayerId,
        );
        if (selectedTilesetEditorId != null &&
            !updated.tilesets.any((t) => t.id == selectedTilesetEditorId)) {
          selectedTilesetEditorId =
              updated.tilesets.isNotEmpty ? updated.tilesets.first.id : null;
        }
        if (selectedTilesetEditorId == null) {
          workspaceMode = EditorWorkspaceMode.map;
        }
      }
      state = state.copyWith(
        project: updated,
        workspaceMode: workspaceMode,
        activeBrush: activeBrush,
        selectedTilesetEditorId: selectedTilesetEditorId,
        selectedTilesetElementGroupId: null,
        terrainSelectionMode: presetSelection.selectionMode,
        selectedTerrainType: presetSelection.selectedTerrainType,
        selectedTerrainPresetId: presetSelection.selectedTerrainPresetId,
        selectedPathPresetId: presetSelection.selectedPathPresetId,
        selectedTerrainPresetByType:
            presetSelection.selectedTerrainPresetByType,
        statusMessage: 'Tileset deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting tileset: $e');
      state = state.copyWith(errorMessage: 'Failed to delete tileset: $e');
    }
  }

  Future<void> assignTilesetToActiveLayer(String tilesetId) async {
    final project = state.project;
    final map = state.activeMap;
    final mapPath = state.activeMapPath;
    final layerId = state.activeLayerId;
    if (project == null || map == null || mapPath == null || layerId == null) {
      return;
    }
    final layer = _findLayerById(map, layerId);
    if (layer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Active layer must be a tile layer to assign a tileset',
      );
      return;
    }

    try {
      final useCase = ref.read(assignTilesetToMapUseCaseProvider);
      final updatedMap = await useCase.execute(
        project,
        map,
        mapPath,
        layerId,
        tilesetId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Tileset "$tilesetId" assigned to layer "${layer.name}"',
        updateSavedSnapshot: true,
      );
      state = state.copyWith(
        workspaceMode: EditorWorkspaceMode.map,
        activeBrush: const EditorBrush.none(),
        selectedTilesetEditorId: tilesetId,
        selectedTilesetElementGroupId: null,
        paletteCategoryFilter: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error assigning layer tileset: $e');
      state =
          state.copyWith(errorMessage: 'Failed to assign layer tileset: $e');
    }
  }

  Future<void> assignTilesetToActiveMap(String tilesetId) async {
    await assignTilesetToActiveLayer(tilesetId);
  }

  ProjectTilesetEntry? getActiveTilesetEntry() {
    return getSelectedTilesetEntry();
  }

  String? getActiveTilesetAbsolutePath() {
    final fs = _projectWorkspace;
    final tileset = getActiveTilesetEntry();
    if (fs == null || tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  PathAutotileSet? getSelectedPathAutotileSet() {
    return _pathAutotileResolver.resolve(
      selectedPreset: getSelectedPathPreset(),
      hasTileset: (tilesetId) => getTilesetById(tilesetId) != null,
    );
  }

  PathAutotileSet? getPathAutotileSetForPresetId(String? presetId) {
    return _pathAutotileResolver.resolve(
      selectedPreset: getPathPresetById(presetId),
      hasTileset: (tilesetId) => getTilesetById(tilesetId) != null,
    );
  }

  Map<String, PathAutotileSet> getPathAutotileSetsByPresetId() {
    final result = <String, PathAutotileSet>{};
    for (final preset in getPathPresets()) {
      final resolved = getPathAutotileSetForPresetId(preset.id);
      if (resolved != null) {
        result[preset.id] = resolved;
      }
    }
    return result;
  }

  List<ProjectTerrainPreset> getTerrainPresets({TerrainType? terrainType}) {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listTerrainPresets(
      project,
      terrainType: terrainType,
    );
  }

  List<ProjectPathPreset> getPathPresets() {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listPathPresets(project);
  }

  List<ProjectSurfacePreset> getSurfacePresets() {
    return state.project?.surfaceCatalog.presets ?? const [];
  }

  List<ProjectPresetCategory> getPresetCategories({
    required PresetLibraryKind kind,
    String? parentCategoryId,
  }) {
    final project = state.project;
    if (project == null) return const [];
    return _terrainPresetResolver.listPresetCategories(
      project,
      kind: kind,
      parentCategoryId: parentCategoryId,
    );
  }

  ProjectPresetCategory? getPresetCategoryById({
    required PresetLibraryKind kind,
    required String? categoryId,
  }) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findPresetCategoryById(
      project,
      kind: kind,
      categoryId: categoryId,
    );
  }

  String? resolvePresetCategoryPath({
    required PresetLibraryKind kind,
    required String? categoryId,
  }) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.resolvePresetCategoryPath(
      project,
      kind: kind,
      categoryId: categoryId,
    );
  }

  ProjectTerrainPreset? getTerrainPresetById(String? presetId) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findTerrainPresetById(project, presetId);
  }

  ProjectPathPreset? getPathPresetById(String? presetId) {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.findPathPresetById(project, presetId);
  }

  ProjectSurfacePreset? getSurfacePresetById(String? presetId) {
    final normalizedPresetId = presetId?.trim();
    if (normalizedPresetId == null || normalizedPresetId.isEmpty) {
      return null;
    }
    final project = state.project;
    if (project == null) return null;
    return project.surfaceCatalog.presetById(normalizedPresetId);
  }

  ProjectTerrainPreset? getSelectedTerrainPreset({TerrainType? terrainType}) {
    final project = state.project;
    if (project == null) return null;
    final type = terrainType ?? state.selectedTerrainType;
    return _terrainPresetResolver.resolveSelectedTerrainPreset(
      project,
      terrainType: type,
      selectedTerrainPresetId: state.selectedTerrainPresetId,
      selectedTerrainPresetByType: state.selectedTerrainPresetByType,
    );
  }

  ProjectPathPreset? getSelectedPathPreset() {
    final project = state.project;
    if (project == null) return null;
    return _terrainPresetResolver.resolveSelectedPathPreset(
      project,
      selectedPathPresetId: state.selectedPathPresetId,
    );
  }

  ProjectSurfacePreset? getSelectedSurfacePreset() {
    return getSurfacePresetById(state.selectedSurfacePresetId);
  }

  Map<TerrainType, ProjectTerrainPreset> getTerrainPresetByType() {
    final result = <TerrainType, ProjectTerrainPreset>{};
    for (final type in TerrainType.values) {
      if (!type.isBackgroundPaintable) continue;
      final preset = getSelectedTerrainPreset(terrainType: type);
      if (preset != null) {
        result[type] = preset;
      }
    }
    return result;
  }

  void selectMapWorkspace() {
    state = _editorWorkspaceController.selectMapWorkspace(state);
  }

  void selectTilesetWorkspace(String? tilesetId) {
    final project = state.project;
    if (project == null) return;
    if (tilesetId != null && !project.tilesets.any((t) => t.id == tilesetId)) {
      return;
    }
    state = state.copyWith(
      workspaceMode: tilesetId == null
          ? EditorWorkspaceMode.map
          : EditorWorkspaceMode.tileset,
      selectedTilesetEditorId: tilesetId,
      selectedTilesetElementGroupId: null,
    );
  }

  /// Ouvre le workspace Pokédex des lots 12-13.
  ///
  /// Ce changement reste volontairement une simple navigation :
  /// - aucune donnee Pokemon n'est chargee ici ;
  /// - aucun service Pokemon n'est appele ici ;
  /// - l'ecran central gerera lui-meme la lecture simple necessaire au lot 13.
  ///
  /// Cela garde la responsabilite du notifier tres claire :
  /// il route vers un workspace, mais ne commence pas une logique Pokédex riche.
  void selectPokedexWorkspace() {
    state = _editorWorkspaceController.selectPokedexWorkspace(state);
  }

  void selectPokemonCatalogSection(PokemonCatalogSection section) {
    state = _editorWorkspaceController.selectPokemonCatalogSection(
      state,
      section,
    );
  }

  /// Ouvre le workspace central "Trainer Studio".
  ///
  /// Cette navigation reste volontairement minimale :
  /// - aucun pipeline trainer parallèle n'est créé ici ;
  /// - aucune donnée locale n'est préchargée depuis le notifier ;
  /// - la surface centrale réutilise le même flux trainer que la sidebar,
  ///   via les méthodes existantes du notifier.
  void selectTrainerWorkspace() {
    state = _editorWorkspaceController.selectTrainerWorkspace(state);
  }

  /// Ouvre le workspace central "Global Story".
  ///
  /// Ce changement est purement une navigation d'espace de travail:
  /// - aucune mutation map/tileset n'est exécutée,
  /// - aucune donnée narrative n'est modifiée ici.
  void selectGlobalStoryWorkspace() {
    state = _editorWorkspaceController.selectGlobalStoryWorkspace(state);
  }

  /// Ouvre le workspace central "Step".
  void selectStepWorkspace() {
    state = _editorWorkspaceController.selectStepWorkspace(state);
  }

  /// Ouvre le workspace central "Cutscene".
  void selectCutsceneWorkspace() {
    state = _editorWorkspaceController.selectCutsceneWorkspace(state);
  }

  /// Bascule vers Dialogue Studio (bibliothèque + canvas + inspecteur).
  void selectDialogueWorkspace() {
    state = _editorWorkspaceController.selectDialogueWorkspace(state);
  }

  /// Bascule vers Path Studio.
  ///
  /// Navigation pure de shell : aucune mutation de manifest, aucune génération
  /// de preview et aucun save flow ne sont déclenchés par ce point d'entrée.
  void selectPathStudioWorkspace() {
    state = _editorWorkspaceController.selectPathStudioWorkspace(state);
  }

  /// Écrit uniquement le fichier `.yarn` (le manifest projet reste inchangé).
  Future<void> saveProjectDialogueYarnBody({
    required String dialogueId,
    required String yarnBody,
  }) async {
    state = await _projectContentController.saveProjectDialogueYarnBody(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      yarnBody: yarnBody,
    );
  }

  void selectTilesetEditorContext(String? tilesetId) {
    final project = state.project;
    if (project == null) return;
    if (tilesetId != null && !project.tilesets.any((t) => t.id == tilesetId)) {
      return;
    }
    state = state.copyWith(
      selectedTilesetEditorId: tilesetId,
      selectedTilesetElementGroupId: null,
      errorMessage: null,
    );
  }

  ProjectTilesetEntry? getSelectedTilesetEntry() {
    final project = state.project;
    if (project == null) return null;

    final selectedId = state.selectedTilesetEditorId;
    if (selectedId != null) {
      for (final tileset in project.tilesets) {
        if (tileset.id == selectedId) {
          return tileset;
        }
      }
    }

    final map = state.activeMap;
    final activeLayerId = state.activeLayerId;
    if (map != null && activeLayerId != null) {
      final activeLayer = _findLayerById(map, activeLayerId);
      if (activeLayer is TileLayer) {
        final layerTilesetId = activeLayer.tilesetId?.trim();
        if (layerTilesetId != null && layerTilesetId.isNotEmpty) {
          for (final tileset in project.tilesets) {
            if (tileset.id == layerTilesetId) {
              return tileset;
            }
          }
        }
      }
    }

    final brushTilesetId = getActiveBrushTilesetId();
    if (brushTilesetId != null) {
      for (final tileset in project.tilesets) {
        if (tileset.id == brushTilesetId) {
          return tileset;
        }
      }
    }

    if (project.tilesets.isEmpty) return null;
    return project.tilesets.first;
  }

  String? getSelectedTilesetAbsolutePath() {
    final fs = _projectWorkspace;
    final tileset = getSelectedTilesetEntry();
    if (fs == null || tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  String? getTilesetAbsolutePathById(String tilesetId) {
    final fs = _projectWorkspace;
    if (fs == null) return null;
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  String? getActiveBrushTilesetId() {
    final brush = state.activeBrush;
    if (brush is TileEditorBrush) {
      return brush.tilesetId;
    }
    if (brush is PaletteEntryEditorBrush) {
      return brush.tilesetId;
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      return element?.tilesetId;
    }
    return null;
  }

  List<TilesetElementGroup> getSelectedTilesetElementGroups() {
    final tileset = getSelectedTilesetEntry();
    if (tileset == null) return const [];
    final groups = List<TilesetElementGroup>.from(
      tileset.elementGroups,
      growable: false,
    );
    groups.sort((a, b) {
      if (a.parentGroupId == b.parentGroupId) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      final parentA = a.parentGroupId ?? '';
      final parentB = b.parentGroupId ?? '';
      final parentCompare = parentA.compareTo(parentB);
      if (parentCompare != 0) return parentCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return groups;
  }

  void selectTilesetElementGroupFilter(String? groupId) {
    final tileset = getSelectedTilesetEntry();
    if (tileset == null) return;
    if (groupId != null &&
        !tileset.elementGroups.any((group) => group.id == groupId)) {
      return;
    }
    state = state.copyWith(selectedTilesetElementGroupId: groupId);
  }

  Future<void> createTilesetElementGroup(
    String tilesetId,
    String name, {
    String? parentGroupId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetElementGroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        name: name,
        parentGroupId: parentGroupId,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset group created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create tileset group: $e',
      );
    }
  }

  Future<void> createTilesetElementSubgroup(
    String tilesetId,
    String parentGroupId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetElementSubgroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        parentGroupId: parentGroupId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset subgroup created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create tileset subgroup: $e',
      );
    }
  }

  Future<void> renameTilesetElementGroup(
    String tilesetId,
    String groupId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameTilesetElementGroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        groupId: groupId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset group renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to rename tileset group: $e',
      );
    }
  }

  List<ProjectElementEntry> getSelectedTilesetElements({
    String? tilesetGroupId,
    bool includeDescendants = true,
  }) {
    final project = state.project;
    final selectedTileset = getSelectedTilesetEntry();
    if (project == null || selectedTileset == null) return const [];
    try {
      final useCase = ref.read(resolveTilesetElementsUseCaseProvider);
      return useCase.execute(
        project,
        tilesetId: selectedTileset.id,
        tilesetGroupId: tilesetGroupId,
        includeDescendants: includeDescendants,
      );
    } catch (_) {
      return const [];
    }
  }

  List<ProjectElementCategory> getElementCategories() {
    final project = state.project;
    if (project == null) return const [];
    final categories = List<ProjectElementCategory>.from(
      project.elementCategories,
      growable: false,
    );
    categories.sort((a, b) {
      if (a.parentCategoryId == b.parentCategoryId) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      final parentA = a.parentCategoryId ?? '';
      final parentB = b.parentCategoryId ?? '';
      final parentCompare = parentA.compareTo(parentB);
      if (parentCompare != 0) return parentCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return categories;
  }

  ProjectElementCategory? getElementCategoryById(String categoryId) {
    final project = state.project;
    if (project == null) return null;
    for (final category in project.elementCategories) {
      if (category.id == categoryId) {
        return category;
      }
    }
    return null;
  }

  ProjectElementEntry? getProjectElementById(String elementId) {
    final project = state.project;
    if (project == null) return null;
    for (final element in project.elements) {
      if (element.id == elementId) {
        return element;
      }
    }
    return null;
  }

  List<ProjectElementEntry> getVisibleProjectElementsForActiveMap({
    bool includeAll = false,
    bool globalOnly = false,
    bool acrossAllTilesets = false,
  }) {
    final project = state.project;
    final map = state.activeMap;
    if (project == null || map == null) return const [];

    List<ProjectElementEntry> resolved;
    final activeTilesetId = getSelectedTilesetEntry()?.id;
    if (includeAll) {
      resolved = project.elements.where((element) {
        if (!acrossAllTilesets && element.tilesetId != activeTilesetId) {
          return false;
        }
        return true;
      }).toList(growable: false);
    } else if (globalOnly) {
      resolved = project.elements
          .where(
            (element) =>
                (acrossAllTilesets || element.tilesetId == activeTilesetId) &&
                element.groupId == null,
          )
          .toList(growable: false);
    } else {
      if (!acrossAllTilesets && activeTilesetId == null) {
        return const [];
      }
      try {
        final useCase = ref.read(resolveVisibleProjectElementsUseCaseProvider);
        resolved = useCase.execute(
          project,
          tilesetId: acrossAllTilesets ? null : activeTilesetId,
          mapId: map.id,
        );
      } catch (_) {
        resolved = const [];
      }
    }

    resolved.sort((a, b) {
      final categoryCompare = a.categoryId.compareTo(b.categoryId);
      if (categoryCompare != 0) return categoryCompare;
      final sortCompare = a.sortOrder.compareTo(b.sortOrder);
      if (sortCompare != 0) return sortCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return resolved;
  }

  Future<void> createElementCategory(
    String name, {
    String? parentCategoryId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createElementCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        parentCategoryId: parentCategoryId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element category created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create category: $e');
    }
  }

  Future<void> createElementSubcategory(
    String parentCategoryId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createElementSubcategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        parentCategoryId: parentCategoryId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element subcategory created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create subcategory: $e');
    }
  }

  Future<void> renameElementCategory(String categoryId, String name) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameElementCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element category renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename category: $e');
    }
  }

  Future<void> createProjectElement({
    required String name,
    required String categoryId,
    required TilesetSourceRect source,
    ElementPresetKind presetKind = ElementPresetKind.generic,
    ElementCollisionProfile? collisionProfile,
    String? tilesetId,
    String? tilesetGroupId,
    String? groupId,
    String? recommendedLayerId,
    List<String> tags = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    final selectedTileset = getSelectedTilesetEntry();
    final effectiveTilesetId = tilesetId ?? selectedTileset?.id;
    if (effectiveTilesetId == null) {
      state = state.copyWith(errorMessage: 'No tileset selected');
      return;
    }
    try {
      final useCase = ref.read(createProjectElementUseCaseProvider);
      final result = await useCase.execute(
        fs,
        project,
        name: name,
        tilesetId: effectiveTilesetId,
        categoryId: categoryId,
        presetKind: presetKind,
        collisionProfile: collisionProfile,
        tilesetGroupId: tilesetGroupId,
        source: source,
        groupId: groupId,
        recommendedLayerId: recommendedLayerId,
        tags: tags,
      );
      state = state.copyWith(
        project: result.project,
        activeBrush: EditorBrush.projectElement(elementId: result.element.id),
        selectedTilesetEditorId: result.element.tilesetId,
        selectedTilesetElementGroupId: result.element.tilesetGroupId,
        statusMessage: 'Element "${result.element.name}" created',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create element: $e');
    }
  }

  Future<void> updateProjectElement({
    required String elementId,
    String? name,
    ElementPresetKind? presetKind,
    ElementCollisionProfile? collisionProfile,
    bool clearCollisionProfile = false,
    String? categoryId,
    String? tilesetGroupId,
    bool clearTilesetGroupId = false,
    String? groupId,
    bool clearGroupId = false,
    String? recommendedLayerId,
    bool clearRecommendedLayerId = false,
    TilesetSourceRect? source,
    List<TilesetVisualFrame>? frames,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateProjectElementUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        elementId: elementId,
        name: name,
        presetKind: presetKind,
        collisionProfile: collisionProfile,
        clearCollisionProfile: clearCollisionProfile,
        categoryId: categoryId,
        tilesetGroupId: tilesetGroupId,
        clearTilesetGroupId: clearTilesetGroupId,
        groupId: groupId,
        clearGroupId: clearGroupId,
        recommendedLayerId: recommendedLayerId,
        clearRecommendedLayerId: clearRecommendedLayerId,
        source: source,
        frames: frames,
        tags: tags,
      );
      String? selectedTilesetElementGroupId =
          state.selectedTilesetElementGroupId;
      final selectedElementId = state.activeBrush.maybeMap(
        projectElement: (brush) => brush.elementId,
        orElse: () => null,
      );
      if (selectedElementId == elementId) {
        if (clearTilesetGroupId) {
          selectedTilesetElementGroupId = null;
        } else if (tilesetGroupId != null) {
          selectedTilesetElementGroupId = tilesetGroupId;
        }
      }
      state = state.copyWith(
        project: updated,
        selectedTilesetElementGroupId: selectedTilesetElementGroupId,
        statusMessage: 'Element updated',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update element: $e');
    }
  }

  Future<void> deleteProjectElement(String elementId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteProjectElementUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        elementId: elementId,
      );
      final activeBrush = state.activeBrush.maybeMap(
        projectElement: (brush) => brush.elementId == elementId
            ? const EditorBrush.none()
            : state.activeBrush,
        orElse: () => state.activeBrush,
      );
      state = state.copyWith(
        project: updated,
        activeBrush: activeBrush,
        statusMessage: 'Element deleted',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete element: $e');
    }
  }

  Future<ElementCollisionProfile?> generateElementCollisionProfile({
    required String tilesetId,
    required TilesetSourceRect source,
    ElementPresetKind presetKind = ElementPresetKind.generic,
    WarpTriggerPadding padding = const WarpTriggerPadding(),
  }) async {
    final project = state.project;
    if (project == null) {
      state = state.copyWith(errorMessage: 'No project loaded');
      return null;
    }
    final tilesetPath = getTilesetAbsolutePathById(tilesetId);
    if (tilesetPath == null || tilesetPath.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Tileset path not found');
      return null;
    }
    try {
      final profile = await _elementCollisionProfileGenerator.generate(
        tilesetImagePath: tilesetPath,
        source: source,
        tileWidth: project.settings.tileWidth,
        tileHeight: project.settings.tileHeight,
        presetKind: presetKind,
        padding: padding,
      );
      state = state.copyWith(
        statusMessage:
            'Collision auto-générée (${profile.cells.length} cellule${profile.cells.length > 1 ? 's' : ''})',
        errorMessage: null,
      );
      return profile;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to generate collision profile: $e',
      );
      return null;
    }
  }

  void _resyncPlacedElementsForActiveMapFromProject() {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) {
      return;
    }
    final synced = _placedElementInstanceIndexer.syncAllTileLayers(
      map: map,
      project: project,
    );
    if (identical(synced, map) || synced == map) {
      return;
    }
    _applyMapMutation(
      previousMap: map,
      updatedMap: synced,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: 'Instances d’éléments synchronisées',
    );
  }

  List<TilesetPaletteEntry> getActivePaletteEntries() {
    final tilesetId = getSelectedTilesetEntry()?.id;
    if (tilesetId == null) return const [];
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return const [];
    return List<TilesetPaletteEntry>.unmodifiable(tileset.paletteEntries);
  }

  ProjectTilesetEntry? getTilesetById(String tilesetId) {
    final project = state.project;
    if (project == null) return null;
    for (final tileset in project.tilesets) {
      if (tileset.id == tilesetId) {
        return tileset;
      }
    }
    return null;
  }

  List<TilesetPaletteEntry> getPaletteEntriesForTileset(String tilesetId) {
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return const [];
    return List<TilesetPaletteEntry>.unmodifiable(tileset.paletteEntries);
  }

  TilesetPaletteEntry? getPaletteEntryById({
    required String tilesetId,
    required String entryId,
  }) {
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return null;
    for (final entry in tileset.paletteEntries) {
      if (entry.id == entryId) {
        return entry;
      }
    }
    return null;
  }

  TilesetPaletteEntry? getActivePaletteEntryById(String entryId) {
    final tilesetId = getSelectedTilesetEntry()?.id;
    if (tilesetId == null) return null;
    return getPaletteEntryById(tilesetId: tilesetId, entryId: entryId);
  }

  void setPaletteCategoryFilter(PaletteCategory? category) {
    state = state.copyWith(paletteCategoryFilter: category);
  }

  void selectPaletteTile(int tileId) {
    if (tileId <= 0) return;
    final selectedTileset =
        getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (selectedTileset == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.tile(
        tileId: tileId,
        tilesetId: selectedTileset.id,
      ),
    );
  }

  void selectPaletteEntry(String entryId) {
    final selectedTileset =
        getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (selectedTileset == null) return;
    final entry =
        getPaletteEntryById(tilesetId: selectedTileset.id, entryId: entryId);
    if (entry == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.paletteEntry(
        entryId: entry.id,
        tilesetId: selectedTileset.id,
      ),
    );
  }

  void selectProjectElement(String elementId) {
    final element = getProjectElementById(elementId);
    if (element == null) return;
    state = state.copyWith(
      activeBrush: EditorBrush.projectElement(elementId: element.id),
      selectedTilesetEditorId: element.tilesetId,
      selectedTilesetElementGroupId: element.tilesetGroupId,
      selectedPlacedElementInstanceId: null,
    );
  }

  Future<void> createPaletteEntry({
    required String name,
    required PaletteCategory category,
    required TilesetSourceRect source,
    String? recommendedLayerId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final tileset = getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (fs == null || project == null || tileset == null) return;

    try {
      final useCase = ref.read(createTilesetPaletteEntryUseCaseProvider);
      final result = await useCase.execute(
        fs,
        project,
        tilesetId: tileset.id,
        name: name,
        category: category,
        source: source,
        recommendedLayerId: recommendedLayerId,
      );
      state = state.copyWith(
        project: result.project,
        activeBrush: EditorBrush.paletteEntry(
          entryId: result.entry.id,
          tilesetId: tileset.id,
        ),
        statusMessage: 'Palette element "${result.entry.name}" created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating palette entry: $e');
      state = state.copyWith(errorMessage: 'Failed to create element: $e');
    }
  }

  Future<void> upsertPaletteEntryForTile({
    required int tileId,
    required int columns,
    required PaletteCategory category,
    String? recommendedLayerId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final tileset = getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (fs == null || project == null || tileset == null) return;
    if (tileId <= 0 || columns <= 0) return;

    final sourceIndex = tileId - 1;
    final sourceX = sourceIndex % columns;
    final sourceY = sourceIndex ~/ columns;

    TilesetPaletteEntry? existing;
    for (final entry in tileset.paletteEntries) {
      final ps = entry.frames.primarySource;
      if (ps.width == 1 &&
          ps.height == 1 &&
          ps.x == sourceX &&
          ps.y == sourceY) {
        existing = entry;
        break;
      }
    }

    final rect = TilesetSourceRect(x: sourceX, y: sourceY);
    final entry = TilesetPaletteEntry(
      id: existing?.id ?? 'tile_$tileId',
      name: existing?.name.isNotEmpty == true ? existing!.name : 'tile_$tileId',
      category: category,
      frames: existing == null
          ? [TilesetVisualFrame(source: rect)]
          : [
              TilesetVisualFrame(source: rect),
              ...existing.frames.skip(1),
            ],
      recommendedLayerId: recommendedLayerId,
    );

    try {
      final useCase = ref.read(upsertTilesetPaletteEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tileset.id,
        entry: entry,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Palette entry updated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating palette entry: $e');
      state =
          state.copyWith(errorMessage: 'Failed to update palette entry: $e');
    }
  }

  void paintSelectedBrushAt(
    GridPos pos, {
    required Map<String, int> tilesetColumnsById,
  }) {
    final layerContext = _resolveActiveTileLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final resolvedBrush = _resolveActiveBrushPattern(
      tilesetColumnsById: tilesetColumnsById,
      emitErrors: true,
    );
    if (resolvedBrush == null) return;
    final preparedMap = _prepareMapForBrushTileset(
      map: layerContext.map,
      layerId: layerContext.layerId,
      activeLayer: layerContext.layer,
      brushTilesetId: resolvedBrush.tilesetId,
    );
    if (preparedMap == null) return;
    _paintPattern(
      map: preparedMap,
      layerId: layerContext.layerId,
      pos: pos,
      pattern: resolvedBrush.pattern,
      failureLabel: resolvedBrush.failureLabel,
    );
  }

  void paintCollisionAt(GridPos pos) {
    final layerContext = _resolveActiveCollisionLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final footprint = _resolveCollisionFootprint(emitErrors: true);
    if (footprint == null) return;
    _paintCollisionPattern(
      map: layerContext.map,
      layerId: layerContext.layerId,
      pos: pos,
      patternSize: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  void paintTerrainAt(GridPos pos) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      _setPaintError('No active editable layer selected');
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      _setPaintError('Active layer not found: $layerId');
      return;
    }
    if (activeLayer is TerrainLayer) {
      final footprint = _resolveTerrainFootprint(emitErrors: true);
      if (footprint == null) return;
      _paintTerrainPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        terrain: state.selectedTerrainType,
        patternSize: footprint.size,
        failureLabel: footprint.failureLabel,
      );
      return;
    }
    if (activeLayer is PathLayer) {
      final footprint = _resolvePathFootprint();
      final selectedPathPreset = getSelectedPathPreset();
      if (activeLayer.presetId.trim().isEmpty && selectedPathPreset != null) {
        try {
          final presetAssigned = _pathLayerEditingCoordinator.assignPreset(
            map: map,
            layerId: layerId,
            presetId: selectedPathPreset.id,
          );
          _paintPathPattern(
            map: presetAssigned,
            previousMap: map,
            layerId: layerId,
            pos: pos,
            patternSize: footprint.size,
            failureLabel: footprint.failureLabel,
          );
        } catch (e) {
          _setPaintError('Failed to assign path preset: $e');
        }
        return;
      }
      _paintPathPattern(
        map: map,
        previousMap: map,
        layerId: layerId,
        pos: pos,
        patternSize: footprint.size,
        failureLabel: footprint.failureLabel,
      );
      return;
    }
    _setPaintError('Active layer "${activeLayer.name}" is not editable');
  }

  void paintSurfaceAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) {
      _setPaintError('No active map selected');
      return;
    }
    final selectedPreset = getSelectedSurfacePreset();
    if (selectedPreset == null) {
      _setPaintError('Select a surface before painting');
      return;
    }

    try {
      final result = _surfacePaintingController.paint(
        map: map,
        targetLayerId: state.activeLayerId,
        surfacePresetId: selectedPreset.id,
        pos: pos,
      );
      if (!result.changed) {
        state = state.copyWith(errorMessage: null);
        return;
      }
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layerId,
        statusMessage: 'Surface painted: ${selectedPreset.name}',
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint surface: $e');
    }
  }

  void fillActiveTerrainLayer(TerrainType terrain) {
    final layerContext = _resolveActiveTerrainLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final map = layerContext.map;
    final layerId = layerContext.layerId;
    try {
      final committed = _terrainPaintingCoordinator.fill(
        map: map,
        layerId: layerId,
        terrain: terrain,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        statusMessage: 'Terrain layer filled with ${terrain.name}',
      );
    } catch (e) {
      _setPaintError('Failed to fill terrain layer: $e');
    }
  }

  void assignPathPresetToActivePathLayer(String presetId) {
    final layerContext = _resolveActivePathLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final normalizedPresetId = presetId.trim();
    if (layerContext.layer.presetId.trim() == normalizedPresetId) {
      final preset = getPathPresetById(normalizedPresetId);
      state = state.copyWith(
        statusMessage: preset == null
            ? 'Path layer preset unchanged'
            : 'Path layer preset: ${preset.name}',
        errorMessage: null,
      );
      return;
    }
    try {
      final updated = _pathLayerEditingCoordinator.assignPreset(
        map: layerContext.map,
        layerId: layerContext.layerId,
        presetId: normalizedPresetId,
      );
      final preset = getPathPresetById(normalizedPresetId);
      _applyMapMutation(
        previousMap: layerContext.map,
        updatedMap: updated,
        preferredActiveLayerId: layerContext.layerId,
        statusMessage: preset == null
            ? 'Path layer preset assigned'
            : 'Path layer preset: ${preset.name}',
      );
    } catch (e) {
      _setPaintError('Failed to assign path preset: $e');
    }
  }

  void eraseAt(GridPos pos) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      _setPaintError('No active layer selected');
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      _setPaintError('Active layer not found: $layerId');
      return;
    }
    if (activeLayer is TileLayer) {
      final pattern = _resolveErasePattern(emitErrors: true);
      if (pattern == null) return;
      _erasePattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: pattern.size,
        failureLabel: pattern.failureLabel,
      );
      return;
    }
    if (activeLayer is CollisionLayer) {
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: true);
      if (collisionFootprint == null) return;
      _eraseCollisionPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: collisionFootprint.size,
        failureLabel: collisionFootprint.failureLabel,
      );
      return;
    }
    if (activeLayer is TerrainLayer) {
      final terrainFootprint = _resolveTerrainFootprint(emitErrors: true);
      if (terrainFootprint == null) return;
      _eraseTerrainPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: terrainFootprint.size,
        failureLabel: terrainFootprint.failureLabel,
      );
      return;
    }
    if (activeLayer is PathLayer) {
      final pathFootprint = _resolvePathFootprint();
      _erasePathPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: pathFootprint.size,
        failureLabel: pathFootprint.failureLabel,
      );
      return;
    }
    if (activeLayer is SurfaceLayer) {
      try {
        final erased = _surfacePaintingController.erase(
          map: map,
          targetLayerId: layerId,
          pos: pos,
        );
        if (!erased.changed) {
          state = state.copyWith(errorMessage: null);
          return;
        }
        _applyMapMutation(
          previousMap: map,
          updatedMap: erased.map,
          preferredActiveLayerId: erased.layerId,
          statusMessage: 'Surface placement erased',
          partOfStroke: true,
        );
      } catch (e) {
        _setPaintError('Failed to erase surface: $e');
      }
      return;
    }
    _setPaintError('Active layer "${activeLayer.name}" is not editable');
  }

  MapWarp? getSelectedWarp() {
    return _warpEditingService.findSelectedWarp(
      state.activeMap,
      state.selectedWarpId,
    );
  }

  MapConnection? getMapConnection(MapConnectionDirection direction) {
    return _mapConnectionEditingService.findConnection(
      state.activeMap,
      direction,
    );
  }

  MapEntity? getSelectedEntity() {
    return _entityEditingService.findSelectedEntity(
      state.activeMap,
      state.selectedEntityId,
    );
  }

  MapTrigger? getSelectedTrigger() {
    return _triggerEditingService.findSelectedTrigger(
      state.activeMap,
      state.selectedTriggerId,
    );
  }

  MapEventDefinition? getSelectedMapEvent() {
    final map = state.activeMap;
    final selectedMapEventId = state.selectedMapEventId;
    if (map == null || selectedMapEventId == null) {
      return null;
    }
    return findMapEventById(map, selectedMapEventId);
  }

  void placeOrSelectMapEventAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = findMapEventAtPos(
      map,
      pos.x,
      pos.y,
      preferredLayerId: state.activeLayerId,
    );
    if (existing != null) {
      selectMapEvent(existing.id);
      return;
    }
    addMapEventAt(pos);
  }

  void addMapEventAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = _resolveEventPlacementLayerId(map);
    if (layerId == null) {
      state = state.copyWith(
        errorMessage: 'No layer available to place a map event',
      );
      return;
    }
    final eventId = _generateUniqueMapEventId(map);
    final created = MapEventDefinition(
      id: eventId,
      title: eventId,
      position: EventPosition(layerId: layerId, x: pos.x, y: pos.y),
      pages: const [
        MapEventPage(
          pageNumber: 0,
          message: '',
        ),
      ],
    );
    try {
      final updated = addMapEventToMap(map, event: created);
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: created.id,
        statusMessage: 'Event "${created.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create event: $e');
    }
  }

  void selectMapEvent(String? eventId) {
    final map = state.activeMap;
    if (map == null) return;
    if (eventId == null) {
      state = state.copyWith(
        selectedMapEventId: null,
        errorMessage: null,
      );
      return;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Event not found: $eventId');
      return;
    }
    state = state.copyWith(
      selectedMapEventId: event.id,
      errorMessage: null,
    );
  }

  void updateSelectedMapEvent({
    required String id,
    required String title,
    required MapEventType type,
    required String layerId,
    required int x,
    required int y,
    required List<MapEventPage> pages,
  }) {
    final selectedMapEventId = state.selectedMapEventId;
    if (selectedMapEventId == null) return;
    updateMapEvent(
      eventId: selectedMapEventId,
      id: id,
      title: title,
      type: type,
      position: EventPosition(layerId: layerId, x: x, y: y),
      pages: pages,
    );
  }

  void updateMapEvent({
    required String eventId,
    String? id,
    String? title,
    MapEventType? type,
    EventPosition? position,
    List<MapEventPage>? pages,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = updateMapEventOnMap(
        map,
        eventId: eventId,
        id: id,
        title: title,
        type: type,
        position: position,
        pages: pages,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId:
            id?.trim().isNotEmpty == true ? id!.trim() : eventId,
        statusMessage: 'Event updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update event: $e');
    }
  }

  void deleteSelectedMapEvent() {
    final selectedMapEventId = state.selectedMapEventId;
    if (selectedMapEventId == null) return;
    deleteMapEvent(selectedMapEventId);
  }

  void deleteMapEvent(String eventId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = removeMapEventFromMap(
        map,
        eventId: eventId,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: state.selectedMapEventId == eventId
            ? null
            : state.selectedMapEventId,
        statusMessage: 'Event deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete event: $e');
    }
  }

  void placeOrSelectEntityAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _entityEditingService.findEntityAtPos(map, pos);
    if (existing != null) {
      selectEntity(existing.id);
      return;
    }
    addEntityAt(
      pos,
      kind: state.selectedEntityKind,
    );
  }

  void addEntityAt(
    GridPos pos, {
    required MapEntityKind kind,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _entityEditingService.addEntityAt(
        map,
        pos,
        kind: kind,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: result.createdEntity.id,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity "${result.createdEntity.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create entity: $e');
    }
  }

  void selectEntity(String? entityId) {
    final map = state.activeMap;
    if (map == null) return;
    if (entityId == null) {
      state = state.copyWith(
        selectedEntityId: null,
        npcWaypointPlacementEntityId: null,
        errorMessage: null,
      );
      return;
    }
    final entity = _entityEditingService.findSelectedEntity(map, entityId);
    if (entity == null) {
      state = state.copyWith(errorMessage: 'Entity not found: $entityId');
      return;
    }
    state = state.copyWith(
      selectedEntityId: entity.id,
      selectedEntityKind: entity.kind,
      npcWaypointPlacementEntityId:
          state.npcWaypointPlacementEntityId == entity.id
              ? state.npcWaypointPlacementEntityId
              : null,
      errorMessage: null,
    );
  }

  /// Active le mode "placement waypoint" sur l'entité NPC sélectionnée.
  ///
  /// Ce mode est volontairement porté par l'état éditeur (et non local panel),
  /// afin que le canvas puisse router le clic map de manière explicite.
  bool startNpcWaypointPlacementForSelectedEntity() {
    final map = state.activeMap;
    final selectedEntityId = state.selectedEntityId;
    if (map == null || selectedEntityId == null || selectedEntityId.isEmpty) {
      return false;
    }
    final entity =
        _entityEditingService.findSelectedEntity(map, selectedEntityId);
    if (entity == null || entity.kind != MapEntityKind.npc) {
      state = state.copyWith(
        npcWaypointPlacementEntityId: null,
        errorMessage: 'Waypoint placement requires a selected NPC.',
      );
      return false;
    }
    final movement = entity.npc?.movement ?? const MapEntityNpcMovementConfig();
    if (movement.mode != MapEntityNpcMovementMode.patrol) {
      state = state.copyWith(
        npcWaypointPlacementEntityId: null,
        errorMessage: 'Waypoint placement requires NPC movement mode "patrol".',
      );
      return false;
    }
    state = state.copyWith(
      npcWaypointPlacementEntityId: entity.id,
      statusMessage: 'Waypoint placement enabled for "${entity.id}"',
      errorMessage: null,
    );
    return true;
  }

  /// Désactive explicitement le mode placement waypoint.
  void cancelNpcWaypointPlacement({String? statusMessage}) {
    if (state.npcWaypointPlacementEntityId == null) {
      return;
    }
    state = state.copyWith(
      npcWaypointPlacementEntityId: null,
      statusMessage: statusMessage ?? 'Waypoint placement disabled',
      errorMessage: null,
    );
  }

  /// Traite un clic map en mode placement waypoint.
  ///
  /// Retourne `true` si le clic a été consommé par ce mode.
  /// Retourne `false` si aucun mode placement actif (ou session invalide).
  bool addNpcWaypointAt(GridPos position) {
    final placementEntityId = state.npcWaypointPlacementEntityId;
    if (placementEntityId == null || placementEntityId.trim().isEmpty) {
      return false;
    }
    final map = state.activeMap;
    if (map == null) {
      cancelNpcWaypointPlacement(statusMessage: 'Waypoint placement cancelled');
      return false;
    }
    final entity = _entityEditingService.findSelectedEntity(
      map,
      placementEntityId,
    );
    if (entity == null || entity.kind != MapEntityKind.npc) {
      cancelNpcWaypointPlacement(
        statusMessage: 'Waypoint placement cancelled (NPC no longer valid)',
      );
      return false;
    }
    final npc = entity.npc ?? const MapEntityNpcData();
    if (npc.movement.mode != MapEntityNpcMovementMode.patrol) {
      cancelNpcWaypointPlacement(
        statusMessage: 'Waypoint placement cancelled (NPC not in patrol mode)',
      );
      return false;
    }

    final nextWaypoints = <GridPos>[
      ...npc.movement.waypoints,
      position,
    ];
    final nextNpc = npc.copyWith(
      movement: npc.movement.copyWith(waypoints: nextWaypoints),
    );
    updateEntity(
      entityId: entity.id,
      npc: nextNpc,
    );
    state = state.copyWith(
      npcWaypointPlacementEntityId: entity.id,
      statusMessage:
          'Waypoint (${position.x}, ${position.y}) added to "${entity.id}"',
      errorMessage: null,
    );
    return true;
  }

  void selectEntityKind(MapEntityKind kind) {
    state = _mapSelectionController.selectEntityKind(
      current: state,
      kind: kind,
    );
  }

  void updateSelectedEntity({
    required String id,
    required String name,
    required MapEntityKind kind,
    required int x,
    required int y,
    required int width,
    required int height,
    required Map<String, String> properties,
    required bool blocksMovement,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
    MapEntityEditorVisual? editorVisual,
  }) {
    final selectedEntityId = state.selectedEntityId;
    if (selectedEntityId == null) return;
    updateEntity(
      entityId: selectedEntityId,
      id: id,
      name: name,
      kind: kind,
      pos: GridPos(x: x, y: y),
      size: GridSize(width: width, height: height),
      properties: properties,
      blocksMovement: blocksMovement,
      npc: npc,
      sign: sign,
      item: item,
      spawn: spawn,
      editorVisual: editorVisual,
    );
  }

  void updateEntity({
    required String entityId,
    String? id,
    String? name,
    MapEntityKind? kind,
    GridPos? pos,
    GridSize? size,
    Map<String, String>? properties,
    bool? blocksMovement,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
    MapEntityEditorVisual? editorVisual,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _entityEditingService.updateEntity(
        map,
        entityId: entityId,
        id: id,
        name: name,
        kind: kind,
        pos: pos,
        size: size,
        properties: properties,
        blocksMovement: blocksMovement,
        npc: npc,
        sign: sign,
        item: item,
        spawn: spawn,
        editorVisual: editorVisual,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: result.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity updated',
      );
      if (kind != null && kind != state.selectedEntityKind) {
        state = state.copyWith(selectedEntityKind: kind);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update entity: $e');
    }
  }

  void deleteSelectedEntity() {
    final selectedEntityId = state.selectedEntityId;
    if (selectedEntityId == null) return;
    deleteEntity(selectedEntityId);
  }

  void deleteEntity(String entityId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _entityEditingService.deleteEntity(
        map,
        entityId: entityId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId:
            state.selectedEntityId == entityId ? null : state.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete entity: $e');
    }
  }

  void placeOrSelectTriggerAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _triggerEditingService.findTriggerAtPos(map, pos);
    if (existing != null) {
      selectTrigger(existing.id);
      return;
    }
    addTriggerAt(pos);
  }

  void addTriggerAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _triggerEditingService.addTriggerAt(map, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: result.createdTrigger.id,
        statusMessage: 'Trigger "${result.createdTrigger.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create trigger: $e');
    }
  }

  void selectTrigger(String? triggerId) {
    final map = state.activeMap;
    if (map == null) return;
    if (triggerId == null) {
      state = state.copyWith(
        selectedTriggerId: null,
        errorMessage: null,
      );
      return;
    }
    final trigger = _triggerEditingService.findSelectedTrigger(map, triggerId);
    if (trigger == null) {
      state = state.copyWith(errorMessage: 'Trigger not found: $triggerId');
      return;
    }
    state = state.copyWith(
      selectedTriggerId: trigger.id,
      errorMessage: null,
    );
  }

  void updateSelectedTrigger({
    required String id,
    required String name,
    required TriggerType type,
    required int x,
    required int y,
    required int width,
    required int height,
    required Map<String, String> properties,
  }) {
    final selectedTriggerId = state.selectedTriggerId;
    if (selectedTriggerId == null) return;
    updateTrigger(
      triggerId: selectedTriggerId,
      id: id,
      name: name,
      type: type,
      area: MapRect(
        pos: GridPos(x: x, y: y),
        size: GridSize(width: width, height: height),
      ),
      properties: properties,
    );
  }

  void updateTrigger({
    required String triggerId,
    String? id,
    String? name,
    TriggerType? type,
    MapRect? area,
    Map<String, String>? properties,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _triggerEditingService.updateTrigger(
        map,
        triggerId: triggerId,
        id: id,
        name: name,
        type: type,
        area: area,
        properties: properties,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: result.selectedTriggerId,
        statusMessage: 'Trigger updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update trigger: $e');
    }
  }

  void deleteSelectedTrigger() {
    final selectedTriggerId = state.selectedTriggerId;
    if (selectedTriggerId == null) return;
    deleteTrigger(selectedTriggerId);
  }

  void deleteTrigger(String triggerId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _triggerEditingService.deleteTrigger(
        map,
        triggerId: triggerId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId == triggerId
            ? null
            : state.selectedTriggerId,
        statusMessage: 'Trigger deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete trigger: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Gameplay zones
  // ---------------------------------------------------------------------------

  MapGameplayZone? getSelectedGameplayZone() {
    return _gameplayZoneEditingService.findSelectedZone(
      state.activeMap,
      state.selectedGameplayZoneId,
    );
  }

  void placeOrSelectGameplayZoneAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _gameplayZoneEditingService.findZoneAtPos(map, pos);
    if (existing != null) {
      selectGameplayZone(existing.id);
      return;
    }
    addGameplayZoneAt(pos);
  }

  void addGameplayZoneAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _gameplayZoneEditingService.addZoneAt(map, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone "${result.createdZone.id}" created',
      );
      state = state.copyWith(selectedGameplayZoneId: result.createdZone.id);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create zone: $e');
    }
  }

  void selectGameplayZone(String? zoneId) {
    final map = state.activeMap;
    if (map == null) return;
    if (zoneId == null) {
      state = state.copyWith(selectedGameplayZoneId: null);
      return;
    }
    final zone = _gameplayZoneEditingService.findSelectedZone(map, zoneId);
    if (zone == null) {
      state = state.copyWith(errorMessage: 'Zone not found: $zoneId');
      return;
    }
    state = state.copyWith(selectedGameplayZoneId: zone.id);
  }

  void updateSelectedGameplayZone({
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    int? priority,
    Object? encounter,
    Object? movement,
    Object? movementEffect,
    Object? hazard,
    Object? special,
  }) {
    final selectedZoneId = state.selectedGameplayZoneId;
    if (selectedZoneId == null) return;
    updateGameplayZone(
      zoneId: selectedZoneId,
      id: id,
      name: name,
      kind: kind,
      area: area,
      priority: priority,
      encounter: encounter,
      movement: movement,
      movementEffect: movementEffect,
      hazard: hazard,
      special: special,
    );
  }

  void updateGameplayZone({
    required String zoneId,
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    int? priority,
    Object? encounter,
    Object? movement,
    Object? movementEffect,
    Object? hazard,
    Object? special,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _gameplayZoneEditingService.updateZone(
        map,
        zoneId: zoneId,
        id: id,
        name: name,
        kind: kind,
        area: area,
        priority: priority,
        encounter: encounter,
        movement: movement,
        movementEffect: movementEffect,
        hazard: hazard,
        special: special,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone updated',
      );
      state = state.copyWith(selectedGameplayZoneId: result.selectedZoneId);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update zone: $e');
    }
  }

  bool applyGeneratedGameplayZones({
    required List<MapGameplayZone> zones,
    String? selectZoneId,
    String? statusMessage,
  }) {
    final map = state.activeMap;
    if (map == null || zones.isEmpty) return false;
    try {
      var updatedMap = map;
      for (final zone in zones) {
        updatedMap = addGameplayZoneToMap(updatedMap, zone: zone);
      }

      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: statusMessage ??
            'Generated ${zones.length} gameplay ${zones.length == 1 ? 'zone' : 'zones'}',
      );

      final requestedSelection = selectZoneId?.trim();
      final hasRequestedSelection = requestedSelection != null &&
          requestedSelection.isNotEmpty &&
          updatedMap.gameplayZones.any(
            (zone) => zone.id == requestedSelection,
          );
      state = state.copyWith(
        selectedGameplayZoneId:
            hasRequestedSelection ? requestedSelection : zones.first.id,
      );
      return true;
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to apply generated zones: $e');
      return false;
    }
  }

  void deleteSelectedGameplayZone() {
    final selectedZoneId = state.selectedGameplayZoneId;
    if (selectedZoneId == null) return;
    deleteGameplayZone(selectedZoneId);
  }

  void deleteGameplayZone(String zoneId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated =
          _gameplayZoneEditingService.deleteZone(map, zoneId: zoneId);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone deleted',
      );
      if (state.selectedGameplayZoneId == zoneId) {
        state = state.copyWith(selectedGameplayZoneId: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete zone: $e');
    }
  }

  // Drag-to-draw ─────────────────────────────────────────────────────────────

  /// Met à jour l'aire de tracé en cours (fantôme visible sur le canvas).
  void setGameplayZoneDraftArea(MapRect area) {
    state = state.copyWith(gameplayZoneDraftArea: area);
  }

  /// Valide le tracé et crée la zone persistée.
  void commitGameplayZoneDraft() {
    final draft = state.gameplayZoneDraftArea;
    if (draft == null) return;
    state = state.copyWith(gameplayZoneDraftArea: null);
    final map = state.activeMap;
    if (map == null) return;
    // Clamp la zone dans les limites de la map
    final clampedArea = _clampRectToMap(draft, map.size);
    if (clampedArea == null) return;
    try {
      final result =
          _gameplayZoneEditingService.addZoneInRect(map, clampedArea);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone "${result.createdZone.id}" créée',
      );
      state = state.copyWith(selectedGameplayZoneId: result.createdZone.id);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create zone: $e');
    }
  }

  /// Annule le tracé en cours sans créer de zone.
  void cancelGameplayZoneDraft() {
    state = state.copyWith(gameplayZoneDraftArea: null);
  }

  static MapRect? _clampRectToMap(MapRect rect, GridSize mapSize) {
    final x = rect.pos.x.clamp(0, mapSize.width - 1);
    final y = rect.pos.y.clamp(0, mapSize.height - 1);
    final w = rect.size.width.clamp(1, mapSize.width - x);
    final h = rect.size.height.clamp(1, mapSize.height - y);
    if (w <= 0 || h <= 0) return null;
    return MapRect(
        pos: GridPos(x: x, y: y), size: GridSize(width: w, height: h));
  }

  void placeOrSelectWarpAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _warpEditingService.findWarpAtPos(map, pos);
    if (existing != null) {
      selectWarp(existing.id);
      return;
    }
    addWarpAt(pos);
  }

  void addWarpAt(GridPos pos) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) return;
    try {
      final result = _warpEditingService.addWarpAt(map, project, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: result.createdWarp.id,
        statusMessage: 'Warp "${result.createdWarp.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create warp: $e');
    }
  }

  void selectWarp(String? warpId) {
    final map = state.activeMap;
    if (map == null) return;
    if (warpId == null) {
      state = state.copyWith(
        selectedWarpId: null,
        errorMessage: null,
      );
      return;
    }
    final warp = _warpEditingService.findSelectedWarp(map, warpId);
    if (warp == null) {
      state = state.copyWith(errorMessage: 'Warp not found: $warpId');
      return;
    }
    state = state.copyWith(
      selectedWarpId: warp.id,
      errorMessage: null,
    );
  }

  void updateSelectedWarp({
    required String id,
    required String targetMapId,
    required int targetPosX,
    required int targetPosY,
    required MapWarpTriggerMode triggerMode,
    required List<EntityFacing> allowedApproachFacings,
    required WarpTriggerPadding triggerPadding,
  }) {
    final selectedWarpId = state.selectedWarpId;
    if (selectedWarpId == null) return;
    updateWarp(
      warpId: selectedWarpId,
      id: id,
      targetMapId: targetMapId,
      targetPos: GridPos(x: targetPosX, y: targetPosY),
      triggerMode: triggerMode,
      allowedApproachFacings: allowedApproachFacings,
      triggerPadding: triggerPadding,
    );
  }

  Future<void> createReciprocalWarpForSelectedWarp() async {
    final fs = _projectWorkspace;
    final project = state.project;
    final sourceMap = state.activeMap;
    final selectedWarpId = state.selectedWarpId;
    if (fs == null) {
      state = state.copyWith(errorMessage: 'No project filesystem available');
      return;
    }
    if (project == null) {
      state = state.copyWith(errorMessage: 'No project loaded');
      return;
    }
    if (sourceMap == null) {
      state = state.copyWith(errorMessage: 'No active map loaded');
      return;
    }
    if (selectedWarpId == null) {
      state = state.copyWith(errorMessage: 'No warp selected');
      return;
    }
    try {
      final selectedWarp =
          _warpEditingService.requireSelectedWarp(sourceMap, selectedWarpId);
      final result = await _warpEditingService.createReciprocalWarp(
        fs,
        project,
        sourceMap: sourceMap,
        sourceWarp: selectedWarp,
      );

      if (result.targetIsSourceMap) {
        _applyMapMutation(
          previousMap: sourceMap,
          updatedMap: result.updatedTargetMap,
          preferredActiveLayerId: state.activeLayerId,
          preferredSelectedWarpId: selectedWarpId,
          statusMessage:
              'Return warp "${result.reciprocalWarp.id}" created in map "${result.updatedTargetMap.id}"',
        );
      } else {
        state = state.copyWith(
          statusMessage:
              'Return warp "${result.reciprocalWarp.id}" created in map "${result.updatedTargetMap.id}"',
          errorMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create return warp: $e');
    }
  }

  void updateWarp({
    required String warpId,
    String? id,
    GridPos? pos,
    String? targetMapId,
    GridPos? targetPos,
    MapWarpTriggerMode? triggerMode,
    List<EntityFacing>? allowedApproachFacings,
    WarpTriggerPadding? triggerPadding,
  }) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) return;
    try {
      final result = _warpEditingService.updateWarp(
        map,
        project,
        warpId: warpId,
        id: id,
        pos: pos,
        targetMapId: targetMapId,
        targetPos: targetPos,
        triggerMode: triggerMode,
        allowedApproachFacings: allowedApproachFacings,
        triggerPadding: triggerPadding,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: result.selectedWarpId,
        statusMessage: 'Warp updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update warp: $e');
    }
  }

  void deleteSelectedWarp() {
    final selectedWarpId = state.selectedWarpId;
    if (selectedWarpId == null) return;
    deleteWarp(selectedWarpId);
  }

  void deleteWarp(String warpId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _warpEditingService.deleteWarp(
        map,
        warpId: warpId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId:
            state.selectedWarpId == warpId ? null : state.selectedWarpId,
        statusMessage: 'Warp deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete warp: $e');
    }
  }

  Future<void> saveMapConnection({
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final map = state.activeMap;
    if (fs == null || project == null || map == null) return;
    try {
      final updatedMap = await _mapConnectionEditingService.upsertConnection(
        fs,
        project,
        sourceMap: map,
        direction: direction,
        targetMapId: targetMapId,
        offset: offset,
      );
      final targetEntry = _mapConnectionEditingService.resolveTargetMapEntry(
        project,
        targetMapId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        statusMessage:
            '${direction.name.toUpperCase()} connection saved to "${targetEntry.name}"',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save map connection: $e',
      );
    }
  }

  void deleteMapConnection(MapConnectionDirection direction) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = _mapConnectionEditingService.deleteConnection(
        map,
        direction: direction,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        statusMessage: '${direction.name.toUpperCase()} connection deleted',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete map connection: $e',
      );
    }
  }

  Future<void> openConnectedMap(MapConnectionDirection direction) async {
    final project = state.project;
    final connection = getMapConnection(direction);
    if (project == null || connection == null) {
      state = state.copyWith(
        errorMessage: 'No ${direction.name} connection available',
      );
      return;
    }
    try {
      endMapStroke();
      final targetEntry = _mapConnectionEditingService.resolveTargetMapEntry(
        project,
        connection.targetMapId,
      );
      await loadMap(targetEntry.relativePath);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to open connected map: $e',
      );
    }
  }

  MapToolPreview? resolveMapToolPreview({
    GridPos? hoveredTile,
    required Map<String, int> tilesetColumnsById,
  }) {
    if (hoveredTile == null) return null;
    final tool = state.activeTool;
    if (tool != EditorToolType.tilePaint &&
        tool != EditorToolType.terrainPaint &&
        tool != EditorToolType.collisionPaint &&
        tool != EditorToolType.eraser) {
      return null;
    }
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) return null;
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) return null;

    if (tool == EditorToolType.tilePaint) {
      if (activeLayer is! TileLayer) return null;
      final resolvedBrush = _resolveActiveBrushPattern(
        tilesetColumnsById: tilesetColumnsById,
        emitErrors: false,
      );
      if (resolvedBrush == null) return null;
      final compatibility = _resolveLayerBrushCompatibility(
        activeLayer,
        resolvedBrush.tilesetId,
      );
      final validity = compatibility == _BrushLayerCompatibility.incompatible
          ? MapToolPreviewValidity.invalid
          : MapToolPreviewValidity.valid;
      return MapToolPreview.paint(
        origin: hoveredTile,
        size: resolvedBrush.pattern.size,
        tilesetId: resolvedBrush.tilesetId,
        tiles: resolvedBrush.pattern.tiles,
        validity: validity,
      );
    }

    if (tool == EditorToolType.terrainPaint) {
      if (activeLayer is TerrainLayer) {
        final terrainFootprint = _resolveTerrainFootprint(emitErrors: false);
        if (terrainFootprint == null) return null;
        return MapToolPreview.terrainPaint(
          origin: hoveredTile,
          size: terrainFootprint.size,
          terrain: state.selectedTerrainType,
          validity: MapToolPreviewValidity.valid,
        );
      }
      if (activeLayer is PathLayer) {
        final pathFootprint = _resolvePathFootprint();
        return MapToolPreview.pathPaint(
          origin: hoveredTile,
          size: pathFootprint.size,
          validity: MapToolPreviewValidity.valid,
        );
      }
      return null;
    }

    if (tool == EditorToolType.collisionPaint) {
      if (activeLayer is! CollisionLayer) return null;
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: false);
      if (collisionFootprint == null) return null;
      return MapToolPreview.collisionPaint(
        origin: hoveredTile,
        size: collisionFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }

    if (activeLayer is TileLayer) {
      final erasePattern = _resolveErasePattern(emitErrors: false);
      if (erasePattern == null) return null;
      return MapToolPreview.erase(
        origin: hoveredTile,
        size: erasePattern.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is CollisionLayer) {
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: false);
      if (collisionFootprint == null) return null;
      return MapToolPreview.collisionErase(
        origin: hoveredTile,
        size: collisionFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is TerrainLayer) {
      final terrainFootprint = _resolveTerrainFootprint(emitErrors: false);
      if (terrainFootprint == null) return null;
      return MapToolPreview.terrainErase(
        origin: hoveredTile,
        size: terrainFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is PathLayer) {
      final pathFootprint = _resolvePathFootprint();
      return MapToolPreview.pathErase(
        origin: hoveredTile,
        size: pathFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    return null;
  }

  void paintSelectedTileAt(GridPos pos) {
    beginMapStroke();
    paintSelectedBrushAt(pos, tilesetColumnsById: const {});
    endMapStroke();
  }

  void beginMapStroke() {
    state = _mapEditingController.beginStroke(state);
  }

  void endMapStroke() {
    state = _mapEditingController.endStroke(state);
  }

  void undoMap() {
    endMapStroke();
    final restored = _mapEditingController.undo(state);
    if (restored == null) return;
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      restored,
    );
  }

  void redoMap() {
    endMapStroke();
    final restored = _mapEditingController.redo(state);
    if (restored == null) return;
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      restored,
    );
  }

  EditorBrush _clearBrushIfTilesetRemoved(EditorBrush brush, String tilesetId) {
    if (brush is TileEditorBrush && brush.tilesetId == tilesetId) {
      return const EditorBrush.none();
    }
    if (brush is PaletteEntryEditorBrush && brush.tilesetId == tilesetId) {
      return const EditorBrush.none();
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element != null && element.tilesetId == tilesetId) {
        return const EditorBrush.none();
      }
    }
    return brush;
  }

  _PaintPattern _buildPatternFromSource(
    TilesetSourceRect source, {
    required int tilesetColumns,
  }) {
    final tiles = List<int>.filled(
      source.width * source.height,
      0,
      growable: false,
    );
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final sourceX = source.x + x;
        final sourceY = source.y + y;
        tiles[y * source.width + x] = sourceY * tilesetColumns + sourceX + 1;
      }
    }
    return _PaintPattern(
      size: GridSize(width: source.width, height: source.height),
      tiles: tiles,
    );
  }

  _ResolvedBrushPattern? _resolveActiveBrushPattern({
    required Map<String, int> tilesetColumnsById,
    required bool emitErrors,
  }) {
    final brush = state.activeBrush;
    if (brush is NoEditorBrush) return null;

    if (brush is TileEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError('Selected tile brush does not have a valid tileset');
        }
        return null;
      }
      if (brush.tileId <= 0) {
        if (emitErrors) {
          _setPaintError('Selected tile brush is invalid');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'tile',
        pattern: _PaintPattern(
          size: const GridSize(width: 1, height: 1),
          tiles: <int>[brush.tileId],
        ),
      );
    }

    if (brush is PaletteEntryEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError(
            'Selected palette brush does not have a valid tileset',
          );
        }
        return null;
      }
      final entry = getPaletteEntryById(
        tilesetId: tilesetId,
        entryId: brush.entryId,
      );
      if (entry == null) {
        if (emitErrors) {
          _setPaintError('Selected palette entry is no longer available');
        }
        return null;
      }
      final tilesetColumns = tilesetColumnsById[tilesetId] ?? 0;
      if (tilesetColumns <= 0) {
        if (emitErrors) {
          _setPaintError('Selected brush tileset image is not available');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'palette entry',
        pattern: _buildPatternFromSource(
          entry.frames.primarySource,
          tilesetColumns: tilesetColumns,
        ),
      );
    }

    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element == null) {
        if (emitErrors) {
          _setPaintError('Selected project element is no longer available');
        }
        return null;
      }
      final tilesetId = element.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError('Selected project element does not have a tileset');
        }
        return null;
      }
      final tilesetColumns = tilesetColumnsById[tilesetId] ?? 0;
      if (tilesetColumns <= 0) {
        if (emitErrors) {
          _setPaintError('Selected brush tileset image is not available');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'element',
        pattern: _buildPatternFromSource(
          element.frames.primarySource,
          tilesetColumns: tilesetColumns,
        ),
      );
    }

    return null;
  }

  _ErasePattern? _resolveErasePattern({
    required bool emitErrors,
  }) {
    final footprint = _resolveBrushFootprint(emitErrors: emitErrors);
    if (footprint == null) return null;
    return _ErasePattern(
      size: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  _ResolvedBrushFootprint? _resolveCollisionFootprint({
    required bool emitErrors,
  }) {
    if (state.collisionBrushSizeMode == CollisionBrushSizeMode.singleTile) {
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    return _resolveBrushFootprint(emitErrors: emitErrors);
  }

  _ResolvedBrushFootprint? _resolveTerrainFootprint({
    required bool emitErrors,
  }) {
    final footprint = _terrainPaintingCoordinator.resolveFootprint(
      terrain: state.selectedTerrainType,
    );
    return _ResolvedBrushFootprint(
      size: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  _ResolvedBrushFootprint? _resolveBrushFootprint({
    required bool emitErrors,
  }) {
    final brush = state.activeBrush;
    if (brush is NoEditorBrush) {
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    if (brush is TileEditorBrush) {
      if (brush.tileId <= 0) {
        if (emitErrors) {
          _setPaintError('Selected tile brush is invalid');
        }
        return null;
      }
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    if (brush is PaletteEntryEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError(
              'Selected palette brush does not have a valid tileset');
        }
        return null;
      }
      final entry = getPaletteEntryById(
        tilesetId: tilesetId,
        entryId: brush.entryId,
      );
      if (entry == null) {
        if (emitErrors) {
          _setPaintError('Selected palette entry is no longer available');
        }
        return null;
      }
      return _ResolvedBrushFootprint(
        size: GridSize(
          width: entry.frames.primarySource.width,
          height: entry.frames.primarySource.height,
        ),
        failureLabel: 'palette entry',
      );
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element == null) {
        if (emitErrors) {
          _setPaintError('Selected project element is no longer available');
        }
        return null;
      }
      return _ResolvedBrushFootprint(
        size: GridSize(
          width: element.frames.primarySource.width,
          height: element.frames.primarySource.height,
        ),
        failureLabel: 'element',
      );
    }
    return null;
  }

  void _paintPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required _PaintPattern pattern,
    required String failureLabel,
  }) {
    try {
      final useCase = ref.read(paintTilePatternOnMapUseCaseProvider);
      final painted = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: pattern.size,
        tiles: pattern.tiles,
        clipToMapBounds: true,
      );
      final project = state.project;
      final committed = project == null
          ? painted
          : _placedElementInstanceIndexer.syncLayer(
              map: painted,
              project: project,
              layerId: layerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint $failureLabel: $e');
    }
  }

  void _erasePattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final project = state.project;
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseTileOnMapUseCaseProvider);
        final erased = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        final committed = project == null
            ? erased
            : _placedElementInstanceIndexer.syncLayer(
                map: erased,
                project: project,
                layerId: layerId,
              );
        _applyMapMutation(
          previousMap: map,
          updatedMap: committed,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }

      final useCase = ref.read(eraseTilePatternOnMapUseCaseProvider);
      final erased = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      final committed = project == null
          ? erased
          : _placedElementInstanceIndexer.syncLayer(
              map: erased,
              project: project,
              layerId: layerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase $failureLabel: $e');
    }
  }

  void _paintCollisionPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(paintCollisionOnMapUseCaseProvider);
        final painted = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        _applyMapMutation(
          previousMap: map,
          updatedMap: painted,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }
      final useCase = ref.read(paintCollisionPatternOnMapUseCaseProvider);
      final painted = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: painted,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint collision $failureLabel: $e');
    }
  }

  void _eraseCollisionPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseCollisionOnMapUseCaseProvider);
        final erased = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        _applyMapMutation(
          previousMap: map,
          updatedMap: erased,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }
      final useCase = ref.read(eraseCollisionPatternOnMapUseCaseProvider);
      final erased = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase collision $failureLabel: $e');
    }
  }

  void _paintTerrainPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required TerrainType terrain,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final committed = _terrainPaintingCoordinator.paint(
        map: map,
        layerId: layerId,
        pos: pos,
        terrain: terrain,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint terrain $failureLabel: $e');
    }
  }

  void _paintPathPattern({
    required MapData map,
    required MapData previousMap,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final committed = _pathLayerEditingCoordinator.paint(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: previousMap,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint path $failureLabel: $e');
    }
  }

  void _eraseTerrainPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final erased = _terrainPaintingCoordinator.erase(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase terrain $failureLabel: $e');
    }
  }

  void _erasePathPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      final erased = _pathLayerEditingCoordinator.erase(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to erase path $failureLabel: $e');
    }
  }

  void _setPaintError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  _ActiveTileLayerContext? _resolveActiveTileLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active tile layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! TileLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a tile layer');
      }
      return null;
    }
    return _ActiveTileLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _ActiveCollisionLayerContext? _resolveActiveCollisionLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active collision layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! CollisionLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a collision layer');
      }
      return null;
    }
    return _ActiveCollisionLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _ActiveTerrainLayerContext? _resolveActiveTerrainLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active terrain layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! TerrainLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a terrain layer');
      }
      return null;
    }
    return _ActiveTerrainLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  PathLayerBrushFootprint _resolvePathFootprint() {
    return _pathLayerEditingCoordinator.resolveFootprint();
  }

  _ActivePathLayerContext? _resolveActivePathLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active path layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! PathLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a path layer');
      }
      return null;
    }
    return _ActivePathLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _BrushLayerCompatibility _resolveLayerBrushCompatibility(
    TileLayer activeLayer,
    String brushTilesetId,
  ) {
    final currentTilesetId = activeLayer.tilesetId?.trim();
    if (currentTilesetId == brushTilesetId) {
      return _BrushLayerCompatibility.compatible;
    }
    if (currentTilesetId == null ||
        currentTilesetId.isEmpty ||
        _isTileLayerEmpty(activeLayer)) {
      return _BrushLayerCompatibility.rebindable;
    }
    return _BrushLayerCompatibility.incompatible;
  }

  MapData? _prepareMapForBrushTileset({
    required MapData map,
    required String layerId,
    required TileLayer activeLayer,
    required String brushTilesetId,
  }) {
    final compatibility = _resolveLayerBrushCompatibility(
      activeLayer,
      brushTilesetId,
    );
    if (compatibility == _BrushLayerCompatibility.compatible) {
      return map;
    }
    if (compatibility == _BrushLayerCompatibility.incompatible) {
      _setPaintError(
        'Layer "${activeLayer.name}" already contains tiles from another source',
      );
      return null;
    }

    final updatedLayers = List<MapLayer>.from(map.layers, growable: false);
    final layerIndex = updatedLayers.indexWhere((layer) => layer.id == layerId);
    if (layerIndex < 0) {
      _setPaintError('Active layer not found: $layerId');
      return null;
    }
    final layer = updatedLayers[layerIndex];
    if (layer is! TileLayer) {
      _setPaintError('Active layer is not a tile layer');
      return null;
    }
    updatedLayers[layerIndex] = layer.copyWith(tilesetId: brushTilesetId);
    final updatedMap = map.copyWith(
      layers: updatedLayers,
      tilesetId: map.tilesetId.trim().isEmpty ? brushTilesetId : map.tilesetId,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: layerId,
      statusMessage: 'Layer "${activeLayer.name}" updated for current brush',
      partOfStroke: true,
    );
    state = state.copyWith(
      selectedTilesetEditorId: brushTilesetId,
      selectedTilesetElementGroupId: null,
      paletteCategoryFilter: null,
    );
    return updatedMap;
  }

  bool _isTileLayerEmpty(TileLayer layer) {
    for (final tile in layer.tiles) {
      if (tile != 0) return false;
    }
    return true;
  }

  void addMapLayer({
    required MapLayerKind kind,
    required String name,
    String? tileTilesetId,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(addMapLayerUseCaseProvider);
      int? insertIndex;
      final activeId = state.activeLayerId;
      if (activeId != null) {
        final idx = map.layers.indexWhere((layer) => layer.id == activeId);
        if (idx >= 0) {
          insertIndex = idx;
        }
      }
      final result = useCase.execute(
        map,
        kind: kind,
        name: name,
        tileTilesetId: tileTilesetId,
        insertIndex: insertIndex,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layer.id,
        statusMessage: 'Layer "${result.layer.name}" added',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add layer: $e');
    }
  }

  void addSurfaceLayer({
    String name = 'Surfaces',
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(addMapLayerUseCaseProvider);
      int? insertIndex;
      final activeId = state.activeLayerId;
      if (activeId != null) {
        final idx = map.layers.indexWhere((layer) => layer.id == activeId);
        if (idx >= 0) {
          insertIndex = idx;
        }
      }
      final result = useCase.executeSurface(
        map,
        name: name,
        insertIndex: insertIndex,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layer.id,
        statusMessage: 'Surface layer "${result.layer.name}" added',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add surface layer: $e');
    }
  }

  void renameMapLayer(String layerId, String name) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(renameMapLayerUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        name: name,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Layer renamed',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename layer: $e');
    }
  }

  void deleteMapLayer(String layerId) {
    final map = state.activeMap;
    if (map == null) return;
    final removedIndex = _findLayerIndexById(map, layerId);
    if (removedIndex < 0) return;
    try {
      final useCase = ref.read(deleteMapLayerUseCaseProvider);
      final updated = useCase.execute(map, layerId: layerId);
      final nextActiveLayerId = state.activeLayerId == layerId
          ? _editorMapSessionCoordinator.resolveFallbackLayerIdAfterDeletion(
              updated,
              removedIndex: removedIndex,
            )
          : _editorMapSessionCoordinator.resolveActiveLayerId(
              updated,
              preferredLayerId: state.activeLayerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: nextActiveLayerId,
        statusMessage: 'Layer deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete layer: $e');
    }
  }

  void deleteAllMapLayers() {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(deleteAllMapLayersUseCaseProvider);
      final updated = useCase.execute(map);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId:
            _editorMapSessionCoordinator.resolveActiveLayerId(updated),
        statusMessage: 'All layers removed',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove all layers: $e');
    }
  }

  void moveMapLayerUp(String layerId) {
    _moveMapLayer(layerId, -1);
  }

  void moveMapLayerDown(String layerId) {
    _moveMapLayer(layerId, 1);
  }

  void moveMapLayerForward(String layerId) {
    _moveMapLayer(layerId, 1);
  }

  void moveMapLayerBackward(String layerId) {
    _moveMapLayer(layerId, -1);
  }

  void _moveMapLayer(String layerId, int direction) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(moveMapLayerUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        direction: direction,
      );
      if (updated != map) {
        _applyMapMutation(
          previousMap: map,
          updatedMap: updated,
          preferredActiveLayerId: state.activeLayerId,
          statusMessage: 'Layer reordered',
        );
      } else {
        state = state.copyWith(errorMessage: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to reorder layer: $e');
    }
  }

  void reorderMapLayers(int oldIndex, int newIndex) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(reorderMapLayersUseCaseProvider);
      final updated = useCase.execute(
        map,
        oldIndex: oldIndex,
        newIndex: newIndex,
      );
      if (updated != map) {
        _applyMapMutation(
          previousMap: map,
          updatedMap: updated,
          preferredActiveLayerId: state.activeLayerId,
          statusMessage: 'Layer reordered',
        );
      } else {
        state = state.copyWith(errorMessage: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to reorder layer: $e');
    }
  }

  /// Places [layerId] before [beforeIndex] (0 = top of list, [layers.length] = bottom).
  void moveMapLayerBeforeIndex(String layerId, int beforeIndex) {
    final map = state.activeMap;
    if (map == null) return;
    final oldIndex = map.layers.indexWhere((layer) => layer.id == layerId);
    if (oldIndex < 0) return;
    reorderMapLayers(oldIndex, beforeIndex);
  }

  void setMapLayerVisibility(String layerId, bool isVisible) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(setMapLayerVisibilityUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        isVisible: isVisible,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: isVisible ? 'Layer shown' : 'Layer hidden',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update layer: $e');
    }
  }

  void setMapLayerOpacity(String layerId, double opacity) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(setMapLayerOpacityUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        opacity: opacity,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update layer opacity: $e');
    }
  }

  void selectTool(EditorToolType tool) {
    state = _mapSelectionController.selectTool(
      current: state,
      tool: tool,
    );
  }

  void selectTerrainType(TerrainType terrain) {
    state = _mapSelectionController.selectTerrainType(
      current: state,
      terrain: terrain,
    );
  }

  void selectTerrainPreset(String? presetId) {
    state = _mapSelectionController.selectTerrainPreset(
      current: state,
      preset: getTerrainPresetById(presetId),
    );
  }

  void selectPathPreset(String? presetId) {
    state = _mapSelectionController.selectPathPreset(
      current: state,
      preset: getPathPresetById(presetId),
    );
  }

  void selectSurfacePreset(String? presetId) {
    final preset = getSurfacePresetById(presetId);
    if (preset == null) {
      state = state.copyWith(errorMessage: 'Surface not found');
      return;
    }
    state = state.copyWith(
      selectedSurfacePresetId: preset.id,
      activeTool: EditorToolType.surfacePaint,
      statusMessage: 'Surface sélectionnée : ${preset.name}',
      errorMessage: null,
    );
  }

  void selectPathPresetForActivePathLayer(String? presetId) {
    final preset = getPathPresetById(presetId);
    if (preset == null) {
      state = state.copyWith(errorMessage: 'Path preset not found');
      return;
    }
    selectPathPreset(presetId);
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! PathLayer) {
      return;
    }
    assignPathPresetToActivePathLayer(preset.id);
  }

  void selectTerrainPaintMode({
    TerrainType? terrainType,
  }) {
    state = _mapSelectionController.selectTerrainPaintMode(
      current: state,
      terrainType: terrainType,
    );
  }

  void selectPathPaintMode() {
    state = _mapSelectionController.selectPathPaintMode(
      current: state,
      selectedPathPreset: getSelectedPathPreset(),
    );
  }

  void selectSurfacePaintMode() {
    if (getSelectedSurfacePreset() == null) {
      state = state.copyWith(errorMessage: 'Select a surface before painting');
      return;
    }
    state = state.copyWith(
      activeTool: EditorToolType.surfacePaint,
      statusMessage: 'Surface paint mode',
      errorMessage: null,
    );
  }

  Future<void> createTerrainPreset({
    required String name,
    required TerrainType terrainType,
    String? categoryId,
    String tilesetId = '',
    List<TerrainPresetVariant> variants = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        terrainType: terrainType,
        categoryId: categoryId,
        tilesetId: tilesetId,
        variants: variants,
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetCreated(
        previous: project,
        updated: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Terrain preset created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create terrain preset: $e',
      );
    }
  }

  Future<void> updateTerrainPreset({
    required String presetId,
    String? name,
    TerrainType? terrainType,
    String? categoryId,
    bool clearCategoryId = false,
    String? tilesetId,
    bool clearTilesetId = false,
    List<TerrainPresetVariant>? variants,
    bool clearVariants = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        presetId: presetId,
        name: name,
        terrainType: terrainType,
        categoryId: categoryId,
        clearCategoryId: clearCategoryId,
        tilesetId: tilesetId,
        clearTilesetId: clearTilesetId,
        variants: variants,
        clearVariants: clearVariants,
      );
      final selectedPreset =
          _terrainPresetResolver.findTerrainPresetById(updated, presetId) ??
              (throw EditorNotFoundException(
                'Terrain preset not found: $presetId',
              ));
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetUpdated(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        selectedPreset: selectedPreset,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Terrain preset updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update terrain preset: $e',
      );
    }
  }

  Future<void> deleteTerrainPreset(String presetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteTerrainPresetUseCaseProvider);
      final updated = await useCase.execute(fs, project, presetId: presetId);
      final selection =
          _terrainPresetSelectionCoordinator.afterTerrainPresetDeleted(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        deletedPresetId: presetId,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Terrain preset deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete terrain preset: $e',
      );
    }
  }

  Future<void> createPathPreset({
    required String name,
    PathSurfaceKind surfaceKind = PathSurfaceKind.path,
    String? categoryId,
    String tilesetId = '',
    List<PathPresetVariantMapping> variants = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createPathPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        surfaceKind: surfaceKind,
        categoryId: categoryId,
        tilesetId: tilesetId,
        variants: variants,
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetCreated(
        previous: project,
        updated: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        activeTool: EditorToolType.terrainPaint,
        statusMessage: 'Path preset created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create path preset: $e');
    }
  }

  Future<void> updatePathPreset({
    required String presetId,
    String? name,
    PathSurfaceKind? surfaceKind,
    String? categoryId,
    bool clearCategoryId = false,
    String? tilesetId,
    bool clearTilesetId = false,
    List<PathPresetVariantMapping>? variants,
    bool clearVariants = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updatePathPresetUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        presetId: presetId,
        name: name,
        surfaceKind: surfaceKind,
        categoryId: categoryId,
        clearCategoryId: clearCategoryId,
        tilesetId: tilesetId,
        clearTilesetId: clearTilesetId,
        variants: variants,
        clearVariants: clearVariants,
      );
      final selected = updated.pathPresets.firstWhere(
        (preset) => preset.id == presetId,
        orElse: () => throw EditorNotFoundException(
          'Path preset not found: $presetId',
        ),
      );
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetUpdated(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        selectedPreset: selected,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Path preset updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update path preset: $e');
    }
  }

  List<PathLayer> getPathLayersForPreset(String presetId) {
    final map = state.activeMap;
    if (map == null) return const [];
    return map.layers
        .whereType<PathLayer>()
        .where((l) => l.presetId.trim() == presetId.trim())
        .toList(growable: false);
  }

  void applyPathLayerAnimationTriggers({
    required String layerId,
    required List<PathAnimationTriggerRule> triggers,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = setPathLayerAnimationTriggers(
        map,
        layerId: layerId,
        triggers: triggers,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Animation triggers updated',
      );
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Failed to update animation triggers: $e');
    }
  }

  void setPathLayerAnimationMode({
    required String layerId,
    required PathAnimationMode mode,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updatedMap = setPathLayerAnimationModeInMap(
        map,
        layerId: layerId,
        mode: mode,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Animation mode updated',
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update animation mode: $e');
    }
  }

  Future<void> deletePathPreset(String presetId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deletePathPresetUseCaseProvider);
      final updated = await useCase.execute(fs, project, presetId: presetId);
      final selection =
          _terrainPresetSelectionCoordinator.afterPathPresetDeleted(
        updated: updated,
        current: _currentTerrainPresetSelection(),
        deletedPresetId: presetId,
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Path preset deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete path preset: $e');
    }
  }

  Future<void> createPresetCategory({
    required String name,
    required PresetLibraryKind kind,
    String? parentCategoryId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createPresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        kind: kind,
        parentCategoryId: parentCategoryId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Category created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create category: $e');
    }
  }

  Future<void> renamePresetCategory({
    required String categoryId,
    required PresetLibraryKind kind,
    required String name,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renamePresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        kind: kind,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Category renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename category: $e');
    }
  }

  Future<void> deletePresetCategory({
    required String categoryId,
    required PresetLibraryKind kind,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deletePresetCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        kind: kind,
      );
      final selection = _terrainPresetSelectionCoordinator.normalize(
        project: updated,
        current: _currentTerrainPresetSelection(),
      );
      state = _copyStateWithTerrainPresetSelection(
        state.copyWith(project: updated),
        selection,
        statusMessage: 'Category deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete category: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Encounter tables
  // ---------------------------------------------------------------------------

  Future<void> createEncounterTable({
    required String name,
    required EncounterKind encounterKind,
    List<String> tags = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createEncounterTableUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        encounterKind: encounterKind,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table created',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to create encounter table: $e');
    }
  }

  Future<void> updateEncounterTable({
    required String tableId,
    String? name,
    EncounterKind? encounterKind,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateEncounterTableUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        name: name,
        encounterKind: encounterKind,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table updated',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update encounter table: $e');
    }
  }

  Future<void> deleteEncounterTable(String tableId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteEncounterTableUseCaseProvider);
      final updated = await useCase.execute(fs, project, tableId: tableId);
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table deleted',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to delete encounter table: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Project dialogues (bibliothèque)
  // ---------------------------------------------------------------------------

  void selectProjectDialogue(String? dialogueId) {
    state = _projectContentController.selectProjectDialogue(state, dialogueId);
  }

  Future<void> createProjectDialogue({
    required String name,
    String? folderId,
  }) async {
    state = await _projectContentController.createProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      name: name,
      folderId: folderId,
    );
  }

  Future<void> importProjectDialogue({
    required String absoluteSourcePath,
    required String displayName,
    String? folderId,
  }) async {
    state = await _projectContentController.importProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      absoluteSourcePath: absoluteSourcePath,
      displayName: displayName,
      folderId: folderId,
    );
  }

  Future<void> renameProjectDialogue({
    required String dialogueId,
    required String newName,
  }) async {
    state = await _projectContentController.renameProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      newName: newName,
    );
  }

  Future<void> deleteProjectDialogue(String dialogueId) async {
    state = await _projectContentController.deleteProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
    );
  }

  Future<void> createDialogueLibraryFolder({
    required String name,
    String? parentFolderId,
  }) async {
    state = await _projectContentController.createDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      name: name,
      parentFolderId: parentFolderId,
    );
  }

  Future<void> renameDialogueLibraryFolder({
    required String folderId,
    required String name,
  }) async {
    state = await _projectContentController.renameDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
      name: name,
    );
  }

  Future<void> moveDialogueLibraryFolder({
    required String folderId,
    String? newParentFolderId,
  }) async {
    state = await _projectContentController.moveDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
      newParentFolderId: newParentFolderId,
    );
  }

  Future<void> deleteDialogueLibraryFolder(String folderId) async {
    state = await _projectContentController.deleteDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
    );
  }

  Future<void> assignDialogueToLibraryFolder({
    required String dialogueId,
    required String folderId,
  }) async {
    state = await _projectContentController.assignDialogueToLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      folderId: folderId,
    );
  }

  Future<void> moveDialogueToLibraryRoot(String dialogueId) async {
    state = await _projectContentController.moveDialogueToLibraryRoot(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
    );
  }

  // ---------------------------------------------------------------------------
  // Narrative Studio - scénarios
  // ---------------------------------------------------------------------------
  //
  // Ce bloc réintroduit des mutations scénario ciblées, mais dans un cadre
  // beaucoup plus strict que l'ancien "Scenario Graph" générique:
  // - surface d'édition centrale (Cutscene Studio v1 guidé),
  // - opérations explicites create / update / delete,
  // - persistance via use-cases dédiés + validation `ProjectValidator`.
  //
  // Frontière volontaire:
  // - ce notifier orchestre la mutation et la UX (messages, sélection),
  // - la logique métier de validation/persistance reste dans les use-cases.
  // ---------------------------------------------------------------------------

  Future<void> createProjectScenario(ScenarioAsset scenario) async {
    state = await _projectContentController.createProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenario: scenario,
    );
  }

  Future<void> updateProjectScenario({
    required String scenarioId,
    required ScenarioAsset scenario,
  }) async {
    state = await _projectContentController.updateProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenarioId: scenarioId,
      scenario: scenario,
    );
  }

  Future<void> deleteProjectScenario(String scenarioId) async {
    state = await _projectContentController.deleteProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenarioId: scenarioId,
    );
  }

  Future<void> addEncounterEntry({
    required String tableId,
    required String speciesId,
    required int minLevel,
    required int maxLevel,
    int weight = 1,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(addEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        speciesId: speciesId,
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry added',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add encounter entry: $e');
    }
  }

  Future<void> updateEncounterEntry({
    required String tableId,
    required int entryIndex,
    String? speciesId,
    int? minLevel,
    int? maxLevel,
    int? weight,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        entryIndex: entryIndex,
        speciesId: speciesId,
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry updated',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update encounter entry: $e');
    }
  }

  Future<void> deleteEncounterEntry({
    required String tableId,
    required int entryIndex,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        entryIndex: entryIndex,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry deleted',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to delete encounter entry: $e');
    }
  }

  void activateFirstTerrainLayer({
    bool createIfMissing = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    for (final layer in map.layers) {
      if (layer is TerrainLayer) {
        state = state.copyWith(
          activeLayerId: layer.id,
          statusMessage: 'Layer "${layer.name}" selected',
          errorMessage: null,
        );
        _coerceActiveToolIfIncompatibleWithLayer();
        return;
      }
    }
    if (createIfMissing) {
      addMapLayer(
        kind: MapLayerKind.terrain,
        name: 'Terrain',
      );
      return;
    }
    state = state.copyWith(
      errorMessage: 'No terrain layer found in this map',
    );
  }

  void activateFirstPathLayer({
    bool createIfMissing = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    for (final layer in map.layers) {
      if (layer is PathLayer) {
        state = state.copyWith(
          activeLayerId: layer.id,
          statusMessage: 'Layer "${layer.name}" selected',
          errorMessage: null,
        );
        _coerceActiveToolIfIncompatibleWithLayer();
        return;
      }
    }
    if (createIfMissing) {
      addMapLayer(
        kind: MapLayerKind.path,
        name: 'Path',
      );
      return;
    }
    state = state.copyWith(
      errorMessage: 'No path layer found in this map',
    );
  }

  void activateFirstSurfaceLayer({
    bool createIfMissing = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    for (final layer in map.layers) {
      if (layer is SurfaceLayer) {
        state = state.copyWith(
          activeLayerId: layer.id,
          statusMessage: 'Layer "${layer.name}" selected',
          errorMessage: null,
        );
        _coerceActiveToolIfIncompatibleWithLayer();
        return;
      }
    }
    if (!createIfMissing) {
      state = state.copyWith(
        errorMessage: 'No surface layer found in this map',
      );
      return;
    }

    try {
      final result = _surfacePaintingController.ensureSurfaceLayer(
        map: map,
        preferredLayerId: state.activeLayerId,
      );
      if (!result.changed) {
        state = state.copyWith(activeLayerId: result.layerId);
        return;
      }
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layerId,
        statusMessage: 'Surface layer created',
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to create surface layer: $e');
    }
  }

  void setCollisionBrushSizeMode(CollisionBrushSizeMode mode) {
    if (state.collisionBrushSizeMode == mode) return;
    state = state.copyWith(
      collisionBrushSizeMode: mode,
      statusMessage: mode == CollisionBrushSizeMode.singleTile
          ? 'Collision brush: 1x1'
          : 'Collision brush: brush footprint',
      errorMessage: null,
    );
  }

  void toggleCollisionBrushSizeMode() {
    setCollisionBrushSizeMode(
      state.collisionBrushSizeMode == CollisionBrushSizeMode.singleTile
          ? CollisionBrushSizeMode.brushFootprint
          : CollisionBrushSizeMode.singleTile,
    );
  }

  void setActiveLayer(String layerId) {
    final map = state.activeMap;
    if (map == null) return;
    final selectedLayer = _findLayerById(map, layerId);
    if (selectedLayer == null) {
      state = state.copyWith(errorMessage: 'Layer not found: $layerId');
      return;
    }
    state = state.copyWith(
      activeLayerId: layerId,
      selectedPlacedElementInstanceId: null,
      errorMessage: null,
    );
    _coerceActiveToolIfIncompatibleWithLayer();
  }

  void setTilesElementsPanelMode(TilesElementsPanelMode mode) {
    if (state.tilesElementsPanelMode == mode) {
      return;
    }
    state = state.copyWith(
      tilesElementsPanelMode: mode,
      errorMessage: null,
    );
  }

  void selectPlacedElementInstance({
    required String? instanceId,
    String? elementId,
    String? layerId,
  }) {
    if (state.selectedPlacedElementInstanceId == instanceId) {
      return;
    }
    state = state.copyWith(
      selectedPlacedElementInstanceId: instanceId,
      errorMessage: null,
    );
    if (instanceId == null) {
      debugPrint('[editor][elements] selected placed instance cleared');
      return;
    }
    final safeElementId = elementId?.trim() ?? '';
    final safeLayerId = layerId?.trim() ?? '';
    debugPrint(
      '[editor][elements] selected placed instance id=$instanceId elementId=$safeElementId layer=$safeLayerId',
    );
  }

  void setPlacedElementInstanceCollisionApplied({
    required String instanceId,
    required bool applyCollision,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (previous.applyCollision == applyCollision) {
      return;
    }
    final updatedMap = setMapPlacedElementCollisionApplied(
      map,
      instanceId: trimmedId,
      applyCollision: applyCollision,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage:
          'Collision ${applyCollision ? 'activée' : 'désactivée'} pour ${previous.elementId}',
    );
  }

  void setPlacedElementInstanceAnimationConfig({
    required String instanceId,
    required MapPlacedElementAnimation? animation,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (previous.animation == animation) {
      return;
    }
    final updatedMap = setMapPlacedElementAnimation(
      map,
      instanceId: trimmedId,
      animation: animation,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: animation == null
          ? 'Animation réinitialisée pour ${previous.elementId}'
          : 'Animation mise à jour pour ${previous.elementId}',
    );
  }

  void setPlacedElementInstanceBehaviors({
    required String instanceId,
    required List<MapPlacedElementBehavior> behaviors,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (listEquals(previous.behaviors, behaviors)) {
      return;
    }
    final updatedMap = setMapPlacedElementBehaviors(
      map,
      instanceId: trimmedId,
      behaviors: behaviors,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: behaviors.isEmpty
          ? 'Comportements réinitialisés pour ${previous.elementId}'
          : 'Comportements mis à jour pour ${previous.elementId}',
    );
  }

  void deletePlacedElementInstance({
    required String instanceId,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final instance = map.placedElements[index];
    final layer = _findLayerById(map, instance.layerId);
    if (layer is! TileLayer) {
      state = state.copyWith(
        errorMessage:
            'Placed element layer is not a tile layer: ${instance.layerId}',
      );
      return;
    }

    final project = state.project;
    var patternSize = const GridSize(width: 1, height: 1);
    if (project != null) {
      ProjectElementEntry? element;
      for (final entry in project.elements) {
        if (entry.id == instance.elementId) {
          element = entry;
          break;
        }
      }
      if (element != null) {
        final source = element.frames.primarySource;
        patternSize = GridSize(
          width: source.width > 0 ? source.width : 1,
          height: source.height > 0 ? source.height : 1,
        );
      }
    }

    try {
      late final MapData erased;
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseTileOnMapUseCaseProvider);
        erased = useCase.execute(
          map,
          layerId: instance.layerId,
          pos: instance.pos,
        );
      } else {
        final useCase = ref.read(eraseTilePatternOnMapUseCaseProvider);
        erased = useCase.execute(
          map,
          layerId: instance.layerId,
          pos: instance.pos,
          patternSize: patternSize,
          clipToMapBounds: true,
        );
      }

      final committed = project == null
          ? erased
          : _placedElementInstanceIndexer.syncLayer(
              map: erased,
              project: project,
              layerId: instance.layerId,
            );

      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Instance supprimée (${instance.elementId})',
      );
      debugPrint(
        '[editor][elements] deleted placed instance id=$trimmedId elementId=${instance.elementId} layer=${instance.layerId} pos=(${instance.pos.x},${instance.pos.y})',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete placed element instance: $e',
      );
    }
  }

  /// Bascule vers la sélection si l’outil courant ne peut pas agir sur le calque actif.
  void _coerceActiveToolIfIncompatibleWithLayer() {
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      state,
    );
  }

  void updateHoveredTile(GridPos? pos) {
    if (state.hoveredTile != pos) {
      state = state.copyWith(hoveredTile: pos);
    }
  }

  void pan(Offset delta) {
    state = state.copyWith(panOffset: state.panOffset + delta);
  }

  void zoom(double delta) {
    final newZoom = (state.zoom + delta).clamp(0.1, 5.0);
    state = state.copyWith(zoom: newZoom);
  }

  void _applyMapMutation({
    required MapData previousMap,
    required MapData updatedMap,
    required String? preferredActiveLayerId,
    String? preferredSelectedEntityId,
    String? preferredSelectedMapEventId,
    String? preferredSelectedWarpId,
    String? preferredSelectedTriggerId,
    bool partOfStroke = false,
    bool updateSavedSnapshot = false,
    GridPos? hoveredTile,
    bool updateHoveredTile = false,
    String? statusMessage,
  }) {
    final next = _mapEditingController.applyMutation(
      current: state,
      previousMap: previousMap,
      updatedMap: updatedMap,
      preferredActiveLayerId: preferredActiveLayerId,
      preferredSelectedEntityId: preferredSelectedEntityId,
      preferredSelectedMapEventId: preferredSelectedMapEventId,
      preferredSelectedWarpId: preferredSelectedWarpId,
      preferredSelectedTriggerId: preferredSelectedTriggerId,
      partOfStroke: partOfStroke,
      updateSavedSnapshot: updateSavedSnapshot,
      hoveredTile: hoveredTile,
      updateHoveredTile: updateHoveredTile,
      statusMessage: statusMessage,
    );
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      next,
    );
  }

  int _findLayerIndexById(MapData map, String layerId) {
    return map.layers.indexWhere((layer) => layer.id == layerId);
  }

  MapLayer? _findLayerById(MapData map, String layerId) {
    for (final layer in map.layers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }

  String? _resolveEventPlacementLayerId(MapData map) {
    final activeLayerId = state.activeLayerId?.trim();
    if (activeLayerId != null &&
        activeLayerId.isNotEmpty &&
        map.layers.any((layer) => layer.id == activeLayerId)) {
      return activeLayerId;
    }
    if (map.layers.isNotEmpty) {
      return map.layers.first.id;
    }
    return null;
  }

  String _generateUniqueMapEventId(MapData map) {
    final ids = map.events.map((event) => event.id).toSet();
    if (!ids.contains('event')) {
      return 'event';
    }
    var index = 1;
    while (ids.contains('event_$index')) {
      index++;
    }
    return 'event_$index';
  }

  // ---------------------------------------------------------------------------
  // Characters (bibliothèque personnages)
  // ---------------------------------------------------------------------------

  void selectCharacter(String? characterId) {
    state = state.copyWith(selectedCharacterId: characterId);
  }

  Future<void> createCharacter({
    required String name,
    required String tilesetId,
    int frameWidth = 1,
    int frameHeight = 2,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        tilesetId: tilesetId,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
      );
      state = state.copyWith(
        project: updated,
        selectedCharacterId:
            updated.characters.isNotEmpty ? updated.characters.last.id : null,
        statusMessage: 'Character created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create character: $e');
    }
  }

  Future<void> updateCharacter({
    required String characterId,
    String? name,
    String? tilesetId,
    int? frameWidth,
    int? frameHeight,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
        name: name,
        tilesetId: tilesetId,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Character updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update character: $e');
    }
  }

  Future<void> deleteCharacter(String characterId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
      );
      state = state.copyWith(
        project: updated,
        selectedCharacterId: state.selectedCharacterId == characterId
            ? null
            : state.selectedCharacterId,
        statusMessage: 'Character deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete character: $e');
    }
  }

  Future<void> upsertCharacterAnimation({
    required String characterId,
    required CharacterAnimationState animState,
    required EntityFacing direction,
    required List<CharacterAnimationFrame> frames,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(upsertCharacterAnimationUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
        animState: animState,
        direction: direction,
        frames: frames,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Animation updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update animation: $e');
    }
  }

  Future<void> setPlayerCharacter(String? characterId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(setPlayerCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: characterId == null
            ? 'Player character cleared'
            : 'Player character set',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to set player character: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Trainers (bibliothèque dresseurs)
  // ---------------------------------------------------------------------------

  void selectTrainer(String? trainerId) {
    state = state.copyWith(selectedTrainerId: trainerId);
  }

  Future<bool> createTrainer({
    required String name,
    required String trainerClass,
    int? battleDifficulty,
    String? battleBackgroundRelativePath,
    String? characterId,
    String? portraitElementId,
    String? battleThemeId,
    String? victoryThemeId,
    List<String> tags = const <String>[],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(createTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        trainerClass: trainerClass,
        battleDifficulty: battleDifficulty,
        battleBackgroundRelativePath: battleBackgroundRelativePath,
        characterId: characterId,
        portraitElementId: portraitElementId,
        battleThemeId: battleThemeId,
        victoryThemeId: victoryThemeId,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        selectedTrainerId:
            updated.trainers.isNotEmpty ? updated.trainers.last.id : null,
        statusMessage: 'Trainer created',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create trainer: $e');
      return false;
    }
  }

  Future<bool> updateTrainer({
    required String trainerId,
    String? name,
    String? trainerClass,
    Object? battleDifficulty = _trainerUnset,
    Object? battleBackgroundRelativePath = _trainerUnset,
    Object? characterId = _trainerUnset,
    Object? portraitElementId = _trainerUnset,
    Object? battleThemeId = _trainerUnset,
    Object? victoryThemeId = _trainerUnset,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(updateTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        name: name,
        trainerClass: trainerClass,
        battleDifficulty: _trainerFieldUpdate<int>(battleDifficulty),
        battleBackgroundRelativePath:
            _trainerFieldUpdate<String>(battleBackgroundRelativePath),
        characterId: _trainerFieldUpdate<String>(characterId),
        portraitElementId: _trainerFieldUpdate<String>(portraitElementId),
        battleThemeId: _trainerFieldUpdate<String>(battleThemeId),
        victoryThemeId: _trainerFieldUpdate<String>(victoryThemeId),
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Trainer updated',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update trainer: $e');
      return false;
    }
  }

  Future<bool> deleteTrainer(String trainerId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(deleteTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
      );
      state = state.copyWith(
        project: updated,
        selectedTrainerId: state.selectedTrainerId == trainerId
            ? null
            : state.selectedTrainerId,
        statusMessage: 'Trainer deleted',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete trainer: $e');
      return false;
    }
  }

  Future<bool> addTrainerPokemon({
    required String trainerId,
    required String speciesId,
    required int level,
    List<String> moves = const <String>[],
    String? heldItemId,
    String? formId,
    String? gender,
    bool shiny = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(addTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        speciesId: speciesId,
        level: level,
        moves: moves,
        heldItemId: heldItemId,
        formId: formId,
        gender: gender,
        shiny: shiny,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon added',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add Pokémon: $e');
      return false;
    }
  }

  Future<bool> updateTrainerPokemon({
    required String trainerId,
    required int pokemonIndex,
    String? speciesId,
    int? level,
    List<String>? moves,
    Object? heldItemId = _trainerUnset,
    Object? formId = _trainerUnset,
    Object? gender = _trainerUnset,
    bool? shiny,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(updateTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        pokemonIndex: pokemonIndex,
        speciesId: speciesId,
        level: level,
        moves: moves,
        heldItemId: _trainerFieldUpdate<String>(heldItemId),
        formId: _trainerFieldUpdate<String>(formId),
        gender: _trainerFieldUpdate<String>(gender),
        shiny: shiny,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon updated',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update Pokémon: $e');
      return false;
    }
  }

  Future<bool> deleteTrainerPokemon({
    required String trainerId,
    required int pokemonIndex,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(deleteTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        pokemonIndex: pokemonIndex,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon removed',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove Pokémon: $e');
      return false;
    }
  }
}

TrainerFieldUpdate<T> _trainerFieldUpdate<T>(Object? rawValue) {
  if (identical(rawValue, _trainerUnset)) {
    return TrainerFieldUpdate<T>.keep();
  }
  return TrainerFieldUpdate<T>.set(rawValue as T?);
}

class _PaintPattern {
  const _PaintPattern({
    required this.size,
    required this.tiles,
  });

  final GridSize size;
  final List<int> tiles;
}

enum _BrushLayerCompatibility {
  compatible,
  rebindable,
  incompatible,
}

class _ResolvedBrushPattern {
  const _ResolvedBrushPattern({
    required this.tilesetId,
    required this.failureLabel,
    required this.pattern,
  });

  final String tilesetId;
  final String failureLabel;
  final _PaintPattern pattern;
}

class _ResolvedBrushFootprint {
  const _ResolvedBrushFootprint({
    required this.size,
    required this.failureLabel,
  });

  final GridSize size;
  final String failureLabel;
}

class _ErasePattern {
  const _ErasePattern({
    required this.size,
    required this.failureLabel,
  });

  final GridSize size;
  final String failureLabel;
}

class _ActiveTileLayerContext {
  const _ActiveTileLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final TileLayer layer;
}

class _ActiveCollisionLayerContext {
  const _ActiveCollisionLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final CollisionLayer layer;
}

class _ActiveTerrainLayerContext {
  const _ActiveTerrainLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final TerrainLayer layer;
}

class _ActivePathLayerContext {
  const _ActivePathLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final PathLayer layer;
}
```

#### packages/map_editor/lib/src/features/editor/state/editor_selectors.dart

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../application/models/terrain_selection_mode.dart';
import '../tools/editor_tool.dart';
import 'editor_notifier.dart';
import 'editor_state.dart';

/// Snapshot léger du shell.
///
/// On évite ainsi de faire rebuild le shell entier sur chaque champ de
/// `EditorState`, tout en gardant un contrat lisible côté UI.
typedef EditorShellSnapshot = ({
  EditorWorkspaceMode workspaceMode,
  String workspaceTitle,
  String workspaceSubtitle,
  bool canUndoMap,
  bool canRedoMap,
  bool isSaving,
  bool canSaveMap,
});

/// Snapshot ciblé pour la toolbar.
///
/// Il contient uniquement les champs réellement lus par `TopToolbar`.
typedef EditorToolbarSnapshot = ({
  ProjectManifest? project,
  String? projectRootPath,
  ProjectSettings settings,
  MapData? activeMap,
  EditorWorkspaceMode workspaceMode,
  ProjectTilesetEntry? selectedTilesetEntry,
  MapLayer? activeLayer,
  EditorToolType activeTool,
  TerrainSelectionMode terrainSelectionMode,
  TerrainType selectedTerrainType,
  MapEntityKind selectedEntityKind,
  CollisionBrushSizeMode collisionBrushSizeMode,
  bool isSaving,
  bool isDirty,
  bool canSaveMap,
  bool canUndoMap,
  bool canRedoMap,
  String? statusMessage,
});

/// Snapshot ciblé pour le Project Explorer.
typedef EditorProjectExplorerSnapshot = ({
  ProjectManifest? project,
  ProjectSettings settings,
  EditorWorkspaceMode workspaceMode,
  PokemonCatalogSection pokemonCatalogSection,
  ProjectTilesetEntry? selectedTilesetEntry,
  String? activeMapId,
});

/// Snapshot léger pour les racines des panneaux terrain/path.
typedef EditorTerrainLibrarySnapshot = ({
  ProjectManifest? project,
  ProjectSettings settings,
  List<ProjectTilesetEntry> tilesets,
  TerrainType selectedTerrainType,
  Map<TerrainType, String> selectedTerrainPresetByType,
  String? selectedTerrainPresetId,
  String? selectedPathPresetId,
});

/// Snapshot léger pour la racine du panneau palette tileset.
typedef EditorTilesetPaletteSnapshot = ({
  ProjectManifest? project,
  ProjectSettings settings,
  MapData? activeMap,
  ProjectTilesetEntry? selectedTilesetEntry,
  String? projectRootPath,
  String? activeLayerId,
  EditorBrush activeBrush,
  PaletteCategory? paletteCategoryFilter,
  String? selectedTilesetElementGroupId,
  TilesElementsPanelMode tilesElementsPanelMode,
  String? selectedPlacedElementInstanceId,
});

final editorWorkspaceModeProvider = Provider<EditorWorkspaceMode>((ref) {
  return ref.watch(editorNotifierProvider.select((s) => s.workspaceMode));
});

final editorProjectManifestProvider = Provider<ProjectManifest?>((ref) {
  return ref.watch(editorNotifierProvider.select((s) => s.project));
});

final editorPokemonCatalogSectionProvider = Provider<PokemonCatalogSection>((
  ref,
) {
  return ref.watch(
    editorNotifierProvider.select((s) => s.pokemonCatalogSection),
  );
});

final editorProjectRootPathProvider = Provider<String?>((ref) {
  return ref.watch(editorNotifierProvider.select((s) => s.projectRootPath));
});

final editorSelectedTilesetEntryProvider =
    Provider<ProjectTilesetEntry?>((ref) {
  return ref.watch(
    editorNotifierProvider.select(_resolveSelectedTilesetEntryFromState),
  );
});

final editorActiveLayerProvider = Provider<MapLayer?>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final map = state.activeMap;
      final activeLayerId = state.activeLayerId;
      if (map == null || activeLayerId == null) {
        return null;
      }
      for (final layer in map.layers) {
        if (layer.id == activeLayerId) {
          return layer;
        }
      }
      return null;
    }),
  );
});

final editorShellSnapshotProvider = Provider<EditorShellSnapshot>((ref) {
  final workspaceMode = ref.watch(editorWorkspaceModeProvider);
  final activeMap = ref.watch(
    editorNotifierProvider.select((s) => s.activeMap),
  );
  final selectedTileset = ref.watch(editorSelectedTilesetEntryProvider);
  final canUndoMap = ref.watch(
    editorNotifierProvider.select((s) => s.canUndoMap),
  );
  final canRedoMap = ref.watch(
    editorNotifierProvider.select((s) => s.canRedoMap),
  );
  final isSaving = ref.watch(
    editorNotifierProvider.select((s) => s.isSaving),
  );

  final workspaceTitle = switch (workspaceMode) {
    EditorWorkspaceMode.map => activeMap?.name ?? 'Map Workspace',
    EditorWorkspaceMode.tileset => selectedTileset?.name ?? 'Tileset Studio',
    EditorWorkspaceMode.trainer => 'Trainer Studio',
    EditorWorkspaceMode.pokedex => 'Catalogues Pokémon',
    EditorWorkspaceMode.globalStory => 'Global Story Workspace',
    EditorWorkspaceMode.step => 'Step Studio',
    EditorWorkspaceMode.cutscene => 'Cutscene Studio',
    EditorWorkspaceMode.dialogue => 'Dialogue Studio',
    EditorWorkspaceMode.pathStudio => 'Path Studio',
  };

  final workspaceSubtitle = switch (workspaceMode) {
    EditorWorkspaceMode.map => activeMap == null
        ? 'Open a map to start building your world.'
        : '${activeMap.size.width} x ${activeMap.size.height} tiles  •  ${activeMap.layers.length} layers',
    EditorWorkspaceMode.tileset => selectedTileset == null
        ? 'Select a tileset to browse and curate your library.'
        : 'Visual library editing for tiles, elements and groups.',
    EditorWorkspaceMode.trainer =>
      'Create trainers, teams and battle-ready rosters without editing raw JSON.',
    EditorWorkspaceMode.pokedex =>
      'Pokédex, Moves et Items réunis dans un même pôle de catalogues Pokémon.',
    EditorWorkspaceMode.globalStory =>
      'Macro narrative progression: arcs, milestones and high-level branches.',
    EditorWorkspaceMode.step =>
      'Step logic workspace: progression rules, expected outcomes, linked cutscenes.',
    EditorWorkspaceMode.cutscene =>
      'Scene execution workspace: dialogue, movement, waits, local branching.',
    EditorWorkspaceMode.dialogue =>
      'Conversation authoring: visual blocks, preview, Yarn export — not a raw script IDE.',
    EditorWorkspaceMode.pathStudio =>
      'Créer des motifs de chemin à partir des presets PathPattern du projet.',
  };

  final exposesMapActions = workspaceMode == EditorWorkspaceMode.map;

  return (
    workspaceMode: workspaceMode,
    workspaceTitle: workspaceTitle,
    workspaceSubtitle: workspaceSubtitle,
    canUndoMap: exposesMapActions && canUndoMap,
    canRedoMap: exposesMapActions && canRedoMap,
    isSaving: isSaving,
    canSaveMap: exposesMapActions && activeMap != null && !isSaving,
  );
});

final editorToolbarSnapshotProvider = Provider<EditorToolbarSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      final exposesMapActions = state.workspaceMode == EditorWorkspaceMode.map;
      return (
        project: project,
        projectRootPath: state.projectRootPath,
        settings: project?.settings ?? const ProjectSettings(),
        activeMap: state.activeMap,
        workspaceMode: state.workspaceMode,
        selectedTilesetEntry: _resolveSelectedTilesetEntryFromState(state),
        activeLayer: _resolveActiveLayerFromState(state),
        activeTool: state.activeTool,
        terrainSelectionMode: state.terrainSelectionMode,
        selectedTerrainType: state.selectedTerrainType,
        selectedEntityKind: state.selectedEntityKind,
        collisionBrushSizeMode: state.collisionBrushSizeMode,
        isSaving: state.isSaving,
        isDirty: state.isDirty,
        canSaveMap: exposesMapActions && state.activeMap != null,
        canUndoMap: exposesMapActions && state.canUndoMap,
        canRedoMap: exposesMapActions && state.canRedoMap,
        statusMessage: state.statusMessage,
      );
    }),
  );
});

final editorProjectExplorerSnapshotProvider =
    Provider<EditorProjectExplorerSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      return (
        project: project,
        settings: project?.settings ?? const ProjectSettings(),
        workspaceMode: state.workspaceMode,
        pokemonCatalogSection: state.pokemonCatalogSection,
        selectedTilesetEntry: _resolveSelectedTilesetEntryFromState(state),
        activeMapId: state.activeMap?.id,
      );
    }),
  );
});

final editorTerrainLibrarySnapshotProvider =
    Provider<EditorTerrainLibrarySnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      return (
        project: project,
        settings: project?.settings ?? const ProjectSettings(),
        tilesets: project?.tilesets ?? const <ProjectTilesetEntry>[],
        selectedTerrainType: state.selectedTerrainType,
        selectedTerrainPresetByType: state.selectedTerrainPresetByType,
        selectedTerrainPresetId: state.selectedTerrainPresetId,
        selectedPathPresetId: state.selectedPathPresetId,
      );
    }),
  );
});

final editorTilesetPaletteSnapshotProvider =
    Provider<EditorTilesetPaletteSnapshot>((ref) {
  return ref.watch(
    editorNotifierProvider.select((state) {
      final project = state.project;
      return (
        project: project,
        settings: project?.settings ?? const ProjectSettings(),
        activeMap: state.activeMap,
        selectedTilesetEntry: _resolveSelectedTilesetEntryFromState(state),
        projectRootPath: state.projectRootPath,
        activeLayerId: state.activeLayerId,
        activeBrush: state.activeBrush,
        paletteCategoryFilter: state.paletteCategoryFilter,
        selectedTilesetElementGroupId: state.selectedTilesetElementGroupId,
        tilesElementsPanelMode: state.tilesElementsPanelMode,
        selectedPlacedElementInstanceId: state.selectedPlacedElementInstanceId,
      );
    }),
  );
});

MapLayer? _resolveActiveLayerFromState(EditorState state) {
  final map = state.activeMap;
  final activeLayerId = state.activeLayerId;
  if (map == null || activeLayerId == null) {
    return null;
  }
  for (final layer in map.layers) {
    if (layer.id == activeLayerId) {
      return layer;
    }
  }
  return null;
}

ProjectTilesetEntry? _resolveSelectedTilesetEntryFromState(EditorState state) {
  final project = state.project;
  if (project == null) {
    return null;
  }

  final selectedId = state.selectedTilesetEditorId;
  if (selectedId != null) {
    for (final tileset in project.tilesets) {
      if (tileset.id == selectedId) {
        return tileset;
      }
    }
  }

  final activeLayer = _resolveActiveLayerFromState(state);
  if (activeLayer is TileLayer) {
    final layerTilesetId = activeLayer.tilesetId?.trim();
    if (layerTilesetId != null && layerTilesetId.isNotEmpty) {
      for (final tileset in project.tilesets) {
        if (tileset.id == layerTilesetId) {
          return tileset;
        }
      }
    }
  }

  final brushTilesetId = _resolveActiveBrushTilesetId(state, project);
  if (brushTilesetId != null) {
    for (final tileset in project.tilesets) {
      if (tileset.id == brushTilesetId) {
        return tileset;
      }
    }
  }

  if (project.tilesets.isEmpty) {
    return null;
  }
  return project.tilesets.first;
}

String? _resolveActiveBrushTilesetId(
  EditorState state,
  ProjectManifest project,
) {
  final brush = state.activeBrush;
  if (brush is TileEditorBrush) {
    return brush.tilesetId;
  }
  if (brush is PaletteEntryEditorBrush) {
    return brush.tilesetId;
  }
  if (brush is ProjectElementEditorBrush) {
    for (final element in project.elements) {
      if (element.id == brush.elementId) {
        return element.tilesetId;
      }
    }
  }
  return null;
}
```

#### packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart

```dart
/// Workspace central actuellement affiché dans l'éditeur.
///
/// Ce type reste simple et orienté UI/session. Le déplacer hors de
/// `editor_state.dart` réduit le bruit du fichier racine et prépare une
/// décomposition plus propre des slices d'état dans les prochains lots.
enum EditorWorkspaceMode {
  map,
  tileset,
  trainer,

  // Workspace Pokédex minimal branché dans l'éditeur.
  //
  // Intention produit:
  // - rendre visible une vraie entree Pokédex dans l'editeur ;
  // - ouvrir un workspace central dedie ;
  // - permettre d'afficher une liste simple des especes importees.
  //
  // Important:
  // ce mode reste volontairement limite :
  // - pas de recherche ;
  // - pas de filtres ;
  // - pas de fiche detail ;
  // - pas d'edition.
  pokedex,

  // Workspaces narratifs centraux.
  //
  // Intention produit (non négociable):
  // - ces surfaces vivent dans l'îlot central, comme des workspaces de
  //   premier plan (pas comme des "petits panneaux" latéraux).
  // - la colonne gauche sert à naviguer/ouvrir.
  // - la colonne droite sert à inspecter le contexte sélectionné.
  globalStory,
  step,
  cutscene,

  /// Studio de conversation (dialogues `.yarn` en blocs visuels).
  dialogue,

  /// Shell Path Studio V0.
  ///
  /// Ce mode expose une surface read-only pour les `ProjectPathPatternPreset` :
  /// liste, recherche, sélection, diagnostics et inspecteur. Il ne branche ni
  /// painter, ni save flow, ni éditeur réel du motif.
  pathStudio,
}
```

#### packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/path_studio/path_studio_panel.dart';
import 'map_canvas.dart';
import 'narrative_workspace_canvas.dart';
import 'pokemon_catalogs_workspace.dart';
import 'tileset_editor_canvas.dart';
import '../panels/trainer_library_panel.dart';

class EditorCanvasHost extends ConsumerWidget {
  const EditorCanvasHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceMode = ref.watch(editorWorkspaceModeProvider);

    return switch (workspaceMode) {
      EditorWorkspaceMode.map => const MapCanvas(),
      EditorWorkspaceMode.tileset => const TilesetEditorCanvas(),
      EditorWorkspaceMode.trainer => const TrainerLibraryPanel(),
      EditorWorkspaceMode.pokedex => const PokemonCatalogsWorkspace(),
      EditorWorkspaceMode.globalStory ||
      EditorWorkspaceMode.step ||
      EditorWorkspaceMode.cutscene ||
      EditorWorkspaceMode.dialogue =>
        const NarrativeWorkspaceCanvas(),
      EditorWorkspaceMode.pathStudio => const PathStudioWorkspace(),
    };
  }
}
```

#### packages/map_editor/lib/src/ui/editor_shell_page.dart

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
      EditorWorkspaceMode.pokedex => false,
      EditorWorkspaceMode.pathStudio => false,
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
                                    EditorWorkspaceMode.globalStory =>
                                      EditorChrome.islandCoolTint,
                                    EditorWorkspaceMode.step =>
                                      EditorChrome.islandWarmTint,
                                    EditorWorkspaceMode.cutscene =>
                                      EditorChrome.islandNeutralTint,
                                    EditorWorkspaceMode.dialogue =>
                                      EditorChrome.islandCoolTint,
                                    EditorWorkspaceMode.pathStudio =>
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
                                    EditorWorkspaceMode.pathStudio =>
                                      const _EmptyWorkspaceInspector(),
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
      EditorWorkspaceMode.globalStory => EditorChrome.inspectorJoyCyan,
      EditorWorkspaceMode.step => EditorChrome.inspectorJoyMint,
      EditorWorkspaceMode.cutscene => EditorChrome.inspectorJoyCoral,
      EditorWorkspaceMode.dialogue => EditorChrome.inspectorJoyBlue,
      EditorWorkspaceMode.pathStudio => EditorChrome.accentPrimary,
    };
    final chipAccent2 = switch (workspaceMode) {
      EditorWorkspaceMode.map => EditorChrome.inspectorJoyApricot,
      EditorWorkspaceMode.tileset => EditorChrome.inspectorJoyPlum,
      EditorWorkspaceMode.trainer => EditorChrome.inspectorJoyCoral,
      EditorWorkspaceMode.pokedex => EditorChrome.accentWarm,
      EditorWorkspaceMode.globalStory => EditorChrome.inspectorJoyBlue,
      EditorWorkspaceMode.step => EditorChrome.accentJade,
      EditorWorkspaceMode.cutscene => EditorChrome.inspectorJoyCoral,
      EditorWorkspaceMode.dialogue => EditorChrome.inspectorJoyCyan,
      EditorWorkspaceMode.pathStudio => EditorChrome.inspectorJoyCyan,
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
              EditorWorkspaceMode.globalStory => CupertinoIcons.link,
              EditorWorkspaceMode.step => CupertinoIcons.flag,
              EditorWorkspaceMode.cutscene => CupertinoIcons.play_rectangle,
              EditorWorkspaceMode.dialogue => CupertinoIcons.text_bubble,
              EditorWorkspaceMode.pathStudio => CupertinoIcons.arrow_branch,
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
              EditorWorkspaceMode.globalStory => 'Global',
              EditorWorkspaceMode.step => 'Step',
              EditorWorkspaceMode.cutscene => 'Cutscene',
              EditorWorkspaceMode.dialogue => 'Dialogue',
              EditorWorkspaceMode.pathStudio => 'Path',
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

#### packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import 'project_explorer/dialogs/import_tileset_dialog.dart';
import 'project_explorer/dialogs/tileset_library_dialogs.dart';
import 'project_explorer/dialogs/world_group_dialogs.dart';
import 'project_explorer/widgets/sidebar_header_action.dart';
import 'project_explorer/widgets/tree/tileset_tree_nodes.dart';
import 'project_explorer/widgets/tree/world_tree_nodes.dart';
import 'character_library_panel.dart';
import 'narrative_library_panel.dart';
import 'terrain_editor_panel.dart';
import 'trainer_library_panel.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_section_card.dart';

class ProjectExplorerPanel extends ConsumerStatefulWidget {
  const ProjectExplorerPanel({super.key});

  @override
  ConsumerState<ProjectExplorerPanel> createState() =>
      _ProjectExplorerPanelState();
}

class _ProjectExplorerPanelState extends ConsumerState<ProjectExplorerPanel> {
  bool _expandTileLib = true;
  bool _expandPokedex = true;
  bool _expandNarrative = true;
  bool _expandWorld = true;
  bool _expandTerrains = true;
  bool _expandPaths = true;
  bool _expandTrainers = false;
  bool _expandCharacters = false;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(editorProjectExplorerSnapshotProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = snapshot.project;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: project == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 2),
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Open a project to browse your world, maps and tilesets.',
                              style: TextStyle(
                                color: CupertinoColors.placeholderText
                                    .resolveFrom(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    primary: false,
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 10),
                        _buildTree(context, project, snapshot, notifier),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    const explorerAccent = EditorChrome.inspectorJoyCyan;
    const explorerDeep = EditorChrome.inspectorJoyPlum;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(CupertinoColors.white, explorerAccent, 0.78)!,
                  Color.lerp(explorerDeep, const Color(0xFF140818), 0.35)!,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: explorerAccent.withValues(alpha: 0.88),
                width: 1.15,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              CupertinoIcons.square_stack_3d_up,
              size: 18,
              color: CupertinoColors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'World Explorer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cartes, tilesets, surfaces — dialogues dans Dialogue Studio',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTree(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final rootMaps = project.maps.where((m) => m.groupId == null).toList();
    final rootGroups =
        project.groups.where((g) => g.parentGroupId == null).toList();

    final worldChildren = <Widget>[
      ...rootGroups.map(
        (g) => GroupNode(
          group: g,
          project: project,
          snapshot: snapshot,
          notifier: notifier,
          depth: 0,
        ),
      ),
      if (rootMaps.isNotEmpty) ...[
        const EditorSidebarSectionTitle('UNGROUPED MAPS', leftInset: 6),
        ...rootMaps.map(
          (m) => MapNode(
            map: m,
            snapshot: snapshot,
            notifier: notifier,
            depth: 0,
          ),
        ),
      ],
      if (rootGroups.isEmpty && rootMaps.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'World is empty',
                style: TextStyle(
                  color: CupertinoColors.placeholderText.resolveFrom(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              PushButton(
                controlSize: ControlSize.regular,
                onPressed: () => showCreateGroupDialog(context, notifier),
                child: const Text('Add City or Route'),
              ),
            ],
          ),
        ),
    ];

    final screenH = MediaQuery.sizeOf(context).height;
    final hTileset = (screenH * 0.30).clamp(240.0, 400.0);
    final hPokedex = (screenH * 0.22).clamp(180.0, 260.0);
    final hNarrative = (screenH * 0.34).clamp(260.0, 460.0);
    final hWorld = (screenH * 0.30).clamp(240.0, 400.0);
    final hTerrains = (screenH * 0.36).clamp(280.0, 500.0);
    final hPaths = (screenH * 0.36).clamp(280.0, 500.0);
    final hTrainers = (screenH * 0.18).clamp(180.0, 240.0);
    final hCharacters = (screenH * 0.35).clamp(260.0, 480.0);
    const explorerTileRadius = 28.0;
    final actionIcon = CupertinoColors.white.withValues(alpha: 0.92);
    final actionHover = CupertinoColors.white.withValues(alpha: 0.16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Tileset Library',
          subtitle: 'Folders, imports, and map painting',
          icon: CupertinoIcons.square_grid_2x2,
          accentColor: EditorChrome.inspectorJoyBlue,
          badgeText: '${project.tilesets.length}',
          expanded: _expandTileLib,
          onToggle: () => setState(() => _expandTileLib = !_expandTileLib),
          expandedHeight: hTileset,
          headerTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SidebarHeaderAction(
                enabled: true,
                icon: CupertinoIcons.photo_on_rectangle,
                tooltip: 'Import tileset',
                onPressed: () =>
                    showImportTilesetDialog(context, snapshot, notifier),
                iconColor: actionIcon,
                hoverFill: actionHover,
              ),
              const SizedBox(width: 6),
              SidebarHeaderAction(
                enabled: true,
                icon: CupertinoIcons.plus_circle_fill,
                tooltip: 'New folder',
                onPressed: () => promptNewTilesetLibraryFolder(
                  context,
                  notifier,
                ),
                iconColor: actionIcon,
                hoverFill: actionHover,
              ),
            ],
          ),
          child: _buildTilesetsIsland(context, project, snapshot, notifier),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Catalogues Pokémon',
          subtitle: 'Pokédex, Moves et Items dans un espace guidé unique',
          icon: CupertinoIcons.book_fill,
          accentColor: EditorChrome.inspectorJoyAmber,
          expanded: _expandPokedex,
          onToggle: () => setState(() => _expandPokedex = !_expandPokedex),
          expandedHeight: hPokedex,
          child: _buildPokemonCatalogsCard(context, snapshot, notifier),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Narrative Studio',
          subtitle:
              'Global Story, Steps, Cutscenes and outcomes (opens central workspaces)',
          icon: CupertinoIcons.link_circle_fill,
          accentColor: EditorChrome.inspectorJoyCyan,
          badgeText: '${project.scenarios.length}',
          expanded: _expandNarrative,
          onToggle: () => setState(() => _expandNarrative = !_expandNarrative),
          expandedHeight: hNarrative,
          child: const NarrativeLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'World Maps',
          subtitle:
              'Maps jouables et contenu monde (events, entités, warps, triggers)',
          icon: CupertinoIcons.map_fill,
          accentColor: EditorChrome.inspectorJoyPlum,
          badgeText: '${project.maps.length}',
          expanded: _expandWorld,
          onToggle: () => setState(() => _expandWorld = !_expandWorld),
          expandedHeight: hWorld,
          headerTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SidebarHeaderAction(
                enabled: true,
                icon: CupertinoIcons.folder_badge_plus,
                tooltip: 'New root group',
                onPressed: () => showCreateGroupDialog(context, notifier),
                iconColor: actionIcon,
                hoverFill: actionHover,
              ),
            ],
          ),
          child: _buildWorldIslandBody(context, worldChildren),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Terrain Library',
          subtitle: 'Base ground presets',
          icon: CupertinoIcons.map,
          accentColor: EditorChrome.accentJade,
          badgeText: '${project.terrainPresets.length}',
          expanded: _expandTerrains,
          onToggle: () => setState(() => _expandTerrains = !_expandTerrains),
          expandedHeight: hTerrains,
          child: const TerrainLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Path Library',
          subtitle: 'Legacy paths and Path Studio shell',
          icon: CupertinoIcons.arrow_branch,
          accentColor: EditorChrome.accentWarm,
          badgeText:
              '${project.pathPresets.length}/${project.pathPatternPresets.length}',
          expanded: _expandPaths,
          onToggle: () => setState(() => _expandPaths = !_expandPaths),
          expandedHeight: hPaths,
          child: _buildPathLibraryCard(context, project, snapshot, notifier),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Trainer Studio',
          subtitle: 'Battle rosters and teams (opens the central workspace)',
          icon: CupertinoIcons.person_2_fill,
          accentColor: EditorChrome.accentCoral,
          badgeText: '${project.trainers.length}',
          expanded: _expandTrainers,
          onToggle: () => setState(() => _expandTrainers = !_expandTrainers),
          expandedHeight: hTrainers,
          child: const TrainerLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Character Library',
          subtitle: 'Overworld sprites for the player and NPCs',
          icon: CupertinoIcons.person_crop_circle,
          accentColor: EditorChrome.inspectorJoyCyan,
          badgeText: '${project.characters.length}',
          expanded: _expandCharacters,
          onToggle: () =>
              setState(() => _expandCharacters = !_expandCharacters),
          expandedHeight: hCharacters,
          child: const CharacterLibraryPanel(embedded: true),
        ),
      ],
    );
  }

  Widget _buildTilesetsIsland(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 8),
      child: _buildTilesetsSection(context, project, snapshot, notifier),
    );
  }

  Widget _buildPokemonCatalogsCard(
    BuildContext context,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final isCatalogsWorkspace =
        snapshot.workspaceMode == EditorWorkspaceMode.pokedex;

    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EditorSidebarListRow(
            key: const Key('pokemon-catalog-entry-pokedex'),
            selected: isCatalogsWorkspace &&
                snapshot.pokemonCatalogSection == PokemonCatalogSection.pokedex,
            onTap: () => notifier.selectPokemonCatalogSection(
              PokemonCatalogSection.pokedex,
            ),
            leading: const MacosIcon(CupertinoIcons.book),
            title: const Text('Pokédex'),
            subtitle: const Text(
              'Recherche, import, détail et édition locale des espèces',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          EditorSidebarListRow(
            key: const Key('pokemon-catalog-entry-moves'),
            selected: isCatalogsWorkspace &&
                snapshot.pokemonCatalogSection == PokemonCatalogSection.moves,
            onTap: () => notifier.selectPokemonCatalogSection(
              PokemonCatalogSection.moves,
            ),
            leading: const MacosIcon(CupertinoIcons.sparkles),
            title: const Text('Moves'),
            subtitle: const Text(
              'Catalogue local des capacités du projet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          EditorSidebarListRow(
            key: const Key('pokemon-catalog-entry-items'),
            selected: isCatalogsWorkspace &&
                snapshot.pokemonCatalogSection == PokemonCatalogSection.items,
            onTap: () => notifier.selectPokemonCatalogSection(
              PokemonCatalogSection.items,
            ),
            leading: const MacosIcon(CupertinoIcons.cube_box),
            title: const Text('Items'),
            subtitle: const Text(
              'Catalogue local des objets du projet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathLibraryCard(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final isPathStudio =
        snapshot.workspaceMode == EditorWorkspaceMode.pathStudio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSidebarListRow(
          key: const Key('project-explorer-path-studio-entry'),
          selected: isPathStudio,
          onTap: notifier.selectPathStudioWorkspace,
          leading: const MacosIcon(CupertinoIcons.arrow_branch),
          title: const Text('Path Studio'),
          subtitle: Text(
            '${project.pathPatternPresets.length} motifs PathPattern — shell read-only',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        const Expanded(
          child: PathLibraryPanel(embedded: true),
        ),
      ],
    );
  }

  Widget _buildWorldIslandBody(
    BuildContext context,
    List<Widget> worldChildren,
  ) {
    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: worldChildren,
      ),
    );
  }

  Widget _buildTilesetsSection(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final selectedTilesetId = snapshot.selectedTilesetEntry?.id;
    final tree = buildTilesetLibraryTree(project);

    String scopeLabel(ProjectTilesetEntry t) {
      if (t.scope == TilesetScope.global) return 'Global';
      final gid = t.groupId;
      if (gid == null) return 'Group';
      for (final g in project.groups) {
        if (g.id == gid) return g.name;
      }
      return 'Group';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TilesetLibraryRootDropStrip(project: project, notifier: notifier),
        if (project.tilesets.isEmpty && project.tilesetFolders.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Text(
              'No tilesets yet. Import an image or create folders to organize your library.',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
                fontSize: 12,
              ),
            ),
          ),
        ...tree.rootFolders.map(
          (branch) => TilesetLibraryFolderNode(
            branch: branch,
            depth: 0,
            project: project,
            notifier: notifier,
            selectedTilesetId: selectedTilesetId,
            scopeLabel: scopeLabel,
          ),
        ),
        ...tree.rootTilesets.map(
          (tileset) => TilesetNode(
            tileset: tileset,
            project: project,
            notifier: notifier,
            selected: selectedTilesetId == tileset.id,
            leftIndent: 14,
            scopeLabel: scopeLabel(tileset),
          ),
        ),
      ],
    );
  }
}
```

#### packages/map_editor/lib/src/ui/shared/top_toolbar.dart

```dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/models/terrain_selection_mode.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/editor/tools/editor_tool.dart';
import 'cupertino_editor_widgets.dart';
import 'top_toolbar/dialogs/top_toolbar_dialogs.dart';
import 'top_toolbar/widgets/toolbar_brand.dart';
import 'top_toolbar/widgets/toolbar_capsules.dart';

/// Exposé pour [MacosScaffold.toolBar], qui attend un [ToolBar] typé (pas un [ConsumerWidget]).
ToolBar buildMapEditorToolbar(BuildContext context, WidgetRef ref) =>
    TopToolbar.buildToolBar(context, ref);

/// Barre d’outils native [macos_ui] pour [MacosScaffold].
class TopToolbar extends ConsumerWidget {
  const TopToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      TopToolbar.buildToolBar(context, ref);

  static List<MacosPulldownMenuEntry> _terrainPulldownItems(
    EditorNotifier notifier,
  ) {
    return TerrainType.values
        .where((t) => t.isBackgroundPaintable)
        .map(
          (terrain) => MacosPulldownMenuItem(
            label: _terrainTypeLabel(terrain),
            title: Text(_terrainTypeLabel(terrain)),
            onTap: () => notifier.selectTerrainType(terrain),
          ),
        )
        .toList();
  }

  static List<MacosPulldownMenuEntry> _entityKindPulldownItems(
    EditorNotifier notifier,
  ) {
    return MapEntityKind.values
        .map(
          (kind) => MacosPulldownMenuItem(
            label: _entityKindLabel(kind),
            title: Text(_entityKindLabel(kind)),
            onTap: () => notifier.selectEntityKind(kind),
          ),
        )
        .toList(growable: false);
  }

  static ToolBar buildToolBar(BuildContext context, WidgetRef ref) {
    final toolbar = ref.watch(editorToolbarSnapshotProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final settings = toolbar.settings;
    final subtle = EditorChrome.subtleLabel(context);

    final map = toolbar.activeMap;
    final isMapWorkspace = toolbar.workspaceMode == EditorWorkspaceMode.map;
    final hasTilesets = (toolbar.project?.tilesets.isNotEmpty ?? false);
    final firstTilesetId =
        hasTilesets ? toolbar.project!.tilesets.first.id : null;
    final hasMapCanvas = map != null;
    final showWorldTools = isMapWorkspace && hasMapCanvas;
    final activeLayer = toolbar.activeLayer;

    final canEraseOnActiveLayer = activeLayer is TileLayer ||
        activeLayer is CollisionLayer ||
        activeLayer is TerrainLayer ||
        activeLayer is PathLayer ||
        activeLayer is SurfaceLayer;

    final showTerrainTypePulldown = activeLayer is TerrainLayer &&
        toolbar.activeTool == EditorToolType.terrainPaint &&
        toolbar.terrainSelectionMode == TerrainSelectionMode.terrain;
    final showEntityKindPulldown =
        toolbar.activeTool == EditorToolType.entityPlacement;
    final showContextStrip =
        showWorldTools && (showTerrainTypePulldown || showEntityKindPulldown);

    final showCollisionBrushSize = activeLayer is CollisionLayer &&
        (toolbar.activeTool == EditorToolType.collisionPaint ||
            toolbar.activeTool == EditorToolType.eraser);

    final actions = <ToolbarItem>[
      _groupItem(
        context,
        overflowLabel: 'Project',
        children: [
          ToolbarCapsuleButton(
            icon: CupertinoIcons.folder_badge_plus,
            tooltip: 'New Project',
            onPressed: () => showTopToolbarNewProjectDialog(
              context,
              notifier,
            ),
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.folder_open,
            tooltip: 'Open Project',
            onPressed: () async {
              final selectedDirectory =
                  await FilePicker.platform.getDirectoryPath();
              if (selectedDirectory != null) {
                final manifestPath = p.join(selectedDirectory, 'project.json');
                await notifier.loadProject(manifestPath);
              }
            },
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.placemark,
            tooltip: 'New Map',
            onPressed:
                toolbar.project != null && toolbar.projectRootPath != null
                    ? () => showTopToolbarNewMapDialog(
                          context,
                          notifier,
                          defaultWidth: settings.defaultMapWidth,
                          defaultHeight: settings.defaultMapHeight,
                        )
                    : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.gear,
            tooltip: 'Project Settings',
            onPressed: toolbar.project != null
                ? () => showTopToolbarProjectSettingsDialog(
                      context,
                      notifier,
                      toolbar.project!,
                    )
                : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.rectangle_arrow_up_right_arrow_down_left,
            tooltip: 'Resize Map',
            onPressed: isMapWorkspace && toolbar.activeMap != null
                ? () => showTopToolbarResizeMapDialog(
                      context,
                      notifier,
                      currentWidth: toolbar.activeMap!.size.width,
                      currentHeight: toolbar.activeMap!.size.height,
                    )
                : null,
          ),
        ],
      ),
      _groupItem(
        context,
        overflowLabel: 'History',
        children: [
          if (toolbar.isSaving)
            const SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: ProgressCircle(),
              ),
            )
          else
            ToolbarCapsuleButton(
              icon: CupertinoIcons.floppy_disk,
              tooltip: 'Save Map',
              selected: toolbar.isDirty,
              onPressed: toolbar.canSaveMap ? notifier.saveActiveMap : null,
            ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.arrow_uturn_left,
            tooltip: 'Undo',
            onPressed: toolbar.canUndoMap ? notifier.undoMap : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.arrow_uturn_right,
            tooltip: 'Redo',
            onPressed: toolbar.canRedoMap ? notifier.redoMap : null,
          ),
        ],
      ),
      _groupItem(
        context,
        overflowLabel: 'Workspace',
        children: [
          ToolbarCapsuleButton(
            icon: CupertinoIcons.map,
            tooltip: 'Switch to map workspace',
            selected: isMapWorkspace,
            onPressed: notifier.selectMapWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.square_grid_2x2,
            tooltip: 'Switch to tileset workspace',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.tileset,
            onPressed: hasTilesets
                ? () => notifier.selectTilesetWorkspace(
                      toolbar.selectedTilesetEntry?.id ?? firstTilesetId,
                    )
                : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.person_3_fill,
            tooltip: 'Switch to Trainer Studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.trainer,
            onPressed: toolbar.project != null
                ? notifier.selectTrainerWorkspace
                : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.book,
            tooltip: 'Switch to Catalogues Pokémon',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.pokedex,
            onPressed: toolbar.project != null
                ? notifier.selectPokedexWorkspace
                : null,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.link,
            tooltip: 'Switch to global story workspace',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.globalStory,
            onPressed: notifier.selectGlobalStoryWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.flag,
            tooltip: 'Switch to Step Studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.step,
            onPressed: notifier.selectStepWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.play_rectangle,
            tooltip: 'Switch to Cutscene Studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.cutscene,
            onPressed: notifier.selectCutsceneWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.text_bubble,
            tooltip: 'Switch to dialogue studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.dialogue,
            onPressed: notifier.selectDialogueWorkspace,
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.arrow_branch,
            tooltip: 'Switch to Path Studio',
            selected: toolbar.workspaceMode == EditorWorkspaceMode.pathStudio,
            onPressed: toolbar.project != null
                ? notifier.selectPathStudioWorkspace
                : null,
          ),
        ],
      ),
      if (showWorldTools)
        _groupItem(
          context,
          overflowLabel: 'Painting Tools',
          children: [
            ToolbarCapsuleButton(
              icon: CupertinoIcons.selection_pin_in_out,
              tooltip: 'Selection Tool',
              selected: toolbar.activeTool == EditorToolType.selection,
              onPressed: () => notifier.selectTool(EditorToolType.selection),
            ),
            if (activeLayer is TileLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.paintbrush,
                tooltip: 'Tile Paint Tool',
                selected: toolbar.activeTool == EditorToolType.tilePaint,
                onPressed: () => notifier.selectTool(EditorToolType.tilePaint),
              ),
            if (activeLayer is TerrainLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.tree,
                tooltip: 'Terrain Paint Tool',
                selected: toolbar.activeTool == EditorToolType.terrainPaint &&
                    toolbar.terrainSelectionMode ==
                        TerrainSelectionMode.terrain,
                onPressed: () =>
                    notifier.selectTool(EditorToolType.terrainPaint),
              ),
            if (activeLayer is PathLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.map,
                tooltip: 'Path Paint Tool',
                selected: toolbar.activeTool == EditorToolType.terrainPaint &&
                    toolbar.terrainSelectionMode == TerrainSelectionMode.path,
                onPressed: notifier.selectPathPaintMode,
              ),
            if (activeLayer is SurfaceLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.drop,
                tooltip: 'Surface Paint Tool',
                selected: toolbar.activeTool == EditorToolType.surfacePaint,
                onPressed: notifier.selectSurfacePaintMode,
              ),
            if (activeLayer is CollisionLayer) ...[
              ToolbarCapsuleButton(
                icon: CupertinoIcons.square_grid_2x2,
                tooltip: 'Collision Paint Tool',
                selected: toolbar.activeTool == EditorToolType.collisionPaint,
                onPressed: () => notifier.selectTool(
                  EditorToolType.collisionPaint,
                ),
              ),
              if (showCollisionBrushSize)
                ToolbarCapsuleButton(
                  icon: toolbar.collisionBrushSizeMode ==
                          CollisionBrushSizeMode.singleTile
                      ? CupertinoIcons.number
                      : CupertinoIcons.square_grid_3x2,
                  tooltip: toolbar.collisionBrushSizeMode ==
                          CollisionBrushSizeMode.singleTile
                      ? 'Collision Brush Size: 1x1'
                      : 'Collision Brush Size: Brush Footprint',
                  selected:
                      toolbar.activeTool == EditorToolType.collisionPaint ||
                          toolbar.activeTool == EditorToolType.eraser,
                  onPressed: notifier.toggleCollisionBrushSizeMode,
                ),
            ],
            if (canEraseOnActiveLayer)
              ToolbarCapsuleButton(
                icon: CupertinoIcons.delete,
                tooltip: 'Eraser Tool',
                selected: toolbar.activeTool == EditorToolType.eraser,
                onPressed: () => notifier.selectTool(EditorToolType.eraser),
              ),
          ],
        ),
      if (showWorldTools)
        _groupItem(
          context,
          overflowLabel: 'Gameplay Tools',
          children: [
            ToolbarCapsuleButton(
              icon: CupertinoIcons.sparkles,
              tooltip: 'Entity Tool',
              selected: toolbar.activeTool == EditorToolType.entityPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.entityPlacement,
              ),
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.flag,
              tooltip: 'Event Tool',
              selected: toolbar.activeTool == EditorToolType.eventPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.eventPlacement,
              ),
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.square,
              tooltip: 'Trigger Tool',
              selected: toolbar.activeTool == EditorToolType.triggerPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.triggerPlacement,
              ),
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.arrow_branch,
              tooltip: 'Warp Tool',
              selected: toolbar.activeTool == EditorToolType.warpPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.warpPlacement,
              ),
            ),
            ToolbarCapsuleButton(
              icon: CupertinoIcons.leaf_arrow_circlepath,
              tooltip: 'Gameplay Zone Tool',
              selected:
                  toolbar.activeTool == EditorToolType.gameplayZonePlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.gameplayZonePlacement,
              ),
            ),
          ],
        ),
      if (showContextStrip)
        _groupItem(
          context,
          overflowLabel: 'Context',
          children: [
            if (showTerrainTypePulldown)
              ToolbarCapsulePulldown(
                label: _terrainTypeLabel(toolbar.selectedTerrainType),
                items: _terrainPulldownItems(notifier),
              ),
            if (showEntityKindPulldown)
              ToolbarCapsulePulldown(
                label: _entityKindLabel(toolbar.selectedEntityKind),
                items: _entityKindPulldownItems(notifier),
              ),
          ],
        ),
      _groupItem(
        context,
        overflowLabel: 'View',
        children: [
          ToolbarCapsuleButton(
            icon: CupertinoIcons.minus_circle,
            tooltip: 'Zoom Out',
            onPressed: () => notifier.zoom(-0.1),
          ),
          ToolbarCapsuleButton(
            icon: CupertinoIcons.plus_circle,
            tooltip: 'Zoom In',
            onPressed: () => notifier.zoom(0.1),
          ),
        ],
      ),
      const ToolBarSpacer(spacerUnits: 4),
      if (toolbar.statusMessage != null)
        CustomToolbarItem(
          inToolbarBuilder: (_) => Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color.lerp(
                EditorChrome.badgeFill(context),
                EditorChrome.chipFill(context),
                0.45,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              toolbar.statusMessage!,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          inOverflowedBuilder: (_) => const ToolbarOverflowMenuItem(
            label: 'Status',
            onPressed: null,
          ),
        ),
    ];

    return ToolBar(
      title: TopToolbarBrand(
        projectName: toolbar.project?.name,
        workspaceLabel: switch (toolbar.workspaceMode) {
          EditorWorkspaceMode.map => 'World Editor',
          EditorWorkspaceMode.tileset => 'Tileset Studio',
          EditorWorkspaceMode.trainer => 'Trainer Studio',
          EditorWorkspaceMode.pokedex => 'Catalogues Pokémon',
          EditorWorkspaceMode.globalStory => 'Global Story',
          EditorWorkspaceMode.step => 'Step Studio',
          EditorWorkspaceMode.cutscene => 'Cutscene Studio',
          EditorWorkspaceMode.dialogue => 'Dialogue Studio',
          EditorWorkspaceMode.pathStudio => 'Path Studio',
        },
      ),
      titleWidth: 236,
      automaticallyImplyLeading: false,
      centerTitle: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      dividerColor: MacosColors.transparent,
      decoration: BoxDecoration(
        color: EditorChrome.toolbarBarFill(context),
      ),
      actions: actions,
    );
  }

  static CustomToolbarItem _groupItem(
    BuildContext context, {
    required String overflowLabel,
    required List<Widget> children,
  }) {
    return CustomToolbarItem(
      inToolbarBuilder: (_) => ToolbarCapsuleGroup(children: children),
      inOverflowedBuilder: (_) => ToolbarOverflowMenuItem(
        label: overflowLabel,
        onPressed: null,
      ),
    );
  }

  static String _terrainTypeLabel(TerrainType type) {
    return switch (type) {
      TerrainType.none => 'None',
      TerrainType.grass => 'Grass Base',
      TerrainType.dirt => 'Dirt Base',
      TerrainType.sand => 'Sand Base',
      TerrainType.rock => 'Rock Base',
      TerrainType.stone => 'Stone Base',
      TerrainType.indoor => 'Indoor Base',
    };
  }

  static String _entityKindLabel(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => 'NPC',
      MapEntityKind.sign => 'Sign',
      MapEntityKind.item => 'Item',
      MapEntityKind.spawn => 'Spawn',
      MapEntityKind.custom => 'Custom',
    };
  }
}
```

#### packages/map_editor/test/editor_selectors_test.dart

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_selectors.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('editor selectors', () {
    test('editorShellSnapshotProvider derives map title and save affordance',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 12, height: 8),
          layers: [
            TileLayer(
              id: 'ground',
              name: 'Ground',
              tilesetId: 'world',
              tiles: [],
            ),
          ],
        ),
        canUndoMap: true,
      );

      final shell = container.read(editorShellSnapshotProvider);
      expect(shell.workspaceTitle, 'Starter Town');
      expect(shell.workspaceSubtitle, contains('12 x 8 tiles'));
      expect(shell.canUndoMap, isTrue);
      expect(shell.canSaveMap, isTrue);
    });

    test('editorToolbarSnapshotProvider resolves selected tileset from layer',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            const ProjectTilesetEntry(
              id: 'world',
              name: 'World',
              relativePath: 'tilesets/world.json',
            ),
          ],
          surfaceCatalog: ProjectSurfaceCatalog(),
        ),
        activeMap: const MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 8, height: 8),
          layers: [
            TileLayer(
              id: 'ground',
              name: 'Ground',
              tilesetId: 'world',
              tiles: [],
            ),
          ],
        ),
        activeLayerId: 'ground',
      );

      final toolbar = container.read(editorToolbarSnapshotProvider);
      expect(toolbar.selectedTilesetEntry?.id, 'world');
      expect(toolbar.activeLayer, isA<TileLayer>());
    });

    test('Path Studio snapshots hide map save and history actions', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        workspaceMode: EditorWorkspaceMode.pathStudio,
        activeMap: MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 8, height: 8),
          layers: [],
        ),
        canUndoMap: true,
        canRedoMap: true,
        isDirty: true,
      );

      final shell = container.read(editorShellSnapshotProvider);
      final toolbar = container.read(editorToolbarSnapshotProvider);

      expect(shell.canSaveMap, isFalse);
      expect(shell.canUndoMap, isFalse);
      expect(shell.canRedoMap, isFalse);
      expect(toolbar.canSaveMap, isFalse);
      expect(toolbar.canUndoMap, isFalse);
      expect(toolbar.canRedoMap, isFalse);
    });

    test('editorProjectExplorerSnapshotProvider exposes active map selection',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = EditorState(
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.items,
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          surfaceCatalog: ProjectSurfaceCatalog(),
        ),
        activeMap: const MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 8, height: 8),
          layers: [],
        ),
      );

      final snapshot = container.read(editorProjectExplorerSnapshotProvider);
      expect(snapshot.workspaceMode, EditorWorkspaceMode.pokedex);
      expect(snapshot.pokemonCatalogSection, PokemonCatalogSection.items);
      expect(snapshot.activeMapId, 'town');
      expect(snapshot.project?.name, 'demo');
    });

    test('editorShellSnapshotProvider exposes trainer studio labels', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = EditorState(
        workspaceMode: EditorWorkspaceMode.trainer,
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          surfaceCatalog: ProjectSurfaceCatalog(),
        ),
      );

      final shell = container.read(editorShellSnapshotProvider);
      expect(shell.workspaceTitle, 'Trainer Studio');
      expect(
        shell.workspaceSubtitle,
        contains('battle-ready rosters'),
      );
    });

    test('editorShellSnapshotProvider exposes Pokémon catalogs labels', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = EditorState(
        workspaceMode: EditorWorkspaceMode.pokedex,
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          surfaceCatalog: ProjectSurfaceCatalog(),
        ),
      );

      final shell = container.read(editorShellSnapshotProvider);
      expect(shell.workspaceTitle, 'Catalogues Pokémon');
      expect(shell.workspaceSubtitle, contains('Pokédex, Moves et Items'));
    });

    test('editorTerrainLibrarySnapshotProvider exposes preset selection inputs',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            const ProjectTilesetEntry(
              id: 'world',
              name: 'World',
              relativePath: 'tilesets/world.json',
            ),
          ],
          surfaceCatalog: ProjectSurfaceCatalog(),
        ),
        selectedTerrainType: TerrainType.grass,
        selectedTerrainPresetId: 'terrain.grass',
        selectedPathPresetId: 'path.route',
      );

      final snapshot = container.read(editorTerrainLibrarySnapshotProvider);
      expect(snapshot.project?.name, 'demo');
      expect(snapshot.tilesets.map((entry) => entry.id), ['world']);
      expect(snapshot.selectedTerrainPresetId, 'terrain.grass');
      expect(snapshot.selectedPathPresetId, 'path.route');
    });

    test('editorTilesetPaletteSnapshotProvider exposes palette panel state',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/project',
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            const ProjectTilesetEntry(
              id: 'world',
              name: 'World',
              relativePath: 'tilesets/world.json',
            ),
          ],
          surfaceCatalog: ProjectSurfaceCatalog(),
        ),
        activeMap: const MapData(
          id: 'town',
          name: 'Starter Town',
          size: GridSize(width: 8, height: 8),
          layers: [
            TileLayer(
              id: 'ground',
              name: 'Ground',
              tilesetId: 'world',
              tiles: [],
            ),
          ],
        ),
        activeLayerId: 'ground',
        activeBrush: const EditorBrush.tile(tileId: 7, tilesetId: 'world'),
        paletteCategoryFilter: PaletteCategory.floors,
        selectedTilesetElementGroupId: 'group_a',
        tilesElementsPanelMode: TilesElementsPanelMode.placedInstances,
        selectedPlacedElementInstanceId: 'instance_1',
      );

      final snapshot = container.read(editorTilesetPaletteSnapshotProvider);
      expect(snapshot.selectedTilesetEntry?.id, 'world');
      expect(snapshot.projectRootPath, '/tmp/project');
      expect(snapshot.activeLayerId, 'ground');
      expect(snapshot.paletteCategoryFilter, PaletteCategory.floors);
      expect(
        snapshot.tilesElementsPanelMode,
        TilesElementsPanelMode.placedInstances,
      );
      expect(snapshot.selectedPlacedElementInstanceId, 'instance_1');
    });
  });
}
```

#### packages/map_editor/test/editor_shell_page_smoke_test.dart

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
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
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

    testWidgets('opens Path Studio from the project explorer', (tester) async {
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_path_studio',
          project: buildShellChromeProject(
            pathPresets: const <ProjectPathPreset>[
              ProjectPathPreset(
                id: 'legacy-water',
                name: 'Legacy Water',
                surfaceKind: PathSurfaceKind.water,
              ),
            ],
            pathPatternPresets: [
              ProjectPathPatternPreset(
                id: 'water-1x1',
                name: 'Water 1x1',
                basePathPresetId: 'legacy-water',
                centerPattern: PathCenterPattern(
                  size: PathCenterPatternSize(width: 1, height: 1),
                  cells: [
                    PathCenterPatternCell(
                      localX: 0,
                      localY: 0,
                      frames: [
                        const TilesetVisualFrame(
                          source: TilesetSourceRect(x: 0, y: 0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      expect(
        find.byKey(const Key('project-explorer-path-studio-entry')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const Key('project-explorer-path-studio-entry')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('project-explorer-path-studio-entry')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.pathStudio,
      );
      expect(find.text('Path Studio'), findsWidgets);
      expect(find.text('Créer des motifs de chemin'), findsWidgets);
      expect(find.text('Water 1x1'), findsWidgets);
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

#### packages/map_editor/test/shell_chrome_test_harness.dart

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
  List<ProjectPathPreset> pathPresets = const <ProjectPathPreset>[],
  List<ProjectPathPatternPreset> pathPatternPresets =
      const <ProjectPathPatternPreset>[],
}) {
  return ProjectManifest(
    name: name,
    maps: maps,
    tilesets: tilesets,
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
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

#### packages/map_editor/test/top_toolbar_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/shared/top_toolbar/widgets/toolbar_capsules.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  group('TopToolbar', () {
    testWidgets('shows the app brand and project workspace label',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_project',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.pokedex,
        ),
      );

      expect(find.text('RPG Map Editor'), findsOneWidget);
      expect(find.text('Pokemon Map  •  Catalogues Pokémon'), findsOneWidget);
    });

    testWidgets('falls back to the workspace label when no project is loaded',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: const EditorState(),
      );

      expect(find.text('RPG Map Editor'), findsOneWidget);
      expect(find.text('World Editor'), findsOneWidget);
    });

    testWidgets('shows the toolbar status chip when a status is present',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_status',
          project: buildShellChromeProject(),
          statusMessage: 'Map saved',
        ),
      );

      expect(find.text('Map saved'), findsOneWidget);
    });

    testWidgets('shows the trainer studio label for the trainer workspace',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_trainer',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.trainer,
        ),
      );

      expect(find.text('Pokemon Map  •  Trainer Studio'), findsOneWidget);
    });

    testWidgets('disables map save and history actions in Path Studio',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_path_studio',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.pathStudio,
          activeMap: buildShellChromeMap(),
          isDirty: true,
          canUndoMap: true,
          canRedoMap: true,
        ),
      );

      ToolbarCapsuleButton buttonWithTooltip(String tooltip) {
        return tester.widget<ToolbarCapsuleButton>(
          find.byWidgetPredicate(
            (widget) =>
                widget is ToolbarCapsuleButton && widget.tooltip == tooltip,
          ),
        );
      }

      expect(buttonWithTooltip('Save Map').onPressed, isNull);
      expect(buttonWithTooltip('Undo').onPressed, isNull);
      expect(buttonWithTooltip('Redo').onPressed, isNull);
    });
  });
}
```

### 9.6 Rapport créé

Ce fichier de rapport est lui-même créé: `reports/pathPattern/pathpattern_13_path_studio_shell_v0.md`. Son contenu complet est le contenu de ce fichier. L’inclure intégralement dans lui-même créerait une récursion sans point fixe; cette limite est documentée explicitement plutôt que masquée.

## 10. Auto-review

- Respect du périmètre: oui, shell UI + lecture uniquement.

- Absence de feature creep: oui, pas d’éditeur réel, pas de drag/drop, pas de save flow PathPattern.

- Cohérence avec read model Lot 12: oui, diagnostics et cards proviennent de `createPathPatternEditorReadModel`.

- Qualité UX: direction dark mode locale, structure desktop claire, états empty/search/blocked visibles.

- Qualité tests: widget tests ciblés, smoke navigation, tests selectors/toolbar pour la revue, régressions PathPattern editor/core, analyze ciblé.

- Reviewer séparé: oui, retour pris en compte avec correction et tests.

## 11. Checklist d’autocontrôle finale

- [x] J’ai fait un audit initial avant modification.

- [x] Je n’ai utilisé que Git en lecture seule.

- [x] Je n’ai fait aucun commit / push / rebase / merge / reset / restore.

- [x] J’ai réutilisé les patterns UI existants du repo quand c’était pertinent.

- [x] Je n’ai pas modifié `map_core`.

- [x] Je n’ai pas modifié `ProjectManifest`.

- [x] Je n’ai pas modifié les codecs PathPattern.

- [x] J’ai utilisé le read model PathPattern existant.

- [x] J’ai créé une vraie entrée Path Studio visible dans l’éditeur.

- [x] J’ai livré une UI shell dark mode crédible.

- [x] J’ai implémenté liste + recherche + sélection.

- [x] J’ai affiché les diagnostics et statuts readiness.

- [x] Je n’ai pas implémenté l’éditeur réel du motif.

- [x] Je n’ai pas implémenté le save flow.

- [x] Je n’ai pas implémenté le painter.

- [x] Je n’ai pas implémenté le runtime render.

- [x] Je n’ai pas ajouté tall grass.

- [x] J’ai créé des tests widget ciblés.

- [x] J’ai exécuté les tests requis.

- [x] J’ai exécuté un analyze ciblé.

- [x] J’ai produit un rapport final ultra complet.

- [x] J’ai inclus le contenu complet de tous les fichiers modifiés/créés/supprimés hors auto-inclusion récursive du rapport.

- [x] J’ai fait une auto-review.

- [x] J’ai fait une critique explicite du prompt.

## 12. Confirmation explicite des non-objectifs

- Confirmé: pas de UI complète Path Studio au-delà du shell.

- Confirmé: pas de widget d’édition réelle du motif centre.

- Confirmé: pas de Riverpod/provider/notifier/controller dédié au Path Studio.

- Confirmé: pas de repository/service de persistance Path Studio.

- Confirmé: pas de PNG preview generation.

- Confirmé: pas d’appel aux renderers PNG.

- Confirmé: pas de mutation ProjectManifest.

- Confirmé: pas de modification map_core.

- Confirmé: pas de generated files.

- Confirmé: pas de build_runner.

- Confirmé: pas de painter/canvas/runtime/gameplay/battle.

- Confirmé: pas de tall grass.

- Confirmé: pas de Surface Studio.

- Confirmé: pas de TSX/TMX.

- Confirmé: pas de Mistral / PixelLab / MCP.

## 13. Critique du prompt

Clair: le périmètre produit était précis: shell visible, dark mode, navigation, read-only, recherche/sélection/diagnostics, pas d’édition réelle.

Ambigu: le prompt dit à la fois “pas de notifier/controller” et demande une entrée workspace cohérente dans une app dont la navigation existante passe par `EditorNotifier` / `EditorWorkspaceController`. J’ai interprété l’interdit comme “pas de nouveau notifier/controller Path Studio”. J’ai donc réutilisé la navigation existante avec une méthode minimale.

Discutable: demander le contenu complet de tous les fichiers modifiés est lourd quand un fichier existant comme `editor_notifier.dart` dépasse 6500 lignes. Je l’ai inclus pour respecter la demande, mais le diff complet est un meilleur artefact de revue pour ce type de modification chirurgicale.

Point utile du prompt: l’exigence de reviewer séparé a trouvé un vrai défaut autour de Save/Undo/Redo, corrigé avant finalisation.

## 14. Autocritique finale

Solide: la navigation est intégrée au shell existant, le panneau est testable hors shell, la recherche/sélection/diagnostics reposent sur le read model existant, et les actions de sauvegarde map sont maintenant bien neutralisées hors workspace map.

Fragile: la UI est volontairement un shell; elle n’a pas encore de preview réelle ni d’édition de cellule. Les textes et tailles sont crédibles pour desktop mais devront être revus avec un vrai contenu utilisateur et un passage visuel manuel.

A valider au Lot 14: modèle d’édition du motif centre, stratégie de preview réelle, emplacement final de l’inspector, et comportement des actions Nouveau/Dupliquer/Enregistrer.

## 15. Risques / limites restantes

- Les boutons shell sont désactivés; aucun flux de création, duplication ou sauvegarde n’existe encore.

- L’inspector est read-only et interne au workspace; il ne remplace pas encore une architecture globale de propriétés.

- Pas de screenshot golden UI: les tests widget vérifient structure/comportement, pas pixel-perfect DA.

- Les outputs de test widget contiennent un warning macos_ui connu sur la résolution lente de couleur accent; les commandes terminent avec succès.

## 16. Prochain lot recommandé

Lot 14 recommandé: un modèle d’état d’édition local pour le motif centre ou une preview réelle contrôlée, avant tout save flow. Les actions shell peuvent rester désactivées jusqu’à ce que le modèle d’édition soit défini.

## 17. Git status final

Commande: `git status --short`

```text
 M packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/editor_selectors_test.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
 M packages/map_editor/test/top_toolbar_test.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart
?? packages/map_editor/lib/src/features/path_studio/path_studio_theme.dart
?? packages/map_editor/test/path_pattern/path_studio_panel_test.dart
?? reports/pathPattern/pathpattern_13_path_studio_shell_v0.md
```
