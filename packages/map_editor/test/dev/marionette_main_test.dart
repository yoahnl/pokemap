import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

import '../../dev/marionette_main.dart' as marionette;

void main() {
  test('resolves a sandbox-owned personalization seed', () async {
    final sandbox = Directory.systemTemp.createTempSync(
      'pokemap_marionette_main_seed_',
    );
    addTearDown(() => sandbox.deleteSync(recursive: true));

    final projectPath = await marionette.resolveMarionetteProjectPath(
      configuredProjectPath: '',
      configuredSeed: 'personalization-v3',
      configuredRunId: 'phase-b-main',
      sandboxRoot: sandbox,
      loadAsset: (_) async => const <int>[1, 2, 3],
    );

    expect(File('$projectPath/project.json').existsSync(), isTrue);
  });

  test('requires exactly one deterministic project source', () async {
    final sandbox = Directory.systemTemp.createTempSync(
      'pokemap_marionette_main_seed_',
    );
    addTearDown(() => sandbox.deleteSync(recursive: true));

    expect(
      () => marionette.resolveMarionetteProjectPath(
        configuredProjectPath: '/project',
        configuredSeed: 'personalization-v3',
        configuredRunId: 'phase-b-main',
        sandboxRoot: sandbox,
        loadAsset: (_) async => const <int>[1],
      ),
      throwsStateError,
    );
  });

  test('opens Character Studio through the deterministic QA extension', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/qa/characters',
      project: ProjectManifest(
        name: 'Character QA',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        characters: <ProjectCharacterEntry>[
          ProjectCharacterEntry(
            id: 'character-qa',
            name: 'Character QA Hero',
            tilesetId: 'tileset-character-qa',
          ),
        ],
      ),
      workspaceMode: EditorWorkspaceMode.map,
    );

    final result = marionette.openCharacterStudioForMarionette(
      container: container,
    );

    expect(result, <String, Object?>{
      'opened': true,
      'workspaceMode': 'characterStudio',
      'projectRootPath': '/qa/characters',
      'projectName': 'Character QA',
      'characterCount': 1,
      'defaultCharacterId': 'character-qa',
      'defaultCharacterName': 'Character QA Hero',
    });
    expect(
      container.read(editorNotifierProvider).workspaceMode,
      EditorWorkspaceMode.characterStudio,
    );
  });

  test(
    'opens Personalization Studio through the deterministic QA extension',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/qa/personalization',
        project: ProjectManifest(
          name: 'Personalization QA',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
        workspaceMode: EditorWorkspaceMode.map,
      );

      final result = marionette.openPersonalizationStudioForMarionette(
        container: container,
      );

      expect(result, <String, Object?>{
        'opened': true,
        'workspaceMode': 'personalizationStudio',
        'projectRootPath': '/qa/personalization',
        'projectName': 'Personalization QA',
      });
      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.personalizationStudio,
      );
    },
  );

  test(
    'selectEditorTool selects borderPaint without touching map or history',
    () {
      final map = _mapWithBorderFeature();
      final undo = MapHistorySnapshot(map: map.copyWith(name: 'Before'));
      final redo = MapHistorySnapshot(map: map.copyWith(name: 'After'));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        activeMap: map,
        activeLayerId: 'border-layer',
        activeTool: EditorToolType.selection,
        mapUndoStack: <MapHistorySnapshot>[undo],
        mapRedoStack: <MapHistorySnapshot>[redo],
        canUndoMap: true,
        canRedoMap: true,
      );
      final before = container.read(editorNotifierProvider);
      final beforeMapJson = before.activeMap!.toJson();

      final result = marionette.selectEditorToolForMarionette(
        container: container,
        parameters: const <String, String>{'tool': 'borderPaint'},
      );

      expect(result['selected'], isTrue);
      expect(result['activeTool'], 'borderPaint');
      expect(result['activeLayerId'], 'border-layer');
      expect(result['activeBorderFeatureId'], 'border-feature');
      expect(result['featureId'], result['activeBorderFeatureId']);
      final after = container.read(editorNotifierProvider);
      expect(after.activeMap, same(before.activeMap));
      expect(after.activeMap!.toJson(), beforeMapJson);
      expect(after.mapUndoStack, before.mapUndoStack);
      expect(after.mapRedoStack, before.mapRedoStack);
      expect(after.mapUndoStack.single, same(undo));
      expect(after.mapRedoStack.single, same(redo));
      expect(after.canUndoMap, before.canUndoMap);
      expect(after.canRedoMap, before.canRedoMap);
    },
  );

  test('selectEditorTool rejects every tool other than borderPaint', () {
    final map = _mapWithBorderFeature();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      activeMap: map,
      activeLayerId: 'border-layer',
      activeTool: EditorToolType.selection,
    );
    final before = container.read(editorNotifierProvider);

    final result = marionette.selectEditorToolForMarionette(
      container: container,
      parameters: const <String, String>{'tool': 'selection'},
    );

    expect(result['selected'], isFalse);
    expect(result['error'], 'tool must be borderPaint.');
    expect(container.read(editorNotifierProvider), same(before));
  });

  test(
    'setBorderPreviewAutoRotation rejects a non-boolean wire as a no-op',
    () {
      final map = _mapWithBorderFeature();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        activeMap: map,
        activeLayerId: 'border-layer',
        activeTool: EditorToolType.borderPaint,
      );
      final before = container.read(editorNotifierProvider);

      final result = marionette.setBorderPreviewAutoRotationForMarionette(
        container: container,
        parameters: const <String, String>{
          'layerId': 'border-layer',
          'featureId': 'border-feature',
          'enabled': 'yes',
        },
      );

      expect(result['updated'], isFalse);
      expect(
        result['error'],
        'layerId, featureId and enabled=true|false are required.',
      );
      expect(container.read(editorNotifierProvider), same(before));
    },
  );

  test('disabling QA fillers preserves authored cardinal orientations', () {
    final structure = _primitive(
      id: 'top-west',
      role: BorderPrimitiveRole.structureLarge,
      orientation: BorderPrimitiveOrientation.west,
      weight: 750,
    );
    final filler = _primitive(
      id: 'detail-east',
      role: BorderPrimitiveRole.filler,
      orientation: BorderPrimitiveOrientation.east,
      weight: 500,
    );

    final result = marionette.disableFillerPrimitivesForMarionette(
      <BorderPrimitiveDraft>[structure, filler],
    );

    expect(result, hasLength(2));
    expect(result.first.authoredOrientation, BorderPrimitiveOrientation.west);
    expect(result.first.weight, 750);
    expect(result.last.authoredOrientation, BorderPrimitiveOrientation.east);
    expect(result.last.weight, 0);
    expect(result.first.anchorPx, structure.anchorPx);
    expect(result.first.transforms, structure.transforms);
    expect(result.first.currentMetrics, structure.currentMetrics);
  });
}

