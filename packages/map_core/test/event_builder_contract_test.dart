import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Event Builder contract bindings', () {
    test('EventBuilderTriggerBinding refuses empty source ids', () {
      expect(
        () => EventBuilderSourceBinding(
          eventId: ' ',
          eventTitle: 'Rival',
          eventType: MapEventType.actor,
          position: const EventPosition(layerId: 'actors', x: 2, y: 3),
        ),
        throwsArgumentError,
      );
    });

    test('EventBuilderConditionBinding refuses empty ids', () {
      expect(
        () => EventBuilderConditionBinding.factIsTrue(' '),
        throwsArgumentError,
      );
      expect(
        () => EventBuilderConditionBinding.eventConsumed(' '),
        throwsArgumentError,
      );
    });

    test('EventBuilderSceneActionBinding refuses empty scene ids', () {
      expect(
        () => EventBuilderSceneActionBinding(sceneId: ' '),
        throwsArgumentError,
      );
    });

    test('EventBuilderBehaviorBinding supports oneShot and reusable', () {
      expect(
        const EventBuilderBehaviorBinding.oneShot().reusePolicy,
        EventBuilderReusePolicy.oneShot,
      );
      expect(
        const EventBuilderBehaviorBinding.reusable().reusePolicy,
        EventBuilderReusePolicy.reusable,
      );
    });

    test('fact conditions compile to script conditions', () {
      expect(
        EventBuilderConditionBinding.factIsTrue('fact_rival_seen')
            .toScriptCondition(),
        ScriptConditionFactory.flagIsSet('fact_rival_seen'),
      );
      expect(
        EventBuilderConditionBinding.factIsFalse('fact_rival_seen')
            .toScriptCondition(),
        ScriptConditionFactory.flagIsUnset('fact_rival_seen'),
      );
    });

    test('event consumed conditions compile to script conditions', () {
      expect(
        EventBuilderConditionBinding.eventConsumed('evt_rival')
            .toScriptCondition(),
        ScriptConditionFactory.eventIsConsumed('evt_rival'),
      );
      expect(
        EventBuilderConditionBinding.eventNotConsumed('evt_rival')
            .toScriptCondition(),
        ScriptConditionFactory.not(
          ScriptConditionFactory.eventIsConsumed('evt_rival'),
        ),
      );
    });

    test('story step conditions compile without pretending they are flags', () {
      final completed =
          EventBuilderConditionBinding.storyStepCompleted('step_go_port');
      final pending =
          EventBuilderConditionBinding.storyStepNotCompleted('step_go_port');

      expect(
        completed.toScriptCondition(),
        ScriptConditionFactory.stepCompleted('step_go_port'),
      );
      expect(
        pending.toScriptCondition(),
        ScriptConditionFactory.not(
          ScriptConditionFactory.stepCompleted('step_go_port'),
        ),
      );

      final result =
          compileEventBuilderConditionsToScriptCondition([completed, pending]);
      expect(result.condition?.type, ScriptConditionType.allOf);
      expect(result.condition?.children, hasLength(2));
      expect(result.diagnostics, isEmpty);
    });
  });
}
