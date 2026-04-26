# PokeMap — Roadmap micro-lots Surface Engine / Tile Animation Engine

Version : 0.1  
Date : 2026-04-26  
Statut : découpage opératoire ultra précis  
But : transformer la grosse spec Surface Engine en lots minuscules, exécutables un par un, sans dépendance obligatoire à Tiled.

---

## 0. Lecture obligatoire avant toute exécution

Ce document n'est pas une demande de tout faire d'un coup. C'est une roadmap en micro-lots. Chaque lot doit être traité comme un ticket autonome, petit, vérifiable, et réversible mentalement.

Le but final est de remplacer progressivement l'actuelle logique `Path Library` par un vrai système :

```text
Surface Studio
+ Surface Engine
+ Animated Tile Atlas
+ Runtime Tile Animation Engine
```

Le projet ne doit pas dépendre de Tiled. Les idées utiles observées dans Tiled / Pokémon SDK sont reprises sous forme de concepts PokeMap internes, mais Tiled ne devient pas une vérité produit.

### Règles absolues pour les agents de code

Pour chaque lot :

1. Ne jamais faire de commit Git.
2. Ne jamais faire de `git add`, `git commit`, `git push`, `git merge`, `git rebase`, `git reset`, `git checkout`, `git restore`, `git stash`, `git tag`.
3. Les seules commandes Git autorisées sont en lecture : `git status --short`, `git diff --stat`, `git diff`, `git branch --show-current`, `git log --oneline -n 5`.
4. Commencer par un audit du périmètre exact du lot.
5. Ne modifier que les fichiers listés dans le lot, sauf si l'audit démontre qu'un fichier supplémentaire est strictement nécessaire.
6. Si un fichier supplémentaire est nécessaire, l'expliquer explicitement dans le rapport final.
7. Ne pas ouvrir de refactor opportuniste.
8. Ne pas renommer les concepts existants tant que le lot ne le demande pas explicitement.
9. Garder `ProjectPathPreset`, `PathLayer` et `RuntimePathAutotileSet` fonctionnels jusqu'aux lots de migration explicites.
10. Ne pas supprimer de code legacy tant qu'un lot ne dit pas explicitement de le faire.
11. Ne pas rendre Tiled obligatoire.
12. Si un import `.tsx` arrive plus tard, il devra être facultatif.
13. Toujours ajouter ou ajuster les tests du lot.
14. Toujours lancer les tests ciblés du lot.
15. Si un test global ou `analyze` échoue à cause d'une dette préexistante hors périmètre, le signaler précisément sans la corriger sauvagement.
16. Le rapport final doit lister tous les fichiers modifiés, créés ou supprimés.
17. Le rapport final doit expliquer ce qui a été testé, ce qui n'a pas pu l'être, et pourquoi.
18. Si le lot produit du code, le rapport final doit inclure le contenu complet des fichiers modifiés ou créés si demandé par Yoahn.
19. L'agent a le droit de dire qu'une instruction du lot est techniquement mauvaise, mais doit l'expliquer avant de proposer un ajustement minimal.
20. Le code généré par les agents externes peut contenir des commentaires utiles si cela aide la compréhension. Les commits restent interdits.

### Convention de validation minimale

Pour les lots `map_core` :

```bash
cd packages/map_core
dart test
```

Si le lot touche Freezed / JSON :

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart test
```

Pour les lots `map_editor` :

```bash
cd packages/map_editor
flutter test <test ciblé>
```

Pour les lots `map_runtime` :

```bash
cd packages/map_runtime
flutter test <test ciblé>
```

Pour les lots `map_gameplay` :

```bash
cd packages/map_gameplay
dart test <test ciblé>
```

Ne lance pas tout le monorepo par réflexe. Un lot minuscule doit rester minuscule. Le mode bulldozer, c'est pour casser des murs, pas pour maintenir un moteur de RPG.

---

## 1. État actuel à garder en tête

### 1.1. Modèle actuel

Le projet possède déjà :

- `ProjectTilesetEntry`
- `TilesetPaletteEntry`
- `TilesetSourceRect`
- `TilesetVisualFrame`
- `ProjectTerrainPreset`
- `TerrainPresetVariant`
- `ProjectPathPreset`
- `PathPresetVariantMapping`
- `PathAnimationTriggerRule`
- `PathLayer`
- `RuntimePathAutotileSet`
- `MapLayersComponent`

La base n'est pas mauvaise. Le problème est que l'animation et l'autotile sont actuellement attachés au monde des `paths`, alors que l'eau, les hautes herbes, les routes, la lave, la glace, les ponts et les transitions sont des surfaces du monde.

### 1.2. Décision de migration

On ne supprime pas `PathLayer` au début. On ajoute un système `Surface` en parallèle, puis on branche progressivement l'éditeur et le runtime dessus.

La trajectoire recommandée :

```text
Legacy Path System reste fonctionnel
        ↓
Surface models ajoutés dans map_core
        ↓
Surface assets et animations validés
        ↓
Runtime sait lire les animations de surface
        ↓
Editor sait créer/éditer les surfaces
        ↓
SurfaceLayer arrive comme nouveau layer propre
        ↓
PathLayer devient legacy
```

### 1.3. Format d'atlas animé cible

Le format visuel principal à supporter est :

```text
colonnes = variantes visuelles
lignes   = frames temporelles
```

Pour des tiles `32x32` :

```text
sourceX = column * 32
sourceY = frameIndex * 32
sourceW = 32
sourceH = 32
```

Mais le projet actuel utilise souvent `16x16` comme taille par défaut. Le modèle ne doit donc jamais hardcoder `32`. Il doit utiliser `tileWidth` et `tileHeight`.

---

## 2. Glossaire canonique

### Surface

Une surface est un matériau visuel et/ou interactif posé sur une carte : eau, hautes herbes, route, sable, lave, glace, rail, pont, marais, etc.

### Surface Atlas

Un atlas est une image source découpée en tiles. Il peut être statique ou contenir des bandes d'animations.

### Animated Tile Atlas

Un atlas animé est un atlas où plusieurs frames d'une même variante sont organisées selon une convention connue, par exemple colonnes = variantes, lignes = frames.

### Surface Animation

Une animation de surface est une suite de frames, chacune pointant vers une source rect dans un atlas, avec une durée.

### Sync Group

Un groupe de synchronisation impose à plusieurs animations de partager la même horloge. Indispensable pour que le centre de l'eau, ses bords et ses coins bougent ensemble.

### Surface Preset

Un preset de surface décrit comment peindre une surface : type, variantes, animation, rendu, fallback, catégorie, etc.

### Surface Variant

Une variante est une forme autotile : centre, horizontal, vertical, coin, bord, inner corner, cross, etc. En V1 on peut réutiliser `TerrainPathVariant` pour réduire le risque.

### Surface Layer

Un layer dédié aux surfaces. Il remplacera progressivement `PathLayer`, mais pas dans les premiers lots.

---

## 3. Macro-phases

| Phase | Nom | But |
|---|---|---|
| P0 | Audit et garde-fous | Stabiliser le périmètre, documenter l'existant |
| P1 | Modèle core Surface | Ajouter les modèles sans runtime ni UI lourde |
| P2 | Validation et migration JSON | Rendre les modèles sûrs dans `project.json` |
| P3 | Algorithmes purs | Layout d'atlas, horloge, resolver de frames, autotile pur |
| P4 | Use cases éditeur | Créer / modifier / supprimer surfaces et animations |
| P5 | Surface Studio minimal | UI no-code minimale, sans rendu runtime avancé |
| P6 | Runtime Animation Engine | Lire les surfaces animées dans Flame |
| P7 | SurfaceLayer | Nouveau layer dédié, sans casser PathLayer |
| P8 | Eau V1 | Première surface animée réellement belle |
| P9 | Hautes herbes V1 | Surface passable + overlay + animation au pas |
| P10 | Migration douce | Outillage Path -> Surface |
| P11 | Optimisation | Performance, cache, culling |
| P12 | Nettoyage final | Dépréciation contrôlée du legacy, docs finales |

---

# Phase P0 — Audit et garde-fous

## Lot P0.01 — Créer un rapport d'état initial Surface/Path

### Objectif

Créer un rapport markdown qui photographie l'état actuel avant de toucher au code. Ce lot ne doit modifier aucun code applicatif.

### Fichiers à créer

- `reports/surface_engine/00_initial_surface_path_audit.md`

### Fichiers à modifier

Aucun.

### Fichiers à supprimer

Aucun.

### Contenu attendu

Le rapport doit contenir :

1. Liste des fichiers actuels liés aux surfaces/paths :
   - `packages/map_core/lib/src/models/enums.dart`
   - `packages/map_core/lib/src/models/project_manifest.dart`
   - `packages/map_core/lib/src/models/map_layer.dart`
   - `packages/map_core/lib/src/operations/map_path.dart`
   - `packages/map_core/lib/src/operations/path_animation_rules.dart`
   - `packages/map_editor/lib/src/application/use_cases/path_layer_use_cases.dart`
   - `packages/map_editor/lib/src/application/use_cases/project_tileset_use_cases.dart`
   - `packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart`
   - `packages/map_runtime/lib/src/presentation/flame/runtime_path_autotile.dart`
   - `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
2. Description de ce que fait chaque fichier.
3. Liste des tests existants qui protègent les paths animés.
4. Liste des limites actuelles :
   - animation portée par `PathPresetVariantMapping` ;
   - pas de modèle Surface séparé ;
   - pas de `SurfaceLayer` ;
   - pas de `syncGroup` ;
   - pas de manifest d'atlas animé ;
   - pas de Surface Studio complet.
5. Conclusion : aucun changement fonctionnel dans ce lot.

### Tests à lancer

Aucun obligatoire.

### Validation manuelle

- Ouvrir le rapport.
- Vérifier qu'il ne prétend pas que le nouveau système existe déjà.
- Vérifier qu'il distingue bien `terrain`, `path`, `surface`, `tile`, `gameplay zone`.

### Critère de fin

Le rapport existe et peut servir de point de référence avant les modifications.

---

## Lot P0.02 — Créer un dossier de décisions d'architecture Surface Engine

### Objectif

Créer une trace durable des décisions structurantes avant de coder.

### Fichiers à créer

- `reports/surface_engine/01_architecture_decisions.md`

### Fichiers à modifier

Aucun.

### Fichiers à supprimer

Aucun.

### Contenu attendu

Le fichier doit contenir exactement ces décisions :

1. PokeMap ne dépend pas de Tiled.
2. Tiled peut devenir un import facultatif plus tard.
3. `PathLayer` reste supporté pendant toute la migration.
4. `SurfaceLayer` sera ajouté plus tard, pas dans les premiers lots core.
5. En V1, les variantes de surfaces peuvent réutiliser `TerrainPathVariant`.
6. En V2, un modèle d'adjacence plus riche pourra remplacer ou compléter `TerrainPathVariant`.
7. Les animations de surface doivent avoir un `syncGroupId` facultatif.
8. Le gameplay reste séparé du visuel.
9. Les hautes herbes ne sont pas seulement une eau verte.
10. L'eau V1 doit être la première preuve runtime.

### Tests à lancer

Aucun.

### Critère de fin

Le rapport est créé et ne contient aucune promesse de suppression immédiate du legacy.

---

## Lot P0.03 — Créer la checklist permanente des lots Surface

### Objectif

Créer une checklist à recopier dans chaque prompt futur donné à un agent.

### Fichiers à créer

- `reports/surface_engine/02_agent_checklist.md`

### Fichiers à modifier

Aucun.

### Fichiers à supprimer

Aucun.

### Contenu attendu

La checklist doit contenir :

- audit initial ;
- fichiers autorisés ;
- fichiers réellement modifiés ;
- tests lancés ;
- interdiction de commandes Git en écriture ;
- interdiction de dépendance Tiled obligatoire ;
- interdiction de suppression legacy non demandée ;
- rapport final exhaustif ;
- autocritique finale ;
- liste des points incertains.

### Tests à lancer

Aucun.

### Critère de fin

Le fichier existe et peut être collé tel quel dans les prompts Codex/Qwen/Devstral.

---

## Lot P0.04 — Ajouter un test de non-régression legacy path sans modification métier

### Objectif

Avant d'ajouter les surfaces, sécuriser le fait que les paths animés existants continuent de fonctionner.

### Fichiers à créer

Aucun si un test équivalent existe déjà. Sinon :

- `packages/map_core/test/path_legacy_non_regression_test.dart`

### Fichiers à modifier

- éventuellement `packages/map_core/test/path_preset_frames_test.dart` si le test peut être ajouté là proprement.

### Fichiers à supprimer

Aucun.

### Contenu attendu

Ajouter un test qui vérifie qu'un `ProjectPathPreset` avec :

- `surfaceKind: PathSurfaceKind.water` ;
- `tilesetId: outdoor` ;
- une variante `TerrainPathVariant.horizontal` ;
- deux `TilesetVisualFrame` avec `durationMs` positives ;

se sérialise et se désérialise sans perte.

### Tests à lancer

```bash
cd packages/map_core
dart test test/path_preset_frames_test.dart
```

ou le fichier nouvellement créé.

### Critère de fin

Le test legacy passe avant l'introduction du nouveau modèle Surface.

---

# Phase P1 — Modèle core Surface minimal

## Lot P1.01 — Créer le fichier modèle `surface.dart` vide mais câblé

### Objectif

Préparer un fichier dédié au modèle Surface sans encore modifier `ProjectManifest`.

### Fichiers à créer

- `packages/map_core/lib/src/models/surface.dart`

### Fichiers à modifier

- `packages/map_core/lib/map_core.dart`

### Fichiers à supprimer

Aucun.

### Contenu attendu dans `surface.dart`

Le fichier doit contenir :

- imports Freezed / JSON ;
- `part 'surface.freezed.dart';` ;
- `part 'surface.g.dart';` ;
- pour l'instant, un seul enum simple : `SurfaceAtlasLayout`.

Valeurs de `SurfaceAtlasLayout` :

- `grid`
- `columnsAreVariantsRowsAreFrames`
- `rowsAreVariantsColumnsAreFrames`

Chaque valeur doit avoir un `@JsonValue` stable :

- `grid`
- `columns_are_variants_rows_are_frames`
- `rows_are_variants_columns_are_frames`

### Contenu attendu dans `map_core.dart`

Exporter le nouveau modèle :

```dart
export 'src/models/surface.dart';
```

### Génération

