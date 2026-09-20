import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/event_backend_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  late EventBackendFixture fixture;
  late EventWorkspaceController controller;
  setUp(() async {
    fixture = await EventBackendFixture.create();
    controller = fixture.attach();
    expect(await controller.prepare(), isTrue);
  });
  tearDown(() => fixture.dispose());

  test(
    'draft creation save reopens without inventing scene or changing registry mode',
    () async {
      final before = await fixture.readFresh();
      final draft = controller.create('Annonce à préparer')!;
      expect(draft.source, isNull);
      expect(draft.sceneId, isNull);
      expect(controller.dirty, isTrue);
      expect(await controller.save(), isTrue, reason: controller.error);
      final after = await fixture.readFresh();
      expect(after.eventRegistry!.records.last, draft);
      expect(after.eventRegistry!.mode, before.eventRegistry!.mode);
      expect(after.scenes, before.scenes);
      expect(after.maps, before.maps);
      expect(after.facts, before.facts);
      expect(controller.dirty, isFalse);
    },
  );

  test(
    'renaming activated record preserves activation and history restores name',
    () async {
      const id = Ui06SceneFixture.eventId;
      final before = controller.record(id)!;
      expect(before.enabledOrNull, isTrue);
      expect(
        controller.rename(id, 'Accueil modifié'),
        isTrue,
        reason: controller.error,
      );
      expect(controller.record(id)!.enabledOrNull, isTrue);
      expect((await fixture.readFresh()).eventRegistry!.records.single, before);
      controller.restore(redo: false);
      expect(controller.record(id), before);
      controller.restore(redo: true);
      expect(controller.record(id)!.name, 'Accueil modifié');
      expect(await controller.save(), isTrue, reason: controller.error);
      expect(
        (await fixture.readFresh()).eventRegistry!.records.single.name,
        'Accueil modifié',
      );
    },
  );

  test(
    'duplicate is distinct draft and deletion uses canonical confirmation',
    () async {
      final clone = controller.duplicate(Ui06SceneFixture.eventId)!;
      expect(clone.id, isNot(Ui06SceneFixture.eventId));
      expect(clone.draftOrNull, isNotNull);
      expect(clone.sceneId, Ui06SceneFixture.sceneId);
      expect(await controller.save(), isTrue, reason: controller.error);
      expect(await controller.prepare(), isTrue);
      expect(controller.delete(clone.id), isTrue, reason: controller.error);
      expect(await controller.save(), isTrue, reason: controller.error);
      expect((await fixture.readFresh()).eventRegistry!.records.length, 1);
    },
  );

  test(
    'nested expression retained, incompatible reset rejected atomically',
    () async {
      const id = Ui06SceneFixture.eventId;
      final condition = NarrativeEventCondition.fact(
        Ui06SceneFixture.passFactId,
        true,
      );
      final expression = NarrativeEventConditionExpression.all([
        NarrativeEventConditionExpression.leaf(condition),
        NarrativeEventConditionExpression.any([
          NarrativeEventConditionExpression.leaf(condition),
          NarrativeEventConditionExpression.not(
            NarrativeEventConditionExpression.leaf(condition),
          ),
        ]),
      ]);
      expect(
        controller.setExpression(id, expression),
        isTrue,
        reason: controller.error,
      );
      expect(controller.record(id)!.expression, expression);
      expect(
        controller.setReuse(id, NarrativeEventReusePolicy.reusable),
        isTrue,
      );
      final beforeReset = controller.record(id);
      expect(
        controller.setReset(id, const NarrativeEventResetPolicy.onMapReentry()),
        isFalse,
      );
      expect(controller.record(id), beforeReset);
      expect(await controller.save(), isTrue, reason: controller.error);
      expect(
        (await fixture.readFresh()).eventRegistry!.records.single.expression,
        expression,
      );
    },
  );

  test(
    'canonical simulation handles disabled configured and consumed states without writes',
    () async {
      final before = await fixture.readFresh();
      const id = Ui06SceneFixture.eventId;
      final initial = controller.simulation(
        NarrativeEventSimulationInput(targetEventId: id),
      );
      expect(initial.handledEventId, id);
      final consumed = controller.simulation(
        NarrativeEventSimulationInput(
          targetEventId: id,
          consumedNarrativeEventIds: {id},
        ),
      );
      expect(consumed.handledEventId, isNull);
      expect(controller.setEnabled(id, false), isTrue);
      final disabled = controller.simulation(
        NarrativeEventSimulationInput(targetEventId: id),
      );
      expect(disabled.handledEventId, isNull);
      expect(await fixture.readFresh(), before);
    },
  );
}
