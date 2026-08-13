import 'dart:convert';

import 'package:map_core/map_core.dart';

enum MapHistoryDirection { backward, forward }

final class MapHistoryDivergence implements Exception {
  const MapHistoryDivergence(this.code);

  final String code;
}

final class MapHistoryDelta {
  MapHistoryDelta._({
    required _ValueDelta<String>? id,
    required _ValueDelta<String>? name,
    required _ValueDelta<GridSize>? size,
    required _ValueDelta<ProjectVersion>? version,
    required _ValueDelta<MapVisualStackConfig?>? visualStack,
    required _ValueDelta<String>? tilesetId,
    required _MapLayersDelta? layers,
    required _ReversibleListDelta<MapPlacedElement>? placedElements,
    required _ReversibleListDelta<MapEntity>? entities,
    required _ReversibleListDelta<MapConnection>? connections,
    required _ReversibleListDelta<MapWarp>? warps,
    required _ReversibleListDelta<MapTrigger>? triggers,
    required _ReversibleListDelta<MapGameplayZone>? gameplayZones,
    required _ValueDelta<MapMetadata>? mapMetadata,
    required _ValueDelta<Map<String, dynamic>>? properties,
    required _ReversibleListDelta<MapEventDefinition>? events,
  }) : _id = id,
       _name = name,
       _size = size,
       _version = version,
       _visualStack = visualStack,
       _tilesetId = tilesetId,
       _layers = layers,
       _placedElements = placedElements,
       _entities = entities,
       _connections = connections,
       _warps = warps,
       _triggers = triggers,
       _gameplayZones = gameplayZones,
       _mapMetadata = mapMetadata,
       _properties = properties,
       _events = events;

  factory MapHistoryDelta.between(MapData before, MapData after) {
    return MapHistoryDelta._(
      id: _valueDelta(before.id, after.id),
      name: _valueDelta(before.name, after.name),
      size: _valueDelta(before.size, after.size),
      version: _valueDelta(before.version, after.version),
      visualStack: _valueDelta(before.visualStack, after.visualStack),
      tilesetId: _valueDelta(before.tilesetId, after.tilesetId),
      layers: _MapLayersDelta.between(before.layers, after.layers),
      placedElements: _listDelta(before.placedElements, after.placedElements),
      entities: _listDelta(before.entities, after.entities),
      connections: _listDelta(before.connections, after.connections),
      warps: _listDelta(before.warps, after.warps),
      triggers: _listDelta(before.triggers, after.triggers),
      gameplayZones: _listDelta(before.gameplayZones, after.gameplayZones),
      mapMetadata: _valueDelta(before.mapMetadata, after.mapMetadata),
      properties: _valueDelta(before.properties, after.properties),
      events: _listDelta(before.events, after.events),
    );
  }

  final _ValueDelta<String>? _id;
  final _ValueDelta<String>? _name;
  final _ValueDelta<GridSize>? _size;
  final _ValueDelta<ProjectVersion>? _version;
  final _ValueDelta<MapVisualStackConfig?>? _visualStack;
  final _ValueDelta<String>? _tilesetId;
  final _MapLayersDelta? _layers;
  final _ReversibleListDelta<MapPlacedElement>? _placedElements;
  final _ReversibleListDelta<MapEntity>? _entities;
  final _ReversibleListDelta<MapConnection>? _connections;
  final _ReversibleListDelta<MapWarp>? _warps;
  final _ReversibleListDelta<MapTrigger>? _triggers;
  final _ReversibleListDelta<MapGameplayZone>? _gameplayZones;
  final _ValueDelta<MapMetadata>? _mapMetadata;
  final _ValueDelta<Map<String, dynamic>>? _properties;
  final _ReversibleListDelta<MapEventDefinition>? _events;

  bool get isEmpty => changedValueCount == 0;

