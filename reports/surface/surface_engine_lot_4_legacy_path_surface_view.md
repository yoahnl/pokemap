# Surface Engine Lot 4 - Legacy Path Surface View Adapter V0

## 1. Resume executif

Le Lot 4 ajoute une petite API pure dans `map_core` pour exposer un `ProjectPathPreset` existant comme une vue de surface legacy en lecture seule.

L'API ajoutee est volontairement non persistante :

- pas de `SurfaceDefinition` ;
- pas de `SurfaceEngine` ;
- pas de JSON ;
- pas de Freezed ;
- pas de `build_runner` ;
- pas de runtime Flame ;
- pas d'editeur Flutter ;
- pas de migration ;
- pas de modification de `ProjectPathPreset`.

La nouvelle API vit dans :

- `packages/map_core/lib/src/operations/legacy_path_surface_view.dart`

Elle est exportee par :

- `packages/map_core/lib/map_core.dart`

Elle est couverte par :

- `packages/map_core/test/legacy_path_surface_view_test.dart`

Le test a ete ecrit avant l'implementation. Le premier passage a echoue comme attendu parce que `createLegacyPathSurfaceView` et `LegacyPathSurfaceVariantView` n'existaient pas encore. Apres implementation minimale, les tests Lot 4, les tests des lots precedents, l'analyse ciblee et le test complet `map_core` passent.

## 2. Pourquoi ce lot est necessaire apres le Lot 3

Le Lot 3 a confirme que `ProjectPathPreset` porte deja plusieurs pieces de donnees proches d'une surface :

- `surfaceKind`, dont `water` et `tallGrass` ;
- `tilesetId` au niveau preset ;
- `categoryId` nullable ;
- `sortOrder` ;
- une liste de `PathPresetVariantMapping` ;
- des frames `TilesetVisualFrame`, avec ordre, durees et overrides `tilesetId`.

Le Lot 3 a aussi confirme qu'il serait dangereux d'ajouter trop vite un champ persistant futur comme `surfaceDefinitions`, car un ancien parser l'ignorerait puis le perdrait au round-trip.

Le Lot 4 introduit donc une etape intermediaire plus sure : une vue read-only non persistante. Elle permet de commencer a raisonner en termes de surface legacy sans changer le schema projet et sans brancher le runtime.

## 3. Fichiers consultes

