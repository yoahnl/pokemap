part of 'spatial_map_editing_viewport.dart';

extension _SpatialCameraSync on _SpatialMapEditingViewportState {
  void _bindAtmosphere() {
    final weather = widget.document.weatherVisuals;
    if (!identical(weather, _weatherVisuals)) {
      _weatherVisuals?.removeListener(_syncAtmosphere);
      _weatherVisuals = weather;
      _weatherVisuals?.addListener(_syncAtmosphere);
    }
    final next = widget.document.atmosphere;
    if (identical(next, _atmosphere)) {
      _syncAtmosphere();
      return;
    }
    _atmosphere?.removeListener(_syncAtmosphere);
    _atmosphere = next;
    _atmosphere?.addListener(_syncAtmosphere);
    _syncAtmosphere();
  }

  void syncCameraView({bool preserveGesture = false}) {
    final next = widget.view.spatialFreeView
        ? SpatialEditorView.orbit
        : SpatialEditorView.game;
    if (camera.view == next) return;
    if (preserveGesture) {
      if (gestureFreeView != null) {
        gestureFreeView = widget.view.spatialFreeView;
      }
    } else {
      discardGesture();
      discardBorder();
    }
    if (next == SpatialEditorView.orbit) {
      final profile = widget.document.current.spatialScene!.camera;
      camera.yaw = profile.yawDegrees * math.pi / 180;
      camera.pitch = profile.pitchDegrees * math.pi / 180;
    }
    camera.setView(next);
  }

  void recenter() {
    discardGesture();
    widget.view.spatialFreeView = false;
    widget.view.transform.value = Matrix4.identity();
    camera.reset();
    camera.setView(SpatialEditorView.game);
    widget.onChanged();
  }
}
