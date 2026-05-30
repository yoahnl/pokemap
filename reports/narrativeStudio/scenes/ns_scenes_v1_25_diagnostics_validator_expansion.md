# NS-SCENES-V1-25 — Diagnostics / Validator Expansion

## 1. Résumé du lot

`NS-SCENES-V1-25` renforce les diagnostics Scene V1 avant le futur `SceneRuntimeExecutor`.

Le lot ajoute :

- diagnostics locaux de ports V0, edge kind, doublons de ports, reachability, fins non atteignables et cycles ;
- diagnostics authoring pour `ActionNode` et `BranchByOutcomeNode` encore unsupported ;
- diagnostics cross-project pour Dialogue, Battle trainer, Cinematic bridge, Facts et source future World Rule ;
- diagnostics Event -> Scene pour readiness `SceneRuntimePlan` et coexistence message/script legacy ;
- tests core ciblés et roadmap mise à jour.

Aucun runtime Scene, aucun `SceneRuntimeExecutor`, aucun branchement Event runtime, aucun `StorylineStep.sceneLinkIds`, aucune migration `ScenarioAsset` et aucune donnée Selbrume ne sont ajoutés.

## 2. Rappel du scope

Scope réalisé :

- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart`
- `packages/map_core/test/scene_diagnostics_test.dart`
- `packages/map_core/test/scene_project_diagnostics_test.dart`
- `packages/map_core/test/event_scene_link_diagnostics_test.dart`
- `packages/map_core/test/scene_runtime_plan_test.dart`
- roadmaps Scenes

Editor surfacing non modifié : les surfaces existantes pourront afficher les nouveaux diagnostics via les listes déjà branchées. Le lot reste core-only côté code.

## 3. Gate 0 complet

Commandes exécutées depuis la racine :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sorties exactes :

```text
/Users/karim/Project/pokemonProject
main
git status initial :
Sortie : <vide>
git diff --stat initial :
Sortie : <vide>
git diff --name-only initial :
Sortie : <vide>
061e9ebc feat(scenes): add scene runtime plan v0
540d5377 feat(scenes): add event page scene link V0
a2e14b19 docs(scenes): add V1-23 architecture decision and roadmap updates
9e85a187 feat(scenes): add payload pickers for linked assets,workdir:/Users/karim/Project/pokemonProject
e3325807 feat(scenes): add linked asset contracts and scene V0 node deletion
d170d0da docs(scenes): add linked-asset contracts audit and update roadmaps
48f3d520 docs(scenes): add checkpoint narrative studio direction and update roadmaps
c9a3d6e2 docs(scenes): add roadmap checkpoint correction and roadmap updates
23fc0436 chore(selbrume): update project scene condition metadata
4d25c19b Fix scene graph zoom scaling
```

## 4. Changements préexistants vs changements du lot

Changements préexistants :

```text
Sortie : <vide>
```

Changements introduits par `NS-SCENES-V1-25` :

```text
packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/test/event_scene_link_diagnostics_test.dart
packages/map_core/test/scene_diagnostics_test.dart
packages/map_core/test/scene_project_diagnostics_test.dart
packages/map_core/test/scene_runtime_plan_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/ns_scenes_v1_25_diagnostics_validator_expansion.md
```

## 5. Fichiers créés/modifiés

Fichiers créés :

```text
packages/map_core/test/scene_project_diagnostics_test.dart
reports/narrativeStudio/scenes/ns_scenes_v1_25_diagnostics_validator_expansion.md
```

Fichiers modifiés :

```text
packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/test/event_scene_link_diagnostics_test.dart
packages/map_core/test/scene_diagnostics_test.dart
packages/map_core/test/scene_runtime_plan_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 6. Fichiers lus

Instructions et prompt :

```text
AGENTS.md
agent_rules.md
skills/README.md
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/fef63ecf/skills/test-driven-development/SKILL.md
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/fef63ecf/skills/verification-before-completion/SKILL.md
/Users/karim/.codex/attachments/ed87a878-38ca-412b-b0b3-c68da15a9c21/pasted-text.txt
```

Rapports et roadmaps :

```text
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_24_scene_runtime_plan_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_23_bis_event_to_scene_link_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_22_payload_pickers_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_21_linked_asset_contracts_v0.md
```

Core :

