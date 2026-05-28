# NS-STORYLINES-V1-01 — Storyline Authoring Model Decision

## 1. Executive summary

Decision: **Recommended model is Option C — hybrid authoring/runtime split**.

```text
StorylineAsset = authoring/product source of truth.
ScenarioAsset = executable scene/runtime flow.
```

This is not an implementation lot. No Dart code, model, test, UI, screenshot, fixture, or button was changed.

Recommended V1 source of truth:

- `Structure` tab owns authoring.
- `Graph` is generated from the authoring model in V1 initial.
- Direct graph editing is later, not V1 initial.
- `localEventFlow` is never promoted to `sideQuest` by default.

Next recommended lot:

```text
NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract
```

Reason: V1-01 makes the architecture decision, but the exact fields/enums/invariants must be specified before code.

## 2. Inputs read

Files read:

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_00_bis_evidence_pack_status_clarification.md`
- `reports/narrativeStudio/storylines/ns_storylines_checkpoint_v0_acceptance.md`
- `reports/narrativeStudio/storylines/ns_storylines_01_read_model_data_contract_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/script_asset.dart`
- `packages/map_core/lib/src/models/script_conditions.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/test/narrative_workspace_projection_test.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`

Files absent but expected:

```text
Sortie : <vide>
```

## 3. Decision context

V0 was accepted with V1 limitations. V1-00 clarified the product model:

```text
Storyline
  -> Chapter
    -> Story Step
      -> linked Scene(s)
        -> Scene Input
        -> Scene Output
        -> Scene Outcome
```

The decision now needed:

- where Storylines are persisted;
- how chapters and story steps become authorable;
- how scenes are linked without confusing them with runtime scripts;
- how outcomes connect scenes to story progression;
- how side quests become first-class storylines;
- how existing `ScenarioAsset globalStory` data migrates without breaking V0 projects.

## 4. Current model audit

Current relevant models:

- `ProjectManifest.scenarios` stores `ScenarioAsset` entries.
- `ScenarioAsset.scope` distinguishes `globalStory` and `localEventFlow`.
- `ScenarioAsset` has `nodes`, `edges`, `declaredOutcomes`, `activationCondition`, bindings and metadata.
- `GlobalStoryStudioDocument` and `StepStudioDocument` are stored in `ScenarioAsset.metadata`.
- `NarrativeWorkspaceProjection` currently projects `ScenarioAsset.globalStory` into Storylines V0.
- `localEventFlow` is already explicitly separated and must stay local/executable.

Current strengths:

- existing runtime-ish graph shape;
- declared outcomes exist;
- activation conditions exist;
- V0 projection can keep old projects readable.

Current limits:

- no explicit `StorylineAsset`;
- no first-class `StorylineType`;
- no first-class side quest model;
- no durable authoring contract for chapters/steps/scene links;
- metadata documents are usable for import but too fragile as the V1 creation source.

## 5. Model options compared

| Option | Product clarity | Migration risk | Runtime impact | Side quest support | Graph support | Recommendation |
|---|---|---|---|---|---|---|
| A — dedicated `StorylineAsset` only | High | Medium | High if runtime must learn it directly | High | High | Maybe later / partial. Good authoring model, but weak executable story without `ScenarioAsset` bridge. |
| B — enriched `ScenarioAsset` | Medium | Low short-term, high long-term | Low short-term | Medium | Medium | Rejected. Too ambiguous; risks turning executable flow into product container. |
| C — `StorylineAsset` authoring + `ScenarioAsset` executable scene flow | High | Medium | Medium and controlled | High | High | Recommended. Clean authoring/runtime split. |
| D — editor-only projection | Low for creation | Low short-term, blocking later | None initially | Low | Low | Rejected for V1 creation. Fine for V0 read-only only. |

Decision:

```text
Recommended: Option C.
Rejected as V1 source of truth: Option B and Option D.
Maybe later: parts of Option A only if runtime can consume StorylineAsset directly in V2.
```

## 6. Recommended model

Recommended architecture:

```text
ProjectManifest
  -> storylines: List<StorylineAsset>        // future V1 authoring source
  -> scenarios: List<ScenarioAsset>          // existing executable flows

StorylineAsset
  -> type
  -> chapters
  -> story steps
  -> scene links
  -> scene outcome links
  -> relationships
  -> validation issues / draft state

ScenarioAsset
  -> executable scene/local flow
  -> nodes/edges/actions/conditions
  -> declared outcomes
