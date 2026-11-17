part of 'scene_graph_canvas.dart';

extension _SceneGraphCanvasNavigation on SceneGraphCanvasState {
  void _center(Offset world, {double? scale}) {
    final zoom = scale ?? _camera!.value.scale;
    _camera!.value = SceneGraphCamera(
      pan: _viewport.center(Offset.zero) - world * zoom,
      scale: zoom,
    );
  }

  double get _minimumZoom => math.min(
    SceneGraphCamera.minScale,
    SceneGraphCamera.fit(_bounds, _viewport).scale,
  );

  void _toolbarZoom(double? factor) {
    final camera = _camera!;
    camera.value = camera.value.zoomAt(
      _viewport.center(Offset.zero),
      factor ?? 1 / camera.value.scale,
      minimum: _minimumZoom,
    );
    requestFocus();
  }

  Offset _startCentre(Rect bounds) =>
      switch (_view.card(widget.scene.graph.startNodeId)) {
        final start? => sceneGraphCardRect(start).center,
        null => bounds.centerLeft,
      };

  Matrix4 _matrix(SceneGraphCamera camera, Offset origin) =>
      Matrix4.diagonal3Values(camera.scale, camera.scale, 1)..setTranslationRaw(
        camera.pan.dx + origin.dx * camera.scale,
        camera.pan.dy + origin.dy * camera.scale,
        0,
      );
}
