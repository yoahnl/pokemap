import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'P6-01 loads repo-local Selbrume and builds New Game from explicit Selbrume spawn',
    () async {
      final repoRoot = _findRepoRoot();
      final projectFilePath = p.join(repoRoot.path, 'selbrume', 'project.json');

      expect(await File(projectFilePath).exists(), isTrue);

      final selbrumeBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'Selbrume',
      );
      final routeBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'route 1',
      );

      expect(selbrumeBundle.projectRootDirectory,
          p.normalize(p.join(repoRoot.path, 'selbrume')));
      expect(selbrumeBundle.manifest.name, 'Selbrume');
      expect(
        selbrumeBundle.manifest.maps.map((map) => map.id),
        containsAll(<String>['route 1', 'Selbrume']),
      );
      expect(selbrumeBundle.manifest.maps.first.id, 'route 1');

      expect(selbrumeBundle.map.id, 'Selbrume');
      expect(routeBundle.map.id, 'route 1');
      final grant = routeBundle.map.entities.singleWhere(
        (entity) => entity.id == 'grant',
      );
      expect(grant.kind, MapEntityKind.npc);
      expect(grant.npc?.trainerId, 'grant');
      expect(
        selbrumeBundle.manifest.trainers.map((trainer) => trainer.id),
        contains('grant'),
      );

      final startMap = selbrumeBundle.map;
      expect(startMap.mapMetadata.defaultSpawnId, isNull);

      final spawn = startMap.entities.singleWhere(
        (entity) => entity.id == 'spawn',
      );
      expect(spawn.kind, MapEntityKind.spawn);
      expect(spawn.pos, const GridPos(x: 17, y: 24));
      expect(spawn.spawn?.role, EntitySpawnRole.playerStart);
      expect(spawn.spawn?.facing, EntityFacing.south);

      final resolvedSpawn = resolveInitialPlayerSpawn(
        startMap,
        tileWidthPx: selbrumeBundle.manifest.settings.tileWidth,
        tileHeightPx: selbrumeBundle.manifest.settings.tileHeight,
      );
      expect(resolvedSpawn.pos, const GridPos(x: 17, y: 24));
      expect(resolvedSpawn.facing, Direction.south);

      final state = createNewGameStateFromMap(
        startMap: startMap,
        saveId: 'p6_01_selbrume_new_game',
        playerName: 'P6 Tester',
        tileWidthPx: selbrumeBundle.manifest.settings.tileWidth,
        tileHeightPx: selbrumeBundle.manifest.settings.tileHeight,
      );

      expect(state.saveId, 'p6_01_selbrume_new_game');
      expect(state.currentMapId, 'Selbrume');
      expect(state.playerPosition, const GridPos(x: 17, y: 24));
      expect(state.playerFacing, EntityFacing.south);
      expect(state.party.members, isEmpty);
      expect(state.bag.entries, isEmpty);
      expect(state.trainerProfile.money, 0);
    },
  );
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;

  while (true) {
    final candidate = File(
      p.join(current.path, 'selbrume', 'project.json'),
    );
    if (candidate.existsSync()) {
      return current;
    }

    final parent = current.parent.absolute;
    if (parent.path == current.path) {
      throw StateError('Could not find repo-local selbrume/project.json');
    }
    current = parent;
  }
}
