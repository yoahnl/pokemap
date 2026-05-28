# NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract

## 1. Executive summary

V1-02 turns the V1-01 architecture decision into a precise conceptual data contract.

Decision preserved:

```text
StorylineAsset = authoring/product source of truth.
ScenarioAsset = executable scene/runtime flow.
Structure = authoring source.
Graph = generated view in V1 initial.
```

Main recommendations:

- future `ProjectManifest.storylines: List<StorylineAsset>` with default `[]`;
- old projects without `storylines` must decode as empty list;
- `StorylineAsset` stores chapters, steps, scene links and outcome links inline;
- `StorylineSceneLink` V1 initial supports `placeholder` and `linkedScenario`;
- `StorylineSceneOutcomeLink` V1 initial supports at least activate/complete step effects;
- facts/world rules/dialogue/cinematic/battle direct links are reserved for later wrappers;
- legacy `ScenarioAsset.globalStory` import is preview/non-destructive;
- `localEventFlow` is never auto-promoted to side quest.

Next recommended lot:

```text
NS-STORYLINES-V1-03 — StorylineAsset Model V0
```

The contract is precise enough to start model implementation next.

## 2. Inputs read

Files read:

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md`
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

## 3. Decision context from V1-01

V1-01 recommended the hybrid model:

```text
StorylineAsset authoring model + ScenarioAsset executable scene flow
```

Implications:

- `StorylineAsset` must be rich enough for creation and organization.
- `ScenarioAsset` must remain executable and not become a product Storyline container.
- `ProjectManifest.scenarios` remains for existing executable flows.
- future `ProjectManifest.storylines` should carry authoring storylines.
- V1 initial graph should be generated, not edited directly.

## 4. Recommended data shape overview

Conceptual future shape:

```text
ProjectManifest
  storylines: List<StorylineAsset> = []
  scenarios: List<ScenarioAsset> = existing executable flows

StorylineAsset
  id
  schemaVersion
  type
  status
  title
  description
  sortOrder
  locale
  chapters
  sceneLinks
  relationships
  legacySource
  authorNotes
  metadata
