import 'dart:typed_data';

import 'package:avelune_converter_adapters/src/source_routed_door_program.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

LiteralFixtureObject _step(int code) => LiteralFixtureObject('RPG::MoveCommand', {
      '@code': code,
      '@parameters': code == 44
          ? [const LiteralFixtureObject('RPG::AudioFile', {'@name': 'Chime', '@volume': 80, '@pitch': 100})]
          : code == 15 ? [2] : <Object?>[],
    });

List<LiteralFixtureEventCommand> _route(int actor, List<int> codes, {int indent = 0}) => [
      LiteralFixtureEventCommand(209, [actor, LiteralFixtureObject('RPG::MoveRoute', {
        '@repeat': false, '@skippable': true, '@list': [...codes.map(_step), _step(0)],
      })], indent: indent),
      for (final code in codes) LiteralFixtureEventCommand(509, [_step(code)], indent: indent),
      LiteralFixtureEventCommand(210, [], indent: indent),
    ];

LiteralFixtureUserDefined _tone(double value) {
  final bytes = ByteData(32);
  for (var axis = 0; axis < 3; axis++) { bytes.setFloat64(axis * 8, value, Endian.little); }
  return LiteralFixtureUserDefined('Tone', bytes.buffer.asUint8List());
}

Future<LiteralTileFixture> routedDoorFixture(String charset, {bool declared = true, bool wrongPin = false, bool unknownArrivalScript = false}) async {
  final pixels = literalFixtureAtlas();
  final profile = SourceInterpretationProfile.fromJson({
    ...syntheticSourceInterpretationProfile.toJson(),
    if (declared) 'presentationBindings': {
      'characterSubstitutions': [], 'pickupFeedbackByRegion': [],
      'routedDoorPatterns': [{'charset': charset,
        'sha256': wrongPin ? '0' * 64 : literalFixtureHash(pixels).value,
        'departurePattern': 3, 'arrivalPattern': 1}],
    },
  });
  return LiteralTileFixture.create(namespace: 'door-$charset',
      scriptsBytes: syntheticInterpretationArchive, interpretationProfile: profile,
      includeEventSystem: true, switchNames: [null, 's:tsOff?("A")'],
      extraFiles: {'Graphics/Characters/$charset.png': pixels},
      maps: [LiteralFixtureMap(id: 7, events: [LiteralFixtureEvent(id: 3, x: 0, y: 0, pages: [
        LiteralFixtureEventPage(trigger: 1, characterName: charset, pattern: 3, commands: [
          ..._route(0, [44, 15, 17, 15, 18, 15, 19, 15]),
          ..._route(-1, [37, 4, 38]),
          const LiteralFixtureEventCommand(208, [0]),
          ..._route(0, [15, 18, 15, 17, 15, 16, 15]),
          LiteralFixtureEventCommand(223, [_tone(-255), 4]),
          const LiteralFixtureEventCommand(106, [4]),
          const LiteralFixtureEventCommand(208, [1]),
          const LiteralFixtureEventCommand(201, [0, 9, 0, 0, 0, 1]),
          LiteralFixtureEventCommand(223, [_tone(0), 4]),
          const LiteralFixtureEventCommand(0, []),
        ]),
        LiteralFixtureEventPage(trigger: 3, globalSwitch: 1,
            characterName: charset, pattern: 1, commands: [
          const LiteralFixtureEventCommand(111, [12, 'get_self.onEvent?']),
          const LiteralFixtureEventCommand(208, [0], indent: 1),
          ..._route(0, [44, 15, 17, 15, 18, 15, 19, 15], indent: 1),
          const LiteralFixtureEventCommand(208, [1], indent: 1),
          ..._route(-1, [1], indent: 1),
          ..._route(0, [18, 15, 17, 15, 16, 15], indent: 1),
          const LiteralFixtureEventCommand(0, [], indent: 1),
          const LiteralFixtureEventCommand(412, []),
          LiteralFixtureEventCommand(355, [unknownArrivalScript ? 'unqualifiedEffect()' : 'setTempSwitchOn("A")']),
          const LiteralFixtureEventCommand(0, []),
        ]),
      ])]), LiteralFixtureMap(id: 9)]);
}

void main() {
  test('routed door presentation is declared independently of charset names', () async {
    for (final charset in ['CopperGate', 'CrystalPortal']) {
      final fixture = await routedDoorFixture(charset);
      final analysis = SourceEventAnalyzer.forProject(fixture.source,
          profile: SourceEventProfile.forProject(fixture.source)).analyze();
      final programs = sourceRoutedDoorPrograms(source: fixture.source, analysis: analysis);
      expect(programs, hasLength(1), reason: analysis.events.map((event) =>
          [event.isQuarantined, for (final page in event.pages)
            page.body.nodes.map((node) => node.runtimeType.toString()).toList()]).toString());
      expect(programs.values.single.nativeStableDepartureDoorSkin, isTrue);
      expect(programs.values.single.isBoundTo(source: fixture.source,
          analysis: analysis, event: analysis.eventAt(7, 3)!), isTrue);
    }
  });
  test('routed door mismatched patterns require an explicit attested binding', () async {
    for (final fixture in [await routedDoorFixture('Undeclared', declared: false),
      await routedDoorFixture('Changed', wrongPin: true)]) {
      final analysis = SourceEventAnalyzer.forProject(fixture.source,
          profile: SourceEventProfile.forProject(fixture.source)).analyze();
      expect(sourceRoutedDoorPrograms(source: fixture.source, analysis: analysis), isEmpty);
    }
  });
}
