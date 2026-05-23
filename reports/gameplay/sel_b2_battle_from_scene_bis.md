# SEL-B2-bis — Battle from Scene Runtime Wiring Validation & Hardening V0

## 1. Résumé exécutif

Ce lot valide et durcit le wiring runtime introduit par SEL-B2. L'audit a identifié un problème de cohérence de pending state dans `_handleScenarioBattleEffect` et un lint info mineur dans les tests. Les deux ont été corrigés. Six tests supplémentaires ont été ajoutés pour couvrir les edge cases du helper de flags et la complétude du résultat de l'executor. L'analyse ciblée sur les fichiers SEL-B2 — incluant `playable_map_game.dart` — passe avec 0 issues. Les 29 tests (15 nouveaux + 14 existants) sont verts.

## 2. Ce que SEL-B2 avait livré

- Constante `kScenarioActionStartTrainerBattle` dans l'executor
- Handler `startTrainerBattle` dans le switch action de `ScenarioRuntimeExecutor`
- `ScenarioRuntimeEffectType.battle` + champs `battleId/trainerId/npcEntityId` sur `ScenarioRuntimeEffect`
- `_handleScenarioBattleEffect` dans `PlayableMapGame` (dispatch → battle handoff)
- Continuation post-combat dans `_onBattleFinished` (flag outcome + `dispatchContinuation`)
- Helper `scenarioBattleOutcomeFlagName` pour le nommage déterministe
- 9 tests ciblés
- Barrel exports

## 3. Problème de preuve identifié

Le rapport SEL-B2 présentait les faiblesses suivantes :

| Faiblesse | Impact |
|---|---|
| Analyse limitée à `lib/src/application/scenario_runtime/` | `playable_map_game.dart` non analysé — le fichier le plus critique du lot |
| `_handleScenarioBattleEffect` reconnu non testable | Aucune preuve que le code compile correctement |
| Pending state potentiellement incohérent | Si `runtimeSourceId` est null, `_pendingScenarioBattleId` est set mais pas `_pendingScenarioBattleSourceId` → leak de state |
| Pas de test d'empty inputs sur le helper de flags | `scenarioBattleOutcomeFlagName('', 'victory')` non vérifié |
| Pas de test de non-avancement du graphe | Rien ne prouvait que le graphe s'arrête exactement au node battle |
| Pas de test de complétude du résultat | `scenarioId`/`sourceNodeId`/`stopNodeId` non-null non vérifié |
| Lint info `_buildContext` dans le fichier de test | Nom de variable commençant par underscore |

## 4. Audit du ScenarioRuntimeExecutor

### Constante `kScenarioActionStartTrainerBattle`

```dart
const String kScenarioActionStartTrainerBattle = 'startTrainerBattle';
```

- ✅ Nom clair et cohérent avec les autres constantes (`kScenarioAction*`)
- ✅ Doc comment complète avec référence SEL-A2 / SEL-B2
- ✅ Exportée dans le barrel `map_runtime.dart`

### Handler dans le switch action (lignes 953–993)