```

Inline storage recommendation:

- chapters inline in `StorylineAsset`;
- steps inline in chapters;
- scene links inline in `StorylineAsset`, referenced by chapter/step ids;
- outcome links inline in each scene link;
- relationships should be project-level later, but may be represented in `StorylineAsset.relationships` until a project relation store exists.

Why:

- one asset can be copied, reviewed, validated and migrated;
- authoring stays coherent;
- no premature cross-file asset system;
- avoids turning `ScenarioAsset` into a mixed authoring/runtime object.

## 5. StorylineAsset contract

Product role:

```text
Authoring source for one complete or semi-complete narrative line.
```

Conceptual fields:

- `id`
- `schemaVersion`
- `type`
- `status`
- `title`
- `description`
- `sortOrder`
- `locale`
- `chapters`
- `sceneLinks`
- `relationships`
- `legacySource`
- `authorNotes`
- `metadata`

Required fields:

- `id`
- `schemaVersion`
- `type`
- `status`
- `title`
- `chapters`
- `sceneLinks`

Optional fields:

- `description`
- `sortOrder`
- `locale`
- `relationships`
- `legacySource`
- `authorNotes`
- `metadata`

Auto-generated:

- `id` by authoring command;
- default `schemaVersion`;
- default `status = draft`;
- `sortOrder` when inserted in list;
- validation issues derived, not stored as truth.

Invariants:

- `id` unique in `ProjectManifest.storylines`;
- at most one active `main`;
- chapter ids unique inside storyline;
- scene link ids unique inside storyline;
- `localEventFlow` never auto-imported as `sideQuest`.

Validation:

- title required;
- duplicate id blocked;
- duplicate active main blocked;
- broken chapter/step/scene references reported.

Status:

- V1 initial.

Existing model link:

- imported from `ScenarioAsset.globalStory` and metadata documents;
- links to `ScenarioAsset` through scene links, not by becoming a scenario.

Migration:

- legacy import preview;
- no destructive migration on load.

Risks:

- temporary dual truth during migration;
- schema version must be explicit from day one.

## 6. StorylineType contract

Enum values:

| Type | Product role | V1 initial? | Constraints | UI visibility | Chapters? | Steps? | Relationships? | Direct creation? |
|---|---|---|---|---|---|---|---|---|
| `main` | primary narrative | yes | at most one active | visible | yes | yes | yes | yes, if none active or replace flow |
| `sideQuest` | optional storyline | yes | explicit relation for main graph display | visible | yes | yes | yes | yes |
| `tutorial` | onboarding narrative | later | may be unique later | hidden V1 initial | yes | yes | maybe | later |
| `epilogue` | post-main narrative | later | usually after main completion | hidden V1 initial | yes | yes | yes | later |
| `episode` | modular story episode | later | may be standalone | hidden V1 initial | yes | yes | yes | later |
| `postGame` | post-game storyline | later | after main completion | hidden V1 initial | yes | yes | yes | later |
| `hiddenEvent` | secret event chain | later | no direct sidebar by default | hidden V1 initial | maybe | maybe | yes | later |

Decisions:

- `main` is unique as active storyline.
- `sideQuest` does not require a parent while draft.
- `sideQuest` needs explicit relationship to appear in main graph.
- `tutorial`, `epilogue`, `episode`, `postGame`, `hiddenEvent` are contract-ready but not V1 initial creation UI.

## 7. StorylineStatus contract

Status is needed in V1 initial, but it must remain authoring/project status, not fake runtime truth.

Enum values:

- `draft`
- `active`
- `archived`
- `disabled`

Meanings:

- `draft`: authoring exists but not intended for runtime/export yet.
- `active`: authoring candidate used by Structure/Graph and future validation.
- `archived`: retained for migration/history; hidden from normal active authoring.
- `disabled`: intentionally not included in generated graph/runtime export.

Rules:

- default `draft`;
- `active main` must be unique;
- side quest `disabled` does not appear in main graph;
- archived can be used during import/replacement.

No V0-style fake status:

```text
Do not display "Active" unless it comes from this field.
```

## 8. StorylineChapter contract

Product role:

```text
Persistent narrative section inside a Storyline.
```

Fields:

- `id`
- `title`
- `description`
- `order`
- `steps`
- `directSceneLinkIds`
- `status`
- `authorNotes`
- `metadata`

Required:

- `id`
- `title`
- `order`
- `steps`

Optional:

- `description`
- `directSceneLinkIds`
- `status`
- `authorNotes`
- `metadata`

Auto-generated:

- id;
- order on insert;
- optional draft title fallback only in UI, not persisted as fake title.

Decisions:

- Chapter is inline in `StorylineAsset`.
- Chapter organizes `StorylineStep`.
- Chapter can be empty as draft.
- Chapter can be reordered.
- Direct scene links are allowed only for unassigned/planning links; V1 should encourage scene links through steps.

Validation:

- duplicate chapter id blocked;
- duplicate order warned/blocking depending command;
- empty chapter allowed with warning;
- missing title blocking for activation.

## 9. StorylineStep contract

Product role:

```text
Durable narrative progression milestone inside one Chapter.
```

Fields:

- `id`
- `title`
- `description`
- `order`
- `entryCondition`
- `completionCondition`
- `sceneLinkIds`
- `expectedOutcomeIds`
- `status`
- `authorNotes`
- `metadata`

Required:

- `id`
- `title`
- `order`
- `sceneLinkIds`

Optional:

- `description`
- `entryCondition`
- `completionCondition`
- `expectedOutcomeIds`
- `status`
- `authorNotes`
- `metadata`

Decisions:

- Step belongs to exactly one Chapter in V1 initial.
- Step is not shared between Storylines.
- Step can exist without Scene as planning milestone.
- Step can be completed by multiple outcomes through outcome links.
- Step can unlock a side quest through relationship/outcome effects.

Difference from Fact:

- Step = authored progression milestone.
- Fact = persistent world truth.

Difference from Scene Outcome:

- Outcome = result emitted by a scene.
- Step = state changed by that result.

## 10. StorylineSceneLink contract

Product role:

```text
Link Structure authoring to a future or executable Scene.
```

Recommended V1 initial scope:

```text
placeholder + linkedScenario only.
```

Fields:

- `id`
- `chapterId`
- `stepId`
- `label`
- `state`
- `role`
- `sceneRef`
- `order`
- `expectedOutcomeIds`
- `outcomeLinks`
- `authorNotes`
- `metadata`

Required:

- `id`
- `chapterId`
- `label`
- `state`
- `role`
- `order`
- `outcomeLinks`

Optional:

- `stepId`
- `sceneRef`
- `expectedOutcomeIds`
- `authorNotes`
- `metadata`

Reference union:

```text
StorylineSceneRef
  kind: scenario
  scenarioId
```

Future references:

- script;
- dialogue;
- cinematic;
- battle;
- dedicated scene asset.

Decision:

- avoid direct script/dialogue/cutscene refs in V1 initial;
- dialogue/cinematic/battle stay inside executable `ScenarioAsset` flow;
- scene placeholder can exist without executable target.

## 11. StorylineSceneOutcomeLink contract

Product role:

```text
Map a Scene outcome to narrative progression effects.
```

Fields:

- `id`
- `outcomeId`
- `label`
- `effects`
- `notes`
- `metadata`

Required:

- `id`
- `outcomeId`
- `effects`

Optional:

- `label`
- `notes`
- `metadata`

Effect model:

```text
StorylineEffect
  type
  targetId
  value?
