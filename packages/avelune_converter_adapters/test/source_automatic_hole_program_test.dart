import 'dart:typed_data';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/source_hole_native_program.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/source_external_original_fixture.dart';

LiteralFixtureUserDefined _tone(double value) {
  final data = ByteData(32);
  for (var index = 0; index < 3; index++) {
    data.setFloat64(index * 8, value, Endian.little);
  }
  return LiteralFixtureUserDefined('Tone', data.buffer.asUint8List());
}

List<LiteralFixtureEventCommand> _opacity(int value, String defect) {
  final step = LiteralFixtureObject('RPG::MoveCommand', {
    '@code': defect == 'movement' ? 1 : 42,
    '@parameters': defect == 'movement' ? <Object?>[] : [value],
  });
  return [
    LiteralFixtureEventCommand(209, [
      defect == 'owner' ? 0 : -1,
      LiteralFixtureObject('RPG::MoveRoute', {
        '@repeat': defect == 'repeat',
        '@skippable': false,
        '@list': [
          step,
          const LiteralFixtureObject('RPG::MoveCommand', {
            '@code': 0,
            '@parameters': <Object?>[],
          }),
        ],
      }),
    ]),
    LiteralFixtureEventCommand(509, [
      defect == 'copy'
          ? const LiteralFixtureObject('RPG::MoveCommand', {
              '@code': 42,
              '@parameters': [127],
            })
          : step,
    ]),
  ];
}

Future<({NormalizedSourceProject source, SourceEventAnalysis analysis})>
    _source({String defect = '', bool terrainBump = false}) async {
  const falling = LiteralFixtureEventCommand(250, [
    LiteralFixtureObject('RPG::AudioFile', {
      '@name': 'Falling Object',
      '@volume': 80,
      '@pitch': 100,
    }),
  ]);
  final commands = [
    if (terrainBump) falling,
    ..._opacity(defect == 'hidden' ? 127 : 0, defect),
    if (!terrainBump) const LiteralFixtureEventCommand(210, []),
    if (!terrainBump) falling,
    LiteralFixtureEventCommand(106, [defect == 'wait' ? 5 : 4]),
    LiteralFixtureEventCommand(223, [_tone(-255), 6]),
    const LiteralFixtureEventCommand(106, [8]),
    LiteralFixtureEventCommand(201, [0, 2, 1, 0, 0, defect == 'fade' ? 0 : 1]),
    if (terrainBump) const LiteralFixtureEventCommand(210, []),
    ..._opacity(defect == 'visible' ? 127 : 255, defect),
    if (!terrainBump) const LiteralFixtureEventCommand(210, []),
    LiteralFixtureEventCommand(223, [_tone(0), 6]),
    const LiteralFixtureEventCommand(250, [
      LiteralFixtureObject('RPG::AudioFile', {
        '@name': 'Landing Object',
        '@volume': 80,
        '@pitch': 100,
      }),
    ]),
    if (defect == 'ruby') const LiteralFixtureEventCommand(355, ['unknown()']),
    const LiteralFixtureEventCommand(0, []),
  ];
  final fixture = await LiteralTileFixture.create(
    interpretationProfile: syntheticSourceInterpretationProfile,
    scriptsBytes: syntheticInterpretationArchive,
    includeEventSystem: true,
    maps: [
      LiteralFixtureMap(id: 1, events: [
        LiteralFixtureEvent(
            id: 1,
            x: 1,
            y: 0,
            name: terrainBump
                ? defect == 'footprint'
                    ? 'Fall size(2,2)'
                    : 'Fall size(2,1)'
                : 'Hole',
            pages: [
              LiteralFixtureEventPage(
                trigger: defect == 'trigger' ? 0 : 1,
                through: terrainBump ? defect == 'through' : defect != 'solid',
                globalSwitch: defect == 'condition' ? 1 : null,
                moveType: defect == 'autonomy' ? 1 : 0,
                characterName: defect == 'graphic' ? 'Visible' : '',
                commands: commands,
              ),
              if (defect == 'pages')
                const LiteralFixtureEventPage(commands: [
                  LiteralFixtureEventCommand(0, []),
                ]),
            ]),
      ]),
      LiteralFixtureMap(id: 2),
    ],
  );
  final analysis = SourceEventAnalyzer.forProject(fixture.source,
          profile: SourceEventProfile.forProject(fixture.source))
      .analyze();
  return (source: fixture.source, analysis: analysis);
}