Lancer :

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
```

### Tests à lancer

```bash
cd packages/map_core
dart test
```

### Critère de fin

- `surface.freezed.dart` généré.
- `surface.g.dart` généré.
- Aucun modèle existant modifié.
- Tous les tests `map_core` passent.

---

## Lot P1.02 — Ajouter `ProjectSurfaceAtlas`

### Objectif

Créer le modèle qui décrit une image source de surface.

### Fichiers à modifier

- `packages/map_core/lib/src/models/surface.dart`
- fichiers générés Freezed / JSON.

### Fichiers à créer

- `packages/map_core/test/surface_atlas_model_test.dart`

### Fichiers à supprimer

Aucun.

### Modèle à ajouter

Ajouter une classe Freezed `ProjectSurfaceAtlas` avec les champs :

- `required String id`
- `required String name`
- `required String tilesetId`
- `required int tileWidth`
- `required int tileHeight`
- `required int columns`
- `required int rows`
- `@Default(SurfaceAtlasLayout.grid) SurfaceAtlasLayout layout`
- `String? transparentColorHex`
- `@Default(100) int defaultFrameDurationMs`
- `@Default(0) int sortOrder`

### Explication métier

`tilesetId` référence un `ProjectTilesetEntry`. On ne duplique pas `relativePath`, car l'image est déjà gérée par la bibliothèque de tilesets.

`transparentColorHex` sert à retenir une convention type `f05ba1`, mais le runtime ne doit pas dépendre de cette couleur magique pour dessiner.

### Test attendu

Dans `surface_atlas_model_test.dart` :

1. Créer un `ProjectSurfaceAtlas`.
2. Le convertir en JSON.
3. Le relire avec `fromJson`.
4. Vérifier tous les champs.
5. Vérifier que `layout` par défaut vaut `grid`.
6. Vérifier que `defaultFrameDurationMs` par défaut vaut `100`.

### Commandes

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart test test/surface_atlas_model_test.dart
```

### Critère de fin

Le modèle round-trip en JSON sans perte.

---

## Lot P1.03 — Ajouter `SurfaceTileRef`

### Objectif

Créer une référence stable vers une tile dans un atlas de surface.

### Fichiers à modifier

- `packages/map_core/lib/src/models/surface.dart`
- fichiers générés.

### Fichiers à créer

- `packages/map_core/test/surface_tile_ref_model_test.dart`

### Fichiers à supprimer

Aucun.

### Modèle à ajouter

Ajouter une classe Freezed `SurfaceTileRef` avec :

- `required String atlasId`
- `required int x`
- `required int y`
- `@Default(1) int width`
- `@Default(1) int height`

### Explication métier

Ce modèle ressemble à `TilesetSourceRect`, mais il est volontairement rattaché à un `atlasId`. Il permet de dire :

```text
prends la tile x/y dans l'atlas de surface water_hgss
```

Il ne remplace pas `TilesetSourceRect` globalement.

### Test attendu

Tester :

- round-trip JSON ;
- valeurs par défaut `width = 1` et `height = 1` ;
- `atlasId` conservé.

### Commandes

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart test test/surface_tile_ref_model_test.dart
```

### Critère de fin

`SurfaceTileRef` fonctionne indépendamment de `ProjectManifest`.

---

## Lot P1.04 — Ajouter `SurfaceAnimationFrame`

### Objectif

Créer le modèle d'une frame d'animation de surface.

### Fichiers à modifier

- `packages/map_core/lib/src/models/surface.dart`
- fichiers générés.

### Fichiers à créer

- `packages/map_core/test/surface_animation_frame_model_test.dart`

### Fichiers à supprimer

Aucun.

### Modèle à ajouter

Ajouter une classe Freezed `SurfaceAnimationFrame` avec :

- `required SurfaceTileRef tile`
- `int? durationMs`

### Règle métier

Si `durationMs` est null, le resolver utilisera `ProjectSurfaceAtlas.defaultFrameDurationMs` ou une valeur fallback runtime.

### Test attendu

Tester :

- frame avec durée explicite ;
- frame sans durée ;
- round-trip JSON.

### Commandes

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart test test/surface_animation_frame_model_test.dart
```

### Critère de fin

Une frame peut pointer vers une tile d'atlas.

---

## Lot P1.05 — Ajouter `SurfaceAnimationPlayback`

### Objectif

Créer l'enum de playback d'animation de surface.

### Fichiers à modifier

- `packages/map_core/lib/src/models/surface.dart`
- fichiers générés.

### Fichiers à créer

- `packages/map_core/test/surface_animation_playback_test.dart`

### Fichiers à supprimer

Aucun.

### Enum à ajouter

`SurfaceAnimationPlayback` avec :

- `loop`
- `onceClampLast`

JSON values :

- `loop`
- `once_clamp_last`

### Explication métier

- `loop` : eau, lave, cascade, courant.
- `onceClampLast` : herbe qui bouge après un pas, splash, interaction locale.

Ne pas ajouter `pingPong` maintenant. Ce serait sympa, mais ce lot doit rester minuscule.

### Test attendu

Tester la sérialisation JSON des deux valeurs.

### Commandes

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart test test/surface_animation_playback_test.dart
```

### Critère de fin

L'enum est utilisable par les futurs modèles.

---

## Lot P1.06 — Ajouter `ProjectSurfaceAnimation`

### Objectif

Créer le modèle d'une animation de surface.

### Fichiers à modifier

- `packages/map_core/lib/src/models/surface.dart`
- fichiers générés.

### Fichiers à créer

- `packages/map_core/test/surface_animation_model_test.dart`

### Fichiers à supprimer

Aucun.

### Modèle à ajouter

Ajouter `ProjectSurfaceAnimation` avec :

- `required String id`
- `required String name`
- `required String atlasId`
- `@Default([]) List<SurfaceAnimationFrame> frames`
- `String? syncGroupId`
- `@Default(SurfaceAnimationPlayback.loop) SurfaceAnimationPlayback playback`
- `@Default(0) int sortOrder`

### Explication métier

`syncGroupId` permet de synchroniser plusieurs variantes d'eau entre elles.

Exemple conceptuel :

```text
water_center
water_edge_north
water_corner_ne
```

Ces animations peuvent avoir des IDs différents mais partager :

```text
syncGroupId = water_main
```

### Test attendu

Tester :

- animation avec deux frames ;
- `syncGroupId` conservé ;
- playback par défaut `loop` ;
- JSON round-trip.

### Commandes

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart test test/surface_animation_model_test.dart
```

### Critère de fin

On peut modéliser une animation d'eau sans `ProjectPathPreset`.

---

## Lot P1.07 — Ajouter `SurfaceRenderMode`

### Objectif

Décrire comment une surface doit être rendue visuellement.

### Fichiers à modifier

- `packages/map_core/lib/src/models/surface.dart`
- fichiers générés.

### Fichiers à créer

- `packages/map_core/test/surface_render_mode_test.dart`

### Fichiers à supprimer

Aucun.

### Enum à ajouter

`SurfaceRenderMode` :

- `ground`
- `overlay`
- `foregroundOverlay`

JSON values :

- `ground`
- `overlay`
- `foreground_overlay`

### Explication métier

- `ground` : rendu sous le joueur, exemple eau ou route.
- `overlay` : rendu au-dessus du terrain mais sous les entités, exemple ombres ou variations.
- `foregroundOverlay` : rendu partiellement devant le joueur, utile pour hautes herbes ou certains rebords.

Ne pas implémenter le rendu maintenant.

### Test attendu

Tester la sérialisation des trois valeurs.

### Commandes

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart test test/surface_render_mode_test.dart
```

### Critère de fin

Le modèle peut différencier eau et herbe haute côté rendu.

---

## Lot P1.08 — Ajouter `SurfaceBehaviorKind` minimal

### Objectif

Ajouter un marqueur métier léger sans fusionner visuel et gameplay.

### Fichiers à modifier

- `packages/map_core/lib/src/models/surface.dart`
- fichiers générés.

### Fichiers à créer

- `packages/map_core/test/surface_behavior_kind_test.dart`

### Fichiers à supprimer

Aucun.

### Enum à ajouter

`SurfaceBehaviorKind` :

- `decorative`
- `road`
- `water`
- `tallGrass`
- `ice`
- `lava`
- `swamp`
- `rails`
- `bridge`
- `custom`

JSON values snake_case :

- `decorative`
- `road`
- `water`
- `tall_grass`
- `ice`
- `lava`
- `swamp`
- `rails`
- `bridge`
- `custom`

### Explication métier

Ce champ sert à guider l'éditeur et le rendu. Il ne doit pas devenir la seule source de vérité gameplay.

Exemple : `water` peut suggérer une zone de surf, mais ne doit pas automatiquement créer une zone gameplay.

### Test attendu

Tester JSON des valeurs importantes : `water`, `tallGrass`, `custom`.

### Commandes

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart test test/surface_behavior_kind_test.dart
```

### Critère de fin

Le modèle distingue eau et hautes herbes sans comportement runtime implicite.

---

## Lot P1.09 — Ajouter `SurfaceVariantMapping`

### Objectif

Créer le lien entre une variante autotile et une animation ou une frame statique.

### Fichiers à modifier

- `packages/map_core/lib/src/models/surface.dart`
- fichiers générés.

### Fichiers à créer

- `packages/map_core/test/surface_variant_mapping_model_test.dart`

### Fichiers à supprimer

Aucun.

### Modèle à ajouter

`SurfaceVariantMapping` avec :

- `required TerrainPathVariant variant`
- `String? animationId`
- `SurfaceTileRef? staticTile`
- `@Default(1) int weight`

### Règle métier

Une variante doit avoir exactement une source :

- soit `animationId` ;
- soit `staticTile`.

Mais cette règle sera validée dans un lot validation, pas dans le constructeur Freezed.

### Explication

On réutilise `TerrainPathVariant` en V1 parce que le projet connaît déjà 20 variantes. Cela évite d'inventer un système Wang complet tout de suite.

### Test attendu

Tester :

- mapping animé ;
- mapping statique ;
- `weight` par défaut.

### Commandes

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart test test/surface_variant_mapping_model_test.dart
```

### Critère de fin

Une surface peut mapper `horizontal` vers une animation `water_horizontal`.

---

## Lot P1.10 — Ajouter `ProjectSurfacePreset`

### Objectif

Créer le modèle principal d'une surface no-code.

### Fichiers à modifier

- `packages/map_core/lib/src/models/surface.dart`
- fichiers générés.

### Fichiers à créer

- `packages/map_core/test/surface_preset_model_test.dart`

### Fichiers à supprimer

Aucun.

### Modèle à ajouter

`ProjectSurfacePreset` avec :

- `required String id`
- `required String name`
- `@Default(SurfaceBehaviorKind.decorative) SurfaceBehaviorKind behaviorKind`
- `String? categoryId`
- `@Default(SurfaceRenderMode.ground) SurfaceRenderMode renderMode`
- `@Default([]) List<SurfaceVariantMapping> variants`
- `@Default(<String, String>{}) Map<String, String> properties`
- `@Default(0) int sortOrder`

### Explication métier

Ce modèle devient le successeur propre de `ProjectPathPreset`. Il ne remplace pas encore `ProjectPathPreset` dans le runtime.

### Test attendu

Tester :

- preset eau avec `behaviorKind = water` ;
- `renderMode = ground` ;
- mapping vers animation ;
- round-trip JSON.

### Commandes

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart test test/surface_preset_model_test.dart
```

### Critère de fin

On peut décrire une surface complète sans toucher aux maps.

---

## Lot P1.11 — Ajouter `ProjectSurfaceCategory`

### Objectif

Créer des catégories dédiées aux surfaces, au lieu de réutiliser `pathCategories`.

### Fichiers à modifier

- `packages/map_core/lib/src/models/surface.dart`
- fichiers générés.

### Fichiers à créer

- `packages/map_core/test/surface_category_model_test.dart`

### Fichiers à supprimer

Aucun.

### Modèle à ajouter

`ProjectSurfaceCategory` avec :

- `required String id`
- `required String name`
- `String? parentCategoryId`
- `@Default(0) int sortOrder`

### Explication métier

Même structure que les catégories existantes, mais le type dédié évite de mélanger `path` legacy et `surface` V2.

### Test attendu

Tester round-trip JSON avec et sans parent.

### Commandes

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart test test/surface_category_model_test.dart
```

### Critère de fin

Les futures surfaces peuvent avoir leur propre bibliothèque.

---

# Phase P2 — Manifest, migration JSON et validation

## Lot P2.01 — Ajouter les listes Surface dans `ProjectManifest`

### Objectif

Faire entrer les surfaces dans `project.json` sans les utiliser encore.

### Fichiers à modifier

- `packages/map_core/lib/src/models/project_manifest.dart`
- fichiers générés `project_manifest.freezed.dart` et `project_manifest.g.dart`
- `packages/map_core/lib/src/models/project_manifest.dart` imports

### Fichiers à créer

- `packages/map_core/test/project_manifest_surface_fields_test.dart`

### Fichiers à supprimer

Aucun.

### Modifications attendues

Ajouter l'import :

```dart
import 'surface.dart';
```

Ajouter dans `ProjectManifest` :

- `@Default([]) List<ProjectSurfaceCategory> surfaceCategories`
- `@Default([]) List<ProjectSurfaceAtlas> surfaceAtlases`
- `@Default([]) List<ProjectSurfaceAnimation> surfaceAnimations`
- `@Default([]) List<ProjectSurfacePreset> surfacePresets`

Position recommandée : après `pathPresets`, parce que c'est le successeur naturel.

### Test attendu

Créer un `ProjectManifest` avec :

- un tileset ;
- un surface atlas ;
- une animation ;
- un surface preset.

Tester JSON round-trip.

### Commandes

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart test test/project_manifest_surface_fields_test.dart
```

### Critère de fin

`project.json` peut contenir les nouvelles listes sans casser les anciens projets.

---

## Lot P2.02 — Migrer les anciens manifests sans champs Surface

### Objectif

Garantir qu'un vieux `project.json` charge avec des listes Surface vides.

### Fichiers à modifier

- `packages/map_core/lib/src/io/legacy_editor_json_compat.dart`

### Fichiers à créer

- `packages/map_core/test/project_manifest_surface_legacy_migration_test.dart`

### Fichiers à supprimer

Aucun.

### Modifications attendues

Dans `migrateProjectManifestJson`, ajouter si absent :

- `surfaceCategories: []`
- `surfaceAtlases: []`
- `surfaceAnimations: []`
- `surfacePresets: []`

Ne pas modifier `pathPresets`.

### Test attendu

Passer un JSON minimal legacy sans champs Surface.

Vérifier que :

- `ProjectManifest.fromJson(migrateProjectManifestJson(raw))` charge ;
- les listes Surface sont vides ;
- les `pathPresets` legacy restent inchangés.

