# Lot Surface Studio Purge V0

Date: 2026-04-30

## 1. Verdict

Verdict scoped purge: OK.

Surface Studio and the TSX authoring workspace have been removed from the active
`map_editor` UI path:

- no production import to `features/surface_studio` remains under `packages/map_editor/lib`;
- `packages/map_editor/lib/src/features/surface_studio/` has been removed;
- `packages/map_editor/test/surface_studio/` has been removed;
- the main editor navigation no longer exposes the Surface Studio workspace;
- Surface Painter, `SurfaceLayer`, `ProjectManifest.surfaceCatalog`, and the
  core surface models were preserved.

Global package status is not fully green for reasons outside this purge:

- `flutter analyze lib test` still fails on Pokemon catalog / move converter
  issues and unrelated const-test debt;
- `flutter test test` still fails on unrelated existing test compile/runtime
  failures;
- the scoped purge checks and Surface Painter regression suite pass.

No git write operation was used.

## 2. Audit initial

Commands run before edits:

```bash
pwd
git status --short --untracked-files=all
git diff --stat
rg -n "SurfaceStudio|Surface Studio|surface_studio|surfaceStudio|TiledTsx|TSX|tiled_tsx|SurfaceStudioPanel|SurfaceStudioPanelFromManifest|SurfaceStudioScreen|TiledTsxWorkspace|SurfaceStudioWorkspace" packages/map_editor/lib packages/map_editor/test
rg -n "surfaceCatalog|SurfaceLayer|SurfacePainter|surface_painter|ProjectSurface|ProjectManifest.surfaceCatalog" packages/map_editor/lib packages/map_core/lib packages/map_runtime/lib packages/map_gameplay/lib
```

Initial `pwd`:

```text
/Users/karim/Project/pokemonProject
```

Initial `git status --short --untracked-files=all`:

```text
 M packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_role_mapping_builder.dart
 M packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart
 M packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart
 M packages/map_editor/test/surface_studio/tiled_tsx_surface_builder_functional_test.dart
 M packages/map_editor/test/surface_studio/tiled_tsx_surface_builder_suggestions_test.dart
 M packages/map_editor/test/surface_studio/tiled_tsx_surface_preview_ui_test.dart
?? packages/map_editor/generate_project_overview.sh
?? packages/map_editor/project_overview.txt
?? packages/map_editor/test/surface_studio/tiled_tsx_functional_actions_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_no_double_workflow_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_recovery_material_error_test.dart
?? packages/map_editor/test/surface_studio/tiled_tsx_workspace_stable_flow_test.dart
?? reports/surface/surface_studio_tiled_tsx_recovery_stabilization.md
```

Initial `git diff --stat`:

```text
 .../importers/tiled_tsx_role_mapping_builder.dart  |  7 +--
 .../importers/tiled_tsx_workspace.dart             | 63 ++++++++++++++++------
 .../surface_studio/tiled_tsx_import_ui_test.dart   | 15 +++++-
 .../tiled_tsx_surface_builder_functional_test.dart | 10 +++-
 ...tiled_tsx_surface_builder_suggestions_test.dart | 10 +++-
 .../tiled_tsx_surface_preview_ui_test.dart         | 16 ++++--
 6 files changed, 93 insertions(+), 28 deletions(-)
```

Context Mode:

```text
command -v ctx
```

returned no executable path. No MCP stats were exposed by the local shell.

Deeper `AGENTS.md` audit:

```text
find packages/map_editor -name AGENTS.md -print
```

returned no deeper package instructions.

Audit answers:

1. Surface Studio was branched from `EditorWorkspaceMode.surfaceStudio`, the
   shell workspace switch, the canvas host, the top toolbar, and the project
   explorer/sidebar group.
2. The activating enum value was `EditorWorkspaceMode.surfaceStudio`.
3. Production imports into `features/surface_studio` were in the editor canvas
   host and shell/page wiring.
4. Tests importing `features/surface_studio` were concentrated in
   `packages/map_editor/test/surface_studio/`, plus shell/controller selector
   tests referencing the workspace mode.
