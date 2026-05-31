# NS-SCENES-V1-34 — World Rules Runtime Projection Hook V0

## Resume executif

V1-34 ajoute un hook runtime borne pour appliquer les World Rules projetees au monde jouable sans transformer les World Rules en consequences et sans muter les sources.

Le nouveau `RuntimeWorldRuleProjectionHook` lit :

- `ProjectManifest.worldRules`;
- le `GameState` courant ou recharge;
- la `MapData` courante;
- la projection pure `projectWorldRuleEffects`.

Il produit un `RuntimeWorldRuleProjectionState` avec :

- `hiddenEntityIds`;
- `visibleEntityIds`;
- `disabledEventIds`;
- `hiddenEventIds`;
- `enabledEventIds`;
- `npcDialogueOverrides`.

Integration runtime limitee :

- presence PNJ combinee avec les World Rules `entityVisible` / `entityHidden`;
- override de dialogue PNJ via `npcDialogueOverride`;
- interaction d'event bloquee par `eventDisabled` / `eventHidden`;
- `eventEnabled` peut reautoriser un event dont la page active est disabled;
- refresh presence PNJ apres commit de `GameState` par `SceneEventRuntimeHook`.

Non realise volontairement :

- pas de nouveau modele Fact/WorldRule;
- pas de nouvelle consequence Scene;
- pas d'application definitive sur `GameState`, `ProjectManifest` ou `MapData`;
- pas de manager UI;
- pas de BranchByOutcome;
- pas de seed Selbrume.

## Design / architecture gate

Decision : conserver `projectWorldRuleEffects` comme source de verite core, puis ajouter un adapter runtime dans `map_runtime`.

Flux retenu :

```text
ProjectManifest.worldRules
        +
GameState courant/recharge
        +
MapData courante
        |
        v
projectWorldRuleEffects(...)
        |
        v
RuntimeWorldRuleProjectionState
        |
        +-- presence PNJ
        +-- dialogue override PNJ
        +-- disponibilite des map events
```

Pourquoi un read model runtime :

- le core garde une projection pure, sans dependance Flutter/Flame;
- le runtime garde une decision locale, testable et non persistante;
- aucune World Rule ne devient une action qui ecrit dans le monde;
- les conflits simples sont resolus deterministiquement dans l'ordre trie par `projectWorldRuleEffects`.

Regle de priorite runtime V0 :

- `projectWorldRuleEffects` trie par `priority`, puis `ruleId`;
- le read model applique les effets dans cet ordre;
- le dernier effet incompatible gagne pour la meme cible :
  - `entityHidden` retire `entityVisible`;
  - `entityVisible` retire `entityHidden`;
  - `eventEnabled`, `eventDisabled`, `eventHidden` s'excluent entre eux.

## Scope realise

Ajoute :

- service runtime `RuntimeWorldRuleProjectionHook`;
- read model `RuntimeWorldRuleProjectionState`;
- export public depuis `map_runtime.dart`;
- tests runtime dedies;
- integration `PlayableMapGame` :
  - presence PNJ;
  - dialogue PNJ override;
  - interaction event enabled/disabled/hidden;
  - refresh presence PNJ apres Scene runtime commit.

Non ajoute :

- aucune nouvelle World Rule;
- aucun Fact runtime nouveau;
- aucun nouveau payload Scene;
- aucun write WorldRule -> `GameState`;
- aucun changement map_editor;
- aucun changement map_battle/map_gameplay/examples.

## Fichiers crees / modifies

### Crees

- `packages/map_runtime/lib/src/application/world_rules/runtime_world_rule_projection_hook.dart`
- `packages/map_runtime/test/world_rules_runtime_projection_hook_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_34_world_rules_runtime_projection_hook_v0.md`

### Modifies

- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

### Preexistants non V1-34 observes au debut

Ces fichiers etaient deja modifies/non suivis avant V1-34 et n'ont pas ete revert :

- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `packages/map_runtime/test/scene_runtime_state_persistence_gate_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_33_runtime_state_persistence_gate_v0.md`

## Operation runtime ajoutee

API :

```dart
const RuntimeWorldRuleProjectionHook().resolve(
  project: project,
  gameState: gameState,
  map: map,
);
```

Retour :

```dart
RuntimeWorldRuleProjectionState(
  hiddenEntityIds: ...,
  visibleEntityIds: ...,
  disabledEventIds: ...,
  hiddenEventIds: ...,
  enabledEventIds: ...,
  npcDialogueOverrides: ...,
)
```

Helpers runtime :

