# NS-SCENES-V1-37 — CinematicAsset Core Model V0

## 1. Résumé exécutif

V1-37 est réalisé.

Le lot ajoute le modèle core canonique `CinematicAsset` dans `map_core`, distinct de `ScenarioAsset`. Le modèle est volontairement linéaire : une timeline de steps visuels, sans graph, sans branch, sans effet gameplay et sans runtime cinematic.

Le stockage projet est ajouté via `ProjectManifest.cinematics`, rétrocompatible quand la clé JSON est absente ou `null`. Le read contract public expose désormais deux familles clairement séparées :

- `CinematicPublicContractSourceKind.cinematicAsset` pour les `CinematicAsset` canoniques ;
- `CinematicPublicContractSourceKind.scenarioBridge` pour les anciens `ScenarioAsset` Cutscene Studio, toujours `bridgeOnly`.

Le runtime n'est pas modifié. Cutscene Studio n'est pas modifié. Aucune migration legacy n'est créée. Aucune donnée produit Selbrume n'est ajoutée.

Prochain lot recommandé : `NS-SCENES-V1-38 — Cinematics Library V0`.

## 2. Pourquoi V1-37 existe

V1-36 a tranché que Cinematic V1 ne devait pas être un `ScenarioAsset` renommé. V1-37 matérialise cette décision côté core : un asset dédié, stockable, sérialisable, diagnostiquable et exposable aux futurs pickers/workspaces.

Sans ce lot, une future Cinematics Library risquerait de repartir du bridge Cutscene/Scenario, donc de réintroduire des branches, outcomes et effets gameplay dans une cinématique supposée linéaire.

## 3. Rappel du scope

Réalisé :

- modèle `CinematicAsset` ;
- `CinematicTimeline` ;
- `CinematicTimelineStep` ;
- `CinematicActorRef` ;
- `CinematicLegacyBridge` ;
- `ProjectManifest.cinematics` ;
- opérations authoring pures ;
- diagnostics cinematic ;
- contrats publics canonical + bridge ;
- diagnostic Scene project-aware canonical vs bridge ;
- tests core ;
- roadmaps ;
- rapport.

Non réalisé :

- aucune UI ;
- aucune Cinematics Library ;
- aucun Builder V2 ;
- aucun runtime cinematic ;
- aucune migration `ScenarioAsset -> CinematicAsset` ;
- aucune modification `map_editor` ;
- aucune modification `map_runtime` par ce lot ;
- aucun seed Selbrume.

## 4. Gate 0 complet

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 15
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
git status --short --untracked-files=all
Sortie : <vide>
git diff --stat
Sortie : <vide>
git diff --name-only
Sortie : <vide>
7c4667a4 feat(runtime): finalize cinematic v1 bridge decision and battle auto-switch
27ae87af chore(repo): ignore and untrack .idea workspace
1bc426a9 feat(runtime): sync gamepads plugin packages and host tests
2db4a2b4 Merge branch 'runtime-battle-bridge-psdk-restart'
5f6a17b7 feat(scenes): add facts and world rules manager ui v0
dcbf33b3 feat: complete PSDK runtime bridge diagnostics
8b78df97 feat(scenes): add v1-33 v1-34 runtime persistence projection gates
29c78ea8 chore(scenes): add v1-32 readiness checkpoint report
49fc181c chore(scenes): add v1-31-bis evidence report
9d012e04 feat(scenes): add scene consequence authoring UI
f1e371d8 feat(scenes): add node deletion UX
df2998d3 feat(scenes): add node payload editing v0
84587492 feat(scenes): add storyline step scene links v0
acd71317 feat(scenes): add scene runtime golden slice smoke v0
44de8cc2 feat(scenes): add dialogue runtime awaitable adapter v0
```

## 5. Changements préexistants vs changements V1-37

Gate 0 était propre.

Pendant le lot, des modifications hors scope sont apparues dans le worktree :

```text
examples/playable_runtime_host/test/runtime_party_builder_test.dart
packages/map_runtime/lib/src/application/runtime_battle_move_bridge_diagnostics.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/runtime_battle_move_bridge_test.dart
```

Elles ne font pas partie de V1-37 et n'ont pas été modifiées par ce lot. Elles sont documentées comme changements concurrents/hors scope. Aucun `git restore`, `stash`, `reset` ou nettoyage n'a été exécuté.

Changements V1-37 :

```text
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
packages/map_core/lib/map_core.dart
packages/map_core/test/cinematic_asset_test.dart
packages/map_core/test/project_manifest_cinematics_test.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
packages/map_core/test/linked_asset_public_contracts_test.dart
packages/map_core/test/scene_project_diagnostics_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_37_cinematic_asset_core_model_v0.md
```

## 6. Fichiers lus

Instructions :

```text
AGENTS.md
agent_rules.md
skills/README.md
/Users/karim/.codex/attachments/2feb0135-53d6-429f-9e39-9765631655cd/pasted-text.txt
```

Rapports / roadmaps :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_36_cinematic_v1_contract_bridge_decision.md
reports/narrativeStudio/scenes/ns_scenes_v1_35_facts_world_rules_manager_ui_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_22_payload_pickers_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_21_linked_asset_contracts_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_21_prep_linked_asset_public_contracts_audit.md
reports/narrativeStudio/scenes/ns_scenes_v1_10_runtime_execution_prep.md
reports/narrativeStudio/scenes/ns_scenes_v1_00_scene_system_scope_current_state_audit.md
```

