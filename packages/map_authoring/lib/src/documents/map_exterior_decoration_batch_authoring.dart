part of 'map_exterior_decoration_authoring.dart';

extension MapExteriorDecorationBatchAuthoring
    on LocalMapExteriorDecorationAuthoring {
  Future<MapExteriorDecorationMutation> setSectors({
    required String projectRoot,
    required String mapId,
    String? mapRelativePath,
    required String expectedRevision,
    required Iterable<ExteriorDecorationSector> sectors,
    Iterable<String> removeSectorIds = const [],
    required String operationId,
    FutureOr<void> Function()? precondition,
  }) {
    final changed = sectors.toList(growable: false);
    final removed = removeSectorIds.toList(growable: false);
    final ids = changed.map((sector) => sector.id).toSet();
    if (changed.length + removed.length == 0 ||
        changed.length + removed.length > MapExteriorDecoration.maxSectors ||
        ids.length != changed.length ||
        removed.toSet().length != removed.length ||
        removed.any(ids.contains)) {
      throw const FormatException(
          'A sector batch requires unique, disjoint, bounded changes.');
    }
    for (final id in [...ids, ...removed]) {
      _safeId(id);
    }
    return _mutate(
      projectRoot: projectRoot,
      mapId: mapId,
      mapRelativePath: mapRelativePath,
      expectedRevision: expectedRevision,
      operationId: operationId,
      descriptor: LocalMapExteriorDecorationAuthoring.sectorBatchDescriptor,
      parameters: {
        'sectors': changed.map((sector) => sector.toJson()).toList(),
        'removeSectorIds': removed
      },
      precondition: precondition,
      prepare: (context, index) async {
        final definition = index.definition;
        if (definition == null) {
          throw const FormatException(
              'Configure exterior decoration before editing sectors.');
        }
        _withSectors(definition, changed).validateForMap(context.map);
        final summaries = {...index.sectors};
        final writes = <String, Map<String, dynamic>?>{};
        for (final sector in changed) {
          final path = _sectorPath(mapId, sector.id);
          final previous = index.sectors[sector.id];
          if (previous != null) {
            await _readSector(context, previous);
          } else if (await _readBytes(context, path,
                  LocalMapExteriorDecorationAuthoring.maximumSectorBytes) !=
              null) {
            throw const FormatException(
                'An unindexed exterior decoration sector requires explicit recovery.');
          }
          final json = sector.toJson();
          final bytes = _encode(
              json, LocalMapExteriorDecorationAuthoring.maximumSectorBytes);
          summaries[sector.id] = _SectorSummary.fromSector(sector,
              computeAuthoringBytesFingerprint(bytes, logicalName: path));
          writes[path] = json;
        }
        for (final id in removed) {
          final previous = summaries.remove(id);
          if (previous == null) {
            throw const FormatException('Unknown exterior decoration sector.');
          }
          await _readSector(context, previous);
          writes[_sectorPath(mapId, id)] = null;
        }
        final next =
            _DecorationIndex(definition, summaries, borders: index.borders);
        next.validate();
        return {context.storageKey: next.toJson(), ...writes};
      },
    );
  }
}
