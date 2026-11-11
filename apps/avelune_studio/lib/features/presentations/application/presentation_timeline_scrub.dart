import 'presentation_preview_transport.dart';

int presentationTimelineTimeAt(
  double dx, {
  required double pixelsPerSecond,
  required int durationUs,
}) => (dx / pixelsPerSecond * 1000000).round().clamp(0, durationUs);

void scrubPresentationTimeline(
  PresentationPreviewTransport transport,
  double dx, {
  required double pixelsPerSecond,
  required int durationUs,
}) {
  transport.pause();
  transport.seek(
    presentationTimelineTimeAt(
      dx,
      pixelsPerSecond: pixelsPerSecond,
      durationUs: durationUs,
    ),
  );
}
