import 'package:avelune_studio/platform/rendering/studio_resource_index.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

ProjectManifest _project() => workspaceProject.copyWith(
  characters: [
    ProjectCharacterEntry(
      id: 'ekans',
      name: 'Abo — compagnon d’équipe',
      tilesetId: 'hgss-compagnon-ekans',
      frameWidth: 2,
      frameHeight: 2,
      animations: [
        CharacterAnimation(
          state: CharacterAnimationState.idle,
          direction: EntityFacing.south,
          sourceAssetId: 'asset-hgss-compagnon-ekans',
          frames: const [
            CharacterAnimationFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() {
  test(
    'the resource index names the owner of a character sheet and animations',
    () {
      final index = StudioResourceIndex(_project());
      final sheet = index.owners['hgss-compagnon-ekans']!;
      expect(
        (sheet.kind, sheet.id, sheet.name),
        ('character', 'ekans', 'Abo — compagnon d’équipe'),
      );
      expect(sheet.role, 'Planche du personnage');
      final animation =
          index.owners['character-animation:asset-hgss-compagnon-ekans']!;
      expect((animation.kind, animation.id), ('character', 'ekans'));
      expect(animation.role, 'Animations');
      final tileset = index.owners[workspaceProject.tilesets.first.id]!;
      expect(tileset.kind, 'tileset');
      expect(index.owners['unknown-reference'], isNull);
    },
  );

}
