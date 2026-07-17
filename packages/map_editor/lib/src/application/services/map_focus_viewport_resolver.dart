import 'dart:ui';

import 'package:map_core/map_core.dart';

Offset resolveMapFocusPanOffset({
  required MapRect bounds,
  required Size viewportSize,
  required double tileWidth,
  required double tileHeight,
  required double zoom,
}) {
  if (viewportSize.width <= 0 || viewportSize.height <= 0) {
    throw ArgumentError.value(viewportSize, 'viewportSize');
  }
  if (tileWidth <= 0 || tileHeight <= 0 || zoom <= 0) {
    throw ArgumentError('Tile dimensions and zoom must be positive.');
  }
  final worldCenter = Offset(
    (bounds.pos.x + bounds.size.width / 2) * tileWidth,
    (bounds.pos.y + bounds.size.height / 2) * tileHeight,
  );
  return viewportSize.center(Offset.zero) - worldCenter * zoom;
}

MapRect resolveNarrativeEventMapFocusBounds({
  required NarrativeEditorFocusTarget focus,
  required MapData map,
}) {
  if (focus.mapId != map.id) {
    throw ArgumentError.value(
      focus.mapId,
      'focus',
      'must target the active map',
    );
  }
  final bounds = focus.bounds;
  if (bounds != null) return bounds;
  if (focus.kind != NarrativeEditorFocusTargetKind.map) {
    throw ArgumentError.value(
      focus,
      'focus',
      'an entity or trigger focus must carry bounds',
    );
  }
  return MapRect(
    pos: const GridPos(x: 0, y: 0),
    size: map.size,
  );
}
