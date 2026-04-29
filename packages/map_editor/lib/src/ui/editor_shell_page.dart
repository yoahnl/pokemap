import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';
import 'package:map_editor/src/ui/panels/narrative_inspector_panel.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';
import 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';
import 'package:map_editor/src/ui/shared/status_bar.dart';
import 'package:map_editor/src/ui/shared/top_toolbar.dart';

import '../features/editor/state/editor_notifier.dart';
import '../features/editor/state/editor_selectors.dart';
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
  bool _didAttemptProjectAutoRestore = false;

  /// When false, the right ResizablePane (map / tileset / narrative inspector) is omitted so the center stage uses full width.
  bool _rightInspectorVisible = true;

  @override
  void initState() {
    super.initState();
    // Provider mutations are intentionally deferred after the first frame:
    // auto-restore loads a project (state mutation), and Riverpod disallows
    // mutating providers during build/init lifecycle phases.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didAttemptProjectAutoRestore) {
        return;
      }
      _didAttemptProjectAutoRestore = true;
      await ref
          .read(editorNotifierProvider.notifier)
          .restoreLastOpenedProjectIfAny();
    });
  }

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
    final shell = ref.watch(editorShellSnapshotProvider);
    final workspaceMode = shell.workspaceMode;
    final notifier = ref.read(editorNotifierProvider.notifier);
    final supportsRightInspector = switch (workspaceMode) {
      EditorWorkspaceMode.pokedex || EditorWorkspaceMode.surfaceStudio => false,
      _ => true,
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

    final isNarrativeWorkspace = switch (workspaceMode) {
      EditorWorkspaceMode.globalStory ||
      EditorWorkspaceMode.step ||
      EditorWorkspaceMode.cutscene ||
      EditorWorkspaceMode.dialogue =>
        true,
      _ => false,
    };

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
              if (!shell.canUndoMap) return null;
              notifier.undoMap();
              return null;
            },
          ),
          _RedoIntent: CallbackAction<_RedoIntent>(
            onInvoke: (_) {
              if (_isTextInputFocused()) return null;
              if (!shell.canRedoMap) return null;
              notifier.redoMap();
              return null;
            },
          ),
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) {
              if (_isTextInputFocused()) return null;
              if (!shell.canSaveMap) return null;
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
                decoration: EditorChrome.appRootDecoration(context),
                child: Stack(
                  children: [
                    const Positioned(
                      left: -120,
                      top: -120,
                      child: _AmbientGlow(
                        size: 460,
                        color: EditorChrome.accentPrimary,
                        opacity: 0.14,
                      ),
                    ),
                    const Positioned(
                      right: -100,
                      top: 40,
                      child: _AmbientGlow(
                        size: 400,
                        color: EditorChrome.accentLilac,
                        opacity: 0.1,
                      ),
                    ),
                    const Positioned(
                      right: -120,
                      top: 90,
                      child: _AmbientGlow(
                        size: 420,
                        color: EditorChrome.accentWarm,
                        opacity: 0.13,
                      ),
                    ),
                    const Positioned(
                      left: 140,
                      bottom: -160,
                      child: _AmbientGlow(
                        size: 520,
                        color: EditorChrome.accentJade,
                        opacity: 0.1,
                      ),
                    ),
                    const Positioned(
                      right: 220,
                      bottom: -140,
                      child: _AmbientGlow(
                        size: 420,
                        color: EditorChrome.accentCoral,
                        opacity: 0.09,
                      ),
                    ),
                    MacosWindow(
                      child: MacosScaffold(
                        backgroundColor: const Color(0x00000000),
                        toolBar: buildMapEditorToolbar(context, ref),
                        children: [
                          ResizablePane.noScrollBar(
                            key: ValueKey<bool>(isNarrativeWorkspace),
                            resizableSide: ResizableSide.right,
                            minSize: isNarrativeWorkspace ? 200 : 240,
                            maxSize: isNarrativeWorkspace ? 460 : 520,
                            startSize: isNarrativeWorkspace ? 268 : 344,
                            decoration: const BoxDecoration(
                              color: MacosColors.transparent,
                            ),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                isNarrativeWorkspace ? 12 : 16,
                                isNarrativeWorkspace ? 16 : 18,
                                isNarrativeWorkspace ? 10 : 12,
                                isNarrativeWorkspace ? 16 : 18,
                              ),
                              child: const ProjectExplorerPanel(),
                            ),
                          ),
                          ContentArea(
                            builder: (context, scrollController) {
                              return Column(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        isNarrativeWorkspace ? 10 : 18,
                                        isNarrativeWorkspace ? 12 : 18,
                                        isNarrativeWorkspace ? 10 : 18,
                                        isNarrativeWorkspace ? 6 : 8,
                                      ),
                                      child: EditorIsland(
                                        radius: 36,
                                        tint: EditorChrome.islandCoolTint,
                                        child: Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            isNarrativeWorkspace ? 12 : 18,
                                            isNarrativeWorkspace ? 12 : 18,
                                            isNarrativeWorkspace ? 12 : 18,
                                            isNarrativeWorkspace ? 10 : 16,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _WorkspaceStageHeader(
                                                title: shell.workspaceTitle,
                                                subtitle:
                                                    shell.workspaceSubtitle,
                                                workspaceMode: workspaceMode,
                                                rightPanelVisible:
                                                    _rightInspectorVisible,
                                                showRightPanelToggle:
                                                    supportsRightInspector,
                                                onToggleRightPanel: () {
                                                  setState(() {
                                                    _rightInspectorVisible =
                                                        !_rightInspectorVisible;
                                                  });
                                                },
                                              ),
                                              SizedBox(
                                                height: isNarrativeWorkspace
                                                    ? 12
                                                    : 18,
                                              ),
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(26),
                                                  child: Padding(
                                                    padding: EdgeInsets.all(
                                                      isNarrativeWorkspace
                                                          ? 8
                                                          : 14,
                                                    ),
                                                    child:
                                                        const EditorCanvasHost(),
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
                              );
                            },
                          ),
                          if (supportsRightInspector && _rightInspectorVisible)
                            ResizablePane.noScrollBar(
                              key: ValueKey<String>(
                                'editor_right_${isNarrativeWorkspace ? 'n' : 'm'}',
                              ),
                              resizableSide: ResizableSide.left,
                              minSize: isNarrativeWorkspace ? 220 : 240,
                              maxSize: 620,
                              startSize: isNarrativeWorkspace ? 292 : 336,
                              decoration: const BoxDecoration(
                                color: MacosColors.transparent,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 18, 16, 18),
                                child: EditorIsland(
                                  radius: 32,
                                  tint: switch (workspaceMode) {
                                    EditorWorkspaceMode.map =>
                                      EditorChrome.islandNeutralTint,
                                    EditorWorkspaceMode.tileset =>
                                      EditorChrome.islandWarmTint,
                                    EditorWorkspaceMode.trainer =>
                                      EditorChrome.islandWarmTint,
                                    EditorWorkspaceMode.pokedex =>
                                      EditorChrome.islandWarmTint,
                                    EditorWorkspaceMode.surfaceStudio =>
                                      EditorChrome.islandCoolTint,
                                    EditorWorkspaceMode.globalStory =>
                                      EditorChrome.islandCoolTint,
                                    EditorWorkspaceMode.step =>
                                      EditorChrome.islandWarmTint,
                                    EditorWorkspaceMode.cutscene =>
                                      EditorChrome.islandNeutralTint,
                                    EditorWorkspaceMode.dialogue =>
                                      EditorChrome.islandCoolTint,
                                  },
                                  child: switch (workspaceMode) {
                                    EditorWorkspaceMode.map =>
                                      const MapInspectorPanel(),
                                    EditorWorkspaceMode.tileset =>
                                      const TilesetPalettePanel(),
                                    EditorWorkspaceMode.trainer =>
                                      const _EmptyWorkspaceInspector(),
                                    // Le Pokédex du lot 13 n'a toujours pas de
                                    // panneau d'inspection dédié :
                                    // pas de détail espèce, pas d'édition.
                                    // On réutilise donc un panneau neutre vide
                                    // pour éviter d'introduire une nouvelle
                                    // structure latérale ou une fausse logique.
                                    EditorWorkspaceMode.pokedex =>
                                      const _EmptyWorkspaceInspector(),
                                    EditorWorkspaceMode.surfaceStudio =>
                                      const _SurfaceWorkspaceInspector(),
                                    EditorWorkspaceMode.globalStory ||
                                    EditorWorkspaceMode.step ||
                                    EditorWorkspaceMode.cutscene ||
                                    EditorWorkspaceMode.dialogue =>
                                      const NarrativeInspectorPanel(),
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
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
    final tint = isError
        ? EditorChrome.errorTint(context)
        : EditorChrome.statusTint(context);
    final accent = isError
        ? EditorChrome.inspectorJoyCoral
        : EditorChrome.inspectorJoyMint;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: EditorIsland(
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(CupertinoColors.white, accent, 0.75)!,
                      Color.lerp(accent, const Color(0xFF102010), 0.35)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.88),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: MacosIcon(
                  isError
                      ? CupertinoIcons.exclamationmark_triangle_fill
                      : CupertinoIcons.check_mark_circled_solid,
                  color: CupertinoColors.white,
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
    required this.rightPanelVisible,
    required this.showRightPanelToggle,
    required this.onToggleRightPanel,
  });

  final String title;
  final String subtitle;
  final EditorWorkspaceMode workspaceMode;
  final bool rightPanelVisible;
  final bool showRightPanelToggle;
  final VoidCallback onToggleRightPanel;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    final chipFill = EditorChrome.chipFill(context);
    final chipAccent = switch (workspaceMode) {
      EditorWorkspaceMode.map => EditorChrome.inspectorJoyHoney,
      EditorWorkspaceMode.tileset => EditorChrome.inspectorJoyLilac,
      EditorWorkspaceMode.trainer => EditorChrome.accentCoral,
      EditorWorkspaceMode.pokedex => EditorChrome.inspectorJoyAmber,
      EditorWorkspaceMode.surfaceStudio => EditorChrome.inspectorJoyCyan,
      EditorWorkspaceMode.globalStory => EditorChrome.inspectorJoyCyan,
      EditorWorkspaceMode.step => EditorChrome.inspectorJoyMint,
      EditorWorkspaceMode.cutscene => EditorChrome.inspectorJoyCoral,
      EditorWorkspaceMode.dialogue => EditorChrome.inspectorJoyBlue,
    };
    final chipAccent2 = switch (workspaceMode) {
      EditorWorkspaceMode.map => EditorChrome.inspectorJoyApricot,
      EditorWorkspaceMode.tileset => EditorChrome.inspectorJoyPlum,
      EditorWorkspaceMode.trainer => EditorChrome.inspectorJoyCoral,
      EditorWorkspaceMode.pokedex => EditorChrome.accentWarm,
      EditorWorkspaceMode.surfaceStudio => EditorChrome.accentJade,
      EditorWorkspaceMode.globalStory => EditorChrome.inspectorJoyBlue,
      EditorWorkspaceMode.step => EditorChrome.accentJade,
      EditorWorkspaceMode.cutscene => EditorChrome.inspectorJoyCoral,
      EditorWorkspaceMode.dialogue => EditorChrome.inspectorJoyCyan,
    };

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(CupertinoColors.white, chipAccent, 0.72)!,
                Color.lerp(chipAccent2, const Color(0xFF1A0A08), 0.38)!,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: chipAccent.withValues(alpha: 0.88),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: MacosIcon(
            switch (workspaceMode) {
              EditorWorkspaceMode.map => CupertinoIcons.map,
              EditorWorkspaceMode.tileset => CupertinoIcons.square_grid_2x2,
              EditorWorkspaceMode.trainer => CupertinoIcons.person_3_fill,
              EditorWorkspaceMode.pokedex => CupertinoIcons.book,
              EditorWorkspaceMode.surfaceStudio => Icons.auto_awesome_motion,
              EditorWorkspaceMode.globalStory => CupertinoIcons.link,
              EditorWorkspaceMode.step => CupertinoIcons.flag,
              EditorWorkspaceMode.cutscene => CupertinoIcons.play_rectangle,
              EditorWorkspaceMode.dialogue => CupertinoIcons.text_bubble,
            },
            color: CupertinoColors.white,
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
        if (showRightPanelToggle) ...[
          MacosTooltip(
            message:
                rightPanelVisible ? 'Hide right panel' : 'Show right panel',
            child: MacosIconButton(
              semanticLabel:
                  rightPanelVisible ? 'Hide right panel' : 'Show right panel',
              icon: MacosIcon(
                rightPanelVisible ? Icons.open_in_full : Icons.close_fullscreen,
                color: label.withValues(alpha: 0.85),
                size: 18,
              ),
              backgroundColor: CupertinoColors.transparent,
              hoverColor: chipAccent.withValues(alpha: 0.12),
              onPressed: onToggleRightPanel,
              boxConstraints: const BoxConstraints(
                minWidth: 34,
                maxWidth: 34,
                minHeight: 34,
                maxHeight: 34,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Color.lerp(chipFill, chipAccent, 0.22),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: chipAccent.withValues(alpha: 0.65),
              width: 1,
            ),
          ),
          child: Text(
            switch (workspaceMode) {
              EditorWorkspaceMode.map => 'Scene',
              EditorWorkspaceMode.tileset => 'Library',
              EditorWorkspaceMode.trainer => 'Trainer',
              EditorWorkspaceMode.pokedex => 'Catalogues',
              EditorWorkspaceMode.surfaceStudio => 'Surface',
              EditorWorkspaceMode.globalStory => 'Global',
              EditorWorkspaceMode.step => 'Step',
              EditorWorkspaceMode.cutscene => 'Cutscene',
              EditorWorkspaceMode.dialogue => 'Dialogue',
            },
            style: TextStyle(
              color: chipAccent,
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

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.4),
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.38, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Rappel produit côté inspecteur (Surface Studio est surtout au centre).
class _SurfaceWorkspaceInspector extends StatelessWidget {
  const _SurfaceWorkspaceInspector();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Ouvrez Surface Studio pour parcourir le catalogue de surfaces animées et les diagnostics (vue centrale).',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Panneau droit volontairement neutre pour les workspaces qui n'ont pas
/// encore d'inspecteur réel.
///
/// Pour le lot 12, cela permet de garder la structure visuelle existante de
/// l'éditeur sans inventer un inspecteur Pokédex artificiel, ni brancher une
/// logique future avant l'heure.
class _EmptyWorkspaceInspector extends StatelessWidget {
  const _EmptyWorkspaceInspector();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Cette section n’a pas encore d’inspecteur dédié.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
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
