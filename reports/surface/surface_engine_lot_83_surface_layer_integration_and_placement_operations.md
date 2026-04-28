# Lot 83 — SurfaceLayer Integration + Placement Operations V0

## Résumé exécutif

Le Lot 83 rend `MapLayer.surface` manipulable côté `map_core` et toléré côté `map_editor` / `map_runtime`, sans créer de painter, palette, resolver autotile, renderer Flame, migration legacy ou diagnostic de placement.

Ajouts principaux :

- API pure `surface_layer_placements.dart` :
  - `isSurfaceLayer`
  - `getSurfacePlacements`
  - `surfacePlacementAt`
  - `paintSurfacePlacement`
  - `eraseSurfacePlacement`
  - `clearSurfacePlacements`
  - `replaceSurfacePlacements`
- Export public depuis `packages/map_core/lib/map_core.dart`.
- Tests `map_core` sur paint / replace / erase / clear / tri déterministe / validations / helpers existants / resize.
- Tolérance editor :
  - `layers_panel.dart` affiche un `SurfaceLayer` avec label/icon neutres.
  - `map_inspector_panel.dart` ajoute les branches `SurfaceLayer` aux switchs exhaustifs.
- Tolérance runtime :
  - `runtime_manifest_tilesets.dart` ignore explicitement `SurfaceLayer` pour le collecteur V0.
  - `map_layers_component.dart` documente le no-op rendu V0.
  - test runtime ciblé confirmant que le collecteur ne crash pas et ne collecte pas de tilesets Surface prématurément.

Le lot ne modifie pas `ProjectManifest`, `surface.dart`, `surface_catalog.dart`, les codecs Surface, `map_gameplay`, `map_battle`, ni les exemples.

## Périmètre

### Inclus

- Opérations pures sur `SurfaceLayer` dans `map_core`.
- Export de ces opérations.
- Compatibilité no-op minimale dans `map_editor`.
- Compatibilité no-op minimale dans `map_runtime`.
- Tests ciblés `map_core` et `map_runtime`.
- Rapport d'exécution.

### Exclu

- Surface Painter UI.
- Surface Palette UI.
- Surface Editor Preview.
- Surface Runtime Renderer.
- Surface Animation Clock Runtime.
- Surface Autotile Resolver.
- Surface Placement Diagnostics.
- Migration legacy.
- Provider / repository / service Surface.
- Modification `ProjectManifest` ou catalogue Surface.

## Gate 0 — Status initial avant modification

Commande exécutée avant toute modification Lot 83 :

```text
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
 M packages/map_core/lib/src/models/map_layer.dart
 M packages/map_core/lib/src/models/map_layer.freezed.dart
 M packages/map_core/lib/src/models/map_layer.g.dart
 M packages/map_core/lib/src/operations/map_layers.dart
 M packages/map_core/lib/src/operations/map_resize.dart
 M packages/map_core/lib/src/validation/validators.dart
?? packages/map_core/test/surface_layer_model_test.dart
?? reports/surface/surface_engine_lot_82_surface_layer_model.md
 packages/map_core/lib/src/models/map_layer.dart    |  23 +
 .../map_core/lib/src/models/map_layer.freezed.dart | 709 +++++++++++++++++++++
 packages/map_core/lib/src/models/map_layer.g.dart  |  45 ++
 .../map_core/lib/src/operations/map_layers.dart    |   5 +
 .../map_core/lib/src/operations/map_resize.dart    |   9 +
 .../map_core/lib/src/validation/validators.dart    |  45 +-
 6 files changed, 834 insertions(+), 2 deletions(-)
9645a04b docs(surface): decide surface placement model
19c75e77 feat(map_editor): ajouter preset vertical atlas et golden slice e2e
ccdf1094 fix(map_editor): lisibilité et ergonomie sélecteur colonne aperçu atlas
33d776aa feat(map_editor): Lot 78 — animations Surface depuis atlas vertical
1a92a64e feat(map_editor): Surface Studio Lot 77 — plan génération animations atlas vertical
021abf5f feat(map_editor): Surface Studio Lots 75–76 — mapping colonnes + preview animation
cd9bf788 feat(map_editor): Surface Studio Lot 74 — assistant atlas vertical + preview grand format
13569f30 feat(map_editor): Surface Studio Lot 73 — grille sur aperçu image source
24467c67 feat(map_editor): Surface Studio Lot 72 — aperçu image source (résolution disque)
fcdc064d feat(map_editor): Surface Studio Lot 71 — aperçu grille atlas (preview V0)
```

