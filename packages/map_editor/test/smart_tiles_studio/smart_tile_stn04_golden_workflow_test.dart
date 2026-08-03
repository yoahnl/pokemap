import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_atlas_image_loader.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_authoring_controller.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_draft_persistence_coordinator.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_draft_persistence_state.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_grid_detector.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_guide.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_guide_placement.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_publication_service.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_source_asset_import_service.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
      'STN-04 golden flow survives Grid reopen then publishes to map and library',
      () async {
    final sandbox = await Directory.systemTemp.createTemp(
      'pokemap_stn04_golden_',
    );
    final projectRoot = await Directory(
      p.join(sandbox.path, 'project'),
    ).create();
    final externalPng = File(p.join(sandbox.path, 'external-grass.png'));
    await externalPng.writeAsBytes(_twentyPixelPng, flush: true);
    await _writeProject(projectRoot);

    final transports = <_EditorTransports>[];
    addTearDown(() async {
      for (final transport in transports.reversed) {
        await transport.close();
      }
      if (await sandbox.exists()) await sandbox.delete(recursive: true);
    });

    final first = _EditorTransports.open();
    transports.add(first);
    final imported = await SmartTileSourceAssetImportService(
      gateway: CanonicalSmartTileSourceAssetGateway(
        mutations: first.mutations,
        queries: first.queries,
      ),
      imageLoader: const FileSmartTileAtlasImageLoader(),
    ).importImage(
      projectRootPath: projectRoot.path,
      sourcePath: externalPng.path,
      displayName: 'Herbe externe.png',
    );
    final mapDraft = _gridDraft(
      id: 'golden-map',
      name: 'Prairie de la map',
      tileset: imported.tileset,
    );
    final firstDraftGateway = CanonicalSmartTileDraftPersistenceGateway(
      mutations: first.mutations,
      queries: first.queries,
    );
    final attached = await SmartTileDraftPersistenceCoordinator.attach(
      projectRootPath: projectRoot.path,
      localDraft: mapDraft,
      gateway: firstDraftGateway,
    );
    attached.updateDraft(mapDraft);
    final savedAtGrid = await attached.flush();
    expect(
      savedAtGrid.phase,
      SmartTileDraftPersistencePhase.saved,
      reason: '${savedAtGrid.errorCode}: ${savedAtGrid.errorMessage}',
    );
    await attached.close();
    await first.close();

    // This is a genuine transport restart: the resumed state must come from
    // project.json, not from an in-memory controller or query session.
    final reopenedTransport = _EditorTransports.open();
    transports.add(reopenedTransport);
    final reopenedGateway = CanonicalSmartTileDraftPersistenceGateway(
      mutations: reopenedTransport.mutations,
      queries: reopenedTransport.queries,
    );
    final reopened = await SmartTileDraftPersistenceCoordinator.reopen(
      projectRootPath: projectRoot.path,
      draftId: mapDraft.id,
      gateway: reopenedGateway,
    );
    expect(reopened.draft.lastStage, SmartTileAuthoringStage.grid);
    expect(reopened.draft.sourceTilesetIds, <String>[imported.tileset.id]);
    expect(reopened.draft.primaryAtlasId, 'golden-map-atlas');
    expect(reopened.draft.atlases.single.columns, 20);
    expect(reopened.draft.atlases.single.rows, 20);
    expect(reopened.draft.materials, isEmpty);
    expect(reopened.draft.rules, isEmpty);
    expect(
      await File(
        p.join(projectRoot.path, imported.tileset.relativePath),
      ).readAsBytes(),
      orderedEquals(_twentyPixelPng),
    );

    final resumedAuthoring =
        SmartTileAuthoringController.fromCanonicalDraft(reopened.draft)
          ..createMaterial(name: 'Herbe')
          ..addAtlasVariant(
            mask: 0,
            column: 0,
            row: 0,
            candidateId: 'base',
          );
    reopened.updateDraft(
      resumedAuthoring.compileAuthoringDraft(
        lastStage: SmartTileAuthoringStage.publish,
      ),
    );
    final publication = SmartTilePublicationService(
      gateway: CanonicalSmartTilePublicationGateway(
        mutations: reopenedTransport.mutations,
        queries: reopenedTransport.queries,
      ),
    );
    final mapPlan = await publication.plan(
      projectRootPath: projectRoot.path,
      draftId: mapDraft.id,
      presetId: mapDraft.targetPresetId,
      target: const SmartTilePublicationTarget.map(
        mapId: 'map',
        layerId: 'golden_ground',
        layerName: 'Prairie',
      ),
      flushDraft: reopened.flush,
    );
    expect(
      mapPlan.affectedResources.map((resource) => resource.kind),
      containsAll(<String>['project', 'map']),
    );
    final mapResult = await publication.apply(
      mapPlan,
      projectRootPath: projectRoot.path,
    );
    expect(mapResult.manifest.smartTileCatalog.drafts, isEmpty);
    expect(mapResult.map!.layers.single, isA<SmartTileLayer>());

    final libraryResult = await _publishLibraryAfterDraftReopen(
      draft: _simpleDraft(
        id: 'golden-library',
        name: 'Prairie de la bibliothèque',
        tileset: imported.tileset,
        lastStage: SmartTileAuthoringStage.forms,
      ),
      projectRootPath: projectRoot.path,
      gateway: reopenedGateway,
      publication: publication,
    );
    expect(
      libraryResult.plan.affectedResources.map((resource) => resource.kind),
      isNot(contains('map')),
    );

    final pathResult = await _publishLibraryAfterDraftReopen(
      draft: _erwPathDraft(imported.tileset),
      projectRootPath: projectRoot.path,
      gateway: reopenedGateway,
      publication: publication,
    );
    final pathPreset = pathResult.manifest.smartTileCatalog.presets
        .singleWhere((preset) => preset.id == 'golden-erw-path');
    expect(pathPreset.templateHint, SmartTileTemplateHint.corner12);
    expect(pathPreset.rules, hasLength(12));

    final forestResult = await _publishLibraryAfterDraftReopen(
      draft: _forestDraft(imported.tileset),
      projectRootPath: projectRoot.path,
      gateway: reopenedGateway,
      publication: publication,
    );
    final forestPreset = forestResult.manifest.smartTileCatalog.presets
        .singleWhere((preset) => preset.id == 'golden-forest');
    final forestParts = forestPreset.rules.single.candidates.single.parts;
    expect(
      forestParts.map((part) => part.channel),
      containsAll(<SmartTileRenderChannel>[
        SmartTileRenderChannel.understory,
        SmartTileRenderChannel.canopy,
      ]),
    );
    await reopened.close();
    await reopenedTransport.close();

    final finalTransport = _EditorTransports.open();
    transports.add(finalTransport);
    final disk = await finalTransport.queries.open(projectRoot.path);
    expect(disk.manifest.smartTileCatalog.drafts, isEmpty);
    expect(
      disk.manifest.smartTileCatalog.presets.map((preset) => preset.id),
      containsAll(<String>[
        'golden-map',
        'golden-library',
        'golden-erw-path',
        'golden-forest',
      ]),
    );
    final diskMap = disk.maps.singleWhere((candidate) => candidate.id == 'map');
    expect(diskMap.layers, hasLength(1));
    expect(diskMap.layers.single.id, 'golden_ground');
    expect(diskMap.layers.single, isA<SmartTileLayer>());
  });

  test('editor loading reports the v6 preflight instead of a codec crash',
      () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_stn04_old_project_',
    );
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final manifestPath = p.join(root.path, 'project.json');
    await File(manifestPath).writeAsString(
      jsonEncode(<String, Object?>{
        'name': 'Ancien projet',
        'version': 'v5',
        'maps': const <Object?>[],
        'tilesets': const <Object?>[],
      }),
      flush: true,
    );

    await expectLater(
      FileProjectRepository().loadProject(manifestPath),
      throwsA(
        isA<ProjectLoadException>()
            .having(
              (error) => error.message,
              'message',
              contains('smart_tile_v6_project_required'),
            )
            .having(
              (error) => error.message,
              'message',
              allOf(contains('expected=v6'), contains('actual=v5')),
            ),
      ),
    );
  });
}

