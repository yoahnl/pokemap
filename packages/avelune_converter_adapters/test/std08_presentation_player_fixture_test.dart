import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'std08_source_presentation_test.dart' show audio, color;
import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';
import 'support/source_map_music_fixture.dart';

List<int> _wave(int frequency) {
  final bytes = sourceMapMusicFixtureWav();
  for (var index = 44; index < bytes.length; index++) {
    bytes[index] = 128 +
        (32 * math.sin(2 * math.pi * frequency * (index - 44) / 8000)).round();
  }
  return bytes;
}

LiteralFixtureUserDefined _tone(double value) {
  final bytes = ByteData(32);
  for (var channel = 0; channel < 3; channel++) {
    bytes.setFloat64(channel * 8, value, Endian.little);
  }
  return LiteralFixtureUserDefined('Tone', bytes.buffer.asUint8List());
}

LiteralFixtureEvent _door(int target) {
  const step = LiteralFixtureObject('RPG::MoveCommand', {
    '@code': 1,
    '@parameters': <Object?>[],
  });
  const end = LiteralFixtureObject('RPG::MoveCommand', {
    '@code': 0,
    '@parameters': <Object?>[],
  });
  return LiteralFixtureEvent(id: 9, x: 2, y: 2, pages: [
    LiteralFixtureEventPage(trigger: 1, commands: [
      LiteralFixtureEventCommand(223, [_tone(-255), 4]),
      const LiteralFixtureEventCommand(106, [4]),
      LiteralFixtureEventCommand(201, [0, target, 2, 2, 2, 1]),
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
            })
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

Future<LiteralTileFixture> std08PresentationFixture({
  bool missingPicture = false,
  bool unknownEffect = false,
  bool fog = false,
  bool missingFog = false,
}) async {
  final banner = image.Image(width: 240, height: 96, numChannels: 4);
  image.fill(banner, color: image.ColorRgba8(40, 96, 220, 255));
  image.fillRect(banner,
      x1: 12,
      y1: 12,
      x2: 227,
      y2: 83,
      color: image.ColorRgba8(255, 210, 40, 255));
  return LiteralTileFixture.create(
    namespace: 'std08-independent-presentation',
    scriptsBytes: syntheticInterpretationArchive,
    interpretationProfile: syntheticSourceInterpretationProfile,
    includeEventSystem: true,
    switchNames: [null, 's:tsOff?("A")'],
    extraFiles: {
      'PBS/metadata.txt': utf8.encode('[1]\nWalkCharset = Player\n'),
      'Graphics/Characters/Player.png': literalFixtureAtlas(),
      'Data/map_metadata.dat': literalFixtureMarshal({}),
      'Data/map_connections.dat': literalFixtureMarshal([]),
      if (!missingPicture)
        'Graphics/Pictures/Banner.png': image.encodePng(banner),
      if (!missingFog) 'Graphics/Fogs/Mist.png': image.encodePng(banner),
      'Audio/BGM/Theme.wav': _wave(440),
      'Audio/BGS/Wind.wav': _wave(220),
      'Audio/SE/Tap.wav': _wave(660),
      'Audio/ME/Jingle.wav': _wave(880),
    },
    maps: [
      for (final location in [(41, 83, 3), (83, 41, 11)])
        LiteralFixtureMap(id: location.$1, width: 8, height: 6, layers: [
          List.filled(48, 384),
          List.filled(48, 0),
          List.filled(48, 0),
        ], events: [
          _door(location.$2),
          LiteralFixtureEvent(id: location.$3, x: 4, y: 2, pages: [
            LiteralFixtureEventPage(characterName: 'Player', commands: [
              if (fog)
                const LiteralFixtureEventCommand(
                    204, [1, 'Mist', 0, 192, 0, 100, -8, 0])
              else ...[
                const LiteralFixtureEventCommand(247, []),
                LiteralFixtureEventCommand(241, [audio('Theme')]),
                LiteralFixtureEventCommand(245, [audio('Wind')]),
                const LiteralFixtureEventCommand(
                    231, [7, 'Banner', 1, 0, 220, 120, 100, 100, 255, 0]),
                const LiteralFixtureEventCommand(
                    232, [7, 20, 1, 0, 280, 150, 120, 100, 192, 0]),
                LiteralFixtureEventCommand(224, [
                  color([255, 80, 0, 128]),
                  20
                ]),
                const LiteralFixtureEventCommand(225, [4, 6, 20]),
                LiteralFixtureEventCommand(250, [audio('Tap')]),
                if (unknownEffect)
                  const LiteralFixtureEventCommand(355, ['pluginEffect()']),
              ],
              const LiteralFixtureEventCommand(0, []),
            ]),
          ]),
          LiteralFixtureEvent(id: location.$3 + 1, x: 6, y: 2, pages: [
            const LiteralFixtureEventPage(characterName: 'Player', commands: [
              LiteralFixtureEventCommand(242, [1]),
              LiteralFixtureEventCommand(246, [1]),
              LiteralFixtureEventCommand(106, [20]),
              LiteralFixtureEventCommand(248, []),
              LiteralFixtureEventCommand(235, [7]),
              LiteralFixtureEventCommand(251, []),
              LiteralFixtureEventCommand(0, []),
            ]),
          ]),
          LiteralFixtureEvent(id: location.$3 + 2, x: 6, y: 4, pages: [
            LiteralFixtureEventPage(characterName: 'Player', commands: [
              LiteralFixtureEventCommand(249, [audio('Jingle')]),
              const LiteralFixtureEventCommand(0, []),
            ]),
          ]),
        ]),
    ],
  );
}

Future<SourceEventStudyComposition> composeStd08Presentation(
    LiteralTileFixture fixture, String output) async {
  const limits = NativeWriteLimits(maxArtifacts: 128);
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: fixture.snapshot,
      files: fixture.files,
      selectedMapIds: {41, 83},
      interpretationProfile: syntheticSourceInterpretationProfile,
      includeEventSystem: true,
      includeConnections: true);
  final literal = await const LiteralTileComposer().compose(
      source: source,
      files: fixture.files,
      selectedSourceMapIds: [41, 83],
      projectName: 'STD08 source presentation Player fixture',
      parentPath: output,
      folderName: 'converted-presentation',
      limits: limits);
  expect(literal.draft, isNotNull, reason: '${literal.diagnostics}');
  final semantic = await const SourceSemanticStudyComposer().compose(
      source: source, base: literal, files: fixture.files, limits: limits);
  expect(semantic, isNotNull);
  final events = await const SourceEventStudyComposer().compose(
      source: source, base: semantic!, files: fixture.files, limits: limits);
  expect(events, isNotNull);
  return events!;
}

void main() {
  test('STD08 source pipeline exports two independent owned presentations',
      () async {
    final requested =
        Platform.environment['AVELUNE_STD08_PRESENTATION_FIXTURE_ROOT'];
    final output = requested == null
        ? await Directory.systemTemp.createTemp('std08-converted-presentation-')
        : await Directory(requested).create(recursive: true);
    if (requested == null) addTearDown(() => output.delete(recursive: true));
    final fixture = await std08PresentationFixture();
    final events = await composeStd08Presentation(fixture, output.path);
    final rows =
        (events.projection.semanticEvidence['events'] as List).cast<Map>();
    expect(rows, hasLength(8));
    for (final row in rows) {
      expect(row['status'], 'adaptedStaticSemantics', reason: '$row');
    }
    final commands = events.projection.scenes
        .expand((scene) => scene.graph.nodes)
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((payload) => payload.interactiveCommand)
        .whereType<SceneInteractiveCommand>()
        .map((command) => command.toJson())
        .toList();
    expect(commands.where((command) => command['kind'] == 'worldPresentation'),
        hasLength(10));
    expect(
        commands.where((command) =>
            command['kind'] == 'sceneMusic' &&
            command['channel'] == 'ambience'),
        hasLength(4));
    final approval = approveNativeFixtureDraft(events.draft);
    final receipt = await NativeProjectWriter().write(
        approval.plan, approval.context, events.draft,
        limits: const NativeWriteLimits(maxArtifacts: 128));
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
      final catalog = decodeProjectMediaCatalogBytes(
          loaded.resourceBytes(projectMediaCatalogResourceIdentity));
      expect(catalog.entries, hasLength(1));
      expect(catalog.entries.single.kind, ProjectMediaKind.image);
      expect(loaded.manifest.pokemon.enabled, isFalse);
      final starts = <Map<String, Object?>>[];
      for (final location in [(41, 3), (83, 11)]) {
        final map = loaded.mapById(events.draft.mapIds[location.$1]!)!;
        final sourceEvent =
            events.draft.source.eventIdentity(location.$1, location.$2);
        final entity = map.entities.singleWhere((entity) =>
            entity.properties['sourceEventIdentity'] == sourceEvent.value);
        final definitions = loaded.manifest.eventRegistry!.records
            .map((record) => record.definitionOrNull)
            .whereType<NarrativeEventDefinition>();
        final definition = definitions.singleWhere((definition) =>
            definition.source.toJson()['entityId'] == entity.id);
        starts.add({
          'sourceMapId': location.$1,
          'sourceEventId': location.$2,
          'mapId': map.id,
          'entityId': entity.id,
          'eventId': definition.id,
          'sceneId': definition.sceneId,
          'startAnchor': {'x': 4, 'y': 2},
          'restoreAnchor': {'x': 6, 'y': 2},
          'musicEffectAnchor': {'x': 6, 'y': 4}
        });
      }
      final reference = {
        'kind': 'std08ConvertedPresentationFixture',
        'projectFilePath': receipt.projectPath,
        'startMapId': events.draft.mapIds[41],
        'otherMapId': events.draft.mapIds[83],
        'spawn': {'x': 4, 'y': 3},
        'door': {'x': 2, 'y': 2},
        'arrival': {'x': 2, 'y': 3},
        'presentations': starts,
        'pictureMediaId': catalog.entries.single.id,
        'pictureSlot': 7,
        'referenceWidth': 512,
        'referenceHeight': 384,
        'sourceMaps': [41, 83],
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'nativeWriterVerified': receipt.verified,
        'strictReopenVerified': true,
        'nativeScopeAdaptation': 'mapPresentationResetOnTransfer',
        'sourceTemporalParity': false,
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

  test('STD08 unknown effects quarantine the whole source event', () async {
    final fixture = await std08PresentationFixture(unknownEffect: true);
    final events = await composeStd08Presentation(fixture, '/unused');
    final rows =
        (events.projection.semanticEvidence['events'] as List).cast<Map>();
    for (final map in [41, 83]) {
      final eventId = map == 41 ? 3 : 11;
      final identity = events.draft.source.eventIdentity(map, eventId).value;
      final row = rows.singleWhere((row) => row['sourceIdentity'] == identity);
      expect(row['status'], isNot('adaptedStaticSemantics'));
    }
  });

  test('STD08 fog capability and missing resource refusals remain distinct',
      () async {
    for (final missing in [false, true]) {
      final fixture =
          await std08PresentationFixture(fog: true, missingFog: missing);
      final events = await composeStd08Presentation(fixture, '/unused');
      final rows =
          (events.projection.semanticEvidence['events'] as List).cast<Map>();
      final identity = events.draft.source.eventIdentity(41, 3).value;
      final row = rows.singleWhere((row) => row['sourceIdentity'] == identity);
      expect(row['status'], isNot('adaptedStaticSemantics'));
      expect(jsonEncode(row), contains('sourceMapFogUnsupported'));
      expect(jsonEncode(row).contains('sourceFogImageMissing'), missing);
    }
  });
}
