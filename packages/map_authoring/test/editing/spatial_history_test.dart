import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('Smart Tile spatial gestures keep one undo boundary across reopen', () {
    final before = MapData(
        id: 'world',
        name: 'World',
        version: ProjectVersion.v9,
        size: const GridSize(width: 2, height: 2),
        spatialScene: MapSpatialScene(width: 2, depth: 2),
        layers: const [
          MapLayer.smartTile(
              id: 'ground',
              name: 'Ground',
              presetId: 'grass',
              usage: SmartTileUsage.terrain,
              materialPalette: ['', 'grass'],
              field: SmartTileField.cell(semanticCells: [0, 0, 0, 0]))
        ]);
    final after = replaceSmartTileLayer(before,
        layer: applySmartTileMaterialGesture(
            before.layers.single as SmartTileLayer,
            mapSize: before.size,
            cells: const [GridPos(x: 0, y: 0), GridPos(x: 1, y: 1)],
            materialId: 'grass'));
    final delta = MapHistoryDelta.between(before, after);
    final reopened = MapData.fromJson(after.toJson());
    expect(delta.applyBackward(reopened), before);
    expect(delta.applyForward(MapData.fromJson(before.toJson())), after);
    expect(after.spatialScene, before.spatialScene);
  });
  test('spatial history preserves terrain, camera and instances across reopen',
      () {
    final before = MapData(
        id: 'world',
        name: 'World',
        size: const GridSize(width: 3, height: 3),
        version: ProjectVersion.v9,
        spatialScene: MapSpatialScene(width: 3, depth: 3),
        layers: const [],
        tilesetId: '');
    final after = before.copyWith(
        spatialScene: before.spatialScene!.copyWith(
            heightLevels: [2, 0, 0, 0, 0, 0, 0, 0, 0],
            camera: SpatialCameraProfile(distance: 50),
            navigation: SpatialNavigationProfile(
                spawn: SpatialSpawn(x: 1, z: 2), allowDiagonalMovement: true),
            instances: [
              SpatialModelInstance(
                  id: 'tree1',
                  modelId: 'tree',
                  position: Model3dVector3(x: 1, y: 2, z: 1))
            ]));
    final delta = MapHistoryDelta.between(before, after);
    expect(delta.isEmpty, isFalse);
    expect(delta.retainedBytes, greaterThan(64));
    expect(delta.applyForward(MapData.fromJson(before.toJson())), after);
    expect(delta.applyBackward(MapData.fromJson(after.toJson())), before);
    expect(
        MapHistoryDelta.between(after, MapData.fromJson(after.toJson()))
            .isEmpty,
        isTrue);
  });
}
