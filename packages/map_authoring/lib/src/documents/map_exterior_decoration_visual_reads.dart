part of 'map_exterior_decoration_authoring.dart';

Future<MapExteriorDecoration?> loadMapExteriorDecoration({
  required String projectRoot,
  required MapData map,
  ProjectFileReader? reader,
  String? mapRelativePath,
}) =>
    _readMapExteriorDecoration(
      reader ?? const LocalProjectFileReader(),
      projectRoot,
      map.id,
      mapRelativePath,
      baseMap: map,
    );

Future<Map<String, Set<CatalogDefinitionKey>>>
    readExteriorDecorationResourceReferences({
  required ProjectFileReader reader,
  required String projectRoot,
  required Iterable<ProjectMapEntry> maps,
}) async {
  final result = <String, Set<CatalogDefinitionKey>>{};
  for (final map in maps) {
    final decoration = await _readMapExteriorDecoration(
        reader, projectRoot, map.id, map.relativePath);
    if (decoration == null) continue;
    result[map.id] = Set.unmodifiable({
      for (final sector in decoration.sectors)
        ...exteriorSectorReferences(sector),
      for (final border in decoration.borders)
        ...exteriorBorderReferences(border),
    });
  }
  return Map.unmodifiable(result);
}

Future<MapExteriorDecoration?> _readMapExteriorDecoration(
  ProjectFileReader files,
  String projectRoot,
  String mapId,
  String? mapRelativePath, {
  MapData? baseMap,
}) async {
  final definitionPath = 'maps/$mapId.decoration.json';
  if (mapRelativePath == definitionPath ||
      mapId.contains('/') ||
      mapId.contains(r'\') ||
      mapId == '..') {
    return null;
  }
  final definitionBytes = await _readExteriorDecorationResource(
      files,
      projectRoot,
      definitionPath,
      LocalMapExteriorDecorationAuthoring.maximumDefinitionBytes);
  if (definitionBytes == null) return null;
  _safeId(mapId);
  final index = _DecorationIndex.fromJson(_decode(definitionBytes),
      bytes: definitionBytes);
  if (index.definition!.mapId != mapId) {
    throw const FormatException('Exterior decoration map identity mismatch.');
  }
  if (baseMap != null) index.validateForMap(baseMap);
  final sectors = <ExteriorDecorationSector>[];
  for (final summary in index.sectors.values) {
    final path = _sectorPath(mapId, summary.id);
    final bytes = await _readExteriorDecorationResource(files, projectRoot,
        path, LocalMapExteriorDecorationAuthoring.maximumSectorBytes);
    if (bytes == null ||
        computeAuthoringBytesFingerprint(bytes, logicalName: path) !=
            summary.revision) {
      throw const FormatException(
          'Required exterior decoration sector is missing or changed.');
    }
    final sector = ExteriorDecorationSector.fromJson(_decode(bytes));
    if (jsonEncode(
            _SectorSummary.fromSector(sector, summary.revision).toJson()) !=
        jsonEncode(summary.toJson())) {
      throw const FormatException(
          'Exterior decoration sector summary mismatch.');
    }
    sectors.add(sector);
  }
  final borders = <ExteriorDecorationBorder>[];
  for (final summary in index.borders.values) {
    final path = _borderPath(mapId, summary.id);
    final bytes = await _readExteriorDecorationResource(files, projectRoot,
        path, LocalMapExteriorDecorationAuthoring.maximumBorderBytes);
    if (bytes == null ||
        computeAuthoringBytesFingerprint(bytes, logicalName: path) !=
            summary.revision) {
      throw const FormatException(
          'Required exterior Border is missing or changed.');
    }
    final border = ExteriorDecorationBorder.fromJson(_decode(bytes));
    if (jsonEncode(
            _SectorSummary.fromBorder(border, summary.revision).toJson()) !=
        jsonEncode(summary.toJson())) {
      throw const FormatException('Exterior Border summary mismatch.');
    }
    borders.add(border);
  }
  return _withVisuals(index.definition!, sectors, borders);
}

Future<List<int>?> _readExteriorDecorationResource(
    ProjectFileReader reader, String root, String path, int maxBytes) async {
  if (reader is! ProjectResourceProbeReader) {
    throw const FormatException(
        'Exterior decoration loading requires a metadata-only resource probe.');
  }
  final probe = await (reader as ProjectResourceProbeReader)
      .probeResource(projectRoot: root, relativePath: path);
  if (probe.status == ProjectResourceProbeStatus.missing) return null;
  if (probe.status != ProjectResourceProbeStatus.exists ||
      probe.identity!.byteLength > maxBytes) {
    throw const FormatException(
        'Exterior decoration resource is unsafe or oversized.');
  }
  final bytes = await reader.readBytes(projectRoot: root, relativePath: path);
  if (bytes.length > maxBytes) {
    throw const FormatException('Exterior decoration resource is oversized.');
  }
  return bytes;
}
