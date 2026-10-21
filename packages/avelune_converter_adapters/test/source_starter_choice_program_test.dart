import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

Future<SourceStarterChoiceProgram?> _read([String defect = '']) async {
  final list = <LiteralFixtureEventCommand>[];
  void c(int code, List<Object?> parameters, [int indent = 0]) =>
      list.add(LiteralFixtureEventCommand(code, parameters, indent: indent));
  void text(String message, [int indent = 0]) => c(101, [message], indent);
  void route(int target, List<(int, List<Object?>)> steps, [int indent = 0]) {
    LiteralFixtureObject step((int, List<Object?>) value) =>
        LiteralFixtureObject(
            'RPG::MoveCommand', {'@code': value.$1, '@parameters': value.$2});
    c(
        209,
        [
          target,
          LiteralFixtureObject('RPG::MoveRoute', {
            '@repeat': false,
            '@skippable': false,
            '@list': [for (final value in steps) step(value), step((0, []))]
          })
        ],
        indent);
    for (final value in steps) {
      c(509, [step(value)], indent);
    }
  }

  route(1, [(18, [])]);
  c(355, ['Pokemon.play_cry(:TINYLEAF)']);
  for (final picture in [(1, 'Frame'), (2, 'Leaf')]) {
    c(231, [picture.$1, picture.$2, 1, 0, 256, 160, 100, 100, 255, 0]);
  }
  c(355, [
    defect == 'seenMismatch'
        ? r'$player.pokedex.set_seen(:OTHER)'
        : r'$player.pokedex.set_seen(:TINYLEAF)'
  ]);
  text('Would you like this companion?');
  c(102, [
    ['YES', 'NO'],
    defect == 'cancel' ? 1 : 2
  ]);
  c(402, [0, 'YES']);
  c(235, [1], 1);
  c(235, [2], 1);
  route(
      0,
      [
        (42, [0])
      ],
      1);
  text('Take good care of it.', 1);
  c(
      355,
      [
        defect == 'dynamicGift'
            ? 'pbAddPokemon(pbGet(2),5)'
            : 'pbAddPokemon(:TINYLEAF,5)'
      ],
      1);
  route(4, [(1, []), (3, []), (4, [])], 1);
  c(210, [], 1);
  text('I will take another companion.', 1);
  route(
      3,
      [
        (42, [0])
      ],
      1);
  c(
      249,
      [
        const LiteralFixtureObject(
            'RPG::AudioFile', {'@name': 'Gift', '@volume': 100, '@pitch': 100})
      ],
      1);
  text('The rival received a companion.', 1);
  c(355, ['pbSetSelfSwitch(3,"A",true)'], 1);
  for (final target in [4, 5, 6]) {
    c(355, ['pbSetSelfSwitch($target,"A",true)'], 1);
    c(
        202,
        [
          target,
          0,
          switch (defect) {
            'dynamicPosition' => 'pbGet(1)',
            'negativePosition' => -1,
            'oversizedPosition' => 65536,
            _ => 5,
          },
          4,
          0
        ],
        1);
  }
  c(122, [2, 2, 0, 0, 1], 1);
  c(121, [2, 2, 1], 1);
  c(116, [], 1);
  c(123, [defect == 'selfMismatch' ? 'B' : 'A', 0], 1);
  c(355, ['FollowingPkmn.start_following(30)'], 1);
  c(0, [], 1);
  c(402, [1, 'NO']);
  c(235, [1], 1);
  c(235, [defect == 'pictureCleanup' ? 3 : 2], 1);
  c(0, [], 1);
  c(404, []);
  c(0, []);
  if (defect == 'unknownSuffix') {
    list.insert(list.length - 1,
        const LiteralFixtureEventCommand(355, ['customUnknown()']));
  }
  if (defect == 'missingRouteMirror') {
    list.removeAt(list.indexWhere((value) => value.code == 509));
  }
  final fixture = await LiteralTileFixture.create(
      namespace: 'closed-starter-$defect',
      includeEventSystem: true,
      scriptsBytes:
          defect == 'archive' ? [4, 8, 48] : syntheticInterpretationArchive,
      interpretationProfile: syntheticSourceInterpretationProfile,
      switchNames: const [
        null,
        'Gate1',
        'Offer'
      ],
      variableNames: const [
        null,
        'Unused',
        'Choice'
      ],
      maps: [
        LiteralFixtureMap(id: 1, width: 20, height: 20, layers: [
          List.filled(400, 384),
          List.filled(400, 0),
          List.filled(400, 0)
        ], events: [
          LiteralFixtureEvent(id: 2, x: 10, y: 6, pages: [
            const LiteralFixtureEventPage(characterName: 'Ball', commands: [
              LiteralFixtureEventCommand(101, ['Some companions.']),
              LiteralFixtureEventCommand(0, [])
            ]),
            LiteralFixtureEventPage(
                characterName: 'Ball', globalSwitch: 2, commands: list),
            LiteralFixtureEventPage(
                characterName: 'Ball',
                variableId: 2,
                variableThreshold: 1,
                commands: [
                  LiteralFixtureEventCommand(
                      111, [1, 2, 0, defect == 'remainingChoice' ? 1 : 2, 0]),
                  const LiteralFixtureEventCommand(
                      101, ['The remaining companion.'],
                      indent: 1),
                  const LiteralFixtureEventCommand(0, [], indent: 1),
                  const LiteralFixtureEventCommand(412, []),
                  const LiteralFixtureEventCommand(0, []),
                ]),
            const LiteralFixtureEventPage(
                selfSwitch: 'A', commands: [LiteralFixtureEventCommand(0, [])]),
          ])
        ])
      ]);
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: fixture.snapshot,
      files: fixture.files,
      selectedMapIds: {1},
      includeEventSystem: true,
      interpretationProfile: syntheticSourceInterpretationProfile);
  return SourceStarterChoiceProgram.read(
      source: source,
      profile: SourceEventProfile.forProject(source),
      sourceMapId: 1,
      event: source.maps.single.map.events.single);
}

void main() {
  test(
      'closed starter grammar derives typed values without map, event or species whitelists',
      () async {
    final program = await _read();
    expect(program, isNotNull);
    expect(program!.sourceMapId, 1);
    expect(program.sourceEventId, 2);
    expect(program.sourceSpeciesSymbol, 'TINYLEAF');
    expect(program.level, 5);
    expect(program.choiceVariableId, 2);
    expect(program.choiceValue, 1);
    expect(program.remainingChoiceValue, 2);
  });
  test('changed script archive is rejected before starter interpretation',
      () async {
    await expectLater(
        _read('archive'),
        throwsA(isA<ContractError>().having(
            (e) => e.code, 'code', 'interpretation_profile.source_mismatch')));
  });
  for (final defect in [
    'seenMismatch',
    'cancel',
    'dynamicGift',
    'dynamicPosition',
    'negativePosition',
    'oversizedPosition',
    'selfMismatch',
    'pictureCleanup',
    'unknownSuffix',
    'missingRouteMirror',
    'remainingChoice'
  ]) {
    test('closed starter grammar refuses $defect',
        () async => expect(await _read(defect), isNull));
  }
}
