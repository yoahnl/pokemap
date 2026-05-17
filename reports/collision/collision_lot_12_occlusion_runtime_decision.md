# Collision Lot 12 — Occlusion Runtime Decision Report V0

## 1. Résumé exécutif

Collision-12 est un lot de décision uniquement. Aucun code runtime, gameplay, editor, core ou generated n'a été modifié.

Décision principale :

```text
occlusionMask doit rester une donnée de rendu uniquement.
Il ne doit jamais entrer dans GameplayWorldState, PixelMovementResolver,
collisionMask, cells ou les règles de blocage.
```

Recommandation V0 :

```text
Créer une passe runtime d'occlusion statique par éléments placés,
basée sur des composants Flame dédiés, triés par profondeur avec les acteurs.
La base de l'élément reste rendue comme aujourd'hui par MapLayersComponent.
Le patch occlusionMask est redessiné au-dessus des acteurs seulement via le
système de priorité visuelle, sans toucher à la collision.
```

Constat important :

```text
PlacedElementOcclusionPatchComponent existe déjà et encode presque la bonne idée,
mais il n'est pas monté par PlayableMapGame et il prend une ui.Image brute alors
que le runtime charge des RuntimeTilesetImage chunkées. Il doit donc être adapté
ou remplacé par un composant équivalent qui consomme RuntimeTilesetImage.
```

Tests non lancés :

```md
Non vérifié.

**Sujet :**
Suites de tests runtime/editor/gameplay.

**Raison :**
Collision-12 est report-only et n'applique aucune modification de code.

**Impact :**
Le rapport ne prétend pas valider un nouveau comportement exécutable.

**Comment vérifier dans Collision-13 :**
Ajouter les tests de résolution/montage d'occlusion recommandés en section 20,
puis lancer les commandes ciblées `flutter test` du package `map_runtime`.
```

## 2. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte au début de Collision-12 :

```text
```

Interprétation : le worktree Collision était propre au début du lot.

Le lot a été exécuté dans le worktree actif des lots Collision précédents :

```text
/Users/karim/.config/superpowers/worktrees/pokemonProject/collision-source-of-truth-worktree
```

Raison : le checkout principal `/Users/karim/Project/pokemonProject` ne contenait pas l'historique local Collision 3 à 11 au moment du lot précédent.

## 3. Rapports précédents relus

Rapports relus :

```text
reports/collision/collision_lot_8_ui_truth_labels.md
reports/collision/collision_lot_9_player_foot_hitbox_preview.md
reports/collision/collision_lot_10_building_golden_slice.md
reports/collision/collision_lot_10bis_fine_collision_mask_authoring_ui.md
reports/collision/collision_lot_11_auto_generation_heuristics_alignment.md
```

Décisions reprises :

- Collision-8 : `collisionMask` est affiché comme `Collision fine active`, `cells` comme `Collision par grille`, `visualMask` comme aperçu/analyse, `occlusionMask` comme rendu devant/derrière non bloquant.
- Collision-9 : la hitbox joueur affichée côté editor est la zone de pieds `12 × 8 px`, pas tout le sprite.
- Collision-10 : la golden slice bâtiment prouve data, normalisation, persistence, gameplay et read-model UI, mais pas le rendu Flame devant/derrière.
- Collision-10-bis : le mode `Masque fin` permet d'éditer `collisionMask`, `visualMask` et `occlusionMask`, et la sauvegarde préserve ces masks.
- Collision-11 : la génération automatique produit `visualMask`, `collisionMask`, `occlusionMask`, et projette `cells` depuis `collisionMask`; elle ne branche pas l'occlusion runtime.

Conclusion reprise :

```text
visualMask = analyse/aperçu.
collisionMask = vérité gameplay fine.
cells = projection/fallback/debug.
occlusionMask = donnée de rendu, non bloquante.
```

## 4. Périmètre et non-objectifs

Périmètre exécuté :

```text
Audit lecture seule.
Création du rapport Markdown Collision-12.
```

Non-objectifs respectés :

```text
Aucune implémentation runtime.
Aucune modification de MapLayersComponent.
Aucune modification de PlayableMapGame.
Aucune modification de RuntimeMapGame.
Aucune modification de PlayerComponent.
Aucune modification de OverworldActorComponent.
Aucune modification de PlacedElementOcclusionPatchComponent.
Aucune modification de ElementCollisionProfile.
Aucune modification de ProjectManifest.
Aucune modification de FileProjectRepository.
Aucune modification de GameplayWorldState.
Aucune modification de la génération auto.
Aucune modification de la sheet collision.
Aucun build_runner.
Aucun fichier generated.
```

Commandes lancées :

