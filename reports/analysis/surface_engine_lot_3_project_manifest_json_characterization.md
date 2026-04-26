# Surface Engine Lot 3 - ProjectManifest / Presets JSON Characterization

## 1. Resume executif

Le Lot 3 a ete execute dans un perimetre volontairement limite : ajout d'un fichier de tests de caracterisation JSON pour `map_core`, sans modification des modeles de production, sans nouveau modele `Surface`, sans generation de code et sans changement runtime/editor/gameplay.

Le nouveau test `packages/map_core/test/project_manifest_surface_json_characterization_test.dart` verrouille le comportement actuel de `ProjectManifest`, `ProjectTilesetEntry`, `TilesetSourceRect`, `TilesetVisualFrame`, `ProjectTerrainPreset`, `ProjectPathPreset`, `PathPresetVariantMapping`, `PathAnimationTriggerRule`, `PathLayer` et `TerrainLayer`.

Le comportement le plus important pour la suite Surface Engine est maintenant documente par test :

- un manifest minimal actuel exige `name`, `maps` et `tilesets` ;
- les listes optionnelles du manifest sont initialisees a `[]` ;
- `ProjectSettings.tileWidth` et `tileHeight` valent `16` par defaut ;
- un champ inconnu racine `surfaceDefinitions` est ignore au parsing et perdu au round-trip ;
- un `tilesetId` absent dans `TilesetVisualFrame` devient une chaine vide `''`, pas `null` ;
- `PathSurfaceKind.water` et `PathSurfaceKind.tallGrass` sont deja serialisables ;
- les animations de path layer sont portees par `PathLayer.animationMode` et `PathLayer.animationTriggers`, pas par `ProjectPathPreset` ;
- `PathAnimationTriggerRule` ne contient aujourd'hui ni duree, ni cooldown ;
- le round-trip stable doit etre compris comme un round-trip de JSON persiste via `jsonEncode` / `jsonDecode`.

Toutes les validations demandees sont vertes, y compris le test complet `map_core` :

```text
/opt/homebrew/bin/dart test
+188: All tests passed!
```

## 2. Pourquoi ce lot est necessaire avant d'ajouter `Surface`

Le futur modele `Surface` sera probablement persiste dans `ProjectManifest`, par exemple sous une collection du type `surfaceDefinitions`. Avant d'ajouter cette collection, il fallait caracteriser le comportement JSON actuel pour eviter trois risques :

1. Casser la lecture des manifests existants.
2. Introduire un champ futur que les binaires actuels lisent mal ou reecrivent dangereusement.
3. Confondre les contrats existants de terrain/path avec le futur contrat Surface.

Ce lot confirme que le parser actuel ignore les champs inconnus. C'est rassurant pour la lecture forward-compatible, mais fragile pour l'ecriture : si une ancienne version de PokeMap ouvre puis sauvegarde un manifest contenant `surfaceDefinitions`, ce champ inconnu est perdu.

Ce lot confirme aussi que les concepts actuels sont encore eparpilles :

- les atlas et frames vivent dans les tilesets, elements, terrain presets et path presets ;
- l'eau est un `ProjectPathPreset` avec `surfaceKind: water` ;
- les hautes herbes peuvent etre representees par `surfaceKind: tall_grass`, mais seulement comme serialisation de preset path ;
- l'animation de layer est sur `PathLayer`, pas sur le preset.

Ces tests fournissent donc un filet de securite avant d'introduire une representation Surface plus explicite.

## 3. Fichiers consultes

Fichiers source inspectes :

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_manifest.g.dart` en lecture seule
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/map_layer.g.dart` en lecture seule
- `packages/map_core/lib/src/models/tileset.dart`
- `packages/map_core/lib/src/models/visual_frame_json.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_core/lib/map_core.dart`

Tests existants inspectes :

- `packages/map_core/test/path_preset_frames_test.dart`
- `packages/map_core/test/path_animation_triggers_test.dart`
- `packages/map_core/test/project_element_frames_test.dart`
- `packages/map_core/test/legacy_editor_json_compat_collision_test.dart`
- `packages/map_core/test/element_collision_profile_pixel_mask_json_test.dart`
- `packages/map_core/test/map_terrain_autotile_characterization_test.dart`
- `packages/map_core/test/tile_visual_frame_timeline_test.dart`

