# NS-GS-06 — GivePokemon Minimal

---

## 1. Résumé exécutif

Ce lot ajoute la mécanique générique permettant de donner un Pokémon au joueur.

Deux couches ont été livrées :

1. **Mutation pure** `GameStateMutations.givePokemon` dans `map_gameplay` — ajoute un `PlayerPokemon` pré-construit à `GameState.party`.
2. **Action narrative** `kScenarioActionGivePokemon` dans `map_runtime` — le ScenarioRuntimeExecutor lit les paramètres depuis `ScenarioNodePayload.params` et applique la mutation.

Aucun speciesId n'est hardcodé. Aucune fixture Selbrume finale n'a été créée. 20 tests passent (16 gameplay + 4 runtime). Les deux analyze sont clean (0 nouveau warning).

---

## 2. Roadmap lue et statut initial

Fichier lu : `MVP Selbrume/road_map.md` (639 lignes).

Statut initial de NS-GS-06 : 🔜 (prochain lot recommandé par NS-GS-05).

Décision mechanics-first confirmée : les agents ne créent pas les fixtures Selbrume finales.

---

## 3. Audit initial

### Modèles existants

| Modèle | Fichier | Observation |
|---|---|---|
| `PlayerPokemon` | [save_data.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart) | Freezed model avec speciesId, level, natureId, abilityId, currentHp, knownMoveIds, etc. `copyWith` disponible. |
| `PlayerParty` | [save_data.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart) | Contient `List<PlayerPokemon> members`. Pas de limite de taille modélisée. |
| `GameState.party` | [game_state.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/game_state.dart) | `PlayerParty` avec `copyWith` disponible. |
| `GameStateMutations` | [game_state_mutations.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/game_state_mutations.dart) | Pattern existant : `setFlag`, `giveItem`, `warpPlayer`, etc. Toutes pures. |
| `ScenarioNodeBinding` | [scenario_asset.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart) | Pas de champ `speciesId` — utiliser `payload.params` comme pour `battleId`. |
| `ScenarioNodePayload.params` | même fichier | `Map<String, String>` libre, utilisé par `startTrainerBattle` pour `battleId`. |

### Pattern existant : giveItem

```dart
GameState giveItem(GameState state, String itemId, int quantity)
```

La mutation `givePokemon` suit exactement ce pattern mais pour `PlayerPokemon`.

### Pattern existant : kScenarioActionSetFlag

```dart
case kScenarioActionSetFlag:
  final flagName = node.binding.flagName?.trim() ?? '';
  // ... validation ...
  final nextState = storyFlags.set(context.gameState, flagName);
  context.gameState = nextState;
  context.onGameStateUpdated(nextState);
```

L'action `givePokemon` suit ce pattern : lire les paramètres, construire le `PlayerPokemon`, appliquer la mutation, avancer le graphe.

### Pattern existant : kScenarioActionStartTrainerBattle

Utilise `payload.params['battleId']` pour les données non présentes dans `ScenarioNodeBinding`. L'action `givePokemon` utilise le même mécanisme pour `speciesId`, `level`, `natureId`, `abilityId`, `preventDuplicate`.

### Conversions save/load

Les conversions `saveDataFromGameState` / `gameStateFromSaveData` / `normalizeLoadedGameState` dans [game_state_persistence.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/operations/game_state_persistence.dart) gèrent déjà `PlayerParty` et `PlayerPokemon`. Pas de modification nécessaire.

### Limite de party

`PlayerParty` n'a pas de limite de taille modélisée. La limite de 6 Pokémon n'est pas modélisée dans les Freezed models. Hors scope NS-GS-06.

---

## 4. Décision d'implémentation

