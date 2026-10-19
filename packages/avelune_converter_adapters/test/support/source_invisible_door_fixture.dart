import 'dart:typed_data';

import '../../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'literal_tile_fixture.dart';

Future<LiteralTileFixture> sourceInvisibleDoorFixture({
  String variant = 'original',
  bool includeSound = true,
}) {
  LiteralFixtureObject step(int code) =>
      LiteralFixtureObject('RPG::MoveCommand', {
        '@code': code,
        '@parameters': code == 15
            ? [2]
            : code == 44
                ? [
                    const LiteralFixtureObject('RPG::AudioFile',
                        {'@name': 'Exit Door', '@volume': 80, '@pitch': 100})
                  ]
                : <Object?>[],
      });
  List<LiteralFixtureEventCommand> route(int actor, List<int> codes,
          {bool first = false, int indent = 1}) =>
      [
        LiteralFixtureEventCommand(
            209,
            [
              first && variant == 'actor' ? 1 : actor,
              LiteralFixtureObject('RPG::MoveRoute', {
                '@repeat': first && variant == 'repeat',
                '@skippable': !(first && variant == 'skippable'),
                '@list': [...codes.map(step), step(0)],
              })
            ],
            indent: indent),
        for (final code in codes)
          LiteralFixtureEventCommand(509, [step(code)], indent: indent),
        if (!(first && variant == 'barrier'))
          LiteralFixtureEventCommand(210, [], indent: indent),
      ];
  LiteralFixtureUserDefined tone(double value) {
    final bytes = ByteData(32);
    for (var axis = 0; axis < 3; axis++) {
      bytes.setFloat64(axis * 8, value, Endian.little);
    }
    return LiteralFixtureUserDefined('Tone', bytes.buffer.asUint8List());
  }

  return LiteralTileFixture.create(
    namespace: 'invisible-routed-door-$variant-$includeSound',
    scriptsBytes: syntheticInterpretationArchive,
    interpretationProfile: syntheticSourceInterpretationProfile,
    includeEventSystem: true,
    extraFiles: {'Data/map_connections.dat': literalFixtureMarshal([])},
    switchNames: [null, 's:tsOff?("A")'],
    maps: [
      LiteralFixtureMap(
        id: 7,
        width: 3,
        height: 3,
        layers: [List.filled(9, 384), List.filled(9, 0), List.filled(9, 0)],
        events: [
          LiteralFixtureEvent(id: 3, x: 1, y: 1, pages: [
            LiteralFixtureEventPage(
              trigger: 1,
              pattern: 1,
              selfSwitch: variant == 'guards' ? 'A' : null,
              characterName: variant == 'charset' ? 'VisibleDoor' : '',
              commands: [
                if (variant == 'emptyAnimated') ...[
                  ...route(0, [44, 15, 17, 15, 18, 15, 19, 15], indent: 0),
                  ...route(-1, [37, 4, 38], indent: 0),
                  const LiteralFixtureEventCommand(208, [0]),
                  ...route(0, [15, 18, 15, 17, 15, 16, 15], indent: 0),
                ],
                if (includeSound && variant != 'emptyAnimated')
                  const LiteralFixtureEventCommand(250, [
                    LiteralFixtureObject('RPG::AudioFile', {
                      '@name': 'Exit Door',
                      '@volume': 80,
                      '@pitch': 100,
                    })
                  ]),
                LiteralFixtureEventCommand(223, [tone(-255), 6]),
                const LiteralFixtureEventCommand(106, [8]),
                if (variant == 'emptyAnimated')
                  const LiteralFixtureEventCommand(208, [1]),
                const LiteralFixtureEventCommand(201, [0, 9, 1, 1, 8, 1]),
                LiteralFixtureEventCommand(223, [tone(0), 6]),
                const LiteralFixtureEventCommand(0, []),
              ],
            ),
            LiteralFixtureEventPage(
              trigger: 3,
              globalSwitch: 1,
              pattern: 1,
              characterName: variant == 'charset' ? 'VisibleDoor' : '',
              commands: [
                const LiteralFixtureEventCommand(
                    111, [12, 'get_self.onEvent?']),
                const LiteralFixtureEventCommand(208, [0], indent: 1),
                ...route(
                    0,
                    [
                      if (variant == 'emptyAnimated') 44,
                      15,
                      17,
                      15,
                      18,
                      15,
                      variant == 'route' ? 16 : 19,
                      15
                    ],
                    first: true),
                const LiteralFixtureEventCommand(208, [1], indent: 1),
                ...route(-1, [1]),
                ...route(0, [18, 15, 17, 15, 16, 15]),
                const LiteralFixtureEventCommand(412, []),
                const LiteralFixtureEventCommand(355, ['setTempSwitchOn("A")']),
                const LiteralFixtureEventCommand(0, []),
              ],
            ),
          ]),
        ],
      ),
      LiteralFixtureMap(
          id: 9,
          width: 3,
          height: 3,
          layers: [List.filled(9, 384), List.filled(9, 0), List.filled(9, 0)]),
    ],
  );
}
