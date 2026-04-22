import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:PokeMap_Loader/src/runtime_launch_save.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('loadRuntimeHostLaunchSaveData', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('runtime_launch_save_');
      await File('${root.path}/project.json').writeAsString(
        jsonEncode(<String, dynamic>{
          'name': 'Phase A Host Test',
          'maps': const <Map<String, dynamic>>[],
          'tilesets': const <Map<String, dynamic>>[],
        }),
      );
    });

    tearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    test('returns null when no versioned launch save is present', () async {
      final save = await loadRuntimeHostLaunchSaveData(
        projectFilePath: '${root.path}/project.json',
      );

      expect(save, isNull);
    });

    test('loads a versioned launch save adjacent to project.json', () async {
      await File('${root.path}/$kRuntimeHostLaunchSaveFileName').writeAsString(
        const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
          'saveId': 'phase-a-save',
          'currentMapId': 'golden_field',
          'playerPosition': <String, int>{'x': 1, 'y': 1},
          'playerFacing': 'east',
          'party': <String, dynamic>{
            'members': <Map<String, dynamic>>[
              <String, dynamic>{
                'speciesId': 'sproutle',
                'natureId': 'bold',
                'abilityId': 'overgrow',
                'level': 7,
                'knownMoveIds': <String>['tackle', 'growl', 'vine_whip'],
                'currentHp': 23,
              },
            ],
          },
          'trainerProfile': <String, dynamic>{'name': 'Phase A Tester'},
        }),
      );

      final save = await loadRuntimeHostLaunchSaveData(
        projectFilePath: '${root.path}/project.json',
      );

      expect(save, isNotNull);
      expect(save!.saveId, equals('phase-a-save'));
      expect(save.currentMapId, equals('golden_field'));
      expect(save.playerPosition.x, equals(1));
      expect(save.playerPosition.y, equals(1));
      expect(save.party.members.single.speciesId, equals('sproutle'));
      expect(
        save.party.members.single.knownMoveIds,
        equals(<String>['tackle', 'growl', 'vine_whip']),
      );
    });
  });
}
