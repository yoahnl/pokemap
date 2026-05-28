# NS-STORYLINES-V1-11 — Side Quest Attachment + Graph Integration V0

## 1. Executive summary

V1-11 is delivered.

The editor can now attach a real `StorylineAsset(type: sideQuest)` to a real main storyline through an explicit author action. The attachment is persisted as a `StorylineRelationship(kind: sideQuestAvailableDuring)` inline on the sideQuest, with a minimal `SideQuestAvailability.startAnchor` pointing to a selected chapter or step in the main storyline.

The main graph now renders attached sideQuests only when this relationship exists. Unattached sideQuests remain absent from the main graph.

## 2. Inputs read

Read:

- `AGENTS.md`
- `agent_rules.md`
- `skills/README.md`
- `/Users/karim/.codex/skills/flutter-add-widget-test/SKILL.md`
- `reports/narrativeStudio/storylines/road_map_storylines.md`
- `packages/map_core/lib/src/models/storyline_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_painter.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `packages/map_editor/test/storylines_current_global_story_characterization_test.dart`
- `packages/map_editor/test/narrative_workspace_projection_test.dart`
- editor notifier/selectors and design-system files listed in the lot audit.

Expected-but-absent reports at start:

- `reports/narrativeStudio/storylines/ns_storylines_v1_10_graph_from_storyline_asset_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_09_create_side_quest_flow_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_08_structure_tab_authoring_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_07_bis_storylines_workspace_cleanup.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_07_create_main_storyline_flow_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_03_storyline_asset_pure_model_v0.md`
- `reports/narrativeStudio/storylines/ns_storylines_v1_00_storyline_semantics_and_usable_authoring_contract.md`

## 3. Product problem addressed

Before this lot, sideQuests existed but were intentionally standalone. The main graph ignored them even when the author wanted a sideQuest to become available during the main story.

V1-11 adds the missing explicit author link:

```text
sideQuest selected
-> Attach to main graph
-> choose main storyline
-> choose chapter or step anchor
-> persist relationship on sideQuest
-> main graph renders sideQuest at that anchor
```

## 4. Implementation summary

- Added sideQuest attachment CTA in Structure.
- Added attachment dialog with main storyline target and chapter/step anchor choices.
- Persisted `StorylineRelationship` and `SideQuestAvailability` without changing `map_core`.
- Updated sideQuest status labels in list, header, Structure, graph, and inspector.
- Extended graph model to derive attached sideQuest nodes from existing relationships.
- Extended graph view to render attached sideQuest chips inside the anchored chapter area.
- Kept graph read-only.

## 5. Attachment flow

The flow is available only when a sideQuest is selected.

If the sideQuest is not attached:

- Structure shows `Attacher au graph principal`.
- The dialog lists main storylines.
- The dialog lists valid anchors from the chosen main storyline:
  - chapter anchors;
  - step anchors.
- Submit creates one relationship on the sideQuest.

If the sideQuest already has a main attachment:

- Structure shows `Déjà attachée`.
- No duplicate relationship is created.

## 6. Relationship / availability persistence

The persisted relationship shape is:

```text
StorylineRelationship(
  kind: sideQuestAvailableDuring,
  sourceStorylineId: sideQuest.id,
  targetStorylineId: main.id,
  anchor: selected chapter/step anchor,
  availability.startAnchor: selected chapter/step anchor,
)
```

The relationship is stored inline on the sideQuest because `StorylineAsset` validates that inline relationships have `sourceStorylineId == StorylineAsset.id`.

No relationship is stored on the main storyline.

## 7. Anchor selection behavior

Supported V0 anchors:

- `StorylineAnchorKind.chapter`
- `StorylineAnchorKind.step`

Unsupported in this UI lot:

- `storyline`
- `sceneOutcome`

If a main storyline has no chapter or step, the dialog blocks attachment and explains that a main anchor must exist first.

## 8. Main graph integration behavior

The graph now scans sideQuest storylines for explicit relationships targeting the selected main storyline.

Only attached sideQuests become graph nodes. Unattached sideQuests still produce only a note that explicit attachment is required.

The rendered sideQuest node says `Relation explicite` and displays the anchor label.

## 9. SideQuest standalone behavior

SideQuest graph remains autonomous. If attached, it shows `Quête annexe attachée` and `Relation principale explicite`. If unattached, it keeps the previous standalone/non-linked wording.

## 10. Legacy non-import guarantee

No legacy import is called. `buildLegacyGlobalStoryImportPreview` is not applied. `ScenarioAsset(scope == globalStory)` remains untouched.

## 11. localEventFlow exclusion

`localEventFlow` is still never promoted to sideQuest. The tests keep checking that it does not appear as a storyline, sideQuest, chapter, step, graph node, or graph edge.

## 12. Non-goals confirmed

Not done:

- no `map_core` change;
- no `ProjectManifest` model change;
- no runtime/gameplay/battle change;
- no generated file change;
- no build_runner;
- no scene placeholder;
- no `StorylineSceneLink`;
- no outcome/fact/world-rule condition;
- no automatic sideQuest relation;
- no automatic legacy import;
- no drag/drop, zoom, minimap, or graph editing.

## 13. Design System Gate

The UI continues to use PokeMap primitives and theme tokens. The anti-color search is clean.

## 14. Tests added or modified

Modified:

- `packages/map_editor/test/storylines_workspace_shell_test.dart`

Added coverage:

- attach sideQuest to explicit main step anchor;
- relationship and availability persisted on sideQuest;
- cancel attachment does not mutate project;
- main graph renders sideQuest only after explicit relation;
- sideQuest stays absent from main graph without relation;
- existing creation/Structure/legacy/localEventFlow/anti-fake checks still pass;
- V1-11 visual gate screenshots generated.

## 15. Visual Gate

Generated dark screenshots:

- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_11_attach_side_quest_dialog.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_11_attached_main_graph.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_11_attached_sidequest_structure.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_11_unattached_sidequest_hidden_from_main_graph.png`

