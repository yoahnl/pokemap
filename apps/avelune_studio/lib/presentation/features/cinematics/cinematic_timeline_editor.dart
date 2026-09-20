import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/cinematics/application/cinematic_preview_transport.dart';
import '../../shared/widgets/layout/studio_graph_card.dart';
import '../../shared/widgets/layout/studio_timeline_clip.dart';
import 'cinematic_labels.dart';
import 'cinematic_view_state.dart';
import 'cinematic_transport_bar.dart';
import 'cinematic_timeline_painter.dart';

part 'cinematic_timeline_gestures.dart';

class CinematicTimelineEditor extends StatefulWidget {
  const CinematicTimelineEditor({
    super.key,
    required this.asset,
    required this.view,
    required this.transport,
    required this.changed,
    required this.onSelect,
    required this.onMove,
    required this.onDuration,
    required this.onPlay,
    this.beforeSelection,
  });
  final CinematicAsset asset;
  final CinematicViewState view;
  final CinematicPreviewTransport transport;
  final VoidCallback changed, onPlay;
  final bool Function()? beforeSelection;
  final ValueChanged<String> onSelect;
  final ValueChanged<int> onMove;
  final void Function(String, int) onDuration;
  @override
  State<CinematicTimelineEditor> createState() =>
      _CinematicTimelineEditorState();
}

class _CinematicTimelineEditorState extends State<CinematicTimelineEditor> {
  String? dragging, resizing;
  double delta = 0;
  int? insertion, draftDuration;
  final focus = FocusNode();
  void mutate(VoidCallback update) => setState(update);
  void cancel() => setState(() {
    dragging = null;
    resizing = null;
    insertion = null;
    draftDuration = null;
    delta = 0;
  });
  @override
  void didUpdateWidget(CinematicTimelineEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) {
      dragging = null;
      resizing = null;
      insertion = null;
      draftDuration = null;
    }
  }

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.view.timelineScale;
    final current = widget.asset;
    final staged = draftDuration == null
        ? current
        : current.copyWith(
            timeline: CinematicTimeline(
              steps: [
                for (final step in current.timeline.steps)
                  if (step.id == resizing)
                    CinematicTimelineStep.fromJson({
                      ...step.toJson(),
                      'durationMs': draftDuration,
                    })
                  else
                    step,
              ],
            ),
          );
    final layout = buildCinematicTimelineTimeLayoutReadModel(staged);
    final original = buildCinematicTimelineTimeLayoutReadModel(current);
    final colors = Theme.of(context).colorScheme;
    final rowHeight = math.max(
      42.0,
      MediaQuery.textScalerOf(context).scale(30),
    );
    return Focus(
      focusNode: focus,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          cancel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: StudioGraphCard(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final labelWidth = constraints.maxWidth < 500 ? 90.0 : 140.0;
            fitOnce(
              constraints.maxWidth - labelWidth - 32,
              layout.totalDurationMs,
            );
            final width = math.max(
              constraints.maxWidth - labelWidth - 12,
              layout.totalDurationMs * scale + 32,
            );
            final height = math.max(80.0, layout.lanes.length * rowHeight + 30);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CinematicTransportBar(
                  transport: widget.transport,
                  onPlay: widget.onPlay,
                  scale: scale,
                  onScale: (value) {
                    widget.view.timelineScale = value;
                    widget.changed();
                  },
                  onFit: () {
                    widget.view.timelineScale =
                        ((constraints.maxWidth - labelWidth - 32) /
                                math.max(1000, layout.totalDurationMs))
                            .clamp(.008, .5);
                    widget.changed();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Text(
                    insertion == null
                        ? 'Ordre séquentiel · durées d’aperçu estimées'
                        : 'Insérer en position ${insertion! + 1} · aucune attente ajoutée',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: labelWidth,
                          child: Column(
                            children: [
                              const SizedBox(height: 30),
                              for (final lane in layout.lanes)
                                SizedBox(
                                  height: rowHeight,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          cinematicActionIcon(
                                            cinematicLaneAction(lane.laneKind),
                                          ),
                                          size: 15,
                                          color: cinematicActionColor(
                                            context,
                                            cinematicLaneAction(lane.laneKind),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            lane.label,
                                            maxLines: 2,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelSmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: widget.view.timelineScroll,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: width,
                              height: height,
                              child: Stack(
                                key: const ValueKey('cinematic-timeline-track'),
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: CinematicTimelineGrid(
                                        layout: layout,
                                        scale: scale,
                                        rowHeight: rowHeight,
                                        color: colors.outlineVariant,
                                        text: colors.onSurfaceVariant,
                                        textStyle: Theme.of(
                                          context,
                                        ).textTheme.labelSmall!,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    height: 28,
                                    child: GestureDetector(
                                      key: const ValueKey(
                                        'cinematic-timeline-ruler',
                                      ),
                                      behavior: HitTestBehavior.opaque,
                                      onTapDown: (e) => widget.transport.seek(
                                        (e.localPosition.dx / scale).round(),
                                      ),
                                      onHorizontalDragUpdate: (e) =>
                                          widget.transport.seek(
                                            (e.localPosition.dx / scale)
                                                .round(),
                                          ),
                                    ),
                                  ),
                                  for (final lane in layout.lanes.indexed)
                                    for (final block in lane.$2.blocks)
                                      Positioned(
                                        left: block.startMs * scale,
                                        top: 30 + lane.$1 * rowHeight + 3,
                                        width: math.max(
                                          14,
                                          block.visualDurationMs * scale - 2,
                                        ),
                                        height: rowHeight - 6,
                                        child: _clip(block, original, context),
                                      ),
                                  if (insertion case final at?)
                                    Positioned(
                                      left:
                                          (at >= original.blocks.length
                                              ? original.totalDurationMs
                                              : original.blocks[at].startMs) *
                                          scale,
                                      top: 28,
                                      bottom: 0,
                                      width: 3,
                                      child: ColoredBox(color: colors.tertiary),
                                    ),
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: CustomPaint(
                                        painter: CinematicPlayhead(
                                          transport: widget.transport,
                                          scale: scale,
                                          color: colors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
