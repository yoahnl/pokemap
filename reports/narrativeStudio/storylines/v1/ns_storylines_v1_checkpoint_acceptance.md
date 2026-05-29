# NS-STORYLINES-V1-CHECKPOINT — Storylines V1 Acceptance Checkpoint

## 1. Executive summary

Verdict: `ACCEPTED WITH LIMITATIONS`.

Storylines V1 is acceptable as an initial authoring workshop: it has a pure authoring model, JSON persistence, `ProjectManifest.storylines`, legacy preview without automatic migration, main storyline creation, sideQuest creation, chapter/step authoring, read-only graph rendering, explicit sideQuest attachment, and visual graph polish.

The limitations are real but mostly outside the V1 acceptance boundary: no scene placeholders, no scene links, no outcome branches, no facts/world rules, no global narrative validator, no applied legacy import, no runtime execution, and no edit/delete/reorder flow. Evidence also has a repository artifact gap: V1-00 through V1-11 reports and V1-07 through V1-11 screenshots are absent from the current tree, while the implemented code/tests and V1-12 artifacts are present.

Recommended next phase: `NS-SCENES-V1 — Scene Placeholder + Scene Linking Foundation`.

## 2. Inputs read

Governance inputs read:

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`

Storylines V1 reports inventory:

- Present: `reports/narrativeStudio/storylines/ns_storylines_v1_12_visual_graph_enrichment.md`
- Absent: `reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md`
- Absent: `reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md`
- Absent: `reports/narrativeStudio/storylines/ns_storylines_v1_02_storyline_authoring_data_shape_contract.md`
- Absent: `reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md`
- Absent: `reports/narrativeStudio/storylines/ns_storylines_v1_04_storyline_asset_json_codec_v0.md`
- Absent: `reports/narrativeStudio/storylines/ns_storylines_v1_05_project_manifest_storylines_integration_v0.md`
- Absent: `reports/narrativeStudio/storylines/ns_storylines_v1_06_legacy_global_story_import_preview_v0.md`
- Absent: `reports/narrativeStudio/storylines/ns_storylines_v1_07_create_main_storyline_flow_v0.md`
- Absent: `reports/narrativeStudio/storylines/ns_storylines_v1_07_bis_storylines_workspace_cleanup.md`
- Absent: `reports/narrativeStudio/storylines/ns_storylines_v1_08_structure_tab_authoring_v0.md`
- Absent: `reports/narrativeStudio/storylines/ns_storylines_v1_09_create_side_quest_flow_v0.md`
- Absent: `reports/narrativeStudio/storylines/ns_storylines_v1_10_graph_from_storyline_asset_v0.md`
- Absent: `reports/narrativeStudio/storylines/ns_storylines_v1_11_side_quest_attachment_graph_integration_v0.md`

Core/editor code and tests read:

- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/authoring/storyline_legacy_import_preview.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart`
- `packages/map_core/test/storyline_asset_test.dart`
- `packages/map_core/test/storyline_asset_json_test.dart`
- `packages/map_core/test/project_manifest_storylines_test.dart`
- `packages/map_core/test/storyline_legacy_import_preview_test.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`
- `packages/map_editor/test/narrative_workspace_projection_test.dart`

## 3. Scope reviewed

The checkpoint reviewed Storylines V1 as an authoring workspace, not as a complete Narrative Studio runtime pipeline.

In scope:

- authoring model and invariants;
- JSON codec;
- manifest storage;
- legacy globalStory preview;
- main and sideQuest creation;
- chapter and story step authoring;
- read-only graph rendering from `StorylineAsset`;
- explicit sideQuest attachment;
- graph display of attached sideQuests;
- visual polish and guardrails.

Out of scope for acceptance:

- scene authoring;
- scene linking;
- runtime execution;
- outcome branches;
- facts/world rules;
- narrative validation beyond current model/test guardrails.

## 4. Feature acceptance matrix