```

V1 initial effect types:

- `activateStep`
- `completeStep`
- `unlockStoryline`

Reserved later:

- `emitFact`
- `setWorldRule`
- `affectRelationship`
- `setStorylineStatus`

Decisions:

- effects should be typed;
- V1 initial must at least activate/complete steps;
- facts/world rules are reserved until their authoring contracts exist;
- outcome ids should match executable `ScenarioAsset.declaredOutcomes` when linked.

## 12. StorylineRelationship and SideQuestAvailability contract

Product role:

```text
Represent relation between storylines and graph availability.
```

`StorylineRelationship` fields:

- `id`
- `kind`
- `sourceStorylineId`
- `targetStorylineId`
- `anchor`
- `availability`
- `condition`
- `notes`
- `metadata`

`SideQuestAvailability` fields:

- `startAnchor`
- `endAnchor`
- `availabilityCondition`
- `expiresCondition`
- `requiredOutcomeIds`

Relationship kinds:

- `sideQuestAvailableDuring`
- `sideQuestUnlockedBy`
- `sideQuestAffectsMain`
- `convergesTo`
- `requires`
- `blocks`

Storage decision:

- V1 initial can store relationships on the source `StorylineAsset`.
- Project-level relationship store is recommended later when cross-storyline graph editing grows.

Side quest decision:

- side quest can exist without parent while draft;
- side quest needs explicit relationship to appear in main graph;
- availability window can be bounded by chapter, step or outcome anchors.

## 13. Conditions and effects strategy

Conditions:

- reuse `ScriptCondition` conceptually;
- do not invent a second condition language;
- wrap `ScriptCondition` in no-code authoring labels later;
- never expose raw flags as normal UI.

Recommended conceptual wrapper:

```text
StorylineCondition
  id
  label
  scriptCondition
  authorSummary
```

Effects:

- define typed `StorylineEffect`;
- V1 initial supports step/storyline effects;
- fact/world rule effects reserved until their contracts exist.

UI requirement:

```text
Show readable phrases, not flag/variable internals.
```

## 14. JSON / ProjectManifest persistence strategy

Recommended future persistence:

```text
ProjectManifest.storylines: List<StorylineAsset>
Default: []
```

Rules:

- non-nullable list with default `[]`;
- old projects without `storylines` decode as `[]`;
- enums encoded as stable lowerCamel strings;
- every model has `schemaVersion` where future migration is likely;
- ids are stable strings generated by authoring commands;
- `legacySource` records import provenance;
- metadata remains string map only for editor notes/forward compatibility, not primary model truth.

Recommended `StorylineAsset.schemaVersion`:

```text
1
```

Legacy strategy:

- if `ProjectManifest.storylines` empty, editor may show legacy V0 projection from `ScenarioAsset.globalStory`;
- import creates draft `StorylineAsset`;
- original scenario remains untouched.

## 15. Invariants

Invariant levels:

- MUST V1 initial
- SHOULD V1
- LATER

Key invariants:

- Storyline id unique.
- At most one active main storyline.
- Chapter ids unique within storyline.
- Step ids unique within storyline.
- Step belongs to exactly one chapter.
- Scene link ids unique within storyline.
- Scene link chapterId references existing chapter.
- Scene link stepId, when present, references existing step.
- Outcome links reference existing scene links by containment.
- Outcome links reference known executable outcomes when scene is linked.
- SideQuest relationship references existing storyline ids.
- No localEventFlow auto-promotion.
- Graph generated only from persisted authoring data.
- Structure is source of truth.

## 16. Validation rules

Validation output concept:

```text
StorylineValidationIssue
  id
  severity
  targetRef
  ruleId
  message
