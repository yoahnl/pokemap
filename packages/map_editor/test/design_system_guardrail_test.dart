import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('design-system guardrails', () {
    test('editor UI does not add direct color references outside tokens', () {
      final regressions = _directColorReferenceRegressions();

      expect(
        regressions,
        isEmpty,
        reason: [
          'Feature UI must use design-system/theme colors only.',
          'Move new colors to PokeMapColorTokens or a semantic helper.',
          'Reduce _legacyDirectColorReferenceBaseline as files migrate.',
          ...regressions,
        ].join('\n'),
      );
    });

    test('new editor UI files do not depend on legacy chrome widgets', () {
      final regressions = _legacyChromeImportRegressions();

      expect(
        regressions,
        isEmpty,
        reason: [
          'New editor UI must use the PokeMap design system.',
          'Extend a design-system primitive before importing legacy chrome.',
          'Reduce _legacyChromeImportBaseline as files migrate.',
          ...regressions,
        ].join('\n'),
      );
    });

    test('Narrative Studio keeps the strict palette ratchet', () {
      final regressions = _narrativeStudioPaletteRegressions();

      expect(
        regressions,
        isEmpty,
        reason: [
          'Narrative Studio is the palette pilot and must stay calm.',
          'Use PokeMap design-system widgets and semantic color tokens.',
          'Allowed temporary debt: 4 legacy imports and 2 CupertinoColors refs.',
          ...regressions,
        ].join('\n'),
      );
    });
  });
}

List<String> _directColorReferenceRegressions() {
  final offendersByPath = <String, List<_Offender>>{};

  for (final sourceFile in _sourceFiles()) {
    final relativePath = sourceFile.relativePath;
    if (_isDesignTokenSource(relativePath)) {
      continue;
    }

    final lines = sourceFile.file.readAsLinesSync();
    for (var index = 0; index < lines.length; index += 1) {
      if (!_directColorReferencePattern.hasMatch(lines[index])) {
        continue;
      }
      offendersByPath.putIfAbsent(relativePath, () => <_Offender>[]).add(
            _Offender(
              path: relativePath,
              line: index + 1,
              snippet: lines[index].trim(),
            ),
          );
    }
  }

  final regressions = <String>[];
  for (final entry in offendersByPath.entries) {
    final allowed = _legacyDirectColorReferenceBaseline[entry.key] ?? 0;
    final extraCount = entry.value.length - allowed;
    if (extraCount <= 0) {
      continue;
    }
    regressions.add(
      '${entry.key}: ${entry.value.length} direct color refs '
      '(baseline $allowed, +$extraCount)',
    );
    regressions.addAll(
      entry.value.skip(allowed).map((offender) => '  ${offender.describe()}'),
    );
  }

  return regressions;
}

List<String> _legacyChromeImportRegressions() {
  final regressions = <String>[];

  for (final sourceFile in _sourceFiles()) {
    final relativePath = sourceFile.relativePath;
    final source = sourceFile.file.readAsStringSync();
    if (!_legacyChromeImportPattern.hasMatch(source)) {
      continue;
    }
    if (_legacyChromeImportBaseline.contains(relativePath)) {
      continue;
    }
    regressions.add(
      '$relativePath imports legacy cupertino_editor_widgets.dart',
    );
  }

  return regressions;
}

List<String> _narrativeStudioPaletteRegressions() {
  final regressions = <String>[];
  var legacyImportCount = 0;
  final cupertinoColorOffenders = <_Offender>[];

  for (final sourceFile in _sourceFiles()) {
    final relativePath = sourceFile.relativePath;
    if (!relativePath.startsWith('lib/src/ui/canvas/narrative_')) {
      continue;
    }

    final source = sourceFile.file.readAsStringSync();
    if (_legacyChromeImportPattern.hasMatch(source)) {
      legacyImportCount += 1;
    }

    final lines = source.split('\n');
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      if (_narrativeHardColorPattern.hasMatch(line)) {
        regressions.add(
          'Narrative hard color: ${_Offender(
            path: relativePath,
            line: index + 1,
            snippet: line.trim(),
          ).describe()}',
        );
      }
      if (_cupertinoColorPattern.hasMatch(line)) {
        cupertinoColorOffenders.add(
          _Offender(
            path: relativePath,
            line: index + 1,
            snippet: line.trim(),
          ),
        );
      }
    }
  }

  if (legacyImportCount > _narrativeLegacyImportBaseline) {
    regressions.add(
      'Narrative legacy imports: $legacyImportCount '
      '(baseline $_narrativeLegacyImportBaseline)',
    );
  }

  if (cupertinoColorOffenders.length > _narrativeCupertinoColorBaseline) {
    regressions.add(
      'Narrative CupertinoColors refs: ${cupertinoColorOffenders.length} '
      '(baseline $_narrativeCupertinoColorBaseline)',
    );
    regressions.addAll(
      cupertinoColorOffenders
          .skip(_narrativeCupertinoColorBaseline)
          .map((offender) => '  ${offender.describe()}'),
    );
  }

  return regressions;
}

