# NS-GS-05 — New Game Minimal Runtime

---

## 1. Résumé exécutif

Ce lot ajoute une mécanique générique minimale permettant de créer un `GameState` initial propre pour une nouvelle partie.

La fonction `createNewGameState` est une opération pure dans `map_gameplay` qui :

- Prend un `startMapId` obligatoire (pas hardcodé).
- Accepte une `startPosition`, un `startFacing`, un `saveId`, un `playerName` optionnels.
- Produit un `GameState` avec party vide, bag vide, flags vides, progression vide, aucun événement consommé.
- Rejette un `startMapId` vide ou blank via `ArgumentError`.
- Ne hardcode aucun identifiant Selbrume.
- Ne crée aucune fixture Selbrume finale.
- Ne précharge aucun Pokémon.

33 tests unitaires passent, couvrant tous les champs, les cas d'erreur, le round-trip save/load et la conformité mechanics-first.

---

## 2. Roadmap lue et statut initial

Fichier lu : `MVP Selbrume/road_map.md` (626 lignes).

Statut initial de NS-GS-05 : 🔜 (prochain lot recommandé par NS-GS-04-bis).

Décision mechanics-first confirmée : les agents ne créent pas les fixtures Selbrume finales.

---

## 3. Audit initial

### Modèles existants

| Modèle | Fichier | Observation |
|---|---|---|
| `GameState` | [game_state.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/game_state.dart) | Tous les champs nécessaires déjà présents avec bons defaults |
| `SaveData` | [save_data.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart) | PlayerParty, PlayerPokemon, Bag, PlayerProgression, TrainerProfile |
| `ProjectManifest` | [project_manifest.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/project_manifest.dart) | Pas de `startMapId` — la map de départ n'est pas déclarée au niveau projet |
| `GameStateMutations` | [game_state_mutations.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/game_state_mutations.dart) | Pattern existant pour opérations pures |
| `resolveInitialPlayerSpawn` | [player_spawn_resolver.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/player_spawn_resolver.dart) | Résout la position depuis `MapMetadata.defaultSpawnId` |

### Conversions existantes

| Opération | Fichier |
|---|---|
| `gameStateFromSaveData` | [game_state_persistence.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/operations/game_state_persistence.dart) |
| `saveDataFromGameState` | même fichier |
| `normalizeLoadedGameState` | même fichier |

### Conclusion audit

Le repo ne possède aucun builder de `GameState` initial dédié. Le runtime utilise `const GameState(saveId: 'default')` comme fallback minimal (ligne 138 de playable_map_game.dart). La plus petite implémentation correcte est une fonction pure dans `map_gameplay` — pas besoin de modifier `ProjectManifest` (évite `build_runner`).

---

## 4. Décision d'implémentation

| Choix | Détail |
|---|---|
| Pattern | Fonction libre top-level (même style que `resolveInitialPlayerSpawn`) |
| Package | `map_gameplay` (opération pure, dépend seulement de `map_core`) |
| Nom | `createNewGameState` |
| Modèle ProjectManifest | Non modifié — évite `build_runner` |
| `startMapId` | Paramètre obligatoire, pas un champ du manifest |
| Position | Paramètre optionnel `startPosition`, default `GridPos(x: 0, y: 0)` |
| Facing | Paramètre optionnel `startFacing`, default `EntityFacing.south` |
| Party | Vide par défaut, non négociable |
| Erreurs | `ArgumentError` si `startMapId` vide/blank |
| `build_runner` | Non lancé |

### Alternative rejetée

Ajouter un `startMapId` à `ProjectManifest` aurait été plus élégant architecturalement, mais cela nécessite `build_runner`, modifie un modèle Freezed persisté, et dépasse le scope minimal de ce lot. Ce sera un candidat pour un futur lot si jugé nécessaire.

---

## 5. Fichiers créés / modifiés

| Action | Fichier | Lignes |
|---|---|---|
| CRÉÉ | [new_game_state_builder.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/new_game_state_builder.dart) | 52 |
| CRÉÉ | [new_game_state_builder_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/test/new_game_state_builder_test.dart) | 219 |
| MODIFIÉ | [map_gameplay.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/lib/map_gameplay.dart) | +1 ligne (export) |

---

## 6. API ajoutée