Fichiers demandes mais absents sous les chemins indiques :

- `packages/map_core/test/project_element_collision_file_repository_roundtrip_test.dart`
- `packages/map_core/test/project_element_collision_persistence_test.dart`

Equivalent partiel trouve pour la dette collision JSON :

- `packages/map_core/test/element_collision_profile_pixel_mask_json_test.dart`
- `packages/map_core/test/legacy_editor_json_compat_collision_test.dart`

## 4. Fichiers crees

- `packages/map_core/test/project_manifest_surface_json_characterization_test.dart`
- `reports/analysis/surface_engine_lot_3_project_manifest_json_characterization.md`

## 5. Fichiers modifies

Aucun fichier de production existant n'a ete modifie.

Le nouveau fichier de test a ete ajuste pendant son ecriture : une premiere fixture utilisait `PaletteCategory` avec la valeur inexistante `terrain`; le modele actuel accepte notamment `water`, `paths`, `floors`, etc. La fixture a ete corrigee pour utiliser `water`.

## 6. API ou comportement JSON caracterise

### ProjectManifest

Le manifest minimal actuel doit contenir :

- `name`
- `maps`
- `tilesets`

Les champs suivants ont des valeurs par defaut cote parsing :

- `version: ProjectVersion.v1`
- `groups: []`
- `tilesetFolders: []`
- `elementCategories: []`
- `elements: []`
- `terrainCategories: []`
- `pathCategories: []`
- `terrainPresets: []`
- `pathPresets: []`
- `encounterTables: []`
- `dialogueFolders: []`
- `dialogues: []`
- `scripts: []`
- `scenarios: []`
- `trainers: []`
- `characters: []`
- `settings: ProjectSettings()`
- `pokemon: ProjectPokemonConfig()`
- `globalProperties: {}`

### ProjectSettings

Les tailles de tiles projet sont persistees par :

- `settings.tileWidth`
- `settings.tileHeight`

Le defaut actuel est :

- `tileWidth: 16`
- `tileHeight: 16`

### ProjectTilesetEntry

Les champs caracterises sont :

- `id`
- `name`
- `relativePath`
- `scope`
- `groupId`
- `folderId`
- `sortOrder`
- `isWorldTileset`
- `paletteEntries`

`scope` serialise `TilesetScope.group` sous la chaine JSON `group`.

### TilesetSourceRect

Les champs caracterises sont :

- `x`
- `y`
- `width`
- `height`

`width` et `height` ont un defaut de `1` si absents.

### TilesetVisualFrame

Les champs caracterises sont :

- `tilesetId`
- `source`
- `durationMs`

Point important : `tilesetId` n'est pas nullable dans le modele actuel. Si la cle est absente du JSON, elle devient `''`.

### ProjectTerrainPreset

Les champs caracterises sont :

- `id`
- `name`
- `terrainType`
- `categoryId`
- `tilesetId`
- `variants`
- `sortOrder`

Les `TerrainPresetVariant` conservent :

- `frames`
- `weight`
- l'ordre des frames
- les durees par frame

### ProjectPathPreset

Les champs caracterises sont :

- `id`
- `name`
- `surfaceKind`
- `categoryId`
- `tilesetId`
- `variants`
- `sortOrder`

Les `PathPresetVariantMapping` conservent :

- `variant`
- `frames`
- l'ordre des mappings
- l'ordre des frames
- les durees par frame
- les overrides `tilesetId` par frame

### PathLayer

Les champs caracterises sont :

- `presetId`
- `cells`
- `properties`
- `animationMode`
- `animationTriggers`
- `isVisible`
- `opacity`

### PathAnimationTriggerRule

Les champs caracterises sont :

- `id`
- `enabled`
- `trigger`
- `mode`
- `scope`

Le modele actuel ne porte pas de champs `duration`, `cooldown` ou equivalent.

### Unknown fields