Le status initial n'était pas vide. Les fichiers listés ci-dessus sont classés comme changements préexistants du Lot 82.

## Audit MapLayer usages

Recherches lancées :

```text
rg -n "MapLayer" packages/map_core/lib packages/map_core/test
rg -n "\.when\(|\.map\(|maybeWhen|maybeMap|switch.*MapLayer|runtimeType" packages/map_core/lib packages/map_core/test
rg -n "MapLayer" packages/map_editor/lib packages/map_editor/test
rg -n "\.when\(|\.map\(|maybeWhen|maybeMap|switch.*MapLayer|runtimeType" packages/map_editor/lib packages/map_editor/test
rg -n "MapLayer" packages/map_runtime/lib packages/map_runtime/test
rg -n "\.when\(|\.map\(|maybeWhen|maybeMap|switch.*MapLayer|runtimeType" packages/map_runtime/lib packages/map_runtime/test
```

Synthèse :

- `map_core`
  - `validators.dart` avait déjà une branche `surface` issue du Lot 82.
  - `map_resize.dart` avait déjà une branche `surface` issue du Lot 82.
  - `map_layers.dart` avait déjà une branche `surface` dans `_copyLayer` issue du Lot 82.
  - Aucun autre dispatch `MapLayer` non generated n'a nécessité de modification Lot 83.
- `map_editor`
  - `layers_panel.dart` utilisait `layer.map(...)` sans branche `surface`.
  - `map_inspector_panel.dart` utilisait des switchs exhaustifs sur les sous-types `MapLayer` sans `SurfaceLayer`.
- `map_runtime`
  - `runtime_manifest_tilesets.dart` utilisait `layer.when(...)` sans branche `surface`.
  - `map_layers_component.dart` utilise `whenOrNull`, donc `SurfaceLayer` était déjà ignoré implicitement. Un commentaire explicite a été ajouté pour documenter le no-op V0.

## Audit map_core

Fichiers lus / audités :

- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/map_layer.freezed.dart`
- `packages/map_core/lib/src/models/map_layer.g.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/geometry.dart`
- `packages/map_core/lib/src/exceptions/map_exceptions.dart`
- `packages/map_core/lib/src/operations/map_layers.dart`
- `packages/map_core/lib/src/operations/map_resize.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/surface_layer_model_test.dart`

Constats :

- `SurfaceCellPlacement` et `MapLayer.surface` existent déjà grâce au Lot 82.
- Les validations minimales de modèle sont déjà présentes dans `MapValidator` :
  - `surfacePresetId` non vide ;
  - coordonnées dans les bornes ;
  - doublons de coordonnées refusés dans un même `SurfaceLayer` ;
  - propriétés avec clés non vides.
- `resizeMapData` conserve les placements dans les nouvelles bornes et supprime ceux hors bornes.
- Les helpers génériques de layer (`renameMapLayer`, visibilité, opacité) tolèrent déjà `SurfaceLayer`.

Lot 83 ajoute donc uniquement des opérations pures de manipulation.

## Audit map_editor

Fichiers lus / audités :

- `packages/map_editor/lib/src/ui/panels/layers_panel.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/terrain_map_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`

Modifications nécessaires :

- `layers_panel.dart` :
  - ajout d'un label `surface` ;
  - ajout d'une icône neutre ;
  - commentaire explicitant que le painter/rendu Surface viendra plus tard.
- `map_inspector_panel.dart` :
  - ajout de `SurfaceLayer` aux switchs exhaustifs.

Fichiers laissés inchangés :

- `layer_use_cases.dart` : `MapLayerKind` ne contient pas `surface`, volontairement. Le Lot 83 ne doit pas permettre la création UI de SurfaceLayer via le panneau de layers.
- `terrain_map_panel.dart` et `map_grid_painter.dart` : pas de painter Surface dans ce lot.
- `editor_notifier.dart` : pas de nouvelle action de peinture Surface.

## Audit map_runtime

Fichiers lus / audités :

- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/test/map_layers_component_render_pass_test.dart`

Modifications nécessaires :

- `runtime_manifest_tilesets.dart` :
  - ajout de branches `surface` no-op dans les `layer.when(...)`.
  - décision : ne pas collecter les tilesets Surface maintenant.
- `map_layers_component.dart` :
  - pas de renderer Surface ;
  - commentaire explicite sur le no-op rendu V0.

Test ajouté :