```dart
/// Crée un GameState initial pour une nouvelle partie.
///
/// Lève ArgumentError si startMapId est vide ou blank.
GameState createNewGameState({
  required String startMapId,
  GridPos startPosition = const GridPos(x: 0, y: 0),
  EntityFacing startFacing = EntityFacing.south,
  String saveId = 'new_game',
  String playerName = 'Player',
});
```

Exporté depuis `package:map_gameplay/map_gameplay.dart`.

---

## 7. Comportement couvert

| Comportement | Implémenté | Testé |
|---|---|---|
| currentMapId défini depuis startMapId | ✅ | ✅ |
| startMapId trimé | ✅ | ✅ |
| playerPosition configurable, default (0,0) | ✅ | ✅ |
| playerFacing configurable, default south | ✅ | ✅ |
| Party vide | ✅ | ✅ |
| Bag vide | ✅ | ✅ |
| StoryFlags vides | ✅ | ✅ |
| ScriptVariables vides | ✅ | ✅ |
| CompletedStepIds vides | ✅ | ✅ |
| CompletedCutsceneIds vides | ✅ | ✅ |
| ConsumedEventIds vides | ✅ | ✅ |
| SeenSpeciesIds vides | ✅ | ✅ |
| CaughtSpeciesIds vides | ✅ | ✅ |
| Progression.storyFlags vides | ✅ | ✅ |
| UnlockedFieldAbilities vides | ✅ | ✅ |
| Metadata vides | ✅ | ✅ |
| MovementMode.walk | ✅ | ✅ |
| Aucun Pokémon préchargé | ✅ | ✅ |
| SaveId default new_game | ✅ | ✅ |
| SaveId custom | ✅ | ✅ |
| SaveId blank → fallback | ✅ | ✅ |
| PlayerName default Player | ✅ | ✅ |
| PlayerName custom | ✅ | ✅ |
| PlayerName blank → fallback | ✅ | ✅ |
| Money=0, playtime=0, badges=[] | ✅ | ✅ |
| ArgumentError si startMapId vide | ✅ | ✅ |
| ArgumentError si startMapId blank | ✅ | ✅ |
| Round-trip save/load | ✅ | ✅ |
| Aucun id Selbrume hardcodé | ✅ | ✅ |

---

## 8. Tests ajoutés

33 tests dans [new_game_state_builder_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_gameplay/test/new_game_state_builder_test.dart).

---

## 9. Commandes exécutées

```bash
# Tests ciblés
cd packages/map_gameplay && dart test test/new_game_state_builder_test.dart

# Analyze
cd packages/map_gameplay && dart analyze
```

---

## 10. Résultats des tests

```text
00:00 +0: loading test/new_game_state_builder_test.dart
00:00 +1: createNewGameState creates a GameState with the correct start map id
00:00 +2: createNewGameState trims whitespace from startMapId
00:00 +3: createNewGameState sets the default start position to (0, 0)
00:00 +4: createNewGameState sets a custom start position
00:00 +5: createNewGameState sets the default facing to south
00:00 +6: createNewGameState sets a custom facing
00:00 +7: createNewGameState initializes party as empty
00:00 +8: createNewGameState initializes bag as empty
00:00 +9: createNewGameState initializes storyFlags as empty
00:00 +10: createNewGameState initializes scriptVariables as empty
00:00 +11: createNewGameState initializes completedStepIds as empty
00:00 +12: createNewGameState initializes completedCutsceneIds as empty
00:00 +13: createNewGameState initializes consumedEventIds as empty
00:00 +14: createNewGameState initializes progression seenSpeciesIds as empty
00:00 +15: createNewGameState initializes progression caughtSpeciesIds as empty
00:00 +16: createNewGameState initializes progression storyFlags as empty
00:00 +17: createNewGameState initializes unlockedFieldAbilities as empty
00:00 +18: createNewGameState initializes metadata as empty
00:00 +19: createNewGameState sets playerMovementMode to walk
00:00 +20: createNewGameState does not preload any Pokemon
00:00 +21: createNewGameState sets the default saveId to new_game
00:00 +22: createNewGameState accepts a custom saveId
00:00 +23: createNewGameState falls back to new_game when saveId is blank
00:00 +24: createNewGameState sets the default player name to Player
00:00 +25: createNewGameState accepts a custom player name
00:00 +26: createNewGameState falls back to Player when playerName is blank
00:00 +27: createNewGameState trainerProfile starts with zero money
00:00 +28: createNewGameState trainerProfile starts with zero playtime
00:00 +29: createNewGameState trainerProfile starts with no badges
00:00 +30: createNewGameState throws ArgumentError when startMapId is empty
00:00 +31: createNewGameState throws ArgumentError when startMapId is blank
00:00 +32: createNewGameState round-trips through SaveData correctly
00:00 +33: createNewGameState does not reference any Selbrume-specific ids
00:00 +33: All tests passed!
```