List<_SourceFile> _sourceFiles() {
  final packageRoot = Directory.current;
  final sourceRoots = <Directory>[
    Directory(p.join(packageRoot.path, 'lib', 'src', 'ui')),
    Directory(p.join(packageRoot.path, 'lib', 'src', 'features')),
  ];
  final files = <_SourceFile>[];

  for (final root in sourceRoots.where((root) => root.existsSync())) {
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      files.add(
        _SourceFile(
          file: entity,
          relativePath: p.relative(entity.path, from: packageRoot.path),
        ),
      );
    }
  }

  files.sort((left, right) => left.relativePath.compareTo(right.relativePath));
  return files;
}

bool _isDesignTokenSource(String relativePath) {
  return relativePath.startsWith('lib/src/theme/') ||
      relativePath.startsWith('lib/src/ui/design_system/');
}

final _directColorReferencePattern = RegExp(
  r'\bColor\(0x[0-9A-Fa-f]+\)|\bColors\.|\bCupertinoColors\.|\bMacosColors\.',
);

final _legacyChromeImportPattern = RegExp(
  r"cupertino_editor_widgets\.dart",
);

final _narrativeHardColorPattern = RegExp(
  r'\bColor\(0x[0-9A-Fa-f]+\)|\bColors\.|\bMacosColors\.',
);

final _cupertinoColorPattern = RegExp(r'\bCupertinoColors\.');

const _narrativeLegacyImportBaseline = 4;
const _narrativeCupertinoColorBaseline = 2;

