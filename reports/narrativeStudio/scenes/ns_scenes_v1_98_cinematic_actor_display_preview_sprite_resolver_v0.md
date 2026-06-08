# NS-SCENES-V1-98 — Cinematic Actor Display Preview Sprite Resolver V0

## 1. Résumé exécutif

Le lot **NS-SCENES-V1-98** a été exécuté avec succès. Il consistait à implémenter le résolveur de sprites acteurs statiques purement symbolique et synchrone pour le Cinematic Builder, conformément aux spécifications cadrées dans le contrat V1-97.

Toutes les contraintes et règles du projet ont été respectées :
- Le résolveur reste 100% synchrone et purement symbolique. Aucun chargement d'image sur le disque, aucun décodage via `dart:ui`, et aucune interaction asynchrone n'ont été introduits.
- Les dimensions des sprites (`frameWidthTiles`, `frameHeightTiles`) sont extraites directement des propriétés `frameWidth` / `frameHeight` de la fiche personnage (`ProjectCharacterEntry`) et non de `TilesetSourceRect`.
- Les diagnostics et fallbacks directionnels de l'animation `idle` ont été implémentés précisément :
  - Si la direction demandée a une animation `idle` avec frames : elle est résolue directement (`spriteReady`).
  - Si l'idle de la direction demandée est manquante mais qu'une autre idle avec frames existe : résolution en `spriteReady` avec le diagnostic `actorDisplayDirectionFallback` (warning).
  - Si aucune idle n'est exploitable (aucune n'a de frames) : retourne `missingIdleAnimation`.
  - Si l'idle demandée existe mais n'a pas de frame : retourne `missingDirectionFrame`.
- Consommation du read model V1-91 pour éviter de dupliquer toute la logique de mapEntity ou Trainer.
- Aucun import Flame, runtime gameplay, ou GameState.
- Aucun code visuel Flutter (pas de RawImage, CustomPainter, ou Widget).
- Le plan de sprites d'acteurs calculé contient toutes les indications de profondeur nécessaires (`depthHint` : `tileX`, `tileY`, `anchorTileX`, `anchorTileY`, `visualBottom`, `footprintWidthTiles`, `footprintHeightTiles`) pour préparer le rendu hybride/depth-aware de la future V1-99.
- 9 tests unitaires robustes couvrent 100% des cas nominaux et d'erreurs, avec une analyse statique Dart/Flutter absolument vierge.

---

## 2. Gate 0

Statut Git initial avant modifications :
```text
On branch main
nothing to commit, working tree clean
```

Fichiers ajoutés ou modifiés :
1. `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart` (Modèles logiques de plan et de profondeur)
2. `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart` (Résolveur synchrone et symbolique)
3. `packages/map_editor/test/cinematic_actor_sprite_preview_resolver_test.dart` (Suite de tests unitaires)

---

## 3. Fichiers modifiés et implémentation

### 3.1. Modèles logiques (`cinematic_actor_sprite_preview_plan.dart`)
Ce fichier définit les structures de données pures pour porter le plan de sprites résolus :
- `CinematicActorSpriteStatus` : Statuts fins de résolution symbolique.
- `CinematicActorSpriteRendererHint` : Indicateur de type de rendu conseillé (overlay / depth-aware / hybride).
- `CinematicActorSpriteDepthHint` : Métadonnées spatiales d'ancrage et de tri de profondeur (Y-sorting).
- `CinematicActorSpriteRef` : Référence logique vers les coordonnées d'atlas du sprite.
- `CinematicActorSpritePreviewActor` : Représentation unitaire d'un acteur résolu.
- `CinematicActorSpritePreviewPlan` : Plan global regroupant la liste des acteurs et les diagnostics.