```

Why:

- creators author story structure in one place;
- executable scenes stay in the existing runtime-oriented shape;
- side quests become explicit `StorylineAsset(type: sideQuest)`;
- old `ScenarioAsset globalStory` can be imported without data loss;
- `localEventFlow` remains local and cannot silently become a quest.

Concept contracts:

| Concept | Role produit | Conceptual fields | Relations | Persistence recommended | Status | Risks | Migration |
|---|---|---|---|---|---|---|---|
| Storyline | Complete narrative arc | id, type, title, description, status, chapterIds, relationships | owns chapters/steps/links | `StorylineAsset` | V1 initial | duplicate main story | import from globalStory |
| StorylineType | Meaning of storyline | main, sideQuest, tutorial, epilogue, episode, postGame, hiddenEvent | on Storyline | enum in `StorylineAsset` contract | V1 initial | type sprawl | derive only globalStory as main during import |
| StorylineChapter | Large narrative section | id, order, title, description, stepIds, sceneLinkIds | child of Storyline | inside `StorylineAsset` | V1 initial | empty chapters | import `GlobalStoryChapter` |
| StorylineStep | Durable progression milestone | id, chapterId, title, description, entry/exit conditions, state rules | child of chapter | inside `StorylineAsset` | V1 initial | confused with Fact | import `StepStudioStep` |
| StorylineSceneLink | Link from structure to executable scene | id, chapterId, stepId?, sceneRef?, placeholder?, order, role, typeHint | links to `ScenarioAsset` or placeholder | inside `StorylineAsset` | V1 initial | unresolved links | placeholders for missing scenes |
| StorylineSceneOutcomeLink | Maps scene result to story effects | id, sceneLinkId, outcomeId, activates/completes step, emits fact/world rule | consumes `ScenarioAsset.declaredOutcomes` | inside `StorylineAsset` | V1 initial | outcome id drift | map existing declared outcomes |
| StorylineRelationship | Main/side/convergence relation | id, fromStorylineId, toStorylineId, kind, condition, chapter/step anchor | links storylines | inside `StorylineAsset` or project-level relation list | V1 later | complex graph semantics | manual review |
| SideQuestAvailability | Availability window | sideQuestId, mainStorylineId, startCondition, endCondition, anchorStepId | relationship detail | inside relationship | V1 later | fake availability | no auto localEventFlow conversion |
| StorylineValidationIssue | Authoring feedback | id, severity, targetRef, message, ruleId | generated from model | derived, not persisted except cache | V1 initial | stale diagnostics | recompute |
| StorylineCreationDraft | UI draft before save | type, title, description, initial chapter option | transient editor state | editor state, not project data | V1 initial | accidental persistence | no migration |

## 7. Storyline main contract

Main storyline decision:

- A project should have **at most one active main Storyline** in V1 initial.
- Multiple archived/imported main candidates may exist only as migration/draft state, not active authoring truth.
- Existing `ScenarioAsset(scope == globalStory)` becomes an import/projection source for the initial main `StorylineAsset`.
- If a main Storyline already exists, `Create main storyline` must not silently create a second one.
- UI should offer: edit existing, import from globalStory, or explicitly replace main.
- `Replace main` is a guided authoring action with validation and preview, not a silent mutation.

Reason:

```text
Main story uniqueness keeps Graph, validation, side quest availability and progression understandable.
```

## 8. Side quest contract

Side quest decision:

- A side quest is always a `StorylineAsset` with `type == sideQuest`.
- It may have a parent/main storyline relationship, but the model should allow temporary independent drafts.
- It owns its own chapters, story steps, scene links and outcomes.
- It can appear in the main graph through explicit relationships/availability windows.
- Availability is defined by conditions/outcomes/step anchors, not by guessing from `localEventFlow`.

`localEventFlow` rule:

```text
localEventFlow is executable local scene/event flow.
localEventFlow is not sideQuest.
localEventFlow can be linked by a sideQuest scene link only when explicitly chosen.
```

## 9. Chapter contract

Chapter decision:

- `StorylineChapter` is a persistent entity inside `StorylineAsset`.
- It directly owns ordered `StorylineStep` ids.
- It can carry direct scene links only as planning/unassigned links, but V1 should encourage linking scenes through steps.
- It can exist without a step as a draft.
- It is not merely a visual group; it is authoring structure.

Minimum conceptual fields:

```text
id
order
title
description
stepIds
sceneLinkIds
metadata / author notes later
```

## 10. Story Step contract

Story Step decision:

- `StorylineStep` is persistent.
- It belongs to exactly one chapter in V1 initial.
- It is not shared between storylines in V1 initial.
- It represents durable narrative progression, not playable content.
- It differs from `Fact`: a step is authored progression; a fact is persistent world truth.
- It differs from `Scene Outcome`: an outcome is a result event; a step can be activated/completed by that result.

Minimum conceptual fields:

```text
id
chapterId
order
title
description
entryCondition
completionCondition
linkedSceneIds
```

## 11. Scene and Scene Outcome contract

Scene decision:

- In V1 initial, `Scene` is a product concept exposed through `StorylineSceneLink`.
- Executable scene flow is backed by `ScenarioAsset` or a future scene-scoped executable asset.
- A scene placeholder can be created from `Structure` before executable content exists.
- A scene connects to a map/event through explicit references, not raw flags in normal UI.

Scene link states:

```text
placeholder
linkedScenario
linkedScript
linkedDialogue
needsImplementation
```

Scene Outcome decision:

- Outcomes are named.
- Outcomes should be typed later, but V1 initial can start with stable ids plus effect categories.
- Actual executable outcomes should come from the scene executable flow, currently `ScenarioAsset.declaredOutcomes`.
- `StorylineSceneOutcomeLink` maps an outcome to story effects: activate step, complete step, emit fact, set world rule, open side quest availability, converge branch.
- Placeholder scenes may declare expected outcomes until linked to executable content.

Ownership rule:

```text
Scene defines what can happen.
Storyline defines what that result means for narrative progression.
```

## 12. Graph source-of-truth decision

Decision:

```text
Structure = source of authoring.
Graph = generated view / comprehension view in V1 initial.
```

Graph V1 initial:

- read-only or limited-selection only;
- generated from StorylineAsset chapters, steps, scene links, outcome links and relationships;
- shows branches, convergence and side quest availability when model data exists;
- does not become a second authoring source.

Direct graph editing:

- V1 later or V2;
- only after data-shape invariants exist;
- must write back to `StorylineAsset`, never to a visual-only layout as product truth.

## 13. Compatibility with existing ScenarioAsset model

| Existing model | Current role | Keep | Migrate | Adapt | Risk | Recommendation |
|---|---|---|---|---|---|---|
| `ScenarioAsset(scope == globalStory)` | V0 global story projection and metadata host | Yes during transition | Yes, into main `StorylineAsset` | Later as import source | duplicate truth | Keep readable; migrate non-destructively. |
| `ScenarioAsset(scope == localEventFlow)` | local executable flow/event hook | Yes | No automatic side quest migration | Link explicitly as scene executable | fake side quests | Never auto-promote. |
| `GlobalStoryStudioDocument` | V0 chapters metadata | Yes for import | Yes, into chapters | Deprecated later | metadata drift | Import to `StorylineChapter`. |
| `GlobalStoryChapter` | V0 chapter | Yes for import | Yes | Replace later | missing scene semantics | Map to `StorylineChapter`. |
| `StepStudioDocument` | V0 step metadata | Yes for import | Yes | Replace later | step/outcome drift | Map to `StorylineStep`. |
| `StepStudioStep` | V0 narrative step | Yes for import | Yes | Replace later | not scene | Map to `StorylineStep`. |
| `NarrativeWorkspaceProjection` | editor read model | Yes | No data migration | Adapt to StorylineAsset + legacy fallback | complex branching | Keep as adapter/read model. |
| `ProjectManifest.scenarios` | stores executable scenarios | Yes | No | Add separate storylines later | schema change | Do not overload scenarios for Storyline V1. |
| `ScriptAsset` | executable command graph | Yes | No | Link via scene | too low-level for author | Use behind pickers. |
| `ScriptCondition` | condition primitives | Yes | No | Reuse in typed authoring wrappers | raw flag exposure | Use guided condition UI later. |

## 14. Migration strategy

Migration principle:

```text
Import, do not mutate destructively.
```

Recommended migration:

| Existing data | Target representation | Migration mode | Automatic? | Manual review needed? | Notes |
|---|---|---|---|---|---|
| one `ScenarioAsset.globalStory` | main `StorylineAsset` | import draft | Yes, with preview | Yes for activation | Preserve scenario. |
| multiple `ScenarioAsset.globalStory` | one active main plus candidates | import candidates | Partial | Yes | User chooses active main. |
| `GlobalStoryChapter` | `StorylineChapter` | direct mapping | Yes | Low | Preserve order/id where safe. |
| `StepStudioStep` | `StorylineStep` | direct mapping | Yes | Medium | Verify activation/completion outcomes. |
| `GlobalStoryChapter.stepIds` | chapter step ordering | direct mapping | Yes | Medium | Missing ids become validation issues. |
| `ScenarioAsset.declaredOutcomes` | scene outcome candidates | link/import | Partial | Yes | Need scene association. |
| `ScenarioAsset.localEventFlow` | executable scene candidate | explicit link only | No | Yes | Never side quest by default. |
| metadata-only authoring docs | legacy import source | read fallback | Yes | Yes before save | Deprecated after migration. |

Migration sequence:

1. Detect legacy V0 sources.
2. Build an import preview.
3. Create `StorylineAsset` draft.
4. Preserve original `ScenarioAsset`.
5. Generate validation issues for missing steps/outcomes/scene links.
6. Require explicit user confirmation before replacing active main.

## 15. Target concept matrix

| Concept | Recommended persistence | V1 initial? | Owns authoring? | Runtime-facing? | Notes |
|---|---|---|---|---|---|
| Storyline | `StorylineAsset` | Yes | Yes | Indirect | Product source. |
| StorylineType | enum in `StorylineAsset` | Yes | Yes | Indirect | main, sideQuest, tutorial, epilogue, episode. |
| StorylineChapter | inside `StorylineAsset` | Yes | Yes | No direct | Organizes steps/scenes. |
| StorylineStep | inside `StorylineAsset` | Yes | Yes | Indirect | Durable progression. |
| StorylineSceneLink | inside `StorylineAsset` | Yes | Yes | Indirect | Links placeholder/executable scene. |
| StorylineSceneOutcomeLink | inside `StorylineAsset` | Yes | Yes | Indirect | Maps scene results to story meaning. |
| StorylineRelationship | project/storyline relation | Later | Yes | Indirect | Side quest availability/convergence. |
| SideQuestAvailability | relationship detail | Later | Yes | Indirect | Explicit window. |
| StorylineValidationIssue | derived | Yes | No | No | Recomputed diagnostics. |
| StorylineCreationDraft | editor state | Yes | Yes | No | Transient only. |

## 16. Existing model compatibility matrix

| Existing model | Current role | Keep | Migrate | Adapt | Risk | Recommendation |
|---|---|---|---|---|---|---|
| `ScenarioAsset.globalStory` | current V0 storyline source | Yes | Yes | Import adapter | duplicate truth | Keep legacy; migrate to main StorylineAsset. |
| `ScenarioAsset.localEventFlow` | executable local flow | Yes | No automatic | explicit scene link | fake quest | Keep local. |
| `GlobalStoryStudioDocument` | metadata chapters | Yes | Yes | legacy fallback | fragile metadata | Import then deprecate. |
| `StepStudioDocument` | metadata steps | Yes | Yes | legacy fallback | outcome mapping | Import then deprecate. |
| `NarrativeWorkspaceProjection` | read model | Yes | No | read StorylineAsset first | complexity | Adapt after data shape. |
| `ProjectManifest.scenarios` | scenario storage | Yes | No | add `storylines` later | schema migration | Do not overload. |
| `ScriptAsset` | commands | Yes | No | link behind scene | raw scripting UI | Keep separate. |
| `ScriptCondition` | condition primitive | Yes | No | wrap for no-code | raw flags | Reuse internally. |

## 17. Decision matrix

| Decision | Recommendation | Why | Risk | Follow-up lot |
|---|---|---|---|---|
| Model option | Option C hybrid | best authoring/runtime separation | medium migration | V1-02 |
| Storyline persistence | new `StorylineAsset` later | product clarity | schema change | V1-02 |
| Scenario role | executable scene flow | preserves existing runtime path | duplicate during migration | V1-02 |
| Main uniqueness | one active main | graph/side quest clarity | import candidates | V1-02 |
| Side quest | `StorylineAsset(type: sideQuest)` | first-class quest | relation complexity | V1-03/V1-04 |
| Chapter | persistent inside Storyline | authoring structure | empty drafts | V1-02 |
| Story Step | persistent inside Chapter | durable progression | Fact confusion | V1-02 |
| Scene | link/placeholder to executable flow | no premature SceneAsset | weak until linked | V1-02 |
| Outcome | scene declared + storyline mapped | clear meaning split | id drift | V1-02 |
| Graph truth | generated from Structure | avoids dual truth | less interactive initially | V1-06/V1-07 |
| localEventFlow | never sideQuest by default | anti-fake | manual linking needed | V1-02 |

## 18. Recommended next lots

Recommended order:

1. `NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract`
2. `NS-STORYLINES-V1-03 — Create Main Storyline Flow`
3. `NS-STORYLINES-V1-04 — Create Side Quest Storyline Flow`
4. `NS-STORYLINES-V1-05 — Storyline Type / Status / Validation`
5. `NS-STORYLINES-V1-06 — Side Quest Graph Integration`
6. `NS-STORYLINES-V1-07 — V1 Visual Graph Enrichment`

Reason V1-02 should be data shape, not UI:

```text
The model decision is clear, but exact fields, JSON shape, invariants and migration tests are not yet specified.
```

Do not start V1-02 inside this lot.

## 19. Roadmap update

Roadmap updated:

- `NS-STORYLINES-V1-01` marked DONE.
- Recommended model recorded: `StorylineAsset` authoring model + `ScenarioAsset` executable scene flow.
- Risks recorded: migration, temporary duplicate truth, scene placeholders/outcomes need precise contract.
- Current lot updated to V1-01.
- Next recommended lot updated to `NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract`.
- V1 sequence adjusted so data shape precedes create flows.

## 20. Commands run

Initial Git:

```text
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Read/audit:

