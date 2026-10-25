import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/features/characters/character_studio_controller.dart';

import '../support/map_workspace_fixture.dart';
import '../resource_io/resource_fixture.dart';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';

void main() {
  const character = ProjectCharacterEntry(
    id: 'agent',
    name: 'Agent',
    tilesetId: 'atlas',
  );

  test('clean character drafts refresh contact shadow after external catalog changes', () {
    var project = workspaceProject.copyWith(characters: [character]);
    final controller = CharacterStudioController(
      project: () => project,
      mutate: (_, _) async => project,
    );
    addTearDown(controller.dispose);
    expect(controller.selectedDraft!.contactShadow, isNull);
    project = project.copyWith(
      characters: [character.copyWith(contactShadow: true)],
    );
    controller.reconcileCatalog(project);
    expect(controller.selectedDraft!.contactShadow, isTrue);
    expect(controller.dirty, isFalse);
  });

  test('editor local adapter persists project default and character overrides canonically', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    final imported = await fixture.import();
    var project = (await fixture.resources.mutate(
      'characterStudio.character.create',
      {'name': 'Agent', 'tilesetId': imported.createdTilesetId},
    )).manifest;
    final controller = CharacterStudioController(
      project: () => project,
      mutate: (action, params) async {
        project = (await fixture.resources.mutate(action, params)).manifest;
        return project;
      },
    );
    addTearDown(controller.dispose);
    expect(project.settings.actorContactShadowsByDefault, isFalse);
    expect(project.characters.single.contactShadow, isNull);
    expect(
      await controller.setContactShadowsByDefault(true),
      isTrue,
      reason: controller.error,
    );
    controller.setContactShadow(false);
    expect(await controller.saveSelected(), isTrue, reason: controller.error);
    final reopened = await LocalMapWorkspaceAdapter().loadProject(
      fixture.session,
    );
    expect(reopened.settings.actorContactShadowsByDefault, isTrue);
    expect(reopened.characters.single.contactShadow, isFalse);
    controller.setContactShadow(null);
    expect(await controller.saveSelected(), isTrue, reason: controller.error);
    final inherited = await LocalMapWorkspaceAdapter().loadProject(
      fixture.session,
    );
    expect(inherited.characters.single.contactShadow, isNull);
    expect(inherited.settings.actorContactShadowsByDefault, isTrue);
  });

  test(
    'contact shadow edits remain drafts until the character is saved',
    () async {
      var project = workspaceProject.copyWith(characters: [character]);
      final calls = <(String, Map<String, Object?>)>[];
      final controller = CharacterStudioController(
        project: () => project,
        mutate: (action, params) async {
          calls.add((action, params));
          project = project.copyWith(
            characters: [
              ProjectCharacterEntry.fromJson({
                ...project.characters.single.toJson(),
                'contactShadow': params['contactShadow'],
              }),
            ],
          );
          return project;
        },
      );
      addTearDown(controller.dispose);
      controller.setContactShadow(true);
      expect(controller.dirty, isTrue);
      expect(calls, isEmpty);
      expect(await controller.saveSelected(), isTrue);
      expect(calls.single.$1, 'characterStudio.character.update');
      expect(calls.single.$2, {'characterId': 'agent', 'contactShadow': true});
      expect(controller.dirty, isFalse);
      controller.setContactShadow(null);
      expect(await controller.saveSelected(), isTrue);
      expect(calls.last.$2, {'characterId': 'agent', 'contactShadow': null});
      expect(controller.dirty, isFalse);
    },
  );

  test(
    'project default uses the canonical action and reports save failure',
    () async {
      final calls = <(String, Map<String, Object?>)>[];
      final controller = CharacterStudioController(
        project: () => workspaceProject,
        mutate: (action, params) async {
          calls.add((action, params));
          throw StateError('Enregistrement refusé');
        },
      );
      addTearDown(controller.dispose);
      expect(await controller.setContactShadowsByDefault(true), isFalse);
      expect(calls.single.$1, 'project.actor_contact_shadows.configure');
      expect(calls.single.$2, {'enabled': true});
      expect(controller.error, contains('Enregistrement refusé'));
      expect(controller.saving, isFalse);
    },
  );
}
