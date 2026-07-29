@Tags(['performance'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_event_validation_coordinator.dart';

const _recordCount = 500;
const _sourceCount = 100;
const _sceneCount = 50;
const _factCount = 100;
const _warmupIterations = 10;
const _measuredIterations = 50;
const _p95BudgetMicroseconds = 36000;

void main() {
  test(
    'incremental validation equals a full rebuild for Event, source, and '
    'Scene invalidation',
    () {
      const coordinator = NarrativeEventValidationCoordinator();
      final fixture = _ValidationFixture.create();
      final initial = coordinator.rebuildIncrementally(
        registry: fixture.registry,
        catalog: fixture.catalog(),
      );

      final mutatedRegistry = fixture.registryWithRenamedEvent(0);
      final eventMutation = coordinator.rebuildIncrementally(
        registry: mutatedRegistry,
        catalog: fixture.catalog(registry: mutatedRegistry),
        previous: initial.cache,
      );
      _expectEquivalentToFullBuild(
        eventMutation,
        registry: mutatedRegistry,
        catalog: fixture.catalog(registry: mutatedRegistry),
      );
      expect(
        eventMutation.recalculatedEventIds,
        {_eventId(0), _eventId(1), _eventId(2)},
      );

      final sourceCatalog = fixture.catalog(removedSourceIndex: 0);
      final sourceDeletion = coordinator.rebuildIncrementally(
        registry: fixture.registry,
        catalog: sourceCatalog,
        previous: initial.cache,
      );
      _expectEquivalentToFullBuild(
        sourceDeletion,
        registry: fixture.registry,
        catalog: sourceCatalog,
      );
      expect(
        sourceDeletion.recalculatedEventIds,
        _withDependents({for (var index = 0; index < 500; index += 100) index}),
      );

      final sceneCatalog = fixture.catalog(removedSceneIndex: 0);
      final sceneDeletion = coordinator.rebuildIncrementally(
        registry: fixture.registry,
        catalog: sceneCatalog,
        previous: initial.cache,
      );
      _expectEquivalentToFullBuild(
        sceneDeletion,
        registry: fixture.registry,
        catalog: sceneCatalog,
      );
      expect(
        sceneDeletion.recalculatedEventIds,
        _withDependents({for (var index = 0; index < 500; index += 50) index}),
      );

      final factCatalog = fixture.catalog(removedFactIndex: 0);
      final factDeletion = coordinator.rebuildIncrementally(
        registry: fixture.registry,
        catalog: factCatalog,
        previous: initial.cache,
      );
      _expectEquivalentToFullBuild(
        factDeletion,
        registry: fixture.registry,
        catalog: factCatalog,
      );
      expect(
        factDeletion.recalculatedEventIds,
        _withDependents({for (var index = 0; index < 500; index += 100) index}),
      );

      final globalCatalog = fixture.catalog(includeGlobalDiagnostic: true);
      final globalChange = coordinator.rebuildIncrementally(
        registry: fixture.registry,
        catalog: globalCatalog,
        previous: initial.cache,
      );
      _expectEquivalentToFullBuild(
        globalChange,
        registry: fixture.registry,
        catalog: globalCatalog,
      );
      expect(globalChange.recalculatedEventIds, isEmpty);

      final modeRegistry = fixture.registryWithMode(EventSystemMode.v2Only);
      final modeCatalog = fixture.catalog(registry: modeRegistry);
      final modeChange = coordinator.rebuildIncrementally(
        registry: modeRegistry,
        catalog: modeCatalog,
        previous: initial.cache,
      );
      _expectEquivalentToFullBuild(
        modeChange,
        registry: modeRegistry,
        catalog: modeCatalog,
      );
      expect(modeChange.recalculatedEventIds, isEmpty);

      final removedRegistry = fixture.registryWithoutLastEvent();
      final removedCatalog = fixture.catalog(registry: removedRegistry);
      final recordSetChange = coordinator.rebuildIncrementally(
        registry: removedRegistry,
        catalog: removedCatalog,
        previous: initial.cache,
      );
      _expectEquivalentToFullBuild(
        recordSetChange,
        registry: removedRegistry,
        catalog: removedCatalog,
      );
      expect(
        recordSetChange.recalculatedEventIds,
        {
          for (var index = 0; index < _recordCount - 1; index++) _eventId(index)
        },
      );
    },
  );

  test('incremental validation keeps the frozen Phase 3 p95 budget', () {
    const coordinator = NarrativeEventValidationCoordinator();
    final fixture = _ValidationFixture.create();
    final initial = coordinator.rebuildIncrementally(
      registry: fixture.registry,
      catalog: fixture.catalog(),
    );
    final mutatedRegistry = fixture.registryWithRenamedEvent(0);
    final mutatedCatalog = fixture.catalog(registry: mutatedRegistry);

    NarrativeEventIncrementalValidationResult run() {
      return coordinator.rebuildIncrementally(
        registry: mutatedRegistry,
        catalog: mutatedCatalog,
        previous: initial.cache,
      );
    }

    for (var index = 0; index < _warmupIterations; index++) {
      run();
    }
    final samples = <int>[];
    NarrativeEventIncrementalValidationResult? last;
    for (var index = 0; index < _measuredIterations; index++) {
      final stopwatch = Stopwatch()..start();
      last = run();
      stopwatch.stop();
      samples.add(stopwatch.elapsedMicroseconds);
    }

    final sorted = [...samples]..sort();
    final p50 = sorted[(sorted.length * 0.50).ceil() - 1];
    final p95 = sorted[(sorted.length * 0.95).ceil() - 1];
    stdout.writeln(
      'NS_EVENT_V2_PHASE_3_INCREMENTAL_BASELINE '
      'os=${Platform.operatingSystem} '
      'os_version=${_singleLine(Platform.operatingSystemVersion)} '
      'dart=${Platform.version.split(' ').first} '
      'processors=${Platform.numberOfProcessors} '
      'records=$_recordCount sources=$_sourceCount scenes=$_sceneCount '
      'facts=$_factCount warmups=$_warmupIterations '
      'iterations=$_measuredIterations execution=sequential '
      'p50_us=$p50 p95_us=$p95 '
      'recalculated=${last!.recalculatedEventIds.length} '
      'unaffected=${_recordCount - last.recalculatedEventIds.length} '
      'budget_p95_us=$_p95BudgetMicroseconds threshold=frozen',
    );

    expect(
      last.recalculatedEventIds,
      {_eventId(0), _eventId(1), _eventId(2)},
    );
    expect(
      _recordCount - last.recalculatedEventIds.length,
      497,
      reason: 'A local rename must not recompute unrelated Event reports.',
    );
    expect(
      last.report.toDebugJson(),
      buildNarrativeEventValidationReport(
        registry: mutatedRegistry,
        catalog: mutatedCatalog,
      ).toDebugJson(),
    );
    expect(
      p95,
      lessThanOrEqualTo(_p95BudgetMicroseconds),
      reason: 'The Phase 3 p95 budget was frozen after the baseline run.',
    );
  });
}

void _expectEquivalentToFullBuild(
  NarrativeEventIncrementalValidationResult result, {
  required NarrativeEventRegistry registry,
  required NarrativeEventProjectCatalog catalog,
}) {
  expect(
    result.report.toDebugJson(),
    buildNarrativeEventValidationReport(
      registry: registry,
      catalog: catalog,
    ).toDebugJson(),
  );
}

Set<String> _withDependents(Set<int> directlyChanged) {
  final result = {...directlyChanged};
  if (result.contains(0)) {
    result
      ..add(1)
      ..add(2);
  } else if (result.contains(1)) {
    result.add(2);
  }
  return {for (final index in result) _eventId(index)};
}

String _eventId(int index) {
  return 'evt_019abcde-0000-7000-8000-'
      '${index.toRadixString(16).padLeft(12, '0')}';
}

String _singleLine(String value) => value.replaceAll(RegExp(r'\s+'), '_');

final class _ValidationFixture {
  _ValidationFixture._({required this.registry});

  factory _ValidationFixture.create() {
    return _ValidationFixture._(
      registry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.dualRead,
        records: [
          for (var index = 0; index < _recordCount; index++) _record(index)
        ],
        legacyClaims: const [],
      ),
    );
  }

  final NarrativeEventRegistry registry;

  NarrativeEventRegistry registryWithRenamedEvent(int renamedIndex) {
    return NarrativeEventRegistry(
      schemaVersion: registry.schemaVersion,
      mode: registry.mode,
      records: [
        for (var index = 0; index < _recordCount; index++)
          _record(
            index,
            name: index == renamedIndex ? 'Event $index renamed' : null,
          ),
      ],
      legacyClaims: registry.legacyClaims,
    );
  }

  NarrativeEventRegistry registryWithoutLastEvent() {
    return NarrativeEventRegistry(
      schemaVersion: registry.schemaVersion,
      mode: registry.mode,
      records: registry.records.take(_recordCount - 1).toList(),
      legacyClaims: registry.legacyClaims,
    );
  }

  NarrativeEventRegistry registryWithMode(EventSystemMode mode) {
    return NarrativeEventRegistry(
      schemaVersion: registry.schemaVersion,
      mode: mode,
      records: registry.records,
      legacyClaims: registry.legacyClaims,
    );
  }

  NarrativeEventProjectCatalog catalog({
    NarrativeEventRegistry? registry,
    int? removedSourceIndex,
    int? removedSceneIndex,
    int? removedFactIndex,
    bool includeGlobalDiagnostic = false,
  }) {
    final effectiveRegistry = registry ?? this.registry;
    final availableSourceIndexes = {
      for (var index = 0; index < _sourceCount; index++)
        if (index != removedSourceIndex) index,
    };
    final availableSceneIndexes = {
      for (var index = 0; index < _sceneCount; index++)
        if (index != removedSceneIndex) index,
    };
    final availableFactIndexes = {
      for (var index = 0; index < _factCount; index++)
        if (index != removedFactIndex) index,
    };
    final diagnostics = <NarrativeEventProjectDiagnostic>[];
    if (includeGlobalDiagnostic) {
      diagnostics.add(
        NarrativeEventProjectDiagnostic(
          code: 'fixtureGlobalDiagnostic',
          severity: NarrativeEventProjectDiagnosticSeverity.warning,
          message: 'Le registre de test doit être vérifié.',
          path: 'eventRegistry',
        ),
      );
    }
    final invalidEventIds = <String>{};
    for (var index = 0; index < effectiveRegistry.records.length; index++) {
      final eventId = _eventId(index);
      if (!availableSourceIndexes.contains(index % _sourceCount)) {
        invalidEventIds.add(eventId);
        diagnostics.add(
          NarrativeEventProjectDiagnostic(
            code: 'narrativeEventSourceMissing',
            severity: NarrativeEventProjectDiagnosticSeverity.error,
            message:
                'La source de cet Event ne résout pas une option utilisable.',
            path: 'eventRegistry.records.$eventId.source',
          ),
        );
      }
      if (!availableSceneIndexes.contains(index % _sceneCount)) {
        invalidEventIds.add(eventId);
        diagnostics.add(
          NarrativeEventProjectDiagnostic(
            code: 'narrativeEventSceneMissing',
            severity: NarrativeEventProjectDiagnosticSeverity.error,
            message: 'La Scene de cet Event doit être unique et exécutable.',
            path: 'eventRegistry.records.$eventId.sceneId',
          ),
        );
      }
      if (index != 1 &&
          index != 2 &&
          !availableFactIndexes.contains(index % _factCount)) {
        invalidEventIds.add(eventId);
        diagnostics.add(
          NarrativeEventProjectDiagnostic(
            code: 'narrativeEventFactMissing',
            severity: NarrativeEventProjectDiagnosticSeverity.error,
            message: 'Le Fact référencé doit exister exactement une fois.',
            path: 'eventRegistry.records.$eventId.conditions.0.factId',
          ),
        );
      }
    }
    diagnostics.sort((left, right) {
      final path = compareNarrativeEventUtf16(left.path, right.path);
      return path != 0
          ? path
          : compareNarrativeEventUtf16(left.code, right.code);
    });

    return NarrativeEventProjectCatalog(
      manifestHash:
          'manifest-${availableSourceIndexes.length}-${availableSceneIndexes.length}',
      mapHashes: {
        for (final index in availableSourceIndexes)
          'map_${index.toString().padLeft(3, '0')}': 'hash-$index',
      },
      spatialSources: NarrativeSpatialEventSourceCatalog(
        options: [
          for (final index in availableSourceIndexes) _sourceOption(index),
        ],
        diagnostics: const [],
      ),
      outcomeSources: NarrativeOutcomeEventSourceCatalog(
        options: const [],
        diagnostics: const [],
      ),
      scenes: [
        for (final index in availableSceneIndexes) _sceneEntry(index),
      ],
      facts: [for (final index in availableFactIndexes) _factEntry(index)],
      events: [
        for (final record in effectiveRegistry.records)
          NarrativeEventProjectEventEntry(
            record: record,
            proposed: false,
            inDependencyCycle: false,
            contextuallyValid: !invalidEventIds.contains(record.id),
          ),
      ],
      diagnostics: diagnostics,
    );
  }
}

NarrativeEventRecord _record(int index, {String? name}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId(index),
      name: name ?? 'Event $index',
      source: NarrativeEventSourceRef.mapEnter(
        'map_${(index % _sourceCount).toString().padLeft(3, '0')}',
      ),
      conditions: [
        if (index == 1)
          NarrativeEventCondition.narrativeEventConsumed(_eventId(0), true)
        else if (index == 2)
          NarrativeEventCondition.narrativeEventConsumed(_eventId(1), true)
        else
          NarrativeEventCondition.fact(
            'fact_${(index % _factCount).toString().padLeft(3, '0')}',
            true,
          ),
      ],
      sceneId: 'scene_${(index % _sceneCount).toString().padLeft(3, '0')}',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: index,
    ),
    enabled: true,
  );
}