```text
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart
packages/map_core/lib/src/runtime/scene_runtime_plan.dart
packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart
packages/map_core/lib/src/read_models/linked_asset_public_contracts.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/models/world_rule.dart
packages/map_core/lib/src/models/narrative_fact.dart
packages/map_core/lib/src/models/project_trainer.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/map_core.dart
packages/map_core/test/scene_diagnostics_test.dart
packages/map_core/test/event_scene_link_diagnostics_test.dart
packages/map_core/test/scene_runtime_plan_test.dart
```

## 7. Design diagnostics retenu

Découpage retenu :

- `diagnoseScene(scene)` : structure locale du graph SceneAsset.
- `diagnoseSceneAgainstProject(scene, project)` : refs projet et contrats publics.
- `diagnoseEventSceneLinks(project, maps)` : pages d'events qui ciblent des Scenes.
- `buildSceneRuntimePlan(scene)` : readiness runtime-plan pure, sans `ProjectManifest`.

Les diagnostics ne corrigent rien automatiquement. Ils signalent et laissent l'auteur décider.

## 8. Sévérités retenues

`error` :

- port source invalide sur les ports V0 stricts ;
- `SceneEdge.kind` incompatible avec le port V0 ;
- deuxième edge depuis le même port single-output ;
- ref Dialogue manquante ;
- ref trainer manquante pour battle trainer ;
- ref Fact manquante ;
- Event -> Scene cible absente/vide ;
- Event -> Scene cible incapable de produire un `SceneRuntimePlan`.

`warning` :

- port requis non connecté ;
- node non atteignable ;
- fin non atteignable si une autre fin reste atteignable ;
- cycle V0 non supporté ;
- `ActionNode` / `BranchByOutcomeNode` unsupported côté authoring ;
- Cinematic bridge absent ;
- source future worldState sans World Rule connue ;
- page Event avec `message`/`script` legacy + `sceneTarget`.

Cette séparation évite de bloquer tous les drafts tout en rendant visibles les erreurs runtime-bloquantes.

## 9. Diagnostics locaux SceneAsset ajoutés/renforcés

Codes ajoutés :

```text
edgeFromPortUnsupported
edgeKindUnsupportedForPort
duplicateOutgoingPortEdge
requiredOutputPortMissing
unreachableNode
unreachableEndNode
cycleUnsupported
actionNodeUnsupported
branchByOutcomeUnsupported
```

Ports V0 vérifiés strictement :

```text
start.completed -> defaultFlow
condition.true -> conditionTrue
condition.false -> conditionFalse
merge.completed -> defaultFlow
end -> aucun output
```

Les nodes `yarnDialogue`, `battle`, `cinematic`, `action` et `branchByOutcome` ne reçoivent pas de validation stricte de ports V1-25, car leurs ports authorables complets ne sont pas encore stabilisés. `ActionNode` et `BranchByOutcomeNode` restent toutefois visibles comme warnings authoring et erreurs runtime-plan.

Cas déjà protégés par le modèle strict :

```text
fromNodeId inconnu -> SceneGraph refuse la construction.
toNodeId inconnu -> SceneGraph refuse la construction.
payload.kind incohérent -> SceneNode refuse la construction.
payload explicite absent pour Yarn/Battle/Cinematic -> SceneNodePayload.emptyForKind refuse la construction.
dialogueId/cinematicId/battleKind vide -> payload refuse la construction.
```

## 10. Diagnostics cross-project ajoutés/renforcés

Codes ajoutés :

```text
dialogueRefUnknown
battleTrainerRefUnknown
cinematicRefUnknown
conditionWorldRuleRefUnknown
```

`diagnoseSceneAgainstProject(scene, project)` utilise maintenant `buildLinkedAssetContractsSnapshot(project)` pour les familles Dialogue/Battle/Cinematic quand cela existe déjà.

Règles :

- `SceneYarnDialoguePayload.dialogueId` absent des dialogues publics -> `error`.
- `SceneBattlePayload(battleKind: trainer).trainerId` absent des battles trainer publics -> `error`.
- `SceneCinematicPayload.cinematicId` absent des bridges cinematic publics -> `warning`.
- `SceneConditionSourceKind.fact` absent de `ProjectManifest.facts` -> `error` existant conservé.
- `SceneConditionSourceKind.worldState` absent de `ProjectManifest.worldRules` -> `warning`, car la source reste future.

