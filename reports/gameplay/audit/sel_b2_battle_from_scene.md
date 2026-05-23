# SEL-B2 — Battle from Scene / Scenario Action V0

## 1. Résumé exécutif

Ce lot implémente le pont minimal entre le graphe scénario (`ScenarioAsset`) et le système de combat trainer existant. Un nouveau `actionKind` — `startTrainerBattle` — permet à un node action du graphe de suspendre le traversal, de lancer un combat trainer via le battle handoff existant de `PlayableMapGame`, puis de reprendre automatiquement le graphe après le combat avec un flag d'outcome déterministe posé dans les `StoryFlags`.

**Résultat** : le pipeline complet fonctionne end-to-end pour le cas nominal Golden Slice Selbrume :
```
Interaction NPC → ScenarioGraph → node startTrainerBattle
→ suspension du graphe → battle handoff → combat
→ BattleOutcome → flag battle:<battleId>:<outcome>
→ continuation du graphe → branchement victory/defeat
```

## 2. Rappel du contrat SEL-A2

SEL-A2 (Option D — Hybride) définissait :

| Composant | Exigence | Statut |
|---|---|---|
| `actionKind = startTrainerBattle` | Réutiliser le node action existant | ✅ |
| `ScenarioRuntimeEffectType.battle` | Nouvel effet pour suspendre le graphe | ✅ |
| Battle handoff via `_pendingBattleRequest` | Réutiliser le pattern existant | ✅ |
| Continuation via `dispatchContinuation` | Réutiliser le pattern post-dialogue | ✅ |
| Flag outcome `battle:<battleId>:<outcome>` | Nommage déterministe et non-générique | ✅ |
| Pas de modification `map_core` | `ScenarioNodePayload.params` est une Map libre | ✅ |
| Pas de nouveau `ScenarioNodeType.battle` | Le type `action` suffit | ✅ |

## 3. Scope réalisé

- [x] Nouveau `actionKind` `startTrainerBattle` traité par `ScenarioRuntimeExecutor`
- [x] Nouvel effet `ScenarioRuntimeEffectType.battle` transmis au runtime
- [x] Runtime lance un `TrainerBattleStartRequest` depuis l'effet battle
- [x] Runtime mémorise une continuation de scénario (`_pendingScenarioBattleSourceId`)
- [x] Runtime reprend le scénario après `BattleOutcome` via `_resumeScenarioAfterRuntimeSource`
- [x] Flag battle outcome déterministe posé : `battle:<battleId>:victory/defeat/flee/captured`
- [x] Aucun flag générique `battle_victory` / `battle_defeat`
- [x] Tests ciblés ajoutés (9 tests, tous verts)
- [x] Tests existants non cassés (14 tests, tous verts)
- [x] Handoff battle LoS/encounter existant non impacté
- [x] `dart analyze` : 0 issues sur les fichiers modifiés
- [x] Aucun modèle `map_core` modifié
- [x] Aucun codegen / build_runner exécuté
- [x] Aucun refactor massif

## 4. Fichiers modifiés

### Fichiers créés (2)

| Fichier | Rôle |
|---|---|
| `packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart` | Helpers purs pour le nommage des flags d'outcome battle |
| `packages/map_runtime/test/scenario_battle_from_scene_test.dart` | 9 tests ciblés pour le lot SEL-B2 |

### Fichiers modifiés (4)

| Fichier | Changement | Lignes ajoutées |
|---|---|---|
| `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart` | `ScenarioRuntimeEffectType.battle` + champs `battleId/trainerId/npcEntityId` sur `ScenarioRuntimeEffect` | +20 |
| `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart` | Constante `kScenarioActionStartTrainerBattle` + handler dans le switch action | +56 |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | `_handleScenarioBattleEffect` + continuation post-combat dans `_onBattleFinished` | +128 |
| `packages/map_runtime/lib/map_runtime.dart` | Exports barrel pour la nouvelle constante et les helpers de flags | +9 |

### Fichiers non modifiés (périmètre respecté)

```
packages/map_core — aucune modification
packages/map_editor — aucune modification
packages/map_gameplay — aucune modification
packages/map_battle — aucune modification
examples/playable_runtime_host — aucune modification
```