5. The complete `packages/map_editor/lib/src/features/surface_studio/` module
   was removable because it was an authoring UI module, not a core/runtime
   surface contract.
6. Surface Studio helpers were not retained in place. Only Surface Painter
   wording/callbacks were adjusted to stop linking toward the removed UI.
7. No generic helper was moved to a neutral folder.
8. Surface Painter was preserved under
   `packages/map_editor/lib/src/features/surface_painter/`.
9. `SurfaceLayer` was preserved in map/core/editor usage.
10. `ProjectManifest.surfaceCatalog` was preserved.

## 3. Production files removed

```text
packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart
packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
packages/map_editor/lib/src/features/surface_studio/importers/tall_grass_tsx_asset_importer.dart
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animated_tileset_parser.dart
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser_models.dart
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_catalog_append.dart
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_animation_pack.dart
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_models.dart
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_prompt_builder.dart
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_suggester.dart
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_role_mapping_builder.dart
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_surface_animation_importer.dart
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_surface_preset_draft.dart
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_transparent_color.dart
packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart
packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_cells.dart
packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart
packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_role_thumbnail_painter.dart
packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_schema_panel.dart
packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart
packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart
packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart
packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_sidebar.dart
packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_top_stepper.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_editing.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_source_picker.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_view_geometry.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_column_role_mapping_block.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_column_selection.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_creation_assistant.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_design_tokens.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_detected_animations_panel.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_diagnostics_view.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_drag_payload.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_local_mapping_suggester.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_response_parser.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_vision_pack.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_motion.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_editor_controller.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_role_assignment_draft.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_preview.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_selection.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_inspector.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_summary.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_step.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_creation_section.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_layout.dart
packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_stepper.dart
```

## 4. Test files removed

```text
packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_editing_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_grid_overlay_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_source_picker_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_view_geometry_test.dart
packages/map_editor/test/surface_studio/surface_studio_atlas_viewport_coordinate_test.dart
packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart
packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart
packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart
packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart
packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart
packages/map_editor/test/surface_studio/surface_studio_mistral_prompt_test.dart
packages/map_editor/test/surface_studio/surface_studio_mistral_response_parser_test.dart
packages/map_editor/test/surface_studio/surface_studio_mistral_vision_pack_test.dart
packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart
packages/map_editor/test/surface_studio/surface_studio_preset_editor_controller_test.dart
packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart
packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart
packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart
packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart
packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart
packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart
packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart
packages/map_editor/test/surface_studio/surface_studio_role_mapping_preview_test.dart
packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart
packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart
packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart
packages/map_editor/test/surface_studio/surface_studio_selection_test.dart
packages/map_editor/test/surface_studio/surface_studio_surface_preview_cells_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generator_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_preview_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_assistant_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_preset_generator_test.dart
packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_role_mapping_test.dart
packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
packages/map_editor/test/surface_studio/tall_grass_tsx_asset_importer_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_animated_tileset_parser_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_animation_browser_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_catalog_append_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_prompt_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_suggester_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_mistral_review_ui_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_reference_no_legacy_stack_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_role_mapping_builder_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_surface_animation_importer_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_surface_builder_functional_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_surface_builder_reference_ui_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_surface_builder_suggestions_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_ui_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_surface_preview_roles_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_surface_preview_ui_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_transparent_color_test.dart
packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart
```

The untracked recovery tests that were under `packages/map_editor/test/surface_studio/`
were also removed with the directory.

## 5. Files modified

