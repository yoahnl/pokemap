import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_feature_authoring_controller.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_controller.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_transaction.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_map_editing_providers.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_preview_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  test('notifier supports Border feature CRUD and reconciles selection', () {
    const collision = MapLayer.collision(
      id: 'collision',
      name: 'Collision',
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      project: _project(<BorderBlueprintRecord>[
        _record('coast-a'),
        _record('coast-b'),
      ]),
      activeMap: const MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v2,
        size: GridSize(width: 4, height: 3),
        layers: <MapLayer>[
          collision,
          MapLayer.border(id: 'borders', name: 'Bordures'),
        ],
      ),
      activeLayerId: 'borders',
    );
    container.read(activeBorderFeatureControllerProvider);
    final collisionJson = collision.toJson();

    notifier.createBorderFeature(
      layerId: 'borders',
      blueprintId: 'coast-a',
      name: 'Basse',
    );
    notifier.createBorderFeature(
      layerId: 'borders',
      blueprintId: 'coast-a',
      name: 'Haute',
    );

    expect(
      container.read(activeBorderFeatureControllerProvider).activeFeatureId,
      'border_feature_2',
      reason: 'the last authored feature is uppermost',
    );
    notifier.selectBorderFeature(
      layerId: 'borders',
      featureId: 'border_feature',
    );
    notifier.renameBorderFeature(
      layerId: 'borders',
      featureId: 'border_feature',
      name: 'Rivage renommé',
    );
    notifier.reorderBorderFeature(
      layerId: 'borders',
      featureId: 'border_feature',
      newIndex: 1,
    );

    final mapBeforePreview = updateBorderFeatureGeometry(
      notifier.state.activeMap!,
      layerId: 'borders',
      featureId: 'border_feature',
      geometry: BorderRegionGeometry(
        width: 4,
        height: 3,
        cells: const <bool>[
          true,
          true,
          false,
          false,
          true,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
        ],
      ),
    );
    notifier.state = notifier.state.copyWith(activeMap: mapBeforePreview);
    final preview =
        const BorderFeatureAuthoringController().previewBlueprintChange(
      map: mapBeforePreview,
      layerId: 'borders',
      featureId: 'border_feature',
      sourceBlueprint: _record('coast-a'),
      targetBlueprint: _record('coast-b'),
      visualSnapshots: notifier.state.project!.borderCatalog.visualSnapshots,
      tileSizePx: const GridSize(width: 16, height: 16),
    );
    expect(notifier.state.activeMap, same(mapBeforePreview));
    final historyBeforeRelink = notifier.state.mapUndoStack.length;
    notifier.changeBorderFeatureBlueprint(preview);
    expect(notifier.state.mapUndoStack, hasLength(historyBeforeRelink + 1));
    notifier.deleteBorderFeature(
      layerId: 'borders',
      featureId: 'border_feature_2',
    );

    final border =
        notifier.state.activeMap!.layers.whereType<BorderLayer>().single;
    expect(border.content.features.single.id, 'border_feature');
    expect(border.content.features.single.name, 'Rivage renommé');
    expect(border.content.features.single.blueprintId, 'coast-b');
    expect(
      container.read(activeBorderFeatureControllerProvider).activeFeatureId,
      'border_feature',
    );
    expect(
      notifier.state.activeMap!.layers
          .whereType<CollisionLayer>()
          .single
          .toJson(),
      collisionJson,
    );
  });

  test('notifier refuses draft and deprecated blueprints for creation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      project: _project(<BorderBlueprintRecord>[
        _record('draft', published: false),
        _record('old', isDeprecated: true),
      ]),
      activeMap: const MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v2,
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[
          MapLayer.border(id: 'borders', name: 'Bordures'),
        ],
      ),
      activeLayerId: 'borders',
    );
    final before = notifier.state.activeMap!.toJson();

    notifier.createBorderFeature(
      layerId: 'borders',
      blueprintId: 'draft',
      name: 'Draft',
    );
    expect(notifier.state.activeMap!.toJson(), before);
    expect(notifier.state.errorMessage, isNotNull);

    notifier.createBorderFeature(
      layerId: 'borders',
      blueprintId: 'old',
      name: 'Old',
    );
    expect(notifier.state.activeMap!.toJson(), before);
    expect(notifier.state.errorMessage, isNotNull);
  });

  test('notifier executes separate creation or confirmed reset proposals', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final coast = _record('coast');
    final wall = _record(
      'wall',
      template: BorderBlueprintTemplate.masonryLine,
    );
    notifier.state = EditorState(
      project: _project(<BorderBlueprintRecord>[coast, wall]),
      activeMap: const MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v2,
        size: GridSize(width: 3, height: 3),
        layers: <MapLayer>[
          MapLayer.border(id: 'borders', name: 'Bordures'),
        ],
      ),
      activeLayerId: 'borders',
    );
    container.read(activeBorderFeatureControllerProvider);
    notifier.createBorderFeature(
      layerId: 'borders',
      blueprintId: 'coast',
      name: 'Côte',
    );
    final sourceMap = notifier.state.activeMap!;
    final preview =
        const BorderFeatureAuthoringController().previewBlueprintChange(
      map: sourceMap,
      layerId: 'borders',
      featureId: 'border_feature',
      sourceBlueprint: coast,
      targetBlueprint: wall,
      visualSnapshots: const <BorderVisualSnapshot>[],
      tileSizePx: const GridSize(width: 16, height: 16),
    );

    notifier.createBorderFeatureFromBlueprintChange(
      preview: preview,
      name: 'Muret séparé',
    );
    var features = notifier.state.activeMap!.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features;
    expect(features, hasLength(2));
    expect(features.first.blueprintId, 'coast');
    expect(features.last.blueprintId, 'wall');
    expect(
      container.read(activeBorderFeatureControllerProvider).activeFeatureId,
      features.last.id,
    );

    final resetPreview =
        const BorderFeatureAuthoringController().previewBlueprintChange(
      map: notifier.state.activeMap!,
      layerId: 'borders',
      featureId: 'border_feature',
      sourceBlueprint: coast,
      targetBlueprint: wall,
      visualSnapshots: const <BorderVisualSnapshot>[],
      tileSizePx: const GridSize(width: 16, height: 16),
    );
    notifier.resetBorderFeatureBlueprint(resetPreview);
    features = notifier.state.activeMap!.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features;
    expect(features.first.blueprintId, 'wall');
    expect(features.first.geometry, isA<BorderStrokeGeometry>());
    expect(features.last.name, 'Muret séparé');
  });

  test('notifier rejects a relink preview after target publication drift', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final coast = _record('coast');
    final wall = _record(
      'wall',
      template: BorderBlueprintTemplate.masonryLine,
    );
    notifier.state = EditorState(
      project: _project(<BorderBlueprintRecord>[coast, wall]),
      activeMap: const MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v2,
        size: GridSize(width: 3, height: 3),
        layers: <MapLayer>[
          MapLayer.border(id: 'borders', name: 'Bordures'),
        ],
      ),
      activeLayerId: 'borders',
    );
    notifier.createBorderFeature(
      layerId: 'borders',
      blueprintId: coast.id,
      name: 'Côte',
    );
    final map = notifier.state.activeMap!;
    final history = notifier.state.mapUndoStack;
    final preview =
        const BorderFeatureAuthoringController().previewBlueprintChange(
      map: map,
      layerId: 'borders',
      featureId: 'border_feature',
      sourceBlueprint: coast,
      targetBlueprint: wall,
      visualSnapshots: const <BorderVisualSnapshot>[],
      tileSizePx: const GridSize(width: 16, height: 16),
    );
    final driftedWall = BorderBlueprintRecord(
      id: wall.id,
      draft: BorderBlueprintDraft(
        baseRevision: 2,
        definition: wall.draft.definition,
      ),
      latestPublished: BorderBlueprintRevision(
        revision: 2,
        definition: wall.latestPublished!.definition,
      ),
    );
    notifier.state = notifier.state.copyWith(
      project: _project(<BorderBlueprintRecord>[coast, driftedWall]),
    );

    notifier.resetBorderFeatureBlueprint(preview);

    expect(notifier.state.activeMap, same(map));
    expect(notifier.state.mapUndoStack, history);
    expect(notifier.state.errorMessage, contains('révision publiée a changé'));
  });

  test('notifier resolves a local correction draft without map history writes',
      () {
    final feature = BorderFeature(
      id: 'feature',
      name: 'Côte',
      blueprintId: 'coast',
      seed: BorderSignedInt64.fromInt(7),
      geometry: BorderRegionGeometry(
        width: 3,
        height: 3,
        cells: List<bool>.filled(9, false),
      ),
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
      materialization: _materialization(),
    );
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v2,
      size: const GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.border(
          id: 'borders',
          name: 'Bordures',
          content: BorderLayerContent(features: <BorderFeature>[feature]),
        ),
      ],
    );
    final preview = BorderPreviewController(
      resolver: (_) => BorderResolutionResult(
        materialization: _materialization(),
        diagnosticReport: const BorderDiagnosticsReport.empty(),
      ),
    );
    final container = ProviderContainer(
      overrides: <Override>[
        borderPreviewControllerProvider.overrideWith((ref) => preview),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      projectRootPath: '/projects/border',
      project: _project(<BorderBlueprintRecord>[_record('coast')]),
      activeMap: map,
      activeMapPath: '/projects/border/maps/map.json',
      activeLayerId: 'borders',
    );
    final draft = const BorderFeatureAuthoringController()
        .previewLocalVariation(feature: feature, slotKey: 'slot-a');
    final before = map.toJson();

    final prepared = notifier.previewBorderFeatureDraft(
      layerId: 'borders',
      featureId: 'feature',
      draft: draft,
    );

    expect(prepared, isTrue);
    expect(preview.state.phase, BorderPreviewPhase.resolved);
    expect(
        preview.state.transaction!.proposedFeature.overrides, draft.overrides);
    expect(notifier.state.activeMap, same(map));
    expect(notifier.state.activeMap!.toJson(), before);
    expect(notifier.state.mapUndoStack, isEmpty);
  });

  test('line side inversion stays preview-only until one atomic Apply', () {
    final preview = BorderPreviewController(
      resolver: (_) => BorderResolutionResult(
        materialization: _materialization(),
        diagnosticReport: const BorderDiagnosticsReport.empty(),
      ),
      applier: _applyProposedFeature,
    );
    final container = ProviderContainer(
      overrides: <Override>[
        borderPreviewControllerProvider.overrideWith((ref) => preview),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      projectRootPath: '/projects/connected-line',
      project: _project(<BorderBlueprintRecord>[
        _record(
          'cliff',
          template: BorderBlueprintTemplate.connectedLine,
        ),
      ]),
      activeMap: const MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v2,
        size: GridSize(width: 4, height: 3),
        layers: <MapLayer>[
          MapLayer.border(id: 'borders', name: 'Bordures'),
        ],
      ),
      activeMapPath: '/projects/connected-line/maps/map.json',
      activeLayerId: 'borders',
    );
    container.read(activeBorderFeatureControllerProvider);
    notifier.createBorderFeature(
      layerId: 'borders',
      blueprintId: 'cliff',
      name: 'Falaise',
    );
    final authoredMap = updateBorderFeatureGeometry(
      notifier.state.activeMap!,
      layerId: 'borders',
      featureId: 'border_feature',
      geometry: BorderStrokeGeometry(
        strokes: <BorderStroke>[
          BorderStroke(
            id: 'stroke',
            points: const <GridPos>[
              GridPos(x: 0, y: 1),
              GridPos(x: 1, y: 1),
              GridPos(x: 2, y: 1),
            ],
            closed: false,
          ),
        ],
      ),
    );
    notifier.state = notifier.state.copyWith(activeMap: authoredMap);
    container
        .read(activeBorderFeatureControllerProvider.notifier)
        .selectFeature(
          map: authoredMap,
          layerId: 'borders',
          featureId: 'border_feature',
        );
    final beforeJson = authoredMap.toJson();
    final historyBefore = notifier.state.mapUndoStack.length;

    expect(
      notifier.previewBorderFeatureLineSideToggle(
        layerId: 'borders',
        featureId: 'border_feature',
      ),
      isTrue,
    );
    expect(preview.state.phase, BorderPreviewPhase.resolved);
    expect(
      preview.state.transaction!.proposedFeature.lineSide,
      BorderLineSide.inverted,
    );
    expect(notifier.state.activeMap, same(authoredMap));
    expect(notifier.state.activeMap!.toJson(), beforeJson);
    expect(notifier.state.mapUndoStack, hasLength(historyBefore));

    preview.cancel();
    expect(notifier.state.activeMap!.toJson(), beforeJson);
    expect(notifier.state.mapUndoStack, hasLength(historyBefore));

    expect(
      notifier.previewBorderFeatureLineSideToggle(
        layerId: 'borders',
        featureId: 'border_feature',
      ),
      isTrue,
    );
    expect(notifier.applyPendingBorderPreview(), isTrue);
    final applied = notifier.state.activeMap!.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single;
    expect(applied.lineSide, BorderLineSide.inverted);
    expect(notifier.state.mapUndoStack, hasLength(historyBefore + 1));
  });

  test('stone-chain side inversion preserves grid edges until one Apply', () {
    final preview = BorderPreviewController(
      resolver: (request) => BorderResolutionResult(
        materialization: _materialization(
          placementY:
              request.feature.lineSide == BorderLineSide.primary ? 4 : -4,
        ),
        diagnosticReport: const BorderDiagnosticsReport.empty(),
      ),
      applier: _applyProposedFeature,
    );
    final container = ProviderContainer(
      overrides: <Override>[
        borderPreviewControllerProvider.overrideWith((ref) => preview),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      projectRootPath: '/projects/stone-chain',
      project: _project(<BorderBlueprintRecord>[
        _record(
          'stone-chain',
          template: BorderBlueprintTemplate.stoneChainLine,
        ),
      ]),
      activeMap: MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v2,
        size: const GridSize(width: 4, height: 3),
        layers: <MapLayer>[
          MapLayer.border(
            id: 'borders',
            name: 'Bordures',
            content: BorderLayerContent(
              formatVersion: BorderLayerContent.formatVersionV3,
            ),
          ),
        ],
      ),
      activeMapPath: '/projects/stone-chain/maps/map.json',
      activeLayerId: 'borders',
    );
    container.read(activeBorderFeatureControllerProvider);
    notifier.createBorderFeature(
      layerId: 'borders',
      blueprintId: 'stone-chain',
      name: 'Falaise',
    );
    final authoredMap = updateBorderFeatureGeometry(
      notifier.state.activeMap!,
      layerId: 'borders',
      featureId: 'border_feature',
      geometry: BorderStrokeGeometry(
        alignment: BorderStrokeAlignment.gridEdges,
        strokes: <BorderStroke>[
          BorderStroke(
            id: 'coast-edge',
            points: const <GridPos>[
              GridPos(x: 0, y: 0),
              GridPos(x: 1, y: 0),
              GridPos(x: 2, y: 0),
            ],
            closed: false,
          ),
        ],
      ),
    );
    notifier.state = notifier.state.copyWith(activeMap: authoredMap);
    container
        .read(activeBorderFeatureControllerProvider.notifier)
        .selectFeature(
          map: authoredMap,
          layerId: 'borders',
          featureId: 'border_feature',
        );
    final beforeJson = authoredMap.toJson();
    final historyBefore = notifier.state.mapUndoStack.length;

    expect(
      notifier.previewBorderFeatureLineSideToggle(
        layerId: 'borders',
        featureId: 'border_feature',
      ),
      isTrue,
    );
    final proposed = preview.state.transaction!.proposedFeature;
    expect(proposed.lineSide, BorderLineSide.inverted);
    expect(
        proposed.geometry,
        authoredMap.layers
            .whereType<BorderLayer>()
            .single
            .content
            .features
            .single
            .geometry);
    final primaryPlacement = _materialization(placementY: 4).placements.single;
    final invertedPlacement =
        preview.state.transaction!.result!.materialization!.placements.single;
    expect(invertedPlacement.id, primaryPlacement.id);
    expect(invertedPlacement.slotKey, primaryPlacement.slotKey);
    expect(invertedPlacement.primitiveId, primaryPlacement.primitiveId);
    expect(
        invertedPlacement.topLeftWorldPx.y, -primaryPlacement.topLeftWorldPx.y);
    expect(invertedPlacement.transform.flipX, isFalse);
    expect(invertedPlacement.transform.quarterTurns, 0);
    expect(notifier.state.activeMap!.toJson(), beforeJson);
    expect(notifier.state.mapUndoStack, hasLength(historyBefore));

    expect(notifier.applyPendingBorderPreview(), isTrue);
    expect(notifier.state.mapUndoStack, hasLength(historyBefore + 1));

    final appliedMap = notifier.state.activeMap!;
    final applied = appliedMap.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single;
    final reloadedMap = MapData.fromJson(appliedMap.toJson());
    final reloaded = reloadedMap.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single;
    expect(reloaded.lineSide, BorderLineSide.inverted);
    expect(
      (reloaded.geometry as BorderStrokeGeometry).alignment,
      BorderStrokeAlignment.gridEdges,
    );
    expect(reloaded.geometry, applied.geometry);
    expect(reloaded.materialization, applied.materialization);
    expect(
      computeBorderFeatureEditFingerprint(reloaded),
      computeBorderFeatureEditFingerprint(applied),
    );
  });

  test('new stone-chain draw can invert side before its first atomic Apply',
      () {
    final preview = BorderPreviewController(
      resolver: (request) => BorderResolutionResult(
        materialization: _materialization(
          placementY:
              request.feature.lineSide == BorderLineSide.primary ? 4 : -4,
        ),
        diagnosticReport: const BorderDiagnosticsReport.empty(),
      ),
      applier: _applyProposedFeature,
    );
    final container = ProviderContainer(
      overrides: <Override>[
        borderPreviewControllerProvider.overrideWith((ref) => preview),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      projectRootPath: '/projects/stone-chain-new-draw',
      project: _project(<BorderBlueprintRecord>[
        _record(
          'stone-chain',
          template: BorderBlueprintTemplate.stoneChainLine,
        ),
      ]),
      activeMap: MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v2,
        size: const GridSize(width: 4, height: 3),
        layers: <MapLayer>[
          MapLayer.border(
            id: 'borders',
            name: 'Bordures',
            content: BorderLayerContent(
              formatVersion: BorderLayerContent.formatVersionV3,
            ),
          ),
        ],
      ),
      activeMapPath: '/projects/stone-chain-new-draw/maps/map.json',
      activeLayerId: 'borders',
    );
    container.read(activeBorderFeatureControllerProvider);
    notifier.createBorderFeature(
      layerId: 'borders',
      blueprintId: 'stone-chain',
      name: 'Nouvelle côte',
    );
    final mapBeforeApply = notifier.state.activeMap!;
    final persisted = mapBeforeApply.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single;
    container
        .read(activeBorderFeatureControllerProvider.notifier)
        .selectFeature(
          map: mapBeforeApply,
          layerId: 'borders',
          featureId: persisted.id,
        );
    final drawn = BorderFeature(
      id: persisted.id,
      name: persisted.name,
      blueprintId: persisted.blueprintId,
      seed: persisted.seed,
      geometry: BorderStrokeGeometry(
        alignment: BorderStrokeAlignment.gridEdges,
        strokes: <BorderStroke>[
          BorderStroke(
            id: 'coast-edge',
            points: const <GridPos>[
              GridPos(x: 0, y: 0),
              GridPos(x: 1, y: 0),
              GridPos(x: 2, y: 0),
            ],
            closed: false,
          ),
        ],
      ),
      lineSide: persisted.lineSide,
      paramsOverride: persisted.paramsOverride,
      overrides: persisted.overrides,
      keepOutRegions: persisted.keepOutRegions,
    );
    preview.begin(
      map: mapBeforeApply,
      layerId: 'borders',
      featureId: persisted.id,
      context: createEditorBorderPreviewContext(
        projectRootPath: notifier.state.projectRootPath!,
        activeMapPath: notifier.state.activeMapPath!,
        project: notifier.state.project!,
        map: mapBeforeApply,
      ),
    );
    preview.previewFeatureDraft(
      drawn,
      blueprintRevision: notifier.state.project!.borderCatalog
          .recordById('stone-chain')!
          .latestPublished,
      tileSizePx: GridSize(
        width: notifier.state.project!.settings.tileWidth,
        height: notifier.state.project!.settings.tileHeight,
      ),
      visualSnapshots: notifier.state.project!.borderCatalog.visualSnapshots,
      resolverVersion: borderResolverVersion,
    );
    final drawnTransaction = preview.state.transaction!;
    final beforeJson = mapBeforeApply.toJson();
    final historyBeforeApply = notifier.state.mapUndoStack.length;

    expect(
      notifier.previewBorderFeatureLineSideToggle(
        layerId: 'borders',
        featureId: persisted.id,
      ),
      isTrue,
    );

    final inverted = preview.state.transaction!;
    expect(inverted.baseFeatureFingerprint,
        drawnTransaction.baseFeatureFingerprint);
    expect(inverted.proposedFeature.geometry, drawn.geometry);
    expect(inverted.proposedFeature.lineSide, BorderLineSide.inverted);
    expect(notifier.state.activeMap!.toJson(), beforeJson);
    expect(notifier.state.mapUndoStack, hasLength(historyBeforeApply));

    expect(
      notifier.previewBorderFeatureLineSideToggle(
        layerId: 'borders',
        featureId: persisted.id,
      ),
      isTrue,
    );
    final primaryAgain = preview.state.transaction!;
    expect(primaryAgain.baseFeatureFingerprint,
        drawnTransaction.baseFeatureFingerprint);
    expect(primaryAgain.proposedFeature.geometry, drawn.geometry);
    expect(primaryAgain.proposedFeature.lineSide, BorderLineSide.primary);
    expect(
      primaryAgain.result!.materialization!.placements.single.topLeftWorldPx.y,
      4,
    );
    expect(notifier.state.activeMap!.toJson(), beforeJson);
    expect(notifier.state.mapUndoStack, hasLength(historyBeforeApply));

    expect(
      notifier.previewBorderFeatureLineSideToggle(
        layerId: 'borders',
        featureId: persisted.id,
      ),
      isTrue,
    );
    expect(
      preview.state.transaction!.proposedFeature.lineSide,
      BorderLineSide.inverted,
    );
    expect(
      preview.state.transaction!.result!.materialization!.placements.single
          .topLeftWorldPx.y,
      -4,
    );
    expect(notifier.state.activeMap!.toJson(), beforeJson);
    expect(notifier.state.mapUndoStack, hasLength(historyBeforeApply));

    expect(notifier.applyPendingBorderPreview(), isTrue);
    final applied = notifier.state.activeMap!.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single;
    expect(applied.geometry, drawn.geometry);
    expect(applied.lineSide, BorderLineSide.inverted);
    expect(notifier.state.mapUndoStack, hasLength(historyBeforeApply + 1));
  });

  test('stone-chain auto-rotation refinement stays preview-only', () {
    final preview = BorderPreviewController(
      resolver: (request) => BorderResolutionResult(
        materialization: _materialization(
          quarterTurns:
              request.feature.paramsOverride?.allowAutoRotation == true ? 1 : 0,
        ),
        diagnosticReport: const BorderDiagnosticsReport.empty(),
      ),
    );
    final container = ProviderContainer(
      overrides: <Override>[
        borderPreviewControllerProvider.overrideWith((ref) => preview),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final feature = BorderFeature(
      id: 'border-feature',
      name: 'Falaise',
      blueprintId: 'stone-chain',
      seed: BorderSignedInt64.zero,
      geometry: BorderStrokeGeometry(
        alignment: BorderStrokeAlignment.gridEdges,
        strokes: <BorderStroke>[
          BorderStroke(
            id: 'coast-edge',
            points: const <GridPos>[
              GridPos(x: 0, y: 0),
              GridPos(x: 1, y: 0),
              GridPos(x: 2, y: 0),
            ],
            closed: false,
          ),
        ],
      ),
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    );
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v2,
      size: const GridSize(width: 4, height: 3),
      layers: <MapLayer>[
        MapLayer.border(
          id: 'borders',
          name: 'Bordures',
          content: BorderLayerContent(
            formatVersion: BorderLayerContent.formatVersionV3,
            features: <BorderFeature>[feature],
          ),
        ),
      ],
    );
    final undo = MapHistorySnapshot(map: map.copyWith(name: 'Before'));
    final redo = MapHistorySnapshot(map: map.copyWith(name: 'After'));
    notifier.state = EditorState(
      projectRootPath: '/projects/stone-chain',
      project: _project(<BorderBlueprintRecord>[
        _record(
          'stone-chain',
          template: BorderBlueprintTemplate.stoneChainLine,
        ),
      ]),
      activeMap: map,
      activeMapPath: '/projects/stone-chain/maps/map.json',
      activeLayerId: 'borders',
      mapUndoStack: <MapHistorySnapshot>[undo],
      mapRedoStack: <MapHistorySnapshot>[redo],
      canUndoMap: true,
      canRedoMap: true,
    );
    final beforeJson = map.toJson();
    final historyBefore = notifier.state.mapUndoStack;
    expect(
      notifier.previewBorderFeatureUpdate(
        layerId: 'borders',
        featureId: feature.id,
      ),
      isTrue,
    );
    final initial = preview.state.transaction!;
    final initialSlots = initial.result!.materialization!.placements
        .map((placement) => placement.slotKey)
        .toSet();

    expect(
      notifier.previewBorderFeatureAutoRotation(
        layerId: 'borders',
        featureId: feature.id,
        enabled: true,
      ),
      isTrue,
    );
    final rotationOn = preview.state.transaction!;
    expect(rotationOn.baseFeatureFingerprint, initial.baseFeatureFingerprint);
    expect(rotationOn.proposedFeature.geometry, feature.geometry);
    expect(
      rotationOn.proposedFeature.paramsOverride!.allowAutoRotation,
      isTrue,
    );
    expect(
      rotationOn
          .result!.materialization!.placements.single.transform.quarterTurns,
      1,
    );
    expect(
      rotationOn.result!.materialization!.placements
          .map((placement) => placement.slotKey)
          .toSet(),
      initialSlots,
    );
    expect(notifier.state.activeMap, same(map));
    expect(notifier.state.activeMap!.toJson(), beforeJson);
    expect(notifier.state.mapUndoStack, orderedEquals(historyBefore));
    expect(notifier.state.mapUndoStack.single, same(undo));
    expect(notifier.state.mapRedoStack.single, same(redo));

    expect(
      notifier.previewBorderFeatureAutoRotation(
        layerId: 'borders',
        featureId: feature.id,
        enabled: false,
      ),
      isTrue,
    );
    final rotationOff = preview.state.transaction!;
    expect(
      rotationOff.proposedFeature.paramsOverride!.allowAutoRotation,
      isFalse,
    );
    expect(
      rotationOff
          .result!.materialization!.placements.single.transform.quarterTurns,
      0,
    );
    expect(notifier.state.activeMap, same(map));
    expect(notifier.state.activeMap!.toJson(), beforeJson);
    expect(notifier.state.mapUndoStack, orderedEquals(historyBefore));
    expect(notifier.state.mapUndoStack.single, same(undo));
    expect(notifier.state.mapRedoStack.single, same(redo));
  });
}

