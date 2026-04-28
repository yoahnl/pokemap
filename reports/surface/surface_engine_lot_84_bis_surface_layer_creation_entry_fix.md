# Lot 84-bis — Surface Layer Creation / Surface Paint Entry Fix V0

## Résumé exécutif

Le Lot 84-bis corrige le deadlock UX introduit par le Lot 84 : la popup de création de calque proposait les types issus de `MapLayerKind.values`, mais `MapLayerKind` ne contient pas `surface`. L'utilisateur pouvait donc voir le Surface Painter dans certains contextes, mais ne pouvait pas créer explicitement le calque nécessaire depuis l'entrée standard "Add Layer".

Correction réalisée :

- ajout de "Surface Layer" dans la popup `Layer type`;
- création explicite d'un `MapLayer.surface`;
- génération d'id stable `surface-main`, puis `surface-2`, `surface-3`, etc.;
- nom par défaut `Surfaces`, puis `Surfaces 2`, `Surfaces 3`, etc.;
- conservation du flux automatique Lot 84 : le premier paint peut toujours créer un `SurfaceLayer` si absent;
- ajout de tests widget/notifier couvrant le flux utilisateur réel.

Le lot ne modifie pas `map_core`, ne crée aucun rendu Surface, ne résout pas d'autotile et ne touche pas `map_runtime`.

## Périmètre

Périmètre réalisé :

- correction ciblée dans `map_editor`;
- ajout d'une option locale editor pour créer un `SurfaceLayer` sans étendre `MapLayerKind`;
- ajout d'un chemin explicite `EditorNotifier.addSurfaceLayer(...)`;
- ajout d'une méthode `AddMapLayerUseCase.executeSurface(...)`;
- ajout d'un test d'entrée UI pour la popup de création de calque;
- extension du test notifier Surface Paint.

Passes exécutées :

1. Pass 1 — Gate 0 + audit worktree : status non vide à cause du Lot 84 non commit.
2. Pass 2 — Audit de la popup “Layer type” : `LayersPanel._showAddLayerDialog`.
3. Pass 3 — Audit de `MapLayerKind` / layer use cases : `MapLayerKind` ne contient pas `surface`; création standard via `AddMapLayerUseCase`.
4. Pass 4 — Audit du flux Surface Paint du Lot 84 : `SurfacePaintingController`, `surfacePaint`, `selectedSurfacePresetId`.
5. Pass 5 — Implémentation création SurfaceLayer explicite : option locale `_LayerCreationKind.surface`.
6. Pass 6 — Correction accessibilité Surface Paint : création explicite rend `SurfaceLayer` actif, le tool devient compatible.
7. Pass 7 — Tests ciblés : surface painter, sélection, Surface Studio.
8. Pass 8 — Analyse ciblée : clean sur les fichiers touchés par ce bis.
9. Pass 9 — Auto-review critique : checklist renseignée.
10. Pass 10 — Rapport final : ce document.

Hors périmètre volontaire :

- pas de rendu des surfaces sur le canvas;
- pas de renderer runtime;
- pas de resolver autotile;
- pas d'animation clock;
- pas de migration legacy;
- pas de changement `ProjectManifest`, `surface.dart`, `surface_catalog.dart` ou codec Surface;
- pas de changement `map_runtime`, `map_gameplay`, `map_battle`.

## Gate 0 — Status initial avant modification

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
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

Changements préexistants : tous les fichiers listés ci-dessus correspondent au Lot 84 non commit au démarrage du 84-bis.

## Audit popup Layer type

Commandes d'audit :

```bash
rg -n "Layer type|Tile Layer|Collision Layer|Terrain Layer|Path Layer|Object Layer|MapLayerKind|add.*Layer|create.*Layer|layer type" packages/map_editor/lib packages/map_editor/test
rg -n "surfacePaint|SurfaceLayer|MapLayer.surface|selectedSurfacePresetId|SurfacePaintingController" packages/map_editor/lib packages/map_editor/test
```

Constats :