### Commandes

```bash
cd packages/map_core
dart test test/project_manifest_surface_legacy_migration_test.dart
```

### Critère de fin

Un ancien projet ne casse pas.

---

## Lot P2.03 — Initialiser les listes Surface à la création d'un projet

### Objectif

Quand l'éditeur crée un nouveau projet, les listes Surface doivent exister explicitement.

### Fichiers à modifier

- `packages/map_editor/lib/src/application/use_cases/project_management_use_cases.dart`

### Fichiers à créer ou modifier

- `packages/map_editor/test/project_management_surface_creation_test.dart`

### Fichiers à supprimer

Aucun.

### Modifications attendues

Dans `CreateProjectUseCase.execute`, ajouter au `ProjectManifest` initial :

- `surfaceCategories: const []`
- `surfaceAtlases: const []`
- `surfaceAnimations: const []`
- `surfacePresets: const []`

Si les defaults Freezed suffisent techniquement, le lot doit quand même les mettre explicitement pour la lisibilité de l'intention.

### Test attendu

Créer un projet via le use case avec fake repository/workspace.

Vérifier que :

- le manifest a les listes Surface vides ;
- les listes `pathPresets` et `terrainPresets` restent vides aussi ;
- aucun champ legacy n'est supprimé.

### Commandes

```bash
cd packages/map_editor
flutter test test/project_management_surface_creation_test.dart
```

### Critère de fin

Les nouveaux projets ont les champs Surface prêts.

---

## Lot P2.04 — Valider les `ProjectSurfaceAtlas`

### Objectif

Empêcher les atlas invalides dans `project.json`.

### Fichiers à modifier

- `packages/map_core/lib/src/validation/validators.dart`

### Fichiers à créer

- `packages/map_core/test/surface_atlas_validation_test.dart`

### Fichiers à supprimer

Aucun.

### Règles à ajouter

Pour chaque `ProjectSurfaceAtlas` :

1. `id.trim()` non vide.
2. `name.trim()` non vide.
3. `tilesetId.trim()` non vide.
4. `tilesetId` doit référencer un `ProjectTilesetEntry` existant.
5. `tileWidth > 0`.
6. `tileHeight > 0`.
7. `columns > 0`.
8. `rows > 0`.
9. `defaultFrameDurationMs > 0`.
10. `transparentColorHex`, si présent, doit être au format hex simple `RRGGBB` ou `#RRGGBB`.

### Test attendu

Créer des tests pour :

- atlas valide ;
- `tilesetId` inconnu ;
- `tileWidth = 0` ;
- `columns = 0` ;
- `defaultFrameDurationMs = 0` ;
- couleur `f05ba1` valide ;
- couleur `#f05ba1` valide ;
- couleur `pink` invalide.

### Commandes

```bash
cd packages/map_core
dart test test/surface_atlas_validation_test.dart
```

### Critère de fin

Les atlas invalides sont rejetés par `ProjectValidator.validate`.

---

## Lot P2.05 — Valider les `ProjectSurfaceAnimation`

### Objectif

Empêcher les animations sans frames ou avec références invalides.

### Fichiers à modifier

- `packages/map_core/lib/src/validation/validators.dart`

### Fichiers à créer

- `packages/map_core/test/surface_animation_validation_test.dart`

### Fichiers à supprimer

Aucun.

### Règles à ajouter

Pour chaque `ProjectSurfaceAnimation` :

1. `id.trim()` non vide.
2. `name.trim()` non vide.
3. `atlasId.trim()` non vide.
4. `atlasId` doit référencer un `ProjectSurfaceAtlas` existant.
5. `frames` non vide.
6. Chaque frame doit pointer vers le même `atlasId` que l'animation.
7. `frame.durationMs`, si non null, doit être `> 0`.
8. `tile.x >= 0`.
9. `tile.y >= 0`.
10. `tile.width > 0`.
11. `tile.height > 0`.
12. `tile.x + tile.width <= atlas.columns`.
13. `tile.y + tile.height <= atlas.rows`.
14. `syncGroupId`, si présent, doit être trim non vide.

### Test attendu

Tester au minimum :

- animation valide ;
- atlas inconnu ;
- frames vides ;
- frame hors atlas ;
- durée nulle ;
- frame qui référence un autre atlas.

### Commandes

```bash
cd packages/map_core
dart test test/surface_animation_validation_test.dart
```

### Critère de fin

Une animation d'eau mal découpée ne peut pas entrer dans le projet.

---

## Lot P2.06 — Valider les `ProjectSurfacePreset`

### Objectif

Empêcher les presets de surface incohérents.

### Fichiers à modifier

- `packages/map_core/lib/src/validation/validators.dart`

### Fichiers à créer

- `packages/map_core/test/surface_preset_validation_test.dart`

### Fichiers à supprimer

Aucun.

### Règles à ajouter

Pour chaque `ProjectSurfacePreset` :

1. `id.trim()` non vide.
2. `name.trim()` non vide.
3. `categoryId`, si présent, doit référencer une `ProjectSurfaceCategory`.
4. Chaque `SurfaceVariantMapping` doit avoir exactement une source : `animationId` XOR `staticTile`.
5. `animationId`, si présent, doit référencer une `ProjectSurfaceAnimation`.
6. `staticTile`, si présent, doit référencer un atlas existant.
7. `staticTile` doit rester dans les limites de l'atlas.
8. `weight > 0`.
9. Il ne doit pas y avoir deux mappings strictement identiques avec même `variant` et même source.

### Test attendu

Tester :

- preset valide avec animation ;
- preset valide avec static tile ;
- preset avec deux sources dans le même mapping ;
- preset sans source ;
- animation inconnue ;
- static tile hors atlas ;
- catégorie inconnue ;
- poids nul.

### Commandes

```bash
cd packages/map_core
dart test test/surface_preset_validation_test.dart
```

### Critère de fin

Les presets de surface sont fiables avant UI/runtime.

---

## Lot P2.07 — Valider l'unicité des IDs Surface

### Objectif

Éviter les conflits d'IDs dans chaque famille Surface.

### Fichiers à modifier

- `packages/map_core/lib/src/validation/validators.dart`

### Fichiers à créer

- `packages/map_core/test/surface_unique_ids_validation_test.dart`

### Fichiers à supprimer

Aucun.

### Règles à ajouter

Vérifier l'unicité de :

- `surfaceCategories.id`
- `surfaceAtlases.id`
- `surfaceAnimations.id`
- `surfacePresets.id`

Ne pas imposer l'unicité entre familles différentes pour l'instant. Exemple : un atlas et une animation peuvent tous les deux s'appeler `water` sans casser techniquement le modèle, même si l'UI devra éviter ça.

### Test attendu

Un test par famille avec doublon rejeté.

### Commandes

```bash
cd packages/map_core
dart test test/surface_unique_ids_validation_test.dart
```

### Critère de fin

Les collections Surface ne peuvent pas contenir de doublons internes.

---

# Phase P3 — Algorithmes purs Surface

## Lot P3.01 — Créer `surface_atlas_layout.dart`

### Objectif

Créer les fonctions pures qui convertissent colonnes/lignes en source rects.

### Fichiers à créer

- `packages/map_core/lib/src/operations/surface_atlas_layout.dart`
- `packages/map_core/test/surface_atlas_layout_test.dart`

### Fichiers à modifier

- `packages/map_core/lib/map_core.dart`

### Fichiers à supprimer

Aucun.

### Fonctions attendues

Créer au minimum :

```text
surfaceTileRefFromColumnRow
surfaceTileRefsFromVerticalAnimationAtlas
```

`surfaceTileRefFromColumnRow` doit recevoir :

- `atlasId`
- `column`
- `row`
- optionnellement `width = 1`
- optionnellement `height = 1`

et retourner `SurfaceTileRef(atlasId, x: column, y: row, width, height)`.

`surfaceTileRefsFromVerticalAnimationAtlas` doit recevoir :

- `atlasId`
- `columns`
- `frames`

et produire une map logique :

```text
columnIndex -> list of SurfaceTileRef for each frame row
```

### Règles

- Rejeter `columns <= 0` avec `ArgumentError`.
- Rejeter `frames <= 0` avec `ArgumentError`.
- Rejeter `atlasId.trim().isEmpty` avec `ArgumentError`.

### Tests attendus

- `column=3,row=5` donne `x=3,y=5`.
- `columns=2,frames=3` produit 2 listes de 3 frames.
- La colonne 1 frame 2 donne `x=1,y=2`.
- Les arguments invalides jettent `ArgumentError`.

### Commandes

```bash
cd packages/map_core
dart test test/surface_atlas_layout_test.dart
```

### Critère de fin

On peut lire une image type colonnes = variantes, lignes = frames sans Tiled.

---

## Lot P3.02 — Créer `surface_animation_timing.dart`

### Objectif

Créer le resolver pur de frame selon le temps écoulé.

### Fichiers à créer

- `packages/map_core/lib/src/operations/surface_animation_timing.dart`
- `packages/map_core/test/surface_animation_timing_test.dart`

### Fichiers à modifier

- `packages/map_core/lib/map_core.dart`

### Fichiers à supprimer

Aucun.

### Fonctions attendues

Créer :

```text
normalizeSurfaceFrameDurationsMs
resolveLoopingSurfaceFrameIndex
resolveOneShotSurfaceFrameIndex
```

`normalizeSurfaceFrameDurationsMs` :

- reçoit une liste de `int?` ;
- reçoit `fallbackDurationMs` ;
- remplace les null par fallback ;
- rejette les durées `<= 0` ;
- rejette fallback `<= 0`.

`resolveLoopingSurfaceFrameIndex` :

- reçoit une liste de durées positives ;
- reçoit `elapsedMs` ;
- boucle sur le total.

`resolveOneShotSurfaceFrameIndex` :

- reçoit une liste de durées positives ;
- reçoit `elapsedMs` ;
- retourne index + bool `completed`.

### Modèle de résultat à créer

Ajouter dans le même fichier une petite classe immuable :

- `SurfaceOneShotFrameResolution`
- champs : `frameIndex`, `completed`

Pas besoin de Freezed pour cette classe.

### Tests attendus

- durées `[100, 100]`, elapsed `0` -> frame 0.
- elapsed `120` -> frame 1.
- elapsed `220` en loop -> frame 0.
- one-shot elapsed `220` -> frame 1 + completed true.
- durée null remplacée par fallback.
- durée 0 rejetée.

### Commandes

```bash
cd packages/map_core
dart test test/surface_animation_timing_test.dart
```

### Critère de fin

Le runtime pourra calculer les frames sans dépendre de Flame.

---

## Lot P3.03 — Créer `surface_animation_builder.dart`

### Objectif

Créer un builder pur qui transforme une colonne d'atlas vertical en `ProjectSurfaceAnimation`.

### Fichiers à créer

- `packages/map_core/lib/src/operations/surface_animation_builder.dart`
- `packages/map_core/test/surface_animation_builder_test.dart`

### Fichiers à modifier

- `packages/map_core/lib/map_core.dart`

### Fichiers à supprimer

Aucun.

### Fonction attendue

Créer :

```text
buildSurfaceAnimationFromAtlasColumn
```

Entrées :

- `id`
- `name`
- `atlasId`
- `column`
- `frameCount`
- `durationMs`
- `syncGroupId`
- `playback`
- `sortOrder`

Sortie : `ProjectSurfaceAnimation`.

### Règles

- `id` trim non vide.
- `name` trim non vide.
- `atlasId` trim non vide.
- `column >= 0`.
- `frameCount > 0`.
- `durationMs > 0`.
- Créer `frameCount` frames avec `x = column`, `y = frameIndex`.

### Tests attendus

- colonne 5 avec 3 frames produit frames `(5,0)`, `(5,1)`, `(5,2)`.
- `syncGroupId` conservé.
- playback conservé.
- erreurs d'arguments invalides.

### Commandes

```bash
cd packages/map_core
dart test test/surface_animation_builder_test.dart
```

### Critère de fin

On peut générer automatiquement des animations depuis l'image uploadée.

---

## Lot P3.04 — Créer `surface_animation_batch_builder.dart`

### Objectif

Créer un builder pur qui génère plusieurs animations depuis un atlas vertical entier.

### Fichiers à créer

- `packages/map_core/lib/src/operations/surface_animation_batch_builder.dart`
- `packages/map_core/test/surface_animation_batch_builder_test.dart`

### Fichiers à modifier

- `packages/map_core/lib/map_core.dart`

### Fichiers à supprimer

Aucun.

### Fonction attendue

Créer :

```text
buildSurfaceAnimationsFromVerticalAtlas
```

Entrées :

- `idPrefix`
- `namePrefix`
- `atlasId`
- `columnCount`
- `frameCount`
- `durationMs`
- `syncGroupId`

Sortie : `List<ProjectSurfaceAnimation>`.

### Convention d'IDs

Pour `idPrefix = water` et 3 colonnes :

- `water_00`
- `water_01`
- `water_02`

Noms :

- `Water 00`
- `Water 01`
- `Water 02`

### Tests attendus

- 3 colonnes produisent 3 animations.
- Chaque animation a `frameCount` frames.
- `sortOrder` suit l'index de colonne.
- `syncGroupId` identique partout.

### Commandes

```bash
cd packages/map_core
dart test test/surface_animation_batch_builder_test.dart
```

### Critère de fin

Le futur Surface Studio peut générer une série d'animations en un clic.

---

## Lot P3.05 — Créer `surface_variant_defaults.dart`

### Objectif

Créer la liste canonique des 20 variantes V1 réutilisées depuis `TerrainPathVariant`.

### Fichiers à créer

- `packages/map_core/lib/src/operations/surface_variant_defaults.dart`
- `packages/map_core/test/surface_variant_defaults_test.dart`

### Fichiers à modifier

- `packages/map_core/lib/map_core.dart`

### Fichiers à supprimer

Aucun.

### Contenu attendu

Créer :

```text
kSurfaceV1AutotileVariants
```

Liste ordonnée contenant exactement :

1. `isolated`
2. `endNorth`
3. `endEast`
4. `endSouth`
5. `endWest`
6. `horizontal`
7. `vertical`
8. `cornerNE`
9. `cornerSE`
10. `cornerSW`
11. `cornerNW`
12. `innerCornerNE`
13. `innerCornerSE`
14. `innerCornerSW`
15. `innerCornerNW`
16. `teeNorth`
17. `teeEast`
18. `teeSouth`
19. `teeWest`
20. `cross`

### Tests attendus

- longueur = 20 ;
- contient toutes les valeurs ;
- ordre stable.

### Commandes

