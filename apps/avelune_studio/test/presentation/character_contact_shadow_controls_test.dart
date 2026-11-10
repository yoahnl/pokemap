import 'package:avelune_studio/features/characters/coordination/character_studio_controller.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('project default publishes immediately while character override remains a separate draft', () async {
    var project = workspaceProject.copyWith(
      settings: ProjectSettings(dimension: ProjectDimension.threeD),
      characters: [
        const ProjectCharacterEntry(
          id: 'agent',
          name: 'Agent',
          tilesetId: 'atlas',
        ),
      ],
    );
    final calls = <(String, Map<String, Object?>)>[];
    final controller = CharacterStudioController(
      project: () => project,
      mutate: (action, params) async {
        calls.add((action, params));
        if (action == 'project.actor_contact_shadows.configure') {
          project = project.copyWith(
            settings: project.settings.copyWith(
              actorContactShadowsByDefault: params['enabled'] as bool,
            ),
          );
        } else {
          project = project.copyWith(
            characters: [
              project.characters.single.copyWith(
                contactShadow: params['contactShadow'] as bool?,
              ),
            ],
          );
        }
        return project;
      },
    )..setSection(CharacterStudioSection.identity);
    addTearDown(controller.dispose);

    expect(project.settings.actorContactShadowsByDefault, isFalse);
    expect(controller.selectedDraft!.contactShadow, isNull);
    expect(await controller.setContactShadowsByDefault(true), isTrue);
    expect(calls.single.$1, 'project.actor_contact_shadows.configure');
    expect(calls.single.$2, {'enabled': true});
    expect(project.settings.actorContactShadowsByDefault, isTrue);
    expect(controller.selectedDraft!.contactShadow, isNull);
    controller.setContactShadow(false);
    expect(calls, hasLength(1));
    expect(controller.dirty, isTrue);
    expect(await controller.saveSelected(), isTrue);
    expect(calls.last.$1, 'characterStudio.character.update');
    expect(calls.last.$2, {'characterId': 'agent', 'contactShadow': false});
    expect(project.characters.single.contactShadow, isFalse);
    expect(controller.dirty, isFalse);
    controller.setContactShadow(null);
    expect(await controller.saveSelected(), isTrue);
    expect(calls.last.$2, {'characterId': 'agent', 'contactShadow': null});
    expect(project.characters.single.contactShadow, isNull);
    expect(project.settings.actorContactShadowsByDefault, isTrue);
    expect(controller.dirty, isFalse);
  });
}