```

Severity:

- `info`
- `warning`
- `error`
- `blocking`

Rules:

- empty title is blocking for activation;
- duplicate storyline id is blocking;
- duplicate active main is blocking;
- sideQuest without relationship is warning in draft, error when published to graph;
- chapter without title is error;
- empty chapter is warning;
- step without chapter is blocking;
- scene link without target is warning if placeholder, error if state is linked;
- outcome link references unknown outcome is error;
- relationship references missing storyline is blocking;
- legacy import missing step is warning/error depending loss severity.

## 17. Legacy migration strategy

Migration mode:

```text
legacy import preview
no destructive migration on load
```

Sources:

- `ScenarioAsset(scope == globalStory)`
- `GlobalStoryStudioDocument`
- `GlobalStoryChapter`
- `StepStudioDocument`
- `StepStudioStep`
- `ScenarioAsset.declaredOutcomes`
- `ScenarioAsset(scope == localEventFlow)`

Decisions:

- create `StorylineAsset` from old globalStory only through import preview;
- keep old `ScenarioAsset`;
- user confirms active main;
- if multiple globalStory exist, import candidates and require choice;
- if metadata missing/corrupt, create minimal storyline draft and validation issues;
- localEventFlow is offered only as explicit scene executable candidate, never sideQuest.

## 18. UI action to data mapping

Future actions:

- `Nouvelle storyline`: creates `StorylineCreationDraft`, then `StorylineAsset`.
- panel `+`: same command or scoped creation menu.
- create main storyline: creates `StorylineAsset(type: main)`.
- create side quest: creates `StorylineAsset(type: sideQuest)`.
- create chapter: appends `StorylineChapter`.
- create step: appends `StorylineStep` in chapter.
- create scene placeholder: appends `StorylineSceneLink(state: placeholder)`.
- Structure tab: edits `StorylineAsset`.
- Graph tab: reads generated graph from `StorylineAsset`.
- Validation UI: displays derived `StorylineValidationIssue`.

No V1-02 UI implementation.

## 19. Future tests strategy

Future test categories and likely names:

- model tests: `storyline_asset_model_test.dart`;
- JSON codec tests: `storyline_asset_json_test.dart`;
- ProjectManifest compatibility tests: `project_manifest_storylines_compatibility_test.dart`;
- legacy import tests: `storyline_legacy_global_story_import_test.dart`;
- validation tests: `storyline_validation_rules_test.dart`;
- projection tests: `narrative_workspace_projection_storyline_asset_test.dart`;
- UI widget tests: `storylines_structure_authoring_test.dart`;
- anti-fake tests: keep `localEventFlow` not sideQuest;
- non-mutation tests: creation drafts do not mutate until confirmed.

Required first tests in V1-03:

- old project JSON without `storylines` decodes to `[]`;
- `StorylineAsset` JSON roundtrip;
- duplicate active main validation;
- legacy globalStory import preview preserves source scenario.

## 20. Object data shape matrix

| Object | Fields | Required | Optional | Auto-generated | V1 initial | Notes |
|---|---|---|---|---|---|---|
| `StorylineAsset` | id, schemaVersion, type, status, title, description, sortOrder, locale, chapters, sceneLinks, relationships, legacySource, authorNotes, metadata | id, schemaVersion, type, status, title, chapters, sceneLinks | description, sortOrder, locale, relationships, legacySource, notes, metadata | id, schemaVersion, status, sortOrder | yes | authoring source |
| `StorylineChapter` | id, title, description, order, steps, directSceneLinkIds, status, authorNotes, metadata | id, title, order, steps | description, directSceneLinkIds, status, notes, metadata | id, order | yes | inline |
| `StorylineStep` | id, title, description, order, entryCondition, completionCondition, sceneLinkIds, expectedOutcomeIds, status, metadata | id, title, order, sceneLinkIds | conditions, outcomes, status, metadata | id, order | yes | inside chapter |
| `StorylineSceneLink` | id, chapterId, stepId, label, state, role, sceneRef, order, expectedOutcomeIds, outcomeLinks, metadata | id, chapterId, label, state, role, order, outcomeLinks | stepId, sceneRef, expectedOutcomeIds, metadata | id, order | yes | placeholder or linked scenario |
| `StorylineSceneOutcomeLink` | id, outcomeId, label, effects, notes, metadata | id, outcomeId, effects | label, notes, metadata | id | yes | effect mapping |
| `StorylineRelationship` | id, kind, sourceStorylineId, targetStorylineId, anchor, availability, condition, notes, metadata | id, kind, source, target | anchor, availability, condition, notes, metadata | id | later | side quest graph |
| `SideQuestAvailability` | startAnchor, endAnchor, availabilityCondition, expiresCondition, requiredOutcomeIds | startAnchor | endAnchor, conditions, outcomes | none | later | explicit availability |
| `StorylineValidationIssue` | id, severity, targetRef, ruleId, message | severity, targetRef, ruleId, message | id | id | yes | derived |
| `StorylineCreationDraft` | type, title, description, initialChapter | type, title | description, initialChapter | temp id | yes | transient |

## 21. Enum matrix

| Enum | Values | V1 initial values | Future values | Notes |
|---|---|---|---|---|
| `StorylineType` | main, sideQuest, tutorial, epilogue, episode, postGame, hiddenEvent | main, sideQuest | tutorial, epilogue, episode, postGame, hiddenEvent | future values hidden initially |
| `StorylineStatus` | draft, active, archived, disabled | draft, active, archived, disabled | maybe published later | authoring status only |
| `StorylineSceneLinkState` | placeholder, linkedScenario, needsImplementation, brokenLink | placeholder, linkedScenario, brokenLink | linkedScript, linkedDialogue, linkedCinematic, linkedBattle | start narrow |
| `StorylineSceneLinkRole` | primary, optional, setup, payoff, branch, convergence | primary, optional, branch, convergence | setup, payoff | graph semantics |
| `StorylineRelationshipKind` | sideQuestAvailableDuring, sideQuestUnlockedBy, sideQuestAffectsMain, convergesTo, requires, blocks | sideQuestAvailableDuring, sideQuestUnlockedBy | sideQuestAffectsMain, convergesTo, requires, blocks | later graph richness |
| `StorylineValidationSeverity` | info, warning, error, blocking | all | none | authoring feedback |
| `StorylineEffectType` | activateStep, completeStep, unlockStoryline, emitFact, setWorldRule, affectRelationship | activateStep, completeStep, unlockStoryline | emitFact, setWorldRule, affectRelationship | typed effects |

## 22. Invariant matrix

| Invariant | Level | Applies to | Enforcement point | Notes |
|---|---|---|---|---|
| Storyline id unique | MUST V1 initial | ProjectManifest.storylines | model validation | blocking |
| At most one active main | MUST V1 initial | Storylines list | validation + command | draft candidates allowed |
| Chapter ids unique | MUST V1 initial | StorylineAsset | validation | blocking |
| Step ids unique | MUST V1 initial | StorylineAsset | validation | blocking |
| Step belongs to one chapter | MUST V1 initial | Chapter/Step | model shape | no sharing initially |
| Scene link ids unique | MUST V1 initial | StorylineAsset | validation | blocking |
| Scene link chapter exists | MUST V1 initial | SceneLink | validation | blocking |
| Scene link step exists if set | MUST V1 initial | SceneLink | validation | blocking |
| Outcome links stay inside scene link | MUST V1 initial | SceneLink | model shape | containment |
| Linked scenario exists | SHOULD V1 | SceneLink | validation | warning/error |
| Linked outcome exists | SHOULD V1 | OutcomeLink | validation | error when linked |
| Side quest relation targets exist | SHOULD V1 | Relationship | validation | blocking when graph visible |
| No localEventFlow auto-promotion | MUST V1 initial | migration/import | importer | anti-fake |
| Graph generated from persisted authoring data | MUST V1 initial | UI/read model | projection | no fake graph |
| Structure is source of truth | MUST V1 initial | product model | commands | Graph later writes back |

## 23. Validation matrix

| Rule | Severity | Blocking? | V1 initial? | User-facing message |
|---|---|---|---|---|
| empty storyline title | blocking | yes | yes | "La storyline doit avoir un titre." |
| duplicate storyline id | blocking | yes | yes | "Une storyline utilise déjà cet identifiant." |
| duplicate active main storyline | blocking | yes | yes | "Une seule histoire principale peut être active." |
| sideQuest without relationship | warning | no in draft | yes | "Cette quête annexe n'est pas encore reliée à l'histoire principale." |
| chapter without title | error | yes for activation | yes | "Ce chapitre doit avoir un titre." |
| empty chapter | warning | no | yes | "Ce chapitre ne contient encore aucun jalon." |
| step without chapter | blocking | yes | yes | "Ce jalon doit appartenir à un chapitre." |
| scene link placeholder | info | no | yes | "Cette scène est encore un placeholder." |
| scene link linked but missing target | error | yes | yes | "La scène liée est introuvable." |
| outcome link references unknown outcome | error | yes for linked scene | yes | "Cet outcome n'existe pas dans la scène liée." |
| relationship references missing storyline | blocking | yes | yes | "La relation pointe vers une storyline introuvable." |
| legacy import missing step | warning | no | yes | "Un jalon référencé par l'ancien chapitre est introuvable." |
| localEventFlow proposed as sideQuest | blocking | yes | yes | "Un flow local ne peut pas devenir une quête annexe automatiquement." |

## 24. Migration matrix

| Legacy source | Target object | Migration mode | Destructive? | User review? | Notes |
|---|---|---|---|---|---|
| `ScenarioAsset.globalStory` | `StorylineAsset(type: main)` | import preview | no | yes | preserve scenario |
| multiple `globalStory` | active main candidate list | import preview | no | yes | user chooses |
| `GlobalStoryStudioDocument` | chapters | direct import | no | low | validation issues for corrupt docs |
| `GlobalStoryChapter` | `StorylineChapter` | direct import | no | low | preserve order |
| `StepStudioDocument` | steps | direct import | no | medium | outcome mapping checked |
| `StepStudioStep` | `StorylineStep` | direct import | no | medium | conditions summarized |
| `ScenarioAsset.declaredOutcomes` | outcome candidates | link/import | no | yes | needs scene link |
| `ScenarioAsset.localEventFlow` | scene executable candidate | explicit link only | no | yes | never sideQuest |
| missing metadata | minimal draft + validation issue | fallback | no | yes | honest degraded import |

## 25. UI action matrix

| UI action | Data object touched | Command needed later | Validation needed | V1 initial? |
|---|---|---|---|---|
| Nouvelle storyline | `StorylineCreationDraft`, `StorylineAsset` | createStoryline | title, duplicate id/type | yes |
| panel `+` | `StorylineCreationDraft` | openCreateStoryline | scoped action clarity | yes |
| create main storyline | `StorylineAsset(type: main)` | createMainStoryline | unique active main | yes |
| create side quest | `StorylineAsset(type: sideQuest)` | createSideQuest | title, relationship optional | yes |
| create chapter | `StorylineChapter` | addChapter | title/order | yes |
| create step | `StorylineStep` | addStep | chapter exists | yes |
| create scene placeholder | `StorylineSceneLink` | addScenePlaceholder | chapter/step exists | yes |
| link existing scenario | `StorylineSceneLink.sceneRef` | linkScenarioToScene | scenario exists/outcomes | yes |
| map outcome | `StorylineSceneOutcomeLink` | mapSceneOutcome | outcome exists/effects valid | yes |
| Structure edit | `StorylineAsset` | multiple authoring commands | invariants | yes |
| Graph view | generated read model | none or select | no mutation | yes |
| Validation view | derived issues | runValidation | model complete enough | later |

## 26. Recommended implementation lots

Recommended next path: Option 1.

```text
NS-STORYLINES-V1-03 — StorylineAsset Model V0
```

Why not a design gate:

- data shape is precise enough for first model implementation;
- remaining choices can be resolved as code-level constraints in V1-03 tests;
- UI creation should still wait until model + JSON + validation basics exist.

Suggested following lots:

- `NS-STORYLINES-V1-04 — Create Main Storyline Flow`
- `NS-STORYLINES-V1-05 — Create Side Quest Storyline Flow`
- `NS-STORYLINES-V1-06 — Storyline Type / Status / Validation`
- `NS-STORYLINES-V1-07 — Side Quest Graph Integration`
- `NS-STORYLINES-V1-08 — V1 Visual Graph Enrichment`

## 27. Roadmap update

Roadmap updated:

- `NS-STORYLINES-V1-02` marked DONE.
- Data shape decisions summarized.
- Risks recorded.
- Next lot set to `NS-STORYLINES-V1-03 — StorylineAsset Model V0`.
- V1 lot sequence shifted so model implementation precedes create flows.

## 28. Commands run

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
rg -n "StorylineAsset|ScenarioAsset executable|StorylineSceneLink|StorylineSceneOutcomeLink|Structure =|Graph =|V1-02|Data Shape|localEventFlow|ProjectManifest|storylines" reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md reports/narrativeStudio/storylines/road_map_storylines.md
rg -n "class ScenarioAsset|enum ScenarioScope|declaredOutcomes|activationCondition|metadata|class ProjectManifest|scenarios|class ScriptAsset|class ScriptCondition|ScriptConditionType|NarrativeChapterSummary|NarrativeStepSummary|GlobalStoryStudioDocument|StepStudioDocument|localEventFlows" packages/map_core/lib/src/models/scenario_asset.dart packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/models/script_asset.dart packages/map_core/lib/src/models/script_conditions.dart packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
test -f reports/narrativeStudio/storylines/ns_storylines_v1_02_storyline_authoring_data_shape_contract.md && echo exists || echo missing
```

