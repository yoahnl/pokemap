import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

enum DecorResizeHandle {
  topLeft(-1, -1),
  top(0, -1),
  topRight(1, -1),
  left(-1, 0),
  right(1, 0),
  bottomLeft(-1, 1),
  bottom(0, 1),
  bottomRight(1, 1);

  const DecorResizeHandle(this.x, this.y);
  final int x, y;
  Offset point(Rect rect) => Offset(
    x < 0
        ? rect.left
        : x > 0
        ? rect.right
        : rect.center.dx,
    y < 0
        ? rect.top
        : y > 0
        ? rect.bottom
        : rect.center.dy,
  );
}

class MapDecorTransformDraft {
  MapDecorTransformDraft({
    required this.source,
    required this.project,
    required this.original,
    required Offset pointer,
    required bool precise,
    this.handle,
    this.lockRatio = false,
  }) : candidate = original,
       _base = original,
       _origin = pointer,
       _lastPointer = pointer,
       _precise = precise,
       environmentOwnedIds = environmentOwnedMapPlacedElementIds(source),
       element = project.elements.firstWhere((e) => e.id == original.elementId),
       tileSize = PixelSize(
         width: project.settings.tileWidth,
         height: project.settings.tileHeight,
       ) {
    final size = geometry.pixelSize;
    _ratio = size.width / size.height;
  }

  final MapData source;
  final ProjectManifest project;
  final MapPlacedElement original;
  final ProjectElementEntry element;
  final PixelSize tileSize;
  final Set<String> environmentOwnedIds;
  final DecorResizeHandle? handle;
  final bool lockRatio;
  late final double _ratio;
  MapPlacedElement candidate;
  MapPlacedElement _base;
  Offset _origin, _lastPointer;
  bool _precise;
  String? error;

  MapPlacedElementGeometry get geometry => resolveMapPlacedElementGeometry(
    instance: candidate,
    element: element,
    tileSize: tileSize,
  );

  void rebasePrecision(bool precise) {
    if (precise == _precise) return;
    _base = candidate;
    _origin = _lastPointer;
    _precise = precise;
  }

  void move(Offset pointer, {required bool precise}) {
    rebasePrecision(precise);
    _lastPointer = pointer;
    final rect = resolveMapPlacedElementGeometry(
      instance: _base,
      element: element,
      tileSize: tileSize,
    ).logicalRect;
    final stepX = precise ? 1 : tileSize.width;
    final stepY = precise ? 1 : tileSize.height;
    final dx = ((pointer.dx - _origin.dx) / stepX).round() * stepX;
    final dy = ((pointer.dy - _origin.dy) / stepY).round() * stepY;
    final edge = handle;
    if (edge == null) {
      propose(rect.leftPx + dx, rect.topPx + dy, _base.pixelSize);
      return;
    }
    var width = math.max(1, rect.widthPx + dx * edge.x);
    var height = math.max(1, rect.heightPx + dy * edge.y);
    if (lockRatio && edge.x != 0 && edge.y != 0) {
      if ((width - rect.widthPx).abs() / rect.widthPx >=
          (height - rect.heightPx).abs() / rect.heightPx) {
        height = math.max(1, (width / _ratio).round());
      } else {
        width = math.max(1, (height * _ratio).round());
      }
    }
    propose(
      edge.x < 0 ? rect.leftPx + rect.widthPx - width : rect.leftPx,
      edge.y < 0 ? rect.topPx + rect.heightPx - height : rect.topPx,
      PixelSize(width: width, height: height),
    );
  }

  void nudge(int x, int y) {
    final rect = geometry.logicalRect;
    propose(rect.leftPx + x, rect.topPx + y, candidate.pixelSize);
  }

  void propose(int x, int y, PixelSize? size) {
    try {
      candidate = resolveMapPlacedElementGeometryCandidate(
        instance: original,
        element: element,
        mapSize: source.size,
        tileSize: tileSize,
        environmentOwnedIds: environmentOwnedIds,
        pixelX: x,
        pixelY: y,
        pixelSize: size,
      );
      error = null;
    } on ValidationException {
      error =
          'Ce décor dépasse les limites de la carte ou sa taille autorisée.';
    }
  }
}
