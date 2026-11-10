import 'dart:convert';

import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/application/event_simulation_session.dart';
import 'package:avelune_studio/features/events/application/event_condition_editing.dart';
import 'package:avelune_studio/features/events/application/event_labels.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/event_backend_fixture.dart';
import 'support/ui06_scene_fixture.dart';

Future<EventBackendFixture> prepared() async {
  final fixture = await EventBackendFixture.create();
  addTearDown(fixture.dispose);
  final controller = fixture.attach();
  expect(await controller.prepareAllMaps(), isTrue, reason: controller.error);
  return fixture;
}

void main() {
  test('condition scope supplies an owner only for entity sources', () async {
    final fixture = await prepared();
    final document = fixture.workspace.documents.values.first;
    final owner = MapEntityEditingCommands(
      document,
      fixture.workspace.project!,
    ).place(MapEntityKind.sign, const GridPos(x: 1, y: 1));
    final controller = fixture.controller!;
    for (final entitySource in [true, false]) {
      final record = controller.create(
        'Conditions',
        source: entitySource
            ? NarrativeEventSourceRef.entityInteract(
                document.current.id,
                owner.id,
              )
            : NarrativeEventSourceRef.mapEnter(document.current.id),
      )!;
      final scope = eventConditionOwner(record.source);
      expect(scope.entityId, entitySource ? owner.id : null);
      expect(scope.mapId, entitySource ? document.current.id : null);
    }
  });

  test(
    'local simulation uses real owners and reports an absent instance',
    () async {
      final fixture = await prepared();
      final controller = fixture.controller!;
      final map = controller.maps.firstWhere((map) => map.entities.isNotEmpty);
      final owner = map.entities.first;
      expect(controller.setEnabled(Ui06SceneFixture.eventId, false), isTrue);
      expect(
        controller.setExpression(
          Ui06SceneFixture.eventId,
          NarrativeEventConditionExpression.leaf(
            NarrativeEventCondition.mapEventInstanceBoolean(
              mapId: map.id,
              eventId: owner.id,
              key: 'opened',
              expectedValue: true,
            ),
          ),
        ),
        isTrue,
        reason: controller.error,
      );
      expect(
        controller.setEnabled(Ui06SceneFixture.eventId, true),
        isTrue,
        reason: controller.error,
      );
      final bytes = jsonEncode(controller.project.toJson());
      final simulation = EventSimulationSession(
        controller,
        Ui06SceneFixture.eventId,
      );
      expect(
        simulation.localConditions,
        contains((map.id, owner.id, 'opened')),
      );
      simulation.run();
      expect(simulation.report!.handledEventId, isNull);
      simulation.setLocalBoolean(map.id, owner.id, 'opened', true);
      expect(simulation.report, isNull);
      simulation.run();
      expect(simulation.report!.handledEventId, Ui06SceneFixture.eventId);
      simulation.setMapAbsent(map.id, true);
      simulation.run();
      expect(simulation.report!.handledEventId, isNull);
      expect(jsonEncode(controller.project.toJson()), bytes);
    },
  );

  test(
    'simulation reruns against a removed source without stale success',
    () async {
      final fixture = await prepared();
      final controller = fixture.controller!;
      final simulation = EventSimulationSession(
        controller,
        Ui06SceneFixture.eventId,
      );
      simulation.run();
      expect(simulation.report!.handledEventId, Ui06SceneFixture.eventId);
      expect(controller.setSource(Ui06SceneFixture.eventId, null), isTrue);
      simulation.run();
      expect(simulation.report!.handledEventId, isNull);
      expect(
        simulation.report!.reasons,
      contains(NarrativeEventSimulationReason.sourceMissing),
      );
    },
  );

  test(
    'simulation names the competing event instead of selecting target',
    () async {
      final fixture = await prepared();
      final controller = fixture.controller!;
      final source = controller.record(Ui06SceneFixture.eventId)!.source;
      expect(
        await controller.changeMode(EventSystemMode.dualRead),
        isTrue,
        reason: controller.error,
      );
      expect(await controller.prepare(), isTrue);
      final rival = controller.create('Annonce prioritaire', source: source)!;
      expect(controller.setScene(rival.id, Ui06SceneFixture.sceneId), isTrue);
      expect(
        controller.setReuse(rival.id, NarrativeEventReusePolicy.reusable),
        isTrue,
      );
      expect(controller.setPriority(rival.id, 100), isTrue);
      expect(controller.configure(rival.id), isTrue, reason: controller.error);
      expect(
        controller.setEnabled(rival.id, true),
        isTrue,
        reason: controller.error,
      );
      final bytes = jsonEncode(controller.project.toJson());
      final simulation = EventSimulationSession(
        controller,
        Ui06SceneFixture.eventId,
      )..run();
      expect(simulation.report!.handledEventId, rival.id);
      expect(
        simulation.report!.candidates.any(
          (candidate) =>
              candidate.name == 'Annonce prioritaire' && candidate.selected,
        ),
        isTrue,
      );
      expect(jsonEncode(controller.project.toJson()), bytes);
    },
  );

  test('grouped conditions remain ANY and NOT when removing a sibling', () {
    final left = NarrativeEventConditionExpression.not(
      NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.fact('ticket', false),
      ),
    );
    final right = NarrativeEventConditionExpression.leaf(
      NarrativeEventCondition.fact('ready', true),
    );
    final group = NarrativeEventConditionExpression.any([left, right]);
    expect(
      removeEventConditionChild(group, 1),
      NarrativeEventConditionExpression.any([left]),
    );
    expect(group, NarrativeEventConditionExpression.any([left, right]));
    expect(
      rebuildEventConditionGroup(group, [right, left]),
      NarrativeEventConditionExpression.any([right, left]),
    );
  });

  test('invalid numeric simulation never reports a stale success', () async {
    final fixture = await prepared();
    final fact = NarrativeFactDefinition(
      id: 'ui08.count',
      label: 'Nombre de billets',
      initialValue: NarrativeValue.integer(2),
    );
    fixture.narrative.pendingFacts[fact.id] = fact;
    final controller = fixture.controller!;
    final bytes = jsonEncode(controller.project.toJson());
    final simulation = EventSimulationSession(
      controller,
      Ui06SceneFixture.eventId,
    )..run();
    expect(simulation.report!.handledEventId, Ui06SceneFixture.eventId);
    simulation.setFactText(fact, 'pas un entier');
    expect(simulation.report, isNull);
    simulation.run();
    expect(simulation.report, isNull);
    expect(simulation.error, contains('avant de simuler'));
    simulation.setFactText(fact, '2');
    simulation.run();
    expect(simulation.report!.handledEventId, Ui06SceneFixture.eventId);
    expect(simulation.error, isNull);
    expect(jsonEncode(controller.project.toJson()), bytes);
  });

  test(
    'consumed simulation input is isolated and withdraws selection',
    () async {
      final fixture = await prepared();
      final controller = fixture.controller!;
      expect(
        controller.setReuse(
          Ui06SceneFixture.eventId,
          NarrativeEventReusePolicy.oneShot,
        ),
        isTrue,
      );
      expect(controller.setEnabled(Ui06SceneFixture.eventId, true), isTrue);
      final bytes = jsonEncode(controller.project.toJson());
      final simulation = EventSimulationSession(
        controller,
        Ui06SceneFixture.eventId,
      )..run();
      expect(simulation.report!.handledEventId, Ui06SceneFixture.eventId);
      simulation.setConsumed(Ui06SceneFixture.eventId, true);
      expect(simulation.report, isNull);
      simulation.run();
      expect(simulation.report!.handledEventId, isNull);
      expect(
        simulation.report!.candidates.expand((candidate) => candidate.reasons),
        contains(NarrativeEventSimulationReason.eventConsumed),
      );
      expect(jsonEncode(controller.project.toJson()), bytes);
    },
  );
}