- `isMapEntityVisible(entity, defaultVisible: ...)`;
- `isMapEventHidden(event, defaultHidden: ...)`;
- `canTriggerMapEvent(event, defaultEnabled: ...)`;
- `dialogueOverrideForEntity(entityId)`.

## Effets World Rules V0 supportes

Supporte :

- `WorldRuleEffectKind.entityVisible`;
- `WorldRuleEffectKind.entityHidden`;
- `WorldRuleEffectKind.eventEnabled`;
- `WorldRuleEffectKind.eventDisabled`;
- `WorldRuleEffectKind.eventHidden`;
- `WorldRuleEffectKind.npcDialogueOverride`.

Sources supportees indirectement via `projectWorldRuleEffects` :

- Fact;
- StoryStep completion;
- consumed event.

Les tests V1-34 couvrent Fact et consumed event. Les tests core existants couvrent StoryStep completion dans la projection pure.

## Integration `PlayableMapGame`

### Presence PNJ

Avant V1-34 :

- `isNpcRuntimePresentOnMap` combinait deja visibilite PNJ auteur + Step Studio world presence.

Apres V1-34 :

- le resultat existant devient `defaultVisible`;
- `RuntimeWorldRuleProjectionState.isMapEntityVisible` peut le forcer visible/cache.

### Dialogue PNJ

Avant V1-34 :

- `MapEntityRuntimePredicateEvaluator.resolveNpcDialogue` resolvait variantes conditionnelles puis dialogue par defaut.

Apres V1-34 :

- une World Rule `npcDialogueOverride` active peut fournir un `DialogueRef(dialogueId: overrideId)`;
- sinon le chemin existant reste identique.

### Map events

Avant V1-34 :

- une page `isDisabled` bloquait l'interaction;
- aucune World Rule runtime n'intervenait.

Apres V1-34 :

- `eventDisabled` bloque l'interaction;
- `eventHidden` bloque aussi l'interaction;
- `eventEnabled` peut rendre triggerable un event dont la page active est disabled;
- si aucune projection n'est disponible, le comportement legacy `isDisabled` reste conserve.

### Refresh apres Scene

Quand `SceneEventRuntimeHook` retourne un `updatedGameState`, `PlayableMapGame` :

- remplace `_gameState`;
- appelle `_refreshWorldNpcPresence()`.

Les events relisent la projection a chaque tentative d'interaction.

## Tests executes

### RED TDD initial

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/world_rules_runtime_projection_hook_test.dart
```

Sortie utile :

```text
Error: Couldn't find constructor 'RuntimeWorldRuleProjectionHook'.
Some tests failed.
```

Interpretation : echec attendu, le test reference le hook pas encore implemente.

### Tests runtime

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/world_rules_runtime_projection_hook_test.dart
```

Resultat :

```text
00:02 +13: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_runtime_state_persistence_gate_test.dart
```

Resultat :

```text
00:01 +4: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_event_runtime_hook_test.dart
```

Resultat :

```text
00:02 +20: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_consequence_runtime_writer_test.dart
```

Resultat :

```text
00:02 +9: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_runtime_golden_slice_smoke_test.dart
```

Resultat :

```text
00:01 +3: All tests passed!
```

Note execution : deux lancements Flutter paralleles ont echoue sur le verrou/native asset macOS, puis les memes commandes ont ete relancees sequentiellement et passent.

Sortie d'incident :

```text
Failed to change install names in LocalFile: '/Users/karim/Project/pokemonProject/packages/map_runtime/build/native_assets/macos/objective_c.dylib':
id -> /Users/karim/Project/pokemonProject/packages/map_runtime/build/native_assets/macos/objective_c.dylib
dependencies -> /Users/karim/Project/pokemonProject/packages/map_runtime/build/native_assets/macos/objective_c.dylib
error: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/install_name_tool: can't open file: /Users/karim/Project/pokemonProject/packages/map_runtime/build/native_assets/macos/objective_c.dylib (No such file or directory)
```

### Tests core

Commande :

```bash
cd packages/map_core && dart test test/world_rule_projection_test.dart
```

Resultat :

```text
00:00 +3: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/world_rule_diagnostics_test.dart
```

Resultat :

```text
00:00 +3: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_plan_test.dart
```

Resultat :

```text
00:02 +15: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_executor_test.dart
```

Resultat :

```text
00:01 +20: All tests passed!
```

## Analyze

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

Commande :

