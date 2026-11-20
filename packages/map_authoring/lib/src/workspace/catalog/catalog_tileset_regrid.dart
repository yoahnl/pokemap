part of 'catalog_authoring_session.dart';

extension _CatalogTilesetRegrid on CatalogAuthoringSession {
  Future<AuthoringMutationPlanResult> _planTilesetRegrid(
      AuthoringRequest request) async {
    if (request.actionVersion != 1 || request.idempotencyKey == null) {
      throw const FormatException(
          'Tileset grid changes require version 1 and an idempotency key.');
    }
    final args = request.parameters;
    rejectUnknownContractKeys(
        args, const {'tilesetId', 'tileWidth', 'tileHeight'});
    final id = requireContractString(args['tilesetId'], 'tilesetId');
    final tileWidth = args['tileWidth'];
    final tileHeight = args['tileHeight'];
    if (tileWidth is! int ||
        tileHeight is! int ||
        tileWidth < 1 ||
        tileHeight < 1) {
      throw const FormatException('Tile sizes must be positive integers.');
    }
    final key = CatalogDefinitionKey(CatalogDefinitionKind.tileset, id);
    final current = (await CatalogProjectReader.open(
        store: reader.store,
        descriptor: reader.descriptor,
        metadataFields: {}))!;
    if (current.revision != request.expectedRevision) throw _libraryPlanStale();
    final edit = await current.read((catalog) async {
      await reader.store.requireMetadataIndexAdmission(catalog.snapshot);
      final unit = await catalog.lookup(key);
      if (unit == null) {
        throw MapAuthoringException(
            code: 'tileset.unknown', message: 'The tileset no longer exists.');
      }
      final tileset = catalog.definitionValue(unit) as ProjectTilesetEntry;
      final after = _regridUnusedTileset(tileset, tileWidth, tileHeight);
      await _requireUnusedLibraryDefinition(
          catalog.snapshot,
          key,
          'tileset',
          CatalogDefinitionKey(
              CatalogDefinitionKind.resourceLibraryEntry, 'tileset:$id'));
      final next = tileset.copyWith(source: after);
      return (
        before: tileset.source!,
        after: after,
        tileset: next,
        unit: catalog.replaceDefinitionValue(unit, next.toJson())
      );
    });
    final editing = await _editing();
    if (editing.snapshot.root != current.catalog.snapshot.root) {
      throw _libraryPlanStale();
    }
    final planned = await editing.planPatch(
        upserts: [edit.unit],
        idempotencyKey: request.idempotencyKey!,
        request: request,
        publicDiff: AuthoringDiff([
          AuthoringDiffEntry(
              operation: AuthoringDiffOperation.replace,
              resource:
                  AuthoringResourceRef(kind: 'catalogHead', id: 'catalog'),
              path: '/tilesets/$id/source',
              before: edit.before.toJson(),
              after: edit.after.toJson()),
        ]));
    final plan = planned.plan;
    _plans[plan.planId] = planned;
    final receipt = plan.toPlannedReceipt();
    return AuthoringMutationPlanResult(
        plan: plan,
        snapshotRevision: current.revision,
        receipt: receipt,
        projectedProject: ProjectManifest(
            name: current.catalog.projectMetadata.name,
            maps: const [],
            tilesets: [edit.tileset]),
        publicProjection: await projections?.preparePlan(
            plan: plan, receipt: receipt, snapshotRevision: current.revision));
  }
}

ProjectRegularAtlasTilesetSource _regridUnusedTileset(
    ProjectTilesetEntry tileset, int tileWidth, int tileHeight) {
  final source = tileset.source;
  if (source is ProjectRegularAtlasTilesetSource) {
    if (source.tileWidth == tileWidth && source.tileHeight == tileHeight) {
      throw MapAuthoringException(
          code: 'tileset.grid_unchanged', message: 'The grid is unchanged.');
    }
    if (tileset.isWorldTileset ||
        tileset.elementGroups.isNotEmpty ||
        tileset.paletteEntries.isNotEmpty ||
        source.tileProperties.isNotEmpty ||
        source.tileAnimations.isNotEmpty) {
      throw MapAuthoringException(
          code: 'tileset.regrid_local_uses',
          message: 'The atlas already has uses or settings tied to this grid.');
    }
  }
  try {
    return const TilesetActions().previewAtlasGrid(tileset,
        tileWidth: tileWidth, tileHeight: tileHeight);
  } on VisualLibraryException catch (error) {
    throw MapAuthoringException(
        code: error.code, message: error.message, details: error.details);
  }
}
