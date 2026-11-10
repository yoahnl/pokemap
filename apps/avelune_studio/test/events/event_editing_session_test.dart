import 'package:avelune_studio/features/events/application/event_editing_session.dart';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/event_backend_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  test(
    'reload clears only the reloaded record input and preserves other drafts',
    () async {
      final h = await EventBackendFixture.create();
      addTearDown(h.dispose);
      final controller = h.attach();
      expect(await controller.prepare(), isTrue);
      final editing = EventEditingSession(controller, changed: () {});
      final id = Ui06SceneFixture.eventId;
      final savedPriority = controller.record(id)!.priority;
      final other = controller.create('Autre événement')!;
      await editing.mutate(() => controller.setPriority(id, 9));
      await editing.commitNumber(
        id,
        'priority',
        'invalide',
        (value) => controller.setPriority(id, value),
      );
      await editing.commitNumber(
        other.id,
        'order',
        'autre saisie',
        (value) => controller.setOrder(other.id, value),
      );
      expect(await editing.reload(id), isTrue, reason: controller.error);
      expect(controller.record(id)!.priority, savedPriority);
      expect(
        editing.inputs.invalidNumbers.containsKey('$id:priority'),
        isFalse,
      );
      expect(
        editing.inputs.invalidNumbers['${other.id}:order'],
        'autre saisie',
      );
      expect(controller.record(other.id), isNotNull);
      expect(await controller.saveAll(), isFalse);
      expect(
        (await h.readFresh()).eventRegistry!.records.any(
          (record) => record.id == other.id,
        ),
        isFalse,
      );
    },
  );

  test(
    'invalid numbers block publication without replacing the stored value',
    () async {
      final h = await EventBackendFixture.create();
      addTearDown(h.dispose);
      final controller = h.attach();
      expect(await controller.prepare(), isTrue);
      final editing = EventEditingSession(controller, changed: () {});
      final before = await h.readFresh();
      final id = Ui06SceneFixture.eventId;
      final priority = controller.record(id)!.priority;
      await editing.commitNumber(
        id,
        'priority',
        'douze',
        (value) => controller.setPriority(id, value),
      );
      expect(editing.inputs.invalidNumbers['$id:priority'], 'douze');
      expect(controller.record(id)!.priority, priority);
      expect(await controller.saveAll(), isFalse);
      expect((await h.readFresh()).eventRegistry, before.eventRegistry);
      await editing.commitNumber(
        id,
        'priority',
        '12',
        (value) => controller.setPriority(id, value),
      );
      expect(editing.inputs.invalidNumbers, isEmpty);
      expect(await controller.saveAll(), isTrue, reason: controller.error);
      expect(
        (await h.readFresh()).eventRegistry!.records
            .singleWhere((record) => record.id == id)
            .priority,
        12,
      );
    },
  );

  test('queued changes preserve canonical undo order', () async {
    final h = await EventBackendFixture.create();
    addTearDown(h.dispose);
    final controller = h.attach();
    expect(await controller.prepare(), isTrue);
    final editing = EventEditingSession(controller, changed: () {});
    final id = Ui06SceneFixture.eventId;
    final first = editing.mutate(() => controller.setPriority(id, 3));
    final second = editing.mutate(() => controller.setPriority(id, 7));
    await Future.wait([first, second]);
    expect(controller.record(id)!.priority, 7);
    await editing.restore(redo: false);
    expect(controller.record(id)!.priority, 3);
    await editing.restore(redo: true);
    expect(controller.record(id)!.priority, 7);
    expect(await controller.saveAll(), isTrue, reason: controller.error);
    expect(
      (await h.readFresh()).eventRegistry!.records
          .singleWhere((record) => record.id == id)
          .priority,
      7,
    );
  });

  test(
    'a rejected edit remains a save guard until a successful edit',
    () async {
      final h = await EventBackendFixture.create();
      addTearDown(h.dispose);
      final controller = h.attach();
      expect(await controller.prepare(), isTrue);
      final editing = EventEditingSession(controller, changed: () {});
      await editing.mutate(() => throw StateError('Édition refusée'));
      expect(await controller.saveAll(), isFalse);
      expect(controller.error, contains('Édition refusée'));
      await editing.mutate(
        () => controller.setPriority(Ui06SceneFixture.eventId, 6),
      );
      expect(await controller.saveAll(), isTrue, reason: controller.error);
      expect(editing.error, isNull);
    },
  );

  test(
    'replacing an editing surface retains its previous flush failure',
    () async {
      final h = await EventBackendFixture.create();
      addTearDown(h.dispose);
      final controller = h.attach();
      expect(await controller.prepare(), isTrue);
      controller.flushEdits = () async =>
          throw StateError('Saisie non validée');
      final editing = EventEditingSession(controller, changed: () {});
      await expectLater(editing.flush(), throwsA(isA<EventFailure>()));
      expect(await controller.saveAll(), isFalse);
      expect(controller.error, contains('Saisie non validée'));
      await editing.mutate(
        () => controller.setOrder(Ui06SceneFixture.eventId, 2),
      );
      expect(await controller.saveAll(), isTrue, reason: controller.error);
    },
  );
}
