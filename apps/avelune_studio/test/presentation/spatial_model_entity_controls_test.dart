import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_model_entity_controls.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  testWidgets('guided object binding uses map entities and supports undo', (
    tester,
  ) async {
    final instance = SpatialModelInstance(
      id: 'orb',
      modelId: 'oak',
      position: Model3dVector3(x: 4.5, y: 0, z: 3.5),
    );
    final original = spatialEnvironmentMap();
    final map = original.copyWith(
      spatialScene: original.spatialScene!.copyWith(instances: [instance]),
      entities: [
        MapEntity(
          id: 'item',
          name: 'Objet à ramasser',
          kind: MapEntityKind.item,
          pos: const GridPos(x: 1, y: 1),
          item: const MapEntityItemData(gameItemId: 'resource'),
        ),
        MapEntity(
          id: 'repeat',
          name: 'Objet répétable',
          kind: MapEntityKind.item,
          pos: const GridPos(x: 2, y: 1),
          item: const MapEntityItemData(
            gameItemId: 'resource',
            pickupMode: ItemPickupMode.always,
          ),
        ),
        MapEntity(
          id: 'npc',
          name: 'Habitant',
          kind: MapEntityKind.npc,
          pos: const GridPos(x: 3, y: 1),
        ),
      ],
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'binding'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, refresh) => SpatialModelEntityControls(
              document: document,
              project: spatialEnvironmentProject(),
              instance: document.current.spatialScene!.instances.single,
              onChanged: () => refresh(() {}),
            ),
          ),
        ),
      ),
    );
    final picker = tester.widget<StudioSelect>(
      find.byKey(const ValueKey('spatial-model-entity-binding')),
    );
    expect(picker.options, {
      '': 'Aucun · décor simple',
      'item': 'Objet à ramasser',
    });
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objet à ramasser').last);
    await tester.pumpAndSettle();
    expect(document.current.spatialScene!.instances.single.entityId, 'item');
    expect(document.current.entities.first.pos, const GridPos(x: 4, y: 3));
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current.spatialScene!.instances.single.entityId, isNull);
    expect(document.current.entities.first.pos, const GridPos(x: 1, y: 1));
  });
}