```text
packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
packages/map_editor/lib/src/features/surface_painter/surface_catalog_availability.dart
packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart
packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart
packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
packages/map_editor/lib/src/ui/editor_shell_page.dart
packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
packages/map_editor/lib/src/ui/shared/top_toolbar.dart
packages/map_editor/test/editor_selectors_test.dart
packages/map_editor/test/editor_shell_page_smoke_test.dart
packages/map_editor/test/editor_state_groups_test.dart
packages/map_editor/test/editor_workspace_controller_test.dart
packages/map_editor/test/map_grid_painter_test.dart
packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart
packages/map_editor/test/surface_painter/surface_catalog_availability_test.dart
packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart
packages/map_editor/test/surface_painter/surface_palette_panel_test.dart
packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart
```

## 6. Files created

```text
packages/map_editor/test/surface_studio_removed_test.dart
reports/surface/surface_studio_purge_v0.md
```

## 7. Navigation before / after

Before:

- `EditorWorkspaceMode.surfaceStudio` existed.
- The top toolbar and shell knew how to switch to a Surface Studio workspace.
- The project explorer/sidebar exposed a Surface Studio entry.
- Surface Painter could route the user toward Surface Studio.

After:

- `EditorWorkspaceMode.surfaceStudio` is removed.
- No selector/shell/canvas/toolbar switch builds Surface Studio.
- The project explorer no longer exposes the Surface Studio entry.
- Surface Painter remains available but no longer links to the removed studio.

## 8. References removed

Removed production references include:

```text
EditorWorkspaceMode.surfaceStudio
selectSurfaceStudioWorkspace
SurfaceStudioPanel
SurfaceStudioScreen
TiledTsxWorkspace
TiledTsxAnimationBrowser
features/surface_studio/*
```

Post-suppression checks:

```bash
rg -n "features/surface_studio|surface_studio/" packages/map_editor/lib packages/map_editor/test
```

Output:

```text
```

Exit code: 1.

```bash
rg -n "SurfaceStudio|Surface Studio|TiledTsx|tiled_tsx|TSX workspace|Créer une surface" packages/map_editor/lib packages/map_editor/test
```

Output:

```text
```

Exit code: 1.

```bash
rg -n "EditorWorkspaceMode\\.surfaceStudio|selectSurfaceStudioWorkspace|onOpenSurfaceStudio|recommendedActionLabel" packages/map_editor/lib packages/map_editor/test
```

Output:

```text
```

Exit code: 1.

## 9. Dependencies and native cleanup

Dependency/native audit commands:

```bash
rg -n "file_picker|FilePicker|map_editor/file_access|TiledTsx|Mistral" packages/map_editor/lib packages/map_editor/pubspec.yaml
rg -n "beginImportBundleAccess|map_editor/file_access|selectedPath|TSX|security" packages/map_editor/macos packages/map_editor/lib
```

Decision:

- `file_picker` was preserved because it is still used by non-Surface-Studio
  features such as Dialogue Studio, tileset import, Pokedex import, gameplay
  zone properties, and top toolbar flows.
- Mistral/API settings were preserved because they are still used by Dialogue
  Studio and editor AI settings.
- `map_editor/file_access` and macOS security-scoped file access were preserved
  because they are still used by Pokedex/editor import flows.
- No `pubspec.yaml` dependency was removed.
- No macOS native file was changed.

## 10. Preserved explicitly

Preserved:

- `packages/map_core/lib/src/models/surface.dart`
- `packages/map_core/lib/src/models/surface_catalog.dart`
- `packages/map_core/lib/src/operations/*surface*`
- `ProjectManifest.surfaceCatalog`
- `SurfaceLayer`
- `SurfaceCellPlacement`
- `packages/map_editor/lib/src/features/surface_painter/`
- runtime surface rendering
- existing Surface to GameplayZone bridge

Not touched:

- `packages/map_runtime/`
- `packages/map_gameplay/`
- `packages/map_battle/`

## 11. Tests

### Removed workspace test

Command:

```bash
cd packages/map_editor && flutter test test/surface_studio_removed_test.dart --no-pub --reporter expanded
```