```bash
cd packages/map_core
dart test test/surface_variant_defaults_test.dart
```

### Critère de fin

L'UI peut afficher une checklist de variantes attendues.

---

## Lot P3.06 — Créer `surface_preset_coverage.dart`

### Objectif

Calculer les variantes manquantes d'un `ProjectSurfacePreset`.

### Fichiers à créer

- `packages/map_core/lib/src/operations/surface_preset_coverage.dart`
- `packages/map_core/test/surface_preset_coverage_test.dart`

### Fichiers à modifier

- `packages/map_core/lib/map_core.dart`

### Fichiers à supprimer

Aucun.

### Fonctions attendues

Créer :

```text
surfacePresetMappedVariants
surfacePresetMissingV1Variants
surfacePresetCoverageLabel
```

`surfacePresetCoverageLabel` doit retourner par exemple :

```text
16/20
```

### Tests attendus

- preset sans variant -> `0/20`.
- preset avec 2 variants -> `2/20`.
- doublon de variant ne compte qu'une fois.
- missing contient les variantes non mappées.

### Commandes

```bash
cd packages/map_core
dart test test/surface_preset_coverage_test.dart
```

### Critère de fin

Le Surface Studio peut afficher `Autotile mappings: 16/20` proprement.

---

## Lot P3.07 — Créer `surface_preset_builder.dart`

### Objectif

Créer un helper pur pour générer un preset depuis une liste d'animations en colonnes.

### Fichiers à créer

- `packages/map_core/lib/src/operations/surface_preset_builder.dart`
- `packages/map_core/test/surface_preset_builder_test.dart`

### Fichiers à modifier

- `packages/map_core/lib/map_core.dart`

### Fichiers à supprimer

Aucun.

### Fonction attendue

Créer :

```text
buildSurfacePresetFromOrderedAnimations
```

Entrées :

- `id`
- `name`
- `behaviorKind`
- `renderMode`
- `animations`
- `variants`

Règle :

- associer `variants[i]` à `animations[i].id` ;
- s'arrêter à la plus petite longueur ;
- ne pas inventer de fallback.

### Tests attendus

- 3 animations + 3 variants -> 3 mappings.
- 2 animations + 3 variants -> 2 mappings.
- ordre conservé.
- `behaviorKind` conservé.

### Commandes

```bash
cd packages/map_core
dart test test/surface_preset_builder_test.dart
```

### Critère de fin

On peut créer un preset initial depuis un atlas importé.

---

# Phase P4 — Use cases éditeur Surface

## Lot P4.01 — Créer les fonctions d'ID Surface

### Objectif

Générer des IDs stables et lisibles pour les surfaces.

### Fichiers à créer

- `packages/map_editor/lib/src/application/use_cases/surface_id_helpers.dart`
- `packages/map_editor/test/surface_id_helpers_test.dart`

### Fichiers à modifier

Aucun autre.

### Fichiers à supprimer

Aucun.

### Fonctions attendues

Créer :

```text
generateUniqueSurfaceCategoryId
generateUniqueSurfaceAtlasId
generateUniqueSurfaceAnimationId
generateUniqueSurfacePresetId
```

Chaque fonction reçoit :

- `ProjectManifest project`
- `String seed`

Règles :

- trim ;
- lowercase ;
- remplacer non alphanum par `_` ;
- compacter les `_` ;
- retirer `_` début/fin ;
- fallback : `surface`, `surface_atlas`, `surface_animation`, `surface_preset` selon la fonction ;
- suffixer `_1`, `_2`, etc. si conflit.

### Tests attendus

- `Mountain Water` -> `mountain_water`.
- doublon -> `mountain_water_1`.
- seed vide -> fallback.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_id_helpers_test.dart
```

### Critère de fin

Les use cases Surface peuvent créer des IDs no-code.

---

## Lot P4.02 — Créer `CreateSurfaceCategoryUseCase`

### Objectif

Ajouter une catégorie Surface depuis l'éditeur.

### Fichiers à créer

- `packages/map_editor/lib/src/application/use_cases/surface_category_use_cases.dart`
- `packages/map_editor/test/surface_category_use_cases_test.dart`

### Fichiers à modifier

Aucun autre sauf exports si le projet a un fichier `use_cases.dart` central.

### Fichiers à supprimer

Aucun.

### Classe attendue

`CreateSurfaceCategoryUseCase`

Entrées :

- `ProjectWorkspace workspace`
- `ProjectManifest project`
- `String name`
- `String? parentCategoryId`

Règles :

- name trim non vide ;
- parentCategoryId si présent doit exister dans `project.surfaceCategories` ;
- id généré via helper ;
- `sortOrder` = prochain index parmi les enfants du même parent ;
- save project.

### Tests attendus

- création racine ;
- création enfant ;
- parent inconnu rejeté ;
- nom vide rejeté ;
- projet sauvegardé.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_category_use_cases_test.dart
```

### Critère de fin

La bibliothèque Surface peut avoir des dossiers/catégories.

---

## Lot P4.03 — Créer `CreateSurfaceAtlasUseCase`

### Objectif

Créer un atlas de surface référencé à un tileset existant.

### Fichiers à créer

- `packages/map_editor/lib/src/application/use_cases/surface_atlas_use_cases.dart`
- `packages/map_editor/test/surface_atlas_use_cases_test.dart`

### Fichiers à modifier

Aucun autre sauf exports.

### Fichiers à supprimer

Aucun.

### Classe attendue

`CreateSurfaceAtlasUseCase`

Entrées :

- `workspace`
- `project`
- `name`
- `tilesetId`
- `tileWidth`
- `tileHeight`
- `columns`
- `rows`
- `layout`
- `transparentColorHex`
- `defaultFrameDurationMs`

Règles :

- name non vide ;
- tilesetId existant ;
- dimensions positives ;
- columns/rows positives ;
- defaultFrameDurationMs positive ;
- couleur hex valide ou null ;
- id généré ;
- save project.

### Tests attendus

- création valide ;
- tileset inconnu ;
- dimensions invalides ;
- couleur invalide ;
- projet sauvegardé.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_atlas_use_cases_test.dart
```

### Critère de fin

On peut déclarer l'image jaune/atlas dans PokeMap sans Tiled.

---

## Lot P4.04 — Créer `UpdateSurfaceAtlasUseCase`

### Objectif

Permettre de corriger les métadonnées d'un atlas.

### Fichiers à modifier

- `packages/map_editor/lib/src/application/use_cases/surface_atlas_use_cases.dart`
- `packages/map_editor/test/surface_atlas_use_cases_test.dart`

### Fichiers à supprimer

Aucun.

### Classe attendue

`UpdateSurfaceAtlasUseCase`

Entrées optionnelles :

- `name`
- `tilesetId`
- `tileWidth`
- `tileHeight`
- `columns`
- `rows`
- `layout`
- `transparentColorHex`
- `clearTransparentColorHex`
- `defaultFrameDurationMs`
- `sortOrder`

Règles :

- atlas existant obligatoire ;
- si `tilesetId` change, il doit exister ;
- ne pas modifier les animations dans ce lot ;
- valider le projet complet avant save.

### Tests attendus

- mise à jour du nom ;
- clear couleur ;
- atlas inconnu rejeté ;
- tileset inconnu rejeté.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_atlas_use_cases_test.dart
```

### Critère de fin

Un atlas peut être édité sans casser les surfaces existantes.

---

## Lot P4.05 — Créer `CreateSurfaceAnimationUseCase`

### Objectif

Créer une animation Surface manuellement.

### Fichiers à créer ou modifier

- `packages/map_editor/lib/src/application/use_cases/surface_animation_use_cases.dart`
- `packages/map_editor/test/surface_animation_use_cases_test.dart`

### Fichiers à supprimer

Aucun.

### Classe attendue

`CreateSurfaceAnimationUseCase`

Entrées :

- `workspace`
- `project`
- `name`
- `atlasId`
- `frames`
- `syncGroupId`
- `playback`

Règles :

- name non vide ;
- atlas existant ;
- frames non vides ;
- id généré ;
- projet validé ;
- save project.

### Tests attendus

- création animation valide ;
- atlas inconnu ;
- frames vides ;
- frame hors atlas ;
- `syncGroupId` trim en null si vide.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_animation_use_cases_test.dart
```

### Critère de fin

Une animation d'eau peut être enregistrée depuis l'éditeur.

---

## Lot P4.06 — Créer `GenerateSurfaceAnimationsFromVerticalAtlasUseCase`

### Objectif

Générer automatiquement N animations depuis un atlas vertical.

### Fichiers à modifier

- `packages/map_editor/lib/src/application/use_cases/surface_animation_use_cases.dart`
- `packages/map_editor/test/surface_animation_use_cases_test.dart`

### Fichiers à supprimer

Aucun.

### Classe attendue

`GenerateSurfaceAnimationsFromVerticalAtlasUseCase`

Entrées :

- `workspace`
- `project`
- `atlasId`
- `idPrefix`
- `namePrefix`
- `columnCount`
- `frameCount`
- `durationMs`
- `syncGroupId`

Règles :

- atlas existant ;
- `columnCount <= atlas.columns` ;
- `frameCount <= atlas.rows` ;
- `durationMs > 0` ;
- générer avec les helpers de `map_core` ;
- éviter les conflits d'IDs en suffixant si nécessaire ;
- ajouter les animations au projet ;
- valider ;
- save.

### Tests attendus

- atlas 23 colonnes, 32 rows -> générer 23 animations de 32 frames ;
- syncGroup commun ;
- conflit d'ID géré ;
- dépassement columns rejeté ;
- dépassement rows rejeté.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_animation_use_cases_test.dart
```

### Critère de fin

Le cas de l'image uploadée devient générable sans Tiled.

---

## Lot P4.07 — Créer `CreateSurfacePresetUseCase`

### Objectif

Créer un preset de surface depuis l'éditeur.

### Fichiers à créer ou modifier

- `packages/map_editor/lib/src/application/use_cases/surface_preset_use_cases.dart`
- `packages/map_editor/test/surface_preset_use_cases_test.dart`

### Fichiers à supprimer

Aucun.

### Classe attendue

`CreateSurfacePresetUseCase`

Entrées :

- `workspace`
- `project`
- `name`
- `behaviorKind`
- `categoryId`
- `renderMode`
- `variants`
- `properties`

Règles :

- name non vide ;
- categoryId si présent doit exister ;
- variants validés par `ProjectValidator` ;
- id généré ;
- save project.

### Tests attendus

- création eau ;
- création tall grass ;
- category unknown rejetée ;
- animation unknown rejetée ;
- projet sauvegardé.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_preset_use_cases_test.dart
```

### Critère de fin

On peut créer une surface sans passer par PathPreset.

---

## Lot P4.08 — Créer `BuildSurfacePresetFromGeneratedAnimationsUseCase`

### Objectif

Créer un preset initial automatiquement après génération d'animations.

### Fichiers à modifier

- `packages/map_editor/lib/src/application/use_cases/surface_preset_use_cases.dart`
- `packages/map_editor/test/surface_preset_use_cases_test.dart`

### Fichiers à supprimer

Aucun.

### Classe attendue

`BuildSurfacePresetFromGeneratedAnimationsUseCase`

Entrées :

- `workspace`
- `project`
- `name`
- `behaviorKind`
- `renderMode`
- `animationIds`
- `variants`
- `categoryId`

Règles :

- charger les animations par ID ;
- associer dans l'ordre aux variantes ;
- créer `ProjectSurfacePreset` ;
- valider ;
- save.

### Tests attendus

- 20 animationIds + 20 variants -> 20 mappings ;
- animation manquante rejetée ;
- moins d'animations que variants accepté mais coverage partiel ;
- coverage vérifiable via helper.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_preset_use_cases_test.dart
```

### Critère de fin

Un atlas généré peut devenir rapidement une surface utilisable.

---

## Lot P4.09 — Câbler les providers des use cases Surface

### Objectif

Rendre les use cases Surface disponibles à `EditorNotifier`.

### Fichiers à modifier

- `packages/map_editor/lib/src/app/providers/editor/project_use_case_providers.dart`
- ou le fichier provider équivalent si le repo a déjà une séparation plus pertinente.

### Fichiers à créer

- `packages/map_editor/test/provider_wiring_surface_test.dart`

### Fichiers à supprimer

Aucun.

### Modifications attendues

Ajouter des providers pour :

- create surface category ;
- create/update surface atlas ;
- create/generate surface animation ;
- create/build surface preset.

Ne pas encore ajouter toute l'UI.

### Tests attendus

Un test qui lit chaque provider depuis un `ProviderContainer` et vérifie qu'il n'est pas null.

### Commandes

```bash
cd packages/map_editor
flutter test test/provider_wiring_surface_test.dart
```

### Critère de fin

Le câblage Riverpod ne casse pas le boot éditeur.

---

## Lot P4.10 — Ajouter les méthodes Surface minimales dans `EditorNotifier`

### Objectif

Exposer les actions Surface à l'UI future.

### Fichiers à modifier

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

### Fichiers à créer

- `packages/map_editor/test/editor_notifier_surface_test.dart`

### Fichiers à supprimer

Aucun.

### Méthodes attendues

Ajouter :

- `createSurfaceAtlas(...)`
- `generateSurfaceAnimationsFromVerticalAtlas(...)`
- `createSurfacePreset(...)`

Ne pas encore ajouter toutes les méthodes update/delete si cela rend le lot trop gros.

### Règles

- vérifier `project != null` ;
- vérifier `projectRootPath != null` si nécessaire ;
- appeler use case ;
- mettre à jour `state.project` ;
- remplir `statusMessage` en succès ;
- remplir `errorMessage` en échec ;
- retourner `bool`.

### Tests attendus

- création atlas succès ;
- génération animation succès ;
- absence de projet -> false + errorMessage ;
- erreur use case -> false + errorMessage.

### Commandes

```bash
cd packages/map_editor
flutter test test/editor_notifier_surface_test.dart
```

### Critère de fin

L'UI future peut appeler le notifier.

---

# Phase P5 — Surface Studio minimal

## Lot P5.01 — Créer le dossier UI `surface_studio`

### Objectif

Créer une zone UI dédiée sans encore l'afficher.

### Fichiers à créer

- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_studio_models.dart`
- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_studio_workspace.dart`
- `packages/map_editor/test/surface_studio_workspace_smoke_test.dart`

### Fichiers à modifier

Aucun autre.

### Fichiers à supprimer

Aucun.

### Contenu attendu

`surface_studio_models.dart` :

- modèles UI simples si besoin : sélection d'atlas, sélection animation, sélection preset ;
- pas de dépendance à Flame.

`surface_studio_workspace.dart` :