- La popup est construite dans `packages/map_editor/lib/src/ui/panels/layers_panel.dart`, méthode privée `_showAddLayerDialog`.
- Le picker de type utilise `showCupertinoListPicker<MapLayerKind>(items: MapLayerKind.values)`.
- Les labels affichés sont définis par `_kindLabel(MapLayerKind)`.
- `MapLayerKind` vient de `map_core` et contient `tile`, `collision`, `terrain`, `path`, `object`, mais pas `surface`.
- La création de calque standard passe par `EditorNotifier.addMapLayer(...)`, puis `AddMapLayerUseCase.execute(...)`, puis `map_core.addMapLayer(...)`.
- Les ids de layers standard sont générés dans `AddMapLayerUseCase._generateUniqueLayerId(...)`.
- `SurfaceLayer` était absent de la popup parce que le Lot 82/83 a ajouté le modèle `MapLayer.surface`, mais n'a pas ajouté `MapLayerKind.surface`.

Décision d'audit : ne pas modifier `MapLayerKind` dans ce bis. Le problème est une entrée UI editor, pas un manque de modèle `map_core`.

## Audit Surface Paint entry

Constats Lot 84 :

- `EditorToolType.surfacePaint` existe.
- `MapSelectionController` considère `surfacePaint` compatible uniquement avec `SurfaceLayer`.
- `TopToolbar` affiche Surface Paint lorsque le layer actif est un `SurfaceLayer`.
- `SurfacePainterPanel` peut créer/sélectionner un `SurfaceLayer`, mais l'entrée standard de création de calque restait incomplète.
- `SurfacePaintingController` peut toujours créer automatiquement un `SurfaceLayer` au premier paint si le flux appelle `paintSurfacePlacement`.

Blocage corrigé : l'utilisateur peut maintenant passer par la popup standard "Add Layer" -> "Layer type" -> "Surface Layer", ce qui rend le flux explicite et découvrable.

## Décision création SurfaceLayer

Décision : ajouter une option locale editor `_LayerCreationKind.surface` dans `LayersPanel`.

Pourquoi ne pas ajouter `MapLayerKind.surface` maintenant :

- cela toucherait `map_core`;
- cela élargirait le contrat partagé alors que le besoin immédiat est l'entrée UI editor;
- `MapLayer.surface` existe déjà dans le modèle de map;
- ce bis doit corriger le deadlock sans rouvrir les generated/model contracts.

Création explicite :

- `EditorNotifier.addSurfaceLayer(...)`;
- `AddMapLayerUseCase.executeSurface(...)`;
- id `surface-main`, puis `surface-2`, `surface-3`;
- nom `Surfaces`, puis `Surfaces 2`, `Surfaces 3`;
- placements vides;
- validation via `MapValidator.validate(...)`;
- le nouveau layer devient actif via `_applyMapMutation(...)`.

## Décision accessibilité Surface Paint

Décision : conserver l'Option A du prompt.

Flux utilisateur :

1. Créer `Surface Layer` depuis la popup.
2. Le nouveau `SurfaceLayer` devient actif.
3. Surface Paint devient compatible/accessible.
4. Sélectionner un preset Surface dans la palette.
5. Peindre/effacer les placements.

La création automatique Lot 84 reste disponible et non régressée.

## Implémentation

Changements principaux :

- `layers_panel.dart`
  - ajout de `_LayerCreationKind`;
  - ajout du label `Surface Layer`;
  - picker basé sur `_LayerCreationKind.values`;
  - auto-remplissage du nom `Surfaces` quand l'utilisateur choisit Surface;
  - appel à `notifier.addSurfaceLayer(...)` pour ce type.
- `layer_use_cases.dart`
  - ajout `AddMapLayerUseCase.executeSurface(...)`;
  - génération id/nom Surface dédiés.
- `editor_notifier.dart`
  - ajout `addSurfaceLayer(...)`.
- tests
  - nouveau test widget `surface_layer_creation_entry_test.dart`;
  - test notifier étendu pour confirmer Surface Paint après création explicite.

## Fichiers créés

- `packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart`
- `reports/surface/surface_engine_lot_84_bis_surface_layer_creation_entry_fix.md`

## Fichiers modifiés

Fichiers modifiés par le Lot 84-bis :

- `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/layers_panel.dart`
- `packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart`

Note : `editor_notifier.dart`, `layers_panel.dart` et `editor_notifier_surface_paint_test.dart` étaient déjà modifiés ou non suivis par le Lot 84 au Gate 0. Le présent bis y ajoute seulement la création explicite de `SurfaceLayer`.

## Fichiers supprimés

Aucun.

## Tests lancés

Test rouge initial :

