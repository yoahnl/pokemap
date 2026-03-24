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
    final selectedTileset = notifier.getSelectedTilesetEntry();
    final workspaceTitle = switch (workspaceMode) {
      EditorWorkspaceMode.map => state.activeMap?.name ?? 'Map Workspace',
      EditorWorkspaceMode.tileset => selectedTileset?.name ?? 'Tileset Studio',
    };
    final workspaceSubtitle = switch (workspaceMode) {
      EditorWorkspaceMode.map => state.activeMap == null
          ? 'Open a map to start building your world.'
          : '${state.activeMap!.size.width} x ${state.activeMap!.size.height} tiles  •  ${state.activeMap!.layers.length} layers',
      EditorWorkspaceMode.tileset => selectedTileset == null
          ? 'Select a tileset to browse and curate your library.'
          : 'Visual library editing for tiles, elements and groups.',
    };

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
              DecoratedBox(
                decoration: BoxDecoration(
                  color: EditorChrome.windowBackground(context),
                ),
                child: MacosWindow(
                  child: MacosScaffold(
                    toolBar: buildMapEditorToolbar(context, ref),
                    children: [
                      ResizablePane.noScrollBar(
                        key: const ValueKey('editor_left_pane'),
                        resizableSide: ResizableSide.right,
                        minSize: 240,
                        maxSize: 520,
                        startSize: 344,
                        decoration: BoxDecoration(
                          color: EditorChrome.leftSidebarBackground(context),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
                          child: Column(
                            children: [
                              const Expanded(
                                child: ProjectExplorerPanel(),
                              ),
                              const SizedBox(height: 14),
                              ResizablePane.noScrollBar(
                                key: const ValueKey(
                                  'editor_surface_library_pane',
                                ),
                                resizableSide: ResizableSide.top,
                                minSize: 160,
                                maxSize: 560,
                                startSize: 420,
                                decoration: const BoxDecoration(
                                  color: MacosColors.transparent,
                                ),
                                child: EditorPaneSurface(
                                  radius: 26,
                                  tint: const Color(0xFF33261D),
                                  child: const TerrainEditorPanel(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ContentArea(
                        builder: (context, scrollController) {
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: EditorChrome.workspaceGradient(context),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      20,
                                      20,
                                      10,
                                    ),
                                    child: EditorPaneSurface(
                                      radius: 30,
                                      tint: const Color(0xFF202A38),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          16,
                                          16,
                                          16,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _WorkspaceStageHeader(
                                              title: workspaceTitle,
                                              subtitle: workspaceSubtitle,
                                              workspaceMode: workspaceMode,
                                            ),
                                            const SizedBox(height: 14),
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: EditorChrome
                                                      .workspaceStageGradient(
                                                    context,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Color(0x16000000),
                                                      blurRadius: 14,
                                                      offset: Offset(0, 6),
                                                    ),
                                                  ],
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(14),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      20,
                                                    ),
                                                    child: DecoratedBox(
                                                      decoration: BoxDecoration(
                                                        color: EditorChrome
                                                            .mapCanvasViewportBackground(
                                                          context,
                                                        ),
                                                      ),
                                                      child:
                                                          const EditorCanvasHost(),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const StatusBar(),
                              ],
                            ),
                          );
                        },
                      ),
                      ResizablePane.noScrollBar(
                        key: const ValueKey('editor_right_pane'),
                        resizableSide: ResizableSide.left,
                        minSize: 240,
                        maxSize: 620,
                        startSize: 336,
                        decoration: BoxDecoration(
                          color: EditorChrome.rightSidebarBackground(context),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 18, 16, 18),
                          child: EditorPaneSurface(
                            radius: 28,
                            tint: const Color(0xFF1F2837),
                            child: workspaceMode == EditorWorkspaceMode.map
                                ? const MapInspectorPanel()
                                : const TilesetPalettePanel(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_toastMessage != null)
                Positioned(
                  right: 24,
                  bottom: 72,
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
    final tint = isError ? const Color(0xFF2A1D23) : const Color(0xFF1B2432);
    final accent = isError ? const Color(0xFFE7A7AF) : const Color(0xFF8EBEFF);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: EditorPaneSurface(
        radius: 18,
        tint: tint,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: MacosIcon(
                  isError
                      ? CupertinoIcons.exclamationmark_triangle_fill
                      : CupertinoIcons.check_mark_circled_solid,
                  color: accent,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceStageHeader extends StatelessWidget {
  const _WorkspaceStageHeader({
    required this.title,
    required this.subtitle,
    required this.workspaceMode,
  });

  final String title;
  final String subtitle;
  final EditorWorkspaceMode workspaceMode;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    final accent = EditorChrome.activeAccent(context);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: MacosIcon(
            workspaceMode == EditorWorkspaceMode.map
                ? CupertinoIcons.map
                : CupertinoIcons.square_grid_2x2,
            color: accent,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: label,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtle,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: CupertinoColors.systemFill.resolveFrom(context),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: EditorChrome.subtleSeparator(context),
            ),
          ),
          child: Text(
            workspaceMode == EditorWorkspaceMode.map ? 'Scene' : 'Library',
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
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
