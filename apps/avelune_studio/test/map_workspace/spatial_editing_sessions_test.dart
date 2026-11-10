import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_ramp_editing_session.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_surface_editing_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_ramp_fixture.dart';

MapData _surfaceMap() => MapData(
  id: 'map',
  name: 'Terrain',
  version: ProjectVersion.v9,
  size: const GridSize(width: 8, height: 8),
  spatialScene: MapSpatialScene(
    width: 8,
    depth: 8,
    levelHeight: .25,
    terrainSurfaces: SpatialTerrainSurfaceSet(
      surfaces: [
        SpatialTerrainSurface(
          id: 'hill',
          x: 1,
          z: 1,
          height: .5,
          footprints: [
            BorderGroundFootprint(
              points: [
                BorderGroundPoint(x: 0, z: 0),
                BorderGroundPoint(x: 2, z: 0),
                BorderGroundPoint(x: 2, z: 2),
                BorderGroundPoint(x: 0, z: 2),
              ],
            ),
          ],
        ),
      ],
    ),
  ),
);

void main() {
  test(
    'ramp draft parses French fractions, previews, commits once and undoes',
    () {
      final map = precisionRampMap();
      final document = rampDocument(map);
      final view = MapWorkspaceEditingState();
      final editing = SpatialRampEditingSession(document, view);
      addTearDown(editing.dispose);
      editing.edit(() {
        editing.x = '2,1875';
        editing.width = '3,5625';
      });
      editing.preview();
      expect(editing.error, isNull);
      expect(view.rampPreview!.updatedRamp.x, 2.1875);
      expect(view.rampPreview!.updatedRamp.width, 3.5625);
      expect(document.current, same(map));
      expect(document.canUndo, isFalse);
      editing.apply();
      expect(view.rampPreview, isNull);
      expect(document.undoCount, 1);
      expect(
        document.current.spatialScene!.navigation.ramps.last,
        map.spatialScene!.navigation.ramps.last,
      );
      document.restore(redo: false);
      expect(document.current, map);
    },
  );

  test(
    'ramp drafts reject NaN and a changed source without changing history',
    () {
      final document = rampDocument(precisionRampMap());
      final view = MapWorkspaceEditingState();
      final editing = SpatialRampEditingSession(document, view);
      addTearDown(editing.dispose);
      editing.x = 'NaN';
      editing.preview();
      expect(editing.error, contains('nombre fini'));
      expect(document.canUndo, isFalse);
      expect(view.rampPreview, isNull);
      editing.x = '2,1875';
      document.commit(document.current.copyWith(name: 'Concurrent'));
      final before = document.current;
      final history = document.undoCount;
      editing.preview();
      expect(editing.error, contains('carte a changé'));
      expect(document.current, same(before));
      expect(document.undoCount, history);
    },
  );

  test('disposing one ramp draft preserves another owner preview', () {
    final document = rampDocument(precisionRampMap());
    final view = MapWorkspaceEditingState();
    final first = SpatialRampEditingSession(document, view)..x = '2,1875';
    first.preview();
    final second = SpatialRampEditingSession(document, view)..x = '2,25';
    second.preview();
    final preview = view.rampPreview;
    expect(preview, isNotNull);
    first.dispose();
    expect(view.rampPreview, same(preview));
    second.dispose();
    expect(view.rampPreview, isNull);
  });

  test(
    'surface draft scales footprints and level gradients, then undoes once',
    () {
      final map = _surfaceMap();
      final document = rampDocument(map);
      final view = MapWorkspaceEditingState()..spatialSurfaceId = 'hill';
      final editing = SpatialTerrainSurfaceEditingSession(document, view);
      addTearDown(editing.dispose);
      expect(editing.values['height'], '2.0');
      editing.edit(
        () => editing.values.addAll({
          'width': '3,5',
          'height': '3',
          'rise-x': '0,5',
        }),
      );
      editing.preview();
      expect(editing.error, isNull);
      final preview = view.terrainSurfacePreview!;
      expect(preview.surface.bounds.right - preview.surface.bounds.left, 3.5);
      expect(preview.surface.height, .75);
      expect(preview.surface.gradientX, .125);
      expect(document.current, same(map));
      editing.apply();
      expect(document.current, preview.result);
      expect(document.undoCount, 1);
      expect(view.terrainSurfacePreview, isNull);
      document.restore(redo: false);
      expect(document.current, map);
    },
  );

  test('surface draft rejects invalid dimensions and changed source', () {
    final document = rampDocument(_surfaceMap());
    final view = MapWorkspaceEditingState()..spatialSurfaceId = 'hill';
    final editing = SpatialTerrainSurfaceEditingSession(document, view);
    addTearDown(editing.dispose);
    editing.values['width'] = '0';
    editing.preview();
    expect(editing.error, contains('strictement positives'));
    expect(document.canUndo, isFalse);
    editing.values['width'] = '3';
    document.commit(document.current.copyWith(name: 'Concurrent'));
    final map = document.current;
    editing.preview();
    expect(editing.error, contains('carte a changé'));
    expect(document.current, same(map));
    expect(document.undoCount, 1);
  });

  test('surface deletion is one undo and clears only its owned preview', () {
    final map = _surfaceMap();
    final document = rampDocument(map);
    final view = MapWorkspaceEditingState()..spatialSurfaceId = 'hill';
    final editing = SpatialTerrainSurfaceEditingSession(document, view);
    addTearDown(editing.dispose);
    editing.preview();
    editing.delete();
    expect(editing.error, isNull);
    expect(document.current.spatialScene!.terrainSurfaces.surfaces, isEmpty);
    expect(view.spatialSurfaceId, isNull);
    expect(view.terrainSurfacePreview, isNull);
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current, map);
  });
  test('a ramp session cannot publish another session preview', () {
    final map = precisionRampMap();
    final document = rampDocument(map);
    final view = MapWorkspaceEditingState();
    final first = SpatialRampEditingSession(document, view)..x = '2,1875';
    final second = SpatialRampEditingSession(document, view)..x = '2,25';
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    first.preview();
    second.preview();
    final secondPreview = view.rampPreview;
    first.apply();
    expect(document.current, same(map));
    expect(document.canUndo, isFalse);
    expect(view.rampPreview, same(secondPreview));
  });

  test('a surface session cannot publish another session preview', () {
    final map = _surfaceMap();
    final document = rampDocument(map);
    final view = MapWorkspaceEditingState()..spatialSurfaceId = 'hill';
    final first = SpatialTerrainSurfaceEditingSession(document, view);
    final second = SpatialTerrainSurfaceEditingSession(document, view);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    first.values['x'] = '1,5';
    first.preview();
    second.values['x'] = '2';
    second.preview();
    final secondPreview = view.terrainSurfacePreview;
    first.apply();
    expect(document.current, same(map));
    expect(document.canUndo, isFalse);
    expect(view.terrainSurfacePreview, same(secondPreview));
  });

  test(
    'surface deletion rejects a concurrent replacement with the same id',
    () {
      final document = rampDocument(_surfaceMap());
      final view = MapWorkspaceEditingState()..spatialSurfaceId = 'hill';
      final editing = SpatialTerrainSurfaceEditingSession(document, view);
      addTearDown(editing.dispose);
      final scene = document.current.spatialScene!;
      document.commit(
        document.current.copyWith(
          spatialScene: scene.copyWith(
            terrainSurfaces: SpatialTerrainSurfaceSet(
              surfaces: [
                scene.terrainSurfaces.surfaces.single.copyWith(height: 1),
              ],
            ),
          ),
        ),
      );
      final concurrent = document.current;
      editing.delete();
      expect(document.current, same(concurrent));
      expect(document.undoCount, 1);
      expect(
        document.current.spatialScene!.terrainSurfaces.surfaces.single.height,
        1,
      );
    },
  );

  test('a disposed surface session cannot delete its former target', () {
    final map = _surfaceMap();
    final document = rampDocument(map);
    final view = MapWorkspaceEditingState()..spatialSurfaceId = 'hill';
    final editing = SpatialTerrainSurfaceEditingSession(document, view);
    editing.dispose();
    editing.delete();
    expect(document.current, same(map));
    expect(document.canUndo, isFalse);
  });
  test('project dependency refresh disarms only its preview and retains ramp fields', () {
    final map = precisionRampMap(instances: false);
    final document = rampDocument(map);
    final view = MapWorkspaceEditingState();
    final project = ProjectManifest(name: 'Initial', maps: [], tilesets: []);
    final editing = SpatialRampEditingSession(document, view, project: project);
    addTearDown(editing.dispose);
    editing.x = '2,1875';
    editing.preview();
    expect(view.rampPreview, isNotNull, reason: editing.error);
    final renamed = project.copyWith(name: 'Renamed');
    editing.updateProject(renamed);
    expect(editing.project, same(renamed));
    expect(editing.x, '2,1875');
    expect(view.rampPreview, isNull);
    expect(document.current, same(map));
    expect(document.canUndo, isFalse);
  });
}
