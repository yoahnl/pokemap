import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('changing visual depth preserves actual first-winner interaction', () {
    final manifest = ProjectManifest(
        name: 'Order',
        maps: const [],
        tilesets: const [],
        elements: const [
          ProjectElementEntry(
              id: 'prop',
              name: 'Prop',
              tilesetId: 'ts',
              categoryId: 'cat',
              frames: [
                TilesetVisualFrame(
                    source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1))
              ])
        ]);
    final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 3, height: 3),
        placedElements: [
          for (final id in ['first', 'second'])
            MapPlacedElement(
                id: id,
                layerId: 'decor',
                elementId: 'prop',
                pos: const GridPos(x: 1, y: 1),
                behaviors: [
                  MapPlacedElementBehavior(
                      id: '$id-action',
                      effect: MapPlacedElementEffect(
                          type: MapPlacedElementEffectType.showMessage,
                          message: id))
                ])
        ]);
    final moved = moveMapPlacedElementVisualOrder(map,
        manifest: manifest, instanceId: 'first', forward: true);
    expect(sortMapPlacedElementsForPainting(moved.placedElements).last.id,
        'first');
    for (final current in [map, moved, MapData.fromJson(moved.toJson())]) {
      final world = GameplayWorldState.initial(
          map: current,
          project: manifest,
          playerPos: const GridPos(x: 0, y: 0));
      final winner = world.placedElementBehaviorOnActionAt(1, 1)!;
      expect(winner.element.id, 'first');
      expect(winner.behavior.id, 'first-action');
    }
  });
}
