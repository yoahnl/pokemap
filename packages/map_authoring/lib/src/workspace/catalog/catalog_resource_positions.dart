import 'dart:convert';

import 'package:map_core/map_core.dart';

abstract final class CatalogResourcePositions {
  static const sections = {
    CatalogDefinitionKind.model3d: 'models3d',
    CatalogDefinitionKind.tileset: 'tilesets',
    CatalogDefinitionKind.character: 'characters',
    CatalogDefinitionKind.resourceLibraryEntry: 'resourceLibraryCatalog.entries',
    CatalogDefinitionKind.smartTileAtlas: 'smartTileCatalog.atlases',
    CatalogDefinitionKind.smartTileMaterial: 'smartTileCatalog.materials',
    CatalogDefinitionKind.smartTilePattern: 'smartTileCatalog.patterns',
    CatalogDefinitionKind.smartTilePreset: 'smartTileCatalog.presets',
    CatalogDefinitionKind.borderRecord: 'borderCatalog.records',
    CatalogDefinitionKind.environmentPreset: 'environmentPresets',
  };

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
    final result = <CatalogDefinitionUnit>[];
    for (final kind in kinds) {
      final state = await snapshot.lookup(key(kind));
      if (state?.payload['valid'] == true &&
          state?.payload['schemaVersion'] == 1) {
        continue;
      }
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
      result.add(_state(kind, _validatePositions(units)));
    }
    return result;
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
}