- widget `SurfaceStudioWorkspace` ;
- reçoit `ProjectManifest project` ;
- affiche un titre `Surface Studio` ;
- affiche trois compteurs : atlas, animations, presets ;
- aucun bouton fonctionnel pour l'instant.

### Test attendu

Pump du widget avec un `ProjectManifest` contenant 1 atlas, 2 animations, 1 preset.

Vérifier les textes.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_studio_workspace_smoke_test.dart
```

### Critère de fin

Le Surface Studio existe comme widget autonome.

---

## Lot P5.02 — Ajouter une carte de résumé Surface dans le Terrain/Path panel

### Objectif

Afficher que les surfaces V2 existent sans remplacer l'ancienne Path Library.

### Fichiers à modifier

- `packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart`

### Fichiers à créer ou modifier

- `packages/map_editor/test/terrain_editor_surface_summary_test.dart`

### Fichiers à supprimer

Aucun.

### Comportement attendu

Dans le panel actuel :

- ajouter une section visuelle `Surface Engine V2` ;
- afficher le nombre de `surfaceAtlases` ;
- afficher le nombre de `surfaceAnimations` ;
- afficher le nombre de `surfacePresets` ;
- ne pas masquer la Path Library existante ;
- ne pas changer la sélection de path.

### Tests attendus

- projet sans surfaces -> compteurs 0 ;
- projet avec surfaces -> compteurs corrects ;
- les widgets de Path Library restent présents.

### Commandes

```bash
cd packages/map_editor
flutter test test/terrain_editor_surface_summary_test.dart
```

### Critère de fin

L'utilisateur voit la nouvelle brique sans perdre l'ancienne.

---

## Lot P5.03 — Créer un dialog de création Surface Atlas minimal

### Objectif

Permettre de déclarer un atlas depuis l'UI.

### Fichiers à créer

- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_atlas_dialogs.dart`

### Fichiers à modifier

- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_studio_workspace.dart`

### Fichiers à créer ou modifier pour tests

- `packages/map_editor/test/surface_atlas_dialog_test.dart`

### Fichiers à supprimer

Aucun.

### Champs UI attendus

- name ;
- tileset dropdown ;
- tileWidth ;
- tileHeight ;
- columns ;
- rows ;
- layout dropdown ;
- transparentColorHex ;
- defaultFrameDurationMs.

### Règles UX

- valeurs positives validées avant appel notifier ;
- message lisible si aucun tileset disponible ;
- bouton Create désactivé ou erreur claire si invalide.

### Test attendu

- dialog affiche les champs ;
- entrée invalide refuse ;
- entrée valide appelle callback avec DTO propre.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_atlas_dialog_test.dart
```

### Critère de fin

Un utilisateur peut déclarer l'image source sans Tiled.

---

## Lot P5.04 — Brancher la création d'atlas au `EditorNotifier`

### Objectif

Le bouton du dialog crée réellement un `ProjectSurfaceAtlas`.

### Fichiers à modifier

- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_studio_workspace.dart`
- éventuellement `packages/map_editor/lib/src/ui/panels/surface_studio/surface_atlas_dialogs.dart`

### Fichiers à créer ou modifier

- `packages/map_editor/test/surface_studio_create_atlas_flow_test.dart`

### Fichiers à supprimer

Aucun.

### Comportement attendu

- bouton `Add Atlas` ;
- ouvre le dialog ;
- appelle `notifier.createSurfaceAtlas` ;
- affiche statusMessage en cas de succès ;
- affiche errorMessage en cas d'échec ;
- met à jour le compteur.

### Tests attendus

Avec fake notifier ou container :

- clic add ;
- remplir champs ;
- valider ;
- vérifier projet mis à jour.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_studio_create_atlas_flow_test.dart
```

### Critère de fin

Le Surface Studio crée réellement un atlas.

---

## Lot P5.05 — Créer une preview grille d'atlas statique

### Objectif

Afficher l'image d'un atlas avec une grille logique.

### Fichiers à créer

- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_atlas_preview.dart`
- `packages/map_editor/test/surface_atlas_preview_test.dart`

### Fichiers à modifier

- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_studio_workspace.dart`

### Fichiers à supprimer

Aucun.

### Comportement attendu

Widget `SurfaceAtlasPreview` :

- reçoit un `ProjectSurfaceAtlas` ;
- reçoit éventuellement une `ui.Image` ou un path image selon convention existante ;
- affiche une grille de `columns x rows` ;
- affiche les dimensions tile ;
- si image indisponible, affiche un placeholder lisible.

### Tests attendus

- placeholder si image null ;
- texte dimensions ;
- pas de crash avec 48 colonnes / 65 lignes.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_atlas_preview_test.dart
```

### Critère de fin

L'utilisateur comprend comment PokeMap découpe l'image.

---

## Lot P5.06 — Créer une preview d'animation Surface

### Objectif

Prévisualiser une animation de surface dans l'éditeur.

### Fichiers à créer

- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_animation_preview.dart`
- `packages/map_editor/test/surface_animation_preview_test.dart`

### Fichiers à modifier

- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_studio_workspace.dart`

### Fichiers à supprimer

Aucun.

### Comportement attendu

Widget `SurfaceAnimationPreview` :

- reçoit `ProjectSurfaceAnimation` ;
- reçoit l'atlas associé ;
- affiche l'ID, le nom, le nombre de frames ;
- affiche le `syncGroupId` ou `No sync group` ;
- pour l'instant, peut afficher la première frame seulement si animer en widget est trop gros.

### Test attendu

- animation avec 32 frames affiche `32 frames` ;
- sync group affiché ;
- animation sans sync group affiche fallback.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_animation_preview_test.dart
```

### Critère de fin

L'utilisateur voit les animations générées.

---

## Lot P5.07 — Créer un dialog de génération d'animations depuis atlas vertical

### Objectif

Permettre le workflow principal : image type Pokémon SDK -> animations PokeMap.

### Fichiers à créer

- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_animation_generation_dialog.dart`
- `packages/map_editor/test/surface_animation_generation_dialog_test.dart`

### Fichiers à modifier

- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_studio_workspace.dart`

### Fichiers à supprimer

Aucun.

### Champs UI attendus

- atlas dropdown ;
- idPrefix ;
- namePrefix ;
- columnCount ;
- frameCount ;
- durationMs ;
- syncGroupId ;
- playback.

### Valeurs par défaut utiles

- `columnCount = atlas.columns` ;
- `frameCount = atlas.rows` ;
- `durationMs = atlas.defaultFrameDurationMs` ;
- `syncGroupId = idPrefix`.

### Tests attendus

- valeurs par défaut calculées depuis atlas ;
- columnCount > atlas.columns rejeté ;
- frameCount > atlas.rows rejeté ;
- callback reçoit DTO propre.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_animation_generation_dialog_test.dart
```

### Critère de fin

L'image uploadée peut être transformée en animations par UI.

---

## Lot P5.08 — Brancher la génération d'animations au notifier

### Objectif

Le dialog génère réellement les animations dans le projet.

### Fichiers à modifier

- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_studio_workspace.dart`

### Fichiers à créer ou modifier

- `packages/map_editor/test/surface_studio_generate_animations_flow_test.dart`

### Fichiers à supprimer

Aucun.

### Comportement attendu

- bouton `Generate Animations` ;
- ouvre dialog ;
- appelle `notifier.generateSurfaceAnimationsFromVerticalAtlas` ;
- compteur animations mis à jour ;
- status message lisible.

### Tests attendus

- projet avec atlas ;
- génération 3 colonnes x 2 frames ;
- vérifier 3 animations ajoutées.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_studio_generate_animations_flow_test.dart
```

### Critère de fin

Le pipeline sans Tiled existe côté UI.

---

## Lot P5.09 — Créer une checklist de mappings variants dans l'UI

### Objectif

Afficher quelles variantes autotile sont mappées ou manquantes.

### Fichiers à créer

- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_variant_mapping_list.dart`
- `packages/map_editor/test/surface_variant_mapping_list_test.dart`

### Fichiers à modifier

- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_studio_workspace.dart`

### Fichiers à supprimer

Aucun.

### Comportement attendu

Widget `SurfaceVariantMappingList` :

- reçoit un `ProjectSurfacePreset` ;
- affiche `Autotile mappings: X/20` ;
- liste les 20 variantes ;
- indique mapped/missing ;
- ne permet pas encore l'édition.

### Tests attendus

- preset vide -> `0/20` ;
- preset partiel -> `2/20` ;
- variante mapped affichée.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_variant_mapping_list_test.dart
```

### Critère de fin

La UI rend visible le problème des variantes manquantes.

---

## Lot P5.10 — Créer un dialog de création Surface Preset depuis animations

### Objectif

Créer une surface initiale en associant des animations aux variantes.

### Fichiers à créer

- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_preset_dialogs.dart`
- `packages/map_editor/test/surface_preset_dialog_test.dart`

### Fichiers à modifier

- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_studio_workspace.dart`

### Fichiers à supprimer

Aucun.

### Champs UI attendus

- name ;
- behaviorKind dropdown ;
- renderMode dropdown ;
- category dropdown optionnel ;
- liste ordonnée d'animations ;
- liste de variantes à mapper.

### Version simple acceptée

Pour ce lot, ne pas faire un mapping drag-and-drop complexe. Une version simple peut :

- prendre les animations sélectionnées dans l'ordre ;
- les mapper aux 20 variantes V1 dans l'ordre canonique.

### Tests attendus