  int get changedValueCount =>
      _changed(_id) +
      _changed(_name) +
      _changed(_size) +
      _changed(_version) +
      _changed(_visualStack) +
      _changed(_tilesetId) +
      (_layers?.changedValueCount ?? 0) +
      (_placedElements?.changedValueCount ?? 0) +
      (_entities?.changedValueCount ?? 0) +
      (_connections?.changedValueCount ?? 0) +
      (_warps?.changedValueCount ?? 0) +
      (_triggers?.changedValueCount ?? 0) +
      (_gameplayZones?.changedValueCount ?? 0) +
      _changed(_mapMetadata) +
      _changed(_properties) +
      (_events?.changedValueCount ?? 0);

  late final int retainedBytes =
      _retained(_id) +
      _retained(_name) +
      _retained(_size) +
      _retained(_version) +
      _retained(_visualStack) +
      _retained(_tilesetId) +
      (_layers?.retainedBytes ?? 0) +
      (_placedElements?.retainedBytes ?? 0) +
      (_entities?.retainedBytes ?? 0) +
      (_connections?.retainedBytes ?? 0) +
      (_warps?.retainedBytes ?? 0) +
      (_triggers?.retainedBytes ?? 0) +
      (_gameplayZones?.retainedBytes ?? 0) +
      _retained(_mapMetadata) +
      _retained(_properties) +
      (_events?.retainedBytes ?? 0) +
      64;

  MapData applyBackward(MapData current) {
    return _apply(current, MapHistoryDirection.backward);
  }

  MapData applyForward(MapData current) {
    return _apply(current, MapHistoryDirection.forward);
  }

  MapData _apply(MapData current, MapHistoryDirection direction) {
    var result = current;
    if (_id case final delta?) {
      result = result.copyWith(id: delta.apply(result.id, direction));
    }
    if (_name case final delta?) {
      result = result.copyWith(name: delta.apply(result.name, direction));
    }
    if (_size case final delta?) {
      result = result.copyWith(size: delta.apply(result.size, direction));
    }
    if (_version case final delta?) {
      result = result.copyWith(version: delta.apply(result.version, direction));
    }
    if (_visualStack case final delta?) {
      result = result.copyWith(
        visualStack: delta.apply(result.visualStack, direction),
      );
    }
    if (_tilesetId case final delta?) {
      result = result.copyWith(
        tilesetId: delta.apply(result.tilesetId, direction),
      );
    }
    if (_layers case final delta?) {
      result = result.copyWith(layers: delta.apply(result.layers, direction));
    }
    if (_placedElements case final delta?) {
      result = result.copyWith(
        placedElements: delta.apply(result.placedElements, direction),
      );
    }
    if (_entities case final delta?) {
      result = result.copyWith(
        entities: delta.apply(result.entities, direction),
      );
    }
    if (_connections case final delta?) {
      result = result.copyWith(
        connections: delta.apply(result.connections, direction),
      );
    }
    if (_warps case final delta?) {
      result = result.copyWith(warps: delta.apply(result.warps, direction));
    }
    if (_triggers case final delta?) {
      result = result.copyWith(
        triggers: delta.apply(result.triggers, direction),
      );
    }
    if (_gameplayZones case final delta?) {
      result = result.copyWith(
        gameplayZones: delta.apply(result.gameplayZones, direction),
      );
    }
    if (_mapMetadata case final delta?) {
      result = result.copyWith(
        mapMetadata: delta.apply(result.mapMetadata, direction),
      );
    }
    if (_properties case final delta?) {
      result = result.copyWith(
        properties: delta.apply(result.properties, direction),
      );
    }
    if (_events case final delta?) {
      result = result.copyWith(events: delta.apply(result.events, direction));
    }
    return result;
  }
}

final class _ValueDelta<T> {
  const _ValueDelta(this.before, this.after);

  final T before;
  final T after;

  int get retainedBytes =>
      estimateMapHistoryValueBytes(before) +
      estimateMapHistoryValueBytes(after) +
      24;