```bash
cd packages/map_editor
flutter test test/surface_painter/surface_layer_creation_entry_test.dart test/surface_painter/editor_notifier_surface_paint_test.dart
```

Résultat attendu :

```text
Error: The method 'addSurfaceLayer' isn't defined for the type 'EditorNotifier'.
Some tests failed.
```

Après implémentation :

```bash
cd packages/map_editor
flutter test test/surface_painter/surface_layer_creation_entry_test.dart test/surface_painter/editor_notifier_surface_paint_test.dart
```

Résultat :

```text
+4: All tests passed!
```

Suite Surface Painter :

```bash
cd packages/map_editor
flutter test test/surface_painter
```

Résultat :

```text
+13: All tests passed!
```

Sélection layer :

```bash
cd packages/map_editor
flutter test test/map_selection_controller_test.dart
```

Résultat :

```text
+5: All tests passed!
```

Surface Studio non-régression :

```bash
cd packages/map_editor
flutter test test/surface_studio
```

Résultat :

```text
+387: All tests passed!
```

## Analyse lancée

Analyse ciblée :

```bash
cd packages/map_editor
flutter analyze \
  lib/src/application/use_cases/layer_use_cases.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/ui/panels/layers_panel.dart \
  test/surface_painter/surface_layer_creation_entry_test.dart \
  test/surface_painter/editor_notifier_surface_paint_test.dart
```

Résultat :

```text
Analyzing 5 items...
No issues found! (ran in 1.6s)
```

Analyse globale optionnelle :

```bash
cd packages/map_editor
flutter analyze lib test
```

Résultat :

```text
420 issues found. (ran in 2.0s)
```

Cette dette globale était déjà observée au Lot 84 et reste hors périmètre. Les premières erreurs concernent notamment `pokemon_sdk_move_catalog_converter.dart`, `sync_pokemon_sdk_moves_catalog_use_case.dart`, `pokedex_workspace_views.dart` et de nombreux tests anciens qui construisent `ProjectManifest` sans `surfaceCatalog`.

## Résultats

- `Surface Layer` apparaît dans la popup `Layer type`.
- La sélection crée un `MapLayer.surface`.
- Le layer créé a `placements: []`.
- L'id est unique (`surface-main`, puis `surface-2`, etc.).
- Le nom par défaut est lisible (`Surfaces`, puis `Surfaces 2`, etc.).
- Le layer créé devient actif.
- Surface Paint devient accessible dans un flux réel.
- Le paint/erase du Lot 84 continue de fonctionner.
- Aucun rendu Surface n'a été ajouté.

## Evidence Pack

Fichiers audités :

- `packages/map_editor/lib/src/ui/panels/layers_panel.dart`
- `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/application/map_selection_controller.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_painting_controller.dart`
- `packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart`
- `packages/map_editor/test/surface_painter/*`
- `packages/map_editor/test/map_selection_controller_test.dart`

Fichiers Dart modifiés par le bis analysés : voir section "Analyse lancée".

`dart format` :

```text
Formatted test/surface_painter/surface_layer_creation_entry_test.dart
Formatted 5 files (1 changed) in 0.05 seconds.
Formatted 1 file (0 changed) in 0.00 seconds.
```

## Git status final

Commandes :

```bash
git status --short --untracked-files=all
git diff --stat
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
git diff --check
```

`git status --short --untracked-files=all` :

```text
 M packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart
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
?? packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart
?? packages/map_editor/test/surface_painter/surface_painting_controller_test.dart
?? packages/map_editor/test/surface_painter/surface_palette_panel_test.dart
?? reports/surface/surface_engine_lot_84_bis_surface_layer_creation_entry_fix.md
?? reports/surface/surface_engine_lot_84_surface_painter_palette_minimal.md
```

`git diff --stat` :

```text
 .../src/application/use_cases/layer_use_cases.dart |  53 ++++++
 .../application/map_selection_controller.dart      |   5 +-
 .../src/features/editor/state/editor_notifier.dart | 180 +++++++++++++++++++++
 .../features/editor/state/editor_notifier.g.dart   |   2 +-
 .../src/features/editor/state/editor_state.dart    |   1 +
 .../editor/state/editor_state.freezed.dart         |  30 +++-
 .../editor/state/models/editor_state_groups.dart   |   9 ++
 .../lib/src/features/editor/tools/editor_tool.dart |   1 +
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   |   5 +
 .../map_editor/lib/src/ui/panels/layers_panel.dart |  65 ++++++--
 .../lib/src/ui/panels/map_inspector_panel.dart     |  30 ++++
 .../map_editor/lib/src/ui/shared/top_toolbar.dart  |  10 +-
 .../test/map_selection_controller_test.dart        |  36 +++++
 13 files changed, 404 insertions(+), 23 deletions(-)
```