- dialog affiche behaviorKind eau/herbe ;
- validation nom vide ;
- callback contient les bons IDs.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_preset_dialog_test.dart
```

### Critère de fin

L'utilisateur peut créer une surface initiale depuis les animations générées.

---

# Phase P6 — Runtime Surface Animation Engine

## Lot P6.01 — Créer `runtime_surface_animation_clock.dart`

### Objectif

Créer une horloge runtime dédiée aux animations de surface.

### Fichiers à créer

- `packages/map_runtime/lib/src/presentation/flame/runtime_surface_animation_clock.dart`
- `packages/map_runtime/test/runtime_surface_animation_clock_test.dart`

### Fichiers à modifier

Aucun autre.

### Fichiers à supprimer

Aucun.

### Classe attendue

`RuntimeSurfaceAnimationClock`

Champs / comportement :

- stocke `elapsedMs` ;
- méthode `update(double dt)` ;
- convertit `dt` secondes en ms ;
- méthode `elapsedForSyncGroup(String? syncGroupId)` ;
- pour V1, retourne simplement `elapsedMs` pour tous les groupes.

### Pourquoi faire simple

Le support des offsets par sync group peut venir plus tard. Pour l'eau V1, une horloge globale suffit.

### Tests attendus

- elapsed initial 0 ;
- update 0.5 -> 500 ms ;
- update cumulatif ;
- group null retourne elapsed global.

### Commandes

```bash
cd packages/map_runtime
flutter test test/runtime_surface_animation_clock_test.dart
```

### Critère de fin

Le runtime a une horloge testable sans Flame rendering.

---

## Lot P6.02 — Créer `runtime_surface_animation.dart`

### Objectif

Créer une représentation runtime légère d'une animation Surface.

### Fichiers à créer

- `packages/map_runtime/lib/src/presentation/flame/runtime_surface_animation.dart`
- `packages/map_runtime/test/runtime_surface_animation_test.dart`

### Fichiers à modifier

Aucun autre.

### Fichiers à supprimer

Aucun.

### Classe attendue

`RuntimeSurfaceAnimation`

Champs :

- `String id`
- `String atlasId`
- `String? syncGroupId`
- `SurfaceAnimationPlayback playback`
- `List<SurfaceAnimationFrame> frames`
- `List<int> durationsMs`

Factory :

```text
RuntimeSurfaceAnimation.fromProjectAnimation(ProjectSurfaceAnimation animation, ProjectSurfaceAtlas atlas)
```

Règles :

- durations null -> atlas.defaultFrameDurationMs ;
- durées positives ;
- frames non vides.

### Tests attendus

- durée fallback ;
- durée explicite ;
- frames vides rejetées.

### Commandes

```bash
cd packages/map_runtime
flutter test test/runtime_surface_animation_test.dart
```

### Critère de fin

Les animations projet sont convertibles en runtime.

---

## Lot P6.03 — Créer `runtime_surface_animation_resolver.dart`

### Objectif

Résoudre la frame courante d'une animation runtime.

### Fichiers à créer

- `packages/map_runtime/lib/src/presentation/flame/runtime_surface_animation_resolver.dart`
- `packages/map_runtime/test/runtime_surface_animation_resolver_test.dart`

### Fichiers à modifier

Aucun autre.

### Fichiers à supprimer

Aucun.

### Classe ou fonction attendue

Créer une fonction :

```text
resolveRuntimeSurfaceAnimationFrame
```

Entrées :

- `RuntimeSurfaceAnimation animation`
- `double elapsedMs`

Sortie :

- `SurfaceAnimationFrame`

Règles :

- si playback loop : boucle ;
- si one-shot : clamp à la dernière frame ;
- utiliser les helpers purs de `map_core` si exportés.

### Tests attendus

- 0 ms -> frame 0 ;
- 120 ms -> frame 1 ;
- 220 ms en loop -> frame 0 ;
- 220 ms en one-shot -> dernière frame.

### Commandes

```bash
cd packages/map_runtime
flutter test test/runtime_surface_animation_resolver_test.dart
```

### Critère de fin

Le runtime sait quelle frame dessiner.

---

## Lot P6.04 — Créer `runtime_surface_catalog.dart`

### Objectif

Centraliser atlas, animations et presets Surface côté runtime.

### Fichiers à créer

- `packages/map_runtime/lib/src/presentation/flame/runtime_surface_catalog.dart`
- `packages/map_runtime/test/runtime_surface_catalog_test.dart`

### Fichiers à modifier

Aucun autre.

### Fichiers à supprimer

Aucun.

### Classe attendue

`RuntimeSurfaceCatalog`

Factory :

```text
RuntimeSurfaceCatalog.fromManifest(ProjectManifest manifest)
```

Index internes :

- atlas by id ;
- animation by id ;
- preset by id ;
- runtime animation by id.

Méthodes :

- `atlasById(String id)` ;
- `animationById(String id)` ;
- `presetById(String id)` ;
- `runtimeAnimationById(String id)`.

### Tests attendus

- manifest vide ;
- lookup atlas ;
- lookup animation ;
- lookup preset ;
- animation avec atlas inconnu ignorée ou rejetée selon choix, mais le choix doit être documenté dans le test.

### Recommandation

Rejeter avec `StateError` en factory si le manifest est incohérent. Normalement `ProjectValidator` protège déjà, mais le runtime doit échouer clairement.

### Commandes

```bash
cd packages/map_runtime
flutter test test/runtime_surface_catalog_test.dart
```

### Critère de fin

Le renderer pourra chercher rapidement les surfaces.

---

## Lot P6.05 — Créer `runtime_surface_frame_resolved.dart`

### Objectif

Créer un DTO runtime qui décrit exactement quoi dessiner.

### Fichiers à créer

- `packages/map_runtime/lib/src/presentation/flame/runtime_surface_frame_resolved.dart`
- `packages/map_runtime/test/runtime_surface_frame_resolved_test.dart`

### Fichiers à modifier

Aucun autre.

### Fichiers à supprimer

Aucun.

### Classe attendue

`RuntimeSurfaceResolvedFrame`

Champs :

- `String atlasId`
- `String tilesetId`
- `TilesetSourceRect source`

### Factory attendue

À partir de :

- `ProjectSurfaceAtlas atlas`
- `SurfaceAnimationFrame frame`

La factory doit convertir `SurfaceTileRef` vers `TilesetSourceRect`.

### Test attendu

- atlas `tilesetId=outdoor` ;
- frame tile x=3,y=4 ;
- resolved source x=3,y=4,width=1,height=1 ;
- tilesetId = outdoor.

### Commandes

```bash
cd packages/map_runtime
flutter test test/runtime_surface_frame_resolved_test.dart
```

### Critère de fin

Le rendu peut recevoir une source rect compatible avec le système existant.

---

## Lot P6.06 — Résoudre une variante de Surface Preset à un instant T

### Objectif

Savoir quelle frame dessiner pour une variante donnée.

### Fichiers à créer

- `packages/map_runtime/lib/src/presentation/flame/runtime_surface_preset_resolver.dart`
- `packages/map_runtime/test/runtime_surface_preset_resolver_test.dart`

### Fichiers à modifier

Aucun autre.

### Fichiers à supprimer

Aucun.

### Classe attendue

`RuntimeSurfacePresetResolver`

Entrées constructeur :

- `RuntimeSurfaceCatalog catalog`
- `RuntimeSurfaceAnimationClock clock`

Méthode :

```text
resolveVariant(ProjectSurfacePreset preset, TerrainPathVariant variant)
```

Retour :

- `RuntimeSurfaceResolvedFrame?`

Règles :

- si variant absent -> null ;
- si mapping staticTile -> frame résolue statique ;
- si mapping animationId -> résoudre animation selon clock et syncGroup ;
- si plusieurs mappings pour même variant, prendre le premier en V1.

### Tests attendus

- static tile ;
- animation loop ;
- variant absent ;
- animation inconnue doit échouer clairement si catalog incohérent.

### Commandes

```bash
cd packages/map_runtime
flutter test test/runtime_surface_preset_resolver_test.dart
```

### Critère de fin

Le runtime sait résoudre une variante sans dessiner.

---

## Lot P6.07 — Brancher l'horloge Surface dans `MapLayersComponent` sans rendu

### Objectif

Préparer `MapLayersComponent` à animer les surfaces, sans encore dessiner les surfaces.

### Fichiers à modifier

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

### Fichiers à créer ou modifier

- `packages/map_runtime/test/map_layers_component_surface_clock_test.dart`

### Fichiers à supprimer

Aucun.

### Modifications attendues

- Ajouter un champ `RuntimeSurfaceAnimationClock _surfaceClock`.
- Dans `update(dt)`, appeler `_surfaceClock.update(dt)`.
- Ne pas modifier `_animElapsed` existant.
- Ne pas modifier le rendu path existant.

### Test attendu

Tester indirectement si possible avec une getter visibleForTesting ou en isolant l'horloge.

Si tester `MapLayersComponent` directement est trop lourd, créer une méthode `@visibleForTesting double get surfaceAnimationElapsedMs`.

### Commandes

```bash
cd packages/map_runtime
flutter test test/map_layers_component_surface_clock_test.dart
```

### Critère de fin

L'horloge est présente mais aucun rendu ne change.

---

## Lot P6.08 — Ajouter le `RuntimeSurfaceCatalog` à `MapLayersComponent`

### Objectif

Construire le catalog runtime depuis le manifest.

### Fichiers à modifier

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

### Fichiers à créer ou modifier

- `packages/map_runtime/test/map_layers_component_surface_catalog_test.dart`

### Fichiers à supprimer

Aucun.

### Modifications attendues

Dans le constructeur :

- créer `_surfaceCatalog = RuntimeSurfaceCatalog.fromManifest(bundle.manifest)`.

Ajouter champ final :

- `RuntimeSurfaceCatalog _surfaceCatalog`.

Ne pas encore utiliser dans paint.

### Tests attendus

- composant se construit avec manifest sans surfaces ;
- composant se construit avec manifest avec surfaces ;
- path rendering existant ne casse pas.

### Commandes

```bash
cd packages/map_runtime
flutter test test/map_layers_component_surface_catalog_test.dart
```

### Critère de fin

Le runtime connaît les surfaces disponibles.

---

# Phase P7 — SurfaceLayer

## Lot P7.01 — Ajouter `MapLayer.surface` dans `map_layer.dart`

### Objectif

Créer un layer dédié aux surfaces, sans supprimer `PathLayer`.

### Fichiers à modifier

- `packages/map_core/lib/src/models/map_layer.dart`
- fichiers générés `map_layer.freezed.dart`, `map_layer.g.dart`

### Fichiers à créer

- `packages/map_core/test/surface_layer_model_test.dart`

### Fichiers à supprimer

Aucun.

### Modèle à ajouter

Dans `MapLayer` ajouter :

```text
@FreezedUnionValue('surface')
MapLayer.surface
```

Champs :

- `required String id`
- `required String name`
- `@Default(true) bool isVisible`
- `@Default(1.0) double opacity`
- `@Default('') String surfacePresetId`
- `@Default([]) List<bool> cells`
- `@Default(<String, String>{}) Map<String, String> properties`
- `@Default(PathAnimationMode.triggered) PathAnimationMode animationMode`
- `@Default([]) List<PathAnimationTriggerRule> animationTriggers`

### Pourquoi réutiliser `PathAnimation...` temporairement

Pour éviter de créer une deuxième taxonomie de triggers dans le même lot. On pourra renommer plus tard si nécessaire.

### Test attendu

- JSON round-trip ;
- runtimeType `surface` ;
- defaults ;
- triggers existants parsés.

### Commandes

```bash
cd packages/map_core
dart run build_runner build --delete-conflicting-outputs
dart test test/surface_layer_model_test.dart
```

### Critère de fin

Une map peut contenir un layer surface sans casser les layers existants.

---

## Lot P7.02 — Ajouter `surface` dans `MapLayerKind`

### Objectif

Permettre aux outils de reconnaître le nouveau type de layer.

### Fichiers à modifier

- `packages/map_core/lib/src/models/enums.dart`

### Fichiers à créer ou modifier

- `packages/map_core/test/surface_layer_kind_test.dart`

### Fichiers à supprimer

Aucun.

### Modification attendue

Ajouter à `MapLayerKind` :

- `@JsonValue('surface') surface`

### Tests attendus

- JSON de l'enum si déjà testé ;
- sinon test simple avec `MapLayer.surface` qui confirme que le runtimeType est `surface`.

### Commandes

```bash
cd packages/map_core
dart test test/surface_layer_kind_test.dart
```

### Critère de fin

Le type de layer est officiel.

---

## Lot P7.03 — Adapter la validation map pour `SurfaceLayer`

### Objectif

Valider la taille de `cells` et la référence au preset.

### Fichiers à modifier

- `packages/map_core/lib/src/validation/validators.dart`

### Fichiers à créer

- `packages/map_core/test/surface_layer_validation_test.dart`

### Fichiers à supprimer

Aucun.

### Règles attendues

Pour chaque `SurfaceLayer` :

- `id` non vide ;
- `name` non vide ;
- `opacity` dans les bornes déjà utilisées par les autres layers ;
- si `surfacePresetId` non vide, il doit référencer `ProjectManifest.surfacePresets` ;
- `cells.length` doit être 0 ou exactement `map.size.width * map.size.height` selon la convention existante des PathLayer ;
- triggers validés comme PathLayer.

### Tests attendus

- layer valide ;
- preset inconnu ;
- cells mauvaise taille ;
- surfacePresetId vide autorisé pour layer préparatoire.

### Commandes

```bash
cd packages/map_core
dart test test/surface_layer_validation_test.dart
```

### Critère de fin

Les maps ne peuvent pas référencer une surface inexistante.

---

## Lot P7.04 — Ajouter opérations `map_surface.dart`

### Objectif

Créer les opérations pures pour peindre/effacer une surface.

### Fichiers à créer

- `packages/map_core/lib/src/operations/map_surface.dart`
- `packages/map_core/test/map_surface_operations_test.dart`

### Fichiers à modifier

- `packages/map_core/lib/map_core.dart`

### Fichiers à supprimer

Aucun.

### Fonctions attendues

Créer :

- `paintSurfaceOnLayer`
- `eraseSurfaceOnLayer`
- `assignSurfacePresetToLayer`

Comportement proche de `map_path.dart` mais ciblé `SurfaceLayer`.

### Règles

- si layer introuvable -> exception claire ;
- si layer n'est pas SurfaceLayer -> exception claire ;
- peinture initialise `cells` à la bonne taille si vide ;
- peinture met la cellule à true ;
- erase met la cellule à false ;
- hors map rejeté.

### Tests attendus

- paint cellule ;
- erase cellule ;
- assign preset ;
- mauvais layer ;
- hors map.

### Commandes

```bash
cd packages/map_core
dart test test/map_surface_operations_test.dart
```

### Critère de fin

Le domaine sait manipuler un `SurfaceLayer` sans UI.

---

## Lot P7.05 — Ajouter use cases `surface_layer_use_cases.dart`

### Objectif

Exposer les opérations de surface layer à l'application éditeur.

### Fichiers à créer

- `packages/map_editor/lib/src/application/use_cases/surface_layer_use_cases.dart`
- `packages/map_editor/test/surface_layer_use_cases_test.dart`

### Fichiers à modifier

Aucun autre sauf exports/providers plus tard.

### Fichiers à supprimer

Aucun.

### Classes attendues

- `PaintSurfaceOnMapUseCase`
- `EraseSurfaceOnMapUseCase`
- `AssignSurfaceLayerPresetUseCase`

Chaque classe :

- appelle l'opération `map_core` correspondante ;
- appelle `MapValidator.validate` ;
- retourne `MapData`.

### Tests attendus

- paint surface ;
- erase surface ;
- assign preset ;
- validation appelée indirectement par cas invalide.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_layer_use_cases_test.dart
```

### Critère de fin

L'éditeur peut manipuler des SurfaceLayer côté application.

---

## Lot P7.06 — Adapter les outils éditeur pour reconnaître `SurfaceLayer`

### Objectif

Ne pas bloquer l'outil terrain/surface quand le layer actif est `SurfaceLayer`.

### Fichiers à modifier

- `packages/map_editor/lib/src/features/editor/application/map_selection_controller.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- éventuellement `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`

### Fichiers à créer ou modifier

- `packages/map_editor/test/surface_layer_tool_compatibility_test.dart`

### Fichiers à supprimer

Aucun.

### Modifications attendues

Partout où la logique dit :

```text
TerrainLayer || PathLayer
```

ajouter `SurfaceLayer` pour l'outil surface/terrain paint si pertinent.

Partout où erase accepte `PathLayer`, ajouter `SurfaceLayer`.

Ne pas retirer `PathLayer`.

### Tests attendus

- `terrainPaint` compatible avec `SurfaceLayer` ;
- `eraser` compatible avec `SurfaceLayer` ;
- `tilePaint` non compatible avec `SurfaceLayer`.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_layer_tool_compatibility_test.dart
```

### Critère de fin

Le nouveau layer n'est pas inutilisable dans l'éditeur.

---

## Lot P7.07 — Adapter le Layers Panel pour afficher `SurfaceLayer`

### Objectif

Rendre le type de layer lisible dans l'UI.

### Fichiers à modifier

- `packages/map_editor/lib/src/ui/panels/layers_panel.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`

### Fichiers à créer ou modifier

- `packages/map_editor/test/surface_layer_ui_label_test.dart`

### Fichiers à supprimer

Aucun.

### Comportement attendu

- `Surface Layer` comme label technique ;
- `Surface layer active` dans l'overview ;
- section surfaces visible quand activeLayer est `SurfaceLayer` ;
- PathLayer continue d'afficher `Surface layer active` ou `Path Layer` selon choix existant, mais ne doit pas disparaître.

### Tests attendus