  T apply(T current, MapHistoryDirection direction) {
    final expected = direction == MapHistoryDirection.backward ? after : before;
    if (current != expected) {
      throw const MapHistoryDivergence('map_history_value_diverged');
    }
    return direction == MapHistoryDirection.backward ? before : after;
  }
}

abstract interface class _ReversibleListDelta<T> {
  int get changedValueCount;
  int get retainedBytes;
  List<T> apply(List<T> current, MapHistoryDirection direction);
}

final class _SparseListDelta<T> implements _ReversibleListDelta<T> {
  _SparseListDelta({
    required this.length,
    required List<int> indices,
    required List<T> beforeValues,
    required List<T> afterValues,
  }) : indices = List<int>.unmodifiable(indices),
       beforeValues = List<T>.unmodifiable(beforeValues),
       afterValues = List<T>.unmodifiable(afterValues);

  final int length;
  final List<int> indices;
  final List<T> beforeValues;
  final List<T> afterValues;

  @override
  int get changedValueCount => indices.length;

  @override
  int get retainedBytes =>
      32 +
      indices.length * 8 +
      beforeValues.fold<int>(
        0,
        (total, value) => total + estimateMapHistoryValueBytes(value),
      ) +
      afterValues.fold<int>(
        0,
        (total, value) => total + estimateMapHistoryValueBytes(value),
      );

  @override
  List<T> apply(List<T> current, MapHistoryDirection direction) {
    if (current.length != length) {
      throw const MapHistoryDivergence('map_history_list_length_diverged');
    }
    final source = direction == MapHistoryDirection.backward
        ? afterValues
        : beforeValues;
    final target = direction == MapHistoryDirection.backward
        ? beforeValues
        : afterValues;
    final result = List<T>.from(current);
    for (var offset = 0; offset < indices.length; offset++) {
      final index = indices[offset];
      if (result[index] != source[offset]) {
        throw const MapHistoryDivergence('map_history_list_value_diverged');
      }
      result[index] = target[offset];
    }
    return List<T>.unmodifiable(result);
  }
}

final class _ListSliceDelta<T> implements _ReversibleListDelta<T> {
  _ListSliceDelta({
    required this.start,
    required this.beforeLength,
    required this.afterLength,
    required List<T> beforeValues,
    required List<T> afterValues,
  }) : beforeValues = List<T>.unmodifiable(beforeValues),
       afterValues = List<T>.unmodifiable(afterValues);

  final int start;
  final int beforeLength;
  final int afterLength;
  final List<T> beforeValues;
  final List<T> afterValues;

  @override
  int get changedValueCount => beforeValues.length > afterValues.length
      ? beforeValues.length
      : afterValues.length;

  @override
  int get retainedBytes =>
      40 +
      beforeValues.fold<int>(
        0,
        (total, value) => total + estimateMapHistoryValueBytes(value),
      ) +
      afterValues.fold<int>(
        0,
        (total, value) => total + estimateMapHistoryValueBytes(value),
      );

  @override
  List<T> apply(List<T> current, MapHistoryDirection direction) {
    final expectedLength = direction == MapHistoryDirection.backward
        ? afterLength
        : beforeLength;
    final source = direction == MapHistoryDirection.backward
        ? afterValues
        : beforeValues;
    final target = direction == MapHistoryDirection.backward
        ? beforeValues
        : afterValues;
    if (current.length != expectedLength ||
        start + source.length > current.length) {
      throw const MapHistoryDivergence('map_history_list_shape_diverged');
    }
    for (var offset = 0; offset < source.length; offset++) {
      if (current[start + offset] != source[offset]) {
        throw const MapHistoryDivergence('map_history_list_slice_diverged');
      }
    }
    final result = List<T>.from(current)
      ..replaceRange(start, start + source.length, target);
    return List<T>.unmodifiable(result);
  }
}

final class _MapLayersDelta {
  _MapLayersDelta._({this.structural, this.changes = const {}});

