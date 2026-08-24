import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  test('editor creates a layer and commits paint and erase once per gesture',
      () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_smart_tile_editor_flow_',
    );
    final container = ProviderContainer();
    addTearDown(() async {
      container.dispose();
      if (await root.exists()) await root.delete(recursive: true);
    });

    final manifest = _manifest();
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: GridSize(width: 3, height: 2),
      visualStack: MapVisualStackConfig.canonicalV1,
    );
    final mapPath = p.join(root.path, 'maps', 'map.json');
    await Directory(p.dirname(mapPath)).create(recursive: true);
    await FileProjectRepository().saveProject(
      manifest,
      p.join(root.path, 'project.json'),
    );
    await FileMapRepository().saveMap(
      map,
      mapPath,
      projectDialogueContext: manifest,
    );

    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      projectRootPath: root.path,
      project: manifest,
      workspaceMode: EditorWorkspaceMode.map,
    );
    await notifier.loadMap('maps/map.json');
    expect(notifier.state.errorMessage, isNull);

    final preset = manifest.smartTileCatalog.presets.single;
    final created = await notifier.createCanonicalSmartTileLayer(
      preset: preset,
    );
    expect(created, isTrue, reason: notifier.state.errorMessage);
    final layerId = notifier.state.activeLayerId!;
    expect(layerId, 'grass_preset_layer');
    expect(notifier.state.isDirty, isFalse);
    expect(notifier.state.isProjectDirty, isFalse);

    final mutations = container.read(authoringMutationAdapterProvider);
    final snapshotCache = container.read(authoringSnapshotCacheProvider);
    final missesBeforeDirtyGesture = snapshotCache.misses;
    notifier.state = notifier.state.copyWith(
      activeTool: EditorToolType.terrainPaint,
    );
    notifier.updateMapMetadata(
      notifier.state.activeMap!.mapMetadata.copyWith(
        displayName: 'Unsaved before painting a path',
      ),
    );
    expect(notifier.state.isDirty, isTrue);
    notifier.applyActiveSmartTileSelection(
      const SmartTileGestureSelection.line(
        start: GridPos(x: 0, y: 0),
        end: GridPos(x: 1, y: 0),
      ),
    );
    expect(notifier.state.errorMessage, isNull);
    expect(notifier.state.isSaving, isTrue);

    await _waitUntil(
      () =>
          mutations.lastAppliedReceipt?.actionId == 'smart_tile.cell.paint' &&
          !notifier.state.isDirty,
      failure: () => null,
    );
    final paintReceipt = mutations.lastAppliedReceipt!;
    expect(paintReceipt.diff.entries, hasLength(1));
    expect(paintReceipt.affectedResources, hasLength(1));
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.canUndoMap, isTrue);
    expect(notifier.state.errorMessage, isNull);
    expect(
      snapshotCache.misses,
      missesBeforeDirtyGesture,
      reason: 'save + paint must project committed map bytes, not reload them',
    );
    expect(
      smartTileSemanticCells(
        notifier.state.activeMap!.layers.single as SmartTileLayer,
      ),
      <int>[1, 1, 0, 0, 0, 0],
    );

    notifier.updateMapMetadata(
      notifier.state.activeMap!.mapMetadata.copyWith(
        displayName: 'Unsaved before erasing a path',
      ),
    );
    expect(notifier.state.isDirty, isTrue);
    notifier.beginMapStroke();
    notifier.eraseAt(const GridPos(x: 0, y: 0));
    notifier.eraseAt(const GridPos(x: 1, y: 0));
    notifier.endMapStroke();

    await _waitUntil(
      () =>
          mutations.lastAppliedReceipt?.actionId == 'smart_tile.cell.erase' &&
          !notifier.state.isDirty,
      failure: () => notifier.state.errorMessage,
    );
    final eraseReceipt = mutations.lastAppliedReceipt!;
    expect(eraseReceipt.diff.entries, hasLength(1));
    expect(eraseReceipt.affectedResources, hasLength(1));
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.canUndoMap, isTrue);
    expect(notifier.state.errorMessage, isNull);
    expect(
      snapshotCache.misses,
      missesBeforeDirtyGesture,
      reason: 'the following erase must remain on the warm snapshot path',
    );

    notifier.undoMap();
    await _waitUntil(
      () =>
          mutations.lastAppliedReceipt?.actionId == 'history.undo' &&
          smartTileSemanticCells(
                notifier.state.activeMap!.layers.single as SmartTileLayer,
              ).join(',') ==
              '1,1,0,0,0,0',
      failure: () => notifier.state.errorMessage,
    );
    expect(notifier.state.canUndoMap, isTrue);
    expect(notifier.state.canRedoMap, isTrue);

    final undoReceiptId = mutations.lastAppliedReceipt!.receiptId;
    notifier.redoMap();
    await _waitUntil(
      () =>
          mutations.lastAppliedReceipt?.receiptId != undoReceiptId &&
          mutations.lastAppliedReceipt?.actionId == 'smart_tile.cell.erase' &&
          smartTileSemanticCells(
            notifier.state.activeMap!.layers.single as SmartTileLayer,
          ).every((value) => value == 0),
      failure: () => notifier.state.errorMessage,
    );
    expect(notifier.state.canUndoMap, isTrue);
    expect(notifier.state.canRedoMap, isFalse);

    final diskMap = await FileMapRepository().loadMap(mapPath);
    expect(
      diskMap.mapMetadata.displayName,
      'Unsaved before erasing a path',
    );
    expect(
      smartTileSemanticCells(diskMap.layers.single as SmartTileLayer),
      <int>[0, 0, 0, 0, 0, 0],
    );
  });

  test(
      'a narrative conflict does not block or absorb a canonical map erase',
      () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_smart_tile_narrative_conflict_',
    );
    final container = ProviderContainer();
    addTearDown(() async {
      container.dispose();
      if (await root.exists()) await root.delete(recursive: true);
    });

    final before = _manifest(cinematicTitle: 'Ouverture');
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: GridSize(width: 3, height: 2),
      visualStack: MapVisualStackConfig.canonicalV1,
    );
    final projectPath = p.join(root.path, 'project.json');
    final mapPath = p.join(root.path, 'maps', 'map.json');
    await Directory(p.dirname(mapPath)).create(recursive: true);
    await FileProjectRepository().saveProject(before, projectPath);
    await FileMapRepository().saveMap(
      map,
      mapPath,
      projectDialogueContext: before,
    );

    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      projectRootPath: root.path,
      project: before,
      workspaceMode: EditorWorkspaceMode.map,
    );
    await notifier.loadMap('maps/map.json');
    expect(
      await notifier.createCanonicalSmartTileLayer(
        preset: before.smartTileCatalog.presets.single,
      ),
      isTrue,
      reason: notifier.state.errorMessage,
    );
    final mutations = container.read(authoringMutationAdapterProvider);
    notifier.state = notifier.state.copyWith(
      activeTool: EditorToolType.terrainPaint,
    );
    notifier.applyActiveSmartTileSelection(
      const SmartTileGestureSelection.line(
        start: GridPos(x: 0, y: 0),
        end: GridPos(x: 0, y: 0),
      ),
    );
    await _waitUntil(
      () => mutations.lastAppliedReceipt?.actionId == 'smart_tile.cell.paint',
      failure: () => notifier.state.errorMessage,
    );

    final local = _manifest(cinematicTitle: 'Ouverture locale');
    expect(
      await notifier.applyNarrativeDocumentEdit(
        local,
        operationId: 'smart-tile-conflict-local-edit',
        label: 'Renommer la cinématique',
      ),
      isTrue,
    );
    final external = _manifest(cinematicTitle: 'Ouverture externe');
    await FileProjectRepository().saveProject(external, projectPath);
    expect(await notifier.saveNarrativeDocument(), isFalse);
    expect(
      notifier.narrativeDocumentStatus,
      NarrativeDocumentSessionStatus.conflicted,
    );
    final narrativeConflict = notifier.state.errorMessage;
    expect(narrativeConflict, isNotNull);

    notifier.updateMapMetadata(
      notifier.state.activeMap!.mapMetadata.copyWith(
        displayName: 'Carte modifiée avant la gomme',
      ),
    );
    final receiptBeforeErase = mutations.lastAppliedReceipt!.receiptId;
    notifier.beginMapStroke();
    notifier.eraseAt(const GridPos(x: 0, y: 0));
    notifier.endMapStroke();

    await _waitUntil(
      () =>
          mutations.lastAppliedReceipt?.receiptId != receiptBeforeErase &&
          mutations.lastAppliedReceipt?.actionId == 'smart_tile.cell.erase' &&
          !notifier.state.isDirty,
      failure: () => notifier.state.errorMessage == narrativeConflict
          ? null
          : notifier.state.errorMessage,
    );
    expect(notifier.state.isProjectDirty, isTrue);
    expect(notifier.state.errorMessage, narrativeConflict);
    expect(
      notifier.narrativeDocumentStatus,
      NarrativeDocumentSessionStatus.conflicted,
    );
    expect(notifier.state.project!.cinematics.single.title, 'Ouverture locale');
    expect(
      smartTileSemanticCells(
        notifier.state.activeMap!.layers.single as SmartTileLayer,
      ),
      <int>[0, 0, 0, 0, 0, 0],
    );

    final durableProject =
        await FileProjectRepository().loadProject(projectPath);
    expect(durableProject.cinematics.single.title, 'Ouverture externe');
    final durableMap = await FileMapRepository().loadMap(mapPath);
    expect(durableMap.mapMetadata.displayName, 'Carte modifiée avant la gomme');
    expect(
      smartTileSemanticCells(durableMap.layers.single as SmartTileLayer),
      <int>[0, 0, 0, 0, 0, 0],
    );
  });

  test('editor commits reusable pattern paint, history, and semantic erase',
      () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_smart_tile_pattern_editor_flow_',
    );
    final container = ProviderContainer();
    addTearDown(() async {
      container.dispose();
      if (await root.exists()) await root.delete(recursive: true);
    });

    final manifest = _manifest();
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: GridSize(width: 3, height: 2),
      visualStack: MapVisualStackConfig.canonicalV1,
    );
    final mapPath = p.join(root.path, 'maps', 'map.json');
    await Directory(p.dirname(mapPath)).create(recursive: true);
    await FileProjectRepository().saveProject(
      manifest,
      p.join(root.path, 'project.json'),
    );
    await FileMapRepository().saveMap(
      map,
      mapPath,
      projectDialogueContext: manifest,
    );

    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      projectRootPath: root.path,
      project: manifest,
      workspaceMode: EditorWorkspaceMode.map,
    );
    await notifier.loadMap('maps/map.json');
    expect(
      await notifier.createCanonicalSmartTileLayer(
        preset: manifest.smartTileCatalog.presets.single,
      ),
      isTrue,
    );

    final mutations = container.read(authoringMutationAdapterProvider);
    notifier.paintActiveSmartTilePattern(
      const SmartTilePatternSelection.stamp(
        anchor: GridPos(x: 1, y: 0),
      ),
      patternId: 'grass_patch',
    );
    await _waitUntil(
      () =>
          mutations.lastAppliedReceipt?.actionId ==
              'smart_tile.pattern.paint' &&
          (notifier.state.activeMap!.layers.single as SmartTileLayer)
                  .patternStrokes
                  .length ==
              1,
      failure: () => notifier.state.errorMessage,
    );
    expect(notifier.state.isDirty, isFalse);
    expect(notifier.state.canUndoMap, isTrue);

    notifier.undoMap();
    await _waitUntil(
      () =>
          mutations.lastAppliedReceipt?.actionId == 'history.undo' &&
          (notifier.state.activeMap!.layers.single as SmartTileLayer)
              .patternStrokes
              .isEmpty,
      failure: () => notifier.state.errorMessage,
    );
    expect(notifier.state.canRedoMap, isTrue);

    notifier.redoMap();
    await _waitUntil(
      () =>
          mutations.lastAppliedReceipt?.actionId ==
              'smart_tile.pattern.paint' &&
          (notifier.state.activeMap!.layers.single as SmartTileLayer)
                  .patternStrokes
                  .length ==
              1,
      failure: () => notifier.state.errorMessage,
    );
    expect(notifier.state.canRedoMap, isFalse);

    notifier.eraseActiveSmartTilePattern(
      const SmartTileGestureSelection.line(
        start: GridPos(x: 1, y: 0),
        end: GridPos(x: 1, y: 0),
      ),
    );
    await _waitUntil(
      () =>
          mutations.lastAppliedReceipt?.actionId ==
              'smart_tile.pattern.erase' &&
          (notifier.state.activeMap!.layers.single as SmartTileLayer)
              .patternStrokes
              .isEmpty,
      failure: () => notifier.state.errorMessage,
    );

    final diskLayer = (await FileMapRepository().loadMap(mapPath)).layers.single
        as SmartTileLayer;
    expect(diskLayer.patternStrokes, isEmpty);
    expect(notifier.state.errorMessage, isNull);
  });

  test('a rejected canonical gesture rolls back its optimistic map exactly',
      () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_smart_tile_editor_rollback_',
    );
    final container = ProviderContainer();
    addTearDown(() async {
      container.dispose();
      if (await root.exists()) await root.delete(recursive: true);
    });

    final manifest = _manifest();
    const map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: GridSize(width: 3, height: 2),
      visualStack: MapVisualStackConfig.canonicalV1,
    );
    final mapPath = p.join(root.path, 'maps', 'map.json');
    await Directory(p.dirname(mapPath)).create(recursive: true);
    await FileProjectRepository().saveProject(
      manifest,
      p.join(root.path, 'project.json'),
    );
    await FileMapRepository().saveMap(
      map,
      mapPath,
      projectDialogueContext: manifest,
    );

    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      projectRootPath: root.path,
      project: manifest,
      workspaceMode: EditorWorkspaceMode.map,
    );
    await notifier.loadMap('maps/map.json');
    final preset = manifest.smartTileCatalog.presets.single;
    expect(
      await notifier.createCanonicalSmartTileLayer(preset: preset),
      isTrue,
    );
    final layerId = notifier.state.activeLayerId!;
    final mutations = container.read(authoringMutationAdapterProvider);
    final queries = container.read(authoringQueryAdapterProvider);
    await notifier.applySmartTileLayerVariantWeights(
      mapId: 'map',
      layerId: layerId,
      weights: const <String, int>{'base': 7},
    );
    await _waitUntil(
      () =>
          mutations.lastAppliedReceipt?.actionId ==
              'smart_tile.layer.set_candidate_weights' &&
          (notifier.state.activeMap!.layers.single as SmartTileLayer)
                  .candidateWeights['base'] ==
              7,
      failure: () => notifier.state.errorMessage,
    );
    final canonicalSession = await queries.open(root.path);
    final revisionBeforeRejection = canonicalSession.snapshotRevision;
    final receiptBeforeRejection = mutations.lastAppliedReceipt!;
    final catalog = notifier.state.project!.smartTileCatalog;
    notifier.state = notifier.state.copyWith(
      project: manifest.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          categories: catalog.categories,
          atlases: catalog.atlases,
          materials: <ProjectSmartTileMaterial>[
            ...catalog.materials,
            const ProjectSmartTileMaterial(
              id: 'not_allowed',
              name: 'Local only',
              connectionGroupId: 'ground',
            ),
          ],
          animations: catalog.animations,
          presets: <ProjectSmartTilePreset>[
            catalog.presets.single.copyWith(
              allowedMaterialIds: <String>['grass', 'not_allowed'],
            ),
          ],
          drafts: catalog.drafts,
        ),
      ),
    );
    final baseline = notifier.state.activeMap!;
    final baselineLayer = baseline.layers.single as SmartTileLayer;
    final baselineUndoStack = notifier.state.mapUndoStack;
    final baselineRedoStack = notifier.state.mapRedoStack;
    final baselineCanUndo = notifier.state.canUndoMap;
    final baselineCanRedo = notifier.state.canRedoMap;
    final baselineSavedMapSnapshot = notifier.state.savedMapSnapshot;
    expect(baselineLayer.candidateWeights, const <String, int>{'base': 7});
    expect(baselineCanUndo, isFalse);
    expect(baselineCanRedo, isFalse);

    notifier.beginMapStroke();
    notifier.paintSmartTileMaterialAt(
      const GridPos(x: 0, y: 0),
      materialId: 'not_allowed',
    );
    expect(notifier.state.activeMap, same(baseline));
    final preview = notifier.activeMapCellStrokePreview!;
    expect(preview.smartTileMaterialAt(0, 0), 'not_allowed');
    expect(
      (notifier.state.activeMap!.layers.single as SmartTileLayer)
          .candidateWeights,
      baselineLayer.candidateWeights,
    );
    notifier.endMapStroke();

    await _waitUntil(
      () =>
          notifier.state.errorMessage != null &&
          notifier.state.activeMap == baseline,
      failure: () => null,
    );
    expect(
      notifier.state.errorMessage,
      'Le matériau choisi n’est pas disponible dans ce calque Smart Tile.',
    );
    expect(
      notifier.state.errorMessage,
      isNot('smart_tile.cell.material_not_allowed'),
    );
    final restored = notifier.state.activeMap!;
    final restoredLayer = restored.layers.single as SmartTileLayer;
    expect(restored.toJson(), baseline.toJson());
    expect(restored.mapMetadata, baseline.mapMetadata);
    expect(restoredLayer.field, baselineLayer.field);
    expect(restoredLayer.materialPalette, baselineLayer.materialPalette);
    expect(restoredLayer.candidateWeights, baselineLayer.candidateWeights);
    expect(restoredLayer.properties, baselineLayer.properties);
    expect(notifier.state.activeLayerId, layerId);
    expect(notifier.state.savedMapSnapshot, baselineSavedMapSnapshot);
    expect(notifier.state.isDirty, isFalse);
    expect(notifier.state.mapStrokeStart, isNull);
    expect(notifier.state.mapUndoStack, orderedEquals(baselineUndoStack));
    expect(notifier.state.mapRedoStack, orderedEquals(baselineRedoStack));
    expect(notifier.state.canUndoMap, baselineCanUndo);
    expect(notifier.state.canRedoMap, baselineCanRedo);
    expect(
      mutations.lastAppliedReceipt?.receiptId,
      receiptBeforeRejection.receiptId,
    );
    expect(
      mutations.lastAppliedReceipt?.actionId,
      receiptBeforeRejection.actionId,
    );
    expect(
      (await canonicalSession.validateFresh())['snapshotRevision'],
      revisionBeforeRejection,
    );
    expect(
      (await FileMapRepository().loadMap(mapPath)).toJson(),
      baseline.toJson(),
    );

    notifier.undoMap();
    notifier.redoMap();
    expect(notifier.state.activeMap!.toJson(), baseline.toJson());
    expect(notifier.state.mapUndoStack, orderedEquals(baselineUndoStack));
    expect(notifier.state.mapRedoStack, orderedEquals(baselineRedoStack));
    expect(notifier.state.canUndoMap, baselineCanUndo);
    expect(notifier.state.canRedoMap, baselineCanRedo);
    expect(
      mutations.lastAppliedReceipt?.receiptId,
      receiptBeforeRejection.receiptId,
    );
  });
}

