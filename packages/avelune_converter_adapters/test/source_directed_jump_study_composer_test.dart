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
    List<LiteralFixtureEvent> events = const [],
    bool includeEventSystem = false,
    bool lowerTransparentPixel = false,
    bool upperOpaquePixel = false}) async {
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
  final middle = List<int>.filled(25, 0);
  for (var x = 1; x <= 3; x++) {
    middle[10 + x] = 391 + x;
  }
  final fixture = await LiteralTileFixture.create(
    includeEventSystem: includeEventSystem,
    scriptsBytes:
        await File(Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS']!)
            .readAsBytes(),
    extraFiles: {
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
          width: 5,
          height: 5,
          layers: [List.filled(25, 384), middle, List.filled(25, 0)],
          events: events)
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
      selectedMapIds: {98},
      includeEventSystem: includeEventSystem);
  final base = await const LiteralTileComposer().compose(
      source: source,
      files: fixture.files,
      selectedSourceMapIds: [98],
      projectName: 'Original ledge',
      parentPath: '/private/tmp',
      folderName: 'original-ledge');
  final native = base.nativeMaps[98]!;
  final imported = base.draft!.mutations
      .singleWhere((m) => m.actionId == 'tileset.import_image');
  final id = imported.parameters['tilesetId'] as String;
  final project = ProjectManifest(
      name: 'Original ledge',
      version: ProjectVersion.v8,
      maps: [
        ProjectMapEntry(
            id: native.id,
            name: native.name,
            relativePath: 'maps/${native.id}.json')
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
  qualified(
      'three original source variants become canonical Borders with exact owners and pixels',
      () async {
    final f = await jumpFixture();
    final result = await composeJump(f);
    expect(result.evidence['importedJumpCount'], 3);
    expect(result.project.borderCatalog.formatVersion, 7);
    final revision =
        result.project.borderCatalog.records.single.latestPublished!;
    expect(revision.definition.template, BorderBlueprintTemplate.ledgeLine);
    expect(revision.definition.jumpBehavior!.side, BorderLineSide.primary);
    expect(revision.definition.primitives, hasLength(3));
    expect(
        result.mutations.map((m) => m.actionId),
        containsAllInOrder([
          'border.blueprint.draft.upsert',
          'border.blueprint.publish',
          'border_layer.feature_create',
          'border_layer.feature_set_replacement',
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
          .single;
      final placement = feature.materialization!.placements
          .singleWhere((p) => p.id == step.plan.binding.owner.placementId);
      expect(placement.transform.quarterTurns, 0);
      expect(placement.transform.flipX, false);
      final primitive = revision.definition.primitives
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
    final primitive = result.project.borderCatalog.records.single
        .latestPublished!.definition.primitives
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
    final primitive = result.project.borderCatalog.records.single
        .latestPublished!.definition.primitives
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
    final feature =
        map.layers.whereType<BorderLayer>().single.content.features.single;
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
      final primitive = native.manifest.borderCatalog.records.single
          .latestPublished!.definition.primitives
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
