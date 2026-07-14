import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_transaction.dart';
import 'package:map_editor/src/features/border_map_editing/application/pending_border_save_guard.dart';

void main() {
  group('PendingBorderSaveGuard', () {
    test('saves the current map directly when no preview is pending', () {
      final map = _map();

      final preparation = PendingBorderSaveGuard().prepare(
        currentMap: map,
        previewState: const BorderPreviewState.idle(),
        currentContext: _context(map),
        activeLayerId: 'borders',
        activeFeatureLayerId: 'borders',
        activeFeatureId: 'coast',
      );

      expect(preparation, isA<PendingBorderSaveReady>());
      final ready = preparation as PendingBorderSaveReady;
      expect(ready.candidateMap, same(map));
      expect(ready.postSaveAction, PendingBorderPostSaveAction.none);
      expect(ready.transaction, isNull);
    });

    test('requires an explicit decision for every pending preview phase', () {
      final map = _map();

      for (final phase in BorderPreviewPhase.values.where(
        (phase) => phase != BorderPreviewPhase.idle,
      )) {
        final preparation = PendingBorderSaveGuard().prepare(
          currentMap: map,
          previewState: BorderPreviewState(
            phase: phase,
            transaction: _transaction(map),
          ),
          currentContext: _context(map),
          activeLayerId: 'borders',
          activeFeatureLayerId: 'borders',
          activeFeatureId: 'coast',
        );

        expect(
          preparation,
          isA<PendingBorderSaveDecisionRequired>(),
          reason: phase.name,
        );
      }
    });

    test('Cancel Save and Discard never call the materialization applier', () {
      final map = _map();
      var applyCalls = 0;
      final guard = PendingBorderSaveGuard(
        applier: ({required map, required transaction}) {
          applyCalls += 1;
          return map.copyWith(name: 'unexpected');
        },
      );
      final preview = _resolvedPreview(map);

      final cancelled = guard.prepare(
        currentMap: map,
        previewState: preview,
        currentContext: _context(map),
        activeLayerId: 'borders',
        activeFeatureLayerId: 'borders',
        activeFeatureId: 'coast',
        decision: PendingBorderSaveDecision.cancelSave,
      );
      final discarded = guard.prepare(
        currentMap: map,
        previewState: preview,
        currentContext: _context(map),
        activeLayerId: 'borders',
        activeFeatureLayerId: 'borders',
        activeFeatureId: 'coast',
        decision: PendingBorderSaveDecision.discardAndSave,
      );

      expect(cancelled, isA<PendingBorderSaveCancelled>());
      expect(discarded, isA<PendingBorderSaveReady>());
      expect(
        (discarded as PendingBorderSaveReady).candidateMap,
        same(map),
      );
      expect(
        discarded.postSaveAction,
        PendingBorderPostSaveAction.discardPreview,
      );
      expect(applyCalls, 0);
    });

    test('Apply prepares a candidate without consuming the preview', () {
      final map = _map();
      final originalMap = map;
      final preview = _resolvedPreview(map);
      final candidate = map.copyWith(name: 'candidate');
      var applyCalls = 0;
      final guard = PendingBorderSaveGuard(
        applier: ({required map, required transaction}) {
          applyCalls += 1;
          expect(map, same(originalMap));
          expect(transaction, same(preview.transaction));
          return candidate;
        },
      );

      final preparation = guard.prepare(
        currentMap: map,
        previewState: preview,
        currentContext: preview.transaction!.context,
        activeLayerId: 'borders',
        activeFeatureLayerId: 'borders',
        activeFeatureId: 'coast',
        decision: PendingBorderSaveDecision.applyAndSave,
      );

      expect(preparation, isA<PendingBorderSaveReady>());
      final ready = preparation as PendingBorderSaveReady;
      expect(ready.candidateMap, same(candidate));
      expect(
        ready.postSaveAction,
        PendingBorderPostSaveAction.commitAppliedPreview,
      );
      expect(ready.transaction, same(preview.transaction));
      expect(preview.phase, BorderPreviewPhase.resolved);
      expect(preview.transaction, isNotNull);
      expect(applyCalls, 1);
    });

    test('Apply rejects invalid preview and every active identity drift', () {
      final map = _map();
      var applyCalls = 0;
      final guard = PendingBorderSaveGuard(
        applier: ({required map, required transaction}) {
          applyCalls += 1;
          return map.copyWith(name: 'unexpected');
        },
      );

      final cases = <BorderPreviewState>[
        BorderPreviewState(
          phase: BorderPreviewPhase.invalid,
          transaction: _transaction(map),
        ),
        _resolvedPreview(map),
        _resolvedPreview(map),
        _resolvedPreview(map),
      ];
      final identities = <(String?, String?, String?)>[
        ('borders', 'borders', 'coast'),
        ('other-layer', 'borders', 'coast'),
        ('borders', 'other-layer', 'coast'),
        ('borders', 'borders', 'other-feature'),
      ];

      for (var index = 0; index < cases.length; index += 1) {
        final identity = identities[index];
        final preparation = guard.prepare(
          currentMap: map,
          previewState: cases[index],
          currentContext: cases[index].transaction!.context,
          activeLayerId: identity.$1,
          activeFeatureLayerId: identity.$2,
          activeFeatureId: identity.$3,
          decision: PendingBorderSaveDecision.applyAndSave,
        );
        expect(
          preparation,
          isA<PendingBorderSaveConflict>(),
          reason: 'case $index',
        );
      }
      expect(applyCalls, 0);
    });

    test('Apply rejects a project or catalog context drift', () {
      final map = _map();
      final preview = _resolvedPreview(map);
      final transactionContext = preview.transaction!.context;
      var applyCalls = 0;
      final guard = PendingBorderSaveGuard(
        applier: ({required map, required transaction}) {
          applyCalls += 1;
          return map.copyWith(name: 'unexpected');
        },
      );
      final driftedContext = BorderPreviewContext(
        projectRootPath: transactionContext.projectRootPath,
        activeMapPath: transactionContext.activeMapPath,
        projectIdentity: transactionContext.projectIdentity,
        mapIdentity: transactionContext.mapIdentity,
        borderCatalogFingerprint: 'changed-catalog-fingerprint',
      );

      final preparation = guard.prepare(
        currentMap: map,
        previewState: preview,
        currentContext: driftedContext,
        activeLayerId: 'borders',
        activeFeatureLayerId: 'borders',
        activeFeatureId: 'coast',
        decision: PendingBorderSaveDecision.applyAndSave,
      );

      expect(preparation, isA<PendingBorderSaveConflict>());
      expect(applyCalls, 0);
      expect(preview.phase, BorderPreviewPhase.resolved);
    });

    test('Apply rejects a same-id map clone paired with the stale context', () {
      final originalMap = _map();
      final currentMapClone = originalMap.copyWith();
      final preview = _resolvedPreview(originalMap);
      var applyCalls = 0;
      final guard = PendingBorderSaveGuard(
        applier: ({required map, required transaction}) {
          applyCalls += 1;
          return map.copyWith(name: 'unexpected');
        },
      );

      final preparation = guard.prepare(
        currentMap: currentMapClone,
        previewState: preview,
        currentContext: preview.transaction!.context,
        activeLayerId: 'borders',
        activeFeatureLayerId: 'borders',
        activeFeatureId: 'coast',
        decision: PendingBorderSaveDecision.applyAndSave,
      );

      expect(preparation, isA<PendingBorderSaveConflict>());
      expect(applyCalls, 0);
      expect(preview.phase, BorderPreviewPhase.resolved);
    });

    test('Apply contains applier failures and same-map optimistic conflicts',
        () {
      final map = _map();
      final preview = _resolvedPreview(map);
      final sameMap = PendingBorderSaveGuard(
        applier: ({required map, required transaction}) => map,
      ).prepare(
        currentMap: map,
        previewState: preview,
        currentContext: preview.transaction!.context,
        activeLayerId: 'borders',
        activeFeatureLayerId: 'borders',
        activeFeatureId: 'coast',
        decision: PendingBorderSaveDecision.applyAndSave,
      );
      final throwing = PendingBorderSaveGuard(
        applier: ({required map, required transaction}) =>
            throw StateError('stale target'),
      ).prepare(
        currentMap: map,
        previewState: preview,
        currentContext: preview.transaction!.context,
        activeLayerId: 'borders',
        activeFeatureLayerId: 'borders',
        activeFeatureId: 'coast',
        decision: PendingBorderSaveDecision.applyAndSave,
      );

      expect(sameMap, isA<PendingBorderSaveConflict>());
      expect(throwing, isA<PendingBorderSaveConflict>());
      expect(map.name, 'Map');
      expect(preview.phase, BorderPreviewPhase.resolved);
    });
  });
}