Fichiers source consultes :

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/operations/map_terrain_autotile.dart`
- `packages/map_core/lib/src/operations/tile_visual_frame_timeline.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/pubspec.yaml`
- `packages/map_core/README.md`

Tests consultes :

- `packages/map_core/test/project_manifest_surface_json_characterization_test.dart`
- `packages/map_core/test/path_preset_frames_test.dart`
- `packages/map_core/test/map_terrain_autotile_characterization_test.dart`
- `packages/map_core/test/tile_visual_frame_timeline_test.dart`

Fichier d'instructions consulte :

- `AGENTS.md`

Commandes Git de lecture utilisees :

- `git status --short`

Aucune commande Git d'ecriture n'a ete utilisee.

## 4. Fichiers crees

- `packages/map_core/lib/src/operations/legacy_path_surface_view.dart`
- `packages/map_core/test/legacy_path_surface_view_test.dart`
- `reports/analysis/surface_engine_lot_4_legacy_path_surface_view.md`

## 5. Fichiers modifies

- `packages/map_core/lib/map_core.dart`

Modification unique dans le barrel public :

```dart
export 'src/operations/legacy_path_surface_view.dart';
```

Aucun autre fichier de production existant n'a ete modifie.

## 6. API ajoutee

### `LegacyPathSurfaceView`

Vue read-only d'un `ProjectPathPreset` legacy.

Champs exposes :

- `id`
- `name`
- `surfaceKind`
- `tilesetId`
- `categoryId`
- `sortOrder`
- `variants`

Getters :

- `hasVariants`
- `hasAnimatedVariants`

Methode :

- `framesForVariant(TerrainPathVariant variant)`

### `LegacyPathSurfaceVariantView`

Vue read-only d'un mapping legacy `TerrainPathVariant -> List<TilesetVisualFrame>`.

Champs exposes :

- `variant`
- `frames`

Getters :

- `hasFrames`
- `isAnimated`

### `createLegacyPathSurfaceView(ProjectPathPreset preset)`

Fonction pure qui cree une vue read-only depuis un `ProjectPathPreset`.

## 7. Semantique de l'adaptateur

`createLegacyPathSurfaceView` copie les valeurs suivantes depuis le preset :

- `id`
- `name`
- `surfaceKind`
- `tilesetId`
- `categoryId`
- `sortOrder`
- ordre exact de `variants`
- ordre exact des `frames`

Les listes exposees sont non mutables :

- `LegacyPathSurfaceView.variants` est cree avec `List.unmodifiable(...)` ;
- `LegacyPathSurfaceVariantView.frames` est cree avec `List.unmodifiable(...)` ;
- `framesForVariant(...)` retourne soit la liste read-only de la variante trouvee, soit `const <TilesetVisualFrame>[]`.

Les objets `TilesetVisualFrame` ne sont pas clones. Ils sont des valeurs Freezed immutables, et l'adaptateur preserve leur identite. Cela permet de prouver que la vue ne reinterprete pas les donnees visuelles.

`framesForVariant` :

- retourne les frames du premier mapping qui correspond a la variante demandee ;
- retourne une liste vide non mutable si la variante est absente ;
- ne fusionne pas les mappings dupliques ;
- ne deduplique pas ;
- ne cree pas de fallback ;
- ne consulte pas `RuntimePathAutotileSet` ;
- ne consulte pas `PathAutotileSet.defaultForTileset` ;
- ne resout aucune animation.

`hasAnimatedVariants` vaut `true` si au moins une variante contient plus d'une frame. Les durees ne sont pas inspectees dans ce lot.

`LegacyPathSurfaceVariantView.isAnimated` vaut `true` si `frames.length > 1`.

## 8. Liste complete des cas testes

Le fichier `legacy_path_surface_view_test.dart` couvre :

1. Adaptation d'un preset `water` simple avec `id`, `name`, `surfaceKind`, `tilesetId`, `categoryId`, `sortOrder`, mapping `isolated` et une frame.
2. Adaptation d'un preset `tallGrass`.
3. Preservation de l'ordre des variants dans un ordre non alphabetique : `cross`, `isolated`, `cornerNE`, `horizontal`.
4. Preservation de l'ordre des frames et des `durationMs`.
5. Preservation d'un override de frame `tilesetId: 'animated-water-atlas'`.
6. `framesForVariant` avec variante existante.
7. `framesForVariant` avec variante absente.
8. `framesForVariant` avec variante dupliquee : retour du premier mapping.
9. Immutabilite de `view.variants`.
10. Immutabilite de `view.variants.first.frames`.
11. Immutabilite de la liste vide retournee par `framesForVariant`.
12. Absence de mutation du `ProjectPathPreset` source.
13. Preset sans variants.
14. `hasAnimatedVariants` pour presets statiques et animes.
15. `LegacyPathSurfaceVariantView.hasFrames`.
16. `LegacyPathSurfaceVariantView.isAnimated`.

## 9. Ce que les tests prouvent

Les tests prouvent que la nouvelle vue :

- expose correctement `PathSurfaceKind.water` ;
- expose correctement `PathSurfaceKind.tallGrass` ;
- preserve les valeurs simples du preset ;
- preserve `categoryId` sans l'aplatir en chaine vide ;
- preserve le `tilesetId` du preset ;
- preserve l'ordre des mappings ;
- preserve l'ordre des frames ;
- preserve les durees des frames ;
- preserve les overrides `tilesetId` des frames ;
- preserve les objets `TilesetVisualFrame` ;
- gere les presets sans variants ;
- expose une detection structurelle d'animation ;
- retourne le premier mapping lors d'une variante dupliquee ;
- retourne une liste vide quand la variante n'existe pas ;
- empeche les mutations externes des listes exposees ;
- ne modifie pas le preset source.

## 10. Ce qui n'a volontairement pas ete fait

Ce lot n'a pas :

- cree `SurfaceDefinition` ;
- cree `SurfaceEngine` ;
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
- modifie `ProjectPathPreset` ;
- modifie `ProjectTerrainPreset` ;
- modifie `tile_visual_frame_timeline.dart` ;
- modifie `map_terrain_autotile.dart` ;
- cree une migration ;
- cree du JSON ;
- branche cette vue dans le runtime ou l'editeur.

## 11. Impact pour les futurs modeles Surface

Cette vue donne une premiere surface de compatibilite qui peut etre utilisee plus tard pour :

- comparer un `ProjectPathPreset` legacy a une future `SurfaceDefinition` ;
- construire un adapter runtime de surface legacy sans changer les presets ;
- migrer progressivement l'eau ;
- migrer progressivement les hautes herbes ;
- ecrire des outils de migration explicites ;
- garder une separation entre donnees persistantes legacy et representation conceptuelle Surface.

Le choix de ne pas fusionner les variantes dupliquees est important. Si une future migration veut interdire ou nettoyer les doublons, elle devra le faire explicitement dans un lot dedie.

## 12. Points de vigilance

### `categoryId` reste nullable

Le prompt proposait une API avec `String categoryId`, mais `ProjectPathPreset.categoryId` est `String?`. Pour preserver exactement la donnee source, l'adaptateur expose `String? categoryId`.

### Les constructeurs ne sont pas `const`

Le prompt proposait des constructeurs `const`, mais l'exigence read-only demandait de proteger les listes avec `List.unmodifiable(...)`. Un constructeur non-const est donc plus adapte pour garantir l'immutabilite des listes, meme quand un appelant construit directement une vue.

### La vue n'est pas un moteur

Elle ne resout pas l'autotile, ne choisit pas de frame temporelle et ne porte aucune logique gameplay. C'est volontaire : ces responsabilites restent separees.

### Les frames sont conservees par identite

Les frames ne sont pas clonees. C'est coherent avec leur nature immutable, mais si un futur modele mutable apparait, cette hypothese devra etre reconsideree.

### Les variants dupliques sont possibles

La vue retourne le premier mapping. Elle ne masque pas le fait que le modele legacy est une liste.

## 13. Commandes lancees

Audit / lecture :

```bash
rg --files -g 'AGENTS.md'
git status --short
```

TDD rouge initial :

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_path_surface_view_test.dart
```

