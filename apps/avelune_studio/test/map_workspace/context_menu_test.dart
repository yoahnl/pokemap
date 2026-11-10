import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../characters/character_editing_test.dart' show guide;
import '../support/map_context_harness.dart';
import '../support/map_workspace_fixture.dart';

const zoneArea = MapRect(
  pos: GridPos(x: 2, y: 2),
  size: GridSize(width: 5, height: 5),
);

void main() {
  late MapContextHarness h;
  setUp(
    () => h = MapContextHarness.of(
      workspaceProject.copyWith(characters: [guide]),
    ),
  );
  tearDown(() => h.dispose());

  testWidgets(
    'a real right click resolves decor actions and selects its target',
    (tester) async {
      final id = MapEditingCommands(
        h.document,
        h.project,
      ).place(workspaceElement, const GridPos(x: 4, y: 4));
      h.document.selectedId = null;
      await h.pump(tester);
      await h.rightClick(tester, 4, 4);
      expect(h.request!.selected!.label, 'Arbre');
      expect(
        h.request!.actions.map((action) => action.command),
        containsAll([
          MapContextCommand.properties,
          MapContextCommand.bringForward,
          MapContextCommand.delete,
        ]),
      );
      expect(h.selected(MapSelectionFamily.decor), id);
    },
  );

  test(
    'a lone decor has one honest reason for both unavailable directions',
    () {
      final id = MapEditingCommands(
        h.document,
        h.project,
      ).place(workspaceElement, const GridPos(x: 4, y: 4))!;
      final actions = mapContextActionsFor(
        MapContextTarget(
          mapId: h.document.current.id,
          family: MapContextFamily.decor,
          id: id,
          label: 'Arbre',
          kindLabel: 'Décor',
        ),
        MapContextActionContext(
          document: h.document,
          project: h.project,
          position: const GridPos(x: 4, y: 4),
        ),
      );
      final forward = actions.singleWhere(
        (action) => action.command == MapContextCommand.bringForward,
      );
      final backward = actions.singleWhere(
        (action) => action.command == MapContextCommand.sendBackward,
      );
      expect(forward.unavailable, backward.unavailable);
      expect(forward.unavailable, contains('Aucun autre décor'));
    },
  );

  testWidgets('a real right click never paints places or erases', (
    tester,
  ) async {
    h.view
      ..tool = StudioMapTool.place
      ..brush = workspaceElement;
    await h.pump(tester);
    final before = h.document.current;
    final steps = h.document.undoCount;
    await h.rightClick(tester, 6, 6);
    expect(h.document.current, same(before));
    expect(h.document.undoCount, steps);
    expect(h.request, isNotNull);
  });

  testWidgets('closing a context request preserves the map and its history', (
    tester,
  ) async {
    MapEntityEditingCommands(
      h.document,
      h.project,
    ).place(MapEntityKind.sign, const GridPos(x: 3, y: 3));
    await h.pump(tester);
    final before = h.document.current;
    final steps = h.document.undoCount;
    await h.rightClick(tester, 3, 3);
    expect(h.request, isNotNull);
    h.close();
    expect(h.request, isNull);
    expect(h.document.current, same(before));
    expect(h.document.undoCount, steps);
  });

  testWidgets(
    'overlapping targets remain distinct and choosing one updates selection',
    (tester) async {
      final npc = CharacterEditingCommands(
        h.document,
        h.project,
      ).place(guide, const GridPos(x: 4, y: 4));
      GameplayZoneEditingCommands(
        h.document,
        h.project,
      ).place(GameplayZoneKind.encounter, zoneArea);
      MapEditingCommands(
        h.document,
        h.project,
      ).place(workspaceElement, const GridPos(x: 4, y: 4));
      h.document.selectedId = null;
      await h.pump(tester);
      await h.rightClick(tester, 4, 4);
      expect(
        h.request!.targets.map((target) => target.family),
        containsAll([
          MapContextFamily.decor,
          MapContextFamily.zone,
          MapContextFamily.character,
        ]),
      );
      h.select(
        h.request!.targets.singleWhere(
          (target) => target.family == MapContextFamily.character,
        ),
      );
      expect(h.selected(MapSelectionFamily.character), npc.id);
      expect(
        h.request!.actions.map((action) => action.command),
        contains(MapContextCommand.openInteraction),
      );
    },
  );

  testWidgets('a right click after pan and zoom resolves the correct cell', (
    tester,
  ) async {
    final sign = MapEntityEditingCommands(
      h.document,
      h.project,
    ).place(MapEntityKind.sign, const GridPos(x: 7, y: 5));
    await h.pump(tester);
    h.view.transform.value = Matrix4.identity()
      ..translateByDouble(-35, -20, 0, 1)
      ..scaleByDouble(1.6, 1.6, 1, 1);
    h.redraw();
    await tester.pumpAndSettle();
    await h.rightClick(tester, 7, 5);
    expect(h.selected(MapSelectionFamily.marker), sign.id);
    expect(h.request!.selected!.kindLabel, 'Panneau');
  });

  testWidgets('context deletion uses the shared command and undo', (
    tester,
  ) async {
    final warp = WarpEditingCommands(h.document, h.project).place(
      workspaceEntries.firstWhere((entry) => entry.id == 'b'),
      const GridPos(x: 6, y: 2),
    );
    await h.pump(tester);
    final steps = h.document.undoCount;
    await h.rightClick(tester, 6, 2);
    h.run(MapContextCommand.delete);
    expect(h.request, isNull);
    expect(h.document.current.warps, isEmpty);
    expect(h.document.undoCount, steps + 1);
    h.document.restore(redo: false);
    expect(h.document.current.warps.single.id, warp.id);
  });

  testWidgets('a target removed while its request is open is refused', (
    tester,
  ) async {
    final sign = MapEntityEditingCommands(
      h.document,
      h.project,
    ).place(MapEntityKind.sign, const GridPos(x: 3, y: 6));
    await h.pump(tester);
    await h.rightClick(tester, 3, 6);
    MapEntityEditingCommands(h.document, h.project).delete(sign.id);
    h.run(MapContextCommand.delete);
    expect(h.document.error, contains('n’est plus à cet endroit'));
    expect(h.request, isNull);
  });

  testWidgets('an empty cell offers coordinates and a scoped tile erase', (
    tester,
  ) async {
    await h.pump(tester);
    await h.rightClick(tester, 12, 9);
    expect(h.request!.selected, isNull);
    expect(h.request!.targets, isEmpty);
    expect(
      h.request!.actions.map((action) => action.command),
      containsAll([
        MapContextCommand.copyCoordinates,
        MapContextCommand.eraseTile,
      ]),
    );
  });
}