| Feature | Expected V1 behavior | Evidence | Status | Notes |
|---|---|---|---|---|
| StorylineAsset model | Pure authoring model with storylines, chapters, steps, links, relationships, validation issues, legacy source. | `storyline_asset.dart`, `storyline_asset_test.dart` passed. | PASS | Model includes relationship and sideQuest availability types. |
| JSON codec | Manual stable `toJson` / `fromJson`; enums as strings; constructors validate decoded data. | `storyline_asset_json_test.dart` passed. | PASS | ScriptCondition codec is used through the existing model path. |
| ProjectManifest.storylines | Non-null `List<StorylineAsset>` with default `[]`, old JSON compatibility, no automatic legacy import. | `project_manifest.dart`, `project_manifest_storylines_test.dart` passed. | PASS | Manifest JSON stores storylines explicitly. |
| Legacy import preview | Pure preview from `ScenarioAsset(scope == globalStory)`, no mutation, localEventFlow ignored. | `storyline_legacy_import_preview.dart`, `storyline_legacy_import_preview_test.dart` passed. | PASS | Preview creates candidates only. |
| Create main storyline | UI creates one `StorylineAsset(type: main, status: draft)` and prevents a second main. | `storylines_workspace_shell_test.dart` passed. | PASS | Mutation goes through editor notifier and `ProjectManifest.storylines`. |
| Create sideQuest | UI creates `StorylineAsset(type: sideQuest, status: draft)` after main exists. | `storylines_workspace_shell_test.dart` passed. | PASS | SideQuest is real authoring data, not localEventFlow promotion. |
| Create chapter | Structure creates ordered chapters with stable IDs and selection. | `storylines_workspace_shell_test.dart` passed. | PASS | Chapter order and ID collision behavior are tested. |
| Create story step | Structure creates ordered steps in selected chapter with unique IDs. | `storylines_workspace_shell_test.dart` passed. | PASS | Step IDs are unique at storyline scale. |
| Graph from StorylineAsset | Graph is generated from the selected `StorylineAsset` and shows real chapters/steps. | `storylines_graph_model.dart`, graph tests in `storylines_workspace_shell_test.dart`. | PASS | Graph source is V1 storylines, not legacy scenarios. |
| SideQuest attachment | User explicitly attaches sideQuest to main chapter/step; relationship stored on sideQuest. | `storylines_workspace.dart`, attachment tests passed. | PASS | Uses `StorylineRelationship(kind: sideQuestAvailableDuring)` and `SideQuestAvailability.startAnchor`. |
| SideQuest graph integration | Attached sideQuest appears in main graph; unattached sideQuest does not. | `storylines_graph_model.dart`, `storylines_graph_view.dart`, tests passed. | PASS | Main graph integration is relation-driven. |
| Visual graph enrichment | Graph has clearer hierarchy, edge semantics, legend, sideQuest treatment. | V1-12 report and screenshots present; tests/analyze pass. | PASS WITH EVIDENCE LIMITATION | Earlier visual artifacts V1-07 to V1-11 are absent. |

## 5. Guardrail matrix

| Guardrail | Evidence | Status | Notes |
|---|---|---|---|
| no fake target data | Anti-fake `rg` found target strings only in negative tests, generated/model `ActiveEventPage`, and a legacy sidebar label. | PASS WITH CONTEXT | No Storylines V1 fake project data was found in the Storylines workspace/graph. |
| no localEventFlow promotion | Tests and code emit/expect `localEventFlowIgnored`; no sideQuest creation from localEventFlow. | PASS | localEventFlow appears only as exclusion evidence. |
| no automatic legacy import | Manifest tests and UI tests assert no automatic import. | PASS | Legacy preview remains non-destructive. |
| no map_core mutation after V1 core lots | Checkpoint changed no `packages/map_core` files. | PASS | Core tests were run read-only. |
| no runtime/gameplay/battle mutation | Checkpoint changed no runtime/gameplay/battle files. | PASS | No such paths in final diff. |
| no hardcoded colors | Anti-color `rg` returned empty output. | PASS | `Color(0x...)` / `Colors.*` absent in checked Storylines files/tests. |
| design system primitives | Code uses the existing editor primitives and theme tokens; analyze passed. | PASS | Graph painter receives colors from the view/theme path. |
| two sidebar separation | Tests and prior code distinguish Narrative Studio shell from global Project Explorer. | PASS | `Maps` is asserted absent from the internal Storylines shell. |
| Maps absent from internal sidebar | `rg "Maps"` only found the Storylines test assertion. | PASS | No product UI hit in `storylines_workspace.dart`. |
| Graph read-only | Tests cover no graph mutation; graph UI labels read-only behavior. | PASS | Graph creates no chapters/steps/relationships/sceneLinks. |
| Structure source-of-authoring | Chapter and step creation live in Structure flows. | PASS | Graph remains generated view. |

