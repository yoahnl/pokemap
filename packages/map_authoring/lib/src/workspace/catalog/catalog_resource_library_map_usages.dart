part of 'catalog_resource_usage_index.dart';

Future<Map<String, Set<String>>?> readCatalogResourceLibraryMapUsages(
  CatalogSnapshot snapshot, {
  required Iterable<String> identities,
  required Set<String> mapIds,
  Map<String, Set<CatalogDefinitionKey>> exteriorMapTargets = const {},
}) async {
  if (!await CatalogResourceUsageIndex.prepared(snapshot)) return null;
  final targets = <String, String>{};
  for (final identity in identities) {
    final separator = identity.indexOf(':');
    if (separator < 1 || separator == identity.length - 1) {
      throw const FormatException('catalog.resource_usage.invalid_identity');
    }
    targets[identity] = CatalogResourceUsageIndex._mapUsageIdentity(
        identity.substring(0, separator), identity.substring(separator + 1));
  }
  final graph = await _CatalogResourceLibraryMapGraph.read(
      snapshot, targets.values.toSet());
  for (final entry in exteriorMapTargets.entries) {
    if (!mapIds.contains(entry.key)) {
      throw const FormatException('catalog.resource_usage.unknown_map');
    }
    for (final target in entry.value) {
      graph.add(
          'map:${entry.key}',
          CatalogResourceUsageIndex._mapUsageIdentity(
              target.kind.name, target.id));
    }
  }
  final usages = graph.mapUsages(targets.values.toSet(), mapIds);
  return Map.unmodifiable({
    for (final entry in targets.entries)
      if (usages[entry.value] case final maps?)
        entry.key: Set.unmodifiable(maps),
  });
}

final class _CatalogResourceLibraryMapGraph {
  final _dependencies = <String, Set<String>>{};

  void add(String owner, String target) =>
      _dependencies.putIfAbsent(owner, () => {}).add(target);

  static Future<_CatalogResourceLibraryMapGraph> read(
      CatalogSnapshot snapshot, Set<String> targets) async {
    final graph = _CatalogResourceLibraryMapGraph();
    final visited = {...targets};
    var pending = targets;
    final sources = <String, ({String owner, Set<String> targets})>{};
    while (pending.isNotEmpty) {
      final consumers =
          await _readIndexRows(snapshot, 'resourceUsageConsumers', pending);
      final sourcesByTarget = {
        for (final entry in consumers.entries)
          entry.key: CatalogResourceUsageIndex._strings(
              entry.value, entry.key, 'sources'),
      };
      final missingSources = {
        for (final names in sourcesByTarget.values)
          for (final name in names)
            if (!sources.containsKey(name)) name,
      };
      final definitions =
          await _readIndexRows(snapshot, 'resourceUsageSource', missingSources);
      if (definitions.length != missingSources.length) {
        throw const FormatException('catalog.resource_usage.stale_consumer');
      }
      for (final entry in definitions.entries) {
        final owner = entry.value.payload['owner'];
        if (owner is! String || owner.isEmpty) {
          throw const FormatException('catalog.resource_usage.stale_consumer');
        }
        sources[entry.key] = (
          owner: owner,
          targets: CatalogResourceUsageIndex._strings(
              entry.value, entry.key, 'targets')
        );
      }
      final next = <String>{};
      for (final entry in sourcesByTarget.entries) {
        for (final source in entry.value) {
          final record = sources[source]!;
          if (!record.targets.contains(entry.key)) {
            throw const FormatException(
                'catalog.resource_usage.stale_consumer');
          }
          graph.add(record.owner, entry.key);
          if (visited.add(record.owner)) next.add(record.owner);
        }
      }
      pending = next;
    }
    return graph;
  }

  static Future<Map<String, CatalogDefinitionUnit>> _readIndexRows(
      CatalogSnapshot snapshot, String rowKind, Set<String> identities) async {
    final selection = [
      for (final id in identities)
        (id, CatalogResourceUsageIndex._key(rowKind, id)),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    final rows = <String, CatalogDefinitionUnit>{};
    for (var cursor = 0; cursor < selection.length;) {
      final batch = selection.skip(cursor).take(24);
      final units =
          await Future.wait(batch.map((entry) => snapshot.lookup(entry.$2)));
      for (final (index, unit) in units.indexed) {
        if (unit != null) rows[selection[cursor + index].$1] = unit;
      }
      cursor += units.length;
    }
    return rows;
  }

  Iterable<String> _reachable(String owner) sync* {
    final visited = {owner};
    final pending = [owner];
    for (var cursor = 0; cursor < pending.length; cursor++) {
      for (final target in _dependencies[pending[cursor]] ?? const <String>{}) {
        if (!visited.add(target)) continue;
        yield target;
        pending.add(target);
      }
    }
  }

  Map<String, Set<String>> mapUsages(Set<String> targets, Set<String> mapIds) {
    final shared =
        _reachable('project:project').where(targets.contains).toSet();
    final result = {for (final target in shared) target: mapIds};
    for (final mapId in mapIds) {
      for (final target in _reachable('map:$mapId')) {
        if (targets.contains(target) && !shared.contains(target)) {
          result.putIfAbsent(target, () => {}).add(mapId);
        }
      }
    }
    return result;
  }
}
