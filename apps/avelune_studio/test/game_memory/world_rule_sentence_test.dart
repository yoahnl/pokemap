import 'package:avelune_studio/features/game_memory/application/world_rule_sentence.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_labels.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

final class _Names implements WorldRuleNames {
  @override
  String? fact(String id) => const {'met': 'Rencontre avec Léo'}[id];

  @override
  String? event(String id) => const {'evt': 'Parler au guide'}[id];

  @override
  String? map(String id) => const {'town': 'Bourg Geon'}[id];
}

WorldRuleDefinition _rule(
  WorldRuleSource source, {
  WorldRuleTarget target = const WorldRuleTarget(
    kind: WorldRuleTargetKind.mapEntity,
    mapId: 'town',
    entityId: 'npc',
    label: 'Léo',
  ),
  WorldRuleEffectKind effect = WorldRuleEffectKind.entityHidden,
}) => WorldRuleDefinition(
  id: 'rule',
  label: 'Règle',
  source: source,
  target: target,
  effect: WorldRuleEffect(kind: effect),
);

void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));
  final names = _Names();

  test('a boolean fact rule reads as a French sentence', () {
    final rule = _rule(
      const WorldRuleSource(
        kind: WorldRuleSourceKind.fact,
        sourceId: 'met',
        predicate: WorldRuleSourcePredicate.isTrue,
      ),
    );

    final sentence = describeWorldRule(rule, names);

    final condition = sentence.condition as WorldRuleFactCondition;
    expect(condition.factName, 'Rencontre avec Léo');
    expect(condition.operator, NarrativeFactOperator.equals);
    expect(condition.value, const NarrativeValue.boolean(true));
    expect(sentence.consequence.targetName, 'Léo');
    expect(sentence.consequence.mapName, 'Bourg Geon');
    expect(
      fr.memoryRuleText(sentence),
      'Tant que « Rencontre avec Léo » est vrai, alors « Léo » (Bourg Geon) '
      'disparaît.',
    );
    expect(
      en.memoryRuleText(sentence),
      'While “Rencontre avec Léo” is true, then “Léo” (Bourg Geon) '
      'disappears.',
    );
  });

  test('a number comparison keeps its operator and value', () {
    final rule = _rule(
      WorldRuleSource.factValue(
        factId: 'met',
        operator: NarrativeFactOperator.greaterThanOrEqual,
        expectedValue: NarrativeValue.integer(3),
      ),
      effect: WorldRuleEffectKind.entityVisible,
    );

    expect(
      fr.memoryRuleText(describeWorldRule(rule, names)),
      'Tant que « Rencontre avec Léo » vaut au moins 3, alors « Léo » '
      '(Bourg Geon) apparaît.',
    );
  });

  test('a false boolean test and an event target are named', () {
    final rule = _rule(
      WorldRuleSource.factValue(
        factId: 'met',
        operator: NarrativeFactOperator.notEquals,
        expectedValue: const NarrativeValue.boolean(true),
      ),
      target: const WorldRuleTarget(
        kind: WorldRuleTargetKind.narrativeEvent,
        mapId: '',
        eventId: 'evt',
      ),
      effect: WorldRuleEffectKind.eventDisabled,
    );

    final sentence = describeWorldRule(rule, names);

    expect(sentence.consequence.mapName, isNull);
    expect(
      fr.memoryRuleText(sentence),
      'Tant que « Rencontre avec Léo » est faux, alors « Parler au guide » '
      'est inactif.',
    );
  });

  test('unknown names never fall back to raw identifiers', () {
    final rule = _rule(
      const WorldRuleSource(
        kind: WorldRuleSourceKind.fact,
        sourceId: 'gone',
        predicate: WorldRuleSourcePredicate.isTrue,
      ),
      target: const WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEntity,
        mapId: 'elsewhere',
        entityId: 'npc_42',
      ),
    );

    final text = fr.memoryRuleText(describeWorldRule(rule, names));

    expect(
      text,
      'Tant que un état introuvable est vrai, alors un personnage '
      'disparaît.',
    );
    expect(text, isNot(contains('gone')));
    expect(text, isNot(contains('npc_42')));
  });

  test('weekday and consumed event conditions are described', () {
    final weekday = describeWorldRule(
      _rule(
        WorldRuleSource.civilWeekday(
          weekday: CivilWeekday.sunday,
          expectedValue: false,
        ),
      ),
      names,
    );
    final consumed = describeWorldRule(
      _rule(
        const WorldRuleSource(
          kind: WorldRuleSourceKind.consumedEvent,
          sourceId: 'evt',
          predicate: WorldRuleSourcePredicate.consumed,
        ),
      ),
      names,
    );

    expect(
      fr.memoryRuleText(weekday),
      startsWith('Tant que on n’est pas dimanche, alors'),
    );
    expect(
      fr.memoryRuleText(consumed),
      startsWith('Tant que « Parler au guide » a déjà eu lieu, alors'),
    );
  });
}