ProjectSmartTileAuthoringDraft _simpleDraft({
  required String id,
  required String name,
  required ProjectTilesetEntry tileset,
  required SmartTileAuthoringStage lastStage,
}) {
  final controller = SmartTileAuthoringController.blank()
    ..configureIdentity(
      id: id,
      name: name,
      materialId: 'grass',
      materialName: 'Herbe',
    )
    ..selectUsage(SmartTileUsage.terrain)
    ..selectTemplate(SmartTileTemplateHint.simple)
    ..configureAtlas(
      atlasId: '$id-atlas',
      atlasName: 'Atlas $name',
      tilesetId: tileset.id,
      geometry: const SmartTileGridGeometry(
        imageWidth: 1,
        imageHeight: 1,
        cellWidth: 1,
        cellHeight: 1,
      ),
    )
    ..addAtlasVariant(
      mask: 0,
      column: 0,
      row: 0,
      candidateId: 'base',
    );
  return controller.compileAuthoringDraft(lastStage: lastStage);
}

ProjectSmartTileAuthoringDraft _gridDraft({
  required String id,
  required String name,
  required ProjectTilesetEntry tileset,
}) {
  final controller = SmartTileAuthoringController.blank()
    ..configureIdentity(id: id, name: name)
    ..selectUsage(SmartTileUsage.terrain)
    ..selectTemplate(SmartTileTemplateHint.simple)
    ..configureAtlas(
      atlasId: '$id-atlas',
      atlasName: 'Atlas $name',
      tilesetId: tileset.id,
      geometry: const SmartTileGridGeometry(
        imageWidth: 20,
        imageHeight: 20,
        cellWidth: 1,
        cellHeight: 1,
      ),
    );
  return controller.compileAuthoringDraft(
    lastStage: SmartTileAuthoringStage.grid,
  );
}