- `packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart`
  - prouve que `collectTilesetIdsReferencedOnMap(...)` tolère un `SurfaceLayer` et ne collecte que le tileset de base pour l'instant.

## Décisions d’intégration

### Ordre déterministe des placements

Les opérations Lot 83 trient les placements par :

```text
y, puis x, puis surfacePresetId
```

Justification :

- JSON stable ;
- diffs propres ;
- comportement indépendant de l'ordre de peinture utilisateur ;
- tests simples.

### Doublons

- `paintSurfacePlacement` remplace le placement existant à même `x/y`.
- `replaceSurfacePlacements` refuse les doublons `x/y` avec `ValidationException`.

Justification :

- painting interactif : repeindre une cellule doit remplacer.
- bulk replace / import : choisir silencieusement un gagnant serait trop implicite.

### Runtime tilesets Surface

Décision V0 : ne pas collecter les tilesets Surface dans `runtime_manifest_tilesets.dart`.

Justification :

- le renderer Surface n'existe pas encore ;
- le resolver runtime Surface n'existe pas encore ;
- la résolution `surfacePresetId -> preset -> animations -> atlas -> tilesetId` doit arriver dans un lot dédié et testé.

## Opérations SurfaceLayer ajoutées

Fichier :

- `packages/map_core/lib/src/operations/surface_layer_placements.dart`

API :

```text
bool isSurfaceLayer(MapLayer layer)
List<SurfaceCellPlacement> getSurfacePlacements(MapLayer layer)
SurfaceCellPlacement? surfacePlacementAt({required MapLayer layer, required int x, required int y})
MapLayer paintSurfacePlacement({required MapLayer layer, required GridSize mapSize, required int x, required int y, required String surfacePresetId})
MapLayer eraseSurfacePlacement({required MapLayer layer, required int x, required int y})
MapLayer clearSurfacePlacements(MapLayer layer)
MapLayer replaceSurfacePlacements({required MapLayer layer, required GridSize mapSize, required Iterable<SurfaceCellPlacement> placements})
```

Validation :

- exige `SurfaceLayer` ;
- `mapSize.width > 0` et `mapSize.height > 0` pour paint/replace ;
- `x >= 0`, `y >= 0` ;
- `x < mapSize.width`, `y < mapSize.height` pour paint/replace ;
- `surfacePresetId.trim().isNotEmpty` ;
- doublons `x/y` refusés dans `replaceSurfacePlacements`.

Non fait :

- pas de validation contre `ProjectManifest.surfaceCatalog` ;
- pas de rôle autotile ;
- pas d'`animationId`, `atlasId`, `tilesetId` dans les placements ;
- pas de resolver Surface.

## Intégration map_core

Ajout :

- export public dans `packages/map_core/lib/map_core.dart`.

Pas de modification des modèles dans Lot 83 :

- `map_layer.dart`, `map_layer.freezed.dart`, `map_layer.g.dart`, `validators.dart`, `map_resize.dart`, `map_layers.dart` étaient déjà modifiés au Gate 0 par le Lot 82.
- `build_runner` n'a pas été lancé dans ce lot.

## Intégration map_editor

`map_editor` tolère `SurfaceLayer` dans :

- la liste des layers ;
- l'inspector.

Comportement V0 :

- affichage neutre ;
- aucune action painter ;
- aucun rendu surface ;
- aucune palette Surface ;
- aucun outil de création de SurfaceLayer depuis l'UI.

## Intégration map_runtime

`map_runtime` tolère `SurfaceLayer` dans :

- la collecte des tilesets référencés directement par une map ;
- la collecte legacy terrain/path ;
- le rendu Flame, en no-op documenté.

Comportement V0 :

- chargement toléré ;
- rendu ignoré ;
- pas de collecte Surface catalog ;
- pas de resolver d'animation Surface.

## Fichiers créés

Changements Lot 83 :

- `packages/map_core/lib/src/operations/surface_layer_placements.dart`
- `packages/map_core/test/surface_layer_placements_test.dart`
- `packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart`
- `reports/surface/surface_engine_lot_83_surface_layer_integration_and_placement_operations.md`

Préexistant au Gate 0 :

- `packages/map_core/test/surface_layer_model_test.dart`
- `reports/surface/surface_engine_lot_82_surface_layer_model.md`

## Fichiers modifiés

Changements Lot 83 :

- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/panels/layers_panel.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

Préexistants au Gate 0, non créés par Lot 83 :

- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/map_layer.freezed.dart`
- `packages/map_core/lib/src/models/map_layer.g.dart`
- `packages/map_core/lib/src/operations/map_layers.dart`
- `packages/map_core/lib/src/operations/map_resize.dart`
- `packages/map_core/lib/src/validation/validators.dart`

## Fichiers supprimés

Aucun.

## Generated files

Aucun fichier generated n'a été modifié par le Lot 83.

Les fichiers generated présents dans le diff (`map_layer.freezed.dart`, `map_layer.g.dart`) étaient déjà modifiés au Gate 0 par le Lot 82.

## Tests lancés

### RED attendu

Commande :

```text
cd packages/map_core
dart test test/surface_layer_placements_test.dart
```

Résultat initial attendu :

```text
Failed to load "test/surface_layer_placements_test.dart":
Method not found: 'isSurfaceLayer'
Method not found: 'getSurfacePlacements'
Method not found: 'surfacePlacementAt'
Method not found: 'paintSurfacePlacement'
Method not found: 'eraseSurfacePlacement'
Method not found: 'clearSurfacePlacements'
Method not found: 'replaceSurfacePlacements'
Some tests failed.
```

### Tests ciblés map_core

```text
cd packages/map_core
dart test test/surface_layer_placements_test.dart
```

Résultat :

```text
+14: All tests passed!
```

```text
cd packages/map_core
dart test test/surface_layer_model_test.dart
```

Résultat :

```text
+16: All tests passed!
```

### Suite complète map_core

```text
cd packages/map_core
dart test
```

Résultat exact :

```text
+1248: All tests passed!
```

### Test ciblé map_runtime

```text
cd packages/map_runtime
flutter test test/runtime_manifest_tilesets_surface_layer_test.dart
```

Résultat :

```text
+1: All tests passed!
```

## Analyse lancée

### map_core ciblé

```text
cd packages/map_core
dart analyze lib/src/operations/surface_layer_placements.dart test/surface_layer_placements_test.dart lib/map_core.dart
```

Résultat :

```text
Analyzing surface_layer_placements.dart, surface_layer_placements_test.dart, map_core.dart...
No issues found!
```

### map_core global

```text
cd packages/map_core
dart analyze lib test
```

Résultat :

```text
Analyzing lib, test...

   info - lib/src/models/enums.dart:34:3 - The constant name 'upper_floor' isn't a lowerCamelCase identifier. Try changing the name to follow the lowerCamelCase style. - constant_identifier_names
   info - lib/src/models/enums.dart:44:3 - The constant name 'sub_area' isn't a lowerCamelCase identifier. Try changing the name to follow the lowerCamelCase style. - constant_identifier_names

2 issues found.
```

Ces 2 infos sont préexistantes et hors Lot 83.

### map_editor global

```text
cd packages/map_editor
flutter analyze lib test
```

Résultat :

```text
419 issues found. (ran in 3.3s)
```

Les erreurs sont préexistantes et hors fichiers Lot 83. Elles touchent notamment :

- `pokemon_sdk_move_catalog_converter.dart` ;
- plusieurs tests qui construisent `ProjectManifest` sans `surfaceCatalog` ;
- `pokedex_workspace_views.dart`.

Analyse ciblée des fichiers modifiés :

```text
cd packages/map_editor
flutter analyze lib/src/ui/panels/layers_panel.dart lib/src/ui/panels/map_inspector_panel.dart
```

Résultat :

```text
Analyzing 2 items...

No issues found! (ran in 1.8s)
```

### map_runtime global

```text
cd packages/map_runtime
flutter analyze lib test
```

Résultat :

```text
412 issues found. (ran in 3.0s)
```

Les erreurs sont préexistantes et hors fichiers Lot 83. Elles touchent notamment :

- de nombreuses infos `prefer_const_constructors` ;
- des tests existants avec construction de `ProjectManifest` / fixtures obsolètes ;
- des erreurs de syntaxe préexistantes dans certains tests runtime.

Analyse ciblée des fichiers modifiés :

```text
cd packages/map_runtime
flutter analyze lib/src/application/runtime_manifest_tilesets.dart lib/src/presentation/flame/map_layers_component.dart test/runtime_manifest_tilesets_surface_layer_test.dart
```

Résultat :

```text
Analyzing 3 items...

