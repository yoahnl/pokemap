import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
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

Finder inMenu(String label) => find.descendant(
  of: find.byKey(const ValueKey('map-context-menu')),
  matching: find.text(label),
);

void main() {
  late MapContextHarness h;
  setUp(() {
    h = MapContextHarness.of(workspaceProject.copyWith(characters: [guide]));
  });
  tearDown(() => h.dispose());

  testWidgets('a right click on a decor names it and offers its actions', (
    tester,
  ) async {
    MapEditingCommands(
      h.document,
      h.project,
    ).place(workspaceElement, const GridPos(x: 4, y: 4));
    h.document.selectedId = null;
    await h.pump(tester);

    await h.rightClick(tester, 4, 4);

    expect(find.byKey(const ValueKey('map-context-menu')), findsOneWidget);
    expect(inMenu('Arbre'), findsWidgets);
    expect(inMenu('Propriétés'), findsOneWidget);
    expect(inMenu('Passer devant'), findsOneWidget);
    expect(inMenu('Supprimer le décor'), findsOneWidget);
    expect(
      h.selected(MapSelectionFamily.decor),
      isNotNull,
      reason: 'the menu target is also the selection',
    );
  });

  testWidgets('a right click never paints, places or erases', (tester) async {
    h.view
      ..tool = StudioMapTool.place
      ..brush = workspaceElement;
    await h.pump(tester);
    final before = h.document.current;
    final steps = h.document.undoCount;

    await h.rightClick(tester, 6, 6);

    expect(h.document.current, before);
    expect(h.document.undoCount, steps);
    expect(find.byKey(const ValueKey('map-context-menu')), findsOneWidget);
  });

  testWidgets('Escape closes the menu without touching the document', (
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
    expect(find.byKey(const ValueKey('map-context-menu')), findsOneWidget);
    await h.escape(tester);

    expect(find.byKey(const ValueKey('map-context-menu')), findsNothing);
    expect(h.document.current, before);
    expect(h.document.undoCount, steps);
  });

  testWidgets('clicking outside closes the menu without painting behind it', (
    tester,
  ) async {
    h.view
      ..tool = StudioMapTool.place
      ..brush = workspaceElement;
    await h.pump(tester);
    final steps = h.document.undoCount;

    await h.rightClick(tester, 5, 5);
    await tester.tap(find.byKey(const ValueKey('map-context-scrim')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-context-menu')), findsNothing);
    expect(
      h.document.undoCount,
      steps,
      reason: 'the dismissing click never reached the canvas behind',
    );
  });

  testWidgets('overlapping elements are all offered and the choice sticks', (
    tester,
  ) async {
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
    expect(inMenu('Éléments à cet endroit'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('map-context-menu')),
        matching: find.textContaining('Zone de jeu'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('map-context-menu')),
        matching: find.textContaining('Décor'),
      ),
      findsWidgets,
    );

    await tester.tap(find.byKey(ValueKey('map-context-pick-${npc.id}')));
    await tester.pumpAndSettle();

    expect(h.selected(MapSelectionFamily.character), npc.id);
    expect(inMenu('Écrire son interaction'), findsOneWidget);
  });

  testWidgets('a right click after pan and zoom lands on the right cell', (
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
    expect(inMenu('Panneau'), findsWidgets);
  });

  testWidgets('deleting from the menu uses the shared command and undo', (
    tester,
  ) async {
    final warp = WarpEditingCommands(h.document, h.project).place(
      workspaceEntries.firstWhere((entry) => entry.id == 'b'),
      const GridPos(x: 6, y: 2),
    );
    await h.pump(tester);
    final steps = h.document.undoCount;

    await h.rightClick(tester, 6, 2);
    await tester.tap(inMenu('Supprimer le passage'));
    await tester.pumpAndSettle();

    expect(h.document.current.warps, isEmpty);
    expect(h.document.undoCount, steps + 1);
    h.document.restore(redo: false);
    expect(h.document.current.warps.single.id, warp.id);
  });

  testWidgets('an element removed while the menu is open is refused', (
    tester,
  ) async {
    final sign = MapEntityEditingCommands(
      h.document,
      h.project,
    ).place(MapEntityKind.sign, const GridPos(x: 3, y: 6));
    await h.pump(tester);

    await h.rightClick(tester, 3, 6);
    MapEntityEditingCommands(h.document, h.project).delete(sign.id);
    h.redraw();
    await tester.pumpAndSettle();

    await tester.tap(inMenu('Supprimer'));
    await tester.pumpAndSettle();

    expect(h.document.error, contains('n’est plus à cet endroit'));
    expect(find.byKey(const ValueKey('map-context-menu')), findsNothing);
  });

  testWidgets('an empty cell offers coordinates and a scoped erase', (
    tester,
  ) async {
    await h.pump(tester);

    await h.rightClick(tester, 12, 9);

    expect(inMenu('Aucun élément ici'), findsOneWidget);
    expect(inMenu('Copier les coordonnées'), findsOneWidget);
    expect(
      inMenu('Effacer la tuile de cette case'),
      findsOneWidget,
      reason: 'the label says what it erases: one tile, not the stack',
    );
  });
}
