import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/apply_border_materialization.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_controller.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_transaction.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_map_editing_providers.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_preview_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('BorderPreviewController', () {
    test(
        'rejects a resolved preview when an indistinguishable cloned project and map become active',
        () {
      final originalMap = _map();
      final clonedMap = MapData.fromJson(originalMap.toJson());
      final originalProject = _project();
      final clonedProject = ProjectManifest.fromJson(originalProject.toJson());
      var applyCalls = 0;
      final controller = BorderPreviewController(
        resolver: _success,
        applier: ({required map, required transaction}) {
          applyCalls += 1;
          return map.copyWith(name: 'Unexpected');
        },
      );
      final originalContext = createEditorBorderPreviewContext(
        projectRootPath: '/projects/same',
        activeMapPath: '/projects/same/maps/map.json',
        project: originalProject,
        map: originalMap,
      );
      final clonedContext = createEditorBorderPreviewContext(
        projectRootPath: '/projects/same',
        activeMapPath: '/projects/same/maps/map.json',
        project: clonedProject,
        map: clonedMap,
      );
      expect(originalMap.id, clonedMap.id);
      expect(
        computeBorderFeatureEditFingerprint(_feature(originalMap, 'coast')),
        computeBorderFeatureEditFingerprint(_feature(clonedMap, 'coast')),
      );

      controller.begin(
        map: originalMap,
        layerId: 'borders',
        featureId: 'coast',
        context: originalContext,
      );
      controller.updateGeometry(_region(<int>{0, 1, 4}));
      controller.resolve(
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );

      final outcome = controller.apply(clonedMap, context: clonedContext);

      expect(outcome.applied, isFalse);
      expect(outcome.map, same(clonedMap));
      expect(applyCalls, 0);
      expect(controller.state.phase, BorderPreviewPhase.resolved);
    });

    test('catalog drift rejects Apply and context reconciliation cancels', () {
      final map = _map();
      final project = _project();
      final context = createEditorBorderPreviewContext(
        projectRootPath: '/projects/one',
        activeMapPath: '/projects/one/maps/map.json',
        project: project,
        map: map,
      );
      final changedCatalogContext = BorderPreviewContext(
        projectRootPath: context.projectRootPath,
        activeMapPath: context.activeMapPath,
        projectIdentity: context.projectIdentity,
        mapIdentity: context.mapIdentity,
        borderCatalogFingerprint: 'catalog-changed',
      );
      var applyCalls = 0;
      final controller = BorderPreviewController(
        resolver: _success,
        applier: ({required map, required transaction}) {
          applyCalls += 1;
          return map.copyWith(name: 'Unexpected');
        },
      );
      controller.begin(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
        context: context,
      );
      controller.updateGeometry(_region(<int>{0, 1, 4}));
      controller.resolve(
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );

      expect(
        controller.apply(map, context: changedCatalogContext).applied,
        isFalse,
      );
      expect(applyCalls, 0);
      expect(controller.state.phase, BorderPreviewPhase.resolved);

      controller.reconcileContext(changedCatalogContext);

      expect(controller.state, const BorderPreviewState.idle());
    });

    test('drag geometry is transient and keeps one seed for the whole drag',
        () {
      final map = _map();
      final before = map.toJson();
      final controller = BorderPreviewController(resolver: _success);

      controller.begin(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
        context: _contextFor(map),
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

    test(
        'Update preview is explicit and Keep Materialized is a strict map no-op',
        () {
      final map = _map();
      final before = map.toJson();
      final oldMaterialization = _feature(map, 'coast').materialization;
      final controller = BorderPreviewController(resolver: _success);

      controller.beginUpdatePreview(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
        context: _contextFor(map),
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: borderResolverVersion,
      );

      expect(controller.state.phase, BorderPreviewPhase.resolved);
      expect(controller.state.transaction!.proposedFeature.geometry,
          _feature(map, 'coast').geometry);
      expect(controller.state.transaction!.proposedFeature.materialization,
          isNull);
      expect(map.toJson(), before);
      expect(_feature(map, 'coast').materialization, same(oldMaterialization));

      controller.keepMaterialized();

      expect(controller.state, const BorderPreviewState.idle());
      expect(map.toJson(), before);
      expect(_feature(map, 'coast').materialization, same(oldMaterialization));
    });

    test('feature draft resolves overrides without mutating the map', () {
      final map = _map();
      final before = map.toJson();
      final controller = BorderPreviewController(resolver: _success);
      controller.begin(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
        context: _contextFor(map),
      );
      final source = _feature(map, 'coast');
      final override = BorderSlotOverride(
        slotKey: source.materialization!.placements.first.slotKey,
        variationSalt: BorderSignedInt64.fromInt(41),
        suppressed: false,
        locked: false,
      );
      final draft = BorderFeature(
        id: source.id,
        name: source.name,
        blueprintId: source.blueprintId,
        seed: source.seed,
        geometry: source.geometry,
        paramsOverride: source.paramsOverride,
        overrides: <BorderSlotOverride>[override],
        keepOutRegions: source.keepOutRegions,
        materialization: source.materialization,
      );

      controller.previewFeatureDraft(
        draft,
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );

      expect(controller.state.phase, BorderPreviewPhase.resolved);
      expect(controller.state.transaction!.proposedFeature.overrides,
          <BorderSlotOverride>[override]);
      expect(controller.state.transaction!.proposedFeature.materialization,
          isNull);
      expect(controller.state.transaction!.request!.feature.materialization,
          isNull);
      expect(map.toJson(), before);
    });

    test('feature draft rejects feature and blueprint identity drift', () {
      final map = _map();
      final source = _feature(map, 'coast');
      for (final drifted in <BorderFeature>[
        BorderFeature(
          id: 'other-feature',
          name: source.name,
          blueprintId: source.blueprintId,
          seed: source.seed,
          geometry: source.geometry,
          paramsOverride: source.paramsOverride,
          overrides: source.overrides,
          keepOutRegions: source.keepOutRegions,
        ),
        BorderFeature(
          id: source.id,
          name: source.name,
          blueprintId: 'other-blueprint',
          seed: source.seed,
          geometry: source.geometry,
          paramsOverride: source.paramsOverride,
          overrides: source.overrides,
          keepOutRegions: source.keepOutRegions,
        ),
      ]) {
        final controller = BorderPreviewController(resolver: _success);
        controller.begin(
          map: map,
          layerId: 'borders',
          featureId: 'coast',
          context: _contextFor(map),
        );

        expect(
          () => controller.previewFeatureDraft(
            drifted,
            blueprintRevision: _revision(),
            tileSizePx: const GridSize(width: 16, height: 16),
            visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
            resolverVersion: 1,
          ),
          throwsArgumentError,
        );
        expect(controller.state.phase, BorderPreviewPhase.drawing);
      }
    });

    test('resolves transient drag updates and freezes only on release', () {
      final map = _map();
      final before = map.toJson();
      final controller = BorderPreviewController(resolver: _success);
      controller.begin(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
        context: _contextFor(map),
      );
      final seed = controller.state.transaction!.proposedFeature.seed;

      controller.previewGeometry(
        _region(<int>{0, 1, 4}),
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );

      expect(controller.state.phase, BorderPreviewPhase.drawing);
      expect(controller.state.transaction!.result?.canApply, isTrue);
      expect(controller.state.transaction!.proposedFeature.seed, seed);
      expect(map.toJson(), before);

      controller.finishDrawing();

      expect(controller.state.phase, BorderPreviewPhase.resolved);
      expect(controller.state.transaction!.result?.canApply, isTrue);
      expect(map.toJson(), before);
    });

    test('resume drawing requires the exact transaction layer and feature', () {
      final map = _map();
      final controller = BorderPreviewController(resolver: _success);
      controller.begin(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
        context: _contextFor(map),
      );
      controller.resolve(
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );
      final resolved = controller.state;

      expect(
        controller.resumeDrawing(
          layerId: 'borders',
          featureId: 'other-feature',
        ),
        isFalse,
      );
      expect(controller.state, same(resolved));

      expect(
        controller.resumeDrawing(
          layerId: 'borders',
          featureId: 'coast',
        ),
        isTrue,
      );
      expect(controller.state.phase, BorderPreviewPhase.drawing);
      expect(controller.state.transaction, same(resolved.transaction));
    });

    test('rolling back an invalid second gesture keeps the resolved preview',
        () {
      final map = _map();
      final controller = BorderPreviewController(resolver: _success);
      controller.begin(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
        context: _contextFor(map),
      );
      controller.previewGeometry(
        _region(<int>{0, 1, 4}),
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );
      controller.finishDrawing();
      final firstResolved = controller.state.transaction!;

      expect(
        controller.resumeDrawing(layerId: 'borders', featureId: 'coast'),
        isTrue,
      );
      controller.updateGeometry(_region(<int>{2, 3, 6}));
      controller.rollbackDrawingGesture();

      expect(controller.state.phase, BorderPreviewPhase.resolved);
      expect(controller.state.transaction, same(firstResolved));
      expect(
        controller.state.transaction!.proposedFeature.geometry,
        _region(<int>{0, 1, 4}),
      );
    });

    test('invalid second resolution restores the last resolved preview', () {
      final map = _map();
      var resolutionCount = 0;
      final controller = BorderPreviewController(
        resolver: (request) {
          resolutionCount += 1;
          if (resolutionCount == 1) return _success(request);
          return BorderResolutionResult(
            materialization: null,
            diagnosticReport: BorderDiagnosticsReport(
              diagnostics: <BorderDiagnostic>[
                BorderDiagnostic(
                  code: 'border.test.invalid_second_gesture',
                  severity: BorderDiagnosticSeverity.error,
                  phase: BorderDiagnosticPhase.resolution,
                  scope: BorderDiagnosticScope.feature,
                  featureId: 'coast',
                  suggestedAction: 'border.action.edit_geometry',
                ),
              ],
            ),
          );
        },
      );
      controller.begin(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
        context: _contextFor(map),
      );
      controller.previewGeometry(
        _region(<int>{0, 1, 4}),
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );
      controller.finishDrawing();
      final firstResolved = controller.state.transaction!;

      expect(
        controller.resumeDrawing(layerId: 'borders', featureId: 'coast'),
        isTrue,
      );
      controller.previewGeometry(
        _region(<int>{0, 1, 2, 4}),
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );
      expect(controller.state.transaction!.result!.canApply, isFalse);

      controller.finishDrawing();

      expect(controller.state.phase, BorderPreviewPhase.resolved);
      expect(controller.state.transaction, same(firstResolved));
      expect(controller.state.transaction!.result!.canApply, isTrue);
      expect(
        controller.state.transaction!.proposedFeature.geometry,
        _region(<int>{0, 1, 4}),
      );
    });

    test('resolved feature refinement preserves the drawing transaction', () {
      final map = _map();
      final controller = BorderPreviewController(resolver: _success);
      controller.begin(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
        context: _contextFor(map),
      );
      controller.previewGeometry(
        _region(<int>{0, 1, 4}),
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );
      controller.finishDrawing();
      final drawn = controller.state.transaction!;
      final proposed = drawn.proposedFeature;
      final inverted = BorderFeature(
        id: proposed.id,
        name: proposed.name,
        blueprintId: proposed.blueprintId,
        seed: proposed.seed,
        geometry: proposed.geometry,
        lineSide: BorderLineSide.inverted,
        paramsOverride: proposed.paramsOverride,
        overrides: proposed.overrides,
        keepOutRegions: proposed.keepOutRegions,
        materialization: proposed.materialization,
      );

      controller.previewResolvedFeatureDraft(
        inverted,
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );

      final refined = controller.state.transaction!;
      expect(controller.state.phase, BorderPreviewPhase.resolved);
      expect(refined.baseFeatureFingerprint, drawn.baseFeatureFingerprint);
      expect(refined.variationOrdinal, drawn.variationOrdinal);
      expect(refined.proposedFeature.geometry, proposed.geometry);
      expect(refined.proposedFeature.lineSide, BorderLineSide.inverted);
      expect(refined.proposedFeature.materialization, isNull);
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
        context: _contextFor(map),
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

      final outcome = controller.apply(map, context: _contextFor(map));

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
      invalid.begin(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
        context: _contextFor(map),
      );
      invalid.resolve(
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );

      expect(invalid.state.phase, BorderPreviewPhase.invalid);
      expect(invalid.apply(map, context: _contextFor(map)).applied, isFalse);
      expect(applyCalls, 0);

      final conflict = BorderPreviewController(
        resolver: _success,
        applier: ({required map, required transaction}) => map,
      );
      conflict.begin(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
        context: _contextFor(map),
      );
      conflict.resolve(
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );

      final outcome = conflict.apply(map, context: _contextFor(map));
      expect(outcome.applied, isFalse);
      expect(outcome.map, same(map));
      expect(conflict.state.phase, BorderPreviewPhase.resolved);
    });

    test('EditorNotifier records Apply as exactly one undo entry', () {
      final map = _map();
      final project = _project();
      final preview = BorderPreviewController(resolver: _success);
      final container = ProviderContainer(
        overrides: <Override>[
          borderPreviewControllerProvider.overrideWith((ref) => preview),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: '/projects/editor',
        project: project,
        activeMap: map,
        activeMapPath: '/projects/editor/maps/map.json',
        activeLayerId: 'borders',
        savedMapSnapshot: map,
        mapUndoStack: <MapHistorySnapshot>[
          MapHistorySnapshot(map: map.copyWith(name: 'État antérieur')),
        ],
        canUndoMap: true,
      );
      final mapWithExistingHistory = notifier.state.activeMap!;
      final unrelatedBefore = _unrelatedJson(mapWithExistingHistory);
      expect(notifier.state.mapUndoStack, hasLength(1));
      container
          .read(activeBorderFeatureControllerProvider.notifier)
          .selectFeature(
            map: mapWithExistingHistory,
            layerId: 'borders',
            featureId: 'coast',
          );
      preview.begin(
        map: mapWithExistingHistory,
        layerId: 'borders',
        featureId: 'coast',
        context: createEditorBorderPreviewContext(
          projectRootPath: '/projects/editor',
          activeMapPath: '/projects/editor/maps/map.json',
          project: project,
          map: mapWithExistingHistory,
        ),
      );
      preview.updateGeometry(_region(<int>{0, 1, 4}));
      preview.resolve(
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );

      expect(notifier.applyPendingBorderPreview(), isTrue);

      expect(notifier.state.mapUndoStack, hasLength(2));
      expect(notifier.state.mapRedoStack, isEmpty);
      expect(
        _feature(notifier.state.activeMap!, 'coast').geometry,
        _region(<int>{0, 1, 4}),
      );
      expect(_unrelatedJson(notifier.state.activeMap!), unrelatedBefore);
      expect(preview.state, const BorderPreviewState.idle());

      notifier.undoMap();
      expect(
          notifier.state.activeMap!.toJson(), mapWithExistingHistory.toJson());
    });

    test('EditorNotifier Update and Keep do not write map history', () {
      final map = _map();
      final before = map.toJson();
      final project = _project();
      final preview = BorderPreviewController(resolver: _success);
      final container = ProviderContainer(
        overrides: <Override>[
          borderPreviewControllerProvider.overrideWith((ref) => preview),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: '/projects/editor',
        project: project,
        activeMap: map,
        activeMapPath: '/projects/editor/maps/map.json',
        activeLayerId: 'borders',
        savedMapSnapshot: map,
      );

      expect(
        notifier.previewBorderFeatureUpdate(
          layerId: 'borders',
          featureId: 'coast',
        ),
        isTrue,
      );
      expect(preview.state.phase, BorderPreviewPhase.invalid,
          reason: 'the fixture intentionally has no published blueprint');
      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.activeMap!.toJson(), before);
      expect(notifier.state.mapUndoStack, isEmpty);

      notifier.keepBorderFeatureMaterialized();

      expect(preview.state, const BorderPreviewState.idle());
      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.activeMap!.toJson(), before);
      expect(notifier.state.mapUndoStack, isEmpty);
    });

    test(
        'EditorNotifier cancels a preview when a cloned project and map replace its owner',
        () {
      final map = _map();
      final project = _project();
      final preview = BorderPreviewController(resolver: _success);
      final container = ProviderContainer(
        overrides: <Override>[
          borderPreviewControllerProvider.overrideWith((ref) => preview),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: '/projects/editor',
        project: project,
        activeMap: map,
        activeMapPath: '/projects/editor/maps/map.json',
        activeLayerId: 'borders',
      );
      _resolvePreview(
        preview,
        map: map,
        context: createEditorBorderPreviewContext(
          projectRootPath: '/projects/editor',
          activeMapPath: '/projects/editor/maps/map.json',
          project: project,
          map: map,
        ),
      );
      final clonedMap = MapData.fromJson(map.toJson());
      final clonedProject = ProjectManifest.fromJson(project.toJson());

      notifier.state = notifier.state.copyWith(
        project: clonedProject,
        activeMap: clonedMap,
      );

      expect(preview.state, const BorderPreviewState.idle());
    });

    test(
        'EditorNotifier rejects active layer drift without consuming the preview',
        () {
      final map = _map();
      final project = _project();
      final preview = BorderPreviewController(resolver: _success);
      final container = ProviderContainer(
        overrides: <Override>[
          borderPreviewControllerProvider.overrideWith((ref) => preview),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: '/projects/editor',
        project: project,
        activeMap: map,
        activeMapPath: '/projects/editor/maps/map.json',
        activeLayerId: 'borders',
        savedMapSnapshot: map,
      );
      container
          .read(activeBorderFeatureControllerProvider.notifier)
          .selectFeature(
            map: map,
            layerId: 'borders',
            featureId: 'coast',
          );
      _resolvePreview(
        preview,
        map: map,
        context: createEditorBorderPreviewContext(
          projectRootPath: '/projects/editor',
          activeMapPath: '/projects/editor/maps/map.json',
          project: project,
          map: map,
        ),
      );
      notifier.state = notifier.state.copyWith(activeLayerId: 'collision-a');

      expect(notifier.applyPendingBorderPreview(), isFalse);
      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(preview.state.phase, BorderPreviewPhase.resolved);
      expect(preview.state.transaction, isNotNull);
    });

    test(
        'EditorNotifier rejects active feature drift without consuming the preview',
        () {
      final map = _map();
      final project = _project();
      final preview = BorderPreviewController(resolver: _success);
      final container = ProviderContainer(
        overrides: <Override>[
          borderPreviewControllerProvider.overrideWith((ref) => preview),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: '/projects/editor',
        project: project,
        activeMap: map,
        activeMapPath: '/projects/editor/maps/map.json',
        activeLayerId: 'borders',
        savedMapSnapshot: map,
      );
      _resolvePreview(
        preview,
        map: map,
        context: createEditorBorderPreviewContext(
          projectRootPath: '/projects/editor',
          activeMapPath: '/projects/editor/maps/map.json',
          project: project,
          map: map,
        ),
      );
      container
          .read(activeBorderFeatureControllerProvider.notifier)
          .selectFeature(
            map: map,
            layerId: 'borders',
            featureId: 'rocks',
          );

      expect(notifier.applyPendingBorderPreview(), isFalse);
      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(preview.state.phase, BorderPreviewPhase.resolved);
      expect(preview.state.transaction, isNotNull);
    });

    test(
        'EditorNotifier contains an Apply exception without mutating map or history',
        () {
      final map = _map();
      final project = _project();
      final before = map.toJson();
      final history = <MapHistorySnapshot>[
        MapHistorySnapshot(map: map.copyWith(name: 'État antérieur')),
      ];
      final preview = BorderPreviewController(
        resolver: _success,
        applier: ({required map, required transaction}) =>
            throw StateError('disk-independent apply failure'),
      );
      final container = ProviderContainer(
        overrides: <Override>[
          borderPreviewControllerProvider.overrideWith((ref) => preview),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: '/projects/editor',
        project: project,
        activeMap: map,
        activeMapPath: '/projects/editor/maps/map.json',
        activeLayerId: 'borders',
        savedMapSnapshot: map,
        mapUndoStack: history,
        canUndoMap: true,
      );
      container
          .read(activeBorderFeatureControllerProvider.notifier)
          .selectFeature(
            map: map,
            layerId: 'borders',
            featureId: 'coast',
          );
      _resolvePreview(
        preview,
        map: map,
        context: createEditorBorderPreviewContext(
          projectRootPath: '/projects/editor',
          activeMapPath: '/projects/editor/maps/map.json',
          project: project,
          map: map,
        ),
      );

      expect(notifier.applyPendingBorderPreview(), isFalse);
      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.activeMap!.toJson(), before);
      expect(notifier.state.mapUndoStack, history);
      expect(notifier.state.mapRedoStack, isEmpty);
      expect(notifier.state.errorMessage, contains('Impossible'));
      expect(preview.state.phase, BorderPreviewPhase.resolved);
      expect(preview.state.transaction, isNotNull);
    });

    test(
        'drag, variation and Cancel keep the rich persisted map byte-for-byte unchanged',
        () {
      final map = _map();
      final before = map.toJson();
      final controller = BorderPreviewController(resolver: _success);

      controller.begin(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
        context: _contextFor(map),
      );
      expect(controller.state.phase, BorderPreviewPhase.drawing);
      final dragSeed = controller.state.transaction!.proposedFeature.seed;
      controller
        ..updateGeometry(_region(<int>{0, 1}))
        ..updateGeometry(_region(<int>{0, 1, 4}));
      expect(controller.state.phase, BorderPreviewPhase.drawing);
      expect(controller.state.transaction!.proposedFeature.seed, dragSeed);
      expect(map.toJson(), before);

      controller.resolve(
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );
      expect(controller.state.phase, BorderPreviewPhase.resolved);
      final beforeVariation = controller.state.transaction!.proposedFeature;
      controller.newVariation();
      final afterVariation = controller.state.transaction!.proposedFeature;
      expect(controller.state.phase, BorderPreviewPhase.resolved);
      expect(afterVariation.seed, isNot(beforeVariation.seed));
      expect(afterVariation.geometry, beforeVariation.geometry);
      expect(afterVariation.paramsOverride, beforeVariation.paramsOverride);
      expect(afterVariation.overrides, beforeVariation.overrides);
      expect(afterVariation.keepOutRegions, beforeVariation.keepOutRegions);
      expect(map.toJson(), before);

      controller.cancel();
      expect(controller.state, const BorderPreviewState.idle());
      expect(map.toJson(), before);
    });

    test(
        'invalid resolution, resolver throw and applier throw preserve the old materialization and unrelated JSON',
        () {
      final map = _map();
      final before = map.toJson();
      final oldMaterialization = _feature(map, 'coast').materialization;
      final unrelatedBefore = _unrelatedJson(map);

      final invalid = BorderPreviewController(
        resolver: (_) => BorderResolutionResult(
          materialization: null,
          diagnosticReport: BorderDiagnosticsReport(
            diagnostics: <BorderDiagnostic>[_resolutionError()],
          ),
        ),
      );
      invalid.begin(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
        context: _contextFor(map),
      );
      invalid.updateGeometry(_region(<int>{0, 1, 4}));
      invalid.resolve(
        blueprintRevision: _revision(),
        tileSizePx: const GridSize(width: 16, height: 16),
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
        resolverVersion: 1,
      );
      expect(invalid.state.phase, BorderPreviewPhase.invalid);
      expect(invalid.apply(map, context: _contextFor(map)).applied, isFalse);
      _expectMapUnchanged(
        map,
        before: before,
        oldMaterialization: oldMaterialization,
        unrelatedBefore: unrelatedBefore,
      );

      final throwingResolver = BorderPreviewController(
        resolver: (_) => throw StateError('solve failed'),
      );
      throwingResolver.begin(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
        context: _contextFor(map),
      );
      expect(
        () => throwingResolver.resolve(
          blueprintRevision: _revision(),
          tileSizePx: const GridSize(width: 16, height: 16),
          visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
          resolverVersion: 1,
        ),
        throwsStateError,
      );
      expect(throwingResolver.state.phase, BorderPreviewPhase.drawing);
      _expectMapUnchanged(
        map,
        before: before,
        oldMaterialization: oldMaterialization,
        unrelatedBefore: unrelatedBefore,
      );

      final throwingApplier = BorderPreviewController(
        resolver: _success,
        applier: ({required map, required transaction}) =>
            throw StateError('apply failed'),
      );
      _resolvePreview(throwingApplier, map: map);
      expect(
        () => throwingApplier.apply(map, context: _contextFor(map)),
        throwsStateError,
      );
      expect(throwingApplier.state.phase, BorderPreviewPhase.resolved);
      expect(throwingApplier.state.transaction, isNotNull);
      _expectMapUnchanged(
        map,
        before: before,
        oldMaterialization: oldMaterialization,
        unrelatedBefore: unrelatedBefore,
      );
    });

    test(
        'whole-feature optimistic fingerprint rejects a materialization-only stale target',
        () {
      final map = _map();
      final controller = BorderPreviewController(resolver: _success);
      _resolvePreview(controller, map: map);
      expect(
        controller.state.transaction!.baseFeatureFingerprint,
        computeBorderFeatureEditFingerprint(_feature(map, 'coast')),
      );
      final staleMap = _replaceFeature(
        map,
        _copyFeature(
          _feature(map, 'coast'),
          materialization: null,
          replaceMaterialization: true,
        ),
      );
      final staleBefore = staleMap.toJson();
      final unrelatedBefore = _unrelatedJson(staleMap);
      expect(
        computeBorderFeatureEditFingerprint(_feature(staleMap, 'coast')),
        isNot(controller.state.transaction!.baseFeatureFingerprint),
      );

      final outcome = controller.apply(
        staleMap,
        context: _contextFor(staleMap),
      );

      expect(outcome.applied, isFalse);
      expect(outcome.map, same(staleMap));
      expect(staleMap.toJson(), staleBefore);
      expect(_unrelatedJson(staleMap), unrelatedBefore);
      expect(_feature(staleMap, 'coast').materialization, isNull);
      expect(controller.state.phase, BorderPreviewPhase.resolved);
      expect(controller.state.transaction, isNotNull);
    });

    test(
        'successful real Apply exposes applying phase and changes only the target feature',
        () {
      final map = _map();
      final before = map.toJson();
      final unrelatedBefore = _unrelatedJson(map);
      final oldMaterialization = _feature(map, 'coast').materialization;
      late final BorderPreviewController controller;
      controller = BorderPreviewController(
        resolver: _success,
        applier: ({required map, required transaction}) {
          expect(controller.state.phase, BorderPreviewPhase.applying);
          return applyBorderMaterialization(
            map: map,
            transaction: transaction,
          );
        },
      );
      _resolvePreview(controller, map: map);

      final outcome = controller.apply(map, context: _contextFor(map));

      expect(outcome.applied, isTrue);
      expect(outcome.map, isNot(same(map)));
      expect(controller.state, const BorderPreviewState.idle());
      expect(_feature(outcome.map, 'coast').geometry, _region(<int>{0, 1, 4}));
      expect(
        _feature(outcome.map, 'coast').materialization,
        isNot(oldMaterialization),
      );
      expect(_unrelatedJson(outcome.map), unrelatedBefore);
      expect(map.toJson(), before);
      expect(_feature(map, 'coast').materialization, same(oldMaterialization));
    });

    test('Border serialization contract contains no collision field', () {
      final borderLayer = _map().layers.whereType<BorderLayer>().single;
      final encoded = borderLayer.toJson().toString().toLowerCase();

      expect(encoded, isNot(contains('collision')));
    });
  });
}

void _resolvePreview(
  BorderPreviewController preview, {
  required MapData map,
  BorderPreviewContext? context,
}) {
  preview.begin(
    map: map,
    layerId: 'borders',
    featureId: 'coast',
    context: context ?? _contextFor(map),
  );
  preview.updateGeometry(_region(<int>{0, 1, 4}));
  preview.resolve(
    blueprintRevision: _revision(),
    tileSizePx: const GridSize(width: 16, height: 16),
    visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
    resolverVersion: 1,
  );
  expect(preview.state.phase, BorderPreviewPhase.resolved);
}

BorderResolutionResult _success(BorderResolutionRequest request) =>
    resolveBorderFeature(request);

final Object _previewProjectIdentity = Object();

BorderPreviewContext _contextFor(MapData map) => BorderPreviewContext(
      projectRootPath: '/projects/test',
      activeMapPath: '/projects/test/maps/${map.id}.json',
      projectIdentity: _previewProjectIdentity,
      mapIdentity: map,
      borderCatalogFingerprint: 'catalog-test',
    );

ProjectManifest _project() => const ProjectManifest(
      name: 'Preview project',
      version: ProjectVersion.v6,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
    );

MapData _map() {
  final unmaterializedCoast = BorderFeature(
    id: 'coast',
    name: 'Côte',
    blueprintId: 'coast-blueprint',
    seed: BorderSignedInt64.fromInt(7),
    geometry: _region(<int>{0}),
    overrides: const <BorderSlotOverride>[],
    keepOutRegions: const <BorderKeepOutRegion>[],
  );
  final oldRequest = BorderResolutionRequest(
    mapSize: const GridSize(width: 4, height: 3),
    tileSizePx: const GridSize(width: 16, height: 16),
    blueprintId: 'coast-blueprint',
    blueprintRevision: _revision(),
    feature: unmaterializedCoast,
    visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
    resolverVersion: 1,
  );
  final oldMaterialization = resolveBorderFeature(oldRequest).materialization!;
  final coast = _copyFeature(
    unmaterializedCoast,
    materialization: oldMaterialization,
  );
  return MapData(
    id: 'map',
    name: 'Map riche',
    version: ProjectVersion.v6,
    size: const GridSize(width: 4, height: 3),
    layers: <MapLayer>[
      const MapLayer.tile(
        id: 'tile',
        name: 'Sol',
        opacity: 0.8,
        cells: <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      ),
      MapLayer.border(
        id: 'borders',
        name: 'Bordures',
        opacity: 0.9,
        properties: const <String, String>{'purpose': 'coast'},
        content: BorderLayerContent(
          features: <BorderFeature>[
            coast,
            BorderFeature(
              id: 'rocks',
              name: 'Rochers',
              blueprintId: 'coast-blueprint',
              seed: BorderSignedInt64.fromInt(17),
              geometry: _region(<int>{3}),
              overrides: const <BorderSlotOverride>[],
              keepOutRegions: const <BorderKeepOutRegion>[],
            ),
          ],
        ),
      ),
      const MapLayer.smartTile(
        id: 'surface',
        name: 'Surface décorative',
        presetId: 'sand',
        usage: SmartTileUsage.forestSurface,
        materialPalette: <String>['', 'sand'],
        field: SmartTileField.cell(
          semanticCells: <int>[0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0],
        ),
        properties: <String, String>{'source': 'manual'},
      ),
      const MapLayer.collision(
        id: 'collision-a',
        name: 'Collision A',
        collisions: <bool>[
          true,
          false,
          false,
          false,
          false,
          true,
          false,
          false,
          false,
          false,
          false,
          true,
        ],
      ),
      const MapLayer.collision(
        id: 'collision-b',
        name: 'Collision B',
        opacity: 0.5,
        collisions: <bool>[
          false,
          true,
          false,
          false,
          true,
          false,
          false,
          true,
          false,
          false,
          true,
          false,
        ],
      ),
      const MapLayer.object(id: 'objects', name: 'Objets'),
    ],
    placedElements: const <MapPlacedElement>[
      MapPlacedElement(
        id: 'manual-lamp',
        layerId: 'objects',
        elementId: 'lamp',
        pos: GridPos(x: 2, y: 2),
        applyCollision: true,
        opacity: 0.75,
        properties: <String, String>{'placement': 'manual'},
      ),
    ],
    properties: const <String, dynamic>{
      'weather': 'sea-breeze',
      'authoring': true,
    },
  );
}

BorderFeature _feature(MapData map, String featureId) => map.layers
    .whereType<BorderLayer>()
    .single
    .content
    .features
    .singleWhere((feature) => feature.id == featureId);

BorderFeature _copyFeature(
  BorderFeature feature, {
  BorderFeatureGeometry? geometry,
  BorderSignedInt64? seed,
  BorderMaterialization? materialization,
  bool replaceMaterialization = false,
}) =>
    BorderFeature(
      id: feature.id,
      name: feature.name,
      blueprintId: feature.blueprintId,
      seed: seed ?? feature.seed,
      geometry: geometry ?? feature.geometry,
      paramsOverride: feature.paramsOverride,
      overrides: feature.overrides,
      keepOutRegions: feature.keepOutRegions,
      materialization: replaceMaterialization
          ? materialization
          : materialization ?? feature.materialization,
    );

MapData _replaceFeature(MapData map, BorderFeature replacement) {
  final layers = <MapLayer>[
    for (final layer in map.layers)
      if (layer is BorderLayer)
        layer.copyWith(
          content: BorderLayerContent(
            formatVersion: layer.content.formatVersion,
            features: <BorderFeature>[
              for (final feature in layer.content.features)
                if (feature.id == replacement.id) replacement else feature,
            ],
          ),
        )
      else
        layer,
  ];
  return map.copyWith(layers: layers);
}

Map<String, Object?> _unrelatedJson(MapData map) {
  final borderLayer = map.layers.whereType<BorderLayer>().single;
  return <String, Object?>{
    'mapMetadata': <String, Object?>{
      'id': map.id,
      'name': map.name,
      'version': map.version.name,
      'size': <int>[map.size.width, map.size.height],
      'properties': map.properties,
    },
    'otherLayers': <Map<String, dynamic>>[
      for (final layer in map.layers)
        if (layer.id != borderLayer.id) layer.toJson(),
    ],
    'borderLayerMetadata': <String, Object?>{
      'id': borderLayer.id,
      'name': borderLayer.name,
      'isVisible': borderLayer.isVisible,
      'opacity': borderLayer.opacity,
      'properties': borderLayer.properties,
      'formatVersion': borderLayer.content.formatVersion,
    },
    'otherBorderFeatures': <Map<String, Object?>>[
      for (final feature in borderLayer.content.features)
        if (feature.id != 'coast') encodeBorderFeatureJson(feature),
    ],
    'placedElements': map.toJson()['placedElements'],
    'entities': map.toJson()['entities'],
    'connections': map.toJson()['connections'],
    'warps': map.toJson()['warps'],
    'triggers': map.toJson()['triggers'],
    'gameplayZones': map.toJson()['gameplayZones'],
    'events': map.toJson()['events'],
  };
}

void _expectMapUnchanged(
  MapData map, {
  required Map<String, dynamic> before,
  required BorderMaterialization? oldMaterialization,
  required Map<String, Object?> unrelatedBefore,
}) {
  expect(map.toJson(), before);
  expect(_feature(map, 'coast').materialization, same(oldMaterialization));
  expect(_unrelatedJson(map), unrelatedBefore);
}

BorderDiagnostic _resolutionError() => BorderDiagnostic(
      code: 'border.test.invalid',
      severity: BorderDiagnosticSeverity.error,
      phase: BorderDiagnosticPhase.resolution,
      scope: BorderDiagnosticScope.feature,
      featureId: 'coast',
      suggestedAction: 'border.action.edit_geometry',
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
        primitives: <BorderPublishedPrimitive>[_primitive()],
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

BorderPublishedPrimitive _primitive() => BorderPublishedPrimitive(
      id: 'rock',
      sourceElementId: 'rock-source',
      visualSnapshotId: _snapshotId,
      role: BorderPrimitiveRole.structureLarge,
      weight: 1,
      anchorPx: const BorderPixelPos(x: 8, y: 8),
      transforms: BorderTransformPolicy(
        allowFlipX: true,
        allowedQuarterTurns: const <int>[0, 1, 2, 3],
      ),
      publishedMetrics: BorderPrimitiveAssetMetrics(
        assetFingerprint: 'asset-rock',
        pixelSize: const GridSize(width: 16, height: 16),
        opaqueBounds: BorderPixelRect(
          x: 0,
          y: 0,
          width: 16,
          height: 16,
        ),
        defaultAnchorPx: const BorderPixelPos(x: 8, y: 8),
        occupancyMaskRle: encodeBorderRleMask(
          List<bool>.filled(16 * 16, true),
        ),
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