ProjectManifest _project(List<BorderBlueprintRecord> records) =>
    ProjectManifest(
      name: 'Project',
      version: ProjectVersion.v2,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      borderCatalog: ProjectBorderCatalog(
        formatVersion: records.any(
          (record) =>
              record.draft.definition.template ==
              BorderBlueprintTemplate.stoneChainLine,
        )
            ? ProjectBorderCatalog.formatVersionV3
            : records.any(
                (record) =>
                    record.draft.definition.template ==
                    BorderBlueprintTemplate.connectedLine,
              )
                ? ProjectBorderCatalog.formatVersionV2
                : ProjectBorderCatalog.formatVersionV1,
        records: records,
        visualSnapshots: <BorderVisualSnapshot>[_snapshot()],
      ),
    );

BorderBlueprintRecord _record(
  String id, {
  bool published = true,
  bool isDeprecated = false,
  BorderBlueprintTemplate template = BorderBlueprintTemplate.organicEdge,
}) {
  final definition = BorderBlueprintDraftDefinition(
    name: id,
    previewSeed: BorderSignedInt64.zero,
    template: template,
    primitives: const <BorderPrimitiveDraft>[],
    defaults: _params(),
    sortOrder: 0,
  );
  return BorderBlueprintRecord(
    id: id,
    draft: BorderBlueprintDraft(
      baseRevision: published ? 1 : 0,
      definition: definition,
    ),
    latestPublished: published
        ? BorderBlueprintRevision(
            revision: 1,
            definition: BorderBlueprintPublishedDefinition(
              name: id,
              previewSeed: BorderSignedInt64.zero,
              template: template,
              primitives: template == BorderBlueprintTemplate.organicEdge
                  ? <BorderPublishedPrimitive>[_primitive()]
                  : const <BorderPublishedPrimitive>[],
              defaults: _params(),
              sortOrder: 0,
            ),
          )
        : null,
    isDeprecated: isDeprecated,
  );
}

