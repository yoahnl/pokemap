import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_controller.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_transaction.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_preview_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('BorderPreviewController', () {
    test('drag geometry is transient and keeps one seed for the whole drag',
        () {
      final map = _map();
      final before = map.toJson();
      final controller = BorderPreviewController(resolver: _success);

      controller.begin(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
      );
      final initialSeed = controller.state.transaction!.proposedFeature.seed;
      controller.updateGeometry(_region(<int>{0, 1}));
      controller.updateGeometry(_region(<int>{0, 1, 4}));

      expect(controller.state.phase, BorderPreviewPhase.drawing);
      expect(
        controller.state.transaction!.proposedFeature.seed,
        initialSeed,
      );
      expect(map.toJson(), before);

      controller.cancel();
      expect(controller.state, const BorderPreviewState.idle());
      expect(map.toJson(), before);
    });

    test('resolve, New Variation and Apply form one atomic map mutation', () {
      final map = _map();
      final before = map.toJson();
      var applyCalls = 0;
      final controller = BorderPreviewController(
        resolver: _success,
        applier: ({required map, required transaction}) {
          applyCalls += 1;
          expect(transaction.result!.canApply, isTrue);
          return map.copyWith(name: 'Applied');
        },
      );
      controller.begin(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
      );
      controller.updateGeometry(_region(<int>{0, 1, 4}));
      controller.resolve(
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );
      final beforeVariation = controller.state.transaction!;

      controller.newVariation();

      final afterVariation = controller.state.transaction!;
      expect(controller.state.phase, BorderPreviewPhase.resolved);
      expect(afterVariation.proposedFeature.geometry,
          beforeVariation.proposedFeature.geometry);
      expect(afterVariation.proposedFeature.seed,
          isNot(beforeVariation.proposedFeature.seed));
      expect(map.toJson(), before);
      expect(applyCalls, 0);

      final outcome = controller.apply(map);

      expect(outcome.applied, isTrue);
      expect(outcome.map.name, 'Applied');
      expect(applyCalls, 1);
      expect(controller.state, const BorderPreviewState.idle());
      expect(map.toJson(), before);
    });

    test('invalid preview and optimistic conflict never mutate the map', () {
      final map = _map();
      var applyCalls = 0;
      final invalid = BorderPreviewController(
        resolver: (_) => BorderResolutionResult(
          materialization: null,
          diagnosticReport: BorderDiagnosticsReport(
            diagnostics: <BorderDiagnostic>[
              BorderDiagnostic(
                code: 'border.test.invalid',
                severity: BorderDiagnosticSeverity.error,
                phase: BorderDiagnosticPhase.resolution,
                scope: BorderDiagnosticScope.feature,
                featureId: 'coast',
                suggestedAction: 'border.action.edit_geometry',
              ),
            ],
          ),
        ),
        applier: ({required map, required transaction}) {
          applyCalls += 1;
          return map.copyWith(name: 'Unexpected');
        },
      );
      invalid.begin(map: map, layerId: 'borders', featureId: 'coast');
      invalid.resolve(
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );

      expect(invalid.state.phase, BorderPreviewPhase.invalid);
      expect(invalid.apply(map).applied, isFalse);
      expect(applyCalls, 0);

      final conflict = BorderPreviewController(
        resolver: _success,
        applier: ({required map, required transaction}) => map,
      );
      conflict.begin(map: map, layerId: 'borders', featureId: 'coast');
      conflict.resolve(
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );

      final outcome = conflict.apply(map);
      expect(outcome.applied, isFalse);
      expect(outcome.map, same(map));
      expect(conflict.state.phase, BorderPreviewPhase.resolved);
    });

    test('EditorNotifier records Apply as exactly one undo entry', () {
      final map = _map();
      final collisionBefore =
          map.layers.whereType<CollisionLayer>().single.toJson();
      final preview = BorderPreviewController(
        resolver: _success,
        applier: ({required map, required transaction}) =>
            map.copyWith(name: 'Applied'),
      );
      final container = ProviderContainer(
        overrides: <Override>[
          borderPreviewControllerProvider.overrideWith((ref) => preview),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        activeMap: map,
        activeLayerId: 'borders',
        savedMapSnapshot: map,
      );
      preview.begin(map: map, layerId: 'borders', featureId: 'coast');
      preview.resolve(
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );

      expect(notifier.applyPendingBorderPreview(), isTrue);

      expect(notifier.state.mapUndoStack, hasLength(1));
      expect(notifier.state.mapRedoStack, isEmpty);
      expect(notifier.state.activeMap!.name, 'Applied');
      expect(
        notifier.state.activeMap!.layers
            .whereType<CollisionLayer>()
            .single
            .toJson(),
        collisionBefore,
      );
      expect(preview.state, const BorderPreviewState.idle());
    });
  });
}

BorderResolutionResult _success(BorderResolutionRequest request) {
  final ground = <BorderResolvedGroundCell>[
    BorderResolvedGroundCell(
      x: 0,
      y: 0,
      visualSnapshotId: _snapshotId,
      resolvedRole: SurfaceVariantRole.isolated,
    ),
  ];
  final components = computeBorderInputFingerprints(request);
  return BorderResolutionResult(
    materialization: BorderMaterialization(
      receipt: BorderResolutionReceipt(
        resolverVersion: request.resolverVersion,
        blueprintRevision: request.blueprintRevision!.revision,
        components: components,
        inputFingerprint: computeBorderAggregateInputFingerprint(
          resolverVersion: request.resolverVersion,
          blueprintRevision: request.blueprintRevision!.revision,
          components: components,
        ),
        outputFingerprint: computeBorderOutputFingerprint(
          ground: ground,
          placements: const <BorderResolvedPlacement>[],
        ),
      ),
      ground: ground,
      placements: const <BorderResolvedPlacement>[],
    ),
    diagnosticReport: const BorderDiagnosticsReport.empty(),
  );
}

MapData _map() => MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v2,
      size: const GridSize(width: 4, height: 3),
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
                geometry: _region(<int>{0}),
                overrides: const <BorderSlotOverride>[],
                keepOutRegions: const <BorderKeepOutRegion>[],
              ),
            ],
          ),
        ),
        const MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: <bool>[
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
            false,
          ],
        ),
      ],
    );

BorderRegionGeometry _region(Set<int> filled) => BorderRegionGeometry(
      width: 4,
      height: 3,
      cells: <bool>[
        for (var index = 0; index < 12; index += 1) filled.contains(index)
      ],
    );

BorderBlueprintRevision _revision() => BorderBlueprintRevision(
      revision: 1,
      definition: BorderBlueprintPublishedDefinition(
        name: 'Côte',
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.organicEdge,
        primitives: const <BorderPublishedPrimitive>[],
        defaults: BorderGenerationParams(
          irregularityPermille: 0,
          detailDensityPermille: 0,
          variationPermille: 0,
          maxOverlapPx: 0,
          gapTolerancePx: 0,
          depthRows: 1,
        ),
        sortOrder: 0,
      ),
    );

BorderVisualSnapshot _snapshot() => BorderVisualSnapshot(
      id: _snapshotId,
      contentFingerprint: 'a' * 64,
      frames: <BorderVisualFrameSnapshot>[
        BorderVisualFrameSnapshot(
          relativeAssetPath: 'assets/borders/snapshots/a.png',
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
          durationMs: 100,
        ),
      ],
    );

const _snapshotId =
    'border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
