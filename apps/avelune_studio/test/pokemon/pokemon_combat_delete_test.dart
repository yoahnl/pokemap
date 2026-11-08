import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/pokemon/data/local_pokemon_combat_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/combat_project_fixture.dart';
import '../support/m3_story_fixture.dart';

ProjectEncounterTable _table(String id) => ProjectEncounterTable(
  id: id,
  name: id,
  encounterKind: EncounterKind.walk,
  entries: const [
    ProjectEncounterEntry(
      speciesId: 'bulbasaur',
      minLevel: 3,
      maxLevel: 5,
      weight: 1,
    ),
  ],
);

ProjectTrainerEntry _trainer(String id) => ProjectTrainerEntry(
  id: id,
  name: id,
  trainerClass: 'Gamin',
  team: const [ProjectTrainerPokemonEntry(speciesId: 'bulbasaur', level: 5)],
);

Matcher _refused(String reason) =>
    throwsA(predicate<Object>((error) => '$error'.contains(reason)));

void main() {
  test(
    'a combat deletion checks every map before removing only unused records',
    () async {
      final source = await M3StoryFixture.create();
      addTearDown(() => source.directory.delete(recursive: true));
      await seedCombatProject(source);
      final file = File('${source.directory.path}/project.json');
      final project = ProjectManifest.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
      await file.writeAsString(
        jsonEncode(
          project
              .copyWith(
                encounterTables: [_table('prairie'), _table('grotte')],
                trainers: [_trainer('rival'), _trainer('gamin')],
              )
              .toJson(),
        ),
      );
      final mapFile = File(
        '${source.directory.path}/${project.maps.first.relativePath}',
      );
      final map = MapData.fromJson(
        jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
      );
      await mapFile.writeAsString(
        jsonEncode(
          map
              .copyWith(
                gameplayZones: [
                  ...map.gameplayZones,
                  const MapGameplayZone(
                    id: 'grotte_herbes',
                    kind: GameplayZoneKind.encounter,
                    area: MapRect(
                      pos: GridPos(x: 0, y: 0),
                      size: GridSize(width: 2, height: 2),
                    ),
                    encounter: EncounterZonePayload(encounterTableId: 'grotte'),
                  ),
                ],
                entities: [
                  ...map.entities,
                  const MapEntity(
                    id: 'rival-npc',
                    name: 'Rival',
                    kind: MapEntityKind.npc,
                    pos: GridPos(x: 3, y: 3),
                    npc: MapEntityNpcData(trainerId: 'rival'),
                  ),
                ],
              )
              .toJson(),
        ),
      );
      await source.maps.loadProject(source.session);
      final adapter = LocalPokemonCombatAdapter(
        session: source.session,
        mapAdapter: source.maps,
      );
      final mapBytes = await mapFile.readAsBytes();
      final authored = await file.readAsBytes();

      for (final (change, reason) in [
        (() => adapter.deleteTable(_table('grotte')), 'still referenced'),
        (() => adapter.deleteTrainer(_trainer('rival')), 'still referenced'),
        (
          () => adapter.deleteTable(
            _table('prairie').copyWith(name: 'Ancienne prairie'),
          ),
          'changé sur le disque',
        ),
      ]) {
        await expectLater(change(), _refused(reason));
        expect(await file.readAsBytes(), authored);
      }

      await adapter.deleteTable(_table('prairie'));
      await adapter.deleteTrainer(_trainer('gamin'));
      final after = (await adapter.load()).project;
      expect(after.encounterTables, [_table('grotte')]);
      expect(after.trainers, [_trainer('rival')]);
      expect(await mapFile.readAsBytes(), mapBytes);
    },
  );
}
