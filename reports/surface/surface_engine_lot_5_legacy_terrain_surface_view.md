# Surface Engine Lot 5 - Legacy Terrain Surface View Adapter V0

## 1. Resume executif

Le Lot 5 ajoute une petite API pure dans `map_core` pour exposer un `ProjectTerrainPreset` existant comme une vue de surface terrain legacy en lecture seule.

Cette API est le miroir prudent du Lot 4 cote terrain. Elle ne cree pas de modele `SurfaceDefinition`, ne cree pas de vue unifiee Surface, ne modifie pas le schema JSON et ne branche rien dans le runtime ou l'editeur.

La nouvelle API vit dans :

- `packages/map_core/lib/src/operations/legacy_terrain_surface_view.dart`

Elle est exportee par :

- `packages/map_core/lib/map_core.dart`

Elle est couverte par :

- `packages/map_core/test/legacy_terrain_surface_view_test.dart`

Le test a ete ecrit avant l'implementation. Le premier passage a echoue comme attendu parce que `createLegacyTerrainSurfaceView` et `LegacyTerrainSurfaceVariantView` n'existaient pas encore. Apres implementation minimale, les tests Lot 5, les tests des lots precedents, l'analyse ciblee et le test complet `map_core` passent.

## 2. Pourquoi ce lot est necessaire apres le Lot 4

Le Lot 4 a cree `LegacyPathSurfaceView`, une vue read-only d'un `ProjectPathPreset`. Ce pont permet de parler de surfaces path legacy sans modifier le modele persistant.

Le Lot 5 applique le meme principe a `ProjectTerrainPreset`, car les presets terrain portent deja des donnees proches d'une surface visuelle :

- `id`
- `name`
- `terrainType`
- `tilesetId`
- `categoryId`
- `sortOrder`
- `variants`
- `TerrainPresetVariant.frames`
- `TerrainPresetVariant.weight`

Le but est de preparer la migration Surface Engine progressivement, sans fusionner trop tot les chemins et terrains dans une abstraction commune. Les terrains legacy restent donc exposes par `TerrainType`, pas par `PathSurfaceKind`.

## 3. Fichiers consultes

