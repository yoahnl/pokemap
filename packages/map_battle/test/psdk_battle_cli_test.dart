import 'dart:convert';

import 'package:map_battle/src/psdk/cli/psdk_battle_cli.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK battle CLI', () {
    test('prints a JSON smoke result for a deterministic battle', () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>['--format', 'json']);

      expect(exitCode, 0);
      expect(lines, hasLength(1));

      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'victory');
      expect(payload['turns'], 1);
      expect(payload['opponentHp'], 0);
      expect(payload['events'], isA<List<dynamic>>());
      expect(
        (payload['events'] as List<dynamic>).cast<Map<String, dynamic>>().map(
              (event) => event['kind'],
            ),
        containsAll(<String>['move_declared', 'damage', 'battle_ended']),
      );
    });

    test('rejects an unknown argument with a non-zero exit code', () async {
      final errors = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: (_) {},
        stderr: errors.add,
      ).run(const <String>['--unknown']);

      expect(exitCode, 64);
      expect(errors.join('\n'), contains('Unknown argument'));
    });

    test('prints an immunity scenario for behavior-focused subagents',
        () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'immunity',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');
      expect(payload['turns'], 1);
      expect(payload['opponentHp'], 100);

      final kinds = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((event) => event['kind']);
      expect(kinds, contains('move_immune'));
      expect(kinds, isNot(contains('animation_cue')));
      expect(kinds, isNot(contains('damage')));
    });

    test('prints a miss scenario without animation or damage', () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'miss',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');
      expect(payload['turns'], 1);

      final kinds = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((event) => event['kind']);
      expect(kinds, contains('miss'));
      expect(kinds, isNot(contains('animation_cue')));
      expect(kinds, isNot(contains('damage')));
    });

    test('prints a secondary effect scenario with status and stat stage',
        () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'secondary_effect',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');
      expect(payload['opponentHp'], lessThan(100));

      final kinds = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((event) => event['kind'])
          .toList(growable: false);
      expect(
        kinds,
        containsAllInOrder(<String>[
          'damage',
          'status',
          'stat_stage_change',
        ]),
      );
    });

    test('prints a zero PP scenario as a move failure', () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'pp_empty',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');

      final playerEvents = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((event) => event['moveId'] == 'empty_ember')
          .toList(growable: false);
      expect(playerEvents, hasLength(1));
      expect(playerEvents.single['kind'], 'move_failed');
      expect(playerEvents.single['reason'], 'pp');
    });

    test('prints a prevented move scenario before PP and declaration',
        () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'prevented',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');

      final playerEvents = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((event) => event['moveId'] == 'blocked_tackle')
          .toList(growable: false);
      expect(playerEvents, hasLength(1));
      expect(playerEvents.single['kind'], 'move_failed');
      expect(playerEvents.single['reason'], 'unusable_by_user');

      final kinds = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((event) => event['moveId'] == 'blocked_tackle')
          .map((event) => event['kind']);
      expect(kinds, isNot(contains('move_pp_spent')));
      expect(kinds, isNot(contains('move_declared')));
      expect(kinds, isNot(contains('animation_cue')));
      expect(kinds, isNot(contains('damage')));
    });

    test('prints a Protect scenario that blocks an incoming move', () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'protect',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');
      expect(payload['playerHp'], 100);

      final opponentEvents = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((event) => event['moveId'] == 'opponent_tackle')
          .toList(growable: false);
      expect(opponentEvents.map((event) => event['kind']), <String>[
        'move_pp_spent',
        'move_declared',
        'move_failed',
      ]);
      expect(opponentEvents.last['reason'], 'protected');
    });

    test('prints a fixed-damage scenario for PSDK direct HP moves', () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'fixed_damage',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');
      expect(payload['opponentHp'], 60);

      final damageEvents = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((event) => event['moveId'] == 'dragon_rage')
          .where((event) => event['kind'] == 'damage')
          .toList(growable: false);
      expect(damageEvents, hasLength(1));
      expect(damageEvents.single['damage'], 40);
    });

    test('prints a multi-hit scenario with one damage event per hit', () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'multi_hit',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');

      final damageEvents = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((event) => event['moveId'] == 'double_slap')
          .where((event) => event['kind'] == 'damage')
          .toList(growable: false);
      expect(damageEvents, hasLength(5));
    });

    test('prints an advanced multi-hit scenario for PSDK hit formulas',
        () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'advanced_multi_hit',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');
      expect(payload['opponentHp'], 85);

      final damageEvents = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((event) => event['moveId'] == 'triple_kick')
          .where((event) => event['kind'] == 'damage')
          .toList(growable: false);
      expect(
        damageEvents.map((event) => event['damage']),
        <int>[3, 5, 7],
      );
    });

    test('prints a basic specialization scenario for PSDK damage rules',
        () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'basic_specialization',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');
      expect(payload['playerHp'], 77);
      expect(payload['opponentHp'], 1);

      final events = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList(growable: false);
      final damageEvents = events
          .where((event) => event['moveId'] == 'false_swipe')
          .where((event) => event['kind'] == 'damage')
          .toList(growable: false);
      expect(damageEvents, hasLength(1));
      expect(damageEvents.single['damage'], 29);
      expect(damageEvents.single['remainingHp'], 1);

      final fullCritDamageEvents = events
          .where((event) => event['moveId'] == 'full_crit_slash')
          .where((event) => event['kind'] == 'damage')
          .toList(growable: false);
      expect(fullCritDamageEvents, hasLength(1));
      expect(fullCritDamageEvents.single['damage'], 23);
    });

    test('prints a direct HP scenario for Endeavor and no-effect moves',
        () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'direct_hp',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');
      expect(payload['playerHp'], 40);
      expect(payload['opponentHp'], 40);

      final events = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList(growable: false);
      final endeavorDamageEvents = events
          .where((event) => event['moveId'] == 'endeavor')
          .where((event) => event['kind'] == 'damage')
          .toList(growable: false);
      expect(endeavorDamageEvents, hasLength(1));
      expect(endeavorDamageEvents.single['damage'], 60);
      expect(endeavorDamageEvents.single['remainingHp'], 40);

      final splashKinds = events
          .where((event) => event['moveId'] == 'splash')
          .map((event) => event['kind'])
          .toList(growable: false);
      expect(
          splashKinds,
          containsAll(<String>[
            'move_pp_spent',
            'move_declared',
            'animation_cue',
          ]));
      expect(splashKinds, isNot(contains('damage')));
    });

    test('prints a healing scenario with weather-adjusted recovery', () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'healing',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');
      expect(payload['playerHp'], 76);
      expect(payload['weather'], 'sunny');

      final healEvents = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((event) => event['moveId'] == 'moonlight')
          .where((event) => event['kind'] == 'heal')
          .toList(growable: false);
      expect(healEvents, hasLength(1));
      expect(healEvents.single['amount'], 66);
      expect(healEvents.single['remainingHp'], 76);
    });

    test('prints a recoil scenario with target and user damage', () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'recoil',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');
      expect(payload['playerHp'], 98);
      expect(payload['opponentHp'], 92);

      final damageEvents = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((event) => event['moveId'] == 'take_down')
          .where((event) => event['kind'] == 'damage')
          .toList(growable: false);
      expect(damageEvents, hasLength(2));
      expect(damageEvents.first['damage'], 8);
      expect(damageEvents.last['damage'], 2);
      expect(damageEvents.last['target'], <String, Object?>{
        'bank': 0,
        'position': 0,
      });
    });

    test('prints a Mind Blown scenario with target damage and self crash',
        () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'mind_blown',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');
      expect(payload['playerHp'], 50);
      expect(payload['opponentHp'], 88);

      final damageEvents = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((event) => event['moveId'] == 'mind_blown')
          .where((event) => event['kind'] == 'damage')
          .toList(growable: false);
      expect(damageEvents, hasLength(2));
      expect(damageEvents.first['target'], <String, Object?>{
        'bank': 1,
        'position': 0,
      });
      expect(damageEvents.first['damage'], 12);
      expect(damageEvents.last['target'], <String, Object?>{
        'bank': 0,
        'position': 0,
      });
      expect(damageEvents.last['damage'], 50);
    });

    test('prints an Explosion scenario with target damage and user self-KO',
        () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'explosion',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'defeat');
      expect(payload['turns'], 1);
      expect(payload['playerHp'], 0);
      expect(payload['opponentHp'], 92);

      final events = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList(growable: false);
      final damageEvents = events
          .where((event) => event['moveId'] == 'explosion')
          .where((event) => event['kind'] == 'damage')
          .toList(growable: false);
      expect(damageEvents, hasLength(2));
      expect(damageEvents.first['target'], <String, Object?>{
        'bank': 1,
        'position': 0,
      });
      expect(damageEvents.first['damage'], 8);
      expect(damageEvents.last['target'], <String, Object?>{
        'bank': 0,
        'position': 0,
      });
      expect(damageEvents.last['damage'], 100);
      expect(events.last['kind'], 'battle_ended');
      expect(events.last['outcome'], 'defeat');
    });

    test('prints a terrain-boosting scenario with seeded Electric Terrain',
        () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'terrain_boosting',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');
      expect(payload['terrain'], 'electric_terrain');
      expect(payload['weather'], 'none');
      expect(payload['opponentHp'], 78);

      final damageEvents = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((event) => event['moveId'] == 'psyblade')
          .where((event) => event['kind'] == 'damage')
          .toList(growable: false);
      expect(damageEvents, hasLength(1));
    });

    test('prints a variable-power scenario for PSDK custom formulas', () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'variable_power',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');
      expect(payload['opponentHp'], 26);

      final damageEvents = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((event) => event['moveId'] == 'brine')
          .where((event) => event['kind'] == 'damage')
          .toList(growable: false);
      expect(damageEvents, hasLength(1));
      expect(damageEvents.single['damage'], 24);
    });

    test('prints a custom-stat scenario for PSDK stat-source formulas',
        () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'custom_stat',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');
      expect(payload['opponentHp'], 71);

      final damageEvents = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((event) => event['moveId'] == 'body_press')
          .where((event) => event['kind'] == 'damage')
          .toList(growable: false);
      expect(damageEvents, hasLength(1));
      expect(damageEvents.single['damage'], 29);
    });

    test('prints a weight-power scenario for PSDK weight formulas', () async {
      final lines = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: lines.add,
        stderr: fail,
      ).run(const <String>[
        '--scenario',
        'weight_power',
        '--format',
        'json',
      ]);

      expect(exitCode, 0);
      final payload = jsonDecode(lines.single) as Map<String, dynamic>;
      expect(payload['outcome'], 'ongoing');
      expect(payload['playerHp'], 78);
      expect(payload['opponentHp'], 81);

      final events = (payload['events'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList(growable: false);
      final lowKickDamageEvents = events
          .where((event) => event['moveId'] == 'low_kick')
          .where((event) => event['kind'] == 'damage')
          .toList(growable: false);
      final heavySlamDamageEvents = events
          .where((event) => event['moveId'] == 'heavy_slam')
          .where((event) => event['kind'] == 'damage')
          .toList(growable: false);
      expect(lowKickDamageEvents, hasLength(1));
      expect(lowKickDamageEvents.single['damage'], 19);
      expect(heavySlamDamageEvents, hasLength(1));
      expect(heavySlamDamageEvents.single['damage'], 22);
    });

    test('rejects an unknown scenario with a non-zero exit code', () async {
      final errors = <String>[];
      final exitCode = await PsdkBattleCli(
        stdout: (_) {},
        stderr: errors.add,
      ).run(const <String>['--scenario', 'wat']);

      expect(exitCode, 64);
      expect(errors.join('\n'), contains('Unknown --scenario value'));
    });
  });
}
