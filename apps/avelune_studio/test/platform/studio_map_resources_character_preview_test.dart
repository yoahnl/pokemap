import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the character preview reads the definitions it is given', () async {
    final temp = await Directory.systemTemp.createTemp('preview-defs-');
    addTearDown(() => temp.delete(recursive: true));
    final root = await temp.resolveSymbolicLinks();
    await Directory('$root/assets').create();
    await File('$root/assets/hero.png').writeAsBytes(base64Decode(_png));
    const loaded = ProjectManifest(
      name: 'Aperçu',
      maps: [],
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
    final resources = await StudioMapResources.load(
      ProjectSession(sessionId: 'preview', name: 'Aperçu', directoryPath: root),
      loaded,
    );
    addTearDown(resources.dispose);
    const map = MapData(
      id: 'town',
      name: 'Bourg',
      size: GridSize(width: 4, height: 4),
      entities: [
        MapEntity(
          id: 'npc-hero',
          name: 'Héros',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1),
          npc: MapEntityNpcData(characterId: 'hero'),
        ),
      ],
    );

    await expectLater(
      resources.spatialPreview(map, loaded.copyWith(characters: const [])),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Le personnage choisi pour « Héros » n’existe plus dans le projet.',
        ),
      ),
    );
  });
}