  factory _MapLayersDelta.between(List<MapLayer> before, List<MapLayer> after) {
    if (_sameLayerIdentity(before, after)) {
      final changes = <int, _MapLayerDelta>{};
      for (var index = 0; index < before.length; index++) {
        final delta = _MapLayerDelta.between(before[index], after[index]);
        if (delta != null) {
          changes[index] = delta;
        }
      }
      return _MapLayersDelta._(
        changes: Map<int, _MapLayerDelta>.unmodifiable(changes),
      );
    }
    return _MapLayersDelta._(structural: _listDelta(before, after));
  }

  final _ReversibleListDelta<MapLayer>? structural;
  final Map<int, _MapLayerDelta> changes;

  int get changedValueCount =>
      structural?.changedValueCount ??
      changes.values.fold<int>(
        0,
        (total, delta) => total + delta.changedValueCount,
      );

  int get retainedBytes =>
      structural?.retainedBytes ??
      changes.entries.fold<int>(
        32,
        (total, entry) => total + 8 + entry.value.retainedBytes,
      );

  List<MapLayer> apply(List<MapLayer> current, MapHistoryDirection direction) {
    final structural = this.structural;
    if (structural != null) {
      return structural.apply(current, direction);
    }
    final result = List<MapLayer>.from(current);
    for (final entry in changes.entries) {
      if (entry.key >= result.length) {
        throw const MapHistoryDivergence('map_history_layer_index_diverged');
      }
      result[entry.key] = entry.value.apply(result[entry.key], direction);
    }
    return List<MapLayer>.unmodifiable(result);
  }
}

abstract interface class _MapLayerDelta {
  int get changedValueCount;
  int get retainedBytes;
  MapLayer apply(MapLayer current, MapHistoryDirection direction);

  static _MapLayerDelta? between(MapLayer before, MapLayer after) {
    if (before == after) return null;
    if (before is TileLayer && after is TileLayer) {
      final beforeShell = before.copyWith(cells: const <int>[]);
      final afterShell = after.copyWith(cells: const <int>[]);
      return _TileLayerDelta(
        beforeShell: beforeShell,
        afterShell: beforeShell == afterShell ? null : afterShell,
        cells: _listDelta(before.cells, after.cells),
      );
    }
    if (before is CollisionLayer && after is CollisionLayer) {
      final beforeShell = before.copyWith(collisions: const <bool>[]);
      final afterShell = after.copyWith(collisions: const <bool>[]);
      return _CollisionLayerDelta(
        beforeShell: beforeShell,
        afterShell: beforeShell == afterShell ? null : afterShell,
        collisions: _listDelta(before.collisions, after.collisions),
      );
    }
    if (before is SmartTileLayer && after is SmartTileLayer) {
      final beforeShell = _smartTileLayerShell(before);
      final afterShell = _smartTileLayerShell(after);
      final sparseField = _SmartTileFieldDelta.between(
        before.field,
        after.field,
      );
      return _SmartTileLayerDelta(
        beforeShell: beforeShell,
        afterShell: beforeShell == afterShell ? null : afterShell,
        sparseField: sparseField,
        replacementField: sparseField == null && before.field != after.field
            ? _ValueDelta<SmartTileField>(before.field, after.field)
            : null,
      );
    }
    return _ReplacementLayerDelta(before, after);
  }
}

final class _TileLayerDelta implements _MapLayerDelta {
  const _TileLayerDelta({
    required this.beforeShell,
    required this.afterShell,
    required this.cells,
  });

  final TileLayer beforeShell;
  final TileLayer? afterShell;
  final _ReversibleListDelta<int>? cells;

  @override
  int get changedValueCount =>
      (afterShell == null ? 0 : 1) + (cells?.changedValueCount ?? 0);

  @override
  int get retainedBytes =>
      estimateMapHistoryValueBytes(beforeShell) +
      (afterShell == null ? 0 : estimateMapHistoryValueBytes(afterShell)) +
      (cells?.retainedBytes ?? 0) +
      64;

