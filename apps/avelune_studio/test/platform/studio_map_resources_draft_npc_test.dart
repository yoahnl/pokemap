import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/platform/rendering/studio_resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a character placed only in the draft gets its preview images',
    () async {
      final temp = await Directory.systemTemp.createTemp('draft-npc-');
      addTearDown(() => temp.delete(recursive: true));
      final root = await temp.resolveSymbolicLinks();
      await Directory('$root/maps').create();
      await Directory('$root/assets').create();
      await File('$root/assets/hero.png').writeAsBytes(base64Decode(_png));
      const project = ProjectManifest(
        name: 'Aperçu',
        maps: [
          ProjectMapEntry(
            id: 'town',
            name: 'Bourg',
            relativePath: 'maps/town.json',
          ),
        ],
        tilesets: [
          ProjectTilesetEntry(
            id: 'hero-sheet',
            name: 'Héros',
            relativePath: 'assets/hero.png',
          ),
        ],
        characters: [
          ProjectCharacterEntry(
            id: 'hero',
            name: 'Héros',
            tilesetId: 'hero-sheet',
          ),
        ],
      );
      const saved = MapData(
        id: 'town',
        name: 'Bourg',
        size: GridSize(width: 4, height: 4),
      );
      await File('$root/project.json')
          .writeAsString(jsonEncode(project.toJson()));
      await File('$root/maps/town.json')
          .writeAsString(jsonEncode(saved.toJson()));
      const npc = MapEntity(
        id: 'npc-hero',
        name: 'Héros',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
        npc: MapEntityNpcData(characterId: 'hero'),
      );

      final empty = await resolveStudioPreviewImagePaths(
        projectRoot: root,
        manifest: project,
        map: saved,
      );
      final draft = await resolveStudioPreviewImagePaths(
        projectRoot: root,
        manifest: project,
        map: saved.copyWith(entities: const [npc]),
      );

      expect(empty, isNot(contains('hero-sheet')));
      expect(draft['hero-sheet'], '$root/assets/hero.png');
    },
  );

  test(
    'the character preview does not depend on the map file saved on disk',
    () async {
      final temp = await Directory.systemTemp.createTemp('stale-npc-');
      addTearDown(() => temp.delete(recursive: true));
      final root = await temp.resolveSymbolicLinks();
      await Directory('$root/maps').create();
      await Directory('$root/assets').create();
      await File('$root/assets/hero.png').writeAsBytes(base64Decode(_png));
      final base = spatialEnvironmentProject();
      final project = base.copyWith(
        maps: const [
          ProjectMapEntry(
            id: 'a',
            name: 'Bosquet',
            relativePath: 'maps/a.json',
          ),
        ],
        tilesets: const [
          ProjectTilesetEntry(
            id: 'hero-sheet',
            name: 'Héros',
            relativePath: 'assets/hero.png',
          ),
        ],
        characters: const [
          ProjectCharacterEntry(
            id: 'hero',
            name: 'Héros',
            tilesetId: 'hero-sheet',
          ),
        ],
      );
      final draft = spatialEnvironmentMap().copyWith(
        entities: const [
          MapEntity(
            id: 'npc-hero',
            name: 'Héros',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(characterId: 'hero'),
          ),
        ],
      );
      final stale = draft.copyWith(
        spatialScene: draft.spatialScene!.copyWith(
          instances: [
            SpatialModelInstance(
              id: 'merged-away',
              modelId: 'removed-duplicate',
              position: Model3dVector3(x: 2, y: 0, z: 2),
            ),
          ],
        ),
      );
      await File('$root/project.json')
          .writeAsString(jsonEncode(project.toJson()));
      await File('$root/maps/a.json').writeAsString(jsonEncode(stale.toJson()));

      final preview = await resolveStudioPreviewImagePaths(
        projectRoot: root,
        manifest: project,
        map: draft,
      );

      expect(preview['hero-sheet'], '$root/assets/hero.png');
    },
  );
}
