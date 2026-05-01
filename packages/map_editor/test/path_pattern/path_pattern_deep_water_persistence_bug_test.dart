import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/path_studio/path_studio_edit_path_build_request.dart';
import 'package:map_editor/src/features/path_studio/path_studio_new_path_build_request.dart';
import 'package:map_editor/src/features/path_studio/path_studio_new_path_draft.dart';
import 'package:map_editor/src/features/path_studio/path_studio_save_flow.dart';

void main() {
  group('PathPattern deep_water persistence bugfix', () {
    test('fixture deep_water statique documente une frame par cellule', () async {
      final file = File(
        'test/fixtures/path_pattern/deep_water_static_saved_project_fixture.json',
      );
      final decoded = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final manifest = ProjectManifest.fromJson(decoded);
      final pattern = manifest.pathPatternPresets.singleWhere(
        (preset) => preset.id == 'nouveau-chemin-pattern',
      );

      expect(pattern.centerPattern.size.width, 2);
      expect(pattern.centerPattern.size.height, 2);
      expect(pattern.centerPattern.cells, hasLength(4));
      for (final cell in pattern.centerPattern.cells) {
        expect(cell.frames, hasLength(1));
        expect(cell.frames.single.durationMs, isNull);
      }
    });

    test('create flow conserve deep_water multi-frame jusqu au JSON roundtrip', () {
      final draft = _buildDeepWaterDraft2x2(
        createInitialPathStudioNewPathDraft(),
      );
      final buildPlan = createPathStudioNewPathBuildPlan(
        manifest: _emptyManifest(),
        draft: draft,
      );
      expect(buildPlan.canBuildRequest, isTrue);
      final request = buildPlan.buildRequest!;

      final updatedManifest = applyNewPathBuildRequestToManifest(
        manifest: _emptyManifest(),
        request: request,
      );

      final reloaded = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(updatedManifest.toJson())) as Map<String, dynamic>,
      );
      _expectDeepWaterAnimatedPattern(reloaded.pathPatternPresets.single);
    });

    test('edit flow part de statique et persiste deep_water multi-frame', () {
      final staticManifest = _loadStaticDeepWaterManifestFixture();
      final staticPattern = staticManifest.pathPatternPresets.single;
      final staticBase = staticManifest.pathPresets.single;

      final editDraft = _buildDeepWaterDraft2x2(
        createPathStudioEditDraftFromExistingPathPattern(
          pathPatternPreset: staticPattern,
          basePathPreset: staticBase,
        ),
      );
      final editPlan = createPathStudioEditPathBuildPlan(
        manifest: staticManifest,
        draft: editDraft,
      );
      expect(editPlan.canBuildRequest, isTrue);
      final editRequest = editPlan.buildRequest!;

      final updatedManifest = applyPathPatternEditRequestToManifest(
        manifest: staticManifest,
        request: editRequest,
      );
      final reloaded = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(updatedManifest.toJson())) as Map<String, dynamic>,
      );
      _expectDeepWaterAnimatedPattern(
        reloaded.pathPatternPresets.singleWhere(
          (preset) => preset.id == 'nouveau-chemin-pattern',
        ),
      );
    });

    test('saveProjectManifest serialize le manifest courant en memoire', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'deep_water_persistence_',
      );
      final manifestPath = '${tempDir.path}/project.json';
      const fixturePath =
          'test/fixtures/path_pattern/deep_water_static_saved_project_fixture.json';
      await File(fixturePath).copy(manifestPath);

      final container = ProviderContainer();
      addTearDown(() async {
        container.dispose();
        await tempDir.delete(recursive: true);
      });

      final notifier = container.read(editorNotifierProvider.notifier);
      await notifier.loadProject(manifestPath);
      final loadedState = notifier.state;
      expect(
        loadedState.project,
        isNotNull,
        reason: 'loadProject error: ${loadedState.errorMessage}',
      );
      final loaded = loadedState.project!;
      final editDraft = _buildDeepWaterDraft2x2(
        createPathStudioEditDraftFromExistingPathPattern(
          pathPatternPreset: loaded.pathPatternPresets.single,
          basePathPreset: loaded.pathPresets.single,
        ),
      );
      final editPlan = createPathStudioEditPathBuildPlan(
        manifest: loaded,
        draft: editDraft,
      );
      final updatedManifest = applyPathPatternEditRequestToManifest(
        manifest: loaded,
        request: editPlan.buildRequest!,
      );

      notifier.applyInMemoryProjectManifest(updatedManifest);
      final saveResult = await notifier.saveProjectManifest();
      expect(saveResult, isTrue);

      final persisted = ProjectManifest.fromJson(
        jsonDecode(await File(manifestPath).readAsString()) as Map<String, dynamic>,
      );
      _expectDeepWaterAnimatedPattern(
        persisted.pathPatternPresets.singleWhere(
          (preset) => preset.id == 'nouveau-chemin-pattern',
        ),
      );
    });
  });
}

