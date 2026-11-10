part of 'decor_draft.dart';

extension DecorDraftCollisionInput on DecorDraft {
  GridPos? collisionPoint(double x, double y, {required bool fine}) {
    if (x < 0 ||
        y < 0 ||
        x >= selection.width * tileWidth ||
        y >= selection.height * tileHeight) {
      return null;
    }
    return GridPos(
      x: (x / (fine ? 1 : tileWidth)).floor(),
      y: (y / (fine ? 1 : tileHeight)).floor(),
    );
  }

  void _paintInput(
    double x,
    double y, {
    required bool fine,
    required bool solid,
    required int size,
  }) {
    final next = collisionPoint(x, y, fine: fine);
    if (next == null || next == _previousCollisionInput) return;
    final before = _previousCollisionInput ?? next;
    final steps = math.max(
      (next.x - before.x).abs(),
      (next.y - before.y).abs(),
    );
    for (var step = 0; step <= steps; step++) {
      final t = steps == 0 ? 1 : step / steps;
      final point = GridPos(
        x: (before.x + (next.x - before.x) * t).round(),
        y: (before.y + (next.y - before.y) * t).round(),
      );
      if (fine) {
        paintCollisionPixel(point, solid: solid, size: size);
      } else {
        paintCollisionCell(point, solid: solid);
      }
    }
    _previousCollisionInput = next;
    collisionCursor = next;
  }

  void beginCollisionPointer(
    double x,
    double y, {
    required bool fine,
    required bool solid,
    int size = 1,
  }) {
    collisionDrawing = true;
    _previousCollisionInput = null;
    beginCollisionStroke();
    _paintInput(x, y, fine: fine, solid: solid, size: size);
  }

  void moveCollisionPointer(
    double x,
    double y, {
    required bool fine,
    required bool solid,
    int size = 1,
  }) {
    if (collisionDrawing) {
      _paintInput(x, y, fine: fine, solid: solid, size: size);
    }
  }

  void endCollisionPointer() {
    if (collisionDrawing) endCollisionStroke();
    collisionDrawing = false;
    _previousCollisionInput = null;
  }

  void cancelCollisionPointer() {
    if (collisionDrawing) cancelCollisionStroke();
    collisionDrawing = false;
    _previousCollisionInput = null;
  }

  void moveCollisionCursor(GridPos offset, {required bool fine}) {
    final current = collisionCursor ?? const GridPos(x: 0, y: 0);
    collisionCursor = GridPos(
      x: (current.x + offset.x).clamp(
        0,
        (fine ? selection.width * tileWidth : selection.width) - 1,
      ),
      y: (current.y + offset.y).clamp(
        0,
        (fine ? selection.height * tileHeight : selection.height) - 1,
      ),
    );
  }

  void paintCollisionCursor({
    required bool fine,
    required bool solid,
    int size = 1,
  }) {
    final current = collisionCursor ?? const GridPos(x: 0, y: 0);
    beginCollisionStroke();
    if (fine) {
      paintCollisionPixel(current, solid: solid, size: size);
    } else {
      paintCollisionCell(current, solid: solid);
    }
    endCollisionStroke();
  }
}
