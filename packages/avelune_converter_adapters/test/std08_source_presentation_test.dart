import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

Future<SourceEventDefinition> presentationEvent(
    List<LiteralFixtureEventCommand> commands,
    {int mapId = 17,
    int eventId = 23}) async {
  final fixture = await LiteralTileFixture.create(
      interpretationProfile: syntheticSourceInterpretationProfile,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      maps: [
        LiteralFixtureMap(id: mapId, events: [
          LiteralFixtureEvent(id: eventId, x: 1, y: 0, pages: [
            LiteralFixtureEventPage(commands: [
              ...commands,
              const LiteralFixtureEventCommand(0, []),
            ])
          ])
        ])
      ]);
  return SourceEventAnalyzer.forProject(fixture.source,
          profile: SourceEventProfile.forProject(fixture.source))
      .analyze()
      .eventAt(mapId, eventId)!;
}

LiteralFixtureObject audio(String name, {int pitch = 100}) =>
    LiteralFixtureObject('RPG::AudioFile', {
      '@name': name,
      '@volume': 75,
      '@pitch': pitch,
    });

LiteralFixtureUserDefined color(List<double> channels) {
  final bytes = ByteData(channels.length * 8);
  for (final entry in channels.indexed) {
    bytes.setFloat64(entry.$1 * 8, entry.$2, Endian.little);
  }
  return LiteralFixtureUserDefined('Color', bytes.buffer.asUint8List());
}

Map<String, Object?> presentationJson(SourceEventNode node) =>
    ((node as dynamic).toJson() as Map).cast<String, Object?>();

void main() {
  for (final location in [(17, 23), (731, 8)]) {
    test('STD08 audio controls preserve exact scope and raw source $location',
        () async {
      final event = await presentationEvent([
        LiteralFixtureEventCommand(241, [audio('')]),
        const LiteralFixtureEventCommand(242, [3]),
        LiteralFixtureEventCommand(245, [audio('Wind')]),
        LiteralFixtureEventCommand(245, [audio('')]),
        const LiteralFixtureEventCommand(246, [2]),
        const LiteralFixtureEventCommand(247, []),
        const LiteralFixtureEventCommand(248, []),
        const LiteralFixtureEventCommand(251, []),
      ], mapId: location.$1, eventId: location.$2);
      expect(event.isQuarantined, isFalse,
          reason: '${event.pages.single.diagnostics}');
      final values =
          event.pages.single.body.nodes.map(presentationJson).toList();
      expect(
          values.map((value) => value['kind']), everyElement('audioControl'));
      expect(values.map((value) => value['operation']), [
        'stop',
        'fadeOut',
        'play',
        'stop',
        'fadeOut',
        'memorize',
        'restoreMemorized',
        'stopEffects',
      ]);
      expect(values.map((value) => value['channel']), [
        'music',
        'music',
        'ambience',
        'ambience',
        'ambience',
        'both',
        'both',
        'effects',
      ]);
      expect(values[1]['durationMs'], 3000);
      expect(values[4]['durationMs'], 2000);
      expect(values[2]['name'], 'Wind');
      for (final value in values) {
        expect(value['scope'], 'map');
        expect(value['rawDataRef'], isNotEmpty);
        expect(value['profileHash'], isNotEmpty);
      }
    });

    test('STD08 picture slots and screen effects remain typed $location',
        () async {
      final event = await presentationEvent([
        const LiteralFixtureEventCommand(
            231, [7, 'Banner', 1, 0, 120, 90, 100, 100, 192, 0]),
        const LiteralFixtureEventCommand(
            232, [7, 12, 1, 0, 180, 110, 125, 80, 96, 0]),
        const LiteralFixtureEventCommand(235, [7]),
        LiteralFixtureEventCommand(224, [
          color([255, 128, 0, 192]),
          4
        ]),
        const LiteralFixtureEventCommand(225, [5, 7, 6]),
      ], mapId: location.$1, eventId: location.$2);
      expect(event.isQuarantined, isFalse);
      final values =
          event.pages.single.body.nodes.map(presentationJson).toList();
      expect(values.take(3).map((value) => value['kind']),
          everyElement('picture'));
      expect(values.take(3).map((value) => value['operation']),
          ['show', 'move', 'erase']);
      expect(values.take(3).map((value) => value['slot']), everyElement(7));
      expect(values[0]['name'], 'Banner');
      expect(values[0]['opacity'], 192);
      expect(values[1]['durationMs'], 600);
      expect(values[1]['x'], 180);
      expect(values[1]['scaleX'], 1.25);
      expect(values[3]['kind'], 'flash');
      expect(values[3]['rgba'], [255.0, 128.0, 0.0, 192.0]);
      expect(values[3]['durationMs'], 200);
      expect(values[4]['kind'], 'shake');
      expect(values[4]['power'], 5);
      expect(values[4]['speed'], 7);
      expect(values[4]['durationMs'], 300);
      for (final value in values) {
        expect(value['rawDataRef'], isNotEmpty);
        expect(value['profileHash'], isNotEmpty);
      }
    });
  }

  test('STD08 fog is preserved as a typed unsupported map capability',
      () async {
    final event = await presentationEvent([
      const LiteralFixtureEventCommand(204, [1, 'Mist', 0, 192, 0, 100, -8, 0]),
    ]);
    expect(event.isQuarantined, isFalse);
    final value = presentationJson(event.pages.single.body.nodes.single);
    expect(value['kind'], 'mapFog');
    expect(value['name'], 'Mist');
    expect(value['targetQualification'], 'sourceMapFogUnsupported');
    expect(value['rawDataRef'], isNotEmpty);
  });

  for (final command in [
    const LiteralFixtureEventCommand(
        231, [1, 'Banner', 0, 1, 1, 2, 100, 100, 255, 0]),
    const LiteralFixtureEventCommand(
        231, [1, 'Banner', 0, 0, 1, 2, 100, 100, 255, 1]),
    const LiteralFixtureEventCommand(233, [1, 4]),
    const LiteralFixtureEventCommand(234, [1, null, 2]),
    const LiteralFixtureEventCommand(242, [-1]),
    const LiteralFixtureEventCommand(247, [1]),
    const LiteralFixtureEventCommand(225, [10, 5, 5]),
  ]) {
    test('STD08 rejects unsupported or malformed literal ${command.code}',
        () async {
      final event = await presentationEvent([command]);
      expect(event.isQuarantined, isTrue);
    });
  }

  test('STD08 ambience refuses pitch without a native equivalent', () async {
    final event = await presentationEvent([
      LiteralFixtureEventCommand(245, [audio('Wind', pitch: 110)]),
    ]);
    expect(event.isQuarantined, isTrue);
  });
}
