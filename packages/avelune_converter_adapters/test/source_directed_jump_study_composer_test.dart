import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'dart:io';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart'
    hide PixelSize;
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:test/test.dart';
import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

typedef JumpFixture = ({
  LiteralTileFixture fixture,
  LiteralTileComposition base,
  ProjectManifest project
});
Future<JumpFixture> jumpFixture(
    {int passage = 7,
    int runLength = 3,
    List<LiteralFixtureEvent> events = const [],
    bool includeEventSystem = false,
    bool useExternalScripts = true,
    bool lowerTransparentPixel = false,
    bool upperOpaquePixel = false,
    bool ledgeAtWestEdge = false,
    List<LiteralFixtureMap> connectedMaps = const [],
    List<List<Object>> connectionRows = const []}) async {
  final atlas = image.Image(width: 256, height: 64, numChannels: 4);
  for (var y = 0; y < 32; y++) {
    for (var x = 0; x < 32; x++) {
      atlas.setPixelRgba(x, y, 31, 41, 59, 255);
    }
  }
  for (var part = 0; part < 3; part++) {
    for (var y = 48; y < 64; y++) {
      for (var x = 32 * part; x < 32 * (part + 1); x++) {
        atlas.setPixelRgba(x, y, 73 + part * 20, x, y, 255);
      }
    }
  }
  if (lowerTransparentPixel) atlas.setPixelRgba(1, 56, 0, 0, 0, 0);
  if (upperOpaquePixel) atlas.setPixelRgba(1, 33, 7, 11, 13, 255);
  final width = runLength + 2;
  final cellCount = width * 5;
  final middle = List<int>.filled(cellCount, 0);
  for (var x = 1; x <= runLength; x++) {
    middle[width * 2 + x - (ledgeAtWestEdge ? 1 : 0)] = 392 + (x - 1) % 3;
  }
  final fixture = await LiteralTileFixture.create(interpretationProfile: fixtureSourceInterpretationProfile,

    includeEventSystem: includeEventSystem,
    scriptsBytes: !useExternalScripts || Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS'] == null
        ? syntheticInterpretationArchive
        : await File(Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS']!)
            .readAsBytes(),
    extraFiles: {
      if (connectionRows.isNotEmpty)
        'Data/map_connections.dat': literalFixtureMarshal(connectionRows),
      'PBS/metadata.txt': [
        91,
        49,
        93,
        10,
        87,
        97,
        108,
        107,
        67,
        104,
        97,
        114,
        115,
        101,
        116,
        32,
        61,
        32,
        79,
        114,
        105,
        103,
        105,
        110,
        97,
        108,
        80,
        108,
        97,
        121,
        101,
        114,
        10
      ],
      'Graphics/Characters/OriginalPlayer.png':
          image.encodePng(image.Image(width: 128, height: 192, numChannels: 4))
    },
    maps: [
      LiteralFixtureMap(
          id: 98,
          width: width,
          height: 5,
          layers: [
            List.filled(cellCount, 384),
            middle,
            List.filled(cellCount, 0)
          ],
          events: events),
      ...connectedMaps
    ],
    tilesets: [
      LiteralFixtureTileset(
          id: 1,
          png: image.encodePng(atlas),
          passages: {392: passage, 393: passage, 394: passage},
          terrainTags: {392: 1, 393: 1, 394: 1})
    ],
  );
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: fixture.snapshot,
      files: fixture.files,
      interpretationProfile: fixtureSourceInterpretationProfile,
      selectedMapIds: {98, ...connectedMaps.map((map) => map.id)},
      includeConnections: connectionRows.isNotEmpty,
      includeEventSystem: includeEventSystem);
  final base = await const LiteralTileComposer().compose(
      source: source,
      files: fixture.files,
      selectedSourceMapIds: [98, ...connectedMaps.map((map) => map.id)],
      projectName: 'Original ledge',
      parentPath: '/private/tmp',
      folderName: 'original-ledge');
  final imported = base.draft!.mutations
      .singleWhere((m) => m.actionId == 'tileset.import_image');
  final id = imported.parameters['tilesetId'] as String;
  final project = ProjectManifest(
      name: 'Original ledge',
      version: ProjectVersion.v8,
      maps: [
        for (final map in base.nativeMaps.values)
          ProjectMapEntry(
              id: map.id,
              name: map.name,
              relativePath: 'maps/${map.id}.json')
      ],
      tilesets: [
        ProjectTilesetEntry(
            id: id,
            name: 'Original atlas',
            relativePath: 'assets/studio/$id.png',
            source: ProjectRegularAtlasTilesetSource(
                assetId: 'image_$id',
                pixelWidth: 256,
                pixelHeight: 64,
                tileWidth: 32,
                tileHeight: 32))
      ],
      settings: const ProjectSettings(tileWidth: 32, tileHeight: 32));
  return (fixture: fixture, base: base, project: project);
}

