part of 'map_exterior_decoration_authoring.dart';

extension MapExteriorDecorationBorderAuthoring
    on LocalMapExteriorDecorationAuthoring {
  Future<MapExteriorDecorationMutation> setBorder(
          {required String projectRoot,
          required String mapId,
          String? mapRelativePath,
          required String expectedRevision,
          required ExteriorDecorationBorder border,
          required String operationId,
          FutureOr<void> Function()? precondition}) =>
      _mutate(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          expectedRevision: expectedRevision,
          operationId: operationId,
          descriptor: LocalMapExteriorDecorationAuthoring.borderSetDescriptor,
          parameters: {'border': border.toJson()},
          precondition: precondition,
          prepare: (context, index) async {
            final definition = index.definition;
            if (definition == null) {
              throw const FormatException(
                  'Configure exterior decoration before editing Borders.');
            }
            _withVisuals(definition, const [], [border])
                .validateForMap(context.map);
            final path = _borderPath(mapId, border.id);
            final json = border.toJson();
            final bytes = _encode(
                json, LocalMapExteriorDecorationAuthoring.maximumBorderBytes);
            final summary = _SectorSummary.fromBorder(border,
                computeAuthoringBytesFingerprint(bytes, logicalName: path));
            final next = _DecorationIndex(definition, index.sectors,
                borders: {...index.borders, border.id: summary});
            next.validate();
            if (index.borders.containsKey(border.id)) {
              await _readBorder(context, index.borders[border.id]!);
            } else if (await _readBytes(context, path,
                    LocalMapExteriorDecorationAuthoring.maximumBorderBytes) !=
                null) {
              throw const FormatException(
                  'An unindexed exterior Border requires explicit recovery.');
            }
            return {context.storageKey: next.toJson(), path: json};
          });
  Future<MapExteriorDecorationMutation> removeBorder(
          {required String projectRoot,
          required String mapId,
          String? mapRelativePath,
          required String expectedRevision,
          required String borderId,
          required String operationId,
          FutureOr<void> Function()? precondition}) =>
      _mutate(
          projectRoot: projectRoot,
          mapId: mapId,
          mapRelativePath: mapRelativePath,
          expectedRevision: expectedRevision,
          operationId: operationId,
          descriptor:
              LocalMapExteriorDecorationAuthoring.borderRemoveDescriptor,
          parameters: {'borderId': borderId},
          precondition: precondition,
          prepare: (context, index) async {
            _safeId(borderId);
            final summary = index.borders[borderId];
            if (summary == null) {
              throw const FormatException('Unknown exterior Border.');
            }
            await _readBorder(context, summary);
            final next = _DecorationIndex(index.definition, index.sectors,
                borders: {...index.borders}..remove(borderId));
            return {
              context.storageKey: next.toJson(),
              _borderPath(mapId, borderId): null
            };
          });
  Future<ExteriorDecorationBorder> _readBorder(
      _DecorationContext context, _SectorSummary summary) async {
    final path = _borderPath(context.map.id, summary.id);
    final bytes = await _readBytes(
        context, path, LocalMapExteriorDecorationAuthoring.maximumBorderBytes);
    if (bytes == null ||
        computeAuthoringBytesFingerprint(bytes, logicalName: path) !=
            summary.revision) {
      throw const FormatException(
          'Required exterior Border is missing or changed.');
    }
    _observer?.incrementCounter(AuthoringPerformanceCounterName.jsonDecode);
    final border = ExteriorDecorationBorder.fromJson(_decode(bytes));
    if (jsonEncode(
            _SectorSummary.fromBorder(border, summary.revision).toJson()) !=
        jsonEncode(summary.toJson())) {
      throw const FormatException('Exterior Border summary mismatch.');
    }
    return border;
  }
}

String _borderPath(String mapId, String id) {
  _safeId(id);
  return 'maps/$mapId.decoration/borders/$id.json';
}
