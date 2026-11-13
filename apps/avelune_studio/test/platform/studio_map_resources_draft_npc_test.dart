import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

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

      final empty = await loadStudioPreviewBundle(
        projectRoot: root,
        manifest: project,
        map: saved,
      );
      final draft = await loadStudioPreviewBundle(
        projectRoot: root,
        manifest: project,
        map: saved.copyWith(entities: const [npc]),
      );

      expect(
        empty.runtimeImageAbsolutePathsById,
        isNot(contains('hero-sheet')),
      );
      expect(
        draft.runtimeImageAbsolutePathsById['hero-sheet'],
        '$root/assets/hero.png',
      );
    },
  );
}
