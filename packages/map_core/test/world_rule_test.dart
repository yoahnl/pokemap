import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('WorldRuleDefinition', () {
    test('creates a declarative authoring rule with stable metadata', () {
      final rule = WorldRuleDefinition(
        id: 'world_rule_hide_rival',
        label: 'Masquer le rival apres combat',
        description: 'Le rival disparait quand le combat est termine.',
        enabled: false,
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.fact,
          sourceId: 'fact_rival_defeated',
          predicate: WorldRuleSourcePredicate.isTrue,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: 'map_port',
          entityId: 'entity_rival',
        ),
        effect: const WorldRuleEffect(
          kind: WorldRuleEffectKind.entityHidden,
        ),
        priority: 20,
        tags: const ['rival', 'port', 'rival'],
        debugTechnicalLabel: 'story_flag.rival_defeated',
      );

      expect(rule.id, 'world_rule_hide_rival');
      expect(rule.label, 'Masquer le rival apres combat');
      expect(rule.enabled, isFalse);
      expect(rule.priority, 20);
      expect(rule.tags, ['rival', 'port']);
      expect(rule.debugTechnicalLabel, 'story_flag.rival_defeated');
      expect(rule.source.sourceId, 'fact_rival_defeated');
      expect(rule.target.entityId, 'entity_rival');
      expect(rule.effect.kind, WorldRuleEffectKind.entityHidden);
    });

    test('rejects empty top-level id and label', () {
      expect(
        () => WorldRuleDefinition(
          id: ' ',
          label: 'Rule',
          source: const WorldRuleSource(
            kind: WorldRuleSourceKind.fact,
            sourceId: 'fact_known',
            predicate: WorldRuleSourcePredicate.isTrue,
          ),
          target: const WorldRuleTarget(
            kind: WorldRuleTargetKind.mapEntity,
            mapId: 'map_test',
            entityId: 'entity_test',
          ),
          effect: const WorldRuleEffect(
            kind: WorldRuleEffectKind.entityVisible,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => WorldRuleDefinition(
          id: 'world_rule_valid',
          label: '',
          source: const WorldRuleSource(
            kind: WorldRuleSourceKind.fact,
            sourceId: 'fact_known',
            predicate: WorldRuleSourcePredicate.isTrue,
          ),
          target: const WorldRuleTarget(
            kind: WorldRuleTargetKind.mapEntity,
            mapId: 'map_test',
            entityId: 'entity_test',
          ),
          effect: const WorldRuleEffect(
            kind: WorldRuleEffectKind.entityVisible,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('round-trips through JSON', () {
      final rule = WorldRuleDefinition(
        id: 'world_rule_dialogue',
        label: 'Dialogue apres etape',
        description: 'Le PNJ utilise un dialogue alternatif.',
        source: const WorldRuleSource(
          kind: WorldRuleSourceKind.storyStepCompletion,
          sourceId: 'step_intro',
          predicate: WorldRuleSourcePredicate.completed,
        ),
        target: const WorldRuleTarget(
          kind: WorldRuleTargetKind.npcDialogue,
          mapId: 'map_harbor',
          entityId: 'npc_captain',
        ),
        effect: const WorldRuleEffect(
          kind: WorldRuleEffectKind.npcDialogueOverride,
          dialogueId: 'dialogue_after_intro',
        ),
        priority: 4,
        tags: const ['dialogue'],
      );

      final json =
          jsonDecode(jsonEncode(rule.toJson())) as Map<String, dynamic>;
      final decoded = WorldRuleDefinition.fromJson(json);

      expect(decoded, equals(rule));
      expect(decoded.toJson()['id'], 'world_rule_dialogue');
      expect(decoded.toJson()['source'], isA<Map<String, dynamic>>());
      expect(decoded.toJson()['target'], isA<Map<String, dynamic>>());
      expect(decoded.toJson()['effect'], isA<Map<String, dynamic>>());
    });
  });
}