Future<void> _waitUntil(
  bool Function() condition, {
  required String? Function() failure,
}) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    if (condition()) return;
    final error = failure();
    if (error != null) fail('Canonical editor flow failed: $error');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out while waiting for the canonical editor gesture.');
}

ProjectManifest _manifest({String cinematicTitle = 'Ouverture'}) => ProjectManifest(
      name: 'Smart Tile editor flow',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map',
          name: 'Map',
          relativePath: 'maps/map.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'tileset',
          name: 'Tileset',
          relativePath: 'assets/tileset.png',
        ),
      ],
      cinematics: <CinematicAsset>[
        CinematicAsset(
          id: 'opening',
          title: cinematicTitle,
          timeline: CinematicTimeline(),
        ),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        atlases: const <ProjectSmartTileAtlas>[
          ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Atlas',
            tilesetId: 'tileset',
            columns: 1,
            rows: 1,
          ),
        ],
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Herbe',
            connectionGroupId: 'ground',
          ),
        ],
        patterns: const <ProjectSmartTilePattern>[
          ProjectSmartTilePattern(
            id: 'grass_patch',
            name: "Touffe d'herbe",
            usage: SmartTileUsage.terrain,
            width: 1,
            height: 1,
            repeatMode: SmartTilePatternRepeatMode.stamp,
            cells: <SmartTilePatternCell>[
              SmartTilePatternCell(
                x: 0,
                y: 0,
                parts: <SmartTileVisualPart>[
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: 'atlas',
                        column: 0,
                        row: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        presets: const <ProjectSmartTilePreset>[
          ProjectSmartTilePreset(
            id: 'grass_preset',
            name: 'Prairie',
            usage: SmartTileUsage.terrain,
            topology: SmartTileTopology.uniform,
            templateHint: SmartTileTemplateHint.simple,
            status: SmartTilePresetStatus.published,
            coveragePolicy: SmartTileCoveragePolicy.sparse,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'grass',
            allowedMaterialIds: <String>['grass'],
            rules: <SmartTileRule>[
              SmartTileRule(
                id: 'base',
                centerMatch: SmartTileSlotMatch.material('grass'),
                signature: SmartTileSignature(),
                candidates: <SmartTileCandidate>[
                  SmartTileCandidate(
                    id: 'base',
                    parts: <SmartTileVisualPart>[
                      SmartTileVisualPart(
                        source: SmartTileVisualSource.frame(
                          frame: SmartTileFrameRef(
                            atlasId: 'atlas',
                            column: 0,
                            row: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
