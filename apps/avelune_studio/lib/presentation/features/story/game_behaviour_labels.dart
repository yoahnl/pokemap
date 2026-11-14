import 'package:avelune_studio/features/events/application/behaviour/behaviour_conditions.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_reuse.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_groups.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_rows.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_summary.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';

extension GameBehaviourLabels on AppLocalizations {
  String behaviourName(GameBehaviourRow row) =>
      row.name.trim().isEmpty ? behavioursUnnamed : row.name;

  String behaviourElement(GameBehaviourRow row) => switch (row.target) {
    null => behavioursWithoutMap,
    final target =>
      row.elementName ??
          behavioursElementKind(
            target == MapStoryElementTarget.map ? 'map' : target.name,
          ),
  };

  String behaviourPlace(GameBehaviourRow row) => row.mapId == null
      ? behavioursWithoutMap
      : behavioursPlace(
          row.mapName ?? behavioursMissingMap,
          behaviourElement(row),
        );

  String behaviourGroup(GameBehaviourGroup group) => switch (group.kind) {
    GameBehaviourGroupKind.map => group.label ?? behavioursMissingMap,
    GameBehaviourGroupKind.missingMap => behavioursMissingMap,
    GameBehaviourGroupKind.withoutMap => behavioursWithoutMap,
    GameBehaviourGroupKind.notLoaded => behavioursNotLoaded,
    GameBehaviourGroupKind.fact => group.label ?? behavioursUnnamedFact,
    GameBehaviourGroupKind.withoutFact => behavioursWithoutFact,
  };

  String behaviourSummary(
    GameBehaviourSummary summary,
    String? Function(String factId) factName,
  ) => behavioursSummary(
    storyTrigger(summary.when?.name ?? 'none'),
    summary.conditions.items.isEmpty
        ? storyAlways
        : [
            for (final item in summary.conditions.items)
              _condition(item, factName),
          ].join(', '),
    switch (summary.scene) {
      null when summary.sceneChosen => behavioursSceneNotFound,
      null => storySceneMissing,
      _ when summary.line => behavioursLineScene,
      final scene => memoryNamed(scene.name),
    },
    switch (summary.after) {
      null => storyReuseUnset,
      BehaviourAfter.once => storyOnce,
      BehaviourAfter.eachTime => storyEachTime,
      BehaviourAfter.oncePerVisit => storyOncePerVisit,
      BehaviourAfter.onceUntilOutcome => storyOnceUntilOutcome,
    },
  );

  String _condition(
    BehaviourConditionItem item,
    String? Function(String factId) factName,
  ) => switch (item) {
    BehaviourEditableCondition(:final factId, :final test, :final number) =>
      memoryConditionFact(
        switch (factName(factId)) {
          final name? => memoryNamed(name),
          null => memoryUnknownFact,
        },
        switch (test) {
          BehaviourConditionTest.isTrue => memoryBooleanTest('true'),
          BehaviourConditionTest.isFalse => memoryBooleanTest('false'),
          BehaviourConditionTest.equalsNumber => memoryComparison(
            'equals',
            '$number',
          ),
        },
      ),
    BehaviourFixedCondition() => behavioursAdvancedCondition,
  };
}
