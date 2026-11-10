import 'dart:async';

import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:avelune_studio/features/characters/coordination/character_import_workflow.dart';
import 'package:avelune_studio/features/characters/coordination/character_studio_portrait_actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/authoring_resource_fixture.dart';
import '../support/character_test_image.dart';

void main() {
  test('refused sheet confirmation preserves the authoring project', () async {
    final fixture = await AuthoringResourceFixture.create();
    addTearDown(fixture.dispose);
    final picked = await characterTestImage(
      fixture.directory,
      'Refusée',
      96,
      128,
    );
    final before = await fixture.reopen();
    final importer = CharacterImportWorkflow(
      navigation: fixture.navigation,
      picker: () async => picked,
      isActive: () => true,
      confirmImage: (_) async => false,
      confirmSave: () async => true,
    );
    await importer.sheet();
    expect(await fixture.reopen(), before);
    expect(fixture.navigation.busy, isFalse);
  });

  test(
    'refused draft save blocks the animation picker and preserves the draft',
    () async {
      final fixture = await AuthoringResourceFixture.create();
      addTearDown(fixture.dispose);
      final characters = fixture.navigation.characters;
      final original = characters.selectedCharacter!;
      characters.setName('Brouillon à conserver');
      var picks = 0;
      final importer = CharacterImportWorkflow(
        navigation: fixture.navigation,
        picker: () async {
          picks++;
          return null;
        },
        isActive: () => true,
        confirmImage: (_) async => true,
        confirmSave: () async => false,
      );
      await importer.animation(
        CharacterAnimationState.walk,
        EntityFacing.south,
      );
      expect(picks, 0);
      expect(characters.selectedDraft!.name, 'Brouillon à conserver');
      expect(characters.dirty, isTrue);
      expect(
        (await fixture.reopen()).characters.singleWhere(
          (entry) => entry.id == original.id,
        ),
        original,
      );
    },
  );

  test(
    'late sheet picker result cannot import after its owner closes',
    () async {
      final fixture = await AuthoringResourceFixture.create();
      addTearDown(fixture.dispose);
      final picked = await characterTestImage(
        fixture.directory,
        'Tardive',
        96,
        128,
      );
      final before = await fixture.reopen();
      final choice = Completer<PickedResourceImage?>();
      var active = true;
      final importer = CharacterImportWorkflow(
        navigation: fixture.navigation,
        picker: () => choice.future,
        isActive: () => active,
        confirmImage: (_) async =>
            fail('Closed owner must not confirm an import'),
        confirmSave: () async => true,
      );
      final pending = importer.sheet();
      active = false;
      choice.complete(picked);
      await pending;
      expect(await fixture.reopen(), before);
      expect(fixture.navigation.busy, isFalse);
    },
  );

  test(
    'incompatible sheet geometry is refused before importing a source',
    () async {
      final fixture = await AuthoringResourceFixture.create();
      addTearDown(fixture.dispose);
      final picked = await characterTestImage(
        fixture.directory,
        'Malformée',
        95,
        128,
      );
      final before = await fixture.reopen();
      final importer = CharacterImportWorkflow(
        navigation: fixture.navigation,
        picker: () async => picked,
        isActive: () => true,
        confirmImage: (_) async =>
            fail('Incompatible sheet must not request confirmation'),
        confirmSave: () async => true,
      );
      await importer.sheet();
      expect(fixture.navigation.error, contains('3 colonnes et 4 rangées'));
      expect(await fixture.reopen(), before);
      expect(fixture.navigation.busy, isFalse);
    },
  );

  test(
    'bicycle import retains four poses and the requested direction row',
    () async {
      final fixture = await AuthoringResourceFixture.create();
      addTearDown(fixture.dispose);
      final picked = await characterTestImage(
        fixture.directory,
        'Vélo',
        128,
        128,
      );
      final characterId = fixture.navigation.characters.selectedCharacter!.id;
      final importer = CharacterImportWorkflow(
        navigation: fixture.navigation,
        picker: () async => picked,
        isActive: () => true,
        confirmImage: (_) async => true,
        confirmSave: () async => true,
      );
      await importer.animation(
        CharacterAnimationState.bicycle,
        EntityFacing.north,
      );
      expect(fixture.navigation.error, isNull);
      final clip = (await fixture.reopen()).characters
          .singleWhere((entry) => entry.id == characterId)
          .animations
          .singleWhere(
            (entry) =>
                entry.state == CharacterAnimationState.bicycle &&
                entry.direction == EntityFacing.north,
          );
      expect(clip.frames, hasLength(4));
      expect(clip.frames.map((frame) => frame.source.x), [0, 32, 64, 96]);
      expect(
        clip.frames.every(
          (frame) =>
              frame.source.y == 96 &&
              frame.source.width == 32 &&
              frame.source.height == 32,
        ),
        isTrue,
      );
      expect(clip.frames.every((frame) => frame.durationMs == 100), isTrue);
    },
  );
  test('portrait saving gate blocks picker and confirmation until the existing write releases', () async {
    final fixture = await AuthoringResourceFixture.create();
    addTearDown(fixture.dispose);
    final navigation = fixture.navigation;
    final characters = navigation.characters;
    expect(await characters.createPortraitState('Expression test'), isTrue);
    final stateId = fixture
        .workspace
        .project!
        .characterStudioCatalog
        .portraitStates
        .singleWhere((state) => state.displayName == 'Expression test')
        .id;
    final picked = await characterTestImage(
      fixture.directory,
      'Portrait',
      64,
      64,
    );
    final before = await fixture.reopen();
    final draft = characters.selectedDraft!;
    var picks = 0;
    var confirmations = 0;
    final importer = CharacterImportWorkflow(
      navigation: navigation,
      picker: () async {
        picks++;
        return picked;
      },
      isActive: () => true,
      confirmImage: (_) async {
        confirmations++;
        return true;
      },
      confirmSave: () async => true,
    );
    characters.saving = true;
    addTearDown(() => characters.saving = false);
    await importer.portrait(stateId);
    expect(picks, 0);
    expect(confirmations, 0);
    expect(await fixture.reopen(), before);
    expect(characters.selectedDraft, same(draft));
    expect(draft.dirty, isFalse);
    characters.saving = false;
    await importer.portrait(stateId);
    expect(picks, 1);
    expect(confirmations, 1);
    expect(navigation.error, isNull);
    final character = (await fixture.reopen()).characters.singleWhere(
      (entry) => entry.id == characters.selectedId,
    );
    expect(
      character.portraits
          .singleWhere((entry) => entry.portraitStateId == stateId)
          .assetId,
      isNotEmpty,
    );
  });
}