PathStudioNewPathDraft _buildDeepWaterDraft2x2(PathStudioNewPathDraft initial) {
  var draft = renamePathStudioNewPathDraft(initial, 'Nouveau chemin');
  draft = selectPathStudioNewPathDraftSurfaceKind(
    draft: draft,
    surfaceKind: PathSurfaceKind.water,
  );
  draft = selectPathStudioNewPathDraftTileset(draft, 'deep_water');
  draft = resizePathStudioNewPathDraftCenter(
    draft: draft,
    width: 2,
    height: 2,
  );

  draft = _assignAnimatedCell(
    draft: draft,
    localX: 0,
    localY: 0,
    frames: const [(0, 0), (3, 0), (6, 0)],
  );
  draft = _assignAnimatedCell(
    draft: draft,
    localX: 1,
    localY: 0,
    frames: const [(1, 0), (4, 0), (7, 0)],
  );
  draft = _assignAnimatedCell(
    draft: draft,
    localX: 0,
    localY: 1,
    frames: const [(0, 1), (3, 1), (6, 1)],
  );
  draft = _assignAnimatedCell(
    draft: draft,
    localX: 1,
    localY: 1,
    frames: const [(1, 1), (4, 1), (7, 1)],
  );
  return draft;
}

PathStudioNewPathDraft _assignAnimatedCell({
  required PathStudioNewPathDraft draft,
  required int localX,
  required int localY,
  required List<(int, int)> frames,
}) {
  var next = assignPathStudioNewPathDraftCellTile(
    draft: draft,
    localX: localX,
    localY: localY,
    sourceX: frames.first.$1,
    sourceY: frames.first.$2,
  );
  next = updatePathStudioNewPathDraftCenterFrameDuration(
    draft: next,
    localX: localX,
    localY: localY,
    frameIndex: 0,
    durationMs: 200,
  );
  for (final coordinate in frames.skip(1)) {
    next = appendPathStudioNewPathDraftCenterFrame(
      draft: next,
      localX: localX,
      localY: localY,
    );
    next = assignPathStudioNewPathDraftCellTile(
      draft: next,
      localX: localX,
      localY: localY,
      sourceX: coordinate.$1,
      sourceY: coordinate.$2,
    );
    next = updatePathStudioNewPathDraftCenterFrameDuration(
      draft: next,
      localX: localX,
      localY: localY,
      frameIndex: next.selectedCenterFrameIndex,
      durationMs: 200,
    );
  }
  return next;
}

void _expectDeepWaterAnimatedPattern(ProjectPathPatternPreset pattern) {
  final byKey = <String, List<TilesetVisualFrame>>{
    for (final cell in pattern.centerPattern.cells)
      '${cell.localX},${cell.localY}': cell.frames,
  };
  _expectCellFrames(
    byKey['0,0']!,
    const [0, 3, 6],
    expectedY: 0,
  );
  _expectCellFrames(
    byKey['1,0']!,
    const [1, 4, 7],
    expectedY: 0,
  );
  _expectCellFrames(
    byKey['0,1']!,
    const [0, 3, 6],
    expectedY: 1,
  );
  _expectCellFrames(
    byKey['1,1']!,
    const [1, 4, 7],
    expectedY: 1,
  );
}

void _expectCellFrames(
  List<TilesetVisualFrame> frames,
  List<int> expectedXs, {
  required int expectedY,
}) {
  expect(frames.length, greaterThanOrEqualTo(3));
  for (var i = 0; i < 3; i += 1) {
    final frame = frames[i];
    expect(frame.tilesetId, 'deep_water');
    expect(frame.durationMs, 200);
    expect(frame.source.x, expectedXs[i]);
    expect(frame.source.y, expectedY);
  }
}

ProjectManifest _emptyManifest() {
  return ProjectManifest(
    name: 'Deep Water',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'deep_water',
        name: 'Deep Water',
        relativePath: 'assets/tilesets/deep_water.png',
      ),
    ],
    pathPresets: const [],
    pathPatternPresets: const [],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectManifest _loadStaticDeepWaterManifestFixture() {
  final fixture = File(
    'test/fixtures/path_pattern/deep_water_static_saved_project_fixture.json',
  );
  final decoded = jsonDecode(fixture.readAsStringSync()) as Map<String, dynamic>;
  return ProjectManifest.fromJson(decoded);
}
