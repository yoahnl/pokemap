# SEL-A2 — Contrat Event → Scene → Outcome → Fact V0

**Date** : 2026-05-23
**Repo** : `/Users/karim/Project/pokemonProject`
**Lot** : SEL-A2 (Phase A — Architecture documentaire, pas de code)
**Auteur** : Audit automatisé
**Prérequis** : [SEL-A1 — Glossaire narratif](file:///Users/karim/Project/pokemonProject/reports/gameplay/sel_a1_narrative_glossary.md)
**Aucun code modifié.**

---

## 1. Objectif

Définir le **contrat runtime minimal** qui permet au Golden Slice Selbrume de fonctionner :

```
Maël → Port → Lysa → Combat rival → Outcome victory/defeat
→ Facts persistants → Step completed → World Rules appliquées
```

Ce document répond à cette question :

> Comment un élément de map déclenche un Event, qui joue une Scene,
> qui lance un dialogue Yarn, qui produit un outcome, qui lance un combat,
> qui produit un outcome victory/defeat, qui pose un Fact, qui complète
> une Step, qui applique une World Rule ?

Chaque maillon de la chaîne est documenté avec :

- **Le contrat V0** (ce que le runtime doit garantir)
- **L'état actuel du repo** (ce qui existe, preuve fichier + ligne)
- **L'écart** (ce qui manque)
- **L'option recommandée** pour combler l'écart

---

## 2. Vue d'ensemble du pipeline

```
┌──────────────────────────────────────────────────────────────────────────┐
│                     Pipeline Golden Slice Selbrume                       │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  [1] MAP ELEMENT (NPC Lysa)                                              │
│       │                                                                  │
│       ▼                                                                  │
│  [2] EVENT TRIGGER (interact)                                            │
│       │                                                                  │
│       ▼                                                                  │
│  [3] SCENE (Scenario Graph, localEventFlow)                              │
│       │ ── source: entityInteract(mapId, entityId)                       │
│       │ ── condition: activationCondition (step active, fact true)        │
│       │                                                                  │
│       ├──► [4] DIALOGUE YARN ──► outcome choice                          │
│       │         │                                                        │
│       │         ▼                                                        │
│       ├──► [5] CINEMATIC (linear staging)                                │
│       │         │                                                        │
│       │         ▼                                                        │
│       ├──► [6] BATTLE HANDOFF ──► victory / defeat  ◄── BLK-1           │
│       │         │                                                        │
│       │         ▼                                                        │
│       ├──► [7] POST-BATTLE CONTINUATION              ◄── BLK-2          │
│       │         │                                                        │
│       │         ▼                                                        │
│       ├──► [8] FACT (setFlag / emitOutcome → storyFlag)                  │
│       │         │                                                        │
│       │         ▼                                                        │
│       ├──► [9] STEP COMPLETION (completedStepIds)                        │
│       │         │                                                        │
│       │         ▼                                                        │
│       └──► [10] WORLD RULE (NPC visibility, conditional dialogue)        │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Contrat détaillé — Maillon par maillon

---

### 3.1 — [1] Map Element → [2] Event Trigger

#### Contrat V0

Un élément de map (NPC, Sign, Trigger Zone, Placed Element) déclenche un pipeline scénario quand le joueur interagit ou entre dans une zone.

#### État du repo

| Mécanisme | Existe | Preuve |
|---|---|---|
| `InteractIntent` → `NpcInteracted` → `_tryDispatchScenarioEntityInteraction` | ✅ | [playable_map_game.dart:4585-4591](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L4585-L4591) |
| `ScenarioRuntimeSourceEvent.entityInteract(mapId, entityId)` | ✅ | [scenario_runtime_models.dart:56-64](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart#L56-L64) |
| `ScenarioRuntimeSourceEvent.triggerEnter(mapId, triggerId)` | ✅ | [scenario_runtime_models.dart:45-53](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart#L45-L53) |
| `ScenarioRuntimeSourceEvent.mapEnter(mapId)` | ✅ | [scenario_runtime_models.dart:36-42](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart#L36-L42) |
| Dispatch vers `ScenarioRuntimeExecutor` | ✅ | [playable_map_game.dart:2087-2134](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L2087-L2134) |
| Fallback: si scénario ne matche pas → `_handleNpcInteraction` classique | ✅ | [playable_map_game.dart:4592-4593](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L4592-L4593) |

#### Flow runtime exact

```
_handleInteract()
  └─ stepGameplayWorld(_world, InteractIntent())
       ├─ NpcInteracted → _faceNpcTowardPlayer(entity.id)
       │                  → _tryDispatchScenarioEntityInteraction(entity.id)
       │                       └─ _dispatchScenarioRuntimeSource(
       │                            ScenarioRuntimeSourceEvent.entityInteract(
       │                              mapId: _activeMapId,
       │                              entityId: entity.id,
       │                            )
       │                          )
       │                            └─ _scenarioRuntime.dispatch(
       │                                 scenarios: _bundle.manifest.scenarios,
       │                                 sourceEvent: ...,
       │                                 context: _buildScenarioRuntimeExecutionContext(),
       │                               )
       └─ si pas handled → _handleNpcInteraction(entity) (dialogue/trainer classique)
```

#### Écart

Aucun écart. Ce maillon fonctionne déjà.

#### Conditions de garde

| Condition | Code | Effet |
|---|---|---|
| `_flowPhase != overworld` | [playable_map_game.dart:2090](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L2090) | Bloque le dispatch si en dialogue/combat/transition |
| Script actif non terminé | [playable_map_game.dart:2098](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L2098) | Bloque si un script cutscene est en cours |

---

### 3.2 — [2] Event Trigger → [3] Scene

#### Contrat V0

Un Event Trigger sélectionne la Scene à jouer via le mécanisme `_candidateScenarios` + `_scenarioActivationPasses`.

Pour le Golden Slice, l'Event "rival_port_meet" est un `ScenarioAsset(scope: localEventFlow)` dont :
- la source est un node `sourceEntityInteract` matchant le `entityId` de Lysa
- la condition d'activation teste un fact/flag (ex: `step_go_to_port` completed)

#### État du repo

| Mécanisme | Existe | Preuve |
|---|---|---|
| Candidate filtering par scope | ✅ | [scenario_runtime_executor.dart:260-281](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L260-L281) — `entityInteract` → locals first |
| `_scenarioActivationPasses` (condition sur GameState) | ✅ | [scenario_runtime_executor.dart:283-289](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L283-L289) |
| `ScenarioAsset.activationCondition` | ✅ | [scenario_asset.dart:38](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart#L38) |
| `conditionEvaluator.evaluate` | ✅ | [scenario_runtime_executor.dart:288](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L288) |
| `shouldSkipScenario` filter (step already completed) | ✅ | [scenario_runtime_executor.dart:240-243](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L240-L243) + [playable_map_game.dart:2205-2211](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L2205-L2211) |

#### Flow runtime exact

```
ScenarioRuntimeExecutor._dispatchInternal()
  │
  ├─ _candidateScenarios(sourceEvent: entityInteract)
  │     └─ privilégie ScenarioAsset(scope: localEventFlow)       ← "Scene"
  │
  ├─ pour chaque candidat:
  │   ├─ _scenarioActivationPasses(scenario, gameState)          ← condition d'activation
  │   ├─ _findMatchingSourceNode(scenario, sourceEvent)          ← match entityId
  │   ├─ shouldSkipScenario(scenarioId)                          ← step déjà complétée ?
  │   └─ _executeScenarioFromSource(...)                         ← traverse le graphe
  │
  └─ si aucun match → noMatchingSource
```

#### Sélection Multi-Scenario

Priorité actuelle (déterministe pour le GS) :

1. Filtrage par scope → `localEventFlow` d'abord (pour `entityInteract`)
2. Premier candidat qui matche source + passe activation + pas skipped

> [!NOTE]
> Pour le Golden Slice avec un seul scénario par NPC+condition, ce mécanisme suffit.
> Un système de priorités explicites serait nécessaire si plusieurs Scenes matchent le même trigger.

#### Écart

Aucun écart. Ce maillon fonctionne déjà.

---

### 3.3 — [3] Scene → [4] Dialogue Yarn

#### Contrat V0

Un node `dialogue` dans le graphe scénario ouvre un dialogue Yarn, suspend le parcours du graphe, et reprend le flow quand le dialogue se termine.

#### État du repo

| Mécanisme | Existe | Preuve |
|---|---|---|
| Node type `ScenarioNodeType.dialogue` | ✅ | [scenario_asset.dart:137-138](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/scenario_asset.dart#L137-L138) |
| Executor ouvre le dialogue via callback | ✅ | [scenario_runtime_executor.dart:379-408](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L379-L408) |
| `context.openDialogue(dialogueId, startNode, runtimeSourceId)` | ✅ | [scenario_runtime_executor.dart:382-389](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L382-L389) |
| Retour `executedEffect` avec `ScenarioRuntimeEffect.dialogue` | ✅ | [scenario_runtime_executor.dart:391-402](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L391-L402) |
| `runtimeSourceId` format `scenario:<scenarioId>:<sourceNodeId>:<nodeId>` | ✅ | [scenario_runtime_executor.dart:385-389](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L385-L389) |
| Continuation après dialogue fermé | ✅ | [playable_map_game.dart:2396-2439](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L2396-L2439) |

#### Flow Suspension / Reprise

```
[ScenarioRuntimeExecutor] exécute node dialogue
  │
  ├─ retourne ScenarioRuntimeExecutionResult(status: executedEffect)
  │   avec runtimeSourceId = "scenario:<scenarioId>:<sourceNodeId>:<dialogueNodeId>"
  │
  └─ le runtime ouvre le dialogue overlay
       │
       │  (joueur navigue dans le dialogue Yarn)
       │
       └─ dialogue fermé → _pendingPostDialogueAction()
            └─ _scheduleScenarioContinuationAfterDialogue(runtimeSourceId)
                 └─ _resumeScenarioAfterRuntimeSource(runtimeSourceId)
                      └─ _scenarioRuntime.dispatchContinuation(
                           scenarioId, sourceNodeId,
                           resumeAfterNodeId = dialogueNodeId
                         )
                           └─ continue le graphe APRÈS le node dialogue
```

Le mécanisme clé est `dispatchContinuation` qui reprend le traversal du graphe à partir du node **suivant** le node dialogue.

#### Écart

Aucun écart. Ce maillon fonctionne déjà.

---

### 3.4 — [3] Scene → [5] Cinematic

#### Contrat V0

Un node `action` avec `actionKind = "script"` dans le graphe scénario lance une cinématique (`RuntimeCutsceneAsset`), suspend le parcours, et reprend quand la cinématique se termine.

#### État du repo

| Mécanisme | Existe | Preuve |
|---|---|---|
| Node type `ScenarioNodeType.action` avec `actionKind = "script"` | ✅ | [scenario_runtime_executor.dart:27](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L27) — `kScenarioActionEmitOutcome` |
| `context.runScript(scriptId, startNode, runtimeSourceId)` | ✅ | [scenario_runtime_models.dart:164-168](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart#L164-L168) |
| `_runScenarioScriptById` runtime implementation | ✅ | [playable_map_game.dart:3939-3968](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L3939-L3968) |
| `CutsceneRuntimeRunner` execution | ✅ | [cutscene_runtime_runner.dart:67-97](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart#L67-L97) |
| 17 step types dans la cinématique | ✅ | [cutscene_runtime_models.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/cutscene_runtime_models.dart) |

#### Écart

Le pont Scene → Cinematic fonctionne via `runScript`. La cinématique est jouée linéairement.

Le step type `CutsceneEmitOutcomeStep` permet à la cinématique d'émettre un outcome qui sera lu par le scenario executor (via le flag `scenarioOutcomeFlagName(outcomeId)`).

Pas d'écart bloquant pour ce maillon.

---

### 3.5 — [3] Scene → [6] BATTLE HANDOFF ← BLK-1

> [!CAUTION]
> **Blocage principal du Golden Slice**. Aucun mécanisme n'existe pour déclencher un combat depuis le graphe scénario ou une cinématique.

#### Contrat V0

Un node dans la Scene doit pouvoir déclencher un combat trainer. Le combat doit :
1. Suspendre le flow scénario/cinématique
2. Lancer le handoff battle existant
3. Produire un `BattleOutcome` (victory/defeat/flee)
4. Reprendre le flow scénario/cinématique avec l'outcome

#### État du repo — Ce qui existe

| Mécanisme | Existe | Preuve |
|---|---|---|
| `_startBattleHandoff(BattleStartRequest)` | ✅ | [playable_map_game.dart:4033-4059](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L4033-L4059) |
| `_openBattleOverlay(BattleStartRequest)` | ✅ | [playable_map_game.dart:4070-4219](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L4070-L4219) |
| `_onBattleFinished(BattleOutcome)` | ✅ | [playable_map_game.dart:4425-4494](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L4425-L4494) |
| `TrainerBattleStartRequest` model | ✅ | [battle_start_request.dart:106-138](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/battle_start_request.dart#L106-L138) |
| `RuntimeBattleSourceKind.script` (valeur enum) | ✅ | [battle_start_request.dart:12](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/battle_start_request.dart#L12) |
| `BattleOutcome` model (victory/defeat/flee/captured) | ✅ | Existe dans `map_battle` |
| `applyRuntimeBattleOutcomeToGameState` | ✅ | [runtime_battle_outcome_apply.dart:174-233](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart#L174-L233) |
| Post-battle trainer flag `markTrainerDefeated` | ✅ | [runtime_battle_outcome_apply.dart:225-230](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart#L225-L230) |

#### État du repo — Ce qui manque

| Mécanisme | Existe | Preuve |
|---|---|---|
| Node scénario `playCombat` / `startBattle` | ❌ | `ScenarioNodeType` enum a 7 valeurs: `start, dialogue, action, condition, choice, reference, end` — aucune n'est `battle` |
| `CutsceneStartBattleStep` dans cutscene runner | ❌ | Les 17 step types ne contiennent aucun step battle |
| `ScenarioRuntimeEffectType.battle` | ❌ | Enum a 4 valeurs: `dialogue, script, message, none` |
| Suspend/resume scénario pendant combat | ❌ | Le continuation ne fonctionne qu'après dialogue |
| `_onBattleFinished` → reprise scénario | ❌ | `_onBattleFinished` retourne directement à l'overworld, sans reprendre de flow |
| `RuntimeBattleSourceKind.script` utilisé quelque part | ❌ | La valeur enum existe mais n'est référencée nulle part |

> [!IMPORTANT]
> L'enum `RuntimeBattleSourceKind.script` existe déjà — un index clair que le battle-from-script a été anticipé mais jamais implémenté.

#### Analyse des options

##### Option A — Étendre le ScenarioNodeType (refactor modèle)

```
ScenarioNodeType { start, dialogue, action, condition, choice, reference, end, battle }
```

- **Avantage** : Concept clair dans le graphe scénario
- **Inconvénient** : Touche `map_core` (modèle + freezed + sérialisation), `map_editor` (graphe canvas), `map_runtime` (executor), tests, fixtures
- **Effort** : L (refactor cascade)
- **Recommandation** : ❌ Non recommandé pour le GS — trop large

##### Option B — Réutiliser le node `action` existant avec un nouveau `actionKind`

```
ScenarioNode(type: action, binding: { actionKind: 'startTrainerBattle', trainerId: '...', npcEntityId: '...' })
```

L'executor traite `kScenarioActionStartTrainerBattle` comme il traite déjà `kScenarioActionEmitOutcome`, `kScenarioActionSetFlag`, `kScenarioActionClearFlag`.

- **Avantage** : Aucun changement de modèle `map_core` — uniquement le runtime executor
- **Inconvénient** : La notation `action(actionKind=startTrainerBattle)` est un détournement du node, pas un concept graphe natif
- **Effort** : M
- **Recommandation** : ✅ Recommandé pour le GS

##### Option C — Ajouter un `CutsceneStartBattleStep` dans le CutsceneRuntimeRunner

Ajouter un step type dans les cinématiques qui suspend la cinématique, lance le combat, puis reprend.

- **Avantage** : La cinématique peut lancer un combat de façon linéaire
- **Inconvénient** : Nécessite un mécanisme de suspension de cinématique (n'existe pas), complexité async
- **Effort** : L
- **Recommandation** : ❌ Non recommandé pour le GS — complexité async trop risquée

##### Option D — Hybride : action node suspend le graphe + le runtime lance le battle

L'executor rencontre un node `action(actionKind: startTrainerBattle)`. Au lieu de traverser linéairement, il :
1. Retourne un `ScenarioRuntimeExecutionResult` avec un nouveau `effectType: battle`
2. Le runtime (`PlayableMapGame`) construit un `TrainerBattleStartRequest` et appelle `_startBattleHandoff`
3. Quand le combat finit, `_onBattleFinished` appelle `dispatchContinuation` pour reprendre le flow scénario

- **Avantage** : Réutilise le mécanisme exact de suspension/reprise du node `dialogue`
- **Inconvénient** : Nécessite de mémoriser le `runtimeSourceId` pendant le combat
- **Effort** : M (suit le pattern dialogue existant)
- **Recommandation** : ✅✅ **Recommandé — meilleur rapport effort/impact**

#### Recommandation : Option D (Hybride)

Le mécanisme de suspension/reprise existe **déjà** pour les dialogues :

```
dialogue node → executedEffect → suspend → dialogue overlay fermé → dispatchContinuation
```

On réplique le même pattern pour les combats :

```
action(startTrainerBattle) → executedEffect(battle) → suspend
→ battle overlay fermé → _onBattleFinished → dispatchContinuation
```

#### Changements requis pour Option D

| Composant | Changement | Fichier |
|---|---|---|
| `ScenarioRuntimeEffectType` | Ajouter valeur `battle` | [scenario_runtime_models.dart:85-90](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart#L85-L90) |
| `ScenarioRuntimeEffect` | Ajouter champs `trainerId`, `npcEntityId` | [scenario_runtime_models.dart:93-108](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart#L93-L108) |
| `ScenarioRuntimeExecutor` | Handler pour `kScenarioActionStartTrainerBattle` | [scenario_runtime_executor.dart](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart) |
| `PlayableMapGame._dispatchScenarioRuntimeSource` | Si `effect.type == battle` → construire `TrainerBattleStartRequest` + `_startBattleHandoff` | [playable_map_game.dart:2087-2134](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L2087-L2134) |
| `PlayableMapGame._onBattleFinished` | Si `_pendingScenarioBattleSourceId != null` → `dispatchContinuation` | [playable_map_game.dart:4425-4494](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L4425-L4494) |

#### Pseudocode — Executor

```dart
case kScenarioActionStartTrainerBattle:
  final trainerId = node.binding.params['trainerId']?.trim() ?? '';
  final npcEntityId = node.binding.params['npcEntityId']?.trim() ?? '';
  if (trainerId.isEmpty || npcEntityId.isEmpty) {
    return blocked('startTrainerBattle sans trainerId/npcEntityId');
  }
  return ScenarioRuntimeExecutionResult(
    status: executedEffect,
    effect: ScenarioRuntimeEffect(
      type: ScenarioRuntimeEffectType.battle,
      trainerId: trainerId,
      npcEntityId: npcEntityId,
    ),
    scenarioId: scenario.id,
    sourceNodeId: sourceId,
    stopNodeId: node.id,
    message: 'Battle trainer "$trainerId" lancé.',
  );
  // Le graphe est suspendu ici. La reprise viendra de dispatchContinuation.
```

#### Pseudocode — Runtime (PlayableMapGame)

```dart
// Dans _dispatchScenarioRuntimeSource, après le dispatch :
if (result.effect.type == ScenarioRuntimeEffectType.battle) {
  _pendingScenarioBattleSourceId = _runtimeSourceId(
    scenarioId: result.scenarioId!,
    sourceNodeId: result.sourceNodeId!,
    nodeId: result.stopNodeId!,
  );
  final request = buildTrainerBattleRequestFromNpc(
    trainerId: result.effect.trainerId!,
    npcEntityId: result.effect.npcEntityId!,
    // ... mapId, playerPos, returnContext
  );
  _startBattleHandoff(request);
}

// Dans _onBattleFinished, après le write-back :
if (_pendingScenarioBattleSourceId != null) {
  final sourceId = _pendingScenarioBattleSourceId!;
  _pendingScenarioBattleSourceId = null;

  // Poser un fact avec l'outcome du combat
  final outcomeFlag = outcome.isVictory ? 'battle_victory' : 'battle_defeat';
  _gameState = storyFlags.set(_gameState, outcomeFlag);

  // Reprendre le graphe
  _resumeScenarioAfterRuntimeSource(sourceId);
}
```

---

### 3.6 — [6] Battle → [7] POST-BATTLE CONTINUATION ← BLK-2

> [!WARNING]
> Le post-battle continuation est le **deuxième blocage** du Golden Slice.
> L'option D (§3.5) résout BLK-1 **et** BLK-2 d'un seul coup.

#### Contrat V0

Après un combat déclenché par la Scene, le flow scénario doit reprendre au node suivant le node battle. Le scénario doit pouvoir **brancher** sur le résultat du combat (victoire/défaite).

#### Mécanisme de branchement post-battle

Le graphe scénario déjà supporté permet le branchement :

```
[action: startTrainerBattle]
     │
     ▼
[condition: storyFlagSet("battle_rival_port:victory")]
     ├─ true  → [action: setFlag("fact_rival_port_defeated")] → [action: emitOutcome("rival_defeated")]
     └─ false → [dialogue: yarn_rival_defeat_consolation] → [end]
```

Ce branchement utilise le mécanisme existant `ScenarioNodeType.condition` + `conditionEvaluator.evaluate`.

#### Comment le fait d'outcome du combat est posé

Deux options :

| Option | Mécanisme | Avantage | Inconvénient |
|---|---|---|---|
| A. Le runtime pose le flag dans `_onBattleFinished` avant la continuation | Le flag est garanti posé avant le graphe reprend | Le runtime connait la convention de nommage des flags battle | Simple, déterministe |
| B. Le nœud action `startTrainerBattle` pose le flag lui-même via un `emitOutcome` implicite | L'executor contrôle la logique | Plus complexe, nécessite de passer l'outcome au continuation | Cohérent avec `emitOutcome` existant |

**Recommandation** : **Option A**. Le runtime pose un flag `battle_<requestId>:victory` ou `battle_<requestId>:defeat` dans `_onBattleFinished`, juste avant d'appeler `dispatchContinuation`. Le graphe scénario branche ensuite via un node `condition(storyFlagSet)`.

#### État du repo — Continuation existante (dialogue)

Le pattern de continuation post-dialogue est déjà en place :

```
_scheduleScenarioContinuationAfterDialogue(runtimeSourceId)
  └─ _pendingPostDialogueAction = () => _resumeScenarioAfterRuntimeSource(id)

_resumeScenarioAfterRuntimeSource(runtimeSourceId)
  └─ parts = runtimeSourceId.split(':')  // scenario:scenarioId:sourceNodeId:nodeId
  └─ _scenarioRuntime.dispatchContinuation(
       scenarioId, sourceNodeId, resumeAfterNodeId = nodeId
     )
```

Le combat réutilisera exactement le même chemin, la seule différence étant :
- **Dialogue** : la continuation est déclenchée par la fermeture du dialogue overlay
- **Combat** : la continuation est déclenchée par `_onBattleFinished`

#### Écart

| Ce qui manque | Effort |
|---|---|
| Champ `_pendingScenarioBattleSourceId` dans `PlayableMapGame` | S — un champ `String?` |
| Logique de pose de flag outcome dans `_onBattleFinished` | S — 5 lignes |
| Appel `_resumeScenarioAfterRuntimeSource` dans `_onBattleFinished` | S — 3 lignes |

---

### 3.7 — [7] Post-Battle → [8] FACT (emitOutcome / setFlag)

#### Contrat V0

Le graphe scénario, après branchement sur le résultat du combat, pose un Fact persistant (= flag dans `StoryFlags.activeFlags`).

#### État du repo

| Mécanisme | Existe | Preuve |
|---|---|---|
| Action `setFlag` dans l'executor | ✅ | [scenario_runtime_executor.dart:582-606](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L582-L606) |
| Action `clearFlag` dans l'executor | ✅ | [scenario_runtime_executor.dart:607-636](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L607-L636) |
| Action `emitOutcome` dans l'executor | ✅ | [scenario_runtime_executor.dart:638-699](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L638-L699) |
| `emitOutcome` persiste un flag `outcome:<outcomeId>` | ✅ | [scenario_runtime_executor.dart:652-656](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L652-L656) |
| `emitOutcome` tente un pont `outcomeReceived` vers la couche globale | ✅ | [scenario_runtime_executor.dart:658-679](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart#L658-L679) |
| `StoryFlagsManager.set / clear` | ✅ | Via `GameState.storyFlags` |
| Persistance dans `SaveData.PlayerProgression.storyFlags` | ✅ | [save_data.dart:201](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/save_data.dart#L201) |

#### Flow Golden Slice

```
[action: setFlag("fact_rival_port_defeated")]
  │ executor: storyFlags.set(gameState, "fact_rival_port_defeated")
  │ → gameState mis à jour
  │ → context.onGameStateUpdated(nextState)
  │ → runtime refreshNpcPresence()
  │
  ▼
[action: emitOutcome("rival_defeated")]
  │ executor:
  │   1. persiste flag "outcome:rival_defeated"
  │   2. tente dispatchInternal(outcomeReceived: "rival_defeated")
  │      → cherche un ScenarioAsset(scope: globalStory) avec sourceOutcome
  │      → si trouvé, exécute le graphe global
  │   3. si pas trouvé, continue localement
  │
  ▼
[end]
```

#### Écart

Aucun écart. Ce maillon fonctionne déjà.

> [!TIP]
> Le pont `emitOutcome → outcomeReceived` est le mécanisme qui connecte le flow local (Scene) au flow global (Storyline). C'est exactement le pont nécessaire pour que le combat rival mette à jour la progression de la Storyline principale.

---

### 3.8 — [8] Fact → [9] STEP COMPLETION

#### Contrat V0

Quand un scénario local atteint son node `end`, si une règle Step Studio `whenCutsceneEnds` cible ce scénario, le Step correspondant est marqué completed dans `PlayerProgression.completedStepIds`.

#### État du repo

| Mécanisme | Existe | Preuve |
|---|---|---|
| `StepCompletionCutsceneIndex` (map cutsceneId → stepId) | ✅ | [step_studio_completion_runtime.dart:22-39](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/step_studio_completion_runtime.dart#L22-L39) |
| `buildStepCompletionCutsceneIndex` parser | ✅ | [step_studio_completion_runtime.dart:46-93](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/step_studio_completion_runtime.dart#L46-L93) |
| `_handleScenarioRuntimeCompletionResult` | ✅ | [playable_map_game.dart:2217-2252](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L2217-L2252) |
| `_applyScenarioReachedEndCompletion` | ✅ | [playable_map_game.dart:2256-2313](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L2256-L2313) |
| `appendCompletedStepIdIfAbsent` | ✅ | [step_studio_completion_runtime.dart:98-110](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/step_studio_completion_runtime.dart#L98-L110) |
| `appendCompletedCutsceneIdIfAbsent` | ✅ | [step_studio_completion_runtime.dart:117-129](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/step_studio_completion_runtime.dart#L117-L129) |
| Deferred completion (attente des effets runtime visibles) | ✅ | [playable_map_game.dart:2228-2251](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L2228-L2251) |

#### Flow

```
ScenarioRuntimeExecutionResult(status: reachedEnd, scenarioId: "scene_rival_battle")
  │
  ├─ _handleScenarioRuntimeCompletionResult(result)
  │   ├─ si dialogue/cutscene encore visible → defer
  │   └─ sinon → _applyScenarioReachedEndCompletion(scenarioId)
  │       ├─ index.stepIdToCompleteWhenCutsceneEnds("scene_rival_battle")
  │       │   └─ retourne "step_rival_battle"
  │       ├─ appendCompletedStepIdIfAbsent(completed, "step_rival_battle")
  │       └─ appendCompletedCutsceneIdIfAbsent(completed, "scene_rival_battle")
  │
  └─ _gameState = _gameState.copyWith(progression: updated)
     → _refreshWorldNpcPresence()
```

#### Écart : mode de complétion

Le seul mode de complétion implémenté est `whenCutsceneEnds`. Le `selbrume.md` demande aussi :

| Mode demandé | Existe | Contournement GS |
|---|---|---|
| `whenCutsceneEnds` (cutscene locale termine) | ✅ | — |
| `whenFlagSet(flagName)` (un fact est posé) | ❌ | Utiliser `whenCutsceneEnds` sur un scénario local qui pose le flag puis atteint `end` |
| `whenBattleWon(battleId)` | ❌ | Le graphe scénario post-combat pose le flag + atteint `end` → `whenCutsceneEnds` couvre ce cas |
| `completeStep` direct (action explicite) | ❌ | Idem ci-dessus |

> [!NOTE]
> Pour le Golden Slice, `whenCutsceneEnds` suffit. La step "rival_battle" sera liée au scénario local `scene_rival_battle`, qui atteint `end` après le branchement post-combat. La step sera complétée automatiquement.

#### Écart

Faible pour le GS. `whenCutsceneEnds` couvre le cas via un scénario local wrapper.

---

### 3.9 — [9] Step → [10] WORLD RULE

#### Contrat V0

Quand un Step est completed ou un Fact est posé, les World Rules s'appliquent automatiquement (NPC visibility, conditional dialogue, NPC presence refresh).

#### État du repo

| Mécanisme | Existe | Preuve |
|---|---|---|
| `MapEntityNpcVisibilityRule` avec predicates | ✅ | [map_entity_payloads.dart:89-94](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart#L89-L94) |
| 8 predicate kinds (`storyFlagSet/Unset`, `stepCompleted/NotCompleted`, `chapterCompleted/NotCompleted`, `cutsceneCompleted/NotCompleted`) | ✅ | `MapEntityRuntimePredicateKind` |
| `_refreshWorldNpcPresence()` appelé après mutation GameState | ✅ | [playable_map_game.dart:2143-2144](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L2143-L2144) + [playable_map_game.dart:2309](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L2309) |
| `_refreshWorldNpcPresence()` appelé après battle si flags ont changé | ✅ | [playable_map_game.dart:4460-4463](file:///Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart#L4460-L4463) |
| `MapEntityConditionalDialogue` (dialogue variant selon fact) | ✅ | [map_entity_payloads.dart:102-107](file:///Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart#L102-L107) |

#### Flow

```
_gameState = _gameState.copyWith(storyFlags: ..., progression: ...)
  │
  └─ _refreshWorldNpcPresence()
       └─ pour chaque NPC de la map :
            ├─ évaluer isNpcRuntimePresentOnMap(entity, gameState)
            │   └─ vérifier NpcVisibilityRule predicates
            └─ mettre à jour la présence visuelle
```

#### Exemple Golden Slice

```
Après combat rival:
  setFlag("fact_rival_port_defeated")
  → step "step_rival_battle" completed
  → _refreshWorldNpcPresence()
       ├─ NPC Lysa: visibilityRule = storyFlagSet("fact_rival_port_defeated") → masquée? changée?
       ├─ NPC Garde: visibilityRule = stepCompleted("step_rival_battle") → apparaît?
       └─ NPC Soline: conditionalDialogue[stepCompleted("step_rival_battle")] → nouveau dialogue
```

#### Écart

Aucun écart. Ce maillon fonctionne déjà.

---

## 4. Synthèse des écarts — Table de blocage

| # | Maillon | État | Blocage | Lot cible |
|---|---|---|---|---|
| 1 | Map Element → Event Trigger | ✅ Fonctionnel | — | — |
| 2 | Event Trigger → Scene | ✅ Fonctionnel | — | — |
| 3 | Scene → Dialogue Yarn | ✅ Fonctionnel | — | — |
| 4 | Scene → Cinematic | ✅ Fonctionnel | — | — |
| 5 | **Scene → Battle Handoff** | ❌ Absent | **BLK-1** | **SEL-B2** |
| 6 | **Post-Battle Continuation** | ❌ Absent | **BLK-2** | **SEL-B2** |
| 7 | Fact (setFlag / emitOutcome) | ✅ Fonctionnel | — | — |
| 8 | Step Completion | ✅ Fonctionnel | Faible (mode unique `whenCutsceneEnds`) | SEL-B9 (post-GS) |
| 9 | World Rule | ✅ Fonctionnel | — | — |

> [!IMPORTANT]
> **8 maillons sur 9 fonctionnent déjà.** Le seul blocage est le pont Scene ↔ Battle (BLK-1 + BLK-2), résolu par un seul lot (SEL-B2) qui réplique le pattern dialogue existant.

---

## 5. Contrat du lot SEL-B2 — Battle from Scene

### 5.1 Objectif

Permettre à un node action `startTrainerBattle` dans le graphe scénario de :
1. Lancer un combat trainer via le handoff existant
2. Suspendre le graphe scénario
3. Reprendre le graphe après le combat avec un flag outcome posé

### 5.2 Changements minimaux

#### `map_runtime` — Modèles (`scenario_runtime_models.dart`)

```diff
 enum ScenarioRuntimeEffectType {
   dialogue,
   script,
   message,
+  battle,
   none,
 }

 class ScenarioRuntimeEffect {
   // ... existant ...
+  final String? trainerId;
+  final String? npcEntityId;
 }
```

#### `map_runtime` — Executor (`scenario_runtime_executor.dart`)

```diff
+const String kScenarioActionStartTrainerBattle = 'startTrainerBattle';

 // Dans le switch case des actions :
+case kScenarioActionStartTrainerBattle:
+  // Valider trainerId + npcEntityId
+  // Retourner ScenarioRuntimeExecutionResult(
+  //   status: executedEffect,
+  //   effect: ScenarioRuntimeEffect(type: battle, trainerId, npcEntityId),
+  //   runtimeSourceId pour continuation,
+  // )
```

#### `map_runtime` — PlayableMapGame

```diff
+String? _pendingScenarioBattleSourceId;

 // Après dispatch, si effect.type == battle :
+  → construire TrainerBattleStartRequest
+  → mémoriser _pendingScenarioBattleSourceId
+  → _startBattleHandoff(request)

 // Dans _onBattleFinished :
+  if (_pendingScenarioBattleSourceId != null) {
+    // 1. Poser flag outcome battle
+    // 2. _resumeScenarioAfterRuntimeSource(_pendingScenarioBattleSourceId!)
+    // 3. _pendingScenarioBattleSourceId = null
+  }
```

### 5.3 Critères de validation

| # | Critère | Test |
|---|---|---|
| 1 | Un node action `startTrainerBattle` lance le combat | Test unitaire executor |
| 2 | Le graphe est suspendu pendant le combat | `_flowPhase == battle` pendant le combat |
| 3 | Après le combat, le graphe reprend au node suivant | Test `dispatchContinuation` |
| 4 | Un flag `battle_<id>:victory` ou `battle_<id>:defeat` est posé | Vérifier `storyFlags` après combat |
| 5 | Le graphe branche correctement sur le résultat | Test condition node avec flag victory/defeat |
| 6 | Aucune régression sur le handoff battle existant (LOS/encounter) | Tests existants passent |

### 5.4 Ce que SEL-B2 ne fait PAS

- Pas de combat sauvage depuis graphe (lot SEL-B3)
- Pas de `givePokemon` (lot SEL-B4)
- Pas de New Game flow (lot SEL-B6)
- Pas de refactor de `ScenarioNodeType` (post-GS)
- Pas de `CutsceneStartBattleStep` (remplacé par le pattern action node)

---

## 6. Golden Slice Selbrume — Flux complet authoring

Voici comment l'auteur configure le Golden Slice avec le contrat V0 :

### Storyline (Global Story)

```
ScenarioAsset(scope: globalStory, id: "story_main_brume_phare")
  metadata[kStepStudioDocumentMetadataKey] = {
    "steps": [
      { "id": "step_intro_selbrume", "completion": { "mode": "whenCutsceneEnds", "cutsceneId": "scene_mael_intro" } },
      { "id": "step_go_to_port",     "completion": { "mode": "whenCutsceneEnds", "cutsceneId": "scene_port_alert" } },
      { "id": "step_rival_battle",   "completion": { "mode": "whenCutsceneEnds", "cutsceneId": "scene_rival_battle" } }
    ]
  }
  metadata[kGlobalStoryStudioDocumentMetadataKey] = {
    "chapters": [
      { "id": "chapter_1_port", "steps": ["step_intro_selbrume", "step_go_to_port", "step_rival_battle"] }
    ]
  }
```

### Scene "rival_battle" (Local Event Flow)

```
ScenarioAsset(scope: localEventFlow, id: "scene_rival_battle")
  activationCondition: storyFlagSet("fact_port_reached")  // ou stepCompleted("step_go_to_port")
  nodes:
    [start: sourceEntityInteract(mapId: "port", entityId: "npc_lysa")]
      │
      ▼
    [dialogue: yarn_rival_intro]  ← dialogue Yarn avec choix
      │  (suspend → dialogue → fermeture → continuation)
      ▼
    [action: startTrainerBattle(trainerId: "trainer_lysa", npcEntityId: "npc_lysa")]  ← BLK-1
      │  (suspend → combat → fin → continuation + flag outcome)
      ▼
    [condition: storyFlagSet("battle_trainer_lysa:victory")]
      ├─ true  ──► [action: setFlag("fact_rival_port_defeated")]
      │               ▼
      │             [action: emitOutcome("rival_defeated")]  ← pont vers global
      │               ▼
      │             [dialogue: yarn_rival_after_win]
      │               ▼
      │             [end]  ← triggers step completion "step_rival_battle"
      │
      └─ false ──► [dialogue: yarn_rival_after_defeat]
                     ▼
                   [end]  ← le step n'est PAS complété (la scene peut être rejouée)
```

### NPC Lysa — World Rules

```
MapEntity(id: "npc_lysa")
  npc:
    visibilityRules:
      - predicate: storyFlagUnset("fact_rival_port_defeated")  // visible tant que pas battue
    dialogue:
      default: yarn_lysa_idle
      conditionalDialogues:
        - predicate: stepCompleted("step_rival_battle")
          dialogue: yarn_lysa_post_battle
```

---

## 7. Risques et limites

| # | Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|---|
| 1 | Le `runtimeSourceId` n'est pas persisté si le joueur sauvegarde pendant un combat | Faible (save en combat non supporté) | Moyen (perte de continuation) | Pour le GS : ignorer. Post-GS : persister dans `SaveData`. |
| 2 | Deux combats scénario simultanés | Nul (guard `_flowPhase`) | — | Le guard `_flowPhase != overworld` empêche un double dispatch. |
| 3 | Le joueur fuit le combat scénario | Moyen | Moyen (que fait le graphe ?) | Le runtime pose un flag `battle_<id>:flee` et le graphe branche dessus. Ou : interdire la fuite dans les combats scénario (configurable sur `BattleStartRequest`). |
| 4 | Le flag outcome du combat a un nom collisionnel | Faible | Faible | Convention stricte : `battle_<trainerId>:<outcome>`. |
| 5 | `giveItem` écrit dans metadata au lieu de Bag | Certain si utilisé | Moyen | Lot SEL-B1 — fixer avant le GS si des items sont donnés. |
| 6 | Pas de `givePokemon` | Certain si Config A | Élevé | Lot SEL-B4 ou utiliser Config B (starter pré-chargé). |

---

## 8. Plan de lots séquencé

| Priorité | Lot | Description | Effort | Prérequis |
|---|---|---|---|---|
| **P0** | **SEL-B2** | Battle from Scene (BLK-1 + BLK-2) | M | — |
| P1 | SEL-B1 | Fix `giveItem` → Bag | S | — |
| P1 | SEL-B6 | New Game flow overlay | M | — |
| P2 | SEL-B4 | `givePokemon` mutation (si Config A) | S | SEL-B1 |
| P2 | SEL-B5 | Passage conditionnel (NPC bloqueur émulé) | S | — |
| P3 | SEL-B3 | Wild battle from Scene (boss phare) | M | SEL-B2 |
| P3 | SEL-B9 | `completeStep` direct (pas via cutscene) | S | — |
| P4 | SEL-B10 | Validator minimal (reachability) | S | — |

---

## 9. Commandes exécutées

| # | Commande / Action | But |
|---|---|---|
| 1 | Lecture `scenario_runtime_executor.dart:200-700` | Comprendre dispatch, continuation, emitOutcome |
| 2 | Lecture `scenario_runtime_models.dart` (278 lignes complètes) | Modèles source event, effect, context |
| 3 | Lecture `battle_start_request.dart` (140 lignes complètes) | Modèles BattleStartRequest, RuntimeBattleSourceKind |
| 4 | Lecture `playable_map_game.dart:4030-4505` | Battle handoff, _onBattleFinished, write-back |
| 5 | Lecture `playable_map_game.dart:2085-2320` | Scenario dispatch, continuation, step completion |
| 6 | Lecture `playable_map_game.dart:4570-4660` | _handleInteract, entity interaction → scenario dispatch |
| 7 | Lecture `runtime_battle_outcome_apply.dart` (412 lignes complètes) | Write-back post-combat |
| 8 | Lecture `step_studio_completion_runtime.dart` (130 lignes complètes) | Step completion index |
| 9 | Lecture `cutscene_runtime_models.dart:245-313` | CutsceneEmitOutcomeStep et step types |
| 10 | Lecture `script_command_executor.dart:200-250` | giveItem → metadata (pas Bag) |
| 11 | Lecture `game_state_mutations.dart:137-152` | giveItem mutation → metadata |
| 12 | `rg RuntimeBattleSourceKind.script` | Confirmé : valeur enum existe, jamais utilisée |
| 13 | `rg emitOutcome` | Confirmé : executor + cutscene step |
| 14 | `rg dispatchContinuation` | Confirmé : seul point de reprise existant |
| 15 | `rg _RuntimeFlowPhase` | Enum: overworld, blockingInteraction, dialogue, mapTransition, battleTransition, battle |

---

## 10. Fichiers créés / modifiés

| Action | Fichier |
|---|---|
| CRÉÉ | `reports/gameplay/sel_a2_event_scene_outcome_fact_contract.md` (ce rapport) |
| Modifié | aucun |

---

## 11. Git status final

```
À exécuter :
git status --short --untracked-files=all
```

Résultat attendu :
```
?? reports/gameplay/sel_a2_event_scene_outcome_fact_contract.md
```

---

*Rapport SEL-A2 généré le 2026-05-23. Aucun code de production, test, fixture, ou fichier generated n'a été modifié.*
