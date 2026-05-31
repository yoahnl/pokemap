# NS-SCENES-V1-33 — Runtime State Persistence Gate V0

## Résumé exécutif

V1-33 ferme le verrou persistence ciblé identifié par V1-32. Un test runtime dédié prouve maintenant la chaîne complète :

```text
MapEventPage.sceneTarget
-> SceneEventRuntimeHook
-> SceneRuntimeExecutor
-> SceneConsequenceRuntimeWriter
-> GameState updated
-> FileGameSaveRepository.save
-> LoadGameUseCase
-> Conditions Scene V1
-> projectWorldRuleEffects
```

Les conséquences V0 `setFact` et `markEventConsumed` écrites par une Scene V1 complétée survivent au save/reload, puis restent lisibles par une Condition Scene V1 et par la projection pure des World Rules. Aucun code production n'a été modifié.

## Scope réalisé

- Ajout du test runtime ciblé `packages/map_runtime/test/scene_runtime_state_persistence_gate_test.dart`.
- Mise à jour de `reports/narrativeStudio/scenes/road_map_scenes.md`.
- Mise à jour de `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`.
- Création du présent rapport.

## Décision technique

Le gate utilise les vraies briques runtime et persistence déjà présentes. La fixture reste neutre et en mémoire côté projet/map. Le repository de sauvegarde utilisé est une sous-classe test de `FileGameSaveRepository` qui redirige seulement le chemin vers un répertoire temporaire ; la logique `save/load` reste celle du runtime.

Le test couvre quatre preuves distinctes :

1. `setFact(fact_persistence_gate_open, true)` et `markEventConsumed(map_persistence_test, event_scene_persistence_test)` sont appliqués au `GameState` par le hook runtime.
2. Le JSON écrit contient `storyFlags.activeFlags`, `progression.storyFlags` et `consumedEventIds`.
3. Après reload, une Condition Scene V1 relit le Fact et l'event consumed.
4. Après reload, `projectWorldRuleEffects` relit le Fact et l'event consumed sans muter le `GameState`.

## Non-objectifs confirmés

- Aucun World Rules runtime projection hook.
- Aucun effet visuel appliqué au monde runtime.
- Aucun nouveau node, payload ou type de conséquence.
- Aucune modification editor, battle, gameplay ou examples.
- Aucune mutation de `ProjectManifest` pour stocker l'état runtime.
- Aucun golden slice jouable complet.
- Aucune donnée produit ciblée ou fixture produit.

## Fichiers créés/modifiés

Créé :

- `packages/map_runtime/test/scene_runtime_state_persistence_gate_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_33_runtime_state_persistence_gate_v0.md`

Modifiés :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## Tests et analyses

Commande :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_runtime_state_persistence_gate_test.dart
```

Résultat exact utile :

```text
00:01 +4: All tests passed!
```

Commande :

```bash
cd packages/map_runtime && flutter analyze --no-fatal-infos test/scene_runtime_state_persistence_gate_test.dart
```

Résultat exact :

```text
Analyzing scene_runtime_state_persistence_gate_test.dart...
No issues found! (ran in 1.7s)
```

Commandes runtime de non-régression :

```bash
cd packages/map_runtime && flutter test --reporter=compact test/scene_event_runtime_hook_test.dart
cd packages/map_runtime && flutter test --reporter=compact test/scene_consequence_runtime_writer_test.dart
cd packages/map_runtime && flutter test --reporter=compact test/scene_runtime_golden_slice_smoke_test.dart
cd packages/map_runtime && flutter test --reporter=compact test/p3_save_load_narrative_state_roundtrip_test.dart
cd packages/map_runtime && flutter test --reporter=compact test/p5_gameplay_save_load_beta_roundtrip_test.dart
```

Résultats exacts utiles :

```text
scene_event_runtime_hook_test.dart: 00:01 +20: All tests passed!
scene_consequence_runtime_writer_test.dart: 00:01 +9: All tests passed!
scene_runtime_golden_slice_smoke_test.dart: 00:01 +3: All tests passed!
p3_save_load_narrative_state_roundtrip_test.dart: 00:01 +2: All tests passed!
p5_gameplay_save_load_beta_roundtrip_test.dart: 00:01 +1: All tests passed!
```

Commandes map_core :

```bash
cd packages/map_core && dart test test/scene_runtime_plan_test.dart
cd packages/map_core && dart test test/scene_runtime_executor_test.dart
cd packages/map_core && dart test test/scene_consequence_model_test.dart
cd packages/map_core && dart test test/world_rule_projection_test.dart
cd packages/map_core && dart analyze
```

Résultats exacts utiles :

```text
scene_runtime_plan_test.dart: 00:00 +15: All tests passed!
scene_runtime_executor_test.dart: 00:00 +20: All tests passed!
scene_consequence_model_test.dart: 00:00 +8: All tests passed!
world_rule_projection_test.dart: 00:00 +3: All tests passed!
dart analyze: No issues found!
```

## Gate 0

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 15
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
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
54acda44 feat(scenes): add golden slice Selbrume readiness
c480c4f5 test(scenes): refine world rule empty state handling
ac3b389c feat(scenes): add world rules map editor integration v0
```

Notes :

