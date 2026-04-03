import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import 'map_canvas.dart';
import 'narrative_workspace_canvas.dart';
import 'tileset_editor_canvas.dart';

class EditorCanvasHost extends ConsumerWidget {
  const EditorCanvasHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);

    return switch (state.workspaceMode) {
      EditorWorkspaceMode.map => const MapCanvas(),
      EditorWorkspaceMode.tileset => const TilesetEditorCanvas(),
      EditorWorkspaceMode.globalStory ||
      EditorWorkspaceMode.step ||
      EditorWorkspaceMode.cutscene =>
        const NarrativeWorkspaceCanvas(),
    };
  }
}
