import 'dart:convert';

import 'package:map_core/map_core.dart';

abstract final class CatalogResourcePositions {
  static const sections = {
    CatalogDefinitionKind.model3d: 'models3d',
    CatalogDefinitionKind.tileset: 'tilesets',
    CatalogDefinitionKind.character: 'characters',
    CatalogDefinitionKind.resourceLibraryEntry: 'resourceLibraryCatalog.entries',
    CatalogDefinitionKind.smartTileAtlas: 'smartTileCatalog.atlases',
    CatalogDefinitionKind.smartTileAnimation: 'smartTileCatalog.animations',
    CatalogDefinitionKind.smartTileMaterial: 'smartTileCatalog.materials',
    CatalogDefinitionKind.smartTilePattern: 'smartTileCatalog.patterns',
    CatalogDefinitionKind.smartTilePreset: 'smartTileCatalog.presets',
    CatalogDefinitionKind.borderRecord: 'borderCatalog.records',
    CatalogDefinitionKind.environmentPreset: 'environmentPresets',
  };

  static const familySection = 'resourceLibraryCatalog.families';

  static String? sectionOf(CatalogDefinitionKind kind) =>
      kind == CatalogDefinitionKind.resourceFamily
          ? familySection
          : sections[kind];

  static int contiguousCount(Iterable<CatalogDefinitionUnit> units) =>
      _validatePositions(units);

  static CatalogDefinitionKey key(CatalogDefinitionKind kind) =>
      CatalogDefinitionKey(CatalogDefinitionKind.workspaceState,
          jsonEncode(['resourcePositions', kind.name]));

  static int _count(CatalogDefinitionUnit? state) {
    final count = state?.payload['count'];
    if (state?.payload['schemaVersion'] != 1 ||
        state?.payload['valid'] != true ||
        count is! int ||
        count < 0) {
      throw const FormatException(
          'catalog.resource_positions.preparation_required');
    }
    return count;
  }

  static Future<int> read(
          CatalogSnapshot snapshot, CatalogDefinitionKind kind) async =>
      _count(await snapshot.lookup(key(kind)));

  static CatalogDefinitionUnit _state(CatalogDefinitionKind kind, int count,
          {bool valid = true}) =>
      CatalogDefinitionUnit(key: key(kind), payload: {
        'schemaVersion': 1,
        'count': count,
        'valid': valid,
      });

  static List<CatalogDefinitionUnit> initialize(
          Iterable<CatalogDefinitionUnit> units) =>
      [
        for (final kind in sections.keys)
          _state(kind,
              _validatePositions(units.where((unit) => unit.key.kind == kind))),
      ];

  static int _validatePositions(Iterable<CatalogDefinitionUnit> units) {
    final positions = units.map((unit) => unit.payload['position']).toList();
    if (positions.any((value) => value is! int || value < 0)) {
      throw const FormatException(
          'catalog.resource_positions.invalid_position');
    }
    final ordered = positions.cast<int>()..sort();
    for (var index = 0; index < ordered.length; index++) {
      if (ordered[index] != index) {
        throw const FormatException(
            'catalog.resource_positions.non_contiguous');
      }
    }
    return ordered.length;
  }

  static Future<List<CatalogDefinitionUnit>> prepare(CatalogSnapshot snapshot,
      {required Set<CatalogDefinitionKind> kinds}) async {
    final result = <CatalogDefinitionUnit>[
      if (kinds.any(slotKinds.contains)) ...await prepareSlots(snapshot),
    ];
    for (final kind in kinds) {
      if (slotKinds.contains(kind)) continue;
      final state = await snapshot.lookup(key(kind));
      if (state?.payload['valid'] == true &&
          state?.payload['schemaVersion'] == 1) {
        continue;
      }
      result.add(_state(
          kind, _validatePositions(await readUnits(snapshot, kind))));
    }
    return result;
  }

  static const slotKinds = {CatalogDefinitionKind.resourceLibraryEntry};
  static const slotChunkSize = 256;

  static CatalogDefinitionKey slotHeaderKey(CatalogDefinitionKind kind) =>
      CatalogDefinitionKey(CatalogDefinitionKind.workspaceState,
          jsonEncode(['resourceSlots', kind.name]));

  static CatalogDefinitionKey slotChunkKey(
          CatalogDefinitionKind kind, int chunk) =>
      CatalogDefinitionKey(CatalogDefinitionKind.workspaceState,
          jsonEncode(['resourceSlots', kind.name, chunk]));

  static bool isSlotKey(CatalogDefinitionKey key) =>
      key.kind == CatalogDefinitionKind.workspaceState &&
      key.id.startsWith('["resourceSlots",');