`find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print` : sortie vide.

`git diff --check` : sortie vide.

## Changements préexistants

Changements préexistants au Lot 84-bis :

- tous les changements Lot 84 listés au Gate 0;
- rapport `surface_engine_lot_84_surface_painter_palette_minimal.md`;
- fichiers Surface Painter ajoutés par le Lot 84.

Ces fichiers restent présents au status final.

## Changements du Lot 84-bis

Changements propres au bis :

- `Surface Layer` ajouté au picker local de `LayersPanel`;
- `AddMapLayerUseCase.executeSurface(...)`;
- `EditorNotifier.addSurfaceLayer(...)`;
- test widget de création explicite SurfaceLayer;
- extension du test notifier Surface Paint;
- rapport 84-bis.

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
- aucun rendu des surfaces sur le canvas;
- `Runner.xcscheme` non modifié par ce lot.

## Vérification fichiers temporaires

Commande :

```bash
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

Résultat : sortie vide.

## Vérification mojibake

Commande :

```bash
rg -n "Ã|Â|�" \
  packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart \
  packages/map_editor/lib/src/features/editor/state/editor_notifier.dart \
  packages/map_editor/lib/src/ui/panels/layers_panel.dart \
  packages/map_editor/test/surface_painter/surface_layer_creation_entry_test.dart \
  packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart \
  reports/surface/surface_engine_lot_84_bis_surface_layer_creation_entry_fix.md || true
```

Résultat : sortie vide.

## Auto-review

- Est-ce que Surface Layer apparaît dans la popup Layer type ? Oui.
- Est-ce que cliquer Surface Layer crée un `MapLayer.surface` ? Oui.
- Est-ce que l'id du layer est unique ? Oui.
- Est-ce que le SurfaceLayer apparaît dans la liste des layers ? Oui, via le layer list existant.
- Est-ce que Surface Paint est accessible dans un flux utilisateur réel ? Oui : création explicite -> layer actif -> preset sélectionné -> `surfacePaint`.
- Est-ce que le paint ajoute un `SurfaceCellPlacement` ? Oui.
- Est-ce que erase supprime un `SurfaceCellPlacement` ? Oui, comportement Lot 84 inchangé.
- Est-ce que la création automatique du Lot 84 fonctionne encore ? Oui, test Surface Painter complet vert.
- Est-ce que TerrainLayer / PathLayer / TileLayer restent inchangés ? Oui, leur création standard passe toujours par `MapLayerKind`.
- Est-ce qu'un rendu Surface est ajouté ? Non.
- Est-ce qu'un resolver autotile est ajouté ? Non.
- Est-ce que map_runtime est modifié ? Non.
- Est-ce que les tests ciblés passent ? Oui.
- Est-ce que l'analyse ciblée passe ? Oui.
- Est-ce qu'un fichier présent au status initial a disparu du status final ? Non attendu; confirmé au Gate final.
- Est-ce qu'un fichier hors périmètre a été modifié ? Non.
- Est-ce qu'un 84-ter est nécessaire ? Non pour le deadlock d'entrée; un futur lot de preview/rendu reste nécessaire mais ce n'est pas un bis.

## Critique du prompt

- Ajouter `SurfaceLayer` à `MapLayerKind` aurait été plus uniforme, mais aurait élargi le contrat `map_core`; pour un bis ciblé, l'option locale editor est plus sûre.
- La coexistence entre création explicite et création automatique fait doublon, mais améliore nettement l'UX V0 : l'utilisateur peut découvrir le flux ou être aidé au premier paint.
- Garder Surface Paint conditionné au layer actif est cohérent avec l'architecture, mais moins découvrable qu'un outil toujours visible. Ce bis corrige le blocage sans refondre la toolbar.
- Le test widget de popup est plus fragile qu'un test pur, mais il couvre précisément le deadlock signalé par la capture.