  @override
  MapLayer apply(MapLayer current, MapHistoryDirection direction) {
    if (current is! TileLayer) {
      throw const MapHistoryDivergence('map_history_tile_layer_diverged');
    }
    final expectedShell = direction == MapHistoryDirection.backward
        ? afterShell ?? beforeShell
        : beforeShell;
    if (current.copyWith(cells: const <int>[]) != expectedShell) {
      throw const MapHistoryDivergence('map_history_tile_layer_diverged');
    }
    final targetShell = direction == MapHistoryDirection.backward
        ? beforeShell
        : afterShell ?? beforeShell;
    return targetShell.copyWith(
      cells: cells?.apply(current.cells, direction) ?? current.cells,
    );
  }
}

final class _CollisionLayerDelta implements _MapLayerDelta {
  const _CollisionLayerDelta({
    required this.beforeShell,
    required this.afterShell,
    required this.collisions,
  });

  final CollisionLayer beforeShell;
  final CollisionLayer? afterShell;
  final _ReversibleListDelta<bool>? collisions;

  @override
  int get changedValueCount =>
      (afterShell == null ? 0 : 1) + (collisions?.changedValueCount ?? 0);

  @override
  int get retainedBytes =>
      estimateMapHistoryValueBytes(beforeShell) +
      (afterShell == null ? 0 : estimateMapHistoryValueBytes(afterShell)) +
      (collisions?.retainedBytes ?? 0) +
      64;

  @override
  MapLayer apply(MapLayer current, MapHistoryDirection direction) {
    if (current is! CollisionLayer) {
      throw const MapHistoryDivergence('map_history_collision_layer_diverged');
    }
    final expectedShell = direction == MapHistoryDirection.backward
        ? afterShell ?? beforeShell
        : beforeShell;
    if (current.copyWith(collisions: const <bool>[]) != expectedShell) {
      throw const MapHistoryDivergence('map_history_collision_layer_diverged');
    }
    final targetShell = direction == MapHistoryDirection.backward
        ? beforeShell
        : afterShell ?? beforeShell;
    return targetShell.copyWith(
      collisions:
          collisions?.apply(current.collisions, direction) ??
          current.collisions,
    );
  }
}

final class _SmartTileLayerDelta implements _MapLayerDelta {
  const _SmartTileLayerDelta({
    required this.beforeShell,
    required this.afterShell,
    required this.sparseField,
    required this.replacementField,
  });

  final SmartTileLayer beforeShell;
  final SmartTileLayer? afterShell;
  final _SmartTileFieldDelta? sparseField;
  final _ValueDelta<SmartTileField>? replacementField;

  @override
  int get changedValueCount =>
      (afterShell == null ? 0 : 1) +
      (sparseField?.changedValueCount ?? 0) +
      (replacementField == null ? 0 : 1);

  @override
  int get retainedBytes =>
      estimateMapHistoryValueBytes(beforeShell) +
      (afterShell == null ? 0 : estimateMapHistoryValueBytes(afterShell)) +
      (sparseField?.retainedBytes ?? 0) +
      (replacementField?.retainedBytes ?? 0) +
      96;

  @override
  MapLayer apply(MapLayer current, MapHistoryDirection direction) {
    if (current is! SmartTileLayer) {
      throw const MapHistoryDivergence('map_history_smart_tile_layer_diverged');
    }
    final expectedShell = direction == MapHistoryDirection.backward
        ? afterShell ?? beforeShell
        : beforeShell;
    if (_smartTileLayerShell(current) != expectedShell) {
      throw const MapHistoryDivergence('map_history_smart_tile_layer_diverged');
    }
    final targetShell = direction == MapHistoryDirection.backward
        ? beforeShell
        : afterShell ?? beforeShell;
    final targetField =
        sparseField?.apply(current.field, direction) ??
        replacementField?.apply(current.field, direction) ??
        current.field;
    return targetShell.copyWith(field: targetField);
  }
}

final class _ReplacementLayerDelta implements _MapLayerDelta {
  const _ReplacementLayerDelta(this.before, this.after);

