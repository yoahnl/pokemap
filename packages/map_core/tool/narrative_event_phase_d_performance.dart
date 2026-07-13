import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_core/src/read_models/narrative_event_read_deduplication.dart';

const _datasets = <_DatasetSpec>[
  _DatasetSpec(
    name: 'small',
    mapCount: 10,
    sourceCount: 100,
    eventCount: 50,
    iterations: 5,
  ),
  _DatasetSpec(
    name: 'medium',
    mapCount: 100,
    sourceCount: 2000,
    eventCount: 1000,
    iterations: 3,
  ),
  _DatasetSpec(
    name: 'large',
    mapCount: 500,
    sourceCount: 20000,
    eventCount: 10000,
    iterations: 2,
  ),
];

void main() {
  const isAot = bool.fromEnvironment('dart.vm.product');
  _write({
    'kind': 'environment',
    'dartVersion': Platform.version,
    'operatingSystem': Platform.operatingSystem,
    'operatingSystemVersion': Platform.operatingSystemVersion,
    'machineModel': _sysctl('hw.model'),
    'processor': _sysctl('machdep.cpu.brand_string'),
    'memoryBytes': _sysctl('hw.memsize'),
    'executionMode': isAot ? 'AOT' : 'JIT',
    'warmup': 'one unrecorded small-dataset run per operation',
  });

  for (final spec in _datasets) {
    final fixture = _buildSpatialFixture(spec);
    final outcomeProject = _buildOutcomeProject(spec.sourceCount);
    final diagnosticInputs = _diagnosticInputs(spec.eventCount);

    _measure(
      spec: spec,
      operation: 'spatial_catalog_build',
      operationInputs: fixture.operationInputs,
      run: () => buildNarrativeSpatialEventSourceCatalog(
        project: fixture.project,
        maps: fixture.maps,
      ).options.length,
    );
    _measure(
      spec: spec,
      operation: 'outcome_catalog_build',
      operationInputs: {
        'manifestMaps': 0,
        'loadedMaps': 0,
        'outcomeSources': spec.sourceCount,
        'events': 0,
      },
      run: () => buildNarrativeOutcomeEventSourceCatalog(
        project: outcomeProject,
      ).options.length,
    );
    _measure(
      spec: spec,
      operation: 'unified_read_model_build',
      operationInputs: fixture.operationInputs,
      run: () => buildNarrativeEventBuilderProjectReadModel(
        project: fixture.project,
        maps: fixture.maps,
      ).events.length,
    );

    final navigationIndex = buildNarrativeEventNavigationIndex(
      project: fixture.project,
      maps: fixture.maps,
    );
    _measure(
      spec: spec,
      operation: 'navigation_lookup',
      operationInputs: {
        ...fixture.operationInputs,
        'lookups': fixture.eventSources.length,
      },
      run: () {
        var available = 0;
        for (final source in fixture.eventSources) {
          if (navigationIndex.navigationForSource(source).available) {
            available++;
          }
        }
        return available;
      },
    );
    _measure(
      spec: spec,
      operation: 'diagnostic_deduplication',
      operationInputs: {
        'diagnosticInputs': diagnosticInputs.length,
        'uniqueDiagnostics': spec.eventCount,
        'duplicatesPerDiagnostic': 3,
      },
      run: () => deduplicateNarrativeEventReadValues(
        values: diagnosticInputs,
        keyOf: (value) => value.key,
        compare: (left, right) {
          for (final comparison in [
            left.severity.compareTo(right.severity),
            left.code.compareTo(right.code),
            left.message.compareTo(right.message),
          ]) {
            if (comparison != 0) return comparison;
          }
          return 0;
        },
      ).length,
    );
  }
}

