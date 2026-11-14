import 'dart:math' as math;

import 'package:map_core/map_core_domain.dart';
import 'package:map_authoring/map_authoring_editing.dart'
    show ExteriorDecorationNativeEditing;

import '../../project_session/domain/project_session.dart';
import '../domain/map_exterior_decoration_port.dart';
import '../domain/map_workspace_port.dart';
import 'editable_map_document.dart';

part 'map_exterior_decoration_sectors.dart';
part 'map_exterior_decoration_borders.dart';
part 'map_exterior_decoration_history.dart';
part 'map_exterior_decoration_publication.dart';

final class MapExteriorDecorationController {
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
  final Set<void Function()> _listeners = {};
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
    _notify();
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
      _notify();
      return true;
    } on FormatException {
      error = 'La marge doit rester entre 0 et 64 cases et contenir le décor existant. Retirez le contenu concerné avant de la réduire.';
      _notify();
      return false;
    }
  }

  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  void _notify() {
    for (final listener in List.of(_listeners)) {
      if (_listeners.contains(listener)) listener();
    }
  }

  void dispose() {
    _disposed = true;
    _listeners.clear();
  }
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
