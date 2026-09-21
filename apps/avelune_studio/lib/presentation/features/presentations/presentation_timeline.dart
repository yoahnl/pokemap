import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_authoring/map_authoring_presentation_editing.dart';
import '../../../features/presentations/application/presentation_preview_transport.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../theme/studio_tokens.dart';
import 'presentation_view_state.dart';
import 'presentation_clip_labels.dart';
import 'presentation_transport_listenable.dart';

part 'presentation_timeline_clip.dart';
part 'presentation_timeline_track.dart';

class PresentationTimeline extends StatefulWidget {
  const PresentationTimeline({
    super.key,
    required this.asset,
    required this.view,
    required this.transport,
    required this.onCommand,
    required this.changed,
    this.beforeSelection,
  });
  final PresentationCinematicAsset asset;
  final PresentationViewState view;
  final PresentationPreviewTransport transport;
  final ValueChanged<PresentationTimelineClipCommand> onCommand;
  final VoidCallback changed;
  final bool Function()? beforeSelection;
  @override
  State<PresentationTimeline> createState() => _PresentationTimelineState();
}

class _PresentationTimelineState extends State<PresentationTimeline> {
  Offset? origin;
  String? dragId;
  int? dragTrack;
  PresentationTimelineDragKind? kind;
  bool invalid = false;
  PresentationTimelineEditingController get editing => widget.view.editing;
  double get scale => widget.view.pixelsPerSecond;
  double x(int us) => us / 1000000 * scale;
  void begin(
    PresentationClip clip,
    int track,
    PresentationTimelineDragKind mode,
    Offset point,
  ) {
    if (widget.beforeSelection?.call() == false) return;
    if (!editing.isClipEditable(clip.id)) return;
    widget.transport.pause();
    origin = point;
    dragId = clip.id;
    dragTrack = track;
    kind = mode;
    invalid = false;
    editing.beginDrag(clipId: clip.id, kind: mode);
    widget.changed();
    setState(() {});
  }

  void update(Offset point) {
    if (origin == null || dragId == null) return;
    final delta = point - origin!;
    final us = (delta.dx / scale * 1000000).round();
    final targetIndex = dragTrack! + (delta.dy / 36).round();
    final source = editing.sourceClip(dragId!);
    final target = targetIndex >= 0 && targetIndex < widget.asset.tracks.length
        ? widget.asset.tracks[targetIndex]
        : null;
    invalid = target == null || target.kind != source.trackKind;
    if (kind != PresentationTimelineDragKind.move) invalid = false;
    final selection = kind == PresentationTimelineDragKind.move
        ? editing.selectedClipIds.map(editing.sourceClip)
        : [source];
    for (final clip in selection) {
      final start =
          clip.startUs +
          (kind == PresentationTimelineDragKind.trimEnd ? 0 : us);
      final end =
          clip.endUs +
          (kind == PresentationTimelineDragKind.trimStart ? 0 : us);
      if (start < 0 ||
          end > widget.asset.durationUs ||
          (clip is! PresentationMarkerClip && end <= start)) {
        invalid = true;
      }
    }
    if (!invalid) editing.updateDrag(deltaUs: us, targetTrackId: target?.id);
    widget.view.actionError = invalid
        ? 'Déplacement refusé : limites temporelles ou piste incompatible.'
        : null;
    setState(() {});
  }

  void finish() {
    if (origin == null) return;
    if (invalid) {
      editing.cancelDrag();
    } else {
      try {
        widget.onCommand(editing.finishDrag());
      } on StateError {
        editing.cancelDrag();
      }
    }
    origin = null;
    dragId = null;
    kind = null;
    widget.changed();
    setState(() {});
  }

  void cancel() {
    editing.cancelDrag();
    origin = null;
    dragId = null;
    kind = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {const SingleActivator(LogicalKeyboardKey.escape): cancel},
    child: StudioPanel(
      compact: true,
      title: 'Timeline · temps absolu',
      actions: [
        StudioTool(
          label: 'Copier les clips',
          icon: Icons.copy_outlined,
          onPressed: editing.selectedClipIds.isEmpty
              ? null
              : () {
                  editing.copySelection();
                  setState(() {});
                },
        ),
        StudioTool(
          label: 'Coller à la tête de lecture',
          icon: Icons.paste,
          onPressed: editing.hasClipboard
              ? () =>
                    command(() => editing.paste(atUs: widget.transport.timeUs))
              : null,
        ),
        StudioTool(
          label: 'Dupliquer les clips',
          icon: Icons.control_point_duplicate,
          onPressed: editing.canEditSelection
              ? () => command(editing.duplicateSelection)
              : null,
        ),
        StudioTool(
          label: 'Réduire la timeline',
          icon: Icons.remove,
          onPressed: () {
            widget.view.pixelsPerSecond = math.max(10, scale / 1.3);
            setState(() {});
          },
        ),
        StudioTool(
          label: 'Agrandir la timeline',
          icon: Icons.add,
          onPressed: () {
            widget.view.pixelsPerSecond = math.min(400, scale * 1.3);
            setState(() {});
          },
        ),
      ],
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: SizedBox(
                height: math.max(
                  constraints.maxHeight,
                  34 + widget.asset.tracks.length * 36.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 105,
                      child: Column(
                        children: [
                          const SizedBox(height: 30),
                          for (final track in widget.asset.tracks)
                            SizedBox(
                              height: 36,
                              child: InkWell(
                                onTap: () => editTrack(track),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    track.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: widget.view.timelineScroll,
                        child: SizedBox(
                          width: math.max(
                            constraints.maxWidth - 105,
                            x(widget.asset.durationUs) + 16,
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 0,
                                right: 0,
                                height: 26,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (event) => widget.transport.seek(
                                    (event.localPosition.dx / scale * 1000000)
                                        .round(),
                                  ),
                                  child: Stack(
                                    children: [
                                      for (
                                        int i = 0;
                                        i <= widget.asset.durationUs ~/ 1000000;
                                        i++
                                      )
                                        Positioned(
                                          left: i * scale,
                                          child: Text(
                                            '${i}s',
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              for (final track in widget.asset.tracks.indexed)
                                for (final clip in track.$2.clips)
                                  bar(context, clip, track.$1),
                              AnimatedBuilder(
                                animation: PresentationTransportListenable(
                                  widget.transport,
                                ),
                                builder: (context, _) => Positioned(
                                  left: x(widget.transport.timeUs),
                                  top: 24,
                                  bottom: 0,
                                  child: IgnorePointer(
                                    child: Container(
                                      width: 1,
                                      color: StudioColors.of(
                                        context,
                                      ).canvasSelection,
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
          ),
        ),
      ],
    ),
  );
}
