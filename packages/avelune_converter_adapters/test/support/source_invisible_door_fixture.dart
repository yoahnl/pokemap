import 'dart:typed_data';

import '../../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'literal_tile_fixture.dart';

Future<LiteralTileFixture> sourceInvisibleDoorFixture({
  String variant = 'original',
  bool includeSound = true,
  int arrivalStep = 1,
  bool annotated = false,
  bool shortArrival = false,
  bool lockedPage = false,
  int? gateVariableId,
  int gateThreshold = 7,
  bool mismatchedArrivalThreshold = false,
  bool trailingSwitch = false,
}) {
  final animated = variant == 'animated' || variant == 'emptyAnimated';
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
    namespace:
        'invisible-routed-door-$variant-$includeSound-$arrivalStep-$annotated-$shortArrival-$lockedPage-$gateVariableId-$gateThreshold-$mismatchedArrivalThreshold-$trailingSwitch',
    scriptsBytes: syntheticInterpretationArchive,
    interpretationProfile: syntheticSourceInterpretationProfile,
    includeEventSystem: true,
    extraFiles: {
      'Data/map_connections.dat': literalFixtureMarshal([]),
      if (variant == 'animated')
        'Graphics/Characters/VisibleDoor.png': literalFixtureAtlas(),
    },
    switchNames: [null, 's:tsOff?("A")', 'Visited gate'],
    variableNames: [null, 'Badge count'],
    maps: [
      LiteralFixtureMap(
        id: 7,
        width: 3,
        height: 3,
        layers: [List.filled(9, 384), List.filled(9, 0), List.filled(9, 0)],
        events: [
          LiteralFixtureEvent(id: 3, x: 1, y: 1, pages: [
            if (lockedPage)
              LiteralFixtureEventPage(commands: [
                if (annotated)
                  const LiteralFixtureEventCommand(
                      108, ['Closed until the gate opens']),
                const LiteralFixtureEventCommand(101, ['The door is locked.']),
                const LiteralFixtureEventCommand(0, []),
              ]),
            LiteralFixtureEventPage(
              trigger: 1,
              pattern: 1,
              selfSwitch: variant == 'guards' ? 'A' : null,
              variableId: gateVariableId,
              variableThreshold: gateThreshold,
              characterName: variant == 'charset' || variant == 'animated'
                  ? 'VisibleDoor'
                  : '',
              commands: [
                if (annotated)
                  const LiteralFixtureEventCommand(108, ['Departure']),
                if (animated) ...[
                  ...route(0, [44, 15, 17, 15, 18, 15, 19, 15], indent: 0),
                  ...route(-1, [37, 4, 38], indent: 0),
                  const LiteralFixtureEventCommand(208, [0]),
                  ...route(0, [15, 18, 15, 17, 15, 16, 15], indent: 0),
                ],
                if (includeSound && !animated)
                  const LiteralFixtureEventCommand(250, [
                    LiteralFixtureObject('RPG::AudioFile', {
                      '@name': 'Exit Door',
                      '@volume': 80,
                      '@pitch': 100,
                    })
                  ]),
                LiteralFixtureEventCommand(223, [tone(-255), 6]),
                const LiteralFixtureEventCommand(106, [8]),
                if (animated) const LiteralFixtureEventCommand(208, [1]),
                const LiteralFixtureEventCommand(201, [0, 9, 1, 1, 8, 1]),
                LiteralFixtureEventCommand(223, [tone(0), 6]),
                if (trailingSwitch)
                  const LiteralFixtureEventCommand(121, [2, 2, 0]),
                const LiteralFixtureEventCommand(0, []),
              ],
            ),
            LiteralFixtureEventPage(
              trigger: 3,
              globalSwitch: 1,
              variableId: gateVariableId,
              variableThreshold: mismatchedArrivalThreshold
                  ? gateThreshold + 1
                  : gateThreshold,
              pattern: 1,
              characterName: variant == 'charset' || variant == 'animated'
                  ? 'VisibleDoor'
                  : '',
              commands: [
                if (annotated)
                  const LiteralFixtureEventCommand(108, ['Arrival']),
                const LiteralFixtureEventCommand(
                    111, [12, 'get_self.onEvent?']),
                if (annotated)
                  const LiteralFixtureEventCommand(
                      108, ['Let the player leave the doorway'],
                      indent: 1),
                if (!shortArrival) ...[
                  const LiteralFixtureEventCommand(208, [0], indent: 1),
                  ...route(
                      0,
                      [
                        if (animated) 44,
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
                ],
                ...route(-1, [arrivalStep]),
                if (!shortArrival) ...route(0, [18, 15, 17, 15, 16, 15]),
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
