import 'dart:convert';
import 'dart:io';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_adapters/src/literal_tile_composer.dart';
import 'package:avelune_converter_adapters/src/source_player_character_import.dart';
import 'package:avelune_converter_adapters/src/source_semantic_study_composer.dart';
import 'package:avelune_converter_adapters/src/source_semantics_projection.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

void main() {
  test('Surf projection is opt-in and preserves stationary water admission',
      () {
    final cells = [_cell(0, terrain: 7, passage: 15, width: 1)];
    final walk = SourceCollisionProjection.resolve(
        cells: cells,
        resolver: _resolver(),
        mapSize: const GridSize(width: 1, height: 1));
    final surf = SourceCollisionProjection.resolve(
        cells: cells,
        resolver: _resolver(),
        mapSize: const GridSize(width: 1, height: 1),
        includeNativeSurfTraversal: true);
    expect(walk.fullyBlockedCells, [true]);
    expect(surf.fullyBlockedCells, [false]);
    expect(surf.allowedTransitions, [0]);
  });

  for (final tag in [8, 9]) {
    test('Surf collision fallback keeps excluded endpoint $tag closed', () {
      final cells = [_cell(0, terrain: 7, passage: 15), _cell(1, terrain: tag)];
      final collision = SourceCollisionProjection.resolve(
          cells: cells,
          resolver: _resolver(),
          mapSize: const GridSize(width: 2, height: 1),
          includeNativeSurfTraversal: true);
      expect(collision.allowedTransitions, [0, 0]);
      expect(collision.wallMasksByCell[1], SourceCardinalDirection.left.bit);
    });
  }

  test('default projector retains walk-only collision and existing zones',
      () async {
    final input = await _input();
    final projection = await _project(input.$1, input.$2, input.$3);
    final map = projection.nativeMaps[9]!;
    expect(map.gameplayZones, input.$2.nativeMaps[9]!.gameplayZones);
    expect(
        projection.mutations.where((m) => m.actionId == 'gameplay_zone.create'),
        isEmpty);
    expect(
        projection.semanticEvidence.containsKey('includeNativeSurfTraversal'),
        isFalse);
    final world = GameplayWorldState.initial(
        map: map, playerPos: const GridPos(x: 0, y: 1));
    expect(world.isBlocked(1, 1, movementMode: MovementMode.surf), isTrue);
  });

  test('opt-in projector emits exact Surf zones once after map saves',
      () async {
    final input = await _input();
    final projection = await _project(input.$1, input.$2, input.$3, surf: true);
    final map = projection.nativeMaps[9]!;
    final zones = map.gameplayZones;
    expect(zones, hasLength(3));
    expect(
        zones.every((z) =>
            z.kind == GameplayZoneKind.movement &&
            z.movement!.requiredMode == MovementMode.surf &&
            z.cellMask == null),
        isTrue);
    final saves =
        projection.mutations.where((m) => m.actionId == 'map.save').toList();
    final creates = projection.mutations
        .where((m) => m.actionId == 'gameplay_zone.create')
        .toList();
    expect(creates, hasLength(zones.length));
    expect(creates.map((m) => (m.parameters['zone'] as Map)['id']).toSet(),
        zones.map((z) => z.id).toSet());
    final saved = MapData.fromJson(
        Map<String, dynamic>.from(saves.single.parameters['map'] as Map));
    expect(saved.gameplayZones, isEmpty);
    expect(projection.mutations.indexOf(saves.single),
        lessThan(projection.mutations.indexOf(creates.first)));
    expect(creates.every((m) => m.parameters['mapId'] == map.id), isTrue);
    final replayed = saved.copyWith(gameplayZones: [
      for (final mutation in creates)
        MapGameplayZone.fromJson(
            Map<String, dynamic>.from(mutation.parameters['zone'] as Map))
    ]);
    expect(_hash(replayed), _hash(map));
    final row = (projection.semanticEvidence['maps'] as List).single as Map;
    expect(row['nativeMapHash'], _hash(map).value);
    expect(projection.semanticEvidence['includeNativeSurfTraversal'], isTrue);
    expect(
        (projection.semanticEvidence['encounterTerrainBinding']
            as Map)['sourceSelectionHash'],
        input.$1.canonicalHash.value);
    expect(() => canonicalHashOf(projection.semanticEvidence), returnsNormally);
  });

  test('native water traversal requires Surf and exact water zones', () async {
    final input = await _input();
    final projection = await _project(input.$1, input.$2, input.$3, surf: true);
    final map = projection.nativeMaps[9]!;
    final world = GameplayWorldState.initial(
        map: map, playerPos: const GridPos(x: 0, y: 1));
    final water = {
      const GridPos(x: 1, y: 0),
      const GridPos(x: 2, y: 0),
      const GridPos(x: 1, y: 1),
      const GridPos(x: 1, y: 2),
      const GridPos(x: 2, y: 2)
    };
    for (var y = 0; y < map.size.height; y++) {
      for (var x = 0; x < map.size.width; x++) {
        expect(world.isWaterCell(x, y), water.contains(GridPos(x: x, y: y)));
      }
    }
    expect(
        world.movementBlockReasonAt(
            x: 1, y: 1, movementMode: MovementMode.walk),
        GameplayMovementBlockReason.waterRequiresSurf);
    expect(
        world.movementBlockReasonAt(
            x: 1, y: 1, movementMode: MovementMode.surf),
        isNull);
    expect(world.isBlocked(2, 1, movementMode: MovementMode.surf), isTrue);
    final withoutZones = GameplayWorldState.initial(
        map: map.copyWith(gameplayZones: []),
        playerPos: const GridPos(x: 0, y: 1));
    expect(
        withoutZones.isBlocked(1, 1, movementMode: MovementMode.walk), isFalse);
  });

  final scriptsPath = Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS'];
  test(
      'composer saves omit Surf creates and replay reconstructs projection hash',
      () async {
    final scripts = await File(scriptsPath!).readAsBytes();
    expect(literalFixtureHash(scripts).value,
        fixtureSourceInterpretationProfile.scriptsArchiveHash.value);
    final input = await _input(scripts: scripts);
    final draft = (await const SourceSemanticStudyComposer(
            includeNativeSurfTraversal: true)
        .compose(source: input.$1, base: input.$2, files: input.$3))!;
    final saves =
        draft.mutations.where((m) => m.actionId == 'map.save').toList();
    final creates = draft.mutations
        .where((m) => m.actionId == 'gameplay_zone.create')
        .toList();
    expect(creates, hasLength(3));
    expect(draft.mutations.indexOf(saves.single),
        lessThan(draft.mutations.indexOf(creates.first)));
    final saved = MapData.fromJson(
        Map<String, dynamic>.from(saves.single.parameters['map'] as Map));
    expect(saved.gameplayZones, isEmpty);
    final replayed = saved.copyWith(gameplayZones: [
      for (final create in creates)
        MapGameplayZone.fromJson(
            Map<String, dynamic>.from(create.parameters['zone'] as Map))
    ]);
    final semantic = draft.compositionEvidence['sourceSemantics'] as Map;
    expect(semantic['includeNativeSurfTraversal'], isTrue);
    final projection = semantic['projection'] as Map;
    expect((projection['maps'] as List).single['nativeMapHash'],
        _hash(replayed).value);
    final evidenceIds = (semantic['operationIds'] as List).toSet();
    expect(creates.every((m) => evidenceIds.contains(m.operationId.value)),
        isTrue);
    expect(draft.mutations.map((m) => m.operationId).toSet().length,
        draft.mutations.length);
  },
      skip: scriptsPath == null
          ? 'Requires attested original Scripts.rxdata'
          : false);
}

