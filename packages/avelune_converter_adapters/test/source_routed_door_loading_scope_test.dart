import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/src/builtin_source_interpretation_profiles.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_adapters/src/source_routed_door_program.dart';
import 'package:avelune_converter_adapters/src/source_static_door_program.dart';
import 'package:avelune_converter_adapters/src/source_external_warp_binding.dart';
import 'package:avelune_converter_adapters/src/source_sequence_program.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

final _scriptsPath = Platform.environment['AVELUNE_KNOWN_SCRIPTS_ARCHIVE'];
final _oracle = () async {
  final bytes = await File(_scriptsPath!).readAsBytes();
  final fixture = await LiteralTileFixture.create(
      scriptsBytes: bytes,
      interpretationProfileForSnapshot:
          detectBuiltinSourceInterpretationProfile);
  return (bytes: bytes, profile: fixture.source.interpretationProfile!);
}();

({List<int> bytes, SourceInterpretationProfile profile}) _changedSection(
    List<int> bytes, SourceInterpretationProfile profile, int index) {
  final document = const MarshalDecoder().decode(bytes);
  final rows = document.node(document.rootId).elements;
  final changedHashes = <int, String>{};
  final changed = <int>[
    4,
    8,
    0x5b,
    ...literalFixtureMarshal(rows.length).skip(3),
    for (var i = 0; i < rows.length; i++)
      ...() {
        final row = document.node(rows[i]).elements;
        var compressed = document.node(row[2]).bytes!;
        if (i == index) {
          final content = [
            ...const BoundedZlibDecoder().decode(compressed),
            10
          ];
          changedHashes[i] = literalFixtureHash(content).value;
          compressed = Uint8List.fromList(zlib.encode(content));
        }
        return [
          0x5b,
          8,
          ...literalFixtureMarshal(document.node(row[0]).integerValue!.toInt())
              .skip(2),
          ...literalFixtureMarshal(document.node(row[1]).text().text!).skip(2),
          0x22,
          ...literalFixtureMarshal(compressed.length).skip(3),
          ...compressed
        ];
      }(),
  ];
  return (
    bytes: changed,
    profile: SourceInterpretationProfile.fromJson({
      ...profile.toJson(),
      'scriptsArchive': {
        'relativePath': profile.scriptsRelativePath,
        'sha256': literalFixtureHash(changed).value
      },
      'sections': {
        for (final pin in profile.sections.entries)
          pin.key: {
            ...pin.value,
            if (changedHashes[pin.value['index']] case final hash?)
              'sha256': hash
          }
      },
    })
  );
}

LiteralFixtureUserDefined _tone(double value) {
  final bytes = ByteData(32);
  for (var axis = 0; axis < 3; axis++) {
    bytes.setFloat64(axis * 8, value, Endian.little);
  }
  return LiteralFixtureUserDefined('Tone', bytes.buffer.asUint8List());
}

