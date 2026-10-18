import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart' show Vector2;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/flame_character_custom_animation_runtime_actor.dart';
import 'package:map_runtime/src/presentation/flame/overworld_actor_component.dart';

void main() {
  test('conditional actors center wider footprints without changing their grid anchor', () {
    for (final conditional in [false, true]) {
      final actor = OverworldActorComponent(character: _character(), tileImages: const {},
        tileWidth: 16, tileHeight: 16, cellWidth: 32, cellHeight: 32,
        centerOnFootprint: conditional);
      actor.configureGridPlacement(pos: const GridPos(x: 3, y: 3),
        footprint: const GridSize(width: 4, height: 2), mapOrigin: Vector2.zero());
      expect(actor.gridPos, const GridPos(x: 3, y: 3));
      expect(actor.position.x, conditional ? 128 : 96);
      expect(actor.position.y + actor.size.y, 160);
    }
  });
  test('Flame actor plays custom pixels then restores Base', () {
    const clip = CharacterCustomAnimationClip(
      definitionId: 'wave',
      sourceAssetId: 'wave_source',
      frames: <CharacterAnimationFrame>[
        CharacterAnimationFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 24, height: 32),
          durationMs: 100,
        ),
        CharacterAnimationFrame(
          source: TilesetSourceRect(x: 24, y: 0, width: 24, height: 32),
          durationMs: 100,
        ),
      ],
    );
    final component = OverworldActorComponent(
      character: _character(),
      tileImages: <String, RuntimeTilesetImage>{
        'hero': _image(),
        characterAnimationRuntimeImageId('wave_source'): _image(),
      },
      tileWidth: 16,
      tileHeight: 16,
      cellWidth: 32,
      cellHeight: 32,
    );
    final actor = FlameCharacterCustomAnimationRuntimeActor(
      actorId: 'player',
      component: component,
    );

    expect(actor.canPlayCustomAnimation(clip), isTrue);
    actor.playCustomAnimation(clip);
    expect(component.debugCustomAnimationDefinitionId, 'wave');
    expect(component.debugAnimationSource?.sourceRect.left, 0);

    component.update(0.1);
    expect(component.debugAnimationSource?.sourceRect.left, 24);

    actor.restoreBase(EntityFacing.east);
    expect(component.debugCustomAnimationDefinitionId, isNull);
    expect(component.facing, EntityFacing.east);
    expect(component.debugAnimationSource?.usesLegacyGrid, isTrue);
  });

  test('custom source must be loaded and every frame must be in bounds', () {
    final component = OverworldActorComponent(
      character: _character(),
      tileImages: <String, RuntimeTilesetImage>{
        characterAnimationRuntimeImageId('wave_source'): _image(
          width: 32,
          height: 32,
        ),
      },
      tileWidth: 16,
      tileHeight: 16,
      cellWidth: 32,
      cellHeight: 32,
    );
    const outOfBounds = CharacterCustomAnimationClip(
      definitionId: 'wave',
      sourceAssetId: 'wave_source',
      frames: <CharacterAnimationFrame>[
        CharacterAnimationFrame(
          source: TilesetSourceRect(x: 24, y: 0, width: 24, height: 32),
        ),
      ],
    );

    expect(component.canPlayCustomAnimation(outOfBounds), isFalse);
  });
}

ProjectCharacterEntry _character() {
  return const ProjectCharacterEntry(
    id: 'hero_character',
    name: 'Hero',
    tilesetId: 'hero',
    animations: <CharacterAnimation>[
      CharacterAnimation(
        state: CharacterAnimationState.idle,
        direction: EntityFacing.east,
        frames: <CharacterAnimationFrame>[
          CharacterAnimationFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
          ),
        ],
      ),
    ],
  );
}

RuntimeTilesetImage _image({int width = 128, int height = 128}) {
  return RuntimeTilesetImage(
    images: const [],
    chunks: const [],
    width: width,
    height: height,
  );
}
