import 'package:avelune_studio/features/events/application/event_labels.dart';
import 'package:avelune_studio/features/events/application/event_source_targets.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/narrative/application/narrative_source_location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_narrative_fixture.dart';

void main() {
  test('model source locates the actual model without a synthetic entity', () {
    final map = spatialNarrativeMap();
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'test'),
    );
    final source = NarrativeEventSourceRef.modelInteract('a', 'door-a');
    final location = NarrativeSourceLocation.fromSource(document, source)!;
    expect(eventMapId(source), 'a');
    expect(eventTargetId(source), 'door-a');
    expect(location.instanceId, 'door-a');
    expect(location.entityId, isNull);
    expect(location.position, const GridPos(x: 4, y: 3));
    expect(
      NarrativeSourceLocation.fromSource(
        document,
        NarrativeEventSourceRef.modelInteract('a', 'removed'),
      ),
      isNull,
    );
  });
  test(
    'native model source selection admits only its exact selectable hit',
    () {
      final map = spatialNarrativeMap();
      final before = map.toJson();
      final source = NarrativeEventSourceRef.modelInteract('a', 'door-a');
      final picking = EventSourcePicking(
        map: map,
        project: spatialNarrativeProject(),
        chooseKind: NarrativeEventSourceKind.modelInteract,
        selectableSources: {source},
      );
      expect(picking.modelChoices.keys, ['door-a']);
      expect(picking.modelHit('door-b'), isNull);
      expect(picking.modelHit('door-a'), source);
      expect(picking.actorHit('npc:door-a'), isNull);
      expect(map.toJson(), before);
    },
  );

  test('selected model projects its native Event V2 identity without a synthetic map entity', () {
    final map = spatialNarrativeMap();
    final before = map.entities;
    final instance = map.spatialScene!.instances.singleWhere(
      (instance) => instance.id == 'door-a',
    );
    final picking = EventSourcePicking(
      map: map,
      project: spatialNarrativeProject(),
      chooseKind: NarrativeEventSourceKind.modelInteract,
    );
    expect(
      picking.modelHit(instance.id),
      NarrativeEventSourceRef.modelInteract(map.id, instance.id),
    );
    expect(map.entities, before);
  });
}
