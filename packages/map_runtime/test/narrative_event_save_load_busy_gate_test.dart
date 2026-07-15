import 'dart:io';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_port.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/infrastructure/file_game_save_repository.dart';

void main() {
  group('Narrative Event save/load busy gate', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('f1_busy_gate_');
    });

    tearDown(() async {
      await directory.delete(recursive: true);
    });

    for (final activity in NarrativeRuntimeActivity.values.where(
      (value) => value != NarrativeRuntimeActivity.idle,
    )) {
      test('$activity rejects save and load before filesystem lookup',
          () async {
        final gate = NarrativeRuntimeActivityGate();
        final repository = _TestFileGameSaveRepository(directory, gate);
        final lease = gate.enter(activity);

        await expectLater(
          repository.save(const GameState(saveId: 'save_f1')),
          throwsA(isA<NarrativeRuntimeCheckpointBlockedException>()),
        );
        await expectLater(
          repository.load(),
          throwsA(isA<NarrativeRuntimeCheckpointBlockedException>()),
        );

        expect(repository.pathLookupCount, 0);
        lease.close();
      });
    }

    test('idle gate permits save and load round-trip', () async {
      final gate = NarrativeRuntimeActivityGate();
      final repository = _TestFileGameSaveRepository(directory, gate);
      const state = GameState(saveId: 'save_f1', currentMapId: 'map_f1');

      await repository.save(state);
      final loaded = await repository.load();

      expect(loaded?.saveId, 'save_f1');
      expect(loaded?.currentMapId, 'map_f1');
      expect(repository.pathLookupCount, 2);
    });

    test('coordinator and repository share one runtime activity gate',
        () async {
      final gate = NarrativeRuntimeActivityGate();
      final port = NarrativeRuntimeActivityPort(gate);
      final repository = _TestFileGameSaveRepository(directory, gate);
      final source = NarrativeEventSourceRef.mapEnter('map');
      final record = NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: 'evt_019abcde-0000-7000-8000-000000000001',
          name: 'Event',
          source: source,
          conditions: const [],
          sceneId: 'scene',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        enabled: true,
      );
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [record],
        legacyClaims: const [],
      );
      final authority = NarrativeEventDispatchAuthority.prepare(
        registryResult: EventRegistryDecodeResult.decoded(registry),
        occurrence: NarrativeEventOccurrence(source: source),
        factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
        projectCatalog: _catalog(source, record),
      ) as NarrativeEventDispatchAuthorityReady;
      final started = Completer<void>();
      final release = Completer<void>();
      final coordinator = NarrativeEventExecutionCoordinator(
        stateTransactions: NarrativeEventStateTransactions(
          const GameState(saveId: 'save'),
        ),
        planner: NarrativeEventDispatchPlanner(),
        executeScene: (request) async {
          started.complete();
          await release.future;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        activityPort: port,
        executionIdFactory: () => 'evx_019abcde-0000-7000-8000-000000000002',
        correlationIdFactory: () => 'corr_019abcde-0000-7000-8000-000000000003',
        deliveryIdFactory: () => 'outd_019abcde-0000-7000-8000-000000000004',
      );

      final execution = coordinator.execute(authority: authority);
      await started.future;

      expect(gate.activity, NarrativeRuntimeActivity.sceneActive);
      await expectLater(
        repository.save(const GameState(saveId: 'save')),
        throwsA(isA<NarrativeRuntimeCheckpointBlockedException>()),
      );
      expect(repository.pathLookupCount, 0);

      release.complete();
      expect(await execution, isA<NarrativeEventExecutionSucceeded>());
      expect(gate.activity, NarrativeRuntimeActivity.idle);
    });
  });
}

NarrativeEventProjectCatalog _catalog(
  NarrativeEventSourceRef source,
  NarrativeEventRecord record,
) {
  return NarrativeEventProjectCatalog(
    manifestHash: 'runtime-composition',
    mapHashes: const {},
    spatialSources: NarrativeSpatialEventSourceCatalog(
      options: [
        NarrativeSpatialEventSourceOption(
          source: source,
          humanLabel: 'Map enter',
          humanDescription: 'Map enter',
          mapId: 'map',
          mapLabel: 'Map',
          sourceTypeLabel: 'Map enter',
          availability: NarrativeSpatialEventSourceAvailability.selectable,
          origin: NarrativeSpatialEventSourceOrigin.canonical,
          debugTechnicalLabel: 'mapEnter:map',
          geometry: const NarrativeSpatialSourceGeometrySummary.mapWide(),
          ownerKind: NarrativeSpatialEventSourceOwnerKind.map,
        ),
      ],
      diagnostics: const [],
    ),
    outcomeSources: NarrativeOutcomeEventSourceCatalog(
      options: const [],
      diagnostics: const [],
    ),
    scenes: [
      NarrativeEventProjectSceneEntry(
        scene: SceneAsset.fromJson(const {
          'id': 'scene',
          'name': 'Scene',
          'graph': {
            'startNodeId': 'start',
            'nodes': [
              {'id': 'start', 'kind': 'start'},
              {'id': 'end', 'kind': 'end'},
            ],
            'edges': [
              {
                'id': 'edge',
                'fromNodeId': 'start',
                'fromPortId': 'completed',
                'toNodeId': 'end',
                'kind': 'default',
              },
            ],
          },
        }),
        buildable: true,
      ),
    ],
    facts: const [],
    events: [
      NarrativeEventProjectEventEntry(
        record: record,
        proposed: false,
        inDependencyCycle: false,
        contextuallyValid: true,
      ),
    ],
    diagnostics: const [],
  );
}

final class _TestFileGameSaveRepository extends FileGameSaveRepository {
  _TestFileGameSaveRepository(this.directory, NarrativeRuntimeActivityGate gate)
      : super(activityGate: gate);

  final Directory directory;
  int pathLookupCount = 0;

  @override
  Future<String> getSaveFilePath() async {
    pathLookupCount++;
    return '${directory.path}/game_save.json';
  }
}
