import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/stories/data/local_story_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/delayed_event_port.dart';
import '../support/event_backend_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  test(
    'external event-only edit conflicts without losing scene or draft; reload is targeted',
    () async {
      final f = await EventBackendFixture.create();
      addTearDown(f.dispose);
      final c = f.attach();
      await c.prepare();
      const id = Ui06SceneFixture.eventId;
      final base = c.record(id)!;
      final other = c.create('Autre brouillon')!;
      expect(c.rename(id, 'Modification locale'), isTrue);
      final external = NarrativeEventRecord.draft(
        NarrativeEventDraft(
          id: id,
          name: 'Modification externe',
          source: base.source,
          conditions: const [],
          priority: 0,
          order: 0,
        ),
      );
      await f.port.publishEvent(id: id, base: base, current: external);
      expect(await c.save(), isFalse);
      expect(c.error, contains('changé sur le disque'));
      expect(c.record(id)!.name, 'Modification locale');
      expect(await c.reload(id), isTrue);
      expect(c.record(id), external);
      expect(c.record(other.id), other);
      expect(c.isDirty(other.id), isFalse);
      expect((await f.readFresh()).scenes, f.source.manifest.scenes);
    },
  );

  test(
    'edit during write retains newer draft and second save publishes it',
    () async {
      final f = await EventBackendFixture.create();
      addTearDown(f.dispose);
      final delayed = DelayedEventPort(f.port);
      final c = f.attach(overridePort: delayed);
      await c.prepare();
      const id = Ui06SceneFixture.eventId;
      c.rename(id, 'Instantané');
      final saving = c.save();
      await delayed.entered.future;
      expect(c.rename(id, 'Après clic'), isTrue);
      delayed.release.complete();
      expect(await saving, isFalse);
      expect(c.record(id)!.name, 'Après clic');
      expect(c.isDirty(id), isTrue);
      expect(
        (await f.readFresh()).eventRegistry!.records.single.name,
        'Instantané',
      );
      expect(await c.save(), isTrue);
      expect(
        (await f.readFresh()).eventRegistry!.records.single.name,
        'Après clic',
      );
    },
  );

  test('close during write never installs an obsolete receipt', () async {
    final f = await EventBackendFixture.create();
    addTearDown(f.dispose);
    final delayed = DelayedEventPort(f.port);
    final c = f.attach(overridePort: delayed);
    await c.prepare();
    final before = f.workspace.project;
    c.rename(Ui06SceneFixture.eventId, 'Édité');
    final saving = c.save();
    await delayed.entered.future;
    c.dispose();
    delayed.release.complete();
    expect(await saving, isFalse);
    expect(f.workspace.project, before);
  });

  test('unrelated fact publication survives targeted event save', () async {
    final f = await EventBackendFixture.create();
    addTearDown(f.dispose);
    final c = f.attach();
    await c.prepare();
    c.rename(Ui06SceneFixture.eventId, 'Événement renommé');
    final fact = addNarrativeFact(
      f.narrative.project,
      label: 'Plus tard',
    ).createdFact;
    await LocalStoryAdapter(
      session: f.source.session,
      mapAdapter: f.source.maps,
    ).publishFact(base: null, current: fact);
    expect(await c.save(), isTrue, reason: c.error);
    expect((await f.readFresh()).facts, contains(fact));
  });

  test(
    'registry mode change is explicit and refuses active author drafts',
    () async {
      final f = await EventBackendFixture.create();
      addTearDown(f.dispose);
      final c = f.attach();
      await c.prepare();
      c.create('À finir');
      expect(await c.changeMode(EventSystemMode.v2Only), isFalse);
      expect(c.error, contains('brouillons'));
      expect(await c.save(), isTrue);
      final records = (await f.readFresh()).eventRegistry!.records;
      expect(await c.changeMode(EventSystemMode.v2Only), isFalse);
      expect(
        await c.changeMode(EventSystemMode.dualRead),
        isTrue,
        reason: c.error,
      );
      final after = await f.readFresh();
      expect(after.eventRegistry!.mode, EventSystemMode.dualRead);
      expect(after.eventRegistry!.records, records);
    },
  );
}
