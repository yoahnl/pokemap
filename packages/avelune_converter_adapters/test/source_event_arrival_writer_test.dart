import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

void main() {
  test('connection validation retains presented arrival blockers', () async {
    final fixture = await LiteralTileFixture.create(
        interpretationProfile: syntheticSourceInterpretationProfile,
        scriptsBytes: syntheticInterpretationArchive,
        extraFiles: {
          'Data/map_connections.dat': literalFixtureMarshal([
            [1, 'E', 0, 2, 'W', 0],
          ]),
        },
        maps: [
          for (final id in [1, 2])
            LiteralFixtureMap(id: id, width: 5, height: 6, layers: [
              List.filled(30, 384),
              List.filled(30, 0),
              List.filled(30, 0),
            ]),
        ]);
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: fixture.snapshot,
        files: fixture.files,
        interpretationProfile: syntheticSourceInterpretationProfile,
        includeConnections: true);
    final literal = await const LiteralTileComposer().compose(
        source: source,
        files: fixture.files,
        selectedSourceMapIds: [1, 2],
        projectName: 'Connection arrival',
        parentPath: '/private/tmp',
        folderName: 'unused-connection-arrival');
    final connections = await const SourceConnectionStudyComposer().compose(
        source: source, nativeMaps: literal.nativeMaps, files: fixture.files);
    expect(connections.mutations, hasLength(1));
    final maps = [
      connections.nativeMaps[1]!,
      connections.nativeMaps[2]!.copyWith(entities: [
        MapEntity(
            id: 'blocking',
            kind: MapEntityKind.custom,
            pos: const GridPos(x: 0, y: 2),
            blocksMovement: false,
            presentation: MapEntityPresentation(variants: [
              MapEntityPresentationVariant(
                  id: 'solid',
                  condition: NarrativeEventConditionExpression.all(const []),
                  blocksMovement: true),
            ])),
      ]),
    ];
    final manifest = ProjectManifest(
        name: 'Connection arrival',
        tilesets: [
          for (final id in literal.tilesetIds.values)
            ProjectTilesetEntry(
                id: id, name: id, relativePath: 'assets/$id.png'),
        ],
        maps: [
          for (final map in maps)
            ProjectMapEntry(
                id: map.id,
                name: map.name,
                relativePath: 'maps/${map.id}.json'),
        ],
        settings: const ProjectSettings(tileWidth: 32, tileHeight: 32));
    expect(
        () => const SourceEventArrivalValidator().validateConnections(
            manifest: manifest,
            maps: maps,
            source: source,
            connectionMutations: connections.mutations),
        throwsA(isA<NativeWriteException>().having(
            (error) => error.code, 'code', 'connections.arrival_mismatch')));
  });

  test('converted arrival actor survives native write and strict reopen',
      () async {
    final temporary = await Directory.systemTemp.createTemp('arrival-owner-');
    addTearDown(() => temporary.delete(recursive: true));
    final charset =
        image.encodePng(image.Image(width: 128, height: 192, numChannels: 4));
    final turn = LiteralFixtureObject(
        'RPG::MoveCommand', {'@code': 16, '@parameters': <Object?>[]});
    final fixture = await LiteralTileFixture.create(
        sourceRootPath: '${temporary.path}/source',
        interpretationProfile: syntheticSourceInterpretationProfile,
        scriptsBytes: syntheticInterpretationArchive,
        includeEventSystem: true,
        extraFiles: {
          'Data/map_connections.dat': literalFixtureMarshal([]),
          'Data/map_metadata.dat': literalFixtureMarshal({}),
          'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = Player\n'),
          'Graphics/Characters/Player.png': charset,
          'Graphics/Characters/Door.png': charset,
        },
        maps: [
          LiteralFixtureMap(id: 1, width: 4, height: 4, layers: [
            List.filled(16, 384),
            List.filled(16, 0),
            List.filled(16, 0),
          ], events: [
            const LiteralFixtureEvent(id: 1, x: 0, y: 2, pages: [
              LiteralFixtureEventPage(characterName: 'Door', commands: [
                LiteralFixtureEventCommand(201, [0, 1, 2, 2, 0, 1]),
              ]),
            ]),
            LiteralFixtureEvent(id: 2, x: 2, y: 2, pages: [
              LiteralFixtureEventPage(characterName: 'Door', commands: [
                LiteralFixtureEventCommand(209, [
                  0,
                  LiteralFixtureObject('RPG::MoveRoute', {
                    '@repeat': false,
                    '@skippable': true,
                    '@list': [
                      turn,
                      LiteralFixtureObject('RPG::MoveCommand',
                          {'@code': 0, '@parameters': <Object?>[]}),
                    ],
                  }),
                ]),
                LiteralFixtureEventCommand(509, [turn]),
                const LiteralFixtureEventCommand(210, []),
              ]),
            ]),
          ]),
        ]);
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: fixture.snapshot,
        files: fixture.files,
        interpretationProfile: syntheticSourceInterpretationProfile,
        includeEventSystem: true,
        includeConnections: true);
    final literal = await const LiteralTileComposer().compose(
        source: source,
        files: fixture.files,
        selectedSourceMapIds: [1],
        projectName: 'Arrival owner',
        parentPath: temporary.path,
        folderName: 'native');
    expect(literal.draft, isNotNull,
        reason: jsonEncode(
            literal.diagnostics.map((row) => row.toJson()).toList()));
    final semantic = (await const SourceSemanticStudyComposer()
        .compose(source: source, base: literal, files: fixture.files))!;
    final composition = (await const SourceEventStudyComposer()
        .compose(source: source, base: semantic, files: fixture.files))!;
    final evidence = composition.projection.semanticEvidence;
    expect(
        (evidence['events'] as List)
            .cast<Map>()
            .every((row) => row['status'] == 'adaptedStaticSemantics'),
        isTrue,
        reason: jsonEncode(evidence['events']));
    final arrival = (evidence['arrivalAnchors'] as List).cast<Map>().single;
    final ownerId = arrival['arrivalCollisionOwnerEntityId'] as String;
    final expected = composition.projection.nativeMaps[1]!;
    expect(
        expected.entities
            .singleWhere((entity) => entity.id == ownerId)
            .presentation,
        isNotNull);
    final approval = approveNativeFixtureDraft(composition.draft);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, composition.draft);
    expect(receipt.verified, isTrue);
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(receipt.projectPath);
    try {
      final snapshot = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(snapshot.loadDiagnostics, isEmpty);
      final map = snapshot.mapById(expected.id)!;
      final owner = map.entities.singleWhere((entity) => entity.id == ownerId);
      expect(owner.presentation, isNotNull);
      expect(isSceneActorEntityReferenceAvailable(snapshot.manifest, owner),
          isTrue);
      expect(map.warps.singleWhere((warp) => warp.id == arrival['warpId']).pos,
          owner.pos);
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
  });
}
