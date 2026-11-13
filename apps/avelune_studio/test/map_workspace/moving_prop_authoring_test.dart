import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('open prop stays visible and dragging translates the complete rail with undo', () {
    final map = _map(withProps: true);
    final open = MovingPropDefinition.fromJson({
      ...map.movingProps.first.toJson(),
      'initialState': 'open',
    });
    final authored = const MovingPropEditing().upsert(
      map: map,
      project: _project(),
      prop: open,
    );
    expect(authored.placedElements.first.pos, const GridPos(x: 3, y: 2));
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: authored, mapId: authored.id, revision: 'open'),
    );
    final commands = MapEditingCommands(document, _project());
    commands.move('visual', const GridPos(x: 5, y: 3));
    final dragged = document.current;
    expect(
      dragged.movingProps
          .singleWhere((prop) => prop.id == 'gate')
          .closedPositionPx,
      const PixelOffset(x: 128, y: 96),
    );
    expect(
      dragged.movingProps
          .singleWhere((prop) => prop.id == 'gate')
          .openPositionPx,
      const PixelOffset(x: 160, y: 96),
    );
    expect(dragged.placedElements.first.pos, const GridPos(x: 5, y: 3));
    expect(commands.setGeometry('visual', x: 192, y: 96, size: null), isTrue);
    expect(
      document.current.movingProps
          .singleWhere((prop) => prop.id == 'gate')
          .closedPositionPx,
      const PixelOffset(x: 160, y: 96),
    );
    expect(
      document.current.movingProps
          .singleWhere((prop) => prop.id == 'gate')
          .openPositionPx,
      const PixelOffset(x: 192, y: 96),
    );
    document.restore(redo: false);
    expect(document.current, dragged);
    expect(commands.setGeometry('visual', x: 0, y: 96, size: null), isFalse);
    expect(document.current, dragged);
    document.restore(redo: false);
    expect(document.current, authored);
  });

}

ProjectManifest _project() => const ProjectManifest(
  name: 'Props',
  maps: [ProjectMapEntry(id: 'hall', name: 'Hall', relativePath: 'hall.json')],
  settings: ProjectSettings(tileWidth: 32, tileHeight: 32),
  tilesets: [],
  elements: [
    ProjectElementEntry(
      id: 'gate-art',
      name: 'Grille',
      tilesetId: 'tiles',
      categoryId: 'decor',
      frames: [
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        ),
      ],
    ),
  ],
);

MapData _map({bool withProps = false}) => MapData(
  id: 'hall',
  name: 'Hall',
  size: const GridSize(width: 10, height: 10),
  placedElements: const [
    MapPlacedElement(
      id: 'visual',
      elementId: 'gate-art',
      layerId: 'art',
      pos: GridPos(x: 2, y: 2),
      properties: {
        pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
      },
    ),
    MapPlacedElement(
      id: 'visual-two',
      elementId: 'gate-art',
      layerId: 'art',
      pos: GridPos(x: 4, y: 2),
      properties: {
        pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
      },
    ),
  ],
  movingProps: [
    if (withProps)
      for (final (id, visual, x) in [
        ('gate', 'visual', 64),
        ('gate-two', 'visual-two', 128),
      ])
        MovingPropDefinition(
          id: id,
          placedElementId: visual,
          closedPositionPx: PixelOffset(x: x, y: 64),
          openPositionPx: PixelOffset(x: x + 32, y: 64),
          collisionRect: const PixelRect(
            leftPx: 0,
            topPx: 0,
            widthPx: 32,
            heightPx: 32,
          ),
        ),
  ],
);
