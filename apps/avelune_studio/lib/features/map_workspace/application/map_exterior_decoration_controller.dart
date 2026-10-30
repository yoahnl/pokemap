import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring_editing.dart'
    show ExteriorDecorationNativeEditing;

import '../../project_session/domain/project_session.dart';
import '../domain/map_exterior_decoration_port.dart';
import '../domain/map_workspace_port.dart';
import 'editable_map_document.dart';

final class MapExteriorDecorationController extends ChangeNotifier {
  MapExteriorDecorationController._(
    this.session,
    this.map,
    this.port,
    MapExteriorDecorationState state,
  ) : _definition = state.decoration == null
          ? null
          : _header(state.decoration!),
      _savedDefinition = state.decoration == null
          ? null
          : _header(state.decoration!),
      _revision = state.revision,
      available = state.supported {
    for (final border
        in state.decoration?.borders ?? const <ExteriorDecorationBorder>[]) {
      _borders[border.id] = border;
      _savedBorders[border.id] = border;
    }
    for (final sector
        in state.decoration?.sectors ?? const <ExteriorDecorationSector>[]) {
      _sectors[sector.id] = sector;
      _savedSectors[sector.id] = sector;
    }
  }
  final bool available;
  final ProjectSession session;
  final MapData map;
  final MapExteriorDecorationPort port;
  MapExteriorDecoration? _definition, _savedDefinition, _projection;
  final _sectors = <String, ExteriorDecorationSector>{};
  final _savedSectors = <String, ExteriorDecorationSector>{};
  final _pending = <String>{};
  final _borders = <String, ExteriorDecorationBorder>{};
  final _savedBorders = <String, ExteriorDecorationBorder>{};
  final _pendingBorders = <String>{};
  final _undo = <_ExteriorEdit>[];
  List<_ExteriorEdit>? _gesture;
  List<_ExteriorEdit> _redo = [];
  String _revision;
  ExteriorDecorationSector? _selected;
  EditableMapDocument? _editingDocument;
  bool editingExterior = false;
  bool saving = false;
  bool _disposed = false;
  bool _externalConflict = false;
  String? error;
  String? lastReceiptId;
  String get revision => _revision;
  Map<String, ExteriorDecorationSector> get _selectedEntry {
    final selected = _selected;
    return selected == null ? const {} : {selected.id: selected};
  }

  MapExteriorDecoration? get current => _definition == null
      ? null
      : _projection ??= _withSectors(
          _definition!,
          {..._sectors, ..._selectedEntry}.values,
          borders: _borders.values,
        );
  MapExteriorDecoration? get saved => _savedDefinition == null
      ? null
      : _withSectors(
          _savedDefinition!,
          _savedSectors.values,
          borders: _savedBorders.values,
        );
  EditableMapDocument? get editingDocument => _editingDocument;
  String? get selectedSectorId => _selected?.id;
  int get originX => _selected?.originX ?? 0;
  int get originZ => _selected?.originZ ?? 0;
  bool get dirty =>
      _definition != _savedDefinition ||
      _pending.isNotEmpty ||
      _pendingBorders.isNotEmpty;
  bool get canUndo => _gesture == null && _undo.isNotEmpty;
  bool get canRedo => _gesture == null && _redo.isNotEmpty;

  static Future<MapExteriorDecorationController> open(
    ProjectSession session,
    MapData map,
    MapExteriorDecorationPort port,
  ) async {
    final state = await port.loadExteriorDecoration(session, map.id);
    state.decoration?.validateForMap(map);
    return MapExteriorDecorationController._(session, map, port, state);
  }

  void setEditingExterior(bool value) {
    if (_disposed || editingExterior == value) return;
    editingExterior = value;
    if (value && _definition == null) {
      configureMargins(west: 16, east: 16, north: 16, south: 16);
    }
    notifyListeners();
  }

  bool configureMargins({
    required int west,
    required int east,
    required int north,
    required int south,
  }) {
    if (_disposed) return false;
    try {
      final next = MapExteriorDecoration(
        mapId: map.id,
        playableWidth: map.size.width,
        playableDepth: map.size.height,
        west: west,
        east: east,
        north: north,
        south: south,
        sectors: _sectors.values,
        borders: _borders.values,
      );
      final header = _header(next);
      if (header == _definition) return true;
      _record(_ExteriorEdit.definition(_definition, header));
      _clearRedo();
      _definition = header;
      _projection = null;
      final selected = _selected;
      if (selected != null && !next.outerBounds.containsRect(selected.bounds)) {
        _selected = null;
        _editingDocument = null;
      }
      error = null;
      notifyListeners();
      return true;
    } on FormatException {
      error = 'La marge doit rester entre 0 et 64 cases et contenir le décor existant. Retirez le contenu concerné avant de la réduire.';
      notifyListeners();
      return false;
    }
  }

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
    notifyListeners();
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
    notifyListeners();
    return sector.asVisualMap().copyWith(id: map.id, name: map.name);
  }

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
  void regenerateBorder(String id, ProjectManifest manifest) {
    final border = _borders[id];
    if (border == null) return;
    commitBorder(
      const ExteriorDecorationNativeEditing().resolveBorder(
        manifest: manifest,
        decoration: current!,
        border: border,
        playableMap: map,
      ),
    );
  }

  ExteriorDecorationBorder? previewBorderErase({required ProjectManifest manifest,required ExteriorDecorationBorder before,required Iterable<GridPos> logicalPoints})=>const ExteriorDecorationNativeEditing().eraseBorder(decoration:current!,manifest:manifest,before:before,logicalPoints:logicalPoints,playableMap:map);
  void eraseBorder({required ProjectManifest manifest,required ExteriorDecorationBorder before,required Iterable<GridPos> logicalPoints}){final next=previewBorderErase(manifest:manifest,before:before,logicalPoints:logicalPoints);if(next==null){removeBorder(before.id);}else{commitBorder(next);}}
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
    notifyListeners();
  }

  void removeBorder(String id) {
    final before = _borders[id];
    if (_disposed || before == null) return;
    _record(_ExteriorEdit.border(before, null));
    _clearRedo();
    _borders.remove(id);
    _trackBorder(id);
    _projection = null;
    notifyListeners();
  }

  void _trackBorder(String id) {
    if (_borders[id] == _savedBorders[id]) {
      _pendingBorders.remove(id);
    } else {
      _pendingBorders.add(id);
    }
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
    notifyListeners();
  }

  void _track(String id) {
    if (_sectors[id] == _savedSectors[id]) {
      _pending.remove(id);
    } else {
      _pending.add(id);
    }
  }

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
      notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
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

  void rejectExternalChange() {
    if (_disposed) return;
    _externalConflict = true;
    error = 'Une modification externe concerne ce décor extérieur. Votre brouillon et son historique sont conservés. Rouvrez la carte avant de publier.';
    notifyListeners();
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
    notifyListeners();
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
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
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

MapExteriorDecoration _header(MapExteriorDecoration value) =>
    _withSectors(value, const [], borders: const []);
MapExteriorDecoration _withSectors(
  MapExteriorDecoration value,
  Iterable<ExteriorDecorationSector> sectors, {
  Iterable<ExteriorDecorationBorder>? borders,
}) => MapExteriorDecoration(
  mapId: value.mapId,
  playableWidth: value.playableWidth,
  playableDepth: value.playableDepth,
  west: value.west,
  east: value.east,
  north: value.north,
  south: value.south,
  sectors: sectors,
  borders: borders ?? value.borders,
);
String _coordinate(int value) => value < 0 ? 'm${-value}' : 'p$value';
