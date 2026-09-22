import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_context_harness.dart';
import '../support/map_workspace_fixture.dart';

Finder menu() => find.byKey(const ValueKey('map-context-menu'));
Finder inMenu(String label) =>
    find.descendant(of: menu(), matching: find.text(label));

void main() {
  late MapContextHarness h;
  setUp(() => h = MapContextHarness.of(workspaceProject));
  tearDown(() => h.dispose());

  testWidgets('the menu takes the focus and gives it back on Escape', (
    tester,
  ) async {
    MapEntityEditingCommands(
      h.document,
      h.project,
    ).place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
    await h.pump(tester);
    final before = FocusManager.instance.primaryFocus;

    await h.rightClick(tester, 4, 4);
    expect(
      FocusManager.instance.primaryFocus,
      isNot(before),
      reason: 'the menu owns the focus while it is open',
    );

    await h.escape(tester);
    expect(menu(), findsNothing);
    expect(
      FocusManager.instance.primaryFocus,
      before,
      reason: 'the focus goes back where it came from',
    );
  });

  testWidgets('an action is activated with the keyboard alone', (tester) async {
    final zones = GameplayZoneEditingCommands(h.document, h.project);
    final zone = zones.place(
      GameplayZoneKind.encounter,
      const MapRect(
        pos: GridPos(x: 3, y: 3),
        size: GridSize(width: 3, height: 3),
      ),
    );
    await h.pump(tester);

    String? focusedLabel() {
      final context = FocusManager.instance.primaryFocus?.context;
      final button = context?.findAncestorWidgetOfExactType<TextButton>();
      final align = button?.child;
      return align is Align && align.child is Text
          ? (align.child! as Text).data
          : null;
    }

    await h.rightClick(tester, 4, 4);
    for (var i = 0; i < 12 && focusedLabel() != 'Supprimer la zone'; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    expect(
      focusedLabel(),
      'Supprimer la zone',
      reason: 'the keyboard reached the entry without the pointer',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(
      zones.selected(zone.id),
      isNull,
      reason: 'the keyboard reached and ran the action',
    );
    expect(menu(), findsNothing);
  });

  testWidgets('a blocked action cannot be run from the keyboard', (
    tester,
  ) async {
    MapEditingCommands(
      h.document,
      h.project,
    ).place(workspaceElement, const GridPos(x: 4, y: 4));
    h.document.selectedId = null;
    await h.pump(tester);

    await h.rightClick(tester, 4, 4);
    final rows = tester.widgetList<TextButton>(
      find.descendant(of: menu(), matching: find.byType(TextButton)),
    );
    expect(
      rows.any((item) => item.onPressed == null),
      isTrue,
      reason: 'a single decor cannot move forward: the entry is inert',
    );
  });

  testWidgets('a right click elsewhere retargets instead of reusing the old', (
    tester,
  ) async {
    final commands = MapEntityEditingCommands(h.document, h.project);
    final first = commands.place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
    await h.pump(tester);

    await h.rightClick(tester, 4, 4);
    expect(inMenu('Panneau'), findsWidgets);

    // Far from the open menu, so the click really reaches the scrim.
    await h.rightClick(tester, 18, 1);
    expect(menu(), findsNothing, reason: 'the click outside closed it');

    await h.rightClick(tester, 18, 1);
    expect(
      inMenu('Aucun élément ici'),
      findsOneWidget,
      reason: 'an empty cell never reuses the previous target',
    );
    expect(commands.selected(first.id), isNotNull);
  });
}
