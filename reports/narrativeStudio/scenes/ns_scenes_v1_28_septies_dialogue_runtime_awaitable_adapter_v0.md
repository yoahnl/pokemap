# NS-SCENES-V1-28-septies — Dialogue Runtime Awaitable Adapter V0

## 1. Résumé du lot

V1-28-septies rend le DialogueNode Scene V1 temporellement fiable côté runtime.

Avant ce lot, `PlayableMapGame` ouvrait un dialogue via le chemin existant puis retournait `completed` immédiatement au `SceneRuntimeExecutor`. Désormais, `showDialogue` passe par `SceneDialogueRuntimeAwaitableAdapter`, ouvre le dialogue runtime existant, attend la fermeture réelle de `DialogueOverlayComponent.onFinished`, puis retourne seulement le port Scene `completed`.

Le lot ne crée aucun outcome Yarn, ne parse pas Yarn, n'ajoute aucune conséquence, ne touche pas à `map_core/lib/src`, ne modifie pas l'éditeur, et ne branche pas `StorylineStep.sceneLinkIds`.

## 2. Pourquoi V1-28-septies existe

V1-28-sexies a rendu `BattleNode` awaitable avec un vrai résultat runtime `victory` / `defeat`. Le dernier seam runtime important était le dialogue : une Scene pouvait continuer pendant que le joueur lisait encore le dialogue. Ce lot corrige uniquement ce timing.

Flux livré :

```text
SceneRuntimeExecutor
-> intent showDialogue
-> SceneRuntimeHostCallbacks.showDialogue
-> SceneDialogueRuntimeAwaitableAdapter
-> ouverture du dialogue runtime existant
-> attente DialogueOverlayComponent.onFinished
-> completed
-> suite de la Scene
```

## 3. Rappel du scope

Réalisé :

- adapter awaitable testable hors Flame ;
- résultat typé `completed` / `failed` ;
- request typée avec `dialogueId`, `yarnNodeName`, `requestId`, timestamp ;
- branchement minimal dans `PlayableMapGame` ;
- completion sur vraie fermeture de l'overlay dialogue ;
- failure contrôlé si dialogue absent, déjà actif, flow non overworld, chargement KO ou reset transitoire ;
- tests adapter ;
- tests hook prouvant que les conséquences stagees ne commit pas tant que le dialogue est pending ;
- roadmaps mises à jour.

Non-objectifs respectés :

- pas d'outcomes Yarn ;
- pas de `BranchByOutcome` ;
- pas de parser Yarn ;
- pas de Dialogue Studio ;
- pas de nouvelle conséquence ;
- pas de write `GameState` dans l'adapter dialogue ;
- pas de World Rule direct apply ;
- pas de `StorylineStep.sceneLinkIds` ;
- pas de modification `map_core/lib/src` ;
- pas de modification `map_editor` ;
- pas de donnée Selbrume.

## 4. Gate 0 complet

Commande exécutée avant modification :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 10
```

Signal RED capturé :

```text
/Users/karim/Project/pokemonProject
main
20e51eca feat(scenes): add battle runtime outcome adapter v0
326e939c feat(scenes): add scene consequence runtime write v0
a6b46779 feat(scenes): add scene consequence model v0
d35b3987 feat(scenes): add map event sceneTarget runtime hook v0
54acda44 feat(scenes): add golden slice selbrume readiness
c480c4f5 test(scenes): refine world rule empty state handling
ac3b389c feat(scenes): add world rules map editor integration v0
757f0ad5 docs(scenes): add V1-26-bis evidence hardening report
108b8c3c feat(scenes): add scene runtime executor MVP
c0d43712 feat(scenes): add dialogue and battle authoring ports
```

Interprétation :

```text
git status initial exact : Sortie : <vide>
git diff --stat initial : Sortie : <vide>
git diff --name-only initial : Sortie : <vide>
```

## 5. Changements préexistants vs changements du lot

Changements préexistants : aucun changement non commit au Gate 0.

Changements introduits par V1-28-septies :

- création de l'adapter dialogue awaitable ;
- création du résultat typé associé ;
- création des tests adapter ;
- ajout de tests pending/failure dans le hook runtime ;
- branchement de `PlayableMapGame.showDialogue` sur le nouvel adapter ;
- mise à jour des roadmaps ;
- création du présent rapport.

## 6. Fichiers lus

Instructions et prompt :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `superpowers:test-driven-development`
- `superpowers:verification-before-completion`
- `karpathy-guidelines`
- `/Users/karim/.codex/attachments/e565c7a8-0d24-4dcb-980d-d355d16e2198/pasted-text.txt`

Roadmaps et rapports :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_sexies_battle_runtime_outcome_adapter_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_quinquies_scene_consequence_runtime_write_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_quater_scene_consequence_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_ter_scene_consequence_contract_prep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_bis_event_to_scene_runtime_hook_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_golden_slice_selbrume_scene_event_prep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_27_world_rules_map_editor_integration_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_bis_scene_runtime_executor_evidence_review.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_scene_runtime_executor_mvp.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md`

Core :

- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_executor.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/map_core.dart`

Chemin attendu absent :

```text
Fichier absent : packages/map_core/lib/src/models/project_dialogue.dart
Impact : les définitions de dialogues projet sont portées par `ProjectManifest` et les opérations/export existants, pas par un fichier dédié à ce chemin.
```

Runtime :

- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_battle_runtime_outcome_result.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/dialogue_overlay_component.dart`
- `packages/map_runtime/lib/map_runtime.dart`

Tests :

- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`
- `packages/map_runtime/test/scene_battle_runtime_outcome_adapter_test.dart`
- `packages/map_runtime/test/scene_consequence_runtime_writer_test.dart`
- `packages/map_core/test/scene_runtime_plan_test.dart`
- `packages/map_core/test/scene_runtime_executor_test.dart`

Recherche dialogue runtime :

```bash
rg -n "dialogue|Dialogue|Yarn|showDialogue|openDialogue|closeDialogue|completed|overlay|conversation" packages/map_runtime/lib packages/map_editor/lib packages/map_core/lib
```

## 7. Fichiers créés/modifiés

Fichiers créés :

- `packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_result.dart`
- `packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_septies_dialogue_runtime_awaitable_adapter_v0.md`

Fichiers modifiés :

- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 8. Audit du dialogue runtime path existant

Chemin legacy/runtime existant :

- `PlayableMapGame._buildSceneRuntimeHostCallbacks.showDialogue` ouvrait auparavant un dialogue par `_openScenarioDialogueById(...)`, puis retournait immédiatement `completed`.
- `_openScenarioDialogueById` délègue à `_tryOpenDialogue(...)` avec un `DialogueRef(dialogueId, startNode)`.
- `_tryOpenDialogue` vérifie `overworld`, l'absence d'interaction bloquante, l'absence d'overlay dialogue déjà actif, résout le dialogue via `resolveDialogue`, puis charge une `DialogueSession`.
- `_openDialogue(DialogueSession)` crée `DialogueOverlayComponent`.
- `DialogueOverlayComponent` possède déjà `onFinished`, appelé quand le dialogue est terminé normalement.
- `PlayableMapGame._openDialogue` utilisait déjà `onFinished` pour fermer l'overlay, repasser en `overworld` et exécuter une action post-dialogue éventuelle.

Pourquoi ce n'était pas awaitable pour Scene V1 : le callback Scene retournait `completed` sur le booléen d'ouverture, pas sur `DialogueOverlayComponent.onFinished`.

## 9. Design retenu

Design retenu : adapter hors Flame + launcher injecté.

- `SceneDialogueRuntimeAwaitableAdapter` transforme un `SceneRuntimePlanIntent.showDialogue` en request runtime dialogue.
- Le launcher concret est injecté via `SceneDialogueRuntimeLauncher`.
- Dans `PlayableMapGame`, le launcher concret appelle `_startSceneDialogue`.
- `_startSceneDialogue` résout le dialogue, lance le chargement existant, ouvre l'overlay existant, puis complète un `Completer<SceneDialogueRuntimeAwaitableResult>` sur `DialogueOverlayComponent.onFinished`.
- Les failures contrôlés complètent le même `Completer` avec `failed`.

Ce design garde l'adapter testable sans Flame, ne refond pas le système de dialogue, et ne mélange pas dialogue completion avec conséquences ou progression.

## 10. API Dialogue Runtime Awaitable Adapter

Types publics exportés par `map_runtime.dart` :

- `SceneDialogueRuntimeAwaitableAdapter`
- `SceneDialogueRuntimeDialogueRequest`
- `SceneDialogueRuntimeLauncher`
- `SceneDialogueRuntimeAwaitableResult`
- `SceneDialogueRuntimeAwaitableStatus`
- `SceneDialogueRuntimeAwaitableErrorCode`

## 11. Mapping runtime dialogue completion -> Scene port

Mapping V0 :

| Signal runtime dialogue | Scene port | Statut |
|---|---|---|
| `DialogueOverlayComponent.onFinished` | `completed` | supporté |
| dialogue introuvable / chargement nul | aucun | failed |
| launcher throw | aucun | failed |
| reset transitoire / annulation | aucun | failed |
| outcome/choix Yarn détaillé | aucun | non supporté V0 |

## 12. Outcomes non supportés

V0 ne retourne jamais :

```text
accepted
refused
choice_1
success
failure
```

Le seul port de succès est :

```text
completed
```

Raison : Dialogue Studio / Yarn outcomes n'ont pas encore de contrat public fiable. Inventer un outcome depuis un label ou un choix Yarn casserait le principe no-code honnête.

## 13. Intégration SceneRuntimeHostCallbacks

Avant :

```dart
showDialogue -> _openScenarioDialogueById(...) -> return 'completed'
```

Après :

```dart
showDialogue -> SceneDialogueRuntimeAwaitableAdapter.showDialogue(...)
-> Future<SceneDialogueRuntimeAwaitableResult>
-> result.scenePortId
```

Si le résultat n'est pas un succès ou si `scenePortId == null`, le callback lance une `StateError`, ce qui fait échouer proprement `SceneRuntimeExecutor` via `callbackFailed`.

## 14. Intégration PlayableMapGame

Sections modifiées :

```dart
showDialogue: (intent) {
  final adapter = SceneDialogueRuntimeAwaitableAdapter(
    runtimeSourceId: runtimeSourceId,
    launcher: _CallbackSceneDialogueRuntimeLauncher(
      _startSceneDialogue,
    ),
  );
  return adapter.showDialogue(intent).then((result) {
    final scenePortId = result.scenePortId;
    if (!result.success || scenePortId == null) {
      throw StateError(
        result.message ??
            'Scene V1 dialogue handoff failed '
                '(dialogueId=${intent.dialogueId}, '
                'yarnNodeName=${intent.yarnNodeName}).',
      );
    }
    return scenePortId;
  });
},
```

```dart
Future<SceneDialogueRuntimeAwaitableResult> _startSceneDialogue(
  SceneDialogueRuntimeDialogueRequest request,
)
```

La méthode :

- refuse si le flow n'est pas `overworld` ;
- refuse si un dialogue est déjà actif ou pending ;
- résout le `DialogueRef` existant avec `dialogueId` et `yarnNodeName` ;
- charge la session via `_dialogueSessionLoader` ;
- ouvre l'overlay via `_openDialogue(..., onDialogueFinished: ...)` ;
- complète `completed` uniquement depuis `onDialogueFinished`.

`_openDialogue` accepte maintenant un callback optionnel :

```dart
void _openDialogue(
  DialogueSession session, {
  VoidCallback? onDialogueFinished,
})
```

Ce callback optionnel est uniquement un seam de completion ; le comportement legacy continue d'utiliser `_openDialogue(session)` sans callback.

## 15. Relation avec Scene consequences V0

Le lot ne modifie pas les conséquences.

La garantie importante est temporelle :

```text
Action setFact
-> dialogue pending
-> pas de commit
-> dialogue completed
-> Scene end
-> commit
```

Si le dialogue échoue, les conséquences stagees sont discard par le hook existant.

## 16. Relation avec GameState

L'adapter dialogue ne reçoit pas `GameState`, n'importe pas `SceneConsequenceRuntimeWriter`, ne lit pas de Fact, ne marque pas d'event consumed et n'applique aucune World Rule.

Les writes restent centralisés dans :

```text
SceneEventRuntimeHook
SceneConsequenceRuntimeWriter
```

## 17. Ce qui reste non couvert

- Pas de smoke test runtime complet `PlayableMapGame` pilotant Event -> Dialogue -> Battle -> consequences dans une seule chaîne.
- Pas d'outcomes Yarn détaillés.
- Pas de `BranchByOutcome`.
- Pas de Dialogue Studio.
- Pas de StorylineStep link.

## 18. Pourquoi aucun outcome Yarn n'est inventé

L'adapter ignore `expectedOutcomes` pour le dialogue V0 et retourne seulement `completed`. Les tests vérifient explicitement qu'il ne renvoie pas `accepted`, `refused`, `choice_1`, `success` ou `failure`.

## 19. Pourquoi aucune conséquence n'est écrite par l'adapter dialogue

L'adapter ne dépend que de `SceneRuntimePlanIntent`, d'un launcher et de son résultat. Il n'a aucune API pour recevoir un `GameState` ou une `SceneConsequence`. Le test source vérifie l'absence de `SceneConsequenceRuntimeWriter`, `GameState`, `setFact` et `markEventConsumed` dans le fichier adapter.

## 20. Pourquoi aucune donnée Selbrume n'a été créée

Les tests utilisent uniquement des ids neutres existants dans les fixtures runtime :

```text
map_test_runtime
event_test_scene
dialogue_test_intro
trainer_test_guard
fact_test_scene_done
```

Aucun fichier `selbrume/**` n'est modifié. Aucun nom produit Maël/Lysa/Port des Brisants n'est créé dans le code ou les tests.

## 21. Tests exécutés avec sorties exactes

### RED adapter test

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_dialogue_runtime_awaitable_adapter_test.dart
```

Sortie exacte :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart
test/scene_dialogue_runtime_awaitable_adapter_test.dart:167:16: Error: Type 'SceneDialogueRuntimeLauncher' not found.
    implements SceneDialogueRuntimeLauncher {
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/scene_dialogue_runtime_awaitable_adapter_test.dart:170:18: Error: Type 'SceneDialogueRuntimeAwaitableResult' not found.
  final FutureOr<SceneDialogueRuntimeAwaitableResult> Function(
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/scene_dialogue_runtime_awaitable_adapter_test.dart:171:5: Error: Type 'SceneDialogueRuntimeDialogueRequest' not found.
    SceneDialogueRuntimeDialogueRequest request,
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/scene_dialogue_runtime_awaitable_adapter_test.dart:175:10: Error: Type 'SceneDialogueRuntimeAwaitableResult' not found.
  Future<SceneDialogueRuntimeAwaitableResult> showDialogue(
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/scene_dialogue_runtime_awaitable_adapter_test.dart:176:5: Error: Type 'SceneDialogueRuntimeDialogueRequest' not found.
    SceneDialogueRuntimeDialogueRequest request,
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
00:01 +0 -1: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart [E]
Some tests failed.
```

Le signal attendu est confirmé : les types publics n'existaient pas avant l'implémentation.

### Adapter awaitable

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_dialogue_runtime_awaitable_adapter_test.dart
```

Sortie exacte :

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart
00:02 +0: SceneDialogueRuntimeAwaitableAdapter maps launcher completion to Scene port completed
00:02 +1: SceneDialogueRuntimeAwaitableAdapter maps launcher completion to Scene port completed
00:02 +1: SceneDialogueRuntimeAwaitableAdapter fails clearly when intent has no dialogueId
00:02 +2: SceneDialogueRuntimeAwaitableAdapter fails clearly when intent has no dialogueId
00:02 +2: SceneDialogueRuntimeAwaitableAdapter fails clearly when launcher fails
00:02 +3: SceneDialogueRuntimeAwaitableAdapter fails clearly when launcher fails
00:02 +3: SceneDialogueRuntimeAwaitableAdapter wraps thrown launcher errors as launcher failure
00:02 +4: SceneDialogueRuntimeAwaitableAdapter wraps thrown launcher errors as launcher failure
00:02 +4: SceneDialogueRuntimeAwaitableAdapter does not invent dialogue outcomes
00:02 +5: SceneDialogueRuntimeAwaitableAdapter does not invent dialogue outcomes
00:02 +5: SceneDialogueRuntimeAwaitableAdapter does not mutate GameState or apply Scene consequences directly
00:02 +6: SceneDialogueRuntimeAwaitableAdapter does not mutate GameState or apply Scene consequences directly
00:02 +6: All tests passed!
```

### Hook runtime Scene

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_event_runtime_hook_test.dart
```

Sortie exacte :

```text
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_event_runtime_hook_test.dart
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/scene_event_runtime_hook_test.dart
00:02 +0: SceneEventRuntimeHook ignores event pages without sceneTarget
00:02 +1: SceneEventRuntimeHook ignores event pages without sceneTarget
00:02 +1: SceneEventRuntimeHook fails clearly when sceneTarget references a missing scene
00:02 +2: SceneEventRuntimeHook fails clearly when sceneTarget references a missing scene
00:02 +2: SceneEventRuntimeHook fails before execution when scene diagnostics contain errors
00:02 +3: SceneEventRuntimeHook fails before execution when scene diagnostics contain errors
00:02 +3: SceneEventRuntimeHook fails before execution when runtime plan cannot be built
00:02 +4: SceneEventRuntimeHook fails before execution when runtime plan cannot be built
00:02 +4: SceneEventRuntimeHook executes a targeted Scene V1 through dialogue and battle victory
00:02 +5: SceneEventRuntimeHook executes a targeted Scene V1 through dialogue and battle victory
00:02 +5: SceneEventRuntimeHook executes a targeted Scene V1 through battle defeat branch
00:02 +6: SceneEventRuntimeHook executes a targeted Scene V1 through battle defeat branch
00:02 +6: SceneEventRuntimeHook does not require or promote ScenarioAsset to execute Scene V1
00:02 +7: SceneEventRuntimeHook does not require or promote ScenarioAsset to execute Scene V1
00:02 +7: SceneEventRuntimeHook does not mutate project, map or game state
00:02 +8: SceneEventRuntimeHook does not mutate project, map or game state
00:02 +8: SceneEventRuntimeHook stages setFact consequence and commits it when scene completes
00:02 +9: SceneEventRuntimeHook stages setFact consequence and commits it when scene completes
00:02 +9: SceneEventRuntimeHook stages setFact consequence and waits for pending dialogue
00:02 +10: SceneEventRuntimeHook stages setFact consequence and waits for pending dialogue
00:02 +10: SceneEventRuntimeHook stages markEventConsumed consequence and commits it on completion
00:02 +11: SceneEventRuntimeHook stages markEventConsumed consequence and commits it on completion
00:02 +11: SceneEventRuntimeHook battle victory follows victory branch and commits consequence
00:02 +12: SceneEventRuntimeHook battle victory follows victory branch and commits consequence
00:02 +12: SceneEventRuntimeHook battle defeat follows defeat branch and commits consequence
00:02 +13: SceneEventRuntimeHook battle defeat follows defeat branch and commits consequence
00:02 +13: SceneEventRuntimeHook battle failure discards staged consequence
00:02 +14: SceneEventRuntimeHook battle failure discards staged consequence
00:02 +14: SceneEventRuntimeHook discards staged consequence when later callback fails
00:02 +15: SceneEventRuntimeHook discards staged consequence when later callback fails
00:02 +15: SceneEventRuntimeHook discards staged consequence when awaitable dialogue fails
00:02 +16: SceneEventRuntimeHook discards staged consequence when awaitable dialogue fails
00:02 +16: SceneEventRuntimeHook does not commit consequences when runtime plan fails
00:02 +17: SceneEventRuntimeHook does not commit consequences when runtime plan fails
00:02 +17: SceneEventRuntimeHook does not apply World Rules or complete StorylineStep directly
00:02 +18: SceneEventRuntimeHook does not apply World Rules or complete StorylineStep directly
00:02 +18: SceneEventRuntimeHook reports callback execution failure without mutating state
00:02 +19: SceneEventRuntimeHook reports callback execution failure without mutating state
00:02 +19: SceneEventRuntimeHook keeps Scene V1 hook files independent from battle package imports
00:02 +20: SceneEventRuntimeHook keeps Scene V1 hook files independent from battle package imports
00:02 +20: All tests passed!
```

### Core non-régressions

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_plan_test.dart
```

Sortie exacte :

```text
00:00 +0: loading test/scene_runtime_plan_test.dart
00:00 +15: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_executor_test.dart
```

Sortie exacte :

```text
00:00 +0: loading test/scene_runtime_executor_test.dart
00:00 +20: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_consequence_model_test.dart
```

Sortie exacte :

```text
00:00 +0: loading test/scene_consequence_model_test.dart
00:00 +8: All tests passed!
```

## 22. Analyze avec sortie exacte

Commande :

```bash
cd packages/map_runtime && flutter analyze --no-fatal-infos lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_result.dart lib/src/presentation/flame/playable_map_game.dart lib/map_runtime.dart test/scene_dialogue_runtime_awaitable_adapter_test.dart test/scene_event_runtime_hook_test.dart
```

Sortie exacte :

```text
Analyzing 6 items...
No issues found! (ran in 2.1s)
```

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

## 23. Recherche anti-Selbrume

Commande :

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_runtime/lib/src/application/scene_runtime packages/map_runtime/test reports/narrativeStudio/scenes/ns_scenes_v1_28_septies_dialogue_runtime_awaitable_adapter_v0.md || true
```

Sortie exacte :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_28_septies_dialogue_runtime_awaitable_adapter_v0.md:73:54acda44 feat(scenes): add golden slice selbrume readiness
reports/narrativeStudio/scenes/ns_scenes_v1_28_septies_dialogue_runtime_awaitable_adapter_v0.md:124:- `reports/narrativeStudio/scenes/ns_scenes_v1_28_golden_slice_selbrume_scene_event_prep.md`
reports/narrativeStudio/scenes/ns_scenes_v1_28_septies_dialogue_runtime_awaitable_adapter_v0.md:385:Aucun fichier `selbrume/**` n'est modifié. Aucun nom produit Maël/Lysa/Port des Brisants n'est créé dans le code ou les tests.
packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart:12:const _saveId = 'p6_02_selbrume_initial_party_bag';
packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart:26:      final projectRoot = Directory(p.join(repoRoot.path, 'selbrume'));
packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart:181:      p.join(current.path, 'selbrume', 'project.json'),
packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart:189:      throw StateError('Could not find repo-local selbrume/project.json');
packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart:15:const _saveId = 'p6_06_selbrume_save_load_golden_slice';
packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart:25:const _p603FlagId = 'p6.selbrume.first_interaction.seen';
packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart:26:const _p603StepId = 'p6.selbrume.first_interaction';
packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart:38:      final projectRoot = Directory(p.join(repoRoot.path, 'selbrume'));
packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart:41:          await Directory.systemTemp.createTemp('p6_06_selbrume_save_load_');
packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart:50:        final selbrumeBundle = await loadRuntimeMapBundle(
packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart:60:          selbrumeBundle.projectRootDirectory,
packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart:64:        expect(selbrumeBundle.map.id, _startMapId);
packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart:68:          startMap: selbrumeBundle.map,
packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart:71:          tileWidthPx: selbrumeBundle.manifest.settings.tileWidth,
packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart:72:          tileHeightPx: selbrumeBundle.manifest.settings.tileHeight,
packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart:333:      p.join(current.path, 'selbrume', 'project.json'),
packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart:341:      throw StateError('Could not find repo-local selbrume/project.json');
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart:36:      final projectRoot = Directory(p.join(repoRoot.path, 'selbrume'));
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart:41:      final selbrumeBundle = await loadRuntimeMapBundle(
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart:51:          selbrumeBundle.projectRootDirectory, p.normalize(projectRoot.path));
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart:53:      expect(selbrumeBundle.map.id, _startMapId);
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart:56:        selbrumeBundle.manifest.maps.map((entry) => entry.id),
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart:62:        manifest: selbrumeBundle.manifest,
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart:66:        containsAll(selbrumeBundle.manifest.maps.map((entry) => entry.id)),
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart:85:      final encounterTable = selbrumeBundle.manifest.encounterTables
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart:103:        speciesDir: selbrumeBundle.manifest.pokemon.speciesDir,
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart:112:        relativePath: selbrumeBundle.manifest.pokemon.catalogFiles['moves']!,
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart:122:        relativePath: selbrumeBundle.manifest.pokemon.catalogFiles['items']!,
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart:127:      final grantTrainer = selbrumeBundle.manifest.trainers.singleWhere(
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart:138:        selbrumeBundle.manifest,
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart:271:      p.join(current.path, 'selbrume', 'project.json'),
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart:279:      throw StateError('Could not find repo-local selbrume/project.json');
packages/map_runtime/test/p5_beta_runtime_smoke_test.dart:473:    'selbrume',
packages/map_runtime/test/p5_beta_runtime_smoke_test.dart:474:    'lysa',
packages/map_runtime/test/p5_beta_runtime_smoke_test.dart:477:    'phare',
packages/map_runtime/test/p5_beta_runtime_smoke_test.dart:509:  return values.any((value) => value.toLowerCase().contains('selbrume'));
packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart:15:const _saveId = 'p6_05_selbrume_first_trainer_battle';
packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart:28:const _p603FlagId = 'p6.selbrume.first_interaction.seen';
packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart:29:const _p603StepId = 'p6.selbrume.first_interaction';
packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart:40:      final projectRoot = Directory(p.join(repoRoot.path, 'selbrume'));
packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart:45:      final selbrumeBundle = await loadRuntimeMapBundle(
packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart:55:          selbrumeBundle.projectRootDirectory, p.normalize(projectRoot.path));
packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart:57:      expect(selbrumeBundle.map.id, _startMapId);
packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart:118:        startMap: selbrumeBundle.map,
packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart:121:        tileWidthPx: selbrumeBundle.manifest.settings.tileWidth,
packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart:122:        tileHeightPx: selbrumeBundle.manifest.settings.tileHeight,
packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart:362:      p.join(current.path, 'selbrume', 'project.json'),
packages/map_runtime/test/p6_selbrume_first_trainer_battle_golden_slice_test.dart:370:      throw StateError('Could not find repo-local selbrume/project.json');
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart:13:const _saveId = 'p6_04_selbrume_route_1_encounter_capture';
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart:21:const _p603FlagId = 'p6.selbrume.first_interaction.seen';
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart:22:const _p603StepId = 'p6.selbrume.first_interaction';
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart:31:      final projectRoot = Directory(p.join(repoRoot.path, 'selbrume'));
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart:36:      final selbrumeBundle = await loadRuntimeMapBundle(
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart:46:          selbrumeBundle.projectRootDirectory, p.normalize(projectRoot.path));
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart:47:      expect(selbrumeBundle.map.id, _startMapId);
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart:51:        selbrumeBundle.manifest.maps.map((entry) => entry.id),
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart:125:        startMap: selbrumeBundle.map,
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart:128:        tileWidthPx: selbrumeBundle.manifest.settings.tileWidth,
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart:129:        tileHeightPx: selbrumeBundle.manifest.settings.tileHeight,
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart:302:      p.join(current.path, 'selbrume', 'project.json'),
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart:310:      throw StateError('Could not find repo-local selbrume/project.json');
packages/map_runtime/test/battle_move_visual_catalog_test.dart:1881:        'menacingmoonrazemaelstrom': BattleMoveVisualRecipeId.sdkHex,
packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart:11:const _saveId = 'p6_03_selbrume_first_narrative_interaction';
packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart:14:const _interactionFlagId = 'p6.selbrume.first_interaction.seen';
packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart:15:const _interactionStepId = 'p6.selbrume.first_interaction';
packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart:32:      final projectRoot = Directory(p.join(repoRoot.path, 'selbrume'));
packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart:201:      p.join(current.path, 'selbrume', 'project.json'),
packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart:209:      throw StateError('Could not find repo-local selbrume/project.json');
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:16:      final projectFilePath = p.join(repoRoot.path, 'selbrume', 'project.json');
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:20:      final selbrumeBundle = await loadRuntimeMapBundle(
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:29:      expect(selbrumeBundle.projectRootDirectory,
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:30:          p.normalize(p.join(repoRoot.path, 'selbrume')));
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:31:      expect(selbrumeBundle.manifest.name, 'Selbrume');
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:33:        selbrumeBundle.manifest.maps.map((map) => map.id),
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:36:      expect(selbrumeBundle.manifest.maps.first.id, 'route 1');
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:38:      expect(selbrumeBundle.map.id, 'Selbrume');
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:46:        selbrumeBundle.manifest.trainers.map((trainer) => trainer.id),
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:50:      final startMap = selbrumeBundle.map;
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:63:        tileWidthPx: selbrumeBundle.manifest.settings.tileWidth,
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:64:        tileHeightPx: selbrumeBundle.manifest.settings.tileHeight,
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:71:        saveId: 'p6_01_selbrume_new_game',
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:73:        tileWidthPx: selbrumeBundle.manifest.settings.tileWidth,
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:74:        tileHeightPx: selbrumeBundle.manifest.settings.tileHeight,
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:77:      expect(state.saveId, 'p6_01_selbrume_new_game');
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:93:      p.join(current.path, 'selbrume', 'project.json'),
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart:101:      throw StateError('Could not find repo-local selbrume/project.json');
packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart:12:const _saveId = 'p6_08_selbrume_playable_runtime_smoke';
packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart:18:const _p603FlagId = 'p6.selbrume.first_interaction.seen';
packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart:19:const _p603StepId = 'p6.selbrume.first_interaction';
packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart:28:      final projectRoot = Directory(p.join(repoRoot.path, 'selbrume'));
packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart:33:      final selbrumeBundle = await loadRuntimeMapBundle(
packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart:43:          selbrumeBundle.projectRootDirectory, p.normalize(projectRoot.path));
packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart:45:      expect(selbrumeBundle.map.id, _startMapId);
packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart:47:      expect(selbrumeBundle.tilesetAbsolutePathsById, isNotEmpty);
packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart:49:        selbrumeBundle.tilesetAbsolutePathsById.values.every(
packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart:55:      final state = _buildSeededNewGameState(selbrumeBundle);
packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart:57:        bundle: selbrumeBundle,
packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart:142:      p.join(current.path, 'selbrume', 'project.json'),
packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart:150:      throw StateError('Could not find repo-local selbrume/project.json');
packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart:971:        'mael', 'Maël', 'lysa', 'Lysa', 'soline', 'Soline',
packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart:972:        'selbrume', 'Selbrume', 'Bourg de Selbrume',
packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart:973:        'map_bourg_selbrume', 'map_port_brisants',
packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart:974:        'npc_mael', 'npc_lysa', 'npc_soline',
packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart:975:        'trainer_lysa_port', 'battle_rival_port',
packages/map_runtime/test/ns_gs_12_golden_slice_validation_test.dart:976:        'scene_mael_intro', 'scene_rival_meet',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:45:              mapId: 'port_brisants',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:46:              entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:59:              trainerId: 'trainer_lysa_port',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:60:              entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:82:          mapId: 'port_brisants',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:83:          entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:90:      expect(result.effect.trainerId, 'trainer_lysa_port');
packages/map_runtime/test/scenario_battle_from_scene_test.dart:91:      expect(result.effect.npcEntityId, 'npc_lysa');
packages/map_runtime/test/scenario_battle_from_scene_test.dart:114:              mapId: 'port_brisants',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:115:              entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:126:              trainerId: 'trainer_lysa_port',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:127:              entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:143:          mapId: 'port_brisants',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:144:          entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:152:        'trainer_lysa_port',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:172:              mapId: 'port_brisants',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:173:              entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:185:              entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:201:          mapId: 'port_brisants',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:202:          entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:226:              mapId: 'port_brisants',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:227:              entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:238:              trainerId: 'trainer_lysa_port',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:255:          mapId: 'port_brisants',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:256:          entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:280:              mapId: 'port_brisants',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:281:              entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:292:              trainerId: 'trainer_lysa_port',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:293:              entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:300:            binding: ScenarioNodeBinding(flagName: 'lysa_battle_done'),
packages/map_runtime/test/scenario_battle_from_scene_test.dart:349:      expect(state.storyFlags.activeFlags, contains('lysa_battle_done'));
packages/map_runtime/test/scenario_battle_from_scene_test.dart:367:              mapId: 'port_brisants',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:368:              entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:379:              trainerId: 'trainer_lysa_port',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:380:              entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:399:            binding: ScenarioNodeBinding(dialogueId: 'lysa_victory_speech'),
packages/map_runtime/test/scenario_battle_from_scene_test.dart:404:            binding: ScenarioNodeBinding(dialogueId: 'lysa_defeat_speech'),
packages/map_runtime/test/scenario_battle_from_scene_test.dart:460:      expect(openedDialogues, <String>['lysa_victory_speech']);
packages/map_runtime/test/scenario_battle_from_scene_test.dart:488:      expect(openedDialogues, <String>['lysa_defeat_speech']);
packages/map_runtime/test/scenario_battle_from_scene_test.dart:593:              mapId: 'port_brisants',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:594:              entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:605:              trainerId: 'trainer_lysa_port',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:606:              entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:629:          mapId: 'port_brisants',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:630:          entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:667:              mapId: 'port_brisants',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:668:              entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:679:              trainerId: 'trainer_lysa_port',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:680:              entityId: 'npc_lysa',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:713:          mapId: 'port_brisants',
packages/map_runtime/test/scenario_battle_from_scene_test.dart:714:          entityId: 'npc_lysa',
packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart:255:  return values.any((value) => value.toLowerCase().contains('selbrume'));
packages/map_runtime/test/battle_move_visual_resolver_test.dart:267:        'menacingmoonrazemaelstrom': BattleMoveVisualRecipeId.sdkHex,
```

Interprétation : les occurrences dans le rapport sont contextuelles. Les autres occurrences sont des tests Selbrume / scenario legacy préexistants sous `packages/map_runtime/test` et ne sont pas introduites par V1-28-septies. Les fichiers créés ou modifiés par ce lot ne créent pas de donnée produit Selbrume.

## 24. Recherche anti-scope

Commande :

```bash
rg -n "accepted|refused|choice_|BranchByOutcome|StorylineStep|sceneLinkIds|projectWorldRuleEffects|WorldRuleEffect|setFact|markEventConsumed|giveItem|teleport|hardcoded completed|fake completed" packages/map_runtime/lib/src/application/scene_runtime packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart packages/map_runtime/test/scene_event_runtime_hook_test.dart || true
```

Sortie exacte :

```text
packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart:112:        'accepted',
packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart:113:        'refused',
packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart:114:        'choice_1',
packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart:160:      expect(adapterSource, isNot(contains('setFact')));
packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart:161:      expect(adapterSource, isNot(contains('markEventConsumed')));
packages/map_runtime/test/scene_event_runtime_hook_test.dart:186:    test('stages setFact consequence and commits it when scene completes',
packages/map_runtime/test/scene_event_runtime_hook_test.dart:218:    test('stages setFact consequence and waits for pending dialogue', () async {
packages/map_runtime/test/scene_event_runtime_hook_test.dart:270:    test('stages markEventConsumed consequence and commits it on completion',
packages/map_runtime/test/scene_event_runtime_hook_test.dart:519:    test('does not apply World Rules or complete StorylineStep directly',
packages/map_runtime/test/scene_event_runtime_hook_test.dart:863:      SceneConsequence.setFact(
packages/map_runtime/test/scene_event_runtime_hook_test.dart:874:      SceneConsequence.markEventConsumed(
packages/map_runtime/test/scene_event_runtime_hook_test.dart:894:            SceneConsequence.setFact(
packages/map_runtime/test/scene_event_runtime_hook_test.dart:946:            SceneConsequence.setFact(
packages/map_runtime/test/scene_event_runtime_hook_test.dart:1011:            SceneConsequence.setFact(
packages/map_runtime/test/scene_event_runtime_hook_test.dart:1021:            SceneConsequence.setFact(
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart:48:      SceneConsequenceKind.setFact => _applySetFact(
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart:52:      SceneConsequenceKind.markEventConsumed => _applyMarkEventConsumed(
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart:67:        'Scene consequence setFact references unknown Fact '
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart:88:        'Scene consequence markEventConsumed references unknown map '
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart:97:        'Scene consequence markEventConsumed references unknown event '
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart:102:      mutations.markEventConsumed(gameState, consequence.eventId),
```

Interprétation : `accepted/refused/choice_1` apparaissent uniquement dans un test qui prouve que l'adapter ne les retourne pas. `setFact` et `markEventConsumed` apparaissent dans les tests de staging/commit et dans le writer V1-28-quinquies existant, pas dans l'adapter dialogue. `World Rules` et `StorylineStep` apparaissent dans un test de non-application directe.

## 25. git diff --check

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
Sortie : <vide>
```

## 26. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 packages/map_runtime/lib/map_runtime.dart          |  10 +
 .../src/presentation/flame/playable_map_game.dart  | 217 +++++++++++++++++++--
 .../test/scene_event_runtime_hook_test.dart        | 128 ++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  19 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 ++-
 5 files changed, 376 insertions(+), 21 deletions(-)
```

## 27. git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
packages/map_runtime/lib/map_runtime.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/scene_event_runtime_hook_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 28. git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/scene_event_runtime_hook_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart
?? packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_result.dart
?? packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_28_septies_dialogue_runtime_awaitable_adapter_v0.md
```

## 29. Evidence Pack

### Contenu complet — `packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_result.dart`

```dart
enum SceneDialogueRuntimeAwaitableStatus {
  completed,
  failed,
}

enum SceneDialogueRuntimeAwaitableErrorCode {
  missingDialogueId,
  launcherFailed,
  cancelled,
  unsupportedOutcome,
}

final class SceneDialogueRuntimeAwaitableResult {
  const SceneDialogueRuntimeAwaitableResult._({
    required this.status,
    this.errorCode,
    this.message,
  });

  const SceneDialogueRuntimeAwaitableResult.completed()
      : this._(status: SceneDialogueRuntimeAwaitableStatus.completed);

  const SceneDialogueRuntimeAwaitableResult.failed({
    required SceneDialogueRuntimeAwaitableErrorCode errorCode,
    required String message,
  }) : this._(
          status: SceneDialogueRuntimeAwaitableStatus.failed,
          errorCode: errorCode,
          message: message,
        );

  final SceneDialogueRuntimeAwaitableStatus status;
  final SceneDialogueRuntimeAwaitableErrorCode? errorCode;
  final String? message;

  bool get success => status == SceneDialogueRuntimeAwaitableStatus.completed;

  String? get scenePortId {
    return switch (status) {
      SceneDialogueRuntimeAwaitableStatus.completed => 'completed',
      SceneDialogueRuntimeAwaitableStatus.failed => null,
    };
  }
}
```

### Contenu complet — `packages/map_runtime/lib/src/application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart`

```dart
import 'package:map_core/map_core.dart';

import 'scene_dialogue_runtime_awaitable_result.dart';

abstract interface class SceneDialogueRuntimeLauncher {
  Future<SceneDialogueRuntimeAwaitableResult> showDialogue(
    SceneDialogueRuntimeDialogueRequest request,
  );
}

final class SceneDialogueRuntimeDialogueRequest {
  const SceneDialogueRuntimeDialogueRequest({
    required this.requestId,
    required this.createdAtEpochMs,
    required this.dialogueId,
    this.yarnNodeName,
  });

  final String requestId;
  final int createdAtEpochMs;
  final String dialogueId;
  final String? yarnNodeName;
}

final class SceneDialogueRuntimeAwaitableAdapter {
  const SceneDialogueRuntimeAwaitableAdapter({
    required this.runtimeSourceId,
    required this.launcher,
    this.createdAtEpochMs = _systemNowMs,
  });

  final String runtimeSourceId;
  final SceneDialogueRuntimeLauncher launcher;
  final int Function() createdAtEpochMs;

  Future<SceneDialogueRuntimeAwaitableResult> showDialogue(
    SceneRuntimePlanIntent intent,
  ) async {
    final dialogueId = intent.dialogueId?.trim();
    if (dialogueId == null || dialogueId.isEmpty) {
      return const SceneDialogueRuntimeAwaitableResult.failed(
        errorCode: SceneDialogueRuntimeAwaitableErrorCode.missingDialogueId,
        message: 'Scene dialogue intent is missing dialogueId.',
      );
    }

    final now = createdAtEpochMs();
    final request = SceneDialogueRuntimeDialogueRequest(
      requestId: '$runtimeSourceId:$dialogueId:$now',
      createdAtEpochMs: now,
      dialogueId: dialogueId,
      yarnNodeName: intent.yarnNodeName,
    );

    try {
      return await launcher.showDialogue(request);
    } catch (error) {
      return SceneDialogueRuntimeAwaitableResult.failed(
        errorCode: SceneDialogueRuntimeAwaitableErrorCode.launcherFailed,
        message: 'Scene dialogue launcher failed: $error',
      );
    }
  }
}

int _systemNowMs() => DateTime.now().millisecondsSinceEpoch;
```

### Contenu complet — `packages/map_runtime/test/scene_dialogue_runtime_awaitable_adapter_test.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('SceneDialogueRuntimeAwaitableAdapter', () {
    test('maps launcher completion to Scene port completed', () async {
      final requests = <SceneDialogueRuntimeDialogueRequest>[];
      final adapter = SceneDialogueRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map_test:event_test:0',
        createdAtEpochMs: () => 1234,
        launcher: _SceneTestDialogueLauncher((request) {
          requests.add(request);
          return const SceneDialogueRuntimeAwaitableResult.completed();
        }),
      );

      final result = await adapter.showDialogue(
        SceneRuntimePlanIntent.showDialogue(
          dialogueId: 'dialogue_test_intro',
          yarnNodeName: 'Start',
        ),
      );

      expect(result.status, SceneDialogueRuntimeAwaitableStatus.completed);
      expect(result.scenePortId, 'completed');
      expect(result.success, isTrue);
      expect(requests, hasLength(1));
      expect(requests.single.requestId,
          'scene:map_test:event_test:0:dialogue_test_intro:1234');
      expect(requests.single.createdAtEpochMs, 1234);
      expect(requests.single.dialogueId, 'dialogue_test_intro');
      expect(requests.single.yarnNodeName, 'Start');
    });

    test('fails clearly when intent has no dialogueId', () async {
      var launched = false;
      final adapter = SceneDialogueRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map_test:event_test:0',
        launcher: _SceneTestDialogueLauncher((request) {
          launched = true;
          return const SceneDialogueRuntimeAwaitableResult.completed();
        }),
      );

      final result = await adapter.showDialogue(
        SceneRuntimePlanIntent.showDialogue(dialogueId: '   '),
      );

      expect(result.status, SceneDialogueRuntimeAwaitableStatus.failed);
      expect(
        result.errorCode,
        SceneDialogueRuntimeAwaitableErrorCode.missingDialogueId,
      );
      expect(result.scenePortId, isNull);
      expect(launched, isFalse);
    });

    test('fails clearly when launcher fails', () async {
      final adapter = SceneDialogueRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map_test:event_test:0',
        launcher: _SceneTestDialogueLauncher((request) {
          return const SceneDialogueRuntimeAwaitableResult.failed(
            errorCode: SceneDialogueRuntimeAwaitableErrorCode.cancelled,
            message: 'Dialogue was cancelled.',
          );
        }),
      );

      final result = await adapter.showDialogue(
        SceneRuntimePlanIntent.showDialogue(
          dialogueId: 'dialogue_test_intro',
        ),
      );

      expect(result.status, SceneDialogueRuntimeAwaitableStatus.failed);
      expect(
        result.errorCode,
        SceneDialogueRuntimeAwaitableErrorCode.cancelled,
      );
      expect(result.scenePortId, isNull);
    });

    test('wraps thrown launcher errors as launcher failure', () async {
      final adapter = SceneDialogueRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map_test:event_test:0',
        launcher: _SceneTestDialogueLauncher((request) {
          throw StateError('dialogue overlay failed');
        }),
      );

      final result = await adapter.showDialogue(
        SceneRuntimePlanIntent.showDialogue(
          dialogueId: 'dialogue_test_intro',
        ),
      );

      expect(result.status, SceneDialogueRuntimeAwaitableStatus.failed);
      expect(
        result.errorCode,
        SceneDialogueRuntimeAwaitableErrorCode.launcherFailed,
      );
      expect(result.scenePortId, isNull);
      expect(result.message, contains('dialogue overlay failed'));
    });

    test('does not invent dialogue outcomes', () async {
      final unsupportedPorts = [
        'accepted',
        'refused',
        'choice_1',
        'success',
        'failure',
      ];
      final adapter = SceneDialogueRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map_test:event_test:0',
        launcher: _SceneTestDialogueLauncher((request) {
          return const SceneDialogueRuntimeAwaitableResult.completed();
        }),
      );

      final result = await adapter.showDialogue(
        SceneRuntimePlanIntent.showDialogue(
          dialogueId: 'dialogue_test_intro',
          expectedOutcomes: unsupportedPorts,
        ),
      );

      expect(result.scenePortId, 'completed');
      expect(unsupportedPorts, isNot(contains(result.scenePortId)));
    });

    test('does not mutate GameState or apply Scene consequences directly',
        () async {
      const gameState = GameState(saveId: 'save_dialogue_adapter');
      final before = gameState.toJson();
      final adapter = SceneDialogueRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:map_test:event_test:0',
        launcher: _SceneTestDialogueLauncher((request) {
          return const SceneDialogueRuntimeAwaitableResult.completed();
        }),
      );

      await adapter.showDialogue(
        SceneRuntimePlanIntent.showDialogue(
          dialogueId: 'dialogue_test_intro',
        ),
      );

      expect(gameState.toJson(), before);
      final adapterSource = File(
        'lib/src/application/scene_runtime/'
        'scene_dialogue_runtime_awaitable_adapter.dart',
      ).readAsStringSync();
      expect(adapterSource, isNot(contains('SceneConsequenceRuntimeWriter')));
      expect(adapterSource, isNot(contains('GameState')));
      expect(adapterSource, isNot(contains('setFact')));
      expect(adapterSource, isNot(contains('markEventConsumed')));
    });
  });
}

final class _SceneTestDialogueLauncher implements SceneDialogueRuntimeLauncher {
  const _SceneTestDialogueLauncher(this._handler);

  final FutureOr<SceneDialogueRuntimeAwaitableResult> Function(
    SceneDialogueRuntimeDialogueRequest request,
  ) _handler;

  @override
  Future<SceneDialogueRuntimeAwaitableResult> showDialogue(
    SceneDialogueRuntimeDialogueRequest request,
  ) async {
    return _handler(request);
  }
}
```

### Sections complètes modifiées — `packages/map_runtime/lib/map_runtime.dart`

```dart
export 'src/application/scene_runtime/scene_dialogue_runtime_awaitable_adapter.dart'
    show
        SceneDialogueRuntimeAwaitableAdapter,
        SceneDialogueRuntimeDialogueRequest,
        SceneDialogueRuntimeLauncher;
export 'src/application/scene_runtime/scene_dialogue_runtime_awaitable_result.dart'
    show
        SceneDialogueRuntimeAwaitableErrorCode,
        SceneDialogueRuntimeAwaitableResult,
        SceneDialogueRuntimeAwaitableStatus;
```

### Sections complètes modifiées — `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

```dart
Completer<SceneDialogueRuntimeAwaitableResult>?
    _pendingSceneDialogueCompleter;
String? _pendingSceneDialogueRequestId;
```

```dart
showDialogue: (intent) {
  final adapter = SceneDialogueRuntimeAwaitableAdapter(
    runtimeSourceId: runtimeSourceId,
    launcher: _CallbackSceneDialogueRuntimeLauncher(
      _startSceneDialogue,
    ),
  );
  return adapter.showDialogue(intent).then((result) {
    final scenePortId = result.scenePortId;
    if (!result.success || scenePortId == null) {
      throw StateError(
        result.message ??
            'Scene V1 dialogue handoff failed '
                '(dialogueId=${intent.dialogueId}, '
                'yarnNodeName=${intent.yarnNodeName}).',
      );
    }
    return scenePortId;
  });
},
```

```dart
Future<SceneDialogueRuntimeAwaitableResult> _startSceneDialogue(
  SceneDialogueRuntimeDialogueRequest request,
)
```

```dart
void _completePendingSceneDialogue(
  SceneDialogueRuntimeAwaitableResult result,
)
```

```dart
void _openDialogue(
  DialogueSession session, {
  VoidCallback? onDialogueFinished,
})
```

```dart
final class _CallbackSceneDialogueRuntimeLauncher
    implements SceneDialogueRuntimeLauncher
```

Justification : `playable_map_game.dart` est très long ; le rapport reproduit toutes les nouvelles signatures, tous les champs ajoutés, toutes les méthodes modifiées ou ajoutées et le callback host modifié.

### Sections complètes modifiées — `packages/map_runtime/test/scene_event_runtime_hook_test.dart`

Tests ajoutés :

```dart
test('stages setFact consequence and waits for pending dialogue', () async { ... });
test('discards staged consequence when awaitable dialogue fails', () async { ... });
```

Helpers ajoutés :

```dart
SceneRuntimeIntentCallback _dialogueAdapterCallback(
  Future<SceneDialogueRuntimeAwaitableResult> result,
)
```

```dart
final class _SceneTestDialogueLauncher implements SceneDialogueRuntimeLauncher
```

Justification : le fichier de test complet dépasse mille lignes. Les sections ajoutées complètes sont listées ci-dessus.

## 30. Auto-review critique

- Est-ce que j'ai inventé des outcomes Yarn ? Non.
- Est-ce que j'ai activé BranchByOutcome ? Non.
- Est-ce que j'ai parsé Yarn ? Non.
- Est-ce que j'ai refactoré largement PlayableMapGame ? Non, ajout localisé au callback showDialogue, au seam `_startSceneDialogue`, à `_openDialogue` et au pending cleanup.
- Est-ce que j'ai hardcodé completed par délai artificiel ? Non.
- Est-ce que l'adapter dialogue écrit une conséquence Scene ? Non.
- Est-ce que l'adapter dialogue applique une World Rule ? Non.
- Est-ce que j'ai branché StorylineStep.sceneLinkIds ? Non.
- Est-ce que j'ai modifié map_core/lib/src ? Non.
- Est-ce que j'ai modifié map_editor ? Non.
- Est-ce que j'ai créé des données Selbrume ? Non.
- Est-ce que completed provient d'une vraie fin runtime du dialogue ? Oui : `DialogueOverlayComponent.onFinished`.
- Est-ce que la Scene reste pending tant que le dialogue est pending ? Oui, test `stages setFact consequence and waits for pending dialogue`.
- Est-ce que les conséquences stagées sont discard si le dialogue échoue ? Oui, test `discards staged consequence when awaitable dialogue fails`.
- Est-ce que le prochain lot n'a pas été démarré ? Oui.

## 31. Limites restantes

- Le smoke runtime complet Event -> Scene -> Dialogue -> Battle -> Consequence n'est pas encore codé.
- Les outcomes Yarn détaillés restent hors scope.
- `BranchByOutcome` reste hors scope.
- Le rapport ne transforme pas le dialogue runtime en Dialogue Studio.

## 32. Prochain lot recommandé

Prochain lot recommandé :

```text
NS-SCENES-V1-28-octies — Golden Slice Runtime Smoke V0
```

Raison : Event -> Scene, consequence runtime write, Battle awaitable et Dialogue awaitable sont désormais connectés. Il faut maintenant prouver la chaîne runtime complète dans un smoke test contrôlé avant de toucher à `StorylineStep.sceneLinkIds`.