Roadmap diff:

```text
git diff -- reports/narrativeStudio/storylines/road_map_storylines.md
git diff --stat
git diff --name-only
git diff --check
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

## 29. Evidence Pack

Git branch initiale:

```text
main
```

Git status initial exact:

```text
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md
```

Git diff --stat initial:

```text
 .../storylines/road_map_storylines.md              | 56 +++++++++++++++++-----
 1 file changed, 44 insertions(+), 12 deletions(-)
```

Git diff --name-only initial:

```text
reports/narrativeStudio/storylines/road_map_storylines.md
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
?? reports/narrativeStudio/storylines/ns_storylines_v1_02_storyline_authoring_data_shape_contract.md
```

Git diff --stat final:

```text
 .../storylines/road_map_storylines.md              | 50 ++++++++++++++++------
 1 file changed, 38 insertions(+), 12 deletions(-)
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
index 8957ab9f..c16ec040 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -303,7 +303,8 @@ Interprétation V0 :
 | NS-STORYLINES-CHECKPOINT | Storylines V0 Acceptance Checkpoint | checkpoint | DONE | NS-STORYLINES-V1-00 |
 | NS-STORYLINES-V1-00 | Storyline Semantics Reset / Usable Authoring Contract | product contract | DONE | NS-STORYLINES-V1-01 |
 | NS-STORYLINES-V1-01 | Storyline Authoring Model Decision | model decision | DONE | NS-STORYLINES-V1-02 |
