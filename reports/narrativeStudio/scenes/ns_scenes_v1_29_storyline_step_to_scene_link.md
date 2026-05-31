# NS-SCENES-V1-29 — StorylineStep to Scene Link

## 1. Resume du lot

`NS-SCENES-V1-29 — StorylineStep to Scene Link` rend `StorylineStep.sceneLinkIds` utilisable comme lien authoring/progression vers des `SceneAsset` V1.

Le lot ajoute :

- des operations pures core pour lier, delier, remplacer et vider les liens Scene d'une Step ;
- des diagnostics StorylineStep -> Scene ;
- un read model pur pour afficher les scenes liees et les options de picker ;
- une section UI `Scenes liees` dans l'edition d'une Step du workspace Storylines ;
- des tests core/editor et un Visual Gate.

Le lot n'ajoute aucun declenchement runtime depuis une StorylineStep.

## 2. Pourquoi V1-29 existe

V1-28-octies a prouve une chaine runtime controlee :

```text
MapEventPage.sceneTarget
-> SceneEventRuntimeHook
-> SceneRuntimeExecutor
-> SceneDialogueRuntimeAwaitableAdapter
-> SceneBattleRuntimeOutcomeAdapter
-> SceneConsequenceRuntimeWriter
-> GameState updated
```

La Scene V1 est donc assez stable pour que les StorylineSteps puissent pointer vers les Scenes qui les expliquent, les realisent ou les illustrent.

Mais la responsabilite reste separee :

```text
Event -> Scene = declenchement runtime local.
StorylineStep -> Scene = lien authoring / lecture / progression / organisation.
```

## 3. Rappel du scope

Inclus :

- audit du champ `StorylineStep.sceneLinkIds` ;
- reuse du champ existant ;
- operations pures sur `ProjectManifest.storylines` ;
- diagnostics de references Scene ;
- read model StorylineStep -> Scene ;
- UI Storylines avec picker depuis `ProjectManifest.scenes` ;
- tests et visual gate.

Exclus :

- runtime Scene depuis StorylineStep ;
- mutation `GameState` ;
- completion runtime de Step ;
- remplacement Event -> Scene ;
- modification `map_runtime`, `map_gameplay`, `map_battle`, `examples` ou `selbrume` ;
- promotion `ScenarioAsset` ;
- BranchByOutcome, outcomes Yarn, parser Yarn, Dialogue Studio ;
- World Rule direct apply ;
- seed ou donnee produit Selbrume.

## 4. Gate 0 complet

Commande :

```bash
pwd
```

Sortie :

```text
/Users/karim/Project/pokemonProject
```

Commande :

```bash
git branch --show-current
```

Sortie :

```text
main
```

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```bash
git diff --stat
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```bash
git diff --name-only
```

Sortie :

```text
Sortie : <vide>
```

Commande :

```bash
git log --oneline -n 10
```

Sortie :

```text
acd71317 feat(scenes): add scene runtime golden slice smoke v0
44de8cc2 feat(scenes): add dialogue runtime awaitable adapter v0
20e51eca feat(scenes): add battle runtime outcome adapter v0
326e939c feat(scenes): add scene consequence runtime write v0
a6b46779 feat(scenes): add scene consequence model v0
d35b3987 feat(scenes): add map event sceneTarget runtime hook v0
54acda44 feat(scenes): add golden slice selbrume readiness
c480c4f5 test(scenes): refine world rule empty state handling
ac3b389c feat(scenes): add world rules map editor integration v0
757f0ad5 docs(scenes): add V1-26-bis evidence hardening report
```

## 5. Changements preexistants vs changements du lot

Gate 0 indiquait un worktree propre.

Changements introduits par V1-29 :

- fichiers core authoring/diagnostics/read model StorylineStep -> Scene ;
- exports publics `map_core.dart` ;
- tests core dedies ;
- UI Storylines pour lier une Step a des Scenes existantes ;
- test editor dedie avec visual gate ;
- roadmaps V1-29 ;
- rapport V1-29.

## 6. Fichiers lus

Prompt :

- `/Users/karim/.codex/attachments/613990c3-be70-4249-a113-f3a869604ee9/pasted-text.txt`

Instructions :

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `/Users/karim/.codex/skills/karpathy-guidelines/SKILL.md`
- `/Users/karim/.codex/plugins/cache/openai-curated/superpowers/fef63ecf/skills/test-driven-development/SKILL.md`
- `/Users/karim/.codex/plugins/cache/openai-curated/superpowers/fef63ecf/skills/verification-before-completion/SKILL.md`

Roadmaps et rapports :

- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_octies_golden_slice_runtime_smoke_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_septies_dialogue_runtime_awaitable_adapter_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_sexies_battle_runtime_outcome_adapter_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_quinquies_scene_consequence_runtime_write_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_quater_scene_consequence_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_ter_scene_consequence_contract_prep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_bis_event_to_scene_runtime_hook_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_28_golden_slice_selbrume_scene_event_prep.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_27_world_rules_map_editor_integration_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_26_scene_runtime_executor_mvp.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.md`

Core :

- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan.dart`
- `packages/map_core/lib/src/runtime/scene_runtime_plan_builder.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/*storyline*`
- `packages/map_core/test/*scene*`

Editor :

- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/test/**`

Runtime lu pour frontiere uniquement :

- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

## 7. Fichiers crees/modifies

Crees :

- `packages/map_core/lib/src/authoring/storyline_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/storyline_scene_link_diagnostics.dart`
- `packages/map_core/lib/src/read_models/storyline_scene_links_read_model.dart`
- `packages/map_core/test/storyline_scene_link_test.dart`
- `packages/map_core/test/storyline_authoring_operations_test.dart`
- `packages/map_core/test/storyline_scene_link_diagnostics_test.dart`
- `packages/map_core/test/storyline_scene_links_read_model_test.dart`
- `packages/map_editor/test/storylines_workspace_scene_links_test.dart`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_29_storyline_step_scene_link_v0.png`
- `reports/narrativeStudio/scenes/ns_scenes_v1_29_storyline_step_to_scene_link.md`

Modifies :

- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 8. Audit StorylineStep.sceneLinkIds existant

Constats :

- `StorylineStep.sceneLinkIds` existait deja dans `packages/map_core/lib/src/models/storyline_asset.dart`.
- Le constructeur definit `sceneLinkIds = const <String>[]`.
- `fromJson` lit `_readStringList(json, 'sceneLinkIds')`.
- `toJson` ecrit `sceneLinkIds`.
- La validation modele passe par `_immutableNonBlankUniqueStrings`, donc les listes invalides sont deja refusees au niveau constructeur.
- L'UI Storylines montrait un nombre de scenes liees mais ne proposait pas encore de picker actif pour modifier ces liens.
- Aucun diagnostic dedie StorylineStep -> Scene n'existait.
- Aucune operation authoring pure dediee n'existait.
- Aucun read model dedie n'existait.

Decision : le champ existant est reutilise tel quel. Aucun changement JSON ni migration n'est ajoute.

## 9. Design retenu

Design V1-29 :

- `StorylineStep.sceneLinkIds` reste la source de verite du lien.
- Les operations authoring prennent un `ProjectManifest`.
- Les operations modifient uniquement `ProjectManifest.storylines`.
- Les Scenes ne sont pas creees, modifiees ni supprimees.
- Les diagnostics verifient les refs Scene depuis `ProjectManifest.scenes`.
- Le read model rassemble les scenes liees, les scenes disponibles et les diagnostics.
- L'UI utilise un picker no-code depuis les scenes reelles du projet.
- Le message visible indique que le lien est authoring/progression only.

Raison : cela donne de la lisibilite narrative sans ajouter un second systeme de trigger.

## 10. Modele / JSON

Aucun modele n'a ete modifie dans ce lot.

Aucun JSON n'a ete modifie dans ce lot.

Preuve fonctionnelle :

- test JSON absent -> liste vide ;
- test JSON roundtrip -> ordre conserve.

## 11. Operations authoring

Fichier :

```text
packages/map_core/lib/src/authoring/storyline_authoring_operations.dart
```

API publique ajoutee :

```dart
final class StorylineStepSceneLinkResult {
  const StorylineStepSceneLinkResult({
    required this.updatedProject,
    required this.updatedStoryline,
    required this.updatedStep,
  });

  final ProjectManifest updatedProject;
  final StorylineAsset updatedStoryline;
  final StorylineStep updatedStep;
}

StorylineStepSceneLinkResult linkSceneToStorylineStep(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
  required String sceneId,
});

StorylineStepSceneLinkResult unlinkSceneFromStorylineStep(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
  required String sceneId,
});

StorylineStepSceneLinkResult replaceStorylineStepSceneLinks(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
  required List<String> sceneIds,
});

StorylineStepSceneLinkResult clearStorylineStepSceneLinks(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
});
```

Regles implementees :

- `storylineId`, `chapterId`, `stepId`, `sceneId` doivent etre non vides ;
- `linkSceneToStorylineStep` refuse les scenes inconnues ;
- `replaceStorylineStepSceneLinks` refuse les scenes inconnues ;
- `linkSceneToStorylineStep` refuse les doublons ;
- `replaceStorylineStepSceneLinks` dedoublonne en preservant l'ordre ;
- `unlinkSceneFromStorylineStep` retire seulement le lien cible ;
- l'objet original n'est pas mute ;
- le reste du `ProjectManifest` est preserve.

## 12. Diagnostics StorylineStep -> Scene

Fichier :

```text
packages/map_core/lib/src/diagnostics/storyline_scene_link_diagnostics.dart
```

API publique ajoutee :

```dart
enum StorylineSceneLinkDiagnosticSeverity {
  error,
  warning,
  info,
}

enum StorylineSceneLinkDiagnosticCode {
  storylineStepUnknownSceneLink,
  storylineStepDuplicateSceneLink,
  storylineStepLinkedSceneHasErrors,
  storylineStepLinkedSceneNotRuntimeBuildable,
}

final class StorylineSceneLinkDiagnostic { ... }

final class StorylineSceneLinkDiagnosticsReport { ... }

StorylineSceneLinkDiagnosticsReport diagnoseStorylineSceneLinks({
  required ProjectManifest project,
});
```

Regles :

- `storylineStepUnknownSceneLink` : error si une Step pointe vers une Scene absente ;
- `storylineStepDuplicateSceneLink` : warning defensif si un doublon est detecte ;
- `storylineStepLinkedSceneHasErrors` : warning si `diagnoseScene` expose une erreur ;
- `storylineStepLinkedSceneNotRuntimeBuildable` : warning si `buildSceneRuntimePlan` ne peut pas construire de plan.

Justification : une Scene liee a une Step peut etre draft ou non executable sans bloquer toute la Storyline. Le diagnostic informe l'auteur, mais ne transforme pas la Step en trigger.

## 13. Read model

Fichier :

```text
packages/map_core/lib/src/read_models/storyline_scene_links_read_model.dart
```

API publique ajoutee :

```dart
final class StorylineStepSceneLinksReadModel {
  StorylineStepSceneLinksReadModel({
    required this.storylineId,
    required this.chapterId,
    required this.stepId,
    required List<StorylineStepSceneLinkView> linkedScenes,
    required List<StorylineStepScenePickerOption> availableScenes,
    required List<StorylineSceneLinkDiagnostic> diagnostics,
  });

  static const authoringOnlyMessage =
      'Lien authoring/progression uniquement: le déclenchement runtime reste côté Event -> Scene.';
}

final class StorylineStepSceneLinkView { ... }

final class StorylineStepScenePickerOption { ... }

StorylineStepSceneLinksReadModel buildStorylineStepSceneLinksReadModel({
  required ProjectManifest project,
  required StorylineAsset storyline,
  required StorylineChapter chapter,
  required StorylineStep step,
});
```

Le read model est pur, deterministe, sans runtime, sans `GameState`, sans disque et sans mutation.

## 14. UI Storylines

Fichier :

```text
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
```

Changements :

- l'edition d'une Step transmet `initialSceneLinkIds` et `availableScenes` ;
- `_StructureItemDraft` porte `sceneLinkIds` ;
- `_CreateStructureItemDialog` maintient une liste locale de scene links ;
- `_StorylineStepSceneLinksSection` affiche la section `Scenes liees` ;
- `_StorylineLinkedSceneRow` affiche les scenes liees et le bouton `Retirer` ;
- le submit applique `replaceStorylineStepSceneLinks` avant de sauvegarder le titre/description ;
- les scenes deja liees sont desactivees dans le picker.

Keys testees :

```text
storylines-step-scene-links-section
storylines-step-scene-link-empty
storylines-step-scene-link-row-<sceneId>
storylines-step-link-scene-<sceneId>
storylines-step-unlink-scene-<sceneId>
```

Message visible :

```text
Lien authoring/progression uniquement: le déclenchement runtime reste côté Event -> Scene.
```

## 15. Cross-navigation

La cross-navigation avancee n'est pas ajoutee.

Raison : le lot devait rester centre sur le lien authoring/progression et le picker de scenes reelles. La navigation Scene <-> StorylineStep peut etre traitee dans un polish UX futur si le checkpoint beta le confirme.

## 16. Visual Gate

Chemin :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_29_storyline_step_scene_link_v0.png
```

Commande productrice :

```bash
cd packages/map_editor && flutter test --reporter=compact test/storylines_workspace_scene_links_test.dart
```

Preuve fichier :

```text
-rw-r--r--  1 karim  staff  41698 May 31 15:33 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_29_storyline_step_scene_link_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_29_storyline_step_scene_link_v0.png: PNG image data, 1400 x 900, 8-bit/color RGBA, non-interlaced
```

Note visuelle : le screenshot vient d'un widget test Flutter avec police de test. Les textes apparaissent sous forme de blocs, mais la capture montre la structure Storylines, la section de lien, une scene liee et l'absence de bouton runtime ambigu.

## 17. Pourquoi aucun runtime n'a ete branche

Aucun fichier `packages/map_runtime/**` n'a ete modifie.

`StorylineStep.sceneLinkIds` n'est lu par aucun hook runtime dans ce lot.

Les operations ajoutent uniquement des references authoring dans `ProjectManifest.storylines`.

Les diagnostics utilisent `buildSceneRuntimePlan` seulement comme validation pure de readiness, pas comme execution.

## 18. Pourquoi StorylineStep ne remplace pas Event -> Scene

Le trigger runtime reste :

```text
MapEventPage.sceneTarget -> Scene V1
```

Le nouveau lien est :

```text
StorylineStep.sceneLinkIds -> SceneAsset
```

Il ne modifie pas `MapEventPage.sceneTarget`.

Il ne lance pas `SceneRuntimeExecutor`.

Il ne complete pas une Step.

Il ne modifie pas `GameState`.

## 19. Pourquoi aucune donnee Selbrume n'a ete creee

Les tests utilisent des ids neutres :

- `story_main`
- `chapter_intro`
- `step_arrival`
- `scene_intro`
- `scene_branch`

Aucun code ou test du lot ne cree de `Mael`, `Lysa`, `Port des Brisants`, `rival_lysa`, scene produit Selbrume ou seed produit.

## 20. Tests executes avec sorties exactes

Commande :

```bash
cd packages/map_core && dart test test/storyline_scene_link_test.dart
```

Sortie :

```text
00:00 +0: loading test/storyline_scene_link_test.dart
00:00 +0: StorylineStep sceneLinkIds decodes missing sceneLinkIds as an empty list
00:00 +1: StorylineStep sceneLinkIds decodes missing sceneLinkIds as an empty list
00:00 +1: StorylineStep sceneLinkIds round-trips sceneLinkIds without changing order
00:00 +2: StorylineStep sceneLinkIds round-trips sceneLinkIds without changing order
00:00 +2: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/storyline_authoring_operations_test.dart
```

Sortie :

```text
00:00 +0: loading test/storyline_authoring_operations_test.dart
00:00 +0: Storyline scene link authoring operations linkSceneToStorylineStep adds an existing scene id
00:00 +1: Storyline scene link authoring operations linkSceneToStorylineStep adds an existing scene id
00:00 +1: Storyline scene link authoring operations linkSceneToStorylineStep refuses unknown step
00:00 +2: Storyline scene link authoring operations linkSceneToStorylineStep refuses unknown step
00:00 +2: Storyline scene link authoring operations linkSceneToStorylineStep refuses empty scene id
00:00 +3: Storyline scene link authoring operations linkSceneToStorylineStep refuses empty scene id
00:00 +3: Storyline scene link authoring operations linkSceneToStorylineStep refuses unknown scene id
00:00 +4: Storyline scene link authoring operations linkSceneToStorylineStep refuses unknown scene id
00:00 +4: Storyline scene link authoring operations linkSceneToStorylineStep refuses duplicate scene id
00:00 +5: Storyline scene link authoring operations linkSceneToStorylineStep refuses duplicate scene id
00:00 +5: Storyline scene link authoring operations unlinkSceneFromStorylineStep removes only selected scene id
00:00 +6: Storyline scene link authoring operations unlinkSceneFromStorylineStep removes only selected scene id
00:00 +6: Storyline scene link authoring operations replaceStorylineStepSceneLinks preserves order without duplicates
00:00 +7: Storyline scene link authoring operations replaceStorylineStepSceneLinks preserves order without duplicates
00:00 +7: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/storyline_scene_link_diagnostics_test.dart
```

Sortie :

```text
00:00 +0: loading test/storyline_scene_link_diagnostics_test.dart
00:00 +0: diagnoseStorylineSceneLinks does not report a step with no scene links
00:00 +1: diagnoseStorylineSceneLinks does not report a step with no scene links
00:00 +1: diagnoseStorylineSceneLinks accepts known scene links
00:00 +2: diagnoseStorylineSceneLinks accepts known scene links
00:00 +2: diagnoseStorylineSceneLinks reports unknown scene links as errors
00:00 +3: diagnoseStorylineSceneLinks reports unknown scene links as errors
00:00 +3: diagnoseStorylineSceneLinks warns when a linked scene has scene diagnostics errors
00:00 +4: diagnoseStorylineSceneLinks warns when a linked scene has scene diagnostics errors
00:00 +4: diagnoseStorylineSceneLinks warns when a linked scene cannot build a runtime plan
00:00 +5: diagnoseStorylineSceneLinks warns when a linked scene cannot build a runtime plan
00:00 +5: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/storyline_scene_links_read_model_test.dart
```

Sortie :

```text
00:00 +0: loading test/storyline_scene_links_read_model_test.dart
00:00 +0: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options
00:00 +1: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options
00:00 +1: buildStorylineStepSceneLinksReadModel reports missing linked scenes without requiring runtime state
00:00 +2: buildStorylineStepSceneLinksReadModel reports missing linked scenes without requiring runtime state
00:00 +2: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/scene_runtime_plan_test.dart
```

Sortie :

```text
00:00 +0: loading test/scene_runtime_plan_test.dart
00:00 +15: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/storylines_workspace_scene_links_test.dart
```

Sortie :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/storylines_workspace_scene_links_test.dart
00:03 +0: StorylineStep scene links authoring shows linked scenes section and links a real project scene
00:03 +1: StorylineStep scene links authoring shows linked scenes section and links a real project scene
00:03 +1: StorylineStep scene links authoring prevents duplicates and removes a linked scene
00:03 +2: StorylineStep scene links authoring prevents duplicates and removes a linked scene
00:03 +2: StorylineStep scene links authoring shows an unknown linked scene diagnostic
00:03 +3: StorylineStep scene links authoring shows an unknown linked scene diagnostic
00:03 +3: StorylineStep scene links authoring writes the V1-29 visual gate screenshot
00:03 +4: StorylineStep scene links authoring writes the V1-29 visual gate screenshot
00:03 +4: All tests passed!
```

Verification supplementaire hors acceptance stricte :

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/storylines_workspace_shell_test.dart
```

Sortie :

```text
00:08 +35 -1: Some tests failed.
```

Detail utile : l'echec vient d'une golden preexistante absente `../../../reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_empty_polished.png`. Le test supplementaire n'est pas modifie par V1-29 et n'etait pas dans la liste obligatoire du lot.

## 21. Analyze avec sortie exacte

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
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart test/storylines_workspace_scene_links_test.dart
```

Sortie :

```text
Analyzing 2 items...
No issues found! (ran in 1.5s)
```

## 22. Recherche anti-Selbrume

Commande :

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_core/lib/src packages/map_core/test packages/map_editor/lib packages/map_editor/test reports/narrativeStudio/scenes/ns_scenes_v1_29_storyline_step_to_scene_link.md || true
```

Sortie de la commande obligatoire :

```text
reports/narrativeStudio/scenes/ns_scenes_v1_29_storyline_step_to_scene_link.md:58:- modification `map_runtime`, `map_gameplay`, `map_battle`, `examples` ou `selbrume` ;
reports/narrativeStudio/scenes/ns_scenes_v1_29_storyline_step_to_scene_link.md:141:54acda44 feat(scenes): add golden slice selbrume readiness
reports/narrativeStudio/scenes/ns_scenes_v1_29_storyline_step_to_scene_link.md:187:- `reports/narrativeStudio/scenes/ns_scenes_v1_28_golden_slice_selbrume_scene_event_prep.md`
reports/narrativeStudio/scenes/ns_scenes_v1_29_storyline_step_to_scene_link.md:534:Aucun code ou test du lot ne cree de `Mael`, `Lysa`, `Port des Brisants`, `rival_lysa`, scene produit Selbrume ou seed produit.
reports/narrativeStudio/scenes/ns_scenes_v1_29_storyline_step_to_scene_link.md:705:rg -n "selbrume|mael|maël|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_core/lib/src packages/map_core/test packages/map_editor/lib packages/map_editor/test reports/narrativeStudio/scenes/ns_scenes_v1_29_storyline_step_to_scene_link.md || true
packages/map_editor/test/storylines_current_global_story_characterization_test.dart:107:  'La brume du phare',
packages/map_editor/test/storylines_current_global_story_characterization_test.dart:110:  'La cabane du phare',
packages/map_editor/test/element_collision_editor_sheet_fine_mask_test.dart:91:                              elementName: 'selbrume nested',
packages/map_editor/test/element_collision_editor_sheet_fine_mask_test.dart:164:          elementName: 'selbrume maison fine',
packages/map_editor/test/element_collision_editor_sheet_fine_mask_test.dart:622:                    elementName: 'selbrume maison fine',
packages/map_editor/test/storylines_seed_graph_usability_test.dart:20:      final main = _selbrumeMain(project);
packages/map_editor/test/storylines_seed_graph_usability_test.dart:21:      final relationships = _selbrumeAttachmentRelationships(project);
packages/map_editor/test/storylines_seed_graph_usability_test.dart:181:      final seedFile = _selbrumeProjectFile();
packages/map_editor/test/storylines_seed_graph_usability_test.dart:192:      expect(_selbrumeMain(project).sceneLinks, isEmpty);
packages/map_editor/test/storylines_seed_graph_usability_test.dart:193:      expect(_selbrumeAttachmentRelationships(project), hasLength(3));
packages/map_editor/test/storylines_seed_graph_usability_test.dart:219:      final seedFile = _selbrumeProjectFile();
packages/map_editor/test/storylines_seed_graph_usability_test.dart:245:      expect(_selbrumeAttachmentRelationships(project), hasLength(3));
packages/map_editor/test/storylines_seed_graph_usability_test.dart:246:      expect(_selbrumeMain(project).sceneLinks, isEmpty);
packages/map_editor/test/storylines_seed_graph_usability_test.dart:300:  final main = _selbrumeMain(project);
packages/map_editor/test/storylines_seed_graph_usability_test.dart:371:  final file = _selbrumeProjectFile();
packages/map_editor/test/storylines_seed_graph_usability_test.dart:376:File _selbrumeProjectFile() {
packages/map_editor/test/storylines_seed_graph_usability_test.dart:377:  final file = File('../../selbrume/project.json');
packages/map_editor/test/storylines_seed_graph_usability_test.dart:384:StorylineAsset _selbrumeMain(ProjectManifest project) {
packages/map_editor/test/storylines_seed_graph_usability_test.dart:386:    (storyline) => storyline.id == 'story_main_brume_phare',
packages/map_editor/test/storylines_seed_graph_usability_test.dart:390:List<StorylineRelationship> _selbrumeAttachmentRelationships(
packages/map_editor/test/storylines_seed_graph_usability_test.dart:398:            relationship.targetStorylineId == 'story_main_brume_phare')
packages/map_editor/test/features/narrative/application/overview/narrative_overview_read_model_test.dart:282:      expect(model.mainStory.title, isNot('La brume du phare'));
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:132:      expect(find.textContaining('La brume du phare'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:376:      expect(find.textContaining('La brume du phare'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:618:      expect(find.textContaining('La brume du phare'), findsNothing);
packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart:790:      expect(find.textContaining('La brume du phare'), findsNothing);
packages/map_editor/test/storylines_structure_layout_test.dart:81:            const ValueKey('storylines-delete-step-action-step_intro_selbrume'),
packages/map_editor/test/storylines_structure_layout_test.dart:86:          find.byKey(const ValueKey('storylines-step-row-step_intro_selbrume')),
packages/map_editor/test/storylines_structure_layout_test.dart:96:      final seedFile = _selbrumeProjectFile();
packages/map_editor/test/storylines_structure_layout_test.dart:119:          find.byKey(const ValueKey('storylines-step-row-step_intro_selbrume')),
packages/map_editor/test/storylines_structure_layout_test.dart:157:      final seedFile = _selbrumeProjectFile();
packages/map_editor/test/storylines_structure_layout_test.dart:185:      var main = _selbrumeMain(updatedProject);
packages/map_editor/test/storylines_structure_layout_test.dart:213:      main = _selbrumeMain(updatedProject);
packages/map_editor/test/storylines_structure_layout_test.dart:223:      final seedFile = _selbrumeProjectFile();
packages/map_editor/test/storylines_structure_layout_test.dart:232:          const ValueKey('storylines-edit-step-action-step_intro_selbrume'),
packages/map_editor/test/storylines_structure_layout_test.dart:246:      var main = _selbrumeMain(updatedProject);
packages/map_editor/test/storylines_structure_layout_test.dart:263:      main = _selbrumeMain(updatedProject);
packages/map_editor/test/storylines_structure_layout_test.dart:266:      expect(main.chapters.first.steps[1].id, 'step_intro_selbrume');
packages/map_editor/test/storylines_structure_layout_test.dart:285:      main = _selbrumeMain(updatedProject);
packages/map_editor/test/storylines_structure_layout_test.dart:296:      final seedFile = _selbrumeProjectFile();
packages/map_editor/test/storylines_structure_layout_test.dart:319:      final main = _selbrumeMain(updatedProject);
packages/map_editor/test/storylines_structure_layout_test.dart:489:  final file = _selbrumeProjectFile();
packages/map_editor/test/storylines_structure_layout_test.dart:494:File _selbrumeProjectFile() {
packages/map_editor/test/storylines_structure_layout_test.dart:495:  final file = File('../../selbrume/project.json');
packages/map_editor/test/storylines_structure_layout_test.dart:502:StorylineAsset _selbrumeMain(ProjectManifest project) {
packages/map_editor/test/storylines_structure_layout_test.dart:504:    (storyline) => storyline.id == 'story_main_brume_phare',
packages/map_editor/test/scenes_workspace_shell_test.dart:360:      expect(find.text('selbrume_port'), findsNothing);
packages/map_editor/test/scenes_workspace_shell_test.dart:408:      expect(find.text('trainer_lysa'), findsNothing);
packages/map_editor/test/scenes_workspace_shell_test.dart:436:      expect(find.text('mael_intro'), findsNothing);
packages/map_editor/test/scenes_workspace_shell_test.dart:437:      expect(find.text('lysa_rival'), findsNothing);
packages/map_core/test/narrative_predicate_authoring_draft_test.dart:230:      expect(serialized, isNot(contains('selbrume')));
packages/map_core/test/narrative_predicate_authoring_draft_test.dart:231:      expect(serialized, isNot(contains('lysa')));
packages/map_core/test/narrative_predicate_authoring_draft_test.dart:232:      expect(serialized, isNot(contains('mael')));
packages/map_core/test/narrative_predicate_authoring_draft_test.dart:233:      expect(serialized, isNot(contains('maël')));
packages/map_core/test/environment_preset_json_codec_test.dart:23:  String id = 'selbrume_dense_forest',
packages/map_core/test/environment_preset_json_codec_test.dart:48:    'id': 'selbrume_dense_forest',
packages/map_core/test/environment_preset_json_codec_test.dart:75:      expect(p.id, 'selbrume_dense_forest');
packages/map_core/test/environment_preset_json_codec_test.dart:92:      expect(m['id'], 'selbrume_dense_forest');
packages/map_core/test/narrative_authoring_golden_path_test.dart:359:      expect(serializedEvidence, isNot(contains('selbrume')));
packages/map_core/test/narrative_authoring_golden_path_test.dart:360:      expect(serializedEvidence, isNot(contains('lysa')));
packages/map_core/test/narrative_authoring_golden_path_test.dart:361:      expect(serializedEvidence, isNot(contains('mael')));
packages/map_core/test/narrative_authoring_golden_path_test.dart:362:      expect(serializedEvidence, isNot(contains('maël')));
packages/map_core/test/narrative_outcome_authoring_operations_test.dart:263:      expect(serialized, isNot(contains('selbrume')));
packages/map_core/test/narrative_outcome_authoring_operations_test.dart:264:      expect(serialized, isNot(contains('lysa')));
packages/map_core/test/narrative_outcome_authoring_operations_test.dart:265:      expect(serialized, isNot(contains('mael')));
packages/map_core/test/narrative_outcome_authoring_operations_test.dart:266:      expect(serialized, isNot(contains('maël')));
packages/map_editor/test/element_collision_editor_sheet_overflow_test.dart:28:                      elementName: 'selbrume maison 1',
packages/map_core/test/narrative_scenario_authoring_draft_test.dart:257:      expect(serialized, isNot(contains('selbrume')));
packages/map_core/test/narrative_scenario_authoring_draft_test.dart:258:      expect(serialized, isNot(contains('lysa')));
packages/map_core/test/narrative_scenario_authoring_draft_test.dart:259:      expect(serialized, isNot(contains('mael')));
packages/map_core/test/narrative_scenario_authoring_draft_test.dart:260:      expect(serialized, isNot(contains('maël')));
packages/map_core/test/narrative_event_source_authoring_operations_test.dart:244:      expect(serialized, isNot(contains('selbrume')));
packages/map_core/test/narrative_event_source_authoring_operations_test.dart:245:      expect(serialized, isNot(contains('lysa')));
packages/map_core/test/narrative_event_source_authoring_operations_test.dart:246:      expect(serialized, isNot(contains('mael')));
packages/map_core/test/narrative_event_source_authoring_operations_test.dart:247:      expect(serialized, isNot(contains('maël')));
packages/map_core/test/beta_playability_validator_test.dart:255:      expect(text, isNot(contains('selbrume')));
packages/map_core/test/environment_layer_usage_diagnostics_test.dart:185:                _area(id: 'forest_north', presetId: 'selbrume_dense_forest'),
packages/map_core/test/environment_layer_usage_diagnostics_test.dart:197:      expect(d.presetId, 'selbrume_dense_forest');
packages/map_core/test/environment_layer_usage_diagnostics_test.dart:200:        'Environment area "forest_north" on layer "env_layer" references missing preset "selbrume_dense_forest".',
packages/map_editor/test/storylines_workspace_shell_test.dart:1297:  'La brume du phare',
packages/map_editor/test/storylines_workspace_shell_test.dart:1300:  'Le phare',
packages/map_editor/test/storylines_workspace_shell_test.dart:1303:  'La cabane du phare',
packages/map_core/test/narrative_validator_authoring_adapter_test.dart:208:      expect(serialized, isNot(contains('selbrume')));
packages/map_core/test/narrative_validator_authoring_adapter_test.dart:209:      expect(serialized, isNot(contains('lysa')));
packages/map_core/test/narrative_validator_authoring_adapter_test.dart:210:      expect(serialized, isNot(contains('mael')));
packages/map_core/test/narrative_validator_authoring_adapter_test.dart:211:      expect(serialized, isNot(contains('maël')));
```

Commande de controle cible sur les fichiers V1-29 :

```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|rival_lysa|brumes|phare" packages/map_core/lib/src/authoring/storyline_authoring_operations.dart packages/map_core/lib/src/diagnostics/storyline_scene_link_diagnostics.dart packages/map_core/lib/src/read_models/storyline_scene_links_read_model.dart packages/map_core/test/storyline_scene_link_test.dart packages/map_core/test/storyline_authoring_operations_test.dart packages/map_core/test/storyline_scene_link_diagnostics_test.dart packages/map_core/test/storyline_scene_links_read_model_test.dart packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_scene_links_test.dart || true
```

Sortie :

```text
Sortie : <vide>
```

Interpretation : le rapport et des tests historiques mentionnent Selbrume conceptuellement ou comme fixtures existantes. Les fichiers code/test ajoutes ou modifies pour V1-29 ne creent aucune donnee produit Selbrume.

## 23. Recherche anti-runtime / anti-scope

Commande :

```bash
rg -n "SceneEventRuntimeHook|SceneRuntimeExecutor|PlayableMapGame|GameState|completeStoryStep|projectWorldRuleEffects|WorldRuleEffect|BranchByOutcome|ScenarioAsset|ScenarioRuntimeExecutor" packages/map_core/lib/src packages/map_core/test packages/map_editor/lib packages/map_editor/test || true
```

Sortie de controle cible sur les fichiers V1-29 :

Commande :

```bash
rg -n "SceneEventRuntimeHook|SceneRuntimeExecutor|PlayableMapGame|GameState|completeStoryStep|projectWorldRuleEffects|WorldRuleEffect|BranchByOutcome|ScenarioAsset|ScenarioRuntimeExecutor" packages/map_core/lib/src/authoring/storyline_authoring_operations.dart packages/map_core/lib/src/diagnostics/storyline_scene_link_diagnostics.dart packages/map_core/lib/src/read_models/storyline_scene_links_read_model.dart packages/map_core/test/storyline_scene_link_test.dart packages/map_core/test/storyline_authoring_operations_test.dart packages/map_core/test/storyline_scene_link_diagnostics_test.dart packages/map_core/test/storyline_scene_links_read_model_test.dart packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_scene_links_test.dart || true
```

Sortie :

```text
Sortie : <vide>
```

Interpretation : la commande large obligatoire a ete executee et liste des references historiques dans le repo, notamment `ScenarioAsset`, `GameState`, World Rules et generated files. Le controle cible ci-dessus confirme que les fichiers V1-29 n'appellent aucun hook runtime, ne mutent aucun `GameState`, ne promeuvent aucun `ScenarioAsset` et n'activent aucun `BranchByOutcome`.

## 24. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
Sortie : <vide>
```

## 25. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart                |   3 +
 .../lib/src/ui/canvas/storylines_workspace.dart    | 296 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  21 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  22 +-
 4 files changed, 326 insertions(+), 16 deletions(-)
```

## 26. git diff --name-only

Commande :

```bash
git diff --name-only
```

Sortie :

```text
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## 27. git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/authoring/storyline_authoring_operations.dart
?? packages/map_core/lib/src/diagnostics/storyline_scene_link_diagnostics.dart
?? packages/map_core/lib/src/read_models/storyline_scene_links_read_model.dart
?? packages/map_core/test/storyline_authoring_operations_test.dart
?? packages/map_core/test/storyline_scene_link_diagnostics_test.dart
?? packages/map_core/test/storyline_scene_link_test.dart
?? packages/map_core/test/storyline_scene_links_read_model_test.dart
?? packages/map_editor/test/storylines_workspace_scene_links_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_29_storyline_step_to_scene_link.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_29_storyline_step_scene_link_v0.png
```

## 28. Evidence Pack

### Fichiers crees, APIs et tests ajoutes

`packages/map_core/lib/src/authoring/storyline_authoring_operations.dart`

- `StorylineStepSceneLinkResult`
- `linkSceneToStorylineStep`
- `unlinkSceneFromStorylineStep`
- `replaceStorylineStepSceneLinks`
- `clearStorylineStepSceneLinks`
- helpers internes de copie immutable Storyline/Chapter/Step

`packages/map_core/lib/src/diagnostics/storyline_scene_link_diagnostics.dart`

- `StorylineSceneLinkDiagnosticSeverity`
- `StorylineSceneLinkDiagnosticCode`
- `StorylineSceneLinkDiagnostic`
- `StorylineSceneLinkDiagnosticsReport`
- `diagnoseStorylineSceneLinks`

`packages/map_core/lib/src/read_models/storyline_scene_links_read_model.dart`

- `StorylineStepSceneLinksReadModel`
- `StorylineStepSceneLinkView`
- `StorylineStepScenePickerOption`
- `buildStorylineStepSceneLinksReadModel`

`packages/map_core/test/storyline_scene_link_test.dart`

- JSON absent -> liste vide ;
- roundtrip -> ordre conserve.

`packages/map_core/test/storyline_authoring_operations_test.dart`

- link scene existante ;
- step inconnue refusee ;
- scene id vide refuse ;
- scene inconnue refusee ;
- doublon refuse ;
- unlink cible ;
- replace preserve l'ordre et dedoublonne.

`packages/map_core/test/storyline_scene_link_diagnostics_test.dart`

- aucune scene liee -> aucun diagnostic ;
- liens connus acceptes ;
- scene inconnue -> error ;
- scene liee avec erreurs Scene -> warning ;
- scene non buildable runtime-plan -> warning.

`packages/map_core/test/storyline_scene_links_read_model_test.dart`

- scenes liees avec labels et options picker ;
- scene manquante signalee sans runtime state.

`packages/map_editor/test/storylines_workspace_scene_links_test.dart`

- section visible et lien d'une vraie scene ;
- doublon prevenu et retrait fonctionne ;
- scene inconnue affiche un diagnostic ;
- screenshot V1-29 ecrit.

### Fichiers modifies, sections completes

`packages/map_core/lib/map_core.dart`

```diff
+export 'src/diagnostics/storyline_scene_link_diagnostics.dart';
+export 'src/authoring/storyline_authoring_operations.dart';
+export 'src/read_models/storyline_scene_links_read_model.dart';
```

`packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`

Sections modifiees :

- `_openEditStepDialog` transmet scenes disponibles et applique `replaceStorylineStepSceneLinks` ;
- `_copyStepWith` accepte `sceneLinkIds` ;
- `_StructureItemDraft` porte `sceneLinkIds` ;
- `_CreateStructureItemDialog` gere la liste locale des scenes liees ;
- `_StorylineStepSceneLinksSection` ajoute la section UI ;
- `_StorylineLinkedSceneRow` ajoute la ligne de scene liee ;
- `_stringListEquals` ajoute la comparaison stable.

`reports/narrativeStudio/scenes/road_map_scenes.md`

- V1-29 passe de TODO a DONE ;
- prochain lot recommande passe a V1-30 ;
- section `Mise a jour V1-29` ajoutee.

`reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

- prochain lot recommande passe a V1-30 ;
- ligne V1-29 marquee DONE ;
- section `Mise a jour V1-29` ajoutee ;
- liste post-slice ajustee pour retirer StorylineStep -> Scene Link complet.

### Diff reel des fichiers modifies

Le diff exact final est capture par les commandes `git diff --stat`, `git diff --name-only` et `git diff --check` ci-dessous. Les hunks publics et widgets ajoutes sont decrits dans les sections precedentes.

### Screenshot

Fichier binaire PNG :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_29_storyline_step_scene_link_v0.png
```

Preuve :

```text
PNG image data, 1400 x 900, 8-bit/color RGBA, non-interlaced
```

## 29. Auto-review critique

- Est-ce que j'ai modifie `map_runtime` ? Non.
- Est-ce que j'ai modifie `PlayableMapGame` ? Non.
- Est-ce que j'ai branche `StorylineStep.sceneLinkIds` au runtime ? Non.
- Est-ce que StorylineStep declenche une Scene ? Non.
- Est-ce que j'ai remplace Event -> Scene ? Non.
- Est-ce que j'ai modifie `MapEventPage.sceneTarget` ? Non.
- Est-ce que j'ai mute `GameState` ? Non.
- Est-ce que j'ai complete une StorylineStep ? Non.
- Est-ce que j'ai applique une World Rule directement ? Non.
- Est-ce que j'ai promu `ScenarioAsset` ? Non.
- Est-ce que j'ai invente des outcomes Yarn ? Non.
- Est-ce que j'ai active BranchByOutcome ? Non.
- Est-ce que j'ai cree des donnees Selbrume ? Non.
- Est-ce que l'utilisateur peut lier une vraie Scene a une Step ? Oui.
- Est-ce que les refs cassees sont diagnostiquees ? Oui.
- Est-ce que le message authoring/progression only est visible ? Oui.
- Est-ce que le prochain lot n'a pas ete demarre ? Oui.

Risque residuel : le lien UI est dans le dialog d'edition de Step, pas encore en cross-navigation directe depuis une Scene.

## 30. Limites restantes

- Pas de bouton `Voir la Scene` depuis la Step.
- Pas d'affichage inverse dans le workspace Scenes des StorylineSteps qui referencent la Scene.
- Pas de completion runtime de Step.
- Pas de declenchement runtime depuis StorylineStep.
- Pas de relation avec ActionNode `completeStoryStep`.
- Pas de contenu produit Selbrume.

## 31. Prochain lot recommande

`NS-SCENES-V1-30 — Scene V1 Beta Readiness Checkpoint`

Raison : les principales briques Scene V1 sont maintenant en place. Il faut verifier la coherence produit/technique avant d'ouvrir les prochains gros chantiers : Dialogue outcomes, BranchByOutcome, Cinematic V1, contenu produit Selbrume ou hardening beta.