Fichiers source consultes :

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/operations/legacy_path_surface_view.dart`
- `packages/map_core/lib/src/operations/tile_visual_frame_timeline.dart`
- `packages/map_core/lib/map_core.dart`

Tests consultes :

- `packages/map_core/test/project_manifest_surface_json_characterization_test.dart`
- `packages/map_core/test/path_preset_frames_test.dart`
- `packages/map_core/test/legacy_path_surface_view_test.dart`
- `packages/map_core/test/tile_visual_frame_timeline_test.dart`

Fichier d'instructions consulte :

- `AGENTS.md`

Commandes Git de lecture utilisees :

- `git status --short`

Aucune commande Git d'ecriture n'a ete utilisee.

## 4. Fichiers crees

- `packages/map_core/lib/src/operations/legacy_terrain_surface_view.dart`
- `packages/map_core/test/legacy_terrain_surface_view_test.dart`
- `reports/analysis/surface_engine_lot_5_legacy_terrain_surface_view.md`

## 5. Fichiers modifies

- `packages/map_core/lib/map_core.dart`

Modification unique dans le barrel public :

```dart
export 'src/operations/legacy_terrain_surface_view.dart';
```

Aucun autre fichier de production existant n'a ete modifie.

## 6. API ajoutee

### `LegacyTerrainSurfaceView`

Vue read-only d'un `ProjectTerrainPreset` legacy.

Champs exposes :

- `id`
- `name`
- `terrainType`
- `tilesetId`
- `categoryId`
- `sortOrder`
- `variants`

Getters :

- `hasVariants`
- `hasAnimatedVariants`
- `hasWeightedVariants`

### `LegacyTerrainSurfaceVariantView`

Vue read-only d'un `TerrainPresetVariant`.

Champs exposes :

- `frames`
- `weight`

Getters :

- `hasFrames`
- `isAnimated`

### `createLegacyTerrainSurfaceView(ProjectTerrainPreset preset)`

Fonction pure qui cree une vue read-only depuis un `ProjectTerrainPreset`.

## 7. Semantique de l'adaptateur

`createLegacyTerrainSurfaceView` copie les valeurs suivantes depuis le preset :

- `id`
- `name`
- `terrainType`
- `tilesetId`
- `categoryId`
- `sortOrder`
- ordre exact de `variants`
- ordre exact des `frames`
- `weight`

Les listes exposees sont non mutables :

- `LegacyTerrainSurfaceView.variants` est cree avec `List.unmodifiable(...)` ;
- `LegacyTerrainSurfaceVariantView.frames` est cree avec `List.unmodifiable(...)`.

Les objets `TilesetVisualFrame` ne sont pas clones. Ils sont des valeurs Freezed immutables, et l'adaptateur preserve leur identite.

`hasAnimatedVariants` vaut `true` si au moins une variante contient plus d'une frame. Les durees ne sont pas inspectees.

`LegacyTerrainSurfaceVariantView.isAnimated` vaut `true` si `frames.length > 1`.

`hasWeightedVariants` vaut `true` si au moins une variante a un poids different du poids par defaut reel du modele. L'audit confirme que `TerrainPresetVariant.weight` utilise `@Default(1)`, donc le poids par defaut est `1`.

Les presets sans variants sont acceptes :

- `variants` est vide ;
- `hasVariants == false` ;
- `hasAnimatedVariants == false` ;
- `hasWeightedVariants == false`.

## 8. Liste complete des cas testes

Le fichier `legacy_terrain_surface_view_test.dart` couvre :

1. Adaptation d'un preset terrain simple `grass` avec `id`, `name`, `terrainType`, `tilesetId`, `categoryId`, `sortOrder`, une variante et une frame.
2. Adaptation de plusieurs `TerrainType` : `grass`, `sand`, `rock`.
3. Preservation de l'ordre des variants avec weights differents.
4. Preservation de l'ordre des frames.
5. Preservation des `durationMs`.
6. Preservation d'un override de frame `tilesetId: 'animated-terrain-atlas'`.
7. Preservation exacte des weights.
8. Immutabilite de `view.variants`.
9. Immutabilite de `view.variants.first.frames`.
10. Absence de mutation du `ProjectTerrainPreset` source.
11. Preservation des variants, frames et weights dans le preset source.
12. Preset sans variants.
13. `hasAnimatedVariants` pour presets statiques et animes.
14. `LegacyTerrainSurfaceVariantView.hasFrames`.
15. `LegacyTerrainSurfaceVariantView.isAnimated`.
16. `hasWeightedVariants` avec poids par defaut `1`.
17. `hasWeightedVariants` avec poids non defaut.

## 9. Ce que les tests prouvent

Les tests prouvent que la nouvelle vue :

- expose correctement `TerrainType.grass` ;
- expose correctement `TerrainType.sand` ;
- expose correctement `TerrainType.rock` ;
- ne passe pas par `PathSurfaceKind` ;
- preserve les valeurs simples du preset ;
- preserve `categoryId` nullable ;
- preserve le `tilesetId` du preset ;
- preserve l'ordre des variants ;
- preserve l'ordre des frames ;
- preserve les durees des frames ;
- preserve les overrides `tilesetId` des frames ;
- preserve les objets `TilesetVisualFrame` ;
- preserve les weights ;
- detecte les weights non defaut par rapport a `1` ;
- gere les presets sans variants ;
- expose une detection structurelle d'animation ;
- empeche les mutations externes des listes exposees ;
- ne modifie pas le preset source.

## 10. Ce qui n'a volontairement pas ete fait

Ce lot n'a pas :

- cree `SurfaceDefinition` ;
- cree `SurfaceEngine` ;
- cree une union commune `LegacySurfaceView` ;
- ajoute `surfaceDefinitions` a `ProjectManifest` ;
- modifie `ProjectManifest` ;
- modifie les modeles Freezed/JSON ;
- lance `build_runner` ;
- modifie un fichier `.g.dart` ;
- modifie un fichier `.freezed.dart` ;
- modifie `map_runtime` ;
- modifie `map_editor` ;
- modifie `map_gameplay` ;
- modifie `map_battle` ;
- modifie `RuntimePathAutotileSet` ;
- modifie `MapLayersComponent` ;
- modifie `PathLayer` ;
- modifie `TerrainLayer` ;
- modifie `ProjectPathPreset` ;
- modifie `ProjectTerrainPreset` ;
- modifie `LegacyPathSurfaceView` ;
- modifie `tile_visual_frame_timeline.dart` ;
- modifie `map_terrain_autotile.dart` ;
- cree une migration ;
- cree du JSON ;
- branche cette vue dans le runtime ou l'editeur.

## 11. Impact pour les futurs modeles Surface

Cette vue donne une surface de compatibilite terrain qui peut servir plus tard a :

- comparer un `ProjectTerrainPreset` legacy a une future `SurfaceDefinition` ;
- construire un outil de migration terrain explicite ;
- garder les poids de variantes dans un format lisible ;
- distinguer terrains legacy et paths legacy ;
- eviter une union commune prematuree ;
- tester une future representation de surfaces sans casser les presets existants.

Le choix de ne pas fusionner `LegacyPathSurfaceView` et `LegacyTerrainSurfaceView` est important. Les paths ont des `TerrainPathVariant`; les terrains ont des variants ponderes sans role d'autotile explicite dans le preset. Les unifier maintenant risquerait d'effacer cette difference.

## 12. Points de vigilance

### `weight` par defaut

L'audit confirme `@Default(1)` sur `TerrainPresetVariant.weight`. L'adaptateur utilise donc `1` comme reference pour `hasWeightedVariants`.

### `categoryId` reste nullable

Comme pour le Lot 4, le modele reel expose `categoryId` en `String?`. L'adaptateur terrain preserve cette nullabilite.

### Pas de selection ponderee

La vue expose les weights mais ne choisit pas de variante. Aucune logique de tirage ou de distribution n'est introduite.

### Pas d'union avec les paths

Le lot refuse volontairement une vue commune entre path et terrain. La future Surface Engine devra decider cette forme dans un lot dedie.

### Les constructeurs ne sont pas `const`

Comme pour le Lot 4, `List.unmodifiable(...)` est utilise pour garantir des listes read-only meme lors d'une construction directe.

### Les frames sont conservees par identite

Les frames ne sont pas clonees. C'est coherent avec leur nature immutable actuelle.

## 13. Commandes lancees

Audit / lecture :

```bash
rg --files -g 'AGENTS.md'
git status --short
```

TDD rouge initial :

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_terrain_surface_view_test.dart
```