-| NS-STORYLINES-V1-02 | Storyline Authoring Data Shape Contract | data contract | TODO | NS-STORYLINES-V1-03 |
+| NS-STORYLINES-V1-02 | Storyline Authoring Data Shape Contract | data contract | DONE | NS-STORYLINES-V1-03 |
+| NS-STORYLINES-V1-03 | StorylineAsset Model V0 | core model | TODO | NS-STORYLINES-V1-04 |
 
 ## 9. Detailed lots
 
@@ -642,11 +643,24 @@ Interprétation V0 :
 
 - Type : data-contract / architecture.
 - Objectif : transformer la décision V1-01 en contrat de données précis avant implémentation.
-- Résultat attendu : champs, enums, invariants, validation rules, migration plan et tests futurs pour le modèle `StorylineAsset`.
+- Résultat : data shape conceptuelle livrée pour `StorylineAsset`, enums, chapters, steps, scene links, outcome links, relationships, conditions/effects, JSON, invariants, validations, migration legacy et tests futurs.
+- Décisions majeures : `ProjectManifest.storylines: List<StorylineAsset>` futur avec `[]` par défaut ; chapters/steps/scene links inline dans `StorylineAsset`; outcome links au niveau scene link ; relationships au niveau projet recommandé plus tard ; legacy import preview non destructif.
+- Risques : schéma JSON à implémenter avec compatibilité vieux projets ; wrappers no-code au-dessus de `ScriptCondition` à préciser en code ; relation side quest disponible mais UI de création encore future.
+- Fichiers créés/modifiés : `reports/narrativeStudio/storylines/ns_storylines_v1_02_storyline_authoring_data_shape_contract.md`, `reports/narrativeStudio/storylines/road_map_storylines.md`.
+- Tests exécutés : aucun, lot documentation-only.
+- Analyse exécutée : aucune, lot documentation-only.
 - Non-objectifs : pas d'UI de création avant contrat data shape.
 - Dépendances : NS-STORYLINES-V1-01.