```text
for f in [required files]; do test -f "$f"; done
rg -n "Roadmap status:|Current lot:|Current lot status:|Next recommended lot:|NS-STORYLINES-V1-00|NS-STORYLINES-V1-01|NS-STORYLINES-V1-02|Storyline Authoring Model Decision" reports/narrativeStudio/storylines/road_map_storylines.md reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md
rg -n "class ScenarioAsset|enum ScenarioScope|globalStory|localEventFlow|metadata|class ProjectManifest|scenarios|class ScriptAsset|class ScriptCondition|Condition|Event|StepStudio|GlobalStory|NarrativeChapterSummary|NarrativeStepSummary|chapters|missingStepIds" packages/map_core/lib/src/models/scenario_asset.dart packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/models/script_asset.dart packages/map_core/lib/src/models/script_conditions.dart packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
rg -n "Storyline|Chapter|Story Step|Scene|Outcome|sideQuest|localEventFlow|Structure|Graph|ScenarioAsset|GlobalStoryStudioDocument" reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md reports/narrativeStudio/storylines/ns_storylines_01_read_model_data_contract_v0.md reports/narrativeStudio/storylines/ns_storylines_00_current_state_target_gap_audit.md reports/narrativeStudio/storylines/ns_storylines_checkpoint_v0_acceptance.md
sed -n '1,190p' packages/map_core/lib/src/models/scenario_asset.dart
sed -n '130,190p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,170p' packages/map_core/lib/src/models/script_asset.dart
sed -n '1,120p' packages/map_core/lib/src/models/script_conditions.dart
test -f reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md && echo exists || echo missing
sed -n '600,835p' reports/narrativeStudio/storylines/road_map_storylines.md
```