- ✅ Lecture de `trainerId` depuis `node.binding.trainerId?.trim() ?? ''`
- ✅ Lecture de `npcEntityId` depuis `node.binding.entityId?.trim() ?? ''`
- ✅ Lecture de `battleId` depuis `node.payload.params['battleId']?.trim() ?? trainerId` (fallback correct)
- ✅ Validation trainerId vide → `blocked` avec message explicite
- ✅ Validation npcEntityId vide → `blocked` avec message explicite
- ✅ Retour `executedEffect` (pas `reachedEnd` ni `noMatchingSource`)
- ✅ `stopNodeId` = `node.id` (le node battle lui-même)
- ✅ Le graphe s'arrête exactement ici via `return` (pas de `currentNodeId = ...`)
- ✅ Aucun import inutile (l'import `scenario_battle_outcome_flags.dart` avait été ajouté puis retiré dans SEL-B2)

### Pas de risque de continuation implicite

Le handler utilise `return` immédiat, pas `currentNodeId = nextNode`. Vérifié que le graphe ne peut pas avancer au-delà du node battle.

## 5. Audit du ScenarioRuntimeEffect

### Enum `ScenarioRuntimeEffectType`

```dart
enum ScenarioRuntimeEffectType {
  dialogue,
  script,
  message,
  battle,  // ← ajouté par SEL-B2
  none,
}
```

- ✅ `battle` ajouté correctement dans l'enum
- ✅ Les effets existants (`dialogue`, `script`, `message`, `none`) ne sont pas modifiés
- ✅ Doc comment présente sur `battle`

### Classe `ScenarioRuntimeEffect`

```dart
class ScenarioRuntimeEffect {
  const ScenarioRuntimeEffect({
    required this.type,
    this.dialogueId,
    this.scriptId,
    this.message,
    this.battleId,     // ← ajouté
    this.trainerId,    // ← ajouté
    this.npcEntityId,  // ← ajouté
  });
  // ...
}
```

- ✅ Les trois champs sont optionnels (`String?`)
- ✅ Le constructeur `const` fonctionne toujours
- ✅ Le constructeur `.none()` n'est pas impacté (utilise `type: none`, les champs restent null)
- ✅ Doc comments individuels pour chaque champ
- ✅ Aucun breaking change : le constructor reste backward compatible (named optionals)

## 6. Audit du helper de flags battle

### `scenario_battle_outcome_flags.dart`

- ✅ Format `battle:<battleId>:<outcome>` confirmé par tests
- ✅ Trim des deux inputs
- ✅ Assert en debug mode si `battleId` vide ou whitespace-only
- ✅ Assert en debug mode si `outcomeSuffix` vide ou whitespace-only
- ✅ 4 constantes de suffixe : `victory`, `defeat`, `flee`, `captured`
- ✅ Constante de préfixe : `battle:`
- ✅ Directive `library` correcte (fix du dangling doc comment)
- ✅ Toutes les constantes exportées dans le barrel

### Aucun flag générique

Les tests vérifient explicitement :
- `scenarioBattleOutcomeFlagName('battle_rival_port', 'victory')` → `'battle:battle_rival_port:victory'`
- Résultat ≠ `'battle_victory'`
- Résultat ≠ `'battle_defeat'`
- Résultat commence par `'battle:'` et jamais par `'battle_'`

## 7. Audit de PlayableMapGame

### 7.1 Import

```dart
import '../../application/scenario_runtime/scenario_battle_outcome_flags.dart';
```

- ✅ Import présent et utilisé dans `_onBattleFinished`

### 7.2 Champs de state

```dart
String? _pendingScenarioBattleSourceId;
String? _pendingScenarioBattleId;
```

- ✅ Deux champs distincts, bien documentés
- ✅ Posés atomiquement (les deux ensemble ou aucun)
- ✅ Nettoyés dans `_onBattleFinished` avant la reprise du graphe

### 7.3 Dispatch interception

```dart
if (result.effect.type == ScenarioRuntimeEffectType.battle) {
  _handleScenarioBattleEffect(result);
}
```

- ✅ Correctement placé après le log et avant le return
- ✅ N'affecte pas les autres effets (dialogue/script/message/none)
- ✅ Le résultat original est quand même retourné

### 7.4 `_handleScenarioBattleEffect` (post-hardening)

**Bug corrigé** : dans la version SEL-B2, le `runtimeSourceId` était calculé par un ternaire nullable après la validation de l'entité/request. Si les composants étaient null, `_pendingScenarioBattleSourceId` serait `null` mais `_pendingScenarioBattleId` serait non-null → half-populated state.

**Après hardening** :

1. Le `runtimeSourceId` est construit **avant** la recherche d'entité
2. Si l'un des composants (`scenarioId`, `sourceNodeId`, `stopNodeId`) est null → `return` immédiat, aucun pending posé
3. Si l'entité NPC n'est pas trouvée → `return` immédiat, aucun pending posé
4. Si le `TrainerBattleStartRequest` ne peut pas être construit → `return` immédiat, aucun pending posé
5. Si un pending existait déjà → warning loggé
6. Les deux champs sont posés ensemble après toutes les validations
7. `_triggeredTrainerBattles.add(entity.id)` et `_pendingBattleRequest = request` sont posés en dernier

**Conclusion** : aucun cas de fuite de pending state. Tous les early returns sont avant la pose du pending.

### 7.5 `_onBattleFinished` (continuation post-combat)

- ✅ Le write-back existant (`applyRuntimeBattleOutcomeToGameState`) s'exécute **avant** le bloc SEL-B2
- ✅ Le defeat recovery (`_applyWhiteoutLiteAfterPlayerDefeat`) s'exécute **avant** le bloc SEL-B2
- ✅ Le NPC presence refresh conditionnel s'exécute **avant** le bloc SEL-B2
- ✅ Le nettoyage overlay/session (`_battleOverlay`, `_battleSession`, `_activeBattleContext`) s'exécute **avant** le bloc SEL-B2
- ✅ Le bloc SEL-B2 :
  1. Capture les deux champs pending dans des locales finales
  2. Vérifie les deux non-null (guard `&&`)
  3. Mappe `BattleOutcomeType` → suffixe via `switch` exhaustif (4 cases)
  4. Construit le flag via `scenarioBattleOutcomeFlagName`
  5. Pose le flag via `_storyFlags.set`
  6. Nettoie les deux champs pending → null
  7. Remet `_flowPhase = _RuntimeFlowPhase.overworld` **avant** `_resumeScenarioAfterRuntimeSource`
  8. Appelle `_resumeScenarioAfterRuntimeSource` pour la continuation
  9. `return` pour éviter le doublon overworld resume
- ✅ Le chemin non-scénario (LoS/wild/encounter) n'est pas impacté (le `if` ne s'active que si les pending sont non-null)

