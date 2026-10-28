import 'dart:io';

import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:image/image.dart' as image;

import 'resource_fixture.dart';

void main() {
  test('Studio imports and reopens all Surf clips and climbing without changing identity or old clips through canonical authoring', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    final imported = await fixture.import();
    final created = await fixture.resources.mutate(
      'characterStudio.character.create',
      {
        'name': 'Navigatrice',
        'tilesetId': imported.createdTilesetId!,
        'frameWidth': 2,
        'frameHeight': 2,
      },
    );
    final characterId = created.manifest.characters.single.id;
    final source = File('${fixture.root.path}/cycle.png');
    await source.writeAsBytes(
      image.encodePng(image.Image(width: 96, height: 32)),
    );
    final existing = await fixture.resources.importCharacterAnimation(
      CharacterAnimationImport(
        sourcePath: source.path,
        characterId: characterId,
        state: CharacterAnimationState.walk,
        direction: EntityFacing.south,
        poseWidth: 32,
        poseHeight: 32,
      ),
    );
    final oldClip = existing.manifest.characters.single.animations.single;
    for (final state in [
      CharacterAnimationState.climb,
      CharacterAnimationState.surfIdle,
      CharacterAnimationState.surf,
      CharacterAnimationState.surfEnter,
      CharacterAnimationState.surfExit,
    ]) {
      for (final direction in EntityFacing.values) {
        final result = await fixture.resources.importCharacterAnimation(
          CharacterAnimationImport(
            sourcePath: source.path,
            characterId: characterId,
            state: state,
            direction: direction,
            poseWidth: 32,
            poseHeight: 32,
          ),
        );
        final clip = result.manifest.characters.single.animations.singleWhere(
          (clip) => clip.state == state && clip.direction == direction,
        );
        expect(
          clip.loop,
          state != CharacterAnimationState.surfEnter &&
              state != CharacterAnimationState.surfExit,
        );
        expect(clip.sourceAssetId, isNotNull);
        expect(clip.frames.map((frame) => frame.source.x), [0, 32, 64]);
        expect(
          clip.frames.every(
            (frame) =>
                frame.source.y == 0 &&
                frame.source.width == 32 &&
                frame.source.height == 32 &&
                frame.durationMs == 150,
          ),
          isTrue,
        );
      }
    }
    final reopened = await fixture.maps.loadProject(fixture.session);
    expect(reopened.characters.single.animations, contains(oldClip));
    expect(reopened.characters.single.id, characterId);
    expect(reopened.characters.single.name, 'Navigatrice');
    expect(reopened.characters.single.tilesetId, imported.createdTilesetId);
    expect(reopened.characters.single.animations, hasLength(21));
  });
}
