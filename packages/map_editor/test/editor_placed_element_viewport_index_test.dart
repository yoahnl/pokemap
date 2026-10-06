import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/editor_placed_element_viewport_index.dart';

void main() {
  test('culls decor by its visual bounds and preserves authored order', () {
    final map = _map([
      _placed('far', x: 80, y: 80),
      _placed('wide', x: 0, y: 0, elementId: 'wide'),
      _placed('near', x: 1, y: 1),
    ]);
    final index = EditorPlacedElementViewportIndex(
      manifest: _project,
      map: map,
    );

    expect(index.elementsIn(_viewport).map((element) => element.id), [
      'wide',
      'near',
    ]);
    expect(
      index
          .elementsIn(
            const EditorPlacedElementCellViewport(
              left: 4,
              top: 0,
              right: 5,
              bottom: 1,
            ),
          )
          .map((element) => element.id),
      ['wide'],
    );
    expect(
      index.elementsIn(
        const EditorPlacedElementCellViewport(
          left: 0,
          top: 0,
          right: 0,
          bottom: 2,
        ),
      ),
      isEmpty,
    );
  });

  test(
    'large decor uses bounded global candidates without filling buckets',
    () {
      final map = _map([
        _placed('large', x: 0, y: 0, elementId: 'large'),
        _placed('far', x: 80, y: 80),
      ]);
      final index = EditorPlacedElementViewportIndex(
        manifest: _project,
        map: map,
      );

      expect(index.debugGlobalCandidateCount, 1);
      expect(index.debugIndexedCellCount, 1);
      expect(index.elementsIn(_viewport).map((element) => element.id), [
        'large',
      ]);
      expect(
        index.elementsIn(
          const EditorPlacedElementCellViewport(
            left: 60,
            top: 60,
            right: 62,
            bottom: 62,
          ),
        ),
        isEmpty,
      );
    },
  );

  test('cached index follows immutable map and project revisions', () {
    final owner = EditorPlacedElementViewportIndexOwner();
    final map = _map([_placed('near', x: 1, y: 1)]);
    final first = owner.indexFor(manifest: _project, map: map);

    expect(owner.indexFor(manifest: _project, map: map), same(first));
    final movedMap = map.copyWith(
      placedElements: [
        map.placedElements.single.copyWith(pos: const GridPos(x: 80, y: 80)),
      ],
    );
    final moved = owner.indexFor(manifest: _project, map: movedMap);
    expect(moved, isNot(same(first)));
    expect(moved.elementsIn(_viewport), isEmpty);
    expect(first.elementsIn(_viewport).single.id, 'near');

    final changedProject = _project.copyWith(name: 'Revised');
    final revised = owner.indexFor(manifest: changedProject, map: movedMap);
    expect(revised, isNot(same(moved)));
    owner.clear();
    expect(
      owner.indexFor(manifest: changedProject, map: movedMap),
      isNot(same(revised)),
    );
  });
}

const _viewport = EditorPlacedElementCellViewport(
  left: 0,
  top: 0,
  right: 2,
  bottom: 2,
);

MapPlacedElement _placed(
  String id, {
  required int x,
  required int y,
  String elementId = 'small',
}) => MapPlacedElement(
  id: id,
  elementId: elementId,
  layerId: 'decor',
  pos: GridPos(x: x, y: y),
);

MapData _map(List<MapPlacedElement> elements) => MapData(
  id: 'map',
  name: 'Map',
  size: const GridSize(width: 100, height: 100),
  layers: [
    TileLayer(id: 'decor', name: 'Decor', cells: List<int>.filled(10000, 0)),
  ],
  placedElements: elements,
);

final _project = ProjectManifest(
  name: 'Project',
  maps: const [],
  tilesets: const [
    ProjectTilesetEntry(id: 'tiles', name: 'Tiles', relativePath: 'tiles.png'),
  ],
  settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
  elements: [
    for (final (id, width, height) in [
      ('small', 1, 1),
      ('wide', 5, 1),
      ('large', 32, 32),
    ])
      ProjectElementEntry(
        id: id,
        name: id,
        tilesetId: 'tiles',
        categoryId: 'decor',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: width, height: height),
          ),
        ],
      ),
  ],
);
