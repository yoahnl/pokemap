import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

void main() {
  void qualifiedTest(String name, Future<void> Function() body) =>
      test(name, body,
          skip: Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS'] == null);
  qualifiedTest(
      'original compiled connection creates one exact reciprocal native pair',
      () async {
    final fixture = await _fixture([
      [98, 'E', 3, 100, 'W', 1]
    ]);
    final result = await _compose(fixture);
    final mutation = result.mutations.single;
    expect(mutation.actionId, 'connection.create_bidirectional_apply');
    expect(mutation.domain, OperationDomain.maps);
    expect(mutation.parameters, {
      'mapId': fixture.maps[98]!.id,
      'direction': 'east',
      'targetMapId': fixture.maps[100]!.id,
      'offset': 2,
    });
    expect(mutation.targetEntityIds.map((id) => id.value),
        [fixture.maps[98]!.id, fixture.maps[100]!.id]);
    expect(
        mutation.sourceEntityIds,
        containsAll([
          fixture.source.mapIdentity(98),
          fixture.source.mapIdentity(100),
          fixture.source.connectionsFileId
        ]));
    expect(result.nativeMaps[98]!.connections.single.offset, 2);
    expect(result.nativeMaps[100]!.connections.single.offset, -2);
    expect(result.nativeMaps[100]!.connections.single.direction,
        MapConnectionDirection.west);
    expect(result.evidence['connectionsState'], 'extracted');
    expect((result.evidence['rows'] as List).single['rawDataRef'],
        fixture.source.connections.single.rawDataRef.id.value);
  });

  qualifiedTest(
      'multiplicity includes excluded neighbors and never overwrites an edge',
      () async {
    final fixture = await _fixture([
      [98, 'E', 0, 100, 'W', 0],
      [98, 'W', 0, 101, 'E', 0],
      [98, 'W', 2, 102, 'E', 0],
    ], allIds: [
      98,
      100,
      101,
      102
    ]);
    final result = await _compose(fixture);
    expect(result.mutations, hasLength(1));
    expect(result.nativeMaps[98]!.connections.single.direction,
        MapConnectionDirection.east);
    final rows = (result.evidence['rows'] as List).cast<Map>();
    expect(rows.map((row) => row['status']),
        ['imported', 'preservedOnly', 'preservedOnly']);
    final diagnostics = (result.evidence['diagnostics'] as List).cast<Map>();
    expect(
        diagnostics
            .where((row) => row['code'] == 'connections.edge_multiplicity'),
        hasLength(2));
    expect(diagnostics.every((row) => row['locator'] != null), isTrue);
    expect(result.evidence['wholeSourceConnectivityQualified'], isFalse);
  });

  test('unselected unique neighbor is preserved without a fabricated map',
      () async {
    final fixture = await _fixture([
      [98, 'E', 0, 101, 'W', 0]
    ], allIds: [
      98,
      100,
      101
    ]);
    final result = await _compose(fixture);
    expect(result.mutations, isEmpty);
    expect(result.nativeMaps.keys, [98, 100]);
    expect((result.evidence['diagnostics'] as List).single['code'],
        'connections.map_excluded');
  });

  test('a source pair without native overlap stays preserved', () async {
    final fixture = await _fixture([
      [98, 'E', 9, 100, 'W', 0]
    ]);
    final result = await _compose(fixture);
    expect(result.mutations, isEmpty);
    expect((result.evidence['diagnostics'] as List).single['code'],
        'connections.no_overlap');
  });

  qualifiedTest('existing native edge cannot be silently replaced', () async {
    final fixture = await _fixture([
      [98, 'E', 0, 100, 'W', 0]
    ]);
    final maps = {...fixture.maps};
    maps[98] = upsertMapConnectionOnMap(maps[98]!,
        connection: MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: maps[100]!.id,
            offset: 1));
    await expectLater(
        _compose(fixture, maps: maps),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'connections.native_occupied')));
  });

  test('compiled graph drift refuses composition before any native mutation',
      () async {
    final fixture = await _fixture([
      [98, 'E', 0, 100, 'W', 0]
    ]);
    fixture.fixture.files.overrides['Data/map_connections.dat'] = _marshal([
      [98, 'E', 1, 100, 'W', 0]
    ]);
    await expectLater(
        _compose(fixture),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'connections.source_changed')));
  });

  test('not requested differs from a witnessed empty compiled graph', () async {
    final absent = await _fixture(null);
    final result = await _compose(absent);
    expect(result.evidence['connectionsState'], 'notRequested');
    expect((result.evidence['diagnostics'] as List).single['code'],
        'connections.not_requested');
    final empty = await _fixture([]);
    final witnessed = await _compose(empty);
    expect(witnessed.evidence['connectionsState'], 'extracted');
    expect(witnessed.evidence['rows'], isEmpty);
    expect(witnessed.evidence['diagnostics'], isEmpty);
    expect(witnessed.evidence['sourceFileHash'],
        literalFixtureHash(_marshal([])).value);
  });

  qualifiedTest(
      'mutation reference budget is unchanged for native connection pairs',
      () async {
    final fixture = await _fixture([
      [98, 'E', 0, 100, 'W', 0],
      [98, 'N', 0, 100, 'S', 0],
    ]);
    await expectLater(
        _compose(fixture, limits: const NativeWriteLimits(maxMutations: 1)),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'native.quota.references')));
  });

  qualifiedTest(
      'stable connection identities do not depend on unrelated snapshot bytes',
      () async {
    final a = await _fixture([
      [98, 'E', 0, 100, 'W', 0]
    ]);
    final b = await _fixture([
      [98, 'E', 0, 100, 'W', 0]
    ], extras: {
      'unrelated.txt': utf8.encode('Original unrelated evidence')
    });
    final left = await _compose(a), right = await _compose(b);
    expect(a.source.canonicalHash, isNot(b.source.canonicalHash));
    expect(
        left.mutations.single.operationId, right.mutations.single.operationId);
    expect(left.mutations.single.parameters, right.mutations.single.parameters);
    expect(left.evidence['sourceSnapshotHash'],
        isNot(right.evidence['sourceSnapshotHash']));
  });

  qualifiedTest(
      'entry d0 is qualified independently of directional passage bits',
      () async {
    final fixture = await _fixture([
      [98, 'E', 0, 100, 'W', 0]
    ], tilesets: [
      LiteralFixtureTileset(id: 1, passages: {384: 4})
    ]);
    final result = await _compose(fixture);
    expect(result.mutations, hasLength(1));
    final arrivals =
        (result.evidence['rows'] as List).single['arrivals'] as List;
    expect(arrivals, hasLength(12));
    expect(arrivals.every((row) => row['status'] == 'allowed'), isTrue);
    expect(result.evidence['sourceDirection'], 0);
    expect(result.evidence['directionBit'], 0);
    expect(result.evidence['sourceEntryScope'],
        'destinationStaticTilesWithoutBorderEvents');
  });

  qualifiedTest(
      'unknown destination terrain preserves the whole source connection',
      () async {
    final fixture = await _fixture([
      [98, 'E', 0, 100, 'W', 0]
    ], tilesets: [
      LiteralFixtureTileset(id: 1, terrainTags: {384: 18})
    ]);
    final result = await _compose(fixture);
    expect(result.mutations, isEmpty);
    expect((result.evidence['diagnostics'] as List).single['code'],
        'connections.source_entry_unqualified');
    expect(result.nativeMaps.values.every((map) => map.connections.isEmpty),
        isTrue);
  });

  qualifiedTest(
      'source border event footprint preserves the whole pair before activation',
      () async {
    final fixture = await _fixture([
      [98, 'E', 0, 100, 'W', 0]
    ], events: {
      100: [
        const LiteralFixtureEvent(
            id: 7, name: 'Original size(2,2)', x: 0, y: 2, pages: [])
      ]
    });
    final result = await _compose(fixture);
    expect(result.mutations, isEmpty);
    expect((result.evidence['diagnostics'] as List).single['code'],
        'connections.border_events_unqualified');
    expect(result.evidence['sourceCrossingParityQualified'], isFalse);
  });

  qualifiedTest(
      'final native rectangle refusal prevents a source-allowed connection',
      () async {
    final fixture = await _fixture([
      [98, 'E', 0, 100, 'W', 0]
    ]);
    final result = await _compose(fixture);
    final maps = {...result.nativeMaps};
    final target = maps[100]!;
    maps[100] = target.copyWith(layers: [
      ...target.layers,
      CollisionLayer(
          id: 'original-refusal',
          name: 'Original refusal',
          collisions: List<bool>.filled(30, false)..[10] = true)
    ]);
    expect(
        () => const SourceEventArrivalValidator().validateConnections(
            manifest: _manifest(maps.values),
            maps: maps.values.toList(),
            source: fixture.source,
            connectionMutations: result.mutations),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'connections.arrival_mismatch')));
  });

  qualifiedTest(
      'final native allow cannot replace a source d0 all-bits refusal',
      () async {
    final fixture = await _fixture([
      [98, 'E', 0, 100, 'W', 0]
    ], tilesets: [
      LiteralFixtureTileset(id: 1, passages: {384: 15})
    ]);
    final result = await _compose(fixture);
    expect(result.mutations, hasLength(1));
    expect(
        () => const SourceEventArrivalValidator().validateConnections(
            manifest: _manifest(result.nativeMaps.values),
            maps: result.nativeMaps.values.toList(),
            source: fixture.source,
            connectionMutations: result.mutations),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'connections.arrival_mismatch')));
  });

  qualifiedTest(
      'native surf-only water cannot imitate an allowed source d0 walk entry',
      () async {
    final fixture = await _fixture([
      [98, 'E', 0, 100, 'W', 0]
    ], tilesets: [
      LiteralFixtureTileset(id: 1, terrainTags: {384: 7})
    ]);
    final result = await _compose(fixture);
    final maps = {...result.nativeMaps};
    maps[100] = maps[100]!.copyWith(gameplayZones: const [
      MapGameplayZone(
          id: 'source-water-trial',
          kind: GameplayZoneKind.movement,
          area: MapRect(
              pos: GridPos(x: 0, y: 2), size: GridSize(width: 1, height: 1)),
          movement: MovementZonePayload(requiredMode: MovementMode.surf))
    ]);
    expect(
        () => const SourceEventArrivalValidator().validateConnections(
            manifest: _manifest(maps.values),
            maps: maps.values.toList(),
            source: fixture.source,
            connectionMutations: result.mutations),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'connections.arrival_mismatch')));
  });

  final scriptsPath = Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS'];
  test(
      'qualified connection follows map saves, survives events and strict writer regeneration',
      () async {
    final scripts = await File(scriptsPath!).readAsBytes();
    final output =
        await Directory.systemTemp.createTemp('ac15-native-connection-');
    try {
      final fixture = await LiteralTileFixture.create(
          scriptsBytes: scripts,
          includeEventSystem: true,
          maps: [
            for (final id in [98, 100, 105])
              LiteralFixtureMap(id: id, width: 5, height: 6, layers: [
                List.filled(30, 384),
                List.filled(30, 0),
                List.filled(30, 0)
              ])
          ],
          extraFiles: {
            'Data/map_connections.dat': _marshal([
              [98, 'E', 0, 100, 'W', 0]
            ]),
            'PBS/metadata.txt':
                utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
            'Graphics/Characters/OriginalPlayer.png': image.encodePng(
                image.Image(width: 128, height: 192, numChannels: 4)),
          });
      final source = await const RmxpSourceNormalizer().normalize(
          snapshot: fixture.snapshot,
          files: fixture.files,
          selectedMapIds: {98, 100, 105},
          includeConnections: true,
          includeEventSystem: true);
      final literal = await const LiteralTileComposer().compose(
          source: source,
          files: fixture.files,
          selectedSourceMapIds: [98, 100, 105],
          projectName: 'Original joined maps',
          parentPath: output.path,
          folderName: 'original-joined-maps');
      final semantic = (await const SourceSemanticStudyComposer()
          .compose(source: source, base: literal, files: fixture.files))!;
      expect(
          semantic.mutations.where(
              (row) => row.actionId == 'connection.create_bidirectional_apply'),
          hasLength(1));
      final event = (await const SourceEventStudyComposer()
          .compose(source: source, base: semantic, files: fixture.files))!;
      final draft = event.draft;
      final connectionIndex = draft.mutations.indexWhere(
          (row) => row.actionId == 'connection.create_bidirectional_apply');
      expect(
          draft.mutations.lastIndexWhere((row) => row.actionId == 'map.save'),
          lessThan(connectionIndex));
      expect(
          event.projection.nativeMaps.values
              .where((map) => map.connections.length == 1),
          hasLength(2));
      expect(event.projection.nativeMaps[105]!.connections, isEmpty);
      final witness = ((draft.compositionEvidence['sourceSemantics']
              as Map)['witnesses'] as List)
          .singleWhere(
              (row) => row['relativePath'] == 'Data/map_connections.dat');
      expect(
          witness['rawSha256'],
          literalFixtureHash(_marshal([
            [98, 'E', 0, 100, 'W', 0]
          ])).value);
      final approval = approveNativeFixtureDraft(draft);
      final receipt = await NativeProjectWriter()
          .write(approval.plan, approval.context, draft);
      expect(receipt.verified, isTrue);
      const reader = LocalProjectFileReader();
      final handles = WorkspaceHandleStore();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
      final opener = ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles);
      final opened = await opener.openProject(receipt.projectPath);
      try {
        final native = await ProjectSnapshotLoader(handles: handles).load(
            opened.projectHandle,
            policy: ProjectSnapshotLoadPolicy.strict);
        expect(native.loadDiagnostics, isEmpty);
        expect(native.maps.where((map) => map.connections.length == 1),
            hasLength(2));
        expect(
            native.maps
                .singleWhere((map) => map.id == draft.mapIds[105])
                .connections,
            isEmpty);
        final maps = {for (final map in native.maps) map.id: map};
        for (final map
            in native.maps.where((map) => map.connections.isNotEmpty)) {
          final connection = map.connections.single;
          final reciprocal = maps[connection.targetMapId]!.connections.single;
          expect(reciprocal.targetMapId, map.id);
          expect(reciprocal.offset, -connection.offset);
        }
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
      final forged = NativeProjectDraft(
          source: source,
          projectName: draft.projectName,
          parentPath: draft.parentPath,
          folderName: draft.folderName,
          mapIds: draft.mapIds,
          artifacts: draft.artifacts,
          sourceArtifacts: draft.sourceArtifacts,
          compositionEvidence: draft.compositionEvidence,
          mutations: [
            for (final mutation in draft.mutations)
              if (mutation.actionId == 'connection.create_bidirectional_apply')
                NativeMutation(
                    operationId: mutation.operationId,
                    actionId: mutation.actionId,
                    sourceEntityIds: mutation.sourceEntityIds,
                    targetEntityIds: mutation.targetEntityIds,
                    parameters: {...mutation.parameters, 'offset': 1})
              else
                mutation
          ]);
      final forgedApproval = approveNativeFixtureDraft(forged);
      final stages = <NativeWriteStage>[];
      await expectLater(
          NativeProjectWriter(checkpoint: (stage, _, __) => stages.add(stage))
              .write(forgedApproval.plan, forgedApproval.context, forged),
          throwsA(isA<NativeWriteException>().having(
              (error) => error.code, 'code', 'native.semantics.regeneration')));
      expect(stages, isEmpty);
    } finally {
      await output.delete(recursive: true);
    }
  }, skip: scriptsPath == null || !Platform.isMacOS);
}

