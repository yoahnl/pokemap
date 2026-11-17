import 'dart:async';

import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_workshop.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../resource_io/map_relief_catalog_fixture.dart';
import 'map_builder_story_catalog_support.dart';
import 'map_builder_story_support.dart';

void main() {
  test(
    'physical dependency refresh settles before the narrative batch starts',
    () async {
      final reader = ReadLogReader();
      final adapter = LocalMapWorkspaceAdapter(reader: reader);
      final operations = <String>{};
      final opened = await openStoryCatalog(
        guides: 2,
        unrelated: 400,
        sameSource: true,
        withCharacters: true,
        adapter: adapter,
        faultInjector: (context) {
          operations.add(context.operationId);
        },
      );
      final maps = opened.maps;
      final story = opened.story;
      Future<bool>? saving;
      addTearDown(() async {
        if (reader.gate case final gate? when !gate.isCompleted) {
          gate.complete();
        }
        await maps.savesSettled;
        await saving;
      });
      await maps.ensureResourceKind('character');
      final document = maps.active!;
      document.commit(
        document.current.copyWith(
          entities: [
            document.current.entities.first.copyWith(
              npc: document.current.entities.first.npc!.copyWith(
                characterId: 'maman',
              ),
            ),
            document.current.entities.last,
            const MapEntity(
              id: 'new',
              name: 'Maman',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 3, y: 3),
              npc: MapEntityNpcData(characterId: 'maman'),
            ),
          ],
        ),
      );
      void gateAfterWrite() {
        if (!document.dirty && reader.gate == null) reader.gate = Completer();
      }

      maps.addListener(gateAfterWrite);
      expect(await maps.saveAll(), isTrue);
      maps.removeListener(gateAfterWrite);
      expect(reader.gate, isNotNull);
      final source = story.elements!.byKey('entity:guide-0')!;
      expect(story.moveCase(story.casesOf(source).groups.single, 1, 0), isTrue);
      final record = story.behaviours
          .registry(maps.project!)!
          .records
          .singleWhere((record) => record.id == catalogEventId(1));
      expect(story.renameBehaviour(record, 'Rencontre harmonieuse'), isTrue);
      expect(story.addBehaviour(story.elements!.byKey('entity:new')!), isTrue);
      final port = _ObservedEvents(opened.port);
      saving = story.publish(storyEvents(story, port));
      await Future<void>.delayed(Duration.zero);
      expect(
        port.calls,
        0,
        reason: 'The saved-map refresh still owns the catalogue projection.',
      );
      reader.gate!.complete();
      expect(await saving, isTrue, reason: story.error);
      expect(port.calls, 1);
      expect(operations, hasLength(1));
      expect(story.dirty, isFalse);
      final reopened = MapWorkspaceController(
        opened.session,
        LocalMapWorkspaceAdapter(),
      );
      addTearDown(reopened.dispose);
      await reopened.initialize();
      await reopened.activate(reopened.project!.maps.single);
      await reopened.ensureWorkshop(MapWorkspaceWorkshop.events);
      final records = reopened.project!.eventRegistry!.records;
      expect(
        records.singleWhere((record) => record.id == catalogEventId(1)).name,
        'Rencontre harmonieuse',
      );
      expect(
        records.singleWhere((record) => record.id == catalogEventId(1)).order,
        1,
      );
      expect(
        records.singleWhere((record) => record.id == catalogEventId(0)).order,
        2,
      );
      expect(
        records
            .where(
              (record) =>
                  record.source ==
                  NarrativeEventSourceRef.entityInteract('bourg', 'new'),
            )
            .single
            .draftOrNull,
        isNotNull,
      );
      expect(reopened.active!.current.entities.last.npc!.characterId, 'maman');
    },
  );
}

class _ObservedEvents implements EventPort, EventBatchPort {
  _ObservedEvents(this.port);
  final EventPort port;
  int calls = 0;

  @override
  Future<ResourceMutationReceipt> publishEvent({
    required String id,
    required NarrativeEventRecord? base,
    required NarrativeEventRecord? current,
  }) {
    calls++;
    return port.publishEvent(id: id, base: base, current: current);
  }

  @override
  Future<ResourceMutationReceipt> publishEvents(
    List<EventRecordChange> changes,
  ) {
    calls++;
    return (port as EventBatchPort).publishEvents(changes);
  }
}