## 11. Diagnostics Event -> Scene ajoutés/renforcés

Codes ajoutés :

```text
eventSceneTargetRuntimePlanNotBuildable
eventSceneTargetMixedLegacyContent
```

Règles :

- page sans `sceneTarget` -> OK ;
- `sceneTarget` vide -> `error` ;
- `sceneTarget` inconnu -> `error` ;
- page disabled avec `sceneTarget` -> `warning` existant conservé ;
- Scene cible avec diagnostics locaux errors -> `warning` existant conservé ;
- Scene cible non buildable en `SceneRuntimePlan` -> `error` ;
- message/script legacy + `sceneTarget` -> `warning`.

## 12. Impact sur buildSceneRuntimePlan

`buildSceneRuntimePlan(SceneAsset)` n'a pas changé de signature et reste :

- pur ;
- non project-aware ;
- sans lecture disque ;
- sans parsing Yarn ;
- sans import `map_battle` ;
- sans import `map_runtime` ;
- sans dépendance au layout.

Il bénéficie indirectement des nouveaux diagnostics locaux : toute erreur `diagnoseScene(scene)` bloque toujours la compilation avec `planBuildBlockedBySceneDiagnostics`.

## 13. Editor surfacing

Pas de modification editor.

Justification : le prompt autorisait un surfacing minimal seulement si nécessaire. Les diagnostics Scene sont déjà exposés par le workspace ; ajouter un panneau ou une refonte aurait dépassé le scope.

## 14. Ce qui reste non couvert

- Validation complète des outputs Yarn/outcomes réels : pas de contrat Yarn outcomes public en V1-25.
- Validation complète des ports Battle/Cinematic/Branch : reportée aux contrats/pickers/outcomes suivants.
- Validation globale World Rules + maps depuis Scene : les World Rules ont déjà `diagnoseWorldRules`; V1-25 ne les fusionne pas dans un validator global.
- `ActionPublicContract` / `ConsequencePublicContract` : toujours futur.
- Runtime executor : prochain lot.

## 15. Pourquoi aucun runtime n’a été codé

Le lot prépare le filet de sécurité avant l'exécution. Aucun package `map_runtime` n'est modifié et aucun `SceneRuntimeExecutor` n'est créé.

## 16. Pourquoi aucun ScenarioAsset n’a été promu

`ScenarioAsset` reste legacy/bridge. Les diagnostics ciblent `SceneAsset`, `ProjectManifest` et les contrats publics. Aucune conversion `SceneAsset -> ScenarioAsset` ou `ScenarioAsset -> SceneAsset` n'est ajoutée.

## 17. Pourquoi aucune donnée Selbrume n’a été créée

Les tests utilisent seulement des IDs neutres :

```text
scene_test
scene_intro
scene_action
map_test
event_gate
dialogue_test
trainer_test
cinematic_test
fact_test
world_rule_test
```

Aucun Maël, Lysa, Port des Brisants, rival ou seed Selbrume n'est ajouté.

## 18. Tests exécutés avec sorties exactes

### RED phase

Commande :

```bash
cd packages/map_core && dart test test/scene_diagnostics_test.dart
```

Sortie :

```text
Failed to load "test/scene_diagnostics_test.dart":
test/scene_diagnostics_test.dart:185:45: Error: Member not found: 'edgeFromPortUnsupported'.
test/scene_diagnostics_test.dart:223:45: Error: Member not found: 'edgeKindUnsupportedForPort'.
test/scene_diagnostics_test.dart:257:45: Error: Member not found: 'duplicateOutgoingPortEdge'.
test/scene_diagnostics_test.dart:295:45: Error: Member not found: 'requiredOutputPortMissing'.
test/scene_diagnostics_test.dart:331:41: Error: Member not found: 'unreachableNode'.
test/scene_diagnostics_test.dart:336:45: Error: Member not found: 'unreachableEndNode'.
test/scene_diagnostics_test.dart:388:45: Error: Member not found: 'cycleUnsupported'.
test/scene_diagnostics_test.dart:437:41: Error: Member not found: 'actionNodeUnsupported'.
test/scene_diagnostics_test.dart:444:41: Error: Member not found: 'branchByOutcomeUnsupported'.
Some tests failed.
```