Final Git:

```text
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

Tests/analyze:

```text
Not run. Documentation-only lot. No Dart code or test modified.
```

## 21. Evidence Pack

Git branch initiale:

```text
main
```

Git status initial exact:

```text
?? reports/narrativeStudio/storylines/ns_storylines_v1_00_bis_evidence_pack_status_clarification.md
```

Git diff --stat initial:

```text
Sortie : <vide>
```

Git diff --name-only initial:

```text
Sortie : <vide>
```

Git diff --check initial:

```text
Sortie : <vide>
```

Liste des fichiers lus: voir section 2.

Liste des fichiers absents mais attendus:

```text
Sortie : <vide>
```

Git status final exact:

```text
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md
```

Git diff --stat final:

```text
 .../storylines/road_map_storylines.md              | 56 +++++++++++++++++-----
 1 file changed, 44 insertions(+), 12 deletions(-)
```

Git diff --name-only final:

```text
reports/narrativeStudio/storylines/road_map_storylines.md
```

Git diff --check final:

```text
Sortie : <vide>
```

Diff complet de `road_map_storylines.md`:

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 58d2f08d..8957ab9f 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -302,7 +302,8 @@ Interprétation V0 :
 | NS-STORYLINES-11 | Storylines Interaction Wiring V0 | editor UI / test | DONE | NS-STORYLINES-CHECKPOINT |
 | NS-STORYLINES-CHECKPOINT | Storylines V0 Acceptance Checkpoint | checkpoint | DONE | NS-STORYLINES-V1-00 |
 | NS-STORYLINES-V1-00 | Storyline Semantics Reset / Usable Authoring Contract | product contract | DONE | NS-STORYLINES-V1-01 |
-| NS-STORYLINES-V1-01 | Storyline Authoring Model Decision | model decision | TODO | NS-STORYLINES-V1-02 |
+| NS-STORYLINES-V1-01 | Storyline Authoring Model Decision | model decision | DONE | NS-STORYLINES-V1-02 |
+| NS-STORYLINES-V1-02 | Storyline Authoring Data Shape Contract | data contract | TODO | NS-STORYLINES-V1-03 |
 
 ## 9. Detailed lots
 
@@ -623,10 +624,29 @@ Interprétation V0 :
 
 - Type : model decision / product architecture.
 - Objectif : décider le modèle durable pour créer et relier Storylines, Chapters, Story Steps et Scenes.
-- Non-objectifs : pas d'UI avant décision modèle.
+- Résultat : décision hybride retenue.
+- Modèle recommandé : `StorylineAsset` authoring model + `ScenarioAsset` executable scene flow.
+- Rôle `StorylineAsset` : structure produit auteur, types de storyline, chapters, story steps, scene links, outcomes, relationships, side quest availability, validation issues.
+- Rôle `ScenarioAsset` : flow exécutable, scènes/orchestrations runtime, graph local, outcomes déclarés et conditions.
+- Décisions clés : Structure est source d'authoring ; Graph est généré/read-only en V1 initial ; `localEventFlow` reste exclu comme `sideQuest` par défaut.
+- Risques : migration douce de `ScenarioAsset globalStory`, duplication temporaire pendant transition, besoin d'un contrat précis pour scene placeholders/outcomes.
+- Fichiers créés/modifiés : `reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
+- Tests exécutés : aucun, lot documentation-only.
+- Analyse exécutée : aucune, lot documentation-only.
+- Non-objectifs respectés : aucun code, modèle core, widget, test, screenshot ou bouton activé.
 - Dépendances : NS-STORYLINES-V1-00.