## 6. Test matrix

| Command | Result | Blocking? | Notes |
|---|---|---|---|
| `cd packages/map_core && dart test --reporter=compact test/storyline_asset_test.dart` | `All tests passed!` | No | Model and invariants. |
| `cd packages/map_core && dart test --reporter=compact test/storyline_asset_json_test.dart` | `All tests passed!` | No | Codec roundtrip/default/invalid JSON. |
| `cd packages/map_core && dart test --reporter=compact test/project_manifest_storylines_test.dart` | `All tests passed!` | No | Manifest storylines compatibility. |
| `cd packages/map_core && dart test --reporter=compact test/storyline_legacy_import_preview_test.dart` | `All tests passed!` | No | Legacy preview/no mutation/localEventFlow exclusion. |
| `cd packages/map_core && dart test --reporter=compact` | `All tests passed!` | No | Full map_core test suite. |
| `cd packages/map_core && dart test --reporter=json \| tail -n 1` | `{"success":true,"type":"done","time":4910}` | No | Exact final JSON event for full map_core suite. |
| `cd packages/map_editor && flutter test --reporter=compact test/storylines_workspace_shell_test.dart` | `All tests passed!` | No | Storylines UI flows and graph/guardrails. |
| `cd packages/map_editor && flutter test --reporter=compact test/storylines_current_global_story_characterization_test.dart` | `All tests passed!` | No | Legacy characterization remains stable. |
| `cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart` | `All tests passed!` | No | Narrative projection regression. |
| `cd packages/map_core && dart analyze ...` | `No issues found!` | No | Targeted core analysis. |
| `cd packages/map_editor && flutter analyze --no-fatal-infos ...` | `No issues found! (ran in 1.5s)` | No | Targeted editor analysis. |
| `rg "Color\(0x\|Colors\." ...` | Sortie : `<vide>` | No | Design color gate clean. |
| Anti-fake `rg` | Contextual hits only. | No | Negative test list, generated `ActiveEventPage`, and legacy sidebar label. |
| `rg "Maps" ...` | Test assertion only. | No | Internal Storylines UI keeps Maps absent. |
| `rg "localEventFlow" ...` | Exclusion code/tests only. | No | No promotion path found. |

## 7. Visual Gate matrix

| Screenshot group | Present | Useful | Notes |
|---|---:|---|---|
| V1-07 create main flow | 0/4 | No current artifact | Expected files are absent. |
| V1-08 Structure authoring | 0/4 | No current artifact | Expected files are absent. |
| V1-09 sideQuest flow | 0/4 | No current artifact | Expected files are absent. |
| V1-10 graph from asset | 0/4 | No current artifact | Expected files are absent. |
| V1-11 sideQuest attachment graph | 0/4 | No current artifact | Expected files are absent. |
| V1-12 visual graph enrichment | 4/4 | Yes | Present: empty, main polished, attached sideQuest polished, standalone sideQuest polished. Ahem/font limitation remains acceptable for structural screenshots. |

## 8. Storyline authoring assessment

Storyline authoring is acceptable for V1.

Evidence indicates:

