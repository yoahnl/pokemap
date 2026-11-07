import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_decor_group_editing.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_elements_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_multi_selection_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

MapData _map() => workspaceMap('a').copyWith(
  placedElements: const [
    MapPlacedElement(
      id: 'bed',
      layerId: 'ground',
      elementId: 'tree',
      pos: GridPos(x: 2, y: 2),
    ),
    MapPlacedElement(
      id: 'desk',
      layerId: 'ground',
      elementId: 'tree',
      pos: GridPos(x: 5, y: 2),
    ),
    MapPlacedElement(
      id: 'lamp',
      layerId: 'ground',
      elementId: 'tree',
      pos: GridPos(x: 8, y: 2),
    ),
  ],
);

GridPos _pos(EditableMapDocument document, String id) =>
    document.current.placedElements.singleWhere((item) => item.id == id).pos;

void main() {
  late EditableMapDocument document;
  late MapEditorController editor;
  late MapWorkspaceViewState view;

  setUp(() async {
    document = EditableMapDocument(
      MapWorkspaceDocument(map: _map(), revision: 'base', mapId: 'a'),
    );
    editor = MapEditorController(
      session: workspaceSession,
      mapId: 'a',
      port: _MemoryEditorPort(),
      state: MapEditorWorkspaceState(
        state: MapEditorState(),
        revision: 'initial',
      ),
    );
    document.editor = editor;
    await editor.setLocked('decor', 'lamp', true);
    view = MapWorkspaceViewState();
  });
  tearDown(() {
    editor.dispose();
    view.dispose();
  });

  test('different X values make the field mixed, not arbitrary', () {
    final summary = MapDecorGroupEditing(
      document,
      workspaceProject,
    ).summarize(['bed', 'desk', 'lamp']);
    expect(summary.mixedX, isTrue);
    expect(summary.x, isNull);
    expect(summary.mixedY, isFalse);
    expect(summary.y, 2);
    expect(summary.editableIds, ['bed', 'desk']);
    expect(summary.lockedIds, ['lamp']);
  });

  test('a group move skips locked items and is one undo unit', () {
    final editing = MapDecorGroupEditing(document, workspaceProject);
    final before = document.undoCount;
    expect(editing.move(['bed', 'desk', 'lamp'], x: 9), isTrue);
    expect(_pos(document, 'bed'), const GridPos(x: 9, y: 2));
    expect(_pos(document, 'desk'), const GridPos(x: 9, y: 2));
    expect(_pos(document, 'lamp'), const GridPos(x: 8, y: 2));
    expect(document.undoCount, before + 1);
    document.restore(redo: false);
    expect(_pos(document, 'bed'), const GridPos(x: 2, y: 2));
    expect(_pos(document, 'desk'), const GridPos(x: 5, y: 2));
    expect(document.canRedo, isTrue);
    expect(editing.move(['bed'], y: 4), isTrue);
    expect(document.canRedo, isFalse);
  });

  test('a refused group move changes nothing and keeps history', () {
    final editing = MapDecorGroupEditing(document, workspaceProject);
    final before = document.current;
    final undo = document.undoCount;
    expect(editing.move(['bed', 'desk'], x: 500), isFalse);
    expect(document.current, same(before));
    expect(document.undoCount, undo);
    expect(document.error, isNotNull);
  });

  test('a group removal keeps locked items and undoes at once', () {
    final editing = MapDecorGroupEditing(document, workspaceProject);
    expect(editing.remove(['bed', 'lamp']), isTrue);
    expect(document.current.placedElements.map((item) => item.id), [
      'desk',
      'lamp',
    ]);
    document.restore(redo: false);
    expect(document.current.placedElements, hasLength(3));
  });

  test('replacing here changes only these occurrences, at once', () {
    const rock = ProjectElementEntry(
      id: 'rock',
      name: 'Rocher',
      tilesetId: 'atlas',
      categoryId: 'decor',
      frames: [
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 2, y: 0, width: 1, height: 1),
        ),
      ],
    );
    final project = workspaceProject.copyWith(
      elements: [workspaceElement, rock],
    );
    final editing = MapDecorGroupEditing(document, project);
    final undo = document.undoCount;
    expect(editing.replace(['bed', 'desk', 'lamp'], 'rock'), isTrue);
    final placed = {
      for (final item in document.current.placedElements) item.id: item,
    };
    expect(placed.keys, ['bed', 'desk', 'lamp']);
    expect(placed['bed']!.elementId, 'rock');
    expect(placed['desk']!.elementId, 'rock');
    expect(placed['lamp']!.elementId, 'tree');
    expect(placed['bed']!.pos, const GridPos(x: 2, y: 2));
    expect(placed['desk']!.pos, const GridPos(x: 5, y: 2));
    expect(project.elements, [workspaceElement, rock]);
    expect(document.undoCount, undo + 1);
    document.restore(redo: false);
    expect(document.current.placedElements.map((item) => item.elementId), [
      'tree',
      'tree',
      'tree',
    ]);
  });

  test('a replacement that no longer fits changes nothing', () {
    const wide = ProjectElementEntry(
      id: 'wide',
      name: 'Muraille',
      tilesetId: 'atlas',
      categoryId: 'decor',
      frames: [
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 19, height: 1),
        ),
      ],
    );
    final project = workspaceProject.copyWith(
      elements: [workspaceElement, wide],
    );
    final before = document.current;
    final undo = document.undoCount;
    expect(
      MapDecorGroupEditing(document, project).replace(['bed', 'desk'], 'wide'),
      isFalse,
    );
    expect(document.current, same(before));
    expect(document.undoCount, undo);
    expect(document.error, 'Ce décor dépasse les limites de la carte.');
  });

  test('replacing a 3D occurrence keeps its place and drops model clips', () {
    final statue = _model('statue');
    final lantern = _model('lantern');
    final project = spatialEnvironmentProject().copyWith(
      models3d: [statue, lantern],
    );
    final base = spatialEnvironmentMap();
    final spatial = EditableMapDocument(
      MapWorkspaceDocument(
        map: base.copyWith(
          spatialScene: MapSpatialScene(
            width: 12,
            depth: 10,
            instances: [
              SpatialModelInstance(
                id: 'model_1',
                modelId: 'statue',
                position: Model3dVector3(x: 3.5, y: 0, z: 4.5),
                rotationDegrees: 90,
                scale: 2,
                animationIndex: 1,
                blocksMovement: false,
              ),
            ],
          ),
        ),
        revision: 'base',
        mapId: 'a',
      ),
    );
    expect(
      MapDecorGroupEditing(spatial, project).replace(['model_1'], 'lantern'),
      isTrue,
    );
    final instance = spatial.current.spatialScene!.instances.single;
    expect(instance.id, 'model_1');
    expect(instance.modelId, 'lantern');
    expect(instance.position.x, 3.5);
    expect(instance.position.z, 4.5);
    expect(instance.rotationDegrees, 90);
    expect(instance.scale, 2);
    expect(instance.blocksMovement, isFalse);
    expect(instance.animationIndex, isNull);
    expect(project.models3d, [statue, lantern]);
  });

  test('changing map drops a stale multiple selection', () {
    view.select(document, MapSelectionFamily.decor, 'bed');
    view.toggleDecorInSelection(document, 'desk');
    expect(view.selectedDecorIds('a'), {'bed', 'desk'});
    final other = EditableMapDocument(
      MapWorkspaceDocument(map: workspaceMap('b'), revision: 'r', mapId: 'b'),
    );
    view.select(other, MapSelectionFamily.decor, 'tree-b');
    expect(view.selectedDecorIds('a'), isEmpty);
    expect(view.selectedDecorIds('b'), {'tree-b'});
  });

  testWidgets('shift-click builds a selection that the inspector edits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Row(
              children: [
                SizedBox(
                  width: 360,
                  child: MapElementsPanel(
                    document: document,
                    project: workspaceProject,
                    view: view,
                    onChanged: () => setState(() {}),
                  ),
                ),
                if (view.selectedDecorIds('a').length > 1)
                  SizedBox(
                    width: 320,
                    child: MapMultiSelectionInspector(
                      document: document,
                      project: workspaceProject,
                      view: view,
                      onChanged: () => setState(() {}),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-element-decor-bed')));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.byKey(const ValueKey('map-element-decor-desk')));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(view.selectedDecorIds('a'), {'bed', 'desk'});
    expect(find.text('2 décors sélectionnés'), findsOneWidget);
    final x = find.byKey(const ValueKey('map-multi-selection-x'));
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: x, matching: find.byType(TextField)),
          )
          .controller!
          .text,
      isEmpty,
    );
    expect(find.text('Valeurs différentes'), findsWidgets);
    await tester.enterText(
      find.descendant(of: x, matching: find.byType(TextField)),
      '7',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_pos(document, 'bed').x, 7);
    expect(_pos(document, 'desk').x, 7);
    expect(_pos(document, 'lamp').x, 8);
  });

  testWidgets('the inspector replaces the selection from a ready resource', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const rock = ProjectElementEntry(
      id: 'rock',
      name: 'Rocher',
      tilesetId: 'atlas',
      categoryId: 'decor',
      frames: [
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 2, y: 0, width: 1, height: 1),
        ),
      ],
    );
    final project = workspaceProject.copyWith(
      elements: [workspaceElement, rock],
    );
    view.select(document, MapSelectionFamily.decor, 'bed');
    view.toggleDecorInSelection(document, 'desk');
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 320,
              child: MapMultiSelectionInspector(
                document: document,
                project: project,
                view: view,
                onChanged: () => setState(() {}),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('map-multi-selection-replace')));
    await tester.pumpAndSettle();
    expect(find.text('Remplacer ces 2 décors ici'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('map-decor-replacement-search')),
        matching: find.byType(TextField),
      ),
      'roch',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('map-decor-replacement-tree')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('map-decor-replacement-rock')));
    await tester.pumpAndSettle();
    expect(document.current.placedElements.map((item) => item.elementId), [
      'rock',
      'rock',
      'tree',
    ]);
    expect(view.selectedDecorIds('a'), {'bed', 'desk'});
  });

  test('undo follows the active map and each map keeps its history', () async {
    final controller = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.activate(workspaceEntries.first);
    final first = controller.active!;
    MapEditingCommands(
      first,
      workspaceProject,
    ).place(workspaceElement, const GridPos(x: 1, y: 1));
    await controller.activate(workspaceEntries.last);
    final second = controller.active!;
    expect(second.canUndo, isFalse);
    MapEditingCommands(
      second,
      workspaceProject,
    ).place(workspaceElement, const GridPos(x: 4, y: 4));
    second.restore(redo: false);
    expect(second.current.placedElements, isEmpty);
    expect(first.current.placedElements, hasLength(1));
    await controller.activate(workspaceEntries.first);
    expect(controller.active, same(first));
    expect(first.canUndo, isTrue);
    first.restore(redo: false);
    expect(first.current.placedElements, isEmpty);
    expect(second.canRedo, isTrue);
  });
}

ProjectModel3dEntry _model(String id) => ProjectModel3dEntry(
  id: id,
  name: id,
  sourceAssetId: '$id-source',
  relativePath: 'assets/models3d/$id.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: 1, y: 1, z: 1),
    ),
    meshCount: 1,
    triangleCount: 1,
  ),
);

final class _MemoryEditorPort implements MapEditorPort {
  var state = MapEditorState();
  @override
  Future<MapEditorWorkspaceState> loadEditorState(
    ProjectSession session,
    String mapId,
  ) async => MapEditorWorkspaceState(state: state, revision: 'initial');
  @override
  Future<MapEditorWorkspaceState> saveEditorState(
    ProjectSession session,
    String mapId,
    MapEditorState state,
    String expectedRevision,
  ) async {
    this.state = state;
    return MapEditorWorkspaceState(state: state, revision: 'saved');
  }
}
