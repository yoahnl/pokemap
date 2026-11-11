import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

const _at = GridPos(x: 4, y: 4);

void main() {
  test('selected context falls back to its placement and partitions layers without editing', () {
    final document = _document()..selectedId = 'top';
    final commands = MapEditingCommands(document, workspaceProject);
    final before = document.current;
    final history = document.undoToken;
    final order = commands.decorOrderContext()!;

    expect(order.instanceId, 'top');
    expect(order.position, _at);
    expect(order.pixelPosition, isNull);
    expect(order.target, document.selected);
    expect(order.reorderable.map((element) => element.id), ['top', 'bottom']);
    expect(order.other.map((element) => element.id), ['upper']);
    expect(order.rank, 0);
    expect(order.forwardProblem, contains('déjà devant'));
    expect(order.backwardProblem, isNull);
    expect(() => order.reorderable.clear(), throwsUnsupportedError);
    expect(document.current, same(before));
    expect(document.undoToken, history);
    expect(document.selectedId, 'top');
  });

  test('the context menu uses its explicit target rather than the current selection', () {
    final document = _document()..selectedId = 'elsewhere';
    final commands = MapEditingCommands(document, workspaceProject);
    final order = commands.decorOrderContext(instanceId: 'bottom', at: _at)!;
    final context = MapContextActionContext(
      document: document,
      project: workspaceProject,
      position: _at,
    );
    final target = mapContextTargetsAt(
      document,
      workspaceProject,
      _at,
    ).singleWhere((target) => target.id == 'bottom');
    final actions = mapContextActionsFor(target, context);
    expect(order.rank, 1);
    expect(order.forwardProblem, isNull);
    expect(order.backwardProblem, contains('déjà derrière'));
    expect(
      actions
          .singleWhere(
            (action) => action.command == MapContextCommand.bringForward,
          )
          .unavailable,
      order.forwardProblem,
    );
    expect(
      actions
          .singleWhere(
            (action) => action.command == MapContextCommand.sendBackward,
          )
          .unavailable,
      order.backwardProblem,
    );
    final before = document.current;
    final history = document.undoCount;
    expect(
      MapContextCommandRunner(context)
          .run(MapContextCommand.bringForward, target),
      isNull,
    );
    final reordered = commands.decorOrderContext(
      instanceId: 'bottom',
      at: _at,
    )!;
    expect(reordered.reorderable.map((element) => element.id), [
      'bottom',
      'top',
    ]);
    expect(document.undoCount, history + 1);
    expect(
      document.current.placedElements.singleWhere(
        (element) => element.id == 'upper',
      ),
      before.placedElements.singleWhere((element) => element.id == 'upper'),
    );
    document.restore(redo: false);
    expect(document.current, before);
    document.restore(redo: true);
    expect(commands.decorOrderContext(instanceId: 'bottom', at: _at)!.rank, 0);
    final reopened = MapData.fromJson(document.current.toJson());
    expect(reopened, document.current);
  });

  test('pixel context only includes placements covering the exact pixel', () {
    final document =
        _document(
            elements: const [
              MapPlacedElement(
                id: 'left',
                layerId: 'ground',
                elementId: 'tree',
                pos: _at,
                pixelSize: PixelSize(width: 8, height: 16),
                visualOrder: 1,
                properties: {
                  pokemapPlacementOriginProperty:
                      pokemapPlacementOriginAuthored,
                },
              ),
              MapPlacedElement(
                id: 'right',
                layerId: 'ground',
                elementId: 'tree',
                pos: _at,
                pixelOffset: PixelOffset(x: 8, y: 0),
                pixelSize: PixelSize(width: 8, height: 16),
                visualOrder: 2,
                properties: {
                  pokemapPlacementOriginProperty:
                      pokemapPlacementOriginAuthored,
                },
              ),
            ],
          )
          ..selectedId = 'left'
          ..stackPosition = _at
          ..stackPixelPosition = const PixelPosition(leftPx: 68, topPx: 68);
    final commands = MapEditingCommands(document, workspaceProject);
    final pixel = commands.decorOrderContext()!;
    expect(pixel.pixelPosition, document.stackPixelPosition);
    expect(pixel.reorderable.map((element) => element.id), ['left']);
    expect(pixel.forwardProblem, isNotNull);
    expect(pixel.backwardProblem, isNotNull);
    final before = document.current;
    commands.reorderAt(instanceId: 'left', at: _at, forward: true);
    expect(document.current, same(before));
    expect(document.undoCount, 0);

    document.stackPixelPosition = null;
    final cell = commands.decorOrderContext()!;
    expect(cell.pixelPosition, isNull);
    expect(cell.reorderable.map((element) => element.id), ['right', 'left']);
    expect(cell.forwardProblem, isNull);
    commands.reorderAt(instanceId: 'left', at: _at, forward: true);
    expect(commands.decorOrderContext()!.rank, 0);
    expect(document.undoCount, 1);
  });

  test('a pixel belonging to a previous anchor does not replace the requested cell', () {
    final document = _document()
      ..selectedId = 'top'
      ..stackPosition = const GridPos(x: 10, y: 10)
      ..stackPixelPosition = const PixelPosition(leftPx: 160, topPx: 160);
    final order = MapEditingCommands(
      document,
      workspaceProject,
    ).decorOrderContext(instanceId: 'top', at: _at)!;
    expect(order.pixelPosition, isNull);
    expect(order.reorderable.map((element) => element.id), ['top', 'bottom']);
    expect(order.backwardProblem, isNull);
  });

  test('missing selection and missing targets are refused without editing', () {
    final document = _document();
    final commands = MapEditingCommands(document, workspaceProject);
    final before = document.current;
    expect(commands.decorOrderContext(), isNull);
    final missing = commands.decorOrderContext(instanceId: 'missing', at: _at)!;
    expect(missing.target, isNull);
    expect(missing.rank, -1);
    expect(missing.reorderable, isEmpty);
    expect(missing.forwardProblem, 'Ce décor n’est plus sur la carte.');
    expect(missing.backwardProblem, missing.forwardProblem);
    commands.reorderAt(instanceId: 'missing', at: _at, forward: true);
    expect(document.current, same(before));
    expect(document.undoCount, 0);
  });

  test('a target outside the requested cell cannot reorder that stack', () {
    final document = _document();
    final commands = MapEditingCommands(document, workspaceProject);
    final before = document.current;
    final order = commands.decorOrderContext(instanceId: 'elsewhere', at: _at)!;
    expect(order.rank, -1);
    expect(order.forwardProblem, 'Ce décor n’occupe plus cet emplacement.');
    expect(order.backwardProblem, order.forwardProblem);
    commands.reorderAt(instanceId: 'elsewhere', at: _at, forward: true);
    expect(document.current, same(before));
    expect(document.undoCount, 0);
  });

  test('hidden and locked placements retain the existing ordering guards', () {
    final document = _document()..selectedId = 'bottom';
    final editor = MapEditorController(
      session: workspaceSession,
      mapId: document.current.id,
      port: _NoEditorPort(),
      state: MapEditorWorkspaceState(
        state: MapEditorState(
          lockedElements: {'decor:bottom'},
          hiddenElements: {'layer:upper'},
        ),
        revision: 'editor-base',
      ),
    );
    document.editor = editor;
    addTearDown(editor.dispose);
    final before = document.current;
    final commands = MapEditingCommands(document, workspaceProject);
    final order = commands.decorOrderContext()!;
    expect(order.reorderable.map((element) => element.id), ['top']);
    expect(order.other, isEmpty);
    expect(order.rank, -1);
    expect(order.forwardProblem, isNotNull);
    expect(order.backwardProblem, isNotNull);
    commands.reorderAt(instanceId: 'bottom', at: _at, forward: true);
    expect(document.current, same(before));
    expect(document.undoCount, 0);
  });
}

EditableMapDocument _document({List<MapPlacedElement>? elements}) {
  final base = workspaceMap('a');
  final map = base.copyWith(
    layers: [
      ...base.layers,
      TileLayer(id: 'upper', name: 'Upper', cells: List.filled(320, 0)),
    ],
    placedElements:
        elements ??
        const [
          MapPlacedElement(
            id: 'bottom',
            layerId: 'ground',
            elementId: 'tree',
            pos: _at,
            visualOrder: 1,
          ),
          MapPlacedElement(
            id: 'top',
            layerId: 'ground',
            elementId: 'tree',
            pos: _at,
            visualOrder: 2,
          ),
          MapPlacedElement(
            id: 'upper',
            layerId: 'upper',
            elementId: 'tree',
            pos: _at,
            visualOrder: 3,
          ),
          MapPlacedElement(
            id: 'elsewhere',
            layerId: 'ground',
            elementId: 'tree',
            pos: GridPos(x: 10, y: 10),
            visualOrder: 4,
          ),
        ],
  );
  return EditableMapDocument(
    MapWorkspaceDocument(map: map, revision: 'base', mapId: map.id),
  );
}

final class _NoEditorPort extends Fake implements MapEditorPort {}