+- Statut : DONE.
+- Prochain lot attendu : NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract.
+
+### NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract
+
+- Type : data-contract / architecture.
+- Objectif : transformer la décision V1-01 en contrat de données précis avant implémentation.
+- Résultat attendu : champs, enums, invariants, validation rules, migration plan et tests futurs pour le modèle `StorylineAsset`.
+- Non-objectifs : pas d'UI de création avant contrat data shape.
+- Dépendances : NS-STORYLINES-V1-01.
 - Statut : TODO.
-- Prochain lot attendu : NS-STORYLINES-V1-02.
+- Prochain lot attendu : NS-STORYLINES-V1-03.
 
 ## 10. Update protocol for every future lot
 
@@ -744,10 +764,10 @@ Décision temporaire :
 ## 13. Current status
 
 ```text
-Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 PRODUCT CONTRACT ACTIVE
-Current lot: NS-STORYLINES-V1-00
+Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 MODEL DECISION DONE
+Current lot: NS-STORYLINES-V1-01
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-V1-01 — Storyline Authoring Model Decision
+Next recommended lot: NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract
 ```
 
 | Lot | Status | Last update | Notes |
@@ -767,7 +787,8 @@ Next recommended lot: NS-STORYLINES-V1-01 — Storyline Authoring Model Decision
 | NS-STORYLINES-11 | DONE | 2026-05-28 | Interaction wiring V0 livré : sélection locale de globalStory existante, synchronisation zones read-only, actions futures non mutantes, notes V1 Creation Readiness. |
 | NS-STORYLINES-CHECKPOINT | DONE | 2026-05-28 | Storylines V0 acceptance checkpoint livré : ACCEPTED V0 WITH V1 LIMITATIONS ; prochaine phase recommandée V1 semantic/product contract. |
 | NS-STORYLINES-V1-00 | DONE | 2026-05-28 | Reset sémantique produit livré : Storylines V0 techniquement valide, V1 doit clarifier et rendre utilisables Storyline / Chapter / Story Step / Scene / Graph / Structure. |