+- Statut : DONE.
+- Prochain lot attendu : NS-STORYLINES-V1-03 — StorylineAsset Model V0.
+
+### NS-STORYLINES-V1-03 — StorylineAsset Model V0
+
+- Type : core model / tests.
+- Objectif : implémenter le modèle `StorylineAsset` V0, codecs JSON, compatibilité `ProjectManifest.storylines`, invariants de base et tests de migration/import legacy.
+- Dépendances : NS-STORYLINES-V1-02.
 - Statut : TODO.
-- Prochain lot attendu : NS-STORYLINES-V1-03.
+- Prochain lot attendu : NS-STORYLINES-V1-04.
 
 ## 10. Update protocol for every future lot
 
@@ -764,10 +778,10 @@ Décision temporaire :
 ## 13. Current status
 
 ```text
-Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 MODEL DECISION DONE
-Current lot: NS-STORYLINES-V1-01
+Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 DATA SHAPE CONTRACT DONE
+Current lot: NS-STORYLINES-V1-02
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract
+Next recommended lot: NS-STORYLINES-V1-03 — StorylineAsset Model V0
 ```
 
 | Lot | Status | Last update | Notes |
@@ -788,7 +802,8 @@ Next recommended lot: NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Con
 | NS-STORYLINES-CHECKPOINT | DONE | 2026-05-28 | Storylines V0 acceptance checkpoint livré : ACCEPTED V0 WITH V1 LIMITATIONS ; prochaine phase recommandée V1 semantic/product contract. |
 | NS-STORYLINES-V1-00 | DONE | 2026-05-28 | Reset sémantique produit livré : Storylines V0 techniquement valide, V1 doit clarifier et rendre utilisables Storyline / Chapter / Story Step / Scene / Graph / Structure. |
 | NS-STORYLINES-V1-01 | DONE | 2026-05-28 | Modèle hybride retenu : `StorylineAsset` authoring + `ScenarioAsset` executable scene flow ; Structure source d'authoring, Graph généré. |