Core :

```text
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/script_asset.dart
packages/map_core/lib/src/models/storyline_asset.dart
packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
packages/map_core/lib/src/runtime/scene_runtime_plan.dart
packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/lib/map_core.dart
packages/map_core/test/project_manifest_scenes_test.dart
packages/map_core/test/linked_asset_public_contracts_test.dart
packages/map_core/test/scene_project_diagnostics_test.dart
packages/map_core/test/scene_runtime_plan_test.dart
```

Audit lecture seule editor/runtime :

```text
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/**
packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart
packages/map_runtime/lib/src/application/cutscene_runtime_models.dart
packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
```

## 7. Fichiers créés/modifiés

Créés :

```text
packages/map_core/lib/src/models/cinematic_asset.dart
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
packages/map_core/test/cinematic_asset_test.dart
packages/map_core/test/project_manifest_cinematics_test.dart
packages/map_core/test/cinematic_authoring_operations_test.dart
packages/map_core/test/cinematic_diagnostics_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_37_cinematic_asset_core_model_v0.md
```

Modifiés :

```text
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/map_core.dart
packages/map_core/test/linked_asset_public_contracts_test.dart
packages/map_core/test/scene_project_diagnostics_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 8. Design CinematicAsset retenu

`CinematicAsset` est un modèle manuel pur Dart, exporté par `map_core.dart`.

Champs V0 :

```text
id
title
description?
storylineId?
chapterId?
mapId?
tags
requiredActors
timeline
notes?
metadata
legacyBridge?
```

Contraintes :

- `id` et `title` sont obligatoires et non vides ;
- les tags sont trim/dédupliqués ;
- les champs optionnels vides deviennent `null` ;
- pas de dépendance Flutter/Flame/runtime/editor ;
- pas de référence à `ScenarioRuntimeExecutor` ;
- pas d'edge, graph ou branchement.

## 9. Timeline V0

`CinematicTimeline` contient uniquement :

```text
steps: List<CinematicTimelineStep>
```

`CinematicTimelineStep` contient :

```text
id
kind
label?
durationMs?
actorId?
targetId?
dialogueText?
assetRef?
metadata
```

Kinds autorisés :

```text
wait
camera
actorMove
actorFace
actorEmote
dialogueLine
sound
music
fade
shake
fx
marker
```

Kinds volontairement absents :

```text
branch
condition
battle
setFact
markEventConsumed
completeStoryStep
giveItem
teleport
script
scenario
worldRule
```

Les JSON utilisant ces kinds sont rejetés par le parseur enum. Si un import legacy transporte une valeur interdite dans `metadata.legacy.kind`, `diagnoseCinematicAsset` produit `cinematicUnsupportedGameplayStep`.

## 10. Required actors

`CinematicActorRef` est minimal :

```text
actorId
label?
entityId?
role?
```

Il ne résout aucune map, ne spawn aucun acteur et ne lit aucun runtime. C'est une information authoring/read contract pour les futurs builders.

## 11. Legacy bridge

`CinematicLegacyBridge` est optionnel :

```text
sourceKind
scenarioId?
cutsceneSchema?
notes?
```

Il documente une provenance possible, sans migration automatique et sans exécution runtime. Les diagnostics marquent ce cas avec :

```text
cinematicLegacyBridge
cinematicScenarioBridgeNotCanonical
```

## 12. ProjectManifest.cinematics

`ProjectManifest` ajoute :

```dart
List<CinematicAsset> cinematics
```

Règles :

- clé JSON absente -> `[]` ;
- clé JSON `null` -> `[]` ;
- roundtrip JSON ;
- `scenarios` et `scenes` préservés ;
- aucune migration depuis `scenarios`.

Comme `ProjectManifest` est Freezed/JsonSerializable, `build_runner` a été exécuté et a modifié :

```text
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
```

## 13. Opérations authoring

Fichier :

```text
packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
```

APIs ajoutées :

```text
addCinematicAsset
updateCinematicAsset
removeCinematicAsset
replaceCinematics
findCinematicById
```

Règles :

- ne mutent pas le `ProjectManifest` original ;
- refusent id/title vides via le modèle ;
- refusent duplicate id ;
- `removeCinematicAsset` refuse si une `SceneAsset` référence la cinematic via `SceneCinematicPayload.cinematicId` ;
- préservent `scenarios` et `scenes` ;
- ne touchent pas au runtime.

## 14. Diagnostics Cinematic

Fichier :

```text
packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
```

APIs :

```text
diagnoseCinematicAsset
diagnoseCinematics
diagnoseCinematicsAgainstProject
```

Codes V0 :

```text
cinematicMissingId
cinematicMissingTitle
cinematicDuplicateId
cinematicEmptyTimeline
cinematicDuplicateStepId
cinematicInvalidStepDuration
cinematicUnsupportedGameplayStep
cinematicTechnicalLabel
cinematicUnknownStorylineRef
cinematicUnknownChapterRef
cinematicUnknownMapRef
cinematicLegacyBridge
cinematicScenarioBridgeNotCanonical
```

Note : `id` et `title` sont aussi strictement refusés par le modèle. Les codes `missing` restent dans le vocabulaire diagnostic pour cohérence future avec des imports/bridges plus tolérants.

## 15. Linked Asset Public Contracts

`CinematicPublicContractSourceKind` distingue maintenant :

```text
cinematicAsset
scenarioBridge
```

Les contrats canoniques exposent :

```text
sourceKind = cinematicAsset
status = available
linear = true
declaredOutputs = completed
requiredActors
mapId
```

Les bridges Cutscene/Scenario restent :

```text
sourceKind = scenarioBridge
status = bridgeOnly
linear = null
declaredOutputs = completed
diagnostic legacyBridge
```

Aucun `ScenarioAsset` régulier n'est converti ou promu.

## 16. Relation avec SceneAsset / SceneRuntimePlan

`SceneCinematicPayload.cinematicId` peut maintenant résoudre :

- un `CinematicAsset` canonique ;
- ou un bridge public `ScenarioAsset` Cutscene Studio.

`diagnoseSceneAgainstProject` :

- ne signale plus `cinematicRefUnknown` si une cinematic canonique existe ;
- signale `legacyScenarioLeak` si la ref pointe vers un bridge scenario ;
- continue de signaler `cinematicRefUnknown` si aucune source publique n'existe.

`buildSceneRuntimePlan` n'est pas modifié. Le node cinematic produit toujours `SceneRuntimePlanIntent.playCinematic(cinematicId)` avec warning bridge V0 existant.

## 17. Relation avec ScenarioAsset / Cutscene Studio

Préservé :

- `ProjectManifest.scenarios` ;
- `ScenarioAsset` ;
- `CinematicPublicContract.scenarioBridge` ;
- Cutscene Studio en lecture/audit ;
- `ScenarioRuntimeExecutor` inchangé.

Interdit respecté :

- pas de migration automatique ;
- pas de renommage ;
- pas de suppression ;
- pas d'exécution runtime depuis `CinematicAsset.legacyBridge`.

## 18. Pourquoi aucun runtime n'a été modifié

V1-37 pose uniquement le modèle core. Le runtime cinematic dédié viendra plus tard. Le seam Scene reste `playCinematic(cinematicId)`, déjà existant.

## 19. Pourquoi aucun editor n'a été modifié

La prochaine étape produit est une Cinematics Library. V1-37 devait seulement rendre cette library possible sans inventer d'UI ou de workflow temporaire.

## 20. Pourquoi aucune donnée Selbrume n'a été créée

Tous les tests utilisent des IDs neutres :

```text
cinematic_intro
cinematic_test
scenario_cutscene
map_lab
actor_professor
```

Aucune scène, map, personnage ou fixture produit Selbrume n'est ajoutée.

## 21. Build runner

Commande exécutée car `ProjectManifest` est Freezed/JsonSerializable :

```bash
cd packages/map_core && dart run build_runner build --delete-conflicting-outputs
```

Sortie :

```text
Generating the build script.
Reading the asset graph.
Checking for updates.
Updating the asset graph.
Building, incremental build.
0s freezed on 341 inputs; lib/map_core.dart
W SDK language version 3.12.0 is newer than `analyzer` language version 3.9.0. Run `dart pub upgrade`.
0s freezed on 341 inputs: 1 no-op; lib/src/authoring/cinematic_authoring_operations.dart
2s freezed on 341 inputs: 3 no-op; spent 1s analyzing; lib/src/authoring/narrative_fact_authoring_operations.dart
4s freezed on 341 inputs: 20 skipped, 1 output, 4 same, 14 no-op; spent 2s analyzing, 2s building; lib/src/models/project_path_pattern_preset.dart
5s freezed on 341 inputs: 287 skipped, 1 output, 4 same, 49 no-op; spent 3s analyzing, 2s building
0s json_serializable on 682 inputs; lib/map_core.dart
1s json_serializable on 682 inputs: 1 no-op; lib/map_core.freezed.dart
W json_serializable on lib/src/models/element_collision_profile.dart:
  The version constraint "^4.8.1" on json_annotation allows versions before 4.9.0 which is not allowed.