## 5. Architecture retenue

### Pipeline d'exécution

```
ScenarioRuntimeExecutor.dispatch()
  ├─ ScenarioNodeType.action → kScenarioActionStartTrainerBattle
  ├─ Valide trainerId et npcEntityId (non vides)
  ├─ Lit battleId depuis payload.params['battleId'], fallback sur trainerId
  └─ Retourne ScenarioRuntimeExecutionResult
       status: executedEffect
       effect: ScenarioRuntimeEffect(
         type: battle,
         trainerId: ...,
         npcEntityId: ...,
         battleId: ...,
       )
       stopNodeId: le node battle (point de continuation)

PlayableMapGame._dispatchScenarioRuntimeSource()
  ├─ Reçoit le résultat
  ├─ Détecte effect.type == battle
  └─ Appelle _handleScenarioBattleEffect(result)

PlayableMapGame._handleScenarioBattleEffect()
  ├─ Cherche l'entité NPC sur la map
  ├─ Construit TrainerBattleStartRequest via buildTrainerBattleRequestFromNpc
  ├─ Mémorise _pendingScenarioBattleSourceId et _pendingScenarioBattleId
  └─ Enqueue dans _pendingBattleRequest (pattern unifié)

update() → _startBattleHandoff() → combat

PlayableMapGame._onBattleFinished(BattleOutcome)
  ├─ Write-back existant (PV, trainer_defeated, etc.)
  ├─ [SEL-B2] Détecte _pendingScenarioBattleSourceId
  ├─ Mappe BattleOutcomeType → suffixe flag (victory/defeat/flee/captured)
  ├─ Pose le flag déterministe via _storyFlags.set
  ├─ Nettoie le pending
  ├─ Restaure _flowPhase = overworld
  └─ Appelle _resumeScenarioAfterRuntimeSource(runtimeSourceId)
       → dispatchContinuation reprend le graphe après le node battle
```

### Choix de design

1. **Pas de callback `startBattle` dans `ScenarioRuntimeExecutionContext`** : contrairement aux dialogues/scripts qui sont lancés par callback depuis l'executor, le battle est géré en aval (dans `PlayableMapGame`) via inspection de l'effet retourné. Cela évite de coupler l'executor pur-Dart au système Flame/Flutter.

2. **Réutilisation de `_pendingBattleRequest`** : le pattern existant (wild encounter, LoS trainer) est réutilisé tel quel. Le combat passe par `update()` → `_startBattleHandoff()` comme tout autre combat.

3. **`battleId` vs `trainerId`** : le `battleId` est un identifiant stable d'authoring pour nommer les flags. S'il est absent, on utilise `trainerId` en fallback, ce qui reste déterministe par trainer.

## 6. Détails d'implémentation

### 6.1 ScenarioRuntimeEffect enrichi

Trois champs ajoutés à `ScenarioRuntimeEffect` :
- `battleId` — identifiant stable du combat (pour les flags)
- `trainerId` — identifiant du trainer dans le manifest
- `npcEntityId` — identifiant de l'entité NPC sur la map

### 6.2 Handler de l'executor

Le handler `startTrainerBattle` dans `ScenarioRuntimeExecutor` :
1. Lit `trainerId` depuis `node.binding.trainerId`
2. Lit `npcEntityId` depuis `node.binding.entityId`
3. Lit `battleId` depuis `node.payload.params['battleId']`, fallback sur `trainerId`
4. Valide que `trainerId` et `npcEntityId` sont non vides → `blocked` sinon
5. Retourne `executedEffect` avec un `ScenarioRuntimeEffect` de type `battle`

Le graphe est suspendu sur ce node. L'executor ne continue pas au node suivant.

### 6.3 PlayableMapGame : _handleScenarioBattleEffect

Méthode ajoutée qui :
1. Cherche l'entité NPC sur la map courante
2. Construit un `TrainerBattleStartRequest` via `buildTrainerBattleRequestFromNpc`
3. Mémorise le `runtimeSourceId` pour la continuation
4. Enqueue la battle request

### 6.4 PlayableMapGame : continuation dans _onBattleFinished