Resultat attendu avant implementation :

```text
Failed to load "test/legacy_path_surface_view_test.dart"
Method not found: 'createLegacyPathSurfaceView'
Method not found: 'LegacyPathSurfaceVariantView'
```

Formatage :

```bash
cd packages/map_core
/opt/homebrew/bin/dart format lib/src/operations/legacy_path_surface_view.dart test/legacy_path_surface_view_test.dart lib/map_core.dart
```

Test Lot 4 :

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_path_surface_view_test.dart
```

Analyse ciblee :

```bash
cd packages/map_core
/opt/homebrew/bin/dart analyze lib/src/operations/legacy_path_surface_view.dart test/legacy_path_surface_view_test.dart lib/map_core.dart
```

Tests des lots precedents :

```bash
cd packages/map_core
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

Lot 4 :

```text
test/legacy_path_surface_view_test.dart
+11: All tests passed!
```

Analyse ciblee :

```text
Analyzing legacy_path_surface_view.dart, legacy_path_surface_view_test.dart, map_core.dart...
No issues found!
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
+199: All tests passed!
```

## 15. Autocritique finale

Le lot reste petit et respecte la direction demandee : il ajoute une vue legacy read-only, pas un modele Surface.

Points solides :

- l'API est pure Dart ;
- aucun schema persistant ne change ;
- les tests couvrent les donnees importantes du preset ;
- le comportement des doublons est documente ;
- l'immutabilite des listes exposees est verifiee ;
- le barrel public est mis a jour ;
- `map_core` complet reste vert.

Limites :

