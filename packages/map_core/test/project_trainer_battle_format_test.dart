import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final shared =
      jsonDecode(
            File(
              '../map_authoring/test/fixtures/trainer_battle_format.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final singles = Map<String, dynamic>.from(shared['singles'] as Map);
  final doubles = Map<String, dynamic>.from(shared['doubles'] as Map);
  final codes = shared['domainCodes'] as Map;

  test('omitted format defaults to explicit singles with two team members', () {
    final value = {...doubles}..remove('battleFormat');
    final trainer = ProjectTrainerEntry.fromJson(value);

    expect(trainer.toJson()['battleFormat'], 'singles');
    expect(trainer.team, hasLength(2));
    expect(trainer.battleDifficulty, 7);
  });

  test('six singles members remain one active format with reserves', () {
    final trainer = ProjectTrainerEntry.fromJson(singles);

    ProjectValidator.validate(_project(trainer, standard: false));

    expect(trainer.toJson()['battleFormat'], 'singles');
    expect(trainer.team, hasLength(6));
    expect(ProjectTrainerEntry.fromJson(trainer.toJson()), trainer);
  });

  test(
    'explicit doubles survives serialization without changing authored stats',
    () {
      final trainer = ProjectTrainerEntry.fromJson(doubles);

      ProjectValidator.validate(_project(trainer));

      expect(trainer.toJson()['battleFormat'], 'doubles');
      expect(trainer.team, hasLength(2));
      expect(trainer.battleDifficulty, 7);
      expect(trainer.team.first.natureId, 'adamant');
      expect(trainer.team.first.ivs!.attack, 30);
      expect(ProjectTrainerEntry.fromJson(trainer.toJson()), trainer);
    },
  );

  test('six authored doubles members retain four available reserves', () {
    final trainer = ProjectTrainerEntry.fromJson({
      ...singles,
      'battleFormat': 'doubles',
    });

    ProjectValidator.validate(_project(trainer));

    expect(trainer.battleFormat, BattleFormat.doubles);
    expect(trainer.team, hasLength(6));
    expect(ProjectTrainerEntry.fromJson(trainer.toJson()).team, trainer.team);
  });

  for (final invalid in shared['invalidFormats'] as List) {
    test('rejects explicit invalid format ${jsonEncode(invalid)}', () {
      expect(
        () =>
            ProjectTrainerEntry.fromJson({...doubles, 'battleFormat': invalid}),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('battleFormat'),
          ),
        ),
      );
    });
  }

  for (final size in (shared['invalidDoubleTeamSizes'] as List).cast<int>()) {
    test('rejects doubles with $size authored members', () {
      final team = (doubles['team'] as List).cast<Map>();
      final trainer = ProjectTrainerEntry.fromJson({
        ...doubles,
        'team': [for (var index = 0; index < size; index++) team[index % 2]],
      });

      expect(
        () => ProjectValidator.validate(_project(trainer)),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.code,
            'code',
            codes['invalidDoubleTeamSize'],
          ),
        ),
      );
    });
  }

  test('refuses a double trainer profile assigned to a static encounter', () {
    final trainer = ProjectTrainerEntry.fromJson(
      Map<String, dynamic>.from(shared['staticTrainer'] as Map),
    );

    expect(
      () => ProjectValidator.validate(_project(trainer)),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.code,
          'code',
          codes['staticDoublesUnsupported'],
        ),
      ),
    );
  });

  test('refuses doubles while the project keeps its default beta ruleset', () {
    final trainer = ProjectTrainerEntry.fromJson(doubles);

    expect(
      () => ProjectValidator.validate(_project(trainer, standard: false)),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.code,
          'code',
          codes['featureDisabled'],
        ),
      ),
    );
  });

  test('scene trainer references carry no separate battle format override', () {
    final payload = SceneBattlePayload.fromJson(
      Map<String, dynamic>.from(shared['trainerBattlePayload'] as Map),
    );

    expect(payload.trainerId, singles['id']);
    expect(payload.toJson().containsKey('battleFormat'), isFalse);
  });
}

ProjectManifest _project(ProjectTrainerEntry trainer, {bool standard = true}) {
  final shared =
      jsonDecode(
            File(
              '../map_authoring/test/fixtures/trainer_battle_format.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  return ProjectManifest(
    name: 'Battle format validation',
    maps: [],
    tilesets: [],
    trainers: [trainer],
    pokemon: ProjectPokemonConfig(
      ruleset: PokemonRulesetProfile.fromJson(
        Map<String, dynamic>.from(
          shared[standard ? 'standardProfile' : 'betaProfile'] as Map,
        ),
      ),
    ),
  );
}
