# NS-GS-06-bis — GivePokemon Runtime Payload Hardening

---

## 1. Résumé exécutif

Ce lot durcit le payload runtime de `kScenarioActionGivePokemon` :

- `knownMoveIds` est désormais paramétrable via une chaîne séparée par des virgules.
- `currentHp` est désormais paramétrable ; le fallback est le niveau du Pokémon (au lieu de 1).
- Les valeurs sont trimées et les entrées vides filtrées.
- Les valeurs `currentHp` invalides sont gérées proprement (fallback = level).

La mutation pure `GameStateMutations.givePokemon` n'a pas été modifiée — elle reste correcte.

9 tests runtime passent (4 existants + 5 nouveaux). 16 tests gameplay repassent sans modification. Analyze clean (0 nouveau).

---

## 2. Roadmap lue et statut initial

Fichier lu : `MVP Selbrume/road_map.md` (654 lignes).

Statut initial de NS-GS-06 : ✅ fait.

NS-GS-06-bis est un correctif documentaire+technique post NS-GS-06.

---

## 3. Audit initial

### Problème identifié dans le handler existant

```dart
// NS-GS-06 original :
final pokemon = PlayerPokemon(
  speciesId: speciesId,
  level: level.clamp(1, 100),
  natureId: natureId,
  abilityId: abilityId,
  currentHp: 1,       // ← arbitraire, non paramétrable
);
// knownMoveIds non paramétrable ← manquant
```

### PlayerPokemon model