| Choix | Détail |
|---|---|
| Mutation | `GameStateMutations.givePokemon(state, {required PlayerPokemon pokemon, bool preventDuplicateSpecies})` |
| Package | `map_gameplay` (même fichier que `giveItem`) |
| Action runtime | `kScenarioActionGivePokemon = 'givePokemon'` dans `map_runtime` |
| Params | `speciesId` (obligatoire), `level` (5), `natureId` ('hardy'), `abilityId` ('unknown'), `preventDuplicate` ('false') |
| Anti-doublon | Par `speciesId` dans la party, optionnel |
| PlayerPokemon.currentHp | Mis à 1 par l'action runtime (la mutation accepte le PlayerPokemon tel quel) |
| build_runner | Non lancé |
| Limite party | Hors scope (non modélisée) |

### Option A — action native ScenarioRuntimeExecutor : **retenue**

L'action native `kScenarioActionGivePokemon` est simple (55 lignes), suit exactement les patterns existants (`setFlag`, `startTrainerBattle`), et rend la mécanique authorable par l'éditeur.

### Option B — runScript : **rejetée**

Moins authorable, moins claire, pas alignée avec le style existant.

---

## 5. Fichiers créés / modifiés

| Action | Fichier | Détail |
|---|---|---|
| MODIFIÉ | [game_state_mutations.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/game_state_mutations.dart) | +42 lignes : méthode `givePokemon` |
| MODIFIÉ | [scenario_runtime_executor.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart) | +68 lignes : constante + handler `kScenarioActionGivePokemon` |
| MODIFIÉ | [map_runtime.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/map_runtime.dart) | +1 ligne : export `kScenarioActionGivePokemon` |
| CRÉÉ | [give_pokemon_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/test/give_pokemon_test.dart) | 16 tests mutation pure |
| CRÉÉ | [scenario_give_pokemon_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/test/scenario_give_pokemon_test.dart) | 4 tests action runtime |

---

## 6. API ajoutée

### Mutation pure (map_gameplay)

```dart
/// Donne un Pokémon au joueur.
///
/// Le PlayerPokemon doit être construit par l'appelant.
/// Si preventDuplicateSpecies est true, no-op si le speciesId existe déjà.
GameState givePokemon(
  GameState state, {
  required PlayerPokemon pokemon,
  bool preventDuplicateSpecies = false,
});
```

Exportée via `package:map_gameplay/map_gameplay.dart` (classe `GameStateMutations`).

### Action narrative (map_runtime)

```dart
const String kScenarioActionGivePokemon = 'givePokemon';
```

Paramètres dans `ScenarioNodePayload.params` :

| Clé | Type | Défaut | Description |
|---|---|---|---|
| `speciesId` | String | **obligatoire** | Identifiant de l'espèce |
| `level` | String (parsé en int) | `'5'` | Niveau du Pokémon |
| `natureId` | String | `'hardy'` | Nature |
| `abilityId` | String | `'unknown'` | Talent |
| `preventDuplicate` | String (`'true'`/`'false'`) | `'false'` | Empêche le doublon |

Exportée via `package:map_runtime/map_runtime.dart`.

---

## 7. Action narrative ajoutée

**Option A retenue** : action native `kScenarioActionGivePokemon` dans le ScenarioRuntimeExecutor.

L'action :
- Lit les paramètres depuis `payload.params`
- Construit un `PlayerPokemon` minimal
- Applique `GameStateMutations.givePokemon`
- Met à jour `context.gameState` et `onGameStateUpdated`
- Avance vers le nœud suivant ou termine le flow
- Bloque si `speciesId` est absent

L'action est alignée avec les patterns existants (`setFlag`, `clearFlag`, `emitOutcome`, `startTrainerBattle`).

---

## 8. Comportement couvert

| Comportement | Implémenté | Testé |
|---|---|---|
| Ajout Pokémon à une party vide | ✅ | ✅ |
| Append à une party existante | ✅ | ✅ |
| Préservation des membres existants | ✅ | ✅ |
| Préservation du bag | ✅ | ✅ |
| Préservation des storyFlags | ✅ | ✅ |
| Préservation currentMapId et playerPosition | ✅ | ✅ |
| Préservation progression | ✅ | ✅ |
| No-op si speciesId vide | ✅ | ✅ |
| No-op si speciesId blank | ✅ | ✅ |
| Trimming speciesId | ✅ | ✅ |
| Anti-doublon par speciesId | ✅ | ✅ |
| Doublon autorisé par défaut | ✅ | ✅ |
| Doublon autorisé explicitement | ✅ | ✅ |
| Aucun id Selbrume hardcodé | ✅ | ✅ |
| Round-trip save/load | ✅ | ✅ |
| Full flow createNewGameState→givePokemon→save/load | ✅ | ✅ |
| Action scénario ajoute Pokémon | ✅ | ✅ |
| Action scénario defaults | ✅ | ✅ |
| Action scénario bloque sans speciesId | ✅ | ✅ |
| Action scénario preventDuplicate | ✅ | ✅ |