const _legacyDirectColorReferenceBaseline = <String, int>{
  'lib/src/features/environment_studio/environment_studio_panel.dart': 9,
  'lib/src/features/environment_studio/environment_studio_workspace.dart': 2,
  'lib/src/features/environment_studio/widgets/environment_element_thumbnail.dart':
      1,
  'lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart':
      1,
  'lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart':
      1,
  'lib/src/features/environment_studio/widgets/environment_palette_item_view.dart':
      1,
  'lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart':
      18,
  'lib/src/features/environment_studio/widgets/environment_preset_detail.dart':
      6,
  'lib/src/features/environment_studio/widgets/environment_preset_diagnostics_view.dart':
      3,
  'lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart':
      5,
  'lib/src/features/environment_studio/widgets/environment_preset_draft_validation_view.dart':
      1,
  'lib/src/features/environment_studio/widgets/environment_preset_list.dart': 4,
  'lib/src/features/path_studio/path_studio_panel.dart': 6,
  'lib/src/features/path_studio/path_studio_saved_preset_detail.dart': 1,
  'lib/src/features/path_studio/path_studio_theme.dart': 19,
  'lib/src/features/path_studio/path_studio_tileset_image_picker.dart': 1,
  'lib/src/features/surface_painter/surface_layer_static_preview.dart': 1,
  'lib/src/ui/canvas/cutscene_studio/cutscene_studio_workbench.dart': 16,
  'lib/src/ui/canvas/cutscene_studio/cutscene_studio_workspace_support.dart':
      10,
  'lib/src/ui/canvas/cutscene_studio_workspace.dart': 2,
  'lib/src/ui/canvas/dialogue_studio/widgets/canvas/dialogue_canvas_cards.dart':
      4,
  'lib/src/ui/canvas/dialogue_studio/widgets/library/dialogue_library_tree.dart':
      4,
  'lib/src/ui/canvas/global_story_studio/global_story_studio_panels.dart': 5,
  'lib/src/ui/canvas/map_canvas.dart': 2,
  'lib/src/ui/canvas/narrative_workspace_canvas.dart': 2,
  'lib/src/ui/canvas/pokedex_workspace/pokedex_common_widgets.dart': 1,
  'lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart': 1,
  'lib/src/ui/canvas/pokedex_workspace/pokedex_empty_state.dart': 3,
  'lib/src/ui/canvas/pokedex_workspace/pokedex_external_batch_field.dart': 2,
  'lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart': 3,
  'lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart': 3,
  'lib/src/ui/canvas/pokedex_workspace/pokedex_list_panel.dart': 2,
  'lib/src/ui/canvas/pokedex_workspace/pokedex_list_row.dart': 1,
  'lib/src/ui/canvas/pokemon_catalogs_workspace/items_catalog_workspace.dart':
      1,
  'lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart':
      1,
  'lib/src/ui/canvas/step_studio/step_studio_workspace_support.dart': 1,
  'lib/src/ui/canvas/step_studio_workspace.dart': 2,
  'lib/src/ui/canvas/tileset_editor_canvas.dart': 1,
  'lib/src/ui/editor_shell_page.dart': 7,
  'lib/src/ui/panels/character_library_panel.dart': 11,
  'lib/src/ui/panels/encounter_tables_panel.dart': 4,
  'lib/src/ui/panels/encounter_tables_panel_entry_widgets.dart': 4,
  'lib/src/ui/panels/encounter_tables_panel_table_widgets.dart': 9,
  'lib/src/ui/panels/entity_properties/entity_properties_dialogue_bindings.dart':
      2,
  'lib/src/ui/panels/entity_properties/entity_properties_npc_runtime.dart': 2,
  'lib/src/ui/panels/entity_properties_panel.dart': 29,
  'lib/src/ui/panels/environment_layer_inspector_panel.dart': 5,
  'lib/src/ui/panels/event_properties_panel.dart': 12,
  'lib/src/ui/panels/gameplay_zone_properties_panel.dart': 11,
  'lib/src/ui/panels/layers_panel.dart': 1,
  'lib/src/ui/panels/map_connections_panel.dart': 13,
  'lib/src/ui/panels/map_properties_panel.dart': 3,
  'lib/src/ui/panels/narrative_inspector_panel.dart': 1,
  'lib/src/ui/panels/project_explorer/dialogs/import_tileset_dialog.dart': 1,
  'lib/src/ui/panels/project_explorer/dnd/tileset_library_drag_drop.dart': 2,
  'lib/src/ui/panels/project_explorer/widgets/sidebar_header_action.dart': 3,
  'lib/src/ui/panels/project_explorer/widgets/tree/tileset_tree_nodes.dart': 1,
  'lib/src/ui/panels/terrain_editor/widgets/terrain_mapping_workspace.dart': 4,
  'lib/src/ui/panels/terrain_editor_panel.dart': 27,
  'lib/src/ui/panels/terrain_map_panel.dart': 22,
  'lib/src/ui/panels/tile_layer_environment_inspector_section.dart': 5,
  'lib/src/ui/panels/tileset_palette/dialogs/element_frame_picker_dialog.dart':
      7,
  'lib/src/ui/panels/tileset_palette/widgets/animation/placed_element_animation_widgets.dart':
      11,
  'lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_editor.dart':
      31,
  'lib/src/ui/panels/tileset_palette/widgets/collision/element_collision_profile_painter.dart':
      7,
  'lib/src/ui/panels/tileset_palette/widgets/library/tileset_palette_library_widgets.dart':
      2,
  'lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart':
      13,
  'lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_instances_section.dart':
      14,
  'lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart':
      17,
  'lib/src/ui/panels/tileset_palette_panel.dart': 21,
  'lib/src/ui/panels/trainer_library_panel.dart': 1,
  'lib/src/ui/panels/trainer_library_panel_pokemon_widgets.dart': 11,
  'lib/src/ui/panels/trainer_library_panel_trainer_widgets.dart': 2,
  'lib/src/ui/panels/trainer_library_panel_workspace_widgets.dart': 3,
  'lib/src/ui/panels/trigger_properties_panel.dart': 11,
  'lib/src/ui/panels/warp_properties_panel.dart': 18,
  'lib/src/ui/shared/editor_paint_palette.dart': 25,
  'lib/src/ui/shared/editor_visual_tokens.dart': 8,
  'lib/src/ui/shared/inspector_embedded_widgets.dart': 7,
  'lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart': 2,
  'lib/src/ui/shared/top_toolbar/widgets/toolbar_brand.dart': 1,
  'lib/src/ui/widgets/element_collision_triple_mask_editor.dart': 27,
};