MapData _map() => MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 2, height: 2),
      layers: <MapLayer>[
        MapLayer.border(
          id: 'borders',
          name: 'Bordures',
          content: BorderLayerContent(
            features: <BorderFeature>[
              BorderFeature(
                id: 'coast',
                name: 'Côte',
                blueprintId: 'coast-blueprint',
                seed: BorderSignedInt64.fromInt(7),
                geometry: BorderRegionGeometry(
                  width: 2,
                  height: 2,
                  cells: const <bool>[true, false, false, false],
                ),
                overrides: const <BorderSlotOverride>[],
                keepOutRegions: const <BorderKeepOutRegion>[],
              ),
            ],
          ),
        ),
      ],
    );

BorderPreviewTransaction _transaction(MapData map) {
  final feature =
      map.layers.whereType<BorderLayer>().single.content.features.single;
  return BorderPreviewTransaction(
    context: _context(map),
    mapId: map.id,
    mapSize: map.size,
    layerId: 'borders',
    featureId: feature.id,
    baseFeatureFingerprint: computeBorderFeatureEditFingerprint(feature),
    proposedFeature: feature,
    variationOrdinal: 0,
    request: _request(feature),
    result: _result(),
  );
}

BorderPreviewContext _context(MapData map) => BorderPreviewContext(
      projectRootPath: '/project',
      activeMapPath: '/project/maps/map.json',
      projectIdentity: map,
      mapIdentity: map,
      borderCatalogFingerprint: 'catalog-fingerprint',
    );

