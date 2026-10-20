import 'dart:convert';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/source_map_music_fixture.dart';

Object? _declaredValue(MarshalDocument document, int id) {
  final node = document.node(id);
  return switch (node.kind) {
    MarshalKind.nil => null,
    MarshalKind.boolean => node.booleanValue,
    MarshalKind.integer => node.integerValue!.toInt(),
    MarshalKind.string => node.text().text,
    MarshalKind.array => [
        for (final child in node.elements) _declaredValue(document, child)
      ],
    MarshalKind.object => {
        '__class__': node.className,
        for (final field in node.instanceVariables)
          document.node(field.key).name!.substring(1):
              _declaredValue(document, field.value)
      },
    MarshalKind.userDefined when node.className == 'Tone' => {
        '__class__': 'Tone',
        'marshalPayload': base64Encode(node.bytes!)
      },
    _ => throw StateError('Unsupported fixture node ${node.kind}'),
  };
}

Future<
    ({
      NormalizedSourceProject source,
      LiteralFixtureFiles files,
      SourceEventAnalysis analysis
    })> _fixture({int direction = 0, int mode = 0, bool plain = false}) async {
  List<int> tone(double channel) {
    final data = ByteData(32);
    for (var index = 0; index < 3; index++) {
      data.setFloat64(index * 8, channel, Endian.little);
    }
    return data.buffer.asUint8List();
  }

  final fixture = await LiteralTileFixture.create(
    interpretationProfile: syntheticSourceInterpretationProfile,
    scriptsBytes: syntheticInterpretationArchive,
    includeEventSystem: true,
    extraFiles: {
      'Audio/SE/Exit Door.wav': sourceMapMusicFixtureWav(),
      'Data/map_connections.dat': literalFixtureMarshal([]),
      'Data/map_metadata.dat': literalFixtureMarshal({}),
    },
    maps: [
      LiteralFixtureMap(id: 1, events: [
        LiteralFixtureEvent(id: 1, x: 1, y: 0, pages: [
          LiteralFixtureEventPage(trigger: 1, commands: [
            if (!plain) ...[
              const LiteralFixtureEventCommand(250, [
                LiteralFixtureObject('RPG::AudioFile',
                    {'@name': 'Exit Door', '@volume': 80, '@pitch': 100})
              ]),
              LiteralFixtureEventCommand(
                  223, [LiteralFixtureUserDefined('Tone', tone(-255)), 6]),
              const LiteralFixtureEventCommand(106, [8]),
              const LiteralFixtureEventCommand(355, ['pbCaveExit']),
            ],
            LiteralFixtureEventCommand(201, [mode, 2, 0, 0, direction, 1]),
            if (!plain)
              LiteralFixtureEventCommand(
                  223, [LiteralFixtureUserDefined('Tone', tone(0)), 6]),
            const LiteralFixtureEventCommand(0, []),
          ])
        ])
      ]),
      LiteralFixtureMap(
          id: 2,
          layers: [List.filled(3, 384), List.filled(3, 0), List.filled(3, 0)]),
    ],
  );
  final page = fixture.source.maps.first.map.events.single.pages.single;
  final reference = fixture.source.archive.references[page.rawDataRef]!;
  final document = fixture.source.sourceFiles[reference.fileId]!.document;
  final profile = SourceInterpretationProfile.fromJson({
    ...syntheticSourceInterpretationProfile.toJson(),
    'declaredPrograms': [
      if (!plain)
        {
          'id': 'closed-cave-exit-preserve-facing',
          'family': 'externalWarp',
          'pages': {'program': _declaredValue(document, reference.nodeId)},
          'parameters': {'presentation': 'caveExit'},
        }
    ],
  });
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: fixture.snapshot,
      files: fixture.files,
      selectedMapIds: {1, 2},
      includeConnections: true,
      includeEventSystem: true,
      interpretationProfile: profile);
  return (
    source: source,
    files: fixture.files,
    analysis: SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze()
  );
}