Output:

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio_removed_test.dart
00:00 +0: removed surface authoring workspace is not exposed in shell UI
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +1: All tests passed!
```

### Editor selectors

Command:

```bash
cd packages/map_editor && flutter test test/editor_selectors_test.dart --no-pub --reporter expanded
```

Output:

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_selectors_test.dart
00:00 +0: editor selectors editorShellSnapshotProvider derives map title and save affordance
00:00 +1: editor selectors editorToolbarSnapshotProvider resolves selected tileset from layer
00:00 +2: editor selectors editorProjectExplorerSnapshotProvider exposes active map selection
00:00 +3: editor selectors editorShellSnapshotProvider exposes trainer studio labels
00:00 +4: editor selectors editorShellSnapshotProvider exposes Pokémon catalogs labels
00:00 +5: editor selectors editorTerrainLibrarySnapshotProvider exposes preset selection inputs
00:00 +6: editor selectors editorTilesetPaletteSnapshotProvider exposes palette panel state
00:00 +7: All tests passed!
```

### Editor shell smoke

Command:

```bash
cd packages/map_editor && flutter test test/editor_shell_page_smoke_test.dart --no-pub --reporter expanded
```

Output:

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_shell_page_smoke_test.dart
00:00 +0: EditorShellPage smoke renders map workspace chrome and toggles the right panel
Warning: Falling back on slow accent color resolution. It’s possible that the accent colors have changed in a recent version of macOS, thus invalidating macos_ui’s accent colors, which were captured on macOS Ventura. If you see this message, please notify a maintainer of the macos_ui package.
00:00 +1: EditorShellPage smoke updates the workspace header for tileset mode
00:01 +2: EditorShellPage smoke renders the trainer studio workspace chrome
FileProjectRepository: Loading project from /tmp/editor_shell_trainer/project.json
00:01 +3: EditorShellPage smoke renders the Pokémon catalogs workspace shell
00:01 +4: EditorShellPage smoke renders the Items catalogs workspace shell
00:01 +5: EditorShellPage smoke renders shell chrome with an error state already present
00:01 +6: All tests passed!
```

### Workspace controller

Command:

```bash
cd packages/map_editor && flutter test test/editor_workspace_controller_test.dart --no-pub --reporter expanded
```

Output:

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/editor_workspace_controller_test.dart
00:00 +0: EditorWorkspaceController selectPokedexWorkspace switches mode and clears stale errors
00:00 +1: EditorWorkspaceController selectTrainerWorkspace switches mode and clears stale errors
00:00 +2: EditorWorkspaceController selectDialogueWorkspace keeps project session and only changes mode
00:00 +3: EditorWorkspaceController selectPokemonCatalogSection opens the parent workspace and stores the section
00:00 +4: All tests passed!
```

### Surface Painter regressions

Command:

```bash
cd packages/map_editor && flutter test test/surface_painter --no-pub --reporter expanded
```

Final line:

```text
00:02 +70: All tests passed!
```

### Full test suite

Command:

```bash
cd packages/map_editor && flutter test test --no-pub --reporter expanded
```

Final line:

```text
00:55 +572 -35: Some tests failed.
```

Failure families observed:

- unrelated const-test failures where tests use
  `const ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), ...)`;
- Pokemon SDK move catalog converter compile errors around removed/renamed move
  model fields and classes;
- Pokedex learnset validation failure for missing local move id `protect`.

## 12. Analyze

Scoped command:

```bash
cd packages/map_editor && flutter analyze lib/src/features/editor/application/editor_workspace_controller.dart lib/src/features/editor/state/editor_notifier.dart lib/src/features/editor/state/editor_selectors.dart lib/src/features/editor/state/models/editor_workspace_mode.dart lib/src/features/surface_painter/surface_catalog_availability.dart lib/src/features/surface_painter/surface_palette_panel.dart lib/src/features/surface_painter/surface_tile_preview_resolver.dart lib/src/ui/canvas/editor_canvas_host.dart lib/src/ui/editor_shell_page.dart lib/src/ui/panels/project_explorer_panel.dart lib/src/ui/shared/top_toolbar.dart test/editor_selectors_test.dart test/editor_shell_page_smoke_test.dart test/editor_workspace_controller_test.dart test/surface_painter/surface_catalog_availability_test.dart test/surface_painter/surface_palette_panel_test.dart test/surface_studio_removed_test.dart
```