Future<({LiteralTileFixture fixture, NormalizedSourceProject source})>
    _fixture({
  int offset = 200,
  int width = 3,
  bool inverse = false,
  bool ambiguous = false,
  bool knownEngine = true,
  bool scroll = false,
  bool representNeighbor = false,
  int? changedSection,
  bool neighborScroll = false,
  bool commonScroll = false,
  bool jump = false,
  int jumpActor = -1,
  bool excludeCustomBehavior = true,
  bool staticDoor = false,
  bool originalFade = false,
  bool sameScope = false,
}) async {
  final engine = knownEngine ? await _oracle : null;
  final changed = engine == null
      ? null
      : changedSection == null
          ? engine
          : _changedSection(engine.bytes, engine.profile, changedSection);
  final step = const LiteralFixtureObject('RPG::MoveCommand', {
    '@code': 1,
    '@parameters': <Object?>[],
  });
  LiteralFixtureEvent jumpEvent() {
    const step = LiteralFixtureObject('RPG::MoveCommand', {
      '@code': 14,
      '@parameters': [64, 0]
    });
    return LiteralFixtureEvent(id: 9, x: 0, y: 0, pages: [
      LiteralFixtureEventPage(commands: [
        LiteralFixtureEventCommand(209, [
          jumpActor,
          LiteralFixtureObject('RPG::MoveRoute', {
            '@repeat': false,
            '@skippable': true,
            '@list': [
              step,
              const LiteralFixtureObject(
                  'RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]})
            ],
          })
        ]),
        const LiteralFixtureEventCommand(509, [step]),
        const LiteralFixtureEventCommand(210, []),
        const LiteralFixtureEventCommand(0, []),
      ]),
    ]);
  }

  final fixture = await LiteralTileFixture.create(
    scriptsBytes: changed?.bytes ?? syntheticInterpretationArchive,
    interpretationProfile: SourceInterpretationProfile.fromJson({
      ...(changed?.profile ?? syntheticSourceInterpretationProfile).toJson(),
      'customPluginPolicy':
          excludeCustomBehavior ? 'excludeCustomBehavior' : 'requireAbsent',
    }),
    includeEventSystem: true,
    switchNames: [null, 's:tsOff?("A")'],
    commonEvents: {
      if (commonScroll)
        1: const [
          LiteralFixtureEventCommand(203, [2, 1000, 6])
        ]
    },
    extraFiles: {
      'Data/map_connections.dat': literalFixtureMarshal([
        inverse ? [73, 'S', 0, 71, 'N', offset] : [71, 'N', offset, 73, 'S', 0],
        if (ambiguous) [71, 'N', 0, 73, 'S', 0],
        if (neighborScroll) [71, 'N', 0, 74, 'S', 0],
      ]),
    },
    maps: [
      LiteralFixtureMap(
        id: 71,
        width: width,
        height: 3,
        layers: [
          List.filled(width * 3, 384),
          List.filled(width * 3, 0),
          List.filled(width * 3, 0)
        ],
        events: [
          LiteralFixtureEvent(id: 5, x: 1, y: 1, pages: [
            LiteralFixtureEventPage(
                trigger: 1,
                pattern: 1,
                through: staticDoor,
                commands: [
                  if (staticDoor || originalFade)
                    const LiteralFixtureEventCommand(250, [
                      LiteralFixtureObject('RPG::AudioFile', {
                        '@name': 'Original latch',
                        '@volume': 80,
                        '@pitch': 100
                      })
                    ]),
                  LiteralFixtureEventCommand(223, [_tone(-255), 6]),
                  const LiteralFixtureEventCommand(106, [8]),
                  LiteralFixtureEventCommand(
                      201, [0, sameScope ? 71 : 72, 1, 1, 8, 1]),
                  LiteralFixtureEventCommand(223, [_tone(0), 6]),
                  const LiteralFixtureEventCommand(0, []),
                ]),
            if (!staticDoor && !originalFade)
              LiteralFixtureEventPage(
                  trigger: 3,
                  pattern: 1,
                  globalSwitch: 1,
                  commands: [
                    const LiteralFixtureEventCommand(
                        111, [12, 'get_self.onEvent?']),
                    LiteralFixtureEventCommand(
                        209,
                        [
                          -1,
                          LiteralFixtureObject('RPG::MoveRoute', {
                            '@repeat': false,
                            '@skippable': true,
                            '@list': [
                              step,
                              const LiteralFixtureObject('RPG::MoveCommand',
                                  {'@code': 0, '@parameters': <Object?>[]})
                            ],
                          })
                        ],
                        indent: 1),
                    LiteralFixtureEventCommand(509, [step], indent: 1),
                    const LiteralFixtureEventCommand(210, [], indent: 1),
                    const LiteralFixtureEventCommand(412, []),
                    const LiteralFixtureEventCommand(
                        355, ['setTempSwitchOn("A")']),
                    const LiteralFixtureEventCommand(0, []),
                  ]),
          ]),
          if (sameScope)
            const LiteralFixtureEvent(id: 6, x: 0, y: 0, pages: [
              LiteralFixtureEventPage(commands: [
                LiteralFixtureEventCommand(106, [1]),
                LiteralFixtureEventCommand(0, [])
              ]),
            ]),
          if (scroll)
            const LiteralFixtureEvent(id: 6, x: 0, y: 0, pages: [
              LiteralFixtureEventPage(trigger: 4, commands: [
                LiteralFixtureEventCommand(203, [2, 1000, 6]),
                LiteralFixtureEventCommand(0, []),
              ]),
            ]),
          if (jump && jumpActor == -1) jumpEvent(),
        ],
      ),
      LiteralFixtureMap(id: 72, height: 3, layers: [
        List.filled(9, 384),
        List.filled(9, 0),
        List.filled(9, 0),
      ]),
      LiteralFixtureMap(id: 73, events: [
        const LiteralFixtureEvent(id: 8, x: 0, y: 0, pages: [
          LiteralFixtureEventPage(
              trigger: 4,
              moveType: 3,
              autonomousRouteCodes: [
                20,
                0
              ],
              commands: [
                LiteralFixtureEventCommand(
                    355, ['opaque_neighbor_controller()']),
                LiteralFixtureEventCommand(0, []),
              ]),
        ]),
        if (jump && jumpActor != -1) jumpEvent(),
      ]),
      if (neighborScroll)
        LiteralFixtureMap(id: 74, events: const [
          LiteralFixtureEvent(id: 2, x: 0, y: 0, pages: [
            LiteralFixtureEventPage(trigger: 4, commands: [
              LiteralFixtureEventCommand(203, [6, 1000, 6]),
              LiteralFixtureEventCommand(0, []),
            ]),
          ]),
        ]),
    ],
  );
  final source = await const RmxpSourceNormalizer().normalize(
    snapshot: fixture.snapshot,
    files: fixture.files,
    selectedMapIds: {71, 72, if (representNeighbor) 73},
    includeEventSystem: true,
    includeConnections: true,
    interpretationProfile: fixture.source.interpretationProfile,
  );
  expect(source.canPlan, isTrue, reason: source.diagnostics.toString());
  return (fixture: fixture, source: source);
}

Future<SourceEventExecutionContext> _context(
  ({LiteralTileFixture fixture, NormalizedSourceProject source}) input, {
  bool routed = true,
  bool staticDoor = false,
  bool originalFade = false,
  bool withSequence = false,
  bool sequenceFirst = false,
  bool forgedFade = false,
}) async {
  final source = input.source;
  final analysis = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze();
  final programs = sourceRoutedDoorPrograms(source: source, analysis: analysis);
  final staticPrograms =
      sourceStaticDoorPrograms(source: source, analysis: analysis);
  if (!originalFade) {
    expect(staticDoor ? staticPrograms : programs, hasLength(1),
        reason: analysis
            .eventAt(71, 5)!
            .pages
            .map((page) =>
                '${page.isQuarantined}/${page.body.nodes.map((node) => node.runtimeType).toList()}/${page.diagnostics.map((d) => d.code).toList()}')
            .join(';'));
  }
  final maps = {
    for (final ir in source.maps)
      ir.map.sourceMapId: MapData(
          id: 'native_${ir.map.sourceMapId}',
          name: ir.map.name,
          size: GridSize(width: ir.map.width, height: ir.map.height),
          layers: const []),
  };
  final base = NativeProjectDraft(
      source: source,
      projectName: 'Bound door scope',
      parentPath: Directory.systemTemp.path,
      folderName: 'bound-door-scope',
      mapIds: {
        for (final entry in maps.entries) entry.key: entry.value.id
      },
      artifacts: const [],
      mutations: [
        for (final entry in maps.entries)
          NativeMutation(
              operationId: ConverterId('map_${entry.key}'),
              actionId: 'map.save',
              sourceEntityIds: [
                source.mapIdentity(entry.key)
              ],
              targetEntityIds: [
                ConverterId(entry.value.id)
              ],
              parameters: {
                'mapId': entry.value.id,
                'map': entry.value.toJson()
              }),
      ]);
  if (originalFade) {
    final event = analysis.eventAt(71, 5)!;
    final binding = await const SourceExternalWarpBindingResolver()
        .read(source: source, analysis: analysis, files: input.fixture.files);
    expect(binding?.programs[event.identity]?.presentation,
        SourceExternalWarpPresentation.fade);
    final sequences =
        sourceSequencePrograms(source: source, analysis: analysis);
    if (withSequence) {
      expect(sequences.containsKey(source.eventIdentity(71, 6)), isTrue);
    }
    final supplied = !forgedFade
        ? analysis
        : SourceEventAnalysis(
            profile: analysis.profile,
            diagnostics: analysis.diagnostics,
            events: [
                for (final candidate in analysis.events)
                  if (candidate.identity != event.identity)
                    candidate
                  else
                    SourceEventDefinition(
                        sourceMapId: event.sourceMapId,
                        sourceEventId: event.sourceEventId,
                        sourceFileId: event.sourceFileId,
                        identity: event.identity,
                        name: event.name,
                        x: event.x + 1,
                        y: event.y,
                        locator: event.locator,
                        pages: event.pages),
              ]);
    final contexts = await const SourceEventExecutionContextResolver()
        .readProgramContexts(
            source: source,
            base: base,
            nativeMaps: maps,
            files: input.fixture.files,
            analysis: supplied,
            externalWarpBinding: binding,
            sequencePrograms: withSequence ? sequences : const {},
            eventIdentities: {
          if (withSequence && sequenceFirst) source.eventIdentity(71, 6),
          event.identity,
          if (withSequence && !sequenceFirst) source.eventIdentity(71, 6),
        });
    if (withSequence) {
      final sequence = contexts[source.eventIdentity(71, 6)]!;
      expect(sequence.isQualified, isFalse,
          reason: 'A generic sequence cannot reuse a door loading proof');
      expect(sequence.refusals, contains('sourceParallelEventUnsupported'));
    }
    return contexts[event.identity]!;
  }
  return const SourceEventExecutionContextResolver().read(
      source: source,
      base: base,
      nativeMaps: maps,
      files: input.fixture.files,
      routedDoorProgram: routed && !staticDoor ? programs.values.single : null,
      staticDoorProgram: staticDoor ? staticPrograms.values.single : null);
}

void main() {
  final skip =
      _scriptsPath == null ? 'Explicit known engine archive required' : false;

  test('a witnessed distant neighbor cannot block a bound static door',
      () async {
    final context =
        await _context(await _fixture(staticDoor: true), staticDoor: true);
    expect(context.isQualified, isTrue, reason: context.refusals.toString());
    expect(
        ((context.toJson()['proof'] as Map)['retainedMapLoading']
            as Map)['excludedSourceMapIds'],
        [73]);
  }, skip: skip);

  test('a static door retains its nearby unsafe neighbor', () async {
    final context = await _context(await _fixture(staticDoor: true, offset: 0),
        staticDoor: true);
    expect(context.isQualified, isFalse);
    expect(context.refusals, contains('sourceParallelEventUnsupported'));
  }, skip: skip);

  test('a witnessed distant neighbor cannot block an original closed fade door',
      () async {
    final context =
        await _context(await _fixture(originalFade: true), originalFade: true);
    expect(context.isQualified, isTrue, reason: context.refusals.toString());
  }, skip: skip);

  test('an original closed fade door retains its nearby unsafe neighbor',
      () async {
    final context = await _context(
        await _fixture(originalFade: true, offset: 0),
        originalFade: true);
    expect(context.isQualified, isFalse);
    expect(context.refusals, contains('sourceParallelEventUnsupported'));
  }, skip: skip);

  test(
      'a forged original closed fade door cannot obtain the bounded loading proof',
      () async {
    final input = await _fixture(originalFade: true);
    expect(
        () => _context(input, originalFade: true, forgedFade: true),
        throwsA(isA<NativeWriteException>()
            .having((error) => error.code, 'code', 'events.program.binding')));
  }, skip: skip);

  for (final sequenceFirst in [false, true]) {
    test(
        'a generic sequence cannot share original fade scope eligibility $sequenceFirst',
        () async {
      final context = await _context(
          await _fixture(originalFade: true, sameScope: true),
          originalFade: true,
          withSequence: true,
          sequenceFirst: sequenceFirst);
      expect(context.isQualified, isTrue, reason: context.refusals.toString());
    }, skip: skip);
  }

  test('a witnessed distant neighbor cannot block a bound routed door',
      () async {
    final context = await _context(await _fixture());
    expect(context.isQualified, isTrue, reason: context.refusals.toString());
    final proof = context.toJson()['proof'] as Map;
    final loading = proof['retainedMapLoading'] as Map;
    expect(loading['excludedSourceMapIds'], [73]);
    expect(
        (proof['witnesses'] as List)
            .whereType<Map>()
            .any((witness) => witness['relativePath'] == 'Data/Map073.rxdata'),
        isTrue);
  }, skip: skip);

  test('inverting the source connection retains the same distant scope proof',
      () async {
    final context = await _context(await _fixture(inverse: true));
    expect(context.isQualified, isTrue, reason: context.refusals.toString());
    expect(
        ((context.toJson()['proof'] as Map)['retainedMapLoading']
            as Map)['excludedSourceMapIds'],
        [73]);
  }, skip: skip);

  test('a represented distant neighbor has the same bounded execution scope',
      () async {
    final context = await _context(await _fixture(representNeighbor: true));
    expect(context.isQualified, isTrue, reason: context.refusals.toString());
    expect(
        ((context.toJson()['proof'] as Map)['retainedMapLoading']
            as Map)['excludedSourceMapIds'],
        [73]);
  }, skip: skip);

  test(
      'changing an unrelated source section preserves the engine loading proof',
      () async {
    final context = await _context(await _fixture(changedSection: 1));
    expect(context.isQualified, isTrue, reason: context.refusals.toString());
  }, skip: skip);

  test('a distant NPC jump cannot move the native player camera', () async {
    final context = await _context(await _fixture(jump: true, jumpActor: 0));
    expect(context.isQualified, isTrue, reason: context.refusals.toString());
  }, skip: skip);

  test(
      'without explicit custom exclusion an unrelated change keeps all neighbors',
      () async {
    final context = await _context(
        await _fixture(changedSection: 1, excludeCustomBehavior: false));
    expect(context.isQualified, isFalse);
    expect(context.refusals, contains('sourceParallelEventUnsupported'));
  }, skip: skip);

  for (final section in [0, 43]) {
    test('changing camera witness section $section keeps all neighbors',
        () async {
      final context = await _context(await _fixture(changedSection: section));
      expect(context.isQualified, isFalse);
      expect(context.refusals, contains('sourceParallelEventUnsupported'));
    }, skip: skip);
  }

  for (final scenario in ['neighbor scroll', 'common scroll', 'jump']) {
    test('a $scenario prevents exclusion of a distant unsafe neighbor',
        () async {
      final context = await _context(await _fixture(
          neighborScroll: scenario == 'neighbor scroll',
          commonScroll: scenario == 'common scroll',
          jump: scenario == 'jump'));
      expect(context.isQualified, isFalse);
      expect(context.refusals, contains('sourceMapAutonomyContextUnsupported'));
    }, skip: skip);
  }

  for (final scenario in [
    'near',
    'opposite edge',
    'ambiguous',
    'transition fringe',
    'scroll',
    'other program'
  ]) {
    test('a $scenario context preserves the conservative neighbor refusal',
        () async {
      final input = await _fixture(
          offset: switch (scenario) {
            'near' => 0,
            'opposite edge' => 90,
            'transition fringe' => 26,
            _ => 200,
          },
          width: scenario == 'opposite edge' ? 100 : 3,
          ambiguous: scenario == 'ambiguous',
          scroll: scenario == 'scroll');
      final context =
          await _context(input, routed: scenario != 'other program');
      expect(context.isQualified, isFalse);
      expect(context.refusals, contains('sourceParallelEventUnsupported'));
    }, skip: skip);
  }

  test('an unknown source engine keeps every declared neighbor', () async {
    final context = await _context(await _fixture(knownEngine: false));
    expect(context.isQualified, isFalse);
    expect(context.refusals, contains('sourceParallelEventUnsupported'));
  });
}