---

## 9. Tests ajoutés

### map_gameplay (16 tests)

Fichier : [give_pokemon_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/test/give_pokemon_test.dart)

### map_runtime (4 tests)

Fichier : [scenario_give_pokemon_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/test/scenario_give_pokemon_test.dart)

---

## 10. Commandes exécutées

```bash
# Tests gameplay
cd packages/map_gameplay && dart test test/give_pokemon_test.dart

# Analyze gameplay
cd packages/map_gameplay && dart analyze

# Tests runtime
cd packages/map_runtime && flutter test test/scenario_give_pokemon_test.dart

# Analyze runtime
cd packages/map_runtime && flutter analyze
```

---

## 11. Résultats des tests

### map_gameplay — 16/16

```text
00:00 +0: loading test/give_pokemon_test.dart
00:00 +0: GameStateMutations.givePokemon adds a Pokemon to an empty party
00:00 +1: GameStateMutations.givePokemon appends to an existing party
00:00 +2: GameStateMutations.givePokemon preserves existing party members
00:00 +3: GameStateMutations.givePokemon preserves bag
00:00 +4: GameStateMutations.givePokemon preserves storyFlags
00:00 +5: GameStateMutations.givePokemon preserves currentMapId and playerPosition
00:00 +6: GameStateMutations.givePokemon preserves progression
00:00 +7: GameStateMutations.givePokemon is a no-op when speciesId is empty
00:00 +8: GameStateMutations.givePokemon is a no-op when speciesId is blank
00:00 +9: GameStateMutations.givePokemon trims speciesId whitespace
00:00 +10: GameStateMutations.givePokemon prevents duplicate species when requested
00:00 +11: GameStateMutations.givePokemon allows duplicate species when preventDuplicateSpecies is false
00:00 +12: GameStateMutations.givePokemon allows duplicate species by default
00:00 +13: GameStateMutations.givePokemon does not hardcode any Selbrume ids
00:00 +14: GameStateMutations.givePokemon round-trips through save/load
00:00 +15: GameStateMutations.givePokemon full flow: createNewGameState then givePokemon then save/load
00:00 +16: All tests passed!
```

### map_gameplay — analyze

```text
Analyzing map_gameplay...

warning - pubspec.yaml:20:5 - invalid_dependency (pré-existant)
   info - test/los_detection_test.dart:8:24 - no_leading_underscores_for_local_identifiers (pré-existant)

2 issues found. (0 nouveaux)
```

### map_runtime — 4/4

```text
00:00 +0: loading scenario_give_pokemon_test.dart
00:00 +0: ScenarioRuntimeExecutor - givePokemon action givePokemon action adds Pokemon to party
00:00 +1: ScenarioRuntimeExecutor - givePokemon action givePokemon uses defaults for optional params
00:00 +2: ScenarioRuntimeExecutor - givePokemon action givePokemon blocks when speciesId is missing
00:00 +3: ScenarioRuntimeExecutor - givePokemon action givePokemon with preventDuplicate prevents double give
00:00 +4: All tests passed!
```

### map_runtime — analyze

```text
353 issues found. (0 nouveau — tous pré-existants info-level: prefer_const_constructors, prefer_const_declarations, etc.)
```

---

## 12. Respect mechanics-first

