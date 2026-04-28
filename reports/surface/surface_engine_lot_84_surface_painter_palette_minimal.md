# Lot 84 — Surface Painter + Palette Minimal V0

## Résumé exécutif

Le Lot 84 ajoute le premier flux éditeur minimal pour poser des surfaces dans une map :

- une palette Surface minimale basée sur `ProjectManifest.surfaceCatalog.presets`;
- une sélection `surfacePresetId` dans l'état éditeur;
- un outil `EditorToolType.surfacePaint`;
- un contrôleur pur côté `map_editor` qui réutilise les opérations `map_core` du Lot 83;
- la création automatique d'un `SurfaceLayer` au premier paint si aucun calque Surface n'existe;
- le paint / erase de `SurfaceCellPlacement` sparse dans `MapLayer.surface`.

Le lot ne rend pas les surfaces dans le canvas, ne résout pas l'autotile, ne charge pas d'atlas runtime et ne modifie pas `map_runtime`.

## Périmètre

Périmètre réalisé :

- `map_editor` uniquement, plus les tests ciblés `map_core` du Lot 83.
- Ajout d'une feature editor interne `surface_painter`.
- Ajout d'un champ d'état `selectedSurfacePresetId`, donc régénération Freezed/Riverpod strictement dans `packages/map_editor`.
- Ajout d'un outil `surfacePaint` toléré par le canvas, la toolbar et la sélection de layer.
- Ajout d'un panneau/palette minimal dans l'inspector map.

Passes exécutées :

1. Pass 1 — Gate 0 + audit du worktree : status initial vide, branche `main`.
2. Pass 2 — Audit de l'architecture editor tools / selection / canvas : `EditorState`, `MapCanvas`, `MapSelectionController`, panels et toolbar inspectés.
3. Pass 3 — Audit des opérations SurfaceLayer du Lot 83 : `surface_layer_placements.dart` et tests associés inspectés.
4. Pass 4 — Design minimal Surface palette / painter : décision `EditorToolType.surfacePaint` + création lazy du `SurfaceLayer`.
5. Pass 5 — Implémentation `map_editor` : palette, contrôleur, état, canvas, panels et toolbar.
6. Pass 6 — Tests ciblés : tests Surface Painter, sélection layer, Surface Studio et non-régression `map_core`.
7. Pass 7 — Analyse ciblée : analyse propre sur tous les fichiers Dart touchés.
8. Pass 8 — Non-régression `map_core` : tests Lot 83 relancés.
9. Pass 9 — Auto-review critique : checklist Lot 84 renseignée.
10. Pass 10 — Rapport final : ce document et evidence pack.

Hors périmètre volontaire :

- aucun rendu Surface dans le canvas;
- aucun renderer runtime;
- aucun resolver autotile;
- aucune animation clock;
- aucune migration legacy;
- aucun changement `ProjectManifest`, `surface.dart`, `surface_catalog.dart` ou codec Surface;
- aucun changement `map_runtime`, `map_gameplay`, `map_battle`.

## Gate 0 — Status initial avant modification

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
```

Sortie capturée avant toute modification :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all` : sortie vide.

`git diff --stat` : sortie vide.

`git log --oneline -n 10` :

```text
d2a3ca2e feat(map): add surface layer model and placement ops
6cc7fafa docs: update agent workflow guidance
9645a04b docs(surface): decide surface placement model
19c75e77 feat(map_editor): ajouter preset vertical atlas et golden slice e2e
ccdf1094 fix(map_editor): lisibilité et ergonomie sélecteur colonne aperçu atlas
33d776aa feat(map_editor): Lot 78 — animations Surface depuis atlas vertical
1a92a64e feat(map_editor): Surface Studio Lot 77 — plan génération animations atlas vertical
021abf5f feat(map_editor): Surface Studio Lots 75–76 — mapping colonnes + preview animation
cd9bf788 feat(map_editor): Surface Studio Lot 74 — assistant atlas vertical + preview grand format
13569f30 feat(map_editor): Surface Studio Lot 73 — grille sur aperçu image source
```

