import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/narrative/application/narrative_source_location.dart';
import 'package:avelune_studio/presentation/features/events/event_context_map.dart';
import 'package:avelune_studio/presentation/features/events/event_labels.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/spatial_narrative_fixture.dart';
import '../support/map_workspace_fixture.dart';

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

  testWidgets(
    '3D source picker uses native model hits and rejects unavailable sources',
    (tester) async {
      final source = NarrativeEventSourceRef.modelInteract('a', 'door-a');
      final chosen = <NarrativeEventSourceRef>[];
      final visuals = SpatialNarrativeVisuals(),
          transform = TransformationController();
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: EventContextMap(
              map: spatialNarrativeMap(),
              project: spatialNarrativeProject(),
              visuals: visuals,
              transform: transform,
              chooseKind: NarrativeEventSourceKind.modelInteract,
              selectableSources: {source},
              onChoose: chosen.add,
            ),
          ),
        ),
      );
      await tester.pump();
      final picker = tester.widget<StudioSelect>(find.byType(StudioSelect));
      expect(picker.options.keys, ['door-a']);
      final canvas = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      canvas.onContent!(
        const SpatialSceneContentHit(
          kind: SpatialSceneContentKind.model,
          id: 'door-b',
          cell: (8, 3),
        ),
      );
      expect(chosen, isEmpty);
      canvas.onContent!(
        const SpatialSceneContentHit(
          kind: SpatialSceneContentKind.model,
          id: 'door-a',
          cell: (4, 3),
        ),
      );
      expect(chosen, [source]);
      await tester.pumpWidget(const SizedBox());
      transform.dispose();
      await visuals.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selected decor opens canonical Event V2 authoring from its inspector',
    (tester) async {
      final map = spatialNarrativeMap(),
          visuals = WorkspaceTestVisuals(),
          view = MapWorkspaceViewState();
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: map.id, revision: 'test'),
      )..selectedId = 'door-a';
      final opened = <NarrativeEventSourceRef>[];
      tester.view.physicalSize = const Size(1000, 1300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: MapWorkspaceInspector(
              project: spatialNarrativeProject(),
              document: document,
              visuals: visuals,
              view: view,
              onChanged: () {},
              onEventSource: opened.add,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Événements de ce décor'));
      await tester.tap(find.text('Événements de ce décor'));
      expect(opened, [NarrativeEventSourceRef.modelInteract('a', 'door-a')]);
      expect(document.current.entities, map.entities);
      await tester.pumpWidget(const SizedBox());
      view.dispose();
      await visuals.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