void main() {
  final sourceRoot = Platform.environment['AVELUNE_AUTOMATIC_HOLE_SOURCE_ROOT'];
  final snapshotPath =
      Platform.environment['AVELUNE_AUTOMATIC_HOLE_SOURCE_SNAPSHOT'];
  test('eighteen original holes bind automatically with the real script oracle',
      () async {
    final fixture = await readExternalOriginalSource(sourceRoot!, snapshotPath!,
        selectedMapIds: {203, 204, 361, 362, 363, 364, 365, 366},
        supplementalRoots: (Platform
                    .environment['AVELUNE_AUTOMATIC_HOLE_SUPPLEMENTAL_ROOTS'] ??
                '')
            .split('|')
            .where((root) => root.isNotEmpty)
            .toList());
    final analysis = SourceEventAnalyzer.forProject(fixture.source,
            profile: SourceEventProfile.forProject(fixture.source))
        .analyze();
    expect(analysis.profile.isQualified, isTrue);
    expect(analysis.profile.scriptsArchiveHash!.value,
        '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d');
    expect(analysis.profile.interpretationProfile!.declaredPrograms, isEmpty);
    expect(analysis.events.where(isSourceHoleNativeIdentity), hasLength(18));
    final programs =
        sourceHoleNativePrograms(source: fixture.source, analysis: analysis);
    expect(programs, hasLength(18));
    for (final program in programs.values) {
      expect(program.declaredProgramBinding.automaticallyDiscovered, isTrue);
      expect(program.waits.map((wait) => wait.durationMs), [200, 400]);
      expect(program.fallingSound.name, 'Falling Object');
      expect(program.landingSound.name, 'Landing Object');
      expect(
          program.isBoundTo(
              source: fixture.source,
              analysis: analysis,
              event: analysis.events.singleWhere(
                  (event) => event.identity == program.eventIdentity)),
          isTrue);
    }
  },
      skip: sourceRoot == null ||
          snapshotPath == null ||
          Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'] == null);

  test('original Mansion falls bind automatically with their terrain contact',
      () async {
    final fixture = await readExternalOriginalSource(sourceRoot!, snapshotPath!,
        selectedMapIds: {197, 198, 199},
        supplementalRoots: (Platform
                    .environment['AVELUNE_AUTOMATIC_HOLE_SUPPLEMENTAL_ROOTS'] ??
                '')
            .split('|')
            .where((root) => root.isNotEmpty)
            .toList());
    final analysis = SourceEventAnalyzer.forProject(fixture.source,
            profile: SourceEventProfile.forProject(fixture.source))
        .analyze();
    final programs =
        sourceHoleNativePrograms(source: fixture.source, analysis: analysis);
    expect(programs, hasLength(2));
    for (final eventId in [14, 15]) {
      final event = analysis.eventAt(199, eventId)!;
      final program = programs[event.identity]!;
      expect(program.terrainBump, isTrue);
      expect(program.declaredProgramBinding.automaticallyDiscovered, isTrue);
      expect(program.warp.targetSourceMapId, eventId == 14 ? 198 : 197);
      expect([program.warp.x, program.warp.y],
          eventId == 14 ? [29, 19] : [21, 24]);
      expect(program.waits.map((wait) => wait.durationMs), [200, 400]);
      expect(program.fallingSound.name, 'Falling Object');
      expect(program.landingSound.name, 'Landing Object');
    }
  },
      skip: sourceRoot == null ||
          snapshotPath == null ||
          Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'] == null);

  test('an exact hole is discovered without a hand-authored declaration',
      () async {
    final fixture = await _source();
    expect(fixture.analysis.profile.interpretationProfile!.declaredPrograms,
        isEmpty);
    expect(isSourceHoleNativeIdentity(fixture.analysis.events.single), isTrue);
    final programs = sourceHoleNativePrograms(
      source: fixture.source,
      analysis: fixture.analysis,
    );
    expect(programs, hasLength(1));
    final program = programs.values.single;
    expect(program.declaredProgramBinding.automaticallyDiscovered, isTrue);
    expect(program.warp.targetSourceMapId, 2);
    expect([program.warp.x, program.warp.y], [1, 0]);
    expect(program.waits.map((wait) => wait.durationMs), [200, 400]);
    expect(program.fallingSound.name, 'Falling Object');
    expect(program.landingSound.name, 'Landing Object');
    expect(
        program.isBoundTo(
            source: fixture.source,
            analysis: fixture.analysis,
            event: fixture.analysis.events.single),
        isTrue);
  });

  test('terrain bump falls preserve their source command order', () async {
    final fixture = await _source(terrainBump: true);
    final programs = sourceHoleNativePrograms(
        source: fixture.source, analysis: fixture.analysis);
    expect(programs, hasLength(1));
    final program = programs.values.single;
    expect(program.declaredProgramBinding.automaticallyDiscovered, isTrue);
    expect(program.warp.targetSourceMapId, 2);
    expect(program.waits.map((wait) => wait.durationMs), [200, 400]);
    expect(program.toJson()['terrainBump'], isTrue);
    expect(program.toJson()['fallingSoundBeforeVisibility'], isTrue);
  });

  for (final defect in [
    'movement',
    'owner',
    'repeat',
    'copy',
    'hidden',
    'visible',
    'wait',
    'fade',
    'ruby',
    'trigger',
    'through',
    'footprint',
    'condition',
    'autonomy',
    'graphic',
    'pages',
  ]) {
    test('terrain bump fall refuses unsafe source program $defect', () async {
      final fixture = await _source(defect: defect, terrainBump: true);
      expect(
          sourceHoleNativePrograms(
              source: fixture.source, analysis: fixture.analysis),
          isEmpty);
    });
  }

  for (final defect in [
    'movement',
    'owner',
    'repeat',
    'copy',
    'hidden',
    'visible',
    'wait',
    'fade',
    'ruby',
    'trigger',
    'solid',
    'condition',
    'autonomy',
    'graphic',
    'pages',
  ]) {
    test('automatic hole refuses unsafe source program $defect', () async {
      final fixture = await _source(defect: defect);
      expect(
          sourceHoleNativePrograms(
              source: fixture.source, analysis: fixture.analysis),
          isEmpty);
    });
  }
}
