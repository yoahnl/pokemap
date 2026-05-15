# Collision System Audit V0

## 1. Résumé exécutif

Le système de collision PokeMap n'est pas seulement une grille 32x32 ou tile-level. Le code actuel contient déjà trois niveaux :

- une collision carte historique par cellules (`CollisionLayer.collisions`, `List<bool>`) ;
- une collision d'éléments placés legacy par cellules (`ElementCollisionProfile.cells`) ;
- une collision d'éléments placés pixel-level (`ElementCollisionProfile.collisionMask`, sérialisé en JSON sous `pixelMask`) consommée par `map_gameplay` et affichable en overlay runtime.

Le moteur runtime/gameplay sait déjà consommer une précision plus fine que la tile pour les éléments placés : `GameplayWorldState` décode `collisionMask`, le projette dans un bitmap monde en pixels, puis teste la hitbox joueur 12x8 px contre ce bitmap. L'hypothèse "collision seulement grosse grille" est donc fausse pour les éléments qui possèdent un `pixelMask` valide.

Le problème produit reste réel : l'écosystème est hybride, incomplet et ambigu. Deux flux d'édition coexistent : un éditeur cellule/polygone qui sauve surtout `cells`, et un éditeur triple masque pixel-level qui sauve `collisionMask`/`occlusionMask` et reprojette `cells`. Les tests ciblés montrent aussi une dérive : plusieurs tests de migration legacy échouent, et un test editor ne compile plus. La trajectoire recommandée n'est pas un big bang V2, mais une consolidation progressive de la collision pixel-level existante comme vérité gameplay, avec `cells` maintenu comme projection de compatibilité.

## 2. Verdict court

Verdict : PokeMap possède déjà le noyau technique d'une collision fine, mais le contrat produit n'est pas encore stable.

- Solide : `ElementCollisionPixelMask`, codec `packed_bits_v1`, cache bitmap monde, hitbox joueur pixel, séparation stockage collision/occlusion/visuel.
- Fragile : migration legacy, validation, cohérence entre les deux éditeurs, génération auto documentée comme copie alpha alors que le code applique des heuristiques, absence d'usage runtime de `occlusionMask`.
- Recommandation : faire de `collisionMask` la vérité V2 officielle pour les éléments placés, garder `cells` comme projection legacy, puis améliorer l'UI pixel/no-code et les tests de bâtiment.

## 3. Périmètre audité

Packages inspectés :

- `packages/map_core`
- `packages/map_editor`
- `packages/map_gameplay`
- `packages/map_runtime`

Fichiers obligatoires inspectés :

- `packages/map_core/lib/src/models/element_collision_profile.dart`
- `packages/map_core/lib/src/collision/pixel_rect.dart`
- `packages/map_core/lib/src/collision/player_collision_conventions_v1.dart`
- `packages/map_core/lib/src/operations/element_collision_mask_codec.dart`
- `packages/map_core/lib/src/operations/map_collision.dart`
- `packages/map_core/lib/src/operations/map_entity_collision_footprint.dart`
- `packages/map_core/lib/src/operations/map_placed_elements.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/models/tileset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_editor/lib/src/application/collision_generation/element_visual_occupancy_analyzer.dart`
- `packages/map_editor/lib/src/application/collision_generation/element_visual_occupancy_raster.dart`
- `packages/map_editor/lib/src/application/collision_generation/placed_element_auto_collision_generator.dart`
- `packages/map_editor/lib/src/application/collision_generation/placed_element_collision_params.dart`
- `packages/map_editor/lib/src/application/collision_generation/placed_element_mask_heuristics_v1.dart`
- `packages/map_editor/lib/src/application/services/element_collision_authoring_service.dart`
- `packages/map_editor/lib/src/application/services/element_collision_base_cells_from_padding_service.dart`
- `packages/map_editor/lib/src/application/services/element_collision_cells_overlay_service.dart`
- `packages/map_editor/lib/src/application/services/element_collision_profile_generator.dart`
- `packages/map_editor/lib/src/application/services/element_collision_shape_rasterizer_service.dart`
- `packages/map_editor/lib/src/ui/panels/element_collision_editor_sheet.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_editor.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_profile_painter.dart`
- `packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_gameplay/lib/src/collision/pixel_movement_resolver.dart`
- `packages/map_gameplay/lib/src/movement_block_reason.dart`
- `packages/map_gameplay/lib/src/gameplay_player_state.dart`
- `packages/map_gameplay/lib/src/gameplay_world_state.dart`
- `packages/map_gameplay/lib/src/gameplay_step.dart`
- `packages/map_runtime/lib/src/presentation/flame/player_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`

Fichiers liés mais non audités en profondeur :

- anciens rapports sous `reports/previous/` et `packages/map_editor/reports/` : utilisés seulement comme historique de noms, pas comme source de vérité ;
- code shadow récent sous `packages/map_runtime/lib/src/shadow/` : hors périmètre collision demandé, et déjà présent comme fichiers non suivis avant l'audit ;
- Surface Engine et PathPattern : plusieurs occurrences collision/eau/surface existent, mais ce lot ne devait pas modifier ni concevoir les surfaces.