### 3.2. Résolveur (`cinematic_actor_sprite_preview_resolver.dart`)
Implémente `buildCinematicActorSpritePreviewPlan` :
1. Parcourt les acteurs du read model d'affichage.
2. Identifie si l'acteur est masqué ou non résolu spatialement.
3. Résout le personnage par son `characterId` (y compris pour le joueur par défaut ou le PNJ/Trainer de la mapEntity pré-résolu).
4. Valide le tileset associé.
5. Résout l'animation `idle` par direction en appliquant les fallbacks demandés et en générant les diagnostics appropriés.
6. Calcule les ancres spatiales :
   - `anchorTileX` = `tileX + frameWidthTiles / 2.0` (centré sur la largeur).
   - `anchorTileY` = `tileY + frameHeightTiles.toDouble()` (base de l'acteur).
   - `visualBottom` = `tileY + frameHeightTiles.toDouble()`.
   - `preferredRendererHint` = `CinematicActorSpriteRendererHint.hybridRecommended`.

---

## 4. Tests unitaires et validation

Une suite de 9 tests unitaires a été écrite dans `cinematic_actor_sprite_preview_resolver_test.dart` pour couvrir tous les cas de figure :
1. **Nominal CinematicOnly Actor** : Résolution correcte de la frame idle de face, du tileset, du rectangle source et du depthHint (visualBottom, anchorTileX).
2. **Player default settings character ID** : Résolution correcte de l'apparence du joueur via le `defaultPlayerCharacterId` du manifeste.
3. **Directional Fallback warning** : Résolution correcte d'un sprite orienté Sud avec fallback sur l'animation Nord existante, accompagnée d'un diagnostic warning `actorDisplayDirectionFallback`.
4. **Missing Direction Frame** : Retourne `missingDirectionFrame` si l'animation idle demandée existe mais ne contient aucune frame.
5. **Missing Idle Animation** : Retourne `missingIdleAnimation` si le personnage n'a aucune animation de type idle.
6. **Missing Character** : Retourne `missingCharacter` si le personnage spécifié n'existe pas dans le manifeste.
7. **Missing Tileset** : Retourne `missingTileset` si le tileset spécifié par le personnage n'existe pas dans les tilesets du manifeste.
8. **Invalid Source Rect** : Retourne `invalidSourceRect` si les coordonnées de la frame sont négatives.
9. **Hidden Actor** : Retourne le statut `hidden` sans erreur et avec `placeholderFallback: false`.

Résultats de l'exécution des tests (`flutter test test/cinematic_actor_sprite_preview_resolver_test.dart`) :
```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_actor_sprite_preview_resolver_test.dart
00:00 +0: Cinematic Actor Sprite Preview Resolver resolves cinematic only actor sprite preview plan from character idle frame
00:00 +1: Cinematic Actor Sprite Preview Resolver resolves player actor using settings default character ID
00:00 +2: Cinematic Actor Sprite Preview Resolver resolves direction fallback warning when requested direction idle is missing
00:00 +3: Cinematic Actor Sprite Preview Resolver returns missingDirectionFrame when idle animation for requested direction has no frames
00:00 +4: Cinematic Actor Sprite Preview Resolver returns missingIdleAnimation when character has no idle animations at all
00:00 +5: Cinematic Actor Sprite Preview Resolver returns missingCharacter when character is not found in manifest
00:00 +6: Cinematic Actor Sprite Preview Resolver returns missingTileset when character tileset is not found in manifest
00:00 +7: Cinematic Actor Sprite Preview Resolver returns invalidSourceRect when frame source coordinates are negative
00:00 +8: Cinematic Actor Sprite Preview Resolver resolves hidden actors without generating errors
00:00 +9: All tests passed!
```

---

## 5. Non-régression et analyse statique

Les tests de régression ciblés ont été lancés avec succès :
- `cinematic_builder_workspace_test.dart` (motifs Path Studio et ordre z-index Map Editor V1-96-bis) : **Green**
- `cinematics_library_workspace_test.dart` (22 tests de la bibliothèque cinématique) : **Green**
- `dart test && dart analyze` dans `map_core` : **Green** (Aucun problème trouvé)

Analyse statique sur les nouveaux fichiers dans `map_editor` :
```bash
flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart test/cinematic_actor_sprite_preview_resolver_test.dart
# Résultat : No issues found!
```

---

## 6. Prochain lot recommandé

`NS-SCENES-V1-99 — Cinematic Actor Display Preview Sprite Renderer V0`

Ce lot s'appuiera sur ce résolveur symbolique pour intégrer le rendu concret des sprites dans le widget d'overlay, en conservant le support réactif et les boutons de sélection tout en affichant l'image découpée à la place de la pastille de couleur.
