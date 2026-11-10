import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

import 'dart:math' as math;

class MapWorkspaceViewportState {
  final transform = TransformationController();
  double get scale => transform.value.entry(0, 0).abs();
  bool positioned = false;
  Size? _viewport;
  Size? _content;
  Matrix4? _fittedTransform;
  int _fitGeneration = 0;
  VoidCallback? recenter;
  void Function(GridPos)? centerOn;
  Offset? Function(GridPos)? globalOfCell;

  void zoomBy(double factor) {
    if ((factor < 1 && scale * factor < .15) || scale * factor > 8) return;
    transform.value = transform.value.clone()
      ..scaleByDouble(factor, factor, 1, 1);
  }

  void fitViewport(Size viewport, Size content) {
    final widthScale = viewport.width / content.width;
    final heightScale = viewport.height / content.height;
    final scale = math.min(1.0, math.min(widthScale, heightScale));
    transform.value = Matrix4.identity()
      ..translateByDouble(
        (viewport.width - content.width * scale) / 2,
        (viewport.height - content.height * scale) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
    _fittedTransform = transform.value.clone();
  }

  void attachViewport(
    Size viewport,
    Size content,
    Size tile, {
    required bool Function() mounted,
    GlobalKey? surface,
  }) {
    void fit() => fitViewport(viewport, content);
    centerOn = (cell) => centerCell(cell, viewport, tile);
    recenter = fit;
    globalOfCell = (cell) {
      final box = surface?.currentContext?.findRenderObject();
      return box is RenderBox && box.attached
          ? box.localToGlobal(
              Offset((cell.x + 1) * tile.width, (cell.y + 1) * tile.height),
            )
          : null;
    };
    final changed = _viewport != viewport || _content != content;
    _viewport = viewport;
    _content = content;
    if (!changed) return;
    final fitted = _fittedTransform;
    if (positioned && fitted != null && transform.value != fitted) return;
    positioned = true;
    final generation = ++_fitGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted() &&
          generation == _fitGeneration &&
          (fitted == null || transform.value == fitted)) {
        fit();
      }
    });
  }

  void centerCell(GridPos cell, Size viewport, Size tile) {
    final scale = this.scale;
    transform.value = Matrix4.identity()
      ..translateByDouble(
        viewport.width / 2 - (cell.x + .5) * tile.width * scale,
        viewport.height / 2 - (cell.y + .5) * tile.height * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void dispose() {
    _fitGeneration++;
    transform.dispose();
  }
}
