import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/event_backend_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  test(
    'four canonical sources publish exact identity and leave existing maps and scenes alone',
    () async {
      final f = await EventBackendFixture.create();
      addTearDown(f.dispose);
      final map = f.workspace.active!;
      map.commit(
        map.current.copyWith(
          entities: [
            ...map.current.entities,
            const MapEntity(
              id: 'chief',
              name: 'Chef de gare',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 4, y: 5),
            ),
          ],
          triggers: [
            const MapTrigger(
              id: 'platform',
              name: 'Quai',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 5, y: 5),
                size: GridSize(width: 2, height: 2),
              ),
            ),
          ],
        ),
      );
      expect(await f.workspace.save(map), isTrue, reason: map.error);
      final c = f.attach();
      await c.prepare();
      final sources = [
        NarrativeEventSourceRef.entityInteract(map.current.id, 'chief'),
        NarrativeEventSourceRef.triggerEnter(map.current.id, 'platform'),
        NarrativeEventSourceRef.mapEnter(map.current.id),
        NarrativeEventSourceRef.outcomeReceived(
          NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: Ui06SceneFixture.sceneId,
            outcomeId: 'embarquement',
          ),
        ),
      ];
      final before = await f.readFresh();
      for (var index = 0; index < sources.length; index++) {
        final draft = c.create('Événement $index', source: sources[index]);
        expect(draft, isNotNull, reason: c.error);
        final id = draft!.id;
        expect(
          c.setScene(id, Ui06SceneFixture.sceneId),
          isTrue,
          reason: c.error,
        );
        expect(c.setReuse(id, NarrativeEventReusePolicy.reusable), isTrue);
        expect(c.configure(id), isTrue, reason: c.error);
        expect(c.setEnabled(id, true), isTrue, reason: c.error);
      }
      expect(await c.save(), isTrue, reason: c.error);
      final after = await f.readFresh();
      expect(
        after.eventRegistry!.records.skip(1).map((r) => r.source),
        sources,
      );
      expect(after.scenes, before.scenes);
      expect(map.current, map.saved);
    },
  );

  test(
    'unpublished new spatial source blocks save and keeps both drafts intact',
    () async {
      final f = await EventBackendFixture.create();
      addTearDown(f.dispose);
      final map = f.workspace.active!;
      map.commit(
        map.current.copyWith(
          entities: [
            ...map.current.entities,
            const MapEntity(
              id: 'new_npc',
              name: 'Non enregistré',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 4, y: 5),
            ),
          ],
        ),
      );
      final c = f.attach();
      await c.prepare();
      final event = c.create(
        'Nouvelle rencontre',
        source: NarrativeEventSourceRef.entityInteract(
          map.current.id,
          'new_npc',
        ),
      )!;
      expect(await c.save(), isFalse);
      expect(c.error, contains('source choisie'));
      expect(c.isDirty(event.id), isTrue);
      expect(map.dirty, isTrue);
      expect((await f.readFresh()).eventRegistry!.records.length, 1);
    },
  );

  test(
    'unavailable outcome does not replace source and full key is retained',
    () async {
      final f = await EventBackendFixture.create();
      addTearDown(f.dispose);
      final c = f.attach();
      await c.prepare();
      final event = c.create('Résultat')!;
      final missing = NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'other_scene',
          outcomeId: 'embarquement',
        ),
      );
      expect(c.setSource(event.id, missing), isFalse);
      expect(c.record(event.id)!.source, isNull);
      final valid = NarrativeEventSourceRef.outcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: Ui06SceneFixture.sceneId,
          outcomeId: 'embarquement',
        ),
      );
      expect(c.setSource(event.id, valid), isTrue, reason: c.error);
      expect(c.record(event.id)!.source, valid);
    },
  );
}
