import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_layer_grouping.dart';

/// The layer panel must read the same way on every map: first row = frontmost.
///
/// A legacy map carrying `tileLayerOrder: bottom_to_top` paints its serialized
/// list in array order, so `map.layers.first` is the *back* of the stack. The
/// panel used to list that layer first, which made "move up" push a layer
/// behind and put a newly appended layer at the bottom of a list while it
/// rendered on top of everything.
void main() {
  const service = MapLayerGroupService();

  group('bottom-to-top map', () {
    test('lists the frontmost layer first', () {
      final groups = service.groupsTopFirst(_bottomToTopMap());

      expect(
        groups.map((group) => group.primaryLayer.id),
        <String>['front', 'middle', 'back'],
      );
    });

    test('moving up brings a layer closer to the front', () {
      final moved = service.moveAdjacent(
        map: _bottomToTopMap(),
        layerId: 'middle',
        direction: MapLayerGroupMoveDirection.up,
      );

      // Painted in array order, so the frontmost layer is serialized last.
      expect(
        moved.layers.map((layer) => layer.id),
        <String>['back', 'front', 'middle'],
      );
      expect(
        service.groupsTopFirst(moved).map((group) => group.primaryLayer.id),
        <String>['middle', 'front', 'back'],
      );
    });

    test('a reorder round-trip preserves every layer exactly once', () {
      final moved = service.moveAdjacent(
        map: _bottomToTopMap(),
        layerId: 'back',
        direction: MapLayerGroupMoveDirection.up,
      );

      expect(moved.layers.length, 3);
      expect(
        moved.layers.map((layer) => layer.id).toSet(),
        <String>{'back', 'middle', 'front'},
      );
    });
  });

  group('canonical map', () {
    test('keeps listing the serialized order, which is already front-first',
        () {
      final groups = service.groupsTopFirst(_canonicalMap());

      expect(
        groups.map((group) => group.primaryLayer.id),
        <String>['front', 'middle', 'back'],
      );
    });
  });
}

/// Serialized back-to-front: `layers.first` renders behind everything.
MapData _bottomToTopMap() => MapData(
      id: 'village',
      name: 'Village',
      version: ProjectVersion.v6,
      size: const GridSize(width: 1, height: 1),
      properties: const <String, Object?>{'tileLayerOrder': 'bottom_to_top'},
      layers: <MapLayer>[_layer('back'), _layer('middle'), _layer('front')],
    );

/// Canonical maps serialize front-first already.
MapData _canonicalMap() => MapData(
      id: 'room',
      name: 'Room',
      version: ProjectVersion.v6,
      size: const GridSize(width: 1, height: 1),
      visualStack: MapVisualStackConfig(
        semanticsVersion: MapVisualStackConfig.canonicalSemanticsVersion,
      ),
      layers: <MapLayer>[_layer('front'), _layer('middle'), _layer('back')],
    );

TileLayer _layer(String id) => TileLayer(
      id: id,
      name: id,
      palette: const <TileLayerPaletteEntry>[],
      cells: const <int>[0],
    );