Output:

```text
Analyzing 17 items...
No issues found! (ran in 1.9s)
```

Global command:

```bash
cd packages/map_editor && flutter analyze lib test
```

Final line:

```text
392 issues found. (ran in 1.9s)
```

First blocking families:

```text
error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
error • The named parameter 'battleEngineMethod' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:72:7 • undefined_named_parameter
error • The named parameter 'effectChance' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:73:7 • undefined_named_parameter
error • Undefined class 'PokemonMoveAimedTarget' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:239:3 • undefined_class
error • Undefined class 'PokemonMoveFlags' • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:284:3 • undefined_class
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
warning • The library 'package:map_editor/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart' doesn't export a member with the shown name 'showPokedexImportFlowSheet' • lib/src/ui/canvas/pokedex_workspace_views.dart:17:9 • undefined_shown_name
```

## 13. QA runtime

Command:

```bash
cd packages/map_editor && flutter run -d macos
```

Observed output:

```text
Launching lib/main.dart on macOS in debug mode...
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
2026-04-30 12:42:28.376 map_editor[37759:19600829] Running with merged UI and platform thread. Experimental.
Syncing files to device macOS...                                   321ms
A Dart VM Service on macOS is available at: http://127.0.0.1:61845/yTFc3YgOLUU=/
The Flutter DevTools debugger and profiler on macOS is available at: http://127.0.0.1:61845/yTFc3YgOLUU=/devtools/?uri=ws://127.0.0.1:61845/yTFc3YgOLUU=/ws
flutter: FileProjectRepository: Loading project from /Users/karim/Desktop/my_new_project/project.json
```

The app built and launched. I did not complete a visual/manual sidebar
inspection through the macOS window. The `flutter run` process created by this
check was terminated after launch so no command from this task remains attached.

## 14. Non-objectifs confirmes

Confirmed:

- no new Path Studio;
- no Path V2 implementation;
- no `map_core` surface model deletion;
- no `ProjectManifest.surfaceCatalog` deletion;
- no Surface Painter deletion;
- no runtime/gameplay/battle package change;
- no PixelLab/Mistral/MCP integration;
- no project manifest save/mutation flow added;
- no Surface Studio placeholder replacement.

## 15. Limites restantes

- Historical reports under `reports/surface/` still mention Surface Studio/TSX;
  they were kept as requested historical work evidence.
- `packages/map_editor/generate_project_overview.sh` remains untracked and was
  already present in the working tree before the purge.
- `reports/surface/surface_studio_tiled_tsx_recovery_stabilization.md` remains
  untracked historical recovery report.
- The global editor test/analyze state still has unrelated failures listed
  above.

## 16. Git status final

Final `git status --short --untracked-files=all`:

