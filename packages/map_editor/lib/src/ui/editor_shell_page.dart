import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';
import 'package:map_editor/src/ui/panels/terrain_editor_panel.dart';
import 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';
import 'package:map_editor/src/ui/shared/status_bar.dart';
import 'package:map_editor/src/ui/shared/top_toolbar.dart';

import '../features/editor/state/editor_notifier.dart';
import '../features/editor/state/editor_state.dart';

class EditorShellPage extends ConsumerStatefulWidget {
  const EditorShellPage({super.key});

  @override
  ConsumerState<EditorShellPage> createState() => _EditorShellPageState();
}

class _EditorShellPageState extends ConsumerState<EditorShellPage> {
  Timer? _toastTimer;
  String? _toastMessage;
  bool _toastIsError = false;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _flashToast(String message, {required bool isError}) {
    _toastTimer?.cancel();
    setState(() {
      _toastMessage = message;
      _toastIsError = isError;
    });
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _toastMessage = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final workspaceMode = state.workspaceMode;
    final notifier = ref.read(editorNotifierProvider.notifier);

    ref.listen(editorNotifierProvider.select((s) => s.errorMessage),
        (prev, next) {
      if (next != null) {
        _flashToast(next, isError: true);
      }
    });

    ref.listen(editorNotifierProvider.select((s) => s.statusMessage),
        (prev, next) {
      if (next != null) {
        _flashToast(next, isError: false);
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
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              MacosWindow(
                titleBar: const TitleBar(
                  title: Text('RPG Map Editor'),
                ),
                child: MacosScaffold(
                  toolBar: buildMapEditorToolbar(context, ref),
                  children: [
                    ResizablePane.noScrollBar(
                      key: const ValueKey('editor_left_pane'),
                      resizableSide: ResizableSide.right,
                      minSize: 220,
                      maxSize: 520,
                      startSize: 340,
                      decoration: BoxDecoration(
                        color: EditorChrome.panelBackground(context),
                      ),
                      child: Column(
                        children: [
                          const Expanded(
                            child: ProjectExplorerPanel(),
                          ),
                          const EditorHorizontalDivider(),
                          ResizablePane.noScrollBar(
                            key: const ValueKey('editor_surface_library_pane'),
                            resizableSide: ResizableSide.top,
                            minSize: 160,
                            maxSize: 560,
                            startSize: 420,
                            decoration: BoxDecoration(
                              color: EditorChrome.panelBackground(context),
                            ),
                            child: const TerrainEditorPanel(),
                          ),
                        ],
                      ),
                    ),
                    ContentArea(
                      builder: (context, scrollController) {
                        return ColoredBox(
                          color: EditorChrome.mapCanvasViewportBackground(context),
                          child: Column(
                            children: const [
                              Expanded(
                                child: EditorCanvasHost(),
                              ),
                              StatusBar(),
                            ],
                          ),
                        );
                      },
                    ),
                    ResizablePane.noScrollBar(
                      key: const ValueKey('editor_right_pane'),
                      resizableSide: ResizableSide.left,
                      minSize: 200,
                      maxSize: 600,
                      startSize: 320,
                      decoration: BoxDecoration(
                        color: EditorChrome.panelBackground(context),
                      ),
                      child: workspaceMode == EditorWorkspaceMode.map
                          ? const MapInspectorPanel()
                          : const TilesetPalettePanel(),
                    ),
                  ],
                ),
              ),
              if (_toastMessage != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 40,
                  child: _EditorToastBanner(
                    message: _toastMessage!,
                    isError: _toastIsError,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorToastBanner extends StatelessWidget {
  const _EditorToastBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final bg = isError
        ? CupertinoColors.destructiveRed.resolveFrom(context)
        : CupertinoColors.systemGrey.resolveFrom(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          message,
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
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
