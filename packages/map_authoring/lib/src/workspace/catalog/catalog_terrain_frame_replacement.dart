part of 'catalog_workshop_selection.dart';

Future<({ProjectManifest project, ProjectSmartTilePreset preset})?>
    _readTerrainFrameProjection(
  PortableProjectCatalog catalog,
  CatalogDefinitionUnit unit,
  Map value,
) async {
  final before = catalog.definitionValue(unit) as ProjectSmartTilePreset;
  final preset =
      ProjectSmartTilePreset.fromJson(Map<String, Object?>.from(value));
  if (!_onlyReplacesTerrainFrameLocations(before, preset)) return null;
  if (before.rules.any((rule) => rule.candidates.any((candidate) =>
      candidate.parts.any((part) => part.source is! SmartTileFrameSource)))) {
    return null;
  }
  final atlases = <String, ProjectSmartTileAtlas>{};
  for (final (index, rule) in preset.rules.indexed) {
    if (before.rules[index] == rule) continue;
    final source =
        rule.candidates.single.parts.single.source as SmartTileFrameSource;
    final frame = source.frame;
    var atlas = atlases[frame.atlasId];
    if (atlas == null) {
      final definition = await catalog.lookup(CatalogDefinitionKey(
          CatalogDefinitionKind.smartTileAtlas, frame.atlasId));
      if (definition == null) {
        throw semanticFailure('smart_tiles.reference.atlas_missing',
            'Missing Smart Tile atlas "${frame.atlasId}".');
      }
      atlas = catalog.definitionValue(definition) as ProjectSmartTileAtlas;
      if (await catalog.snapshot.indexEntry(CatalogDefinitionKey(
              CatalogDefinitionKind.tileset, atlas.tilesetId)) ==
          null) {
        return null;
      }
      atlases[frame.atlasId] = atlas;
    }
    if (frame.column >= atlas.columns || frame.row >= atlas.rows) {
      throw semanticFailure('smart_tiles.atlas.frame_out_of_bounds',
          'Frame exceeds atlas "${atlas.id}" bounds.',
          details: {'presetId': preset.id, 'ruleId': rule.id});
    }
  }
  final atlasDiagnostics = validateProjectSmartTileCatalog(
      catalog: ProjectSmartTileCatalog(atlases: atlases.values.toList()),
      projectTilesetIds: atlases.values.map((atlas) => atlas.tilesetId));
  if (atlasDiagnostics.any((diagnostic) => diagnostic.isError)) return null;
  return (
    project: catalog.projectMetadata.copyWith(
        maps: const [],
        smartTileCatalog: ProjectSmartTileCatalog(presets: [before])),
    preset: preset
  );
}

bool _onlyReplacesTerrainFrames(Object? existing, Object? candidate) {
  if (existing is! Map || candidate is! Map) return false;
  final before =
      ProjectSmartTilePreset.fromJson(Map<String, Object?>.from(existing));
  final after =
      ProjectSmartTilePreset.fromJson(Map<String, Object?>.from(candidate));
  return _onlyReplacesTerrainFrameLocations(before, after);
}

bool _onlyReplacesTerrainFrameLocations(
  ProjectSmartTilePreset before,
  ProjectSmartTilePreset after,
) {
  if (before.status != SmartTilePresetStatus.published ||
      before.rules.length != after.rules.length ||
      before.copyWith(rules: after.rules) != after) {
    return false;
  }

  for (var index = 0; index < before.rules.length; index++) {
    final previous = before.rules[index];
    final replacement = after.rules[index];
    if (previous != replacement &&
        !_onlyReassignsFrame(previous, replacement)) {
      return false;
    }
  }
  return true;
}

bool _onlyReassignsFrame(SmartTileRule before, SmartTileRule after) {
  if (before.candidates.length != 1 || after.candidates.length != 1) {
    return false;
  }
  final previous = before.candidates.single;
  final replacement = after.candidates.single;
  if (previous.parts.length != 1 || replacement.parts.length != 1) return false;
  final part = previous.parts.single;
  final oldSource = part.source;
  final newSource = replacement.parts.single.source;
  if (oldSource is! SmartTileFrameSource ||
      newSource is! SmartTileFrameSource ||
      part.frameSampling != SmartTileFrameSampling.fullFrame) {
    return false;
  }
  final frame = oldSource.frame;
  final next = newSource.frame;
  return frame.columnSpan == 1 &&
      frame.rowSpan == 1 &&
      frame.copyWith(column: next.column, row: next.row) == next &&
      before.copyWith(candidates: [
            previous.copyWith(parts: [part.copyWith(source: newSource)]),
          ]) ==
          after;
}