Commande :

```bash
cd packages/map_core && dart test test/scene_project_diagnostics_test.dart
```

Sortie :

```text
Failed to load "test/scene_project_diagnostics_test.dart":
test/scene_project_diagnostics_test.dart:20:52: Error: Member not found: 'dialogueRefUnknown'.
test/scene_project_diagnostics_test.dart:37:53: Error: Member not found: 'dialogueRefUnknown'.
test/scene_project_diagnostics_test.dart:59:39: Error: Member not found: 'battleTrainerRefUnknown'.
test/scene_project_diagnostics_test.dart:77:53: Error: Member not found: 'battleTrainerRefUnknown'.
test/scene_project_diagnostics_test.dart:94:52: Error: Member not found: 'cinematicRefUnknown'.
test/scene_project_diagnostics_test.dart:112:53: Error: Member not found: 'cinematicRefUnknown'.
test/scene_project_diagnostics_test.dart:139:39: Error: Member not found: 'conditionWorldRuleRefUnknown'.
test/scene_project_diagnostics_test.dart:152:48: Error: Member not found: 'conditionWorldRuleRefUnknown'.
Some tests failed.
```

Commande :

```bash
cd packages/map_core && dart test test/event_scene_link_diagnostics_test.dart
```

Sortie :

```text
Failed to load "test/event_scene_link_diagnostics_test.dart":
test/event_scene_link_diagnostics_test.dart:126:18: Error: Member not found: 'eventSceneTargetRuntimePlanNotBuildable'.
test/event_scene_link_diagnostics_test.dart:151:42: Error: Member not found: 'eventSceneTargetMixedLegacyContent'.
Some tests failed.
```

### GREEN phase

Commande :

```bash
cd packages/map_core && dart test test/scene_diagnostics_test.dart
```

Sortie :

```text
00:00 +0: loading test/scene_diagnostics_test.dart
00:00 +0: Scene diagnostics V1-08 minimal draft has no blocking error
00:00 +1: Scene diagnostics scene without end node emits missingEndNode error
00:00 +2: Scene diagnostics end outcome absent from declared outcomes emits error
00:00 +3: Scene diagnostics declared outcome never emitted by an end node emits warning
00:00 +4: Scene diagnostics incomplete layout emits layoutMissingNode warning
00:00 +5: Scene diagnostics complete layout does not emit layoutMissingNode
00:00 +6: Scene diagnostics condition node without source emits blocking diagnostic
00:00 +7: Scene diagnostics configured V0 condition source has no condition error
00:00 +8: Scene diagnostics incompatible edge port emits blocking diagnostic
00:00 +9: Scene diagnostics edge kind mismatch emits blocking diagnostic
00:00 +10: Scene diagnostics duplicate edge from single output port emits blocking diagnostic
00:00 +11: Scene diagnostics missing required condition output emits warning
00:00 +12: Scene diagnostics unreachable node and unreachable end are diagnosed
00:00 +13: Scene diagnostics cycle reachable from start is diagnosed as unsupported warning
00:00 +14: Scene diagnostics action and branch nodes remain unsupported authoring warnings
00:00 +15: Scene diagnostics fact source references must resolve against ProjectManifest facts
00:00 +16: Scene diagnostics future and incomplete condition sources are diagnosed
00:00 +17: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_project_diagnostics_test.dart
```

Sortie :

```text
00:00 +0: loading test/scene_project_diagnostics_test.dart
00:00 +0: Scene project diagnostics detects missing dialogue reference without parsing Yarn
00:00 +1: Scene project diagnostics detects missing trainer reference for trainer battle
00:00 +2: Scene project diagnostics detects missing cinematic bridge reference as warning
00:00 +3: Scene project diagnostics detects missing world rule reference from future world state source
00:00 +4: Scene project diagnostics does not import runtime or battle packages
00:00 +5: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/event_scene_link_diagnostics_test.dart
```

Sortie :