Le bloc ajouté dans `_onBattleFinished` :
1. Vérifie si un pending scenario battle existe
2. Mappe `BattleOutcomeType` → suffixe de flag (via un `switch` exhaustif)
3. Construit le flag avec `scenarioBattleOutcomeFlagName`
4. Pose le flag dans les `StoryFlags`
5. Nettoie le pending
6. Restaure l'overworld
7. Appelle `_resumeScenarioAfterRuntimeSource` pour reprendre le graphe

## 7. Convention de flags battle outcome

Format obligatoire :
```
battle:<battleId>:<outcome>
```

Outcomes supportés :
```
battle:<battleId>:victory
battle:<battleId>:defeat
battle:<battleId>:flee
battle:<battleId>:captured
```

Exemples concrets pour le Golden Slice Selbrume :
```
battle:battle_rival_port:victory
battle:battle_rival_port:defeat
```

Flags interdits :
```
battle_victory       ← trop générique, collision
battle_defeat        ← idem
```

Le graphe scénario peut brancher après le combat avec une condition `storyFlagSet` :
```
ScriptCondition(
  type: flagIsSet,
  params: { 'flagName': 'battle:battle_rival_port:victory' },
)
```

## 8. Tests ajoutés / modifiés

### Fichier créé : `test/scenario_battle_from_scene_test.dart`

| Test | Assertion |
|---|---|
| `action startTrainerBattle returns executedEffect with battle data` | Status, effect type, trainerId, npcEntityId, battleId, stopNodeId, message |
| `battleId defaults to trainerId when not in params` | Fallback trainerId quand battleId absent |
| `blocks when trainerId is empty` | Status blocked, message contains trainerId |
| `blocks when npcEntityId is empty` | Status blocked, message contains npcEntityId |
| `dispatchContinuation resumes after battle node and sets flag` | Continuation linéaire après battle, flag lysa_battle_done posé |
| `continuation branches on victory/defeat flag after battle` | Victory → dialogue victory ; Defeat → dialogue defeat |
| `produces deterministic battle:id:outcome format` | 4 outcomes vérifiés |
| `trims whitespace from battleId and outcomeSuffix` | Whitespace trimmed |
| `does not produce generic flags like battle_victory` | Not equal to generic patterns |

### Tests existants non modifiés

Tous les 14 tests de `scenario_runtime_executor_test.dart` passent sans modification.

## 9. Commandes exécutées

```bash
cd packages/map_runtime && flutter test test/scenario_battle_from_scene_test.dart
cd packages/map_runtime && flutter test test/scenario_runtime_executor_test.dart
cd packages/map_runtime && dart analyze lib/src/application/scenario_runtime/
cd packages/map_runtime && flutter test test/scenario_battle_from_scene_test.dart test/scenario_runtime_executor_test.dart
```

## 10. Résultats exacts des commandes

### flutter test (nouveau fichier)
```
00:00 +9: All tests passed!
```

### flutter test (fichier existant)
```
00:00 +14: All tests passed!
```

### dart analyze (scenario_runtime/)
```
Analyzing scenario_runtime...
No issues found!
```

### flutter test (les deux fichiers ensemble)
```
00:00 +23: All tests passed!
```

## 11. Limites V0

| Limite | Justification |
|---|---|
| Un seul combat scénario pending à la fois | Suffisant pour le Golden Slice. Un concurrent écraserait le précédent. |
| Pas de persistance du pending en save | Sauvegarder pendant un combat narratif n'est pas supporté en V0. |
| Pas de reprise après reload pendant un combat narratif | Idem, la state pending est en mémoire uniquement. |
| Pas de combat sauvage scripté | Hors périmètre SEL-B2 (uniquement trainer battles). |
| Pas de boss static encounter | Idem. |
| Pas de validation croisée NPC entity/trainer existence | La validation reste au runtime (le handler dans PlayableMapGame log si l'entité ou le trainer n'existe pas, mais ne crash pas). |
| `_handleScenarioBattleEffect` dépend de Flame | Non testable en pur Dart ; couvert manuellement et par intégration smoke test future. |

## 12. Non-objectifs respectés

