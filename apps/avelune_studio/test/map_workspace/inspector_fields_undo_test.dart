import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_commit_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_selection_harness.dart';
import '../support/map_workspace_fixture.dart';

const zoneArea = MapRect(
  pos: GridPos(x: 2, y: 2),
  size: GridSize(width: 4, height: 4),
);

void main() {
  late MapSelectionHarness h;
  setUp(() => h = MapSelectionHarness.of(workspaceProject));
  tearDown(() => h.dispose());

  Finder field(String label) => find.byWidgetPredicate(
    (widget) => widget is StudioCommitField && widget.label == label,
  );

  Future<void> type(WidgetTester tester, String label, String value) async {
    await tester.enterText(field(label), value);
    await tester.pumpAndSettle();
  }

  /// Leaves the field the way an author does: a tap elsewhere in the panel,
  /// then the focus moves on. Works for a raw TextField and for a field that
  /// commits on focus loss.
  Future<void> leaveField(WidgetTester tester) async {
    await tester.tapAt(const Offset(1000, 24));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  String fieldText(WidgetTester tester, String label) => tester
      .widget<TextField>(
        find.descendant(of: field(label), matching: find.byType(TextField)),
      )
      .controller!
      .text;

  testWidgets('an undone sign title is not re-applied when leaving the field', (
    tester,
  ) async {
    final commands = MapEntityEditingCommands(h.document, h.project);
    final sign = commands.place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
    commands.updateSign(sign.id, title: 'Quai numéro 3');

    await h.pump(tester);
    await h.use(tester, StudioMapTool.select);
    await h.tapCell(tester, 4, 4);

    await type(tester, 'Titre', 'Quai revu');
    await leaveField(tester);
    expect(commands.selected(sign.id)!.sign!.title, 'Quai revu');

    h.document.restore(redo: false);
    h.redraw();
    await tester.pumpAndSettle();
    expect(commands.selected(sign.id)!.sign!.title, 'Quai numéro 3');
    expect(
      fieldText(tester, 'Titre'),
      'Quai numéro 3',
      reason: 'the field shows the restored document, not the undone entry',
    );

    await tester.tap(field('Titre'));
    await tester.pumpAndSettle();
    await leaveField(tester);

    expect(
      commands.selected(sign.id)!.sign!.title,
      'Quai numéro 3',
      reason: 'leaving the field never re-applies what was undone',
    );
  });

  testWidgets('an undone zone name is not re-applied when leaving the field', (
    tester,
  ) async {
    final commands = GameplayZoneEditingCommands(h.document, h.project);
    final zone = commands.place(GameplayZoneKind.encounter, zoneArea);

    await h.pump(tester);
    await h.use(tester, StudioMapTool.gameplayZone);
    await h.tapCell(tester, 3, 3);

    await type(tester, 'Nom', 'Herbes du quai');
    await leaveField(tester);
    expect(commands.selected(zone.id)!.name, 'Herbes du quai');

    h.document.restore(redo: false);
    h.redraw();
    await tester.pumpAndSettle();
    expect(commands.selected(zone.id)!.name, 'Zone de rencontres');

    await tester.tap(field('Nom'));
    await tester.pumpAndSettle();
    await leaveField(tester);

    expect(
      commands.selected(zone.id)!.name,
      'Zone de rencontres',
      reason: 'the undone name stays undone',
    );
  });

  testWidgets('redo brings the field back to the redone value', (tester) async {
    final commands = MapEntityEditingCommands(h.document, h.project);
    final sign = commands.place(MapEntityKind.sign, const GridPos(x: 4, y: 4));

    await h.pump(tester);
    await h.use(tester, StudioMapTool.select);
    await h.tapCell(tester, 4, 4);

    await type(tester, 'Titre', 'Quai revu');
    await leaveField(tester);
    h.document.restore(redo: false);
    h.redraw();
    await tester.pumpAndSettle();
    h.document.restore(redo: true);
    h.redraw();
    await tester.pumpAndSettle();

    expect(commands.selected(sign.id)!.sign!.title, 'Quai revu');
    expect(fieldText(tester, 'Titre'), 'Quai revu');
  });

  testWidgets('an entry aimed at one sign never lands on another', (
    tester,
  ) async {
    final commands = MapEntityEditingCommands(h.document, h.project);
    final first = commands.place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
    final second = commands.place(
      MapEntityKind.sign,
      const GridPos(x: 9, y: 2),
    );
    commands.updateSign(first.id, title: 'Premier');
    commands.updateSign(second.id, title: 'Second');

    await h.pump(tester);
    await h.use(tester, StudioMapTool.select);
    await h.tapCell(tester, 4, 4);
    await type(tester, 'Titre', 'Saisie en cours');

    await h.tapCell(tester, 9, 2);

    expect(
      commands.selected(second.id)!.sign!.title,
      'Second',
      reason: 'the pending entry never reaches the newly selected sign',
    );
    expect(
      fieldText(tester, 'Titre'),
      'Second',
      reason: 'the field shows the new target, not the abandoned entry',
    );
  });

  testWidgets('an invalid arrival cell is refused and the field restored', (
    tester,
  ) async {
    final warps = WarpEditingCommands(h.document, h.project);
    final warp = warps.place(
      workspaceEntries.firstWhere((entry) => entry.id == 'b'),
      const GridPos(x: 3, y: 3),
    );
    warps.retarget(warp.id, targetPos: const GridPos(x: 5, y: 2));

    await h.pump(tester);
    await h.use(tester, StudioMapTool.select);
    await h.tapCell(tester, 3, 3);

    await type(tester, 'Case X', 'abc');
    await leaveField(tester);

    expect(
      warps.selected(warp.id)!.targetPos,
      const GridPos(x: 5, y: 2),
      reason: 'an unreadable entry never reaches the document',
    );
    expect(
      fieldText(tester, 'Case X'),
      '5',
      reason: 'the refused field goes back to the stored value',
    );
    expect(h.document.error, contains('nombres positifs'));

    await type(tester, 'Case X', '7');
    await leaveField(tester);
    expect(warps.selected(warp.id)!.targetPos, const GridPos(x: 7, y: 2));
  });

  testWidgets('saving while a field still has focus keeps the entry', (
    tester,
  ) async {
    final commands = MapEntityEditingCommands(h.document, h.project);
    final sign = commands.place(MapEntityKind.sign, const GridPos(x: 4, y: 4));

    await h.pump(tester);
    await h.use(tester, StudioMapTool.select);
    await h.tapCell(tester, 4, 4);
    await type(tester, 'Titre', 'Quai enregistré');

    // What the real save path does before writing, as the other spaces do.
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    await tester.pumpAndSettle();

    expect(
      commands.selected(sign.id)!.sign!.title,
      'Quai enregistré',
      reason: 'the pending entry is applied before the document is written',
    );
  });
}
