import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class SceneGraphViewport extends ChangeNotifier {
  SceneGraphViewport({this.pan = Offset.zero, this.zoom = 1});
  Offset pan;
  double zoom;
  Size size = Size.zero;
  bool initialized = false;
  double gestureStartZoom = 1;
  bool trackpadActive = false;
  Offset _gestureWorld = Offset.zero;
  void startTrackpad(Offset focal) {
    gestureStartZoom = zoom;
    _gestureWorld = localToWorld(focal);
    trackpadActive = true;
  }

  void updateTrackpad(double scale, Offset translation, Offset focal) {
    zoom = (gestureStartZoom * scale).clamp(.3, 2.5);
    pan = focal + translation - _gestureWorld * zoom;
    initialized = true;
    notifyListeners();
  }

  Offset localToWorld(Offset point) => (point - pan) / zoom;
  Offset worldToLocal(Offset point) => point * zoom + pan;
  Offset get center => localToWorld(size.center(Offset.zero));
  void translate(Offset delta) {
    pan += delta;
    initialized = true;
    notifyListeners();
  }

  void zoomAt(double value, Offset focal) {
    final world = localToWorld(focal);
    zoom = value.clamp(.3, 2.5);
    pan = focal - world * zoom;
    initialized = true;
    notifyListeners();
  }

  void centerOn(Offset world) {
    pan = size.center(Offset.zero) - world * zoom;
    initialized = true;
    notifyListeners();
  }

  void fit(Rect bounds) {
    if (size.isEmpty) return;
    zoom = math
        .min(
          (size.width - 80) / bounds.width,
          (size.height - 80) / bounds.height,
        )
        .clamp(.3, 1.1);
    centerOn(bounds.center);
  }
}