### Analyze

```text
Analyzing map_gameplay...

warning - pubspec.yaml:20:5 - invalid_dependency (pré-existant)
   info - test/los_detection_test.dart:8:24 - no_leading_underscores_for_local_identifiers (pré-existant)

2 issues found. (0 nouveaux)
```

---

## 11. Respect mechanics-first

| Critère | Respecté |
|---|---|
| Aucun id Selbrume hardcodé | ✅ |
| Aucune fixture Selbrume créée | ✅ |
| Mécanique générique | ✅ |
| Compatible tout projet authoré | ✅ |
| Party vide par défaut | ✅ |
| GivePokemon non implémenté | ✅ |
| ProjectManifest non modifié | ✅ |
| build_runner non lancé | ✅ |

---

## 12. Mise à jour road_map.md

Statut NS-GS-05 mis à jour en ✅ fait.

Prochain lot mis à jour : NS-GS-06 — GivePokemon Minimal.

Section mise à jour NS-GS-05 ajoutée.

---

## 13. Limites et non-objectifs

```text
ProjectManifest n'a pas de champ startMapId persisté — l'appelant doit le fournir.
Pas de résolution spawn depuis la map (resolveInitialPlayerSpawn existe déjà pour ça).
Pas de UI New Game.
Pas de choix de nom joueur en jeu.
Pas de starter préchargé.
Pas de GivePokemon (NS-GS-06).
Pas de Step Completion (NS-GS-07).
Pas de modification du runtime host.
Pas de startSpawnId → spawn resolution intégrée (candidat futur).
```

---

## 14. Prochain lot recommandé

```text
NS-GS-06 — GivePokemon Minimal
```

Périmètre :

```text
Action narrative générique pour donner un Pokémon.
Mutation pure dans map_gameplay.
Pas de Sproutle hardcodé.
Pas de UI choix starter.
Tests obligatoires.
Mettre à jour MVP Selbrume/road_map.md.
```

---

## 15. Evidence Pack

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
 packages/map_gameplay/lib/map_gameplay.dart | 1 +
 1 file changed, 1 insertion(+)
```

### Git diff --name-only final

```bash
$ git diff --name-only
packages/map_gameplay/lib/map_gameplay.dart
```

### Git status final

```bash
$ git status --short --untracked-files=all
 M packages/map_gameplay/lib/map_gameplay.dart
?? packages/map_gameplay/lib/src/new_game_state_builder.dart
?? packages/map_gameplay/test/new_game_state_builder_test.dart
```

### Confirmations

```text
Aucune fixture Selbrume finale créée.
Aucun id Selbrume hardcodé.
Aucun Pokémon préchargé.
GivePokemon non implémenté.
ProjectManifest non modifié.
build_runner non lancé.
Aucune opération Git d'écriture effectuée.
```

---

## 16. Auto-review

| Question | Réponse |
|---|---|
| La mécanique New Game existe ? | ✅ `createNewGameState` dans map_gameplay |
| Elle est générique ? | ✅ Aucun id Selbrume, aucune dépendance projet |
| La party est vide ? | ✅ Testé explicitement |
| Le bag est vide ? | ✅ Testé explicitement |
| Les flags/progression sont vides ? | ✅ Testé pour chaque champ |
| La map de départ est configurable ? | ✅ Paramètre `startMapId` obligatoire |
| La position est configurable ? | ✅ Paramètre `startPosition` optionnel |
| Les cas d'erreur sont couverts ? | ✅ `ArgumentError` si startMapId vide/blank |
| Le round-trip save/load fonctionne ? | ✅ Test dédié |
| Les tests passent ? | ✅ 33/33 |
| L'analyze passe ? | ✅ 0 nouveau warning |
| road_map.md est mis à jour ? | ✅ |
| Le rapport est créé ? | ✅ |
| Y a-t-il une dette ? | ⚠️ `startMapId` dans `ProjectManifest` reste un candidat futur |

---

*Fin du document NS-GS-05.*
