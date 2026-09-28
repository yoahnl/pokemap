import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/platform/rendering/studio_resource_index.dart';

void main() {
  test('a walk-only character retains its base and dedicated source', () {
    const character = ProjectCharacterEntry(
      id: 'walker',
      name: 'Walker',
      tilesetId: 'base',
      animations: [
        CharacterAnimation(
          state: CharacterAnimationState.walk,
          direction: EntityFacing.south,
          sourceAssetId: 'walk-source',
          frames: [
            CharacterAnimationFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
            ),
          ],
        ),
      ],
    );
    final index = StudioResourceIndex(
      const ProjectManifest(name: 'Characters', maps: [], tilesets: []),
    );
    expect(index.forCharacter(character), {
      'base',
      'character-animation:walk-source',
    });
  });
}
