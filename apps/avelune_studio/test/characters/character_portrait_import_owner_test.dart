import 'package:avelune_studio/features/characters/coordination/character_import_workflow.dart';
import 'package:avelune_studio/features/characters/coordination/character_studio_portrait_actions.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/authoring_resource_fixture.dart';
import '../support/character_test_image.dart';

void main() {
  test('portrait import binds a real image and survives independent reopen', () async {
    final fixture = await AuthoringResourceFixture.create();
    addTearDown(fixture.dispose);
    final navigation = fixture.navigation;
    final characters = navigation.characters;
    final tilesetId = fixture.workspace.project!.tilesets.first.id;
    expect(
      await characters.create('Élia', tilesetId, frameWidth: 1, frameHeight: 1),
      isTrue,
    );
    expect(await characters.createPortraitState('Souriante'), isTrue);
    final state = fixture.workspace.project!.characterStudioCatalog.portraitStates
        .single;
    expect(state.displayName, 'Souriante');

    final picture = await characterTestImage(fixture.directory, 'portrait', 24, 32);
    await CharacterImportWorkflow(
      navigation: navigation,
      picker: () async => picture,
      isActive: () => true,
      confirmImage: (_) async => true,
      confirmSave: () async => true,
    ).portrait(state.id);

    expect(characters.error, isNull);
    expect(navigation.error, isNull);
    final saved = fixture.workspace.project!;
    final character = saved.characters.firstWhere((entry) => entry.name == 'Élia');
    expect(character.portraits.single.portraitStateId, state.id);
    expect(character.portraits.single.assetId, isNotEmpty);

    final reader = LocalMapWorkspaceAdapter();
    final reopened = await reader.loadProject(fixture.session);
    expect(
      reopened.characters.firstWhere((entry) => entry.id == character.id).portraits,
      character.portraits,
    );
    final portraitBytes = await LocalDialogueAdapter(
      session: fixture.session,
      mapAdapter: reader,
    ).readPortrait(character.id, state.id);
    expect(portraitBytes, isNotNull);
    expect(portraitBytes, isNotEmpty);
  });
}