- main storyline creation exists and is tested;
- second main creation is prevented;
- sideQuest creation exists and is tested;
- sideQuest creation respects the documented main-first rule;
- IDs are slugified and collision-safe;
- mutations are performed via `ProjectManifest.storylines` and editor notifier pathways;
- no direct list mutation was found in the focused evidence search.

Remaining limits are expected V2/editor refinements: editing, deleting, duplicating, and reordering storylines are not part of this V1 checkpoint.

## 9. Structure authoring assessment

Structure authoring is acceptable for V1.

Evidence indicates:

- a chapter can be created from Structure;
- a story step can be created inside a selected chapter;
- chapter order is stable and tested;
- step order is stable and tested;
- step IDs are collision-safe at storyline scope;
- Structure remains the authoring surface for chapters/steps;
- graph rendering does not create structure data.

Remaining limits are acceptable: no drag/drop, no reorder UI, no edit/delete flows, no scene linking.

## 10. Graph assessment

Graph behavior is acceptable for V1 as a read-only comprehension view.

Evidence indicates:

- graph is generated from selected `StorylineAsset`;
- main story graph shows chapters and steps;
- chapter/step ordering is model-driven;
- sideQuest graph is autonomous when a sideQuest is selected;
- sideQuest appears in the main graph only through explicit relationship data;
- author-order edges and sideQuest availability edges are distinct in the graph model/painter/view;
- graph remains read-only and creates no data.

Remaining graph limitations are acceptable: no graph editing, no drag/drop, no runtime branch semantics, no outcomes, no zoom/minimap functionality.

## 11. SideQuest assessment

SideQuest support is acceptable for V1.

Evidence indicates:

- sideQuest creation creates `StorylineAsset(type: sideQuest, status: draft)`;
- sideQuest Structure authoring reuses the same chapter/step path;
- explicit attachment creates a `StorylineRelationship(kind: sideQuestAvailableDuring)` with `SideQuestAvailability.startAnchor`;
- anchors can target a chapter or step;
- unattached sideQuests remain out of the main graph;
- attached sideQuests appear in the main graph through the explicit relation;
- no sceneLink, outcome, fact, or world rule is created by attachment.

The availability model is intentionally minimal and acceptable for V1.

## 12. Legacy / migration assessment

Legacy handling is acceptable for V1.

Evidence indicates:

- `buildLegacyGlobalStoryImportPreview(ProjectManifest)` exists;
- preview scans `ScenarioAsset(scope == globalStory)`;
- preview creates import candidates without mutating the manifest;
- old projects without `storylines` decode with `storylines == []`;
- no automatic application/import was found;
- `localEventFlow` is explicitly ignored and diagnosed as `localEventFlowIgnored`.

Applied legacy import remains a future phase, not a V1 acceptance blocker.

## 13. Anti-fake assessment

Anti-fake status: acceptable with contextual hits documented.

The anti-fake search found:

- expected negative assertions in `packages/map_editor/test/storylines_workspace_shell_test.dart`;
- `ActiveEventPage` hits in map core generated/model files because the search includes the broad term `Active`;
- one legacy navigation label hit for `Histoire globale` in the broader Narrative Studio canvas, outside the V1 Storylines workspace data flow.

No evidence was found that Storylines V1 hardcodes target project names, fake counts, fake branches, fake sideQuests, or fake narrative data as product content.

## 14. Design System assessment

Design System status: acceptable.

The anti-color command returned empty output for:

```bash
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines packages/map_editor/test/storylines_workspace_shell_test.dart
```

Graph painter code uses `Color` typed values passed from the view/theme layer, not hardcoded `Color(0x...)` or `Colors.*` constants in the checked paths.

## 15. Architecture / maintainability assessment

Architecture is acceptable for a V1 checkpoint.

Strong points:

- `map_core` owns pure models, JSON, manifest storage, and legacy preview;
- `map_editor` owns authoring UI and graph view models;
- graph feature files are separated from the main workspace file;
- Structure remains the mutation surface for chapters/steps;
- graph remains generated/read-only;
- sideQuest attachment is explicit and relationship-backed.