void _measure({
  required _DatasetSpec spec,
  required String operation,
  required Map<String, Object?> operationInputs,
  required int Function() run,
}) {
  if (spec.name == 'small') {
    run();
  }
  final samples = <int>[];
  int? result;
  for (var index = 0; index < spec.iterations; index++) {
    final stopwatch = Stopwatch()..start();
    result = run();
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds);
  }
  final sorted = [...samples]..sort();
  final mean = samples.reduce((left, right) => left + right) / samples.length;
  final median = sorted.length.isOdd
      ? sorted[sorted.length ~/ 2].toDouble()
      : (sorted[sorted.length ~/ 2 - 1] + sorted[sorted.length ~/ 2]) / 2;
  _write({
    'kind': 'metric',
    'dataset': spec.name,
    'datasetTarget': {
      'maps': spec.mapCount,
      'sources': spec.sourceCount,
      'events': spec.eventCount,
    },
    'operation': operation,
    'operationInputs': operationInputs,
    'iterations': spec.iterations,
    'samplesMicros': samples,
    'meanMicros': mean.round(),
    'medianMicros': median.round(),
    'resultCount': result,
  });
}

_SpatialFixture _buildSpatialFixture(_DatasetSpec spec) {
  final entries = <ProjectMapEntry>[];
  final maps = <MapData>[];
  final sources = <NarrativeEventSourceRef>[];
  final loadedMapCount = spec.mapCount - 1;
  var remainingLocalSources = spec.sourceCount - spec.mapCount;
  var globalLocalSourceIndex = 0;
  var globalEntityIndex = 0;
  var globalTriggerIndex = 0;
  var multiCellSourceCount = 0;

  for (var mapIndex = 0; mapIndex < spec.mapCount; mapIndex++) {
    final mapId = 'map_$mapIndex';
    entries.add(
      ProjectMapEntry(
        id: mapId,
        name: 'Map $mapIndex',
        relativePath: 'maps/$mapId.json',
        sortOrder: mapIndex,
      ),
    );
    if (mapIndex == loadedMapCount) continue;

    final remainingMaps = loadedMapCount - mapIndex;
    final localSourceCount = remainingLocalSources ~/ remainingMaps;
    remainingLocalSources -= localSourceCount;
    final entities = <MapEntity>[];
    final triggers = <MapTrigger>[];
    for (var localIndex = 0; localIndex < localSourceCount; localIndex++) {
      final position = GridPos(
        x: localIndex % 100,
        y: (localIndex ~/ 100) % 100,
      );
      final multiCell = globalLocalSourceIndex % 10 == 0;
      final size = multiCell
          ? const GridSize(width: 2, height: 2)
          : const GridSize(width: 1, height: 1);
      if (multiCell) multiCellSourceCount++;
      if (globalLocalSourceIndex.isEven) {
        final entityId = 'entity_$globalEntityIndex';
        entities.add(
          MapEntity(
            id: entityId,
            name: 'Personnage $globalEntityIndex',
            kind: MapEntityKind.npc,
            pos: position,
            size: size,
          ),
        );
        sources.add(NarrativeEventSourceRef.entityInteract(mapId, entityId));
        globalEntityIndex++;
      } else {
        final triggerId = 'trigger_$globalTriggerIndex';
        triggers.add(
          MapTrigger(
            id: triggerId,
            name: 'Zone $globalTriggerIndex',
            type: TriggerType.event,
            area: MapRect(pos: position, size: size),
          ),
        );
        sources.add(NarrativeEventSourceRef.triggerEnter(mapId, triggerId));
        globalTriggerIndex++;
      }
      globalLocalSourceIndex++;
    }
    maps.add(
      MapData(
        id: mapId,
        name: 'Map $mapIndex',
        size: const GridSize(width: 100, height: 100),
        entities: entities,
        triggers: triggers,
      ),
    );
  }

  final records = <NarrativeEventRecord>[];
  final eventSources = <NarrativeEventSourceRef>[];
  for (var index = 0; index < spec.eventCount; index++) {
    final source = sources[index % sources.length];
    eventSources.add(source);
    records.add(_configuredEvent(index, source));
  }
  final project = ProjectManifest(
    name: 'Phase D performance ${spec.name}',
    maps: entries,
    tilesets: const [],
    scenes: [_simpleScene()],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: records,
      legacyClaims: const [],
    ),
  );
  return _SpatialFixture(
    project: project,
    maps: List.unmodifiable(maps),
    eventSources: List.unmodifiable(eventSources),
    manifestMapCount: spec.mapCount,
    entitySourceCount: globalEntityIndex,
    triggerSourceCount: globalTriggerIndex,
    multiCellSourceCount: multiCellSourceCount,
  );
}

