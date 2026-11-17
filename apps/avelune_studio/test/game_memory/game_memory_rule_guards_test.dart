import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'game_memory_fakes.dart';

WorldRuleDefinition guardedRule([WorldRuleSource? source]) =>
    WorldRuleDefinition(
      id: 'world_rule_test',
      label: 'Présence',
      source:
          source ??
          const WorldRuleSource(
            kind: WorldRuleSourceKind.fact,
            sourceId: 'met',
            predicate: WorldRuleSourcePredicate.isTrue,
          ),
      target: const WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEntity,
        mapId: 'a',
        entityId: 'guide',
      ),
      effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
    );

void main() {
  late FakeNarrativeIndex index;
  late FakeMemoryStaging staging;
  late GameMemoryController memory;

  setUp(() async {
    index = FakeNarrativeIndex()..addFacts([memoryFact('met', 'Rencontre')]);
    index.rules = [guardedRule()];
    staging = FakeMemoryStaging();
    memory = GameMemoryController(
      port: index,
      staging: staging,
      changed: () {},
    );
    addTearDown(memory.dispose);
    await memory.open();
    await memory.rules.open();
    memory.select('met');
    await Future<void>.delayed(Duration.zero);
  });

  test('an incompatible typed condition is refused without coercion', () {
    expect(
      memory.rules.update(
        'world_rule_test',
        condition: (
          factId: 'met',
          operator: NarrativeFactOperator.equals,
          value: NarrativeValue.integer(7),
        ),
      ),
      isFalse,
    );
    expect(staging.draft.touchedRefs, isEmpty);
    expect(memory.rules.rule('world_rule_test'), same(index.rules.single));
  });

  test(
    'unknown facts and incompatible effects keep the saved rule untouched',
    () {
      expect(
        memory.rules.update(
          'world_rule_test',
          condition: (
            factId: 'missing',
            operator: NarrativeFactOperator.equals,
            value: const NarrativeValue.boolean(true),
          ),
        ),
        isFalse,
      );
      expect(
        memory.rules.update(
          'world_rule_test',
          effect: WorldRuleEffectKind.eventEnabled,
        ),
        isFalse,
      );
      expect(staging.draft.touchedRefs, isEmpty);
    },
  );

  test(
    'a non-editable source can be renamed without becoming a fact condition',
    () async {
      const source = WorldRuleSource(
        kind: WorldRuleSourceKind.consumedEvent,
        sourceId: 'evt_missing',
        predicate: WorldRuleSourcePredicate.notConsumed,
        debugTechnicalLabel: 'preserve',
      );
      index.rules = [guardedRule(source)];
      await memory.rules.retry();
      expect(
        memory.rules.update('world_rule_test', label: 'Nouveau libellé'),
        isTrue,
      );
      expect(memory.rules.rule('world_rule_test')!.source, same(source));
      expect(
        memory.rules.update(
          'world_rule_test',
          condition: (
            factId: 'met',
            operator: NarrativeFactOperator.equals,
            value: const NarrativeValue.boolean(true),
          ),
        ),
        isFalse,
      );
      expect(memory.rules.rule('world_rule_test')!.source, same(source));
    },
  );
}
