import 'dart:math' as math;

import 'package:map_core/map_core_domain.dart';

part 'decor_draft_collision_pixels.dart';

class DecorDraft {
  DecorDraft({required this.tileset, ProjectElementEntry? original})
    : _original = original,
      _collisionBase = original?.collisionProfile,
      selection =
          original?.frames.first.source ?? const TilesetSourceRect(x: 0, y: 0),
      name = original?.name ?? 'Nouveau décor',
      blocked = {...?original?.collisionProfile?.cells};
  final ProjectTilesetEntry tileset;
  ProjectElementEntry? _original;
  ProjectElementEntry? get original => _original;
  final ElementCollisionProfile? _collisionBase;
  static const collisionHistoryLimit = 64;
  TilesetSourceRect selection;
  String name;
  bool variant = false;
  bool collisionChanged = false;
  final newId = 'decor-${DateTime.now().microsecondsSinceEpoch}';
  Set<GridPos> blocked;
  List<bool>? _pixels;
  int _maskWidth = 0;
  int _maskHeight = 0;
  int collisionRevision = 0;
  final _undo = <_CollisionState>[];
  final _redo = <_CollisionState>[];
  _CollisionState? _stroke;
  ElementCollisionPixelMask? _checkedMask;
  String? _maskProblem;

  void rebase(ProjectElementEntry saved) {
    _original = saved;
    variant = false;
  }

  int get tileWidth => switch (tileset.source) {
    ProjectRegularAtlasTilesetSource(:final tileWidth) => tileWidth,
    _ => 0,
  };
  int get tileHeight => switch (tileset.source) {
    ProjectRegularAtlasTilesetSource(:final tileHeight) => tileHeight,
    _ => 0,
  };
  int get pixelWidth => math.max(
    selection.width * tileWidth,
    _collisionBase?.collisionMask?.widthPx ?? 0,
  );
  int get pixelHeight => math.max(
    selection.height * tileHeight,
    _collisionBase?.collisionMask?.heightPx ?? 0,
  );
  bool get hasFineCollision =>
      _pixels != null ||
      (!collisionChanged && _collisionBase?.collisionMask != null);
  bool get canUndoCollision => _undo.isNotEmpty;
  bool get canRedoCollision => _redo.isNotEmpty;
  List<bool>? get collisionPixels {
    if (!hasFineCollision) return null;
    _ensurePixels();
    return _pixels;
  }

  String? get collisionProblem {
    if (tileWidth <= 0 || tileHeight <= 0) {
      return 'La grille de cette source ne permet pas une peinture précise. Les collisions existantes sont conservées.';
    }
    final mask = _collisionBase?.collisionMask;
    if (!collisionChanged && mask != null && !identical(_checkedMask, mask)) {
      _checkedMask = mask;
      try {
        ElementCollisionMaskCodec.decodePackedBits(
          widthPx: mask.widthPx,
          heightPx: mask.heightPx,
          dataBase64: mask.dataBase64,
        );
      } on FormatException {
        _maskProblem =
            'Le masque existant est illisible. Il est conservé ; corrigez sa source avant de le peindre.';
      }
    }
    return collisionChanged ? null : _maskProblem;
  }

  void beginCollisionStroke() {
    _stroke ??= _snapshot();
  }

  void endCollisionStroke() {
    final before = _stroke;
    _stroke = null;
    if (before == null || before.revision == collisionRevision) return;
    _syncCells();
    _undo.add(before);
    if (_undo.length > collisionHistoryLimit) _undo.removeAt(0);
    _redo.clear();
  }

  void cancelCollisionStroke() {
    final before = _stroke;
    _stroke = null;
    if (before != null) _restore(before);
  }

  void undoCollision() {
    if (_undo.isEmpty) return;
    _redo.add(_snapshot());
    _restore(_undo.removeLast());
  }

  void redoCollision() {
    if (_redo.isEmpty) return;
    _undo.add(_snapshot());
    _restore(_redo.removeLast());
  }

  void paintCollisionCell(GridPos cell, {required bool solid}) {
    if (cell.x < 0 ||
        cell.y < 0 ||
        cell.x >= selection.width ||
        cell.y >= selection.height) {
      return;
    }
    final standalone = _stroke == null;
    if (standalone) beginCollisionStroke();
    if (hasFineCollision) {
      _ensurePixels();
      _paintRect(
        cell.x * tileWidth,
        cell.y * tileHeight,
        tileWidth,
        tileHeight,
        solid,
      );
    } else {
      final changed = solid ? blocked.add(cell) : blocked.remove(cell);
      if (changed) {
        collisionRevision++;
        collisionChanged = true;
      }
    }
    if (standalone) endCollisionStroke();
  }

  void paintCollisionPixel(GridPos pixel, {required bool solid, int size = 1}) {
    if (pixel.x < 0 ||
        pixel.y < 0 ||
        pixel.x >= pixelWidth ||
        pixel.y >= pixelHeight ||
        size <= 0) {
      return;
    }
    final standalone = _stroke == null;
    if (standalone) beginCollisionStroke();
    _ensurePixels();
    final half = (size - 1) ~/ 2;
    _paintRect(pixel.x - half, pixel.y - half, size, size, solid);
    if (standalone) endCollisionStroke();
  }

  void setBlocked(bool value) {
    beginCollisionStroke();
    if (value && hasFineCollision) {
      _ensurePixels();
      _pixels!.fillRange(0, _pixels!.length, true);
    } else {
      _pixels = null;
    }
    collisionChanged = true;
    blocked = value
        ? {
            for (var y = 0; y < selection.height; y++)
              for (var x = 0; x < selection.width; x++) GridPos(x: x, y: y),
          }
        : {};
    collisionRevision++;
    endCollisionStroke();
  }

  ProjectElementEntry build({bool validateName = true}) {
    if (validateName && name.trim().isEmpty) {
      throw const FormatException('Nommez ce décor.');
    }
    final base =
        original ??
        ProjectElementEntry(
          id: newId,
          name: name,
          tilesetId: tileset.id,
          categoryId: '',
          frames: [TilesetVisualFrame(source: selection)],
        );
    final editableFrame = base.frames.length == 1;
    final frames = editableFrame
        ? [base.frames.first.copyWith(source: selection)]
        : base.frames;
    final profile = collisionChanged
        ? (_collisionBase ?? const ElementCollisionProfile()).copyWith(
            source: ElementCollisionProfileSource.manual,
            shapeCells: blocked.toList(),
            cells: blocked.toList(),
            manualAddedCells: [],
            manualRemovedCells: [],
            collisionMask: _pixels == null ? null : _pixelMask(),
          )
        : _collisionBase;
    return base.copyWith(
      id: variant ? newId : base.id,
      name: name.trim(),
      frames: frames,
      collisionProfile: profile,
    );
  }
}