```bash
git status --short --untracked-files=all
sed -n '1,220p' reports/collision/collision_lot_8_ui_truth_labels.md
sed -n '1,240p' reports/collision/collision_lot_9_player_foot_hitbox_preview.md
sed -n '1,260p' reports/collision/collision_lot_10_building_golden_slice.md
sed -n '1,280p' reports/collision/collision_lot_10bis_fine_collision_mask_authoring_ui.md
sed -n '1,300p' reports/collision/collision_lot_11_auto_generation_heuristics_alignment.md
rg -n "occlusionMask|visualMask|collisionMask|ElementCollisionProfile|MapPlacedElement|ProjectElementEntry|PlacedElementOcclusion|Occlusion|occlusion|foreground|background|renderPass|depthSort|depth|zOrder|zIndex|PlayerComponent|OverworldActorComponent|MapLayersComponent|drawImageRect|drawAtlas|canvas.draw|renderInForeground|shouldRenderProjectElementInForeground" packages/map_core packages/map_editor packages/map_runtime packages/map_gameplay
sed -n '1,220p' packages/map_core/lib/src/models/element_collision_profile.dart
sed -n '1,240p' packages/map_core/lib/src/operations/element_collision_mask_codec.dart
sed -n '1,620p' packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart
sed -n '1,180p' packages/map_editor/lib/src/application/models/element_collision_truth_summary.dart
sed -n '1,260p' packages/map_editor/lib/src/application/collision_generation/placed_element_auto_collision_generator.dart
sed -n '1,320p' packages/map_editor/lib/src/application/collision_generation/placed_element_mask_heuristics_v1.dart
sed -n '1,320p' packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
sed -n '1,710p' packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
sed -n '1010,1085p' packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
sed -n '6460,6555p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '6555,7665p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '1600,1632p' packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
sed -n '1,260p' packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
sed -n '1,280p' packages/map_runtime/lib/src/presentation/flame/player_component.dart
sed -n '1,320p' packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/runtime_map_bundle.dart
sed -n '940,1125p' packages/map_gameplay/lib/src/gameplay_world_state.dart
rg -n "PlacedElementOcclusionPatchComponent|occlusionMask|foregroundLayers|MapLayerRenderPass|_mountLoadedMap|priority = 100000|priority = 1000" packages/map_runtime/test packages/map_runtime/lib/src/presentation/flame packages/map_runtime/lib/src/application
ls packages/map_runtime/test | sed -n '1,220p'
sed -n '1,220p' packages/map_runtime/test/map_layers_component_placed_element_render_test.dart
sed -n '1,120p' packages/map_runtime/test/map_layers_component_render_pass_test.dart
sed -n '1,220p' packages/map_runtime/test/load_runtime_map_bundle_collision_normalization_test.dart
sed -n '1,220p' packages/map_runtime/test/shadow/runtime_actor_contact_shadow_host_integration_test.dart
sed -n '1,180p' packages/map_runtime/lib/map_runtime.dart
rg -n "placed_element_occlusion_patch_component|PlacedElementOcclusionPatchComponent" packages/map_runtime/lib/map_runtime.dart packages/map_runtime/lib/src packages/map_runtime/test
rg -n "normalizeElementCollisionProfile|collisionMask|occlusionMask|loadProjectManifestFromFile|ProjectValidator.validate" packages/map_runtime/test packages/map_runtime/lib/src/application packages/map_runtime/lib/src/presentation/flame
git log --oneline -5
sed -n '95,210p' packages/map_core/lib/src/models/map_data.dart
sed -n '320,420p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '527,545p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '450,465p' packages/map_core/lib/src/models/enums.dart
git diff --name-only
git diff --stat
git status --short --untracked-files=all
wc -l reports/collision/collision_lot_12_occlusion_runtime_decision.md
sed -n '1,80p' reports/collision/collision_lot_12_occlusion_runtime_decision.md
rg -n "<motifs interdits du prompt>" reports/collision/collision_lot_12_occlusion_runtime_decision.md || true
rg -n "^## " reports/collision/collision_lot_12_occlusion_runtime_decision.md
```

## 5. Audit du modèle occlusion actuel

Fichiers inspectés :

```text
packages/map_core/lib/src/models/element_collision_profile.dart
packages/map_core/lib/src/operations/element_collision_mask_codec.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/enums.dart
```

Constats :

- `ElementCollisionPixelMask` stocke `widthPx`, `heightPx`, `encoding`, `dataBase64`.
- `ElementCollisionProfile.visualMask` existe comme masque séparé.
- `ElementCollisionProfile.collisionMask` existe et reste sérialisé sous la clé JSON historique `pixelMask`.
- `ElementCollisionProfile.occlusionMask` existe comme masque séparé.
- `ElementCollisionProfile.cells` reste une liste de `GridPos`.
- `ElementCollisionMaskCodec` encode/décode `packed_bits_v1` et projette un pixel mask en `cells` avec `cellsFromPixelMask(...)`.
- `ProjectElementEntry` porte le `collisionProfile`.
- `MapPlacedElement` référence seulement `elementId`, `layerId`, `pos`, `applyCollision`, `opacity`, `animation`, `shadowOverride`, `behaviors`, `properties`.
- `MapPlacedElementAnimationMode` supporte `none`, `loop`, `pingPong`.

Conclusion :

```text
Le modèle a déjà la donnée nécessaire.
Aucun changement de schema n'est nécessaire pour une V0 runtime.
```

## 6. Audit de l’édition occlusion

Fichiers inspectés :

```text
packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart
packages/map_editor/lib/src/application/models/element_collision_truth_summary.dart
```

Classes et fonctions importantes :

- `ElementCollisionTripleMaskEditor`
- `MaskSurfaceMode.preview`
- `MaskSurfaceMode.collisionPaint`
- `MaskSurfaceMode.occlusionPaint`
- `_emitProfile()`
- `summarizeElementCollisionTruth(...)`

Constats :

