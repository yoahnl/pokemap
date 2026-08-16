import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/environment_studio/environment_studio_workspace.dart';
import '../../features/smart_tiles_studio/presentation/smart_tiles_studio_workspace.dart';
import '../../features/border_studio/border_studio_workspace.dart';
import '../../features/character_studio/presentation/character_studio_workspace.dart';
import '../../features/personalization/presentation/personalization_studio_workspace.dart';
import 'encounter_studio_panel.dart';
import 'map_canvas.dart';
import 'narrative_workspace_canvas.dart';
import 'pokemon_catalogs_workspace.dart';
import 'tileset_editor_canvas.dart';

class EditorCanvasHost extends ConsumerWidget {
  const EditorCanvasHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceMode = ref.watch(editorWorkspaceModeProvider);

    return switch (workspaceMode) {
      EditorWorkspaceMode.map => const MapCanvas(),
      EditorWorkspaceMode.tileset => const TilesetEditorCanvas(),
      EditorWorkspaceMode.encounter => const EncounterStudioPanel(),
      EditorWorkspaceMode.characterStudio => const CharacterStudioWorkspace(),
      EditorWorkspaceMode.pokedex => const PokemonCatalogsWorkspace(),
      EditorWorkspaceMode.narrativeOverview ||
      EditorWorkspaceMode.globalStory ||
      EditorWorkspaceMode.scenes ||
      EditorWorkspaceMode.events ||
      EditorWorkspaceMode.step ||
      EditorWorkspaceMode.cinematics ||
      EditorWorkspaceMode.dialogue ||
      EditorWorkspaceMode.facts ||
      EditorWorkspaceMode.shops ||
      EditorWorkspaceMode.worldRules =>
        const NarrativeWorkspaceCanvas(),
      EditorWorkspaceMode.narrativeValidator =>
        const NarrativeWorkspaceCanvas(),
      EditorWorkspaceMode.smartTilesStudio => const SmartTilesStudioWorkspace(),
      EditorWorkspaceMode.environmentStudio =>
        const EnvironmentStudioWorkspace(),
      EditorWorkspaceMode.personalizationStudio =>
        const PersonalizationStudioWorkspace(),
      EditorWorkspaceMode.borderStudio => const BorderStudioWorkspace(),
    };
  }
}
