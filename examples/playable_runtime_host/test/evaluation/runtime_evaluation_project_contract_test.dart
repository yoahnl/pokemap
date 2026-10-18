import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_loader/src/evaluation/driver/runtime_evaluation_driver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final name in ['alpha', 'beta']) {
    test(
      'evaluation starts $name from its authored map, trainer and party',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'generic-evaluation-$name-',
        );
        addTearDown(() => root.delete(recursive: true));
        final mapId = '$name-start';
        final party = name == 'alpha'
            ? const <PlayerPokemon>[]
            : const [
                PlayerPokemon(
                  speciesId: 'partner',
                  abilityId: 'sturdy',
                  natureId: 'hardy',
                  level: 5,
                  currentHp: 12,
                ),
              ];
        final project = ProjectManifest(
          name: name,
          maps: [
            ProjectMapEntry(id: mapId, name: name, relativePath: 'start.json'),
          ],
          tilesets: const [],
          newGame: ProjectNewGameConfig(
            enabled: true,
            startMapId: mapId,
            startSpawnId: 'start',
            playerName: name,
            startingMoney: name == 'alpha' ? 17 : 29,
            initialParty: party,
          ),
        );
        final map = MapData(
          id: mapId,
          name: name,
          size: const GridSize(width: 4, height: 4),
          entities: const [
            MapEntity(
              id: 'start',
              name: 'Start',
              kind: MapEntityKind.spawn,
              pos: GridPos(x: 1, y: 2),
              blocksMovement: false,
              spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
            ),
          ],
        );
        await File('${root.path}/project.json')
            .writeAsString(jsonEncode(project.toJson()));
        await File('${root.path}/start.json')
            .writeAsString(jsonEncode(map.toJson()));
        if (party.isNotEmpty) {
          final species = File(
            '${root.path}/data/pokemon/species/partner.json',
          );
          await species.parent.create(recursive: true);
          await species.writeAsString(
            jsonEncode({
              'schemaVersion': 1,
              'id': 'partner',
              'typing': {
                'types': ['normal'],
              },
              'baseStats': {
                'hp': 45,
                'atk': 49,
                'def': 49,
                'spa': 65,
                'spd': 65,
                'spe': 45,
              },
              'abilities': {'primary': 'sturdy'},
              'progression': {
                'growthRateId': 'medium_slow',
                'baseExp': 64,
                'catchRate': 45,
              },
            }),
          );
        }
        final driver = await RuntimeEvaluationDriver.start(projectRoot: root);
        addTearDown(driver.dispose);
        expect(driver.state.currentMapId, mapId);
        expect(driver.state.playerPosition, const GridPos(x: 1, y: 2));
        expect(driver.state.trainerProfile.name, name);
        expect(driver.state.trainerProfile.money, name == 'alpha' ? 17 : 29);
        expect(
          driver.state.party.members.map((value) => value.speciesId),
          party.map((value) => value.speciesId),
        );
        await driver.startNewGame();
      },
    );
  }
}