Future<SourceDirectedJumpStudyComposition> composeJump(JumpFixture f,
        {Map<int, MapData>? maps,
        ProjectManifest? project,
        NativeWriteLimits limits = const NativeWriteLimits()}) =>
    const SourceDirectedJumpStudyComposer().compose(
        source: f.base.draft!.source,
        base: f.base,
        nativeMaps: maps ?? f.base.nativeMaps,
        project: project ?? f.project,
        files: f.fixture.files,
        limits: limits);
void main() {
  final scripts = Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS'];
  void qualified(String name, Future<void> Function() body) =>
      test(name, body, skip: scripts == null);
  test('connection arrivals preserve only intersecting ledges across offset neighbors', () async {
    LiteralFixtureMap neighbor(int id) => LiteralFixtureMap(
        id: id, width: 3, height: 2, layers: [
          List.filled(6, 384), List.filled(6, 0), List.filled(6, 0)
        ]);
    final f = await jumpFixture(ledgeAtWestEdge: true,
        connectedMaps: [neighbor(99), neighbor(100)], connectionRows: [
          [99, 'E', 0, 98, 'W', 0],
          [100, 'E', 0, 98, 'W', 2],
        ]);
    final result = await composeJump(f);
    expect(result.evidence['importedJumpCount'], 2);
    final gaps = (result.evidence['diagnostics'] as List).cast<Map>().where(
        (row) => row['code'] == 'jumps.connection_arrival_unqualified').toList();
    expect(gaps, hasLength(1));
    expect(gaps.single['via'], [0, 2]);
    expect(gaps.single['sourceMapId'], 98);
    expect(gaps.single['qualified'], isFalse);
    expect(gaps.single['locator'], containsPair('mapId', 98));
    final row = (result.evidence['rows'] as List).cast<Map>().singleWhere(
        (row) => row['via'].toString() == '[0, 2]' && row['direction'] == 'down');
    expect(row['nativeStatus'], 'preservedOnly');
    final map = result.nativeMaps[98]!;
    final original = f.base.nativeMaps[98]!;
    final layer = map.layers.whereType<TileLayer>().singleWhere(
        (layer) => layer.name == 'Source Z 1');
    final sourceLayer = original.layers.whereType<TileLayer>().singleWhere(
        (layer) => layer.name == 'Source Z 1');
    expect(layer.cells[map.size.width * 2], sourceLayer.cells[map.size.width * 2]);
    final connections = await const SourceConnectionStudyComposer().compose(
        source: f.base.draft!.source, files: f.fixture.files,
        nativeMaps: result.nativeMaps);
    expect(connections.mutations, hasLength(2));
    expect(() => const SourceEventArrivalValidator().validateConnections(
        manifest: result.project, maps: connections.nativeMaps.values.toList(),
        source: f.base.draft!.source, connectionMutations: connections.mutations),
        returnsNormally);
  });
  test('inactive connections do not suppress a separate source ledge', () async {
    final f = await jumpFixture(ledgeAtWestEdge: true, connectedMaps: [
      LiteralFixtureMap(id: 100, width: 3, height: 2, layers: [
        List.filled(6, 384), List.filled(6, 0), List.filled(6, 0)
      ], events: const [
        LiteralFixtureEvent(id: 7, x: 2, y: 1, pages: [])
      ])
    ], connectionRows: [[100, 'E', 0, 98, 'W', 2]]);
    final admission = await const SourceConnectionStudyComposer().compose(
        source: f.base.draft!.source, nativeMaps: f.base.nativeMaps,
        files: f.fixture.files);
    expect(admission.mutations, isEmpty);
    expect((admission.evidence['diagnostics'] as List).cast<Map>()
        .map((row) => row['code']), contains('connections.border_events_unqualified'));
    final result = await composeJump(f);
    expect(result.evidence['importedJumpCount'], 3);
    expect((result.evidence['diagnostics'] as List).cast<Map>()
        .where((row) => row['code'] == 'jumps.connection_arrival_unqualified'), isEmpty);
  });
  qualified(
      'local ledge indices retain exact ownership away from the global first tile',
      () async {
    final f = await jumpFixture();
    final layer = f.base.nativeMaps[98]!.layers
        .whereType<TileLayer>()
        .singleWhere((l) => l.name == 'Source Z 1');
    expect(layer.cells.sublist(11, 14), [1, 2, 3]);
    expect(layer.palette.map((p) => p.localTileId), [8, 9, 10]);
    final result = await composeJump(f);
    expect(result.evidence['importedJumpCount'], 3);
    expect(result.evidence['version'], 3);
  });
  qualified(
      'local ledge attestation rejects forged palette references and indices',
      () async {
    final f = await jumpFixture();
    final map = f.base.nativeMaps[98]!;
    final layer = map.layers
        .whereType<TileLayer>()
        .singleWhere((l) => l.name == 'Source Z 1');
    final palette = layer.palette.toList();
    final reference = palette[layer.cells[11] - 1];
    final wrongTile = palette.toList()
      ..[layer.cells[11] - 1] =
          TileLayerPaletteEntry(tilesetId: reference.tilesetId, localTileId: 0);
    final wrongTileset = palette.toList()
      ..[layer.cells[11] - 1] = TileLayerPaletteEntry(
          tilesetId: 'forged-atlas', localTileId: reference.localTileId);
    final reordered = palette.reversed.toList();
    final recoded =
        layer.cells.map((c) => c == 0 ? 0 : palette.length - c + 1).toList();
    for (final forged in [
      layer.copyWith(palette: wrongTile),
      layer.copyWith(palette: wrongTileset),
      layer.copyWith(palette: reordered, cells: recoded),
      for (final cell in [0, -1, palette.length + 1])
        layer.copyWith(cells: layer.cells.toList()..[11] = cell),
      layer.copyWith(cells: layer.cells.take(11).toList()),
    ]) {
      await expectLater(
          composeJump(f, maps: {
            98: map.copyWith(layers: [
              for (final original in map.layers)
                if (original.id == layer.id) forged else original
            ])
          }),
          throwsA(isA<NativeWriteException>().having((e) => e.code, 'code',
              anyOf('jumps.native_glyph', 'jumps.native_references'))));
    }
  });
  qualified(
      'long mixed source ledges use actions per glyph without per-cell replacement',
      () async {
    final f = await jumpFixture(runLength: 60);
    const limits = NativeWriteLimits(maxMutations: 20);
    final result = await composeJump(f, limits: limits);
    expect(result.evidence['importedJumpCount'], 60);
    expect(result.mutations.length, 16);
    expect(result.mapMutations.map((m) => m.actionId), [
      for (var i = 0; i < 3; i++) ...[
        'border_layer.feature_create',
        'border_layer.materialize_apply'
      ]
    ]);
    final map = result.nativeMaps[98]!;
    final features =
        map.layers.whereType<BorderLayer>().single.content.features;
    expect(features, hasLength(3));
    expect(features.every((feature) => feature.overrides.isEmpty), isTrue);
    final bindings = bindMaterializedBorderJumpFaces(
        map: map,
        project: result.project,
        tileSize: const PixelSize(width: 32, height: 32));
    expect(bindings.length, 60);
    for (var x = 1; x <= 60; x++) {
      final world = GameplayWorldState.initial(
          map: map,
          project: result.project,
          playerPos: GridPos(x: x, y: 1),
          tileWidth: 32,
          tileHeight: 32);
      final jumped = stepGameplayWorld(
              world, const MoveIntent(Direction.south, pixelsPerStep: 32))
          as Jumped;
      final feature = features.singleWhere(
          (feature) => feature.id == jumped.plan.binding.owner.featureId);
      final primitive = result.project.borderCatalog
          .recordById(feature.blueprintId)!
          .latestPublished!
          .definition
          .primitives
          .single;
      final element = result.project.elements
          .singleWhere((element) => element.id == primitive.sourceElementId);
      expect(element.frames.single.source,
          TilesetSourceRect(x: (x - 1) % 3, y: 1));
      final reverse = stepGameplayWorld(
          world.withPlayer(GameplayPlayerState.fromGridSpawn(
              cell: GridPos(x: x, y: 3),
              facing: Direction.north,
              tileWidthPx: 32,
              tileHeightPx: 32,
              mapWidthCells: map.size.width,
              mapHeightCells: map.size.height)),
          const MoveIntent(Direction.north, pixelsPerStep: 32));
      expect(reverse, isA<Blocked>());
    }
    await expectLater(
        composeJump(f, limits: const NativeWriteLimits(maxMutations: 15)),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'jumps.quota.mutations')));
  });
  qualified(
      'three original source variants become canonical Borders with exact owners and pixels',
      () async {
    final f = await jumpFixture();
    final result = await composeJump(f);
    expect(result.evidence['importedJumpCount'], 3);
    expect(result.project.borderCatalog.formatVersion, 7);
    expect(result.project.borderCatalog.records, hasLength(3));
    final revisions = result.project.borderCatalog.records
        .map((record) => record.latestPublished!)
        .toList();
    final revision = revisions.first;
    expect(revision.definition.template, BorderBlueprintTemplate.ledgeLine);
    expect(revision.definition.jumpBehavior!.side, BorderLineSide.primary);
    expect(revisions.every((r) => r.definition.primitives.length == 1), isTrue);
    expect(
        result.mutations.map((m) => m.actionId),
        containsAllInOrder([
          'border.blueprint.draft.upsert',
          'border.blueprint.publish',
          'border_layer.feature_create',
          'border_layer.materialize_apply'
        ]));
    expect(result.mutations.any((m) => m.actionId == 'gameplay_zone.create'),
        isFalse);
    final original = f.base.nativeMaps[98]!;
    final prepared = result.preparedMaps[98]!;
    final target = original.layers
        .whereType<TileLayer>()
        .singleWhere((l) => l.name == 'Source Z 1');
    final cells = target.cells.toList()
      ..[11] = 0
      ..[12] = 0
      ..[13] = 0;
    expect(
        prepared.layers
            .whereType<TileLayer>()
            .singleWhere((l) => l.id == target.id)
            .cells,
        cells);
    for (final layer in original.layers
        .whereType<TileLayer>()
        .where((l) => l.id != target.id)) {
      expect(prepared.layers.singleWhere((l) => l.id == layer.id), layer);
    }
    expect(prepared.placedElements, original.placedElements);
    expect(
        target.palette,
        prepared.layers
            .whereType<TileLayer>()
            .singleWhere((l) => l.id == target.id)
            .palette);
    final finalMap = result.nativeMaps[98]!;
    final bindings = bindMaterializedBorderJumpFaces(
        map: finalMap,
        project: result.project,
        tileSize: const PixelSize(width: 32, height: 32));
    expect(bindings.map((b) => b.carrierCell), [
      const GridPos(x: 1, y: 2),
      const GridPos(x: 2, y: 2),
      const GridPos(x: 3, y: 2)
    ]);
    for (var x = 1; x <= 3; x++) {
      final world = GameplayWorldState.initial(
          map: finalMap,
          project: result.project,
          playerPos: GridPos(x: x, y: 1),
          tileWidth: 32,
          tileHeight: 32);
      final step = stepGameplayWorld(
          world, const MoveIntent(Direction.south, pixelsPerStep: 32));
      expect(step, isA<Jumped>());
      expect((step as Jumped).plan.landingPos, GridPos(x: x, y: 3));
      final feature = finalMap.layers
          .whereType<BorderLayer>()
          .single
          .content
          .features
          .singleWhere(
              (feature) => feature.id == step.plan.binding.owner.featureId);
      final placement = feature.materialization!.placements
          .singleWhere((p) => p.id == step.plan.binding.owner.placementId);
      expect(placement.transform.quarterTurns, 0);
      expect(placement.transform.flipX, false);
      final primitive = revisions
          .expand((r) => r.definition.primitives)
          .singleWhere((p) => p.id == placement.primitiveId);
      final sourceElement = result.project.elements
          .singleWhere((e) => e.id == primitive.sourceElementId);
      expect(sourceElement.frames.single.source,
          TilesetSourceRect(x: x - 1, y: 1));
      expect(placement.topLeftWorldPx, BorderPixelPos(x: x * 32, y: 2 * 32));
    }
    ProjectValidator.validate(result.project, maps: result.nativeMaps.values);
    MapValidator.validate(finalMap, projectDialogueContext: result.project);
    expect(result.evidence['runtimeJourneyQualified'], isFalse);
  });
  qualified('transparent pixels inside the lower source module remain exact',
      () async {
    final f = await jumpFixture(lowerTransparentPixel: true);
    final result = await composeJump(f);
    expect(result.evidence['importedJumpCount'], 3);
    final glyph = (result.evidence['glyphs'] as List)
        .singleWhere((g) => (g['crop'] as Map)['sourceTileId'] == 392) as Map;
    final primitive = result.project.borderCatalog.records
        .expand((record) => record.latestPublished!.definition.primitives)
        .singleWhere((p) => p.id == glyph['primitiveId']);
    final mask = [
      for (var y = 0; y < 32; y++)
        for (var x = 0; x < 32; x++) y >= 16 && !(x == 1 && y == 24)
    ];
    expect(
        primitive.publishedMetrics.occupancyMaskRle, encodeBorderRleMask(mask));
    expect(primitive.publishedMetrics.opaqueBounds,
        BorderPixelRect(x: 0, y: 16, width: 32, height: 16));
    expect(primitive.anchorPx, const BorderPixelPos(x: 16, y: 31));
  });
  qualified('complete source frames retain upper pixels and exact jump faces',
      () async {
    final f = await jumpFixture(upperOpaquePixel: true);
    final result = await composeJump(f);
    expect(result.evidence['importedJumpCount'], 3);
    final glyph = (result.evidence['glyphs'] as List)
        .singleWhere((g) => (g['crop'] as Map)['sourceTileId'] == 392) as Map;
    final primitive = result.project.borderCatalog.records
        .expand((record) => record.latestPublished!.definition.primitives)
        .singleWhere((p) => p.id == glyph['primitiveId']);
    final mask = [
      for (var y = 0; y < 32; y++)
        for (var x = 0; x < 32; x++) y >= 16 || (x == 1 && y == 1)
    ];
    expect(
        primitive.publishedMetrics.occupancyMaskRle, encodeBorderRleMask(mask));
    expect(primitive.publishedMetrics.opaqueBounds,
        BorderPixelRect(x: 0, y: 1, width: 32, height: 31));
    expect(primitive.anchorPx, const BorderPixelPos(x: 16, y: 31));
    final map = result.nativeMaps[98]!;
    final feature = map.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .singleWhere((feature) => feature.blueprintId == glyph['blueprintId']);
    final placement = feature.materialization!.placements
        .singleWhere((p) => p.primitiveId == primitive.id);
    expect(placement.topLeftWorldPx, const BorderPixelPos(x: 32, y: 64));
    final element = result.project.elements
        .singleWhere((e) => e.id == primitive.sourceElementId);
    expect(element.frames.single.source, TilesetSourceRect(x: 0, y: 1));
    final world = GameplayWorldState.initial(
        map: map,
        project: result.project,
        playerPos: const GridPos(x: 1, y: 1),
        tileWidth: 32,
        tileHeight: 32);
    final step = stepGameplayWorld(
        world, const MoveIntent(Direction.south, pixelsPerStep: 32));
    expect(step, isA<Jumped>());
    expect((step as Jumped).plan.landingPos, const GridPos(x: 1, y: 3));
    final reverse = GameplayWorldState.initial(
        map: map,
        project: result.project,
        playerPos: const GridPos(x: 1, y: 3),
        tileWidth: 32,
        tileHeight: 32);
    expect(
        stepGameplayWorld(
            reverse, const MoveIntent(Direction.north, pixelsPerStep: 32)),
        isA<Blocked>());
  });
  qualified('complete source frames survive native writer and strict reopen',
      () async {
    final f = await jumpFixture(upperOpaquePixel: true);
    final temporary =
        await Directory.systemTemp.createTemp('source-full-ledge-');
    addTearDown(() => temporary.delete(recursive: true));
    final base = await const LiteralTileComposer().compose(
        source: f.base.draft!.source,
        files: f.fixture.files,
        selectedSourceMapIds: [98],
        projectName: 'Complete source ledge frame',
        parentPath: temporary.path,
        folderName: 'complete-ledge-frame');
    final draft = (await const SourceSemanticStudyComposer().compose(
        source: f.base.draft!.source, base: base, files: f.fixture.files))!;
    final approval = approveNativeFixtureDraft(draft);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, draft);
    expect(receipt.verified, isTrue);
    final handles = WorkspaceHandleStore();
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(receipt.projectPath);
    try {
      final native = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(native.loadDiagnostics, isEmpty);
      final map = native.mapById(draft.mapIds[98]!)!;
      final primitive = native.manifest.borderCatalog.records
          .expand((record) => record.latestPublished!.definition.primitives)
          .singleWhere((p) => p.publishedMetrics.opaqueBounds.y == 1);
      final snapshot = native.manifest.borderCatalog.visualSnapshots
          .singleWhere((s) => s.id == primitive.visualSnapshotId);
      final frame = snapshot.frames.single;
      final raster = image.decodePng(
          await File('${receipt.projectPath}/${frame.relativeAssetPath}')
              .readAsBytes())!;
      final pixel =
          raster.getPixel(frame.sourceRectPx.x + 1, frame.sourceRectPx.y + 1);
      expect([pixel.r, pixel.g, pixel.b, pixel.a], [7, 11, 13, 255]);
      final world = GameplayWorldState.initial(
          map: map,
          project: native.manifest,
          playerPos: const GridPos(x: 1, y: 1),
          tileWidth: 32,
          tileHeight: 32);
      final step = stepGameplayWorld(
          world, const MoveIntent(Direction.south, pixelsPerStep: 32));
      expect(step, isA<Jumped>());
      expect((step as Jumped).plan.landingPos, const GridPos(x: 1, y: 3));
      final derived = <NativeArtifact>[];
      for (final snapshot in native.manifest.borderCatalog.visualSnapshots) {
        for (final frame in snapshot.frames) {
          derived.add(
            NativeArtifact(
              bytes: await File('${receipt.projectPath}/${frame.relativeAssetPath}')
                  .readAsBytes(),
            ),
          );
        }
      }
      final retained = [...draft.artifacts, ...draft.sourceArtifacts];
      final finalUniqueCount = {
        for (final artifact in [...retained, ...derived]) artifact.handle,
      }.length;
      expect(
        finalUniqueCount,
        greaterThan(retained.map((a) => a.handle).toSet().length),
      );
      expect(retained.length + derived.length * 2, greaterThan(finalUniqueCount));
      NativeProjectDraft withFolder(String folder) => NativeProjectDraft(
            source: draft.source,
            projectName: draft.projectName,
            parentPath: draft.parentPath,
            folderName: folder,
            sourceRootPath: draft.sourceRootPath,
            mapIds: draft.mapIds,
            artifacts: draft.artifacts,
            sourceArtifacts: draft.sourceArtifacts,
            mutations: draft.mutations,
            compositionEvidence: draft.compositionEvidence,
            defaultMapWidth: draft.defaultMapWidth,
            defaultMapHeight: draft.defaultMapHeight,
          );
      final bounded = withFolder('border-quota-rejected');
      final boundedApproval = approveNativeFixtureDraft(bounded);
      final stages = <NativeWriteStage>[];
      await expectLater(
        NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage)).write(
          boundedApproval.plan,
          boundedApproval.context,
          bounded,
          limits: NativeWriteLimits(maxArtifacts: finalUniqueCount - 1),
        ),
        throwsA(
          isA<NativeWriteException>().having(
            (error) => error.code,
            'code',
            'native.border.quota',
          ),
        ),
      );
      expect(stages, isEmpty);
      expect(
        await Directory('${temporary.path}/border-quota-rejected').exists(),
        isFalse,
      );
      final exact = withFolder('border-quota-exact');
      final exactApproval = approveNativeFixtureDraft(exact);
      final exactReceipt = await NativeProjectWriter().write(
        exactApproval.plan,
        exactApproval.context,
        exact,
        limits: NativeWriteLimits(maxArtifacts: finalUniqueCount),
      );
      expect(exactReceipt.verified, isTrue);
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
  });
  qualified(
      'source blocked ledges do not create Border resources or clear pixels',
      () async {
    final f = await jumpFixture(passage: 15);
    final result = await composeJump(f);
    expect(result.mutations, isEmpty);
    expect(result.nativeMaps, f.base.nativeMaps);
  });
  qualified('missing landing reference is rejected before native admission',
      () async {
    final f = await jumpFixture();
    final map = f.base.nativeMaps[98]!;
    final altered = map.copyWith(placedElements: [
      MapPlacedElement(
          id: 'missing',
          layerId: map.layers.first.id,
          elementId: 'missing',
          pos: const GridPos(x: 2, y: 3))
    ]);
    await expectLater(
        composeJump(f, maps: {98: altered}),
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'jumps.native_references')));
  });
  qualified(
      'missing landing tileset reference is rejected before native admission',
      () async {
    final f = await jumpFixture();
    final map = f.base.nativeMaps[98]!;
    final project = f.project.copyWith(elementCategories: const [
      ProjectElementCategory(id: 'original', name: 'Original')
    ], elements: const [
      ProjectElementEntry(
          id: 'missing-atlas-element',
          name: 'Missing atlas',
          tilesetId: 'missing-atlas',
          categoryId: 'original',
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))])
    ]);
    final altered = map.copyWith(placedElements: [
      MapPlacedElement(
          id: 'missing-atlas',
          layerId: map.layers.first.id,
          elementId: 'missing-atlas-element',
          pos: const GridPos(x: 2, y: 3))
    ]);
    await expectLater(
        composeJump(f, maps: {98: altered}, project: project),
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'jumps.native_references')));
  });
  qualified(
      'native landing solid retains its own source variant and all other solids',
      () async {
    final f = await jumpFixture();
    final map = f.base.nativeMaps[98]!;
    final collision = List<bool>.filled(25, false)..[17] = true;
    final original = map.copyWith(layers: [
      ...map.layers,
      MapLayer.collision(
          id: 'third-party', name: 'Third party', collisions: collision)
    ]);
    final result = await composeJump(f, maps: {98: original});
    expect(result.evidence['importedJumpCount'], 2);
    expect(
        result.preparedMaps[98]!.layers
            .whereType<TileLayer>()
            .singleWhere((l) => l.name == 'Source Z 1')
            .cells[12],
        isNonZero);
    expect(
        result.nativeMaps[98]!.layers.lastWhere((l) => l.id == 'third-party'),
        original.layers.last);
  });
  qualified('changed source layer palette cannot be consumed as an owned glyph',
      () async {
    final f = await jumpFixture();
    final map = f.base.nativeMaps[98]!;
    final target = map.layers
        .whereType<TileLayer>()
        .singleWhere((l) => l.name == 'Source Z 1');
    final cells = target.cells.toList()..[12] = 1;
    await expectLater(
        composeJump(f, maps: {
          98: map.copyWith(layers: [
            for (final l in map.layers)
              if (l.id == target.id) target.copyWith(cells: cells) else l
          ])
        }),
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'jumps.native_glyph')));
  });
  qualified('low explicit action budget refuses without partial resources',
      () async {
    final f = await jumpFixture();
    await expectLater(
        composeJump(f, limits: const NativeWriteLimits(maxMutations: 2)),
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'jumps.quota.mutations')));
  });
}