  final MapLayer before;
  final MapLayer after;

  @override
  int get changedValueCount => 1;

  @override
  int get retainedBytes =>
      estimateMapHistoryValueBytes(before) +
      estimateMapHistoryValueBytes(after) +
      24;

  @override
  MapLayer apply(MapLayer current, MapHistoryDirection direction) {
    final expected = direction == MapHistoryDirection.backward ? after : before;
    if (current != expected) {
      throw const MapHistoryDivergence('map_history_layer_diverged');
    }
    return direction == MapHistoryDirection.backward ? before : after;
  }
}

final class _SmartTileFieldDelta {
  const _SmartTileFieldDelta({
    required this.kind,
    required this.semanticCells,
    this.horizontalEdges,
    this.verticalEdges,
    this.corners,
  });

  static _SmartTileFieldDelta? between(
    SmartTileField before,
    SmartTileField after,
  ) {
    if (before.runtimeType != after.runtimeType) return null;
    final semantic = _listDelta(
      _smartTileSemanticCells(before),
      _smartTileSemanticCells(after),
    );
    final horizontal = _listDelta(
      _smartTileHorizontalEdges(before),
      _smartTileHorizontalEdges(after),
    );
    final vertical = _listDelta(
      _smartTileVerticalEdges(before),
      _smartTileVerticalEdges(after),
    );
    final corners = _listDelta(
      _smartTileCorners(before),
      _smartTileCorners(after),
    );
    if (semantic == null &&
        horizontal == null &&
        vertical == null &&
        corners == null) {
      return null;
    }
    return _SmartTileFieldDelta(
      kind: before.runtimeType,
      semanticCells: semantic,
      horizontalEdges: horizontal,
      verticalEdges: vertical,
      corners: corners,
    );
  }

  final Type kind;
  final _ReversibleListDelta<int>? semanticCells;
  final _ReversibleListDelta<int>? horizontalEdges;
  final _ReversibleListDelta<int>? verticalEdges;
  final _ReversibleListDelta<int>? corners;

  int get changedValueCount =>
      (semanticCells?.changedValueCount ?? 0) +
      (horizontalEdges?.changedValueCount ?? 0) +
      (verticalEdges?.changedValueCount ?? 0) +
      (corners?.changedValueCount ?? 0);

  int get retainedBytes =>
      (semanticCells?.retainedBytes ?? 0) +
      (horizontalEdges?.retainedBytes ?? 0) +
      (verticalEdges?.retainedBytes ?? 0) +
      (corners?.retainedBytes ?? 0) +
      48;

  SmartTileField apply(SmartTileField current, MapHistoryDirection direction) {
    if (current.runtimeType != kind) {
      throw const MapHistoryDivergence(
        'map_history_smart_tile_field_kind_diverged',
      );
    }
    final semantic =
        semanticCells?.apply(_smartTileSemanticCells(current), direction) ??
        _smartTileSemanticCells(current);
    final horizontal =
        horizontalEdges?.apply(_smartTileHorizontalEdges(current), direction) ??
        _smartTileHorizontalEdges(current);
    final vertical =
        verticalEdges?.apply(_smartTileVerticalEdges(current), direction) ??
        _smartTileVerticalEdges(current);
    final cornerValues =
        corners?.apply(_smartTileCorners(current), direction) ??
        _smartTileCorners(current);
    return switch (current) {
      SmartTileCellField value => value.copyWith(semanticCells: semantic),
      SmartTileCornerField value => value.copyWith(
        semanticCells: semantic,
        corners: cornerValues,
      ),
      SmartTileEdgeField value => value.copyWith(
        semanticCells: semantic,
        horizontalEdges: horizontal,
        verticalEdges: vertical,
      ),
      SmartTileMixedField value => value.copyWith(
        semanticCells: semantic,
        horizontalEdges: horizontal,
        verticalEdges: vertical,
        corners: cornerValues,
      ),
    };
  }
}

