import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/storylines/storylines_graph_model.dart';

const _warmupIterations = 3;
const _measuredIterations = 10;

// Frozen from the first accepted sequential NSC-74 baselines. Each ceiling is
// at least four times its recorded p95 and is never derived from the final run.
const _mapEventsP95BudgetMicroseconds = 3000000;
const _storylineGraphP95BudgetMicroseconds = 20000;
const _cinematicsLibraryP95BudgetMicroseconds = 30000;
const _timelineP95BudgetMicroseconds = 10000;
const _maximumDoublingRatio = 3.5;

void main() {
  test('Map Events projects 100 maps and 1000 linked events within budget', () {
    final medium = _mapEventsFixture(mapCount: 50, eventsPerMap: 10);
    final large = _mapEventsFixture(mapCount: 100, eventsPerMap: 10);

    final mediumMeasurement = _measure(
      () => buildNarrativeMapEventsReadModel(
        project: medium.project,
        maps: medium.maps,
      ),
    );
    final largeMeasurement = _measure(
      () => buildNarrativeMapEventsReadModel(
        project: large.project,
        maps: large.maps,
      ),
    );
    final model = largeMeasurement.last;
    final sourceCount = model.maps.fold<int>(
      0,
      (sum, map) => sum + map.sources.length,
    );
    final eventCount = model.maps.fold<int>(
      0,
      (sum, map) => sum + map.events.length,
    );

    _emit(
      operation: 'map_events_projection',
      volume: eventCount,
      mediumP95: mediumMeasurement.p95,
      large: largeMeasurement,
      budget: _mapEventsP95BudgetMicroseconds,
      checksum: sourceCount + eventCount,
    );

    expect(model.maps, hasLength(100));
    expect(sourceCount, 1100);
    expect(eventCount, 1000);
    expect(model.orphanEvents, isEmpty);
    expect(model.unassignedEvents, isEmpty);
    _expectBudgetAndSlope(
      mediumMeasurement,
      largeMeasurement,
      _mapEventsP95BudgetMicroseconds,
    );
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('Storyline graph projects 1000 Steps within budget', () {
    final mediumProject = _storylineProject(stepCount: 500);
    final largeProject = _storylineProject(stepCount: 1000);
    final mediumMeasurement = _measure(
      () => StorylineGraphViewModel.fromProject(
        mediumProject,
        storylineId: 'story_main',
      ),
    );
    final largeMeasurement = _measure(
      () => StorylineGraphViewModel.fromProject(
        largeProject,
        storylineId: 'story_main',
      ),
    );
    final model = largeMeasurement.last;
    final checksum = model.nodes.fold<int>(
      0,
      (sum, node) => sum + node.id.length,
    );

    _emit(
      operation: 'storyline_graph_projection',
      volume: model.stepCount,
      mediumP95: mediumMeasurement.p95,
      large: largeMeasurement,
      budget: _storylineGraphP95BudgetMicroseconds,
      checksum: checksum,
    );

    expect(model.chapterCount, 10);
    expect(model.stepCount, 1000);
    expect(model.nodes, hasLength(1011));
    expect(model.edges.length, greaterThan(1000));
    _expectBudgetAndSlope(
      mediumMeasurement,
      largeMeasurement,
      _storylineGraphP95BudgetMicroseconds,
    );
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('Cinematics Library builds and filters 1000 assets within budget', () {
    final mediumProject = _cinematicsProject(assetCount: 500);
    final largeProject = _cinematicsProject(assetCount: 1000);
    const query = CinematicsLibraryQuery(
      searchText: 'rival port',
      sort: CinematicsLibrarySort.durationDescending,
    );
    final mediumMeasurement = _measure(() {
      final model = buildCinematicsLibraryReadModel(mediumProject);
      return (model: model, matches: model.queryEntries(query));
    });
    final largeMeasurement = _measure(() {
      final model = buildCinematicsLibraryReadModel(largeProject);
      return (model: model, matches: model.queryEntries(query));
    });
    final result = largeMeasurement.last;
    final checksum = result.matches.fold<int>(
      0,
      (sum, entry) => sum + int.parse(entry.id.substring('cinematic_'.length)),
    );

    _emit(
      operation: 'cinematics_library_projection',
      volume: result.model.canonicalEntries.length,
      mediumP95: mediumMeasurement.p95,
      large: largeMeasurement,
      budget: _cinematicsLibraryP95BudgetMicroseconds,
      checksum: checksum,
    );

    expect(result.model.canonicalEntries, hasLength(1000));
    expect(result.matches, hasLength(500));
    expect(result.matches.first.id, 'cinematic_0998');
    _expectBudgetAndSlope(
      mediumMeasurement,
      largeMeasurement,
      _cinematicsLibraryP95BudgetMicroseconds,
    );
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('timeline lays out 1000 blocks and keeps local mutation stable', () {
    final medium = _cinematicWithSteps(stepCount: 500);
    final large = _cinematicWithSteps(stepCount: 1000);
    final mediumMeasurement = _measure(
      () => buildCinematicTimelineTimeLayoutReadModel(medium),
    );
    final largeMeasurement = _measure(
      () => buildCinematicTimelineTimeLayoutReadModel(large),
    );
    final layout = largeMeasurement.last;
    final mutated = buildCinematicTimelineTimeLayoutReadModel(
      _cinematicWithSteps(stepCount: 1000, mutatedIndex: 500),
    );
    final stableIds = layout.blocks
        .where((block) => block.stepId != 'step_0500')
        .map((block) => block.stepId)
        .toList(growable: false);
    final mutatedStableIds = mutated.blocks
        .where((block) => block.stepId != 'step_0500')
        .map((block) => block.stepId)
        .toList(growable: false);

    _emit(
      operation: 'cinematic_timeline_layout',
      volume: layout.stepCount,
      mediumP95: mediumMeasurement.p95,
      large: largeMeasurement,
      budget: _timelineP95BudgetMicroseconds,
      checksum: layout.totalDurationMs,
    );

    expect(layout.stepCount, 1000);
    expect(layout.blocks, hasLength(1000));
    expect(layout.totalDurationMs, 100000);
    expect(mutated.totalDurationMs, 100100);
    expect(mutatedStableIds, orderedEquals(stableIds));
    _expectBudgetAndSlope(
      mediumMeasurement,
      largeMeasurement,
      _timelineP95BudgetMicroseconds,
    );
  }, timeout: const Timeout(Duration(seconds: 30)));
}

void _expectBudgetAndSlope<T>(
  _Measurement<T> medium,
  _Measurement<T> large,
  int budget,
) {
  expect(large.p95, lessThanOrEqualTo(budget));
  expect(
    large.p95 / medium.p95.clamp(1, medium.p95),
    lessThanOrEqualTo(_maximumDoublingRatio),
  );
}

void _emit<T>({
  required String operation,
  required int volume,
  required int mediumP95,
  required _Measurement<T> large,
  required int budget,
  required int checksum,
}) {
  stdout.writeln(
    'NSC_74_LARGE_WORKSPACE operation=$operation '
    'os=${Platform.operatingSystem} '
    'os_version=${_singleLine(Platform.operatingSystemVersion)} '
    'dart=${Platform.version.split(' ').first} '
    'processors=${Platform.numberOfProcessors} mode=flutter_test_debug_jit '
    'execution=sequential volume=$volume '
    'warmups=$_warmupIterations iterations=$_measuredIterations '
    'p50_us=${large.p50} p95_us=${large.p95} '
    'medium_p95_us=$mediumP95 '
    'doubling_ratio=${(large.p95 / mediumP95.clamp(1, mediumP95)).toStringAsFixed(2)} '
    'checksum=$checksum budget_p95_us=$budget threshold=frozen',
  );
}

_Measurement<T> _measure<T>(T Function() operation) {
  for (var index = 0; index < _warmupIterations; index++) {
    operation();
  }
  final samples = <int>[];
  T? last;
  for (var index = 0; index < _measuredIterations; index++) {
    final stopwatch = Stopwatch()..start();
    last = operation();
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds);
  }
  final sorted = [...samples]..sort();
  return _Measurement<T>(
    last: last as T,
    p50: sorted[(sorted.length * .50).ceil() - 1],
    p95: sorted[(sorted.length * .95).ceil() - 1],
  );
}

final class _Measurement<T> {
  const _Measurement({
    required this.last,
    required this.p50,
    required this.p95,
  });

  final T last;
  final int p50;
  final int p95;
}

({ProjectManifest project, List<MapData> maps}) _mapEventsFixture({
  required int mapCount,
  required int eventsPerMap,
}) {
  final maps = <MapData>[];
  final entries = <ProjectMapEntry>[];
  final records = <NarrativeEventRecord>[];
  for (var mapIndex = 0; mapIndex < mapCount; mapIndex++) {
    final mapId = 'map_${mapIndex.toString().padLeft(3, '0')}';
    entries.add(
      ProjectMapEntry(
        id: mapId,
        name: 'Map ${mapIndex.toString().padLeft(3, '0')}',
        relativePath: 'maps/$mapId.json',
      ),
    );
    final entities = <MapEntity>[];
    for (var localIndex = 0; localIndex < eventsPerMap; localIndex++) {
      final entityId = 'npc_${localIndex.toString().padLeft(2, '0')}';
      entities.add(
        MapEntity(
          id: entityId,
          name: 'NPC $localIndex',
          kind: MapEntityKind.npc,
          pos: GridPos(x: localIndex, y: mapIndex % 10),
        ),
      );
      final eventIndex = mapIndex * eventsPerMap + localIndex;
      records.add(
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: _eventId(eventIndex),
            name: 'Event $eventIndex',
            source: NarrativeEventSourceRef.entityInteract(mapId, entityId),
            conditions: const <NarrativeEventCondition>[],
            sceneId: 'scene_shared',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: localIndex,
            order: eventIndex,
          ),
          enabled: true,
        ),
      );
    }
    maps.add(
      MapData(
        id: mapId,
        name: 'Map $mapIndex',
        size: const GridSize(width: 20, height: 20),
        entities: entities,
      ),
    );
  }
  final scene = SceneAsset(
    id: 'scene_shared',
    name: 'Shared scene',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'edge',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
  return (
    project: ProjectManifest(
      name: 'NSC-74 Map Events',
      maps: entries,
      tilesets: const <ProjectTilesetEntry>[],
      scenes: <SceneAsset>[scene],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: records,
        legacyClaims: const [],
      ),
    ),
    maps: maps,
  );
}

ProjectManifest _storylineProject({required int stepCount}) {
  const chapterCount = 10;
  final stepsPerChapter = stepCount ~/ chapterCount;
  return ProjectManifest(
    name: 'NSC-74 Storyline',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    storylines: <StorylineAsset>[
      StorylineAsset(
        id: 'story_main',
        type: StorylineType.main,
        title: 'Large story',
        chapters: <StorylineChapter>[
          for (var chapterIndex = 0;
              chapterIndex < chapterCount;
              chapterIndex++)
            StorylineChapter(
              id: 'chapter_${chapterIndex.toString().padLeft(2, '0')}',
              title: 'Chapter $chapterIndex',
              order: chapterIndex,
              steps: <StorylineStep>[
                for (var stepIndex = 0;
                    stepIndex < stepsPerChapter;
                    stepIndex++)
                  StorylineStep(
                    id: 'step_${(chapterIndex * stepsPerChapter + stepIndex).toString().padLeft(4, '0')}',
                    title: 'Step ${chapterIndex * stepsPerChapter + stepIndex}',
                    order: stepIndex,
                  ),
              ],
            ),
        ],
      ),
    ],
  );
}

ProjectManifest _cinematicsProject({required int assetCount}) =>
    ProjectManifest(
      name: 'NSC-74 Cinematics',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map_port',
          name: 'Port Selbrume',
          relativePath: 'maps/port.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      cinematics: <CinematicAsset>[
        for (var index = 0; index < assetCount; index++)
          CinematicAsset(
            id: 'cinematic_${index.toString().padLeft(4, '0')}',
            title: 'Plan $index',
            mapId: 'map_port',
            tags: <String>[index.isEven ? 'rival' : 'ambiance'],
            timeline: CinematicTimeline(
              steps: <CinematicTimelineStep>[
                CinematicTimelineStep(
                  id: 'step_$index',
                  kind: CinematicTimelineStepKind.wait,
                  durationMs: 100 + index,
                ),
              ],
            ),
          ),
      ],
    );

CinematicAsset _cinematicWithSteps({
  required int stepCount,
  int? mutatedIndex,
}) =>
    CinematicAsset(
      id: 'cinematic_timeline',
      title: 'Large timeline',
      timeline: CinematicTimeline(
        steps: <CinematicTimelineStep>[
          for (var index = 0; index < stepCount; index++)
            CinematicTimelineStep(
              id: 'step_${index.toString().padLeft(4, '0')}',
              kind: CinematicTimelineStepKind.wait,
              durationMs: index == mutatedIndex ? 200 : 100,
            ),
        ],
      ),
    );

String _eventId(int index) =>
    'evt_10000000-0000-7000-8000-${index.toRadixString(16).padLeft(12, '0')}';

String _singleLine(String value) => value.replaceAll(RegExp(r'\s+'), '_');