Changements préexistants : aucun.

## Audit editor paint architecture

Fichiers audités :

- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/application/map_selection_controller.dart`
- `packages/map_editor/lib/src/features/editor/tools/editor_tool.dart`
- `packages/map_editor/lib/src/application/services/terrain_painting_coordinator.dart`
- `packages/map_editor/lib/src/application/services/path_layer_editing_coordinator.dart`
- `packages/map_editor/lib/src/application/use_cases/paint_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart`
- `packages/map_editor/lib/src/app/providers/editor/map_use_case_providers.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/panels/terrain_map_panel.dart`
- `packages/map_editor/lib/src/ui/panels/layers_panel.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/features/surface_studio/**`

Recherches obligatoires lancées :

```bash
rg -n "terrainPaint|path|paint|erase|activeTool|EditorTool|ToolType|MapLayerKind|selectedLayer|selectedPreset|layersPanel|MapCanvas" packages/map_editor/lib packages/map_editor/test
rg -n "surfaceCatalog|ProjectSurfacePreset|SurfaceLayer|SurfaceCellPlacement|paintSurfacePlacement|eraseSurfacePlacement" packages/map_editor/lib packages/map_editor/test packages/map_core/lib packages/map_core/test
```

Constats :

- L'outil actif est porté par `EditorState.activeTool`.
- Les clics canvas passent par `MapCanvas.applyToolAt(...)`, qui route vers `EditorNotifier`.
- Les strokes sont activés pour `tilePaint`, `terrainPaint`, `collisionPaint` et `eraser`.
- `terrainPaint` couvre déjà `TerrainLayer` et `PathLayer` via `TerrainPaintingCoordinator` / `PathLayerEditingCoordinator`.
- `MapSelectionController.coerceActiveToolIfIncompatibleWithLayer(...)` protège les outils incompatibles avec le layer actif.
- L'inspector map est le bon endroit pour une palette minimale : il connaît le layer actif, le manifest et les panels spécialisés.

## Audit SurfaceLayer operations

Fichiers audités :

- `packages/map_core/lib/src/operations/surface_layer_placements.dart`
- `packages/map_core/test/surface_layer_placements_test.dart`
- `packages/map_core/test/surface_layer_model_test.dart`

Constats :

- `paintSurfacePlacement(...)` ajoute ou remplace un placement à coordonnée identique.
- `eraseSurfacePlacement(...)` supprime un placement et no-op si la cellule est vide.
- Les placements sont triés `y`, puis `x`, puis `surfacePresetId`.
- Les validations de bornes, `surfacePresetId` vide et doublons sont déjà côté `map_core`.

Le Lot 84 ne réimplémente donc pas ces règles dans l'éditeur.

## Décision outil Surface Paint

Décision : ajouter `EditorToolType.surfacePaint`.

Justification :

- le flux Surface n'est ni un tile paint, ni un terrain paint, ni un path paint;
- le modèle cible est `MapLayer.surface`;
- garder un outil dédié évite de mélanger les semantics `PathLayer.presetId` legacy avec `SurfaceCellPlacement.surfacePresetId`;
- les dispatchs existants restent explicites.

Limite V0 :

- l'outil n'a pas encore de preview visuelle dans `MapGridPainter`;
- l'absence de preview est volontaire, car le rendu Surface statique/animé arrive dans des lots futurs.

## Décision SurfaceLayer cible

Décision : création automatique d'un `SurfaceLayer` au premier paint si aucun SurfaceLayer n'existe.

Règle V0 :

- si le layer actif est un `SurfaceLayer`, on l'utilise;
- sinon, on réutilise le premier `SurfaceLayer` existant;
- sinon, au premier paint, on crée :

```text
id: surface-main
name: Surfaces
isVisible: true
opacity: 1.0
placements: []
properties: {}
```

Si `surface-main` existe déjà, l'id devient `surface-2`, puis `surface-3`, etc.

Justification :

- V0 doit être utilisable sans demander à l'utilisateur de comprendre les détails du modèle;
- la création est lazy : sélectionner une surface ne mute pas la map;
- un nouveau calque n'est pas créé à chaque clic.

## Palette Surface

Fichier créé :

- `packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart`

Comportement :

- lit une liste de `ProjectSurfacePreset`;
- affiche `Surfaces`;
- affiche `Aucune surface disponible` si le catalogue est vide;
- liste les noms des presets;
- expose l'id en information secondaire;
- marque le preset sélectionné avec `Surface sélectionnée`;
- appelle `onPresetSelected(preset.id)`.

La palette sélectionne un `surfacePresetId`, pas un atlas, pas une animation, pas un tileset.

## Paint / erase Surface

Fichier créé :

- `packages/map_editor/lib/src/features/surface_painter/surface_painting_controller.dart`

API ajoutée :

- `SurfacePaintingController.ensureSurfaceLayer(...)`
- `SurfacePaintingController.paint(...)`
- `SurfacePaintingController.erase(...)`
- `SurfacePaintingResult`

Règles :

- `paint(...)` no-op si aucun `surfacePresetId` n'est sélectionné;
- `paint(...)` crée le SurfaceLayer au premier paint;
- `paint(...)` appelle `paintSurfacePlacement(...)`;
- `erase(...)` appelle `eraseSurfacePlacement(...)`;
- `erase(...)` no-op si aucun SurfaceLayer ou aucun placement à la coordonnée;
- `MapValidator.validate(...)` est appelé après mutation.

## Intégration editor

Fichiers modifiés :

- `packages/map_editor/lib/src/features/editor/tools/editor_tool.dart`
  - ajout de `surfacePaint`.
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
  - ajout de `selectedSurfacePresetId`.
- `packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart`
  - propagation dans les vues groupées.
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
  - ajout sélection preset Surface;
  - ajout mode Surface paint;
  - ajout création/sélection SurfaceLayer;
  - ajout paint/erase Surface.
- `packages/map_editor/lib/src/features/editor/application/map_selection_controller.dart`
  - compatibilité `surfacePaint` uniquement avec `SurfaceLayer`;
  - eraser compatible avec `SurfaceLayer`.
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
  - routing canvas vers `paintSurfaceAt(...)`.
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
  - bouton Surface Paint si le layer actif est un SurfaceLayer.
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
  - section `Surfaces` avec `SurfacePainterPanel`.
- `packages/map_editor/lib/src/ui/panels/layers_panel.dart`
  - label SurfaceLayer enrichi avec le nombre de placements.

Generated files modifiés :

- `packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.g.dart`

`build_runner` a été lancé uniquement dans `packages/map_editor`.

## Fichiers créés

- `packages/map_editor/lib/src/features/surface_painter/surface_painting_controller.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart`
- `packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart`
- `packages/map_editor/test/surface_painter/surface_painting_controller_test.dart`
- `packages/map_editor/test/surface_painter/surface_palette_panel_test.dart`
- `reports/surface/surface_engine_lot_84_surface_painter_palette_minimal.md`

## Fichiers modifiés

- `packages/map_editor/lib/src/features/editor/application/map_selection_controller.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.g.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart`
- `packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart`
- `packages/map_editor/lib/src/features/editor/tools/editor_tool.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/panels/layers_panel.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/test/map_selection_controller_test.dart`

Note hors périmètre :

- `AGENTS.md` est apparu comme modifié pendant le lot, alors que le status initial était vide et que ce fichier n'était pas dans le périmètre. Le diff correspondait à une ancienne version longue du fichier. Il a été restauré manuellement au contenu de `HEAD` avec `apply_patch`, sans commande git d'écriture. Le diff final de `AGENTS.md` est vide (`AGENTS_DIFF_EXIT:0`).

## Fichiers supprimés

Aucun.

## Tests lancés

TDD / rouges attendus :

```bash
cd packages/map_editor
flutter test test/surface_painter/surface_painting_controller_test.dart
```

Résultat initial :

```text
Compilation failed ... surface_painting_controller.dart: No such file or directory
```

```bash
cd packages/map_editor
flutter test test/surface_painter/surface_palette_panel_test.dart
```

Résultat initial :

```text
Compilation failed ... surface_palette_panel.dart: No such file or directory
```

Incident de commande :

```text
Waiting for another flutter command to release the startup lock...
Unable to delete file or directory at ".../macos/Flutter/ephemeral/Packages/.packages".
```

Cause retenue : deux commandes Flutter lancées en parallèle. Les tests ont ensuite été relancés séquentiellement / par dossier et sont passés.

Tests finaux :

```bash
cd packages/map_editor
flutter test test/surface_painter
```

Résultat :

```text
+10: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/map_selection_controller_test.dart
```

Résultat :

```text
+5: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/surface_studio
```

Résultat :

```text
+387: All tests passed!
```

```bash
cd packages/map_core
dart test test/surface_layer_placements_test.dart
```

Résultat :

```text
+14: All tests passed!
```

```bash
cd packages/map_core
dart test test/surface_layer_model_test.dart
```

Résultat :

```text
+16: All tests passed!
```

## Analyse lancée

Analyse ciblée finale :

```bash
cd packages/map_editor
flutter analyze \
  lib/src/features/editor/application/map_selection_controller.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/features/editor/state/editor_notifier.g.dart \
  lib/src/features/editor/state/editor_state.dart \
  lib/src/features/editor/state/editor_state.freezed.dart \
  lib/src/features/editor/state/models/editor_state_groups.dart \
  lib/src/features/editor/tools/editor_tool.dart \
  lib/src/ui/canvas/map_canvas.dart \
  lib/src/ui/panels/layers_panel.dart \
  lib/src/ui/panels/map_inspector_panel.dart \
  lib/src/ui/shared/top_toolbar.dart \
  lib/src/features/surface_painter/surface_painting_controller.dart \
  lib/src/features/surface_painter/surface_palette_panel.dart \
  test/surface_painter/surface_painting_controller_test.dart \
  test/surface_painter/surface_palette_panel_test.dart \
  test/surface_painter/editor_notifier_surface_paint_test.dart \
  test/map_selection_controller_test.dart
```

Résultat :

```text
Analyzing 17 items...
No issues found! (ran in 1.7s)
```

Analyse globale optionnelle :

```bash
cd packages/map_editor
flutter analyze lib test
```

Résultat :

```text
420 issues found. (ran in 1.8s)
```

Cette dette est hors Lot 84 : les premiers fichiers en erreur sont notamment `pokemon_sdk_move_catalog_converter.dart`, `sync_pokemon_sdk_moves_catalog_use_case.dart`, plusieurs tests Pokédex/Trainer/Scenario et des warnings de panels narratifs non modifiés par ce lot. Les 17 fichiers modifiés/créés par le Lot 84 passent l'analyse ciblée.

## Résultats

- Surface Painter minimal : OK.
- Palette Surface : OK.
- Sélection `surfacePresetId` : OK.
- Paint sparse via `paintSurfacePlacement(...)` : OK.
- Erase sparse via `eraseSurfacePlacement(...)` : OK.
- Création automatique du SurfaceLayer au premier paint : OK.
- Tests ciblés `map_editor` : OK.
- Tests Surface Studio : OK.
- Tests ciblés `map_core` Lot 83 : OK.
- Analyse ciblée : OK.
- Analyse globale `map_editor` : KO, dette préexistante hors fichiers touchés.

## Evidence Pack

Gate 0 : voir section dédiée.

Build runner :

```bash
cd packages/map_editor
flutter pub run build_runner build --delete-conflicting-outputs
```

Sortie finale :

```text
Built with build_runner in 28s; wrote 14 outputs.
```

Warning build runner :

```text
W SDK language version 3.10.0 is newer than `analyzer` language version 3.9.0. Run `flutter packages upgrade`.
```

Diff stat avant ajout du rapport :

```text
.../application/map_selection_controller.dart      |   5 +-
.../src/features/editor/state/editor_notifier.dart | 149 +++++++++++++++++++++
.../features/editor/state/editor_notifier.g.dart   |   2 +-
.../src/features/editor/state/editor_state.dart    |   1 +
.../editor/state/editor_state.freezed.dart         |  30 ++++-
.../editor/state/models/editor_state_groups.dart   |   9 ++
.../lib/src/features/editor/tools/editor_tool.dart |   1 +
.../map_editor/lib/src/ui/canvas/map_canvas.dart   |   5 +
.../map_editor/lib/src/ui/panels/layers_panel.dart |   8 +-
.../lib/src/ui/panels/map_inspector_panel.dart     |  30 +++++
.../map_editor/lib/src/ui/shared/top_toolbar.dart  |  10 +-
.../test/map_selection_controller_test.dart        |  36 +++++
12 files changed, 274 insertions(+), 12 deletions(-)
```

`git diff --check` : sortie vide.

Vérification mojibake :

```bash
rg -n "Ã|Â|�" <fichiers Dart modifiés/créés> || true
```

Résultat : sortie vide.

## Git status final

Le status final exact est capturé dans la section "Gate final".

## Changements préexistants

Aucun changement préexistant au Gate 0.

## Changements du Lot 84

Changements du lot :

- nouvelle feature interne `surface_painter`;
- nouveaux tests surface painter;
- nouveau champ état éditeur `selectedSurfacePresetId`;
- nouvel outil `surfacePaint`;
- wiring `EditorNotifier`, `MapCanvas`, `TopToolbar`, `MapInspectorPanel`, `LayersPanel`;
- generated files requis pour Freezed/Riverpod;
- rapport Lot 84.

## Périmètre explicitement non touché

Confirmé :

- `ProjectManifest` non modifié;
- `surface.dart` non modifié;
- `surface_catalog.dart` non modifié;
- codecs Surface non modifiés;
- `map_runtime` non modifié;
- `map_gameplay` non modifié;
- `map_battle` non modifié;
- aucun renderer runtime Surface créé;
- aucun resolver autotile Surface créé;
- aucune animation clock runtime créée;
- aucune migration legacy codée;
- aucun provider/repository/service Surface créé;
- aucune refonte Surface Studio;
- `Runner.xcscheme` non modifié.

## Vérification fichiers temporaires

Commande :

```bash
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

Résultat avant rapport : sortie vide.

Résultat final : voir "Gate final".

## Vérification mojibake

Commande ciblée lancée sur les fichiers Dart modifiés/créés :

```bash
rg -n "Ã|Â|�" ... || true
```

Résultat : sortie vide.

## Auto-review

- Est-ce qu'une palette Surface existe ? Oui.
- Est-ce que la palette lit `ProjectManifest.surfaceCatalog.presets` ? Oui, via `SurfacePainterPanel`.
- Est-ce qu'elle sélectionne un `surfacePresetId` ? Oui.
- Est-ce qu'un mode/tool Surface Paint existe ? Oui, `EditorToolType.surfacePaint`.
- Est-ce que paint utilise `paintSurfacePlacement` du Lot 83 ? Oui, dans `SurfacePaintingController.paint`.
- Est-ce que erase utilise `eraseSurfacePlacement` du Lot 83 ? Oui, dans `SurfacePaintingController.erase`.
- Est-ce qu'un SurfaceLayer est créé automatiquement ou requis ? Créé automatiquement au premier paint si absent; un SurfaceLayer existant est réutilisé.
- Est-ce que paint crée/remplace un placement sparse ? Oui.
- Est-ce que erase supprime un placement sparse ? Oui.
- Est-ce que TerrainLayer / PathLayer restent inchangés ? Oui, le contrôleur ne cible que `SurfaceLayer`; test dédié avec TerrainLayer préservé.
- Est-ce qu'un rendu Surface est ajouté ? Non.
- Est-ce qu'un resolver autotile est ajouté ? Non.
- Est-ce que map_runtime est modifié ? Non.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que les analyses ciblées passent ? Oui.
- Est-ce qu'un fichier présent au status initial a disparu du status final ? Non.
- Est-ce qu'un fichier hors périmètre a été modifié ? Non au final; `AGENTS.md` a brièvement été détecté modifié puis restauré sans diff final.
- Est-ce qu'un 84-bis est nécessaire ? Non pour le périmètre V0; l'UX reste volontairement limitée sans rendu visuel.

## Critique du prompt

- Créer automatiquement un SurfaceLayer est pratique pour V0, mais cela peut surprendre si l'éditeur adopte plus tard une politique stricte de création explicite des calques.
- Ajouter `EditorToolType.surfacePaint` force à traiter les dispatchs exhaustifs, ce qui est sain mais plus large qu'un simple panneau.
- Le prompt demande un flux utilisateur, mais interdit le rendu : l'utilisateur peut écrire des placements sans feedback visuel fort dans le canvas. Le compteur dans les panels aide, mais ne remplace pas une preview.
- L'analyse globale `map_editor` remonte une dette existante importante, sans lien direct avec Surface Painter. Le prompt demande surtout des analyses ciblées, ce qui est plus réaliste pour ce lot.

## Gate final

Commandes :

```bash
git status --short --untracked-files=all
git diff --stat
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

`git status --short --untracked-files=all` :

```text
 M packages/map_editor/lib/src/features/editor/application/map_selection_controller.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.g.dart
 M packages/map_editor/lib/src/features/editor/state/editor_state.dart
 M packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart
 M packages/map_editor/lib/src/features/editor/state/models/editor_state_groups.dart
 M packages/map_editor/lib/src/features/editor/tools/editor_tool.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/panels/layers_panel.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/map_selection_controller_test.dart
?? packages/map_editor/lib/src/features/surface_painter/surface_painting_controller.dart
?? packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart
?? packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart
?? packages/map_editor/test/surface_painter/surface_painting_controller_test.dart
?? packages/map_editor/test/surface_painter/surface_palette_panel_test.dart
?? reports/surface/surface_engine_lot_84_surface_painter_palette_minimal.md
```

`git diff --stat` :

```text
 .../application/map_selection_controller.dart      |   5 +-
 .../src/features/editor/state/editor_notifier.dart | 149 +++++++++++++++++++++
 .../features/editor/state/editor_notifier.g.dart   |   2 +-
 .../src/features/editor/state/editor_state.dart    |   1 +
 .../editor/state/editor_state.freezed.dart         |  30 ++++-
 .../editor/state/models/editor_state_groups.dart   |   9 ++
 .../lib/src/features/editor/tools/editor_tool.dart |   1 +
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   |   5 +
 .../map_editor/lib/src/ui/panels/layers_panel.dart |   8 +-
 .../lib/src/ui/panels/map_inspector_panel.dart     |  30 +++++
 .../map_editor/lib/src/ui/shared/top_toolbar.dart  |  10 +-
 .../test/map_selection_controller_test.dart        |  36 +++++
 12 files changed, 274 insertions(+), 12 deletions(-)
```

`find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print` :

```text
```

Contrôle hors périmètre :

```bash
git diff --quiet -- AGENTS.md; printf 'AGENTS_DIFF_EXIT:%s\n' $?
```

Résultat :

```text
AGENTS_DIFF_EXIT:0
```
