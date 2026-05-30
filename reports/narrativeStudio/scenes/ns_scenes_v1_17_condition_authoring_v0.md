# NS-SCENES-V1-17 — Condition Authoring V0

## Resume executif

NS-SCENES-V1-17 est valide.

Le Scene Builder peut maintenant configurer un `ConditionNode` avec une source structuree V0, sans expression texte magique et sans reference inventee. Les sources actives sont strictement celles autorisees par V1-16 :

- `factLikeStoryFlag`
- `storyStepCompletion`
- `consumedEvent`

Le lot ajoute le modele structure `SceneConditionSource`, une operation pure `updateSceneConditionSource`, des diagnostics conditionnels bloquants et un panel no-code dans l'inspecteur Scene. La mise a jour reste en memoire dans `ProjectManifest.scenes`.

Aucun runtime, aucune Fact Registry, aucune World Rule, aucun lien StorylineStep, aucun Event -> Scene et aucune donnee Selbrume ne sont ajoutes.

## Design / Architecture Gate

Decision retenue : etendre uniquement `SceneConditionPayload` avec une source structuree, plutot que coder une expression dans `conditionDraft`.

Reponses au gate :

- Representation : `SceneConditionSource` porte `sourceKind`, `sourceId`, `field`, `operator`, `value`, `label`, `debugTechnicalLabel`.
- Extension du modele : oui, strictement limitee au payload condition.
- Expression libre : interdite. `conditionDraft` reste compatible mais n'est pas la source de verite V1-17.
- Source/operator/value : types explicites via `SceneConditionSourceKind` et `SceneConditionOperator`.
- `conditionLabel` : conserve comme label humain affichable, derive de la source choisie lors de l'operation.
- Compatibilite JSON : les champs historiques restent presents ; `conditionSource` est optionnel et round-trippe proprement.
- Generated files : aucun fichier generated n'existe pour `scene_asset.dart`; `build_runner` non lance.
- Pickers V0 : derive des references existantes du projet : flags techniques detectes par les read models de predicates, story steps du manifest et events consommes depuis les maps disponibles.
- Diagnostics : une condition sans source structuree est une erreur ; les sources futures, operateurs incompatibles et valeurs manquantes sont bloques.
- Fact Registry / World Rules : explicitement hors scope ; les fact-like flags restent temporaires et doivent etre remplaces/enveloppes par V1-18.

## Scope realise

- Modele core structure pour condition V0.
- Operation pure d'authoring condition.
- Diagnostics Scene V1 pour conditions incompletes ou invalides.
- UI inspector no-code pour choisir source, reference, operateur et valeur.
- Callback editor pour remplacer uniquement la SceneAsset cible dans `ProjectManifest.scenes`.
- Tests core, JSON, diagnostics, editor et analyse.
- Screenshot visual gate.
- Roadmaps mises a jour.

## Fichiers crees/modifies

Fichier cree :