```text
00:00 +0: loading test/event_scene_link_diagnostics_test.dart
00:00 +0: diagnoseEventSceneLinks does not report pages without scene target
00:00 +1: diagnoseEventSceneLinks accepts a scene target referencing an existing scene
00:00 +2: diagnoseEventSceneLinks reports missing and empty scene targets as errors
00:00 +3: diagnoseEventSceneLinks warns when a disabled page targets a scene
00:00 +4: diagnoseEventSceneLinks warns when the target scene has scene diagnostics errors
00:00 +5: diagnoseEventSceneLinks errors when the target scene cannot build a runtime plan
00:00 +6: diagnoseEventSceneLinks warns when legacy message or script coexist with scene target
00:00 +7: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_plan_test.dart
```

Sortie :

```text
00:00 +0: loading test/scene_runtime_plan_test.dart
00:00 +0: Scene runtime plan V0 builds a pure plan for a minimal valid start to end scene
00:00 +1: Scene runtime plan V0 ignores SceneGraphLayout when building the plan
00:00 +2: Scene runtime plan V0 preserves deterministic node and edge order from SceneGraph
00:00 +3: Scene runtime plan V0 scene diagnostics errors block plan building cleanly
00:00 +4: Scene runtime plan V0 condition nodes become evaluateCondition intents
00:00 +5: Scene runtime plan V0 merge nodes become merge intents
00:00 +6: Scene runtime plan V0 yarn dialogue payload becomes showDialogue intent without outcomes invented
00:00 +7: Scene runtime plan V0 battle payload becomes startBattle intent without importing battle runtime
00:00 +8: Scene runtime plan V0 cinematic payload becomes playCinematic intent with bridge warning
00:00 +9: Scene runtime plan V0 action nodes produce unsupported diagnostics and no plan
00:00 +10: Scene runtime plan V0 branchByOutcome nodes produce unsupported diagnostics and no plan
00:00 +11: Scene runtime plan V0 does not mutate the original SceneAsset
00:00 +12: All tests passed!
```

## 19. Analyze avec sortie exacte

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie :

```text
Analyzing map_core...
No issues found!
```

## 20. git diff --check

Sortie finale à jour :

```text
Sortie : <vide>
```

## 21. git diff --stat

Sortie finale exacte :

```text
 .../diagnostics/event_scene_link_diagnostics.dart  |  47 +++
 .../lib/src/diagnostics/scene_diagnostics.dart     | 433 ++++++++++++++++++++-
 .../test/event_scene_link_diagnostics_test.dart    |  89 +++++
 packages/map_core/test/scene_diagnostics_test.dart | 302 ++++++++++++++
 .../map_core/test/scene_runtime_plan_test.dart     |  12 +-
 .../scenes/road_map_scene_builder_authoring.md     |  18 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  19 +-
 7 files changed, 903 insertions(+), 17 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Ils sont visibles dans `git status final`.

## 22. git diff --name-only

Sortie finale exacte :

```text
packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/test/event_scene_link_diagnostics_test.dart
packages/map_core/test/scene_diagnostics_test.dart
packages/map_core/test/scene_runtime_plan_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Note : `git diff --name-only` ne liste pas les fichiers non suivis. Ils sont visibles dans `git status final`.

## 23. git status final exact

Sortie finale exacte :

```text
 M packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/test/event_scene_link_diagnostics_test.dart
 M packages/map_core/test/scene_diagnostics_test.dart
 M packages/map_core/test/scene_runtime_plan_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/test/scene_project_diagnostics_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_25_diagnostics_validator_expansion.md
```

## 24. Evidence Pack

### Nouveau fichier `packages/map_core/test/scene_project_diagnostics_test.dart`

