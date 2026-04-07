# Rapport : présence runtime PNJ (Step Studio + visibilité) — fermeture du flux « Emma réapparaît »

## 1. Cause racine (constat technique)

Le symptôme « disparaît puis revient » venait d’une **combinaison** de facteurs, pas d’un seul `if` :

1. **Acteurs Flame conservés pour les PNJ « absents »**  
   Tant qu’un `OverworldActorComponent` existe, tout bug de synchronisation (prédicat, refresh ou état `_gameplayVisible`) peut refaire apparaître un sprite ou réactiver des chemins qui partent du composant. La politique « masquer seulement » (`setGameplayVisible(false)`) est fragile si un flux ne rappelle pas le refresh ou si le composant est traité comme « monté » ailleurs.

2. **Risque de désynchronisation après changements de progression hors chemins déjà instrumentés**  
   Le callback `onGameStateUpdated` des **scripts** mettait à jour `_gameState` **sans** `_refreshWorldNpcPresence()`. Toute mutation de progression (flags, etc.) via ce chemin pouvait laisser `_world` et les acteurs dans un état cohérent avec l’**ancienne** présence jusqu’au prochain refresh « chanceux ».

3. **Warp / connexion entre cartes**  
   Après transition, le monde gameplay était reconstruit avec un prédicat correct à l’instant T, mais **sans** repasser par la même séquence que `loadGame` (`_refreshWorldNpcPresence`). En pratique le montage appelait déjà `_applyNpcVisibilityToLoadedMap`, mais l’absence de refresh unique après prune / preload laissait une **fenêtre** pour des écarts entre gameplay, acteurs et effets parallèles (patrouille, etc.) selon l’ordre des opérations.

4. **Prédicat : liste Step Studio capturée à la création du closure (risque théorique)**  
   `_npcPresencePredicateFor` fixait `worldRules` **avant** le `return` du closure. Si le cache manifeste était invalidé de façon inhabituelle, une ancienne liste pouvait rester attachée à un closure déjà stocké dans un composant. **Correction** : recalcul systématique via `_ensureStepStudioWorldRulesForManifest(manifest)` **à l’intérieur** de chaque évaluation + fonction pure partagée.

## 2. Chemins runtime qui pouvaient « ressusciter » ou désynchroniser un PNJ

| Zone | Comportement à risque |
|------|------------------------|
| `_mountLoadedMap` | Création d’un acteur par PNJ avec personnage **sans** tenir compte de l’absence → acteur par défaut « présent » jusqu’au refresh. |
| `_refreshWorldNpcPresence` | Si non appelé après mutation de `_gameState`, visibilité / gameplay restent sur l’ancienne vérité. |
| Scripts (`_startScriptExecution`) | Mise à jour `_gameState` sans refresh de présence. |
| Warp / `_handleConnection` | Transitions sans `_refreshWorldNpcPresence()` après preload / prune. |
| `_collectCurrentNpcPositions` | Suivi des positions pour tout PNJ ayant un acteur, **y compris** masqué → patrouille / tracking pouvant rester alignés sur un PNJ « logiquement absent ». |
| `MapLayersComponent` + acteur | Deux représentations ; si l’acteur existe toujours, le risque visuel / hit test est porté par le composant acteur. |

Les lectures directes de `map.entities` restent la source des données **auteur** ; la règle produit est : **filtrer par prédicat** (gameplay + rendu calques + LoS + refresh) ou **ne pas monter** l’acteur si absent.

## 3. Décision architecturale retenue

- **Source de vérité unique pour la booléenne « présent sur cette carte »** :  
  `isNpcRuntimePresentOnMap` dans `lib/src/application/npc_runtime_presence.dart`  
  = `MapEntityRuntimePredicateEvaluator.isNpcPresentOnMap` **puis** `entityPassesStepStudioWorldPresence` (même ordre qu’avant, centralisé et testable).

- **`PlayableMapGame._npcPresencePredicateFor`** : closure mince qui assure le cache manifeste puis délègue à `isNpcRuntimePresentOnMap`.

- **Montage** : ne plus créer d’`OverworldActorComponent` pour un PNJ absent au moment du mount.

- **Refresh** : après `withNpcMapPresencePredicate`, **`_detachAbsentNpcActorsFromAllLoadedMaps`** retire physiquement les acteurs des PNJ devenus absents (toutes les cartes chargées), puis resync visibilité / debug / effets secondaires.

- **Tracking patrouille** : `_collectCurrentNpcPositions` ne garde que les PNJ **présents** au sens du prédicat **et** encore montés en acteur.

- **Scripts** : `onGameStateUpdated` déclenche `_refreshWorldNpcPresence()`.

- **Warp / connexion** : appel explicite à `_refreshWorldNpcPresence()` après preload / prune.

## 4. Fichiers modifiés / ajoutés

