import 'package:avelune_studio/features/characters/coordination/character_studio_controller.dart';
import 'package:avelune_studio/features/characters/application/character_studio_tileset_compatibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  const project = ProjectManifest(
    name: 'Création de personnage',
    maps: [],
    tilesets: [
      ProjectTilesetEntry(
        id: 'voyageur',
        name: 'Voyageur',
        relativePath: 'voyageur.png',
        source: ProjectRegularAtlasTilesetSource(
          assetId: 'voyageur',
          pixelWidth: 256,
          pixelHeight: 256,
          tileWidth: 32,
          tileHeight: 32,
        ),
      ),
    ],
  );

  test('character creation retains trimmed identity, compatible atlas and selected receipt', () async {
    var current = project;
    final calls = <(String, Map<String, Object?>)>[];
    final controller = CharacterStudioController(
      project: () => current,
      mutate: (action, parameters) async {
        calls.add((action, parameters));
        return current = current.copyWith(
          characters: [
            ProjectCharacterEntry(
              id: 'eloise',
              name: parameters['name'] as String,
              tilesetId: parameters['tilesetId'] as String,
            ),
          ],
        );
      },
    );
    addTearDown(controller.dispose);
    expect(
      compatibleCharacterStudioTilesets(project).map((entry) => entry.id),
      ['voyageur'],
    );
    expect(await controller.create(' Éloïse ', 'voyageur'), isTrue);
    expect(calls.single.$1, 'characterStudio.character.create');
    expect(calls.single.$2, {
      'name': 'Éloïse',
      'tilesetId': 'voyageur',
      'frameWidth': 2,
      'frameHeight': 2,
    });
    expect(controller.selectedCharacter!.name, 'Éloïse');
    expect(controller.error, isNull);
    expect(controller.saving, isFalse);
  });

  test('creation fails without claiming a selected character', () async {
    final controller = CharacterStudioController(
      project: () => project,
      mutate: (_, _) async => throw StateError('write.refused'),
    );
    addTearDown(controller.dispose);
    expect(await controller.create('Éloïse', 'voyageur'), isFalse);
    expect(controller.selectedCharacter, isNull);
    expect(controller.error, contains('write.refused'));
    expect(controller.saving, isFalse);
    expect(
      compatibleCharacterStudioTilesets(project.copyWith(tilesets: [])),
      isEmpty,
    );
  });
}