```bash
cd packages/map_runtime && flutter analyze --no-fatal-infos lib/map_runtime.dart lib/src/application/world_rules/runtime_world_rule_projection_hook.dart lib/src/presentation/flame/playable_map_game.dart test/world_rules_runtime_projection_hook_test.dart
```

Sortie :

```text
Analyzing 4 items...
No issues found! (ran in 2.1s)
```

## Mutations interdites verifiees

V1-34 ne modifie pas :

- `packages/map_editor/**`;
- `packages/map_battle/**`;
- `packages/map_gameplay/**`;
- `examples/**`;
- donnees Selbrume.

V1-34 ne branche pas :

- `StorylineStep.sceneLinkIds` runtime;
- `ScenarioRuntimeExecutor` comme moteur Scene V1;
- `ScenarioAsset` comme modele Scene V1;
- BranchByOutcome;
- outcomes Yarn detailles;
- nouveau payload/consequence Scene.

## Roadmap

`road_map_scenes.md` et `road_map_scene_builder_authoring.md` marquent maintenant V1-34 comme DONE.

Prochain lot recommande :

```text
NS-SCENES-V1-35 — Facts & World Rules Manager UI V0
```

Raison : la projection runtime est maintenant branchee prudemment. Le prochain blocage produit est l'authoring/gestion centralise de Facts et World Rules, pour eviter que l'utilisateur doive les comprendre uniquement via l'overview ou les panneaux contextuels.

## Evidence Pack

### pwd

```text
/Users/karim/Project/pokemonProject
```

### git branch --show-current

```text
main
```

### git status initial exact

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_runtime/test/scene_runtime_state_persistence_gate_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_33_runtime_state_persistence_gate_v0.md
```

### git diff --stat initial

```text
 .../scenes/road_map_scene_builder_authoring.md          | 15 +++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md       | 17 ++++++++++++++---
 2 files changed, 27 insertions(+), 5 deletions(-)
```

### git log --oneline -n 15

```text
29c78ea8 chore(scenes): add v1-32 readiness checkpoint report
49fc181c chore(scenes): add v1-31-bis evidence report
9d012e04 feat(scenes): add scene consequence authoring UI
f1e371d8 feat(scenes): add node deletion UX
df2998d3 feat(scenes): add node payload editing v0
84587492 feat(scenes): add storyline step scene links v0
acd71317 feat(scenes): add scene runtime golden slice smoke v0
44de8cc2 feat(scenes): add dialogue runtime awaitable adapter v0
20e51eca feat(scenes): add battle runtime outcome adapter v0
326e939c feat(scenes): add scene consequence runtime write v0
a6b46779 feat(scenes): add scene consequence model v0
d35b3987 feat(scenes): add map event sceneTarget runtime hook v0
54acda44 feat(scenes): add golden slice selbrume readiness
c480c4f5 test(scenes): refine world rule empty state handling
ac3b389c feat(scenes): add world rules map editor integration v0
```

### Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_33_runtime_state_persistence_gate_v0.md`
- `packages/map_core/lib/src/models/world_rule.dart`
- `packages/map_core/lib/src/projection/world_rule_projection.dart`
- `packages/map_core/lib/src/diagnostics/world_rule_diagnostics.dart`
- `packages/map_core/lib/src/read_models/world_rule_target_context_read_model.dart`
- `packages/map_core/lib/src/models/narrative_fact.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/test/world_rule_projection_test.dart`
- `packages/map_runtime/lib/map_runtime.dart`
- `packages/map_runtime/lib/src/application/runtime_map_bundle.dart`
- `packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart`
- `packages/map_runtime/lib/src/application/npc_runtime_presence.dart`
- `packages/map_runtime/lib/src/application/runtime_story_branching.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/scene_runtime_state_persistence_gate_test.dart`
- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`
- `packages/map_runtime/test/scene_consequence_runtime_writer_test.dart`
- `packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart`

### Contenu cree principal

Fichier : `packages/map_runtime/lib/src/application/world_rules/runtime_world_rule_projection_hook.dart`

```dart
import 'package:map_core/map_core.dart';

final class RuntimeWorldRuleProjectionHook {
  const RuntimeWorldRuleProjectionHook();