void main() {
  for (final direction in [0, 2, 4, 6, 8]) {
    test('closed source cave exit retains exact direction $direction',
        () async {
      final fixture = await _fixture(direction: direction);
      final event = fixture.analysis.eventAt(1, 1)!;
      expect(event.isQuarantined, isFalse);
      final warp = event.pages.single.body.nodes.single as SourceWarpNode;
      expect(warp.direction, direction);
      expect(warp.originalProgram, isNotNull);
      final program = warp.originalProgram!;
      expect(program.direction, direction);
      expect(program.matches(warp), isTrue);
      expect(
          program.isBoundToSourceEvent(
              source: fixture.source,
              profile: fixture.analysis.profile,
              event: fixture.source.maps.first.map.events.single),
          isTrue);
      expect(program.toJson()['sourceScriptsExecuted'], 0);
    });
  }

  for (final direction in [-1, 1, 3, 5, 7, 9, 10]) {
    test('unknown direction is not a closed external warp $direction',
        () async {
      final fixture = await _fixture(direction: direction);
      expect(
          fixture.analysis
              .eventAt(1, 1)!
              .pages
              .single
              .body
              .nodes
              .whereType<SourceWarpNode>()
              .any((node) => node.originalProgram != null),
          isFalse);
    });
  }

  test('variable destination mode is not promoted to a literal external warp',
      () async {
    final fixture = await _fixture(mode: 1);
    expect(
        fixture.analysis
            .eventAt(1, 1)!
            .pages
            .single
            .body
            .nodes
            .whereType<SourceWarpNode>()
            .any((node) => node.originalProgram != null),
        isFalse);
  });

  test(
      'external warp binding preserves source zero without importing escape state',
      () async {
    final fixture = await _fixture();
    final binding = await const SourceExternalWarpBindingResolver().read(
        source: fixture.source,
        analysis: fixture.analysis,
        files: fixture.files,
        policy: SourceExternalWarpPolicy.nativeTransitionsWithoutEscapeState);
    expect(binding, isNotNull);
    expect(binding!.programs.values.single.direction, 0);
    expect(binding.evidence['sourceEscapePoint'], 'notImported');
  });

  test('the existing native warp projection omits facing for source zero',
      () async {
    final fixture = await _fixture(plain: true);
    final maps = {
      for (final map in fixture.source.maps)
        map.map.sourceMapId: MapData(
            id: 'native-${map.map.sourceMapId}',
            name: 'Native',
            size: GridSize(width: map.map.width, height: map.map.height),
            layers: [
              MapLayer.collision(
                  id: 'collision',
                  name: 'Collision',
                  collisions:
                      List.filled(map.map.width * map.map.height, false))
            ])
    };
    final base = NativeProjectDraft(
        source: fixture.source,
        projectName: 'Preserved facing',
        parentPath: '/private/tmp',
        folderName: 'unused-facing-fixture',
        mapIds: {
          for (final entry in maps.entries) entry.key: entry.value.id
        },
        artifacts: const [],
        mutations: [
          for (final entry in maps.entries)
            NativeMutation(
                operationId: ConverterId('save-${entry.key}'),
                actionId: 'map.save',
                sourceEntityIds: const [],
                targetEntityIds: [
                  ConverterId(entry.value.id)
                ],
                parameters: {
                  'mapId': entry.value.id,
                  'map': entry.value.toJson()
                })
        ]);
    final context = await const SourceEventExecutionContextResolver().read(
        source: fixture.source,
        base: base,
        nativeMaps: maps,
        files: fixture.files);
    expect(context.isQualified, isTrue, reason: '${context.refusals}');
    final retention = await sourceEventMapRetentionPolicy(
        source: fixture.source,
        files: fixture.files,
        nativeMapIds: base.mapIds);
    final projected = const SourceEventProjector().project(
        source: fixture.source,
        analysis: fixture.analysis,
        nativeMaps: maps,
        executionContext: context,
        retentionPolicy: retention);
    final row = (projected.semanticEvidence['events'] as List).single as Map;
    expect(row['gaps'], isEmpty);
    final command = projected.scenes.single.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((payload) => payload.interactiveCommand)
        .whereType<SceneWarpInteractiveCommand>()
        .single;
    final reloaded = SceneInteractiveCommand.fromJson(
        jsonDecode(jsonEncode(command.toJson())));
    expect((reloaded as SceneWarpInteractiveCommand).arrivalFacing, isNull);
    expect(reloaded.toJson().containsKey('arrivalFacing'), isFalse);
  });
}
