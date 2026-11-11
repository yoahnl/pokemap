import 'package:map_core/map_core_domain.dart';

import 'cinematic_preview_transport.dart';

const cinematicTimelineMinimumResizeMs = 1;
const cinematicTimelineMaximumResizeMs = 3600000;

bool cinematicDurationEditable(CinematicTimelineStep step) =>
    switch (step.kind) {
      CinematicTimelineStepKind.actorFace ||
      CinematicTimelineStepKind.marker => false,
      _ => step.durationMs != null,
    };

CinematicTimelineStepKind cinematicLaneAction(CinematicTimelineLaneKind lane) =>
    switch (lane) {
      CinematicTimelineLaneKind.camera => CinematicTimelineStepKind.camera,
      CinematicTimelineLaneKind.actor => CinematicTimelineStepKind.actorMove,
      CinematicTimelineLaneKind.dialogue =>
        CinematicTimelineStepKind.dialogueLine,
      CinematicTimelineLaneKind.fx => CinematicTimelineStepKind.fx,
      CinematicTimelineLaneKind.audio => CinematicTimelineStepKind.music,
      CinematicTimelineLaneKind.transitions => CinematicTimelineStepKind.fade,
      CinematicTimelineLaneKind.timeGlobal => CinematicTimelineStepKind.wait,
      CinematicTimelineLaneKind.other => CinematicTimelineStepKind.marker,
    };

int cinematicResizedDuration(int sourceMs, double delta, double scale) =>
    (sourceMs + delta / scale).round().clamp(
      cinematicTimelineMinimumResizeMs,
      cinematicTimelineMaximumResizeMs,
    );

int cinematicTimelineInsertionIndex(
  CinematicTimelineTimeLayoutReadModel layout,
  double timeMs,
) => layout.blocks
    .where((block) => timeMs >= (block.startMs + block.endMs) / 2)
    .length;

int cinematicTimelineTimeAt(double dx, double scale) => (dx / scale).round();

void seekCinematicStep(CinematicPreviewTransport transport, String stepId) {
  final block = transport.plan?.timelineItems
      .where((item) => item.stepId == stepId)
      .firstOrNull;
  if (block != null) transport.seek(block.startMs);
}

void toggleCinematicStepSelection(Set<String> selection, String stepId) {
  if (!selection.add(stepId)) selection.remove(stepId);
}
