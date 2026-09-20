import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/event_backend_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  for (final active in [true, false]) {
    test(
      'UI09 metadata rename preserves activation=$active through history and publication',
      () async {
        final fixture = await EventBackendFixture.create();
        addTearDown(fixture.dispose);
        final controller = fixture.attach();
        expect(await controller.prepare(), isTrue);
        const id = Ui06SceneFixture.eventId;
        if (!active) {
          expect(controller.setEnabled(id, false), isTrue);
          expect(await controller.save(), isTrue);
          expect(await controller.prepare(), isTrue);
        }
        final before = controller.record(id)!;
        final mode = controller.project.eventRegistry!.mode;
        expect(controller.rename(id, 'Rencontre renommée'), isTrue);
        final renamed = controller.record(id)!;
        expect(renamed.enabledOrNull, active);
        expect(renamed.toJson(), {
          ...before.toJson(),
          'definition': {
            ...before.definitionOrNull!.toJson(),
            'name': 'Rencontre renommée',
          },
        });
        controller.restore(redo: false);
        expect(controller.record(id), before);
        controller.restore(redo: true);
        expect(controller.record(id), renamed);
        expect(await controller.save(), isTrue, reason: controller.error);
        final reopened = await fixture.readFresh();
        expect(reopened.eventRegistry!.records.single, renamed);
        expect(reopened.eventRegistry!.mode, mode);
        expect(controller.isDirty(id), isFalse);
      },
    );
  }

  test(
    'UI09 unchanged name is a true no-op and behavior edits still deactivate',
    () async {
      final fixture = await EventBackendFixture.create();
      addTearDown(fixture.dispose);
      final controller = fixture.attach();
      expect(await controller.prepare(), isTrue);
      const id = Ui06SceneFixture.eventId;
      final before = controller.record(id)!;
      expect(controller.rename(id, before.definitionOrNull!.name), isTrue);
      expect(controller.record(id), before);
      expect(controller.dirty, isFalse);
      expect(controller.canUndo, isFalse);
      expect(await controller.save(), isTrue);
      expect((await fixture.readFresh()).eventRegistry!.records.single, before);
      expect(
        controller.setExpression(
          id,
          NarrativeEventConditionExpression.all([
            NarrativeEventConditionExpression.leaf(
              NarrativeEventCondition.fact(Ui06SceneFixture.passFactId, true),
            ),
          ]),
        ),
        isTrue,
        reason: controller.error,
      );
      expect(controller.record(id)!.enabledOrNull, isFalse);
      controller.restore(redo: false);
      expect(controller.record(id), before);
      expect(controller.setScene(id, null), isTrue);
      expect(controller.record(id)!.draftOrNull, isNotNull);
      controller.restore(redo: false);
      expect(controller.record(id), before);
      expect(controller.setSource(id, null), isTrue);
      expect(controller.record(id)!.draftOrNull, isNotNull);
      expect((await fixture.readFresh()).eventRegistry!.records.single, before);
    },
  );
}
