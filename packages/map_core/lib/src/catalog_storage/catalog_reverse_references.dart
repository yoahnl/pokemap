part of 'catalog_storage.dart';

abstract final class CatalogReverseReferences {
  static final marker = CatalogDefinitionKey(
    CatalogDefinitionKind.workspaceState,
    'reverseReferences',
  );

  static CatalogDefinitionKey _key(CatalogDefinitionKey target) =>
      CatalogDefinitionKey(
        CatalogDefinitionKind.workspaceState,
        'reverseReferences:${crypto.sha256.convert(_encode(target.toJson()))}',
      );

  static bool owns(CatalogDefinitionKey key) =>
      key.kind == CatalogDefinitionKind.workspaceState &&
      (key == marker || key.id.startsWith('reverseReferences:'));

  static Future<bool> prepared(CatalogSnapshot snapshot) async {
    final unit = await snapshot.lookup(marker);
    if (unit == null) return false;
    if (unit.payload.length != 1 ||
        unit.payload['schemaVersion'] != 1 ||
        unit.references.isNotEmpty) {
      throw const FormatException('catalog.reverse: unsupported marker');
    }
    return true;
  }

  static Set<CatalogDefinitionKey> _decode(
    CatalogDefinitionUnit? unit,
    CatalogDefinitionKey target,
  ) {
    if (unit == null) return {};
    final payload = unit.payload;
    if (payload.length != 3 ||
        payload['schemaVersion'] != 1 ||
        utf8.decode(_encode(_map(payload['target']))) !=
            utf8.decode(_encode(target.toJson())) ||
        payload['consumers'] is! List ||
        unit.references.isNotEmpty) {
      throw const FormatException('catalog.reverse: invalid consumers');
    }
    final keys = (payload['consumers'] as List)
        .map((value) => CatalogDefinitionKey.fromJson(_map(value)))
        .toList();
    _ordered(keys);
    return keys.toSet();
  }

  static Future<Set<CatalogDefinitionKey>> consumers(
    CatalogSnapshot snapshot,
    CatalogDefinitionKey target,
  ) async {
    if (!await prepared(snapshot)) {
      throw const FormatException('catalog.reverse: preparation_required');
    }
    return Set.unmodifiable(
      _decode(await snapshot.lookup(_key(target)), target),
    );
  }

  static CatalogDefinitionUnit _unit(
    CatalogDefinitionKey target,
    Set<CatalogDefinitionKey> consumers,
  ) => CatalogDefinitionUnit(
    key: _key(target),
    payload: {
      'schemaVersion': 1,
      'target': target.toJson(),
      'consumers': (consumers.toList()..sort())
          .map((key) => key.toJson())
          .toList(),
    },
  );

  static List<CatalogDefinitionUnit> initialize(
    Iterable<CatalogDefinitionUnit> units,
  ) {
    final incoming = <CatalogDefinitionKey, Set<CatalogDefinitionKey>>{};
    for (final unit in units) {
      if (owns(unit.key)) continue;
      for (final target in unit.references) {
        incoming.putIfAbsent(target, () => {}).add(unit.key);
      }
    }
    return [
      CatalogDefinitionUnit(key: marker, payload: {'schemaVersion': 1}),
      for (final entry in incoming.entries) _unit(entry.key, entry.value),
    ];
  }

  static void validate(Iterable<CatalogDefinitionUnit> units) {
    final indexed = {
      for (final unit in units.where((unit) => owns(unit.key))) unit.key: unit,
    };
    if (!indexed.containsKey(marker)) {
      if (indexed.isNotEmpty) {
        throw const FormatException('catalog.reverse: missing marker');
      }
      return;
    }
    final expected = initialize(units);
    if (expected.length != indexed.length ||
        expected.any(
          (unit) =>
              indexed[unit.key] == null ||
              utf8.decode(_encode(unit.toJson())) !=
                  utf8.decode(_encode(indexed[unit.key]!.toJson())),
        )) {
      throw const FormatException('catalog.reverse: inconsistent index');
    }
  }

  static Future<Map<CatalogDefinitionKey, CatalogDefinitionUnit?>> _maintain(
    CatalogSnapshot snapshot,
    Map<CatalogDefinitionKey, CatalogDefinitionUnit?> changed,
  ) async {
    final incoming = <CatalogDefinitionKey, Set<CatalogDefinitionKey>>{};
    Future<Set<CatalogDefinitionKey>> facet(CatalogDefinitionKey key) async =>
        incoming[key] ??= _decode(await snapshot.lookup(_key(key)), key);
    for (final entry in changed.entries) {
      if (owns(entry.key)) {
        throw const FormatException('catalog.reverse: reserved mutation');
      }
      final before =
          (await snapshot.lookup(entry.key))?.references.toSet() ?? {};
      final after = entry.value?.references.toSet() ?? {};
      for (final target in before.difference(after)) {
        (await facet(target)).remove(entry.key);
      }
      for (final target in after.difference(before)) {
        (await facet(target)).add(entry.key);
      }
    }
    return {
      for (final entry in incoming.entries)
        _key(entry.key): entry.value.isEmpty
            ? null
            : _unit(entry.key, entry.value),
    };
  }
}