- `reports/narrativeStudio/scenes/ns_scenes_v1_17_condition_authoring_v0.md`
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_17_condition_authoring_v0.png`

Fichiers modifies :

- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/test/scene_asset_json_test.dart`
- `packages/map_core/test/scene_authoring_operations_test.dart`
- `packages/map_core/test/scene_diagnostics_test.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

Fichiers attendus absents :

- `packages/map_core/lib/src/models/scene_asset.freezed.dart`
  - Impact : aucun, `scene_asset.dart` est un modele manuel dans ce repo.
- `packages/map_core/lib/src/models/scene_asset.g.dart`
  - Impact : aucun, la serialization est implementee manuellement dans `scene_asset.dart`.

## Decisions techniques

- `SceneConditionPayload.conditionSource` est optionnel pour permettre des drafts incomplets.
- Une condition incomplete est autorisee en authoring mais produit une erreur diagnostic.
- Les sources futures existent dans l'enum pour stabiliser le vocabulaire, mais sont refusees par l'operation V0 et diagnostiquees comme non supportees.
- Les refs viennent de l'existant ; aucun picker ne cree de nouvelle ref.
- `ScriptCondition` reste un backend technique possible, pas une surface UI directe.
- `ProjectManifest` n'est pas modifie comme schema.

## Modele condition structure

Elements ajoutes dans `scene_asset.dart` :

- `SceneConditionSourceKind`
- `SceneConditionOperator`
- `SceneConditionValues`
- `SceneConditionSource`
- `SceneConditionPayload.conditionSource`

Sources V0 actives :

- `factLikeStoryFlag`
- `storyStepCompletion`
- `consumedEvent`

Sources futures encodees mais non actives :

- `storyStepActive`
- `inventoryItem`
- `partyState`
- `trainerDefeated`
- `dialogueOutcome`
- `battleOutcome`
- `scriptVariable`
- `worldState`

Operateurs V0 :

- `isTrue`
- `isFalse`
- `equals`

Valeurs V0 :

- `completed`
- `notCompleted`

## Operation core ajoutee

Operation :

```dart
SceneConditionSourceUpdateResult updateSceneConditionSource(
  SceneAsset scene, {
  required String nodeId,
  required SceneConditionSource source,
})
```

Garanties :

- refuse un node inconnu ;
- refuse un node non-condition ;
- refuse les sources futures ;
- refuse un `sourceId` vide via le modele ;
- refuse les operateurs incompatibles ;
- refuse `storyStepCompletion` sans `completed` ou `notCompleted` ;
- preserve les autres nodes ;
- preserve les edges ;
- preserve le layout ;
- preserve outcomes, tags, metadata, description, storylineId et chapterId ;
- ne mute jamais la scene originale.

## Sources supportees

| Source | Picker | Operateurs | Stockage | Statut |
|---|---|---|---|---|
| `factLikeStoryFlag` | flags existants derives des predicates/read models | `isTrue`, `isFalse` | `sourceId` du flag technique existant | support V0 temporaire |
| `storyStepCompletion` | storylines/chapters/steps du manifest | `equals` | `sourceId` du step | support V0 |
| `consumedEvent` | event refs derivees des maps disponibles | `isTrue`, `isFalse` | ref stable event/map | support V0 |

Decision fact-like :

`factLikeStoryFlag` est supporte seulement lorsqu'une ref existante est derivee du projet. L'UI ne permet pas de saisir un nouveau flag libre ; le label reste marque comme source existante technique tant que V1-18 n'a pas cree la Fact Registry.

## Sources refusees/reportees

Les sources suivantes ne sont pas actives :

- inventory / item ;
- party / move ;
- script variable ;
- trainer defeated dedie ;
- dialogue outcome ;
- battle outcome ;
- world state / world rule ;
- story step active.

Raison : elles demandent une registry, un picker dedie, un runtime outcome local ou un contrat World Rules non encore code.

## Diagnostics condition

Codes ajoutes :

- `conditionSourceMissing`
- `conditionSourceUnknown`
- `conditionOperatorMissing`
- `conditionOperatorUnsupported`
- `conditionValueMissing`
- `conditionSourceRequiresPicker`
- `conditionUsesFutureSource`
- `conditionUsesRawTechnicalId`
- `conditionSourceMigratesToFactRegistry`

Regles effectives :

- condition sans source structuree : erreur `conditionSourceMissing`.
- source future : erreur `conditionUsesFutureSource`.
- sourceId vide : erreur `conditionSourceMissing` ou exception de modele.
- operateur incompatible : erreur `conditionOperatorUnsupported`.
- `storyStepCompletion` sans `completed/notCompleted` : erreur `conditionValueMissing`.
- label absent ou brut identique au sourceId : warning `conditionUsesRawTechnicalId`.

## Integration editor

`SceneNodeReadOnlyInspector` affiche une section Condition pour les nodes `condition`.

UI V0 :

- boutons de type source : fait existant technique, etape narrative completee, event consomme ;
- liste controlee de refs existantes ;
- choix operateur/valeur selon le type ;
- bouton d'application ;
- rendu du payload structure dans l'inspecteur.

`ScenesWorkspace` accepte un callback `onUpdateConditionSource`, conserve la selection locale et relaie la mise a jour en memoire.

`NarrativeWorkspaceCanvas` construit les options de source depuis le `ProjectManifest` et la map active, appelle `updateSceneConditionSource`, remplace uniquement la scene cible et applique le manifest en memoire.

## Tests executes

### map_core authoring operations

Commande :

```bash
cd packages/map_core && dart test test/scene_authoring_operations_test.dart
```

Sortie exacte utile :

```text
00:00 +21: All tests passed!
```

### map_core diagnostics

Commande :

```bash
cd packages/map_core && dart test test/scene_diagnostics_test.dart
```

Sortie exacte utile :

```text
00:00 +9: All tests passed!
```

### map_core JSON

Commande :

```bash
cd packages/map_core && dart test test/scene_asset_json_test.dart
```

Sortie exacte utile :

```text
00:00 +7: All tests passed!
```

### map_editor Scenes workspace

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/scenes_workspace_shell_test.dart
```