typedef _Fixture = ({
  LiteralTileFixture fixture,
  NormalizedSourceProject source,
  Map<int, MapData> maps
});

Future<_Fixture> _fixture(List<List<Object>>? rows,
    {List<int> allIds = const [98, 100],
    Map<String, List<int>> extras = const {},
    List<LiteralFixtureTileset>? tilesets,
    Map<int, List<LiteralFixtureEvent>> events = const {}}) async {
  final scriptPath = Platform.environment['AVELUNE_AC12_SOURCE_SCRIPTS'];
  final fixture = await LiteralTileFixture.create(
      scriptsBytes:
          scriptPath == null ? null : await File(scriptPath).readAsBytes(),
      tilesets: tilesets,
      maps: [
        for (final id in allIds)
          LiteralFixtureMap(
              id: id,
              width: 5,
              height: 6,
              layers: [
                List.filled(30, 384),
                List.filled(30, 0),
                List.filled(30, 0)
              ],
              events: events[id] ?? [])
      ],
      selectedMapIds: {
        98,
        100
      },
      extraFiles: {
        ...extras,
        if (rows != null) 'Data/map_connections.dat': _marshal(rows)
      });
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: fixture.snapshot,
      files: fixture.files,
      selectedMapIds: {98, 100},
      includeConnections: rows != null);
  final literal = await const LiteralTileComposer().compose(
      source: source,
      files: fixture.files,
      selectedSourceMapIds: [98, 100],
      projectName: 'Original connected study',
      parentPath: '/private/tmp',
      folderName: 'unused-connection-study');
  expect(literal.canWrite, isTrue);
  return (fixture: fixture, source: source, maps: literal.nativeMaps);
}