_ValueDelta<T>? _valueDelta<T>(T before, T after) {
  return before == after ? null : _ValueDelta<T>(before, after);
}

_ReversibleListDelta<T>? _listDelta<T>(List<T> before, List<T> after) {
  if (before.length == after.length) {
    final indices = <int>[];
    final beforeValues = <T>[];
    final afterValues = <T>[];
    for (var index = 0; index < before.length; index++) {
      if (before[index] == after[index]) continue;
      indices.add(index);
      beforeValues.add(before[index]);
      afterValues.add(after[index]);
    }
    if (indices.isEmpty) return null;
    return _SparseListDelta<T>(
      length: before.length,
      indices: indices,
      beforeValues: beforeValues,
      afterValues: afterValues,
    );
  }
  var prefix = 0;
  final shortest = before.length < after.length ? before.length : after.length;
  while (prefix < shortest && before[prefix] == after[prefix]) {
    prefix++;
  }
  var suffix = 0;
  while (suffix < shortest - prefix &&
      before[before.length - 1 - suffix] == after[after.length - 1 - suffix]) {
    suffix++;
  }
  return _ListSliceDelta<T>(
    start: prefix,
    beforeLength: before.length,
    afterLength: after.length,
    beforeValues: before.sublist(prefix, before.length - suffix),
    afterValues: after.sublist(prefix, after.length - suffix),
  );
}

bool _sameLayerIdentity(List<MapLayer> before, List<MapLayer> after) {
  if (before.length != after.length) return false;
  for (var index = 0; index < before.length; index++) {
    if (before[index].id != after[index].id ||
        before[index].runtimeType != after[index].runtimeType) {
      return false;
    }
  }
  return true;
}

SmartTileLayer _smartTileLayerShell(SmartTileLayer layer) =>
    layer.copyWith(field: const SmartTileField.cell(semanticCells: <int>[]));

List<int> _smartTileSemanticCells(SmartTileField field) => switch (field) {
  SmartTileCellField value => value.semanticCells,
  SmartTileCornerField value => value.semanticCells,
  SmartTileEdgeField value => value.semanticCells,
  SmartTileMixedField value => value.semanticCells,
};

List<int> _smartTileHorizontalEdges(SmartTileField field) => switch (field) {
  SmartTileEdgeField value => value.horizontalEdges,
  SmartTileMixedField value => value.horizontalEdges,
  _ => const <int>[],
};

List<int> _smartTileVerticalEdges(SmartTileField field) => switch (field) {
  SmartTileEdgeField value => value.verticalEdges,
  SmartTileMixedField value => value.verticalEdges,
  _ => const <int>[],
};

List<int> _smartTileCorners(SmartTileField field) => switch (field) {
  SmartTileCornerField value => value.corners,
  SmartTileMixedField value => value.corners,
  _ => const <int>[],
};

int _changed(Object? delta) => delta == null ? 0 : 1;

int _retained<T>(_ValueDelta<T>? delta) => delta?.retainedBytes ?? 0;

int estimateMapHistoryValueBytes(Object? value) {
  if (value == null) return 1;
  if (value is bool) return 1;
  if (value is num || value is Enum) return 8;
  if (value is String) return utf8.encode(value).length + 16;
  if (value is List<Object?>) {
    return 24 +
        value.fold<int>(
          0,
          (total, item) => total + estimateMapHistoryValueBytes(item),
        );
  }
  if (value is Map<Object?, Object?>) {
    return 48 +
        value.entries.fold<int>(
          0,
          (total, entry) =>
              total +
              estimateMapHistoryValueBytes(entry.key) +
              estimateMapHistoryValueBytes(entry.value),
        );
  }
  try {
    final json = (value as dynamic).toJson();
    return utf8.encode(jsonEncode(json)).length + 32;
  } on Object {
    return value.toString().length * 2 + 32;
  }
}

int estimateMapDataSnapshotBytes(MapData map) {
  return utf8.encode(jsonEncode(map.toJson())).length;
}