  RuntimeWorldRuleProjectionState resolve({
    required ProjectManifest project,
    required GameState gameState,
    required MapData map,
  }) {
    final effects = projectWorldRuleEffects(
      project,
      gameState,
      maps: [map],
      mapId: map.id,
    );
    return RuntimeWorldRuleProjectionState.fromResolvedEffects(effects);
  }
}
```

Le fichier contient aussi `RuntimeWorldRuleProjectionState` avec sets/maps immutables et les helpers `isMapEntityVisible`, `isMapEventHidden`, `canTriggerMapEvent`, `dialogueOverrideForEntity`.

Fichier : `packages/map_runtime/test/world_rules_runtime_projection_hook_test.dart`

Couverture creee :

- Fact-backed `entityHidden`;
- `entityVisible`;
- `eventDisabled`;
- `eventEnabled`;
- consumed-event-backed `eventHidden`;
- `npcDialogueOverride`;
- autre map ignoree;
- World Rule disabled ignoree;
- liste vide;
- Scene-written Fact -> event disabled;
- Scene-written Fact -> entity hidden;
- Scene consequence -> `GameState` -> projection runtime;
- reloaded Scene-written Fact -> projection runtime.

### git status final exact

```text
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_runtime/lib/src/application/world_rules/runtime_world_rule_projection_hook.dart
?? packages/map_runtime/test/scene_runtime_state_persistence_gate_test.dart
?? packages/map_runtime/test/world_rules_runtime_projection_hook_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_33_runtime_state_persistence_gate_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_34_world_rules_runtime_projection_hook_v0.md
```

Note : `scene_runtime_state_persistence_gate_test.dart` et `ns_scenes_v1_33_runtime_state_persistence_gate_v0.md` etaient deja non suivis au debut du lot.

### git diff --stat final

```text
 packages/map_runtime/lib/map_runtime.dart          |  2 +
 .../src/presentation/flame/playable_map_game.dart  | 51 +++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     | 28 +++++++++++-
 reports/narrativeStudio/scenes/road_map_scenes.md  | 30 +++++++++++--
 4 files changed, 104 insertions(+), 7 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Les nouveaux fichiers V1-34 apparaissent dans `git status final exact`.

### git diff --name-only final

```text
packages/map_runtime/lib/map_runtime.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

### git diff --check final

```text
Sortie : <vide>
```

### Check anti-scope packages interdits

Commande :

```bash
git diff --name-only -- packages/map_editor packages/map_battle packages/map_gameplay examples selbrume
```

Sortie :

```text
Sortie : <vide>
```

### Recherches anti-scope

Commande :

```bash
rg -n "BranchByOutcome|accepted|refused|choice_|giveItem|teleport|completeStoryStep|StorylineStep|sceneLinkIds|ScenarioRuntimeExecutor|ScenarioAsset|CinematicAsset|DialogueOutcome" packages/map_runtime/lib packages/map_runtime/test packages/map_core/lib packages/map_core/test || true
```

Resultat : la commande retourne des occurrences historiques dans des tests/fichiers legacy existants (`ScenarioRuntimeExecutor`, `ScenarioAsset`, `giveItem`, `StorylineStep.sceneLinkIds`, `BranchByOutcome`, etc.). Les fichiers V1-34 crees/modifies n'ajoutent pas ces mecanismes comme nouvelle capacite Scene V1.

Commande :

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_runtime/lib packages/map_runtime/test packages/map_core/lib packages/map_core/test reports/narrativeStudio/scenes/ns_scenes_v1_34_world_rules_runtime_projection_hook_v0.md || true
```

Resultat : la commande retourne des occurrences historiques deja presentes dans tests/fixtures P6, catalogues existants et la ligne de git log reprise dans ce rapport. Aucun fichier V1-34 de code runtime/core ne cree de donnee produit Selbrume.

### Auto-review critique

- Le hook est volontairement un read model runtime, pas un moteur d'effets. C'est conforme a la decision V1-20/V1-33.
- L'application visuelle des events caches depend encore du rendu event existant : V1-34 bloque l'interaction et expose `isMapEventHidden`, mais ne cree pas un systeme de rendu event separe.
- `eventEnabled` peut override une page active disabled uniquement dans le chemin interaction runtime. Ce comportement est utile mais devra rester visible en diagnostics/manager UI pour eviter des surprises auteur.
- La projection est recalculee a la demande dans `PlayableMapGame`; si les World Rules deviennent nombreuses, un cache invalidable par `GameState`/map pourra etre utile.

### Regard critique sur le prompt

Le prompt est juste de ralentir l'application runtime : il force a garder les World Rules comme projection et non comme mutation. Le seul point a surveiller est la demande "apply to runtime view/behavior" : V1-34 couvre le comportement et la presence PNJ, mais ne doit pas devenir un chantier complet de rendu dynamique d'events. Le prochain lot UI Manager est donc plus pertinent qu'un durcissement runtime immediat.
