import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core.dart';

void main() {
  const element = ProjectElementEntry(
    id: 'tree',
    name: 'Arbre',
    tilesetId: 'atlas',
    categoryId: 'nature',
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
      ),
    ],
  );
  final project = ProjectManifest(
    name: 'Test',
    maps: [],
    tilesets: [],
    elements: [element],
  );
  final initial = MapData(
    id: 'map',
    name: 'Carte',
    size: const GridSize(width: 4, height: 4),
    visualStack: MapVisualStackConfig.canonicalV1,
    properties: const {
      'custom': {'nested': 'kept'},
    },
    layers: [
      TileLayer(id: 'decor', name: 'Décors', cells: List.filled(16, 0)),
      CollisionLayer(
        id: 'collision',
        name: 'Collisions',
        collisions: List.filled(16, false),
      ),
    ],
    entities: const [
      MapEntity(
        id: 'event-anchor',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 3, y: 3),
        properties: {'script': 'keep'},
      ),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'a',
        layerId: 'decor',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 0),
        opacity: 0.7,
        applyCollision: false,
        properties: {'quest': 'kept'},
      ),
      MapPlacedElement(
        id: 'b',
        layerId: 'decor',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 0),
        quarterTurns: 1,
      ),
    ],
  );
  late EditableMapDocument document;
  late MapEditingCommands commands;
  setUp(() {
    document = EditableMapDocument(
      MapWorkspaceDocument(map: initial, revision: 'base', mapId: 'map'),
    );
    commands = MapEditingCommands(document, project);
  });

  test('selection and inspection never create dirty state or history', () {
    document.selectedId = 'a';
    document.stackPosition = const GridPos(x: 1, y: 1);
    expect(commands.stack(document.stackPosition!).map((e) => e.id), [
      'b',
      'a',
    ]);
    expect(document.selected!.properties, {'quest': 'kept'});
    expect(document.dirty, isFalse);
    expect(document.canUndo, isFalse);
  });

  test('move changes only position and out of bounds movement is ignored', () {
    commands.move('a', const GridPos(x: 2, y: 2));
    final moved = document.current;
    expect(
      moved.placedElements.first,
      initial.placedElements.first.copyWith(pos: const GridPos(x: 2, y: 2)),
    );
    expect(moved.placedElements.last, initial.placedElements.last);
    expect(moved.layers, initial.layers);
    expect(moved.entities, initial.entities);
    expect(moved.properties, initial.properties);
    commands.move('a', const GridPos(x: 3, y: 3));
    expect(document.current, same(moved));
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current, initial);
    expect(document.dirty, isFalse);
    document.restore(redo: true);
    expect(document.current, moved);
  });

  test('reorder undo redo keeps list priority and every non-order field', () {
    document.selectedId = 'a';
    document.stackPosition = const GridPos(x: 1, y: 1);
    expect(commands.canReorder(forward: true), isTrue);
    expect(commands.canReorder(forward: false), isFalse);
    expect(document.dirty, isFalse);
    commands.reorder(forward: true);
    expect(commands.canReorder(forward: true), isFalse);
    expect(commands.canReorder(forward: false), isTrue);
    final reordered = document.current;
    expect(commands.stack(document.stackPosition!).map((e) => e.id), [
      'a',
      'b',
    ]);
    expect(reordered.placedElements.map((e) => e.id), ['a', 'b']);
    for (var index = 0; index < initial.placedElements.length; index++) {
      expect(
        reordered.placedElements[index].toJson()..remove('visualOrder'),
        initial.placedElements[index].toJson()..remove('visualOrder'),
      );
    }
    expect(reordered.copyWith(placedElements: initial.placedElements), initial);
    document.restore(redo: false);
    expect(document.current, initial);
    document.restore(redo: true);
    expect(document.current, reordered);
  });

  test(
    'delete targets selection and undo restores exact decoration metadata',
    () {
      document.selectedId = 'a';
      commands.deleteSelected();
      expect(document.current.placedElements, [initial.placedElements.last]);
      expect(document.selectedId, isNull);
      expect(document.current.entities, initial.entities);
      document.restore(redo: false);
      expect(document.current, initial);
      document.restore(redo: true);
      expect(document.current.placedElements, [initial.placedElements.last]);
    },
  );

  test(
    'place validates footprint and one undo removes only the new instance',
    () {
      commands.place(element, const GridPos(x: 3, y: 3));
      expect(document.current, initial);
      expect(document.canUndo, isFalse);
      commands.place(element, const GridPos(x: 2, y: 2));
      final placed = document.current;
      expect(placed.placedElements.length, 3);
      expect(placed.placedElements.take(2), initial.placedElements);
      expect(document.selected!.elementId, 'tree');
      expect(document.selected!.pos, const GridPos(x: 2, y: 2));
      expect(document.undoCount, 1);
      document.restore(redo: false);
      expect(document.current, initial);
      document.restore(redo: true);
      expect(document.current, placed);
    },
  );

  test(
    'one buffered stroke is one undo and interrupted stroke stays clean',
    () {
      const tile = TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 7);
      final stroke = MapCellStrokeBuffer.tile(
        sourceMap: document.current,
        layerId: 'decor',
      );
      for (var x = 0; x < 4; x++) {
        stroke.paintTiles(
          origin: GridPos(x: x, y: 2),
          patternSize: const GridSize(width: 1, height: 1),
          tiles: const [tile],
        );
      }
      expect(document.current, initial);
      expect(document.dirty, isFalse);
      document.commit(
        stroke.commit(
          validate: (context) => MapValidator.validate(context.after),
        ),
      );
      final painted = document.current;
      expect(document.undoCount, 1);
      expect(
        (painted.layers.first as TileLayer).cells.sublist(8, 12),
        everyElement(1),
      );
      expect(painted.placedElements, initial.placedElements);
      expect(painted.layers.last, initial.layers.last);
      document.restore(redo: false);
      expect(document.current, initial);
      document.restore(redo: true);
      expect(document.current, painted);
    },
  );

  test(
    'new edits after undo discard redo and saved equality governs dirty',
    () {
      final changed = initial.copyWith(name: 'Saved');
      document.commit(changed);
      document.acceptSave(changed, 'next');
      expect(document.dirty, isFalse);
      document.restore(redo: false);
      expect(document.dirty, isTrue);
      document.restore(redo: true);
      expect(document.dirty, isFalse);
      document.restore(redo: false);
      document.commit(initial.copyWith(name: 'New branch'));
      expect(document.canRedo, isFalse);
      expect(document.dirty, isTrue);
      expect(document.base.revision, 'next');
    },
  );
}