- Le triple mask editor expose les modes `Aperçu`, `Peindre collision`, `Peindre occlusion`.
- `_emitProfile()` construit un `ElementCollisionProfile` avec `visualMask`, `collisionMask`, `occlusionMask`.
- `_emitProfile()` reprojette `cells` depuis `collisionMask` via `ElementCollisionMaskCodec.cellsFromPixelMask(...)`.
- Le texte UI indique : `Masque occlusion : rendu devant/derrière, ne bloque pas`.
- `summarizeElementCollisionTruth(...)` ajoute une note : `Masque d’occlusion disponible : il sert au rendu devant/derrière et ne bloque pas le joueur.`

Conclusion :

```text
Côté authoring, occlusionMask est éditable et correctement présenté comme non bloquant.
Collision-12 ne recommande aucun changement editor pour la V0 runtime.
```

## 7. Audit de la génération occlusion

Fichiers inspectés :

```text
packages/map_editor/lib/src/application/collision_generation/placed_element_auto_collision_generator.dart
packages/map_editor/lib/src/application/collision_generation/placed_element_mask_heuristics_v1.dart
```

Classes et fonctions importantes :

- `PlacedElementAutoCollisionGenerator.generate(...)`
- `PlacedElementMaskHeuristicsV1.deriveFromVisualOccupancy(...)`
- `MaskTriple.collision`
- `MaskTriple.occlusion`

Constats :

- Le générateur produit `visualMask`, `collisionMask`, `occlusionMask`.
- `visualMask` vient de l'occupation visuelle alpha après padding et seuil.
- `collisionMask` vient des heuristiques.
- `occlusionMask` vient d'une bande haute du bbox visuel.
- Les lignes d'ombre basses peuvent être retirées de `collisionMask`.
- `cells` est projeté depuis `collisionMask`.
- `occlusionMask` n'est pas injecté dans `cells`.

Conclusion :

```text
La génération auto est alignée avec le contrat.
Le runtime peut consommer occlusionMask sans rouvrir la génération.
```

## 8. Audit du rendu runtime actuel

Fichiers inspectés :

```text
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_map_bundle.dart
packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart
```

Classes et fonctions importantes :

- `MapLayersComponent`
- `MapLayerRenderPass.background`
- `MapLayerRenderPass.foreground`
- `MapLayersComponent.render(...)`
- `_paintPlacedElementsForLayer(...)`
- `_paintPlacedElementsCollisionOverlay(...)`
- `PlayableMapGame._mountLoadedMap(...)`
- `PlayableMapGame._repositionLoadedMap(...)`
- `PlayableMapGame._unmountLoadedMap(...)`
- `RuntimeMapGame.onLoad()`
- `PlacedElementOcclusionPatchComponent`
- `RuntimeTilesetImage.drawImageRect(...)`

Constats sur `MapLayersComponent` :

