part of 'map_exterior_decoration_controller.dart';

extension MapExteriorDecorationSectors on MapExteriorDecorationController {
  bool selectAt(
    num x,
    num z, {
    Iterable<ExteriorDecorationRect> neighborBounds = const [],
  }) {
    final definition = _definition;
    if (_disposed ||
        !editingExterior ||
        definition == null ||
        !x.isFinite ||
        !z.isFinite ||
        !definition.outerBounds.contains(x, z) ||
        definition.isExcluded(x, z, neighborBounds: neighborBounds)) {
      return false;
    }
    final selected = _selected;
    if (selected != null && selected.bounds.contains(x, z)) return true;
    var sector = _sectors.values
        .where((v) => v.bounds.contains(x, z))
        .firstOrNull;
    if (sector == null) {
      final outer = definition.outerBounds;
      var left = math.max((x / 32).floor() * 32, outer.x);
      var top = math.max((z / 32).floor() * 32, outer.z);
      var right = math.min(((x / 32).floor() + 1) * 32, outer.right);
      var bottom = math.min(((z / 32).floor() + 1) * 32, outer.bottom);
      for (final other in _sectors.values) {
        final bounds = other.bounds;
        if (left >= bounds.right ||
            right <= bounds.x ||
            top >= bounds.bottom ||
            bottom <= bounds.z) {
          continue;
        }
        if (x < bounds.x) {
          right = math.min(right, bounds.x);
        } else if (x >= bounds.right) {
          left = math.max(left, bounds.right);
        } else if (z < bounds.z) {
          bottom = math.min(bottom, bounds.z);
        } else {
          top = math.max(top, bounds.bottom);
        }
      }
      sector = ExteriorDecorationSector(
        id: 'exterior_${_coordinate(left)}_${_coordinate(top)}',
        originX: left,
        originZ: top,
        scene: MapSpatialScene(
          width: right - left,
          depth: bottom - top,
          levelHeight: map.spatialScene!.levelHeight,
          generateCliffs: false,
        ),
      );
    }
    _select(sector);
    _projection = null;
    _notify();
    return true;
  }

  void _select(ExteriorDecorationSector sector) {
    _selected = sector;
    final visual = sector.asVisualMap().copyWith(id: map.id, name: map.name);
    _editingDocument = _ExteriorEditableDocument(
      MapWorkspaceDocument(map: visual, revision: _revision, mapId: map.id),
      (next) => _commitSector(sector, next),
    );
    _editingDocument!.exteriorDecoration = this;
  }

  MapData _commitSector(ExteriorDecorationSector source, MapData next) {
    if (_disposed) return next;
    if (next.size.width != source.scene.width ||
        next.size.height != source.scene.depth ||
        next.entities.isNotEmpty ||
        next.warps.isNotEmpty ||
        next.connections.isNotEmpty ||
        next.events.isNotEmpty ||
        next.gameplayZones.isNotEmpty ||
        next.triggers.isNotEmpty) {
      throw const FormatException(
        'Le décor extérieur accepte uniquement des éléments visuels natifs.',
      );
    }
    final sector = const ExteriorDecorationNativeEditing().visualSector(
      before: source,
      map: next,
    );
    final before = _sectors[sector.id];
    if (before == sector) return next;
    _withSectors(
      _definition!,
      {..._sectors, sector.id: sector}.values,
      borders: _borders.values,
    );
    _record(_ExteriorEdit.sector(before, sector));
    _clearRedo();
    _sectors[sector.id] = sector;
    _track(sector.id);
    _selected = sector;
    _projection = null;
    error = null;
    _notify();
    return sector.asVisualMap().copyWith(id: map.id, name: map.name);
  }

  void removeSector(String id) {
    final before = _sectors[id];
    if (_disposed || before == null) return;
    _record(_ExteriorEdit.sector(before, null));
    _clearRedo();
    _sectors.remove(id);
    _track(id);
    _projection = null;
    if (_selected?.id == id) {
      _selected = null;
      _editingDocument = null;
    }
    _notify();
  }

  void _track(String id) {
    if (_sectors[id] == _savedSectors[id]) {
      _pending.remove(id);
    } else {
      _pending.add(id);
    }
  }
}

final class _ExteriorEditableDocument extends EditableMapDocument {
  _ExteriorEditableDocument(super.base, this.apply);
  final MapData Function(MapData) apply;
  @override
  void commit(MapData next) {
    if (next == current) return;
    current = apply(next);
    error = null;
  }
}
