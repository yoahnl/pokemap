import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

LiteralFixtureUserDefined _tone(double value) {
  final bytes = ByteData(32);
  for (var axis = 0; axis < 3; axis++) {
    bytes.setFloat64(axis * 8, value, Endian.little);
  }
  return LiteralFixtureUserDefined('Tone', bytes.buffer.asUint8List());
}

LiteralFixtureEvent _door(int id, int destination) {
  const step = LiteralFixtureObject('RPG::MoveCommand', {
    '@code': 1,
    '@parameters': <Object?>[],
  });
  const end = LiteralFixtureObject('RPG::MoveCommand', {
    '@code': 0,
    '@parameters': <Object?>[],
  });
  return LiteralFixtureEvent(id: id, x: 2, y: 2, pages: [
    LiteralFixtureEventPage(trigger: 1, commands: [
      LiteralFixtureEventCommand(223, [_tone(-255), 4]),
      const LiteralFixtureEventCommand(106, [4]),
      LiteralFixtureEventCommand(201, [0, destination, 2, 2, 2, 1]),
      LiteralFixtureEventCommand(223, [_tone(0), 4]),
      const LiteralFixtureEventCommand(0, []),
    ]),
    const LiteralFixtureEventPage(trigger: 3, globalSwitch: 1, commands: [
      LiteralFixtureEventCommand(111, [12, 'get_self.onEvent?']),
      LiteralFixtureEventCommand(
          209,
          [
            -1,
            LiteralFixtureObject('RPG::MoveRoute', {
              '@repeat': false,
              '@skippable': true,
              '@list': [step, end],
            }),
          ],
          indent: 1),
      LiteralFixtureEventCommand(509, [step], indent: 1),
      LiteralFixtureEventCommand(210, [], indent: 1),
      LiteralFixtureEventCommand(412, []),
      LiteralFixtureEventCommand(355, ['setTempSwitchOn("A")']),
      LiteralFixtureEventCommand(0, []),
    ]),
  ]);
}

void main() {
  test(
      'STD-EV-06 converts arbitrary paired doors into a reopenable Player fixture',
      () async {
    final requested = Platform.environment['AVELUNE_STD06_DOOR_FIXTURE_ROOT'];
    final output = requested == null
        ? await Directory.systemTemp.createTemp('std06-converted-doors-')
        : await Directory(requested).create(recursive: true);
    if (requested == null) {
      addTearDown(() => output.delete(recursive: true));
    }
    final fixture = await LiteralTileFixture.create(
      namespace: 'std06-arbitrary-door-pair',
      scriptsBytes: syntheticInterpretationArchive,
      interpretationProfile: syntheticSourceInterpretationProfile,
      includeEventSystem: true,
      switchNames: [null, 's:tsOff?("A")'],
      extraFiles: {
        'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = Player\n'),
        'Graphics/Characters/Player.png': literalFixtureAtlas(),
        'Data/map_metadata.dat': literalFixtureMarshal({}),
        'Data/map_connections.dat': literalFixtureMarshal([]),
      },
      maps: [
        for (final location in [(41, 83, 3), (83, 41, 11)])
          LiteralFixtureMap(
            id: location.$1,
            name: location.$1 == 41 ? 'STD06 exterior' : 'STD06 interior',
            width: 5,
            height: 5,
            layers: [
              List.filled(25, 384),
              List.filled(25, 0),
              List.filled(25, 0),
            ],
            events: [_door(location.$3, location.$2)],
          ),
      ],
    );
    const limits = NativeWriteLimits(maxArtifacts: 96);
    final source = await const RmxpSourceNormalizer().normalize(
      snapshot: fixture.snapshot,
      files: fixture.files,
      selectedMapIds: {41, 83},
      interpretationProfile: syntheticSourceInterpretationProfile,
      includeEventSystem: true,
      includeConnections: true,
    );
    final analysis = SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze();
    final programs =
        sourceRoutedDoorPrograms(source: source, analysis: analysis);
    expect(programs, hasLength(2));
    final literal = await const LiteralTileComposer().compose(
      source: source,
      files: fixture.files,
      selectedSourceMapIds: [41, 83],
      projectName: 'STD06 converted door Player fixture',
      parentPath: output.path,
      folderName: 'converted-doors',
      limits: limits,
    );
    expect(literal.draft, isNotNull,
        reason: literal.diagnostics.map((value) => value.toJson()).toString());
    final semantic = await const SourceSemanticStudyComposer().compose(
        source: source, base: literal, files: fixture.files, limits: limits);
    expect(semantic, isNotNull);
    final events = await const SourceEventStudyComposer().compose(
        source: source, base: semantic!, files: fixture.files, limits: limits);
    expect(events, isNotNull);
    final rows =
        (events!.projection.semanticEvidence['events'] as List).cast<Map>();
    for (final event in analysis.events) {
      final row = rows.singleWhere(
          (value) => value['sourceIdentity'] == event.identity.value);
      expect(row['status'], 'adaptedStaticSemantics', reason: row.toString());
    }
    final approval = approveNativeFixtureDraft(events.draft);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, events.draft, limits: limits);
    expect(receipt.verified, isTrue);
    final handles = WorkspaceHandleStore();
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(receipt.projectPath);
    try {
      final loaded = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(loaded.loadDiagnostics, isEmpty);
      for (final id in [41, 83]) {
        expect(loaded.mapById(events.draft.mapIds[id]!)!.triggers, isNotEmpty);
      }
      final reference = {
        'kind': 'std06ConvertedDoorFixture',
        'projectFilePath': receipt.projectPath,
        'startMapId': events.draft.mapIds[41],
        'otherMapId': events.draft.mapIds[83],
        'spawn': {'x': 2, 'y': 3},
        'door': {'x': 2, 'y': 2},
        'arrival': {'x': 2, 'y': 3},
        'arrivalFacing': 'south',
        'sourceMaps': [41, 83],
        'sourceDoorEvents': [3, 11],
        'sceneIds': events.projection.scenes.map((scene) => scene.id).toList(),
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'nativeWriterVerified': receipt.verified,
        'strictReopenVerified': true,
        'doorPresentation': 'invisibleSourceDoor',
        'destinationRoles': ['exterior', 'interior'],
      };
      if (requested != null) {
        await File('${output.path}/reference.json').writeAsString(
            '${const JsonEncoder.withIndent('  ').convert(reference)}\n');
      }
      stdout.writeln(jsonEncode(reference));
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