2s json_serializable on 682 inputs: 54 skipped, 1 output, 4 same, 20 no-op; spent 2s analyzing; lib/src/models/project_path_pattern_preset.freezed.dart
4s json_serializable on 682 inputs: 229 skipped, 1 output, 4 same, 91 no-op; spent 3s analyzing; test/beta_playability_validator_test.freezed.dart
5s json_serializable on 682 inputs: 297 skipped, 1 output, 4 same, 159 no-op; spent 4s analyzing; test/project_manifest_surface_json_characterization_test.freezed.dart
6s json_serializable on 682 inputs: 367 skipped, 1 output, 4 same, 229 no-op; spent 5s analyzing; test/storyline_legacy_import_preview_test.freezed.dart
6s json_serializable on 682 inputs: 408 skipped, 1 output, 4 same, 269 no-op; spent 5s analyzing
0s source_gen:combining_builder on 682 inputs; lib/map_core.dart
0s source_gen:combining_builder on 682 inputs: 649 skipped, 1 output, 4 same, 28 no-op
Running the post build.
Writing the asset graph.
Built with build_runner in 12s; wrote 15 outputs.
```

## 22. Tests exécutés

Commande groupée de vérification ciblée :

```bash
cd packages/map_core && dart test test/cinematic_asset_test.dart && dart test test/project_manifest_cinematics_test.dart && dart test test/cinematic_authoring_operations_test.dart && dart test test/cinematic_diagnostics_test.dart && dart test test/linked_asset_public_contracts_test.dart && dart test test/scene_project_diagnostics_test.dart && dart test test/scene_runtime_plan_test.dart
```

Résultat :

```text
test/cinematic_asset_test.dart: All tests passed! (+4)
test/project_manifest_cinematics_test.dart: All tests passed! (+5)
test/cinematic_authoring_operations_test.dart: All tests passed! (+7)
test/cinematic_diagnostics_test.dart: All tests passed! (+6)
test/linked_asset_public_contracts_test.dart: All tests passed! (+9)
test/scene_project_diagnostics_test.dart: All tests passed! (+7)
test/scene_runtime_plan_test.dart: All tests passed! (+15)
```

## 23. Analyze

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie finale :

```text
Analyzing map_core...
No issues found!
```

Note : une première passe a signalé un import inutilisé dans `linked_asset_public_contracts.dart`; il a été supprimé avant la passe verte finale.

## 24. Recherches anti-scope

Commande :

```bash
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_battle packages/map_gameplay examples selbrume
```

Sortie :

```text
examples/playable_runtime_host/test/runtime_party_builder_test.dart
packages/map_runtime/lib/src/application/runtime_battle_move_bridge_diagnostics.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/runtime_battle_move_bridge_test.dart
```

Interprétation : sortie non vide à cause de changements concurrents hors scope apparus pendant le lot. V1-37 n'a pas modifié ces fichiers.

Commande :

```bash
rg -n "PlayableMapGame|ScenarioRuntimeExecutor|CutsceneRuntimeRunner|GameState|BranchByOutcome|accepted|refused|choice_|giveItem|teleport|completeStoryStep|WorldRuleEffect|RuntimeWorldRuleProjectionHook" packages/map_core/lib packages/map_core/test || true
```

Interprétation : la sortie contient des occurrences existantes de Scene/WorldRule/GameState et les chaînes interdites listées dans les diagnostics cinematic comme valeurs legacy à refuser. Aucun import runtime/editor n'a été introduit par `CinematicAsset`.

## 25. Recherche anti-Selbrume

Commande exécutée avant création du rapport :

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_core/lib packages/map_core/test reports/narrativeStudio/scenes/ns_scenes_v1_37_cinematic_asset_core_model_v0.md || true
```

