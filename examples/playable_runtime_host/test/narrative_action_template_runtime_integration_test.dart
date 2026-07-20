import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';

// Cross-package integration proof: the host executes the exact editor output.
// ignore: avoid_relative_lib_imports
import '../../../packages/map_editor/lib/src/application/services/narrative_template_catalog.dart';

const _eventId = 'evt_019abcde-6000-7000-8000-000000000001';
const _sceneId = 'scene.template.item.ball';
const _mapId = 'map_port';
const _objectId = 'object_potion';
const _itemId = 'item_potion';

void main() {
  test(
    'generated Event→Scene→Action survives reload without double reward',
    () async {
      final before = ProjectManifest(
        name: 'Template runtime fixture',
        maps: const [
          ProjectMapEntry(
            id: _mapId,
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        tilesets: const [],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: const [],
          legacyClaims: const [],
        ),
      );
      final preview = previewNarrativeTemplate(
        project: before,
        request: NarrativeTemplateRequest(
          kind: NarrativeTemplateKind.itemBall,
          eventId: _eventId,
          sceneId: _sceneId,
          name: 'Potion au sol',
          source: NarrativeEventSourceRef.entityInteract(_mapId, _objectId),
          physicalSource: const NarrativeTemplatePhysicalSource(
            kind: NarrativeTemplatePhysicalSourceKind.object,
            mapId: _mapId,
            sourceId: _objectId,
            exists: true,
          ),
          parameters: const {'itemId': _itemId, 'quantity': '2'},
        ),
      );
      expect(preview.canApply, isTrue);

      final project = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(preview.after!.toJson())) as Map<String, dynamic>,
      );
      const map = MapData(
        id: _mapId,
        name: 'Port',
        size: GridSize(width: 4, height: 4),
        layers: [MapLayer.object(id: 'objects', name: 'Objects')],
        entities: [
          MapEntity(
            id: _objectId,
            name: 'Potion',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );
      final catalog = buildNarrativeEventProjectCatalog(
        project: project,
        maps: [map],
      );
      final occurrence = NarrativeEventOccurrence(
        source: NarrativeEventSourceRef.entityInteract(_mapId, _objectId),
      );
      var state = const GameState(saveId: 'template-runtime');
      var sequence = 0;

      Future<NarrativeSpatialProductionDispatchResult> dispatch(
        String occurrenceId,
      ) async {
        final transactions = NarrativeEventStateTransactions(state);
        final bridge = NarrativeSpatialProductionDispatchBridge(
          stateTransactions: transactions,
          currentGameState: () => state,
          onGameStateCommitted: (next) => state = next,
          prepareAuthority: (_, currentOccurrence) async =>
              NarrativeEventDispatchAuthority.prepare(
            registryResult: EventRegistryDecodeResult.decoded(
              project.eventRegistry!,
            ),
            occurrence: currentOccurrence,
            factResolver: NarrativeFactRuntimeResolver.fromFacts(
              project.facts,
            ),
            projectCatalog: catalog,
          ),
          executeScene: (request) => executeNarrativeEventScene(
            request: request,
            project: project,
            mapsById: {_mapId: map},
            currentGameState: () => state,
            callbacks: SceneRuntimeHostCallbacks(
              evaluateCondition: (_) => 'false',
              showDialogue: (_) => 'completed',
              startBattle: (_) => 'victory',
              playCinematic: (_) => 'completed',
            ),
          ),
          legacyFallback: (_, __, ___) async =>
              fail('A generated V2 template must not use legacy fallback.'),
          activityPort: NoopNarrativeEventActivityPort(),
          isCurrentOccurrence: (_) => true,
          executionIdFactory: () => _runtimeId('evx', ++sequence),
          correlationIdFactory: () => _runtimeId('corr', ++sequence),
          deliveryIdFactory: () => _runtimeId('outd', ++sequence),
        );
        return bridge.dispatch(
          occurrenceId: occurrenceId,
          occurrence: occurrence,
        );
      }

      final first = await dispatch('template-item-ball-1');
      expect(first, isA<NarrativeSpatialProductionDispatchV2Handled>());
      expect(_itemQuantity(state, _itemId), 2);
      expect(
        state.narrativeEventProgress.consumedNarrativeEventIds,
        contains(_eventId),
      );

      state = GameState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
      );
      final afterReload = await dispatch('template-item-ball-2');
      expect(
        afterReload,
        isA<NarrativeSpatialProductionDispatchNoFallback>(),
      );
      expect(_itemQuantity(state, _itemId), 2);
    },
  );
}

int _itemQuantity(GameState state, String itemId) => state.bag.entries
    .where((entry) => entry.itemId == itemId)
    .fold(0, (total, entry) => total + entry.quantity);

String _runtimeId(String prefix, int sequence) =>
    '${prefix}_019abcde-6000-7000-8000-${sequence.toString().padLeft(12, '0')}';
