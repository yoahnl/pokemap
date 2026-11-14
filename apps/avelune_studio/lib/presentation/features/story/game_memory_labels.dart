import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/game_memory/application/world_rule_sentence.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';

extension GameMemoryLabels on AppLocalizations {
  String memoryKind(NarrativeValueKind kind) => memoryValueKind(kind.wireName);

  String memoryValue(NarrativeValue value) => switch (value.kind) {
    NarrativeValueKind.boolean => memoryBoolean('${value.boolValue}'),
    NarrativeValueKind.integer => '${value.intValue}',
    NarrativeValueKind.string => memoryNamed(value.stringValue),
  };

  String memoryOwner(NarrativeOwner owner, String? name) =>
      name ?? memoryOwnerUnnamed(memoryOwnerKind(owner.kind.name));

  String memoryCoverage(List<String> sources) =>
      memoryNotCovered(sources.map(memoryCoverageSource).toSet().join(', '));

  String memoryRuleText(WorldRuleSentence sentence) => memoryRuleSentence(
    _condition(sentence.condition),
    _effect(sentence.consequence),
  );

  String _condition(WorldRuleCondition condition) => switch (condition) {
    WorldRuleFactCondition(:final factName, :final operator, :final value) =>
      memoryConditionFact(
        factName == null ? memoryUnknownFact : memoryNamed(factName),
        value.kind == NarrativeValueKind.boolean &&
                (operator == NarrativeFactOperator.equals ||
                    operator == NarrativeFactOperator.notEquals)
            ? memoryBooleanTest(
                '${value.boolValue == (operator == NarrativeFactOperator.equals)}',
              )
            : memoryComparison(operator.name, memoryValue(value)),
      ),
    WorldRuleWeekdayCondition(:final weekday, :final expected) =>
      memoryConditionWeekday(
        weekday == null ? memoryAnyDay : memoryWeekday(weekday.name),
        '$expected',
      ),
    WorldRuleStepCondition(:final completed) => memoryConditionStep(
      '$completed',
    ),
    WorldRuleEventCondition(:final eventName, :final consumed) =>
      memoryConditionEvent(
        eventName == null ? memoryUnknownEvent : memoryNamed(eventName),
        '$consumed',
      ),
    WorldRuleRewardCondition(:final available) => memoryConditionReward(
      '$available',
    ),
  };

  String _effect(WorldRuleConsequence consequence) {
    final map = consequence.mapName;
    final name = consequence.targetName;
    if (consequence.effect == WorldRuleEffectKind.atmosphere) {
      return map == null
          ? memoryEffectAtmosphereSomewhere
          : memoryEffectAtmosphere(map);
    }
    final target = switch (consequence.target) {
      WorldRuleTargetKind.narrativeEvent || WorldRuleTargetKind.mapEvent =>
        name == null ? memoryUnknownEvent : memoryNamed(name),
      _ => switch ((name, map)) {
        (final name?, final map?) => memoryTargetCharacter(name, map),
        (final name?, null) => memoryNamed(name),
        (null, final map?) => memoryTargetUnnamedCharacter(map),
        (null, null) => memoryUnknownCharacter,
      },
    };
    return memoryEffect(target, memoryEffectKind(consequence.effect.name));
  }
}