- `git status --short --untracked-files=all` initial : Sortie : `<vide>`.
- `git diff --stat` initial : Sortie : `<vide>`.
- `git diff --name-only` initial, relancé avant édition : Sortie : `<vide>`.

## Fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_32_scene_v1_beta_readiness_checkpoint.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_31_bis_scene_consequence_runtime_evidence_sweep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_31_scene_consequence_authoring_ui_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_octies_golden_slice_runtime_smoke_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_quinquies_scene_consequence_runtime_write_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_quater_scene_consequence_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_20_world_rules_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_18_fact_registry_v0.md`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/scene_consequence.dart`
- `packages/map_core/lib/src/models/narrative_fact.dart`
- `packages/map_core/lib/src/models/world_rule.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_executor.dart`
- `packages/map_core/lib/src/projection/world_rule_projection.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_host_callbacks.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_runtime_hook_result.dart`
- `packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart`
- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`
- `packages/map_runtime/test/scene_consequence_runtime_writer_test.dart`
- `packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart`
- `packages/map_runtime/test/p3_save_load_narrative_state_roundtrip_test.dart`
- `packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart`

## Evidence Pack

Le fichier `packages/map_runtime/test/scene_runtime_state_persistence_gate_test.dart` contient :

- une fixture `ProjectManifest` avec Fact, World Rules et trois Scenes neutres ;
- une `MapData` neutre avec `event_scene_persistence_test` et `event_gate` ;
- une Scene d'écriture avec `ActionNode` `setFact` puis `markEventConsumed` ;
- deux Scenes conditionnelles de lecture après reload ;
- une sous-classe test de `FileGameSaveRepository` redirigée vers un dossier temporaire ;
- quatre tests couvrant write, save/reload, Conditions et World Rules projection.

Extrait structurel du test :

```text
Scene runtime state persistence gate
- Scene-written setFact and markEventConsumed survive save and reload
- Reloaded Scene-written Fact is readable by Scene condition source
- Reloaded Scene-written consumed event is readable by condition source
- Reloaded Scene-written Fact and consumed event are readable by pure World Rules projection
```

## Auto-review critique

- Le gate est volontairement un test d'intégration runtime ciblé, pas un test visuel du monde jouable.
- Le test ne prouve pas encore qu'une World Rule modifie l'état visuel/actif d'un event en runtime ; c'est le lot suivant.
- La lecture Condition est prouvée via le callback de condition du hook, cohérent avec l'architecture actuelle où l'executor délègue l'évaluation au host.
- Aucun bug de production n'a été identifié ; aucune correction production n'était justifiée.

## Checks anti-scope

Commande :

```bash
git diff --name-only -- packages/map_editor packages/map_battle packages/map_gameplay examples packages/map_runtime
```

Sortie :

```text
<vide>
```

Commande :

```bash
rg -n "WorldRuleEffect|projectWorldRuleEffects\(|applyWorldRule|apply.*WorldRule|entityVisible|entityHidden|eventEnabled|eventDisabled|BranchByOutcome|accepted|refused|choice_|giveItem|teleport|completeStoryStep|StorylineStep|sceneLinkIds|ScenarioRuntimeExecutor|ScenarioAsset" packages/map_runtime/lib packages/map_runtime/test packages/map_core/lib packages/map_core/test || true
```

Résultat : la commande remonte des symboles historiques existants dans `map_core`, `map_runtime` et leurs tests legacy. Le changement V1-33 n'ajoute aucun code production et n'ajoute que le test ciblé `scene_runtime_state_persistence_gate_test.dart`, dont les nouveaux usages de `WorldRuleEffect` et `projectWorldRuleEffects` servent uniquement à prouver la projection pure après reload.

Commande :

```bash
rg -n "<termes produit interdits du prompt>" packages/map_runtime/lib packages/map_runtime/test packages/map_core/lib packages/map_core/test reports/narrativeStudio/scenes/ns_scenes_v1_33_runtime_state_persistence_gate_v0.md || true
```

Résultat : la commande remonte des occurrences historiques existantes hors V1-33 dans des tests et catalogues legacy. Le nouveau test V1-33 et le présent rapport ne créent aucune fixture produit.

## Git final

Commande :

```bash
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Sortie :

```text
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_runtime/test/scene_runtime_state_persistence_gate_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_33_runtime_state_persistence_gate_v0.md
 .../scenes/road_map_scene_builder_authoring.md          | 15 +++++++++++++--
 reports/narrativeStudio/scenes/road_map_scenes.md       | 17 ++++++++++++++---
 2 files changed, 27 insertions(+), 5 deletions(-)
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

`git diff --check` : Sortie : `<vide>`.

## Regard critique sur le prompt

Le prompt est bien borné : il évite de mélanger persistence, projection runtime du monde et golden slice jouable. Le point le plus délicat est que les recherches anti-scope peuvent remonter des symboles existants dans `map_core` qui ne sont pas des modifications du lot ; la preuve déterminante reste donc `git diff --name-only` et l'absence de diff hors fichiers autorisés.

## Prochain lot recommandé

`NS-SCENES-V1-34 — World Rules Runtime Projection Hook V0`

Raison : la persistence Scene-specific est maintenant prouvée. Le prochain verrou est d'appliquer au runtime jouable les effets World Rules projetés depuis ce `GameState` restauré, sans changer le contrat Scene ni ajouter de conséquence directe.
