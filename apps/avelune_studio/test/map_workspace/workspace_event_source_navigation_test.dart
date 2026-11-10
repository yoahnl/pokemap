import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

class _Port extends WorkspaceMemoryPort {
  Completer<void>? gate;
  @override
  Future<ProjectManifest> loadProject(ProjectSession session) async =>
      spatialEnvironmentProject();
  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    await gate?.future;
    return super.loadMap(session, entry);
  }
}

void main() {
  late _Port port;
  late MapWorkspaceController controller;
  late MapEditingViewportSession view;
  late WorkspaceNavigationSession navigation;
  late List<void Function()> afterLayout;
  late List<GridPos> centered;
  setUp(() async {
    port = _Port();
    final base = spatialEnvironmentMap().copyWith(
      entities: const [
        MapEntity(
          id: 'actor',
          name: 'Actor',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 3),
          npc: MapEntityNpcData(characterId: 'guide'),
        ),
      ],
      triggers: const [
        MapTrigger(
          id: 'zone',
          name: 'Zone',
          type: TriggerType.event,
          area: MapRect(
            pos: GridPos(x: 4, y: 5),
            size: GridSize(width: 1, height: 1),
          ),
        ),
      ],
      spatialScene: spatialEnvironmentMap().spatialScene!.copyWith(
        instances: [
          SpatialModelInstance(
            id: 'pillar',
            modelId: 'oak',
            position: Model3dVector3(x: 6.5, y: 0, z: 7.5),
          ),
        ],
      ),
    );
    port.saved['a'] = base;
    port.saved['b'] = base.copyWith(id: 'b');
    controller = MapWorkspaceController(workspaceSession, port);
    await controller.initialize();
    centered = [];
    afterLayout = [];
    view = MapEditingViewportSession()..tool = StudioMapTool.pan;
    view.centerOn = centered.add;
    navigation = WorkspaceNavigationSession(
      controller: controller,
      isActive: () => true,
      changed: () {},
      mapView: () => view,
      afterViewportLayout: afterLayout.add,
    )..show(WorkspaceSpace.events);
  });
  tearDown(() {
    view.dispose();
    controller.dispose();
  });

  for (final (source, family, id, position) in [
    (
      NarrativeEventSourceRef.entityInteract('a', 'actor'),
      MapSelectionFamily.character,
      'actor',
      const GridPos(x: 2, y: 3),
    ),
    (
      NarrativeEventSourceRef.triggerEnter('a', 'zone'),
      MapSelectionFamily.trigger,
      'zone',
      const GridPos(x: 4, y: 5),
    ),
    (
      NarrativeEventSourceRef.modelInteract('a', 'pillar'),
      MapSelectionFamily.decor,
      'pillar',
      const GridPos(x: 6, y: 7),
    ),
  ]) {
    test(
      'event source selects its exact ${family.name} and centers only after layout',
      () async {
        final before = controller.active!.current;
        final steps = controller.active!.undoCount;
        expect(await navigation.locateEventSource(source), isNull);
        expect(navigation.space, WorkspaceSpace.map);
        expect(navigation.eventMapReturn, isTrue);
        expect(view.tool, StudioMapTool.select);
        expect(view.target!.family, family);
        expect(view.target!.id, id);
        expect(centered, isEmpty);
        afterLayout.single();
        expect(centered, [position]);
        expect(controller.active!.current, same(before));
        expect(controller.active!.undoCount, steps);
        expect(port.writes, 0);
      },
    );
  }

  test('a map entry source clears an earlier selection without choosing a replacement', () async {
    view.select(controller.active!, MapSelectionFamily.character, 'actor');
    expect(
      await navigation.locateEventSource(NarrativeEventSourceRef.mapEnter('a')),
      isNull,
    );
    expect(view.target, isNull);
    afterLayout.single();
    expect(centered, isEmpty);
    expect(navigation.eventMapReturn, isTrue);
  });

  test(
    'a missing target preserves the prior selection and reports its refusal',
    () async {
      view.select(controller.active!, MapSelectionFamily.character, 'actor');
      final before = view.target;
      expect(
        await navigation.locateEventSource(
          NarrativeEventSourceRef.entityInteract('a', 'missing'),
        ),
        contains('Aucune cible de remplacement'),
      );
      expect(view.target, same(before));
      expect(navigation.space, WorkspaceSpace.events);
      expect(navigation.eventMapReturn, isFalse);
      expect(afterLayout, isEmpty);
    },
  );

  test(
    'leaving events during a map load ignores the late location result',
    () async {
      port.gate = Completer<void>();
      final original = controller.active;
      final locating = navigation.locateEventSource(
        NarrativeEventSourceRef.entityInteract('b', 'actor'),
      );
      navigation.show(WorkspaceSpace.story);
      port.gate!.complete();
      expect(await locating, isNull);
      expect(controller.active, same(original));
      expect(navigation.space, WorkspaceSpace.story);
      expect(navigation.eventMapReturn, isFalse);
      expect(view.target, isNull);
      expect(afterLayout, isEmpty);
    },
  );
}