- la vue n'est pas encore utilisee par runtime/editor, volontairement ;
- elle ne fournit pas de lookup optimise par map, volontairement ;
- elle ne valide pas les presets incomplets ou incoherents ;
- elle ne modelise pas les dimensions gameplay des surfaces ;
- elle ne resout pas les frames animees, qui restent le role de `TileVisualFrameTimeline`.

Le choix le plus important est d'avoir conserve `categoryId` nullable. Cela s'ecarte legerement de l'exemple du prompt, mais preserve mieux le contrat reel de `ProjectPathPreset`.

## 16. Ce que le prompt semble discutable ou incomplet

Le prompt proposait `final String categoryId`, mais le modele reel a `String? categoryId`. Forcer une chaine aurait introduit une conversion implicite non demandee. L'adaptateur expose donc `String? categoryId`.

Le prompt proposait des constructeurs `const`. Pour garantir des listes non mutables avec `List.unmodifiable(...)`, les constructeurs publics ne sont pas `const`. C'est un compromis volontaire en faveur de l'exigence read-only.

Le prompt demande de preserver les objets `TilesetVisualFrame` ou au minimum leurs valeurs. L'implementation preserve les objets eux-memes, ce qui est plus strict.

Le prompt ne precise pas si la liste vide retournee par `framesForVariant` doit etre partagee ou nouvelle a chaque appel. L'implementation retourne `const <TilesetVisualFrame>[]`, ce qui est non mutable et suffisant pour V0.

## 17. Auto-review independante

### Est-ce que le lot est reste strictement limite a une vue legacy read-only ?

Oui. Le lot ajoute uniquement une vue read-only, son export, ses tests et son rapport.

### Est-ce qu'aucun modele Surface persistant n'a ete cree ?

Oui. Aucun `SurfaceDefinition`, `SurfaceEngine` ou champ persistant Surface n'a ete cree.

### Est-ce qu'aucun modele Freezed/JSON n'a ete modifie ?

Oui. Aucun modele Freezed/JSON n'a ete modifie.

### Est-ce qu'aucun fichier generated n'a ete modifie ?

Oui. Aucun fichier `.g.dart` ou `.freezed.dart` n'a ete modifie.

### Est-ce qu'aucun runtime/editor/gameplay n'a ete modifie ?

Oui. Aucun fichier `map_runtime`, `map_editor`, `map_gameplay` ou `map_battle` n'a ete modifie.

### Est-ce que `ProjectPathPreset` n'a pas ete modifie ?

Oui. `ProjectPathPreset` est intact.

### Est-ce que `RuntimePathAutotileSet` est reste intact ?

Oui. Aucun fichier runtime n'a ete touche.

### Est-ce que les donnees du preset sont preservees exactement ?

Oui. Les valeurs simples, l'ordre des variants, l'ordre des frames, les durees, les overrides `tilesetId` et les objets frames sont preserves.

### Est-ce que les listes exposees sont non mutables ?

Oui. Les tests verifient que `view.variants.add(...)`, `view.variants.first.frames.add(...)` et l'ajout dans la liste vide de `framesForVariant(...)` lancent `UnsupportedError`.

### Est-ce que les tests documentent le comportement actuel plutot qu'un comportement futur ideal ?

Oui. Les tests documentent notamment les doublons de variants par retour du premier mapping, l'absence de fallback, et la simple detection structurelle des animations.

### Est-ce que les tests des lots precedents passent toujours ?

Oui. Les tests cibles des lots 1, 2, 2-bis et 3 passent.

### Est-ce que `map_core` complet passe ?

Oui. `dart test` dans `packages/map_core` termine avec `+199: All tests passed!`.

### Est-ce que les commandes Git interdites n'ont pas ete utilisees ?

Oui. Seules des commandes Git de lecture ont ete utilisees.

### Est-ce que le rapport est assez detaille ?

Oui. Il couvre les fichiers consultes, crees, modifies, l'API, la semantique, les tests, les resultats, les points de vigilance et l'auto-review.

### Est-ce que quelque chose du prompt etait ambigu ou discutable ?

Oui. Les points principaux sont `categoryId` nullable dans le modele reel et les constructeurs `const` incompatibles avec une garantie simple de listes read-only.