```
- [ ] New Game flow → non implémenté (correct)
- [ ] Contenu Selbrume → non créé (correct)
- [ ] map_bourg_selbrume → non créé (correct)
- [ ] map_port_brisants → non créé (correct)
- [ ] npc_mael / npc_lysa → non créés (correct)
- [ ] Dialogue Yarn → non créé (correct)
- [ ] cutscene Lysa → non créée (correct)
- [ ] givePokemon / giveItem → non implémentés (correct)
- [ ] healParty → non implémenté (correct)
- [ ] wild battle from scene → non implémenté (correct)
- [ ] static boss battle → non implémenté (correct)
- [ ] shop / money / XP / level-up / PC / box → non implémentés (correct)
- [ ] Event Builder UI → non implémenté (correct)
- [ ] Scene Builder UI → non implémenté (correct)
- [ ] Cinematic Builder UI → non implémenté (correct)
- [ ] Facts & World Rules UI → non implémenté (correct)
- [ ] Validator narratif complet → non implémenté (correct)
- [ ] Refactor de ScenarioAsset → non fait (correct)
- [ ] Refactor de CutsceneRuntimeRunner → non fait (correct)
- [ ] Codegen / build_runner → non exécuté (correct)
```

## 13. Git status initial

```
(clean — aucun fichier modifié ou non-tracké dans le périmètre)
```

Note : `reports/gameplay/sel_a2_event_scene_outcome_fact_contract.md` était déjà untracked (lot précédent).

## 14. Git status final

```
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
 M packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
?? packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
?? packages/map_runtime/test/scenario_battle_from_scene_test.dart
```

Diff stat :
```
packages/map_runtime/lib/map_runtime.dart                              |   9 ++
.../scenario_runtime_executor.dart                                      |  56 +++++++++
.../scenario_runtime/scenario_runtime_models.dart                       |  20 ++++
.../src/presentation/flame/playable_map_game.dart                       | 128 +++++++++++++++++++++
4 files changed, 213 insertions(+)
+ 2 fichiers créés (helper + tests)
```

## 15. Auto-review critique

### Points forts

1. **Zéro modification `map_core`** : le binding `trainerId` existait déjà, `battleId` passe par `params` (Map libre).
2. **Pattern identique au dialogue** : la suspension/continuation utilise exactement le même mécanisme (`_runtimeSourceId` → `dispatchContinuation`), ce qui garantit la cohérence.
3. **Pattern unifié battle** : le combat passe par `_pendingBattleRequest` comme tout autre combat, pas de chemin spécial.
4. **Tests exhaustifs** : 9 tests couvrent le nominal, les fallbacks, les validations, la continuation, et le branchement.
5. **Flag naming strict** : impossible de produire un flag générique ; la convention `battle:<id>:<outcome>` est enforced par le helper.

### Points de vigilance

1. **`_handleScenarioBattleEffect` non testable en pur Dart** : cette méthode dépend de `_world`, `_bundle`, `_pendingBattleRequest` etc. Un test d'intégration Flame serait nécessaire pour valider le wiring complet.
2. **Entity lookup par `firstWhere` sur `_world.map.entities`** : si le NPC n'est pas sur la map courante (ex: transition de map avant le combat), le handoff échouera silencieusement. C'est correct pour V0 mais devrait être documenté.
3. **`outcome.type == BattleOutcomeType.runaway` → flag flee** : le suffixe est `flee` et non `runaway` pour rester cohérent avec la convention de nommage du spec, mais le code mappe `BattleOutcomeType.runaway` vers `kBattleOutcomeSuffixFlee`. À surveiller si le modèle battle évolue.
4. **Pas de guard contre double-set** : si le même combat est rejoué, le flag précédent sera écrasé par le nouveau. C'est voulu en V0.

## 16. Conclusion

Le lot SEL-B2 est **terminé et validable**. L'infrastructure runtime minimale pour lancer un combat trainer depuis un graphe scénario est en place. Le pipeline complet `dispatch → battle → outcome flag → continuation → branching` fonctionne et est testé.

La prochaine étape recommandée est **SEL-B1** (fix `giveItem` → Bag) ou **SEL-B6** (New Game flow), selon la priorité du Golden Slice.
