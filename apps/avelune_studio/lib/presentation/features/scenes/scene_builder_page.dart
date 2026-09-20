import 'dart:async';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_name_dialog.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_tool.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_page_header.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/application/scene_edit_session.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_graph_canvas.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_view_state.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_library_panel.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_inspector.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_preview_panel.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_payload_picker.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_linked_document.dart';
export 'package:avelune_studio/presentation/features/scenes/scene_builder_view_state.dart';

part 'scene_builder_commands.dart';
part 'scene_builder_header.dart';

class SceneBuilderPage extends StatefulWidget {
  const SceneBuilderPage({
    super.key,
    required this.controller,
    required this.views,
    required this.onBack,
    this.narrative,
    this.onTest,
  });
  final SceneWorkspaceController controller;
  final SceneBuilderViewStore views;
  final NarrativeWorkspaceController? narrative;
  final VoidCallback onBack;
  final VoidCallback? onTest;
  @override
  State<SceneBuilderPage> createState() => _SceneBuilderPageState();
}

class _SceneBuilderPageState extends State<SceneBuilderPage> {
  final documents = SceneLinkedDocuments();
  SceneBuilderViewState? get view => widget.controller.active == null
      ? null
      : widget.views.forScene(widget.controller.active!.current.id);
  List<SceneBlockDragData> get blocks => [
    for (final kind in SceneNodeKind.values.where(
      (kind) => kind != SceneNodeKind.start,
    ))
      SceneBlockDragData(kind: kind, label: sceneBlockLabel(kind)),
  ];
  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.controller.active;
    final state = view;
    if (session != null) state!.invalidate(session.current);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 1050 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        final small = constraints.maxHeight < 650;
        final library = SceneLibraryPanel(
          controller: widget.controller,
          views: widget.views,
          blocks: blocks,
          onAdd: (block) => add(block, state?.viewport.center ?? Offset.zero),
          onCreate: create,
          changed: refresh,
        );
        final inspector = session == null
            ? null
            : SceneInspector(
                session: session,
                project: widget.controller.project,
                documents: documents,
                narrative: widget.narrative,
                nodeId: state!.nodeId,
                edgeId: state.edgeId,
                changed: refresh,
                onDelete: delete,
                onDuplicate: duplicate,
                onDocument: (node) => documents.open(
                  context,
                  node,
                  widget.controller.project,
                  widget.narrative,
                ),
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._header(context, compact, small, session, state),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!compact || session == null || state!.libraryOpen) ...[
                      SizedBox(width: compact ? 270 : 240, child: library),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: session == null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.account_tree_outlined,
                                    size: 54,
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Ouvrez une scène ou créez votre première rencontre.',
                                  ),
                                  const SizedBox(height: 16),
                                  StudioButton(
                                    label: 'Créer une scène',
                                    icon: Icons.add,
                                    onPressed: create,
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    4,
                                    8,
                                    12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          session.current.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                      ),
                                      if (!compact)
                                        Text(
                                          session.saving
                                              ? 'Enregistrement…'
                                              : session.dirty
                                              ? 'Modifiée · en mémoire'
                                              : 'Enregistrée',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: SceneGraphCanvas(
                                    key: ValueKey(session.current.id),
                                    scene: session.current,
                                    viewport: state!.viewport,
                                    selectedNodeId: state.nodeId,
                                    selectedEdgeId: state.edgeId,
                                    onSelectNode: (id) {
                                      state.nodeId = id;
                                      state.edgeId = null;
                                      refresh();
                                    },
                                    onSelectEdge: (id) {
                                      state.edgeId = id;
                                      state.nodeId = null;
                                      refresh();
                                    },
                                    onClearSelection: () {
                                      state.nodeId = null;
                                      state.edgeId = null;
                                      refresh();
                                    },
                                    onMoveNode: (id, point) {
                                      session.move(id, point.dx, point.dy);
                                      refresh();
                                    },
                                    onConnect: (from, port, to) {
                                      session.connect(from, port, to);
                                      refresh();
                                    },
                                    onAdd:
                                        (
                                          block,
                                          point, {
                                          fromNodeId,
                                          fromPortId,
                                        }) => unawaited(
                                          add(
                                            block,
                                            point,
                                            fromNodeId: fromNodeId,
                                            fromPortId: fromPortId,
                                          ),
                                        ),
                                    onDelete: delete,
                                    onDuplicate: duplicate,
                                    onUndo: () {
                                      session.restore(redo: false);
                                      refresh();
                                    },
                                    onRedo: () {
                                      session.restore(redo: true);
                                      refresh();
                                    },
                                    onSave: () =>
                                        unawaited(widget.controller.save()),
                                    availableBlocks: blocks,
                                    highlightedNodeIds:
                                        state.preview?.trace
                                            .map((e) => e.nodeId)
                                            .toSet() ??
                                        {},
                                    highlightedEdgeIds: {
                                      for (final trace
                                          in state.preview?.trace ??
                                              <SceneDryRunTraceEntry>[])
                                        for (final edge
                                            in session.current.graph.edges
                                                .where(
                                                  (e) =>
                                                      e.fromNodeId ==
                                                          trace.nodeId &&
                                                      e.fromPortId ==
                                                          trace.outputPortId,
                                                ))
                                          edge.id,
                                    },
                                    nodeSummary: (node) => _summary(
                                      node,
                                      widget.controller.project,
                                      session.current,
                                    ),
                                  ),
                                ),
                                if (state.previewOpen) ...[
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: small ? 180 : 230,
                                    child: ScenePreviewPanel(
                                      scene: session.current,
                                      view: state,
                                      changed: refresh,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                    if (inspector != null &&
                        (!compact || state!.inspectorOpen)) ...[
                      const SizedBox(width: 8),
                      SizedBox(width: compact ? 300 : 288, child: inspector),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
