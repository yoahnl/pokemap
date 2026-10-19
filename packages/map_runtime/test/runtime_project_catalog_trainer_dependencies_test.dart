import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/runtime_manifest_tilesets.dart';
import 'package:map_runtime/src/application/runtime_project_catalog.dart';
import 'package:path/path.dart' as p;

import '../../map_gameplay/test/support/border_jump_fixture.dart';

void main() {
  for (final partitioned in [false, true]) {
    test('retained trainer dependencies stay valid partitioned=$partitioned',
        () async {
      final root = await Directory.systemTemp.createTemp('trainer-catalog-');
      addTearDown(() => root.delete(recursive: true));
      final fixture = BorderJumpFixture();
      final project = fixture.project.copyWith(
        tilesets: [
          ...fixture.project.tilesets,
          const ProjectTilesetEntry(
            id: 'trainer-sheet',
            name: 'Trainer',
            relativePath: 'trainer.png',
          ),
        ],
        characters: const [
          ProjectCharacterEntry(
            id: 'trainer-character',
            name: 'Trainer',
            tilesetId: 'trainer-sheet',
          ),
          ProjectCharacterEntry(
            id: 'unused-character',
            name: 'Unused',
            tilesetId: 'trainer-sheet',
          ),
        ],
        elements: [
          ...fixture.project.elements,
          fixture.project.elements.first.copyWith(id: 'trainer-portrait'),
          fixture.project.elements.first.copyWith(id: 'unused-portrait'),
        ],
        trainers: const [
          ProjectTrainerEntry(
            id: 'trainer-on-another-map',
            name: 'Trainer',
            trainerClass: 'Sage',
            characterId: 'trainer-character',
            portraitElementId: 'trainer-portrait',
            team: [ProjectTrainerPokemonEntry(speciesId: 'rattata', level: 8)],
          ),
        ],
      );
      ProjectValidator.validate(project);
      final file = File(p.join(root.path, 'project.json'));
      if (partitioned) {
        final publication = PortableCatalogPublication.encodeProject(project);
        await file.writeAsString(jsonEncode(publication.descriptor));
        for (final entry in publication.storage.objects.entries) {
          final object = File(p.join(root.path, 'catalog/objects/${entry.key}.json'));
          await object.parent.create(recursive: true);
          await object.writeAsBytes(entry.value);
        }
      } else {
        await file.writeAsString(jsonEncode(project.toJson()));
      }
      final catalog = await RuntimeProjectCatalog.open(file.path);
      addTearDown(catalog.dispose);
      final selected = await catalog.manifestForMap(fixture.map);
      expect(selected.trainers, project.trainers);
      expect(selected.characters.map((c) => c.id), ['trainer-character']);
      expect(selected.elements.any((e) => e.id == 'trainer-portrait'), true);
      expect(selected.elements.any((e) => e.id == 'unused-portrait'), false);
      expect(collectAllRuntimeTilesetIds(fixture.map, selected),
          isNot(contains('trainer-sheet')));
      ProjectValidator.validate(selected);
      final edge = fixture.evidence.edges.single;
      final world = GameplayWorldState.initial(
        map: fixture.map,
        project: selected,
        playerPos: GridPos(
          x: edge.expectedCarrierCell.x,
          y: edge.expectedCarrierCell.y - 1,
        ),
        tileWidth: 32,
        tileHeight: 32,
      );
      expect(stepGameplayWorld(world, const MoveIntent(Direction.south)),
          isA<Jumped>());
    });
  }
}