## 4. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
?? packages/map_runtime/lib/src/shadow/runtime_actor_contact_shadow_collection.dart
?? packages/map_runtime/test/shadow/runtime_actor_contact_shadow_collection_test.dart
?? packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
```

Ces changements existaient avant le rapport. Ils n'ont pas été modifiés par l'audit.

## 5. Commandes exécutées

Inventaire et recherche :

```bash
git status --short --untracked-files=all
rg --files -g 'AGENTS.md' -g '!**/.dart_tool/**' -g '!**/build/**'
rg -n "Collision|collision|ElementCollision|collisionProfile|CollisionProfile|PixelRect|footprint|hitbox|solid|blocked|passable|MovementBlock|mask|raster|padding|polygon|occlusion" packages/map_core packages/map_editor packages/map_gameplay packages/map_runtime -g '!**/.dart_tool/**' -g '!**/build/**' -g '!**/*.g.dart' -g '!**/*.freezed.dart'
find packages -path '*test*' \( -iname '*collision*' -o -iname '*movement*' -o -iname '*placed_element*' -o -iname '*entity*' \) | sort
find reports packages/map_editor/reports -maxdepth 3 -type f \( -iname '*collision*' -o -iname '*runtime*' -o -iname '*occlusion*' \) 2>/dev/null | sort
rg -n "ElementCollisionProfileSource|ElementCollisionMaskEncoding|enum .*Collision|collisionProfile|collisionProfiles" packages/map_core/lib/src/models packages/map_core/lib/src/operations -g '!**/*.g.dart' -g '!**/*.freezed.dart'
rg -n -C 5 "collisionProfile|ElementCollisionProfile|TilesetElement|placedElements|applyCollision|MapPlacedElement" packages/map_core/lib/src/models/tileset.dart packages/map_core/lib/src/models/map_data.dart packages/map_core/lib/src/operations/map_placed_elements.dart -g '!**/*.g.dart' -g '!**/*.freezed.dart'
rg -n -C 4 "collisionProfile|ElementCollisionAuthoringService|shapeCells|manualAddedCells|migrate.*collision|saveProject|loadProject|ProjectManifest.fromJson" packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart packages/map_editor/lib/src -g '!**/*.g.dart' -g '!**/*.freezed.dart'
rg -n "occlusionMask|visualMask|collisionMask|ElementCollisionMaskCodec|showCollisionOverlay|foreground|shouldRenderProjectElementInForeground|RenderPass" packages/map_runtime/lib/src packages/map_runtime/test -g '!**/.dart_tool/**' -g '!**/build/**'
```

Tests et vérifications :

```bash
cd packages/map_core && dart test --reporter compact test/element_collision_mask_codec_test.dart test/element_collision_profile_model_test.dart test/element_collision_profile_pixel_mask_json_test.dart test/map_entity_collision_footprint_test.dart
cd packages/map_editor && flutter test --reporter compact test/element_collision_authoring_service_test.dart test/element_collision_shape_rasterizer_service_test.dart test/project_element_collision_file_repository_roundtrip_test.dart test/project_element_collision_persistence_test.dart test/collision_generation/placed_element_auto_collision_copy_test.dart
cd packages/map_gameplay && dart test --reporter compact test/placed_elements_collision_test.dart test/runtime_movement_collision_regression_test.dart test/npc_default_collision_footprint_test.dart
cd packages/map_runtime && flutter test --reporter compact test/map_layers_component_placed_element_render_test.dart test/movement_feedback_test.dart
cd packages/map_editor && flutter test --reporter expanded test/project_element_collision_persistence_test.dart
cd packages/map_editor && flutter test --reporter expanded test/project_element_collision_file_repository_roundtrip_test.dart
cd packages/map_gameplay && dart test --reporter expanded test/placed_elements_collision_test.dart
cd packages/map_gameplay && flutter pub get
git diff --stat -- packages/map_gameplay/.dart_tool/package_config.json packages/map_gameplay/.dart_tool/package_graph.json
git diff --name-only -- packages/map_gameplay/.dart_tool/package_config.json packages/map_gameplay/.dart_tool/package_graph.json
git show HEAD:packages/map_gameplay/.dart_tool/package_graph.json > packages/map_gameplay/.dart_tool/package_graph.json
git status --short --untracked-files=all
```

Note d'hygiène : `dart test` dans `packages/map_gameplay` a modifié temporairement deux fichiers `.dart_tool` suivis. `flutter pub get` a restauré `package_config.json`; `package_graph.json` a été restauré depuis `HEAD` avec `git show` en lecture seule et redirection fichier. La vérification `git diff --name-only -- packages/map_gameplay/.dart_tool/...` ne renvoyait ensuite plus de sortie.

## 6. Inventaire des fichiers collision

Modèles domaine :

- `ElementCollisionPixelMask` : masque pixel local, `widthPx`, `heightPx`, `encoding`, `dataBase64`.
- `ElementCollisionProfile` : agrège `visualMask`, `collisionMask` JSON `pixelMask`, `occlusionMask`, `padding`, `shapeCells`, `cells`, `manualAddedCells`, `manualRemovedCells`.
- `CollisionLayer` : calque carte `List<bool> collisions`.
- `MapPlacedElement` : instance d'élément placée, avec `elementId`, `pos`, `applyCollision`.
- `MapEntity` : entité map avec `blocksMovement` et propriétés de footprint.
- `PixelRect`, `PixelPoint`, `PixelPosition` : primitives pixels pures.
- `PlayerCollisionConventionsV1` : convention hitbox joueur et projection pieds.

Services collision :

- `ElementCollisionMaskCodec`
- `ElementCollisionBaseCellsFromPaddingService`
- `ElementCollisionCellsOverlayService`
- `ElementCollisionShapeRasterizerService`
- `ElementCollisionAuthoringService`
- `ElementCollisionProfileGenerator`
- `ElementVisualOccupancyAnalyzer`
- `ElementVisualOccupancyRaster`
- `PlacedElementAutoCollisionGenerator`
- `PlacedElementMaskHeuristicsV1`

Widgets collision :

- `element_collision_editor_sheet.dart`
- `element_collision_editor.dart`
- `element_collision_profile_painter.dart`
- `element_collision_triple_mask_editor.dart`

Tests collision identifiés :

- `packages/map_core/test/element_collision_mask_codec_test.dart`
- `packages/map_core/test/element_collision_profile_model_test.dart`
- `packages/map_core/test/element_collision_profile_pixel_mask_json_test.dart`
- `packages/map_core/test/map_entity_collision_footprint_test.dart`
- `packages/map_editor/test/collision_generation/placed_element_auto_collision_copy_test.dart`
- `packages/map_editor/test/element_collision_authoring_service_test.dart`
- `packages/map_editor/test/element_collision_shape_rasterizer_service_test.dart`
- `packages/map_editor/test/project_element_collision_file_repository_roundtrip_test.dart`
- `packages/map_editor/test/project_element_collision_persistence_test.dart`
- `packages/map_gameplay/test/placed_elements_collision_test.dart`
- `packages/map_gameplay/test/runtime_movement_collision_regression_test.dart`
- `packages/map_gameplay/test/npc_default_collision_footprint_test.dart`
- `packages/map_runtime/test/map_layers_component_placed_element_render_test.dart`
- `packages/map_runtime/test/movement_feedback_test.dart`

Flux runtime/gameplay :

- `MapData` + `ProjectManifest` chargés par runtime.
- `GameplayWorldState.fromMap` construit les caches collision.
- `stepGameplayWorld` appelle `PixelMovementResolverV1`.
- `PixelMovementResolverV1` teste une hitbox `PixelRect`.
- `PlayableMapGame` applique le résultat gameplay aux composants Flame.
- `MapLayersComponent` peut peindre un overlay collision de debug.

## 7. Modèle actuel de collision

`ElementCollisionProfile` est le modèle principal pour les éléments de tileset/projet :

- lignes 13-24 : `ElementCollisionPixelMask` stocke taille et payload compact ;
- lignes 30-35 : `visualMask`, `collisionMask` et `occlusionMask` coexistent ;
- ligne 34 : `collisionMask` est sérialisé sous le nom JSON historique `pixelMask` ;
- lignes 36-50 : `padding`, `shapeCells` et `cells` coexistent ;
- lignes 47-50 : `cells` est explicitement documenté comme vérité runtime legacy ;
- lignes 51-61 : `manualAddedCells` et `manualRemovedCells` stockent l'intention auteur.

Réponse aux questions de granularité :

- Collision carte : cellules de carte, `List<bool>`, une valeur par tile.
- Collision legacy d'élément : cellules locales de l'élément, `List<GridPos>`.
- Collision fine d'élément : masque pixel local, `ElementCollisionPixelMask`.
- Polygone : non persisté comme polygone géométrique ; il est rasterisé en `GridPos`.
- Rectangles : utilisés comme primitives pixels (`PixelRect`) et rectangles pleins lors du stamp des cellules dans le bitmap monde.

Peut-on exprimer une collision plus fine que la tile ? Oui, si `collisionMask` est présent. Le masque est pixel-level à la résolution du rectangle source de l'élément. La limite actuelle n'est pas le runtime ; elle est surtout l'outillage auteur, la validation et la migration.

## 8. Sérialisation / persistance

Stockage principal :

- `ProjectManifest.elements[].collisionProfile` dans `packages/map_core/lib/src/models/project_manifest.dart:380`.
- `MapData.placedElements[]` ne duplique pas le profil ; il référence `elementId`, `pos`, `applyCollision`.

Encodage :

- `ElementCollisionMaskEncoding.packedBitsV1` : pixels row-major, origine haut-gauche, 1 bit par pixel, base64.
- `ElementCollisionMaskCodec.encodePackedBits` et `decodePackedBits` assurent l'aller-retour.
- `ElementCollisionMaskCodec.cellsFromPixelMask` projette un masque pixel vers des cellules legacy selon un ratio de pixels solides.

Compatibilité backward :

- `ElementCollisionProfile.fromJson` nettoie les anciens champs `visualMask`, `pixelMask`, `occlusionMask` quand ils ne sont pas des maps.
- Les champs d'authoring absents (`shapeCells`, `manualAddedCells`, `manualRemovedCells`) ont des listes vides par défaut.
- `ElementCollisionTripleMaskEditor` dérive un bitmap depuis `cells` si aucun `collisionMask` valide n'existe.

Invariants existants :

- Le runtime/gameplay ignore `shapeCells`, `manualAddedCells` et `manualRemovedCells`.
- Quand `collisionMask` existe, le gameplay ignore `cells` pour les éléments placés.
- `cells` reste requis pour des outils legacy, des tests et certains overlays/fallbacks.

Absences de validation :

- `ProjectValidator.validate` ne valide pas explicitement la cohérence `collisionMask.widthPx/heightPx` avec les frames.
- Il ne valide pas la cohérence `cells` vs `collisionMask`.
- Il ne signale pas les profils manuels legacy où `manualAddedCells` contient la vraie forme mais `cells` reste plein.

## 9. Flux d'édition dans map_editor

Flux cellule/polygone :

```text
ProjectElementEntry
-> collisionProfile existant ou fallback padding
-> ElementCollisionAuthoringService.describe()
-> base padding OU forme auteur
-> retouches pinceau +/-
-> rasterisation polygone en cellules
-> rebuild()
-> sauvegarde ElementCollisionProfile.cells + champs auteur
```

`ElementCollisionAuthoringService` documente clairement ses responsabilités :

- dériver la base automatique depuis le padding ;
- traiter la forme auteur comme base principale ;
- conserver les retouches locales ;
- reconstruire la vérité finale `profile.cells`.

Flux pixel triple masque :

```text
visual alpha / visualMask
-> collisionMask editable au pinceau/gomme pixel
-> occlusionMask editable au pinceau/gomme pixel
-> ElementCollisionMaskCodec.cellsFromPixelMask()
-> sauvegarde collisionMask + occlusionMask + cells projetés
```

Le triple mask editor déclare explicitement :

- collision = bloque le déplacement ;
- occlusion = peut recouvrir le joueur au rendu, ne bloque pas ;
- si seul `cells` existe, il remplit chaque tile bloquante en pixels ;
- à chaque modification, il réécrit aussi `cells`.

Ambiguïté majeure : ces deux flux ne manipulent pas la même vérité avec la même précision. Le premier reste centré sur `cells`; le second rend `collisionMask` éditable.

## 10. Génération automatique actuelle

Entrée :

- image tileset ;
- rectangle source `TilesetSourceRect` ;
- taille tile ;
- `WarpTriggerPadding` ;
- seuil alpha.

Sortie :

- `visualMask` ;
- `collisionMask` ;
- `occlusionMask` ;
- `padding` ;
- `cells: const []` dans `PlacedElementAutoCollisionGenerator`.

Pipeline réel :

1. `ElementVisualOccupancyAnalyzer` lit l'alpha du rectangle source.
2. Le padding clippe la zone inspectée.
3. `PlacedElementMaskHeuristicsV1.deriveFromVisualOccupancy` dérive collision et occlusion.
4. Les trois masques sont encodés en `packed_bits_v1`.

Seuils et règles :

- `kCollisionAlphaOpaqueThreshold = 24`.
- `occlusionBandTopFraction = 0.38`.
- `shadowBandMaxFraction = 0.22`.
- `shadowDensityRatioVsMaxRow = 0.48`.
- Une ligne basse peu dense peut être classée comme ombre et retirée de la collision.
- L'occlusion auto est une bande haute du bounding box opaque.

Avis critique :

- Bien : séparation explicite visual/collision/occlusion ; masque pixel compact ; ombres basses traitées.
- Fragile : l'heuristique ne comprend pas un bâtiment ; elle lit uniquement des densités de lignes.
- Fragile : `PlacedElementCollisionGenerationParams` indique une copie alpha -> gameplay sans heuristique, alors que le générateur appelle `PlacedElementMaskHeuristicsV1`.
- Limite bâtiment : toit, cheminée, enseigne, porte et ombres intégrées restent difficiles à distinguer automatiquement.
- Limite props : petits objets partiellement transparents peuvent être sur- ou sous-bloquants selon alpha et densité.

## 11. Preview / UI actuelle

UI cellule/polygone :

- `Aperçu` : visualiser la forme finale sauvegardée.
- `Pinceau +` : ajouter des retouches locales.
- `Pinceau -` : retirer des retouches locales.
- `Polygone forme` : fermer un polygone pour remplacer la forme principale.
- `Polygone -` : retirer une zone.
- `Réinitialiser retouches` : supprime les overrides.
- `Utiliser le padding comme base` : repasse en base générée.
- `Vider toute collision` : rend le profil vide.

Texte UI relevé :

```text
Polygone forme: définit la forme principale d’un bâtiment. Pinceau + / -: applique des retouches locales. Le padding auto reste un outil secondaire pour les cas simples. Le runtime continue à lire uniquement `collisionProfile.cells`.
```

Ce texte est partiellement périmé pour les profils qui possèdent `collisionMask`, car `map_gameplay` lit alors le masque pixel.

UI triple masque :

- affiche visual/collision/occlusion ;
- permet peinture collision et occlusion ;
- rappelle que la grille est un repère et que la vérité reste le masque pixel ;
- réécrit `cells` comme projection legacy.

Ambiguïtés UX :

- L'utilisateur peut croire que le polygone reste stocké ; il est rasterisé en cellules.
- La grille du panneau polygone correspond aux cellules locales, pas au masque pixel.
- La hitbox joueur n'est pas intégrée comme outil de test direct dans l'éditeur cellule.
- Occlusion et collision sont séparées dans le modèle, mais l'effet runtime d'occlusion n'est pas branché.
- L'éditeur distingue des notions fines, mais deux écrans différents portent des vérités différentes.

## 12. Consommation runtime / gameplay

`GameplayWorldState` construit trois caches :

- `_tileCollisionCellCache` : calque collision carte, cellule entière.
- `_placedElementCellCollisionCache` : fallback legacy depuis `profile.cells` si aucun `collisionMask`.
- `_pixelCollisionCache` : bitmap monde en pixels, vérité de déplacement.

Construction du bitmap monde :

- les `CollisionLayer.collisions` vrais stampent un rectangle plein de taille tile ;
- les cellules legacy d'éléments placés stampent aussi des tiles pleines ;
- les `collisionMask` des éléments placés sont décodés et stampés pixel par pixel ;
- les entités bloquantes stampent des rectangles pleins par footprint cellulaire.

API de collision fine :

- `GameplayWorldState.worldStaticObstaclesCollidePixelRect(PixelRect rect)` ;
- `PixelMovementResolverV1.resolveSeparateAxis(...)` ;
- `PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(...)`.

Broad phase / narrow phase actuelle :

- Broad phase explicite : pré-stamp en cache bitmap monde, donc coût amorti.
- Narrow phase : test pixel par pixel de la hitbox joueur 12x8 contre `_pixelCollisionCache`.
- Pas de structure spatiale dynamique pour le masque ; le bitmap monde tient lieu d'accélération simple.

Sliding :

- Oui, par résolution séparée des axes : essai complet, puis axe X, puis axe Y.

Diagonales :

- Le resolver accepte `deltaX` et `deltaY`, mais les intentions runtime courantes sont cardinales.

Tunneling :

- Le déplacement teste seulement la position finale du pas. Avec le pas actuel 16 px et une hitbox 12x8, des obstacles très fins peuvent être sautés si un futur input introduit des pas plus grands ou diagonaux rapides.

## 13. Hitbox joueur et conventions

`PlayerCollisionConventionsV1` fixe :

- sprite joueur par défaut : 32x32 px ;
- hitbox déplacement : 12x8 px ;
- hitbox centrée horizontalement ;
- bas de hitbox aligné sur le bas du sprite ;
- projection grille : centre du bord inférieur de la hitbox.

`GameplayPlayerState` porte `playerPositionPx`, `playerSpriteWidthPx` et `playerSpriteHeightPx`.

`PlayerComponent` ne décide pas la collision. Il synchronise visuellement la position gameplay vers Flame :

- `_computeWorldTopLeft` convertit les pixels gameplay en coordonnées Flame ;
- `syncState` et `startStep` synchronisent ou interpolent le sprite ;
- `footPoint` est une aide visuelle/caméra, pas la primitive de collision.

## 14. Collision vs occlusion vs interaction

Séparations claires :

- Collision : `collisionMask` / `cells` / `CollisionLayer` / `blocksMovement`.
- Occlusion : `occlusionMask` dans `ElementCollisionProfile`.
- Visuel : `visualMask`.
- Interaction : `MapPlacedElementBehavior`, triggers on action/enter/bump/near/exit.

Zones ambiguës :

- `occlusionMask` est stocké et édité, mais pas consommé par `MapLayersComponent` pour dessiner le joueur derrière un toit.
- Le foreground runtime repose surtout sur `MapEntityEditorVisual.renderInForeground` pour les entités rendues comme éléments projet, pas sur `occlusionMask`.
- Les interactions des éléments placés restent indexées par cellules / triggers, pas par masque pixel.

Risques bâtiment :

- Un toit peut être visuel/occlusif sans bloquer.
- Une porte peut être interactive sans bloquer tout le rectangle.
- Une cheminée doit rarement bloquer le pied joueur au sol.
- Améliorer seulement la collision peut créer un rendu incohérent si occlusion et interaction ne suivent pas.

## 15. Tests existants

Tests map_core :

- `element_collision_mask_codec_test.dart` : roundtrip packed bits, projection cellules depuis masque.
- `element_collision_profile_model_test.dart` : sérialisation forme/cells et defaults legacy.
- `element_collision_profile_pixel_mask_json_test.dart` : `pixelMask`, `visualMask`, `occlusionMask`, nettoyage legacy.
- `map_entity_collision_footprint_test.dart` : footprints NPC 1x1 et 2x2.

Tests map_editor :

- `element_collision_authoring_service_test.dart` : padding, overrides, rebuild, legacy migration, shape.
- `element_collision_shape_rasterizer_service_test.dart` : polygon rectangle, concave, narrow silhouette, roof-like coarse block.
- `project_element_collision_file_repository_roundtrip_test.dart` : migration repository legacy.
- `project_element_collision_persistence_test.dart` : persistance collision profile.
- `placed_element_auto_collision_copy_test.dart` : génération auto depuis alpha.

Tests map_gameplay :

- `placed_elements_collision_test.dart` : `applyCollision`, `collisionMask`, legacy cells, bâtiments.
- `runtime_movement_collision_regression_test.dart` : collision tile, entity, placed element.
- `npc_default_collision_footprint_test.dart` : footprint NPC gameplay.

Tests map_runtime :

- `map_layers_component_placed_element_render_test.dart` : rendu élément placé.
- `movement_feedback_test.dart` : message surf/blocked.

Résultats exécutés :

- `packages/map_core` ciblé : 11 tests passés dans la sortie compacte.
- `packages/map_runtime` ciblé : `+3: All tests passed!`.
- `packages/map_editor` ciblé : échec `+30 -3`.
- `packages/map_gameplay` ciblé : échec `+13 -2`.

## 16. Limites actuelles

### Limites de modèle

Impact utilisateur : l'auteur ne sait pas quelle vérité prévaut.

Impact technique : `cells`, `collisionMask`, `shapeCells`, `manualAddedCells`, `manualRemovedCells` peuvent diverger.

Risque : profils incohérents entre éditeur, gameplay et tests.

Complexité : moyenne.

Fichiers : `element_collision_profile.dart`, `element_collision_authoring_service.dart`, `element_collision_triple_mask_editor.dart`, `gameplay_world_state.dart`.

### Limites de sérialisation

Impact utilisateur : anciens projets peuvent charger avec une collision trop large.

Impact technique : la migration legacy n'est pas centralisée dans `ProjectManifest.fromJson` ou `FileProjectRepository`.

Risque : bâtiments hérités bloquent leur toit.

Complexité : moyenne.

Fichiers : `file_repositories.dart`, `project_manifest.dart`, `element_collision_profile.dart`.

### Limites UI

Impact utilisateur : le polygone donne une impression de précision mais sort en cellules.

Impact technique : deux éditeurs différents pour la même notion produit.

Risque : retouches longues, résultats imprédictibles.

Complexité : moyenne à élevée.

Fichiers : `element_collision_editor_sheet.dart`, `element_collision_triple_mask_editor.dart`.

### Limites runtime

Impact utilisateur : collision fine présente, mais occlusion fine absente.

Impact technique : les masks ne pilotent pas encore un split foreground/background.

Risque : joueur bloqué correctement mais rendu devant/derrière faux.

Complexité : élevée.

Fichiers : `map_layers_component.dart`, `playable_map_game.dart`.

### Limites performance

Impact utilisateur : peu visible sur petites maps.

Impact technique : `_pixelCollisionCache` est un bitmap monde complet ; très grandes maps et nombreux masks peuvent augmenter mémoire et temps de reconstruction.

Risque : rebuild coûteux lors de changements dynamiques nombreux.

Complexité : moyenne.

Fichiers : `gameplay_world_state.dart`.

### Limites UX/no-code

Impact utilisateur : l'auteur doit comprendre collision/occlusion/cells/masks.

Impact technique : manque d'assistants guidés par cas bâtiment, prop, porte.

Risque : outil trop moteur.

Complexité : élevée.

Fichiers : UI editor collision.

### Limites de tests

Impact utilisateur : régressions non détectées ou tests déjà rouges.

Impact technique : tests migration legacy échouent actuellement.

Risque : roadmap V2 bâtie sur une base non verte.

Complexité : faible à moyenne pour rétablir les tests, élevée pour couvrir tout le flux.

Fichiers : tests listés section 15.

## 17. Bugs ou comportements suspects

### Test editor qui ne compile plus

Commande :

```bash
cd packages/map_editor && flutter test --reporter expanded test/project_element_collision_persistence_test.dart
```

Sortie essentielle :

```text
test/project_element_collision_persistence_test.dart:163:48: Error: Cannot invoke a non-'const' constructor where a const expression is expected.
  return const ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(),
                                               ^^^^^^^^^^^^^^^^^^^^^
