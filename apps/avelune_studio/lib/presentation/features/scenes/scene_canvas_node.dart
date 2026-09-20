import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/theme/studio_tokens.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_canvas_types.dart';

Color sceneNodeColor(BuildContext context, SceneNodeKind kind) {
  final tokens = StudioColors.of(context);
  return switch (kind) {
    SceneNodeKind.start || SceneNodeKind.merge => tokens.success,
    SceneNodeKind.end => Theme.of(context).colorScheme.error,
    SceneNodeKind.condition || SceneNodeKind.branchByOutcome => tokens.warning,
    SceneNodeKind.yarnDialogue => tokens.featureAccent,
    _ => tokens.canvasSelection,
  };
}

Color sceneBlockColor(BuildContext context, SceneNodeKind kind) =>
    sceneNodeColor(context, kind);
IconData sceneBlockIcon(SceneNodeKind kind) => switch (kind) {
  SceneNodeKind.start => Icons.play_arrow_rounded,
  SceneNodeKind.end => Icons.flag_outlined,
  SceneNodeKind.condition => Icons.call_split,
  SceneNodeKind.yarnDialogue => Icons.chat_bubble_outline,
  SceneNodeKind.action => Icons.bolt,
  SceneNodeKind.battle => Icons.sports_martial_arts,
  _ => Icons.account_tree_outlined,
};

class SceneCanvasNode extends StatefulWidget {
  const SceneCanvasNode({
    super.key,
    required this.node,
    required this.size,
    required this.selected,
    required this.highlighted,
    required this.onSelect,
    required this.onStart,
    required this.onMove,
    required this.onEnd,
    required this.onCancel,
    this.summary,
  });
  final SceneNode node;
  final Size size;
  final bool selected, highlighted;
  final VoidCallback onSelect, onStart, onEnd, onCancel;
  final ValueChanged<Offset> onMove;
  final String? summary;

  @override
  State<SceneCanvasNode> createState() => _SceneCanvasNodeState();
}

class _SceneCanvasNodeState extends State<SceneCanvasNode> {
  bool hovered = false, focused = false;
  bool dragging = false;

  @override
  Widget build(BuildContext context) {
    final node = widget.node, size = widget.size;
    final selected = widget.selected, highlighted = widget.highlighted;
    final onSelect = widget.onSelect, onStart = widget.onStart;
    final onMove = widget.onMove, onEnd = widget.onEnd;
    final onCancel = widget.onCancel, summary = widget.summary;
    final colors = Theme.of(context).colorScheme;
    final tone = sceneNodeColor(context, node.kind);
    final terminal =
        node.kind == SceneNodeKind.start || node.kind == SceneNodeKind.end;
    return GestureDetector(
      key: ValueKey('scene-graph-node-drag-target-${node.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      onPanStart: (event) {
        dragging = event.kind != PointerDeviceKind.trackpad;
        if (dragging) onStart();
      },
      onPanUpdate: (event) {
        if (dragging) onMove(event.delta);
      },
      onPanEnd: (_) {
        if (dragging) onEnd();
        dragging = false;
      },
      onPanCancel: () {
        if (dragging) onCancel();
        dragging = false;
      },
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.grab,
        onShowHoverHighlight: (value) => setState(() => hovered = value),
        onShowFocusHighlight: (value) => setState(() => focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onSelect();
              return null;
            },
          ),
        },
        child: SizedBox.fromSize(
          size: size,
          child: Material(
            key: ValueKey('scene-graph-node-${node.id}'),
            color: Color.alphaBlend(
              tone.withValues(alpha: hovered ? .18 : .10),
              colors.surface,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                terminal ? 28 : StudioMetrics.panelRadius,
              ),
              side: BorderSide(
                color: selected
                    ? colors.primary
                    : focused
                    ? StudioColors.of(context).canvasSelection
                    : highlighted
                    ? StudioColors.of(context).success
                    : tone.withValues(alpha: .65),
                width: selected || highlighted || focused ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: terminal
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: terminal
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      Icon(
                        switch (node.kind) {
                          SceneNodeKind.start => Icons.play_arrow_rounded,
                          SceneNodeKind.end => Icons.flag_outlined,
                          SceneNodeKind.condition => Icons.call_split,
                          SceneNodeKind.yarnDialogue =>
                            Icons.chat_bubble_outline,
                          SceneNodeKind.action => Icons.bolt,
                          SceneNodeKind.battle => Icons.sports_martial_arts,
                          _ => Icons.account_tree_outlined,
                        },
                        color: tone,
                        size: 18,
                      ),
                      if (!terminal) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            sceneKindLabel(node.kind),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: tone),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    node.title ?? sceneKindLabel(node.kind),
                    maxLines: terminal ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: terminal ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!terminal && summary != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SceneCanvasPort extends StatelessWidget {
  const SceneCanvasPort({
    super.key,
    required this.label,
    required this.color,
    this.output = false,
    this.compatible = false,
    this.hovered = false,
    this.disabled = false,
    this.onStart,
    this.onMove,
    this.onEnd,
    this.onCancel,
  });
  final String label;
  final Color color;
  final bool output, compatible, hovered, disabled;
  final VoidCallback? onStart, onEnd, onCancel;
  final ValueChanged<Offset>? onMove;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: disabled ? '$label — déjà reliée' : label,
    child: Semantics(
      label: label,
      button: output,
      enabled: !disabled,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: disabled ? null : (_) => onStart?.call(),
        onPointerMove: disabled ? null : (e) => onMove?.call(e.position),
        onPointerUp: disabled ? null : (_) => onEnd?.call(),
        onPointerCancel: (_) => onCancel?.call(),
        child: MouseRegion(
          cursor: output && !disabled
              ? SystemMouseCursors.precise
              : MouseCursor.defer,
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: Container(
                width: hovered ? 18 : 12,
                height: hovered ? 18 : 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: disabled ? .25 : .9),
                  border: Border.all(
                    color: compatible || hovered
                        ? Theme.of(context).colorScheme.onSurface
                        : color,
                    width: compatible ? 2 : 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
