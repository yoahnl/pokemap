import 'dart:collection';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final unified in [false, true]) {
    test(
      '${unified ? 'project' : 'outcome'} catalog indexes project once per loop',
      () {
        int readsFor(int count) {
          final dialogues = _ReadCountingList<ProjectDialogueEntry>(const [
            ProjectDialogueEntry(
              id: 'dialogue',
              name: 'Dialogue',
              relativePath: 'dialogues/test.yarn',
            ),
          ]);
          final project = _project(
            List.generate(count, (i) => _scene('scene_$i')),
            dialogues: dialogues,
          );
          if (unified) {
            final catalog = buildNarrativeEventProjectCatalog(
              project: project,
              maps: [_map()],
            );
            expect(catalog.scenes.every((entry) => entry.buildable), isTrue);
          } else {
            final catalog = buildNarrativeOutcomeEventSourceCatalog(
              project: project,
              maps: [_map()],
            );
            expect(catalog.selectableOptions, hasLength(count));
          }
          return dialogues.reads;
        }

        final two = readsFor(2);
        expect(two, greaterThan(0));
        expect(readsFor(6), two);
      },
    );
  }

  test(
    'shared diagnostics retain exact project and map reference validity',
    () {
      final scenes = [_scene('first'), _scene('second')];
      final project = _project(scenes);
      for (final maps in [
        <MapData>[],
        [_map(hasEvent: false)],
        [_map()],
      ]) {
        final byId = {for (final map in maps) map.id: map};
        final catalog = buildNarrativeEventProjectCatalog(
          project: project,
          maps: maps,
        );
        for (final entry in catalog.scenes) {
          expect(
            entry.buildable,
            buildSceneRuntimePlan(entry.scene).canBuild &&
                diagnoseSceneAgainstProject(
                      entry.scene,
                      project,
                      mapsById: byId,
                    ).errorCount ==
                    0,
          );
        }
        final outcomes = buildNarrativeOutcomeEventSourceCatalog(
          project: project,
          maps: maps,
        );
        expect(
          outcomes.selectableOptions.length,
          maps.isNotEmpty && maps.single.events.isNotEmpty ? 2 : 0,
        );
        expect(catalog.outcomeSources.toDebugJson(), outcomes.toDebugJson());
      }
    },
  );

  test(
    'duplicate scenes and maps remain unavailable without contaminating another call',
    () {
      final scene = _scene('duplicate');
      final duplicateProject = _project([scene, scene]);
      final duplicates = buildNarrativeEventProjectCatalog(
        project: duplicateProject,
        maps: [_map()],
      );
      expect(
        duplicates.diagnostics.map((item) => item.code),
        contains('duplicateSceneId'),
      );
      expect(duplicates.outcomeSources.selectableOptions, isEmpty);
      final project = _project([scene]);
      final duplicateMaps = buildNarrativeOutcomeEventSourceCatalog(
        project: project,
        maps: [_map(), _map()],
      );
      expect(duplicateMaps.selectableOptions, isEmpty);
      final valid = buildNarrativeEventProjectCatalog(
        project: project,
        maps: [_map()],
      );
      expect(valid.scenes.single.buildable, isTrue);
      expect(valid.outcomeSources.selectableOptions, hasLength(1));
      final dialogueProject = _project(
        [_scene('dialogue_scene', dialogue: true)],
        dialogues: const [
          ProjectDialogueEntry(
            id: 'dialogue',
            name: 'Dialogue',
            relativePath: 'dialogues/test.yarn',
          ),
        ],
      );
      expect(
        buildNarrativeEventProjectCatalog(
          project: dialogueProject,
          maps: [_map()],
        ).scenes.single.buildable,
        isTrue,
      );
      final changed = buildNarrativeEventProjectCatalog(
        project: dialogueProject.copyWith(dialogues: const []),
        maps: [_map()],
      );
      expect(changed.scenes.single.buildable, isFalse);
      expect(changed.outcomeSources.selectableOptions, isEmpty);
    },
  );
}

ProjectManifest _project(
  List<SceneAsset> scenes, {
  List<ProjectDialogueEntry> dialogues = const [],
}) => ProjectManifest(
  name: 'Catalog test',
  maps: const [
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  tilesets: const [],
  scenes: scenes,
  dialogues: dialogues,
);

MapData _map({bool hasEvent = true}) => MapData(
  id: 'map',
  name: 'Map',
  size: const GridSize(width: 8, height: 8),
  events: [
    if (hasEvent)
      MapEventDefinition(
        id: 'event',
        pages: const [MapEventPage(pageNumber: 0)],
        position: const EventPosition(layerId: 'events', x: 1, y: 1),
      ),
  ],
);

SceneAsset _scene(String id, {bool dialogue = false}) => SceneAsset(
  id: id,
  name: id,
  declaredOutcomes: [SceneOutcome(id: 'done', label: 'Done')],
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      if (dialogue)
        SceneNode(
          id: 'action',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'dialogue'),
        )
      else
        SceneNode(
          id: 'action',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.markEventConsumed(mapId: 'map', eventId: 'event'),
          ),
        ),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(sceneOutcomeId: 'done'),
      ),
    ],
    edges: [
      SceneEdge(
        id: 'first',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'action',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'second',
        fromNodeId: 'action',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

final class _ReadCountingList<T> extends ListBase<T> {
  _ReadCountingList(this._values);
  final List<T> _values;
  int reads = 0;
  @override
  int get length => _values.length;
  @override
  set length(int value) => throw UnsupportedError('immutable');
  @override
  T operator [](int index) {
    reads++;
    return _values[index];
  }

  @override
  void operator []=(int index, T value) => throw UnsupportedError('immutable');
}