Sha256Hash _hash(MapData map) =>
    canonicalHashOf(jsonDecode(jsonEncode(map.toJson())));

Future<SourceSemanticsProjection> _project(NormalizedSourceProject source,
        LiteralTileComposition base, SourceFilePort files,
        {bool surf = false}) =>
    SourceSemanticsProjector(includeNativeSurfTraversal: surf).project(
        source: source, base: base, player: _player(source), files: files);

Future<(NormalizedSourceProject, LiteralTileComposition, SourceFilePort)>
    _input({List<int>? scripts}) async {
  final fixture = await LiteralTileFixture.create(interpretationProfile: fixtureSourceInterpretationProfile,
scriptsBytes: scripts, maps: [
    LiteralFixtureMap(id: 9, width: 4, height: 3, layers: [
      [384, 386, 386, 384, 384, 386, 386, 384, 384, 386, 386, 384],
      List.filled(12, 0),
      [0, 0, 0, 0, 0, 0, 387, 0, 0, 0, 0, 0]
    ])
  ], tilesets: [
    LiteralFixtureTileset(
        id: 1, passages: {386: 15, 387: 15}, terrainTags: {386: 7, 387: 4})
  ], extraFiles: {
    'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
    'Graphics/Characters/OriginalPlayer.png':
        image.encodePng(image.Image(width: 128, height: 192, numChannels: 4))
  });
  final snapshot = scripts == null
      ? SourceSnapshot(
          logicalProjectNamespace: fixture.snapshot.logicalProjectNamespace,
          policyHash: fixture.snapshot.policyHash,
          entries: [
            ...fixture.snapshot.entries,
            SourceFileEntry(
                fileId: ConverterId('fixture:attested-scripts'),
                relativePath: 'Data/Scripts.rxdata',
                kind: SourceNodeKind.file,
                byteLength: 1,
                sha256:
                    Sha256Hash(fixtureSourceInterpretationProfile.scriptsArchiveHash.value),
                format: 'ruby-marshal',
                family: 'data')
          ],
          diagnostics: [],
          excludedPaths: [],
          profileEvidence: fixture.snapshot.profileEvidence,
          state: SourceScanState.complete)
      : fixture.snapshot;
  final files = LiteralFixtureFiles(snapshot, fixture.sourceBytes);
  final source = scripts == null
      ? await const RmxpSourceNormalizer()
          .normalize(snapshot: snapshot, files: files, selectedMapIds: {9})
      : fixture.source;
  final base = await const LiteralTileComposer().compose(
      source: source,
      files: files,
      selectedSourceMapIds: [9],
      projectName: 'Native Surf projection',
      parentPath: '/private/tmp',
      folderName: 'unused-native-surf-projection');
  expect(base.draft, isNotNull);
  return (source, base, files);
}