Sortie exacte utile :

```text
00:08 +45: All tests passed!
```

### map_editor overview navigation

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_overview_shell_navigation_test.dart
```

Sortie exacte utile :

```text
00:05 +19: All tests passed!
```

### map_editor header

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/ui/canvas/narrative_studio_header_test.dart
```

Sortie exacte utile :

```text
00:02 +3: All tests passed!
```

### map_editor projection

Commande :

```bash
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
```

Sortie exacte utile :

```text
00:01 +3: All tests passed!
```

## Analyze exact

Commande :

```bash
cd packages/map_core && dart analyze
```

Sortie exacte :

```text
Analyzing map_core...
No issues found!
```

Commande :

```bash
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/narrative_workspace_canvas.dart lib/src/ui/canvas/scenes_workspace.dart lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart test/scenes_workspace_shell_test.dart
```

Sortie exacte :

```text
Analyzing 4 items...
No issues found! (ran in 1.7s)
```

## Build runner exact

Non lance.

Justification : `packages/map_core/lib/src/models/scene_asset.dart` est un modele manuel ; les fichiers `scene_asset.freezed.dart` et `scene_asset.g.dart` sont absents.

Generated files modifies : aucun.

## Visual Gate

Fichier :

```text
/Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_17_condition_authoring_v0.png
```

Commande de production :

```bash
cd packages/map_editor && flutter test --update-goldens --reporter=compact test/scenes_workspace_shell_test.dart --plain-name "writes V1-17 condition authoring screenshot"
```

Sortie exacte utile :

```text
00:00 +1: All tests passed!
```

Verification visuelle : screenshot present, workspace Scenes visible, graph/ports visibles, node Condition selectionne, inspecteur avec section Condition, source/operator/value affiches, aucune donnee Selbrume.

## Git status initial

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git log --oneline -n 10
```

Sortie exacte initiale :

```text
/Users/karim/Project/pokemonProject
main
Sortie git status : <vide>
Sortie git diff --stat : <vide>
8932f26b docs(scenes): add condition sources contract v0 and update roadmaps
385c2da3 docs(scenes): add prep condition sources roadmap review and roadmap updates
92d43017 chore(selbrume): update project.json configuration
eb2037bf feat(scenes): add wire anchor color coding and update screenshots
b98b4424 feat(scenes): add edge selection and deletion UX v0 with updated tests
a604c2c4 feat(scenes): add visual port connection UX v0 and update tests
82b0d2bc feat(scenes): add blueprint graph canvas foundation and update tests
1c5ee72d feat(scenes): implement edge authoring v0 and update tests
18046f6a feat(scenes): implement node authoring v0 and update tests
79df007c docs(scenes): add scene graph draft node strategy report
```

## Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M packages/map_core/lib/src/authoring/scene_authoring_operations.dart
 M packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
 M packages/map_core/lib/src/models/scene_asset.dart
 M packages/map_core/test/scene_asset_json_test.dart
 M packages/map_core/test/scene_authoring_operations_test.dart
 M packages/map_core/test/scene_diagnostics_test.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
 M packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
 M packages/map_editor/test/scenes_workspace_shell_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_17_condition_authoring_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_17_condition_authoring_v0.png
```

## Git diff --stat

Capture avant creation du rapport :

```text
 .../src/authoring/scene_authoring_operations.dart  | 124 ++++++
 .../lib/src/diagnostics/scene_diagnostics.dart     | 155 +++++++
 packages/map_core/lib/src/models/scene_asset.dart  | 126 +++++-
 packages/map_core/test/scene_asset_json_test.dart  |  27 ++
 .../test/scene_authoring_operations_test.dart      | 128 ++++++
 packages/map_core/test/scene_diagnostics_test.dart | 122 ++++++
 .../src/ui/canvas/narrative_workspace_canvas.dart  | 126 ++++++
 .../scenes/scene_node_read_only_inspector.dart     | 487 ++++++++++++++++++++-
 .../lib/src/ui/canvas/scenes_workspace.dart        |  38 ++
 .../test/scenes_workspace_shell_test.dart          | 298 +++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  14 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  38 +-
 12 files changed, 1673 insertions(+), 10 deletions(-)
```

## Git diff --name-only

Capture avant creation du rapport :