- Le composant rend une passe background par défaut.
- La passe foreground existe avec `MapLayerRenderPass.foreground`.
- La passe foreground est utilisée pour les layers explicitement marqués foreground, `fg`, `above`, `overlay`, `front`, `roof`, `toit`.
- `_paintPlacedElementsForLayer(...)` dessine les `MapPlacedElement` complets sur leur layer.
- `_paintPlacedElementsForLayer(...)` ne lit pas `occlusionMask`.
- `_paintPlacedElementsCollisionOverlay(...)` lit `collisionMask` seulement pour l'overlay debug collision, avec un commentaire explicite : `masque collision (blocage), pas l'occlusion`.

Constats sur `PlayableMapGame` :

- `_mountLoadedMap(...)` crée deux `MapLayersComponent` par map chargée :
  - background avec `priority = 0`;
  - foreground avec `priority = 100000`.
- Le joueur est ajouté comme `PlayerComponent`.
- Les PNJ sont ajoutés comme `OverworldActorComponent`.
- `_updateActorDepthOrdering()` applique :
  - joueur : `priority = 1000 + _player.footPoint.y.round()`;
  - PNJ : `priority = 1000 + actor.depthSortY.round()`.
- `_repositionLoadedMap(...)` repositionne background, foreground et PNJ lors des maps connectées.
- `_unmountLoadedMap(...)` retire background, foreground et PNJ.
- Aucun composant d'occlusion n'est monté.

Constats sur `RuntimeMapGame` :

- `RuntimeMapGame` ajoute seulement un `MapLayersComponent` background.
- Il ne crée pas de joueur, PNJ ni depth sorting acteur.
- Il n'est pas le chemin prioritaire pour une V0 d'occlusion acteur.

Constats sur `PlacedElementOcclusionPatchComponent` :

- Le composant existe déjà.
- Il redessine les pixels `occlusionMask` au-dessus du joueur lorsque la priorité Flame le permet.
- Il calcule une priorité `1000 + bottomWorld`.
- Il utilise `element.frames.primaryFrame`.
- Il dessine un `drawImageRect` par pixel occlusif.
- Il prend une `ui.Image tileImage`.
- Il n'est pas référencé ailleurs dans `map_runtime`.
- Il n'est pas exporté par `map_runtime.dart`.
- Le runtime courant charge les tilesets comme `RuntimeTilesetImage`, pas comme `ui.Image` brute.

Conclusion :

```text
Le runtime a déjà deux ingrédients : depth sorting acteur et prototype de patch.
Il manque la résolution/montage des patches, et le composant doit parler
RuntimeTilesetImage pour respecter le pipeline d'assets chunkés.
```

## 9. Audit des acteurs / joueur / depth sorting

Fichiers inspectés :

```text
packages/map_runtime/lib/src/presentation/flame/player_component.dart
packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
```

Classes et fonctions importantes :

- `PlayerComponent.footPoint`
- `PlayerComponent.focusPoint`
- `PlayerComponent.mapOrigin`
- `PlayerComponent.syncState(...)`
- `OverworldActorComponent.depthSortY`
- `OverworldActorComponent.configureGridPlacement(...)`
- `PlayableMapGame._updateActorDepthOrdering()`

Constats :

- `PlayerComponent.footPoint` est calculé depuis la hitbox de pieds V1.
- `OverworldActorComponent.depthSortY` vaut `position.y + size.y`.
- `PlayableMapGame._updateActorDepthOrdering()` trie visuellement par priorité Flame autour de `1000 + footY/depthSortY`.
- Les layers foreground complets sont à priorité `100000`, donc toujours au-dessus des acteurs.
- Un patch occlusion à priorité `1000 + sortY` peut s'intercaler avec joueur et PNJ.

Conclusion :

```text
Le système de priorité acteur existant est le bon point d'accroche.
Une V0 ne doit pas transformer les toits en foreground layer global à priorité 100000,
car cela supprime la nuance de depth sorting.
```

## 10. Problème produit à résoudre

Question produit :

```text
Quand le joueur passe derrière un toit, une couronne d'arbre, une arche ou un
objet haut, la partie haute doit recouvrir le sprite joueur sans bloquer le
déplacement.
```

Ce que le système sait déjà :

```text
Créer occlusionMask.
Éditer occlusionMask.
Sauvegarder occlusionMask.
Charger occlusionMask.
Séparer occlusionMask de collisionMask.
```

Ce qui manque :

```text
Transformer occlusionMask en instructions/composants de rendu runtime.
Monter ces patches au bon endroit dans le monde Flame.
Les trier avec joueur et PNJ sans modifier GameplayWorldState.
Tester le rendu et la non-régression collision.
```

Règle produit cible :

```text
occlusionMask peut recouvrir visuellement un acteur.
occlusionMask ne bloque jamais un acteur.
```

## 11. Options d’architecture comparées

### Option A — Ne rien faire runtime, occlusionMask reste donnée future

Avantages :

- Aucun risque runtime.
- Aucun coût performance.
- Aucune dette de rendu ajoutée.

Inconvénients :

- Les toits, arbres et arches ne recouvrent pas le joueur.
- L'UI et la génération produisent une donnée visible mais sans effet runtime.
- Le contrat produit reste incomplet.

Verdict :

```text
Acceptable comme état temporaire, pas comme prochaine étape.
```

### Option B — Rendu foreground coarse basé sur cells / bbox

Avantages :

- Simple à implémenter.
- Réutilise des notions déjà connues.

Inconvénients :

- Pas fidèle à `occlusionMask`.
- Risque de recouvrir trop large, notamment les trous, fenêtres, bords de toit.
- Confond facilement `cells` collision/debug avec rendu occlusion.
- Recrée précisément le problème produit : une bbox visuelle trop large.

Verdict :

```text
Non recommandé.
```

### Option C — Patch d’occlusion pixel-level rendu au-dessus des acteurs

Avantages :

- Fidèle à `occlusionMask`.
- Sépare clairement collision et rendu.
- Correspond au contrat des lots 8 à 11.
- Peut être testé avec des pixels précis.

Inconvénients :

- Un draw call par pixel occlusif est coûteux si implémenté naïvement.
- Requiert une stratégie pour les tilesets chunkés.
- Requiert un montage/lifecycle par map chargée.

Verdict :

```text
Recommandé comme fond de V0, avec limite statique et tests de performance simples.
```

### Option D — Nouveau composant Flame dédié par élément occlusif

Avantages :

- S'intègre naturellement au depth sorting Flame.
- Ne surcharge pas `MapLayersComponent`.
- Permet de repositionner, monter et démonter par map.
- Proche du composant existant `PlacedElementOcclusionPatchComponent`.

Inconvénients :

- Beaucoup de composants si la map contient beaucoup d'éléments occlusifs.
- Lifecycle à gérer dans `_LoadedPlayableMap`.
- Le composant existant doit être aligné sur `RuntimeTilesetImage`.

Verdict :

```text
Recommandé pour la V0 avec un garde-fou statique et un inventaire limité aux
éléments ayant un occlusionMask non vide.
```

### Option E — Intégration dans MapLayersComponent avec render pass dédiée

Avantages :

- `MapLayersComponent` sait déjà dessiner les layers et éléments placés.
- Il possède déjà `tileImagesByTilesetId`.
- Peu de nouvelles classes.

Inconvénients :

- `MapLayersComponent` background a priorité `0` et ne peut pas recouvrir les acteurs.
- `MapLayersComponent` foreground a priorité `100000` et recouvre tous les acteurs.
- Une passe interne ne s'intercale pas naturellement entre plusieurs acteurs.
- Risque de charger encore plus un composant déjà dense.

Verdict :

```text
Non recommandé pour la V0 de depth sorting acteur.
Possible seulement comme aide de résolution pure ou test renderer.
```

## 12. Décision recommandée V0

Option V0 recommandée :

```text
Option C + Option D :
patch d'occlusion pixel-level statique, monté comme composant Flame dédié par
élément placé occlusif, trié avec les acteurs par priorité.
```

Règle de déclenchement V0 :

```text
Pour chaque MapPlacedElement statique dont le ProjectElementEntry possède un
ElementCollisionProfile.occlusionMask non vide :
1. rendre l'élément complet comme aujourd'hui dans MapLayersComponent ;
2. monter un patch occlusion dédié qui redessine seulement les pixels
   occlusionMask ;