ProjectSmartTileAuthoringDraft _erwPathDraft(ProjectTilesetEntry tileset) {
  final controller = SmartTileAuthoringController.blank()
    ..configureIdentity(
      id: 'golden-erw-path',
      name: 'Chemin ERW',
      materialId: 'dirt',
      materialName: 'Terre',
    )
    ..selectUsage(SmartTileUsage.path)
    ..configureAtlas(
      atlasId: 'golden-erw-path-atlas',
      atlasName: 'Atlas ERW',
      tilesetId: tileset.id,
      geometry: const SmartTileGridGeometry(
        imageWidth: 20,
        imageHeight: 20,
        cellWidth: 1,
        cellHeight: 1,
      ),
    );
  final placement = placeSmartTileGuide(
    guide: erwCorner16Guide,
    geometry: controller.state.gridGeometry!,
    anchorColumn: 3,
    anchorRow: 4,
  );
  expect(placement.isValid, isTrue);
  controller.applyGuidePlacement(
    guide: erwCorner16Guide,
    placement: placement,
  );
  return controller.compileAuthoringDraft(
    lastStage: SmartTileAuthoringStage.forms,
    guideId: SmartTileGuideId.erwCorner16.name,
  );
}

ProjectSmartTileAuthoringDraft _forestDraft(ProjectTilesetEntry tileset) {
  final controller = SmartTileAuthoringController.blank()
    ..configureIdentity(
      id: 'golden-forest',
      name: 'Sous-bois organique',
      materialId: 'forest',
      materialName: 'Forêt',
    )
    ..selectUsage(SmartTileUsage.forestSurface)
    ..configureAtlas(
      atlasId: 'golden-forest-atlas',
      atlasName: 'Atlas forêt',
      tilesetId: tileset.id,
      geometry: const SmartTileGridGeometry(
        imageWidth: 20,
        imageHeight: 20,
        cellWidth: 1,
        cellHeight: 1,
      ),
    )
    ..addAtlasVariant(
      mask: 0xff,
      column: 0,
      row: 0,
      candidateId: 'forest-main',
      channel: SmartTileRenderChannel.understory,
    )
    ..addVisualPart(
      mask: 0xff,
      candidateId: 'forest-main',
      part: const SmartTileVisualPart(
        source: SmartTileVisualSource.frame(
          frame: SmartTileFrameRef(
            atlasId: 'golden-forest-atlas',
            column: 1,
            row: 0,
          ),
        ),
        channel: SmartTileRenderChannel.canopy,
        offsetY: -1,
        drawOrder: 10,
      ),
    );
  return controller.compileAuthoringDraft(
    lastStage: SmartTileAuthoringStage.forms,
  );
}