No issues found! (ran in 1.5s)
```

## Résultats

- `map_core` ciblé : vert.
- `map_core` complet : vert, `+1248`.
- `map_core` analyse ciblée : clean.
- `map_core` analyse globale : 2 infos préexistantes.
- `map_runtime` test ciblé : vert.
- `map_runtime` analyse ciblée : clean.
- `map_runtime` analyse globale : dette préexistante.
- `map_editor` analyse ciblée : clean.
- `map_editor` analyse globale : dette préexistante.

## Evidence Pack

### Status initial complet

Voir section "Gate 0 — Status initial avant modification".

### Fichiers audités

- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/map_layer.freezed.dart`
- `packages/map_core/lib/src/models/map_layer.g.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/geometry.dart`
- `packages/map_core/lib/src/exceptions/map_exceptions.dart`
- `packages/map_core/lib/src/operations/map_layers.dart`
- `packages/map_core/lib/src/operations/map_resize.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/surface_layer_model_test.dart`
- `packages/map_editor/lib/src/ui/panels/layers_panel.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/application/use_cases/layer_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/terrain_map_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/test/map_layers_component_render_pass_test.dart`

### Passes internes

- Pass 1 — Audit `map_core` autour de `MapLayer.surface` : fait.
- Pass 2 — Audit `map_editor` : fait, deux fichiers modifiés.
- Pass 3 — Audit `map_runtime` : fait, deux fichiers modifiés et un test ajouté.
- Pass 4 — Implémentation opérations pures SurfaceLayer dans `map_core` : fait.
- Pass 5 — Sweep intégration `map_editor` no-op : fait.
- Pass 6 — Sweep intégration `map_runtime` no-op : fait.
- Pass 7 — Tests ciblés + suite `map_core` : fait.
- Pass 8 — Analyze final par package touché : fait, dette globale préexistante isolée.
- Pass 9 — Review séparée / auto-critique : fait.
- Pass 10 — Rapport final : fait.

## Git status final

Commande :

```text
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/models/map_layer.dart
 M packages/map_core/lib/src/models/map_layer.freezed.dart
 M packages/map_core/lib/src/models/map_layer.g.dart
 M packages/map_core/lib/src/operations/map_layers.dart
 M packages/map_core/lib/src/operations/map_resize.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_editor/lib/src/ui/panels/layers_panel.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart
 M packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
?? packages/map_core/lib/src/operations/surface_layer_placements.dart
?? packages/map_core/test/surface_layer_model_test.dart
?? packages/map_core/test/surface_layer_placements_test.dart
?? packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart
?? reports/surface/surface_engine_lot_82_surface_layer_model.md
?? reports/surface/surface_engine_lot_83_surface_layer_integration_and_placement_operations.md
```

Commande :

```text
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart                |   1 +
 packages/map_core/lib/src/models/map_layer.dart    |  23 +
 .../map_core/lib/src/models/map_layer.freezed.dart | 709 +++++++++++++++++++++
 packages/map_core/lib/src/models/map_layer.g.dart  |  45 ++
 .../map_core/lib/src/operations/map_layers.dart    |   5 +
 .../map_core/lib/src/operations/map_resize.dart    |   9 +
 .../map_core/lib/src/validation/validators.dart    |  45 +-
 .../map_editor/lib/src/ui/panels/layers_panel.dart |   4 +
 .../lib/src/ui/panels/map_inspector_panel.dart     |   2 +
 .../src/application/runtime_manifest_tilesets.dart |  12 +-
 .../presentation/flame/map_layers_component.dart   |   2 +
 11 files changed, 853 insertions(+), 4 deletions(-)
```

Les fichiers Lot 82 présents au Gate 0 restent présents au status final. Aucun fichier du Gate 0 n'a disparu.

## Changements préexistants

Présents dès le Gate 0 :

- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/map_layer.freezed.dart`
- `packages/map_core/lib/src/models/map_layer.g.dart`
- `packages/map_core/lib/src/operations/map_layers.dart`
- `packages/map_core/lib/src/operations/map_resize.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/test/surface_layer_model_test.dart`
- `reports/surface/surface_engine_lot_82_surface_layer_model.md`

Ces changements appartiennent au Lot 82 et ne doivent pas être attribués au Lot 83.

## Changements du Lot 83

- `packages/map_core/lib/src/operations/surface_layer_placements.dart`
- `packages/map_core/test/surface_layer_placements_test.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/panels/layers_panel.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_runtime/lib/src/application/runtime_manifest_tilesets.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart`
- `reports/surface/surface_engine_lot_83_surface_layer_integration_and_placement_operations.md`

## Périmètre explicitement non touché

- `ProjectManifest` non modifié.
- `surface.dart` non modifié.
- `surface_catalog.dart` non modifié.
- Codecs Surface non modifiés.
- Surface Studio authoring vertical atlas non modifié.
- Aucun painter Surface créé.
- Aucune palette Surface créée.
- Aucun outil Surface Painter créé.
- Aucun resolver autotile Surface créé.
- Aucun renderer runtime Surface créé.
- Aucune animation clock runtime créée.
- Aucune migration legacy codée.
- Aucun provider / repository / service Surface créé.
- Aucun changement `map_gameplay`.
- Aucun changement `map_battle`.
- `Runner.xcscheme` non modifié par ce lot.
- `build_runner` non lancé dans ce lot.

## Vérification fichiers temporaires

Commande :

```text
find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print
```

Sortie :

```text
```

Aucun fichier temporaire correspondant n'a été trouvé.

## Vérification mojibake

Commande :

```text
rg -n "Ã|�" packages/map_core/lib/src/operations/surface_layer_placements.dart packages/map_core/test/surface_layer_placements_test.dart packages/map_runtime/test/runtime_manifest_tilesets_surface_layer_test.dart
```

Sortie :

```text
```

Aucun mojibake détecté dans les fichiers Dart Lot 83 explicitement vérifiés. Le rapport a été relu après rédaction pour éviter un faux positif causé par l'affichage littéral des marqueurs dans la section de vérification.

## Auto-review

- Est-ce que le repo tolère `MapLayer.surface` dans `map_core` ? Oui.
- Est-ce que `map_editor` compile/analyze avec `MapLayer.surface` ? Les fichiers touchés analysent clean ; l'analyse globale a une dette préexistante hors Lot 83.
- Est-ce que `map_runtime` compile/analyze avec `MapLayer.surface` ? Les fichiers touchés analysent clean ; l'analyse globale a une dette préexistante hors Lot 83.
- Est-ce que des opérations pures SurfaceLayer existent ? Oui.
- Est-ce que `paintSurfacePlacement` remplace proprement un placement existant ? Oui, testé.
- Est-ce que `eraseSurfacePlacement` fonctionne ? Oui, testé.
- Est-ce que `clearSurfacePlacements` fonctionne ? Oui, testé.
- Est-ce que l'ordre des placements est déterministe ? Oui, tri `y/x/surfacePresetId`, testé.
- Est-ce que les doublons de coordonnées sont empêchés ? Oui, `replaceSurfacePlacements` les refuse et `paintSurfacePlacement` remplace.
- Est-ce que les coordonnées hors map sont refusées ? Oui pour paint/replace, testé.
- Est-ce que `surfacePresetId` vide est refusé ? Oui, testé.
- Est-ce que `ProjectManifest` est modifié ? Non.
- Est-ce que `surface.dart` est modifié ? Non.
- Est-ce qu'un painter Surface a été créé ? Non.
- Est-ce qu'un renderer runtime Surface a été créé ? Non.
- Est-ce que les tests `map_core` passent ? Oui, `+1248`.
- Est-ce que les tests editor/runtime pertinents passent ? Runtime ciblé oui ; aucun test editor n'a été ajouté, analyse ciblée clean.
- Est-ce que les analyses finales passent ? Oui sur fichiers modifiés ; global editor/runtime ont une dette préexistante documentée.
- Est-ce qu'un fichier présent au status initial a disparu du status final ? Non.
- Est-ce qu'un fichier hors périmètre a été modifié ? Non.
- Est-ce qu'un 83-bis est nécessaire ? Non, sauf si l'équipe souhaite traiter la dette globale editor/runtime dans un lot séparé.

## Critique du prompt

- Le prompt demande `flutter analyze lib test` global dans `map_editor` et `map_runtime`. C'est utile pour révéler la dette, mais trop large pour conclure sur Lot 83 dans ce repo actuel : les deux packages ont des erreurs préexistantes sans rapport direct avec `SurfaceLayer`.
- La demande de support editor/runtime est ambitieuse pour un lot qui ne doit pas créer de painter/renderer. La stratégie no-op explicite reste la plus prudente.
- Collecter les tilesets Surface maintenant aurait été prématuré : il manque encore un resolver runtime `surfacePresetId -> catalog -> animation -> atlas`.
- Garder `MapLayerKind` sans `surface` est important : ajouter la valeur aurait ouvert une surface de création UI hors scope.