```dart
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Scene project diagnostics', () {
    test('detects missing dialogue reference without parsing Yarn', () {
      final scene = _sceneWithMiddleNode(
        SceneNode(
          id: 'node_dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'dialogue_test'),
        ),
      );

      final missingReport = diagnoseSceneAgainstProject(scene, _project());

      final missingDiagnostic =
          missingReport.byCode(SceneDiagnosticCode.dialogueRefUnknown).single;
      expect(missingDiagnostic.severity, SceneDiagnosticSeverity.error);
      expect(missingDiagnostic.nodeId, 'node_dialogue');

      final validReport = diagnoseSceneAgainstProject(
        scene,
        _project(
          dialogues: const [
            ProjectDialogueEntry(
              id: 'dialogue_test',
              name: 'Dialogue Test',
              relativePath: 'dialogues/dialogue_test.yarn',
            ),
          ],
        ),
      );

      expect(
          validReport.byCode(SceneDiagnosticCode.dialogueRefUnknown), isEmpty);
    });

    test('detects missing trainer reference for trainer battle', () {
      final scene = _sceneWithMiddleNode(
        SceneNode(
          id: 'node_battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_test',
            declaredOutcomes: const ['victory', 'defeat'],
          ),
        ),
        outgoingPortId: 'victory',
        outgoingKind: SceneEdgeKind.battleVictory,
      );

      final missingReport = diagnoseSceneAgainstProject(scene, _project());

      final missingDiagnostic = missingReport
          .byCode(SceneDiagnosticCode.battleTrainerRefUnknown)
          .single;
      expect(missingDiagnostic.severity, SceneDiagnosticSeverity.error);
      expect(missingDiagnostic.nodeId, 'node_battle');

      final validReport = diagnoseSceneAgainstProject(
        scene,
        _project(
          trainers: const [
            ProjectTrainerEntry(
              id: 'trainer_test',
              name: 'Trainer Test',
              trainerClass: 'Tester',
            ),
          ],
        ),
      );

      expect(validReport.byCode(SceneDiagnosticCode.battleTrainerRefUnknown),
          isEmpty);
    });

    test('detects missing cinematic bridge reference as warning', () {
      final scene = _sceneWithMiddleNode(
        SceneNode(
          id: 'node_cinematic',
          kind: SceneNodeKind.cinematic,
          payload: SceneCinematicPayload(cinematicId: 'cinematic_test'),
        ),
        outgoingKind: SceneEdgeKind.cinematicCompleted,
      );

      final missingReport = diagnoseSceneAgainstProject(scene, _project());

      final missingDiagnostic =
          missingReport.byCode(SceneDiagnosticCode.cinematicRefUnknown).single;
      expect(missingDiagnostic.severity, SceneDiagnosticSeverity.warning);
      expect(missingDiagnostic.nodeId, 'node_cinematic');

      final validReport = diagnoseSceneAgainstProject(
        scene,
        _project(
          scenarios: const [
            ScenarioAsset(
              id: 'cinematic_test',
              name: 'Cinematic Test',
              entryNodeId: 'scenario_start',
              metadata: {'authoring.cutsceneSchema': 'v0'},
            ),
          ],
        ),
      );

      expect(
          validReport.byCode(SceneDiagnosticCode.cinematicRefUnknown), isEmpty);
    });

    test('detects missing world rule reference from future world state source',
        () {
      final scene = _sceneWithMiddleNode(
        SceneNode(
          id: 'node_condition',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(
            conditionSource: SceneConditionSource(
              sourceKind: SceneConditionSourceKind.worldState,
              sourceId: 'world_rule_test',
              operator: SceneConditionOperator.equals,
              value: 'active',
              label: 'World rule test',
            ),
          ),
        ),
        outgoingPortId: 'true',
        outgoingKind: SceneEdgeKind.conditionTrue,
      );

      final missingReport = diagnoseSceneAgainstProject(scene, _project());

      final missingDiagnostic = missingReport
          .byCode(SceneDiagnosticCode.conditionWorldRuleRefUnknown)
          .single;
      expect(missingDiagnostic.severity, SceneDiagnosticSeverity.warning);
      expect(missingDiagnostic.nodeId, 'node_condition');

      final validReport = diagnoseSceneAgainstProject(
        scene,
        _project(
          worldRules: [_worldRule()],
        ),
      );

      expect(
        validReport.byCode(SceneDiagnosticCode.conditionWorldRuleRefUnknown),
        isEmpty,
      );
    });

    test('does not import runtime or battle packages', () {
      final source =
          File('lib/src/diagnostics/scene_diagnostics.dart').readAsStringSync();

      expect(source, isNot(contains('map_runtime')));
      expect(source, isNot(contains('map_battle')));
    });
  });
}

SceneAsset _sceneWithMiddleNode(
  SceneNode middleNode, {
  String outgoingPortId = 'completed',
  SceneEdgeKind outgoingKind = SceneEdgeKind.defaultFlow,
}) {
  return SceneAsset(
    id: 'scene_test',
    name: 'Scene Test',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        middleNode,
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_middle',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: middleNode.id,
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_middle_end',
          fromNodeId: middleNode.id,
          fromPortId: outgoingPortId,
          toNodeId: 'node_end',
          kind: outgoingKind,
        ),
      ],
    ),
  );
}

ProjectManifest _project({
  List<ProjectDialogueEntry> dialogues = const [],
  List<ProjectTrainerEntry> trainers = const [],
  List<ScenarioAsset> scenarios = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'Project diagnostics test',
    maps: const [
      ProjectMapEntry(
        id: 'map_test',
        name: 'Map Test',
        relativePath: 'maps/map_test.json',
      ),
    ],
    tilesets: const [],
    dialogues: dialogues,
    trainers: trainers,
    scenarios: scenarios,
    worldRules: worldRules,
  );
}

WorldRuleDefinition _worldRule() {
  return WorldRuleDefinition(
    id: 'world_rule_test',
    label: 'World Rule Test',
    source: const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: 'fact_test',
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEvent,
      mapId: 'map_test',
      eventId: 'event_test',
    ),
    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventEnabled),
  );
}
```

