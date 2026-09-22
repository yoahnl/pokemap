import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/trigger_editing_commands.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../characters/character_editing_test.dart' show guide;
import '../support/map_context_harness.dart';
import '../support/map_workspace_fixture.dart';

const area = MapRect(
  pos: GridPos(x: 3, y: 3),
  size: GridSize(width: 4, height: 3),
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

  Future<void> dragTo(
    WidgetTester tester,
    int fromX,
    int fromY,
    int toX,
    int toY,
  ) async {
    final gesture = await tester.startGesture(h.cellAt(tester, fromX, fromY));
    await gesture.moveTo(h.cellAt(tester, toX, toY));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('a gameplay zone is really moved by the menu action', (
    tester,
  ) async {
    final zones = GameplayZoneEditingCommands(h.document, h.project);
    final zone = zones.place(GameplayZoneKind.hazard, area);
    zones.updateHazard(zone.id, damagePerStep: 2);
    await h.pump(tester);
    final steps = h.document.undoCount;

    await h.rightClick(tester, 4, 4);
    await tester.tap(inMenu('Déplacer'));
    await tester.pumpAndSettle();
    expect(h.view.pendingMove?.id, zone.id);

    await dragTo(tester, 4, 4, 7, 6);

    final moved = zones.selected(zone.id)!;
    expect(moved.area.pos, const GridPos(x: 6, y: 5));
    expect(moved.area.size, area.size, reason: 'the size never changes');
    expect(moved.hazard!.damagePerStep, 2);
    expect(
      h.document.undoCount,
      steps + 1,
      reason: 'one move, one history entry',
    );

    h.document.restore(redo: false);
    expect(zones.selected(zone.id)!.area.pos, area.pos);
  });

  testWidgets('a story zone moves the same way', (tester) async {
    final triggers = TriggerEditingCommands(h.document, h.project);
    triggers.add(
      const MapTrigger(
        id: 'quai',
        name: 'Quai',
        type: TriggerType.event,
        area: area,
      ),
    );
    await h.pump(tester);

    await h.rightClick(tester, 4, 4);
    await tester.tap(inMenu('Déplacer'));
    await tester.pumpAndSettle();
    await dragTo(tester, 4, 4, 6, 5);

    final moved = triggers.selected('quai')!;
    expect(moved.area.pos, const GridPos(x: 5, y: 4));
    expect(moved.area.size, area.size);
    expect(moved.name, 'Quai');
  });

  testWidgets('a character under the zone does not move instead of it', (
    tester,
  ) async {
    final zones = GameplayZoneEditingCommands(h.document, h.project);
    final zone = zones.place(GameplayZoneKind.encounter, area);
    final npc = CharacterEditingCommands(
      h.document,
      h.project,
    ).place(guide, const GridPos(x: 4, y: 4));
    MapEditingCommands(
      h.document,
      h.project,
    ).place(workspaceElement, const GridPos(x: 4, y: 4));
    h.document.selectedId = null;
    await h.pump(tester);

    await h.rightClick(tester, 4, 4);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('map-context-menu')),
        matching: find.textContaining('· Zone de jeu'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(inMenu('Déplacer'));
    await tester.pumpAndSettle();

    final npcBefore = CharacterEditingCommands(
      h.document,
      h.project,
    ).selected(npc.id)!.pos;
    final decorBefore = h.document.current.placedElements.single.pos;
    await dragTo(tester, 4, 4, 8, 7);

    expect(zones.selected(zone.id)!.area.pos, const GridPos(x: 7, y: 6));
    expect(
      CharacterEditingCommands(h.document, h.project).selected(npc.id)!.pos,
      npcBefore,
      reason: 'the character under the zone stayed where it was',
    );
    expect(h.document.current.placedElements.single.pos, decorBefore);
  });

  testWidgets('Escape cancels the armed move without touching the map', (
    tester,
  ) async {
    final zones = GameplayZoneEditingCommands(h.document, h.project);
    final zone = zones.place(GameplayZoneKind.encounter, area);
    await h.pump(tester);
    final before = h.document.current;
    final steps = h.document.undoCount;

    await h.rightClick(tester, 4, 4);
    await tester.tap(inMenu('Déplacer'));
    await tester.pumpAndSettle();
    h.view.pendingMove = null;
    h.redraw();
    await tester.pumpAndSettle();

    await dragTo(tester, 4, 4, 8, 8);

    expect(zones.selected(zone.id)!.area.pos, area.pos);
    expect(h.document.current, before);
    expect(h.document.undoCount, steps);
  });
}