| Fichier | Rôle |
|---------|------|
| `lib/src/application/npc_runtime_presence.dart` | **Nouveau** — décision de présence runtime partagée. |
| `lib/src/presentation/flame/playable_map_game.dart` | Prédicat, detach acteurs, mount filtré, collect positions, scripts, warp, connexion. |
| `lib/map_runtime.dart` | Export public de `isNpcRuntimePresentOnMap`. |
| `test/npc_runtime_presence_test.dart` | **Nouveau** — tests ciblés (voir §6). |

## 5. Pourquoi chaque modification est nécessaire

- **`isNpcRuntimePresentOnMap`** : un seul endroit pour tests et pour éviter des divergences futures entre gameplay, Flame et outils.
- **Closure + `_ensureStepStudioWorldRulesForManifest` à l’intérieur** : évite une capture figée de `worldRules` si le cache manifeste change.
- **Pas d’acteur si absent au mount** : supprime la fenêtre « acteur créé visible par défaut » et réduit les chemins qui supposent un composant monté.
- **`_detachAbsentNpcActorsFromAllLoadedMaps`** : quand la progression fait passer un PNJ de présent à absent, **aucun** composant Flame ne subsiste ; pas de hit test, pas de sprite, pas de patrouille côté acteur.
- **`_collectCurrentNpcPositions` filtré** : patrouille / positions runtime alignés sur la même définition de « présent ».
- **Script + warp + connexion** : même point de resynchronisation que après chargement de sauvegarde.

## 6. Tests ajoutés

Fichier `test/npc_runtime_presence_test.dart` :

1. Emma **présente** tant que `step_2_1` n’est pas dans `completedStepIds`.
2. Emma **absente** après complétion (`hiddenAfterStepCompletion`) — **cas produit Bourivka / emma**.
3. **Rebuild** de `GameplayWorldState.initial` deux fois avec le même prédicat dérivé de `isNpcRuntimePresentOnMap` → toujours absent des caches (`entityAt` / `isBlocked`).
4. **Round-trip JSON** sur `GameState` → `completedStepIds` conservés → toujours absent côté prédicat (proxy « reload save » au niveau données).
5. Visibilité de base `visibleWhen` impossible → `false` (pas de contournement Step Studio).

Les tests existants `map_gameplay/test/npc_map_presence_predicate_test.dart` et `test/step_studio_world_presence_runtime_test.dart` continuent de couvrir interaction / mouvement / parsing `worldChanges`.

## 7. Limites restantes (honnêtes)

- **Réapparition dynamique sans rechargement de carte** : si un PNJ passe de **absent → présent** (ex. règle `visibleAfterStepCompletion`) **sans** un nouveau `_mountLoadedMap`, le runtime **ne recrée pas** automatiquement un `OverworldActorComponent` (il n’y a pas encore de « spawn » async symétrique au detach). Il faudrait soit un remount ciblé, soit une factory async d’acteur PNJ. Aujourd’hui le produit est surtout sensible au **masquage durable** (Emma).

- **Tests d’intégration Flame** : pas de test `flutter_test` sur `PlayableMapGame` complet (chargement carte, warp, assert `isGameplayPresent` / absence de composant). La preuve reste **unitaire + logique gameplay** ; un golden ou un test de widget resterait un bonus.

- **`MapLayersComponent.bundle`** : reste l’instance du bundle au mount ; les mises à jour fines de `_world.map` sans resync explicite du bundle chargé peuvent garder des écarts sur les **données** calques (pas sur le filtre PNJ si le prédicat est rappelé). Hors périmètre immédiat sauf si un bug côté « sprite élément » réapparaît.

- **Autres kinds d’entités** : Step Studio `worldChanges` sur non-PNJ ne sont toujours pas filtrés par ce module (déjà documenté dans `step_studio_world_presence_runtime.dart`).

## 8. Vérification explicite du cas Emma

Scénario cible : `mapId` authoring = identifiant carte `bourivka_center`, `entityId` = `emma`, règle `hiddenAfterStepCompletion`, step source `step_2_1`, `completedStepIds` contient `step_2_1`.

- `isNpcRuntimePresentOnMap` retourne **`false`** (test dédié).
- Un `GameplayWorldState` construit avec un prédicat branché sur cette fonction **exclut** Emma des caches (test rebuild).
- À l’exécution Flame : après `_refreshWorldNpcPresence`, **aucun** acteur ne reste monté pour Emma sur la carte chargée si elle était présente avec personnage ; au prochain mount de cette carte, **aucun** acteur n’est créé si le prédicat est faux.

Si Emma « revient » encore en jeu réel après cette passe, la prochaine piste prioritaire est un **écart d’ids** (`mapId` / `entityId` / `sourceStepId`) entre l’authoring Step Studio et `MapData.id` / `MapEntity.id`, ou une progression qui n’est pas celle lue dans `_gameState` au moment du prédicat (instrumenter les logs `[step_studio]` / sauvegarde).
