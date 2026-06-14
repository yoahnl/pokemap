import 'package:flutter/foundation.dart';

import 'cinematic_timeline_zoom_state.dart';

class CinematicTimelineZoomController
    extends ValueNotifier<CinematicTimelineZoomState> {
  CinematicTimelineZoomController({
    CinematicTimelineZoomState initialValue =
        const CinematicTimelineZoomState(),
  }) : super(initialValue);

  void setScale(double scale) {
    final nextValue = CinematicTimelineZoomState.clamped(scale);
    if (nextValue == value) {
      return;
    }
    value = nextValue;
  }

  void zoomIn() {
    setScale(value.scale + CinematicTimelineZoomState.step);
  }

  void zoomOut() {
    setScale(value.scale - CinematicTimelineZoomState.step);
  }

  void reset() {
    setScale(CinematicTimelineZoomState.defaultScale);
  }

  void applyScale(double scale, {double? baseScale}) {
    if (!scale.isFinite || scale <= 0) {
      return;
    }
    setScale((baseScale ?? value.scale) * scale);
  }
}