Sortie utile :

```text
rg: reports/narrativeStudio/scenes/ns_scenes_v1_37_cinematic_asset_core_model_v0.md: No such file or directory (os error 2)
packages/map_core/test/narrative_predicate_authoring_draft_test.dart:230:      expect(serialized, isNot(contains('selbrume')));
packages/map_core/test/narrative_event_source_authoring_operations_test.dart:244:      expect(serialized, isNot(contains('selbrume')));
packages/map_core/test/environment_preset_json_codec_test.dart:23:  String id = 'selbrume_dense_forest',
packages/map_core/test/environment_layer_usage_diagnostics_test.dart:185:                _area(id: 'forest_north', presetId: 'selbrume_dense_forest'),
```

Interprétation : aucune donnée Selbrume n'a été créée par V1-37. Les occurrences listées sont préexistantes ou des assertions anti-hardcode.

## 26. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

## 27. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../test/runtime_party_builder_test.dart           |  18 ++++
 packages/map_core/lib/map_core.dart                |   3 +
 .../lib/src/diagnostics/scene_diagnostics.dart     |  27 ++++-
 .../map_core/lib/src/models/project_manifest.dart  |  43 ++++++++
 .../lib/src/models/project_manifest.freezed.dart   |  61 ++++++++++-
 .../lib/src/models/project_manifest.g.dart         |   4 +
 .../read_models/linked_asset_public_contracts.dart |  52 ++++++++++
 .../test/linked_asset_public_contracts_test.dart   |  65 ++++++++++++
 .../test/scene_project_diagnostics_test.dart       |  71 ++++++++++++-
 .../runtime_battle_move_bridge_diagnostics.dart    |  19 ++++
 .../presentation/flame/map_layers_component.dart   | 115 ++++++++++++++++++---
 .../src/presentation/flame/playable_map_game.dart  |  52 +++++++++-
 .../test/runtime_battle_move_bridge_test.dart      |  44 ++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  17 ++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 ++++-
 15 files changed, 580 insertions(+), 34 deletions(-)