ProjectManifest _buildOutcomeProject(int sourceCount) {
  return ProjectManifest(
    name: 'Phase D outcome performance',
    maps: const [],
    tilesets: const [],
    scenes: [
      SceneAsset(
        id: 'scene_outcomes',
        name: 'Scene à résultats multiples',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'end',
              kind: SceneNodeKind.end,
              payload: SceneEndPayload(sceneOutcomeId: 'outcome_0'),
            ),
          ],
          edges: [
            SceneEdge(
              id: 'edge_start_end',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
        declaredOutcomes: [
          for (var index = 0; index < sourceCount; index++)
            SceneOutcome(
              id: 'outcome_$index',
              label: 'Résultat $index',
            ),
        ],
      ),
    ],
  );
}

List<_DiagnosticSample> _diagnosticInputs(int uniqueCount) {
  return List.unmodifiable([
    for (var index = 0; index < uniqueCount; index++)
      for (var duplicate = 0; duplicate < 3; duplicate++)
        _DiagnosticSample(
          code: 'diagnostic_$index',
          severity: index % 3,
          message: 'Diagnostic humain $index',
        ),
  ]);
}

NarrativeEventRecord _configuredEvent(
  int index,
  NarrativeEventSourceRef source,
) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId(index),
      name: 'Event $index',
      source: source,
      conditions: const [],
      sceneId: 'scene_perf',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: index,
    ),
    enabled: true,
  );
}

SceneAsset _simpleScene() {
  return SceneAsset(
    id: 'scene_perf',
    name: 'Scene de performance',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

String _eventId(int index) {
  final first = index.toRadixString(16).padLeft(8, '0');
  final tail = index.toRadixString(16).padLeft(12, '0');
  return 'evt_$first-0000-7000-8000-$tail';
}

void _write(Map<String, Object?> value) {
  stdout.writeln(jsonEncode(value));
}

String _sysctl(String key) {
  if (!Platform.isMacOS) return 'not-available';
  final result = Process.runSync('/usr/sbin/sysctl', ['-n', key]);
  if (result.exitCode != 0) return 'not-available';
  return '${result.stdout}'.trim();
}

final class _DatasetSpec {
  const _DatasetSpec({
    required this.name,
    required this.mapCount,
    required this.sourceCount,
    required this.eventCount,
    required this.iterations,
  });

  final String name;
  final int mapCount;
  final int sourceCount;
  final int eventCount;
  final int iterations;
}

final class _SpatialFixture {
  const _SpatialFixture({
    required this.project,
    required this.maps,
    required this.eventSources,
    required this.manifestMapCount,
    required this.entitySourceCount,
    required this.triggerSourceCount,
    required this.multiCellSourceCount,
  });

  final ProjectManifest project;
  final List<MapData> maps;
  final List<NarrativeEventSourceRef> eventSources;
  final int manifestMapCount;
  final int entitySourceCount;
  final int triggerSourceCount;
  final int multiCellSourceCount;

  Map<String, Object?> get operationInputs => {
        'manifestMaps': manifestMapCount,
        'loadedMaps': maps.length,
        'missingMapSources': manifestMapCount - maps.length,
        'mapEnterSources': manifestMapCount,
        'entitySources': entitySourceCount,
        'triggerSources': triggerSourceCount,
        'multiCellSources': multiCellSourceCount,
        'totalSpatialOptions':
            manifestMapCount + entitySourceCount + triggerSourceCount,
        'events': eventSources.length,
      };
}

final class _DiagnosticSample {
  const _DiagnosticSample({
    required this.code,
    required this.severity,
    required this.message,
  });

  final String code;
  final int severity;
  final String message;

  String get key => '$code\u0000$severity\u0000$message';
}