- map avec SurfaceLayer affiche le label ;
- pas de crash dans inspector ;
- PathLayer toujours reconnu.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_layer_ui_label_test.dart
```

### Critère de fin

L'utilisateur voit le nouveau layer proprement.

---

# Phase P8 — Rendu runtime des surfaces

## Lot P8.01 — Créer `runtime_surface_autotile.dart`

### Objectif

Résoudre la variante à utiliser pour une cellule SurfaceLayer selon ses voisins.

### Fichiers à créer

- `packages/map_runtime/lib/src/presentation/flame/runtime_surface_autotile.dart`
- `packages/map_runtime/test/runtime_surface_autotile_test.dart`

### Fichiers à supprimer

Aucun.

### Fonction attendue

Créer :

```text
resolveSurfaceVariantForCell
```

Entrées :

- `List<bool> cells`
- `GridSize mapSize`
- `GridPos pos`

Sortie :

- `TerrainPathVariant`

### Règle V1

Réutiliser la logique actuelle de path autotile si elle existe déjà. Si elle est dans `map_editor` et pas accessible, déplacer uniquement la logique pure vers `map_core` dans un lot séparé avant celui-ci.

### Tests attendus

- cellule isolée -> `isolated` ;
- ligne horizontale -> `horizontal` ;
- ligne verticale -> `vertical` ;
- coin -> variante de coin correcte ;
- cross -> `cross`.

### Commandes

```bash
cd packages/map_runtime
flutter test test/runtime_surface_autotile_test.dart
```

### Critère de fin

Le runtime peut savoir quelle variante demander au preset.

---

## Lot P8.02 — Dessiner un `SurfaceLayer` statique dans `MapLayersComponent`

### Objectif

Premier rendu SurfaceLayer, sans animation.

### Fichiers à modifier

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

### Fichiers à créer ou modifier

- `packages/map_runtime/test/map_layers_component_surface_static_render_test.dart`

### Fichiers à supprimer

Aucun.

### Comportement attendu

Dans la boucle de rendu des layers :

- détecter `SurfaceLayer` ;
- si invisible, skip ;
- si `surfacePresetId` vide, skip ;
- récupérer le `ProjectSurfacePreset` via `_surfaceCatalog` ;
- pour chaque cellule true :
  - résoudre la variante via `runtime_surface_autotile.dart` ;
  - résoudre la frame via `RuntimeSurfacePresetResolver` ;
  - dessiner avec `canvas.drawImageRect` comme les tiles existantes.

Dans ce lot, utiliser uniquement des mappings `staticTile`. Ne pas exiger animation.

### Tests attendus

- composant ne crash pas avec SurfaceLayer statique ;
- si possible, golden/render test minimal ;
- sinon test par extraction helper de résolution.

### Commandes

```bash
cd packages/map_runtime
flutter test test/map_layers_component_surface_static_render_test.dart
```

### Critère de fin

Une surface statique peut apparaître dans le runtime.

---

## Lot P8.03 — Dessiner un `SurfaceLayer` animé

### Objectif

Brancher les animations Surface au rendu.

### Fichiers à modifier

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

### Fichiers à créer ou modifier

- `packages/map_runtime/test/map_layers_component_surface_animation_render_test.dart`

### Fichiers à supprimer

Aucun.

### Comportement attendu

Même pipeline que le statique, mais si le mapping utilise `animationId` :

- résoudre la frame selon `_surfaceClock` ;
- dessiner la source rect correspondant à la frame ;
- respecter `syncGroupId`.

### Tests attendus

Créer une surface avec :

- atlas ;
- animation 2 frames ;
- mapping `horizontal` ;
- clock à 0 ms -> source x/y frame 0 ;
- clock à 120 ms -> source x/y frame 1.

Si tester le canvas est pénible, isoler la résolution dans une méthode testable.

### Commandes

```bash
cd packages/map_runtime
flutter test test/map_layers_component_surface_animation_render_test.dart
```

### Critère de fin

Le runtime peut afficher une eau animée en théorie.

---

## Lot P8.04 — Respecter `SurfaceRenderMode.ground`

### Objectif

Rendre les surfaces ground dans la passe background.

### Fichiers à modifier

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

### Fichiers à créer ou modifier

- `packages/map_runtime/test/map_layers_component_surface_render_mode_test.dart`

### Fichiers à supprimer

Aucun.

### Règle attendue

- `SurfaceRenderMode.ground` rendu uniquement en `MapLayerRenderPass.background`.
- `SurfaceRenderMode.foregroundOverlay` non rendu en background dans ce lot.
- `SurfaceRenderMode.overlay` rendu en background pour l'instant, sauf si architecture existante offre une meilleure passe.

### Tests attendus

- ground présent en background ;
- ground absent en foreground ;
- foregroundOverlay absent en background.

### Commandes

```bash
cd packages/map_runtime
flutter test test/map_layers_component_surface_render_mode_test.dart
```

### Critère de fin

On prépare les hautes herbes sans casser l'eau.

---

## Lot P8.05 — Respecter `SurfaceRenderMode.foregroundOverlay`

### Objectif

Rendre certaines surfaces devant le joueur/les entités.

### Fichiers à modifier

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- éventuellement l'endroit où les passes foreground/background sont ajoutées dans le jeu runtime.

### Fichiers à créer ou modifier

- `packages/map_runtime/test/map_layers_component_surface_foreground_overlay_test.dart`

### Fichiers à supprimer

Aucun.

### Règle attendue

- `foregroundOverlay` rendu uniquement en `MapLayerRenderPass.foreground`.
- `ground` non rendu en foreground.
- `overlay`, si ambigu, documenter le choix et garder simple.

### Tests attendus

- surface tallGrass foreground visible uniquement foreground ;
- surface water ground visible uniquement background.

### Commandes

```bash
cd packages/map_runtime
flutter test test/map_layers_component_surface_foreground_overlay_test.dart
```

### Critère de fin

Le rendu des hautes herbes devient possible.

---

# Phase P9 — Eau V1

## Lot P9.01 — Créer fixture de projet eau animée minimal

### Objectif

Créer une fixture de test représentant une eau animée sans Tiled.

### Fichiers à créer

- `packages/map_runtime/test/fixtures/surface_water_fixture.dart`

### Fichiers à modifier

Aucun autre sauf tests qui l'utilisent.

### Fichiers à supprimer

Aucun.

### Contenu attendu

La fixture doit exposer une fonction qui retourne :

- `ProjectManifest` avec :
  - un tileset `water_tileset` ;
  - un `ProjectSurfaceAtlas` ;
  - deux animations `water_horizontal` et `water_vertical` ;
  - un preset `water_surface` ;
- `MapData` avec :
  - un `SurfaceLayer` ;
  - quelques cellules true.

### Tests à lancer

Aucun si la fixture compile via les tests suivants.

### Critère de fin

Les futurs tests n'ont pas besoin de réécrire 60 lignes de manifest.

---

## Lot P9.02 — Test runtime eau : frame synchronisée

### Objectif

Prouver que plusieurs variantes d'eau partagent la même horloge.

### Fichiers à créer

- `packages/map_runtime/test/runtime_surface_water_sync_test.dart`

### Fichiers à modifier

- éventuellement fixture `surface_water_fixture.dart`.

### Fichiers à supprimer

Aucun.

### Test attendu

Créer deux animations avec :

- même `syncGroupId = water_main` ;
- mêmes durées ;
- sources différentes.

À elapsed 120 ms :

- les deux animations doivent être à la frame index 1 ;
- seules leurs colonnes/source x diffèrent.

### Commandes

```bash
cd packages/map_runtime
flutter test test/runtime_surface_water_sync_test.dart
```

### Critère de fin

Le centre et les bords d'eau ne se désynchronisent pas.

---

## Lot P9.03 — Créer un preset eau depuis atlas vertical dans test editor

### Objectif

Prouver le workflow sans Tiled côté éditeur.

### Fichiers à créer

- `packages/map_editor/test/surface_water_vertical_atlas_flow_test.dart`

### Fichiers à modifier

Aucun autre sauf si helpers manquent.

### Fichiers à supprimer

Aucun.

### Test attendu

Workflow :

1. Projet avec tileset `water_tileset`.
2. Créer atlas `water_atlas` avec `columns=23`, `rows=32`.
3. Générer 23 animations avec `syncGroupId=water_main`.
4. Créer preset eau avec 20 premières animations mappées aux 20 variantes V1.
5. Vérifier coverage `20/20`.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_water_vertical_atlas_flow_test.dart
```

### Critère de fin

L'image type Pokémon SDK peut devenir une surface PokeMap en workflow pur.

---

## Lot P9.04 — Ajouter une preview eau dans Surface Studio

### Objectif

Afficher une mini-map de preview de l'eau.

### Fichiers à créer

- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_autotile_preview_grid.dart`
- `packages/map_editor/test/surface_autotile_preview_grid_test.dart`

### Fichiers à modifier

- `packages/map_editor/lib/src/ui/panels/surface_studio/surface_studio_workspace.dart`

### Fichiers à supprimer

Aucun.

### Comportement attendu

Widget de preview :

- grille 5x5 ;
- motif d'eau central ;
- affiche quelles variantes seraient utilisées ;
- si une variante manque, cellule en warning ;
- pas besoin d'animer réellement dans ce lot.

### Tests attendus

- preset complet -> aucun warning ;
- preset incomplet -> warning visible ;
- coverage affiché.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_autotile_preview_grid_test.dart
```

### Critère de fin

L'utilisateur peut voir si son eau est mappée correctement.

---

# Phase P10 — Hautes herbes V1

## Lot P10.01 — Créer fixture tall grass Surface

### Objectif

Créer une surface de hautes herbes qui utilise `foregroundOverlay`.

### Fichiers à créer

- `packages/map_runtime/test/fixtures/surface_tall_grass_fixture.dart`

### Fichiers à modifier

Aucun autre sauf tests.

### Fichiers à supprimer

Aucun.

### Contenu attendu

Manifest :

- atlas tall grass ;
- animation loop ou statique ;
- preset `tall_grass_surface` ;
- `behaviorKind = tallGrass` ;
- `renderMode = foregroundOverlay`.

Map :

- SurfaceLayer avec plusieurs cellules true.

### Critère de fin

Les tests hautes herbes ont une base stable.

---

## Lot P10.02 — Ajouter test rendu foreground hautes herbes

### Objectif

Prouver que les hautes herbes peuvent être rendues dans la passe foreground.

### Fichiers à créer

- `packages/map_runtime/test/surface_tall_grass_foreground_test.dart`

### Fichiers à modifier

Aucun sauf fixture.

### Fichiers à supprimer

Aucun.

### Test attendu

- `SurfaceRenderMode.foregroundOverlay` ;
- absent en background ;
- présent en foreground.

### Commandes

```bash
cd packages/map_runtime
flutter test test/surface_tall_grass_foreground_test.dart
```

### Critère de fin

La base visuelle des hautes herbes est là.

---

## Lot P10.03 — Créer modèle runtime d'animation locale de surface

### Objectif

Préparer les animations déclenchées par une cellule, comme l'herbe qui bouge quand le joueur marche dessus.

### Fichiers à créer

- `packages/map_runtime/lib/src/presentation/flame/runtime_surface_cell_animation.dart`
- `packages/map_runtime/test/runtime_surface_cell_animation_test.dart`

### Fichiers à supprimer

Aucun.

### Classe attendue

`RuntimeSurfaceCellAnimation`

Champs :

- `String layerId`
- `GridPos pos`
- `String animationId`
- `double startedAtMs`

Méthodes/helpers :

- key stable par layerId + pos ;
- elapsed depuis clock ;
- completed si playback one-shot terminé.

### Tests attendus

- key stable ;
- elapsed correct ;
- completed après durée totale.

### Commandes

```bash
cd packages/map_runtime
flutter test test/runtime_surface_cell_animation_test.dart
```

### Critère de fin

On peut déclencher une animation locale sans modifier le joueur.

---

## Lot P10.04 — Ajouter une API pour déclencher une animation de cellule Surface

### Objectif

Permettre au runtime de dire : cette cellule d'herbe vient d'être traversée.

### Fichiers à modifier

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

### Fichiers à créer ou modifier

- `packages/map_runtime/test/map_layers_component_surface_cell_trigger_test.dart`

### Fichiers à supprimer

Aucun.

### API attendue

Ajouter une méthode publique ou visibleForTesting :

```text
triggerSurfaceCellAnimation({layerId, pos, animationId})
```

Comportement :

- ajoute/remplace l'animation active pour cette cellule ;
- utilise l'horloge Surface ;
- prune les one-shots terminés dans `update`.

### Tests attendus

- trigger ajoute animation ;
- retrigger restart ;
- update après durée totale prune.

### Commandes

```bash
cd packages/map_runtime
flutter test test/map_layers_component_surface_cell_trigger_test.dart
```

### Critère de fin

La mécanique locale des hautes herbes est possible.

---

## Lot P10.05 — Connecter déplacement joueur -> trigger hautes herbes

### Objectif

Quand le joueur entre dans une cellule de tall grass, déclencher l'animation locale.

### Fichiers à modifier

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- ou le fichier qui orchestre déjà les feedbacks de mouvement.

### Fichiers à créer ou modifier

- `packages/map_runtime/test/playable_map_game_tall_grass_animation_trigger_test.dart`

### Fichiers à supprimer

Aucun.

### Règles

- Détecter entrée dans une cellule SurfaceLayer dont preset `behaviorKind = tallGrass`.
- Ne pas créer de rencontre sauvage dans ce lot.
- Ne pas bloquer le mouvement.
- Appeler `triggerSurfaceCellAnimation`.

### Tests attendus

- déplacement sur tall grass déclenche ;
- déplacement sur water ne déclenche pas tall grass ;
- déplacement hors surface ne déclenche rien.

### Commandes

```bash
cd packages/map_runtime
flutter test test/playable_map_game_tall_grass_animation_trigger_test.dart
```

### Critère de fin

Les hautes herbes réagissent au joueur.

---

# Phase P11 — Gameplay integration minimale

## Lot P11.01 — Créer helper de requête Surface sous une cellule

### Objectif

Permettre au gameplay/runtime de savoir quelles surfaces existent sous une position.

### Fichiers à créer

- `packages/map_core/lib/src/operations/map_surface_query.dart`
- `packages/map_core/test/map_surface_query_test.dart`

### Fichiers à modifier

- `packages/map_core/lib/map_core.dart`

### Fichiers à supprimer

Aucun.

### Fonctions attendues

- `surfaceLayersAtCell(MapData map, GridPos pos)` ;
- `surfaceLayerHasCell(SurfaceLayer layer, GridSize size, GridPos pos)`.

### Tests attendus

- surface présente ;
- surface absente ;
- pos hors map ;
- cells vides.

### Commandes

```bash
cd packages/map_core
dart test test/map_surface_query_test.dart
```

### Critère de fin

On peut interroger les surfaces sans rendu.

---

## Lot P11.02 — Créer helper `ProjectSurfaceLookup`

### Objectif

Résoudre rapidement les presets depuis les layers.

### Fichiers à créer

- `packages/map_core/lib/src/operations/project_surface_lookup.dart`
- `packages/map_core/test/project_surface_lookup_test.dart`

### Fichiers à modifier

- `packages/map_core/lib/map_core.dart`

### Fichiers à supprimer

Aucun.

### Fonctions attendues

- `surfacePresetById(ProjectManifest project, String id)` ;
- `surfacePresetsAtCell(ProjectManifest project, MapData map, GridPos pos)`.

### Tests attendus

- trouve preset ;
- ignore presetId vide ;
- ignore preset inconnu ou lève selon décision documentée ;
- retourne tall grass sous cellule.

### Commandes

```bash
cd packages/map_core
dart test test/project_surface_lookup_test.dart
```

### Critère de fin

Le runtime peut savoir si une cellule est tall grass/water.

---

## Lot P11.03 — Ne pas confondre Surface water et surf gameplay

### Objectif

Ajouter un test qui protège la séparation visuel/gameplay.

### Fichiers à créer

- `packages/map_gameplay/test/surface_visual_does_not_imply_surf_test.dart`

### Fichiers à modifier

Aucun sauf si helper nécessaire.

### Fichiers à supprimer

Aucun.

### Test attendu

Créer une map avec :

- SurfaceLayer water ;
- aucune MovementZone surf ;
- joueur sans droit surf.

Vérifier que le comportement gameplay actuel ne décide pas automatiquement que la cellule est surfable simplement à cause du visuel water.

### Commandes

