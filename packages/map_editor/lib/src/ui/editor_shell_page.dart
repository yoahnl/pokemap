import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
import 'package:map_editor/src/ui/panels/layers_panel.dart';
import 'package:map_editor/src/ui/panels/map_connections_panel.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';
import 'package:map_editor/src/ui/panels/terrain_editor_panel.dart';
import 'package:map_editor/src/ui/panels/terrain_map_panel.dart';
import 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';
import 'package:map_editor/src/ui/panels/warp_properties_panel.dart';
import 'package:map_editor/src/ui/shared/status_bar.dart';
import 'package:map_editor/src/ui/shared/top_toolbar.dart';

import '../features/editor/state/editor_notifier.dart';
import '../features/editor/state/editor_state.dart';

class EditorShellPage extends ConsumerWidget {
  const EditorShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final workspaceMode = state.workspaceMode;
    final notifier = ref.read(editorNotifierProvider.notifier);

    ref.listen(editorNotifierProvider.select((s) => s.errorMessage),
        (prev, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next), backgroundColor: Colors.red.shade900),
        );
      }
    });

    ref.listen(editorNotifierProvider.select((s) => s.statusMessage),
        (prev, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next), duration: const Duration(seconds: 2)),
        );
      }
    });

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true): _UndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
            _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, meta: true): _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, control: true): _RedoIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, meta: true): _SaveIntent(),
        SingleActivator(LogicalKeyboardKey.keyS, control: true): _SaveIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _UndoIntent: CallbackAction<_UndoIntent>(
            onInvoke: (_) {
              if (_isTextInputFocused()) return null;
              if (!state.canUndoMap) return null;
              notifier.undoMap();
              return null;
            },
          ),
          _RedoIntent: CallbackAction<_RedoIntent>(
            onInvoke: (_) {
              if (_isTextInputFocused()) return null;
              if (!state.canRedoMap) return null;
              notifier.redoMap();
              return null;
            },
          ),
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) {
              if (_isTextInputFocused()) return null;
              if (state.activeMap == null || state.isSaving) return null;
              notifier.saveActiveMap();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Column(
              children: [
                const TopToolbar(),
                Expanded(
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 340,
                        child: Column(
                          children: [
                            Expanded(
                              child: ProjectExplorerPanel(),
                            ),
                            Divider(height: 1),
                            SizedBox(height: 420, child: TerrainEditorPanel()),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      const Expanded(
                        child: EditorCanvasHost(),
                      ),
                      const VerticalDivider(width: 1),
                      SizedBox(
                        width: 320,
                        child: workspaceMode == EditorWorkspaceMode.map
                            ? LayoutBuilder(
                                builder: (context, constraints) {
                                  final tilesetHeight =
                                      constraints.maxHeight.isFinite
                                          ? (constraints.maxHeight > 420
                                              ? constraints.maxHeight
                                              : 420.0)
                                          : 420.0;
                                  return SingleChildScrollView(
                                    primary: false,
                                    child: Column(
                                      children: [
                                        const SizedBox(
                                          height: 260,
                                          child: LayersPanel(),
                                        ),
                                        const SizedBox(
                                          height: 320,
                                          child: TerrainMapPanel(),
                                        ),
                                        const SizedBox(
                                          height: 520,
                                          child: MapConnectionsPanel(),
                                        ),
                                        const SizedBox(
                                          height: 260,
                                          child: WarpPropertiesPanel(),
                                        ),
                                        SizedBox(
                                          height: tilesetHeight,
                                          child: const TilesetPalettePanel(),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : const TilesetPalettePanel(),
                      ),
                    ],
                  ),
                ),
                const StatusBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _isTextInputFocused() {
  final focusedContext = FocusManager.instance.primaryFocus?.context;
  if (focusedContext == null) return false;
  return focusedContext.widget is EditableText ||
      focusedContext.findAncestorWidgetOfExactType<EditableText>() != null;
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}
