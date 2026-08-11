import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_loader/src/runtime_launch_save.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveRuntimeHostLaunchPlan', () {
    const versionedSave = SaveData(saveId: 'versioned');
    const manualSeed = SaveData(saveId: 'manual-seed');
    const demoSeed = SaveData(saveId: 'demo-seed');

    test('versioned save stays ahead of project New Game and host seeds', () {
      final plan = resolveRuntimeHostLaunchPlan(
        newGame: const ProjectNewGameConfig(enabled: true),
        versionedLaunchSave: versionedSave,
        manualLaunchOverride: manualSeed,
        demoLaunchFallback: demoSeed,
      );

      expect(plan.saveData, same(versionedSave));
      expect(plan.initialMapActivationReason, MapActivationReason.saveRestore);
      expect(
        allowsRuntimeHostSyntheticLaunchSeed(
          newGame: const ProjectNewGameConfig(enabled: true),
          versionedLaunchSave: versionedSave,
        ),
        isFalse,
      );
    });

    test('project New Game is not replaced by manual or demo host seeds', () {
      final plan = resolveRuntimeHostLaunchPlan(
        newGame: const ProjectNewGameConfig(enabled: true),
        versionedLaunchSave: null,
        manualLaunchOverride: manualSeed,
        demoLaunchFallback: demoSeed,
      );

      expect(plan.saveData, isNull);
      expect(plan.initialMapActivationReason, MapActivationReason.initialBoot);
      expect(
        allowsRuntimeHostSyntheticLaunchSeed(
          newGame: const ProjectNewGameConfig(enabled: true),
          versionedLaunchSave: null,
        ),
        isFalse,
      );
    });

    test('legacy projects preserve manual then demo seed fallbacks', () {
      const legacyNewGame = ProjectNewGameConfig();

      final manualPlan = resolveRuntimeHostLaunchPlan(
        newGame: legacyNewGame,
        versionedLaunchSave: null,
        manualLaunchOverride: manualSeed,
        demoLaunchFallback: demoSeed,
      );
      final demoPlan = resolveRuntimeHostLaunchPlan(
        newGame: legacyNewGame,
        versionedLaunchSave: null,
        manualLaunchOverride: null,
        demoLaunchFallback: demoSeed,
      );

      expect(manualPlan.saveData, same(manualSeed));
      expect(demoPlan.saveData, same(demoSeed));
      expect(manualPlan.initialMapActivationReason,
          MapActivationReason.initialBoot);
      expect(
          demoPlan.initialMapActivationReason, MapActivationReason.initialBoot);
      expect(
        allowsRuntimeHostSyntheticLaunchSeed(
          newGame: legacyNewGame,
          versionedLaunchSave: null,
        ),
        isTrue,
      );
    });
  });

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
          'itemSystemSchemaVersion': 1,
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