BorderPreviewState _resolvedPreview(MapData map) => BorderPreviewState(
      phase: BorderPreviewPhase.resolved,
      transaction: _transaction(map),
    );

BorderResolutionRequest _request(BorderFeature feature) =>
    BorderResolutionRequest(
      mapSize: const GridSize(width: 2, height: 2),
      tileSizePx: const GridSize(width: 16, height: 16),
      blueprintId: feature.blueprintId,
      blueprintRevision: null,
      feature: feature,
      visualSnapshots: const <BorderVisualSnapshot>[],
      resolverVersion: 1,
    );

BorderResolutionResult _result() => BorderResolutionResult(
      materialization: BorderMaterialization(
        receipt: BorderResolutionReceipt(
          resolverVersion: 1,
          blueprintRevision: 1,
          components: BorderInputFingerprints(
            blueprint: _fingerprint('1'),
            geometryAndSeed: _fingerprint('2'),
            parameters: _fingerprint('3'),
            overrides: _fingerprint('4'),
            keepOutRegions: _fingerprint('5'),
            mapContext: _fingerprint('6'),
            visualSnapshots: _fingerprint('7'),
          ),
          inputFingerprint: _fingerprint('8'),
          outputFingerprint: _fingerprint('9'),
        ),
        ground: <BorderResolvedGroundCell>[
          BorderResolvedGroundCell(
            x: 0,
            y: 0,
            visualSnapshotId: 'border-snapshot-sha256:${'a' * 64}',
            resolvedRole: SurfaceVariantRole.isolated,
          ),
        ],
        placements: const <BorderResolvedPlacement>[],
      ),
      diagnosticReport: const BorderDiagnosticsReport.empty(),
    );

String _fingerprint(String digit) => 'sha256:${digit * 64}';
