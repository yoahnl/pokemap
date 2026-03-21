import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';
import 'package:map_editor/src/ui/shared/status_bar.dart';
import 'package:map_editor/src/ui/shared/top_toolbar.dart';

import '../features/editor/state/editor_notifier.dart';

class EditorShellPage extends ConsumerWidget {
  const EditorShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  child: MapCanvas(),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 300,
                  child: Container(
                      color:
                          Theme.of(context).cardColor.withValues(alpha: 0.5)),
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