```text
packages/map_core/lib/src/authoring/scene_authoring_operations.dart
packages/map_core/lib/src/diagnostics/scene_diagnostics.dart
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/test/scene_asset_json_test.dart
packages/map_core/test/scene_authoring_operations_test.dart
packages/map_core/test/scene_diagnostics_test.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart
packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart
packages/map_editor/test/scenes_workspace_shell_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

## Git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
<vide>
```

## Evidence Pack

### pwd

```text
/Users/karim/Project/pokemonProject
```

### Branche

```text
main
```

### Liste des fichiers lus

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `/Users/karim/.codex/attachments/e9c2adcd-7e07-40a1-9e97-f461098b0c7a/pasted-text.txt`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_16_condition_sources_contract_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_16_prep_condition_sources_facts_world_rules_roadmap_review.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_09_scene_validation_diagnostics.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_10_runtime_execution_prep.md`
- `MVP Selbrume/narrative_studio.md`
- `MVP Selbrume/selbrume.md`
- `packages/map_core/lib/src/models/scene_asset.dart`
- `packages/map_core/lib/src/diagnostics/scene_diagnostics.dart`
- `packages/map_core/lib/src/authoring/scene_authoring_operations.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/script_conditions.dart`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/read_models/narrative_reference_picker_read_models.dart`
- `packages/map_gameplay/lib/src/script_condition_evaluator.dart`
- `packages/map_gameplay/lib/src/event_page_resolver.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart`
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/features/narrative/state/narrative_workspace_providers.dart`
- `packages/map_editor/test/scenes_workspace_shell_test.dart`

### Contenu complet des fichiers crees

Ce fichier contient le rapport complet. Le screenshot est un PNG binaire produit par le visual gate :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_17_condition_authoring_v0.png
```

### Sections completes modifiees principales

`scene_asset.dart` :

- ajout des enums `SceneConditionSourceKind`, `SceneConditionOperator` ;
- ajout de `SceneConditionValues` ;
- ajout de `SceneConditionSource` ;
- ajout de `SceneConditionPayload.conditionSource`.

`scene_authoring_operations.dart` :

- ajout de `SceneConditionSourceUpdateResult` ;
- ajout de `updateSceneConditionSource` ;
- ajout de la validation V0 par source/operator/value.

`scene_diagnostics.dart` :

- ajout des codes diagnostics condition ;
- ajout du diagnostic des `ConditionNode` incomplets ou invalides.

`scene_node_read_only_inspector.dart` :

- ajout des options picker ;
- ajout du panel condition ;
- ajout de l'affichage du payload structure.

`narrative_workspace_canvas.dart` :

- construction des options de source condition depuis les refs existantes ;
- callback de mise a jour condition source en memoire.

`scenes_workspace.dart` :

- propagation des options et du callback ;
- conservation de la selection locale.

`scenes_workspace_shell_test.dart` :

- tests de story step completion ;
- tests de fact-like story flag ;
- tests de consumed event ;
- test screenshot V1-17.