test/project_element_collision_persistence_test.dart:163:16: Error: Cannot invoke a non-'const' factory where a const expression is expected.
  return const ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(),
               ^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.
```

Cause observée : le test construit `const ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), ...)` alors que `ProjectSurfaceCatalog()` n'est pas const dans ce contexte.

### Migration repository legacy non appliquée

Commande :

```bash
cd packages/map_editor && flutter test --reporter expanded test/project_element_collision_file_repository_roundtrip_test.dart
```

Sortie essentielle :

```text
Expected: GridPos(x: 0, y: 3)...
Actual: GridPos(x: 0, y: 0)...
test/project_element_collision_file_repository_roundtrip_test.dart 33:7
00:00 +0 -1: Some tests failed.
```

Cause observée : `FileProjectRepository.loadProject` appelle `migrateProjectManifestJson`, puis `ProjectManifest.fromJson`, puis `ProjectValidator.validate`, sans normaliser les profils collision legacy via `ElementCollisionAuthoringService`.

### Tests gameplay legacy bâtiments rouges

Commande :

```bash
cd packages/map_gameplay && dart test --reporter expanded test/placed_elements_collision_test.dart
```

Sortie essentielle :

```text
GameplayWorldState placed element collisions legacy broken manual profile is migrated before gameplay reads placed element cells [E]
Expected: false
  Actual: <true>
