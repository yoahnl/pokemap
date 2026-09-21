import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/cinematics/application/cinematic_workspace_controller.dart';
import '../../../features/dialogues/application/dialogue_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../events/event_map_loader.dart';
import '../map_workspace/map_workspace_visuals.dart';
import '../narrative/narrative_name_dialog.dart';
import 'cinematic_view_state.dart';
import 'cinematic_library.dart';
import 'cinematic_map_model.dart';
import 'cinematic_map_scene.dart';
import 'cinematic_timeline_editor.dart';
import 'cinematic_inspector.dart';
import 'cinematic_action_palette.dart';
import 'cinematic_document_toolbar.dart';
import 'cinematic_preview_status.dart';
import 'cinematic_workspace_visuals.dart';
import '../../theme/studio_dialogue_theme.dart';

part 'cinematic_page_commands.dart';
part 'cinematic_page_map.dart';

part 'cinematic_page_timeline.dart';
part 'cinematic_page_header.dart';

class CinematicWorkspacePage extends StatefulWidget {
  const CinematicWorkspacePage({
    super.key,
    required this.controller,
    required this.views,
    required this.loader,
    required this.visuals,
    required this.onBack,
    this.backLabel = 'Histoire',
    required this.onDialogue,
    required this.onLocate,
    this.dialogues,
    this.onPresentations,
  });
  final CinematicWorkspaceController controller;
  final CinematicViewStore views;
  final EventMapLoader loader;
  final MapWorkspaceVisuals visuals;
  final VoidCallback onBack;
  final String backLabel;
  final ValueChanged<String> onDialogue;
  final Future<String?> Function(String) onLocate;
  final DialogueWorkspaceController? dialogues;
  final VoidCallback? onPresentations;
  @override
  State<CinematicWorkspacePage> createState() => _CinematicWorkspacePageState();
}

class _CinematicWorkspacePageState extends State<CinematicWorkspacePage> {
  CinematicWorkspaceController get controller => widget.controller;
  CinematicViewState? get view => controller.activeId == null
      ? null
      : widget.views.forAsset(controller.activeId!);
  CinematicMapModel? model;
  MapData? loadedMap;
  String? loadingMapId, mapError;
  int loadGeneration = 0;
  CinematicTimelineClipboard? clipboard;
  Object? mediaIdentity;
  @override
  void initState() {
    super.initState();
    controller.flushEdits = flush;
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  bool flush() {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    return view?.error == null;
  }

  @override
  void dispose() {
    controller.flushEdits = null;
    loadGeneration++;
    controller.transport.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = controller.active, state = view;
    if (session != null) {
      state!.reconcile(session.asset);
      prepareMap(session.asset);
    }
    return StudioDialogueTheme(
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, meta: true): save,
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): save,
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 1120 ||
                MediaQuery.textScalerOf(context).scale(14) > 20;
            final small = constraints.maxHeight < 650;
            final library = CinematicLibrary(
              controller: controller,
              views: widget.views,
              changed: refresh,
              onOpen: open,
              onCreate: create,
              loader: widget.loader,
              visuals: widget.visuals,
            );
            final inspector = state == null
                ? null
                : CinematicInspector(
                    controller: controller,
                    view: state,
                    model: model,
                    changed: refresh,
                    onAdd: addAction,
                    previewContent: CinematicPreviewStatus(
                      controller: controller,
                      dialogues: widget.dialogues,
                    ),
                    onDialogue: (id) {
                      if (flush()) {
                        controller.transport.pause();
                        widget.onDialogue(id);
                      }
                    },
                    onLocate: (id) async => flush()
                        ? widget.onLocate(id)
                        : 'Corrigez la saisie avant de changer de page.',
                  );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header(small),
                if (state?.error ??
                        state?.actionError ??
                        state?.spatialError ??
                        controller.error ??
                        session?.readOnlyReason
                    case final error?)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 80),
                      child: SingleChildScrollView(
                        child: StudioNotice(error, isError: true),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!compact ||
                            (state?.libraryOpen == true &&
                                state?.inspectorOpen != true) ||
                            session == null) ...[
                          SizedBox(width: compact ? 230 : 240, child: library),
                          const SizedBox(width: 8),
                        ],
                        if (compact &&
                            state?.inspectorOpen == true &&
                            inspector != null)
                          Expanded(child: inspector)
                        else
                          Expanded(
                            child: session == null
                                ? const Center(
                                    child: Text(
                                      'Ouvrez une cinématique ou créez une séquence sur carte.',
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      CinematicDocumentToolbar(
                                        controller: controller,
                                        onDuplicate: duplicate,
                                        onDelete: delete,
                                        onReload: reload,
                                        onArchive: archive,
                                      ),
                                      Expanded(
                                        flex: (state!.mapShare * 100).round(),
                                        child: mapContent(),
                                      ),
                                      MouseRegion(
                                        cursor: SystemMouseCursors.resizeRow,
                                        child: GestureDetector(
                                          key: const ValueKey(
                                            'cinematic-pane-divider',
                                          ),
                                          behavior: HitTestBehavior.opaque,
                                          onVerticalDragUpdate: (e) {
                                            state.mapShare =
                                                (state.mapShare +
                                                        e.delta.dy /
                                                            constraints
                                                                .maxHeight)
                                                    .clamp(.3, .75);
                                            refresh();
                                          },
                                          child: const SizedBox(
                                            height: 10,
                                            child: Center(
                                              child: Icon(
                                                Icons.drag_handle,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: ((1 - state.mapShare) * 100)
                                            .round(),
                                        child: timeline(session.asset, state),
                                      ),
                                    ],
                                  ),
                          ),
                        if (!compact && inspector != null) ...[
                          const SizedBox(width: 8),
                          SizedBox(width: 292, child: inspector),
                        ],
                      ],
                    ),
                  ),
                ),
                if (session != null && (compact || small))
                  SizedBox(
                    height: MediaQuery.textScalerOf(context).scale(32) + 36,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: CinematicActionPalette(onAdd: addAction),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