Resultat attendu avant implementation :

```text
Failed to load "test/legacy_terrain_surface_view_test.dart"
Method not found: 'createLegacyTerrainSurfaceView'
Method not found: 'LegacyTerrainSurfaceVariantView'
```

Formatage :

```bash
cd packages/map_core
/opt/homebrew/bin/dart format lib/src/operations/legacy_terrain_surface_view.dart test/legacy_terrain_surface_view_test.dart lib/map_core.dart
```

Test Lot 5 :

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_terrain_surface_view_test.dart
```

Analyse ciblee :

```bash
cd packages/map_core
/opt/homebrew/bin/dart analyze lib/src/operations/legacy_terrain_surface_view.dart test/legacy_terrain_surface_view_test.dart lib/map_core.dart
```

Tests des lots precedents :

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_path_surface_view_test.dart
/opt/homebrew/bin/dart test test/project_manifest_surface_json_characterization_test.dart
/opt/homebrew/bin/dart test test/map_terrain_autotile_characterization_test.dart
/opt/homebrew/bin/dart test test/tile_visual_frame_timeline_test.dart
/opt/homebrew/bin/dart test test/legacy_editor_json_compat_collision_test.dart
/opt/homebrew/bin/dart test test/element_collision_profile_pixel_mask_json_test.dart
```

Test complet :

```bash
cd packages/map_core
/opt/homebrew/bin/dart test
```

## 14. Resultats des tests

TDD rouge initial :

```text
Expected failure: API not found before implementation.
```

Lot 5 :

```text
test/legacy_terrain_surface_view_test.dart
+12: All tests passed!
```

Analyse ciblee :

```text
Analyzing legacy_terrain_surface_view.dart, legacy_terrain_surface_view_test.dart, map_core.dart...
No issues found!
```

Lot 4 :

```text
test/legacy_path_surface_view_test.dart
+11: All tests passed!
```

Lot 3 :

```text
test/project_manifest_surface_json_characterization_test.dart
+15: All tests passed!
```

Lot 1 :

```text
test/map_terrain_autotile_characterization_test.dart
+21: All tests passed!
```

Lot 2 :

```text
test/tile_visual_frame_timeline_test.dart
+16: All tests passed!
```

Lot 2-bis legacy compat :

```text
test/legacy_editor_json_compat_collision_test.dart
+3: All tests passed!
```

Lot 2-bis collision masks :

```text
test/element_collision_profile_pixel_mask_json_test.dart
+6: All tests passed!
```

Suite complete `map_core` :

```text
+211: All tests passed!
```

## 15. Autocritique finale

Le lot reste petit et symetrique au Lot 4. Il ajoute une vue terrain legacy read-only, pas un modele Surface.

Points solides :