Risks:

- historical V1 report/screenshot artifacts are missing for V1-00 through V1-11;
- editor test file remains broad, though targeted coverage is strong;
- future scene linking should avoid overloading `storylines_workspace.dart`.

## 16. Limitations matrix

| Limitation | Impact | Acceptable for V1? | Follow-up phase |
|---|---|---|---|
| pas encore de scene placeholder | Steps cannot point to authorable scenes yet. | Yes | `NS-SCENES-V1` |
| pas encore de sceneLink | Story graph cannot bridge to executable scene flow. | Yes | `NS-SCENES-V1` |
| pas encore de Scene Outcome branch | No outcome-driven branching authoring. | Yes | Storylines V2 / Scenes outcomes |
| pas encore de facts/world rules | No narrative condition layer yet. | Yes | Validator / Rules phase |
| pas encore de validation narrative globale | Cross-story diagnostics remain limited. | Yes | `NS-VALIDATOR-V1` |
| pas encore de drag/drop / reorder | Ordering exists by model but not ergonomic. | Yes | Storylines V2 |
| pas encore de delete/edit | Created data cannot be managed fully in UI. | Yes | Storylines V2 |
| pas encore d'import legacy appliqué | Legacy preview exists but no apply flow. | Yes | Legacy import apply phase |
| pas encore de runtime execution | Authoring does not drive runtime story execution yet. | Yes | Runtime integration after scenes |
| graph pas encore éditable | Graph is comprehension only. | Yes | Later graph editor phase |
| sideQuest availability limitée | Only minimal start anchor is supported. | Yes | SideQuest V2 / validator |
| UI encore Ahem dans screenshots | Visual QA is structural rather than typography-final. | Yes | Visual QA refinement |

## 17. Open issues

1. V1-00 through V1-11 reports are absent from the current tree.
2. V1-07 through V1-11 screenshots are absent from the current tree.
3. Storylines still lacks scene placeholder and sceneLink authoring.
4. Storylines still lacks outcomes, facts/world rules, and global narrative validation.
5. Storylines still lacks edit/delete/reorder ergonomics.

None of these issues require rejecting V1 as an initial authoring workshop.

## 18. Recommended next phase

Recommended next phase:

```text
NS-SCENES-V1 — Scene Placeholder + Scene Linking Foundation
```

Rationale: Storylines can now create the narrative skeleton, sideQuests, attachments, and read-only graph. The biggest product gap is the connection between story steps and scenes. Scene placeholder + scene linking is the natural next foundation before deeper outcomes, validation, or runtime story execution.

Alternative later phases:

- `NS-VALIDATOR-V1` for narrative consistency checks;
- `NS-STORYLINES-V2` for edit/delete/reorder/sceneLink/outcome ergonomics.

## 19. Verdict

`ACCEPTED WITH LIMITATIONS`

Storylines V1 is closed as a usable initial authoring workshop.

The verdict is not plain `ACCEPTED` because the historical reports/screenshots for earlier V1 lots are missing from the current tree, and the product intentionally stops before scene links, outcomes, facts/world rules, validation, and runtime execution.

The verdict is not `NEEDS BIS` because targeted tests, full map_core tests, targeted analyses, design/color checks, and guardrail searches all passed, and the remaining gaps are scoped follow-up phases rather than regressions in the V1 acceptance surface.

## 20. Roadmap update

`reports/narrativeStudio/storylines/road_map_storylines.md` was updated:

- `NS-STORYLINES-V1-CHECKPOINT` marked `DONE`;
- verdict recorded as `ACCEPTED WITH LIMITATIONS`;
- Storylines V1 marked closed as an initial authoring workshop;
- next recommended phase set to `NS-SCENES-V1 — Scene Placeholder + Scene Linking Foundation`.

## 21. Commands run

```bash
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --check
```