```bash
cd packages/map_gameplay
dart test test/surface_visual_does_not_imply_surf_test.dart
```

### Critère de fin

Le visuel ne devient pas une règle gameplay cachée.

---

## Lot P11.04 — Ne pas confondre tall grass visuelle et rencontres sauvages

### Objectif

Protéger la séparation entre surface visuelle et encounter zones.

### Fichiers à créer

- `packages/map_gameplay/test/surface_tall_grass_does_not_imply_encounter_test.dart`

### Fichiers à modifier

Aucun sauf si helper nécessaire.

### Fichiers à supprimer

Aucun.

### Test attendu

Créer une map avec :

- SurfaceLayer tallGrass ;
- aucune zone de rencontre ;
- déplacement joueur sur tall grass.

Vérifier qu'aucune rencontre n'est déclenchée uniquement par la surface visuelle.

### Commandes

```bash
cd packages/map_gameplay
dart test test/surface_tall_grass_does_not_imply_encounter_test.dart
```

### Critère de fin

Les hautes herbes visuelles ne cassent pas la logique d'encounters.

---

# Phase P12 — Migration Path vers Surface

## Lot P12.01 — Créer `path_to_surface_migration.dart`

### Objectif

Créer un convertisseur pur `ProjectPathPreset` -> `ProjectSurfacePreset`.

### Fichiers à créer

- `packages/map_core/lib/src/operations/path_to_surface_migration.dart`
- `packages/map_core/test/path_to_surface_migration_test.dart`

### Fichiers à modifier

- `packages/map_core/lib/map_core.dart`

### Fichiers à supprimer

Aucun.

### Fonction attendue

```text
convertPathPresetToSurfacePreset
```

Entrées :

- `ProjectPathPreset pathPreset`
- `String surfacePresetId`
- `Map<String, String> animationIdByPathVariantKey` optionnel ou structure équivalente.

Version simple :

- convertir `surfaceKind` vers `SurfaceBehaviorKind` ;
- convertir chaque `PathPresetVariantMapping` en `SurfaceVariantMapping` statique si une seule frame ;
- si plusieurs frames, ne pas créer d'animations dans ce lot, mais retourner un résultat avec warnings.

### Modèle de résultat

Créer une classe simple :

- `PathToSurfacePresetMigrationResult`
- `ProjectSurfacePreset preset`
- `List<String> warnings`

### Tests attendus

- path statique -> surface preset ;
- path animé -> warning ;
- surfaceKind water -> behaviorKind water ;
- tallGrass -> tallGrass.

### Commandes

```bash
cd packages/map_core
dart test test/path_to_surface_migration_test.dart
```

### Critère de fin

On a une base de migration sans perte silencieuse.

---

## Lot P12.02 — Créer un rapport de migration Path -> Surface

### Objectif

Lister ce qui serait migrable dans un projet sans modifier le projet.

### Fichiers à créer

- `packages/map_editor/lib/src/application/use_cases/surface_migration_report_use_case.dart`
- `packages/map_editor/test/surface_migration_report_use_case_test.dart`

### Fichiers à supprimer

Aucun.

### Classe attendue

`BuildSurfaceMigrationReportUseCase`

Sortie :

- nombre de path presets ;
- nombre statiques migrables directement ;
- nombre animés nécessitant animation Surface ;
- liste warnings par preset ;
- nombre de PathLayer à migrer plus tard.

### Tests attendus

- projet sans paths ;
- projet avec path statique ;
- projet avec path animé ;
- warnings lisibles.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_migration_report_use_case_test.dart
```

### Critère de fin

On peut auditer avant de migrer.

---

## Lot P12.03 — Créer migration projet non destructive

### Objectif

Ajouter les SurfacePresets issus de PathPresets sans supprimer les PathPresets.

### Fichiers à créer ou modifier

- `packages/map_editor/lib/src/application/use_cases/surface_migration_use_case.dart`
- `packages/map_editor/test/surface_migration_use_case_test.dart`

### Fichiers à supprimer

Aucun.

### Classe attendue

`MigratePathPresetsToSurfacePresetsUseCase`

Règles :

- ne jamais supprimer `pathPresets` ;
- créer de nouveaux `surfacePresets` ;
- éviter les doublons si migration déjà faite ;
- produire un rapport ;
- save project seulement si `dryRun = false` ;
- `dryRun = true` par défaut recommandé.

### Tests attendus

- dry run ne sauvegarde pas ;
- migration sauvegarde ;
- migration répétée ne double pas ;
- path animé produit warning mais ne ment pas.

### Commandes

```bash
cd packages/map_editor
flutter test test/surface_migration_use_case_test.dart
```

### Critère de fin

La migration commence sans casser l'ancien système.

---

# Phase P13 — Optimisation runtime

## Lot P13.01 — Mesurer le nombre de cellules Surface animées

### Objectif

Créer un outil de mesure simple pour éviter le rendu bourrin.

### Fichiers à créer

- `packages/map_runtime/lib/src/presentation/flame/runtime_surface_render_stats.dart`
- `packages/map_runtime/test/runtime_surface_render_stats_test.dart`

### Fichiers à supprimer

Aucun.

### Classe attendue

`RuntimeSurfaceRenderStats`

Champs :

- `totalSurfaceCells`
- `animatedSurfaceCells`
- `staticSurfaceCells`
- `missingVariantCells`

### Tests attendus

- compteur vide ;
- addition stats ;
- format debug lisible.

### Commandes

```bash
cd packages/map_runtime
flutter test test/runtime_surface_render_stats_test.dart
```

### Critère de fin

On peut savoir si une map est coûteuse à rendre.

---

## Lot P13.02 — Séparer helpers de résolution et rendu Canvas

### Objectif

Rendre testable le pipeline sans golden test fragile.

### Fichiers à créer

- `packages/map_runtime/lib/src/presentation/flame/runtime_surface_cell_resolver.dart`
- `packages/map_runtime/test/runtime_surface_cell_resolver_test.dart`

### Fichiers à modifier

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

### Fichiers à supprimer

Aucun.

### Classe attendue

`RuntimeSurfaceCellResolver`

Entrées :

- catalog ;
- clock ;
- mapSize ;
- layer ;

Sortie par cellule :

- `RuntimeSurfaceResolvedFrame?`

### Tests attendus

- cellule false -> null ;
- cellule true + variant mapped -> frame ;
- variant missing -> null ;
- stats incrementables si branché.

### Commandes

```bash
cd packages/map_runtime
flutter test test/runtime_surface_cell_resolver_test.dart
```

### Critère de fin

Le rendu Canvas devient plus simple et moins risqué.

---

## Lot P13.03 — Ajouter culling caméra pour SurfaceLayer

### Objectif

Ne pas parcourir toute la map si seulement une partie est visible.

### Fichiers à modifier

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

### Fichiers à créer ou modifier

- `packages/map_runtime/test/map_layers_component_surface_culling_test.dart`

### Fichiers à supprimer

Aucun.

### Comportement attendu

Si le rendu existant a déjà une logique de culling pour tiles, la réutiliser.

Sinon, ajouter un helper pur qui calcule :

- first visible column ;
- last visible column ;
- first visible row ;
- last visible row.

Pour ce lot, le helper peut être testé sans canvas.

### Tests attendus

- viewport plus petit que map ;
- viewport hors origine ;
- bornes clampées.

### Commandes

```bash
cd packages/map_runtime
flutter test test/map_layers_component_surface_culling_test.dart
```

### Critère de fin

Les grandes maps ne deviennent pas absurdes à animer.

---

# Phase P14 — Nettoyage et documentation

## Lot P14.01 — Documenter le format `Animated Tile Atlas`

### Objectif

Créer la doc utilisateur/dev du format d'image attendu.

### Fichiers à créer

- `docs/surface_engine/animated_tile_atlas_format.md`

### Fichiers à modifier

Aucun.

### Fichiers à supprimer

Aucun.

### Contenu attendu

Expliquer :

- colonnes = variantes ;
- lignes = frames ;
- tileWidth/tileHeight ;
- couleur de transparence ;
- syncGroup ;
- durées ;
- exemple eau ;
- exemple hautes herbes ;
- pourquoi Tiled n'est pas requis.

### Tests à lancer

Aucun.

### Critère de fin

Un dev peut créer un atlas sans relire cette conversation.

---

## Lot P14.02 — Documenter le workflow Surface Studio

### Objectif

Créer une doc no-code utilisateur.

### Fichiers à créer

- `docs/surface_engine/surface_studio_workflow.md`

### Fichiers à modifier

Aucun.

### Fichiers à supprimer

Aucun.

### Contenu attendu

Workflow :

1. importer/ajouter tileset ;
2. créer Surface Atlas ;
3. générer animations ;
4. créer Surface Preset ;
5. vérifier coverage ;
6. créer SurfaceLayer ;
7. peindre la map ;
8. tester runtime.

### Tests à lancer

Aucun.

### Critère de fin

Une personne non développeuse peut comprendre le principe.

---

## Lot P14.03 — Ajouter un rapport final de couverture Surface Engine

### Objectif

Savoir honnêtement ce qui est fait et pas fait.

### Fichiers à créer

- `reports/surface_engine/final_surface_engine_coverage.md`

### Fichiers à modifier

Aucun.

### Fichiers à supprimer

Aucun.

### Contenu attendu

Sections :

- modèles core faits ;
- validations faites ;
- UI faite ;
- runtime fait ;
- eau V1 faite ;
- hautes herbes V1 faite ;
- migrations faites ;
- limites restantes ;
- dette connue ;
- tests lancés ;
- recommandations prochaine phase.

### Tests à lancer

Aucun.

### Critère de fin

Yoahn sait exactement où en est le chantier.

---

# 4. Ordre recommandé ultra court

Si l'objectif est d'avancer sans se noyer, l'ordre minimal est :

```text
P0.01
P0.02
P1.01 → P1.11
P2.01 → P2.07
P3.01 → P3.07
P4.01 → P4.10
P5.01 → P5.10
P6.01 → P6.08
P7.01 → P7.07
P8.01 → P8.05
P9.01 → P9.04
P10.01 → P10.05
P11.01 → P11.04
P12.01 → P12.03
P13.01 → P13.03
P14.01 → P14.03
```

Mais dans la vraie vie, je recommande ce sous-ensemble d'abord :

```text
P1.01
P1.02
P1.03
P1.04
P1.06
P1.09
P1.10
P2.01
P2.04
P2.05
P2.06
P3.01
P3.03
P3.04
P3.06
P4.03
P4.06
P4.08
P6.01
P6.02
P6.03
P6.04
P6.06
```

Ce sous-ensemble donne déjà :

- modèles d'atlas ;
- modèles d'animation ;
- modèles de preset ;
- validation ;
- génération depuis atlas vertical ;
- resolver runtime ;
- pas encore de grosse UI ;
- pas encore de SurfaceLayer ;
- donc risque beaucoup plus faible.

---

# 5. Prompt type à donner à un agent pour un lot

```text
Tu travailles dans le repo local :
/Users/karim/Project/pokemonProject

Tu dois exécuter uniquement le lot <ID DU LOT> de la roadmap Surface Engine.

Règles non négociables :
- aucun commit Git ;
- aucune commande Git d'écriture ;
- seules commandes Git autorisées : status/diff/log/branch en lecture ;
- commencer par un audit initial ;
- modifier uniquement les fichiers listés par le lot ;
- si un fichier supplémentaire est nécessaire, l'expliquer avant ou dans le rapport ;
- ne pas rendre Tiled obligatoire ;
- ne pas supprimer ProjectPathPreset, PathLayer ou RuntimePathAutotileSet ;
- ne pas refactorer hors périmètre ;
- ajouter/adapter les tests demandés ;
- lancer les tests ciblés ;
- produire un rapport final exhaustif.

Lot à exécuter :
<COLLER LE LOT COMPLET ICI>

Rapport final obligatoire :
1. Résumé exécutif honnête.
2. Fichiers créés.
3. Fichiers modifiés.
4. Fichiers supprimés.
5. Détail exact des changements.
6. Tests lancés avec résultats.
7. Tests non lancés et pourquoi.
8. Écarts au prompt, même petits.
9. Auto-critique finale.
10. Prochain lot recommandé.
```

---

# 6. Pièges à éviter

## 6.1. Le piège du gros refactor héroïque

Ne pas faire :

```text
Je vais supprimer PathLayer et tout remplacer par SurfaceLayer.
```

C'est le genre de phrase qui commence comme une vision produit et finit comme une scène de crime.

## 6.2. Le piège Tiled

Ne pas faire :

```text
On lit directement les TSX au runtime.
```

Le runtime doit lire le modèle PokeMap, pas Tiled.

## 6.3. Le piège gameplay caché

Ne pas faire :

```text
behaviorKind water => surf automatique
behaviorKind tallGrass => encounter automatique
```

Le visuel peut suggérer. Il ne doit pas décider seul.

## 6.4. Le piège animation désynchronisée

Ne pas oublier `syncGroupId`. L'eau doit bouger ensemble. Sinon, on obtient un rendu qui fait plus glitch de fangame de 2007 que moteur propre.

## 6.5. Le piège UI trop ambitieuse trop tôt

Ne pas commencer par un Surface Studio magnifique. D'abord le modèle, les validateurs, les resolvers, puis l'UI. Sinon on fabrique une Tesla avec un moteur de trottinette.

---

# 7. Définition de “done” globale

Le chantier Surface Engine V1 est terminé quand :

1. `ProjectManifest` contient les surfaces.
2. Les anciens projets chargent toujours.
3. Les paths legacy fonctionnent toujours.
4. On peut déclarer un atlas de surface.
5. On peut générer des animations depuis un atlas vertical.
6. On peut créer un preset eau.
7. On peut créer un preset hautes herbes.
8. Le runtime résout les frames selon le temps.
9. Le runtime synchronise les animations via `syncGroupId`.
10. Le runtime rend au moins une surface animée.
11. Le runtime distingue background et foreground overlay.
12. Les hautes herbes peuvent avoir une animation locale au pas.
13. Le gameplay ne confond pas visuel et règles.
14. Un rapport final dit précisément ce qui reste à faire.

---

# 8. Dernière recommandation

La meilleure première vraie tranche n'est pas l'UI. C'est :

```text
ProjectSurfaceAtlas
ProjectSurfaceAnimation
ProjectSurfacePreset
Validation
Vertical atlas generation
Runtime resolver
```

Une fois ça solide, le Surface Studio devient une UI au-dessus d'un vrai moteur. Dans l'autre sens, on aurait juste une belle façade avec des poutres en carton. Et bon, on a déjà assez souffert dans le monde avec Devstral, pas besoin d'infliger ça aux pixels.