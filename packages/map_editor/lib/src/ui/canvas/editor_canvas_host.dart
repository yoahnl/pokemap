import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/surface_studio/surface_studio_panel.dart';
import 'map_canvas.dart';
import 'narrative_workspace_canvas.dart';
import 'pokemon_catalogs_workspace.dart';
import 'tileset_editor_canvas.dart';
import '../panels/trainer_library_panel.dart';

class EditorCanvasHost extends ConsumerWidget {
  const EditorCanvasHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceMode = ref.watch(editorWorkspaceModeProvider);
    final project = ref.watch(
      editorNotifierProvider.select((s) => s.project),
    );

    return switch (workspaceMode) {
      EditorWorkspaceMode.map => const MapCanvas(),
      EditorWorkspaceMode.tileset => const TilesetEditorCanvas(),
      EditorWorkspaceMode.trainer => const TrainerLibraryPanel(),
      EditorWorkspaceMode.pokedex => const PokemonCatalogsWorkspace(),
      EditorWorkspaceMode.surfaceStudio => project == null
          ? const Center(
              child: Text('Open a project to browse Surface Studio.'),
            )
          : SurfaceStudioPanelFromManifest(
              manifest: project,
              onProjectManifestChanged: (m) {
                ref
                    .read(editorNotifierProvider.notifier)
                    .applyInMemoryProjectManifest(m);
              },
            ),
      EditorWorkspaceMode.globalStory ||
      EditorWorkspaceMode.step ||
      EditorWorkspaceMode.cutscene ||
      EditorWorkspaceMode.dialogue =>
        const NarrativeWorkspaceCanvas(),
    };
  }
}