Les champs inconnus sont ignores par les parsers generated actuels et ne sont pas presents dans `toJson()`.

Ce comportement est caracterise pour :

- `surfaceDefinitions` a la racine de `ProjectManifest` ;
- `surfaceDraft` dans `ProjectPathPreset` ;
- `surfaceDraft` dans `ProjectTerrainPreset`.

## 7. Liste complete des cas testes

Le nouveau fichier de test couvre les cas suivants :

1. Manifest minimal actuel avec defaults materialises.
2. Manifest avec champ inconnu racine `surfaceDefinitions`.
3. Manifest avec `ProjectTilesetEntry` simple, scope de groupe et palette minimale.
4. `TilesetSourceRect` round-trip.
5. `TilesetVisualFrame` sans override tileset.
6. `TilesetVisualFrame` avec override tileset.
7. `ProjectTerrainPreset` avec variante animee et poids.
8. `ProjectPathPreset` `water` avec mappings `isolated`, `horizontal`, `vertical`, `cornerNE`, `cross`.
9. `ProjectPathPreset` `tallGrass` avec `surfaceKind: tall_grass`.
10. `PathLayer.animationMode` avec `always_active` et `triggered`.
11. `PathAnimationTriggerRule` avec `id`, `enabled`, `trigger`, `mode`, `scope`.
12. `PathLayer` avec `presetId`, grille de cellules, proprietes, mode et triggers.
13. `TerrainLayer` avec plusieurs `TerrainType`.
14. Champs inconnus dans `ProjectPathPreset` et `ProjectTerrainPreset`.
15. Stabilite d'un manifest metier apres round-trip JSON wire.

## 8. Ce que les tests prouvent

Les tests prouvent que le modele actuel est lisible et stable pour les contrats JSON existants, a condition de parler de JSON persiste et non seulement de la map Dart retournee par certains `toJson()`.

Ils prouvent notamment que :

- les manifests minimaux restent compatibles ;
- les defaults generated sont stables ;
- les champs inconnus sont perdus au round-trip ;
- les tilesets conservent les informations de scope et de palette ;
- les rectangles source conservent leurs coordonnees ;
- les frames visuelles conservent `source`, `durationMs` et `tilesetId` ;
- le sentinel d'absence d'override tileset est `''` ;
- les presets terrain conservent les variantes animees ;
- les presets path conservent les variants legacy d'autotile ;
- l'eau est aujourd'hui un path preset `surfaceKind: water` ;
- les hautes herbes sont serialisables comme `surfaceKind: tall_grass` ;
- l'animation globale ou declenchee de path est portee par `PathLayer`;
- les trigger rules de path ont un modele encore tres simple ;
- `TerrainLayer` garde une grille enumeree separee de `PathLayer`.

## 9. Points etranges ou fragiles observes

### `TilesetVisualFrame.tilesetId` utilise `''`

Le prompt mentionne un override nullable, mais le modele actuel utilise une chaine vide par defaut. C'est compatible avec l'existant, mais c'est un point a traiter explicitement si les futures surfaces veulent un modele plus clair.

### Les champs inconnus sont perdus

Le parser ignore `surfaceDefinitions`, mais `toJson()` ne le conserve pas. Cela veut dire qu'une ancienne version de PokeMap peut probablement ouvrir un manifest futur, puis supprimer les surfaces en sauvegardant.

### `PathAnimationTriggerRule` ne porte pas de timing

Le prompt demande de tester duree/cooldown si reels. L'audit montre qu'ils n'existent pas aujourd'hui. Le test documente donc uniquement les champs existants.

### `ProjectPathPreset` ne porte pas `animationMode`

Le mode d'animation vit sur `PathLayer`. C'est important pour eviter de migrer trop vite des concepts de layer vers des definitions globales de surface.

### Round-trip direct `fromJson(toJson())` peut etre trompeur

Certains `toJson()` generated n'appellent pas explicitement `toJson()` sur toutes les listes imbriquees. Dans une persistance reelle, `jsonEncode` transforme ces objets via leur propre `toJson()`. Les tests utilisent donc un helper `wireJson()` base sur `jsonEncode` / `jsonDecode`.

