import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import 'map_canvas.dart';
import 'narrative_workspace_canvas.dart';
import 'pokedex_workspace.dart';
import 'tileset_editor_canvas.dart';

class EditorCanvasHost extends ConsumerWidget {
  const EditorCanvasHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceMode = ref.watch(editorWorkspaceModeProvider);

    return switch (workspaceMode) {
      EditorWorkspaceMode.map => const MapCanvas(),
      EditorWorkspaceMode.tileset => const TilesetEditorCanvas(),
      // Lot 13: on remplace le placeholder vide du lot 12 par une première
      // vraie liste simple, toujours en lecture seule et sans logique riche.
      EditorWorkspaceMode.pokedex => const PokedexWorkspace(),
      EditorWorkspaceMode.globalStory ||
      EditorWorkspaceMode.step ||
      EditorWorkspaceMode.cutscene ||
      EditorWorkspaceMode.dialogue =>
        const NarrativeWorkspaceCanvas(),
    };
  }
}