3. donner au patch une priorité proche de 1000 + sortY du bas de l'élément ou
   de l'ancre visuelle choisie ;
4. laisser les acteurs avec leurs priorités existantes.
```

Condition d'occlusion V0 :

```text
Pas de test gameplay.
Pas de collision.
Pas de condition par cellule.
Le patch existe dans la scène et Flame décide l'ordre via priority.
```

Pourquoi cette condition est acceptable en V0 :

- Pour un toit ou une couronne haute, le patch est visuellement censé passer au-dessus des acteurs situés derrière.
- Un acteur devant l'élément a généralement un `footY` plus bas que le bas de l'élément, donc une priorité supérieure au patch si le sortY du patch est basé sur le bas de l'élément.
- Le résultat reste compatible avec plusieurs acteurs, car chaque acteur garde sa priorité.

Adaptation nécessaire avant implémentation :

```text
PlacedElementOcclusionPatchComponent doit consommer RuntimeTilesetImage ou une
instruction de rendu utilisant RuntimeTilesetImage.drawImageRect(...), pas une
ui.Image brute.
```

## 13. Décision recommandée V1

Option V1 recommandée :

```text
Introduire une résolution pure de patches d'occlusion et une optimisation de rendu.
```

Éléments V1 :

- Pré-calculer des segments horizontaux ou rectangles contigus depuis `occlusionMask`.
- Réduire les draw calls au lieu de dessiner pixel par pixel.
- Supporter les éléments placés animés en synchronisant la frame avec `MapLayersComponent`.
- Ajouter une condition acteur si les cas arches/ponts exigent une règle plus fine que le simple depth sort.
- Exposer un mode debug runtime pour visualiser les patches occlusion séparément de l'overlay collision.

## 14. Traitement des éléments statiques

Recommandation :

```text
Collision-13/14 doivent commencer par les éléments placés statiques.
```

Définition V0 d'un élément statique :

```text
ProjectElementEntry.frames.length == 1
et
MapPlacedElement.animation == null ou animation.enabled == false
```

Traitement :

- Résoudre l'élément depuis `instance.elementId`.
- Lire `element.collisionProfile?.occlusionMask`.
- Ignorer les masks absents, vides ou invalides.
- Résoudre la frame primaire.
- Résoudre le tileset via `frame.tilesetId` ou `element.tilesetId`.
- Monter un patch à l'origine map correcte.

Pourquoi commencer par statique :

- Le cas produit immédiat est la maison/arbre statique.
- Le composant existant utilise déjà `element.frames.primaryFrame`.
- Les tests pixel sont plus simples et moins fragiles.

## 15. Traitement des éléments animés

État actuel :

- `MapPlacedElement.animation` existe.
- `MapLayersComponent` sait choisir des frames via `_pickEntityFrame(...)`.
- `PlacedElementOcclusionPatchComponent` utilise seulement `element.frames.primaryFrame`.

Décision V0 :

```text
Les éléments animés avec occlusionMask doivent être ignorés ou rendus avec une
limite explicitement testée comme non couverte en V0.
```

Raison :

- Le mask est stocké une fois au niveau `ElementCollisionProfile`.
- Les frames doivent avoir même taille selon validation, mais le contenu peut varier.
- La synchronisation de frame entre base et patch doit être conçue, pas copiée à la main.

Décision V1 :

```text
Partager une résolution de frame avec MapLayersComponent ou extraire une helper
runtime commune, puis appliquer le même frame courant au patch.
```

## 16. Traitement des maps connectées

État actuel :

- `PlayableMapGame` charge plusieurs maps dans `_loadedMapsById`.
- `_mountLoadedMap(...)` positionne chaque map avec `originCellX`, `originCellY`.
- `_originPixels(...)` convertit l'origine en pixels monde.
- `_repositionLoadedMap(...)` repositionne background, foreground et PNJ.
- `_unmountLoadedMap(...)` retire background, foreground et PNJ.

Décision V0 :

```text
Les patches d'occlusion doivent être attachés à la même unité de lifecycle que
backgroundLayers, foregroundLayers et npcActors.
```

Conséquence fichier :

```text
_LoadedPlayableMap doit stocker la liste des patches d'occlusion.
_mountLoadedMap doit les créer avec l'origine map.
_repositionLoadedMap doit les repositionner ou les recréer.
_unmountLoadedMap doit les retirer.
```

Risque évité :

```text
Un patch d'une map connectée ne doit jamais rester affiché après un prune ou
être dessiné à l'origine d'une autre map.
```

## 17. Performance / draw calls / masking

Constat :

```text
PlacedElementOcclusionPatchComponent.render(...) parcourt tous les pixels du
mask et appelle canvas.drawImageRect(...) pour chaque pixel occlusif.
```

Avantages V0 :

- Fidélité parfaite au mask.
- Pas de shader.
- Pas de `saveLayer`.
- Simple à tester.

Risques :

- Trop de draw calls si de nombreux éléments occlusifs ou grands masques.
- Coût CPU par frame, car le mask est décodé dans `render(...)`.
- Pas de cache de pixels décodés.

Recommandation V0 :

```text
Éviter saveLayer/shader/clipPath.
Décoder le mask hors render ou mettre en cache dans le composant.
Limiter la V0 aux éléments statiques.
Accepter une stratégie pixel-level seulement si les tests ciblés restent bornés.
```

Recommandation V1 :

```text
Pré-calculer des runs horizontaux de pixels occlusifs ou des rectangles
contigus, puis dessiner par segments.
```

Décision sur `saveLayer` :

```text
Ne pas utiliser saveLayer en V0.
```

Raison :

- `saveLayer` est plus difficile à borner en performance.
- La V0 peut être exacte avec des draw rects simples.
- Une approche par segments donnera un meilleur compromis avant shader.

## 18. Plan fichier par fichier pour les lots futurs

### `packages/map_core/lib/src/models/element_collision_profile.dart`

**Statut recommandé :**
À ne pas modifier.

**Rôle actuel :**
Stocke `visualMask`, `collisionMask`, `occlusionMask`, `cells`.

**Pourquoi ce fichier est concerné :**
Il contient la donnée source `occlusionMask`.

**Changement futur recommandé :**
Aucun pour la V0.

**Changement interdit :**
Ne pas renommer `pixelMask`, ne pas fusionner occlusion et collision, ne pas changer le schema.

**Tests nécessaires :**
Aucun nouveau test core pour la V0 runtime.

**Lot recommandé :**
Hors lot.

### `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`

**Statut recommandé :**
À auditer seulement en V0, à ne modifier que si un helper de résolution de frame est extrait proprement.

**Rôle actuel :**
Rend les layers, les placed elements, les entités projet, les shadows et l'overlay collision debug.

**Pourquoi ce fichier est concerné :**
Il dessine déjà l'image complète des placed elements et résout leurs frames.

**Changement futur recommandé :**
Ne pas y mettre la passe occlusion principale. Éventuellement extraire ou partager la logique de résolution de frame/tileset dans un helper runtime.

**Changement interdit :**
Ne pas utiliser `occlusionMask` dans `_paintPlacedElementsCollisionOverlay(...)`.
Ne pas transformer tous les éléments occlusifs en foreground global à priorité `100000`.

**Tests nécessaires :**
Tests de non-régression `map_layers_component_placed_element_render_test.dart` et `map_layers_component_render_pass_test.dart`.

**Lot recommandé :**
Collision-13 si extraction pure, Collision-14 si intégration minimale.

### `packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart`

**Statut recommandé :**
À modifier dans le lot d'implémentation.

**Rôle actuel :**
Prototype de composant qui redessine les pixels `occlusionMask` au-dessus des acteurs.

**Pourquoi ce fichier est concerné :**
Il encode déjà l'architecture recommandée.

**Changement futur recommandé :**
Remplacer `ui.Image tileImage` par `RuntimeTilesetImage` ou une instruction qui utilise `RuntimeTilesetImage.drawImageRect(...)`.
Décoder/cache le mask hors boucle chaude si possible.
Garder le rendu strictement visuel.

**Changement interdit :**
Ne pas lire `collisionMask` pour le rendu d'occlusion.
Ne pas écrire dans `GameplayWorldState`.

**Tests nécessaires :**
Nouveau test renderer : pixels masqués redessinés, pixels non masqués transparents, priorité calculée.

**Lot recommandé :**
Collision-14.

### `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