### `PaletteCategory` n'a pas de valeur `terrain`

La premiere fixture de test utilisait `category: terrain`, qui n'existe pas. Le modele actuel expose des categories comme `water`, `paths`, `floors`, `plants`, etc. La fixture a ete corrigee vers `water`.

## 10. Impact pour les futurs modeles Surface

Les futurs lots doivent tenir compte de ces faits :

- ajouter `surfaceDefinitions` sera lu comme champ inconnu par les anciennes versions, mais perdu si elles sauvegardent ;
- il faudra probablement une strategie de version ou de sauvegarde prudente pour eviter la perte silencieuse de surfaces ;
- `SurfaceDefinition` ne doit pas remplacer brutalement `ProjectPathPreset` ou `ProjectTerrainPreset` ;
- l'eau legacy est deja identifiee par `PathSurfaceKind.water`, ce qui donne un chemin de migration progressif ;
- `tall_grass` existe dans l'enum, mais il ne faut pas lui donner la meme semantique que l'eau ;
- les frames visuelles actuelles peuvent servir de base, mais leur `tilesetId` sentinel `''` devra etre documente ;
- les trigger rules actuelles sont insuffisantes pour des animations locales riches, mais elles doivent rester compatibles ;
- les tests de ce lot doivent rester verts lorsque le futur champ Surface sera ajoute, avec des attentes mises a jour uniquement dans un lot dedie.

## 11. Commandes lancees

Commande de formatage :

```bash
/opt/homebrew/bin/dart format packages/map_core/test/project_manifest_surface_json_characterization_test.dart
```

Commande ciblee Lot 3, premier passage :

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/project_manifest_surface_json_characterization_test.dart
```

Resultat initial :

```text
Echec dans la fixture de test : category `terrain` n'existe pas dans PaletteCategory.
```

Commande ciblee Lot 3 apres correction :

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/project_manifest_surface_json_characterization_test.dart
```

Analyse statique ciblee :

```bash
cd packages/map_core
/opt/homebrew/bin/dart analyze test/project_manifest_surface_json_characterization_test.dart
```

Tests des lots precedents :

