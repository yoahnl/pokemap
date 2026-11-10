import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/characters/coordination/character_import_workflow.dart';
import 'package:avelune_studio/features/characters/coordination/character_studio_animation_actions.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';

import '../support/authoring_resource_fixture.dart';
import '../support/character_test_image.dart';

void main() {
  test('dedicated strip saves pending atlas clips, imports one direction and persists timing', () async {
    final fixture = await AuthoringResourceFixture.create();
    addTearDown(fixture.dispose);
    final atlas = await characterTestImage(
      fixture.directory,
      'Planche-base',
      256,
      256,
    );
    final strip = await characterTestImage(
      fixture.directory,
      'Marche-dediee',
      96,
      32,
    );
    final navigation = fixture.navigation;
    await navigation.import(
      ResourceImageImport(
        sourcePath: atlas.path,
        name: atlas.name,
        tileWidth: 16,
        tileHeight: 16,
      ),
      intent: ResourceImportIntent.source,
    );
    final tileset = navigation.importedSource!.tileset!;
    final characters = navigation.characters;
    expect(await characters.create('Agent', tileset.id), isTrue);
    expect(
      characters.assignClassicSheet(
        tileset.source as ProjectRegularAtlasTilesetSource,
      ),
      isTrue,
    );
    expect(characters.selectedDraft!.changedClips.toList(), hasLength(4));
    var picks = 0;
    var confirmations = 0;
    final importer = CharacterImportWorkflow(
      navigation: navigation,
      picker: () async {
        picks++;
        return strip;
      },
      isActive: () => !navigation.isDisposed,
      confirmImage: (_) async => true,
      confirmSave: () async {
        confirmations++;
        return true;
      },
    );
    await importer.animation(CharacterAnimationState.walk, EntityFacing.south);
    expect(confirmations, 1);
    expect(picks, 1);
    expect(characters.error, isNull);
    expect(characters.selectedDraft!.dirty, isFalse);
    final saved = fixture.workspace.project!;
    final character = saved.characters.firstWhere(
      (entry) => entry.name == 'Agent',
    );
    final clip = character.animations.singleWhere(
      (entry) =>
          entry.state == CharacterAnimationState.walk &&
          entry.direction == EntityFacing.south,
    );
    expect(clip.sourceAssetId, isNotNull);
    expect(clip.frames.map((entry) => entry.source.x), [0, 32, 64]);
    expect(clip.frames.every((entry) => entry.source.width == 32), isTrue);
    expect(
      character.animations
          .singleWhere(
            (entry) =>
                entry.state == CharacterAnimationState.walk &&
                entry.direction == EntityFacing.north,
          )
          .sourceAssetId,
      isNull,
    );
    characters.setFrameDuration(EntityFacing.south, 0, 300);
    expect(await characters.saveSelected(), isTrue);
    final persisted = (await fixture.reopen()).characters
        .firstWhere((entry) => entry.id == character.id)
        .animations
        .singleWhere(
          (entry) =>
              entry.state == CharacterAnimationState.walk &&
              entry.direction == EntityFacing.south,
        );
    expect(persisted.sourceAssetId, clip.sourceAssetId);
    expect(persisted.frames.first.durationMs, 300);
    characters.setPreviewDirection(EntityFacing.north);
    characters.setAnimationState(CharacterAnimationState.bicycle);
    expect(characters.previewDirection, EntityFacing.north);
    expect(characters.animationState, CharacterAnimationState.bicycle);
  });
}
