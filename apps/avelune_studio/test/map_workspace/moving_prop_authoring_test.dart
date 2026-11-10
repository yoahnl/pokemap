import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_moving_prop_commands.dart';
import 'package:avelune_studio/features/scenes/application/scene_action_draft.dart';
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

  test('selected decor configures a rail with undo and serialized reopen', () {
    final source = _map();
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: source, mapId: source.id, revision: 'test'),
    );
    final commands = MapMovingPropCommands(document, _project());
    final draft = MapMovingPropDraft.fromPlacement(
      source,
      _project(),
      'visual',
    );
    expect(commands.save('visual', draft), isNull);
    final prop = document.current.movingProps.single;
    expect(prop.placedElementId, 'visual');
    expect(prop.closedPositionPx, const PixelOffset(x: 64, y: 64));
    expect(prop.openPositionPx, const PixelOffset(x: 96, y: 64));
    expect(MapData.fromJson(document.current.toJson()).movingProps, [prop]);
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current, source);
  });

  test(
    'moving prop draft retains opening direction collision and initial state',
    () {
      final map = _map(withProps: true);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: map.id, revision: 'test'),
      );
      final commands = MapMovingPropCommands(document, _project());
      final draft = MapMovingPropDraft.fromPlacement(map, _project(), 'visual')
        ..direction = 'north'
        ..distance = '16'
        ..width = '16'
        ..height = '24'
        ..left = '4'
        ..top = '8'
        ..initialState = 'open';
      expect(commands.save('visual', draft), isNull);
      final reopened = MapData.fromJson(document.current.toJson());
      final changed = MapMovingPropDraft.fromPlacement(
        reopened,
        _project(),
        'visual',
      );
      expect(changed.direction, 'north');
      expect(changed.distance, '16');
      expect(changed.width, '16');
      expect(changed.height, '24');
      expect(changed.left, '4');
      expect(changed.top, '8');
      expect(changed.initialState, 'open');
      expect(reopened.movingProps.last.id, 'gate');
      expect(reopened.movingProps.first.id, 'gate-two');
    },
  );

  test('invalid rail input preserves current data and undo history', () {
    final map = _map();
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'test'),
    );
    final commands = MapMovingPropCommands(document, _project());
    final draft = MapMovingPropDraft.fromPlacement(map, _project(), 'visual');
    for (final invalid in ['0', '1025', '1.5', 'text']) {
      draft.distance = invalid;
      expect(commands.save('visual', draft), isNotNull);
    }
    expect(document.current, same(map));
    expect(document.canUndo, isFalse);
    draft.distance = '32';
    expect(commands.save('visual', draft), isNull);
    expect(commands.delete(document.current.movingProps.single.id), isNull);
    expect(document.current.movingProps, isEmpty);
    document.restore(redo: false);
    expect(document.current.movingProps, hasLength(1));
  });

  test(
    'scene draft selects synchronized props and rejects invalid duration',
    () async {
      final map = _map(withProps: true);
      final draft = SceneActionDraft(
        project: _project(),
        changed: () {},
        current: SceneActionPayload.interactive(
          SceneInteractiveCommand.setPropState(
            mapId: 'hall',
            propIds: ['gate'],
            state: MovingPropState.open,
          ),
        ),
        loadMap: (_) async => map,
      );
      addTearDown(draft.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(draft.movingProps.keys, containsAll(['gate', 'gate-two']));
      draft.changeParameter('propIds', '["gate","gate-two"]');
      draft.changeParameter('durationMs', '10001');
      expect(draft.valid, isFalse);
      draft.changeParameter('durationMs', '350');
      expect(draft.valid, isTrue);
      final command =
          (draft.buildPayload() as SceneActionPayload).interactiveCommand!
              as SceneSetPropStateInteractiveCommand;
      expect(command.propIds, ['gate', 'gate-two']);
      expect(command.durationMs, 350);
      expect(command.state, MovingPropState.open);
    },
  );

  test(
    'missing props remain in the draft and prevent scene publication',
    () async {
      final original = SceneActionPayload.interactive(
        SceneInteractiveCommand.setPropState(
          mapId: 'hall',
          propIds: ['removed'],
          state: MovingPropState.open,
        ),
      );
      final draft = SceneActionDraft(
        project: _project(),
        changed: () {},
        current: original,
        loadMap: (_) async => _map(withProps: true),
      );
      addTearDown(draft.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(draft.values['propIds'], '["removed"]');
      expect(draft.movingProps.containsKey('removed'), isFalse);
      expect(draft.valid, isFalse);
      expect(draft.current, same(original));
    },
  );
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