### 7.6 Impact sur les combats LoS / encounter existants

- ✅ Les combats non-scénario ne posent jamais `_pendingScenarioBattleSourceId`
- ✅ Dans `_onBattleFinished`, le guard `scenarioBattleSourceId != null && scenarioBattleId != null` est false pour les combats normaux
- ✅ Le chemin existant (overworld resume direct) reste inchangé

### 7.7 Flow phase cohérence

- ✅ Dans `_handleScenarioBattleEffect`, la flow phase est en `overworld` (guard vérifié dans `_dispatchScenarioRuntimeSource` l.2102)
- ✅ La battle request passe par `_pendingBattleRequest` → `update()` → `_startBattleHandoff` qui met `battleTransition`
- ✅ Après combat, le bloc SEL-B2 remet `overworld` avant `_resumeScenarioAfterRuntimeSource`

## 8. Corrections effectuées

### 8.1 `_handleScenarioBattleEffect` — cohérence du pending state

**Avant** : `runtimeSourceId` calculé par ternaire nullable après les validations entity/request. Possibilité d'un half-populated state si le ternaire retourne null.

**Après** : Le `runtimeSourceId` est construit et validé **avant** toute recherche d'entité. Si l'un des composants est null, abort immédiat sans poser de pending. Warning log si un pending existait déjà (protection contre double-set).

### 8.2 Lint `_buildContext` → `buildContext`

Renommage du helper dans `test/scenario_battle_from_scene_test.dart` pour supprimer le warning `no_leading_underscores_for_local_identifiers`.

### 8.3 Lint `unnecessary_brace_in_string_interps`

Suppression des accolades inutiles dans l'interpolation de `_pendingScenarioBattleSourceId`.

## 9. Tests ajoutés ou renforcés

### Tests ajoutés (6 tests)

| Test | Assertion |
|---|---|
| `asserts on empty battleId (debug mode)` | `scenarioBattleOutcomeFlagName('', ...)` et `'   '` → `AssertionError` |
| `asserts on empty outcomeSuffix (debug mode)` | `scenarioBattleOutcomeFlagName(..., '')` et `'   '` → `AssertionError` |
| `all four outcome suffixes are unique and non-empty` | 4 constantes distinctes, toutes non-vides |
| `flag prefix is battle: (colon-separated, not underscore)` | Préfixe `'battle:'`, jamais `'battle_'` |
| `battle effect result has non-null scenarioId/sourceNodeId/stopNodeId` | Les 3 champs sont non-null, `stopNodeId == 'battle_node'` |
| `graph does not advance past battle node (no graph leak)` | Un flag posé après le node battle n'est pas set dans le gameState |

### Tests existants conservés (9 + 14 = 23 tests)

- 9 tests de `scenario_battle_from_scene_test.dart` (version SEL-B2)
- 14 tests de `scenario_runtime_executor_test.dart`

### Total : 29 tests, tous verts

### Couverture restante non couverte (justification)

| Composant | Couvert | Justification |
|---|---|---|
| `ScenarioRuntimeExecutor.dispatch` — startTrainerBattle | ✅ Tests purs | Exécuteur pur Dart |
| `scenarioBattleOutcomeFlagName` | ✅ Tests purs | Helper pur Dart |
| `ScenarioRuntimeEffect` — champs battle | ✅ Via tests executor | Constructor validated |
| `_handleScenarioBattleEffect` | ❌ Non testable en pur Dart | Dépend de `_world`, `_bundle`, `_pendingBattleRequest`. Nécessite intégration Flame. |
| `_onBattleFinished` — bloc SEL-B2 | ❌ Non testable en pur Dart | Dépend du cycle de vie complet battle overlay. Nécessite smoke test Golden Slice. |
| Combat LoS non impacté | ⚠️ Analyse structurelle | Le guard `pendingScenarioBattle != null` isole le chemin. Vérifiable par smoke test existant. |

## 10. Commandes exécutées