-| NS-STORYLINES-V1-01 | TODO | 2026-05-28 | Storyline Authoring Model Decision. |
+| NS-STORYLINES-V1-01 | DONE | 2026-05-28 | Modèle hybride retenu : `StorylineAsset` authoring + `ScenarioAsset` executable scene flow ; Structure source d'authoring, Graph généré. |
+| NS-STORYLINES-V1-02 | TODO | 2026-05-28 | Storyline Authoring Data Shape Contract. |
 
 ## 14. V1 Creation Readiness Notes
 
@@ -789,14 +810,25 @@ Suite V1 documentaire recommandée :
 
 - `NS-STORYLINES-V1-00 — Storyline Semantics Reset / Usable Authoring Contract`
 - `NS-STORYLINES-V1-01 — Storyline Authoring Model Decision`
-- `NS-STORYLINES-V1-02 — Create Main Storyline Flow`
-- `NS-STORYLINES-V1-03 — Create Side Quest Storyline Flow`
-- `NS-STORYLINES-V1-04 — Storyline Type / Status / Validation`
-- `NS-STORYLINES-V1-05 — Side Quest Graph Integration`
-- `NS-STORYLINES-V1-06 — V1 Visual Graph Enrichment`
+- `NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract`
+- `NS-STORYLINES-V1-03 — Create Main Storyline Flow`
+- `NS-STORYLINES-V1-04 — Create Side Quest Storyline Flow`
+- `NS-STORYLINES-V1-05 — Storyline Type / Status / Validation`
+- `NS-STORYLINES-V1-06 — Side Quest Graph Integration`
+- `NS-STORYLINES-V1-07 — V1 Visual Graph Enrichment`
 
 ## 15. Changelog
 
