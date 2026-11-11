import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../characters/character_editing_test.dart' show guide;
import '../support/map_selection_owner_fixture.dart';
import '../support/map_workspace_fixture.dart';

const zoneArea = MapRect(
  pos: GridPos(x: 2, y: 2),
  size: GridSize(width: 4, height: 4),
);

void main() {
  late MapSelectionOwnerHarness h;
  setUp(() {
    h = MapSelectionOwnerHarness.of(
      workspaceProject.copyWith(characters: [guide]),
    );
  });
  tearDown(() => h.dispose());

  testWidgets('choosing a decor drops the gameplay zone selection', (
    tester,
  ) async {
    final zone = GameplayZoneEditingCommands(
      h.document,
      h.project,
    ).place(GameplayZoneKind.encounter, zoneArea);
    MapEditingCommands(
      h.document,
      h.project,
    ).place(workspaceElement, const GridPos(x: 9, y: 9));
    h.document.selectedId = null;

    await h.pump(tester);
    await h.use(tester, StudioMapTool.gameplayZone);
    await h.tapCell(tester, 3, 3);
    expect(h.selected(MapSelectionFamily.zone), zone.id);

    await h.use(tester, StudioMapTool.select);
    await h.tapCell(tester, 9, 9);

    expect(
      h.selected(MapSelectionFamily.zone),
      isNull,
      reason: 'the zone stops being the active target once a decor is picked',
    );

    expect(h.document.selectedId, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('choosing a character drops the sign selection', (tester) async {
    final sign = MapEntityEditingCommands(
      h.document,
      h.project,
    ).place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
    final npc = CharacterEditingCommands(
      h.document,
      h.project,
    ).place(guide, const GridPos(x: 7, y: 7));

    await h.pump(tester);
    await h.use(tester, StudioMapTool.select);
    await h.tapCell(tester, 4, 4);
    expect(h.selected(MapSelectionFamily.marker), sign.id);

    await h.tapCell(tester, 7, 7);

    expect(h.selected(MapSelectionFamily.character), npc.id);
    expect(
      h.selected(MapSelectionFamily.marker),
      isNull,
      reason: 'the sign is no longer the target of the delete button',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('choosing a warp drops the sign selection', (tester) async {
    MapEntityEditingCommands(
      h.document,
      h.project,
    ).place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
    final warp = WarpEditingCommands(h.document, h.project).place(
      workspaceEntries.firstWhere((entry) => entry.id == 'b'),
      const GridPos(x: 8, y: 2),
    );

    await h.pump(tester);
    await h.use(tester, StudioMapTool.select);
    await h.tapCell(tester, 4, 4);
    await h.tapCell(tester, 8, 2);

    expect(h.selected(MapSelectionFamily.warp), warp.id);
    expect(h.selected(MapSelectionFamily.marker), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'deletion follows the active selection after switching families',
    (tester) async {
      final zone = GameplayZoneEditingCommands(
        h.document,
        h.project,
      ).place(GameplayZoneKind.encounter, zoneArea);
      final sign = MapEntityEditingCommands(
        h.document,
        h.project,
      ).place(MapEntityKind.sign, const GridPos(x: 9, y: 2));

      await h.pump(tester);
      await h.use(tester, StudioMapTool.gameplayZone);
      await h.tapCell(tester, 3, 3);
      await h.use(tester, StudioMapTool.select);
      await h.tapCell(tester, 9, 2);
      expect(h.selected(MapSelectionFamily.marker), sign.id);

      final target = h.view.target!;
      MapEntityEditingCommands(h.document, h.project).delete(target.id);

      expect(
        h.document.current.entities,
        isEmpty,
        reason: 'the sign shown in the inspector is the one removed',
      );
      expect(
        h.document.current.gameplayZones.single.id,
        zone.id,
        reason: 'the previously selected zone survives untouched',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a click on empty ground clears the destructive target', (
    tester,
  ) async {
    MapEntityEditingCommands(
      h.document,
      h.project,
    ).place(MapEntityKind.sign, const GridPos(x: 4, y: 4));

    await h.pump(tester);
    await h.use(tester, StudioMapTool.select);
    await h.tapCell(tester, 4, 4);

    await h.tapCell(tester, 15, 12);

    expect(h.selected(MapSelectionFamily.marker), isNull);
    expect(h.document.selectedId, isNull);

    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting never writes to the document or the history', (
    tester,
  ) async {
    GameplayZoneEditingCommands(
      h.document,
      h.project,
    ).place(GameplayZoneKind.encounter, zoneArea);
    MapEntityEditingCommands(
      h.document,
      h.project,
    ).place(MapEntityKind.sign, const GridPos(x: 9, y: 2));
    final before = h.document.current;
    final steps = h.document.undoCount;

    await h.pump(tester);
    await h.use(tester, StudioMapTool.gameplayZone);
    await h.tapCell(tester, 3, 3);
    await h.use(tester, StudioMapTool.select);
    await h.tapCell(tester, 9, 2);
    await h.tapCell(tester, 15, 15);

    expect(h.document.current, before);
    expect(h.document.undoCount, steps);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a twin id on another map never becomes the target', (
    tester,
  ) async {
    final sign = MapEntityEditingCommands(
      h.document,
      h.project,
    ).place(MapEntityKind.sign, const GridPos(x: 4, y: 4));

    await h.pump(tester);
    await h.use(tester, StudioMapTool.select);
    await h.tapCell(tester, 4, 4);
    expect(h.selected(MapSelectionFamily.marker), sign.id);

    final other = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('b').copyWith(
          entities: [
            MapEntity(
              id: sign.id,
              name: 'Homonyme',
              kind: MapEntityKind.sign,
              pos: const GridPos(x: 4, y: 4),
              sign: const MapEntitySignData(title: 'Homonyme'),
            ),
          ],
        ),
        revision: 'base',
        mapId: 'b',
      ),
    );

    expect(
      h.view.selectedFor(other.current.id, MapSelectionFamily.marker),
      isNull,
      reason: 'the same local id on another map is not the active target',
    );
    expect(h.view.hasSelectionIn(other.current.id), isFalse);
    expect(
      h.view.selectedFor(h.document.current.id, MapSelectionFamily.marker),
      sign.id,
      reason: 'the original map keeps its own target',
    );
  });

  testWidgets('the target survives pan and zoom without moving anything', (
    tester,
  ) async {
    final sign = MapEntityEditingCommands(
      h.document,
      h.project,
    ).place(MapEntityKind.sign, const GridPos(x: 4, y: 4));

    await h.pump(tester);
    await h.use(tester, StudioMapTool.select);
    await h.tapCell(tester, 4, 4);
    final before = h.document.current;

    h.redraw();
    h.view.transform.value = Matrix4.identity()
      ..translateByDouble(-30, -18, 0, 1)
      ..scaleByDouble(1.5, 1.5, 1, 1);
    await tester.pumpAndSettle();

    expect(h.selected(MapSelectionFamily.marker), sign.id);
    expect(h.document.current, before);
    expect(tester.takeException(), isNull);
  });
}
