import 'package:map_core/map_core_domain.dart';

import 'scene_step_families.dart';

typedef SceneStepTemplate = ({SceneNodeKind kind, SceneNodePayload payload});

const sceneInsertableStepFamilies = [
  SceneStepFamily.rememberFact,
  SceneStepFamily.talk,
  SceneStepFamily.showOrHide,
  SceneStepFamily.battle,
  SceneStepFamily.conditions,
];

SceneConditionPayload? sceneDefaultCondition(ProjectManifest project) {
  final fact = project.facts
      .where((fact) => fact.initialValue.kind == NarrativeValueKind.boolean)
      .firstOrNull;
  if (fact == null) return null;
  return SceneConditionPayload(
    conditionLabel: fact.label,
    conditionRef: fact.id,
    conditionSource: SceneConditionSource(
      sourceKind: SceneConditionSourceKind.fact,
      sourceId: fact.id,
      operator: SceneConditionOperator.isTrue,
      label: fact.label,
    ),
  );
}

SceneStepTemplate? sceneStepTemplateOf(
  SceneStepFamily family,
  ProjectManifest project,
  MapData? map,
) {
  switch (family) {
    case SceneStepFamily.rememberFact:
      final factId = project.facts
          .where((fact) => fact.initialValue.kind == NarrativeValueKind.boolean)
          .firstOrNull
          ?.id;
      return factId == null
          ? null
          : (
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(factId: factId, value: true),
              ),
            );
    case SceneStepFamily.talk:
      final dialogue = project.dialogues.firstOrNull;
      return dialogue == null
          ? null
          : (
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(dialogueId: dialogue.id),
            );
    case SceneStepFamily.showOrHide:
      final entity = map?.entities
          .where((entity) => entity.npc != null)
          .firstOrNull;
      return map == null || entity == null
          ? null
          : (
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setNpcPresence(
                  mapId: map.id,
                  entityId: entity.id,
                  present: true,
                ),
              ),
            );
    case SceneStepFamily.battle:
      final trainer = project.trainers.firstOrNull;
      return trainer == null
          ? null
          : (
              kind: SceneNodeKind.battle,
              payload: SceneBattlePayload(
                battleKind: 'trainer',
                trainerId: trainer.id,
              ),
            );
    case SceneStepFamily.conditions:
      final condition = sceneDefaultCondition(project);
      return condition == null
          ? null
          : (kind: SceneNodeKind.condition, payload: condition);
    case SceneStepFamily.musicAndSound:
    case SceneStepFamily.giveItem:
    case SceneStepFamily.other:
      return null;
  }
}
