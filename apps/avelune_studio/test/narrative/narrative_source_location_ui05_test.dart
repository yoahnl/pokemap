import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  for (final source in [
    NarrativeEventSourceRef.mapEnter('b'),
    NarrativeEventSourceRef.outcomeReceived(
      NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'scene_departure',
        outcomeId: 'departed',
      ),
    ),
    NarrativeEventSourceRef.entityInteract('missing', 'npc'),
  ]) {
    test(
      'source without known position cannot invent a location: $source',
      () async {
        final port = WorkspaceMemoryPort();
        final maps = MapWorkspaceController(workspaceSession, port);
        await maps.initialize();
        final record = NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: 'evt_00000000-0000-7000-8000-000000000001',
            name: 'Source',
            source: source,
            conditions: [],
            sceneId: 'advanced',
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: 0,
            order: 0,
          ),
          enabled: true,
          activeInLegacyMode: true,
        );
        maps.project = maps.project!.copyWith(
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.legacyOnly,
            records: [record],
            legacyClaims: [],
          ),
        );
        final narrative = NarrativeWorkspaceController(
          maps,
          _NoReads(),
          () {},
          (_, _) async {},
        );
        final active = maps.active;
        expect(await narrative.locateInteraction(record.id), isNull);
        expect(narrative.error, isNotEmpty);
        expect(narrative.sessions, isEmpty);
        expect(maps.active, same(active));
        expect(port.reads, 1);
        expect(port.writes, 0);
        narrative.dispose();
        maps.dispose();
      },
    );
  }

  for (final source in [
    NarrativeEventSourceRef.entityInteract('a', 'npc'),
    NarrativeEventSourceRef.triggerEnter('a', 'zone'),
  ]) {
    test(
      'advanced canonical draft remains locatable without conversion: $source',
      () async {
        final port = WorkspaceMemoryPort();
        port.saved['a'] = workspaceMap('a').copyWith(
          entities: const [
            MapEntity(
              id: 'npc',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 3, y: 4),
            ),
          ],
          triggers: const [
            MapTrigger(
              id: 'zone',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 2, y: 3),
                size: GridSize(width: 3, height: 3),
              ),
            ),
          ],
        );
        final maps = MapWorkspaceController(workspaceSession, port);
        await maps.initialize();
        final record = NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: 'evt_00000000-0000-7000-8000-000000000002',
            name: 'Avancée',
            source: source,
            conditions: [],
            priority: 0,
            order: 0,
          ),
        );
        maps.project = maps.project!.copyWith(
          eventRegistry: NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.legacyOnly,
            records: [record],
            legacyClaims: [],
          ),
        );
        final narrative = NarrativeWorkspaceController(
          maps,
          _NoReads(),
          () {},
          (_, _) async {},
        );
        final snapshot = maps.active!.current;
        final location = await narrative.locateInteraction(record.id);
        expect(location!.position, const GridPos(x: 3, y: 4));
        expect(
          location.entityId ?? location.triggerId,
          source.kind == NarrativeEventSourceKind.entityInteract
              ? 'npc'
              : 'zone',
        );
        expect(narrative.sessions, isEmpty);
        expect(narrative.active, isNull);
        expect(maps.active!.current, same(snapshot));
        expect(maps.active!.dirty, false);
        expect(maps.project!.eventRegistry!.records.single, same(record));
        expect(port.reads, 1);
        expect(port.writes, 0);
        narrative.dispose();
        maps.dispose();
      },
    );
  }

  test('explicit recenter keeps zoom and does not affect another map view', () {
    final selected = MapWorkspaceViewState();
    final other = MapWorkspaceViewState();
    selected.transform.value = Matrix4.identity()..scaleByDouble(2, 2, 1, 1);
    final unchanged = other.transform.value.clone();
    selected.centerCell(
      const GridPos(x: 6, y: 4),
      const Size(800, 600),
      const Size(32, 32),
    );
    expect(selected.transform.value.getMaxScaleOnAxis(), 2);
    final center = MatrixUtils.transformPoint(
      selected.transform.value,
      const Offset(6.5 * 32, 4.5 * 32),
    );
    expect(center, const Offset(400, 300));
    expect(other.transform.value, unchanged);
    selected.dispose();
    other.dispose();
  });
}

class _NoReads implements NarrativePort {
  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) =>
      throw StateError('Localization must not read dialogue');
  @override
  Future<NarrativePublicationReceipt> publish(NarrativePublication value) =>
      throw StateError('Localization must not write');
}
