import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Event Builder authoring operations', () {
    test('reads legacy event without Event Builder metadata', () {
      final event = _event(
        page: const MapEventPage(pageNumber: 0),
      );

      final contract = readEventBuilderContractFromMapEvent(event);

      expect(contract.source.eventId, 'evt_rival');
      expect(contract.sceneAction, isNull);
      expect(contract.behavior.reusePolicy, EventBuilderReusePolicy.oneShot);
      expect(
        contract.diagnostics.single.kind,
        EventBuilderContractDiagnosticKind.missingSceneAction,
      );
    });

    test('reads scene action from MapEventPage.sceneTarget', () {
      final event = _event(
        page: const MapEventPage(
          pageNumber: 0,
          sceneTarget: MapEventSceneTarget(sceneId: 'scene_rival'),
        ),
      );

      final contract = readEventBuilderContractFromMapEvent(event);

      expect(contract.sceneAction?.sceneId, 'scene_rival');
      expect(contract.diagnostics, isEmpty);
    });

    test('applies scene action without deleting legacy script or message', () {
      final event = _event(
        page: const MapEventPage(
          pageNumber: 0,
          script: ScriptRef(scriptId: 'legacy_script'),
          message: 'legacy message',
          metadata: {'legacy': 'keep'},
        ),
      );
      final contract = readEventBuilderContractFromMapEvent(event).copyWith(
        sceneAction: EventBuilderSceneActionBinding(
          sceneId: 'scene_rival',
        ),
        behavior: const EventBuilderBehaviorBinding.reusable(),
      );

      final updated = applyEventBuilderContractToMapEvent(event, contract);
      final page = updated.pages.single;

      expect(
          page.sceneTarget, const MapEventSceneTarget(sceneId: 'scene_rival'));
      expect(page.script, const ScriptRef(scriptId: 'legacy_script'));
      expect(page.message, 'legacy message');
      expect(page.metadata['legacy'], 'keep');
      expect(
        page.metadata[EventBuilderMetadataKeys.reusePolicy],
        EventBuilderReusePolicy.reusable.name,
      );
    });

    test('compiles supported conditions into allOf ScriptCondition', () {
      final event = _event(
        page: const MapEventPage(pageNumber: 0),
      );
      final contract = readEventBuilderContractFromMapEvent(event).copyWith(
        sceneAction: EventBuilderSceneActionBinding(
          sceneId: 'scene_rival',
        ),
        conditions: [
          EventBuilderConditionBinding.factIsTrue('fact_started'),
          EventBuilderConditionBinding.eventNotConsumed('evt_rival'),
        ],
      );

      final updated = applyEventBuilderContractToMapEvent(event, contract);
      final condition = updated.pages.single.condition;

      expect(condition?.type, ScriptConditionType.allOf);
      expect(
        condition?.children,
        [
          ScriptConditionFactory.flagIsSet('fact_started'),
          ScriptConditionFactory.not(
            ScriptConditionFactory.eventIsConsumed('evt_rival'),
          ),
        ],
      );
    });

    test('preserves unknown metadata when applying contract', () {
      final event = _event(
        page: const MapEventPage(
          pageNumber: 0,
          metadata: {'customKey': 'customValue'},
        ),
      );
      final contract = readEventBuilderContractFromMapEvent(event).copyWith(
        sceneAction: EventBuilderSceneActionBinding(
          sceneId: 'scene_rival',
        ),
      );

      final updated = applyEventBuilderContractToMapEvent(event, contract);

      expect(updated.pages.single.metadata['customKey'], 'customValue');
      expect(
        updated.pages.single.metadata[EventBuilderMetadataKeys.schemaVersion],
        EventBuilderMetadataKeys.currentSchemaVersion,
      );
    });

    test('does not apply unsupported story step condition as opaque flag', () {
      final event = _event(
        page: const MapEventPage(pageNumber: 0),
      );
      final contract = readEventBuilderContractFromMapEvent(event).copyWith(
        sceneAction: EventBuilderSceneActionBinding(
          sceneId: 'scene_rival',
        ),
        conditions: [
          EventBuilderConditionBinding.storyStepCompleted('step_go_port'),
        ],
      );

      expect(
        () => applyEventBuilderContractToMapEvent(event, contract),
        throwsUnsupportedError,
      );
    });

    test('keeps malformed legacy conditions as diagnostic instead of crashing',
        () {
      final malformedLegacyCondition = ScriptConditionFactory.not(
        ScriptConditionFactory.allOf([
          ScriptConditionFactory.eventIsConsumed('evt_a'),
          ScriptConditionFactory.eventIsConsumed('evt_b'),
        ]),
      );
      final event = _event(
        page: MapEventPage(
          pageNumber: 0,
          condition: malformedLegacyCondition,
        ),
      );

      final contract = readEventBuilderContractFromMapEvent(event);

      expect(contract.conditions, isEmpty);
      expect(contract.legacyConditionToPreserve, malformedLegacyCondition);
      expect(
        contract.diagnostics.map((diagnostic) => diagnostic.kind),
        contains(EventBuilderContractDiagnosticKind.unsupportedLegacyCondition),
      );
    });
  });
}

MapEventDefinition _event({required MapEventPage page}) {
  return MapEventDefinition(
    id: 'evt_rival',
    title: 'Rival au port',
    position: const EventPosition(layerId: 'events', x: 4, y: 5),
    type: MapEventType.actor,
    pages: [page],
  );
}
