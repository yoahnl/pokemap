import 'dart:convert';

import 'literal_tile_fixture.dart';

typedef NativeTrainerFixtureRoster = ({String type, String name, int version});

Map<String, List<int>> nativeTrainerFixtureFiles(
        List<NativeTrainerFixtureRoster> rosters,
        {List<({String species, int level})> team = const [
          (species: 'RATTATA', level: 16)
        ]}) =>
    {
      'PBS/trainers.txt': utf8.encode(rosters
          .map((row) =>
              '[${row.type},${row.name},${row.version}]\nLoseText = Good game!\n${team.map((member) => 'Pokemon = ${member.species},${member.level}\n').join()}')
          .join()),
      'Data/trainers.dat': literalFixtureMarshal({
        for (final row in rosters)
          [LiteralFixtureSymbol(row.type), row.name, row.version]:
              LiteralFixtureObject('GameData::Trainer', {
            '@id': [LiteralFixtureSymbol(row.type), row.name, row.version],
            '@trainer_type': LiteralFixtureSymbol(row.type),
            '@real_name': row.name,
            '@version': row.version,
            '@items': <Object?>[],
            '@real_lose_text': 'Good game!',
            '@pokemon': [
              for (final member in team)
                {
                  const LiteralFixtureSymbol('species'):
                      LiteralFixtureSymbol(member.species),
                  const LiteralFixtureSymbol('level'): member.level
                }
            ],
            '@pbs_file_suffix': '',
          }),
      }),
    };

LiteralFixtureEvent nativeTrainerFixtureEvent(
    NativeTrainerFixtureRoster roster, int id) {
  const turn = LiteralFixtureObject('RPG::MoveCommand', {
    '@code': 25,
    '@parameters': <Object?>[],
  });
  const end = LiteralFixtureObject('RPG::MoveCommand', {
    '@code': 0,
    '@parameters': <Object?>[],
  });
  return LiteralFixtureEvent(
      id: id,
      x: id,
      y: 1,
      name: 'Original Trainer(2)',
      pages: [
        LiteralFixtureEventPage(
            characterName: 'OriginalTrainer',
            trigger: 2,
            commands: [
              LiteralFixtureEventCommand(
                  355, ['pbTrainerIntro(:${roster.type})']),
              const LiteralFixtureEventCommand(
                  355, ['pbNoticePlayer(get_self)']),
              const LiteralFixtureEventCommand(101, ['Ready?']),
              const LiteralFixtureEventCommand(108, ['EndSpeech: Good game!']),
              LiteralFixtureEventCommand(111, [
                12,
                'TrainerBattle.start(:${roster.type}, "${roster.name}", ${roster.version})'
              ]),
              const LiteralFixtureEventCommand(123, ['A', 0], indent: 1),
              const LiteralFixtureEventCommand(0, [], indent: 1),
              const LiteralFixtureEventCommand(412, []),
              const LiteralFixtureEventCommand(355, ['pbTrainerEnd']),
              const LiteralFixtureEventCommand(0, []),
            ]),
        const LiteralFixtureEventPage(
            characterName: 'OriginalTrainer',
            selfSwitch: 'A',
            commands: [
              LiteralFixtureEventCommand(101, ['See you!']),
              LiteralFixtureEventCommand(209, [
                0,
                LiteralFixtureObject('RPG::MoveRoute', {
                  '@repeat': false,
                  '@skippable': false,
                  '@list': [turn, end],
                })
              ]),
              LiteralFixtureEventCommand(509, [turn]),
              LiteralFixtureEventCommand(0, []),
            ]),
      ]);
}
