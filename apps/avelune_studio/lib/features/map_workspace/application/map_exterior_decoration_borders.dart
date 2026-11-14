part of 'map_exterior_decoration_controller.dart';

extension MapExteriorDecorationBorders on MapExteriorDecorationController {
  ExteriorDecorationBorder previewBorder({
    required ProjectManifest manifest,
    required String blueprintId,
    required Iterable<GridPos> logicalPoints,
    required BorderSignedInt64 seed,
    required String borderId,
    String? layerId,
    bool closed = false,
  }) {
    final decoration = current;
    if (decoration == null) {
      throw const FormatException(
        'Configure exterior margins before drawing a Border.',
      );
    }
    const native = ExteriorDecorationNativeEditing();
    final prepared = native.prepareBorder(
      decoration: decoration,
      manifest: manifest,
      id: borderId,
      blueprintId: blueprintId,
      logicalPoints: logicalPoints,
      seed: seed,
      before: _borders[borderId],
      layerId: layerId,
      closed: closed,
    );
    return native.resolveBorder(
      manifest: manifest,
      decoration: decoration,
      border: prepared,
      playableMap: map,
    );
  }

  void drawBorder({
    required ProjectManifest manifest,
    required String blueprintId,
    required Iterable<GridPos> logicalPoints,
    required BorderSignedInt64 seed,
    required String borderId,
    String? layerId,
    bool closed = false,
  }) => commitBorder(
    previewBorder(
      manifest: manifest,
      blueprintId: blueprintId,
      logicalPoints: logicalPoints,
      seed: seed,
      borderId: borderId,
      layerId: layerId,
      closed: closed,
    ),
  );
  ExteriorDecorationBorder? previewBorderErase({
    required ProjectManifest manifest,
    required ExteriorDecorationBorder before,
    required Iterable<GridPos> logicalPoints,
  }) => const ExteriorDecorationNativeEditing().eraseBorder(
    decoration: current!,
    manifest: manifest,
    before: before,
    logicalPoints: logicalPoints,
    playableMap: map,
  );
  void eraseBorder({
    required ProjectManifest manifest,
    required ExteriorDecorationBorder before,
    required Iterable<GridPos> logicalPoints,
  }) {
    final next = previewBorderErase(
      manifest: manifest,
      before: before,
      logicalPoints: logicalPoints,
    );
    if (next == null) {
      removeBorder(before.id);
    } else {
      commitBorder(next);
    }
  }

  void commitBorder(ExteriorDecorationBorder border) {
    if (_disposed) return;
    final before = _borders[border.id];
    if (before == border) return;
    _withSectors(
      _definition!,
      _sectors.values,
      borders: {..._borders, border.id: border}.values,
    );
    _record(_ExteriorEdit.border(before, border));
    _clearRedo();
    _borders[border.id] = border;
    _trackBorder(border.id);
    _projection = null;
    error = null;
    _notify();
  }

  void removeBorder(String id) {
    final before = _borders[id];
    if (_disposed || before == null) return;
    _record(_ExteriorEdit.border(before, null));
    _clearRedo();
    _borders.remove(id);
    _trackBorder(id);
    _projection = null;
    _notify();
  }

  void _trackBorder(String id) {
    if (_borders[id] == _savedBorders[id]) {
      _pendingBorders.remove(id);
    } else {
      _pendingBorders.add(id);
    }
  }
}