ProjectManifest _manifest(Iterable<MapData> maps) => ProjectManifest(
    name: 'Original connection validation',
    version: ProjectVersion.v8,
    maps: [
      for (final map in maps)
        ProjectMapEntry(
            id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
    ],
    tilesets: const [],
    settings: const ProjectSettings(tileWidth: 32, tileHeight: 32));

Future<SourceConnectionStudyComposition> _compose(_Fixture fixture,
        {Map<int, MapData>? maps,
        NativeWriteLimits limits = const NativeWriteLimits()}) =>
    const SourceConnectionStudyComposer().compose(
        source: fixture.source,
        files: fixture.fixture.files,
        nativeMaps: maps ?? fixture.maps,
        limits: limits);

List<int> _marshal(Object value) {
  List<int> integer(int number) {
    if (number == 0) return [0];
    if (number > 0 && number < 123) return [number + 5];
    if (number < 0 && number > -124) return [(number - 5) & 255];
    final bytes = (ByteData(4)..setInt32(0, number, Endian.little))
        .buffer
        .asUint8List()
        .toList();
    while (bytes.length > 1 && bytes.last == (number < 0 ? 255 : 0)) {
      bytes.removeLast();
    }
    return [number < 0 ? 256 - bytes.length : bytes.length, ...bytes];
  }

  List<int> encode(Object input) => switch (input) {
        int() => [0x69, ...integer(input)],
        String() => [
            0x22,
            ...integer(utf8.encode(input).length),
            ...utf8.encode(input)
          ],
        List() => [
            0x5b,
            ...integer(input.length),
            for (final item in input) ...encode(item as Object)
          ],
        _ => throw ArgumentError(
            'Unsupported original compiled connection fixture'),
      };
  return [4, 8, ...encode(value)];
}
