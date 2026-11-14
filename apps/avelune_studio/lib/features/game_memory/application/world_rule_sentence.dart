import 'package:map_core/map_core_domain.dart';

sealed class WorldRuleCondition {
  const WorldRuleCondition();
}

final class WorldRuleFactCondition extends WorldRuleCondition {
  const WorldRuleFactCondition({
    required this.factName,
    required this.operator,
    required this.value,
  });

  final String? factName;
  final NarrativeFactOperator operator;
  final NarrativeValue value;
}

final class WorldRuleWeekdayCondition extends WorldRuleCondition {
  const WorldRuleWeekdayCondition(this.weekday, {required this.expected});

  final CivilWeekday? weekday;
  final bool expected;
}

final class WorldRuleStepCondition extends WorldRuleCondition {
  const WorldRuleStepCondition({required this.completed});

  final bool completed;
}

final class WorldRuleEventCondition extends WorldRuleCondition {
  const WorldRuleEventCondition(this.eventName, {required this.consumed});

  final String? eventName;
  final bool consumed;
}

final class WorldRuleRewardCondition extends WorldRuleCondition {
  const WorldRuleRewardCondition({required this.available});

  final bool available;
}

final class WorldRuleConsequence {
  const WorldRuleConsequence({
    required this.effect,
    required this.target,
    this.targetName,
    this.mapName,
  });

  final WorldRuleEffectKind effect;
  final WorldRuleTargetKind target;
  final String? targetName;
  final String? mapName;
}

final class WorldRuleSentence {
  const WorldRuleSentence(this.condition, this.consequence);

  final WorldRuleCondition condition;
  final WorldRuleConsequence consequence;
}

abstract interface class WorldRuleNames {
  String? fact(String id);

  String? event(String id);

  String? map(String id);
}

WorldRuleSentence describeWorldRule(
  WorldRuleDefinition rule,
  WorldRuleNames names,
) {
  final source = rule.source;
  final positive = source.predicate == WorldRuleSourcePredicate.isTrue;
  final condition = switch (source.kind) {
    WorldRuleSourceKind.fact => WorldRuleFactCondition(
      factName: names.fact(source.sourceId),
      operator: source.resolvedFactOperator,
      value: source.resolvedExpectedFactValue,
    ),
    WorldRuleSourceKind.civilWeekday => WorldRuleWeekdayCondition(
      source.weekday,
      expected: positive,
    ),
    WorldRuleSourceKind.storyStepCompletion => WorldRuleStepCondition(
      completed: source.predicate == WorldRuleSourcePredicate.completed,
    ),
    WorldRuleSourceKind.consumedEvent => WorldRuleEventCondition(
      names.event(source.sourceId),
      consumed: source.predicate == WorldRuleSourcePredicate.consumed,
    ),
    WorldRuleSourceKind.periodicRewardAvailable => WorldRuleRewardCondition(
      available: positive,
    ),
  };
  final target = rule.target;
  final label = target.label?.trim();
  return WorldRuleSentence(
    condition,
    WorldRuleConsequence(
      effect: rule.effect.kind,
      target: target.kind,
      targetName: label != null && label.isNotEmpty
          ? label
          : switch (target.kind) {
              WorldRuleTargetKind.narrativeEvent ||
              WorldRuleTargetKind.mapEvent => switch (target.eventId) {
                final id? => names.event(id),
                null => null,
              },
              _ => null,
            },
      mapName: target.kind == WorldRuleTargetKind.narrativeEvent
          ? null
          : names.map(target.mapId),
    ),
  );
}