const _legacyChromeImportBaseline = <String>{
  'lib/src/features/environment_studio/environment_studio_panel.dart',
  'lib/src/features/environment_studio/widgets/environment_element_thumbnail.dart',
  'lib/src/features/environment_studio/widgets/environment_generation_params_draft_editor.dart',
  'lib/src/features/environment_studio/widgets/environment_palette_item_draft_editor.dart',
  'lib/src/features/environment_studio/widgets/environment_palette_item_view.dart',
  'lib/src/features/environment_studio/widgets/environment_preset_creation_wizard.dart',
  'lib/src/features/environment_studio/widgets/environment_preset_detail.dart',
  'lib/src/features/environment_studio/widgets/environment_preset_diagnostics_view.dart',
  'lib/src/features/environment_studio/widgets/environment_preset_draft_form.dart',
  'lib/src/features/environment_studio/widgets/environment_preset_draft_validation_view.dart',
  'lib/src/features/environment_studio/widgets/environment_preset_list.dart',
  'lib/src/features/environment_studio/widgets/environment_preset_save_feedback.dart',
  'lib/src/features/surface_painter/surface_palette_panel.dart',
  'lib/src/ui/canvas/cutscene_studio/cutscene_studio_workbench.dart',
  'lib/src/ui/canvas/cutscene_studio_workspace.dart',
  'lib/src/ui/canvas/dialogue_studio_workspace.dart',
  'lib/src/ui/canvas/global_story_studio/global_story_studio_panels.dart',
  'lib/src/ui/canvas/global_story_studio/global_story_studio_shell.dart',
  'lib/src/ui/canvas/global_story_studio_workspace.dart',
  'lib/src/ui/canvas/narrative_overview_empty_states.dart',
  'lib/src/ui/canvas/narrative_overview_structure_inspector.dart',
  'lib/src/ui/canvas/narrative_overview_workspace.dart',
  'lib/src/ui/canvas/narrative_workspace_canvas.dart',
  'lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart',
  'lib/src/ui/canvas/pokemon_catalogs_workspace/items_catalog_workspace.dart',
  'lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart',
  'lib/src/ui/canvas/step_studio/step_flow_canvas.dart',
  'lib/src/ui/canvas/step_studio/step_flow_palette.dart',
  'lib/src/ui/canvas/step_studio_workspace.dart',
  'lib/src/ui/canvas/tileset_editor_canvas.dart',
  'lib/src/ui/editor_shell_page.dart',
  'lib/src/ui/panels/character_library_panel.dart',
  'lib/src/ui/panels/element_collision_editor_sheet.dart',
  'lib/src/ui/panels/encounter_tables_panel.dart',
  'lib/src/ui/panels/entity_properties_panel.dart',
  'lib/src/ui/panels/environment_layer_inspector_panel.dart',
  'lib/src/ui/panels/event_properties_panel.dart',
  'lib/src/ui/panels/gameplay_zone_properties_panel.dart',
  'lib/src/ui/panels/layers_panel.dart',
  'lib/src/ui/panels/map_connections_panel.dart',
  'lib/src/ui/panels/map_inspector_panel.dart',
  'lib/src/ui/panels/map_properties_panel.dart',
  'lib/src/ui/panels/narrative_inspector_panel.dart',
  'lib/src/ui/panels/narrative_library_panel.dart',
  'lib/src/ui/panels/project_explorer/dialogs/import_tileset_dialog.dart',
  'lib/src/ui/panels/project_explorer/dialogs/tileset_library_dialogs.dart',
  'lib/src/ui/panels/project_explorer/dialogs/world_group_dialogs.dart',
  'lib/src/ui/panels/project_explorer/dnd/tileset_library_drag_drop.dart',
  'lib/src/ui/panels/project_explorer/widgets/sidebar_header_action.dart',
  'lib/src/ui/panels/project_explorer/widgets/tree/tileset_tree_nodes.dart',
  'lib/src/ui/panels/project_explorer/widgets/tree/world_tree_nodes.dart',
  'lib/src/ui/panels/project_explorer_panel.dart',
  'lib/src/ui/panels/terrain_editor_panel.dart',
  'lib/src/ui/panels/terrain_map_panel.dart',
  'lib/src/ui/panels/tile_layer_environment_inspector_section.dart',
  'lib/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_shadow_override_section.dart',
  'lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart',
  'lib/src/ui/panels/tileset_palette_panel.dart',
  'lib/src/ui/panels/trainer_library_panel.dart',
  'lib/src/ui/panels/trigger_properties_panel.dart',
  'lib/src/ui/panels/warp_properties_panel.dart',
  'lib/src/ui/shared/inspector_embedded_widgets.dart',
  'lib/src/ui/shared/inspector_section_card.dart',
  'lib/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart',
  'lib/src/ui/widgets/element_collision_triple_mask_editor.dart',
};

class _SourceFile {
  const _SourceFile({
    required this.file,
    required this.relativePath,
  });

  final File file;
  final String relativePath;
}

class _Offender {
  const _Offender({
    required this.path,
    required this.line,
    required this.snippet,
  });

  final String path;
  final int line;
  final String snippet;

  String describe() => '$path:$line: $snippet';
}