**Statut recommandé :**
À modifier dans le lot d'implémentation runtime.

**Rôle actuel :**
Monte maps, layers, joueur, PNJ, gère les maps connectées et la priorité acteur.

**Pourquoi ce fichier est concerné :**
C'est le point qui connaît `world`, `originCellX`, `originCellY`, `tileImagesById`, lifecycle de map et acteurs.

**Changement futur recommandé :**
Créer et monter les patches d'occlusion dans `_mountLoadedMap(...)`.
Les stocker dans `_LoadedPlayableMap`.
Les repositionner dans `_repositionLoadedMap(...)`.
Les retirer dans `_unmountLoadedMap(...)`.

**Changement interdit :**
Ne pas modifier `_world` ou les règles de collision pour l'occlusion.

**Tests nécessaires :**
Test de montage PlayableMapGame : un placed element avec occlusionMask crée un patch; une map sans mask n'en crée pas; reposition/unmount fonctionne.

**Lot recommandé :**
Collision-14.

### `packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart`

**Statut recommandé :**
À ne pas modifier en V0.

**Rôle actuel :**
Affiche une map runtime simple avec un seul `MapLayersComponent`, sans acteurs.

**Pourquoi ce fichier est concerné :**
Il est un host runtime simplifié, mais l'occlusion acteur nécessite joueur/PNJ.

**Changement futur recommandé :**
Aucun en V0. Ajouter un support plus tard seulement si ce host devient un viewer avec acteur.

**Changement interdit :**
Ne pas dupliquer le système PlayableMapGame dans RuntimeMapGame.

**Tests nécessaires :**
Test de non-régression : RuntimeMapGame reste passif si la V0 cible PlayableMapGame.

**Lot recommandé :**
Hors V0.

### `packages/map_runtime/lib/src/presentation/flame/player_component.dart`

**Statut recommandé :**
À ne pas modifier.

**Rôle actuel :**
Rend le joueur et expose `footPoint`.

**Pourquoi ce fichier est concerné :**
`footPoint` sert déjà au depth sorting.

**Changement futur recommandé :**
Aucun pour la V0.

**Changement interdit :**
Ne pas changer la hitbox, la taille de sprite ou le calcul `footPoint` pour résoudre l'occlusion.