NarrativeSpatialEventSourceOption _sourceOption(int index) {
  final mapId = 'map_${index.toString().padLeft(3, '0')}';
  return NarrativeSpatialEventSourceOption(
    source: NarrativeEventSourceRef.mapEnter(mapId),
    humanLabel: 'Entrée sur Map $index',
    humanDescription: 'Quand le joueur entre sur Map $index',
    mapId: mapId,
    mapLabel: 'Map $index',
    sourceTypeLabel: 'Entrée sur une map',
    availability: NarrativeSpatialEventSourceAvailability.selectable,
    origin: NarrativeSpatialEventSourceOrigin.canonical,
    debugTechnicalLabel: 'mapEnter:$mapId',
    geometry: const NarrativeSpatialSourceGeometrySummary.mapWide(),
    ownerKind: NarrativeSpatialEventSourceOwnerKind.map,
  );
}

NarrativeEventProjectSceneEntry _sceneEntry(int index) {
  final sceneId = 'scene_${index.toString().padLeft(3, '0')}';
  return NarrativeEventProjectSceneEntry(
    scene: SceneAsset.fromJson({
      'id': sceneId,
      'name': 'Scene $index',
      'graph': const {
        'startNodeId': 'start',
        'nodes': [
          {'id': 'start', 'kind': 'start'},
          {'id': 'end', 'kind': 'end'},
        ],
        'edges': [
          {
            'id': 'edge_end',
            'fromNodeId': 'start',
            'fromPortId': 'completed',
            'toNodeId': 'end',
            'kind': 'default',
          },
        ],
      },
    }),
    buildable: true,
  );
}

NarrativeEventProjectFactEntry _factEntry(int index) {
  final factId = 'fact_${index.toString().padLeft(3, '0')}';
  return NarrativeEventProjectFactEntry(
    NarrativeFactDefinition(id: factId, label: 'Fact $index'),
  );
}