+### 2026-05-28 — NS-STORYLINES-V1-01
+
+- Décision d'architecture Storylines V1 livrée.
+- Modèle recommandé : `StorylineAsset` authoring model + `ScenarioAsset` executable scene flow.
+- `StorylineAsset` devient la source produit pour Storylines, Chapters, Story Steps, scene links, outcomes, relationships, side quest availability et validation issues.
+- `ScenarioAsset` reste le modèle exécutable pour les scènes/flows runtime et n'est pas enrichi comme conteneur produit Storyline.
+- `localEventFlow` reste exclu comme `sideQuest` par défaut.
+- Décision Graph : `Structure` est source d'authoring ; `Graph` est généré/read-only en V1 initial, édition limitée plus tard.
+- Prochain lot recommandé : `NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract`.
+
 ### 2026-05-28 — NS-STORYLINES-V1-00
 
 - Reset sémantique produit Storylines V1 livré.
```

Contenu complet du rapport créé:

```text
Le contenu complet du rapport créé est le présent document, du titre "# NS-STORYLINES-V1-01 — Storyline Authoring Model Decision" jusqu'à la section "## 22. Self-review".
```

Justification de l'absence de tests Flutter:

```text
Lot documentation-only. Aucun code Dart, test, widget, modèle ou screenshot modifié.
```

Auto-review critique:

```text
- La décision est claire mais volontairement non implémentée.
- Le rapport recommande `StorylineAsset`, mais la forme exacte attend V1-02.
- Le choix de ne pas faire de Graph une source d'édition peut frustrer à court terme, mais évite une double source de vérité.
- La migration depuis `ScenarioAsset.globalStory` devra être testée avant activation UI.
- Le fichier V1-00-bis était untracked au début du lot mais n'apparaît plus dans le status final; aucune commande Git write n'a été exécutée dans ce lot.
```

## 22. Self-review

Criteria reviewed:

- Aucun code modifié: yes.
- Aucun test modifié: yes.
- Aucun screenshot modifié: yes.
- Options de modèle comparées: yes.
- Recommandation claire: yes, Option C.
- Rôle `StorylineAsset` tranché: yes, authoring source.
- Rôle `ScenarioAsset` tranché: yes, executable scene flow.
- `localEventFlow` exclu comme sideQuest: yes.
- Main storyline contract: yes.
- Side quest contract: yes.
- Chapter contract: yes.
- Story step contract: yes.
- Scene/outcome contract: yes.
- Graph vs Structure source of truth: yes.
- Migration documented: yes.
- Roadmap updated: yes.
- Next lot recommended: yes, V1-02 data shape.
- `git diff --check` clean: yes.
