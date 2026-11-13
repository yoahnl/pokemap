import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';

import '../support/authoring_resource_fixture.dart';
import '../support/character_test_image.dart';

void main() {
  test('character clip edits preserve draft selection, save, clearing and disk reopen', () async {
    final fixture = await AuthoringResourceFixture.create();
    addTearDown(fixture.dispose);
    final image = await characterTestImage(
      fixture.directory,
      'Planche-base',
      256,
      256,
    );
    final navigation = fixture.navigation;
    await navigation.import(
      ResourceImageImport(
        sourcePath: image.path,
        name: image.name,
        tileWidth: 16,
        tileHeight: 16,
      ),
      intent: ResourceImportIntent.source,
    );
    final atlas = navigation.importedSource!.tileset!;
    final characters = navigation.characters;
    expect(await characters.create('Marcheur', atlas.id), isTrue);
    expect(characters.selectedCharacter?.name, 'Marcheur');
    characters.setFrameSize(3, 2);
    expect(characters.selectedDraft!.frameWidth, 3);
    characters.setPlaybackSpeed(2);
    expect(characters.playbackSpeed, 2);
    characters.assign(
      EntityFacing.south,
      0,
      const TilesetSourceRect(x: 0, y: 0),
    );
    expect(characters.dirty, isTrue);
    final selected = characters.selectedId!;
    characters.select(fixture.workspace.project!.characters.first.id);
    characters.select(selected);
    expect(characters.selectedDraft!.dirty, isTrue);
    expect(await characters.saveSelected(), isTrue);
    expect(characters.error, isNull);
    expect(characters.dirty, isFalse);
    final reopened = await fixture.reopen();
    final saved = reopened.characters.firstWhere(
      (entry) => entry.id == selected,
    );
    final clip = saved.animations.firstWhere(
      (animation) =>
          animation.state == CharacterAnimationState.walk &&
          animation.direction == EntityFacing.south,
    );
    expect(clip.frames.first.source, const TilesetSourceRect(x: 0, y: 0));
    expect(clip.sourceAssetId, isNull);
    expect(saved.frameWidth, 3);
    characters.clear(EntityFacing.south, 0);
    expect(characters.selectedDraft!.previewCharacter.animations, isEmpty);
    expect(await characters.saveSelected(), isTrue);
    expect(
      (await fixture.reopen()).characters
          .firstWhere((entry) => entry.id == selected)
          .animations,
      isEmpty,
    );
  });

}