test/placed_elements_collision_test.dart 314:7

GameplayWorldState placed element collisions gameplay collision uses the placed element id only [E]
Expected: false
  Actual: <true>
test/placed_elements_collision_test.dart 373:7

00:00 +8 -2: Some tests failed.
```

Cause observée : les fixtures legacy ont `cells` plein rectangle et `manualAddedCells` comme vraie silhouette. `GameplayWorldState` lit `profile.cells` en fallback quand `collisionMask == null`, sans interpréter `manualAddedCells` comme forme réelle.

### Documentation/code drift dans génération auto

`placed_element_collision_params.dart` dit que l'auto-génération copie l'occupation alpha vers le masque gameplay. `placed_element_auto_collision_generator.dart` appelle pourtant `PlacedElementMaskHeuristicsV1`, qui retire des lignes d'ombre et dérive l'occlusion.

## 18. Risques produit

- L'auteur peut dessiner une forme bâtiment et obtenir une collision finale en blocs.
- Un masque pixel peut fonctionner en runtime sans être évident dans l'UI principale.
- Les vieux projets peuvent garder un rectangle bloquant complet.
- La collision peut être bonne alors que l'occlusion est fausse.
- Les tests rouges brouillent la confiance avant une V2.
- Les termes `padding`, `forme finale`, `pixelMask`, `cells`, `occlusion` exposent trop de concepts moteur.

## 19. Options d'amélioration comparées

### Option A - Garder le système actuel mais améliorer l'UI

Améliorations :

- zoom plus fort ;
- preview hitbox joueur ;
- test interactif "marcher contre l'élément" ;
- grille plus lisible ;
- messages d'état "sauvé en cells" vs "sauvé en pixelMask" ;
- validation visuelle avant sauvegarde.

Avantages :

- faible risque ;
- aucune migration majeure ;
- utile pour les auteurs immédiatement.

Limite :

- insuffisant si le flux principal reste en cellules.

### Option B - Polygones persistés

Avantages :

- formes compactes ;
- précision géométrique ;
- édition naturelle pour bâtiments.

Coûts :

- sérialisation et validation plus complexes ;
- runtime doit faire intersection rect/polygone ;
- UX difficile pour non-développeurs ;
- occlusion/interaction nécessitent d'autres polygones ou rôles.

Verdict : utile comme format auteur optionnel, pas comme vérité runtime V2.

### Option C - Fine grid locale

Idée :

- masque local 8x8 px ou 4x4 px par élément.

Avantages :

- plus facile à éditer qu'un pixel exact ;
- données compactes ;
- compatible avec broad/narrow phase ;
- migration simple depuis `cells`.

Limite :

- le repo possède déjà `collisionMask` pixel-level. Ajouter une fine grid distincte créerait un second masque fin.

Verdict : bon choix si l'équipe veut réduire la granularité auteur. Sinon, formaliser `collisionMask` existant est plus direct.

### Option D - Hybride coarse grid + fine mask

Idée :

- broad phase via cellules/tile ;
- narrow phase via masque fin ou pixel mask.

État actuel :

- le runtime fait déjà une variante de cette option en stampant toutes les sources dans `_pixelCollisionCache`.

Recommandation :

- officialiser ce modèle ;
- garder `cells` comme broad/projection legacy ;
- utiliser `collisionMask` comme narrow/source gameplay.

### Option E - Pixel-perfect alpha mask

Avantages :

- précision maximale ;
- déjà proche du `visualMask`.

Limites :

- alpha visuel n'est pas collision gameplay ;
- ombres, décors hauts, cheminées et toits deviennent bloquants si utilisés directement ;
- édition pixel-perfect peut être laborieuse.

Verdict : à réserver comme source automatique initiale, jamais comme vérité non retouchée.

## 20. Architecture cible recommandée

Architecture recommandée : Collision Profile V2 par consolidation, pas remplacement.

Concepts :

- `collisionMask` devient vérité gameplay officielle pour les éléments placés.
- `cells` devient projection de compatibilité et broad-phase/debug legacy.
- `shapeCells` reste une source auteur coarse, pas une primitive runtime.
- `occlusionMask` reste distinct et obtient un lot runtime dédié.
- `visualMask` reste une aide d'analyse/preview.

Noms proposés :

- `ElementCollisionProfileV2` : à éviter au début si Freezed/JSON existant peut évoluer sans casse.
- `ElementCollisionRuntimeMask` : meilleur nom pour clarifier le rôle runtime de `collisionMask`.
- `ElementCollisionCompatibilityCells` : nom documentaire, pas nécessaire comme type tout de suite.
- `PlayerFootCollisionBox` : utile si on externalise les constantes joueur ; aujourd'hui `PlayerCollisionConventionsV1` suffit.
- `ElementCollisionAuthoringShape` : utile si on veut persister un polygone auteur plus tard.

Placement :

- modèles purs : `map_core`;
- codecs et projections : `map_core`;
- analyse image : `map_editor` seulement ;
- authoring UI : `map_editor`;
- cache collision et resolver : `map_gameplay`;
- affichage/debug/occlusion runtime : `map_runtime`.

Frontière importante :

- `map_core` ne doit pas dépendre de Flutter/Flame.
- `map_gameplay` ne doit pas dépendre des images.
- `map_runtime` ne doit pas réinventer la collision gameplay.

## 21. Stratégie de compatibilité V1 -> V2

Règles de lecture :

1. Si `collisionMask` valide existe : utiliser lui pour le gameplay.
2. Sinon, si `cells` existe : projeter chaque cellule en rectangle plein.
3. Si profil legacy manuel avec `shapeCells` vide, `cells` plein et `manualAddedCells` non vide : migrer vers `shapeCells = manualAddedCells`, `cells = manualAddedCells`, overrides vides.
4. Si rien n'existe : pas de collision d'élément.

Règles d'écriture :

1. Sauver `collisionMask` pour toute édition pixel.
2. Sauver `cells` comme projection de compatibilité.
3. Ne jamais recalculer `cells` depuis `visualMask` sans action auteur.
4. Ne pas mélanger `occlusionMask` avec blocage déplacement.

Règles de migration :

- migration pure dans `map_core` ou adaptateur explicite appelé par editor/runtime ;
- tests de roundtrip JSON ;
- aucun `build_runner` avant le lot dédié ;
- aucun changement de manifest tant que la décision V2 n'est pas validée.

## 22. Roadmap courte recommandée

### Collision-2 - Decision report précision source-of-truth

Objectif : trancher officiellement `collisionMask` comme vérité gameplay.

Fichiers probables : rapports seulement.

Interdits : modèle persistant, runtime, editor.

Tests : aucun nouveau test.

Risque : faible.

Critère d'acceptation : décision écrite, termes produit validés.

### Collision-3 - Tests rouges legacy et contrat migration

Objectif : isoler les tests rouges actuels et choisir correction test vs correction migration.

Fichiers probables : tests map_editor/map_gameplay, adaptateur pur si approuvé.

Interdits : refonte UI.

Tests : les trois tests rouges de ce rapport.

Risque : moyen.

Critère : résultat vert ou décision explicite de supprimer les attentes obsolètes.

### Collision-4 - Normaliseur pur de profil collision

Objectif : créer une fonction pure pour normaliser les profils legacy sans image.

Fichiers probables : `map_core` operations.

Interdits : Flutter, Flame, image decoding.

Tests : JSON legacy broken manual profile, cells plein, manualAdded vraie forme.

Risque : moyen.

Critère : même profil normalisé dans editor et gameplay.

### Collision-5 - UI truth labels

Objectif : rendre visible "truth = pixelMask" vs "truth = cells".

Fichiers probables : widgets collision editor.

Interdits : runtime.

Tests : widget/service selon patterns existants.

Risque : faible.

Critère : auteur comprend ce qui sera sauvegardé.

### Collision-6 - Preview hitbox joueur dans l'éditeur

Objectif : superposer la hitbox 12x8 et simuler un contact simple.

Fichiers probables : painter/editor sheet/triple mask editor.

Interdits : nouvelle physique.

Tests : service pur de projection, golden si disponible.

Risque : moyen.

Critère : preview montre où le pied joueur bloque.

### Collision-7 - Golden bâtiment runtime

Objectif : fixture bâtiment 5x6/6x7 avec toit passable et base bloquante.

Fichiers probables : tests map_gameplay/map_runtime.

Interdits : assets massifs non justifiés.

Tests : collisionMask, movement, overlay debug.

Risque : moyen.

Critère : roof passable, body bloquant, overlay correspond.

### Collision-8 - Auto-generation calibration

Objectif : clarifier copie alpha vs heuristiques et ajouter cas ombre/toit.

Fichiers probables : collision_generation tests/services.

Interdits : ML, dépendance Tiled.

Tests : alpha threshold, shadow rows, occlusion band.

Risque : moyen.

Critère : docs, tests et comportement alignés.

## 23. Roadmap complète recommandée

1. Collision-2 - Decision report précision source-of-truth.
2. Collision-3 - Tests rouges legacy et contrat migration.
3. Collision-4 - Normaliseur pur de profil collision.
4. Collision-5 - Projection `collisionMask -> cells` standardisée.
5. Collision-6 - Validation dimensions mask/frame/source.
6. Collision-7 - UI truth labels et état de sauvegarde.
7. Collision-8 - Preview hitbox joueur.
8. Collision-9 - Test interactif local déplacement contre élément.
9. Collision-10 - Golden bâtiment gameplay.
10. Collision-11 - Overlay runtime collision pixel/cells comparé.
11. Collision-12 - Auto-generation calibration alpha/ombre.
12. Collision-13 - Occlusion runtime decision report.
13. Collision-14 - Occlusion foreground prototype sans casser collision.
14. Collision-15 - Interaction zones bâtiment/porte séparées de collision.
15. Collision-16 - Performance audit grandes maps / rebuild cache.

## 24. Tests à ajouter

map_core :

- normalisation profil legacy manuel ;
- validation mask dimensions vs source rect ;
- projection mask -> cells avec seuils documentés ;
- absence de confusion `visualMask`/`collisionMask`/`occlusionMask`.

map_editor :

- génération auto bâtiment avec ombre intégrée ;
- triple mask editor réécrit `cells` depuis `collisionMask` ;
- UI service expose vérité active ;
- persistance sans constructeur const obsolète.

map_gameplay :

- `collisionMask` ignore `cells` contradictoires ;
- fallback cells legacy seulement sans `collisionMask` ;
- bâtiment roof/body à coordonnées monde ;
- pas rapide contre obstacle fin.

map_runtime :

- overlay debug pixel mask ;
- absence d'usage `occlusionMask` pour collision ;
- futur test occlusion foreground quand branché.

## 25. Questions ouvertes

- Le produit veut-il exposer un éditeur pixel exact ou une fine grid plus simple ?
- `cellsFromPixelMask` doit-il utiliser un seuil fixe ou paramétrable par profil ?
- Faut-il persister des polygones auteur en plus du masque runtime ?
- `occlusionMask` doit-il piloter un split de rendu dans Flame ou rester une donnée préparatoire ?
- Les interactions de porte doivent-elles devenir des zones fines ou rester cell-based ?
- Les tests legacy rouges représentent-ils un bug à corriger ou un contrat ancien à retirer ?

## 26. Recommandation finale

Recommandation : ne pas créer une V2 persistante nouvelle au prochain lot. D'abord consolider ce qui existe.

Ordre conseillé :

1. Rendre les tests collision/migration cohérents.
2. Déclarer `collisionMask` vérité gameplay pour éléments placés.
3. Garder `cells` comme projection de compatibilité.
4. Ajouter validation et normalisation pure.
5. Améliorer l'éditeur autour de la preview hitbox et du masque actif.
6. Traiter l'occlusion dans un lot séparé.

Cette trajectoire résout le cas bâtiment sans casser les assets existants ni imposer des polygones JSON à l'utilisateur.

## 27. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale vérifiée après création du rapport :

```text
?? reports/collision/collision_system_audit_v0.md
```

Inventaire des fichiers :

- Créé : `reports/collision/collision_system_audit_v0.md`.
- Modifié par l'audit et conservé modifié : None.
- Supprimé : None.
- Généré/touché temporairement puis restauré : `packages/map_gameplay/.dart_tool/package_config.json`, `packages/map_gameplay/.dart_tool/package_graph.json`.
- Toujours non suivi et préexistant en status final : None.
- Toujours modifié et préexistant en status final : None.
- Différence observée : le status initial listait une modification runtime et trois fichiers shadow non suivis ; le status final ne les liste plus. Aucune commande de l'audit n'a ciblé ces chemins.

## 28. Auto-review finale

Checklist :

- Ai-je modifié uniquement le rapport autorisé ? Finalement oui pour le diff conservé ; deux fichiers `.dart_tool` ont été touchés temporairement par les tests puis restaurés.
- Ai-je évité toute implémentation ? Oui.
- Ai-je inspecté map_core, map_editor, map_gameplay et map_runtime ? Oui.
- Ai-je identifié le modèle actuel ? Oui : hybride cells + pixel masks.
- Ai-je identifié le flux auteur ? Oui : flux cellule/polygone et flux triple masque.
- Ai-je identifié le flux runtime ? Oui : cache bitmap monde + hitbox 12x8.
- Ai-je proposé plusieurs options ? Oui : A à E.
- Ai-je proposé une roadmap concrète ? Oui : courte et complète.
- Ai-je signalé les zones non vérifiées ? Oui ci-dessous.
- Ai-je conservé un git status initial et final ? Oui.

Zones non vérifiées :

```text
Non vérifié.
Sujet : analyse complète de tous les anciens rapports collision.
Raison : le lot demandait un audit du code réel actuel ; les rapports anciens sont nombreux et peuvent contenir des décisions dépassées.
Impact : certaines décisions historiques de nommage peuvent manquer.
Comment vérifier au prochain lot : audit ciblé des rapports `reports/previous/*collision*` et `packages/map_editor/reports/*collision*`.
```

```text
Non vérifié.
Sujet : performance mesurée sur très grande map.
Raison : aucun benchmark n'a été lancé.
Impact : l'analyse performance reste qualitative.
Comment vérifier au prochain lot : créer un benchmark de reconstruction `_pixelCollisionCache` avec N éléments placés et map large.
```

```text
Non vérifié.
Sujet : rendu réel d'occlusion depuis `occlusionMask`.
Raison : la recherche runtime n'a trouvé aucun usage direct de `occlusionMask`; aucun prototype visuel n'a été exécuté.
Impact : le risque occlusion bâtiment reste ouvert.
Comment vérifier au prochain lot : test runtime dédié qui place un joueur derrière un bâtiment avec `occlusionMask`.
```

Critique du prompt :

- Le prompt partait d'une hypothèse de collision trop grosse. Le code actuel montre déjà une collision pixel-level en runtime. La question utile devient donc : comment rendre cette capacité stable, visible et migrée ?
- Le périmètre est large pour un seul rapport. Context-mode a permis de garder les sorties longues hors conversation, mais une suite de rapports plus courts serait plus facile à maintenir.
- Les tests ciblés ont révélé de vraies dettes ; le prochain lot doit les traiter avant toute nouvelle architecture persistante.
