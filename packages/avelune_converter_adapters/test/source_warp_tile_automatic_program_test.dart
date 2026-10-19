import 'package:avelune_converter_adapters/src/source_warp_tile_native_program.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

void main() {
  for (final defect in [
    'none',
    'script',
    'guard',
    'missingArrival',
    'activationGuard',
    'extraPage',
    'graphic',
    'autonomous',
    'earlyPosition',
    'playerMovement',
    'ghostUnrestored',
    'foreignPositionVariable',
    'scriptRoute'
  ]) {
    test('discovers closed warp family without declarations: $defect',
        () async {
      LiteralFixtureEvent tile(int id, int x, int destination) =>
          LiteralFixtureEvent(id: id, x: x, y: 1, pages: [
            LiteralFixtureEventPage(
                selfSwitch: 'A',
                trigger: 1,
                through: true,
                characterName:
                    defect == 'graphic' && id == 1 ? 'VisibleNpc' : '',
                moveType: defect == 'autonomous' && id == 1 ? 1 : 0,
                commands: [
                  if (defect == 'earlyPosition' && id == 1)
                    const LiteralFixtureEventCommand(202, [0, 1, 2, 3, 0]),
                  const LiteralFixtureEventCommand(122, [1, 1, 0, 7, 0]),
                  const LiteralFixtureEventCommand(122, [2, 2, 0, 6, 0, 0]),
                  const LiteralFixtureEventCommand(122, [3, 3, 0, 6, 0, 1]),
                  if (defect == 'foreignPositionVariable' && id == 1)
                    const LiteralFixtureEventCommand(202, [0, 1, 2, 4, 0]),
                  if (const ['playerMovement', 'ghostUnrestored']
                          .contains(defect) &&
                      id == 1) ...[
                    LiteralFixtureEventCommand(209, [
                      defect == 'playerMovement' ? -1 : 0,
                      const LiteralFixtureObject('RPG::MoveRoute', {
                        '@repeat': false,
                        '@skippable': false,
                        '@list': [
                          LiteralFixtureObject('RPG::MoveCommand',
                              {'@code': 1, '@parameters': <Object?>[]}),
                          LiteralFixtureObject('RPG::MoveCommand',
                              {'@code': 0, '@parameters': <Object?>[]}),
                        ]
                      })
                    ]),
                    const LiteralFixtureEventCommand(509, [
                      LiteralFixtureObject('RPG::MoveCommand',
                          {'@code': 1, '@parameters': <Object?>[]})
                    ]),
                  ],
                  if (defect == 'script' && id == 1)
                    const LiteralFixtureEventCommand(
                        355, ['customSideEffect()']),
                  if (defect == 'scriptRoute' && id == 1) ...const [
                    LiteralFixtureEventCommand(209, [
                      0,
                      LiteralFixtureObject('RPG::MoveRoute', {
                        '@repeat': false,
                        '@skippable': false,
                        '@list': [
                          LiteralFixtureObject('RPG::MoveCommand', {
                            '@code': 45,
                            '@parameters': ['customSideEffect()']
                          }),
                          LiteralFixtureObject('RPG::MoveCommand',
                              {'@code': 0, '@parameters': <Object?>[]}),
                        ]
                      })
                    ]),
                    LiteralFixtureEventCommand(509, [
                      LiteralFixtureObject('RPG::MoveCommand', {
                        '@code': 45,
                        '@parameters': ['customSideEffect()']
                      })
                    ]),
                  ],
                  const LiteralFixtureEventCommand(250, [
                    LiteralFixtureObject('RPG::AudioFile',
                        {'@name': 'departure', '@volume': 90, '@pitch': 100})
                  ]),
                  LiteralFixtureEventCommand(201, [
                    0,
                    1,
                    defect == 'missingArrival' && id == 1 ? 9 : destination,
                    1,
                    0,
                    1
                  ]),
                  const LiteralFixtureEventCommand(0, []),
                ]),
            LiteralFixtureEventPage(
                globalSwitch: defect == 'guard' && id == 1 ? 2 : 1,
                trigger: 3,
                through: true,
                commands: const [
                  LiteralFixtureEventCommand(111, [12, 'get_self.onEvent?']),
                  LiteralFixtureEventCommand(122, [1, 1, 0, 7, 0], indent: 1),
                  LiteralFixtureEventCommand(122, [2, 2, 0, 6, 0, 0],
                      indent: 1),
                  LiteralFixtureEventCommand(122, [3, 3, 0, 6, 0, 1],
                      indent: 1),
                  LiteralFixtureEventCommand(122, [3, 3, 2, 0, 6], indent: 1),
                  LiteralFixtureEventCommand(
                      250,
                      [
                        LiteralFixtureObject('RPG::AudioFile',
                            {'@name': 'arrival', '@volume': 90, '@pitch': 100})
                      ],
                      indent: 1),
                  LiteralFixtureEventCommand(412, []),
                  LiteralFixtureEventCommand(123, ['A', 1]),
                  LiteralFixtureEventCommand(355, ['setTempSwitchOn("A")']),
                  LiteralFixtureEventCommand(0, []),
                ]),
            if (defect == 'extraPage' && id == 1)
              const LiteralFixtureEventPage(commands: []),
          ]);
      final fixture = await LiteralTileFixture.create(
          interpretationProfile: syntheticSourceInterpretationProfile,
          scriptsBytes: syntheticInterpretationArchive,
          includeEventSystem: true,
          switchNames: const [
            null,
            's:tsOff?("A")',
            'Ordinary switch'
          ],
          variableNames: const [
            null,
            'Map',
            'X',
            'Y'
          ],
          maps: [
            LiteralFixtureMap(id: 1, width: 12, height: 3, layers: [
              List.filled(36, 384),
              List.filled(36, 0),
              List.filled(36, 0)
            ], events: [
              tile(1, 2, 7),
              tile(2, 7, 2),
              LiteralFixtureEvent(id: 3, x: 2, y: 0, pages: [
                LiteralFixtureEventPage(
                    trigger: 1,
                    globalSwitch: defect == 'activationGuard' ? 2 : null,
                    through: true,
                    commands: const [
                      LiteralFixtureEventCommand(
                          355, ['pbSetSelfSwitch(1,"A",true)']),
                      LiteralFixtureEventCommand(0, [])
                    ]),
              ])
            ])
          ]);
      final source = await const RmxpSourceNormalizer().normalize(
          snapshot: fixture.snapshot,
          files: fixture.files,
          interpretationProfile: syntheticSourceInterpretationProfile,
          includeEventSystem: true);
      final analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source))
          .analyze();
      final result =
          sourceWarpTileNativePrograms(source: source, analysis: analysis);
      if (defect == 'none') {
        expect(result.programs, hasLength(3), reason: '${result.refusals}');
        expect(result.refusals, isEmpty);
        expect(
            result.programs.values.every((program) =>
                program.declaredProgramBinding.automaticallyDiscovered),
            isTrue);
        final activation = result.programs[source.eventIdentity(1, 3)]!;
        expect(activation.target!.sourceEventId, 1);
        expect(activation.repairsTarget, isFalse);
        expect(activation.selfSwitchLetter, 'A');
        expect(result.programs[source.eventIdentity(1, 1)]!.warp!.x, 7);
      } else if (defect == 'activationGuard') {
        expect(result.programs, hasLength(2));
        expect(
            result.programs.containsKey(source.eventIdentity(1, 3)), isFalse);
      } else {
        expect(result.programs, isEmpty);
      }
    });
  }
}