All are `1600 x 1000` PNG files.

## 16. Commands run

Initial git evidence:

```text
--- branch ---
main
--- status ---
Sortie : <vide>
--- diff stat ---
Sortie : <vide>
--- diff name-only ---
Sortie : <vide>
--- diff check ---
Sortie : <vide>
```

Format:

```text
Formatted packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
Formatted packages/map_editor/test/storylines_workspace_shell_test.dart
Formatted 4 files (2 changed) in 0.03 seconds.
```

Targeted widget test:

```text
cd packages/map_editor && flutter test test/storylines_workspace_shell_test.dart
00:05 +36: All tests passed!
EXIT:0
```

Regression tests:

```text
cd packages/map_editor && flutter test test/storylines_current_global_story_characterization_test.dart
00:00 +2: All tests passed!
EXIT:0

cd packages/map_editor && flutter test test/narrative_workspace_projection_test.dart
00:00 +3: All tests passed!
EXIT:0
```

Analyze:

```text
Analyzing 7 items...
No issues found! (ran in 1.7s)
EXIT:0
```

Anti-colors:

```text
Sortie : <vide>
```

## 17. Roadmap update

`NS-STORYLINES-V1-11` is marked DONE.

Next recommended lot:

```text
NS-STORYLINES-V1-12 — V1 Visual Graph Enrichment
```

## 18. Evidence Pack

Files modified:

- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart`
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart`
- `packages/map_editor/test/storylines_workspace_shell_test.dart`
- `reports/narrativeStudio/storylines/road_map_storylines.md`

Files created:

- `reports/narrativeStudio/storylines/ns_storylines_v1_11_side_quest_attachment_graph_integration_v0.md`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_11_attach_side_quest_dialog.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_11_attached_main_graph.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_11_attached_sidequest_structure.png`
- `reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_11_unattached_sidequest_hidden_from_main_graph.png`

Final git status:

```text
 M packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart
 M packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
 M packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
 M packages/map_editor/test/storylines_workspace_shell_test.dart
 M reports/narrativeStudio/storylines/road_map_storylines.md
?? reports/narrativeStudio/storylines/ns_storylines_v1_11_side_quest_attachment_graph_integration_v0.md
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_11_attach_side_quest_dialog.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_11_attached_main_graph.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_11_attached_sidequest_structure.png
?? reports/narrativeStudio/storylines/screenshots/ns_storylines_v1_11_unattached_sidequest_hidden_from_main_graph.png
```

Final git diff --stat:

```text
 .../canvas/storylines/storylines_graph_model.dart  | 201 ++++++++-
 .../canvas/storylines/storylines_graph_view.dart   | 286 +++++++++----
 .../lib/src/ui/canvas/storylines_workspace.dart    | 447 ++++++++++++++++++++-
 .../test/storylines_workspace_shell_test.dart      | 211 +++++++++-
 .../storylines/road_map_storylines.md              |  21 +-
 5 files changed, 1054 insertions(+), 112 deletions(-)
```

Final git diff --name-only:

```text
packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_model.dart
packages/map_editor/lib/src/ui/canvas/storylines/storylines_graph_view.dart
packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart
packages/map_editor/test/storylines_workspace_shell_test.dart
reports/narrativeStudio/storylines/road_map_storylines.md
```

Final git diff --check:

```text
Sortie : <vide>
```

## 19. Self-review

- The attachment is explicit and persisted.
- The graph does not infer sideQuest placement from existence.
- The relation is stored on the sideQuest to satisfy the existing core invariant.
- No core model was modified.
- No runtime behavior was introduced.
- Current limitation: V1-11 supports one attachment flow in UI; richer availability windows and multiple relation editing are left for later lots.