  static CatalogDefinitionUnit _slotHeader(CatalogDefinitionKind kind, int count,
          {bool valid = true}) =>
      CatalogDefinitionUnit(key: slotHeaderKey(kind), payload: {
        'schemaVersion': 1,
        'count': count,
        'valid': valid,
      });

  static bool _slotsReady(CatalogDefinitionUnit? state,
          CatalogDefinitionUnit? header) =>
      state?.payload['schemaVersion'] == 1 &&
      state?.payload['valid'] == true &&
      header?.payload['schemaVersion'] == 1 &&
      header?.payload['valid'] == true &&
      header?.payload['count'] == state?.payload['count'];

  static Future<String> readSlot(CatalogSnapshot snapshot,
      CatalogDefinitionKind kind, int position) async {
    final state = await snapshot.lookup(key(kind));
    final count = _count(state);
    if (!slotKinds.contains(kind) ||
        !_slotsReady(state, await snapshot.lookup(slotHeaderKey(kind)))) {
      throw const FormatException(
          'catalog.resource_positions.slots_preparation_required');
    }
    if (position < 0 || position >= count) {
      throw const FormatException(
          'catalog.resource_positions.invalid_position');
    }
    final chunk =
        await snapshot.lookup(slotChunkKey(kind, position ~/ slotChunkSize));
    final ids = chunk?.payload['ids'];
    final offset = position % slotChunkSize;
    if (ids is! List || offset >= ids.length || ids[offset] is! String) {
      throw const FormatException('catalog.resource_positions.slots_stale');
    }
    return ids[offset] as String;
  }

  static List<CatalogDefinitionUnit> _slotUnits(
      CatalogDefinitionKind kind, Iterable<CatalogDefinitionUnit> units) {
    final ordered = units.toList()
      ..sort((a, b) => (a.payload['position'] as int)
          .compareTo(b.payload['position'] as int));
    return [
      for (var start = 0; start < ordered.length; start += slotChunkSize)
        CatalogDefinitionUnit(
            key: slotChunkKey(kind, start ~/ slotChunkSize),
            payload: {
              'ids': [
                for (final unit in ordered.skip(start).take(slotChunkSize))
                  unit.key.id
              ]
            }),
      _slotHeader(kind, ordered.length),
    ];
  }

  static Future<List<CatalogDefinitionUnit>> prepareSlots(
      CatalogSnapshot snapshot) async {
    final result = <CatalogDefinitionUnit>[];
    for (final kind in slotKinds) {
      final state = await snapshot.lookup(key(kind));
      if (_slotsReady(state, await snapshot.lookup(slotHeaderKey(kind)))) {
        continue;
      }
      final units = await readUnits(snapshot, kind);
      final count = _validatePositions(units);
      if (state?.payload['schemaVersion'] != 1 ||
          state?.payload['valid'] != true ||
          state?.payload['count'] != count) {
        result.add(_state(kind, count));
      }
      result.addAll(_slotUnits(kind, units));
    }
    return result;
  }

  static Future<List<CatalogDefinitionUnit>> readUnits(
      CatalogSnapshot snapshot, CatalogDefinitionKind kind) async {
    final units = <CatalogDefinitionUnit>[];
    String? cursor;
    do {
      final page = await snapshot.page(
          kind: kind, limit: snapshot.limits.indexPageSize, cursor: cursor);
      for (final entry in page.items) {
        units.add((await snapshot.lookup(entry.key))!);
      }
      cursor = page.nextCursor;
    } while (cursor != null);
    return units;
  }

  static Future<List<CatalogDefinitionUnit>> maintain({
    required Future<CatalogDefinitionUnit?> Function(CatalogDefinitionKey)
        lookup,
    required Iterable<CatalogDefinitionUnit> upserts,
    required Iterable<CatalogDefinitionKey> removals,
  }) async {
    final result = <CatalogDefinitionUnit>[];
    final changes = upserts.toList();
    final deleted = removals.toList();
    for (final kind in sections.keys) {
      final rows = changes.where((unit) => unit.key.kind == kind).toList();
      if (rows.isEmpty && !deleted.any((key) => key.kind == kind)) continue;
      final state = await lookup(key(kind));
      if (state == null || state.payload['valid'] != true) continue;
      if (slotKinds.contains(kind)) {
        result.addAll(await _maintainSlots(kind, state, rows,
            deleted.where((key) => key.kind == kind).toList(), lookup));
        continue;
      }
      var count = _count(state);
      var valid = !deleted.any((key) => key.kind == kind);
      rows.sort((a, b) => (a.payload['position'] as int)
          .compareTo(b.payload['position'] as int));
      for (final row in rows) {
        final before = await lookup(row.key);
        if (before != null) {
          valid =
              valid && before.payload['position'] == row.payload['position'];
        } else if (row.payload['position'] == count) {
          count++;
        } else {
          valid = false;
        }
      }
      if (count != state.payload['count'] || !valid) {
        result.add(_state(kind, count, valid: valid));
      }
    }
    return result;
  }

