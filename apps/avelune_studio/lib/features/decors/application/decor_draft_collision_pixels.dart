part of 'decor_draft.dart';

extension _DecorDraftCollisionPixels on DecorDraft {
  void _paintRect(int left, int top, int width, int height, bool solid) {
    var changed = false;
    for (
      var y = math.max(0, top);
      y < math.min(_maskHeight, top + height);
      y++
    ) {
      for (
        var x = math.max(0, left);
        x < math.min(_maskWidth, left + width);
        x++
      ) {
        final index = y * _maskWidth + x;
        if (_pixels![index] == solid) continue;
        _pixels![index] = solid;
        changed = true;
      }
    }
    if (!changed) return;
    collisionRevision++;
    collisionChanged = true;
  }

  void _syncCells() {
    if (_pixels == null) return;
    blocked = ElementCollisionMaskCodec.cellsFromPixelMask(
      mask: _pixelMask(),
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      sourceWidthInTiles: selection.width,
      sourceHeightInTiles: selection.height,
    ).toSet();
  }

  void _ensurePixels() {
    if (_pixels != null) return;
    final problem = collisionProblem;
    if (problem != null) throw FormatException(problem);
    _maskWidth = pixelWidth;
    _maskHeight = pixelHeight;
    final pixels = List<bool>.filled(_maskWidth * _maskHeight, false);
    final mask = collisionChanged ? null : _collisionBase?.collisionMask;
    if (mask != null) {
      final decoded = ElementCollisionMaskCodec.decodePackedBits(
        widthPx: mask.widthPx,
        heightPx: mask.heightPx,
        dataBase64: mask.dataBase64,
      );
      for (var y = 0; y < mask.heightPx; y++) {
        for (var x = 0; x < mask.widthPx; x++) {
          pixels[y * _maskWidth + x] = decoded[y * mask.widthPx + x];
        }
      }
    } else {
      for (final cell in blocked) {
        for (var y = cell.y * tileHeight; y < (cell.y + 1) * tileHeight; y++) {
          for (var x = cell.x * tileWidth; x < (cell.x + 1) * tileWidth; x++) {
            if (x >= 0 && y >= 0 && x < _maskWidth && y < _maskHeight) {
              pixels[y * _maskWidth + x] = true;
            }
          }
        }
      }
    }
    _pixels = pixels;
  }

  ElementCollisionPixelMask _pixelMask() => ElementCollisionPixelMask(
    widthPx: _maskWidth,
    heightPx: _maskHeight,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: _maskWidth,
      heightPx: _maskHeight,
      solidPixels: _pixels!,
    ),
  );

  _CollisionState _snapshot() => _CollisionState(
    {...blocked},
    _pixels == null ? null : _pixelMask(),
    _maskWidth,
    _maskHeight,
    collisionChanged,
    collisionRevision,
  );

  void _restore(_CollisionState state) {
    blocked = {...state.blocked};
    final pixels = state.pixels;
    _pixels = pixels == null
        ? null
        : ElementCollisionMaskCodec.decodePackedBits(
            widthPx: pixels.widthPx,
            heightPx: pixels.heightPx,
            dataBase64: pixels.dataBase64,
          );
    _maskWidth = state.width;
    _maskHeight = state.height;
    collisionChanged = state.changed;
    collisionRevision++;
  }
}

class _CollisionState {
  const _CollisionState(
    this.blocked,
    this.pixels,
    this.width,
    this.height,
    this.changed,
    this.revision,
  );
  final Set<GridPos> blocked;
  final ElementCollisionPixelMask? pixels;
  final int width, height;
  final bool changed;
  final int revision;
}