```text
 M packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/editor/state/editor_selectors.dart
 M packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart
 M packages/map_editor/lib/src/features/surface_painter/surface_catalog_availability.dart
 M packages/map_editor/lib/src/features/surface_painter/surface_palette_panel.dart
 M packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart
 D packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_grid_painter.dart
 D packages/map_editor/lib/src/features/surface_studio/atlas/surface_studio_atlas_panel.dart
 D packages/map_editor/lib/src/features/surface_studio/importers/tall_grass_tsx_asset_importer.dart
 D packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animated_tileset_parser.dart
 D packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart
 D packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_animation_browser_models.dart
 D packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_catalog_append.dart
 D packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_animation_pack.dart
 D packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_models.dart
 D packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_prompt_builder.dart
 D packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_suggester.dart
 D packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_role_mapping_builder.dart
 D packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_surface_animation_importer.dart
 D packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_surface_preset_draft.dart
 D packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_transparent_color.dart
 D packages/map_editor/lib/src/features/surface_studio/importers/tiled_tsx_workspace.dart
 D packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_preview_panel.dart
 D packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_cells.dart
 D packages/map_editor/lib/src/features/surface_studio/preview/surface_studio_surface_preview_renderer.dart
 D packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_role_thumbnail_painter.dart
 D packages/map_editor/lib/src/features/surface_studio/schema/surface_studio_schema_panel.dart
 D packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_bottom_action_bar.dart
 D packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_header.dart
 D packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_shell.dart
 D packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_sidebar.dart
 D packages/map_editor/lib/src/features/surface_studio/shell/surface_studio_top_stepper.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_ai_mapping_suggester.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_authoring_prep.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_editing.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_grid_preview.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_image_preview.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_source_picker.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_view_geometry.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_column_role_mapping_block.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_column_selection.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_creation_assistant.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_design_tokens.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_detected_animations_panel.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_diagnostics_view.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_drag_payload.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_local_mapping_suggester.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_controller.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_models.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_mapping_suggestion_prompt_builder.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_mapping_suggester.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_response_parser.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_mistral_vision_pack.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_motion.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_paintable_surfaces_panel.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_editor_controller.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_role_assignment_draft.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_editor.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_role_mapping_preview.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_screen.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_selection.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_inspector.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_summary.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_step.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_creation_section.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_layout.dart
 D packages/map_editor/lib/src/features/surface_studio/surface_studio_workflow_stepper.dart
 M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
 M packages/map_editor/lib/src/ui/editor_shell_page.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/lib/src/ui/shared/top_toolbar.dart
 M packages/map_editor/test/editor_selectors_test.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/editor_state_groups_test.dart
 M packages/map_editor/test/editor_workspace_controller_test.dart
 M packages/map_editor/test/map_grid_painter_test.dart
 M packages/map_editor/test/surface_painter/editor_notifier_surface_paint_test.dart
 M packages/map_editor/test/surface_painter/surface_catalog_availability_test.dart
 M packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart
 M packages/map_editor/test/surface_painter/surface_palette_panel_test.dart
 M packages/map_editor/test/surface_painter/surface_to_gameplay_zone_action_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_atlas_editing_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_atlas_grid_overlay_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_atlas_grid_preview_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_layout_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_atlas_image_preview_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_atlas_source_picker_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_atlas_view_geometry_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_atlas_viewport_coordinate_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_column_role_mapping_block_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_mapper_preview_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_mapping_suggestion_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_mistral_progress_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_mistral_prompt_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_mistral_response_parser_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_mistral_vision_pack_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_preset_editor_controller_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_rebuild_atlas_interaction_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_rebuild_functional_integration_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_rebuild_preview_controls_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_rebuild_schema_panel_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_rebuild_shell_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_rebuild_test_harness.dart
 D packages/map_editor/test/surface_studio/surface_studio_role_mapping_editor_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_role_mapping_preview_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_selection_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_surface_preview_cells_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generation_plan_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_generator_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_animation_preview_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_assistant_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_golden_slice_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_preset_generator_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_vertical_atlas_role_mapping_test.dart
 D packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
 D packages/map_editor/test/surface_studio/tall_grass_tsx_asset_importer_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_animated_tileset_parser_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_animation_browser_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_catalog_append_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_import_ui_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_prompt_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_suggester_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_mistral_grouping_ui_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_mistral_review_ui_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_reference_no_legacy_stack_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_role_mapping_builder_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_surface_animation_importer_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_surface_builder_functional_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_surface_builder_reference_ui_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_surface_builder_suggestions_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_surface_preset_builder_ui_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_surface_preview_roles_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_surface_preview_ui_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_transparent_color_test.dart
 D packages/map_editor/test/surface_studio/tiled_tsx_workspace_tab_test.dart
?? packages/map_editor/generate_project_overview.sh
?? packages/map_editor/test/surface_studio_removed_test.dart
?? reports/surface/surface_studio_purge_v0.md
?? reports/surface/surface_studio_tiled_tsx_recovery_stabilization.md
```