**Tests nécessaires :**
Réutiliser `player_component_test.dart` et ajouter un test d'ordre côté PlayableMapGame si nécessaire.

**Lot recommandé :**
Hors V0.

### `packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart`

**Statut recommandé :**
À ne pas modifier.

**Rôle actuel :**
Rend les PNJ/acteurs et expose `depthSortY`.

**Pourquoi ce fichier est concerné :**
Les patches occlusion doivent se trier avec les acteurs.

**Changement futur recommandé :**
Aucun pour la V0.

**Changement interdit :**
Ne pas ajouter de logique occlusion par acteur dans le composant.

**Tests nécessaires :**
Tests d'ordre de priorité dans PlayableMapGame, pas dans l'acteur.

**Lot recommandé :**
Hors V0.

### `packages/map_runtime/test/...`

**Statut recommandé :**
À créer / modifier.

**Rôle actuel :**
Le package contient déjà des tests de `MapLayersComponent`, `PlayableMapGame`, shadows et load bundle.

**Pourquoi ce fichier est concerné :**
L'occlusion V0 est un comportement runtime visuel.

**Changement futur recommandé :**
Créer des tests dédiés :

```text
packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
packages/map_runtime/test/playable_map_game_placed_element_occlusion_test.dart
```

**Changement interdit :**
Ne pas ajouter de golden screenshot fragile si un test pixel ciblé suffit.

**Tests nécessaires :**
Voir section 20.

**Lot recommandé :**
Collision-13 / Collision-14 / Collision-15.

### `packages/map_editor/lib/src/ui/widgets/element_collision_triple_mask_editor.dart`

**Statut recommandé :**
À ne pas modifier.

**Rôle actuel :**
Permet d'éditer `collisionMask` et `occlusionMask`.

**Pourquoi ce fichier est concerné :**
Il produit la donnée que le runtime consommera.

**Changement futur recommandé :**
Aucun pour la V0 runtime.

**Changement interdit :**
Ne pas changer l'UX d'authoring dans le lot runtime.

**Tests nécessaires :**
Relancer `element_collision_editor_sheet_fine_mask_test.dart` seulement comme non-régression si un lot futur touche editor.

**Lot recommandé :**
Hors V0.

### `packages/map_gameplay/lib/src/gameplay_world_state.dart`

**Statut recommandé :**
À ne pas modifier.

**Rôle actuel :**
Consomme `collisionMask` en priorité et `cells` comme fallback.

**Pourquoi ce fichier est concerné :**
Il est la frontière à protéger : l'occlusion ne doit pas y entrer.

**Changement futur recommandé :**
Aucun.

**Changement interdit :**
Ne pas lire `occlusionMask`.
Ne pas changer `movementBlockReasonAt(...)`.
Ne pas ajouter une migration ou un cache d'occlusion.

**Tests nécessaires :**
Test de non-régression gameplay : `occlusionMask` seul ne bloque pas, si un lot futur ajoute des fixtures runtime.

**Lot recommandé :**
Hors V0.

## 19. Roadmap recommandée

### Collision-13 — Occlusion Runtime Patch Resolution Model V0

Objectif :

```text
Créer une résolution pure map_runtime des patches d'occlusion statiques.
```

Livrables :

- modèle interne de patch ou instruction runtime ;
- résolution depuis `RuntimeMapBundle`, `MapPlacedElement`, `ProjectElementEntry`, `RuntimeTilesetImage`;
- tests sans montage PlayableMapGame lourd ;
- aucune collision.

### Collision-14 — Static Placed Element Occlusion Patch Renderer V0

Objectif :

```text
Adapter ou remplacer PlacedElementOcclusionPatchComponent pour RuntimeTilesetImage,
puis monter les patches statiques dans PlayableMapGame.
```

Livrables :

- composant patch utilisant `RuntimeTilesetImage.drawImageRect(...)`;
- montage dans `_mountLoadedMap(...)`;
- lifecycle dans `_LoadedPlayableMap`, `_repositionLoadedMap(...)`, `_unmountLoadedMap(...)`;
- tests pixel renderer et tests de montage.

### Collision-15 — Building Occlusion Golden Slice V0

Objectif :

```text
Prouver sur un bâtiment que le toit recouvre le joueur au runtime pendant que
la base/collision reste gouvernée par collisionMask.
```

Livrables :

- fixture bâtiment avec `collisionMask` et `occlusionMask`;
- test runtime render order ;
- test gameplay inchangé ;
- test map connected si le patch traverse une boundary de chargement.

### Collision-16 — Animated Occlusion / Optimization V1

Objectif :

```text
Étendre l'occlusion aux éléments animés et optimiser les draw calls.
```

Livrables :

- frame timeline partagée ;
- run-length rendering ou cache de rectangles ;
- perf guard.

## 20. Plan de tests futurs

Tests `map_runtime` recommandés :

```text
placed element occlusion patch renders only masked pixels
placed element occlusion patch uses RuntimeTilesetImage chunks
placed element occlusion patch priority sorts with player footY
playable map game mounts static occlusion patches for placed elements
playable map game does not mount patches when occlusionMask is absent
playable map game removes occlusion patches when map is unmounted
playable map game repositions occlusion patches with connected map origins
building occlusion golden slice draws roof patch above player behind building
building occlusion golden slice lets player render above patch when in front
occlusionMask does not affect GameplayWorldState blocking
collision overlay still renders collisionMask, not occlusionMask
animated placed elements with occlusionMask are explicitly skipped in V0
```

