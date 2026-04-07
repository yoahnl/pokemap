# Rapport — PNJ « absent » : alignement gameplay / rendu / interaction

**Date** : 2026-04-07  
**Contrainte** : aucune écriture Git.

---

## 1. Cause racine (diagnostic précis)

### Ce qui était déjà correct

- [GameplayWorldState] reconstruit `_blockingEntityByPos` et `_entityByPos` via [NpcMapPresencePredicate] : `isBlocked`, `entityAt`, [stepGameplayWorld] + [InteractIntent] s’appuient sur ces caches.
- Dès que `_refreshWorldNpcPresence()` met à jour le prédicat, **la grille logique** exclut normalement le PNJ.

### Pourquoi le produit voyait encore blocage + dialogue

Plusieurs chemins **parallèles** au cache gameplay restaient actifs :

| Zone | Fichier | Problème |
|------|---------|----------|
| Rendu Flame | `overworld_actor_component.dart` | `setGameplayVisible(false)` ne faisait que court-circuiter `render` : le [PositionComponent] gardait sa **taille** et participait aux **hit tests** Flame (`containsLocalPoint` / équivalent). |
| Patrouille PNJ | `playable_map_game.dart` → `_applyNpcOverworldDefaultMovement` | Les patrouilles démarraient pour **tous** les PNJ avec route, **sans** vérifier le prédicat → réservations de cases (`_scriptedNpcReservedOccupiedCellsByEntity`) et pas encore visibles pouvaient bloquer le joueur via `_scriptedNpcDynamicBlockedCells`. |
| Trainer LoS | `_triggeredTrainerBattles` | Pas nettoyé quand le PNJ devient absent → états parasites possibles. |
| Dialogue | `_tryOpenDialogue` | Ouvertures pilotées par **id** (cutscene / script) sans repasser par `entityAt` → contournement possible du prédicat. |
| Garde-fou interaction | `_handleNpcInteraction` | Aucune vérif explicite si une régression réintroduisait un `NpcInteracted` incohérent. |

---

## 2. Corrections implémentées

### A. `OverworldActorComponent`

- Surcharge de **`containsLocalPoint`** : retourne `false` si `!_gameplayVisible` → pas de ciblage tap / propagation sur le sprite « absent ».
- Getter **`isGameplayPresent`** pour tests / debug.
- Commentaires : absence = hors hit test, pas seulement invisible.

### B. `PlayableMapGame`

1. **`_stopGameplaySideEffectsForAbsentNpcs()`** (appelée depuis `_refreshWorldNpcPresence`) : pour chaque PNJ avec prédicat `false` sur la map active : `stopPatrol`, suppression réservations, `_runtimeNpcPositions`, `_triggeredTrainerBattles`.
2. **`_applyNpcOverworldDefaultMovement()`** : ne démarre plus de patrouille si le prédicat exclut le PNJ ; appelle `stopPatrol` dans ce cas.
3. **`_npcEntityAllowedOnActiveMapForDialogue`** + garde dans **`_tryOpenDialogue`** : si l’`entityId` correspond à un PNJ sur `_world.map` et que le prédicat est faux → pas d’ouverture.
4. **`_handleNpcInteraction`** : retour immédiat si prédicat faux.
5. **`loadGame()`** : appel final à **`_refreshWorldNpcPresence()`** pour réaligner rendu + systèmes scriptés après hydratation.

**Source de vérité unique** : toujours `npcPresencePredicate(mapId, entity)` ; le rendu et les effets parallèles suivent cette même règle.

---

## 3. Tests

Fichier : `packages/map_gameplay/test/npc_map_presence_predicate_test.dart`

- Déplacement : `MoveIntent` vers la case du PNJ **réussit** si le prédicat retire le PNJ.
- Interaction : `InteractIntent` → `NothingToInteract` si le PNJ est retiré du prédicat.
- Réapparition : `withNpcMapPresencePredicate((_, __) => true)` → `NpcInteracted` à nouveau possible.

**Non couvert ici** (limite honnête) : test d’intégration **Flutter / PlayableMapGame** complet (load binaire + tap) — la logique dialogue/patrouille est testée au niveau unitaire + gameplay pur.

---

## 4. Commandes exécutées

- `dart test test/npc_map_presence_predicate_test.dart` (map_gameplay) : OK  
- `dart test` (map_gameplay, suite complète) : OK  
- `dart analyze` sur `playable_map_game.dart` et `overworld_actor_component.dart` : OK  

---

## 5. Limites restantes

- Dialogues / scripts qui **ne** passent **pas** par `_tryOpenDialogue` avec un `entityId` de PNJ sur la map active pourraient encore exister ; la garde couvre le chemin principal runtime.
- PNJ absents restent dans `map.entities` (données carte) ; seuls les **systèmes runtime** les ignorent — c’est voulu pour réapparition sans recharger la map.

---

## 6. Fichiers modifiés

| Fichier | Modification |
|---------|----------------|
| `packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart` | Hit test désactivé si absent. |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | Sync patrouille / LoS / dialogue / load. |
| `packages/map_gameplay/test/npc_map_presence_predicate_test.dart` | Tests mouvement, interaction, réapparition. |
| `packages/map_editor/reports/npc_absent_gameplay_alignment_report.md` | Ce rapport. |