```bash
cd packages/map_core && dart test --reporter=compact test/storyline_asset_test.dart
cd packages/map_core && dart test --reporter=compact test/storyline_asset_json_test.dart
cd packages/map_core && dart test --reporter=compact test/project_manifest_storylines_test.dart
cd packages/map_core && dart test --reporter=compact test/storyline_legacy_import_preview_test.dart
cd packages/map_core && dart test --reporter=compact
cd packages/map_core && dart test --reporter=json | tail -n 1
```

```bash
cd packages/map_editor && flutter test --reporter=compact test/storylines_workspace_shell_test.dart
cd packages/map_editor && flutter test --reporter=compact test/storylines_current_global_story_characterization_test.dart
cd packages/map_editor && flutter test --reporter=compact test/narrative_workspace_projection_test.dart
```

```bash
cd packages/map_core && dart analyze lib/src/models/storyline_asset.dart lib/src/models/project_manifest.dart lib/src/authoring/storyline_legacy_import_preview.dart test/storyline_asset_test.dart test/storyline_asset_json_test.dart test/project_manifest_storylines_test.dart test/storyline_legacy_import_preview_test.dart
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/storylines_workspace.dart lib/src/ui/canvas/storylines/storylines_graph_model.dart lib/src/ui/canvas/storylines/storylines_graph_painter.dart lib/src/ui/canvas/storylines/storylines_graph_view.dart test/storylines_workspace_shell_test.dart test/storylines_current_global_story_characterization_test.dart test/narrative_workspace_projection_test.dart
```

```bash
rg "Color\(0x|Colors\." packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines packages/map_editor/test/storylines_workspace_shell_test.dart
rg "Histoire globale|La brume du phare|Le port|Les marais|Le phare|Les cristaux de sel|Le Goélise du port|La cabane du phare|Mystère|Exploration|Phare|Côtiers|5 chapitres|27 scènes|412 dialogues|18 facts|3 problèmes|Active|Haute|Validé|Défini|En cours" packages/map_editor/lib/src/ui/canvas packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_core/lib packages/map_core/test
rg "Maps" packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/test/storylines_workspace_shell_test.dart
rg "localEventFlow" packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart packages/map_editor/lib/src/ui/canvas/storylines packages/map_editor/test/storylines_workspace_shell_test.dart packages/map_core/lib/src/authoring/storyline_legacy_import_preview.dart packages/map_core/test/storyline_legacy_import_preview_test.dart
```

## 22. Evidence Pack

### Git branch initiale

```text
main
```

### Git status initial exact

```text
Sortie : <vide>
```

### Git diff --stat initial

```text
Sortie : <vide>
```

### Git diff --name-only initial

```text
Sortie : <vide>
```

### Git diff --check initial

```text
Sortie : <vide>
```

### Rapports V1 présents

```text
PRESENT reports/narrativeStudio/storylines/ns_storylines_v1_12_visual_graph_enrichment.md
```

### Rapports V1 absents

```text
MISSING reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md
MISSING reports/narrativeStudio/storylines/ns_storylines_v1_01_storyline_authoring_model_decision.md
MISSING reports/narrativeStudio/storylines/ns_storylines_v1_02_storyline_authoring_data_shape_contract.md
MISSING reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md
MISSING reports/narrativeStudio/storylines/ns_storylines_v1_04_storyline_asset_json_codec_v0.md
MISSING reports/narrativeStudio/storylines/ns_storylines_v1_05_project_manifest_storylines_integration_v0.md
MISSING reports/narrativeStudio/storylines/ns_storylines_v1_06_legacy_global_story_import_preview_v0.md
MISSING reports/narrativeStudio/storylines/ns_storylines_v1_07_create_main_storyline_flow_v0.md
MISSING reports/narrativeStudio/storylines/ns_storylines_v1_07_bis_storylines_workspace_cleanup.md
MISSING reports/narrativeStudio/storylines/ns_storylines_v1_08_structure_tab_authoring_v0.md
MISSING reports/narrativeStudio/storylines/ns_storylines_v1_09_create_side_quest_flow_v0.md
MISSING reports/narrativeStudio/storylines/ns_storylines_v1_10_graph_from_storyline_asset_v0.md
MISSING reports/narrativeStudio/storylines/ns_storylines_v1_11_side_quest_attachment_graph_integration_v0.md
```