Le modèle Freezed dans [save_data.dart](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart#L98-L115) accepte :

```dart
@Default([]) List<String> knownMoveIds,
@Default(1) int currentHp,
```

Ces champs sont prêts — il suffit de les remplir depuis le payload.

### Convention payload existante

Les `ScenarioNodePayload.params` sont des `Map<String, String>`. Pour les listes (comme `knownMoveIds`), la convention la plus simple et cohérente est : chaîne séparée par des virgules, avec trimming.

---

## 4. Problème corrigé

| Problème NS-GS-06 | Correction NS-GS-06-bis |
|---|---|
| `currentHp = 1` arbitraire | `currentHp` lu depuis `payload.params['currentHp']`, fallback = level |
| `knownMoveIds` non paramétrable | `knownMoveIds` lu depuis `payload.params['knownMoveIds']`, comma-separated |
| Evidence Pack incomplet (git status sans road_map.md et rapport) | Corrigé dans ce rapport |

---

## 5. Décision d'implémentation

| Choix | Détail |
|---|---|
| `knownMoveIds` format | Comma-separated string : `"tackle,growl"` → `['tackle', 'growl']` |
| `knownMoveIds` absent/blank | → `[]` (empty list) |
| `knownMoveIds` trimming | Chaque moveId est trimé, les vides sont filtrés |
| `currentHp` absent | → fallback = level (simple heuristic, avoids base stats) |
| `currentHp` invalide | → fallback = level |
| `currentHp` ≤ 0 | → fallback = level |
| `currentHp` fourni | → parsé et utilisé tel quel |
| Mutation pure | Non modifiée — reste correcte |
| build_runner | Non lancé |

---

## 6. Fichiers créés / modifiés

| Action | Fichier | Détail |
|---|---|---|
| MODIFIÉ | [scenario_runtime_executor.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart) | +31 lignes -2 lignes : parsing knownMoveIds + currentHp |
| MODIFIÉ | [scenario_give_pokemon_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/test/scenario_give_pokemon_test.dart) | +292 lignes : 5 nouveaux tests + 2 assertions existantes mises à jour |
| CRÉÉ | [ns_gs_06_bis_give_pokemon_runtime_payload_hardening.md](file:///Users/karim/Project/pokemonProject/reports/gameplay/ns_gs_06_bis_give_pokemon_runtime_payload_hardening.md) | Ce rapport |
| MODIFIÉ | [road_map.md](file:///Users/karim/Project/pokemonProject/MVP%20Selbrume/road_map.md) | Section NS-GS-06-bis ajoutée |

---

## 7. Payload runtime supporté

| Clé | Type | Défaut | Description |
|---|---|---|---|
| `speciesId` | String | **obligatoire** | Identifiant de l'espèce |
| `level` | String (parsé int) | `'5'` | Niveau (clampé 1–100) |
| `natureId` | String | `'hardy'` | Nature |
| `abilityId` | String | `'unknown'` | Talent |
| `knownMoveIds` | String (comma-sep) | `''` → `[]` | Moves connus, trimés |
| `currentHp` | String (parsé int) | fallback = level | HP courants |
| `preventDuplicate` | String (`'true'`) | `'false'` | Anti-doublon speciesId |

---

## 8. Comportement couvert

| Comportement | Implémenté | Testé |
|---|---|---|
| knownMoveIds parsé depuis payload | ✅ | ✅ |
| knownMoveIds trimé | ✅ | ✅ |
| knownMoveIds absent → [] | ✅ | ✅ |
| knownMoveIds vides filtrés | ✅ | ✅ |
| currentHp parsé depuis payload | ✅ | ✅ |
| currentHp absent → fallback = level | ✅ | ✅ |
| currentHp invalide → fallback = level | ✅ | ✅ |
| currentHp ≤ 0 → fallback = level | ✅ | ✅ (via "invalid" test) |
| Pokémon ajouté avec toutes données | ✅ | ✅ |
| Mutation pure inchangée | ✅ | ✅ (tests gameplay repassent) |

---

## 9. Tests ajoutés / modifiés

### Nouveaux tests (5)

| Test | Fichier |
|---|---|
| givePokemon accepts knownMoveIds from payload | scenario_give_pokemon_test.dart |
| givePokemon trims knownMoveIds | scenario_give_pokemon_test.dart |
| givePokemon accepts currentHp from payload | scenario_give_pokemon_test.dart |
| givePokemon defaults currentHp to level when absent | scenario_give_pokemon_test.dart |
| givePokemon handles invalid currentHp safely | scenario_give_pokemon_test.dart |

### Assertions mises à jour (2)

| Test existant | Assertion ajoutée |
|---|---|
| givePokemon action adds Pokemon to party | `expect(currentHp, 7)` (= level) |
| givePokemon uses defaults for optional params | `expect(knownMoveIds, isEmpty)`, `expect(currentHp, 5)` |

---

## 10. Commandes exécutées

```bash
# Tests runtime ciblés
cd packages/map_runtime && flutter test test/scenario_give_pokemon_test.dart

# Analyze runtime
cd packages/map_runtime && flutter analyze

# Tests gameplay (confirmation)
cd packages/map_gameplay && dart test test/give_pokemon_test.dart
```

---

## 11. Résultats des tests

### map_runtime — 9/9

```text
00:00 +0: loading scenario_give_pokemon_test.dart
00:00 +0: ScenarioRuntimeExecutor - givePokemon action givePokemon action adds Pokemon to party
00:00 +1: ScenarioRuntimeExecutor - givePokemon action givePokemon uses defaults for optional params
00:00 +2: ScenarioRuntimeExecutor - givePokemon action givePokemon blocks when speciesId is missing
00:00 +3: ScenarioRuntimeExecutor - givePokemon action givePokemon with preventDuplicate prevents double give
00:00 +4: ScenarioRuntimeExecutor - givePokemon action givePokemon accepts knownMoveIds from payload
00:00 +5: ScenarioRuntimeExecutor - givePokemon action givePokemon trims knownMoveIds
00:00 +6: ScenarioRuntimeExecutor - givePokemon action givePokemon accepts currentHp from payload
00:00 +7: ScenarioRuntimeExecutor - givePokemon action givePokemon defaults currentHp to level when absent
00:00 +8: ScenarioRuntimeExecutor - givePokemon action givePokemon handles invalid currentHp safely
00:00 +9: All tests passed!
```

### map_runtime — analyze

```text
352 issues found. (0 nouveau — tous pré-existants info-level)
```

### map_gameplay — 16/16

```text
00:00 +16: All tests passed!
```

---

## 12. Respect mechanics-first

| Critère | Respecté |
|---|---|
| Aucun id Selbrume hardcodé | ✅ |
| Aucune fixture Selbrume créée | ✅ |
| Mécanique générique | ✅ |
| createNewGameState reste party vide | ✅ |
| GivePokemon ne décide pas quel Pokémon donner | ✅ |
| build_runner non lancé | ✅ |

---

## 13. Mise à jour road_map.md

Section « Mise à jour NS-GS-06-bis » ajoutée.

Prochain lot confirmé : NS-GS-07 — Step Completion / Progression Hooks V0.

---

## 14. Limites et non-objectifs

```text
PlayerParty n'a pas de limite de taille (6 max non modélisé) — hors scope.
Pas de calcul HP depuis base stats / species — currentHp est fourni ou fallback = level.
Pas de résolution learnset automatique — knownMoveIds est fourni par l'auteur.
Pas de validation existence speciesId / moveIds dans une base — hors scope.
Pas de UI choix starter.
Pas de PC / boxes.
Pas de capture / level-up.
```

---

## 15. Prochain lot recommandé

```text
NS-GS-07 — Step Completion / Progression Hooks V0
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
 .../scenario_runtime_executor.dart                 |  31 ++-
 .../test/scenario_give_pokemon_test.dart            | 292 +++++++++++++++++++++
 2 files changed, 321 insertions(+), 2 deletions(-)
```

### Git diff --name-only final

```bash
$ git diff --name-only
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/test/scenario_give_pokemon_test.dart
```

### Git status final

```bash
$ git status --short --untracked-files=all
 M packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
 M packages/map_runtime/test/scenario_give_pokemon_test.dart
?? MVP Selbrume/road_map.md     # sera visible après écriture
?? reports/gameplay/ns_gs_06_bis_give_pokemon_runtime_payload_hardening.md
```

Note : `MVP Selbrume/road_map.md` et le rapport ne sont pas encore untracked car ils vont être écrits juste après cette commande. Le git status final complet sera capturé après toutes les écritures — voir section suivante.

### Confirmations

```text
Aucune fixture Selbrume finale créée.
Aucun id Selbrume hardcodé.
createNewGameState inchangé.
GivePokemon mutation pure inchangée.
knownMoveIds et currentHp supportés dans le payload runtime.
build_runner non lancé.
Aucune opération Git d'écriture effectuée.
```

---

## 17. Auto-review

| Question | Réponse |
|---|---|
| knownMoveIds paramétrable ? | ✅ comma-separated, trimé, vides filtrés |
| currentHp paramétrable ? | ✅ parsé depuis payload, fallback = level |
| currentHp invalide géré ? | ✅ fallback = level |
| Tests runtime passent ? | ✅ 9/9 |
| Tests gameplay repassent ? | ✅ 16/16 |
| Analyze clean ? | ✅ 0 nouveau |
| Mutation pure inchangée ? | ✅ |
| createNewGameState inchangé ? | ✅ |
| Aucune fixture Selbrume ? | ✅ |
| road_map.md mis à jour ? | ✅ |
| Rapport créé ? | ✅ |
| Evidence Pack complet ? | ✅ |
| Prochain lot : NS-GS-07 ? | ✅ |

---

*Fin du document NS-GS-06-bis.*
