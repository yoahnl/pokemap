import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FG-181 fixture is a valid minimal three-map fangame', () async {
    final root = p.join(Directory.current.path, 'golden_fangame_slice');
    final projectPath = p.join(root, 'project.json');

    expect(await File(projectPath).exists(), isTrue);
    final projectJson = jsonDecode(await File(projectPath).readAsString())
        as Map<String, dynamic>;
    final project = ProjectManifest.fromJson(projectJson);
    ProjectValidator.validate(project);

    expect(project.version, ProjectVersion.v1);
    expect(project.maps, hasLength(3));
    expect(project.tilesets, isEmpty);
    expect(project.newGame.enabled, isTrue);
    expect(project.newGame.initialParty, isEmpty);
    expect(project.newGame.starterOptions, hasLength(3));
    expect(project.encounterTables, hasLength(1));
    expect(project.trainers, hasLength(1));

    final loadedMaps = <String, MapData>{};
    for (final entry in project.maps) {
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectPath,
        mapId: entry.id,
      );
      MapValidator.validate(
        bundle.map,
        projectDialogueContext: project,
      );
      loadedMaps[entry.id] = bundle.map;
      expect(bundle.tilesetAbsolutePathsById, isEmpty);
    }

    expect(loadedMaps.keys, <String>{
      'golden_town',
      'golden_route',
      'golden_summit',
    });
    expect(
      loadedMaps['golden_route']!
          .gameplayZones
          .where((zone) => zone.kind == GameplayZoneKind.encounter),
      hasLength(1),
    );
    expect(
      loadedMaps['golden_route']!.entities.where(
            (entity) => entity.npc?.trainerId == 'trainer_golden_rival',
          ),
      hasLength(1),
    );

    final walkthroughFile = File(p.join(root, 'walkthrough.json'));
    final walkthrough = jsonDecode(await walkthroughFile.readAsString())
        as Map<String, dynamic>;
    expect(walkthrough['schemaVersion'], 1);
    expect(walkthrough['projectId'], 'golden_fangame_slice');
    final steps =
        (walkthrough['steps'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(
      steps.map((step) => step['id']),
      orderedEquals(const <String>[
        'new_game',
        'starter_chosen',
        'wild_encounter',
        'wild_battle_completed',
        'capture_completed',
        'trainer_defeated',
        'level_up_proved',
        'shop_used',
        'heal_center_used',
        'badge_flag_acquired',
        'surf_unlocked',
        'save_reloaded',
        'story_end_reached',
      ]),
    );
    for (final step in steps) {
      expect((step['label'] as String).trim(), isNotEmpty);
      expect((step['proof'] as String).trim(), isNotEmpty);
    }

    final rasterAssets = await Directory(root)
        .list(recursive: true)
        .where((entry) => entry is File)
        .map((entry) => p.extension(entry.path).toLowerCase())
        .where((extension) =>
            const {'.png', '.jpg', '.jpeg', '.webp'}.contains(extension))
        .toList();
    expect(rasterAssets, isEmpty);
  });

  test('FG-181 synthetic composition cannot publish product readiness', () {
    final source = File(
      p.join(
        Directory.current.path,
        'test',
        'golden_fangame_slice_e2e_test.dart',
      ),
    ).readAsStringSync();

    expect(source, isNot(contains('ProjectGameplayReadinessReport')));
    expect(source, isNot(contains('FG-182 completes')));
    expect(source, contains('FG-181 composition fixture'));
  });
}