```bash
cd packages/map_core
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

Commandes Git en lecture :

```bash
git status --short
```

Aucune commande Git d'ecriture n'a ete utilisee.

## 12. Resultats des tests

Resultat apres correction du test Lot 3 :

```text
test/project_manifest_surface_json_characterization_test.dart
+15: All tests passed!
```

Analyse statique :

```text
Analyzing project_manifest_surface_json_characterization_test.dart...
No issues found!
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
+188: All tests passed!
```

## 13. Ce qui n'a volontairement pas ete fait

Ce lot n'a pas :

- cree de modele `Surface` ;
- cree de `SurfaceEngine` ;
- ajoute `surfaceDefinitions` dans `ProjectManifest` ;
- modifie les modeles Freezed/JSON ;
- lance `build_runner` ;
- modifie des fichiers `.g.dart` ou `.freezed.dart` ;
- modifie `map_runtime` ;
- modifie `map_editor` ;
- modifie `map_gameplay` ;
- modifie `map_battle` ;
- modifie `tile_visual_frame_timeline.dart` ;
- modifie `map_terrain_autotile.dart` ;
- modifie `ElementCollisionProfile` ;
- change un comportement runtime ;
- corrige ou refactorise des details hors perimetre.

## 14. Autocritique finale

Le lot reste bien centre sur la caracterisation JSON. Les tests sont volontairement plus descriptifs que minimalistes, car ils servent de documentation de migration.

Limites de cette analyse :

- elle ne teste pas la persistence fichier complete via repository IO, seulement le JSON wire encode/decode ;
- elle ne teste pas tous les enums du projet, seulement ceux lies aux surfaces legacy et aux layers demandes ;
- elle ne teste pas les migrations legacy hors collision, car ce n'etait pas l'objet du lot ;
- elle ne teste pas l'effet d'une ancienne version de l'application qui sauvegarderait un manifest futur en conditions reelles, elle caracterise seulement le comportement generated actuel ;
- elle ne tranche pas le design futur de `SurfaceDefinition`.

Le point le plus fragile est la perte de champs inconnus. Pour une migration Surface, il faudra probablement traiter ce risque avant de laisser des versions mixtes ouvrir et sauvegarder les memes projets.

## 15. Ce que le prompt semble discutable ou incomplet

Le prompt mentionne `tilesetId == null` si absent dans `TilesetVisualFrame`. Le modele actuel utilise `@Default('') String tilesetId`, donc le comportement reel est `tilesetId == ''`. Le test documente le comportement actuel plutot que l'intention supposee.

Le prompt mentionne des champs de duree/cooldown sur `PathAnimationTriggerRule`. Ces champs n'existent pas dans le modele actuel. Le test caracterise uniquement `id`, `enabled`, `trigger`, `mode` et `scope`.

Le prompt demande des tests de `project_element_collision_file_repository_roundtrip_test.dart` et `project_element_collision_persistence_test.dart`, mais ces fichiers n'existent pas dans le repo actuel sous ces chemins. Les equivalents pertinents inspectes sont les tests collision JSON presents.

Le prompt demande parfois un round-trip `fromJson(toJson)`. Pour plusieurs modeles generated, le `toJson()` Dart brut peut contenir des objets imbriques tant que l'on ne passe pas par `jsonEncode`. Comme la persistance projet passe par du JSON encode, les tests utilisent un round-trip wire via `jsonEncode` / `jsonDecode`.

## 16. Auto-review independante

### Est-ce que le lot est reste strictement limite a la caracterisation JSON ?

Oui. Le lot ajoute un test de caracterisation JSON et un rapport. Aucun comportement de production n'a ete modifie.

### Est-ce qu'aucun modele Surface n'a ete cree ?

Oui. Aucun modele `Surface`, `SurfaceDefinition` ou `SurfaceEngine` n'a ete ajoute.

### Est-ce qu'aucun modele Freezed/JSON n'a ete modifie ?

Oui. Les fichiers sources de modeles n'ont pas ete modifies.

### Est-ce qu'aucun fichier generated n'a ete modifie ?

Oui. Les fichiers `.g.dart` et `.freezed.dart` ont ete lus uniquement.

### Est-ce qu'aucun runtime/editor/gameplay n'a ete modifie ?

Oui. Aucun fichier `map_runtime`, `map_editor`, `map_gameplay` ou `map_battle` n'a ete modifie par ce lot.

### Est-ce que les tests documentent le comportement actuel plutot qu'un comportement ideal futur ?

Oui. Les tests verrouillent notamment la perte des champs inconnus, le sentinel `tilesetId: ''` et l'absence de timing sur les trigger rules.

### Est-ce que le champ inconnu `surfaceDefinitions` est caracterise ?

Oui. Il est ignore au parsing et perdu au round-trip.

### Est-ce que les presets terrain/path sont caracterises ?

Oui. Les deux types de presets sont testes, y compris variantes, frames, poids, surface kind, mappings et champs inconnus.

### Est-ce que les frames avec `tilesetId` override sont caracterisees ?

Oui. Un test direct de `TilesetVisualFrame` et un mapping water animent un override `tilesetId`.

### Est-ce que les tests des Lots 1, 2 et 2-bis passent toujours ?

Oui. Les tests cibles des trois lots passent.

### Est-ce que `map_core` complet passe ?

Oui. `dart test` dans `packages/map_core` termine avec `+188: All tests passed!`.

### Est-ce que les commandes Git interdites n'ont pas ete utilisees ?

Oui. Seule la commande Git de lecture `git status --short` a ete utilisee.

### Est-ce que le rapport est assez detaille ?

Oui. Il liste les fichiers consultes, crees, modifies, les comportements caracterises, les commandes, les resultats, les limites et les points discutables du prompt.

### Est-ce que quelque chose du prompt etait ambigu ou discutable ?

Oui. Les points ambigus principaux sont le `tilesetId` absent attendu comme `null`, les champs de timing inexistants sur `PathAnimationTriggerRule`, les fichiers collision demandes mais absents, et la nuance entre `toJson()` Dart brut et JSON wire persiste.
