import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_context_harness.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  late MapContextHarness h;
  setUp(() => h = MapContextHarness.of(workspaceProject));
  tearDown(() => h.dispose());

  testWidgets('a single decor reports blocked stacking actions', (
    tester,
  ) async {
    MapEditingCommands(
      h.document,
      h.project,
    ).place(workspaceElement, const GridPos(x: 4, y: 4));
    await h.pump(tester);
    await h.rightClick(tester, 4, 4);
    final action = h.request!.actions.singleWhere(
      (action) => action.command == MapContextCommand.bringForward,
    );
    expect(action.enabled, isFalse);
    expect(action.unavailable, contains('Aucun autre décor'));
  });

  testWidgets('right-clicking another cell never reuses the old target', (
    tester,
  ) async {
    final commands = MapEntityEditingCommands(h.document, h.project);
    final first = commands.place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
    await h.pump(tester);
    await h.rightClick(tester, 4, 4);
    expect(h.request!.selected!.id, first.id);
    await h.rightClick(tester, 18, 1);
    expect(h.request!.selected, isNull);
    expect(h.request!.targets, isEmpty);
    expect(commands.selected(first.id), isNotNull);
  });

  testWidgets(
    'changing maps or entering exterior editing closes the pending request',
    (tester) async {
      await h.pump(tester);
      await h.rightClick(tester, 4, 4);
      h.session.releaseIfStale('other');
      expect(h.request, isNull);
      await h.rightClick(tester, 4, 4);
      h.session.releaseIfStale(h.document.current.id, exterior: true);
      expect(h.request, isNull);
    },
  );

  testWidgets(
    'disposing a context session prevents new requests and commands',
    (tester) async {
      MapEntityEditingCommands(
        h.document,
        h.project,
      ).place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
      await h.pump(tester);
      await h.rightClick(tester, 4, 4);
      final before = h.document.current;
      final target = h.request!.selected!;
      h.session.dispose();
      expect(h.request, isNull);
      expect(h.session.run(MapContextCommand.delete), isFalse);
      expect(h.session.select(target), isFalse);
      await h.rightClick(tester, 4, 4);
      expect(h.request, isNull);
      expect(h.document.current, same(before));
    },
  );
}