### Hunks principaux modifiés

`scene_diagnostics.dart` :

```text
- nouveaux codes diagnostics ports/reachability/cross-project ;
- appel à buildLinkedAssetContractsSnapshot(project) ;
- validation V0 des ports start/condition/merge/end ;
- reachability BFS depuis start ;
- detection cycle DFS depuis start ;
- diagnostics refs dialogue/trainer/cinematic/fact/worldRule.
```

`event_scene_link_diagnostics.dart` :

```text
- import scene_runtime_plan_builder.dart ;
- nouveaux codes eventSceneTargetRuntimePlanNotBuildable et eventSceneTargetMixedLegacyContent ;
- appel buildSceneRuntimePlan(scene) pour readiness ;
- warning si message/script legacy coexistent avec sceneTarget.
```

`scene_runtime_plan_test.dart` :

```text
- test "scene diagnostics errors block plan building cleanly" assoupli pour accepter plusieurs diagnostics locaux, tout en exigeant conditionSourceMissing.
```

Roadmaps :

```text
- V1-25 marque DONE ;
- prochain lot recommande : NS-SCENES-V1-26 — Scene Runtime Executor MVP.
```

## 25. Auto-review critique

- Est-ce que j’ai modifié `map_runtime` ? Non.
- Est-ce que j’ai modifié `map_battle` ? Non.
- Est-ce que j’ai modifié `map_gameplay` ? Non.
- Est-ce que j’ai créé un `SceneRuntimeExecutor` ? Non.
- Est-ce que j’ai exécuté une Scene ? Non.
- Est-ce que j’ai branché Event -> Scene runtime ? Non.
- Est-ce que j’ai branché `StorylineStep.sceneLinkIds` ? Non.
- Est-ce que j’ai promu `ScenarioAsset` comme modèle final ? Non.
- Est-ce que j’ai inventé des outcomes Yarn ? Non.
- Est-ce que j’ai inventé des fake refs ? Non.
- Est-ce que j’ai créé des données Selbrume ? Non.
- Est-ce que les diagnostics distinguent error/warning/info ? Oui.
- Est-ce que les drafts restent authorables sans être sur-bloqués ? Oui : missing output, unreachable, cycles et unsupported authoring restent warnings.
- Est-ce que les erreurs runtime bloquantes sont visibles ? Oui : ports invalides, duplicates, refs absentes et plan non buildable.
- Est-ce que `buildSceneRuntimePlan` reste pur ? Oui.
- Est-ce que le prochain lot reste V1-26 et n’a pas été démarré ? Oui.

Regard critique : V1-25 pose un filet utile, mais ne doit pas être confondu avec un validator global complet. Les ports métier Dialogue/Battle/Cinematic/Branch restent volontairement partiels pour ne pas inventer de contrat d’outcome.

## 26. Limites et prochain lot recommandé

Limites :

- pas de validator global agrégé Scene + World Rules + maps ;
- pas de parsing Yarn ;
- pas d'outcomes Yarn publics ;
- pas de ports visuels/contrats complets pour Battle/Cinematic/Branch ;
- pas d'editor surfacing nouveau ;
- pas de runtime Scene.

Prochain lot recommandé :

```text
NS-SCENES-V1-26 — Scene Runtime Executor MVP
```