### Diff complet des roadmaps

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@
-NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)
+NS-SCENES-V1-18 — Fact Registry V0
@@
-| NS-SCENES-V1-17 | Condition Authoring V0 (Existing Sources Only) | core / editor | Configurer un `ConditionNode` V0 avec sources existantes uniquement, sans texte magique ni fake refs. | Pas de runtime, pas d'expressions complexes, pas de sources non cadrees, pas de Yarn/Battle/Cinematic pickers. | scene authoring operations, inspector controls, diagnostics tests. | Tests payload condition, mutation ProjectManifest.scenes, diagnostics condition incomplete/valid. | Ouvrir trop tot un langage de conditions complet ; exposer flags bruts. | Condition configurable via source explicite, scene invalide si condition incomplete bloquante. | V1-16. |
+| NS-SCENES-V1-17 | Condition Authoring V0 (Existing Sources Only) | core / editor | Configurer un `ConditionNode` V0 avec sources existantes uniquement, sans texte magique ni fake refs. | Pas de runtime, pas d'expressions complexes, pas de sources non cadrees, pas de Yarn/Battle/Cinematic pickers. | scene authoring operations, inspector controls, diagnostics tests. | Tests payload condition, mutation ProjectManifest.scenes, diagnostics condition incomplete/valid. | Ouvrir trop tot un langage de conditions complet ; exposer flags bruts. | DONE : condition configurable via source structuree explicite, diagnostics bloquants si incomplete, picker limite aux refs existantes. | V1-16. |
@@
+## Mise a jour V1-17
+
+Statut : `NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)` est DONE.
+
+Decision : V1-17 code l'authoring no-code d'un `ConditionNode` a source unique. Les sources V0 actives sont `factLikeStoryFlag`, `storyStepCompletion` et `consumedEvent`, selectionnees depuis des refs existantes derivees du projet. Le payload reste structure via `SceneConditionSource`; aucun texte libre, ID fake, runtime ou World Rule n'est introduit. Une condition incomplete devient une erreur authoring, ce qui garde les scenes non executables tant que le payload n'est pas honnete.
+
+Limites : pas de Fact Registry, pas de sources inventory/party/dialogue outcome/battle outcome/script variable/world state, pas de AND/OR, pas de payload picker Yarn/Battle/Cinematic, pas de runtime, pas de StorylineStep link, pas d'Event -> Scene.
+
+Prochain lot exact : `NS-SCENES-V1-18 — Fact Registry V0`.
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@
-| NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only) | TODO | Configurer un `ConditionNode` V0 uniquement avec des sources existantes et honnetes, sans texte magique ni refs inventees. |
+| NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only) | DONE | `ConditionNode` configurable avec source structuree V0 depuis refs existantes : fact-like story flag, story step completion et event consumed, sans texte magique ni fake ref. |
@@
-`NS-SCENES-V1-17 — Condition Authoring V0 (Existing Sources Only)`
+`NS-SCENES-V1-18 — Fact Registry V0`
@@
-Raison : V1-16 fixe maintenant le contrat no-code des sources conditionnelles. Le prochain lot peut coder l'authoring d'un `ConditionNode` limite aux sources V0 autorisees, sans expression libre, sans Fact Registry, sans World Rules et sans runtime.
+Raison : V1-17 permet maintenant de configurer une condition avec les sources existantes autorisees, mais les sources fact-like restent encore des flags techniques presentes avec prudence. Le prochain bloc produit doit les envelopper dans une registry de Facts lisibles, bool-first, avant d'elargir World Rules, payload pickers ou runtime.
@@
+## Decisions V1-17
+
+- `SceneConditionSource` devient le payload structure d'une condition V0 : `sourceKind`, `sourceId`, `operator`, `value`, `label` et `debugTechnicalLabel`.
+- Sources codees en V0 : `factLikeStoryFlag`, `storyStepCompletion`, `consumedEvent`.
+- Operateurs V0 : `isTrue` / `isFalse` pour les sources booleennes fact-like et consumed event ; `equals completed/notCompleted` pour story step completion.
+- L'operation pure `updateSceneConditionSource` met a jour un node `condition` sans muter la scene originale et sans toucher aux nodes, edges, layout, outcomes ou metadata.
+- L'editor expose un panel no-code dans l'inspecteur : choisir type de source, choisir une reference existante via picker derive, choisir l'operateur/valeur, puis appliquer.
+- Les diagnostics bloquent les conditions sans source structuree, les sources futures, les operateurs invalides et les valeurs manquantes ; les labels techniques bruts restent au minimum warning.
+- Aucun texte libre n'est source de verite. Aucun ID invente n'est cree.
+- Prochain lot : remplacer progressivement les flags techniques fact-like par une `Fact Registry V0` lisible.
```

## Auto-review critique

- Point solide : le lot garde la condition comme un payload structure et evite le piege du champ texte libre.
- Point solide : les diagnostics rendent les conditions incompletes non executables plus tard.
- Point de vigilance : `factLikeStoryFlag` reste une transition technique ; V1-18 doit arriver rapidement pour eviter d'installer les flags bruts comme UX durable.
- Point de vigilance : les options de source dependent des refs detectables dans le projet courant ; un projet pauvre en refs affichera peu d'options, ce qui est honnete mais peut sembler vide.
- Point de vigilance : pas de composition AND/OR ; la composition par graph devra rester claire avec les futures diagnostics de ports.

## Regard critique sur le prompt

Le prompt est bien borne : il autorise la modification du payload condition tout en interdisant runtime, Fact Registry et World Rules. La tension principale est la demande d'un Evidence Pack exhaustif avec un rapport qui est lui-meme cree par le lot : la preuve finale exacte est donc aussi reportee dans la reponse de cloture apres `git diff --check`.

La meilleure decision produit reste de coder seulement les sources existantes. Cela donne une condition utile maintenant, sans transformer l'outil en editeur de flags techniques permanent.
