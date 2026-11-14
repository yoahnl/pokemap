part of 'map_exterior_decoration_controller.dart';

extension MapExteriorDecorationHistory on MapExteriorDecorationController {
  void beginGesture() {
    if (_disposed || _gesture != null) return;
    _gesture = [];
  }

  void endGesture() {
    final changes = _gesture;
    _gesture = null;
    if (changes != null && changes.isNotEmpty) {
      _redo = [];
      _undo.add(_ExteriorEdit.group(changes));
      _notify();
    }
  }

  void cancelGesture() {
    final changes = _gesture;
    _gesture = null;
    if (changes == null) return;
    for (final change in changes.reversed) {
      _applyChange(change, false);
    }
    _projection = null;
    _selected = null;
    _editingDocument = null;
    _notify();
  }

  void _clearRedo() {
    if (_gesture == null) _redo = [];
  }

  void _record(_ExteriorEdit change) {
    final gesture = _gesture;
    if (gesture == null) {
      _undo.add(change);
    } else {
      gesture.add(change);
    }
  }

  void undo() => _restore(false);
  void redo() => _restore(true);
  void _restore(bool redo) {
    final from = redo ? _redo : _undo;
    if (_disposed || from.isEmpty) return;
    final change = from.removeLast();
    (redo ? _undo : _redo).add(change);
    _applyChange(change, redo);
    _projection = null;
    final selected = _selected;
    if (selected != null) {
      final value = _sectors[selected.id];
      if (value == null) {
        _selected = null;
        _editingDocument = null;
      } else {
        _select(value);
      }
    }
    error = null;
    _notify();
  }

  void _applyChange(_ExteriorEdit change, bool redo) {
    final children = change.children;
    if (children != null) {
      for (final child in redo ? children : children.reversed) {
        _applyChange(child, redo);
      }
      return;
    }
    if (change.borderId != null) {
      final value = redo ? change.afterBorder : change.beforeBorder;
      if (value == null) {
        _borders.remove(change.borderId);
      } else {
        _borders[change.borderId!] = value;
      }
      _trackBorder(change.borderId!);
    } else if (change.sectorId == null) {
      _definition = redo ? change.afterDefinition : change.beforeDefinition;
    } else {
      final value = redo ? change.afterSector : change.beforeSector;
      if (value == null) {
        _sectors.remove(change.sectorId);
      } else {
        _sectors[change.sectorId!] = value;
      }
      _track(change.sectorId!);
    }
  }
}

final class _ExteriorEdit {
  const _ExteriorEdit.definition(this.beforeDefinition, this.afterDefinition)
    : beforeSector = null,
      afterSector = null,
      sectorId = null,
      beforeBorder = null,
      afterBorder = null,
      borderId = null,
      children = null;
  _ExteriorEdit.sector(this.beforeSector, this.afterSector)
    : beforeDefinition = null,
      afterDefinition = null,
      sectorId = afterSector?.id ?? beforeSector!.id,
      beforeBorder = null,
      afterBorder = null,
      borderId = null,
      children = null;
  _ExteriorEdit.border(this.beforeBorder, this.afterBorder)
    : beforeDefinition = null,
      afterDefinition = null,
      beforeSector = null,
      afterSector = null,
      sectorId = null,
      borderId = afterBorder?.id ?? beforeBorder!.id,
      children = null;
  _ExteriorEdit.group(Iterable<_ExteriorEdit> values)
    : children = List.unmodifiable(values),
      beforeDefinition = null,
      afterDefinition = null,
      beforeSector = null,
      afterSector = null,
      sectorId = null,
      beforeBorder = null,
      afterBorder = null,
      borderId = null;
  final MapExteriorDecoration? beforeDefinition, afterDefinition;
  final ExteriorDecorationSector? beforeSector, afterSector;
  final ExteriorDecorationBorder? beforeBorder, afterBorder;
  final String? sectorId, borderId;
  final List<_ExteriorEdit>? children;
}