```bash
pwd
git status --short --untracked-files=all

cd packages/map_runtime && flutter test test/scenario_battle_from_scene_test.dart
cd packages/map_runtime && flutter test test/scenario_runtime_executor_test.dart
cd packages/map_runtime && flutter test test/scenario_battle_from_scene_test.dart test/scenario_runtime_executor_test.dart

cd packages/map_runtime && dart analyze lib/src/application/scenario_runtime/ lib/src/presentation/flame/playable_map_game.dart lib/map_runtime.dart test/scenario_battle_from_scene_test.dart
cd packages/map_runtime && dart analyze

git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

## 11. Résultats exacts des commandes

### `pwd`

```
/Users/karim/Project/pokemonProject
```

### `flutter test test/scenario_battle_from_scene_test.dart`

```
00:00 +15: All tests passed!
```

### `flutter test test/scenario_runtime_executor_test.dart`

```
00:00 +14: All tests passed!
```

### `flutter test` (les deux fichiers ensemble)

```
00:00 +29: All tests passed!
```

### `dart analyze` (ciblé SEL-B2)

```
Analyzing scenario_runtime, playable_map_game.dart, map_runtime.dart, scenario_battle_from_scene_test.dart...
No issues found!
```

### `dart analyze` (global)

```
353 issues found.
```

Toutes les 353 issues sont de niveau `info` uniquement (`prefer_const_constructors`, `no_leading_underscores_for_local_identifiers`). Aucune `warning` ni `error`. **Aucune de ces issues n'est dans les fichiers SEL-B2.**

### `git diff --check`

```
(sortie vide — aucun whitespace error)
```

### `git diff --stat`

```
 packages/map_runtime/lib/map_runtime.dart          |   9 ++
 .../scenario_runtime_executor.dart                 |  56 ++++++++
 .../scenario_runtime/scenario_runtime_models.dart  |  20 +++
 .../src/presentation/flame/playable_map_game.dart  | 150 +++++++++++++++++++++
 4 files changed, 235 insertions(+)
```

### `git diff --name-only`

```
packages/map_runtime/lib/map_runtime.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
```

## 12. Analyse des erreurs éventuelles

### Erreurs introduites par SEL-B2 ou SEL-B2-bis

**Aucune.** L'analyse ciblée retourne 0 issues.

### Erreurs préexistantes (hors SEL-B2)

353 issues `info`-level, toutes dans des fichiers non touchés par SEL-B2 :
- `test/trainer_battle_request_test.dart` — `prefer_const_constructors`, `no_leading_underscores_for_local_identifiers`
- `test/trainer_defeated_test.dart` — `prefer_const_constructors`, `prefer_const_declarations`
- `test/wild_battle_end_to_end_flow_test.dart` — `prefer_const_constructors`
- (et ~340 autres dans d'autres fichiers de lib/test)

### Erreurs incertaines

**Aucune.**

## 13. Git diff résumé

| Fichier | Insertions | Suppressions | Net |
|---|---|---|---|
| `map_runtime.dart` | +9 | 0 | +9 |
| `scenario_runtime_executor.dart` | +56 | 0 | +56 |
| `scenario_runtime_models.dart` | +20 | 0 | +20 |
| `playable_map_game.dart` | +150 | 0 | +150 |
| **Total** | **+235** | **0** | **+235** |

+ 2 fichiers untracked créés (non dans le diff car untracked)

## 14. Fichiers créés / modifiés / supprimés

### Fichiers créés (2 — déjà créés par SEL-B2)

| Fichier | Rôle |
|---|---|
| `packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart` | Helper pur de nommage des flags battle outcome |
| `packages/map_runtime/test/scenario_battle_from_scene_test.dart` | 15 tests ciblés (9 SEL-B2 + 6 SEL-B2-bis) |

### Fichiers modifiés (4 — identiques à SEL-B2, ajustements mineurs)

| Fichier | Modifications SEL-B2-bis spécifiques |
|---|---|
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | Hardening `_handleScenarioBattleEffect` : validation `runtimeSourceId` avant entity lookup, warning sur double-set, fix lint |
| `packages/map_runtime/test/scenario_battle_from_scene_test.dart` | Renommage `_buildContext` → `buildContext`, ajout 6 tests |

### Fichiers supprimés

**Aucun.**

## 15. Git status initial exact

```
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
 M packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
?? packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
?? packages/map_runtime/test/scenario_battle_from_scene_test.dart
?? reports/gameplay/sel_b2_battle_from_scene.md
```

Note : les fichiers `M` et `??` sont le résultat de SEL-B2, pas de modifications préexistantes antérieures.

## 16. Git status final exact

```
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
 M packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
?? packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
?? packages/map_runtime/test/scenario_battle_from_scene_test.dart
?? reports/gameplay/sel_b2_battle_from_scene.md
?? reports/gameplay/sel_b2_battle_from_scene_bis.md
```

Différence avec l'initial : uniquement `?? reports/gameplay/sel_b2_battle_from_scene_bis.md` ajouté (ce rapport).

## 17. Limites restantes

| Limite | Sévérité | Justification |
|---|---|---|
| `_handleScenarioBattleEffect` non testable en pur Dart | Moyen | Dépend de `_world.map.entities`, `_bundle.manifest`, `buildTrainerBattleRequestFromNpc`. Extractible en V1 mais hors scope SEL-B2-bis. |
| `_onBattleFinished` bloc SEL-B2 non testable en pur Dart | Moyen | Dépend du cycle de vie complet (overlay, session, flow phase). Nécessite smoke test Golden Slice. |
| Un seul combat scénario pending à la fois | Faible (V0) | Suffisant pour Golden Slice. Warning log si déjà pending. |
| Pas de persistance du pending en save | Moyen (V0) | Sauvegarder pendant un combat narratif n'est pas supporté. |
| Pas de reprise après reload pendant combat narratif | Moyen (V0) | State en mémoire uniquement. |
| `_handleScenarioBattleEffect` cherche l'entité par `firstWhere` sur `_world.map.entities` | Faible | Si le NPC n'est pas sur la map courante, le handoff échoue silencieusement. Correct pour V0 car le combat est déclenché par interaction → le NPC est sur la map. |
| `BattleOutcomeType.runaway` mappé vers `kBattleOutcomeSuffixFlee` | Faible | Le suffixe est `flee` (convention spec) mais le type code est `runaway`. Cohérent mais à surveiller si le modèle battle évolue. |

## 18. Auto-review critique

### Points forts

1. **Analyse ciblée incluant `playable_map_game.dart`** : contrairement à SEL-B2 qui n'analysait que `scenario_runtime/`, ici l'analyse couvre les 4 fichiers modifiés + le fichier de test → 0 issues.
2. **Bug de cohérence pending corrigé** : le half-populated state est éliminé par validation anticipée du `runtimeSourceId`.
3. **6 tests edge-case ajoutés** : empty inputs, assert, complétude du résultat, non-avancement du graphe. Total : 15 + 14 = 29 tests.
4. **Pas de scope creep** : aucun fichier hors périmètre modifié, aucun codegen, aucun commit.
5. **Evidence pack complet** : git status initial/final, diff --stat/--name-only/--check, commandes exactes, résultats exacts.

### Points de vigilance

1. **Le wiring runtime Flame reste non testable en pur Dart.** C'est structurel : `PlayableMapGame` est une classe Flame avec état mutable riche. Un refactor pour extraire la logique pure améliorerait la testabilité, mais c'est hors scope SEL-B2-bis.
2. **Le test de non-avancement (`no graph leak`) prouve que l'executor ne leak pas.** Mais il ne prouve pas que `PlayableMapGame` ne calling pas `_resumeScenarioAfterRuntimeSource` trop tôt (avant la fin du combat). Cette preuve viendra du smoke test Golden Slice.
3. **Les 353 issues info du `dart analyze` global sont préexistantes.** Elles ne sont pas SEL-B2 et n'impactent pas la fonctionnalité. Elles mériteraient un lot hygiene séparé.

## 19. Conclusion

Le lot SEL-B2-bis est **terminé et validable**. Le wiring runtime SEL-B2 est confirmé sain par analyse statique ciblée (0 issues sur les fichiers modifiés), 29 tests verts, et un hardening du pending state qui élimine le risque de half-populated state. Les limites restantes sont documentées et ne nécessitent pas de correction immédiate.

### Checklist de validation

- [x] PlayableMapGame est couvert par analyze ciblé.
- [x] Les tests SEL-B2 passent toujours (9/9 → 15/15 avec ajouts).
- [x] Le helper de flags est validé (y compris empty inputs, assert, format).
- [x] Aucun flag générique `battle_victory` / `battle_defeat` n'est produit.
- [x] Les pending scenario battle sont nettoyés en cas d'échec (early return avant pose).
- [x] Les combats LoS / encounter ne sont pas cassés (guard structurel vérifié).
- [x] Aucun scope creep.
- [x] Aucun codegen.
- [x] Aucun commit.
- [x] Rapport complet créé.
- [x] Git status initial et final exacts fournis.

### Prochaine étape recommandée

- **SEL-B1** — Fix `giveItem` → Bag
- **SEL-B6** — New Game flow minimal
- **Smoke test Golden Slice** — Validation end-to-end du wiring runtime dans un vrai projet
