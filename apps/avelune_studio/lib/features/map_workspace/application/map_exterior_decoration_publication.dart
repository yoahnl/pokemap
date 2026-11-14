part of 'map_exterior_decoration_controller.dart';

extension MapExteriorDecorationPublication on MapExteriorDecorationController {
  void rejectExternalChange() {
    if (_disposed) return;
    _externalConflict = true;
    error = 'Une modification externe concerne ce décor extérieur. Votre brouillon et son historique sont conservés. Rouvrez la carte avant de publier.';
    _notify();
  }

  Future<bool> save() async {
    if (_disposed || saving || _gesture != null) return false;
    if (!dirty) return true;
    if (_externalConflict) {
      rejectExternalChange();
      return false;
    }
    final definition = _definition;
    final changes = {for (final id in _pending) id: _sectors[id]};
    final borderChanges = {for (final id in _pendingBorders) id: _borders[id]};
    saving = true;
    error = null;
    _notify();
    try {
      if (definition != null && definition != _savedDefinition) {
        final result = await port.configureExteriorDecoration(
          session,
          map.id,
          definition,
          _revision,
        );
        _revision = result.revision;
        lastReceiptId = result.receiptId;
        _savedDefinition = definition;
      }
      if (changes.isNotEmpty) {
        final result = await port.saveExteriorDecorationSectors(
          session,
          map.id,
          [for (final value in changes.values) ?value],
          [
            for (final value in changes.entries)
              if (value.value == null) value.key,
          ],
          _revision,
        );
        _revision = result.revision;
        lastReceiptId = result.receiptId;
        for (final change in changes.entries) {
          final sector = change.value;
          if (sector == null) {
            _savedSectors.remove(change.key);
          } else {
            _savedSectors[change.key] = sector;
          }
          _track(change.key);
        }
      }
      for (final change in borderChanges.entries) {
        final border = change.value;
        final result = border == null
            ? await port.removeExteriorDecorationBorder(
                session,
                map.id,
                change.key,
                _revision,
              )
            : await port.saveExteriorDecorationBorder(
                session,
                map.id,
                border,
                _revision,
              );
        _revision = result.revision;
        lastReceiptId = result.receiptId;
        if (border == null) {
          _savedBorders.remove(change.key);
        } else {
          _savedBorders[change.key] = border;
        }
        _trackBorder(change.key);
      }
      if (definition == null && _savedDefinition != null) {
        final result = await port.configureExteriorDecoration(
          session,
          map.id,
          null,
          _revision,
        );
        _revision = result.revision;
        lastReceiptId = result.receiptId;
        _savedDefinition = null;
      }
      return !_disposed;
    } on Object catch (failure) {
      if (!_disposed) error = '$failure';
      return false;
    } finally {
      saving = false;
      if (!_disposed) _notify();
    }
  }
}
