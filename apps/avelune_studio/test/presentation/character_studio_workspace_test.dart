import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:avelune_studio/features/characters/coordination/character_import_workflow.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';

import '../support/authoring_resource_fixture.dart';
import '../support/character_test_image.dart';
import '../support/real_test_io.dart';

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

  testWidgets(
    'a real three by four PNG imports a draft, renders and preserves bounds on refused save',
    (tester) async {
      final fixture = (await RealTestIo.run(
        tester,
        AuthoringResourceFixture.create,
      ))!;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await RealTestIo.run(tester, fixture.dispose);
      });
      final picked = (await RealTestIo.run(
        tester,
        () => characterTestImage(fixture.directory, 'Pose-guide', 96, 128),
      ))!;
      final navigation = fixture.navigation;
      final importer = CharacterImportWorkflow(
        navigation: navigation,
        picker: () async => picked,
        isActive: () => !navigation.isDisposed,
        confirmImage: (_) async => true,
        confirmSave: () async => true,
      );
      await RealTestIo.run(tester, importer.sheet);
      final characters = navigation.characters;
      expect(characters.selectedCharacter?.name, 'Pose-guide');
      expect(characters.selectedDraft?.changedClips.length, 4);
      expect(characters.dirty, isTrue);
      final resources = (await RealTestIo.run(
        tester,
        () => StudioMapResources.load(
          fixture.session,
          fixture.workspace.project!,
        ),
      ))!;
      addTearDown(() => RealTestIo.run(tester, resources.dispose));
      await RealTestIo.run(tester, () async {
        resources.setCharacterBrush(characters.selectedDraft!.previewCharacter);
        await resources.settled;
      });
      expect(resources.diagnostics, isEmpty);
      final preview = RuntimeAuthoringCharacterRenderer(
        character: characters.selectedDraft!.previewCharacter,
        settings: fixture.workspace.project!.settings,
        images: resources.images,
        animationState: CharacterAnimationState.walk,
      );
      expect(
        preview.hasVisual,
        isTrue,
        reason:
            'images=${resources.images.keys}; diagnostics=${resources.diagnostics}',
      );
      expect(await RealTestIo.run(tester, characters.saveSelected), isTrue);
      expect(characters.saving, isFalse);
      final reopened = (await RealTestIo.run(tester, fixture.reopen))!;
      final imported = reopened.characters.firstWhere(
        (entry) => entry.name == 'Pose-guide',
      );
      expect(imported.frameWidth, 2);
      expect(imported.frameHeight, 2);
      expect(imported.animations, hasLength(4));
      expect(
        imported.animations.every((clip) => clip.frames.length == 3),
        isTrue,
      );
      characters.setFrameSize(3, 2);
      expect(await RealTestIo.run(tester, characters.saveSelected), isFalse);
      expect(characters.error, contains('sort de la planche'));
      expect(characters.dirty, isTrue);
      final unchanged = (await RealTestIo.run(tester, fixture.reopen))!;
      expect(
        unchanged.characters
            .firstWhere((entry) => entry.id == imported.id)
            .frameWidth,
        2,
      );
    },
  );
}