Future<SmartTilePublicationResult> _publishLibraryAfterDraftReopen({
  required ProjectSmartTileAuthoringDraft draft,
  required String projectRootPath,
  required SmartTileDraftPersistenceGateway gateway,
  required SmartTilePublicationService publication,
}) async {
  final attached = await SmartTileDraftPersistenceCoordinator.attach(
    projectRootPath: projectRootPath,
    localDraft: draft,
    gateway: gateway,
  );
  attached.updateDraft(draft);
  final saved = await attached.flush();
  expect(
    saved.phase,
    SmartTileDraftPersistencePhase.saved,
    reason: '${saved.errorCode}: ${saved.errorMessage}',
  );
  await attached.close();

  final reopened = await SmartTileDraftPersistenceCoordinator.reopen(
    projectRootPath: projectRootPath,
    draftId: draft.id,
    gateway: gateway,
  );
  expect(reopened.draft.lastStage, SmartTileAuthoringStage.forms);
  reopened.updateDraft(
    reopened.draft.copyWith(lastStage: SmartTileAuthoringStage.publish),
  );
  final snapshot = await gateway.load(
    projectRootPath: projectRootPath,
    draftId: draft.id,
  );
  final compilation = compileSmartTileAuthoringDraft(
    draft: reopened.draft,
    catalog: snapshot.manifest.smartTileCatalog,
    manifest: snapshot.manifest,
  );
  if (compilation case final SmartTileDraftCompilationFailure failure) {
    throw StateError(
      'Compilation failed for ${draft.id}: '
      '${failure.diagnostics.map((item) => item.code).join(', ')}',
    );
  }
  late final SmartTilePublicationPlan plan;
  try {
    plan = await publication.plan(
      projectRootPath: projectRootPath,
      draftId: draft.id,
      presetId: draft.targetPresetId,
      target: const SmartTilePublicationTarget.library(),
      flushDraft: reopened.flush,
    );
  } on Object catch (error) {
    throw StateError('Publication failed for ${draft.id}: $error');
  }
  final result = await publication.apply(
    plan,
    projectRootPath: projectRootPath,
  );
  await reopened.close();
  return result;
}

Future<void> _writeProject(Directory root) async {
  const manifest = ProjectManifest(
    name: 'STN-04 golden project',
    version: ProjectVersion.v6,
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map',
        name: 'Map',
        relativePath: 'maps/map.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
  );
  const map = MapData(
    id: 'map',
    name: 'Map',
    version: ProjectVersion.v6,
    size: GridSize(width: 2, height: 2),
    visualStack: MapVisualStackConfig.canonicalV1,
  );
  final mapFile = File(p.join(root.path, 'maps', 'map.json'));
  await mapFile.parent.create(recursive: true);
  await File(p.join(root.path, 'project.json')).writeAsString(
    jsonEncode(manifest.toJson()),
    flush: true,
  );
  await mapFile.writeAsString(jsonEncode(map.toJson()), flush: true);
}

final class _EditorTransports {
  _EditorTransports._({required this.queries, required this.mutations});

  factory _EditorTransports.open() {
    const reader = EditorProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    return _EditorTransports._(
      queries: queries,
      mutations: AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      ),
    );
  }

  final AuthoringQueryAdapter queries;
  final AuthoringMutationAdapter mutations;
  bool _closed = false;

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await mutations.closeAll();
    await queries.closeAll();
  }
}

final Uint8List _twentyPixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAALElEQVR4nGNgGAWD'
  'DjDikvgfEPAfr8YNG7DqZaKGq5DBqIEjwcBRMAoYSAcAopsEECjFJ6AAAAAASUVORK5CYII=',
);
