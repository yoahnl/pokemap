import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
import 'package:map_editor/src/ui/panels/layers_panel.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';
import 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';
import 'package:map_editor/src/ui/shared/status_bar.dart';
import 'package:map_editor/src/ui/shared/top_toolbar.dart';

import '../features/editor/state/editor_notifier.dart';
import '../features/editor/state/editor_state.dart';

class EditorShellPage extends ConsumerWidget {
  const EditorShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceMode =
        ref.watch(editorNotifierProvider.select((s) => s.workspaceMode));

    // Listen for error messages to show SnackBars
    ref.listen(editorNotifierProvider.select((s) => s.errorMessage),
        (prev, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next), backgroundColor: Colors.red.shade900),
        );
      }
    });

    // Listen for status messages to show SnackBars (optional, but requested for feedback)
    ref.listen(editorNotifierProvider.select((s) => s.statusMessage),
        (prev, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next), duration: const Duration(seconds: 2)),
        );
      }
    });

    return Scaffold(
      body: Column(
        children: [
          const TopToolbar(),
          Expanded(
            child: Row(
              children: [
                const SizedBox(
                  width: 250,
                  child: ProjectExplorerPanel(),
                ),
                const VerticalDivider(width: 1),
                const Expanded(
                  child: EditorCanvasHost(),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 320,
                  child: workspaceMode == EditorWorkspaceMode.map
                      ? const Column(
                          children: [
                            SizedBox(height: 280, child: LayersPanel()),
                            Expanded(child: TilesetPalettePanel()),
                          ],
                        )
                      : const TilesetPalettePanel(),
                ),
              ],
            ),
          ),
          const StatusBar(),
        ],
      ),
    );
  }
}