| Critère | Respecté |
|---|---|
| Aucun id Selbrume hardcodé | ✅ |
| Aucune fixture Selbrume créée | ✅ |
| Mécanique générique | ✅ |
| Compatible tout projet authoré | ✅ |
| createNewGameState reste party vide | ✅ |
| PlayerPokemon fourni par l'appelant | ✅ |
| GivePokemon ne décide pas quel Pokémon donner | ✅ |
| build_runner non lancé | ✅ |

---

## 13. Mise à jour road_map.md

Statut NS-GS-06 mis à jour en ✅ fait.

Prochain lot mis à jour : NS-GS-07 — Step Completion / Progression Hooks V0.

Section « Mise à jour NS-GS-06 » ajoutée.

---

## 14. Limites et non-objectifs

```text
PlayerParty n'a pas de limite de taille (6 max non modélisé) — hors scope.
PlayerPokemon.currentHp mis à 1 par l'action runtime — pas de calcul HP/stats.
Pas de calcul learnset / moves / stats.
Pas de UI choix starter.
Pas de PC / boxes.
Pas de capture.
Pas de level-up.
Pas de validation complète du Pokémon (seul speciesId non-vide est vérifié).
Level clampé entre 1 et 100 dans l'action runtime (guard minimal).
```

---

## 15. Prochain lot recommandé

```text
NS-GS-07 — Step Completion / Progression Hooks V0
```

Périmètre attendu :

```text
Mécanique de progression narrative step-by-step.
Marquage des étapes complétées.
Hooks de condition pour le scénario.
Tests obligatoires.
Mettre à jour MVP Selbrume/road_map.md.
```

---

## 16. Evidence Pack

### Git status initial

```bash
$ git status --short --untracked-files=all
(working tree propre)
```

### Git diff --check final

```bash
$ git diff --check
EXIT:0
```

### Git diff --stat final

```bash
$ git diff --stat
 packages/map_gameplay/lib/src/game_state_mutations.dart     | 42 +++++++++++++
 packages/map_runtime/lib/map_runtime.dart                   |  1 +
 .../scenario_runtime/scenario_runtime_executor.dart          | 68 ++++++++++++++++++++++
 3 files changed, 111 insertions(+)
```

### Git diff --name-only final

```bash
$ git diff --name-only
packages/map_gameplay/lib/src/game_state_mutations.dart
packages/map_runtime/lib/map_runtime.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
```

### Git status final

```bash
$ git status --short --untracked-files=all
 M packages/map_gameplay/lib/src/game_state_mutations.dart
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
?? packages/map_gameplay/test/give_pokemon_test.dart
?? packages/map_runtime/test/scenario_give_pokemon_test.dart
```

### Confirmations

```text
Aucune fixture Selbrume finale créée.
Aucun id Selbrume hardcodé.
createNewGameState reste party vide.
GivePokemon est générique.
build_runner non lancé.
Aucune opération Git d'écriture effectuée.
```

---

## 17. Auto-review

| Question | Réponse |
|---|---|
| La mutation givePokemon existe ? | ✅ `GameStateMutations.givePokemon` |
| Elle est générique ? | ✅ Aucun id Selbrume |
| Elle ajoute à la party ? | ✅ Testé |
| Elle préserve le reste ? | ✅ bag, flags, map, position, progression |
| Anti-doublon optionnel ? | ✅ `preventDuplicateSpecies` |
| No-op si speciesId vide ? | ✅ Testé |
| Save/load round-trip ? | ✅ Testé |
| Action narrative runtime ? | ✅ `kScenarioActionGivePokemon` |
| Action testée ? | ✅ 4 tests scénario |
| Tests gameplay passent ? | ✅ 16/16 |
| Tests runtime passent ? | ✅ 4/4 |
| Analyze clean ? | ✅ 0 nouveau warning |
| road_map.md mis à jour ? | ✅ |
| Rapport créé ? | ✅ |
| createNewGameState inchangé ? | ✅ Party toujours vide |
| Aucune fixture Selbrume ? | ✅ |
| Prochain lot : NS-GS-07 ? | ✅ |
| Dette identifiée ? | ⚠️ Limite party 6 max non modélisée. currentHp=1 arbitraire. |

---

*Fin du document NS-GS-06.*