Tests à relancer en non-régression :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter compact test/map_layers_component_placed_element_render_test.dart test/map_layers_component_render_pass_test.dart test/load_runtime_map_bundle_collision_normalization_test.dart
```

Tests futurs ciblés :

```bash
cd packages/map_runtime
flutter test --no-pub --reporter compact test/placed_element_occlusion_patch_component_test.dart test/playable_map_game_placed_element_occlusion_test.dart
```

Test gameplay garde-fou :

```bash
cd packages/map_gameplay
flutter test --no-pub --reporter compact test/collision_building_golden_slice_test.dart
```

## 21. Risques et arbitrages

Risque : draw calls pixel-level.

Arbitrage :

```text
Acceptable seulement pour une V0 bornée et testée. V1 doit réduire les draw calls.
```

Risque : composant dormant incompatible avec `RuntimeTilesetImage`.

Arbitrage :

```text
Adapter le composant avant montage. Ne pas contourner le pipeline chunké.
```

Risque : foreground global à priorité `100000`.

Arbitrage :

```text
Ne pas utiliser foreground global pour occlusionMask, car il recouvre tout acteur
sans nuance de depth sorting.
```

Risque : animations.

Arbitrage :

```text
V0 statique seulement. Les animations passent en V1 avec timeline partagée.
```

Risque : maps connectées.

Arbitrage :

```text
Stocker les patches dans _LoadedPlayableMap et les traiter comme layers/PNJ au
mount, reposition et unmount.
```

## 22. Ce qu’il ne faut surtout pas faire

Interdits techniques :

```text
Ne pas lire occlusionMask dans GameplayWorldState.
Ne pas mélanger occlusionMask et collisionMask.
Ne pas projeter occlusionMask vers cells.
Ne pas utiliser visualMask comme collision.
Ne pas rendre toute la bbox ou toutes les cells comme occlusion.
Ne pas mettre tous les éléments occlusifs dans foregroundLayers à priorité 100000.
Ne pas changer la hitbox joueur pour faire marcher l'occlusion.
Ne pas lancer build_runner pour ce sujet.
Ne pas changer le JSON schema.
Ne pas brancher l'occlusion runtime dans editor.
```

## 23. Questions ouvertes

Questions pour Collision-13/14 :

- Le sortY du patch doit-il être le bas du mask, le bas de l'élément, ou une ancre explicite future ?
- Faut-il ignorer les masks entièrement vides après décodage ?
- Faut-il ajouter un debug overlay distinct `occlusion overlay` dans un lot séparé ?
- Quel seuil de draw calls impose un passage à des runs horizontaux ?
- Les éléments `MapEntity` avec `editorVisual.elementId` doivent-ils aussi bénéficier de `occlusionMask`, ou seulement les `MapPlacedElement` en V0 ?

Décision V0 pour réduire le périmètre :

```text
Traiter d'abord les MapPlacedElement statiques.
Documenter les MapEntity editorVisual comme hors V0.
```

## 24. Recommandation finale

Recommandation finale :

```text
Lancer Collision-13 avec un modèle de résolution de patches d'occlusion statiques
dans map_runtime, sans toucher à GameplayWorldState.
```

Design cible :

```text
RuntimeMapBundle + MapPlacedElement + ProjectElementEntry + occlusionMask
→ instructions/composants d'occlusion statiques
→ montage dans PlayableMapGame
→ priorité Flame autour de 1000 + sortY
→ rendu au-dessus ou au-dessous des acteurs selon footY/depthSortY
```

Position ferme :

```text
occlusionMask est une donnée de rendu.
collisionMask reste la donnée gameplay.
cells reste projection/fallback/debug.
```

## 25. Git status final

Commande :

```bash
git diff --name-only
```

Sortie exacte avant création du rapport :

```text
```

Commande :

```bash
git diff --stat
```

Sortie exacte avant création du rapport :

```text
```

Commande après création du rapport :

```bash
git status --short --untracked-files=all
```

Sortie exacte finale :

```text
?? reports/collision/collision_lot_12_occlusion_runtime_decision.md
```

Interprétation :

```text
Seul le rapport Collision-12 est créé.
Aucun fichier packages/** n'est modifié.
```

## 26. Auto-review finale

Checklist :

- Ai-je modifié uniquement le rapport ? Oui.
- Ai-je évité `map_core` production ? Oui.
- Ai-je évité `map_editor` production ? Oui.
- Ai-je évité `map_gameplay` production ? Oui.
- Ai-je évité `map_runtime` production ? Oui.
- Ai-je évité build_runner/generated ? Oui.
- Ai-je clairement séparé collision et occlusion ? Oui.
- Ai-je audité `MapLayersComponent` ? Oui.
- Ai-je audité `PlacedElementOcclusionPatchComponent` ? Oui.
- Ai-je audité `PlayerComponent` / `OverworldActorComponent` ? Oui.
- Ai-je identifié les options d'architecture ? Oui.
- Ai-je recommandé une V0 claire ? Oui.
- Ai-je proposé une roadmap future ? Oui.
- Ai-je identifié les risques ? Oui.

Auto-critique :

```text
Le rapport recommande une V0 statique et dédiée, pas une solution finale.
Le principal risque restant est la performance du rendu pixel-level si le nombre
de patches ou de pixels occlusifs augmente. La roadmap propose de le traiter
après la preuve produit statique, avec des segments/runs ou un cache.
```
