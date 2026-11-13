import 'package:avelune_studio/features/scenes/application/steps/scene_step_families.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'scene_step_fixtures.dart';

void main() {
  final catalog = NarrativeCommandCatalog.canonical();

  test('every catalog command has a family', () {
    final missing = [
      for (final command in catalog.commands)
        if (sceneStepFamilyOfCommand(command.id) == null) command.id,
    ];
    expect(missing, isEmpty);
    expect(catalog.commands, hasLength(greaterThan(50)));
  });

  test('the family table names no command outside the catalog', () {
    final known = {for (final command in catalog.commands) command.id};
    expect(
      sceneStepCommandFamilies.keys.where((id) => !known.contains(id)),
      isEmpty,
    );
  });

  test('every family except conditions groups catalog commands', () {
    final used = sceneStepCommandFamilies.values.toSet();
    expect(SceneStepFamily.values.where((family) => !used.contains(family)), [
      SceneStepFamily.conditions,
    ]);
  });

  test('nodes are classified through their command', () {
    expect(sceneStepFamilyOfNode(factNode('f')), SceneStepFamily.rememberFact);
    expect(sceneStepFamilyOfNode(dialogueNode('d')), SceneStepFamily.talk);
    expect(
      sceneStepFamilyOfNode(soundNode('s')),
      SceneStepFamily.musicAndSound,
    );
    expect(sceneStepFamilyOfNode(giveNode('g')), SceneStepFamily.giveItem);
    expect(sceneStepFamilyOfNode(battleNode('b')), SceneStepFamily.battle);
    expect(
      sceneStepFamilyOfNode(conditionNode('c')),
      SceneStepFamily.conditions,
    );
    expect(
      sceneStepCommandIdOf(giveNode('g')),
      NarrativeCommandIds.giveItemGift,
    );
    expect(
      sceneStepFamilyOfNode(
        SceneNode(
          id: 'hide',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setNpcPresence(
              mapId: 'town',
              entityId: 'npc',
              present: false,
            ),
          ),
        ),
      ),
      SceneStepFamily.showOrHide,
    );
  });

  test('nodes without a catalog command are advanced and kept as other', () {
    final presentation = SceneNode(
      id: 'show',
      kind: SceneNodeKind.presentationCinematic,
      payload: ScenePresentationCinematicPayload(
        presentationCinematicId: 'intro',
      ),
    );
    final legacy = SceneNode(
      id: 'legacy',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload(actionKind: 'custom'),
    );
    final wild = SceneNode(
      id: 'wild',
      kind: SceneNodeKind.battle,
      payload: SceneBattlePayload(battleKind: 'wild'),
    );
    for (final node in [presentation, legacy, mergeNode('m')]) {
      expect(sceneStepIsAdvanced(node), isTrue);
      expect(sceneStepFamilyOfNode(node), SceneStepFamily.other);
    }
    expect(sceneStepIsAdvanced(wild), isTrue);
    expect(sceneStepFamilyOfNode(wild), SceneStepFamily.battle);
    expect(sceneStepIsAdvanced(factNode('f')), isFalse);
    expect(sceneStepIsAdvanced(conditionNode('c')), isFalse);
  });
}