BorderGenerationParams _params() => BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 0,
      maxOverlapPx: 0,
      gapTolerancePx: 0,
      depthRows: 1,
    );

BorderPublishedPrimitive _primitive() => BorderPublishedPrimitive(
      id: 'structure',
      sourceElementId: 'structure-source',
      visualSnapshotId: _snapshotId,
      role: BorderPrimitiveRole.structureLarge,
      weight: 1,
      anchorPx: const BorderPixelPos(x: 8, y: 8),
      transforms: BorderTransformPolicy(
        allowFlipX: true,
        allowedQuarterTurns: const <int>[0, 1, 2, 3],
      ),
      publishedMetrics: BorderPrimitiveAssetMetrics(
        assetFingerprint: 'asset-structure',
        pixelSize: const GridSize(width: 16, height: 16),
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
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

BorderMaterialization _materialization({
  int placementY = 0,
  int quarterTurns = 0,
}) =>
    BorderMaterialization(
      receipt: BorderResolutionReceipt(
        resolverVersion: 1,
        blueprintRevision: 1,
        components: BorderInputFingerprints(
          blueprint: 'sha256:${'0' * 64}',
          geometryAndSeed: 'sha256:${'1' * 64}',
          parameters: 'sha256:${'2' * 64}',
          overrides: 'sha256:${'3' * 64}',
          keepOutRegions: 'sha256:${'4' * 64}',
          mapContext: 'sha256:${'5' * 64}',
          visualSnapshots: 'sha256:${'6' * 64}',
        ),
        inputFingerprint: 'sha256:${'7' * 64}',
        outputFingerprint: 'sha256:${'8' * 64}',
      ),
      ground: <BorderResolvedGroundCell>[
        BorderResolvedGroundCell(
          x: 0,
          y: 0,
          visualSnapshotId:
              'border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          resolvedRole: SurfaceVariantRole.isolated,
        ),
      ],
      placements: <BorderResolvedPlacement>[
        BorderResolvedPlacement(
          id: 'placement-a',
          slotKey: 'slot-a',
          primitiveId: 'structure',
          visualSnapshotId: _snapshotId,
          anchorCell: const GridPos(x: 0, y: 0),
          topLeftWorldPx: BorderPixelPos(x: 0, y: placementY),
          opaqueWorldBoundsPx:
              BorderPixelRect(x: 0, y: placementY, width: 16, height: 16),
          transform: BorderSpriteTransform(
            quarterTurns: quarterTurns,
            flipX: false,
          ),
          drawBand: BorderDrawBand.structure,
          stableOrderKey: BorderStableOrderKey(
            drawBandIndex: borderDrawBandV1Index(BorderDrawBand.structure),
            anchorRowMajor: 0,
            passIndex: 0,
            rank: 0,
            ordinalLocal: 0,
            slotKey: 'slot-a',
          ),
        ),
      ],
    );

MapData _applyProposedFeature({
  required MapData map,
  required BorderPreviewTransaction transaction,
}) {
  final layerIndex = map.layers.indexWhere(
    (layer) => layer.id == transaction.layerId && layer is BorderLayer,
  );
  if (layerIndex < 0) return map;
  final layer = map.layers[layerIndex] as BorderLayer;
  final featureIndex = layer.content.features.indexWhere(
    (feature) => feature.id == transaction.featureId,
  );
  if (featureIndex < 0) return map;

  final proposed = transaction.proposedFeature;
  final features = List<BorderFeature>.from(layer.content.features);
  features[featureIndex] = BorderFeature(
    id: proposed.id,
    name: proposed.name,
    blueprintId: proposed.blueprintId,
    seed: proposed.seed,
    geometry: proposed.geometry,
    lineSide: proposed.lineSide,
    paramsOverride: proposed.paramsOverride,
    overrides: proposed.overrides,
    keepOutRegions: proposed.keepOutRegions,
    materialization: transaction.result?.materialization,
  );
  final layers = List<MapLayer>.from(map.layers);
  layers[layerIndex] = layer.copyWith(
    content: BorderLayerContent(
      formatVersion: layer.content.formatVersion,
      features: features,
    ),
  );
  return map.copyWith(layers: layers);
}