BorderPrimitiveDraft _primitive({
  required String id,
  required BorderPrimitiveRole role,
  required BorderPrimitiveOrientation orientation,
  required int weight,
}) => BorderPrimitiveDraft(
  id: id,
  sourceElementId: 'element-$id',
  role: role,
  authoredOrientation: orientation,
  weight: weight,
  anchorPx: const BorderPixelPos(x: 4, y: 8),
  transforms: BorderTransformPolicy(
    allowFlipX: false,
    allowedQuarterTurns: const <int>[0, 1, 2, 3],
  ),
  currentMetrics: BorderPrimitiveAssetMetrics(
    assetFingerprint: 'sha256:$id',
    pixelSize: const GridSize(width: 16, height: 16),
    opaqueBounds: BorderPixelRect(x: 2, y: 2, width: 12, height: 12),
    defaultAnchorPx: const BorderPixelPos(x: 4, y: 8),
    occupancyMaskRle: 'border-rle-v1:256:0:256',
  ),
);

MapData _mapWithBorderFeature() => MapData(
  id: 'marionette-map',
  name: 'Marionette map',
  version: ProjectVersion.v6,
  size: const GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    MapLayer.border(
      id: 'border-layer',
      name: 'Border layer',
      content: BorderLayerContent(
        formatVersion: BorderLayerContent.formatVersionV3,
        features: <BorderFeature>[
          BorderFeature(
            id: 'border-feature',
            name: 'Border feature',
            blueprintId: 'border-blueprint',
            seed: BorderSignedInt64.zero,
            geometry: BorderStrokeGeometry(
              strokes: <BorderStroke>[
                BorderStroke(
                  id: 'stroke',
                  points: const <GridPos>[
                    GridPos(x: 0, y: 0),
                    GridPos(x: 1, y: 0),
                  ],
                  closed: false,
                ),
              ],
              alignment: BorderStrokeAlignment.gridEdges,
            ),
            overrides: const <BorderSlotOverride>[],
            keepOutRegions: const <BorderKeepOutRegion>[],
          ),
        ],
      ),
    ),
  ],
);