```

Interprétation : cette sortie est globale au worktree et inclut des modifications concurrentes hors scope dans `examples/` et `packages/map_runtime/`. Les fichiers créés non trackés V1-37 apparaissent dans `git status final exact`.

## 28. git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie :

```text
examples/playable_runtime_host/test/runtime_party_builder_test.dart
packages/map_core/lib/map_core.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
packages/map_core/test/linked_asset_public_contracts_test.dart
packages/map_core/test/scene_project_diagnostics_test.dart
packages/map_runtime/lib/src/application/runtime_battle_move_bridge_diagnostics.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/runtime_battle_move_bridge_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Interprétation : `git diff --name-only` ne liste pas les fichiers non trackés créés par V1-37. Ils sont listés par le status final.

## 29. git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M examples/playable_runtime_host/test/runtime_party_builder_test.dart
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/lib/src/models/project_manifest.dart
 M packages/map_core/lib/src/models/project_manifest.freezed.dart
 M packages/map_core/lib/src/models/project_manifest.g.dart
 M packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
 M packages/map_core/test/linked_asset_public_contracts_test.dart
 M packages/map_core/test/scene_project_diagnostics_test.dart
 M packages/map_runtime/lib/src/application/runtime_battle_move_bridge_diagnostics.dart
 M packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/runtime_battle_move_bridge_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart
?? packages/map_core/lib/src/diagnostics/cinematic_diagnostics.dart
?? packages/map_core/lib/src/models/cinematic_asset.dart
?? packages/map_core/test/cinematic_asset_test.dart
?? packages/map_core/test/cinematic_authoring_operations_test.dart
?? packages/map_core/test/cinematic_diagnostics_test.dart
?? packages/map_core/test/project_manifest_cinematics_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_37_cinematic_asset_core_model_v0.md
```

## 30. Evidence Pack

Éléments prouvés :

- RED initial : `test/cinematic_asset_test.dart` échouait car `CinematicAsset`, `CinematicTimeline`, `CinematicTimelineStep`, `CinematicActorRef` et `CinematicLegacyBridge` n'existaient pas.
- GREEN : tests ciblés core verts.
- `dart analyze` map_core vert.
- build_runner exécuté uniquement parce que `ProjectManifest` est Freezed/JsonSerializable.
- aucun fichier `map_editor` modifié.
- aucun fichier `map_runtime` modifié par V1-37.
- aucun `ScenarioAsset` migré.
- aucun runtime cinematic ajouté.

Contenu des nouveaux fichiers : voir fichiers créés listés en section 7. Les tests et modèles sont inclus dans le diff V1-37.

## 31. Auto-review critique

- Est-ce que j'ai modifié map_editor ? Non.
- Est-ce que j'ai modifié map_runtime ? Non pour V1-37. Des fichiers runtime sont sales hors scope et documentés comme concurrents.
- Est-ce que j'ai modifié ScenarioRuntimeExecutor ? Non.
- Est-ce que j'ai modifié Cutscene Studio ? Non.
- Est-ce que j'ai créé une UI ? Non.
- Est-ce que j'ai créé un runtime cinematic ? Non.
- Est-ce que j'ai migré ScenarioAsset automatiquement ? Non.
- Est-ce que j'ai promu ScenarioAsset comme modèle final ? Non.
- Est-ce que CinematicAsset peut brancher ? Non.
- Est-ce que CinematicAsset peut écrire des Facts/WorldRules ? Non.
- Est-ce que CinematicAsset peut lancer un battle ? Non.
- Est-ce que ProjectManifest.scenarios est préservé ? Oui, testé.
- Est-ce que ProjectManifest.cinematics est rétrocompatible absent -> [] ? Oui, testé.
- Est-ce que CinematicPublicContract distingue canonical asset et scenarioBridge ? Oui, testé.
- Est-ce que SceneRuntimePlan reste non cassé ? Oui, `scene_runtime_plan_test.dart` vert.
- Est-ce que le prochain lot n'a pas été commencé ? Oui, V1-38 est seulement recommandé.

## 32. Limites restantes

- Pas de Cinematics Library UI.
- Pas de création UI de CinematicAsset.
- Pas de timeline editor.
- Pas de runtime cinematic playback.
- Pas de migration Cutscene Studio.
- Les diagnostics `cinematicMissingId` / `cinematicMissingTitle` existent mais le modèle strict refuse déjà ces cas à la construction.
- La recherche anti-scope globale est polluée par des changements runtime/example concurrents.

## 33. Prochain lot recommandé

```text
NS-SCENES-V1-38 — Cinematics Library V0
```

Raison : le modèle core existe. Il faut maintenant rendre les `CinematicAsset` visibles, navigables et diagnostiqués dans Narrative Studio avant de construire un Builder V2 ou un runtime adapter.