### Fichiers core/editor lus

```text
PRESENT packages/map_core/lib/src/models/storyline_asset.dart
PRESENT packages/map_core/lib/src/models/project_manifest.dart
PRESENT packages/map_core/lib/src/authoring/storyline_legacy_import_preview.dart
PRESENT packages/map_core/lib/map_core.dart
PRESENT packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
PRESENT packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart
PRESENT packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart
PRESENT packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
PRESENT packages/map_core/test/storyline_asset_test.dart
PRESENT packages/map_core/test/storyline_asset_json_test.dart
PRESENT packages/map_core/test/project_manifest_storylines_test.dart
PRESENT packages/map_core/test/storyline_legacy_import_preview_test.dart
PRESENT packages/map_editor/test/storylines_workspace_shell_test.dart
PRESENT packages/map_editor/test/storylines_current_global_story_characterization_test.dart
PRESENT packages/map_editor/test/narrative_workspace_projection_test.dart
```

### Résultats tests/analyze/rg

```text
map_core storyline_asset_test: All tests passed!
map_core storyline_asset_json_test: All tests passed!
map_core project_manifest_storylines_test: All tests passed!
map_core storyline_legacy_import_preview_test: All tests passed!
map_core full dart test: All tests passed!
map_core full dart test final JSON event: {"success":true,"type":"done","time":4910}
map_editor storylines_workspace_shell_test: All tests passed!
map_editor storylines_current_global_story_characterization_test: All tests passed!
map_editor narrative_workspace_projection_test: All tests passed!
map_core targeted analyze: No issues found!
map_editor targeted analyze: No issues found! (ran in 1.5s)
rg anti-colors: Sortie : <vide>
rg anti-fake: contextual hits only; negative tests, ActiveEventPage generated/model names, legacy sidebar label.
rg Maps: Storylines test assertion only.
rg localEventFlow: exclusion code/tests only.
```

### Inventaire screenshots Visual Gate

```text
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_empty_storylines_desktop.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_create_main_dialog.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_created_main_graph.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_07_created_main_structure.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_structure_empty.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_create_chapter_dialog.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_created_chapter.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_08_created_step.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_09_create_side_quest_dialog.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_09_created_side_quest_graph.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_09_created_side_quest_structure.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_09_storyline_list_with_side_quest.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_10_graph_empty_storyline.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_10_graph_main_chapters_steps.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_10_graph_sidequest_standalone.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_10_graph_main_ignores_sidequest.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_11_attach_side_quest_dialog.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_11_attached_main_graph.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_11_attached_sidequest_structure.png
MISSING reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_11_unattached_sidequest_hidden_from_main_graph.png
PRESENT reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_empty_polished.png
PRESENT reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_main_polished.png
PRESENT reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_sidequest_attached_polished.png
PRESENT reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_12_graph_sidequest_standalone_polished.png
```

### Diff complet de road_map_storylines.md

```diff
diff --git a/reports/narrativeStudio/storylines/road_map_storylines.md b/reports/narrativeStudio/storylines/road_map_storylines.md
index 3cca63a6..777b3f9b 100644
--- a/reports/narrativeStudio/storylines/road_map_storylines.md
+++ b/reports/narrativeStudio/storylines/road_map_storylines.md
@@ -315,7 +315,7 @@ Interprétation V0 :
 | NS-STORYLINES-V1-10 | Graph From StorylineAsset V0 | editor graph | DONE | NS-STORYLINES-V1-11 |
 | NS-STORYLINES-V1-11 | Side Quest Attachment + Graph Integration V0 | editor graph | DONE | NS-STORYLINES-V1-12 |
 | NS-STORYLINES-V1-12 | V1 Visual Graph Enrichment | visual gate | DONE | NS-STORYLINES-V1-CHECKPOINT |
-| NS-STORYLINES-V1-CHECKPOINT | Storylines V1 Acceptance Checkpoint | checkpoint | TODO | TBD |
+| NS-STORYLINES-V1-CHECKPOINT | Storylines V1 Acceptance Checkpoint | checkpoint | DONE | NS-SCENES-V1 |
 
 ## 9. Detailed lots
 
@@ -896,10 +896,10 @@ Décision temporaire :
 ## 13. Current status
 
 ```text
-Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 VISUAL GRAPH ENRICHMENT DONE
-Current lot: NS-STORYLINES-V1-12
+Roadmap status: V0 ACCEPTED WITH V1 LIMITATIONS / V1 ACCEPTED WITH LIMITATIONS
+Current lot: NS-STORYLINES-V1-CHECKPOINT
 Current lot status: DONE
-Next recommended lot: NS-STORYLINES-V1-CHECKPOINT — Storylines V1 Acceptance Checkpoint
+Next recommended lot: NS-SCENES-V1 — Scene Placeholder + Scene Linking Foundation
 ```
 
 | Lot | Status | Last update | Notes |
@@ -966,6 +966,15 @@ Suite V1 documentaire recommandée :
 
 ## 15. Changelog
 
+### 2026-05-29 — NS-STORYLINES-V1-CHECKPOINT
+
+- Storylines V1 Acceptance Checkpoint livré en audit-only / documentation-only.
+- Verdict : `ACCEPTED WITH LIMITATIONS`.
+- Storylines V1 est fermé comme atelier auteur initial : modèle, JSON, `ProjectManifest.storylines`, preview legacy, création main/sideQuest, chapters/steps, attachement sideQuest explicite, graph read-only et polish V1 sont couverts par tests ciblés.
+- Limites acceptées : pas encore de scene placeholder, sceneLink, Scene Outcome branch, facts/world rules, validation narrative globale, edit/delete/reorder avancé, import legacy appliqué ou runtime execution.
+- Limite d'évidence : les rapports V1-00 à V1-11 et les captures V1-07 à V1-11 attendus sont absents du repo courant ; les tests et le rapport V1-12 restent présents.
+- Prochaine phase recommandée : `NS-SCENES-V1 — Scene Placeholder + Scene Linking Foundation`.
+
 ### 2026-05-29 — NS-STORYLINES-V1-12
 
 - V1 Visual Graph Enrichment livré côté editor : le graph read-only est plus lisible sans ajouter de comportement produit.
```

### Contenu complet du rapport checkpoint créé

Ce document est le rapport checkpoint créé pour `NS-STORYLINES-V1-CHECKPOINT`. Son contenu complet est constitué par les sections `1` à `23`, depuis le titre jusqu'à la self-review.

### Git status final exact

```text
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_v1_checkpoint_acceptance.md
```

### Git diff --stat final

```text
 .../narrativeStudio/storylines/road_map_storylines.md   | 17 +++++++++++++----
 1 file changed, 13 insertions(+), 4 deletions(-)
```

### Git diff --name-only final

```text
reports/narrativeStudio/storylines/road_map_storylines.md
```

### Git diff --check final

```text
Sortie : <vide>
```

### Auto-review critique

- The functional acceptance signal is strong: all targeted Storylines tests, full map_core tests, and targeted analyses passed.
- The evidence signal is limited by missing historical reports/screenshots for V1-00 through V1-11.
- The checkpoint did not modify code, tests, screenshots, or generated files.
- The recommended next phase should be scenes, not another hidden Storylines feature lot.

## 23. Self-review

This checkpoint stayed audit-only/documentation-only. It created the checkpoint report and updated the roadmap. It did not modify Dart code, tests, screenshots, generated files, runtime, gameplay, or battle packages.

The verdict is intentionally conservative: `ACCEPTED WITH LIMITATIONS`, because Storylines V1 is usable for initial authoring but not yet connected to scene authoring/runtime execution, and historical evidence artifacts for earlier V1 lots are absent.
