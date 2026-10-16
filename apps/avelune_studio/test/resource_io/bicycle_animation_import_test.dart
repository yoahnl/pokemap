import 'dart:io';

import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:image/image.dart' as image;

import 'resource_fixture.dart';

void main() {
  test('Studio imports and reopens all eight dedicated bicycle clips through canonical authoring', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    final imported = await fixture.import();
    final created = await fixture.resources.mutate(
      'characterStudio.character.create',
      {
        'name': 'Cycliste',
        'tilesetId': imported.createdTilesetId!,
        'frameWidth': 2,
        'frameHeight': 2,
      },
    );
    final characterId = created.manifest.characters.single.id;
    final source = File('${fixture.root.path}/cycle.png');
    await source.writeAsBytes(
      image.encodePng(image.Image(width: 128, height: 128)),
    );
    const rows = {
      EntityFacing.south: 0,
      EntityFacing.west: 1,
      EntityFacing.east: 2,
      EntityFacing.north: 3,
    };
    for (final state in [
      CharacterAnimationState.bicycleIdle,
      CharacterAnimationState.bicycle,
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
        expect(clip.sourceAssetId, isNotNull);
        expect(clip.frames.map((frame) => frame.source.x), [0, 32, 64, 96]);
        expect(
          clip.frames.every(
            (frame) =>
                frame.source.y == rows[direction]! * 32 &&
                frame.source.width == 32 &&
                frame.source.height == 32 &&
                frame.durationMs == 100,
          ),
          isTrue,
        );
      }
    }
    final reopened = await fixture.maps.loadProject(fixture.session);
    expect(reopened.characters.single.animations, hasLength(8));
  });
}
