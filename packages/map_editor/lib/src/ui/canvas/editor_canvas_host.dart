import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import 'map_canvas.dart';
import 'narrative_workspace_canvas.dart';
import 'pokedex_placeholder_workspace.dart';
import 'tileset_editor_canvas.dart';

class EditorCanvasHost extends ConsumerWidget {
  const EditorCanvasHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);

    return switch (state.workspaceMode) {
      EditorWorkspaceMode.map => const MapCanvas(),
      EditorWorkspaceMode.tileset => const TilesetEditorCanvas(),
      // Lot 12: le Pokédex n'est pas encore branché à de vraies données.
      // On route donc vers un placeholder dédié, sans charger de JSON Pokémon
      // et sans introduire d'architecture anticipée pour le lot suivant.
      EditorWorkspaceMode.pokedex => const PokedexPlaceholderWorkspace(),
      EditorWorkspaceMode.globalStory ||
      EditorWorkspaceMode.step ||
      EditorWorkspaceMode.cutscene ||
      EditorWorkspaceMode.dialogue =>
        const NarrativeWorkspaceCanvas(),
    };
  }
}