  static Future<List<CatalogDefinitionUnit>> _maintainSlots(
      CatalogDefinitionKind kind,
      CatalogDefinitionUnit state,
      List<CatalogDefinitionUnit> rows,
      List<CatalogDefinitionKey> deleted,
      Future<CatalogDefinitionUnit?> Function(CatalogDefinitionKey) lookup) async {
    final count = _count(state);
    final header = await lookup(slotHeaderKey(kind));
    final vacated = <int, String>{};
    final occupied = <int, String>{};
    var valid = true;
    var removed = 0;
    var appended = 0;
    for (final key in deleted) {
      final before = await lookup(key);
      if (before == null) continue;
      final position = before.payload['position'];
      if (position is! int || vacated.containsKey(position)) {
        valid = false;
        continue;
      }
      vacated[position] = key.id;
      removed++;
    }
    for (final row in rows) {
      final before = await lookup(row.key);
      final position = row.payload['position'];
      if (position is! int || occupied.containsKey(position)) {
        valid = false;
        continue;
      }
      if (before == null) {
        appended++;
      } else if (before.payload['position'] == position) {
        continue;
      } else {
        final previous = before.payload['position'];
        if (previous is! int || vacated.containsKey(previous)) {
          valid = false;
          continue;
        }
        vacated[previous] = row.key.id;
      }
      occupied[position] = row.key.id;
    }
    final next = count - removed + appended;
    if (valid) {
      for (final position in occupied.keys) {
        if (position < 0 ||
            position >= next ||
            (position < count && !vacated.containsKey(position))) {
          valid = false;
        }
      }
      for (final position in vacated.keys) {
        if (position < next && !occupied.containsKey(position)) valid = false;
      }
      for (var position = next; position < count && valid; position++) {
        if (!vacated.containsKey(position)) valid = false;
      }
      for (var position = count; position < next && valid; position++) {
        if (!occupied.containsKey(position)) valid = false;
      }
    }
    final result = <CatalogDefinitionUnit>[];
    if (!valid || next != count) result.add(_state(kind, next, valid: valid));
    if (header == null) return result;
    if (!valid || !_slotsReady(state, header)) {
      if (header.payload['valid'] == true) {
        result.add(_slotHeader(kind, count, valid: false));
      }
      return result;
    }
    final chunks = <int, List<String>>{};
    Future<List<String>?> chunk(int index) async {
      if (chunks.containsKey(index)) return chunks[index];
      final unit = await lookup(slotChunkKey(kind, index));
      final ids = unit?.payload['ids'];
      final length =
          (count - index * slotChunkSize).clamp(0, slotChunkSize);
      if (length > 0 &&
          (ids is! List || ids.length < length || ids.any((id) => id is! String))) {
        return null;
      }
      return chunks[index] = [
        for (final id in (ids as List? ?? const []).take(length)) id as String
      ];
    }

    var consistent = true;
    for (final entry in vacated.entries) {
      final ids = await chunk(entry.key ~/ slotChunkSize);
      final offset = entry.key % slotChunkSize;
      if (ids == null || offset >= ids.length || ids[offset] != entry.value) {
        consistent = false;
      }
    }
    final touched = {
      for (final position in [...occupied.keys, ...vacated.keys])
        position ~/ slotChunkSize,
    };
    if (consistent) {
      for (final index in touched) {
        final ids = await chunk(index);
        if (ids == null) {
          consistent = false;
          break;
        }
      }
    }
    if (!consistent) {
      result.add(_slotHeader(kind, count, valid: false));
      return result;
    }
    for (final entry in occupied.entries) {
      final ids = chunks[entry.key ~/ slotChunkSize]!;
      final offset = entry.key % slotChunkSize;
      while (ids.length <= offset) {
        ids.add('');
      }
      ids[offset] = entry.value;
    }
    for (final index in touched) {
      final length = (next - index * slotChunkSize).clamp(0, slotChunkSize);
      final ids = chunks[index]!;
      if (ids.length > length) ids.removeRange(length, ids.length);
      result.add(CatalogDefinitionUnit(
          key: slotChunkKey(kind, index), payload: {'ids': ids}));
    }
    if (next != count) result.add(_slotHeader(kind, next));
    return result;
  }
}