- l'API est pure Dart ;
- aucun schema persistant ne change ;
- aucune union Surface commune n'est creee ;
- les weights sont preserves et testes ;
- les listes exposees sont non mutables ;
- les tests couvrent les donnees terrain importantes ;
- `map_core` complet reste vert.

Limites :

- la vue n'est pas encore utilisee par runtime/editor, volontairement ;
- elle ne fournit pas de selection ponderee ;
- elle ne valide pas les poids ;
- elle ne modelise pas les comportements gameplay des terrains ;
- elle ne resout pas les frames animees ;
- elle ne relie pas les terrains aux variants d'autotile.

Le choix principal est de garder terrain et path separes. C'est plus verbeux a court terme, mais plus prudent tant que le vrai modele Surface n'est pas defini.

## 16. Ce que le prompt semble discutable ou incomplet

Le prompt demande explicitement de ne pas creer de vue unifiee Surface. Cela est coherent avec la prudence architecturale, mais implique une duplication volontaire entre les vues path et terrain.

Le prompt ne demande pas de lookup de variant pour les terrains. Contrairement aux paths, les terrains n'ont pas de `TerrainPathVariant` dans `ProjectTerrainPreset`; l'API expose donc simplement la liste ordonnee des variants.

Le prompt demande `hasWeightedVariants` mais ne donne pas la valeur par defaut. L'audit a confirme que le modele reel utilise `@Default(1)`.

Le prompt propose des constructeurs non-const dans l'exemple. L'implementation suit cette direction pour pouvoir garantir `List.unmodifiable(...)`.

## 17. Auto-review independante

### Est-ce que le lot est reste strictement limite a une vue terrain legacy read-only ?

Oui. Le lot ajoute uniquement une vue terrain read-only, son export, ses tests et son rapport.

### Est-ce qu'aucun modele Surface persistant n'a ete cree ?

Oui. Aucun `SurfaceDefinition`, `SurfaceEngine` ou champ persistant Surface n'a ete cree.

### Est-ce qu'aucune vue unifiee Surface n'a ete creee ?

Oui. `LegacyPathSurfaceView` et `LegacyTerrainSurfaceView` restent separes.

### Est-ce qu'aucun modele Freezed/JSON n'a ete modifie ?

Oui. Aucun modele Freezed/JSON n'a ete modifie.

### Est-ce qu'aucun fichier generated n'a ete modifie ?

Oui. Aucun fichier `.g.dart` ou `.freezed.dart` n'a ete modifie.

### Est-ce qu'aucun runtime/editor/gameplay n'a ete modifie ?

Oui. Aucun fichier `map_runtime`, `map_editor`, `map_gameplay` ou `map_battle` n'a ete modifie.

### Est-ce que `ProjectTerrainPreset` n'a pas ete modifie ?

Oui. `ProjectTerrainPreset` est intact.

### Est-ce que `ProjectPathPreset` n'a pas ete modifie ?

Oui. `ProjectPathPreset` est intact.

### Est-ce que les donnees du preset terrain sont preservees exactement ?

Oui. Les valeurs simples, l'ordre des variants, l'ordre des frames, les durees, les overrides `tilesetId`, les weights et les objets frames sont preserves.

### Est-ce que les listes exposees sont non mutables ?

Oui. Les tests verifient que `view.variants.add(...)` et `view.variants.first.frames.add(...)` lancent `UnsupportedError`.

### Est-ce que les tests documentent le comportement actuel plutot qu'un comportement futur ideal ?

Oui. Les tests documentent la liste ordonnee de variants, les weights tels quels, l'absence de selection ponderee et l'absence d'union Surface.

### Est-ce que les tests des lots precedents passent toujours ?

Oui. Les tests cibles des lots 1, 2, 2-bis, 3 et 4 passent.

### Est-ce que `map_core` complet passe ?

Oui. `dart test` dans `packages/map_core` termine avec `+211: All tests passed!`.

### Est-ce que les commandes Git interdites n'ont pas ete utilisees ?

Oui. Seules des commandes Git de lecture ont ete utilisees.

### Est-ce que le rapport est assez detaille ?

Oui. Il couvre les fichiers consultes, crees, modifies, l'API, la semantique, les tests, les resultats, les points de vigilance et l'auto-review.

### Est-ce que quelque chose du prompt etait ambigu ou discutable ?

Oui. Les points principaux sont la duplication volontaire avec le Lot 4, l'absence de lookup terrain par variante nommee, et la necessite d'auditer la valeur par defaut de `weight`.
