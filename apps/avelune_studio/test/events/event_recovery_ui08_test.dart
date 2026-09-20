import 'dart:io';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import '../support/delayed_event_port.dart';
import '../support/event_backend_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  test('interrupted event promotion recovers verified record', () async {
    final f = await EventBackendFixture.create();
    addTearDown(f.dispose);
    var interrupted = false;
    final c = f.attach(
      overridePort: LocalEventAdapter(
        session: f.source.session,
        mapAdapter: f.source.maps,
        faultInjector: (context) {
          if (!interrupted &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted) {
            interrupted = true;
            throw const FileSystemException('Injected event promotion failure');
          }
        },
      ),
    );
    await c.prepare();
    c.rename(Ui06SceneFixture.eventId, 'Récupéré');
    expect(await c.save(), isTrue, reason: c.error);
    expect(interrupted, isTrue);
    expect(
      (await f.readFresh()).eventRegistry!.records.single.name,
      'Récupéré',
    );
    expect(c.dirty, isFalse);
  });

  test(
    'partial publication preserves failed event and reports already saved scope',
    () async {
      final f = await EventBackendFixture.create();
      addTearDown(f.dispose);
      final port = DelayedEventPort(f.port, failOn: Ui06SceneFixture.eventId)
        ..release.complete();
      final c = f.attach(overridePort: port);
      await c.prepare();
      final added = c.create('Déjà enregistré')!;
      c.rename(Ui06SceneFixture.eventId, 'Reste ouvert');
      expect(await c.save(), isFalse);
      expect(c.error, contains('1 événement(s) enregistré(s)'));
      expect(c.isDirty(added.id), isFalse);
      expect(c.isDirty(Ui06SceneFixture.eventId), isTrue);
      expect((await f.readFresh()).eventRegistry!.records.last, added);
      expect(c.record(Ui06SceneFixture.eventId)!.name, 'Reste ouvert');
    },
  );

  test(
    'clean reconciliation invalidates obsolete undo; dirty external change stays editable',
    () async {
      final f = await EventBackendFixture.create();
      addTearDown(f.dispose);
      final c = f.attach();
      await c.prepare();
      const id = Ui06SceneFixture.eventId;
      c.open(id);
      c.rename(id, 'Publié');
      expect(await c.save(), isTrue);
      expect(c.canUndo, isTrue);
      final before = f.workspace.project!;
      f.workspace.acceptResources(before, before.copyWith(eventRegistry: null));
      expect(c.active, isNull);
      expect(c.canUndo, isFalse);
    },
  );
}
