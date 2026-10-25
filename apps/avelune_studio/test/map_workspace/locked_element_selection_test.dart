import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/trigger_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_elements_panel.dart';
import 'package:map_core/map_core.dart';

import '../support/map_selection_harness.dart';
import '../characters/character_editing_test.dart' show guide;
import '../support/map_workspace_fixture.dart';
import '../support/spatial_border_fixture.dart';

import 'package:avelune_studio/features/map_workspace/application/map_border_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';

void main() {
  late MapSelectionHarness h;
  late MapEditorController editor;
  setUp(() {
    h = MapSelectionHarness.of(workspaceProject);
    editor = MapEditorController(
      session: workspaceSession,
      mapId: h.document.current.id,
      port: _MemoryEditorPort(),
      state: MapEditorWorkspaceState(
        state: MapEditorState(),
        revision: 'initial',
      ),
    );
    h.document.editor = editor;
  });
  tearDown(() {
    h.dispose();
    editor.dispose();
  });

  test('border and environment layer visibility follows canonical generated ownership', () async {
    h.project = spatialBorderProject();
    h.document.commit(spatialBorderMap());
    final draft = MapBorderDrawingDraft.start(
      mapId: h.document.current.id,
      mapSize: h.document.current.size,
      blueprintId: 'fence',
      origin: const GridPos(x: 2, y: 5),
      sourceMap: h.document.current,
      sourceProject: h.project,
      featureId: 'test-border',
      seed: BorderSignedInt64.fromInt(17),
    ).addAngle(const GridPos(x: 5, y: 5)).addAngle(const GridPos(x: 5, y: 7));
    MapBorderEditingCommands(h.document, h.project).finish(draft);
    final border = h.document.current.layers.whereType<BorderLayer>().single;
    final borderId = border.content.features.single.generatedPlacementIds.first;
    final map = h.document.current;
    h.document.commit(
      map.copyWith(
        layers: [
          ...map.layers,
          MapLayer.environment(
            id: 'forest',
            name: 'Forêt',
            content: EnvironmentLayerContent(
              targetsSpatialTerrain: true,
              areas: [
                EnvironmentArea(
                  id: 'trees',
                  name: 'Arbres',
                  presetId: 'woodland',
                  mask: EnvironmentAreaMask(
                    width: 12,
                    height: 10,
                    cells: List.filled(120, true),
                  ),
                  seed: 1,
                  generatedPlacementIds: ['forest-tree'],
                ),
              ],
            ),
          ),
        ],
        spatialScene: map.spatialScene!.copyWith(
          instances: [
            ...map.spatialScene!.instances,
            SpatialModelInstance(
              id: 'forest-tree',
              modelId: 'oak',
              position: Model3dVector3.zero,
            ),
          ],
        ),
      ),
    );
    final before = h.document.current;
    await editor.setHidden('layer', border.id, true);
    expect(h.document.isElementHidden('model', borderId), isTrue);
    expect(h.document.isElementHidden('model', 'forest-tree'), isFalse);
    expect(
      h.document.elementIdsInLayer('model', border.id),
      contains(borderId),
    );
    await editor.setHidden('layer', 'forest', true);
    expect(h.document.isElementHidden('model', 'forest-tree'), isTrue);
    expect(h.document.elementIdsInLayer('model', 'forest'), ['forest-tree']);
    expect(h.document.current, same(before));
    await editor.showAll();
    expect(h.document.isElementHidden('model', borderId), isFalse);
    expect(h.document.isElementHidden('model', 'forest-tree'), isFalse);
  });

  for (final type in ['character', 'marker', 'warp', 'zone', 'trigger']) {
    test(
      'hidden $type rejects stale commands and resumes after showing',
      () async {
        final target = _guardCase(h, type);
        final before = h.document.current;
        final history = h.document.undoCount;
        await editor.setHidden(target.kind, target.id, true);
        target.move();
        target.resize?.call();
        if (type == 'character' || type == 'marker' || type == 'trigger') {
          expect(target.delete, throwsStateError);
        } else {
          target.delete();
        }
        expect(h.document.current, same(before));
        expect(h.document.undoCount, history);
        expect(target.exists(), isTrue);
        await editor.setHidden(target.kind, target.id, false);
        target.move();
        expect(h.document.current, isNot(same(before)));
        target.delete();
        expect(target.exists(), isFalse);
      },
    );
    test(
      'stale $type commands preserve a lock and resume after unlocking',
      () async {
        final target = _guardCase(h, type);
        final before = h.document.current;
        final history = h.document.undoCount;
        await editor.setLocked(target.kind, target.id, true);
        target.move();
        target.resize?.call();
        if (type == 'character' || type == 'marker' || type == 'trigger') {
          expect(target.delete, throwsStateError);
        } else {
          target.delete();
        }
        expect(h.document.current, same(before));
        expect(h.document.undoCount, history);
        expect(target.exists(), isTrue);
        await editor.setLocked(target.kind, target.id, false);
        target.move();
        target.resize?.call();
        final moved = h.document.current;
        expect(moved, isNot(before));
        await editor.setLocked(target.kind, target.id, true);
        h.document.restore(redo: false);
        expect(h.document.current, isNot(moved));
        h.document.restore(redo: true);
        expect(h.document.current, moved);
        await editor.setLocked(target.kind, target.id, false);
        target.delete();
        expect(target.exists(), isFalse);
      },
    );
  }

  testWidgets(
    'hidden decor and its hidden layer are excluded from real taps and stale moves',
    (tester) async {
      final commands = MapEditingCommands(h.document, h.project);
      final back = commands.place(workspaceElement, const GridPos(x: 4, y: 4))!;
      final front = commands.place(
        workspaceElement,
        const GridPos(x: 4, y: 4),
      )!;
      await h.pump(tester);
      await h.tapCell(tester, 4, 4);
      expect(h.document.selectedId, front);
      final before = h.document.current;
      await editor.setHidden('decor', front, true);
      h.redraw();
      await tester.pumpAndSettle();
      expect(h.document.selectedId, isNull);
      await h.tapCell(tester, 4, 4);
      expect(h.document.selectedId, back);
      commands.move(front, const GridPos(x: 7, y: 7));
      expect(h.document.current, same(before));
      await editor.showAll();
      h.view.clearSelection(h.document);
      h.redraw();
      await tester.pumpAndSettle();
      await h.tapCell(tester, 4, 4);
      expect(h.document.selectedId, front);
      final layer = h.document.current.placedElements
          .singleWhere((entry) => entry.id == front)
          .layerId;
      await editor.setHidden('layer', layer, true);
      h.redraw();
      await tester.pumpAndSettle();
      expect(h.document.isElementHidden('decor', front), isTrue);
      expect(h.document.isElementHidden('decor', back), isTrue);
      await h.tapCell(tester, 4, 4);
      expect(h.document.selectedId, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'locked front decor lets real taps and drags reach the decor behind',
    (tester) async {
      final commands = MapEditingCommands(h.document, h.project);
      final back = commands.place(workspaceElement, const GridPos(x: 4, y: 4))!;
      final front = commands.place(
        workspaceElement,
        const GridPos(x: 4, y: 4),
      )!;
      await h.pump(tester);
      await h.tapCell(tester, 4, 4);
      expect(h.document.selectedId, front);
      await editor.setLocked('decor', front, true);
      h.redraw();
      await tester.pumpAndSettle();
      expect(h.document.selectedId, isNull);
      await h.tapCell(tester, 4, 4);
      expect(h.document.selectedId, back);
      await h.dragCells(tester, 4, 4, 5, 4);
      expect(
        h.document.current.placedElements
            .firstWhere((entry) => entry.id == front)
            .pos,
        const GridPos(x: 4, y: 4),
      );
      expect(
        h.document.current.placedElements
            .firstWhere((entry) => entry.id == back)
            .pos,
        const GridPos(x: 5, y: 4),
      );
      await editor.setLocked('decor', front, false);
      h.redraw();
      await tester.pumpAndSettle();
      await h.tapCell(tester, 4, 4);
      expect(h.document.selectedId, front);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'family lock in the panel allows clicking behind all its effects',
    (tester) async {
      final effect = workspaceElement.copyWith(
        id: 'mist',
        name: 'Brume',
        categoryId: 'effects',
      );
      h.project = h.project.copyWith(
        elements: [workspaceElement, effect],
        elementCategories: const [
          ProjectElementCategory(id: 'effects', name: 'Effets'),
        ],
      );
      final commands = MapEditingCommands(h.document, h.project);
      final back = commands.place(workspaceElement, const GridPos(x: 4, y: 4))!;
      final front = commands.place(effect, const GridPos(x: 4, y: 4))!;
      final other = commands.place(effect, const GridPos(x: 7, y: 7))!;
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
                    width: 640,
                    child: MapWorkspaceCanvas(
                      document: h.document,
                      project: h.project,
                      visuals: WorkspaceTestVisuals(),
                      view: h.view,
                      onChanged: () => setState(() {}),
                      gestureGeneration: 0,
                    ),
                  ),
                  Expanded(
                    child: MapElementsPanel(
                      document: h.document,
                      project: h.project,
                      view: h.view,
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
      await h.tapCell(tester, 4, 4);
      expect(h.document.selectedId, front);
      final before = h.document.current;
      await tester.tap(
        find.byTooltip('Verrouiller ou déverrouiller Décors · Effets'),
      );
      await tester.pumpAndSettle();
      expect(h.document.current, same(before));
      expect(h.document.isElementLocked('decor', front), isTrue);
      expect(h.document.isElementLocked('decor', other), isTrue);
      expect(h.document.selectedId, isNull);
      await h.tapCell(tester, 4, 4);
      expect(h.document.selectedId, back);
      commands.move(front, const GridPos(x: 9, y: 9));
      expect(h.document.current, same(before));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('locking an effects layer makes its decor click through', (
    tester,
  ) async {
    final commands = MapEditingCommands(h.document, h.project);
    final back = commands.place(workspaceElement, const GridPos(x: 4, y: 4))!;
    final front = commands.place(workspaceElement, const GridPos(x: 4, y: 4))!;
    final map = h.document.current;
    h.document.commit(
      map.copyWith(
        layers: [
          MapLayer.tile(
            id: 'effects',
            name: 'Effets',
            cells: List.filled(320, 0),
          ),
          ...map.layers,
        ],
        placedElements: [
          for (final entry in map.placedElements)
            entry.id == front ? entry.copyWith(layerId: 'effects') : entry,
        ],
      ),
    );
    await h.pump(tester);
    await h.tapCell(tester, 4, 4);
    expect(h.document.selectedId, front);
    final before = h.document.current;
    await editor.setLocked('layer', 'effects', true);
    h.redraw();
    await tester.pumpAndSettle();
    await h.tapCell(tester, 4, 4);
    expect(h.document.selectedId, back);
    commands.move(front, const GridPos(x: 9, y: 9));
    expect(h.document.current, same(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets('locking a decor during a drag cancels its pending movement', (
    tester,
  ) async {
    final id = MapEditingCommands(
      h.document,
      h.project,
    ).place(workspaceElement, const GridPos(x: 4, y: 4))!;
    await h.pump(tester);
    final gesture = await tester.startGesture(h.cell(tester, 4, 4));
    await gesture.moveTo(h.cell(tester, 6, 4));
    await tester.pump();
    await editor.setLocked('decor', id, true);
    h.redraw();
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      h.document.current.placedElements.single.pos,
      const GridPos(x: 4, y: 4),
    );
    expect(h.document.selectedId, isNull);
    expect(
      h.view.selectedFor(h.document.current.id, MapSelectionFamily.decor),
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}

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

typedef _GuardCase = ({
  String kind,
  String id,
  VoidCallback move,
  VoidCallback? resize,
  VoidCallback delete,
  bool Function() exists,
});

_GuardCase _guardCase(MapSelectionHarness h, String type) {
  const origin = GridPos(x: 4, y: 4);
  const destination = GridPos(x: 6, y: 6);
  const size = GridSize(width: 2, height: 2);
  const area = MapRect(pos: origin, size: size);
  switch (type) {
    case 'character':
      h.project = h.project.copyWith(characters: [guide]);
      final commands = CharacterEditingCommands(h.document, h.project);
      final id = commands.place(guide, origin).id;
      return (
        kind: 'entity',
        id: id,
        move: () => commands.move(id, destination),
        resize: null,
        delete: () => commands.delete(id),
        exists: () => commands.selected(id) != null,
      );
    case 'marker':
      final commands = MapEntityEditingCommands(h.document, h.project);
      final id = commands.place(MapEntityKind.sign, origin).id;
      return (
        kind: 'entity',
        id: id,
        move: () => commands.move(id, destination),
        resize: null,
        delete: () => commands.delete(id),
        exists: () => commands.selected(id) != null,
      );
    case 'warp':
      final commands = WarpEditingCommands(h.document, h.project);
      final id = commands.placeArrival(origin).id;
      return (
        kind: 'warp',
        id: id,
        move: () => commands.move(id, destination),
        resize: null,
        delete: () => commands.delete(id),
        exists: () => commands.selected(id) != null,
      );
    case 'zone':
      final commands = GameplayZoneEditingCommands(h.document, h.project);
      final id = commands.place(GameplayZoneKind.encounter, area).id;
      return (
        kind: 'zone',
        id: id,
        move: () => commands.move(id, destination),
        resize: () => commands.resize(id, const GridSize(width: 3, height: 3)),
        delete: () => commands.delete(id),
        exists: () => commands.selected(id) != null,
      );
    case 'trigger':
      final commands = TriggerEditingCommands(h.document, h.project);
      final id = commands
          .add(
            const MapTrigger(id: 'story', type: TriggerType.event, area: area),
          )
          .id;
      return (
        kind: 'trigger',
        id: id,
        move: () => commands.move(id, destination),
        resize: () => commands.resize(id, const GridSize(width: 3, height: 3)),
        delete: () => commands.delete(id),
        exists: () => commands.selected(id) != null,
      );
    default:
      throw StateError(type);
  }
}