-| NS-STORYLINES-V1-02 | TODO | 2026-05-28 | Storyline Authoring Data Shape Contract. |
+| NS-STORYLINES-V1-02 | DONE | 2026-05-28 | Contrat data shape `StorylineAsset` livré : champs, enums, invariants, validations, JSON, migration legacy, UI actions et tests futurs. |
+| NS-STORYLINES-V1-03 | TODO | 2026-05-28 | StorylineAsset Model V0. |
 
 ## 14. V1 Creation Readiness Notes
 
@@ -811,14 +826,25 @@ Suite V1 documentaire recommandée :
 - `NS-STORYLINES-V1-00 — Storyline Semantics Reset / Usable Authoring Contract`
 - `NS-STORYLINES-V1-01 — Storyline Authoring Model Decision`
 - `NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract`
-- `NS-STORYLINES-V1-03 — Create Main Storyline Flow`
-- `NS-STORYLINES-V1-04 — Create Side Quest Storyline Flow`
-- `NS-STORYLINES-V1-05 — Storyline Type / Status / Validation`
-- `NS-STORYLINES-V1-06 — Side Quest Graph Integration`
-- `NS-STORYLINES-V1-07 — V1 Visual Graph Enrichment`
+- `NS-STORYLINES-V1-03 — StorylineAsset Model V0`
+- `NS-STORYLINES-V1-04 — Create Main Storyline Flow`
+- `NS-STORYLINES-V1-05 — Create Side Quest Storyline Flow`
+- `NS-STORYLINES-V1-06 — Storyline Type / Status / Validation`
+- `NS-STORYLINES-V1-07 — Side Quest Graph Integration`
+- `NS-STORYLINES-V1-08 — V1 Visual Graph Enrichment`
 
 ## 15. Changelog
 
+### 2026-05-28 — NS-STORYLINES-V1-02
+
+- Contrat de données Storylines V1 livré.
+- Data shape conceptuelle définie pour `StorylineAsset`, `StorylineType`, `StorylineStatus`, chapters, steps, scene links, outcome links, relationships, availability et validation issues.
+- Décision : `StorylineAsset` stockera chapters/steps/scene links inline ; `ProjectManifest.storylines` futur devra décoder les vieux projets en `[]`.
+- Décision : `StorylineSceneLink` V1 initial démarre avec `placeholder` et `linkedScenario`; dialogue/cinematic/battle restent dans le `ScenarioAsset` exécutable.
+- Décision : outcome links V1 initial activent/complètent des `StorylineStep`; facts/world rules réservés à plus tard.
+- Migration : legacy import preview non destructif depuis `ScenarioAsset.globalStory`; `localEventFlow` jamais promu automatiquement.
+- Prochain lot recommandé : `NS-STORYLINES-V1-03 — StorylineAsset Model V0`.
+
 ### 2026-05-28 — NS-STORYLINES-V1-01
 
 - Décision d'architecture Storylines V1 livrée.
```

Contenu complet du rapport créé:

```text
Le contenu complet du rapport créé est le présent document, du titre "# NS-STORYLINES-V1-02 — Storyline Authoring Data Shape Contract" jusqu'à la section "## 30. Self-review".
```

Justification de l'absence de tests Flutter:

```text
Lot documentation-only. Aucun code Dart, test, widget, modèle ou screenshot modifié.
```

Auto-review critique:

```text
- Le contrat est assez précis pour V1-03, mais les wrappers condition/effect devront être codés avec prudence.
- `ProjectManifest.storylines` est recommandé, mais pas implémenté ici.
- `StorylineRelationship` reste probablement à stabiliser quand le graph side quest sera codé.
- Les imports legacy doivent rester non destructifs jusqu'à preuve par tests.
- Le rapport V1-01 était untracked au début du lot mais n'apparaît plus dans le status final; aucune commande Git write n'a été exécutée dans ce lot.
```

## 30. Self-review

Criteria reviewed:

- Aucun code modifié: yes.
- Aucun test modifié: yes.
- Aucun screenshot modifié: yes.
- `StorylineAsset` conceptually defined: yes.
- `StorylineType` defined: yes.
- `StorylineStatus` defined: yes.
- `StorylineChapter` defined: yes.
- `StorylineStep` defined: yes.
- `StorylineSceneLink` defined: yes.
- `StorylineSceneOutcomeLink` defined: yes.
- `StorylineRelationship` / `SideQuestAvailability` defined: yes.
- Conditions/effects strategy clarified: yes.
- JSON / ProjectManifest strategy clarified: yes.
- Invariants listed: yes.
- Validation rules listed: yes.
- Legacy migration clarified: yes.
- UI actions mapped: yes.
- Future tests listed: yes.
- Roadmap updated: yes.
- Next lot recommended: yes, V1-03 `StorylineAsset Model V0`.
- `git diff --check` clean: yes.
