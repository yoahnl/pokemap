import 'dart:async';

import 'package:avelune_studio/features/scenes/application/scene_action_references.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_narrative_fixture.dart';

void main() {
  test('a late response cannot replace a more recent destination', () async {
    var changes = 0;
    final references = SceneActionReferences(
      project: workspaceProject,
      changed: () => changes++,
    );
    final first = Completer<MapData>(), second = Completer<MapData>();
    final pendingFirst = references.load(
      project: workspaceProject,
      commandId: NarrativeCommandIds.warp,
      parameters: {'destinationMapId': 'a'},
      loadMap: (_) => first.future,
    );
    final pendingSecond = references.load(
      project: workspaceProject,
      commandId: NarrativeCommandIds.warp,
      parameters: {'destinationMapId': 'b'},
      loadMap: (_) => second.future,
    );
    second.complete(workspaceMap('b'));
    await pendingSecond;
    expect(references.map!.id, 'b');
    first.complete(workspaceMap('a'));
    await pendingFirst;
    expect(references.map!.id, 'b');
    expect(changes, 1);
  });

  test('disposal invalidates a pending map read without notifying', () async {
    var changes = 0;
    final references = SceneActionReferences(
      project: workspaceProject,
      changed: () => changes++,
    );
    final result = Completer<MapData>();
    final pending = references.load(
      project: workspaceProject,
      commandId: NarrativeCommandIds.warp,
      parameters: {'destinationMapId': 'a'},
      loadMap: (_) => result.future,
    );
    references.dispose();
    result.complete(workspaceMap('a'));
    await pending;
    expect(references.map, isNull);
    expect(changes, 0);
  });

  test('an unexpected map identity cannot provide arrival points', () async {
    final references = SceneActionReferences(
      project: workspaceProject,
      changed: () {},
    );
    await references.load(
      project: workspaceProject,
      commandId: NarrativeCommandIds.warp,
      parameters: {'destinationMapId': 'a'},
      loadMap: (_) async => workspaceMap('b'),
    );
    expect(references.map, isNull);
    expect(references.warpPoints, isEmpty);
    expect(
      references.error,
      'La carte chargée ne correspond pas à la destination.',
    );
    expect(references.loading, isFalse);
  });

  test('a missing destination never loads or retains a previous map', () async {
    final references = SceneActionReferences(
      project: workspaceProject,
      changed: () {},
    );
    var reads = 0;
    Future<MapData> load(String id) async {
      reads++;
      return workspaceMap(id);
    }

    await references.load(
      project: workspaceProject,
      commandId: NarrativeCommandIds.warp,
      parameters: {'destinationMapId': 'a'},
      loadMap: load,
    );
    expect(references.map, isNotNull);
    await references.load(
      project: workspaceProject.copyWith(maps: []),
      commandId: NarrativeCommandIds.warp,
      parameters: {'destinationMapId': 'a'},
      loadMap: load,
    );
    expect(reads, 1);
    expect(references.map, isNull);
    expect(references.loading, isFalse);
  });

  test(
    'missing loader stays explicit and a failed load can be retried',
    () async {
      final references = SceneActionReferences(
        project: workspaceProject,
        changed: () {},
      );
      const parameters = {'destinationMapId': 'a'};
      await references.load(
        project: workspaceProject,
        commandId: NarrativeCommandIds.warp,
        parameters: parameters,
        loadMap: null,
      );
      expect(
        references.error,
        'La carte n’est pas disponible dans cet éditeur.',
      );
      await references.load(
        project: workspaceProject,
        commandId: NarrativeCommandIds.warp,
        parameters: parameters,
        loadMap: (_) async => throw StateError('Indisponible'),
      );
      expect(
        references.error,
        contains('Impossible de charger les points d’arrivée'),
      );
      await references.load(
        project: workspaceProject,
        commandId: NarrativeCommandIds.warp,
        parameters: parameters,
        loadMap: (_) async => workspaceMap('a'),
      );
      expect(references.map!.id, 'a');
      expect(references.error, isNull);
      expect(references.loading, isFalse);
    },
  );

  test('mobile prop references reject a spatial map', () async {
    final project = spatialNarrativeProject();
    final map = spatialNarrativeMap();
    final references = SceneActionReferences(project: project, changed: () {});
    await references.load(
      project: project,
      commandId: NarrativeCommandIds.setPropState,
      parameters: {'mapId': map.id},
      loadMap: (_) async => map,
    );
    expect(references.map, isNull);
    expect(references.movingProps, isEmpty);
    expect(references.error, 'Les décors mobiles nécessitent une carte 2D.');
  });
}