SourcePlayerCharacterImport _player(NormalizedSourceProject source) {
  final entries = source.snapshot.entries;
  return SourcePlayerCharacterImport(
      sourceSnapshotHash: source.snapshot.canonicalHash,
      metadataFile:
          entries.firstWhere((e) => e.relativePath == 'PBS/metadata.txt'),
      imageFile: entries.firstWhere(
          (e) => e.relativePath == 'Graphics/Characters/OriginalPlayer.png'),
      imageBytes: literalFixtureAtlas(),
      outputBytes: literalFixtureAtlas(),
      selectedHeaderId: 1,
      charsetName: 'Synthetic preview',
      sheetWidth: 128,
      sheetHeight: 192,
      frameWidthPx: 32,
      frameHeightPx: 48,
      assetId: 'preview-player',
      tilesetId: 'preview-player',
      character: const ProjectCharacterEntry(
          id: 'preview-player', name: 'Preview', tilesetId: 'preview-player'));
}

SourceSemanticResolver _resolver() => SourceSemanticResolver(
    profile: SourceSemanticProfile(
        scriptsArchiveHash:
            Sha256Hash(fixtureSourceInterpretationProfile.scriptsArchiveHash.value),
        sourceSnapshotHash: Sha256Hash('a' * 64),
        sourceSelectionHash: Sha256Hash('b' * 64),
interpretationProfile: fixtureSourceInterpretationProfile,
));

SourceSemanticCell _cell(int x,
        {required int terrain, int passage = 0, int width = 2}) =>
    SourceSemanticCell(
        sourceMapId: 9,
        x: x,
        y: 0,
        width: width,
        height: 1,
        stack: [
          const SourceSemanticTile(sourceZ: 2, tileId: 0),
          const SourceSemanticTile(sourceZ: 1, tileId: 0),
          SourceSemanticTile(
              sourceZ: 0,
              tileId: 384,
              terrainTag: terrain,
              passage: passage,
              priority: 0)
        ]);
